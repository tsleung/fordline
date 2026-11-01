class_name PlannerData
extends RefCounted
## The planner's choices as data, for learning to choose as it does: at
## each of its re-plans, what its side could see, as a fixed row of numbers,
## each choice's rollout score, and the choice it took; at the battle's end,
## how it came out. tests/plan_examples.gd writes them out.
##
## A choice is how the line is sent: index 0 the AI's own allotment, index
## k + 1 the whole line to flag k (Commander.PlannerCommander's choice c is
## index c + 1). A quick battle has at most MAX_FLAGS flags; a smaller one
## pads its rows and leaves those choices out of `legal`.

const K := UnitTypes.Kind
const MAX_FLAGS := 3
## Strength is AI._power summed, in thousands.
const POWER_UNIT := 1000.0


## The state's numbers, in order, and what each means.
static func feature_names() -> PackedStringArray:
	var names := PackedStringArray()
	for k in MAX_FLAGS:
		for n in ["present", "owner", "progress", "own_line", "own_other", "enemy", "distance"]:
			names.append("flag%d_%s" % [k, n])
	names.append_array(["time", "clock_left", "resolve_own", "resolve_enemy", "flags_own", "flags_enemy",
			"line_own", "line_enemy", "horse_own", "horse_enemy", "shooters_own", "shooters_enemy"])
	return names


static func feature_units() -> Dictionary:
	return {
		"present": "1 if the flag exists", "owner": "1 ours, -1 theirs, 0 no one's",
		"progress": "capture progress toward us, -1 to 1",
		"own_line": "our line's strength bound for or nearest the flag (thousands of AI._power)",
		"own_other": "our horse, shooters and guns nearest the flag (thousands)",
		"enemy": "enemy strength coming for the flag, as the allotment judges it: the flag nearest where it is headed (AI._lead), thousands",
		"distance": "from our line's middle to the flag, thousands of units",
		"time": "battle seconds / 100", "clock_left": "seconds to the deadline / 100, or -1 with none",
		"resolve_own": "/ 100", "resolve_enemy": "/ 100", "flags_own": "count", "flags_enemy": "count",
		"line_own": "thousands", "line_enemy": "thousands", "horse_own": "thousands", "horse_enemy": "thousands",
		"shooters_own": "thousands", "shooters_enemy": "thousands",
	}


static func choice_names() -> PackedStringArray:
	var names := PackedStringArray(["allotment"])
	for k in MAX_FLAGS:
		names.append("line_to_flag%d" % k)
	return names


## What side `team` sees of `b`, in feature_names() order. Fordline hides
## nothing, so this is the whole battle, from that side.
static func features(b: Battle, team: int) -> PackedFloat64Array:
	var mine := AI._fighting(b, team)
	var foes := AI._fighting(b, 1 - team)
	var line := AI._line(mine, [] as Array[int])
	var centre := Vector2.ZERO
	for r in line:
		centre += r.pos
	centre = centre / line.size() if not line.is_empty() else b.terrain.size * 0.5
	var sign := 1.0 if team == 0 else -1.0
	var out := PackedFloat64Array()
	for k in MAX_FLAGS:
		if k >= b.flags.size():
			for n in 7:
				out.append(0.0)
			continue
		var f: Dictionary = b.flags[k]
		var own_line := 0.0
		var own_other := 0.0
		for r in mine:
			var i := AI._bound_flag(b, r) if r in line else -1
			if i < 0:
				i = AI._nearest_flag(b, r.pos, AI.THREAT_REACH)
			if i == k and r.kind != K.GENERAL:
				if r in line:
					own_line += AI._power(r)
				else:
					own_other += AI._power(r)
		var enemy := 0.0
		for e in foes:
			if e.kind != K.GENERAL and AI._nearest_flag(b, AI._lead(b, e), AI.THREAT_REACH) == k:
				enemy += AI._power(e)
		out.append(1.0)
		out.append(0.0 if f.owner < 0 else (1.0 if f.owner == team else -1.0))
		out.append(f.progress * sign)
		out.append(own_line / POWER_UNIT)
		out.append(own_other / POWER_UNIT)
		out.append(enemy / POWER_UNIT)
		out.append(centre.distance_to(f.pos) / 1000.0)
	out.append(b.time / 100.0)
	out.append((b.deadline - b.time) / 100.0 if b.deadline > 0.0 else -1.0)
	out.append(b.resolve[team] / 100.0)
	out.append(b.resolve[1 - team] / 100.0)
	out.append(b.flags_held(team))
	out.append(b.flags_held(1 - team))
	for side in [mine, foes]:
		out.append(_sum_power(AI._line(side, [] as Array[int])) / POWER_UNIT)
	for side in [mine, foes]:
		out.append(_sum_power(side.filter(func(r): return r.kind == K.CAVALRY)) / POWER_UNIT)
	for side in [mine, foes]:
		out.append(_sum_power(side.filter(func(r): return UnitTypes.is_ranged(r.kind))) / POWER_UNIT)
	return out


static func _sum_power(regs: Array) -> float:
	var total := 0.0
	for r in regs:
		total += AI._power(r)
	return total


## Fight `b` with the planner as side `team` against the AI as `enemy`, and
## return a row per re-plan: {episode, step, t, state, legal, rollout,
## rollout_n, label, outcome}. `settings` may set the planner's replan,
## horizon, samples and budget, and the battle's length. The battle and its
## seats are as the luck study's,
## `die` setting when each first looks.
static func fight(b: Battle, team: int, persona: Dictionary, enemy: Dictionary, die: int, episode: String, settings := {}) -> Array[Dictionary]:
	var planner := Commander.PlannerCommander.new(persona, false, enemy)
	planner.replan = settings.get("replan", planner.replan)
	planner.horizon = settings.get("horizon", planner.horizon)
	planner.samples = settings.get("samples", planner.samples)
	planner.budget = settings.get("budget", planner.budget)
	var rows: Array[Dictionary] = []
	var samples := planner.samples
	planner.on_choice = func(at: Battle, side: int, scores: Dictionary, chosen: int) -> void:
		var legal: Array[int] = []
		var rollout: Array = []
		for i in MAX_FLAGS + 1:
			var c := i - 1
			rollout.append(snappedf(scores[c], 0.0001) if scores.has(c) else null)
			if scores.has(c):
				legal.append(i)
		var state := features(at, side)
		rows.append({
			"episode": episode, "step": rows.size(), "t": snappedf(at.time, 0.01),
			"state": Array(state).map(func(x): return snappedf(x, 0.0001)),
			"legal": legal, "rollout": rollout, "rollout_n": samples, "label": chosen + 1,
		})
	var run := BattleRun.new(b)
	var seats := [BattleRun.Seat.new(1 - team, Commander.AICommander.new(enemy)), BattleRun.Seat.new(team, planner)]
	for i in seats.size():
		Fights.first_look(seats[i], i, die)
		run.add_seat(seats[i])
	run.begin()
	run.run_for(settings.get("length", Fights.length(b)))
	# The planner holds the window and the window the rows; let it go.
	planner.on_choice = Callable()
	var outcome := 0.5 if b.winner < 0 else (1.0 if b.winner == team else 0.0)
	for row in rows:
		row.outcome = outcome
	return rows
