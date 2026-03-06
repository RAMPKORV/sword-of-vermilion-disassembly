#!/usr/bin/env node
// tools/index/script_entries.js
//
// Sword of Vermilion — Script Entry Point Index
//
// Scans all .asm source files for:
//   1. Script string labels (labels ending in "Str:" or followed by dc.b/script_cmd_*)
//   2. Sites that reference those labels via:
//      - MOVE.l #<Label>, obj_npc_str_ptr(...)  — NPC dialogue assignment
//      - print <Label>                           — inline print macro
//      - MOVE.l #<Label>, Script_source_base     — direct source assignment
//      - dc.l <Label>                            — pointer table entries
//
// Emits: tools/index/script_entries.json
//
// Usage: node tools/index/script_entries.js
//
// Output format:
// {
//   "_meta": { ... },
//   "entries": {
//     "LabelName": {
//       "defined_in": "src/file.asm",
//       "defined_line": 123,
//       "callers": [
//         { "file": "src/npc.asm", "line": 51, "caller_type": "npc_str_ptr", "context": "..." },
//         ...
//       ]
//     },
//     ...
//   }
// }

'use strict';

const fs   = require('fs');
const path = require('path');

const ROOT     = path.resolve(__dirname, '..', '..');
const SRC_DIR  = path.join(ROOT, 'src');
const OUT_FILE = path.join(__dirname, 'script_entries.json');

// Files to scan (all .asm files at root + src/)
const ASM_FILES = [
  ...fs.readdirSync(SRC_DIR).filter(f => f.endsWith('.asm')).map(f => path.join(SRC_DIR, f)),
  path.join(ROOT, 'header.asm'),
  path.join(ROOT, 'constants.asm'),
  path.join(ROOT, 'macros.asm'),
].filter(f => fs.existsSync(f));

// ── Step 1: Collect all script string label definitions ──────────────────────
//
// A label is considered a "script entry point" if:
//   (a) Its name ends with "Str" (by far the most common convention), OR
//   (b) The line immediately following the label contains dc.b with a quoted string
//       or a script_cmd_* macro call.
//
// We record: label name → { file, line }

const definitions = {}; // label → { file, line }

function collectDefinitions(filePath, lines) {
  const rel = path.relative(ROOT, filePath).replace(/\\/g, '/');
  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i];
    // Match a label at column 0: identifier followed by ':'
    const m = raw.match(/^([A-Za-z_][A-Za-z0-9_]*)\s*:/);
    if (!m) continue;
    const label = m[1];

    // Criterion (a): ends with "Str"
    if (label.endsWith('Str')) {
      definitions[label] = { file: rel, line: i + 1 };
      continue;
    }

    // Criterion (b): next non-blank line starts with dc.b + quote, or script_cmd_*
    for (let j = i + 1; j < Math.min(i + 4, lines.length); j++) {
      const next = lines[j].trim();
      if (next === '' || next.startsWith(';')) continue;
      if (
        /^dc\.b\s+["']/.test(next) ||
        /^script_cmd_/.test(next) ||
        (/^dc\.b/.test(next) && /SCRIPT_|0x[Ff][0-9A-Fa-f]|\$F[0-9A-Fa-f]/.test(next))
      ) {
        definitions[label] = { file: rel, line: i + 1 };
      }
      break; // only check first non-blank line
    }
  }
}

// ── Step 2: Collect all caller sites ─────────────────────────────────────────
//
// Patterns:
//   NPC str ptr:   MOVE.l  #<Label>, obj_npc_str_ptr(...)
//   print macro:   print <Label>  (or MOVE.l #<Label>, Script_source_base)
//   pointer table: dc.l <Label>   (in a dispatch/pointer table context)
//   Script_source_base direct: MOVE.l #<Label>, Script_source_base

const callers = {}; // label → [ { file, line, caller_type, context } ]

function addCaller(label, entry) {
  if (!callers[label]) callers[label] = [];
  callers[label].push(entry);
}

