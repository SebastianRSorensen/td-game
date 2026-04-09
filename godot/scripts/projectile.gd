class_name ProjectileEntity
extends Node2D

var target: Node2D
var damage: float
var speed := 450.0
var color: Color
var proj_size := 4.0


func setup(start_pos: Vector2, p_target: Node2D, p_damage: float, p_color: Color) -> void:
	position = start_pos
	target = p_target
	damage = p_damage
	color = p_color


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var direction := (target.position - position).normalized()
	position += direction * speed * delta

	if position.distance_to(target.position) < 10.0:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()
		return

	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, proj_size, color)
	draw_circle(Vector2.ZERO, proj_size * 0.5, color.lightened(0.5))
