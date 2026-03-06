// DOC-006: Rename _LoopN/_DoneN sub-labels in gameplay.asm
'use strict';
const fs = require('fs');
const path = require('path');
const FILE = path.join(__dirname, '..', 'src', 'gameplay.asm');

// Map from old label -> new label
// Process in descending suffix order where needed to avoid prefix collisions
const RENAMES = [
  // GameState_LoadTown
  // Loop2: skip Carthahena index -- adjusting index for visited array
  // Loop3: skip Keltwick index
  // Loop4: skip town intro music
  ['GameState_LoadTown_Loop2', 'GameState_LoadTown_SkipCarthahenaIdx'],
  ['GameState_LoadTown_Loop3', 'GameState_LoadTown_SkipKelwickIdx'],
  ['GameState_LoadTown_Loop4', 'GameState_LoadTown_SkipMusicLoad'],

  // GameState_InitTownEntry_NormalPalette_Loop2: fall-through after choosing palette -> start fade in
  ['GameState_InitTownEntry_NormalPalette_Loop2', 'GameState_InitTownEntry_StartFadeIn'],

  // GameState_TownExploration
  // Loop2: no boss trigger, check tile type
  // Loop3: on castle tile -> play sounds + fade
  // Loop4: on exit tile -> fade to overworld
  // Loop5: on entrance tile -> fade into building
  // Loop6: common exit -- save player position after any transition
  ['GameState_TownExploration_Loop6', 'GameState_TownExploration_SavePosition'],
  ['GameState_TownExploration_Loop5', 'GameState_TownExploration_EnterBuilding'],
  ['GameState_TownExploration_Loop4', 'GameState_TownExploration_ExitToOverworld'],
  ['GameState_TownExploration_Loop3', 'GameState_TownExploration_EnterCastle'],
  ['GameState_TownExploration_Loop2', 'GameState_TownExploration_CheckTile'],

  // GameState_InitBuildingEntry_Loop2: spawn position set (first entry check bypassed)
  ['GameState_InitBuildingEntry_Loop2', 'GameState_InitBuildingEntry_SetSpawn'],

  // GameState_BuildingInterior_NoBossEvent
  // Loop2: no boss trigger -> check tile type
  // Loop3: on exit tile -> return to town
  // Loop4: on entrance tile -> go to next floor
  // Loop5: awakening flag set: handle inn wakeup (careless/arise branch)
  ['GameState_BuildingInterior_NoBossEvent_Loop5', 'GameState_BuildingInterior_CheckBanshee'],
  ['GameState_BuildingInterior_NoBossEvent_Loop4', 'GameState_BuildingInterior_GoToNextFloor'],
  ['GameState_BuildingInterior_NoBossEvent_Loop3', 'GameState_BuildingInterior_ExitToTown'],
  ['GameState_BuildingInterior_NoBossEvent_Loop2', 'GameState_BuildingInterior_CheckTile'],

  // GameState_ReadAwakening_Dismiss
  // Loop2: has continuation -> check C to advance page
  // Loop3: C not pressed -> just return (wait)
  ['GameState_ReadAwakening_Dismiss_Loop3', 'GameState_ReadAwakening_WaitPageTurn'],
  ['GameState_ReadAwakening_Dismiss_Loop2', 'GameState_ReadAwakening_CheckPageTurn'],

  // GameState_FryingPanDelay_Return
  // Loop2: equipped sword -> apply str bonus
  // Loop3: equipped shield -> apply ac bonus  
  // Loop4: equipped armor -> apply ac bonus (additive)
  ['GameState_FryingPanDelay_Return_Loop4', 'GameState_FryingPanDelay_ApplyArmorBonus'],
  ['GameState_FryingPanDelay_Return_Loop3', 'GameState_FryingPanDelay_ApplyShieldBonus'],
  ['GameState_FryingPanDelay_Return_Loop2', 'GameState_FryingPanDelay_ApplySwordBonus'],

  // GameState_ReadFryingPan_Dismiss
  // Loop2: has continuation -> check C to advance page
  // Loop3: C not pressed -> just return (wait)
  ['GameState_ReadFryingPan_Dismiss_Loop3', 'GameState_ReadFryingPan_WaitPageTurn'],
  ['GameState_ReadFryingPan_Dismiss_Loop2', 'GameState_ReadFryingPan_CheckPageTurn'],

  // GameState_SecondFloorActive_Loop2: on entrance -> go to third floor
  ['GameState_SecondFloorActive_Loop2', 'GameState_SecondFloorActive_GoToThirdFloor'],

  // GameState_TransitionToCastleMain_Loop2: spawn set (first entry check bypassed)
  ['GameState_TransitionToCastleMain_Loop2', 'GameState_TransitionToCastleMain_SetSpawn'],

  // GameState_CastleRoom1Active
  // Loop2: on exit tile -> return to town
  // Loop3: on entrance tile -> go to room 2
  ['GameState_CastleRoom1Active_Loop3', 'GameState_CastleRoom1Active_GoToRoom2'],
  ['GameState_CastleRoom1Active_Loop2', 'GameState_CastleRoom1Active_ExitToTown'],

  // GameState_CastleRoom2Active_Loop2: on entrance -> go to room 3
  ['GameState_CastleRoom2Active_Loop2', 'GameState_CastleRoom2Active_GoToRoom3'],

  // GameState_BattleInitialize_Loop2: magic loaded -> display HP
  ['GameState_BattleInitialize_Loop2', 'GameState_BattleInitialize_DisplayHud'],

  // GameState_BattleActive_Loop2: bully flag already set -> play death sound anyway
  ['GameState_BattleActive_Loop2', 'GameState_BattleActive_TriggerDeath'],

  // GameState_BattleExit
  // Loop2: bully flag -> play death sound
  // Loop3: soldier event -> handle soldier route
  // Loop4: in cave -> reload cave
  // Loop5: common exit after setting cave/overworld reload
  ['GameState_BattleExit_Loop5', 'GameState_BattleExit_ClearEntities'],
  ['GameState_BattleExit_Loop4', 'GameState_BattleExit_ReloadCave'],
  ['GameState_BattleExit_Loop3', 'GameState_BattleExit_CheckCaveReload'],
  ['GameState_BattleExit_Loop2', 'GameState_BattleExit_TriggerDeath'],

  // GameState_EnteringCave_Loop2: cave light active -> apply lit palette
  ['GameState_EnteringCave_Loop2', 'GameState_EnteringCave_ApplyLightPalette'],

  // GameState_LevelUpComplete_Check
  // Loop2: not in cave -> play overworld music
  // Loop3: common exit -> clear input block
  ['GameState_LevelUpComplete_Check_Loop3', 'GameState_LevelUpComplete_Check_ClearBlock'],
  ['GameState_LevelUpComplete_Check_Loop2', 'GameState_LevelUpComplete_Check_OverworldMusic'],

  // GameState_CaveExploration_CheckDeath
  // Loop2: no boss -> check movement
  // Loop3: not in cave -> check overworld
  // Loop4: common path after cave/overworld interaction check
  ['GameState_CaveExploration_CheckDeath_Loop4', 'GameState_CaveExploration_CheckReward'],
  ['GameState_CaveExploration_CheckDeath_Loop3', 'GameState_CaveExploration_CheckOverworld'],
  // Loop2 has existing comment "process movement actions in overworld" - rename to match
  ['GameState_CaveExploration_CheckDeath_Loop2', 'GameState_CaveExploration_CheckMovement'],

  // GameState_EncounterInitialize
  // Loop: in cave -> use cave encounter table
  // Loop2: common after table selection -> pick random variant
  ['GameState_EncounterInitialize_Loop2', 'GameState_EncounterInitialize_PickVariant'],

  // GameState_EncounterGraphicsFadeIn
  // Loop: PAL -> check every 4 frames
  // Loop2: frame interval elapsed -> check phase count
  // Loop3: not all phases done -> draw next column
  ['GameState_EncounterGraphicsFadeIn_Loop3', 'GameState_EncounterGraphicsFadeIn_DrawColumn'],
  ['GameState_EncounterGraphicsFadeIn_Loop2', 'GameState_EncounterGraphicsFadeIn_CheckPhase'],

  // GameState_LevelUpComplete_Exit
  // Loop2: not in cave -> play overworld music
  ['GameState_LevelUpComplete_Exit_Loop2', 'GameState_LevelUpComplete_OverworldMusic'],

  // GameState_ReturnToFirstPersonView_Loop2: cave light active -> apply lit palette
  ['GameState_ReturnToFirstPersonView_Loop2', 'GameState_ReturnToFirstPersonView_ApplyLightPalette'],

  // GameState_DialogDisplay
  // Loop: PAL -> check every 4 frames
  // Loop2: frame interval elapsed -> check phase count
  // Loop3: not done -> draw next column
  ['GameState_DialogDisplay_Loop3', 'GameState_DialogDisplay_DrawColumn'],
  ['GameState_DialogDisplay_Loop2', 'GameState_DialogDisplay_CheckPhase'],

  // GameState_BossBattleInit_Loop2 is actually a valid label for the main body, not a _LoopN suffix
  // However GameState_BossBattleInit_Loop2_Done is a DBF target label - keep _Done suffix pattern as-is
  // Actually rename Loop2 body -> FindActiveBoss; Loop2_Done -> FindActiveBoss_Next
  ['GameState_BossBattleInit_Loop2_Done', 'GameState_BossBattleInit_ClearFlagNext'],
  ['GameState_BossBattleInit_Loop2', 'GameState_BossBattleInit_FoundActiveBoss'],

  // GameState_ReturnFromBossBattle
  // Loop: check fade done
  // Loop2: waiting for fade
  // Loop3: in cave -> set first person mode
  // Loop4: common exit after in_cave branch
  ['GameState_ReturnFromBossBattle_Loop4', 'GameState_ReturnFromBossBattle_EnableDisplay'],
  ['GameState_ReturnFromBossBattle_Loop3', 'GameState_ReturnFromBossBattle_InCaveMode'],
  ['GameState_ReturnFromBossBattle_Loop2', 'GameState_ReturnFromBossBattle_WaitFade'],

  // GameState_ProcessResurrection
  // Loop2: resurrection entry -- already has comment "ressurected in church?"
  // Loop2_Done: DBF target for BCD halving loop
  // Loop3: skipped BCD halving (banshee active) -> init town
  // Loop4: high nibble is zero -> skip high nibble divide
  // Loop5: no carry from high digit -> no add 5
  // Loop6: low nibble is zero -> skip low nibble divide
  // Loop7: no carry from low digit -> no add 5
  ['GameState_ProcessResurrection_Loop7', 'GameState_ProcessResurrection_BcdLowNoCarry'],
  ['GameState_ProcessResurrection_Loop6', 'GameState_ProcessResurrection_BcdLowZero'],
  ['GameState_ProcessResurrection_Loop5', 'GameState_ProcessResurrection_BcdHighNoCarry'],
  ['GameState_ProcessResurrection_Loop4', 'GameState_ProcessResurrection_BcdHighZero'],
  ['GameState_ProcessResurrection_Loop2_Done', 'GameState_ProcessResurrection_BcdByteLoop'],
  ['GameState_ProcessResurrection_Loop3', 'GameState_ProcessResurrection_InitTown'],
  ['GameState_ProcessResurrection_Loop2', 'GameState_ProcessResurrection_HalveKims'],

  // GameState_WaitNotification_Dismiss_Loop2: script text not complete -> process text
  ['GameState_WaitNotification_Dismiss_Loop2', 'GameState_WaitNotification_ProcessText'],

  // OverworldMenuState0_Return_Loop2: message speed menu input handler
  // Loop3: options menu init handler
  // Loop4: waiting for window draw (return)
  // Loop5: C not pressed -> check C for confirm
  // Loop6: no direction input -> handle cursor
  ['OverworldMenuState0_Return_Loop6', 'OverworldMenuMsgSpeed_MoveCursor'],
  ['OverworldMenuState0_Return_Loop5', 'OverworldMenuMsgSpeed_CheckConfirm'],
  ['OverworldMenuState0_Return_Loop4', 'OverworldMenuMsgSpeed_WaitDraw'],
  ['OverworldMenuState0_Return_Loop3', 'OverworldMenuOptions_Init'],
  ['OverworldMenuState0_Return_Loop2', 'OverworldMenuMsgSpeed_HandleInput'],

  // InitMenuCursorDefaults
  // Loop2: execute selected menu action
  // Loop3: waiting for window draw (return)
  // Loop4: B not pressed -> check C
  // Loop5: C not pressed -> handle cursor
  ['InitMenuCursorDefaults_Loop5', 'InitMenuCursorDefaults_MoveCursor'],
  ['InitMenuCursorDefaults_Loop4', 'InitMenuCursorDefaults_CheckConfirm'],
  ['InitMenuCursorDefaults_Loop3', 'InitMenuCursorDefaults_WaitDraw'],
  ['InitMenuCursorDefaults_Loop2', 'InitMenuCursorDefaults_ExecuteAction'],

  // DecrementTimerBCD_Loop2: timer expired -> return 0
  ['DecrementTimerBCD_Loop2', 'DecrementTimerBCD_Expired'],

  // LoadAndPlayAreaMusic
  // LookupRoom_Loop2: room $B (Swaffham) -> check ruined
  // LookupRoom_Loop3: Stow innocence proven -> play innocence music
  ['LoadAndPlayAreaMusic_LookupRoom_Loop3', 'LoadAndPlayAreaMusic_StowInnocenceMusic'],
  ['LoadAndPlayAreaMusic_LookupRoom_Loop2', 'LoadAndPlayAreaMusic_CheckSwaffham'],
];

let content = fs.readFileSync(FILE, 'utf8');

// Apply renames highest-to-lowest (already ordered above for each group)
// Use whole-word regex to avoid partial matches
for (const [oldName, newName] of RENAMES) {
  const regex = new RegExp(`\\b${oldName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`, 'g');
  const before = content;
  content = content.replace(regex, newName);
  const count = (before.match(regex) || []).length;
  if (count === 0) {
    console.warn(`WARNING: '${oldName}' not found!`);
  } else {
    console.log(`Renamed ${count} occurrence(s): ${oldName} -> ${newName}`);
  }
}

fs.writeFileSync(FILE, content, 'utf8');
console.log('Done.');
