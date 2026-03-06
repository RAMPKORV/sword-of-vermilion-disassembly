const fs = require('fs');
let src = fs.readFileSync('E:/Romhacking/vermilion/src/battle_gfx.asm', 'utf8');

// Each entry: [oldLabel, newLabel]
// Ordered most-specific (longer/higher numbered) first to prevent cascade errors
const renames = [
  // WriteDirectionTilesForBoss
  ['WriteDirectionTilesForBoss_Done2', 'WriteDirectionTilesForBoss_TileLoop'],
  ['WriteDirectionTilesForBoss_Done', 'WriteDirectionTilesForBoss_RowLoop'],
  // GetDirectionFromDeltas — rename numbered sub-labels
  ['GetDirectionFromDeltas_Loop8', 'GetDirectionFromDeltas_IncrementAngle'],
  ['GetDirectionFromDeltas_Loop7', 'GetDirectionFromDeltas_CheckCCW'],
  ['GetDirectionFromDeltas_Loop6', 'GetDirectionFromDeltas_AdjustAngle'],
  ['GetDirectionFromDeltas_Loop5', 'GetDirectionFromDeltas_CheckDiagonal2'],
  ['GetDirectionFromDeltas_Loop4', 'GetDirectionFromDeltas_CheckDiagonal'],
  ['GetDirectionFromDeltas_Loop3', 'GetDirectionFromDeltas_ShiftMajorAxis'],
  ['GetDirectionFromDeltas_Loop2', 'GetDirectionFromDeltas_CheckXY'],
  ['GetDirectionFromDeltas_Loop', 'GetDirectionFromDeltas_CheckNegX'],
  // WriteTilesToVRAM
  ['WriteTilesToVRAM_Done2', 'WriteTilesToVRAM_TileLoop'],
  ['WriteTilesToVRAM_Done', 'WriteTilesToVRAM_RowLoop'],
  // AddSpriteToDisplayList
  ['AddSpriteToDisplayList_Done', 'AddSpriteToDisplayList_FindSlot'],
  ['AddSpriteToDisplayList_Loop', 'AddSpriteToDisplayList_InsertSprite'],
  // FlushSpriteAttributesToVDP
  ['FlushSpriteAttributesToVDP_Done', 'FlushSpriteAttributesToVDP_WriteLoop'],
  ['FlushSpriteAttributesToVDP_Loop', 'FlushSpriteAttributesToVDP_WriteTerminator'],
  // SortAndUploadSpriteOAM
  ['QueueSpriteOAM_Return_Done2', 'SortAndUploadSpriteOAM_CopyEntry'],
  ['QueueSpriteOAM_Return_Done', 'SortAndUploadSpriteOAM_BucketLoop'],
  ['QueueSpriteOAM_Return_Loop3_Done', 'ClearSpritePrioritySlots_Loop'],
  ['QueueSpriteOAM_Return_Loop3', 'SortAndUploadSpriteOAM_ErrorTrap'],
  ['QueueSpriteOAM_Return_Loop2', 'SortAndUploadSpriteOAM_BucketEmpty'],
  ['QueueSpriteOAM_Return_Loop', 'SortAndUploadSpriteOAM_Return'],
  // DecompressTileGraphics
  ['DecompressTileGraphics_Loop_Done', 'DecompressTileGraphics_UnmaskedTileLoop'],
  ['DecompressTileGraphics_PixelSkip', 'DecompressTileGraphics_MaskedPixelSkip'],
  ['DecompressTileGraphics_PixelLoop', 'DecompressTileGraphics_ScanPixelBit'],
  ['DecompressTileGraphics_CheckFull', 'DecompressTileGraphics_CheckMaskFull'],
  ['DecompressTileGraphics_Done3', 'DecompressTileGraphics_PixelFillLoop'],
  ['DecompressTileGraphics_Done2', 'DecompressTileGraphics_CheckAllMasked'],
  ['DecompressTileGraphics_Loop3', 'DecompressTileGraphics_SkipMaskedPixel'],
  ['DecompressTileGraphics_Loop2', 'DecompressTileGraphics_AllMaskedDone'],
  ['DecompressTileGraphics_Done', 'DecompressTileGraphics_MaskGroupLoop'],
  ['DecompressTileGraphics_ReadMask', 'DecompressTileGraphics_ReadMaskGroup'],
  ['DecompressTileGraphics_ReadByte', 'DecompressTileGraphics_ReadGroupCount'],
  ['DecompressTileGraphics_Loop', 'DecompressTileGraphics_UnmaskedTile'],
  ['DecompressTileGraphics_UnmaskedEntry', 'DecompressTileGraphics_UnmaskedTileStart'],
  // WriteMaskedTileRow
  ['WriteMaskedTileRow_PixelLoop', 'WriteMaskedTileRow_InitCounter'],
  ['WriteMaskedTileRow_TestPixel', 'WriteMaskedTileRow_TestBit'],
  ['WriteMaskedTileRow_NextPixel', 'WriteMaskedTileRow_AdvancePtr'],
  ['WriteMaskedTileRow_Done', 'WriteMaskedTileRow_PixelLoop'],
  ['WriteMaskedTileRow_Loop', 'WriteMaskedTileRow_SkipWrite'],
  // DecompressFontTile
  ['DecompressFontTile_Loop_Done', 'DecompressFontTile_UnmaskedTileLoop'],
  ['DecompressFontTile_Loop3', 'DecompressFontTile_SkipMaskedPixel'],
  ['DecompressFontTile_Loop2', 'DecompressFontTile_AllMaskedDone'],
  ['DecompressFontTile_Done3', 'DecompressFontTile_PixelFillLoop'],
  ['DecompressFontTile_Done2', 'DecompressFontTile_CheckAllMasked'],
  ['DecompressFontTile_Done', 'DecompressFontTile_MaskGroupLoop'],
  ['DecompressFontTile_Loop', 'DecompressFontTile_UnmaskedTile'],
  // WriteTileRowFromBitfield
  ['WriteTileRowFromBitfield_Done', 'WriteTileRowFromBitfield_PixelLoop'],
  ['WriteTileRowFromBitfield_Loop', 'WriteTileRowFromBitfield_SkipWrite'],
  // ClampTileCoordinates
  ['ClampTileCoordinates_Loop2_Done', 'LoadAndDecompressTileGfx_TileLoop'],  // this label is reused as sub-label in LoadAndDecompressTileGfx!
  ['ClampTileCoordinates_Loop2', 'ClampTileCoordinates_CheckLowNibble'],
  ['ClampTileCoordinates_Loop', 'ClampTileCoordinates_CheckHighNibbleDone'],
  // InitFontTiles
  ['InitFontTiles_Done', 'InitFontTiles_TileLoop'],
  // LoadBattleTerrainGraphics
  ['LoadBattleTerrainGraphics_Loop3', 'LoadBattleTerrainGraphics_CheckOverworld'],
  ['LoadBattleTerrainGraphics_Loop2', 'LoadBattleTerrainGraphics_CheckSoldier'],
  ['LoadBattleTerrainGraphics_Loop', 'LoadBattleTerrainGraphics_CheckCave'],
  // DetermineTerrainTileset
  ['DetermineTerrainTileset_Done2', 'DetermineTerrainTileset_ColLoop'],
  ['DetermineTerrainTileset_Done', 'DetermineTerrainTileset_RowLoop'],
  ['DetermineTerrainTileset_Loop', 'DetermineTerrainTileset_SetField'],
  // CountTerrainTileType
  ['CountTerrainTileType_Loop', 'CountTerrainTileType_CheckWater'],
  ['CountDialogBytes_Return', 'CountTerrainTileType_Return'],
  // Individual tile-load loop labels
  ['LoadBattleTileGraphics_Done', 'LoadBattleTileGraphics_TileLoop'],
  ['LoadBattleUiTileGraphics_Done', 'LoadBattleUiTileGraphics_TileLoop'],
  ['LoadWorldMapTileGraphics_Done', 'LoadWorldMapTileGraphics_TileLoop'],
  ['LoadCaveTileGfxToBuffer_NextTile', 'LoadCaveTileGfxToBuffer_AdvancePtr'],
  ['LoadCaveTileGfxToBuffer_DmaTransfer', 'LoadCaveTileGfxToBuffer_DoDma'],
  ['LoadCaveTileGfxToBuffer_Loop', 'LoadCaveTileGfxToBuffer_TileLoopEnd'],
  ['LoadCaveTileGfxToBuffer_Done', 'LoadCaveTileGfxToBuffer_TileLoop'],
  ['LoadBattleGroundTileGraphics_Done', 'LoadBattleGroundTileGraphics_TileLoop'],
  ['LoadBattleEnemyTileGraphics_Done', 'LoadBattleEnemyTileGraphics_TileLoop'],
  ['LoadBattleStatusTileGraphics_Done', 'LoadBattleStatusTileGraphics_TileLoop'],
  ['LoadCaveEnemyTileGraphics_Done', 'LoadCaveEnemyTileGraphics_TileLoop'],
  ['LoadCaveItemTileGraphics_Done', 'LoadCaveItemTileGraphics_TileLoop'],
  ['LoadBattlePlayerTileGraphics_Done', 'LoadBattlePlayerTileGraphics_TileLoop'],
  ['LoadTownTileGfxToBuffer_Done5', 'LoadTownTileGfxToBuffer_TileLoop5'],
  ['LoadTownTileGfxToBuffer_Done4', 'LoadTownTileGfxToBuffer_TileLoop4'],
  ['LoadTownTileGfxToBuffer_Done3', 'LoadTownTileGfxToBuffer_TileLoop3'],
  ['LoadTownTileGfxToBuffer_Done2', 'LoadTownTileGfxToBuffer_TileLoop2'],
  ['LoadTownTileGfxToBuffer_Done', 'LoadTownTileGfxToBuffer_TileLoop1'],
  ['LoadMenuTileGfxSet3_Done3', 'LoadMenuTileGfxSet3_TileLoop3'],
  ['LoadMenuTileGfxSet3_Set2Loop', 'LoadMenuTileGfxSet3_TileLoop2'],
  ['LoadMenuTileGfxSet3_Done', 'LoadMenuTileGfxSet3_TileLoop1'],
  ['LoadMenuTileGraphics_Done2', 'LoadMenuTileGraphics_TileLoop2'],
  ['LoadMenuTileGraphics_Done', 'LoadMenuTileGraphics_TileLoop1'],
  ['LoadTitleScreenTileGfx_Done2', 'LoadTitleScreenTileGfx_TileLoop2'],
  ['LoadTitleScreenTileGfx_Done', 'LoadTitleScreenTileGfx_TileLoop1'],
  ['LoadTitleScreenGraphics_Done4', 'LoadTitleScreenGraphics_TileLoop4'],
  ['LoadTitleScreenGraphics_Done3', 'LoadTitleScreenGraphics_TileLoop3'],
  ['LoadTitleScreenGraphics_Set2Loop', 'LoadTitleScreenGraphics_TileLoop2'],
  ['LoadTitleScreenGraphics_Done', 'LoadTitleScreenGraphics_TileLoop1'],
  ['LoadOptionsMenuGraphics_Done', 'LoadOptionsMenuGraphics_TileLoop'],
  ['ExecuteVdpDmaFromPointer_Done', 'LoadOverworldStatusTiles_TileLoop'],
  ['LoadBattleHudGraphics_Done2', 'LoadBattleHudGraphics_TileLoop2'],
  ['LoadBattleHudGraphics_Done', 'LoadBattleHudGraphics_TileLoop1'],
  ['LoadBattleGraphics_Done', 'LoadBattleGraphics_TileLoop'],
  ['LoadBattleGraphics_Loop', 'LoadBattleGraphics_Return'],
  ['LoadBattleTilesToVram_Done', 'LoadBattleTilesToVram_EntryLoop'],
  ['LoadBattleTilesToVram_Loop', 'LoadBattleTilesToVram_Return'],
  ['VDP_DMAFill_Done', 'VDP_DMAFill_WaitBusy'],
  ['LoadTownTileGfx_LookupTable_Loop_Done', 'LoadTownTileGfx_DecompressLoop'],
  ['LoadTownTileGfx_LookupTable_Loop', 'LoadTownTileGfx_UseTownTable'],
  ['LoadTownObjectGfx_DecompressLoop', 'LoadTownObjectGfx_TileLoop'],
];

function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

let changed = 0;
for (const [from, to] of renames) {
  const re = new RegExp('(?<![\\w])' + escapeRegex(from) + '(?![\\w])', 'g');
  const matches = src.match(re);
  const count = matches ? matches.length : 0;
  if (count > 0) {
    src = src.replace(re, to);
    console.log(from + ' -> ' + to + ' (' + count + ')');
    changed++;
  }
}

fs.writeFileSync('E:/Romhacking/vermilion/src/battle_gfx.asm', src);
console.log('Done. ' + changed + ' labels renamed.');
