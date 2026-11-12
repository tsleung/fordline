class_name Fights
extends RefCounted
## Battles fought computer against computer, for the suite and the studies:
## the ladder of player commanders, and one way to fight a battle with them,
## through the same loop the game uses.

## Player commanders of rising skill (idle, person, standard, sharp), then
## sharp with one change each (reserve, hills), then the planner. every:
## seconds between decisions (0 never decides). persona: the AI persona it
## plays with. rally: whether it blows the horn when regiments near the
## general break. per_look: at most this many orders each decision, the
## most urgent first: a person's pace, the ladder's stand-in for a player.
## plans: thinks ahead, trying plans on copies of the battle; it fights
## about ten times as long, so the studies run it only when asked.
const POLICIES := {
	"idle": {"every": 0.0, "persona": {"hold": 8.0, "flank": false}, "rally": false},
	"person": {"every": 2.0, "persona": AI.PERSONAS["balanced"], "rally": false, "per_look": 1},
	"standard": {"every": 0.75, "persona": AI.PERSONAS["balanced"], "rally": false},
	"sharp": {"every": 0.4, "persona": AI.PERSONAS["balanced"], "rally": true},
	"reserve": {"every": 0.4, "persona": AI.PERSONAS["reserve"], "rally": true},
	"hills": {"every": 0.4, "persona": AI.PERSONAS["hills"], "rally": true},
	"planner": {"every": 0.75, "persona": AI.PERSONAS["balanced"], "rally": false, "plans": true},
}
## A quick battle may not run longer than this; a grand one runs to dusk.
const TIME_CAP := 600.0


## The player's seat for `policy`, against an enemy that fights as
## `enemy_persona` (a planner reads it in the briefing).
static func player_seat(policy: String, enemy_persona: Dictionary) -> BattleRun.Seat:
	var p: Dictionary = POLICIES[policy]
	if p.every <= 0.0:
		return BattleRun.Seat.new(0, Commander.new())
	if p.has("plans"):
		return BattleRun.Seat.new(0, Commander.PlannerCommander.new(p.persona, p.rally, enemy_persona), p.every)
	if p.has("per_look"):
		return BattleRun.Seat.new(0, Commander.PacedCommander.new(p.persona, p.rally, p.per_look), p.every)
	return BattleRun.Seat.new(0, Commander.AICommander.new(p.persona, p.rally), p.every)


## Fight `b` to its end, the enemy under `enemy_persona` and the player
## under `policy`. With `logged`, the player's orders go into the run's log
## as its turns, so the battle can be replayed with one taken out. `die`
## sets when each commander first looks (see seats). Returns the run, with
## its trace.
static func fight(b: Battle, enemy_persona: Dictionary, policy: String, logged := false, die := 0) -> BattleRun:
	var run := BattleRun.new(b)
	for seat in seats(enemy_persona, policy, die):
		seat.logged = logged and seat.team == 0
		run.add_seat(seat)
	run.begin()
	run.run_for(length(b))
	return run


## The seats for a fight: the enemy first, then the player, the order in
## which they decide within a step. `die` sets when each first looks: a
## few steps into its think, a different few for each seat, as a person
## never looks at the same moments twice. Where the battle's own random
## numbers barely matter (only guns scatter), this is what makes the dice
## fight different battles: on the knife edge a few steps is another
## battle. Die 0 has both look at once.
static func seats(enemy_persona: Dictionary, policy: String, die := 0) -> Array:
	var out: Array = [BattleRun.Seat.new(1, Commander.AICommander.new(enemy_persona)), player_seat(policy, enemy_persona)]
	for i in out.size():
		first_look(out[i], i, die)
	return out


## Seat `seat`, the `index`th to decide in a step, first looks a few steps
## into its think, by `die`. A think's worth of dice on, the first seat's
## moments come round again, so each lap shifts the later seats a step more:
## the dice below a lap time as they always did, and those past it fight
## other battles rather than the same ones again.
static func first_look(seat: BattleRun.Seat, index: int, die: int) -> void:
	var steps := maxi(1, roundi(seat.every / Battle.STEP))
	@warning_ignore("integer_division")
	var lap := die / steps
	seat.wait = (die * (3 + 2 * index) + lap * index) % steps * Battle.STEP


static func length(b: Battle) -> float:
	return maxf(TIME_CAP, b.deadline + 10.0)


