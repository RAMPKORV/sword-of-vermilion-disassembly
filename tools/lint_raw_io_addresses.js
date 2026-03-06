'use strict';
// lint_raw_io_addresses.js
// Scans all build .asm files for raw Genesis hardware I/O port addresses used
// as instruction operands outside of equ definitions. These should use symbolic
// constants from constants.asm instead.
//
// Covered ranges:
//   $C00000-$C0001F  VDP ports (data, control, HV counter)
//   $A10000-$A1001F  I/O controller ports + version register
//   $A11100-$A11101  Z80 bus request
//   $A11200-$A11201  Z80 reset
//   $A14000-$A14003  TMSS (SEGA license register)
//
// Usage: node tools/lint_raw_io_addresses.js
// Exit 0 = clean, Exit 1 = violations found

const fs   = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');

const BUILD_FILES = [
  'header.asm',
  'init.asm',
  'macros.asm',
  ...fs.readdirSync(path.join(ROOT, 'src'))
        .filter(f => f.endsWith('.asm'))
        .map(f => path.join('src', f)),
];

const EQU_LINE_RE = /^\s*\w+\s+(equ|=)\s+/i;
const COMMENT_RE  = /^\s*;/;
const DC_LINE_RE  = /^\s*dc\.[bwl]\s+/i;

// I/O address patterns (as 6-char hex after $, no # prefix)
// We avoid flagging immediate operands with #$A1xxxx since those could be
// data values, not I/O reads. We flag bare $Axxxxx and $Cxxxxx operands.
const IO_PATTERNS = [
  // VDP
  /(?<!#)\$C00[0-9A-Fa-f]{3}\b/g,
  // I/O ports ($A10000-$A1001F)
  /(?<!#)\$A1000[0-9A-Fa-f]\b/g,
  /(?<!#)\$A1001[0-9A-Fa-f]\b/g,
  // Z80 bus / reset
  /(?<!#)\$A111[0-9A-Fa-f]{2}\b/g,
  /(?<!#)\$A112[0-9A-Fa-f]{2}\b/g,
  // TMSS
  /(?<!#)\$A140[0-9A-Fa-f]{2}\b/g,
];

let violations = [];

for (const relPath of BUILD_FILES) {
  const fullPath = path.join(ROOT, relPath);
  if (!fs.existsSync(fullPath)) continue;
  const lines = fs.readFileSync(fullPath, 'utf8').split('\n');
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (COMMENT_RE.test(line)) continue;
    if (EQU_LINE_RE.test(line)) continue;
    if (DC_LINE_RE.test(line)) continue;
    const codePart = line.split(';')[0];
    for (const pattern of IO_PATTERNS) {
      pattern.lastIndex = 0; // reset regex state for /g
      let m;
      while ((m = pattern.exec(codePart)) !== null) {
        violations.push({ file: relPath, line: i + 1, addr: m[0], source: line.trimEnd() });
      }
    }
  }
}

if (violations.length === 0) {
  console.log('lint_raw_io_addresses: OK — no raw I/O port addresses found in instructions.');
  process.exit(0);
} else {
  console.error(`lint_raw_io_addresses: FAIL — ${violations.length} raw I/O address(es) found:`);
  for (const v of violations) {
    console.error(`  ${v.file}:${v.line}: ${v.addr}  |  ${v.source}`);
  }
  process.exit(1);
}
