extends Node2D

@onready var battlefield: Node2D = $Battlefield
@onready var towers_container: Node2D = $Entities/Towers
@onready var enemies_container: Node2D = $Entities/Enemies
@onready var projectiles_container: Node2D = $Entities/Projectiles
@onready var wave_manager: Node = $WaveManager
@onready var adaptation: Node = $AdaptationDirector
@onready var hud: Control = $UI/HUD
@onready var tower_panel: Control = $UI/TowerPanel

var placed_towers: Dictionary = {}  # Vector2i -> TowerEntity
var selected_tower: TowerEntity = null


func _ready() -> void:
	wave_manager.all_enemies_dead.connect(_on_all_enemies_dead)
	hud.start_wave_pressed.connect(_on_start_wave)
	hud.ability_pressed.connect(_on_ability_pressed)
	hud.upgrade_pressed.connect(_on_upgrade_pressed)
	hud.sell_pressed.connect(_on_sell_pressed)
	GameManager.game_over.connect(_on_game_over)

	get_viewport().get_window().title = "WILDCORE"
	battlefield.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_deselect_all()

	if event is InputEventMouseMotion:
		var grid_pos := GameManager.world_to_grid(event.position)
		if GameManager.is_valid_grid_pos(grid_pos):
			battlefield.set_hover_pos(grid_pos)
		else:
			battlefield.set_hover_pos(Vector2i(-1, -1))


func _handle_left_click(screen_pos: Vector2) -> void:
	var grid_pos := GameManager.world_to_grid(screen_pos)

	# If we have a tower selected for placement, try to place it
	if GameManager.selected_tower_index >= 0:
		_try_place_tower(screen_pos)
		return

	# Check if clicking on a placed tower
	if GameManager.is_valid_grid_pos(grid_pos) and placed_towers.has(grid_pos):
		_select_placed_tower(placed_towers[grid_pos])
		return

	# Clicked on empty space — deselect
	_deselect_all()


func _deselect_all() -> void:
	tower_panel.deselect()
	_deselect_tower()
	battlefield.set_hover_pos(Vector2i(-1, -1))


func _select_placed_tower(tower: TowerEntity) -> void:
	# Deselect previous
	if selected_tower and is_instance_valid(selected_tower):
		selected_tower.show_range = false
		selected_tower.queue_redraw()

	# Deselect panel selection
	tower_panel.deselect()

	selected_tower = tower
	tower.show_range = true
	tower.queue_redraw()
	hud.show_tower_info(tower)


func _deselect_tower() -> void:
	if selected_tower and is_instance_valid(selected_tower):
		selected_tower.show_range = false
		selected_tower.queue_redraw()
	selected_tower = null
	hud.hide_tower_info()


func _try_place_tower(screen_pos: Vector2) -> void:
	if GameManager.selected_tower_index < 0:
		return

	var grid_pos := GameManager.world_to_grid(screen_pos)
	if not GameManager.is_valid_grid_pos(grid_pos):
		return
	if GameManager.is_path_tile(grid_pos):
		hud.show_info("Cannot place on the enemy path!", Color.RED)
		return
	if placed_towers.has(grid_pos):
		hud.show_info("Tile already occupied!", Color.RED)
		return

	var tower_def: Dictionary = GameManager.tower_defs[GameManager.selected_tower_index]
	if not GameManager.spend_scrap(tower_def["cost"]):
		hud.show_info("Not enough scrap! Need %d" % tower_def["cost"], Color.RED)
		return

	var tower := TowerEntity.new()
	tower.setup(grid_pos, tower_def)
	placed_towers[grid_pos] = tower
	towers_container.add_child(tower)

	GameManager.set_terrain(grid_pos, tower_def["terrain_aura"] as GameManager.TerrainState)
	battlefield.mark_placed(grid_pos)

	hud.show_info("Placed %s" % tower_def["name"], Color(0.5, 1.0, 0.5))
	GameManager.tower_placed.emit()


func _on_upgrade_pressed() -> void:
	if not selected_tower or not is_instance_valid(selected_tower):
		return
	if selected_tower.level >= TowerEntity.MAX_LEVEL:
		hud.show_info("Already at max level!", Color.YELLOW)
		return
	var cost := selected_tower.get_upgrade_cost()
	if selected_tower.upgrade():
		hud.show_info("Upgraded %s to level %d!" % [selected_tower.tower_def["name"], selected_tower.level], Color(0.5, 1.0, 0.5))
		hud.show_tower_info(selected_tower)
	else:
		hud.show_info("Not enough scrap! Need %d" % cost, Color.RED)


func _on_sell_pressed() -> void:
	if not selected_tower or not is_instance_valid(selected_tower):
		return
	var refund := selected_tower.get_sell_value()
	var tower_name: String = selected_tower.tower_def["name"]
	var gpos := selected_tower.grid_pos

	GameManager.add_scrap(refund)
	GameManager.set_terrain(gpos, GameManager.TerrainState.NATURAL)
	placed_towers.erase(gpos)
	battlefield.placed_positions.erase(gpos)
	selected_tower.queue_free()
	selected_tower = null

	hud.hide_tower_info()
	hud.show_info("Sold %s for %d scrap" % [tower_name, refund], Color(0.9, 0.8, 0.3))
	battlefield.queue_redraw()


