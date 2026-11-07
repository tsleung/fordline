class_name PackMedieval
extends RefCounted
## Quick battles with swords, pikes, bows, horse and guns.

const K := UnitTypes.Kind

const PACK := {
	"id": "medieval", "name": "Medieval", "menu": "quick",
	"modules": [],
	"era": {
		"id": "medieval", "name": "Medieval",
		"draw": [K.SWORDS, K.PIKES, K.ARCHERS, K.CAVALRY, K.CANNONS],
	},
	"scenarios": [
		{
			"id": "skirmish", "name": "Skirmish", "era": "medieval",
			"brief": "A new field each time and two armies made the same. Only how you fight is different.",
			"map": "random", "persona": "balanced",
			"stars": [{"time": 150.0}, {"losses": 0.35}],
		},
		{
			"id": "hold", "era": "medieval", "name": "Hold the Fords",
			"brief": "The three fords are yours and an army is coming for them. Still hold one when the clock runs out.",
			"map": "fords", "map_seed": 41, "persona": "aggressive",
			"player": [[K.SWORDS, 1], [K.SWORDS, 0], [K.PIKES, 1], [K.ARCHERS, 0], [K.ARCHERS, 0]],
			"enemy": [[K.SWORDS, 0], [K.SWORDS, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CAVALRY, 0]],
			"deadline": 180.0, "hold_needed": 1, "own_flags": [0, 1, 2], "deploy_depth": 370.0,
			"stars": [{"flags": 2}, {"losses": 0.4}],
		},
		{
			"id": "hammer", "era": "medieval", "name": "Hammer and Anvil",
			"brief": "Open woods. They have dug in with bows and a gun; you have horse. Pin them with the foot, then ride round.",
			"map": "woods", "map_seed": 7, "persona": "dug_in",
			"player": [[K.SWORDS, 0], [K.PIKES, 0], [K.CAVALRY, 0], [K.CAVALRY, 0], [K.CAVALRY, 1]],
			"enemy": [[K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 0], [K.PIKES, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.ARCHERS, 1], [K.CANNONS, 0], [K.CAVALRY, 0]],
			"stars": [{"time": 120.0}, {"losses": 0.3}],
		},
		{
			"id": "bridges", "era": "medieval", "name": "Two Narrow Bridges",
			"brief": "Take both bridges before dusk. They hold the far bank with guns; so do you, and you can call a barrage.",
			"map": "bridges", "map_seed": 23, "persona": "dug_in", "abilities": ["rally", "barrage"],
			"player": [[K.SWORDS, 1], [K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CANNONS, 0], [K.CANNONS, 0]],
			"enemy": [[K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 1], [K.PIKES, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CANNONS, 0], [K.CAVALRY, 0]],
			"deadline": 300.0, "hold_needed": 2,
			## Flag 0 is the field between them, flags 1 and 2 the bridges.
			"deadline_flags": [1, 2],
			"stars": [{"time": 200.0}, {"losses": 0.35}],
		},
		{
			"id": "riders", "era": "medieval", "name": "Riders at Dawn",
			"brief": "Their horse will come early and from everywhere. Keep your pikes facing it and your bows behind them.",
			"map": "ridge", "map_seed": 5, "persona": "aggressive",
			"player": [[K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 1], [K.PIKES, 0], [K.SWORDS, 0], [K.ARCHERS, 0], [K.ARCHERS, 0]],
			"enemy": [[K.CAVALRY, 0], [K.CAVALRY, 0], [K.CAVALRY, 0], [K.SWORDS, 0]],
			"stars": [{"time": 150.0}, {"losses": 0.35}],
		},
	],
}
