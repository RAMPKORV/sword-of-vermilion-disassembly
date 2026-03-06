# SRAM Save Format — Sword of Vermilion

This document describes the on-cartridge SRAM layout used for save files.
It is intended for save game editor development and randomizer patching.

Source: `src/sram.asm` — `SaveGameToSram`, `LoadGameFromSave`,
`CalculateChecksumAndBackupSram`, `VerifySaveChecksum`.

---

## SRAM physical layout

The cartridge SRAM is mapped at `$200000`–`$2FFFFF` with **byte-wide
interleaved** access: only odd SRAM addresses are used, starting at `$200001`.
Each logical data byte is stored at an odd SRAM address; the even address
immediately before it is unused (skipped).

This means every logical offset X maps to SRAM physical address:

```
physical_address = slot_base + (X * 2) + 1
```

---

## Save slots

The game supports **3 save slots** (plus a duplicate of slot 0 as a guard):

| Slot | Primary base | Backup base |
|------|-------------|------------|
| 0    | `$00200001` | `$00200541` |
| 1    | `$00200A81` | `$00200FC1` |
| 2    | `$00201501` | `$00201A41` |

**Slot size in SRAM address space:** `$A80` (2688) bytes → `$540` (1344) logical data bytes.

**Backup:** each slot has a full backup copy stored immediately after the primary.  
The backup is `$2A0` (672) bytes = 336 logical data bytes (the checksummed portion only).

---

## Save slot record layout

All offsets below are **logical offsets** (0, 1, 2… = every other SRAM byte).

| Offset (hex) | Size | RAM source | Description |
|-------------|------|-----------|-------------|
| `0x00` | 14 bytes | `Player_name` (`$FFFFC64C`) | Player name string, null-terminated or padded |
| `0x0E` | 2 bytes | `Current_town` (`$FFFFC40C`) + 1 | Current town ID (`.w`) |
| `0x10` | 14 bytes | `Towns_visited` (`$FFFFC508`) | Visited-town flags array |
| `0x1E` | 8 bytes | `Player_position_x_outside_town` (`$FFFFC662`) + 7 | Player overworld position (4× `.w`) |
| `0x26` | 22 bytes | `Possessed_items_length` (`$FFFFC442`) + 21 | Item count + item array |
| `0x3C` | 22 bytes | `Possessed_magics_length` (`$FFFFC462`) + 21 | Magic count + magic array |
| `0x52` | 22 bytes | `Possessed_equipment_length` (`$FFFFC482`) + 21 | Equipment count + equip array |
| `0x68` | 16 bytes | `Equipped_sword` (`$FFFFC4D0`) + 15 | Currently equipped items (8× `.w`) |
| `0x78` | 48 bytes | `Player_kims` (`$FFFFC620`) + 47 | Gold, stats, level, HP, XP etc. (`.l`-aligned block) |
| `0xA8` | 512 bytes | `Event_triggers_start` (`$FFFFC720`) + 511 | Story progress flags (`$200` bytes) |
| `0x2A8` | 2 bytes | (computed) | 16-bit checksum (big-endian word, see below) |

**Total logical save record:** 680 bytes data + 2 bytes checksum = **682 bytes**.

---

## Checksum algorithm

The checksum covers the first **670 bytes** of save data (not all 680 — the last
10 bytes of `Event_triggers` are not included in the checksum calculation).

Algorithm (from `CalculateChecksumAndBackupSram` / `VerifySaveChecksum`):

```
accumulator = 0   (16-bit)

for i in 0 .. 334:                       // 335 iterations (DBF D7, #$014E)
    word = (save_byte[i*2] << 8) | save_byte[i*2 + 1]
    accumulator ^= word
    carry = accumulator & 1
    accumulator >>= 1                    // logical shift right
    if carry:
        accumulator ^= $8810

stored_checksum = big-endian 16-bit word at offset $2A8
```

The verification (`VerifySaveChecksum`) recomputes the accumulator over the
same 670 bytes, then compares it to the stored word at offset `$2A8`.  It
returns with the Z flag set (equal = valid).

