#!/usr/bin/env node
// tools/extract_game_data.js
//
// EDIT-006: Machine-readable data extraction from Sword of Vermilion ASM sources.
//
// Extracts the following game data tables from ASM source files and emits JSON:
//
//   tools/data/enemies.json       — All 85 enemy types (stats, rewards, gfx)
//   tools/data/encounter_map.json — Overworld + cave encounter zone tables
//   tools/data/shops.json         — All town shop assortments and prices
//   tools/data/player_stats.json  — Level-up stat tables and equipment modifiers
//   tools/data/magic_tables.json  — Magic MP costs, damage, element types
//   tools/data/service_prices.json — Inn, church, fortune teller prices per town
//
// Usage:
//   node tools/extract_game_data.js [--out <dir>]
//
// Defaults:
//   --out  tools/data/
//
// All values are extracted from the .asm source files (not the binary ROM).
// Hex values from dc.l/dc.w/dc.b are preserved as-is; the script does not
// convert between representations unless noted.

'use strict';

const fs   = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Argument parsing & paths
// ---------------------------------------------------------------------------
const args = process.argv.slice(2);
function getArg(flag, def) {
  const i = args.indexOf(flag);
  return i !== -1 ? args[i + 1] : def;
}

const ROOT    = path.resolve(__dirname, '..');
const outDir  = path.resolve(ROOT, getArg('--out', 'tools/data'));

// Source files
const BATTLEDATA_ASM  = path.join(ROOT, 'src', 'battledata.asm');
const SHOPDATA_ASM    = path.join(ROOT, 'src', 'shopdata.asm');
const PLAYERSTATS_ASM = path.join(ROOT, 'src', 'playerstats.asm');
const CONSTANTS_ASM   = path.join(ROOT, 'constants.asm');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Parse a hex literal ($XXXX or $XX) or decimal integer, returns number */
function parseNum(s) {
  s = s.trim();
  if (s.startsWith('$')) return parseInt(s.slice(1), 16);
  return parseInt(s, 10);
}

/** Read file lines, stripping \r */
function readLines(p) {
  return fs.readFileSync(p, 'utf8').split('\n').map(l => l.replace(/\r$/, ''));
}

/** Strip inline comment from an ASM token. */
function stripComment(s) {
  const i = s.indexOf(';');
  return i === -1 ? s : s.slice(0, i);
}

// ---------------------------------------------------------------------------
// Parse constants.asm for named constant values
// ---------------------------------------------------------------------------
function loadConstants(asmPath) {
  const lines = readLines(asmPath);
  const map = {};
  for (const line of lines) {
    const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s+(?:=|equ)\s+(\S+)/i);
    if (!m) continue;
    const name = m[1];
    const raw  = stripComment(m[2]).trim();
    if (raw.startsWith('$')) {
      map[name] = parseInt(raw.slice(1), 16);
    } else if (/^-?\d+$/.test(raw)) {
      map[name] = parseInt(raw, 10);
    }
  }
  return map;
}

const CONST = loadConstants(CONSTANTS_ASM);

// ---------------------------------------------------------------------------
// Resolve a token that may be a constant name or a literal
// ---------------------------------------------------------------------------
function resolveToken(tok) {
  tok = stripComment(tok).trim();
  if (tok.startsWith('$')) return parseInt(tok.slice(1), 16);
  if (/^-?\d+$/.test(tok)) return parseInt(tok, 10);
  if (tok in CONST) return CONST[tok];
  return null; // label pointer or unresolvable
}

