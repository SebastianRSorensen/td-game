class_name TowerEntity
extends Node2D

var tower_def: Dictionary
var grid_pos: Vector2i
var attack_timer := 0.0
var show_range := false
var level := 1
const MAX_LEVEL := 3


func setup(p_grid_pos: Vector2i, p_tower_def: Dictionary) -> void:
	tower_def = p_tower_def
	grid_pos = p_grid_pos
	position = GameManager.grid_to_world(grid_pos)
	add_to_group("towers")


func get_damage() -> float:
	return tower_def["damage"] * (1.0 + (level - 1) * 0.35)


func get_attack_speed() -> float:
	return tower_def["attack_speed"] * (1.0 + (level - 1) * 0.15)


func get_range() -> int:
	return tower_def["range"] + (1 if level >= 3 else 0)


func get_upgrade_cost() -> int:
	if level >= MAX_LEVEL:
		return 0
	var base_cost: int = tower_def["cost"]
	if level == 1:
		return int(base_cost * 0.6)
	return base_cost


func get_sell_value() -> int:
	var base_cost: int = tower_def["cost"]
	var total_invested := base_cost
	if level >= 2:
		total_invested += int(base_cost * 0.6)
	if level >= 3:
		total_invested += base_cost
	return int(total_invested * 0.6)


func upgrade() -> bool:
	if level >= MAX_LEVEL:
		return false
	var cost := get_upgrade_cost()
	if not GameManager.spend_scrap(cost):
		return false
	level += 1
	queue_redraw()
	return true


func _process(delta: float) -> void:
	var atk_speed := get_attack_speed()
	if atk_speed <= 0:
		return

	attack_timer -= delta
	if attack_timer <= 0:
		var target := _find_target()
		if target:
			_fire_at(target)
			attack_timer = 1.0 / atk_speed
		else:
			attack_timer = 0.1


func _find_target() -> EnemyEntity:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var range_px: float = get_range() * GameManager.CELL_SIZE
	var closest: EnemyEntity = null
	var closest_dist := INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist := position.distance_to(enemy.position)
		if dist <= range_px and dist < closest_dist:
			closest = enemy as EnemyEntity
			closest_dist = dist

	return closest


func _fire_at(target: EnemyEntity) -> void:
	var target_grid := GameManager.world_to_grid(target.position)
	var combo := _calc_combo(target_grid)
	var damage := get_damage() * combo * _get_support_bonus()

	if tower_def["role"] == "Control":
		target.apply_slow(1.4 + level * 0.1, 1.5 + level * 0.3)

	var proj := ProjectileEntity.new()
	var color: Color = GameManager.faction_colors[tower_def["faction"]]
	proj.setup(position, target, damage, color)
	var proj_container := get_node_or_null("/root/Main/Entities/Projectiles")
	if proj_container:
		proj_container.add_child(proj)
	else:
		get_tree().root.add_child(proj)

	var battlefield := get_node_or_null("/root/Main/Battlefield")
	if battlefield:
		battlefield.queue_redraw()


func _calc_combo(tile_pos: Vector2i) -> float:
	var state := GameManager.get_terrain(tile_pos)
	var element: String = tower_def["element"]
	var bonus := 1.0

	if element == "lightning" and state == GameManager.TerrainState.FLOODED:
		bonus += 0.5
		GameManager.set_terrain(tile_pos, GameManager.TerrainState.ELECTRIFIED)
	elif element == "fire" and state == GameManager.TerrainState.FLOODED:
		bonus += 0.4
		GameManager.set_terrain(tile_pos, GameManager.TerrainState.SCORCHED)
	elif element == "explosive" and state == GameManager.TerrainState.FROZEN:
		bonus += 0.6
		GameManager.set_terrain(tile_pos, GameManager.TerrainState.CRATERED)
	elif element == "poison" and state == GameManager.TerrainState.CORRUPTED:
		bonus += 0.35
	elif element == "growth" and state == GameManager.TerrainState.CRATERED:
		bonus += 0.2
		GameManager.set_terrain(tile_pos, GameManager.TerrainState.OVERGROWN)

	if bonus > 1.0:
		GameManager.story_moments.append(
			"Wave %d: %s combo on %s terrain!" % [
				GameManager.current_wave, tower_def["name"],
				GameManager.TerrainState.keys()[state]
			]
		)

	return bonus


