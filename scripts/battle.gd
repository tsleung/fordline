class_name Battle
extends RefCounted
## The battle simulation, and the one writer of battle state.
## Callers hand it orders (apply_orders) and advance it (step); the view
## reads its fields and drains its events (take_events).

const S := Regiment.State
const K := UnitTypes.Kind

const STEP := 1.0 / 30.0

const FLAG_RADIUS := 72.0
const CAPTURE_RATE := 0.3
const FLAG_DRAIN := 0.5
const DUSK_TIME := 240.0
const DUSK_DRAIN := 0.25
const ROUT_COST := 5.0
const DESTROYED_COST := 4.0
const GENERAL_COST := 20.0
const BREAK_DELAY := 2.5

const AURA_RADIUS := 170.0
const RALLY_RADIUS := 280.0
const PANIC_RADIUS := 140.0
const ENGAGE_RADIUS := 70.0

const ABILITY_COOLDOWN := {"rally": 40.0, "barrage": 55.0, "march": 35.0}

var terrain: Terrain
var rng := RandomNumberGenerator.new()
var regiments: Array[Regiment] = []
var phase := "deploy"
var time := 0.0
var winner := -1
var broken_team := -1
var break_timer := 0.0

## {"pos": Vector2, "owner": -1|0|1, "progress": -1..1 (+1 = team 0)}
var flags: Array[Dictionary] = []
var resolve := [100.0, 100.0]
var killed := [0, 0]
## Abilities the player (team 0) has, and their cooldowns.
var abilities: Array[String] = []
var cooldowns := {"rally": 0.0, "barrage": 0.0, "march": 0.0}

var projectiles: Array[Dictionary] = []
var shells: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _by_id := {}
var _next_id := 1


func _init(map: Terrain, seed_value: int) -> void:
	terrain = map
	rng.seed = seed_value
	for p in map.flags:
		flags.append({"pos": p, "owner": -1, "progress": 0.0})


func add_regiment(
	team: int, kind: int, men: int, at: Vector2, face: float, stars: int,
	doctrine: Dictionary, roster_index := -1
) -> Regiment:
	var r := Regiment.create(_next_id, team, kind, men, at, face, stars, doctrine)
	r.roster_index = roster_index
	_next_id += 1
	regiments.append(r)
	_by_id[r.id] = r
	return r


func get_regiment(id: int) -> Regiment:
	return _by_id.get(id)


func team_regiments(team: int) -> Array[Regiment]:
	var out: Array[Regiment] = []
	for r in regiments:
		if r.team == team and r.alive():
			out.append(r)
	return out


func general_of(team: int) -> Regiment:
	for r in regiments:
		if r.team == team and r.kind == K.GENERAL and r.fighting():
			return r
	return null


func flags_held(team: int) -> int:
	var n := 0
	for f in flags:
		if f.owner == team:
			n += 1
	return n


func take_events() -> Array[Dictionary]:
	var out := _events
	_events = []
	return out


func begin() -> void:
	phase = "battle"
	_emit({"type": "begin"})


# --- orders ----------------------------------------------------------------

## Orders are dictionaries; see the match arms for each type's fields.
func apply_orders(orders: Array) -> void:
	for o in orders:
		match o.type:
			"place":
				_order_place(o)
			"move":
				_order_move(o)
			"attack":
				_order_attack(o)
			"halt":
				_order_halt(o)
			"rally":
				_ability_rally()
			"barrage":
				_ability_barrage(o.pos)
			"march":
				_ability_march(o.ids)


func _commandable(id: int) -> Regiment:
	var r := get_regiment(id)
	if r == null or not r.fighting():
		return null
	return r


func _order_place(o: Dictionary) -> void:
	var r := _commandable(o.id)
	if r == null or phase != "deploy":
		return
	r.pos = terrain.clamp_deploy(r.team, o.to)
	if o.has("facing"):
		r.facing = o.facing
	r.final_facing = r.facing
	for i in r.men():
		r.soldiers[i] = r.slot_world(i, r.men())