// ---------------------------------------------------------------------------
// SECTION 1: Enemy data extraction from battledata.asm
// ---------------------------------------------------------------------------
//
// enemyData macro expands to:
//   dc.l  ai_fn          — function pointer (unresolvable label)
//   dc.w  tile_id        — arg 2 ($hex)
//   dc.w  reward_type    — arg 3 (ENEMY_REWARD_* constant)
//   dc.w  reward_value   — arg 4
//   dc.b  extra_obj_slots — arg 5
//   dc.b  max_spawn      — arg 6
//   dc.b  hp_hi          — arg 7 >> 8
//   dc.b  hp_lo          — arg 7 & $FF
//   dc.b  dmg_hi         — arg 8 >> 8
//   dc.b  dmg_lo         — arg 8 & $FF
//   dc.w  xp_reward      — arg 9
//   dc.w  kim_reward     — arg 10
//   dc.l  speed          — arg 11
//   dc.b  sprite_frame   — arg 12
//   dc.b  behavior_flag  — arg 13
//
// In source: enemyData ai_fn,tile_id,reward_type,reward_value,extra_slots,max_spawn,
//                      hp,damage,xp,kims,speed,sprite_frame,behavior_flag
//
// EnemyGfxDataTable: 3 dc.l per entry → Appearance / Data / SpriteSet labels
// EnemyEncounterGroup_NN: 4 dc.w → gfx table indices
// EnemyEncounterTypesByMapSector: 128 dc.b in 8 rows × 16 cols
// EnemyEncounterTypesByCaveRoom:  42 dc.b

