# VEXILLUM Build Bible — Claude Code Reference
# Module 1A: Map Generator
# Version 1.3 | Read this entire file before writing any code.

======================================================================
## CRITICAL: READ THESE SECTIONS BEFORE WRITING ANY CODE
======================================================================

### Known Godot Errors (from real prior projects — DO NOT REPEAT)

1. NEVER use get_class() — always use "is" keyword for type checking
2. ALL constants MUST be UPPER_SNAKE_CASE
3. add_child() inside _ready() MUST use call_deferred("add_child", node)
4. Save paths MUST use "user://" NOT "res://"
5. NEVER name a function go_to() — conflicts with Godot internals
6. Stub function unused params MUST be prefixed with underscore: _param
7. NEVER use walrus operator := for Color, Vector2, or non-primitives
8. Connect signals with null-check — always verify node exists first
9. NavigationRegion2D must be baked before any navigation is used
10. ALL scene paths defined in GameConstants.gd — NEVER hardcoded strings
11. Use dictionary.get(key, default) NEVER dictionary[key] directly
12. OptionButton: never modify items during execution — disable instead

### Real Error History (Fifth Sun project)
Claude Code confirmed reading all docs then invented constants that
didn't exist. This happens even with full context.
PREVENTION: After writing each file, read it back and audit every
constant name, field name, and function name against this document.
Fix ALL errors in one pass before opening Godot.

### Audit Checklist (run before EVERY Godot open)
[ ] All constants UPPER_SNAKE_CASE
[ ] No hardcoded scene paths (all in GameConstants.gd)
[ ] No add_child() in _ready() without call_deferred
[ ] No get_class() anywhere
[ ] No walrus := for non-primitives
[ ] All stub params prefixed with _
[ ] All signals connected with null-check
[ ] Dictionary access uses .get() not direct []

======================================================================
## SECTION 15: MAP GEOMETRY — THE RULES (MANDATORY READ)
======================================================================

### 15.1 Section Grid Constants
- Every section is 31x31 tiles (NOT 30x30)
- Center tile is position 16,16 (1-indexed)
- TILE_SIZE = 32 pixels per tile
- Edge midpoints (where sections connect):
  North = (16, 1)
  South = (16, 31)
  East  = (31, 16)
  West  = (1, 16)
- Blue tiles = VEX tower zone (TILE_TOWER)
- Red tiles  = path (TILE_PATH)
- These are mutually exclusive — a tile cannot be both

### 15.2 Tower Footprint — 3x3 Grid
A tower occupies a 3x3 tile footprint:
  [B][B][B]
  [B][T][B]    B = buffer zone (exclusive to this tower)
  [B][B][B]    T = tower center tile

Rules:
- Tower buffer zones CANNOT overlap another tower's buffer
- Tower buffer zones CAN overlap a path's buffer zone
- Minimum distance between two tower centers: 3 tiles
  (their 3x3 grids share an edge but never overlap)

### 15.3 Path Buffer Rules
- Path has a directional buffer — applies to SIDES only
  (perpendicular to direction of travel)
- Front/back of path connect directly — no buffer there
- Path buffer zones CANNOT overlap another path's buffer
- Minimum 2 tiles between any two parallel path segments
- Tower buffer CAN overlap path buffer (how towers sit near roads)
- Minimum 3 tiles from a road to have a valid tower placement spot

### 15.4 U-Turn Rules (CRITICAL)
Valid U-turn:
  [■][■][■][■][■][■]   going east
  [■]
  [■]         [T]       tower centered, equal distance both legs
  [■]
  [■][■][■][■][■][■]   coming back west

Invalid — tower off-center (buffer overlaps one path):
  [■][■][■][■][■][■]
  [■]         [T]       TOO CLOSE to top path — INVALID
  [■]
  [■][■][■][■][■][■]

U-turn return leg MUST end further from entry than where it turned.
Net forward progress toward exit must always be maintained.
A U-turn cannot send minions back toward the entry point.

### 15.5 Tower Placement Validation
A placement is VALID only if ALL of these are true:
1. The 3x3 footprint contains NO path tiles
2. The 3x3 footprint does NOT overlap any existing tower's 3x3
3. The tower's radius covers at least one path tile

```gdscript
func is_valid_placement(cx: int, cy: int, path_tiles: Array, towers: Array) -> bool:
    # Rule 1: 3x3 footprint must not contain path tile
    for dx in range(-1, 2):
        for dy in range(-1, 2):
            if get_tile(cx + dx, cy + dy) == GameConstants.TILE_PATH:
                return false
    # Rule 2: No existing tower 3x3 overlaps
    for t in towers:
        if abs(t.x - cx) < 3 and abs(t.y - cy) < 3:
            return false
    # Rule 3: Radius must cover at least one path tile
    var covers = false
    for p in path_tiles:
        if Vector2i(cx, cy).distance_to(p) <= tower_range:
            covers = true
            break
    return covers
```

