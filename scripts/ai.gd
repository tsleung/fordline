class_name AI
extends RefCounted
## A commander as a pure decision: battle state in, orders out.
## The enemy uses it every think; the headless balance tests use it for
## both sides.

const K := UnitTypes.Kind
const S := Regiment.State

const THINK_EVERY := 0.75

## hold: seconds to hold the near side of the objectives before advancing
## past them.
## flank: whether cavalry looks for rears and soft targets.
## reserve: foot regiments kept behind the line and sent onto the flank of
## whoever a friend is fighting, as soon as that friend is pinned.
## terrain: archers take a hill behind the line when one is in reach.
## garrison: a castle's defenders. Foot fight only what gets inside the
## walls, shooters and guns man the wall-walk; horse may still sally.
const PERSONAS := {
	"garrison": {"hold": INF, "flank": true, "garrison": true},
	"balanced": {"hold": 8.0, "flank": true},
	"aggressive": {"hold": 0.0, "flank": true},
	"dug_in": {"hold": 45.0, "flank": false},
	"flanker": {"hold": 12.0, "flank": true},
	"reserve": {"hold": 8.0, "flank": true, "reserve": 1},
	"hills": {"hold": 8.0, "flank": true, "terrain": true},
}

## A friend in melee below this share of its nerve, or this stamina (about
## five seconds into a fight), calls in the reserve. Waiting until a friend
## is about to break measured worse: the reserve arrives too late.
const RESERVE_CALL_MORALE := 0.75
const RESERVE_CALL_STAMINA := 0.9
const RESERVE_REACH := 450.0
## While holding, foot stand this far short of each flag on their own side
## (inside its capture ring), and guns stand this far back from the flag
## they cover.
const HOLD_SHORT := 50.0
const BATTERY_BACK := 170.0
## A block keeps the enemy it is closing on unless another scores this much
## better.
const TARGET_STICK := 40.0
## Archers step back from foot this close; muskets only from foot about to
## strike, since a musket on the move doesn't fire and its range is short.
const ARCHERS_SHY := 110.0
const MUSKETS_SHY := 60.0
## Shooters keep behind pikes within this of them rather than other foot.
const PIKE_COVER := 300.0
## A division within this of its objective is there, and faces the enemy;
## its blocks stand this far apart, centre to centre.
const DIVISION_THERE := 220.0
const DIVISION_GAP := 120.0
## Horse whose orders start later still rides at an enemy this near.
const HORSE_WAKE := 500.0
## The line's allotment: an enemy block within THREAT_REACH of a flag is
## coming for the nearest; a flag is taken with TAKE_MARGIN times the
## weight of its defenders; TAKE_SPAN of distance counts as much as
## defenders as strong as the whole line, in choosing which to take.
const THREAT_REACH := 400.0
const TAKE_MARGIN := 1.3
const TAKE_SPAN := 800.0
## An enemy block is judged by where it will be this many seconds on.
const THREAT_LEAD := 6.0
## Idle horse take a flag no enemy stands within this of.
const FREE_REACH := 200.0


## Place orders that set out a team's regiments in its deployment zone:
## foot in front, archers and muskets then cannons behind, horse on the
## wings, the general at the back.
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
			K.ARCHERS, K.MUSKETS, K.RIFLES, K.LINE:
				archers.append(r)
			K.CANNONS:
				guns.append(r)
			K.CAVALRY:
				horse.append(r)
			K.GENERAL:
				general.append(r)
	foot.sort_custom(func(a, c): return a.kind < c.kind)
	var sign := -1.0 if team == 0 else 1.0
	var depth: float = b.terrain.deploy_depth[team]
	var front_y := b.terrain.size.y - depth + 40.0 if team == 0 else depth - 40.0
	var face := -PI * 0.5 if team == 0 else PI * 0.5
	var cx := b.terrain.size.x * 0.5
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
		var x := clampf(cx + wing * (half_front + (i / 2) * 95.0), Terrain.EDGE + 40.0, b.terrain.size.x - Terrain.EDGE - 40.0)
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


