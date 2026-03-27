


VEXILLUM
COMPLETE BUILD BIBLE — GODOT & PHASER IMPLEMENTATION PLAN

Version 1.3  |  All Systems  |  Godot 4.x + Phaser.js  |  Confidential

Designed by Genius Mullins


## Document Purpose
--------------------------------------------------
This document is the complete implementation reference for VEXILLUM for both Godot 4 (Claude Code) and Phaser.js (Replit). It covers the full game design, all systems in exact detail, the complete enemy and tower taxonomy, V.E.X. AI architecture, map geometry rules, build phases with testable milestones, and a comprehensive list of known errors to watch for. Feed this document to your AI build tool at the start of each session. Direct Claude Code to Section 14.1. Direct Replit to Section 14.2.


## Quick Reference — What We Have vs What We Need
--------------------------------------------------


======================================================================
# 1. Core Design Problems Identified in Prototype
======================================================================


These problems were identified during HTML prototype testing and MUST be solved in Godot implementation.


## 1.1  The Spawner Lock Problem
--------------------------------------------------
Currently the player can pick any minion type from wave 1. This destroys balance and eliminates the discovery loop. In a real Tower Defense, enemies are introduced gradually to teach the player each tower counter. In reverse TD, minion types must be UNLOCKED through gameplay so VEX has time to build appropriate counters.
⚠ WARNING: Player must start with ONLY the Crawler (basic unit). All other types require Research unlocks.


### Solution — Research & Unlock System
Wave 1-2: Crawler only. VEX learns Crawler. Player earns Gold from distance.
Wave 3: Research tree unlocks. Player can spend Gold on: Tank, Flyer, OR Stealth — not all at once.
Wave 5+: Second research tier. Splitter, Healer, Regen available.
Wave 8+: Third tier. Fusion unlocks. Evolution paths available.
Each unlock costs Gold AND requires previous wave minimums.


## 1.2  The "Free Units" Problem
--------------------------------------------------
Currently player gets 5 Crawlers on wave 1 for free with no friction. There is no resource cost to sending units — only a tier upgrade cost. This means the player can immediately flood the path and earn Gold with zero risk or investment decision.
⚠ WARNING: Sending minions must have a cost. Not a large one — but enough that the player has to choose between sending more units vs upgrading vs researching.

### Solution — Deployment Cost
Each Spawner slot costs Gold to activate per wave (small cost: 10-20G per slot active).
Higher tier spawners cost more to run per wave.
This means: sending 5 Tier-3 Swarmers costs 30G to deploy that slot. Worth it? Depends on path length.
VEX earns more Byte-coins for stopping expensive waves — acknowledges the investment.


## 1.3  The VEX Intelligence Problem
--------------------------------------------------
VEX is currently too reactive and too slow to adapt. By the time it places a Detection tower, the player has already won with stealth. The core issue is that VEX has no hedge budget — it spends everything on what counters the LAST wave, leaving it exposed to ANY change.
⚠ WARNING: VEX must ALWAYS maintain minimum coverage of all major threat types, even if it has not seen them yet. This is the hedge budget.

### Solution — Weighted Reserve System
VEX divides its budget: 60% offensive (counters last seen threats), 30% hedge (covers unseen threats at minimum level), 10% reserve (emergency fund for mid-wave response).
Hedge always includes: 1 AA tower (even if no Flyers seen), 1 Detection tower near a damage cluster (even if no Stealth seen).
On Hard+: hedge increases to 40%. On Insane: 50%. VEX always has an answer.
On Easy: hedge is only 15%. VEX is genuinely catchable.


## 1.4  The Path Problem
--------------------------------------------------
Single fixed path means the player can perfectly optimise for one route. VEX path expansion (adding sections each wave) creates the dynamic map needed for real strategy variance.

### Solution — Grid-Based Expandable Path
Map is a 30x30 unit grid system. Each grid block = 30x30 pixels in Godot.
Path tiles are flagged. Tower zones are flagged. These are mutually exclusive.
Each wave VEX picks a direction. Seed generates a path section. Section always connects center-to-center of adjacent grid edges.
New tower zones are automatically flagged when a new section is added.
Player does NOT see VEX's path expansion pick during the plan phase — only sees result at wave start.


======================================================================
# 2. Complete Player Minion Taxonomy
======================================================================


This is the full roster of player-deployable minion types. In Reverse TD, these are the "enemies" from VEX's perspective — equivalent to creep types in a standard TD. Each has base stats, unlock requirements, upgrade path, evolution path, and faction variants.


## 2.1  Tier 1 — Starter Units (Unlocked Wave 1)
--------------------------------------------------
The Crawler exists solely to let VEX log encounter data and for the player to earn starting Gold. Getting wiped is expected and designed.


## 2.2  Tier 2 — Research Unlocks (Wave 3+, 200G each)
--------------------------------------------------


## 2.3  Tier 3 — Advanced Research (Wave 5+, 400G each)
--------------------------------------------------


## 2.4  Tier 4 — Fusion Units (Wave 8+, must research two Tier 3 units first)
--------------------------------------------------


## 2.5  Evolution System — Unit Growth
--------------------------------------------------
Any Tier 2+ unit can be evolved using Byte-coins between sessions. Evolution is permanent and applies to all future uses of that unit. Think Pokemon — the unit grows into a more powerful form with enhanced abilities, not just stat bumps.


## 2.6  Boss Units — Milestone Wave Deployments
--------------------------------------------------
Player selects Boss type from unlocked roster at milestone waves (every 10). VEX knows a Boss wave is coming but NOT which type. Boss selection is hidden during the plan phase.


======================================================================
# 3. Complete V.E.X. Tower Taxonomy
======================================================================


These are VEX's defensive tools. From the player's perspective these are the obstacles to overcome — equivalent to what towers do to enemies in standard TD. Each has base stats, upgrade path (3 session tiers), permanent Byte-coin upgrades (5 levels), and merge potential.


## 3.1  Base Tower Roster — 8 Core + 4 Specialist
--------------------------------------------------


## 3.2  Session Upgrade Tiers (Gold — resets each run)
--------------------------------------------------


### Tier 3 Secondary Effects by Tower
Bolt T3: Piercing shot — projectile passes through first target and hits one behind it
Burst T3: Napalm — AoE leaves burning ground for 3 seconds (DoT zone)
Volley T3: Burst fire — fires 3 rounds per trigger instead of 1
Chill T3: Freeze — slows become full freezes for 0.8 seconds on kill blow
Ember T3: Inferno — DoT aura damage doubles, range increases 20%
Skywatcher T3: Flak burst — AoE blast on air unit kill damages nearby air units
Lantern T3: True Sight — reveals AND damages stealth units. Detection range doubles.
Beacon T3: War Drum — buff increases to +40% damage and adds +15% fire rate


## 3.3  Permanent Byte-coin Upgrades (5 levels, persist across sessions)
--------------------------------------------------


### Level 3 Passive Abilities


## 3.4  Double Merge Table (requires Level 5 on both towers)
--------------------------------------------------


======================================================================
# 4. V.E.X. AI Architecture — Complete Implementation
======================================================================


VEX is not a real AI. It is a weighted priority queue fed by a dictionary of encounter data. This section covers the EXACT implementation in GDScript. Copy this architecture into Godot verbatim.


## 4.1  Brain Data Structure
--------------------------------------------------
```
# vex_brain.gd — attach to VEX node
extends Node

var brain = {
    "encounter_log": {},      # keyed by unit_type_id
    "tower_research": {},     # keyed by tower_type_id
    "player_patterns": {
        "wave_sequences": [],  # last 8 wave compositions
        "bluff_count": 0,     # times player switched after 3+ same-type waves
        "stealth_after_eye_sold": 0,
        "flyer_after_aa_sold": 0,
        "favourite_type": "",
        "boss_history": []
    },
    "resource_state": {
        "current_gold": 0,
        "reserve_pct": 0.30,  # scales with difficulty
        "hedge_pct": 0.30,
        "waves_until_boss": 10
    },
    "difficulty_modifiers": {
        "easy":       {"reserve":0.10, "hedge":0.15, "anticipation_waves":1},
        "normal":     {"reserve":0.20, "hedge":0.25, "anticipation_waves":3},
        "hard":       {"reserve":0.25, "hedge":0.35, "anticipation_waves":5},
        "insane":     {"reserve":0.30, "hedge":0.45, "anticipation_waves":8},
        "hell":       {"reserve":0.35, "hedge":0.50, "anticipation_waves":10},
    }
}
```

```
# Encounter log entry structure (auto-created on first sighting)
var new_encounter = {
    "type": unit_type_id,
    "times_seen": 0,
    "times_broke_through": 0,
    "first_wave": current_wave,
    "best_counter": "",        # tower type that kills it fastest
    "worst_counter": "",       # tower type that barely affects it
    "is_flying": false,
    "is_stealth": false,
    "is_regen": false,
    "is_splitter": false,
    "cascade_known": false,    # does VEX know about split behaviour yet?
    "confidence": 0.0          # 0.0-1.0 — how well does VEX understand this unit
}
```


## 4.2  Priority Queue — The Decision Engine
--------------------------------------------------
```
func vex_think(current_gold: int, wave_num: int) -> Array:
    var actions = []
    
    # Calculate scores for every possible action
    actions.append({"action": "upgrade_existing",  "score": _score_upgrade()})
    actions.append({"action": "place_bolt",        "score": _score_bolt()})
    actions.append({"action": "place_burst",       "score": _score_burst()})
    actions.append({"action": "place_chill",       "score": _score_chill()})
    actions.append({"action": "place_ember",       "score": _score_ember()})
    actions.append({"action": "place_aa",          "score": _score_aa()})
    actions.append({"action": "place_detection",   "score": _score_detection()})
    actions.append({"action": "place_beacon",      "score": _score_beacon()})
    actions.append({"action": "sell_dead_tower",   "score": _score_sell()})
    actions.append({"action": "hold_reserve",      "score": _score_reserve()})
    
    # Sort descending by score
    actions.sort_custom(func(a, b): return a.score > b.score)
    
    return actions  # caller executes top actions until budget spent
```


### Scoring Function Example — Detection Tower
```
func _score_detection() -> float:
    var score = 0.0
    var stealth_data = brain.encounter_log.get("wraith", null)
    var phantom_data = brain.encounter_log.get("phantom", null)
    
    # Base score from encounter history
    if stealth_data:
        score += stealth_data.times_seen * 8.0
        score += stealth_data.times_broke_through * 20.0
        score += (1.0 - stealth_data.confidence) * 15.0  # uncertainty = more investment
    
    if phantom_data:  # Phantom (stealth + fly fusion) is worst case
        score += phantom_data.times_broke_through * 35.0
    
    # Subtract if we already have adequate detection coverage
    var detection_count = _count_towers_of_type("lantern")
    score -= detection_count * 18.0
    
    # Hedge budget always provides minimum detection score
    if detection_count == 0:
        score += 30.0  # Always place at least one, even unseen
    
    # Player pattern manipulation detection
    if brain.player_patterns.stealth_after_eye_sold >= 2:
        score += 50.0  # Player has done this trick before — maintain detection
    
    # Boss wave anticipation
    if brain.resource_state.waves_until_boss <= 3:
        score += 15.0  # Boss might be stealth type
    
    return score
```


## 4.3  Placement Clustering Logic
--------------------------------------------------
This is the most critical AI fix. Detection and AA towers placed in isolation are useless. VEX must always place specialist towers within range-overlap of damage towers.
```
func _find_cluster_zone(near_tower: Tower, new_tower_range: float) -> Vector2:
    # Find a tower zone that:
    # 1. Is within 80px of near_tower (overlap range)
    # 2. Is not too close to another tower (min 45px spacing)
    # 3. Actually covers the path with new_tower_range
    
    var best_zone = Vector2.ZERO
    var best_dist = INF
    
    for zone in tower_zones:
        var dist_to_anchor = zone.distance_to(near_tower.global_position)
        if dist_to_anchor < 20 or dist_to_anchor > 80:
            continue
        if _zone_too_close_to_existing(zone):
            continue
        if not _zone_covers_path(zone, new_tower_range):
            continue
        if dist_to_anchor < best_dist:
            best_dist = dist_to_anchor
            best_zone = zone
    
    return best_zone  # Returns Vector2.ZERO if no valid cluster zone found
```


## 4.4  Bluff Detection System
--------------------------------------------------
```
func _detect_bluff_pattern() -> bool:
    var seq = brain.player_patterns.wave_sequences
    if seq.size() < 4:
        return false
    
    # Check for 3+ same type followed by anything
    var last_type = seq[-1]
    var streak = 0
    for i in range(seq.size() - 2, -1, -1):
        if seq[i] == last_type:
            streak += 1
        else:
            break
    
    if streak >= 3:
        # Player has sent same type 3+ waves — classic bluff setup
        brain.player_patterns.bluff_count += 1
        return true
    
    return false

# When bluff detected — VEX hedges instead of committing
func _apply_bluff_hedge(primary_tower_type: String) -> String:
    # Instead of going all-in on counter, mix 60/40
    if randf() < 0.4:
        return _get_secondary_counter(primary_tower_type)
    return primary_tower_type
```


## 4.5  VEX Budget Allocation
--------------------------------------------------
```
func _allocate_budget(total_gold: int) -> Dictionary:
    var diff = difficulty_settings[current_difficulty]
    
    var reserve = int(total_gold * diff.reserve_pct)
    var hedge   = int(total_gold * diff.hedge_pct)
    var offense = total_gold - reserve - hedge
    
    return {
        "offense": offense,   # Counter last wave threats
        "hedge":   hedge,     # Minimum coverage all threat types
        "reserve": reserve    # Emergency mid-wave fund (not spent normally)
    }

# IMPORTANT: Reserve is NEVER spent during placement phase
# It is only spent if VEX detects mid-wave breakthrough (future feature)
# This makes VEX feel like it's holding something back
```


