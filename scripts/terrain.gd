class_name Terrain
extends RefCounted
## A seeded battlefield and the questions the simulation asks of it.
## The player deploys along the bottom edge, the enemy along the top.

const SIZE := Vector2(1300.0, 820.0)
const DEPLOY_DEPTH := 190.0
const EDGE := 36.0
const RIVER_HALF := 13.0
const BANK_CLEARANCE := 24.0
const ROAD_HALF := 9.0

var kind := ""
var has_river := false
## River centre line, sampled left to right.
var river := PackedVector2Array()
## Each crossing: {"x": float, "half": float, "bridge": bool}.
var crossings: Array[Dictionary] = []
## Each forest and hill: {"c": Vector2, "r": float}.
var forests: Array[Dictionary] = []
var hills: Array[Dictionary] = []
var roads: Array[PackedVector2Array] = []
var flags := PackedVector2Array()
## How far each side's deployment zone reaches in from its edge. The map is
## generated around DEPLOY_DEPTH; a scenario may push a side forward.
var deploy_depth := [DEPLOY_DEPTH, DEPLOY_DEPTH]


static func generate(map_kind: String, seed_value: int) -> Terrain:
	var t := Terrain.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	t.kind = map_kind
	t.has_river = map_kind in ["fords", "bridges", "roads"]
	if t.has_river:
		t._make_river(rng)
		t._make_crossings(rng)
		for c in t.crossings:
			t.flags.append(Vector2(c.x, t.river_y(c.x)))
	else:
		t._make_open_flags(rng)
	t._make_hills(rng)
	t._make_forests(rng)
	t._make_roads(rng)
	return t


# --- queries ---------------------------------------------------------------

func river_y(x: float) -> float:
	if river.is_empty():
		return SIZE.y * 0.5
	var step := river[1].x - river[0].x
	var i := clampi(int((x - river[0].x) / step), 0, river.size() - 2)
	var a := river[i]
	var b := river[i + 1]
	return lerpf(a.y, b.y, clampf((x - a.x) / (b.x - a.x), 0.0, 1.0))


## 0 for the player's (south) bank, 1 for the enemy's (north) bank.
func side(p: Vector2) -> int:
	return 1 if p.y < river_y(p.x) else 0


func crossing_at(x: float) -> Dictionary:
	for c in crossings:
		if absf(x - c.x) <= c.half:
			return c
	return {}


func in_river_band(p: Vector2) -> bool:
	return has_river and absf(p.y - river_y(p.x)) < RIVER_HALF


func is_water(p: Vector2) -> bool:
	return in_river_band(p) and crossing_at(p.x).is_empty()


func is_blocked(p: Vector2) -> bool:
	return is_water(p) or not in_bounds(p)


func in_bounds(p: Vector2) -> bool:
	return p.x >= 4.0 and p.y >= 4.0 and p.x <= SIZE.x - 4.0 and p.y <= SIZE.y - 4.0


func in_forest(p: Vector2) -> bool:
	for f in forests:
		if p.distance_squared_to(f.c) < f.r * f.r:
			return true
	return false


## 0 off any hill, rising to 1 at a hill's crest.
func height(p: Vector2) -> float:
	var h := 0.0
	for hill in hills:
		var d: float = p.distance_to(hill.c) / hill.r
		if d < 1.0:
			h = maxf(h, 1.0 - d * d)
	return h


func on_road(p: Vector2) -> bool:
	for road in roads:
		for i in road.size() - 1:
			var q := Geometry2D.get_closest_point_to_segment(p, road[i], road[i + 1])
			if p.distance_squared_to(q) < ROAD_HALF * ROAD_HALF:
				return true
	return false


func speed_mult(p: Vector2) -> float:
	if in_river_band(p):
		var c := crossing_at(p.x)
		if not c.is_empty():
			return 0.95 if c.bridge else 0.5
	if in_forest(p):
		return 0.6
	if on_road(p):
		return 1.2
	return 1.0 - 0.15 * height(p)


## Share of arrow damage that gets through at `p`.
func cover(p: Vector2) -> float:
	return 0.5 if in_forest(p) else 1.0


func range_mult(p: Vector2) -> float:
	return 1.0 + 0.25 * height(p)


func defence_bonus(p: Vector2) -> float:
	return 0.12 * height(p)