function collectCallers(filePath, lines) {
  const rel = path.relative(ROOT, filePath).replace(/\\/g, '/');
  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i];
    const trimmed = raw.trim();

    // Pattern 1: MOVE.l #<Label>, obj_npc_str_ptr(...)
    {
      const m = raw.match(/MOVE\.l\s+#([A-Za-z_][A-Za-z0-9_]*)\s*,\s*obj_npc_str_ptr/);
      if (m) {
        addCaller(m[1], {
          file: rel, line: i + 1,
          caller_type: 'npc_str_ptr',
          context: trimmed,
        });
        continue;
      }
    }

    // Pattern 2: print <Label>  (macro invocation)
    {
      const m = raw.match(/^\s+print\s+([A-Za-z_][A-Za-z0-9_]*)/);
      if (m) {
        addCaller(m[1], {
          file: rel, line: i + 1,
          caller_type: 'print_macro',
          context: trimmed,
        });
        continue;
      }
    }

    // Pattern 3: MOVE.l #<Label>, Script_source_base (direct assignment)
    {
      const m = raw.match(/MOVE\.l\s+#([A-Za-z_][A-Za-z0-9_]*)\s*,\s*Script_source_base/);
      if (m) {
        addCaller(m[1], {
          file: rel, line: i + 1,
          caller_type: 'script_source_base',
          context: trimmed,
        });
        continue;
      }
    }

    // Pattern 4: dc.l <Label>  — pointer table entry
    // Only capture if the label is a known script entry (checked post-scan)
    {
      const m = raw.match(/^\s+dc\.l\s+([A-Za-z_][A-Za-z0-9_]*)/);
      if (m) {
        // Defer — we need definitions first; store tentatively
        addCaller(m[1], {
          file: rel, line: i + 1,
          caller_type: 'pointer_table',
          context: trimmed,
        });
        // (pruned post-scan for labels not in definitions)
      }
    }
  }
}

// ── Run both passes over all files ──────────────────────────────────────────

const fileCache = {};
for (const filePath of ASM_FILES) {
  try {
    const text = fs.readFileSync(filePath, 'utf8');
    const lines = text.split('\n');
    fileCache[filePath] = lines;
    collectDefinitions(filePath, lines);
  } catch (e) {
    // skip unreadable files
  }
}

for (const filePath of ASM_FILES) {
  if (fileCache[filePath]) {
    collectCallers(filePath, fileCache[filePath]);
  }
}

// ── Prune pointer_table callers to only known labels ─────────────────────────

for (const [label, callList] of Object.entries(callers)) {
  callers[label] = callList.filter(c =>
    c.caller_type !== 'pointer_table' || definitions[label] !== undefined
  );
}

// ── Build output ─────────────────────────────────────────────────────────────

const entries = {};

// All defined labels
for (const [label, def] of Object.entries(definitions)) {
  entries[label] = {
    defined_in:   def.file,
    defined_line: def.line,
    callers:      callers[label] || [],
  };
}

// Also include labels that have callers but no definition found (forward refs, etc.)
for (const [label, callList] of Object.entries(callers)) {
  if (!entries[label] && callList.length > 0) {
    entries[label] = {
      defined_in:   null,
      defined_line: null,
      callers:      callList,
    };
  }
}

// Sort by label name
const sorted = {};
for (const key of Object.keys(entries).sort()) {
  sorted[key] = entries[key];
}

const totalDefs    = Object.values(sorted).filter(e => e.defined_in).length;
const totalCallers = Object.values(sorted).reduce((n, e) => n + e.callers.length, 0);
const unreferenced = Object.values(sorted).filter(e => e.callers.length === 0 && e.defined_in).length;
const undefined_   = Object.values(sorted).filter(e => !e.defined_in).length;

const output = {
  _meta: {
    description:     'Sword of Vermilion script entry point index',
    generated_by:    'tools/index/script_entries.js',
    total_labels:    Object.keys(sorted).length,
    total_defined:   totalDefs,
    total_callers:   totalCallers,
    unreferenced:    unreferenced,
    undefined_labels: undefined_,
    caller_types: {
      npc_str_ptr:       'MOVE.l #Label, obj_npc_str_ptr(...) — NPC dialogue assignment in npc.asm',
      print_macro:       'print Label — inline print macro call',
      script_source_base:'MOVE.l #Label, Script_source_base — direct VM program counter set',
      pointer_table:     'dc.l Label — entry in a dialogue dispatch pointer table',
    },
  },
  entries: sorted,
};

fs.writeFileSync(OUT_FILE, JSON.stringify(output, null, 2));

console.log(`Script entry index written to ${path.relative(ROOT, OUT_FILE)}`);
console.log(`  Labels defined:    ${totalDefs}`);
console.log(`  Total call sites:  ${totalCallers}`);
console.log(`  Unreferenced:      ${unreferenced}`);
console.log(`  Callers w/o def:   ${undefined_}`);
