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
