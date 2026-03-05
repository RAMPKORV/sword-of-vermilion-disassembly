#!/usr/bin/env node
// tools/encounter_analyzer.js
//
// Parses src/battledata.asm to extract encounter tables and enemy stat data,
// then reports:
//   - Overworld encounter groups per sector (8x16 grid)
//   - Cave/dungeon encounter groups per room (42 rooms)
//   - Enemy group composition (4 possible enemies per group)
//   - Per-enemy stats (hp, damage, xp, kims, speed)
//   - Difficulty curve analysis (average HP/damage by encounter zone)
//
// No binary ROM required — all data is parsed from ASM source.
//
// Usage:
//   node tools/encounter_analyzer.js [options]
//
// Options:
//   --overworld        Show overworld encounter map (ASCII grid)
//   --cave             Show cave/dungeon encounter list
//   --groups           Show all encounter group compositions
//   --enemies          Show enemy stat table
//   --curve            Show difficulty curve (default output)
//   --group <id>       Show details for one group (hex, e.g. --group 0F)
//   --enemy <name>     Show stats for one enemy (e.g. --enemy Skeleton)
//   --json             Output full data as JSON
//   --all              Show everything
//
// Example:
//   node tools/encounter_analyzer.js --curve
//   node tools/encounter_analyzer.js --overworld
//   node tools/encounter_analyzer.js --group 2A --enemies

'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const BATTLEDATA = path.join(ROOT, 'src', 'battledata.asm');

// ---------------------------------------------------------------------------
// Parse battledata.asm
// ---------------------------------------------------------------------------

