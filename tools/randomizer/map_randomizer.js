#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const {
  MAP_HEIGHT,
  MAP_WIDTH,
  OVERWORLD_DIR,
  PROJECT_ROOT,
  TOOLS_DATA_DIR,
  cloneTiles,
  compressRLE,
  getSpecials,
  isWalkableTile,
} = require('./map_utils');
const { buildVanillaPlacements, buildWorld, compareLayoutToVanilla } = require('./map_graph');
const { floodFill, toIndex } = require('./pathfinder');
const {
  CRITICAL_CAVE_IDS,
  CRITICAL_TOWN_IDS,
  TOWN_NAMES,
  TOWN_OVERWORLD_COORDS,
  TOWN_TELEPORT_COORDS,
} = require('./map_runtime_tables');

const MODULE_ID = 6;
const WALL_TILES = new Set([0x01, 0x02, 0x03, 0x04, 0x05, 0x08, 0x09, 0x0A, 0x0F]);

function xorshift32(state) {
  state = state >>> 0;
  state ^= state << 13;
  state ^= state >>> 17;
  state ^= state << 5;
  return state >>> 0;
}

function makePrng(seed) {
  let state = (seed ^ (MODULE_ID * 0x9E3779B9)) >>> 0;
  if (state === 0) state = 1;
  return {
    next() {
      state = xorshift32(state);
      return state;
    },
    int(min, max) {
      return min + (this.next() % (max - min + 1));
    },
  };
}

function shuffle(array, rng) {
  for (let index = array.length - 1; index > 0; index -= 1) {
    const other = rng.int(0, index);
    [array[index], array[other]] = [array[other], array[index]];
  }
}

function clonePlacements(placements) {
  return placements.map((placement) => ({
    ...placement,
    sector: {
      ...placement.sector,
      tiles: cloneTiles(placement.sector.tiles),
      specials: placement.sector.specials.map((special) => ({ ...special })),
    },
  }));
}

function toLocalIndex(x, y) {
  return y * MAP_WIDTH + x;
}

function inBounds(x, y) {
  return x >= 0 && x < MAP_WIDTH && y >= 0 && y < MAP_HEIGHT;
}

function walkableBoundaryAnchors(tiles) {
  const anchors = [];
  const seen = new Set();

  function collect(points) {
    let run = [];
    for (const point of points) {
      const open = isWalkableTile(tiles[toLocalIndex(point.x, point.y)]);
      if (open) {
        run.push(point);
        continue;
      }
      if (run.length > 0) {
        const mid = run[Math.floor(run.length / 2)];
        const key = `${mid.x},${mid.y}`;
        if (!seen.has(key)) {
          anchors.push(mid);
          seen.add(key);
        }
        run = [];
      }
    }
    if (run.length > 0) {
      const mid = run[Math.floor(run.length / 2)];
      const key = `${mid.x},${mid.y}`;
      if (!seen.has(key)) {
        anchors.push(mid);
        seen.add(key);
      }
    }
  }

  collect(Array.from({ length: MAP_WIDTH }, (_, x) => ({ x, y: 0 })));
  collect(Array.from({ length: MAP_WIDTH }, (_, x) => ({ x, y: MAP_HEIGHT - 1 })));
  collect(Array.from({ length: MAP_HEIGHT }, (_, y) => ({ x: 0, y })));
  collect(Array.from({ length: MAP_HEIGHT }, (_, y) => ({ x: MAP_WIDTH - 1, y })));

  return anchors;
}

function carvePath(tiles, start, end, rng) {
  let x = start.x;
  let y = start.y;

  while (x !== end.x || y !== end.y) {
    tiles[toLocalIndex(x, y)] = 0x06;
    const options = [];
    if (x !== end.x) options.push({ x: x + Math.sign(end.x - x), y });
    if (y !== end.y) options.push({ x, y: y + Math.sign(end.y - y) });
    options.sort(() => (rng.int(0, 1) === 0 ? -1 : 1));
    const next = options[0];
    x = next.x;
    y = next.y;
  }
  tiles[toLocalIndex(end.x, end.y)] = 0x06;
}

