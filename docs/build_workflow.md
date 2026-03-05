# Build and Verify Workflow

## Overview

```
vermilion.asm  (top-level include list)
      |
      v
  asm68k.exe  /k /p /o ae-
      |
      +---> out.bin         (assembled ROM, gitignored)
      +---> vermilion.lst   (listing file with offsets, gitignored)
      |
      v
  verify.bat  (SHA256 check)
      |
      +---> EXIT 0  BUILD VERIFIED - ROM IS BIT-PERFECT
      +---> EXIT 1  HASH MISMATCH or build error
```

## Building

```batch
build.bat
```

From Git Bash or WSL:

```bash
cmd //c build.bat
```

Direct invocation:

```
asm68k /k /p /o ae- vermilion.asm,out.bin,,vermilion.lst
```

### Flags

| Flag | Meaning |
|------|---------|
| `/k` | Keep symbols (do not strip symbol table) |
| `/p` | Generate listing file (`vermilion.lst`) |
| `/o ae-` | Disable auto-extend (branches do not auto-promote `.b` → `.w`) |

### Outputs

- `out.bin` — the assembled ROM (512 KB). Gitignored; never commit this file.
- `vermilion.lst` — listing file mapping every ROM offset to its source line.
  Also gitignored.

## Verifying

```batch
verify.bat
```

Or from Git Bash:

```bash
cmd //c verify.bat
```

`verify.bat` runs `build.bat` and then computes the SHA256 of `out.bin`,
comparing it against the known-good hash:

```
bcf1698a01a7e481240a4b01b3e68e31b133d289d9aaea7181e72a4057845eb4
```

Exit code 0 = bit-perfect. Exit code 1 = mismatch or build failure.

**After every code change, run `verify.bat`. A non-bit-perfect result is never
acceptable. Do not commit until the build is clean.**

## The listing file

`vermilion.lst` is regenerated on every build. Each line contains:

- Source line number
- ROM offset (hex)
- Encoded bytes (hex)
- Source text

Example:

```
  1234   00C000  303C 0001   MOVE.w  #$0001, D0
```

Use the listing to trace any ROM byte back to its source:

```bash
node -e "
const fs = require('fs');
const lst = fs.readFileSync('vermilion.lst', 'utf8').split('\n');
const target = 0xC000;
lst.forEach((line, i) => {
  const m = line.match(/([0-9A-Fa-f]{6})/);
  if (m && Math.abs(parseInt(m[1],16) - target) < 4)
    console.log(i+1 + ': ' + line);
});
"
```

See [debugging_verify_failures.md](debugging_verify_failures.md) for a
step-by-step guide to using the listing when the hash mismatches.

## Recommended workflow for multi-step changes

1. Make one small, targeted change.
2. `cmd //c verify.bat`
3. On success: `git add . && git commit -m "ID: Description (bit-perfect)"`
4. Repeat.

Never commit before verifying. Never revert a clean tree to fix a broken build
— identify and fix the specific cause instead.

## Gitignore policy

The following files are gitignored and must not be committed:

- `out.bin` — assembled ROM output
- `vermilion.lst` — listing file

The original ROM backup `orig_backup.bin` is also gitignored (it is a
copyrighted binary).

## Running the linters before committing

```bash
node tools/run_checks.js
```

This runs all lint scripts and prints a summary. All linters must pass before
committing. See [contributing.md](contributing.md) for the full list of checks.
