// Decode the two UnknownData_* blobs from script.asm
// These sit between named HUD functions and decode as 68000 machine code

const b1addr = 0x12EA8; // ROM offset of UnknownData_12EA8
const b2addr = 0x12F92; // ROM offset of UnknownData_12F92

const b1 = [0x00,0x7C,0x07,0x00, 0x31,0xFC,0x00,0x06,0xC2,0x42, 0x31,0xFC,0x00,0x18,0xC2,0x44,
            0x30,0x38,0xC6,0x2C, 0x4E,0xB9,0x00,0x01,0x04,0x8C, 0x34,0x00, 0x36,0x3C,0x00,0x00,
            0x42,0x45, 0x61,0x00,0xE5,0xA4, 0x31,0xFC,0x00,0x06,0xC2,0x42, 0x31,0xFC,0x00,0x1A,0xC2,0x44,
            0x30,0x38,0xC6,0x32, 0x4E,0xB9,0x00,0x01,0x04,0x8C, 0x34,0x00, 0x36,0x3C,0x00,0x00,
            0x42,0x45, 0x61,0x00,0xE5,0x82, 0x02,0x7C,0xF8,0xFF, 0x4E,0x75];

const b2 = [0x00,0x7C,0x07,0x00, 0x31,0xFC,0x00,0x0C,0xC2,0x42, 0x31,0xFC,0x00,0x18,0xC2,0x44,
            0x30,0x38,0xC6,0x2E, 0x4E,0xB9,0x00,0x01,0x04,0x8C, 0x34,0x00, 0x36,0x3C,0x00,0x00,
            0x42,0x45, 0x61,0x00,0xE4,0xEE, 0x31,0xFC,0x00,0x0C,0xC2,0x42, 0x31,0xFC,0x00,0x1A,0xC2,0x44,
            0x30,0x38,0xC6,0x30, 0x4E,0xB9,0x00,0x01,0x04,0x8C, 0x34,0x00, 0x36,0x3C,0x00,0x00,
            0x42,0x45, 0x61,0x00,0xE4,0xCC, 0x02,0x7C,0xF8,0xFF, 0x4E,0x75];

function bsrTarget(baseROMaddr, blobOffset, dispHi, dispLo) {
  const instrAddr = baseROMaddr + blobOffset;
  let disp = (dispHi << 8) | dispLo;
  if (disp > 0x7FFF) disp = disp - 0x10000; // sign-extend
  return instrAddr + 2 + disp;
}

function hex(n, w) { return '0x' + n.toString(16).toUpperCase().padStart(w||4,'0'); }

// 31 FC xx xx yy yy = MOVE.w #$xxyy, $yyzz.w  (MOVE.w #imm16, abs16)
// addr bytes yy zz become sign-extended to FFFF_yyZZ
function absShort(hi, lo) {
  return 'FFFF' + hi.toString(16).toUpperCase().padStart(2,'0') + lo.toString(16).toUpperCase().padStart(2,'0');
}