function parseBattledata() {
  const src = fs.readFileSync(BATTLEDATA, 'utf8');
  const lines = src.split('\n');

  const overworldGrid = [];   // 128 bytes (8 rows × 16 cols), value = group index
  const caveRooms = [];       // 42 bytes, value = group index
  const groups = {};          // groupId (hex str) -> { enemies: [idx,...], names: [str,...] }
  const gfxTableOrder = [];   // ordered list of enemy names from EnemyGfxDataTable
  const enemyStats = {};      // name -> { hp, damage, xp, kims, speed, ai }

  let state = 'none';

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmed = line.trim();

    // -----------------------------------------------------------------------
    // Detect section starts
    // -----------------------------------------------------------------------
    if (trimmed.startsWith('EnemyEncounterTypesByMapSector:')) {
      state = 'overworld';
      continue;
    }
    if (trimmed.startsWith('EnemyEncounterTypesByCaveRoom:')) {
      state = 'cave';
      continue;
    }
    if (trimmed.startsWith('EnemyEncounterGroupTable:')) {
      state = 'skip'; // just pointer table, skip
      continue;
    }
    if (trimmed.startsWith('EnemyGfxDataTable:')) {
      state = 'gfxtable';
      continue;
    }

    // Match EnemyEncounterGroup_XX label
    const groupMatch = trimmed.match(/^EnemyEncounterGroup_([0-9A-Fa-f]+):\s*$/);
    if (groupMatch) {
      state = 'group:' + groupMatch[1].toUpperCase().padStart(2, '0');
      continue;
    }

    // Match EnemyData_* label
    const enemyDataMatch = trimmed.match(/^EnemyData_(\w+):\s*$/);
    if (enemyDataMatch) {
      state = 'enemydata:' + enemyDataMatch[1];
      continue;
    }

    // Match EnemyAppearance_* label (marks end of gfx table region)
    if (trimmed.match(/^EnemyAppearance_\w+:/)) {
      if (state === 'gfxtable') state = 'appearances';
      continue;
    }

    // -----------------------------------------------------------------------
    // Process lines by state
    // -----------------------------------------------------------------------

    if (state === 'overworld') {
      // dc.b $xx, $xx, ... ; row N
      const dcbMatch = trimmed.match(/^dc\.b\s+(.+?)(?:\s*;.*)?$/);
      if (dcbMatch) {
        const vals = parseDcbBytes(dcbMatch[1]);
        overworldGrid.push(...vals);
        if (overworldGrid.length >= 128) state = 'none';
      }
    }

    else if (state === 'cave') {
      const dcbMatch = trimmed.match(/^dc\.b\s+(.+?)(?:\s*;.*)?$/);
      if (dcbMatch) {
        const vals = parseDcbBytes(dcbMatch[1]);
        caveRooms.push(...vals);
        if (caveRooms.length >= 42) state = 'none';
      }
    }

    else if (state.startsWith('group:')) {
      const groupId = state.slice(6);
      // dc.w $A, $B, $C, $D ; Name | Name | Name | Name
      const dcwMatch = trimmed.match(/^dc\.w\s+(.+?)(?:\s*;\s*(.+))?$/);
      if (dcwMatch) {
        const idxStrs = dcwMatch[1].split(',').map(s => s.trim());
        const enemies = idxStrs.map(s => parseInt(s, 16));
        const comment = dcwMatch[2] || '';
        const names = comment.split('|').map(s => s.trim()).filter(Boolean);
        groups[groupId] = { enemies, names };
        state = 'none';
      }
    }

    else if (state === 'gfxtable') {
      // dc.l EnemyData_Foo  (every 2nd dc.l entry after EnemyAppearance_*)
      // Layout: dc.l EnemyAppearance_X / dc.l EnemyData_X / dc.l EnemySpriteSet_Y  (repeat)
      const dcl = trimmed.match(/^\bdc\.l\s+EnemyData_(\w+)/);
      if (dcl) {
        gfxTableOrder.push(dcl[1]);
      }
      // EnemyAppearance_* label marks the natural end of the pointer table
      if (trimmed.match(/^EnemyAppearance_\w+:/)) {
        state = 'appearances';
      }
    }

    else if (state.startsWith('enemydata:')) {
      const enemyName = state.slice(10);
      // enemyData ai_fn, tile_id, reward_type, reward_val, extra_slots, max_spawn,
      //           hp, damage, xp, kims, speed, sprite_frame, behavior_flag
      const edMatch = trimmed.match(/^\benemyData\s+(.+)$/);
      if (edMatch) {
        const args = splitArgs(edMatch[1]);
        if (args.length >= 13) {
          enemyStats[enemyName] = {
            ai:       args[0],
            tile_id:  parseHex(args[1]),
            reward_type: args[2],
            reward_val: parseHex(args[3]),
            extra_slots: parseHex(args[4]),
            max_spawn:  parseHex(args[5]),
            hp:       parseHex(args[6]),
            damage:   parseHex(args[7]),
            xp:       parseHex(args[8]),
            kims:     parseHex(args[9]),
            speed:    parseHex(args[10]),
            sprite_frame: parseHex(args[11]),
            behavior: parseHex(args[12]),
          };
        }
        state = 'none';
      }
    }
  }

  return { overworldGrid, caveRooms, groups, gfxTableOrder, enemyStats };
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function parseDcbBytes(str) {
  return str.split(',').map(s => {
    const t = s.trim();
    if (t.startsWith('$')) return parseInt(t.slice(1), 16);
    return parseInt(t, 10);
  }).filter(n => !isNaN(n));
}

function parseHex(str) {
  if (!str) return 0;
  const t = str.trim();
  if (t.startsWith('$')) return parseInt(t.slice(1), 16);
  if (t.startsWith('0x') || t.startsWith('0X')) return parseInt(t, 16);
  const n = parseInt(t, 10);
  return isNaN(n) ? 0 : n;
}

function splitArgs(str) {
  // Split on commas, but be aware there are no nested parens in these lines
  return str.split(',').map(s => s.trim());
}

function groupIdHex(idx) {
  return idx.toString(16).toUpperCase().padStart(2, '0');
}

// ---------------------------------------------------------------------------
// Analysis helpers
// ---------------------------------------------------------------------------

function getGroupNames(group, gfxTableOrder) {
  if (!group) return ['???'];
  if (group.names && group.names.length > 0) return group.names;
  // Fall back to index lookup
  return group.enemies.map(idx => gfxTableOrder[idx] || ('idx:' + idx));
}

function avgStat(enemies, enemyStats, statKey) {
  const vals = enemies
    .map(name => enemyStats[name])
    .filter(Boolean)
    .map(s => s[statKey]);
  if (!vals.length) return null;
  return Math.round(vals.reduce((a, b) => a + b, 0) / vals.length);
}

