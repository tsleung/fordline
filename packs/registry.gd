class_name Packs
extends RefCounted
## The content packs, listed here because a web build cannot scan folders.
## A pack is data: an id, where its scenarios appear ("quick": by era, on the
## quick battle list; "grand": on the grand battles list), the modules it
## needs, optionally an era of its own, and its scenarios.
##
## An era: id, name, and draw, the kinds a Skirmish of that era picks its
## army from (a kind listed twice comes up twice as often). Eras are listed
## oldest first.
##
## A scenario:
##   era: an era's id (a grand battle's names its period, for the record)
##   name / brief / goal: the words on its card and briefing; goal when the
##     generic one won't do
##   map / map_seed: the ground ("random" with no seed: Skirmish)
##   player / enemy: [kind, stars] for each regiment beside the general
##   persona: how the enemy fights
##   abilities: the player's (Rally if not given)
##   deadline / hold_needed: the battle ends on the flags at that time
##   deadline_flags: the flags that must be held at the deadline, by index,
##     when "any hold_needed flags" won't do
##   own_flags / their_flags: the flags each side starts holding, by index
##   flag_drain: resolve per second per flag of difference (sieges: 0)
##   deploy_depth: how far in from its edge the player may deploy
##   stars: the two stars beyond the win, each one condition: {"time": s} win
##     within s seconds; {"losses": f} lose at most that share of your men;
##     {"flags": n} hold at least n flags at the end; {"hold": i, "noun",
##     "verb"} hold flag i at the end
## A grand battle adds:
##   plan: its hand-drawn field (Terrain.from_plan); view: where the camera
##   opens; start_hour / hour: the day's clock; rout_scale, pace, veterancy:
##   rule numbers; start / arrivals: who holds the field, who comes by road.

const ALL := [
	PackMedieval.PACK,
	PackPikeShot.PACK,
	PackSieges.PACK,
	Gettysburg.PACK,
	Waterloo.PACK,
]


## Every pack's era, in pack order.
static func eras() -> Array:
	return ALL.filter(func(p): return p.has("era")).map(func(p): return p.era)


## The scenarios of the packs on `menu` ("quick" or "grand"), in pack order.
static func scenarios(menu: String) -> Array:
	var out: Array = []
	for p in ALL:
		if p.menu == menu:
			out.append_array(p.scenarios)
	return out
