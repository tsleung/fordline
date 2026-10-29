#!/usr/bin/env python3
"""Luck or skill? Reads the ROW lines tests/luck_skill.gd prints and reports
how much of a battle's outcome the commander decides and how much the draw
and the dice decide.

    python3 tests/luck_skill.py build/luck/*.txt

The outcome is the final resolve margin (player minus enemy, -100..100).
Its spread is split, battle by battle, the way a two-way analysis of
variance splits it:
    commander   - the four policies differ on average
    draw        - some maps and rosters are easier for everyone
    fit         - which commander does best depends on the map
    dice        - the same commander on the same map, different dice
Commander and fit are skill; draw and dice are luck.
"""
import json
import sys
from collections import defaultdict
from statistics import mean

ORDER = ["idle", "slow", "standard", "sharp"]
NAMES = ["Millbrook Ford", "Ashwood", "Two Bridges", "Saltmarsh Road", "Marshal's Ridge"]


def load(paths):
    rows = []
    for path in paths:
        with open(path) as f:
            for line in f:
                if line.startswith("ROW "):
                    rows.append(json.loads(line[4:]))
    return rows


def decompose(rows):
    """Sums of squares for commander, draw, fit and dice over one battle."""
    y = lambda r: r["margin"]
    grand = mean(map(y, rows))
    by_p, by_d, by_pd = defaultdict(list), defaultdict(list), defaultdict(list)
    for r in rows:
        by_p[r["policy"]].append(y(r))
        by_d[r["draw"]].append(y(r))
        by_pd[(r["policy"], r["draw"])].append(y(r))
    mp = {k: mean(v) for k, v in by_p.items()}
    md = {k: mean(v) for k, v in by_d.items()}
    ss = {"commander": 0.0, "draw": 0.0, "fit": 0.0, "dice": 0.0}
    for r in rows:
        p, d = r["policy"], r["draw"]
        cell = mean(by_pd[(p, d)])
        ss["commander"] += (mp[p] - grand) ** 2
        ss["draw"] += (md[d] - grand) ** 2
        ss["fit"] += (cell - mp[p] - md[d] + grand) ** 2
        ss["dice"] += (y(r) - cell) ** 2
    return ss


def main(paths):
    rows = load(paths)
    if not rows:
        sys.exit("no ROW lines found")
    print(f"{len(rows)} battles\n")

    print("By commander (all battles)")
    print(f"  {'':10} {'won':>6} {'margin':>8} {'time':>6} {'lead changes':>13}")
    for p in ORDER:
        rs = [r for r in rows if r["policy"] == p]
        if rs:
            print(f"  {p:10} {mean(r['won'] for r in rs):6.0%} {mean(r['margin'] for r in rs):8.1f}"
                  f" {mean(r['time'] for r in rs):6.0f} {mean(r['lead_changes'] for r in rs):13.2f}")

    print("\nWin rate by battle and commander")
    print(f"  {'':16} " + " ".join(f"{p:>9}" for p in ORDER))
    for b in sorted({r["battle"] for r in rows}):
        cells = []
        for p in ORDER:
            rs = [r for r in rows if r["battle"] == b and r["policy"] == p]
            cells.append(f"{mean(r['won'] for r in rs):9.0%}" if rs else f"{'-':>9}")
        print(f"  {NAMES[b]:16} " + " ".join(cells))

    # With the idle commander in, "does giving orders matter" swamps
    # everything; without it, the split is about playing well.
    for title, keep in [("all four commanders", ORDER), ("commanders who give orders", ORDER[1:])]:
        total = defaultdict(float)
        for b in {r["battle"] for r in rows}:
            subset = [r for r in rows if r["battle"] == b and r["policy"] in keep]
            for k, v in decompose(subset).items():
                total[k] += v
        whole = sum(total.values()) or 1.0
        print(f"\nWhat decides the margin, {title} (share of its spread, within each battle)")
        for k, label in [("commander", "commander (skill)"), ("fit", "fit to the map (skill)"),
                         ("draw", "the draw (luck)"), ("dice", "the dice (luck)")]:
            print(f"  {label:26} {total[k] / whole:6.0%}")
        print(f"  {'skill in all':26} {(total['commander'] + total['fit']) / whole:6.0%}")

    # The same map and dice, one step up in skill: how often does the
    # better commander finish with the better margin?
    cells = defaultdict(dict)
    for r in rows:
        cells[(r["battle"], r["draw"], r["dice"])][r["policy"]] = r
    print("\nOne step up in skill, same map and dice: better commander ends ahead")
    for lo, hi in zip(ORDER, ORDER[1:]):
        pairs = [(c[lo], c[hi]) for c in cells.values() if lo in c and hi in c]
        better = sum(h["margin"] > l["margin"] for l, h in pairs)
        flips = sum(h["won"] != l["won"] for l, h in pairs)
        print(f"  {lo:>8} -> {hi:9} {better / len(pairs):6.0%}   result flips {flips / len(pairs):5.0%}")

    # A draw is decided by luck when every non-idle commander gets the
    # same result on every die.
    settled = defaultdict(set)
    for r in rows:
        if r["policy"] != "idle":
            settled[(r["battle"], r["draw"])].add(r["won"])
    decided = sum(len(s) == 1 for s in settled.values())
    print(f"\nDraws where no commander changed the result: {decided} of {len(settled)}")


if __name__ == "__main__":
    main(sys.argv[1:])
