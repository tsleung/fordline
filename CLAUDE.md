# CLAUDE.md

Fordline is a Godot 4.5 real-time tactics game (GDScript). Read
`docs/DESIGN.md` first, then `README.md`.

## Documentation

`docs/README.md` maps the docs: `docs/DESIGN.md` (the game, and what was
measured), `docs/ARCHITECTURE.md` (the engine and how it grows),
`docs/HISTORY.md` (what was built when, and why). Keep them current in the
same commit as the change they describe.

## Private paths

`notes/prompts.md` is the owner's verbatim prompt log about Fordline. On his
machine it is a gitignored symlink into his private notebook
(`~/github/terranleung.com/notes/fordline/prompts.md`), so what is written
here lands there; on any other machine it is absent. This repo is public:
the log is never committed here, and `test.sh` fails if it is tracked.

- When the path exists, append each of the owner's prompts about Fordline
  verbatim (typos and all) under a dated one-line context, the format the
  file already uses. Never create the path where it does not exist.
- Before you finish, if you appended to it, commit it in the notebook with
  `npm --prefix ~/github/terranleung.com run commit-logs`. It commits the
  logs there and nothing else.
- Nothing else from the notebook is copied into this repo unless the owner
  says so.

## Rules for editing

- **One writer.** `scripts/battle.gd` is the only code that writes battle
  state. Input and AI produce order dictionaries for `apply_orders`; views
  read fields and drain `take_events()`. Keep it that way.
- **Pure where it can be.** `combat.gd`, `campaign.gd` and `ai.gd` are
  functions over values: `campaign.gd` returns new run state and never
  mutates its argument (the tests check this).
- **Balance changes go through the headless battles.** After touching
  stats, combat, morale or the AI, run `./test.sh` and read the battle
  table it prints (winner, time, kills, resolve). A battle running past
  seven minutes fails the suite.
- **Godot binary:** `/Applications/Godot.app/Contents/MacOS/Godot`
  (4.5.1). Run `./test.sh` after every nontrivial edit; it fails on any
  script error, not only on failed checks.
- GDScript can't infer a type from a Variant (a Dictionary field, an untyped
  ternary): give such variables an explicit type.
- The design numbers in `docs/DESIGN.md` must match the code.
- Scripts and probes never launch an installed browser; use Godot's own
  window, the Claude browser pane, or Playwright's bundled Chromium.
- In `DESIGN.md`, a section headed "not built" holds proposals; its numbers
  are not the code's yet. When you build one, make it the rule and move the
  numbers.

## Running things

- **What's next:** `docs/HISTORY.md`, "Open".
- **The suite can take over ten minutes** when other sessions load this
  machine, so run it in the background. `./test.sh --quick` is the fast one.
- **Read the suite's own exit code before committing.** Piping it through
  `grep` hid a failure once, and a broken commit went out. macOS `sed` has no
  `\b`.
- **A failed recorded battle may not be your change.** Check first whether
  the CI image or the platform moved; compare the runner image in the logs of
  the last green run. See `docs/ARCHITECTURE.md`, "Staying stable", for how
  recordings are made on each platform.
- **`scripts/ai.gd` and the studies belong to the better-AI branch** until it
  lands. Don't change them on main before then.
- **In tests,** `root.push_input(e, true)` needs its `true` to use viewport
  coordinates.
- **A wrapped `Label`:** the ellipsis collapses wrapped lines in this Godot
  version; limit it with `max_lines_visible` alone.
