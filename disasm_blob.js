// disasm_blob.js - Disassemble the BossParallaxEntry blob in miscdata.asm
'use strict';
const fs = require('fs');
const rom = fs.readFileSync('E:/Romhacking/vermilion/out.bin');
const start = 0x3C6E8;
const end   = 0x3D1C4;

// Load label names from listing file
const lst = fs.readFileSync('E:/Romhacking/vermilion/vermilion.lst', 'utf8');
const labelsByAddr = {};
for (const line of lst.split('\n')) {
    const m = line.match(/^([0-9A-F]{8})\s+([A-Za-z_][A-Za-z_0-9]*):/);
    if (m) {
        const a = parseInt(m[1], 16);
        if (!labelsByAddr[a]) labelsByAddr[a] = m[2];
    }
}
function labelFor(addr) {
    return labelsByAddr[addr] || ('loc_'+addr.toString(16).toUpperCase().padStart(8,'0'));
}

function rd(pc, off) { return (rom[pc+off] << 8) | rom[pc+off+1]; }
function rl(pc, off) { return (((rom[pc+off]<<24)|(rom[pc+off+1]<<16)|(rom[pc+off+2]<<8)|rom[pc+off+3])>>>0); }
function i8(v) { return v > 127 ? v - 256 : v; }
function i16(v) { return v > 32767 ? v - 65536 : v; }
function hb(v) { return '$'+v.toString(16).toUpperCase().padStart(2,'0'); }
function hw(v) { return '$'+v.toString(16).toUpperCase().padStart(4,'0'); }
function hl(v) { return '$'+v.toString(16).toUpperCase().padStart(8,'0'); }
const SZ = ['.b','.w','.l'];

function eaStr(pc, mode, reg, sz, extraOff) {
    switch(mode) {
        case 0: return 'D'+reg;
        case 1: return 'A'+reg;
        case 2: return '(A'+reg+')';
        case 3: return '(A'+reg+')+';
        case 4: return '-(A'+reg+')';
        case 5: return hw(i16(rd(pc,extraOff)))+'(A'+reg+')';
        case 6: { const ext=rd(pc,extraOff); const dn=(ext>>12)&7; const d=i8(ext&0xFF); return (d>=0?'+':'')+d+'(A'+reg+',D'+dn+(ext&0x800?'.l':'.w')+')'; }
        case 7:
            if (reg===0) return hw(rd(pc,extraOff))+'.w';
            if (reg===1) return hl(rl(pc,extraOff))+'.l';
            if (reg===2) { const d=i16(rd(pc,extraOff)); return labelFor(pc+2+d); }
            if (reg===4) {
                if (sz===0) return '#'+hb(rd(pc,extraOff)&0xFF);
                if (sz===1) return '#'+hw(rd(pc,extraOff));
                if (sz===2) return '#'+hl(rl(pc,extraOff));
            }
    }
    return '???';
}

function eaSize(mode, reg, sz) {
    if (mode <= 4) return 0;
    if (mode === 5) return 2;
    if (mode === 6) return 2;
    if (mode === 7) {
        if (reg===0) return 2;
        if (reg===1) return 4;
        if (reg===2) return 2;
        if (reg===4) return sz===2 ? 4 : 2;
    }
    return 0;
}

