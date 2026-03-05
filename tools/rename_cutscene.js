// tools/rename_cutscene.js
// Rename all _LoopN / _DoneN sub-labels in src/cutscene.asm
// Run: node tools/rename_cutscene.js

const fs = require('fs');
const path = require('path');

const FILE = path.join(__dirname, '..', 'src', 'cutscene.asm');
let src = fs.readFileSync(FILE, 'utf8');

// Rename map: [oldLabel, newLabel]
// Process highest-numbered first to avoid prefix collisions.
const renames = [
  // DrawTilemapBlock_15x12 — inner tile write loop
  ['DrawTilemapBlock_15x12_Done2', 'DrawTilemapBlock_15x12_WriteTile'],

  // DrawTilemapBlock_13x10 — inner tile write loop
  ['DrawTilemapBlock_13x10_Done2', 'DrawTilemapBlock_13x10_WriteTile'],

  // DrawVerticalText — after all lines done, fall into end
  ['DrawVerticalText_NewLine_Loop2', 'DrawVerticalText_End'],

  // ResetTownCameraMovementState — update tile Y after clamp
  ['ResetTownCameraMovementState_Loop2', 'ResetTownCameraMovementState_UpdateTileY'],

  // TownCameraScrollUp_TileStep — per-tile scroll sub-steps (highest first)
  ['TownCameraScrollUp_TileStep_Loop4', 'TownCameraScrollUp_TileStep_UpdateScrollDown'],
  ['TownCameraScrollUp_TileStep_Loop3', 'TownCameraScrollUp_TileStep_CommitTileY'],
  ['TownCameraScrollUp_TileStep_Loop2', 'TownCameraScrollUp_TileStep_ClampTileY'],

  // TownCameraScrollDown_TileStep — update tile X
  ['TownCameraScrollDown_TileStep_Loop2', 'TownCameraScrollDown_TileStep_UpdateTileX'],

  // TownCameraScrollLeft_TileStep — per-tile scroll sub-steps (highest first)
  ['TownCameraScrollLeft_TileStep_Loop4', 'TownCameraScrollLeft_TileStep_UpdateScrollRight'],
  ['TownCameraScrollLeft_TileStep_Loop3', 'TownCameraScrollLeft_TileStep_CommitTileX'],
  ['TownCameraScrollLeft_TileStep_Loop2', 'TownCameraScrollLeft_TileStep_ClampTileX'],

  // InitializeTilemapFromData — map layout steps (highest first)
  ['InitializeTilemapFromData_Loop6', 'InitializeTilemapFromData_NextTile'],
  ['InitializeTilemapFromData_Loop5', 'InitializeTilemapFromData_WritePlaneA'],
  ['InitializeTilemapFromData_Loop4', 'InitializeTilemapFromData_AdjustOriginX'],
  ['InitializeTilemapFromData_Loop3', 'InitializeTilemapFromData_CheckRowOverflow'],
  ['InitializeTilemapFromData_Loop2', 'InitializeTilemapFromData_AdjustOriginY'],

  // WriteTownTilemapToVRAM — plane B write and palette region 2 (highest first)
  ['WriteTownTilemapToVRAM_Loop2', 'WriteTownTilemapToVRAM_SetPaletteRegion2'],
  ['WriteTownTilemapToVRAM_Done2', 'WriteTownTilemapToVRAM_WritePlaneB'],

  // DrawTownTilemapRow — advance to next tile
  ['DrawTownTilemapRow_Loop2', 'DrawTownTilemapRow_NextTile'],

  // DrawTownTilemapColumn — advance to next tile
  ['DrawTownTilemapColumn_Loop2', 'DrawTownTilemapColumn_NextTile'],

  // WriteTilemapRowToVDP — merge plane A tiles
  ['WriteTilemapRowToVDP_Loop2', 'WriteTilemapRowToVDP_MergePlaneA'],

  // WriteTilemapColumnToVDP — merge plane A/B rows (highest first)
  ['WriteTilemapColumnToVDP_Loop4', 'WriteTilemapColumnToVDP_MergePlaneA_Row2'],
  ['WriteTilemapColumnToVDP_Loop3', 'WriteTilemapColumnToVDP_MergePlaneB_Row2'],
  ['WriteTilemapColumnToVDP_Loop2', 'WriteTilemapColumnToVDP_MergePlaneA'],

  // UpdatePaletteCycle — set palette index
  ['UpdatePaletteCycle_Loop2', 'UpdatePaletteCycle_SetPaletteIndex'],

  // TilemapDecompression_JumpTable — decompression type dispatch (highest first)
  ['TilemapDecompression_JumpTable_Loop8', 'TilemapDecompression_Copy2RowsBack'],
  ['TilemapDecompression_JumpTable_Loop7', 'TilemapDecompression_CopyPrevRow'],
  ['TilemapDecompression_JumpTable_Loop6', 'TilemapDecompression_Repeat4Bytes'],
  ['TilemapDecompression_JumpTable_Loop5', 'TilemapDecompression_Repeat3Bytes'],
  ['TilemapDecompression_JumpTable_Loop4', 'TilemapDecompression_Repeat2Bytes'],
  ['TilemapDecompression_JumpTable_Loop3', 'TilemapDecompression_RepeatByte'],
  ['TilemapDecompression_JumpTable_Loop2', 'TilemapDecompression_CopyLiterals'],

  // TitleScreen_FadeAndAnimate — clamp animation frame
  ['TitleScreen_FadeAndAnimate_Loop2', 'TitleScreen_FadeAndAnimate_ClampFrame'],

  // TitleScreen_LightningFlash — flash sub-steps (highest first)
  ['TitleScreen_LightningFlash_Loop4', 'TitleScreen_LightningFlash_WhiteFlash'],
  ['TitleScreen_LightningFlash_Loop3', 'TitleScreen_LightningFlash_FinalFlash'],
  ['TitleScreen_LightningFlash_Loop2', 'TitleScreen_LightningFlash_FlashStep'],

  // TitleScreen_ShowPressStart — wait for fade before showing
  ['TitleScreen_ShowPressStart_Loop2', 'TitleScreen_ShowPressStart_WaitFade'],

  // UpdatePrologueScrollVRAM — clamp scroll at end/zero (highest first)
  ['UpdatePrologueScrollVRAM_Loop3', 'UpdatePrologueScrollVRAM_ClampToZero'],
  ['UpdatePrologueScrollVRAM_Loop2', 'UpdatePrologueScrollVRAM_ClampToEnd'],

  // DrawIntroBackground — inner tile write loop
  ['DrawIntroBackground_Done2', 'DrawIntroBackground_WriteTile'],

  // DrawIntroGraphics — nested tile/row writes (highest first)
  ['DrawIntroGraphics_Done7', 'DrawIntroGraphics_WriteSwordTile'],
  ['DrawIntroGraphics_Done6', 'DrawIntroGraphics_WriteSwordRow'],
  ['DrawIntroGraphics_Done5', 'DrawIntroGraphics_WriteSwordGroup'],
  ['DrawIntroGraphics_Done4', 'DrawIntroGraphics_WriteTile2'],
  ['DrawIntroGraphics_Done3', 'DrawIntroGraphics_WriteRow2'],
  ['DrawIntroGraphics_Done2', 'DrawIntroGraphics_WriteTile1'],

  // DrawTilemapToVRAM_PlaneA — inner tile write loop
  ['DrawTilemapToVRAM_PlaneA_Done2', 'DrawTilemapToVRAM_PlaneA_WriteTile'],

  // DrawPressStartText — inner tile write loop
  ['DrawPressStartText_Done2', 'DrawPressStartText_WriteTile'],

  // === Ending Sequence step handlers ===
  // Process highest-numbered suffixes first to avoid prefix collisions.

  // EndingSequence_ScrollText_Done_Loop — step 17/18 sub-steps (highest first)
  ['EndingSequence_ScrollText_Done_Loop4', 'EndingStep_WaitForCreditsEnd_Scroll'],
  ['EndingSequence_ScrollText_Done_Loop3', 'EndingStep_DisplayCreditLines_WriteRow'],
  ['EndingSequence_ScrollText_Done_Loop2', 'EndingStep_WaitForCreditsEnd'],
  ['EndingSequence_ScrollText_Done_Loop', 'EndingStep_DisplayCreditLines'],

  // EndingStep_Return7_Loop — step 15/16 sub-steps (highest first)
  ['EndingStep_Return7_Loop6', 'EndingStep_ClearDialogSprites'],
  ['EndingStep_Return7_Loop5_Done', 'EndingStep_ClearNameBuffer'],
  ['EndingStep_Return7_Loop5', 'EndingStep_ScrollCreditsText_DrawCheck'],
  ['EndingStep_Return7_Loop4', 'EndingStep_ScrollCreditsText_OverseasSpeed'],
  ['EndingStep_Return7_Loop3', 'EndingStep_WaitAndInitFontTiles_Return'],
  ['EndingStep_Return7_Loop2', 'EndingStep_ScrollCreditsText'],
  ['EndingStep_Return7_Loop', 'EndingStep_WaitAndInitFontTiles'],

  // EndingStep_Return6_Loop — step 13/14 sub-steps (highest first)
  ['EndingStep_Return6_Loop4', 'EndingStep_ScrollUpStep'],
  ['EndingStep_Return6_Loop3', 'EndingStep_FillPattern_Return'],
  ['EndingStep_Return6_Loop2', 'EndingStep_ScrollUpAndAdvance'],
  ['EndingStep_Return6_Loop', 'EndingStep_FillPattern'],

  // EndingStep_Return5_Loop — step 11/12 sub-steps (highest first)
  ['EndingStep_Return5_Loop3', 'EndingStep_DrawOutro5_Return'],
  ['EndingStep_Return5_Loop2', 'EndingStep_WaitAfterOutro5'],
  ['EndingStep_Return5_Loop', 'EndingStep_DrawOutro5'],

  // EndingStep_Return4_Loop — step 9/10 sub-steps (highest first)
  ['EndingStep_Return4_Loop3', 'EndingStep_DrawOutro4_Return'],
  ['EndingStep_Return4_Loop2', 'EndingStep_WaitAfterOutro4'],
  ['EndingStep_Return4_Loop', 'EndingStep_DrawOutro4'],

  // EndingSequenceStep_Done_Loop — step 8
  ['EndingSequenceStep_Done_Loop', 'EndingStep_WaitThenFadeToBlack'],

  // EndingStep_Return3_Loop — step 6/7 sub-steps (highest first)
  ['EndingStep_Return3_Loop4', 'EndingStep_ScrollFireStep'],
  ['EndingStep_Return3_Loop3', 'EndingStep_InitCreditsScreen_Return'],
  ['EndingStep_Return3_Loop2', 'EndingStep_ScrollFireAndDrawOutro3'],
  ['EndingStep_Return3_Loop', 'EndingStep_InitCreditsScreen'],

  // EndingStep_Return2_Loop — step 4/5 sub-steps (highest first)
  ['EndingStep_Return2_Loop3', 'EndingStep_DrawOutro2_Return'],
  ['EndingStep_Return2_Loop2', 'EndingStep_WaitThenFadeOut'],
  ['EndingStep_Return2_Loop', 'EndingStep_DrawOutro2'],

  // EndingStep_Return1_Loop — step 1/2/3 sub-steps (highest first)
  ['EndingStep_Return1_Loop5', 'EndingStep_WaitAndDrawOutro1_Return'],
  ['EndingStep_Return1_Loop4', 'EndingStep_WaitAndPlayFanfareA_Return'],
  ['EndingStep_Return1_Loop3', 'EndingStep_WaitThenFadeToWhite'],
  ['EndingStep_Return1_Loop2', 'EndingStep_WaitAndDrawOutro1'],
  ['EndingStep_Return1_Loop', 'EndingStep_WaitAndPlayFanfareA'],

  // EndingSequenceStepJumpTable_Loop — step 0
  ['EndingSequenceStepJumpTable_Loop', 'EndingStep_WaitForFadeAndPlayFanfare'],
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
