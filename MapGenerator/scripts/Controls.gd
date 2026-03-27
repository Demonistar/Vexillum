extends Control

@onready var seed_input:   SpinBox = $UILayer/VBox/SeedRow/SeedInput
@onready var status_label: Label   = $UILayer/VBox/StatusLabel
@onready var map_renderer: Node2D  = $MapView/MapRenderer

func _ready() -> void:
	MapManager.initialize_default_map()
	_refresh()

func _on_generate_pressed() -> void:
	var seed_val = int(seed_input.value)
	MapManager.initialize_default_map()
	for i in range(MapManager.sections.size()):
		MapManager.regenerate_section(i, seed_val + i)
	_refresh()

func _on_add_north_pressed() -> void:
	var ok = MapManager.add_section(GameConstants.Direction.NORTH)
	if ok:
		status_label.text = "Added North section."
	else:
		status_label.text = "INVALID: North direction already used or blocked."
	_refresh()

func _on_add_south_pressed() -> void:
	var ok = MapManager.add_section(GameConstants.Direction.SOUTH)
	if ok:
		status_label.text = "Added South section."
	else:
		status_label.text = "INVALID: South direction already used or blocked."
	_refresh()

func _on_add_east_pressed() -> void:
	var ok = MapManager.add_section(GameConstants.Direction.EAST)
	if ok:
		status_label.text = "Added East section."
	else:
		status_label.text = "INVALID: East direction already used or blocked."
	_refresh()

func _on_remove_last_pressed() -> void:
	var ok = MapManager.remove_last_section()
	if ok:
		status_label.text = "Removed last expansion."
	else:
		status_label.text = "INVALID: No expansion sections to remove."
	_refresh()

func _on_regen_cave_pressed() -> void:
	MapManager.regenerate_section(0, randi())
	_refresh()

func _on_regen_vex_pressed() -> void:
	var last = MapManager.sections.size() - 1
	MapManager.regenerate_section(last, randi())
	_refresh()

func _on_overlay_toggled(pressed: bool) -> void:
	map_renderer.toggle_overlay(pressed)

func _on_waypoints_toggled(pressed: bool) -> void:
	map_renderer.toggle_waypoints(pressed)

func _on_connections_toggled(pressed: bool) -> void:
	map_renderer.toggle_connections(pressed)

func _refresh() -> void:
	map_renderer.render(MapManager)
	var total_path  = 0
	var total_tower = 0
	for s in MapManager.sections:
		total_path  += s.path_tiles.size()
		total_tower += s.tower_zones.size()
	status_label.text = (
		"Sections: %d | Path tiles: %d | Tower zones: %d" %
		[MapManager.sections.size(), total_path, total_tower]
	)
