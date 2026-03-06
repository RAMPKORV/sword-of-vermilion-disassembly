#!/usr/bin/env node
// tools/index/callsites.js
//
// Reads vermilion.lst and records every JSR / BSR call site for a configurable
// set of target functions.  Emits tools/index/callsites.json.
//
// Useful for:
//   - Documenting call graphs before refactoring
//   - Finding all callers of a utility before renaming it
//   - Verifying that a function is called the expected number of times
//
// Usage:
//   node tools/index/callsites.js [--lst <path>] [--out <path>] [--target <name>] ...
//
// Defaults:
//   --lst  vermilion.lst                (relative to repo root)
//   --out  tools/index/callsites.json
//
// Target functions: the built-in list covers the most-called utilities.
// Pass one or more --target <name> flags to add extra targets (they are merged
// with the built-in list).  Pass --only to suppress the built-in list entirely
// and use only the --target flags.
//
// Output format:
//   {
//     "_meta": { "generated_by": "...", "lst": "...", "target_count": N },
//     "callsites": {
//       "WaitForVBlank": [
//         { "caller_address": "0x0001096", "insn": "BSR.w", "source_context": "..." },
//         ...
//       ],
//       ...
//     }
//   }

'use strict';

const fs   = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Built-in high-value target list
// ---------------------------------------------------------------------------

const BUILTIN_TARGETS = new Set([
  // Core timing / interrupts
  'WaitForVBlank',

  // Input
  'CheckButtonPress',
  'ReadJoypad',
  'ReadJoypads',

  // Audio
  'QueueSoundEffect',
  'QueueMusic',
  'StopMusic',

  // VDP / DMA
  'ExecuteVdpDmaFromRam',
  'VDP_DMAFill',
  'InitVDP',
  'DisableVDPDisplay',
  'EnableVDPDisplay',
  'ClearVRAMPlaneA',
  'ClearVRAMPlaneB',
  'ClearVRAMSprites',

  // Graphics
  'DecompressTileGraphics',
  'LoadPalettesFromTable',
  'LoadMultipleTilesFromTable',
  'AddSpriteToDisplayList',

  // Text / dialogue
  'CopyStringUntilFF',
  'RenderTextToWindow',
  'ProcessScriptText',
  'ResetScriptAndInitDialogue',
  'DrawMenuCursor',
  'HandleMenuInput',
  'DrawLeftMenuWindow',
  'DrawStatusHudWindow',
  'DrawWindowBorder',
  'ReadWindowToBuffer',

  // Math / RNG
  'GetRandomNumber',
  'ConvertToBCD',
  'CalculateAngleBetweenObjects',

  // Map / world
  'ValidateDungeonTileType',
  'LoadMapTileGfxIndex',

  // Combat / enemy
  'HandlePlayerTakeDamage',
  'SetRandomDirection',
  'CheckObjectOnScreen',

  // Inventory
  'RemoveSelectedItemFromList',

  // Misc utilities
  'SaveStatusBarToBuffer',
  'SetHintTextIfTriggered',
]);

// ---------------------------------------------------------------------------
// Argument parsing
// ---------------------------------------------------------------------------

const args = process.argv.slice(2);
function getArg(flag, def) {
  const i = args.indexOf(flag);
  return i !== -1 ? args[i + 1] : def;
}
function getAllArgs(flag) {
  const result = [];
  for (let i = 0; i < args.length; i++) {
    if (args[i] === flag && args[i + 1]) result.push(args[i + 1]);
  }
  return result;
}

const ROOT    = path.resolve(__dirname, '..', '..');
const lstPath = path.resolve(ROOT, getArg('--lst', 'vermilion.lst'));
const outPath = path.resolve(ROOT, getArg('--out', 'tools/index/callsites.json'));
const onlyFlag = args.includes('--only');

if (!fs.existsSync(lstPath)) {
  console.error(`ERROR: listing file not found: ${lstPath}`);
  console.error('Run build.bat first to generate vermilion.lst');
  process.exit(1);
}

// Build final target set
const targets = onlyFlag ? new Set() : new Set(BUILTIN_TARGETS);
for (const t of getAllArgs('--target')) targets.add(t);

if (targets.size === 0) {
  console.error('ERROR: no targets specified (built-in list is empty and no --target given)');
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Parse listing file
// ---------------------------------------------------------------------------
// Listing line format (real instructions have a non-zero ROM address):
//   00001096 6100 0000                  \tBSR.w\tWaitForVBlank\t\t\t; wait for next VBlank
//   00000270 4EB9 0000 0000             \tJSR\tUpgradeLevelStats
//
// Label-definition lines (for surrounding context):
//   0000104A                            FunctionName:
//
// The address field is 8 hex digits at the very start of the line.

// Regex: address  [bytes]  instruction   target  [comment]
const CALL_RE = /^([0-9A-Fa-f]{8})\s+[0-9A-Fa-f ]+\s+(JSR|BSR\S*)\s+([A-Za-z_][A-Za-z0-9_.]*)/;
const LABEL_RE = /^([0-9A-Fa-f]{8})\s+([A-Za-z_][A-Za-z0-9_]*):\s*(?:;.*)?$/;

// Initialize results
const callsites = {};
for (const t of targets) callsites[t] = [];

const lines = fs.readFileSync(lstPath, 'utf8').split('\n');

// Keep a small rolling window of nearby label definitions to provide context
let lastLabel = null;

for (const rawLine of lines) {
  const line = rawLine.replace(/\r$/, '');

  // Track nearest label for context
  const lm = LABEL_RE.exec(line);
  if (lm) lastLabel = lm[2];

  const m = CALL_RE.exec(line);
  if (!m) continue;

  const callerAddr = '0x' + m[1].toUpperCase();
  const insn       = m[2];          // 'JSR' or 'BSR.w' etc.
  const target     = m[3];          // callee name

  if (!targets.has(target)) continue;

  // Source context: trim the instruction line down to something readable
  const sourceContext = line.replace(/\s+/g, ' ').trim();

  callsites[target].push({
    caller_address:  callerAddr,
    insn,
    enclosing_label: lastLabel || null,
    source_context:  sourceContext,
  });
}

// ---------------------------------------------------------------------------
// Summary stats
// ---------------------------------------------------------------------------

const summary = {};
let totalCallsites = 0;
for (const [name, sites] of Object.entries(callsites)) {
  summary[name] = sites.length;
  totalCallsites += sites.length;
}

// Sort callsites by address within each target
for (const sites of Object.values(callsites)) {
  sites.sort((a, b) => parseInt(a.caller_address, 16) - parseInt(b.caller_address, 16));
}

// Sort summary by call count (descending) for the top-level view
const sortedSummary = Object.fromEntries(
  Object.entries(summary).sort((a, b) => b[1] - a[1])
);

// ---------------------------------------------------------------------------
// Write output
// ---------------------------------------------------------------------------

const output = {
  _meta: {
    generated_by: 'tools/index/callsites.js',
    lst: path.relative(ROOT, lstPath),
    target_count: targets.size,
    total_callsites: totalCallsites,
  },
  summary: sortedSummary,
  callsites,
};

fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(output, null, 2) + '\n');

console.log(`callsites.js: ${totalCallsites} call sites across ${targets.size} targets`);
console.log(`  written to ${path.relative(ROOT, outPath)}`);
console.log();
console.log('Top callee targets:');
Object.entries(sortedSummary)
  .filter(([, v]) => v > 0)
  .slice(0, 15)
  .forEach(([k, v]) => console.log(`  ${String(v).padStart(4)}  ${k}`));
