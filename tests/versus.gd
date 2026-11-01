extends SceneTree
## The AI against its yardstick (tests/ai_baseline.gd, the AI of 1 November
## 2026): every quick scenario and campaign battle, the AI as the player
## against the yardstick as the enemy and the other way round, and the
## yardstick against itself for the base rate. The armies, personas and
## dice are the luck study's. A battle's sides are unequal, so the AI is
## stronger when, against the same opponent, it wins more as the player
## than the yardstick does and loses less as the enemy.
##   Godot --headless --path . -s tests/versus.gd -- --job=scenario:hold --dice=4
##   --job=battle:2 --draws=2 fights a campaign battle; --pairs=ai-base,base-ai
##   leaves out the base rate.
## Prints one VS line of JSON per battle for tests/play.py --versus.

const PAIRS := [["base", "base"], ["ai", "base"], ["base", "ai"]]


## The yardstick as a commander.
class Baseline extends Commander:
	var persona: Dictionary

	func _init(with_persona: Dictionary) -> void:
		persona = with_persona

	func decide(b: Battle, team: int) -> Array:
		return AIBaseline.decide(b, team, persona)


func _initialize() -> void:
	var job := "scenario:hold"
	var dice := 4
	var draws := 1
	var pairs: Array = PAIRS
	for arg in OS.get_cmdline_user_args():
		var value := arg.get_slice("=", 1)
		if arg.begins_with("--job="):
			job = value
		elif arg.begins_with("--dice="):
			dice = int(value)
		elif arg.begins_with("--draws="):
			draws = int(value)
		elif arg.begins_with("--pairs="):
			pairs = Array(value.split(",")).map(func(p): return p.split("-"))
	var kind := job.get_slice(":", 0)
	var what := job.get_slice(":", 1)
	# Only a campaign battle or a Skirmish draws its field and armies anew.
	var drawn := kind == "battle" or what.begins_with("skirmish")
	for draw in (draws if drawn else 1):
		for die in dice:
			for pair in pairs:
				print("VS ", JSON.stringify(_fight(kind, what, draw, die, pair[0], pair[1])))
	quit()


func _fight(kind: String, what: String, draw: int, die: int, player: String, enemy: String) -> Dictionary:
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
		BattleRun.Seat.new(1, _commander(enemy, enemy_persona)),
		BattleRun.Seat.new(0, _commander(player, AI.PERSONAS.balanced)),
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


func _commander(which: String, persona: Dictionary) -> Commander:
	return Commander.AICommander.new(persona) if which == "ai" else Baseline.new(persona)
