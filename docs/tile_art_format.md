# Tile and Sprite Art Format — Sword of Vermilion

Reference for `src/gfxdata.asm` and the binary assets in `data/art/tiles/`.

---

## Genesis / VDP Tile Format

Every tile on the Sega Genesis is an 8×8-pixel cell stored in the YM7101 (VDP) VRAM.
Each pixel is 4 bits (one of 16 palette colors), so one tile = 32 bytes.

**Byte layout (row-major, 4bpp):**

```
Byte 0:  pixels [0,0] and [0,1]  — high nibble = column 0, low nibble = column 1
Byte 1:  pixels [0,2] and [0,3]
...
Byte 7:  pixels [0,14] and [0,15]    (wait — tiles are 8 wide, not 16)
```

Corrected: each row is 4 bytes:

```
Row 0: byte 0 = (col0<<4)|col1,  byte 1 = (col2<<4)|col3
       byte 2 = (col4<<4)|col5,  byte 3 = (col6<<4)|col7
Row 1: bytes 4-7
...
Row 7: bytes 28-31
Total: 32 bytes per tile
```

Pixel value 0 is transparent for sprites; value 0 in background tiles uses palette
color 0 (usually the background color).

---

## RLE Compression

Magic effect tiles and some font data use a simple RLE scheme (also used for map data):

| Byte value | Meaning |
|------------|---------|
| `$00`–`$7F` | **Literal**: output this byte as-is |
| `$80`–`$FF` | **Run**: output the **next** byte (`$80 − value`) times |

Note: a control byte of `$80` would mean repeat the next byte 0 times (no output).
The minimum useful run is `$81` (1 repeat — equivalent to a literal), so in practice
runs start at `$82` (2 repeats) or higher.

Uncompressed output is raw VDP tile data (32 bytes per tile).

---

## Data Organisation in `src/gfxdata.asm`

The file contains four kinds of structures:

### 1. Binary tile blobs (`incbin`)

Raw or RLE-compressed 4bpp tile data loaded directly from external `.bin` files.
Labels at fixed byte offsets within the blob let the pointer tables reference individual
frames without repeating the data.

```asm
LoadBattleTilesToBuffers_Data2_Gfx_429F0:
    incbin "data/art/tiles/battle/data2_gfx.bin"
LoadBattleTilesToBuffers_Data2_Gfx_42A08 equ LoadBattleTilesToBuffers_Data2_Gfx_429F0+$18
; etc.
```

### 2. Pointer tables (`dc.l` arrays)

Arrays of 32-bit absolute ROM pointers, one per animation frame or graphic variant.
The calling code indexes into the table by frame/variant number, then DMA-transfers
the pointed-to tile data into VRAM.

### 3. Tile-index remap arrays (`dc.b`)

Byte arrays that map **logical tile slots** (the position in the VRAM sprite table
where the game expects to find a tile) to **physical tile indices** in the blob
(the actual order tiles are stored in the binary).

```asm
LoadPlayerOverworldGraphics_Data:
    dc.b  $00,$03,$06,$09,$01,$04,$07,$0A,$02,$05,$08,$0B,...
```
Each byte = physical tile index in the incbin blob for that logical slot.
These allow the game to reorder or share tiles without storing them multiple times.

### 4. Inline compressed tile data (`dc.b`)

Magic effect graphics are stored as RLE-compressed tile data inline in the source
(not in a separate `.bin` file). Each magic section also has a remap array followed
by the compressed blobs and a pointer table for each spell frame.

---

## Tile Binary Categories

### `data/art/tiles/battle/`

| File | Size | Notes |
|------|------|-------|
| `data2_gfx.bin` | 852 B | Battle background tile fragments (set 2) |
| `data4_gfx.bin` | 1962 B | Battle background tile fragments (set 4) |
| `data6_gfx_1.bin` | 3103 B | Battle tile set 6, part 1 |
| `data6_gfx_2.bin` | 3334 B | Battle tile set 6, part 2 |
| `excalabria_gfx.bin` | 5066 B | Excalabria boss battle tiles |
| `fakeking_gfx.bin` | 5558 B | Fake-king boss battle tiles |
| `ground_tiles.bin` | 2334 B | Battle ground/floor tiles |
| `hud_gfx_1.bin` | 6542 B | Battle HUD graphics part 1 (also loaded in sound.asm region) |
| `hud_gfx_2.bin` | 1758 B | Battle HUD graphics part 2 |
| `player_tiles.bin` | 2294 B | Player sprite tiles used in battle |
| `status_tiles.bin` | 2382 B | Battle status bar tiles |
| `stow_thief_gfx.bin` | 4582 B | Stow / Thief boss tiles |
| `tsarkon_gfx.bin` | 2184 B | Tsarkon boss tiles |

### `data/art/tiles/boss/`

| File | Size | Notes |
|------|------|-------|
| `data2_gfx.bin` | 4212 B | Boss tile set 2 |
| `data4_gfx.bin` | 4806 B | Boss tile set 4 |
| `data6_gfx.bin` | 558 B | Boss tile set 6 |
| `data8_gfx.bin` | 194 B | Boss tile set 8 |
| `magic_wyclifparma_gfx.bin` | 398 B | Wyclif-Parma magic effect tiles |

### `data/art/tiles/dungeon/`

| File | Size | Notes |
|------|------|-------|
| `cave_item_tiles.bin` | 1922 B | Dungeon item/chest tiles |
| `cave_tiles.bin` | 4206 B | Dungeon wall/floor tiles |

### `data/art/tiles/enemy/`

Each enemy type has two files: `*_main_gfx.bin` (primary sprite) and
`*_child_gfx.bin` (secondary/child sprite for multi-sprite enemies).

