// MAGICB-003: Replace raw VDP command longwords with named constants
// Process: script.asm only (first file)
// Only replaces values appearing 2+ times in the codebase OR already-named constants

const fs = require('fs');

// Map of hex value -> constant name
// Only replacing values in this file that we're confident about
const replacements = [
  // Already defined in hw_constants.asm
  ['40000003', 'VDP_CMD_VRAM_WRITE_PLANE_A'],
  ['60000003', 'VDP_CMD_VRAM_WRITE_PLANE_B'],
  // New constants (multi-use across codebase)
  ['41A20003', 'VDP_CMD_VRAM_WRITE_C1A2'],
  ['6D360003', 'VDP_CMD_VRAM_WRITE_ED36'],
  ['4D360003', 'VDP_CMD_VRAM_WRITE_CD36'],
  ['61060003', 'VDP_CMD_VRAM_WRITE_E106'],
  // Single-use in script.asm but semantically interesting
  ['6CB60003', 'VDP_CMD_VRAM_WRITE_ECB6'],
  ['4CB60003', 'VDP_CMD_VRAM_WRITE_CCB6'],
];

// EXCLUDE: $4E4557FF (ASCII 'NEW\xFF'), $40000000 (VRAM addr 0), single-use misc addresses

const file = 'src/script.asm';
let text = fs.readFileSync(file, 'utf8');
const original = text;

for (const [hex, name] of replacements) {
  // Match #$XXXXXXXX (case insensitive) but NOT if it's in a comment line
  // We do line-by-line to avoid replacing in comments
  const lines = text.split('\n');
  const re = new RegExp('#\\$' + hex + '\\b', 'i');
  let count = 0;
  for (let i = 0; i < lines.length; i++) {
    const l = lines[i];
    // Skip pure comment lines
    if (/^\s*;/.test(l)) continue;
    // Find the code portion (before any comment)
    // Simple approach: replace only in the instruction part
    if (re.test(l)) {
      lines[i] = l.replace(re, '#' + name);
      count++;
    }
  }
  if (count > 0) {
    text = lines.join('\n');
    console.log(`  ${file}: $${hex.toUpperCase()} -> ${name} (${count} replacements)`);
  }
}

if (text !== original) {
  fs.writeFileSync(file, text, 'utf8');
  console.log(`Written: ${file}`);
} else {
  console.log('No changes made.');
}
