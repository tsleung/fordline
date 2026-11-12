extends SceneTree
## Does a scenario's ground teach its lesson? Fights each designed scenario
## under several ways of playing it, the naive one and the one its brief
## asks for, on the studies' dice, and prints for each how often it won, the
## share of its men it lost, the stars and the minutes.
##   Godot --headless --path . -s tests/lessons.gd -- --scenario=open_ground --dice=8
## With no --scenario it fights every scenario that has plays of its own.
## --plays=straight,round fights only those. --field prints the distances
## the lesson rests on instead of fighting. --watch=10 also prints, for the
## first die, where every regiment is every 10 seconds. --drain=0.2 fights
## with that flag drain instead of the scenario's, to try one.
## --on-crossings fights a drawn river field with each flag moved onto its
## nearest crossing, where a seeded map would have put it.
##
## Three plays fit any scenario: "stand" gives no orders, "straight" walks
## at the enemy with no holding and no flanking, "balanced" is the standard
## commander. The rest are drills (Drill, below), written for one field:
## when a field is redrawn, its drills are redrawn with it.

const K := UnitTypes.Kind

const STRAIGHT := {"hold": 0.0, "flank": false}
const GENERIC := ["stand", "straight", "balanced"]

## Each scenario's own plays, by name. A drill:
##   wait: seconds before it gives its first order
##   stations: for each kind, where its regiments go, left to right, or
##     "here" to stand where they deployed
##   via: points the whole body passes on the way, keeping its shape
##   then: "ai" hands a regiment to the AI once it arrives; "stand" keeps
##     it on its station, shooting what comes within reach
##   wake: a regiment on the march is handed to the AI when an enemy comes
##     this near (0: never)
##   hunt: once on its station a regiment attacks the nearest enemy of this
##     kind, whatever stands nearer; the drill ends when none is left
##   until_gone: the drill ends when no enemy of this kind fights
##   until_clear: the drill ends when an enemy has come within this of a
##     regiment on its station and none is any longer
##   until_near: the drill ends when an enemy comes within this of a
##     regiment on its station
##   rest: "ai" (the default) leaves the other kinds to the AI; "stand"
##     gives them no orders
##   all_to: the AI sends the whole line to this flag, by index, until it
##     is taken; then the AI allots the line itself
##   barrage: a point; whenever the player's barrage is ready it is called
##     on the enemy nearest that point, if one is within BARRAGE_NEAR of it
##   persona: how the AI plays what it is handed (balanced if not given)
## When a drill ends, all its regiments are the AI's.
const PLAYS := {
	"cuirassiers": {
		"front": {"stations": {K.CAVALRY: "here"}, "then": "stand", "hunt": K.MUSKETS},
		"round": {
			"stations": {K.CAVALRY: [Vector2(300, 130), Vector2(300, 200), Vector2(370, 130), Vector2(370, 200)]},
			"via": [Vector2(110, 600), Vector2(110, 300)],
		},
	},
	"hold": {
		"forward": {
			"stations": {K.SWORDS: [Vector2(590, 320), Vector2(710, 320)], K.PIKES: [Vector2(650, 320)]},
		},
		"stay": {
			"stations": {
				K.SWORDS: [Vector2(200, 427), Vector2(1100, 427)], K.PIKES: [Vector2(650, 427)],
				K.ARCHERS: [Vector2(425, 480), Vector2(875, 480)],
			},
			"then": "stand",
		},
	},
	"fords_shot": {
		"bank": {
			"stations": {
				K.PIKES: [Vector2(200, 377), Vector2(650, 377), Vector2(1100, 377)],
				K.MUSKETS: [Vector2(200, 430), Vector2(650, 430), Vector2(1100, 430)],
			},
			"then": "stand",
		},
	},
	"bridges": {
		"east": {"all_to": 2, "barrage": Vector2(870, 350)},
		"west": {"all_to": 1, "barrage": Vector2(430, 350)},
	},
	"battery": {
		"front": {"all_to": 1},
	},
	"push": {
		"charge": {"stations": {K.PIKES: [Vector2(530, 300), Vector2(650, 300), Vector2(770, 300)]}},
		"rise": {
			"stations": {
				K.PIKES: [Vector2(470, 540), Vector2(650, 540), Vector2(830, 540)],
				K.MUSKETS: [Vector2(560, 540), Vector2(740, 540), Vector2(920, 540)],
				K.CANNONS: [Vector2(380, 540)],
			},
			"then": "stand", "until_near": 90.0,
		},
	},
	"open_ground": {
		"front": {"all_to": 0},
		"round": {"all_to": 1},
	},
	"trees": {
		"late": {"wait": 12.0},
	},
	"gunners": {
		"hill": {"all_to": 1},
		"hunt": {"stations": {K.RIFLES: "here"}, "then": "stand", "hunt": K.CANNONS},
	},
	"creek": {
		"bank": {
			"stations": {K.RIFLES: [Vector2(180, 320), Vector2(590, 337), Vector2(650, 415), Vector2(710, 337), Vector2(1120, 320)]},
			"then": "stand",
		},
	},
	"fords_line": {
		"bank": {
			"stations": {K.LINE: [Vector2(270, 372), Vector2(390, 372), Vector2(910, 372), Vector2(1030, 372)]},
			"then": "stand",
		},
	},
	"bridge_dawn": {
		"ford": {"stations": {K.CAVALRY: [Vector2(110, 300)]}, "via": [Vector2(110, 520)]},
		"no_horse": {"stations": {K.CAVALRY: "here"}, "then": "stand"},
	},
	"receive": {
		"receive": {"stations": {K.LINE: "here", K.CANNONS: "here"}, "then": "stand", "until_gone": K.CAVALRY},
	},
	"horse_guns": {
		"show": {"stations": {K.CAVALRY: [Vector2(175, 170), Vector2(175, 300), Vector2(1125, 300)]}, "then": "stand"},
		"no_horse": {"stations": {K.CAVALRY: "here"}, "then": "stand"},
	},
}


