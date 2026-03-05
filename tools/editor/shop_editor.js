#!/usr/bin/env node
// tools/editor/shop_editor.js
// Sword of Vermilion — Shop Inventory Editor
//
// Interactive CLI for viewing and editing town shop inventories and prices
// in tools/data/shops.json.  Changes are validated and written back to JSON,
// then injected into the ASM source via inject_game_data.js.
//
// Usage:
//   node tools/editor/shop_editor.js [options]
//   node tools/editor/shop_editor.js --town <name_or_id>
//
// Options:
//   --list              List all towns and their shop types, then exit
//   --town <n>          Select town by index (0-based) or name substring
//   --no-rebuild        Skip inject + verify.bat after saving
//   --dry-run           Show changes without writing any files
//   --json              Dump full shops data as JSON and exit
//   --help              Show this help

'use strict';

const fs       = require('fs');
const path     = require('path');
const readline = require('readline');
const { execSync } = require('child_process');

// ---------------------------------------------------------------------------
// Paths
// ---------------------------------------------------------------------------

const ROOT         = path.join(__dirname, '..', '..');
const SHOPS_JSON   = path.join(ROOT, 'tools', 'data', 'shops.json');
const INJECT_SCRIPT = path.join(ROOT, 'tools', 'inject_game_data.js');

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

const args       = process.argv.slice(2);
const HELP       = args.includes('--help');
const DO_LIST    = args.includes('--list');
const DO_JSON    = args.includes('--json');
const DRY_RUN    = args.includes('--dry-run');
const NO_REBUILD = args.includes('--no-rebuild');

function getArg(flag, def) {
  const i = args.indexOf(flag);
  return i >= 0 && args[i + 1] !== undefined ? args[i + 1] : def;
}

if (HELP) {
  console.log([
    'Usage: node tools/editor/shop_editor.js [options]',
    '',
    'Options:',
    '  --list          List all 16 towns with shop type summary',
    '  --town <n>      Select by 0-based index or town name substring',
    '  --no-rebuild    Skip inject_game_data.js + verify.bat',
    '  --dry-run       Show changes without writing',
    '  --json          Dump full shops JSON and exit',
    '  --help          Show this help',
    '',
    'In the editor, you can:',
    '  - Change an item slot to a different item constant',
    '  - Change a price for an item slot',
    '  - Add an item slot (up to original item_count; cannot expand tables)',
    '  - Remove an item slot (reduces item_count)',
  ].join('\n'));
  process.exit(0);
}

// ---------------------------------------------------------------------------
// Load data
// ---------------------------------------------------------------------------

if (!fs.existsSync(SHOPS_JSON)) {
  console.error(`Error: ${SHOPS_JSON} not found. Run tools/extract_game_data.js first.`);
  process.exit(1);
}

const rawData   = JSON.parse(fs.readFileSync(SHOPS_JSON, 'utf8'));
const townShops = rawData.town_shops;

