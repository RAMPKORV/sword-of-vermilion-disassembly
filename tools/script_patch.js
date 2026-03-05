#!/usr/bin/env node
// tools/script_patch.js — Sword of Vermilion script reassembler / patch injector (VM-010)
//
// Takes a JSON patch file describing text changes and rewrites the corresponding
// dc.b lines in the ASM source files (src/*.asm).  Preserves all surrounding code,
// macros, and layout; only the dialogue bytes themselves are touched.
//
// Usage:
//   node tools/script_patch.js --patch <patch.json>
//   node tools/script_patch.js --patch <patch.json> --dry-run
//   node tools/script_patch.js --validate <patch.json>
//   node tools/script_patch.js --example
//   node tools/script_patch.js --help
//
// Patch file format  (patch.json):
//   [
//     {
//       "label": "Prologue1Str",
//       "new_text": "Long ago, King\nTsarkon ruled\nover Cartahena."
//     },
//     {
//       "label": "TookTreasureStr",
//       "raw_ops": [
//         { "mnemonic": "TEXT", "text": "You grabbed it." },
//         { "mnemonic": "ACTIONS", "actions": [ { "type": "SET_TRIGGER", "trigger": 6 } ] }
//       ]
//     }
//   ]
//
// Simple patches use "new_text":
//   - "\n"  encodes NEWLINE ($FE)
//   - "\f"  encodes CONTINUE ($FD)
//   - "\p"  encodes PLAYER_NAME ($F7)
//   - All other characters map to their raw ASCII byte
//
// Advanced patches use "raw_ops" — the same format exported by tools/index/strings.js.
// Supported mnemonics in raw_ops:
//   TEXT        { "mnemonic": "TEXT", "text": "..." }
//   NEWLINE     { "mnemonic": "NEWLINE" }
//   CONTINUE    { "mnemonic": "CONTINUE" }
//   END         { "mnemonic": "END" }
//   PLAYER_NAME { "mnemonic": "PLAYER_NAME" }
//   QUESTION    { "mnemonic": "QUESTION", "response_index": <n> }
//   YES_NO      { "mnemonic": "YES_NO", "response_index": <n>, "trigger_offset": <n>, "ext_trigger": <n> }
//   CHOICE      { "mnemonic": "CHOICE", "response_index": <n>, "map_trigger": <n> }
//   TRIGGERS    { "mnemonic": "TRIGGERS", "triggers": [<n>, ...] }
//   ACTIONS     { "mnemonic": "ACTIONS", "actions": [ ... ] }
//     Action types:  { "type": "SET_TRIGGER",    "trigger": <n> }
//                    { "type": "REVEAL_SECTOR",   "sector": <n> }
//                    { "type": "GIVE_KIMS",       "bcd": "<8 hex digits>" }
//   WIDE_HI     { "mnemonic": "WIDE_HI" }
//   WIDE_LO     { "mnemonic": "WIDE_LO" }
//
// Size constraint:
//   The reassembled byte sequence MUST fit in the original ROM span for this label
//   (determined by symbol_map.json: address of next *Str label in ROM minus this
//   label's address).  If shorter, $00 padding bytes are added.  If longer, the
//   tool aborts with an error.  Use --force-resize to override (breaks bit-perfect).
//
// After patching, run: cmd //c verify.bat
// A bit-perfect result confirms a no-op patch.  A non-bit-perfect result is expected
// when you actually change the text.
//
// Depends on:
//   tools/index/script_entries.json  (label → source file + line)
//   tools/index/symbol_map.json      (label → ROM address, for byte-span calculation)
//   tools/index/strings.json         (original raw_ops reference)
//
// Build before running: cmd //c build.bat  (regenerates symbol map / listing)

'use strict';

const fs   = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const ROOT           = path.resolve(__dirname, '..');
const ENTRIES_PATH   = path.join(ROOT, 'tools', 'index', 'script_entries.json');
const SYMBOL_MAP_PATH = path.join(ROOT, 'tools', 'index', 'symbol_map.json');
const STRINGS_PATH   = path.join(ROOT, 'tools', 'index', 'strings.json');
const DEFAULT_INDENT = '\t';

