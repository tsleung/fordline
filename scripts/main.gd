extends Node
## The game's screens and the run that threads through them:
## title → briefing → battle → result → briefing (with a reward) … → final.

const K := UnitTypes.Kind
const BattleScreen := preload("res://scripts/battle_screen.gd")
const SAVE_PATH := "user://fordline.cfg"

var run: Dictionary = {}
var best := 0
var _theme: Theme
var _stage: Node


func _ready() -> void:
	randomize()
	_theme = _make_theme()
	best = _load_best()
	show_title()


# --- screens ---------------------------------------------------------------

func show_title() -> void:
	var demo_run := Campaign.new_run(randi())
	demo_run.battle = randi() % 2
	demo_run = Campaign.apply_reward(demo_run, {"id": "recruit", "kind": K.CANNONS})
	var screen := BattleScreen.new()
	screen.setup(Campaign.make_battle(demo_run), "aggressive", "demo", true)
	var ui := _fresh(screen)
	var shade := ColorRect.new()
	shade.color = Color(Palette.DESK, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	var col := _column(ui, 520)
	var name := _text("FORDLINE", 76, Palette.INK)
	name.add_theme_constant_override("outline_size", 12)
	name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	col.add_child(name)
	col.add_child(_text("Hold the crossings. Five battles, one army,\nabout twenty minutes.", 20, Palette.INK))
	col.add_child(_spacer(12))
	col.add_child(_button("New campaign", _start_run, true))
	var rules := _panel_text(_how_to_play())
	rules.visible = false
	col.add_child(_button("How to play", func(): rules.visible = not rules.visible))
	col.add_child(rules)
	if best > 0:
		col.add_child(_text("Best score  %d" % best, 18, Palette.BRASS))


func _start_run() -> void:
	Sfx.play("click")
	run = Campaign.new_run(randi())
	show_briefing([])


func show_briefing(rewards: Array) -> void:
	var spec := Campaign.current(run)
	var ui := _fresh(null)
	var bg := ColorRect.new()
	bg.color = Palette.DESK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	scroll.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var step := _inline("BATTLE %d OF %d" % [run.battle + 1, Campaign.BATTLES.size()], 15, Palette.BRASS)
	step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(step)
	head.add_child(_inline("Score  %d" % run.score, 15, Palette.INK_DIM))
	col.add_child(_route())
	col.add_child(_text(spec.name, 40, Palette.INK, false))
	col.add_child(_text(spec.brief, 18, Palette.INK_DIM, false))
	col.add_child(_text("THEY BRING", 14, Palette.BRASS, false))
	col.add_child(_army_strip(Campaign.enemy_army(run), 1))
	var choice := {"reward": null}
	var march := _button("To battle", func(): _start_battle(choice.reward), true)
	if not rewards.is_empty():
		col.add_child(_text("CHOOSE A REWARD", 14, Palette.BRASS, false))
		var group := ButtonGroup.new()
		var cards := GridContainer.new()
		cards.columns = 3 if get_viewport().get_visible_rect().size.x > 760 else 1
		cards.add_theme_constant_override("h_separation", 10)
		cards.add_theme_constant_override("v_separation", 10)
		for r in rewards:
			var card := Button.new()
			card.toggle_mode = true
			card.button_group = group
			card.text = "%s\n%s" % [r.title, r.text]
			card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.custom_minimum_size = Vector2(220, 84)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.focus_mode = Control.FOCUS_NONE
			card.pressed.connect(func():
				choice.reward = r
				march.disabled = false
				Sfx.play("click"))
			cards.add_child(card)
		col.add_child(cards)
		march.disabled = true
	col.add_child(_text("YOUR ARMY", 14, Palette.BRASS, false))
	col.add_child(_roster())
	col.add_child(march)


func _start_battle(reward: Variant) -> void:
	if reward != null:
		run = Campaign.apply_reward(run, reward)
	Sfx.play("click")
	var spec := Campaign.current(run)
	var screen := BattleScreen.new()
	screen.setup(Campaign.make_battle(run), spec.persona, spec.name)
	screen.finished.connect(_battle_over)
	_fresh(screen)


func _battle_over(b: Battle) -> void:
	var result := Campaign.battle_result(b)
	var before: int = run.score
	run = Campaign.after_battle(run, result)
	var lost := 0
	for r in b.regiments:
		if r.team == 0:
			lost += r.men_max - r.men()
	var ui := CanvasLayer.new()
	ui.layer = 5
	_stage.add_child(ui)
	var root := Control.new()
	root.theme = _theme
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(Palette.DESK, 0.7)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var col := _column(root, 460)
	var won: bool = result.won
	col.add_child(_text("Victory" if won else "Defeat", 60, Palette.GOLD if won else Palette.TEAM_LIGHT[1]))
	col.add_child(_text(Campaign.BATTLES[run.battle].name, 20, Palette.INK_DIM))
	var t := int(b.time)
	col.add_child(_panel_text("Time  %d:%02d\nEnemy fallen  %d\nYour fallen  %d\nScore  +%d" % [t / 60, t % 60, b.killed[0], lost, run.score - before]))
	col.add_child(_button("Continue" if not run.over else "See the war's end", _after_result, true))


func _after_result() -> void:
	Sfx.play("click")
	if run.over:
		show_final()
		return
	run = Campaign.advance(run)
	show_briefing(Campaign.offer_rewards(run))


func show_final() -> void:
	var record: bool = run.score > best
	if record:
		best = run.score
		_save_best(best)
	var ui := _fresh(null)
	var bg := ColorRect.new()
	bg.color = Palette.DESK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	var col := _column(ui, 520)
	var won: bool = run.won
	col.add_child(_text("The war is won" if won else "Your army is broken", 44, Palette.GOLD if won else Palette.TEAM_LIGHT[1]))
	col.add_child(_text("Score  %d" % run.score + ("   New best!" if record else "   Best  %d" % best), 24, Palette.INK))
	var lines := PackedStringArray()
	for entry in run.log:
		var t := int(entry.time)
		lines.append("%s   %s   %d:%02d   +%d" % ["Won " if entry.won else "Lost", entry.name, t / 60, t % 60, entry.score])
	col.add_child(_panel_text("\n".join(lines)))
	col.add_child(_button("New campaign", _start_run, true))
	col.add_child(_button("Title", show_title))


# --- building blocks -------------------------------------------------------

## Replace whatever is on stage with `screen` (or nothing) and a fresh UI
## layer; returns the UI root.
func _fresh(screen: Node) -> Control:
	if _stage != null:
		_stage.queue_free()
	_stage = Node.new()
	add_child(_stage)
	if screen != null:
		_stage.add_child(screen)
	var layer := CanvasLayer.new()
	layer.layer = 4
	_stage.add_child(layer)
	var root := Control.new()
	root.theme = _theme
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	return root


func _column(parent: Control, width: float) -> VBoxContainer:
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(centre)
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = minf(width, get_viewport().get_visible_rect().size.x - 40.0)
	col.add_theme_constant_override("separation", 12)
	centre.add_child(col)
	return col


func _text(s: String, size: int, color: Color, centred := true) -> Label:
	var l := _inline(s, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if centred:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## A label that sits in a row and keeps to one line.
func _inline(s: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


func _panel_text(s: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_child(_text(s, 17, Palette.INK, false))
	return p


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c


func _button(text: String, action: Callable, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 56)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(action)
	if primary:
		b.add_theme_stylebox_override("normal", _box(Palette.BRASS, Palette.BRASS))
		b.add_theme_stylebox_override("hover", _box(Palette.GOLD, Palette.GOLD))
		b.add_theme_stylebox_override("pressed", _box(Palette.GOLD, Palette.GOLD))
		b.add_theme_stylebox_override("disabled", _box(Palette.DESK_RAISED, Palette.DESK_RAISED))
		b.add_theme_color_override("font_color", Palette.DESK)
		b.add_theme_color_override("font_hover_color", Palette.DESK)
		b.add_theme_color_override("font_pressed_color", Palette.DESK)
		b.add_theme_font_size_override("font_size", 22)
	return b


## Five bars, one per battle: done, here, ahead.
func _route() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for i in Campaign.BATTLES.size():
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(44, 6)
		dot.color = Palette.BRASS if i < run.battle else (Palette.GOLD if i == run.battle else Palette.DESK_RAISED)
		row.add_child(dot)
	return row


func _army_strip(army: Array, team: int) -> Control:
	var counts := {}
	for reg in army:
		counts[reg.kind] = counts.get(reg.kind, 0) + 1
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 14)
	for kind in counts:
		var item := HBoxContainer.new()
		item.add_child(UnitIcon.make(kind, team, 30))
		item.add_child(_inline("%s ×%d" % [UnitTypes.label(kind), counts[kind]], 16, Palette.INK))
		flow.add_child(item)
	return flow


func _roster() -> Control:
	var grid := GridContainer.new()
	grid.columns = 2 if get_viewport().get_visible_rect().size.x > 760 else 1
	grid.add_theme_constant_override("h_separation", 24)
	for reg in run.roster:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.add_child(UnitIcon.make(reg.kind, 0, 30))
		var full: int = UnitTypes.stat(reg.kind, "men")
		var stars: String = ("  " + "★".repeat(reg.stars)) if reg.stars > 0 else ""
		var name := _inline(UnitTypes.label(reg.kind) + stars, 17, Palette.INK)
		name.custom_minimum_size.x = 150
		row.add_child(name)
		var bar := ProgressBar.new()
		bar.max_value = full
		bar.value = reg.men
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(120, 10)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
		row.add_child(_inline("%d/%d" % [reg.men, full], 15, Palette.INK_DIM))
		grid.add_child(row)
	return grid


func _how_to_play() -> String:
	return "\n".join([
		"Hold more of the three flags to drain the enemy's resolve. Rout their regiments to drain it faster. At zero, their army breaks.",
		"",
		"Tap a banner to select. Double-tap selects every regiment of that kind. With nothing selected, drag to box-select.",
		"Tap the field to move. Drag to set a line. Tap an enemy to attack.",
		"",
		"Pikes stop cavalry. Swords beat pikes. Cavalry rides down archers and guns. Flanks and rears take more damage and break faster.",
		"Pause any time; orders still work. Rally brings broken regiments back near your general.",
	])


# --- theme and save --------------------------------------------------------

func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 18
	t.set_stylebox("normal", "Button", _box(Palette.DESK_RAISED, Color(Palette.BRASS, 0.45)))
	t.set_stylebox("hover", "Button", _box(Palette.DESK_RAISED.lightened(0.08), Palette.BRASS))
	t.set_stylebox("pressed", "Button", _box(Palette.BRASS.darkened(0.45), Palette.GOLD))
	t.set_stylebox("disabled", "Button", _box(Palette.DESK_PANEL, Color(Palette.BRASS, 0.15)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Palette.INK)
	t.set_color("font_hover_color", "Button", Palette.INK)
	t.set_color("font_pressed_color", "Button", Palette.GOLD)
	t.set_color("font_disabled_color", "Button", Palette.INK_DIM)
	t.set_color("font_color", "Label", Palette.INK)
	t.set_stylebox("panel", "PanelContainer", _box(Color(Palette.DESK_PANEL, 0.95), Color(Palette.BRASS, 0.35)))
	var bar_bg := _box(Palette.DESK_RAISED, Palette.DESK_RAISED)
	bar_bg.content_margin_top = 0
	bar_bg.content_margin_bottom = 0
	t.set_stylebox("background", "ProgressBar", bar_bg)
	var bar_fill := _box(Palette.TEAM[0], Palette.TEAM[0])
	bar_fill.content_margin_top = 0
	bar_fill.content_margin_bottom = 0
	t.set_stylebox("fill", "ProgressBar", bar_fill)
	return t


func _load_best() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 0
	return int(cfg.get_value("score", "best", 0))


func _save_best(value: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", value)
	cfg.save(SAVE_PATH)


## A banner as a UI element, for the roster and the enemy list.
class UnitIcon extends Control:
	var kind := 0
	var team := 0

	static func make(k: int, t: int, px: float) -> UnitIcon:
		var icon := UnitIcon.new()
		icon.kind = k
		icon.team = t
		icon.custom_minimum_size = Vector2(px, px)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		return icon

	func _draw() -> void:
		var r := minf(size.x, size.y) * 0.5 - 3.0
		Glyphs.banner(self, kind, team, size * 0.5, r * 0.75, 0.0, false, false, false)
