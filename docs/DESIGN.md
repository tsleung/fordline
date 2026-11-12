# Fordline — design

A real-time tactics game about holding river crossings with regiments of
little soldiers, seen from above on a flat field map. One campaign is five
battles and takes about twenty minutes. Built in Godot 4.5, so it runs in a
browser (desktop or phone) and exports to Android and iOS from the same code.

Every decision here is provisional: it is the studio's call, made to be
played and argued with.

## The thirty-second version

You command a small army: swords, pikes, archers, cavalry, cannons and your
general (in the later eras' scenarios, muskets, line infantry or rifles
take the place of swords and bows). Each battle is on a new map with a river, woods and hills, and
three flags at the crossings. Holding more flags than the enemy drains their
**resolve**; routing their regiments drains it faster. When one side's
resolve hits zero, its whole army breaks and runs. After a win you keep your
survivors, pick one of three rewards, and march to the next battle. Lose
once and the run is over; your score goes on the board.

## Pillars

1. **The look is the toy.** Hundreds of soldiers in blocks, banners over
   each block, lines grinding together at a ford. Soldiers die one by one,
   the front rank refills from the back, and a broken regiment scatters.
2. **Read the board in a glance.** Each banner shows the regiment's type,
   strength (the ring) and morale (the bar beneath it; the banner blinks
   when wavering). A line marks each block's front, so its flanks show.
   The flags and the two resolve bars say who is winning.
3. **See it coming.** A red arrow shows each enemy regiment closing on one
   of yours, and a red ring pulses on the banner it is coming for; enemy
   horse on the move trails a faint arrow. Flank and rear hits are called
   out. The fun is reading the move and answering it in time.
4. **Every battle is short.** Resolve drains a little faster after four
   minutes. A battle is two to four minutes, a run is about twenty.
5. **One more run.** Losses carry over, regiments earn stars, rewards stack
   into a build, and a run ends on the first defeat with a score.
6. **History serves the fun.** A rule taken from history or physics earns
   its place when it shows on the map and changes a decision. Hills do:
   you see them and choose where to stand. Squares do: you see horse
   coming and the infantry answers. Currents, tides and wind at sea do
   not: they are invisible and would drift a ship off the place you sent
   it, fighting the one-tap order instead of adding a choice.

## Rules

- **Counters.** Pikes stop cavalry. Swords beat pikes. Cavalry rides down
  archers, muskets and cannons. Archers and cannons wear everyone down from
  range; muskets break blocks of pikes.
- **Muskets.** Range 170 (archers 230), one volley every 7.5 s that lands
  at once. Shot goes through 70% of armour, but woods still halve it, and a
  volley costs its target 6 morale on top of the men it kills (arrows: 1.5).
  Weak in melee and soft to horse (1.8×), so they stand behind pikes. A
  musket on the move doesn't fire, so the AI's muskets only step back from
  foot within 60 (archers: 110).
- **Flanks.** A regiment fights the enemy in front of it. Hit it from the
  side and it takes 1.5× damage and 1.7× the morale loss; from behind,
  2.2× and 2.5×. So pin with infantry, then hit with cavalry.
- **Morale.** Casualties, flanks, cannon fire and nearby routs drain
  morale. At zero the regiment routs: it runs for its own edge and can't be
  ordered. If it gets clear of the enemy it rallies, and its side wins back
  a little resolve. Your general's aura slows the bleed; the Rally horn
  brings broken regiments back.
- **Terrain.** The river can only be crossed at fords (slow) and bridges.
  Woods slow movement and halve arrow damage. Hills extend range and
  harden defence.
- **Fatigue.** Melee wears a regiment out in about a minute; marching
  tires it a little; standing clear of the fight restores it in about
  thirty seconds. A spent regiment strikes at half strength, loses nerve
  half as fast again, moves at three-quarters pace and its horse cannot
  charge. So the side that wins the first clash is tired when the second
  comes: a fresh reserve sent in where the line bends turns fights.
- **Castles.** A fortress map is a castle backing onto one edge of the
  field: a moat with one bridge, a curtain wall with a gatehouse, and an
  inner keep with its own gate in its side wall and a great tower. Nobody
  walks through stone, and no blades cross a wall; arrows, shot and balls
  fly over. A gate is open to its own garrison and shut to the besieger
  until battered down: the outer gate takes 300, the keep's 220; each
  cannonball landing on it 5, each barrage shell 14, and the regiment of
  foot pressed closest against it from outside 0.04 per man per second
  (one ram at a time; 48 men take about two minutes alone). Select guns
  and tap an enemy gate to batter it. The wall-walk, 40 deep inside each
  wall, counts as a hilltop (range +25%, defence +0.12) and its
  battlements stop 70% of arrows and shot. The side holding a castle
  fights as its garrison: its foot form across the gateway and fight only
  what gets inside, its shooters and guns man the wall-walk and answer
  the enemy's shooters first, its horse may sally.
- **Charge.** Cavalry that hits at speed deals heavy damage and a morale
  shock for two seconds, except against pikes from the front.

## Controls (touch and mouse alike)

- Tap a regiment to select it; tap again to deselect it. Double-tap to
  select every regiment of that type. **All** selects the whole army.
- With nothing selected, drag on the field to box-select.
- With a selection: tap the field to move there; tap an enemy to attack it.
- A drag is an arrow: the selection stands where it starts and faces the
  way it points, side by side across it. Drag from a selected banner to
  turn the selection where it stands. Any direction works, so a line can
  face a flank or its own rear.
- Waypoints: a selected route ends in a gold marker. Tap it to pin it (a
  ring with a plus) and the next tap on the field adds a leg from there
  instead of replacing the route; tap it again to unpin. On a computer,
  shift-click the field does the same in one click. Routing a flank force
  around woods or through a chosen ford is what this is for.
- Pause any time; orders can be given while paused. 2× speed for the
  quiet parts.
- **Menu** (top left, or Esc with nothing selected) pauses and offers
  Resume, Restart (quick battles) and leaving: back to the scenarios, back
  to the briefing before the fighting starts, or, once it has started, a
  retreat that ends the campaign (it asks twice).
- Abilities: **Rally** (from the start), **Barrage** and **Forced March**
  (rewards).

## The campaign

| # | Battle | Ground | Enemy |
|---|--------|--------|-------|
| 1 | Millbrook Ford | river, three fords | small, balanced |
| 2 | Ashwood | woods and hills, no river | aggressive, cavalry |
| 3 | Two Bridges | river, two bridges | dug in, archers and a cannon |
| 4 | Saltmarsh Road | river and roads | large, flanking |
| 5 | Marshal's Ridge | ridge at the centre | the Marshal and his guard |

Map details and the exact enemy roster vary per run from a seed.

After a win, every regiment gets back 40% of its missing men, and you pick
one of three rewards: a new regiment, a full muster, an ability, or a
doctrine (longbows, iron shot, steel, warhorses, old banners, drill).

## Quick battle

Scenarios for when there isn't time for a campaign: one battle each, on a
map fixed by design so it can be learned (seeded, or drawn by hand: see
"Drawn fields" below), three to five minutes. A win is
one star; each scenario names two more conditions (a fast win, light
losses, crossings held at the end), and the best is kept on the device.

| Scenario | Ground | Goal | Teaches |
|---|---|---|---|
| Skirmish | a new field each time | break them | two armies made the same; only play differs |
| Hold the Fords | drawn: three fords, a flag on each | hold one ford at 3:00 | standing on ground you already own |
| Hammer and Anvil | open woods | break them | pin with foot, ride round with horse |
| Two Narrow Bridges | drawn: two bridges, a gun hill behind the west one; barrage | hold both bridges at 5:00 | forcing a crossing with guns and a barrage: the bridge the guns cover first |
| Riders at Dawn | the ridge | break them | pikes against a cavalry army |
| The Storming of Duskwatch | a castle | hold two of its three flags at 6:00 | a siege: guns and a ram on the gate, then the keep |
| The Last Keep | your castle | hold one flag at 5:00 | holding the walls, then the gateway |

Scenarios are grouped by era, oldest first, with a tab for each above the
list (the list remembers the last one). An era is data: a name, the kinds a
Skirmish of that era draws from, and its scenarios. Medieval is the five
above; Pike and Shot fights with pikes, muskets, horse and guns:

| Scenario | Ground | Goal | Teaches |
|---|---|---|---|
| Skirmish | a new field each time | break them | the same, drawn from pike, shot, horse and guns |
| Push of Pike | drawn: three flags on a lane, a rise 140 behind them | break them | let the shot thin their blocks before the pikes meet |
| Shot at the Fords | drawn: three fords, the flags 170 back from the water | hold one flag at 3:00 | muskets on ground that makes the enemy wade |
| The Cuirassiers | drawn: their flag behind the middle ford, a ford 540 off either side | break them | ride round the pikes into the shot behind them |
| The Great Battery | drawn: a hill for the guns, a lane flag at either edge | break them | cross open ground under three batteries: at once, all together |
| The Breach at Greyhold | a castle | hold two of its three flags at 6:00 | great guns against walls built for bows |

In a siege the flags don't drain resolve (a castle's three would bleed
the attacker dry before the gate fell); they decide at the deadline.

**Line and Square** fights with line infantry, horse and guns. Line that
stands its ground forms square when enemy horse comes within 240, and keeps
it until none is within 330 (`Battle._squares`). Horse hits a square at
0.35, a charge doesn't land on it and it has no flank, but only one face
fires: half a volley.

| Scenario | Ground | Goal | Teaches |
|---|---|---|---|
| Skirmish | a new field each time | break them | the same, drawn from line, horse and guns |
| Receive Cavalry | drawn: a low ridge to start on, a crossroads, their camp | break them | stand to form square, then their three batteries find the squares: when to break it |
| Horse and Guns | drawn: three flags on a lane, an inn at the middle one | break them | threaten with horse to force squares, then shoot them |
| Line at the Fords | drawn: two fords, the flags 215 back from the water | hold one flag at 3:00 | stand back: their line must wade into your muskets, their horse must cross to force a square |
| The Bridge at Dawn | drawn: two bridges, a ford upstream; barrage | hold both bridges at 5:00 | forcing a crossing: horse over the water keeps their line in square |

