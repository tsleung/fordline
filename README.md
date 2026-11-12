# Fordline

Hold the river crossings. A real-time tactics game of regiments seen from
above: blocks of little soldiers under banners, lines grinding together at
a ford, flanks and broken morale. Five battles make a campaign of about
twenty minutes. Godot 4.5, GDScript, no art or audio files (everything is
drawn and synthesised in code).

Design and rules: [docs/DESIGN.md](docs/DESIGN.md). Every doc, by the
question it answers: [docs/README.md](docs/README.md).

## Play

**In a browser:** https://tsleung.github.io/fordline/ (on a phone, Add to
Home Screen installs it to play full screen and offline). Every push to
`main` that passes `./test.sh` is published there by
[.github/workflows/pages.yml](.github/workflows/pages.yml).

**On this Mac:**

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path ~/github/fordline
```

Or open the folder in the Godot editor and press Play.

**In the browser** (desktop or phone): export, then serve `build/web/`:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --export-release "Web" build/web/index.html
```

```bash
python3 -m http.server 8890 --directory build/web
```

The web build is single-threaded, so any static host works; it needs no
cross-origin isolation headers.

**On a phone as an app:** Android export needs the Android SDK and the
Android export templates (neither is on this Mac yet); iOS export needs
Xcode and the iOS templates. The game already lays itself out for a tall
screen: the field turns a quarter and your army stands on the left.

**Quick battle** on the title screen opens the scenarios: single battles
on designed maps with three stars to earn. **Grand battles** are whole
historical days on fields several screens across, with armies arriving by
road: Gettysburg's first day, and Waterloo.

## Controls

Tap a banner to select it (again to deselect; double-tap for every regiment
of that kind). With nothing selected, drag to box-select. With a selection,
tap the field to move, tap an enemy to attack, or drag an arrow: they stand
where it starts and face where it points. To add a
stop, tap the gold marker at the end of the route, then tap the next spot;
shift-click does it in one click.
Keys: Space pause, A select all, F 2× speed, Esc clear. Right-drag always
gives an order. In a grand battle, drag empty ground to pan, pinch or scroll
to zoom, tap the minimap to look there, double-tap a brigade for its
division, and tap a named flag to send the selection to take and hold it
on its own; the arrow keys pan and F reaches 4×.

## Test

```bash
./test.sh
```

Runs the rules, map and campaign checks, replays a recorded battle to
prove the simulation deterministic, then fights the campaign, every quick
scenario and the grand battles AI against AI, through the same loop the
game uses (`scripts/battle_run.gd`). Each battle must come out exactly as
recorded for the platform the suite runs on (`tests/golden-macos.txt`,
`tests/golden-linux.txt`, which CI uses on a pinned Ubuntu 24.04); after a deliberate change to how
battles come out, `./test.sh --record` records them again for this
platform, in the same commit. The other platform's file is then updated
from CI's report of what it got: each line it fails on says what it was
and what it now is.
Fails on any failed check, any script error or `push_error`, a battle past
its time, or (on CI, where the machine is its own) Waterloo's step over
budget. `./test.sh --quick` fights one seed and skips
the long battles.

Studies, all fought through the game's loop:
- `tests/luck_skill.gd` fights a battle under a ladder of commanders
  (idle, person-paced, standard, sharp; `--policies=planner` adds the
  planner, which tries plans ahead on copies of the battle and fights
  about ten times as long) and prints one row per battle;
  `tests/luck_skill.py` splits the outcome into skill and luck,
  `tests/play.py` reports the measures of play (length, lead changes,
  comebacks, quiet, warning, orders a minute, and with `--impact=N` how
  far one dropped order carries). Each die is the battle's random numbers
  and when each commander first looks.
- `tests/plans.gd` searches fixed plans against the enemy AI: the
  ceiling, and how much a plan is worth.
- `tests/versus.gd` fights the AI against its yardstick, the AI of 1
  November 2026 kept in `tests/ai_baseline.gd`, from both ends of every
  battle; `tests/play.py` reports it. A change to the AI is better when
  it beats the yardstick from both ends.
- `tests/plan_examples.gd` writes the planner's choices as a dataset
  (`spec.json` and `examples.jsonl`, `tests/planner_data.gd`): at each
  re-plan, what its side could see, each choice's rollout score, the
  choice it took, and how the battle came out. Rerun, the same bytes.
- `tests/lessons.gd` asks whether a drawn scenario's ground teaches its
  lesson: it fights the scenario under plays written down, the naive one
  and the one the brief asks for, and prints wins, men lost, stars and
  minutes. `--field` prints the distances the lesson rests on;
  `--on-crossings` fights a river field with its flags moved onto the
  crossings, where a seeded map has them.

`tests/studies.sh NAME ladder plans versus planner lessons` runs any of these in
parallel, as DESIGN.md measures them, from a copy of the tree (so editing
doesn't disturb a long run), into `build/studies/NAME`, with `tests/play.py`'s
report and DESIGN.md's table in its `report.txt`.

See "Play over time" in [docs/DESIGN.md](docs/DESIGN.md).

`tests/shot.tscn` plays a battle on autopilot in a real window and saves
screenshots to `build/shots/` (see the header of `tests/shot.gd`); keep the
window visible while it runs.

## Layout

```
scripts/battle.gd       the simulation; the one writer of battle state
scripts/regiment.gd     one regiment's state and formation geometry
scripts/combat.gd       the fighting rules, pure functions
scripts/terrain.gd      seeded maps and the questions the sim asks of them
scripts/ai.gd           a commander: battle in, orders out
scripts/campaign.gd     the run: pure functions over run state
scripts/scenarios.gd    looks up, checks and builds a scenario's battle
packs/                  the content: eras and scenarios, as data
scripts/battle_screen.gd  input, fixed-step loop, events into effects
scripts/*_view.gd, hud.gd, glyphs.gd, palette.gd   drawing
scripts/main.gd         title, briefing, results, final screens
scripts/sfx.gd          synthesised sound (autoload)
tests/                  headless suite and the screenshot capture
```

## Licence

MIT; see [LICENSE](LICENSE).
