extends Node2D

var hover_pos := Vector2i(-1, -1)
var placed_positions: Dictionary = {}  # Vector2i -> true


func set_hover_pos(pos: Vector2i) -> void:
	hover_pos = pos
	queue_redraw()


func mark_placed(pos: Vector2i) -> void:
	placed_positions[pos] = true
	queue_redraw()


func _draw() -> void:
	_draw_tiles()
	_draw_path()
	_draw_grid_lines()
	_draw_hover()


func _draw_tiles() -> void:
	for y in range(GameManager.GRID_HEIGHT):
		for x in range(GameManager.GRID_WIDTH):
			var grid_pos := Vector2i(x, y)
			var terrain := GameManager.get_terrain(grid_pos)
			var color: Color = GameManager.terrain_colors[terrain]
			var rect := Rect2(
				GameManager.GRID_OFFSET.x + x * GameManager.CELL_SIZE,
				GameManager.GRID_OFFSET.y + y * GameManager.CELL_SIZE,
				GameManager.CELL_SIZE, GameManager.CELL_SIZE
			)
			draw_rect(rect, color)


func _draw_path() -> void:
	# Draw path tiles with a lighter overlay
	for grid_pos in GameManager.enemy_path:
		var rect := Rect2(
			GameManager.GRID_OFFSET.x + grid_pos.x * GameManager.CELL_SIZE,
			GameManager.GRID_OFFSET.y + grid_pos.y * GameManager.CELL_SIZE,
			GameManager.CELL_SIZE, GameManager.CELL_SIZE
		)
		draw_rect(rect, Color(1, 1, 1, 0.08))

	# Draw path direction lines
	for i in range(GameManager.enemy_path.size() - 1):
		var from_pos := GameManager.grid_to_world(GameManager.enemy_path[i])
		var to_pos := GameManager.grid_to_world(GameManager.enemy_path[i + 1])
		draw_line(from_pos, to_pos, Color(1, 1, 1, 0.2), 2.0)

	# Entry and exit markers
	if GameManager.enemy_path.size() >= 2:
		var entry := GameManager.grid_to_world(GameManager.enemy_path[0])
		draw_circle(entry, 8, Color(0, 1, 0, 0.5))
		var exit_pos := GameManager.grid_to_world(GameManager.enemy_path[-1])
		draw_circle(exit_pos, 8, Color(1, 0, 0, 0.5))


func _draw_grid_lines() -> void:
	var line_color := Color(1, 1, 1, 0.1)
	var ox := GameManager.GRID_OFFSET.x
	var oy := GameManager.GRID_OFFSET.y
	var cs := GameManager.CELL_SIZE

	for x in range(GameManager.GRID_WIDTH + 1):
		var x_pos := ox + x * cs
		draw_line(
			Vector2(x_pos, oy),
			Vector2(x_pos, oy + GameManager.GRID_HEIGHT * cs),
			line_color, 1.0
		)
	for y in range(GameManager.GRID_HEIGHT + 1):
		var y_pos := oy + y * cs
		draw_line(
			Vector2(ox, y_pos),
			Vector2(ox + GameManager.GRID_WIDTH * cs, y_pos),
			line_color, 1.0
		)


func _draw_hover() -> void:
	if hover_pos == Vector2i(-1, -1):
		return
	if not GameManager.is_valid_grid_pos(hover_pos):
		return

	var rect := Rect2(
		GameManager.GRID_OFFSET.x + hover_pos.x * GameManager.CELL_SIZE + 2,
		GameManager.GRID_OFFSET.y + hover_pos.y * GameManager.CELL_SIZE + 2,
		GameManager.CELL_SIZE - 4, GameManager.CELL_SIZE - 4
	)

	var can_place := _can_place_at(hover_pos)
	var color: Color
	if GameManager.selected_tower_index >= 0:
		color = Color(0, 1, 0, 0.3) if can_place else Color(1, 0, 0, 0.3)
	else:
		color = Color(1, 1, 1, 0.1)

	draw_rect(rect, color)
	draw_rect(rect, color.lightened(0.3), false, 2.0)

	# Show selected tower range preview
	if can_place and GameManager.selected_tower_index >= 0:
		var td := GameManager.tower_defs[GameManager.selected_tower_index]
		var range_px: float = td["range"] * GameManager.CELL_SIZE
		var center := GameManager.grid_to_world(hover_pos)
		draw_arc(center, range_px, 0, TAU, 64, Color(1, 1, 1, 0.12), 1.0)


func _can_place_at(pos: Vector2i) -> bool:
	if GameManager.is_path_tile(pos):
		return false
	if placed_positions.has(pos):
		return false
	if GameManager.selected_tower_index < 0:
		return false
	var td := GameManager.tower_defs[GameManager.selected_tower_index]
	if GameManager.scrap < td["cost"]:
		return false
	return true
