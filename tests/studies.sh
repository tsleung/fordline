#!/bin/sh
# The studies behind DESIGN.md's "Play over time" and "The AI audit", in
# parallel, from a copy of the tree (editing doesn't disturb a long run), into
# build/studies/NAME, reported by tests/play.py into its report.txt.
#   tests/studies.sh NAME ladder plans versus planner siege lessons
# Pick any of the six. siege fights the gun-line player against the
# standard one at both sieges (tests/gun_line.gd); lessons fights each drawn
# scenario under the naive play and the intended one (tests/lessons.gd). Set
# in the environment:
#   DICE (8), DRAWS (2): the ladder's, the planner's, the sieges' and the lessons' dice, and how many
#     fields of each campaign battle and Skirmish the ladder fights
#   TRIES (30): plans the plan search tries
#   VERSUS: more for the versus study (--pairs=ai-plan --budget=12)
#   PAR (the machine's cores): battles at once
#   TREE: a tree already prepared, to study instead of a copy of this one
set -u
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
if [ "${1:-}" = "--job" ]; then
	# One study: --job TREE OUT SCRIPT ARGS...
	tree=$2
	out=$3
	shift 3
	"$GODOT" --headless --path "$tree" -s "$@" > "$out" 2>&1
	exit
fi

NAME=$1
shift
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/build/studies/$NAME"
DICE="${DICE:-8}"
DRAWS="${DRAWS:-2}"
TRIES="${TRIES:-30}"
VERSUS="${VERSUS:-}"
PAR="${PAR:-$(getconf _NPROCESSORS_ONLN)}"
mkdir -p "$OUT"
# Godot skips what lies under a .gdignore, or the copies' classes would clash
# with this tree's.
touch "$ROOT/build/studies/.gdignore"
if [ -z "${TREE:-}" ]; then
	TREE="$OUT/tree"
	rsync -a --delete --exclude build --exclude .git --exclude notes "$ROOT/" "$TREE/"
	"$GODOT" --headless --path "$TREE" --import >/dev/null 2>&1
fi

DESIGNED="hold hammer bridges riders storm last_keep push fords_shot cuirassiers battery breach receive horse_guns fords_line bridge_dawn open_ground trees gunners creek"
DRAWN="receive horse_guns fords_line bridge_dawn open_ground trees gunners creek"
SKIRMISHES="skirmish skirmish_shot skirmish_line skirmish_rifle"
LADDER="--policies=idle,person,standard,sharp"
jobs() {
	for study in "$@"; do
		case $study in
		ladder)
			for b in 0 1 2 3 4; do
				echo "$OUT/ladder_$b.txt tests/luck_skill.gd -- --battle=$b --draws=$DRAWS --dice=$DICE $LADDER"
			done
			for s in $SKIRMISHES; do
				echo "$OUT/ladder_$s.txt tests/luck_skill.gd -- --scenario=$s --draws=$DRAWS --dice=$DICE $LADDER"
			done
			for s in $DESIGNED; do
				echo "$OUT/ladder_$s.txt tests/luck_skill.gd -- --scenario=$s --draws=1 --dice=$DICE $LADDER"
			done
			;;
		plans)
			for s in hold hammer push; do
				echo "$OUT/plans_$s.txt tests/plans.gd -- --scenario=$s --dice=3 --tries=$TRIES"
			done
			;;
		versus)
			# $VERSUS comes first: xargs -L runs a line ending in a blank on into
			# the next.
			for s in $DESIGNED; do
				echo "$OUT/versus_$s.txt tests/versus.gd -- $VERSUS --job=scenario:$s --dice=8"
			done
			for b in 0 1 2 3 4; do
				echo "$OUT/versus_$b.txt tests/versus.gd -- $VERSUS --job=battle:$b --dice=4 --draws=2"
			done
			# Mirrors: both sides the same army and persona, on twenty fields.
			for s in $SKIRMISHES; do
				for first in 0 5 10 15; do
					echo "$OUT/versus_${s}_$first.txt tests/versus.gd -- $VERSUS --job=scenario:$s --dice=2 --draws=5 --first=$first"
				done
			done
			;;
		siege)
			# The siege slog: the gun-line player against the standard one.
			for s in storm breach; do
				echo "$OUT/siege_$s.txt tests/gun_line.gd -- --scenarios=$s --dice=$DICE"
			done
			;;
		planner)
			for s in $SKIRMISHES $DESIGNED; do
				echo "$OUT/planner_$s.txt tests/luck_skill.gd -- --scenario=$s --draws=1 --dice=$DICE --policies=planner"
			done
			;;
		lessons)
			for s in $DRAWN; do
				echo "$OUT/lessons_$s.txt tests/lessons.gd -- --scenario=$s --dice=$DICE"
			done
			;;
		*)
			echo "unknown study: $study" >&2
			exit 2
			;;
		esac
	done
}
jobs "$@" | xargs -L 1 -P "$PAR" sh "$0" --job "$TREE"
python3 "$ROOT/tests/play.py" "$OUT"/*.txt > "$OUT/report.txt"
grep -h '^LESSON' "$OUT"/*.txt >> "$OUT/report.txt"
cat "$OUT/report.txt"
if grep -q 'SCRIPT ERROR' "$OUT"/*.txt; then
	echo "FAILED: script errors in $OUT"
	exit 1
fi
