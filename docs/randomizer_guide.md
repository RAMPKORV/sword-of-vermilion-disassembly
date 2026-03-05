# Randomizer User Guide — Sword of Vermilion

## Prerequisites

- **Node.js v14+** (project uses v25.0.0)
- The assembler toolchain (`asm68k.exe`) present in the project root
- A bit-perfect base ROM: run `cmd //c verify.bat` first to confirm

```
cmd //c verify.bat
# Expected: SHA-256 bcf1698a01a7e481240a4b01b3e68e31b133d289d9aaea7181e72a4057845eb4
```

---

## Quick Start

Randomize all five systems with a single command:

```bash
node tools/randomizer/randomize.js --seed SOV-1-1F-3141592653
```

This will:
1. Run all five sub-randomizers (enemies, shops, chests, encounters, stats)
2. Validate game progression is still completable
3. Inject the randomized data back into the ASM sources
4. Rebuild the ROM via `verify.bat`

When done, `out.bin` is your randomized ROM. The seed string printed at the
end can be shared with others to reproduce the exact same result.

---

## Seed Format

```
SOV-1-<flags_hex>-<seed_integer>
```

| Part           | Description                                              |
|----------------|----------------------------------------------------------|
| `SOV`          | Game identifier (Sword of Vermilion)                     |
| `1`            | Randomizer version                                       |
| `<flags_hex>`  | Hex bitmask of enabled modules (see table below)         |
| `<seed_integer>` | Unsigned 32-bit decimal integer                        |

**Examples:**

```
SOV-1-1F-3141592653   All five modules, seed 3141592653
SOV-1-03-99999        Enemies + shops only, seed 99999
SOV-1-04-12345        Chests only, seed 12345
```

### Flag Bitmask

| Hex  | Decimal | Module       | What it randomizes                        |
|------|---------|--------------|-------------------------------------------|
| 0x01 | 1       | `enemies`    | Enemy HP, damage, speed, XP/kim rewards   |
| 0x02 | 2       | `shops`      | Shop item inventories                     |
| 0x04 | 4       | `chests`     | Treasure chest contents                   |
| 0x08 | 8       | `encounters` | Encounter group composition               |
| 0x10 | 16      | `stats`      | Player level-up stat gains                |
| 0x1F | 31      | *(all)*      | All five modules                          |

Combine by adding the hex values: enemies+shops = `0x01 + 0x02` = `0x03`.

---

## CLI Reference

```
node tools/randomizer/randomize.js --seed <seed> [options]
```

### Options

| Option            | Default    | Description                                        |
|-------------------|------------|----------------------------------------------------|
| `--seed <str>`    | *(required)*| Full seed string or raw integer                  |
| `--flags <hex>`   | from seed  | Override flag bitmask (e.g. `1F`, `03`)            |
| `--variance <v>`  | `0.5`      | Variance for enemy and stat randomizers (0–1)      |
| `--behavior`      | off        | Also shuffle enemy behavior flags within tiers     |
| `--dry-run`       | off        | Simulate all steps without writing any files       |
| `--no-rebuild`    | off        | Skip ASM inject and verify.bat (data files only)   |
| `--no-validate`   | off        | Skip the progression validator                     |
| `--help`          | —          | Show usage summary                                 |

### Using a raw integer seed

If you supply a plain integer, `--flags` selects which modules to run
(defaults to `1F` = all modules):

```bash
node tools/randomizer/randomize.js --seed 42 --flags 07
# Runs enemies + shops + chests with seed 42
```

---

## Running Individual Modules

Each sub-randomizer can be run standalone for testing or partial re-rolls:

```bash
# Enemy stats only
node tools/randomizer/enemy_randomizer.js --seed 12345 --variance 0.3

# With behavior flag shuffling
node tools/randomizer/enemy_randomizer.js --seed 12345 --behavior

# Shop inventories only
node tools/randomizer/shop_randomizer.js --seed 12345

# Treasure chests only
node tools/randomizer/chest_randomizer.js --seed 12345

# Encounter tables only
node tools/randomizer/encounter_randomizer.js --seed 12345

# Player stat curves only
node tools/randomizer/stats_randomizer.js --seed 12345 --variance 0.4
```

All support `--dry-run` to preview changes without writing, and `--json` to
dump the modified data as JSON to stdout.

---

## Configuration Options

### `--variance <v>`

Controls how far enemy stats and player stat gains can deviate from their
vanilla values. Range: `0.0`–`1.0`.

- `0.0` — no change (identity, useful for testing)
- `0.25` — mild variation (0.75×–1.25× of original values)
- `0.5` *(default)* — moderate variation (0.5×–1.5×)
- `1.0` — maximum variation (near-zero or double original values possible)

HP, XP, and kim rewards use the full variance range.  
Speed uses a tighter internal range (0.75×–1.25×) regardless of `--variance`.

### `--behavior`

When set, the enemy behavior flags (movement patterns, aggression, attack
type) are shuffled among enemies within the same difficulty tier. Without this
flag, all behavior flags remain at their vanilla values.

### `--no-rebuild`

Useful when iterating on data without a full rebuild each time. Leaves the
modified JSON data files on disk. Run `inject_game_data.js` and `verify.bat`
manually when ready:

```bash
node tools/randomizer/randomize.js --seed 12345 --no-rebuild
node tools/inject_game_data.js --enemies --shops --player-stats
cmd //c verify.bat
```

---

## Seed Sharing

To share a randomized ROM setup with someone else:

