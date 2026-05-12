'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  buildFullRandomizedWorld,
  buildRandomizedInteractionLists,
  buildPlacements,
  buildTownTables,
  validatePlacements,
} = require('../randomizer/full_overworld');
const { buildVanillaPlacements } = require('../randomizer/map_graph');
const { isWalkableTile } = require('../randomizer/map_utils');
const { createWorkspace } = require('../hack_workdir');

const TOWN_TEMPLATE_RADIUS_X = 3;
const TOWN_TEMPLATE_RADIUS_Y_TOP = 3;
const TOWN_TEMPLATE_RADIUS_Y_BOTTOM = 4;

function buildTownTemplateMap() {
  const templates = new Map();
  for (const placement of buildVanillaPlacements()) {
    for (const special of placement.sector.specials) {
      if (special.kind !== 'town' || templates.has(special.id)) continue;
      const entries = [];
      for (let dy = -TOWN_TEMPLATE_RADIUS_Y_TOP; dy <= TOWN_TEMPLATE_RADIUS_Y_BOTTOM; dy += 1) {
        for (let dx = -TOWN_TEMPLATE_RADIUS_X; dx <= TOWN_TEMPLATE_RADIUS_X; dx += 1) {
          if (dx === 0 && dy === 0) continue;
          const x = special.col + dx;
          const y = special.row + dy;
          if (x < 0 || x >= 16 || y < 0 || y >= 16) continue;
          const tile = placement.sector.tiles[y * 16 + x];
          if ((tile >= 0x10 && tile < 0x20) || (tile >= 0x80 && tile < 0x90) || tile === 0xFF) continue;
          entries.push({ dx, dy, tile });
        }
      }
      templates.set(special.id, entries);
    }
  }
  return templates;
}

const STOCK_TOWN_TEMPLATES = buildTownTemplateMap();

function buildVanillaCaveCoordinateMap() {
  const coords = new Map();
  for (const placement of buildVanillaPlacements()) {
    for (const special of placement.sector.specials) {
      if (special.kind !== 'cave') continue;
      coords.set(special.id, { col: special.col, row: special.row });
    }
  }
  return coords;
}

const STOCK_CAVE_COORDINATES = buildVanillaCaveCoordinateMap();

function adjacentWalkableDirections(tiles, col, row) {
  const dirs = [
    { name: 'up', x: col, y: row - 1 },
    { name: 'down', x: col, y: row + 1 },
    { name: 'left', x: col - 1, y: row },
    { name: 'right', x: col + 1, y: row },
  ];
  return dirs
    .filter((dir) => dir.x >= 0 && dir.x < 16 && dir.y >= 0 && dir.y < 16)
    .filter((dir) => isWalkableTile(tiles[dir.y * 16 + dir.x]))
    .map((dir) => dir.name);
}

function buildStockApproachDirectionMap() {
  const approaches = new Map();
  for (const placement of buildVanillaPlacements()) {
    for (const special of placement.sector.specials) {
      if (special.kind !== 'town' && special.kind !== 'cave') continue;
      approaches.set(special.key, adjacentWalkableDirections(placement.sector.tiles, special.col, special.row));
    }
  }
  return approaches;
}

const STOCK_APPROACH_DIRECTIONS = buildStockApproachDirectionMap();

test('full overworld generator uses only overworld-safe terrain tiles', () => {
  const placements = buildPlacements(3296380455);
  const allowedTerrain = new Set([0x00, 0x01, 0x02, 0x0F]);

  for (const placement of placements) {
    for (const tile of placement.sector.tiles) {
      const special = (tile >= 0x10 && tile < 0x20) || (tile >= 0x80 && tile < 0x90) || tile === 0xFF;
      assert.equal(allowedTerrain.has(tile) || special, true, `unexpected tile ${tile.toString(16)} in sector ${placement.slotX},${placement.slotY}`);
    }
  }
});

test('full overworld generator still produces generated sectors', () => {
  const placements = buildPlacements(3296380455);
  assert.ok(placements.length > 0);
  assert.ok(placements.every((placement) => placement.sector.generated));
});

test('full overworld generator passes internal progression reachability check for fixed seed', () => {
  const placements = buildPlacements(3296380455);
  assert.equal(validatePlacements(placements), true);
});

test('full overworld town tables map each town to its generated overworld entrance', () => {
  const placements = buildPlacements(3296380455);
  const tables = buildTownTables(placements);

  for (const placement of placements) {
    for (const special of placement.sector.specials) {
      if (special.kind !== 'town') continue;
      const entry = tables.teleport[special.id];
      assert.equal(entry.id, special.id);
      assert.equal(entry.slotX, placement.slotX);
      assert.equal(entry.slotY, placement.slotY);
    }
  }
});

