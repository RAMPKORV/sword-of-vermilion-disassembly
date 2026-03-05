#!/usr/bin/env node
// tools/palette_viewer.js
// Sword of Vermilion — Palette Data Viewer/Dumper
//
// Reads the PaletteDataTable from data/art/palettes/palette_data.bin and
// outputs palette contents in human-readable form (indexed hex + RGB) with
// optional 256-color ANSI terminal color swatches.
//
// Genesis CRAM color format (16-bit big-endian word):
//   bit 15: unused
//   bits 14-12: unused
//   bits 11-9:  blue  (3 bits, value 0-7 → 0, 36, 73, 109, 146, 182, 219, 255)
//   bit 8: unused (0)
//   bits 7-5:   green (3 bits, same scale)
//   bit 4: unused (0)
//   bits 3-1:   red   (3 bits, same scale)
//   bit 0: unused (0)
//
// Genesis 3-bit channel to 8-bit linear: channel * 36 (0,36,73,109,146,182,219,255)
// (Nintendo documents it as x*36+x>0?1:0 but most emulators use x*36.)
//
// Usage:
//   node tools/palette_viewer.js [options] [palette_index ...]
//
//   No arguments          — list all palettes (one per line, hex values)
//   --index N [N ...]     — show only these palette indices
//   --name                — show known palette names next to indices
//   --swatches            — render ANSI 256-color swatches for each color
//   --html FILE           — write an HTML color swatch sheet to FILE
//   --all                 — show all palettes with full color detail
//   --csv                 — output as CSV (index, color_slot, r, g, b, hex_24bit)
//
// Examples:
//   node tools/palette_viewer.js --all
//   node tools/palette_viewer.js --index 18 --swatches
//   node tools/palette_viewer.js --name --all
//   node tools/palette_viewer.js --html palettes.html

'use strict';

const fs   = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const ROOT         = path.resolve(__dirname, '..');
const PALETTE_FILE = path.join(ROOT, 'data', 'art', 'palettes', 'palette_data.bin');
const COLORS_PER_PALETTE = 16;
const BYTES_PER_COLOR    = 2;  // 16-bit CRAM word
const BYTES_PER_PALETTE  = COLORS_PER_PALETTE * BYTES_PER_COLOR;  // 32

// ---------------------------------------------------------------------------
// Known palette names (from game_constants.asm PALETTE_IDX_* constants)
// ---------------------------------------------------------------------------

const PALETTE_NAMES = {
  0x0011: 'TOWN_HUD (player sprite, status bar)',
  0x0012: 'TOWN_TILES (torches, walls, floor)',
  0x0013: 'BATTLE_OUTDOOR (grass/field ground)',
  0x0027: 'TITLE_TILES',
  0x0028: 'TITLE_BG',
  0x0029: 'TITLE_LOGO',
  0x0030: 'TITLE_LIGHTNING',
  0x0032: 'NAMEENTRY_BG',
  0x0033: 'NAMEENTRY_GLOW1',
  0x0034: 'NAMEENTRY_GLOW2',
  0x0036: 'CAVE_WALLS',
  0x0037: 'OVERWORLD_LINE1',
  0x0038: 'OVERWORLD_LINE2 / CAVE_FLOOR',
  0x0040: 'CAVE_ANIM_BASE (torch cycle start)',
  0x0047: 'CAVE_ANIM_END (torch cycle end)',
  0x003F: 'CAVE_ANIM_ALT (torch cycle alt end)',
  0x0048: 'CAVE_FLOOR_LIT (light spell)',
  0x004F: 'PROLOGUE_BG',
  0x0050: 'PROLOGUE_LINE1',
  0x0051: 'PROLOGUE_LINE2',
  0x0052: 'PROLOGUE_SCENE',
  0x0072: 'CAVE_POISON',
  0x0083: 'TOWN_DARK (Carthahena under Tsarkon)',
  0x0084: 'ALL_WHITE (flash)',
  0x0085: 'ENDING_TEXT_BG',
  0x0094: 'ALL_BLACK',
  0x0095: 'ENDING_FIRE',
  0x0096: 'ENDING_CURSOR_MIN',
};

// ---------------------------------------------------------------------------
// Color conversion
// ---------------------------------------------------------------------------

// Genesis 3-bit channel to 8-bit: 0→0, 1→36, 2→73, ..., 7→255
function channel3to8(c) {
  const table = [0, 36, 73, 109, 146, 182, 219, 255];
  return table[c & 7];
}

// Decode one 16-bit big-endian Genesis CRAM word to {r, g, b}
function decodeCramWord(hi, lo) {
  const word = (hi << 8) | lo;
  const b = (word >> 9) & 7;
  const g = (word >> 5) & 7;
  const r = (word >> 1) & 7;
  return { r: channel3to8(r), g: channel3to8(g), b: channel3to8(b) };
}