**Rifle and Gun** fights with rifles, horse and guns. Rifles reach 230
where muskets reach 170, and trees halve the fire of whoever shoots into
them (`Terrain.cover`).

| Scenario | Ground | Goal | Teaches |
|---|---|---|---|
| Skirmish | a new field each time | break them | long reach on any field |
| Open Ground | drawn: houses along a ridge, a wood off its east end | break them | crossing open ground under rifles and guns: go round |
| Into the Trees | drawn: three woods, a flag in each | break them | trees halve fire: be in the woods before they are |
| Shoot the Gunners | drawn: four batteries on a hill over two roads | break them | each battery is twelve men: close inside 230 and shoot the gunners |
| Hold the Creek | drawn: three fords, the flags 250 back from the water | hold one flag at 3:00 | reach against men who must wade |

**Both eras run at pace 0.4.** Rifles and Line were made for the grand
battles, which run at `pace` 0.4: volleys of shot and arrows do that share
of their damage, and nerve comes back at that share of its rate, while a
volley's shock and the guns' cannonballs are not scaled. At pace 1 a rifle
volley killed a dozen of a regiment's forty: Open Ground, Shoot the Gunners
and Hold the Creek were over in about a minute, and the Creek was lost by
every commander in its first volleys. So an era can set the pace its quick battles run at (`pace` on the
era in its pack; 1 if not given), and Medieval and Pike and Shot keep 1.
Their kinds' stats are the grand battles', unchanged.

Four era tabs fit a phone 360 pixels wide (`tests/shot.gd --scenarios`),
so there is no range slider yet.

Measured 2026-10-31, AI players of the luck study, wins (stars):

| Scenario | idle | slow | standard | sharp |
|---|---|---|---|---|
| Skirmish (36 battles each) | 0% | 42% | 28% | 61% (1.2) |
| Push of Pike | 0% | 0% | 17% | 100% (2.0) |
| Shot at the Fords | 0% | 100% | 0% | 100% (2.0) |
| The Cuirassiers | 0% | 100% (2.0) | 100% (2.0) | 100% (3.0) |
| The Great Battery | 0% | 0% | 67% | 100% (2.3) |

Sieges, measured the same day:

| Scenario | idle | slow | standard | sharp |
|---|---|---|---|---|
| The Storming of Duskwatch | 0% | 50% | 100% | 83% (1.3) |
| The Last Keep | 67% | 33% | 83% | 100% (3.0) |
| The Breach at Greyhold | 0% | 83% | 50% | 83% (1.7) |

The two later eras, measured 2026-11-11 on the seeded fields they then
had, with the ladder of 7 November (see "Play over time"): eight dice each,
two draws of eight for the Skirmishes. The designed scenarios' ladder on
their drawn fields is under "Drawn fields" below; the Skirmishes' stands. Minutes are the standard commander's; stars are the average
over every battle, won or lost.

| Scenario | idle | person | standard | sharp | minutes | stars (person / standard / sharp) |
|---|---|---|---|---|---|---|
| Skirmish (Line and Square) | 0% | 38% | 56% | 88% | 2.7 | 0.4 / 1.1 / 1.3 |
| Receive Cavalry | 25% | 100% | 100% | 100% | 1.8 | 2.0 / 2.0 / 2.0 |
| Horse and Guns | 0% | 100% | 100% | 50% | 2.4 | 2.9 / 2.4 / 1.2 |
| Line at the Fords | 100% | 75% | 50% | 88% | 2.7 | 1.2 / 0.8 / 1.8 |
| The Bridge at Dawn | 0% | 88% | 100% | 100% | 2.5 | 2.1 / 2.0 / 2.0 |
| Skirmish (Rifle and Gun) | 0% | 31% | 75% | 56% | 2.4 | 0.5 / 1.4 / 1.1 |
| Open Ground | 0% | 0% | 100% | 100% | 1.7 | 0 / 2.0 / 2.0 |
| Into the Trees | 0% | 100% | 50% | 100% | 2.8 | 2.5 / 0.6 / 1.8 |
| Shoot the Gunners | 0% | 62% | 75% | 75% | 1.9 | 1.2 / 2.2 / 1.5 |
| Hold the Creek | 0% | 62% | 50% | 100% | 1.8 | 1.2 / 1.0 / 2.0 |