func _order_move(o: Dictionary) -> void:
	var r := _commandable(o.id)
	if r == null or phase != "battle":
		return
	r.waypoints = terrain.path(r.pos, o.to)
	r.final_facing = o.get("facing", NAN)
	r.target_id = -1
	r.via = Vector2(NAN, NAN)
	r.ordered = true
	if r.state == S.IDLE:
		r.state = S.MOVING


func _order_attack(o: Dictionary) -> void:
	var r := _commandable(o.id)
	var t := get_regiment(o.target)
	if r == null or t == null or not t.alive() or t.team == r.team or phase != "battle":
		return
	r.target_id = t.id
	r.via = o.get("via", Vector2(NAN, NAN))
	r.waypoints = PackedVector2Array()
	r.repath = 0.0
	r.final_facing = NAN
	r.ordered = true


func _order_halt(o: Dictionary) -> void:
	var r := _commandable(o.id)
	if r == null:
		return
	r.waypoints = PackedVector2Array()
	r.target_id = -1
	r.ordered = true


func _ability_ready(name: String) -> bool:
	return phase == "battle" and name in abilities and cooldowns[name] <= 0.0


func _ability_rally() -> void:
	var g := general_of(0)
	if not _ability_ready("rally") or g == null:
		return
	cooldowns.rally = ABILITY_COOLDOWN.rally
	for r in team_regiments(0):
		if r.pos.distance_to(g.pos) > RALLY_RADIUS:
			continue
		if r.state == S.ROUTING:
			if r.strength() >= 0.2:
				_rally(r)
				r.morale = r.morale_max * 0.6
		else:
			r.morale = minf(r.morale_max, r.morale + 40.0)
	_emit({"type": "horn", "pos": g.pos, "team": 0})


func _ability_barrage(at: Vector2) -> void:
	if not _ability_ready("barrage"):
		return
	cooldowns.barrage = ABILITY_COOLDOWN.barrage
	for i in 6:
		var off := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, 70.0)
		shells.append({"pos": at + off, "t": 1.2 + 0.25 * i})
	_emit({"type": "barrage", "pos": at, "team": 0})


func _ability_march(ids: Array) -> void:
	if not _ability_ready("march"):
		return
	cooldowns.march = ABILITY_COOLDOWN.march
	for id in ids:
		var r := _commandable(id)
		if r != null and r.team == 0:
			r.march_t = 10.0
	_emit({"type": "march", "team": 0})


# --- the step --------------------------------------------------------------

func step(dt: float) -> void:
	if phase != "battle":
		return
	time += dt
	_update_contacts()
	for r in regiments:
		if r.alive():
			_think(r, dt)
	_separate()
	_melee(dt)
	_ranged(dt)
	_fly(dt)
	_shells(dt)
	_morale(dt)
	_flags(dt)
	_drain(dt)
	_place_soldiers(dt)
	for key in cooldowns:
		cooldowns[key] = maxf(0.0, cooldowns[key] - dt)
	_check_end(dt)


func _update_contacts() -> void:
	var pairs: Array = []
	for r in regiments:
		r.contacts.clear()
	for i in regiments.size():
		var a := regiments[i]
		if not a.alive():
			continue
		for j in range(i + 1, regiments.size()):
			var b := regiments[j]
			if b.team == a.team or not b.alive():
				continue
			if not a.fighting() and not b.fighting():
				continue
			var d := a.pos.distance_to(b.pos)
			var ang := (b.pos - a.pos).angle()
			if d < a.reach(ang) + b.reach(ang + PI):
				pairs.append([d, a, b])
	pairs.sort_custom(func(x, y): return x[0] < y[0])
	for p in pairs:
		p[1].contacts.append(p[2].id)
		p[2].contacts.append(p[1].id)


