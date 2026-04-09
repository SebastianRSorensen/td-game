extends Control

signal start_wave_pressed
signal ability_pressed
signal upgrade_pressed
signal sell_pressed

var wave_label: Label
var biome_label: Label
var node_type_label: Label
var integrity_bar: ProgressBar
var integrity_label: Label
var scrap_label: Label
var essence_label: Label
var core_label: Label
var start_button: Button
var ability_button: Button
var info_label: Label
var traits_label: Label
var enemies_alive_label: Label
var wave_preview_label: Label
var restart_button: Button

# Speed control
var speed_buttons: Array[Button] = []
var current_speed := 1

# Tower info panel
var tower_info_panel: PanelContainer
var tower_info_name: Label
var tower_info_stats: Label
var tower_info_level: Label
var upgrade_button: Button
var sell_button: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top_bar()
	_build_bottom_bar()
	_build_tower_info_panel()

	GameManager.resources_changed.connect(_update_display)
	GameManager.integrity_changed.connect(_on_integrity_changed)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_ended.connect(_on_wave_ended)
	GameManager.game_over.connect(_on_game_over)
	GameManager.adaptation_forecasted.connect(_on_adaptation)

	_update_display()
	_update_wave_preview()


func _process(_delta: float) -> void:
	if GameManager.wave_in_progress:
		var wm := get_node_or_null("/root/Main/WaveManager")
		if wm:
			enemies_alive_label.text = "Enemies: %d" % wm.enemies_alive
			enemies_alive_label.visible = true
	else:
		enemies_alive_label.visible = false


func _build_top_bar() -> void:
	var bar := PanelContainer.new()
	bar.position = Vector2.ZERO
	bar.size = Vector2(1300, 90)
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.08, 0.08, 0.12, 0.92)
	bar.add_theme_stylebox_override("panel", bar_style)
	add_child(bar)

	var hbox := HBoxContainer.new()
	hbox.position = Vector2(20, 12)
	hbox.add_theme_constant_override("separation", 28)
	bar.add_child(hbox)

	wave_label = _make_label("Wave 0/12", 28)
	hbox.add_child(wave_label)

	enemies_alive_label = _make_label("", 22)
	enemies_alive_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	enemies_alive_label.visible = false
	hbox.add_child(enemies_alive_label)

	biome_label = _make_label("Verdant Basin", 24)
	biome_label.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))
	hbox.add_child(biome_label)

	node_type_label = _make_label("[Battle]", 24)
	node_type_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
	hbox.add_child(node_type_label)

	var int_box := HBoxContainer.new()
	int_box.add_theme_constant_override("separation", 8)
	var int_text := _make_label("HP:", 24)
	int_box.add_child(int_text)
	integrity_bar = ProgressBar.new()
	integrity_bar.custom_minimum_size = Vector2(200, 28)
	integrity_bar.value = 100
	integrity_bar.show_percentage = false
	int_box.add_child(integrity_bar)
	integrity_label = _make_label("110%", 24)
	int_box.add_child(integrity_label)
	hbox.add_child(int_box)

	scrap_label = _make_label("Scrap: 120", 24)
	scrap_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	hbox.add_child(scrap_label)

	essence_label = _make_label("Essence: 0", 24)
	essence_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
	hbox.add_child(essence_label)

	core_label = _make_label("Core: 2", 24)
	core_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	hbox.add_child(core_label)


