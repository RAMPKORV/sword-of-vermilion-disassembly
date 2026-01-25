const fs = require('fs');

// Read files
const ramRefs = JSON.parse(fs.readFileSync('ram_references.json', 'utf8'));
const constants = fs.readFileSync('constants.asm', 'utf8');

// Find all defined RAM addresses in constants.asm
const defined = new Set();
const lines = constants.split('\n');
for (const line of lines) {
    const match = line.match(/=\s*(\$FFFF[0-9A-Fa-f]{4})/i);
    if (match) {
        defined.add(match[1].toUpperCase());
    }
}

console.log('Found', defined.size, 'defined RAM addresses in constants.asm');

// Filter out already-named addresses
const remaining = {};
let removed = 0;
for (const [addr, count] of Object.entries(ramRefs)) {
    if (defined.has(addr)) {
        removed++;
        console.log('  Removing:', addr);
    } else {
        remaining[addr] = count;
    }
}

// Write filtered list back
fs.writeFileSync('ram_references.json', JSON.stringify(remaining, null, 2));

console.log('Removed', removed, 'already-named addresses');
console.log('Remaining unnamed:', Object.keys(remaining).length);
