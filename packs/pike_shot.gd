class_name PackPikeShot
extends RefCounted
## Quick battles of pike blocks and musket volleys, horse and guns.

const K := UnitTypes.Kind

const PACK := {
	"id": "pike_shot", "name": "Pike and Shot", "menu": "quick",
	"modules": [],
	"era": {
		"id": "pike_shot", "name": "Pike and Shot",
		"draw": [K.PIKES, K.PIKES, K.MUSKETS, K.MUSKETS, K.CAVALRY, K.CANNONS],
	},
	"scenarios": [
		{
			"id": "skirmish_shot", "era": "pike_shot", "name": "Skirmish",
			"brief": "Pike, shot, horse and guns, the same on both sides, on a new field each time.",
			"map": "random", "persona": "balanced",
			"stars": [{"time": 180.0}, {"losses": 0.35}],
		},
		{
			"id": "push", "era": "pike_shot", "name": "Push of Pike",
			"brief": "Two armies of pike and shot. Let your muskets thin their blocks before the pikes meet.",
			"map": "roads", "map_seed": 13, "persona": "balanced",
			"player": [[K.PIKES, 1], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CAVALRY, 0], [K.CANNONS, 0]],
			"enemy": [[K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CAVALRY, 0]],
			"stars": [{"time": 180.0}, {"losses": 0.35}],
		},
		{
			"id": "fords_shot", "era": "pike_shot", "name": "Shot at the Fords",
			"brief": "Your muskets hold the fords. Their pikes must wade to reach you, and every volley shakes them.",
			"map": "fords", "map_seed": 17, "persona": "aggressive",
			"player": [[K.MUSKETS, 1], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 0]],
			"enemy": [[K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.CAVALRY, 0]],
			"deadline": 180.0, "hold_needed": 1, "own_flags": [0, 1, 2], "deploy_depth": 370.0,
			"stars": [{"flags": 2}, {"losses": 0.4}],
		},
		{
			"id": "cuirassiers", "era": "pike_shot", "name": "The Cuirassiers",
			"brief": "Their shot stands behind their pikes. Ride round the pikes and the shot cannot stop you.",
			"map": "roads", "map_seed": 31, "persona": "dug_in",
			"player": [[K.CAVALRY, 1], [K.CAVALRY, 0], [K.CAVALRY, 0], [K.CAVALRY, 0], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0]],
			"enemy": [[K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CAVALRY, 0]],
			"stars": [{"time": 150.0}, {"losses": 0.35}],
		},
		{
			"id": "battery", "era": "pike_shot", "name": "The Great Battery",
			"brief": "Three batteries hold the ridge. Cross the open ground quickly and take the guns from the side.",
			"map": "ridge", "map_seed": 9, "persona": "dug_in", "abilities": ["rally", "barrage"],
			"player": [[K.PIKES, 1], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CAVALRY, 0]],
			"enemy": [[K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 1], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CANNONS, 1], [K.CAVALRY, 0]],
			"stars": [{"time": 240.0}, {"losses": 0.4}],
		},
	],
}
