'use strict';
// lint_duplicate_constants.js
// Parses constants.asm for all 'label equ value' lines and reports any label
// defined more than once. Directly targets the CONST-001 duplicate block regression.
//
// Usage: node tools/lint_duplicate_constants.js
// Exit 0 = clean, Exit 1 = duplicates found

const fs   = require('fs');
const path = require('path');

const ROOT           = path.join(__dirname, '..');
const CONSTANTS_FILE = path.join(ROOT, 'constants.asm');

// Match lines like:   LabelName   equ   $1234   or   LabelName equ 5
// Groups: [1] = label name, [2] = value
const EQU_RE = /^(\w+)\s+equ\s+(.+?)(?:\s*;.*)?$/i;

const lines     = fs.readFileSync(CONSTANTS_FILE, 'utf8').split('\n');
const seen      = new Map(); // label -> [{ lineNum, value }]

for (let i = 0; i < lines.length; i++) {
  const line = lines[i].trim();
  const m    = EQU_RE.exec(line);
  if (!m) continue;
  const label = m[1];
  const value = m[2].trim();
  if (!seen.has(label)) {
    seen.set(label, []);
  }
  seen.get(label).push({ lineNum: i + 1, value });
}

const duplicates = [...seen.entries()].filter(([, defs]) => defs.length > 1);

if (duplicates.length === 0) {
  console.log('lint_duplicate_constants: OK — no duplicate equ definitions found.');
  process.exit(0);
} else {
  console.error(`lint_duplicate_constants: FAIL — ${duplicates.length} label(s) defined multiple times:`);
  for (const [label, defs] of duplicates) {
    const locs = defs.map(d => `line ${d.lineNum} (${d.value})`).join(', ');
    console.error(`  ${label}: ${locs}`);
  }
  process.exit(1);
}
