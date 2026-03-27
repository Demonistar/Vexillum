extends Node

func generate(section: SectionGrid) -> bool:
	var entry    = section.get_entry_point()
	var exit_pt  = section.get_exit_point()

	# Try up to 3 seeds
	for attempt in range(3):
		var seed_attempt = section.seed_val + attempt
		var path = _generate_attempt(section, entry, exit_pt, seed_attempt)
		if path.size() > 0 and _validate_path(path, entry, exit_pt):
			_apply_path(section, path)
			section.flag_tower_zones()
			return true

	# Fallback: straight path — always valid
	_carve_straight(section, entry, exit_pt)
	section.flag_tower_zones()
	return true

func _generate_attempt(section: SectionGrid, entry: Vector2i,
		exit_pt: Vector2i, seed: int) -> Array:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed
	var style = seed % 4
	match style:
		0: return _build_straight(entry, exit_pt)
		1: return _build_arc(entry, exit_pt, -1, rng)
		2: return _build_arc(entry, exit_pt,  1, rng)
		3: return _build_zigzag(entry, exit_pt, rng)
	return _build_straight(entry, exit_pt)

func _build_straight(entry: Vector2i, exit_pt: Vector2i) -> Array:
	var path: Array = []
	var cur = Vector2i(entry.x, entry.y)
	while cur != exit_pt:
		path.append(cur)
		var dx = sign(exit_pt.x - cur.x)
		var dy = sign(exit_pt.y - cur.y)
		if dx != 0:
			cur.x += dx
		elif dy != 0:
			cur.y += dy
	path.append(exit_pt)
	return path

func _build_arc(entry: Vector2i, exit_pt: Vector2i,
		bias: int, rng: RandomNumberGenerator) -> Array:
	var path: Array = []
	var cur = Vector2i(entry.x, entry.y)
	var mid_offset = rng.randi_range(4, 10) * bias
	var perp_steps = abs(mid_offset)
	var perp_dir   = sign(mid_offset)
	# Determine primary travel direction
	var travel_h = abs(exit_pt.x - entry.x) > abs(exit_pt.y - entry.y)
	# Move perpendicular first
	for _i in range(perp_steps):
		path.append(cur)
		if travel_h:
			cur.y += perp_dir
		else:
			cur.x += perp_dir
	# Then move toward exit
	while cur != exit_pt:
		path.append(cur)
		var dx = sign(exit_pt.x - cur.x)
		var dy = sign(exit_pt.y - cur.y)
		if dx != 0:
			cur.x += dx
		elif dy != 0:
			cur.y += dy
	path.append(exit_pt)
	return path

func _build_zigzag(entry: Vector2i, exit_pt: Vector2i,
		rng: RandomNumberGenerator) -> Array:
	var path: Array = []
	var cur = Vector2i(entry.x, entry.y)
	var mid_x = (entry.x + exit_pt.x) / 2
	var mid_y = (entry.y + exit_pt.y) / 2
	var jog_mag = rng.randi_range(3, 6)
	var jog_dir = 1 if rng.randi() % 2 == 0 else -1
	var jog = jog_mag * jog_dir
	# Leg 1: go to midpoint
	while cur.x != mid_x or cur.y != mid_y:
		path.append(cur)
		var dx = sign(mid_x - cur.x)
		var dy = sign(mid_y - cur.y)
		if dx != 0:
			cur.x += dx
		elif dy != 0:
			cur.y += dy
	# Jog perpendicular at midpoint
	var jog_steps = abs(jog)
	var jog_step_dir = sign(jog)
	var travel_h = abs(exit_pt.x - entry.x) > abs(exit_pt.y - entry.y)
	for _i in range(jog_steps):
		path.append(cur)
		if travel_h:
			cur.y += jog_step_dir
		else:
			cur.x += jog_step_dir
	# Leg 2: go to exit
	while cur != exit_pt:
		path.append(cur)
		var dx = sign(exit_pt.x - cur.x)
		var dy = sign(exit_pt.y - cur.y)
		if dx != 0:
			cur.x += dx
		elif dy != 0:
			cur.y += dy
	path.append(exit_pt)
	return path

func _validate_path(path: Array, _entry: Vector2i, exit_pt: Vector2i) -> bool:
	if path.size() < 2:
		return false
	# Rule 1: No duplicate tiles
	var seen: Dictionary = {}
	for t in path:
		var key = str(t.x) + "," + str(t.y)
		if seen.has(key):
			return false
		seen[key] = true
	# Rule 2: No non-sequential tiles within Manhattan distance 2
	for i in range(path.size()):
		for j in range(i + 3, path.size()):
			var dx = abs(path[i].x - path[j].x)
			var dy = abs(path[i].y - path[j].y)
			if dx + dy <= 2:
				return false
	# Rule 3: Last tile within 1 of exit edge midpoint
	var last = path[path.size() - 1]
	if last.distance_to(exit_pt) > 1.0:
		return false
	return true

func _apply_path(section: SectionGrid, path: Array) -> void:
	section.path_tiles.clear()
	for t in path:
		if t.x >= 0 and t.x < GameConstants.SECTION_SIZE:
			if t.y >= 0 and t.y < GameConstants.SECTION_SIZE:
				section.set_tile(t.x, t.y, GameConstants.TILE_PATH)
				section.path_tiles.append(t)

func _carve_straight(section: SectionGrid,
		entry: Vector2i, exit_pt: Vector2i) -> void:
	var path = _build_straight(entry, exit_pt)
	_apply_path(section, path)
