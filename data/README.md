# data/ — Binary Asset Reference

This directory contains binary assets extracted from the Sword of Vermilion ROM
and referenced by `incbin` directives in the disassembly sources.

All files here are **read-only build inputs** — do not edit them unless you
understand the exact format and have verified the build remains bit-perfect
after your change.

---

## Directory layout

```
data/
├── art/
│   ├── palettes/           Colour palette data
│   └── tiles/              Graphics tile data (by category)
│       ├── battle/         Battle-screen enemy tile sets
│       ├── boss/           Boss sprite tile sets
│       ├── dungeon/        Dungeon wall/floor tiles
│       ├── enemy/          Overworld/encounter enemy sprites
│       ├── font/           Text font tiles
│       ├── misc/           Miscellaneous graphics
│       ├── npc/            NPC portrait/sprite tiles
│       ├── overworld/      Overworld map tiles
│       ├── player/         Player sprite tiles
│       ├── town/           Town building/terrain tiles
│       └── ui/             UI chrome, windows, icons
├── maps/
│   ├── cave/               Cave/dungeon map sectors (RLE-compressed)
│   ├── overworld/          Overworld map sectors (RLE-compressed)
│   └── town/               Town map sectors (RLE-compressed, currently empty)
└── sound/
    ├── dac/                PCM sample data for the DAC channel
    ├── driver/             Z80 sound driver binary
    ├── music/              Music track data (currently empty)
    └── sound_cmd_data.bin  Sound command/SFX dispatch table
```

---

## Format details

### art/palettes/palette_data.bin

**Size:** 6272 bytes  
**Layout:** 98 palette entries × 64 bytes each  
**Entry structure (64 bytes = one Mega Drive palette line):**

```
Offset  Size   Content
0x00    2×16   16 colours × 2 bytes (big-endian 16-bit Mega Drive colour word)
```

**Mega Drive colour word format (16-bit):**
```
Bits 15–12  unused (zero)
Bits 11–9   Blue  component (3 bits, values 0–7 → 0x0, 0x2, 0x4, 0x6, 0x8, 0xA, 0xC, 0xE)
Bits 8–6    unused (zero)
Bits 5–3    Green component (3 bits, same scale)
Bits 2–0    Red   component (3 bits, same scale)
```

Colour 0 of each line is the transparent colour (always `$0000` = black/transparent).

The game stores four active palette lines (`Palette_line_0_buffer` –
`Palette_line_3_buffer`) in RAM at `$FFFFC000`–`$FFFFC07F` and DMAs them to
CRAM each VBlank.

The `palette_data.bin` blob is referenced in `src/gfxdata.asm` via `incbin`
and indexed by palette-load functions in `src/battle_gfx.asm` and
`src/states.asm`.

---

### art/tiles/\*/\*.bin

**Format:** Sega Genesis 4bpp tile data (optionally RLE-compressed)

**Uncompressed tile format:**
Each tile is 8×8 pixels at 4 bits per pixel = 32 bytes per tile.

```
Byte 0:  pixels (7,6) of row 0   (high nibble = left pixel)
Byte 1:  pixels (5,4) of row 0
...
Byte 4:  pixels (7,6) of row 1
...
Byte 31: pixels (1,0) of row 7
```

**RLE-compressed tile format** (used by font, overworld, and several other sets):
```
Byte < $80:  output as-is (literal byte)
Byte >= $80: read next byte N; output N repeated ($80 - byte) times
```

This is the same RLE encoding used by the map data.  The decompressor is
`DecompressTileGraphics` in `src/battle_gfx.asm`.

**File naming:** files are named after the function or data label that loads
them (e.g. `data2_gfx.bin` corresponds to `LoadBattleTilesToBuffers_Data2`).

---

### maps/overworld/sector_X_Y.bin  
### maps/cave/\*.bin  
### maps/town/\*.bin

**Format:** RLE-compressed map sector data

Each file is one map sector, stored with the same RLE encoding as tiles:

```
Byte < $80:  tile ID — output as-is
Byte >= $80: read next byte N; output N repeated ($80 - byte) times
```

**Decompressed layout:** a grid of tile IDs, one byte per map tile.  The
sector dimensions vary by map type.

**Tile ID meanings (overworld):**

| ID range | Meaning |
|----------|---------|
| `$00` | Ground (passable) |
| `$01` | Tree (impassable) |
| `$02` | Rock (impassable) |
| `$05` | Cave rock |
| `$0F` | House |
| `$1x` | Cave entrance / lower cave level (x = cave number) |
| `$8x` | Town entrance (x = town ID) |
| `$FF` | Cave exit |

**Sector file naming:** `sector_X_Y.bin` where X is the sector column and Y
is the sector row in the world grid.  The two `data_XXXXX.bin` files in
`overworld/` are auxiliary data tables loaded alongside the sector map.

The map decompressor is `MapRLEDecompressor` in `src/mapdata.asm`.  The
current sector data is stored at `Current_map_sector_data` (`$FFFF9000`).

---

### sound/sound_cmd_data.bin

**Size:** 22350 bytes  
**Format:** Sound driver command/data stream

This blob contains the YM2612 FM synthesis command sequences and PSG data for
all sound effects and music tracks.  It is consumed by the Z80 sound driver
(`sound/driver/`) via the sound command queue (`Sound_driver_play` at
`$FFFFF404`).

The exact sub-format is documented in `src/sound.asm`.

---

### sound/driver/\*.bin

**Format:** Z80 machine code — the sound driver that runs on the secondary Z80
processor.  Loaded into Z80 RAM at `$0000` during boot by `LoadZ80Driver` /
`InitZ80SoundDriver` in `init.asm`.

Do not modify this binary unless you understand Z80 assembly; it is not
assembled from source in this project (the Z80 driver source is not included).

---

### sound/dac/\*.bin

**Format:** Raw 8-bit unsigned PCM samples at the rate expected by the YM2612
DAC channel (channel 6).  Used for percussion and special sound effects.

---

## Adding new binary assets

1. Place the file in the appropriate subdirectory.
2. Reference it via `incbin "data/..."` in the corresponding `.asm` source.
3. Run `cmd //c verify.bat` — the build must remain bit-perfect.

If you are extracting a binary from the ROM, use `vermilion.lst` to find the
ROM offset of the data you want to extract, then slice `orig_backup.bin`
accordingly.  See [docs/build_workflow.md](../docs/build_workflow.md) for
listing file usage.
