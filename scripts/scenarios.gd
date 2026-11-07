class_name Scenarios
extends RefCounted
## Battles from the packs: looking a scenario up, checking it, and building
## its battle. A quick battle is one fight on a map fixed by design so it can
## be learned, with up to three stars to earn; a grand battle is a historical
## day. The data is in packs/; what a scenario holds, in packs/registry.gd.

const K := UnitTypes.Kind

const MAP_KINDS := ["fords", "woods", "bridges", "roads", "ridge"]
const SKIRMISH_SIZE := 6


## Every key a scenario may use; anything else is a misspelling.
const KEYS := [
	"id", "name", "era", "brief", "goal", "map", "map_seed", "player", "enemy", "persona",
	"abilities", "deadline", "hold_needed", "deadline_flags", "own_flags", "their_flags",
	"flag_drain", "deploy_depth", "stars",
	"plan", "view", "start_hour", "hour", "rout_scale", "pace", "veterancy", "start", "arrivals",
]
const FIXED_MAP_KINDS := ["fortress", "fortress_held", "random"]


## What is wrong with a scenario, as sentences: empty when nothing is.
static func check(spec: Dictionary) -> PackedStringArray:
	var wrong := PackedStringArray()
	var id: String = spec.get("id", "(no id)")
	for key in spec:
		if not key in KEYS:
			wrong.append("scenario %s has an unknown key: %s" % [id, key])
	if not is_grand(spec):
		var map: String = spec.get("map", "")
		if not map in MAP_KINDS and not map in FIXED_MAP_KINDS:
			wrong.append("scenario %s has an unknown map kind: %s" % [id, map])
		if era(spec.get("era", "")).is_empty():
			wrong.append("scenario %s has an unknown era: %s" % [id, spec.get("era", "")])
	return wrong


static func era(id: String) -> Dictionary:
	for e in Packs.eras():
		if e.id == id:
			return e
	return {}


## The scenarios of era `era_id`, in list order.
static func of_era(era_id: String) -> Array:
	return Packs.scenarios("quick").filter(func(s): return s.era == era_id)


## Grand battles: a historical day on a hand-drawn field several screens
## across, with armies arriving by road. See DESIGN.md.
static func grand() -> Array:
	return Packs.scenarios("grand")


static func get_spec(id: String) -> Dictionary:
	for s in Packs.scenarios("quick") + grand():
		if s.id == id:
			return s
	return {}


## A scenario whose field and armies are drawn afresh each time.
static func is_random(id: String) -> bool:
	return get_spec(id).get("map", "") == "random"


static func is_grand(spec: Dictionary) -> bool:
	return spec.has("plan")


## The scenario as it will be fought with `seed_value`: a Skirmish draws
## its map kind and its (shared) army, from its era's kinds, from the seed;
## the rest are fixed.
static func resolve(id: String, seed_value: int) -> Dictionary:
	var spec := get_spec(id).duplicate(true)
	if is_grand(spec) or spec.map != "random":
		return spec
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	spec.map = MAP_KINDS[rng.randi() % MAP_KINDS.size()]
	spec.map_seed = seed_value
	var kinds: Array = era(spec.era).draw
	var army: Array = []
	for i in SKIRMISH_SIZE:
		army.append([kinds[rng.randi() % kinds.size()], 0])
	army.sort()
	spec.player = army
	spec.enemy = army.duplicate(true)
	return spec


## The ground is the scenario's; `dice` seeds the battle's own random
## numbers, so replays differ a little.
static func make_battle(spec: Dictionary, dice: int) -> Battle:
	for wrong in check(spec):
		push_error(wrong)
	if is_grand(spec):
		return _make_grand(spec, dice)
	var map_seed: int = spec.map_seed
	var b := Battle.new(Terrain.generate(spec.map, map_seed), dice)
	b.abilities.assign(spec.get("abilities", ["rally"]))
	if spec.has("deploy_depth"):
		b.terrain.deploy_depth[0] = spec.deploy_depth
	var mid := b.terrain.size * 0.5
	for team in 2:
		var face := -PI * 0.5 if team == 0 else PI * 0.5
		b.add_regiment(team, K.GENERAL, UnitTypes.stat(K.GENERAL, "men"), mid, face, 0, {})
		for e in (spec.player if team == 0 else spec.enemy):
			b.add_regiment(team, e[0], UnitTypes.stat(e[0], "men"), mid, face, e[1], {})
	b.apply_orders(AI.deploy_orders(b, 0))
	b.apply_orders(AI.deploy_orders(b, 1))
	b.deadline = spec.get("deadline", 0.0)
	b.hold_needed = spec.get("hold_needed", 1)
	b.deadline_flags.assign(spec.get("deadline_flags", []))
	b.flag_drain = spec.get("flag_drain", Battle.FLAG_DRAIN)
	_claim_flags(b, spec)
	return b


