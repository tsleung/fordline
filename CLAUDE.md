# CLAUDE.md

Fordline is a Godot 4.5 real-time tactics game (GDScript). Read
`docs/DESIGN.md` first, then `README.md`.

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
