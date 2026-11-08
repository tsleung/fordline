# Fordline — history

What was built when, and the decisions along the way. The commit messages
hold the detail; this is the thread through them. Dates are the owner's
local time.

## 30 October 2026: a playable game first

| Commit | What |
|---|---|
| `0cab6d9` | The first playable build, 39 minutes after the first message: a five-battle campaign of river crossings, flags and resolve, flank and rear hits, rally, rewards between battles; a phone layout; a web build; 1,204 checks |
| `3eb5e33` | A study of luck against skill, and the first fixes from it: slower fights, red arrows for enemy intent, morale on the field |
| `80617df` | Fatigue, an enemy line that keeps its share of the front, a reserve |
| `f5b013a` | Waypoints, in the owner's tap scheme rather than the first proposal |
| `ed0abac` | Quick battle: five scenarios, three stars each |
| `60b3e17` | Published from CI to GitHub Pages, as an installable web app |

Decisions: Godot, so one codebase serves phones and the web. The look is
the toy: hundreds of soldiers in blocks. Measure balance with computer
players of rising skill instead of guessing it.

## 31 October: open source, eras and castles

| Commit | What |
|---|---|
| `5fdff05` | One public repo under MIT, built and published by CI |
| `a9b2bf1` | Map previews on every briefing, an in-battle menu, an enemy that moves up to hold its flags |
| `d0d17b7` | Pike and Shot: muskets, era tabs, five scenarios |
| `bfa56d2` | Sieges: walls, gates to ram or bombard, a garrison AI, three siege battles |

Decisions: packs by era; combat only, no economy or building; the
designer's free hand on content, with quick battles as the place to try
variants.

## 1 November: grand battles, an architecture, and measuring for real

| Commit | What |
|---|---|
| `c1678a8` | A drag became an arrow (stand here, face that way) on every device; grand battles: a field bigger than the screen with a camera and minimap, armies arriving by road, divisions on their own command, Gettysburg's first day and Waterloo, squares against horse |
| `1ad2c28` | The architecture: a core engine, modules, content packs, every one a two-way door; air as things in flight between ground units, aircraft as flights that come back, navies as units on water; history serves the fun |
| `f545ff5` | One loop for every battle: the tests had been stepping at 1/15 s while the game steps at 1/30, a different game (6 of 15 campaign battles changed winner). Order logs and replays, 44 recorded battles, measures of play per time horizon, the AI audit |
| `fcfd310`, `c00ef9c` | Recorded battles per platform: Linux and macOS differ in the last bits of their maths, and the battle grows them into different outcomes |
| `8224604` | Ten bugs from a bug hunt (input over the minimap and the bars, Two Narrow Bridges, a general mourned twice, texts, saves, a way out of a campaign) and a fixed warning measure |

Decisions: keep the core the game we started with; a rule that data
switches on is core, a whole mechanic is a module; fail when a battle is
built, never silently; no reinforcement learning yet, a planner first.

## 2 November: documentation and sharing

The docs map ([`README.md`](README.md)) and this history. The owner's
prompt log moved to his private notebook, reached here through a
gitignored symlink, the way his other projects share with it.

## 7 November: tests for every fix, and packs

Tests for the fixes that had none, through the real input path where that
is the point. Scenarios and eras moved out of the code into `packs/`, with a
registry the menus read: a first step of the architecture's migration that
keeps clear of the better-AI branch's files. A misspelt scenario key, an
unknown map or era, and an unknown order type are now loud errors, and the
suite fails on any of them. No recorded battle moves.

The same day CI's `ubuntu-latest` moved from Ubuntu 24.04 to 26.04, and its
maths library moved 18 of the 44 Linux recordings with no change to the
code. CI now runs on a pinned 24.04; a new image is a deliberate
re-recording, like a balance change.

## 7 November: a stronger line, and what the planner is worth

The studies run from one command (`tests/studies.sh`), on eight dice. Foot
on a flag of their own now fight whatever comes within their reach, not
only what crosses to them: against the AI of 1 November the AI wins 55% of
416 battles from both ends, where it had been even, and 36 of the 44
recorded battles moved (12 changed winner). Eleven other changes to the
line's rules, the AI at a person's pace at three speeds, and an attacker
that keeps to its plan longer, measured within the noise and were not
kept. The planner thinks between its looks on a budget; as the enemy it is
barely harder than the AI. The suite now fails when a class name is taken
by a stray copy: an old probe of the AI under `build/` had taken it, and
the suite fought the probe.

Decisions: a change to the AI is kept only when it beats the AI it would
replace from both ends beyond the noise; a rule that measures as neither
stays; the game's enemy stays the AI, not the planner.

## 8 November: what play found, the plan, and the better AI lands

The owner played a siege and found the safest line was the only line and
nothing threatened it, and saw that quick battles never picked up Rifles or
Line. The diagnosis and the plan are in `DESIGN.md`, under "Next". He agreed
the order below.

The better AI (`tsleung/fordline` pull request 1) merged first, so the new
eras are measured once, against the AI they will ship with. Its 36 moved
battles were re-recorded on Linux from a CI run on the pinned 24.04 before
main moved, so main stayed green.

## Open

In the agreed order:

1. **Two more eras:** Line and Square, Rifle and Gun. `DESIGN.md`, "Next: two
   more eras".
2. **A gun-line player** that measures the siege slog. `DESIGN.md`, "Next:
   gates that matter", step 1.
3. **Gate rules:** the gatehouse shoots the ram, battlements against
   cannonballs, a gate that can be read. Step 2 there; measure again after.
4. **The sally and the relief column.** Step 3 there.

Alongside:

- **Why the person-paced commander leads in the designed battles.** Not its
  pace and not plan commitment; the cause is not known. `DESIGN.md`, the AI
  audit.
- **The planner dataset:** written by `tests/plan_examples.gd` at `fa0a272`,
  for a language-model experiment outside this repo. It has not been handed
  over.
- **The rest of the architecture's migration** (kinds as data, the module
  contract, fortifications as the first module): `ARCHITECTURE.md`,
  "Migration". Collaborative generals are its last step.
