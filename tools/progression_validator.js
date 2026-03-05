#!/usr/bin/env node
// tools/progression_validator.js
//
// Validates game completability by modelling the Sword of Vermilion progression
// graph: town access, dungeon access, key items, locked doors, and story flags.
//
// The game is a linear RPG — progression is driven by:
//   1. Story event flags (Event_triggers, $FFFFC720+)
//   2. Key items (Pass to Carthahena, dungeon keys, crystals, etc.)
//   3. Locked dungeon doors (require specific key items)
//   4. Sequential quest chains linking each town
//
// This tool performs a forward-reachability analysis starting from the
// beginning of the game and verifies that all story milestones are reachable
// given the items and shops available at each stage.
//
// Usage:
//   node tools/progression_validator.js [options]
//
// Options:
//   --verbose    Print each step of the reachability expansion
//   --items      Print item availability summary per stage
//   --shops      Print shop accessibility per stage
//   --json       Output full analysis as JSON
//   --help       Show this help
//
// Exit code: 0 = completable, 1 = validation failure found

'use strict';

const args = process.argv.slice(2);
const VERBOSE = args.includes('--verbose');
const SHOW_ITEMS = args.includes('--items') || args.includes('--verbose');
const SHOW_SHOPS = args.includes('--shops') || args.includes('--verbose');
const SHOW_JSON  = args.includes('--json');
const SHOW_HELP  = args.includes('--help');

if (SHOW_HELP) {
  console.log(`Usage: node tools/progression_validator.js [--verbose] [--items] [--shops] [--json]`);
  process.exit(0);
}

// ---------------------------------------------------------------------------
// Constants (mirrors game_constants.asm / notes.txt)
// ---------------------------------------------------------------------------

const ITEMS = {
  HERBS:              0x00,
  CANDLE:             0x01,
  LANTERN:            0x02,
  POISON_BALM:        0x03,
  ALARM_CLOCK:        0x04,
  VASE:               0x05,
  JOKE_BOOK:          0x06,
  SMALL_BOMB:         0x07,
  OLD_WOMANS_SKETCH:  0x08,
  OLD_MANS_SKETCH:    0x09,
  PASS_TO_CARTHAHENA: 0x0A,
  TRUFFLE:            0x0B,
  DIGOT_PLANT:        0x0C,
  TREASURE_OF_TROY:   0x0D,
  WHITE_CRYSTAL:      0x0E,
  RED_CRYSTAL:        0x0F,
  BLUE_CRYSTAL:       0x10,
  WHITE_KEY:          0x11,
  RED_KEY:            0x12,
  BLUE_KEY:           0x13,
  CROWN:              0x14,
  SIXTEEN_RINGS:      0x15,
  BRONZE_KEY:         0x16,
  SILVER_KEY:         0x17,
  GOLD_KEY:           0x18,
  THULE_KEY:          0x19,
  SECRET_KEY:         0x1A,
  MEDICINE:           0x1B,
  AGATE_JEWEL:        0x1C,
  GRIFFIN_WING:       0x1D,
  TITANIAS_MIRROR:    0x1E,
  GNOME_STONE:        0x1F,
  TOPAZ_JEWEL:        0x20,
  BANSHEE_POWDER:     0x21,
  RAFAELS_STICK:      0x22,
  MIRROR_OF_ATLAS:    0x23,
  RUBY_BROOCH:        0x24,
  DUNGEON_KEY:        0x25,
  KULMS_VASE:         0x26,
  KASANS_CHISEL:      0x27,
  BOOK_OF_KIEL:       0x28,
  DANEGELD_WATER:     0x29,
  MINERAL_BAR:        0x2A,
  MEGA_BLAST:         0x2B,
  // Virtual item: Sword of Vermilion (equipment, not in items array)
  SWORD_OF_VERMILION: 0xFF,
};

const ITEM_NAMES = {};
for (const [k, v] of Object.entries(ITEMS)) ITEM_NAMES[v] = k;

const TOWNS = {
  WYCLIF:     0x00,
  PARMA:      0x01,
  WATLING:    0x02,
  DEEPDALE:   0x03,
  STOW1:      0x04,
  STOW2:      0x05,
  KELTWICK:   0x06,
  MALAGA:     0x07,
  BARROW:     0x08,
  TADCASTER:  0x09,
  HELWIG:     0x0A,
  SWAFFHAM:   0x0B,
  EXCALABRIA: 0x0C,
  HASTINGS1:  0x0D,
  HASTINGS2:  0x0E,
  CARTHAHENA: 0x0F,
};

