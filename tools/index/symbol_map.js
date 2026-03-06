#!/usr/bin/env node
// tools/index/symbol_map.js
//
// Produces tools/index/symbol_map.json — a machine-readable mapping of every
// label / symbolic constant in the disassembly to its address and metadata.
//
// Two sources are combined:
//   1. vermilion.lst  — positional labels (ROM + RAM EQU-ed via positional
//      placement in constants.asm).  Line format:
//        XXXXXXXX<whitespace>LabelName:
//   2. constants.asm  — symbolic constants defined with `=`.  Line format:
//        NAME  = $HHHHHHHH  [; optional comment]
//      Only hex address values ($ prefix) are included; plain numeric
//      constants (palette indices, tile flags, etc.) are excluded because
//      they are not memory addresses.
//
// Usage:
//   node tools/index/symbol_map.js [--lst <path>] [--out <path>]
//
// Defaults:
//   --lst  vermilion.lst              (relative to repo root)
//   --out  tools/index/symbol_map.json
//
// Output format (sorted by address):
//   {
//     "EntryPoint":  { "address": "0x00000F2C", "region": "rom", "source": "lst"  },
//     "Player_hp":   { "address": "0xFFFFC62C", "region": "ram", "source": "const" },
//     ...
//   }
//
// Regions:
//   "rom"  — address < 0x400000  (cartridge ROM)
//   "ram"  — address >= 0xFF0000 (work RAM / hardware registers)
//   "io"   — 0xA00000–0xBFFFFF   (Z80 RAM, VDP, I/O)
//   "misc" — everything else

'use strict';

const fs   = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Argument parsing
// ---------------------------------------------------------------------------
const repoRoot = path.resolve(__dirname, '..', '..');
const args     = process.argv.slice(2);

function getArg(flag, defaultVal) {
    const idx = args.indexOf(flag);
    return idx !== -1 && args[idx + 1] ? args[idx + 1] : defaultVal;
}

const lstPath    = path.resolve(repoRoot, getArg('--lst', 'vermilion.lst'));
const constPath  = path.resolve(repoRoot, 'constants.asm');
const outPath    = path.resolve(repoRoot, getArg('--out', 'tools/index/symbol_map.json'));

if (!fs.existsSync(lstPath)) {
    console.error(`ERROR: listing file not found: ${lstPath}`);
    console.error('Run build.bat first to generate vermilion.lst');
    process.exit(1);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function addrRegion(addrNum) {
    if (addrNum < 0x400000)              return 'rom';
    if (addrNum >= 0xA00000 && addrNum < 0xC00000) return 'io';
    if (addrNum >= 0xFF0000)             return 'ram';
    return 'misc';
}

// ---------------------------------------------------------------------------
// Pass 1 — Parse listing file for positional labels
// ---------------------------------------------------------------------------
// Line format:  XXXXXXXX<whitespace>LabelName:\r?
const LABEL_RE = /^([0-9A-Fa-f]{8})\s+([A-Za-z_][A-Za-z0-9_]*):\s*(?:;.*)?$/;

const symbolMap  = {};
let lstDuplicates = 0;

const lstContent = fs.readFileSync(lstPath, 'utf8');
for (const rawLine of lstContent.split('\n')) {
    const line = rawLine.replace(/\r$/, '');
    const m    = LABEL_RE.exec(line);
    if (!m) continue;

    const addrNum = parseInt(m[1], 16);
    const name    = m[2];
    const addrHex = '0x' + m[1].toUpperCase();

    if (symbolMap[name]) { lstDuplicates++; continue; }
    symbolMap[name] = { address: addrHex, region: addrRegion(addrNum), source: 'lst' };
}

// ---------------------------------------------------------------------------
// Pass 2 — Parse constants.asm for hex-address symbolic constants
// ---------------------------------------------------------------------------
// Line format (either style used in this codebase):
//   NAME  = $HHHHHHHH   [; comment]
//   NAME  equ $HHHHHHHH [; comment]
// Only constants whose value is a $ hex literal are included (not plain
// decimals, which are flags/indices rather than memory addresses).
const CONST_RE = /^\s*([A-Za-z_][A-Za-z0-9_]*)\s+(?:=|equ)\s+\$([0-9A-Fa-f]+)/i;

let constAdded = 0;
let constSkipped = 0;

if (fs.existsSync(constPath)) {
    const constContent = fs.readFileSync(constPath, 'utf8');
    for (const rawLine of constContent.split('\n')) {
        const line = rawLine.replace(/\r$/, '');
        const m    = CONST_RE.exec(line);
        if (!m) continue;

        const name    = m[1];
        const addrNum = parseInt(m[2], 16);
        const addrHex = '0x' + addrNum.toString(16).toUpperCase().padStart(8, '0');

        if (symbolMap[name]) { constSkipped++; continue; }   // already from lst
        symbolMap[name] = { address: addrHex, region: addrRegion(addrNum), source: 'const' };
        constAdded++;
    }
}

// ---------------------------------------------------------------------------
// Write output (sorted by address for readability)
// ---------------------------------------------------------------------------
const sorted = Object.entries(symbolMap).sort((a, b) => {
    const na = parseInt(a[1].address, 16);
    const nb = parseInt(b[1].address, 16);
    return na - nb || a[0].localeCompare(b[0]);
});
const sortedMap = Object.fromEntries(sorted);

const outDir = path.dirname(outPath);
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(sortedMap, null, 2) + '\n');

const total   = Object.keys(sortedMap).length;
const romCnt  = sorted.filter(([,v]) => v.region === 'rom').length;
const ramCnt  = sorted.filter(([,v]) => v.region === 'ram').length;
const ioCnt   = sorted.filter(([,v]) => v.region === 'io').length;
const miscCnt = sorted.filter(([,v]) => v.region === 'misc').length;

console.log(`symbol_map.js: ${total} symbols written to ${path.relative(repoRoot, outPath)}`);
console.log(`  ROM labels    : ${romCnt}`);
console.log(`  RAM labels    : ${ramCnt}`);
console.log(`  I/O labels    : ${ioCnt}`);
if (miscCnt) console.log(`  Misc labels   : ${miscCnt}`);
console.log(`  From lst      : ${total - constAdded}`);
console.log(`  From constants: ${constAdded}`);
if (lstDuplicates) console.log(`  lst duplicates skipped : ${lstDuplicates}`);
if (constSkipped)  console.log(`  const duplicates skipped: ${constSkipped}`);
