#!/usr/bin/env node
// Sword of Vermilion - Treasure Chest Analyzer

const fs = require('fs');

console.log('=== Sword of Vermilion Treasure Chest Analyzer ===\n');

const lines = fs.readFileSync('vermilion.asm', 'utf8').split('\n');

const treasureChests = [];
let currentFunc = null;

for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    
    if (line.match(/^loc_[0-9A-F]{8}:/)) {
        currentFunc = line.replace(':', '');
    }
    
    if (line.includes('BSR.w') && 
        (line.includes('InitMoneyTreasure') || 
         line.includes('SetupEquipmentTreasure') ||
         line.includes('loc_0002141E'))) {
        
        let type = 'Unknown';
        let value = 0;
        let flag = '';
        
        for (let j = i - 1; j >= Math.max(0, i - 10); j--) {
            const prevLine = lines[j].trim();
            
            if (prevLine.includes('InitMoneyTreasure')) {
                type = 'Money';
            } else if (prevLine.includes('SetupEquipmentTreasure')) {
                type = 'Equipment';
            } else if (prevLine.includes('loc_0002141E')) {
                type = 'Item';
            }
            
            const valueMatch = prevLine.match(/MOVE\.w\s+#\$([0-9A-F]+),\s+\$FFFFC572/);
            if (valueMatch) {
                value = parseInt(valueMatch[1], 16);
            }
            
            const flagMatch = prevLine.match(/MOVE\.l\s+#\$([0-9A-F]+),\s+\$FFFFC574/);
            if (flagMatch) {
                flag = '$' + flagMatch[1];
            }
        }
        
        treasureChests.push({
            location: currentFunc,
            line: i + 1,
            type: type,
            value: value,
            flag: flag
        });
    }
}

console.log(`Found ${treasureChests.length} treasure chests:\n`);
console.log('| Location | Line | Type | Value | Flag Address | Description |');
console.log('|----------|------|------|-------|--------------|-------------|');

for (const chest of treasureChests) {
    let desc = '';
    if (chest.type === 'Money') {
        desc = `${chest.value} Kims`;
    } else if (chest.type === 'Equipment') {
        desc = `Equipment ID ${chest.value}`;
    } else if (chest.type === 'Item') {
        desc = `Item ID ${chest.value}`;
    }
    
    console.log(`| ${chest.location} | ${chest.line} | ${chest.type} | ${chest.value} | ${chest.flag} | ${desc} |`);
}

console.log(`\nTotal: ${treasureChests.length} treasure chests`);
