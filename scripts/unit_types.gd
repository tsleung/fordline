class_name UnitTypes
extends RefCounted
## Regiment types and their base stats. Pure data.

enum Kind { SWORDS, PIKES, ARCHERS, CAVALRY, CANNONS, GENERAL }

## men: soldiers at full strength. hp: per soldier. atk: damage per second
## per fighting soldier. def: fraction of incoming damage ignored.
## speed: world units per second. cols: soldiers per rank. spacing: gap
## between soldiers. range/reload/shot: ranged units only.
const STATS := {
	Kind.SWORDS: {
		"name": "Swords", "men": 48, "hp": 10.0, "atk": 1.0, "def": 0.30,
		"speed": 30.0, "morale": 70.0, "cols": 12, "spacing": 8.0,
	},
	Kind.PIKES: {
		"name": "Pikes", "men": 48, "hp": 10.0, "atk": 0.8, "def": 0.30,
		"speed": 27.0, "morale": 70.0, "cols": 12, "spacing": 8.0,
	},
	Kind.ARCHERS: {
		"name": "Archers", "men": 36, "hp": 7.0, "atk": 0.5, "def": 0.10,
		"speed": 31.0, "morale": 55.0, "cols": 12, "spacing": 8.5,
		"range": 230.0, "reload": 3.5, "shot": 3.4, "accuracy": 0.4,
	},
	Kind.CAVALRY: {
		"name": "Cavalry", "men": 24, "hp": 16.0, "atk": 1.4, "def": 0.25,
		"speed": 68.0, "morale": 75.0, "cols": 8, "spacing": 10.5,
	},
	Kind.CANNONS: {
		"name": "Cannons", "men": 12, "hp": 8.0, "atk": 0.4, "def": 0.05,
		"speed": 16.0, "morale": 60.0, "cols": 6, "spacing": 9.0,
		"range": 430.0, "reload": 6.5, "shot": 11.0, "guns": 2,
	},
	Kind.GENERAL: {
		"name": "General", "men": 10, "hp": 24.0, "atk": 1.6, "def": 0.40,
		"speed": 64.0, "morale": 100.0, "cols": 5, "spacing": 10.5,
	},
}

const RECRUITABLE: Array[int] = [
	Kind.SWORDS, Kind.PIKES, Kind.ARCHERS, Kind.CAVALRY, Kind.CANNONS,
]


static func stat(kind: int, key: String) -> Variant:
	return STATS[kind][key]


static func label(kind: int) -> String:
	return STATS[kind]["name"]


static func is_ranged(kind: int) -> bool:
	return kind == Kind.ARCHERS or kind == Kind.CANNONS


static func is_mounted(kind: int) -> bool:
	return kind == Kind.CAVALRY or kind == Kind.GENERAL