## Whichever side holds a castle fights as its garrison, whatever its
## persona otherwise. `plan` says where blocks of the line go, by id to
## flag index: the allotment a commander thought out last (allot), or a
## planner's choice. Blocks it doesn't name go where the AI allots them now.
## `only` (block ids) is the part of the side a seat commands, a division
## the player sent off on its own; it forms its lines among its own blocks.
## Empty: the whole side.
static func decide(b: Battle, team: int, persona: Dictionary, plan := {}, only: Array[int] = []) -> Array:
	if b.terrain.holder == team:
		persona = persona.merged(PERSONAS.garrison, true)
	var mine := _commanded(b, team, only)
	var foes := _fighting(b, 1 - team)
	var orders: Array = []
	if mine.is_empty() or foes.is_empty():
		return orders
	var home_y := b.terrain.size.y if team == 0 else 0.0
	## Toward this team's own edge.
	var home := Vector2(0.0, 1.0 if team == 0 else -1.0)
	var advancing: bool = b.time >= persona.hold or _foe_near_line(mine, foes, 260.0)
	var goals := _flags_left_to_right(b)
	var reserve := _reserve(mine, persona.get("reserve", 0))
	var garrison: bool = persona.get("garrison", false)
	# A garrison's line forms across the gateway, not out on the flags.
	if garrison:
		goals = [b.terrain.gate_mouth()] as Array[Vector2]
	# A garrison's foot ignore what is still outside the walls.
	var foot_foes: Array[Regiment] = []
	for f in foes:
		if not garrison or b.terrain.inside(f.pos):
			foot_foes.append(f)
	var shooters := mine.filter(func(r): return UnitTypes.is_ranged(r.kind))
	var line := _line(mine, reserve)
	var flag_of := {} if garrison else _allot(b, team, line, foes, plan)
	var allotted := {}
	for id in flag_of:
		allotted[id] = b.flags[flag_of[id]].pos
	for r in mine:
		var o: Variant = null
		# A block whose orders start later in the day keeps to its ground
		# until then, unless the enemy comes to it; horse held back watches
		# farther, as a reserve of cavalry does.
		var wake := HORSE_WAKE if UnitTypes.is_mounted(r.kind) else maxf(r.fire_range, 150.0) * 1.1
		if b.time < r.holds_until and _nearest(r, foes, wake) == null:
			continue
		match r.kind:
			K.SWORDS, K.PIKES:
				if r.id in reserve:
					o = _reserve_foot(b, r, line, foot_foes, home_y)
				else:
					o = _foot(r, foot_foes, advancing, _spot(b, team, r, line, goals, allotted), home)
			K.RIFLES, K.LINE:
				o = _rifle(r, foes, advancing, _spot(b, team, r, line, goals, allotted), home)
			K.ARCHERS, K.MUSKETS:
				if garrison:
					o = _man_wall(b, r, foes, shooters.find(r))
				else:
					o = _archer(b, r, mine, foes, home_y, persona.get("terrain", false))
			K.CANNONS:
				if garrison:
					o = _man_wall(b, r, foes, shooters.find(r))
				else:
					var aims := _flag_goals(b, team)
					var back := home
					if not r.objectives.is_empty():
						# Unlimber short of the objective on the way in.
						aims = [_objective(b, team, r.objectives) as Vector2] as Array[Vector2]
						back = (r.pos - aims[0]).normalized()
					o = _gun(b, r, foes, aims, back)
			K.CAVALRY:
				o = _horse(b, r, foes, advancing, persona)
			K.GENERAL:
				o = _general(r, mine, foes, home_y)
		if o != null:
			orders.append(o)
	return orders


## Where the line goes, thought out on its own: the plan a commander keeps
## and hands back to decide() until it thinks again. By id to flag index;
## a garrison's line has none, it stands across the gateway. `only` as
## for decide().
static func allot(b: Battle, team: int, persona: Dictionary, only: Array[int] = []) -> Dictionary:
	if b.terrain.holder == team or persona.get("garrison", false):
		return {}
	var mine := _commanded(b, team, only)
	var foes := _fighting(b, 1 - team)
	if mine.is_empty() or foes.is_empty():
		return {}
	return _allot(b, team, _line(mine, _reserve(mine, persona.get("reserve", 0))), foes, {})


