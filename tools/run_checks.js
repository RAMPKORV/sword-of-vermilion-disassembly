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

// Hard-fail checks: any failure blocks the commit.
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

// Warning-only checks: displayed but do not cause a non-zero exit.
// REGR-002: comment density regression warning
// REGR-003: raw struct offset ($NN(Ax)) regression warning
const WARNINGS = [
  {
    id:     'comment_density',
    script: path.join(TOOLS_DIR, 'comment_density.js'),
    desc:   'Comment density ≥10% per file (warning only)',
    args:   ['--threshold', '10'],
  },
  {
    id:     'lint_raw_obj_offsets',
    script: path.join(TOOLS_DIR, 'lint_raw_obj_offsets.js'),
    desc:   'No new raw $NN(Ax) struct offsets (warning only)',
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
  results.push({ check, passed, output: output.trim(), isWarning: false });
}

const warnResults = [];
for (const check of WARNINGS) {
  let output = '';
  const args = check.args ? [check.script, ...check.args] : [check.script];
  try {
    output = execFileSync(NODE, args, { encoding: 'utf8', stderr: 'pipe' });
  } catch (err) {
    output = (err.stdout || '') + (err.stderr || '');
  }
  warnResults.push({ check, output: output.trim() });
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
    output.split('\n').forEach(line => console.log('         ' + line));
  }
}

if (warnResults.length > 0) {
  console.log('-'.repeat(60));
  console.log('  Warnings (informational — do not block commit):');
  for (const { check, output } of warnResults) {
    const label = check.id.padEnd(WIDTH);
    console.log(`  [WARN] ${label} ${check.desc}`);
    if (output) {
      output.split('\n').slice(0, 6).forEach(line => console.log('         ' + line));
    }
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

