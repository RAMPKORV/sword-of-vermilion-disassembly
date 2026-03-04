const fs = require('fs');
const path = require('path');

const srcDir = 'E:\\Romhacking\\vermilion\\src';
const files = fs.readdirSync(srcDir).filter(f => f.endsWith('.asm')).map(f => path.join(srcDir, f));

let totalReplaced = 0;

for (const f of files) {
  const src = fs.readFileSync(f, 'utf8');

  // Match: tab MOVE.w/MOVE.b #SOUND_xxx, D0  (optional comment) CRLF  tab JSR QueueSoundEffect (optional trailing)
  const re = /(\t)(MOVE\.(w|b))\t#(SOUND_\w+),\s*D0([ \t]*(?:;[^\r\n]*)?\r?\n\t)JSR\tQueueSoundEffect([ \t]*)/g;

  let count = 0;
  const out = src.replace(re, (match, tab, moveOp, size, soundId, sep, trail) => {
    const macro = (size === 'b') ? 'PlaySound_b' : 'PlaySound';
    count++;
    return tab + macro + '\t' + soundId + trail;
  });

  if (count > 0) {
    fs.writeFileSync(f, out, 'utf8');
    console.log(path.basename(f) + ': ' + count + ' replacements');
    totalReplaced += count;
  }
}

console.log('Total:', totalReplaced);