function groupDifficulty(groupId, groups, gfxTableOrder, enemyStats) {
  const group = groups[groupId];
  if (!group) return null;
  const names = getGroupNames(group, gfxTableOrder);
  const stats = names.map(n => enemyStats[n]).filter(Boolean);
  if (!stats.length) return null;
  const avgHp = Math.round(stats.reduce((a, s) => a + s.hp, 0) / stats.length);
  const avgDmg = Math.round(stats.reduce((a, s) => a + s.damage, 0) / stats.length);
  const avgXp = Math.round(stats.reduce((a, s) => a + s.xp, 0) / stats.length);
  const avgSpd = Math.round(stats.reduce((a, s) => a + s.speed, 0) / stats.length);
  return { avgHp, avgDmg, avgXp, avgSpd, names };
}

// ---------------------------------------------------------------------------
// Output formatters
// ---------------------------------------------------------------------------

function printOverworld(overworldGrid, groups, gfxTableOrder, enemyStats) {
  console.log('\n=== OVERWORLD ENCOUNTER MAP (8 rows × 16 cols) ===');
  console.log('  Values = group index (hex). 00 = no encounters.\n');
  const header = '     ' + Array.from({ length: 16 }, (_, i) => i.toString(16).toUpperCase().padStart(3)).join('');
  console.log(header);
  for (let row = 0; row < 8; row++) {
    const cells = [];
    for (let col = 0; col < 16; col++) {
      const idx = overworldGrid[row * 16 + col];
      cells.push(idx === 0 ? ' --' : (' ' + groupIdHex(idx)));
    }
    console.log('  ' + row + ' ' + cells.join(''));
  }
  console.log();

  // Print per-sector group summary
  console.log('--- Overworld group details ---');
  const seen = new Set();
  for (let row = 0; row < 8; row++) {
    for (let col = 0; col < 16; col++) {
      const idx = overworldGrid[row * 16 + col];
      if (idx === 0) continue;
      const gid = groupIdHex(idx);
      if (seen.has(gid)) continue;
      seen.add(gid);
      const diff = groupDifficulty(gid, groups, gfxTableOrder, enemyStats);
      if (diff) {
        console.log(`  Group ${gid}: ${diff.names.join(' | ')}  [avg HP:${diff.avgHp} DMG:${diff.avgDmg} XP:${diff.avgXp}]`);
      } else {
        const g = groups[gid];
        console.log(`  Group ${gid}: ${g ? getGroupNames(g, gfxTableOrder).join(' | ') : '???'}`);
      }
    }
  }
}

function printCave(caveRooms, groups, gfxTableOrder, enemyStats) {
  console.log('\n=== CAVE/DUNGEON ENCOUNTER TABLE (42 rooms) ===');
  for (let i = 0; i < caveRooms.length; i++) {
    const idx = caveRooms[i];
    const gid = groupIdHex(idx);
    const diff = groupDifficulty(gid, groups, gfxTableOrder, enemyStats);
    if (diff) {
      console.log(`  Room ${i.toString(16).toUpperCase().padStart(2,'0')} (${i.toString().padStart(2)}): Group ${gid} — ${diff.names.join(' | ')}  [avg HP:${diff.avgHp} DMG:${diff.avgDmg} XP:${diff.avgXp}]`);
    } else {
      console.log(`  Room ${i.toString(16).toUpperCase().padStart(2,'0')} (${i.toString().padStart(2)}): Group ${gid}`);
    }
  }
}

function printGroups(groups, gfxTableOrder, enemyStats) {
  console.log('\n=== ALL ENCOUNTER GROUPS ===');
  const ids = Object.keys(groups).sort();
  for (const gid of ids) {
    const g = groups[gid];
    const names = getGroupNames(g, gfxTableOrder);
    const diff = groupDifficulty(gid, groups, gfxTableOrder, enemyStats);
    const diffStr = diff ? `  [avg HP:${diff.avgHp} DMG:${diff.avgDmg} XP:${diff.avgXp} SPD:${diff.avgSpd}]` : '';
    console.log(`  ${gid}: ${names.join(' | ')}${diffStr}`);
  }
}

