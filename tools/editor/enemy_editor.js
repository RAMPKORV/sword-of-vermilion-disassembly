#!/usr/bin/env node
// tools/editor/enemy_editor.js
// Sword of Vermilion — Enemy Stat Editor
//
// Interactive CLI for viewing and editing enemy stats in tools/data/enemies.json.
// Changes are validated against hardware-safe ranges and written back to JSON.
// After editing, the modified data is injected into the ASM source and verified
// with verify.bat (unless --no-rebuild is given).
//
// Usage:
//   node tools/editor/enemy_editor.js [options]
//   node tools/editor/enemy_editor.js --enemy <name_or_index> [field=value ...]
//
// Options:
//   --list              List all enemies with index, name, and key stats, then exit
//   --enemy <n>         Select enemy by index (0-based) or name substring, skip menu
//   --set <field=val>   Set a field directly (can repeat; skips interactive loop)
//   --no-rebuild        Skip inject + verify.bat after saving
//   --dry-run           Show changes without writing any files
//   --json              Dump full enemies array as JSON and exit
//   --help              Show this help

'use strict';

const fs       = require('fs');
const path     = require('path');
const readline = require('readline');
const { execSync } = require('child_process');

// ---------------------------------------------------------------------------
// Paths
// ---------------------------------------------------------------------------

const ROOT          = path.join(__dirname, '..', '..');
const ENEMIES_JSON  = path.join(ROOT, 'tools', 'data', 'enemies.json');
const INJECT_SCRIPT = path.join(ROOT, 'tools', 'inject_game_data.js');

// ---------------------------------------------------------------------------
// Field definitions with constraints
// ---------------------------------------------------------------------------

const EDITABLE_FIELDS = [
  { key: 'hp',            label: 'HP',             type: 'int', min: 1,    max: 65535 },
  { key: 'damage_per_hit',label: 'Damage/hit',      type: 'int', min: 1,    max: 255   },
  { key: 'speed',         label: 'Speed',           type: 'int', min: 64,   max: 65535 },
  { key: 'xp_reward',     label: 'XP reward',       type: 'int', min: 1,    max: 65535 },
  { key: 'kim_reward',    label: 'Kim reward',      type: 'int', min: 0,    max: 65535 },
  { key: 'behavior_flag', label: 'Behavior flag',   type: 'hex', min: 0x00, max: 0xFF  },
  { key: 'max_spawn',     label: 'Max spawn count', type: 'int', min: 1,    max: 255   },
];

// Read-only info fields (shown but not editable)
const INFO_FIELDS = ['name', 'ai_fn', 'tile_id', 'reward_type', 'reward_value', 'extra_obj_slots', 'sprite_frame'];

// ---------------------------------------------------------------------------
// CLI argument parsing
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

// Collect all --set field=value pairs
function getSetArgs() {
  const sets = {};
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--set' && args[i + 1]) {
      const eq = args[i + 1].indexOf('=');
      if (eq > 0) {
        sets[args[i + 1].slice(0, eq)] = args[i + 1].slice(eq + 1);
      }
      i++;
    }
  }
  // Also accept bare field=value arguments
  for (const a of args) {
    if (!a.startsWith('--')) {
      const eq = a.indexOf('=');
      if (eq > 0) sets[a.slice(0, eq)] = a.slice(eq + 1);
    }
  }
  return sets;
}

if (HELP) {
  console.log([
    'Usage: node tools/editor/enemy_editor.js [options]',
    '',
    'Options:',
    '  --list              List all 85 enemies with stats',
    '  --enemy <n>         Select by 0-based index or name substring',
    '  --set <field=val>   Set a field non-interactively (repeatable)',
    '  --no-rebuild        Skip inject_game_data.js + verify.bat',
    '  --dry-run           Show changes without writing',
    '  --json              Dump full enemies array as JSON and exit',
    '  --help              Show this help',
    '',
    'Editable fields:',
    ...EDITABLE_FIELDS.map(f => `  ${f.key.padEnd(16)} ${f.label} (${f.type}, ${f.min}–${f.max})`),
  ].join('\n'));
  process.exit(0);
}

// ---------------------------------------------------------------------------
// Load data
// ---------------------------------------------------------------------------

