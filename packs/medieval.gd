class_name PackMedieval
extends RefCounted
## Quick battles with swords, pikes, bows, horse and guns.

const K := UnitTypes.Kind

## The fields, drawn by hand (Terrain.from_plan). The player deploys along
## the bottom edge, foot at y 670 and archers at 720; the enemy along the
## top, foot at 150. This era runs at pace 1.

## Hold the Fords. Three fords 68 wide and 450 apart, a flag on each,
## the player's from the start. The river is 230 from their foot's start
## line and 290 from the player's: both reach the fords in about eight
## seconds, so a block sent to each is on its flag as they wade. A flag
## changes hands only when one side stands on it alone, and a block 450
## from the next ford is 15 seconds from helping there or being helped.
const HOLD := {
	"id": "hold",
	"river": [Vector2(-10, 380), Vector2(1310, 380)],
	"crossings": [{"x": 200.0}, {"x": 650.0}, {"x": 1100.0}],
	"roads": [
		[Vector2(200, 830), Vector2(200, 380), Vector2(230, -10)],
		[Vector2(650, 830), Vector2(650, 380), Vector2(650, -10)],
		[Vector2(1100, 830), Vector2(1100, 380), Vector2(1070, -10)],
	],
	"flags": [
		{"name": "West Ford", "at": Vector2(200, 380)},
		{"name": "Middle Ford", "at": Vector2(650, 380)},
		{"name": "East Ford", "at": Vector2(1100, 380)},
	],
}

## Two Narrow Bridges. Two bridges 440 apart, each 32 wide, with houses at
## their far ends that halve arrows from the near bank and stop no
## cannonball. Gun Hill is 170 south of the west bridge, where the guns
## unlimber: from it they reach 537, which covers the west bridge's guard
## and their gun, 474 away behind the Meadow, whose own reach is 430. The
## east bridge has no hill: guns behind it reach 430, and theirs are 472
## away.
const BRIDGES := {
	"id": "bridges",
	"river": [Vector2(-10, 395), Vector2(430, 405), Vector2(650, 385), Vector2(870, 405), Vector2(1310, 395)],
	"crossings": [{"x": 430.0, "bridge": true}, {"x": 870.0, "bridge": true}],
	"hills": [{"c": Vector2(430, 575), "r": 110.0}],
	"towns": [
		[Vector2(370, 300), Vector2(490, 300), Vector2(490, 385), Vector2(370, 385)],
		[Vector2(810, 300), Vector2(930, 300), Vector2(930, 385), Vector2(810, 385)],
	],
	"roads": [
		[Vector2(430, 830), Vector2(430, 385)],
		[Vector2(430, 300), Vector2(450, -10)],
		[Vector2(870, 830), Vector2(870, 385)],
		[Vector2(870, 300), Vector2(850, -10)],
		[Vector2(490, 330), Vector2(650, 325), Vector2(810, 330)],
	],
	"flags": [
		{"name": "The Meadow", "at": Vector2(650, 325)},
		{"name": "West Bridge", "at": Vector2(430, 403)},
		{"name": "East Bridge", "at": Vector2(870, 403)},
	],
}

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
			"brief": "The three fords are yours. Put a block on each and stay there: still hold one when the clock runs out.",
			"plan": HOLD, "persona": "aggressive",
			"player": [[K.SWORDS, 1], [K.SWORDS, 0], [K.PIKES, 1], [K.ARCHERS, 0], [K.ARCHERS, 0]],
			"enemy": [[K.SWORDS, 0], [K.SWORDS, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CAVALRY, 0]],
			"deadline": 180.0, "hold_needed": 1, "own_flags": [0, 1, 2],
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
			"brief": "Take both bridges before dusk. Force the west one first: your guns on the hill cover it, and you can call a barrage.",
			"plan": BRIDGES, "persona": "dug_in", "abilities": ["rally", "barrage"],
			"goal": "Hold both bridges when the clock reaches 5:00, or break their army first.",
			"player": [[K.SWORDS, 1], [K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CANNONS, 0], [K.CANNONS, 0]],
			"enemy": [[K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 1], [K.PIKES, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CANNONS, 0], [K.CAVALRY, 0]],
			"deadline": 300.0, "hold_needed": 2, "flag_drain": 0.3,
			## Flag 0 is the meadow between them, flags 1 and 2 the bridges.
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
