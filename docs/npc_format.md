# NPC Placement and Behavior Data Format

Sword of Vermilion (Sega Genesis) — NPC system reference.

---

## Overview

NPCs are spawned at town load time from a per-town `NpcEntryList` table.  Each entry
encodes the NPC's world position, sprite, animation table, AI init routine, and collision
flag.  At runtime the game creates entity objects in a linked-list pool and calls each
NPC's tick function once per frame.

Key files:
- `src/townbuild.asm` — all NPC placement data (`NpcEntryList_*`, `NpcDataTable_*`)
- `src/npc.asm` — all NPC init/tick behavior functions
- `src/towndata.asm` — dispatch tables (`TownNpcSetupJumpTable`, `TownNpcDataLookupJumpTable`)
- `src/bossbattle.asm:712` — `LoadTownNPCs` (entity-pool spawner)
- `macros.asm:547` — `npcEntry` macro definition
- `constants.asm:2590` — `obj_*` entity struct field equates

---

## `npcEntry` Macro (macros.asm:547)

Each NPC entry in a placement list is **14 bytes**, emitted by the `npcEntry` macro:

```
Offset  Size  Field       Description
------  ----  ----------  -----------------------------------------
+$00    .w    xpos        World X position (pixels)
+$02    .w    ypos        World Y position (pixels)
+$04    .w    tile        VRAM sprite tile index
+$06    .l    anim        Pointer to sprite frame animation table
+$0A    .l    tick        Pointer to NPC AI init routine
+$0E    .b    attr        VDP sprite attribute flags (palette, priority)
+$0F    .b    solid       Collision: NPC_SOLID=$01, NPC_PASSABLE=$00
```

**Example** (from `NpcEntryList_Wyclif`, townbuild.asm:2012):
```asm
npcEntry $02B8, $01D8, $0091, NPCSpriteFrames_ManA, NPCInit_StowSoldier_DoctorHint, NPC_ATTR_PAL3, NPC_SOLID
```
Places Man A sprite at world (0x2B8, 0x1D8), using palette line 3, with collision.

### `attr` flag constants

| Constant        | Value  | Meaning                                 |
|-----------------|--------|-----------------------------------------|
| `NPC_ATTR_PAL0` | `$00`  | Palette line 0 (tile/background palette)|
| `NPC_ATTR_PAL1` | `$20`  | Palette line 1 (enemy palette)          |
| `NPC_ATTR_PAL3` | `$60`  | Palette line 3 (character/player palette)|

The `attr` byte maps to the high byte of the VDP sprite attribute word (bits 7–0 of that
byte = priority, palette select, V-flip, H-flip).

---

## `NpcEntryList` Format (townbuild.asm:72–93)

Each `NpcEntryList_<Town>` is a sequence of **NPC groups**.  Each group contains exactly
one `DialogueDispatch` pointer followed by zero or more `npcEntry` records, terminated
by a `$FFFF` sentinel word.

```
NpcEntryList_<Town>:
    dc.l  <DialogueDispatchFn>      ; pointer to dialogue handler for group 0
    npcEntry ...                    ; one per NPC (14 bytes each)
    npcEntry ...
    dc.w  $FFFF                     ; end-of-group
    dc.l  <NextDialogueDispatchFn>  ; group 1
    npcEntry ...
    dc.w  $FFFF
    ...                             ; more groups follow
```

**Groups** correspond to separate rooms or story-conditional NPC sets.  Group 0 is
always the outdoor town population.  Groups 1+ are typically building interiors.

Groups with zero `npcEntry` lines (dispatch pointer + `$FFFF` immediately) define
conditional groups that have no physical NPCs but a dispatch handler for dialogue state
wiring.

### Loading sequence (`LoadTownNPCs`, bossbattle.asm:712)

1. `Town_npc_data_ptr` points to the active `NpcEntryList_<Town>`.
2. Read first longword → `Npc_init_routine_ptr` (the dispatch function pointer).
3. Iterate up to 30 entity slots (`D7 = $1D`), reading 14-byte entries:
   - Copy `xpos` → `obj_world_x`, `ypos` → `obj_world_y`
   - Copy `tile` → `obj_tile_index`
   - Copy `anim` → `obj_anim_ptr`
   - Copy `tick` → `obj_tick_fn`, then **immediately call it** (init call)
   - Copy `attr` → `obj_sprite_flags`
   - Copy `solid` → `obj_collidable`
4. On `$FFFF` sentinel: set `Npc_load_done_flag`, deactivate remaining slots.
5. Call `Npc_init_routine_ptr` (the dispatch function) to wire up dialogue strings.
6. Walk `Npc_count` entities, writing dialogue string pointers from the dispatch table
   into each entity's `obj_npc_str_ptr`.

