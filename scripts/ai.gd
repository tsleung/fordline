class_name AI
extends RefCounted
## A commander as a pure decision: battle state in, orders out.
## The enemy uses it every think; the headless balance tests use it for
## both sides.

const K := UnitTypes.Kind
const S := Regiment.State

const THINK_EVERY := 0.75

## hold: seconds to stay in the deployment line before advancing.
## flank: whether cavalry looks for rears and soft targets.
const PERSONAS := {
	"balanced": {"hold": 8.0, "flank": true},
	"aggressive": {"hold": 0.0, "flank": true},
	"dug_in": {"hold": 45.0, "flank": false},
	"flanker": {"hold": 12.0, "flank": true},
}


## Place orders that set out a team's regiments in its deployment zone:
## foot in front, archers then cannons behind, horse on the wings, the
## general at the back.
static func deploy_orders(b: Battle, team: int) -> Array:
	var foot: Array[Regiment] = []
	var archers: Array[Regiment] = []
	var guns: Array[Regiment] = []
	var horse: Array[Regiment] = []
	var general: Array[Regiment] = []
	for r in b.team_regiments(team):
		match r.kind:
			K.SWORDS, K.PIKES:
				foot.append(r)
			K.ARCHERS:
				archers.append(r)
			K.CANNONS:
				guns.append(r)
			K.CAVALRY:
				horse.append(r)
			K.GENERAL:
				general.append(r)
	foot.sort_custom(func(a, c): return a.kind < c.kind)
	var sign := -1.0 if team == 0 else 1.0
	var front_y := Terrain.SIZE.y - Terrain.DEPLOY_DEPTH + 40.0 if team == 0 else Terrain.DEPLOY_DEPTH - 40.0
	var face := -PI * 0.5 if team == 0 else PI * 0.5
	var cx := Terrain.SIZE.x * 0.5
	var orders: Array = []
	var rows := [
		[_interleave(foot), 0.0, 112.0],
		[archers, 50.0, 116.0],
		[guns, 88.0, 130.0],
		[general, 118.0, 80.0],
	]
	for row in rows:
		var units: Array = row[0]
		for i in units.size():
			var x: float = cx + (i - (units.size() - 1) * 0.5) * row[2]
			orders.append({"type": "place", "id": units[i].id, "to": Vector2(x, front_y - sign * row[1]), "facing": face})
	var half_front := maxf(foot.size(), 2) * 56.0 + 60.0
	for i in horse.size():
		var wing := -1.0 if i % 2 == 0 else 1.0
		var x := clampf(cx + wing * (half_front + (i / 2) * 95.0), Terrain.EDGE + 40.0, Terrain.SIZE.x - Terrain.EDGE - 40.0)
		orders.append({"type": "place", "id": horse[i].id, "to": Vector2(x, front_y - sign * 20.0), "facing": face})
	return orders


## Pikes between swords so a cavalry charge always finds a pike nearby.
static func _interleave(foot: Array[Regiment]) -> Array:
	var swords := foot.filter(func(r): return r.kind == K.SWORDS)
	var pikes := foot.filter(func(r): return r.kind == K.PIKES)
	var out: Array = []
	while not swords.is_empty() or not pikes.is_empty():
		if not swords.is_empty():
			out.append(swords.pop_front())
		if not pikes.is_empty():
			out.append(pikes.pop_front())
	return out


static func decide(b: Battle, team: int, persona: Dictionary) -> Array:
	var mine := _fighting(b, team)
	var foes := _fighting(b, 1 - team)
	var orders: Array = []
	if mine.is_empty() or foes.is_empty():
		return orders
	var home_y := Terrain.SIZE.y if team == 0 else 0.0
	var advancing: bool = b.time >= persona.hold or _foe_near_line(mine, foes, 260.0)
	var goals := _flag_goals(b, team)
	var foot_index := 0
	for r in mine:
		var o: Variant = null
		match r.kind:
			K.SWORDS, K.PIKES:
				o = _foot(b, r, foes, advancing, goals, foot_index)
				foot_index += 1
			K.ARCHERS:
				o = _archer(b, r, mine, foes, home_y, advancing)
			K.CANNONS:
				o = _gun(b, r, foes, goals, advancing, persona)
			K.CAVALRY:
				o = _horse(b, r, foes, advancing, persona)
			K.GENERAL:
				o = _general(r, mine, foes, home_y)
		if o != null:
			orders.append(o)
	return orders


static func _fighting(b: Battle, team: int) -> Array[Regiment]:
	var out: Array[Regiment] = []
	for r in b.team_regiments(team):
		if r.fighting():
			out.append(r)
	return out


static func _foe_near_line(mine: Array[Regiment], foes: Array[Regiment], radius: float) -> bool:
	for r in mine:
		for f in foes:
			if r.pos.distance_to(f.pos) < radius:
				return true
	return false


## Flags this team should take, most wanted first: not ours, then nearest
## to our side of the field.
static func _flag_goals(b: Battle, team: int) -> Array[Vector2]:
	var fl := b.flags.duplicate()
	var home_y := Terrain.SIZE.y if team == 0 else 0.0
	fl.sort_custom(func(a, c):
		var a_ours: bool = a.owner == team
		var c_ours: bool = c.owner == team
		if a_ours != c_ours:
			return c_ours
		return absf(a.pos.y - home_y) < absf(c.pos.y - home_y))
	var out: Array[Vector2] = []
	for f in fl:
		out.append(f.pos)
	return out


