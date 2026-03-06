'use strict';
const fs = require('fs');

// Fix the DmaFillVRAM -> VdpDmaFill rename to avoid collision
// with the DMAFillVRAM macro (assembler is case-insensitive)
const files = [
  'src/battle_gfx.asm',
  'src/core.asm',
  'macros.asm',
];

const renames = [
  ['DmaFillVRAM_WaitBusy', 'VdpDmaFill_WaitBusy'],
  ['DmaFillVRAM',          'VdpDmaFill'],
];

let totalChanges = 0;
for (const f of files) {
  let content = fs.readFileSync(f, 'utf8');
  let changed = false;
  for (const [from, to] of renames) {
    if (content.includes(from)) {
      const count = content.split(from).length - 1;
      content = content.split(from).join(to);
      console.log(f + ': ' + from + ' -> ' + to + ' (' + count + ')');
      totalChanges += count;
      changed = true;
    }
  }
  if (changed) fs.writeFileSync(f, content, 'utf8');
}
console.log('Total replacements:', totalChanges);
