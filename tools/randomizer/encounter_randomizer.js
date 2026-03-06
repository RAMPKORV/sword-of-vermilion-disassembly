#!/usr/bin/env node
// tools/randomizer/encounter_randomizer.js
// Sword of Vermilion — Encounter Randomizer
//
// Shuffles enemy encounter group assignments across overworld map cells and
// cave rooms. Enemy groups that appear in early-game areas stay within a
// tier-appropriate range so the game remains beatable.
//
// Tier boundaries (by group_index, proxy for difficulty):
//   Tier 0 (early):  groups 0–19
//   Tier 1 (mid):    groups 20–44
//   Tier 2 (late):   groups 45–59
//   Tier 3 (final):  groups 60–69
//
// Shuffling is performed within tiers. Group index 0 means "no encounter" in
// the overworld map and is never moved.
//
// Data source: tools/data/enemies.json
// No ASM is modified — enemies.json is updated and inject_game_data.js handles
// the ASM patch (--enemies flag).
//
// Usage:
//   node tools/randomizer/encounter_randomizer.js --seed N [--dry-run] [--json]
//
// Options:
//   --seed N    32-bit integer seed (required unless --dry-run)
//   --dry-run   Show changes without writing
//   --json      Output modified data as JSON
//   --help      Show this help

'use strict';

const fs   = require('fs');
const path = require('path');

const MODULE_ID = 4; // encounter module

// ---------------------------------------------------------------------------
// PRNG
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
    'Usage: node tools/randomizer/encounter_randomizer.js --seed N [--dry-run] [--json]',
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
const OUTPUT_PATH = path.resolve(__dirname, '..', getArg('--output', path.join('data', 'enemies.json')));

// ---------------------------------------------------------------------------
// Tier classification for encounter group indices
// ---------------------------------------------------------------------------

function groupTier(idx) {
  if (idx === 0)  return null; // 0 = no encounter (locked)
  if (idx <= 19)  return 0;
  if (idx <= 44)  return 1;
  if (idx <= 59)  return 2;
  return 3;
}

// ---------------------------------------------------------------------------
// Load data
// ---------------------------------------------------------------------------

const DATA_PATH = path.join(__dirname, '..', 'data', 'enemies.json');
const data = JSON.parse(fs.readFileSync(DATA_PATH, 'utf8'));

// ---------------------------------------------------------------------------
// Randomize
// ---------------------------------------------------------------------------

function randomizeEncounters(seed) {
  const rng = makePrng(seed);

  // Deep clone
  const out = JSON.parse(JSON.stringify(data));

  // Collect all non-zero group indices from overworld_encounter_map rows
  const owRows = out.overworld_encounter_map.rows;
  const flatOW = []; // { row, col, val }
  owRows.forEach((row, r) => {
    row.forEach((val, c) => {
      if (val !== 0) flatOW.push({ row: r, col: c, val });
    });
  });

  // Group overworld cells by tier
  const owByTier = {};
  flatOW.forEach(cell => {
    const t = groupTier(cell.val);
    if (t === null) return;
    if (!owByTier[t]) owByTier[t] = [];
    owByTier[t].push(cell);
  });

  // Shuffle values within each overworld tier
  for (const tier of Object.keys(owByTier)) {
    const cells = owByTier[tier];
    const vals  = cells.map(c => c.val);
    fisherYates(vals, rng);
    cells.forEach((cell, i) => {
      out.overworld_encounter_map.rows[cell.row][cell.col] = vals[i];
    });
  }

  // Collect cave room encounter group indices
  const caveRooms = out.cave_room_encounter_table.rooms; // flat array
  const caveCells = caveRooms
    .map((val, idx) => ({ idx, val }))
    .filter(c => c.val !== 0);

  // Group cave rooms by tier
  const caveByTier = {};
  caveCells.forEach(cell => {
    const t = groupTier(cell.val);
    if (t === null) return;
    if (!caveByTier[t]) caveByTier[t] = [];
    caveByTier[t].push(cell);
  });

  // Shuffle cave room encounter groups within tier
  for (const tier of Object.keys(caveByTier)) {
    const cells = caveByTier[tier];
    const vals  = cells.map(c => c.val);
    fisherYates(vals, rng);
    cells.forEach((cell, i) => {
      out.cave_room_encounter_table.rooms[cell.idx] = vals[i];
    });
  }

  return out;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const modified = randomizeEncounters(SEED);

if (JSON_OUT) {
  console.log(JSON.stringify(modified, null, 2));
  process.exit(0);
}

// Compute summary diffs
const origOW  = data.overworld_encounter_map.rows;
const modOW   = modified.overworld_encounter_map.rows;
const origCave = data.cave_room_encounter_table.rooms;
const modCave  = modified.cave_room_encounter_table.rooms;

let owChanges   = 0;
let caveChanges = 0;

origOW.forEach((row, r) => {
  row.forEach((v, c) => { if (v !== modOW[r][c]) owChanges++; });
});
origCave.forEach((v, i) => { if (v !== modCave[i]) caveChanges++; });

if (DRY_RUN || !seedArg) {
  console.log(`Encounter randomizer — seed=${SEED}`);
  console.log(`  Overworld cells changed:    ${owChanges} / ${origOW.flat().filter(v=>v!==0).length}`);
  console.log(`  Cave room slots changed:    ${caveChanges} / ${origCave.filter(v=>v!==0).length}`);
  if (DRY_RUN) process.exit(0);
}

fs.writeFileSync(OUTPUT_PATH, JSON.stringify(modified, null, 2) + '\n', 'utf8');
console.log(`Encounter randomizer: updated overworld map and cave rooms in ${OUTPUT_PATH}`);