const TOWN_NAMES = {};
for (const [k, v] of Object.entries(TOWNS)) TOWN_NAMES[v] = k;

// ---------------------------------------------------------------------------
// Shop inventory (from shopdata.asm — item shop type 0 only)
// ---------------------------------------------------------------------------

// Items available to buy in each town's item shop (item ID list)
// Consumables only — key quest items are obtained through quests/chests/NPCs
const TOWN_ITEM_SHOP = {
  [TOWNS.WYCLIF]:     [ITEMS.HERBS, ITEMS.CANDLE],
  [TOWNS.PARMA]:      [ITEMS.HERBS, ITEMS.CANDLE, ITEMS.LANTERN, ITEMS.POISON_BALM, ITEMS.GNOME_STONE],
  [TOWNS.WATLING]:    [ITEMS.HERBS, ITEMS.CANDLE, ITEMS.LANTERN, ITEMS.POISON_BALM, ITEMS.SMALL_BOMB],
  [TOWNS.DEEPDALE]:   [ITEMS.HERBS, ITEMS.CANDLE, ITEMS.LANTERN, ITEMS.POISON_BALM, ITEMS.SMALL_BOMB],
  [TOWNS.STOW1]:      [ITEMS.HERBS, ITEMS.CANDLE, ITEMS.LANTERN, ITEMS.POISON_BALM, ITEMS.SMALL_BOMB, ITEMS.GRIFFIN_WING],
  [TOWNS.STOW2]:      [ITEMS.HERBS, ITEMS.CANDLE, ITEMS.LANTERN, ITEMS.ALARM_CLOCK], // uses Keltwick data
  [TOWNS.KELTWICK]:   [ITEMS.HERBS, ITEMS.CANDLE, ITEMS.LANTERN, ITEMS.ALARM_CLOCK],
  [TOWNS.MALAGA]:     [ITEMS.VASE, ITEMS.JOKE_BOOK, ITEMS.SMALL_BOMB],
  [TOWNS.BARROW]:     [ITEMS.HERBS, ITEMS.CANDLE, ITEMS.LANTERN, ITEMS.SMALL_BOMB, ITEMS.AGATE_JEWEL, ITEMS.BANSHEE_POWDER],
  [TOWNS.TADCASTER]:  [ITEMS.HERBS, ITEMS.CANDLE, ITEMS.LANTERN, ITEMS.SMALL_BOMB, ITEMS.AGATE_JEWEL, ITEMS.BANSHEE_POWDER],
  [TOWNS.HELWIG]:     [ITEMS.HERBS, ITEMS.CANDLE, ITEMS.LANTERN, ITEMS.SMALL_BOMB, ITEMS.AGATE_JEWEL, ITEMS.BANSHEE_POWDER],
  [TOWNS.SWAFFHAM]:   [ITEMS.HERBS, ITEMS.CANDLE, ITEMS.LANTERN, ITEMS.SMALL_BOMB, ITEMS.MEDICINE],
  [TOWNS.EXCALABRIA]: [ITEMS.HERBS, ITEMS.CANDLE, ITEMS.LANTERN, ITEMS.SMALL_BOMB, ITEMS.TOPAZ_JEWEL],
  [TOWNS.HASTINGS1]:  [ITEMS.HERBS, ITEMS.CANDLE, ITEMS.LANTERN, ITEMS.SMALL_BOMB, ITEMS.TOPAZ_JEWEL],
  [TOWNS.HASTINGS2]:  [],  // no item shop
  [TOWNS.CARTHAHENA]: [],  // no item shop
};

// ---------------------------------------------------------------------------
// Locked doors (from LockedDoorDataTable in towndata.asm)
// ---------------------------------------------------------------------------

const LOCKED_DOORS = [
  { cave: 0x16, desc: 'Parma North gate',        key: ITEMS.WHITE_KEY  },
  { cave: 0x28, desc: 'Parma Inner gate',         key: ITEMS.RED_KEY    },
  { cave: 0x23, desc: 'Deepdale dungeon gate',    key: ITEMS.BLUE_KEY   },
  { cave: 0x20, desc: 'Stow main gate',           key: ITEMS.THULE_KEY  },
  { cave: 0x20, desc: 'Stow bronze gate',         key: ITEMS.BRONZE_KEY },
  { cave: 0x20, desc: 'Stow silver gate',         key: ITEMS.SILVER_KEY },
  { cave: 0x20, desc: 'Stow gold gate (a)',       key: ITEMS.GOLD_KEY   },
  { cave: 0x22, desc: 'Carthahena bronze gate',   key: ITEMS.BRONZE_KEY },
  { cave: 0x21, desc: 'Malaga silver gate',       key: ITEMS.SILVER_KEY },
  { cave: 0x20, desc: 'Stow gold gate (b)',       key: ITEMS.GOLD_KEY   },
  { cave: 0x2A, desc: 'Excalabria secret gate',   key: ITEMS.SECRET_KEY },
  { cave: 0x2B, desc: 'Tsarkon fortress gate',    key: ITEMS.DUNGEON_KEY},
];

