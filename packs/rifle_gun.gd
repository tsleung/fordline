class_name PackRifleGun
extends RefCounted
## Quick battles of rifles, horse and guns: long reach, and ground that
## decides who can be hit.

const K := UnitTypes.Kind

const PACK := {
	"id": "rifle_gun", "name": "Rifle and Gun", "menu": "quick",
	"modules": [],
	"era": {
		"id": "rifle_gun", "name": "Rifle and Gun",
		"draw": [K.RIFLES, K.RIFLES, K.RIFLES, K.CAVALRY, K.CANNONS],
		"pace": 0.4,
	},
	"scenarios": [
		{
			"id": "skirmish_rifle", "era": "rifle_gun", "name": "Skirmish",
			"brief": "Rifles, horse and guns, the same on both sides, on a new field each time.",
			"map": "random", "persona": "balanced",
			"stars": [{"time": 180.0}, {"losses": 0.35}],
		},
		{
			"id": "open_ground", "era": "rifle_gun", "name": "Open Ground",
			"brief": "They are dug in on the ridge with guns, and rifles reach far. Walk straight at them and few will arrive: go round.",
			"map": "ridge", "map_seed": 21, "persona": "dug_in",
			"player": [[K.RIFLES, 1], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0]],
			"enemy": [[K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.CANNONS, 0], [K.CANNONS, 0]],
			"stars": [{"time": 240.0}, {"losses": 0.4}],
		},
		{
			"id": "trees", "era": "rifle_gun", "name": "Into the Trees",
			"brief": "Trees halve the fire of whoever shoots into them. Get into the woods before they do.",
			"map": "woods", "map_seed": 11, "persona": "balanced",
			"player": [[K.RIFLES, 1], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.CAVALRY, 0], [K.CANNONS, 0]],
			"enemy": [[K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.CAVALRY, 0]],
			"stars": [{"time": 180.0}, {"losses": 0.35}],
		},
		{
			"id": "gunners", "era": "rifle_gun", "name": "Shoot the Gunners",
			"brief": "Four batteries hold the roads. A battery is twelve men: get within your rifles' reach and shoot the gunners.",
			"map": "roads", "map_seed": 47, "persona": "dug_in",
			"player": [[K.RIFLES, 1], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.CAVALRY, 0]],
			"enemy": [[K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CANNONS, 0]],
			"stars": [{"time": 150.0}, {"losses": 0.35}],
		},
		{
			"id": "creek", "era": "rifle_gun", "name": "Hold the Creek",
			"brief": "The crossings are yours, and their rifles must wade to reach you. Still hold one when the clock runs out.",
			"map": "fords", "map_seed": 53, "persona": "aggressive",
			"player": [[K.RIFLES, 1], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.CANNONS, 0]],
			"enemy": [[K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.CAVALRY, 0]],
			"deadline": 180.0, "hold_needed": 1, "own_flags": [0, 1, 2], "deploy_depth": 370.0,
			"stars": [{"flags": 2}, {"losses": 0.4}],
		},
	],
}
