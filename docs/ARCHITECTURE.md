# Fordline — architecture

How the game grows without breaking: a core engine, a few modules that add
whole mechanics, and packs of content. Every module and pack is a two-way
door: take it out and everything else plays exactly as before. The suite
checks that against recorded battles on every run.

This is the design, written before the code moves. The migration at the
end says how the code gets here, one reversible step at a time.

## The rules

1. **The core engine plays the first game.** The campaign and the
   open-field quick battles of both eras need no module.
2. **Dormant rules are core; whole mechanics are modules.** A rule that
   data switches on stays in the core and costs nothing when off: a unit
   trait (line infantry forms square), a schedule (forces arriving at an
   hour), a number (pace, how much a rout costs), a field bigger than the
   screen (the camera follows). A mechanic that brings its own state,
   orders, AI behaviour and things on screen is a module: fortifications
   today, the command layer for collaborative generals next.
3. **Packs are data.** Scenarios, maps and eras live in packs: constants
   that name kinds, map kinds and modules by id and hold no functions.
4. **One writer, and modules return effects.** Only the battle's step
   changes battle state. A module's sim hooks are pure: given a read-only
   view of the battle and the module's own state, they return the module's
   next state and a list of effects (wound these men, blast this place,
   raise this force, emit this event), which the battle applies through its
   own functions.
5. **Fail when the battle is built, never silently.** A pack whose module
   is not loaded; a kind, map kind or scenario key nothing provides; a kind
   whose role no commander handles; two modules claiming one order or event
   type: each is an error when the battle is built. An order of an unknown
   type is an error when given. The suite builds every scenario.
6. **A hook is added when a module needs it**, with a test showing the core
   unchanged.
7. **One clock.** The battle advances in steps of `Battle.STEP` everywhere:
   on screen, in the suite and in the balance studies. A game measured at
   one step and played at another is a different game; see Migration.

## The layers

```
  packs     campaign · medieval · pike_shot · sieges · gettysburg · waterloo
                │          │          │          │          │          │
  modules       ·          ·          ·   fortifications    ·          ·
                          (command, air, naval, supply … later)
                │          │          │          │          │          │
  core      battle · regiment · kinds · combat · terrain · ai · seats
            · layers · screen · hud
```

Dependencies point down only. The core never names a module. A module uses
the core and the modules it lists. A pack names everything by id.

## The core

The battle and its step, regiments, kinds, combat, morale, flags and
resolve; the terrain queries; seeded maps (rivers, fords, bridges, hills,
woods, roads) and hand-drawn ones (ridges, towns, streams); the AI
commander; the campaign; rally, barrage and forced march; and the screen:
tap, the arrow drag, pause, speed, the HUD.

**Kinds are data.** A kind is an id ("pikes", "line"), its stats, a role
(foot, shot, archers, horse, guns, general), traits (`square`,
`bayonet`) and a look (soldiers in a block; later, a crew on a hull). The
AI and combat read roles and traits, never ids, so a pack can add a kind
with no code, and a role nothing handles fails at build time. Nothing to
convert: no campaign is saved between sessions today, only stars and the
best score.

**Seats and the commander loop.** One pure loop runs a battle: each seat (a
commander over some of a side's regiments) is asked for orders at its
interval, the orders are stamped with the step they belong to, and the
battle steps. The screen, the suite and the balance studies all use this
loop, so what is measured is what is played. A quick battle has two seats,
you and the enemy AI; a division on its own command is a third;
collaborative generals are more. Because orders are plain values stamped
with their step, a battle is its scenario, its seed and its order log:
enough to replay it, attach it to a bug report, or one day send it between
players.

**Each side has a home and its own abilities.** A side's home edge is
data, not "the bottom of the map", so a landing comes from the sea and a
strike from its own rear. Each side has its own abilities and cooldowns,
so an AI or an allied seat can call a barrage.

**Layers.** The core keeps a list of map layers, each a thing that draws
over the ground and can be switched on and off. With none registered, the
switch is hidden. Ground height, anti-air coverage and supply lines are
layers that modules add.

Dormant until data asks for them:

- **Formation shape.** A regiment is in line or in square. Kinds with the
  `square` trait form square against horse; the geometry (width, depth,
  reach, slots) reads the shape, so nothing outside the regiment needs to
  know.
- **Arrivals.** A scenario may list forces that come on by road at an hour.
- **Orders from above.** A regiment may carry a division, objectives and an
  hour before which it holds; the AI reads them, and they are empty in every
  quick battle.
- **Flights.** Everything fired is one thing in flight: arrows, shot,
  cannonballs, barrage shells. A flight has today's values (source, target
  regiment or place, duration, damage, shock, whether pace scales it) and
  an `ext` slot where a module keeps its own (homing, what can engage it, a
  landing ring). Guns may fire at a place rather than a regiment;
  fortifications uses that to batter gates.
