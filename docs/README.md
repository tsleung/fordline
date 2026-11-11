# Fordline — the documentation

Start with the question you have.

| If you want to… | Read |
|---|---|
| play it, run it, test it or publish it | [`../README.md`](../README.md) |
| know what the game is, its rules, modes and scenarios | [`DESIGN.md`](DESIGN.md): pillars, rules, controls, the campaign, quick battles, sieges, grand battles |
| know how it plays, measured | [`DESIGN.md`](DESIGN.md), "Play over time": the targets for each time horizon, what was measured, and the AI audit |
| change the engine or add a mechanic | [`ARCHITECTURE.md`](ARCHITECTURE.md): one writer, the battle loop and seats, recorded battles, modules and packs, solving the game, worked examples for air and navies |
| know what was built when, and why | [`HISTORY.md`](HISTORY.md) |
| know what comes next | [`HISTORY.md`](HISTORY.md), "Open": the agreed order, and what else is open; [`DESIGN.md`](DESIGN.md), "Next": the plans in detail |
| work on it as an agent | [`../CLAUDE.md`](../CLAUDE.md): the rules for editing, and the private paths |

## The code, by file

| File | What it is |
|---|---|
| `scripts/battle.gd` | The simulation; the one writer of battle state |
| `scripts/battle_run.gd` | The one loop that advances every battle: seats, the order log, the trace |
| `scripts/commander.gd` | What commands a seat: the AI with a persona, at a person's pace, or thinking ahead (the planner); or no one |
| `scripts/ai.gd` | The AI: a pure decision, battle in, orders out |
| `scripts/combat.gd` | The rules, as pure functions |
| `scripts/campaign.gd` | The campaign: run state in, new run state out |
| `scripts/terrain.gd` | Maps (seeded, castles, hand-drawn from a plan) and the questions asked of them |
| `scripts/scenarios.gd` | Looking a scenario up, checking it, building its battle |
| `packs/registry.gd` | The content packs, and what a pack and a scenario hold |
| `packs/medieval.gd`, `pike_shot.gd`, `sieges.gd`, `line_square.gd`, `rifle_gun.gd`, `gettysburg.gd`, `waterloo.gd` | The packs: eras and scenarios, as data |
| `scripts/unit_types.gd`, `scripts/regiment.gd` | Kinds of regiment and one regiment's state |
| `scripts/telemetry.gd` | Read-only measures of a battle, and its trace |
| `scripts/main.gd` | The menus |
| `scripts/battle_screen.gd`, `hud.gd`, `units_view.gd`, `terrain_view.gd`, `minimap.gd`, `map_preview.gd` | The battle on screen; they read the battle and never write it |
| `tests/run_tests.gd` | The suite: rules, maps, screens, replays, recorded battles, the step budget |
| `tests/golden-macos.txt`, `tests/golden-linux.txt` | The recorded battles, one file per platform |
| `tests/fights.gd`, `tests/measures.gd` | The commander ladder, and the measures of play |
| `tests/studies.sh` | Runs the studies in parallel from a copy of the tree, into `build/studies` |
| `tests/luck_skill.gd`, `tests/luck_skill.py`, `tests/play.py`, `tests/plans.gd`, `tests/versus.gd` | The studies; `tests/ai_baseline.gd` is the AI of 1 November, frozen, the yardstick `versus.gd` plays against |
| `tests/planner_data.gd`, `tests/plan_examples.gd` | The planner's choices as a dataset |
| `tests/lessons.gd` | Whether a designed scenario's ground teaches its lesson: the naive play against the intended one |
| `tests/shot.gd` | Screenshots from Godot's own window |

## Not in this repo

The owner's verbatim prompts about Fordline are kept in his private
notebook. On his machine `notes/prompts.md` is a symlink to them; it is
never committed here (see `../CLAUDE.md`, "Private paths").