function decorateSector(seed, placement) {
  const rng = makePrng(seed ^ ((placement.slotX + 1) << 8) ^ ((placement.slotY + 1) << 16));
  const tiles = cloneTiles(placement.sector.tiles);
  const anchors = walkableBoundaryAnchors(tiles);
  if (anchors.length < 2) return null;

  const hub = { x: rng.int(4, 11), y: rng.int(4, 11) };
  for (const anchor of anchors) {
    carvePath(tiles, anchor, hub, rng);
  }

  const loops = rng.int(1, 3);
  for (let i = 0; i < loops; i += 1) {
    carvePath(tiles, hub, { x: rng.int(2, 13), y: rng.int(2, 13) }, rng);
  }

  for (let y = 1; y < MAP_HEIGHT - 1; y += 1) {
    for (let x = 1; x < MAP_WIDTH - 1; x += 1) {
      const index = toLocalIndex(x, y);
      if (tiles[index] === 0x06) continue;
      if (rng.int(0, 99) < 12) tiles[index] = rng.int(0, 1) === 0 ? 0x0B : 0x0E;
    }
  }

  return {
    ...placement.sector,
    id: `generated:${placement.slotX},${placement.slotY}`,
    tiles,
    specials: getSpecials(tiles),
    generated: true,
  };
}

function sameAnchorType(a, b) {
  if (a.kind !== b.kind) return false;
  if (a.kind === 'town') {
    return CRITICAL_TOWN_IDS.has(a.id) === CRITICAL_TOWN_IDS.has(b.id);
  }
  if (a.kind === 'cave') {
    return CRITICAL_CAVE_IDS.has(a.id) === CRITICAL_CAVE_IDS.has(b.id);
  }
  return true;
}

function collectAnchorPlacements(placements) {
  return placements.flatMap((placement) => placement.sector.specials.map((special) => ({ placement, special })));
}

function swapSpecialSectors(seed, placements) {
  const rng = makePrng(seed ^ 0xCAFE1234);
  let current = clonePlacements(placements);
  const anchors = collectAnchorPlacements(current);
  const swapLog = [];

  for (let attempt = 0; attempt < 300 && swapLog.length < 4; attempt += 1) {
    const a = anchors[rng.int(0, anchors.length - 1)];
    const b = anchors[rng.int(0, anchors.length - 1)];
    if (a.placement.slotX === b.placement.slotX && a.placement.slotY === b.placement.slotY) continue;
    if (!sameAnchorType(a.special, b.special)) continue;

    const candidate = clonePlacements(current);
    const indexA = candidate.findIndex((entry) => entry.slotX === a.placement.slotX && entry.slotY === a.placement.slotY);
    const indexB = candidate.findIndex((entry) => entry.slotX === b.placement.slotX && entry.slotY === b.placement.slotY);
    const sectorA = candidate[indexA].sector;
    const sectorB = candidate[indexB].sector;

    candidate[indexA].sector = sectorB;
    candidate[indexA].sourceX = b.placement.sourceX;
    candidate[indexA].sourceY = b.placement.sourceY;
    candidate[indexB].sector = sectorA;
    candidate[indexB].sourceX = a.placement.sourceX;
    candidate[indexB].sourceY = a.placement.sourceY;

    const validation = compareLayoutToVanilla(candidate);
    if (!validation.ok) continue;

    current = candidate;
    swapLog.push({
      slotA: `${candidate[indexA].slotX},${candidate[indexA].slotY}`,
      slotB: `${candidate[indexB].slotX},${candidate[indexB].slotY}`,
      kind: a.special.kind,
      id: a.special.id,
    });
  }

  return { placements: current, swapLog };
}