func _initialize() -> void:
	var ids := PackedStringArray(PLAYS.keys())
	var dice := 8
	var chosen := PackedStringArray()
	var field := false
	var watch := 0.0
	var drain := -1.0
	var on_crossings := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="):
			ids = arg.get_slice("=", 1).split(",")
		elif arg.begins_with("--dice="):
			dice = int(arg.get_slice("=", 1))
		elif arg.begins_with("--plays="):
			chosen = arg.get_slice("=", 1).split(",")
		elif arg == "--field":
			field = true
		elif arg == "--on-crossings":
			on_crossings = true
		elif arg.begins_with("--drain="):
			drain = float(arg.get_slice("=", 1))
		elif arg.begins_with("--watch="):
			watch = float(arg.get_slice("=", 1))
	for id in ids:
		var spec := Scenarios.resolve(id, 1)
		if drain >= 0.0:
			spec.flag_drain = drain
		if on_crossings:
			_flags_to_crossings(spec)
		if field:
			_print_field(spec)
			continue
		var plays: Array = GENERIC + PLAYS.get(id, {}).keys()
		for play in plays:
			if chosen.is_empty() or play in chosen:
				_report(spec, play, dice, watch)
	quit()


## Move each flag of the scenario's plan onto the crossing nearest it.
func _flags_to_crossings(spec: Dictionary) -> void:
	var t := Terrain.from_plan(spec.plan)
	for f in spec.plan.flags:
		var best: Dictionary = t.crossings[0]
		for c in t.crossings:
			if absf(c.x - f.at.x) < absf(best.x - f.at.x):
				best = c
		f.at = Vector2(best.x, t.river_y(best.x))


## One play of one scenario over the dice, as a LESSON line.
func _report(spec: Dictionary, play: String, dice: int, watch: float) -> void:
	var wins := 0
	var lost := 0.0
	var stars := 0
	var seconds := 0.0
	for die in dice:
		var b := Scenarios.make_battle(spec, 7919 * (die + 1))
		var fielded := Telemetry.fielded(b, 0)
		var run := BattleRun.new(b)
		var seats := [
			BattleRun.Seat.new(1, Commander.AICommander.new(AI.PERSONAS[spec.persona])),
			BattleRun.Seat.new(0, _commander(spec.id, play), 0.75),
		]
		for i in seats.size():
			Fights.first_look(seats[i], i, die)
			run.add_seat(seats[i])
		run.begin()
		while watch > 0.0 and die == 0 and b.phase == "battle":
			_print_watch(b)
			run.run_for(watch)
		run.run_for(Fights.length(b))
		wins += 1 if b.winner == 0 else 0
		lost += 1.0 - float(Telemetry.fielded(b, 0)) / fielded
		stars += Scenarios.stars(spec, b)
		seconds += b.time
	print("LESSON %-12s %-10s won %d of %d  men lost %3d%%  stars %.1f  minutes %.1f" % [
		spec.id, play, wins, dice, roundi(100.0 * lost / dice), float(stars) / dice, seconds / dice / 60.0])


