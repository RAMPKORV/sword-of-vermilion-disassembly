# Randomizer Architecture — Sword of Vermilion

## Overview

The randomizer produces a patched ROM binary from the base Sword of Vermilion ROM
by modifying game data tables (enemy stats, shop inventories, treasure chests,
encounter groups, and player stat curves) without altering any code.

The baseline ROM must be bit-perfect (SHA-256
`bcf1698a01a7e481240a4b01b3e68e31b133d289d9aaea7181e72a4057845eb4`).

---

## Approach: ASM Reassembly (not binary patching)

The randomizer uses **ASM source patching + reassembly**, not direct binary patching:

1. Extract current game data to JSON via `tools/extract_game_data.js`.
2. Modify the JSON data tables using seed-driven randomization.
3. Inject the modified values back into ASM source via `tools/inject_game_data.js`
   (which patches in-place, preserving all macro syntax and structure).
4. Rebuild with `build.bat` to produce the output ROM.

**Why ASM reassembly over binary patching?**

- The disassembly already has full symbol coverage. ASM injection is safer and
  produces readable diffs (auditable with `tools/rom_diff.js`).
- Binary patching is brittle if table sizes change (e.g., adding shop items);
  ASM reassembly handles layout changes automatically.
- The `inject_game_data.js` tool already exists and is tested (Phase 1).
- Output ROMs are reproducible: same seed + same base ROM always produces the
  same output.

**Tradeoff:** Requires the assembler toolchain (`asm68k.exe`) to be present.
A future binary-patch export mode can be added later using `tools/rom_diff.js`
to compute and export an IPS patch.

---

## Seed Format

```
<game>-<version>-<flags>-<seed>
```

- `<game>`:    `SOV` (Sword of Vermilion)
- `<version>`: `1` (first randomizer version)
- `<flags>`:   hex bitmask of enabled randomization modes (see flag table below)
- `<seed>`:    unsigned 32-bit integer (decimal), user-supplied or generated

**Example:** `SOV-1-1F-3141592653`

### Flag Bitmask

| Bit | Flag constant      | Randomizes                         |
|-----|--------------------|------------------------------------|
| 0   | `FLAG_ENEMIES`     | Enemy stats (HP, damage, speed)    |
| 1   | `FLAG_SHOPS`       | Shop inventories                   |
| 2   | `FLAG_CHESTS`      | Treasure chest contents            |
| 3   | `FLAG_ENCOUNTERS`  | Encounter group composition        |
| 4   | `FLAG_STATS`       | Player level-up stat gains         |

---

## Data Tables Randomized

### 1. Enemy Stats (`FLAG_ENEMIES`)

**Source:** `tools/data/enemies.json` → `src/battledata.asm`  
**Tool:** `tools/randomizer/enemy_randomizer.js`

| Field           | Randomization approach                         | Constraint               |
|-----------------|------------------------------------------------|--------------------------|
| `hp`            | Multiply by variance factor (0.5×–2.0×)        | Min 1, max 65535         |
| `damage_per_hit`| Multiply by variance factor (0.5×–2.0×)        | Min 1, max 255           |
| `speed`         | Multiply by variance factor (0.75×–1.5×)       | Min 64, max 65535        |
| `xp_reward`     | Multiply by variance factor (0.5×–2.0×)        | Min 1                    |
| `kim_reward`    | Multiply by variance factor (0.5×–2.0×)        | Min 0                    |
| `behavior_flag` | Optionally shuffle among enemies of same tier  | Per-mode config          |

Enemy stats are randomized **per-enemy independently** using a deterministic
PRNG seeded from `seed + enemy_index`. All values are rounded to integers and
clamped to safe ranges.

There are 85 enemies in the roster.

### 2. Shop Inventories (`FLAG_SHOPS`)

**Source:** `tools/data/shops.json` → `src/shopdata.asm`  
**Tool:** `tools/randomizer/shop_randomizer.js`

There are 16 town shops. Each has an item shop and optional equipment/magic shops.

Randomization approach: **shuffle within tier constraints**.

- Items are divided into tiers by base price (early/mid/late game).
- Each shop slot is replaced with a random item from the same or adjacent tier.
- Key healing items (HERBS, VIAL) are guaranteed to appear in at least 2 early
  shops (Wyclif and one other).
- Equipment shops shuffle weapon/armor types but preserve the shop's equipment
  category (town shops remain weapon shops; city shops can receive any equipment).

### 3. Treasure Chest Contents (`FLAG_CHESTS`)

