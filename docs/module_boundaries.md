# Module Boundaries

Each `src/*.asm` file has a single responsibility. This document defines what
each module owns, what it may call, and which RAM regions it touches. Use this
as the authoritative guide when deciding where new code belongs or whether a
function is misplaced.

---

## `src/core.asm`

**Responsibility**: low-level system initialisation and the object init system.

**Owns**:
- `ErrorTrap` — CPU exception handler
- `InitVDP` — VDP register initialisation
- `ClearRAM` — RAM zeroing on boot
- `ObjectInit*` — object table initialisation helpers

**May call**: nothing outside `macros.asm` / `constants.asm`.

**RAM regions**: initialisation-time RAM only; does not touch gameplay RAM
  during normal operation.

**Must not contain**: gameplay logic, script commands, sound, or I/O beyond
  boot-time VDP setup.

---

## `src/vblank.asm`

**Responsibility**: vertical blank interrupt handler.

**Owns**:
- VBlank ISR entry point and exit
- Sprite attribute table DMA upload
- Controller input sampling
- Scroll register updates

**May call**: DMA helpers, sound driver tick.

**RAM regions**: `Sprite_buffer`, `Controller_*`, `Scroll_*`.

**Must not contain**: game logic that should run in the main loop.

---

## `src/states.asm`

**Responsibility**: top-level program state machine (non-gameplay screens).

**Owns**:
- `ProgramStateMap` dispatch table
- Sega logo, title screen, name entry, prologue states

**May call**: `script.asm` for dialogue, `strings.asm` for text rendering,
  `sound.asm` for music/SFX.

**RAM regions**: `Program_state`, `Name_entry_*`.

---

## `src/gameplay.asm`

**Responsibility**: gameplay state machine (town, overworld, dungeon, battle
  dispatch).

**Owns**:
- `GameplayStateMap` dispatch table
- State transitions between overworld, town, dungeon, and battle sub-states

**May call**: all gameplay sub-modules.

**RAM regions**: `Gameplay_state`, `Current_town`, `Current_map_*`.

---

## `src/player.asm`

**Responsibility**: player movement, input handling, and collision.

**Owns**:
- Player movement logic
- Input-to-action mapping
- Collision detection against terrain

**May call**: `enemy.asm` (encounter trigger), `npc.asm` (NPC bump),
  `items.asm` (item pickup).

**RAM regions**: `Player_x`, `Player_y`, `Player_direction`, `Player_speed`.

---

## `src/npc.asm`

**Responsibility**: NPC loading, behavior, and dialogue dispatch.

**Owns**:
- NPC object table management
- NPC movement AI
- NPC interaction / dialogue trigger

**May call**: `script.asm`, `towndata.asm` data tables.

**RAM regions**: `Npc_*` object table entries.

---

## `src/enemy.asm`

**Responsibility**: enemy AI and overworld encounter system.

**Owns**:
- Enemy movement on overworld/dungeon maps
- Random encounter trigger (`CheckForEncounter`)
- Enemy object table management

**May call**: `combat.asm` to initiate battle.

**RAM regions**: `Enemy_*` object entries, `Encounter_*`.

---

## `src/combat.asm`

**Responsibility**: turn-based combat mechanics.

**Owns**:
- Combat state machine
- Damage/heal calculation
- Status effects (poison, etc.)
- Victory/defeat handling

**May call**: `magic.asm`, `items.asm`, `sound.asm`, `battle_gfx.asm`.

**RAM regions**: `Combat_*`, `Battle_*`.

---

## `src/battle_gfx.asm`

**Responsibility**: battle screen graphics rendering and DMA.

**Owns**:
- Battle sprite rendering
- DMA transfer command execution (`ExecuteVdpDmaTransfer`)
- Battle background tilemap setup

**May call**: VDP/DMA helpers in `macros.asm`.

**RAM regions**: `Battle_sprite_buffer`, `BattleSpriteDMACommands`.

**Note**: `GetRandomNumber`, `RemoveItemFromArray`, `ConvertToBCD`,
  `ExtractBCDDigit`, and `DetermineTerrainTileset` currently live here but
  logically belong elsewhere. They are annotated with `; MISPLACED:` comments.
  They cannot be physically moved without breaking bit-perfectness.

---

## `src/script.asm`

**Responsibility**: dialogue script interpreter / virtual machine.

**Owns**:
- Script bytecode fetch-decode-execute loop
- All script command handlers
- Window drawing primitives called by scripts

**May call**: `strings.asm`, `items.asm`, `sram.asm`, `sound.asm`.

