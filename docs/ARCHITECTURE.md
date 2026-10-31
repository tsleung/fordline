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
                     (command, strategy, map_layers, air, naval, supply … later)
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
- **Flights.** Everything fired is one thing in flight: arrows, shot,
  cannonballs, barrage shells today; mortar bombs, railgun rounds, drones
  and missiles later. A flight goes from a source to a regiment or a place
  and is described by a few values: speed (so flight time and warning),
  path (straight, arc or dive), whether it homes, its blast (radius,
  kills, shock), whether a landing ring and countdown show, and tags
  saying what can engage it in the air. Guns may fire at a place rather
  than a regiment; fortifications uses that to batter gates.
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
listed once in `modules/registry.gd`. Today there is one; the rest are
designed and wait for a pack that needs them:

| Module | Adds | Needs |
|---|---|---|
| `fortifications` | castles as a map kind: walls, gates, the moat; ramming, bombarding, the garrison | — |
| `command` (next) | sending divisions off on their own command, allied generals' seats, dispatches | — |
| `strategy` (later) | a plan layer: set every division's objectives on a map of the field | `command` |
| `map_layers` (later) | overlays you switch on: ground, sight lines, coverage | — |
| `air` (later) | drones and missiles, interceptors and anti-air, jamming, aircraft on missions; see Air below | — |
| `naval` (later) | ships as units on the water, coasts and shallows, landings, fire from the sea; see Navies below | — |
| `supply` (later) | supply lines from depots; out of supply, reloads and nerve suffer | `map_layers` |

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

Every hook below exists because fortifications or command needs it, except
`in_flight`, which air adds. Each runs at the place in the step the code
runs today, so no recorded battle moves.

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
| `in_flight(battle, dt)` | after flights move, before any lands | interception, drones steering (air) |
| `on_landed(battle, hit)` | when a flight lands | gate damage |

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

Fourteen hooks in all, counting the terrain feature's queries as one;
`in_flight` is added with the `air` module, not before (rule 6).

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
   for line infantry. Arrows, shot, balls and shells as one list of
   flights with their values, and guns firing at a place. Seats in the
   screen. One way to write held flags (`own_flags` is a list in every
   spec, not sometimes a flag).
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
with a role (foot, shot, horse, guns, general), traits and a look
(soldiers in a block, or a crew on a hull), and saves store them by name
with a one-time conversion. A modern era is that pack: drone
teams, anti-air, jammers, mortars and railguns are kinds with traits the
`air` module acts on. Until then this waits.

## Air: a worked example

How drones, missiles and interceptors would enter, to check the contract
before it is built. Drawn from the research in the owner's notebook
(`notes/wartech/`, `notes/ideas.md`, `notes/wta-game/`).

**Air is things in flight between ground units, never units in the air.**
Every drone, missile, shell and interceptor is fired from the ground at a
regiment or a place, flies, and lands or is stopped. Nothing in the air
holds a flag, and no aircraft fight each other. Every decision stays a
ground decision, and the one-tap orders stay enough:

- where your anti-air stands, since its reach is a ring on the map;
- how close your blocks stand, since massing is both firepower and a
  target;
- what to fire at what, and when to spend the expensive round;
- whether to be somewhere else when the countdown ends.

**Weapons are values, not special cases.** As `ideas.md` puts it, every
weapon sits on a few shared axes: speed, homing, area, whether it can be
shot down, warning time, cost. The counters follow from the numbers.

| In flight | Fired by | Speed and warning | Can be stopped by | Notes |
|---|---|---|---|---|
| shell | a gun, at a place, on or off the field | arc, seconds; landing ring | close-in guns and lasers, in range, at a rate | counter-battery finds the gun |
| mortar bomb | a mortar team, over cover | high arc, a few seconds; ring | the same | fires over houses and hills |
| railgun round | a railgun, straight | almost instant; no warning | nothing | long reload; the precise, narrow end |
| FPV drone | a drone team, at a regiment | slow (horse pace), homes | any block's guns close in, anti-air guns, interceptor drones; jamming | fibre-optic ones ignore jamming but keep within a ring of their team |
| loitering munition | a drone team, at an area | slow; waits for a target | the same | a decoy draws it off |
| one-way drone, cruise missile | off the field, from an edge | minutes in history, seconds in play; ring | interceptor drones, guns, missiles | comes in waves, with decoys |
| ballistic or hypersonic | off the field | fast; a second's warning or none | only the long-range tier, at a low rate | effectively unstoppable without that tier |