func _think(r: Regiment, dt: float) -> void:
	r.charge_t = maxf(0.0, r.charge_t - dt)
	r.march_t = maxf(0.0, r.march_t - dt)
	r.repath -= dt
	if r.state == S.ROUTING:
		_flee(r, dt)
		return
	if not r.contacts.is_empty():
		_hold_contact(r, dt)
		return
	if r.state == S.ENGAGED:
		r.state = S.IDLE
	_pursue(r)
	if r.waypoints.is_empty() and r.target_id < 0 and not UnitTypes.is_ranged(r.kind):
		var e := _nearest_enemy(r, ENGAGE_RADIUS * (1.4 if UnitTypes.is_mounted(r.kind) else 1.0), true)
		if e != null:
			r.target_id = e.id
			r.ordered = false
			_pursue(r)
	if r.waypoints.is_empty():
		r.last_speed = 0.0
		if r.state == S.MOVING:
			r.state = S.IDLE
		if not is_nan(r.final_facing):
			_turn(r, r.final_facing, dt)
		return
	r.state = S.MOVING
	var goal := r.waypoints[0]
	_advance(r, goal, 1.0, dt)
	if r.pos.distance_to(goal) < 4.0:
		r.waypoints.remove_at(0)


## Close on the target, or stop in range of it when shooting.
func _pursue(r: Regiment) -> void:
	if r.target_id < 0:
		return
	var t := get_regiment(r.target_id)
	var mounted := UnitTypes.is_mounted(r.kind)
	if t == null or not t.alive() or (t.state == S.ROUTING and not mounted):
		r.target_id = -1
		r.waypoints = PackedVector2Array()
		return
	if UnitTypes.is_ranged(r.kind):
		if r.pos.distance_to(t.pos) <= _range_of(r) * 0.95:
			r.waypoints = PackedVector2Array()
			r.final_facing = (t.pos - r.pos).angle()
			return
	var goal := t.pos
	if not is_nan(r.via.x):
		if r.pos.distance_to(r.via) < 12.0:
			r.via = Vector2(NAN, NAN)
		else:
			goal = r.via
	if r.repath <= 0.0 or r.waypoints.is_empty():
		r.waypoints = terrain.path(r.pos, goal)
		r.repath = 0.5


func _hold_contact(r: Regiment, dt: float) -> void:
	var was_engaged := r.state == S.ENGAGED
	r.state = S.ENGAGED
	var primary := get_regiment(r.contacts[0])
	if r.target_id in r.contacts:
		primary = get_regiment(r.target_id)
	if not was_engaged:
		_on_impact(r, primary)
	if r.ordered and not r.waypoints.is_empty() and r.target_id < 0:
		# Ordered away: withdraw at half pace if the way is clear of the enemy.
		var away := true
		var dir := r.waypoints[0] - r.pos
		for id in r.contacts:
			if dir.dot(get_regiment(id).pos - r.pos) > 0.0:
				away = false
		if away:
			_advance(r, r.waypoints[0], 0.5, dt)
			return
	if primary.fighting() or UnitTypes.is_mounted(r.kind):
		_turn(r, (primary.pos - r.pos).angle(), dt)
	r.last_speed = 0.0


func _on_impact(r: Regiment, enemy: Regiment) -> void:
	if not UnitTypes.is_mounted(r.kind) or r.last_speed < r.speed * 0.6:
		return
	var z := Combat.zone(enemy.pos, enemy.facing, r.pos)
	if not Combat.charge_lands(enemy.kind, z):
		_emit({"type": "braced", "pos": enemy.pos})
		return
	r.charge_t = Combat.CHARGE_TIME
	enemy.morale -= Combat.CHARGE_SHOCK * Combat.ZONE_MORALE[z]
	_emit({"type": "charge", "pos": (r.pos + enemy.pos) * 0.5, "team": r.team})