func _get_support_bonus() -> float:
	var bonus := 1.0
	for tower in get_tree().get_nodes_in_group("towers"):
		if tower == self:
			continue
		var td: Dictionary = tower.tower_def
		if td["name"] != "Bloom Shrine":
			continue
		var range_px: float = td["range"] * GameManager.CELL_SIZE
		if position.distance_to(tower.position) <= range_px:
			bonus += 0.20
	return bonus


func _draw() -> void:
	var half := GameManager.CELL_SIZE / 2.0 - 6.0
	var color: Color = GameManager.faction_colors[tower_def["faction"]]

	# Selection highlight
	if show_range:
		draw_rect(Rect2(-half - 3, -half - 3, (half + 3) * 2, (half + 3) * 2), Color.WHITE, false, 3.0)

	# Tower base
	draw_rect(Rect2(-half, -half, half * 2, half * 2), color)
	draw_rect(Rect2(-half, -half, half * 2, half * 2), color.lightened(0.3), false, 2.0)

	# Level pips (bottom of tower)
	for i in range(level):
		var pip_x := -8.0 + i * 10.0
		draw_circle(Vector2(pip_x, half - 8), 3.5, Color.WHITE)

	# Role icon
	var icon_color := Color.WHITE
	match tower_def["role"]:
		"DPS":
			draw_line(Vector2(-8, 0), Vector2(8, 0), icon_color, 2.0)
			draw_line(Vector2(0, -8), Vector2(0, 8), icon_color, 2.0)
			draw_arc(Vector2.ZERO, 6, 0, TAU, 16, icon_color, 1.5)
		"AoE":
			draw_arc(Vector2.ZERO, 10, 0, TAU, 16, icon_color, 1.5)
			draw_arc(Vector2.ZERO, 5, 0, TAU, 16, icon_color, 1.5)
		"Control":
			draw_line(Vector2(-8, -4), Vector2(8, -4), icon_color, 2.0)
			draw_line(Vector2(-8, 4), Vector2(8, 4), icon_color, 2.0)
		"Support":
			draw_line(Vector2(-6, 0), Vector2(6, 0), Color.YELLOW, 3.0)
			draw_line(Vector2(0, -6), Vector2(0, 6), Color.YELLOW, 3.0)
		"Anchor":
			draw_rect(Rect2(-8, -8, 16, 16), icon_color, false, 3.0)
		"Economy":
			draw_circle(Vector2.ZERO, 7, Color.GOLD)
			draw_circle(Vector2.ZERO, 4, color)
		"Chain":
			draw_line(Vector2(-2, -8), Vector2(2, 0), icon_color, 2.0)
			draw_line(Vector2(2, 0), Vector2(-2, 0), icon_color, 2.0)
			draw_line(Vector2(-2, 0), Vector2(2, 8), icon_color, 2.0)
		"Finisher":
			draw_line(Vector2(0, -10), Vector2(0, 10), icon_color, 3.0)
			draw_line(Vector2(-6, 4), Vector2(0, 10), icon_color, 3.0)
			draw_line(Vector2(6, 4), Vector2(0, 10), icon_color, 3.0)
		"Volatile":
			draw_line(Vector2(-7, -7), Vector2(7, 7), Color.RED, 2.0)
			draw_line(Vector2(7, -7), Vector2(-7, 7), Color.RED, 2.0)
		"Late":
			draw_line(Vector2(-6, -8), Vector2(6, -8), icon_color, 2.0)
			draw_line(Vector2(-6, 8), Vector2(6, 8), icon_color, 2.0)
			draw_line(Vector2(-6, -8), Vector2(6, 8), icon_color, 1.5)
			draw_line(Vector2(6, -8), Vector2(-6, 8), icon_color, 1.5)
		"Aura":
			draw_arc(Vector2.ZERO, 10, 0, TAU, 16, Color.ORANGE, 2.0)

	# Range circle
	if show_range:
		var range_px: float = get_range() * GameManager.CELL_SIZE
		draw_arc(Vector2.ZERO, range_px, 0, TAU, 64, Color(1, 1, 1, 0.2), 2.0)