### 15.7 Section Expansion System
- VEX picks direction: North, South, OR East only
- West is NEVER valid (player entry side — always behind cave)
- New 31x31 section generates from random seed
- VEX base section shifts 31 tiles in chosen direction
- New section connects at matching edge midpoints
- Once placed, section is PERMANENT — never regenerates
- Dead ends = null = minions never choose them

Minion navigation at any junction:
```gdscript
func get_next_direction(came_from: int) -> int:
    for dir in get_connected_neighbors():
        if dir != came_from and has_section(dir):
            return dir
    return Direction.NONE  # should never happen on valid map
```
No A* needed. No NavMesh. Always exactly one valid forward direction.

### 15.8 Path Validation Rules
After every generation attempt, validate:
1. No tile appears twice (path never crosses itself)
2. No two non-sequential path tiles within 2 tiles of each other
3. Last tile within 1 tile of exit edge midpoint
4. First tile within 1 tile of entry edge midpoint

If validation fails: retry with seed+1, then seed+2.
If all 3 fail: use straight path fallback (always valid).
Expected rejection rate: 10-15% of seeds.

```gdscript
func validate_path(path_tiles: Array, entry: Vector2i, exit_pt: Vector2i) -> bool:
    # Rule 1: No duplicates
    var seen = {}
    for t in path_tiles:
        var key = str(t.x) + "," + str(t.y)
        if seen.has(key): return false
        seen[key] = true
    # Rule 2: No non-sequential tiles within 2 of each other
    for i in range(path_tiles.size()):
        for j in range(i + 3, path_tiles.size()):
            var dx = abs(path_tiles[i].x - path_tiles[j].x)
            var dy = abs(path_tiles[i].y - path_tiles[j].y)
            if dx + dy <= 2: return false
    # Rule 3: Ends near exit
    var last = path_tiles[path_tiles.size() - 1]
    if Vector2i(last.x, last.y).distance_to(exit_pt) > 1: return false
    return true
```

======================================================================
## SECTION 8: GODOT BUILD PHASES (Module 1A only)
======================================================================

### File Structure to Create
```
MapGenerator/
├── project.godot
├── scenes/
│   ├── Main.tscn
│   └── MapView.tscn
└── scripts/
    ├── GameConstants.gd    (autoload as "GameConstants")
    ├── SectionGrid.gd      (autoload as "SectionGrid" — NO, plain class)
    ├── PathGenerator.gd    (autoload as "PathGenerator")
    ├── MapManager.gd       (autoload as "MapManager")
    ├── MapRenderer.gd      (Node2D — child of MapView)
    └── Controls.gd         (attached to Main scene root)
```

### GameConstants.gd
```gdscript
extends Node

const SECTION_SIZE = 31
const TILE_SIZE    = 32
const CENTER_TILE  = 16
const TILE_EMPTY   = 0
const TILE_PATH    = 1
const TILE_TOWER   = 2
const TILE_BLOCKED = 3

const EDGE_MIDPOINTS = {
    "north": Vector2i(16, 1),
    "south": Vector2i(16, 31),
    "east":  Vector2i(31, 16),
    "west":  Vector2i(1,  16)
}

enum SectionType { CAVE, HUB, VEX_BASE, EXPANSION }
enum Direction    { NORTH, SOUTH, EAST, WEST, NONE }

# Tile colors for rendering
const COLOR_PATH    = Color(0.70, 0.10, 0.10)
const COLOR_TOWER   = Color(0.20, 0.60, 0.80)
const COLOR_EMPTY   = Color(0.15, 0.15, 0.20)
const COLOR_BLOCKED = Color(0.10, 0.10, 0.10)
const COLOR_VALID   = Color(0.20, 0.60, 0.80, 0.5)
const COLOR_INVALID = Color(0.80, 0.40, 0.10, 0.5)
const COLOR_WAYPOINT    = Color(0.20, 0.90, 0.30)
const COLOR_CONNECTION  = Color(0.90, 0.80, 0.10)
```

