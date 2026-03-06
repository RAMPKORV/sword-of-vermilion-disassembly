#!/usr/bin/env node
// tools/randomizer/stats_randomizer.js
// Sword of Vermilion — Player Stats Randomizer
//
// Applies variance-bounded randomization to per-level stat gains in
// player_stats.json. Each stat gain is multiplied by a random factor in
// [1-variance, 1+variance], then clamped to a safe range.
//
// XP thresholds are intentionally NOT randomized — they affect game pacing in
// ways that can make the game unfinishable if set too high.
//
// Writes modified data back to tools/data/player_stats.json unless an
// alternate output path is provided.
// After writing, use inject_game_data.js --player-stats to patch playerstats.asm.
//
// Usage:
//   node tools/randomizer/stats_randomizer.js --seed N [--variance V] [--dry-run] [--json]
//
// Options:
//   --seed N       32-bit integer seed (required)
//   --variance V   Max variance delta 0-1 (default: 0.4 → range 0.6×–1.4×)
//   --dry-run      Show changes without writing
//   --json         Output modified data as JSON
//   --help         Show this help

'use strict';

const fs   = require('fs');
const path = require('path');

const MODULE_ID = 5; // stats module

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
    range(min, max) { return min + this.float() * (max - min); },
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
    'Usage: node tools/randomizer/stats_randomizer.js --seed N [--variance V] [--dry-run] [--json]',
    '',
    'Options:',
    '  --seed N       Seed integer (required)',
    '  --variance V   Max variance delta 0-1 (default: 0.4)',
    '  --dry-run      Show changes without writing',
    '  --json         Output modified data as JSON',
    '  --help         Show this help',
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
const SEED     = seedArg ? (parseInt(seedArg, 10) >>> 0) : 0;
const VARIANCE = parseFloat(getArg('--variance', '0.4'));
const OUTPUT_PATH = path.resolve(__dirname, '..', getArg('--output', path.join('data', 'player_stats.json')));

// ---------------------------------------------------------------------------
// Stat limits (safe ranges for each gain field)
// ---------------------------------------------------------------------------

const STAT_LIMITS = {
  mhp_gain: { min: 1,  max: 255 },
  mmp_gain: { min: 0,  max: 255 },
  str_gain: { min: 0,  max: 255 },
  ac_gain:  { min: 0,  max: 255 },
  int_gain: { min: 0,  max: 255 },
  dex_gain: { min: 0,  max: 255 },
  luk_gain: { min: 0,  max: 255 },
};

// xp_to_next is intentionally excluded from randomization.

// ---------------------------------------------------------------------------
// Load data
// ---------------------------------------------------------------------------

const DATA_PATH = path.join(__dirname, '..', 'data', 'player_stats.json');
const data = JSON.parse(fs.readFileSync(DATA_PATH, 'utf8'));
const levelUps = data.level_ups; // array of 31 level-up entries

// ---------------------------------------------------------------------------
// Randomize
// ---------------------------------------------------------------------------

function randomizeStats(seed, variance) {
  const rng  = makePrng(seed);
  const lo   = 1 - variance;
  const hi   = 1 + variance;

  const modified = levelUps.map(entry => {
    const out = { ...entry };
    for (const [field, limits] of Object.entries(STAT_LIMITS)) {
      if (entry[field] === undefined) continue;
      if (entry[field] === 0) continue; // keep zero gains at zero
      const factor = rng.range(lo, hi);
      out[field] = Math.max(limits.min, Math.min(limits.max, Math.round(entry[field] * factor)));
    }
    // xp_to_next is preserved verbatim
    return out;
  });

  return { ...data, level_ups: modified };
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const modified = randomizeStats(SEED, VARIANCE);

if (JSON_OUT) {
  console.log(JSON.stringify(modified, null, 2));
  process.exit(0);
}

if (DRY_RUN || !seedArg) {
  console.log(`Stats randomizer — seed=${SEED} variance=${VARIANCE}`);
  modified.level_ups.forEach((entry, i) => {
    const orig = levelUps[i];
    const diffs = [];
    for (const field of Object.keys(STAT_LIMITS)) {
      if (orig[field] !== entry[field]) {
        diffs.push(`${field}: ${orig[field]} → ${entry[field]}`);
      }
    }
    if (diffs.length > 0) {
      console.log(`  Lv${String(entry.level).padStart(2)}: ${diffs.join(', ')}`);
    }
  });
  if (DRY_RUN) process.exit(0);
}

fs.writeFileSync(OUTPUT_PATH, JSON.stringify(modified, null, 2) + '\n', 'utf8');
console.log(`Stats randomizer: wrote ${modified.level_ups.length} level-up entries to ${OUTPUT_PATH}`);
