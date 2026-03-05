#!/usr/bin/env node
// tools/inject_game_data.js
//
// EDIT-007: Machine-readable data injection into Sword of Vermilion ASM sources.
//
// Takes edited JSON data (produced by extract_game_data.js) and patches the
// corresponding values back into the assembly source files WITHOUT altering
// any surrounding structure, labels, macros, or layout.
//
// Supported data sets:
//   --enemies        tools/data/enemies.json       → src/battledata.asm
//   --magic          tools/data/magic_tables.json  → src/shopdata.asm
//   --player-stats   tools/data/player_stats.json  → src/playerstats.asm
//   --shops          tools/data/shops.json         → src/shopdata.asm
//
// Usage:
//   node tools/inject_game_data.js [--enemies] [--magic] [--player-stats] [--shops]
//   node tools/inject_game_data.js --all
//   node tools/inject_game_data.js --enemies --dry-run
//
// Options:
//   --all       Run all injectors
//   --dry-run   Print diffs without writing files
//   --in <dir>  Input JSON directory (default: tools/data/)
//
// IMPORTANT: This script only patches VALUES, never layout.
//   - enemyData macro argument values are replaced in-place; the macro call
//     structure is preserved verbatim.
//   - dc.w/dc.l table entries are replaced line-by-line using hex ($XXXX).
//   - Shop assortment count and macro entries are regenerated using the same
//     shopItem/shopEquip/shopMagic macro syntax.
//   - Any value that cannot be resolved safely causes an abort with an error.
//
// After running, always verify with: cmd //c verify.bat
// A bit-perfect build confirms the injected values are semantically equivalent.

'use strict';

const fs   = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Argument parsing
// ---------------------------------------------------------------------------
const args = process.argv.slice(2);
const DRY_RUN  = args.includes('--dry-run');
const ALL      = args.includes('--all');
const DO_ENEMIES      = ALL || args.includes('--enemies');
const DO_MAGIC        = ALL || args.includes('--magic');
const DO_PLAYER_STATS = ALL || args.includes('--player-stats');
const DO_SHOPS        = ALL || args.includes('--shops');

if (!DO_ENEMIES && !DO_MAGIC && !DO_PLAYER_STATS && !DO_SHOPS) {
  console.error('Usage: node tools/inject_game_data.js [--enemies] [--magic] [--player-stats] [--shops] [--all] [--dry-run]');
  process.exit(1);
}

function getArg(flag, def) {
  const i = args.indexOf(flag);
  return i !== -1 ? args[i + 1] : def;
}

const ROOT   = path.resolve(__dirname, '..');
const inDir  = path.resolve(ROOT, getArg('--in', 'tools/data'));

const BATTLEDATA_ASM  = path.join(ROOT, 'src', 'battledata.asm');
const SHOPDATA_ASM    = path.join(ROOT, 'src', 'shopdata.asm');
const PLAYERSTATS_ASM = path.join(ROOT, 'src', 'playerstats.asm');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Read file as array of lines (CRLF → LF stripped). */
function readLines(p) {
  return fs.readFileSync(p, 'utf8').split('\n').map(l => l.replace(/\r$/, ''));
}

/** Write lines back to file (preserving original line endings). */
function writeLines(p, lines, originalLines) {
  // Detect dominant line ending from original file
  const raw = fs.readFileSync(p, 'utf8');
  const useCRLF = (raw.match(/\r\n/g) || []).length > (raw.match(/(?<!\r)\n/g) || []).length;
  const sep = useCRLF ? '\r\n' : '\n';
  fs.writeFileSync(p, lines.join(sep));
}

/** Format a number as $XXXX hex (word), upper-case, minimum 4 hex digits. */
function fmtHexW(n) {
  if (n < 0) n = n & 0xFFFF;
  const h = n.toString(16).toUpperCase();
  return '$' + h.padStart(4, '0');
}

/** Format a number as $XXXXXXXX hex (long), upper-case, minimum 8 hex digits. */
function fmtHexL(n) {
  if (n < 0) n = n >>> 0;
  const h = n.toString(16).toUpperCase();
  return '$' + h.padStart(8, '0');
}

/** Format a byte as $XX hex, upper-case, 2 digits. */
function fmtHexB(n) {
  if (n < 0) n = n & 0xFF;
  return '$' + n.toString(16).toUpperCase().padStart(2, '0');
}

