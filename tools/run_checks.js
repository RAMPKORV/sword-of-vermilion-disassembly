'use strict';
// run_checks.js
// Unified pre-commit sanity checker for the Sword of Vermilion disassembly.
// Runs all lint scripts in sequence and prints a pass/fail summary.
//
// Usage: node tools/run_checks.js
// Exit 0 = all checks passed, Exit 1 = one or more checks failed
//
// This does NOT run verify.bat (the bit-perfect SHA256 check). Run that
// separately before committing. This script is for fast static analysis.

const { execFileSync } = require('child_process');
const path = require('path');

const TOOLS_DIR = __dirname;
const NODE = process.execPath;

const CHECKS = [
  {
    id:     'lint_loc_labels',
    script: path.join(TOOLS_DIR, 'lint_loc_labels.js'),
    desc:   'No remaining loc_XXXXXXXX placeholder labels',
  },
  {
    id:     'lint_dc_decimal',
    script: path.join(TOOLS_DIR, 'lint_dc_decimal.js'),
    desc:   'No decimal literals in dc.b/dc.w/dc.l directives',
  },
  {
    id:     'lint_raw_io_addresses',
    script: path.join(TOOLS_DIR, 'lint_raw_io_addresses.js'),
    desc:   'No raw hardware I/O port addresses in instructions',
  },
  {
    id:     'lint_raw_ram_addresses',
    script: path.join(TOOLS_DIR, 'lint_raw_ram_addresses.js'),
    desc:   'No raw $FFFFxxxx RAM addresses in instructions',
  },
  {
    id:     'lint_duplicate_constants',
    script: path.join(TOOLS_DIR, 'lint_duplicate_constants.js'),
    desc:   'No duplicate equ definitions in constants.asm',
  },
];

const WIDTH = 40;
let allPassed = true;
const results = [];

for (const check of CHECKS) {
  let passed = false;
  let output = '';
  try {
    output = execFileSync(NODE, [check.script], { encoding: 'utf8', stderr: 'pipe' });
    passed = true;
  } catch (err) {
    output = (err.stdout || '') + (err.stderr || '');
    passed = false;
  }
  if (!passed) allPassed = false;
  results.push({ check, passed, output: output.trim() });
}

// Print summary
console.log('\n' + '='.repeat(60));
console.log('  run_checks.js — pre-commit lint summary');
console.log('='.repeat(60));

for (const { check, passed, output } of results) {
  const status = passed ? 'PASS' : 'FAIL';
  const label  = check.id.padEnd(WIDTH);
  console.log(`  [${status}] ${label} ${check.desc}`);
  if (!passed && output) {
    // Indent failure output
    output.split('\n').forEach(line => console.log('         ' + line));
  }
}

console.log('='.repeat(60));
if (allPassed) {
  console.log('  ALL CHECKS PASSED');
} else {
  const failCount = results.filter(r => !r.passed).length;
  console.log(`  ${failCount} CHECK(S) FAILED — fix before committing`);
}
console.log('='.repeat(60) + '\n');

process.exit(allPassed ? 0 : 1);
