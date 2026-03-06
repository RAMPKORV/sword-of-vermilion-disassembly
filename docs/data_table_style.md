# Data Table Style Guide — Sword of Vermilion Disassembly

This guide documents the conventions for defining data tables in `src/*.asm`.

---

## Core Rule: Hex Literals Only in dc.*

**Never use unadorned decimal integers in `dc.b`, `dc.w`, or `dc.l` directives.**

ASM68K encodes decimal and hex constants differently in certain contexts. Even
`dc.b 0` vs `dc.b $00` can produce different assembled bytes. This is the most
common cause of non-bit-perfect builds.

```asm
; CORRECT
    dc.b    $FF, $00, $01
    dc.w    $0016, $0032
    dc.l    $00000001

; WRONG — will likely break bit-perfect
    dc.b    255, 0, 1
    dc.w    22, 50
    dc.l    1
```

**Safe exceptions:** Decimal is fine in *instruction* immediates:
```asm
    MOVE.w  #0, D0        ; OK — instruction immediate
    MOVEQ   #10, D1       ; OK — instruction immediate
    MOVE.w  #(copies)-1   ; OK — expression in objectInitGroup macro
```

The linter `tools/lint_dc_decimal.js` flags violations automatically.

---

## Use Macros When Available

Several macros exist specifically to make data tables readable and reduce
copy-paste errors. Always prefer the macro form over raw bytes.

| Data type | Macro | File |
|-----------|-------|------|
| Enemy stats | `enemyData` | `macros.asm` |
| Enemy appearance | `enemyAppearance` | `macros.asm` |
| NPC entry | `npcEntry` | `macros.asm` |
| Object init group | `objectInitGroup` | `macros.asm` |
| Shop item | `shopItem` | `macros.asm` |
| Shop equipment | `shopEquip` | `macros.asm` |
| Shop magic | `shopMagic` | `macros.asm` |
| Town shop pointers | `townShopBlock` | `macros.asm` |
| Town tile gfx | `townTileGfxEntry` | `macros.asm` |
| Talker NPC gfx | `talkerGfxDesc` / `talkerGfxDescPortrait` | `macros.asm` |
| Magic gfx data | `magicGfxData` | `macros.asm` |
| Chest reward | `ItemChest` / `EquipChest` / `MoneyChest` / `RingChest` | `macros.asm` |
| VDP DMA command | `dmaCmd` | `macros.asm` |
| VDP command word | `vdpCmd` | `macros.asm` |
| Offset table entry | `offsetTableEntry.w` / `offsetTableEntry.l` | `macros.asm` |

---

## Symbolic Constants for Values

Use named constants instead of raw magic numbers. Constants are defined in
`constants.asm`. Common categories:

```asm
; Item IDs
    dc.b    ITEM_TYPE_DISCARDABLE, ITEM_HERBS       ; not: dc.b $00, $00

; Equipment
    dc.b    EQUIPMENT_TYPE_SWORD, EQUIPMENT_SWORD_BRONZE  ; not: dc.b $00, $01

; Boolean flags
    dc.b    FLAG_TRUE        ; not: dc.b $FF
    dc.b    FLAG_FALSE       ; not: dc.b $00

; Enemy reward types
    dc.w    ENEMY_REWARD_NONE    ; not: dc.w $0000
```

---

## Alignment and Grouping

Group related fields on the same line with a trailing comment explaining the group:

```asm
; Enemy: Slime
    enemyData   InitEnemy_Bouncing, $0001, ENEMY_REWARD_NONE, $0000, $00, $04, $0010, $0002, $0004, $0008, $00008000, $00, $02

; Good: logically grouped and commented
    dc.b    $00         ; movement direction
    dc.b    $01         ; animation frame
    dc.w    $0010       ; HP
    dc.w    $0004       ; damage

; Avoid: unexplained raw bytes with no context
    dc.b    $00, $01
    dc.w    $0010, $0004
```

For pointer tables, put each pointer on its own line with a label comment:

```asm
ProgramStateMap:
    dc.l    ProgramState_SegaLogo   ; $00 SEGA logo
    dc.l    ProgramState_TitleScreen ; $01 title screen
    dc.l    ProgramState_NameEntry  ; $02 name entry
```

---

## Adding a New Table

1. **Define the label** at column 0 with a PascalCase name.

2. **Add a comment block** before the label explaining:
   - Entry size (bytes)
   - Field layout
   - How the table is indexed
   - Which function reads it

3. **Use the macro** if one exists; otherwise follow the field order in the struct comment.

4. **Mark the end** of the table if the consumer needs a sentinel:
   ```asm
   SomeTable_End:
   ```
   or use a `dc.w $FFFF` / `dc.b $FF` sentinel matching the reader's expectation.

5. **Run verify.bat** to confirm the build is still bit-perfect.

### Example: adding a new enemy

```asm
; --- Goblin ---
; enemyData format: ai_fn, tile_id, reward_type, reward_value,
;   extra_obj_slots, max_spawn, hp, damage_per_hit,
;   xp_reward, kim_reward, speed, sprite_frame, behavior_flag
    enemyData   InitEnemy_Walking, $0005, ENEMY_REWARD_ITEM, ITEM_HERBS, \
                $00, $06, $0020, $0004, $0008, $0010, $00008000, $00, $02

; enemyAppearance format: main_frames, main_gfx, child_frames, child_gfx, dma_fn, vfx
    enemyAppearance GoblinFrames, GoblinGfx, StartOfRom, StartOfRom, \
                    NullSpriteRoutine-2, $01020F05
```

---

## Sentinel Values and Table Terminators

Some tables use sentinel terminators. Use the appropriate named constant:

| Context | Sentinel | Constant |
|---------|---------|---------|
| Item array end | `$FF` | use `dc.b $FF` (no named constant) |
| No-item slot | `$00` | `ITEM_NONE` or `dc.w $0000` |
| No equipment | `$FF` | `dc.b $FF` |
| Menu cursor "none" | `$FFFF` | `MENU_CURSOR_NONE` |

---

## Linter

Run `node tools/lint_dc_decimal.js` after editing data tables. It will flag any
`dc.b`, `dc.w`, or `dc.l` lines with unadorned decimal integers.

For the full suite of checks: `node tools/run_checks.js`