## The foot and rifles that stand in the line, left to right: all but the
## reserve.
static func _line(mine: Array[Regiment], reserve: Array[int]) -> Array[Regiment]:
	var line: Array[Regiment] = []
	for r in mine:
		if (r.kind == K.SWORDS or r.kind == K.PIKES or r.kind == K.RIFLES or r.kind == K.LINE) and not r.id in reserve:
			line.append(r)
	line.sort_custom(func(a, c): return a.pos.x < c.pos.x)
	return line


## The side's fighting regiments, or of them those in `only`.
static func _commanded(b: Battle, team: int, only: Array[int]) -> Array[Regiment]:
	var mine := _fighting(b, team)
	return mine if only.is_empty() else mine.filter(func(r): return r.id in only)


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


## The line's share of the front: left-hand regiments take the left-hand
## goal and so on, side by side within each share.
static func _line_spot(line: Array[Regiment], i: int, goals: Array[Vector2]) -> Vector2:
	var g := mini(i * goals.size() / maxi(line.size(), 1), goals.size() - 1)
	var group: Array[int] = []
	for j in line.size():
		if mini(j * goals.size() / line.size(), goals.size() - 1) == g:
			group.append(j)
	var k := group.find(i)
	return goals[g] + Vector2((k - (group.size() - 1) * 0.5) * 85.0, 0.0)


## Where a line regiment stands: in a division's line across its goal,
## beside the blocks of its formation under the same orders. A block's
## goal is its own objective (a grand battle's division, or a flag the
## player sent it to on its own command), or else the flag its side
## allotted it. A line with no allotment (a garrison's, across its
## gateway) takes its share of the front.
##
## Under the same orders, not merely of the same division: a block the
## player sends off alone forms its line by itself on the flag, not at
## the end of a line with the blocks still in the player's hands, which
## would stand it outside the flag's ring for good.
static func _spot(b: Battle, team: int, r: Regiment, line: Array[Regiment], goals: Array[Vector2], allotted: Dictionary) -> Vector2:
	var goal: Variant = _goal(b, team, r, allotted)
	if goal == null:
		return _line_spot(line, line.find(r), goals)
	var division: Array[Regiment] = []
	for o in line:
		if o.formation == r.formation and o.objectives == r.objectives and allotted.get(o.id) == allotted.get(r.id):
			division.append(o)
	return _division_spot(b, team, r, division, goal)


## Where a block is going: its objective, else its allotted flag, else
## nowhere (null).
static func _goal(b: Battle, team: int, r: Regiment, allotted: Dictionary) -> Variant:
	var objective: Variant = _objective(b, team, r.objectives)
	return objective if objective != null else allotted.get(r.id)


## A division forms side by side across its objective, square to the way
## it is going; once there, square to the nearest enemy. Each block keeps
## its place from left to right, so their routes don't cross. `r` stands
## in the line whether or not `division` names it.
static func _division_spot(b: Battle, team: int, r: Regiment, division: Array[Regiment], objective: Vector2) -> Vector2:
	var order := division.duplicate()
	if not r in order:
		order.append(r)
	var centre := Vector2.ZERO
	for o in order:
		centre += o.pos
	centre /= order.size()
	var ahead := objective - centre
	if ahead.length() < DIVISION_THERE:
		var nearest := INF
		for f in _fighting(b, 1 - team):
			var d := f.pos.distance_to(objective)
			if d < nearest:
				nearest = d
				ahead = f.pos - objective
	var across := ahead.normalized().orthogonal() if ahead.length() > 1.0 else Vector2.RIGHT
	order.sort_custom(func(x, y): return x.pos.dot(across) < y.pos.dot(across))
	var k := order.find(r)
	return objective + across * (k - (order.size() - 1) * 0.5) * DIVISION_GAP


## A division's objectives are flags to take in order: the first it
## doesn't hold. Once it holds them all it stays on the last. With none,
## null.
static func _objective(b: Battle, team: int, objectives: PackedVector2Array) -> Variant:
	if objectives.is_empty():
		return null
	for p in objectives:
		for f in b.flags:
			if f.pos.distance_to(p) < Battle.FLAG_RADIUS and f.owner != team:
				return p
	return objectives[objectives.size() - 1]


