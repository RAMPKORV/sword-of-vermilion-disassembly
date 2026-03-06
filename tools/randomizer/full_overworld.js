'use strict';

const fs = require('fs');
const path = require('path');

const {
  MAP_HEIGHT,
  MAP_WIDTH,
  compressRLE,
  getSpecials,
  isWalkableTile,
  loadOverworldSectors,
} = require('./map_utils');
const { buildWorld } = require('./map_graph');
const { floodFill, shortestPath, toIndex } = require('./pathfinder');

const POINTER_TABLE_START = 'OverworldMaps: ; 128';
const POINTER_TABLE_END = ';==============================================================\n; OVERWORLD SECTOR DATA';
const INTERACTION_START = 'OverworldSectorInteractionPtrs:';
const INTERACTION_END = 'OverworldChest_CrimsonArmor:';

const MAGIC_TOWN_ORDER = [0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 15];
const REQUIRED_KEYS = [
  'town:0', 'town:1', 'cave:0', 'town:2', 'cave:1', 'cave:3',
  'town:7', 'town:6', 'cave:5', 'cave:9', 'town:8', 'town:9',
  'town:10', 'town:11', 'town:12', 'town:13', 'cave:11', 'cave:15',
];

const TILE_PLAIN = 0x00;
const TILE_FOREST = 0x01;
const TILE_MOUNTAIN = 0x02;
const TILE_ROAD = 0x00;
const TILE_HOUSE = 0x0F;
const TILE_DECOR = [0x01, 0x02];
const TOWN_TEMPLATE_RADIUS_X = 3;
const TOWN_TEMPLATE_RADIUS_Y_TOP = 3;
const TOWN_TEMPLATE_RADIUS_Y_BOTTOM = 4;

// Stock town layout: 2x4 block of house ($0F) tiles above the entrance,
// terrain flanking the entrance row, ground path extending south.
// The entrance tile ($8x) is placed at (0,0) by stampTownFootprint.
const TOWN_FOOTPRINT = [
  // Row -2: houses (col -1 to +2)
  { dx: -1, dy: -2, tile: TILE_HOUSE },
  { dx:  0, dy: -2, tile: TILE_HOUSE },
  { dx:  1, dy: -2, tile: TILE_HOUSE },
  { dx:  2, dy: -2, tile: TILE_HOUSE },
  // Row -1: houses (col -1 to +2)
  { dx: -1, dy: -1, tile: TILE_HOUSE },
  { dx:  0, dy: -1, tile: TILE_HOUSE },
  { dx:  1, dy: -1, tile: TILE_HOUSE },
  { dx:  2, dy: -1, tile: TILE_HOUSE },
  // Row 0: terrain flanking the entrance
  { dx: -1, dy:  0, tile: TILE_FOREST },
  { dx:  1, dy:  0, tile: TILE_FOREST },
  // Row +1: ground exit tile (where player spawns after leaving town)
  { dx:  0, dy:  1, tile: TILE_PLAIN },
  // Row +2: ground path continuing south
  { dx:  0, dy:  2, tile: TILE_PLAIN },
];

function buildTownTemplateMap() {
  const templates = new Map();
  for (const sector of loadOverworldSectors()) {
    for (const special of sector.specials) {
      if (special.kind !== 'town' || templates.has(special.id)) continue;
      const entries = [];
      for (let dy = -TOWN_TEMPLATE_RADIUS_Y_TOP; dy <= TOWN_TEMPLATE_RADIUS_Y_BOTTOM; dy += 1) {
        for (let dx = -TOWN_TEMPLATE_RADIUS_X; dx <= TOWN_TEMPLATE_RADIUS_X; dx += 1) {
          if (dx === 0 && dy === 0) continue;
          const x = special.col + dx;
          const y = special.row + dy;
          if (x < 0 || x >= MAP_WIDTH || y < 0 || y >= MAP_HEIGHT) continue;
          const tile = sector.tiles[y * MAP_WIDTH + x];
          if ((tile >= 0x10 && tile < 0x20) || (tile >= 0x80 && tile < 0x90) || tile === 0xFF) continue;
          entries.push({ dx, dy, tile });
        }
      }
      templates.set(special.id, entries);
    }
  }
  return templates;
}

const TOWN_TEMPLATE_BY_ID = buildTownTemplateMap();

