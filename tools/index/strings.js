#!/usr/bin/env node
// tools/index/strings.js — Sword of Vermilion string index generator (VM-007)
//
// Reads out.bin and tools/index/symbol_map.json, decodes every script string
// reachable via a *Str label, and writes tools/index/strings.json:
//
//   [
//     {
//       "label":   "Prologue1Str",
//       "address": "0x015BAE",
//       "text":    "Once upon a time...",
//       "raw_ops": [...],          // decoded opcode stream
//       "byte_length": 42          // total bytes consumed (including END)
//     },
//     ...
//   ]
//
// "text" is a human-readable plain-text rendering of the string:
//   - TEXT runs are included verbatim
//   - NEWLINE → "\n"
//   - CONTINUE → " [CONTINUE]\n"  (wait-for-button page break)
//   - PLAYER_NAME → "[PLAYER_NAME]"
//   - WIDE_HI/WIDE_LO → "[WIDE]"
//   - QUESTION/YES_NO/CHOICE → "[CHOICE]"
//   - TRIGGERS/ACTIONS → "[TRIGGER/ACTION]"
//   - END → (terminates, not included in text)
//   - UNKNOWN → "[?0xNN]"
//
// Usage:
//   node tools/index/strings.js            # writes tools/index/strings.json
//   node tools/index/strings.js --stats    # also print summary stats to stdout
//
// Depends on:
//   tools/index/symbol_map.json   (LABEL-004)
//   tools/index/script_opcodes.json (VM-001)
//   out.bin                        (build the ROM first)
//
'use strict';

const fs   = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Paths
// ---------------------------------------------------------------------------
const ROOT        = path.join(__dirname, '..', '..');
const SYMBOL_MAP  = path.join(ROOT, 'tools', 'index', 'symbol_map.json');
const OPCODES_F   = path.join(ROOT, 'tools', 'index', 'script_opcodes.json');
const ROM_PATH    = path.join(ROOT, 'out.bin');
const OUT_PATH    = path.join(__dirname, 'strings.json');

const showStats = process.argv.includes('--stats');