static func _flags_left_to_right(b: Battle) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for f in b.flags:
		out.append(f.pos)
	out.sort_custom(func(a, c): return a.x < c.x)
	return out


## Flags this team should take, most wanted first: not ours, then nearest
## to our side of the field.
static func _flag_goals(b: Battle, team: int) -> Array[Vector2]:
	var fl := b.flags.duplicate()
	var home_y := b.terrain.size.y if team == 0 else 0.0
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


## A block's weight in a fight: its men, how much each takes to kill and
## how hard he hits, worn down by fatigue and failing nerve.
static func _power(r: Regiment) -> float:
	return r.men() * r.hp * r.atk * Combat.fatigue_hit(r.stamina) * (0.5 + 0.5 * r.morale / r.morale_max)


## Where the line goes: in strength to the flags that matter, as the plans
## that beat it do, rather than spread over every flag. The needs, most
## pressing first: each flag this side holds that the enemy is coming for,
## enough to outweigh what comes; then each flag it could take, the least
## held and nearest first, TAKE_MARGIN times its defenders and at least
## one block. A need the line hasn't the strength left to meet gets nobody,
## rather than blocks sent one at a time to be beaten in turn. Blocks left
## over stand behind the first need met while time is on this side, and
## otherwise go for the flag it most wants, since waiting loses. A block
## bound for a flag that still needs it keeps it, so blocks don't trade
## places as the enemy moves; then each need takes the nearest free blocks
## for what it lacks. An enemy block is coming for the flag nearest where
## it is headed (_lead), within THREAT_REACH. Blocks with objectives of
## their own are not the side's to send, and blocks in `plan` go where it
## sends them. Returns each block's flag index, by id.
static func _allot(b: Battle, team: int, line: Array[Regiment], foes: Array[Regiment], plan: Dictionary) -> Dictionary:
	var allotted := {}
	var free: Array[Regiment] = []
	for r in line:
		if plan.has(r.id):
			allotted[r.id] = plan[r.id]
		elif r.objectives.is_empty():
			free.append(r)
	if free.is_empty() or b.flags.is_empty():
		return allotted
	var threat: Array[float] = []
	threat.resize(b.flags.size())
	threat.fill(0.0)
	for f in foes:
		var i := _nearest_flag(b, _lead(b, f), THREAT_REACH)
		if i >= 0 and f.kind != K.GENERAL:
			threat[i] += _power(f)
	var spare := 0.0
	var centre := Vector2.ZERO
	for r in free:
		spare += _power(r)
		centre += r.pos
	centre /= free.size()
	var defend: Array[int] = []
	var take: Array[int] = []
	for i in b.flags.size():
		if b.flags[i].owner != team:
			take.append(i)
		elif threat[i] > 0.0:
			defend.append(i)
	defend.sort_custom(func(x, y): return threat[x] > threat[y])
	var cost := func(i: int) -> float: return threat[i] / spare + centre.distance_to(b.flags[i].pos) / TAKE_SPAN
	take.sort_custom(func(x, y): return cost.call(x) < cost.call(y))
	var needs: Array = defend.map(func(i): return [i, threat[i]])
	needs.append_array(take.map(func(i): return [i, threat[i] * TAKE_MARGIN]))
	# A flag the line can't make good gets nobody, rather than blocks sent
	# one at a time to be beaten in turn; what it can't win there it keeps
	# for where it can.
	var met: Array = []
	var left := spare
	for need in needs:
		if need[1] <= left:
			met.append(need)
			left -= need[1]
	var given: Array[float] = []
	given.resize(b.flags.size())
	given.fill(0.0)
	# Blocks already bound for a flag that needs them stay; then each need,
	# in turn, takes the nearest free blocks for what it still lacks.
	for keep in [true, false]:
		for need in met:
			var i: int = need[0]
			while given[i] == 0.0 or given[i] < need[1]:
				var r := _nearest_to(b.flags[i].pos, free.filter(func(c): return not keep or _bound_flag(b, c) == i), INF)
				if r == null:
					break
				free.erase(r)
				allotted[r.id] = i
				given[i] += _power(r)
	# Blocks left over: while time is on this side, behind the first need it
	# met; otherwise waiting loses, so at the flag it most wants to take,
	# even one it can't yet make good.
	var main := -1
	if not _time_on_side(b, team) and not take.is_empty():
		main = take[0]
	elif not met.is_empty():
		main = met[0][0]
	elif not needs.is_empty():
		main = needs[0][0]
	for r in free:
		allotted[r.id] = main if main >= 0 else _nearest_flag(b, r.pos, INF)
	return allotted


