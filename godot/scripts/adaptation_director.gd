extends Node

var window: Array[Dictionary] = []
var cooldowns: Dictionary = {}


func ingest(metrics: Dictionary) -> void:
	window.append(metrics)
	if window.size() > 3:
		window.pop_front()
	for key in cooldowns.keys():
		cooldowns[key] = maxi(0, cooldowns[key] - 1)


func forecast(wave: int, player_integrity: float) -> Dictionary:
	if wave % 3 != 0 or window.size() < 3:
		return {}
	if player_integrity < 0.35:
		return {}

	var avg := {
		"burn_share": 0.0,
		"slow_dilation": 0.0,
		"path_extension": 0.0,
		"early_kill_share": 0.0,
		"corruption_stacks": 0.0,
		"corruption_kill_share": 0.0,
	}

	for w in window:
		for key in avg.keys():
			avg[key] += w.get(key, 0.0) / 3.0

	var scores := {
		"Burn": minf(1.0, avg["burn_share"] / 0.60),
		"Control": minf(1.0, avg["slow_dilation"] / 0.50),
		"Maze": minf(1.0, avg["path_extension"] / 0.50),
		"Burst": minf(1.0, avg["early_kill_share"] / 0.70),
		"Corruption": minf(1.0, ((avg["corruption_stacks"] / 12.0) + (avg["corruption_kill_share"] / 0.55)) / 2.0),
	}

	var dominant := ""
	var max_score := 0.0
	for key in scores:
		if scores[key] > max_score:
			max_score = scores[key]
			dominant = key

	if max_score < 0.75 or cooldowns.get(dominant, 0) > 0:
		return {}

	var family_map := {
		"Burn": "Fireproof",
		"Control": "Unstoppable",
		"Maze": "Pathfinder",
		"Burst": "Bulwark",
		"Corruption": "Purgeblood",
	}

	cooldowns[dominant] = 3

	var result := {
		"signal_name": dominant,
		"family": family_map[dominant],
		"eta_partial": wave + 1,
		"eta_full": wave + 2,
	}

	# Apply counter trait
	var trait_map := {
		"Burn": "heat-fed",
		"Control": "momentum-burst",
		"Maze": "burrower",
		"Burst": "bulwark-shield",
		"Corruption": "purgeblood",
	}
	var trait_name: String = trait_map[dominant]
	if trait_name not in GameManager.enemy_traits:
		GameManager.enemy_traits.append(trait_name)

	GameManager.story_moments.append(
		"Wave %d: enemy evolution forecasted %s counter-line" % [wave, family_map[dominant]]
	)
	GameManager.adaptation_forecasted.emit(result)

	return result


func reset() -> void:
	window.clear()
	cooldowns.clear()