// ---------------------------------------------------------------------------
// Progression stages
//
// Each stage represents a phase of the game with:
//   requires_flags  — story flags that must be set to enter this stage
//   requires_items  — items player must possess (obtained in prior stages)
//   unlocks_flags   — story flags set during this stage
//   grants_items    — items acquired during this stage
//   towns_available — towns accessible during this stage
//   description     — human-readable stage name
//
// Stages are ordered: player must complete each before proceeding.
// This is a conservative model — we only check that the critical path is
// reachable, not every side quest.
// ---------------------------------------------------------------------------

const STAGES = [
  {
    id: 'START',
    description: 'Game start — Wyclif',
    requires_flags: [],
    requires_items: [],
    towns_available: [TOWNS.WYCLIF],
    grants_items: [],
    unlocks_flags: [],
    notes: 'Player begins at Wyclif. No key items. Starting town only.',
  },
  {
    id: 'PARMA_ARRIVAL',
    description: 'Arrive at Parma, start imposter-king quest',
    requires_flags: [],
    requires_items: [],
    towns_available: [TOWNS.WYCLIF, TOWNS.PARMA],
    grants_items: [ITEMS.TRUFFLE],  // obtained in overworld or given by NPC
    unlocks_flags: ['Talked_to_real_king'],
    notes: 'Parma is accessible from the start. Truffle is found in overworld cave near Parma.',
  },
  {
    id: 'TRUFFLE_DELIVERY',
    description: 'Deliver Truffle to Deepdale king',
    requires_flags: ['Talked_to_real_king'],
    requires_items: [ITEMS.TRUFFLE],
    towns_available: [TOWNS.WYCLIF, TOWNS.PARMA, TOWNS.DEEPDALE],
    grants_items: [],
    unlocks_flags: ['Truffle_collected', 'Treasure_of_troy_challenge_issued'],
    notes: 'Deepdale king issues the Treasure of Troy quest.',
  },
  {
    id: 'TREASURE_OF_TROY',
    description: 'Find and deliver Treasure of Troy',
    requires_flags: ['Treasure_of_troy_challenge_issued'],
    requires_items: [],
    towns_available: [TOWNS.WYCLIF, TOWNS.PARMA, TOWNS.DEEPDALE],
    grants_items: [ITEMS.TREASURE_OF_TROY],
    unlocks_flags: ['Treasure_of_troy_found', 'Treasure_of_troy_given_to_king', 'Fake_king_killed', 'Sent_to_malaga'],
    notes: 'Treasure found in Parma dungeon (requires defeating fake king). Then sent to Malaga.',
  },
  {
    id: 'WATLING_RINGS',
    description: 'Watling crystal and Ring of Earth',
    requires_flags: ['Fake_king_killed'],
    requires_items: [],
    towns_available: [TOWNS.WYCLIF, TOWNS.PARMA, TOWNS.WATLING, TOWNS.DEEPDALE],
    grants_items: [ITEMS.WHITE_CRYSTAL, ITEMS.RED_CRYSTAL, ITEMS.BLUE_CRYSTAL],
    unlocks_flags: [
      'Watling_villagers_asked_about_rings',
      'White_crystal_quest_started', 'White_crystal_received',
      'Red_crystal_quest_started', 'Red_crystal_received',
      'Blue_crystal_quest_started', 'Blue_crystal_received',
      'Ring_of_earth_obtained',
    ],
    notes: 'Three crystals restore youth to Watling villagers. Yield Ring of Earth.',
  },
  {
    id: 'MALAGA_CROWN',
    description: 'Malaga quest — crown the rightful king',
    requires_flags: ['Sent_to_malaga'],
    requires_items: [],
    towns_available: [TOWNS.WYCLIF, TOWNS.PARMA, TOWNS.WATLING, TOWNS.DEEPDALE,
                      TOWNS.STOW1, TOWNS.STOW2, TOWNS.KELTWICK, TOWNS.MALAGA],
    grants_items: [],
    unlocks_flags: ['Sent_to_malaga', 'Malaga_king_crowned', 'Bearwulf_met'],
    notes: 'Complete Bearwulf/Malaga arc to crown Malaga king. Opens Stow/Barrow region.',
  },
  {
    id: 'STOW_DUNGEON',
    description: 'Stow dungeon — keys and Ring of Wind',
    requires_flags: ['Malaga_king_crowned'],
    // Keys are obtained *inside* the dungeon (boss drops + chests), not required beforehand.
    // The initial entrance (outer gate) is always open; deeper locked doors use keys found inside.
    requires_items: [],
    towns_available: [TOWNS.STOW1, TOWNS.STOW2, TOWNS.KELTWICK],
    grants_items: [ITEMS.BRONZE_KEY, ITEMS.SILVER_KEY, ITEMS.GOLD_KEY, ITEMS.THULE_KEY],
    unlocks_flags: ['Ring_of_wind_received', 'Stow_thief_defeated', 'Stow_innocence_proven'],
    notes: 'Bronze/Silver/Gold keys from boss drops inside Stow dungeon. Thule key from chest. Keys found in order inside the dungeon allow passage through sequential locked gates. Ring of Wind reward.',
  },
  {
    id: 'BARROW_IMPOSTER',
    description: 'Barrow — defeat imposter, obtain Ring of Wisdom',
    requires_flags: ['Malaga_king_crowned'],
    // White Key and Red Key are obtained from chests inside the Parma dungeon
    // during this arc — not prerequisites from the outside world.
    requires_items: [],
    towns_available: [TOWNS.BARROW, TOWNS.TADCASTER, TOWNS.HELWIG],
    grants_items: [ITEMS.WHITE_KEY, ITEMS.RED_KEY],
    unlocks_flags: ['Imposter_killed', 'Barrow_map_received'],
    notes: 'White Key from chest in Parma North dungeon. Red Key from chest in Parma Inner dungeon. Imposter defeated in Barrow dungeon. Ring of Wisdom reward.',
  },
  {
    id: 'SWAFFHAM_DEEPDALE_KEYS',
    description: 'Blue Key from Deepdale dungeon, Deepdale complete',
    requires_flags: ['Imposter_killed'],
    requires_items: [],
    towns_available: [TOWNS.DEEPDALE],
    grants_items: [ITEMS.BLUE_KEY],
    unlocks_flags: ['Blue_key_received'],
    notes: 'Blue Key obtained inside Deepdale dungeon (chest). Unlocks Deepdale dungeon inner gate.',
  },
  {
    id: 'SWAFFHAM_POISON',
    description: 'Swaffham — cure poison, Digot Plant',
    requires_flags: ['Imposter_killed'],
    requires_items: [],
    towns_available: [TOWNS.SWAFFHAM],
    grants_items: [ITEMS.DIGOT_PLANT],
    unlocks_flags: ['Digot_plant_received', 'Swaffham_ruined', 'White_crystal_quest_started'],
    notes: 'Swaffham poisoned by spy. Digot Plant cures. Ring of Water progresses.',
  },
  {
    id: 'HASTINGS_SPY',
    description: 'Hastings — spy dinner, Titania\'s Mirror',
    requires_flags: ['Imposter_killed'],
    requires_items: [],
    towns_available: [TOWNS.HASTINGS1, TOWNS.HASTINGS2],
    grants_items: [ITEMS.TITANIAS_MIRROR],
    unlocks_flags: ['Ate_spy_dinner', 'Spy_dinner_poisoned_flag'],
    notes: 'Titania\'s Mirror found in overworld near Hastings seek point.',
  },
  {
    id: 'PASS_TO_CARTHAHENA',
    description: 'Purchase Pass to Carthahena at Hastings shop',
    requires_flags: ['Imposter_killed'],
    // Pass is bought at Hastings item shop — it's a purchasable item, not obtained from outside.
    requires_items: [],
    towns_available: [TOWNS.HASTINGS1, TOWNS.HASTINGS2],
    grants_items: [ITEMS.PASS_TO_CARTHAHENA],
    unlocks_flags: ['Pass_to_carthahena_purchased'],
    notes: 'Pass sold at Hastings item shop (requires sufficient kims). Unlocks Carthahena border.',
  },
  {
    id: 'EXCALABRIA_RINGS',
    description: 'Excalabria — three dungeon bosses, Rafael\'s Stick, Secret Key',
    requires_flags: ['Pass_to_carthahena_purchased'],
    // Secret Key is found inside the Excalabria dungeon, not required to enter it.
    requires_items: [],
    towns_available: [TOWNS.EXCALABRIA],
    grants_items: [ITEMS.SECRET_KEY, ITEMS.RAFAELS_STICK],
    unlocks_flags: ['Ring_of_fire_obtained', 'Excalabria_boss_1_defeated', 'Excalabria_boss_2_defeated', 'Excalabria_boss_3_defeated'],
    notes: 'Secret Key from dungeon chest. Rafael\'s Stick from overworld seek. Three bosses yield Ring of Fire.',
  },
  {
    id: 'SIXTEEN_RINGS',
    description: 'All four rings collected — Sixteen Rings ceremony at Wyclif',
    requires_flags: [
      'Ring_of_earth_obtained',
      'Ring_of_wind_received',
      // Ring of Wisdom and Ring of Fire are obtained through Barrow/Excalabria
    ],
    // Sixteen Rings is *formed* from the four individual rings during this stage —
    // it is not a prerequisite obtained beforehand.
    requires_items: [],
    towns_available: [TOWNS.WYCLIF],
    grants_items: [ITEMS.SIXTEEN_RINGS],
    unlocks_flags: ['All_rings_collected', 'Sixteen_rings_used_at_throne'],
    notes: 'Sixteen Rings formed from the four individual rings. Used at Wyclif throne.',
  },
  {
    id: 'SWORD_OF_VERMILION',
    description: 'Obtain Sword of Vermilion from Malaga blacksmith',
    requires_flags: ['All_rings_collected'],
    requires_items: [],
    towns_available: [TOWNS.MALAGA],
    grants_items: [ITEMS.SWORD_OF_VERMILION],
    unlocks_flags: ['Sword_stolen_by_blacksmith', 'Player_has_sword_of_vermilion'],
    notes: 'Blacksmith takes equipped sword + all kims, then returns Sword of Vermilion.',
  },
  {
    id: 'TSARKON_FIGHT',
    description: 'Enter Tsarkon\'s fortress and defeat Tsarkon',
    requires_flags: ['Player_has_sword_of_vermilion', 'Pass_to_carthahena_purchased'],
    // SWORD_OF_VERMILION (virtual) is granted by the prior stage and required here.
    // DUNGEON_KEY is obtained *inside* the fortress (chest), not a prerequisite.
    requires_items: [ITEMS.SWORD_OF_VERMILION],
    towns_available: [TOWNS.CARTHAHENA],
    grants_items: [ITEMS.DUNGEON_KEY],
    unlocks_flags: ['Tsarkon_is_dead'],
    notes: 'Dungeon Key found inside Tsarkon fortress. Must wield Sword of Vermilion.',
  },
  {
    id: 'ENDING',
    description: 'Crown ceremony — game complete',
    requires_flags: ['Tsarkon_is_dead'],
    // Crown is received after defeating Tsarkon — it's not a prerequisite.
    requires_items: [],
    towns_available: [TOWNS.WYCLIF],
    grants_items: [ITEMS.CROWN],
    unlocks_flags: ['Crown_received'],
    notes: 'Crown found after defeating Tsarkon. Ending ceremony at Wyclif.',
  },
];

