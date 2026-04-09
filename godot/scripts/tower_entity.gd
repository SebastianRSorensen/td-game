class_name TowerEntity
extends Node2D

var tower_def: Dictionary
var grid_pos: Vector2i
var attack_timer := 0.0
var show_range := false
var level := 1
const MAX_LEVEL := 3

# Visual state
var fire_flash_timer := 0.0

# Role-specific state
var aura_timer := 0.0
var instability := 0.0  # Volatile
var wave_shots := 0      # Late


func setup(p_grid_pos: Vector2i, p_tower_def: Dictionary) -> void:
	tower_def = p_tower_def
	grid_pos = p_grid_pos
	position = GameManager.grid_to_world(grid_pos)
	add_to_group("towers")
	GameManager.wave_started.connect(_on_wave_started)


func _on_wave_started(_wave: int) -> void:
	wave_shots = 0


func get_damage() -> float:
	var base: float = tower_def["damage"] * (1.0 + (level - 1) * 0.35)
	if tower_def["role"] == "Anchor":
		base *= 1.15
	return base


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
	# Fire flash decay
	if fire_flash_timer > 0:
		fire_flash_timer -= delta
		queue_redraw()

	var atk_speed := get_attack_speed()
	if atk_speed <= 0:
		return

	# Aura towers tick damage, no projectiles
	if tower_def["role"] == "Aura":
		_tick_aura(delta)
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
	var base_damage := get_damage() * combo * _get_support_bonus()

	fire_flash_timer = 0.12

	match tower_def["role"]:
		"AoE":
			_fire_aoe(target, base_damage)
		"Chain":
			_fire_chain(target, base_damage)
		"Finisher":
			_fire_finisher(target, base_damage)
		"Volatile":
			_fire_volatile(target, base_damage)
		"Late":
			_fire_late(target, base_damage)
		"Control":
			_fire_control(target, base_damage)
		_:
			_fire_standard(target, base_damage)


func _fire_standard(target: EnemyEntity, damage: float) -> void:
	var proj := _create_projectile(target, damage)
	_add_projectile(proj)


func _fire_aoe(target: EnemyEntity, damage: float) -> void:
	var proj := _create_projectile(target, damage)
	proj.aoe_radius = 1.5 * GameManager.CELL_SIZE
	proj.proj_size = 6.0
	_add_projectile(proj)


func _fire_chain(target: EnemyEntity, damage: float) -> void:
	var bounces := 2 + mini(level - 1, 2)  # 2-4 bounces
	var proj := _create_projectile(target, damage)
	proj.chain_remaining = bounces
	proj.chain_radius = 2.0 * GameManager.CELL_SIZE
	proj.chain_damage_decay = 0.75
	proj.chain_hit_ids = [target.get_instance_id()]
	_add_projectile(proj)


func _fire_finisher(target: EnemyEntity, damage: float) -> void:
	# Up to 2x damage on low-HP enemies
	var hp_ratio := clampf(target.hp / target.max_hp, 0.0, 1.0)
	var execute_mult := 1.0 + (1.0 - hp_ratio)
	var proj := _create_projectile(target, damage * execute_mult)
	proj.proj_size = 6.0
	proj.speed = 600.0
	_add_projectile(proj)


func _fire_volatile(target: EnemyEntity, damage: float) -> void:
	# Check misfire
	if instability >= 1.0:
		instability = 0.0
		fire_flash_timer = 0.3  # longer red flash for misfire
		return

	var proj := _create_projectile(target, damage * 1.5)
	_add_projectile(proj)
	var instability_gain := 0.1 if level < 3 else 0.07
	instability += instability_gain


func _fire_late(target: EnemyEntity, damage: float) -> void:
	wave_shots += 1
	var ramp := 0.5 + minf(wave_shots * 0.05, 1.5)
	var proj := _create_projectile(target, damage * ramp)
	_add_projectile(proj)


func _fire_control(target: EnemyEntity, damage: float) -> void:
	target.apply_slow(1.4 + level * 0.1, 1.5 + level * 0.3)
	var proj := _create_projectile(target, damage)
	_add_projectile(proj)


func _tick_aura(delta: float) -> void:
	aura_timer += delta
	if aura_timer < 0.5:
		return
	aura_timer -= 0.5

	var range_px: float = get_range() * GameManager.CELL_SIZE
	var damage := get_damage() * 0.5 * _get_support_bonus()  # half damage per tick
	var enemies := get_tree().get_nodes_in_group("enemies")
	var hit_any := false

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if position.distance_to(enemy.position) <= range_px:
			enemy.take_damage(damage, tower_def["element"])
			hit_any = true

	if hit_any:
		fire_flash_timer = 0.1
		# Redraw battlefield for terrain
		var battlefield := get_node_or_null("/root/Main/Battlefield")
		if battlefield:
			battlefield.queue_redraw()


func _create_projectile(target: EnemyEntity, damage: float) -> ProjectileEntity:
	var proj := ProjectileEntity.new()
	var proj_color: Color = GameManager.faction_colors[tower_def["faction"]]
	proj.setup(position, target, damage, proj_color, tower_def["element"])
	return proj


func _add_projectile(proj: ProjectileEntity) -> void:
	var proj_container := get_node_or_null("/root/Main/Entities/Projectiles")
	if proj_container:
		proj_container.add_child(proj)
	else:
		get_tree().root.add_child(proj)


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
		# Spawn combo popup
		var popup := DamageNumber.new()
		var world_pos := GameManager.grid_to_world(tile_pos)
		popup.setup(world_pos + Vector2(0, -30), bonus, Color(1.0, 0.85, 0.2), true)
		var container := get_node_or_null("/root/Main/Entities/Projectiles")
		if container:
			container.add_child(popup)

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

	# Fire flash overlay
	if fire_flash_timer > 0:
		var flash_alpha := clampf(fire_flash_timer / 0.12, 0.0, 1.0) * 0.5
		var flash_color := Color.WHITE if instability < 1.0 else Color.RED
		draw_rect(Rect2(-half, -half, half * 2, half * 2), Color(flash_color, flash_alpha))

	# Level pips
	for i in range(level):
		var pip_x := -8.0 + i * 10.0
		draw_circle(Vector2(pip_x, half - 8), 3.5, Color.WHITE)

	# Aura range indicator (always visible for Aura towers)
	if tower_def["role"] == "Aura":
		var range_px: float = get_range() * GameManager.CELL_SIZE
		draw_arc(Vector2.ZERO, range_px, 0, TAU, 48, Color(1.0, 0.5, 0.1, 0.12), 2.0)

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
			draw_rect(Rect2(-5, -5, 10, 10), icon_color, true)
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
