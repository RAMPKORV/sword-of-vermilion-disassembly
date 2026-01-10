# AGENTS.md - Sword of Vermilion Disassembly

This is a Sega Genesis/Mega Drive disassembly project for the classic JRPG "Sword of Vermilion" (1989/1990 by Sega). The codebase uses Motorola 68000 assembly language.

## Project Structure

```
vermilion.asm       # Main assembly source (~78,000+ lines)
constants.asm       # RAM addresses, game constants, item/magic/equipment IDs
macros.asm          # Assembly macros (e.g., print macro for scripting)
build.bat           # Build script using asm68k assembler
notes.txt           # Reverse engineering notes (RAM locations, map format)
asm68k.exe          # Motorola 68000 assembler for Sega Genesis
```

## Build Commands

```batch
build.bat
```
Or directly:
```batch
asm68k /k /p /o ae- vermilion.asm,out.bin,,vermilion.lst
```

**Flags:** `/k` keep temps, `/p` produce listing, `/o ae-` output opts  
**Output:** `out.bin` (ROM binary), `vermilion.lst` (listing with addresses)

### Verification
No automated tests. Verify by comparing `out.bin` against original ROM and testing in an emulator (Kega Fusion, BlastEm).

## Code Style Guidelines

### Label Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Documented code | PascalCase | `CheckIfCursed:`, `GetRandomNumber:`, `CastAero:` |
| Undocumented | `loc_XXXXXXXX` | `loc_00000202:`, `loc_0001870E:` |
| Strings | PascalCase + `Str` | `WelcomeMessageStr:`, `NotEnoughMoneyStr:` |
| Jump tables | PascalCase + `Map` | `ProgramStateMap:`, `UseItemMap:` |

### Constants Naming (constants.asm)

**RAM addresses - Snake_Case:**
```asm
Player_hp           = $FFFFC62C
Equipped_sword      = $FFFFC4D0
Script_source_base  = $FFFFC204
```

**Enumeration constants - SCREAMING_SNAKE_CASE:**
```asm
DIRECTION_UP        = 0
TOWN_WYCLIF         = $00
ITEM_HERBS          = $00
MAX_PLAYER_LEVEL    = 30
```

### File Organization

1. Includes at top (`macros.asm`, `constants.asm`)
2. ROM Header with vector table at address 0
3. Initialization (hardware, Z80, VDP setup)
4. Main loop and state machine
5. Subroutines grouped by functionality
6. Data tables and string data
7. Compressed graphics at end

### Assembly Patterns

**Subroutine calls:**
```asm
BSR.w   NearSubroutine    ; Branch subroutine (within 32KB)
JSR     FarSubroutine     ; Jump to subroutine (absolute)
RTS                       ; Return from subroutine
```

**Jump tables:**
```asm
CastBattleMagicMap:
    BRA.w CastAero
    BRA.w CastAerios
    BRA.w CastVolti
```

**RAM access:**
```asm
MOVE.w  Player_hp.w, D0         ; Read from RAM
MOVE.w  D0, Player_hp.w         ; Write to RAM
```

**Common register usage:**
- `D0-D7` - Data registers (D0 often for return values)
- `A0-A6` - Address registers (A5/A6 often point to entities)
- `A7` - Stack pointer (implicit)

**Interrupt control:**
```asm
ORI     #$0700, SR        ; Disable interrupts
ANDI    #$F8FF, SR        ; Enable interrupts
```

### String/Script Data Format

```asm
SomeDialogueStr:
    dc.b    "Hello, traveler!", $FE, "Welcome to ", $F7, "!", $FF
```

| Byte | Meaning |
|------|---------|
| `$FF` | String terminator |
| `$FE` | Line break |
| `$F7` | Player name placeholder |

**Print macro:**
```asm
PRINT WelcomeMessageStr
; Expands to: MOVE.l #WelcomeMessageStr, Script_source_base.w
```

### Data Declarations

```asm
dc.b    $3C, $3C, $1F     ; Byte data
dc.w    $1234             ; Word data (16-bit)
dc.l    $12345678         ; Long data (32-bit)
dc.l    SomeLabel         ; Address reference
```

### Comments

```asm
; Full line comment explaining the section
MOVE.w  D0, D1            ; Inline comment after instruction
```

## Technical Reference

**Platform:** Sega Genesis/Mega Drive (68000 @ 7.67 MHz)  
**RAM:** `$FF0000 - $FFFFFF`  
**VDP Control:** `$C00004` | **VDP Data:** `$C00000` | **Z80 Bus:** `$A11100`

## When Modifying Code

1. **Preserve byte alignment** - ROM must match expected size
2. **Use existing constants** - Check constants.asm before hardcoding
3. **Follow naming patterns** - PascalCase for new labels, `loc_XXXXXXXX` for raw
4. **Document discoveries** - Rename labels when code is understood
5. **Test in emulator** - Build and verify changes work
6. **Update notes.txt** - Add RAM location findings

## Common Tasks

**Renaming an undocumented label:**
Change `loc_0001870E` to descriptive name like `HandlePlayerDeath` once understood.

**Adding a new constant:**
Add to constants.asm following naming convention for that section.

**Finding a string:**
Search for `Str:` suffix labels or `dc.b` with ASCII text.

**Tracing game flow:**
Start at `ProgramStateMap` or `GameStateMap` jump tables.
