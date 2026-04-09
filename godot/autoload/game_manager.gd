extends Node

# ---- Enums ----
enum Faction { WILD_GROWTH, IRON_DOMINION, VOID_BLOOM }
enum TerrainState { NATURAL, SCORCHED, FROZEN, FLOODED, CORRUPTED, OVERGROWN, CRATERED, INDUSTRIAL, ELECTRIFIED, UNSTABLE }
enum Biome { VERDANT_BASIN, IRON_SCAR, HOLLOW_VEIL }
enum Commander { WARDEN, FOREMAN, SEER }
enum NodeType { BATTLE, ELITE, RESOURCE_CACHE, ANOMALY, SHRINE, MERCHANT, BOSS }

# ---- Signals ----
signal wave_started(wave_number: int)
signal wave_ended(wave_number: int)
signal resources_changed
signal integrity_changed(value: float)
signal game_over(won: bool)
signal tower_placed
signal adaptation_forecasted(forecast: Dictionary)

# ---- Constants ----
const GRID_WIDTH := 8
const GRID_HEIGHT := 5
const CELL_SIZE := 128
const GRID_OFFSET := Vector2(80, 100)

# ---- Tower Definitions ----
var tower_defs: Array[Dictionary] = []

# ---- Colors ----
var faction_colors := {
	Faction.WILD_GROWTH: Color(0.2, 0.8, 0.3),
	Faction.IRON_DOMINION: Color(0.85, 0.55, 0.2),
	Faction.VOID_BLOOM: Color(0.65, 0.2, 0.85),
}

var terrain_colors := {
	TerrainState.NATURAL: Color(0.22, 0.28, 0.18),
	TerrainState.SCORCHED: Color(0.75, 0.25, 0.1),
	TerrainState.FROZEN: Color(0.55, 0.75, 0.9),
	TerrainState.FLOODED: Color(0.15, 0.35, 0.75),
	TerrainState.CORRUPTED: Color(0.5, 0.1, 0.45),
	TerrainState.OVERGROWN: Color(0.1, 0.55, 0.15),
	TerrainState.CRATERED: Color(0.5, 0.4, 0.25),
	TerrainState.INDUSTRIAL: Color(0.55, 0.55, 0.55),
	TerrainState.ELECTRIFIED: Color(0.25, 0.65, 0.9),
	TerrainState.UNSTABLE: Color(0.7, 0.15, 0.25),
}

var faction_names := {
	Faction.WILD_GROWTH: "Wild Growth",
	Faction.IRON_DOMINION: "Iron Dominion",
	Faction.VOID_BLOOM: "Void Bloom",
}

var biome_names := {
	Biome.VERDANT_BASIN: "Verdant Basin",
	Biome.IRON_SCAR: "Iron Scar",
	Biome.HOLLOW_VEIL: "Hollow Veil",
}

var node_type_names := {
	NodeType.BATTLE: "Battle",
	NodeType.ELITE: "Elite",
	NodeType.RESOURCE_CACHE: "Resource Cache",
	NodeType.ANOMALY: "Anomaly",
	NodeType.SHRINE: "Shrine",
	NodeType.MERCHANT: "Merchant",
	NodeType.BOSS: "Boss",
}

var commander_names := {
	Commander.WARDEN: "The Warden",
	Commander.FOREMAN: "The Foreman",
	Commander.SEER: "The Seer",
}

# ---- Enemy Path (grid coordinates) ----
var enemy_path: Array[Vector2i] = [
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
	Vector2i(2, 1), Vector2i(2, 0),
	Vector2i(3, 0), Vector2i(4, 0),
	Vector2i(4, 1), Vector2i(4, 2), Vector2i(4, 3), Vector2i(4, 4),
	Vector2i(5, 4), Vector2i(6, 4),
	Vector2i(6, 3), Vector2i(6, 2),
	Vector2i(7, 2),
]

# ---- Game State ----
var current_wave := 0
var total_waves := 12
var integrity := 1.0
var scrap := 120
var essence := 0
var core_charge := 2
var biome_pressure := 0.0
var commander: Commander = Commander.WARDEN
var wave_in_progress := false
var enemy_traits: Array[String] = []
var story_moments: Array[String] = []
var selected_tower_index := -1
var wave_damage_dealt := 0.0

# ---- Tile State ----
var tile_states: Dictionary = {}  # Vector2i -> TerrainState

# ---- Node Plan ----
var node_plan: Array[Dictionary] = []


func _ready() -> void:
	_init_tower_defs()
	_build_node_plan()
	_apply_commander_start_bonus()
	_init_tile_states()


func _init_tile_states() -> void:
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			tile_states[Vector2i(x, y)] = TerrainState.NATURAL


