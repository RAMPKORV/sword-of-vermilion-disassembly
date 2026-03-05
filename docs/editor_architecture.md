# Editor Architecture — Sword of Vermilion

## Overview

The game editor is a set of **Node.js CLI tools** that read game data from
the disassembly's JSON data files and ASM source, allow human-driven editing
with validation, and write changes back via the existing injection pipeline
(`tools/inject_game_data.js`, `tools/script_patch.js`).

Each editor is a standalone script covering one data domain. There is no
GUI; all editors use interactive terminal prompts (via Node.js `readline` or
similar). The tools follow the same ASM-reassembly approach as the randomizer:
edits are applied to ASM source, then rebuilt with `build.bat`.

---

## Approach: CLI Editors over ASM Sources

The same ASM-reassembly pipeline used by the randomizer applies here:

1. Load current data from `tools/data/*.json` (or parse ASM directly).
2. Present editable fields to the user in the terminal.
3. Validate changes against game constraints.
4. Write the modified data back to JSON and/or ASM.
5. Run `inject_game_data.js` + `verify.bat` to confirm a bit-perfect build.

**Why CLI over a web/GUI editor?**

- The entire project toolchain is Node.js CLI. A web app introduces a build
  system dependency (bundler, browser, static server) with no corresponding
  benefit for the expected user base (ROM hackers familiar with terminals).
- CLI tools are scriptable and composable with the existing linters and
  randomizer pipeline.
- All validation logic already exists in the JSON data structures; a GUI
  would duplicate this without adding correctness.

A web-based viewer/editor remains a plausible future direction, but is out of
scope for Phase 2.

---

## Data Flow

```
ASM source files (src/*.asm)
        │
        ▼  extract_game_data.js (once, or on demand)
tools/data/*.json           ◄──── editor tools read/write JSON
        │
        ▼  inject_game_data.js / script_patch.js / chest direct-patch
ASM source files (patched in-place)
        │
        ▼  build.bat + verify.bat
out.bin (rebuilt ROM)
```

The JSON files in `tools/data/` serve as the **canonical edit layer**.  
Editors never modify ASM source directly, except:
- `chest_randomizer.js` and the chest editor, which patch `src/towndata.asm`
  in-place (no JSON intermediate exists for chest data).
- `script_patch.js` / text editor, which patch dialogue strings directly.

---

## Editor Modules

| Task      | File                           | Data source                       | Injection method                  |
|-----------|--------------------------------|-----------------------------------|-----------------------------------|
| EDITOR-002 | `tools/editor/enemy_editor.js` | `tools/data/enemies.json`        | `inject_game_data.js --enemies`   |
| EDITOR-003 | `tools/editor/shop_editor.js`  | `tools/data/shops.json`          | `inject_game_data.js --shops`     |
| EDITOR-004 | `tools/editor/text_editor.js`  | `src/gamestrings.asm` via `script_disasm.js` | `script_patch.js`   |
| EDITOR-005 | `tools/editor/stats_editor.js` | `tools/data/player_stats.json`   | `inject_game_data.js --player-stats` |
| EDITOR-006 | `tools/editor/map_editor.js`   | `src/mapdata.asm` via `map_viewer.js` | Direct ASM patch (RLE recompress) |

All editors live in `tools/editor/` (new directory, does not exist yet).

---

## Common Editor Patterns

Every editor follows the same structure:

```
1. Load data (JSON or ASM parse)
2. Print summary of current state
3. Enter interactive edit loop:
   a. User selects an entry to edit
   b. Editor shows current field values
   c. User enters new value(s)
   d. Validate against constraints
   e. Apply change to in-memory data
   f. Offer to apply more edits or finish
4. On finish:
   a. Write modified JSON / ASM
   b. Run inject + verify (unless --no-rebuild)
   c. Print confirmation or error
```

All editors support:

| Option         | Description                                     |
|----------------|-------------------------------------------------|
| `--no-rebuild` | Skip inject + verify; leave data files modified |
| `--dry-run`    | Show what would change without writing          |
| `--json`       | Dump the full data set as JSON and exit         |
| `--help`       | Show usage                                      |

