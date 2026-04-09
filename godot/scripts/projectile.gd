class_name ProjectileEntity
extends Node2D

var target: Node2D
var damage: float
var speed := 450.0
var color: Color
var proj_size := 4.0
var element: String = ""

# AoE fields
var aoe_radius := 0.0

# Chain fields
var chain_remaining := 0
var chain_radius := 0.0
var chain_damage_decay := 0.75
var chain_hit_ids: Array[int] = []


func setup(start_pos: Vector2, p_target: Node2D, p_damage: float, p_color: Color, p_element: String = "") -> void:
	position = start_pos
	target = p_target
	damage = p_damage
	color = p_color
	element = p_element


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		if aoe_radius > 0:
			_explode_aoe(position)
		queue_free()
		return

	var direction := (target.position - position).normalized()
	position += direction * speed * delta

	if position.distance_to(target.position) < 10.0:
		_on_hit()
		return

	queue_redraw()


func _on_hit() -> void:
	var hit_pos := target.position

	if aoe_radius > 0:
		_explode_aoe(hit_pos)
	else:
		if target.has_method("take_damage"):
			target.take_damage(damage, element)

	if chain_remaining > 0:
		_try_chain(hit_pos)

	queue_free()


func _explode_aoe(center: Vector2) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.position.distance_to(center) <= aoe_radius:
			enemy.take_damage(damage, element)

	# Spawn AoE visual
	var vfx := AoEFlash.new()
	vfx.setup(center, aoe_radius)
	get_parent().add_child(vfx)


func _try_chain(from_pos: Vector2) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var best_enemy: Node2D = null
	var best_dist := INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.get_instance_id() in chain_hit_ids:
			continue
		var dist := from_pos.distance_to(enemy.position)
		if dist <= chain_radius and dist < best_dist:
			best_enemy = enemy
			best_dist = dist

	if best_enemy:
		var new_proj := ProjectileEntity.new()
		new_proj.setup(from_pos, best_enemy, damage * chain_damage_decay, color, element)
		new_proj.chain_remaining = chain_remaining - 1
		new_proj.chain_radius = chain_radius
		new_proj.chain_damage_decay = chain_damage_decay
		new_proj.chain_hit_ids = chain_hit_ids.duplicate()
		new_proj.chain_hit_ids.append(best_enemy.get_instance_id())
		new_proj.speed = 600.0  # chain bolts move faster
		get_parent().add_child(new_proj)


func _draw() -> void:
	draw_circle(Vector2.ZERO, proj_size, color)
	draw_circle(Vector2.ZERO, proj_size * 0.5, color.lightened(0.5))


# ---- AoE Flash Visual ----
class AoEFlash extends Node2D:
	var radius := 0.0
	var elapsed := 0.0
	var lifetime := 0.25

	func setup(pos: Vector2, r: float) -> void:
		position = pos
		radius = r

	func _process(delta: float) -> void:
		elapsed += delta
		if elapsed >= lifetime:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var alpha := clampf(1.0 - elapsed / lifetime, 0.0, 1.0) * 0.3
		draw_circle(Vector2.ZERO, radius, Color(1, 0.8, 0.3, alpha))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1, 0.9, 0.4, alpha * 2), 2.0)
