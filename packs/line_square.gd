class_name PackLineSquare
extends RefCounted
## Quick battles of line infantry, horse and guns: the line forms square
## when horse comes, and a square fires at half.

const K := UnitTypes.Kind

## The fields, drawn by hand (Terrain.from_plan). The player deploys along
## the bottom edge, the line at y 720; the enemy along the top, at 100.

## Receive Cavalry. Their guns unlimber 170 behind the Crossroads and reach
## 430: to y 665. The low ridge the line starts on is at 715. Their general
## keeps their camp, so its flag is theirs until he is driven off it.
const RECEIVE := {
	"id": "receive",
	"ridges": [{"line": [Vector2(250, 715), Vector2(1050, 715)], "r": 70.0}],
	"roads": [
		[Vector2(650, 830), Vector2(650, 405), Vector2(650, -10)],
		[Vector2(-10, 440), Vector2(330, 425), Vector2(650, 405), Vector2(970, 425), Vector2(1310, 440)],
	],
	"flags": [
		{"name": "Mill Lane", "at": Vector2(330, 425)},
		{"name": "The Crossroads", "at": Vector2(650, 405)},
		{"name": "Abbey Lane", "at": Vector2(970, 425)},
		{"name": "Their Camp", "at": Vector2(650, 100)},
	],
}

## Horse and Guns. Their line holds three flags on the lane, 250 apart,
## the middle one among houses, which halve musketry and stop no cannonball.
## There are 400 of open ground beyond either end: room for horse to stand
## 240 from a block and outside its muskets' 170.
const HORSE_GUNS := {
	"id": "horse_guns",
	"hills": [{"c": Vector2(650, 490), "r": 120.0}],
	"towns": [
		[Vector2(585, 240), Vector2(715, 240), Vector2(720, 350), Vector2(580, 350)],
	],
	"roads": [
		[Vector2(400, 830), Vector2(400, 300), Vector2(420, -10)],
		[Vector2(900, 830), Vector2(900, 300), Vector2(880, -10)],
		[Vector2(-10, 290), Vector2(400, 300), Vector2(580, 315)],
		[Vector2(720, 315), Vector2(900, 300), Vector2(1310, 290)],
	],
	"flags": [
		{"name": "West Road", "at": Vector2(400, 300)},
		{"name": "The Inn", "at": Vector2(650, 320)},
		{"name": "East Road", "at": Vector2(900, 300)},
	],
}

## Line at the Fords. Two fords 640 apart, and a flag 215 south of each:
## muskets on the far bank, 37 back from the water, are 252 from a line on
## the flags and reach 170, and horse there is past the 240 that calls a
## square.
const FORDS_LINE := {
	"id": "fords_line",
	"river": [Vector2(-10, 318), Vector2(330, 325), Vector2(650, 340), Vector2(970, 325), Vector2(1310, 318)],
	"crossings": [{"x": 330.0}, {"x": 970.0}],
	"forests": [
		{"c": Vector2(85, 85), "r": 55.0}, {"c": Vector2(140, 135), "r": 40.0},
		{"c": Vector2(1215, 745), "r": 50.0},
	],
	"roads": [
		[Vector2(330, 830), Vector2(330, 540), Vector2(330, 325), Vector2(350, -10)],
		[Vector2(970, 830), Vector2(970, 540), Vector2(970, 325), Vector2(950, -10)],
	],
	"flags": [
		{"name": "West Ford Road", "at": Vector2(330, 540)},
		{"name": "East Ford Road", "at": Vector2(970, 540)},
	],
}

## The Bridge at Dawn. Two bridges 440 apart, each 32 wide, with houses at
## their far ends that halve musketry from the near bank. A ford 320
## upstream of the west bridge is out of reach of the muskets at the bridge
## (170), and horse across it comes within 240 of them.
const BRIDGE_DAWN := {
	"id": "bridge_dawn",
	"river": [Vector2(-10, 395), Vector2(110, 395), Vector2(430, 405), Vector2(650, 385), Vector2(870, 405), Vector2(1310, 395)],
	"crossings": [{"x": 110.0}, {"x": 430.0, "bridge": true}, {"x": 870.0, "bridge": true}],
	"forests": [
		{"c": Vector2(1150, 250), "r": 55.0}, {"c": Vector2(1200, 290), "r": 45.0},
		{"c": Vector2(250, 640), "r": 50.0}, {"c": Vector2(200, 600), "r": 45.0},
	],
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
		[Vector2(110, 830), Vector2(110, 395), Vector2(370, 330)],
	],
	"flags": [
		{"name": "The Meadow", "at": Vector2(650, 325)},
		{"name": "West Bridge", "at": Vector2(430, 403)},
		{"name": "East Bridge", "at": Vector2(870, 403)},
	],
}

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
			"plan": RECEIVE, "persona": "aggressive",
			"player": [[K.LINE, 1], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.CANNONS, 0]],
			"enemy": [[K.CAVALRY, 0], [K.CAVALRY, 0], [K.CAVALRY, 0], [K.CAVALRY, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CANNONS, 0]],
			"stars": [{"time": 180.0}, {"losses": 0.35}],
		},
		{
			"id": "horse_guns", "era": "line_square", "name": "Horse and Guns",
			"brief": "Their line holds the roads. Show it your horse and it forms square, and a square fires at half: then bring up the guns.",
			"plan": HORSE_GUNS, "persona": "balanced",
			"player": [[K.CAVALRY, 1], [K.CAVALRY, 0], [K.CAVALRY, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0]],
			"enemy": [[K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.CAVALRY, 0]],
			"stars": [{"time": 180.0}, {"losses": 0.25}],
		},
		{
			"id": "fords_line", "era": "line_square", "name": "Line at the Fords",
			"brief": "Stand back from the two fords: their line must wade into your muskets, and their horse must cross to force a square.",
			"plan": FORDS_LINE, "persona": "aggressive",
			"player": [[K.LINE, 1], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.CANNONS, 0]],
			"enemy": [[K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.CAVALRY, 0], [K.CAVALRY, 0]],
			"goal": "Hold one of the two flags when the clock reaches 3:00, or break their army first.",
			"deadline": 180.0, "hold_needed": 1, "own_flags": [0, 1], "flag_drain": 0.25,
			"stars": [{"flags": 2, "noun": "flags"}, {"losses": 0.4}],
		},
		{
			"id": "bridge_dawn", "era": "line_square", "name": "The Bridge at Dawn",
			"brief": "Take both bridges before the clock runs out. Get your horse over the water: their line will stand in square, firing at half.",
			"plan": BRIDGE_DAWN, "persona": "dug_in", "abilities": ["rally", "barrage"],
			"goal": "Hold both bridges when the clock reaches 5:00, or break their army first.",
			"player": [[K.LINE, 1], [K.LINE, 0], [K.LINE, 0], [K.LINE, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CAVALRY, 0]],
			"enemy": [[K.LINE, 0], [K.LINE, 0], [K.LINE, 1], [K.LINE, 0], [K.LINE, 0], [K.CANNONS, 0], [K.CANNONS, 0]],
			"deadline": 300.0, "hold_needed": 2,
			## Flag 0 is the meadow between them, flags 1 and 2 the bridges.
			"deadline_flags": [1, 2],
			"stars": [{"time": 200.0}, {"losses": 0.35}],
		},
	],
}
