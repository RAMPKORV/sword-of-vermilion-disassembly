#!/usr/bin/env node
// tools/editor/map_editor.js
// Sword of Vermilion — Interactive Map Tile Editor
//
// Loads an RLE-compressed overworld sector or cave room binary file,
// decompresses it to a 16×16 tile grid, displays it, and allows the user
// to set individual tile values. The edited grid is RLE-recompressed and
// written back to the .bin file.
//
// IMPORTANT: The recompressed output must be the same byte length as the
// original file, because all map .bin files are directly incbin'd by the
// assembler (src/mapdata.asm). A size mismatch would shift subsequent data
// and break the bit-perfect build. The editor warns if sizes differ and
// requires --force to override.
//
// RLE Format (DecompressMapSectorRLE in src/dungeon.asm):
//   Byte < $80  → emit literal tile value
//   Byte >= $80 → RLE run: count = (byte - $80) + 1 (DBF semantics)
//                 next byte = tile value; emit tile (count) times
//
// Usage:
//   node tools/editor/map_editor.js overworld X Y              -- edit sector
//   node tools/editor/map_editor.js cave N                     -- edit cave room
//   node tools/editor/map_editor.js overworld X Y --show       -- display only
//   node tools/editor/map_editor.js cave N --show              -- display only
//   node tools/editor/map_editor.js overworld X Y set COL ROW TILE
//   node tools/editor/map_editor.js cave N set COL ROW TILE
//   node tools/editor/map_editor.js overworld X Y set COL ROW TILE --force
//
// Examples:
//   node tools/editor/map_editor.js overworld 5 3 --show
//   node tools/editor/map_editor.js cave 0 --show
//   node tools/editor/map_editor.js overworld 5 3 set 8 4 0x06
//   node tools/editor/map_editor.js cave 7 set 3 11 0x05
//   node tools/editor/map_editor.js cave 7 set 3 11 5 --force

'use strict';

const fs   = require('fs');
const path = require('path');
const readline = require('readline');

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------
const MAPS_DIR  = path.join(__dirname, '..', '..', 'data', 'maps');
const OW_DIR    = path.join(MAPS_DIR, 'overworld');
const CAVE_DIR  = path.join(MAPS_DIR, 'cave');

const MAP_WIDTH  = 16;
const MAP_HEIGHT = 16;
const MAP_TILES  = MAP_WIDTH * MAP_HEIGHT; // 256

const MAX_RUN_LENGTH = 128; // (0xFF - 0x80) + 1
const MAX_TILE_VALUE = 0xFF;

// ---------------------------------------------------------------------------
// Tile legend (matches map_viewer.js)
// ---------------------------------------------------------------------------
const TILE_CHARS = {
  0x00: '.',   // Ground / floor
  0x01: 'T',   // Tree (impassable)
  0x02: 'R',   // Rock (impassable)
  0x03: 'r',   // Rock variant
  0x04: 'r',   // Rock variant
  0x05: '#',   // Cave rock (impassable)
  0x06: '+',   // Path / road
  0x07: 's',   // Sand
  0x08: 'w',   // Water / sea
  0x09: 'm',   // Mountain
  0x0A: 'M',   // Mountain variant
  0x0B: 'f',   // Forest
  0x0C: 'b',   // Bridge
  0x0D: 'd',   // Desert
  0x0E: 'g',   // Grassland variant
  0x0F: 'H',   // House (impassable)
  0xFF: 'X',   // Cave exit
};

function tileChar(t) {
  if (t in TILE_CHARS) return TILE_CHARS[t];
  if (t >= 0x10 && t < 0x20) return String.fromCharCode(48 + (t & 0xF)); // Cave entrance: '0'-'F'
  if (t >= 0x80 && t < 0x90) return String.fromCharCode(65 + (t & 0xF)); // Town entrance: 'A'-'F'
  return t.toString(16).slice(-1);
}

