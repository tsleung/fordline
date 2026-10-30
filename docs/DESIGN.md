# Fordline — design

A real-time tactics game about holding river crossings with regiments of
little soldiers, seen from above on a flat field map. One campaign is five
battles and takes about twenty minutes. Built in Godot 4.5, so it runs in a
browser (desktop or phone) and exports to Android and iOS from the same code.

Every decision here is provisional: it is the studio's call, made to be
played and argued with.

## The thirty-second version

You command a small army: swords, pikes, archers, cavalry, cannons and your
general. Each battle is on a new map with a river, woods and hills, and
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

## Rules

- **Counters.** Pikes stop cavalry. Swords beat pikes. Cavalry rides down
  archers and cannons. Archers and cannons wear everyone down from range.
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
- **Charge.** Cavalry that hits at speed deals heavy damage and a morale
  shock for two seconds, except against pikes from the front.

## Controls (touch and mouse alike)

- Tap a regiment to select it; tap again to deselect it. Double-tap to
  select every regiment of that type. **All** selects the whole army.
- With nothing selected, drag on the field to box-select.
- With a selection: tap the field to move there; drag to draw a line and the
  regiments form up along it, facing the enemy; tap an enemy to attack it.
- Waypoints: a selected route ends in a gold marker. Tap it to pin it (a
  ring with a plus) and the next tap on the field adds a leg from there
  instead of replacing the route; tap it again to unpin. On a computer,
  shift-click the field does the same in one click. Routing a flank force
  around woods or through a chosen ford is what this is for.
- Pause any time; orders can be given while paused. 2× speed for the
  quiet parts.
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
doctrine (longbows, iron shot, steel, warhorses, old banners).

## Quick battle

Scenarios for when there isn't time for a campaign: one battle each, on a
map fixed by design so it can be learned, three to five minutes. A win is
one star; each scenario names two more conditions (a fast win, light
losses, crossings held at the end), and the best is kept on the device.

| Scenario | Ground | Goal | Teaches |
|---|---|---|---|
| Skirmish | a new field each time | break them | two armies made the same; only play differs |
| Hold the Fords | fords, deploy at the river | hold one ford at 3:00 | standing on ground you already own |
| Hammer and Anvil | open woods | break them | pin with foot, ride round with horse |
| Two Narrow Bridges | bridges | hold both bridges at 5:00 | forcing a crossing with guns and a barrage |
| Riders at Dawn | the ridge | break them | pikes against a cavalry army |

A scenario may give the player abilities, start them holding every flag,
let them deploy further forward, and end on the flags at a deadline. They
are data in `scripts/scenarios.gd`.

Measured 2026-10-30 against the AI players of the luck study: every
scenario is won by some ways of playing and lost by others (Hold the Fords
is won by the patient players and lost by the ones that throw the line
forward; Riders at Dawn the other way round), and no AI player averages
three stars. On a fixed map the AI players' results barely vary with the
dice, so an army composition tends to be all or nothing for them; the
stars, not the win rate, carry the difficulty.

## Score

1000 per victory, plus 2 per enemy soldier killed, plus 1 per surviving
soldier at the end of each battle, plus a speed bonus for battles won
under three minutes. Best score is kept on the device.

## Architecture (for whoever edits next)

- `scripts/battle.gd` is the simulation and the one writer of battle
  state. Everything else hands it orders (`apply_orders`) and reads it.
- `scripts/ai.gd` is a pure decision: battle state in, orders out. The
  player's side in the headless balance tests uses the same function.
- `scripts/combat.gd` holds the rules as pure functions over values.
- `scripts/campaign.gd` is pure: run state in, new run state out.
- `scripts/terrain.gd` builds a seeded map and answers queries about it.
- The view (`battle_view.gd`) and HUD read state and turn the battle's
  events into effects and sound; they never write battle state.
- `tests/run_tests.gd` runs headless: rules, pathing, campaign, and
  AI-vs-AI battles that must finish in time.

## Luck and skill (measured)

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

Rerun after any balance change:

```bash
for i in 0 1 2 3 4; do /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s tests/luck_skill.gd -- --battle=$i > build/luck/b$i.txt & done; wait
python3 tests/luck_skill.py build/luck/b*.txt
```
