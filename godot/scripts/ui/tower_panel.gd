extends Control

signal tower_selected(index: int)

var button_map: Dictionary = {}  # Button -> tower_def index
var selected_button: Button = null


func _ready() -> void:
	# Position on right side (grid ends at 80 + 8*128 = 1104)
	position = Vector2(1300, 0)
	size = Vector2(620, 1080)

	_build_panel()
	GameManager.resources_changed.connect(_update_affordability)
	_update_affordability()


func _build_panel() -> void:
	# Background
	var panel := PanelContainer.new()
	panel.size = Vector2(620, 1080)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.14)
	style.border_color = Color(0.25, 0.25, 0.3)
	style.border_width_left = 2
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "TOWERS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	vbox.add_child(title)

	var commander_label := Label.new()
	commander_label.text = GameManager.commander_names[GameManager.commander]
	commander_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	commander_label.add_theme_font_size_override("font_size", 19)
	commander_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(commander_label)

	vbox.add_child(HSeparator.new())

	# Group by faction
	var factions := [
		GameManager.Faction.WILD_GROWTH,
		GameManager.Faction.IRON_DOMINION,
		GameManager.Faction.VOID_BLOOM,
	]

	for faction in factions:
		var faction_label := Label.new()
		faction_label.text = GameManager.faction_names[faction]
		faction_label.add_theme_font_size_override("font_size", 22)
		faction_label.add_theme_color_override("font_color", GameManager.faction_colors[faction])
		vbox.add_child(faction_label)

		for i in range(GameManager.tower_defs.size()):
			var td: Dictionary = GameManager.tower_defs[i]
			if td["faction"] != faction:
				continue

			var btn := Button.new()
			var damage_text := ""
			if td["damage"] > 0:
				damage_text = " %d dmg" % int(td["damage"])
			btn.text = "%s  [%s]%s  %d$" % [td["name"], td["role"], damage_text, td["cost"]]
			btn.custom_minimum_size = Vector2(560, 48)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_font_size_override("font_size", 19)

			var idx := i
			btn.pressed.connect(func(): _on_tower_pressed(idx, btn))
			btn.mouse_entered.connect(func(): _on_tower_hover(idx))

			vbox.add_child(btn)
			button_map[btn] = i

		vbox.add_child(HSeparator.new())

	# Instructions at bottom
	var hint := Label.new()
	hint.text = "Click tower then click grid.\nRight-click to deselect."
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	vbox.add_child(hint)


func _on_tower_pressed(index: int, btn: Button) -> void:
	GameManager.selected_tower_index = index

	# Visual selection feedback
	if selected_button:
		selected_button.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	selected_button = btn
	btn.add_theme_color_override("font_color", Color.GREEN)

	tower_selected.emit(index)


func _on_tower_hover(index: int) -> void:
	var td: Dictionary = GameManager.tower_defs[index]
	var hud_node := get_node_or_null("/root/Main/UI/HUD")
	if not hud_node or not hud_node.has_method("show_info"):
		return

	var info := "%s | %s | Element: %s | Range: %d" % [
		td["name"], td["role"], td["element"], td["range"]
	]

	match td["role"]:
		"Economy":
			info += " | +14 scrap/wave, +0.02 pressure/wave"
		"Support":
			if td["name"] == "Bloom Shrine":
				info += " | +20% damage to nearby towers"
			elif td["damage"] > 0:
				info += " | DPS: %.1f" % (td["damage"] * td["attack_speed"])
		"AoE":
			info += " | DPS: %.1f | Splash damage in area" % (td["damage"] * td["attack_speed"])
		"Chain":
			info += " | DPS: %.1f | Bounces to nearby enemies" % (td["damage"] * td["attack_speed"])
		"Finisher":
			info += " | DPS: %.1f | Up to 2x on low-HP enemies" % (td["damage"] * td["attack_speed"])
		"Aura":
			info += " | Pulses damage to all enemies in range"
		"Volatile":
			info += " | DPS: %.1f | 1.5x damage, can misfire" % (td["damage"] * td["attack_speed"])
		"Late":
			info += " | DPS: %.1f | Ramps to 2x during wave" % (td["damage"] * td["attack_speed"])
		"Anchor":
			info += " | DPS: %.1f | +15%% bonus, cannot be sold" % (td["damage"] * td["attack_speed"])
		"Control":
			info += " | DPS: %.1f | Slows enemies" % (td["damage"] * td["attack_speed"])
		_:
			if td["damage"] > 0:
				info += " | DPS: %.1f" % (td["damage"] * td["attack_speed"])

	hud_node.show_info(info)


func _update_affordability() -> void:
	for btn in button_map:
		if not is_instance_valid(btn):
			continue
		var idx: int = button_map[btn]
		var td: Dictionary = GameManager.tower_defs[idx]
		btn.disabled = GameManager.scrap < td["cost"]


func deselect() -> void:
	if selected_button:
		selected_button.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
		selected_button = null
	GameManager.selected_tower_index = -1
