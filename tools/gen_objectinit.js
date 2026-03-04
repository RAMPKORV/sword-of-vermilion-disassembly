// Convert GameplayObjectInitTable and BossObjectInitTable_B from dc.w/dc.l to objectInitGroup macro
// Each entry: dc.w copies-1, words-1, type, flags  /  dc.l handler  /  dc.l ptr_dest

// RAM pointer label map (from constants.asm / known labels)
const ptrMap = {
  '0x00000000': '$00000000',
  '0xCCC0C050': null, // shouldn't appear
};

// Parse a dc.w entry block into objectInitGroup
// copies-1, words-1, type, flags are words; handler and ptr_dest are longs
function parseEntry(w0, w1, w2, w3, handler, ptr) {
  const copies = w0 + 1;
  const words = w1 + 1;
  const type = w2;
  const flags = w3;
  return { copies, words, type, flags, handler, ptr };
}

function hexW(n) { return '$' + n.toString(16).toUpperCase().padStart(4, '0'); }
function hexL(n) { return '$' + (n >>> 0).toString(16).toUpperCase().padStart(8, '0'); }

// Known RAM pointer labels (long addresses -> label name)
const ptrLabels = {
  0x00000000: '$00000000',
  0xFFFFCCC0: 'Enemy_list_ptr',
  0xFFFFCCC4: 'Object_slot_01_ptr',
  0xFFFFCCC8: 'Object_slot_02_ptr',
  0xFFFFCCCC: 'Object_slot_03_ptr',
  0xFFFFCCD0: 'Object_slot_04_ptr',
  0xFFFFCCD4: 'Object_slot_05_ptr',
};

// Handler labels (ROM addresses)
const handlerLabels = {
  0x00000000: '$00000000',
};

function ptrName(val) {
  if (ptrLabels[val] !== undefined) return ptrLabels[val];
  return hexL(val);
}

function handlerName(val) {
  if (handlerLabels[val] !== undefined) return handlerLabels[val];
  return hexL(val);
}

// Print objectInitGroup line
function printGroup(e) {
  const h = handlerName(e.handler);
  const p = ptrName(e.ptr);
  return `\tobjectInitGroup ${e.copies}, ${e.words}, ${hexW(e.type)}, ${hexW(e.flags)}, ${h}, ${p}`;
}

// The GameplayObjectInitTable entries (from reading the source)
// Format: dc.w copies-1, words-1, type, flags / dc.l handler / dc.l ptr_dest
// Parsed manually from vblank.asm lines 91-181

const gameplayEntries = [
  // dc.w $0000, $0027, $0050, $0000 / dc.l $00000000 / dc.l Enemy_list_ptr
  parseEntry(0x0000, 0x0027, 0x0050, 0x0000, 0x00000000, 0xFFFFCCC0),
  // dc.w $0001, $001F, $0040, $0000 / dc.l $00000000 / dc.l $00000000
  parseEntry(0x0001, 0x001F, 0x0040, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0000, 0x0027, 0x0050, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0001, 0x001F, 0x0040, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0000, 0x0027, 0x0050, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0001, 0x001F, 0x0040, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0000, 0x0027, 0x0050, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0001, 0x001F, 0x0040, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0000, 0x0027, 0x0050, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0001, 0x001F, 0x0040, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0000, 0x0027, 0x0050, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0001, 0x001F, 0x0040, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0000, 0x0027, 0x0050, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0001, 0x001F, 0x0040, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0000, 0x0027, 0x0050, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0001, 0x001F, 0x0040, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0000, 0x0027, 0x0050, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0001, 0x001F, 0x0040, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0000, 0x0027, 0x0050, 0x0000, 0x00000000, 0x00000000),
  parseEntry(0x0001, 0x001F, 0x0040, 0x0000, 0x00000000, 0x00000000),
  // dc.w $0000, $001F, $0040, $0000 / dc.l $00000000 / dc.l Object_slot_01_ptr
  parseEntry(0x0000, 0x001F, 0x0040, 0x0000, 0x00000000, 0xFFFFCCC4),
  // dc.w $0000, $0027, $0050, $0000 / dc.l $00000000 / dc.l Object_slot_02_ptr
  parseEntry(0x0000, 0x0027, 0x0050, 0x0000, 0x00000000, 0xFFFFCCC8),
  // dc.w $000B, $001F, $0040, $0000 / dc.l $00000000 / dc.l $00000000
  parseEntry(0x000B, 0x001F, 0x0040, 0x0000, 0x00000000, 0x00000000),
];

console.log(`; ${gameplayEntries.length} entries (0x${(gameplayEntries.length - 1).toString(16).toUpperCase()} = ${gameplayEntries.length - 1} zero-based)`);
console.log(`GameplayObjectInitTable:`);
console.log(`\tdc.w\t$${(gameplayEntries.length - 1).toString(16).padStart(4,'0').toUpperCase()}\t\t\t\t; ${gameplayEntries.length} object groups`);
for (const e of gameplayEntries) {
  console.log(printGroup(e));
}