**RAM regions**: `Script_pc`, `Script_state`, `Window_*`.

---

## `src/items.asm`

**Responsibility**: item use and inventory management.

**Owns**:
- Item use dispatch
- Inventory array manipulation
- Item effect application

**May call**: `combat.asm` (healing items in battle), `sound.asm`.

**RAM regions**: `Possessed_items`, `Player_herbs`, etc.

---

## `src/magic.asm`

**Responsibility**: magic spellcasting.

**Owns**:
- Spell dispatch and effect logic
- MP consumption
- Spell animation triggers

**May call**: `combat.asm`, `sound.asm`, `battle_gfx.asm`.

**RAM regions**: `Player_mp`, `Player_mmp`, `Player_spells`.

---

## `src/sram.asm`

**Responsibility**: SRAM save and load.

**Owns**:
- Save game serialisation
- Load game deserialisation
- SRAM integrity checks

**May call**: nothing except constants and macros.

**RAM regions**: all `Player_*` and `Event_triggers` (reads/writes on
  save and load).

---

## `src/strings.asm`

**Responsibility**: UI and system strings, text rendering.

**Owns**:
- Menu strings, UI labels
- Text rendering routines (tile blitting to VRAM)

**May call**: VDP helpers.

**RAM regions**: text rendering temporaries.

---

## `src/gamestrings.asm`

**Responsibility**: dialogue and narrative text data.

**Owns**: all dialogue string data referenced by `script.asm` command handlers.

**May call**: nothing (data-only module).

---

## `src/shopdata.asm`

**Responsibility**: shop inventory and pricing tables.

**Owns**: `ShopInventory*`, `ShopPrices*` data tables.

**May call**: nothing (data-only module).

---

## `src/battledata.asm`

**Responsibility**: battle and encounter data tables.

**Owns**: enemy stat tables, encounter rate tables, `BattleSpriteDMACommands`.

**May call**: nothing (data-only module).

---

## `src/playerstats.asm`

**Responsibility**: player stat tables and level-up data.

**Owns**: base stat tables, level-up delta tables, starting equipment.

**May call**: nothing (data-only module).

---

## `src/mapdata.asm`

**Responsibility**: map and sector data (RLE-compressed).

**Owns**: overworld sector data, cave room data, map pointer tables.

**May call**: nothing (data-only module).

---

## `src/gfxdata.asm`

**Responsibility**: graphics tile and sprite data (incbin blobs + offset equates).

**Owns**: all `incbin` graphics data, `_Gfx_*` offset equates.

**May call**: nothing (data-only module).

---

## `src/sound.asm`

**Responsibility**: sound driver and audio data.

**Owns**:
- Z80 sound driver upload
- Sound effect queue (`QueueSoundEffect`)
- FM channel data

**Note**: `TownTilesetPtrs_Gfx_8FEE6` and `TownTilesetPtrs_Gfx_9239A` (town
  tileset pointer tables) live here due to ROM layout constraints. They are
  annotated with `; MISPLACED:` comments.

---

## `src/dungeon.asm`

**Responsibility**: first-person dungeon rendering system.

**Owns**:
- Dungeon view ray-casting / column rendering
- Dungeon tile lookup
- Dungeon movement and collision

**May call**: `mapdata.asm` data, `gfxdata.asm` graphics.

---

## `src/boss.asm` / `src/bossbattle.asm`

**Responsibility**: boss encounter logic and boss battle state machine.

**May call**: `combat.asm`, `battle_gfx.asm`, `sound.asm`.

---

## `src/cutscene.asm`

**Responsibility**: cutscene and ending sequence playback.

**May call**: `script.asm`, `sound.asm`, `strings.asm`.

---

## `src/townbuild.asm`

**Responsibility**: town map rendering and NPC placement.

**May call**: `towndata.asm`, `mapdata.asm`, `npc.asm`.

---

## `src/towndata.asm`

**Responsibility**: town layout and NPC placement data tables.

**May call**: nothing (data-only module).

---

## `src/miscdata.asm`

**Responsibility**: miscellaneous data tables that do not fit a single module.

---

## Top-level files

| File | Role |
|------|------|
| `vermilion.asm` | Include list only — ~30 `include` directives, no code |
| `header.asm` | ROM header, 68k exception vector table, includes `macros.asm` and `constants.asm` |
| `init.asm` | `EntryPoint`, `MainGameLoop`, `WaitForVBlank` |
| `macros.asm` | All assembly macros |
| `constants.asm` | All symbolic constants and RAM address definitions |