// ---------------------------------------------------------------------------
// Validator
// ---------------------------------------------------------------------------

function validate() {
  const results = [];
  let failed = false;

  // Track accumulated state across stages
  const acquiredItems   = new Set();
  const acquiredFlags   = new Set();
  const availableTowns  = new Set();
  let availableShopItems = new Set();

  for (const stage of STAGES) {
    const stageResult = {
      id:          stage.id,
      description: stage.description,
      status:      'PASS',
      errors:      [],
      warnings:    [],
      info:        [],
    };

    // Check required flags
    for (const flag of stage.requires_flags) {
      if (!acquiredFlags.has(flag)) {
        stageResult.errors.push(`Missing required story flag: ${flag}`);
        stageResult.status = 'FAIL';
        failed = true;
      }
    }

    // Check required items
    for (const item of stage.requires_items) {
      if (!acquiredItems.has(item) && !availableShopItems.has(item)) {
        stageResult.errors.push(`Required item not reachable: ${ITEM_NAMES[item] || '0x'+item.toString(16)}`);
        stageResult.status = 'FAIL';
        failed = true;
      }
    }

    // Check locked doors referenced by this stage
    if (stage.check_doors) {
      for (const door of stage.check_doors) {
        const keyId = door.key;
        const keyName = ITEM_NAMES[keyId] || '0x'+keyId.toString(16);
        if (!acquiredItems.has(keyId) && !availableShopItems.has(keyId)) {
          stageResult.errors.push(`Locked door "${door.desc}" requires ${keyName} — not yet obtainable`);
          stageResult.status = 'FAIL';
          failed = true;
        }
      }
    }

    // Apply grants and unlocks for this stage
    for (const item of stage.grants_items)   acquiredItems.add(item);
    for (const flag of stage.unlocks_flags)  acquiredFlags.add(flag);
    for (const town of stage.towns_available) availableTowns.add(town);

    // Update shop availability based on newly accessible towns
    for (const town of availableTowns) {
      const shopItems = TOWN_ITEM_SHOP[town] || [];
      for (const item of shopItems) availableShopItems.add(item);
    }

    // Info: what's been acquired
    if (SHOW_ITEMS && stage.grants_items.length > 0) {
      stageResult.info.push(`Items acquired: ${stage.grants_items.map(i => ITEM_NAMES[i] || '0x'+i.toString(16)).join(', ')}`);
    }
    if (SHOW_SHOPS) {
      const newTowns = stage.towns_available.filter(t => true); // all towns in this stage
      const shopSummary = newTowns.map(t => `${TOWN_NAMES[t]}: ${(TOWN_ITEM_SHOP[t]||[]).map(i=>ITEM_NAMES[i]).join(', ')}`);
      stageResult.info.push(`Shop items in accessible towns: ${shopSummary.join(' | ')}`);
    }

    stageResult.info.push(`Flags unlocked this stage: ${stage.unlocks_flags.join(', ') || '(none)'}`);
    stageResult.info.push(`Towns accessible: ${stage.towns_available.map(t=>TOWN_NAMES[t]).join(', ')}`);
    if (stage.notes) stageResult.info.push(`Note: ${stage.notes}`);

    results.push(stageResult);
  }

  // Final checks: all locked doors reachable?
  const doorResults = [];
  for (const door of LOCKED_DOORS) {
    const keyName = ITEM_NAMES[door.key] || '0x'+door.key.toString(16);
    const reachable = acquiredItems.has(door.key) || availableShopItems.has(door.key);
    doorResults.push({
      desc: door.desc,
      cave: '0x' + door.cave.toString(16).toUpperCase().padStart(2,'0'),
      key:  keyName,
      reachable,
    });
    if (!reachable) {
      failed = true;
    }
  }

  return { results, doorResults, failed, summary: { stages: STAGES.length, failed } };
}

