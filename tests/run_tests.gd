extends SceneTree
## Headless checks: the rules, the maps, the campaign, and whole battles
## fought AI against AI.
##   godot --headless --path . -s tests/run_tests.gd [-- --quick]

const K := UnitTypes.Kind

var _failures := 0
## Lead changes in the last battle _fight fought.
var _lead_changes := 0
var _checks := 0


func _initialize() -> void:
	_run()


## A coroutine, because the screen test needs a frame for its nodes to
## enter the tree.
func _run() -> void:
	var quick := "--quick" in OS.get_cmdline_user_args()
	_test_combat()
	_test_terrain()
	_test_campaign()
	await _test_routes()
	_test_battles(quick)
	print("\n%d checks, %d failed" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		print("FAIL: ", what)


func _test_combat() -> void:
	_check(Combat.type_mult(K.PIKES, K.CAVALRY) == 2.5, "pikes beat cavalry")
	_check(Combat.type_mult(K.SWORDS, K.PIKES) == 1.5, "swords beat pikes")
	_check(Combat.type_mult(K.CAVALRY, K.ARCHERS) > 1.0, "cavalry beats archers")
	var facing_up := -PI * 0.5
	_check(Combat.zone(Vector2.ZERO, facing_up, Vector2(0, -50)) == Combat.Zone.FRONT, "front zone")
	_check(Combat.zone(Vector2.ZERO, facing_up, Vector2(50, 0)) == Combat.Zone.SIDE, "side zone")
	_check(Combat.zone(Vector2.ZERO, facing_up, Vector2(0, 50)) == Combat.Zone.REAR, "rear zone")
	_check(not Combat.charge_lands(K.PIKES, Combat.Zone.FRONT), "pikes brace a frontal charge")
	_check(Combat.charge_lands(K.PIKES, Combat.Zone.REAR), "pikes caught from behind")
	var front := Combat.melee_dps(K.SWORDS, 32, 8, 1.0, K.SWORDS, 0.3, Combat.Zone.FRONT, false)
	var rear := Combat.melee_dps(K.SWORDS, 32, 8, 1.0, K.SWORDS, 0.3, Combat.Zone.REAR, false)
	_check(is_equal_approx(rear / front, 2.2), "rear hits 2.2x")
	_check(Combat.fighting_men(32, 8) == 16, "two ranks fight")
	_check(Combat.stars_for_kills(0) == 0 and Combat.stars_for_kills(60) == 3, "stars from kills")
	_check(Combat.fatigue_hit(1.0) == 1.0 and Combat.fatigue_hit(0.0) == Combat.SPENT_HIT, "spent regiments hit softer")
	_check(Combat.fatigue_nerve(0.0) > Combat.fatigue_nerve(1.0), "spent regiments break sooner")
	_check(_duel(1.0, 1.0) == "even", "fresh against fresh is even")
	_check(_duel(1.0, 0.2) == "first", "fresh swords beat tired swords")


## Two sword regiments meet head on, the first with stamina a, the second
## with stamina b, on open ground; which breaks first?
func _duel(a: float, b: float) -> String:
	var t := Terrain.generate("woods", 1)
	t.forests.clear()
	t.hills.clear()
	var battle := Battle.new(t, 1)
	var mid := Terrain.SIZE * 0.5
	var first := battle.add_regiment(0, K.SWORDS, 48, mid + Vector2(0, 30), -PI * 0.5, 0, {})
	var second := battle.add_regiment(1, K.SWORDS, 48, mid - Vector2(0, 30), PI * 0.5, 0, {})
	first.stamina = a
	second.stamina = b
	battle.begin()
	while battle.time < 120.0:
		battle.step(1.0 / 15.0)
		var first_broke := not first.fighting()
		var second_broke := not second.fighting()
		if first_broke and second_broke:
			return "even"
		if second_broke:
			return "first"
		if first_broke:
			return "second"
	return "even"


func _test_terrain() -> void:
	for kind in ["fords", "woods", "bridges", "roads", "ridge"]:
		for s in 6:
			var t := Terrain.generate(kind, 1000 + s)
			var tag := "%s/%d" % [kind, s]
			_check(t.flags.size() == 3, tag + " has three flags")
			for f in t.flags:
				_check(not t.is_water(f), tag + " flag on dry ground or a crossing")
			var from := Vector2(Terrain.SIZE.x * 0.3, Terrain.SIZE.y - 100.0)
			var to := Vector2(Terrain.SIZE.x * 0.7, 100.0)
			var way := t.path(from, to)
			_check(way[way.size() - 1].distance_to(to) < 1.0, tag + " path ends at the goal")
			if t.has_river:
				var dry := true
				var last := from
				for w in way:
					for i in 40:
						if t.is_water(last.lerp(w, i / 40.0)):
							dry = false
					last = w
				_check(dry, tag + " path never wades except at a crossing")
				var banks := 0
				for i in way.size() - 1:
					if t.side(way[i]) != t.side(way[i + 1]):
						banks += 1
						_check(not t.crossing_at(way[i].x).is_empty(), tag + " river crossed at a crossing")
				_check(banks == 1, tag + " path crosses the river once")
			var b := Battle.new(t, s)
			for k in [K.SWORDS, K.PIKES, K.ARCHERS, K.CAVALRY, K.CANNONS, K.GENERAL, K.SWORDS, K.SWORDS]:
				b.add_regiment(0, k, 40, Terrain.SIZE * 0.5, 0.0, 0, {})
				b.add_regiment(1, k, 40, Terrain.SIZE * 0.5, 0.0, 0, {})
			b.apply_orders(AI.deploy_orders(b, 0))
			b.apply_orders(AI.deploy_orders(b, 1))
			for r in b.regiments:
				_check(t.in_deploy(r.team, r.pos) or t.clamp_deploy(r.team, r.pos) == r.pos, tag + " deployed inside the zone")
				_check(not t.is_water(r.pos), tag + " deployed on dry ground")


func _test_campaign() -> void:
	var run := Campaign.new_run(42)
	_check(run.roster.size() == 7, "starting roster is the general and six regiments")
	_check(Campaign.enemy_army(run).size() == 6, "first enemy is the general and five regiments")
	var picks := Campaign.offer_rewards(run)
	_check(picks.size() == 3, "three rewards on offer")
	_check(picks.any(func(p): return p.id == "recruit"), "a recruit is always on offer")
	var titles := {}
	for p in picks:
		titles[p.title] = true
	_check(titles.size() == 3, "rewards are distinct")
	var units: Array = []
	for i in run.roster.size():
		units.append({"roster_index": i, "men": 10 if i == 1 else run.roster[i].men, "kills": 15 if i == 1 else 0, "fled": false})
	units.remove_at(2)
	var after := Campaign.after_battle(run, {"won": true, "time": 120.0, "kills": 40, "units": units})
	_check(after.roster.size() == 6, "a destroyed regiment leaves the roster")
	var full: int = UnitTypes.stat(K.SWORDS, "men")
	_check(after.roster[1].men == 10 + int(ceil((full - 10) * Campaign.REFILL)), "losses refill by 40%")
	_check(after.roster[1].stars == 1, "kills earn a star")
	var survivors := 0
	for u in units:
		survivors += u.men
	_check(after.score == 1000 + 2 * 40 + survivors + 60 * 3, "score counts win, kills, survivors, speed")
	_check(run.roster.size() == 7, "after_battle leaves the old run alone")
	var drilled := Campaign.apply_reward(after, {"id": "doctrine", "name": "drill"})
	_check(is_equal_approx(drilled.doctrine["atk_0"], 1.12), "drill raises sword attack")
	_check(not after.doctrine.has("atk_0"), "apply_reward leaves the old run alone")
	var lost := Campaign.after_battle(run, {"won": false, "time": 200.0, "kills": 5, "units": units})
	_check(lost.over and not lost.won, "a defeat ends the run")


## Waypoints through the real battle screen: tap a regiment, tap the
## field, tap the route's end to pin it, tap again; the route runs through
## the first stop to the second. Without the pin a tap replaces the route;
## shift-click appends.
func _test_routes() -> void:
	var screen = preload("res://scripts/battle_screen.gd").new()
	screen.setup(Campaign.make_battle(Campaign.new_run(9)), "dug_in", "routes")
	root.add_child(screen)
	await process_frame
	screen.begin_battle()
	var r: Regiment = screen.battle.team_regiments(0).filter(func(x): return x.kind == K.SWORDS)[0]
	var first: Vector2 = r.pos + Vector2(-140.0, -30.0)
	var second: Vector2 = r.pos + Vector2(-260.0, 20.0)
	_tap(screen, r.pos)
	_check(screen.selected == [r.id], "tapping a banner selects it")
	_tap(screen, first)
	_check(screen.route_end(r).distance_to(first) < 1.0, "tapping the field sends it there")
	_tap(screen, first)
	_check(screen.pinned, "tapping the route's end pins it")
	_tap(screen, second)
	_check(not screen.pinned, "the next tap uses the pin up")
	_check(screen.route_end(r).distance_to(second) < 1.0, "the pinned route ends at the new stop")
	_check(Array(r.waypoints).any(func(w): return w.distance_to(first) < 1.0), "the pinned route still goes through the first stop")
	_tap(screen, first)
	_check(not Array(r.waypoints).any(func(w): return w.distance_to(second) < 1.0), "a tap without the pin replaces the route")
	screen._press(screen.to_screen(second), false, true)
	screen._release(screen.to_screen(second))
	_check(screen.route_end(r).distance_to(second) < 1.0 and Array(r.waypoints).any(func(w): return w.distance_to(first) < 1.0), "shift-click adds a stop")
	screen.free()


func _tap(screen, world_pos: Vector2) -> void:
	var sp: Vector2 = screen.to_screen(world_pos)
	screen._press(sp, false, false)
	screen._release(sp)


## Fight every campaign battle AI against AI, the player's army growing by
## one regiment a battle as it would with rewards.
func _test_battles(quick: bool) -> void:
	var wins := 0
	var seeds := [3] if quick else [3, 11, 29]
	for s in seeds:
		var run := Campaign.new_run(s)
		for i in Campaign.BATTLES.size():
			run.battle = i
			if i > 0:
				run = Campaign.apply_reward(run, {"id": "recruit", "kind": UnitTypes.RECRUITABLE[(i + s) % 5]})
			var b := Campaign.make_battle(run)
			var outcome := _fight(b, true, Campaign.BATTLES[i].persona)
			var name: String = Campaign.BATTLES[i].name
			print("  seed %d  %-16s  winner %s  %3ds  kills %d/%d  resolve %d/%d  lead changes %d" % [
				s, name, "player" if b.winner == 0 else "enemy", int(b.time),
				b.killed[0], b.killed[1], int(b.resolve[0]), int(b.resolve[1]), _lead_changes])
			_check(outcome, "seed %d %s ends within the time limit" % [s, name])
			if b.winner == 0:
				wins += 1
	var passive := Campaign.make_battle(Campaign.new_run(5))
	_fight(passive, false, "balanced")
	print("  passive player: winner %s at %ds" % ["player" if passive.winner == 0 else "enemy", int(passive.time)])
	_check(passive.winner == 1, "an army that never moves loses")
	print("  AI-as-player won %d of %d" % [wins, seeds.size() * Campaign.BATTLES.size()])


func _fight(b: Battle, player_acts: bool, persona: String) -> bool:
	b.begin()
	var dt := 1.0 / 15.0
	var think := 0.0
	var enemy: Dictionary = AI.PERSONAS[persona]
	var fielded := [Telemetry.fielded(b, 0), Telemetry.fielded(b, 1)]
	var tracker := Telemetry.LeadTracker.new()
	var sample := 0.0
	while b.phase == "battle" and b.time < 600.0:
		think -= dt
		if think <= 0.0:
			think = AI.THINK_EVERY
			b.apply_orders(AI.decide(b, 1, enemy))
			if player_acts:
				b.apply_orders(AI.decide(b, 0, AI.PERSONAS["balanced"]))
		b.step(dt)
		b.take_events()
		sample -= dt
		if sample <= 0.0:
			sample = 1.0
			tracker.sample(Telemetry.lead(b, fielded))
	_lead_changes = tracker.changes
	return b.phase == "over" and b.time < 420.0
