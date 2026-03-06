#!/usr/bin/env node
// tools/script_disasm.js — Sword of Vermilion script bytecode disassembler (VM-006)
//
// Usage:
//   node tools/script_disasm.js <label>           # disassemble by label name
//   node tools/script_disasm.js 0x<addr>          # disassemble by ROM address (hex)
//   node tools/script_disasm.js --all              # disassemble all *Str labels
//   node tools/script_disasm.js --list             # list all *Str labels with addresses
//
// Options:
//   --rom <path>     Path to ROM binary  (default: out.bin)
//   --limit <n>      Stop after <n> bytes (safety cap, default 2048)
//   --no-chars       Don't render printable characters (show CHAR opcode instead)
//   --json           Output disassembly as JSON instead of text
//   --help           Show this help
//
// Depends on:
//   tools/index/symbol_map.json  (LABEL-004)
//   tools/index/script_opcodes.json (VM-001)
//
// Build the ROM first: cmd //c build.bat
'use strict';

const fs = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const ROOT = path.join(__dirname, '..');
const SYMBOL_MAP_PATH = path.join(ROOT, 'tools', 'index', 'symbol_map.json');
const OPCODES_PATH    = path.join(ROOT, 'tools', 'index', 'script_opcodes.json');
const DEFAULT_ROM     = path.join(ROOT, 'out.bin');
const FONT_TILE_BASE  = 0x04C0;

// ---------------------------------------------------------------------------
// Parse arguments
// ---------------------------------------------------------------------------
const args = process.argv.slice(2);
if (args.includes('--help') || args.length === 0) {
  console.log(`Usage:
  node tools/script_disasm.js <label>           Disassemble string by label name
  node tools/script_disasm.js 0x<addr>          Disassemble by ROM address (hex)
  node tools/script_disasm.js --all             Disassemble all *Str labels
  node tools/script_disasm.js --list            List all *Str labels with addresses

Options:
  --rom <path>     ROM binary path (default: out.bin)
  --limit <n>      Max bytes to decode (default 2048)
  --no-chars       Show CHAR opcode for printable bytes instead of text
  --json           Output as JSON
  --help           Show this help`);
  process.exit(0);
}

// Parse flags and value-taking options
let romPath  = DEFAULT_ROM;
let limitArg = 2048;
const noChars   = args.includes('--no-chars');
const jsonOut   = args.includes('--json');
const doAll     = args.includes('--all');
const doList    = args.includes('--list');

const skipIndices = new Set();
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--rom'   && i + 1 < args.length) { romPath  = args[i + 1]; skipIndices.add(i); skipIndices.add(i + 1); }
  if (args[i] === '--limit' && i + 1 < args.length) { limitArg = parseInt(args[i + 1], 10); skipIndices.add(i); skipIndices.add(i + 1); }
  if (args[i].startsWith('--')) skipIndices.add(i);
}
const target = args.find((a, i) => !skipIndices.has(i));