### SectionGrid.gd (plain class, not autoload)
```gdscript
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
    tiles = []
    for x in range(GameConstants.SECTION_SIZE):
        var col = []
        for y in range(GameConstants.SECTION_SIZE):
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
        _dir_to_string(entry_dir), Vector2i(1, 16))

func get_exit_point() -> Vector2i:
    return GameConstants.EDGE_MIDPOINTS.get(
        _dir_to_string(exit_dir), Vector2i(31, 16))

func _dir_to_string(dir: int) -> String:
    match dir:
        GameConstants.Direction.NORTH: return "north"
        GameConstants.Direction.SOUTH: return "south"
        GameConstants.Direction.EAST:  return "east"
        GameConstants.Direction.WEST:  return "west"
    return "west"

func flag_tower_zones() -> void:
    tower_zones.clear()
    for x in range(GameConstants.SECTION_SIZE):
        for y in range(GameConstants.SECTION_SIZE):
            if get_tile(x, y) == GameConstants.TILE_EMPTY:
                if _is_valid_tower_center(x, y):
                    set_tile(x, y, GameConstants.TILE_TOWER)
                    tower_zones.append(Vector2i(x, y))

func _is_valid_tower_center(cx: int, cy: int) -> bool:
    # 3x3 footprint must not contain path tile
    for dx in range(-1, 2):
        for dy in range(-1, 2):
            if get_tile(cx + dx, cy + dy) == GameConstants.TILE_PATH:
                return false
    # Must be within reasonable range of a path tile (max 8 tiles)
    for p in path_tiles:
        if Vector2i(cx, cy).distance_to(p) <= 8:
            return true
    return false
```

### PathGenerator.gd (autoload)
```gdscript
extends Node

func generate(section: SectionGrid) -> bool:
    var entry = section.get_entry_point()
    var exit_pt = section.get_exit_point()
    
    # Try up to 3 seeds
    for attempt in range(3):
        var seed_attempt = section.seed_val + attempt
        var path = _generate_attempt(section, entry, exit_pt, seed_attempt)
        if path.size() > 0 and _validate_path(path, entry, exit_pt):
            _apply_path(section, path)
            section.flag_tower_zones()
            return true
    
    # Fallback: straight path
    _carve_straight(section, entry, exit_pt)
    section.flag_tower_zones()
    return true  # straight always valid

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
    var path = []
    var cur = Vector2i(entry)
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
    # Go sideways first (bias direction), then toward exit
    var path = []
    var cur = Vector2i(entry)
    var mid_offset = rng.randi_range(4, 10) * bias
    # Move perpendicular first
    var perp_steps = abs(mid_offset)
    var perp_dir = sign(mid_offset)
    # Determine if primary travel is horizontal or vertical
    var travel_h = abs(exit_pt.x - entry.x) > abs(exit_pt.y - entry.y)
    for _i in range(perp_steps):
        path.append(cur)
        if travel_h: cur.y += perp_dir
        else: cur.x += perp_dir
    # Then move toward exit
    while cur != exit_pt:
        path.append(cur)
        var dx = sign(exit_pt.x - cur.x)
        var dy = sign(exit_pt.y - cur.y)
        if dx != 0: cur.x += dx
        elif dy != 0: cur.y += dy
    path.append(exit_pt)
    return path

func _build_zigzag(entry: Vector2i, exit_pt: Vector2i,
                   rng: RandomNumberGenerator) -> Array:
    # Move partway, jog sideways, continue
    var path = []
    var cur = Vector2i(entry)
    var mid_x = (entry.x + exit_pt.x) / 2
    var mid_y = (entry.y + exit_pt.y) / 2
    var jog = rng.randi_range(3, 6) * (1 if rng.randi() % 2 == 0 else -1)
    # Leg 1: go to midpoint
    while cur.x != mid_x or cur.y != mid_y:
        path.append(cur)
        var dx = sign(mid_x - cur.x)
        var dy = sign(mid_y - cur.y)
        if dx != 0: cur.x += dx
        elif dy != 0: cur.y += dy
    # Jog perpendicular
    var jog_steps = abs(jog)
    var jog_dir = sign(jog)
    var travel_h = abs(exit_pt.x - entry.x) > abs(exit_pt.y - entry.y)
    for _i in range(jog_steps):
        path.append(cur)
        if travel_h: cur.y += jog_dir
        else: cur.x += jog_dir
    # Leg 2: go to exit
    while cur != exit_pt:
        path.append(cur)
        var dx = sign(exit_pt.x - cur.x)
        var dy = sign(exit_pt.y - cur.y)
        if dx != 0: cur.x += dx
        elif dy != 0: cur.y += dy
    path.append(exit_pt)
    return path

func _validate_path(path: Array, entry: Vector2i, exit_pt: Vector2i) -> bool:
    if path.size() < 2: return false
    # Rule 1: No duplicates
    var seen = {}
    for t in path:
        var key = str(t.x) + "," + str(t.y)
        if seen.has(key): return false
        seen[key] = true
    # Rule 2: No non-sequential tiles within 2 of each other
    for i in range(path.size()):
        for j in range(i + 3, path.size()):
            var dx = abs(path[i].x - path[j].x)
            var dy = abs(path[i].y - path[j].y)
            if dx + dy <= 2: return false
    # Rule 3: Ends near exit
    var last = path[path.size() - 1]
    if last.distance_to(exit_pt) > 1: return false
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
```