// ---------------------------------------------------------------------------
// RLE Decompressor (matches DecompressMapSectorRLE in src/dungeon.asm)
// ---------------------------------------------------------------------------
function decompressRLE(buf) {
  const tiles = new Uint8Array(MAP_TILES);
  let src = 0;
  let dst = 0;

  while (src < buf.length && dst < MAP_TILES) {
    const b = buf[src++];
    if (b < 0x80) {
      tiles[dst++] = b;
    } else {
      const count = (b - 0x80) + 1; // DBF semantics: $80 = 1 copy, $81 = 2 copies, etc.
      const tile  = buf[src++];
      for (let i = 0; i < count && dst < MAP_TILES; i++) {
        tiles[dst++] = tile;
      }
    }
  }

  if (dst !== MAP_TILES) {
    process.stderr.write(
      `WARNING: decompressed ${dst} tiles (expected ${MAP_TILES})\n`
    );
  }

  return tiles;
}

// ---------------------------------------------------------------------------
// RLE Compressor — produces minimal RLE encoding.
// Uses runs of length >= 2, and encodes single tiles as literals.
// The run byte for N repetitions of tile T is: (N - 1 + 0x80), T
// Max run length is 128 (run byte 0xFF = 128 copies).
// ---------------------------------------------------------------------------
function compressRLE(tiles) {
  const out = [];
  let i = 0;

  while (i < tiles.length) {
    // Count how many consecutive identical tiles follow
    let runLen = 1;
    while (
      i + runLen < tiles.length &&
      tiles[i + runLen] === tiles[i] &&
      runLen < MAX_RUN_LENGTH
    ) {
      runLen++;
    }

    if (runLen >= 2) {
      // Encode as RLE run: byte = (runLen - 1) + 0x80, then tile value
      out.push((runLen - 1) + 0x80);
      out.push(tiles[i]);
    } else {
      // Encode as literal (tile value must be < 0x80)
      // If the tile value is >= 0x80, it MUST be encoded as a run of 1
      if (tiles[i] >= 0x80) {
        // Run of 1: $80 = (1 - 1) + 0x80, then tile
        out.push(0x80);
        out.push(tiles[i]);
      } else {
        out.push(tiles[i]);
      }
    }
    i += runLen;
  }

  return Buffer.from(out);
}

// ---------------------------------------------------------------------------
// Render a 16×16 tile grid as ASCII art with coordinate axes.
// Optionally highlight a specific cell (col, row).
// ---------------------------------------------------------------------------
function renderGrid(tiles, title, highlightCol = -1, highlightRow = -1) {
  const lines = [];
  lines.push(title);
  lines.push('   0123456789ABCDEF  (col)');
  for (let row = 0; row < MAP_HEIGHT; row++) {
    const chars = [];
    for (let col = 0; col < MAP_WIDTH; col++) {
      const t = tiles[row * MAP_WIDTH + col];
      let ch = tileChar(t);
      if (col === highlightCol && row === highlightRow) {
        ch = '*'; // Highlight the modified tile
      }
      chars.push(ch);
    }
    const prefix = row.toString(16).toUpperCase().padStart(1, '0');
    lines.push(`${prefix}  ${chars.join('')}`);
  }
  lines.push('(row)');
  return lines.join('\n');
}

// ---------------------------------------------------------------------------
// Tile legend footer
// ---------------------------------------------------------------------------
function renderLegend() {
  return [
    'Tile legend:',
    '  .  ground/floor    T  tree           R  rock (impassable)',
    '  H  house           #  cave rock       X  cave exit',
    '  +  path/road       w  water           m  mountain',
    '  f  forest          b  bridge          d  desert',
    '  0-F  cave entrance (hex digit = entrance ID)',
    '  A-P  town entrance (letter = town ID)',
  ].join('\n');
}

// ---------------------------------------------------------------------------
// File path resolution
// ---------------------------------------------------------------------------
function resolveOverworldPath(x, y) {
  return path.join(OW_DIR, `sector_${x}_${y}.bin`);
}

