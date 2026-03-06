'use strict';
// lint_raw_ram_addresses.js
// Scans all build .asm files for raw $FFFF... or $FFFC... address literals used
// as instruction operands (not in equ definitions). These should use symbolic
// constants from constants.asm instead.
//
// Usage: node tools/lint_raw_ram_addresses.js
// Exit 0 = clean, Exit 1 = violations found

const fs   = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');

const BUILD_FILES = [
  'header.asm',
  'init.asm',
  'macros.asm',
  'constants.asm',
  ...fs.readdirSync(path.join(ROOT, 'src'))
        .filter(f => f.endsWith('.asm'))
        .map(f => path.join('src', f)),
];

// We target RAM addresses used as *memory operands* (not as immediate data).
// Real RAM on Genesis: $FF0000-$FFFFFF (68k mirror: $FFFF0000-$FFFFFFFF).
// We flag: $FFFFCxxx, $FFFFExxx, $FFFFxxxx used as bare addressing-mode operands.
// We skip:
//   - Lines that are equ / = definitions (those ARE the constant file)
//   - Comment-only lines
//   - #$... immediate operands (could be signed fixed-point numbers, not RAM addrs)
//   - dc.* data lines (raw pixel/sound data may contain FF-prefixed values)
//   - constants.asm entirely (it only contains definitions)

const EQU_LINE_RE   = /^\s*\w+\s+(equ|=)\s+/i;
const COMMENT_RE    = /^\s*;/;
const DC_LINE_RE    = /^\s*dc\.[bwl]\s+/i;
// Match a raw RAM address used as an address-mode operand (not after #)
// Pattern: NOT preceded by # (i.e., not an immediate), followed by $FFFF or $FFFC etc.
// We look specifically for the 68k "short" or "long" RAM address patterns:
//   $FFFFCxxx  $FFFFExxx  $FFFFxxxx  $FFFFFxxx
// used in MOVE/CLR/TST/LEA/etc. as destination or source operands.
const RAM_ADDR_RE   = /(?<!#)\$FFFF[0-9A-Fa-f]{4}\b/g;

let violations = [];

for (const relPath of BUILD_FILES) {
  if (relPath === 'constants.asm') continue; // skip — it's all definitions
  const fullPath = path.join(ROOT, relPath);
  if (!fs.existsSync(fullPath)) continue;
  const lines = fs.readFileSync(fullPath, 'utf8').split('\n');
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (COMMENT_RE.test(line)) continue;
    if (EQU_LINE_RE.test(line)) continue;
    if (DC_LINE_RE.test(line)) continue;
    // Strip inline comments before matching
    const codePart = line.split(';')[0];
    const matches  = codePart.match(RAM_ADDR_RE);
    if (!matches) continue;
    for (const m of matches) {
      violations.push({ file: relPath, line: i + 1, addr: m, source: line.trimEnd() });
    }
  }
}

if (violations.length === 0) {
  console.log('lint_raw_ram_addresses: OK — no raw RAM addresses found in instructions.');
  process.exit(0);
} else {
  console.error(`lint_raw_ram_addresses: FAIL — ${violations.length} raw RAM address(es) found:`);
  for (const v of violations) {
    console.error(`  ${v.file}:${v.line}: ${v.addr}  |  ${v.source}`);
  }
  process.exit(1);
}
