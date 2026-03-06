# Palette Format and Assignment System

Sword of Vermilion (Sega Genesis) — palette data reference.

---

## Genesis Hardware Background

The Genesis VDP holds **4 palette lines** (CRAM), each with **16 colors**, for 64 colors
on-screen simultaneously.  Each color entry is a 16-bit word:

```
Bit:  15-12  11-9   8     7-5    4     3-1    0
       0000  BBB    0   GGG      0   RRR      0
```

- Three bits per channel (R, G, B), stored in bits 3–1 of each nibble group.
- The low bit of each channel is always 0; valid channel values are 0, 2, 4, 6, 8, A, C, E.
- Bit 0 is always 0; bits 12–15 are always 0.
- Black = `$0000`.  Full white = `$0EEE`.

**Palette line assignment in hardware:**
- Plane A tiles use palette lines selected by bits 13–14 of each tilemap entry.
- Plane B tiles similarly.
- Sprites use palette lines selected by bits 9–10 of each sprite attribute entry.
- Color index 0 in every palette line is the universal transparent/backdrop color.

---

## Palette Data File

```
data/art/palettes/palette_data.bin   (6,272 bytes)
```

- **196 entries**, each exactly **32 bytes** (16 colors × 2 bytes per color, big-endian).
- Indexed linearly: entry N starts at byte offset `N × 32`.
- Assembled into ROM via a single `incbin` at `PaletteDataTable` (`src/script.asm:4127`).

---

## RAM Layout

All palette state lives in the low RAM region `$FFFFC000–$FFFFC0BD`.

### Palette Line Buffers

| Address        | Symbol                   | Size     | Purpose                                      |
|----------------|--------------------------|----------|----------------------------------------------|
| `$FFFFC000`    | `Palette_line_0_buffer`  | 32 bytes | CRAM line 0 staging buffer                   |
| `$FFFFC020`    | `Palette_line_1_buffer`  | 32 bytes | CRAM line 1 staging buffer                   |
| `$FFFFC040`    | `Palette_line_2_buffer`  | 32 bytes | CRAM line 2 staging buffer                   |
| `$FFFFC060`    | `Palette_line_3_buffer`  | 32 bytes | CRAM line 3 staging buffer                   |

The four buffers are contiguous (128 bytes total, `$FFFFC000–$FFFFC07F`).  DMA to CRAM
always transfers all 128 bytes from `Palette_line_0_buffer`.

### Palette Line Index Registers

| Address        | Symbol                   | Width | Purpose                                      |
|----------------|--------------------------|-------|----------------------------------------------|
| `$FFFFC080`    | `Palette_line_0_index`   | .w    | Index into `PaletteDataTable` for line 0     |
| `$FFFFC082`    | `Palette_line_1_index`   | .w    | Index into `PaletteDataTable` for line 1     |
| `$FFFFC084`    | `Palette_line_2_index`   | .w    | Index into `PaletteDataTable` for line 2     |
| `$FFFFC086`    | `Palette_line_3_index`   | .w    | Index into `PaletteDataTable` for line 3     |

### Fade and Cycle Control