### MapManager.gd (autoload)
```gdscript
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
    s_cave.world_offset = Vector2(0, 0)
    sections.append(s_cave)

    var s_hub = SectionGrid.new()
    s_hub.initialize(GameConstants.SectionType.HUB,
                     GameConstants.Direction.WEST,
                     GameConstants.Direction.EAST, 1)
    PathGenerator.generate(s_hub)
    s_hub.world_offset = Vector2(GameConstants.SECTION_SIZE *
                                  GameConstants.TILE_SIZE, 0)
    sections.append(s_hub)

    var s_vex = SectionGrid.new()
    s_vex.initialize(GameConstants.SectionType.VEX_BASE,
                     GameConstants.Direction.WEST,
                     GameConstants.Direction.NONE, 2)
    PathGenerator.generate(s_vex)
    s_vex.world_offset = Vector2(GameConstants.SECTION_SIZE *
                                  GameConstants.TILE_SIZE * 2, 0)
    sections.append(s_vex)

func add_section(direction: int) -> bool:
    if direction == GameConstants.Direction.WEST:
        return false  # West is never valid
    if direction == GameConstants.Direction.NONE:
        return false
    # Check direction not already used
    if direction in expansion_history:
        return false
    # Generate new expansion section
    var new_seed = randi()
    var new_section = SectionGrid.new()
    new_section.initialize(GameConstants.SectionType.EXPANSION,
                           _opposite(direction), direction, new_seed)
    PathGenerator.generate(new_section)
    # Insert before VEX base, shift VEX base
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
    var valid = []
    for dir in [GameConstants.Direction.NORTH,
                GameConstants.Direction.SOUTH,
                GameConstants.Direction.EAST]:
        if not (dir in expansion_history):
            valid.append(dir)
    return valid

func get_minion_waypoints() -> Array:
    var waypoints = []
    for section in sections:
        for pt in section.path_tiles:
            waypoints.append(section.world_offset +
                Vector2(pt.x * GameConstants.TILE_SIZE,
                        pt.y * GameConstants.TILE_SIZE))
    return waypoints

func regenerate_section(index: int, new_seed: int) -> void:
    if index < 0 or index >= sections.size(): return
    var s = sections[index]
    s.seed_val = new_seed
    # Clear tiles
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
    var step = GameConstants.SECTION_SIZE * GameConstants.TILE_SIZE
    match dir:
        GameConstants.Direction.NORTH: return Vector2(0, -step)
        GameConstants.Direction.SOUTH: return Vector2(0,  step)
        GameConstants.Direction.EAST:  return Vector2( step, 0)
        GameConstants.Direction.WEST:  return Vector2(-step, 0)
    return Vector2.ZERO
```

### MapRenderer.gd (Node2D)
```gdscript
extends Node2D

var show_overlay: bool = false
var show_waypoints: bool = false
var show_connections: bool = false
var _manager: MapManager = null

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
    if _manager == null: return
    for section in _manager.sections:
        _draw_section(section)
    if show_waypoints:
        _draw_waypoints()
    if show_connections:
        _draw_connections()

func _draw_section(section: SectionGrid) -> void:
    var ts = GameConstants.TILE_SIZE
    for x in range(GameConstants.SECTION_SIZE):
        for y in range(GameConstants.SECTION_SIZE):
            var tile = section.get_tile(x, y)
            var color: Color
            match tile:
                GameConstants.TILE_PATH:    color = GameConstants.COLOR_PATH
                GameConstants.TILE_TOWER:   color = GameConstants.COLOR_TOWER
                GameConstants.TILE_BLOCKED: color = GameConstants.COLOR_BLOCKED
                _:                          color = GameConstants.COLOR_EMPTY
            var rect = Rect2(section.world_offset +
                             Vector2(x * ts, y * ts),
                             Vector2(ts, ts))
            draw_rect(rect, color)
            draw_rect(rect, Color(0, 0, 0, 0.2), false, 0.5)
            # Overlay
            if show_overlay and tile == GameConstants.TILE_TOWER:
                draw_rect(rect, GameConstants.COLOR_VALID)
            elif show_overlay and tile == GameConstants.TILE_EMPTY:
                draw_rect(rect, GameConstants.COLOR_INVALID)

func _draw_waypoints() -> void:
    var waypoints = _manager.get_minion_waypoints()
    for wp in waypoints:
        draw_circle(wp + Vector2(GameConstants.TILE_SIZE / 2,
                                  GameConstants.TILE_SIZE / 2),
                    4.0, GameConstants.COLOR_WAYPOINT)

func _draw_connections() -> void:
    for section in _manager.sections:
        for dir_name in ["north", "south", "east", "west"]:
            var mid = GameConstants.EDGE_MIDPOINTS.get(dir_name, Vector2i())
            var world_pt = section.world_offset + Vector2(
                mid.x * GameConstants.TILE_SIZE,
                mid.y * GameConstants.TILE_SIZE)
            draw_circle(world_pt, 8.0, GameConstants.COLOR_CONNECTION)
```

