#!/usr/bin/env node
// tools/map_viewer.js
// Sword of Vermilion — Map Data Viewer/Dumper
//
// Reads RLE-compressed overworld sector and cave room binary files,
// decompresses them, and outputs ASCII visualizations.
//
// RLE Format (same for overworld and cave):
//   Byte < $80  → emit literal tile value
//   Byte >= $80 → RLE run: count = (byte - $80) + 1 (DBF semantics),
//                 next byte = tile value; emit tile (count) times
//
// Usage:
//   node tools/map_viewer.js overworld [X Y]       -- one sector or all
//   node tools/map_viewer.js cave [N]              -- one room or all
//   node tools/map_viewer.js overworld --all       -- dump all sectors (grid layout)
//   node tools/map_viewer.js cave --all            -- dump all rooms
//
// Examples:
//   node tools/map_viewer.js overworld 5 3         -- sector at X=5, Y=3
//   node tools/map_viewer.js cave 0                -- cave room 0
//   node tools/map_viewer.js overworld --all       -- full overworld grid

'use strict';

const fs   = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------
const MAPS_DIR  = path.join(__dirname, '..', 'data', 'maps');
const OW_DIR    = path.join(MAPS_DIR, 'overworld');
const CAVE_DIR  = path.join(MAPS_DIR, 'cave');

const MAP_WIDTH  = 16;   // tiles per row in a decompressed sector/room
const MAP_HEIGHT = 16;   // tiles per column
const MAP_TILES  = MAP_WIDTH * MAP_HEIGHT;   // 256 total

// ---------------------------------------------------------------------------
// Tile legend — ASCII representation for each tile type
// Only the documented special tiles have named symbols; other terrain tiles
// map to their hex digit (for debugging) or a generic '.' for $00 ground.
// ---------------------------------------------------------------------------
const TILE_CHARS = {
  0x00: '.',   // Ground / floor
  0x01: 'T',   // Tree (impassable)
  0x02: 'R',   // Rock (impassable) — most common overworld tile
  0x03: 'r',   // Rock variant
  0x04: 'r',   // Rock variant
  0x05: '#',   // Cave rock (impassable, used in cave rooms)
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
  0xFF: 'X',   // Cave exit (returns player to overworld)
};

function tileChar(t) {
  if (t in TILE_CHARS) return TILE_CHARS[t];
  if (t >= 0x10 && t < 0x20) return String.fromCharCode(48 + (t & 0xF)); // Cave entrance: '0'-'F'
  if (t >= 0x80 && t < 0x90) return String.fromCharCode(65 + (t & 0xF)); // Town entrance: 'A'-'F'
  // Fallback: hex nibble for unknown terrain tiles
  return t.toString(16).slice(-1);
}

