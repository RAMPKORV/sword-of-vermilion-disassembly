#!/usr/bin/env node
// tools/replace_vdp_cmds_miscdata.js
// One-shot script: replace raw VDP dc.l longwords in src/miscdata.asm with vdpCmd macro calls.
// Only processes lines that (a) are dc.l data lines and (b) contain a VDP cmd comment.
// Run once, then delete.

'use strict';

const fs   = require('fs');
const path = require('path');

const filePath = path.join(__dirname, '..', 'src', 'miscdata.asm');

function decodeVdpCmd(v) {
  v = v >>> 0;
  const cd_lo  = (v >>> 30) & 3;
  const a13_0  = (v >>> 16) & 0x3FFF;
  const cd_hi  = (v >>> 4)  & 0xF;
  const a15_14 = v & 3;
  const type   = (cd_hi << 2) | cd_lo;
  const addr   = (a15_14 << 14) | a13_0;
  // Verify round-trip
  const check = ((( type)&3)<<30) | (((addr)&0x3FFF)<<16) | ((((type)>>2)&0xF)<<4) | (((addr)>>14)&3);
  if ((check >>> 0) !== v) return null;
  return { addr, type };
}

const lines = fs.readFileSync(filePath, 'utf8').split('\n');
let changed = 0;

const out = lines.map((line, i) => {
  // Only touch lines that have a raw hex 8-digit literal followed by a VDP write cmd comment
  const m = line.match(/^(\s*)dc\.l\s+(\$[0-9A-Fa-f]{8})\s*(;.*)?$/i);
  if (!m) return line;

  const indent  = m[1];
  const hexStr  = m[2];
  const comment = m[3] || '';
  const v       = parseInt(hexStr.slice(1), 16);
  const decoded = decodeVdpCmd(v);
  if (!decoded) return line;

  // Only replace if there's a "VDP write cmd" comment — these are the confirmed real ones
  if (!/VDP write cmd/i.test(comment)) return line;

  const addrHex = '$' + decoded.addr.toString(16).toUpperCase().padStart(4, '0');
  const typeHex = '$' + decoded.type.toString(16).toUpperCase().padStart(2, '0');
  changed++;
  return `${indent}vdpCmd\t${addrHex}, ${typeHex}\t\t\t\t; VRAM write to ${addrHex}`;
});

fs.writeFileSync(filePath, out.join('\n'), 'utf8');
console.log(`Replaced ${changed} raw VDP dc.l longwords in src/miscdata.asm`);