function generateLayout(seed) {
  const rng = makePrng(seed);
  const vanillaPlacements = clonePlacements(buildVanillaPlacements());
  let placements = clonePlacements(vanillaPlacements);
  const movable = placements.map((placement, index) => ({ placement, index })).filter((entry) => entry.placement.sector.specials.length === 0);
  const swapLog = [];

  for (let attempt = 0; attempt < 500 && swapLog.length < 8; attempt += 1) {
    const a = movable[rng.int(0, movable.length - 1)].index;
    const b = movable[rng.int(0, movable.length - 1)].index;
    if (a === b) continue;

    const candidate = clonePlacements(placements);
    const sectorA = candidate[a].sector;
    const sectorB = candidate[b].sector;
    candidate[a].sector = sectorB;
    candidate[a].sourceX = sectorB.slotX;
    candidate[a].sourceY = sectorB.slotY;
    candidate[b].sector = sectorA;
    candidate[b].sourceX = sectorA.slotX;
    candidate[b].sourceY = sectorA.slotY;

    const validation = compareLayoutToVanilla(candidate);
    if (!validation.ok) continue;
    placements = candidate;
    swapLog.push({ slotA: `${candidate[a].slotX},${candidate[a].slotY}`, slotB: `${candidate[b].slotX},${candidate[b].slotY}` });
  }

  const specialSwap = swapSpecialSectors(seed, placements);
  placements = specialSwap.placements;

  const decorCandidates = placements
    .map((placement, index) => ({ placement, index }))
    .filter((entry) => entry.placement.sector.specials.length === 0);
  shuffle(decorCandidates, makePrng(seed ^ 0x7E57));
  const generatedSlots = [];

  for (const entry of decorCandidates) {
    if (generatedSlots.length >= 6) break;
    const candidate = clonePlacements(placements);
    const decorated = decorateSector(seed + generatedSlots.length, candidate[entry.index]);
    if (!decorated) continue;
    candidate[entry.index].sector = decorated;
    const validation = compareLayoutToVanilla(candidate);
    if (!validation.ok) continue;
    placements = candidate;
    generatedSlots.push(`${candidate[entry.index].slotX},${candidate[entry.index].slotY}`);
  }

  const finalStageValidation = stageAwareValidation(placements);
  if (!finalStageValidation.ok) {
    return {
      placements: vanillaPlacements,
      swapLog: [],
      specialSwapLog: [],
      generatedSlots: [],
      fallback: {
        reason: 'stage_validation_failed',
        failedStage: finalStageValidation.failedStage,
        failedKeys: finalStageValidation.failedKeys,
      },
    };
  }

  return {
    placements,
    swapLog,
    specialSwapLog: specialSwap.swapLog,
    generatedSlots,
    fallback: null,
  };
}

function buildWarpTables(placements) {
  const towns = [];
  const caves = [];

  for (const placement of placements) {
    for (const special of placement.sector.specials) {
      const entry = {
        id: special.id,
        kind: special.kind,
        label: special.kind === 'town' ? TOWN_NAMES[special.id] : `Cave-${special.id.toString(16).toUpperCase()}`,
        slotX: placement.slotX,
        slotY: placement.slotY,
        x: special.col,
        y: special.row,
      };
      if (special.kind === 'town') towns.push(entry);
      if (special.kind === 'cave') caves.push(entry);
    }
  }

  towns.sort((a, b) => a.id - b.id);
  caves.sort((a, b) => a.id - b.id);

  const teleportTable = TOWN_TELEPORT_COORDS.map((coords, id) => {
    const moved = towns.find((town) => town.id === id);
    return moved ? [moved.x, moved.y, moved.slotX, moved.slotY] : coords;
  });

  const ariesTable = TOWN_OVERWORLD_COORDS.map((coords, index) => {
    const sourceTownId = index >= 4 ? index + 1 : index;
    const moved = towns.find((town) => town.id === sourceTownId);
    return moved ? [moved.x, moved.y, moved.slotX, moved.slotY] : coords;
  });

  return { towns, caves, teleportTable, ariesTable };
}

const STAGE_REQUIREMENTS = [
  { id: 'START', required: ['town:0'] },
  { id: 'PARMA', required: ['town:1', 'cave:0'] },
  { id: 'WATLING_ROUTE', required: ['town:2', 'cave:1', 'cave:3'] },
  { id: 'MALAGA_ROUTE', required: ['town:7', 'town:6', 'cave:5', 'cave:9'] },
  { id: 'BARROW_ROUTE', required: ['town:8', 'town:9', 'town:10', 'town:11'] },
  { id: 'LATE_GAME', required: ['town:12', 'town:13', 'cave:11', 'cave:15'] },
];