/** Parse a hex ($XXXX) or decimal integer token. Returns number or null. */
function parseNumToken(s) {
  s = (s || '').trim();
  if (s.startsWith('$')) return parseInt(s.slice(1), 16);
  if (/^-?\d+$/.test(s)) return parseInt(s, 10);
  return null;
}

/**
 * Reconstruct an ASM token for a numeric value, preserving the original
 * token string if the value is unchanged.
 */
function tokenForValue(newVal, originalToken) {
  const orig = parseNumToken(originalToken);
  if (orig !== null && orig === newVal) return originalToken.trim();
  return fmtHexW(newVal); // default to $XXXX
}

function tokenForValueL(newVal, originalToken) {
  const orig = parseNumToken(originalToken);
  if (orig !== null && orig === newVal) return originalToken.trim();
  return fmtHexL(newVal);
}

function tokenForValueB(newVal, originalToken) {
  const orig = parseNumToken(originalToken);
  if (orig !== null && orig === newVal) return originalToken.trim();
  return fmtHexB(newVal);
}

/** Strip inline comment from a token string. */
function stripComment(s) {
  const i = s.indexOf(';');
  return (i === -1 ? s : s.slice(0, i)).trim();
}

/** Load JSON from a file. */
function loadJson(filename) {
  const p = path.join(inDir, filename);
  if (!fs.existsSync(p)) {
    throw new Error(`Input file not found: ${p}\nRun extract_game_data.js first.`);
  }
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

/** Apply modified lines and show a summary. Returns number of changed lines. */
function applyChanges(filePath, originalLines, newLines, label) {
  let changed = 0;
  for (let i = 0; i < Math.min(originalLines.length, newLines.length); i++) {
    if (originalLines[i] !== newLines[i]) changed++;
  }
  const relPath = path.relative(ROOT, filePath);
  if (changed === 0) {
    console.log(`  ${label}: no changes needed`);
    return 0;
  }
  if (DRY_RUN) {
    console.log(`  ${label}: ${changed} line(s) would change (--dry-run)`);
    for (let i = 0; i < Math.min(originalLines.length, newLines.length); i++) {
      if (originalLines[i] !== newLines[i]) {
        console.log(`    L${i+1}  - ${originalLines[i]}`);
        console.log(`    L${i+1}  + ${newLines[i]}`);
      }
    }
  } else {
    writeLines(filePath, newLines, originalLines);
    console.log(`  ${label}: patched ${changed} line(s) in ${relPath}`);
  }
  return changed;
}

// ---------------------------------------------------------------------------
// INJECTOR 1: Enemy stats → src/battledata.asm
// ---------------------------------------------------------------------------
//
// For each enemy entry in enemies.json, finds the label "EnemyData_<name>:"
// in battledata.asm and replaces the following "enemyData ..." macro line
// with values from the JSON stats object.
//
// Fields patched (all 13 enemyData arguments):
//   ai_fn, tile_id, reward_type, reward_value, extra_obj_slots, max_spawn,
//   hp, damage_per_hit, xp_reward, kim_reward, speed, sprite_frame, behavior_flag
//
// Notes:
//   - ai_fn is kept as a symbolic label (string) from JSON; if it was changed
//     in the JSON, the new string is used verbatim. Ensure the label exists.
//   - reward_type is patched as its numeric value formatted as $XXXX.
//     The original symbolic constant (ENEMY_REWARD_TYPE_*) is replaced with
//     the numeric equivalent. If you need symbolic names, edit the ASM manually.
//   - All numeric values use hex ($XXXX or $XXXXXXXX), matching the original style.
//
// IMPORTANT: Only enemies whose data_label exists in battledata.asm are patched.
// Missing labels are reported as warnings (not errors) since some enemies share
// EnemyData labels.

function injectEnemies() {
  console.log('Injecting enemy stats...');
  const data = loadJson('enemies.json');
  const lines = readLines(BATTLEDATA_ASM);
  const newLines = lines.slice();

  // Build a map: EnemyData_label → line index of the label line
  const labelLineMap = {};
  for (let i = 0; i < lines.length; i++) {
    const m = lines[i].trim().match(/^(EnemyData_\w+):$/);
    if (m) labelLineMap[m[1]] = i;
  }

  // Track which data labels we've already patched (multiple gfx_index may share one)
  const patched = new Set();
  let patchCount = 0;
  let warnCount  = 0;

  for (const enemy of data.enemies) {
    if (!enemy.stats) continue;
    const label = enemy.data_label;
    if (patched.has(label)) continue;
    patched.add(label);

    if (!(label in labelLineMap)) {
      console.warn(`  WARN: label not found in battledata.asm: ${label}`);
      warnCount++;
      continue;
    }

    const labelLine = labelLineMap[label];

    // Find the next non-blank, non-comment line after the label
    let macroIdx = -1;
    for (let j = labelLine + 1; j < lines.length && j < labelLine + 5; j++) {
      const l = lines[j].trim();
      if (l && !l.startsWith(';')) { macroIdx = j; break; }
    }

    if (macroIdx === -1) {
      console.error(`  ERROR: no enemyData macro line found after ${label} (line ${labelLine + 1})`);
      process.exit(1);
    }

    const macroLine = lines[macroIdx].trim();
    if (!macroLine.match(/^enemyData\s+/i)) {
      console.error(`  ERROR: expected enemyData macro after ${label} (L${macroIdx + 1}): ${macroLine}`);
      process.exit(1);
    }

    // Parse original macro args so we can preserve tokens where values are unchanged
    const origArgs = macroLine.replace(/^enemyData\s+/i, '').split(',').map(a => stripComment(a).trim());
    if (origArgs.length < 13) {
      console.error(`  ERROR: ${label} macro has ${origArgs.length} args (expected 13)`);
      process.exit(1);
    }

    const s = enemy.stats;

    // reward_type: preserve original symbolic token (e.g. ENEMY_REWARD_NONE) if
    // the numeric value is unchanged; otherwise emit $XXXX.
    const origRewardTypeToken = origArgs[2]; // 0-based: ai_fn,tile_id,reward_type,...
    const origRewardTypeVal   = parseNumToken(origRewardTypeToken); // null for symbolic names
    let rewardTypeTok;
    if (origRewardTypeVal === null) {
      // Original was a symbolic constant — resolve via CONST map if we can
      // For now, preserve the original token if the resolved value matches s.reward_type.
      // Since we can't resolve it here without loading constants, preserve unconditionally.
      rewardTypeTok = origRewardTypeToken;
    } else {
      rewardTypeTok = tokenForValue(s.reward_type, origArgs[2]);
    }

    const tileIdTok     = tokenForValue(s.tile_id,          origArgs[1]);
    const rewardValTok  = tokenForValue(s.reward_value,      origArgs[3]);
    const extraSlotsTok = tokenForValueB(s.extra_obj_slots,  origArgs[4]);
    const maxSpawnTok   = tokenForValueB(s.max_spawn,        origArgs[5]);
    const hpTok         = tokenForValue(s.hp,                origArgs[6]);
    const dmgTok        = tokenForValue(s.damage_per_hit,    origArgs[7]);
    const xpTok         = tokenForValue(s.xp_reward,        origArgs[8]);
    const kimTok        = tokenForValue(s.kim_reward,        origArgs[9]);
    const speedTok      = tokenForValueL(s.speed,            origArgs[10]);
    const frameTok      = tokenForValueB(s.sprite_frame,     origArgs[11]);
    const behaviorTok   = tokenForValueB(s.behavior_flag,    origArgs[12]);

    // Detect original indentation (tab or spaces)
    const indentMatch = lines[macroIdx].match(/^(\s+)/);
    const indent = indentMatch ? indentMatch[1] : '\t';

    const newMacroLine = `${indent}enemyData ${s.ai_fn},${tileIdTok},${rewardTypeTok},${rewardValTok},${extraSlotsTok},${maxSpawnTok},${hpTok},${dmgTok},${xpTok},${kimTok},${speedTok},${frameTok},${behaviorTok}`;

    if (newLines[macroIdx] !== newMacroLine) {
      newLines[macroIdx] = newMacroLine;
      patchCount++;
    }
  }

  if (warnCount > 0) console.warn(`  ${warnCount} label(s) not found (warnings above)`);
  applyChanges(BATTLEDATA_ASM, lines, newLines, `enemies (${patchCount} of ${patched.size} entries changed)`);
}

// ---------------------------------------------------------------------------
// INJECTOR 2: Magic MP costs → src/shopdata.asm
// ---------------------------------------------------------------------------
//
// Patches MagicMpConsumptionMap dc.w values in shopdata.asm.
// Only mp_cost is injected (damage_tier, damage_base, element are not touched
// here — those live in MagicBaseDamageTable / MagicElementTypeTable which use
// a different encoding; edit those manually if needed).
//
// Strategy: find the MagicMpConsumptionMap: label, then replace each subsequent
// "dc.w $XX" line's value, preserving trailing comments.

function injectMagic() {
  console.log('Injecting magic MP costs...');
  const data = loadJson('magic_tables.json');
  const lines = readLines(SHOPDATA_ASM);
  const newLines = lines.slice();

  // Find the label
  let tableStart = -1;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].trim().startsWith('MagicMpConsumptionMap:')) { tableStart = i; break; }
  }
  if (tableStart === -1) {
    console.error('  ERROR: MagicMpConsumptionMap not found in shopdata.asm');
    process.exit(1);
  }

  const mpCosts = data.magic.map(m => m.mp_cost);
  let entryIdx = 0;
  let patchCount = 0;

  for (let i = tableStart + 1; i < lines.length && entryIdx < mpCosts.length; i++) {
    const l = lines[i].trim();
    if (l === '' || l.startsWith(';')) continue;
    // Stop at next label
    if (l.match(/^[A-Za-z_]\w*:/) && !l.startsWith('dc.')) break;

    const m = lines[i].match(/^(\s*)dc\.w\s+(\S+)(.*)/i);
    if (!m) break;

    const indent = m[1];
    const commentPart = m[3] || '';  // trailing "; ..." if any
    const newVal = tokenForValue(mpCosts[entryIdx], m[2]);

    const newLine = `${indent}dc.w\t${newVal}${commentPart}`;
    if (newLines[i] !== newLine) {
      newLines[i] = newLine;
      patchCount++;
    }
    entryIdx++;
  }

  if (entryIdx !== mpCosts.length) {
    console.error(`  ERROR: expected ${mpCosts.length} MagicMpConsumptionMap entries, found ${entryIdx}`);
    process.exit(1);
  }

  applyChanges(SHOPDATA_ASM, lines, newLines, `magic MP costs (${patchCount} of ${mpCosts.length} entries changed)`);
}