## 4.6  Tower Sell Logic
--------------------------------------------------
```
func _should_sell_tower(tower: Tower) -> bool:
    # NEVER sell a tower that killed something in the last 2 waves
    if tower.kills_last_2_waves > 0:
        return false
    
    # Consider selling if zero kills for 3+ waves AND we need budget
    if tower.waves_without_kill >= 3 and _is_budget_strained():
        return true
    
    # Sell if player has completely stopped using the type it counters
    var counter_type = TOWER_COUNTERS[tower.type]
    if brain.encounter_log.has(counter_type):
        var last_seen = brain.encounter_log[counter_type].last_seen_wave
        if current_wave - last_seen > 4:  # Not seen in 4+ waves
            return true
    
    return false

# Sell return: 60% of original cost
func get_sell_value(tower: Tower) -> int:
    return int(tower.base_cost * 0.60)
```


======================================================================
# 5. Grid System & Procedural Path
======================================================================


## 5.1  Grid Architecture
--------------------------------------------------
The map is divided into grid sections. Each section is a 30x30 tile block (where 1 tile = 32 pixels in Godot). A section contains a sub-grid of tiles flagged as: PATH, TOWER_ZONE, BLOCKED, or EMPTY.
```
# grid_section.gd
const SECTION_SIZE = 30  # tiles per section edge
const TILE_SIZE = 32     # pixels per tile

enum TileType {
    EMPTY,
    PATH,
    TOWER_ZONE,   # VEX can place towers here
    BLOCKED       # Neither path nor tower (decorative/edge)
}

var tiles = []  # 2D array [x][y] of TileType
var entry_point: Vector2i  # always center of incoming edge
var exit_point: Vector2i   # always center of outgoing edge
var tower_valid_zones = [] # pre-computed list of TOWER_ZONE positions
```


## 5.2  Connection System
--------------------------------------------------
Path sections connect center-to-center of adjacent edges. This guarantees geometric connectivity regardless of internal path geometry.
```
# Entry/exit points are FIXED for each section edge direction
# North edge entry: (SECTION_SIZE/2, 0)     = (15, 0)
# South edge entry: (SECTION_SIZE/2, 29)    = (15, 29)
# East edge entry:  (29, SECTION_SIZE/2)    = (29, 15)
# West edge entry:  (0, SECTION_SIZE/2)     = (0, 15)

# Internal path connects entry to exit via seed-generated geometry
# Seed only generates the MIDDLE — entry and exit are predetermined
func generate_internal_path(seed_val: int, from_dir: int, to_dir: int) -> void:
    var entry = get_edge_center(from_dir)
    var exit_p = get_edge_center(to_dir)
    
    # Use seed to pick path type
    var path_type = seed_val % PathType.COUNT
    match path_type:
        PathType.STRAIGHT:    _carve_straight(entry, exit_p)
        PathType.CURVE_LEFT:  _carve_curve(entry, exit_p, -1)
        PathType.CURVE_RIGHT: _carve_curve(entry, exit_p, 1)
        PathType.S_CURVE:     _carve_s_curve(entry, exit_p)
        PathType.ZIGZAG:      _carve_zigzag(entry, exit_p)
        PathType.LOOP:        _carve_loop(entry, exit_p)
```


## 5.3  Tower Zone Auto-Flagging
--------------------------------------------------
```
func flag_tower_zones() -> void:
    tower_valid_zones.clear()
    
    for x in range(SECTION_SIZE):
        for y in range(SECTION_SIZE):
            if tiles[x][y] == TileType.EMPTY:
                var dist = _min_dist_to_path(Vector2i(x, y))
                # Must be close enough that SMALLEST tower range covers path
                # Smallest range = Barrier at ~50px = ~1.5 tiles
                # So max distance = 1.5 tiles from path edge
                if dist >= 1 and dist <= 2:  # 1-2 tiles from path
                    tiles[x][y] = TileType.TOWER_ZONE
                    tower_valid_zones.append(Vector2i(x, y))
```
⚠ WARNING: Tower zones must be re-flagged every time a new path section is added to the map.


## 5.4  Path Expansion — VEX Picks Direction
--------------------------------------------------
```
func vex_expand_path() -> void:
    # VEX picks a direction based on strategic value
    # Strategic value = which direction creates longest possible path?
    var direction_scores = {}
    
    for dir in [Direction.NORTH, Direction.SOUTH, Direction.EAST, Direction.WEST]:
        if not _is_direction_available(dir):
            continue
        # Score = estimated path length increase in that direction
        direction_scores[dir] = _estimate_path_length_gain(dir)
    
    # On Easy: random. On Hard+: pick highest score with some variance
    var chosen_dir
    match difficulty:
        "easy":   chosen_dir = _random_available_direction()
        "normal": chosen_dir = _weighted_direction(direction_scores, 0.3)
        "hard":   chosen_dir = _weighted_direction(direction_scores, 0.15)
        "insane": chosen_dir = direction_scores.keys()[0]  # always best
    
    # Generate section — VEX does NOT control internal geometry
    var seed_val = randi()  # truly random — VEX cannot predict it
    var new_section = GridSection.new()
    new_section.generate_internal_path(seed_val, Direction.opposite(chosen_dir), _pick_exit_dir())
    
    _append_section(new_section)
    
    # VEX cannot undo this if the seed generates a shortcut
    # This is intentional — VEX can be unlucky
```


======================================================================
# 6. Economy & Progression Systems
======================================================================


## 6.1  Session Economy — Gold
--------------------------------------------------
Gold is the per-session tactical currency. The core earning loop is distance-based — minions earn Gold based on how far they travel, not whether they survive.


## 6.2  Gold Spending — Player Options
--------------------------------------------------


## 6.3  Permanent Currency — Byte-coins
--------------------------------------------------
Byte-coins persist across ALL sessions of the same save file. Both player and VEX earn them. VEX spends them automatically between sessions on its upgrade tree. Player spends them manually between sessions on the upgrade screen.


## 6.4  Player Byte-coin Upgrade Tree
--------------------------------------------------


======================================================================
# 7. Godot Build Phases
======================================================================


Each phase has a clear testable milestone. DO NOT proceed to the next phase until the current phase milestone passes all tests. Each phase should be a separate Git commit.
⚠ WARNING: Read the Known Godot Gotchas section (Section 9) BEFORE starting ANY phase. Many common errors are avoidable by reading it first.


## Phase 1 — Foundation: Scenes, Grid & Path
--------------------------------------------------
Goal: A map exists with a grid, a hardcoded starter path, and minions can walk it.


### Scene Structure
```
Main.tscn
├── GameManager (Node — autoload singleton)
├── Map (Node2D)
│   ├── GridSystem (Node2D)
│   │   ├── TileMap (TileMapLayer x3: ground, path, overlay)
│   │   └── TowerContainer (Node2D)
│   ├── PathContainer (Node2D) — holds path waypoints
│   └── MinionContainer (Node2D)
├── UI (CanvasLayer)
│   ├── SpawnerPanel (Control)
│   ├── StatsBar (Control)
│   ├── TimerBar (Control)
│   └── VEXPanel (Control)
└── VEX (Node — AI controller)
```


### Phase 1 Milestones
TileMap loads with 30x30 grid visible
Path tiles flagged and rendered as distinct color
Tower zone tiles flagged and rendered
Minion scene created with NavigationAgent2D
Minion walks path start to end following waypoints
Minion death triggers Gold increment
Gold displays in UI correctly

⚠ WARNING: Do NOT use get_class() to check node types — causes conflicts. Use is keyword: if node is Minion.
⚠ WARNING: NavigationAgent2D requires NavigationRegion2D parent. Add it to Map scene or navigation will silently fail.
✅ TIP: Set path waypoints as an Array[Vector2] on GameManager. Minions read from this array, not from the scene tree directly.


## Phase 2 — Spawner System & Wave Timer
--------------------------------------------------
Goal: Player has spawner UI, can assign a Crawler to slot 1, timer counts down, wave sends.


### Phase 2 Milestones
SpawnerSlot scene created with OptionButton for unit assignment
Plan phase timer (60 seconds) counts down, triggers wave on zero
Send Wave button works — disables during execution phase
Wave execution: spawns correct number of Crawlers with staggered delay
After all minions dead or through: wave end triggers, plan phase restarts
Wave counter increments correctly
Gold earns per distance correctly (use _process delta accumulation)

⚠ WARNING: Timer uses get_tree().create_timer() for simple countdowns — DO NOT use Timer nodes for gameplay timers, they do not pause correctly. Use a float variable decremented in _process.
⚠ WARNING: Spawner slot OptionButton: signal item_selected does NOT fire on programmatic set_item. Use select() then emit signal manually if setting default values in code.
```
# Correct way to track distance gold
var dist_gold_accumulator = 0.0
func _process(delta):
    if is_alive and is_on_path:
        dist_gold_accumulator += speed * delta * gold_per_tile
        if dist_gold_accumulator >= 1.0:
            GameManager.add_gold(int(dist_gold_accumulator))
            dist_gold_accumulator = fmod(dist_gold_accumulator, 1.0)
```


## Phase 3 — VEX Tower Placement
--------------------------------------------------
Goal: VEX places towers at wave start. Towers fire at minions. Minions die.


### Phase 3 Milestones
Tower scene created with Area2D for range detection
VEX brain dictionary initialized (empty) at session start
vex_think() function runs at plan phase start
Towers placed at valid tower zone positions only
zoneCoverPath() verification prevents out-of-range placement
Towers fire at minions in range with correct damage
Minions have HP bar that depletes
Tower kills are logged to brain dictionary

⚠ WARNING: Area2D for tower range: use area_entered signal not body_entered — minions are Area2D not RigidBody2D.
⚠ WARNING: Tower targeting: do NOT use get_overlapping_bodies() in _process every frame. Use the entered/exited signals to maintain a local targets array. Pop dead targets on minion death signal.
```
# Tower target management — correct pattern
var targets_in_range = []

func _on_range_area_entered(area):
    if area is Minion:
        targets_in_range.append(area)

func _on_range_area_exited(area):
    targets_in_range.erase(area)

# In minion death handler:
Signals.minion_died.connect(_on_minion_died)
func _on_minion_died(minion):
    targets_in_range.erase(minion)
```


## Phase 4 — VEX Brain & Learning
--------------------------------------------------
Goal: VEX logs encounter data. Confidence ratings update. Tower selection changes based on history.


### Phase 4 Milestones
Brain logs new unit types on first sight (Shocked face triggers)
Confidence ratings update after each wave based on kill/breakthrough ratio
Tower selection changes when specific types dominate player's waves
Detection towers placed near damage towers (clustering verified)
AA towers placed near damage towers (clustering verified)
Brain saved to disk at session end (FileAccess.open with WRITE)
Brain loaded from disk at session start (FileAccess.open with READ)
New save = fresh brain (check file exists before loading)

⚠ WARNING: FileAccess paths: use "user://" prefix NOT "res://". "res://" is read-only in exported builds.
⚠ WARNING: store_var() / get_var() for Dictionary works but use JSON.stringify/parse for better cross-version compatibility.
```
# Correct brain persistence
const BRAIN_PATH = "user://vex_brain_slot%d.json"

func save_brain(slot: int) -> void:
    var file = FileAccess.open(BRAIN_PATH % slot, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(brain))
        file.close()

func load_brain(slot: int) -> void:
    if not FileAccess.file_exists(BRAIN_PATH % slot):
        brain = get_fresh_brain()  # new game
        return
    var file = FileAccess.open(BRAIN_PATH % slot, FileAccess.READ)
    if file:
        var result = JSON.parse_string(file.get_as_text())
        if result:
            brain = result
        file.close()
```


## Phase 5 — Spawner Locks & Research System
--------------------------------------------------
Goal: Player starts with Crawler only. Research UI exists. Unlocks cost Gold. New types become available.


### Phase 5 Milestones
Spawner OptionButton shows only UNLOCKED unit types
Research panel shows locked/unlocked state with costs
Purchasing research unlocks that unit type permanently for this session
Tier 2 units (Runner, Brute, Wraith, Skyborn) available at Wave 3+ for 200G
Tier 3 units available at Wave 5+ for 400G
Tier 4 fusions require both component types researched first
Evolution panel (between sessions) shows available evolutions and costs

⚠ WARNING: OptionButton items: removing/adding items during execution phase causes index errors. Disable the OptionButton instead of modifying it. Re-enable and repopulate in plan phase.


## Phase 6 — Procedural Path Growth
--------------------------------------------------
Goal: VEX expands the path one section per wave. New tower zones appear. Map grows.


### Phase 6 Milestones
GridSection scene created with TileMap and auto-flagging
VEX direction picker runs at wave end
Seed generates correct path section geometry connecting center-to-center
New section appends to existing map — path is continuous
New tower zones auto-flagged and added to VEX placement pool
Player sees new section at wave start (not during plan phase)
Shortcut sections occasionally generated — VEX cannot prevent this

⚠ WARNING: TileMap add_layer() at runtime can cause rendering issues. Pre-create all section TileMaps as children with visible=false, then show/populate them as sections are added. Do not add TileMap nodes dynamically.
⚠ WARNING: NavigationRegion2D must be rebaked when path changes. Call bake_navigation_polygon() after each section is added. This is expensive — do it at wave end not during execution.


## Phase 7 — Fog of War
--------------------------------------------------
Goal: VEX can only see areas within tower range. Stealth units in fog are completely invisible to VEX.