function resolveCavePath(index) {
  return path.join(CAVE_DIR, `room_${String(index).padStart(2, '0')}.bin`);
}

// ---------------------------------------------------------------------------
// Load map: returns { filePath, originalBuf, tiles }
// ---------------------------------------------------------------------------
function loadMap(filePath) {
  if (!fs.existsSync(filePath)) {
    console.error(`Error: file not found: ${filePath}`);
    process.exit(1);
  }
  const originalBuf = fs.readFileSync(filePath);
  const tiles = decompressRLE(originalBuf);
  return { filePath, originalBuf, tiles };
}

// ---------------------------------------------------------------------------
// Save map: RLE-compress tiles and write back to file.
// Checks that compressed size matches original. If sizes differ, warns and
// requires --force to proceed.
// ---------------------------------------------------------------------------
function saveMap(filePath, tiles, originalSize, force = false) {
  const compressed = compressRLE(tiles);

  if (compressed.length !== originalSize) {
    const delta = compressed.length - originalSize;
    const sign  = delta > 0 ? '+' : '';
    console.error('');
    console.error('ERROR: Recompressed size mismatch!');
    console.error(`  Original:     ${originalSize} bytes`);
    console.error(`  Recompressed: ${compressed.length} bytes  (${sign}${delta})`);
    console.error('');
    console.error('Map .bin files are directly incbin\'d by the assembler (src/mapdata.asm).');
    console.error('A size change will shift subsequent data and break the bit-perfect build.');
    console.error('');
    console.error('Options:');
    console.error('  1. Choose a different tile value or location that produces the same RLE encoding size.');
    console.error('  2. Use --force to write anyway (WILL break the build unless you adjust other maps).');
    console.error('');

    if (!force) {
      process.exit(1);
    }

    console.error('WARNING: --force specified. Writing mismatched size. Build will likely fail.');
  }

  fs.writeFileSync(filePath, compressed);
  console.log(`Wrote ${compressed.length} bytes to ${filePath}`);

  if (compressed.length === originalSize) {
    console.log('Size check: OK (same as original)');
  }
}

// ---------------------------------------------------------------------------
// Validate tile coordinates and value
// ---------------------------------------------------------------------------
function validateCoords(col, row) {
  if (isNaN(col) || col < 0 || col >= MAP_WIDTH) {
    console.error(`Error: column must be 0–${MAP_WIDTH - 1}, got: ${col}`);
    process.exit(1);
  }
  if (isNaN(row) || row < 0 || row >= MAP_HEIGHT) {
    console.error(`Error: row must be 0–${MAP_HEIGHT - 1}, got: ${row}`);
    process.exit(1);
  }
}

function parseTileValue(str) {
  let val;
  if (str.startsWith('0x') || str.startsWith('0X') || str.startsWith('$')) {
    val = parseInt(str.replace('$', '0x'), 16);
  } else {
    val = parseInt(str, 10);
  }
  if (isNaN(val) || val < 0 || val > MAX_TILE_VALUE) {
    console.error(`Error: tile value must be 0–255 (0x00–0xFF), got: ${str}`);
    process.exit(1);
  }
  return val;
}

function parseCoord(str, axis) {
  let val;
  if (str.startsWith('0x') || str.startsWith('0X')) {
    val = parseInt(str, 16);
  } else {
    val = parseInt(str, 10);
  }
  if (isNaN(val)) {
    console.error(`Error: invalid ${axis} coordinate: ${str}`);
    process.exit(1);
  }
  return val;
}