func _build_bottom_bar() -> void:
	start_button = Button.new()
	start_button.text = "  START WAVE  "
	start_button.position = Vector2(300, 980)
	start_button.custom_minimum_size = Vector2(220, 55)
	start_button.add_theme_font_size_override("font_size", 22)
	start_button.pressed.connect(func(): start_wave_pressed.emit())
	add_child(start_button)

	ability_button = Button.new()
	ability_button.text = "  CORE ABILITY  "
	ability_button.position = Vector2(540, 980)
	ability_button.custom_minimum_size = Vector2(200, 55)
	ability_button.add_theme_font_size_override("font_size", 22)
	ability_button.pressed.connect(func(): ability_pressed.emit())
	add_child(ability_button)

	# Speed controls
	var speed_x := 760
	for i in [1, 2, 3]:
		var btn := Button.new()
		btn.text = " %dx " % i
		btn.position = Vector2(speed_x, 988)
		btn.custom_minimum_size = Vector2(55, 40)
		btn.add_theme_font_size_override("font_size", 18)
		var spd: int = i
		btn.pressed.connect(func(): _set_speed(spd))
		add_child(btn)
		speed_buttons.append(btn)
		speed_x += 62
	_update_speed_buttons()

	# Restart button (hidden until game over)
	restart_button = Button.new()
	restart_button.text = "  RESTART  "
	restart_button.position = Vector2(500, 980)
	restart_button.custom_minimum_size = Vector2(200, 55)
	restart_button.add_theme_font_size_override("font_size", 22)
	restart_button.visible = false
	restart_button.pressed.connect(func():
		Engine.time_scale = 1.0
		GameManager.reset_game()
		get_tree().reload_current_scene()
	)
	add_child(restart_button)

	# Wave preview
	wave_preview_label = Label.new()
	wave_preview_label.position = Vector2(80, 855)
	wave_preview_label.text = ""
	wave_preview_label.add_theme_font_size_override("font_size", 17)
	wave_preview_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	add_child(wave_preview_label)

	info_label = Label.new()
	info_label.position = Vector2(80, 890)
	info_label.text = "Select a tower from the panel, then click the grid to place it.  [Space = Start Wave]"
	info_label.add_theme_font_size_override("font_size", 20)
	info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(info_label)

	traits_label = Label.new()
	traits_label.position = Vector2(80, 925)
	traits_label.text = ""
	traits_label.add_theme_font_size_override("font_size", 18)
	traits_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
	add_child(traits_label)


