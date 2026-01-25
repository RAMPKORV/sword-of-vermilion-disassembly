#!/usr/bin/env node
// Map RLE Decompressor for Sword of Vermilion

const fs = require('fs');

function decompressRLE(data) {
  const output = [];
  let i = 0;
  while (i < data.length) {
    const byte = data[i++];
    if (byte < 0x80) {
      output.push(byte);
    } else {
      const repeatByte = data[i++];
      const count = 0x80 - byte;
      for (let j = 0; j < count; j++) output.push(repeatByte);
    }
  }
  return output;
}

console.log('RLE Decompressor loaded');
module.exports = { decompressRLE };