# AGENTS.md - Sword of Vermilion Disassembly

This document provides guidance for AI coding agents working on this Sega Genesis/Mega Drive ROM disassembly project.

## Project Overview

This is a reverse-engineered disassembly of **Sword of Vermilion** for the Sega Genesis. The codebase is written in Motorola 68000 assembly language using the ASM68K assembler.

## Build Commands

### Build the ROM
```batch
build.bat
```
Or directly:
```batch
asm68k /k /p /o ae- vermilion.asm,out.bin,,vermilion.lst
```

**From bash/Git Bash/WSL:** Use `cmd //c build.bat` to run the batch file.

**Assembler flags:**
- `/k` - Keep symbol information
- `/p` - Generate listing file
- `/o ae-` - Disable auto-extend

**Output files:**
- `out.bin` - Compiled ROM binary
- `vermilion.lst` - Assembly listing with addresses

### Verify Build (Bit-Perfect Check)
```batch
verify.bat
```
**From bash/Git Bash/WSL:** Use `cmd //c verify.bat`

This script builds the ROM and verifies it matches the expected SHA256 hash. Exit code 0 means bit-perfect, exit code 1 means mismatch or build failure.

**CRITICAL:** After making ANY code changes, you MUST run `verify.bat` to confirm the build remains bit-perfect. If verification fails, you MUST fix the issue before proceeding. A non-bit-perfect build is never acceptable.

## File Structure

```
vermilion/
├── vermilion.asm      # Main assembly (~78,000 lines)
├── header.asm         # ROM header, vector table, includes
├── init.asm           # Hardware initialization
├── constants.asm      # RAM addresses, game constants
├── macros.asm         # Assembly macros
├── build.bat          # Build script
├── asm68k.exe         # ASM68K assembler
├── notes.txt          # Developer notes on RAM/formats
└── TASKLIST.md        # Project improvement roadmap
```

## Code Style Guidelines

### Label Naming Conventions

**Undocumented locations** use auto-generated names:
```asm
loc_XXXXXXXX    ; Code at ROM offset XXXXXXXX (hex)
```

**Documented labels** use descriptive names:
```asm
; Functions: PascalCase or Mixed_Case
EntryPoint:
InitVDP:
CheckForEncounter:
UpgradeLevelStats:

; Data tables: PascalCase with descriptive suffix
ProgramStateMap:
EnemyStartingPositions:
VDPInitValues:
```

### Constants and RAM Addresses

**Symbolic constants** use ALL_CAPS_WITH_UNDERSCORES:
```asm
PROGRAM_STATE_00    = $00
DIRECTION_UP        = 0
DIRECTION_LEFT      = 2
MAX_PLAYER_LEVEL    = 30
ITEM_HERBS          = $00
EQUIPMENT_SWORD_BRONZE = $00
```

**RAM addresses** use Mixed_Case:
```asm
Player_hp           = $FFFFC62C
Player_level        = $FFFFC640
Current_town        = $FFFFC40C
Program_state       = $FFFFC400
Random_number       = $FFFFC680
```

**Hardware registers** use Mixed_Case:
```asm
VDP_control_port    = $C00004
VDP_data_port       = $C00000
Z80_bus_request     = $A11100
```

### Instruction Formatting

- Instructions in **UPPERCASE** with size suffix lowercase: `MOVE.w`, `JSR`, `BRA.b`, `TST.l`
- Size suffixes: `.b` (byte/8-bit), `.w` (word/16-bit), `.l` (long/32-bit)
- Labels at column 0, instructions indented with tab
- Comments use semicolons: `; Comment`

```asm
EntryPoint:
    TST.l   $00A10008       ; Check if system initialized
    BNE.w   loc_0000102C    ; Branch if not equal
    MOVE.w  #0, Player_level.w
    JSR     UpgradeLevelStats
    RTS
```

### Register Conventions

- **D0-D7**: Data registers for computation and temporary values
- **A0-A6**: Address registers for pointers
- **A7**: Stack pointer (SP)
- **A5**: Often used for object/entity data pointers
- **A6**: Often used for RAM base addresses

