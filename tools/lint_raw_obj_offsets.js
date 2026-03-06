#!/usr/bin/env node
// tools/lint_raw_obj_offsets.js
//
// Detects raw numeric object-field offsets in assembly source, i.e. operands
// of the form  $NN(A5)  or  $NN(A6)  that should be replaced with named
// obj_* constants defined in constants.asm.
//
// After RAM-002 completes (replacing all such raw offsets), this linter runs
// in CI / run_checks.js to prevent regressions.
//
// Usage:
//   node tools/lint_raw_obj_offsets.js [--fix-hints]
//
// Exit codes:
//   0  No violations found
//   1  One or more violations found (printed to stdout)
//
// Options:
//   --fix-hints   Print the known obj_* constant name alongside each hit
//                 (looked up from constants.asm obj_* comment block).

'use strict';

const fs   = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const srcDir   = path.join(repoRoot, 'src');
const fixHints = process.argv.includes('--fix-hints');

// ---------------------------------------------------------------------------
// Optional: load obj_* offset→name mapping from constants.asm for --fix-hints
// ---------------------------------------------------------------------------
// constants.asm documents the object struct in a comment block like:
//   ; $00   .b   obj_active     ...
//   ; $02   .l   obj_tick_fn    ...
// We parse those to build a hex-offset → obj_name map.
const OBJ_COMMENT_RE = /^;\s*\$([0-9A-Fa-f]{2})\s+\.[bwl]\s+(obj_\w+)/;
const offsetToName = {};

const constPath = path.join(repoRoot, 'constants.asm');
if (fs.existsSync(constPath)) {
    for (const line of fs.readFileSync(constPath, 'utf8').split('\n')) {
        const m = OBJ_COMMENT_RE.exec(line.replace(/\r$/, ''));
        if (m) offsetToName[parseInt(m[1], 16)] = m[2];
    }
}

// ---------------------------------------------------------------------------
// Scan source files
// ---------------------------------------------------------------------------
// Match:  $HH(A5)  or  $HH(A6)  (case-insensitive on hex digits, A5/A6 upper)
// We allow 1–4 hex digits to catch $0(A5) through $FFFF(A5).
const RAW_OFFSET_RE = /\$([0-9A-Fa-f]{1,4})\((A[56])\)/g;

const violations = [];

for (const fname of fs.readdirSync(srcDir)) {
    if (!fname.endsWith('.asm')) continue;
    const fpath = path.join(srcDir, fname);
    const lines = fs.readFileSync(fpath, 'utf8').split('\n');

    lines.forEach((rawLine, idx) => {
        const line = rawLine.replace(/\r$/, '');
        // Skip pure comment lines
        if (/^\s*;/.test(line)) return;

        let m;
        RAW_OFFSET_RE.lastIndex = 0;
        while ((m = RAW_OFFSET_RE.exec(line)) !== null) {
            const offset = parseInt(m[1], 16);
            const reg    = m[2];
            const hint   = (fixHints && offsetToName[offset])
                ? ` → ${offsetToName[offset]}(${reg})`
                : '';
            violations.push({
                file   : path.relative(repoRoot, fpath).replace(/\\/g, '/'),
                line   : idx + 1,
                col    : m.index + 1,
                text   : m[0],
                hint,
            });
        }
    });
}

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------
if (violations.length === 0) {
    console.log('lint_raw_obj_offsets: OK — no raw $NN(A5/A6) offsets found.');
    process.exit(0);
}

console.log(`lint_raw_obj_offsets: ${violations.length} raw object-field offset(s) found:\n`);
for (const v of violations) {
    console.log(`  ${v.file}:${v.line}:${v.col}  ${v.text}${v.hint}`);
}
console.log(`\nReplace each with the corresponding obj_* constant from constants.asm.`);
if (!fixHints) console.log(`Re-run with --fix-hints for suggested replacements.`);
process.exit(1);