---

## Enemy Editor (`EDITOR-002`)

**File:** `tools/editor/enemy_editor.js`  
**Data:** `tools/data/enemies.json` (85 enemies)

Presents a searchable list of enemies. On selection, shows all stat fields
with their current values and valid ranges. User edits fields one at a time.

**Editable fields and constraints:**

| Field           | Type   | Min  | Max   | Notes                               |
|-----------------|--------|------|-------|-------------------------------------|
| `name`          | string | —    | —     | Display only; not injected           |
| `hp`            | int    | 1    | 65535 |                                     |
| `damage_per_hit`| int    | 1    | 255   |                                     |
| `speed`         | int    | 64   | 65535 |                                     |
| `xp_reward`     | int    | 1    | 65535 |                                     |
| `kim_reward`    | int    | 0    | 65535 |                                     |
| `behavior_flag` | hex    | 0x00 | 0xFF  | Bitmask; see `battledata.asm`        |
| `element`       | string | —    | —     | Must be a known element constant     |

Injection: `inject_game_data.js --enemies`

---

## Shop Editor (`EDITOR-003`)

**File:** `tools/editor/shop_editor.js`  
**Data:** `tools/data/shops.json` (16 shops)

Presents a list of towns with their shops. On selection, shows the shop's
item/equipment/magic slots. User can add, remove, or change items.

**Constraints:**

- Item IDs must match constants defined in `constants.asm` (`ITEM_*`).
- Equipment IDs must match `EQUIP_*` constants.
- Max items per shop determined by the original slot count (cannot grow a
  shop beyond its original size without ASM layout changes).
- A warning is shown if no Herbs or Vial are accessible in the first two towns.

Injection: `inject_game_data.js --shops`

---

## Text / Dialogue Editor (`EDITOR-004`)

**File:** `tools/editor/text_editor.js`  
**Depends on:** `tools/script_disasm.js`, `tools/script_patch.js`

Provides interactive editing of dialogue strings in `src/gamestrings.asm`
and `src/strings.asm`. Built on top of the existing `script_patch.js` pipeline.

**Workflow:**

```
1. List all *Str labels (from symbol_map.json)
2. User selects a label
3. Disassemble and display current text (via script_disasm.js)
4. User types replacement text (supports \n, \f, \p escape sequences)
5. Byte length is checked:
   - EQUAL length: safe, always allowed
   - SHORTER: padded with END opcode ($FF) — safe
   - LONGER: BLOCKED — would shift all subsequent label offsets and break
     bit-perfect build. User must use raw_ops mode or accept the limit.
6. Patch written via script_patch.js
```

**Escape sequences in text input:**

| Sequence | Meaning              | Byte |
|----------|----------------------|------|
| `\n`     | Newline              | $FE  |
| `\f`     | Continue (page flip) | $FD  |
| `\p`     | Player name          | $F7  |

**Length constraint:** this is the primary complexity of the text editor.
Strings cannot grow beyond their original byte length without relocating the
string. Relocation would break the bit-perfect build because string addresses
are hardcoded in dialogue dispatch tables. The editor enforces this limit
strictly; the only workaround is to shorten other nearby strings manually.

Injection: `script_patch.js --patch <generated_patch.json>`

---

## Player Stat Editor (`EDITOR-005`)

**File:** `tools/editor/stats_editor.js`  
**Data:** `tools/data/player_stats.json` (31 level-up entries)

Presents a level-by-level table of stat gains. User can edit individual
level entries or apply a global scaling factor.

**Editable fields per level:**

| Field       | Min | Max   |
|-------------|-----|-------|
| `mhp_gain`  | 0   | 255   |
| `mmp_gain`  | 0   | 255   |
| `str_gain`  | 0   | 255   |
| `ac_gain`   | 0   | 255   |
| `int_gain`  | 0   | 255   |
| `dex_gain`  | 0   | 255   |
| `luk_gain`  | 0   | 255   |
| `xp_to_next`| 1   | 65535 |

