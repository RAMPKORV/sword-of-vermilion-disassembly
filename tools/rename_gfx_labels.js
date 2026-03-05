#!/usr/bin/env node
// tools/rename_gfx_labels.js
//
// DATA-001: Rename ROM-address-suffix graphics labels in gfxdata.asm
//
// Replaces   Prefix_Gfx_XXXXXX  →  Prefix_Entry00, Prefix_Entry01, …
// across gfxdata.asm and all files that reference those labels.
//
// Within each group (same Prefix) entries are ordered by ascending hex address,
// then numbered sequentially starting at 00.
//
// Usage:
//   node tools/rename_gfx_labels.js            # dry-run (prints rename map)
//   node tools/rename_gfx_labels.js --apply     # write files in place
//   node tools/rename_gfx_labels.js --apply --verbose

'use strict';

const fs    = require('fs');
const path  = require('path');

const ROOT = path.resolve(__dirname, '..');
const APPLY   = process.argv.includes('--apply');
const VERBOSE = process.argv.includes('--verbose');

// All files that may contain these labels (definitions or references)
const TARGET_FILES = [
  'src/gfxdata.asm',
  'src/bossbattle.asm',
  'src/battledata.asm',
  'src/mapdata.asm',
  'src/sound.asm',
  'src/towndata.asm',
  'src/battle_gfx.asm',
].map(f => path.join(ROOT, f));

// ── 1. Collect all _Gfx_XXXXXX tokens across all target files ────────────────

const LABEL_RE = /\b([A-Za-z_][A-Za-z0-9_]*)_Gfx_([0-9A-Fa-f]+)\b/g;

/** Map:  groupPrefix  →  Set of hex-address strings */
const groups = new Map();

for (const file of TARGET_FILES) {
  const txt = fs.readFileSync(file, 'utf8');
  let m;
  while ((m = LABEL_RE.exec(txt)) !== null) {
    const prefix = m[1];
    const hex    = m[2].toUpperCase();
    if (!groups.has(prefix)) groups.set(prefix, new Set());
    groups.get(prefix).add(hex);
  }
}

// ── 2. Build rename map:  old label  →  new label ───────────────────────────

const renameMap = new Map();   // full old name → full new name

for (const [prefix, hexSet] of groups) {
  // Sort entries by ROM address (ascending)
  const sorted = Array.from(hexSet).sort((a, b) =>
    parseInt(a, 16) - parseInt(b, 16)
  );
  sorted.forEach((hex, idx) => {
    const oldName = `${prefix}_Gfx_${hex}`;
    // Re-use whatever case the source uses (might be mixed), but hex suffix in
    // original casing — we match case-insensitively when replacing.
    const newName = `${prefix}_Entry${String(idx).padStart(2, '0')}`;
    renameMap.set(oldName, newName);
  });
}

console.log(`Total label groups  : ${groups.size}`);
console.log(`Total renames       : ${renameMap.size}`);
if (VERBOSE) {
  for (const [o, n] of renameMap) console.log(`  ${o}  →  ${n}`);
}

if (!APPLY) {
  console.log('\nDry-run mode. Pass --apply to write files.');
  process.exit(0);
}

// ── 3. Apply renames ─────────────────────────────────────────────────────────
//
// We need to replace all occurrences of each old label.  Because labels share
// common prefixes we must replace the longest matches first to avoid partial
// substitution (e.g. Prefix_Gfx_123 must not be replaced if Prefix_Gfx_1234
// exists and appears first in sorted order — but since we sort by address and
// number sequentially this can't happen).  Still, we sort by descending old-
// name length for safety.

const sortedRenames = Array.from(renameMap.entries())
  .sort((a, b) => b[0].length - a[0].length);

// Build a single giant alternation regex for efficiency
// Escape special regex chars in label names (none expected, but be safe)
function escapeRe(s) { return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }

// Split into batches to avoid regex length limits (~10k chars each)
const BATCH = 500;
const batches = [];
for (let i = 0; i < sortedRenames.length; i += BATCH) {
  batches.push(sortedRenames.slice(i, i + BATCH));
}

let totalReplacements = 0;

for (const file of TARGET_FILES) {
  let txt = fs.readFileSync(file, 'utf8');
  let replacements = 0;
  for (const batch of batches) {
    const re = new RegExp(
      batch.map(([o]) => `\\b${escapeRe(o)}\\b`).join('|'),
      'g'
    );
    // Build a lookup for this batch
    const batchMap = new Map(batch.map(([o, n]) => [o, n]));
    txt = txt.replace(re, match => {
      const replacement = batchMap.get(match);
      if (replacement) { replacements++; return replacement; }
      return match;
    });
  }
  if (replacements > 0) {
    fs.writeFileSync(file, txt, 'utf8');
    console.log(`  Updated ${path.relative(ROOT, file)}: ${replacements} replacements`);
    totalReplacements += replacements;
  } else {
    console.log(`  No changes: ${path.relative(ROOT, file)}`);
  }
}

console.log(`\nDone. Total replacements across all files: ${totalReplacements}`);
