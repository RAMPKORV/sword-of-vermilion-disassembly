// Replace dc.l $XXXXXXXX VDP write commands in miscdata.asm with vdpCmd macro
// Only replaces lines matching: dc.l TAB $XXXXXXXX TAB TAB ; VDP write cmd

const fs = require('fs');

const file = 'src/miscdata.asm';
let text = fs.readFileSync(file, 'utf8');
const lines = text.split('\n');
let count = 0;

function decodeVramAddr(v) {
  // For VRAM write (type=0x01):
  // bits 31-30 = 01, bits 7-4 = 0000, bits 1-0 = A15-A14
  // bits 29-16 = A13-A0
  const addrLow = (v >>> 16) & 0x3FFF;
  const addrHigh = (v & 3) << 14;
  return addrLow | addrHigh;
}

for (let i = 0; i < lines.length; i++) {
  const l = lines[i];
  // Match: whitespace dc.l whitespace $XXXXXXXX whitespace ; VDP write cmd
  const m = l.match(/^(\s+dc\.l\s+)\$([4-7][0-9A-Fa-f]{7})(\s*;\s*VDP write cmd.*)$/i);
  if (m) {
    const hex = m[2];
    const v = parseInt(hex, 16);
    // Check it's a VRAM write (bits 31-30 = 01, bits 7-4 = 0000)
    const cd10 = (v >>> 30) & 3;
    const cd54 = (v >>> 4) & 0xF;
    if (cd10 === 1 && cd54 === 0) {
      const addr = decodeVramAddr(v);
      const addrHex = addr.toString(16).toUpperCase().padStart(4, '0');
      // Replace with vdpCmd macro
      lines[i] = `\tvdpCmd\t$${addrHex}, VDP_TYPE_VRAM_WRITE\t\t\t; $${hex.toUpperCase()} (VRAM write to $${addrHex})`;
      count++;
    }
  }
}

if (count > 0) {
  fs.writeFileSync(file, lines.join('\n'), 'utf8');
  console.log(`Replaced ${count} dc.l VDP write commands with vdpCmd macro in ${file}`);
} else {
  console.log('No matches found');
}