func _flee(r: Regiment, dt: float) -> void:
	if r.waypoints.is_empty():
		r.waypoints = terrain.path(r.pos, _edge_point(r))
	_advance(r, r.waypoints[0], 1.15, dt)
	if r.pos.distance_to(r.waypoints[0]) < 6.0:
		r.waypoints.remove_at(0)
	var edge_y := Terrain.SIZE.y - 12.0 if r.team == 0 else 12.0
	if (r.team == 0 and r.pos.y >= edge_y) or (r.team == 1 and r.pos.y <= edge_y):
		r.state = S.GONE
		r.fled = true
		_emit({"type": "fled", "pos": r.pos, "team": r.team})


func _edge_point(r: Regiment) -> Vector2:
	return Vector2(r.pos.x, Terrain.SIZE.y - 4.0 if r.team == 0 else 4.0)


func _advance(r: Regiment, goal: Vector2, pace: float, dt: float) -> void:
	var to_goal := goal - r.pos
	var dist := to_goal.length()
	if dist < 0.01:
		return
	var mult := terrain.speed_mult(r.pos) * pace * (1.6 if r.march_t > 0.0 else 1.0)
	var stride := minf(dist, r.speed * mult * dt)
	var dir := to_goal / dist
	var next := r.pos + dir * stride
	if terrain.is_blocked(next) and r.state != S.ROUTING:
		var slide_x := r.pos + Vector2(dir.x, 0.0) * stride
		var slide_y := r.pos + Vector2(0.0, dir.y) * stride
		if not terrain.is_blocked(slide_x):
			next = slide_x
		elif not terrain.is_blocked(slide_y):
			next = slide_y
		else:
			r.last_speed = 0.0
			r.waypoints = PackedVector2Array()
			return
	r.last_speed = r.pos.distance_to(next) / dt
	r.pos = terrain.clamp_to_field(next)
	_turn(r, dir.angle(), dt * 1.5)


func _turn(r: Regiment, angle: float, dt: float) -> void:
	var rate := 2.6 if UnitTypes.is_mounted(r.kind) else 1.5
	var diff := angle_difference(r.facing, angle)
	r.facing += clampf(diff, -rate * dt, rate * dt)


func _separate() -> void:
	for i in regiments.size():
		var a := regiments[i]
		if not a.alive():
			continue
		for j in range(i + 1, regiments.size()):
			var b := regiments[j]
			if not b.alive():
				continue
			var delta := b.pos - a.pos
			var d := delta.length()
			var ang := delta.angle()
			var want := (a.reach(ang) + b.reach(ang + PI)) * (0.85 if a.team == b.team else 0.7)
			if d >= want or d < 0.001:
				continue
			var push := delta / d * (want - d) * 0.25
			_nudge(a, -push)
			_nudge(b, push)


func _nudge(r: Regiment, by: Vector2) -> void:
	var next := terrain.clamp_to_field(r.pos + by)
	if not terrain.is_water(next):
		r.pos = next


func _melee(dt: float) -> void:
	for r in regiments:
		if not r.fighting() or r.contacts.is_empty():
			continue
		var share := 1.0 / r.contacts.size()
		for id in r.contacts:
			var e := get_regiment(id)
			if not e.alive():
				continue
			var z := Combat.zone(e.pos, e.facing, r.pos)
			if e.state == S.ROUTING:
				z = Combat.Zone.REAR
			var dps := Combat.melee_dps(
				r.kind, r.men(), r.formation_cols(r.men()), r.atk,
				e.kind, e.def + terrain.defence_bonus(e.pos), z, r.charge_t > 0.0
			) * share
			if e.fighting():
				e.morale -= Combat.MELEE_STRAIN * Combat.ZONE_MORALE[z] * share * dt
			_wound(e, dps * dt, r.pos, r, Combat.ZONE_MORALE[z])


func _range_of(r: Regiment) -> float:
	return r.fire_range * terrain.range_mult(r.pos)