func in_deploy(team: int, p: Vector2) -> bool:
	if p.x < EDGE or p.x > SIZE.x - EDGE:
		return false
	if team == 0:
		return p.y > SIZE.y - deploy_depth[0] and p.y < SIZE.y - EDGE * 0.6
	return p.y < deploy_depth[1] and p.y > EDGE * 0.6


func clamp_deploy(team: int, p: Vector2) -> Vector2:
	var x := clampf(p.x, EDGE, SIZE.x - EDGE)
	if team == 0:
		return Vector2(x, clampf(p.y, SIZE.y - deploy_depth[0] + 10.0, SIZE.y - EDGE))
	return Vector2(x, clampf(p.y, EDGE, deploy_depth[1] - 10.0))


func clamp_to_field(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, 8.0, SIZE.x - 8.0), clampf(p.y, 8.0, SIZE.y - 8.0))


## Waypoints from `from` to `to`, through a crossing when the river is
## in between. The last waypoint is always the destination (moved off the
## water if it was on it).
func path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var dest := _off_water(clamp_to_field(to), side(from))
	if not has_river:
		return PackedVector2Array([dest])
	var bank := side(from)
	if bank == side(dest):
		return _along_bank(from, dest, bank)
	var best: Dictionary = crossings[0]
	var best_cost := INF
	for c in crossings:
		var cost: float = absf(from.x - c.x) + absf(dest.x - c.x)
		if cost < best_cost:
			best_cost = cost
			best = c
	var ry := river_y(best.x)
	var reach := RIVER_HALF + BANK_CLEARANCE
	var near := Vector2(best.x, ry + reach if bank == 0 else ry - reach)
	var far := Vector2(best.x, ry - reach if bank == 0 else ry + reach)
	var way := PackedVector2Array()
	if from.distance_to(near) >= 6.0 and not in_river_band(from):
		way.append_array(_along_bank(from, near, bank))
	way.append(far)
	way.append_array(_along_bank(far, dest, 1 - bank))
	return way


## Waypoints from a to b on one bank: the straight line where it stays
## clear of the water, pushed out to the bank where the river bends into it.
func _along_bank(a: Vector2, b: Vector2, bank: int) -> PackedVector2Array:
	var steps := int(ceil(a.distance_to(b) / 50.0))
	var clear := true
	for i in range(1, steps * 6):
		if is_water(a.lerp(b, float(i) / (steps * 6))):
			clear = false
			break
	if clear:
		return PackedVector2Array([b])
	var reach := RIVER_HALF + BANK_CLEARANCE
	var way := PackedVector2Array()
	for i in range(1, steps):
		var p := a.lerp(b, float(i) / steps)
		var ry := river_y(p.x)
		p.y = maxf(p.y, ry + reach) if bank == 0 else minf(p.y, ry - reach)
		way.append(p)
	way.append(b)
	return way


func _off_water(p: Vector2, prefer_side: int) -> Vector2:
	if not is_water(p):
		return p
	var ry := river_y(p.x)
	var reach := RIVER_HALF + BANK_CLEARANCE * 0.5
	return Vector2(p.x, ry + reach if prefer_side == 0 else ry - reach)


# --- generation ------------------------------------------------------------

func _make_river(rng: RandomNumberGenerator) -> void:
	var a1 := rng.randf_range(35.0, 70.0)
	var a2 := rng.randf_range(10.0, 22.0)
	var p1 := rng.randf_range(0.0, TAU)
	var p2 := rng.randf_range(0.0, TAU)
	var tilt := rng.randf_range(-0.05, 0.05)
	var x := -40.0
	while x <= SIZE.x + 40.0:
		var y := SIZE.y * 0.5 + a1 * sin(x * 0.0042 + p1) + a2 * sin(x * 0.013 + p2)
		y += (x - SIZE.x * 0.5) * tilt
		river.append(Vector2(x, y))
		x += 40.0


func _make_crossings(rng: RandomNumberGenerator) -> void:
	var spots: Array = []
	var bridges: Array = []
	match kind:
		"fords":
			spots = [0.2, 0.5, 0.8]
			bridges = [false, false, false]
		"bridges":
			spots = [0.32, 0.68]
			bridges = [true, true]
		"roads":
			spots = [0.18, 0.5, 0.82]
			bridges = [false, true, false]
	for i in spots.size():
		var x: float = SIZE.x * spots[i] + rng.randf_range(-70.0, 70.0)
		crossings.append({"x": x, "half": 16.0 if bridges[i] else 34.0, "bridge": bridges[i]})
	if kind == "bridges":
		var x := SIZE.x * 0.5 + rng.randf_range(-40.0, 40.0)
		flags.append(Vector2(x, river_y(x) + (60.0 if rng.randf() < 0.5 else -60.0)))


