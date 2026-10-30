# Fordline

Hold the river crossings. A real-time tactics game of regiments seen from
above: blocks of little soldiers under banners, lines grinding together at
a ford, flanks and broken morale. Five battles make a campaign of about
twenty minutes. Godot 4.5, GDScript, no art or audio files (everything is
drawn and synthesised in code).

Design and rules: [docs/DESIGN.md](docs/DESIGN.md).

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
on designed maps with three stars to earn.

## Controls

Tap a banner to select it (again to deselect; double-tap for every regiment
of that kind). With nothing selected, drag to box-select. With a selection,
tap the field to move, drag to form a line, tap an enemy to attack. To add a
stop, tap the gold marker at the end of the route, then tap the next spot;
shift-click does it in one click.
Keys: Space pause, A select all, F 2× speed, Esc clear. Right-drag always
gives an order.

## Test

```bash
./test.sh
```

Runs the rules, map and campaign checks, then fights all five campaign
battles AI against AI on three seeds; fails if any battle runs past seven
minutes or any script fails to compile. `./test.sh --quick` fights one seed.

`tests/luck_skill.gd` and `tests/luck_skill.py` measure how much of a
battle's outcome is the commander and how much is the draw and the dice;
see the end of [docs/DESIGN.md](docs/DESIGN.md).

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
scripts/battle_screen.gd  input, fixed-step loop, events into effects
scripts/*_view.gd, hud.gd, glyphs.gd, palette.gd   drawing
scripts/main.gd         title, briefing, results, final screens
scripts/sfx.gd          synthesised sound (autoload)
tests/                  headless suite and the screenshot capture
```

## Licence

MIT; see [LICENSE](LICENSE).
