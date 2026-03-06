'use strict';
// tools/index/functions.js
//
// Scans all .asm files in the build (per include_graph.json) for PascalCase
// labels — the naming convention for functions in this disassembly — and emits
// tools/index/functions.json:
//
//   [
//     { "name": "EntryPoint", "file": "init.asm", "line": 5, "address": "0x00000F2C" },
//     ...
//   ]
//
// Address is filled from symbol_map.json where available (requires a recent
// build so that vermilion.lst / symbol_map.json is up to date).
//
// Usage:
//   node tools/index/functions.js [--out <path>]
//
// Defaults:
//   --out   tools/index/functions.json

const fs   = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..', '..');
const args     = process.argv.slice(2);

function getArg(flag, def) {
  const i = args.indexOf(flag);
  return i !== -1 && args[i + 1] ? args[i + 1] : def;
}

const outPath = path.resolve(repoRoot, getArg('--out', 'tools/index/functions.json'));

// ---------------------------------------------------------------------------
// Load symbol map for address resolution (optional — don't fail if absent)
// ---------------------------------------------------------------------------
const symbolMapPath = path.resolve(repoRoot, 'tools/index/symbol_map.json');
let symbolMap = {};
if (fs.existsSync(symbolMapPath)) {
  try { symbolMap = JSON.parse(fs.readFileSync(symbolMapPath, 'utf8')); } catch (_) {}
}

// ---------------------------------------------------------------------------
// Load include graph to enumerate files in build order
// ---------------------------------------------------------------------------
const graphPath = path.resolve(repoRoot, 'tools/index/include_graph.json');
let buildFiles = [];
if (fs.existsSync(graphPath)) {
  try {
    const graph = JSON.parse(fs.readFileSync(graphPath, 'utf8'));
    buildFiles = graph.build_order || [];
  } catch (_) {}
}
// Fallback: scan manually
if (buildFiles.length === 0) {
  const srcDir = path.resolve(repoRoot, 'src');
  buildFiles = ['init.asm', 'header.asm'].concat(
    fs.readdirSync(srcDir).filter(f => f.endsWith('.asm')).map(f => `src/${f}`)
  );
}

// ---------------------------------------------------------------------------
// PascalCase label pattern:
//   - starts at column 0 (no leading whitespace)
//   - begins with uppercase letter
//   - followed by alphanumeric / underscore  
//   - ends with ':'
//   - NOT a data-only label (optional heuristic: skip ALL_CAPS)
//
// We include Mixed_Case (e.g. CheckButtonPress, Check_button) and PascalCase.
// We skip ALL_CAPS (constants/data), pure lowercase, and local labels (@xxx).
// ---------------------------------------------------------------------------
const FUNC_LABEL_RE = /^([A-Z][A-Za-z0-9_]*):(?:\s|$)/;
const ALL_CAPS_RE   = /^[A-Z][A-Z0-9_]*:$/;   // e.g. SOUND_EFFECT_HIT:

const functions = [];
const seen      = new Set();

for (const relFile of buildFiles) {
  const absFile = path.resolve(repoRoot, relFile);
  if (!fs.existsSync(absFile)) continue;

  let content;
  try { content = fs.readFileSync(absFile, 'utf8'); } catch (_) { continue; }

  const lines = content.split('\n');
  lines.forEach((rawLine, idx) => {
    const line = rawLine.replace(/\r$/, '');
    const m = FUNC_LABEL_RE.exec(line);
    if (!m) return;

    const name = m[1];
    // Skip pure ALL_CAPS labels (they're constants/data, not code)
    if (/^[A-Z][A-Z0-9_]+$/.test(name)) return;
    // Skip duplicates (same name in multiple files is a forward-reference trampoline)
    if (seen.has(name)) return;
    seen.add(name);

    const sym     = symbolMap[name];
    const address = sym ? sym.address : null;
    const region  = sym ? sym.region  : null;

    functions.push({
      name,
      file:    relFile.replace(/\\/g, '/'),
      line:    idx + 1,
      address,
      region,
    });
  });
}

// Sort by file then line for a stable, readable ordering
functions.sort((a, b) => {
  if (a.file !== b.file) return a.file.localeCompare(b.file);
  return a.line - b.line;
});

// ---------------------------------------------------------------------------
// Write output
// ---------------------------------------------------------------------------
const outDir = path.dirname(outPath);
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(functions, null, 2) + '\n');

const withAddr   = functions.filter(f => f.address !== null).length;
const romFuncs   = functions.filter(f => f.region === 'rom').length;
console.log(`functions.js: ${functions.length} functions found`);
console.log(`  With address : ${withAddr} (${romFuncs} in ROM)`);
console.log(`  Written to   : ${path.relative(repoRoot, outPath)}`);
