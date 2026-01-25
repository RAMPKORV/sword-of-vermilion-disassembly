const fs = require('fs');

// Read the file
let content = fs.readFileSync('vermilion.asm', 'utf8');

// Define all renames
const renames = [
  ['loc_000018f2', 'GameState_InitTownEntry'],
  ['loc_00001958', 'GameState_LoadTown'],
  ['loc_00001aa0', 'GameState_TownExploration'],
  ['loc_00001bb8', 'GameState_InitBuildingEntry'],
  ['loc_00001c1c', 'GameState_BuildingInterior'],
  ['loc_00001f00', 'GameState_TransitionToSecondFloor'],
  ['loc_00001f42', 'GameState_SecondFloorActive'],
  ['loc_00001fe0', 'GameState_TransitionToThirdFloor'],
  ['loc_00002074', 'GameState_ThirdFloorActive'],
  ['loc_000020b2', 'GameState_TransitionToCastleMain'],
  ['loc_00002116', 'GameState_CastleRoom1Active'],
  ['loc_000021da', 'GameState_LoadCastleRoom2'],
  ['loc_0000221c', 'GameState_CastleRoom2Active'],
  ['loc_000022a6', 'GameState_LoadCastleRoom3'],
  ['loc_000022e8', 'GameState_CaveEntrance'],
  ['loc_00002324', 'GameState_BattleInitialize'],
  ['loc_00002412', 'GameState_BattleActive'],
  ['loc_0000244a', 'GameState_BattleExit'],
  ['loc_00002542', 'GameState_OverworldReload'],
  ['loc_000025ae', 'GameState_OverworldActive'],
  ['loc_000025b2', 'GameState_TownFadeInComplete'],
  ['loc_000025ce', 'GameState_EnteringCave'],
  ['loc_0000273e', 'GameState_CaveExploration'],
  ['loc_00002814', 'GameState_CaveFadeOutComplete'],
  ['loc_00002832', 'GameState_EncounterInitialize'],
  ['loc_000028c2', 'GameState_EncounterGraphicsFadeIn'],
  ['loc_000028fc', 'GameState_EncounterPauseBeforeBattle'],
  ['loc_00002916', 'GameState_LevelUpBannerDisplay'],
  ['loc_00002930', 'GameState_LevelUpStatsWaitInput'],
  ['loc_00002974', 'GameState_LevelUpComplete'],
  ['loc_000029fa', 'GameState_ReturnToFirstPersonView'],
  ['loc_00001a92', 'GameState_FadeInComplete'],
  ['loc_00002a52', 'GameState_DialogDisplay'],
  ['loc_00002a92', 'GameState_BossBattleInit'],
  ['loc_00002bb8', 'GameState_BossBattleActive'],
  ['loc_00002bc4', 'GameState_ReturnFromBossBattle'],
  ['loc_00002c6a', 'GameState_BeginResurrection'],
  ['loc_00002c7c', 'GameState_ProcessResurrection'],
  ['loc_00002d22', 'GameState_NotifyInaudiosExpired'],
  ['loc_00002d6c', 'GameState_WaitForNotificationDismiss'],
  ['loc_00001d58', 'GameState_ReadAwakeningMessage'],
  ['loc_00001db4', 'GameState_FryingPanDelay'],
  ['loc_00001e9c', 'GameState_ReadFryingPanMessage'],
  ['loc_000024d6', 'GameState_SoldierTaunt'],
  ['loc_000024f8', 'GameState_ReadSoldierTaunt'],
  ['loc_00002d44', 'GameState_ShowPoisonNotification']
];

let labelCount = 0;
let totalReplacements = 0;

// Apply all renames
for (const [oldLabel, newName] of renames) {
  // Replace label definition (add comment with old name) - case insensitive
  const labelDefRegex = new RegExp('^' + oldLabel + ':', 'gmi');
  const labelDefMatch = content.match(labelDefRegex);
  if (labelDefMatch) {
    content = content.replace(labelDefRegex, ';' + oldLabel + ':\n' + newName + ':');
    labelCount++;
  }
  
  // Replace all references to the label - case insensitive  
  const labelRefRegex = new RegExp('\\b' + oldLabel + '\\b', 'gi');
  const matches = content.match(labelRefRegex);
  if (matches) {
    const matchCount = matches.length;
    content = content.replace(labelRefRegex, newName);
    totalReplacements += matchCount;
    console.log(`${oldLabel} -> ${newName}: ${matchCount} replacements`);
  }
}

// Write back
fs.writeFileSync('vermilion.asm', content);

console.log(`\nRenamed ${labelCount} functions with ${totalReplacements} total replacements`);