### Phase 7 Milestones
Fog overlay layer renders over full map
Tower range circles clear fog in their radius
VEX threat model only includes units where vis_state != CLOAKED
Stealth units in fog do not appear in VEX priority queue
Sensor Array tower type clears fog AND alerts VEX when stealth detected
Player can see fog state — knows VEX blind spots

⚠ WARNING: Fog of War implementation: use a CanvasLayer with a ShaderMaterial. Do NOT try to use TileMap tiles for fog — tile-based fog has 1-frame delay issues. Shader approach: render dark overlay, punch holes at tower positions using circle distance in fragment shader.


## Phase 8 — VEX Character & UI
--------------------------------------------------
Goal: VEX panel shows animated face, dialogue, upgrade log. Surrender UI works with sign and UNCLE button.


### Phase 8 Milestones
VEX body sprites assembled as layered TextureRect nodes
Face screen swaps texture on mood change with brief flicker animation
Dialogue system delivers word-by-word text
Difficulty accessory sprite shows correctly per difficulty
Surrender button opens modal
Sign sprite appears instantly on surrender click
UNCLE button flickers between Accept/UNCLE
UNCLE screen plays with full sequence
Sign hides instantly on Cancel — Angry face for 3 seconds

⚠ WARNING: AnimationPlayer for face flicker: keep it simple — 3-frame animation on Modulate alpha (1.0→0.0→1.0). Do not animate texture swaps directly in AnimationPlayer, set texture in code after flicker completes.
```
# Correct mood change pattern
func set_mood(mood: String) -> void:
    face_anim.play("flicker")      # 3-frame alpha animation
    await face_anim.animation_finished
    face_screen.texture = mood_textures[mood]  # swap after flicker
```


## Phase 9 — Wave Milestones & Boss Waves
--------------------------------------------------
Goal: Wave 10 = Boss wave. Player selects Boss. VEX prepares. Boss has special behaviour.


### Phase 9 Milestones
Boss selection UI appears at wave 10, 20, 30 etc.
Player choice is hidden from VEX until wave starts
VEX hedges tower selection for Boss wave (reserves budget)
Boss unit spawns with correct HP and special ability active
Gel Boss splits correctly through 4 tiers on death
VEX Shocked face on first Boss type encounter
VEX brain logs Boss type and cascade behaviour after first encounter


## Phase 10 — Permanent Progression & Byte-coins
--------------------------------------------------
Goal: Byte-coins earned at session end. Player upgrade screen between sessions. VEX auto-upgrades. Evolutions visible.


### Phase 10 Milestones
Session end screen shows Byte-coins earned breakdown
Player upgrade screen accessible from main menu
Purchasing upgrade updates permanent stats file
Next session loads permanent stats and applies modifiers
VEX Byte-coin balance persists in brain file
VEX auto-spends Byte-coins on upgrade tree based on what defeated it
Evolution panel shows available evolutions and visual preview


## Phase 11 — Merge System
--------------------------------------------------
Goal: VEX can merge Level 5 towers. Merged towers have combined effects. Sauron's Eye confusion arc works.


### Phase 11 Milestones
Tower Level 5 permanent upgrade unlocks merge flag
VEX merge logic identifies eligible adjacent tower pairs
Merge replaces two towers with one merged tower at midpoint position
Merged tower has combined stats and unique property
Sauron's Eye fires only at stealth units — verified with mixed wave
VEX research confidence system tests Sauron's Eye and logs result
VEX sells Sauron's Eye if no stealth seen for 3+ waves


## Phase 12 — Difficulty System & Polish
--------------------------------------------------
Goal: All 7 difficulty modes work. VEX behaviour correctly scales. Ultimate Mode triggers at wave 50.


### Phase 12 Milestones
Difficulty selection screen works
VEX budget, hedge percentage, and anticipation waves scale per difficulty
Easy: VEX makes visible mistakes, recovers slowly
Insane: VEX hedges perfectly, recognises bluff patterns
Hell: VEX has bonus tower stat multiplier
Wave 50 triggers Ultimate Mode announcement
VEX Cheat Mode triggers correctly on qualifying conditions
Punishment screen plays correctly after Cheat Mode loss
All opening monologues play per difficulty


======================================================================
# 8. Known Godot Gotchas — Read Before Building
======================================================================


These are confirmed errors and pitfalls from prior Godot development. Address them proactively.


## 8.1  Type System Errors
--------------------------------------------------
⚠ WARNING: get_class() returns a String and conflicts with built-in type checking. ALWAYS use the "is" keyword instead.
```
# WRONG
if node.get_class() == "Minion": ...
# CORRECT
if node is Minion: ...
```

⚠ WARNING: clamp() requires matching types. clamp(float_val, int, int) will cause type errors.
```
# WRONG
var clamped = clamp(my_float, 0, 100)
# CORRECT
var clamped = clamp(my_float, 0.0, 100.0)
```

⚠ WARNING: Constants must use UPPER_SNAKE_CASE. Lowercase constant names cause linter warnings that can mask real errors.
```
# WRONG
const tile_size = 32
# CORRECT
const TILE_SIZE = 32
```


## 8.2  Node & Scene Errors
--------------------------------------------------
⚠ WARNING: add_child() on nodes that are not yet in the scene tree causes errors. Use call_deferred("add_child", node) when adding children during _ready() or signal callbacks.
```
# WRONG
add_child(new_minion)  # during _ready() callbacks
# CORRECT
call_deferred("add_child", new_minion)
# OR
await get_tree().process_frame
add_child(new_minion)
```

⚠ WARNING: SAVE_PATH must use "user://" not "res://". "res://" is read-only in exported builds and will silently fail on save.
⚠ WARNING: Renamed nodes break NodePath references. If you rename a node in the editor, ALL @onready var references to it break silently.


## 8.3  Navigation Errors
--------------------------------------------------
⚠ WARNING: NavigationAgent2D requires its target to be set AFTER the navigation map is baked. Set target_position in _physics_process, not in _ready.
⚠ WARNING: NavigationRegion2D bake_navigation_polygon() is async — await it or use a signal before sending minions.
```
func _on_section_added() -> void:
    await nav_region.bake_navigation_polygon()
    # Now safe to spawn minions
```


## 8.4  Signal & Naming Errors
--------------------------------------------------
⚠ WARNING: Function named go_to() conflicts with Godot internal method. Use navigate_to() or move_to_target() instead.
⚠ WARNING: Audio stubs require all parameters even when creating empty AudioStreamPlayer nodes. Missing parameters cause null errors on play().
⚠ WARNING: Session dictionary must be initialized before access. Always use .get(key, default) instead of direct access on dictionaries that might not have the key.
```
# WRONG
var val = my_dict["key"]  # KeyError if missing
# CORRECT
var val = my_dict.get("key", default_value)
```


## 8.5  TileMap & Rendering Errors
--------------------------------------------------
⚠ WARNING: TileMap set_cell() uses layer index as first parameter in Godot 4. Forgetting the layer parameter silently places tiles on layer 0.
```
# WRONG (Godot 3 style)
tile_map.set_cell(x, y, tile_id)
# CORRECT (Godot 4)
tile_map.set_cell(layer_index, Vector2i(x, y), source_id, atlas_coords)
```
⚠ WARNING: CanvasLayer z_index for fog: set z_index on the CanvasLayer node itself, not on children. Children inherit parent CanvasLayer z ordering.


## 8.6  Performance Gotchas
--------------------------------------------------
⚠ WARNING: Never call get_overlapping_bodies() or get_overlapping_areas() in _process(). Cache the overlapping list using entered/exited signals.
⚠ WARNING: Avoid creating new Array or Dictionary objects in _process() every frame. Pre-allocate and reuse.
⚠ WARNING: Large minion counts (50+): use object pooling. Pre-instantiate 60 minion scenes at startup, activate/deactivate rather than instance/free during waves.
```
# Object pool pattern
var minion_pool = []
const POOL_SIZE = 60

func _ready():
    for i in POOL_SIZE:
        var m = MinionScene.instantiate()
        m.visible = false
        add_child(m)
        minion_pool.append(m)

func get_minion_from_pool() -> Minion:
    for m in minion_pool:
        if not m.visible:
            m.visible = true
            return m
    return null  # pool exhausted — increase POOL_SIZE
```


## 8.7  Missing Scene Constants
--------------------------------------------------
⚠ WARNING: Scene paths must be defined as constants or exported variables. Hard-coded strings like "res://scenes/Minion.tscn" break on refactor. Define all scene paths in a single GameConstants.gd autoload.
```
# GameConstants.gd (autoload)
extends Node

const SCENE_MINION_CRAWLER = preload("res://scenes/minions/Crawler.tscn")
const SCENE_MINION_RUNNER  = preload("res://scenes/minions/Runner.tscn")
const SCENE_TOWER_BOLT     = preload("res://scenes/towers/TowerBolt.tscn")
const SCENE_TOWER_BURST    = preload("res://scenes/towers/TowerBurst.tscn")
# etc. — ALL scene references live here
```


======================================================================
# 9. Claude Code Session Guide
======================================================================


This section tells Claude Code exactly what to do at the start of each session and what to avoid.


## 9.1  Audit-Before-Godot Workflow
--------------------------------------------------
This is mandatory. Every session starts with this workflow before writing any code.
READ this entire document before writing any code.
READ Section 8 (Known Godot Gotchas) specifically.
IDENTIFY which Phase is currently being implemented.
LIST the milestones for that Phase and verify which are complete.
ONLY then write code — one milestone at a time.
After each milestone: run headless test, verify output, commit.

⚠ WARNING: DO NOT skip the audit step. Hallucination-despite-documents errors occur when code is written without re-reading the current spec. The audit step prevents this.


## 9.2  Session Scope Rules
--------------------------------------------------
One Phase per session maximum. Do not bleed into the next Phase.
One milestone per commit. Smaller commits = easier rollback.
If a milestone fails testing: STOP. Do not proceed to next milestone.
If context window gets large (1500+ lines of code): start a new session with a fresh read of this document.
Never modify a working Phase to implement a later Phase feature. Isolate changes.


## 9.3  Testing Protocol Per Phase
--------------------------------------------------
```
# After each milestone, run this mental checklist:
# 1. Does the new feature work as designed?
# 2. Does the previous milestone still work? (regression check)
# 3. Are there any console errors or warnings?
# 4. Does the scene tree look correct in the editor?
# 5. If networking/saving involved: test fresh start AND load scenarios
```


## 9.4  What Claude Code Should Never Do
--------------------------------------------------
Never use get_class() — always use "is" keyword
Never hard-code scene paths as strings — use GameConstants.gd
Never add_child() during _ready() without call_deferred
Never call get_overlapping_bodies() in _process()
Never save to "res://" — always use "user://"
Never name functions go_to() — conflicts with Godot internals
Never skip the audit step at session start
Never implement two phases in one session


======================================================================
# 10. What Makes VEXILLUM Addictive — Design Principles
======================================================================


Synthesized from analysis of BTD6, Kingdom Rush, Legion TD 2, PvZ, Defense Grid, and game analytics research. These principles must be preserved in implementation.


## 10.1  The Core Addiction Loop
--------------------------------------------------
The most addictive TD games operate on a 3-layer satisfaction loop:
Immediate: watching minions move, seeing Gold tick up, hearing VEX react
Session: building toward unlocking a new unit type, surviving to wave 10
Long-term: permanent Byte-coin upgrades, VEX getting harder, rivalry deepening
ALL THREE LAYERS must be present from wave 1. If any layer is missing the player disengages.


## 10.2  The Distance Economy Is Critical
--------------------------------------------------
The single most important economic design decision: minions earn Gold for DISTANCE, not survival. This means:
Wave 1 total wipe = player still earned Gold = player not punished = player stays
Player always has SOMETHING to show for a wave even if they lost badly
Better minions = more distance = more Gold = positive feedback loop
VEX stopping units early = less Gold = player FEELS the counter
⚠ WARNING: If Gold only comes from reaching VEX base, early game is dead. The distance economy is non-negotiable.


## 10.3  VEX Must Feel Smart But Beatable
--------------------------------------------------
The most critical balance problem: if VEX is too easy the game is boring, if too hard it's unfair. The solution from research is not difficulty tuning — it's TRANSPARENCY of failure.
When VEX stops a wave, the player must understand WHY. Show kill feeds, damage numbers, which tower did what.
When player breaks through, VEX's reaction (face, dialogue, log entry) confirms the player outsmarted something real.
VEX making a mistake (selling wrong tower, bad path expansion) must be VISIBLE so player knows to exploit it.
Bluff meta: player must be able to SEE enough of VEX's build to plan a counter-bluff. VEX's towers are visible. VEX's budget is not.


## 10.4  Minion Unlock Pacing (Critical for Balance)
--------------------------------------------------
This is the single biggest fix from the HTML prototype. The unlock pacing must match VEX's ability to respond:


## 10.5  The "One More Wave" Hook
--------------------------------------------------
Every successful TD game has this: a reason to send one more wave even when the session is going poorly. In VEXILLUM this is built in structurally:
Failed wave = Gold earned from distance = can afford something new next wave
VEX makes a visible mistake = player wants to exploit it NOW
Wave 10 Boss selection approaching = player wants to reach it
VEX placed a weird tower = player wants to understand it
Surrender exists but costs VEX a trophy spot = player doesn't want VEX to win that easily
The UNCLE button must never feel like the obviously correct choice. It must always feel like giving up.


======================================================================
# 11. Spawner System — Corrected Design
======================================================================


IMPORTANT CORRECTION from prototype: Spawners are NOT per-wave unit pickers. They are permanent placed structures inside the player's Cave/Den that produce minions each wave automatically. This is a fundamental design difference that affects the entire player experience.


## 11.1  What Spawners Actually Are
--------------------------------------------------
A Spawner is a permanent structure the player places inside their Cave. Once placed, it produces a specific unit type every wave automatically. The player cannot change a placed Spawner's unit type — they must place a new Spawner for a different type.