**Source:** `src/towndata.asm` chest reward code, item constants from `constants.asm`  
**Tool:** `tools/randomizer/chest_randomizer.js`

Chest locations are fixed in the map. Contents are randomized by shuffling the
reward pool (items, equipment, kims amounts) across all chests while keeping key
progression items reachable.

**Logic validation:** After shuffling, `tools/progression_validator.js` is run to
confirm all required story items remain obtainable. If validation fails, the
randomizer tries again with a perturbed sub-seed (up to 100 attempts before aborting).

### 4. Encounter Groups (`FLAG_ENCOUNTERS`)

**Source:** `tools/data/enemies.json` encounter tables → `src/battledata.asm`  
**Tool:** `tools/randomizer/encounter_randomizer.js`

The overworld encounter map is an 8×16 grid of encounter group indices.
There are 70 encounter groups, each containing 4 enemy slots.

Randomization approach: **shuffle enemy slots within encounter groups**, then
optionally shuffle group assignments on the overworld map.

- Mode A (default): Only shuffle enemy composition within groups while preserving
  regional difficulty gradient (groups assigned to areas don't change).
- Mode B: Also reshuffle group assignments on the overworld map (harder mode).

### 5. Player Stat Curves (`FLAG_STATS`)

**Source:** `tools/data/player_stats.json` → `src/playerstats.asm`  
**Tool:** `tools/randomizer/stats_randomizer.js`

The player has 31 level-up entries. Each entry has: `mhp_gain`, `mmp_gain`,
`str_gain`, `ac_gain`, `int_gain`, `dex_gain`, `luk_gain`, `xp_to_next`.

Randomization approach: Apply per-stat variance multipliers while keeping the
total stat budget at each level within ±25% of the original.

`xp_to_next` is not randomized (affects game length too drastically).

---

## Logic Validation

After any randomization affecting item availability (chests, shops), the result
is validated with `tools/progression_validator.js`:

- All story-required items are reachable from the start.
- No required key item is locked behind another required key item it unlocks.
- At least one source of healing items exists in towns accessible before each
  mandatory dungeon.

Validation failure aborts randomization and returns an error with the seed.

---

## Output Format

The randomizer writes modified ASM source files to a **temporary working copy**,
then runs `build.bat` to produce `out.bin`. The output is then copied to the
requested output path.

```
tools/randomizer/randomize.js --seed 12345 --flags 0x1F --out sov_rando_12345.bin
```

The working copy is always cleaned up. The original `src/` files are restored after
the build, so the base assembly remains untouched.

### IPS Patch Export (future)

After building the randomized ROM, `tools/rom_diff.js` can compute the delta and
export an IPS patch for distribution without distributing the ROM binary.

---

## Implementation Plan

| File                                     | Task     | Depends on                      |
|------------------------------------------|----------|---------------------------------|
| `tools/randomizer/enemy_randomizer.js`   | RANDO-002 | `tools/data/enemies.json`       |
| `tools/randomizer/shop_randomizer.js`    | RANDO-003 | `tools/data/shops.json`         |
| `tools/randomizer/chest_randomizer.js`   | RANDO-004 | TOOLB-004 (progression validator) |
| `tools/randomizer/encounter_randomizer.js` | RANDO-005 | `tools/data/enemies.json`     |
| `tools/randomizer/stats_randomizer.js`   | RANDO-006 | `tools/data/player_stats.json`  |
| `tools/randomizer/randomize.js`          | RANDO-007 | All of the above + TOOLB-004    |
| `docs/randomizer_guide.md`               | RANDO-008 | RANDO-007                       |

---

## PRNG

All randomization uses a seeded 32-bit xorshift PRNG for reproducibility:

```js
function xorshift32(state) {
  state ^= state << 13;
  state ^= state >>> 17;
  state ^= state << 5;
  return state >>> 0;
}
```

Each sub-randomizer receives a derived sub-seed: `xorshift32(seed ^ MODULE_ID)`
where `MODULE_ID` is a fixed constant per module (enemy=1, shop=2, chest=3,
encounter=4, stats=5).

---

## Known Limitations

- Map layouts and dungeon structures are **not** randomized (requires RLE
  decompression + recompression and cross-referencing cave room pointers; planned
  as a future editor-only feature via EDITOR-006).
- Dialogue and story script are **not** randomized (no randomizer mode planned).
- The `vdpCmd` macro in `macros.asm` has a known ASM68K arithmetic overflow bug
  for addresses ≥ `$4000` — do not attempt to use it for code generation.
