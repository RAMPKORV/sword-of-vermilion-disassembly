const fs = require('fs');

let content = fs.readFileSync('vermilion.asm', 'utf8');

// Pattern for complete stopZ80 sequences (with wait loop)
// MOVE.w #$0100, Z80_bus_request
// loc_XXXXXXXX:
// BTST.b #0, Z80_bus_request
// BNE.b loc_XXXXXXXX
const stopPattern = /\tMOVE\.w\t#\$0100, Z80_bus_request\n(loc_[0-9A-F]+:)\n\tBTST\.b\t#0, Z80_bus_request\n\tBNE\.b\t\1\n/g;

content = content.replace(stopPattern, '\tstopZ80\n');

// Pattern for startZ80 (simple replacement)
content = content.replace(/\tMOVE\.w\t#0, Z80_bus_request\n/g, '\tstartZ80\n');

fs.writeFileSync('vermilion.asm', content, 'utf8');

console.log('Z80 macro replacements completed');
