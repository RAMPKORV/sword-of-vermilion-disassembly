const fs = require('fs');
const files = [
  'src/battle_gfx.asm',
  'src/boss.asm',
  'src/cutscene.asm',
  'src/dungeon.asm',
  'src/bossbattle.asm',
  'src/gameplay.asm',
  'src/magic.asm',
  'src/script.asm',
  'src/towndata.asm',
];
let total = 0;
for (const f of files) {
  const orig = fs.readFileSync(f, 'utf8');
  // Only replace ADDI.l and SUBI.l uses (not MOVE.l which has a different semantic meaning)
  const reAddi = /ADDI\.l\t#\$00800000,/g;
  const reSubi = /SUBI\.l\t#\$00800000,/g;
  const countAddi = (orig.match(reAddi) || []).length;
  const countSubi = (orig.match(reSubi) || []).length;
  const count = countAddi + countSubi;
  if (count === 0) continue;
  const updated = orig
    .replace(/ADDI\.l\t#\$00800000,/g, 'ADDI.l\t#VDP_VRAM_ROW_STRIDE,')
    .replace(/SUBI\.l\t#\$00800000,/g, 'SUBI.l\t#VDP_VRAM_ROW_STRIDE,');
  fs.writeFileSync(f, updated);
  total += count;
  console.log(f + ': ' + count + ' replacements (ADDI=' + countAddi + ', SUBI=' + countSubi + ')');
}
console.log('Total replacements:', total);
