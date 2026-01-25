const fs = require('fs');

// Read the file
let content = fs.readFileSync('vermilion.asm', 'utf8');

// Read rename mapping
const renameMap = [
  ['loc_00016328', 'DrawTownRow_Up'],
  ['loc_00015A94', 'DrawPrologueScene6'],
  ['loc_00015A1E', 'DrawPrologueScene4and5'],
  ['loc_000159DE', 'DrawPrologueScene3'],
  ['loc_00015968', 'DrawPrologueScene1and2'],
  ['loc_0001548A', 'HandleNameEntryDPad'],
  ['loc_00015442', 'DrawNameEntryCharGrid'],
  ['loc_000153FA', 'DrawNameEntryBackground'],
  ['loc_00012CE2', 'RenderFormattedTextToWindow'],
  ['loc_00012BE6', 'DrawSpecialCharToVRAM'],
  ['loc_00011BA4', 'GetMagicNamePointer'],
  ['loc_00011798', 'ValidateSavegameName'],
  ['loc_00011506', 'WriteDigitToWindowPlane3'],
  ['loc_0001092E', 'CopySramBackupToSlot'],
  ['loc_0001050E', 'CountTerrainTileType'],
  ['loc_000104CA', 'DetermineTerrainTileset'],
  ['loc_0000FF74', 'DecompressTileLoop'],
  ['loc_0000FCA2', 'WriteTileRowFromBitfield'],
  ['loc_0000FC1C', 'DecompressFontTile'],
  ['loc_0000FC04', 'WriteMaskedTileRow'],
  ['loc_0000F56C', 'WriteTilesToVRAM'],
  ['loc_0000F4C2', 'GetDirectionFromDeltas'],
  ['loc_0000F49C', 'CalculateDirectionToPlayer'],
  ['loc_0000F482', 'CalculateDirectionToEntity'],
  ['loc_0000F3B8', 'UpdateBossBodyTiles'],
  ['loc_0000ECC4', 'CheckPlayerWithinRange'],
  ['loc_0000EBBE', 'InitBossProjectile'],
  ['loc_0000EB9C', 'DeactivateBossBodyParts'],
  ['loc_0000E63C', 'ActivateNextBossPart'],
  ['loc_0000E4DE', 'CalculateSineVelocity'],
  ['loc_0000DC54', 'CheckBossDamageAndKnockback'],
  ['loc_0000D094', 'DisplayBattleVictoryMessage'],
  ['loc_0000D06A', 'AwardBattleRewards'],
  ['loc_0000CEA6', 'SetBattleVictoryAnimFrames2'],
  ['loc_0000CE4A', 'SetBattleVictoryAnimFrames1'],
  ['loc_0000CD3C', 'AnimateBossAttackFlash'],
  ['loc_0000CCB2', 'DrawBossAttackGraphic1'],
  ['loc_0000CC82', 'UpdateBossAttackGraphic'],
  ['loc_0000CBCC', 'DrawBossNameplate'],
  ['loc_0000CB8C', 'DrawBossPortrait'],
  ['loc_0000CB1E', 'ProcessBattleDamageAndPalette'],
  ['loc_0000BF14', 'UpdateBattleParallaxLayers'],
  ['loc_00008830', 'InitMapIndicatorEntity'],
  ['loc_00008768', 'InitObjectEntity_Type14'],
  ['loc_0000852E', 'BackupRingsToMapTriggers'],
  ['loc_000084F2', 'CheckItemInList'],
  ['loc_000083F8', 'CheckAdjacentTileCollision'],
  ['loc_000083AA', 'CheckSurroundingTileCollision'],
  ['loc_00008376', 'CheckEntityOnScreen'],
  ['loc_0000820C', 'AnimateEntitySprite'],
  ['loc_0000809E', 'GetStaticNPCAnimationOffset'],
  ['loc_00008052', 'CheckPlayerInBoundingBox'],
  ['loc_00007FAC', 'UpdateParmaSoldierRotation'],
  ['loc_00006C10', 'DispatchBattleCollisionChecks'],
  ['loc_0000651A', 'UpdateCaveLightTimer'],
  ['loc_000063B2', 'CheckCaveRoomMapRevealed'],
  ['loc_00006390', 'CheckOverworldSectorMapRevealed'],
  ['loc_00006060', 'RenderMapToVRAM_DualPalette_21x13_Alt'],
  ['loc_00006052', 'RenderMapToVRAM_DualPalette_21x13'],
  ['loc_00006048', 'RenderMapToVRAM_DualPalette_21x20']
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
    changeCount += matches.length - 1; // -1 because we already counted the definition
    console.log(`${oldLabel} -> ${newName}: ${matches.length} replacements`);
  }
}

// Write back
fs.writeFileSync('vermilion.asm', content);

console.log(`\nRenamed ${renameMap.length} functions with ${changeCount} total replacements`);
