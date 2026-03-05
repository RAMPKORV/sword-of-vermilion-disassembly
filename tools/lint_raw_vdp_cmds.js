#!/usr/bin/env node
// tools/lint_raw_vdp_cmds.js
// Sword of Vermilion — Lint for Raw VDP Command Longwords
//
// Scans src/*.asm for raw VDP control-port command longwords in dc.l data
// tables that should be replaced with either:
//   (a) a vdpCmd macro call, OR
//   (b) a VDP_CMD_* named constant
//
// After MAGICB-003 converted all existing raw VDP longwords, this linter
// prevents regressions from new raw values being introduced.
//
// SCOPE: Only dc.l data lines are checked (not instruction immediates).
// Instruction operands left as raw hex per MAGICB-003 policy are intentional
// single-use values and are not flagged.
//
// DETECTION: A dc.l value is flagged if it matches the vdpCmd encoding
// formula with a known valid access type (VRAM write, VSRAM write, CRAM write,
// VRAM DMA) AND the upper nibble of the high byte matches the expected CD bits:
//   CD=01 (VRAM write) → high byte $40–$5F
//   CD=01 (VSRAM write, CD=0101) → high byte $60–$7F
//   CD=11 (CRAM write) → high byte $C0–$DF
//   CD=21 (VRAM DMA)   → high byte $40–$5F, low byte bit4 set
//
// Values with low-byte bits [3:2] non-zero are not VDP commands and are
// never flagged (eliminates almost all false positives from data tables).
//
// Usage:
//   node tools/lint_raw_vdp_cmds.js [--verbose] [--fix-suggest] [files...]
//   node tools/lint_raw_vdp_cmds.js src/cutscene.asm
//
// Options:
//   --verbose      Print every scanned file even if no issues found
//   --fix-suggest  Print a suggested vdpCmd replacement for each hit
//   --help         Show this help
//
// Exit code: 0 = no raw VDP longwords found, 1 = violations found

'use strict';

const fs   = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

const args    = process.argv.slice(2);
const VERBOSE = args.includes('--verbose');
const SUGGEST = args.includes('--fix-suggest');
const HELP    = args.includes('--help');

if (HELP) {
  console.log([
    'Usage: node tools/lint_raw_vdp_cmds.js [files...] [--verbose] [--fix-suggest]',
    '',
    'Scans src/*.asm dc.l lines for raw VDP command longwords not using vdpCmd or VDP_CMD_*.',
    '',
    'Options:',
    '  --verbose      Print each file checked even if clean',
    '  --fix-suggest  Print suggested vdpCmd replacement for each hit',
    '  --help         Show this help',
  ].join('\n'));
  process.exit(0);
}

// Files to scan: explicit args (minus flags) or default src/*.asm
const SRC_DIR = path.join(__dirname, '..', 'src');
const fileArgs = args.filter(a => !a.startsWith('--') && fs.existsSync(a));
let files;
if (fileArgs.length > 0) {
  files = fileArgs;
} else {
  files = fs.readdirSync(SRC_DIR)
    .filter(f => f.endsWith('.asm'))
    .map(f => path.join(SRC_DIR, f))
    .sort();
}

// ---------------------------------------------------------------------------
// Files exempt from VDP command linting (pure binary data / animation data
// where coincidental pattern matches are unavoidable and not VDP commands).
// ---------------------------------------------------------------------------

const EXEMPT_FILES = new Set([
  'gfxdata.asm',   // raw graphics tile pixel data
  'battledata.asm', // boss animation frame tables
]);

// ---------------------------------------------------------------------------
// VDP command detection (tightly scoped to dc.l tables only)
// ---------------------------------------------------------------------------

const VDP_TYPE_NAMES = {
  0x01: 'VDP_TYPE_VRAM_WRITE',
  0x03: 'VDP_TYPE_CRAM_WRITE',
  0x05: 'VDP_TYPE_VSRAM_WRITE',
  0x21: 'VDP_TYPE_VRAM_DMA',
};

// Expected high byte (bits 31-24) range for each type, based on vdpCmd formula.
// bits 31-30 = CD1-CD0, bits 29-16 = A13-A0
// For VRAM write (CD=01): high byte = 0100_xxxx (0x40-0x7F range when A13 set)
//   but more precisely: bits 31-30 = 01, so $40–$7F (but $60-$7F is used by VSRAM write too)
// We check by CD reconstruction from the decoded value.
function decodeVdpCmd(v) {
  const lowByte = v & 0xFF;

  // Bits [3:2] of low byte must be 0 in all valid vdpCmd outputs
  if ((lowByte & 0x0C) !== 0) return null;

  const cd_lo  = (v >>> 30) & 3;        // CD1:CD0 from bits 31-30
  const a13_0  = (v >>> 16) & 0x3FFF;   // A13:A0
  const cd_hi  = (v >>> 4)  & 0xF;      // CD5:CD2
  const a15_14 = v & 3;                  // A15:A14

  // Verify low-byte encoding is consistent
  if (((cd_hi << 4) | a15_14) !== lowByte) return null;

  const type = (cd_hi << 2) | cd_lo;
  const addr = (a15_14 << 14) | a13_0;

  // Only flag known write types (not read types, which have many false positives)
  // VRAM write = 0x01, CRAM write = 0x03, VSRAM write = 0x05, VRAM DMA = 0x21
  if (!(type === 0x01 || type === 0x03 || type === 0x05 || type === 0x21)) return null;

  // Additional check: the high byte should match expected ranges.
  // VRAM write (type=0x01): CD1:CD0=01, so bits 31-30=01 → high byte $40-$7F
  //   But VSRAM (type=0x05): CD1:CD0=01 too. Distinguish by cd_hi.
  //   VRAM write:  cd_hi=0, CD=0001 → ok
  //   VSRAM write: cd_hi=1, CD=0101 → ok (bits 31-30=01, cd_hi=1 → bits 7-4=0001)
  //   CRAM write:  cd_hi=0, CD1:CD0=11 → bits 31-30=11 → high byte $C0-$FF
  //   VRAM DMA:    cd_hi=8+0=type $21 = 0x21 → CD=100001: bits 31-30=01, cd_hi=8 → bits 7-4=1000 → lowByte=0x83 or similar
  const highByte = (v >>> 24) & 0xFF;
  if (type === 0x01 && (highByte < 0x40 || highByte > 0x7F)) return null;
  if (type === 0x03 && (highByte < 0xC0 || highByte > 0xFF)) return null;
  if (type === 0x05 && (highByte < 0x60 || highByte > 0x7F)) return null;
  if (type === 0x21 && (highByte < 0x40 || highByte > 0x7F)) return null;

  return { addr, type, name: VDP_TYPE_NAMES[type] };
}

