// tools/rename_script.js
// Rename all _LoopN / _DoneN sub-labels in src/script.asm
// Run: node tools/rename_script.js

const fs = require('fs');
const path = require('path');

const FILE = path.join(__dirname, '..', 'src', 'script.asm');
let src = fs.readFileSync(FILE, 'utf8');

// Rename map: [oldLabel, newLabel]
// Process highest-numbered first to avoid prefix collisions.
const renames = [
  // ProcessScriptText_Loop2 — dispatch on script control codes
  ['ProcessScriptText_Loop2', 'ProcessScriptText_Dispatch'],

  // DrawShopItemListWindow_Done2 — render each item price row
  ['DrawShopItemListWindow_Done2', 'DrawShopItemListWindow_RenderRow'],

  // DrawTownListWindow_Loop2 — advance row after optional render
  ['DrawTownListWindow_Loop2', 'DrawTownListWindow_AdvanceRow'],

  // RenderTextToTilemap — nested column/row loop
  ['RenderTextToTilemap_Done2', 'RenderTextToTilemap_WriteColumn'],
  // _Done is outer row loop — rename last so _Done2 prefix is gone first
  // (already handled above; now the outer loop)
  // Note: _Done is the outer row, not numbered — already clean, skip

  // LongToDecimalString digit encode: highest first
  ['LongToDecimalString_EncodeDigit_Loop3', 'LongToDecimalString_EncodeDigit_StoreDigit'],
  ['LongToDecimalString_EncodeDigit_Loop2', 'LongToDecimalString_EncodeDigit_WriteVDP'],

  // ConvertNumberToTextDigits digit encode
  ['ConvertNumberToTextDigits_EncodeDigit_Loop3', 'ConvertNumberToTextDigits_EncodeDigit_StoreDigit'],
  ['ConvertNumberToTextDigits_EncodeDigit_Loop2', 'ConvertNumberToTextDigits_EncodeDigit_WriteVDP'],

  // WordToDecimalString_NoPad digit encode
  ['WordToDecimalString_NoPad_EncodeDigit_Loop3', 'WordToDecimalString_NoPad_EncodeDigit_StoreDigit'],
  ['WordToDecimalString_NoPad_EncodeDigit_Loop2', 'WordToDecimalString_NoPad_EncodeDigit_WriteVDP'],

  // DeductPaymentAmount — clamp HP to zero
  ['DeductPaymentAmount_Loop2', 'DeductPaymentAmount_ClampHp'],

  // ValidateSavegameName — name too long: mark overflow
  ['ValidateSavegameName_Loop_Loop2', 'ValidateSavegameName_NameTooLong'],

  // DrawCharacterStatsWindow — condition checks (highest first)
  ['DrawCharacterStatsWindow_Loop3', 'DrawCharacterStatsWindow_ConditionBest'],
  ['DrawCharacterStatsWindow_Loop2', 'DrawCharacterStatsWindow_ConditionGood'],

  // DrawEquippedGearWindow — slot render joins (highest first)
  ['DrawEquippedGearWindow_Loop4', 'DrawEquippedGearWindow_RenderMagic'],
  ['DrawEquippedGearWindow_Loop3', 'DrawEquippedGearWindow_RenderArmor'],
  ['DrawEquippedGearWindow_Loop2', 'DrawEquippedGearWindow_RenderShield'],

  // WindowDrawTypeJumpTable — window type draw targets (highest first)
  ['WindowDrawTypeJumpTable_Loop11', 'WindowDrawTypeJumpTable_DrawRingList'],
  ['WindowDrawTypeJumpTable_Loop10', 'WindowDrawTypeJumpTable_DrawItemListHeight'],
  ['WindowDrawTypeJumpTable_Loop9', 'WindowDrawTypeJumpTable_DrawMagicListHeight'],
  ['WindowDrawTypeJumpTable_Loop8', 'WindowDrawTypeJumpTable_DrawEquipListHeight'],
  ['WindowDrawTypeJumpTable_Loop7', 'WindowDrawTypeJumpTable_DrawDialogWindow'],
  ['WindowDrawTypeJumpTable_Loop6', 'WindowDrawTypeJumpTable_DrawRingListConfig'],
  ['WindowDrawTypeJumpTable_Loop5', 'WindowDrawTypeJumpTable_DrawItemListConfig'],
  ['WindowDrawTypeJumpTable_Loop4', 'WindowDrawTypeJumpTable_DrawMagicListConfig'],
  ['WindowDrawTypeJumpTable_Loop3', 'WindowDrawTypeJumpTable_DrawEquipListConfig'],
  ['WindowDrawTypeJumpTable_Loop2', 'WindowDrawTypeJumpTable_DrawFullMenu'],

  // DrawWindowRow_MessageSpeed — sub-window draw variants (highest first)
  ['DrawWindowRow_MessageSpeed_Loop7', 'DrawWindowRow_ItemList8Rows'],
  ['DrawWindowRow_MessageSpeed_Loop6', 'DrawWindowRow_StatusMenuLarge'],
  ['DrawWindowRow_MessageSpeed_Loop5', 'DrawWindowRow_RightMenu'],
  ['DrawWindowRow_MessageSpeed_Loop4', 'DrawWindowRow_SmallMenu'],
  ['DrawWindowRow_MessageSpeed_Loop3', 'DrawWindowRow_StatusMenu'],
  ['DrawWindowRow_MessageSpeed_Loop2', 'DrawWindowRow_ItemList6Rows'],

  // DrawWindowTilemap_WriteVDP — clear pending / advance row
  ['DrawWindowTilemap_WriteVDP_Loop2', 'DrawWindowTilemap_NextRow'],

  // ReadWindowToBuffer — nested row/column scan
  ['ReadWindowToBuffer_Done2', 'ReadWindowToBuffer_ReadColumn'],

  // DrawStatusHudWindow — skip kims/exp if not first-person
  ['DrawStatusHudWindow_Loop2', 'DrawStatusHudWindow_Return'],

  // DrawWindowFromBuffer — nested row/column blit
  ['DrawWindowFromBuffer_Done2', 'DrawWindowFromBuffer_WriteColumn'],

  // DrawWindowBorder — inner tile selection (highest first)
  ['DrawWindowBorder_Loop4', 'DrawWindowBorder_RightEdge'],
  ['DrawWindowBorder_Loop3', 'DrawWindowBorder_WriteTile'],
  ['DrawWindowBorder_Loop2', 'DrawWindowBorder_BottomRow'],

  // WindowTextDecode_Next — space→dot substitution join
  ['WindowTextDecode_Next_Loop2', 'WindowTextDecode_Next_StoreByte'],

  // DrawWindowTilemapFull — inner column loop
  ['DrawWindowTilemapFull_Done2', 'DrawWindowTilemapFull_WriteColumn'],

  // LoadLevelUpBannerTiles — nested row/tile loops
  ['LoadLevelUpBannerTiles_Done2', 'LoadLevelUpBannerTiles_WriteTile'],

  // DisplayCantUseMessage / DisplayReadiedMagicName
  ['DisplayCantUseMessage_Done2', 'DisplayCantUseMessage_ClearSecondRow'],
  ['DisplayReadiedMagicName_Loop3', 'DisplayReadiedMagicName_WriteToVDP'],
  ['DisplayReadiedMagicName_Loop3_Done2', 'DisplayReadiedMagicName_WriteToVDP_Done'],
  ['DisplayReadiedMagicName_Loop2', 'DisplayReadiedMagicName_NoMagic'],

  // LoadPalettesFromTable — palette line fade checks (highest first)
  ['LoadPalettesFromTable_Return_Loop4', 'LoadPalettesFromTable_FadeLine3'],
  ['LoadPalettesFromTable_Return_Loop3', 'LoadPalettesFromTable_FadeLine2'],
  ['LoadPalettesFromTable_Return_Loop2', 'LoadPalettesFromTable_FadeLine1'],

  // DecrementPaletteRGBValues — RGB component decrement (highest first)
  ['DecrementPaletteRGBValues_Loop2', 'DecrementPaletteRGBValues_CheckBlue'],

  // BuildFadeTable_Store (fade-out) — line checks (highest first)
  ['BuildFadeTable_Store_Loop5', 'BuildFadeTable_FadeOutLine3'],
  ['BuildFadeTable_Store_Loop4', 'BuildFadeTable_FadeOutLine2'],
  ['BuildFadeTable_Store_Loop3', 'BuildFadeTable_FadeOutLine1'],
  ['BuildFadeTable_Store_Loop2', 'BuildFadeTable_FadeOutDone'],

  // ShiftPaletteTowardsTarget — green/blue component shifts
  ['ShiftPaletteTowardsTarget_Loop2', 'ShiftPaletteTowardsTarget_AdjustBlue'],

  // BuildFadeInTable_Store — line checks (highest first)
  ['BuildFadeInTable_Store_Loop13', 'BuildFadeInTable_LoadLine3'],
  ['BuildFadeInTable_Store_Loop12', 'BuildFadeInTable_FadeOrLoadLine3'],
  ['BuildFadeInTable_Store_Loop11', 'BuildFadeInTable_LoadLine2'],
  ['BuildFadeInTable_Store_Loop10', 'BuildFadeInTable_FadeOrLoadLine2'],
  ['BuildFadeInTable_Store_Loop9', 'BuildFadeInTable_LoadLine1'],
  ['BuildFadeInTable_Store_Loop8', 'BuildFadeInTable_FadeOrLoadLine1'],
  ['BuildFadeInTable_Store_Loop7', 'BuildFadeInTable_LoadLine0'],
  ['BuildFadeInTable_Store_Loop6', 'BuildFadeInTable_FadeInLineMasksDone'],
  ['BuildFadeInTable_Store_Loop5', 'BuildFadeInTable_CommitLine3'],
  ['BuildFadeInTable_Store_Loop4', 'BuildFadeInTable_CommitLine2'],
  ['BuildFadeInTable_Store_Loop3', 'BuildFadeInTable_CommitLine1'],
  ['BuildFadeInTable_Store_Loop2', 'BuildFadeInTable_FadeInComplete'],

  // FadePaletteTowardsTarget_NextEntry — commit fade targets (highest first)
  ['FadePaletteTowardsTarget_NextEntry_Loop5', 'FadePaletteTowardsTarget_CommitLine3'],
  ['FadePaletteTowardsTarget_NextEntry_Loop4', 'FadePaletteTowardsTarget_CommitLine2'],
  ['FadePaletteTowardsTarget_NextEntry_Loop3', 'FadePaletteTowardsTarget_CommitLine1'],
  ['FadePaletteTowardsTarget_NextEntry_Loop2', 'FadePaletteTowardsTarget_CommitLine0'],

  // NameEntryScreen_InputHandler — flow joins (highest first)
  ['NameEntryScreen_InputHandler_Loop4', 'NameEntryScreen_InputHandler_CheckCharType'],
  ['NameEntryScreen_InputHandler_Loop3', 'NameEntryScreen_InputHandler_HandleDPad'],
  ['NameEntryScreen_InputHandler_Loop2', 'NameEntryScreen_InputHandler_InputChar'],

  // WriteCharacterToNameEntry — width limit check join (highest first)
  ['WriteCharacterToNameEntry_Loop3', 'WriteCharacterToNameEntry_CheckLimit'],
  ['WriteCharacterToNameEntry_Loop2', 'WriteCharacterToNameEntry_WriteWideHi'],
  ['WriteCharacterToNameEntry_Loop', 'WriteCharacterToNameEntry_WriteWideLo'],

  // NameEntry_ConfirmDone_Loop — backspace flow (highest first)
  ['NameEntry_ConfirmDone_Loop4', 'NameEntry_ConfirmDone_EraseSingle'],
  ['NameEntry_ConfirmDone_Loop3', 'NameEntry_ConfirmDone_EraseWideExtra'],
  ['NameEntry_ConfirmDone_Loop2', 'NameEntry_ConfirmDone_NothingToErase'],

  // DrawNameEntryBackground — nested row/tile loops
  ['DrawNameEntryBackground_Done2', 'DrawNameEntryBackground_WriteTile'],

  // DrawNameEntryCharGrid — nested row/tile loops
  ['DrawNameEntryCharGrid_Done2', 'DrawNameEntryCharGrid_WriteTile'],

  // CheckNameEntryCharValid — key repeat dispatchers (highest first)
  ['CheckNameEntryCharValid_Loop5', 'CheckNameEntryCharValid_RepeatLeft'],
  ['CheckNameEntryCharValid_Loop4', 'CheckNameEntryCharValid_RepeatDown'],
  ['CheckNameEntryCharValid_Loop3', 'CheckNameEntryCharValid_RepeatUp'],
  ['CheckNameEntryCharValid_Loop2', 'CheckNameEntryCharValid_Invalid'],

  // SegaLogoScreen_Init — nested row/tile loops (highest first)
  ['SegaLogoScreen_Init_Done3', 'SegaLogoScreen_Init_WriteTile'],
  ['SegaLogoScreen_Init_Done2', 'SegaLogoScreen_Init_WriteRow'],

  // SegaLogoScreen_FadeIn — flow joins (highest first)
  ['SegaLogoScreen_FadeIn_Loop4', 'SegaLogoScreen_FadeIn_UpdatePalette'],
  ['SegaLogoScreen_FadeIn_Loop3', 'SegaLogoScreen_FadeIn_AdvancePalette'],
  ['SegaLogoScreen_FadeIn_Loop2', 'SegaLogoScreen_FadeIn_CheckStep'],

  // LoadPrologueFadeParams — fade type dispatch (highest first)
  ['LoadPrologueFadeParams_Loop2', 'LoadPrologueFadeParams_SetCrossFadeMask'],

  // PrologueStateJumpTable — debug max-stats helpers (highest first)
  ['PrologueStateJumpTable_Loop2', 'PrologueStateJumpTable_MaxAllStats'],

  // DebugMaxStats_Return_Loop2 — prologue state handlers
  ['DebugMaxStats_Return_Loop2', 'PrologueTick_DrawScene6'],

  // PrologueTick_WaitTimer — timer expired join
  ['PrologueTick_WaitTimer_Loop2', 'PrologueTick_TimerExpired'],
];

// Apply renames as whole-word replacements, highest-numbered last processed
// (already ordered above).  Process in reverse to avoid prefix collisions.
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