// ---------------------------------------------------------------------------
// Load support files
// ---------------------------------------------------------------------------
function loadJSON(p) {
  if (!fs.existsSync(p)) {
    console.error(`Missing: ${p}\nBuild the ROM first with: cmd //c build.bat`);
    process.exit(1);
  }
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

const symbolMap = loadJSON(SYMBOL_MAP_PATH);
const opcodesData = loadJSON(OPCODES_PATH);

// ---------------------------------------------------------------------------
// Build reverse address→label map (ROM addresses only, lst source)
// ---------------------------------------------------------------------------
const addrToLabel = new Map(); // address (number) → [label, ...]
for (const [name, info] of Object.entries(symbolMap)) {
  if (info.source === 'lst') {
    const addr = parseInt(info.address, 16);
    if (!addrToLabel.has(addr)) addrToLabel.set(addr, []);
    addrToLabel.get(addr).push(name);
  }
}

// ---------------------------------------------------------------------------
// Build opcode lookup: byte_value → opcode info
// Handles ranges like "0x00-0xDD"
// ---------------------------------------------------------------------------
const opcodeMap = new Map(); // byte (0-255) → opcode entry

for (const op of opcodesData.opcodes) {
  const byteStr = op.byte;
  if (byteStr.includes('-')) {
    const [loStr, hiStr] = byteStr.split('-');
    const lo = parseInt(loStr, 16);
    const hi = parseInt(hiStr, 16);
    for (let b = lo; b <= hi; b++) {
      opcodeMap.set(b, op);
    }
  } else {
    const b = parseInt(byteStr, 16);
    opcodeMap.set(b, op);
  }
}

// ---------------------------------------------------------------------------
// Load ROM
// ---------------------------------------------------------------------------
if (!fs.existsSync(romPath)) {
  console.error(`ROM not found: ${romPath}\nRun: cmd //c build.bat`);
  process.exit(1);
}
const rom = fs.readFileSync(romPath);

// ---------------------------------------------------------------------------
// Core disassembler
// ---------------------------------------------------------------------------
/**
 * Disassemble one script string starting at romAddr.
 * Returns an array of instruction objects.
 */
function disassemble(romAddr, limit) {
  const instructions = [];
  let offset = romAddr;
  const end = Math.min(romAddr + limit, rom.length);

  while (offset < end) {
    const instrAddr = offset;
    const byte = rom[offset];

    // Label(s) at this address (skip the entry label itself at romAddr)
    const labels = (instrAddr > romAddr) ? (addrToLabel.get(instrAddr) || []) : [];

    const op = opcodeMap.get(byte);
    if (!op) {
      instructions.push({ addr: instrAddr, labels, raw: [byte], mnemonic: 'UNKNOWN', text: null, note: `unrecognized byte 0x${byte.toString(16).toUpperCase()}` });
      offset++;
      continue;
    }

    const mnemonic = op.mnemonic;

    // Display characters ($00–$DD and $E0–$F6) — output as text
    if (mnemonic === 'CHAR') {
      // Collect a run of consecutive display chars for compactness
      let run = [];
      while (offset < end) {
        const b = rom[offset];
        const o = opcodeMap.get(b);
        if (!o || o.mnemonic !== 'CHAR') break;
        // Stop run at any new label (except entry point)
        if (offset > romAddr && (addrToLabel.get(offset) || []).length > 0) break;
        run.push(b);
        offset++;
      }
      if (run.length === 0) { offset++; continue; }
      const text = run.map(b => (b >= 0x20 && b <= 0x7E) ? String.fromCharCode(b) : `\\x${b.toString(16).padStart(2,'0')}`).join('');
      if (noChars) {
        for (let i = 0; i < run.length; i++) {
          instructions.push({ addr: instrAddr + i, labels: i === 0 ? labels : [], raw: [run[i]], mnemonic: 'CHAR', text: null, operands: [{ name: 'byte', value: `0x${run[i].toString(16).toUpperCase().padStart(2,'0')}` }] });
        }
      } else {
        instructions.push({ addr: instrAddr, labels, raw: run, mnemonic: 'TEXT', text });
      }
      continue;
    }

    // Wide characters
    if (mnemonic === 'WIDE_HI' || mnemonic === 'WIDE_LO') {
      instructions.push({ addr: instrAddr, labels, raw: [byte], mnemonic, text: null, operands: [] });
      offset++;
      continue;
    }

    // PLAYER_NAME, NEWLINE, CONTINUE — no operands
    if (mnemonic === 'PLAYER_NAME' || mnemonic === 'NEWLINE') {
      instructions.push({ addr: instrAddr, labels, raw: [byte], mnemonic, text: null, operands: [] });
      offset++;
      continue;
    }

    if (mnemonic === 'CONTINUE') {
      instructions.push({ addr: instrAddr, labels, raw: [byte], mnemonic, text: null, operands: [] });
      offset++;
      continue;
    }

    // QUESTION [$FC, response_index]
    if (mnemonic === 'QUESTION') {
      const responseIdx = rom[offset + 1];
      instructions.push({ addr: instrAddr, labels, raw: [byte, responseIdx], mnemonic, text: null,
        operands: [{ name: 'response_index', value: `0x${responseIdx.toString(16).toUpperCase().padStart(2,'0')}` }] });
      offset += 2;
      continue;
    }

    // YES_NO [$FB, response_index, trigger_offset, ext_trigger]
    if (mnemonic === 'YES_NO') {
      const ri = rom[offset + 1], to = rom[offset + 2], et = rom[offset + 3];
      instructions.push({ addr: instrAddr, labels, raw: [byte, ri, to, et], mnemonic, text: null,
        operands: [
          { name: 'response_index', value: `0x${ri.toString(16).toUpperCase().padStart(2,'0')}` },
          { name: 'trigger_offset',  value: `0x${to.toString(16).toUpperCase().padStart(2,'0')}` },
          { name: 'ext_trigger',     value: `0x${et.toString(16).toUpperCase().padStart(2,'0')}` }
        ] });
      offset += 4;
      continue;
    }

    // CHOICE [$FA, response_index, map_trigger]
    if (mnemonic === 'CHOICE') {
      const ri = rom[offset + 1], mt = rom[offset + 2];
      instructions.push({ addr: instrAddr, labels, raw: [byte, ri, mt], mnemonic, text: null,
        operands: [
          { name: 'response_index', value: `0x${ri.toString(16).toUpperCase().padStart(2,'0')}` },
          { name: 'map_trigger',    value: `0x${mt.toString(16).toUpperCase().padStart(2,'0')}` }
        ] });
      offset += 3;
      continue;
    }

    // TRIGGERS [$F8, count, offset0, offset1, ...]
    if (mnemonic === 'TRIGGERS') {
      const count = rom[offset + 1];
      const raw = [byte, count];
      const ops = [];
      for (let i = 0; i < count && offset + 2 + i < end; i++) {
        const trig = rom[offset + 2 + i];
        raw.push(trig);
        ops.push({ name: `trigger_${i}`, value: `0x${trig.toString(16).toUpperCase().padStart(2,'0')}` });
      }
      instructions.push({ addr: instrAddr, labels, raw, mnemonic, text: null, operands: ops });
      offset += 2 + count;
      continue;
    }

    // ACTIONS [$F9, count, action_type, ...] — variable-length entries
    if (mnemonic === 'ACTIONS') {
      const count = rom[offset + 1];
      const raw = [byte, count];
      const ops = [{ name: 'count', value: count.toString() }];
      let cur = offset + 2;
      for (let i = 0; i < count && cur < end; i++) {
        const type = rom[cur]; raw.push(type);
        if (type === 0x00) {
          // [$00, offset.b] set trigger
          const trig = rom[cur + 1]; raw.push(trig);
          ops.push({ name: `action_${i}`, value: `SET_TRIGGER 0x${trig.toString(16).toUpperCase().padStart(2,'0')}` });
          cur += 2;
        } else if (type === 0x01) {
          // [$01, sector.b] reveal sector
          const sec = rom[cur + 1]; raw.push(sec);
          ops.push({ name: `action_${i}`, value: `REVEAL_SECTOR 0x${sec.toString(16).toUpperCase().padStart(2,'0')}` });
          cur += 2;
        } else if (type === 0x02) {
          // [$02, bcd0..3] give kims (4 BCD bytes)
          const b0 = rom[cur+1], b1 = rom[cur+2], b2 = rom[cur+3], b3 = rom[cur+4];
          raw.push(b0, b1, b2, b3);
          ops.push({ name: `action_${i}`, value: `GIVE_KIMS ${b0.toString(16).toUpperCase().padStart(2,'0')}${b1.toString(16).toUpperCase().padStart(2,'0')}${b2.toString(16).toUpperCase().padStart(2,'0')}${b3.toString(16).toUpperCase().padStart(2,'0')}` });
          cur += 5;
        } else {
          // unknown action type
          ops.push({ name: `action_${i}`, value: `UNKNOWN(0x${type.toString(16).toUpperCase().padStart(2,'0')})` });
          cur += 1;
        }
      }
      instructions.push({ addr: instrAddr, labels, raw, mnemonic, text: null, operands: ops });
      offset = cur;
      continue;
    }

    // END ($FF) — stop disassembly
    if (mnemonic === 'END') {
      instructions.push({ addr: instrAddr, labels, raw: [byte], mnemonic, text: null, operands: [] });
      // Skip optional $00 alignment padding
      offset++;
      break;
    }

    // Fallback
    instructions.push({ addr: instrAddr, labels, raw: [byte], mnemonic: op.mnemonic, text: null, operands: [] });
    offset++;
  }

  return instructions;
}

// ---------------------------------------------------------------------------
// Text formatter
// ---------------------------------------------------------------------------
function formatInstructions(label, addr, instructions) {
  const lines = [];
  lines.push(`; ${label}  @ 0x${addr.toString(16).toUpperCase().padStart(6,'0')}`);
  lines.push(';' + '-'.repeat(70));
  for (const instr of instructions) {
    const addrStr = `0x${instr.addr.toString(16).toUpperCase().padStart(6,'0')}`;
    const rawStr = instr.raw.map(b => b.toString(16).toUpperCase().padStart(2,'0')).join(' ');

    // Emit any labels at this address (other than entry label)
    for (const lbl of instr.labels) {
      lines.push(`${lbl}:`);
    }

    if (instr.mnemonic === 'TEXT') {
      lines.push(`  ${addrStr}  ${rawStr.padEnd(30)}  "${instr.text}"`);
    } else if (instr.mnemonic === 'CHAR') {
      const opStr = instr.operands ? instr.operands.map(o => o.value).join(', ') : '';
      lines.push(`  ${addrStr}  ${rawStr.padEnd(30)}  CHAR ${opStr}`);
    } else {
      const opStr = instr.operands && instr.operands.length
        ? '  ' + instr.operands.map(o => `${o.name}=${o.value}`).join(', ')
        : '';
      const note = instr.note ? `  ; ${instr.note}` : '';
      lines.push(`  ${addrStr}  ${rawStr.padEnd(30)}  ${instr.mnemonic}${opStr}${note}`);
    }
  }
  return lines.join('\n');
}

// ---------------------------------------------------------------------------
// Resolve label or hex address to ROM offset
// ---------------------------------------------------------------------------
function resolveTarget(t) {
  if (!t) return null;
  if (t.startsWith('0x') || t.startsWith('0X')) {
    return parseInt(t, 16);
  }
  // look up in symbol map
  const entry = symbolMap[t];
  if (!entry) return null;
  return parseInt(entry.address, 16);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
if (doList) {
  const strLabels = Object.entries(symbolMap)
    .filter(([k, v]) => k.endsWith('Str') && v.source === 'lst')
    .sort((a, b) => parseInt(a[1].address, 16) - parseInt(b[1].address, 16));
  if (jsonOut) {
    console.log(JSON.stringify(strLabels.map(([k, v]) => ({ label: k, address: v.address })), null, 2));
  } else {
    for (const [k, v] of strLabels) {
      console.log(`  0x${parseInt(v.address, 16).toString(16).toUpperCase().padStart(6,'0')}  ${k}`);
    }
    console.log(`\n${strLabels.length} string labels`);
  }
  process.exit(0);
}

if (doAll) {
  const strLabels = Object.entries(symbolMap)
    .filter(([k, v]) => k.endsWith('Str') && v.source === 'lst')
    .sort((a, b) => parseInt(a[1].address, 16) - parseInt(b[1].address, 16));

  const results = [];
  for (const [label, info] of strLabels) {
    const addr = parseInt(info.address, 16);
    if (addr >= rom.length) continue;
    const instructions = disassemble(addr, limitArg);
    results.push({ label, address: `0x${addr.toString(16).toUpperCase().padStart(6,'0')}`, instructions });
  }

  if (jsonOut) {
    console.log(JSON.stringify(results, null, 2));
  } else {
    for (const r of results) {
      console.log(formatInstructions(r.label, parseInt(r.address, 16), r.instructions));
      console.log('');
    }
    console.log(`; ${results.length} strings disassembled`);
  }
  process.exit(0);
}

// Single label/address
if (!target) {
  console.error('Error: no target specified. Use --help for usage.');
  process.exit(1);
}

const addr = resolveTarget(target);
if (addr === null || addr === undefined) {
  console.error(`Error: label or address "${target}" not found in symbol_map.json`);
  process.exit(1);
}
if (addr >= rom.length) {
  console.error(`Error: address 0x${addr.toString(16)} is outside ROM (size 0x${rom.length.toString(16)})`);
  process.exit(1);
}

const instructions = disassemble(addr, limitArg);

if (jsonOut) {
  console.log(JSON.stringify({ label: target, address: `0x${addr.toString(16).toUpperCase().padStart(6,'0')}`, instructions }, null, 2));
} else {
  const labelName = target.startsWith('0x') || target.startsWith('0X')
    ? `0x${addr.toString(16).toUpperCase().padStart(6,'0')}`
    : target;
  console.log(formatInstructions(labelName, addr, instructions));
}