The polynomial constant `$8810` is specific to this game.

---

## Item array format

Each entry in `Possessed_items` (22 bytes total: 1-byte length + up to 21 entries):

```
Byte 0:   flags    — $01 = quest item (cannot be discarded); $00 = normal item
Byte 1:   item ID  — see table below
```

Items are stored as pairs, so `Possessed_items_length` (.w) is the count of
items, and the array starts immediately after.

### Item IDs

| ID   | Name |
|------|------|
| `$00` | Herbs |
| `$01` | Candle |
| `$02` | Lantern |
| `$03` | Poison Balm |
| `$04` | Alarm Clock |
| `$05` | Vase |
| `$06` | Joke Book |
| `$07` | Small Bomb |
| `$08` | Old Woman's Sketch |
| `$09` | Old Man's Sketch |
| `$0A` | Pass to Cartahena |
| `$0B` | Truffle |
| `$0C` | Digot Plant |
| `$0D` | Treasure of Troy |
| `$0E` | White Crystal |
| `$0F` | Red Crystal |
| `$10` | Blue Crystal |
| `$11` | White Key |
| `$12` | Red Key |
| `$13` | Blue Key |
| `$14` | Crown |
| `$15` | Sixteen Rings |
| `$16` | Bronze Key |
| `$17` | Silver Key |
| `$18` | Gold Key |
| `$19` | Thule Key |
| `$1A` | Secret Key |
| `$1B` | Medicine |
| `$1C` | Agate Jewel |
| `$1D` | Griffin Wing |
| `$1E` | Titania's Mirror |
| `$1F` | Gnome Stone |
| `$20` | Topaz Jewel |
| `$21` | Banshee Powder |
| `$22` | Rafael's Stick |
| `$23` | Mirror of Atlas |
| `$24` | Ruby Brooch |
| `$25` | Dungeon Key |
| `$26` | Kulm Vase |
| `$27` | Kasan's Chisel |
| `$28` | Book of Kiel |
| `$29` | Danegeld Water |
| `$2A` | Mineral Bar |
| `$2B` | Mega Blast |

Full item data (names, shop prices, descriptions) is in `src/shopdata.asm`.
Item constants are in `constants.asm` under the `ITEM_*` prefix.

---

## Relevant RAM addresses

See `constants.asm` for the full annotated list.  Key fields:

| Symbol | Address | Description |
|--------|---------|-------------|
| `Player_name` | `$FFFFC64C` | Player name (null-terminated) |
| `Player_level` | `$FFFFC640` | Player level (`.w`) |
| `Player_hp` | `$FFFFC62C` | Current HP (`.w`) |
| `Player_mhp` | `$FFFFC62E` | Max HP (`.w`) |
| `Player_kims` | `$FFFFC620` | Gold (`.l`) |
| `Current_town` | `$FFFFC40C` | Active town ID (`.w`) |
| `Event_triggers_start` | `$FFFFC720` | Story flags array (`.b[512]`) |
| `Towns_visited` | `$FFFFC508` | Town visit flags (`.b[16]`) |
| `Possessed_items_length` | `$FFFFC442` | Item count (`.w`) |
| `Possessed_items` | `$FFFFC444` | Item array (`.b[42]`) |
| `Equipped_sword` | `$FFFFC4D0` | Equipped sword slot (`.w`) |

---

## Implementing a save editor

1. Read the raw SRAM file (or a save state memory dump).
2. Select the slot base address (see table above).
3. Dereference each logical offset using: `physical_addr = base + (logical_offset * 2) + 1`.
4. Parse each field according to the table above.
5. Before writing: recompute the checksum over the first 670 logical bytes
   and store it at logical offset `$2A8`.
6. Write the primary slot; optionally write the backup slot (same format,
   backup base address).

For a Node.js implementation example, see `tools/index/ram_symbols.js` for the
pattern of reading `constants.asm` to enumerate all RAM symbols.
