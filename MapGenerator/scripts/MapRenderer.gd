extends Node2D

var show_overlay: bool = false
var show_waypoints: bool = false
var show_connections: bool = false
var _manager = null  # MapManager autoload reference

func render(manager) -> void:
	_manager = manager
	queue_redraw()

func toggle_overlay(show: bool) -> void:
	show_overlay = show
	queue_redraw()

func toggle_waypoints(show: bool) -> void:
	show_waypoints = show
	queue_redraw()

func toggle_connections(show: bool) -> void:
	show_connections = show
	queue_redraw()

func _draw() -> void:
	if _manager == null:
		return
	for section in _manager.sections:
		_draw_section(section)
	if show_waypoints:
		_draw_waypoints()
	if show_connections:
		_draw_connections()

func _draw_section(section: SectionGrid) -> void:
	var ts = float(GameConstants.TILE_SIZE)
	for x in range(GameConstants.SECTION_SIZE):
		for y in range(GameConstants.SECTION_SIZE):
			var tile = section.get_tile(x, y)
			var color: Color
			match tile:
				GameConstants.TILE_PATH:    color = GameConstants.COLOR_PATH
				GameConstants.TILE_TOWER:   color = GameConstants.COLOR_TOWER
				GameConstants.TILE_BLOCKED: color = GameConstants.COLOR_BLOCKED
				_:                          color = GameConstants.COLOR_EMPTY
			var rect = Rect2(
				section.world_offset + Vector2(float(x) * ts, float(y) * ts),
				Vector2(ts, ts))
			draw_rect(rect, color)
			draw_rect(rect, Color(0.0, 0.0, 0.0, 0.2), false, 0.5)
			# Overlay
			if show_overlay and tile == GameConstants.TILE_TOWER:
				draw_rect(rect, GameConstants.COLOR_VALID)
			elif show_overlay and tile == GameConstants.TILE_EMPTY:
				draw_rect(rect, GameConstants.COLOR_INVALID)

func _draw_waypoints() -> void:
	var waypoints = _manager.get_minion_waypoints()
	var half_ts = float(GameConstants.TILE_SIZE) * 0.5
	for wp in waypoints:
		draw_circle(wp + Vector2(half_ts, half_ts), 4.0, GameConstants.COLOR_WAYPOINT)

func _draw_connections() -> void:
	for section in _manager.sections:
		for dir_name in ["north", "south", "east", "west"]:
			var mid: Vector2i = GameConstants.EDGE_MIDPOINTS.get(dir_name, Vector2i())
			var world_pt = section.world_offset + Vector2(
				float(mid.x) * float(GameConstants.TILE_SIZE),
				float(mid.y) * float(GameConstants.TILE_SIZE))
			draw_circle(world_pt, 8.0, GameConstants.COLOR_CONNECTION)
