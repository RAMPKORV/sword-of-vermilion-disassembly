// Script: define new VDP_CMD_* constants in hw_constants.asm
// and replace raw hex VDP command longwords across source files

const fs = require('fs');

// Mapping of raw hex -> constant name (for all values appearing 2+ times)
// or single-use values we still want to name for clarity
const VDP_CONSTANTS = {
  // Already defined - just replacing raw hex with existing constant name
  '40000003': 'VDP_CMD_VRAM_WRITE_PLANE_A',
  '60000003': 'VDP_CMD_VRAM_WRITE_PLANE_B',
  '40000010': 'VDP_CMD_VSRAM_WRITE_0',
  '7C000002': 'VDP_CMD_VRAM_WRITE_HSCROLL',
  '78000002': 'VDP_CMD_VRAM_WRITE_SAT',

  // New constants to define (2+ occurrences)
  '5FFF0003': 'VDP_CMD_VRAM_WRITE_ADDR_MASK',
  '69800003': 'VDP_CMD_VRAM_WRITE_E980',
  '40820003': 'VDP_CMD_VRAM_WRITE_C082',
  '44040003': 'VDP_CMD_VRAM_WRITE_C404',
  '46420003': 'VDP_CMD_VRAM_WRITE_C642',
  '61060003': 'VDP_CMD_VRAM_WRITE_E106',
  '413C0003': 'VDP_CMD_VRAM_WRITE_C13C',
  '43BE0003': 'VDP_CMD_VRAM_WRITE_C3BE',
  '42040003': 'VDP_CMD_VRAM_WRITE_C204',
  '44820003': 'VDP_CMD_VRAM_WRITE_C482',
  '45600002': 'VDP_CMD_VRAM_WRITE_8560',
  '67100003': 'VDP_CMD_VRAM_WRITE_E710',
  '67140003': 'VDP_CMD_VRAM_WRITE_E714',
  '60AA0003': 'VDP_CMD_VRAM_WRITE_E0AA',
  '4A040003': 'VDP_CMD_VRAM_WRITE_CA04',
  '48C20003': 'VDP_CMD_VRAM_WRITE_C8C2',
  '60AE0003': 'VDP_CMD_VRAM_WRITE_E0AE',
  '6D360003': 'VDP_CMD_VRAM_WRITE_ED36',
  '4D360003': 'VDP_CMD_VRAM_WRITE_CD36',
  '41A20003': 'VDP_CMD_VRAM_WRITE_C1A2',

  // player.asm battle sprite DMA VRAM destination addresses
  '40200080': 'VDP_DMA_VRAM_WRITE_0200',
  '41A00080': 'VDP_DMA_VRAM_WRITE_1A00',
  '42A00080': 'VDP_DMA_VRAM_WRITE_2A00',
  '42200080': 'VDP_DMA_VRAM_WRITE_2200',
  '43A00080': 'VDP_DMA_VRAM_WRITE_3A00',
  '41A00080': 'VDP_DMA_VRAM_WRITE_1A00',
  '42200080': 'VDP_DMA_VRAM_WRITE_2200',
  '42A00080': 'VDP_DMA_VRAM_WRITE_2A00',
  '43A00080': 'VDP_DMA_VRAM_WRITE_3A00',
};