if (DO_JSON) {
  console.log(JSON.stringify(rawData, null, 2));
  process.exit(0);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function pad(s, n) { return String(s).padEnd(n); }
function lpad(s, n) { return String(s).padStart(n); }

function shopTypes(town) {
  return Object.keys(town.shops).filter(k => town.shops[k] !== null).join(', ');
}

function printList() {
  console.log(`${'Idx'.padEnd(4)} ${'Town'.padEnd(14)} ${'Shop types'}`);
  console.log('─'.repeat(50));
  for (let i = 0; i < townShops.length; i++) {
    const t = townShops[i];
    console.log(`${lpad(i, 3)}  ${pad(t.town_name, 14)} ${shopTypes(t)}`);
  }
}

function printShop(shopType, shop, prices) {
  if (!shop) { console.log(`  (no ${shopType} shop)`); return; }
  console.log(`\n  [${shopType.toUpperCase()} SHOP]  — ${shop.label}`);
  console.log(`  ${'Slot'.padEnd(5)} ${'Item'.padEnd(30)} ${'Price'.padEnd(8)}`);
  console.log('  ' + '─'.repeat(50));
  const items = shop.items;
  for (let i = 0; i < items.length; i++) {
    const it    = items[i];
    const price = prices ? prices[i] : 'N/A';
    const name  = it.item_constant || it.equip_id_constant || it.item_name || '?';
    console.log(`  ${lpad(i + 1, 4)}  ${pad(name, 30)} ${lpad(price, 7)}`);
  }
}

function printTown(idx) {
  const t = townShops[idx];
  console.log(`\n[${idx}] ${t.town_name}`);
  for (const type of ['item', 'equipment', 'magic']) {
    const shopEntry = t.shops[type];
    if (!shopEntry) continue;
    const shop   = shopEntry.assortment;
    const prices = shopEntry.prices;
    printShop(type, shop, prices);
  }
}

// ---------------------------------------------------------------------------
// Find town
// ---------------------------------------------------------------------------

function findTown(query) {
  const n = parseInt(query, 10);
  if (!isNaN(n) && n >= 0 && n < townShops.length) return n;
  const q = query.toLowerCase();
  const idx = townShops.findIndex(t => t.town_name.toLowerCase().includes(q));
  return idx;
}

// ---------------------------------------------------------------------------
// Validation helpers
// ---------------------------------------------------------------------------

// Warn if no healing items (HERBS, VIAL) in the first two towns.
function warnHealingAvailability() {
  const HEALING = ['ITEM_HERBS', 'ITEM_VIAL'];
  let healingTowns = 0;
  for (let i = 0; i < Math.min(3, townShops.length); i++) {
    const t = townShops[i];
    const itemShop = t.shops.item;
    if (!itemShop) continue;
    const items = itemShop.assortment.items;
    if (items.some(it => HEALING.includes(it.item_constant))) healingTowns++;
  }
  if (healingTowns < 1) {
    console.log('  WARNING: No HERBS or VIAL found in first 3 towns (Wyclif area). Early game may be very difficult.');
  }
}

// ---------------------------------------------------------------------------
// Interactive RL helpers
// ---------------------------------------------------------------------------

function createRl() {
  return readline.createInterface({ input: process.stdin, output: process.stdout });
}
async function prompt(rl, q) {
  return new Promise(resolve => rl.question(q, resolve));
}

// ---------------------------------------------------------------------------
// Edit one shop's items interactively
// ---------------------------------------------------------------------------

async function editShop(rl, townIdx, shopType) {
  const t       = townShops[townIdx];
  const entry   = t.shops[shopType];
  if (!entry) {
    console.log(`  No ${shopType} shop in ${t.town_name}.`);
    return false;
  }

  const shop   = entry.assortment;
  const prices = entry.prices;

  let changed = false;

  while (true) {
    printShop(shopType, shop, prices);
    const ans = (await prompt(rl, `\n  Slot# to edit, +item to add, -N to remove slot, s=save, q=quit ${shopType}: `)).trim().toLowerCase();

    if (ans === 'q') break;
    if (ans === 's') { changed = true; break; }

    // Add item
    if (ans === '+item' || ans === '+') {
      const newConst = (await prompt(rl, '  New item constant (e.g. ITEM_HERBS): ')).trim();
      if (!newConst) continue;
      const newPrice = parseInt((await prompt(rl, '  Price: ')).trim(), 10);
      if (isNaN(newPrice) || newPrice < 0) { console.log('  Invalid price.'); continue; }

      let newItem;
      if (shopType === 'item') {
        newItem = { item_type: 'item', item_constant: newConst, item_id: 0, item_name: newConst.replace('ITEM_', '') };
      } else if (shopType === 'equipment') {
        const equipId = (await prompt(rl, '  Equip ID constant (e.g. EQUIPMENT_SWORD_BRONZE): ')).trim();
        newItem = { item_type: 'equipment', equip_type_constant: newConst, equip_type: 0, equip_id_constant: equipId, equip_id: 0, item_name: equipId };
      } else {
        newItem = { item_type: 'magic', magic_constant: newConst, magic_id: 0, item_name: newConst.replace('MAGIC_', '') };
      }
      shop.items.push(newItem);
      prices.push(newPrice);
      shop.item_count = shop.items.length;
      console.log(`  Added slot ${shop.items.length}: ${newConst} at price ${newPrice}`);
      continue;
    }

    // Remove slot
    if (ans.startsWith('-')) {
      const removeIdx = parseInt(ans.slice(1), 10) - 1;
      if (isNaN(removeIdx) || removeIdx < 0 || removeIdx >= shop.items.length) {
        console.log(`  Invalid slot number.`); continue;
      }
      if (shop.items.length <= 1) {
        console.log(`  Cannot remove last item from shop.`); continue;
      }
      shop.items.splice(removeIdx, 1);
      prices.splice(removeIdx, 1);
      shop.item_count = shop.items.length;
      console.log(`  Removed slot ${removeIdx + 1}.`);
      continue;
    }

    // Edit existing slot
    const slotN = parseInt(ans, 10);
    if (isNaN(slotN) || slotN < 1 || slotN > shop.items.length) {
      console.log(`  Enter a slot number 1–${shop.items.length}, +item, or -N.`); continue;
    }
    const slotIdx = slotN - 1;
    const it = shop.items[slotIdx];

    const fieldQ = (await prompt(rl, `  Edit [i]tem constant, [p]rice, or [b]oth? `)).trim().toLowerCase();

    if (fieldQ === 'i' || fieldQ === 'b') {
      const oldConst = it.item_constant || it.equip_id_constant || it.magic_constant || '?';
      const newConst = (await prompt(rl, `  Item constant [${oldConst}]: `)).trim();
      if (newConst) {
        if (it.item_constant !== undefined) it.item_constant = newConst;
        else if (it.equip_id_constant !== undefined) it.equip_id_constant = newConst;
        else if (it.magic_constant !== undefined) it.magic_constant = newConst;
        it.item_name = newConst.replace(/^(ITEM_|EQUIPMENT_|MAGIC_)/, '');
        console.log(`  Item constant set to ${newConst}`);
      }
    }

    if (fieldQ === 'p' || fieldQ === 'b') {
      const oldPrice = prices[slotIdx];
      const newPriceStr = (await prompt(rl, `  Price [${oldPrice}]: `)).trim();
      if (newPriceStr) {
        const newPrice = parseInt(newPriceStr, 10);
        if (isNaN(newPrice) || newPrice < 0) { console.log('  Invalid price.'); }
        else { prices[slotIdx] = newPrice; console.log(`  Price set to ${newPrice}`); }
      }
    }
  }

  return changed;
}

// ---------------------------------------------------------------------------
// Edit a town (choose shop type first)
// ---------------------------------------------------------------------------

async function editTown(rl, townIdx) {
  const t = townShops[townIdx];
  printTown(townIdx);

  const available = Object.keys(t.shops).filter(k => t.shops[k] !== null);
  if (available.length === 0) {
    console.log('  No shops in this town.');
    return false;
  }

  const ans = (await prompt(rl, `\n  Which shop to edit? [${available.join('/')}] or q=quit: `)).trim().toLowerCase();
  if (ans === 'q' || !available.includes(ans)) return false;

  return await editShop(rl, townIdx, ans);
}

// ---------------------------------------------------------------------------
// Save + inject
// ---------------------------------------------------------------------------

async function saveAndInject() {
  warnHealingAvailability();

  if (DRY_RUN) {
    console.log('\n[DRY RUN] Would write:', SHOPS_JSON);
    console.log('[DRY RUN] Would run: node tools/inject_game_data.js --shops');
    return;
  }

  console.log('\nWriting', SHOPS_JSON, '...');
  fs.writeFileSync(SHOPS_JSON, JSON.stringify(rawData, null, 2) + '\n');
  console.log('Saved.');

  if (NO_REBUILD) {
    console.log('--no-rebuild: skipping inject + verify.');
    return;
  }

  console.log('\nInjecting into ASM sources...');
  try {
    execSync(`node "${INJECT_SCRIPT}" --shops`, { cwd: ROOT, stdio: 'inherit' });
  } catch (e) {
    console.error('inject_game_data.js failed. Changes saved to JSON but not injected.');
    process.exit(1);
  }

  console.log('\nRunning verify.bat...');
  try {
    execSync('cmd /c verify.bat', { cwd: ROOT, stdio: 'inherit' });
    console.log('Build verified.');
  } catch (e) {
    console.error('verify.bat FAILED. Review the error above.');
    process.exit(1);
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

if (DO_LIST) { printList(); process.exit(0); }

const townArg = getArg('--town', null);

async function main() {
  const rl = createRl();

  let townIdx;
  if (townArg !== null) {
    townIdx = findTown(townArg);
    if (townIdx < 0) {
      console.error(`No town matching "${townArg}"`);
      rl.close();
      process.exit(1);
    }
  }

  let keepGoing = true;
  while (keepGoing) {
    if (townIdx === undefined) {
      printList();
      const ans = (await prompt(rl, '\nEnter town index or name (or q to quit): ')).trim();
      if (ans === 'q' || ans === 'Q') break;
      townIdx = findTown(ans);
      if (townIdx < 0) { console.log(`No match for "${ans}".`); continue; }
    }

    const changed = await editTown(rl, townIdx);
    townIdx = undefined; // reset for next iteration

    if (changed) {
      const confirm = (await prompt(rl, '\nSave changes? (y/n): ')).trim().toLowerCase();
      if (confirm === 'y') await saveAndInject();
    }

    const again = (await prompt(rl, 'Edit another town? (y/n): ')).trim().toLowerCase();
    keepGoing = (again === 'y');
  }

  rl.close();
  console.log('Done.');
}

main().catch(err => { console.error(err); process.exit(1); });
