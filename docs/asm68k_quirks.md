# ASM68K Assembler Quirks

This document covers known ASM68K (version 2.53) behaviors that affect
bit-perfect reassembly of this ROM. Many of these were discovered during
disassembly work; violating them is the most common cause of verify failures.

## 1. Decimal vs hex in `dc.*` directives

ASM68K encodes `dc.b`/`dc.w`/`dc.l` values differently depending on whether
you write them as hex or decimal. Even semantically identical values differ:

```asm
dc.w    $0000   ; assembles to 00 00
dc.w    0       ; may assemble differently in certain contexts
```

**Rule**: always use hex literals in `dc.*` directives. Decimal is only safe
in instruction immediates such as `MOVEQ #10, D1` or `MOVE.w #0, D0`.

The `tools/lint_dc_decimal.js` linter flags violations.

## 2. Auto-extend disabled (`/o ae-`)

The build uses the `/o ae-` flag, which disables automatic branch extension.
ASM68K will **not** automatically promote a `.b` branch to `.w` when the
target is out of the short range (±127 bytes).

Consequence: if code is inserted between a `.b` branch and its target,
the build may silently produce a wrong offset rather than an error, or it
may error out with a range complaint.

**Rule**: use `.b` only for branches that are and will remain within ±127 bytes.
Use `.w` for anything that might grow.

## 3. Named macro arguments are lowercased

When a macro is defined with named arguments, ASM68K lowercases the argument
name before substituting it. This causes subtle breakage:

```asm
; BROKEN — 'Flag' is lowercased to 'flag' on substitution
myMacro macro Flag
    BTST.b  #Flag, D0
    ENDM
```

**Rule**: use positional arguments (`\1`, `\2`, etc.) instead of named
arguments in all macros:

```asm
; CORRECT
myMacro macro
    BTST.b  #\1, D0
    ENDM
```

## 4. Addressing suffix on positional arguments

You can append an addressing suffix directly to a positional argument:

```asm
clearRam macro
    CLR.w   \1.w    ; appends .w short-address mode
    ENDM
```

This is valid and produces the correct short-addressing encoding. It is
preferable to leaving it off when the address is in RAM (`$FFFF...`).

## 5. Local labels in macros use `\@` suffix

Local labels inside macros must use the `\@` suffix to be unique per expansion:

```asm
waitLoop macro
.loop\@:
    TST.b   $A10008
    BNE.b   .loop\@
    ENDM
```

Without `\@`, multiple expansions of the same macro produce duplicate label
definitions and an assembly error.

## 6. Forward reference resolution

ASM68K resolves forward references in two passes. In the first pass, unknown
sizes default to long-form. If the size resolves to short-form in the second
pass but the first pass already allocated more bytes, a phase error results.

**Practical impact**: avoid placing a `dc.l` table before the labels it
references if those labels are defined later in the same file — the label
values may be resolved correctly but the table size could mismatch between
passes in edge cases.

## 7. `=` vs `equ` for constant definitions

Both `=` and `equ` define symbolic constants, but they are not always
interchangeable in expression contexts. This project uses `=` for simple
value assignments and `equ` for RAM address definitions, consistent with the
original disassembly output.

## 8. Expressions in `dc.*` are evaluated as signed 32-bit

Expressions passed to `dc.l` are evaluated as 32-bit signed integers.
For constants with bit 31 set (e.g. `$C0000000`), the bitwise expression
`(3<<30)` yields a negative integer in some host environments but ASM68K
treats it correctly as an unsigned 32-bit value. Do not rely on the same
expression in JavaScript to verify the assembled value; use the listing file
instead.

## 9. No `INCLUDE` search path — paths are relative to the top-level file

All `include` directives in `vermilion.asm` use paths relative to the
project root. ASM68K does not support a search path; every path must be
exact relative to the file that contains the `include` directive.

## 10. Listing file format

The listing file `vermilion.lst` produced by `/p` contains:

```
<line>   <ROM offset>  <encoded bytes>   <source line>
```

Offsets are in hex. Use it to map any ROM byte back to its source line.
See [debugging_verify_failures.md](debugging_verify_failures.md) for
usage examples.