// Regex: dc.l data line (instruction-only filter: skip lines with comma after a register pattern)
const RE_DC_L  = /^\s*dc\.l\s+(.+)/i;
// Match bare 8-hex-digit values
const RE_HEX8  = /\$([0-9A-Fa-f]{8})\b/g;

function checkLine(line, lineNo, filePath, violations) {
  // Strip comments
  const stripped = line.replace(/;.*$/, '');
  if (!stripped.trim()) return;

  // Skip lines that already use symbolic replacements
  if (/vdpCmd|VDP_CMD_/.test(stripped)) return;

  // Skip lines explicitly acknowledged as intentional raw VDP data or non-VDP values
  // "VDP write cmd" = confirmed intentional raw VDP cmd (MAGICB-003 policy: single-use)
  // "inline bytes"  = dead code / embedded machine code bytes, not VDP commands
  // "raw data"      = general exclusion marker for non-VDP coincidental patterns
  if (/VDP write cmd|inline bytes|raw data/i.test(line)) return;

  // Only check dc.l lines (not instruction operands per policy)
  if (!RE_DC_L.test(stripped)) return;

  const m = stripped.match(RE_DC_L);
  if (!m) return;

  RE_HEX8.lastIndex = 0;
  let hexMatch;
  while ((hexMatch = RE_HEX8.exec(m[1])) !== null) {
    const hexStr = hexMatch[1];
    const v = parseInt(hexStr, 16);
    const decoded = decodeVdpCmd(v);
    if (decoded) {
      violations.push({
        file:     filePath,
        line:     lineNo,
        raw:      '$' + hexStr.toUpperCase(),
        addr:     '$' + decoded.addr.toString(16).toUpperCase().padStart(4,'0'),
        type:     decoded.name,
        text:     line.trimEnd(),
      });
    }
  }
}

// ---------------------------------------------------------------------------
// Scan files
// ---------------------------------------------------------------------------

const allViolations = [];

for (const filePath of files) {
  const basename = path.basename(filePath);
  if (EXEMPT_FILES.has(basename)) {
    if (VERBOSE) {
      const rel = path.relative(process.cwd(), filePath);
      console.log(`  - ${rel.padEnd(45)} skipped (raw data file)`);
    }
    continue;
  }
  const lines = fs.readFileSync(filePath, 'utf8').split('\n');
  const beforeCount = allViolations.length;

  for (let i = 0; i < lines.length; i++) {
    checkLine(lines[i], i + 1, filePath, allViolations);
  }

  const fileViolations = allViolations.length - beforeCount;
  if (VERBOSE || fileViolations > 0) {
    const rel = path.relative(process.cwd(), filePath);
    const status = fileViolations > 0
      ? `FAIL (${fileViolations} raw VDP dc.l longword(s))`
      : 'ok';
    console.log(`  ${fileViolations > 0 ? '✗' : '✓'} ${rel.padEnd(45)} ${status}`);
  }
}

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------

const WIDTH = 72;
const hr    = '─'.repeat(WIDTH);

if (allViolations.length === 0) {
  console.log('\n' + hr);
  console.log('  PASS — no raw VDP command dc.l longwords found.');
  console.log(hr + '\n');
  process.exit(0);
}

console.log('\n' + hr);
console.log(`  ${allViolations.length} raw VDP command dc.l longword(s) found:`);
console.log(hr);

for (const v of allViolations) {
  const rel = path.relative(process.cwd(), v.file);
  console.log(`\n  ${rel}:${v.line}`);
  console.log(`    ${v.text}`);
  console.log(`    raw value: ${v.raw}  →  addr=${v.addr}, type=${v.type}`);
  if (SUGGEST) {
    console.log(`    suggest:   vdpCmd ${v.addr}, ${v.type}`);
    console.log(`             OR define VDP_CMD_* equ ${v.raw} in hw_constants.asm`);
  }
}

console.log('\n' + hr);
console.log(`  FAIL — ${allViolations.length} raw VDP dc.l longword(s) need vdpCmd or VDP_CMD_* replacement.`);
console.log(hr + '\n');
process.exit(1);
