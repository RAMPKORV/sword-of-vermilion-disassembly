const fs = require('fs');

// Read the assembly file
const asm = fs.readFileSync('vermilion.asm', 'utf8');

// Pattern to match RAM addresses ($FFFF0000-$FFFFFFFF range)
// These are the main RAM addresses used on Genesis
// Matches $FFFF followed by exactly 4 hex digits
const ramPattern = /\$FFFF[0-9A-Fa-f]{4}/g;

// Count references
const refs = {};
let match;
while ((match = ramPattern.exec(asm)) !== null) {
    const addr = match[0].toUpperCase();
    refs[addr] = (refs[addr] || 0) + 1;
}

// Sort by reference count descending
const sorted = Object.entries(refs)
    .sort((a, b) => b[1] - a[1])
    .reduce((obj, [k, v]) => { obj[k] = v; return obj; }, {});

// Write to file
fs.writeFileSync('ram_references.json', JSON.stringify(sorted, null, 2));

console.log('Total unique RAM addresses:', Object.keys(sorted).length);
console.log('Top 20 most referenced:');
Object.entries(sorted).slice(0, 20).forEach(([addr, count]) => {
    console.log('  ' + addr + ': ' + count);
});