function stageAwareValidation(placements) {
  const { worldTiles, specialNodes } = buildWorld(placements);
  const start = specialNodes.find((node) => node.key === 'town:0');
  if (!start) {
    return { ok: false, failedStage: 'START', failedKeys: ['town:0'], stages: [] };
  }

  const fill = floodFill({
    width: 16 * MAP_WIDTH,
    height: 8 * MAP_HEIGHT,
    startIndices: [toIndex(start.worldX, start.worldY, 16 * MAP_WIDTH)],
    canVisit(index) {
      return isWalkableTile(worldTiles[index]);
    },
  });

  const stageResults = [];
  for (const stage of STAGE_REQUIREMENTS) {
    const missing = [];
    for (const key of stage.required) {
      const node = specialNodes.find((entry) => entry.key === key);
      if (!node) {
        missing.push(key);
        continue;
      }
      const reachable = !!fill.visited[toIndex(node.worldX, node.worldY, 16 * MAP_WIDTH)];
      if (!reachable) missing.push(key);
    }
    stageResults.push({ id: stage.id, required: stage.required, missing, ok: missing.length === 0 });
    if (missing.length > 0) {
      return { ok: false, failedStage: stage.id, failedKeys: missing, stages: stageResults };
    }
  }

  return { ok: true, failedStage: null, failedKeys: [], stages: stageResults };
}

function writeRandomizedAssets(manifest, applyAssets) {
  const assetDir = path.join(TOOLS_DATA_DIR, 'randomized_maps_assets');
  fs.mkdirSync(assetDir, { recursive: true });

  for (const asset of manifest.assetLayout) {
    const buffer = compressRLE(Uint8Array.from(asset.tiles));
    fs.writeFileSync(path.join(assetDir, `sector_${asset.slotX}_${asset.slotY}.bin`), buffer);
    if (applyAssets) {
      fs.writeFileSync(path.join(OVERWORLD_DIR, `sector_${asset.slotX}_${asset.slotY}.bin`), buffer);
    }
  }

  return assetDir;
}

function buildManifest(seed) {
  const generated = generateLayout(seed);
  const placements = generated.placements;
  const vanillaValidation = compareLayoutToVanilla(placements);
  const stageValidation = stageAwareValidation(placements);
  const warpTables = buildWarpTables(placements);

  const movedSectors = placements
    .filter((placement) => placement.sourceX !== placement.slotX || placement.sourceY !== placement.slotY)
    .map((placement) => ({ slotId: `${placement.slotX},${placement.slotY}`, sourceId: `${placement.sourceX},${placement.sourceY}`, fixed: placement.sector.specials.length > 0 }));

  return {
    seed,
    mode: 'special-shuffle-generated',
    summary: {
      totalSectors: placements.length,
      fixedSectors: placements.filter((placement) => placement.sector.specials.length > 0).length,
      movableSectors: placements.filter((placement) => placement.sector.specials.length === 0).length,
      movedSectors: movedSectors.length,
      generatedSectors: generated.generatedSlots.length,
      fillerSwaps: generated.swapLog.length,
      specialSwaps: generated.specialSwapLog.length,
      reachableSpecials: vanillaValidation.candidate.summary.reachableSpecials,
      unreachableSpecials: vanillaValidation.candidate.summary.unreachableSpecials,
      valid: vanillaValidation.ok && stageValidation.ok,
    },
    notes: [
      'Special sectors can now relocate when stage-aware and vanilla reachability validation still passes.',
      'Generated filler sectors carve road-heavy loops while preserving boundary connectivity.',
      'Warp export includes town teleport and Aries tables based on the new overworld positions.',
    ],
    fallback: generated.fallback,
    swaps: generated.swapLog,
    specialSwaps: generated.specialSwapLog,
    generatedSlots: generated.generatedSlots,
    movedSectors,
    validation: {
      ok: vanillaValidation.ok && stageValidation.ok,
      missingReachable: vanillaValidation.missingReachable,
      unexpectedReachable: vanillaValidation.unexpectedReachable,
      baselineReachable: vanillaValidation.baselineReachable,
      candidateReachable: vanillaValidation.candidateReachable,
      sampleRoutes: vanillaValidation.candidate.sampleRoutes,
      start: vanillaValidation.candidate.start,
      specialNodes: vanillaValidation.candidate.specialNodes,
      stageValidation,
    },
    layout: vanillaValidation.candidate.layout,
    warpTables,
    assetLayout: placements.map((placement) => ({
      slotX: placement.slotX,
      slotY: placement.slotY,
      sourceId: `${placement.sourceX},${placement.sourceY}`,
      moved: placement.sourceX !== placement.slotX || placement.sourceY !== placement.slotY,
      generated: !!placement.sector.generated,
      tiles: Array.from(placement.sector.tiles),
    })),
  };
}

const args = process.argv.slice(2);
const HELP = args.includes('--help');
const DRY_RUN = args.includes('--dry-run');
const JSON_OUT = args.includes('--json');
const APPLY = args.includes('--apply');
const WRITE_ASSETS = args.includes('--write-assets') || APPLY;

