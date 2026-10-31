class_name Telemetry
extends RefCounted
## Read-only measures of a battle, for the tests and the balance studies.


## A team's standing soldiers as a share of what it brought onto the field.
static func strength(b: Battle, team: int, fielded: int) -> float:
	var standing := 0
	for r in b.regiments:
		if r.team == team and r.fighting():
			standing += r.men()
	return float(standing) / float(maxi(fielded, 1))


static func fielded(b: Battle, team: int) -> int:
	var total := 0
	for r in b.regiments:
		if r.team == team:
			total += r.men()
	return total


## Who is ahead, from -1 (the enemy) to +1 (the player): half resolve,
## half standing strength.
static func lead(b: Battle, fielded_by_team: Array) -> float:
	var resolve: float = (b.resolve[0] - b.resolve[1]) / 100.0
	var standing := strength(b, 0, fielded_by_team[0]) - strength(b, 1, fielded_by_team[1])
	return 0.5 * resolve + 0.5 * standing


## Counts how often the lead changes hands. A side must get clear by
## MARGIN to count as leading, so a lead wobbling around zero is not a
## change; taking the first lead is not a change either.
class LeadTracker:
	const MARGIN := 0.06
	var leader := 0
	var changes := 0

	func sample(value: float) -> void:
		var now := leader
		if value > MARGIN:
			now = 1
		elif value < -MARGIN:
			now = -1
		if now != leader:
			if leader != 0:
				changes += 1
			leader = now


## How a battle went, second by second: what the measures of play read.
## Each sample holds the state at that second and what happened since the
## last one. Read-only: it notes, never changes, the battle.
class Trace:
	## Steps between samples: one a second.
	const SAMPLE_TICKS := 30
	const COUNTED := ["rout", "rally", "charge", "flank", "death", "volley", "musket", "boom"]

	var fielded := [0, 0]
	var samples: Array[Dictionary] = []
	var lead := LeadTracker.new()
	## Since the last sample, by side: events of each counted type (charges
	## and flanks by the side that made them, the rest by the side they
	## befell), and orders given.
	var _counts := {}
	var _orders := [0, 0]
	## Blows by the side that took them: for each new clash, the seconds its
	## attacker had been aimed at that regiment, or -1 when no one had aimed
	## (two regiments walked into each other).
	var blows := [[], []]
	## Regiment id -> [the regiment it aims at, since when].
	var _aimed := {}
	var _pairs := {}

	func start(b: Battle) -> void:
		fielded = [Telemetry.fielded(b, 0), Telemetry.fielded(b, 1)]
		_reset()

	func note_events(events: Array[Dictionary]) -> void:
		for e in events:
			if e.type in COUNTED and e.has("team"):
				_counts[e.type][e.team] += 1

	func note_orders(team: int, n: int) -> void:
		_orders[team] += n

	func sample(b: Battle) -> void:
		var value := Telemetry.lead(b, fielded)
		lead.sample(value)
		var men := [0, 0]
		var blocks := [0, 0]
		var engaged := [0, 0]
		for r in b.regiments:
			if r.fighting():
				men[r.team] += r.men()
				blocks[r.team] += 1
				if not r.contacts.is_empty():
					engaged[r.team] += 1
		_note_blows(b)
		samples.append({
			"t": snappedf(b.time, 0.01), "lead": value,
			"resolve": [b.resolve[0], b.resolve[1]], "men": men, "blocks": blocks,
			"engaged": engaged, "flags": b.flags.map(func(f): return f.owner),
			"counts": _counts, "orders": _orders,
		})
		_reset()

	func _note_blows(b: Battle) -> void:
		for r in b.regiments:
			if not r.fighting() or r.target_id < 0:
				_aimed.erase(r.id)
			elif not _aimed.has(r.id) or _aimed[r.id][0] != r.target_id:
				_aimed[r.id] = [r.target_id, b.time]
		var now := {}
		for r in b.regiments:
			if not r.fighting():
				continue
			for id in r.contacts:
				var key := Vector2i(mini(r.id, id), maxi(r.id, id))
				if now.has(key):
					continue
				now[key] = true
				if _pairs.has(key):
					continue
				var other := b.get_regiment(id)
				var announced := false
				for pair in [[r, other], [other, r]]:
					var by: Regiment = pair[0]
					var at: Regiment = pair[1]
					if _aimed.has(by.id) and _aimed[by.id][0] == at.id:
						blows[at.team].append(b.time - _aimed[by.id][1])
						announced = true
				if not announced:
					blows[0].append(-1.0)
					blows[1].append(-1.0)
		_pairs = now

	func _reset() -> void:
		_counts = {}
		for type in COUNTED:
			_counts[type] = [0, 0]
		_orders = [0, 0]