### Town NPC pointer dispatch (`TownNpcSetupJumpTable`, towndata.asm:2278)

16 entries (one per town), indexed by `Current_town * 4`.  Each entry runs a short stub
that sets `Town_npc_data_ptr` to the correct `NpcEntryList_<Town>`.  Stubs may check
story-state flags to select an alternate list (e.g. Parma Normal vs. Locked).

---

## `NpcDataTable` Format (townbuild.asm:95–115)

A separate **40-byte-per-record** array, terminated by `$FF $FF`.  Used by
`SearchTownNPCData` (gameplay.asm:~2190) to match the player's tile position to a town
state configuration (e.g. to trigger conversations, open doors, advance quests).

```
Offset  Size  Field                 Notes
------  ----  --------------------  ------------------------------------
+$00    .w    patrol_start_x        Patrol start tile X
+$02    .w    patrol_start_y        Patrol start tile Y
+$04    .w    speed_or_range        Patrol speed or range
+$06    .w    ???
+$08    .w    ???
+$0A    .w    ???
+$0C    .w    ???
+$0E    .w    ???
+$10    .w    dialog_state          NPC dialog state index
+$12    .w    ???
+$14    .l    ptr_a                 Pointer (dialog or route data)
+$18    .w    waypoint_b_x          Patrol waypoint B tile X
+$1A    .w    waypoint_b_y          Patrol waypoint B tile Y
+$1C    .w    ???
+$1E    .w    ???
+$20    .w    dialog_state_2        Secondary dialog state index
+$22    .w    ???
+$24    .l    ptr_b                 Secondary pointer
+$28    ...   (end of 40-byte record)
```

> **Note:** `NpcDataTable` field meanings are **not yet fully reversed.**
> Known fields are marked above; `???` fields require further analysis.
> Record stride confirmed as `$28` bytes (`LEA $28(A1), A1` in SearchTownNPCData).

### NpcDataTable lookup dispatch (`TownNpcDataLookupJumpTable`, towndata.asm:2180)

16 entries, indexed by `Current_town * 4`.  Each returns a pointer to
`NpcDataTable_<Town>` in A1 for use by `SearchTownNPCData`.

---

## Entity Object Struct (`obj_*` fields)

The entity pool stores all entities (NPCs, enemies, projectiles) in a fixed-size linked
list.  The base pointer for the active object is A5 (or A6).  All fields are equated in
`constants.asm:2590`.

| Equate                | Offset  | Size  | Purpose                                              |
|-----------------------|---------|-------|------------------------------------------------------|
| `obj_active`          | `$00`   | .b    | Bit 7 = active flag                                  |
| `obj_next_offset`     | `$01`   | .b    | Linked-list stride to next entity slot               |
| `obj_tick_fn`         | `$02`   | .l    | Per-frame tick / behavior function pointer           |
| `obj_sprite_size`     | `$06`   | .b    | VDP sprite size nibble (H/V cell count)              |
| `obj_sprite_flags`    | `$07`   | .b    | VDP tile attr high byte (priority, palette, flip)    |
| `obj_tile_index`      | `$08`   | .w    | VRAM tile index for sprite                           |
| `obj_screen_x`        | `$0A`   | .w    | On-screen X position (pixels)                        |
| `obj_screen_y`        | `$0C`   | .w    | On-screen Y position (pixels)                        |
| `obj_world_x`         | `$0E`   | .w    | World X position (pixels)                            |
| `obj_world_y`         | `$12`   | .w    | World Y position (pixels)                            |
| `obj_sort_key`        | `$16`   | .w    | Sprite Z-depth / priority sort value                 |
| `obj_direction`       | `$18`   | .b    | Facing: 0=up, 2=left, 4=down, 6=right                |
| `obj_npc_busy_flag`   | `$19`   | .b    | NPC busy: `$FF`=interacting, `$00`=free              |
| `obj_invuln_timer`    | `$1A`   | .b    | Invulnerability countdown (NPC: wander delay timer)  |
| `obj_move_counter`    | `$1B`   | .b    | Movement / animation step counter                    |
| `obj_npc_str_ptr`     | `$1C`   | .l    | NPC hint-text / dialogue string pointer (NPC only)   |
| `obj_hitbox_half_w`   | `$1C`   | .w    | Hitbox half-width (enemy/projectile only, same offset)|
| `obj_hitbox_half_h`   | `$1E`   | .w    | Hitbox half-height (enemy/projectile only)           |
| `obj_pos_x_fixed`     | `$20`   | .l    | Fixed-point world X (first-person/dungeon movement)  |
| `obj_seg_counter`     | `$22`   | .w    | Segment / sub-state counter                          |
| `obj_sprite_frame`    | `$24`   | .b    | Current sprite frame index                           |
| `obj_behavior_flag`   | `$25`   | .b    | NPC conditional behavior: `$FF`=triggered            |
| `obj_hit_flag`        | `$26`   | .b    | Collision hit flag: `$FF`=hit this frame             |
| `obj_npc_saved_dir`   | `$27`   | .b    | NPC saved wander direction (restored post-dialogue)  |
| `obj_hp`              | `$28`   | .w    | Current HP (enemy only)                              |
| `obj_xp_reward`       | `$2A`   | .w    | XP awarded on kill (enemy only)                      |
| `obj_max_hp`          | `$2C`   | .w    | Max HP (enemy only)                                  |
| `obj_collidable`      | `$2D`   | .b    | NPC solid flag: `$01`=solid, `$00`=passable          |
| `obj_anim_ptr`        | `$2E`   | .l    | NPC sprite frame animation table pointer             |
| `obj_vel_x`           | `$32`   | .l    | X velocity fixed-point (enemy only)                  |
| `obj_vel_y`           | `$36`   | .l    | Y velocity fixed-point (enemy only)                  |
| `obj_attack_timer`    | `$3A`   | .w    | AI / attack cooldown counter (enemy only)            |
| `obj_knockback_timer` | `$3C`   | .w    | Knockback / stun countdown (enemy only)              |
| `obj_kim_reward`      | `$3E`   | .w    | Gold (kims) on kill (enemy only)                     |