// ---------------------------------------------------------------------------
// Load files
// ---------------------------------------------------------------------------
function loadJSON(p) {
  if (!fs.existsSync(p)) {
    console.error(`Missing required file: ${p}`);
    if (p.endsWith('out.bin')) console.error('  Run: cmd //c build.bat');
    process.exit(1);
  }
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function loadBin(p) {
  if (!fs.existsSync(p)) {
    console.error(`ROM not found: ${p}\n  Run: cmd //c build.bat`);
    process.exit(1);
  }
  return fs.readFileSync(p);
}

const symbolMap  = loadJSON(SYMBOL_MAP);
const opcodesData = loadJSON(OPCODES_F);
const rom        = loadBin(ROM_PATH);

// ---------------------------------------------------------------------------
// Build opcode lookup: byte → opcode entry
// Handles range strings like "0x00-0xDD"
// ---------------------------------------------------------------------------
const opcodeMap = new Map();
for (const op of opcodesData.opcodes) {
  const s = op.byte;
  if (s.includes('-')) {
    const [lo, hi] = s.split('-').map(x => parseInt(x, 16));
    for (let b = lo; b <= hi; b++) opcodeMap.set(b, op);
  } else {
    opcodeMap.set(parseInt(s, 16), op);
  }
}

// ---------------------------------------------------------------------------
// Collect all *Str labels, sorted by ROM address
// ---------------------------------------------------------------------------
const strLabels = Object.entries(symbolMap)
  .filter(([k, v]) => k.endsWith('Str') && v.source === 'lst')
  .map(([label, v]) => ({ label, address: parseInt(v.address, 16) }))
  .sort((a, b) => a.address - b.address);

// ---------------------------------------------------------------------------
// Decode one string starting at romAddr
// Returns { text, raw_ops, byte_length }
// ---------------------------------------------------------------------------
const DECODE_LIMIT = 4096; // safety cap: no single string should be this long

function decode(romAddr) {
  const raw_ops = [];
  let offset    = romAddr;
  const end     = Math.min(romAddr + DECODE_LIMIT, rom.length);
  const textParts = [];

  while (offset < end) {
    const byte = rom[offset];
    const op   = opcodeMap.get(byte);

    if (!op) {
      raw_ops.push({ mnemonic: 'UNKNOWN', byte: `0x${byte.toString(16).toUpperCase().padStart(2,'0')}` });
      textParts.push(`[?0x${byte.toString(16).toUpperCase().padStart(2,'0')}]`);
      offset++;
      continue;
    }

    const m = op.mnemonic;

    // --- Display character run ---
    if (m === 'CHAR') {
      let run = [];
      while (offset < end) {
        const b  = rom[offset];
        const ob = opcodeMap.get(b);
        if (!ob || ob.mnemonic !== 'CHAR') break;
        run.push(b);
        offset++;
      }
      // Render printable ASCII verbatim; non-ASCII as \xNN escape
      const rendered = run.map(b =>
        (b >= 0x20 && b <= 0x7E) ? String.fromCharCode(b) : `\\x${b.toString(16).padStart(2, '0')}`
      ).join('');
      raw_ops.push({ mnemonic: 'TEXT', bytes: run.map(b => b.toString(16).toUpperCase().padStart(2,'0')), text: rendered });
      textParts.push(rendered);
      continue;
    }

    // --- NEWLINE ---
    if (m === 'NEWLINE') {
      raw_ops.push({ mnemonic: 'NEWLINE', byte: `0x${byte.toString(16).toUpperCase().padStart(2,'0')}` });
      textParts.push('\n');
      offset++;
      continue;
    }

    // --- CONTINUE (wait-for-button page break) ---
    if (m === 'CONTINUE') {
      raw_ops.push({ mnemonic: 'CONTINUE', byte: `0x${byte.toString(16).toUpperCase().padStart(2,'0')}` });
      textParts.push(' [CONTINUE]\n');
      offset++;
      continue;
    }

    // --- PLAYER_NAME ---
    if (m === 'PLAYER_NAME') {
      raw_ops.push({ mnemonic: 'PLAYER_NAME', byte: `0x${byte.toString(16).toUpperCase().padStart(2,'0')}` });
      textParts.push('[PLAYER_NAME]');
      offset++;
      continue;
    }

    // --- WIDE_HI / WIDE_LO ---
    if (m === 'WIDE_HI' || m === 'WIDE_LO') {
      raw_ops.push({ mnemonic: m, byte: `0x${byte.toString(16).toUpperCase().padStart(2,'0')}` });
      textParts.push('[WIDE]');
      offset++;
      continue;
    }

    // --- QUESTION [$FC, response_index] ---
    if (m === 'QUESTION') {
      const ri = rom[offset + 1];
      raw_ops.push({ mnemonic: 'QUESTION', response_index: ri });
      textParts.push(`[QUESTION:${ri}]`);
      offset += 2;
      continue;
    }

    // --- YES_NO [$FB, response_index, trigger_offset, ext_trigger] ---
    if (m === 'YES_NO') {
      const ri = rom[offset + 1], to = rom[offset + 2], et = rom[offset + 3];
      raw_ops.push({ mnemonic: 'YES_NO', response_index: ri, trigger_offset: to, ext_trigger: et });
      textParts.push(`[YES_NO:ri=${ri},trig=${to},ext=${et}]`);
      offset += 4;
      continue;
    }

    // --- CHOICE [$FA, response_index, map_trigger] ---
    if (m === 'CHOICE') {
      const ri = rom[offset + 1], mt = rom[offset + 2];
      raw_ops.push({ mnemonic: 'CHOICE', response_index: ri, map_trigger: mt });
      textParts.push(`[CHOICE:ri=${ri},map=${mt}]`);
      offset += 3;
      continue;
    }

    // --- TRIGGERS [$F8, count, offset0, ...] ---
    if (m === 'TRIGGERS') {
      const count = rom[offset + 1];
      const triggers = [];
      for (let i = 0; i < count && offset + 2 + i < end; i++) triggers.push(rom[offset + 2 + i]);
      raw_ops.push({ mnemonic: 'TRIGGERS', triggers });
      textParts.push(`[TRIGGERS:${triggers.map(t => t.toString(16).toUpperCase().padStart(2,'0')).join(',')}]`);
      offset += 2 + count;
      continue;
    }

    // --- ACTIONS [$F9, count, action_type, ...] ---
    if (m === 'ACTIONS') {
      const count = rom[offset + 1];
      const actions = [];
      let cur = offset + 2;
      for (let i = 0; i < count && cur < end; i++) {
        const type = rom[cur];
        if (type === 0x00) {
          const trig = rom[cur + 1];
          actions.push({ type: 'SET_TRIGGER', trigger: trig });
          cur += 2;
        } else if (type === 0x01) {
          const sec = rom[cur + 1];
          actions.push({ type: 'REVEAL_SECTOR', sector: sec });
          cur += 2;
        } else if (type === 0x02) {
          const b0 = rom[cur+1], b1 = rom[cur+2], b2 = rom[cur+3], b3 = rom[cur+4];
          actions.push({ type: 'GIVE_KIMS', bcd: [b0,b1,b2,b3].map(b=>b.toString(16).toUpperCase().padStart(2,'0')).join('') });
          cur += 5;
        } else {
          actions.push({ type: `UNKNOWN(0x${type.toString(16).toUpperCase().padStart(2,'0')})` });
          cur++;
        }
      }
      raw_ops.push({ mnemonic: 'ACTIONS', actions });
      textParts.push(`[ACTIONS:${actions.map(a=>a.type).join(',')}]`);
      offset = cur;
      continue;
    }

    // --- END ($FF) ---
    if (m === 'END') {
      raw_ops.push({ mnemonic: 'END', byte: '0xFF' });
      offset++; // consume the END byte
      break;
    }

    // --- Fallback ---
    raw_ops.push({ mnemonic: m, byte: `0x${byte.toString(16).toUpperCase().padStart(2,'0')}` });
    textParts.push(`[${m}]`);
    offset++;
  }

  return {
    text:        textParts.join(''),
    raw_ops,
    byte_length: offset - romAddr
  };
}

// ---------------------------------------------------------------------------
// Decode all strings
// ---------------------------------------------------------------------------
const results = [];
for (const { label, address } of strLabels) {
  if (address >= rom.length) continue;
  const { text, raw_ops, byte_length } = decode(address);
  results.push({
    label,
    address: `0x${address.toString(16).toUpperCase().padStart(6,'0')}`,
    text,
    raw_ops,
    byte_length
  });
}

// ---------------------------------------------------------------------------
// Write output
// ---------------------------------------------------------------------------
fs.writeFileSync(OUT_PATH, JSON.stringify(results, null, 2), 'utf8');

const totalBytes = results.reduce((s, r) => s + r.byte_length, 0);
console.log(`strings.js: ${results.length} strings written to tools/index/strings.json`);
console.log(`  Total decoded bytes : ${totalBytes}`);
console.log(`  Avg bytes per string: ${(totalBytes / results.length).toFixed(1)}`);

if (showStats) {
  // Count by mnemonic across all strings
  const mnemonicCounts = {};
  for (const r of results) {
    for (const op of r.raw_ops) {
      mnemonicCounts[op.mnemonic] = (mnemonicCounts[op.mnemonic] || 0) + 1;
    }
  }
  console.log('\n  Opcode frequencies:');
  const sorted = Object.entries(mnemonicCounts).sort((a, b) => b[1] - a[1]);
  for (const [m, n] of sorted) {
    console.log(`    ${m.padEnd(14)} ${n}`);
  }
}