if (!fs.existsSync(ENEMIES_JSON)) {
  console.error(`Error: ${ENEMIES_JSON} not found. Run tools/extract_game_data.js first.`);
  process.exit(1);
}

const data    = JSON.parse(fs.readFileSync(ENEMIES_JSON, 'utf8'));
const enemies = data.enemies;

if (DO_JSON) {
  console.log(JSON.stringify(enemies, null, 2));
  process.exit(0);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function pad(s, n) { return String(s).padEnd(n); }
function lpad(s, n) { return String(s).padStart(n); }

function fmtField(f, val) {
  if (f.type === 'hex') return `$${val.toString(16).toUpperCase().padStart(2, '0')}`;
  return String(val);
}

function parseFieldValue(f, raw) {
  let n;
  if (f.type === 'hex') {
    n = raw.startsWith('$') ? parseInt(raw.slice(1), 16) : parseInt(raw, 16);
  } else {
    n = parseInt(raw, 10);
  }
  if (isNaN(n)) return { error: `"${raw}" is not a valid number` };
  if (n < f.min || n > f.max) return { error: `${n} is out of range [${f.min}–${f.max}]` };
  return { value: n };
}

function printEnemy(idx, e) {
  const s = e.stats;
  console.log(`\n[${ lpad(idx, 2)}] ${s.name}`);
  console.log('  ' + '─'.repeat(50));
  for (const f of EDITABLE_FIELDS) {
    const val = s[f.key];
    console.log(`  ${pad(f.key, 16)} ${pad(fmtField(f, val), 8)}  (${f.label}, ${f.min}–${f.max})`);
  }
  console.log('  ' + '─'.repeat(50));
  console.log(`  ${'name'.padEnd(16)} ${s.name}  (read-only)`);
  console.log(`  ${'ai_fn'.padEnd(16)} ${s.ai_fn}  (read-only)`);
}

function printList() {
  console.log(`${'Idx'.padEnd(4)} ${'Name'.padEnd(22)} ${'HP'.padEnd(6)} ${'Dmg'.padEnd(5)} ${'Spd'.padEnd(6)} ${'XP'.padEnd(5)} ${'Kim'.padEnd(5)} Bhv`);
  console.log('─'.repeat(70));
  for (let i = 0; i < enemies.length; i++) {
    const s = enemies[i].stats;
    console.log(
      `${lpad(i, 3)}  ${pad(s.name, 22)} ${lpad(s.hp, 5)}  ${lpad(s.damage_per_hit, 4)}  ` +
      `${lpad(s.speed, 5)}  ${lpad(s.xp_reward, 4)}  ${lpad(s.kim_reward, 4)}  ` +
      `$${s.behavior_flag.toString(16).toUpperCase().padStart(2, '0')}`
    );
  }
}

// ---------------------------------------------------------------------------
// List mode
// ---------------------------------------------------------------------------

if (DO_LIST) {
  printList();
  process.exit(0);
}

// ---------------------------------------------------------------------------
// Find enemy by --enemy flag
// ---------------------------------------------------------------------------

function findEnemy(query) {
  const n = parseInt(query, 10);
  if (!isNaN(n) && n >= 0 && n < enemies.length) return n;
  const q = query.toLowerCase();
  const idx = enemies.findIndex(e => e.stats.name.toLowerCase().includes(q));
  if (idx >= 0) return idx;
  return -1;
}

const enemyArg  = getArg('--enemy', null);
const setArgs   = getSetArgs();

// ---------------------------------------------------------------------------
// Non-interactive (--enemy + --set) mode
// ---------------------------------------------------------------------------

async function applyNonInteractive(idx) {
  const e = enemies[idx];
  printEnemy(idx, e);

  let changed = false;
  for (const [key, raw] of Object.entries(setArgs)) {
    const f = EDITABLE_FIELDS.find(x => x.key === key);
    if (!f) {
      console.error(`Unknown or non-editable field: ${key}`);
      process.exit(1);
    }
    const result = parseFieldValue(f, raw);
    if (result.error) {
      console.error(`Field ${key}: ${result.error}`);
      process.exit(1);
    }
    const old = e.stats[key];
    e.stats[key] = result.value;
    console.log(`  ${key}: ${fmtField(f, old)} → ${fmtField(f, result.value)}`);
    changed = true;
  }

  if (!changed) {
    console.log('No --set arguments provided; nothing changed.');
    return;
  }

  await saveAndInject();
}

// ---------------------------------------------------------------------------
// Interactive edit loop
// ---------------------------------------------------------------------------

function createRl() {
  return readline.createInterface({ input: process.stdin, output: process.stdout });
}

async function prompt(rl, question) {
  return new Promise(resolve => rl.question(question, resolve));
}

async function selectEnemy(rl) {
  printList();
  while (true) {
    const ans = (await prompt(rl, '\nEnter enemy index or name (or q to quit): ')).trim();
    if (ans === 'q' || ans === 'Q') return -1;
    const idx = findEnemy(ans);
    if (idx >= 0) return idx;
    console.log(`No match for "${ans}". Try an index (0–${enemies.length - 1}) or name substring.`);
  }
}

async function editEnemy(rl, idx) {
  const e = enemies[idx];
  printEnemy(idx, e);

  while (true) {
    const ans = (await prompt(rl, '\nField to edit (name or number 1–7), s=save, l=list, q=quit: ')).trim().toLowerCase();
    if (ans === 'q') return false;
    if (ans === 'l') { printList(); continue; }
    if (ans === 's') return true;

    let f = EDITABLE_FIELDS.find(x => x.key === ans);
    if (!f) {
      const n = parseInt(ans, 10);
      if (!isNaN(n) && n >= 1 && n <= EDITABLE_FIELDS.length) f = EDITABLE_FIELDS[n - 1];
    }
    if (!f) {
      console.log(`Unknown field "${ans}". Available: ${EDITABLE_FIELDS.map(x => x.key).join(', ')}`);
      continue;
    }

    const cur = fmtField(f, e.stats[f.key]);
    const raw = (await prompt(rl, `  ${f.label} [current: ${cur}, range ${f.min}–${f.max}]: `)).trim();
    if (!raw) continue;

    const result = parseFieldValue(f, raw);
    if (result.error) { console.log(`  Error: ${result.error}`); continue; }

    e.stats[f.key] = result.value;
    console.log(`  ${f.key} set to ${fmtField(f, result.value)}`);
    printEnemy(idx, e);
  }
}

// ---------------------------------------------------------------------------
// Save + inject
// ---------------------------------------------------------------------------

async function saveAndInject() {
  if (DRY_RUN) {
    console.log('\n[DRY RUN] Would write:', ENEMIES_JSON);
    console.log('[DRY RUN] Would run: node tools/inject_game_data.js --enemies');
    return;
  }

  console.log('\nWriting', ENEMIES_JSON, '...');
  const original = JSON.parse(fs.readFileSync(ENEMIES_JSON, 'utf8'));
  original.enemies = enemies;
  fs.writeFileSync(ENEMIES_JSON, JSON.stringify(original, null, 2) + '\n');
  console.log('Saved.');

  if (NO_REBUILD) {
    console.log('--no-rebuild: skipping inject + verify.');
    return;
  }

  console.log('\nInjecting into ASM sources...');
  try {
    execSync(`node "${INJECT_SCRIPT}" --enemies`, { cwd: ROOT, stdio: 'inherit' });
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

async function main() {
  // Non-interactive path: --enemy + optional --set
  if (enemyArg !== null) {
    const idx = findEnemy(enemyArg);
    if (idx < 0) {
      console.error(`No enemy matching "${enemyArg}"`);
      process.exit(1);
    }
    if (Object.keys(setArgs).length > 0) {
      await applyNonInteractive(idx);
      return;
    }
    // --enemy only: drop into interactive edit for that enemy
    const rl = createRl();
    const save = await editEnemy(rl, idx);
    rl.close();
    if (save) await saveAndInject();
    return;
  }

  // Fully interactive path
  const rl = createRl();
  let keepGoing = true;

  while (keepGoing) {
    const idx = await selectEnemy(rl);
    if (idx < 0) { keepGoing = false; break; }
    const save = await editEnemy(rl, idx);
    if (save) {
      await saveAndInject();
      // After saving, ask if user wants to edit another
      const again = (await prompt(rl, '\nEdit another enemy? (y/n): ')).trim().toLowerCase();
      keepGoing = (again === 'y');
    }
  }

  rl.close();
  console.log('Done.');
}

main().catch(err => { console.error(err); process.exit(1); });
