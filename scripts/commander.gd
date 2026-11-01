class_name Commander
extends RefCounted
## Turns a battle into orders for one side. This one gives none: an army
## that is never commanded, the bottom of every skill ladder. The AI and
## anything else that commands a seat extends it.


## Orders for `team`, or, with `ids`, for those of its regiments only: the
## part of the side the seat commands (see BattleRun.Seat).
func decide(_b: Battle, _team: int, _ids: Array[int] = []) -> Array:
	return []


## A commander for a copy of the battle, in the state this one is in, so
## the copy is fought on as this one would fight it. One that keeps no
## state is its own copy.
func copy() -> Commander:
	return self


## The core AI with a persona. `rally` blows the Rally horn when regiments
## near the general are breaking or broken, as a sharp player does.
##
## Where the line goes is the commander's plan (AI.allot), which it thinks
## out again every `rethink` seconds, 0 for at every look; at the looks in
## between, the AI carries it out. Measured on 1 November 2026: thought out
## every 4 s, blocks stopped marching back and forth as the battle wavered
## around a threshold (which flag the enemy comes for, whether a flag can
## be made good), but the AI was weaker for it from both ends against
## tests/ai_baseline.gd, so it thinks at every look.
class AICommander extends Commander:
	var persona: Dictionary
	var rally := false
	var plan := {}
	var rethink := 0.0
	var _rethink_at := 0.0

	func _init(with_persona: Dictionary, blows_rally := false) -> void:
		persona = with_persona
		rally = blows_rally

	func copy() -> Commander:
		return _with_plan_of(AICommander.new(persona, rally))

	## `c`, holding this commander's plan and thinking it out again when
	## this one would.
	func _with_plan_of(c: AICommander) -> AICommander:
		c.plan = plan.duplicate()
		c.rethink = rethink
		c._rethink_at = _rethink_at
		return c

	func decide(b: Battle, team: int, ids: Array[int] = []) -> Array:
		if b.time >= _rethink_at:
			plan = think(b, team, ids)
			_rethink_at = b.time + rethink
		var orders := AI.decide(b, team, persona, plan, ids)
		if rally and team == 0 and should_rally(b):
			orders.append({"type": "rally"})
		return orders

	## The plan: where the AI allots the line (of `ids`, when given) now.
	func think(b: Battle, team: int, ids: Array[int] = []) -> Dictionary:
		return AI.allot(b, team, persona, ids)

	## The horn is ready, the general stands, and a regiment within his
	## reach is running but worth saving, or close to running.
	static func should_rally(b: Battle) -> bool:
		if b.cooldowns.rally > 0.0:
			return false
		var g := b.general_of(0)
		if g == null:
			return false
		for r in b.team_regiments(0):
			if r == g or r.pos.distance_to(g.pos) > Battle.RALLY_RADIUS:
				continue
			if r.state == Regiment.State.ROUTING and r.strength() >= 0.2:
				return true
			if r.fighting() and r.morale < r.morale_max * 0.25:
				return true
		return false


## The core AI at a person's pace: it looks at the battle as often as a
## person might, and of the orders the AI would give it gives only
## `per_look`, the most urgent first. The rest wait; at the next look the
## AI proposes them again if they still matter. This is the ladder's
## stand-in for a player, who gives perhaps 10 to 30 orders a minute.
class PacedCommander extends AICommander:
	var per_look := 1

	func _init(with_persona: Dictionary, blows_rally := false, orders_per_look := 1) -> void:
		super(with_persona, blows_rally)
		per_look = orders_per_look

	func copy() -> Commander:
		return _with_plan_of(PacedCommander.new(persona, rally, per_look))

	func decide(b: Battle, team: int, ids: Array[int] = []) -> Array:
		var keyed := super.decide(b, team, ids).map(func(o): return [urgency(b, team, o), o])
		keyed.sort_custom(func(x, y): return x[0] < y[0])
		return keyed.slice(0, per_look).map(func(k): return k[1])

	## Lower is sooner: the horn first, then the regiment nearest an enemy.
	static func urgency(b: Battle, team: int, o: Dictionary) -> float:
		var r := b.get_regiment(o.get("id", -1))
		if r == null:
			return -INF
		var nearest := INF
		for f in b.team_regiments(1 - team):
			if f.fighting():
				nearest = minf(nearest, r.pos.distance_to(f.pos))
		return nearest