function extractEnemies(lines) {
  // --- Pass 1: collect EnemyData_* entries ---
  const enemyDataMap = {}; // label -> parsed stats object

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();

    // Match: "EnemyData_Name:" on its own line or with a comment
    const labelMatch = line.match(/^(EnemyData_\w+):$/);
    if (!labelMatch) continue;
    const label = labelMatch[1];

    // Next non-blank line should be the enemyData macro call
    let macroLine = '';
    for (let j = i + 1; j < lines.length && j < i + 4; j++) {
      const l = lines[j].trim();
      if (l && !l.startsWith(';')) { macroLine = l; break; }
    }

    // Match: enemyData args...
    const macroMatch = macroLine.match(/^enemyData\s+(.+)/);
    if (!macroMatch) continue;

    // Split args by comma (careful: no nested commas in this macro)
    const rawArgs = macroMatch[1].split(',').map(s => stripComment(s).trim());
    if (rawArgs.length < 13) continue;

    const [ai_fn, tile_id, reward_type, reward_value,
           extra_slots, max_spawn, hp, damage, xp, kims, speed,
           sprite_frame, behavior_flag] = rawArgs;

    const entry = {
      label,
      name: label.replace('EnemyData_', ''),
      ai_fn: ai_fn.trim(),
      tile_id:       resolveToken(tile_id),
      reward_type:   resolveToken(reward_type),
      reward_value:  resolveToken(reward_value),
      extra_obj_slots: resolveToken(extra_slots),
      max_spawn:     resolveToken(max_spawn),
      hp:            resolveToken(hp),
      damage_per_hit: resolveToken(damage),
      xp_reward:     resolveToken(xp),
      kim_reward:    resolveToken(kims),
      speed:         resolveToken(speed),
      sprite_frame:  resolveToken(sprite_frame),
      behavior_flag: resolveToken(behavior_flag),
    };
    enemyDataMap[label] = entry;
  }

  // --- Pass 2: EnemyGfxDataTable — map index → labels ---
  // Lines: EnemyGfxDataTable: then triplets dc.l App / dc.l Data / dc.l Sprite
  const gfxTable = []; // array of { index, appearance, data, sprite_set }
  let inGfxTable = false;
  let tripletBuf = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line.startsWith('EnemyGfxDataTable:')) { inGfxTable = true; continue; }
    if (!inGfxTable) continue;

    // Stop when we reach EnemyAppearance_ section (next named block)
    if (line.match(/^EnemyAppearance_\w+:/) && tripletBuf.length === 0) { inGfxTable = false; break; }
    if (line.startsWith(';') || line === '') continue;

    const dcl = line.match(/^dc\.l\s+(\S+)/i);
    if (!dcl) { inGfxTable = false; break; }

    tripletBuf.push(stripComment(dcl[1]).trim());
    if (tripletBuf.length === 3) {
      gfxTable.push({
        index: gfxTable.length,
        appearance_label: tripletBuf[0],
        data_label:       tripletBuf[1],
        sprite_set_label: tripletBuf[2],
      });
      tripletBuf = [];
    }
  }

  // --- Pass 3: EnemyEncounterGroup_NN ---
  const encounterGroups = {}; // groupIndex (number) -> [idx0..idx3]
  const groupRe = /^EnemyEncounterGroup_([0-9A-Fa-f]+):$/;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    const gm = line.match(groupRe);
    if (!gm) continue;
    const groupIdx = parseInt(gm[1], 16);

    // Next line: dc.w $X, $X, $X, $X ; optional comment
    for (let j = i + 1; j < lines.length && j < i + 4; j++) {
      const l = lines[j].trim();
      if (!l || l.startsWith(';')) continue;
      const dcw = l.match(/^dc\.w\s+(.+)/i);
      if (!dcw) break;
      const raw = stripComment(dcw[1]);
      const vals = raw.split(',').map(s => resolveToken(s.trim())).filter(v => v !== null);
      encounterGroups[groupIdx] = vals;
      break;
    }
  }

  // --- Pass 4: EnemyEncounterTypesByMapSector (128 bytes in 8 rows) ---
  const overworldMap = [];
  let inOverworld = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line.startsWith('EnemyEncounterTypesByMapSector:')) { inOverworld = true; continue; }
    if (!inOverworld) continue;
    if (line.startsWith(';') || line === '') continue;
    // Stop at next label
    if (line.match(/^[A-Za-z_]\w*:/) && !line.startsWith('dc.')) { inOverworld = false; break; }

    const dcb = line.match(/^dc\.b\s+(.+)/i);
    if (!dcb) { inOverworld = false; break; }
    const raw = stripComment(dcb[1]);
    const vals = raw.split(',').map(s => resolveToken(s.trim())).filter(v => v !== null);
    overworldMap.push(vals);
    if (overworldMap.length === 8) { inOverworld = false; }
  }

  // --- Pass 5: EnemyEncounterTypesByCaveRoom (42 bytes) ---
  const caveRooms = [];
  let inCave = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line.startsWith('EnemyEncounterTypesByCaveRoom:')) { inCave = true; continue; }
    if (!inCave) continue;
    if (line.startsWith(';') || line === '') continue;
    if (line.match(/^[A-Za-z_]\w*:/) && !line.startsWith('dc.')) { inCave = false; break; }

    const dcb = line.match(/^dc\.b\s+(.+)/i);
    if (!dcb) { inCave = false; break; }
    const raw = stripComment(dcb[1]);
    const vals = raw.split(',').map(s => resolveToken(s.trim())).filter(v => v !== null);
    caveRooms.push(...vals);
    if (caveRooms.length >= 42) { inCave = false; }
  }

  // --- Build final enemy list (indexed by EnemyGfxDataTable order) ---
  const enemies = gfxTable.map(entry => {
    const dataEntry = enemyDataMap[entry.data_label] || null;
    return {
      gfx_index:        entry.index,
      appearance_label: entry.appearance_label,
      data_label:       entry.data_label,
      sprite_set_label: entry.sprite_set_label,
      stats: dataEntry ? {
        name:            dataEntry.name,
        ai_fn:           dataEntry.ai_fn,
        tile_id:         dataEntry.tile_id,
        reward_type:     dataEntry.reward_type,
        reward_value:    dataEntry.reward_value,
        extra_obj_slots: dataEntry.extra_obj_slots,
        max_spawn:       dataEntry.max_spawn,
        hp:              dataEntry.hp,
        damage_per_hit:  dataEntry.damage_per_hit,
        xp_reward:       dataEntry.xp_reward,
        kim_reward:      dataEntry.kim_reward,
        speed:           dataEntry.speed,
        sprite_frame:    dataEntry.sprite_frame,
        behavior_flag:   dataEntry.behavior_flag,
      } : null,
    };
  });

  return { enemies, gfxTable, encounterGroups, overworldMap, caveRooms };
}

// ---------------------------------------------------------------------------
// SECTION 2: Shop data extraction from shopdata.asm
// ---------------------------------------------------------------------------

