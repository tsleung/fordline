extends SceneTree
## Luck or skill? Fights one campaign battle many times, varying three
## things independently:
##   the commander - the player policies in POLICIES
##   the draw      - the map and the enemy roster swap (a run seed)
##   the dice      - the battle's own random numbers (reloads, scatter)
## and prints one ROW line of JSON per battle for tests/luck_skill.py.
##   Godot --headless --path . -s tests/luck_skill.gd -- --battle=2 --draws=6 --dice=3
## --policies=sharp,reserve fights only those.

const K := UnitTypes.Kind
const DT := 1.0 / 15.0
const TIME_CAP := 600.0

## Player policies: a ladder of rising skill (idle to sharp), then sharp
## with one change each (reserve, hills). think: seconds between decisions.
## persona: the AI persona it plays with. rally: whether it blows the horn
## when regiments near the general break.
const POLICIES := {
	"idle": {"think": 0.0, "persona": {"hold": 8.0, "flank": false}, "rally": false},
	"slow": {"think": 4.0, "persona": {"hold": 8.0, "flank": false}, "rally": false},
	"standard": {"think": 0.75, "persona": AI.PERSONAS["balanced"], "rally": false},
	"sharp": {"think": 0.4, "persona": AI.PERSONAS["balanced"], "rally": true},
	"reserve": {"think": 0.4, "persona": AI.PERSONAS["reserve"], "rally": true},
	"hills": {"think": 0.4, "persona": AI.PERSONAS["hills"], "rally": true},
}


func _initialize() -> void:
	var battle_index := 0
	var draws := 6
	var dice := 3
	var chosen := PackedStringArray(POLICIES.keys())
	for arg in OS.get_cmdline_user_args():
		var value := int(arg.get_slice("=", 1))
		if arg.begins_with("--battle="):
			battle_index = value
		elif arg.begins_with("--draws="):
			draws = value
		elif arg.begins_with("--dice="):
			dice = value
		elif arg.begins_with("--policies="):
			chosen = arg.get_slice("=", 1).split(",")
	for draw in draws:
		for die in dice:
			for policy in chosen:
				print("ROW ", JSON.stringify(_fight(battle_index, draw, die, policy)))
	quit()


func _fight(battle_index: int, draw: int, die: int, policy_name: String) -> Dictionary:
	var run := Campaign.new_run(1000 + draw)
	run.battle = battle_index
	for i in battle_index:
		run = Campaign.apply_reward(run, {"id": "recruit", "kind": UnitTypes.RECRUITABLE[(i + draw) % 5]})
	var b := Campaign.make_battle(run)
	b.rng.seed = 7919 * (die + 1)
	var policy: Dictionary = POLICIES[policy_name]
	var persona: Dictionary = policy.persona
	var enemy: Dictionary = AI.PERSONAS[Campaign.BATTLES[battle_index].persona]
	var fielded := [Telemetry.fielded(b, 0), Telemetry.fielded(b, 1)]
	var tracker := Telemetry.LeadTracker.new()
	var enemy_think := 0.0
	var player_think := 0.0
	var sample := 0.0
	b.begin()
	while b.phase == "battle" and b.time < TIME_CAP:
		enemy_think -= DT
		if enemy_think <= 0.0:
			enemy_think = AI.THINK_EVERY
			b.apply_orders(AI.decide(b, 1, enemy))
		player_think -= DT
		if policy.think > 0.0 and player_think <= 0.0:
			player_think = policy.think
			b.apply_orders(AI.decide(b, 0, persona))
			if policy.rally and _should_rally(b):
				b.apply_orders([{"type": "rally"}])
		b.step(DT)
		b.take_events()
		sample -= DT
		if sample <= 0.0:
			sample = 1.0
			tracker.sample(Telemetry.lead(b, fielded))
	return {
		"battle": battle_index, "draw": draw, "dice": die, "policy": policy_name,
		"won": b.winner == 0, "margin": b.resolve[0] - b.resolve[1], "time": snappedf(b.time, 0.1),
		"lead_changes": tracker.changes, "killed": b.killed,
	}


func _should_rally(b: Battle) -> bool:
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
