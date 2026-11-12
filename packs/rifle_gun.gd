class_name PackRifleGun
extends RefCounted
## Quick battles of rifles, horse and guns: long reach, and ground that
## decides who can be hit.

const K := UnitTypes.Kind

## The fields, drawn by hand (Terrain.from_plan). The player deploys along
## the bottom edge, rifles at y 720; the enemy along the top, rifles at 100.

## Open Ground. Their line stands among the houses of Highfield, 500 wide
## along the crest, which halve fire from the open slope below; their guns
## unlimber 170 behind its flag and reach 430. East Wood's flag is 730 from
## the guns, inside trees that halve the fire of whoever comes to retake it.
const OPEN_GROUND := {
	"id": "open_ground",
	"ridges": [{"line": [Vector2(140, 240), Vector2(420, 223), Vector2(700, 235)], "r": 115.0}],
	"forests": [
		{"c": Vector2(1080, 450), "r": 90.0}, {"c": Vector2(1000, 480), "r": 70.0}, {"c": Vector2(1160, 470), "r": 70.0},
		{"c": Vector2(1060, 540), "r": 70.0}, {"c": Vector2(1150, 550), "r": 65.0}, {"c": Vector2(1090, 380), "r": 60.0},
		{"c": Vector2(1220, 520), "r": 55.0},
	],
	"towns": [[Vector2(220, 155), Vector2(720, 155), Vector2(725, 270), Vector2(215, 270)]],
	"roads": [
		[Vector2(470, 830), Vector2(480, 560), Vector2(470, 270)],
		[Vector2(470, 155), Vector2(500, -10)],
		[Vector2(725, 215), Vector2(900, 240), Vector2(1090, 260), Vector2(1310, 245)],
		[Vector2(-10, 215), Vector2(215, 212)],
	],
	"flags": [
		{"name": "Highfield", "at": Vector2(470, 225)},
		{"name": "East Wood", "at": Vector2(1080, 450)},
		{"name": "The Turnpike", "at": Vector2(1090, 260)},
	],
}

## Into the Trees. Three woods, each from y 420 to 630, with a flag in each
## at 470. The lines start 620 apart and stop to fire 218 apart, the
## player's slowed by the trees it enters first: moving at once it stands
## near 600, inside, and theirs near 380, 40 short of the trees. Whoever is
## inside is shot at half.
const TREES := {
	"id": "trees",
	"forests": [
		{"c": Vector2(205, 486), "r": 68.0}, {"c": Vector2(300, 482), "r": 64.0}, {"c": Vector2(392, 487), "r": 67.0},
		{"c": Vector2(210, 566), "r": 64.0}, {"c": Vector2(298, 568), "r": 62.0}, {"c": Vector2(390, 565), "r": 65.0},
		{"c": Vector2(558, 487), "r": 67.0}, {"c": Vector2(650, 482), "r": 64.0}, {"c": Vector2(744, 486), "r": 68.0},
		{"c": Vector2(560, 566), "r": 65.0}, {"c": Vector2(650, 568), "r": 62.0}, {"c": Vector2(742, 565), "r": 64.0},
		{"c": Vector2(908, 486), "r": 68.0}, {"c": Vector2(1000, 482), "r": 64.0}, {"c": Vector2(1094, 487), "r": 67.0},
		{"c": Vector2(910, 566), "r": 64.0}, {"c": Vector2(1000, 568), "r": 62.0}, {"c": Vector2(1092, 565), "r": 65.0},
	],
	"roads": [
		[Vector2(475, 830), Vector2(478, 510), Vector2(470, -10)],
		[Vector2(825, 830), Vector2(822, 510), Vector2(830, -10)],
	],
	"flags": [
		{"name": "West Wood", "at": Vector2(300, 470)},
		{"name": "Middle Wood", "at": Vector2(650, 470)},
		{"name": "East Wood", "at": Vector2(1000, 470)},
	],
}

