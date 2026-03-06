# Onboarding Guide: Sword of Vermilion Disassembly

Welcome. This guide takes you from zero to a working, verified local build and
explains where to look first when exploring or modifying the disassembly.

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Git | any recent | For cloning and committing |
| Node.js | v18+ (v25 in CI) | Scripts in `tools/` are Node.js only — no Python |
| Windows (or WSL/Git Bash) | — | `asm68k.exe` is a Windows binary; WSL/Git Bash users call it via `cmd //c` |

`asm68k.exe` is already committed to the repo root — you do not need to
install it separately.

---

## Step 1: Clone the repo

```bash
git clone <repo-url>
cd vermilion
```

---

## Step 2: Build and verify

```batch
verify.bat
```

From Git Bash or WSL:

```bash
cmd //c verify.bat
```

A successful run prints:

```
BUILD VERIFIED - ROM IS BIT-PERFECT
```

and exits with code 0. If it fails on a fresh clone, check that you are in the
correct directory and that `asm68k.exe` is present in the project root.

See [build_workflow.md](build_workflow.md) for a full explanation of the
build pipeline and what `verify.bat` actually checks.

---

## Step 3: Understand the file structure

```
vermilion/
├── vermilion.asm        # Top-level entry: ~30 include directives only
├── header.asm           # ROM header, 68000 vector table, includes macros + constants
├── init.asm             # EntryPoint, MainGameLoop, WaitForVBlank
├── constants.asm        # ALL symbolic constants and RAM addresses (~2976 lines)
├── macros.asm           # Assembly macros (~280 lines)
├── src/                 # 28 split source modules
│   ├── core.asm         #   ErrorTrap, InitVDP, ClearRAM, object init
│   ├── vblank.asm       #   Vertical blank interrupt handler
│   ├── states.asm       #   Program state machine (logo, title, name entry…)
│   ├── gameplay.asm     #   Gameplay state machine (town, overworld, dungeon, battle)
│   ├── player.asm       #   Player movement, input, collision
│   ├── npc.asm          #   NPC loading, behavior, dialogue dispatch
│   ├── enemy.asm        #   Enemy AI, encounter system
│   ├── combat.asm       #   Combat/battle mechanics
│   ├── script.asm       #   Dialogue script interpreter
│   ├── items.asm        #   Item use and inventory
│   ├── magic.asm        #   Magic spellcasting
│   ├── sram.asm         #   Save/load SRAM persistence
│   ├── strings.asm      #   UI strings
│   ├── gamestrings.asm  #   Dialogue text strings
│   ├── shopdata.asm     #   Shop inventory and pricing data
│   ├── battledata.asm   #   Battle/encounter data tables
│   ├── playerstats.asm  #   Player stat tables, level-up data
│   ├── mapdata.asm      #   Map/sector data (RLE compressed)
│   ├── gfxdata.asm      #   Graphics tile/sprite data
│   ├── sound.asm        #   Sound driver and audio data
│   └── …               #   (8 more: dungeon, boss, battle_gfx, cutscene, etc.)
├── data/                # Binary assets: art/palettes, art/tiles, maps/, sound/
├── tools/               # Node.js lint and index scripts
├── docs/                # Documentation (you are here)
├── notes.txt            # Original research notes: RAM locations, item list, map format
├── build.bat            # Build script
├── verify.bat           # SHA256 bit-perfect verification
└── asm68k.exe           # Assembler binary (committed)
```

**`vermilion_test.asm`** is a reference-only copy of the original unsplit
disassembly. It is not part of the build. Do not edit it.

---

## Step 4: Read the five most important files

Work outward from these:

| File | Why it matters |
|------|---------------|
| `constants.asm` | Every RAM address and symbolic constant lives here. Before using a raw address, search here first. |
| `init.asm` | The boot sequence: `EntryPoint` → `MainGameLoop` → `WaitForVBlank`. The entry point for tracing any execution path. |
| `macros.asm` | All assembler macros. Check here before writing repeated instruction sequences. |
| `notes.txt` | Original research notes: RAM map, item list, map tile format, and other discoveries. |
| `docs/module_boundaries.md` | Which code belongs in which `src/` file; the rules for adding to or splitting modules. |

---

## Step 5: Make a change

Follow the single-change workflow:

1. Edit one file.
2. Run `cmd //c verify.bat`.
3. Exit 0 → `git add <file> && git commit -m "ID: Description (bit-perfect)"`.
4. Exit 1 → see [debugging_verify_failures.md](debugging_verify_failures.md).

The most common cause of a broken build after an edit is **converting hex
literals to decimal** in `dc.b`/`dc.w`/`dc.l` data. Keep all data in hex.
See [asm68k_quirks.md](asm68k_quirks.md) for the full explanation.

---

## Running the linters

```bash
node tools/run_checks.js
```

This runs all lint scripts and prints a pass/fail summary. All checks must
pass before committing. See [contributing.md](contributing.md) for the
individual script list.

---

## Further reading

| Doc | Contents |
|-----|---------|
| [build_workflow.md](build_workflow.md) | Full build pipeline, flags, listing file usage |
| [contributing.md](contributing.md) | Code style: labels, instructions, data directives, macros |
| [asm68k_quirks.md](asm68k_quirks.md) | Assembler-specific gotchas (hex vs decimal, macro arg casing) |
| [debugging_verify_failures.md](debugging_verify_failures.md) | Step-by-step SHA256 mismatch diagnosis |
| [module_boundaries.md](module_boundaries.md) | Module ownership rules |
| [glossary.md](glossary.md) | Key terms: VDP, DMA, RLE, SRAM, etc. |
| [data_table_style.md](data_table_style.md) | How to write and annotate data tables |
| [change_checklist.md](change_checklist.md) | Pre-commit safety checklist |
