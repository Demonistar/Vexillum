extends Node

const SECTION_SIZE = 31
const TILE_SIZE    = 32
const CENTER_TILE  = 16  # 1-indexed center position (reference only)
const TILE_EMPTY   = 0
const TILE_PATH    = 1
const TILE_TOWER   = 2
const TILE_BLOCKED = 3

# 0-indexed edge midpoints — tile indices 0..30
# west (0,15): leftmost tile at mid-row
# east (30,15): rightmost tile at mid-row
# This ensures adjacent sections share pixel-adjacent path tiles
const EDGE_MIDPOINTS = {
	"north":  Vector2i(15, 0),
	"south":  Vector2i(15, 30),
	"east":   Vector2i(30, 15),
	"west":   Vector2i(0,  15),
	"center": Vector2i(15, 15)
}

enum SectionType { CAVE, HUB, VEX_BASE, EXPANSION }
enum Direction    { NORTH, SOUTH, EAST, WEST, NONE }

# Tile colors for rendering
const COLOR_PATH       = Color(0.70, 0.10, 0.10)
const COLOR_TOWER      = Color(0.20, 0.60, 0.80)
const COLOR_EMPTY      = Color(0.15, 0.15, 0.20)
const COLOR_BLOCKED    = Color(0.10, 0.10, 0.10)
const COLOR_VALID      = Color(0.20, 0.60, 0.80, 0.5)
const COLOR_INVALID    = Color(0.80, 0.40, 0.10, 0.5)
const COLOR_WAYPOINT   = Color(0.20, 0.90, 0.30)
const COLOR_CONNECTION = Color(0.90, 0.80, 0.10)