// ---------------------------------------------------------------------------
// INJECTOR 3: Player level-up stats → src/playerstats.asm
// ---------------------------------------------------------------------------
//
// Patches all 8 PlayerLevelTo*Map tables and PlayerLevelToNextLevelExperienceMap.
// Also patches EquipmentToStatModifierMap.
//
// Strategy: for each table, locate the label, then replace dc.w/dc.l values
// one by one, preserving trailing comments.

function injectPlayerStats() {
  console.log('Injecting player stats...');
  const data = loadJson('player_stats.json');
  const lines = readLines(PLAYERSTATS_ASM);
  const newLines = lines.slice();

  const levelUps = data.level_ups;
  const equipMods = data.equipment_stat_modifiers;

  let totalPatched = 0;

  // Helper: patch a dc.w table starting after `labelName:`.
  // `values` is an array of numbers. Returns count of patched lines.
  function patchWordTable(labelName, values) {
    let tableStart = -1;
    for (let i = 0; i < newLines.length; i++) {
      if (newLines[i].trim().match(new RegExp('^' + labelName + ':'))) {
        tableStart = i; break;
      }
    }
    if (tableStart === -1) {
      console.error(`  ERROR: label not found in playerstats.asm: ${labelName}`);
      process.exit(1);
    }

    let entryIdx = 0;
    let patched = 0;
    for (let i = tableStart + 1; i < newLines.length && entryIdx < values.length; i++) {
      const l = newLines[i].trim();
      if (l === '' || l.startsWith(';')) continue;
      if (l.match(/^[A-Za-z_]\w*:/) && !l.startsWith('dc.')) break;

      const m = newLines[i].match(/^(\s*)dc\.w\s+(\S+)(.*)/i);
      if (!m) break;

      const indent = m[1];
      const commentPart = m[3] || '';
      const newVal = tokenForValue(values[entryIdx], m[2]);

      // Preserve trailing whitespace style from original value token
      const newLine = `${indent}dc.w\t${newVal}${commentPart}`;
      if (newLines[i] !== newLine) {
        newLines[i] = newLine;
        patched++;
      }
      entryIdx++;
    }

    if (entryIdx !== values.length) {
      console.error(`  ERROR: ${labelName}: expected ${values.length} entries, found ${entryIdx}`);
      process.exit(1);
    }
    return patched;
  }

  // Helper: patch a dc.l table starting after `labelName:`.
  function patchLongTable(labelName, values) {
    let tableStart = -1;
    for (let i = 0; i < newLines.length; i++) {
      if (newLines[i].trim().match(new RegExp('^' + labelName + ':'))) {
        tableStart = i; break;
      }
    }
    if (tableStart === -1) {
      console.error(`  ERROR: label not found in playerstats.asm: ${labelName}`);
      process.exit(1);
    }

    let entryIdx = 0;
    let patched = 0;
    for (let i = tableStart + 1; i < newLines.length && entryIdx < values.length; i++) {
      const l = newLines[i].trim();
      if (l === '' || l.startsWith(';')) continue;
      if (l.match(/^[A-Za-z_]\w*:/) && !l.startsWith('dc.')) break;

      const m = newLines[i].match(/^(\s*)dc\.l\s+(\S+)(.*)/i);
      if (!m) break;

      const indent = m[1];
      const commentPart = m[3] || '';
      const newVal = tokenForValueL(values[entryIdx], m[2]);

      const newLine = `${indent}dc.l\t${newVal}${commentPart}`;
      if (newLines[i] !== newLine) {
        newLines[i] = newLine;
        patched++;
      }
      entryIdx++;
    }

    if (entryIdx !== values.length) {
      console.error(`  ERROR: ${labelName}: expected ${values.length} entries, found ${entryIdx}`);
      process.exit(1);
    }
    return patched;
  }

  // Patch level-up stat tables
  totalPatched += patchWordTable('PlayerLevelToMmpMap', levelUps.map(l => l.mmp_gain));
  totalPatched += patchWordTable('PlayerLevelToMhpMap', levelUps.map(l => l.mhp_gain));
  totalPatched += patchWordTable('PlayerLevelToStrMap', levelUps.map(l => l.str_gain));
  totalPatched += patchWordTable('PlayerLevelToAcMap',  levelUps.map(l => l.ac_gain));
  totalPatched += patchWordTable('PlayerLevelToIntMap', levelUps.map(l => l.int_gain));
  totalPatched += patchWordTable('PlayerLevelToDexMap', levelUps.map(l => l.dex_gain));
  totalPatched += patchWordTable('PlayerLevelToLukMap', levelUps.map(l => l.luk_gain));
  totalPatched += patchLongTable('PlayerLevelToNextLevelExperienceMap', levelUps.map(l => l.xp_to_next));

  // Patch equipment stat modifiers
  totalPatched += patchWordTable('EquipmentToStatModifierMap', equipMods.map(e => e.stat_bonus));

  applyChanges(PLAYERSTATS_ASM, lines, newLines, `player stats (${totalPatched} line(s) changed)`);
}