func _make_open_flags(rng: RandomNumberGenerator) -> void:
	var mid := SIZE.y * 0.5
	if kind == "ridge":
		flags.append(Vector2(SIZE.x * 0.5, mid - 20.0))
		flags.append(Vector2(SIZE.x * 0.2 + rng.randf_range(-40, 40), mid + rng.randf_range(-50, 50)))
		flags.append(Vector2(SIZE.x * 0.8 + rng.randf_range(-40, 40), mid + rng.randf_range(-50, 50)))
		return
	for f in [0.22, 0.5, 0.78]:
		flags.append(Vector2(SIZE.x * f + rng.randf_range(-50, 50), mid + rng.randf_range(-70, 70)))


func _make_hills(rng: RandomNumberGenerator) -> void:
	if kind == "ridge":
		hills.append({"c": Vector2(SIZE.x * 0.5, SIZE.y * 0.47), "r": 180.0})
	var count: int = {"fords": 2, "woods": 3, "bridges": 2, "roads": 2, "ridge": 2}.get(kind, 2)
	var tries := 0
	while hills.size() < count + (1 if kind == "ridge" else 0) and tries < 200:
		tries += 1
		var r := rng.randf_range(80.0, 130.0)
		var c := Vector2(rng.randf_range(120, SIZE.x - 120), rng.randf_range(250, SIZE.y - 250))
		if has_river and absf(c.y - river_y(c.x)) < r * 0.9:
			continue
		var clash := false
		for h in hills:
			if c.distance_to(h.c) < r + h.r:
				clash = true
		if not clash:
			hills.append({"c": c, "r": r})


func _make_forests(rng: RandomNumberGenerator) -> void:
	var clusters: int = {"fords": 4, "woods": 9, "bridges": 5, "roads": 3, "ridge": 5}.get(kind, 4)
	var tries := 0
	var made := 0
	while made < clusters and tries < 400:
		tries += 1
		var centre := Vector2(rng.randf_range(60, SIZE.x - 60), rng.randf_range(DEPLOY_DEPTH + 50, SIZE.y - DEPLOY_DEPTH - 50))
		if not _forest_allowed(centre, 70.0):
			continue
		made += 1
		for i in rng.randi_range(4, 9):
			var c := centre + Vector2(rng.randf_range(-55, 55), rng.randf_range(-40, 40))
			if _forest_allowed(c, 30.0):
				forests.append({"c": c, "r": rng.randf_range(18.0, 32.0)})


func _forest_allowed(p: Vector2, clearance: float) -> bool:
	if p.y < DEPLOY_DEPTH + 20.0 or p.y > SIZE.y - DEPLOY_DEPTH - 20.0:
		return false
	for f in flags:
		if p.distance_to(f) < 90.0 + clearance:
			return false
	if has_river:
		if absf(p.y - river_y(p.x)) < RIVER_HALF + clearance:
			return false
		for c in crossings:
			if absf(p.x - c.x) < c.half + 60.0 + clearance:
				return false
	return true


func _make_roads(rng: RandomNumberGenerator) -> void:
	for f in flags:
		var road := PackedVector2Array()
		var bottom_x := clampf(f.x + rng.randf_range(-160, 160), 40, SIZE.x - 40)
		var top_x := clampf(f.x + rng.randf_range(-160, 160), 40, SIZE.x - 40)
		road.append(Vector2(bottom_x, SIZE.y + 10.0))
		road.append(Vector2(lerpf(bottom_x, f.x, 0.6), lerpf(SIZE.y, f.y, 0.55)))
		if has_river:
			var ry := river_y(f.x)
			road.append(Vector2(f.x, ry + 40.0))
			road.append(Vector2(f.x, ry - 40.0))
		else:
			road.append(f)
		road.append(Vector2(lerpf(top_x, f.x, 0.6), lerpf(0.0, f.y, 0.55)))
		road.append(Vector2(top_x, -10.0))
		roads.append(road)
