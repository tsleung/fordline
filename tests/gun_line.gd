extends SceneTree
## The siege slog, measured (DESIGN.md, "Next: gates that matter", step 1):
## the gun-line player (Fights.GunLineCommander) against the standard AI
## player, which assaults with everything, on the same dice. Per battle it
## prints a SIEGE line of JSON for tests/play.py: won, time, the share of its
## men the player lost, and when the walls were clear of enemy shooters and
## each gate fell (-1: never). tests/studies.sh NAME siege runs it.
##   Godot --headless --path . -s tests/gun_line.gd -- --scenarios=storm,breach --dice=8

const POLICIES := ["gun_line", "standard"]


func _initialize() -> void:
	var scenarios := PackedStringArray(["storm", "breach"])
	var dice := 8
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenarios="):
			scenarios = arg.get_slice("=", 1).split(",")
		elif arg.begins_with("--dice="):
			dice = int(arg.get_slice("=", 1))
	for id in scenarios:
		for die in dice:
			for policy in POLICIES:
				print("SIEGE ", JSON.stringify(_fight(id, die, policy)))
	quit()


func _fight(id: String, die: int, policy: String) -> Dictionary:
	var spec := Scenarios.resolve(id, 1000)
	var b := Scenarios.make_battle(spec, 7919 * (die + 1))
	var enemy: Dictionary = AI.PERSONAS[spec.persona]
	var player: BattleRun.Seat
	if policy == "gun_line":
		player = BattleRun.Seat.new(0, Fights.GunLineCommander.new(), 0.75)
	else:
		player = Fights.player_seat(policy, enemy)
	var seats: Array = [BattleRun.Seat.new(1, Commander.AICommander.new(enemy)), player]
	var run := BattleRun.new(b)
	for i in seats.size():
		Fights.first_look(seats[i], i, die)
		run.add_seat(seats[i])
	var start := _men(b, 0)
	var when := {"walls_clear": -1.0, "gate_0": -1.0, "gate_1": -1.0}
	run.begin()
	var end := Fights.length(b)
	while b.phase == "battle" and b.time < end:
		run.advance()
		if when.walls_clear < 0.0 and not b.team_regiments(1).any(func(r): return r.fighting() and UnitTypes.is_ranged(r.kind)):
			when.walls_clear = snappedf(b.time, 0.1)
		for g in b.terrain.gates.size():
			var key := "gate_%d" % g
			if when[key] < 0.0 and b.terrain.gate_broken[g]:
				when[key] = snappedf(b.time, 0.1)
	var row := {"scenario": id, "dice": die, "policy": policy, "won": b.winner == 0,
		"time": snappedf(b.time, 0.1), "lost": snappedf(1.0 - float(_men(b, 0)) / start, 0.01)}
	row.merge(when)
	return row


static func _men(b: Battle, team: int) -> int:
	var n := 0
	for r in b.team_regiments(team):
		n += r.men()
	return n