## Shoot the Gunners. Their batteries unlimber 170 behind Battery Hill's
## flag, on the hill, and reach 430 and a quarter more for the height: both
## road flags, 490 away, which are 380 either side of the way up the middle.
## The gunners are 218 from a line 48 short of the hill's flag.
const GUNNERS := {
	"id": "gunners",
	"hills": [{"c": Vector2(650, 175), "r": 130.0}],
	"forests": [
		{"c": Vector2(75, 745), "r": 50.0}, {"c": Vector2(1225, 745), "r": 50.0},
	],
	"roads": [
		[Vector2(230, 830), Vector2(270, 470), Vector2(330, -10)],
		[Vector2(1070, 830), Vector2(1030, 470), Vector2(970, -10)],
		[Vector2(270, 470), Vector2(650, 330), Vector2(1030, 470)],
	],
	"flags": [
		{"name": "West Road", "at": Vector2(270, 470)},
		{"name": "Battery Hill", "at": Vector2(650, 330)},
		{"name": "East Road", "at": Vector2(1030, 470)},
	],
}

## Hold the Creek. Each flag is 250 south of the creek: rifles on the far
## bank, 37 back from the water, are 287 from a line on the flags and reach
## 230. To fire they must cross, by three fords 68 wide. The Mill's houses
## halve the fire of whoever shoots at the regiment holding it.
const CREEK := {
	"id": "creek",
	"river": [Vector2(-10, 275), Vector2(250, 275), Vector2(450, 289), Vector2(650, 295), Vector2(850, 289), Vector2(1050, 275), Vector2(1310, 275)],
	"crossings": [{"x": 180.0}, {"x": 650.0}, {"x": 1120.0}],
	"forests": [
		{"c": Vector2(70, 80), "r": 50.0}, {"c": Vector2(1230, 80), "r": 50.0},
		{"c": Vector2(80, 750), "r": 45.0}, {"c": Vector2(1220, 750), "r": 45.0},
	],
	"towns": [[Vector2(575, 500), Vector2(725, 500), Vector2(730, 592), Vector2(570, 592)]],
	"roads": [
		[Vector2(180, 830), Vector2(180, 525), Vector2(180, 275), Vector2(210, -10)],
		[Vector2(650, 830), Vector2(650, 592)],
		[Vector2(650, 500), Vector2(650, 295), Vector2(650, -10)],
		[Vector2(1120, 830), Vector2(1120, 525), Vector2(1120, 275), Vector2(1090, -10)],
	],
	"flags": [
		{"name": "West Ford Road", "at": Vector2(180, 525)},
		{"name": "The Mill", "at": Vector2(650, 545)},
		{"name": "East Ford Road", "at": Vector2(1120, 525)},
	],
}

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
			"plan": OPEN_GROUND, "persona": "dug_in",
			"player": [[K.RIFLES, 1], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0]],
			"enemy": [[K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.CANNONS, 0], [K.CANNONS, 0]],
			"stars": [{"time": 240.0}, {"losses": 0.4}],
		},
		{
			"id": "trees", "era": "rifle_gun", "name": "Into the Trees",
			"brief": "Trees halve the fire of whoever shoots into them. Get into the woods before they do.",
			"plan": TREES, "persona": "balanced",
			"player": [[K.RIFLES, 1], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.CAVALRY, 0], [K.CANNONS, 0]],
			"enemy": [[K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.CAVALRY, 0]],
			"stars": [{"time": 180.0}, {"losses": 0.35}],
		},
		{
			"id": "gunners", "era": "rifle_gun", "name": "Shoot the Gunners",
			"brief": "Four batteries hold the roads. A battery is twelve men: get within your rifles' reach and shoot the gunners.",
			"plan": GUNNERS, "persona": "dug_in",
			"player": [[K.RIFLES, 1], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.CAVALRY, 0]],
			"enemy": [[K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CANNONS, 0]],
			"stars": [{"time": 150.0}, {"losses": 0.35}],
		},
		{
			"id": "creek", "era": "rifle_gun", "name": "Hold the Creek",
			"brief": "Your flags stand 250 back from the creek, out of reach of the far bank. Hold there: their rifles must wade to you.",
			"plan": CREEK, "persona": "aggressive",
			"player": [[K.RIFLES, 1], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.CANNONS, 0]],
			"enemy": [[K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.RIFLES, 0], [K.CAVALRY, 0]],
			"goal": "Hold one of the three flags when the clock reaches 3:00, or break their army first.",
			"deadline": 180.0, "hold_needed": 1, "own_flags": [0, 1, 2], "flag_drain": 0.25,
			"stars": [{"flags": 2, "noun": "flags"}, {"losses": 0.4}],
		},
	],
}
