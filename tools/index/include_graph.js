'use strict';
// tools/index/include_graph.js
//
// Parses vermilion.asm and all included .asm files recursively, extracts
// `include` directives, and emits tools/index/include_graph.json as an
// adjacency list with build-order metadata.
//
// Usage:
//   node tools/index/include_graph.js [--root <entry.asm>] [--out <path>]
//
// Defaults:
//   --root  vermilion.asm
//   --out   tools/index/include_graph.json
//
// Output format:
// {
//   "build_order": ["vermilion.asm", "header.asm", "macros.asm", ...],
//   "nodes": {
//     "vermilion.asm": { "includes": ["header.asm", "src/core.asm", ...], "depth": 0 },
//     "header.asm":    { "includes": ["macros.asm", "constants.asm"],     "depth": 1 },
//     ...
//   }
// }

const fs   = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..', '..');
const args     = process.argv.slice(2);

function getArg(flag, def) {
  const i = args.indexOf(flag);
  return i !== -1 && args[i + 1] ? args[i + 1] : def;
}

const rootFile = path.resolve(repoRoot, getArg('--root', 'vermilion.asm'));
const outPath  = path.resolve(repoRoot, getArg('--out',  'tools/index/include_graph.json'));

// Match:   include "path/to/file.asm"
//   or:      include 'path/to/file.asm'
const INCLUDE_RE = /^\s*include\s+["']([^"']+)["']/i;

const nodes      = {};  // relative path -> { includes: [], depth }
const buildOrder = [];  // DFS pre-order
const visited    = new Set();

function relPath(absPath) {
  return path.relative(repoRoot, absPath).replace(/\\/g, '/');
}

function processFile(absFile, depth) {
  const rel = relPath(absFile);
  if (visited.has(rel)) return;   // guard against circular includes
  visited.add(rel);
  buildOrder.push(rel);

  if (!fs.existsSync(absFile)) {
    nodes[rel] = { includes: [], depth, error: 'file not found' };
    return;
  }

  const content  = fs.readFileSync(absFile, 'utf8');
  const dir      = path.dirname(absFile);
  const includes = [];

  for (const rawLine of content.split('\n')) {
    const m = INCLUDE_RE.exec(rawLine.replace(/\r$/, ''));
    if (!m) continue;
    const includedRel = m[1];
    const includedAbs = path.resolve(dir, includedRel);
    includes.push(relPath(includedAbs));
    processFile(includedAbs, depth + 1);
  }

  nodes[rel] = { includes, depth };
}

processFile(rootFile, 0);

// ---------------------------------------------------------------------------
// Write output
// ---------------------------------------------------------------------------
const output = { build_order: buildOrder, nodes };
const outDir = path.dirname(outPath);
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(output, null, 2) + '\n');

const totalFiles = buildOrder.length;
const totalEdges = Object.values(nodes).reduce((n, v) => n + v.includes.length, 0);
const maxDepth   = Math.max(...Object.values(nodes).map(v => v.depth));
console.log(`include_graph.js: ${totalFiles} files, ${totalEdges} include edges, max depth ${maxDepth}`);
console.log(`  Written to ${path.relative(repoRoot, outPath)}`);
