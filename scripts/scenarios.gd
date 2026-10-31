class_name Scenarios
extends RefCounted
## Quick battles: one fight each, on a map fixed by design so it can be
## learned, with up to three stars to earn. Pure data and builders.

const K := UnitTypes.Kind

## Scenarios are grouped by era, oldest first; each era fights with its
## own weapons. draw: the kinds a Skirmish of that era picks its army from;
## a kind listed twice comes up twice as often.
const ERAS := [
	{
		"id": "medieval", "name": "Medieval",
		"draw": [K.SWORDS, K.PIKES, K.ARCHERS, K.CAVALRY, K.CANNONS],
	},
	{
		"id": "pike_shot", "name": "Pike and Shot",
		"draw": [K.PIKES, K.PIKES, K.MUSKETS, K.MUSKETS, K.CAVALRY, K.CANNONS],
	},
]

## Each scenario:
##   era: an id from ERAS
##   map / map_seed: the ground ("random" with no seed: Skirmish)
##   player / enemy: [kind, stars] for each regiment beside the general
##   persona: how the enemy fights
##   abilities: the player's (Rally if not given)
##   deadline / hold_needed: the battle ends on the flags at that time
##   own_flags / enemy_flags: that side starts holding every flag
##   flag_drain: resolve per second per flag of difference (sieges: 0)
##   goal: the briefing's one-line goal, when the generic one won't do
##   deploy_depth: how far in from its edge the player may deploy
##   stars: the two stars beyond the win, each one condition:
##     {"time": s} win within s seconds; {"losses": f} lose at most that
##     share of your men; {"flags": n} hold at least n flags at the end
const LIST := [
	{
		"id": "skirmish", "name": "Skirmish", "era": "medieval",
		"brief": "A new field each time and two armies made the same. Only how you fight is different.",
		"map": "random", "persona": "balanced",
		"stars": [{"time": 150.0}, {"losses": 0.35}],
	},
	{
		"id": "hold", "era": "medieval", "name": "Hold the Fords",
		"brief": "The three fords are yours and an army is coming for them. Still hold one when the clock runs out.",
		"map": "fords", "map_seed": 41, "persona": "aggressive",
		"player": [[K.SWORDS, 1], [K.SWORDS, 0], [K.PIKES, 1], [K.ARCHERS, 0], [K.ARCHERS, 0]],
		"enemy": [[K.SWORDS, 0], [K.SWORDS, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CAVALRY, 0]],
		"deadline": 180.0, "hold_needed": 1, "own_flags": true, "deploy_depth": 370.0,
		"stars": [{"flags": 2}, {"losses": 0.4}],
	},
	{
		"id": "hammer", "era": "medieval", "name": "Hammer and Anvil",
		"brief": "Open woods. They have dug in with bows and a gun; you have horse. Pin them with the foot, then ride round.",
		"map": "woods", "map_seed": 7, "persona": "dug_in",
		"player": [[K.SWORDS, 0], [K.PIKES, 0], [K.CAVALRY, 0], [K.CAVALRY, 0], [K.CAVALRY, 1]],
		"enemy": [[K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 0], [K.PIKES, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.ARCHERS, 1], [K.CANNONS, 0], [K.CAVALRY, 0]],
		"stars": [{"time": 120.0}, {"losses": 0.3}],
	},
	{
		"id": "bridges", "era": "medieval", "name": "Two Narrow Bridges",
		"brief": "Take both bridges before dusk. They hold the far bank with guns; so do you, and you can call a barrage.",
		"map": "bridges", "map_seed": 23, "persona": "dug_in", "abilities": ["rally", "barrage"],
		"player": [[K.SWORDS, 1], [K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CANNONS, 0], [K.CANNONS, 0]],
		"enemy": [[K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 1], [K.PIKES, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CANNONS, 0], [K.CAVALRY, 0]],
		"deadline": 300.0, "hold_needed": 2,
		"stars": [{"time": 200.0}, {"losses": 0.35}],
	},
	{
		"id": "riders", "era": "medieval", "name": "Riders at Dawn",
		"brief": "Their horse will come early and from everywhere. Keep your pikes facing it and your bows behind them.",
		"map": "ridge", "map_seed": 5, "persona": "aggressive",
		"player": [[K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 1], [K.PIKES, 0], [K.SWORDS, 0], [K.ARCHERS, 0], [K.ARCHERS, 0]],
		"enemy": [[K.CAVALRY, 0], [K.CAVALRY, 0], [K.CAVALRY, 0], [K.SWORDS, 0]],
		"stars": [{"time": 150.0}, {"losses": 0.35}],
	},
	{
		"id": "storm", "era": "medieval", "name": "The Storming of Duskwatch",
		"brief": "A castle on the sea cliffs: a moat, a gatehouse, a walled keep. Batter in the gate, then the keep's, before dusk.",
		"map": "fortress", "map_seed": 3, "persona": "garrison", "abilities": ["rally", "barrage"],
		"player": [[K.SWORDS, 1], [K.SWORDS, 0], [K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 0], [K.PIKES, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CANNONS, 0], [K.CANNONS, 0]],
		"enemy": [[K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CAVALRY, 0]],
		"deadline": 360.0, "hold_needed": 2, "enemy_flags": true, "flag_drain": 0.0,
		"goal": "Hold two of the castle's three flags at 6:00, or break the garrison.",
		"stars": [{"time": 240.0}, {"losses": 0.45}],
	},
	{
		"id": "last_keep", "era": "medieval", "name": "The Last Keep",
		"brief": "Now the castle is yours and a great host is at the gate. Man the walls; when the gate goes, hold the gateway.",
		"map": "fortress_held", "map_seed": 3, "persona": "aggressive",
		"player": [[K.SWORDS, 1], [K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 0], [K.ARCHERS, 1], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CANNONS, 0]],
		"enemy": [[K.SWORDS, 0], [K.SWORDS, 0], [K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 0], [K.PIKES, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CAVALRY, 0], [K.CAVALRY, 0]],
		"deadline": 300.0, "hold_needed": 1, "own_flags": true, "flag_drain": 0.0,
		"goal": "Hold one of your three flags at 5:00, or break their army.",
		"stars": [{"flags": 3, "noun": "flags"}, {"losses": 0.4}],
	},
	{
		"id": "skirmish_shot", "era": "pike_shot", "name": "Skirmish",
		"brief": "Pike, shot, horse and guns, the same on both sides, on a new field each time.",
		"map": "random", "persona": "balanced",
		"stars": [{"time": 180.0}, {"losses": 0.35}],
	},
	{
		"id": "push", "era": "pike_shot", "name": "Push of Pike",
		"brief": "Two armies of pike and shot. Let your muskets thin their blocks before the pikes meet.",
		"map": "roads", "map_seed": 13, "persona": "balanced",
		"player": [[K.PIKES, 1], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CAVALRY, 0], [K.CANNONS, 0]],
		"enemy": [[K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CAVALRY, 0]],
		"stars": [{"time": 180.0}, {"losses": 0.35}],
	},
	{
		"id": "fords_shot", "era": "pike_shot", "name": "Shot at the Fords",
		"brief": "Your muskets hold the fords. Their pikes must wade to reach you, and every volley shakes them.",
		"map": "fords", "map_seed": 17, "persona": "aggressive",
		"player": [[K.MUSKETS, 1], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 0]],
		"enemy": [[K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.CAVALRY, 0]],
		"deadline": 180.0, "hold_needed": 1, "own_flags": true, "deploy_depth": 370.0,
		"stars": [{"flags": 2}, {"losses": 0.4}],
	},
	{
		"id": "cuirassiers", "era": "pike_shot", "name": "The Cuirassiers",
		"brief": "Their shot stands behind their pikes. Ride round the pikes and the shot cannot stop you.",
		"map": "roads", "map_seed": 31, "persona": "dug_in",
		"player": [[K.CAVALRY, 1], [K.CAVALRY, 0], [K.CAVALRY, 0], [K.CAVALRY, 0], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0]],
		"enemy": [[K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CAVALRY, 0]],
		"stars": [{"time": 150.0}, {"losses": 0.35}],
	},
	{
		"id": "battery", "era": "pike_shot", "name": "The Great Battery",
		"brief": "Three batteries hold the ridge. Cross the open ground quickly and take the guns from the side.",
		"map": "ridge", "map_seed": 9, "persona": "dug_in", "abilities": ["rally", "barrage"],
		"player": [[K.PIKES, 1], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CAVALRY, 0]],
		"enemy": [[K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 1], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CANNONS, 1], [K.CAVALRY, 0]],
		"stars": [{"time": 240.0}, {"losses": 0.4}],
	},
	{
		"id": "breach", "era": "pike_shot", "name": "The Breach at Greyhold",
		"brief": "Greyhold's walls were built for bows. Bring up the great guns, open the gate, and send the pikes through the smoke.",
		"map": "fortress", "map_seed": 11, "persona": "garrison", "abilities": ["rally", "barrage"],
		"player": [[K.PIKES, 1], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CAVALRY, 0]],
		"enemy": [[K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CANNONS, 0], [K.CAVALRY, 0]],
		"deadline": 360.0, "hold_needed": 2, "enemy_flags": true, "flag_drain": 0.0,
		"goal": "Hold two of the castle's three flags at 6:00, or break the garrison.",
		"stars": [{"time": 240.0}, {"losses": 0.4}],
	},
]