func _ranged(dt: float) -> void:
	for r in regiments:
		if not r.fighting() or not UnitTypes.is_ranged(r.kind):
			continue
		r.reload -= dt
		if not r.contacts.is_empty() or (r.state == S.MOVING and r.target_id < 0):
			continue
		var t := _shot_target(r)
		if t == null:
			continue
		if r.waypoints.is_empty():
			_turn(r, (t.pos - r.pos).angle(), dt)
		if r.reload > 0.0:
			continue
		r.reload = r.reload_time * rng.randf_range(0.9, 1.1)
		if r.kind == K.ARCHERS:
			_loose_volley(r, t)
		else:
			_fire_guns(r, t)


func _shot_target(r: Regiment) -> Regiment:
	var reach := _range_of(r)
	var t := get_regiment(r.target_id) if r.target_id >= 0 else null
	if t != null and t.alive() and r.pos.distance_to(t.pos) <= reach:
		return t
	var best: Regiment = null
	var best_d := INF
	for e in regiments:
		if e.team == r.team or not e.alive():
			continue
		var d := r.pos.distance_to(e.pos)
		if d < 40.0 or d > reach:
			continue
		# Fighting regiments first, and those not already locked with ours.
		if not e.fighting():
			d += 400.0
		elif not e.contacts.is_empty():
			d += 120.0
		if d < best_d:
			best_d = d
			best = e
	return best


func _loose_volley(r: Regiment, t: Regiment) -> void:
	var dmg := Combat.volley_damage(r.men(), r.shot, r.accuracy, t.def + terrain.defence_bonus(t.pos))
	dmg *= terrain.cover(t.pos)
	if not t.contacts.is_empty():
		dmg *= 0.6
	var d := r.pos.distance_to(t.pos)
	projectiles.append({
		"kind": "arrows", "from": r.pos, "to": t.pos, "t": 0.0, "dur": 0.5 + d / 420.0,
		"target": t.id, "src": r.id, "team": r.team, "dmg": dmg, "count": mini(r.men(), 12),
		"seed": rng.randi(),
	})
	_emit({"type": "volley", "pos": r.pos, "team": r.team})


func _fire_guns(r: Regiment, t: Regiment) -> void:
	var guns := 2 if r.men() >= 5 else 1
	var d := r.pos.distance_to(t.pos)
	for g in guns:
		var scatter := 8.0 + d * 0.06
		var to := t.pos + Vector2(rng.randf_range(-scatter, scatter), rng.randf_range(-scatter, scatter))
		var from := r.pos + r.forward().orthogonal() * (g - 0.5) * 18.0
		projectiles.append({
			"kind": "ball", "from": from, "to": to, "t": 0.0, "dur": 0.25 + d / 600.0 + g * 0.12,
			"src": r.id, "team": r.team, "dmg": r.shot,
		})
		_emit({"type": "boom", "pos": from, "team": r.team})


func _fly(dt: float) -> void:
	var landed: Array[Dictionary] = []
	for p in projectiles:
		p.t += dt / p.dur
		if p.t >= 1.0:
			landed.append(p)
	for p in landed:
		projectiles.erase(p)
		var src := get_regiment(p.src)
		if p.kind == "arrows":
			var t := get_regiment(p.target)
			if t != null and t.alive():
				if t.fighting():
					t.morale -= 1.5
				_wound(t, p.dmg, p.from, src, 1.0)
		else:
			_blast(p.to, 1 - p.team, 13.0, 3, 6.0, src)
			_emit({"type": "impact", "pos": p.to, "big": false})


func _shells(dt: float) -> void:
	var due: Array[Dictionary] = []
	for s in shells:
		s.t -= dt
		if s.t <= 0.0:
			due.append(s)
	for s in due:
		shells.erase(s)
		_blast(s.pos, 1, 20.0, 5, 10.0, null)
		_emit({"type": "impact", "pos": s.pos, "big": true})