function makePrng(seed) {
  let state = (seed >>> 0) || 1;
  return {
    next() {
      state ^= state << 13;
      state ^= state >>> 17;
      state ^= state << 5;
      state >>>= 0;
      return state;
    },
    int(min, max) {
      return min + (this.next() % (max - min + 1));
    },
    pick(array) {
      return array[this.int(0, array.length - 1)];
    },
  };
}

function hexWord(value) {
  return `$${(value & 0xFFFF).toString(16).toUpperCase().padStart(4, '0')}`;
}

function parseWord(text) {
  const trimmed = text.trim();
  if (trimmed.startsWith('$')) return parseInt(trimmed.slice(1), 16);
  return parseInt(trimmed, 10);
}

function sectionBetween(text, startMarker, endMarker) {
  const start = text.indexOf(startMarker);
  if (start < 0) throw new Error(`marker not found: ${startMarker}`);
  const end = text.indexOf(endMarker, start);
  if (end < 0) throw new Error(`marker not found: ${endMarker}`);
  return { start, end };
}

function replaceSection(text, startMarker, endMarker, replacement) {
  const { start, end } = sectionBetween(text, startMarker, endMarker);
  return text.slice(0, start) + replacement + text.slice(end);
}

function parseOverworldInteractions(workspace) {
  const towndataPath = path.join(workspace, 'src', 'towndata.asm');
  const text = fs.readFileSync(towndataPath, 'utf8');
  const { start, end } = sectionBetween(text, INTERACTION_START, INTERACTION_END);
  const lines = text.slice(start, end).split(/\r?\n/);
  const bySlot = new Map();
  let sectorX = -1;
  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i].trim();
    const labelMatch = line.match(/^OverworldInteractions_Sector(\d+):$/);
    if (labelMatch) {
      sectorX = parseInt(labelMatch[1], 10);
      continue;
    }
    if (!line.startsWith('dc.w')) continue;
    if (line.includes('$FFFF')) continue;
    const words = line.replace(/^dc\.w\s+/i, '').split(',').map((part) => parseWord(part));
    if (words.length < 4 || i + 1 >= lines.length) continue;
    const handlerLine = lines[i + 1].trim();
    const handlerMatch = handlerLine.match(/^dc\.l\s+([A-Za-z0-9_\-]+)$/i);
    if (!handlerMatch) continue;
    const key = `${sectorX},${words[0]}`;
    if (!bySlot.has(key)) bySlot.set(key, []);
    bySlot.get(key).push({
      sourceSectorX: sectorX,
      sourceSectorY: words[0],
      x: words[1],
      y: words[2],
      direction: words[3],
      handler: handlerMatch[1],
    });
  }
  return bySlot;
}

function buildEmptySector(fill = TILE_PLAIN) {
  const tiles = new Uint8Array(MAP_WIDTH * MAP_HEIGHT);
  tiles.fill(fill);
  return tiles;
}

function carveLine(tiles, x0, y0, x1, y1, tile = TILE_ROAD) {
  let x = x0;
  let y = y0;
  while (x !== x1 || y !== y1) {
    tiles[y * MAP_WIDTH + x] = tile;
    if (x !== x1) x += Math.sign(x1 - x);
    else if (y !== y1) y += Math.sign(y1 - y);
  }
  tiles[y * MAP_WIDTH + x] = tile;
}

function decorateTerrain(tiles, rng) {
  for (let y = 1; y < MAP_HEIGHT - 1; y += 1) {
    for (let x = 1; x < MAP_WIDTH - 1; x += 1) {
      const index = y * MAP_WIDTH + x;
      if (tiles[index] === TILE_ROAD) continue;
      const roll = rng.int(0, 99);
      if (roll < 48) tiles[index] = TILE_FOREST;
      else if (roll < 92) tiles[index] = TILE_MOUNTAIN;
      else tiles[index] = TILE_PLAIN;
    }
  }
}

function openBoundaries(tiles, rng, edges) {
  const center = { x: rng.int(5, 10), y: rng.int(5, 10) };
  if (edges.north) carveLine(tiles, 8, 0, center.x, center.y);
  if (edges.south) carveLine(tiles, 8, MAP_HEIGHT - 1, center.x, center.y);
  if (edges.west) carveLine(tiles, 0, 8, center.x, center.y);
  if (edges.east) carveLine(tiles, MAP_WIDTH - 1, 8, center.x, center.y);
  return center;
}