Every scenario is won by some ways of playing and lost by others, and no
commander averages three stars. The armies differ from the first proposal
where four dice of the ladder said so. Against too little, every commander
but idle won, so the enemy got more: a third battery at Receive Cavalry
(against two, the idle player's squares won too), a fifth line regiment at
Line at the Fords, a fifth line regiment and a second battery at the Bridge
at Dawn, horse at Into the Trees, and four rifles, not two, guarding the
guns at Shoot the Gunners. In Horse and Guns standard and sharp lost every
time, so the player got a third line regiment; at Hold the Creek every
commander lost, so the player has five rifles, as many as the attacker.
Open Ground is as proposed: a fifth rifle regiment on the ridge and every
commander lost.

### Drawn fields (12 November 2026)

The eight designed scenarios of Line and Square and of Rifle and Gun are
fought on fields drawn by hand (`plan` in their packs; `ARCHITECTURE.md`,
"Packs"), not seeded ones. On a seeded field nobody chose where the woods,
hills and fords fell, so a brief could promise what the ground didn't
deliver, and any change to the generator would have redrawn every scenario.
Two cases were measured on 11 November: Open Ground's brief said "go round"
and a straight walk won 7 of 8; the fords' lesson is to stand back from the
bank, and the seeded banks were inside each other's reach, with the flags
on the crossings themselves. Six scenarios of the older eras were drawn the
next day (see "The older eras", below).

Each field is drawn so its lesson is true in distances. The numbers they
rest on: rifles reach 230, line and muskets 170, guns 430, each a quarter
more from a crest; a regiment told to shoot closes to 0.95 of its reach and
stands (218 for rifles, 161 for line); the AI attacks what comes within 1.1
of its reach (253, 187); line forms square when horse is within 240; trees
and houses halve arrow and shot, and stop no cannonball; the AI's guns
unlimber 170 behind the flag it most wants, its line stands 50 short of a
flag on its own side until the enemy is near, and it sends the whole line
to whichever flag is threatened. Both armies deploy in the usual zones: the
player's line at y 720, the enemy's at 100, on the usual 1300 × 820.

| Scenario | Its lesson | What on the ground makes it true |
|---|---|---|
| Receive Cavalry | Receive their horse in square where their guns can't reach; then break square and go for the guns. | Their guns unlimber at y 235, 170 behind the Crossroads, and reach to 665. The line starts at 720, on a low ridge, 55 beyond. Their general keeps a fourth flag, Their Camp, so a line that never leaves the ridge bleeds to the flags. |
| Horse and Guns | Horse within 240 holds their line in square, firing at half; then the guns kill it. | Three flags on a lane, 250 apart, with 400 of open ground beyond either end: horse can stand 240 from a block and outside its muskets' 170. The middle flag is among the Inn's houses, which halve your musketry and not your guns. |
| Line at the Fords | Stand back from the water. | Two fords 640 apart, a flag 215 south of each. The far bank's edge, 37 back from the water, is 252 from a line on the flags: past the muskets' 170, and past the 240 at which horse calls a square. Line and horse must both cross first. |
| The Bridge at Dawn | Get the horse over the water, by the ford, to hold their line in square while yours forces the bridges. | Two bridges 440 apart and 32 wide, with houses at their far ends that halve fire from the near bank. A ford 320 upstream of the west bridge, outside the 170 of the muskets there; horse across it is within 240 of them. |
| Open Ground | Don't walk at the ridge: take the flag their guns can't cover. | Highfield's houses run 500 along the crest and halve fire from the slope below; their guns, 170 behind its flag, reach every way up from the south. East Wood's flag is 730 from the guns, inside trees that halve the fire of whoever comes to retake it. |
| Into the Trees | Be inside the trees when the lines meet. | Three woods, each from y 420 to 630, a flag in each at 470. The lines start 620 apart and stop to fire 218 apart, the player's slowed by the trees it enters first: moving at once it stands near y 590, inside, and theirs between 340 and 400, short of the trees. Twelve seconds late, theirs is on the flags, inside, and the player's stops in the open. |
| Shoot the Gunners | Shoot the gunners, not the rifles in front of them. | Four batteries on a hill, 170 behind Battery Hill's flag, reach 530: both road flags, 490 away and 380 either side of the way up the middle. A battery is twelve men, and two volleys break it. |
| Hold the Creek | Stand back from the water. | Three fords 68 wide, a flag 250 south of each. The far bank's edge is 287 from a line on the flags, past the rifles' 230: to fire, they must cross, a regiment at a time at each ford. The Mill's houses halve fire at whoever holds it. |

**Measured** with `tests/lessons.gd`, which fights a scenario under plays
written down: a naive one and the one the brief asks for, against the
scenario's own enemy, on eight dice. Won, then the share of its men the
player lost. "Seeded" is the standard commander on the field of 11
November, measured the same way.

| Scenario | Seeded | The naive play | | The intended play | |
|---|---|---|---|---|---|
| Receive Cavalry | 8 of 8, 54% | advance at once (the standard commander) | 7 of 8, 71% | stand on the ridge until their horse is beaten, then advance | 8 of 8, 25% |
| Horse and Guns | 8 of 8, 34% | keep the horse back | 5 of 8, 30% | stand the horse 225 off the ends of their line | 8 of 8, 28% |
| Line at the Fords | 4 of 8, 67% | stand the line on the bank | 0 of 8, 47% | hold the flags (the standard commander) | 8 of 8, 50% |
| The Bridge at Dawn | 8 of 8, 41% | keep the horse back | 0 of 8, 72% | send the horse over the ford | 8 of 8, 44% |
| Open Ground | 8 of 8, 59% | the whole line at Highfield | 0 of 8, 65% | the whole line to East Wood first | 8 of 8, 66% |
| Into the Trees | 4 of 8, 64% | wait twelve seconds, then advance | 3 of 8, 54% | advance at once (the standard commander) | 7 of 8, 43% |
| Shoot the Gunners | 6 of 8, 42% | the whole line at Battery Hill, shooting whoever is nearest | 0 of 8, 81% | the whole line at the batteries, shooting the gunners first | 7 of 8, 48% |
| Hold the Creek | 4 of 8, 76% | stand the rifles on the bank | 0 of 8, 98% | hold the flags (the standard commander) | 8 of 8, 48% |

Every lesson holds. Over the eight, the intended play wins 62 of 64 and
the naive one 15: seven of those at Receive Cavalry, where advancing at
once wins too and loses 71% of its men to 25%, five at Horse and Guns, and
three at Into the Trees.
Two more measures of the fords, the same river with each flag moved onto
its crossing, where a seeded map puts it: the standard commander then wins
2 of 8 at Line at the Fords, losing 82% of its men (8 of 8 and 50% with the
flags 215 back), and 4 of 8 at Hold the Creek, losing 72% (8 of 8 and 48%
with them 250 back). The bridge has two ways over
for the horse: by the ford it wins 8 of 8 with 2.5 stars, by the west
bridge (where the AI's own horse goes) 6 of 8 with 1.5.

The ladder on the drawn fields, eight dice each (`tests/luck_skill.gd`,
reported by `tests/play.py`); minutes are the standard commander's, stars
the average over every battle:

| Scenario | idle | person | standard | sharp | minutes | stars (person / standard / sharp) |
|---|---|---|---|---|---|---|
| Receive Cavalry | 0% | 100% | 88% | 100% | 2.2 | 2.8 / 1.8 / 2.0 |
| Horse and Guns | 0% | 100% | 62% | 100% | 2.0 | 2.8 / 1.5 / 2.4 |
| Line at the Fords | 0% | 88% | 100% | 100% | 3.0 | 1.8 / 1.2 / 1.0 |
| The Bridge at Dawn | 0% | 88% | 75% | 100% | 2.7 | 1.6 / 1.5 / 2.5 |
| Open Ground | 0% | 12% | 88% | 62% | 3.0 | 0.1 / 1.8 / 1.2 |
| Into the Trees | 0% | 25% | 88% | 62% | 2.5 | 0.2 / 1.9 / 1.2 |
| Shoot the Gunners | 0% | 25% | 12% | 62% | 2.4 | 0.2 / 0.2 / 1.2 |
| Hold the Creek | 38% | 62% | 100% | 100% | 2.7 | 0.6 / 2.1 / 2.0 |

Against the bar: every scenario is won by some ways of playing and lost by
others, no commander averages three stars, and the standard commander's
battle runs 2.0 to 3.0 minutes (on the seeded fields, 1.7 to 2.8, four of
the eight under 2). Three things to read with it. Horse and Guns' second
star is now 25% of your men, not 35%: at 35% the person-paced commander
averaged 3.0 on the drawn field (2.9 on the seeded one). Shoot the Gunners
is hard for every commander on the ladder, because none of them picks its
target: the play that does wins 7 of 8. And the person-paced commander
loses Open Ground and Into the Trees, where being late or piecemeal is the
mistake the field punishes.

Changed besides the ground, and why:

- **Line at the Fords and Hold the Creek no longer deploy at the river**
  (`deploy_depth` is gone from both): the flags stand back from the water,
  and a line that starts at 720 reaches them before the enemy is across.
- **Their flags drain at 0.25, not 0.5.** They start the player's, and with
  the flags back from the water the attacker can't contest one until it has
  crossed: at 0.5 the standard commander's Creek was over in 1.3 minutes,
  on the drain alone.
- **Line at the Fords has two fords and two flags, not three.** Four line
  regiments on three flags 400 apart support nobody: standing on them won
  1 of 4, and a line that never left its start won 4 of 4.
- **Their briefs** say where to stand, since "the crossings are yours" is
  no longer what the flags are. The armies are as they were.
- **Receive Cavalry has a fourth flag.** Without Their Camp a line that
  stood in square all day won 4 of 4, in 9.4 minutes; with it, 0 of 8.

Tried and dropped, four dice each:

- **Open Ground, a farm on the crest and a wood beside the east flag.**
  Marching into the wood and shooting from cover won 0 of 4, losing in 1.5
  minutes: their whole line and then their guns come to the threatened
  flag, and while they hold three flags the drain is 1.5 a second, which
  ends the battle before fire from cover can. With the drain at 0.2 it won
  2 of 4. So the flag went inside the wood: taking it is what turns them.
- **Open Ground, a farm 150 wide.** The whole line straight at it won 3 of
  4, with fewer men lost than going round: only two of their four
  regiments fit inside. Hence houses 500 along the crest.
- **Shoot the Gunners, a copse within 218 of the guns** on the hill's east
  side. 0 and 1 of 4: their line stands across the way in. And the guns
  further back, in their own deployment zone: 1 of 4.
- **Hold the Creek, the creek bowed north in the middle** so that no flag
  was within 253 of the player's start line. The standard commander won 1
  of 4: their first regiments are over the middle ford before the line
  reaches the Mill. With two fords, as the line era has: 1 of 4. With the
  outer fords 400 from the Mill, not 470: a line that never moved won 4 of
  4, because the enemy, having taken the outer flags, keeps regiments on
  them against the nearest of the player's.
- **The Bridge at Dawn, horse standing 220 from the bridge guard** to hold
  it in square: 1 of 4, no better than no horse. Their guns kill a standing
  horse.
- **Line at the Fords, a line that walks to the flags and then stands
  still**, two regiments on each or all four on one: 0 of 4 either way.
  Their horse crosses and holds the squares, and their line shoots them.
  The standard commander, on the same flags and free to move, won 8 of 8:
  the ground puts the far bank out of reach, and holding it still takes a
  commander.
- **Into the Trees, woods from y 370.** As the lines met, three of their
  five regiments were at the trees' north edge or under them. The edge
  moved south to 420; waiting twelve seconds then won 3 of 8 where it had
  won 1, since the late line now stops nearer the trees.
- **Horse and Guns, no houses**: the standard commander averaged three
  stars. **Houses at two flags**: it lost 4 of 4 inside a minute, to the
  drain, shooting at half into both.

Found drawing them, and open:

- **The drain outruns the shooting in these two eras.** Three flags drain
  a side in 67 seconds, and at pace 0.4 shooting does 0.4 of its damage:
  the line that shot from the wood beside Open Ground's east flag lost in
  90 seconds with over half its men standing. A plan that fires from good
  ground without taking a flag loses to the clock, which is why every
  lesson above had to be made true of the flags and not only of the fire. Whether an era's drain should
  follow its pace is a rule for the owner's play to judge; it was not
  changed.
- **The standard commander doesn't play two of the lessons.** It shoots
  whoever is nearest, so at Shoot the Gunners it shoots the rifles in front
  of the guns; and its horse rides at the nearest shooter, so at Horse and
  Guns it charges squares, which wins no more than keeping it back (5 of 8
  each). `scripts/ai.gd` was not changed.
- **A line that never moves still wins Hold the Creek 3 of 8** (with 0.4
  stars). The enemy takes the outer flags and then keeps regiments on them.
- **There is no scenery.** Every copse is cover and slow ground. The first
  Creek had two copses, put there for looks, under the ends of the player's
  start line, and the line that never moved won 5 of 8 from them; copses
  beside the gunners' roads stood where an attack on the road flags stops
  to fire. Trees that carry no lesson are now in the corners of the field.
- **A drawn field's drills are written for it** (`PLAYS` in
  `tests/lessons.gd`): redraw the field and they are redrawn with it.

#### The older eras (13 November 2026)

Six designed scenarios of Medieval and of Pike and Shot are drawn the same
way: Hold the Fords and Two Narrow Bridges; Push of Pike, Shot at the
Fords, The Cuirassiers and The Great Battery. Hammer and Anvil and Riders
at Dawn stay seeded.

**These eras run at pace 1, and that changes what ground can do.** A
volley does its full damage, and a meeting of pike or sword blocks is
decided in ten to twenty seconds. Bows are weak (a volley from thirty-six
archers kills about three of forty-eight swords), muskets are not (six or
seven of forty-eight, and they shake them), and a battery kills a few men a
salvo. Nothing on a field changes melee but a river: houses and a crest
take a tenth off a blow. So these lessons rest on reach where the kind has
it, and otherwise on who meets whom, and when. The numbers besides those
above: bows reach 230 and muskets 170, each a quarter more from a crest
(287, 212); pikes go for anything within 220, and for horse first; the AI
stands its bows and shot 75 behind its foot, and sends one block of foot to
each flag it has no reason to mass on. Foot deploys at y 670, shot and bows
at 720; theirs at 150 and 100.

| Scenario | Its lesson | What on the ground makes it true |
|---|---|---|
| The Cuirassiers | Ride round the pikes, by a ford they can't reach, onto the shot and guns behind them. | One flag 180 north of the middle ford, so their three pike blocks stand side by side across it, shot 75 behind, guns 170 behind the flag. The middle ford comes out 143 from the flag, inside the pikes' 220 and the guns' 430. The outer fords are 540 either side: 643 from the guns, 440 from the nearest pikes. |
| Hold the Fords | Put a block on each ford and keep it there. | Three fords 68 wide and 450 apart, a flag on each, the player's from the start. The river is 230 from their foot's start line and 290 from the player's, so a block sent to each ford is on its flag as they wade. A flag changes hands only when one side stands on it alone; a block is 15 seconds from the next ford. |
| Shot at the Fords | Stand a musket's reach back from the water. | Three fords 450 apart, a flag 170 south of each: shot on the flags reaches the middle of the ford, and shot on the far bank is 207 from the flags. To fire, theirs must wade. |
| Two Narrow Bridges | Force the bridge your guns cover, with the barrage on its guard; then the other. | Two bridges 440 apart, houses at their far ends that halve arrows and stop no cannonball. Gun Hill is 170 south of the west bridge, where the guns unlimber: from it they reach 537, their gun 474 away and the west guard. The east bridge has no hill: guns behind it reach 430, and their gun is 472 away. |
| The Great Battery | Cross the open ground at once and all together, at the guns. | The guns stand on a hill 170 behind the battery's flag and reach 537, 3 short of the pikes' start line. A lane flag at either edge, 658 from the guns and 574 from the battery's flag. Their general sends a pike block to each flag: one stands before the guns, and the other two are 21 seconds' march away. The battery's flag is 370 from the start line, 14 seconds. |
| Push of Pike | Stand on the rise and let the shot work as their blocks climb; then push. | Three flags on a lane, the same march from both lines, and a rise 140 behind them. Shot on its crest reaches 212, 72 past the flags. Their shot, 75 behind pikes on the flags, is 215 from the crest and reaches 170. Their pikes, within 220 of shot on the crest, leave the flags and climb at it. |

**Measured** as the newer eras were, eight dice. "Seeded" is the standard
commander on the seeded field, measured the same day.

| Scenario | Seeded | The naive play | | The intended play | |
|---|---|---|---|---|---|
| The Cuirassiers | 2 of 8, 55% | the horse straight at their shot, over the middle ford | 0 of 8, 72% | the horse round by the west ford, the foot over the middle | 8 of 8, 31% |
| Hold the Fords | 2 of 8, 46% | send the foot over the middle ford to meet them | 1 of 8, 42% | a block on each ford, bows behind, never moving | 8 of 8, 47% |
| Shot at the Fords | 3 of 8, 46% | stand the line at the water | 1 of 8, 42% | hold the flags (the standard commander) | 7 of 8, 44% |
| Two Narrow Bridges | 1 of 8, 51% | the whole line at the east bridge, with the barrage | 0 of 8, 75% | the whole line at the west bridge, with the barrage | 5 of 8, 65% |
| The Great Battery | 1 of 8, 68% | take the lanes first (the standard commander) | 2 of 8, 73% | the whole line at the battery's flag | 5 of 8, 61% |
| Push of Pike | 4 of 8, 55% | march the pikes 100 past the flags | 1 of 8, 60% | pike, shot and gun on the crest until their pikes are within 90 | 8 of 8, 31% |

Over the six, the intended play wins 41 of 48 and the naive one 5. The
lessons are not equally strong. The Cuirassiers, Hold the Fords and Push
of Pike are as clear as any of the newer eight. The bridges and the
battery are won five times in eight by the play the field asks for, and
stay hard.

Other plays measured on the final fields: the standard commander at The
Cuirassiers wins 5 of 8 over the middle ford and loses 61% of its men; at
the bridges it attacks both and wins 2 of 8; at Push of Pike it meets them
on the flags and wins 4 of 8. A commander that walks straight in wins 2 of
8 at The Cuirassiers (8 of 8 with three stars on the seeded field), 3 at
the bridges, 1 at the battery, 3 at Push of Pike. At Hold the Fords the
standard commander wins 7 of 8, losing 55%, and the one that walks
straight in 8 of 8. Shot at the Fords with each flag moved onto its
crossing: the standard commander wins 7 of 8, losing 54% (7 of 8 and 44%
with them 170 back).

The ladder, eight dice each, beside the ladder of 7 November on the seeded
fields:

| Scenario | idle | person | standard | sharp | minutes | stars (person / standard / sharp) | 7 November | its minutes |
|---|---|---|---|---|---|---|---|---|
| Hold the Fords | 0% | 25% | 88% | 100% | 2.2 | 0.4 / 1.9 / 2.0 | 0, 38, 25, 38% | 2.2 |
| Two Narrow Bridges | 0% | 0% | 25% | 75% | 2.2 | 0 / 0.5 / 1.1 | 0, 0, 12, 0% | 1.4 |
| Push of Pike | 0% | 38% | 50% | 62% | 1.2 | 0.9 / 1.4 / 1.9 | 0, 75, 50, 75% | 1.9 |
| Shot at the Fords | 0% | 88% | 88% | 100% | 2.4 | 2.2 / 2.0 / 2.4 | 0, 100, 38, 62% | 2.1 |
| The Cuirassiers | 0% | 12% | 62% | 50% | 2.0 | 0.1 / 1.2 / 0.9 | 0, 75, 25, 62% | 1.6 |
| The Great Battery | 0% | 0% | 25% | 12% | 2.4 | 0 / 0.5 / 0.2 | 0, 0, 12, 12% | 1.6 |

Against the bar: every scenario is won by some ways of playing and lost by
others, and no commander averages three stars. The standard commander's
battle runs 2.0 to 2.4 minutes in five of the six. Push of Pike's is 1.2:
two lines of pike that meet on the flags settle it in half a minute, and at
a drain of 0.25 it still ran 1.3. That one does not meet the bar.

Changed besides the ground, and why:

- **Hold the Fords and Shot at the Fords no longer deploy at the river**
  (`deploy_depth` is gone from both). Shot at the Fords' flags stand back
  from the water, and a line that starts at 670 is on them first. Hold the
  Fords' river is drawn 290 from the player's foot and 230 from theirs, so
  the usual zone is near enough. Both keep the drain of 0.5: at 0.25 Hold
  the Fords came out the same (7 of 8, and 8 of 8 for the blocks that
  stay), and Shot at the Fords ran 2.7 minutes for 2.4.
- **Two Narrow Bridges drains at 0.3.** At 0.5 the standard commander's
  battle was 1.7 minutes; at 0.3 it is 2.2. The wins did not move: 2 of 8,
  the west bridge 5 of 8 and the east 0 at either.
- **Briefs.** All six say where to stand or which way to go, since each
  field now has such a place. The Great Battery's no longer says "take the
  guns from the side": a gun's reach is the same all round and it turns at
  once, so a side is no safer than the front (measured below). Shot at the
  Fords' goal and stars say "flags", not "crossings", and the bridges' goal
  is written out. Hold the Fords keeps its brief and adds how: a block on
  each ford, and stay.
- No army changed, and no rule.

Tried and dropped, four dice each unless it says eight:

- **The Cuirassiers on open ground,** one flag at a crossroads with 500
  clear off either end of their pikes. The standard commander won 3 of 4
  from the front, once with three stars in half a minute. Horse round the
  flank with the foot going in at once won 2 of 4; with the foot held back
  nine seconds, so that both arrive together, 4 of 4; alone, 0 of 4. Their
  shot stands 75 from their pikes, which turn on horse within 220: riding
  round gains nothing unless the pikes are pinned at that moment, and
  nothing in open ground makes the front cost more. A river does both.
- **The Cuirassiers, the river 110 from the flag** (the ford comes out 73
  from it): the standard commander 0 of 4, round 3 of 4. **250 from it**
  (out at 213): the standard commander 4 of 4 with two stars, round 4 of 4
  with three. At 180 it is 5 of 8 and 8 of 8.
- **The Cuirassiers, the horse round and the foot never moving:** 5 of 8
  (eight dice), losing 30%. The horse alone nearly does it.
- **Hold the Fords, the flags back from the water on a ridge,** as the
  Creek's are back from it. First drawn that way: the crest 240 south of
  the river, so that bows on it reach the far bank (277 of 287) and are not
  reached, the flags on its slope 140 from the water. Eight dice: the
  standard commander 5 of 8; a line at the water that never moves 0 of 8;
  the same line on the flags and crest, never moving, 2 of 8; each of
  those two handed to the AI when the enemy is within 90, 0 of 8 and 0 of
  8; and the standard commander with the flags moved onto the crossings 7
  of 8. The ridge did not beat the bank on equal terms, so the field was
  not teaching it. Bows don't decide a Medieval battle: a volley kills
  three men, and standing back buys one or two.
- **Hold the Fords, other ground behind the fords** (eight dice, the
  standard commander and the one that walks straight in, which differ only
  in their first eight seconds). Flags an archer's reach back, no ridge: 3
  and 7 of 8. Two fords: 3 and 5. Three fords 320 apart: 5 and 4. A ridge
  under flags 230 back: 3 and 1. Flags 140 back and no ridge: 5 and 6. A
  crest 260 back: 8 and 6. Nothing separates them.
- **Hold the Fords, the flags on the fords and the river elsewhere.** 150
  from their foot and 370 from the player's (eight dice): they are on the
  fords first, the blocks that stay win 0 of 8 and the standard commander
  6. 300 from theirs and 220 from the player's (four dice): the blocks that
  stay win 4 of 4, the standard commander 0 of 4, and all the foot massed
  at the middle ford 0 of 4. At 230 and 290, as drawn, both win.
- **Two Narrow Bridges on the Bridge at Dawn's field** (a ford 320
  upstream, a rise behind both bridges; eight dice). Two sword blocks over
  the ford won 3 of 8 where the standard commander won 4: foot is half a
  minute wading round, and is not horse when it arrives. So the ford
  went, and the bridges are again the only way over.
