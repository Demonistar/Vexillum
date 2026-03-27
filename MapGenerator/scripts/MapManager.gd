extends Node

var sections: Array = []
var expansion_history: Array = []

func initialize_default_map() -> void:
	sections.clear()
	expansion_history.clear()

	var s_cave = SectionGrid.new()
	s_cave.initialize(GameConstants.SectionType.CAVE,
		GameConstants.Direction.NONE,
		GameConstants.Direction.EAST, 0)
	PathGenerator.generate(s_cave)
	s_cave.world_offset = Vector2(0.0, 0.0)
	sections.append(s_cave)

	var s_hub = SectionGrid.new()
	s_hub.initialize(GameConstants.SectionType.HUB,
		GameConstants.Direction.WEST,
		GameConstants.Direction.EAST, 1)
	PathGenerator.generate(s_hub)
	s_hub.world_offset = Vector2(
		float(GameConstants.SECTION_SIZE * GameConstants.TILE_SIZE), 0.0)
	sections.append(s_hub)

	var s_vex = SectionGrid.new()
	s_vex.initialize(GameConstants.SectionType.VEX_BASE,
		GameConstants.Direction.WEST,
		GameConstants.Direction.NONE, 2)
	PathGenerator.generate(s_vex)
	s_vex.world_offset = Vector2(
		float(GameConstants.SECTION_SIZE * GameConstants.TILE_SIZE * 2), 0.0)
	sections.append(s_vex)

func add_section(direction: int) -> bool:
	if direction == GameConstants.Direction.WEST:
		return false  # West is never valid
	if direction == GameConstants.Direction.NONE:
		return false
	if direction in expansion_history:
		return false  # Direction already used

	var new_seed = randi()
	var new_section = SectionGrid.new()
	new_section.initialize(GameConstants.SectionType.EXPANSION,
		_opposite(direction), direction, new_seed)
	PathGenerator.generate(new_section)

	# Place new section where VEX currently sits; shift VEX outward
	var vex = sections[sections.size() - 1]
	var shift = _direction_to_offset(direction)
	new_section.world_offset = vex.world_offset
	vex.world_offset += shift
	sections.insert(sections.size() - 1, new_section)
	expansion_history.append(direction)
	return true

func remove_last_section() -> bool:
	if expansion_history.size() == 0:
		return false
	var last_dir = expansion_history[expansion_history.size() - 1]
	var shift = _direction_to_offset(last_dir)
	var vex = sections[sections.size() - 1]
	vex.world_offset -= shift
	sections.remove_at(sections.size() - 2)  # remove expansion (not vex)
	expansion_history.remove_at(expansion_history.size() - 1)
	return true

func get_valid_directions() -> Array:
	var valid: Array = []
	for dir in [GameConstants.Direction.NORTH,
				GameConstants.Direction.SOUTH,
				GameConstants.Direction.EAST]:
		if not (dir in expansion_history):
			valid.append(dir)
	return valid

func get_minion_waypoints() -> Array:
	var waypoints: Array = []
	for section in sections:
		for pt in section.path_tiles:
			waypoints.append(section.world_offset +
				Vector2(float(pt.x) * GameConstants.TILE_SIZE,
						float(pt.y) * GameConstants.TILE_SIZE))
	return waypoints

func regenerate_section(index: int, new_seed: int) -> void:
	if index < 0 or index >= sections.size():
		return
	var s = sections[index]
	s.initialize(s.section_type, s.entry_dir, s.exit_dir, new_seed)
	PathGenerator.generate(s)

func _opposite(dir: int) -> int:
	match dir:
		GameConstants.Direction.NORTH: return GameConstants.Direction.SOUTH
		GameConstants.Direction.SOUTH: return GameConstants.Direction.NORTH
		GameConstants.Direction.EAST:  return GameConstants.Direction.WEST
		GameConstants.Direction.WEST:  return GameConstants.Direction.EAST
	return GameConstants.Direction.NONE

func _direction_to_offset(dir: int) -> Vector2:
	var step = float(GameConstants.SECTION_SIZE * GameConstants.TILE_SIZE)
	match dir:
		GameConstants.Direction.NORTH: return Vector2(0.0,  -step)
		GameConstants.Direction.SOUTH: return Vector2(0.0,   step)
		GameConstants.Direction.EAST:  return Vector2( step, 0.0)
		GameConstants.Direction.WEST:  return Vector2(-step, 0.0)
	return Vector2.ZERO
