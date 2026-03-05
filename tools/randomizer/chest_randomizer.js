#!/usr/bin/env node
// tools/randomizer/chest_randomizer.js
// Sword of Vermilion — Chest Content Randomizer
//
// Shuffles non-key item chests in towndata.asm:
//   - ItemChest (consumable items) shuffled among themselves
//   - EquipChest (equipment) shuffled among themselves
//   - MoneyChest amounts shuffled among themselves
//   - RingChest and story-critical items (ITEM_MIRROR_OF_ATLAS,
//     ITEM_RUBY_BROOCH) are LOCKED and never moved.
//
// Patches towndata.asm in-place using regex line replacement.
// After patching, re-run verify.bat to confirm bit-perfect build.
//
// Usage:
//   node tools/randomizer/chest_randomizer.js --seed N [--dry-run] [--json]
//
// Options:
//   --seed N    32-bit integer seed (required unless --dry-run)
//   --dry-run   Show changes without writing
//   --json      Output modified chest list as JSON
//   --help      Show this help

'use strict';

const fs   = require('fs');
const path = require('path');

const MODULE_ID = 3; // chest module

// ---------------------------------------------------------------------------
// PRNG (xorshift32 — see randomizer_architecture.md)
// ---------------------------------------------------------------------------

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

function fisherYates(arr, rng) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = rng.int(0, i);
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
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
    'Usage: node tools/randomizer/chest_randomizer.js --seed N [--dry-run] [--json]',
    '',
    'Options:',
    '  --seed N    Seed integer (required)',
    '  --dry-run   Show changes without writing',
    '  --json      Output modified chest list as JSON',
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
// Story-critical item constants — these are NEVER shuffled
// ---------------------------------------------------------------------------

// Items that are required for progression or are unique story rewards.
// Consumable ItemChest items (HERBS, CANDLE, LANTERN, MEDICINE, POISON_BALM,
// BANSHEE_POWDER, GNOME_STONE) are freely shuffleable.
const LOCKED_ITEMS = new Set([
  'ITEM_MIRROR_OF_ATLAS',  // required for Excalabria quest
  'ITEM_RUBY_BROOCH',      // story item / gift
]);

// ---------------------------------------------------------------------------
// Parse towndata.asm chest macros
// ---------------------------------------------------------------------------

const TOWNDATA_PATH = path.join(__dirname, '..', '..', 'src', 'towndata.asm');
const source = fs.readFileSync(TOWNDATA_PATH, 'utf8');
const lines  = source.split('\n');

// Chest record: { lineIdx, type, raw, locked, ...fields }
// type: 'item' | 'equip' | 'money' | 'ring'
const chests = [];

const RE_ITEM  = /^(\s+)ItemChest\s+(ITEM_\w+)\s*,\s*(\w+)/;
const RE_EQUIP = /^(\s+)EquipChest\s+(EQUIPMENT_TYPE_\w+)\s*,\s*(EQUIPMENT_\w+)\s*,\s*(\w+)(.*)/;
const RE_MONEY = /^(\s+)MoneyChest\s+(\$[0-9A-Fa-f]+)\s*,\s*(\w+)/;
const RE_RING  = /^(\s+)RingChest\s+(\d+)\s*,\s*(\d+)\s*,\s*(\w+)/;

for (let i = 0; i < lines.length; i++) {
  const line = lines[i];
  let m;

  if ((m = RE_ITEM.exec(line))) {
    const itemConst = m[2];
    const flag      = m[3];
    chests.push({
      lineIdx: i,
      type:    'item',
      indent:  m[1],
      item:    itemConst,
      flag,
      locked:  LOCKED_ITEMS.has(itemConst),
      raw:     line,
    });
  } else if ((m = RE_EQUIP.exec(line))) {
    const flag    = m[4];
    const trailer = m[5].trim(); // optional EQUIPMENT_FLAG_CURSED etc.
    chests.push({
      lineIdx:  i,
      type:     'equip',
      indent:   m[1],
      eqType:   m[2],
      eqId:     m[3],
      flag,
      trailer,
      locked:   false,
      raw:      line,
    });
  } else if ((m = RE_MONEY.exec(line))) {
    chests.push({
      lineIdx: i,
      type:    'money',
      indent:  m[1],
      amount:  m[2],
      flag:    m[3],
      locked:  false,
      raw:     line,
    });
  } else if ((m = RE_RING.exec(line))) {
    // RingChest — always locked (story ring rewards)
    chests.push({
      lineIdx: i,
      type:    'ring',
      indent:  m[1],
      rType:   m[2],
      rVal:    m[3],
      flag:    m[4],
      locked:  true,
      raw:     line,
    });
  }
}

