const fs = require('fs');
let src = fs.readFileSync('E:/Romhacking/vermilion/src/magic.asm', 'utf8');

const renames = [
  // SpellbookMenuStateJumpTable — rename state 0's label
  ['SpellbookMenuStateJumpTable_Loop3', 'SpellbookMenuPhase_CheckCButton'],  // checking C button after B miss
  ['SpellbookMenuStateJumpTable_Loop6', 'SpellbookMenuPhase_CombatReadyCheck'],  // checks if any magic is ready
  ['SpellbookMenuStateJumpTable_Loop7', 'SpellbookMenuPhase_NoCombatBooks'],  // no combat spell books
  ['SpellbookMenuStateJumpTable_Loop5', 'SpellbookMenuPhase_CastSpell'],  // cast spell path
  ['SpellbookMenuStateJumpTable_Loop4', 'SpellbookMenuPhase_HasSpellsCheck'],  // has spells?

  // State 2: script wait + C/B to dismiss
  ['SpellbookMenu_Return_Loop', 'SpellbookState_ScriptWaitDismiss'],

  // State 3: wait for script then draw equip magic list
  ['SpellMenu_ScriptDoneShowStatus_Loop', 'SpellbookState_WaitThenDrawEquipList'],

  // State 5: yes/no confirm for equip
  ['SpellMenu_ScriptDoneShowStatus_Loop3', 'SpellbookState_EquipYesNoWait'],
  ['SpellMenu_ScriptDoneShowStatus_Loop19', 'SpellbookState_EquipYesNoCancel'],
  ['SpellMenu_ScriptDoneShowStatus_Loop21', 'SpellbookState_UnequipMagic'],
  ['SpellMenu_ScriptDoneShowStatus_Loop22', 'SpellbookState_BuildDiscardMsg'],
  ['SpellMenu_ScriptDoneShowStatus_Loop20', 'SpellbookState_EquipYesNoNav'],

  // State 6: wait for script then draw cast magic list
  ['SpellMenu_ScriptDoneShowStatus_Loop4', 'SpellbookState_WaitThenDrawCastList'],
  ['SpellMenu_ScriptDoneShowStatus_Loop31', 'SpellbookState_DrawCastList_ScriptWait'],

  // State 7: B=cancel, C=cast
  ['SpellMenu_ScriptDoneShowStatus_Loop5', 'SpellbookState_CastMagicSelect'],
  ['SpellMenu_ScriptDoneShowStatus_Loop32', 'SpellbookState_CastMagicSelect_CheckC'],
  ['SpellMenu_ScriptDoneShowStatus_Loop33', 'SpellbookState_CastMagicSelect_Nav'],

  // State 8: wait for script, increment state
  ['SpellMenu_ScriptDoneShowStatus_Loop6', 'SpellbookState_ScriptWaitThenAdvance'],
  ['SpellMenu_ScriptDoneShowStatus_Loop34', 'SpellbookState_ScriptWaitThenAdvance_Process'],

  // State 9: wait for script, show HP/MP in first-person
  ['SpellMenu_ScriptDoneShowStatus_Loop7', 'SpellbookState_ScriptWaitShowHpMp'],

  // State 8 sub-labels for showing HP/MP after casting
  ['SpellMenu_ScriptDoneShowStatus_Loop8', 'SpellbookState_ClearFirstPersonHud'],
  ['SpellMenu_ScriptDoneShowStatus_Loop15', 'SpellbookState_ClearHud_FirstPersonCheck'],
  ['SpellMenu_ScriptDoneShowStatus_Loop14', 'SpellbookState_ClearHud_Return'],

  // State 11: wait for script then draw discard list
  ['SpellMenu_ScriptDoneShowStatus_Loop9', 'SpellbookState_WaitThenDrawDiscardList'],
  ['SpellMenu_ScriptDoneShowStatus_Loop23', 'SpellbookState_DrawDiscardList_ScriptWait'],

  // State 12: B=cancel, C=select to discard
  ['SpellMenu_ScriptDoneShowStatus_Loop10', 'SpellbookState_DiscardSelect'],
  ['SpellMenu_ScriptDoneShowStatus_Loop24', 'SpellbookState_DiscardSelect_CheckC'],
  ['SpellMenu_ScriptDoneShowStatus_Loop25', 'SpellbookState_DiscardSelect_Nav'],

  // State 13: yes/no confirm discard
  ['SpellMenu_ScriptDoneShowStatus_Loop11', 'SpellbookState_DiscardYesNoWait'],
  ['SpellMenu_ScriptDoneShowStatus_Loop26', 'SpellbookState_DiscardYesNoCancel'],
  ['SpellMenu_ScriptDoneShowStatus_Loop28', 'SpellbookState_DiscardConfirmed'],
  ['SpellMenu_ScriptDoneShowStatus_Loop29', 'SpellbookState_DiscardCantCombat'],
  ['SpellMenu_ScriptDoneShowStatus_Loop27', 'SpellbookState_DiscardYesNoNav'],

  // State 14: wait for Luminos cave light fade
  ['SpellMenu_ScriptDoneShowStatus_Loop12', 'SpellbookState_LuminosFadeWait'],
  ['SpellMenu_ScriptDoneShowStatus_Loop30', 'SpellbookState_LuminosFadeWait_Return'],

  // State 3/wait16 - process script text
  ['SpellMenu_ScriptDoneShowStatus_Loop16', 'SpellbookState_DrawEquipList_ScriptWait'],

  // State 13 script text (loop 13)
  ['SpellMenu_ScriptDoneShowStatus_Loop13', 'SpellbookState_Dismiss_ScriptProcess'],

  // ClearEndingTextArea
  ['ClearEndingTextArea_Done3', 'ClearEndingTextArea_DrawRowLoop'],
  ['ClearEndingTextArea_Done4', 'ClearEndingTextArea_DrawTileLoop'],
  ['ClearEndingTextArea_Done5', 'ClearEndingTextArea_ClearRowLoop'],
  ['ClearEndingTextArea_Done6', 'ClearEndingTextArea_ClearTileLoop'],
  ['ClearEndingTextArea_Done', 'ClearEndingTextArea_OuterLoop'],
  ['ClearEndingTextArea_InnerLoop', 'ClearEndingTextArea_FillLoop'],

  // InitEndingCreditsScreen
  ['InitEndingCreditsScreen_Done3', 'InitEndingCreditsScreen_RowLoop2'],
  ['InitEndingCreditsScreen_Done4', 'InitEndingCreditsScreen_TileLoop2'],
  ['InitEndingCreditsScreen_Done5', 'InitEndingCreditsScreen_RowLoop3'],
  ['InitEndingCreditsScreen_Done6', 'InitEndingCreditsScreen_TileLoop3'],
  ['InitEndingCreditsScreen_Done', 'InitEndingCreditsScreen_RowLoop1'],
  ['InitEndingCreditsScreen_InnerLoop', 'InitEndingCreditsScreen_TileLoop1'],

  // ClearDialogSprites
  ['ClearDialogSprites_Done', 'ClearDialogSprites_Loop'],

  // CheckAnyMagicReady
  ['CheckAnyMagicReady_Done', 'CheckAnyMagicReady_Loop'],
  ['CheckAnyMagicReady_Loop', 'CheckAnyMagicReady_Next'],

  // ClearMagicReadyFlags
  ['ClearMagicReadyFlags_Done', 'ClearMagicReadyFlags_Loop'],

  // CastSanguia
  ['CastSanguia_Loop', 'CastSanguia_ClampToMax'],

  // CastToxios
  ['CastToxios_Loop', 'CastToxios_CheckGreatPoison'],

  // CastExtrios
  ['CastExtrios_Loop', 'CastExtrios_CantUseHere'],

  // UpdateEndingCursorBlink
  ['UpdateEndingCursorBlink_Loop', 'UpdateEndingCursorBlink_Return'],

  // DrawCreditsStaffNames
  ['DrawCreditsStaffNames_Done', 'DrawCreditsStaffNames_SpriteGroupLoop'],

  // FillDialogAreaWithPattern
  ['FillDialogAreaWithPattern_Done', 'FillDialogAreaWithPattern_RowLoop'],
  ['FillDialogAreaWithPattern_InnerLoop', 'FillDialogAreaWithPattern_TileLoop'],

  // DrawEndingBorderPattern
  ['DrawEndingBorderPattern_Done', 'DrawEndingBorderPattern_RowLoop'],
  ['DrawEndingBorderPattern_InnerLoop', 'DrawEndingBorderPattern_TileLoop'],
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

fs.writeFileSync('E:/Romhacking/vermilion/src/magic.asm', src);
console.log('Done. ' + changed + ' labels renamed.');