- **Two Narrow Bridges, Gun Hill as a fourth flag** the player starts
  with, to slow the drain (eight dice): the standard commander 1 of 8, the
  west bridge 1 of 8.
- **Two Narrow Bridges, the west bridge without the barrage:** 4 of 8
  (eight dice); the standard commander with the barrage on the west guard,
  2 of 8.
- **The Great Battery, the lanes level with the battery** (566 from the
  guns): the whole line at the battery won 1 of 4, by the edge of the
  field to a lane 0 of 4, straight to a lane 0 of 4. Their whole line, and
  then their guns, come to the lane, and the march there costs 37 resolve
  to three flags' drain.
- **The Great Battery laid out as Open Ground is,** the battery to the west
  and two flags to the east: the whole line at the battery won 4 of 4,
  losing 36%, because their line marched east to the free flags and their
  guns, which deploy in the middle, were still limbered 250 from the hill.
  The battery has to be where their guns already are.
- **The Great Battery, every flag theirs from the start,** so their line
  stays before the guns: 0 of 4 for every play, the frontal one in 0.9
  minutes. **Two flags, the battery and a mill in houses beyond the guns:**
  0 of 4 for every play; their line and guns come to the mill, and it is an
  even fight the standard commander loses.
- **The Great Battery, the barrage on the battery's guard:** 5 of 8 (eight
  dice), as without it.