## The core AI thinking ahead. Every `replan` seconds it tries each way of
## sending the line on copies of the battle, each fought `horizon` seconds
## on by the AI on both sides (the enemy as `rival`: how the briefing says
## the enemy fights), and keeps the one that leaves it furthest ahead on
## average (Telemetry.lead). Each is fought `samples` times, the commanders
## looking a few steps apart each time and the guns' scatter drawn afresh,
## since on the knife edge one fight ahead says little, and the planner
## can't see the battle's own dice to come. The ways: the AI's own allotment (`choice` -1), or
## the whole line to one flag (its index). Between, the AI carries out the
## one it chose. This is the plan search of the AI audit, done during the
## battle.
class PlannerCommander extends AICommander:
	var rival: Dictionary
	var replan := 20.0
	var horizon := 30.0
	var samples := 2
	var choice := -1
	## Called at each re-plan with the battle, the side, each choice's score
	## (choice to lead) and the choice taken: a study's window on the
	## planner, which changes nothing.
	var on_choice := Callable()
	var _replan_at := 0.0

	func _init(with_persona: Dictionary, blows_rally: bool, rival_persona: Dictionary) -> void:
		super(with_persona, blows_rally)
		rival = rival_persona

	func copy() -> Commander:
		var c := PlannerCommander.new(persona, rally, rival)
		c.replan = replan
		c.horizon = horizon
		c.samples = samples
		c.choice = choice
		c._replan_at = _replan_at
		return _with_plan_of(c)

	func think(b: Battle, team: int, ids: Array[int] = []) -> Dictionary:
		if b.time >= _replan_at:
			var scores := try_all(b, team)
			choice = best_of(scores)
			if on_choice.is_valid():
				on_choice.call(b, team, scores, choice)
			_replan_at = b.time + replan
		return plan_for(b, team, persona, choice, ids)

	## Each way of sending the line, tried ahead: choice to its score.
	func try_all(b: Battle, team: int) -> Dictionary:
		var out := {}
		for c in range(-1, b.flags.size()):
			out[c] = ahead(b, team, c)
		return out

	## The best-scoring choice; on a tie the one in hand, so a choice no
	## better doesn't replace it.
	func best_of(scores: Dictionary) -> int:
		var best := choice
		for c in scores:
			if scores[c] > scores[best]:
				best = c
		return best

	## The plan `c` stands for: the AI's allotment, or every block of the
	## line (of `ids`, when given) to flag `c`.
	static func plan_for(b: Battle, team: int, with_persona: Dictionary, c: int, ids: Array[int] = []) -> Dictionary:
		var out := AI.allot(b, team, with_persona, ids)
		if c >= 0:
			for id in out:
				out[id] = c
		return out

	## How far ahead this side is, on average, `horizon` seconds after
	## taking up choice `c`: the lead, from -1 to 1 (2 once the battle is
	## won, -2 lost).
	func ahead(b: Battle, team: int, c: int) -> float:
		var fielded := [Telemetry.fielded(b, 0), Telemetry.fielded(b, 1)]
		var total := 0.0
		for k in samples:
			# Dice of its own, not the battle's, and the same for each choice
			# at this look, so the choices are tried on equal luck.
			var copied := b.copy()
			copied.reseed(hash([roundi(b.time / Battle.STEP), k]))
			var run := BattleRun.new(copied)
			var mine := PlannerCommander.new(persona, false, rival)
			mine.choice = c
			mine._replan_at = INF
			var theirs := BattleRun.Seat.new(1 - team, AICommander.new(rival))
			theirs.wait = 5 * k * Battle.STEP
			run.add_seat(theirs)
			run.add_seat(BattleRun.Seat.new(team, mine))
			run.run_for(horizon)
			var lead := Telemetry.lead(run.battle, fielded)
			if run.battle.phase == "over":
				lead = 2.0 if run.battle.winner == 0 else -2.0
			total += lead if team == 0 else -lead
		return total / samples
