'use strict';
// label_coverage.js
// Parses the build listing file (vermilion.lst) and reports named labels vs
// remaining loc_XXXXXXXX placeholder labels, tracking naming coverage progress.
//
// Usage: node tools/label_coverage.js [path/to/vermilion.lst]
// Defaults to vermilion.lst in the project root.
// Exit 0 always (informational report only).

const fs   = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');

// Accept optional path argument
const lstPath = process.argv[2] || path.join(ROOT, 'vermilion.lst');

if (!fs.existsSync(lstPath)) {
  console.error('ERROR: Listing file not found: ' + lstPath);
  console.error('Run build.bat first to generate vermilion.lst.');
  process.exit(1);
}

// Scan the source files directly (faster and more reliable than parsing the lst)
// The listing file format varies; scanning the .asm files is definitive.
const BUILD_FILES = [
  'header.asm',
  'init.asm',
  'macros.asm',
  'constants.asm',
  ...fs.readdirSync(path.join(ROOT, 'src'))
        .filter(f => f.endsWith('.asm'))
        .map(f => path.join('src', f)),
];

// Label definition patterns
// loc_XXXXXXXX: at column 0
const LOC_LABEL_RE  = /^(loc_[0-9A-Fa-f]+)\s*:/;
// Any label at column 0 (not loc_, not a comment, not a macro invocation)
const ANY_LABEL_RE  = /^([A-Za-z_][A-Za-z0-9_.]*)\s*:/;
// Skip equ/= definitions (those are constants, not code labels)
const EQU_RE        = /^[A-Za-z_]\w*\s+(equ|=)\s+/i;

let locLabels   = [];  // { file, line, label }
let namedLabels = [];  // { file, line, label }

for (const rel of BUILD_FILES) {
  const abs = path.join(ROOT, rel);
  if (!fs.existsSync(abs)) continue;
  const lines = fs.readFileSync(abs, 'utf8').split(/\r?\n/);
  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i];
    // Skip equ/= lines
    if (EQU_RE.test(raw)) continue;
    // Skip comment-only lines
    if (/^\s*;/.test(raw)) continue;

    const locM = raw.match(LOC_LABEL_RE);
    if (locM) {
      locLabels.push({ file: rel, line: i + 1, label: locM[1] });
      continue;
    }
    const anyM = raw.match(ANY_LABEL_RE);
    if (anyM) {
      // Exclude macro keywords
      const lbl = anyM[1];
      if (/^(macro|endm|rept|endr|section|include)$/i.test(lbl)) continue;
      namedLabels.push({ file: rel, line: i + 1, label: lbl });
    }
  }
}

const totalLabels = locLabels.length + namedLabels.length;
const namedCount  = namedLabels.length;
const locCount    = locLabels.length;
const pct         = totalLabels === 0 ? 100 : Math.round((namedCount / totalLabels) * 1000) / 10;

console.log('');
console.log('====================================================');
console.log('  Label Coverage Report');
console.log('====================================================');
console.log(`  Total labels : ${totalLabels}`);
console.log(`  Named labels : ${namedCount}  (${pct}%)`);
console.log(`  loc_ labels  : ${locCount}`);
console.log('====================================================');

if (locCount === 0) {
  console.log('  STATUS: 100% named — no loc_ labels remain.');
} else {
  console.log('  STATUS: ' + locCount + ' loc_ label(s) still need renaming.');
  console.log('');
  console.log('  Remaining loc_ labels by file:');
  // Group by file
  const byFile = {};
  for (const { file, line, label } of locLabels) {
    if (!byFile[file]) byFile[file] = [];
    byFile[file].push({ line, label });
  }
  for (const [file, entries] of Object.entries(byFile)) {
    console.log(`    ${file} (${entries.length}):`);
    for (const { line, label } of entries) {
      console.log(`      line ${line}: ${label}`);
    }
  }
}

console.log('====================================================');
console.log('');