// Town ID mapping
const TOWN_NAMES = {
  0x00: 'WYCLIF', 0x01: 'PARMA', 0x02: 'WATLING', 0x03: 'DEEPDALE',
  0x04: 'STOW1', 0x05: 'STOW2', 0x06: 'KELTWICK', 0x07: 'MALAGA',
  0x08: 'BARROW', 0x09: 'TADCASTER', 0x0A: 'HELWIG', 0x0B: 'SWAFFHAM',
  0x0C: 'EXCALABRIA', 0x0D: 'HASTINGS1', 0x0E: 'HASTINGS2', 0x0F: 'CARTHAHENA',
};

// Item ID mapping (from ITEM_* constants)
const ITEM_NAMES = {};
const MAGIC_NAMES = {};
const EQUIP_NAMES = {};
for (const [k, v] of Object.entries(CONST)) {
  if (k.startsWith('ITEM_') && !k.includes('TYPE') && !k.includes('MENU') && !k.includes('TAKE') && typeof v === 'number') {
    ITEM_NAMES[v] = k.replace('ITEM_', '');
  }
  if (k.startsWith('MAGIC_') && !k.includes('TYPE') && !k.includes('NONE') && !k.includes('READIED') && !k.includes('SLOT') && !k.includes('SANGUIOS') && typeof v === 'number') {
    MAGIC_NAMES[v] = k.replace('MAGIC_', '');
  }
  if (k.startsWith('EQUIPMENT_') && !k.includes('TYPE') && !k.includes('FLAG') && typeof v === 'number') {
    EQUIP_NAMES[v] = k.replace('EQUIPMENT_', '');
  }
}
// Add MAGIC_SANGUIOS manually since it was excluded above
if ('MAGIC_SANGUIOS' in CONST) MAGIC_NAMES[CONST['MAGIC_SANGUIOS']] = 'SANGUIOS';