function getArg(flag, fallback) {
  const index = args.indexOf(flag);
  return index >= 0 && args[index + 1] !== undefined ? args[index + 1] : fallback;
}

if (HELP) {
  console.log('Usage: node tools/randomizer/map_randomizer.js --seed N [--dry-run] [--json] [--write-assets] [--apply]');
  process.exit(0);
}

const seedArg = getArg('--seed', null);
if (!seedArg) {
  console.error('Error: --seed N is required');
  process.exit(1);
}

const exportPath = getArg('--export', path.join('tools', 'data', 'randomized_maps.json'));
const assetDirArg = getArg('--asset-dir', path.join('tools', 'data', 'randomized_maps_assets'));
const seed = parseInt(seedArg, 10) >>> 0;
const manifest = buildManifest(seed);

if (JSON_OUT) {
  console.log(JSON.stringify(manifest, null, 2));
  process.exit(manifest.validation.ok ? 0 : 1);
}

console.log(`Map randomizer — seed=${manifest.seed} mode=${manifest.mode}`);
console.log(`  Fixed critical sectors : ${manifest.summary.fixedSectors}`);
console.log(`  Movable filler sectors : ${manifest.summary.movableSectors}`);
console.log(`  Sectors moved          : ${manifest.summary.movedSectors}`);
console.log(`  Generated sectors      : ${manifest.summary.generatedSectors}`);
console.log(`  Filler swaps           : ${manifest.summary.fillerSwaps}`);
console.log(`  Special swaps          : ${manifest.summary.specialSwaps}`);
console.log(`  Reachable specials     : ${manifest.summary.reachableSpecials}`);
if (manifest.fallback) {
  console.log(`  Fallback               : ${manifest.fallback.reason} (${manifest.fallback.failedStage}: ${manifest.fallback.failedKeys.join(', ')})`);
}

if (!manifest.validation.ok) {
  console.log('  Validation             : FAIL');
  if (manifest.validation.missingReachable.length) console.log(`  Missing reachable      : ${manifest.validation.missingReachable.join(', ')}`);
  if (!manifest.validation.stageValidation.ok) console.log(`  Failed stage           : ${manifest.validation.stageValidation.failedStage} (${manifest.validation.stageValidation.failedKeys.join(', ')})`);
  process.exit(1);
}

console.log('  Validation             : PASS');
manifest.movedSectors.slice(0, 12).forEach((entry) => {
  console.log(`    slot ${entry.slotId.padEnd(5)} <= sector ${entry.sourceId}`);
});
if (manifest.movedSectors.length > 12) console.log(`    ... ${manifest.movedSectors.length - 12} more moved sectors`);

if (DRY_RUN) {
  console.log('Dry run complete — no files written.');
  process.exit(0);
}

const absoluteExportPath = path.join(PROJECT_ROOT, exportPath);
fs.writeFileSync(absoluteExportPath, JSON.stringify(manifest, null, 2) + '\n', 'utf8');
const originalToolsDataDir = TOOLS_DATA_DIR;
const targetAssetDir = path.join(PROJECT_ROOT, assetDirArg);
function writeRandomizedAssetsToDir(localManifest, assetDir, applyAssets) {
  fs.mkdirSync(assetDir, { recursive: true });
  for (const asset of localManifest.assetLayout) {
    const buffer = compressRLE(Uint8Array.from(asset.tiles));
    fs.writeFileSync(path.join(assetDir, `sector_${asset.slotX}_${asset.slotY}.bin`), buffer);
    if (applyAssets) {
      fs.writeFileSync(path.join(OVERWORLD_DIR, `sector_${asset.slotX}_${asset.slotY}.bin`), buffer);
    }
  }
  return assetDir;
}
const assetDir = writeRandomizedAssetsToDir(manifest, targetAssetDir, WRITE_ASSETS);
console.log(`Wrote preview manifest to ${path.relative(PROJECT_ROOT, absoluteExportPath)}`);
console.log(`Wrote randomized sector assets to ${path.relative(PROJECT_ROOT, assetDir)}`);
if (WRITE_ASSETS) console.log(`Applied randomized sector binaries into ${path.relative(PROJECT_ROOT, OVERWORLD_DIR)}.`);
else console.log('Asset export only; pass --write-assets or --apply to patch live sector binaries.');
