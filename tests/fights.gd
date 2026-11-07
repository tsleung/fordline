class_name Fights
extends RefCounted
## Battles fought computer against computer, for the suite and the studies:
## the ladder of player commanders, and one way to fight a battle with them,
## through the same loop the game uses.

## Player commanders of rising skill (idle, person, standard, sharp), then
## sharp with one change each (reserve, hills), then the planner. every:
## seconds between decisions (0 never decides). persona: the AI persona it
## plays with. rally: whether it blows the horn when regiments near the
## general break. per_look: at most this many orders each decision, the
## most urgent first: a person's pace, the ladder's stand-in for a player.
## plans: thinks ahead, trying plans on copies of the battle; it fights
## about ten times as long, so the studies run it only when asked.
const POLICIES := {
	"idle": {"every": 0.0, "persona": {"hold": 8.0, "flank": false}, "rally": false},
	"person": {"every": 2.0, "persona": AI.PERSONAS["balanced"], "rally": false, "per_look": 1},
	"standard": {"every": 0.75, "persona": AI.PERSONAS["balanced"], "rally": false},
	"sharp": {"every": 0.4, "persona": AI.PERSONAS["balanced"], "rally": true},
	"reserve": {"every": 0.4, "persona": AI.PERSONAS["reserve"], "rally": true},
	"hills": {"every": 0.4, "persona": AI.PERSONAS["hills"], "rally": true},
	"planner": {"every": 0.75, "persona": AI.PERSONAS["balanced"], "rally": false, "plans": true},
}
## A quick battle may not run longer than this; a grand one runs to dusk.
const TIME_CAP := 600.0


## The player's seat for `policy`, against an enemy that fights as
## `enemy_persona` (a planner reads it in the briefing).
static func player_seat(policy: String, enemy_persona: Dictionary) -> BattleRun.Seat:
	var p: Dictionary = POLICIES[policy]
	if p.every <= 0.0:
		return BattleRun.Seat.new(0, Commander.new())
	if p.has("plans"):
		return BattleRun.Seat.new(0, Commander.PlannerCommander.new(p.persona, p.rally, enemy_persona), p.every)
	if p.has("per_look"):
		return BattleRun.Seat.new(0, Commander.PacedCommander.new(p.persona, p.rally, p.per_look), p.every)
	return BattleRun.Seat.new(0, Commander.AICommander.new(p.persona, p.rally), p.every)


## Fight `b` to its end, the enemy under `enemy_persona` and the player
## under `policy`. With `logged`, the player's orders go into the run's log
## as its turns, so the battle can be replayed with one taken out. `die`
## sets when each commander first looks (see seats). Returns the run, with
## its trace.
static func fight(b: Battle, enemy_persona: Dictionary, policy: String, logged := false, die := 0) -> BattleRun:
	var run := BattleRun.new(b)
	for seat in seats(enemy_persona, policy, die):
		seat.logged = logged and seat.team == 0
		run.add_seat(seat)
	run.begin()
	run.run_for(length(b))
	return run


## The seats for a fight: the enemy first, then the player, the order in
## which they decide within a step. `die` sets when each first looks: a
## few steps into its think, a different few for each seat, as a person
## never looks at the same moments twice. Where the battle's own random
## numbers barely matter (only guns scatter), this is what makes the dice
## fight different battles: on the knife edge a few steps is another
## battle. Die 0 has both look at once.
static func seats(enemy_persona: Dictionary, policy: String, die := 0) -> Array:
	var out: Array = [BattleRun.Seat.new(1, Commander.AICommander.new(enemy_persona)), player_seat(policy, enemy_persona)]
	for i in out.size():
		first_look(out[i], i, die)
	return out


## Seat `seat`, the `index`th to decide in a step, first looks a few steps
## into its think, by `die`. A think's worth of dice on, the first seat's
## moments come round again, so each lap shifts the later seats a step more:
## the dice below a lap time as they always did, and those past it fight
## other battles rather than the same ones again.
static func first_look(seat: BattleRun.Seat, index: int, die: int) -> void:
	var steps := maxi(1, roundi(seat.every / Battle.STEP))
	@warning_ignore("integer_division")
	var lap := die / steps
	seat.wait = (die * (3 + 2 * index) + lap * index) % steps * Battle.STEP


static func length(b: Battle) -> float:
	return maxf(TIME_CAP, b.deadline + 10.0)