## Whether waiting wins for `team` as things stand: the clock would end
## the battle its way before the flags' drain breaks it; or, with no clock,
## the flags drain the enemy and not it.
static func _time_on_side(b: Battle, team: int) -> bool:
	var ahead := b.flags_held(team) - b.flags_held(1 - team)
	if b.deadline <= 0.0:
		return ahead > 0
	var player_holds := b.flags_held(0) >= b.hold_needed
	if not b.deadline_flags.is_empty():
		player_holds = b.deadline_flags.all(func(i): return b.flags[i].owner == 0)
	if player_holds != (team == 0):
		return false
	if ahead >= 0 or b.flag_drain <= 0.0:
		return true
	return b.resolve[team] / (b.flag_drain * -ahead) > b.deadline - b.time


## Where a block will be in THREAT_LEAD seconds if it keeps on: toward the
## enemy it is attacking, or along its way.
static func _lead(b: Battle, r: Regiment) -> Vector2:
	var to := _bound_for(r)
	var t := b.get_regiment(r.target_id)
	if t != null:
		to = t.pos
	return r.pos + (to - r.pos).limit_length(r.speed * THREAT_LEAD)


## The end of a block's way, or where it stands.
static func _bound_for(r: Regiment) -> Vector2:
	return r.waypoints[r.waypoints.size() - 1] if not r.waypoints.is_empty() else r.pos


## The flag a block is bound for or stands at, or -1.
static func _bound_flag(b: Battle, r: Regiment) -> int:
	return _nearest_flag(b, _bound_for(r), DIVISION_THERE)


## The flag nearest `p` within `radius`, or -1.
static func _nearest_flag(b: Battle, p: Vector2, radius: float) -> int:
	var best := -1
	var best_d := radius
	for i in b.flags.size():
		var d := p.distance_to(b.flags[i].pos)
		if d < best_d:
			best_d = d
			best = i
	return best


## Fight what comes within reach; otherwise take the goal, or while
## holding, stand just short of it on our own side. A block in melee fights
## whoever it is fighting: pointed at another, it would turn to face it and
## give its flank to the one in front. One closing on an enemy keeps it
## unless another is clearly better (TARGET_STICK), and one that takes its
## place faces the nearest enemy, not the way it walked.
static func _foot(r: Regiment, foes: Array[Regiment], advancing: bool, goal: Vector2, home: Vector2) -> Variant:
	if not r.contacts.is_empty():
		return null
	var reach := 220.0 if r.kind == K.PIKES else 170.0
	var stand := goal + home * HOLD_SHORT if not advancing else goal
	var best: Regiment = null
	var best_score := INF
	for f in foes:
		var d := r.pos.distance_to(f.pos)
		if d > reach:
			continue
		var score := d - 60.0 * (Combat.type_mult(r.kind, f.kind) - 1.0)
		score -= 50.0 if not f.contacts.is_empty() else 0.0
		score -= TARGET_STICK if f.id == r.target_id else 0.0
		if r.kind == K.PIKES and UnitTypes.is_mounted(f.kind):
			score -= 120.0
		if score < best_score:
			best_score = score
			best = f
	if best != null:
		return _attack(r, best)
	var facing := NAN
	var near := _nearest_to(stand, foes, INF)
	if near != null:
		facing = (near.pos - stand).angle()
	return _move(r, stand, facing)


## The foot held back: the last `count` by id, always leaving two in line.
static func _reserve(mine: Array[Regiment], count: int) -> Array[int]:
	var foot: Array[int] = []
	for r in mine:
		if r.kind == K.SWORDS or r.kind == K.PIKES:
			foot.append(r.id)
	foot.sort()
	var keep := mini(count, foot.size() - 2)
	return foot.slice(foot.size() - keep) if keep > 0 else ([] as Array[int])