## 11.2  The Cave / Den — Player's Build Space
--------------------------------------------------
The player operates from inside a Cave or Monster Den during the plan phase. This is their home base — a small interior space where they place and manage their Spawners. The Cave view is entirely separate from the battlefield map.


### Cave Layout
Cave is a fixed-size interior space — approximately 10x8 tiles in Godot.
Spawner slots are designated floor areas where Spawners can be placed (like tower zones, but inside the cave).
Maximum 5 Spawner slots available — some locked at game start, unlocked by spending Gold.
Player can also place minor support structures in the Cave (e.g. a Shrine that gives all minions +5% speed, a Forge that gives physical resistance, etc.) — these are the player's equivalent of VEX's Beacon tower.
Cave has a gate/door at one side — this is where minions exit when the wave is sent.


### What the Player Does During Plan Phase
Views their Cave interior — can see all placed Spawners and their types
Upgrades existing Spawners (tier 1→2→3 for more minions per wave)
Places new Spawners in empty slots (commits to a unit type permanently)
Researches new unit types (unlocks them for future Spawner placement)
Places/upgrades support structures
Waits for timer or clicks Send Wave
CANNOT see VEX's side of the map during this phase


### What the Player Sees During Wave Execution
View shifts to the BATTLEFIELD — the full top-down map
Player sees their minions emerge from the left side and walk toward VEX's base
Player sees VEX's towers, their range rings, projectiles firing
Player sees minions dying, Gold ticking up per distance
Player sees VEX's face reacting on the right panel
Player sees the path expanding (new section VEX added this wave is visible now)
Player CANNOT interact during execution — no placing, no upgrading, no changing

⚠ WARNING: The player must NOT be able to see VEX's tower placement during the plan phase. They can only observe what VEX built AFTER they send the wave. This is the core information asymmetry.


## 11.3  Spawner Placement Rules
--------------------------------------------------
```
# Spawner placement is permanent — expensive to undo
# SpawnerSlot.gd

var assigned_unit_type: String = ""  # empty = unoccupied
var tier: int = 1
var is_locked: bool = true  # start locked, unlock with Gold

# Placing a spawner COMMITS to that unit type
# Cannot change type — must remove and replace (costs Gold, loses some value)
func place_spawner(unit_type: String) -> void:
    if assigned_unit_type != "":
        push_error("Slot already occupied")
        return
    if not GameManager.is_unit_researched(unit_type):
        push_error("Unit type not yet researched")
        return
    assigned_unit_type = unit_type
    GameManager.deduct_gold(SPAWNER_PLACE_COST)
    _update_visual()

# Removing a spawner returns only 60% of placement cost
func remove_spawner() -> void:
    var refund = int(SPAWNER_PLACE_COST * 0.6)
    GameManager.add_gold(refund)
    assigned_unit_type = ""
    tier = 1
    _update_visual()
```


## 11.4  Spawner Upgrade Tiers — Revised
--------------------------------------------------


## 11.5  Cave Support Structures
--------------------------------------------------
These are the player's equivalent of VEX's Beacon tower. Small structures placed in the Cave that passively buff all outgoing minions. They cannot be placed in Spawner slots — they use separate support slots (2 available, unlock more with Byte-coins).


## 11.6  The Information Asymmetry — Complete Picture
--------------------------------------------------


======================================================================
# 12. Real Error History — Lessons from Fifth Sun & Hook Crook & Yarn
======================================================================


These are CONFIRMED errors that occurred in actual Claude Code sessions on prior Godot projects. They are documented here so Claude Code does not repeat them.


## 12.1  The Hallucination-Despite-Documents Problem (Fifth Sun — Critical)
--------------------------------------------------
During Fifth Sun Step 1, Claude Code confirmed reading all four reference documents, then proceeded to invent constants, field names, god names, and class structures that did not exist in any document. This happened on MULTIPLE files in the same session.
⚠ WARNING: Reading a document does NOT prevent hallucination. Claude Code will confirm it read the spec and still invent things. The audit-before-Godot workflow is the ONLY reliable prevention.


### Specific Files Where Hallucination Occurred (Fifth Sun)


### Prevention Protocol
After Claude Code writes ANY file: immediately audit it against this document before touching Godot.
Ask Claude Code explicitly: "Read the file you just wrote and list every constant, field name, and function name. Verify each one against the Build Bible."
Do NOT open Godot until Claude Code has audited and self-corrected.
Fix ALL errors in one commit — not one at a time.


## 12.2  Constant Naming Errors (Fifth Sun)
--------------------------------------------------
⚠ WARNING: Claude Code consistently uses lowercase or wrong-format constant names. GDScript requires UPPER_SNAKE_CASE for constants.
✅ TIP: Define ALL scene paths and constants in a single GameConstants.gd autoload. Never reference constants that were not explicitly defined in this Build Bible.


## 12.3  Piecemeal Error Fixing (Fifth Sun & Hook Crook & Yarn)
--------------------------------------------------
In both projects, the error pattern was identical: Claude Code would fix one error, create another, require another session, fix that one, etc. This spiral consumed many sessions and tokens.
⚠ WARNING: NEVER fix errors one at a time. Always gather ALL errors from Godot's output panel, paste them ALL to Claude Code at once, and fix in one commit.


### The Hook Crook & Yarn Pattern
Hook Crook & Yarn had a more severe version: Claude Code generated a structural shell with no actual working logic — panels existed but buttons did nothing, signals were not connected, data was not populated. Fixing surface syntax errors while the underlying architecture was wrong wasted the entire session.
⚠ WARNING: After each Phase milestone, verify BEHAVIOUR not just syntax. If a button exists but does nothing, the milestone is NOT complete. Do not proceed.


### Type Inference Error (Hook Crook & Yarn)
```
# Error that occurred in StitchGrid.gd:
# var lc := border_col   ← walrus operator cannot infer Color type

# Correct:
var lc: Color = border_col
lc.a = 0.45
```
⚠ WARNING: Avoid walrus operator := for Color, Vector2, or other non-primitive types. Explicit type annotation prevents this class of error entirely.


## 12.4  Unused Parameter Warnings Becoming Errors
--------------------------------------------------
In Fifth Sun, unused parameters in stub functions caused warnings that cascaded into errors in later steps because Claude Code then tried to "fix" warnings by deleting the parameters entirely, breaking function signatures.
```
# WRONG — causes warning then broken fix
func play_sfx(sound_key: String) -> void: pass

# CORRECT — prefix unused params with underscore
func play_sfx(_sound_key: String) -> void: pass
```
✅ TIP: ALL stub functions must prefix unused parameters with underscore from the moment they are written. Do not wait for warnings to appear.


## 12.5  Signal Connection Failures (Hook Crook & Yarn)
--------------------------------------------------
In Hook Crook & Yarn, Claude Code wrote signal connections in _ready() before the target nodes existed in the scene tree. The signals connected without errors (Godot does not throw on missing connections always) but never fired.
⚠ WARNING: Connect signals in _ready() ONLY after verifying the target node exists. Use @onready var to ensure nodes are ready before connecting.
```
# WRONG — target may not exist yet
func _ready():
    $Button.pressed.connect(_on_button_pressed)

# CORRECT
@onready var buy_btn = $BuyButton
func _ready():
    if buy_btn:
        buy_btn.pressed.connect(_on_buy_pressed)
    else:
        push_error("BuyButton not found in scene tree")
```


## 12.6  NavigationAgent2D Setup Errors (Fifth Sun)
--------------------------------------------------
In Fifth Sun, NavigationAgent2D was set up without NavigationRegion2D parent, causing silent navigation failures — units would appear to move but follow no actual path.
⚠ WARNING: NavigationAgent2D REQUIRES a NavigationRegion2D to exist in the scene. Without it, agents will silently fail to navigate. Always verify NavigationRegion2D exists AND is baked before testing unit movement.


## 12.7  VEXILLUM-Specific Error Prevention Rules
--------------------------------------------------
Based on all prior project experience, these rules are mandatory for this project:


======================================================================
# 13. The Cave — Complete Sub-Space Design
======================================================================


The Cave is a procedurally seeded interior space that serves as the player's home base between waves. It is a sub-scene — not a mini-game, but a distinct UI/environment the player inhabits during the plan phase. It replaces the spawner panel from the prototype entirely.


## 13.1  Cave Layout Rules
--------------------------------------------------
Cave is generated from a seed at the start of each session — different each run.
Cave size: 12x10 tiles minimum, scales slightly with wave count (cave "grows" as the faction gets stronger — cosmetic only, not mechanical).
Tiles types: FLOOR (placeable), WALL (boundary), ROCK (obstacle — impassable, decorative), PATH (connecting floor tiles).
The cave entrance is always on the LEFT edge center — this is where minions exit to the battlefield.
Spawner placement zones (FLOOR tiles) are seeded but always leave clear paths to the entrance.


### The Crystal Hearthstone — Fixed Center
The single non-seeded element. A 3x3 block Crystal always occupies the center of the Cave. It cannot be moved, built around within 1 tile, or removed. It is the faction's power source and the player's upgrade hub.
Visually distinct per faction theme — glowing blue gem (Fantasy), humming reactor core (Sci-Fi), pulsing soul stone (Horror), ancient tree heart (Nature), infernal ember (Hell)
Player clicks Crystal to open the Hearthstone Menu
Hearthstone Menu contains: Fusion Lab, General Upgrades, Evolution Chamber, Faction Abilities


## 13.2  Hearthstone Menu — Fusion Lab (Crystal Fusion System)
--------------------------------------------------
This is the player's equivalent of VEX's tower merge system. The player intentionally combines two existing unit types to create a new, more powerful Fusion unit. Unlike VEX's emergent discovery, the player knows the combinations — they just need to unlock the base units first.


### Fusion Flow
Player clicks Crystal Hearthstone
Hearthstone Menu opens — player selects "Fusion Lab" (Fantasy) / "Engineering Garage" (Sci-Fi) / "Dark Ritual" (Horror) / "Nature's Pact" (Nature) / "Hellforging" (Hell)
Fusion Lab shows 2 selector slots: [CREATURE 1] + [CREATURE 2]
Player can only select from units they have BOTH researched AND have an active Spawner for
When both slots filled, a preview shows the resulting Fusion unit
Player sees cost: both source Spawners are consumed (their lairs are removed from cave)
Player clicks "Begin Ritual" / "Initiate Fusion" / "Seal the Pact"
Both source lairs are removed. A new Fusion Lair appears in one of the original positions (randomly chosen).
Fusion unit is now available for that Spawner slot. Cannot be de-fused.

⚠ WARNING: Fusing removes both source Spawners permanently. Player loses those two unit types unless they research and place new Spawners for them. This is a significant strategic commitment.


## 13.3  Complete Fusion Table — Fantasy Theme
--------------------------------------------------


## 13.4  Complete Fusion Table — Sci-Fi Theme
--------------------------------------------------


## 13.5  Complete Fusion Table — Horror Theme
--------------------------------------------------


## 13.6  Cave Spawner Visual — Themed Structures
--------------------------------------------------
Each unit type has a corresponding themed lair structure in the cave. When a Spawner is placed, a themed building/structure appears on that tile.


## 13.7  Cave Scene — Godot Implementation Notes
--------------------------------------------------
```
# Cave.tscn scene structure
Cave (Node2D)
├── TileMap (ground, walls, rocks — seeded)
├── Crystal (StaticBody2D — center 3x3, always present)
│   └── HearthstoneMenu (Control — popup on click)
│       ├── FusionLab (Control)
│       ├── GeneralUpgrades (Control)
│       ├── EvolutionChamber (Control)
│       └── FactionAbilities (Control)
├── SpawnerContainer (Node2D)
│   └── SpawnerSlot (x5 max — placed on FLOOR tiles)
├── SupportContainer (Node2D)
│   └── SupportSlot (x2 — separate from spawner slots)
├── CaveEntrance (Area2D — left edge, triggers wave send)
└── WavePanel (Control — timer, send button, wave info)
```

⚠ WARNING: Cave scene is a SEPARATE scene from Battlefield. Scene transition on "Send Wave": Cave → Battlefield. Transition back on wave end: Battlefield → Cave. Use SceneManager for this, not get_tree().change_scene_to_file() directly.
```
# Cave → Battlefield transition
func _on_send_wave_pressed() -> void:
    GameManager.commit_wave_composition()  # lock in spawner state
    SceneManager.go_to("res://scenes/Battlefield.tscn")

# Battlefield → Cave transition (called at wave end)
func _on_wave_complete() -> void:
    GameManager.process_wave_results()
    SceneManager.go_to("res://scenes/Cave.tscn")
```


## 13.8  Cave Scene — Phaser/JS Implementation Notes
--------------------------------------------------
In the Phaser version, the Cave is a Phaser Scene using tilemaps for the grid. The cave layout is stored as a JSON object in IndexedDB.
```
// cave_state structure in IndexedDB:
const caveState = {
    seed: 12345,
    tiles: [[...], [...], ...],  // 12x10 grid of tile types
    crystalPos: {x: 5, y: 4},   // always center
    spawnerSlots: [
        {id: 0, pos: {x:2, y:2}, unitType: "crawler", tier: 1,
         upgrades: {size:{level:1}, speed:{level:0}, hp:{level:0}, armor:{level:0}}},
        {id: 1, pos: {x:2, y:7}, unitType: "brute",   tier: 2,
         upgrades: {size:{level:2}, speed:{level:1}, hp:{level:0}, armor:{level:0}}},
        {id: 2, pos: null, unitType: null, tier: 0}  // empty slot
    ],
    supportSlots: [
        {id: 0, pos: {x:9, y:5}, structure: "war_drum"},
        {id: 1, pos: null, structure: null}
    ]
};

// CaveScene.js - Phaser Scene
class CaveScene extends Phaser.Scene {
    create() {
        this.caveMap = this.make.tilemap({key: "cave_tiles"});
        this.spawnerGroup = this.add.group();
        this.loadStateFromDB();
        this.createCrystal();
        this.setupInputHandlers();
    }

    async loadStateFromDB() {
        const state = await Storage.loadCaveState(GameState.saveSlot);
        this.renderFromState(state);
    }
}
```