test('full overworld town exit coordinates place player adjacent to town tile', () => {
  const placements = buildPlacements(3296380455);
  const tables = buildTownTables(placements);

  for (const placement of placements) {
    for (const special of placement.sector.specials) {
      if (special.kind !== 'town') continue;
      const entry = tables.teleport[special.id];
      const dx = Math.abs(entry.x - special.col);
      const dy = Math.abs(entry.y - special.row);
      assert.equal(dx, 0, `town ${special.id} exit should stay in same column as town tile`);
      assert.equal(dy, 1, `town ${special.id} exit should be exactly one tile south of town tile`);
      assert.equal(entry.y > special.row, true, `town ${special.id} exit should be south of town tile`);
      const tile = placement.sector.tiles[entry.y * 16 + entry.x];
      const isSpecial = (tile >= 0x10 && tile < 0x20) || (tile >= 0x80 && tile < 0x90) || tile === 0xFF;
      assert.equal(isSpecial, false, `town ${special.id} exit lands on special tile`);
    }
  }
});

test('full overworld towns preserve stock-derived local town templates', () => {
  const placements = buildPlacements(3296380455);
  for (const placement of placements) {
    for (const special of placement.sector.specials) {
      if (special.kind !== 'town') continue;
      const template = STOCK_TOWN_TEMPLATES.get(special.id);
      assert.ok(template, `missing stock template for town ${special.id}`);
      for (const entry of template) {
        const tx = special.col + entry.dx;
        const ty = special.row + entry.dy;
        if (tx < 0 || tx >= 16 || ty < 0 || ty >= 16) continue;
        const tile = placement.sector.tiles[ty * 16 + tx];
        assert.equal(tile, entry.tile,
          `town ${special.id} at (${special.col},${special.row}): expected tile $${entry.tile.toString(16).toUpperCase()} at (${tx},${ty}), got $${tile.toString(16).toUpperCase()}`);
      }
    }
  }
});

test('full overworld towns and caves keep a single stock-matching approach direction', () => {
  const placements = buildPlacements(3296380455);
  for (const placement of placements) {
    for (const special of placement.sector.specials) {
      if (special.kind !== 'town' && special.kind !== 'cave') continue;
      const expected = STOCK_APPROACH_DIRECTIONS.get(special.key);
      assert.ok(expected, `missing stock approach data for ${special.key}`);
      const actual = adjacentWalkableDirections(placement.sector.tiles, special.col, special.row);
      assert.equal(actual.length, 1, `${special.key} should have exactly one walkable adjacent approach tile, got ${actual.join(',') || 'none'}`);
      assert.deepEqual(actual, expected, `${special.key} should match stock approach direction`);
    }
  }
});

test('full overworld caves keep vanilla local coordinates required by cave room exits', () => {
  const placements = buildPlacements(3296380455);
  for (const placement of placements) {
    for (const special of placement.sector.specials) {
      if (special.kind !== 'cave') continue;
      const expected = STOCK_CAVE_COORDINATES.get(special.id);
      assert.ok(expected, `missing stock cave coordinates for cave ${special.id}`);
      assert.equal(special.col, expected.col, `cave ${special.id} must keep vanilla local x coordinate`);
      assert.equal(special.row, expected.row, `cave ${special.id} must keep vanilla local y coordinate`);
    }
  }
});

test('generated sectors place important overworld interactions on dead ends when enough dead ends exist', () => {
  const workspace = createWorkspace('test-deadend-interactions');
  const world = buildFullRandomizedWorld(workspace, 3296380455);
  const lists = buildRandomizedInteractionLists(world.placements, world.interactionMap);

  function reservedTiles(placement) {
    const reserved = new Set();
    for (const special of placement.sector.specials) {
      reserved.add(`${special.col},${special.row}`);
      const dirs = [
        { x: special.col, y: special.row - 1 },
        { x: special.col, y: special.row + 1 },
        { x: special.col - 1, y: special.row },
        { x: special.col + 1, y: special.row },
      ];
      for (const dir of dirs) reserved.add(`${dir.x},${dir.y}`);
    }
    return reserved;
  }

  function degree(tiles, x, y) {
    const dirs = [
      { x, y: y - 1 },
      { x, y: y + 1 },
      { x: x - 1, y },
      { x: x + 1, y },
    ];
    return dirs
      .filter((dir) => dir.x >= 0 && dir.x < 16 && dir.y >= 0 && dir.y < 16)
      .filter((dir) => isWalkableTile(tiles[dir.y * 16 + dir.x]))
      .length;
  }

  function important(entry) {
    return entry.handler.startsWith('OverworldChest_')
      || entry.handler.startsWith('OverworldNpc_')
      || entry.handler === 'SetupNoOneTalker';
  }

  for (const placement of world.placements) {
    if (!placement.sector.generated) continue;
    const entries = (lists[placement.slotX] || []).filter((entry) => entry.sectorY === placement.slotY && important(entry));
    if (!entries.length) continue;

    const reserved = reservedTiles(placement);
    let availableDeadEnds = 0;
    for (let y = 1; y < 15; y += 1) {
      for (let x = 1; x < 15; x += 1) {
        if (reserved.has(`${x},${y}`)) continue;
        if (!isWalkableTile(placement.sector.tiles[y * 16 + x])) continue;
        if (degree(placement.sector.tiles, x, y) === 1) availableDeadEnds += 1;
      }
    }

    if (availableDeadEnds < entries.length) continue;

    for (const entry of entries) {
      assert.equal(
        degree(placement.sector.tiles, entry.x, entry.y),
        1,
        `${entry.handler} in generated sector ${placement.slotX},${placement.slotY} should be on a dead end`
      );
    }
  }
});