// Format as CSS hex
function toHex24(r, g, b) {
  return '#' + [r, g, b].map(v => v.toString(16).padStart(2, '0')).join('').toUpperCase();
}

// ---------------------------------------------------------------------------
// ANSI 256-color swatch (nearest color approximation)
// ---------------------------------------------------------------------------

// Map 0-255 to the nearest xterm-256 color cube entry for terminal display.
// The xterm 6×6×6 color cube occupies indices 16-231:
//   index = 16 + 36*r + 6*g + b   where r/g/b are 0-5 (each maps ~0,95,135,175,215,255)
function rgbToXterm256(r, g, b) {
  function toIdx(v) {
    if (v < 48)  return 0;
    if (v < 115) return 1;
    return Math.floor((v - 35) / 40);
  }
  const ri = toIdx(r);
  const gi = toIdx(g);
  const bi = toIdx(b);
  return 16 + 36 * ri + 6 * gi + bi;
}

function ansiFgFor(r, g, b) {
  // Use white or black foreground depending on luminance
  const lum = 0.299 * r + 0.587 * g + 0.114 * b;
  return lum > 128 ? '\x1b[38;5;0m' : '\x1b[38;5;255m';
}

function colorSwatch(r, g, b) {
  const bg  = rgbToXterm256(r, g, b);
  const fg  = ansiFgFor(r, g, b);
  return `\x1b[48;5;${bg}m${fg}  \x1b[0m`;
}

// ---------------------------------------------------------------------------
// Load palette data
// ---------------------------------------------------------------------------

function loadPalettes() {
  const buf = fs.readFileSync(PALETTE_FILE);
  const count = Math.floor(buf.length / BYTES_PER_PALETTE);
  const palettes = [];
  for (let i = 0; i < count; i++) {
    const colors = [];
    const base = i * BYTES_PER_PALETTE;
    for (let c = 0; c < COLORS_PER_PALETTE; c++) {
      const off = base + c * BYTES_PER_COLOR;
      const hi = buf[off];
      const lo = buf[off + 1];
      const raw = (hi << 8) | lo;
      const rgb = decodeCramWord(hi, lo);
      colors.push({ raw, ...rgb });
    }
    palettes.push(colors);
  }
  return palettes;
}

// ---------------------------------------------------------------------------
// Output formatters
// ---------------------------------------------------------------------------

function printPaletteOneLine(idx, colors, opts) {
  const name = opts.showNames ? (PALETTE_NAMES[idx] ? ` — ${PALETTE_NAMES[idx]}` : '') : '';
  const hexList = colors.map(c => `$${c.raw.toString(16).padStart(4,'0').toUpperCase()}`).join(' ');
  process.stdout.write(`Palette $${idx.toString(16).padStart(4,'0').toUpperCase()} [${String(idx).padStart(3)}]${name}: ${hexList}\n`);
}

function printPaletteDetail(idx, colors, opts) {
  const name = opts.showNames ? (PALETTE_NAMES[idx] ? ` — ${PALETTE_NAMES[idx]}` : '') : '';
  console.log(`\nPalette $${idx.toString(16).padStart(4,'0').toUpperCase()} [${String(idx).padStart(3)}]${name}`);
  for (let c = 0; c < colors.length; c++) {
    const col = colors[c];
    const raw = `$${col.raw.toString(16).padStart(4,'0').toUpperCase()}`;
    const hex = toHex24(col.r, col.g, col.b);
    const rgb = `R=${String(col.r).padStart(3)} G=${String(col.g).padStart(3)} B=${String(col.b).padStart(3)}`;
    const swatch = opts.swatches ? colorSwatch(col.r, col.g, col.b) : '';
    process.stdout.write(`  [${String(c).padStart(2)}] ${raw} ${hex} ${rgb}${swatch ? ' ' + swatch : ''}\n`);
  }
}

function printAllCSV(palettes) {
  console.log('palette_index,color_slot,r8,g8,b8,hex_24bit,cram_raw');
  palettes.forEach((colors, idx) => {
    colors.forEach((col, c) => {
      const hex = toHex24(col.r, col.g, col.b).slice(1);
      const raw = col.raw.toString(16).padStart(4,'0').toUpperCase();
      process.stdout.write(`${idx},${c},${col.r},${col.g},${col.b},${hex},${raw}\n`);
    });
  });
}

// ---------------------------------------------------------------------------
// HTML output
// ---------------------------------------------------------------------------

