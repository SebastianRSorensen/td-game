extends Node

signal all_enemies_dead

var enemies_alive := 0
var enemies_to_spawn: Array[Dictionary] = []
var spawn_timer := 0.0
var spawn_interval := 0.7
var spawning := false

@onready var enemies_container: Node2D = get_node("/root/Main/Entities/Enemies")


func start_wave(wave_number: int) -> void:
	enemies_to_spawn = _get_wave_composition(wave_number)
	enemies_alive = 0
	spawn_timer = 0.0
	spawning = true
	GameManager.wave_in_progress = true
	GameManager.wave_damage_dealt = 0.0
	GameManager.wave_started.emit(wave_number)


func _process(delta: float) -> void:
	if not spawning:
		return

	spawn_timer -= delta
	if spawn_timer <= 0 and enemies_to_spawn.size() > 0:
		_spawn_enemy(enemies_to_spawn.pop_front())
		spawn_timer = spawn_interval

	if enemies_to_spawn.size() == 0 and enemies_alive <= 0 and spawning:
		spawning = false
		all_enemies_dead.emit()


func _spawn_enemy(enemy_data: Dictionary) -> void:
	var enemy := EnemyEntity.new()
	enemy.setup(enemy_data)
	enemy.add_to_group("enemies")
	enemy.died.connect(_on_enemy_died)
	enemy.reached_end.connect(_on_enemy_reached_end)
	enemies_container.add_child(enemy)
	enemies_alive += 1


func _on_enemy_died(scrap_reward: int) -> void:
	enemies_alive -= 1
	GameManager.add_scrap(scrap_reward)


func _on_enemy_reached_end(damage: float) -> void:
	enemies_alive -= 1
	GameManager.reduce_integrity(damage)


func _get_wave_composition(wave: int) -> Array[Dictionary]:
	var base_hp := 60.0 + wave * 20.0
	var result: Array[Dictionary] = []

	var node := GameManager.node_plan[wave - 1]
	var threat: float = node["threat_multiplier"]
	var node_type: GameManager.NodeType = node["node_type"] as GameManager.NodeType

	match node_type:
		GameManager.NodeType.BOSS:
			# Boss enemy
			result.append({
				"name": _boss_name(node["biome"] as GameManager.Biome),
				"hp": base_hp * 6.0 * threat,
				"speed": 40.0,
				"reward": 50,
				"size": 28.0,
				"color": Color(0.9, 0.15, 0.15),
			})
			# Escort minions
			for i in range(4):
				result.append({
					"name": "Minion",
					"hp": base_hp * 0.5,
					"speed": 85.0,
					"reward": 3,
					"size": 10.0,
					"color": Color(0.6, 0.6, 0.6),
				})
		GameManager.NodeType.ELITE:
			for i in range(4):
				result.append({
					"name": "Elite",
					"hp": base_hp * 2.0 * threat,
					"speed": 55.0,
					"reward": 12,
					"size": 18.0,
					"color": Color(1.0, 0.7, 0.2),
				})
			for i in range(6):
				result.append({
					"name": "Regular",
					"hp": base_hp * threat,
					"speed": 75.0,
					"reward": 5,
					"size": 13.0,
					"color": Color(0.85, 0.85, 0.85),
				})
		_:
			var count := 6 + wave
			for i in range(count):
				result.append({
					"name": "Regular",
					"hp": base_hp * threat,
					"speed": 72.0 + randf_range(-5.0, 5.0),
					"reward": 5,
					"size": 13.0,
					"color": Color(0.85, 0.85, 0.85),
				})
			# Add a couple fast enemies from wave 3 onward
			if wave >= 3:
				for i in range(mini(wave - 2, 4)):
					result.append({
						"name": "Runner",
						"hp": base_hp * 0.6,
						"speed": 115.0,
						"reward": 7,
						"size": 10.0,
						"color": Color(0.4, 0.9, 1.0),
					})

	# Inject adaptation traits into enemies
	if GameManager.enemy_traits.size() > 0:
		for enemy_data in result:
			enemy_data["traits"] = GameManager.enemy_traits.duplicate()

	return result


func get_wave_preview(wave: int) -> String:
	if wave < 1 or wave > GameManager.total_waves:
		return ""
	var comp := _get_wave_composition(wave)
	var counts: Dictionary = {}
	for enemy_data in comp:
		var n: String = enemy_data["name"]
		counts[n] = counts.get(n, 0) + 1
	var parts: Array[String] = []
	for n in counts:
		parts.append("%dx %s" % [counts[n], n])
	return ", ".join(parts)


func _boss_name(biome: GameManager.Biome) -> String:
	match biome:
		GameManager.Biome.VERDANT_BASIN:
			return "Bloom Rot Matriarch"
		GameManager.Biome.IRON_SCAR:
			return "Ember Titan"
		GameManager.Biome.HOLLOW_VEIL:
			return "Glass Saint"
		_:
			return "Boss"
