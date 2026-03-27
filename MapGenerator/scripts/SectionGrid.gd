class_name SectionGrid

var tiles: Array = []
var section_type: int  # GameConstants.SectionType
var entry_dir: int     # GameConstants.Direction
var exit_dir: int      # GameConstants.Direction
var seed_val: int
var world_offset: Vector2  # pixel offset on screen
var path_tiles: Array = []   # Array of Vector2i
var tower_zones: Array = []  # Array of Vector2i (valid placements)

func initialize(_type: int, _entry: int, _exit: int, _seed: int) -> void:
	section_type = _type
	entry_dir    = _entry
	exit_dir     = _exit
	seed_val     = _seed
	path_tiles.clear()
	tower_zones.clear()
	tiles = []
	for _x in range(GameConstants.SECTION_SIZE):
		var col = []
		for _y in range(GameConstants.SECTION_SIZE):
			col.append(GameConstants.TILE_EMPTY)
		tiles.append(col)

func get_tile(x: int, y: int) -> int:
	if x < 0 or x >= GameConstants.SECTION_SIZE: return GameConstants.TILE_BLOCKED
	if y < 0 or y >= GameConstants.SECTION_SIZE: return GameConstants.TILE_BLOCKED
	return tiles[x][y]

func set_tile(x: int, y: int, tile_type: int) -> void:
	if x < 0 or x >= GameConstants.SECTION_SIZE: return
	if y < 0 or y >= GameConstants.SECTION_SIZE: return
	tiles[x][y] = tile_type

func get_entry_point() -> Vector2i:
	return GameConstants.EDGE_MIDPOINTS.get(
		_dir_to_string(entry_dir), Vector2i(0, 15))

func get_exit_point() -> Vector2i:
	return GameConstants.EDGE_MIDPOINTS.get(
		_dir_to_string(exit_dir), Vector2i(30, 15))

func _dir_to_string(dir: int) -> String:
	match dir:
		GameConstants.Direction.NORTH: return "north"
		GameConstants.Direction.SOUTH: return "south"
		GameConstants.Direction.EAST:  return "east"
		GameConstants.Direction.WEST:  return "west"
	return "center"  # Direction.NONE → path terminates at section center

func flag_tower_zones() -> void:
	tower_zones.clear()
	for x in range(GameConstants.SECTION_SIZE):
		for y in range(GameConstants.SECTION_SIZE):
			if get_tile(x, y) == GameConstants.TILE_EMPTY:
				if _is_valid_tower_center(x, y):
					set_tile(x, y, GameConstants.TILE_TOWER)
					tower_zones.append(Vector2i(x, y))

func _is_valid_tower_center(cx: int, cy: int) -> bool:
	# 3x3 footprint must not contain any path tile
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if get_tile(cx + dx, cy + dy) == GameConstants.TILE_PATH:
				return false
	# Must be within range 8 of at least one path tile
	for p in path_tiles:
		if Vector2i(cx, cy).distance_to(p) <= 8.0:
			return true
	return false