function reconnectSectorEdges(tiles, center, edges) {
  if (edges.north) carveLine(tiles, 8, 0, center.x, center.y);
  if (edges.south) carveLine(tiles, 8, MAP_HEIGHT - 1, center.x, center.y);
  if (edges.west) carveLine(tiles, 0, 8, center.x, center.y);
  if (edges.east) carveLine(tiles, MAP_WIDTH - 1, 8, center.x, center.y);
}

function reconnectSectorEdgesAroundTown(tiles, connectors, edges, protectedTiles) {
  const anchors = [];
  if (edges.north) anchors.push({ x: 8, y: 0 });
  if (edges.south) anchors.push({ x: 8, y: MAP_HEIGHT - 1 });
  if (edges.west) anchors.push({ x: 0, y: 8 });
  if (edges.east) anchors.push({ x: MAP_WIDTH - 1, y: 8 });

  for (const anchor of anchors) {
    const startIndex = toIndex(anchor.x, anchor.y, MAP_WIDTH);
    let bestPath = null;
    for (const connector of connectors) {
      const goalIndex = toIndex(connector.x, connector.y, MAP_WIDTH);
      const path = shortestPath({
        width: MAP_WIDTH,
        height: MAP_HEIGHT,
        startIndex,
        goalIndex,
        canVisit(index) {
          const x = index % MAP_WIDTH;
          const y = Math.floor(index / MAP_WIDTH);
          if (x === connector.x && y === connector.y) return true;
          return !protectedTiles || !protectedTiles.has(`${x},${y}`);
        },
      });
      if (!path) continue;
      if (!bestPath || path.length < bestPath.length) bestPath = path;
    }
    if (!bestPath) continue;
    for (const index of bestPath) {
      const x = index % MAP_WIDTH;
      const y = Math.floor(index / MAP_WIDTH);
      const isConnector = connectors.some((entry) => entry.x === x && entry.y === y);
      if (protectedTiles && protectedTiles.has(`${x},${y}`) && !isConnector) continue;
      tiles[index] = TILE_ROAD;
    }
  }
}

function placeSpecial(tiles, center, specialTile) {
  tiles[center.y * MAP_WIDTH + center.x] = specialTile;
}

function stampTownFootprint(tiles, center, specialTile) {
  for (const entry of TOWN_FOOTPRINT) {
    const x = center.x + entry.dx;
    const y = center.y + entry.dy;
    if (x < 0 || x >= MAP_WIDTH || y < 0 || y >= MAP_HEIGHT) continue;
    tiles[y * MAP_WIDTH + x] = entry.tile;
  }
  tiles[center.y * MAP_WIDTH + center.x] = specialTile;
}

function stampTownTemplate(tiles, center, specialTile) {
  const townId = specialTile & 0x0F;
  const template = TOWN_TEMPLATE_BY_ID.get(townId);
  if (!template) {
    stampTownFootprint(tiles, center, specialTile);
    return {
      protectedTiles: new Set(TOWN_FOOTPRINT.map((entry) => `${center.x + entry.dx},${center.y + entry.dy}`)),
      connectors: [{ x: center.x, y: Math.min(center.y + 1, MAP_HEIGHT - 1) }],
    };
  }

  const protectedTiles = new Set();
  const walkableCandidates = [];
  for (const entry of template) {
    const x = center.x + entry.dx;
    const y = center.y + entry.dy;
    if (x < 0 || x >= MAP_WIDTH || y < 0 || y >= MAP_HEIGHT) continue;
    tiles[y * MAP_WIDTH + x] = entry.tile;
    protectedTiles.add(`${x},${y}`);
    if (entry.dy >= 1 && isWalkableTile(entry.tile)) {
      walkableCandidates.push({ x, y, dx: entry.dx, dy: entry.dy });
    }
  }
  tiles[center.y * MAP_WIDTH + center.x] = specialTile;
  protectedTiles.add(`${center.x},${center.y}`);
  walkableCandidates.sort((a, b) => {
    if (a.dy !== b.dy) return a.dy - b.dy;
    return Math.abs(a.dx) - Math.abs(b.dx);
  });
  const connectors = walkableCandidates.length > 0
    ? walkableCandidates.map((entry) => ({ x: entry.x, y: entry.y }))
    : [{ x: center.x, y: Math.min(center.y + 1, MAP_HEIGHT - 1) }];
  return {
    protectedTiles,
    connectors,
  };
}

