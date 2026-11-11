class_name PackLineSquare
extends RefCounted
## Quick battles of line infantry, horse and guns: the line forms square
## when horse comes, and a square fires at half.

const K := UnitTypes.Kind

const PACK := {
	"id": "line_square", "name": "Line and Square", "menu": "quick",
	"modules": [],
	"era": {
		"id": "line_square", "name": "Line and Square",
		"draw": [K.LINE, K.LINE, K.LINE, K.CAVALRY, K.CANNONS],
		"pace": 0.4,
	},
	"scenarios": [
		{
			"id": "skirmish_line", "era": "line_square", "name": "Skirmish",
			"brief": "Line, horse and guns, the same on both sides, on a new field each time.",
			"map": "random", "persona": "balanced",
			"stars": [{"time": 180.0}, {"losses": 0.35}],
		},
		{
			"id": "receive", "era": "line_square", "name": "Receive Cavalry",
			"brief": "Their horse comes for your line. Stand and it forms square; their guns hunt squares, so know when to break it.",
			"map": "ridge", "map_seed": 19, "persona": "aggressive",
			"player": [[K.LINE, 1], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.CANNONS, 0]],
			"enemy": [[K.CAVALRY, 0], [K.CAVALRY, 0], [K.CAVALRY, 0], [K.CAVALRY, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CANNONS, 0]],
			"stars": [{"time": 180.0}, {"losses": 0.35}],
		},
		{
			"id": "horse_guns", "era": "line_square", "name": "Horse and Guns",
			"brief": "Their line holds the roads. Show it your horse and it forms square, and a square fires at half: then bring up the guns.",
			"map": "roads", "map_seed": 37, "persona": "balanced",
			"player": [[K.CAVALRY, 1], [K.CAVALRY, 0], [K.CAVALRY, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0]],
			"enemy": [[K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.CAVALRY, 0]],
			"stars": [{"time": 180.0}, {"losses": 0.35}],
		},
		{
			"id": "fords_line", "era": "line_square", "name": "Line at the Fords",
			"brief": "The fords are yours. Their line must wade to reach you, and their horse will try to make you form square first.",
			"map": "fords", "map_seed": 43, "persona": "aggressive",
			"player": [[K.LINE, 1], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.CANNONS, 0]],
			"enemy": [[K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.CAVALRY, 0], [K.CAVALRY, 0]],
			"deadline": 180.0, "hold_needed": 1, "own_flags": [0, 1, 2], "deploy_depth": 370.0,
			"stars": [{"flags": 2}, {"losses": 0.4}],
		},
		{
			"id": "bridge_dawn", "era": "line_square", "name": "The Bridge at Dawn",
			"brief": "Take both bridges before the clock runs out. Get your horse over the water: their line will stand in square, firing at half.",
			"map": "bridges", "map_seed": 29, "persona": "dug_in", "abilities": ["rally", "barrage"],
			"player": [[K.LINE, 1], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CAVALRY, 0]],
			"enemy": [[K.LINE, 0], [K.LINE, 0], [K.LINE, 1], [K.LINE, 0], [K.LINE, 0], [K.CANNONS, 0], [K.CANNONS, 0]],
			"deadline": 300.0, "hold_needed": 2,
			## Flag 0 is the field between them, flags 1 and 2 the bridges.
			"deadline_flags": [1, 2],
			"stars": [{"time": 200.0}, {"losses": 0.35}],
		},
	],
}
