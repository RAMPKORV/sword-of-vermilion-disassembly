# Project Roadmap — Sword of Vermilion Disassembly

This document describes the three phases of the project and the key milestones for each.
The detailed task list lives in `todos.json` — this document provides the high-level arc.

---

## Phase 1: Clean, Bit-Perfect Disassembly (Complete)

**Goal:** Transform the raw single-file disassembly into a clean, maintainable,
fully-labeled, and well-documented source codebase that assembles bit-perfectly.

### Milestones

- **Label coverage:** All 10,471 labels named (0 `loc_` labels remain). *Done.*
- **Constants cleanup:** All hardcoded RAM/I/O addresses replaced with symbolic
  constants from `constants.asm`. Duplicate constant blocks removed. *Done.*
- **Macro adoption:** All identified macro adoption opportunities applied
  (`DMAFillVRAM`, `CheckButton`, `initObjects`, `objectInitGroup`, `PlaySound`, etc.). *Done.*
- **Code deduplication:** Major DRY violations resolved or documented with bit-perfect
  constraint explanations. *Done.*
- **Magic number elimination:** VDP command words, DMA parameters, and hardware values
  replaced with named constants or the `vdpCmd`/`dmaCmd` macros. *Done.*
- **Dead code annotation:** Unreachable functions and orphan bytes documented. *Done.*
- **Documentation:** All major systems have function headers, register conventions,
  and comment blocks (states.asm, init.asm, battle_gfx.asm, gameplay.asm, dungeon.asm,
  vblank.asm, script.asm, etc.). *Done.*
- **RAM/struct documentation:** Object struct layout, Event_triggers, sprite pipeline,
  controller input, scroll system all fully documented. *Done.*
- **Tooling:** Node.js linters, index generators, build coverage tools. *Done.*
- **Contributor docs:** Contributing guide, debug playbook, ASM68K quirks doc,
  build workflow doc, module boundaries, glossary, data table style guide. *Done.*

**Remaining Phase 1 tasks** (see `todos.json` for details):
- `DOC-006`: Rename remaining meaningless sub-label suffixes (low priority, large scope)
- `DATA-001`, `DATA-002`: Rename 3,771 gfxdata.asm disassembler-artifact labels (very large)
- `ARCH-001`: Split `constants.asm` into logical sections (optional)
- `LABEL-006`: Replace intent-free sub-label suffixes project-wide (optional)

---

## Phase 2: Randomizer Tooling (In Progress)

**Goal:** Enable a ROM randomizer that can shuffle items, enemy stats, encounter
tables, and story trigger progression while maintaining a completable game.

### Milestones

- **Data documentation:** Enemy stat tables, shop data, player stat tables, item
  distribution, encounter tables, story trigger system all documented. *Done.*
- **Script VM:** Full opcode table, runtime RAM state, text encoding documented. *Done.*
  Script bytecode disassembler (VM-006), string export tool (VM-007): *Pending.*
- **Index tooling:** Symbol map, function inventory, callsite index. *Partially done.*
  - `LABEL-005`: Callsite index generator — *Pending.*
  - `RAM-008`: RAM symbol index export — *Pending.*
  - `VM-004`: Script entry points to callers map — *Pending.*
- **Chest catalog:** `RAND-008` — all treasure chest contents and locations. *Pending.*
- **Connectivity graph:** `RAND-009` — town/dungeon connectivity and access gates. *Pending.*
- **Enemy graphics:** `RAND-006` — VRAM slot constraints for enemy sprite swapping. *Pending.*
- **Data extraction scripts:** `EDIT-006` — Node.js tools to export game data as JSON. *Pending.*
- **Data injection scripts:** `EDIT-007` — Node.js tools to write edited JSON back to ASM. *Pending.*

### Key Technical Constraints
- Randomizer patches the ROM binary, not the ASM source.
- All data addresses are provided by `tools/index/symbol_map.json`.
- RNG seed injection point: write a non-zero `.l` to `Rng_state` ($FFFFC0A0)
  before `StartupSequence`. Documented in `init.asm` and `battle_gfx.asm`.

---

## Phase 3: Game Editor (Future)

**Goal:** A visual editor for maps, NPCs, dialogue, items, and graphics.
The editor reads/writes JSON produced by Phase 2 extraction scripts.

### Milestones

- **Map formats documented:** Overworld (RLE), town (binary tilemap), dungeon/cave.
  *Done.* See `src/mapdata.asm` header.
- **Sprite/tile art format:** `EDIT-004` — document tile and sprite binary format. *Pending.*
- **Palette system:** `EDIT-005` — palette format and assignment. *Pending.*
- **NPC placement format:** `EDIT-008` — NPC data table format for placement editor. *Pending.*
- **SRAM format:** `EDIT-009` — save game format for a save editor. *Pending.*
- **Sound format:** `EDIT-010` — music/SFX data format for a music editor. *Pending.*
- **Script tools:** `VM-006`, `VM-007`, `VM-010` — disassembler, string exporter, patch injector. *Pending.*
- **Dialogue catalog:** `STR-001`, `STR-002`, `STR-003` — NPC dialogue audit and string index. *Pending.*

---

## Links

- Detailed task list: `todos.json`
- Build workflow: `docs/build_workflow.md`
- Contributing guide: `docs/contributing.md`
- Module responsibilities: `docs/module_boundaries.md`
- Glossary: `docs/glossary.md`
