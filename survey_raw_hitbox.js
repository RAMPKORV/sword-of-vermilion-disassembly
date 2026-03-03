// survey_raw_hitbox.js
// Scans vermilion.asm for raw $2E/$2F/$30/$31/$32/$36 offset uses on Ax registers
// Categorizes by access size (.b/.w/.l) to distinguish hitbox byte fields vs word/long uses

const fs = require('fs');
const raw = fs.readFileSync('vermilion.asm', 'utf8');
const lines = raw.replace(/\r\n/g, '\n').split('\n');

// Pattern: matches $2E/$2F/$30/$31/$32/$36 used as struct offsets on address registers
// Groups: [lineNum, size, offset, reg]
const results = [];

for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lineNum = i + 1;

    // Match patterns like: $2E(A5), $2F(A6), $30(A4), $31(A5), $32(A4), $36(A4)
    // Also -$30(A2) style (fmch stride) - we skip those
    const match = line.match(/\$(2[EF]|3[012346])\((A[0-9])\)/);
    if (!match) continue;

    const offset = '$' + match[1].toUpperCase();
    const reg = match[2];

    // Determine access size from instruction mnemonic
    let size = '?';
    const instr = line.trim();
    if (/MOVE\.b|MOVEA\.b|CLR\.b|TST\.b|BSET\.b|BCLR\.b|BTST\.b|ADDQ\.b|SUBQ\.b|CMPI\.b/i.test(instr)) size = '.b';
    else if (/MOVE\.w|MOVEA\.w|CLR\.w|TST\.w|BSET\.w|BCLR\.w|CMPI\.w|ADD\.w|SUB\.w|ADDQ\.w|SUBQ\.w/i.test(instr)) size = '.w';
    else if (/MOVE\.l|MOVEA\.l|CLR\.l|TST\.l|BSET\.l|BCLR\.l|ADD\.l|SUB\.l/i.test(instr)) size = '.l';
    else if (/LEA/i.test(instr)) size = 'LEA';

    results.push({ lineNum, size, offset, reg, line: line.trim() });
}

// Group by offset + size
const groups = {};
for (const r of results) {
    const key = `${r.offset} ${r.size}`;
    if (!groups[key]) groups[key] = [];
    groups[key].push(r);
}

// Print summary
const keys = Object.keys(groups).sort();
for (const key of keys) {
    const items = groups[key];
    console.log(`\n${key}  (${items.length} occurrences):`);
    for (const r of items) {
        console.log(`  line ${r.lineNum}: ${r.line}`);
    }
}

console.log(`\nTotal raw offset uses: ${results.length}`);
