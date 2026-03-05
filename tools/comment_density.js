#!/usr/bin/env node
// tools/comment_density.js
// Sword of Vermilion — Comment Density Reporter
//
// Reports the comment-line percentage for every src/*.asm file and highlights
// files below the 15% threshold defined in todos.json (COMMENT-001 through
// COMMENT-008 targets).
//
// A "comment line" is any line whose first non-whitespace character is ';'.
// Blank lines are excluded from both numerator and denominator.
//
// Usage:
//   node tools/comment_density.js [--threshold N] [--verbose] [files...]
//
// Options:
//   --threshold N   Warn threshold in percent (default: 15)
//   --verbose       Show per-file breakdown even if above threshold
//   --json          Output JSON instead of human-readable table
//   --help          Show this help
//
// Exit code: 0 = all files at/above threshold, 1 = any file below threshold

'use strict';

const fs   = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

const args      = process.argv.slice(2);
const VERBOSE   = args.includes('--verbose');
const JSON_OUT  = args.includes('--json');
const HELP      = args.includes('--help');

let THRESHOLD = 15;
const tIdx = args.indexOf('--threshold');
if (tIdx >= 0 && args[tIdx + 1]) {
  const t = parseFloat(args[tIdx + 1]);
  if (!isNaN(t)) THRESHOLD = t;
}

if (HELP) {
  console.log([
    'Usage: node tools/comment_density.js [files...] [--threshold N] [--verbose] [--json]',
    '',
    'Reports comment-line % per src/*.asm file, highlights files below threshold.',
    '',
    'Options:',
    '  --threshold N   Warning threshold % (default: 15)',
    '  --verbose       Show all files, not just below-threshold ones',
    '  --json          Output JSON array of results',
    '  --help          Show this help',
  ].join('\n'));
  process.exit(0);
}

// Files to analyze: explicit args (minus flags) or default src/*.asm
const SRC_DIR = path.join(__dirname, '..', 'src');
const fileArgs = args.filter(a => !a.startsWith('--') && fs.existsSync(a));
let files;
if (fileArgs.length > 0) {
  files = fileArgs;
} else {
  files = fs.readdirSync(SRC_DIR)
    .filter(f => f.endsWith('.asm'))
    .map(f => path.join(SRC_DIR, f))
    .sort();
}

// ---------------------------------------------------------------------------
// Analyze each file
// ---------------------------------------------------------------------------

function analyzeFile(filePath) {
  const lines    = fs.readFileSync(filePath, 'utf8').split('\n');
  let totalLines = 0;
  let codeLines  = 0;
  let commentLines = 0;
  let blankLines   = 0;

  for (const raw of lines) {
    const line = raw.trimEnd();
    const stripped = line.trimStart();

    if (stripped === '') {
      blankLines++;
      continue;
    }
    totalLines++;

    if (stripped.startsWith(';')) {
      commentLines++;
    } else {
      // Check if line contains an inline comment after code
      codeLines++;
    }
  }

  const ratio = totalLines > 0 ? (commentLines / totalLines) * 100 : 0;
  return {
    file:         path.basename(filePath),
    filePath,
    totalLines,
    codeLines,
    commentLines,
    blankLines,
    ratio: Math.round(ratio * 10) / 10,
  };
}

const results = files.map(analyzeFile);

// Sort by ratio ascending (worst documented first) for the below-threshold list
const below = results.filter(r => r.ratio < THRESHOLD).sort((a, b) => a.ratio - b.ratio);
const above = results.filter(r => r.ratio >= THRESHOLD).sort((a, b) => a.ratio - b.ratio);

// ---------------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------------

if (JSON_OUT) {
  console.log(JSON.stringify(results, null, 2));
  process.exit(below.length > 0 ? 1 : 0);
}

const WIDTH = 72;
const hr    = '─'.repeat(WIDTH);

function bar(ratio, width) {
  const filled = Math.round((ratio / 100) * width);
  return '█'.repeat(Math.min(filled, width)) + '░'.repeat(Math.max(0, width - filled));
}

function fmt(r) {
  const pct    = r.ratio.toFixed(1).padStart(5);
  const flag   = r.ratio < THRESHOLD ? '⚠' : '✓';
  const bGraph = bar(r.ratio, 20);
  const name   = r.file.padEnd(28);
  return `  ${flag} ${name} ${pct}%  [${bGraph}]  ${r.commentLines}/${r.totalLines} lines`;
}

console.log('\n' + hr);
console.log(`  Comment Density Report  (threshold: ${THRESHOLD}%)`);
console.log(hr);

if (below.length > 0) {
  console.log(`\n  Files BELOW ${THRESHOLD}% threshold (${below.length}):\n`);
  for (const r of below) {
    console.log(fmt(r));
  }
}

if (VERBOSE || below.length === 0) {
  if (above.length > 0) {
    console.log(`\n  Files at/above ${THRESHOLD}% threshold (${above.length}):\n`);
    for (const r of above) {
      console.log(fmt(r));
    }
  }
} else if (above.length > 0) {
  console.log(`\n  ${above.length} file(s) at/above ${THRESHOLD}% threshold (use --verbose to list)`);
}

// Summary line
const totalFiles  = results.length;
const totalNonBlank = results.reduce((s, r) => s + r.totalLines, 0);
const totalComment  = results.reduce((s, r) => s + r.commentLines, 0);
const overallRatio  = totalNonBlank > 0 ? (totalComment / totalNonBlank * 100).toFixed(1) : '0.0';

console.log('\n' + hr);
console.log(`  Overall: ${totalComment}/${totalNonBlank} non-blank lines are comments (${overallRatio}%)`);
console.log(`  Files below threshold: ${below.length}/${totalFiles}`);
console.log(hr + '\n');

process.exit(below.length > 0 ? 1 : 0);