======================================================================
# 14. Platform-Specific Build Guides
======================================================================


VEXILLUM can be built in two ways simultaneously. Use this section to direct the correct AI tool to the correct build approach. The two builds share the same game design (all of Sections 1-13 apply to both) but differ in technology stack, implementation patterns, and capability limits.

IMPORTANT: Direct your AI tool to the correct section below before starting any build work.


## 14.1  ═══ GODOT BUILD — Claude Code ═══
--------------------------------------------------
Use this section when building in Godot 4.x with Claude Code.


### Godot Scene Architecture
```
res://
├── scenes/
│   ├── Cave.tscn          # Plan phase — player's home
│   ├── Battlefield.tscn   # Execute phase — the TD map
│   ├── MainMenu.tscn
│   ├── SessionEnd.tscn
│   ├── minions/
│   │   ├── Crawler.tscn
│   │   ├── Brute.tscn
│   │   └── [all unit types]
│   ├── towers/
│   │   ├── TowerBolt.tscn
│   │   └── [all tower types]
│   └── ui/
│       ├── VEXPanel.tscn
│       ├── FusionLab.tscn
│       └── HearthstoneMenu.tscn
├── scripts/
│   ├── autoloads/
│   │   ├── GameManager.gd    # Central state
│   │   ├── GameConstants.gd  # ALL constants and scene paths
│   │   ├── SceneManager.gd   # Scene transitions
│   │   ├── VEXBrain.gd       # AI brain — persists to disk
│   │   └── AudioManager.gd   # Stub initially
│   ├── cave/
│   │   ├── Cave.gd
│   │   ├── CaveGenerator.gd
│   │   ├── Crystal.gd
│   │   └── SpawnerSlot.gd
│   ├── battlefield/
│   │   ├── Battlefield.gd
│   │   ├── GridSystem.gd
│   │   ├── VEXController.gd
│   │   └── PathManager.gd
│   └── minions/
│       ├── Minion.gd         # Base class
│       └── [unit type scripts]
└── data/
    ├── units.json            # Unit stats — read at startup
    ├── towers.json           # Tower stats
    └── fusions.json          # Fusion combinations table
```


### Godot Build Order — Phases 1-12
Follow Sections 7, 8, 9 of this document exactly. Phases 1-12 as documented. Key Godot-specific rules:
Read Section 8 (Known Godot Gotchas) before every session.
Read Section 12 (Real Error History) before every session.
Audit-before-Godot workflow is mandatory — see Section 9.
One Phase per session. One milestone per commit.
ALL scene paths defined in GameConstants.gd — never hardcoded.
ALL constants UPPER_SNAKE_CASE.
ALL stub parameters prefixed with underscore.
Use "is" keyword not get_class() for type checking.


### Godot Testing Protocol
```
# After each milestone in Godot:
# 1. F5 to run
# 2. Check Output panel — zero errors AND zero warnings
# 3. Test the BEHAVIOUR of the milestone (not just that it runs)
# 4. Test that previous milestones still work (regression)
# 5. Only then commit

# If errors appear: copy ALL errors at once to Claude Code
# Do NOT fix one at a time — fix in one pass
```


### Godot Capability Notes
Godot CAN do: full visual cave with TileMap, animated VEX sprite, NavigationAgent2D pathfinding, shader-based fog of war, smooth scene transitions, proper save/load, audio.
Godot CANNOT easily do in early phases: complex shader effects, 3D elements, real-time multiplayer.
Aim for: clean 2D top-down, readable unit shapes, functional VEX face, working fog.


## 14.2  ═══ REPLIT BUILD — Python/JSON ═══
--------------------------------------------------
Use this section when building in Replit with Phaser.js. Recommended by Replit itself as the best fit for browser-native 2D TD games.


### Phaser.js Project Structure
```
vexillum/
├── index.html             # Entry point — loads Phaser
├── package.json           # phaser, idb
├── data/
│   ├── units.json         # Unit definitions and stats
│   ├── towers.json        # Tower definitions
│   ├── fusions.json       # Fusion combination table
│   └── difficulty.json    # Difficulty settings
├── src/
│   ├── main.js            # Phaser game config, scene registration
│   ├── scenes/
│   │   ├── CaveScene.js   # Plan phase — player home base
│   │   ├── BattleScene.js # Execute phase — the TD map
│   │   ├── UIScene.js     # Overlay — VEX panel, stats, UNCLE button
│   │   └── MenuScene.js   # Main menu, difficulty select
│   ├── vex/
│   │   ├── VEXBrain.js    # Brain dictionary, priority queue
│   │   ├── VEXWorker.js   # Web Worker — heavy AI analysis
│   │   └── VEXFace.js     # Face system, dialogue queue
│   ├── cave/
│   │   ├── CaveGenerator.js  # Seeded cave layout
│   │   ├── Spawner.js        # Spawner placement and upgrade
│   │   └── Crystal.js        # Hearthstone menu, fusion
│   ├── map/
│   │   ├── SectionGrid.js    # 31x31 section, path validation
│   │   ├── PathManager.js    # Waypoint array, expansion
│   │   └── TowerPlacer.js    # Placement scoring, validation
│   ├── minions/
│   │   └── Minion.js         # Base class, all unit types
│   ├── economy/
│   │   └── Economy.js        # Gold, Byte-coins, research costs
│   └── storage/
│       └── Storage.js        # IndexedDB via idb wrapper
```


### Scene Sleep/Wake Pattern — Cave ↔ Battlefield
Both scenes stay alive in memory the entire session. Shared state lives in a single global GameState object both scenes read from. Never rebuild scenes from scratch on transition.
```
// main.js — scene registration
const config = {
    type: Phaser.AUTO,
    scene: [MenuScene, CaveScene, BattleScene, UIScene]
};

// Cave → Battlefield (player hits Send Wave)
class CaveScene extends Phaser.Scene {
    sendWave() {
        GameState.commitWaveComposition(); // lock spawner state
        this.scene.sleep("CaveScene");
        this.scene.wake("BattleScene");
        this.scene.wake("UIScene");
    }
}

// Battlefield → Cave (wave ends)
class BattleScene extends Phaser.Scene {
    onWaveComplete() {
        GameState.processWaveResults();
        // VEX heavy thinking starts NOW in Web Worker
        // Player goes to cave while VEX plans
        vexBrain.startBetweenWaveAnalysis();
        this.scene.sleep("BattleScene");
        this.scene.wake("CaveScene");
    }
}
```


### VEX Web Worker Pattern
```
// VEXWorker.js — runs off main thread
self.onmessage = function(e) {
    const snapshot = e.data;
    const result = {
        placements: calculateOptimalPlacements(snapshot),
        expansionDirection: scoreExpansionDirections(snapshot),
        doctrineUpdates: recalculateWeights(snapshot),
        dialogueTrigger: buildDialogueTrigger(snapshot)
    };
    self.postMessage(result);
};

// VEXBrain.js — main thread
startBetweenWaveAnalysis() {
    const snapshot = this.buildDecisionSnapshot(); // lightweight
    const worker = new Worker("VEXWorker.js");
    worker.onmessage = (e) => {
        this.applyWorkerResult(e.data); // applies placements etc
        this.saveToIndexedDB();         // persist updated brain
    };
    worker.postMessage(snapshot);
    // Cave scene is running — player is planning — zero jank
}
```


### IndexedDB Storage
```
// Storage.js — idb wrapper
import { openDB } from "idb";

const DB_NAME = "vexillum";
const DB_VERSION = 1;

async function getDB() {
    return openDB(DB_NAME, DB_VERSION, {
        upgrade(db) {
            db.createObjectStore("vex_brain");   // VEX memory per save
            db.createObjectStore("progression"); // Byte-coins, unlocks
            db.createObjectStore("cave_state");  // Spawner placements
        }
    });
}

export async function saveVEXBrain(slotId, brain) {
    const db = await getDB();
    await db.put("vex_brain", brain, `slot_${slotId}`);
}

export async function loadVEXBrain(slotId) {
    const db = await getDB();
    return await db.get("vex_brain", `slot_${slotId}`) || freshBrain();
}
```


### Waypoint Path System
```
// PathManager.js
class PathManager {
    constructor() {
        this.waypoints = []; // appended each wave
    }

    addSection(section) {
        // Append new waypoints from section path tiles
        const newWaypoints = section.pathTiles.map(t => ({
            x: t.worldX,
            y: t.worldY
        }));
        this.waypoints.push(...newWaypoints);
        // Existing mid-wave minions finish current path
        // New wave minions use full extended waypoints
    }

    getNextWaypoint(minion) {
        if (minion.waypointIndex >= this.waypoints.length) {
            return null; // reached VEX base
        }
        return this.waypoints[minion.waypointIndex];
    }
}
```


### Combat AI — 300ms Interval
```
// BattleScene.js — VEX reactive loop during combat
create() {
    // Event-driven — fires immediately on trigger
    EventBus.on("minion_reached_base",  this.onBreachEvent, this);
    EventBus.on("tower_destroyed",      this.onTowerLost, this);
    EventBus.on("new_unit_type_seen",   this.onNewUnitType, this);
    EventBus.on("aoe_hit_8_plus",       this.onAoESmug, this);

    // Interval monitoring — lightweight only
    this.time.addEvent({
        delay: 300,
        callback: this.vexMonitorTick,
        callbackScope: this,
        loop: true
    });
}

vexMonitorTick() {
    // ONLY lightweight checks — no weight updates, no doctrine
    const densities = this.countMinionsPerSection();
    const anomaly   = this.checkAccessoryAnomaly();
    if (anomaly) EventBus.emit("accessory_anomaly_detected", anomaly);
    // That is ALL that runs here
}
```


### Replit/Phaser Build Order
The Replit build follows the same Phase structure as Godot but in Phaser.js. Phase numbers match for cross-reference.


### Phaser-Specific Warnings
⚠ WARNING: Crystal Hearthstone is the PLAYER's upgrade hub. V.E.X. is the enemy on the east side of the battlefield. Do NOT put VEX inside the Cave scene.
⚠ WARNING: Scene Sleep/Wake not Scene Stop/Start. scene.stop() destroys the scene. scene.sleep() preserves it. Always use sleep/wake for Cave↔Battlefield transitions.
⚠ WARNING: IndexedDB NOT localStorage. localStorage has 5MB limit and blocks main thread. Use idb library from day one.
⚠ WARNING: Web Worker cannot access Phaser directly. Worker receives snapshot, returns decision payload. Main thread applies the result. Never pass Phaser objects to Worker.
⚠ WARNING: Waypoint array only — no EasyStar.js. Path is structured and predictable. Appending waypoints per wave is all that is needed.
⚠ WARNING: VEX heavy analysis runs ONLY during Cave phase. Never run weight recalculation or doctrine updates during combat. Combat = lightweight reactive only.


## 14.3  Comparing the Two Builds
--------------------------------------------------


======================================================================
# 15. Map Geometry — Confirmed Rules
======================================================================


These rules were confirmed visually via spreadsheet mockups. They are non-negotiable constraints that the path generator, tower placement system, and VEX AI must all respect.


## 15.1  Section Grid
--------------------------------------------------
Every section is 31x31 tiles. Not 30x30. 31 gives a clean center at tile 16,16.
Edge midpoints: North=(16,1), South=(16,31), East=(31,16), West=(1,16)
All path sections connect center-to-center of adjacent edges — guaranteed geometric connectivity.
Blue tiles = VEX tower placement zone. Red tiles = path. These are mutually exclusive.
Once a section is generated and placed it NEVER changes. Permanent.
```
const SECTION_SIZE = 31
const CENTER = 16  // 1-indexed
const EDGE_MIDPOINTS = {
    north: {x:16, y:1},
    south: {x:16, y:31},
    east:  {x:31, y:16},
    west:  {x:1,  y:16}
}
```


## 15.2  Tower Footprint — 3x3 Grid
--------------------------------------------------
A tower occupies a 3x3 tile footprint. The center tile (2,2) is the tower itself. The outer 8 tiles are its buffer zone. Nothing else may occupy the buffer zone.
```
// Tower footprint visualization:
// [B][B][B]
// [B][T][B]
// [B][B][B]
// B = buffer (exclusive to this tower)
// T = tower center
```


### Tower Spacing Rules
Tower buffer zones CANNOT overlap another tower's buffer zone.
Tower buffer zones CAN overlap a path's buffer zone.
Minimum distance between two tower centers: 3 tiles (buffers share edge, never overlap).
```
// Two towers side by side — VALID (buffers share edge):
// [B][B][B][B][B][B]
// [B][T][B][B][T][B]
// [B][B][B][B][B][B]

// Two towers diagonal — VALID if no B overlaps:
// [B][B][B]
// [B][T][B]
// [B][B][B][B][B][B]
//          [B][T][B]
//          [B][B][B]
```