---

## NPC Behavior Functions (src/npc.asm)

Every NPC has an **init function** (the `tick` field in `npcEntry`) called once at spawn,
and a **tick function** set by the init call and invoked every frame thereafter.

### Common Init Functions

| Function                        | Behavior |
|---------------------------------|----------|
| `NPCInit_WalkingStatic`         | Stationary NPC, no animation |
| `NPCInit_WalkingAnimated`       | Random-wander walk with animation |
| `NPCInit_WalkingStatic_LoadFrame` | Stationary with one-time frame load |
| `NPCInit_WalkingAnimated_Animate` | Walk + continuous sprite animation |
| `NPCInit_StowSoldier_DoctorHint` | Sets up soldier/doctor hint text |
| `NPCInit_ParmaFairy`            | Fairy-type floating animation |
| `NPCInit_Wyclif_UseMapHint1`    | Context-sensitive hint about the map |
| `NPCInit_Wyclif_UseMapHint2Init`| Second map-hint variant |
| `NPCInit_Wyclif_ParmaFindRing`  | Quest-conditional ring-find dialogue |

### Timing Constants

| Constant               | Value   | Meaning                                  |
|------------------------|---------|------------------------------------------|
| `NPC_ROTATION_FRAMES`  | `$20`   | 32 frames for turn animation             |
| `NPC_WANDER_DELAY`     | `$32`   | 50 ticks between wander steps            |
| `NPC_STUCK_THRESHOLD`  | `$78`   | 120 ticks before reversing direction     |

### Hint / Dialogue Wiring

`SetHintTextIfTriggered` (npc.asm:2354):
1. Reads `Map_trigger_flags[D5]` (story progress flags).
2. If the flag is set, copies `Pending_hint_text` into `obj_npc_str_ptr`.
3. `obj_npc_str_ptr` is read by the dialogue engine when the player interacts.

---

## VRAM Tile IDs for NPC Sprites

Defined in `constants.asm`:

| Constant                    | Value    | Sprite type            |
|-----------------------------|----------|------------------------|
| `VRAM_TILE_NPC_MAN_A`       | `$0091`  | Adult man A            |
| `VRAM_TILE_NPC_MAN_B`       | `$00CD`  | Adult man B            |
| `VRAM_TILE_NPC_VILLAGER_C`  | `$0109`  | Villager type C        |

Animation frame tables (e.g. `NPCSpriteFrames_ManA`, `NPCSpriteFrames_Elder`,
`NPCSpriteFrames_Woman`, `NPCSpriteFrames_Child`, `NPCSpriteFrames_Soldier`,
`NPCSpriteFrames_Priest`, `NPCSpriteFrames_Shopkeeper`) are defined in `src/npc.asm`.

---

## RAM Variables

