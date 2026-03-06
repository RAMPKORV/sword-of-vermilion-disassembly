'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

const {
  buildPlacements,
  buildTownTables,
  validatePlacements,
} = require('../randomizer/full_overworld');
const { buildVanillaPlacements } = require('../randomizer/map_graph');

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
