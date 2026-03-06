const fs = require('fs');
const path = require('path');

// Pattern: MOVE.l #$dest, D7 / MOVE.w #$len, D6 / MOVE.b #0, D5 / MOVE.w #1, D4 / JSR VDP_DMAFill
const jsrPat = /\tMOVE\.l\t#(\$[0-9A-Fa-f]+), D7[\t ]*\r?\n\tMOVE\.w\t#(\$[0-9A-Fa-f]+), D6[\t ]*\r?\n\tMOVE\.b\t#0, D5[\t ]*\r?\n\tMOVE\.w\t#1, D4[\t ]*\r?\n\tJSR\tVDP_DMAFill/g;

const bsrPat = /\tMOVE\.l\t#(\$[0-9A-Fa-f]+), D7[\t ]*\r?\n\tMOVE\.w\t#(\$[0-9A-Fa-f]+), D6[\t ]*\r?\n\tMOVE\.b\t#0, D5[\t ]*\r?\n\tMOVE\.w\t#1, D4[\t ]*\r?\n\tBSR\.w\tVDP_DMAFill/g;

const jsrFiles = ['src/core.asm', 'src/gameplay.asm', 'src/towndata.asm'];
const bsrFiles = ['src/battle_gfx.asm'];

let total = 0;

for (const file of jsrFiles) {
    const fp = path.join(process.cwd(), file);
    let c = fs.readFileSync(fp, 'utf8');
    let count = 0;
    c = c.replace(jsrPat, (m, dest, len) => {
        count++;
        return '\tDMAFillVRAM ' + dest + ', ' + len;
    });
    if (count > 0) fs.writeFileSync(fp, c, 'utf8');
    console.log(file + ' (JSR): ' + count);
    total += count;
}

for (const file of bsrFiles) {
    const fp = path.join(process.cwd(), file);
    let c = fs.readFileSync(fp, 'utf8');
    let count = 0;
    c = c.replace(bsrPat, (m, dest, len) => {
        count++;
        return '\tDMAFillVRAM_bsr ' + dest + ', ' + len;
    });
    if (count > 0) fs.writeFileSync(fp, c, 'utf8');
    console.log(file + ' (BSR): ' + count);
    total += count;
}

console.log('Total: ' + total);
