'use strict';

const fs = require('fs');
const path = require('path');

const { connectedComponents, toIndex } = require('./pathfinder');

const PROJECT_ROOT = path.join(__dirname, '..', '..');
const MAPS_DIR = path.join(PROJECT_ROOT, 'data', 'maps');
const OVERWORLD_DIR = path.join(MAPS_DIR, 'overworld');
const TOOLS_DATA_DIR = path.join(PROJECT_ROOT, 'tools', 'data');

const MAP_WIDTH = 16;
const MAP_HEIGHT = 16;
const MAP_TILE_COUNT = MAP_WIDTH * MAP_HEIGHT;
const WORLD_SECTOR_COLS = 16;
const WORLD_SECTOR_ROWS = 8;
const WORLD_TILE_WIDTH = WORLD_SECTOR_COLS * MAP_WIDTH;
const WORLD_TILE_HEIGHT = WORLD_SECTOR_ROWS * MAP_HEIGHT;

const TOWN_NAMES = [
  'Wyclif',
  'Parma',
  'Watling',
  'Deepdale',
  'Stow-1',
  'Stow-2',
  'Keltwick',
  'Malaga',
  'Barrow',
  'Tadcaster',
  'Helwig',
  'Swaffham',
  'Excalabria',
  'Hastings-1',
  'Hastings-2',
  'Carthahena',
];

const IMPASSABLE_TILES = new Set([
  0x01, 0x02, 0x03, 0x04, 0x05, 0x08, 0x09, 0x0A, 0x0F,
]);

function isSpecialTile(tile) {
  return (tile >= 0x10 && tile < 0x20) || (tile >= 0x80 && tile < 0x90) || tile === 0xFF;
}

function isWalkableTile(tile) {
  if (isSpecialTile(tile)) return true;
  return !IMPASSABLE_TILES.has(tile);
}

function describeSpecial(tile) {
  if (tile >= 0x80 && tile < 0x90) {
    const id = tile & 0x0F;
    return {
      key: `town:${id}`,
      kind: 'town',
      id,
      label: TOWN_NAMES[id] || `Town-${id.toString(16).toUpperCase()}`,
    };
  }
  if (tile >= 0x10 && tile < 0x20) {
    const id = tile & 0x0F;
    return {
      key: `cave:${id}`,
      kind: 'cave',
      id,
      label: `Cave-${id.toString(16).toUpperCase()}`,
    };
  }
  return {
    key: 'exit:ff',
    kind: 'exit',
    id: 0xFF,
    label: 'Exit',
  };
}

function decompressRLE(buffer) {
  const tiles = new Uint8Array(MAP_TILE_COUNT);
  let src = 0;
  let dst = 0;

  while (src < buffer.length && dst < MAP_TILE_COUNT) {
    const value = buffer[src++];
    if (value < 0x80) {
      tiles[dst++] = value;
      continue;
    }

    const count = value - 0x80 + 1;
    const tile = buffer[src++];
    for (let i = 0; i < count && dst < MAP_TILE_COUNT; i += 1) {
      tiles[dst++] = tile;
    }
  }

  return tiles;
}

function compressRLE(tiles) {
  const out = [];
  let index = 0;

  while (index < tiles.length) {
    let runLength = 1;
    while (
      index + runLength < tiles.length &&
      tiles[index + runLength] === tiles[index] &&
      runLength < 128
    ) {
      runLength += 1;
    }

    if (runLength >= 2 || tiles[index] >= 0x80) {
      out.push(0x80 + runLength - 1, tiles[index]);
      index += runLength;
      continue;
    }

    out.push(tiles[index]);
    index += 1;
  }

  return Buffer.from(out);
}

function cloneTiles(tiles) {
  return Uint8Array.from(tiles);
}

function getSpecials(tiles) {
  const specials = [];
  for (let index = 0; index < tiles.length; index += 1) {
    const tile = tiles[index];
    if (!isSpecialTile(tile)) continue;
    specials.push({
      tile,
      index,
      row: Math.floor(index / MAP_WIDTH),
      col: index % MAP_WIDTH,
      ...describeSpecial(tile),
    });
  }
  return specials;
}

function encodeBoundarySignature(tiles) {
  const { componentIds } = connectedComponents({
    width: MAP_WIDTH,
    height: MAP_HEIGHT,
    canVisit(index) {
      return isWalkableTile(tiles[index]);
    },
  });

  const labels = new Map();
  let nextLabel = 0;

  function labelFor(componentId) {
    if (componentId < 0) return '.';
    if (!labels.has(componentId)) {
      labels.set(componentId, nextLabel.toString(36).toUpperCase());
      nextLabel += 1;
    }
    return labels.get(componentId);
  }

  function encode(indices) {
    return indices.map((index) => labelFor(componentIds[index])).join('');
  }

  const top = [];
  const right = [];
  const bottom = [];
  const left = [];

  for (let col = 0; col < MAP_WIDTH; col += 1) {
    top.push(toIndex(col, 0, MAP_WIDTH));
    bottom.push(toIndex(col, MAP_HEIGHT - 1, MAP_WIDTH));
  }
  for (let row = 0; row < MAP_HEIGHT; row += 1) {
    right.push(toIndex(MAP_WIDTH - 1, row, MAP_WIDTH));
    left.push(toIndex(0, row, MAP_WIDTH));
  }

  return [encode(top), encode(right), encode(bottom), encode(left)].join('|');
}

function loadOverworldSectors() {
  return fs.readdirSync(OVERWORLD_DIR)
    .filter((file) => /^sector_\d+_\d+\.bin$/.test(file))
    .sort((a, b) => a.localeCompare(b, 'en', { numeric: true }))
    .map((file) => {
      const match = file.match(/^sector_(\d+)_(\d+)\.bin$/);
      const x = parseInt(match[1], 10);
      const y = parseInt(match[2], 10);
      const filePath = path.join(OVERWORLD_DIR, file);
      const tiles = decompressRLE(fs.readFileSync(filePath));
      const specials = getSpecials(tiles);
      return {
        id: `${x},${y}`,
        file,
        filePath,
        slotX: x,
        slotY: y,
        tiles,
        specials,
        hasSpecials: specials.length > 0,
        signature: encodeBoundarySignature(tiles),
      };
    });
}

module.exports = {
  MAP_HEIGHT,
  MAP_WIDTH,
  OVERWORLD_DIR,
  PROJECT_ROOT,
  TOWN_NAMES,
  TOOLS_DATA_DIR,
  WORLD_SECTOR_COLS,
  WORLD_SECTOR_ROWS,
  WORLD_TILE_HEIGHT,
  WORLD_TILE_WIDTH,
  cloneTiles,
  compressRLE,
  describeSpecial,
  getSpecials,
  isWalkableTile,
  loadOverworldSectors,
};
