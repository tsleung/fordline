#!/usr/bin/env python3
"""Measures of play against DESIGN.md's "Play over time" targets. Reads the
ROW lines tests/luck_skill.gd prints and reports, per battle and commander,
each horizon's measure; and the VS lines tests/versus.gd prints, the AI
against its yardstick from both ends.

    python3 tests/play.py build/play/*.txt
"""
import json
import sys
from collections import defaultdict
from statistics import mean, median

LADDER = ["idle", "person", "standard", "sharp", "reserve", "hills", "planner"]


def load(paths, tag="ROW "):
    rows = []
    for path in paths:
        with open(path) as f:
            for line in f:
                if line.startswith(tag):
                    rows.append(json.loads(line[len(tag):]))
    return rows


def versus(rows):
    """The player's win rate for each pairing, player's AI against the
    enemy's; and what the AI changes against the yardstick's base rate."""
    by = defaultdict(list)
    for r in rows:
        by[(r["job"], r["player"], r["enemy"])].append(r["won"])
    pairs = [("base", "base"), ("ai", "base"), ("base", "ai")]
    print(f"{'battle':24s} " + " ".join(f"{p + ' v ' + e:>12s}" for p, e in pairs) + "    n")
    pooled = defaultdict(list)
    for job in sorted({r["job"] for r in rows}):
        cells = []
        for pe in pairs:
            won = by.get((job,) + pe, [])
            pooled[pe] += won
            cells.append(f"{mean(won):12.0%}" if won else f"{'-':>12s}")
        print(f"{job:24s} " + " ".join(cells) + f" {len(by.get((job, 'ai', 'base'), [])):4d}")
    rate = {pe: mean(w) if w else float("nan") for pe, w in pooled.items()}
    print(f"{'all':24s} " + " ".join(f"{rate.get(pe, float('nan')):12.0%}" for pe in pairs))
    print(f"the AI as the player wins {rate[('ai', 'base')] - rate[('base', 'base')]:+.0%} against the yardstick's base rate; "
          f"as the enemy it holds the player to {rate[('base', 'ai')] - rate[('base', 'base')]:+.0%}")


def report(rows):
    by = defaultdict(list)
    for r in rows:
        by[(str(r["battle"]), r["policy"])].append(r)
    print(f"{'battle':16s} {'commander':9s} {'n':>3s} {'win':>5s} {'min':>5s} {'leadΔ':>6s} {'comeb':>6s} "
          f"{'quiet':>6s} {'warn':>5s} {'unann':>6s} {'ord/m':>6s}")
    for (battle, policy) in sorted(by, key=lambda k: (k[0], LADDER.index(k[1]) if k[1] in LADDER else 99)):
        rs = by[(battle, policy)]
        warns = [r["warning"] for r in rs if r["warning"] >= 0]
        print(f"{battle:16s} {policy:9s} {len(rs):3d} {mean(r['won'] for r in rs):5.0%} "
              f"{mean(r['time'] for r in rs) / 60:5.1f} {mean(r['lead_changes'] for r in rs):6.2f} "
              f"{mean(r['comeback'] for r in rs):6.0%} {max(r['quiet'] for r in rs):5.0f}s "
              f"{(median(warns) if warns else -1):4.0f}s {mean(r['unannounced'] for r in rs):6.0%} "
              f"{mean(r['orders_min'] for r in rs):6.1f}")
    impacts = [(r["battle"], i) for r in rows for i in r.get("impact", [])]
    if impacts:
        print()
        print("sensitivity (one order taken out, every other order kept, battle fought again)")
        per = defaultdict(list)
        for battle, i in impacts:
            per[str(battle)].append(i)
        for battle, items in sorted(per.items()):
            matters = mean(abs(i["margin"]) >= 5 for i in items)
            flips = mean(i["flip"] for i in items)
            soon = mean(abs(i["soon"]) for i in items)
            end = mean(abs(i["end"]) for i in items)
            print(f"  {battle:16s} orders {len(items):3d}  move the margin 5+ {matters:4.0%}  flip the winner {flips:4.0%}  "
                  f"growth {end / soon if soon > 0 else float('nan'):4.1f}")


if __name__ == "__main__":
    rows, vs = load(sys.argv[1:]), load(sys.argv[1:], "VS ")
    if rows:
        report(rows)
    if vs:
        print()
        versus(vs)
