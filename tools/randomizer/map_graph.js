'use strict';

const {
  MAP_HEIGHT,
  MAP_WIDTH,
  WORLD_SECTOR_COLS,
  WORLD_SECTOR_ROWS,
  WORLD_TILE_HEIGHT,
  WORLD_TILE_WIDTH,
  isWalkableTile,
  loadOverworldSectors,
} = require('./map_utils');
const { floodFill, shortestPath, toIndex, toXY } = require('./pathfinder');

let cachedVanillaPlacements = null;
let cachedVanillaAnalysis = null;

function buildVanillaPlacements() {
  if (!cachedVanillaPlacements) {
    cachedVanillaPlacements = loadOverworldSectors().map((sector) => ({
      slotX: sector.slotX,
      slotY: sector.slotY,
      sourceX: sector.slotX,
      sourceY: sector.slotY,
      fixed: sector.hasSpecials,
      sector,
    }));
  }
  return cachedVanillaPlacements.map((placement) => ({ ...placement }));
}

function placementsBySlot(placements) {
  const bySlot = new Map();
  for (const placement of placements) {
    bySlot.set(`${placement.slotX},${placement.slotY}`, placement);
  }
  return bySlot;
}

function serializeLayout(placements) {
  const bySlot = placementsBySlot(placements);
  const rows = [];
  for (let y = 0; y < WORLD_SECTOR_ROWS; y += 1) {
    const row = [];
    for (let x = 0; x < WORLD_SECTOR_COLS; x += 1) {
      const placement = bySlot.get(`${x},${y}`);
      if (!placement) {
        row.push({
          slotId: `${x},${y}`,
          slotX: x,
          slotY: y,
          sourceId: null,
          sourceX: null,
          sourceY: null,
          moved: false,
          fixed: true,
          specialCount: 0,
          missing: true,
        });
        continue;
      }
      row.push({
        slotId: `${x},${y}`,
        slotX: x,
        slotY: y,
        sourceId: `${placement.sourceX},${placement.sourceY}`,
        sourceX: placement.sourceX,
        sourceY: placement.sourceY,
        moved: placement.sourceX !== x || placement.sourceY !== y,
        fixed: placement.fixed,
        specialCount: placement.sector.specials.length,
        missing: false,
      });
    }
    rows.push(row);
  }
  return { rows };
}

function buildWorld(placements) {
  const worldTiles = new Uint8Array(WORLD_TILE_WIDTH * WORLD_TILE_HEIGHT);
  const specialNodes = [];

  for (const placement of placements) {
    const baseX = placement.slotX * MAP_WIDTH;
    const baseY = placement.slotY * MAP_HEIGHT;
    const tiles = placement.sector.tiles;

    for (let localY = 0; localY < MAP_HEIGHT; localY += 1) {
      for (let localX = 0; localX < MAP_WIDTH; localX += 1) {
        const tile = tiles[localY * MAP_WIDTH + localX];
        const worldX = baseX + localX;
        const worldY = baseY + localY;
        worldTiles[toIndex(worldX, worldY, WORLD_TILE_WIDTH)] = tile;
      }
    }

    for (const special of placement.sector.specials) {
      specialNodes.push({
        key: special.key,
        label: special.label,
        kind: special.kind,
        slotX: placement.slotX,
        slotY: placement.slotY,
        sourceX: placement.sourceX,
        sourceY: placement.sourceY,
        localX: special.col,
        localY: special.row,
        worldX: baseX + special.col,
        worldY: baseY + special.row,
      });
    }
  }

  return { worldTiles, specialNodes };
}

function analyzeLayout(placements) {
  const { worldTiles, specialNodes } = buildWorld(placements);
  const startNode = specialNodes.find((node) => node.key === 'town:0') || specialNodes[0] || null;

  const analysis = {
    layout: serializeLayout(placements),
    start: startNode ? { key: startNode.key, label: startNode.label, worldX: startNode.worldX, worldY: startNode.worldY } : null,
    specialNodes: [],
    reachableKeys: [],
    unreachableKeys: [],
    summary: {
      specialCount: specialNodes.length,
      reachableSpecials: 0,
      unreachableSpecials: 0,
    },
    sampleRoutes: [],
  };

  if (!startNode) {
    return analysis;
  }

  const startIndex = toIndex(startNode.worldX, startNode.worldY, WORLD_TILE_WIDTH);
  const fill = floodFill({
    width: WORLD_TILE_WIDTH,
    height: WORLD_TILE_HEIGHT,
    startIndices: [startIndex],
    canVisit(index) {
      return isWalkableTile(worldTiles[index]);
    },
  });

  for (const node of specialNodes) {
    const index = toIndex(node.worldX, node.worldY, WORLD_TILE_WIDTH);
    const reachable = !!fill.visited[index];
    const entry = {
      key: node.key,
      label: node.label,
      kind: node.kind,
      slotX: node.slotX,
      slotY: node.slotY,
      sourceX: node.sourceX,
      sourceY: node.sourceY,
      worldX: node.worldX,
      worldY: node.worldY,
      reachable,
      distance: fill.distance[index],
    };
    analysis.specialNodes.push(entry);
    if (reachable) analysis.reachableKeys.push(node.key);
    else analysis.unreachableKeys.push(node.key);
  }

  analysis.summary.reachableSpecials = analysis.reachableKeys.length;
  analysis.summary.unreachableSpecials = analysis.unreachableKeys.length;

  const routed = analysis.specialNodes
    .filter((node) => node.reachable && node.key !== startNode.key)
    .sort((a, b) => a.distance - b.distance)
    .slice(0, 5);

  for (const node of routed) {
    const goalIndex = toIndex(node.worldX, node.worldY, WORLD_TILE_WIDTH);
    const path = shortestPath({
      width: WORLD_TILE_WIDTH,
      height: WORLD_TILE_HEIGHT,
      startIndex,
      goalIndex,
      canVisit(index) {
        return isWalkableTile(worldTiles[index]);
      },
    });
    if (!path) continue;
    analysis.sampleRoutes.push({
      to: node.label,
      steps: path.length - 1,
      path: path.slice(0, 10).map((index) => toXY(index, WORLD_TILE_WIDTH)),
    });
  }

  return analysis;
}

function getVanillaAnalysis() {
  if (!cachedVanillaAnalysis) {
    cachedVanillaAnalysis = analyzeLayout(buildVanillaPlacements());
  }
  return cachedVanillaAnalysis;
}

function compareLayoutToVanilla(placements) {
  const vanilla = getVanillaAnalysis();
  const candidate = analyzeLayout(placements);
  const vanillaReachable = new Set(vanilla.reachableKeys);
  const candidateReachable = new Set(candidate.reachableKeys);

  const missingReachable = vanilla.reachableKeys.filter((key) => !candidateReachable.has(key));
  const unexpectedReachable = candidate.reachableKeys.filter((key) => !vanillaReachable.has(key));

  return {
    ok: missingReachable.length === 0 && unexpectedReachable.length === 0,
    missingReachable,
    unexpectedReachable,
    baselineReachable: vanilla.summary.reachableSpecials,
    candidateReachable: candidate.summary.reachableSpecials,
    candidate,
  };
}

module.exports = {
  analyzeLayout,
  buildVanillaPlacements,
  buildWorld,
  compareLayoutToVanilla,
  getVanillaAnalysis,
  serializeLayout,
};
