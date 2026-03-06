'use strict';
// tools/report_macro_opportunities.js
//
// For each macro defined in macros.asm, scan src/*.asm (and init.asm,
// header.asm) for instruction sequences that match its known expansion
// pattern and report file + line as adoption opportunities.
//
// This automates the MACRO-00x audits and catches regressions.
//
// Usage:
//   node tools/report_macro_opportunities.js [--out <report.txt>]
//
// Exit 0 always (this is a report, not a gate).

const fs   = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const args     = process.argv.slice(2);

function getArg(flag, def) {
  const i = args.indexOf(flag);
  return i !== -1 && args[i + 1] ? args[i + 1] : def;
}

const outFile = getArg('--out', null);

// ---------------------------------------------------------------------------
// Files to scan
// ---------------------------------------------------------------------------
const BUILD_FILES = [
  'init.asm',
  'header.asm',
  ...fs.readdirSync(path.resolve(repoRoot, 'src'))
      .filter(f => f.endsWith('.asm'))
      .map(f => `src/${f}`),
];

function readFile(rel) {
  const abs = path.resolve(repoRoot, rel);
  return fs.existsSync(abs) ? fs.readFileSync(abs, 'utf8').split('\n').map(l => l.replace(/\r$/, '')) : [];
}

// ---------------------------------------------------------------------------
// Macro pattern definitions
// Each entry:
//   name:     macro name
//   desc:     brief description
//   patterns: array of regex arrays. A match requires ALL regexes to match
//             consecutive non-blank, non-comment lines (sliding window).
//             Use null to match any non-blank line (wildcard).
// ---------------------------------------------------------------------------
const MACROS = [
  // --------------------------------------------------------------------------
  // IsPalRegion — single instruction
  // --------------------------------------------------------------------------
  {
    name: 'IsPalRegion',
    desc: 'PAL/NTSC region test via IO_version bit 6',
    patterns: [
      [/BTST\.b\s+#[0-9]+\s*,\s*(?:\$00A10001|IO_version)/i],
    ],
    exclude: /macros\.asm/,   // don't flag the macro definition itself
  },

  // --------------------------------------------------------------------------
  // PlaySound / PlaySound_b — MOVE #id, D0  +  JSR QueueSoundEffect
  // --------------------------------------------------------------------------
  {
    name: 'PlaySound / PlaySound_b',
    desc: 'MOVE.w/#.b soundId, D0  +  JSR QueueSoundEffect',
    patterns: [
      [/MOVE\.[bw]\s+#.+,\s*D0/i, /JSR\s+QueueSoundEffect/i],
    ],
  },

  // --------------------------------------------------------------------------
  // CheckButton — MOVE.w #button, D2  +  JSR CheckButtonPress
  // --------------------------------------------------------------------------
  {
    name: 'CheckButton',
    desc: 'MOVE.w #button, D2  +  JSR CheckButtonPress',
    patterns: [
      [/MOVE\.w\s+#.+,\s*D2/i, /JSR\s+CheckButtonPress/i],
    ],
  },

  // --------------------------------------------------------------------------
  // DMAFillVRAM — 5-instruction DMA fill setup + JSR/BSR VDP_DMAFill
  // --------------------------------------------------------------------------
  {
    name: 'DMAFillVRAM / DMAFillVRAM_bsr',
    desc: '5-instruction DMA fill pattern: MOVE.l dest, D7 + MOVE.w len, D6 + MOVE.b #0, D5 + MOVE.w #1, D4 + JSR/BSR VDP_DMAFill',
    patterns: [
      [
        /MOVE\.l\s+#.+,\s*D7/i,
        /MOVE\.w\s+#.+,\s*D6/i,
        /MOVE\.b\s+#0\s*,\s*D5/i,
        /MOVE\.w\s+#1\s*,\s*D4/i,
        /[JB]SR(?:\.w)?\s+VDP_DMAFill/i,
      ],
    ],
  },

  // --------------------------------------------------------------------------
  // stopZ80 — MOVE.w #$100, (Z80_bus_request/.l)  +  BTST loop
  // --------------------------------------------------------------------------
  {
    name: 'stopZ80',
    desc: 'MOVE.w #$100, Z80_bus_request + busy-loop pattern',
    patterns: [
      [
        /MOVE\.w\s+#\$?100\s*,\s*\(Z80_bus_request\)/i,
        /BTST\.b\s+#0\s*,\s*\(Z80_bus_request\)/i,
      ],
    ],
  },

  // --------------------------------------------------------------------------
  // startZ80 — MOVE.w #0, (Z80_bus_request)
  // --------------------------------------------------------------------------
  {
    name: 'startZ80',
    desc: 'MOVE.w #0, Z80_bus_request (after bus acquired)',
    patterns: [
      [/MOVE\.w\s+#0\s*,\s*\(Z80_bus_request\)/i],
    ],
  },

  // --------------------------------------------------------------------------
  // SetupWindow — 5 MOVEs + BSR DrawWindowBorder
  // --------------------------------------------------------------------------
  {
    name: 'SetupWindow',
    desc: '5-instruction window setup: x/y/w/h + attrs=0 + BSR DrawWindowBorder',
    patterns: [
      [
        /MOVE\.w\s+#.+,\s*Window_tilemap_x/i,
        /MOVE\.w\s+#.+,\s*Window_tilemap_y/i,
        /MOVE\.w\s+#.+,\s*Window_width/i,
        /MOVE\.w\s+#.+,\s*Window_height/i,
        /MOVE\.w\s+#0\s*,\s*Window_tile_attrs/i,
        /BSR\.w\s+DrawWindowBorder/i,
      ],
    ],
  },

  // --------------------------------------------------------------------------
  // TriggerWindowRedraw / TriggerWindowRedraw_alt
  // --------------------------------------------------------------------------
  {
    name: 'TriggerWindowRedraw',
    desc: 'MOVE Window_draw_type + CLR Window_text_row + MOVE Window_tilemap_row_draw_pending',
    patterns: [
      [
        /MOVE\.w\s+#.+,\s*Window_draw_type/i,
        /CLR\.w\s+Window_text_row/i,
        /MOVE\.b\s+#FLAG_TRUE\s*,\s*Window_tilemap_row_draw_pending/i,
      ],
      [
        /MOVE\.w\s+#.+,\s*Window_draw_type/i,
        /MOVE\.b\s+#FLAG_TRUE\s*,\s*Window_tilemap_row_draw_pending/i,
        /CLR\.w\s+Window_text_row/i,
      ],
    ],
  },

  // --------------------------------------------------------------------------
  // ActivateWindowDraw — CLR Window_draw_row + MOVE #FLAG_TRUE, Window_tilemap_draw_active
  // --------------------------------------------------------------------------
  {
    name: 'ActivateWindowDraw',
    desc: 'CLR Window_draw_row + MOVE FLAG_TRUE Window_tilemap_draw_active',
    patterns: [
      [
        /CLR\.w\s+Window_draw_row/i,
        /MOVE\.b\s+#FLAG_TRUE\s*,\s*Window_tilemap_draw_active/i,
      ],
    ],
  },

  // --------------------------------------------------------------------------
  // InitMenuCursor — 4-MOVE cursor init sequence
  // --------------------------------------------------------------------------
  {
    name: 'InitMenuCursor',
    desc: 'MOVE cols + MOVE MENU_CURSOR_NONE + MOVE x + MOVE y',
    patterns: [
      [
        /MOVE\.w\s+#.+,\s*Menu_cursor_column_break/i,
        /MOVE\.w\s+#MENU_CURSOR_NONE\s*,\s*Menu_cursor_last_index/i,
        /MOVE\.w\s+#.+,\s*Menu_cursor_base_x/i,
        /MOVE\.w\s+#.+,\s*Menu_cursor_base_y/i,
      ],
    ],
  },
];

// ---------------------------------------------------------------------------
// Sliding-window multi-line matcher
// ---------------------------------------------------------------------------
function findPatternMatches(lines, regexes) {
  const hits = [];
  const W = regexes.length;

  // Build an index of "instruction lines" (skip blanks and pure comment lines)
  const instrLines = [];
  lines.forEach((ln, i) => {
    const t = ln.trim();
    if (t.length > 0 && !t.startsWith(';')) instrLines.push({ line: ln, lineNo: i + 1, idx: i });
  });

  for (let i = 0; i <= instrLines.length - W; i++) {
    let allMatch = true;
    for (let j = 0; j < W; j++) {
      if (!regexes[j].test(instrLines[i + j].line)) { allMatch = false; break; }
    }
    if (allMatch) {
      hits.push(instrLines[i].lineNo);
    }
  }
  return hits;
}

// ---------------------------------------------------------------------------
// Main scan
// ---------------------------------------------------------------------------
const report = [];

for (const macro of MACROS) {
  const macroHits = [];

  for (const relFile of BUILD_FILES) {
    if (macro.exclude && macro.exclude.test(relFile)) continue;

    const lines = readFile(relFile);
    if (lines.length === 0) continue;

    for (const patternSeq of macro.patterns) {
      const hits = findPatternMatches(lines, patternSeq);
      for (const lineNo of hits) {
        macroHits.push({ file: relFile, line: lineNo });
      }
    }
  }

  if (macroHits.length > 0) {
    report.push({ macro: macro.name, desc: macro.desc, hits: macroHits });
  }
}

// ---------------------------------------------------------------------------
// Output
// ---------------------------------------------------------------------------
const lines = [];
lines.push('='.repeat(70));
lines.push('  Macro Adoption Opportunity Report — Sword of Vermilion');
lines.push('='.repeat(70));
lines.push('');

if (report.length === 0) {
  lines.push('  No raw macro-expansion patterns found. All macros fully adopted.');
} else {
  let total = 0;
  for (const entry of report) {
    total += entry.hits.length;
    lines.push(`  ${entry.macro}  (${entry.hits.length} site${entry.hits.length === 1 ? '' : 's'})`);
    lines.push(`  ${entry.desc}`);
    for (const h of entry.hits) {
      lines.push(`    ${h.file}:${h.line}`);
    }
    lines.push('');
  }
  lines.push(`  Total: ${total} potential macro adoption site(s) across ${report.length} macro(s)`);
}

lines.push('='.repeat(70));

const text = lines.join('\n') + '\n';
if (outFile) {
  fs.writeFileSync(path.resolve(repoRoot, outFile), text, 'utf8');
  console.log(`Report written to ${outFile}`);
} else {
  process.stdout.write(text);
}

process.exit(0);