- **Push of Pike, the three flags on the crest:** the standard commander 4
  of 4 with three stars in 1.1 minutes. **One flag at the crossroads:** 8
  of 8 with three stars in 0.9 (eight dice). The flags have to be where
  marching to them gives up the rise.

Found drawing them, and open:

- **Hold the Fords teaches staying, not where to stand.** What separates
  the plays is leaving the fords (1 of 8) from keeping a block on each (8
  of 8); the standard commander, which moves its blocks as the attack
  shifts, wins 7. Nothing was found for a Medieval defender in reach or
  height. And where the river lies decides it as much as the play does
  (above): 80 further from the player and the blocks that stay lose every
  time.
- **No commander on the ladder rides round at The Cuirassiers.** A
  regiment crosses by the ford nearest its way (`Terrain.path`), which for
  everything aimed at their line is the middle one. The drill rides round;
  the ladder's 62% is the frontal crossing.
- **No AI commander calls the barrage,** so at the bridges only the drill
  does. And the standard commander attacks both bridges at once.
- **The standard commander spreads at The Great Battery,** a block to each
  flag nobody threatens (`AI._allot`), which is the naive play there.
- **Their guns leave the hill.** The AI's guns go 170 behind the flag it
  most wants, and a flag it doesn't hold comes first: when a lane is not
  theirs and nobody is in reach, the batteries limber up and set off for
  it, at 16 a second.
- **The bridges and the battery are hard:** the standard commander wins a
  quarter of each, and the person-paced one none.
- **Push of Pike is short,** and no field tried lengthens it with the
  lesson intact (four dice each; the standard commander's minutes, then
  the rise and the charge). Three streams across their approach: 1.4, and
  the charge wins 3 of 4 where it won 1 of 8. The flags 70 nearer the
  player and the rise with them: 1.4, charge 4 of 4, rise 2 of 4. The rise
  170 behind the flags: 1.3, rise 4 of 4, charge 1 of 4. 185 behind: 1.1.
  200 behind: 2.2, but the rise wins 1 of 4, its shot reaching 12 past the
  flags. The flags 400 apart, not 250: 1.8, charge 4 of 4, rise 0 of 4.
  The approach is 13 seconds whatever is drawn on it, and the meeting
  settles it.

#### Which older scenarios are left

Hammer and Anvil and Riders at Dawn are still seeded: Hammer and Anvil's
ladder rises through every rung, and neither brief names ground the seed
doesn't give. The three sieges are fought on the castle. Note that `roads`
is a river map: no designed scenario is on one now.

Found measuring the seeded fields on 11 November (the drawn fields answer
the first two for these eras, and the third):

- **A frontal assault into rifles.** The one thing the Rifle era needed was
  that walking straight at rifles is suicide. In its Skirmish an AI player
  that walks straight in, without holding or flanking, wins 2 of 16 and
  loses 96% of its men, where the balanced one wins 11 of 16. On Open
  Ground it still wins 7 of 8, losing 75% of its men to the balanced
  player's 61%: six rifles against four and two guns is enough, and the
  stars, not the win, carry the cost.
- **The AI walks rifles and line onto fords it already holds.** `AI._rifle`
  sends them to the flag itself once it advances, so they stand in the water
  within reach of the far bank; the rule that foot on a flag of their own
  fight what comes within their reach is in `AI._foot` only. A person
  learns to stand back from the bank. Changing it would move the Gettysburg
  and Waterloo recordings, so it waits for a versus measurement of its own.
- **A passive line in square stalls Receive Cavalry.** The idle player's
  squares outlast the horse, and the battle runs to nine minutes before the
  late drain decides it, once in four for the idle player. On the drawn
  field their general keeps a flag, and the idle player loses in 3.4
  minutes.

A garrison that does nothing holds the Last Keep two times in three:
standing in the bailey is a defence. Building them, three things were
found and fixed: every regiment at a gate rammed it at once, so it fell in
twenty seconds; battlements that stopped only half lost the archery duel
to two regiments in the open; and garrison archers shooting the nearest
foot rather than the archers shooting them lost it anyway.

