class_name DamageNumber
extends Node2D

var text: String
var font_color: Color
var velocity := Vector2(0, -70)
var lifetime := 0.7
var elapsed := 0.0
var font_size := 18
var is_combo := false

var _label: Label


func setup(pos: Vector2, amount: float, color: Color, combo := false) -> void:
	position = pos
	font_color = color
	is_combo = combo

	if combo:
		text = "COMBO +%d%%" % int((amount - 1.0) * 100)
		font_size = 24
		lifetime = 1.0
		velocity = Vector2(0, -50)
	else:
		text = str(int(amount))
		font_size = 18
		velocity = Vector2(randf_range(-25, 25), -65)


func _ready() -> void:
	_label = Label.new()
	_label.text = text
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", font_color)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-40, -12)
	_label.size = Vector2(80, 30)
	add_child(_label)


func _process(delta: float) -> void:
	elapsed += delta
	position += velocity * delta
	velocity.y += 50 * delta

	var alpha := clampf(1.0 - elapsed / lifetime, 0.0, 1.0)
	_label.modulate.a = alpha

	if is_combo:
		var s := 1.0 + (1.0 - alpha) * 0.3
		_label.scale = Vector2(s, s)

	if elapsed >= lifetime:
		queue_free()
