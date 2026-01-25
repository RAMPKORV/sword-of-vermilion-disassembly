#!/usr/bin/env node
/**
 * Pointer Analysis Tool for Sword of Vermilion Disassembly
 * 
 * Analyzes the .lst file to find potential pointers in data sections.
 * A pointer is identified when a dc.l value matches a known code/data address.
 * 
 * Filters out likely false positives (small values that are probably data).
 */

const fs = require('fs');

// Read the listing file
const lstContent = fs.readFileSync('vermilion.lst', 'utf8');
const asmContent = fs.readFileSync('vermilion.asm', 'utf8');

// Parse listing file to build address map
console.log('Building address map from listing file...\n');

const addressMap = new Map(); // ROM address -> line info
const labelMap = new Map();   // Label name -> ROM address
const lstLines = lstContent.split('\n');

for (let i = 0; i < lstLines.length; i++) {
    const line = lstLines[i];
    
    // Match lines with addresses at the start (8 hex digits)
    if (line.match(/^[0-9A-F]{8}/)) {
        const parts = line.split(/\s+/);
        const romAddr = parseInt(parts[0], 16);
        
        addressMap.set(romAddr, {
            lstLine: i + 1,
            content: line,
            address: romAddr
        });
        
        // Check for label definitions (colon after potential label name)
        const labelMatch = line.match(/^[0-9A-F]{8}\s+(\w+):/);
        if (labelMatch) {
            const label = labelMatch[1];
            labelMap.set(label, romAddr);
        }
    }
}

console.log(`Found ${addressMap.size} addresses`);
console.log(`Found ${labelMap.size} labels\n`);

// Extract all labels from ASM
const asmLines = asmContent.split('\n');
const locLabels = new Set();
const existingLabels = new Set();
const asmLineByLabel = new Map();

for (let i = 0; i < asmLines.length; i++) {
    const line = asmLines[i];
    const labelMatch = line.match(/^(\w+):/);
    if (labelMatch) {
        const label = labelMatch[1];
        existingLabels.add(label);
        asmLineByLabel.set(label, i + 1);
        if (label.startsWith('loc_')) {
            locLabels.add(label);
        }
    }
}

console.log(`Found ${existingLabels.size} total labels in ASM`);
console.log(`Found ${locLabels.size} loc_* labels in ASM\n`);

// Find all dc.l declarations in listing with their values
console.log('Analyzing dc.l declarations for pointers...\n');

const pointers = [];
const likelyFalsePositives = [];

