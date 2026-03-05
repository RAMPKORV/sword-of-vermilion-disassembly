#!/usr/bin/env node
// tools/editor/stats_editor.js
// Sword of Vermilion — Player Stat Curve Editor
//
// Interactive CLI for viewing and editing level-up stat gains in
// tools/data/player_stats.json.  Changes are written back to JSON and injected
// into the ASM source via inject_game_data.js --player-stats.
//
// Usage:
//   node tools/editor/stats_editor.js [options]
//   node tools/editor/stats_editor.js --level <1-31>
//
// Options:
//   --table             Print the full stat table and exit
//   --graph <field>     Print ASCII bar chart for a stat field across levels
//   --level <n>         Jump directly to level n for editing
//   --scale <field> <m> Multiply all values of <field> by <m> (non-interactive)
//   --no-rebuild        Skip inject + verify.bat after saving
//   --dry-run           Show changes without writing
//   --json              Dump player_stats JSON and exit
//   --help              Show this help

'use strict';

const fs       = require('fs');
const path     = require('path');
const readline = require('readline');
const { execSync } = require('child_process');

// ---------------------------------------------------------------------------
// Paths
// ---------------------------------------------------------------------------

const ROOT           = path.join(__dirname, '..', '..');
const STATS_JSON     = path.join(ROOT, 'tools', 'data', 'player_stats.json');
const INJECT_SCRIPT  = path.join(ROOT, 'tools', 'inject_game_data.js');

// ---------------------------------------------------------------------------
// Field definitions
// ---------------------------------------------------------------------------

const STAT_FIELDS = [
  { key: 'mhp_gain', label: 'MHP gain', min: 0, max: 255 },
  { key: 'mmp_gain', label: 'MMP gain', min: 0, max: 255 },
  { key: 'str_gain', label: 'STR gain', min: 0, max: 255 },
  { key: 'ac_gain',  label: 'AC gain',  min: 0, max: 255 },
  { key: 'int_gain', label: 'INT gain', min: 0, max: 255 },
  { key: 'dex_gain', label: 'DEX gain', min: 0, max: 255 },
  { key: 'luk_gain', label: 'LUK gain', min: 0, max: 255 },
  { key: 'xp_to_next', label: 'XP to next', min: 1, max: 65535 },
];

const STAT_KEYS = STAT_FIELDS.map(f => f.key);

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

const args       = process.argv.slice(2);
const HELP       = args.includes('--help');
const DO_TABLE   = args.includes('--table');
const DO_JSON    = args.includes('--json');
const DRY_RUN    = args.includes('--dry-run');
const NO_REBUILD = args.includes('--no-rebuild');

function getArg(flag, def) {
  const i = args.indexOf(flag);
  return i >= 0 && args[i + 1] !== undefined ? args[i + 1] : def;
}

if (HELP) {
  console.log([
    'Usage: node tools/editor/stats_editor.js [options]',
    '',
    'Options:',
    '  --table             Print full 31-level stat table and exit',
    '  --graph <field>     ASCII bar chart for one stat field',
    '  --level <n>         Jump to level n (1-31) for editing',
    '  --scale <field> <m> Multiply all values of field by m (e.g. --scale mhp_gain 1.5)',
    '  --no-rebuild        Skip inject + verify.bat',
    '  --dry-run           Show changes without writing',
    '  --json              Dump player_stats JSON and exit',
    '  --help              Show this help',
    '',
    'Stat fields: ' + STAT_FIELDS.map(f => f.key).join(', '),
  ].join('\n'));
  process.exit(0);
}

// ---------------------------------------------------------------------------
// Load data
// ---------------------------------------------------------------------------

if (!fs.existsSync(STATS_JSON)) {
  console.error(`Error: ${STATS_JSON} not found. Run tools/extract_game_data.js first.`);
  process.exit(1);
}

const rawData  = JSON.parse(fs.readFileSync(STATS_JSON, 'utf8'));
const levelUps = rawData.level_ups; // array of 31

if (DO_JSON) {
  console.log(JSON.stringify(rawData, null, 2));
  process.exit(0);
}

// ---------------------------------------------------------------------------
// Display helpers
// ---------------------------------------------------------------------------