Open: in the Pike and Shot Skirmish the slow AI player beats the standard
one (in Medieval it doesn't: 50% and 53%). The first musket design made a
volley more accurate close in; the slow player's muskets walked in further
before firing, so slow won 64% to standard's 31%. Auto-fire always shoots
at the edge of range, so the falloff punished holding ground; it was
removed, which narrowed the gap but did not close it. Separately, pikes in
the line take the enemy general as a target whenever he is within reach
(pikes hit horse 2.5×), in both eras.

Every briefing (and each card in the scenario list) shows the field as it
will be fought, both armies deployed: the battle's own map, drawn small.

A scenario may give the player abilities, start them holding every flag,
let them deploy further forward (`deploy_depth`; no scenario does since the
fords were drawn), and end on the flags at a deadline. They are data in the
packs.

Measured 2026-10-30 against the AI players of the luck study: every
scenario is won by some ways of playing and lost by others (Hold the Fords
is won by the patient players and lost by the ones that throw the line
forward; Riders at Dawn the other way round), and no AI player averages
three stars. On a fixed map the AI players' results barely vary with the
dice, so an army composition tends to be all or nothing for them; the
stars, not the win rate, carry the difficulty.

### Next: gates that matter (not built)

The owner played The Breach at Greyhold on 7 November 2026: the only thing
to do was aim the guns at their guns, then shoot out their muskets. It felt
like a slog with no threat, once their horse had died at the start. Reading
the code (not yet measured) says why:

- **Guns clear the walls for free.** Guns reach 430; muskets on the wall-walk
  reach 212, with the height. Battlements stop 70% of arrows and shot
  (`Terrain.cover`) and nothing of a cannonball (`Battle._blast`). The
  garrison's gun outranges yours (537) but is one against three.
- **The garrison never threatens you.** Its foot fight only what is inside
  (`foot_foes` in `AI.decide`). Its horse is the only part that comes out, and
  it comes alone and early.
- **The gate is a health bar.** `Battle._ram` costs the ram nothing from the
  gate itself, and `_hit_gate` does nothing but open the way.
- **Nothing forces your hand.** Six minutes, no enemy coming, and flags that
  don't drain in a siege. The safe line is always the best line.

The direction, agreed on 8 November 2026: **make the gate a door both sides
gamble on.** The steps are in order, and the numbers are starting values to
tune by measuring.

1. **Measure the slog first: a gun-line player. Built and measured, 12
   November 2026.** `Fights.GunLineCommander` plays what the owner played.
   Its guns stand straight out from the gate, halfway between the reach of
   the shot on the wall-walk (muskets 212, archers 287, with the height) and
   their own 430, and shoot enemy guns, then shooters. Everyone else stands
   behind them and fights only what comes within 200 of the guns. When no
   enemy shooter is left fighting, the guns bombard the gate and the foot
   ram it; once it falls, the AI takes the army on to the flags.
   `tests/gun_line.gd` fights it and the standard AI player, which assaults
   with everything, on the same eight dice (`tests/studies.sh NAME siege`):

   | Siege | Player | won | minutes | men lost | walls clear | outer gate | keep gate |
   |---|---|---|---|---|---|---|---|
   | The Storming of Duskwatch | gun line | 8 of 8 | 4.5 | 36% | 2.0 (8 of 8) | 3.2 (8 of 8) | 4.5 (5 of 8) |
   | The Storming of Duskwatch | standard | 2 of 8 | 3.8 | 95% | 2.8 (2 of 8) | 1.1 (8 of 8) | 5.6 (1 of 8) |
   | The Breach at Greyhold | gun line | 8 of 8 | 3.5 | 17% | 1.4 (8 of 8) | 2.3 (8 of 8) | 3.1 (6 of 8) |
   | The Breach at Greyhold | standard | 4 of 8 | 2.9 | 84% | 1.9 (4 of 8) | 0.8 (8 of 8) | 1.9 (3 of 8) |

   Times are medians, in minutes, over the battles where it happened. What
   the owner felt is measured: the gun line never loses, and it costs a
   fifth to a third of the men an assault costs. The assault has the outer
   gate down in about a minute, then loses most of its men with the walls
   still manned. Target: after step 2 it costs more men or time than a mixed
   assault, and after step 3 it can lose.
2. **Rules only, no AI.**
   - **The gatehouse shoots the ram.** While a gate stands, it fires on the
     regiment `_ram` picks. It can't be silenced, and it stops when the gate
     falls. Both gates do this. Start at about a third of a 48-man regiment
     over a ram alone (about 156 s for the outer gate, at 0.04 per man per
     second). Ramming becomes quick and bloody; guns stay safe and slow. Show
     it with the existing arrows so it can be seen. The holder gets it in The
     Last Keep too, so measure that one again.
   - **Battlements take half of each cannonball** (and barrage shell) on the
     wall-walk. `_blast` kills whole men, so halve the kills. If that takes a
     random draw, draw only for men on the wall-walk, so open-field recordings
     stay put.
   - **The gate can be read.** A pure `Battle.gate_pressure(g)`, sharing its
     choice of ram with `_ram`, gives what is battering the gate and how fast.
     The bar in `units_view.gd` shows how long the gate has left. The briefs
     and the help in `main.gd` say the rule in a line.
3. **The garrison's answer,** in `ai.gd`.
   - **Sally.** The garrison comes out through its own gate at guns left
     unguarded, instead of its horse riding out alone. The gate is open while
     the holder's men are in the gateway, and open to everyone: today
     `Terrain.walled` lets only the holder through, whatever is happening. So
     a sally risks the castle. The attacker has to guard the guns, and can
     catch a sally and storm in behind it. There is no new control, and the
     player gets the same gamble in The Last Keep. This moves the siege
     recordings once.
   - **A relief column at a stated time**, up the road behind the guns. A slow
     siege runs out of time and the guns must face two ways. `Battle.arrivals`
     already works on any battle, but `Scenarios.make_battle` reads
     `arrivals` only for grand battles, in hours. `AI.decide` also makes the
     whole holding side a garrison, so a relief force would just walk to the
     gate; it needs orders of its own.

An idea not in the agreed order: make the moment the gate falls count, with a
shock to the garrison's resolve and its foot charging into the gateway.
Consider it once the steps above have been measured.

All of this belongs to the fortifications module when the migration gets
there (`ARCHITECTURE.md`, step 7). Until then it goes in the core, kept
together so it moves out whole.

## Grand battles

The second way to play. Quick battles and the campaign are arcade: one
screen, a few regiments, three minutes. A grand battle is a historical
day: a field several screens across, twenty blocks a side, armies that
arrive along the roads through the afternoon, and about fifteen minutes
of play. The fun is different: not reflexes at one ford but where to
send the next division when it comes up the road, and when to give
ground.

**The scale.** A block is a brigade, not a regiment; the rules are the
same. The field is 3200 × 2200, about 2.5 × 2.7 quick-battle fields,
drawn by hand from the real ground. The clock shows the hour of the
historical day (an hour is 78 seconds at Gettysburg, 90 at Waterloo), and dusk ends it.

**The pace.** Fights are stretched to fit the day: volleys do 0.4 of
their damage and nerve comes back at 0.4 of its rate, so a brigade
firefight lasts the better part of an hour of the day. A volley's shock is
not stretched, so brigades break and rally long before they are shot to
pieces, as they did.

**Keeping it calm.** More units must not mean more stress:

- The battle opens paused, and orders work while paused, as always.
- Time runs at 1×, 2× or 4×; the marches are long, the fights are not.
- A drag on empty ground with nothing selected pans the map; with two
  fingers it always pans, and pinching zooms. On a computer: the wheel or
  a trackpad pinch zooms where the pointer is, a middle-drag or a
  trackpad scroll pans, the arrow keys move the view, and shift-drag
  still box-selects.
- A minimap in the corner shows the whole field, both armies and the
  view; tap or drag on it to look there.
- Blocks belong to divisions. Double-tap a block to select its division,
  then drag one arrow and the division forms its line across it.
- **Its own command.** With blocks selected, tap a named flag and they
  take it and hold it on their own: the same AI the enemy uses forms them
  square to their approach, fights what comes, and holds the ground once
  there. A gold diamond over the banner marks them; any order of yours
  takes a block back. This is how a corps commander fights: send a
  division to the wood and turn to the next problem.
- A routing brigade is named ("The Iron Brigade is running!") and ringed
  on the minimap, since it may be off screen.
- Arrivals are announced ("Wadsworth's Division comes up the
  Emmitsburg Road"), and a gold ring pulses on the minimap where they
  come on.
- The briefing lists the day's order of march, both sides, by the hour.
- A block given no orders stands, faces what comes and fights it. Fresh
  divisions march up their road to a mustering point and wait for you.

**Resolve.** A rout costs half what it does in a quick battle, since there
are three times the blocks, and the four-minute late drain is off. Flags
don't drain resolve; they decide at dusk, like a siege's.

**History as a test.** The enemy follows its historical orders: each
division has its objectives in order, and takes the next once it holds the
last. A division forms its line square to the way it is going, and once
there, square to the nearest enemy; its batteries unlimber short of the
objective as soon as anything is in reach. Fought computer against computer, a battle should come out roughly
as it did in history; `tests/luck_skill.gd` measures how often it does,
alongside the usual skill ladder. If a historical day plays out as history
with nobody steering, and a good commander can do better, the scenario
works.

### Gettysburg, the first day (1 July 1863)

You are the Union. Buford's two cavalry brigades hold McPherson Ridge west
of town at 8:00 against Heth's division coming down the Chambersburg Pike.
The I Corps comes up the Emmitsburg Road from 10:00, the XI Corps up the
Taneytown Road from 12:30. The Confederates keep coming: Rodes from Oak
Hill to the north at 13:00, Early down the Harrisburg Road at 15:00,
Pender behind Heth. Historically the Union line broke at about 16:30 and
fell back through the town to Cemetery Hill, and held it.

- **Win:** hold Cemetery Hill at dusk (19:30), or break their army.
- **Stars:** also hold Seminary Ridge at dusk; lose no more than 45% of
  your men.
- **Era:** rifles. Rifled muskets reach farther than smoothbores (230
  against 170) and hit more often (accuracy 0.4 against 0.3); cavalry
  hits them 1.3× rather than musketeers' 1.8×, since a rifled brigade can
  form and fire with the bayonet fixed.
- **Veterans:** the Confederate brigades carry one star each, for the
  Army of Northern Virginia's size and confidence that summer.

Measured (`tests/luck_skill.gd --scenario=gettysburg`, four dice per
commander, the enemy at its historical orders):

| | idle | slow | standard | sharp |
|---|---|---|---|---|
| Union wins | 0% | 25% | 25% | 50% |
| Union holds Cemetery Hill at the end | 25% | 25% | 25% | 50% |
| Union holds McPherson Ridge at the end | 0% | 25% | 25% | 25% |

The Confederates took Oak Hill and Barlow's Knoll in every run, and the
town in all but one, as on the day. A defeat usually comes between 15:00 and 17:00, when the
Union army breaks; historically it broke at about 16:30 and fell back to
Cemetery Hill. Holding the hill means doing what Howard did: keeping
von Steinwehr's division there and giving up the western ridges in time.

### Waterloo (18 June 1815)

You are Wellington, on the ridge of Mont-Saint-Jean with Hougoumont, La
Haye Sainte and Papelotte held out in front. Napoleon's corps go in at
their historical hours: Reille at Hougoumont from 11:30, the grand battery
from 12:30, d'Erlon's four divisions at 13:30, Ney's cuirassiers at 16:00
and 17:00, Lobau and the Young Guard against the Prussians at Plancenoit,
and the Middle and Old Guard at 19:30. Bülow's Prussians come out of the
Paris Wood at 16:30, Pirch's at 18:00, Zieten's by Smohain at 19:00; they
are yours to command.

- **Win:** hold Mont-Saint-Jean at dusk (21:00), or break their army.
- **Stars:** also hold La Haye Sainte at dusk; take Plancenoit.
- **Era:** Napoleonic line infantry: smoothbore muskets (range 170) and
  the bayonet, and **squares**. Standing line infantry forms square when
  enemy horse comes within 240 and keeps it until none is within 330. In
  square it has no flank or rear, a charge doesn't land, horse hits it at
  0.35, and only one face fires (half a volley); marching breaks it, and
  horse that reaches a line before it forms catches it in line.
- **Quality:** the French carry two stars (the Guard two more); four of
  Wellington's brigades are raw, a star below the line (the
  Dutch-Belgians, the Nassauers and the Hanoverian militia).
- **Held back:** a corps whose hour has not come keeps to its ground
  unless the enemy comes near; horse held back rides at an enemy within
  500, as a cavalry reserve does.

Measured (four dice per commander):

| | idle | slow | standard | sharp |
|---|---|---|---|---|
| Allied wins | 0% | 100% | 75% | 75% |

The French take Hougoumont in every run, as they never did on the day.
Open: the slow commander does better than the quick ones, because the
AI's defenders counterattack off the ridge into the French columns; a
person holding the crest does not have that habit, so the scenario is
tuned to the quicker AI's result. Each AI-against-AI run first found a
real problem: Allied horse riding down the grand battery unopposed (the
French cavalry reserve now answers), and a French army a third short of
its order of battle.

## Play over time

What the game should feel like at each time horizon, as measures the
studies compute and targets they are judged against. The frame: decisions
should matter and not be monotonous, and their consequences should last
yet be reversible with effort; and killing is not everything.

Every measure is read from a battle's trace (one sample a second) and its
order log, fought through the same loop the game uses. A target is a band
the studies report against, not a check the suite enforces: balance is
judged, then changed deliberately.

| Horizon | Question | Measure | Target |
|---|---|---|---|
| The moment (seconds) | Can you see it coming? | warning: seconds a regiment had been aimed at one of yours before the blow landed | median 4 s or more; under a fifth of blows unannounced |
| The moment | Is there always something to do? | longest quiet stretch after the first clash: no block engaged and nothing fired | under 10 s in a quick battle |
| The engagement (a minute) | Do decisions matter? | decision impact: take one of the player's orders out of the log, fight again, compare | at least a third of orders move the final margin by 5 or more |
| The engagement | Do they last? | persistence: an order's effect on the margin at the end over its effect 20 s after | 1 or more on average: effects grow or hold rather than wash out |
| The battle (minutes) | Does skill win? | the ladder (idle, person, standard, sharp) in win rate, and skill's share of the outcome | rising up the ladder; skill's share over half |
| The battle | Is it decided early? | lead changes; comebacks: battles won by a side that was behind by 0.15 after the first clash | lead changes 0.5 or more; comebacks 15–35% |
| The battle | Is it short? | battle length | quick battles 2–4 minutes |
| The run (twenty minutes) | Do consequences carry? | how much a costly win (40% of men lost) lowers the next battle's win rate | a real drop, but the next battle is still winnable more often than not |
| The day (a grand battle) | Does history hold, and can you beat it? | how often the AI-against-AI day ends as history did; the ladder | history most of the time with nobody steering; skill still rising |

How far the AI can be trusted as a stand-in for a player is its own
question, measured alongside: see the AI audit below.

**Every older table in this document was measured at the wrong step.**
Until 1 November 2026 the tests and studies stepped the battle at 1/15 s
while the game steps at 1/30 s, and the two are different games: 6 of the
15 campaign battles in the suite change winner between them. The suite,
the studies and the screen now share one loop at the game's step
(`scripts/battle_run.gd`). The older tables stay below as a record of how
the design got here, and are not current.

### Measured, 7 November 2026

**The dice had been fighting the same battle.** A battle's own random
numbers scatter only cannonballs, so in a battle without guns every die
was one battle, and a cell of four dice could read only 0% or 100%. The
studies' dice now also set when each commander first looks, a few steps
into its think (`Fights.seats`). On the knife edge that is another battle:
Hold the Fords, standard against its attacker, over eight such offsets is
5 won and 3 lost. Die 0 is the old timing, so the recorded battles did not
move. Everything in this section is measured this way, the old AI too. A
think is 23 steps, so 23 dice on the first seat's moments come round again;
each such lap shifts the player's first look a step more, so the dice past
it fight other battles, not the same ones again (the suite checks 529).

Every quick scenario and campaign battle, AI against AI through the game's
own loop (`tests/luck_skill.gd`, reported by `tests/play.py`; `tests/studies.sh
NAME ladder planner` fights them all): eight dice for each quick scenario,
two draws of eight dice for each campaign battle and Skirmish. Win rates for
the player's commander, the enemy at its persona, both under the AI as it
now stands:

| Battle | idle | person | standard | sharp | planner | minutes | lead changes | orders a minute |
|---|---|---|---|---|---|---|---|---|
| Millbrook Ford | 0% | 62% | 50% | 81% | – | 1.9 | 0.6 | 25 / 82 |
| Ashwood | 0% | 44% | 69% | 75% | – | 1.6 | 0.4 | 23 / 95 |
| Two Bridges | 0% | 31% | 94% | 100% | – | 1.4 | 0.4 | 27 / 126 |
| Saltmarsh Road | 0% | 19% | 19% | 19% | – | 1.5 | 0.4 | 28 / 121 |
| Marshal's Ridge | 0% | 0% | 50% | 38% | – | 1.2 | 0.1 | 27 / 152 |
| Skirmish | 0% | 0% | 69% | 75% | 100% | 2.2 | 0.2 | 27 / 89 |
| Hold the Fords | 0% | 38% | 25% | 38% | 50% | 2.2 | 1.2 | 23 / 53 |
| Hammer and Anvil | 0% | 50% | 75% | 88% | 100% | 1.7 | 0.8 | 26 / 75 |
| Two Narrow Bridges | 0% | 0% | 12% | 0% | 0% | 1.4 | 0.1 | 26 / 97 |
| Riders at Dawn | 0% | 38% | 0% | 0% | 50% | 1.6 | 0.1 | 22 / 91 |
| The Storming of Duskwatch | 0% | 88% | 25% | 25% | 25% | 3.8 | 0.2 | 23 / 39 |
| The Last Keep | 50% | 75% | 62% | 75% | 62% | 3.3 | 0.9 | 20 / 27 |
| Skirmish (Pike and Shot) | 0% | 75% | 75% | 75% | 100% | 1.6 | 0.9 | 15 / 61 |
| Push of Pike | 0% | 75% | 50% | 75% | 100% | 1.9 | 0.1 | 28 / 100 |
| Shot at the Fords | 0% | 100% | 38% | 62% | 75% | 2.1 | 0.9 | 25 / 68 |
| The Cuirassiers | 0% | 75% | 25% | 62% | 100% | 1.6 | 0.4 | 28 / 95 |
| The Great Battery | 0% | 0% | 12% | 12% | 75% | 1.6 | 0.4 | 26 / 101 |
| The Breach at Greyhold | 0% | 100% | 50% | 62% | 75% | 2.9 | 1.5 | 26 / 56 |

Minutes and lead changes are for the standard commander; orders a minute
for the person-paced one, then standard. The planner (see the AI audit)
was fought on the quick scenarios only, one draw of eight dice each.

The ladder is idle, person, standard, sharp. The person-paced commander
(`Commander.PacedCommander`) is the stand-in for a player: it looks every
2 s and gives at most one of the orders the AI would, the most urgent
first (the regiment nearest an enemy), 15–28 orders a minute where
standard gives 27–152.

The same ladder with the AI of 1 November 2026, the yardstick kept in
`tests/ai_baseline.gd`, on both sides:

| Battle | idle | person | standard | sharp |
|---|---|---|---|---|
| Millbrook Ford | 0% | 44% | 88% | 100% |
| Ashwood | 0% | 56% | 75% | 69% |
| Two Bridges | 0% | 25% | 100% | 94% |
| Saltmarsh Road | 0% | 6% | 38% | 44% |
| Marshal's Ridge | 0% | 0% | 19% | 25% |
| Skirmish | 0% | 6% | 75% | 75% |
| Hold the Fords | 100% | 38% | 38% | 25% |
| Hammer and Anvil | 0% | 25% | 88% | 100% |
| Two Narrow Bridges | 0% | 0% | 0% | 0% |
| Riders at Dawn | 0% | 88% | 100% | 100% |
| The Storming of Duskwatch | 0% | 100% | 50% | 88% |
| The Last Keep | 88% | 100% | 62% | 88% |
| Skirmish (Pike and Shot) | 0% | 38% | 56% | 56% |
| Push of Pike | 0% | 62% | 62% | 88% |
| Shot at the Fords | 0% | 25% | 38% | 50% |
| The Cuirassiers | 0% | 38% | 88% | 100% |
| The Great Battery | 0% | 25% | 62% | 100% |
| The Breach at Greyhold | 0% | 100% | 75% | 88% |

Against the targets:

- **The ladder rises at its ends, not in its middle.** Over every battle,
  idle wins 2%, person 44%, standard 49%, sharp 57% (the yardstick: 8%,
  38%, 62%, 70%). It rises through every rung in 7 of the 18 battles, the
  yardstick's in 12. In five of the other eleven a rung stands 12 points
  below the one beneath it (Millbrook Ford, Marshal's Ridge, Hold the
  Fords, Two Narrow Bridges, the Last Keep): one battle in eight, within
  the noise of a cell. In the other six the person-paced commander
  beats standard by 25 to 63 points: the Breach, the Cuirassiers, Shot at
  the Fords, Push of Pike, Riders at Dawn and the Storming. That is its
  role, not its pace. Against the same enemy it wins 58% of the eleven
  designed scenarios where the AI as the player wins 34% (88 battles each),
  and loses the campaign battles 32% to 58% (40 each). But fought as the AI
  from both ends against the AI as it is, its pace is no stronger: one
  order every 2 s wins 44% of 416 battles, one order a look 48%, two 51%
  (±5). Attacking a held crossing it does better; holding one, or
  commanding a campaign army, worse (with it as the enemy, the AI as the
  player wins 59% of the designed battles, against 41% when the enemy is
  the AI itself). Nor is it that an attacker should keep to its plan: the
  AI thinking its line out only every 2 or 4 s while time is not on its
  side, and at every look while it is, wins 51% and 49% of 416. What the
  person-paced commander does better there is not yet known.
- **Some battles got much harder for the player's side.** Riders at Dawn is
  won by no AI player but the person-paced one (38%) and the planner (50%):
  the enemy there is the AI at its strongest (the yardstick as the player wins
  it every time against the yardstick, 25% against the AI). The Great
  Battery is the reverse: the AI as the attacker is the weaker one there
  (it wins 12% against the yardstick's enemy, where the yardstick wins
  62%). Two Narrow Bridges is still lost by nearly every AI player.
- **Battles are short and settled early.** They last 1.2–3.8 minutes, most
  under 2.5, against a target of 2–4, with 0.1–1.5 lead changes.
- **You see it coming.** A blow counts as announced when its attacker was
  closing on your side beforehand, by the rule the screen draws its red
  arrows by (`Telemetry.closing_on`: the regiment it is ordered to attack,
  or the one where its march ends). Measured that way, nearly every blow
  is announced (under a fifth unannounced everywhere), with a median
  warning of 4–20 s against a target of 4 (about a minute in the Last
  Keep). (A first version of the measure
  counted only blows on the very regiment an arrow pointed at, and called a
  third to a half of blows unannounced; in a line the blow often lands on
  that regiment's neighbour.)

### The AI audit

What the AI is: a reactive commander with a plan. Every 0.75 s it works
out where its line goes (`AI.allot`): first to each flag it holds that the
enemy is coming for, enough to outweigh what comes; then to the flags it
can take, the least held and nearest first, in strength, and none to a
flag it hasn't the strength left to make good (no blocks sent one at a
time to be beaten in turn). Blocks bound for a flag that still needs them
keep it. Spare blocks stand behind the defence while time is on its side
(the clock or the drain would decide for it) and go for a flag otherwise.
Each regiment's role then picks an order: foot fight what comes within
their reach and otherwise go to their flag, or while holding stand just
short of it on their own side; a block in melee fights whoever it is
fighting; idle horse take a flag no enemy stands near; shooters keep
behind the line, behind pikes where there are any. In a grand battle,
divisions take objectives in order, as before. It has no lookahead and no
read of the player's plan.

**Against fixed plans** (`tests/plans.gd`: each of the player's regiments
sent to one flag or left to the AI's line, the standard commander fighting
the plan out on three dice, twenty-five or so plans each, the dice as
above):

| Battle | the AI's own line wins | plans that win all three dice | plans that win none |
|---|---|---|---|
| Hold the Fords | 1 of 3 → 1 of 3 | 14 of 26 → 5 of 25 | 3 → 10 |
| Hammer and Anvil | 2 of 3 → 2 of 3 | 13 of 25 → 11 of 23 | 0 → 0 |
| Push of Pike | 2 of 3 → 1 of 3 | 7 of 22 → 8 of 22 | 1 → 5 |

In each cell the yardstick comes first. In Hold the Fords the enemy is now
hard to beat with a fixed plan: without the line's allotment it was beaten
on all three dice by 16 of 25. The plans that do beat it put each foot
block on a ford of its own; the AI's own line wins once in three. In Hammer and Anvil just under half the plans beat it on every die,
from 14 of 23 before foot holding a flag fought what reached them: there a
plan places only the two foot blocks, and the player's three horse fight
under the AI whatever the plan.

**Against the yardstick** (`tests/versus.gd`, `tests/studies.sh NAME
versus`): the AI as the player against the yardstick as the enemy and the
other way round, and the yardstick against itself for the base rate. On
the designed battles (eight dice for each quick scenario, two draws of
four for each campaign battle; 256 battles from the two ends) the player
wins 61% of the yardstick's own battles; with the AI as the player 47%,
with the AI as the enemy 41%: 135 of 256 from both ends, 53% ±6. In mirror
Skirmishes over twenty fields of each era, where both sides are the same
army and persona, the player wins 48% of the yardstick's, 60% with the AI
as the player and 42% with it as the enemy: 94 of 160, 59% ±8. Together,
229 of 416, 55% ±5: stronger, most of it as the enemy, and in Hold the
Fords from both ends (as the player it wins every time against the
yardstick's enemy; as the enemy it holds the yardstick's player to 12%).

The change that made it so: foot holding a flag of their own used to fight
only what came within 130 of where they stood, so the enemy had to cross to
them, and shooters stood off and shot them for nothing. Now they fight
what comes within their reach. Against the AI as it was, that wins 151 of
256 designed battles and 90 of 160 mirror Skirmishes from both ends, 58%
±5.

Tried and not kept, each against the AI of its day from both ends (256
designed battles and 160 mirror Skirmishes, ±5 on the two together; a 4 s
plan clock, 1 November, was weaker, 42% against 50%):

| Change to the line | designed | mirror |
|---|---|---|
| leaning each of the allotment's choices to what is already under way, or the general keeping behind the main body rather than the middle of a split line (2 November, each) | 46–52% | 46–51% |
| the whole line to the first flag that needs it | 48% | 49% |
| one flag taken at a time | 45% | 46% |
| at least two blocks to a flag it goes to take | 48% | 47% |
| a block left on every held flag while time is on its side | 47% | 48% |
| foot keep no hold on the enemy they are closing on | 49% | 49% |
| every flag that needs blocks sent some, whether or not it can be made good | 56% | 42% |
| the threat to a flag read from where enemies stand, not where they are going | 55% | 48% |
| foot reach 50 farther | 50% | 55% |
| shooters behind the nearest foot, not pikes first | 53% | 51% |
| foot that take their place face the way they walked, not the nearest enemy | 50% | 49% |
| idle horse wait rather than take an empty flag | 46% | 49% |
| the AI at a person's pace: one order every 2 s | 46% | 41% |
| one order a look | 49% | 46% |
| two orders a look | 50% | 52% |
| the line thought out every 4 s while time is not on its side, at every look while it is | 50% | 47% |
| the same, every 2 s | 50% | 54% |

None is better from both ends beyond the noise. Without the shooters',
the facing or the idle horse's rule the AI is no weaker either; they stay
for what a player expects to see (archers behind pikes, a block that faces
the enemy, horse that take an empty flag), not for strength.

**The planner** (`Commander.PlannerCommander`, see "Solving the game" in
ARCHITECTURE.md) tries, every 20 s, the AI's allotment and the whole line
to each flag, each on a copy of the battle fought 30 s ahead, and keeps
the best. On the AI as it now stands, on eight dice of the thirteen quick
scenarios (104 battles), it wins 70% (73 of 104) where standard wins about
40%, sharp 50% and person 55% on the same scenarios. It is the same AI
giving the same kinds of order; only where the line goes is chosen by
looking ahead. One rollout per choice does as well as two (76% and 70% on
the AI of 2 November), but a 10 s look ahead does no better than standard:
it has to see about 30 s on, which costs about seven times a battle. Also
trying the line shared out, each block to a flag of its own (what wins Hold
the Fords as a fixed plan), won 73 of 104 where without it 79, on the AI
before its foot fought for a held flag: not kept.
As the enemy it is barely harder than the AI, and on a budget that fits a
frame no harder (ARCHITECTURE.md), so the game's enemy stays the AI.

So:

- **As an opponent it is harder to beat on purpose, where the plan is the
  lesson.** Concentrating on a ford no longer beats Hold the Fords on
  every die; the enemy finds the empty one, and its foot fight for the ford
  they hold. Where the lesson is tactics (horse round the flank, pikes
  against horse), fixed plans say little.
- **As a stand-in for a player it is fit for more, and still not for
  everything.** Fit for regressions, for comparing scenarios, for the
  history checks; and with the person-paced commander on the ladder, a
  rough read of what a player at a person's pace can do. Not yet for
  saying exactly how hard a battle is: a cell of eight dice reads in
  eighths, and the AI attacks a held crossing worse than the same AI at a
  person's pace.
- **The plan is still worth more than the dice.** Plans that lose on every
  die rose from 3 to 10 of 25 in Hold the Fords: the choice matters more.
- **Where the AI falls short is choosing where its line goes as the
  attacker**, not carrying it out: the planner's 70% against standard's 40%
  says so, and so does the person-paced commander's lead in the designed
  battles. The planner's search costs about seven battles' worth of steps
  per battle, fine for the studies and too slow to run live as it stands;
  as the enemy it would buy little. Where it could earn its cost is the
  player's side: the ladder's top rung, and the divisions a player sends
  off on their own in a grand battle. Open: pikes that face horse.

## Score

1000 per victory, plus 2 per enemy soldier killed, plus 1 per surviving
soldier at the end of each battle, plus a speed bonus for battles won
under three minutes. Best score is kept on the device.

## Architecture (for whoever edits next)

- `scripts/battle.gd` is the simulation and the one writer of battle
  state. Everything else hands it orders (`apply_orders`) and reads it.
- `scripts/ai.gd` is a pure decision: battle state in, orders out. The
  player's side in the headless balance tests uses the same function.
  Where the line goes is a plan (block to flag) that the commander
  (`scripts/commander.gd`) keeps, thinks out with `AI.allot` and hands to
  `AI.decide`. A planner is a commander that picks the plan by trying
  plans on copies of the battle (`Battle.copy`, `BattleRun.copy`).
- `scripts/combat.gd` holds the rules as pure functions over values.
- `scripts/campaign.gd` is pure: run state in, new run state out.
- `scripts/terrain.gd` builds a seeded map, or a grand battle's map from
  a hand-drawn plan (`Terrain.from_plan`), and answers queries about it.
  Each map has its own size.
- `packs/` holds the content as data: `medieval`, `pike_shot` and `sieges`
  are quick battles, and `packs/gettysburg.gd` and `packs/waterloo.gd` are grand battles as
  pure data: the ground, who starts where, when each corps goes in, and
  who comes up which road when. `Scenarios` builds the
  battle from it; the battle raises each arrival at its hour.
  River maps route by banks and crossings; a fortress map routes on a
  16-unit grid (Godot's AStarGrid2D) pulled tight to straight legs, with
  gates open in the plan so a besieger's route ends pressed against the
  gate, which is where it rams. Only the battle writes `gate_broken`.
- The views (`terrain_view.gd`, `units_view.gd`, `minimap.gd`) and HUD read state and turn the battle's
  events into effects and sound; they never write battle state. A grand
  battle's camera (centre and zoom) and minimap are screen state.
- `tests/run_tests.gd` runs headless: rules, pathing, campaign, and
  AI-vs-AI battles that must finish in time.

## Luck and skill (measured)

Measured at the old test step (1/15 s); see "Play over time" for what is
current.

`tests/luck_skill.gd` fights each campaign battle under a ladder of player
commanders of rising skill (idle; slow; standard; sharp, which thinks
faster and blows the Rally horn) and two variants of sharp (reserve: holds
one foot regiment back and sends it onto the flank of whoever a friend is
fighting; hills: puts archers on high ground), × 8 draws (map and enemy
roster) × 3 dice (the battle's own random numbers). `tests/luck_skill.py`
splits the spread of the final resolve margin between them. Among slow,
standard and sharp, measured 2026-10-30:

| | first build (0cab6d9) | slower fights, softer panic, no reload luck (3eb5e33) | + line fix, fatigue |
|---|---|---|---|
| commander (same edge everywhere) | 5% | 7% | 21% |
| fit to the map | 31% | 39% | 34% |
| the draw | 48% | 42% | 39% |
| the dice | 15% | 12% | 6% |
| **skill in all** | **36%** | **46%** | **56%** |
| wins: slow / standard / sharp | – | 38% / 46% / 57% | 29% / 34% / 49% |
| lead changes per battle, sharp | – | 0.26 | 0.58 |

What each change bought, from runs that changed one thing at a time:

- **The line fix** (each regiment takes the crossing on its own part of the
  front, instead of crossing paths) took skill from 46% to 55%.
- **Fatigue** left skill's share about where it was (55% → 56%) but doubled
  how often the lead changes hands for the sharp commander (0.34 → 0.58)
  and widened the gap between slow and sharp play (38% → 29% for slow).
- **A reserve pays on some maps and costs on others.** Held back and sent
  in as soon as a friend is pinned, it lifts Two Bridges from 50% to 83%
  and Saltmarsh Road from 8% to 17%, and drops Ashwood, where their horse
  comes early through open woods, from 75% to 38%. Overall it draws level
  with no reserve (49% each). Whether to hold one is a call to make from
  the briefing. Committed late, when a friend is about to break, it
  measured worse everywhere and was removed.
- Tried and dropped: throwing the whole line at one crossing (loses the
  flag race), and a morale shock when fresh troops hit worn ones (no
  measurable gain).

Giving orders at all is decisive: an idle army never wins. Past that, the
draw weighs most, but it is luck you can see: the briefing shows their army
and deployment shows the map before you commit, and the study's commanders
are map-blind AI, so they cannot use it. The dice are luck after you
commit; they are now only cannon scatter. Volleys fall out of step by a
fixed stagger per regiment rather than a random reload.

The last two battles are hard: no AI commander wins Saltmarsh Road or
Marshal's Ridge more than 17% of the time. A player has rewards and the
abilities the study does not use; whether that is enough is for play to
show.

**2026-10-31: the AI holds its objectives.** Until it advances, an army
used to stand in its deployment zone, so a dug-in enemy let the player
walk onto both bridges unopposed. Now it stands just short of each flag on
its own side and its guns cover the most wanted flag. Measured on the
campaign: the sharp AI wins 61% (was 49%), the last two battles became
winnable for it (Saltmarsh Road 38%, Marshal's Ridge 38%, from 8–12%), and
skill's share among slow, standard and sharp fell to 47% (the draw rose to
46%): attacking a held crossing is costly, and which crossings the map
gives you matters more. Two Narrow Bridges is now lost by every AI player;
a person has guns and a barrage they use badly.

Rerun after any balance change:

```bash
for i in 0 1 2 3 4; do /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s tests/luck_skill.gd -- --battle=$i > build/luck/b$i.txt & done; wait
python3 tests/luck_skill.py build/luck/b*.txt
```
