# AGENTS.md - Sword of Vermilion Disassembly

Guidance for AI coding agents working on this Sega Genesis/Mega Drive ROM disassembly.

## CRITICAL: Working Directory Safety

**NEVER run commands that traverse outside `E:\Romhacking\vermilion\`.** All file operations
(dir, ls, find, glob, grep, etc.) MUST be scoped to this project directory.

```
# WRONG - may escape project directory
dir /s /b *.bin
find / -name "*.asm"

# CORRECT - explicit project-scoped paths
dir /s /b E:\Romhacking\vermilion\data\*.bin
rg "pattern" E:\Romhacking\vermilion\src\
```

## Build Commands

### Build the ROM
```batch
build.bat
```
From Git Bash/WSL: `cmd //c build.bat`

Direct invocation: `asm68k /k /p /o ae- vermilion.asm,out.bin,,vermilion.lst`

Flags: `/k` keep symbols, `/p` generate listing, `/o ae-` disable auto-extend.
Output: `out.bin` (ROM binary), `vermilion.lst` (listing with addresses). Both are gitignored.

### Verify Build (Bit-Perfect Check)
```batch
verify.bat
```
From Git Bash/WSL: `cmd //c verify.bat`

Builds the ROM and checks its SHA256 against the known-good hash. Exit 0 = bit-perfect,
exit 1 = mismatch or build failure.

**CRITICAL: After ANY code change, run `verify.bat`. A non-bit-perfect build is never
acceptable. Do not proceed until the build is clean.**

There are no unit tests — bit-perfect verification is the only test.

## File Structure

```
vermilion/
├── vermilion.asm          # Top-level entry: ~30 lines of include directives only
├── header.asm             # ROM header, 68000 exception vector table, includes macros+constants
├── init.asm               # Reference file: EntryPoint, MainGameLoop, WaitForVBlank
├── constants.asm          # ALL symbolic constants and RAM addresses (~2976 lines)
├── macros.asm             # Assembly macros (~281 lines)
├── src/                   # Split source modules (28 .asm files, included by vermilion.asm)
│   ├── core.asm           #   ErrorTrap, InitVDP, ClearRAM, object init system
│   ├── vblank.asm         #   Vertical blank interrupt handler
│   ├── states.asm         #   Program state machine (logo, title, name entry, prologue)
│   ├── gameplay.asm       #   Gameplay state machine (town, overworld, dungeon, battle)
│   ├── player.asm         #   Player movement, input, collision
│   ├── npc.asm            #   NPC loading, behavior, dialogue dispatch
│   ├── enemy.asm          #   Enemy AI, encounter system
│   ├── combat.asm         #   Combat/battle mechanics
│   ├── script.asm         #   Dialogue script interpreter
│   ├── items.asm          #   Item use and inventory
│   ├── magic.asm          #   Magic spellcasting
│   ├── sram.asm           #   Save/load SRAM persistence
│   ├── strings.asm        #   UI and game strings
│   ├── gamestrings.asm    #   Dialogue text strings
│   ├── shopdata.asm       #   Shop inventory and pricing data
│   ├── battledata.asm     #   Battle/encounter data tables
│   ├── playerstats.asm    #   Player stat tables, level-up data
│   ├── mapdata.asm        #   Map/sector data (RLE compressed)
│   ├── gfxdata.asm        #   Graphics tile/sprite data
│   ├── sound.asm          #   Sound driver and audio data
│   └── ...                #   (8 more: dungeon, boss, battle_gfx, cutscene, towndata, etc.)
├── data/                  # Binary assets: art/palettes, art/tiles, maps/, sound/
├── build.bat              # Build script
├── verify.bat             # SHA256 bit-perfect verification
├── asm68k.exe             # ASM68K assembler binary
├── notes.txt              # Developer notes: RAM locations, map format, item list
└── notes.txt              # Developer notes: RAM locations, map format, item list
```

## Code Style Guidelines

### Label Naming

| Type | Convention | Example |
|------|-----------|---------|
| Undocumented locations | `loc_XXXXXXXX` (hex ROM offset) | `loc_0000633C` |
| Functions | PascalCase or Mixed_Case | `EntryPoint`, `CheckForEncounter` |
| Data tables | PascalCase with descriptive suffix | `ProgramStateMap`, `VDPInitValues` |
| Local labels within functions | `FunctionName_Loop`, `_Return`, `_End` | `EntryPoint_VdpInitLoop` |
| Symbolic constants | `ALL_CAPS_WITH_UNDERSCORES` | `PROGRAM_STATE_SEGA_LOGO`, `ITEM_HERBS` |
| RAM addresses | `Mixed_Case` noun phrase | `Player_hp`, `Current_town` |
| Hardware registers | `Mixed_Case` | `VDP_control_port`, `Z80_bus_request` |