| Address       | Symbol                     | Width | Purpose                                          |
|---------------|----------------------------|-------|--------------------------------------------------|
| `$FFFFC0FC`   | `Npc_count`                | .w    | Number of NPCs spawned in current town           |
| `$FFFFC15E`   | `Town_npc_data_ptr`        | .l    | Pointer to active `NpcEntryList_<Town>`          |
| `$FFFFC162`   | `Saved_town_npc_data_ptr`  | .l    | Saved ptr for outdoor town (room restore)        |
| `$FFFFC166`   | `Saved_npc_data_ptr`       | .l    | Saved ptr for room 2 (building interior)         |
| `$FFFFC16A`   | `Saved_npc_data_ptr_room3` | .l    | Saved ptr for room 3                             |
| `$FFFFC170`   | `Npc_init_routine_ptr`     | .l    | Dialogue dispatch function pointer               |
| `$FFFFC303`   | `Npc_load_done_flag`       | .b    | Set when `$FFFF` sentinel is encountered         |

---

## Town Coverage

| Town           | NpcEntryList label(s)                               | Notes                                        |
|----------------|-----------------------------------------------------|----------------------------------------------|
| Wyclif         | `NpcEntryList_Wyclif`                               | 10 groups; quest-conditional indoor NPCs     |
| Parma          | `NpcEntryList_Parma`, `NpcEntryList_Parma_Locked`   | Two outdoor variants (story flag)            |
| Deepdale       | `NpcEntryList_Deepdale`                             |                                              |
| Stow           | `NpcEntryList_Stow`, `NpcEntryList_Stow_Soldiers`   | Two variants (pre/post military occupation)  |
| Malaga         | `NpcEntryList_Malaga`                               |                                              |
| Keltwick       | `NpcEntryList_Stow2AndKeltwick`                     | Shares list with Stow2                       |
| Helwig         | `NpcEntryList_Helwig`                               |                                              |
| Tadcaster      | `NpcEntryList_Tadcaster`                            |                                              |
| Swaffham       | `NpcEntryList_Swaffham`, `NpcEntryList_Swaffham_Ruined` | Two variants (pre/post destruction)       |
| Excalabria     | `NpcEntryList_Excalabria`                           |                                              |
| Hastings       | `NpcEntryList_Hastings1`/`_Hastings2`               | Shares `NpcDataTable_Hastings1`              |
| Carthahena     | `NpcEntryList_Carthahena`, `NpcEntryList_Carthahena_TsarkonDead` | Two variants             |

---

## Tilemap Format (brief — see townbuild.asm header for full spec)

Town tilemaps use a **7-opcode RLE** format distinct from overworld/cave RLE:

```
Stream header: 2 bytes — width (tiles), height (tiles)

Command byte: bits[7:5] = opcode, bits[4:0] = count N
  op 0  Literal run:    emit N+1 bytes from stream
  op 1  Repeat 1 byte:  repeat 1 byte N+1 times
  op 2  Repeat 2 bytes: repeat 2-byte pair N+1 times
  op 3  Repeat 3 bytes: repeat 3-byte triple N+1 times
  op 4  Repeat 4 bytes: repeat 4-byte quad N+1 times
  op 5  Copy row-1:     copy N+1 tiles from 1 row back
  op 6  Copy row-2:     copy N+1 tiles from 2 rows back
  op 7  End of stream:  $FF = terminate
```

Each town has two interleaved blob pairs per plane (Plane A / Plane B); the primary blob
fills low bytes (stride +2) and the secondary fills high bytes, together forming
VDP nametable entries.

Room index ranges:
- `$00–$0F` — outdoor town areas (16 towns)
- `$10–$1F` — castle interiors
- `$20–$35` — building interiors (22 types)

---

## Quick Reference: Adding an NPC

1. Choose the target town's `NpcEntryList_<Town>` in `src/townbuild.asm`.
2. Add a `npcEntry` line to the appropriate group (before its `dc.w $FFFF`), or add a
   new group (new `dc.l <DispatchFn>` + entries + `dc.w $FFFF`).
3. World coordinates: `xpos` and `ypos` are in pixels; one tile = 8 pixels.
4. Choose a sprite tile constant (`VRAM_TILE_NPC_*`) and matching animation table
   (`NPCSpriteFrames_*`).
5. Choose an init/AI routine (`NPCInit_WalkingStatic`, `NPCInit_WalkingAnimated`, etc.).
6. Set `attr` (`NPC_ATTR_PAL0` or `NPC_ATTR_PAL3`) and `solid` (`NPC_SOLID`).
7. Wire dialogue in the town's `DialogueDispatch` function (`src/npc.asm`).
8. Run `cmd //c verify.bat` — build must remain bit-perfect.