func _commander(id: String, play: String) -> Commander:
	match play:
		"stand":
			return Commander.new()
		"straight":
			return Commander.AICommander.new(STRAIGHT)
		"balanced":
			return Commander.AICommander.new(AI.PERSONAS["balanced"])
	return Drill.new(PLAYS[id][play])


## Where every regiment is now: kind, place, men, and what it is doing.
func _print_watch(b: Battle) -> void:
	print("WATCH %3ds  resolve %d/%d  flags %s" % [int(b.time), int(b.resolve[0]), int(b.resolve[1]), ",".join(b.flags.map(func(f): return str(f.owner)))])
	for r in b.regiments:
		if r.alive():
			print("    %d %-8s (%4d,%4d) men %2d  morale %3d  %s%s" % [
				r.team, UnitTypes.label(r.kind), roundi(r.pos.x), roundi(r.pos.y), r.men(), roundi(r.morale),
				Regiment.State.keys()[r.state], " square" if r.square else ""])


## The distances a field's lesson rests on: each flag, how high it stands,
## whether it is in cover and how far it is from the river; each drill's
## stations; and each regiment as deployed, with its distance to the
## nearest flag.
func _print_field(spec: Dictionary) -> void:
	var b := Scenarios.make_battle(spec, 1)
	var t := b.terrain
	print("FIELD %s" % spec.id)
	for i in b.flags.size():
		var at: Vector2 = b.flags[i].pos
		var name := t.flag_names[i] if i < t.flag_names.size() else "flag %d" % i
		var water := "  %d from the river" % roundi(absf(at.y - t.river_y(at.x))) if t.has_river else ""
		print("  %-14s at (%d, %d)  height %.2f  cover %.1f%s" % [name, roundi(at.x), roundi(at.y), t.height(at), t.cover(at), water])
	for play in PLAYS.get(spec.id, {}):
		var stations: Dictionary = PLAYS[spec.id][play].get("stations", {})
		for kind in stations:
			if stations[kind] is Array:
				for p in stations[kind]:
					print("  %s: %s station at (%d, %d)  height %.2f  cover %.1f" % [play, UnitTypes.label(kind), roundi(p.x), roundi(p.y), t.height(p), t.cover(p)])
	for team in 2:
		for r in b.team_regiments(team):
			var nearest := INF
			for f in b.flags:
				nearest = minf(nearest, r.pos.distance_to(f.pos))
			print("  team %d %-8s at (%d, %d)  %d from the nearest flag" % [team, UnitTypes.label(r.kind), roundi(r.pos.x), roundi(r.pos.y), roundi(nearest)])