// ---------------------------------------------------------------------------
// Argument parsing
// ---------------------------------------------------------------------------
const args = process.argv.slice(2);

if (args.includes('--help') || args.length === 0) {
  printHelp();
  process.exit(0);
}

if (args.includes('--example')) {
  printExample();
  process.exit(0);
}

const DRY_RUN       = args.includes('--dry-run');
const FORCE_RESIZE  = args.includes('--force-resize');
const VALIDATE_ONLY = args.includes('--validate');

function getArg(flag) {
  const i = args.indexOf(flag);
  return (i !== -1 && i + 1 < args.length) ? args[i + 1] : null;
}

const patchArg = getArg('--patch') || getArg('--validate');
if (!patchArg) {
  console.error('Error: --patch <patch.json> is required. Use --help for usage.');
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Load support files
// ---------------------------------------------------------------------------
function loadJSON(p, name) {
  if (!fs.existsSync(p)) {
    console.error(`Missing: ${p}\n  Run: cmd //c build.bat  then regenerate indexes.`);
    process.exit(1);
  }
  try {
    return JSON.parse(fs.readFileSync(p, 'utf8'));
  } catch (e) {
    console.error(`Failed to parse ${name}: ${e.message}`);
    process.exit(1);
  }
}

const entriesData = loadJSON(ENTRIES_PATH, 'script_entries.json');
const entries     = entriesData.entries || entriesData;

const symbolMapRaw = loadJSON(SYMBOL_MAP_PATH, 'symbol_map.json');
// Build a map: label → ROM address (number), filtered to lst source only
const symbolMap = new Map();
for (const [name, info] of Object.entries(symbolMapRaw)) {
  if (info.source === 'lst') {
    symbolMap.set(name, parseInt(info.address, 16));
  }
}

const stringsArr = loadJSON(STRINGS_PATH, 'strings.json');
const stringsMap = new Map();
for (const e of stringsArr) {
  stringsMap.set(e.label, e);
}

// Load the patch file
const patchPath = path.resolve(patchArg);
if (!fs.existsSync(patchPath)) {
  console.error(`Patch file not found: ${patchPath}`);
  process.exit(1);
}
let patches;
try {
  patches = JSON.parse(fs.readFileSync(patchPath, 'utf8'));
} catch (e) {
  console.error(`Failed to parse patch file: ${e.message}`);
  process.exit(1);
}
if (!Array.isArray(patches)) {
  console.error('Patch file must be a JSON array of patch objects.');
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Symbol-map-based byte-span calculator
//
// For label X at address A, the in-source byte span is determined by the next
// label in the symbol map that appears immediately after X in ROM address order.
// This is the exact number of bytes in the ASM block between X: and the next
// label (which may be an intermediate label like FindTreasureStr inside what
// strings.json reports as a single string).
// ---------------------------------------------------------------------------

/**
 * Return the ROM byte span for `label`: the distance from its address to the
 * next defined label in ROM order.  Returns null if the label is not in the
 * symbol map or no next label exists.
 */
function getRomByteSpan(label) {
  const addr = symbolMap.get(label);
  if (addr === undefined) return null;

  // Find the smallest address strictly greater than addr
  let nextAddr = Infinity;
  for (const [, a] of symbolMap) {
    if (a > addr && a < nextAddr) nextAddr = a;
  }
  if (nextAddr === Infinity) return null;
  return nextAddr - addr;
}

// ---------------------------------------------------------------------------
// Byte encoder: raw_ops → number[]
// ---------------------------------------------------------------------------

function charToByte(ch) {
  return ch.charCodeAt(0);
}

/** Encode raw_ops to a number[]. Does NOT automatically append END. */
function encodeOps(ops) {
  const bytes = [];
  for (const op of ops) {
    switch (op.mnemonic) {
      case 'TEXT': {
        if (typeof op.text !== 'string') throw new Error('TEXT op missing "text" string');
        for (const ch of op.text) bytes.push(charToByte(ch));
        break;
      }
      case 'NEWLINE':    bytes.push(0xFE); break;
      case 'CONTINUE':   bytes.push(0xFD); break;
      case 'END':        bytes.push(0xFF); break;
      case 'PLAYER_NAME': bytes.push(0xF7); break;
      case 'WIDE_HI':    bytes.push(0xDF); break;
      case 'WIDE_LO':    bytes.push(0xDE); break;
      case 'QUESTION': {
        const ri = op.response_index;
        if (ri === undefined) throw new Error('QUESTION op missing "response_index"');
        bytes.push(0xFC, ri & 0xFF);
        break;
      }
      case 'YES_NO': {
        const ri = op.response_index, to = op.trigger_offset, et = op.ext_trigger;
        if (ri === undefined || to === undefined || et === undefined)
          throw new Error('YES_NO op missing response_index / trigger_offset / ext_trigger');
        bytes.push(0xFB, ri & 0xFF, to & 0xFF, et & 0xFF);
        break;
      }
      case 'CHOICE': {
        const ri = (op.response_index !== undefined) ? op.response_index
                                                     : (op.answer !== undefined ? op.answer : 0);
        const mt = op.map_trigger !== undefined ? op.map_trigger : 0;
        bytes.push(0xFA, ri & 0xFF, mt & 0xFF);
        break;
      }
      case 'TRIGGERS': {
        const triggers = op.triggers;
        if (!Array.isArray(triggers) || triggers.length === 0)
          throw new Error('TRIGGERS op missing "triggers" array');
        if (triggers.length > 2)
          throw new Error(`TRIGGERS: macro supports 1 or 2 triggers; got ${triggers.length}`);
        bytes.push(0xF8, triggers.length & 0xFF);
        for (const t of triggers) bytes.push(t & 0xFF);
        break;
      }
      case 'ACTIONS': {
        const actions = op.actions;
        if (!Array.isArray(actions) || actions.length === 0)
          throw new Error('ACTIONS op missing "actions" array');
        bytes.push(0xF9, actions.length & 0xFF);
        for (const action of actions) {
          switch (action.type) {
            case 'SET_TRIGGER':
              if (action.trigger === undefined) throw new Error('SET_TRIGGER missing "trigger"');
              bytes.push(0x00, action.trigger & 0xFF);
              break;
            case 'REVEAL_SECTOR':
              if (action.sector === undefined) throw new Error('REVEAL_SECTOR missing "sector"');
              bytes.push(0x01, action.sector & 0xFF);
              break;
            case 'GIVE_KIMS': {
              const bcd = action.bcd || '00000000';
              if (typeof bcd !== 'string' || !/^[0-9A-Fa-f]{8}$/.test(bcd))
                throw new Error(`GIVE_KIMS bcd must be 8 hex chars: ${bcd}`);
              bytes.push(0x02,
                parseInt(bcd.slice(0, 2), 16),
                parseInt(bcd.slice(2, 4), 16),
                parseInt(bcd.slice(4, 6), 16),
                parseInt(bcd.slice(6, 8), 16));
              break;
            }
            default:
              throw new Error(`Unknown action type in ACTIONS: ${action.type}`);
          }
        }
        break;
      }
      default:
        throw new Error(`Unknown mnemonic: ${op.mnemonic}`);
    }
  }
  return bytes;
}

// ---------------------------------------------------------------------------
// Text → ops parser
// Interprets escape sequences in "new_text":
//   \n → NEWLINE, \f → CONTINUE, \p → PLAYER_NAME, \\ → literal backslash
// Bare newline (\n in JSON) also maps to NEWLINE.
// Automatically appends END.
// ---------------------------------------------------------------------------
function parseNewText(text) {
  const ops = [];
  let i = 0;
  let chunk = '';

  function flushChunk() {
    if (chunk.length > 0) { ops.push({ mnemonic: 'TEXT', text: chunk }); chunk = ''; }
  }

  while (i < text.length) {
    if (text[i] === '\\' && i + 1 < text.length) {
      const next = text[i + 1];
      if (next === 'n') { flushChunk(); ops.push({ mnemonic: 'NEWLINE' });     i += 2; continue; }
      if (next === 'f') { flushChunk(); ops.push({ mnemonic: 'CONTINUE' });    i += 2; continue; }
      if (next === 'p') { flushChunk(); ops.push({ mnemonic: 'PLAYER_NAME' }); i += 2; continue; }
      if (next === '\\') { chunk += '\\'; i += 2; continue; }
      chunk += text[i]; i++;
    } else if (text[i] === '\n') {
      flushChunk(); ops.push({ mnemonic: 'NEWLINE' }); i++;
    } else {
      chunk += text[i]; i++;
    }
  }
  flushChunk();
  ops.push({ mnemonic: 'END' });
  return ops;
}

// ---------------------------------------------------------------------------
// ASM reassembler: ops → ASM source lines
// ---------------------------------------------------------------------------

function fmtByte(b) {
  return '$' + b.toString(16).toUpperCase().padStart(2, '0');
}

/**
 * Reassemble a sequence of raw_ops to ASM source lines.
 * Uses the same macro names as macros.asm.
 * ops must end with END.
 *
 * @param {Array}  ops    - raw_ops array
 * @param {string} indent - indentation string (default: one tab)
 * @param {number[]} paddingBytes - $00 padding bytes to append after END dc.b line
 * @returns {string[]}   - array of ASM lines
 */
function reassembleOpsToLines(ops, indent, paddingBytes) {
  indent = indent || DEFAULT_INDENT;
  paddingBytes = paddingBytes || [];
  const lines = [];

  // Accumulate dc.b arguments for the current line.
  // Each NEWLINE or CONTINUE flushes the pending args with a $FE/$FD suffix.
  // END flushes with SCRIPT_END.
  // Control-code ops (QUESTION, YES_NO, CHOICE, TRIGGERS, ACTIONS) always flush
  // pending args first, then emit a macro line.
  let currentArgs = [];

  function flushDcb(suffix) {
    // suffix: string to append as last arg, or null to just flush without suffix
    const argList = [...currentArgs];
    if (suffix !== null && suffix !== undefined) argList.push(suffix);
    if (argList.length > 0) {
      lines.push(`${indent}dc.b\t${argList.join(', ')}`);
    }
    currentArgs = [];
  }

  for (const op of ops) {
    switch (op.mnemonic) {
      case 'TEXT':
        if (typeof op.text === 'string' && op.text.length > 0) {
          currentArgs.push(`"${op.text}"`);
        }
        break;

      case 'NEWLINE':
        flushDcb('$FE');
        break;

      case 'CONTINUE':
        flushDcb('$FD');
        break;

      case 'PLAYER_NAME':
        // Emit inline in dc.b line (same style as original: dc.b "text", SCRIPT_PLAYER_NAME, "more")
        currentArgs.push('SCRIPT_PLAYER_NAME');
        break;

      case 'WIDE_HI':
        currentArgs.push('$DF');
        break;

      case 'WIDE_LO':
        currentArgs.push('$DE');
        break;

      case 'END': {
        // Flush with SCRIPT_END; append padding on same line if any, otherwise separate line
        if (paddingBytes.length > 0) {
          const argList = [...currentArgs, 'SCRIPT_END', ...paddingBytes.map(fmtByte)];
          lines.push(`${indent}dc.b\t${argList.join(', ')}`);
          currentArgs = [];
        } else {
          flushDcb('SCRIPT_END');
        }
        paddingBytes = []; // consumed
        break;
      }

      case 'QUESTION':
        flushDcb(null);
        lines.push(`${indent}script_cmd_question ${fmtByte(op.response_index || 0)}`);
        break;

      case 'YES_NO':
        flushDcb(null);
        lines.push(`${indent}script_cmd_yes_no ${fmtByte(op.response_index || 0)}, ${fmtByte(op.trigger_offset || 0)}, ${fmtByte(op.ext_trigger || 0)}`);
        break;

      case 'CHOICE':
        flushDcb(null);
        {
          const ri = (op.response_index !== undefined) ? op.response_index : (op.answer || 0);
          const mt = op.map_trigger || 0;
          lines.push(`${indent}script_cmd_choice ${fmtByte(ri)}, ${fmtByte(mt)}`);
        }
        break;

      case 'TRIGGERS':
        flushDcb(null);
        {
          const t = op.triggers || [];
          if (t.length === 1) {
            lines.push(`${indent}script_cmd_triggers ${fmtByte(t[0])}`);
          } else if (t.length === 2) {
            lines.push(`${indent}script_cmd_triggers ${fmtByte(t[0])}, ${fmtByte(t[1])}`);
          } else {
            // Fallback to raw dc.b
            lines.push(`${indent}dc.b\tSCRIPT_TRIGGERS, ${t.length}${t.map(x => ', ' + fmtByte(x)).join('')}`);
          }
        }
        break;

      case 'ACTIONS':
        flushDcb(null);
        {
          const acts = op.actions || [];
          lines.push(`${indent}script_cmd_actions ${acts.length}`);
          for (const a of acts) {
            switch (a.type) {
              case 'SET_TRIGGER':
                lines.push(`${indent}script_set_trigger ${fmtByte(a.trigger)}`);
                break;
              case 'REVEAL_SECTOR':
                lines.push(`${indent}script_reveal_map ${fmtByte(a.sector)}`);
                break;
              case 'GIVE_KIMS':
                lines.push(`${indent}script_give_kims $${(a.bcd || '00000000').toUpperCase()}`);
                break;
              default:
                throw new Error(`Unknown action type: ${a.type}`);
            }
          }
        }
        break;

      default:
        throw new Error(`Unknown mnemonic in reassembler: ${op.mnemonic}`);
    }
  }

  // Flush any remaining args (safety net)
  if (currentArgs.length > 0) flushDcb(null);

  // Remaining padding (if END was never hit)
  if (paddingBytes.length > 0) {
    lines.push(`${indent}dc.b\t${paddingBytes.map(fmtByte).join(', ')}`);
  }

  return lines;
}

// ---------------------------------------------------------------------------
// Find the ASM block for a label in a file's lines array.
// Returns { labelLineIdx, start, end } where:
//   labelLineIdx  = index of the "Label:" line
//   start         = first line after the label
//   end           = exclusive end (index of next label line, or next non-dc.b/non-blank line)
// ---------------------------------------------------------------------------
function findLabelBlock(fileLines, label) {
  let labelLineIdx = -1;
  for (let i = 0; i < fileLines.length; i++) {
    if (fileLines[i].trim() === label + ':') { labelLineIdx = i; break; }
  }
  if (labelLineIdx === -1) return null;

  const start = labelLineIdx + 1;
  let end = start;
  for (let i = start; i < fileLines.length; i++) {
    const l = fileLines[i].trim();
    // Stop at a new label (word chars followed immediately by colon)
    if (l.length > 0 && !l.startsWith(';') && /^\w[\w.]*:/.test(l) && !l.startsWith('dc.')) {
      end = i;
      break;
    }
    end = i + 1;
  }
  return { labelLineIdx, start, end };
}

// ---------------------------------------------------------------------------
// Detect indentation used in a block
// ---------------------------------------------------------------------------
function detectIndent(fileLines, start, end) {
  for (let i = start; i < end; i++) {
    const m = fileLines[i].match(/^(\s+)/);
    if (m) return m[1];
  }
  return DEFAULT_INDENT;
}

// ---------------------------------------------------------------------------
// Per-file line accumulator (apply multiple patches to the same file)
// ---------------------------------------------------------------------------
const fileChanges = new Map(); // relPath → { originalLines, newLines }

function getFileLines(relPath) {
  if (fileChanges.has(relPath)) return fileChanges.get(relPath).newLines;
  const fullPath = path.join(ROOT, relPath);
  if (!fs.existsSync(fullPath)) throw new Error(`Source file not found: ${fullPath}`);
  const raw  = fs.readFileSync(fullPath, 'utf8');
  const lines = raw.split('\n').map(l => l.replace(/\r$/, ''));
  fileChanges.set(relPath, { originalLines: lines.slice(), newLines: lines });
  return lines;
}

// ---------------------------------------------------------------------------
// Core patcher
// ---------------------------------------------------------------------------

function applyPatch(patch) {
  const label = patch.label;
  if (!label) throw new Error('Patch entry missing "label"');

  // Parse / validate ops
  let ops;
  if (patch.raw_ops) {
    ops = patch.raw_ops.slice();
    // Auto-append END only if the ops don't already end with a terminal opcode.
    // Terminal opcodes: END ($FF), TRIGGERS ($F8), ACTIONS ($F9) — all mark
    // Script_text_complete and/or stop further script execution.
    const TERMINAL = new Set(['END', 'TRIGGERS', 'ACTIONS']);
    if (ops.length === 0 || !TERMINAL.has(ops[ops.length - 1].mnemonic)) {
      ops.push({ mnemonic: 'END' });
    }
  } else if (patch.new_text !== undefined) {
    ops = parseNewText(patch.new_text);
  } else {
    throw new Error(`Patch for "${label}" must have "new_text" or "raw_ops"`);
  }

  // Find label in script_entries.json
  const entry = entries[label];
  if (!entry) throw new Error(`Label "${label}" not found in script_entries.json`);
  if (!entry.defined_in) throw new Error(`Label "${label}" has no defined_in`);

  // Compute the target byte span using the symbol map
  const romSpan = getRomByteSpan(label);

  // Encode ops to bytes
  let newBytes = encodeOps(ops);

  // Ensure END byte is present when the terminal opcode is END
  const lastOp = ops[ops.length - 1];
  if (lastOp && lastOp.mnemonic === 'END' && newBytes[newBytes.length - 1] !== 0xFF) {
    newBytes.push(0xFF);
  }

  const contentSize = newBytes.length;

  if (romSpan !== null) {
    if (contentSize > romSpan && !FORCE_RESIZE) {
      throw new Error(
        `"${label}": encoded size ${contentSize} > ROM span ${romSpan} byte(s). ` +
        `Shorten the text or use --force-resize (breaks bit-perfect).`
      );
    }
    if (contentSize < romSpan) {
      // Pad with $00 to fill the original span
      for (let i = contentSize; i < romSpan; i++) newBytes.push(0x00);
    }
  }

  const paddingBytes = newBytes.slice(contentSize); // $00s after END

  // Load source file
  const fileLines = getFileLines(entry.defined_in);

  // Find the block
  const block = findLabelBlock(fileLines, label);
  if (!block) throw new Error(`Label "${label}:" not found in ${entry.defined_in}`);
  const { start, end } = block;

  // Detect indentation
  const indent = detectIndent(fileLines, start, end);

  // Reassemble ops to ASM lines
  const newAsmLines = reassembleOpsToLines(ops, indent, paddingBytes);

  // Replace block lines
  fileLines.splice(start, end - start, ...newAsmLines);

  return {
    label,
    file: entry.defined_in,
    originalLineCount: end - start,
    newLineCount: newAsmLines.length,
    romSpan: romSpan !== null ? romSpan : '?',
    newByteCount: newBytes.length,
  };
}

// ---------------------------------------------------------------------------
// Validate patch file without applying changes
// ---------------------------------------------------------------------------
function validatePatches(patches) {
  let ok = true;
  for (const patch of patches) {
    const label = patch.label || '(missing label)';
    try {
      if (!patch.label) throw new Error('Missing "label" field');
      const entry = entries[patch.label];
      if (!entry) throw new Error('Label not found in script_entries.json');

      let ops;
      if (patch.raw_ops) {
        ops = patch.raw_ops.slice();
        const TERMINAL = new Set(['END', 'TRIGGERS', 'ACTIONS']);
        if (ops.length === 0 || !TERMINAL.has(ops[ops.length - 1].mnemonic)) ops.push({ mnemonic: 'END' });
      } else if (patch.new_text !== undefined) {
        ops = parseNewText(patch.new_text);
      } else {
        throw new Error('Missing "new_text" or "raw_ops"');
      }

      let bytes = encodeOps(ops);
      const lastOp = ops[ops.length - 1];
      if (lastOp && lastOp.mnemonic === 'END' && bytes[bytes.length - 1] !== 0xFF) bytes.push(0xFF);

      const romSpan = getRomByteSpan(patch.label);
      if (romSpan !== null && bytes.length > romSpan && !FORCE_RESIZE) {
        console.warn(`  WARN [${label}]: encoded ${bytes.length} bytes > ROM span ${romSpan} — too long`);
      } else {
        const spanStr = romSpan !== null ? `ROM span ${romSpan}` : 'ROM span unknown';
        console.log(`  OK   [${label}]: ${bytes.length} bytes (${spanStr})`);
      }
    } catch (e) {
      console.error(`  FAIL [${label}]: ${e.message}`);
      ok = false;
    }
  }
  return ok;
}

// ---------------------------------------------------------------------------
// Write all changed files
// ---------------------------------------------------------------------------
function writeChanges() {
  for (const [relPath, { originalLines, newLines }] of fileChanges.entries()) {
    const fullPath = path.join(ROOT, relPath);
    const orig = fs.readFileSync(fullPath, 'utf8');
    const useCRLF = (orig.match(/\r\n/g) || []).length > (orig.match(/(?<!\r)\n/g) || []).length;
    const sep = useCRLF ? '\r\n' : '\n';
    fs.writeFileSync(fullPath, newLines.join(sep));
    console.log(`  Written: ${relPath}`);
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

if (VALIDATE_ONLY) {
  console.log(`Validating ${patches.length} patch(es) from: ${patchArg}`);
  const ok = validatePatches(patches);
  process.exit(ok ? 0 : 1);
}

console.log(`Applying ${patches.length} patch(es) from: ${patchArg}${DRY_RUN ? '  [dry-run]' : ''}`);

let errors = 0;
const results = [];

for (const patch of patches) {
  try {
    const result = applyPatch(patch);
    results.push(result);
    console.log(`  OK   [${result.label}] ${result.file}  (${result.originalLineCount} → ${result.newLineCount} lines, ${result.romSpan} byte span)`);
  } catch (e) {
    console.error(`  FAIL [${patch.label || '?'}]: ${e.message}`);
    errors++;
  }
}

if (errors > 0) {
  console.error(`\n${errors} patch(es) failed. No files written.`);
  process.exit(1);
}

if (DRY_RUN) {
  console.log(`\nDry run complete. ${results.length} patch(es) would be applied.`);
  process.exit(0);
}

console.log('\nWriting changes...');
writeChanges();
console.log(`\nDone. ${results.length} patch(es) applied.`);
console.log('Run: cmd //c verify.bat');
console.log('  Bit-perfect = no-op patch (text unchanged)');
console.log('  Non-bit-perfect = expected when text is actually changed');

// ---------------------------------------------------------------------------
// Help / example
// ---------------------------------------------------------------------------
function printHelp() {
  console.log(`tools/script_patch.js — Sword of Vermilion script reassembler / patch injector

Usage:
  node tools/script_patch.js --patch <patch.json>               Apply patches
  node tools/script_patch.js --patch <patch.json> --dry-run     Dry run (no writes)
  node tools/script_patch.js --validate <patch.json>            Validate without applying
  node tools/script_patch.js --example                          Print example patch JSON
  node tools/script_patch.js --help                             Show this help

Options:
  --force-resize   Allow encoded size > ROM span (breaks bit-perfect, for actual ROM hacking)

Patch file: JSON array; each entry:
  "label"     — Script string label (e.g. "Prologue1Str")
  "new_text"  — Replacement text: \\n = NEWLINE, \\f = CONTINUE, \\p = PLAYER_NAME
  "raw_ops"   — Full opcode list (same format as tools/index/strings.json raw_ops)

After patching: cmd //c verify.bat`);
}

function printExample() {
  const example = [
    {
      "label": "Prologue1Str",
      "new_text": "Long ago, King\nTsarkon ruled\nover Cartahena.\nHe was quite mean.",
      "_comment": "Simple text: \\n = newline, \\f = continue prompt, \\p = player name."
    },
    {
      "label": "LongLiveKingStr",
      "new_text": "Hail, \\p!",
      "_comment": "\\p inserts the player name via PLAYER_NAME opcode."
    },
    {
      "label": "TookTreasureStr",
      "raw_ops": [
        { "mnemonic": "TEXT", "text": "You grabbed it." },
        { "mnemonic": "ACTIONS", "actions": [ { "type": "SET_TRIGGER", "trigger": 6 } ] }
      ],
      "_comment": "raw_ops for strings with control codes. ACTIONS implicitly marks END; do not add END manually."
    }
  ];
  console.log(JSON.stringify(example, null, 2));
}