function printEnemies(gfxTableOrder, enemyStats) {
  console.log('\n=== ENEMY STAT TABLE ===');
  const fmt = (n, w) => String(n).padStart(w);
  console.log('  #   Name                           HP     DMG    XP     Kims   Speed   AI');
  console.log('  ' + '-'.repeat(90));
  for (let i = 0; i < gfxTableOrder.length; i++) {
    const name = gfxTableOrder[i];
    const s = enemyStats[name];
    if (!s) {
      console.log(`  ${fmt(i,3)}  ${name.padEnd(30)} (no stats parsed)`);
      continue;
    }
    const aiShort = s.ai.replace('InitEnemy_', '').replace('InitBoss_', 'Boss_');
    console.log(
      `  ${fmt(i,3)}  ${name.padEnd(30)} ` +
      `${fmt(s.hp,6)} ${fmt(s.damage,6)} ${fmt(s.xp,6)} ` +
      `${fmt(s.kims,6)} ${fmt(s.speed,7)}  ${aiShort}`
    );
  }
}

function printCurve(overworldGrid, caveRooms, groups, gfxTableOrder, enemyStats) {
  console.log('\n=== DIFFICULTY CURVE ANALYSIS ===\n');

  // Overworld: row-by-row average difficulty
  console.log('--- Overworld (by map row, south = row 0, north = row 7) ---');
  for (let row = 0; row < 8; row++) {
    const rowGroups = [];
    for (let col = 0; col < 16; col++) {
      const idx = overworldGrid[row * 16 + col];
      if (idx > 0) rowGroups.push(groupIdHex(idx));
    }
    if (!rowGroups.length) {
      console.log(`  Row ${row}: (no encounter sectors)`);
      continue;
    }
    const diffs = rowGroups.map(gid => groupDifficulty(gid, groups, gfxTableOrder, enemyStats)).filter(Boolean);
    if (!diffs.length) {
      console.log(`  Row ${row}: groups [${rowGroups.join(',')}] (no stat data)`);
      continue;
    }
    const avgHp  = Math.round(diffs.reduce((a, d) => a + d.avgHp, 0)  / diffs.length);
    const avgDmg = Math.round(diffs.reduce((a, d) => a + d.avgDmg, 0) / diffs.length);
    const avgXp  = Math.round(diffs.reduce((a, d) => a + d.avgXp, 0)  / diffs.length);
    const bar = hpBar(avgHp, 4000, 30);
    console.log(`  Row ${row}: avg HP=${String(avgHp).padStart(5)} DMG=${String(avgDmg).padStart(4)} XP=${String(avgXp).padStart(5)}  ${bar}`);
  }

  // Cave rooms: sequential
  console.log('\n--- Cave/Dungeon (by room ID, 00 = earliest, 29 = latest) ---');
  for (let i = 0; i < caveRooms.length; i++) {
    const gid = groupIdHex(caveRooms[i]);
    const diff = groupDifficulty(gid, groups, gfxTableOrder, enemyStats);
    if (!diff) {
      console.log(`  Room ${i.toString(16).toUpperCase().padStart(2,'0')}: Group ${gid} (no stat data)`);
      continue;
    }
    const bar = hpBar(diff.avgHp, 4000, 30);
    console.log(`  Room ${i.toString(16).toUpperCase().padStart(2,'0')}: avg HP=${String(diff.avgHp).padStart(5)} DMG=${String(diff.avgDmg).padStart(4)} XP=${String(diff.avgXp).padStart(5)}  ${bar}`);
  }
}

function hpBar(val, max, width) {
  const filled = Math.max(0, Math.min(width, Math.round((val / max) * width)));
  return '[' + '█'.repeat(filled) + '░'.repeat(width - filled) + ']';
}

