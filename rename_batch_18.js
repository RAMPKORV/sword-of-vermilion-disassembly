const fs = require('fs');

// Read the file
let content = fs.readFileSync('vermilion.asm', 'utf8');

// Read rename mapping
const renameMap = [
  ['loc_00093436', 'WriteYM2612Register_Part1'],
  ['loc_00002F9C', 'FlushDialogTileBuffer'],
  ['loc_00002F54', 'UpdateDialogTileColumn'],
  ['loc_000026BA', 'CheckLevelUpAndRestoreMusic'],
  ['loc_00002620', 'InitBattleDisplay'],
  ['loc_00001B9A', 'SavePlayerTownPosition'],
  ['loc_000937F0', 'ApplyChannelPitchSlide'],
  ['loc_00093640', 'ProcessFMChannelPitchBend'],
  ['loc_000935A2', 'ProcessSoundScriptNote'],
  ['loc_00093372', 'UpdateFM_TotalLevelRegisters'],
  ['loc_0009332A', 'WriteFM_ChannelRegisters'],
  ['loc_00093318', 'LoadFM_AlgorithmData'],
  ['loc_000932EE', 'MutePSG_AllChannels'],
  ['loc_000932A2', 'InitFM_ChannelsToSilence'],
  ['loc_0009320C', 'ProcessSound_FadeOut'],
  ['loc_000931C0', 'ProcessSound_TempoCounter'],
  ['loc_00092FE2', 'ProcessSound_CommandQueue'],
  ['loc_00092D74', 'LoadDAC_SampleToZ80'],
  ['loc_00092BAC', 'ApplyPSG_PitchModulation'],
  ['loc_00092B3E', 'ApplyPSG_PitchBend'],
  ['loc_00092AF8', 'LoadNextSoundNote_WithPitchSlide'],
  ['loc_00092A84', 'LoadNextSoundNote'],
  ['loc_00092A3C', 'SetSoundNoteAndDuration'],
  ['loc_00092918', 'ProcessFMSoundChannels'],
  ['loc_0001E5AC', 'BuildRewardItemMessage'],
  ['loc_0001E14E', 'CheckIfTileIsEmpty'],
  ['loc_0001DF34', 'CheckIfDoorIsLocked'],
  ['loc_0001DEE4', 'WriteChestAnimationToVRAM'],
  ['loc_0001D62A', 'ClearEquipmentCursedFlag'],
  ['loc_0001D58C', 'UnequipItemByID'],
  ['loc_0001CEF8', 'FormatShopItemPrice'],
  ['loc_0001CE80', 'CheckPlayerTalkToNPC'],
  ['loc_0001A1A2', 'FindTargetEnemyForHoming'],
  ['loc_00019F54', 'ApplyScreenShakeToEnemies'],
  ['loc_00019E20', 'SetPositionFromActiveEnemy'],
  ['loc_00019384', 'FindActiveEnemyPosition'],
  ['loc_00018F5A', 'UpdateProjectileFollowPlayer'],
  ['loc_00018C6E', 'UpdateHomingProjectile'],
  ['loc_00018680', 'ClearMagicReadyFlags'],
  ['loc_00018662', 'CheckAnyMagicReady'],
  ['loc_000176F8', 'UpdateEndingCursorBlink'],
  ['loc_000176BC', 'ClearDialogSprites'],
  ['loc_0001765A', 'DrawEndingBorderPattern'],
  ['loc_0001760A', 'DrawCreditsStaffNames'],
  ['loc_0001756A', 'InitEndingCreditsScreen'],
  ['loc_0001749A', 'ClearEndingTextArea'],
  ['loc_000173E4', 'DisplayEndingTextLine'],
  ['loc_00016F3C', 'DrawPressStartText'],
  ['loc_00016E86', 'SpawnMenuCursorSprites'],
  ['loc_00016DCE', 'SpawnIntroSwordSprite'],
  ['loc_00016D94', 'DrawTilemapToVRAM_PlaneA'],
  ['loc_00016CD2', 'DrawIntroGraphics'],
  ['loc_00016C92', 'DrawIntroBackground'],
  ['loc_00016C30', 'UpdatePrologueScrollVRAM'],
  ['loc_0001684E', 'DecompressTilemaps_PlaneB'],
  ['loc_00016830', 'DecompressTilemaps_PlaneA'],
  ['loc_0001677C', 'UpdatePaletteCycle'],
  ['loc_000164EE', 'DrawTownColumn_Right'],
  ['loc_0001644E', 'DrawTownRow_Bottom'],
  ['loc_000163BA', 'DrawTownColumn_Left']
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
