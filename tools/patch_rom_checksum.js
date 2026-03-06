#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const HEADER_CHECKSUM_OFFSET = 0x18E;
const CHECKSUM_START = 0x200;

const args = process.argv.slice(2);
const HELP = args.includes('--help') || args.includes('-h');

function getArg(flag, fallback) {
  const index = args.indexOf(flag);
  return index >= 0 && args[index + 1] !== undefined ? args[index + 1] : fallback;
}

if (HELP) {
  console.log('Usage: node tools/patch_rom_checksum.js [--rom out.bin]');
  process.exit(0);
}

const romPath = path.resolve(ROOT, getArg('--rom', 'out.bin'));

if (!fs.existsSync(romPath)) {
  console.error(`ROM not found: ${romPath}`);
  process.exit(1);
}

const rom = fs.readFileSync(romPath);
if (rom.length < CHECKSUM_START) {
  console.error(`ROM too small to patch checksum: ${rom.length} bytes`);
  process.exit(1);
}

let checksum = 0;
for (let offset = CHECKSUM_START; offset < rom.length; offset += 2) {
  const hi = rom[offset];
  const lo = offset + 1 < rom.length ? rom[offset + 1] : 0;
  checksum = (checksum + ((hi << 8) | lo)) & 0xFFFF;
}

rom.writeUInt16BE(checksum, HEADER_CHECKSUM_OFFSET);
fs.writeFileSync(romPath, rom);

console.log(`Patched ROM checksum in ${path.relative(ROOT, romPath)} to $${checksum.toString(16).toUpperCase().padStart(4, '0')}`);
