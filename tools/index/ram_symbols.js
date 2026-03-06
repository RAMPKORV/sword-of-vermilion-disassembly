#!/usr/bin/env node
// tools/index/ram_symbols.js
//
// Reads constants.asm and extracts every RAM address definition of the form:
//
//   Label_name   = $FFFFC...   ; .w  brief description
//   Label_name   = $FFFF8...   ; buf  some buffer
//
// Emits tools/index/ram_symbols.json — one entry per symbol, sorted by address.
//
// JSON entry shape:
//   {
//     "name":    "Player_hp",
//     "address": "0xFFFFC62C",
//     "size":    ".w",          // ".b", ".w", ".l", or null if unknown
//     "kind":    "scalar",      // "scalar" | "array" | "buffer" | "end" | "unknown"
//     "description": "current HP"
//   }
//
// Usage:
//   node tools/index/ram_symbols.js [--src <constants.asm>] [--out <output.json>]
//
// Defaults:
//   --src  constants.asm                   (relative to repo root)
//   --out  tools/index/ram_symbols.json

'use strict';

const fs   = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Argument parsing
// ---------------------------------------------------------------------------

const args = process.argv.slice(2);
function getArg(flag, def) {
  const i = args.indexOf(flag);
  return i !== -1 ? args[i + 1] : def;
}

const ROOT    = path.resolve(__dirname, '..', '..');
const srcPath = path.resolve(ROOT, getArg('--src', 'constants.asm'));
const outPath = path.resolve(ROOT, getArg('--out', 'tools/index/ram_symbols.json'));

// ---------------------------------------------------------------------------
// Parsing
// ---------------------------------------------------------------------------

// Matches:  Label_name  = $FFFFC62C   ; .w  current HP
// Group 1: label name
// Group 2: hex address (without $)
// Group 3: optional comment text after ';'
const DEF_RE = /^(\w+)\s*=\s*\$([0-9A-Fa-f]{8})\b(.*)/;

// RAM address range: $FFFF0000 – $FFFFFFFF (Mega Drive work RAM + mirrors)
const RAM_LO = 0xFFFF0000;

function parseComment(raw) {
  // raw is everything after the '=' value, e.g. '   ; .w  current HP'
  const semi = raw.indexOf(';');
  if (semi === -1) return { size: null, kind: 'unknown', description: '' };

  const comment = raw.slice(semi + 1).trim();

  // Size tag: .b  .w  .l  at the start of comment
  let size = null;
  let rest = comment;
  const sizeMatch = rest.match(/^(\.b|\.w|\.l)\b\s*/i);
  if (sizeMatch) {
    size = sizeMatch[1].toLowerCase();
    rest = rest.slice(sizeMatch[0].length);
  }

  // Kind tag: arr  buf  end  at the start of what remains
  let kind = 'scalar';
  const kindMatch = rest.match(/^(arr|buf|end|array|buffer)\b\s*/i);
  if (kindMatch) {
    const k = kindMatch[1].toLowerCase();
    if (k === 'arr' || k === 'array') kind = 'array';
    else if (k === 'buf' || k === 'buffer') kind = 'buffer';
    else if (k === 'end') kind = 'end';
    rest = rest.slice(kindMatch[0].length);
  } else if (size === null) {
    // If no size and no kind keyword, check for bare kind tags
    const bareKind = rest.match(/^(arr|buf|end|array|buffer)\b\s*/i);
    if (bareKind) {
      const k = bareKind[1].toLowerCase();
      if (k === 'arr' || k === 'array') kind = 'array';
      else if (k === 'buf' || k === 'buffer') kind = 'buffer';
      else if (k === 'end') kind = 'end';
      rest = rest.slice(bareKind[0].length);
    } else {
      kind = 'unknown';
    }
  }

  // Remaining text is the description; strip trailing semicolon-delimited
  // sub-comments (e.g. '; .b[14] ...; length in X') — keep the whole thing
  const description = rest.trim();

  return { size, kind, description };
}

const lines = fs.readFileSync(srcPath, 'utf8').split('\n');
const symbols = [];

for (const rawLine of lines) {
  const line = rawLine.replace(/\r$/, '');
  // Skip blank lines and pure comment lines
  if (!line.trim() || line.trimStart().startsWith(';')) continue;

  const m = line.match(DEF_RE);
  if (!m) continue;

  const name    = m[1];
  const addrInt = parseInt(m[2], 16);
  const suffix  = m[3];

  // Filter to RAM range only
  if (addrInt < RAM_LO) continue;

  const address = '0x' + addrInt.toString(16).toUpperCase().padStart(8, '0');
  const { size, kind, description } = parseComment(suffix);

  symbols.push({ name, address, size, kind, description });
}

// Sort by address (numeric)
symbols.sort((a, b) => {
  const ai = parseInt(a.address, 16);
  const bi = parseInt(b.address, 16);
  return ai - bi;
});

// ---------------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------------

const output = {
  _meta: {
    generated_by: 'tools/index/ram_symbols.js',
    source: path.relative(ROOT, srcPath),
    count: symbols.length,
  },
  symbols,
};

fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(output, null, 2) + '\n');

console.log(`ram_symbols.js: wrote ${symbols.length} RAM symbols to ${path.relative(ROOT, outPath)}`);