func _on_start_wave() -> void:
	if GameManager.wave_in_progress:
		return
	if GameManager.current_wave >= GameManager.total_waves:
		return

	GameManager.current_wave += 1
	wave_manager.start_wave(GameManager.current_wave)

	var node := GameManager.node_plan[GameManager.current_wave - 1]
	var biome_name: String = GameManager.biome_names[node["biome"]]
	var type_name: String = GameManager.node_type_names[node["node_type"]]
	hud.show_info("Wave %d - %s [%s]" % [GameManager.current_wave, biome_name, type_name])


func _on_all_enemies_dead() -> void:
	for tower in get_tree().get_nodes_in_group("towers"):
		if tower.tower_def["name"] == "Oil Extractor":
			GameManager.add_scrap(14)
			GameManager.biome_pressure += 0.02

	_apply_node_rewards()
	_run_adaptation()

	var pressure_tick := randf_range(0.02, 0.06) + GameManager.biome_pressure
	GameManager.reduce_integrity(pressure_tick)

	GameManager.wave_in_progress = false
	GameManager.wave_ended.emit(GameManager.current_wave)

	if GameManager.current_wave >= GameManager.total_waves and GameManager.integrity > 0:
		GameManager.game_over.emit(true)
	elif GameManager.integrity > 0:
		hud.show_info("Wave %d cleared! Place towers and start next wave." % GameManager.current_wave, Color(0.5, 1.0, 0.5))


func _apply_node_rewards() -> void:
	if GameManager.current_wave < 1:
		return
	var node: Dictionary = GameManager.node_plan[GameManager.current_wave - 1]
	var node_type: GameManager.NodeType = node["node_type"] as GameManager.NodeType

	match node_type:
		GameManager.NodeType.RESOURCE_CACHE:
			GameManager.add_scrap(45)
			GameManager.essence += 8
		GameManager.NodeType.SHRINE:
			GameManager.integrity = minf(1.2, GameManager.integrity + 0.12)
			GameManager.biome_pressure = maxf(0.0, GameManager.biome_pressure - 0.03)
		GameManager.NodeType.ANOMALY:
			GameManager.essence += 12
			GameManager.biome_pressure += 0.05
		GameManager.NodeType.ELITE:
			GameManager.add_scrap(28)
			GameManager.essence += 10
		GameManager.NodeType.BOSS:
			GameManager.add_scrap(60)
			GameManager.essence += 20

	GameManager.core_charge = mini(4, GameManager.core_charge + 1)
	GameManager.resources_changed.emit()


func _run_adaptation() -> void:
	var towers_arr := get_tree().get_nodes_in_group("towers")
	var total := maxf(1.0, towers_arr.size())

	var fire_count := 0
	var control_count := 0
	var corruption_count := 0

	for tower in towers_arr:
		if tower.tower_def["element"] == "fire":
			fire_count += 1
		if tower.tower_def["role"] in ["Control", "Support"]:
			control_count += 1
		if tower.tower_def["element"] == "corruption":
			corruption_count += 1

	var transformed := 0
	for pos in GameManager.tile_states:
		if GameManager.tile_states[pos] != GameManager.TerrainState.NATURAL:
			transformed += 1
	var transformed_ratio := float(transformed) / float(GameManager.GRID_WIDTH * GameManager.GRID_HEIGHT)

	var metrics := {
		"burn_share": minf(1.0, fire_count / total + randf_range(0.1, 0.3)),
		"slow_dilation": minf(1.0, control_count / total + randf_range(0.0, 0.25)),
		"path_extension": minf(1.0, transformed_ratio + randf_range(0.0, 0.2)),
		"early_kill_share": minf(1.0, GameManager.wave_damage_dealt / 170.0),
		"corruption_stacks": corruption_count * 14.0 / total,
		"corruption_kill_share": minf(1.0, corruption_count / total + randf_range(0.05, 0.25)),
	}

	adaptation.ingest(metrics)
	adaptation.forecast(GameManager.current_wave, GameManager.integrity)


func _on_ability_pressed() -> void:
	if GameManager.core_charge <= 0:
		hud.show_info("No core charges remaining!", Color.RED)
		return

	GameManager.core_charge -= 1

	var x := randi_range(1, GameManager.GRID_WIDTH - 2)
	var y := randi_range(0, GameManager.GRID_HEIGHT - 1)
	var pos := Vector2i(x, y)

	match GameManager.commander:
		GameManager.Commander.WARDEN:
			GameManager.set_terrain(pos, GameManager.TerrainState.OVERGROWN)
			GameManager.story_moments.append("Wave %d: Warden overgrowth stabilized a lane" % GameManager.current_wave)
			hud.show_info("Overgrowth Surge! Terrain transformed.", Color(0.2, 0.9, 0.3))
		GameManager.Commander.FOREMAN:
			GameManager.set_terrain(pos, GameManager.TerrainState.SCORCHED)
			GameManager.biome_pressure += 0.03
			GameManager.story_moments.append("Wave %d: Foreman ignition burned a collapse lane" % GameManager.current_wave)
			hud.show_info("Ignition Sweep! Watch the pressure.", Color(0.9, 0.5, 0.2))
		GameManager.Commander.SEER:
			GameManager.set_terrain(pos, GameManager.TerrainState.UNSTABLE)
			GameManager.essence += 4
			GameManager.story_moments.append("Wave %d: Seer void pulse rewired the battlefield" % GameManager.current_wave)
			hud.show_info("Void Pulse! Essence gained.", Color(0.6, 0.3, 0.9))

	GameManager.resources_changed.emit()
	battlefield.queue_redraw()


func _on_game_over(_won: bool) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0.06, 0.07, 0.09))
