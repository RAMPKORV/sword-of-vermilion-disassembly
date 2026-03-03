// extract_maps.js - Extract all overworld and cave map sectors to individual .bin files
// Also generates the replacement .asm text with incbin directives

const fs = require('fs');
const path = require('path');

// Read the ROM and listing file
const rom = fs.readFileSync('out.bin');
const lst = fs.readFileSync('vermilion.lst', 'utf8').split('\n');
const src = fs.readFileSync('vermilion.asm', 'utf8');
const lines = src.split('\n');

// Build label -> ROM offset map from listing file
const labelOffsets = {};
for (const line of lst) {
    const m = line.match(/^([0-9A-Fa-f]{8})\s+(\w+):/);
    if (m) {
        labelOffsets[m[2]] = parseInt(m[1], 16);
    }
}

// ===== OVERWORLD MAP SECTORS =====

// Parse the pointer table to get grid mapping
const ptrTableEntries = [];
let inPtrTable = false;
for (let i = 0; i < lines.length; i++) {
    if (lines[i].trim() === 'OverworldMaps: ; 128') inPtrTable = true;
    if (inPtrTable && i > 0) {
        const m = lines[i].match(/dc\.l\s+(\S+)/);
        if (m) {
            ptrTableEntries.push(m[1]);
        } else if (ptrTableEntries.length >= 128) {
            break;
        }
    }
}

// Build label -> first grid coordinate mapping
const labelToGridCoord = {};
for (let idx = 0; idx < 128; idx++) {
    const label = ptrTableEntries[idx];
    if (label === 'CaveMaps') continue; // Skip cave entry markers
    if (!labelToGridCoord[label]) {
        const col = idx % 16;
        const row = Math.floor(idx / 16);
        labelToGridCoord[label] = { col, row };
    }
}

// Collect all overworld sector data labels in order
const owSectors = [];
let inOWData = false;
for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line === 'OverworldMaps_Map_3E1D4:') inOWData = true;
    if (line.startsWith('CaveMaps:')) { inOWData = false; break; }
    
    if (inOWData && line.endsWith(':') && !line.startsWith(';')) {
        owSectors.push({ label: line.slice(0, -1), asmLine: i });
    }
}

// Determine which labels are in the pointer table (need files) vs sub-labels (internal to a sector)
const ptrTableLabels = new Set(ptrTableEntries.filter(l => l !== 'CaveMaps'));

// Also check for labels referenced elsewhere (like EnemySpriteData_FacingSide_Gfx_40020)
// These need to remain as labels even if they're inside another sector's range
const referencedElsewhere = new Set();
const unreferencedSubLabels = [];

for (const sec of owSectors) {
    if (!ptrTableLabels.has(sec.label)) {
        // Check if referenced anywhere besides its definition
        let refCount = 0;
        for (let i = 0; i < lines.length; i++) {
            if (i === sec.asmLine) continue; // Skip definition
            if (lines[i].includes(sec.label)) refCount++;
        }
        if (refCount > 0) {
            referencedElsewhere.add(sec.label);
        } else {
            unreferencedSubLabels.push(sec.label);
        }
    }
}

// Filter out unreferenced sub-labels before calculating sizes.
// Their byte ranges belong to the preceding sector.
const significantSectors = owSectors.filter(s => 
    ptrTableLabels.has(s.label) || referencedElsewhere.has(s.label)
);

// Calculate sizes from consecutive significant sector offsets
for (let i = 0; i < significantSectors.length; i++) {
    const offset = labelOffsets[significantSectors[i].label];
    const nextOffset = i + 1 < significantSectors.length 
        ? labelOffsets[significantSectors[i + 1].label]
        : labelOffsets['CaveMaps']; // CaveMaps follows
    significantSectors[i].romStart = offset;
    significantSectors[i].romEnd = nextOffset;
    significantSectors[i].size = nextOffset - offset;
}

// Also store romStart for unreferenced labels (for logging)
for (const sec of owSectors) {
    if (!sec.romStart) {
        sec.romStart = labelOffsets[sec.label];
        sec.romEnd = sec.romStart;
        sec.size = 0;
    }
}

console.log('=== OVERWORLD MAP SECTORS ===');
console.log(`Total sector data labels: ${owSectors.length}`);
console.log(`In pointer table: ${ptrTableLabels.size}`);
console.log(`Referenced elsewhere (not in ptr table): ${[...referencedElsewhere].join(', ') || 'none'}`);
console.log(`Unreferenced sub-labels (can remove): ${unreferencedSubLabels.join(', ') || 'none'}`);
console.log('');