1. Give them the seed string printed at the end of a successful run, e.g.:
   ```
   Seed: SOV-1-1F-3141592653
   ```
2. They run the same command on a bit-perfect base ROM:
   ```bash
   node tools/randomizer/randomize.js --seed SOV-1-1F-3141592653
   ```
3. The resulting `out.bin` will be byte-identical to yours, provided:
   - Same base ROM (bit-perfect SHA-256 above)
   - Same Node.js randomizer version

The flags are embedded in the seed string, so no extra `--flags` argument is
needed when using a full `SOV-1-FLAGS-SEED` string.

---

## How Each Module Works

### Enemies (`0x01`)

Reads `tools/data/enemies.json` (85 enemies). For each enemy, applies
independent per-stat variance multipliers driven by the seeded PRNG.
Stats are clamped to safe hardware ranges (HP min 1, damage min 1, etc.).
Writes back to `enemies.json`; injected via `inject_game_data.js --enemies`.

### Shops (`0x02`)

Reads `tools/data/shops.json` (16 town shops). Shuffles item slots within
progression tiers so early-game shops retain early-game items.
Healing items (Herbs, Vial) are guaranteed in at least two early-access shops.
Injected via `inject_game_data.js --shops`.

### Chests (`0x04`)

Parses `src/towndata.asm` directly for `ItemChest`, `EquipChest`, `MoneyChest`,
and `RingChest` macros (61 total chests). Shuffles contents within each chest
type group. Patches `towndata.asm` in-place via regex replacement.

**Locked chests (never shuffled):**
- All `RingChest` entries (3 chests — story rings)
- `ITEM_MIRROR_OF_ATLAS`
- `ITEM_RUBY_BROOCH`

### Encounters (`0x08`)

Reads encounter group data from `tools/data/enemies.json`. Shuffles enemy
composition within encounter groups while preserving the regional difficulty
gradient. Injected alongside enemy data via `inject_game_data.js --enemies`.

### Stats (`0x10`)

Reads `tools/data/player_stats.json` (31 level-up entries). Applies per-stat
variance multipliers while keeping total stat budget at each level within ±25%
of vanilla. XP-to-next-level values are never changed.
Injected via `inject_game_data.js --player-stats`.

---

## Progression Validation

After any run affecting item availability, the randomizer automatically runs
`tools/progression_validator.js` to confirm:

- All story-required items are reachable from the start
- No required key item is locked behind the door it unlocks
- At least one healing item source is available before each mandatory dungeon

If validation fails, randomization is aborted with a message indicating which
items are unreachable. Try a different seed or disable the problematic modules.

Skip validation only for testing purposes:
```bash
node tools/randomizer/randomize.js --seed 12345 --no-validate
```

---

## Known Limitations

- **Map layouts and dungeon structures are not randomized.** Requires RLE
  decompression and cave room pointer updates; planned as a future
  `tools/editor/map_editor.js` feature (EDITOR-006).

- **Story dialogue and scripts are not randomized.** No randomizer mode is
  planned for text.

- **The assembler toolchain is required.** `asm68k.exe` must be present in the
  project root. There is no binary-patch export mode yet (planned future work
  using `tools/rom_diff.js` to generate IPS patches).

- **Shop randomizer does not guarantee all items are reachable via shops.**
  Only healing items and story-critical items have explicit availability
  guarantees. Some equipment types may become shop-exclusive or shop-absent in
  a given seed.

- **Chest randomizer modifies `src/towndata.asm` directly.** After a chest
  randomization run, `git diff src/towndata.asm` will show the actual changes.
  Run `git checkout src/towndata.asm` to restore vanilla before creating a new
  seed (the unified `randomize.js` does not auto-restore source files between
  runs).

- **Progression validator covers only the critical path.** Optional side
  content (optional bosses, non-critical treasure) is not checked.

---

## FAQ

**Q: Can I share a `SOV-1-...` seed with someone using an older version of
the randomizer?**

Seeds produced by version `1` of the randomizer are tied to the v1 PRNG and
data layout. Future versions will increment the version field (`SOV-2-...`).
Always use the same randomizer source version as the seed producer.

**Q: Does the randomizer modify the base ROM files permanently?**

Yes — the sub-randomizers write to `tools/data/*.json` and (for chests)
directly to `src/towndata.asm`. The unified `randomize.js` does not restore
sources automatically after building. Use `git checkout` to restore vanilla
sources, or `git stash` before running and `git stash pop` afterward.

**Q: The build failed after randomization. What now?**

Run `cmd //c verify.bat` for details. Common causes:
- A randomized value exceeded the ASM expression range (report as a bug).
- `src/towndata.asm` was left in a partially-patched state from a previous
  failed run — run `git checkout src/towndata.asm` and retry.

**Q: Can I combine seeds from different modules?**

No. The seed string encodes all active modules together. To combine results,
run the full unified CLI with the desired flag combination.

**Q: Where are the randomized data files?**

- `tools/data/enemies.json` — enemy stats and encounter tables
- `tools/data/shops.json` — shop inventories
- `tools/data/player_stats.json` — level-up stat curves
- `src/towndata.asm` — chest contents (patched in-place)

---

## See Also

- `docs/randomizer_architecture.md` — design rationale, PRNG details, data table specifications
- `tools/progression_validator.js` — progression logic checker
- `tools/rom_diff.js` — compare two ROMs by label to review randomizer output
- `tools/encounter_analyzer.js` — analyze encounter rates and difficulty curves
