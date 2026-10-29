extends Node2D
## Paints the map once per battle; Godot keeps the drawing until the next
## queue_redraw.

var terrain: Terrain
var seed_value := 0


func show_terrain(t: Terrain, s: int) -> void:
	terrain = t
	seed_value = s
	queue_redraw()


func _draw() -> void:
	if terrain == null:
		return
	var size := Terrain.SIZE
	draw_rect(Rect2(Vector2(-400, -400), size + Vector2(800, 800)), Palette.GRASS.darkened(0.25))
	draw_rect(Rect2(Vector2.ZERO, size), Palette.GRASS)
	_fields()
	_hills()
	for road in terrain.roads:
		_road(road)
	if terrain.has_river:
		_river()
	_forests()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.25), false, 3.0)


## Field patches in a jittered grid, each a slightly different green with a
## pale hedge line, like a printed survey map.
func _fields() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cell := Vector2(200.0, 160.0)
	var cols := int(ceil(Terrain.SIZE.x / cell.x)) + 1
	var rows := int(ceil(Terrain.SIZE.y / cell.y)) + 1
	var grid := []
	for y in rows + 1:
		var line := []
		for x in cols + 1:
			var p := Vector2(x * cell.x, y * cell.y)
			if x > 0 and x < cols and y > 0 and y < rows:
				p += Vector2(rng.randf_range(-50, 50), rng.randf_range(-40, 40))
			line.append(p)
		grid.append(line)
	for y in rows:
		for x in cols:
			var poly := PackedVector2Array([grid[y][x], grid[y][x + 1], grid[y + 1][x + 1], grid[y + 1][x]])
			var tone := rng.randf()
			if tone < 0.35:
				draw_colored_polygon(_inset(poly, 5.0), Palette.FIELD_LIGHT)
			elif tone < 0.6:
				draw_colored_polygon(_inset(poly, 5.0), Palette.FIELD_DARK)
			var closed := poly.duplicate()
			closed.append(poly[0])
			draw_polyline(closed, Palette.FIELD_EDGE, 2.0, true)


func _inset(poly: PackedVector2Array, by: float) -> PackedVector2Array:
	var c := Vector2.ZERO
	for p in poly:
		c += p
	c /= poly.size()
	var out := PackedVector2Array()
	for p in poly:
		out.append(p + (c - p).normalized() * by)
	return out


func _hills() -> void:
	for h in terrain.hills:
		var c: Vector2 = h.c
		var r: float = h.r
		for i in 3:
			var rr := r * (1.0 - i * 0.28)
			draw_circle(c, rr, Palette.HILL[i])
			draw_arc(c, rr, 0, TAU, 48, Palette.HILL_LINE, 1.5, true)


func _road(road: PackedVector2Array) -> void:
	var smooth := _smooth(road)
	draw_polyline(smooth, Palette.ROAD_EDGE, Terrain.ROAD_HALF * 1.2 + 2.0, true)
	draw_polyline(smooth, Palette.ROAD, Terrain.ROAD_HALF * 1.2, true)


## Chaikin smoothing, so roads bend rather than kink.
func _smooth(points: PackedVector2Array) -> PackedVector2Array:
	var pts := points
	for pass_i in 3:
		var out := PackedVector2Array([pts[0]])
		for i in pts.size() - 1:
			out.append(pts[i].lerp(pts[i + 1], 0.25))
			out.append(pts[i].lerp(pts[i + 1], 0.75))
		out.append(pts[pts.size() - 1])
		pts = out
	return pts


func _river() -> void:
	var w := Terrain.RIVER_HALF * 2.0
	draw_polyline(terrain.river, Palette.RIVER_EDGE, w + 5.0, true)
	draw_polyline(terrain.river, Palette.RIVER, w, true)
	var shine := PackedVector2Array()
	for p in terrain.river:
		shine.append(p + Vector2(0, -w * 0.18))
	draw_polyline(shine, Palette.RIVER_SHINE, 2.0, true)
	for c in terrain.crossings:
		var x: float = c.x
		var half: float = c.half
		var y := terrain.river_y(x)
		var slope := atan2(terrain.river_y(x + 10.0) - terrain.river_y(x - 10.0), 20.0)
		draw_set_transform(Vector2(x, y), slope)
		if c.bridge:
			draw_rect(Rect2(-half, -w * 0.5 - 6.0, half * 2.0, w + 12.0), Palette.BRIDGE)
			for i in int(half * 2.0 / 5.0):
				draw_line(Vector2(-half + i * 5.0, -w * 0.5 - 6.0), Vector2(-half + i * 5.0, w * 0.5 + 6.0), Palette.BRIDGE_RAIL, 1.0)
			draw_line(Vector2(-half, -w * 0.5 - 6.0), Vector2(half, -w * 0.5 - 6.0), Palette.BRIDGE_RAIL, 2.5)
			draw_line(Vector2(-half, w * 0.5 + 6.0), Vector2(half, w * 0.5 + 6.0), Palette.BRIDGE_RAIL, 2.5)
		else:
			var ford := Palette.FORD
			ford.a = 0.8
			draw_rect(Rect2(-half, -w * 0.5 - 2.0, half * 2.0, w + 4.0), ford)
			for i in 6:
				var sx := -half + 6.0 + i * (half * 2.0 - 12.0) / 5.0
				draw_line(Vector2(sx, -w * 0.4), Vector2(sx + 4.0, w * 0.4), Palette.RIVER_SHINE, 1.5)
		draw_set_transform(Vector2.ZERO)


func _forests() -> void:
	for f in terrain.forests:
		draw_circle(f.c + Vector2(4, 6), f.r, Palette.TREE_SHADOW)
	for f in terrain.forests:
		draw_circle(f.c, f.r, Palette.TREE)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 99
	for f in terrain.forests:
		var c: Vector2 = f.c
		var r: float = f.r
		for i in int(r / 6.0):
			var p := c + Vector2.from_angle(rng.randf() * TAU) * rng.randf() * r * 0.7
			draw_circle(p, rng.randf_range(3.0, 7.0), Palette.TREE_LIGHT)
