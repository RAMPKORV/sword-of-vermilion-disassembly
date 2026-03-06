const fs = require('fs');
const files = [
  'src/cutscene.asm','src/magic.asm','src/miscdata.asm','src/boss.asm',
  'src/dungeon.asm','src/bossbattle.asm','src/towndata.asm','src/enemy.asm',
  'src/items.asm','src/player.asm','src/gameplay.asm','src/script.asm',
  'src/sram.asm','src/npc.asm'
];

// Match MOVE.l #$XXXXXXXX or ORI.l #$XXXXXXXX patterns with 8-digit hex in range $40000000-$7FFFFFFF or $C0000000-$CFFFFFFF
// These are VDP command longwords
const vdpCmdRe = /[#,]\s*\$([4-7C][0-9A-Fa-f]{7})\b/g;

function decodeVdpCmd(v) {
  // CD bits: b31-30 and b7-4 (upper 4) and b1-0 (lower 2, but shifted)
  const cd10 = (v >>> 30) & 3;
  const cd54 = ((v >>> 4) & 0xF) >> 2; // bits 5-4 of CD mapped from bits 5-4
  const cdBits = cd10 | (((v >> 4) & 0xF) << 2);
  // addr: bits 29-16 (A13-A0) and bits 1-0 (A15-A14)
  const addrLow = (v >>> 16) & 0x3FFF;
  const addrHigh = (v & 3) << 14;
  const addr = addrLow | addrHigh;
  return { cd: cdBits, addr };
}

const totals = {};
const allLines = [];

for (const f of files) {
  try {
    const t = fs.readFileSync(f, 'utf8');
    const lines = t.split('\n');
    lines.forEach((l, i) => {
      // Skip pure comment lines
      if (/^\s*;/.test(l)) return;
      // Skip DMAFillVRAM macro calls and dmaCmd entries (not control port writes)
      const m = l.match(/[#]\s*\$([4-7C][0-9A-Fa-f]{7})\b/);
      if (m) {
        const hex = m[1].toUpperCase();
        const v = parseInt(hex, 16);
        const { cd, addr } = decodeVdpCmd(v);
        totals[hex] = (totals[hex] || 0) + 1;
        allLines.push({ file: f, line: i + 1, hex, v, cd, addr, text: l.trim() });
      }
    });
  } catch(e) { console.error('Cannot read', f, e.message); }
}

// Print summary by value
console.log('\n=== UNIQUE VDP COMMAND VALUES ===');
const sorted = Object.entries(totals).sort((a,b) => b[1]-a[1]);
for (const [hex, count] of sorted) {
  const v = parseInt(hex, 16);
  const { cd, addr } = decodeVdpCmd(v);
  const typeStr = cd === 0x01 ? 'VRAM_W' : cd === 0x00 ? 'VRAM_R' : cd === 0x03 ? 'CRAM_W' : cd === 0x05 ? 'VSRAM_W' : `CD=${cd.toString(16)}`;
  console.log(`  $${hex} x${count}  type=${typeStr} addr=$${addr.toString(16).padStart(4,'0').toUpperCase()}`);
}

console.log('\n=== ALL INSTANCES ===');
for (const r of allLines) {
  const typeStr = r.cd === 0x01 ? 'VRAM_W' : r.cd === 0x00 ? 'VRAM_R' : r.cd === 0x03 ? 'CRAM_W' : r.cd === 0x05 ? 'VSRAM_W' : `CD=${r.cd.toString(16)}`;
  console.log(`${r.file}:${r.line}: $${r.hex} type=${typeStr} addr=$${r.addr.toString(16).padStart(4,'0').toUpperCase()}  | ${r.text}`);
}
