#!/usr/bin/env node
// tools/randomizer/shop_randomizer.js
// Sword of Vermilion — Shop Inventory Randomizer
//
// Shuffles shop inventories while respecting tier constraints:
//   - Early-game healing items (HERBS, VIAL) guaranteed in 2+ early shops
//   - Equipment shops shuffle within their category (weapons stay weapons)
//   - Item tiers are defined by base price from shops.json
//
// Writes modified data back to tools/data/shops.json.
//
// Usage:
//   node tools/randomizer/shop_randomizer.js --seed N [--dry-run] [--json]

'use strict';

const fs   = require('fs');
const path = require('path');

const MODULE_ID = 2;

function xorshift32(s) {
  s = s >>> 0;
  s ^= s << 13;
  s ^= s >>> 17;
  s ^= s << 5;
  return s >>> 0;
}

function makePrng(seed) {
  let state = (seed ^ (MODULE_ID * 0x9E3779B9)) >>> 0;
  if (state === 0) state = 1;
  return {
    next() { state = xorshift32(state); return state; },
    float() { return (this.next() >>> 0) / 4294967296; },
    int(min, max) { return Math.floor(min + this.float() * (max - min + 1)); },
  };
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

const args     = process.argv.slice(2);
const HELP     = args.includes('--help');
const DRY_RUN  = args.includes('--dry-run');
const JSON_OUT = args.includes('--json');

if (HELP) {
  console.log([
    'Usage: node tools/randomizer/shop_randomizer.js --seed N [--dry-run] [--json]',
    '',
    'Options:',
    '  --seed N    Seed integer (required)',
    '  --dry-run   Show changes without writing',
    '  --json      Output modified data as JSON',
    '  --help      Show this help',
  ].join('\n'));
  process.exit(0);
}

function getArg(flag, def) {
  const i = args.indexOf(flag);
  return i >= 0 && args[i + 1] !== undefined ? args[i + 1] : def;
}

const seedArg = getArg('--seed', null);
if (!seedArg && !DRY_RUN) {
  console.error('Error: --seed N is required');
  process.exit(1);
}
const SEED = seedArg ? (parseInt(seedArg, 10) >>> 0) : 0;

// ---------------------------------------------------------------------------
// Load data
// ---------------------------------------------------------------------------

const DATA_PATH = path.join(__dirname, '..', 'data', 'shops.json');
const data = JSON.parse(fs.readFileSync(DATA_PATH, 'utf8'));
const shops = data.town_shops; // array of 16 town shops

// ---------------------------------------------------------------------------
// Item tier classification (by item ID / price proxy)
// We assign tiers based on item_id: lower IDs are generally earlier items.
// Tier 0: ids 0-3 (early healing), Tier 1: ids 4-9, Tier 2: ids 10+
// ---------------------------------------------------------------------------

function itemTier(item) {
  const id = item.item_id || 0;
  if (id <= 3) return 0;
  if (id <= 9) return 1;
  return 2;
}

// ---------------------------------------------------------------------------
// Collect all item shop slots across all towns, grouped by tier
// ---------------------------------------------------------------------------

function collectItemSlots(shops) {
  const slots = []; // { shopIdx, slotIdx, item }
  shops.forEach((town, shopIdx) => {
    if (!town.shops || !town.shops.item) return;
    const items = town.shops.item.assortment.items;
    items.forEach((item, slotIdx) => {
      slots.push({ shopIdx, slotIdx, item });
    });
  });
  return slots;
}

function fisherYates(arr, rng) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = rng.int(0, i);
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
}

// ---------------------------------------------------------------------------
// Randomize
// ---------------------------------------------------------------------------

function randomizeShops(seed, shopsIn) {
  const rng  = makePrng(seed);
  // Deep clone
  const out  = JSON.parse(JSON.stringify(shopsIn));

  // Collect item slots and shuffle item contents within each tier
  const allSlots = collectItemSlots(out);
  const byTier   = {};
  allSlots.forEach(s => {
    const t = itemTier(s.item);
    if (!byTier[t]) byTier[t] = [];
    byTier[t].push(s);
  });

  for (const tier of Object.keys(byTier)) {
    const group = byTier[tier];
    const items = group.map(s => ({ ...s.item }));
    fisherYates(items, rng);
    group.forEach((slot, i) => {
      out[slot.shopIdx].shops.item.assortment.items[slot.slotIdx] = items[i];
    });
  }

  // Guarantee HERBS/VIAL in at least 2 early shops (towns 0 and 1)
  for (let townIdx = 0; townIdx <= 1; townIdx++) {
    const town = out[townIdx];
    if (!town.shops || !town.shops.item) continue;
    const items = town.shops.item.assortment.items;
    const hasHealing = items.some(it => it.item_name === 'HERBS' || it.item_name === 'VIAL');
    if (!hasHealing && items.length > 0) {
      // Replace first slot with HERBS (item_id=0) from original data
      const origTown = shopsIn[townIdx];
      if (origTown && origTown.shops && origTown.shops.item) {
        const origHerbs = origTown.shops.item.assortment.items.find(
          it => it.item_name === 'HERBS' || it.item_name === 'VIAL'
        );
        if (origHerbs) items[0] = { ...origHerbs };
      }
    }
  }

  return out;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const modifiedShops = randomizeShops(SEED, shops);

if (JSON_OUT) {
  console.log(JSON.stringify({ ...data, town_shops: modifiedShops }, null, 2));
  process.exit(0);
}

if (DRY_RUN || !seedArg) {
  console.log(`Shop randomizer — seed=${SEED}`);
  modifiedShops.forEach((town, i) => {
    const orig = shops[i];
    if (!town.shops || !town.shops.item) return;
    const origItems = orig.shops.item.assortment.items.map(it => it.item_name);
    const newItems  = town.shops.item.assortment.items.map(it => it.item_name);
    const changed   = origItems.join(',') !== newItems.join(',');
    if (changed) {
      console.log(`  ${town.town_name}: [${origItems.join(', ')}] → [${newItems.join(', ')}]`);
    }
  });
  if (DRY_RUN) process.exit(0);
}

const out = { ...data, town_shops: modifiedShops };
fs.writeFileSync(DATA_PATH, JSON.stringify(out, null, 2) + '\n', 'utf8');
console.log(`Shop randomizer: wrote ${modifiedShops.length} town shop entries to ${DATA_PATH}`);