function extractShops(lines) {
  // --- Parse per-town assortment blocks ---
  // Pattern: <TownName>[Item|Equipment|Magic]ShopAssortment:
  //   dc.w count
  //   shopItem ITEM_*, ...  or shopEquip TYPE,ID  or shopMagic TYPE,ID

  const assortments = {}; // label -> { type, items: [{category, item_id, item_name}] }

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    const assortMatch = line.match(/^(\w+ShopAssortment):\s*$/);
    if (!assortMatch) continue;
    const label = assortMatch[1];

    let type = 'unknown';
    if (/Item/.test(label)) type = 'item';
    else if (/Equipment/.test(label)) type = 'equipment';
    else if (/Magic/.test(label)) type = 'magic';

    const items = [];

    // Read dc.w count
    let j = i + 1;
    while (j < lines.length && (!lines[j].trim() || lines[j].trim().startsWith(';'))) j++;
    const countLine = lines[j] ? lines[j].trim() : '';
    const countMatch = countLine.match(/^dc\.w\s+\$?([0-9A-Fa-f]+)/i);
    if (!countMatch) continue;
    const count = parseInt(countMatch[1], 16);
    j++;

    for (let k = 0; k < count && j < lines.length; j++) {
      const l = lines[j].trim();
      if (!l || l.startsWith(';')) continue;
      if (l.match(/^[A-Za-z_]\w*:/) && !l.startsWith('shopItem') && !l.startsWith('shopEquip') && !l.startsWith('shopMagic')) break;

      const shopItemM = l.match(/^shopItem\s+(\S+)/i);
      const shopEquipM = l.match(/^shopEquip\s+(\S+)\s*,\s*(\S+)/i);
      const shopMagicM = l.match(/^shopMagic\s+(\S+)\s*,\s*(\S+)/i);

      if (shopItemM) {
        const raw = stripComment(shopItemM[1]).trim();
        const id = resolveToken(raw);
        items.push({ item_type: 'item', item_constant: raw, item_id: id, item_name: ITEM_NAMES[id] || null });
        k++;
      } else if (shopEquipM) {
        const typeRaw = stripComment(shopEquipM[1]).trim();
        const idRaw   = stripComment(shopEquipM[2]).trim();
        const typeVal = resolveToken(typeRaw);
        const idVal   = resolveToken(idRaw);
        items.push({ item_type: 'equipment', equip_type_constant: typeRaw, equip_type: typeVal, equip_id_constant: idRaw, equip_id: idVal, item_name: EQUIP_NAMES[idVal] || null });
        k++;
      } else if (shopMagicM) {
        const typeRaw = stripComment(shopMagicM[1]).trim();
        const idRaw   = stripComment(shopMagicM[2]).trim();
        const typeVal = resolveToken(typeRaw);
        const idVal   = resolveToken(idRaw);
        items.push({ item_type: 'magic', magic_type_constant: typeRaw, magic_type: typeVal, magic_id_constant: idRaw, magic_id: idVal, item_name: MAGIC_NAMES[idVal] || null });
        k++;
      }
    }

    assortments[label] = { label, shop_type: type, item_count: count, items };
  }

  // --- Parse price tables ---
  const prices = {}; // label -> [price0, price1, ...]

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    const priceMatch = line.match(/^(\w+ShopPrices):\s*$/);
    if (!priceMatch) continue;
    const label = priceMatch[1];
    const priceList = [];

    for (let j = i + 1; j < lines.length; j++) {
      const l = lines[j].trim();
      if (!l || l.startsWith(';')) continue;
      if (l.match(/^[A-Za-z_]\w*:/) && !l.startsWith('dc.')) break;
      const dcl = l.match(/^dc\.l\s+(\S+)/i);
      if (!dcl) break;
      const val = resolveToken(stripComment(dcl[1]).trim());
      if (val !== null) priceList.push(val);
    }

    prices[label] = priceList;
  }

  // --- Parse ShopAssortmentByTownAndShopType ---
  // Lines: townShopBlock AssortItem, AssortEquip, AssortMagicBuy, AssortMagicSell ; TOWN_NAME
  const townShops = [];
  let inShopTable = false;
  const SHOP_TYPE_NAMES = ['item', 'equipment', 'magic_buy', 'magic_sell'];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line.startsWith('ShopAssortmentByTownAndShopType:')) { inShopTable = true; continue; }
    if (!inShopTable) continue;
    if (line === '' || line.startsWith(';')) continue;
    if (line.match(/^ShopPricesBy/) || line.match(/^ShopResale/)) { inShopTable = false; break; }

    const blockM = line.match(/^townShopBlock\s+(.+)/i);
    if (!blockM) continue;

    const raw = stripComment(blockM[1]);
    const parts = raw.split(',').map(s => s.trim());
    if (parts.length < 4) continue;

    const townIdx = townShops.length;
    const townId = townIdx;

    const shops = {};
    for (let t = 0; t < 4; t++) {
      const assortLabel = parts[t];
      const assortData  = assortments[assortLabel] || null;

      // Match price label: same prefix but Prices instead of Assortment
      // We'll match by index in ShopPricesByTownAndType below
      shops[SHOP_TYPE_NAMES[t]] = {
        assortment_label: assortLabel,
        assortment: assortData,
        price_label: null,
        prices: [],
      };
    }

    townShops.push({
      town_id: townId,
      town_name: TOWN_NAMES[townId] || `TOWN_${townId.toString(16).toUpperCase()}`,
      shops,
    });
  }

  // --- Parse ShopPricesByTownAndType — cross-reference prices ---
  let inPriceTable = false;
  let priceRowIdx  = 0;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line.startsWith('ShopPricesByTownAndType:')) { inPriceTable = true; priceRowIdx = 0; continue; }
    if (!inPriceTable) continue;
    if (line === '' || line.startsWith(';')) continue;
    if (line.match(/^ShopResale/) || line.match(/^ShopPossession/)) { inPriceTable = false; break; }

    const blockM = line.match(/^townShopBlock\s+(.+)/i);
    if (!blockM) continue;

    const raw = stripComment(blockM[1]);
    const parts = raw.split(',').map(s => s.trim());
    if (parts.length < 4 || priceRowIdx >= townShops.length) { priceRowIdx++; continue; }

    for (let t = 0; t < 4; t++) {
      const priceLabel = parts[t];
      const priceList  = prices[priceLabel] || [];
      if (townShops[priceRowIdx] && townShops[priceRowIdx].shops[SHOP_TYPE_NAMES[t]]) {
        townShops[priceRowIdx].shops[SHOP_TYPE_NAMES[t]].price_label = priceLabel;
        townShops[priceRowIdx].shops[SHOP_TYPE_NAMES[t]].prices = priceList;
      }
    }
    priceRowIdx++;
  }

  // --- Parse flat price/resale tables ---
  function extractFlatTable(labelName, sizeDirective) {
    const result = [];
    let inTable = false;
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (line.startsWith(labelName + ':')) { inTable = true; continue; }
      if (!inTable) continue;
      if (line === '' || line.startsWith(';')) continue;
      if (line.match(/^[A-Za-z_]\w*:/) && !line.startsWith('dc.')) break;
      const re = new RegExp(`^dc\\.${sizeDirective}\\s+(.+)`, 'i');
      const m = line.match(re);
      if (!m) break;
      const raw = stripComment(m[1]);
      const vals = raw.split(',').map(s => resolveToken(s.trim())).filter(v => v !== null);
      result.push(...vals);
    }
    return result;
  }

  // --- Parse inn/fortune teller & church prices ---
  const innPrices         = extractFlatTable('InnAndFortuneTellerPricesByTown', 'l');
  const churchCurse       = extractFlatTable('ChurchCurseRemovalPricesByTown', 'l');
  const churchPoison      = extractFlatTable('ChurchPoisonCurePricesByTown', 'l');
  const itemResale        = extractFlatTable('ItemResaleValueMap', 'l');
  const equipResale       = extractFlatTable('EquipmentResaleValueMap', 'l');
  const magicResale       = extractFlatTable('MagicResaleValueMap', 'l');

  return {
    town_shops: townShops,
    service_prices: {
      inn_fortune_teller: innPrices.map((price, idx) => ({ town_id: idx, town_name: TOWN_NAMES[idx] || null, price })),
      church_curse_removal: churchCurse.map((price, idx) => ({ town_id: idx, town_name: TOWN_NAMES[idx] || null, price })),
      church_poison_cure:   churchPoison.map((price, idx) => ({ town_id: idx, town_name: TOWN_NAMES[idx] || null, price })),
    },
    resale_maps: {
      items:     itemResale.map((value, id) => ({ id, name: ITEM_NAMES[id] || null, resale_value: value })),
      equipment: equipResale.map((value, id) => ({ id, name: EQUIP_NAMES[id] || null, resale_value: value })),
      magic:     magicResale.map((value, id) => ({ id, name: MAGIC_NAMES[id] || null, resale_value: value })),
    },
  };
}