for (let i = 0; i < lstLines.length; i++) {
    const line = lstLines[i];
    
    // Match dc.l lines
    if (line.includes('dc.l')) {
        const parts = line.split(/\s+/);
        
        // Format: address, high word, low word, ..., dc.l, value
        if (parts.length >= 5 && parts[0].match(/^[0-9A-F]{8}$/)) {
            const romAddr = parseInt(parts[0], 16);
            const highWord = parts[1];
            const lowWord = parts[2];
            
            // Ensure we have valid hex words
            if (highWord.match(/^[0-9A-F]{4}$/) && lowWord.match(/^[0-9A-F]{4}$/)) {
                const value = parseInt(highWord + lowWord, 16);
                
                // Find the actual value in the line after "dc.l"
                const dclIndex = line.indexOf('dc.l');
                const afterDcl = line.substring(dclIndex + 4).trim();
                const asmText = afterDcl.split(/\s*;/)[0].trim(); // Remove comments
                
                // Check if this value points to a valid ROM address
                const MAX_ROM_SIZE = 0xA0000; // Actual ROM size
                const isValidRomAddr = value >= 0x000000 && value <= MAX_ROM_SIZE;
                const pointsToCode = addressMap.has(value);
                
                // Check if it's already a known label reference (not a hex literal)
                const isHexLiteral = asmText.match(/^\$[0-9A-F]+$/) || asmText === '0';
                
                // Skip RAM addresses (not ROM pointers)
                if (value >= 0xFF0000 && value <= 0xFFFFFF) {
                    continue; // This is a RAM address, not a ROM pointer
                }
                
                // Heuristic: Filter out likely false positives
                // Small values < $2000 (8192) are often prices, IDs, or counters, not pointers
                // Exception: Values pointing to vector table ($00-$3FF) might be valid
                const isLikelyFalsePositive = value > 0x3FF && value < 0x2000;
                
                // Check if it's in the ROM range and points to code
                if (isValidRomAddr && pointsToCode && isHexLiteral) {
                    const targetInfo = addressMap.get(value);
                    
                    // Analyze what's at the target address
                    const targetContent = targetInfo.content;
                    
                    // Check if target is executable code (common instructions)
                    const codeInstructions = /\t(MOVE|JSR|BSR|JMP|BRA|RTS|RTE|LEA|CLR|TST|CMP|ADD|SUB|AND|OR|BEQ|BNE|BLT|BGT|DBRA|TRAP|PEA|LINK|UNLK|MOVEM|EXT|SWAP)/i;
                    const isTargetCode = codeInstructions.test(targetContent);
                    
                    // Check if target is a label (often indicates entry points)
                    const isTargetLabel = /^\s*[0-9A-F]{8}\s+\w+:/.test(targetContent);
                    
                    // Improve confidence based on target content
                    let confidence = 'high';
                    if (isLikelyFalsePositive) {
                        // Small value pointing to code/label = probably a pointer
                        if (isTargetCode || isTargetLabel) {
                            confidence = 'medium';
                        } else {
                            confidence = 'low';
                        }
                    }
                    
                    // Try to find what label exists at that address
                    let targetLabel = null;
                    for (const [label, addr] of labelMap.entries()) {
                        if (addr === value) {
                            targetLabel = label;
                            break;
                        }
                    }
                    
                    // If no label exists, suggest creating one
                    if (!targetLabel) {
                        targetLabel = `loc_${value.toString(16).toUpperCase().padStart(8, '0')}`;
                    }
                    
                    const ptrInfo = {
                        sourceAddr: romAddr,
                        sourceLstLine: i + 1,
                        targetAddr: value,
                        currentValue: asmText,
                        suggestedLabel: targetLabel,
                        targetContent: targetContent.substring(0, 80),
                        hasExistingLabel: targetLabel && !targetLabel.startsWith('loc_'),
                        existsInAsm: existingLabels.has(targetLabel),
                        isTargetCode: isTargetCode,
                        isTargetLabel: isTargetLabel,
                        confidence: confidence
                    };
                    
                    if (confidence === 'low') {
                        likelyFalsePositives.push(ptrInfo);
                    } else {
                        pointers.push(ptrInfo);
                    }
                }
            }
        }
    }
}

console.log(`Found ${pointers.length} high/medium-confidence pointers`);
console.log(`Found ${likelyFalsePositives.length} low-confidence (likely false positives)\n`);

// Group by status
const highConfidence = pointers.filter(p => p.confidence === 'high');
const mediumConfidence = pointers.filter(p => p.confidence === 'medium');
const withLabels = pointers.filter(p => p.hasExistingLabel);
const withLocLabels = pointers.filter(p => !p.hasExistingLabel && p.existsInAsm);
const needNewLabels = pointers.filter(p => !p.hasExistingLabel && !p.existsInAsm);

console.log('='.repeat(80));
console.log('POINTER ANALYSIS RESULTS');
console.log('='.repeat(80));
console.log(`Total pointers found: ${pointers.length}`);
console.log(`  - High confidence: ${highConfidence.length}`);
console.log(`  - Medium confidence: ${mediumConfidence.length}`);
console.log(`  - Already using named labels: ${withLabels.length}`);
console.log(`  - Should use existing loc_* labels: ${withLocLabels.length}`);
console.log(`  - Need new labels created: ${needNewLabels.length}`);
console.log('='.repeat(80));
console.log();