## Kill up to `max_kills` soldiers of `team` within `radius` of `at`, and
## shake every regiment of that team close by.
func _blast(at: Vector2, team: int, radius: float, max_kills: int, shock: float, src: Regiment) -> void:
	var left := max_kills
	for r in regiments:
		if r.team != team or not r.alive():
			continue
		var d := r.pos.distance_to(at)
		if d > 60.0 + r.width():
			continue
		if r.fighting() and d < 50.0:
			r.morale -= shock
		var victims: Array[int] = []
		for i in r.men():
			if left > 0 and r.soldiers[i].distance_to(at) < radius:
				victims.append(i)
				left -= 1
		if not victims.is_empty():
			_kill(r, victims, src, 1.0)


## Apply damage to `e`; whole soldiers die nearest to `from`.
func _wound(e: Regiment, dmg: float, from: Vector2, src: Regiment, morale_mult: float) -> void:
	e.wound += dmg
	var n := mini(int(e.wound / e.hp), e.men())
	if n <= 0:
		return
	e.wound -= n * e.hp
	var order: Array = range(e.men())
	order.sort_custom(func(a, b): return e.soldiers[a].distance_squared_to(from) < e.soldiers[b].distance_squared_to(from))
	_kill(e, order.slice(0, n), src, morale_mult)


func _kill(e: Regiment, indices: Array, src: Regiment, morale_mult: float) -> void:
	indices.sort()
	indices.reverse()
	for i in indices:
		_emit({"type": "death", "pos": e.soldiers[i], "team": e.team, "kind": e.kind})
		e.soldiers.remove_at(i)
	var n := indices.size()
	killed[1 - e.team] += n
	if src != null:
		src.kills += n
	if e.fighting():
		var aura := 0.7 if _in_aura(e) else 1.0
		e.morale -= Combat.loss_morale(n, e.men_max) * morale_mult * aura
	if e.men() == 0:
		_destroy(e)


func _destroy(e: Regiment) -> void:
	var was_routed := e.routed_once
	e.state = S.GONE
	resolve[e.team] -= DESTROYED_COST + (0.0 if was_routed else ROUT_COST)
	if e.kind == K.GENERAL:
		_lose_general(e.team)
	_emit({"type": "destroyed", "pos": e.pos, "team": e.team, "kind": e.kind})


func _lose_general(team: int) -> void:
	resolve[team] -= GENERAL_COST
	for r in team_regiments(team):
		if r.fighting():
			r.morale -= 25.0
	_emit({"type": "general", "team": team})


func _in_aura(r: Regiment) -> bool:
	if r.kind == K.GENERAL:
		return true
	var g := general_of(r.team)
	return g != null and g.pos.distance_to(r.pos) < AURA_RADIUS


func _morale(dt: float) -> void:
	for r in regiments:
		if not r.alive():
			continue
		if r.state == S.ROUTING:
			if _nearest_enemy(r, 130.0, true) == null:
				r.morale += 7.0 * dt
			if r.morale >= r.morale_max * 0.4 and r.strength() >= 0.25:
				_rally(r)
			continue
		var regen := 0.0
		if r.contacts.is_empty():
			regen = 3.5 + (3.0 if _in_aura(r) else 0.0)
		elif _in_aura(r):
			regen = 1.2
		r.morale = minf(r.morale_max, r.morale + regen * dt)
		if r.morale <= 0.0:
			_rout(r)


func _rout(r: Regiment) -> void:
	r.state = S.ROUTING
	r.morale = 0.0
	r.target_id = -1
	r.ordered = false
	r.charge_t = 0.0
	r.waypoints = terrain.path(r.pos, _edge_point(r))
	if not r.routed_once:
		r.routed_once = true
		resolve[r.team] -= ROUT_COST
		if r.kind == K.GENERAL:
			_lose_general(r.team)
	for f in team_regiments(r.team):
		if f != r and f.fighting() and f.pos.distance_to(r.pos) < PANIC_RADIUS:
			f.morale -= 5.0
	_emit({"type": "rout", "pos": r.pos, "team": r.team, "kind": r.kind, "id": r.id})


