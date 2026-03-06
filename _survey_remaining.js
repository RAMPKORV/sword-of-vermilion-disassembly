// Survey remaining raw VDP hex values across all source files
// Find any multi-use values worth naming as constants
const fs = require('fs');
const files = [
  'src/cutscene.asm','src/magic.asm','src/miscdata.asm','src/boss.asm',
  'src/dungeon.asm','src/bossbattle.asm','src/gameplay.asm','src/script.asm'
];

const counts = {};
const locations = {};

for (const f of files) {
  const t = fs.readFileSync(f, 'utf8');
  const re = /#\$([4-7][0-9A-Fa-f]{7})/g;
  let m;
  while ((m = re.exec(t)) !== null) {
    const v = m[1].toUpperCase();
    counts[v] = (counts[v] || 0) + 1;
    if (!locations[v]) locations[v] = [];
    // find line number
    const lineNum = t.substring(0, m.index).split('\n').length;
    locations[v].push(f + ':' + lineNum);
  }
}

const multi = Object.entries(counts).filter(([k,v]) => v > 1).sort((a,b) => b[1]-a[1]);
console.log('Multi-use values:');
if (!multi.length) {
  console.log('  (none - all remaining values are single-use)');
} else {
  multi.forEach(([k,v]) => {
    console.log('  $' + k + ' x' + v);
    locations[k].forEach(l => console.log('    ' + l));
  });
}
console.log('\nTotal unique remaining raw VDP hex values: ' + Object.keys(counts).length);
console.log('Total instances: ' + Object.values(counts).reduce((a,b)=>a+b,0));