// Show pointers that should use existing loc_* labels
if (withLocLabels.length > 0) {
    console.log('POINTERS USING HEX VALUES (should use existing loc_* labels):');
    console.log('-'.repeat(80));
    
    for (const ptr of withLocLabels.slice(0, 50)) {
        const conf = ptr.confidence === 'high' ? '***' : ptr.confidence === 'medium' ? '**' : '*';
        console.log(`${conf} ROM $${ptr.sourceAddr.toString(16).padStart(6, '0').toUpperCase()}: dc.l ${ptr.currentValue} [${ptr.confidence}]`);
        console.log(`    → Should be: dc.l ${ptr.suggestedLabel}`);
        console.log(`    → Points to: ${ptr.targetContent.substring(0, 70)}`);
        if (ptr.isTargetCode) console.log(`    → Target is CODE`);
        if (ptr.isTargetLabel) console.log(`    → Target is LABEL`);
        console.log();
    }
    
    if (withLocLabels.length > 50) {
        console.log(`... and ${withLocLabels.length - 50} more`);
    }
    console.log();
}

// Show addresses that need new labels created
if (needNewLabels.length > 0) {
    console.log('POINTERS NEEDING NEW LABELS:');
    console.log('-'.repeat(80));
    
    for (const ptr of needNewLabels.slice(0, 30)) {
        console.log(`ROM $${ptr.sourceAddr.toString(16).padStart(6, '0').toUpperCase()}: dc.l ${ptr.currentValue}`);
        console.log(`  → Needs label: ${ptr.suggestedLabel}`);
        console.log(`  → Target addr: $${ptr.targetAddr.toString(16).padStart(6, '0').toUpperCase()}`);
        console.log(`  → Target code: ${ptr.targetContent.substring(0, 70)}`);
        console.log();
    }
    
    if (needNewLabels.length > 30) {
        console.log(`... and ${needNewLabels.length - 30} more`);
    }
    console.log();
}

// Show low-confidence findings
if (likelyFalsePositives.length > 0) {
    console.log('LOW-CONFIDENCE POINTERS (likely prices/IDs, manual review needed):');
    console.log('-'.repeat(80));
    
    const fpWithLocLabels = likelyFalsePositives.filter(p => p.existsInAsm);
    
    for (const ptr of fpWithLocLabels.slice(0, 20)) {
        console.log(`ROM $${ptr.sourceAddr.toString(16).padStart(6, '0').toUpperCase()}: dc.l ${ptr.currentValue}`);
        console.log(`  → Could be: dc.l ${ptr.suggestedLabel} (but value=$${ptr.targetAddr.toString(16)} seems small)`);
        console.log(`  → Points to: ${ptr.targetContent.substring(0, 70)}`);
        console.log();
    }
    
    if (fpWithLocLabels.length > 20) {
        console.log(`... and ${fpWithLocLabels.length - 20} more`);
    }
    console.log();
}

// Save detailed report
const report = {
    romSize: 0xA0000,
    summary: {
        highConfidence: highConfidence.length,
        mediumConfidence: mediumConfidence.length,
        total: pointers.length,
        withLabels: withLabels.length,
        withLocLabels: withLocLabels.length,
        needNewLabels: needNewLabels.length,
        lowConfidence: likelyFalsePositives.length
    },
    highConfidencePointers: highConfidence,
    mediumConfidencePointers: mediumConfidence,
    pointersToFix: withLocLabels,
    pointersNeedingLabels: needNewLabels,
    lowConfidenceFalsePositives: likelyFalsePositives
};

fs.writeFileSync('pointer_analysis.json', JSON.stringify(report, null, 2));
console.log('Full report saved to pointer_analysis.json');
console.log(`\nRecommendation: Start with the ${highConfidence.length} high-confidence pointers`);
console.log(`Consider reviewing the ${mediumConfidence.length} medium-confidence pointers`);
console.log('Review low-confidence matches manually to determine if they are truly pointers.');
