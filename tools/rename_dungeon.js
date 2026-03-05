// tools/rename_dungeon.js
// Rename all _LoopN / _DoneN sub-labels in src/dungeon.asm
// Run: node tools/rename_dungeon.js

const fs = require('fs');
const path = require('path');

const FILE = path.join(__dirname, '..', 'src', 'dungeon.asm');
let src = fs.readFileSync(FILE, 'utf8');

// Rename map: [oldLabel, newLabel]
// Process highest-numbered first to avoid prefix collisions.
const renames = [
  // HandleMapTileTransition — tile transition type dispatch (highest first)
  ['HandleMapTileTransition_Loop5', 'HandleMapTileTransition_SaveCavePosition'],
  ['HandleMapTileTransition_Loop4', 'HandleMapTileTransition_ClearHighBitAndEnterCave'],
  ['HandleMapTileTransition_Loop3', 'HandleMapTileTransition_EnterTown'],
  ['HandleMapTileTransition_Loop2', 'HandleMapTileTransition_EnterCave'],

  // RotateCounterClockwiseJumpTable — rotate/facing dispatch (highest first)
  ['RotateCounterClockwiseJumpTable_Loop12', 'RotateCounterClockwiseJumpTable_DisplayCaveStats_21x13Alt'],
  ['RotateCounterClockwiseJumpTable_Loop11', 'RotateCounterClockwiseJumpTable_Init21x13Alt_And_Render'],
  ['RotateCounterClockwiseJumpTable_Loop10', 'RotateCounterClockwiseJumpTable_DisplayCaveStats_21x20'],
  ['RotateCounterClockwiseJumpTable_Loop9', 'RotateCounterClockwiseJumpTable_Init21x20_And_Render'],
  ['RotateCounterClockwiseJumpTable_Loop8', 'RotateCounterClockwiseJumpTable_DisplayCaveStats_21x13'],
  ['RotateCounterClockwiseJumpTable_Loop7', 'RotateCounterClockwiseJumpTable_Init21x13_And_Render'],
  ['RotateCounterClockwiseJumpTable_Loop6', 'RotateCounterClockwiseJumpTable_RotateCCW_West'],
  ['RotateCounterClockwiseJumpTable_Loop5', 'RotateCounterClockwiseJumpTable_RotateCCW_East'],
  ['RotateCounterClockwiseJumpTable_Loop4', 'RotateCounterClockwiseJumpTable_RotateCCW_South'],
  ['RotateCounterClockwiseJumpTable_Loop3', 'RotateCounterClockwiseJumpTable_RotateCW_South'],
  ['RotateCounterClockwiseJumpTable_Loop2', 'RotateCounterClockwiseJumpTable_RotateCW_East'],

  // RenderWallTile_NearTwoPalette — rotate action sub-steps (highest first)
  ['RenderWallTile_NearTwoPalette_Loop6', 'RenderWallTile_NearTwoPalette_RotateCW_UpdateArea'],
  ['RenderWallTile_NearTwoPalette_Loop5', 'RenderWallTile_NearTwoPalette_RotateCW_DisplayKims'],
  ['RenderWallTile_NearTwoPalette_Loop4', 'RenderWallTile_NearTwoPalette_RotateCCW_UpdateArea'],
  ['RenderWallTile_NearTwoPalette_Loop3', 'RenderWallTile_NearTwoPalette_RotateCCW_DisplayKims'],
  ['RenderWallTile_NearTwoPalette_Loop2', 'RenderWallTile_NearTwoPalette_RotateCW'],

  // ForwardMovementJumpTable — forward step palette/frame sub-steps (highest first)
  ['ForwardMovementJumpTable_Loop12', 'ForwardMovementJumpTable_PaletteCycleWrap_NonCave'],
  ['ForwardMovementJumpTable_Loop11', 'ForwardMovementJumpTable_LoadPalette_Frame12'],
  ['ForwardMovementJumpTable_Loop10', 'ForwardMovementJumpTable_ClampHpAfterHeal_Frame12'],
  ['ForwardMovementJumpTable_Loop9', 'ForwardMovementJumpTable_LoadPaletteDone_Frame12'],
  ['ForwardMovementJumpTable_Loop8', 'ForwardMovementJumpTable_ClampHpAfterHeal_Frame8'],
  ['ForwardMovementJumpTable_Loop7', 'ForwardMovementJumpTable_LoadPaletteDone_Frame8'],
  ['ForwardMovementJumpTable_Loop6', 'ForwardMovementJumpTable_LoadPalette_Frame8'],
  ['ForwardMovementJumpTable_Loop5', 'ForwardMovementJumpTable_LoadPalette_Frame0'],
  ['ForwardMovementJumpTable_Loop4', 'ForwardMovementJumpTable_Frame16_PaletteCycle'],
  ['ForwardMovementJumpTable_Loop3', 'ForwardMovementJumpTable_Frame12_CaveWalls'],
  ['ForwardMovementJumpTable_Loop2', 'ForwardMovementJumpTable_CheckPoison_Frame8'],

  // BackwardMovementJumpTable — backward move palette cycle wrap
  ['BackwardMovementJumpTable_Loop2', 'BackwardMovementJumpTable_PaletteCycleWrap_NonCave'],

  // DungeonBackwardMove_LoadPaletteDraw — backward step sub-steps (highest first)
  ['DungeonBackwardMove_LoadPaletteDraw_Loop10', 'DungeonBackwardMove_LoadPalette_Frame16'],
  ['DungeonBackwardMove_LoadPaletteDraw_Loop9', 'DungeonBackwardMove_LoadPalette_Frame4'],
  ['DungeonBackwardMove_LoadPaletteDraw_Loop8', 'DungeonBackwardMove_ClampHpAfterHeal_Frame4'],
  ['DungeonBackwardMove_LoadPaletteDraw_Loop7', 'DungeonBackwardMove_LoadPaletteDone_Frame4'],
  ['DungeonBackwardMove_LoadPaletteDraw_Loop6', 'DungeonBackwardMove_ClampHpAfterHeal_Frame8'],
  ['DungeonBackwardMove_LoadPaletteDraw_Loop5', 'DungeonBackwardMove_CheckPoison_Frame8'],
  ['DungeonBackwardMove_LoadPaletteDraw_Loop4', 'DungeonBackwardMove_LoadPalette_Frame12'],
  ['DungeonBackwardMove_LoadPaletteDraw_Loop3', 'DungeonBackwardMove_Frame16_PaletteCycle'],
  ['DungeonBackwardMove_LoadPaletteDraw_Loop2', 'DungeonBackwardMove_Frame4_CaveWalls'],

  // ApplyAreaDamageToObjects — damage application join
  ['ApplyAreaDamageToObjects_Loop2', 'ApplyAreaDamageToObjects_Apply'],

  // DrawFirstPersonWalls — draw center and far wall steps
  ['DrawFirstPersonWalls_Loop3', 'DrawFirstPersonWalls_Return'],
  ['DrawFirstPersonWalls_Loop2', 'DrawFirstPersonWalls_DrawCenterWall'],

  // RenderWallTile_14x10_TwoPalette — inner tile write loops
  ['RenderWallTile_14x10_TwoPalette_Done3', 'RenderWallTile_14x10_TwoPalette_WritePalette2Tile'],
  ['RenderWallTile_14x10_TwoPalette_Done2', 'RenderWallTile_14x10_TwoPalette_WritePalette1Tile'],

  // RenderWallTile_14x10_TwoPalette_RightWall — inner tile write loops
  ['RenderWallTile_14x10_TwoPalette_RightWall_Done3', 'RenderWallTile_14x10_TwoPalette_RightWall_WritePalette2Tile'],
  ['RenderWallTile_14x10_TwoPalette_RightWall_Done2', 'RenderWallTile_14x10_TwoPalette_RightWall_WritePalette1Tile'],

  // RenderWallTile_16x5_Palette1 / Palette0 — inner tile write loops
  ['RenderWallTile_16x5_Palette1_Done2', 'RenderWallTile_16x5_Palette1_WriteTile'],
  ['RenderWallTile_16x5_Palette0_Done2', 'RenderWallTile_16x5_Palette0_WriteTile'],

  // RenderWallTile_16x11_TwoPalette — inner tile write loops
  ['RenderWallTile_16x11_TwoPalette_Done3', 'RenderWallTile_16x11_TwoPalette_WritePalette2Tile'],
  ['RenderWallTile_16x11_TwoPalette_Done2', 'RenderWallTile_16x11_TwoPalette_WritePalette1Tile'],

  // ClearFirstPersonTilemap — inner clear loop
  ['ClearFirstPersonTilemap_Done2', 'ClearFirstPersonTilemap_ClearTile'],

  // UpdateMapSectorPosition — scroll right/down from current sector
  ['UpdateMapSectorPosition_Loop3', 'UpdateMapSectorPosition_ScrollDown'],
  ['UpdateMapSectorPosition_Loop2', 'UpdateMapSectorPosition_ScrollRight'],

  // RenderFpSector_Near — load object tiles after wall render
  ['RenderFpSector_Near_Loop2', 'RenderFpSector_Near_LoadObjectTiles'],

  // RenderFpSector_Far — mid wall and object tile steps
  ['RenderFpSector_Far_Loop3', 'RenderFpSector_Far_LoadObjectTiles'],
  ['RenderFpSector_Far_Loop2', 'RenderFpSector_Far_RenderMidWall'],

  // RenderFpSector_Mid — load object tiles
  ['RenderFpSector_Mid_Loop2', 'RenderFpSector_Mid_LoadObjectTiles'],

  // MapTileToTypeIndex — tile type classification (highest first)
  ['MapTileToTypeIndex_Loop5', 'MapTileToTypeIndex_SetType3_OverworldCave'],
  ['MapTileToTypeIndex_Loop4', 'MapTileToTypeIndex_ClearType'],
  ['MapTileToTypeIndex_Loop3', 'MapTileToTypeIndex_NormalType'],
  ['MapTileToTypeIndex_Loop2', 'MapTileToTypeIndex_SetType4_UpperCave'],

  // ValidateDungeonTileType — tile type validation (highest first)
  ['ValidateDungeonTileType_Loop4', 'ValidateDungeonTileType_SetType3_OverworldCave'],
  ['ValidateDungeonTileType_Loop3', 'ValidateDungeonTileType_NormalType'],
  ['ValidateDungeonTileType_Loop2', 'ValidateDungeonTileType_SetType4_UpperCave'],

  // RenderMapToVRAM_NoPalette — inner tile write loops
  ['RenderMapToVRAM_NoPalette_Done3', 'RenderMapToVRAM_NoPalette_WritePalette2Tile'],
  ['RenderMapToVRAM_NoPalette_Done2', 'RenderMapToVRAM_NoPalette_WritePalette1Tile'],

  // RenderMapToVRAM_WithPalette — inner tile write loop
  ['RenderMapToVRAM_WithPalette_Done2', 'RenderMapToVRAM_WithPalette_WriteTile'],

  // DisplayStatsToVRAM_NoPalette — inner tile write loops
  ['DisplayStatsToVRAM_NoPalette_Done3', 'DisplayStatsToVRAM_NoPalette_WritePalette2Tile'],
  ['DisplayStatsToVRAM_NoPalette_Done2', 'DisplayStatsToVRAM_NoPalette_WritePalette1Tile'],

  // DisplayStatsToVRAM_WithPalette — inner tile write loop
  ['DisplayStatsToVRAM_WithPalette_Done2', 'DisplayStatsToVRAM_WithPalette_WriteTile'],

  // UpdateCompassDisplay — neither left nor right; derive frame from direction
  ['UpdateCompassDisplay_Loop2', 'UpdateCompassDisplay_SetFrameFromDirection'],

  // DrawCompassTiles — inner tile write loop
  ['DrawCompassTiles_Done2', 'DrawCompassTiles_WriteTile'],

  // DecompressMapTile_Next — RLE decompression inner steps
  ['DecompressMapTile_Next_Loop3', 'DecompressMapTile_Next_Exit'],
  ['DecompressMapTile_Next_Loop2', 'DecompressMapTile_Next_CheckRleDone'],
];

// Apply renames as whole-word replacements.
for (const [oldName, newName] of renames) {
  const re = new RegExp(`\\b${oldName}\\b`, 'g');
  const before = src;
  src = src.replace(re, newName);
  const count = (before.match(re) || []).length;
  if (count === 0) {
    console.warn(`WARNING: '${oldName}' not found`);
  } else {
    console.log(`${oldName} -> ${newName}  (${count} occurrences)`);
  }
}

fs.writeFileSync(FILE, src, 'utf8');
console.log('Done.');
