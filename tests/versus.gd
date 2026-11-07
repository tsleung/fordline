extends SceneTree
## The AI against its yardstick (tests/ai_baseline.gd, the AI of 1 November
## 2026): every quick scenario and campaign battle, the AI as the player
## against the yardstick as the enemy and the other way round, and the
## yardstick against itself for the base rate. The armies, personas and
## dice are the luck study's. A battle's sides are unequal, so the AI is
## stronger when, against the same opponent, it wins more as the player
## than the yardstick does and loses less as the enemy.
##   Godot --headless --path . -s tests/versus.gd -- --job=scenario:hold --dice=4
##   --job=battle:2 --draws=2 fights a campaign battle; --first=5 starts at the
##   sixth draw, to split a long run; --pairs=ai-base,base-ai leaves out the
##   base rate. A pair is player-enemy, each of ai, base, plan (the planner,
##   its look ahead set by --horizon= and --budget=) or, as the player, person
##   (the ladder's person-paced commander).
## Prints one VS line of JSON per battle for tests/play.py --versus.

const PAIRS := [["base", "base"], ["ai", "base"], ["base", "ai"]]


## The yardstick as a commander.
class Baseline extends Commander:
	var persona: Dictionary

	func _init(with_persona: Dictionary) -> void:
		persona = with_persona

	func decide(b: Battle, team: int, _ids: Array[int] = []) -> Array:
		return AIBaseline.decide(b, team, persona)


func _initialize() -> void:
	var job := "scenario:hold"
	var dice := 4
	var draws := 1
	var first := 0
	var pairs: Array = PAIRS
	var settings := {}
	for arg in OS.get_cmdline_user_args():
		var value := arg.get_slice("=", 1)
		if arg.begins_with("--job="):
			job = value
		elif arg.begins_with("--dice="):
			dice = int(value)
		elif arg.begins_with("--draws="):
			draws = int(value)
		elif arg.begins_with("--first="):
			first = int(value)
		elif arg.begins_with("--pairs="):
			pairs = Array(value.split(",")).map(func(p): return p.split("-"))
		elif arg.begins_with("--horizon="):
			settings.horizon = float(value)
		elif arg.begins_with("--budget="):
			settings.budget = int(value)
	var kind := job.get_slice(":", 0)
	var what := job.get_slice(":", 1)
	# Only a campaign battle or a Skirmish draws its field and armies anew.
	var drawn := kind == "battle" or what.begins_with("skirmish")
	for draw in range(first, first + (draws if drawn else 1)):
		for die in dice:
			for pair in pairs:
				print("VS ", JSON.stringify(_fight(kind, what, draw, die, pair[0], pair[1], settings)))
	quit()


func _fight(kind: String, what: String, draw: int, die: int, player: String, enemy: String, settings: Dictionary) -> Dictionary:
	var b: Battle
	var enemy_persona: Dictionary
	if kind == "scenario":
		var spec := Scenarios.resolve(what, 1000 + draw)
		b = Scenarios.make_battle(spec, 7919 * (die + 1))
		enemy_persona = AI.PERSONAS[spec.persona]
	else:
		var index := int(what)
		var run := Campaign.new_run(1000 + draw)
		run.battle = index
		for i in index:
			run = Campaign.apply_reward(run, {"id": "recruit", "kind": UnitTypes.RECRUITABLE[(i + draw) % 5]})
		b = Campaign.make_battle(run)
		b.rng.seed = 7919 * (die + 1)
		enemy_persona = AI.PERSONAS[Campaign.BATTLES[index].persona]
	var fought := BattleRun.new(b)
	var seats := [
		BattleRun.Seat.new(1, _commander(enemy, enemy_persona, AI.PERSONAS.balanced, settings)),
		BattleRun.Seat.new(0, _commander(player, AI.PERSONAS.balanced, enemy_persona, settings), Fights.POLICIES.person.every if player == "person" else AI.THINK_EVERY),
	]
	for i in seats.size():
		Fights.first_look(seats[i], i, die)
		fought.add_seat(seats[i])
	fought.begin()
	fought.run_for(Fights.length(b))
	return {
		"job": kind + ":" + what, "draw": draw, "dice": die, "player": player, "enemy": enemy,
		"won": b.winner == 0, "margin": Measures.margin(b), "time": snappedf(b.time, 0.1),
	}


## A commander of `persona`; a planner reads in the briefing that its rival
## fights as `rival`.
func _commander(which: String, persona: Dictionary, rival: Dictionary, settings: Dictionary) -> Commander:
	match which:
		"ai":
			return Commander.AICommander.new(persona)
		"person":
			return Commander.PacedCommander.new(persona, false, Fights.POLICIES.person.per_look)
		"plan":
			var planner := Commander.PlannerCommander.new(persona, false, rival)
			planner.horizon = settings.get("horizon", planner.horizon)
			planner.budget = settings.get("budget", planner.budget)
			return planner
	return Baseline.new(persona)
