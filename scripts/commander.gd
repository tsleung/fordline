class_name Commander
extends RefCounted
## Turns a battle into orders for one side. This one gives none: an army
## that is never commanded, the bottom of every skill ladder. The AI and
## anything else that commands a seat extends it.


func decide(_b: Battle, _team: int) -> Array:
	return []


## The core AI with a persona. `rally` blows the Rally horn when regiments
## near the general are breaking or broken, as a sharp player does.
class AICommander extends Commander:
	var persona: Dictionary
	var rally := false

	func _init(with_persona: Dictionary, blows_rally := false) -> void:
		persona = with_persona
		rally = blows_rally

	func decide(b: Battle, team: int) -> Array:
		var orders := AI.decide(b, team, persona)
		if rally and team == 0 and should_rally(b):
			orders.append({"type": "rally"})
		return orders

	## The horn is ready, the general stands, and a regiment within his
	## reach is running but worth saving, or close to running.
	static func should_rally(b: Battle) -> bool:
		if b.cooldowns.rally > 0.0:
			return false
		var g := b.general_of(0)
		if g == null:
			return false
		for r in b.team_regiments(0):
			if r == g or r.pos.distance_to(g.pos) > Battle.RALLY_RADIUS:
				continue
			if r.state == Regiment.State.ROUTING and r.strength() >= 0.2:
				return true
			if r.fighting() and r.morale < r.morale_max * 0.25:
				return true
		return false


## The core AI at a person's pace: it looks at the battle as often as a
## person might, and of the orders the AI would give it gives only
## `per_look`, the most urgent first. The rest wait; at the next look the
## AI proposes them again if they still matter. This is the ladder's
## stand-in for a player, who gives perhaps 10 to 30 orders a minute.
class PacedCommander extends AICommander:
	var per_look := 1

	func _init(with_persona: Dictionary, blows_rally := false, orders_per_look := 1) -> void:
		super(with_persona, blows_rally)
		per_look = orders_per_look

	func decide(b: Battle, team: int) -> Array:
		var keyed := super.decide(b, team).map(func(o): return [urgency(b, team, o), o])
		keyed.sort_custom(func(x, y): return x[0] < y[0])
		return keyed.slice(0, per_look).map(func(k): return k[1])

	## Lower is sooner: the horn first, then the regiment nearest an enemy.
	static func urgency(b: Battle, team: int, o: Dictionary) -> float:
		var r := b.get_regiment(o.get("id", -1))
		if r == null:
			return -INF
		var nearest := INF
		for f in b.team_regiments(1 - team):
			if f.fighting():
				nearest = minf(nearest, r.pos.distance_to(f.pos))
		return nearest
