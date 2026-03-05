#!/usr/bin/env node
// tools/randomizer/randomize.js
// Sword of Vermilion — Unified Randomizer CLI
//
// Main entry point for the randomizer. Accepts a seed string, flag bitmask,
// and per-module options. Runs the requested sub-randomizers, validates
// progression, injects data into ASM, and rebuilds the ROM.
//
// Seed format:  SOV-1-<flags_hex>-<seed_decimal>
//   e.g.        SOV-1-1F-3141592653  (all five modules)
//
// Flag bitmask:
//   0x01  enemies     Enemy stat randomization
//   0x02  shops       Shop inventory randomization
//   0x04  chests      Chest content randomization
//   0x08  encounters  Encounter table randomization
//   0x10  stats       Player stat curve randomization
//
// Usage:
//   node tools/randomizer/randomize.js --seed SOV-1-1F-12345 [options]
//   node tools/randomizer/randomize.js --seed 12345 --flags 1F [options]
//
// Options:
//   --seed <str>       Seed string (SOV-1-FLAGS-SEED) or raw integer
//   --flags <hex>      Override flag bitmask (hex, e.g. 1F for all)
//   --variance <v>     Variance for enemy/stat randomizers (default: 0.5)
//   --behavior         Include enemy behavior flag shuffle
//   --dry-run          Run all sub-randomizers in dry-run mode; do not write
//   --no-rebuild       Skip ASM inject + verify step (data files only)
//   --no-validate      Skip progression validator
//   --help             Show this help

'use strict';

const fs           = require('fs');
const path         = require('path');
const { execSync } = require('child_process');

// ---------------------------------------------------------------------------
// Seed / flag parsing
// ---------------------------------------------------------------------------

const SOV_RE = /^SOV-(\d+)-([0-9A-Fa-f]+)-(\d+)$/;

function parseSeed(str) {
  const m = SOV_RE.exec(str);
  if (m) {
    return { version: parseInt(m[1], 10), flags: parseInt(m[2], 16), seed: parseInt(m[3], 10) >>> 0 };
  }
  // Raw integer seed, no flags embedded
  const raw = parseInt(str, 10);
  if (!isNaN(raw)) return { version: 1, flags: null, seed: raw >>> 0 };
  return null;
}