// ---------------------------------------------------------------------------
// SECTION 3: Magic tables from shopdata.asm
// ---------------------------------------------------------------------------

function extractMagicTables(shopLines) {
  function extractWordTable(labelName) {
    const result = [];
    let inTable = false;
    for (const line of shopLines) {
      const l = line.trim();
      if (l.startsWith(labelName + ':')) { inTable = true; continue; }
      if (!inTable) continue;
      if (l === '' || l.startsWith(';')) continue;
      if (l.match(/^[A-Za-z_]\w*:/) && !l.startsWith('dc.')) break;
      const m = l.match(/^dc\.w\s+(.+)/i);
      if (!m) break;
      const raw = stripComment(m[1]);
      const vals = raw.split(',').map(s => resolveToken(s.trim())).filter(v => v !== null);
      result.push(...vals);
    }
    return result;
  }

  function extractByteTable(labelName) {
    const result = [];
    let inTable = false;
    for (const line of shopLines) {
      const l = line.trim();
      if (l.startsWith(labelName + ':')) { inTable = true; continue; }
      if (!inTable) continue;
      if (l === '' || l.startsWith(';')) continue;
      if (l.match(/^[A-Za-z_]\w*:/) && !l.startsWith('dc.')) break;
      const m = l.match(/^dc\.b\s+(.+)/i);
      if (!m) break;
      const raw = stripComment(m[1]);
      const vals = raw.split(',').map(s => resolveToken(s.trim())).filter(v => v !== null);
      result.push(...vals);
    }
    return result;
  }

  const mpCosts     = extractWordTable('MagicMpConsumptionMap');
  const dmgBytes    = extractByteTable('MagicBaseDamageTable');  // pairs: [tier, base]
  const elemBytes   = extractByteTable('MagicElementTypeTable');

  const MAGIC_ID_NAMES = {};
  for (const [k, v] of Object.entries(CONST)) {
    if (k.startsWith('MAGIC_') && !k.startsWith('MAGIC_TYPE') && !k.startsWith('MAGIC_NONE') && !k.startsWith('MAGIC_READIED')) {
      MAGIC_ID_NAMES[v] = k.replace('MAGIC_', '');
    }
  }

  const ELEMENT_NAMES = ['neutral', 'water', 'thunder', 'fire'];

  const magics = mpCosts.map((mp, id) => ({
    id,
    name: MAGIC_ID_NAMES[id] || null,
    mp_cost: mp,
    // damage table only covers battle magic ($00–$0D)
    damage_tier: id < dmgBytes.length / 2 ? dmgBytes[id * 2]     : null,
    damage_base: id < dmgBytes.length / 2 ? dmgBytes[id * 2 + 1] : null,
    element:     id < elemBytes.length    ? ELEMENT_NAMES[elemBytes[id]] || elemBytes[id] : null,
  }));

  return magics;
}

