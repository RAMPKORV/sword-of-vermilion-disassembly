# Debugging Verify Failures

`verify.bat` builds the ROM and checks its SHA256 against the known-good hash:

```
bcf1698a01a7e481240a4b01b3e68e31b133d289d9aaea7181e72a4057845eb4
```

A mismatch means the assembled `out.bin` differs from the original ROM. This
document covers how to diagnose and fix the divergence.

## Step 1 — confirm the build itself succeeded

```batch
build.bat
```

If ASM68K reports errors, fix them first. A build error produces a truncated or
zero-byte `out.bin`, which will always fail the hash check.

## Step 2 — find the first differing byte

```bash
node -e "
const fs = require('fs');
const orig = fs.readFileSync('orig_backup.bin');
const built = fs.readFileSync('out.bin');
const len = Math.min(orig.length, built.length);
for (let i = 0; i < len; i++) {
  if (orig[i] !== built[i]) {
    console.log('First diff at offset 0x' + i.toString(16).toUpperCase().padStart(6,'0'),
                'orig=0x' + orig[i].toString(16).padStart(2,'0'),
                'built=0x' + built[i].toString(16).padStart(2,'0'));
    break;
  }
}
if (orig.length !== built.length)
  console.log('Size mismatch: orig=' + orig.length + ' built=' + built.length);
"
```

The offset points to the first divergence. Everything after that offset may be
shifted if the cause is a size change.

## Step 3 — locate the offset in the listing file

After a successful build, `vermilion.lst` contains every assembled line with
its ROM offset. Search for the offset:

```bash
grep -n "00XXXX" vermilion.lst | head -20
```

Or in Node.js:

```bash
node -e "
const fs = require('fs');
const lst = fs.readFileSync('vermilion.lst', 'utf8').split('\n');
const target = 0xXXXXXX; // fill in offset
lst.forEach((line, i) => {
  const m = line.match(/^\s*([0-9A-Fa-f]{6})/);
  if (m && Math.abs(parseInt(m[1],16) - target) < 16)
    console.log(i+1 + ': ' + line);
});
"
```

The listing shows the source file and line that produced each byte.

## Common causes and fixes

### Hex-to-decimal conversion in `dc.*`

**Symptom**: a data table is wrong starting at the changed entry.

**Cause**: ASM68K encodes decimal and hex literals differently in some contexts.
Even `0` vs `$0000` can differ.

**Fix**: convert back to hex. Run `node tools/lint_dc_decimal.js` to find all
occurrences project-wide.

```asm
; WRONG
dc.w    26, 0, 1

; CORRECT
dc.w    $001A, $0000, $0001
```

### Off-by-one in a data table

**Symptom**: everything from a table entry onward is shifted by 1–4 bytes.

**Cause**: a byte was added or removed from a `dc.b`/`dc.w`/`dc.l` table.
Count the entries against the original and compare the table end address in
the listing.

### Wrong label after a rename

**Symptom**: a branch or jump goes to the wrong address; code after the label
is correct but the branch target offset changed.

**Cause**: a label was renamed but not all references were updated, or a new
label was introduced mid-function that changed relative offsets.

**Fix**: use `rg` to find all references before renaming:

```bash
rg "\bloc_XXXXXXXX\b" E:/Romhacking/vermilion/src/
```

### Missing or extra bytes in a struct

**Symptom**: all data from a struct definition onward is shifted.

**Cause**: a `dc.*` entry was added, removed, or has the wrong size suffix
(`.b` vs `.w`).

**Fix**: compare the struct size in the listing against the expected size (often
documented in a comment above the struct).

### Macro expansion produces wrong byte count

**Symptom**: new macro usage changes table size.

**Cause**: a macro expands to a different number of bytes than the inline code
it replaced, usually because a size suffix differs or an extra instruction
was included.

**Fix**: verify expansion byte-count matches by checking the listing file
before and after the macro is applied.

### Auto-extend disabled — branch range exceeded

**Symptom**: ASM68K reports a range error, or the build succeeds but a branch
target is wrong.

**Cause**: `build.bat` uses `/o ae-` (auto-extend disabled). A `.b` branch
that previously fit in ±127 bytes no longer does after code was added nearby.

**Fix**: change the branch suffix from `.b` to `.w`.

## If you cannot find the cause

1. `git stash` your change.
2. Run `verify.bat` — confirm it passes on the unmodified tree.
3. `git stash pop` and re-apply the change in the smallest possible increment,
   verifying after each step.
4. Use `git diff` to confirm only the intended lines changed.

## What NOT to do

**Never** run `git checkout -- <file>` or `git revert` to fix a broken build
unless you genuinely want to discard all uncommitted work. Identify and fix
the specific problem instead.