function carveNarrowRoad(tiles, start, end, rng) {
  let x = start.x;
  let y = start.y;
  while (x !== end.x || y !== end.y) {
    tiles[y * MAP_WIDTH + x] = TILE_ROAD;
    if (x !== end.x && y !== end.y) {
      if (rng.int(0, 99) < 65) x += Math.sign(end.x - x);
      else y += Math.sign(end.y - y);
    } else if (x !== end.x) {
      x += Math.sign(end.x - x);
    } else if (y !== end.y) {
      y += Math.sign(end.y - y);
    }
  }
  tiles[y * MAP_WIDTH + x] = TILE_ROAD;
}

function widenRoadCorners(tiles) {
  for (let y = 1; y < MAP_HEIGHT - 1; y += 1) {
    for (let x = 1; x < MAP_WIDTH - 1; x += 1) {
      const index = y * MAP_WIDTH + x;
      if (tiles[index] !== TILE_ROAD) continue;
      const north = tiles[(y - 1) * MAP_WIDTH + x] === TILE_ROAD;
      const south = tiles[(y + 1) * MAP_WIDTH + x] === TILE_ROAD;
      const west = tiles[y * MAP_WIDTH + (x - 1)] === TILE_ROAD;
      const east = tiles[y * MAP_WIDTH + (x + 1)] === TILE_ROAD;
      if ((north || south) && (east || west)) {
        if (!north && y > 1) tiles[(y - 1) * MAP_WIDTH + x] = TILE_PLAIN;
        if (!south && y < MAP_HEIGHT - 2) tiles[(y + 1) * MAP_WIDTH + x] = TILE_PLAIN;
      }
    }
  }
}

function addBoundaryPressure(tiles, edges) {
  for (let x = 0; x < MAP_WIDTH; x += 1) {
    if (!edges.north && tiles[x] !== TILE_ROAD) tiles[x] = TILE_MOUNTAIN;
    if (!edges.south && tiles[(MAP_HEIGHT - 1) * MAP_WIDTH + x] !== TILE_ROAD) tiles[(MAP_HEIGHT - 1) * MAP_WIDTH + x] = TILE_MOUNTAIN;
  }
  for (let y = 0; y < MAP_HEIGHT; y += 1) {
    if (!edges.west && tiles[y * MAP_WIDTH] !== TILE_ROAD) tiles[y * MAP_WIDTH] = TILE_MOUNTAIN;
    if (!edges.east && tiles[y * MAP_WIDTH + (MAP_WIDTH - 1)] !== TILE_ROAD) tiles[y * MAP_WIDTH + (MAP_WIDTH - 1)] = TILE_MOUNTAIN;
  }
}

function restoreBoundaryAnchors(tiles, edges) {
  if (edges.north) tiles[8] = TILE_ROAD;
  if (edges.south) tiles[(MAP_HEIGHT - 1) * MAP_WIDTH + 8] = TILE_ROAD;
  if (edges.west) tiles[8 * MAP_WIDTH] = TILE_ROAD;
  if (edges.east) tiles[8 * MAP_WIDTH + (MAP_WIDTH - 1)] = TILE_ROAD;
}