**Interception is a rate, not a roll.** An interceptor has a ring, the
tags it can engage, the fastest thing it can catch, how many flights it
can engage at once, how long each one takes, and a magazine. A flight it
can engage inside its ring is stopped once it has been engaged for that
long. Too many at once and the rest get through. So failure is
"I can't kill those fast enough", never "I can't kill that"
(`wta_game_concept.md`), saturation and decoys work by themselves, and the
dice stay out of it, which both the WTA findings and Fordline's own luck
study argue for. A slower interceptor catches a faster flight only while
it is still coming in, which puts pickets forward.

**Jamming is a zone.** Radio drones that fly into an enemy jammer's ring
drift and drop; your own falter in your own ring. Fibre drones are immune
and stay on their leash.

**Aircraft are flights that come back.** A drone or a missile is spent; a
sortie returns and rearms. Aircraft are a side's wings, each a resource
given a mission, as in Supreme Commander, where you direct the effort and
never fly the dogfight:

- **Strike** a place: the wing flies in from its edge, drops its munitions
  (flights of their own) and turns for home.
- **Cover** an area: the wing becomes a moving interceptor ring that
  engages only aircraft, at its rate.
- **Escort** a strike: its cover ring travels with it.

Who owns the sky is then whose rings are where, and it reads as shading on
the map: denied, contested, open. Over open sky a strike arrives quickly
and surely; through enemy rings each ring spends its rate on the sortie,
which may be turned back or lost, or must drop from outside the rings with
weapons that can themselves be shot down. Winning the air is a ground
decision: push your anti-air forward, or kill theirs to open the sky. A
grand battle can simply give the sky to one side as a scenario value: then
the other side's arrivals come slower by day, as German reserves did in
Normandy.

**Effects lean to nerve.** A strike costs more morale and stamina than men,
so air shapes where blocks will stand rather than deleting them; the WTA
siege showed air that removes a garrison makes the fight a walk.

**What it takes from the contract:** the core's flights (values and tags),
`in_flight` to steer, intercept and fly sorties, `on_landed` for what a
landing does, module state for magazines, wings and jammers, `ai_order` for
launchers and anti-air, `draw_marks` for rings, shading and countdowns,
`on_tap` to aim a strike or set a wing's mission. Kinds become data.
Nothing else.

**Left out on purpose:**
- Aircraft you steer, and dogfights. A wing is given a mission, not flown.
- Seeing and being seen. Reconnaissance drones and fog of war would be a
  `sensing` module, and a costly one: the WTA work kept an all-seeing map
  for legibility.
- Cost exchange as an economy. It is the scoreboard, not the fun
  (`ideas.md`). At most, magazines carry over between campaign battles.
- Real flight times. Warning is scaled to seconds of play: a grand battle's
  hour is 78 seconds.

## Navies: a worked example

**If it holds space, it is a unit; if it only passes through, it is a
flight.** Aircraft pass through, so they are flights. Ships hold water, so
they are units, commanded with the same one-tap orders as a regiment: tap
to select, tap to move, drag an arrow to stand and face, tap an enemy to
fire on it.

**Where they belong.** Battles where land and sea meet: a landing, a river
with gunboats, guns supporting the shore. A battle of fleets alone would be
a different game and is left out. First candidates in eras the game
already has: Vicksburg (river gunboats, with the rifles) and Quebec in 1759
(the landing below the cliffs and the battle on the Plains of Abraham, with
line infantry).

**What a ship is.** A kind with a domain: water instead of land. It moves
only on water, it has a lot of strength and turns slowly, and its look
comes from its kind: the core draws a hull under its crew, a dormant rule
like the square. Its weapons are flights like
everyone's: long guns that fire at a place for the shore; on later ships,
an escort's anti-air ring that moves with it, and a carrier's wings.

**The sea is three kinds of water and nothing else:** deep (any ship),
shallows (boats and landing craft only; a visible lighter colour) and the
coast. No currents, tides or wind (DESIGN.md, pillar 6).

**Landings are arrivals by sea.** A force comes in landing craft along a
sea lane instead of up a road, and becomes regiments on the beach it
reaches; craft hit on the way lose men, as anything does.

**What it takes.**
- From the core, as dormant rules: a domain on regiments (land unless a
  kind says water), so the terrain's blocking and speed answer for the
  regiment's domain; the hull look; and the grid router, which moves from
  fortifications to the core once a second user (the sea) needs it.
- From the contract: `make_map` for coastlines and shallows as terrain
  features; `ai_order` for ships (keep station, support the shore);
  `react` for their effects. Landings use the core's arrivals with a sea
  lane. Kinds become data. No new hook.

