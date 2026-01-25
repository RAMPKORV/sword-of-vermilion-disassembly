const fs = require('fs');

// Read files
const ramRefs = JSON.parse(fs.readFileSync('ram_references.json', 'utf8'));
const constants = fs.readFileSync('constants.asm', 'utf8');

// Find all defined RAM addresses in constants.asm
// Format: Name = $FFFFxxxx
const defined = new Map(); // address -> name
const lines = constants.split('\n');
for (const line of lines) {
    const match = line.match(/^\s*(\w+)\s*=\s*(\$FFFF[0-9A-Fa-f]{4})/i);
    if (match) {
        const name = match[1];
        const addr = match[2].toUpperCase();
        defined.set(addr, name);
    }
}

console.log('RAM addresses already named in constants.asm:', defined.size);
console.log('Total unique RAM addresses in code:', Object.keys(ramRefs).length);

// Filter to unnamed addresses
const unnamed = {};
const named = {};
for (const [addr, count] of Object.entries(ramRefs)) {
    if (defined.has(addr)) {
        named[addr] = { count, name: defined.get(addr) };
    } else {
        unnamed[addr] = count;
    }
}

console.log('Unnamed RAM addresses:', Object.keys(unnamed).length);
console.log('Named RAM addresses:', Object.keys(named).length);

// Save unnamed to file
fs.writeFileSync('ram_unnamed.json', JSON.stringify(unnamed, null, 2));

console.log('\nTop 30 unnamed (by reference count):');
Object.entries(unnamed).slice(0, 30).forEach(([addr, count]) => {
    console.log('  ' + addr + ': ' + count);
});

console.log('\nTop 10 named (by reference count):');
Object.entries(named)
    .sort((a, b) => b[1].count - a[1].count)
    .slice(0, 10)
    .forEach(([addr, info]) => {
        console.log('  ' + addr + ' (' + info.name + '): ' + info.count);
    });