function generateSector(seed, slotX, slotY, specialTile, edges) {
  const rng = makePrng(seed ^ ((slotX + 1) << 8) ^ ((slotY + 1) << 16));
  const tiles = buildEmptySector(TILE_FOREST);
  const center = openBoundaries(tiles, rng, edges);
  const branchTargets = [];

  const branches = rng.int(1, 2);
  for (let i = 0; i < branches; i += 1) {
    const target = { x: rng.int(2, 13), y: rng.int(2, 13) };
    branchTargets.push(target);
    carveNarrowRoad(tiles, center, target, rng);
  }

  for (let i = 0; i < 10; i += 1) {
    const cx = rng.int(1, 14);
    const cy = rng.int(1, 14);
    if (tiles[cy * MAP_WIDTH + cx] === TILE_ROAD) continue;
    tiles[cy * MAP_WIDTH + cx] = rng.pick(TILE_DECOR);
  }

  decorateTerrain(tiles, rng);
  if (specialTile !== null && !(specialTile >= 0x80 && specialTile < 0x90)) {
    placeSpecial(tiles, center, specialTile);
    // For non-town specials, ensure walkable surroundings
    if (center.y > 0) tiles[(center.y - 1) * MAP_WIDTH + center.x] = TILE_ROAD;
    if (center.y + 1 < MAP_HEIGHT) tiles[(center.y + 1) * MAP_WIDTH + center.x] = TILE_PLAIN;
    if (center.x > 0) tiles[center.y * MAP_WIDTH + (center.x - 1)] = TILE_FOREST;
    if (center.x + 1 < MAP_WIDTH) tiles[center.y * MAP_WIDTH + (center.x + 1)] = TILE_FOREST;
  }
  widenRoadCorners(tiles);
  addBoundaryPressure(tiles, edges);
  restoreBoundaryAnchors(tiles, edges);
  let protectedTownTiles = null;
  // For towns: stamp the house footprint, then RE-carve edge roads to a
  // hub south of the house block so connectivity isn't broken by the
  // impassable $0F tiles.  The hub is 2 rows below the entrance, safely
  // clear of the house block (which occupies rows center.y-2 to center.y-1).
  if (specialTile !== null && specialTile >= 0x80 && specialTile < 0x90) {
    const townTemplate = stampTownTemplate(tiles, center, specialTile);
    protectedTownTiles = townTemplate.protectedTiles;
    reconnectSectorEdgesAroundTown(tiles, townTemplate.connectors, edges, protectedTownTiles);
  }
  tiles[center.y * MAP_WIDTH + center.x] = specialTile !== null ? specialTile : TILE_ROAD;
  const isTownSector = specialTile !== null && specialTile >= 0x80 && specialTile < 0x90;
  for (const target of branchTargets) {
    if (isTownSector && protectedTownTiles && protectedTownTiles.has(`${target.x},${target.y}`)) continue;
    tiles[target.y * MAP_WIDTH + target.x] = TILE_ROAD;
  }
  return {
    tiles,
    specials: getSpecials(tiles),
    generated: true,
    rawBuffer: compressRLE(tiles),
    compressedSize: compressRLE(tiles).length,
  };
}

function backbonePath() {
  return [
    [0, 6], [1, 6], [1, 5], [1, 4], [2, 4], [3, 4], [4, 4], [5, 4],
    [6, 4], [6, 5], [7, 5], [8, 5], [9, 5], [10, 5], [11, 5], [12, 5],
    [12, 4], [12, 3], [12, 2], [13, 2], [14, 2], [14, 1], [14, 0],
    [13, 0], [12, 0], [11, 0], [10, 0], [9, 0], [9, 1], [9, 2],
    [8, 2], [7, 2], [6, 2], [5, 2],
  ];
}

function expandConnectedBackbone() {
  const connected = backbonePath().map(([x, y]) => ({ x, y }));
  const connectedSet = new Set(connected.map(({ x, y }) => `${x},${y}`));
  const specials = [...assignSpecials().keys()].map((key) => {
    const [x, y] = key.split(',').map(Number);
    return { x, y };
  });

  function addPoint(x, y) {
    const key = `${x},${y}`;
    if (connectedSet.has(key)) return;
    connected.push({ x, y });
    connectedSet.add(key);
  }

  function nearestConnected(target) {
    let best = connected[0];
    let bestDist = Infinity;
    for (const point of connected) {
      const dist = Math.abs(point.x - target.x) + Math.abs(point.y - target.y);
      if (dist < bestDist) {
        best = point;
        bestDist = dist;
      }
    }
    return best;
  }

  for (const target of specials) {
    if (connectedSet.has(`${target.x},${target.y}`)) continue;
    const anchor = nearestConnected(target);
    let x = anchor.x;
    let y = anchor.y;
    while (x !== target.x || y !== target.y) {
      if (x !== target.x) x += Math.sign(target.x - x);
      else if (y !== target.y) y += Math.sign(target.y - y);
      addPoint(x, y);
    }
  }

  return connected;
}

function edgePlan(backboneSet, x, y) {
  const has = (nx, ny) => backboneSet.has(`${nx},${ny}`);
  return {
    north: y > 0 && has(x, y - 1),
    south: y < 7 && has(x, y + 1),
    west: x > 0 && has(x - 1, y),
    east: x < 15 && has(x + 1, y),
  };
}