### Data Declarations

```asm
dc.b    $FF, $00, $01       ; Byte data
dc.w    $1234, $5678        ; Word data (16-bit)
dc.l    $12345678           ; Long data (32-bit)
```

**Simplify numeric literals when context is clear:**
- When a value clearly represents a small positive integer, use decimal notation
- When a value clearly represents a negative number, use decimal notation
- Only when you are **extremely certain** from context

```asm
; GOOD - Clear semantic meaning
dc.l    2                   ; Two items
dc.w    -1                  ; Invalid/sentinel value
dc.b    10                  ; Counter limit

; AVOID - Unnecessarily verbose for simple numbers
dc.l    $00000002           ; Unclear if this is meant to be 2 or a bit pattern
dc.w    $FFFF               ; Unclear if -1 or max unsigned value
dc.b    $0A                 ; Unnecessary hex for small decimal

; KEEP HEX - When value has bitwise/address meaning
dc.l    $00C00004           ; VDP port address
dc.w    $8F02               ; VDP register command
dc.b    $FF                 ; Bitmask/flag value
```

### Include Directives

```asm
include "header.asm"        ; Include another assembly file
incbin  "data/file.bin"     ; Include binary data (planned)
```

## Memory Map (Key RAM Addresses)

```
$FFFFC400   Program_state       - Current program state
$FFFFC40C   Current_town        - Active town ID
$FFFFC620   Player_kims         - Player gold (long)
$FFFFC62C   Player_hp           - Current HP
$FFFFC62E   Player_mhp          - Max HP
$FFFFC640   Player_level        - Player level
$FFFFC64C   Player_name         - Player name string
$FFFFC680   Random_number       - RNG state
$FFFFC720+  Event_triggers      - Story progress flags
```

## Important Conventions

### Hex Values
- Use `$` prefix for hex: `$FFFFC400`, `$80`, `$0F`
- Use decimal for small constants when semantically clear

### Branching
- Use `.b` for short branches (within ~127 bytes): `BRA.b`, `BNE.b`
- Use `.w` for longer branches: `BRA.w`, `BNE.w`
- Use `JSR`/`BSR` for subroutine calls, `JMP`/`BRA` for jumps

### Error Handling
The ROM has minimal error handling. All CPU exceptions route to `ErrorTrap` which simply returns (`RTE`).

## Project Goals (from TASKLIST.md)

1. **Split main file**: Break `vermilion.asm` into logical modules
2. **Extract assets**: Move binary blobs to external files with `incbin`
3. **Meaningful labels**: Replace `loc_XXXXXXXX` with descriptive names
4. **Document RAM**: Expand `constants.asm` with all known addresses
5. **Create macros**: Add macros for common patterns and data structures

## Working with This Codebase

### When Adding New Labels
- Use descriptive names matching existing conventions
- Add RAM addresses to `constants.asm`
- Add game constants (items, towns, etc.) to `constants.asm`
- When renaming `loc_XXXXXXXX` labels, add a comment line above the new label with the original `loc_XXXXXXXX` value to preserve ROM address context

### When Documenting Code
- Add comments explaining what code does, not what instructions do
- Document data formats in `notes.txt`
- Cross-reference related functions

### Compression Format
Map data uses RLE encoding:
- Byte < $80: Output as-is
- Byte >= $80: Read next byte, output it ($80 - byte) times

## Scripting

**Do NOT use Python in this environment.** Use Node.js for any scripting needs.

### Running Node.js Scripts

**Inline execution:**
```bash
node -e "console.log('Hello');"
```

**Running a script file:**
```bash
node script.js
```

**Example - Reading a file:**
```bash
node -e "const fs = require('fs'); const data = fs.readFileSync('out.bin'); console.log('Size:', data.length);"
```

Node.js version: v25.0.0

## References

- See `notes.txt` for RAM location notes and data format documentation
- See `TASKLIST.md` for the project improvement roadmap
- See `constants.asm` for all defined constants and RAM addresses