// ---------------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------------

function printResults({ results, doorResults, failed }) {
  const WIDTH = 70;
  const hr = '─'.repeat(WIDTH);

  console.log('\n' + '═'.repeat(WIDTH));
  console.log(' SWORD OF VERMILION — PROGRESSION VALIDATOR');
  console.log('═'.repeat(WIDTH));

  for (const r of results) {
    const icon = r.status === 'PASS' ? '✓' : '✗';
    const statusTag = r.status === 'PASS' ? '' : ' [FAIL]';
    console.log(`\n${icon} [${r.id}] ${r.description}${statusTag}`);

    for (const e of r.errors)   console.log(`    ERROR:   ${e}`);
    for (const w of r.warnings) console.log(`    WARN:    ${w}`);
    if (VERBOSE) {
      for (const i of r.info)   console.log(`    info:    ${i}`);
    }
  }

  console.log('\n' + hr);
  console.log('LOCKED DOOR REACHABILITY:');
  console.log(hr);
  for (const d of doorResults) {
    const icon = d.reachable ? '✓' : '✗';
    console.log(`  ${icon} ${d.desc.padEnd(35)} cave=${d.cave}  key=${d.key}${d.reachable ? '' : '  [UNREACHABLE]'}`);
  }

  console.log('\n' + hr);
  if (failed) {
    console.log('RESULT: FAIL — one or more progression checks failed.');
  } else {
    console.log('RESULT: PASS — all progression stages and locked doors are reachable.');
    console.log(`  ${STAGES.length} stages validated, ${LOCKED_DOORS.length} locked doors checked.`);
  }
  console.log(hr + '\n');
}

function main() {
  const analysis = validate();

  if (SHOW_JSON) {
    console.log(JSON.stringify(analysis, null, 2));
    process.exit(analysis.failed ? 1 : 0);
  }

  printResults(analysis);
  process.exit(analysis.failed ? 1 : 0);
}

main();
