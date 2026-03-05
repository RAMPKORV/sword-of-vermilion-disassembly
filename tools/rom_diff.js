#!/usr/bin/env node
// tools/rom_diff.js
// Sword of Vermilion — Symbol-Aware ROM Diff Tool
//
// Compares two ROM binaries and reports differences annotated with the
// nearest symbol name from tools/index/symbol_map.json. More useful than
// a raw hex diff for diagnosing verify failures and reviewing patches.
//
// Usage:
//   node tools/rom_diff.js <rom_a> <rom_b> [options]
//
// Options:
//   --context N   Show N bytes of hex context around each change (default 8)
//   --max N       Limit output to first N diff regions (default 200)
//   --bytes       Show raw byte values alongside ASCII in context lines
//   --json        Output full diff as JSON
//   --help        Show this help
//
// Examples:
//   node tools/rom_diff.js out.bin reference.bin
//   node tools/rom_diff.js patched.bin out.bin --context 16
//   node tools/rom_diff.js out.bin patched.bin --json > diff.json
//
// Exit code: 0 = identical, 1 = differences found, 2 = usage error

'use strict';

const fs   = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// CLI argument parsing
// ---------------------------------------------------------------------------

const args = process.argv.slice(2);

if (args.includes('--help') || args.length < 2) {
  console.log([
    'Usage: node tools/rom_diff.js <rom_a> <rom_b> [options]',
    '',
    'Options:',
    '  --context N   Show N bytes of hex context around each change (default 8)',
    '  --max N       Limit output to first N diff regions (default 200)',
    '  --bytes       Show raw byte values in context lines',
    '  --json        Output full diff as JSON',
    '  --help        Show this help',
  ].join('\n'));
  process.exit(args.includes('--help') ? 0 : 2);
}

const romAPath = args[0];
const romBPath = args[1];

let CONTEXT  = 8;
let MAX_REGIONS = 200;
const SHOW_BYTES = args.includes('--bytes');
const SHOW_JSON  = args.includes('--json');

const ctxIdx = args.indexOf('--context');
if (ctxIdx !== -1 && args[ctxIdx + 1]) CONTEXT = parseInt(args[ctxIdx + 1], 10) || 8;
const maxIdx = args.indexOf('--max');
if (maxIdx !== -1 && args[maxIdx + 1]) MAX_REGIONS = parseInt(args[maxIdx + 1], 10) || 200;

// ---------------------------------------------------------------------------
// Load ROMs
// ---------------------------------------------------------------------------

let romA, romB;
try {
  romA = fs.readFileSync(romAPath);
} catch (e) {
  console.error(`Error reading ${romAPath}: ${e.message}`);
  process.exit(2);
}
try {
  romB = fs.readFileSync(romBPath);
} catch (e) {
  console.error(`Error reading ${romBPath}: ${e.message}`);
  process.exit(2);
}

// ---------------------------------------------------------------------------
// Load symbol map (rom labels only, sorted by address for binary search)
// ---------------------------------------------------------------------------

const SYMBOL_MAP_PATH = path.join(__dirname, 'index', 'symbol_map.json');
let sortedSymbols = [];  // [{addr, name}] sorted by addr ascending

try {
  const rawMap = JSON.parse(fs.readFileSync(SYMBOL_MAP_PATH, 'utf8'));
  // Only use 'lst' source symbols — these have real ROM code/data addresses
  sortedSymbols = Object.entries(rawMap)
    .filter(([, v]) => v.source === 'lst' && v.region === 'rom')
    .map(([name, v]) => ({ addr: parseInt(v.address, 16), name }))
    .sort((a, b) => a.addr - b.addr);
} catch (e) {
  // symbol map optional — diff still works without it
}

// ---------------------------------------------------------------------------
// Find nearest symbol at or before a given address
// ---------------------------------------------------------------------------