When renaming a `loc_XXXXXXXX` label, preserve the original address in a comment above it:
```asm
; loc_0000633C
MapRLEDecompressor:
```

### Instruction Formatting

```asm
EntryPoint:
    TST.l   $00A10008       ; Check if system initialized
    BNE.w   loc_0000102C    ; Branch if not equal
    MOVE.w  #0, Player_level.w
    JSR     UpgradeLevelStats
    RTS
```

- Instructions **UPPERCASE**, size suffixes **lowercase**: `MOVE.w`, `TST.l`, `BNE.b`
- Labels at column 0; instructions indented with one tab
- Comments use `; ` (semicolon + space)
- Size suffixes: `.b` byte (8-bit), `.w` word (16-bit), `.l` long (32-bit)
- Branches: `.b` for short (±127 bytes), `.w` for longer ranges
- Calls: `JSR`/`BSR` for subroutines; `JMP`/`BRA` for plain jumps

### Register Conventions

- `D0–D7`: Data/computation/temporaries
- `A0–A6`: Address/pointer registers
- `A5`: Object/entity data pointer (frequent convention)
- `A6`: RAM base address (frequent convention)
- `A7`: Stack pointer (SP), reset to `$FFFFFE00` at main loop top

### Data Declarations and Numeric Literals

```asm
dc.b    $FF, $00, $01       ; Byte data
dc.w    $1234, $5678        ; Word data (16-bit)
dc.l    $12345678           ; Long data (32-bit)
```

**CRITICAL — Never convert hex to decimal in `dc.b`/`dc.w`/`dc.l` data.**
Even `$0000` vs `0` or `$0001` vs `1` can break bit-perfect builds because ASM68K
encodes them differently in certain contexts. This is the most common source of build
failures.

- **KEEP HEX** for addresses, hardware values, bitmasks, and all existing data tables
- **SAFE** to use decimal for instruction immediates: `MOVE.w #0, D0`, `MOVEQ #10, D1`
- **Add comments** to explain values: `dc.w $0016 ; 22 groups (0-based)`

### Section Banner Comments

```asm
; ======================================================================
; src/combat.asm
; Combat and battle mechanics
; ======================================================================
```

## Constants and RAM Addresses

All constants go in `constants.asm`. Key RAM addresses:

```
$FFFFC400   Program_state       Current program state
$FFFFC40C   Current_town        Active town ID
$FFFFC444   Possessed_items     Item inventory array
$FFFFC620   Player_kims         Player gold (long)
$FFFFC62C   Player_hp           Current HP
$FFFFC62E   Player_mhp          Max HP
$FFFFC640   Player_level        Player level
$FFFFC64C   Player_name         Player name string
$FFFFC680   Random_number       RNG state
$FFFFC720+  Event_triggers      Story progress flags
```

## Git Safety

**NEVER use `git checkout -- <file>` or `git revert` unless you intend to discard ALL
uncommitted changes.** When a build breaks, identify and fix the specific problem; do not
reflexively revert.

Recommended workflow for multi-step changes:
1. Make one small, targeted change
2. Run `cmd //c verify.bat`
3. On success: `git add . && git commit -m "Description (bit-perfect)"`
4. Repeat

## Scripting

**Do NOT use Python.** Use Node.js (v25.0.0) for any scripting needs.

```bash
node -e "const fs = require('fs'); const d = fs.readFileSync('out.bin'); console.log(d.length);"
node script.js
```

## Debugging Build Failures

```bash
# Find all references to a label before renaming
rg "\bloc_XXXXXXXX\b" E:\Romhacking\vermilion\src\
```

Common causes: hex→decimal conversion in data, wrong label reference after rename,
missing/extra bytes in a data table.

## Map Compression Format

Map data uses RLE encoding:
- Byte `< $80`: output as-is
- Byte `>= $80`: read next byte, output it `($80 - byte)` times

## References

- `notes.txt` — RAM locations, map tile format, item list
- `constants.asm` — all symbolic constants and RAM address definitions
