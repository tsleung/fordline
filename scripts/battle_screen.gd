extends Node
## A battle on screen. Steps the simulation on a fixed tick, lets the enemy
## think, turns taps and drags into orders, and turns the battle's events
## into effects and sound. Selection is screen state; the battle never
## sees it.

signal finished(battle: Battle)
## The player chose to leave the battle, or to fight it again from the
## start; what that means is up to whoever started it.
signal left
signal restarted

const K := UnitTypes.Kind
const S := Regiment.State
const TerrainView := preload("res://scripts/terrain_view.gd")
const CorpseView := preload("res://scripts/corpse_view.gd")
const UnitsView := preload("res://scripts/units_view.gd")
const Hud := preload("res://scripts/hud.gd")

## Screen pixels a press may wander and still count as a tap.
const TAP_SLOP := 14.0
const DOUBLE_TAP := 0.35
const MAX_STEPS_PER_FRAME := 8

var battle: Battle
var demo := false
## The scenario's goal, shown as the battle opens; empty in the campaign.
var goal := ""
## A quick battle: the menu offers Restart, and leaving costs nothing.
var quick := false
var menu_open := false
var _paused_before_menu := false
## Both sides commanded by the AI, with the HUD up: for watching and for
## the screenshot capture in tests/shot.gd.
var autopilot := false
var title := ""
var world: Node2D
var units_view
var hud
var selected: Array[int] = []
var paused := false
var speed := 1.0
## "" or the ability waiting for a point on the field ("barrage").
var targeting := ""
## The press in progress: mode, where it started and where it is now.
var drag := {}
## The selection's route end has been tapped: the next tap on the field adds
## a leg after it instead of replacing the route.
var pinned := false
## Screen pixels from a route's end marker that still count as tapping it.
const END_REACH_PX := 20.0
## How near a gate (in world units) a tap counts as a tap on it.
const GATE_TAP := 50.0

var _persona: Dictionary
var _terrain_view
var _corpses
var _acc := 0.0
var _think := 0.0
var _last_tap := {"id": -1, "at": -10.0}
var _clash_wait := 0.0
var _reported := false
## Enemy horse already called out, and at whom: enemy id -> target id.
var _warned := {}


func setup(b: Battle, persona_name: String, battle_title: String, is_demo := false) -> void:
	battle = b
	_persona = AI.PERSONAS[persona_name]
	title = battle_title
	demo = is_demo


func _ready() -> void:
	world = Node2D.new()
	add_child(world)
	_terrain_view = TerrainView.new()
	world.add_child(_terrain_view)
	_corpses = CorpseView.new()
	world.add_child(_corpses)
	units_view = UnitsView.new()
	units_view.screen = self
	world.add_child(units_view)
	_terrain_view.show_terrain(battle.terrain, hash(title))
	if demo:
		battle.begin()
	else:
		hud = Hud.new()
		hud.screen = self
		add_child(hud)
	get_viewport().size_changed.connect(_fit)
	_fit()


## Fit the field to the space between the bars. On a tall screen the field
## turns a quarter so the long front runs down the screen and your army
## stands on the left.
func _fit() -> void:
	var vp := get_viewport().get_visible_rect().size
	var portrait := vp.y > vp.x * 1.05
	var top: float = 0.0 if demo else hud.top_height(portrait)
	var bottom: float = 0.0 if demo else hud.bottom_height(portrait)
	var avail := Rect2(Vector2(6.0, top + 4.0), vp - Vector2(12.0, top + bottom + 8.0))
	var rot := PI * 0.5 if portrait else 0.0
	var span := Vector2(Terrain.SIZE.y, Terrain.SIZE.x) if portrait else Terrain.SIZE
	var s := minf(avail.size.x / span.x, avail.size.y / span.y)
	if demo:
		s = maxf(vp.x / span.x, vp.y / span.y)
	world.rotation = rot
	world.scale = Vector2(s, s)
	world.position = avail.get_center() - (Terrain.SIZE * 0.5 * s).rotated(rot)
	if hud != null:
		hud.layout(vp, portrait)


func _process(delta: float) -> void:
	if battle.phase == "battle" and not paused:
		_acc += delta * speed
		var steps := 0
		while _acc >= Battle.STEP and steps < MAX_STEPS_PER_FRAME:
			_command(Battle.STEP)
			battle.step(Battle.STEP)
			_acc -= Battle.STEP
			steps += 1
		if steps == MAX_STEPS_PER_FRAME:
			_acc = 0.0
	_react(battle.take_events())
	_warn_of_horse()
	_ambient(delta)
	selected.assign(selected.filter(func(id): return battle.get_regiment(id) != null and battle.get_regiment(id).fighting()))
	if pinned and _route_ends().is_empty():
		pinned = false
	if battle.phase == "over" and not _reported:
		_reported = true
		finished.emit(battle)


