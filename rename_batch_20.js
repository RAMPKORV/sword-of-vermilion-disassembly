const fs = require('fs');

// Read the file
let content = fs.readFileSync('vermilion.asm', 'utf8');

// Batch 20: Final 36 BSR-called functions
const renameMap = [
  ['loc_00005D86', 'InitObjectPositions_21x13Alt'],
  ['loc_00005C02', 'InitObjectPositions_21x20'],
  ['loc_00005A3C', 'InitObjectPositions_21x13'],
  ['loc_00005256', 'RenderWallTile_16x5_Palette0'],
  ['loc_00005224', 'RenderWallTile_16x5_Palette1'],
  ['loc_000051BA', 'RenderWallTile_14x10_TwoPalette_RightWall'],
  ['loc_00004898', 'RenderWallTile_NearTwoPalette'],
  ['loc_00004872', 'RenderWallTile_FarSinglePalette'],
  ['loc_0000484C', 'RenderWallTile_MidSinglePalette'],
  ['loc_00004820', 'RenderWallTile_NearFrontTwoPalette'],
  ['loc_00004234', 'ClearObjectActiveFlags'],
  ['loc_0000421A', 'DispatchBattleMagic'],
  ['loc_000040DE', 'CheckBattleAttackHitbox'],
  ['loc_00003A22', 'CheckTownEnemyCollision'],
  ['loc_00003654', 'PlayBattleMusic'],
  ['loc_000035FA', 'UpdatePlayerOverworldPosition'],
  ['loc_0000341A', 'DisplayKimsAndCompass'],
  ['loc_0000340C', 'UpdateAndDisplayCompass'],
  ['loc_0000336E', 'LoadTownStateData'],
  ['loc_00003064', 'DrawBattleNametable'],
  ['loc_00002FDA', 'DrawTerrainTilemapHelper'],
  ['loc_00001448', 'ProcessSoundQueue'],
  ['loc_0000141E', 'FillVScrollTable'],
  ['loc_00001364', 'UpdateSceneScrollBuffers'],
  ['loc_000012C0', 'UpdateScrollRegs_Boss'],
  ['loc_00001282', 'UpdateScrollRegs_Normal'],
  ['loc_00001242', 'ReadControllerPort'],
  ['loc_000011EE', 'ReadControllers'],
  ['loc_000011D4', 'CheckDebugMode'],
  ['loc_00000404', 'LoadZ80Driver'],
  ['loc_000003D6', 'InitZ80SoundDriver'],
  ['loc_0000035A', 'InitVDPAndClearVRAM'],
  ['loc_0000032A', 'InitYM2612'],
  ['loc_000002B6', 'ClearVRAMHScroll'],
  ['loc_0000029A', 'ClearVSRAM'],
  ['loc_00000280', 'ClearVRAMSprites']
];

let changeCount = 0;

// Apply all renames
for (const [oldLabel, newName] of renameMap) {
  // Replace label definition (add comment with old name) - case insensitive
  const labelDefRegex = new RegExp('^' + oldLabel + ':', 'gmi');
  const labelDefMatch = content.match(labelDefRegex);
  if (labelDefMatch) {
    content = content.replace(labelDefRegex, ';' + oldLabel + ':\n' + newName + ':');
    changeCount++;
  }
  
  // Replace all references to the label - case insensitive
  const labelRefRegex = new RegExp('\\b' + oldLabel + '\\b', 'gi');
  const matches = content.match(labelRefRegex);
  if (matches) {
    content = content.replace(labelRefRegex, newName);
    changeCount += matches.length - 1;
    console.log(`${oldLabel} -> ${newName}: ${matches.length} replacements`);
  }
}

// Write back
fs.writeFileSync('vermilion.asm', content);
console.log(`\nRenamed ${renameMap.length} functions with ${changeCount} total replacements`);