function pad(s, n) { return String(s).padEnd(n); }
function lpad(s, n) { return String(s).padStart(n); }

function printTable() {
  const header = ['Lvl', 'MHP', 'MMP', 'STR', 'AC', 'INT', 'DEX', 'LUK', 'XP_Next'];
  console.log(header.map((h, i) => lpad(h, i === 0 ? 3 : i === 8 ? 7 : 4)).join(' '));
  console.log('─'.repeat(50));
  for (const lu of levelUps) {
    const row = [
      lpad(lu.level, 3),
      lpad(lu.mhp_gain, 4),
      lpad(lu.mmp_gain, 4),
      lpad(lu.str_gain, 4),
      lpad(lu.ac_gain, 4),
      lpad(lu.int_gain, 4),
      lpad(lu.dex_gain, 4),
      lpad(lu.luk_gain, 4),
      lpad(lu.xp_to_next, 7),
    ];
    console.log(row.join(' '));
  }
}

function printGraph(fieldKey) {
  const f = STAT_FIELDS.find(x => x.key === fieldKey);
  if (!f) { console.error(`Unknown field: ${fieldKey}`); process.exit(1); }

  const vals = levelUps.map(lu => lu[fieldKey]);
  const maxV = Math.max(...vals) || 1;
  const BAR_WIDTH = 40;

  console.log(`\n${f.label} across levels 1–${levelUps.length}`);
  console.log('─'.repeat(BAR_WIDTH + 12));
  for (let i = 0; i < levelUps.length; i++) {
    const v    = vals[i];
    const bars = Math.round((v / maxV) * BAR_WIDTH);
    const bar  = '█'.repeat(bars);
    console.log(`Lv${lpad(i + 1, 2)} ${lpad(v, 5)} │${bar}`);
  }
  console.log('─'.repeat(BAR_WIDTH + 12));

  // Cumulative total
  const cumulative = vals.reduce((a, v) => a + v, 0);
  console.log(`Cumulative total: ${cumulative}   Max single gain: ${maxV}`);
}

function printLevel(idx) {
  const lu = levelUps[idx];
  console.log(`\n[Level ${lu.level}]`);
  console.log('  ' + '─'.repeat(40));
  for (const f of STAT_FIELDS) {
    console.log(`  ${pad(f.key, 14)} ${lpad(lu[f.key], 6)}   (${f.label}, ${f.min}–${f.max})`);
  }
  console.log('  ' + '─'.repeat(40));
}

// ---------------------------------------------------------------------------
// Non-interactive: --table or --graph
// ---------------------------------------------------------------------------

if (DO_TABLE) { printTable(); process.exit(0); }

const graphArg = getArg('--graph', null);
if (graphArg !== null) { printGraph(graphArg); process.exit(0); }

// ---------------------------------------------------------------------------
// Non-interactive: --scale <field> <multiplier>
// ---------------------------------------------------------------------------

const scaleFieldArg = getArg('--scale', null);
if (scaleFieldArg !== null) {
  const idx  = args.indexOf('--scale');
  const mult = idx >= 0 && args[idx + 2] !== undefined ? parseFloat(args[idx + 2]) : NaN;

  const f = STAT_FIELDS.find(x => x.key === scaleFieldArg);
  if (!f) { console.error(`Unknown field: ${scaleFieldArg}`); process.exit(1); }
  if (isNaN(mult) || mult <= 0) { console.error('Invalid multiplier. Example: --scale mhp_gain 1.5'); process.exit(1); }

  console.log(`Scaling ${f.key} by ${mult}x...`);
  for (const lu of levelUps) {
    const old = lu[f.key];
    const nv  = Math.max(f.min, Math.min(f.max, Math.round(old * mult)));
    if (!DRY_RUN) lu[f.key] = nv;
    if (old !== nv) console.log(`  Lv${lu.level}: ${old} → ${nv}`);
  }

  if (!DRY_RUN) {
    saveAndInject(true);
  } else {
    console.log('[DRY RUN] No files written.');
  }
  process.exit(0);
}

// ---------------------------------------------------------------------------
// Save + inject
// ---------------------------------------------------------------------------