// Decode and describe each blob
function decodeBlob(name, bytes, baseAddr) {
  let i = 0;
  console.log('\n=== ' + name + ' @ ROM ' + hex(baseAddr, 6) + ' ===');
  
  // ORI #$0700, SR
  console.log(hex(baseAddr+i,6) + ': ORI  #$0700, SR   ; disable interrupts (mask=7)');
  i += 4;
  
  // MOVE.w #hp_cursor_x, Window_number_cursor_x
  const hpCurX = (bytes[i+2]<<8)|bytes[i+3];
  const curXAddr = absShort(bytes[i+4], bytes[i+5]);
  console.log(hex(baseAddr+i,6) + ': MOVE.w #$' + hpCurX.toString(16).padStart(4,'0') + ', $' + curXAddr + '.w  ; HP cursor X');
  i += 6;
  
  // MOVE.w #$0018, Window_number_cursor_y
  const hpCurY = (bytes[i+2]<<8)|bytes[i+3];
  const curYAddr = absShort(bytes[i+4], bytes[i+5]);
  console.log(hex(baseAddr+i,6) + ': MOVE.w #$' + hpCurY.toString(16).padStart(4,'0') + ', $' + curYAddr + '.w  ; HP cursor Y');
  i += 6;
  
  // MOVE.w $C62x.w, D0  (read HP or MP)
  const src1Addr = absShort(bytes[i+2], bytes[i+3]);
  console.log(hex(baseAddr+i,6) + ': MOVE.w $' + src1Addr + '.w, D0  ; read stat');
  i += 4;
  
  // JSR ConvertToBCD
  const jsrTarget = ((bytes[i+2]<<24)|(bytes[i+3]<<16)|(bytes[i+4]<<8)|bytes[i+5])>>>0;
  console.log(hex(baseAddr+i,6) + ': JSR  $' + jsrTarget.toString(16).toUpperCase() + '  ; ConvertToBCD');
  i += 6;
  
  // MOVE.w D0, D2
  console.log(hex(baseAddr+i,6) + ': MOVE.w D0, D2');
  i += 2;
  
  // MOVE.w #0, D3
  console.log(hex(baseAddr+i,6) + ': MOVE.w #0, D3');
  i += 4;
  
  // CLR.w D5
  console.log(hex(baseAddr+i,6) + ': CLR.w D5');
  i += 2;
  
  // BSR.w <target>
  const bsr1disp = (bytes[i+2]<<8)|bytes[i+3];
  const bsr1target = bsrTarget(baseAddr, i, bytes[i+2], bytes[i+3]);
  console.log(hex(baseAddr+i,6) + ': BSR.w $' + bsr1target.toString(16).toUpperCase() + '  ; disp=$' + bsr1disp.toString(16) + '  ConvertNumberToTextDigits variant');
  i += 4;
  
  // === MP display ===
  const mpCurX = (bytes[i+2]<<8)|bytes[i+3];
  console.log(hex(baseAddr+i,6) + ': MOVE.w #$' + mpCurX.toString(16).padStart(4,'0') + ', $' + absShort(bytes[i+4],bytes[i+5]) + '.w  ; MP cursor X');
  i += 6;
  const mpCurY = (bytes[i+2]<<8)|bytes[i+3];
  console.log(hex(baseAddr+i,6) + ': MOVE.w #$' + mpCurY.toString(16).padStart(4,'0') + ', $' + absShort(bytes[i+4],bytes[i+5]) + '.w  ; MP cursor Y');
  i += 6;
  const src2Addr = absShort(bytes[i+2], bytes[i+3]);
  console.log(hex(baseAddr+i,6) + ': MOVE.w $' + src2Addr + '.w, D0  ; read stat');
  i += 4;
  const jsr2target = ((bytes[i+2]<<24)|(bytes[i+3]<<16)|(bytes[i+4]<<8)|bytes[i+5])>>>0;
  console.log(hex(baseAddr+i,6) + ': JSR  $' + jsr2target.toString(16).toUpperCase() + '  ; ConvertToBCD');
  i += 6;
  console.log(hex(baseAddr+i,6) + ': MOVE.w D0, D2');
  i += 2;
  console.log(hex(baseAddr+i,6) + ': MOVE.w #0, D3');
  i += 4;
  console.log(hex(baseAddr+i,6) + ': CLR.w D5');
  i += 2;
  const bsr2disp = (bytes[i+2]<<8)|bytes[i+3];
  const bsr2target = bsrTarget(baseAddr, i, bytes[i+2], bytes[i+3]);
  console.log(hex(baseAddr+i,6) + ': BSR.w $' + bsr2target.toString(16).toUpperCase() + '  ; disp=$' + bsr2disp.toString(16));
  i += 4;
  
  // ANDI #$F8FF, SR
  console.log(hex(baseAddr+i,6) + ': ANDI #$F8FF, SR  ; restore interrupt mask');
  i += 4;
  // RTS
  console.log(hex(baseAddr+i,6) + ': RTS');
  i += 2;
  
  console.log('Total bytes decoded: ' + i + ' / ' + bytes.length);
}

decodeBlob('UnknownData_12EA8', b1, b1addr);
decodeBlob('UnknownData_12F92', b2, b2addr);

console.log('\n=== Diff between blobs ===');
for(let i=0;i<b1.length;i++) {
  if(b1[i]!==b2[i]) {
    console.log('  offset '+i+' (ROM b1='+hex(b1addr+i,6)+', b2='+hex(b2addr+i,6)+'): '+
      hex(b1[i],2)+' vs '+hex(b2[i],2));
  }
}

// Look up what C62C, C62E, C632, C630 might be
console.log('\n=== RAM address cross-reference ===');
console.log('b1 HP source:  $FFFFC62C  (should be Player_hp)');
console.log('b1 MP source:  $FFFFC632  (???)');
console.log('b2 HP source:  $FFFFC62E  (should be Player_mp)');
console.log('b2 MP source:  $FFFFC630  (???)');
console.log('Window_number_cursor_x / y - check constants.asm for C242/C244');
