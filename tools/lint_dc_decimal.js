'use strict';
// lint_dc_decimal.js
// Scans all .asm files in the build for dc.b / dc.w / dc.l lines that contain
// unadorned decimal integer literals (not preceded by $ or %).
// These are the most common cause of non-bit-perfect builds in ASM68K because
// the assembler may encode them differently from hex in certain contexts.
//
// Usage: node tools/lint_dc_decimal.js
// Exit 0 = clean, Exit 1 = violations found

const fs   = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');

// All .asm files that participate in the build (from vermilion.asm includes)
const BUILD_FILES = [
  'header.asm',
  'init.asm',
  'macros.asm',
  'constants.asm',
  ...fs.readdirSync(path.join(ROOT, 'src'))
        .filter(f => f.endsWith('.asm'))
        .map(f => path.join('src', f)),
];

// Regex: a dc directive followed by one or more comma-separated values
// We flag any value token that looks like a plain decimal integer:
//   - starts with an optional sign or just a digit
//   - does NOT start with $, %, or a quote
//   - is not a label reference (we allow bare 0 if it looks like a symbol,
//     but in dc context a bare number is always a literal)
// We allow: $hex, %binary, 'char', "string", symbol_name
// We flag: bare decimal integers like 0, 1, 22, 255, etc.
//
// Note: MOVEQ #n, Dn and MOVE.w #n, Dx are SAFE with decimal — only dc.* matters.
const DC_LINE_RE = /^\s*dc\.[bwl]\s+/i;

// Split a dc argument list into individual tokens, respecting quotes
function tokenize(argStr) {
  const tokens = [];
  let cur = '';
  let inStr = false;
  let strChar = '';
  for (let i = 0; i < argStr.length; i++) {
    const ch = argStr[i];
    if (inStr) {
      cur += ch;
      if (ch === strChar) inStr = false;
    } else if (ch === "'" || ch === '"') {
      inStr = true;
      strChar = ch;
      cur += ch;
    } else if (ch === ',') {
      tokens.push(cur.trim());
      cur = '';
    } else if (ch === ';') {
      break; // rest is comment
    } else {
      cur += ch;
    }
  }
  if (cur.trim()) tokens.push(cur.trim());
  return tokens;
}

// Returns true if the token is a plain decimal integer literal (flaggable)
function isDecimalLiteral(tok) {
  // Strip leading unary minus/plus
  const s = tok.replace(/^[+-]/, '').trim();
  // Must be purely digits (no $ % ' ")
  return /^\d+$/.test(s);
}

let violations = [];

for (const relPath of BUILD_FILES) {
  const fullPath = path.join(ROOT, relPath);
  if (!fs.existsSync(fullPath)) continue;
  const lines = fs.readFileSync(fullPath, 'utf8').split('\n');
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!DC_LINE_RE.test(line)) continue;
    // Strip the dc.x prefix to get the argument list
    const argPart = line.replace(DC_LINE_RE, '');
    const tokens = tokenize(argPart);
    for (const tok of tokens) {
      if (isDecimalLiteral(tok)) {
        violations.push({ file: relPath, line: i + 1, token: tok, source: line.trimEnd() });
      }
    }
  }
}

if (violations.length === 0) {
  console.log('lint_dc_decimal: OK — no decimal literals in dc.* directives.');
  process.exit(0);
} else {
  console.error(`lint_dc_decimal: FAIL — ${violations.length} decimal literal(s) found in dc.* directives:`);
  for (const v of violations) {
    console.error(`  ${v.file}:${v.line}: token="${v.token}"  |  ${v.source}`);
  }
  process.exit(1);
}