// ---------------------------------------------------------------------------
// RLE Decompressor
// Matches the 68000 routine DecompressMapSectorRLE in src/dungeon.asm.
// DBF semantics: a run byte of $80+N emits N+1 copies of the tile.
// ---------------------------------------------------------------------------
function decompressRLE(buf) {
  const tiles = new Uint8Array(MAP_TILES);
  let src = 0;
  let dst = 0;

  while (src < buf.length && dst < MAP_TILES) {
    const b = buf[src++];
    if (b < 0x80) {
      // Literal tile
      tiles[dst++] = b;
    } else {
      // RLE run: (b - 0x80) + 1 copies  (DBF decrements after first write)
      const count = (b - 0x80) + 1;
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
// Format a 16×16 tile grid as ASCII art, with a header line.
// ---------------------------------------------------------------------------
function renderGrid(tiles, title, showHex = false) {
  const lines = [];
  lines.push(title);
  lines.push('  0123456789ABCDEF');
  for (let row = 0; row < MAP_HEIGHT; row++) {
    const chars = [];
    for (let col = 0; col < MAP_WIDTH; col++) {
      const t = tiles[row * MAP_WIDTH + col];
      chars.push(showHex ? t.toString(16).padStart(2, '0') : tileChar(t));
    }
    const prefix = row.toString(16).toUpperCase().padStart(1, '0');
    lines.push(`${prefix} ${showHex ? chars.join(' ') : chars.join('')}`);
  }
  return lines.join('\n');
}

// ---------------------------------------------------------------------------
// Load and decompress an overworld sector by (X, Y) coordinates.
// ---------------------------------------------------------------------------
function loadOverworldSector(x, y) {
  const file = path.join(OW_DIR, `sector_${x}_${y}.bin`);
  if (!fs.existsSync(file)) return null;
  const buf = fs.readFileSync(file);
  return decompressRLE(buf);
}

// ---------------------------------------------------------------------------
// Load and decompress a cave room by index.
// ---------------------------------------------------------------------------
function loadCaveRoom(index) {
  const name = `room_${String(index).padStart(2, '0')}.bin`;
  const file = path.join(CAVE_DIR, name);
  if (!fs.existsSync(file)) return null;
  const buf = fs.readFileSync(file);
  return decompressRLE(buf);
}

// ---------------------------------------------------------------------------
// Tile statistics summary (for understanding map contents at a glance)
// ---------------------------------------------------------------------------
function tileSummary(tiles) {
  const counts = {};
  for (const t of tiles) {
    counts[t] = (counts[t] || 0) + 1;
  }
  const sorted = Object.entries(counts).sort((a, b) => b[1] - a[1]);
  const lines = sorted.slice(0, 8).map(([t, n]) => {
    const hex = parseInt(t).toString(16).padStart(2, '0');
    const ch  = tileChar(parseInt(t));
    const pct = ((n / MAP_TILES) * 100).toFixed(1);
    return `  $${hex} (${ch}): ${n} tiles (${pct}%)`;
  });
  if (sorted.length > 8) lines.push(`  ... and ${sorted.length - 8} more tile types`);
  return lines.join('\n');
}

// ---------------------------------------------------------------------------
// Dump all available overworld sectors in a compact grid view.
// The overworld is a 16×8 grid; missing sectors are shown as '?'.
// ---------------------------------------------------------------------------
function dumpAllOverworld() {
  const OW_COLS = 16;
  const OW_ROWS = 8;

  console.log('=== OVERWORLD MAP (16×8 sectors, each 16×16 tiles) ===');
  console.log('Legend: . ground  T tree  R rock  H house  0-F cave  A-P town  X exit  ? missing\n');

  for (let sy = 0; sy < OW_ROWS; sy++) {
    // Print each of the 16 tile rows for this sector row
    for (let tileRow = 0; tileRow < MAP_HEIGHT; tileRow++) {
      const rowParts = [];
      for (let sx = 0; sx < OW_COLS; sx++) {
        const tiles = loadOverworldSector(sx, sy);
        if (!tiles) {
          // Missing sector — fill with '~' (ocean/void)
          rowParts.push('~~~~~~~~~~~~~~~~');
        } else {
          const rowTiles = [];
          for (let col = 0; col < MAP_WIDTH; col++) {
            rowTiles.push(tileChar(tiles[tileRow * MAP_WIDTH + col]));
          }
          rowParts.push(rowTiles.join(''));
        }
      }
      if (tileRow === 0) {
        // Print sector X coordinates header on top row
        process.stdout.write(`Y${sy}|`);
      } else {
        process.stdout.write('  |');
      }
      console.log(rowParts.join('|'));
    }
    console.log('');
  }
}

// ---------------------------------------------------------------------------
// Dump all cave rooms.
// ---------------------------------------------------------------------------
function dumpAllCave() {
  const caveFiles = fs.readdirSync(CAVE_DIR)
    .filter(f => f.match(/^room_\d+\.bin$/))
    .sort();

  console.log(`=== CAVE ROOMS (${caveFiles.length} rooms) ===`);
  console.log('Legend: . floor  # cave rock  X exit  0-F/A-P entrances\n');

  for (const file of caveFiles) {
    const match = file.match(/room_(\d+)\.bin/);
    if (!match) continue;
    const index = parseInt(match[1]);
    const tiles = loadCaveRoom(index);
    if (!tiles) continue;
    console.log(renderGrid(tiles, `--- Room ${index} (${file}) ---`));
    console.log(tileSummary(tiles));
    console.log('');
  }
}

// ---------------------------------------------------------------------------
// CLI entry point
// ---------------------------------------------------------------------------
function printUsage() {
  console.log('Usage:');
  console.log('  node tools/map_viewer.js overworld X Y      -- single overworld sector');
  console.log('  node tools/map_viewer.js overworld --all    -- full overworld grid (all sectors)');
  console.log('  node tools/map_viewer.js cave N             -- single cave room');
  console.log('  node tools/map_viewer.js cave --all         -- all cave rooms');
  console.log('  node tools/map_viewer.js list               -- list available sectors/rooms');
  console.log('');
  console.log('Options:');
  console.log('  --hex    Show raw tile values as hex instead of ASCII symbols');
  console.log('');
  console.log('Tile legend:');
  console.log('  .  ground/floor     T  tree          R  rock');
  console.log('  H  house            #  cave rock      X  cave exit');
  console.log('  0-F cave entrance (ID = digit)');
  console.log('  A-P town entrance (ID = letter A=0)');
  console.log('  ~  missing sector (ocean/void)');
}

function listMaps() {
  const owFiles  = fs.readdirSync(OW_DIR).filter(f => f.match(/^sector_\d+_\d+\.bin$/));
  const caveFiles = fs.readdirSync(CAVE_DIR).filter(f => f.match(/^room_\d+\.bin$/));

  console.log(`Overworld sectors (${owFiles.length}):`);
  // Build a 16×8 presence grid
  const grid = Array.from({length: 8}, () => new Array(16).fill(false));
  for (const f of owFiles) {
    const m = f.match(/sector_(\d+)_(\d+)\.bin/);
    if (m) {
      const sx = parseInt(m[1]);
      const sy = parseInt(m[2]);
      if (sx < 16 && sy < 8) grid[sy][sx] = true;
    }
  }
  for (let sy = 0; sy < 8; sy++) {
    const row = grid[sy].map((present, sx) => present ? `${sx},${sy}`.padEnd(5) : '-----').join(' ');
    console.log(`  Y${sy}: ${row}`);
  }

  console.log('');
  console.log(`Cave rooms (${caveFiles.length}):`);
  console.log(' ', caveFiles.map(f => f.replace('.bin', '')).join('  '));
}

function main() {
  const args = process.argv.slice(2);
  const showHex = args.includes('--hex');
  const filteredArgs = args.filter(a => a !== '--hex');

  if (filteredArgs.length === 0 || filteredArgs[0] === '--help' || filteredArgs[0] === '-h') {
    printUsage();
    process.exit(0);
  }

  const mode = filteredArgs[0];

  if (mode === 'list') {
    listMaps();
    return;
  }

  if (mode === 'overworld') {
    if (filteredArgs[1] === '--all' || filteredArgs.length === 1) {
      dumpAllOverworld();
      return;
    }
    const x = parseInt(filteredArgs[1]);
    const y = parseInt(filteredArgs[2]);
    if (isNaN(x) || isNaN(y)) {
      console.error('Error: overworld requires X and Y integer coordinates');
      process.exit(1);
    }
    const tiles = loadOverworldSector(x, y);
    if (!tiles) {
      console.error(`Error: sector_${x}_${y}.bin not found in ${OW_DIR}`);
      process.exit(1);
    }
    console.log(renderGrid(tiles, `Overworld Sector (${x}, ${y}) — data/maps/overworld/sector_${x}_${y}.bin`, showHex));
    console.log('');
    console.log('Tile distribution:');
    console.log(tileSummary(tiles));
    return;
  }

  if (mode === 'cave') {
    if (filteredArgs[1] === '--all' || filteredArgs.length === 1) {
      dumpAllCave();
      return;
    }
    const index = parseInt(filteredArgs[1]);
    if (isNaN(index)) {
      console.error('Error: cave requires a room index integer');
      process.exit(1);
    }
    const tiles = loadCaveRoom(index);
    if (!tiles) {
      console.error(`Error: room_${String(index).padStart(2,'0')}.bin not found in ${CAVE_DIR}`);
      process.exit(1);
    }
    console.log(renderGrid(tiles, `Cave Room ${index} — data/maps/cave/room_${String(index).padStart(2,'0')}.bin`, showHex));
    console.log('');
    console.log('Tile distribution:');
    console.log(tileSummary(tiles));
    return;
  }

  console.error(`Error: unknown mode '${mode}'. Expected: overworld, cave, list`);
  printUsage();
  process.exit(1);
}

main();