| Address        | Symbol                         | Width | Purpose                                                  |
|----------------|--------------------------------|-------|----------------------------------------------------------|
| `$FFFFC08C`    | `Palette_fade_step_counter`    | .w    | Steps completed in current fade-out (0–7)                |
| `$FFFFC08E`    | `Fade_out_lines_mask`          | .b    | Bitmask: bits 0–3 select which lines are fading out      |
| `$FFFFC096`    | `Palette_line_1_index_saved`   | .w    | Saved line 1 index (restored after certain transitions)  |
| `$FFFFC098`    | `Palette_line_2_cycle_base`    | .w    | Base palette index for line 2 cycle animation            |
| `$FFFFC09A`    | `Palette_line_2_cycle_index_1` | .w    | Cycle step 1 palette index (0 = end of cycle)            |
| `$FFFFC09C`    | `Palette_line_2_cycle_index_2` | .w    | Cycle step 2 palette index                               |
| `$FFFFC09E`    | `Palette_cycle_frame_counter`  | .b    | Frame counter for palette cycle timing                   |
| `$FFFFC09F`    | `Palette_line_2_cycle_step`    | .b    | Current cycle step index (0–2)                           |
| `$FFFFC0A4`    | `Palette_fade_tick_counter`    | .w    | Raw tick counter; used to derive per-step timing         |
| `$FFFFC0A8`    | `Palette_fade_in_step`         | .w    | Steps completed in current cross-fade-in (0–7)           |
| `$FFFFC0AA`    | `Fade_in_lines_mask`           | .b    | Bitmask: bits 0–3 select which lines are cross-fading in |
| `$FFFFC0AB`    | `Palette_fade_in_mask`         | .b    | Bitmask: bits 0–3 select which lines are fading in       |
| `$FFFFC0AC`    | `Palette_line_0_fade_target`   | .w    | Fade-in target palette index for line 0                  |
| `$FFFFC0AE`    | `Palette_line_1_fade_target`   | .w    | Fade-in target palette index for line 1                  |
| `$FFFFC0B0`    | `Palette_line_2_fade_target`   | .w    | Fade-in target palette index for line 2                  |
| `$FFFFC0B2`    | `Palette_line_3_fade_target`   | .w    | Fade-in target palette index for line 3                  |
| `$FFFFC0B4`    | `Palette_fade_in_step_counter` | .w    | Steps completed in current fade-in (0–7)                 |
| `$FFFFC0B6`    | `Palette_line_0_fade_in_target`| .w    | Cross-fade target palette index for line 0               |
| `$FFFFC0B8`    | `Palette_line_1_fade_in_target`| .w    | Cross-fade target palette index for line 1               |
| `$FFFFC0BA`    | `Palette_line_2_fade_in_target`| .w    | Cross-fade target palette index for line 2               |
| `$FFFFC0BC`    | `Palette_line_3_fade_in_target`| .w    | Cross-fade target palette index for line 3               |
| `$FFFFC0BD`    | `Palette_buffer_dirty`         | .b    | Bit 7 = buffer needs DMA to CRAM this VBlank             |

---

## Key Functions

All palette management code lives in `src/script.asm:3604–4128`.

### `LoadPalettesFromTable` (src/script.asm:3661)

Copies all four palette lines from `PaletteDataTable` into the four line buffers using
the current `Palette_line_X_index` values, then sets `Palette_buffer_dirty` bit 7 so
the next `UpdatePaletteBuffer` call uploads them to CRAM.

**Guards:** returns immediately (no copy) if any fade is active:
- `Palette_fade_in_mask` ≠ 0
- `Fade_out_lines_mask` ≠ 0
- `Fade_in_lines_mask` ≠ 0

**Addressing:** index N → byte offset `N × 32` into `PaletteDataTable` (achieved via
`ASL.w #5, D1` then indexed addressing).

**Usage:** called from ~68 sites across the codebase whenever the active scene's palette
indices change (room transitions, battle setup, spell effects, cutscenes, etc.).

### `LoadPaletteByIndex` (src/script.asm:4017)

Copies a single 32-byte palette entry from `PaletteDataTable[D1]` into the buffer
pointed to by A1.  Used internally by the cross-fade system to reload non-fading lines.

### `UpdatePaletteBuffer` (src/script.asm:3611)

Called each VBlank (from the VBlank handler or main loop).  Dispatches based on active
fade flags:

| Condition | Action |
|-----------|--------|
| `Palette_fade_in_mask` set | Run fade-in-from-black step (`BuildFadeInTable_Store_Loop`) |
| `Fade_out_lines_mask` set  | Run fade-to-black step (`LoadPalettesFromTable_Return_Loop`) |
| `Fade_in_lines_mask` set   | Run cross-fade step (`BuildFadeTable_Store_Loop`) |
| None set, dirty bit set    | DMA all 128 bytes to CRAM immediately |
| None set, dirty bit clear  | No-op |

### `DecrementPaletteRGBValues` (src/script.asm:3746)

Steps one 16-color palette line one level toward black.  For each color entry, subtracts
one step from each non-zero channel:
- Blue channel: −`$0200` per step (bits 11–8)
- Green channel: −`$0020` per step (bits 7–4)
- Red channel: −2 per step (bits 3–0)