func _command(dt: float) -> void:
	_think -= dt
	if _think > 0.0:
		return
	_think = AI.THINK_EVERY
	battle.apply_orders(AI.decide(battle, 1, _persona))
	if demo or autopilot:
		battle.apply_orders(AI.decide(battle, 0, AI.PERSONAS["balanced"]))


# --- the player's commands (also called by the HUD) -----------------------

func begin_battle() -> void:
	if battle.phase != "deploy":
		return
	battle.begin()
	_select([])


func toggle_pause() -> void:
	if battle.phase == "battle" and not menu_open:
		paused = not paused


## The menu stops the battle while it is open and leaves the pause as it
## was when it closes.
func open_menu() -> void:
	if menu_open:
		return
	menu_open = true
	_paused_before_menu = paused
	paused = true
	drag = {}


func close_menu() -> void:
	menu_open = false
	paused = _paused_before_menu


## Leaving a campaign battle once the fighting has started is a retreat,
## and ends the run; the menu asks twice for it.
func leaving_costs() -> bool:
	return not quick and battle.phase == "battle"


func leave_label() -> String:
	if quick:
		return "Back to scenarios"
	if battle.phase == "deploy":
		return "Back to the briefing"
	return "Retreat (ends the campaign)"


func leave() -> void:
	menu_open = false
	left.emit()


func restart() -> void:
	menu_open = false
	restarted.emit()


func toggle_speed() -> void:
	speed = 2.0 if speed == 1.0 else 1.0


func select_all() -> void:
	var ids: Array[int] = []
	for r in battle.team_regiments(0):
		if r.fighting():
			ids.append(r.id)
	_select(ids)
	_click()


func clear_selection() -> void:
	_select([])
	targeting = ""


## Every change of selection goes through here, so a pinned route end
## never carries over to regiments it wasn't pinned for.
func _select(ids: Array[int]) -> void:
	selected = ids
	pinned = false


## Where a regiment's route ends, or NAN when it has no route of its own
## (standing, or closing on a target).
func route_end(r: Regiment) -> Vector2:
	if r.target_id >= 0 or r.waypoints.is_empty():
		return Vector2(NAN, NAN)
	return r.waypoints[r.waypoints.size() - 1]


func _route_ends() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for r in _selected_regiments():
		var end := route_end(r)
		if not is_nan(end.x):
			out.append(end)
	return out


func use_ability(name: String) -> void:
	match name:
		"rally":
			battle.apply_orders([{"type": "rally"}])
		"barrage":
			targeting = "" if targeting == "barrage" else "barrage"
		"march":
			var ids: Array = selected.duplicate()
			if ids.is_empty():
				for r in battle.team_regiments(0):
					ids.append(r.id)
			battle.apply_orders([{"type": "march", "ids": ids}])


# --- input ----------------------------------------------------------------

func to_world(screen_pos: Vector2) -> Vector2:
	return world.get_global_transform_with_canvas().affine_inverse() * screen_pos


func to_screen(world_pos: Vector2) -> Vector2:
	return world.get_global_transform_with_canvas() * world_pos


