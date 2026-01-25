# Sword of Vermilion - Game Systems Documentation

This document provides detailed information about the game's core systems for map loading, NPC spawning, treasure chests, and enemy encounters.

---

## Table of Contents
1. [Map System](#map-system)
2. [NPC & Entity System](#npc--entity-system)
3. [Treasure & Reward System](#treasure--reward-system)
4. [Enemy Encounter System](#enemy-encounter-system)
5. [Town & Building System](#town--building-system)

---

## Map System

### Map Decompression (RLE Format)

**Function**: loc_0000633C (Line 6363)

The game uses a custom RLE (Run-Length Encoding) compression for map data.

Algorithm:
- Read byte A
- If A < $80: Output byte A directly
- If A >= $80: Read next byte B, output byte B repeated ($80 - A) times
- Repeat until complete

**Map Tile Values**:
- $00 = Ground (walkable)
- $01 = Tree (obstacle)
- $02 = Rock (obstacle)
- $05 = Cave rock
- $0F = House
- $8x = Entrance to town number x
- $1x = Entrance to cave number x
- $FF = Cave exit

### Map Loading Functions

**Cave Map Loading**: loc_0000622A (Line 6261)
- Fills entire map with cave rocks ($05)
- Then decompresses specific cave layout
- Uses Current_cave_room to select data

**Overworld Map Loading**: loc_0000626C (Line 6282)
- Loads 9 map sectors (3x3 grid) around player
- Each sector is 16x16 tiles
- Uses Player_map_sector_x/y coordinates

**Helper Functions**:
- LoadMapSectorIfInBounds (Line 6340)
- loc_00006328 (Line 6349)

### Map Data Tables

**Cave Maps**: CaveMaps (Line 47898)
- 44 cave map pointers
- Each points to RLE-compressed layout

**Overworld Maps**: OverworldMaps (Line 47368)
- 128 overworld sector pointers (8x16 grid)
- Each sector is 16x16 tiles, RLE-compressed

### Map Memory Layout

Nine decompressed sectors in RAM:

- $FFFF9000 = Map_sector_top_left
- $FFFF9100 = Map_sector_top_center
- $FFFF9200 = Map_sector_top_right
- $FFFF9310 = Map_sector_center (current)
- $FFFF9400 = Map_sector_middle_right
- $FFFF9500 = Map_sector_bottom_left
- $FFFF9600 = Map_sector_bottom_center
- $FFFF9700 = Map_sector_bottom_right
- $FFFF9800 = Map_sector_middle_left

Each sector: 256 bytes (16x16 tiles).

---

## NPC & Entity System

### NPC Loading

**Main Function**: loc_00006E1C (Line 7088)
- Loads up to 29 ($1D) NPCs per town
- Reads from Town_npc_data_ptr ($FFFFC15E)
- Initializes objects at Object_slot_base ($FFFFD000)
- Each object slot: 46 ($2E) bytes

### NPC Data Formats

The game uses TWO different NPC data formats:

#### Format 1: Building Room NPCs (Simple - 10 bytes)

Used for NPCs inside building rooms.

Structure per NPC:
- Word 0: X position in room
- Word 1: Y position in room
- Word 2: Facing direction
- Long 3: Behavior script pointer
- Terminator: $FFFF

Direction values: 1=Up, 2=Left, 4=Down, 6=Right, 8=?, $F=Any

Example (loc_000200F6, Line 34605):
  dc.w $0004, $0001, $0001, $0002
  dc.l loc_000203DA
  dc.w $FFFF

#### Format 2: Town Map NPCs (Complex - 36 bytes)

Used for NPCs on town outdoor maps.

Structure per NPC (36 bytes):
- +0  (word): Building index
- +2  (word): Room index
- +4  (word): X position (pixels)
- +6  (word): Y position (pixels)
- +8  (long): Unknown flags/data
- +12 (word): Sprite/entity type ID
- +14 (word): Direction/animation flags
- +16 (long): Primary behavior script pointer
- +20 (word): Secondary X position
- +22 (word): Secondary Y position
- +24 (word): Movement parameters
- +26 (long): Secondary script pointer
- +30 (6 bytes): Padding/unknown

Terminator: $FF $FF

### Town NPC Setup

**Setup Scripts**: loc_0001FECA (Line 34398)
- 16 town entries
- Each sets Town_npc_data_ptr based on story flags

**Data Pointers**: loc_0001FDD4 (Line 34300)
- 16 pointers to NPC data per town

Towns dynamically change NPCs based on story progression.

---

## Treasure & Reward System

### Treasure Types

Reward_script_type ($FFFFC570):
- 0 = Item treasure (Herbs, Keys, etc.)
- 1 = Equipment treasure (Weapons, Armor, Shields)
- 3 = Money treasure (Kims/Gold)

### Setup Functions

**loc_0002141E** (Line 35850): Item treasure setup
**SetupEquipmentTreasure** (Line 35854): Equipment setup
**InitMoneyTreasure** (Line 35858): Money setup

### Initialization Pattern

Example - 50 Kims chest:
  MOVE.w #$50, $FFFFC572.w        ; Amount
  MOVE.l #$FFFFC798, $FFFFC574.w ; Flag address
  BSR.w  InitMoneyTreasure
  RTS

### Key RAM Addresses

- Reward_script_type = $FFFFC570
- Reward_script_value = $FFFFC572 (item ID or money amount)
- Reward_script_flag = $FFFFC574 (pointer to opened flag)
- Reward_script_active = $FFFFC56C (FF = active)
- Reward_script_available = $FFFFC56F (FF = not opened)

### Treasure Flags

Range: $FFFFC780 - $FFFFC820+
- Each flag: 1 byte
- $00 = Not opened
- $FF = Already taken

Notable chests:
- $FFFFC789 = Bronze Sword (equipment ID 0)
- $FFFFC798 = 50 Kims chest (outside Wyclif)
- $FFFFC7BA = 1700 Kims chest
- $FFFFC7BC = 9999 Kims chest

### Enemy Drops

**Function**: loc_0002145A (Line 35871)
- Uses Enemy_reward_type ($FFFFC57A)
- Uses Enemy_reward_value ($FFFFC57C)
- Sets up reward after battle victory

---

## Enemy Encounter System

### Encounter Mapping

**Overworld**: EnemyEncounterTypesByMapSector (Line 37780)
- 128 bytes (one per sector)
- Each byte = encounter group index

**Caves**: EnemyEncounterTypesByCaveRoom (Line 37791)
- 44 bytes (one per cave)
- Each byte = encounter group index

### Encounter Groups

**Table**: loc_00023C40 (Line 37867)

Each group: 4 possible encounter types (8 bytes):
  dc.w $0001  ; Type 1
  dc.w $0002  ; Type 2
  dc.w $0003  ; Type 3
  dc.w $0004  ; Type 4

Game randomly selects one type when battle triggers.

### Encounter Checking

**Function**: CheckForEncounter (Line 3031)
- Increments step counter
- Compares vs Encounter_rate threshold
- Triggers battle when exceeded

### Battle Spawn Positions

**Table**: EnemyStartingPositions (Line 12499)

8 (X,Y) coordinate pairs for enemy placement:
  dc.w $0078, $005A
  dc.w $00B8, $005A
  dc.w $0098, $0046
  dc.w $0098, $006E
  dc.w $0060, $0046
  dc.w $0060, $006E
  dc.w $00D0, $0046
  dc.w $00D0, $006E

---

## Town & Building System

### Town Tables

**Tileset Index**: loc_0001FC88 (Line 34198)
- 16 entries (one per town)
- Values: 0, 1, or 2 (tileset type)
- Town 11 (Swaffham): tileset 2 if ruined

**Spawn Positions**: loc_0001FD54 (Line 34283)
- 16 entries (8 bytes each)

Format per town:
  dc.w Player_spawn_X
  dc.w Player_spawn_Y
  dc.w Camera_X_tile
  dc.w Camera_Y_tile

Example (Town 0):
  dc.w $00D8, $02B8, $0003, $001F
  ; Spawn at (216, 696), camera at tile (3, 31)

### Building System

Towns organized hierarchically:
  Town (0-15)
    -> Building (0-N)
        -> Room (0-N)
            -> NPCs (Format 1)

---

## Key Constants

### Map System
- Current_cave_room = $FFFFC556
- Is_in_cave = $FFFFC551
- Player_map_sector_x = $FFFFC666
- Player_map_sector_y = $FFFFC668
- Map_sector_center = $FFFF9310

### Town System
- Current_town = $FFFFC40C
- Player_position_x_in_town = $FFFFC606
- Player_position_y_in_town = $FFFFC608
- Town_npc_data_ptr = $FFFFC15E

### Object System
- Object_slot_base = $FFFFD000
- Object_slot_size = $2E (46 bytes)
- Max_town_npcs = $1D (29)

---

## Modding Opportunities

### Map Editing
- Decompress sector data from OverworldMaps/CaveMaps
- Edit tile layout
- Recompress with RLE algorithm
- Update pointer table

### Treasure Editing
- Modify treasure setup scripts (loc_00020xxx range)
- Change Reward_script_value for different items/amounts
- Reassign treasure flag addresses

### NPC Editing
- Modify NPC position data
- Change behavior script pointers
- Add/remove NPCs (respect 29 NPC limit)

### Encounter Editing
- Modify EnemyEncounterTypesByMapSector table
- Edit encounter group compositions
- Adjust encounter rates per area

---

*This documentation is based on reverse engineering analysis.*
*All addresses and line numbers refer to vermilion.asm as of 2026-01-25.*