Called repeatedly each frame for lines selected by `Fade_out_lines_mask`.  Completes
after 8 steps (all channels reach 0).

### `ShiftPaletteTowardsTarget` (src/script.asm:3858)

Moves one 16-color palette line one step toward a target palette (for cross-fade).  Each
channel is independently clamped toward the target value by one step per frame.  Used
by the `Fade_in_lines_mask` system.

### `FadePaletteTowardsTarget` (src/script.asm:4034)

Like `ShiftPaletteTowardsTarget` but used by the `Palette_fade_in_mask` system (the
fade-in-from-black path).  Adjusts R/G/B channels independently toward the target.

### `UpdatePaletteCycle` (src/cutscene.asm:1026)

Animates palette line 2 by cycling through up to 3 indices every 8 frames:
1. Increments `Palette_cycle_frame_counter` each call.
2. Fires only on the rising edge of bit 3 (every 8 frames).
3. Advances `Palette_line_2_cycle_step` (0 → 1 → 2 → 0).
4. Reads the resolved index from `[Palette_line_2_cycle_base + step*2]`; if zero,
   resets to step 0 and uses the base entry.
5. Writes to `Palette_line_2_index` and calls `LoadPalettesFromTable`.

Used for torch/fire flicker animations in towns and caves.

---

## Fade System Details

### Fade to Black (`Fade_out_lines_mask`)

1. Set `Fade_out_lines_mask` with a 4-bit mask (bit N = fade line N).
2. `UpdatePaletteBuffer` calls `DecrementPaletteRGBValues` for each selected line
   every 8 ticks (one step per 8 frames).
3. After 8 steps, all channels reach 0.  `BuildFadeTable_Store_Loop2` fires:
   - Clears `Fade_out_lines_mask` and `Palette_fade_step_counter`.
   - Zeroes all four `Palette_line_X_index` values.
   - DMAs the all-black buffers to CRAM.

### Cross-Fade Between Palettes (`Fade_in_lines_mask`)

Used to transition between two named palettes (e.g., a town palette change).

1. Set `Palette_line_X_fade_target` to the destination index for each line.
2. Set `Fade_in_lines_mask` with the relevant line bits.
3. `UpdatePaletteBuffer` calls `ShiftPaletteTowardsTarget` for each selected line
   every 8 ticks.
4. After 8 steps, `BuildFadeInTable_Store_Loop2` fires:
   - Copies `Palette_line_X_fade_target` into `Palette_line_X_index` for each
     selected line.
   - Clears `Fade_in_lines_mask` and `Palette_fade_in_step`.
   - DMAs final palette to CRAM.

### Fade In from Black (`Palette_fade_in_mask`)

Used for scene entrances (e.g., loading a dungeon floor, entering battle).

1. Set `Palette_line_X_fade_in_target` to the destination index.
2. Set `Palette_fade_in_mask` with the relevant line bits.
3. `UpdatePaletteBuffer` calls `FadePaletteTowardsTarget` for selected lines every 8
   ticks; unselected lines are refreshed from their current `Palette_line_X_index`
   via `LoadPaletteByIndex`.
4. After 8 steps, `FadePaletteTowardsTarget_NextEntry_Loop` fires:
   - Copies `Palette_line_X_fade_in_target` into `Palette_line_X_index`.
   - Clears `Palette_fade_in_mask` and `Palette_fade_in_step_counter`.
   - DMAs final palette to CRAM.

### Fade Timing

All three fade systems use the same bit-3 edge-detect trick to fire once every 8 ticks:

```asm
ADDQ.w  #1, Palette_fade_tick_counter.w
MOVE.w  Palette_fade_tick_counter.w, D0
MOVE.w  D0, D1
SUBQ.w  #1, D1
EOR.w   D0, D1          ; D1 = bits that changed from (counter-1) to counter
BTST.l  #3, D1          ; did bit 3 change?
BEQ.w   <skip>          ; no → skip this step
```