function writeHTML(outFile, palettes, showNames) {
  const rows = palettes.map((colors, idx) => {
    const swatches = colors.map((col, c) => {
      const hex = toHex24(col.r, col.g, col.b);
      const lum = 0.299 * col.r + 0.587 * col.g + 0.114 * col.b;
      const fg  = lum > 128 ? '#000' : '#fff';
      const title = `Slot ${c}: ${hex} R=${col.r} G=${col.g} B=${col.b} (raw $${col.raw.toString(16).padStart(4,'0').toUpperCase()})`;
      return `<td title="${title}" style="background:${hex};color:${fg};width:18px;height:18px;font-size:9px;text-align:center">${c.toString(16).toUpperCase()}</td>`;
    }).join('');
    const idxHex = idx.toString(16).padStart(4,'0').toUpperCase();
    const name   = showNames && PALETTE_NAMES[idx] ? ` <span style="color:#888;font-size:11px">${PALETTE_NAMES[idx]}</span>` : '';
    return `<tr><td style="font-family:monospace;font-size:12px;padding-right:8px;white-space:nowrap">$${idxHex} [${idx}]${name}</td>${swatches}</tr>`;
  }).join('\n');

  const html = `<!DOCTYPE html>
<html><head><meta charset="utf-8">
<title>Sword of Vermilion — Palette Table (${palettes.length} palettes)</title>
<style>
  body { font-family: monospace; background: #1a1a1a; color: #ddd; padding: 20px; }
  h1   { font-size: 18px; margin-bottom: 4px; }
  p    { font-size: 12px; color: #888; margin: 0 0 16px; }
  table { border-collapse: collapse; }
  td   { border: 1px solid #333; }
</style></head><body>
<h1>Sword of Vermilion — PaletteDataTable</h1>
<p>${palettes.length} palettes × 16 colors × 2 bytes (Genesis CRAM BGR555 format)</p>
<table>
${rows}
</table>
</body></html>`;

  fs.writeFileSync(outFile, html);
  console.log(`Wrote ${outFile} (${palettes.length} palettes)`);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function printUsage() {
  console.log(`
Usage: node tools/palette_viewer.js [options] [index ...]

Options:
  --all             Show all palettes (detail view)
  --index N ...     Show specific palette indices (detail view)
  --name            Annotate known palette names
  --swatches        Show ANSI color swatches in terminal (requires 256-color support)
  --html FILE       Write HTML swatch sheet to FILE
  --csv             Output as CSV (all palettes)
  (no options)      List all palettes one-line each (hex CRAM values)

Examples:
  node tools/palette_viewer.js                   -- one-line list of all palettes
  node tools/palette_viewer.js --all --name      -- full detail + names
  node tools/palette_viewer.js --index 18 --swatches
  node tools/palette_viewer.js --html out.html --name
  node tools/palette_viewer.js --csv > palettes.csv
`);
}

function main() {
  const args = process.argv.slice(2);
  if (args.includes('--help') || args.includes('-h')) { printUsage(); process.exit(0); }

  const showAll    = args.includes('--all');
  const showNames  = args.includes('--name');
  const swatches   = args.includes('--swatches');
  const csv        = args.includes('--csv');
  const htmlIdx    = args.indexOf('--html');
  const htmlFile   = htmlIdx >= 0 ? args[htmlIdx + 1] : null;

  // Collect explicit indices
  const indices = [];
  const indexIdx = args.indexOf('--index');
  if (indexIdx >= 0) {
    for (let i = indexIdx + 1; i < args.length; i++) {
      if (args[i].startsWith('--')) break;
      const n = args[i].startsWith('0x') || args[i].startsWith('$')
        ? parseInt(args[i].replace('$', ''), 16)
        : parseInt(args[i], 10);
      if (!isNaN(n)) indices.push(n);
    }
  }

  const palettes = loadPalettes();

  if (csv) {
    printAllCSV(palettes);
    return;
  }

  if (htmlFile) {
    writeHTML(htmlFile, palettes, showNames);
    return;
  }

  const opts = { showNames, swatches };

  if (showAll || indices.length > 0) {
    const targets = showAll ? palettes.map((_, i) => i) : indices;
    for (const idx of targets) {
      if (idx < 0 || idx >= palettes.length) {
        console.error(`Palette index ${idx} out of range (0-${palettes.length - 1})`);
        continue;
      }
      printPaletteDetail(idx, palettes[idx], opts);
    }
  } else {
    // Default: one-line list
    console.log(`PaletteDataTable: ${palettes.length} palettes × ${COLORS_PER_PALETTE} colors`);
    console.log(`File: ${PALETTE_FILE}\n`);
    palettes.forEach((colors, idx) => {
      printPaletteOneLine(idx, colors, opts);
    });
  }
}

main();