function assignSpecials() {
  return new Map([
    ['0,6', 0x80], ['1,4', 0x81], ['0,7', 0x10], ['6,5', 0x82], ['3,4', 0x11], ['6,3', 0x13],
    ['12,2', 0x87], ['14,4', 0x86], ['2,6', 0x15], ['12,5', 0x19], ['14,0', 0x88], ['9,1', 0x89],
    ['10,0', 0x8A], ['1,0', 0x8B], ['5,2', 0x8C], ['9,2', 0x8D], ['12,4', 0x1B], ['14,1', 0x1F],
    ['4,6', 0x83], ['11,6', 0x84], ['15,0', 0x1D], ['10,3', 0x8F],
  ]);
}

function buildPlacements(seed) {
  const backbone = expandConnectedBackbone();
  const specials = assignSpecials();
  const specialKeys = [...specials.keys()];
  const backboneSet = new Set([...backbone.map(({ x, y }) => `${x},${y}`), ...specialKeys]);
  const placements = [];

  for (let y = 0; y < 8; y += 1) {
    for (let x = 0; x < 16; x += 1) {
      const key = `${x},${y}`;
      if (!backboneSet.has(key) && !specials.has(key)) continue;
      const sector = generateSector(seed, x, y, specials.has(key) ? specials.get(key) : null, edgePlan(backboneSet, x, y));
      if (specials.has(key)) {
        const special = sector.specials[0];
        if (special) {
          const isTown = special.kind === 'town';
          const exits = isTown
            ? [
                // For towns, only ensure the immediate exit tile south of the entrance.
                // The wider local footprint is stamped from stock-derived templates.
                [special.col, special.row + 1],
              ]
            : [
                [special.col + 1, special.row],
                [special.col - 1, special.row],
                [special.col, special.row + 1],
                [special.col, special.row - 1],
              ];
          for (const [ex, ey] of exits) {
            if (ex >= 0 && ex < MAP_WIDTH && ey >= 0 && ey < MAP_HEIGHT) {
              sector.tiles[ey * MAP_WIDTH + ex] = TILE_ROAD;
            }
          }
          sector.rawBuffer = compressRLE(sector.tiles);
          sector.compressedSize = sector.rawBuffer.length;
          sector.specials = getSpecials(sector.tiles);
        }
      }
      placements.push({
        slotX: x,
        slotY: y,
        sourceX: x,
        sourceY: y,
        fixed: specials.has(key),
        sector,
      });
    }
  }

  return placements;
}

function validatePlacements(placements) {
  const { worldTiles, specialNodes } = buildWorld(placements);
  const start = specialNodes.find((node) => node.key === 'town:0');
  if (!start) return false;
  const width = 16 * MAP_WIDTH;
  const fill = floodFill({
    width,
    height: 8 * MAP_HEIGHT,
    startIndices: [toIndex(start.worldX, start.worldY, width)],
    canVisit(index) {
      return isWalkableTile(worldTiles[index]);
    },
  });
  const missing = [];
  for (const key of REQUIRED_KEYS) {
    const node = specialNodes.find((entry) => entry.key === key);
    if (!node || !fill.visited[toIndex(node.worldX, node.worldY, width)]) missing.push(key);
  }
  return missing.length === 0 ? true : missing;
}

function preserveConnectivity(seed, placements) {
  return buildPlacements(seed);
}

function buildFullRandomizedWorld(workspace, seed) {
  const placements = buildPlacements(seed);
  const validation = validatePlacements(placements);
  if (validation !== true) {
    throw new Error(`Generated overworld backbone failed validation: ${Array.isArray(validation) ? validation.join(', ') : String(validation)}`);
  }
  const interactionMap = parseOverworldInteractions(workspace);
  return { placements, interactionMap };
}