## The siege as the owner played it on 7 November 2026 (DESIGN.md, "Next:
## gates that matter", step 1). The guns stand where they outreach the
## wall-walk's shot and clear it, enemy guns first; everyone else stands
## behind them and fights only what comes at the guns. Once no enemy
## shooter is left fighting, the guns batter the gate and the foot ram it;
## once it falls, the AI takes the army on to the flags.
class GunLineCommander extends Commander:
	## How far behind the guns the rest stand, how far apart the guns stand,
	## how close an enemy may come to them before it is fought, and how far
	## out from the gate the rammers wait their turn.
	const GUARD_BACK := 70.0
	const GUN_GAP := 60.0
	const GUARD_REACH := 200.0
	const RAM_OUT := 24.0
	const WAIT_OUT := 70.0

	var _ai := AICommander.new(AI.PERSONAS["balanced"])

	func copy() -> Commander:
		var c := GunLineCommander.new()
		c._ai = _ai.copy()
		return c

	func decide(b: Battle, team: int, ids: Array[int] = []) -> Array:
		if b.terrain.gates.is_empty() or b.terrain.gate_broken[0]:
			return _ai.decide(b, team, ids)
		var mine := _fighting(b, team).filter(func(r): return ids.is_empty() or r.id in ids)
		var foes := _fighting(b, 1 - team)
		var gate: Dictionary = b.terrain.gates[0]
		var out: Vector2 = gate.out
		var along: Vector2 = gate.along
		var guns := mine.filter(func(r): return r.kind == UnitTypes.Kind.CANNONS)
		var rest := mine.filter(func(r): return r.kind != UnitTypes.Kind.CANNONS)
		var shooters := foes.filter(func(f): return UnitTypes.is_ranged(f.kind))
		var line := gun_line(b, guns, foes)
		var orders: Array = []
		for i in guns.size():
			var r: Regiment = guns[i]
			var o: Variant = null
			if shooters.is_empty():
				o = null if r.target_gate == 0 else {"type": "bombard", "id": r.id, "gate": 0}
			else:
				var reach := r.fire_range * b.terrain.range_mult(r.pos)
				var target := _nearest(r.pos, shooters.filter(func(f): return f.kind == UnitTypes.Kind.CANNONS), reach)
				if target == null:
					target = _nearest(r.pos, shooters, reach)
				if target != null:
					o = null if r.target_id == target.id else {"type": "attack", "id": r.id, "target": target.id}
				else:
					o = _go(r, line + along * GUN_GAP * (i - (guns.size() - 1) * 0.5), (-out).angle())
			if o != null:
				orders.append(o)
		var near_guns := foes.filter(func(f): return guns.any(func(g): return g.pos.distance_to(f.pos) < GUARD_REACH))
		var foot := rest.filter(func(r): return not UnitTypes.is_ranged(r.kind) and not UnitTypes.is_mounted(r.kind))
		for i in rest.size():
			var r: Regiment = rest[i]
			var o: Variant = null
			var threat := _nearest(r.pos, near_guns, INF)
			if threat != null and r.kind != UnitTypes.Kind.GENERAL and not UnitTypes.is_ranged(r.kind):
				o = null if r.target_id == threat.id else {"type": "attack", "id": r.id, "target": threat.id}
			elif shooters.is_empty() and r in foot:
				# The first foot rams; the others wait just behind.
				var k := foot.find(r)
				var at: Vector2 = gate.c + out * RAM_OUT if k == 0 else gate.c + out * WAIT_OUT + along * 50.0 * (k - foot.size() * 0.5)
				o = _go(r, at, (-out).angle())
			else:
				o = _go(r, line + out * GUARD_BACK + along * 55.0 * (i - (rest.size() - 1) * 0.5), (-out).angle())
			if o != null:
				orders.append(o)
		return orders

	## Where the guns stand: out from the wall-walk over the gate, beyond the
	## reach of the shot on it and within their own.
	static func gun_line(b: Battle, guns: Array, foes: Array) -> Vector2:
		var gate: Dictionary = b.terrain.gates[0]
		var height := 1.0
		for p in b.terrain.posts:
			height = maxf(height, b.terrain.range_mult(p))
		var shot := 0.0
		for f in foes:
			if UnitTypes.is_ranged(f.kind) and f.kind != UnitTypes.Kind.CANNONS:
				shot = maxf(shot, f.fire_range * height)
		var reach := 430.0
		for g in guns:
			reach = minf(reach, g.fire_range)
		var standoff := clampf((shot + reach) * 0.5, shot + 30.0, reach - 30.0)
		# Measured from the wall-walk: the post nearest the gate, straight
		# out in front of the gate.
		var post := _nearest_point(gate.c, b.terrain.posts)
		var wall_walk: Vector2 = gate.c + gate.out * (post - gate.c).dot(gate.out)
		return b.terrain.clamp_to_field(wall_walk + gate.out * standoff)

	static func _nearest_point(p: Vector2, among: PackedVector2Array) -> Vector2:
		var best := p
		var best_d := INF
		for q in among:
			if p.distance_to(q) < best_d:
				best_d = p.distance_to(q)
				best = q
		return best

	static func _fighting(b: Battle, team: int) -> Array:
		return b.team_regiments(team).filter(func(r): return r.fighting())

	static func _nearest(p: Vector2, among: Array, radius: float) -> Regiment:
		var best: Regiment = null
		var best_d := radius
		for f in among:
			var d: float = p.distance_to(f.pos)
			if d < best_d:
				best_d = d
				best = f
		return best

	## A move, unless it is already going there and not chasing anyone.
	static func _go(r: Regiment, to: Vector2, facing: float) -> Variant:
		var heading := r.waypoints[r.waypoints.size() - 1] if not r.waypoints.is_empty() else r.pos
		if heading.distance_to(to) < 20.0 and r.target_id < 0 and r.target_gate < 0:
			return null
		return {"type": "move", "id": r.id, "to": to, "facing": facing}
