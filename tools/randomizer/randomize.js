#!/usr/bin/env node
// tools/randomizer/randomize.js
// Sword of Vermilion — Unified Randomizer CLI
//
// Main entry point for the randomizer. Accepts a seed string, flag bitmask,
// and per-module options. Runs the requested sub-randomizers, validates
// progression, injects data into ASM, rebuilds the ROM, and patches the ROM
// checksum so modified builds boot correctly.
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
//   0x20  maps        Connectivity-preserving overworld sector shuffle preview
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
//   --no-rebuild       Skip ASM inject + build step (data files only)
//   --no-validate      Skip progression validator
//   --maps-mode <m>    Map randomizer mode (default: special-shuffle-generated)
//   --maps-export <p>  Export preview manifest path
//   --help             Show this help

'use strict';

const fs           = require('fs');
const path         = require('path');
const { execSync } = require('child_process');
const {
  cleanupWorkspace,
  copyOutBin,
  createWorkspace,
  runInWorkspace,
} = require('../hack_workdir');

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
     '  --flags <hex>    Module flags (default: 1F = classic modules, add 20 for maps)',
     '  --variance <v>   Variance for enemy/stat randomizers (default: 0.5)',
     '  --behavior       Shuffle enemy behavior flags within tiers',
     '  --dry-run        Run without writing any files or rebuilding',
     '  --no-rebuild     Skip inject + build step',
     '  --no-validate    Skip progression validator',
     '  --maps-mode <m>  Map randomizer mode (default: special-shuffle-generated)',
     '  --maps-export <p> Export preview manifest path',
     '  --help           Show this help',
    '',
    'Flag bits:',
    '  0x01  enemies     0x02  shops   0x04  chests',
     '  0x08  encounters  0x10  stats   0x20  maps',
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
const MAP_MODE = getArg('--maps-mode', 'special-shuffle-generated');
const MAP_EXPORT = getArg('--maps-export', 'tools/data/randomized_maps.json');

const DO_ENEMIES   = !!(FLAGS & 0x01);
const DO_SHOPS     = !!(FLAGS & 0x02);
const DO_CHESTS    = !!(FLAGS & 0x04);
const DO_ENCOUNTERS = !!(FLAGS & 0x08);
const DO_STATS     = !!(FLAGS & 0x10);
const DO_MAPS      = !!(FLAGS & 0x20);

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

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function writeJson(filePath, data) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
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
  DO_MAPS      ? 'maps'       : null,
].filter(Boolean).join(', ')}`);
log(`  Variance:  ${VARIANCE}`);
log(`  Dry run:   ${DRY_RUN}`);

if (DRY_RUN) {
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

  if (DO_MAPS) {
    const script = path.join(__dirname, 'map_randomizer.js');
    runModule('MAPS', script, [`--mode ${MAP_MODE}`]);
  }

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
        process.exit(1);
      }
    } catch (err) {
      log(`[VALIDATE] ERROR: ${err.message}`);
      process.exit(1);
    }
  }

  log('\nDry run complete — no files written.');
  process.exit(0);
}

// Inject data into ASM sources and rebuild in an isolated workspace
if (!NO_REBUILD) {
  const workspace = createWorkspace('randomizer');
  try {
    log(`\n[WORKDIR] Using isolated workspace: ${path.relative(ROOT, workspace)}`);

    const workspaceEnemies = path.join(workspace, 'tools', 'data', 'enemies.json');
    const workspaceShops = path.join(workspace, 'tools', 'data', 'shops.json');
    const workspaceStats = path.join(workspace, 'tools', 'data', 'player_stats.json');

    if (DO_ENEMIES || DO_ENCOUNTERS) writeJson(workspaceEnemies, readJson(path.join(ROOT, 'tools', 'data', 'enemies.json')));
    if (DO_SHOPS) writeJson(workspaceShops, readJson(path.join(ROOT, 'tools', 'data', 'shops.json')));
    if (DO_STATS) writeJson(workspaceStats, readJson(path.join(ROOT, 'tools', 'data', 'player_stats.json')));

    if (DO_ENEMIES) {
      runInWorkspace(workspace, process.execPath, [path.join('tools', 'randomizer', 'enemy_randomizer.js'), '--seed', String(SEED), '--variance', String(VARIANCE), '--output', path.join('data', 'enemies.json'), ...(DO_BEHAV ? ['--behavior'] : [])]);
    }
    if (DO_SHOPS) {
      runInWorkspace(workspace, process.execPath, [path.join('tools', 'randomizer', 'shop_randomizer.js'), '--seed', String(SEED), '--output', path.join('data', 'shops.json')]);
    }
    if (DO_ENCOUNTERS) {
      runInWorkspace(workspace, process.execPath, [path.join('tools', 'randomizer', 'encounter_randomizer.js'), '--seed', String(SEED), '--output', path.join('data', 'enemies.json')]);
    }
    if (DO_STATS) {
      runInWorkspace(workspace, process.execPath, [path.join('tools', 'randomizer', 'stats_randomizer.js'), '--seed', String(SEED), '--variance', String(VARIANCE), '--output', path.join('data', 'player_stats.json')]);
    }
    if (DO_CHESTS) {
      runInWorkspace(workspace, process.execPath, [path.join('tools', 'randomizer', 'chest_randomizer.js'), '--seed', String(SEED)]);
    }
    if (DO_MAPS) {
      runInWorkspace(workspace, process.execPath, [path.join('tools', 'randomizer', 'map_randomizer.js'), '--seed', String(SEED), '--mode', MAP_MODE, '--export', path.join('tools', 'data', 'randomized_maps.json'), '--asset-dir', path.join('tools', 'data', 'randomized_maps_assets'), '--write-assets']);
    }

    log('\n[VALIDATE] Running progression validator in workspace...');
    if (!NO_VALID) {
      runInWorkspace(workspace, process.execPath, [path.join('tools', 'progression_validator.js')]);
      log('[VALIDATE] PASS — game is completable.');
    }

    log('\n[INJECT] Injecting data into workspace ASM sources...');
    const injectFlags = [
      DO_ENEMIES ? '--enemies' : null,
      DO_SHOPS ? '--shops' : null,
      DO_ENCOUNTERS ? '--enemies' : null,
      DO_STATS ? '--player-stats' : null,
    ].filter((v, i, a) => v && a.indexOf(v) === i);
    if (injectFlags.length > 0) {
      runInWorkspace(workspace, process.execPath, [path.join('tools', 'inject_game_data.js'), ...injectFlags]);
    }

    log('\n[BUILD] Running build.bat in workspace...');
    runInWorkspace(workspace, 'cmd', ['/c', 'build.bat']);
    log('[BUILD] PASS — ROM assembled.');

    log('\n[CHECKSUM] Patching ROM checksum in workspace...');
    runInWorkspace(workspace, process.execPath, [path.join('tools', 'patch_rom_checksum.js'), '--rom', 'out.bin']);
    log('[CHECKSUM] PASS — ROM header checksum updated.');

    copyOutBin(workspace, 'out.bin');
    log('[OUTPUT] Copied hacked ROM to out.bin without modifying tracked project data.');
  } catch (err) {
    log(`[WORKDIR] FAIL — ${err.message}`);
    process.exit(1);
  } finally {
    cleanupWorkspace(workspace);
  }
}

log(`\nRandomization complete!`);
log(`  Seed: ${fullSeed}`);
log(`  Share this seed to reproduce the same randomized ROM.`);
