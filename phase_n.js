// Phase N: Rewrite parallax data records with readable string literals
// Each record format:
//   dc.l  VDP_ctrl          ; 4 bytes
//   dc.w  col_count_minus1  ; 2 bytes (word; actual columns = value + 1)
//   dc.w  tile_attr         ; 2 bytes
//   dc.b  "text..."         ; col_count_minus1 + 1 bytes of ASCII

const fs = require('fs');

const filePath = 'src/miscdata.asm';
let src = fs.readFileSync(filePath, 'utf8');
const lines = src.split('\n');

// Collect all bytes from a block of dc.b lines (multiple lines until next label or blank)
// Returns {bytes, lineCount} from startLine
function collectBytes(lines, startLine) {
    const bytes = [];
    let i = startLine;
    while (i < lines.length) {
        const line = lines[i];
        // Stop at a label line (non-indented, ends with :) or blank or non-dc.b
        if (line.match(/^[^\s;]/) || line.trim() === '') break;
        const m = line.match(/^\s+dc\.b\s+(.+)/);
        if (!m) break;
        // Parse comma-separated hex/decimal values
        const parts = m[1].split(',').map(s => s.trim().replace(/;.*$/, '').trim()).filter(Boolean);
        for (const p of parts) {
            if (p.startsWith('$')) {
                bytes.push(parseInt(p.slice(1), 16));
            } else {
                bytes.push(parseInt(p, 10));
            }
        }
        i++;
    }
    return { bytes, lineCount: i - startLine };
}

// Format a 4-byte VDP ctrl as dc.l $XXXXXXXX
function fmtVdpCtrl(b) {
    const v = (b[0] << 24 | b[1] << 16 | b[2] << 8 | b[3]) >>> 0;
    return '$' + v.toString(16).toUpperCase().padStart(8, '0');
}

// Format a 2-byte word as $XXXX
function fmtWord(hi, lo) {
    return '$' + ((hi << 8 | lo) >>> 0).toString(16).toUpperCase().padStart(4, '0');
}

// Determine tile attr name from value
function tileAttrComment(val) {
    if (val === 0x84C0) return 'normal tile';
    if (val === 0xA4C0) return 'wide/title tile';
    if (val === 0xC4C0) return 'special tile';
    return 'tile attr';
}

// Escape a byte for use in ASM string (only printable ASCII 0x20-0x7E, no backslash or quotes)
// Returns null if not directly embeddable
function isSafeChar(b) {
    return b >= 0x20 && b <= 0x7E && b !== 0x5C && b !== 0x22 && b !== 0x27;
}

// Build replacement lines for a record starting at 'labelLine' (e.g. "DebugMenu_Row_InputTest:")
// The raw data lines follow immediately after the label.
// Returns null if record doesn't match expected pattern.
function buildReplacement(labelLine, bytes) {
    if (bytes.length < 8) return null;
    const vdpCtrl = fmtVdpCtrl(bytes);
    const colMinus1 = (bytes[4] << 8) | bytes[5];
    const colCount = colMinus1 + 1;
    const tileAttrVal = (bytes[6] << 8) | bytes[7];
    const tileAttr = fmtWord(bytes[6], bytes[7]);
    const allTextBytes = bytes.slice(8);
    // Some records have a trailing $00 alignment pad after the col_count text bytes
    const hasNullPad = allTextBytes.length === colCount + 1 && allTextBytes[colCount] === 0x00;
    if (allTextBytes.length !== colCount && !hasNullPad) return null; // sanity check
    const textBytes = allTextBytes.slice(0, colCount);

    // Decode text
    // Build a quoted string, falling back to hex escapes for non-printable chars
    // ASM68K supports dc.b "string" for ASCII strings
    let textParts = [];
    let currentStr = '';
    for (const b of textBytes) {
        if (isSafeChar(b)) {
            currentStr += String.fromCharCode(b);
        } else {
            if (currentStr) { textParts.push('"' + currentStr + '"'); currentStr = ''; }
            textParts.push('$' + b.toString(16).toUpperCase().padStart(2, '0'));
        }
    }
    if (currentStr) textParts.push('"' + currentStr + '"');
    // Append the null pad if present (preserves byte count)
    if (hasNullPad) textParts.push('$00');

    const textDecl = textParts.join(', ');

    const vdpComment = `VDP write cmd`;
    const colComment = `col count-1 = ${colMinus1} (${colCount} cols)`;
    const attrComment = tileAttrComment(tileAttrVal);

    const TAB = '\t';
    const lines = [
        labelLine,
        `${TAB}dc.l\t${vdpCtrl}\t\t\t\t; ${vdpComment}`,
        `${TAB}dc.w\t${fmtWord(bytes[4], bytes[5])}\t\t\t\t\t; ${colComment}`,
        `${TAB}dc.w\t${tileAttr}\t\t\t\t\t; ${attrComment}`,
        `${TAB}dc.b\t${textDecl}`,
    ];
    return lines.join('\n');
}

// Find all Debug*_Row_* label blocks and replace them
// Strategy: scan line by line, detect label, collect following dc.b lines, replace
const LABEL_RE = /^(Debug\w+_Row_\w+|DebugSound_Row_\w+|DebugCRTTest_Row_\w+):\s*$/;

let i = 0;
const outLines = [];

while (i < lines.length) {
    const line = lines[i];
    const labelMatch = line.match(LABEL_RE);
    if (labelMatch) {
        const labelLine = line.trimEnd();
        // Collect raw dc.b lines
        const { bytes, lineCount } = collectBytes(lines, i + 1);
        if (lineCount > 0 && bytes.length >= 8) {
            const replacement = buildReplacement(labelLine, bytes);
            if (replacement) {
                outLines.push(replacement);
                i += 1 + lineCount; // skip label + dc.b lines
                continue;
            }
        }
        // fallback: keep as-is
        outLines.push(line);
        i++;
    } else {
        outLines.push(line);
        i++;
    }
}

const result = outLines.join('\n');

// Verify byte count stays the same by counting dc.b/dc.w/dc.l bytes
// (We trust the logic; verification is done by verify.bat)

fs.writeFileSync(filePath, result, 'utf8');
console.log('Phase N: Done. Rewrote parallax data records with string literals.');
console.log('Run: cmd //c verify.bat');