function formatSeed(flags, seed) {
  return `SOV-1-${flags.toString(16).toUpperCase().padStart(2, '0')}-${seed}`;
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

const args       = process.argv.slice(2);
const HELP       = args.includes('--help');
const DRY_RUN    = args.includes('--dry-run');
const NO_REBUILD = args.includes('--no-rebuild');
const NO_VALID   = args.includes('--no-validate');
const DO_BEHAV   = args.includes('--behavior');

if (HELP || args.length === 0) {
  console.log([
    'Usage: node tools/randomizer/randomize.js --seed <seed> [options]',
    '',
    'Seed formats:',
    '  SOV-1-<flags_hex>-<integer>   Full seed string (flags embedded)',
    '  <integer>                     Raw seed (use --flags to select modules)',
    '',
    'Options:',
    '  --seed <s>       Seed (required)',
    '  --flags <hex>    Module flags (default: 1F = all modules)',
    '  --variance <v>   Variance for enemy/stat randomizers (default: 0.5)',
    '  --behavior       Shuffle enemy behavior flags within tiers',
    '  --dry-run        Run without writing any files or rebuilding',
    '  --no-rebuild     Skip inject + verify.bat step',
    '  --no-validate    Skip progression validator',
    '  --help           Show this help',
    '',
    'Flag bits:',
    '  0x01  enemies     0x02  shops   0x04  chests',
    '  0x08  encounters  0x10  stats',
  ].join('\n'));
  process.exit(args.length === 0 ? 1 : 0);
}

function getArg(flag, def) {
  const i = args.indexOf(flag);
  return i >= 0 && args[i + 1] !== undefined ? args[i + 1] : def;
}

const seedStr = getArg('--seed', null);
if (!seedStr) {
  console.error('Error: --seed is required');
  process.exit(1);
}

const parsed = parseSeed(seedStr);
if (!parsed) {
  console.error(`Error: unrecognised seed format: ${seedStr}`);
  process.exit(1);
}

const flagsArg = getArg('--flags', null);
const FLAGS    = flagsArg ? parseInt(flagsArg, 16) : (parsed.flags !== null ? parsed.flags : 0x1F);
const SEED     = parsed.seed;
const VARIANCE = parseFloat(getArg('--variance', '0.5'));

const DO_ENEMIES   = !!(FLAGS & 0x01);
const DO_SHOPS     = !!(FLAGS & 0x02);
const DO_CHESTS    = !!(FLAGS & 0x04);
const DO_ENCOUNTERS = !!(FLAGS & 0x08);
const DO_STATS     = !!(FLAGS & 0x10);

const ROOT = path.join(__dirname, '..', '..');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function log(msg) { process.stdout.write(msg + '\n'); }

function runModule(label, scriptPath, extraArgs) {
  const nodeArgs = [
    `--seed ${SEED}`,
    DRY_RUN ? '--dry-run' : '',
    ...extraArgs,
  ].filter(Boolean).join(' ');

  log(`\n[${label}] Running...`);
  try {
    const out = execSync(`node "${scriptPath}" ${nodeArgs}`, {
      cwd: ROOT,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    process.stdout.write(out.split('\n').map(l => `  ${l}`).join('\n'));
  } catch (err) {
    log(`  ERROR: ${err.stderr || err.message}`);
    process.exit(1);
  }
  log(`[${label}] Done.`);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const fullSeed = formatSeed(FLAGS, SEED);
log(`Sword of Vermilion Randomizer`);
log(`  Seed:      ${fullSeed}`);
log(`  Modules:   ${[
  DO_ENEMIES   ? 'enemies'    : null,
  DO_SHOPS     ? 'shops'      : null,
  DO_CHESTS    ? 'chests'     : null,
  DO_ENCOUNTERS ? 'encounters' : null,
  DO_STATS     ? 'stats'      : null,
].filter(Boolean).join(', ')}`);
log(`  Variance:  ${VARIANCE}`);
log(`  Dry run:   ${DRY_RUN}`);

// Run sub-randomizers
if (DO_ENEMIES) {
  const script = path.join(__dirname, 'enemy_randomizer.js');
  runModule('ENEMIES', script, [`--variance ${VARIANCE}`, DO_BEHAV ? '--behavior' : ''].filter(Boolean));
}

if (DO_SHOPS) {
  const script = path.join(__dirname, 'shop_randomizer.js');
  runModule('SHOPS', script, []);
}

if (DO_CHESTS) {
  const script = path.join(__dirname, 'chest_randomizer.js');
  runModule('CHESTS', script, []);
}

if (DO_ENCOUNTERS) {
  const script = path.join(__dirname, 'encounter_randomizer.js');
  runModule('ENCOUNTERS', script, []);
}

if (DO_STATS) {
  const script = path.join(__dirname, 'stats_randomizer.js');
  runModule('STATS', script, [`--variance ${VARIANCE}`]);
}

if (DRY_RUN) {
  log('\nDry run complete — no files written.');
  process.exit(0);
}

// Progression validation
if (!NO_VALID) {
  log('\n[VALIDATE] Running progression validator...');
  try {
    const out = execSync(`node "${path.join(ROOT, 'tools', 'progression_validator.js')}"`, {
      cwd: ROOT,
      encoding: 'utf8',
    });
    const pass = out.includes('RESULT: PASS');
    if (pass) {
      log('[VALIDATE] PASS — game is completable.');
    } else {
      log('[VALIDATE] FAIL — progression check failed!');
      log(out);
      log('Aborting. The randomized data breaks game progression.');
      log('Try a different seed or disable problematic modules.');
      process.exit(1);
    }
  } catch (err) {
    log(`[VALIDATE] ERROR: ${err.message}`);
    process.exit(1);
  }
}

// Inject data into ASM sources and rebuild
if (!NO_REBUILD) {
  log('\n[INJECT] Injecting data into ASM sources...');
  const injectFlags = [
    DO_ENEMIES    ? '--enemies'      : null,
    DO_SHOPS      ? '--shops'        : null,
    DO_ENCOUNTERS ? '--enemies'      : null, // encounter data lives in enemies.json
    DO_STATS      ? '--player-stats' : null,
  ].filter((v, i, a) => v && a.indexOf(v) === i); // deduplicate

  if (injectFlags.length > 0) {
    try {
      const out = execSync(
        `node "${path.join(ROOT, 'tools', 'inject_game_data.js')}" ${injectFlags.join(' ')}`,
        { cwd: ROOT, encoding: 'utf8' }
      );
      process.stdout.write(out.split('\n').map(l => `  ${l}`).join('\n'));
    } catch (err) {
      log(`[INJECT] ERROR: ${err.message}`);
      process.exit(1);
    }
  }

  // Chest randomizer patches towndata.asm directly — no inject step needed.
  if (DO_CHESTS) {
    log('[INJECT] Chests: towndata.asm patched directly by chest_randomizer.js');
  }

  log('\n[BUILD] Running verify.bat...');
  try {
    execSync('cmd /c verify.bat', { cwd: ROOT, stdio: 'inherit' });
    log('[BUILD] PASS — bit-perfect build verified.');
  } catch (err) {
    log('[BUILD] FAIL — build or hash mismatch!');
    log('The randomized patches may have introduced a build error.');
    log('Run verify.bat manually for details.');
    process.exit(1);
  }
}

log(`\nRandomization complete!`);
log(`  Seed: ${fullSeed}`);
log(`  Share this seed to reproduce the same randomized ROM.`);
