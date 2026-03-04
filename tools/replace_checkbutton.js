const fs = require('fs');

const BUTTON_MAP = {
  '0': 'BUTTON_BIT_UP',
  '1': 'BUTTON_BIT_DOWN',
  '2': 'BUTTON_BIT_LEFT',
  '3': 'BUTTON_BIT_RIGHT',
  '4': 'BUTTON_BIT_B',
  '5': 'BUTTON_BIT_C',
  '6': 'BUTTON_BIT_A',
  '7': 'BUTTON_BIT_START',
};

function resolveButton(val) {
  // Already a named constant?
  if (val.startsWith('BUTTON_BIT_')) return val;
  // val is like $0005 or $0006 or 5 or 6
  const cleaned = val.replace(/^\$0*/, '').replace(/^0*/, '') || '0';
  const n = parseInt(cleaned, 16);
  if (isNaN(n)) return null;
  return BUTTON_MAP[String(n)] || null;
}

const files = [
  'E:\\Romhacking\\vermilion\\src\\combat.asm',
  'E:\\Romhacking\\vermilion\\src\\miscdata.asm',
  'E:\\Romhacking\\vermilion\\src\\script.asm',
  'E:\\Romhacking\\vermilion\\src\\states.asm',
  'E:\\Romhacking\\vermilion\\src\\sram.asm',
  'E:\\Romhacking\\vermilion\\src\\player.asm',
  'E:\\Romhacking\\vermilion\\src\\boss.asm',
];

let totalReplaced = 0;
for (const f of files) {
  const src = fs.readFileSync(f, 'utf8');
  // Match: tab MOVE.w #val, D2 (optional comment) newline  tab JSR CheckButtonPress (optional trailing space)
  // val can be raw hex ($0005), decimal, or a named constant (BUTTON_BIT_C)
  // Files use CRLF line endings and tabs
  const re = /(\t)MOVE\.w\t#(\$[0-9A-Fa-f]+|\d+|BUTTON_BIT_\w+),\s*D2([ \t]*(?:;[^\r\n]*)?\r?\n\t)JSR\tCheckButtonPress([ \t]*)/g;
  let count = 0;
  const out = src.replace(re, (match, tab, val, sep, trail) => {
    const btn = resolveButton(val);
    if (!btn) { console.log('  UNKNOWN button value:', val, 'in', f); return match; }
    count++;
    return tab + 'CheckButton ' + btn + trail;
  });
  if (count > 0) {
    fs.writeFileSync(f, out, 'utf8');
    console.log(f.split('\\').pop() + ': ' + count + ' replacements');
    totalReplaced += count;
  }
}
console.log('Total:', totalReplaced);