## A reserve waits behind the middle of the line. When a friend in melee is
## pinned it goes in on the flank of whoever that friend is fighting, and
## when that fight is done it falls back to wait again.
static func _reserve_foot(b: Battle, r: Regiment, line: Array[Regiment], foes: Array[Regiment], home_y: float) -> Variant:
	if not r.contacts.is_empty() or r.target_id >= 0:
		return null
	var best: Regiment = null
	var best_d := RESERVE_REACH
	for f in line:
		if f.contacts.is_empty():
			continue
		if f.morale > f.morale_max * RESERVE_CALL_MORALE and f.stamina > RESERVE_CALL_STAMINA:
			continue
		var enemy := b.get_regiment(f.contacts[0])
		var d := r.pos.distance_to(enemy.pos)
		if enemy.fighting() and d < best_d:
			best_d = d
			best = enemy
	if best != null:
		var side := best.forward().orthogonal()
		if side.dot(r.pos - best.pos) < 0.0:
			side = -side
		var via := b.terrain.clamp_to_field(best.pos + side * 80.0)
		return {"type": "attack", "id": r.id, "target": best.id, "via": via}
	var near := _nearest(r, foes, 120.0)
	if near != null:
		return _attack(r, near)
	if line.is_empty():
		return null
	var centre := Vector2.ZERO
	for f in line:
		centre += f.pos
	centre /= line.size()
	var back := 1.0 if home_y > 0.0 else -1.0
	return _move(r, centre + Vector2(0.0, 110.0 * back))


## Archers and muskets: step back from foot closing on them, else shoot
## at the nearest in reach, else keep behind the line, behind pikes where
## there are any near (PIKE_COVER), since horse won't ride at shooters
## pikes stand by. They keep with the line while it holds too, so a line
## that steps up to its flags doesn't leave them behind for horse to take.
static func _archer(b: Battle, r: Regiment, mine: Array[Regiment], foes: Array[Regiment], home_y: float, use_hills: bool) -> Variant:
	var shy := ARCHERS_SHY if r.kind == K.ARCHERS else MUSKETS_SHY
	for f in foes:
		if UnitTypes.is_ranged(f.kind) or not f.contacts.is_empty():
			continue
		if r.pos.distance_to(f.pos) < shy:
			var away := (r.pos - f.pos).normalized() * 100.0
			away.y += 40.0 if home_y > 0.0 else -40.0
			return _move(r, r.pos + away)
	var reach := r.fire_range * b.terrain.range_mult(r.pos)
	var target := _nearest(r, foes, reach)
	if target != null:
		return _attack(r, target)
	var anchor := _nearest_kind(r, mine, [K.PIKES])
	if anchor == null or anchor.pos.distance_to(r.pos) > PIKE_COVER:
		anchor = _nearest_kind(r, mine, [K.SWORDS, K.PIKES])
	if anchor == null:
		return null
	var back := 1.0 if home_y > 0.0 else -1.0
	var spot := anchor.pos + Vector2(0.0, 75.0 * back)
	if use_hills:
		spot = _hill_near(b.terrain, spot, anchor.pos)
	return _move(r, spot)


## The closest hilltop to `spot` from which archers still reach past
## `front`; `spot` itself when there is none.
static func _hill_near(t: Terrain, spot: Vector2, front: Vector2) -> Vector2:
	var best := spot
	var best_d := 200.0
	for h in t.hills:
		var top: Vector2 = h.c + (front - h.c).limit_length(h.r * 0.4)
		if top.distance_to(front) > 170.0 or t.is_water(top):
			continue
		var d := top.distance_to(spot)
		if d < best_d:
			best_d = d
			best = top
	return best