## The flags each side starts holding.
static func _claim_flags(b: Battle, spec: Dictionary) -> void:
	for i in spec.get("own_flags", []):
		b.claim_flag(i, 0)
	for i in spec.get("their_flags", []):
		b.claim_flag(i, 1)


## A grand battle: the hand-drawn field, who holds it at the start, and
## everyone else on the road, due at the hour the spec gives.
static func _make_grand(spec: Dictionary, dice: int) -> Battle:
	var plan: Dictionary = spec.plan
	var b := Battle.new(Terrain.from_plan(plan), dice)
	b.abilities.assign(spec.get("abilities", ["rally"]))
	var veterancy: Array = spec.get("veterancy", [0, 0])
	var start_hour: float = spec.start_hour
	var hour: float = spec.hour
	for force in spec.start:
		var team: int = force.team
		for u in force.units:
			var stars: int = veterancy[team] + (u[4] if u.size() > 4 else 0)
			var r := b.add_regiment(team, u[0], UnitTypes.stat(u[0], "men"), u[2], u[3], stars, {})
			r.name = u[1]
			r.formation = force.formation
			r.objectives = _flag_points(plan, force.objectives)
			r.holds_until = (force.get("from_hour", start_hour) - start_hour) * hour
	for a in spec.arrivals:
		var stars: int = veterancy[a.team]
		var units: Array = a.units.map(func(u): return {"kind": u[0], "name": u[1], "stars": stars + (u[2] if u.size() > 2 else 0)})
		b.arrivals.append({
			"at": (a.hour - start_hour) * hour, "team": a.team, "formation": a.formation,
			"from": a.from, "road": PackedVector2Array(a.road), "face": a.face,
			"objectives": _flag_points(plan, a.objectives), "units": units,
		})
	b.arrivals.sort_custom(func(x, y): return x.at < y.at)
	b.deadline = spec.deadline
	b.deadline_flags.assign(spec.deadline_flags)
	b.flag_drain = spec.flag_drain
	b.rout_scale = spec.rout_scale
	b.pace = spec.pace
	b.dusk_time = INF
	_claim_flags(b, spec)
	return b


static func _flag_points(plan: Dictionary, indices: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in indices:
		out.append(plan.flags[i].at)
	return out


## The hour of a grand battle's day at battle time `t`, as "13:45".
static func hour_text(spec: Dictionary, t: float) -> String:
	var h: float = spec.start_hour + t / spec.hour
	var minutes := int(h * 60.0)
	return "%d:%02d" % [minutes / 60, minutes % 60]


static func goal_text(spec: Dictionary) -> String:
	if spec.has("goal"):
		return spec.goal
	if spec.get("deadline", 0.0) <= 0.0:
		return "Break their army."
	var t := _clock(spec.deadline)
	var need: int = spec.get("hold_needed", 1)
	var what := "one crossing" if need == 1 else ("both bridges" if spec.map == "bridges" and need == 2 else "%d crossings" % need)
	return "Hold %s when the clock reaches %s, or break their army first." % [what, t]


static func condition_text(c: Dictionary) -> String:
	if c.has("time"):
		return "Win within " + _clock(c.time)
	if c.has("losses"):
		return "Lose no more than %d%% of your men" % roundi(c.losses * 100.0)
	if c.has("flags"):
		return "Hold %d %s at the end" % [c.flags, c.get("noun", "crossings")]
	if c.has("hold"):
		return "%s %s at the end" % [c.get("verb", "Hold"), c.noun]
	return ""


## Which of the scenario's two extra conditions a finished battle met.
static func conditions_met(spec: Dictionary, b: Battle) -> Array[bool]:
	var out: Array[bool] = []
	for c in spec.stars:
		out.append(b.winner == 0 and _met(c, b))
	return out


## 0 for a defeat, else 1 plus a star for each condition met.
static func stars(spec: Dictionary, b: Battle) -> int:
	if b.winner != 0:
		return 0
	return 1 + conditions_met(spec, b).count(true)


static func _met(c: Dictionary, b: Battle) -> bool:
	if c.has("time"):
		return b.time <= c.time
	if c.has("losses"):
		var full := 0
		var lost := 0
		for r in b.regiments:
			if r.team == 0:
				full += r.men_max
				lost += r.men_max - r.men()
		return float(lost) / maxf(full, 1) <= c.losses
	if c.has("flags"):
		return b.flags_held(0) >= c.flags
	if c.has("hold"):
		return b.flags[c.hold].owner == 0
	return false


static func _clock(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
