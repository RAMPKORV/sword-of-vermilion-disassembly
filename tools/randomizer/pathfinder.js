'use strict';

function toIndex(x, y, width) {
  return y * width + x;
}

function toXY(index, width) {
  return {
    x: index % width,
    y: Math.floor(index / width),
  };
}

function forEachNeighbor(index, width, height, visit) {
  const x = index % width;
  const y = Math.floor(index / width);

  if (x > 0) visit(index - 1);
  if (x + 1 < width) visit(index + 1);
  if (y > 0) visit(index - width);
  if (y + 1 < height) visit(index + width);
}

function floodFill(options) {
  const { width, height, startIndices, canVisit } = options;
  const size = width * height;
  const visited = new Uint8Array(size);
  const distance = new Int32Array(size);
  distance.fill(-1);

  const queue = [];
  for (const index of startIndices) {
    if (index < 0 || index >= size) continue;
    if (!canVisit(index) || visited[index]) continue;
    visited[index] = 1;
    distance[index] = 0;
    queue.push(index);
  }

  for (let head = 0; head < queue.length; head += 1) {
    const current = queue[head];
    forEachNeighbor(current, width, height, (next) => {
      if (visited[next] || !canVisit(next)) return;
      visited[next] = 1;
      distance[next] = distance[current] + 1;
      queue.push(next);
    });
  }

  return { visited, distance };
}

function connectedComponents(options) {
  const { width, height, canVisit } = options;
  const size = width * height;
  const componentIds = new Int32Array(size);
  componentIds.fill(-1);

  let componentCount = 0;
  const queue = [];

  for (let index = 0; index < size; index += 1) {
    if (componentIds[index] !== -1 || !canVisit(index)) continue;

    componentIds[index] = componentCount;
    queue.length = 0;
    queue.push(index);

    for (let head = 0; head < queue.length; head += 1) {
      const current = queue[head];
      forEachNeighbor(current, width, height, (next) => {
        if (componentIds[next] !== -1 || !canVisit(next)) return;
        componentIds[next] = componentCount;
        queue.push(next);
      });
    }

    componentCount += 1;
  }

  return { componentIds, componentCount };
}

function shortestPath(options) {
  const { width, height, startIndex, goalIndex, canVisit } = options;
  if (!canVisit(startIndex) || !canVisit(goalIndex)) return null;
  if (startIndex === goalIndex) return [startIndex];

  const size = width * height;
  const visited = new Uint8Array(size);
  const parent = new Int32Array(size);
  parent.fill(-1);

  const queue = [startIndex];
  visited[startIndex] = 1;

  for (let head = 0; head < queue.length; head += 1) {
    const current = queue[head];
    if (current === goalIndex) break;
    forEachNeighbor(current, width, height, (next) => {
      if (visited[next] || !canVisit(next)) return;
      visited[next] = 1;
      parent[next] = current;
      queue.push(next);
    });
  }

  if (!visited[goalIndex]) return null;

  const path = [];
  for (let current = goalIndex; current !== -1; current = parent[current]) {
    path.push(current);
  }
  path.reverse();
  return path;
}

module.exports = {
  connectedComponents,
  floodFill,
  shortestPath,
  toIndex,
  toXY,
};