function nearestSymbol(addr) {
  if (sortedSymbols.length === 0) return null;
  let lo = 0, hi = sortedSymbols.length - 1, best = null;
  while (lo <= hi) {
    const mid = (lo + hi) >> 1;
    if (sortedSymbols[mid].addr <= addr) {
      best = sortedSymbols[mid];
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return best;
}

// ---------------------------------------------------------------------------
// Compute diff regions
// ---------------------------------------------------------------------------
// A "region" is a contiguous run of bytes that differ between romA and romB.

function computeDiffRegions(a, b) {
  const regions = [];
  const len = Math.max(a.length, b.length);
  let i = 0;
  while (i < len) {
    const byteA = i < a.length ? a[i] : -1;
    const byteB = i < b.length ? b[i] : -1;
    if (byteA !== byteB) {
      const start = i;
      while (i < len) {
        const bA = i < a.length ? a[i] : -1;
        const bB = i < b.length ? b[i] : -1;
        if (bA === bB) break;
        i++;
      }
      regions.push({ start, end: i - 1, length: i - start });
    } else {
      i++;
    }
  }
  return regions;
}

// ---------------------------------------------------------------------------
// Format helpers
// ---------------------------------------------------------------------------

function hex(n, width) {
  return n.toString(16).toUpperCase().padStart(width, '0');
}

function hexBytes(buf, start, len) {
  const end = Math.min(start + len, buf.length);
  const out = [];
  for (let i = start; i < end; i++) out.push(hex(buf[i], 2));
  return out.join(' ');
}

function asciiBytes(buf, start, len) {
  const end = Math.min(start + len, buf.length);
  let s = '';
  for (let i = start; i < end; i++) {
    const c = buf[i];
    s += (c >= 0x20 && c < 0x7F) ? String.fromCharCode(c) : '.';
  }
  return s;
}

// Format a hex dump line: addr | hex bytes | ascii
function fmtLine(buf, offset, count) {
  const hexPart  = hexBytes(buf, offset, count).padEnd(count * 3 - 1);
  const ascPart  = asciiBytes(buf, offset, count);
  return `$${hex(offset, 8)}  ${hexPart}  ${ascPart}`;
}

// ---------------------------------------------------------------------------
// Main diff logic
// ---------------------------------------------------------------------------

const regions = computeDiffRegions(romA, romB);

if (SHOW_JSON) {
  const output = {
    rom_a: romAPath,
    rom_b: romBPath,
    rom_a_size: romA.length,
    rom_b_size: romB.length,
    diff_regions: regions.slice(0, MAX_REGIONS).map(r => {
      const sym = nearestSymbol(r.start);
      return {
        offset:  '0x' + hex(r.start, 8),
        length:  r.length,
        symbol:  sym ? sym.name : null,
        symbol_offset: sym ? r.start - sym.addr : null,
        bytes_a: hexBytes(romA, r.start, r.length),
        bytes_b: hexBytes(romB, r.start, r.length),
      };
    }),
    total_regions: regions.length,
    total_changed_bytes: regions.reduce((s, r) => s + r.length, 0),
    truncated: regions.length > MAX_REGIONS,
  };
  console.log(JSON.stringify(output, null, 2));
  process.exit(regions.length > 0 ? 1 : 0);
}

// ---------------------------------------------------------------------------
// Human-readable output
// ---------------------------------------------------------------------------

const WIDTH = 72;
const hr    = '─'.repeat(WIDTH);

console.log('\n' + '═'.repeat(WIDTH));
console.log(` ROM DIFF: ${path.basename(romAPath)}  vs  ${path.basename(romBPath)}`);
console.log('═'.repeat(WIDTH));
console.log(`  A: ${romAPath}  (${romA.length.toLocaleString()} bytes)`);
console.log(`  B: ${romBPath}  (${romB.length.toLocaleString()} bytes)`);
if (romA.length !== romB.length) {
  console.log(`  WARNING: ROM sizes differ by ${Math.abs(romA.length - romB.length)} bytes`);
}
console.log('');

if (regions.length === 0) {
  console.log('  ROMs are IDENTICAL.');
  console.log('');
  process.exit(0);
}

const totalChangedBytes = regions.reduce((s, r) => s + r.length, 0);
console.log(`  ${regions.length} diff region(s), ${totalChangedBytes} changed byte(s) total`);
if (regions.length > MAX_REGIONS) {
  console.log(`  (showing first ${MAX_REGIONS} of ${regions.length} regions — use --max to change)`);
}
console.log('');

const shown = regions.slice(0, MAX_REGIONS);
for (const r of shown) {
  const sym = nearestSymbol(r.start);
  const symLabel = sym
    ? `${sym.name} + $${hex(r.start - sym.addr, 0)}`
    : '(no symbol)';

  console.log(hr);
  console.log(
    `  OFFSET $${hex(r.start, 8)}  length=${r.length}  ${symLabel}`
  );
  console.log('');

  // Context before
  const ctxBefore = Math.max(0, r.start - CONTEXT);
  if (ctxBefore < r.start) {
    const contextLen = r.start - ctxBefore;
    if (SHOW_BYTES) {
      console.log(`  context before:`);
      console.log(`    ${fmtLine(romA, ctxBefore, contextLen)}`);
    }
  }

  // Changed bytes
  const chunkLen = Math.min(r.length, 64);  // cap display at 64 bytes per region
  console.log(`  A: ${fmtLine(romA, r.start, chunkLen)}`);
  console.log(`  B: ${fmtLine(romB, r.start, chunkLen)}`);
  if (r.length > 64) {
    console.log(`     ... (${r.length - 64} more changed bytes not shown)`);
  }

  // Context after
  const ctxAfterStart = r.end + 1;
  const ctxAfterEnd   = Math.min(ctxAfterStart + CONTEXT, romA.length);
  if (SHOW_BYTES && ctxAfterStart < ctxAfterEnd) {
    console.log(`  context after:`);
    console.log(`    ${fmtLine(romA, ctxAfterStart, ctxAfterEnd - ctxAfterStart)}`);
  }
  console.log('');
}

if (regions.length > MAX_REGIONS) {
  console.log(hr);
  console.log(`  ... ${regions.length - MAX_REGIONS} more region(s) not shown. Use --max to increase limit.`);
  console.log('');
}

console.log(hr);
console.log(`  RESULT: ${regions.length} diff region(s), ${totalChangedBytes} changed byte(s)`);
console.log(hr + '\n');

process.exit(1);