func _build_tower_info_panel() -> void:
	tower_info_panel = PanelContainer.new()
	tower_info_panel.position = Vector2(80, 760)
	tower_info_panel.size = Vector2(500, 90)
	tower_info_panel.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.16, 0.95)
	style.border_color = Color(0.4, 0.4, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	tower_info_panel.add_theme_stylebox_override("panel", style)
	add_child(tower_info_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	tower_info_panel.add_child(vbox)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 16)
	vbox.add_child(top_row)

	tower_info_name = Label.new()
	tower_info_name.add_theme_font_size_override("font_size", 22)
	top_row.add_child(tower_info_name)

	tower_info_level = Label.new()
	tower_info_level.add_theme_font_size_override("font_size", 20)
	tower_info_level.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	top_row.add_child(tower_info_level)

	tower_info_stats = Label.new()
	tower_info_stats.add_theme_font_size_override("font_size", 18)
	tower_info_stats.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	vbox.add_child(tower_info_stats)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	upgrade_button = Button.new()
	upgrade_button.text = "  UPGRADE  "
	upgrade_button.custom_minimum_size = Vector2(180, 40)
	upgrade_button.add_theme_font_size_override("font_size", 18)
	upgrade_button.pressed.connect(func(): upgrade_pressed.emit())
	btn_row.add_child(upgrade_button)

	sell_button = Button.new()
	sell_button.text = "  SELL  "
	sell_button.custom_minimum_size = Vector2(140, 40)
	sell_button.add_theme_font_size_override("font_size", 18)
	sell_button.pressed.connect(func(): sell_pressed.emit())
	btn_row.add_child(sell_button)


func _set_speed(spd: int) -> void:
	current_speed = spd
	Engine.time_scale = float(spd)
	_update_speed_buttons()


func _update_speed_buttons() -> void:
	for i in range(speed_buttons.size()):
		var btn := speed_buttons[i]
		if i + 1 == current_speed:
			btn.add_theme_color_override("font_color", Color.GREEN)
		else:
			btn.remove_theme_color_override("font_color")


func _update_wave_preview() -> void:
	var next_wave := GameManager.current_wave + 1
	if next_wave > GameManager.total_waves:
		wave_preview_label.text = ""
		return
	var wm := get_node_or_null("/root/Main/WaveManager")
	if wm and wm.has_method("get_wave_preview"):
		wave_preview_label.text = "Next wave: %s" % wm.get_wave_preview(next_wave)
	else:
		wave_preview_label.text = ""


func show_tower_info(tower: TowerEntity) -> void:
	tower_info_panel.visible = true
	var td: Dictionary = tower.tower_def
	var color: Color = GameManager.faction_colors[td["faction"]]
	tower_info_name.text = td["name"]
	tower_info_name.add_theme_color_override("font_color", color)
	tower_info_level.text = "Lv.%d / %d" % [tower.level, TowerEntity.MAX_LEVEL]

	var dmg := tower.get_damage()
	var spd := tower.get_attack_speed()
	var rng := tower.get_range()
	var dps := dmg * spd if spd > 0 else 0.0
	tower_info_stats.text = "Dmg: %.0f  Spd: %.1f  Range: %d  DPS: %.1f  |  %s  %s" % [
		dmg, spd, rng, dps, td["role"], td["element"]
	]

	if tower.level >= TowerEntity.MAX_LEVEL:
		upgrade_button.text = "  MAX LEVEL  "
		upgrade_button.disabled = true
	else:
		var cost := tower.get_upgrade_cost()
		upgrade_button.text = "  UPGRADE (%d$)  " % cost
		upgrade_button.disabled = GameManager.scrap < cost

	# Anchor can't be sold
	if td["role"] == "Anchor":
		sell_button.text = "  ANCHORED  "
		sell_button.disabled = true
	else:
		sell_button.text = "  SELL (%d$)  " % tower.get_sell_value()
		sell_button.disabled = false


func hide_tower_info() -> void:
	tower_info_panel.visible = false


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _update_display() -> void:
	scrap_label.text = "Scrap: %d" % GameManager.scrap
	essence_label.text = "Essence: %d" % GameManager.essence
	core_label.text = "Core: %d" % GameManager.core_charge
	ability_button.disabled = GameManager.core_charge <= 0

	var biome := GameManager.get_current_biome()
	biome_label.text = GameManager.biome_names[biome]

	var node := GameManager.get_current_node()
	if not node.is_empty():
		var nt: GameManager.NodeType = node["node_type"] as GameManager.NodeType
		node_type_label.text = "[%s]" % GameManager.node_type_names[nt]
	wave_label.text = "Wave %d/%d" % [GameManager.current_wave, GameManager.total_waves]

	integrity_label.text = "%d%%" % int(GameManager.integrity * 100)
	integrity_bar.value = GameManager.integrity * 100

	if GameManager.enemy_traits.size() > 0:
		traits_label.text = "Enemy traits: %s" % ", ".join(GameManager.enemy_traits)
	else:
		traits_label.text = ""


func _on_integrity_changed(_value: float) -> void:
	_update_display()


func _on_wave_started(_wave: int) -> void:
	start_button.disabled = true
	_update_display()


func _on_wave_ended(_wave: int) -> void:
	start_button.disabled = false
	if GameManager.current_wave >= GameManager.total_waves:
		start_button.disabled = true
		start_button.text = "  CAMPAIGN COMPLETE  "
	_update_display()
	_update_wave_preview()


func _on_game_over(won: bool) -> void:
	start_button.visible = false
	ability_button.visible = false
	for btn in speed_buttons:
		btn.visible = false
	restart_button.visible = true

	if won:
		info_label.text = "VICTORY! Campaign complete. All 12 waves cleared!"
		info_label.add_theme_color_override("font_color", Color.GOLD)
	else:
		info_label.text = "DEFEAT! Your base has fallen. Try a different strategy."
		info_label.add_theme_color_override("font_color", Color.RED)


func _on_adaptation(forecast: Dictionary) -> void:
	info_label.text = "ADAPTATION: %s counter incoming (partial w%d, full w%d)" % [
		forecast["family"], forecast["eta_partial"], forecast["eta_full"]
	]
	info_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
	_update_display()


func show_info(text: String, color := Color(0.7, 0.7, 0.7)) -> void:
	info_label.text = text
	info_label.add_theme_color_override("font_color", color)
