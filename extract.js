// extract.js - Extract byte ranges from a ROM binary file
// Usage: node extract.js <start_hex> <end_hex> <output_path>
// Example: node extract.js 0x1A000 0x1B000 data/art/tiles/font/font_tiles.bin
//
// start_hex: Start offset in ROM (inclusive)
// end_hex: End offset in ROM (exclusive)
// output_path: Path to write the extracted .bin file

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
if (args.length < 3) {
    console.error('Usage: node extract.js <start_hex> <end_hex> <output_path>');
    console.error('Example: node extract.js 0x1A000 0x1B000 data/art/tiles/font/font_tiles.bin');
    process.exit(1);
}

const startOffset = parseInt(args[0], 16);
const endOffset = parseInt(args[1], 16);
const outputPath = args[2];

if (isNaN(startOffset) || isNaN(endOffset)) {
    console.error('Error: offsets must be valid hex numbers (e.g. 0x1A000 or 1A000)');
    process.exit(1);
}

if (endOffset <= startOffset) {
    console.error(`Error: end offset (0x${endOffset.toString(16).toUpperCase()}) must be greater than start offset (0x${startOffset.toString(16).toUpperCase()})`);
    process.exit(1);
}

const romPath = 'out.bin';
if (!fs.existsSync(romPath)) {
    console.error(`Error: ${romPath} not found. Run build.bat first.`);
    process.exit(1);
}

const rom = fs.readFileSync(romPath);

if (endOffset > rom.length) {
    console.error(`Error: end offset 0x${endOffset.toString(16).toUpperCase()} exceeds ROM size 0x${rom.length.toString(16).toUpperCase()}`);
    process.exit(1);
}

const extracted = rom.subarray(startOffset, endOffset);
const size = endOffset - startOffset;

// Ensure output directory exists
const dir = path.dirname(outputPath);
if (dir && !fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
}

fs.writeFileSync(outputPath, extracted);
console.log(`Extracted ${size} bytes (0x${size.toString(16).toUpperCase()}) from 0x${startOffset.toString(16).toUpperCase()}-0x${endOffset.toString(16).toUpperCase()} to ${outputPath}`);
