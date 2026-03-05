# Contributing to the Sword of Vermilion Disassembly

This project is a bit-perfect disassembly of the Sega Genesis/Mega Drive game
*Sword of Vermilion* (1989, Sega). The goal is a clean, well-documented 68k
source that can be reassembled byte-for-byte to the original ROM, enabling
randomizers and game editor tooling.

## Quick start

1. Clone the repo.
2. Ensure `asm68k.exe` is present in the project root (already committed).
3. Build and verify:

```batch
verify.bat
```

A passing run prints `BUILD VERIFIED - ROM IS BIT-PERFECT`. See
[build_workflow.md](build_workflow.md) for a full explanation.

## Workflow: one change, verify, commit

Make the smallest possible change, then verify immediately:

```bash
# Make your edit
# Then:
cmd //c verify.bat      # must exit 0 before committing
git add <files>
git commit -m "ID: Brief description (bit-perfect)"
```

Never batch multiple unrelated changes into one commit. If `verify.bat` fails,
see [debugging_verify_failures.md](debugging_verify_failures.md).

## Code style

### Label naming

| Type | Convention | Example |
|------|-----------|---------|
| Undocumented location | `loc_XXXXXXXX` (hex ROM offset) | `loc_0000633C` |
| Function | PascalCase | `CheckForEncounter` |
| Data table | PascalCase + suffix | `ProgramStateMap` |
| Local label in function | `FunctionName_Desc` | `EntryPoint_Loop` |
| Symbolic constant | `ALL_CAPS` | `ITEM_HERBS` |
| RAM address | `Mixed_Case` noun phrase | `Player_hp` |
| Hardware register | `Mixed_Case` | `VDP_control_port` |

When renaming a `loc_` label, preserve the original address in a comment:

```asm
; loc_0000633C
MapRLEDecompressor:
```

### Instruction formatting

- Mnemonics **UPPERCASE**, size suffixes **lowercase**: `MOVE.w`, `TST.l`
- Labels at column 0; instructions indented one tab
- Comments: `; ` (semicolon + space)
- Size suffixes: `.b` byte, `.w` word, `.l` longword
- Short branches (±127 bytes): `.b`; longer: `.w`

### Data directives — **never convert hex to decimal**

```asm
; CORRECT
dc.w    $001A, $0000

; WRONG — may break bit-perfect build
dc.w    26, 0
```

Plain decimal is safe only in instruction immediates (`MOVEQ #10, D0`).
See [asm68k_quirks.md](asm68k_quirks.md) for why.

### Constants and RAM addresses

All constants and RAM addresses belong in `constants.asm`. Use symbolic names
everywhere; avoid hardcoded `$FFFF...` RAM addresses or raw I/O ports in
instructions.

### Macros

Prefer existing macros in `macros.asm` over repeated instruction sequences.
See the macro file for documentation on each macro.

## Running the linters

```bash
node tools/lint_loc_labels.js          # check for remaining loc_ labels
node tools/lint_dc_decimal.js          # check for decimal in dc.*
node tools/lint_raw_io_addresses.js    # check for raw I/O port addresses
node tools/lint_raw_ram_addresses.js   # check for raw RAM addresses
node tools/lint_duplicate_constants.js # check for duplicate equ definitions
```

Or run them all at once:

```bash
node tools/run_checks.js
```

## Pre-commit hook (recommended)

A pre-commit hook runs lint checks and `verify.bat` automatically before every
`git commit`. Install it once from the repo root:

**Git Bash / WSL / Linux / macOS:**
```bash
cp tools/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**Windows (manual check only):**
Git for Windows executes hooks as shell scripts, so install `pre-commit.sh` as
above. To run the checks manually from `cmd.exe`:
```batch
tools\pre-commit.cmd
```

Once installed, the hook fires on every `git commit` and blocks the commit if
any lint check fails or the ROM hash does not match.

## Adding constants

All new constants go in `constants.asm` in the appropriate section (section
banners mark each group). Do not add constants to individual `src/` files.

## Adding macros

Macros go in `macros.asm`. Document the usage, arguments, and an example in a
comment block above the macro definition.

## Tooling

Scripts in `tools/` are Node.js only. Do **not** use Python.
See `tools/run_checks.js` for a list of all available checks.

## Further reading

- [build_workflow.md](build_workflow.md) — full build pipeline explanation
- [debugging_verify_failures.md](debugging_verify_failures.md) — fixing broken builds
- [asm68k_quirks.md](asm68k_quirks.md) — assembler-specific gotchas
- [module_boundaries.md](module_boundaries.md) — which code belongs in which module
