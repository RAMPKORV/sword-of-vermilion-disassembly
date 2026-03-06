# Change Safety Checklist

Use this checklist before committing any change to the disassembly.

---

## Before Every Commit

- [ ] **`cmd //c verify.bat` passes** (exit 0, SHA256 matches).
      If it fails, fix the cause — do not revert unrelated changes.

- [ ] **No hex→decimal conversions in `dc.b`/`dc.w`/`dc.l` tables.**
      Run `node tools/lint_dc_decimal.js` to check.
      Safe: `dc.w $0016` → Unsafe: `dc.w 22`

- [ ] **No new hardcoded RAM addresses.**
      Run `node tools/lint_raw_ram_addresses.js` to check.
      Use constants from `constants.asm` instead of raw `$FFFFC...` literals.

- [ ] **No new hardcoded I/O port addresses.**
      Run `node tools/lint_raw_io_addresses.js` to check.
      Use `IO_version`, `VDP_control_port`, `Z80_bus_request`, etc.

- [ ] **No new `loc_XXXXXXXX` labels.**
      Run `node tools/lint_loc_labels.js` to check.
      Assign a descriptive PascalCase name; preserve ROM offset in a comment above the label.

- [ ] **No raw `$NN(A5)` / `$NN(A6)` object field offsets.**
      Run `node tools/lint_raw_obj_offsets.js` to check.
      Use named `obj_*` constants from `constants.asm`.

- [ ] **No new duplicate constant definitions.**
      Run `node tools/lint_duplicate_constants.js` to check.

---

## When Renaming a Label

- [ ] Update **all call sites** (search with `rg "\blabel_name\b" E:\Romhacking\vermilion\src\`).
- [ ] Add a comment above the new label preserving the original hex ROM offset:
      ```asm
      ; loc_0000633C
      MapRLEDecompressor:
      ```
- [ ] Run `cmd //c verify.bat` after each rename.

---

## When Adding or Modifying a Function

- [ ] Add or update the **function header comment**: inputs (Dx/Ax), outputs, trashed registers, stack effects.
- [ ] Ensure **branch sizes** are correct: `.b` for ±127 bytes, `.w` for longer ranges.
- [ ] If using `BSR.w` to call within the same module, confirm range is still valid after edits.
- [ ] Use `JSR`/`JMP` for cross-module calls.

---

## When Adding a Data Table

- [ ] See `docs/data_table_style.md` for the full guide.
- [ ] Hex literals only in `dc.*`.
- [ ] Use a macro if one exists (see the macro table in `docs/data_table_style.md`).
- [ ] Add a comment block explaining entry size, field layout, and which function reads the table.

---

## Run All Checks at Once

```
node tools/run_checks.js
cmd //c verify.bat
```

All checks must pass before committing.