// ---------------------------------------------------------------------------
// Interactive mode — prompts user for set commands until 'quit'
// ---------------------------------------------------------------------------
function interactiveMode(mapData, force) {
  const { filePath, originalBuf, tiles } = mapData;
  const originalSize = originalBuf.length;
  let modified = false;

  console.log(renderGrid(tiles, `Map: ${filePath}`));
  console.log('');
  console.log(renderLegend());
  console.log('');
  console.log('Commands:');
  console.log('  set COL ROW TILE   -- set tile at (COL, ROW) to TILE value (hex: 0x06 or $06, decimal: 6)');
  console.log('  show               -- redisplay the grid');
  console.log('  show COL ROW       -- show tile value at (COL, ROW)');
  console.log('  save               -- RLE-compress and write back to file');
  console.log('  quit               -- exit (warns if unsaved changes)');
  console.log('');

  const rl = readline.createInterface({
    input:  process.stdin,
    output: process.stdout,
    prompt: 'map> ',
  });

  rl.prompt();

  rl.on('line', (line) => {
    const parts = line.trim().split(/\s+/);
    const cmd = parts[0];

    if (!cmd) {
      rl.prompt();
      return;
    }

    if (cmd === 'set') {
      if (parts.length < 4) {
        console.log('Usage: set COL ROW TILE');
        rl.prompt();
        return;
      }
      const col  = parseCoord(parts[1], 'column');
      const row  = parseCoord(parts[2], 'row');
      const tile = parseTileValue(parts[3]);
      validateCoords(col, row);

      const idx = row * MAP_WIDTH + col;
      const old = tiles[idx];
      tiles[idx] = tile;
      modified = true;

      const oldHex = old.toString(16).padStart(2, '0').toUpperCase();
      const newHex = tile.toString(16).padStart(2, '0').toUpperCase();
      console.log(`Set (${col}, ${row}): $${oldHex} (${tileChar(old)}) → $${newHex} (${tileChar(tile)})`);
      console.log('');
      console.log(renderGrid(tiles, `Map: ${filePath}`, col, row));
      rl.prompt();
      return;
    }

    if (cmd === 'show') {
      if (parts.length >= 3) {
        const col  = parseCoord(parts[1], 'column');
        const row  = parseCoord(parts[2], 'row');
        validateCoords(col, row);
        const t   = tiles[row * MAP_WIDTH + col];
        const hex = t.toString(16).padStart(2, '0').toUpperCase();
        console.log(`Tile at (${col}, ${row}): $${hex} = ${tileChar(t)}`);
      } else {
        console.log(renderGrid(tiles, `Map: ${filePath}`));
      }
      rl.prompt();
      return;
    }

    if (cmd === 'save') {
      saveMap(filePath, tiles, originalSize, force);
      modified = false;
      rl.prompt();
      return;
    }

    if (cmd === 'quit' || cmd === 'exit' || cmd === 'q') {
      if (modified) {
        console.log('Warning: unsaved changes. Use "save" first, or run "quit" again to discard.');
        modified = false; // Second quit will succeed
        rl.prompt();
        return;
      }
      rl.close();
      return;
    }

    if (cmd === 'help' || cmd === '?') {
      console.log('Commands: set COL ROW TILE | show [COL ROW] | save | quit');
      rl.prompt();
      return;
    }

    console.log(`Unknown command: ${cmd}. Type "help" for available commands.`);
    rl.prompt();
  });

  rl.on('close', () => {
    process.exit(0);
  });
}

