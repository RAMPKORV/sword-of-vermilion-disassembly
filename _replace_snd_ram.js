const fs = require('fs');
const text = fs.readFileSync('src/sound.asm', 'utf8');

// Map raw address literals to symbolic names
// Order: longer/more-specific addresses first to avoid partial matches
const replacements = [
  ['$00FFF5E0', 'SndRAM_ch_bank2'],
  ['$00FFF670', 'SndRAM_dac_ext'],
  ['$00FFF5B0', 'SndRAM_ch8'],
  ['$00FFF580', 'SndRAM_ch7'],
  ['$00FFF550', 'SndRAM_ch6'],
  ['$00FFF520', 'SndRAM_ch_dac'],
  ['$00FFF4F0', 'SndRAM_ch4'],
  ['$00FFF4C0', 'SndRAM_ch3'],
  ['$00FFF490', 'SndRAM_ch2'],
  ['$00FFF430', 'SndRAM_ch_bank1'],
  ['$00FFF421', 'SndRAM_part_flag'],
  ['$00FFF41D', 'SndRAM_fade_speed'],
  ['$00FFF41C', 'SndRAM_fade_volume'],
  ['$00FFF404', 'SndRAM_cmd_pending'],
  ['$00FFF402', 'SndRAM_tempo_reload'],
  ['$00FFF401', 'SndRAM_tempo_ctr'],
  ['$00FFF400', 'SndRAM_cmd_queue'],
];

let updated = text;
let total = 0;
for (const [raw, sym] of replacements) {
  // Escape $ for regex
  const escaped = raw.replace(/\$/g, '\\$');
  const re = new RegExp(escaped.replace(/\$/g, '\\$'), 'g');
  // Count before replace
  const count = (updated.match(new RegExp(escaped.replace(/\$/g, '\\$'), 'g')) || []).length;
  // Simple string replace (no regex needed since no regex special chars after escaping)
  while (updated.includes(raw)) {
    updated = updated.replace(raw, sym);
  }
  if (count > 0) console.log(raw + ' -> ' + sym + ': ' + count + ' replacements');
  total += count;
}

fs.writeFileSync('src/sound.asm', updated);
console.log('Total:', total);
