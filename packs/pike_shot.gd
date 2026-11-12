class_name PackPikeShot
extends RefCounted
## Quick battles of pike blocks and musket volleys, horse and guns.

const K := UnitTypes.Kind

## The fields, drawn by hand (Terrain.from_plan). The player deploys along
## the bottom edge, pikes at y 670, shot at 720 and horse on the wings; the
## enemy along the top, pikes at 150. This era runs at pace 1: a volley
## does its full damage, and a meeting of pike blocks is over in seconds.

## The Cuirassiers. One flag, 180 north of the middle ford, so their three
## pike blocks stand side by side across it, 120 apart, the shot 75 behind
## them and the guns 170 behind the flag. Whoever leaves the middle ford,
## 143 from the flag, is inside the 220 at which their pikes go for him,
## and inside the guns' 430. The outer fords are 540 either side: 643 from
## the guns and 440 from the nearest pike block, so horse crosses there out
## of every reach and comes in behind the pikes, onto the shot.
const CUIRASSIERS := {
	"id": "cuirassiers",
	"river": [Vector2(-10, 450), Vector2(650, 450), Vector2(1310, 450)],
	"crossings": [{"x": 110.0}, {"x": 650.0}, {"x": 1190.0}],
	"roads": [
		[Vector2(650, 830), Vector2(650, 270), Vector2(650, -10)],
	],
	"flags": [
		{"name": "The Crossroads", "at": Vector2(650, 270)},
	],
}

## Shot at the Fords. Each flag is 170 south of the river, a musket's
## reach: shot on the flags reaches the middle of the fords, and shot on the
## far bank, 37 back from the water, is 207 from the flags. To fire, theirs
## must wade, by three fords 68 wide.
const FORDS_SHOT := {
	"id": "fords_shot",
	"river": [Vector2(-10, 330), Vector2(1310, 330)],
	"crossings": [{"x": 200.0}, {"x": 650.0}, {"x": 1100.0}],
	"roads": [
		[Vector2(200, 830), Vector2(200, 500), Vector2(200, 330), Vector2(230, -10)],
		[Vector2(650, 830), Vector2(650, 500), Vector2(650, 330), Vector2(650, -10)],
		[Vector2(1100, 830), Vector2(1100, 500), Vector2(1100, 330), Vector2(1070, -10)],
	],
	"flags": [
		{"name": "West Ford Road", "at": Vector2(200, 500)},
		{"name": "Middle Ford Road", "at": Vector2(650, 500)},
		{"name": "East Ford Road", "at": Vector2(1100, 500)},
	],
}

## The Great Battery. Their guns unlimber on the hill, 170 behind the
## battery's flag, and reach 430 and a quarter more for the height: 537,
## which is 3 short of the pikes' start line. The lane flags are 658 from
## the guns and 573 from the battery's flag. Their general sends a pike
## block to each flag, so one block stands before the guns and the other
## two are 21 seconds' march away; the battery's flag is 370 from the start
## line, 14 seconds for pikes.
const BATTERY := {
	"id": "battery",
	"hills": [{"c": Vector2(650, 130), "r": 130.0}],
	"roads": [
		[Vector2(650, 830), Vector2(650, 300), Vector2(650, -10)],
		[Vector2(120, 830), Vector2(120, 520), Vector2(140, -10)],
		[Vector2(1180, 830), Vector2(1180, 520), Vector2(1160, -10)],
	],
	"flags": [
		{"name": "West Lane", "at": Vector2(120, 520)},
		{"name": "The Great Battery", "at": Vector2(650, 300)},
		{"name": "East Lane", "at": Vector2(1180, 520)},
	],
}

## Push of Pike. Three flags on the lane, the same march from both lines,
## and a rise 140 behind them on the player's side. Shot on its crest
## reaches 170 and a quarter more: 212, which is 72 past the flags. Their
## shot stands 75 behind their pikes: with their pikes on the flags it is
## 215 from the crest and reaches 170. Pikes go for what is within 220, so
## theirs leave the flags and climb at shot on the crest, under its fire.
const PUSH := {
	"id": "push",
	"ridges": [{"line": [Vector2(250, 540), Vector2(1050, 540)], "r": 110.0}],
	"roads": [
		[Vector2(650, 830), Vector2(650, 400), Vector2(650, -10)],
		[Vector2(-10, 410), Vector2(400, 400), Vector2(650, 400), Vector2(900, 400), Vector2(1310, 410)],
	],
	"flags": [
		{"name": "West Field", "at": Vector2(400, 400)},
		{"name": "The Crossroads", "at": Vector2(650, 400)},
		{"name": "East Field", "at": Vector2(900, 400)},
	],
}

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
			"brief": "Stand your pike and shot on the rise behind the lane. Let the muskets thin their blocks as they climb, then push.",
			"plan": PUSH, "persona": "balanced",
			"player": [[K.PIKES, 1], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CAVALRY, 0], [K.CANNONS, 0]],
			"enemy": [[K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CAVALRY, 0]],
			"stars": [{"time": 180.0}, {"losses": 0.35}],
		},
		{
			"id": "fords_shot", "era": "pike_shot", "name": "Shot at the Fords",
			"brief": "Stand a musket's reach back from the three fords: their pikes must wade into your volleys.",
			"plan": FORDS_SHOT, "persona": "aggressive",
			"player": [[K.MUSKETS, 1], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 0]],
			"enemy": [[K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.CAVALRY, 0]],
			"goal": "Hold one of the three flags when the clock reaches 3:00, or break their army first.",
			"deadline": 180.0, "hold_needed": 1, "own_flags": [0, 1, 2],
			"stars": [{"flags": 2, "noun": "flags"}, {"losses": 0.4}],
		},
		{
			"id": "cuirassiers", "era": "pike_shot", "name": "The Cuirassiers",
			"brief": "Their pikes hold the middle ford, their shot behind them. Ride round by an outer ford and the shot cannot stop you.",
			"plan": CUIRASSIERS, "persona": "dug_in",
			"player": [[K.CAVALRY, 1], [K.CAVALRY, 0], [K.CAVALRY, 0], [K.CAVALRY, 0], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0]],
			"enemy": [[K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CAVALRY, 0]],
			"stars": [{"time": 150.0}, {"losses": 0.35}],
		},
		{
			"id": "battery", "era": "pike_shot", "name": "The Great Battery",
			"brief": "Three batteries hold the hill, and their pikes are spread to the lanes. Cross the open ground at once, all together.",
			"plan": BATTERY, "persona": "dug_in", "abilities": ["rally", "barrage"],
			"player": [[K.PIKES, 1], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CAVALRY, 0]],
			"enemy": [[K.PIKES, 0], [K.PIKES, 0], [K.PIKES, 1], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CANNONS, 1], [K.CAVALRY, 0]],
			"stars": [{"time": 240.0}, {"losses": 0.4}],
		},
	],
}