func _init_tower_defs() -> void:
	tower_defs = [
		_tower("Thorn Nest", Faction.WILD_GROWTH, "DPS", "growth", 11, 2, TerrainState.OVERGROWN, 30, 1.0),
		_tower("Root Spire", Faction.WILD_GROWTH, "Control", "growth", 8, 2, TerrainState.OVERGROWN, 25, 0.8),
		_tower("Bloom Shrine", Faction.WILD_GROWTH, "Support", "growth", 0, 2, TerrainState.OVERGROWN, 20, 0.0),
		_tower("Spore Pod", Faction.WILD_GROWTH, "AoE", "poison", 10, 2, TerrainState.CORRUPTED, 35, 0.7),
		_tower("Greatbark Sentinel", Faction.WILD_GROWTH, "Anchor", "growth", 20, 2, TerrainState.OVERGROWN, 50, 0.5),
		_tower("Rivet Gun", Faction.IRON_DOMINION, "DPS", "kinetic", 12, 3, TerrainState.INDUSTRIAL, 30, 1.2),
		_tower("Mortar Foundry", Faction.IRON_DOMINION, "AoE", "explosive", 18, 4, TerrainState.CRATERED, 45, 0.5),
		_tower("Oil Extractor", Faction.IRON_DOMINION, "Economy", "oil", 0, 1, TerrainState.FLOODED, 40, 0.0),
		_tower("Arc Furnace", Faction.IRON_DOMINION, "Aura", "fire", 14, 2, TerrainState.SCORCHED, 35, 0.8),
		_tower("Rail Cannon", Faction.IRON_DOMINION, "Finisher", "kinetic", 25, 5, TerrainState.INDUSTRIAL, 60, 0.3),
		_tower("Hex Obelisk", Faction.VOID_BLOOM, "Support", "corruption", 9, 3, TerrainState.CORRUPTED, 30, 0.6),
		_tower("Rift Lantern", Faction.VOID_BLOOM, "Chain", "lightning", 13, 3, TerrainState.UNSTABLE, 35, 0.9),
		_tower("Plague Vessel", Faction.VOID_BLOOM, "AoE", "poison", 12, 2, TerrainState.CORRUPTED, 40, 0.6),
		_tower("Entropy Coil", Faction.VOID_BLOOM, "Volatile", "arcane", 16, 3, TerrainState.UNSTABLE, 45, 0.7),
		_tower("Abyss Seed", Faction.VOID_BLOOM, "Late", "corruption", 30, 2, TerrainState.CORRUPTED, 55, 0.4),
	]


func _tower(p_name: String, faction: Faction, role: String, element: String,
		damage: float, attack_range: int, terrain_aura: TerrainState,
		cost: int, attack_speed: float) -> Dictionary:
	return {
		"name": p_name, "faction": faction, "role": role, "element": element,
		"damage": damage, "range": attack_range, "terrain_aura": terrain_aura,
		"cost": cost, "attack_speed": attack_speed,
	}


func _build_node_plan() -> void:
	var biomes := [Biome.VERDANT_BASIN, Biome.IRON_SCAR, Biome.HOLLOW_VEIL]
	node_plan.clear()
	for wave in range(1, 13):
		var biome: Biome = biomes[(wave - 1) / 4] as Biome
		var node_type: NodeType
		var threat_mult := 1.0
		if wave in [6, 12]:
			node_type = NodeType.BOSS
			threat_mult = 1.6
		elif wave in [4, 8, 11]:
			node_type = NodeType.ELITE
			threat_mult = 1.25
		elif wave in [3, 7, 10]:
			node_type = NodeType.ANOMALY
			threat_mult = 1.0
		else:
			node_type = NodeType.BATTLE
			threat_mult = 1.0
		node_plan.append({
			"wave": wave,
			"biome": biome,
			"node_type": node_type,
			"threat_multiplier": threat_mult,
		})


func _apply_commander_start_bonus() -> void:
	match commander:
		Commander.WARDEN:
			integrity = 1.1
		Commander.FOREMAN:
			scrap += 40
			biome_pressure += 0.03
		Commander.SEER:
			essence += 10
			biome_pressure += 0.02


# ---- Helpers ----

func get_current_biome() -> Biome:
	if current_wave < total_waves:
		return node_plan[current_wave]["biome"] as Biome
	return Biome.HOLLOW_VEIL


func get_current_node() -> Dictionary:
	if current_wave < total_waves:
		return node_plan[current_wave]
	return {}


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return GRID_OFFSET + Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
		grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0
	)


func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local := world_pos - GRID_OFFSET
	return Vector2i(int(local.x) / CELL_SIZE, int(local.y) / CELL_SIZE)


func is_valid_grid_pos(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < GRID_WIDTH and grid_pos.y >= 0 and grid_pos.y < GRID_HEIGHT


func is_path_tile(grid_pos: Vector2i) -> bool:
	return grid_pos in enemy_path


func get_terrain(pos: Vector2i) -> TerrainState:
	return tile_states.get(pos, TerrainState.NATURAL) as TerrainState


func set_terrain(pos: Vector2i, state: TerrainState) -> void:
	tile_states[pos] = state


func get_movement_modifier(state: TerrainState) -> float:
	match state:
		TerrainState.OVERGROWN, TerrainState.CRATERED:
			return 1.35
		TerrainState.FLOODED, TerrainState.CORRUPTED, TerrainState.INDUSTRIAL:
			return 1.15
		TerrainState.FROZEN:
			return 0.90
		TerrainState.ELECTRIFIED:
			return 1.20
		_:
			return 1.0


# ---- Resource Management ----

func add_scrap(amount: int) -> void:
	scrap += amount
	resources_changed.emit()


func spend_scrap(amount: int) -> bool:
	if scrap >= amount:
		scrap -= amount
		resources_changed.emit()
		return true
	return false


func reduce_integrity(amount: float) -> void:
	integrity = max(0.0, integrity - amount)
	integrity_changed.emit(integrity)
	if integrity <= 0:
		game_over.emit(false)


func reset_game() -> void:
	current_wave = 0
	integrity = 1.0
	scrap = 120
	essence = 0
	core_charge = 2
	biome_pressure = 0.0
	wave_in_progress = false
	enemy_traits.clear()
	story_moments.clear()
	selected_tower_index = -1
	wave_damage_dealt = 0.0
	_init_tile_states()
	_build_node_plan()
	_apply_commander_start_bonus()
	resources_changed.emit()
	integrity_changed.emit(integrity)