function buildTownTables(placements) {
  const towns = placements.flatMap((placement) => placement.sector.specials
    .filter((special) => special.kind === 'town')
    .map((special) => {
      const candidates = [
        { x: special.col, y: special.row + 1 },
      ].filter((point) => point.x >= 0 && point.x < MAP_WIDTH && point.y >= 0 && point.y < MAP_HEIGHT);

      const exit = candidates.find((point) => {
        const tile = placement.sector.tiles[point.y * MAP_WIDTH + point.x];
        const specialTile = (tile >= 0x10 && tile < 0x20) || (tile >= 0x80 && tile < 0x90) || tile === 0xFF;
        return !specialTile;
      }) || { x: special.col, y: special.row };

      return { id: special.id, x: exit.x, y: exit.y, slotX: placement.slotX, slotY: placement.slotY };
    }));
  towns.sort((a, b) => a.id - b.id);
  return {
    teleport: Array.from({ length: 16 }, (_, id) => towns.find((town) => town.id === id) || { x: 0, y: 0, slotX: 0, slotY: 0 }),
    magic: MAGIC_TOWN_ORDER.map((id) => towns.find((town) => town.id === id) || { x: 0, y: 0, slotX: 0, slotY: 0 }),
  };
}

function buildRandomizedInteractionLists(placements, interactionMap) {
  const byColumn = Array.from({ length: 16 }, () => []);
  for (const placement of placements) {
    const key = `${placement.slotX},${placement.slotY}`;
    const entries = interactionMap.get(key) || [];
    for (const entry of entries) {
      byColumn[placement.slotX].push({
        sectorY: placement.slotY,
        x: entry.x,
        y: entry.y,
        direction: entry.direction,
        handler: entry.handler,
      });
    }
  }
  return byColumn;
}

function buildGeneratedInteractionAsm(placements, interactionMap) {
  const lists = buildRandomizedInteractionLists(placements, interactionMap);
  return [
    '; ----------------------------------------------------------------------',
    '; Workspace-only generated overworld interaction lists',
    '; ----------------------------------------------------------------------',
    ...Array.from({ length: 16 }, (_, x) => `RandomizedOverworldInteractions_Sector${x}:`),
  ].join('\n').replace(/RandomizedOverworldInteractions_Sector(\d+):/g, (match, col) => {
    const x = parseInt(col, 10);
    const lines = [`RandomizedOverworldInteractions_Sector${x}:`];
    for (const entry of lists[x]) {
      lines.push(`\tdc.w\t${hexWord(entry.sectorY)}, ${hexWord(entry.x)}, ${hexWord(entry.y)}, ${hexWord(entry.direction)}`);
      lines.push(`\tdc.l\t${entry.handler}`);
    }
    lines.push('\tdc.w\t$FFFF');
    return lines.join('\n');
  }) + '\n';
}

function patchGameplayTable(text, label, entries) {
  const start = text.indexOf(label);
  if (start < 0) throw new Error(`label not found: ${label}`);
  const end = label === 'TownTeleportLocationData:' ? text.indexOf('; TownSavedPositionData', start) : text.indexOf('; CastBattleMagicMap', start);
  if (end < 0) throw new Error(`end marker not found for ${label}`);
  const body = [
    `${label}`,
    '\t; format:',
    '\t; dc.w (x_in_sector), (y_in_sector), (sector_x), (sector_y)',
    ...entries.map((entry) => `\tdc.w\t${hexWord(entry.x)}, ${hexWord(entry.y)}, ${hexWord(entry.slotX)}, ${hexWord(entry.slotY)}`),
    '',
  ].join('\n');
  return text.slice(0, start) + body + text.slice(end);
}