function printGroupDetail(groupId, groups, gfxTableOrder, enemyStats) {
  const gid = groupId.toUpperCase().padStart(2, '0');
  const group = groups[gid];
  if (!group) {
    console.log(`Group ${gid} not found.`);
    return;
  }
  const names = getGroupNames(group, gfxTableOrder);
  console.log(`\n=== Encounter Group ${gid} ===`);
  console.log(`  4 possible encounters (selected by RNG & 3):`);
  for (let i = 0; i < 4; i++) {
    const name = names[i] || ('idx:' + group.enemies[i]);
    const s = enemyStats[name];
    const statsStr = s
      ? `HP:${s.hp} DMG:${s.damage} XP:${s.xp} Kims:${s.kims} Speed:${s.speed}`
      : '(no stats)';
    console.log(`  [${i}] ${name.padEnd(30)} ${statsStr}`);
  }
}

function printEnemyDetail(enemyName, enemyStats) {
  const s = enemyStats[enemyName];
  if (!s) {
    // Try case-insensitive match
    const key = Object.keys(enemyStats).find(k => k.toLowerCase() === enemyName.toLowerCase());
    if (key) return printEnemyDetail(key, enemyStats);
    console.log(`Enemy "${enemyName}" not found. Use --enemies to list all names.`);
    return;
  }
  console.log(`\n=== ${enemyName} ===`);
  console.log(`  HP:           ${s.hp}`);
  console.log(`  Damage/hit:   ${s.damage}`);
  console.log(`  XP reward:    ${s.xp}`);
  console.log(`  Kim reward:   ${s.kims}`);
  console.log(`  Speed:        $${s.speed.toString(16).toUpperCase().padStart(8,'0')} (${s.speed})`);
  console.log(`  AI routine:   ${s.ai}`);
  console.log(`  Max spawn:    ${s.max_spawn}`);
  console.log(`  Extra slots:  ${s.extra_slots}`);
  console.log(`  Reward type:  ${s.reward_type}  val=$${s.reward_val.toString(16).toUpperCase()}`);
  console.log(`  Behavior:     $${s.behavior.toString(16).toUpperCase().padStart(2,'0')}`);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function main() {
  const args = process.argv.slice(2);

  const showOverworld = args.includes('--overworld') || args.includes('--all');
  const showCave      = args.includes('--cave')      || args.includes('--all');
  const showGroups    = args.includes('--groups')    || args.includes('--all');
  const showEnemies   = args.includes('--enemies')   || args.includes('--all');
  const showCurve     = args.includes('--curve')     || args.includes('--all') || args.length === 0;
  const showJson      = args.includes('--json');

  const groupArg = (() => {
    const i = args.indexOf('--group');
    return i >= 0 ? args[i + 1] : null;
  })();
  const enemyArg = (() => {
    const i = args.indexOf('--enemy');
    return i >= 0 ? args[i + 1] : null;
  })();

  console.log('Parsing src/battledata.asm...');
  const { overworldGrid, caveRooms, groups, gfxTableOrder, enemyStats } = parseBattledata();

  console.log(`  Overworld sectors:  ${overworldGrid.length} bytes (${overworldGrid.filter(x=>x>0).length} with encounters)`);
  console.log(`  Cave rooms:         ${caveRooms.length}`);
  console.log(`  Encounter groups:   ${Object.keys(groups).length}`);
  console.log(`  Gfx table entries:  ${gfxTableOrder.length} enemies`);
  console.log(`  Enemy stat entries: ${Object.keys(enemyStats).length}`);

  if (showJson) {
    const out = { overworldGrid, caveRooms, groups, gfxTableOrder, enemyStats };
    console.log(JSON.stringify(out, null, 2));
    return;
  }

  if (groupArg) {
    printGroupDetail(groupArg, groups, gfxTableOrder, enemyStats);
    return;
  }

  if (enemyArg) {
    printEnemyDetail(enemyArg, enemyStats);
    return;
  }

  if (showOverworld) printOverworld(overworldGrid, groups, gfxTableOrder, enemyStats);
  if (showCave)      printCave(caveRooms, groups, gfxTableOrder, enemyStats);
  if (showGroups)    printGroups(groups, gfxTableOrder, enemyStats);
  if (showEnemies)   printEnemies(gfxTableOrder, enemyStats);
  if (showCurve)     printCurve(overworldGrid, caveRooms, groups, gfxTableOrder, enemyStats);
}

main();