function saveAndInject(sync) {
  if (DRY_RUN) {
    console.log('\n[DRY RUN] Would write:', STATS_JSON);
    console.log('[DRY RUN] Would run: node tools/inject_game_data.js --player-stats');
    return;
  }

  console.log('\nWriting', STATS_JSON, '...');
  fs.writeFileSync(STATS_JSON, JSON.stringify(rawData, null, 2) + '\n');
  console.log('Saved.');

  if (NO_REBUILD) {
    console.log('--no-rebuild: skipping inject + verify.');
    return;
  }

  console.log('\nInjecting into ASM sources...');
  try {
    execSync(`node "${INJECT_SCRIPT}" --player-stats`, { cwd: ROOT, stdio: 'inherit' });
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
// Interactive RL helpers
// ---------------------------------------------------------------------------

function createRl() {
  return readline.createInterface({ input: process.stdin, output: process.stdout });
}
async function prompt(rl, q) {
  return new Promise(resolve => rl.question(q, resolve));
}

// ---------------------------------------------------------------------------
// Interactive: edit one level
// ---------------------------------------------------------------------------

async function editLevel(rl, lvlIdx) {
  const lu = levelUps[lvlIdx];
  printLevel(lvlIdx);

  let changed = false;
  while (true) {
    const ans = (await prompt(rl, '\nField to edit (name or 1–8), s=save, g=graph, q=quit: ')).trim().toLowerCase();
    if (ans === 'q') break;
    if (ans === 's') { changed = true; break; }
    if (ans === 'g') {
      const gf = (await prompt(rl, 'Graph which field? ')).trim();
      printGraph(gf);
      continue;
    }

    let f = STAT_FIELDS.find(x => x.key === ans);
    if (!f) {
      const n = parseInt(ans, 10);
      if (!isNaN(n) && n >= 1 && n <= STAT_FIELDS.length) f = STAT_FIELDS[n - 1];
    }
    if (!f) {
      console.log(`Unknown field. Options: ${STAT_KEYS.join(', ')}`);
      continue;
    }

    const cur = lu[f.key];
    const raw = (await prompt(rl, `  ${f.label} [current: ${cur}, range ${f.min}–${f.max}]: `)).trim();
    if (!raw) continue;

    const nv = parseInt(raw, 10);
    if (isNaN(nv)) { console.log('  Not a number.'); continue; }
    if (nv < f.min || nv > f.max) { console.log(`  Out of range [${f.min}–${f.max}].`); continue; }
    lu[f.key] = nv;
    console.log(`  ${f.key}: ${cur} → ${nv}`);
    printLevel(lvlIdx);
  }
  return changed;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const levelArg = getArg('--level', null);

async function main() {
  const rl = createRl();
  let keepGoing = true;

  while (keepGoing) {
    let lvlIdx;

    if (levelArg && keepGoing === true) {
      const n = parseInt(levelArg, 10);
      if (isNaN(n) || n < 1 || n > levelUps.length) {
        console.error(`Invalid level "${levelArg}". Use 1–${levelUps.length}.`);
        rl.close(); process.exit(1);
      }
      lvlIdx = n - 1;
    } else {
      printTable();
      const ans = (await prompt(rl, `\nLevel to edit (1–${levelUps.length}), g=graph, q=quit: `)).trim().toLowerCase();
      if (ans === 'q') break;
      if (ans === 'g') {
        const gf = (await prompt(rl, 'Graph which field? ')).trim();
        printGraph(gf);
        continue;
      }
      const n = parseInt(ans, 10);
      if (isNaN(n) || n < 1 || n > levelUps.length) { console.log('Invalid level.'); continue; }
      lvlIdx = n - 1;
    }

    const changed = await editLevel(rl, lvlIdx);
    levelArg && (keepGoing = false); // reset after first if --level given

    if (changed) {
      const confirm = (await prompt(rl, '\nSave changes? (y/n): ')).trim().toLowerCase();
      if (confirm === 'y') saveAndInject();
    }

    if (keepGoing) {
      const again = (await prompt(rl, 'Edit another level? (y/n): ')).trim().toLowerCase();
      keepGoing = (again === 'y');
    }
  }

  rl.close();
  console.log('Done.');
}

main().catch(err => { console.error(err); process.exit(1); });