## 15.3  Path Buffer Rules
--------------------------------------------------
Path tiles have a directional buffer. The buffer applies to the SIDES of the path (perpendicular to direction of travel). Front and back of path connect directly to adjacent path tiles.
Path buffer zones CANNOT overlap another path's buffer zone.
Minimum tiles between two parallel path segments: 2 tiles (one buffer each side, cannot overlap).
Tower buffer CAN overlap path buffer — this is how towers sit adjacent to roads.
```
// Path going east, buffers on north and south sides:
// [path buffer — 1 tile]
// [■][■][■][■][■]  ← path tiles going east
// [path buffer — 1 tile]

// Two parallel eastward paths — minimum valid gap:
// [■][■][■][■][■]   ← path 1
// [path1 buffer]     ← 1 tile
// [path2 buffer]     ← 1 tile  (buffers touch, cannot overlap)
// [■][■][■][■][■]   ← path 2
```


## 15.4  U-Turn Gap — The Sweet Spot
--------------------------------------------------
A U-turn with minimum gap between legs creates the highest-value tower placement on any map. One tower centered in the gap covers BOTH path legs simultaneously.
```
// Valid U-turn — 2 tile gap between legs:
// [■][■][■][■][■][■]   ← going east
// [■]
// [■]         [T]       ← tower centered, equal distance both legs
// [■]
// [■][■][■][■][■][■]   ← coming back west

// Tower is valid because:
// - 3x3 footprint clear of all path tiles
// - Buffer overlaps both path buffers (allowed)
// - Radius covers both path legs

// NOT valid — tower off-center:
// [■][■][■][■][■][■]
// [■]         [T]       ← too close to top path, buffer overlaps
// [■]
// [■][■][■][■][■][■]
```
⚠ WARNING: U-turn placement MUST be centered with equal clearance to both legs. Off-center = buffer overlaps one path = invalid.


## 15.5  Tower Placement Validation — Complete Rules
--------------------------------------------------
```
function isValidTowerPlacement(centerX, centerY, pathTiles, existingTowers) {

    // Rule 1: Tower 3x3 footprint must not contain any path tile
    for (let dx = -1; dx <= 1; dx++) {
        for (let dy = -1; dy <= 1; dy++) {
            if (isPathTile(centerX + dx, centerY + dy)) return false;
        }
    }

    // Rule 2: No existing tower 3x3 may overlap this tower 3x3
    // Centers must be at least 3 apart in BOTH x and y
    for (const t of existingTowers) {
        if (Math.abs(t.x - centerX) < 3 && Math.abs(t.y - centerY) < 3) {
            return false; // 3x3 grids overlap
        }
    }

    // Rule 3: Tower radius must cover at least one path tile
    const coversPath = pathTiles.some(p =>
        distance(centerX, centerY, p.x, p.y) <= towerRange
    );
    if (!coversPath) return false;

    // All rules pass
    return true;
}
```


## 15.6  Tower Placement Scoring
--------------------------------------------------
```
function scoreTowerPlacement(centerX, centerY, pathTiles, existingTowers, towerRange) {

    // Hard gate first
    if (!isValidTowerPlacement(centerX, centerY, pathTiles, existingTowers))
        return -Infinity;

    let score = 0;

    // Score 1: Path tiles covered
    const covered = pathTiles.filter(p =>
        distance(centerX, centerY, p.x, p.y) <= towerRange
    );
    score += covered.length * 2;

    // Score 2: Distinct path segments covered (U-turn = 2 segments)
    const segments = countDistinctSegments(covered);
    score += segments * 15;  // big bonus

    // Score 3: U-turn gap detection — jackpot placement
    if (isUTurnGap(centerX, centerY, pathTiles)) score += 40;

    // Score 4: Overlap with existing towers (combo coverage)
    const overlapping = existingTowers.filter(t =>
        distance(centerX, centerY, t.x, t.y) <= (towerRange + t.range)
    );
    score += overlapping.length * 10;

    // Score 5: Proximity to path center (not edge clip)
    const avgDist = covered.reduce((s, p) =>
        s + distance(centerX, centerY, p.x, p.y), 0
    ) / covered.length;
    score += (towerRange - avgDist) * 3;

    return score;
}
```


## 15.7  Section Expansion System
--------------------------------------------------
VEX expands the map by adding new 31x31 sections. His base section shifts in the chosen direction. All expansion happens before the wave starts — player sees the result when they exit the Cave.


### Expansion Rules
VEX picks direction: North, South, OR East. West is always the player's entry direction — never expanded.
New 31x31 section generated from random seed. Seed controls internal path geometry only. Entry and exit points are fixed at edge midpoints.
VEX base section shifts 31 tiles in chosen direction (30 for new section + 1 alignment gap).
New section connects to existing section at matching edge midpoints.
Once placed, section is permanent — never regenerates.
Expansion frequency: every 2-5 waves early game, scaling toward wave 50.


### Dead End Navigation
At any junction, a minion has 2-4 possible directions. Dead end detection is trivial:
```
function getNextDirection(currentTile, cameFromDir) {
    const neighbors = getConnectedNeighbors(currentTile);
    const valid = neighbors.filter(n =>
        n.direction !== cameFromDir &&  // not where we came from
        n.hasConnectedSection           // section exists in this direction
    );
    // Always exactly one valid direction remains
    return valid[0];
}
```
No pathfinding algorithm needed. No A*. No NavMesh. One valid direction always exists.
Minions follow waypoint array appended per wave. Existing mid-wave minions finish current path. Next wave uses extended path.


### VEX Expansion Scoring
```
// VEX picks direction that maximises path length added
// Higher difficulty = smarter direction choice
function scoreExpansionDirection(direction, currentMap) {
    const estimatedLength = estimatePathLengthGain(direction, currentMap);
    const existingCoverage = calculateTowerCoverage(currentMap);
    // Longer path = more tower placement real estate
    // More coverage gaps = prioritise filling them
    return estimatedLength * 2 + (1 - existingCoverage) * 15;
}

// Easy: random direction
// Normal: weighted random (prefers longer gain)
// Hard+: always picks highest score
```


## 15.8  Path Generation — Validation Rules
--------------------------------------------------
The seed generates internal path geometry between fixed entry and exit points. Generated paths must pass all validation rules. Invalid paths regenerate with next seed.
Path must never cross itself (no tile appears twice).
No two non-sequential path tiles within 2 tiles of each other (parallel path buffer rule).
U-turns are valid but return leg must end further from entry than where it turned (net forward progress maintained).
Path must connect entry midpoint to exit midpoint.
Estimated rejection rate: 10-15% of seeds. Max 3 regeneration attempts before using simple straight path as fallback.
```
function validatePath(pathTiles, entryPoint, exitPoint) {
    // Rule 1: No duplicate tiles
    const unique = new Set(pathTiles.map(t => `${t.x},${t.y}`));
    if (unique.size !== pathTiles.length) return false;

    // Rule 2: No non-sequential tiles within 2 tiles of each other
    for (let i = 0; i < pathTiles.length; i++) {
        for (let j = i + 3; j < pathTiles.length; j++) {
            const dx = Math.abs(pathTiles[i].x - pathTiles[j].x);
            const dy = Math.abs(pathTiles[i].y - pathTiles[j].y);
            if (dx + dy <= 2) return false;
        }
    }

    // Rule 3: Ends at exit midpoint
    const last = pathTiles[pathTiles.length - 1];
    if (distance(last.x, last.y, exitPoint.x, exitPoint.y) > 1) return false;

    return true;
}
```


## 15.9  VEX Decision Snapshot — Web Worker Handoff
--------------------------------------------------
VEX's heavy thinking runs during the Cave phase as a Web Worker. The main thread assembles a lightweight decision snapshot from the brain — never passes the full brain. Worker returns a decision payload. Main thread applies it.
```
// What main thread sends TO Worker:
const snapshot = {
    waveNumber: 14,
    difficulty: "Challenging",
    personality: "Conservative",
    budget: 820,
    availableTowers: [...],
    battlefield: {
        sections: [...],         // array of section objects
        existingTowers: [{id:1, type:"bolt", x:8, y:14, hp:80}],
        validPlacements: [...]   // pre-computed valid 3x3 positions
    },
    threatProfile: {
        sectionHeatmap: {        // which sections see most minion traffic
            "section_1": 0.8,
            "section_2": 0.4
        },
        creatureThreatRatings: {"brute": 0.9, "goblin": 0.4},
        breakthroughHistory: [{wave:12, type:"brute"}, {wave:13, type:"brute"}]
    },
    doctrineWeights: {
        prioritizeSlowVsBrute: 0.8,
        savingsThreshold: 400    // Conservative: save until can afford this
    },
    accessoryAnomalyFlags: ["water_weakness_suspected"]
};

// What Worker returns:
const result = {
    placements: [
        {gridX:8, gridY:6, towerType:"bolt"},
        {gridX:14, gridY:6, towerType:"chill"}
    ],
    repairPriorities: [
        {towerId:3, urgency:"high"}
    ],
    budgetReserve: 200,
    expansionDirection: "north",
    doctrineUpdates: {
        prioritizeSlowVsBrute: 0.85
    },
    dialogueTrigger: {
        key: "anomaly_water_noticed",
        delay: 4000
    }
};
```
⚠ WARNING: Worker only receives pre-computed validPlacements array. It never independently calculates valid positions — that runs on main thread before snapshot assembly. Worker picks FROM the valid list, never generates positions.


## 15.10  AI Timing Split — Complete Specification
--------------------------------------------------


======================================================================
# 16. Document Changelog
======================================================================


| System | HTML Prototype Status | Godot Implementation Status |
| --- | --- | --- |
| Core game loop | ✅ Working | ❌ Not started |
| Path traversal | ✅ Working | ❌ Not started |
| VEX tower placement | ⚠ Partially working — AI too easy | ❌ Not started |
| VEX brain / memory | ⚠ Basic version only | ❌ Not started |
| Gold economy | ✅ Working | ❌ Not started |
| Spawner system | ⚠ No lock — player picks any unit immediately | ❌ Not started |
| Minion types | ⚠ 4 types, no unlocks, no evolution | ❌ Not started |
| Tower types | ⚠ 5 types, no upgrades shown to player | ❌ Not started |
| Fog of war | ❌ Not implemented | ❌ Not started |
| Procedural path growth | ❌ Not implemented | ❌ Not started |
| Grid system | ❌ Not implemented | ❌ Not started |
| Surrender / UNCLE UI | ✅ Working | ❌ Not started |
| VEX character / face | ⚠ CSS sprites only | ❌ Not started |
| Wave milestone system | ❌ Not implemented | ❌ Not started |
| Byte-coins / permanent progression | ❌ Not implemented | ❌ Not started |
| Merge system | ❌ Not implemented | ❌ Not started |
| Evolution system | ❌ Not implemented | ❌ Not started |
| Faction themes | ❌ Not implemented | ❌ Not started |
| Cosmetic set bonuses | ❌ Not implemented | ❌ Not started |


| Unit | HP | Speed | Special | Gold/Tile | Counter | Unlock |
| --- | --- | --- | --- | --- | --- | --- |
| Crawler | 20 | Medium | None. Pure baseline. | 0.2 | Any single-target | Default — wave 1 |


| Unit | HP | Speed | Special Ability | Gold/Tile | Hard Counter | Godot Flag |
| --- | --- | --- | --- | --- | --- | --- |
| Runner | 25 | Fast (1.8x) | Gains +20% speed when below 40% HP (panic run) | 0.35 | Rapid-fire Bolt tower | is_runner |
| Brute | 200 | Slow (0.5x) | Physical resistance: takes 40% less from Bolt/Burst. Magic/elemental full damage. | 1.8 | Ember DoT or magic tower | is_tank, phys_resist:0.4 |
| Wraith | 35 | Medium | Cloaks 0.8s after last hit. Revealed by Detection towers or AoE splash. | 0.7 | Detection + damage cluster | is_stealth, cloak_delay:0.8 |
| Skyborn | 40 | Medium-fast | Flies — ignores ground path, bypasses all ground-only towers. Needs AA counter. | 0.6 | AA tower (Sky/Skywatcher) | is_flying |


| Unit | HP | Speed | Special Ability | Gold/Tile | Hard Counter |
| --- | --- | --- | --- | --- | --- |
| Splitter | 80 | Medium | On death: splits into 3 Crawlers. Crawlers inherit 30% remaining HP. Chain-splits if Crawlers also die fast. | 0.9 | High burst single-shot to trigger split in kill zone, then AoE for spawns |
| Mender | 30 | Medium-slow | Heals adjacent minions for 8 HP/sec. Priority kill target — VEX towers will retarget to Mender when detected. | 0.5 | Priority-targeting tower (retarget upgrade) |
| Revenant | 60 | Medium | Regenerates 5 HP/sec when not taking damage. Must be killed in one sustained burst — slow towers are useless. | 0.8 | DoT tower or rapid-fire Bolt |
| Juggernaut | 350 | Very slow (0.35x) | Immune to slow effects. Knocks back towers within 2 tiles on death (visual only). Cannot be killed in one hit — requires minimum 3 hits. | 2.5 | Multiple high-damage towers overlapping |


| Fusion | Components | Combined Stats | Unique Ability | Cost to Deploy |
| --- | --- | --- | --- | --- |
| Phantom | Wraith + Skyborn | HP:50, Speed: Fast | Flies AND cloaks. Requires Detection tower with AA capability or is completely invisible. Rarest and most expensive counter to build. | 150G/slot/wave |
| Titan | Brute + Juggernaut | HP:600, Speed: Crawl | Physical AND slow immunity. Takes full damage only from Fire/Magic/Electric. Shrugs off every standard tower type. | 200G/slot/wave |
| Cascade | Splitter + Revenant | HP:120, Speed: Medium | Splits on death AND each split regenerates. Forces VEX to sustain massive AoE damage or be flooded with regenerating micro-units. | 175G/slot/wave |
| Warden | Mender + Revenant | HP:80, Speed: Slow | Heals others AND self-regenerates. If not killed fast, entire wave becomes unkillable. VEX must prioritize immediately. | 160G/slot/wave |