const MAP_KINDS := ["fords", "woods", "bridges", "roads", "ridge"]
const SKIRMISH_SIZE := 6


static func era(id: String) -> Dictionary:
	for e in ERAS:
		if e.id == id:
			return e
	return {}


## The scenarios of era `era_id`, in list order.
static func of_era(era_id: String) -> Array:
	return LIST.filter(func(s): return s.era == era_id)


static func get_spec(id: String) -> Dictionary:
	for s in LIST:
		if s.id == id:
			return s
	return {}


## The scenario as it will be fought with `seed_value`: a Skirmish draws
## its map kind and its (shared) army, from its era's kinds, from the seed;
## the rest are fixed.
static func resolve(id: String, seed_value: int) -> Dictionary:
	var spec := get_spec(id).duplicate(true)
	if spec.map != "random":
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
	var map_seed: int = spec.map_seed
	var b := Battle.new(Terrain.generate(spec.map, map_seed), dice)
	b.abilities.assign(spec.get("abilities", ["rally"]))
	if spec.has("deploy_depth"):
		b.terrain.deploy_depth[0] = spec.deploy_depth
	var mid := Terrain.SIZE * 0.5
	for team in 2:
		var face := -PI * 0.5 if team == 0 else PI * 0.5
		b.add_regiment(team, K.GENERAL, UnitTypes.stat(K.GENERAL, "men"), mid, face, 0, {})
		for e in (spec.player if team == 0 else spec.enemy):
			b.add_regiment(team, e[0], UnitTypes.stat(e[0], "men"), mid, face, e[1], {})
	b.apply_orders(AI.deploy_orders(b, 0))
	b.apply_orders(AI.deploy_orders(b, 1))
	b.deadline = spec.get("deadline", 0.0)
	b.hold_needed = spec.get("hold_needed", 1)
	b.flag_drain = spec.get("flag_drain", Battle.FLAG_DRAIN)
	for team in 2:
		if spec.get("own_flags" if team == 0 else "enemy_flags", false):
			for i in b.flags.size():
				b.claim_flag(i, team)
	return b


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
	return false


static func _clock(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
