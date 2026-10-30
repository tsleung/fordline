extends Node
## Plays a campaign battle on autopilot in a real window and saves
## screenshots, so the look can be checked without a browser.
##   Godot --path . --resolution 1280x720 res://tests/shot.tscn -- --battle=0 --out=build/shots/land
## Saves <out>-deploy.png, then <out>-<seconds>s.png at each time in SHOTS.
## With --menus it instead saves the title and the first briefing; with
## --routes, a paused battle with one regiment given a two-stop route.

const BattleScreen := preload("res://scripts/battle_screen.gd")
const Main := preload("res://scenes/main.tscn")
const SHOTS := [25.0, 50.0, 80.0]

var _screen
var _out := "build/shots/shot"
var _taken := 0
var _frames := 0
var _main: Node


func _ready() -> void:
	var battle_index := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--battle="):
			battle_index = int(arg.get_slice("=", 1))
		elif arg.begins_with("--out="):
			_out = arg.get_slice("=", 1)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + _out.get_base_dir()))
	if "--menus" in OS.get_cmdline_user_args():
		_main = Main.instantiate()
		add_child(_main)
		return
	var run := Campaign.new_run(7)
	run.battle = battle_index
	var spec: Dictionary = Campaign.BATTLES[battle_index]
	_screen = BattleScreen.new()
	_screen.setup(Campaign.make_battle(run), spec.persona, spec.name)
	_screen.autopilot = true
	add_child(_screen)


func _process(_delta: float) -> void:
	_frames += 1
	if _main != null:
		if _frames == 90:
			_save(_out + "-title.png")
			_main._start_run()
		elif _frames == 110:
			set_process(false)
			await _save(_out + "-briefing.png")
			get_tree().quit()
		return
	var b: Battle = _screen.battle
	if "--routes" in OS.get_cmdline_user_args():
		_routes()
		return
	if b.phase == "deploy":
		if _frames == 20:
			await _save(_out + "-deploy.png")
			_screen.begin_battle()
			_screen.speed = 4.0
		return
	if b.time > 18.0 and _screen.selected.is_empty():
		_screen.select_all()
		_screen.selected.resize(2)
	if _taken < SHOTS.size() and b.time >= SHOTS[_taken]:
		_save("%s-%ds.png" % [_out, int(SHOTS[_taken])])
		_taken += 1
	if _taken >= SHOTS.size() or b.phase == "over":
		set_process(false)
		if b.phase == "over":
			await _save(_out + "-end.png")
		get_tree().quit()


func _routes() -> void:
	if _frames == 10:
		_screen.autopilot = false
		_screen.begin_battle()
		_screen.paused = true
		var r: Regiment = _screen.battle.team_regiments(0).filter(func(x): return x.kind == UnitTypes.Kind.SWORDS)[0]
		for at in [r.pos, r.pos + Vector2(-160, -60), r.pos + Vector2(-160, -60), r.pos + Vector2(-330, -40)]:
			var sp: Vector2 = _screen.to_screen(at)
			_screen._press(sp, false, false)
			_screen._release(sp)
		# Pin the new end again, to show the pinned marker.
		var end: Vector2 = _screen.to_screen(_screen.route_end(r))
		_screen._press(end, false, false)
		_screen._release(end)
	elif _frames == 30:
		set_process(false)
		_save(_out + "-routes.png")
		get_tree().quit()


## The window must stay visible: macOS stops drawing a covered window and
## the shot then shows the last frame it drew.
func _save(path: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://" + path))
	print("saved ", path)