## A way of playing written down: regiments walk to their stations, by a
## route, and then stand there, hunt one kind of enemy, or are handed to the
## AI. See PLAYS.
class Drill extends Commander:
	## How near its point an enemy must be for the barrage to be called.
	const BARRAGE_NEAR := 150.0

	var play: Dictionary
	var persona: Dictionary
	## Each regiment still under the drill, by id, to its station.
	var _station := {}
	## Every regiment the drill ever commanded.
	var _drilled: Array[int] = []
	var _sent := false
	## Whether an enemy has yet come within until_clear of a station.
	var _met := false

	func _init(with_play: Dictionary) -> void:
		play = with_play
		persona = play.get("persona", AI.PERSONAS["balanced"])

	func decide(b: Battle, team: int, _ids: Array[int] = []) -> Array:
		if b.time < play.get("wait", 0.0):
			return []
		var orders: Array = []
		if not _sent:
			_sent = true
			orders.append_array(_send(b, team))
		var foes: Array[Regiment] = []
		for f in b.team_regiments(1 - team):
			if f.fighting():
				foes.append(f)
		if team == 0 and play.has("barrage") and "barrage" in b.abilities and b.cooldowns.barrage <= 0.0:
			var mark: Regiment = null
			for f in foes:
				var d: float = f.pos.distance_to(play.barrage)
				if d < BARRAGE_NEAR and (mark == null or d < mark.pos.distance_to(play.barrage)):
					mark = f
			if mark != null:
				orders.append({"type": "barrage", "pos": mark.pos})
		if _over(b, foes):
			_station.clear()
		var wake: float = play.get("wake", 0.0)
		var free: Array[int] = []
		for r in b.team_regiments(team):
			if not r.fighting():
				continue
			if _station.has(r.id):
				var woken := wake > 0.0 and foes.any(func(f): return f.pos.distance_to(r.pos) < wake)
				if woken or (_arrived(r) and play.get("then", "ai") == "ai"):
					_station.erase(r.id)
			if _station.has(r.id):
				var prey := _prey(r, foes)
				if prey != null and r.target_id != prey.id:
					orders.append({"type": "attack", "id": r.id, "target": prey.id})
			elif play.get("rest", "ai") == "ai" or r.id in _drilled:
				free.append(r.id)
		var plan := {}
		if play.has("all_to") and b.flags[play.all_to].owner != team:
			for id in free:
				plan[id] = play.all_to
		if not free.is_empty():
			orders.append_array(AI.decide(b, team, persona, plan, free))
		return orders

	func _arrived(r: Regiment) -> bool:
		return r.pos.distance_to(_station[r.id]) < 12.0

	## The enemy of the hunted kind nearest `r`, once it has reached its
	## station; null when the play hunts nothing.
	func _prey(r: Regiment, foes: Array[Regiment]) -> Regiment:
		if not play.has("hunt") or (r.target_id < 0 and not _arrived(r)):
			return null
		var best: Regiment = null
		for f in foes:
			if f.kind == play.hunt and (best == null or f.pos.distance_to(r.pos) < best.pos.distance_to(r.pos)):
				best = f
		return best

	## Whether the drill is over, and every regiment the AI's: the kind it
	## waited out or hunted is gone, or the enemy that came within
	## until_clear of a regiment standing on its station is there no longer.
	func _over(b: Battle, foes: Array[Regiment]) -> bool:
		for key in ["until_gone", "hunt"]:
			if play.has(key) and not foes.any(func(f): return f.kind == play[key]):
				return true
		if play.has("until_near"):
			var near_to: float = play.until_near
			for id in _station:
				var r := b.get_regiment(id)
				if r.fighting() and _arrived(r) and foes.any(func(f): return f.pos.distance_to(r.pos) < near_to):
					return true
		if not play.has("until_clear"):
			return false
		var standing := _station.keys().map(func(id): return b.get_regiment(id)).filter(func(r): return r.fighting() and _arrived(r))
		var near: bool = standing.any(func(r): return foes.any(func(f): return f.pos.distance_to(r.pos) < play.until_clear))
		_met = _met or near
		return _met and not near

	## The first orders: each drilled regiment's route to its station. A
	## kind whose stations are "here" stands where it deployed.
	func _send(b: Battle, team: int) -> Array:
		var orders: Array = []
		var stations: Dictionary = play.get("stations", {})
		var centre := Vector2.ZERO
		var count := 0
		for kind in stations:
			if stations[kind] is Array:
				for p in stations[kind]:
					centre += p
					count += 1
		centre /= maxi(count, 1)
		for kind in stations:
			var body := b.team_regiments(team).filter(func(r): return r.kind == kind and r.fighting())
			body.sort_custom(func(x, y): return x.pos.x < y.pos.x)
			for i in body.size():
				var r: Regiment = body[i]
				if not stations[kind] is Array:
					_station[r.id] = r.pos
					_drilled.append(r.id)
					continue
				if i >= stations[kind].size():
					break
				var station: Vector2 = stations[kind][i]
				_station[r.id] = station
				_drilled.append(r.id)
				var legs: Array = play.get("via", []).map(func(p): return b.terrain.clamp_to_field(p + station - centre))
				legs.append(station)
				for k in legs.size():
					orders.append({"type": "move", "id": r.id, "to": legs[k], "append": k > 0})
		return orders