This fires on every 8th increment (when the counter's bit 3 transitions 0→1).

---

## DMA Upload to CRAM

All palette flushing routes share the same VDP DMA sequence:

1. Stop Z80 (`stopZ80` macro).
2. Call `InitVdpDmaRamRoutine` to install the DMA trampoline in RAM.
3. Set VDP auto-increment to 2 (`VDP register 15 = 2`).
4. Enable DMA in VDP register 1 (set bit 4).
5. Write DMA source/length registers (`$9340`, `$9400`, `$9500`, `$96E0`, `$977F`).
6. Write the CRAM DMA command longword (`VDP_DMA_CMD_CRAM`) to `Vdp_dma_cmd`.
7. Call `Vdp_dma_ram_routine` (self-modifying code in RAM).
8. Clear DMA enable bit.
9. Restart Z80 (`startZ80` macro).

The source is always `Palette_line_0_buffer` ($FFFFC000), length always 128 bytes
(all 4 lines), destination always CRAM offset 0.

---

## Town Palette Configuration

Each town has a dedicated palette configuration table entry (`TownPaletteConfigTable`,
`src/cutscene.asm:1062`).  Each entry contains:

| Word offset | Meaning |
|-------------|---------|
| 0           | `Palette_line_1_index` — tile graphics palette for this town |
| 1           | `Palette_line_2_cycle_base` — primary NPC/object palette (cycle step 0) |
| 2+          | `Palette_line_2_cycle_index_1`, `_2` — fire/torch animation cycle steps (`$0000` = end) |

The `TownPaletteLine1IndexTable` (`src/cutscene.asm:1085`) provides an alternate
per-town line 1 index array used in some transition paths.

---

## Named Palette Index Constants

Defined in `constants.asm:2178–2221`.  All are indices into `PaletteDataTable`.

### Town / Overworld

| Constant                      | Index   | Usage                                              |
|-------------------------------|---------|----------------------------------------------------|
| `PALETTE_IDX_TOWN_TILES`      | `$0012` | Town tile palette (line 0): torches, walls, floor  |
| `PALETTE_IDX_TOWN_HUD`        | `$0011` | Town HUD palette (line 3): player sprite, status   |
| `PALETTE_IDX_TOWN_DARK`       | `$0083` | Carthahena dark palette (Tsarkon rule)             |
| `PALETTE_IDX_BATTLE_OUTDOOR`  | `$0013` | Outdoor battle terrain palette (line 0)            |
| `PALETTE_IDX_OVERWORLD_LINE1` | `$0037` | Overworld map palette line 1                       |
| `PALETTE_IDX_OVERWORLD_LINE2` | `$0038` | Overworld map palette line 2 / cave floor base     |

### Cave / Dungeon

| Constant                    | Index   | Usage                                        |
|-----------------------------|---------|----------------------------------------------|
| `PALETTE_IDX_CAVE_WALLS`    | `$0036` | Cave wall tile palette (line 0)              |
| `PALETTE_IDX_CAVE_FLOOR`    | `$0038` | Cave floor palette (line 2)                  |
| `PALETTE_IDX_CAVE_FLOOR_LIT`| `$0048` | Cave floor with Light spell active (line 1)  |
| `PALETTE_IDX_CAVE_ANIM_BASE`| `$0040` | Cave torch/fire animation start (line 2)     |
| `PALETTE_IDX_CAVE_ANIM_END` | `$0047` | Cave torch/fire animation end (forward loop) |
| `PALETTE_IDX_CAVE_ANIM_ALT` | `$003F` | Cave torch/fire animation alt end (reverse)  |
| `PALETTE_IDX_CAVE_POISON`   | `$0072` | Cave poison tint (line 0)                    |

### Title Screen

| Constant                       | Index   | Usage                                     |
|--------------------------------|---------|-------------------------------------------|
| `PALETTE_IDX_TITLE_LOGO`       | `$0029` | Title screen logo palette (line 1)        |
| `PALETTE_IDX_TITLE_TILES`      | `$0027` | Title screen tile palette (line 3)        |
| `PALETTE_IDX_TITLE_BG`         | `$0028` | Title screen background palette (line 2)  |
| `PALETTE_IDX_TITLE_LIGHTNING`  | `$0030` | Title screen lightning flash (line 0)     |

### Prologue / Name Entry

| Constant                          | Index   | Usage                                    |
|-----------------------------------|---------|------------------------------------------|
| `PALETTE_IDX_PROLOGUE_BG`         | `$004F` | Prologue background (lines 0, 2)         |
| `PALETTE_IDX_PROLOGUE_SCENE`      | `$0052` | Prologue scene tile palette (lines 1, 3) |
| `PALETTE_IDX_PROLOGUE_LINE1`      | `$0050` | Prologue line 1 fade target              |
| `PALETTE_IDX_PROLOGUE_LINE2`      | `$0051` | Prologue line 2 fade target              |
| `PALETTE_IDX_NAMEENTRY_BG`        | `$0032` | Name entry screen background             |
| `PALETTE_IDX_NAMEENTRY_GLOW1`     | `$0033` | Name entry glow animation 1              |
| `PALETTE_IDX_NAMEENTRY_GLOW2`     | `$0034` | Name entry glow animation 2              |

### Ending / Special

| Constant                          | Index   | Usage                                       |
|-----------------------------------|---------|---------------------------------------------|
| `PALETTE_IDX_ALL_WHITE`           | `$0084` | All-white flash (ending/lightning)          |
| `PALETTE_IDX_ALL_BLACK`           | `$0094` | All-black palette (screen blank)            |
| `PALETTE_IDX_ENDING_FIRE`         | `$0095` | Ending sequence fire palette                |
| `PALETTE_IDX_ENDING_TEXT_BG`      | `$0085` | Ending outro text background                |
| `PALETTE_IDX_ENDING_CURSOR_MIN`   | `$0096` | Ending cursor blink range start             |
| `PALETTE_IDX_ENDING_CURSOR_MAX`   | `$009D` | Ending cursor blink range end               |

---

## Reading Palette Data (Node.js)

```js
const fs = require('fs');
const data = fs.readFileSync('data/art/palettes/palette_data.bin');
const ENTRY_SIZE = 32;
const NUM_ENTRIES = data.length / ENTRY_SIZE; // 196

function readPalette(index) {
  const offset = index * ENTRY_SIZE;
  const colors = [];
  for (let i = 0; i < 16; i++) {
    const word = data.readUInt16BE(offset + i * 2);
    const r = (word >> 1) & 0x7;   // bits 3–1
    const g = (word >> 5) & 0x7;   // bits 7–5
    const b = (word >> 9) & 0x7;   // bits 11–9
    colors.push({ word, r, g, b });
  }
  return colors;
}

// Example: dump palette $12 (PALETTE_IDX_TOWN_TILES)
console.log(readPalette(0x12));
```

---

## Writing Palette Data

To replace palette entry N (32 bytes):

```js
const fs = require('fs');
const data = fs.readFileSync('data/art/palettes/palette_data.bin');
const offset = N * 32;
// colors: array of 16 Genesis color words (big-endian)
for (let i = 0; i < 16; i++) {
  data.writeUInt16BE(colors[i], offset + i * 2);
}
fs.writeFileSync('data/art/palettes/palette_data.bin', data);
```

After any change to this file, run `cmd //c verify.bat` — the build must remain
bit-perfect.

---

## Summary

```
palette_data.bin
  196 entries × 32 bytes = 6,272 bytes
  Entry N → PaletteDataTable + N*32
  16 colors per entry, 2 bytes per color (Genesis BGR format)

RAM at runtime:
  $FFFFC000–$FFFFC07F   4 × 32-byte line buffers (DMA source)
  $FFFFC080–$FFFFC087   4 × .w palette index registers
  $FFFFC08E             Fade_out_lines_mask  (bits 0–3)
  $FFFFC0AA             Fade_in_lines_mask   (bits 0–3)
  $FFFFC0AB             Palette_fade_in_mask (bits 0–3)
  $FFFFC0BD             Palette_buffer_dirty (bit 7)

Key functions (src/script.asm):
  LoadPalettesFromTable    — reload all 4 lines from indexed table
  UpdatePaletteBuffer      — VBlank dispatcher: fade step or DMA
  DecrementPaletteRGBValues — one fade-to-black step per line
  ShiftPaletteTowardsTarget — one cross-fade step per line
  FadePaletteTowardsTarget  — one fade-in step per line
  LoadPaletteByIndex        — copy one entry to buffer
  UpdatePaletteCycle (src/cutscene.asm) — 3-step torch animation
```