// ---------------------------------------------------------------------------
// Randomize
// ---------------------------------------------------------------------------

function randomizeChests(seed) {
  const rng = makePrng(seed);

  // Deep-clone chest list
  const modified = chests.map(c => ({ ...c }));

  // Shuffle ItemChest contents (only unlocked items)
  const itemGroup = modified.filter(c => c.type === 'item' && !c.locked);
  const itemValues = itemGroup.map(c => c.item);
  fisherYates(itemValues, rng);
  itemGroup.forEach((c, i) => { c.item = itemValues[i]; });

  // Shuffle EquipChest: shuffle (eqType, eqId, trailer) tuples together
  // Keep flag (opened-flag) in place — only swap the equipment identity
  const equipGroup = modified.filter(c => c.type === 'equip' && !c.locked);
  const equipValues = equipGroup.map(c => ({ eqType: c.eqType, eqId: c.eqId, trailer: c.trailer }));
  fisherYates(equipValues, rng);
  equipGroup.forEach((c, i) => {
    c.eqType   = equipValues[i].eqType;
    c.eqId     = equipValues[i].eqId;
    c.trailer  = equipValues[i].trailer;
  });

  // Shuffle MoneyChest amounts (keep flags in place)
  const moneyGroup = modified.filter(c => c.type === 'money' && !c.locked);
  const moneyAmounts = moneyGroup.map(c => c.amount);
  fisherYates(moneyAmounts, rng);
  moneyGroup.forEach((c, i) => { c.amount = moneyAmounts[i]; });

  return modified;
}

// ---------------------------------------------------------------------------
// Render modified chest back to source line
// ---------------------------------------------------------------------------

function renderChest(c) {
  switch (c.type) {
    case 'item':
      return `${c.indent}ItemChest ${c.item}, ${c.flag}`;
    case 'equip': {
      // trailer already includes leading ', ' if present (captured from source)
      return `${c.indent}EquipChest ${c.eqType}, ${c.eqId}, ${c.flag}${c.trailer}`;
    }
    case 'money':
      return `${c.indent}MoneyChest ${c.amount}, ${c.flag}`;
    case 'ring':
      return `${c.indent}RingChest ${c.rType}, ${c.rVal}, ${c.flag}`;
    default:
      return c.raw;
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const modifiedChests = randomizeChests(SEED);

if (JSON_OUT) {
  console.log(JSON.stringify(modifiedChests, null, 2));
  process.exit(0);
}

// Collect diffs
const diffs = [];
modifiedChests.forEach((mc, idx) => {
  const orig   = chests[idx];
  const newLine = renderChest(mc);
  if (newLine.trimEnd() !== orig.raw.trimEnd()) {
    diffs.push({ lineIdx: mc.lineIdx, orig: orig.raw, newLine });
  }
});

if (DRY_RUN || !seedArg) {
  console.log(`Chest randomizer — seed=${SEED}`);
  console.log(`  Total chests parsed: ${chests.length} (item:${chests.filter(c=>c.type==='item').length} equip:${chests.filter(c=>c.type==='equip').length} money:${chests.filter(c=>c.type==='money').length} ring:${chests.filter(c=>c.type==='ring').length})`);
  console.log(`  Changes: ${diffs.length}`);
  diffs.forEach(d => {
    console.log(`  L${d.lineIdx + 1}: ${d.orig.trim()} → ${d.newLine.trim()}`);
  });
  if (DRY_RUN) process.exit(0);
}

// Apply changes to source
const newLines = lines.slice();
diffs.forEach(d => {
  newLines[d.lineIdx] = d.newLine;
});

fs.writeFileSync(TOWNDATA_PATH, newLines.join('\n'), 'utf8');
console.log(`Chest randomizer: patched ${diffs.length} chest lines in src/towndata.asm`);
console.log('Run verify.bat to confirm bit-perfect build.');
