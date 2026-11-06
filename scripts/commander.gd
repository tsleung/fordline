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
## can't see the battle's own dice to come. The ways: the AI's own
## allotment (`choice` -1), or the whole line to one flag (its index).
## Between, the AI carries out the one it chose. This is the plan search of
## the AI audit, done during the battle.
##
## With a `budget` it fights only that many steps of its look ahead at each
## look, so no frame carries the whole search, and the choice lands the
## looks it took after the moment it was tried from. The budget is counted
## in steps of the battle, not time on the clock, so a replay comes out the
## same.
class PlannerCommander extends AICommander:
	var rival: Dictionary
	var replan := 20.0
	var horizon := 30.0
	var samples := 2
	## Rollout steps fought at each look; 0, the whole search at once.
	var budget := 0
	var choice := -1
	## Called as each search ends with the battle as it was when the search
	## began, the side, each choice's score (choice to lead), the choice
	## taken, and for each choice how many of its rollouts ended the battle
	## inside the look ahead: a study's window on the planner, which changes
	## nothing.
	var on_choice := Callable()
	var _replan_at := 0.0
	## The search under way: the battle as it began from, the rollouts still
	## to fight (each [choice, sample]), the one being fought, its choice and
	## the steps it has left, the scores so far and the rollouts that ended
	## the battle, and each side's men when it began. No search: _from is
	## null.
	var _from: Battle = null
	var _todo: Array = []
	var _rollout: BattleRun = null
	var _rollout_choice := 0
	var _rollout_left := 0
	var _sums := {}
	var _ended := {}
	var _fielded := []

	func _init(with_persona: Dictionary, blows_rally: bool, rival_persona: Dictionary) -> void:
		super(with_persona, blows_rally)
		rival = rival_persona

	## The copy goes on with the search where this one is in it; it has no
	## study listening.
	func copy() -> Commander:
		var c := PlannerCommander.new(persona, rally, rival)
		c.replan = replan
		c.horizon = horizon
		c.samples = samples
		c.budget = budget
		c.choice = choice
		c._replan_at = _replan_at
		c._from = _from.copy() if _from != null else null
		c._todo = _todo.duplicate(true)
		c._rollout = _rollout.copy() if _rollout != null else null
		c._rollout_choice = _rollout_choice
		c._rollout_left = _rollout_left
		c._sums = _sums.duplicate()
		c._ended = _ended.duplicate()
		c._fielded = _fielded.duplicate()
		return _with_plan_of(c)

	func think(b: Battle, team: int, ids: Array[int] = []) -> Dictionary:
		if _from == null and b.time >= _replan_at:
			_begin(b)
			_replan_at = b.time + replan
		if _from != null:
			_work(team, budget if budget > 0 else -1)
		return plan_for(b, team, persona, choice, ids)

	func _begin(b: Battle) -> void:
		_from = b.copy()
		_fielded = [Telemetry.fielded(b, 0), Telemetry.fielded(b, 1)]
		_sums = {}
		_ended = {}
		_todo = []
		for c in range(-1, b.flags.size()):
			_sums[c] = 0.0
			_ended[c] = 0
			for k in samples:
				_todo.append([c, k])

	## Fight `steps` steps of the search (-1, all of it); once every
	## rollout is fought, take the best choice.
	func _work(team: int, steps: int) -> void:
		while steps != 0:
			if _rollout != null and (_rollout_left <= 0 or _rollout.battle.phase != "battle"):
				_sums[_rollout_choice] += score_of(_rollout, team, _fielded)
				_ended[_rollout_choice] += 1 if _rollout.battle.phase == "over" else 0
				_rollout = null
			if _rollout == null:
				if _todo.is_empty():
					_finish(team)
					return
				var next: Array = _todo.pop_front()
				_rollout = rollout(_from, team, next[0], next[1], 5 * next[1])
				_rollout_choice = next[0]
				_rollout_left = ceili(horizon / Battle.STEP)
				continue
			_rollout.advance()
			_rollout_left -= 1
			steps -= 1 if steps > 0 else 0

	func _finish(team: int) -> void:
		var scores := {}
		for c in _sums:
			scores[c] = _sums[c] / samples
		choice = best_of(scores)
		if on_choice.is_valid():
			on_choice.call(_from, team, scores, choice, _ended.duplicate())
		_from = null

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

	## Choice `c` fought on from `from`, its dice drawn from `dice` and the
	## enemy looking `phase` steps into its think. The search's `k`th try of
	## a choice is dice k and phase 5k, the same for each choice, so the
	## choices are tried on equal luck; the battle's own dice are never used.
	func rollout(from: Battle, team: int, c: int, dice: int, phase: int) -> BattleRun:
		var copied := from.copy()
		copied.reseed(hash([roundi(from.time / Battle.STEP), dice]))
		var run := BattleRun.new(copied)
		var mine := PlannerCommander.new(persona, false, rival)
		mine.choice = c
		mine._replan_at = INF
		var theirs := BattleRun.Seat.new(1 - team, AICommander.new(rival))
		theirs.wait = phase * Battle.STEP
		run.add_seat(theirs)
		run.add_seat(BattleRun.Seat.new(team, mine))
		return run

	## A rollout the search never fights, dice and timing of its own (the
	## `j`th of them), fought `horizon` on and scored: a study's check on
	## the scores the planner chose by.
	func evaluate(from: Battle, team: int, c: int, j: int, fielded: Array) -> float:
		var run := rollout(from, team, c, 1000 + j, 5 * j + 2)
		run.run_for(horizon)
		return score_of(run, team, fielded)

	## How far ahead `team` is at the end of a rollout: the lead, from -1
	## to 1, measured against each side's men `fielded` when it began; 2 once
	## the battle is won, -2 lost.
	static func score_of(run: BattleRun, team: int, fielded: Array) -> float:
		var lead := Telemetry.lead(run.battle, fielded)
		if run.battle.phase == "over":
			lead = 2.0 if run.battle.winner == 0 else -2.0
		return lead if team == 0 else -lead