### Controls.gd (attached to Main scene root)
```gdscript
extends Control

@onready var seed_input   = $VBox/SeedRow/SeedInput
@onready var status_label = $VBox/StatusLabel
@onready var map_renderer = $MapView/MapRenderer

func _ready() -> void:
    MapManager.initialize_default_map()
    _refresh()

func _on_generate_pressed() -> void:
    var seed = int(seed_input.value)
    MapManager.initialize_default_map()
    # Apply seed to all sections
    for i in range(MapManager.sections.size()):
        MapManager.regenerate_section(i, seed + i)
    _refresh()

func _on_add_north_pressed() -> void:
    var ok = MapManager.add_section(GameConstants.Direction.NORTH)
    status_label.text = "Added North section." if ok else \
                        "INVALID: North direction already used or blocked."
    _refresh()

func _on_add_south_pressed() -> void:
    var ok = MapManager.add_section(GameConstants.Direction.SOUTH)
    status_label.text = "Added South section." if ok else \
                        "INVALID: South direction already used or blocked."
    _refresh()

func _on_add_east_pressed() -> void:
    var ok = MapManager.add_section(GameConstants.Direction.EAST)
    status_label.text = "Added East section." if ok else \
                        "INVALID: East direction already used or blocked."
    _refresh()

func _on_remove_last_pressed() -> void:
    var ok = MapManager.remove_last_section()
    status_label.text = "Removed last expansion." if ok else \
                        "INVALID: No expansion sections to remove."
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
    var total_path = 0
    var total_tower = 0
    for s in MapManager.sections:
        total_path  += s.path_tiles.size()
        total_tower += s.tower_zones.size()
    status_label.text = (
        "Sections: %d | Path tiles: %d | Tower zones: %d" %
        [MapManager.sections.size(), total_path, total_tower]
    )
```

======================================================================
## DEFINITION OF DONE — Module 1A
======================================================================

ALL of these must pass before committing:

[ ] F5 launches — zero errors, zero warnings in Output panel
[ ] Default map renders: Cave (left) + Hub (center) + VEX Base (right)
[ ] Path tiles are RED, tower zones are BLUE, empty is DARK
[ ] Seed 12345 → same map every run (deterministic)
[ ] Seed 99999 → different but valid map
[ ] "Add North" → north section appears, VEX Base shifts north
[ ] "Add South" → south section appears, VEX Base shifts south
[ ] "Add East"  → east section appears, VEX Base shifts east
[ ] Adding same direction twice → rejected, status shows reason
[ ] "Remove Last" → last expansion removed, VEX Base reverts
[ ] "Regenerate Cave" → cave internal path changes, position unchanged
[ ] "Regenerate VEX Base" → VEX base internal path changes, unchanged
[ ] Show Waypoints → green dots trace CONTINUOUS path Cave→VEX Base
[ ] Show Connections → yellow dots at ALL edge midpoints, always aligned
[ ] Show Overlay → blue on valid tower spots, orange on invalid
[ ] status_label shows correct section/tile/zone counts
[ ] No section ever overlaps another section
[ ] Path is always continuous — no gaps between sections

DO NOT IMPLEMENT:
- Minions, towers, AI, gold, economy
- Cave interior (Farm/Bazaar/Crystal)
- Any game logic

This is a map geometry validator ONLY.

When all checkboxes pass:
Commit message: "Module 1A complete — map generator passing all validation"
Do not ask for incremental approval. Run to completion.
Report when Definition of Done is met OR when hitting a blocker.

