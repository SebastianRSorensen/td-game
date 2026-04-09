class_name EnemyEntity
extends Node2D

signal died(scrap_reward: int)
signal reached_end(damage: float)

var hp: float
var max_hp: float
var speed: float
var reward: int
var enemy_size: float
var enemy_color: Color
var enemy_name: String
var traits: Array[String] = []

var path_index := 0
var path_points: Array[Vector2] = []
var slow_timer := 0.0
var slow_factor := 1.0

# Death animation
var dying := false
var death_timer := 0.0
const DEATH_DURATION := 0.3

# Shield (bulwark-shield trait)
var shield := 0.0
var max_shield := 0.0

# Damage flash
var flash_timer := 0.0


func setup(data: Dictionary) -> void:
	enemy_name = data["name"]
	hp = data["hp"]
	max_hp = hp
	speed = data["speed"]
	reward = data["reward"]
	enemy_size = data["size"]
	enemy_color = data["color"]
	if data.has("traits"):
		traits = data["traits"]

	# Trait: bulwark-shield
	if "bulwark-shield" in traits:
		shield = max_hp * 0.3
		max_shield = shield

	for grid_pos in GameManager.enemy_path:
		path_points.append(GameManager.grid_to_world(grid_pos))

	if path_points.size() > 0:
		position = path_points[0]
	path_index = 0


func _process(delta: float) -> void:
	# Death animation
	if dying:
		death_timer += delta
		var t := death_timer / DEATH_DURATION
		scale = Vector2.ONE * (1.0 - t)
		modulate.a = 1.0 - t
		if death_timer >= DEATH_DURATION:
			queue_free()
		else:
			queue_redraw()
		return

	if path_index >= path_points.size() - 1:
		reached_end.emit(0.08)
		queue_free()
		return

	var target_pos := path_points[path_index + 1]
	var direction := (target_pos - position).normalized()

	# Terrain movement modifier
	var grid_pos := GameManager.world_to_grid(position)
	var terrain := GameManager.get_terrain(grid_pos)
	var move_mod := GameManager.get_movement_modifier(terrain)

	# Trait: burrower ignores terrain
	if "burrower" in traits:
		move_mod = 1.0

	# Slow debuff
	if slow_timer > 0:
		slow_timer -= delta
		move_mod *= slow_factor

	var effective_speed := speed / move_mod
	position += direction * effective_speed * delta

	if position.distance_to(target_pos) < effective_speed * delta + 2.0:
		position = target_pos
		path_index += 1

	# Flash decay
	if flash_timer > 0:
		flash_timer -= delta

	queue_redraw()


func take_damage(amount: float, element: String = "") -> void:
	if dying:
		return

	# Trait: heat-fed — fire heals instead of damaging
	if "heat-fed" in traits and element == "fire":
		hp = minf(max_hp, hp + amount * 0.5)
		_spawn_damage_number(amount * 0.5, Color(0.3, 1.0, 0.3))  # green = heal
		return

	# Trait: purgeblood — 60% reduction from corruption/poison
	if "purgeblood" in traits and element in ["corruption", "poison"]:
		amount *= 0.4

	# Shield absorbs damage first
	if shield > 0:
		if amount <= shield:
			shield -= amount
			_spawn_damage_number(amount, Color(0.6, 0.7, 1.0))  # blue = shield
			return
		else:
			amount -= shield
			shield = 0

	hp -= amount
	GameManager.wave_damage_dealt += amount
	flash_timer = 0.1

	_spawn_damage_number(amount, Color.WHITE)

	if hp <= 0:
		dying = true
		death_timer = 0.0
		died.emit(reward)


func apply_slow(factor: float, duration: float) -> void:
	# Trait: momentum-burst — immune to slow
	if "momentum-burst" in traits:
		return
	slow_factor = factor
	slow_timer = duration


func _spawn_damage_number(amount: float, color: Color) -> void:
	var dmg_num := DamageNumber.new()
	dmg_num.setup(position + Vector2(0, -enemy_size - 16), amount, color)
	var container := get_node_or_null("/root/Main/Entities/Projectiles")
	if container:
		container.add_child(dmg_num)


func _draw() -> void:
	# Shadow
	draw_circle(Vector2(2, 2), enemy_size, Color(0, 0, 0, 0.3))

	# Damage flash
	var body_color := enemy_color
	if flash_timer > 0:
		body_color = body_color.lerp(Color.WHITE, clampf(flash_timer / 0.1, 0.0, 1.0) * 0.7)

	# Body
	draw_circle(Vector2.ZERO, enemy_size, body_color)

	# Outline
	draw_arc(Vector2.ZERO, enemy_size, 0, TAU, 32, body_color.darkened(0.3), 2.0)

	# Slow indicator — blue ring
	if slow_timer > 0:
		draw_arc(Vector2.ZERO, enemy_size + 3, 0, TAU, 24, Color(0.3, 0.6, 1.0, 0.6), 2.5)

	# Trait indicators — colored pips above HP bar
	var pip_y := -enemy_size - 20.0
	var pip_x := -float(traits.size()) * 5.0
	for trait_name in traits:
		var trait_color := _trait_color(trait_name)
		draw_circle(Vector2(pip_x, pip_y), 3.0, trait_color)
		pip_x += 10.0

	# HP bar
	var bar_width := enemy_size * 3.5
	var bar_height := 5.0
	var bar_pos := Vector2(-bar_width / 2.0, -enemy_size - 12.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.2, 0.0, 0.0))
	var hp_ratio := clampf(hp / max_hp, 0.0, 1.0)
	var hp_color := Color.GREEN.lerp(Color.RED, 1.0 - hp_ratio)
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), hp_color)

	# Shield bar (if bulwark-shield)
	if max_shield > 0:
		var shield_ratio := clampf(shield / max_shield, 0.0, 1.0)
		var shield_pos := Vector2(bar_pos.x, bar_pos.y - 5.0)
		draw_rect(Rect2(shield_pos, Vector2(bar_width, 3.0)), Color(0.15, 0.15, 0.3))
		draw_rect(Rect2(shield_pos, Vector2(bar_width * shield_ratio, 3.0)), Color(0.5, 0.6, 1.0))


func _trait_color(trait_name: String) -> Color:
	match trait_name:
		"heat-fed":
			return Color(1.0, 0.5, 0.1)
		"momentum-burst":
			return Color(0.2, 0.9, 0.3)
		"burrower":
			return Color(0.6, 0.4, 0.2)
		"bulwark-shield":
			return Color(0.5, 0.6, 1.0)
		"purgeblood":
			return Color(0.7, 0.2, 0.8)
		_:
			return Color.GRAY
