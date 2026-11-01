extends SceneTree
## The planner's choices as a dataset (tests/planner_data.gd): fights each
## scenario with the planner as the player against the scenario's enemy and
## writes, under --out, spec.json (what the dataset is) and examples.jsonl
## (a row per re-plan). Rerun, it writes the same bytes.
##   Godot --headless --path . -s tests/plan_examples.gd -- --scenarios=hold,riders --dice=4 --out=build/plan_examples/a
##   --draws=N fights N fields of a Skirmish; --commit=SHA records the code it came from.

const QUICK := ["skirmish", "hold", "hammer", "bridges", "riders", "storm", "last_keep", "skirmish_shot", "push", "fords_shot", "cuirassiers", "battery", "breach"]


func _initialize() -> void:
	var scenarios := PackedStringArray(QUICK)
	var dice := 4
	var draws := 1
	var out := "res://build/plan_examples"
	var commit := "unknown"
	for arg in OS.get_cmdline_user_args():
		var value := arg.get_slice("=", 1)
		if arg.begins_with("--scenarios="):
			scenarios = value.split(",")
		elif arg.begins_with("--dice="):
			dice = int(value)
		elif arg.begins_with("--draws="):
			draws = int(value)
		elif arg.begins_with("--out="):
			out = value
		elif arg.begins_with("--commit="):
			commit = value
	var dir := out if out.is_absolute_path() or out.begins_with("res://") else "res://" + out
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var planner := Commander.PlannerCommander.new(AI.PERSONAS.balanced, false, {})
	var seeds: Array = []
	var lines := PackedStringArray()
	for id in scenarios:
		for draw in (draws if id.begins_with("skirmish") else 1):
			var spec := Scenarios.resolve(id, 1000 + draw)
			for die in dice:
				seeds.append({"scenario": id, "draw": draw, "dice": die, "battle_seed": 7919 * (die + 1)})
				var b := Scenarios.make_battle(spec, 7919 * (die + 1))
				var episode := "%s:d%dx%d:0" % [id, draw, die]
				for row in PlannerData.fight(b, 0, AI.PERSONAS.balanced, AI.PERSONAS[spec.persona], die, episode):
					lines.append(JSON.stringify(row, "", true))
	var info := Engine.get_version_info()
	var units := PlannerData.feature_units()
	var names := PlannerData.feature_names()
	var spec_out := {
		"generator": "tests/plan_examples.gd", "commit": commit,
		"godot": "%d.%d.%d" % [info.major, info.minor, info.patch], "platform": OS.get_name(),
		"scenarios": Array(scenarios), "seeds": seeds, "side": "player (team 0), the enemy at its scenario's persona",
		"planner": {"replan_s": planner.replan, "horizon_s": planner.horizon, "rollout_reseeds_per_choice": planner.samples},
		"features": Array(names).map(func(n): return {"name": n, "unit": units[_unit_key(n)]}),
		"choices": Array(PlannerData.choice_names()),
		"outcome": "1 the side won, 0 lost, 0.5 undecided at the time cap",
	}
	_write(dir + "/spec.json", JSON.stringify(spec_out, "  ", true) + "\n")
	_write(dir + "/examples.jsonl", "\n".join(lines) + ("\n" if not lines.is_empty() else ""))
	print("wrote %d examples from %d battles to %s" % [lines.size(), seeds.size(), dir])
	quit()


## A feature's key in PlannerData.feature_units(): a flag's features share
## one per kind ("flag2_enemy" is "enemy"; "flags_own" is itself).
func _unit_key(name: String) -> String:
	return name.substr(name.find("_") + 1) if name.begins_with("flag") and name.substr(4, 1).is_valid_int() else name


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
