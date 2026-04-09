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

	for grid_pos in GameManager.enemy_path:
		path_points.append(GameManager.grid_to_world(grid_pos))

	if path_points.size() > 0:
		position = path_points[0]
	path_index = 0


func _process(delta: float) -> void:
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

	# Slow debuff
	if slow_timer > 0:
		slow_timer -= delta
		move_mod *= slow_factor

	var effective_speed := speed / move_mod
	position += direction * effective_speed * delta

	if position.distance_to(target_pos) < effective_speed * delta + 2.0:
		position = target_pos
		path_index += 1

	queue_redraw()


func take_damage(amount: float) -> void:
	hp -= amount
	GameManager.wave_damage_dealt += amount
	if hp <= 0:
		died.emit(reward)
		queue_free()


func apply_slow(factor: float, duration: float) -> void:
	slow_factor = factor
	slow_timer = duration


func _draw() -> void:
	# Shadow
	draw_circle(Vector2(2, 2), enemy_size, Color(0, 0, 0, 0.3))
	# Body
	draw_circle(Vector2.ZERO, enemy_size, enemy_color)
	# Outline
	draw_arc(Vector2.ZERO, enemy_size, 0, TAU, 32, enemy_color.darkened(0.3), 2.0)

	# HP bar
	var bar_width := enemy_size * 3.5
	var bar_height := 5.0
	var bar_pos := Vector2(-bar_width / 2.0, -enemy_size - 12.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.2, 0.0, 0.0))
	var hp_ratio := clampf(hp / max_hp, 0.0, 1.0)
	var hp_color := Color.GREEN.lerp(Color.RED, 1.0 - hp_ratio)
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), hp_color)