function disasm(pc) {
    const w = rd(pc,0);
    const op3 = (w>>12)&0xF;

    // RTS
    if (w === 0x4E75) return { s:'RTS', size:2 };
    // NOP
    if (w === 0x4E71) return { s:'NOP', size:2 };
    // ILLEGAL
    if (w === 0x4AFC) return { s:'ILLEGAL', size:2 };

    // MOVEQ
    if ((w&0xF100)===0x7000) { const dn=(w>>9)&7; return { s:'MOVEQ\t#'+i8(w&0xFF)+', D'+dn, size:2 }; }

    // ORI/ANDI to SR
    if (w===0x007C) return { s:'ORI\t#'+hw(rd(pc,2))+', SR', size:4 };
    if (w===0x027C) return { s:'ANDI\t#'+hw(rd(pc,2))+', SR', size:4 };

    // ANDI.w #imm, Dn
    if ((w&0xFFF8)===0x0240) return { s:'ANDI.w\t#'+hw(rd(pc,2))+', D'+(w&7), size:4 };

    // ORI.l #imm, Dn
    if ((w&0xFFF8)===0x0080) return { s:'ORI.l\t#'+hl(rl(pc,2))+', D'+(w&7), size:6 };

    // BTST/BCHG/BCLR/BSET immediate
    if ((w&0xFF00)===0x0800) {
        const ops=['BTST','BCHG','BCLR','BSET'];
        const op2=(w>>6)&3; const mode=(w>>3)&7; const reg=w&7;
        const bit=rd(pc,2)&0x1F;
        if (mode===0) return { s:ops[op2]+'\t#'+bit+', D'+reg, size:4 };
        if (mode===7&&reg===0) return { s:ops[op2]+'\t#'+bit+', '+hw(rd(pc,4))+'.w', size:6 };
    }

    // MOVE (size in bits 13-12, remapped: 1=byte, 3=word, 2=long)
    if (op3===1||op3===2||op3===3) {
        const sz = op3===1?0:op3===3?1:2;
        const dstMode=(w>>6)&7; const dstReg=(w>>9)&7;
        const srcMode=(w>>3)&7; const srcReg=w&7;
        let off=2;
        const srcE=eaStr(pc,srcMode,srcReg,sz,off); off+=eaSize(srcMode,srcReg,sz);
        const dstE=eaStr(pc,dstMode,dstReg,sz,off);
        return { s:'MOVE'+SZ[sz]+'\t'+srcE+', '+dstE, size:2+eaSize(srcMode,srcReg,sz)+eaSize(dstMode,dstReg,sz) };
    }

    // MOVEA
    if ((w&0xF1C0)===0x2040||(w&0xF1C0)===0x3040) {
        const sz=(w>>12)===3?1:2; const an=(w>>9)&7;
        const mode=(w>>3)&7; const reg=w&7;
        const e=eaStr(pc,mode,reg,sz,2);
        return { s:'MOVEA'+SZ[sz]+'\t'+e+', A'+an, size:2+eaSize(mode,reg,sz) };
    }

    // LEA
    if ((w&0xF1C0)===0x41C0) {
        const an=(w>>9)&7; const mode=(w>>3)&7; const reg=w&7;
        if (mode===7&&reg===1) { const a=rl(pc,2); return { s:'LEA\t'+labelFor(a)+', A'+an, size:6, lea:a }; }
        if (mode===7&&reg===0) { const a=rd(pc,2); return { s:'LEA\t'+hw(a)+'.w, A'+an, size:4 }; }
    }

    // PEA
    if ((w&0xFFC0)===0x4840&&(w&0x38)!==0) { /* skip, handle SWAP below */ }
    // SWAP
    if ((w&0xFFF8)===0x4840) return { s:'SWAP\tD'+(w&7), size:2 };
    // EXT
    if ((w&0xFFF8)===0x4880) return { s:'EXT.w\tD'+(w&7), size:2 };
    if ((w&0xFFF8)===0x48C0) return { s:'EXT.l\tD'+(w&7), size:2 };
    // CLR
    if ((w&0xFF00)===0x4200) {
        const sz=(w>>6)&3; const mode=(w>>3)&7; const reg=w&7;
        return { s:'CLR'+SZ[sz]+'\t'+eaStr(pc,mode,reg,sz,2), size:2+eaSize(mode,reg,sz) };
    }
    // TST
    if ((w&0xFF00)===0x4A00) {
        const sz=(w>>6)&3; const mode=(w>>3)&7; const reg=w&7;
        return { s:'TST'+SZ[sz]+'\t'+eaStr(pc,mode,reg,sz,2), size:2+eaSize(mode,reg,sz) };
    }
    // NOT
    if ((w&0xFF00)===0x4600) {
        const sz=(w>>6)&3; const mode=(w>>3)&7; const reg=w&7;
        return { s:'NOT'+SZ[sz]+'\t'+eaStr(pc,mode,reg,sz,2), size:2+eaSize(mode,reg,sz) };
    }

    // JSR
    if (w===0x4EB9) { const a=rl(pc,2); return { s:'JSR\t'+labelFor(a), size:6, call:a }; }
    if (w===0x4EB8) { const a=rd(pc,2); return { s:'JSR\t'+hw(a)+'.w', size:4 }; }
    // JMP
    if (w===0x4EF9) { const a=rl(pc,2); return { s:'JMP\t'+labelFor(a), size:6 }; }
    if ((w&0xFFF8)===0x4EF0) { const ext=rd(pc,2); const dn=(ext>>12)&7; return { s:'JMP\t(A'+(w&7)+',D'+dn+'.w)', size:4 }; }
    if ((w&0xFFF8)===0x4EEB) { const d=i16(rd(pc,2)); return { s:'JMP\t'+hw(d)+'(A'+(w&7)+')', size:4 }; }

    // BSR
    if ((w&0xFF00)===0x6100) {
        const d8=w&0xFF;
        if (d8!==0) { const t=pc+2+i8(d8); return { s:'BSR.b\t'+labelFor(t), size:2, call:t }; }
        const t=pc+2+i16(rd(pc,2)); return { s:'BSR.w\t'+labelFor(t), size:4, call:t };
    }
    // Bcc
    const BCC=['RA','SR','HI','LS','CC','CS','NE','EQ','VC','VS','PL','MI','GE','LT','GT','LE'];
    if ((w&0xF000)===0x6000) {
        const cc=(w>>8)&0xF; const d8=w&0xFF;
        let t, size;
        if (d8!==0) { t=pc+2+i8(d8); size=2; } else { t=pc+2+i16(rd(pc,2)); size=4; }
        const mn=cc===0?'BRA':cc===1?'BSR':'B'+BCC[cc];
        return { s:mn+(size===2?'.b':'.w')+'\t'+labelFor(t), size, branch:t };
    }

    // DBF
    if ((w&0xFFF8)===0x51C8) { const t=pc+2+i16(rd(pc,2)); return { s:'DBF\tD'+(w&7)+', '+labelFor(t), size:4, branch:t }; }

    // ADD/SUB family
    if (op3===0xD||op3===0x9) {
        const mn=op3===0xD?'ADD':'SUB';
        const dn=(w>>9)&7; const dir=(w>>8)&1; const sz=(w>>6)&3;
        const mode=(w>>3)&7; const reg=w&7;
        if (dir===0) return { s:mn+SZ[sz]+'\t'+eaStr(pc,mode,reg,sz,2)+', D'+dn, size:2+eaSize(mode,reg,sz) };
        else return { s:mn+SZ[sz]+'\t'+'D'+dn+', '+eaStr(pc,mode,reg,sz,2), size:2+eaSize(mode,reg,sz) };
    }
    // ADDI/SUBI
    if ((w&0xFF00)===0x0600||(w&0xFF00)===0x0400) {
        const mn=(w&0xFF00)===0x0600?'ADDI':'SUBI';
        const sz=(w>>6)&3; const mode=(w>>3)&7; const reg=w&7;
        const immSz=sz===2?4:2;
        return { s:mn+SZ[sz]+'\t#'+hw(sz===2?rl(pc,2):rd(pc,2))+', '+eaStr(pc,mode,reg,sz,2+immSz), size:2+immSz+eaSize(mode,reg,sz) };
    }
    // ADDQ/SUBQ
    if ((w&0xF100)===0x5000||(w&0xF100)===0x5100) {
        const mn=(w&0x0100)===0?'ADDQ':'SUBQ';
        const data=(w>>9)&7; const sz=(w>>6)&3; const mode=(w>>3)&7; const reg=w&7;
        return { s:mn+SZ[sz]+'\t#'+data+', '+eaStr(pc,mode,reg,sz,2), size:2+eaSize(mode,reg,sz) };
    }
    // AND/OR
    if (op3===0xC||op3===0x8) {
        const mn=op3===0xC?'AND':'OR';
        const dn=(w>>9)&7; const dir=(w>>8)&1; const sz=(w>>6)&3; const mode=(w>>3)&7; const reg=w&7;
        if (dir===0) return { s:mn+SZ[sz]+'\t'+eaStr(pc,mode,reg,sz,2)+', D'+dn, size:2+eaSize(mode,reg,sz) };
        return { s:mn+SZ[sz]+'\tD'+dn+', '+eaStr(pc,mode,reg,sz,2), size:2+eaSize(mode,reg,sz) };
    }
    // CMP
    if (op3===0xB&&(w&0x100)===0) {
        const dn=(w>>9)&7; const sz=(w>>6)&3; const mode=(w>>3)&7; const reg=w&7;
        return { s:'CMP'+SZ[sz]+'\t'+eaStr(pc,mode,reg,sz,2)+', D'+dn, size:2+eaSize(mode,reg,sz) };
    }
    // CMPI
    if ((w&0xFF00)===0x0C00) {
        const sz=(w>>6)&3; const mode=(w>>3)&7; const reg=w&7;
        const immSz=sz===2?4:2;
        return { s:'CMPI'+SZ[sz]+'\t#'+hw(sz===2?rl(pc,2):rd(pc,2))+', '+eaStr(pc,mode,reg,sz,2+immSz), size:2+immSz+eaSize(mode,reg,sz) };
    }
    // ASL/ASR/LSL/LSR/ROL/ROR register shifts
    if (op3===0xE) {
        const cnt=(w>>9)&7; const dir=(w>>8)&1; const sz=(w>>6)&3; const imm=(w>>5)&1; const type=(w>>3)&3; const reg=w&7;
        const shOps=['AS','LS','ROX','RO'];
        const mn=shOps[type]+(dir?'L':'R');
        if (sz<3) {
            const c=imm?'#'+cnt:'D'+cnt;
            return { s:mn+SZ[sz]+'\t'+c+', D'+reg, size:2 };
        }
        // memory shifts
        const mode=(w>>3)&7; const mreg=w&7;
        return { s:mn+'.w\t'+eaStr(pc,mode,mreg,1,2), size:2+eaSize(mode,mreg,1) };
    }
    // MUL/DIV
    if ((w&0xF1C0)===0xC0C0) { const dn=(w>>9)&7; const mode=(w>>3)&7; const reg=w&7; return { s:'MULU.w\t'+eaStr(pc,mode,reg,1,2)+', D'+dn, size:2+eaSize(mode,reg,1) }; }
    if ((w&0xF1C0)===0xC1C0) { const dn=(w>>9)&7; const mode=(w>>3)&7; const reg=w&7; return { s:'MULS.w\t'+eaStr(pc,mode,reg,1,2)+', D'+dn, size:2+eaSize(mode,reg,1) }; }
    if ((w&0xF1C0)===0x80C0) { const dn=(w>>9)&7; const mode=(w>>3)&7; const reg=w&7; return { s:'DIVU.w\t'+eaStr(pc,mode,reg,1,2)+', D'+dn, size:2+eaSize(mode,reg,1) }; }

    // NEG
    if ((w&0xFF00)===0x4400) { const sz=(w>>6)&3; const mode=(w>>3)&7; const reg=w&7; return { s:'NEG'+SZ[sz]+'\t'+eaStr(pc,mode,reg,sz,2), size:2+eaSize(mode,reg,sz) }; }

    return { s:'dc.w\t$'+w.toString(16).toUpperCase().padStart(4,'0')+' ; ???', size:2 };
}

