# Refactor Log — Sword of Vermilion Disassembly

A running log of significant refactors: label renames, constant extractions,
macro adoptions, and module moves. Most recent first.

For the complete commit history, use `git log --oneline`.

---

## 2026-03-05

### ARCH-004: macros.asm — Added file-level section index
Added a top-level banner with a table of contents listing all 52 macros organized
by category (Hardware/System, VDP/DMA, Sound, Input, Object System, Data Tables,
State Machine, UI/Window, Tile Helpers, Chest/Reward, Script/Dialogue, Data Entry).

### BUILD-003: vermilion_test.asm — Added REFERENCE ONLY header
Added a prominent comment header to the original 78,461-line single-file reference
disassembly clarifying that it is not part of the active build and may be removed
if git history is sufficient.

### MOD-008: vblank.asm — Converted all raw dc.b object init tables to objectInitGroup macro
Converted 6 raw `dc.b` sections: BattleObjectInitTable (29 groups), BossObjectInitTable_A
(13 groups), BossObjectInitTable_C (15 groups), BossObjectInitTable_D (7 groups),
BossObjectInitTable_E (19 groups), BossObjectInitTable_F (7 groups). Bit-perfect verified.

### MOD-005: Consolidated PAL/NTSC region check into IsPalRegion macro
Added `IsPalRegion` macro to macros.asm. All 11 existing call sites use the explicit
`BTST.b #6, IO_version` form which is byte-for-byte identical to the macro expansion;
left as-is for bit-perfect output.

### RAM-005, RAM-006, RAM-007: vblank.asm documentation
Added comprehensive comment blocks documenting:
- Sprite attribute buffer and DMA upload pipeline
- Controller input sampling and debounce pipeline (3-phase TH-strobe protocol)
- Scroll register and tilemap layout (HScroll/VScroll, parallax system)

### ARCH-003 / MOD-010: vdpCmd macro
Added `vdpCmd` macro and `VDP_TYPE_*` constants to macros.asm for generating VDP
control-port command longwords at assemble time.

### ARCH-002: constants.asm — Section headers
Added clear section separator comments to all sections in constants.asm.

### RAM-004: RAM symbol annotations
Added size/type/description annotations (`.b`, `.w`, `.l`, `buf`, `arr`) to all
~80 RAM symbol definitions in constants.asm.

### MOD-001: docs/module_boundaries.md
Created module boundaries document covering all 28 src/*.asm files with single
responsibility, allowed callers, RAM ownership, and misplaced-code notes.

### CONTRIB-001, CONTRIB-002, CONTRIB-005, CONTRIB-009: Contributor docs
Created: docs/contributing.md, docs/debugging_verify_failures.md,
docs/asm68k_quirks.md, docs/build_workflow.md.

---

## 2026-03-04 to 2026-03-05

### DRY-001: dungeon.asm — Unified four UpdateFpWalls_Facing* functions
Merged UpdateFpWalls_FacingUp/Down/Left/Right (~240 lines) into a single
parameterized function using a direction offset table. Saved ~240 lines.

### DRY-003: battle_gfx.asm — Deduplicated ExecuteVdpDmaFromPointer/FromRam
One function replaced with a JMP to the other (byte-for-byte identical).

### DRY-005: script.asm — Window setup macro adoption
Converted 31 of 32 inline window-setup sequences to SetupWindow/SetupWindowSize/
DrawWindowDynH macro calls.

### DRY-009: states.asm — AdvanceStateOnComplete macro
Added macro to macros.asm; replaced 3 identical 5-instruction state completion
patterns in ProgramState_Prologue, ProgramState_LoadSave, ProgramState_NameEntry.

### MACRO-001 through MACRO-005: Macro adoption sweep
Applied DMAFillVRAM (7 sites in core.asm), initObjects (9 trampolines), CheckButton
(36 JSR calls), objectInitGroup (8 entries), PlaySound (~12 sites).

### CONST-001: Removed duplicate constant block
Removed lines 2218–2575 (wholesale duplicate of lines 1879–2216) from constants.asm.
Preserved 12 unique Sound IDs from the duplicate block by merging them into the
first copy's sound section.

### CONST-002 through CONST-005: I/O and hardware constants
Defined IO_version_register, IO_ctrl_port_1/2/exp, IO_tmss_register, and other
I/O port constants. Replaced 26 hardcoded I/O addresses across 9 files.
Applied Z80_reset, Z80_ram, PSG_port constants (15 sites).

### CONST-006 / RAM-002: Object struct constants
Defined obj_* offset constants for all 40-byte object struct fields. Replaced all
raw $NN(A5)/$NN(A6) accesses across src/*.asm.

### RAM-001, RAM-003: Object struct and Event_triggers documentation
Full object slot struct layout documented in constants.asm.
All Event_triggers flags ($FFFFC720+) identified and named.

### VM-001, VM-002, VM-003: Script VM documentation
Complete opcode table exported to tools/index/script_opcodes.json.
All script VM RAM variables named and documented.
Full text encoding table documented in src/strings.asm / src/gamestrings.asm.

### LABEL-001: Final loc_ label renamed
The last loc_ label in header.asm renamed to a descriptive PascalCase label
(0 loc_ labels now remain in the active build).

### LABEL-004: Symbol map tool
Created tools/index/symbol_map.js: parses vermilion.lst and emits
tools/index/symbol_map.json (label → ROM address for all 10,471 labels).

### TOOL-001 through TOOL-010: Linter and tooling suite
Created: lint_dc_decimal.js, lint_raw_ram_addresses.js, lint_raw_io_addresses.js,
lint_duplicate_constants.js, lint_loc_labels.js, lint_raw_obj_offsets.js,
run_checks.js, todos.schema.json, validate_todos.js, update_todos_stats.js.

### MOD-002, MOD-003, MOD-004: Function header sweep
Added register convention comment blocks (In/Out/Trashed) to all exported
functions with >3 call sites across src/*.asm.
Documented ProgramStateMap (states.asm) and GameplayStateDispatch (gameplay.asm).

### RAND-001 through RAND-007: Randomizer data documentation
Documented enemy stat table, shop format, player stat tables, item distribution,
encounter tables, story trigger flag system. Item shuffle map created.

### EDIT-001 through EDIT-003: Editor format documentation
Documented town map binary format, overworld RLE sector format, dungeon/cave
room format in src/mapdata.asm and supporting docs.
