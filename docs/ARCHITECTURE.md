# Fordline — architecture

How the game grows without breaking: a core engine, a few modules that add
whole mechanics, and packs of content. Every module and pack is a two-way
door: take it out and everything else plays exactly as before. The suite
checks that against recorded battles on every run.

This is the design, written before the code moves. The migration at the
end says how the code gets here, one reversible step at a time.

## The rules

1. **The core engine plays the first game.** The campaign and the open-field
   quick battles of both eras need no module.
2. **Dormant rules are core; whole mechanics are modules.** A rule that
   data switches on stays in the core and costs nothing when off: a unit
   trait (line infantry forms square), a schedule (forces arriving at an
   hour), a number (pace, how much a rout costs), a field bigger than the
   screen (the camera follows). A mechanic that brings its own state,
   orders, AI behaviour and things on screen is a module: fortifications
   today, the command layer for collaborative generals next.
3. **Packs are data.** Scenarios, maps and eras live in packs. A pack lists
   the modules it needs and loads no code.
4. **One writer.** Only the battle's step changes battle state. A module's
   sim code runs only when the battle calls it, and writes only its own
   state (on `battle.ext`) and core state through the battle's own
   functions.
5. **Fail when the battle is built.** A pack whose module is not loaded, a
   map kind or scenario key nothing provides, or a commander missing a
   method a module needs: each is an error when the battle is built. The
   suite builds every scenario.
6. **A hook is added when a module needs it**, with a test showing the core
   unchanged.

## The layers

```
  packs     campaign · medieval · pike_shot · sieges · gettysburg · waterloo
                │          │          │          │          │          │
  modules       ·          ·          ·   fortifications    ·          ·
                                         (command, strategy, map_layers … later)
                │          │          │          │          │          │
  core      battle · regiment · combat · terrain · ai · seats · screen · hud
```

Dependencies point down only. The core never names a module. A module uses
the core and the modules it lists. A pack names modules by id.

## The core

The battle and its step, regiments, combat, morale, flags and resolve; the
terrain queries; seeded maps (rivers, fords, bridges, hills, woods, roads)
and hand-drawn ones (ridges, towns, streams); the AI commander; the
campaign; rally, barrage and forced march; and the screen: tap, the arrow
drag, pause, speed, the HUD.

Dormant until data asks for them:

- **Formation shape.** A regiment is in line or in square. Kinds with the
  `square` trait form square against horse; the geometry (width, depth,
  reach, slots) reads the shape, so nothing outside the regiment needs to
  know. Today only line infantry has the trait.
- **Arrivals.** A scenario may list forces that come on by road at an
  hour.
- **Orders from above.** A regiment may carry a division, objectives and
  an hour before which it holds; the AI reads them, and they are empty in
  every quick battle.
- **Fire at a place.** Guns may be ordered to fire at a point rather than
  a regiment. Fortifications uses this to batter gates; barrage and air
  strikes are the same idea.
- **Seats.** The screen runs a list of seats, each a commander (the player
  or an AI) over some of a side's regiments. A quick battle has two: you,
  and the enemy AI. A division sent off on its own command is a third.
  Collaborative generals are more of the same.
- **The camera and the clock.** The field pans and zooms, with a minimap,
  only when it is bigger than the screen. The clock shows an hour of the
  day only when the scenario gives a starting hour.
- **Rule numbers**: `pace`, `rout_scale`, `flag_drain`, `dusk_time`,
  `deadline`, `deadline_flags`, `veterancy`.

## Modules

A module is a folder, `modules/<id>/`, whose `module.gd` extends `Module`,
listed once in `modules/registry.gd`. Today there is one, and the next two
are designed:

| Module | Adds | Needs |
|---|---|---|
| `fortifications` | castles as a map kind: walls, gates, the moat; ramming, bombarding, the garrison | — |
| `command` (next) | sending divisions off on their own command, allied generals' seats, dispatches | — |
| `strategy` (later) | a plan layer: set every division's objectives on a map of the field | `command` |
| `map_layers` (later) | overlays you switch on: ground, sight lines, coverage | — |
| `air`, `supply` (later) | air strikes and anti-air coverage; supply lines from depots | `map_layers` |

## The module contract

```gdscript
class_name Module
extends RefCounted
## A whole mechanic the core does not have. Every hook has a default that
## does nothing, so a module fills in only what it needs.

var id := ""
var requires: Array[String] = []       # other modules, by id
var map_kinds: Array[String] = []      # map kinds it can build ("fortress")
var spec_keys: Array[String] = []      # scenario keys it owns
```

Every hook below exists because fortifications or command needs it. Each
runs at the place in the step the code runs today, so no recorded battle
moves.

**Building a battle**