| Base Unit | Evolution 1 (50 Byte-coins) | Evolution 2 (150 Byte-coins) | Evolution 3 (400 Byte-coins) |
| --- | --- | --- | --- |
| Crawler | Scuttler: +30% speed, +15 HP | Ravager: gains Splitter-lite (splits into 1 Crawler on death) | Swarm Lord: spawns 2 Crawlers at path start when deployed |
| Runner | Dasher: panic run triggers at 60% HP | Blur: 3-second speed burst on spawn, untargetable during burst | Phase Runner: brief stealth window on spawn (2 seconds) |
| Brute | Iron Brute: resistance increases to 55% | Siege Brute: destroys 1 tower zone tile on death (path widens) | Dreadnought: immune to all CC effects including slow |
| Wraith | Deep Shade: cloak delay drops to 0.4s | Void Walker: Detection towers have 50% reduced effectiveness | Null Shade: completely invisible — requires Tier 2 Detection tower to reveal |
| Skyborn | Stormwing: +25% speed, smaller hitbox | Galeforce: immune to AA slow effects | Hurricane: AoE wind on death — briefly disrupts nearby projectiles |


| Boss Name | Unlock Wave | Base Stats | Ability | Cascade Effect |
| --- | --- | --- | --- | --- |
| The Gel | Wave 10 | HP:400, Slow speed | Splitter: 1→4→8→16 cascade on each tier death | Tier 4 are pure Crawlers. First encounter VEX treats as Tank. Shocked face guaranteed. |
| The Veil | Wave 10 | HP:300, Medium speed | Massive stealth aura: makes all nearby friendly units cloak simultaneously for 5s | VEX Detection towers reveal Veil but not buffed units unless range overlaps all of them |
| Iron Colossus | Wave 20 | HP:1200, Very slow | Physical + Slow immunity. Tower knockback on death (visual). Triggers VEX emergency response. | VEX Cheat Mode chance increases 20% if Colossus reaches base threshold |
| Storm Queen | Wave 20 | HP:500, Fast flying | Flies. Summons 4 Skyborn units mid-path. | Forces VEX to split AA attention between Boss and spawned units simultaneously |
| The Undying | Wave 30 | HP:800, Medium | Regenerates 40 HP/sec. Must sustain 1200+ DPS to overcome regen. Below that threshold it heals faster than damage dealt. | VEX must either upgrade existing DoT towers or deploy multiple high-rate towers. Single tower inadequate. |
| CHAOS FORM | Wave 50 — Ultimate Mode only | HP:3000, Variable speed | Randomly shifts between all Boss archetypes every 30 seconds. No single counter works for full duration. | VEX must have full mixed coverage. Player must have full mixed sending. Both sides at maximum. |


| Tower | Base DMG | Range | Fire Rate | Hits Air | Hits Stealth | Type | Cost |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Bolt | 12 | 80 | 1.2/s | No | No | Single-target | 40G |
| Burst | 8 | 65 | 0.8/s | No | No | AoE splash, 70% range radius | 55G |
| Volley | 6 | 60 | 2.5/s | No | No | Rapid single-target | 45G |
| Chill | 4 | 70 | 1.0/s | No | No | Single, applies 1.5s slow (40% speed) | 45G |
| Ember | 3/s DoT | 55 | Continuous | No | No | DoT aura — damages all in range per second | 50G |
| Skywatcher | 10 | 90 | 1.0/s | Yes | No | AA only — ignores ground units | 60G |
| Lantern | 3 | 100 | 0.8/s | Yes | Yes | Reveals stealth. AoE. Hits air and ground | 50G |
| Beacon | 0 | 80 | N/A | No | No | Buff: +20% damage to all towers in range | 55G |
| Sauron's Eye | 8/s DoT | 90 | Continuous | No | Yes (ONLY) | Stealth specialist. Ignores all visible units completely. | Merge only |
| Barrier | 0 | N/A | N/A | No | No | Slows path traversal 30% for units passing through zone | 35G |
| Overcharge | 300 burst | 120 | 30s cooldown | Yes | Yes | Ultimate nuke. Massive AoE. Long cooldown. | Upgrade only |


| Tier | Cost | Stat Change | New Effect |
| --- | --- | --- | --- |
| Base → Tier 2 | 50G | +30% damage, +10% range | None |
| Tier 2 → Tier 3 | 120G | +50% damage total, +20% range total, +15% fire rate | Unique secondary effect unlocked per tower type (see below) |


| Level | Byte-coin Cost | Effect |
| --- | --- | --- |
| 1 | 20 | +10% base damage for this tower type permanently |
| 2 | 40 | +15% range permanently |
| 3 | 80 | Unique passive ability unlocked (see table below) |
| 4 | 150 | +20% fire rate permanently |
| 5 | 300 | Merge eligibility unlocked — can now merge with one other Level 5 tower type |


| Tower | Level 3 Passive |
| --- | --- |
| Bolt | First Hit: first shot on any new unit always crits for 2x damage |
| Burst | Aftershock: AoE triggers a 50% smaller secondary splash 0.5s later at same location |
| Volley | Suppression: units hit by Volley have 15% reduced speed for 1 second |
| Chill | Brittle: slowed units take +25% damage from all sources |
| Ember | Spreading Flame: fire DoT spreads to adjacent units (chains once) |
| Skywatcher | Lock On: Skywatcher pre-targets next air unit while current projectile is mid-flight |
| Lantern | Mark: revealed units take +30% damage for 3 seconds after reveal |
| Beacon | Resonance: Beacon buff stacks additively with second Beacon in range (max 2 stacks) |


| Tower A | Tower B | Result Name | Combined Effect | Unique Property |
| --- | --- | --- | --- | --- |
| Chill | Bolt | Frost Sniper | Damage + slow on every hit. Long range. | Slowed targets highlighted — other towers prioritize them |
| Chill | Ember | Frostburn | Slow + DoT simultaneously. Contradictory elements = bonus damage. | +50% damage to slowed targets from Ember component |
| Burst | Ember | Inferno Ring | AoE + sustained fire field at blast point. | Fire field lasts 4 seconds. Multiple units caught over time. |
| Bolt | Volley | Gatling | High damage + high fire rate. Single target destroyer. | Unlocks priority targeting — can be set to focus highest HP unit |
| Lantern | Ember | Sauron's Eye | Detection + Fire DoT. STEALTH UNITS ONLY. Ignores all visible units. | Massive DoT on revealed units. Completely ignores visible units (see design note in GDD) |
| Lantern | Chill | Cryo Scanner | Detection + instant slow on reveal. Revealed units frozen 1.2s. | Frozen units are fully revealed for duration even after damage tick |
| Skywatcher | Burst | Storm Battery | AA + chain lightning between nearby air units. | Chain hits up to 3 additional air units per shot |
| Skywatcher | Chill | Icewind Battery | AA + slow. Grounded Flyers drop to ground layer temporarily (3 seconds). | Grounded Flyers become targetable by all ground towers during grounded state |
| Beacon | Burst | War Drum | AoE damage + massive buff aura. Both simultaneously. | Damages while buffing nearby towers. Beacon effect doubles. |
| Bolt | Skywatcher | Dual Cannon | Hits ground AND air. Switches target priority automatically. | Only merged tower that naturally handles both layers without AA-only limitation |


| Event | Gold Earned | Notes |
| --- | --- | --- |
| Minion travels 1 tile | Base rate × unit Gold multiplier | Crawler: 0.2G/tile. Tank: 1.8G/tile. Scales with unit value. |
| Minion reaches VEX base | +50% bonus on remaining distance value | Surviving the full path pays significantly more |
| Wave completion (any outcome) | +20G flat | Ensures minimum progression even on total wipe |
| Boss wave completion | +100G | Win or lose — milestone bonus |
| VEX Cheat Mode survived | +500G + unique unlock | Exceptional reward for exceptional play |


| Purchase | Cost | Notes |
| --- | --- | --- |
| Activate Spawner slot | 10-30G per wave (scales with tier) | Ongoing operational cost per wave per active slot |
| Unlock 2nd Spawner slot | 100G once | Permanent for this session |
| Unlock 3rd-5th Spawner slot | 200G / 350G / 500G | Each slot costs progressively more |
| Upgrade Spawner tier 1→2 | 150G | 5→10 minions per wave |
| Upgrade Spawner tier 2→3 | 400G | 10→20 minions per wave |
| Research new unit type | 200-400G depending on tier | Permanent for session — unlocks that minion type for assignment |
| Deploy Boss (milestone wave) | 100-200G depending on Boss type | One-time deployment cost at milestone waves |


| Event | Player Earns | VEX Earns |
| --- | --- | --- |
| Session win (destroy VEX base) | 50 + wave reached × 3 | 0 (VEX lost) |
| Session loss (player base destroyed) | 5 + wave reached | 30 + wave reached × 2 |
| Surrender (UNCLE) | 5 flat | 20 flat — VEX counts this as a win |
| Reaching wave 10 | 15 | 10 |
| Reaching wave 20 | 25 | 15 |
| Reaching wave 50 (Ultimate Mode) | 100 | 100 — both sides get rewarded for this |
| Defeating VEX after Cheat Mode | 200 + unique cosmetic unlock | 0 |
| VEX Cheat Mode — player loses | 15 consolation — does not count as loss | 50 |


| Upgrade | Cost | Effect |
| --- | --- | --- |
| Crawler Speed I-III | 20/50/100 | +5/10/15% permanent speed to all Crawlers |
| Brute Resilience I-III | 30/70/150 | +10/20/35% permanent HP to all Brutes |
| Wraith Depth I-II | 40/100 | Cloak delay drops to 0.6s / 0.3s permanently |
| Skyborn Altitude I | 50 | Flyers ignore Tier 1 AA towers permanently |
| Splitter Cascade I | 80 | Splitter starts at Tier 2 (splits into 4 not 3) permanently |
| Mender Potency I-II | 40/90 | Mender heals +4 HP/sec / +8 HP/sec permanently |
| Boss Budget I | 100 | All Boss deployment costs reduced 20% |
| Research Discount I | 150 | All session research costs reduced 15% |
| Spawner Efficiency I | 120 | Spawner slot operational costs reduced 20% |
| Evolution Unlock: Runner | 50 | Unlocks Runner Evolution path |
| Evolution Unlock: Brute | 50 | Unlocks Brute Evolution path |
| Evolution Unlock: Wraith | 50 | Unlocks Wraith Evolution path |


| Wave Range | Player Can Use | VEX Counter Available | Tension Source |
| --- | --- | --- | --- |
| 1-2 | Crawler only | Basic Bolt, Burst | Can VEX kill all Crawlers? Usually yes. Player earns distance Gold. |
| 3-4 | + Runner or Brute or Wraith or Skyborn (one at a time, 200G each) | + Chill (anti-Runner), Ember (anti-Brute), Lantern (anti-Wraith), Skywatcher (anti-Skyborn) | Player chooses which unlock. VEX hasn't seen chosen type yet — advantage window. |
| 5-7 | + Splitter, Mender, Revenant, Juggernaut | + Burst upgraded (anti-Splitter), priority targeting (anti-Mender) | VEX has memory of early types. Player mixes types to split attention. |
| 8-9 | + Fusion units available | VEX upgrades existing towers. Budget higher. Merges begin. | Fusion units hard-counter VEX's single-type specialisation. |
| 10 | Boss selection available | VEX hedges for Boss wave. Which Boss does player pick? | Information asymmetry at its maximum. VEX knows a Boss comes. Player knows which one. |


| Aspect | WRONG (Prototype) | CORRECT (Design) |
| --- | --- | --- |
| Assignment | Player picks unit type from dropdown each wave | Player places Spawner structure permanently — type is fixed at placement |
| Flexibility | Player can change type every single wave | Player must plan ahead — wrong Spawner is expensive to replace |
| Economy | No cost to change type | Placing a new Spawner costs Gold. Removing one wastes the placement cost. |
| Strategy | React to VEX every wave freely | Commit to a composition. Adapt by adding new Spawners, not changing existing ones. |
| Visibility | Player sees full UI at all times | Player is inside the Cave during plan phase — cannot see VEX's side at all |


| Tier | Minions Per Wave | Upgrade Cost | Visual in Cave |
| --- | --- | --- | --- |
| 1 — Den | 5 | Free (placement cost only) | Small structure, single creature icon |
| 2 — Warren | 10 | 150G | Medium structure, reinforced with bones/stone |
| 3 — Hive | 20 | 400G | Large structure, glowing with energy |
| 4 — Nest | 35 | 800G — requires research unlock | Massive structure, dominant in cave |
| 5 — Lair | 50 | 1500G — requires Byte-coin upgrade first | Takes up 2 slot spaces, legendary appearance |


| Structure | Effect | Cost | Unlock |
| --- | --- | --- | --- |
| War Drum | All minions +10% speed | 200G | Wave 3 |
| Blood Altar | All minions +15% HP | 300G | Wave 5 |
| Stealth Shrine | Stealth units cloak 0.3s faster | 250G | After researching Wraith |
| Sky Totem | Flyers +20% speed | 250G | After researching Skyborn |
| Forge | Brutes/Juggernauts +10% physical resistance | 350G | After researching Brute |
| Mending Pool | Menders heal +5 HP/sec additional | 300G | After researching Mender |


| What | Player Knows | VEX Knows |
| --- | --- | --- |
| Their own Spawners | Exactly — they placed them | Only what it observes during wave execution |
| VEX's towers | Only during wave execution (battlefield view) | Exactly — it placed them |
| VEX's new path section | Only during wave execution (battlefield view) | Which direction it picked — not the seed geometry |
| Which Boss player picked | Exactly — player chose it | Only that a Boss wave is coming — not which type |
| VEX's budget | Never | Exactly |
| Player's Gold | Exactly | Never |
| VEX's brain/doctrine | Never directly — only inferred from observing tower placement patterns over multiple waves | Its own data — fully |
| Player's research unlocks | Exactly | Only types it has seen deployed — never what the player has researched but not yet used |