| Prefix | Enemy type |
|--------|-----------|
| `beast` | Beast-type enemies |
| `dragon` | Dragon-type |
| `fpenemy_b/d/f/h/j/l/n` | Fixed-palette enemies A–N (generic variants) |
| `gargoyle` | Gargoyle-type |
| `golem` | Golem-type |
| `humanoid` | Humanoid enemies |
| `insect` | Insect-type |
| `orb` | Orb/floating enemies |
| `quadruped` | Four-legged enemies |
| `serpent` | Serpent-type |
| `skeleton` | Skeleton/undead |
| `world_map` | Enemy sprites on world map |
| `boss_main_gfx.bin` | Generic boss sprite |

### `data/art/tiles/font/`

| File | Size | Notes |
|------|------|-------|
| `font_tiles.bin` | 3936 B | 123 tiles — game font (RLE compressed inline, `CompressedFontTileData`) |

### `data/art/tiles/misc/`

| File | Size | Notes |
|------|------|-------|
| `gfxlist_worldbattle_gfx.bin` | 1066 B | World map battle screen tiles |

### `data/art/tiles/npc/`

| File | Size | Notes |
|------|------|-------|
| `talker_portrait_51534_gfx.bin` | 96 B | 3 tiles — NPC portrait set A |
| `talker_portrait_51e44_gfx.bin` | 2018 B | NPC portrait set B |

### `data/art/tiles/overworld/`

| File | Size | Notes |
|------|------|-------|
| `world_map_tiles.bin` | 7026 B | World map terrain tiles (non-power-of-32 = mixed format) |

### `data/art/tiles/player/`

| File | Size | Notes |
|------|------|-------|
| `overworld_gfx.bin` | 2138 B | Player overworld walking sprites (101-entry pointer table, 101-entry remap array `LoadPlayerOverworldGraphics_Data`) |

### `data/art/tiles/town/`

| File | Size | Notes |
|------|------|-------|
| `tileset_a_gfx.bin` | 4160 B | 130 tiles — town tileset A (raw 4bpp) |
| `tileset_a_mappings.bin` | 7436 B | Town A tilemap / metatile mappings |
| `tileset_b_gfx.bin` | 1620 B | Town tileset B (raw 4bpp) |
| `tileset_b_mappings.bin` | 6930 B | Town B tilemap / metatile mappings |

### `data/art/tiles/ui/`

| File | Size | Notes |
|------|------|-------|
| `menu_gfx_1.bin` | 6032 B | Menu/dialog box tiles part 1 |
| `menu_gfx_2.bin` | 2354 B | Menu/dialog box tiles part 2 |
| `title_screen_1.bin` | 2350 B | Title screen tiles part 1 |
| `title_screen_2.bin` | 2816 B | 88 tiles — title screen part 2 |
| `title_screen_3.bin` | 2598 B | Title screen tiles part 3 |
| `title_screen_4.bin` | 1718 B | Title screen tiles part 4 |
| `title_screen_5.bin` | 2170 B | Title screen tiles part 5 |

---

## Pointer Table Conventions

Pointer tables in `gfxdata.asm` follow this pattern:

1. **Remap byte array** (if present): maps logical sprite slots to physical tile
   indices within the blob. One byte per sprite-composition slot.
2. **Incbin blob**: the raw tile data. Sub-labels are byte-offset equates pointing
   to specific frames.
3. **Pointer table** (`dc.l`): one longword per animation frame, pointing into the
   blob. The calling code in `src/battle_gfx.asm` or `src/enemy.asm` indexes by
   frame number, then transfers via DMA to VRAM.

---

## Magic Effect Tiles (Inline RLE)

Magic spell effect graphics are stored inline in `gfxdata.asm` as RLE-compressed
`dc.b` streams (not in separate `.bin` files). One section exists per town that has
magic:

| Section label | Town |
|---------------|------|
| `MagicGfxData_DeepdaleStow_Gfx_48EFE` | Deepdale / Stow |
| `MagicGfxData_Keltwick_Gfx_49AD8` | Keltwick |
| `MagicGfxData_Helwig_Gfx_49ECC` | Helwig |
| `MagicGfxData_Tadcaster_Gfx_4A548` | Tadcaster |
| `MagicGfxData_WyclifParma_Gfx_4A8F4` | Wyclif / Parma (incbin) |

Each section contains:
1. A tile-index remap array (`dc.b`)
2. One or more RLE-compressed tile blobs (`dc.b`)
3. A `SpriteFramePointerTable_*` for the spell animation frames

---

## VDP DMA Loading

At runtime the game:
1. Indexes the relevant pointer table by animation frame.
2. Issues a DMA transfer (via `VDP_control_port`) to copy the tile data into VRAM
   at the pre-assigned VRAM address for that sprite slot.
3. Applies the remap array to construct the hardware sprite attribute table entries
   that reference the correct VRAM tile indices.

No decompression of RLE data happens at this step for normal tiles. RLE-compressed
data (magic tiles, font) is decompressed once at load time into a VRAM or RAM buffer.

---

## Editing Tiles

To replace tile graphics:

1. Locate the relevant `.bin` file in `data/art/tiles/<category>/`.
2. Replace the file with new 4bpp Genesis-format tile data of identical byte length.
3. Run `cmd //c verify.bat` to confirm the ROM is still bit-perfect.
   (Verification will fail since you changed tile data — this is expected.
   The bit-perfect check only applies to *code* changes in the disassembly.)

> **Note:** Files that contain RLE-compressed data (`font_tiles.bin`, magic inline
> blobs) must be re-compressed with the same RLE scheme if content changes.
> Files with remap arrays require updating the array if the physical order of tiles
> in the blob changes.
