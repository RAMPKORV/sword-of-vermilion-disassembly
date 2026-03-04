const fs = require('fs');
const path = 'E:\\Romhacking\\vermilion\\src\\combat.asm';
const src = fs.readFileSync(path, 'utf8');
// Find the first JSR CheckButtonPress and show context
const idx = src.indexOf('JSR\tCheckButtonPress');
if (idx < 0) { console.log('not found with tab'); } else {
  console.log('Found with tab at', idx);
  console.log(JSON.stringify(src.slice(idx - 80, idx + 30)));
}
const idx2 = src.indexOf('JSR CheckButtonPress');
if (idx2 < 0) { console.log('not found with space'); } else {
  console.log('Found with space at', idx2);
  console.log(JSON.stringify(src.slice(idx2 - 80, idx2 + 30)));
}