**Terminal graph:** the editor renders a simple ASCII bar chart of cumulative
HP/MP gain across all 31 levels for quick balance assessment.

Injection: `inject_game_data.js --player-stats`

---

## Map Editor (`EDITOR-006`)

**File:** `tools/editor/map_editor.js`  
**Depends on:** `tools/map_viewer.js` (RLE decompressor)

This is the most complex editor. It reads RLE-compressed map data from
`src/mapdata.asm`, decompresses it into a 2D tile grid, lets the user edit
tiles in a terminal grid view, recompresses with RLE, and patches the ASM.

**Map types supported:**

| Map type       | Source                  | Format                     |
|----------------|-------------------------|----------------------------|
| Overworld sector | `src/mapdata.asm`     | 48×32 RLE tile grid        |
| Town interior  | `src/towndata.asm` / `src/mapdata.asm` | Variable RLE grid |
| Dungeon room   | `src/mapdata.asm`       | Fixed-size RLE rooms       |

**RLE format (from AGENTS.md):**

- Byte `< $80`: output as-is
- Byte `>= $80`: read next byte, output it `($80 - byte)` times (wait: the
  formula is `(byte - $80 + 1)` run-length; see `map_viewer.js` for the
  canonical implementation)

**Constraints:**

- RLE-recompressed map must fit in the same byte count as the original
  compressed data, or the ASM layout shifts. The editor checks this and
  warns if the new compressed size differs.
- Tile IDs must be in the valid range for the map type (overworld vs dungeon
  use different tile sets).
- Cave room pointers are hardcoded; room sizes cannot change.

**Scope note:** Map editing is the highest-effort editor task. The terminal
grid view is limited to ~40 columns (tile IDs truncated to 1 char). A full
graphical tile editor is out of scope for Phase 2.

---

## Validation Strategy

All editors share a common validation philosophy:

1. **Reject out-of-range values** immediately with a clear message.
2. **Warn on constraint violations** (e.g., shop has no healing items in
   early towns) but allow the user to proceed.
3. **Abort on layout-breaking changes** (e.g., text longer than original,
   map recompression size mismatch) — the user must shorten or rethink.
4. **Always run `verify.bat` as final gate** — a bit-perfect build is
   definitive proof of correctness.

---

## Known Limitations

- All editors are **non-interactive batch mode only for injection.** There is
  no undo within a session beyond reloading the original JSON or using git.
- The text editor cannot increase string length. This limits dialogue edits
  to equal-or-shorter replacements.
- The map editor's terminal grid is low-fidelity; consider using `map_viewer.js`
  output and an external hex/text editor for complex map work.
- Magic spell data (`tools/data/magic_tables.json`) does not have a dedicated
  editor — magic tables are small enough to edit via `inject_game_data.js
  --magic` after hand-editing the JSON.
- Service prices (`tools/data/service_prices.json`) are similarly small; no
  dedicated editor is planned.

---

## Implementation Order

| Priority | Task      | Effort    | Notes                                    |
|----------|-----------|-----------|------------------------------------------|
| 1        | EDITOR-001 | medium   | This document (done)                     |
| 2        | EDITOR-002 | large    | Enemy editor (richest data, most useful) |
| 3        | EDITOR-003 | medium   | Shop editor                              |
| 4        | EDITOR-004 | large    | Text editor (complex length constraint)  |
| 5        | EDITOR-005 | medium   | Stats editor (simplest inject path)      |
| 6        | EDITOR-006 | very large | Map editor (RLE complexity)            |

---

## See Also

- `docs/randomizer_architecture.md` — shared PRNG and ASM-reassembly approach
- `tools/inject_game_data.js` — data injection pipeline
- `tools/extract_game_data.js` — data extraction pipeline
- `tools/script_patch.js` — dialogue patch pipeline
- `tools/script_disasm.js` — dialogue disassembler
- `tools/map_viewer.js` — RLE map decompressor
- `docs/sram_format.md` — save slot format reference
- `docs/npc_format.md` — NPC and shop data format reference
