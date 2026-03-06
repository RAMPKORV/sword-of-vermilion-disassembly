// MAGICB-003: Replace raw VDP command longwords with named constants
// Processes one file at a time (pass filename as argv[2])

const fs = require('fs');

const file = process.argv[2];
if (!file) { console.error('Usage: node _do_vdp_replace.js <file>'); process.exit(1); }

// All replacements: hex -> constant name
// IMPORTANT: longer/more-specific patterns first to avoid partial matches
const replacements = [
  // Already-defined constants
  ['40000010', 'VDP_CMD_VSRAM_WRITE_0'],
  ['7C000002', 'VDP_CMD_VRAM_WRITE_HSCROLL'],
  ['78000002', 'VDP_CMD_VRAM_WRITE_SAT'],
  // New constants added to hw_constants.asm
  ['5FFF0003', 'VDP_CMD_VRAM_WRITE_ADDR_MASK'],
  ['40820003', 'VDP_CMD_VRAM_WRITE_C082'],
  ['413C0003', 'VDP_CMD_VRAM_WRITE_C13C'],
  ['41A20003', 'VDP_CMD_VRAM_WRITE_C1A2'],
  ['42040003', 'VDP_CMD_VRAM_WRITE_C204'],
  ['43BE0003', 'VDP_CMD_VRAM_WRITE_C3BE'],
  ['44040003', 'VDP_CMD_VRAM_WRITE_C404'],
  ['44820003', 'VDP_CMD_VRAM_WRITE_C482'],
  ['46420003', 'VDP_CMD_VRAM_WRITE_C642'],
  ['48C20003', 'VDP_CMD_VRAM_WRITE_C8C2'],
  ['4A040003', 'VDP_CMD_VRAM_WRITE_CA04'],
  ['4CB60003', 'VDP_CMD_VRAM_WRITE_CCB6'],
  ['4D360003', 'VDP_CMD_VRAM_WRITE_CD36'],
  ['60AA0003', 'VDP_CMD_VRAM_WRITE_E0AA'],
  ['60AE0003', 'VDP_CMD_VRAM_WRITE_E0AE'],
  ['61060003', 'VDP_CMD_VRAM_WRITE_E106'],
  ['67100003', 'VDP_CMD_VRAM_WRITE_E710'],
  ['67140003', 'VDP_CMD_VRAM_WRITE_E714'],
  ['69800003', 'VDP_CMD_VRAM_WRITE_E980'],
  ['6CB60003', 'VDP_CMD_VRAM_WRITE_ECB6'],
  ['6D360003', 'VDP_CMD_VRAM_WRITE_ED36'],
  ['45600002', 'VDP_CMD_VRAM_WRITE_8560'],
  // DMA VRAM write commands (player.asm)
  ['41A00080', 'VDP_DMA_VRAM_WRITE_1A00'],
  ['42200080', 'VDP_DMA_VRAM_WRITE_2200'],
  ['42A00080', 'VDP_DMA_VRAM_WRITE_2A00'],
  ['43A00080', 'VDP_DMA_VRAM_WRITE_3A00'],
  ['40200080', 'VDP_DMA_VRAM_WRITE_0200'],
  // These last because they're substrings of others
  ['40000003', 'VDP_CMD_VRAM_WRITE_PLANE_A'],
  ['60000003', 'VDP_CMD_VRAM_WRITE_PLANE_B'],
];

// EXCLUSIONS: values that look like VDP commands but aren't
const EXCLUDE = new Set([
  '4E4557FF',  // ASCII 'NEW\xFF' - not a VDP command
]);

let text = fs.readFileSync(file, 'utf8');
const original = text;
let totalChanges = 0;

for (const [hex, name] of replacements) {
  if (EXCLUDE.has(hex.toUpperCase())) continue;
  
  const lines = text.split('\n');
  let count = 0;
  
  for (let i = 0; i < lines.length; i++) {
    const l = lines[i];
    // Skip pure comment lines
    if (/^\s*;/.test(l)) continue;
    
    // Match #$XXXXXXXX (instruction immediate) - case insensitive
    const re = new RegExp('#\\$' + hex + '\\b', 'ig');
    if (re.test(l)) {
      lines[i] = l.replace(new RegExp('#\\$' + hex + '\\b', 'ig'), '#' + name);
      count++;
    }
  }
  
  if (count > 0) {
    text = lines.join('\n');
    totalChanges += count;
    console.log(`  $${hex.toUpperCase()} -> ${name}: ${count} replacement(s)`);
  }
}

if (text !== original) {
  fs.writeFileSync(file, text, 'utf8');
  console.log(`\nWritten: ${file} (${totalChanges} total replacements)`);
} else {
  console.log(`No changes in ${file}`);
}