// ---------------------------------------------------------------------------
// CLI entry point
// ---------------------------------------------------------------------------
function printUsage() {
  console.log('Usage:');
  console.log('  node tools/editor/map_editor.js overworld X Y              -- interactive editor');
  console.log('  node tools/editor/map_editor.js cave N                     -- interactive editor');
  console.log('  node tools/editor/map_editor.js overworld X Y --show       -- display only');
  console.log('  node tools/editor/map_editor.js cave N --show              -- display only');
  console.log('  node tools/editor/map_editor.js overworld X Y set COL ROW TILE  -- single edit');
  console.log('  node tools/editor/map_editor.js cave N set COL ROW TILE         -- single edit');
  console.log('');
  console.log('Options:');
  console.log('  --show    Display the map and exit (no editing)');
  console.log('  --force   Write even if recompressed size differs from original (BREAKS BUILD)');
  console.log('');
  console.log('Tile values:');
  console.log('  Hex: 0x06 or $06    Decimal: 6    Range: 0x00–0xFF');
  console.log('');
  console.log('Common tile IDs:');
  console.log('  0x00 .  ground/floor    0x01 T  tree         0x02 R  rock (impassable)');
  console.log('  0x05 #  cave rock       0x06 +  path/road    0x08 w  water');
  console.log('  0x0F H  house           0xFF X  cave exit');
  console.log('  0x10-0x1F  cave entrance (ID = low nibble)');
  console.log('  0x80-0x8F  town entrance (ID = low nibble)');
  console.log('');
  console.log('IMPORTANT: Recompressed .bin size must match original (enforced by default).');
  console.log('           Files are incbin\'d by the assembler; size changes break the build.');
}

function main() {
  const args = process.argv.slice(2);

  if (args.length === 0 || args[0] === '--help' || args[0] === '-h') {
    printUsage();
    process.exit(0);
  }

  const showOnly = args.includes('--show');
  const force    = args.includes('--force');
  const filtered = args.filter(a => a !== '--show' && a !== '--force');

  const mode = filtered[0];

  let filePath;
  let setArgs = null; // [col, row, tile] strings if 'set' subcommand given

  if (mode === 'overworld') {
    const x = parseInt(filtered[1]);
    const y = parseInt(filtered[2]);
    if (isNaN(x) || isNaN(y)) {
      console.error('Error: overworld requires integer X and Y coordinates');
      printUsage();
      process.exit(1);
    }
    filePath = resolveOverworldPath(x, y);

    // Check for 'set' subcommand: overworld X Y set COL ROW TILE
    if (filtered[3] === 'set') {
      if (filtered.length < 7) {
        console.error('Error: set requires COL ROW TILE');
        process.exit(1);
      }
      setArgs = [filtered[4], filtered[5], filtered[6]];
    }

  } else if (mode === 'cave') {
    const index = parseInt(filtered[1]);
    if (isNaN(index)) {
      console.error('Error: cave requires an integer room index');
      printUsage();
      process.exit(1);
    }
    filePath = resolveCavePath(index);

    // Check for 'set' subcommand: cave N set COL ROW TILE
    if (filtered[2] === 'set') {
      if (filtered.length < 6) {
        console.error('Error: set requires COL ROW TILE');
        process.exit(1);
      }
      setArgs = [filtered[3], filtered[4], filtered[5]];
    }

  } else {
    console.error(`Error: unknown map type '${mode}'. Expected: overworld, cave`);
    printUsage();
    process.exit(1);
  }

  const mapData = loadMap(filePath);
  const { tiles, originalBuf } = mapData;

  // --show: display and exit
  if (showOnly) {
    console.log(renderGrid(tiles, `Map: ${filePath}`));
    console.log('');
    console.log(renderLegend());
    process.exit(0);
  }

  // Single-shot set subcommand
  if (setArgs) {
    const col  = parseCoord(setArgs[0], 'column');
    const row  = parseCoord(setArgs[1], 'row');
    const tile = parseTileValue(setArgs[2]);
    validateCoords(col, row);

    const idx = row * MAP_WIDTH + col;
    const old = tiles[idx];
    tiles[idx] = tile;

    const oldHex = old.toString(16).padStart(2, '0').toUpperCase();
    const newHex = tile.toString(16).padStart(2, '0').toUpperCase();
    console.log(`Set (${col}, ${row}): $${oldHex} (${tileChar(old)}) → $${newHex} (${tileChar(tile)})`);
    console.log('');
    console.log(renderGrid(tiles, `Map: ${filePath}`, col, row));
    console.log('');

    saveMap(filePath, tiles, originalBuf.length, force);
    process.exit(0);
  }

  // Interactive mode
  interactiveMode(mapData, force);
}

main();