func _unhandled_input(event: InputEvent) -> void:
	if demo or (menu_open and not event is InputEventKey):
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_RIGHT:
			return
		if mb.pressed:
			_press(mb.position, mb.button_index == MOUSE_BUTTON_RIGHT, mb.shift_pressed)
		else:
			_release(mb.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and not drag.is_empty():
		drag.now_screen = event.position
		drag.now_world = to_world(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				toggle_pause()
			KEY_ESCAPE:
				if menu_open:
					close_menu()
				elif selected.is_empty() and targeting == "":
					open_menu()
				else:
					clear_selection()
			KEY_A:
				select_all()
			KEY_F:
				toggle_speed()


func _press(sp: Vector2, right: bool, shift: bool) -> void:
	var wp := to_world(sp)
	if targeting == "barrage":
		battle.apply_orders([{"type": "barrage", "pos": wp}])
		targeting = ""
		return
	var own := _pick(wp, 0)
	var foe := _pick(wp, 1)
	var mode := "order"
	if not right:
		if battle.phase == "battle" and _on_route_end(sp):
			mode = "end"
		elif own != null:
			mode = "unit"
		elif foe != null:
			mode = "enemy"
		elif selected.is_empty():
			mode = "box"
	drag = {
		"mode": mode, "start_screen": sp, "start_world": wp, "now_screen": sp, "now_world": wp,
		"unit": own.id if own != null else -1, "foe": foe.id if foe != null else -1, "shift": shift,
	}


func _release(sp: Vector2) -> void:
	if drag.is_empty():
		return
	var d := drag
	drag = {}
	var wp := to_world(sp)
	var moved: bool = d.start_screen.distance_to(sp) > TAP_SLOP
	var deploying := battle.phase == "deploy"
	match d.mode:
		"end":
			if not moved:
				pinned = not pinned
				_click()
		"unit":
			if not moved:
				_tap_unit(d.unit, d.shift)
			elif deploying:
				battle.apply_orders([{"type": "place", "id": d.unit, "to": wp}])
				if not d.unit in selected:
					_select([d.unit])
			else:
				if not d.unit in selected:
					_select([d.unit])
				_order_line(d.start_world, wp)
		"enemy":
			if not moved and not selected.is_empty() and not deploying:
				var orders: Array = []
				for id in selected:
					orders.append({"type": "attack", "id": id, "target": d.foe})
				battle.apply_orders(orders)
				units_view.add_fx("mark", battle.get_regiment(d.foe).pos, 0.5)
				_click()
			elif moved and not selected.is_empty():
				_order_line(d.start_world, wp)
		"box":
			if moved:
				_box_select(d.start_screen, sp)
		"order":
			if moved:
				_order_line(d.start_world, wp)
			elif not deploying and _bombard(wp):
				pinned = false
			else:
				_order_point(wp, d.shift or pinned)
				pinned = false


## A tap on an enemy gate with guns selected: the guns batter it and the
## rest of the selection goes to it (foot pressed against it ram it).
func _bombard(wp: Vector2) -> bool:
	var t := battle.terrain
	var g := t.gate_near(wp, GATE_TAP)
	if g < 0 or t.gate_broken[g] or t.holder == 0:
		return false
	var guns := _selected_regiments().filter(func(r): return r.kind == UnitTypes.Kind.CANNONS)
	if guns.is_empty():
		return false
	var orders: Array = []
	for r in _selected_regiments():
		if r.kind == UnitTypes.Kind.CANNONS:
			orders.append({"type": "bombard", "id": r.id, "gate": g})
		else:
			orders.append({"type": "move", "id": r.id, "to": t.gates[g].c + t.gates[g].out * 30.0})
	battle.apply_orders(orders)
	units_view.add_fx("mark", t.gates[g].c, 0.5)
	_click()
	return true


func _tap_unit(id: int, shift: bool) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var r := battle.get_regiment(id)
	var ids: Array[int] = selected.duplicate()
	if _last_tap.id == id and now - _last_tap.at < DOUBLE_TAP:
		ids.clear()
		for o in battle.team_regiments(0):
			if o.kind == r.kind and o.fighting():
				ids.append(o.id)
	elif shift:
		if id in ids:
			ids.erase(id)
		else:
			ids.append(id)
	elif ids.size() == 1 and ids[0] == id:
		ids.clear()
	else:
		ids = [id]
	_select(ids)
	_last_tap = {"id": id, "at": now}
	_click()


func _pick(wp: Vector2, team: int) -> Regiment:
	var best: Regiment = null
	var best_d := INF
	var reach: float = units_view.BANNER_PX * units_view.px() * 1.6
	for r in battle.team_regiments(team):
		if team == 0 and not r.fighting():
			continue
		var d := wp.distance_to(units_view.banner_pos(r))
		if (d < reach or r.hit_test(wp)) and d < best_d:
			best_d = d
			best = r
	return best


func _box_select(a: Vector2, b: Vector2) -> void:
	var rect := Rect2(a, Vector2.ZERO).expand(b)
	var ids: Array[int] = []
	for r in battle.team_regiments(0):
		if r.fighting() and rect.has_point(to_screen(r.pos)):
			ids.append(r.id)
	_select(ids)
	_click()


func _on_route_end(sp: Vector2) -> bool:
	if selected.is_empty():
		return false
	for end in _route_ends():
		if to_screen(end).distance_to(sp) < END_REACH_PX:
			return true
	return false


func _selected_regiments() -> Array[Regiment]:
	var out: Array[Regiment] = []
	for id in selected:
		var r := battle.get_regiment(id)
		if r != null and r.fighting():
			out.append(r)
	return out


## Tap on the field: the selection moves there, keeping its shape. With
## `append`, it goes on from where its route ends instead.
func _order_point(wp: Vector2, append := false) -> void:
	var regs := _selected_regiments()
	if regs.is_empty():
		return
	var starts: Array[Vector2] = []
	for r in regs:
		var end := route_end(r)
		starts.append(end if append and not is_nan(end.x) else r.pos)
	var centre := Vector2.ZERO
	for s in starts:
		centre += s
	centre /= starts.size()
	var travel := wp - centre
	var orders: Array = []
	for i in regs.size():
		var r := regs[i]
		var to := wp + (starts[i] - centre)
		if battle.phase == "deploy":
			orders.append({"type": "place", "id": r.id, "to": to})
		else:
			var o := {"type": "move", "id": r.id, "to": to, "append": append}
			if travel.length() > 80.0:
				o.facing = travel.angle()
			orders.append(o)
	battle.apply_orders(orders)
	units_view.add_fx("ring", wp, 0.35, {"size": 22.0})
	_click()


func _order_line(a: Vector2, b: Vector2) -> void:
	var orders: Array = []
	for s in line_slots(a, b):
		orders.append({"type": "place" if battle.phase == "deploy" else "move", "id": s[0], "to": s[1], "facing": s[2]})
	battle.apply_orders(orders)
	_click()


## Where each selected regiment stands on a line dragged from a to b:
## side by side in their current order along the line, facing the enemy.
func line_slots(a: Vector2, b: Vector2) -> Array:
	var regs := _selected_regiments()
	if regs.is_empty():
		return []
	var dir := (b - a).normalized() if a.distance_to(b) > 1.0 else Vector2.RIGHT
	regs.sort_custom(func(x, y): return x.pos.dot(dir) < y.pos.dot(dir))
	var gap := 10.0
	var total := -gap
	for r in regs:
		total += r.width() + gap
	var length := maxf(a.distance_to(b), total)
	var spare := (length - total) / maxf(regs.size() - 1, 1)
	var mid := (a + b) * 0.5
	var normal := dir.orthogonal()
	var foes := battle.team_regiments(1)
	var foe_centre := Vector2(Terrain.SIZE.x * 0.5, 0.0)
	if not foes.is_empty():
		foe_centre = Vector2.ZERO
		for f in foes:
			foe_centre += f.pos
		foe_centre /= foes.size()
	if normal.dot(foe_centre - mid) < 0.0:
		normal = -normal
	var facing := normal.angle()
	var cursor := -length * 0.5
	var out: Array = []
	for r in regs:
		var w := r.width()
		out.append([r.id, mid + dir * (cursor + w * 0.5), facing])
		cursor += w + gap + (spare if regs.size() > 1 else 0.0)
	return out


func preview_slots() -> Array:
	if drag.is_empty() or drag.mode == "box":
		return []
	if drag.start_screen.distance_to(drag.now_screen) <= TAP_SLOP:
		return []
	if drag.mode == "unit" and battle.phase == "deploy":
		return []
	if drag.mode == "unit" and not drag.unit in selected:
		return []
	return line_slots(drag.start_world, drag.now_world)


# --- events into effects --------------------------------------------------

func _react(events: Array[Dictionary]) -> void:
	for e in events:
		match e.type:
			"death":
				_corpses.add(e.pos, e.team)
			"volley":
				_sound("volley", -10.0, randf_range(0.9, 1.15))
			"ram":
				units_view.add_fx("dust", e.pos, 0.6, {"size": 14.0})
				_sound("boom", -14.0, 1.8)
			"gate":
				_terrain_view.queue_redraw()
				units_view.add_fx("dust", e.pos, 1.6, {"size": 46.0})
				units_view.add_fx("smoke", e.pos, 2.2, {"size": 40.0})
				units_view.add_fx("text", e.pos, 2.0, {"text": "The gate is down!", "color": Palette.GOLD})
				_sound("boom", -2.0, 0.7)
			"musket":
				var facing: float = e.facing
				var width: float = e.width
				var fwd := Vector2.from_angle(facing)
				var along := fwd.orthogonal()
				for i in 5:
					var at: Vector2 = e.pos + fwd * 10.0 + along * (i - 2) * width * 0.22
					units_view.add_fx("flash", at, 0.1, {"size": 4.0})
					units_view.add_fx("smoke", at, 2.4, {"size": 16.0, "dx": randf_range(-6, 6)})
				_sound("musket", -7.0, randf_range(0.9, 1.1))
			"boom":
				units_view.add_fx("flash", e.pos, 0.15, {"size": 7.0})
				units_view.add_fx("smoke", e.pos, 1.8, {"size": 20.0, "dx": randf_range(-8, 8)})
				_sound("boom", -6.0, randf_range(0.85, 1.1))
			"impact":
				var big: bool = e.big
				units_view.add_fx("dust", e.pos, 0.9, {"size": 22.0 if big else 12.0})
				units_view.add_fx("flash", e.pos, 0.12, {"size": 9.0 if big else 4.0})
				if big:
					units_view.add_fx("smoke", e.pos, 1.4, {"size": 26.0})
					_sound("boom", -4.0, 1.3)
			"charge":
				units_view.add_fx("dust", e.pos, 0.8, {"size": 24.0})
				_sound("charge", -4.0)
			"flank":
				var rear: bool = e.zone == Combat.Zone.REAR
				var ours: bool = e.team == 0
				var word := "Rear!" if rear else "Flank!"
				units_view.add_fx("text", e.pos, 1.4, {"text": word, "color": Palette.GOLD if ours else Palette.TEAM_LIGHT[1]})
				_sound("clash", -4.0, 0.7)
				if not ours:
					_toast("They're in behind your " + UnitTypes.label(e.kind).to_lower() if rear else "Your " + UnitTypes.label(e.kind).to_lower() + " are flanked", 1)
			"braced":
				units_view.add_fx("text", e.pos, 1.2, {"text": "Braced!", "color": Palette.GOLD})
			"rout":
				var who := "Your " if e.team == 0 else "Their "
				units_view.add_fx("text", e.pos, 1.6, {"text": "Routing", "color": Palette.TEAM_LIGHT[e.team]})
				_sound("rout", -12.0)
				_toast(who + UnitTypes.label(e.kind).to_lower() + (" are running!" if e.team == 0 else " break and run"), e.team)
			"rally":
				units_view.add_fx("text", e.pos, 1.4, {"text": "Rallied", "color": Palette.GOLD})
			"flag":
				var owner: int = e.owner
				_sound("flag", -6.0)
				if owner == 0:
					_toast("Crossing taken", 0)
				elif owner == 1:
					_toast("Crossing lost", 1)
			"horn":
				units_view.add_fx("ring", e.pos, 1.0, {"size": Battle.RALLY_RADIUS})
				_sound("horn", -3.0)
			"barrage":
				_toast("Barrage on its way", 0)
			"march":
				_sound("horn", -8.0, 1.5)
			"general":
				_toast("Your general has fallen!" if e.team == 0 else "Their commander has fallen!", e.team)
			"broken":
				_toast("Your army breaks..." if e.team == 0 else "The enemy army breaks!", e.team)
				_sound("lose" if e.team == 0 else "win", 0.0)
			"deadline":
				var held: int = e.held
				_toast("Time! You hold %d %s." % [held, "crossing" if held == 1 else "crossings"], 0 if held >= battle.hold_needed else 1)
			"begin":
				_sound("horn", -2.0, 0.9)


## Say so once when enemy horse picks one of your regiments to ride at.
func _warn_of_horse() -> void:
	if demo or battle.phase != "battle":
		return
	for e in battle.team_regiments(1):
		if e.kind != K.CAVALRY or not e.fighting() or e.target_id < 0:
			continue
		var t := battle.get_regiment(e.target_id)
		if t == null or t.team != 0 or _warned.get(e.id, -1) == t.id:
			continue
		if e.pos.distance_to(t.pos) > units_view.THREAT_RANGE:
			continue
		_warned[e.id] = t.id
		_toast("Their cavalry rides for your " + UnitTypes.label(t.kind).to_lower(), 1)
		_sound("charge", -10.0, 0.8)


func _ambient(delta: float) -> void:
	_clash_wait -= delta
	if _clash_wait > 0.0 or battle.phase != "battle" or paused:
		return
	_clash_wait = 0.07 / speed
	var engaged: Array[Regiment] = []
	for r in battle.regiments:
		if r.state == S.ENGAGED and not r.contacts.is_empty():
			engaged.append(r)
	if engaged.is_empty():
		return
	var r: Regiment = engaged[randi() % engaged.size()]
	var e := battle.get_regiment(r.contacts[0])
	var at := r.pos.lerp(e.pos, 0.5) + Vector2(randf_range(-14, 14), randf_range(-14, 14))
	units_view.add_fx("dust", at, 0.7, {"size": 10.0})
	_sound("clash", -16.0, randf_range(0.8, 1.3))


## Sound is looked up rather than named, so a battle runs where the Sfx
## autoload isn't loaded (the headless tests).
func _sound(name: String, db := 0.0, pitch := 1.0) -> void:
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null and not demo:
		sfx.play(name, db, pitch)


func _click() -> void:
	_sound("click", -10.0)


func _toast(text: String, team: int) -> void:
	if hud != null:
		hud.toast(text, team)