| Hook | Purpose |
|---|---|
| `make_map(kind, rng) -> Terrain` | build a map kind it provides (the castle's ground, walls and flags) |
| `make_state(spec, battle) -> Variant` | its own state, kept at `battle.ext[id]` (the gates' strength) |

A map a module builds carries `TerrainFeature`s: objects the core terrain
queries ask about height, cover, speed, water, blocking, walls between two
points and routes, and that draw themselves. The core's terrain view,
briefing preview and minimap all draw features, so a castle shows
everywhere without them knowing it is a castle. A map with no features
answers from the core alone, as it does now.

**The step** (the battle calls these)

| Hook | Where | Purpose |
|---|---|---|
| `apply_order(battle, order) -> bool` | orders | an order type it owns ("bombard") |
| `on_order(battle, order)` | orders | any order was given (a new move ends a bombardment) |
| `after_melee(battle, dt)` | between melee and fatigue | ramming |
| `on_landed(battle, hit)` | when a ball or shell lands | gate damage |

**The AI** (the core commander calls these for each regiment, in registry
order, before the regiment's own role)

| Hook | Purpose |
|---|---|
| `ai_context(battle, team, ctx)` | change what the whole side wants (a garrison forms across its gate) |
| `ai_order(battle, team, r, ctx) -> Variant` | an order, `Module.PASS` (let the role decide) or `Module.HOLD` (no order) |

**The screen** (the screen calls these; the battle never does)

| Hook | Purpose |
|---|---|
| `on_tap(screen, at) -> bool` | a tap on empty field it takes (a gate; a flag, for command) |
| `react(screen, event)` | effects and notices for its events |
| `draw_marks(view, battle)` | marks over the regiments (a gate's damage; a division's own-command diamond) |
| `describe(battle, r) -> String` | its words in the selection readout |

Thirteen hooks in all, counting the terrain feature's queries as one.

**Per-regiment state.** A module keeps what it knows about a regiment in its
own state, keyed by regiment id (which gate a battery is battering), not in
fields on `Regiment`. `Regiment` holds only core data.

**Random numbers.** Modules draw from the battle's generator, like the core.
A module only runs in battles whose pack lists it, so it can never shift the
dice of a battle that doesn't use it.

## Commanders and interfaces

A commander turns a battle into orders for one seat. The core AI is one,
and it runs every module's AI hooks before its own roles, so a commander
built on it serves every module without knowing they exist.

A module that needs something only a commander can do lists the methods:

```gdscript
var commander_methods: Array[String] = ["plan"]   # strategy, when it comes
```

When a battle is built, every commander in a seat that module governs is
checked with `has_method`, and a missing one is an error naming the
commander, the module and the method. A module should also ship a default
(the strategy module's default plan is the scenario's historical one) so
that a commander can take an army seat without writing a planner. The
suite builds every scenario with every commander, so a missing method fails
there.

## Packs

```gdscript
const PACK := {
	"id": "sieges", "name": "Sieges", "menu": "quick",
	"modules": ["fortifications"],
	"scenarios": [STORM, LAST_KEEP, BREACH],
}
```

`menu` says where its scenarios appear (the campaign, quick battle by era,
or grand battles). A scenario may use core keys and its modules' keys; its
map kind must be a core one or one its modules provide. Anything else is an
error naming the key. If a pack's module is not loaded, the pack is left
out of the menus and the suite says so.

## Staying stable

- **Recorded battles.** The suite fights fixed battles computer against
  computer: the campaign on three seeds, every quick scenario, the sieges,
  and Gettysburg and Waterloo through the whole day. It compares each
  winner, time, losses and flags with `tests/golden.txt`. A change that
  moves any of them fails until the file is updated in the same commit, so
  every balance change is a visible, deliberate diff.
- **Modules can't leak.** The core battles are fought twice: with no module
  registered, and with every module registered. Both must match the
  recording.
- **Every scenario is built** with its pack's modules and every commander.
- **Each module tests itself** in `modules/<id>/test.gd`.

## Migration

Each step is one commit that keeps every check and every recorded battle
the same, and can be reverted alone.

1. **Record the battles** and add the comparison to the suite. No code
   moves.
2. **Make the dormant rules core and data-driven.** Formation shape on
   regiment, read by its geometry. The `square` trait instead of checking
   for line infantry. Fire at a place. Seats in the screen. One way to
   write held flags (`own_flags` is a list in every spec, not sometimes a
   flag).
3. **The contract**: `Module`, `TerrainFeature`, the registry, map kinds,
   the hook calls (empty loops), the build-time checks, the no-module and
   every-module runs.
4. **Fortifications** out of the core: its map kind and features, gate
   state on `battle.ext`, bombard as fire at a place, ramming and gate
   damage behind the step hooks, the garrison behind the AI hooks, the gate
   tap and gate marks behind the screen hooks.
5. **Packs**: scenarios and eras into pack files; the menus and the
   briefing read packs.
6. **Command** as a module: the own-command tap, its seat, its marks and
   words.

After that, new mechanics start as modules. The steps all touch the same
core files, so they run one after another in one session.

## Kinds

Unit kinds are core data in one list, and saved campaigns store them by
number. When a pack needs to add a kind without code, kinds become data
with a role (foot, shot, horse, guns, general) and traits, and saves store
them by name with a one-time conversion. Until then this waits.