// ---------------------------------------------------------------------------
// SECTION 4: Player stats from playerstats.asm
// ---------------------------------------------------------------------------

function extractPlayerStats(lines) {
  function extractTable(labelName, directive) {
    const result = [];
    let inTable = false;
    for (const line of lines) {
      const l = line.trim();
      if (l.match(new RegExp('^' + labelName + ':'))) { inTable = true; continue; }
      if (!inTable) continue;
      if (l === '' || l.startsWith(';')) continue;
      if (l.match(/^[A-Za-z_]\w*:/) && !l.startsWith('dc.')) break;
      const re = new RegExp(`^dc\\.${directive}\\s+(.+)`, 'i');
      const m = l.match(re);
      if (!m) break;
      const raw = stripComment(m[1]);
      const vals = raw.split(',').map(s => resolveToken(s.trim())).filter(v => v !== null);
      result.push(...vals);
    }
    return result;
  }

  const mmpTable  = extractTable('PlayerLevelToMmpMap', 'w');
  const mhpTable  = extractTable('PlayerLevelToMhpMap', 'w');
  const strTable  = extractTable('PlayerLevelToStrMap', 'w');
  const equipMods = extractTable('EquipmentToStatModifierMap', 'w');
  const acTable   = extractTable('PlayerLevelToAcMap', 'w');
  const intTable  = extractTable('PlayerLevelToIntMap', 'w');
  const dexTable  = extractTable('PlayerLevelToDexMap', 'w');
  const lukTable  = extractTable('PlayerLevelToLukMap', 'w');
  const xpTable   = extractTable('PlayerLevelToNextLevelExperienceMap', 'l');

  const levelCount = Math.min(mmpTable.length, mhpTable.length, strTable.length);
  const levels = [];
  for (let lv = 0; lv < levelCount; lv++) {
    levels.push({
      level:      lv + 1,       // entry 0 = gain when reaching level 1
      mmp_gain:   mmpTable[lv],
      mhp_gain:   mhpTable[lv],
      str_gain:   strTable[lv],
      ac_gain:    acTable[lv]  ?? null,
      int_gain:   intTable[lv] ?? null,
      dex_gain:   dexTable[lv] ?? null,
      luk_gain:   lukTable[lv] ?? null,
      xp_to_next: xpTable[lv]  ?? null,
    });
  }

  // Equipment stat modifiers: indexed by equip ID
  // $00–$13 swords (STR bonus), $14–$27 shields (AC), $28–$38 armor (AC)
  const equipStatMods = equipMods.map((value, id) => ({
    id,
    name:        EQUIP_NAMES[id] || null,
    stat_bonus:  value,
    bonus_type:  id < 0x14 ? 'str' : 'ac',
  }));

  return { levels, equip_stat_mods: equipStatMods };
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function main() {
  fs.mkdirSync(outDir, { recursive: true });

  // Read source files
  const battleLines  = readLines(BATTLEDATA_ASM);
  const shopLines    = readLines(SHOPDATA_ASM);
  const statsLines   = readLines(PLAYERSTATS_ASM);

  // --- Extract enemies ---
  console.log('Extracting enemy data...');
  const { enemies, gfxTable, encounterGroups, overworldMap, caveRooms } = extractEnemies(battleLines);

  const enemiesOut = {
    _meta: {
      generated_by: 'tools/extract_game_data.js',
      source: 'src/battledata.asm',
      description: 'Enemy stats, encounter groups, and zone tables',
      enemy_count: enemies.length,
    },
    enemies,
    encounter_groups: Object.fromEntries(
      Object.entries(encounterGroups).map(([k, v]) => [
        parseInt(k),
        {
          group_index: parseInt(k),
          enemy_gfx_indices: v,
          enemy_names: v.map(idx => enemies[idx] ? enemies[idx].stats ? enemies[idx].stats.name : null : null),
        }
      ])
    ),
    overworld_encounter_map: {
      description: '8 rows × 16 columns — index = row*16+col; 0 = no encounter; 1–$45 = group index',
      rows: overworldMap,
    },
    cave_room_encounter_table: {
      description: '42 bytes — indexed by cave room ID $00–$29; value = group index',
      rooms: caveRooms,
    },
  };

  fs.writeFileSync(path.join(outDir, 'enemies.json'), JSON.stringify(enemiesOut, null, 2) + '\n');
  console.log(`  enemies.json: ${enemies.length} enemy types, ${Object.keys(encounterGroups).length} encounter groups`);

  // --- Extract shops ---
  console.log('Extracting shop data...');
  const { town_shops, service_prices, resale_maps } = extractShops(shopLines);

  const shopsOut = {
    _meta: {
      generated_by: 'tools/extract_game_data.js',
      source: 'src/shopdata.asm',
      description: 'Town shop assortments, prices, and service prices',
    },
    town_shops,
  };
  fs.writeFileSync(path.join(outDir, 'shops.json'), JSON.stringify(shopsOut, null, 2) + '\n');
  console.log(`  shops.json: ${town_shops.length} towns`);

  const servicePricesOut = {
    _meta: { generated_by: 'tools/extract_game_data.js', source: 'src/shopdata.asm' },
    service_prices,
    resale_maps,
  };
  fs.writeFileSync(path.join(outDir, 'service_prices.json'), JSON.stringify(servicePricesOut, null, 2) + '\n');
  console.log(`  service_prices.json: ${service_prices.inn_fortune_teller.length} town entries`);

  // --- Extract magic tables ---
  console.log('Extracting magic tables...');
  const magics = extractMagicTables(shopLines);
  const magicOut = {
    _meta: { generated_by: 'tools/extract_game_data.js', source: 'src/shopdata.asm' },
    magic_count: magics.length,
    magic: magics,
  };
  fs.writeFileSync(path.join(outDir, 'magic_tables.json'), JSON.stringify(magicOut, null, 2) + '\n');
  console.log(`  magic_tables.json: ${magics.length} magic entries`);

  // --- Extract player stats ---
  console.log('Extracting player stat tables...');
  const { levels, equip_stat_mods } = extractPlayerStats(statsLines);
  const statsOut = {
    _meta: {
      generated_by: 'tools/extract_game_data.js',
      source: 'src/playerstats.asm',
      description: 'Level-up stat gain tables and equipment stat modifiers',
    },
    level_count: levels.length,
    level_ups: levels,
    equipment_stat_modifiers: equip_stat_mods,
  };
  fs.writeFileSync(path.join(outDir, 'player_stats.json'), JSON.stringify(statsOut, null, 2) + '\n');
  console.log(`  player_stats.json: ${levels.length} levels, ${equip_stat_mods.length} equipment entries`);

  console.log(`\nAll data written to ${path.relative(ROOT, outDir)}/`);
}

main();