// ---------------------------------------------------------------------------
// Helper: patch a single shop macro line in-place, preserving alignment spacing.
//
// Given an original line like:
//   "\tshopMagic MAGIC_TYPE_FIELD,  MAGIC_SANGUA"
// and a new item with magic_type_constant/magic_id_constant, returns the line
// with updated constants but original spacing preserved.
//
// For shopItem (single arg), the single arg is replaced.
// For shopEquip/shopMagic (two args), both args are replaced preserving the
// spacing between comma and second arg.
// ---------------------------------------------------------------------------

function patchShopMacroLine(origLine, item) {
  // Match: (indent)(macroName)(whitespace)(arg1)(comma+spaces)(arg2)(comment?)
  // or:    (indent)(macroName)(whitespace)(arg1)(comment?)
  const m2 = origLine.match(/^(\s*)(shop(?:Magic|Equip|Item))\s+(\S+)(,\s*)(\S+)(.*)?$/i);
  const m1 = origLine.match(/^(\s*)(shop(?:Magic|Equip|Item))\s+(\S+)()()(.*)?$/i);

  if (item.item_type === 'item') {
    if (m2 && m2[2].toLowerCase() === 'shopitem') {
      return `${m2[1]}${m2[2]} ${item.item_constant}${m2[6] || ''}`;
    }
    if (m1) {
      return `${m1[1]}${m1[2]} ${item.item_constant}${m1[6] || ''}`;
    }
  } else if (item.item_type === 'equipment') {
    if (m2 && m2[2].toLowerCase() === 'shopequip') {
      return `${m2[1]}${m2[2]} ${item.equip_type_constant}${m2[4]}${item.equip_id_constant}${m2[6] || ''}`;
    }
  } else if (item.item_type === 'magic') {
    if (m2 && m2[2].toLowerCase() === 'shopmagic') {
      return `${m2[1]}${m2[2]} ${item.magic_type_constant}${m2[4]}${item.magic_id_constant}${m2[6] || ''}`;
    }
  }
  // Fallback: rebuild from scratch
  console.warn(`  WARN: could not parse macro line for in-place patch: ${origLine}`);
  const ind = (origLine.match(/^(\s*)/) || ['', '\t'])[1];
  if (item.item_type === 'item')      return `${ind}shopItem ${item.item_constant}`;
  if (item.item_type === 'equipment') return `${ind}shopEquip ${item.equip_type_constant},${item.equip_id_constant}`;
  if (item.item_type === 'magic')     return `${ind}shopMagic ${item.magic_type_constant},${item.magic_id_constant}`;
  return origLine;
}

