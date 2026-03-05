#!/usr/bin/env node
// tools/randomizer/enemy_randomizer.js
// Sword of Vermilion — Enemy Stat Randomizer
//
// Randomizes enemy stats (HP, damage, speed, XP/kim rewards, behavior flags)
// within configurable variance bounds. All changes are applied to in-memory
// data and written back to tools/data/enemies.json.
//
// Used by tools/randomizer/randomize.js. Can also be run standalone:
//
//   node tools/randomizer/enemy_randomizer.js --seed 12345 --variance 0.5 [--dry-run]
//
// Options:
//   --seed N       32-bit integer seed (required unless --help)
//   --variance V   Max variance multiplier delta, 0–1 (default: 0.5 → range 0.5×–1.5×)
//   --behavior     Also shuffle behavior_flag across same-tier enemies
//   --dry-run      Print changes without writing
//   --json         Output modified enemies array as JSON to stdout
//   --help         Show this help

'use strict';

const fs   = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// PRNG (xorshift32 — see randomizer_architecture.md)
// ---------------------------------------------------------------------------

const MODULE_ID = 1; // enemy module

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
    // float in [0, 1)
    float() { return (this.next() >>> 0) / 4294967296; },
    // float in [min, max)
    range(min, max) { return min + this.float() * (max - min); },
    // integer in [min, max] inclusive
    int(min, max) { return Math.floor(this.range(min, max + 1)); },
  };
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

const args    = process.argv.slice(2);
const HELP    = args.includes('--help');
const DRY_RUN = args.includes('--dry-run');
const JSON_OUT = args.includes('--json');
const DO_BEHAVIOR = args.includes('--behavior');

if (HELP) {
  console.log([
    'Usage: node tools/randomizer/enemy_randomizer.js --seed N [options]',
    '',
    'Options:',
    '  --seed N       Seed integer (required)',
    '  --variance V   Max variance delta 0-1 (default: 0.5)',
    '  --behavior     Shuffle behavior_flag within tiers',
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
const VARIANCE = parseFloat(getArg('--variance', '0.5'));

// ---------------------------------------------------------------------------
// Load data
// ---------------------------------------------------------------------------

const DATA_PATH = path.join(__dirname, '..', 'data', 'enemies.json');
const data = JSON.parse(fs.readFileSync(DATA_PATH, 'utf8'));
const enemies = data.enemies; // array of 85 enemies

// ---------------------------------------------------------------------------
// Tier classification (by base HP — proxy for enemy strength)
// ---------------------------------------------------------------------------

function classifyTier(hp) {
  if (hp < 50)  return 0; // early
  if (hp < 150) return 1; // mid
  if (hp < 400) return 2; // late
  return 3;               // boss-tier
}

// ---------------------------------------------------------------------------
// Randomize stats
// ---------------------------------------------------------------------------

function randomizeEnemies(seed, variance, doBehavior) {
  const rng = makePrng(seed);
  const lo  = 1 - variance;
  const hi  = 1 + variance;

  const modified = enemies.map((enemy, i) => {
    const s = { ...enemy, stats: { ...enemy.stats } };
    const st = s.stats;

    // HP
    const hpFactor = rng.range(lo, hi);
    st.hp = Math.max(1, Math.min(65535, Math.round(st.hp * hpFactor)));

    // Damage
    const dmgFactor = rng.range(lo, hi);
    st.damage_per_hit = Math.max(1, Math.min(255, Math.round(st.damage_per_hit * dmgFactor)));

    // Speed (tighter variance)
    const spd = variance * 0.75;
    const spdFactor = rng.range(1 - spd, 1 + spd);
    st.speed = Math.max(64, Math.min(65535, Math.round(st.speed * spdFactor)));

    // XP reward
    const xpFactor = rng.range(lo, hi);
    st.xp_reward = Math.max(1, Math.round(st.xp_reward * xpFactor));

    // Kim reward
    const kimFactor = rng.range(lo, hi);
    st.kim_reward = Math.max(0, Math.round(st.kim_reward * kimFactor));

    return s;
  });

  // Behavior flag shuffle (within same tier)
  if (doBehavior) {
    const tierGroups = {};
    modified.forEach((e, i) => {
      const tier = classifyTier(e.stats.hp);
      if (!tierGroups[tier]) tierGroups[tier] = [];
      tierGroups[tier].push(i);
    });
    for (const tier of Object.keys(tierGroups)) {
      const indices = tierGroups[tier];
      // Fisher-Yates shuffle of behavior_flag values within tier
      const flags = indices.map(i => modified[i].stats.behavior_flag);
      for (let j = flags.length - 1; j > 0; j--) {
        const k = rng.int(0, j);
        [flags[j], flags[k]] = [flags[k], flags[j]];
      }
      indices.forEach((idx, pos) => {
        modified[idx].stats.behavior_flag = flags[pos];
      });
    }
  }

  return modified;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const modifiedEnemies = randomizeEnemies(SEED, VARIANCE, DO_BEHAVIOR);

if (JSON_OUT) {
  console.log(JSON.stringify(modifiedEnemies, null, 2));
  process.exit(0);
}

if (DRY_RUN || !seedArg) {
  console.log(`Enemy randomizer — seed=${SEED} variance=${VARIANCE}`);
  modifiedEnemies.forEach((e, i) => {
    const orig = enemies[i].stats;
    const mod  = e.stats;
    const diffs = [];
    if (orig.hp !== mod.hp)             diffs.push(`hp: ${orig.hp} → ${mod.hp}`);
    if (orig.damage_per_hit !== mod.damage_per_hit) diffs.push(`dmg: ${orig.damage_per_hit} → ${mod.damage_per_hit}`);
    if (orig.speed !== mod.speed)       diffs.push(`spd: ${orig.speed} → ${mod.speed}`);
    if (orig.xp_reward !== mod.xp_reward) diffs.push(`xp: ${orig.xp_reward} → ${mod.xp_reward}`);
    if (orig.kim_reward !== mod.kim_reward) diffs.push(`kim: ${orig.kim_reward} → ${mod.kim_reward}`);
    if (orig.behavior_flag !== mod.behavior_flag) diffs.push(`bhv: ${orig.behavior_flag} → ${mod.behavior_flag}`);
    if (diffs.length > 0) {
      console.log(`  [${String(i).padStart(3)}] ${String(orig.name).padEnd(20)} ${diffs.join(', ')}`);
    }
  });
  if (DRY_RUN) process.exit(0);
}

// Write modified data
const out = { ...data, enemies: modifiedEnemies };
fs.writeFileSync(DATA_PATH, JSON.stringify(out, null, 2) + '\n', 'utf8');
console.log(`Enemy randomizer: wrote ${modifiedEnemies.length} enemy entries to ${DATA_PATH}`);