- **The camera and the clock.** The field pans and zooms, with a minimap,
  only when it is bigger than the screen. The clock shows an hour of the
  day only when the scenario gives a starting hour.
- **Rule numbers**: `pace`, `rout_scale`, `flag_drain`, `dusk_time`,
  `deadline`, `deadline_flags`, `veterancy`.

**Dice.** The simulation's random numbers come from the battle's generator
and nothing else draws on it: the scatter of arrows on screen is seeded
from the flight, not the battle. Each module gets its own generator,
seeded from the battle's seed and the module's id, so adding a module to a
pack never reshuffles another's dice.

## Modules

A module is a folder, `modules/<id>/`, whose `module.gd` extends `Module`,
listed once in `modules/registry.gd`. Today there is one; the rest are
designed and wait for a pack that needs them:

| Module | Adds | Needs |
|---|---|---|
| `fortifications` | castles as a map kind: walls, gates, the moat; ramming, bombarding, the garrison | — |
| `command` (next) | sending divisions off on their own command, allied generals, dispatches | — |
| `air` (later) | drones and missiles, interceptors and anti-air, jamming, aircraft on missions; see Air below | — |
| `naval` (later) | ships as units on the water, coasts and shallows, landings, fire from the sea; see Navies below | — |
| `supply` (later) | supply lines from depots; out of supply, reloads and nerve suffer | — |

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
var orders: Array[String] = []         # order types, named "<id>.<type>"
var events: Array[String] = []         # event types, named the same way
var intro := ""                        # one line, shown the first time a player meets it
```

Each hook below exists because fortifications or command needs it, except
`in_flight`, `layers` and `actions`, which air adds. Each runs at the place
in the step the code runs today.

**Building a battle**

| Hook | Purpose |
|---|---|
| `make_map(kind, rng) -> Terrain` | build a map kind it provides (the castle's ground, walls and flags) |
| `make_state(spec) -> Variant` | its own starting state, kept at `battle.ext[id]` (the gates' strength) |

A map a module builds carries `TerrainFeature`s that the core terrain
queries ask, given the battle so a feature can read its module's state (a
gate that is down no longer walls). Each query says how features combine:
height takes the highest, cover and speed the lowest, blocking and walls
any. The core's terrain view, briefing preview and minimap all draw
features, so a castle shows everywhere without them knowing it is a
castle. A map with no features answers from the core alone, as it does
now.

**The step** (pure: each takes the module's state and a read-only view of
the battle, and returns the next state and effects)

| Hook | Where | Purpose |
|---|---|---|
| `apply_order(state, view, order)` | orders | an order type it owns ("fortifications.bombard") |
| `after_melee(state, view, dt)` | between melee and fatigue | ramming |
| `in_flight(state, view, dt)` | after flights move, before any lands | interception, drones steering (air) |
| `on_landed(state, view, hit)` | when a flight lands | gate damage |

The effects are a short fixed list the battle knows how to apply:
`wound`, `blast`, `morale`, `raise` (a force arrives), `order`, `launch`
(a flight), `event`. A module that needs a new kind of effect is adding a
hook (rule 6).

**The AI** (the core commander calls these for each regiment, in registry
order, before the regiment's own role)

| Hook | Purpose |
|---|---|
| `ai_context(view, team, ctx) -> ctx` | change what the whole side wants (a garrison forms across its gate) |
| `ai_order(view, team, r, ctx) -> Variant` | an order, `Module.PASS` (let the role decide) or `Module.HOLD` (no order) |

**The screen** (the screen calls these; the battle never does)

| Hook | Purpose |
|---|---|
| `on_tap(screen, at) -> bool` | a tap on empty field it takes (a gate; a flag, for command) |
| `react(screen, event)` | effects and notices for its events |
| `draw_marks(view, battle)` | marks over the regiments (a gate's damage; a division's own-command diamond) |
| `layers() -> Array[Layer]` | map layers it adds (anti-air coverage, air) |
| `actions(screen) -> Array` | buttons for the bottom bar's one module slot (aim a strike, air) |
| `describe(battle, r) -> String` | its words in the selection readout |

**Per-regiment state.** A module keeps what it knows about a regiment in its
own state, keyed by regiment id (which gate a battery is battering), not in
fields on `Regiment`. `Regiment` holds only core data.

**The screen stays calm.** Modules get places, not the whole screen: marks
over the field, layers behind a switch, one slot in the bottom bar, a line
in the selection readout, notices in the toast column. A module's `intro`
is shown once, the first time a player meets it, so the core game still
needs almost no introduction.

## Commanders

A commander turns a battle into orders for one seat. The core AI is one,
and it runs every module's AI hooks before its own roles, so a commander
built on it serves every module without knowing they exist. If a module
ever needs something only a commander can do (a strategy module asking an
AI in the army's seat for a plan), it will list the methods it needs, and
every commander in a seat it governs is checked when the battle is built,
with a default (the historical plan) so nobody has to write one. That is
designed, not built: no module needs it yet.

## Packs

```gdscript
const PACK := {
	"id": "sieges", "name": "Sieges", "menu": "quick",
	"modules": ["fortifications"],
	"scenarios": [STORM, LAST_KEEP, BREACH],
}
```

Packs are listed in `packs/registry.gd` (a web build cannot scan folders).
`menu` says where a pack's scenarios appear: the campaign, quick battle by
era, or grand battles. A scenario's keys are checked when its battle is
built, so a misspelt or unowned key is an error naming it, and its map
kind must be a core one or one its modules provide. If a pack's module is
not loaded, the pack is left out of the menus and the suite says so.

To add an era: write `packs/<name>.gd` with a `class_name`, a `PACK` holding
its `era` (id, name, the kinds a Skirmish draws) and its scenarios, and add it
to `Packs.ALL`, oldest era first. `packs/registry.gd` documents every field;
`packs/pike_shot.gd` is the one to copy. The tabs, the list, the map previews
and the suite's scenario battles all read the registry, so no other code
changes. Then record the new battles (below).

## Staying stable

- **Recorded battles.** The suite fights fixed battles through the one
  commander loop: the campaign on three seeds, every quick scenario, the
  sieges, and Gettysburg and Waterloo through the whole day. It compares
  each winner, time, losses and flags with the recording for the platform
  it runs on (`tests/golden-macos.txt`, `tests/golden-linux.txt`). A
  battle is deterministic on one platform, but the maths library's last
  bits differ between platforms, and the knife edge grows them into a
  different battle: on 1 November 2026, 21 of 44 battles came out
  differently on CI's Linux than on macOS. So each platform keeps its own
  recording, and the studies, which measure many battles, are what holds
  across platforms, including the web build players run. The platform
  includes the system's maths library, so CI runs on a pinned image
  (Ubuntu 24.04): on 7 November 2026 `ubuntu-latest` moved to 26.04 and 18
  of the 44 came out differently with no change to the code. Moving to a
  new image is a deliberate re-recording. A change that moves any of them
  fails until the file is updated in the same commit, so every balance
  change is a visible, deliberate diff.

  Recording on macOS is `./test.sh --record`. Linux has no local run, so
  record it on CI before main moves: push the change to a branch and run
  the workflow there (`gh workflow run pages.yml --ref <branch>`). Its Test
  step fails with a "was" and a "now" line for each moved battle;
  `tests/golden-linux.txt` takes the "now" lines. Take them only from a run
  whose runner image matches the last green run on main. A branch run never
  publishes: the Pages environment deploys from main alone. One gap:
  `_compare_golden` prints no line for a battle not yet recorded, so CI's
  report can't fill in a new scenario. Have it print the line when adding
  the next one.
- **Modules don't leak.** A pack that lists a module whose data its
  scenarios don't use must fight exactly as the core does; and the packs
  that use several modules are recorded together, so modules are tested in
  company.
- **Every scenario is built** with its pack's modules and every commander.
- **A time budget.** The suite times the step on the largest battle and,
  on CI, fails past a budget, worst step as well as average, so a phone
  stays smooth at 4×. On a dev machine it only reports the time: other work
  there inflates it tenfold.
- **Each module tests itself** in `modules/<id>/test.gd`.

## Migration

Each step is one commit that keeps every check the same and can be
reverted alone. A step that must move recorded battles says so, and moves
them once, deliberately.

Steps 1, 2 and 5 are done, with the small parts of step 4 that touch only
the specs and the order dispatch (6 November 2026). Packs went ahead of
kinds on purpose: kinds as data rewrite `ai.gd` and the studies, which the
better-AI branch was rewriting too. It landed on 8 November 2026, so step 3
and the rest of 4 can go ahead.

1. **One clock and one loop.** The commander loop and seats in the core,
   stepping at `Battle.STEP`; the screen, the suite and the balance studies
   all use it; orders logged by step; cosmetic random numbers off the
   battle's generator. This changes outcomes: today the tests step at 1/15
   s and the game at 1/30, and 6 of the 15 campaign battles change winner
   between them. DESIGN.md's tables are measured again.
2. **Record the battles** through that loop, on the CI platform, and add the
   comparison and the time budget to the suite.
3. **Kinds as data**, with roles, traits and looks; doctrine keyed by kind
   id; the build-time check that every role is handled.
4. **The dormant rules, one commit each**: formation shape; one list of
   flights; each side's home and abilities. Done: held flags written one way
   (`own_flags` and `their_flags`, lists in every spec); unknown orders an
   error; a scenario's keys checked when its battle is built.
5. **Packs**: scenarios and eras into pack files and the registry; the
   menus and briefings read packs.
6. **The contract**: `Module`, effects, `TerrainFeature`, layers, the hook
   calls, the build-time checks.
7. **Fortifications** out of the core: its map kind and features, gate
   state in its own state, bombard as fire at a place, ramming and gate
   damage as effects, the garrison behind the AI hooks, the gate tap and
   marks behind the screen hooks. Its own generator moves the siege
   recordings once.
8. **Command** as a module: sending a division to a flag creates a seat in
   the core loop; the module is the tap, the marks and the words.

After that, new mechanics start as modules. The steps touch the same core
files, so they run one after another in one session.

## Solving the game: search and learning

The studies need many battles, and a stronger AI needs to try plans before
it commits to one. What that costs, what was built to try it, and what it
found (1 November 2026).

**The cost.** A quick battle is 3,000–6,000 steps of a third to one
millisecond: one to five seconds of computer time on a free core. A plan
search of thirty plans on three dice is about ninety battles. Studies of a
few thousand battles fit in an afternoon on ten cores. Reinforcement
learning, which wants hundreds of thousands of battles at least, would take
days of computer per experiment.

**Built for it.**

- **Copies.** `Battle.copy()` copies a battle as it stands, down to its
  random numbers, and `BattleRun.copy()` copies its commanders with it:
  fought on, the copy fights the same battle, which the suite checks 60 s
  on, a castle's gates included. A copy takes a few milliseconds, so trying
  a plan costs only the fighting. (Godot passes packed arrays by
  reference; the copy duplicates them.)
- **Plans as values.** A commander keeps a plan, where each block of its
  line goes (block id to flag index), thinks it out with `AI.allot`, and
  hands it to `AI.decide`, which carries it out; the AI stays a pure
  function and the commander holds the one piece of state. A planner is a
  commander that picks its plan another way. The plan can be thought out
  at every look or more slowly (`rethink`): every 4 s stopped blocks going
  back and forth when the battle wavered around a threshold, but cost more
  in strength than it saved, so the AI thinks at every look.
- **The planner.** `Commander.PlannerCommander`: every 20 s it tries the
  AI's own allotment and the whole line sent to each flag, each on a copy
  fought 30 s ahead, and keeps the one that leaves it furthest ahead. It
  fights about seven battles' worth of steps per battle: fine for studies,
  too slow to run live on a phone at 4×.

**What it found.** On the quick scenarios, four dice each, the planner
wins 69% (36 of 52) where the standard commander, the same AI without the
look ahead, wins 41% (sharp 48%). It is nowhere worse, and it wins Riders
at Dawn and the Great Battery, which no commander on the ladder wins once.
The rollouts draw dice of their own (`Battle.reseed`): a copy keeps the
battle's random numbers, and without the reseed the planner would see
where the guns' shot was going to fall.

How much look ahead it needs (2 November 2026, the thirteen quick
scenarios on eight dice, 104 battles a column, standard on the same
battles 44%): one rollout per choice wins 76%, two 70%, so one is enough;
but a 10 s look ahead wins 44%, no better than none. The planner has to see
about 30 s on, which is four rollouts of 900 steps every 20 s: some six
rollout steps for each step of the battle, so the battle costs about seven
times as much. On a desktop at 1× that is a few milliseconds a frame; on a
phone at 4× it is too much. A `budget` spreads the search over every step of
the battle (`Commander.between_looks`; the suite checks the same plans are
tried from the same moment), so no frame carries it, and the choice lands as
long after that moment as the search took: 10 s at twelve rollout steps a
step, 20 s at six. Distilling the planner is the way to a phone.

Whether it would make a harder enemy (7 November 2026, the designed battles
and mirror Skirmishes, 208 battles a column, ±7): barely, and not once it
fits a frame. The person-paced player wins 48% against the AI and 43%
against the planner, the AI as the player 40% and 34%. On a budget it is no
harder than the AI: 50% and 43% at twelve rollout steps a step, 53% and 37%
at six. The same search is worth 30 points as the player (DESIGN.md, the AI
audit); why so much less as the enemy is not measured. So the game keeps the
AI as its enemy, and offers no planner as a hard setting; this is the current
reading, open to what play shows.

**What would make it cheaper**, most value for least cost first:

1. **Soldiers as a view, not the simulation.** Today each soldier is
   simulated and his place matters: which men fall first, what a cannonball
   hits. Simulating each regiment as a whole (men as a count, a blast's
   toll from how much of the block it covers) would cut about a quarter of
   each step, take away much of the knife edge, and leave a state of a few
   numbers per regiment that a search or a learner can read. The screen
   still draws every soldier. Cost: moderate, and every recorded battle
   moves once.
2. **A faster core.** Porting the battle step to native code would make it
   tens of times faster. The recorded battles would be its specification:
   the port is done when they all come out the same. Cost: high; worth it
   only if learning becomes the plan.

**The verdict on learning: not now.** Measured, three things stand against
it:

- **Cost.** A hundred thousand battles is four to six days of one core,
  before a learner exists: GDScript has none, so it would be a Python
  learner driving headless Godot over a pipe.
- **The knife edge.** Changing when one commander first looks by a few
  steps turns one battle of Hold the Fords into another (eight offsets: 5
  won, 3 lost); taking one order out of a logged battle flips the winner a
  third of the time. A learner's reward for a small change of policy is
  mostly that noise, which multiplies the battles it needs.
- **The gap is reachable without it.** The planner finds what there is
  to find in where the line goes, 28 points of win rate over the AI it
  is built on, with no learning: a search over a handful of plans with
  the true rules. What it leaves is tactics (pikes against horse, the
  general's place, the back-and-forth around thresholds), which are
  cheaper to write and measure than to learn.

What would change the verdict: soldiers as a view (cheaper battles, a
smoother edge, a small state to learn from), and a planner that clearly
beats the heuristics but is too slow to ship. Then learning has one job:
distilling the planner into a policy fast enough for a phone, learned from
the planner's choices rather than from wins and losses.

The data for that job is written by `tests/plan_examples.gd`: a row per
re-plan with 33 numbers for what the side sees (per flag: owner, capture
progress, each side's strength there; then the clock, resolve and each
arm's strength), the rollout score of each of the four choices, the one
taken, and the outcome. Two scores fit it: per-decision regret (the best
choice's rollout score minus the chosen one's), a pure function over the
file; and the win rate with the learned chooser fought as a commander,
which only the simulator can give. A learned chooser has to run in GDScript
in a single-threaded web build, with the heuristic allotment as its
fallback when it is unsure.

## Air: a worked example

How drones, missiles and interceptors would enter, to check the contract
before it is built.

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

**Weapons are values, not special cases.** Every weapon sits on a few
shared axes: speed, homing, area, whether it can be shot down, warning
time, cost. The counters follow from the numbers.

| In flight | Fired by | Speed and warning | Can be stopped by | Notes |
|---|---|---|---|---|
| shell | a gun, at a place, on or off the field | arc, seconds; landing ring | close-in guns and lasers, in range, at a rate | counter-battery finds the gun |
| mortar bomb | a mortar team, over cover | high arc, a few seconds; ring | the same | fires over houses and hills |
| railgun round | a railgun, straight | almost instant; no warning | nothing | long reload; the precise, narrow end |
| FPV drone | a drone team, at a regiment | slow (horse pace), homes | any block's guns close in, anti-air guns, interceptor drones; jamming | fibre-optic ones ignore jamming but keep within a ring of their team |
| loitering munition | a drone team, at an area | slow; waits for a target | the same | a decoy draws it off |
| one-way drone, cruise missile | off the field, from its side's edge | minutes in history, seconds in play; ring | interceptor drones, guns, missiles | comes in waves, with decoys |
| ballistic or hypersonic | off the field | fast; a second's warning or none | only the long-range tier, at a low rate | effectively unstoppable without that tier |

**Interception is a rate, not a roll.** An interceptor has a ring, the
tags it can engage, the fastest thing it can catch, how many flights it can
engage at once, how long each one takes, and a magazine. A flight it can
engage inside its ring is stopped once it has been engaged for that long.
Too many at once and the rest get through. So failure is "I can't kill
those fast enough", never "I can't kill that"; saturation and decoys work
by themselves, and the dice stay out of it, which Fordline's own luck
study argues for. A
slower interceptor catches a faster flight only while it is still coming
in, which puts pickets forward.

**Jamming is a zone.** Radio drones that fly into an enemy jammer's ring
drift and drop; your own falter in your own ring. Fibre drones are immune
and stay on their leash.

**Aircraft are flights that come back.** A drone or a missile is spent; a
sortie returns and rearms. Aircraft are a side's wings, each a resource
given a mission, as in Supreme Commander, where you direct the effort and
never fly the dogfight:

- **Strike** a place: the wing flies in from its side's edge, drops its
  munitions (flights of their own) and turns for home.
- **Cover** an area: the wing becomes a moving interceptor ring that
  engages only aircraft, at its rate.
- **Escort** a strike: its cover ring travels with it.

Who owns the sky is then whose rings are where, and it reads as a layer on
the map: denied, contested, open. Over open sky a strike arrives quickly
and surely; through enemy rings each ring spends its rate on the sortie,
which may be turned back or lost, or must drop from outside the rings with
weapons that can themselves be shot down. Winning the air is a ground
decision: push your anti-air forward, or kill theirs to open the sky. A
grand battle can simply give the sky to one side as a scenario value: then
the other side's arrivals come slower by day, as German reserves did in
Normandy.

**Effects lean to nerve.** A strike costs more morale and stamina than men,
so air shapes where blocks will stand rather than deleting them: air that
removes a garrison would make a siege a walk.

**What it takes:** from the core, flights with an `ext` slot, each side's
home edge and abilities, layers, and kinds as data (drone teams, anti-air,
jammers, mortars, railguns); from the contract, `in_flight` to steer,
intercept and fly sorties, `on_landed`, its own state for magazines, wings
and jammers, `ai_order` for launchers and anti-air, `draw_marks` for
countdowns, `layers` for coverage and the sky, `actions` and `on_tap` to aim
a strike or set a wing's mission.

**Left out on purpose:**
- Aircraft you steer, and dogfights. A wing is given a mission, not flown.
- Seeing and being seen. The map shows everything; reconnaissance drones
  and fog of war are not planned.
- Cost exchange as an economy. It is the scoreboard, not the fun. At
  most, magazines carry over between campaign battles.
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
comes from its kind: a hull under its crew. Its weapons are flights like
everyone's: long guns that fire at a place for the shore; on later ships,
an escort's anti-air ring that moves with it, and a carrier's wings.

**The sea is three kinds of water and nothing else:** deep (any ship),
shallows (boats and landing craft only; a visible lighter colour) and the
coast. No currents, tides or wind (DESIGN.md, pillar 6).

**Landings are arrivals by sea.** A force comes in landing craft along a
sea lane from its side's home edge, and becomes regiments on the beach it
reaches; craft hit on the way lose men, as anything does.

**What it takes:** from the core, as dormant rules, a domain on regiments
(land unless a kind says water) that the terrain's blocking and speed
answer for, the hull look, and the grid router, which moves from
fortifications to the core once a second user (the sea) needs it; from the
contract, `make_map` for coastlines and shallows, `ai_order` for ships
(keep station, support the shore), `react` for their effects. Landings use
the core's arrivals with a sea lane. No new hook.