static func _foot(b: Battle, r: Regiment, foes: Array[Regiment], advancing: bool, goals: Array[Vector2], index: int) -> Variant:
	var reach := 220.0 if r.kind == K.PIKES else 170.0
	var best: Regiment = null
	var best_score := INF
	for f in foes:
		var d := r.pos.distance_to(f.pos)
		if d > reach:
			continue
		var score := d - 60.0 * (Combat.type_mult(r.kind, f.kind) - 1.0)
		score -= 50.0 if not f.contacts.is_empty() else 0.0
		if r.kind == K.PIKES and UnitTypes.is_mounted(f.kind):
			score -= 120.0
		if score < best_score:
			best_score = score
			best = f
	if best != null:
		return _attack(r, best)
	if not advancing:
		return null
	var goal := goals[index % goals.size()]
	var spread := (float(index / goals.size()) - 0.5) * 70.0
	return _move(r, goal + Vector2(spread, 0.0))


static func _archer(b: Battle, r: Regiment, mine: Array[Regiment], foes: Array[Regiment], home_y: float, advancing: bool) -> Variant:
	for f in foes:
		if UnitTypes.is_ranged(f.kind) or not f.contacts.is_empty():
			continue
		if r.pos.distance_to(f.pos) < 110.0:
			var away := (r.pos - f.pos).normalized() * 100.0
			away.y += 40.0 if home_y > 0.0 else -40.0
			return _move(r, r.pos + away)
	var reach := r.fire_range * b.terrain.range_mult(r.pos)
	var target := _nearest(r, foes, reach)
	if target != null:
		return _attack(r, target)
	if not advancing:
		return null
	var anchor := _nearest_kind(r, mine, [K.SWORDS, K.PIKES])
	if anchor == null:
		return null
	var back := 1.0 if home_y > 0.0 else -1.0
	return _move(r, anchor.pos + Vector2(0.0, 75.0 * back))


static func _gun(b: Battle, r: Regiment, foes: Array[Regiment], goals: Array[Vector2], advancing: bool, persona: Dictionary) -> Variant:
	var reach := r.fire_range * b.terrain.range_mult(r.pos)
	if _nearest(r, foes, reach) != null:
		return null
	if not advancing or b.time < persona.hold + 15.0:
		return null
	var toward := goals[0]
	return _move(r, r.pos + (toward - r.pos).limit_length(120.0))


static func _horse(b: Battle, r: Regiment, foes: Array[Regiment], advancing: bool, persona: Dictionary) -> Variant:
	if not r.contacts.is_empty():
		for id in r.contacts:
			var e := b.get_regiment(id)
			if e.kind == K.PIKES and Combat.zone(e.pos, e.facing, r.pos) == Combat.Zone.FRONT:
				var back := (r.pos - e.pos).normalized() * 140.0
				return {"type": "move", "id": r.id, "to": r.pos + back}
		return null
	if not advancing:
		var close := _nearest(r, foes, 150.0)
		return _attack(r, close) if close != null else null
	var pikes := foes.filter(func(f): return f.kind == K.PIKES)
	var prey: Regiment = null
	var prey_d := INF
	for f in foes:
		if not (UnitTypes.is_ranged(f.kind) or (persona.flank and not f.contacts.is_empty() and f.kind != K.PIKES)):
			continue
		var guarded := false
		for p in pikes:
			if p.pos.distance_to(f.pos) < 120.0 and p.contacts.is_empty():
				guarded = true
		if guarded:
			continue
		var d := r.pos.distance_to(f.pos)
		if d < prey_d:
			prey_d = d
			prey = f
	if prey != null:
		if not prey.contacts.is_empty() and r.target_id != prey.id:
			var rear := prey.pos - prey.forward() * 90.0
			return {"type": "attack", "id": r.id, "target": prey.id, "via": b.terrain.clamp_to_field(rear)}
		return _attack(r, prey)
	var near := _nearest(r, foes, 130.0)
	if near != null and near.kind != K.PIKES:
		return _attack(r, near)
	return null


static func _general(r: Regiment, mine: Array[Regiment], foes: Array[Regiment], home_y: float) -> Variant:
	var centre := Vector2.ZERO
	var n := 0
	for m in mine:
		if m.kind == K.SWORDS or m.kind == K.PIKES:
			centre += m.pos
			n += 1
	if n == 0:
		return null
	centre /= n
	var back := 1.0 if home_y > 0.0 else -1.0
	var spot := centre + Vector2(0.0, 150.0 * back)
	var threat := _nearest(r, foes, 120.0)
	if threat != null:
		spot = r.pos + (r.pos - threat.pos).normalized() * 120.0
	return _move(r, spot)


static func _nearest(r: Regiment, among: Array[Regiment], radius: float) -> Regiment:
	var best: Regiment = null
	var best_d := radius
	for f in among:
		var d := r.pos.distance_to(f.pos)
		if d < best_d:
			best_d = d
			best = f
	return best


static func _nearest_kind(r: Regiment, among: Array[Regiment], kinds: Array) -> Regiment:
	var best: Regiment = null
	var best_d := INF
	for f in among:
		if f.kind in kinds:
			var d := r.pos.distance_to(f.pos)
			if d < best_d:
				best_d = d
				best = f
	return best


static func _attack(r: Regiment, t: Regiment) -> Variant:
	if r.target_id == t.id:
		return null
	return {"type": "attack", "id": r.id, "target": t.id}


## Move only when it changes where the regiment is going.
static func _move(r: Regiment, to: Vector2) -> Variant:
	var heading_to := r.waypoints[r.waypoints.size() - 1] if not r.waypoints.is_empty() else r.pos
	if heading_to.distance_to(to) < 30.0 and r.target_id < 0:
		return null
	return {"type": "move", "id": r.id, "to": to}