// Linear sweep disassembly
let pc = start;
const instrs = [];
while (pc < end) {
    let instr;
    try { instr = disasm(pc); }
    catch(e) { instr = { s:'dc.w\t$'+rd(pc,0).toString(16).toUpperCase().padStart(4,'0')+' ; ERR', size:2 }; }
    instrs.push({ pc, ...instr });
    pc += instr.size || 2;
}

// Collect all branch/call targets for label insertion
const targetSet = new Set();
for (const i of instrs) {
    if (i.branch !== undefined) targetSet.add(i.branch);
    if (i.call !== undefined && i.call >= start && i.call < end) targetSet.add(i.call);
}

// Print with inline labels
let output = '';
let prevWasRts = false;
for (const i of instrs) {
    if (targetSet.has(i.pc) || (labelsByAddr[i.pc] && labelsByAddr[i.pc] !== 'loc_003C6E8')) {
        const lbl = labelsByAddr[i.pc] || ('loc_'+i.pc.toString(16).toUpperCase().padStart(8,'0'));
        output += lbl+':\n';
    } else if (i.pc === start) {
        output += 'loc_003C6E8:\n';
    }
    output += '\t'+i.s+'\t; $'+i.pc.toString(16).toUpperCase()+'\n';
}

process.stdout.write(output);