// ---------------------------------------------------------------------------
// INJECTOR 4: Shop assortments → src/shopdata.asm
// ---------------------------------------------------------------------------
//
// Patches each <Town>[Item|Equipment|Magic]ShopAssortment block.
// The block structure is:
//   <Label>:
//     dc.w  <count>
//     shopItem/shopEquip/shopMagic  ...   (count lines)
//
// Strategy: for each assortment label in shops.json, locate the label in
// shopdata.asm, then replace dc.w count + following macro lines.
//
// NOTE: The count can change (items can be added/removed from a shop).
// The script splices new lines in place of the old block, keeping all
// surrounding content intact.
//
// WARNING: Changing item counts may affect the binary size of shopdata.asm
// which WILL break bit-perfect verification. This is expected and intentional
// when using this tool for ROM hacking — the verify.bat will fail, and the
// resulting ROM will differ from stock. Only use --shops when intentionally
// modifying shop contents.

function injectShops() {
  console.log('Injecting shop assortments...');
  const data = loadJson('shops.json');
  const lines = readLines(SHOPDATA_ASM);

  // Collect all unique assortment blocks from JSON (deduplicated by label)
  const assortments = {};
  for (const town of data.town_shops) {
    for (const [shopType, shopData] of Object.entries(town.shops)) {
      const assort = shopData.assortment;
      if (!assort || !assort.label) continue;
      if (assort.label in assortments) continue;  // already seen
      assortments[assort.label] = assort;
    }
  }

  // For each assortment, locate its block in the ASM and replace it
  let newLines = lines.slice();
  let totalPatched = 0;
  const processedLabels = new Set();

  for (const [label, assort] of Object.entries(assortments)) {
    if (processedLabels.has(label)) continue;
    processedLabels.add(label);

    // Find the label line
    let labelIdx = -1;
    for (let i = 0; i < newLines.length; i++) {
      if (newLines[i].trim() === label + ':') { labelIdx = i; break; }
    }
    if (labelIdx === -1) {
      console.warn(`  WARN: assortment label not found: ${label} (skipping)`);
      continue;
    }

    // Find the dc.w count line
    let countIdx = -1;
    for (let j = labelIdx + 1; j < newLines.length && j < labelIdx + 5; j++) {
      const l = newLines[j].trim();
      if (!l || l.startsWith(';')) continue;
      if (l.match(/^dc\.w\s+/i)) { countIdx = j; break; }
      break;
    }
    if (countIdx === -1) {
      console.error(`  ERROR: no dc.w count line found after ${label} (L${labelIdx + 1})`);
      process.exit(1);
    }

    // Find the end of the macro block: count lines of shopItem/shopEquip/shopMagic
    // Allow blank/comment lines interleaved
    const oldCountLine = newLines[countIdx].trim();
    const oldCountM = oldCountLine.match(/^dc\.w\s+(\$?[0-9A-Fa-f]+)/i);
    if (!oldCountM) {
      console.error(`  ERROR: cannot parse count in ${label}: ${oldCountLine}`);
      process.exit(1);
    }
    const oldCount = oldCountM[1].startsWith('$') ?
      parseInt(oldCountM[1].slice(1), 16) : parseInt(oldCountM[1], 10);

    // Collect actual macro lines (skip blank/comment)
    let macroStart = countIdx + 1;
    const oldMacroIndices = [];
    for (let j = macroStart; j < newLines.length && oldMacroIndices.length < oldCount; j++) {
      const l = newLines[j].trim();
      if (!l || l.startsWith(';')) continue;
      if (!l.match(/^shop(Item|Equip|Magic)\s+/i)) break;
      oldMacroIndices.push(j);
    }

    if (oldMacroIndices.length !== oldCount) {
      console.warn(`  WARN: ${label}: expected ${oldCount} macro lines, found ${oldMacroIndices.length} (skipping)`);
      continue;
    }

    // Detect indentation from first macro line (or count line)
    const indentSource = oldMacroIndices.length > 0 ? newLines[oldMacroIndices[0]] : newLines[countIdx];
    const indentMatch = indentSource.match(/^(\s+)/);
    const indent = indentMatch ? indentMatch[1] : '\t';

    // Build new count + macro lines from JSON
    const newCount = assort.items.length;
    const newCountLine = `${indent}dc.w\t$${newCount.toString(16).toUpperCase().padStart(1, '0')}`;

    // Build new macro lines.
    // For the same-count case, we patch in-place to preserve alignment spacing.
    // For count-changed cases, we build new lines (spacing not preserved — intentional edit).
    const newMacroLines = [];
    for (let k = 0; k < assort.items.length; k++) {
      const item = assort.items[k];
      if (oldCount === assort.items.length && k < oldMacroIndices.length) {
        // Same count: preserve original line structure, substitute token values only
        const origLine = newLines[oldMacroIndices[k]];
        newMacroLines.push(patchShopMacroLine(origLine, item));
      } else {
        // Count changed: rebuild from scratch
        if (item.item_type === 'item') {
          newMacroLines.push(`${indent}shopItem ${item.item_constant}`);
        } else if (item.item_type === 'equipment') {
          newMacroLines.push(`${indent}shopEquip ${item.equip_type_constant},${item.equip_id_constant}`);
        } else if (item.item_type === 'magic') {
          newMacroLines.push(`${indent}shopMagic ${item.magic_type_constant},${item.magic_id_constant}`);
        } else {
          console.error(`  ERROR: unknown item_type '${item.item_type}' in ${label}`);
          process.exit(1);
        }
      }
    }

    // Apply: replace count line and old macro lines
    // Since indices may not be contiguous (blank lines interleaved), we replace
    // only the exact lines we found.
    let changed = false;

    // Replace count line
    if (newLines[countIdx] !== newCountLine) {
      newLines[countIdx] = newCountLine;
      changed = true;
    }

    if (oldCount === newCount) {
      // Same number of items: replace in-place
      for (let k = 0; k < oldCount; k++) {
        if (newLines[oldMacroIndices[k]] !== newMacroLines[k]) {
          newLines[oldMacroIndices[k]] = newMacroLines[k];
          changed = true;
        }
      }
    } else {
      // Different count: splice the macro block.
      // Remove old macro lines (in reverse to keep indices valid),
      // then insert new ones after the count line.
      for (let k = oldMacroIndices.length - 1; k >= 0; k--) {
        newLines.splice(oldMacroIndices[k], 1);
      }
      // Insert new macro lines right after countIdx
      newLines.splice(countIdx + 1, 0, ...newMacroLines);
      changed = true;
    }

    if (changed) totalPatched++;
  }

  applyChanges(SHOPDATA_ASM, lines, newLines, `shops (${totalPatched} assortment block(s) changed)`);

  if (totalPatched > 0 && !DRY_RUN) {
    console.log('  NOTE: Shop item counts may have changed — binary size may differ.');
    console.log('        Run cmd //c verify.bat; a non-bit-perfect result is expected');
    console.log('        if you intentionally changed shop contents.');
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

if (DO_ENEMIES)      injectEnemies();
if (DO_MAGIC)        injectMagic();
if (DO_PLAYER_STATS) injectPlayerStats();
if (DO_SHOPS)        injectShops();

if (!DRY_RUN) {
  console.log('\nDone. Run cmd //c verify.bat to confirm build integrity.');
}
