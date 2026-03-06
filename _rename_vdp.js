'use strict';
const fs = require('fs');

const files = [
  'src/core.asm',
  'src/battle_gfx.asm',
  'src/vblank.asm',
  'init.asm',
  'hw_constants.asm',
  'game_constants.asm',
];

// Ordered: longer/more-specific first to avoid partial replacement
const renames = [
  ['ExecuteVdpDmaFromPointer_Setup', 'DmaTransferFromPointer_Setup'],
  ['ExecuteVdpDmaFromPointer',       'DmaTransferFromPointer'],
  ['ExecuteVdpDmaFromRam',           'DmaTransferFromRam'],
  ['ExecuteVdpDmaTransfer',          'DmaTransfer'],
  ['TransferTilesViaDma',            'DmaTransferTiles'],
  ['InitVdpDmaRamRoutine_CopyLoop',  'VdpInitDmaRamStub_CopyLoop'],
  ['InitVdpDmaRamRoutine',           'VdpInitDmaRamStub'],
  ['VDP_DMAFill_WaitBusy',           'DmaFillVRAM_WaitBusy'],
  ['VDP_DMAFill',                    'DmaFillVRAM'],
  ['DMAFillWindowSpriteArea',        'DmaFillWindowSpriteArea'],
  ['DMAFillEntireVRAM',              'DmaFillEntireVRAM'],
  ['DMAFillPartial',                 'DmaFillPartial'],
];

let totalChanges = 0;
for (const f of files) {
  let content = fs.readFileSync(f, 'utf8');
  let changed = false;
  for (const [from, to] of renames) {
    // Simple literal replacement (no regex special chars in these names)
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