## A garrison's shooter takes its station on the wall-walk (the best
## stations first, in id order) and from there shoots back at the enemy's
## shooters first, then at the nearest in reach.
static func _man_wall(b: Battle, r: Regiment, foes: Array[Regiment], index: int) -> Variant:
	var posts := b.terrain.posts
	if posts.is_empty():
		return null
	var post := posts[index % posts.size()]
	if r.pos.distance_to(post) > 24.0:
		return _move(r, post)
	var reach := r.fire_range * b.terrain.range_mult(r.pos)
	var shooters: Array[Regiment] = []
	for f in foes:
		if UnitTypes.is_ranged(f.kind):
			shooters.append(f)
	var target := _nearest(r, shooters, reach)
	if target == null:
		target = _nearest(r, foes, reach)
	return _attack(r, target) if target != null else null


## Before a castle, guns batter the nearest gate still shut against them.
## Otherwise they keep firing at whatever is in range, or stand behind the
## most wanted flag, close enough to cover it.
static func _gun(b: Battle, r: Regiment, foes: Array[Regiment], goals: Array[Vector2], home: Vector2) -> Variant:
	if b.terrain.has_walls() and b.terrain.holder != r.team:
		for g in b.terrain.gates.size():
			if not b.terrain.gate_broken[g]:
				if r.target_gate == g:
					return null
				return {"type": "bombard", "id": r.id, "gate": g}
	var reach := r.fire_range * b.terrain.range_mult(r.pos)
	if _nearest(r, foes, reach) != null:
		# A battery on its way to an objective unlimbers where it is.
		if not r.objectives.is_empty() and not r.waypoints.is_empty():
			return {"type": "halt", "id": r.id}
		return null
	return _move(r, b.terrain.clamp_to_field(goals[0] + home * BATTERY_BACK))


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
	if r.objectives.is_empty():
		var flag := _free_flag(b, r, foes)
		if flag >= 0:
			return _move(r, b.flags[flag].pos)
	return null


## Horse with nothing to ride at takes the nearest flag not yet its side's
## that no enemy stands near (FREE_REACH): it gets there first, and a flag
## is held by whoever stands on it alone. -1 when there is none.
static func _free_flag(b: Battle, r: Regiment, foes: Array[Regiment]) -> int:
	var best := -1
	var best_d := INF
	for i in b.flags.size():
		var at: Vector2 = b.flags[i].pos
		if b.flags[i].owner == r.team or _nearest_to(at, foes, FREE_REACH) != null:
			continue
		var d := r.pos.distance_to(at)
		if d < best_d:
			best_d = d
			best = i
	return best


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
	return _nearest_to(r.pos, among, radius)


static func _nearest_to(p: Vector2, among: Array[Regiment], radius: float) -> Regiment:
	var best: Regiment = null
	var best_d := radius
	for f in among:
		var d := p.distance_to(f.pos)
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


## Rifles are the line: they take their place in it, and anything that
## comes within range they stand and shoot at.
static func _rifle(r: Regiment, foes: Array[Regiment], advancing: bool, goal: Vector2, home: Vector2) -> Variant:
	if r.kind == K.LINE and _horse_near(r, foes, Battle.SQUARE_STAND):
		# Horse about: stand, so the square forms and holds.
		return {"type": "halt", "id": r.id} if not r.waypoints.is_empty() else null
	var best: Regiment = null
	var best_d := r.fire_range * 1.1
	for f in foes:
		var d := r.pos.distance_to(f.pos)
		if d < best_d:
			best_d = d
			best = f
	if best != null:
		return _attack(r, best)
	if not advancing:
		return _move(r, goal + home * HOLD_SHORT)
	return _move(r, goal)


static func _horse_near(r: Regiment, foes: Array[Regiment], radius: float) -> bool:
	return foes.any(func(f): return UnitTypes.is_mounted(f.kind) and f.pos.distance_to(r.pos) < radius)


## Move only when it changes where the regiment is going; with a
## `facing`, it turns that way once there.
static func _move(r: Regiment, to: Vector2, facing := NAN) -> Variant:
	var heading_to := r.waypoints[r.waypoints.size() - 1] if not r.waypoints.is_empty() else r.pos
	if heading_to.distance_to(to) < 30.0 and r.target_id < 0:
		return null
	if is_nan(facing):
		return {"type": "move", "id": r.id, "to": to}
	return {"type": "move", "id": r.id, "to": to, "facing": facing}
