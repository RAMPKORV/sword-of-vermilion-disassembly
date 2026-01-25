# Function Reference - Sword of Vermilion

Quick reference guide for all documented functions and data tables.

## Map System Functions

| Function Name | Location | Line | Description |
|---------------|----------|------|-------------|
| loc_0000633C | $0000633C | 6363 | RLE map decompression routine |
| loc_0000622A | $0000622A | 6261 | Cave map loading |
| loc_0000626C | $0000626C | 6282 | Overworld map loading (3x3 sectors) |
| LoadMapSectorIfInBounds | - | 6340 | Load sector with bounds check |
| loc_00006328 | $00006328 | 6349 | Unconditional sector load |

## Map Data Tables

| Table Name | Location | Line | Description |
|------------|----------|------|-------------|
| CaveMaps | - | 47898 | 44 cave map pointers |
| OverworldMaps | - | 47368 | 128 overworld sector pointers |

## NPC System Functions

| Function Name | Location | Line | Description |
|---------------|----------|------|-------------|
| loc_00006E1C | $00006E1C | 7088 | Main NPC loading routine (max 29 NPCs) |
| loc_0001FECA | $0001FECA | 34398 | Town NPC setup scripts (16 towns) |
| loc_0001FDD4 | $0001FDD4 | 34300 | Town NPC data pointer table |

## NPC Data Locations

| Data Name | Location | Line | Description |
|-----------|----------|------|-------------|
| loc_000200B6 | $000200B6 | 34587 | Building room NPC data (Format 1) |
| loc_00020780 | $00020780 | 35016 | Building data pointer table |
| loc_0002d208 | $0002D208 | 42630 | Town 0 (Excalabria) NPC data (Format 2) |

## Treasure System Functions

| Function Name | Location | Line | Description |
|---------------|----------|------|-------------|
| loc_0002141E | $0002141E | 35850 | Setup item treasure (type 0) |
| SetupEquipmentTreasure | $00021428 | 35854 | Setup equipment treasure (type 1) |
| InitMoneyTreasure | $00021432 | 35858 | Setup money treasure (type 3) |
| loc_0002145A | $0002145A | 35871 | Setup enemy drop reward |
| loc_00021438 | $00021438 | 35860 | Common treasure init routine |
| loc_00021480 | $00021480 | 35880 | Treasure object initialization |

## Treasure Data Examples

| Location | Line | Type | Contents | Flag Address |
|----------|------|------|----------|--------------|
| loc_000203DA | 34761 | Money | 100 Kims | $FFFFC788 |
| loc_00020402 | 34769 | Money | 50 Kims | $FFFFC798 |
| loc_00020416 | 34775 | Money | 300 Kims | $FFFFC79B |
| loc_0002047A | 34792 | Money | 1700 Kims | $FFFFC7BA |
| loc_000204A2 | 34799 | Money | 9999 Kims | $FFFFC7BC |
| loc_000204B6 | 34805 | Equipment | ID 1 | $FFFFC7AE |
| loc_000204CA | 34811 | Equipment | ID 2 | $FFFFC7AF |
| loc_000204DE | 34817 | Equipment | ID 0 (Bronze Sword) | $FFFFC789 |
| loc_000204F2 | 34823 | Equipment | ID 0 | $FFFFC78A |

## Enemy Encounter System

| Table/Function Name | Location | Line | Description |
|---------------------|----------|------|-------------|
| CheckForEncounter | - | 3031 | Checks if random encounter triggers |
| EnemyEncounterTypesByMapSector | - | 37780 | 128 bytes (overworld sectors) |
| EnemyEncounterTypesByCaveRoom | - | 37791 | 44 bytes (cave rooms) |
| loc_00023C40 | $00023C40 | 37867 | Encounter group table (4 types per group) |
| EnemyStartingPositions | - | 12499 | 8 enemy spawn positions for battle |

## Town System Functions

| Function/Table Name | Location | Line | Description |
|---------------------|----------|------|-------------|
| loc_0001FC88 | $0001FC88 | 34198 | Town tileset index (16 towns) |
| loc_0001FD54 | $0001FD54 | 34283 | Town spawn positions (16 entries) |

## Town Indices

| Index | Town Name | NPC Setup | Tileset | Notes |
|-------|-----------|-----------|---------|-------|
| 0 | Excalabria | loc_0001FF0A | 0 | Starting village |
| 1 | Parma | loc_0001FF14 | 1 | Has conditional NPCs |
| 2 | Wyclif | loc_0001FF40 | 0 | |
| 3 | Helwig | loc_0001FF4A | 1 | |
| 4 | Stow | loc_0001FF54 | 1 | Conditional (innocence) |
| 5 | Malaga | loc_0001FF74 | 1 | |
| 6 | (Unknown) | loc_0001FF7E | 1 | |
| 7 | Deepdale | loc_0001FF88 | 1 | |
| 8 | Keltwick | loc_0001FF92 | 0 | |
| 9 | Hastings | loc_0001FF9C | 1 | |
| 10 | Swadling | loc_0001FFA6 | 0 | |
| 11 | Swaffham | loc_0001FFB0 | 1/2 | Ruined = tileset 2 |
| 12 | Pembroke | loc_0001FFC8 | 2 | |
| 13 | Stow (alt) | loc_0001FFD2 | 0 | |
| 14 | (Unknown) | loc_0001FFDC | 1 | |
| 15 | Carthahena | loc_0001FFE6 | 1 | |

## Important RAM Address Quick Reference

### Player Data
- Player_hp = $FFFFC62C
- Player_mhp = $FFFFC62E
- Player_level = $FFFFC640
- Player_kims = $FFFFC620 (long)
- Player_name = $FFFFC64C

### Position/State
- Program_state = $FFFFC400
- Current_town = $FFFFC40C
- Current_cave_room = $FFFFC556
- Is_in_cave = $FFFFC551
- Player_map_sector_x = $FFFFC666
- Player_map_sector_y = $FFFFC668
- Player_position_x_in_town = $FFFFC606
- Player_position_y_in_town = $FFFFC608

### Game Systems
- Random_number = $FFFFC680
- Event_triggers = $FFFFC720+ (story flags)
- Map_trigger_flags = $FFFFC820

### Object/Entity System
- Object_slot_base = $FFFFD000
- Town_npc_data_ptr = $FFFFC15E

---

## Data Structure Sizes

- Map sector: 256 bytes (16x16 tiles)
- Object slot: 46 bytes ($2E)
- NPC entry (Format 1): 10 bytes
- NPC entry (Format 2): 36 bytes
- Encounter group: 8 bytes (4 word entries)
- Town spawn entry: 8 bytes (4 words)

---

*Quick reference for vermilion.asm*
*Updated: 2026-01-25*
