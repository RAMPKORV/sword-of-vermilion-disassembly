'use strict';
// lint_loc_labels.js
// Scans all .asm files in the active build for remaining loc_XXXXXXXX labels
// (disassembler-generated placeholder names that should be renamed).
//
// Usage: node tools/lint_loc_labels.js
// Exit 0 = clean (no loc_ labels), Exit 1 = violations found

const fs   = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');

// All .asm files that participate in the build (from vermilion.asm includes)
const BUILD_FILES = [
  'header.asm',
  'init.asm',
  'macros.asm',
  'constants.asm',
  ...fs.readdirSync(path.join(ROOT, 'src'))
        .filter(f => f.endsWith('.asm'))
        .map(f => path.join('src', f)),
];

// Match labels defined at column 0 that start with loc_ followed by hex digits
// Also match references to loc_ labels in operands
const LOC_LABEL_DEF_RE = /^(loc_[0-9A-Fa-f]+)\s*:/;
const LOC_LABEL_REF_RE = /\bloc_[0-9A-Fa-f]+\b/g;

let totalDefs = 0;
let totalRefs = 0;
const hits = [];

for (const rel of BUILD_FILES) {
  const abs = path.join(ROOT, rel);
  if (!fs.existsSync(abs)) continue;

  const lines = fs.readFileSync(abs, 'utf8').split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lineNum = i + 1;

    // Check for label definitions
    const defMatch = line.match(LOC_LABEL_DEF_RE);
    if (defMatch) {
      totalDefs++;
      hits.push({ file: rel, line: lineNum, type: 'def', label: defMatch[1], text: line.trimEnd() });
      continue;
    }

    // Check for references (skip comment-only lines)
    const stripped = line.replace(/;.*$/, '');
    const refs = stripped.match(LOC_LABEL_REF_RE);
    if (refs) {
      for (const ref of refs) {
        totalRefs++;
        hits.push({ file: rel, line: lineNum, type: 'ref', label: ref, text: line.trimEnd() });
      }
    }
  }
}

if (hits.length === 0) {
  console.log('PASS: No loc_ labels found in active build files.');
  process.exit(0);
} else {
  console.log(`FAIL: Found ${totalDefs} loc_ label definition(s) and ${totalRefs} reference(s):\n`);
  for (const h of hits) {
    const tag = h.type === 'def' ? 'DEF' : 'REF';
    console.log(`  ${h.file}:${h.line} [${tag}] ${h.label}`);
  }
  console.log(`\nTotal: ${totalDefs} definitions, ${totalRefs} references`);
  process.exit(1);
}
