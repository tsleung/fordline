class_name PackSieges
extends RefCounted
## Castles: siege battles of both eras, listed under their era's tab.

const K := UnitTypes.Kind

const PACK := {
	"id": "sieges", "name": "Sieges", "menu": "quick",
	## "fortifications" here, once the castle is a module (ARCHITECTURE.md).
	"modules": [],
	"scenarios": [
		{
			"id": "storm", "era": "medieval", "name": "The Storming of Duskwatch",
			"brief": "A castle on the sea cliffs: a moat, a gatehouse, a walled keep. Batter in the gate, then the keep's, before dusk.",
			"map": "fortress", "map_seed": 3, "persona": "garrison", "abilities": ["rally", "barrage"],
			"player": [[K.SWORDS, 1], [K.SWORDS, 0], [K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 0], [K.PIKES, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CANNONS, 0], [K.CANNONS, 0]],
			"enemy": [[K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CAVALRY, 0]],
			"deadline": 360.0, "hold_needed": 2, "their_flags": [0, 1, 2], "flag_drain": 0.0,
			"goal": "Hold two of the castle's three flags at 6:00, or break the garrison.",
			"stars": [{"time": 240.0}, {"losses": 0.45}],
		},
		{
			"id": "last_keep", "era": "medieval", "name": "The Last Keep",
			"brief": "Now the castle is yours and a great host is at the gate. Man the walls; when the gate goes, hold the gateway.",
			"map": "fortress_held", "map_seed": 3, "persona": "aggressive",
			"player": [[K.SWORDS, 1], [K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 0], [K.ARCHERS, 1], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CANNONS, 0]],
			"enemy": [[K.SWORDS, 0], [K.SWORDS, 0], [K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 0], [K.PIKES, 0], [K.ARCHERS, 0], [K.ARCHERS, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CAVALRY, 0], [K.CAVALRY, 0]],
			"deadline": 300.0, "hold_needed": 1, "own_flags": [0, 1, 2], "flag_drain": 0.0,
			"goal": "Hold one of your three flags at 5:00, or break their army.",
			"stars": [{"flags": 3, "noun": "flags"}, {"losses": 0.4}],
		},
		{
			"id": "breach", "era": "pike_shot", "name": "The Breach at Greyhold",
			"brief": "Greyhold's walls were built for bows. Bring up the great guns, open the gate, and send the pikes through the smoke.",
			"map": "fortress", "map_seed": 11, "persona": "garrison", "abilities": ["rally", "barrage"],
			"player": [[K.PIKES, 1], [K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CANNONS, 0], [K.CAVALRY, 0]],
			"enemy": [[K.PIKES, 0], [K.PIKES, 0], [K.MUSKETS, 0], [K.MUSKETS, 0], [K.CANNONS, 0], [K.CAVALRY, 0]],
			"deadline": 360.0, "hold_needed": 2, "their_flags": [0, 1, 2], "flag_drain": 0.0,
			"goal": "Hold two of the castle's three flags at 6:00, or break the garrison.",
			"stars": [{"time": 240.0}, {"losses": 0.4}],
		},
	],
}