function patchInitialOverworldStart(text, entry) {
  return text
    .replace(/\tMOVE\.w\t#8, Player_position_x_outside_town\.w/, `\tMOVE.w\t#${hexWord(entry.x)}, Player_position_x_outside_town.w`)
    .replace(/\tMOVE\.w\t#\$D, Player_position_y_outside_town\.w/, `\tMOVE.w\t#${hexWord(entry.y)}, Player_position_y_outside_town.w`)
    .replace(/\tMOVE\.w\t#0, Player_map_sector_x\.w/, `\tMOVE.w\t#${hexWord(entry.slotX)}, Player_map_sector_x.w`)
    .replace(/\tMOVE\.w\t#6, Player_map_sector_y\.w/, `\tMOVE.w\t#${hexWord(entry.slotY)}, Player_map_sector_y.w`);
}

function patchTowndataInteractionPtrs(text) {
  const start = text.indexOf(INTERACTION_START);
  if (start < 0) throw new Error('interaction pointer table not found');
  const labelEnd = text.indexOf('\n', start) + 1;
  const firstList = text.indexOf('OverworldInteractions_Sector0:', labelEnd);
  if (firstList < 0) throw new Error('first overworld interaction list not found');
  const pointerBlock = [
    'OverworldSectorInteractionPtrs:',
    ...Array.from({ length: 16 }, (_, x) => `\tdc.l\tRandomizedOverworldInteractions_Sector${x}`),
    '',
  ].join('\n');
  return text.slice(0, start) + pointerBlock + text.slice(firstList);
}

function patchMapdata(text, placements) {
  const placementMap = new Map(placements.map((placement) => [`${placement.slotX},${placement.slotY}`, placement]));
  const pointerLines = ['OverworldMaps: ; 128'];
  for (let y = 0; y < 8; y += 1) {
    for (let x = 0; x < 16; x += 1) {
      const key = `${x},${y}`;
      pointerLines.push(placementMap.has(key) ? `\tdc.l\tRandomizedOverworld_${x}_${y}` : '\tdc.l\tCaveMaps');
    }
  }
  return replaceSection(text, POINTER_TABLE_START, POINTER_TABLE_END, `${pointerLines.join('\n')}\n${POINTER_TABLE_END}`);
}

function buildGeneratedOverworldAsm(placements) {
  return [
    '; ======================================================================',
    '; tools/generated_overworld.asm',
    '; Workspace-only generated overworld sector data',
    '; ======================================================================',
    ...placements.flatMap((placement) => [
      `RandomizedOverworld_${placement.slotX}_${placement.slotY}:`,
      `\tincbin "data/maps/overworld/generated/slot_${placement.slotX}_${placement.slotY}.bin"`,
    ]),
    '',
  ].join('\n');
}

function patchSoundAsm(text) {
  const includeLine = '\tinclude "tools/generated_overworld.asm"';
  if (text.includes(includeLine)) return text;
  const anchor = 'EndOfRom:';
  if (!text.includes(anchor)) {
    throw new Error('could not find EndOfRom anchor in sound.asm');
  }
  return text.replace(anchor, `${includeLine}\n${anchor}`);
}

function writeGeneratedAssets(workspace, placements) {
  const dir = path.join(workspace, 'data', 'maps', 'overworld', 'generated');
  fs.mkdirSync(dir, { recursive: true });
  for (const placement of placements) {
    fs.writeFileSync(path.join(dir, `slot_${placement.slotX}_${placement.slotY}.bin`), placement.sector.rawBuffer);
  }
}

function applyFullRandomizedWorld(workspace, world) {
  const { placements, interactionMap } = world;
  writeGeneratedAssets(workspace, placements);
  const mapdataPath = path.join(workspace, 'src', 'mapdata.asm');
  const gameplayPath = path.join(workspace, 'src', 'gameplay.asm');
  const magicPath = path.join(workspace, 'src', 'magic.asm');
  const statesPath = path.join(workspace, 'src', 'states.asm');
  const soundPath = path.join(workspace, 'src', 'sound.asm');
  const towndataPath = path.join(workspace, 'src', 'towndata.asm');
  const generatedAsmPath = path.join(workspace, 'tools', 'generated_overworld.asm');
  const townTables = buildTownTables(placements);
  fs.writeFileSync(mapdataPath, patchMapdata(fs.readFileSync(mapdataPath, 'utf8'), placements), 'utf8');
  fs.writeFileSync(gameplayPath, patchGameplayTable(fs.readFileSync(gameplayPath, 'utf8'), 'TownTeleportLocationData:', townTables.teleport), 'utf8');
  fs.writeFileSync(magicPath, patchGameplayTable(fs.readFileSync(magicPath, 'utf8'), 'TownOverworldCoords:', townTables.magic), 'utf8');
  fs.writeFileSync(statesPath, patchInitialOverworldStart(fs.readFileSync(statesPath, 'utf8'), townTables.teleport[0]), 'utf8');
  fs.writeFileSync(towndataPath, patchTowndataInteractionPtrs(fs.readFileSync(towndataPath, 'utf8')), 'utf8');
  fs.writeFileSync(soundPath, patchSoundAsm(fs.readFileSync(soundPath, 'utf8')), 'utf8');
  fs.writeFileSync(generatedAsmPath, `${buildGeneratedOverworldAsm(placements)}\n${buildGeneratedInteractionAsm(placements, interactionMap)}`, 'utf8');
}

module.exports = {
  applyFullRandomizedWorld,
  buildPlacements,
  buildFullRandomizedWorld,
  buildTownTables,
  validatePlacements,
};