func _rally(r: Regiment) -> void:
	if r.team == broken_team:
		return
	r.state = S.IDLE
	r.waypoints = PackedVector2Array()
	r.final_facing = PI * 1.5 if r.team == 0 else PI * 0.5
	_emit({"type": "rally", "pos": r.pos, "team": r.team, "id": r.id})


func _nearest_enemy(r: Regiment, radius: float, fighting_only: bool) -> Regiment:
	var best: Regiment = null
	var best_d := radius
	for e in regiments:
		if e.team == r.team or not e.alive() or (fighting_only and not e.fighting()):
			continue
		var d := r.pos.distance_to(e.pos)
		if d < best_d:
			best_d = d
			best = e
	return best


func _flags(dt: float) -> void:
	for f in flags:
		var present := [0, 0]
		for r in regiments:
			if r.fighting() and r.pos.distance_to(f.pos) < FLAG_RADIUS:
				present[r.team] += 1
		var push := 0.0
		if present[0] > 0 and present[1] == 0:
			push = 1.0
		elif present[1] > 0 and present[0] == 0:
			push = -1.0
		if push == 0.0:
			continue
		f.progress = clampf(f.progress + push * CAPTURE_RATE * dt, -1.0, 1.0)
		var owner: int = f.owner
		if f.progress >= 1.0:
			owner = 0
		elif f.progress <= -1.0:
			owner = 1
		elif (f.owner == 0 and f.progress < 0.0) or (f.owner == 1 and f.progress > 0.0):
			owner = -1
		if owner != f.owner:
			f.owner = owner
			_emit({"type": "flag", "pos": f.pos, "owner": owner})


func _drain(dt: float) -> void:
	var diff := flags_held(0) - flags_held(1)
	var dusk := time > DUSK_TIME
	var rate := FLAG_DRAIN * (2.0 if dusk else 1.0)
	if diff > 0:
		resolve[1] -= rate * diff * dt
	elif diff < 0:
		resolve[0] -= rate * -diff * dt
	if dusk:
		resolve[0] -= DUSK_DRAIN * dt
		resolve[1] -= DUSK_DRAIN * dt
	resolve[0] = maxf(resolve[0], 0.0)
	resolve[1] = maxf(resolve[1], 0.0)


func _check_end(dt: float) -> void:
	if broken_team >= 0:
		break_timer -= dt
		if break_timer <= 0.0:
			phase = "over"
			winner = 1 - broken_team
			_emit({"type": "end", "winner": winner})
		return
	for team in 2:
		var standing := false
		for r in team_regiments(team):
			if r.fighting():
				standing = true
		if resolve[team] <= 0.0 or not standing:
			_break(team)
			return


func _break(team: int) -> void:
	broken_team = team
	break_timer = BREAK_DELAY
	resolve[team] = 0.0
	for r in team_regiments(team):
		if r.fighting():
			_rout(r)
	_emit({"type": "broken", "team": team})


func _place_soldiers(dt: float) -> void:
	for r in regiments:
		if not r.alive():
			continue
		var n := r.men()
		var k := minf(1.0, dt * (5.0 if UnitTypes.is_mounted(r.kind) else 3.5))
		var routing := r.state == S.ROUTING
		var fwd := r.forward()
		var front := r.formation_cols(n)
		for i in n:
			var target := r.slot_world(i, n)
			if routing:
				var h := float(i * 7919 + r.id * 104729)
				target += Vector2(sin(h), cos(h * 1.3)) * 16.0
			elif r.state == S.ENGAGED and i < front:
				target += fwd * (2.0 + 1.5 * sin(time * 9.0 + i * 1.7))
			r.soldiers[i] = r.soldiers[i].lerp(target, k)


func _emit(e: Dictionary) -> void:
	_events.append(e)