// Map labels to filenames
const labelToFile = {};
for (const sec of owSectors) {
    if (ptrTableLabels.has(sec.label)) {
        const coord = labelToGridCoord[sec.label];
        const filename = `sector_${coord.col}_${coord.row}.bin`;
        labelToFile[sec.label] = `data/maps/overworld/${filename}`;
        console.log(`${sec.label} -> ${filename} (${sec.size} bytes, ROM 0x${sec.romStart.toString(16).toUpperCase()})`);
    } else if (referencedElsewhere.has(sec.label)) {
        // Keep as separate bin with descriptive name
        const offsetHex = sec.romStart.toString(16).toUpperCase();
        const filename = `data_${offsetHex}.bin`;
        labelToFile[sec.label] = `data/maps/overworld/${filename}`;
        console.log(`${sec.label} -> ${filename} (${sec.size} bytes, ROM 0x${sec.romStart.toString(16).toUpperCase()}) [dual-purpose data]`);
    }
}

// ===== CAVE MAP SECTORS =====
console.log('\n=== CAVE MAP SECTORS ===');

// Parse cave pointer table
const cavePtrEntries = [];
let inCavePtrTable = false;
for (let i = 0; i < lines.length; i++) {
    if (lines[i].trim().startsWith('CaveMaps:')) inCavePtrTable = true;
    if (inCavePtrTable && i > 0) {
        const m = lines[i].match(/dc\.l\s+(\S+)/);
        if (m) {
            cavePtrEntries.push(m[1]);
        }
        // Stop when we hit the first cave data label
        if (lines[i].trim().match(/^CaveMaps_Map_/) || (cavePtrEntries.length >= 44 && !m)) {
            break;
        }
    }
}

const caveSectors = [];
let inCaveData = false;
for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line === 'CaveMaps_Map_4014C:') inCaveData = true;
    if (line === 'CompressedFontTileData:') { inCaveData = false; break; }
    
    if (inCaveData && line.endsWith(':') && !line.startsWith(';')) {
        caveSectors.push({ label: line.slice(0, -1), asmLine: i });
    }
}

// Calculate sizes
for (let i = 0; i < caveSectors.length; i++) {
    const offset = labelOffsets[caveSectors[i].label];
    const nextOffset = i + 1 < caveSectors.length
        ? labelOffsets[caveSectors[i + 1].label]
        : labelOffsets['CompressedFontTileData'];
    caveSectors[i].romStart = offset;
    caveSectors[i].romEnd = nextOffset;
    caveSectors[i].size = nextOffset - offset;
}

// Map cave labels to room indices
const caveUnique = [...new Set(cavePtrEntries)];
const caveLabelToIndex = {};
for (let i = 0; i < cavePtrEntries.length; i++) {
    if (!caveLabelToIndex[cavePtrEntries[i]]) {
        caveLabelToIndex[cavePtrEntries[i]] = i;
    }
}

for (const sec of caveSectors) {
    const idx = caveLabelToIndex[sec.label];
    const filename = idx !== undefined 
        ? `room_${String(idx).padStart(2, '0')}.bin`
        : `shared_${sec.romStart.toString(16).toUpperCase()}.bin`;
    labelToFile[sec.label] = `data/maps/cave/${filename}`;
    console.log(`${sec.label} -> ${filename} (${sec.size} bytes, ROM 0x${sec.romStart.toString(16).toUpperCase()})`);
}

// ===== EXTRACT ALL FILES =====
console.log('\n=== EXTRACTING FILES ===');

let totalExtracted = 0;
const allSectors = [...owSectors, ...caveSectors];
for (const sec of allSectors) {
    const filePath = labelToFile[sec.label];
    if (!filePath) continue; // Skip unreferenced sub-labels
    
    const dir = path.dirname(filePath);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    
    const data = rom.subarray(sec.romStart, sec.romEnd);
    fs.writeFileSync(filePath, data);
    totalExtracted += sec.size;
}

console.log(`\nTotal extracted: ${totalExtracted} bytes (${(totalExtracted/1024).toFixed(1)} KB)`);
console.log(`Overworld files: ${owSectors.filter(s => labelToFile[s.label]).length}`);
console.log(`Cave files: ${caveSectors.length}`);

// ===== GENERATE REPLACEMENT ASM =====
// Write a summary JSON for the next step (replacing dc.b with incbin)
const replacements = [];
for (const sec of allSectors) {
    const filePath = labelToFile[sec.label];
    if (!filePath) {
        replacements.push({ label: sec.label, action: 'remove', asmLine: sec.asmLine });
    } else {
        replacements.push({ label: sec.label, action: 'incbin', file: filePath, asmLine: sec.asmLine });
    }
}

fs.writeFileSync('map_replacements.json', JSON.stringify(replacements, null, 2));
console.log('\nWrote map_replacements.json with replacement instructions');
