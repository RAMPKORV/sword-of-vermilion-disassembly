#!/usr/bin/env node
// DEADB-002: Cross-reference all function labels against callsites across all ASM files.
// Reports labels defined in src/*.asm with zero external references.
// Usage: node tools/deadb002_audit.js

'use strict';
const fs = require('fs');
const path = require('path');

// Collect all ASM files to scan
const srcFiles = fs.readdirSync('src').filter(f => f.endsWith('.asm')).map(f => path.join('src', f));
const rootFiles = ['header.asm', 'init.asm', 'constants.asm', 'macros.asm'].filter(f => fs.existsSync(f));
const allFiles = [...rootFiles, ...srcFiles];

// Pass 1: collect all labels defined at column 0
// A label is any line where col-0 is a word char (not whitespace, not semicolon)
const labelDefRe = /^([A-Za-z_][A-Za-z0-9_.]*)(:)?\s*(?:;.*)?$/;
const asmKeywords = new Set([
  'include', 'incbin', 'dc', 'ds', 'org', 'section', 'even', 'align', 'end',
  'rept', 'endr', 'macro', 'endm', 'if', 'else', 'endif', 'offset',
  'rsreset', 'rs', 'rset', 'equ', 'set', 'fail', 'inform', 'opt',
]);

const definedLabels = new Map(); // name -> {file, line}

for (const filePath of allFiles) {
  const lines = fs.readFileSync(filePath, 'utf8').split('\n');
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line.length || /^[\s;]/.test(line)) continue;
    const m = line.match(labelDefRe);
    if (m) {
      const name = m[1];
      if (asmKeywords.has(name.toLowerCase())) continue;
      if (!definedLabels.has(name)) {
        definedLabels.set(name, { file: filePath, line: i + 1 });
      }
    }
  }
}

console.log('Total labels defined across all files:', definedLabels.size);

// Pass 2: count total token occurrences across all files
const tokenCount = new Map();
for (const filePath of allFiles) {
  const content = fs.readFileSync(filePath, 'utf8');
  const tokens = content.match(/\b[A-Za-z_][A-Za-z0-9_.]*\b/g) || [];
  for (const tok of tokens) {
    tokenCount.set(tok, (tokenCount.get(tok) || 0) + 1);
  }
}

// Pass 3: find src/ labels with count <= 1 (only own definition)
const zeroCallerLabels = [];
for (const [name, def] of definedLabels.entries()) {
  // Only care about labels defined in src/ files
  const normFile = def.file.replace(/\\/g, '/');
  if (!normFile.startsWith('src/')) continue;
  const count = tokenCount.get(name) || 0;
  if (count <= 1) {
    zeroCallerLabels.push({ name, file: def.file, line: def.line });
  }
}

// Sort by file then line
zeroCallerLabels.sort((a, b) => a.file.localeCompare(b.file) || a.line - b.line);

console.log('\nLabels in src/ with zero external references:', zeroCallerLabels.length);
console.log('\nFile breakdown:');
const byFile = {};
for (const entry of zeroCallerLabels) {
  byFile[entry.file] = (byFile[entry.file] || 0) + 1;
}
for (const [f, n] of Object.entries(byFile).sort()) {
  console.log(`  ${f}: ${n}`);
}

console.log('\n--- Full zero-reference label list ---');
for (const entry of zeroCallerLabels) {
  console.log(`  ${entry.file}:${entry.line}  ${entry.name}`);
}