| File | What Claude Code Invented | What Was Actually Correct |
| --- | --- | --- |
| lore_data.gd | Wrong gods: Chalchiuhtlicue, Mictlantecuhtli, Tezcatlipoca as candidates. Invented fields. Wrong class names. | Eight specific gods listed in Lore Bible. Exact field names from GDD. |
| game_config.gd | TILE_SIZE (wrong), MISSION_TIMER=300 (wrong), QUEST_POINTS=3 (wrong) | TILE_SIZE_PX, MISSION_TIMER=90, QUEST_POINTS=10 |
| game_state.gd | Wrong structure: resources/hub/quests/skills | Correct: inventory/progression/meta/mission |
| save_system.gd | Referenced GameConfig.SAVE_FILE_PATH (does not exist) | Path is a const inside save_system.gd itself: const SAVE_PATH = "user://..." |
| scene_manager.gd | Referenced GameConfig.SCENE_* constants (do not exist). Called go_to_scene() (wrong name). Wrote to GameState.session.* (does not exist). | No SCENE_ constants in GameConfig. Method is go_to(). No session dict. |
| main.gd | TILE_SIZE, MAP_WIDTH, GameState.resources, GameConfig.SAVE_FILE_PATH, LoreData.gods (lowercase) | TILE_SIZE_PX, GRID_SIZE_START, correct path, LoreData.GODS (uppercase) |


| Wrong (Claude Code Wrote) | Correct | Error It Caused |
| --- | --- | --- |
| TILE_SIZE | TILE_SIZE_PX | Undefined constant error |
| MAP_WIDTH | GRID_SIZE_START | Undefined constant error |
| LoreData.gods | LoreData.GODS | Undefined member error |
| LoreData.classes | LoreData.CLASSES | Undefined member error |
| RecipeData.recipes | RecipeData.RECIPES | Undefined member error |
| GameConfig.SAVE_FILE_PATH | Does not exist — use string literal | Undefined member error |
| GameConfig.SCENE_MAIN | Does not exist — use GameConstants.gd | Undefined member error |


| Rule | Reason | How to Enforce |
| --- | --- | --- |
| ALL scene paths in GameConstants.gd only | Fifth Sun: invented scene constants that didn't exist | Audit step: verify every scene reference points to GameConstants.gd |
| ALL constants UPPER_SNAKE_CASE | Fifth Sun: lowercase constants caused undefined errors | Audit step: grep for lowercase const declarations |
| ALL stub function params prefixed with _ | Fifth Sun: warnings became broken fixes | Write stubs correctly from day one |
| NO walrus operator := for non-primitives | Hook Crook: Color type inference failure | Use explicit type annotation always |
| Signals connected with null-check | Hook Crook: silent signal failures | Always check node exists before connect() |
| Navigation baked before wave send | Fifth Sun: silent navigation failure | await bake_navigation_polygon() before spawning minions |
| No add_child() in _ready() without call_deferred | Documented Godot gotcha | Audit step: grep for add_child in _ready functions |
| Save paths always user:// | Fifth Sun: res:// fails in export | Audit step: grep for res:// in any FileAccess.open call |
| Verify BEHAVIOUR not just syntax after each milestone | Hook Crook: structural shell with no working logic | Each milestone checklist item includes a behaviour test, not just "file exists" |


| Unit 1 | Unit 2 | Fusion Result | Abilities Gained | Lore Note |
| --- | --- | --- | --- | --- |
| Eagle | Lion | Gryphon | Flies (Eagle) + Physical resistance (Lion) + Claw strike AoE on landing | Noble guardian — flies above ground towers, tanks hits that reach it |
| Giant Bat | Basilisk | Dragon | Flies + Petrify gaze (brief freeze on targets in path) + Fire breath DoT aura | The apex predator. Slow but devastating. |
| Wolf | Goblin | Warg Rider | Fast (Wolf) + Rider throws spears (ranged harass on towers — doesn't damage but delays targeting) | First unit to interact with towers rather than just running past |
| Troll | Shaman | Hex Troll | Regeneration (Troll) + Heals nearby units (Shaman) + Curse aura: towers in range fire 15% slower | Support bruiser — makes everything around it harder to kill |
| Goblin | Spider | Spider Jockey | Swarmer speed + Web shot (applies slow to tower target lock — tower briefly re-targets after hit) | Disrupts tower priority targeting |
| Phantom | Wraith | Void Walker | Double stealth depth + Phases through barrier-type towers + Heals 5HP/sec while invisible | Near-unkillable if not countered perfectly |


| Unit 1 | Unit 2 | Fusion Result | Abilities Gained | Flavor |
| --- | --- | --- | --- | --- |
| Soldier | Jeep | Tank | High HP + Physical resistance + Shells deal AoE damage to nearby tower range circles (visual disruption) | Engineering Garage: "Weld the bazooka to the hood, obviously." |
| Combat Drone | Hover Disc | UFO | Flies + Stealth scanner jammer (Detection towers have 50% reduced effectiveness in range) + Beam attack on arrival at base | DNA Lab: "Unexpected emergent property of the disc's EM field." |
| Speed Bot | Laser Drone | Raider Mech | Fast + Ranged harass (fires at towers while moving — doesn't damage but delays fire) + Evasion: 20% chance to dodge single-target shots | "It shoots back. That's new." |
| Nanite Swarm | Repair Bot | Adaptive Swarm | Splits (Nanite) + Self-repairs (Repair Bot) + Adapts: gains 10% resistance to whatever tower type kills it first | "It learns from being shot. VEX finds this unsettling." |
| EMP Unit | Gunship | Carrier | Flies + On death: EMP burst stuns all towers in 100px radius for 2 seconds | "The explosion is the whole point." |


| Unit 1 | Unit 2 | Fusion Result | Abilities Gained | Flavor |
| --- | --- | --- | --- | --- |
| Zombie | Ghost | Revenant | Regenerates (Zombie) + Stealth (Ghost) + On death: possesses nearest tower for 3 seconds (tower stops firing) | Bone Altar: "The soul refuses to leave the machine." |
| Vampire | Werewolf | Nosferatu | Flies (bat form) + Fast (wolf speed) + Drains 5HP/sec from towers it passes (reduces their effective range briefly) | "Neither fully one thing nor the other. Both at their worst." |
| Lich | Skeleton Horde | Death Knight | Summons 4 skeletons mid-path (Splitter-lite) + Physical immunity + Aura: undead units in range reanimate once on death | "One death knight. Infinite inconvenience." |
| Banshee | Abomination | Wailing Hulk | Scream AoE (brief stun ALL towers in 80px radius, 4s cooldown) + Massive HP + Regen | "The scream is on a cooldown. The HP is not." |


| Unit Type | Fantasy Lair | Sci-Fi Lair | Horror Lair |
| --- | --- | --- | --- |
| Crawler/Basic | Mushroom burrow | Maintenance hatch | Bone pit |
| Runner/Fast | Wolf den | Speed track loop | Shadow pool |
| Brute/Tank | Stone giant's seat | Armored bay | Abomination vat |
| Wraith/Stealth | Mist shrine | Cloaking emitter | Ghost well |
| Skyborn/Flyer | Eyrie nest | Launch pad | Bat cave |
| Splitter | Spider egg clutch | Nanobot cannister | Slime pool |
| Mender/Healer | Shaman's hut | Repair station | Necromancer altar |
| Fusion unit | Ritual circle | Fusion chamber | Dark ritual stone |
| Boss | Throne platform | Command module | Death throne |


| CLAUDE CODE: Read this section only for Godot builds |
| --- |
| Technology Stack Engine: Godot 4.x Language: GDScript Scenes: .tscn files with Node-based architecture Save system: JSON via FileAccess to user:// directory Navigation: NavigationAgent2D + NavigationRegion2D Rendering: TileMapLayer for grid, CanvasLayer for fog, Sprite2D for VEX |


| REPLIT AI: Read this section only for Replit builds |
| --- |
| Technology Stack Framework: Phaser.js 3 (browser-native, no export step needed) Language: JavaScript (ES6+) Scenes: Phaser Scene system with Sleep/Wake pattern Storage: IndexedDB via idb wrapper library (NOT localStorage — 5MB limit) AI heavy thinking: Web Worker (off main thread, zero frame drops) Path: Waypoint array appended per wave — no EasyStar needed Data: JSON files for units/towers/fusions/difficulty loaded at startup |


| Phase | Phaser Focus | Milestone Test |
| --- | --- | --- |
| 1 | Phaser game boots. CaveScene loads. 31x31 grid renders from seed. Blue/red tiles visible. | Open browser — cave grid visible. Console zero errors. Tiles correct colors. |
| 2 | Spawner placement UI. Click floor tile → spawner appears. Upgrade tracks work. Crystal clickable. | Place spawner → structure appears. Upgrade → count increases. Crystal opens menu. |
| 3 | Send Wave → CaveScene sleeps, BattleScene wakes. Minions spawn and follow waypoints. Gold ticks up. | Hit Send Wave → battlefield visible → minions walk path → Gold increments per tile. |
| 4 | VEXBrain initializes. Web Worker runs between-wave analysis. Tower placement changes wave 2 vs wave 1. | Send same unit type 3 waves. Console log shows Worker result. Tower positions differ by wave 3. |
| 5 | Research system. Only unlocked types show in spawner selector. Research purchase works. | Start with Crawler only. Buy Runner → appears in dropdown. IndexedDB persists on refresh. |
| 6 | Section expansion. VEX picks direction. New 31x31 section appended. Waypoints extended. Path grows. | Send wave → BattleScene shows longer path. New section visible. Minions walk full extended path. |
| 7 | Crystal Hearthstone. Fusion flow. Two spawners consumed → fusion spawner appears. | Place two compatible spawners → Crystal → select both → fuse → new fusion lair appears. |
| 8 | VEX panel. UIScene overlay. Face texture swaps. Word-by-word dialogue. UNCLE flow complete. | Wave outcome → VEX face changes. Surrender → modal → sign appears → UNCLE sequence plays. |
| 9 | IndexedDB persistence. Byte-coins save/load. VEX brain persists. Upgrade screen between sessions. | Win session → Byte-coins awarded. Refresh browser → brain loaded → VEX remembers previous waves. |


| Aspect | Godot (Claude Code) | Replit (Python/JS) |
| --- | --- | --- |
| Visual quality | Higher — TileMap, sprites, shaders | Lower — Canvas shapes, CSS |
| Cave experience | Immersive 2D interior scene | Functional grid with click placement |
| VEX character | Animated sprite with face swap | CSS emoji/image swap — simpler |
| Wave simulation | Real-time in engine | Server-side tick simulation, polled |
| Export/distribution | Standalone executable | Web app — browser-based |
| Development speed | Slower — engine complexity | Faster — Python is fast to iterate |
| Token burn risk | Higher — Godot context is large | Lower — Python context smaller |
| Platform | Windows/Mac/Linux executable | Browser — instantly shareable URL |
| VEX brain fidelity | Full GDScript implementation | Full JavaScript implementation — identical logic |
| Best for | Final polished game | Rapid prototyping, early validation, instant browser sharing |


| Phase | VEX Does | Interval | Notes |
| --- | --- | --- | --- |
| Combat — reactive | Threshold checks only: AoE fired on 8+ units, minion reached base, tower destroyed, new unit type seen | Event-driven — fires immediately on trigger | Zero calculation. Just threshold compare and face/dialogue change. |
| Combat — monitoring | Count minions per section, check tower idle status, aggregate damage tracking, accessory anomaly check | Every 300ms | Lightweight. Never updates weights or doctrine during combat. |
| Wave end → Cave transition | Full weight recalculation, confidence updates, bluff pattern analysis, doctrine revision, dialogue queue pre-load | One-shot on wave-end event. Async via Web Worker. | Runs while player is in Cave. Player never sees delay. |
| Cave phase | Tower placement decisions, budget allocation, upgrade priority, expansion direction, repair priority | Web Worker — parallel to Cave scene rendering | Results ready before player hits Send Wave. |


| Version | Date | Changes |
| --- | --- | --- |
| 1.0 | Session 1 | Initial build bible: core loop, enemy taxonomy (10 archetypes), tower taxonomy (12 types), VEX AI architecture, grid system, economy, build phases 1-12, Godot gotchas, Claude Code session guide, addiction design principles |
| 1.1 | Session 1 | Added: Spawner system corrected design (permanent placement not per-wave picker), Cave/Den view, information asymmetry table, real error history from Fifth Sun (hallucination-despite-documents, constant naming, piecemeal fixing) and Hook Crook & Yarn (signal failures, type inference, structural shell problem) |
| 1.2 | Session 1 | Added: Cave zone system (Battle/Farm/Bazaar), Crystal Hearthstone design, fusion tables for Fantasy/Sci-Fi/Horror, cave spawner visual structures, platform build guides, Phaser.js Replit section replacing Python/Flask, Web Worker AI architecture, IndexedDB specification, spawner upgrade tracks JSON structure |
| 1.3 | Session 1 | Added: 31x31 section geometry confirmed with visual mockups, tower 3x3 footprint/buffer rules with code, path directional buffer rules, U-turn gap placement as highest-value position, section expansion system with dead-end navigation, path validation algorithm, VEX decision snapshot / Web Worker handoff structure, AI timing split specification (event-driven vs 300ms vs one-shot), minion tower attack system, spawner tier progression 5→10→20→35→50 with four upgrade tracks, colony sim cave zones (Farm/Bazaar aesthetic hooks), Replit section updated to Phaser.js with Scene Sleep/Wake pattern |