// Descriptions for new constants (for comments)
const VDP_CONST_COMMENTS = {
  'VDP_CMD_VRAM_WRITE_ADDR_MASK': 'ANDI mask: clears VRAM address bits while preserving VDP command type bits',
  'VDP_CMD_VRAM_WRITE_E980':  'VRAM write to $E980 (Plane B row offset, credits/staff names)',
  'VDP_CMD_VRAM_WRITE_C082':  'VRAM write to $C082 (Plane A, dungeon wall tile row 1)',
  'VDP_CMD_VRAM_WRITE_C404':  'VRAM write to $C404 (Plane A row 8, debug/inventory menu)',
  'VDP_CMD_VRAM_WRITE_C642':  'VRAM write to $C642 (Plane A, boss HP gauge row)',
  'VDP_CMD_VRAM_WRITE_E106':  'VRAM write to $E106 (Plane B row 8, col 3)',
  'VDP_CMD_VRAM_WRITE_C13C':  'VRAM write to $C13C (Plane A, town tilemap render start)',
  'VDP_CMD_VRAM_WRITE_C3BE':  'VRAM write to $C3BE (Plane A, boss text row 1)',
  'VDP_CMD_VRAM_WRITE_C204':  'VRAM write to $C204 (Plane A row 4, col 2)',
  'VDP_CMD_VRAM_WRITE_C482':  'VRAM write to $C482 (Plane A, dungeon wall tile row 9)',
  'VDP_CMD_VRAM_WRITE_8560':  'VRAM write to $8560 (overworld tilemap window area)',
  'VDP_CMD_VRAM_WRITE_E710':  'VRAM write to $E710 (Plane B row 14, col 8)',
  'VDP_CMD_VRAM_WRITE_E714':  'VRAM write to $E714 (Plane B row 14, col 10)',
  'VDP_CMD_VRAM_WRITE_E0AA':  'VRAM write to $E0AA (Plane B row 1, col 85)',
  'VDP_CMD_VRAM_WRITE_CA04':  'VRAM write to $CA04 (Plane A row 10, col 2)',
  'VDP_CMD_VRAM_WRITE_C8C2':  'VRAM write to $C8C2 (Plane A, boss text row 2)',
  'VDP_CMD_VRAM_WRITE_E0AE':  'VRAM write to $E0AE (Plane B row 1, col 87)',
  'VDP_CMD_VRAM_WRITE_ED36':  'VRAM write to $ED36 (Plane B, NPC portrait area row 26)',
  'VDP_CMD_VRAM_WRITE_CD36':  'VRAM write to $CD36 (Plane A, NPC portrait area row 26)',
  'VDP_CMD_VRAM_WRITE_C1A2':  'VRAM write to $C1A2 (Plane A row 3, col 81)',
  'VDP_DMA_VRAM_WRITE_0200':  'VRAM DMA write to $0200 (battle sprite slot: enemy)',
  'VDP_DMA_VRAM_WRITE_1A00':  'VRAM DMA write to $1A00 (battle sprite slot: player)',
  'VDP_DMA_VRAM_WRITE_2A00':  'VRAM DMA write to $2A00 (battle sprite slot: ally/partner)',
  'VDP_DMA_VRAM_WRITE_2200':  'VRAM DMA write to $2200 (battle sprite slot: player boss battle)',
  'VDP_DMA_VRAM_WRITE_3A00':  'VRAM DMA write to $3A00 (battle sprite slot: boss slot 2)',
};

// Only replace in these files
const FILES = [
  'src/cutscene.asm',
  'src/magic.asm',
  'src/dungeon.asm',
  'src/bossbattle.asm',
  'src/towndata.asm',
  'src/boss.asm',
  'src/gameplay.asm',
  'src/script.asm',
  'src/player.asm',
  'src/miscdata.asm',
];

// Already-defined constants (no need to add to hw_constants.asm)
const ALREADY_DEFINED = new Set([
  '40000003', '60000003', '40000010', '7C000002', '78000002'
]);

// Process each file
for (const f of FILES) {
  let text = fs.readFileSync(f, 'utf8');
  let changed = false;

  for (const [hex, constName] of Object.entries(VDP_CONSTANTS)) {
    // Replace #$XXXXXXXX with #constName (case-insensitive hex)
    const re = new RegExp('#\\$' + hex + '\\b', 'gi');
    const newText = text.replace(re, '#' + constName);
    if (newText !== text) {
      console.log(`  ${f}: replaced $${hex.toUpperCase()} -> ${constName}`);
      text = newText;
      changed = true;
    }
  }

  if (changed) {
    fs.writeFileSync(f, text, 'utf8');
    console.log(`  Written: ${f}`);
  }
}

console.log('\nDone. Now add new constants to hw_constants.asm manually or via next step.');
