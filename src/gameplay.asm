; ======================================================================
; src/gameplay.asm
; Gameplay state machine dispatcher for all in-game states.
;
; The main game loop calls the handler indexed by Gameplay_state each
; frame.  State IDs are defined in constants.asm as GAMEPLAY_STATE_*.
;
; State index:
;   $00  GameState_InitTownEntry          - Clear VRAM, load player gfx
;   $01  GameState_LoadTown               - Load tilemap, NPCs, music
;   $1F  GameState_FadeInComplete         - Wait for palette fade; restore state
;   $02  GameState_TownExploration        - Town walk, event dispatch
;   $03  GameState_InitBuildingEntry      - Enter building room
;   $04  GameState_BuildingInterior       - Building walk, inn/boss/event dispatch
;   $29  GameState_FryingPanDelay         - Woman hits player with frying pan
;   $2A  GameState_ReadFryingPanMessage   - Display frying-pan dialog
;   $28  GameState_ReadAwakeningMessage   - Inn wakeup dialog (set from $04)
;   $05  GameState_TransitionToSecondFloor - Load 2nd floor tilemap
;   $06  GameState_SecondFloorActive      - 2nd floor walk
;   $07  GameState_TransitionToThirdFloor - Load 3rd floor tilemap
;   $08  GameState_ThirdFloorActive       - 3rd floor walk
;   $09  GameState_TransitionToCastleMain - Load castle main room
;   $0A  GameState_CastleRoom1Active      - Castle room 1 walk
;   $0B  GameState_LoadCastleRoom2        - Load castle room 2
;   $0C  GameState_CastleRoom2Active      - Castle room 2 walk
;   $0D  GameState_LoadCastleRoom3        - Load castle room 3
;   $0E  GameState_CaveEntrance           - Enter cave from overworld
;   $0F  GameState_BattleInitialize       - Set up field battle
;   $10  GameState_BattleActive           - Field battle tick
;   $11  GameState_BattleExit             - Tear down field battle
;   $2B  GameState_SoldierTaunt           - Carthahenian soldier event setup
;   $2C  GameState_ReadSoldierTaunt       - Soldier taunt dialog
;   $12  GameState_OverworldReload        - Reload overworld after battle
;   $13  GameState_OverworldActive        - Alias: BRA GameState_CaveExploration
;   $14  GameState_TownFadeInComplete     - Fade done after town exit; re-enter town
;   $15  GameState_EnteringCave           - Load cave gfx and palettes
;   $16  GameState_CaveExploration        - First-person overworld/cave tick
;   $17  GameState_CaveFadeOutComplete    - Cave fade done; start encounter
;   $18  GameState_EncounterInitialize    - Choose enemy group, load portrait
;   $19  GameState_EncounterGraphicsFadeIn - Slide portrait in column by column
;   $1A  GameState_EncounterPauseBeforeBattle - Brief pause before battle starts
;   $1B  GameState_LevelUpBannerDisplay   - Show level-up banner for N frames
;   $1C  GameState_LevelUpStatsWaitInput  - Show new stats; wait for A/B/C
;   $1D  GameState_LevelUpComplete        - Check for another level; restore state
;   $1E  GameState_ReturnToFirstPersonView - Post-battle fade; restore cave view
;   $20  GameState_DialogDisplay          - NPC portrait slide-in animation
;   $21  GameState_BossBattleInit         - Scan boss flags, load boss objects
;   $22  GameState_BossBattleActive       - Boss battle per-frame tick
;   $23  GameState_ReturnFromBossBattle   - Post-boss cleanup, restore state
;   $24  GameState_BeginResurrection      - Player died: trigger fade-out
;   $25  GameState_ProcessResurrection    - Halve kims, warp to church
;   $26  GameState_NotifyInaudiosExpired  - Print Inaudios-worn-off message
;   $27  GameState_WaitForNotificationDismiss - Wait for B/C to dismiss popup
;   $2D  GameState_ShowPoisonNotification - First-time poison warning
; ======================================================================

; ======================================================================
; Town Entry State Handlers
; ======================================================================

; --- GameState_InitTownEntry ($00) ---
; First half of the two-state town-load sequence.  Waits for any active
; fade to clear, then disables the VDP display and resets all objects and
; VRAM so the town loader ($01) can start clean.
; Increments Gameplay_state to $01 on completion.
GameState_InitTownEntry:
	TST.b	Fade_out_lines_mask.w
	BNE.w	GameState_InitTownEntry_Loop
	JSR	DisableVDPDisplay
	BSR.w	ClearAllEnemyEntities
	JSR	InitMenuObjects
	CLR.b	Player_in_first_person_mode.w
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.l	#PlayerObjectHandler, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BCLR.b	#7, (A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BCLR.b	#7, (A6)
	JSR	LoadPlayerOverworldGraphics
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	JSR	ClearScrollData
	ADDQ.w	#1, Gameplay_state.w
	CLR.w	Town_spawn_x.w
GameState_InitTownEntry_Loop:
	RTS

; --- GameState_LoadTown ($01) ---
; Second half of town-load sequence.  Waits for fade, disables display, then:
;   - Loads town tileset, graphics, and tilemaps
;   - Marks town as visited in Towns_visited array
;   - Sets spawn coordinates from TownSpawnPositionTable
;   - Loads town NPCs and area music
;   - Sets Carthahena dark palette if Tsarkon is alive
;   - Starts fade-in to state $1F, with Saved_game_state = $02
; Special cases: Carthahena ($0C) and Keltwick ($06) are skipped in the
; Towns_visited index because they share indices with other towns.
GameState_LoadTown:
	TST.b	Fade_out_lines_mask.w
	BNE.w	GameState_InitTownEntry_NormalPalette_Loop
	JSR	DisableVDPDisplay
	MOVE.w	#ENCOUNTER_RATE_TOWN, Encounter_rate.w
	JSR	LoadTownTileGraphics
	JSR	LoadTownGraphics
	TST.w	Town_spawn_x.w
	BGT.w	GameState_LoadTown_Loop
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_CARTHAHENA, D0
	BLT.b	GameState_LoadTown_SkipCarthahenaIdx
	SUBQ.w	#1, D0
GameState_LoadTown_SkipCarthahenaIdx:
	CMPI.w	#TOWN_KELTWICK, D0
	BLT.b	GameState_LoadTown_SkipKelwickIdx
	SUBQ.w	#1, D0
GameState_LoadTown_SkipKelwickIdx:
	LEA	Towns_visited.w, A0
	MOVE.b	#$FF, (A0,D0.w)
	MOVE.w	Current_town.w, D0
	ASL.w	#3, D0
	LEA	TownSpawnPositionTable, A0
	LEA	(A0,D0.w), A0
	MOVE.w	(A0)+, Town_spawn_x.w
	MOVE.w	(A0)+, Player_spawn_tile_y_buffer.w
	MOVE.w	(A0)+, Town_camera_initial_x.w
	MOVE.w	(A0), Town_default_camera_y.w
GameState_LoadTown_Loop:
	MOVE.w	Town_spawn_x.w, Player_spawn_position_x.w
	MOVE.w	Player_spawn_tile_y_buffer.w, Player_spawn_tile_y.w
	MOVE.w	Town_camera_initial_x.w, Town_camera_spawn_x.w
	MOVE.w	Town_default_camera_y.w, Town_camera_target_tile_y.w
	MOVE.w	Current_town.w, D0
	MOVE.w	D0, Current_town_room.w
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	TownTilesetLoadJumpTable, A0
	LEA	TownNpcSetupJumpTable, A1
	JSR	(A1,D0.w)
	JSR	(A0,D0.w)
	JSR	LoadTownTilemaps
	MOVE.w	#TOWN_SPRITE_TILE_BASE, Town_vram_tile_base.w
	MOVE.w	#TOWN_TILEMAP_VRAM_BASE_TOWN, Town_tilemap_vram_base.w
	JSR	WriteTownTilemapToVRAM
	TST.b	Skip_town_intro_after_fight.w
	BNE.b	GameState_LoadTown_SkipMusicLoad
	JSR	LoadAndPlayAreaMusic
GameState_LoadTown_SkipMusicLoad:
	CLR.b	Skip_town_intro_after_fight.w
	MOVEA.l	Enemy_list_ptr.w, A6
	BSET.b	#7, (A6)
	MOVE.l	#LoadTownNPCs, obj_tick_fn(A6)
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_CARTHAHENA, D0
	BNE.b	GameState_InitTownEntry_NormalPalette
	TST.b	Tsarkon_is_dead.w
	BNE.b	GameState_InitTownEntry_NormalPalette
	MOVE.w	#PALETTE_IDX_TOWN_DARK, Palette_line_0_fade_target.w
	BRA.b	GameState_InitTownEntry_StartFadeIn
GameState_InitTownEntry_NormalPalette:
	MOVE.w	#PALETTE_IDX_TOWN_TILES, Palette_line_0_fade_target.w
GameState_InitTownEntry_StartFadeIn:
	MOVE.w	Palette_line_1_index_saved.w, Palette_line_1_fade_target.w
	MOVE.w	Palette_line_2_cycle_base.w, Palette_line_2_fade_target.w
	MOVE.w	#PALETTE_IDX_TOWN_HUD, Palette_line_3_fade_target.w
	MOVE.w	#GAMEPLAY_STATE_TOWN_EXPLORATION, Saved_game_state.w
	MOVE.w	#GAMEPLAY_STATE_FADE_IN_COMPLETE, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Fade_in_lines_mask.w
	CLR.w	Overworld_menu_state.w
	CLR.w	Saved_player_x_in_town.w
	JSR	EnableDisplay
	CLR.w	Town_camera_move_state.w
	CLR.b	Camera_scrolling_active.w
	MOVE.b	#PLAYER_MOVE_STEPS, Player_movement_step_counter.w
	CLR.b	Is_in_battle.w
GameState_InitTownEntry_NormalPalette_Loop:
	RTS

; --- GameState_FadeInComplete ($1F) ---
; Generic fade-in wait state.  Spins until Fade_in_lines_mask clears, then
; restores the gameplay state saved in Saved_game_state.
GameState_FadeInComplete:
	TST.b	Fade_in_lines_mask.w
	BNE.b	GameState_FadeInComplete_Loop
	MOVE.w	Saved_game_state.w, Gameplay_state.w
GameState_FadeInComplete_Loop:
	RTS

; ======================================================================
; Town / Building Walk State Handlers ($02-$08)
; ======================================================================

; --- GameState_TownExploration ($02) ---
; Main per-frame handler while walking in town.  Checks for Carthahenian
; soldier fight trigger, boss event trigger, then reads the tile type under
; the player to dispatch transitions (castle, exit, building entrance).
; Falls through to HandleOverworldMenuInput if no transition is needed.
GameState_TownExploration:
	TST.b	Soldier_fight_event_trigger.w
	BEQ.b	GameState_TownExploration_Loop
	MOVE.w	Gameplay_state.w, Saved_game_state.w
	BSR.w	SavePlayerTownPosition
	MOVE.w	#GAMEPLAY_STATE_BATTLE_INITIALIZE, Gameplay_state.w
	MOVE.w	#$54, Current_encounter_type.w ; Carthahenian soldiers
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	CLR.b	Player_input_blocked.w
	RTS

GameState_TownExploration_Loop:
	TST.b	Boss_event_trigger.w
	BEQ.b	GameState_TownExploration_CheckTile
	MOVE.w	Gameplay_state.w, Saved_game_state.w	
	BSR.w	SavePlayerTownPosition	
	MOVE.w	#GAMEPLAY_STATE_BOSS_BATTLE_INIT, Gameplay_state.w	
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w	
	RTS
	
GameState_TownExploration_CheckTile:
	BSR.w	GetCurrentTileType
	CMPI.w	#TILE_TYPE_CASTLE, Current_tile_type.w
	BEQ.b	GameState_TownExploration_EnterCastle
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w
	BEQ.b	GameState_TownExploration_ExitToOverworld
	CMPI.w	#TILE_TYPE_ENTRANCE, Current_tile_type.w
	BEQ.w	GameState_TownExploration_EnterBuilding
	BRA.w	HandleOverworldMenuInput
GameState_TownExploration_EnterCastle:
	PlaySound_b SOUND_TRANSITION
	PlaySound SOUND_LEVEL_UP
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.w	#GAMEPLAY_STATE_TRANSITION_TO_CASTLE_MAIN, Gameplay_state.w
	BRA.w	GameState_TownExploration_SavePosition
GameState_TownExploration_ExitToOverworld:
	PlaySound_b SOUND_TRANSITION
	PlaySound SOUND_LEVEL_UP
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.w	#GAMEPLAY_STATE_OVERWORLD_RELOAD, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Player_is_moving.w
	RTS

GameState_TownExploration_EnterBuilding:
	PlaySound_b SOUND_TRANSITION
	PlaySound SOUND_LEVEL_UP
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	ADDQ.w	#1, Gameplay_state.w
GameState_TownExploration_SavePosition:
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), Town_spawn_x.w
	MOVE.w	obj_world_y(A6), D0
	ADDI.w	#$0010, D0
	MOVE.w	D0, Player_spawn_tile_y_buffer.w
	MOVE.w	Town_camera_tile_x.w, Town_camera_initial_x.w
	MOVE.w	Camera_scroll_y.w, D0
	ASR.w	#4, D0
	MOVE.w	D0, Town_default_camera_y.w
	RTS

; --- SavePlayerTownPosition ---
; Saves the player's current world position and camera tile offsets into
; the town spawn variables so re-entering town restores the same spot.
SavePlayerTownPosition:
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), Town_spawn_x.w
	MOVE.w	obj_world_y(A6), Player_spawn_tile_y_buffer.w
	MOVE.w	Town_camera_tile_x.w, Town_camera_initial_x.w
	MOVE.w	Town_camera_tile_y.w, Town_default_camera_y.w
	RTS

; --- GameState_InitBuildingEntry ($03) ---
; Loads building interior resources: HUD graphics, battle tile graphics,
; NPC data (via SearchTownNPCData if first entry), and area music.
; Sets Saved_game_state = $04 (BUILDING_INTERIOR) and calls InitTownDisplay.
GameState_InitBuildingEntry:
	TST.b	Fade_out_lines_mask.w
	BNE.b	GameState_InitBuildingEntry_Loop
	JSR	DisableVDPDisplay
	JSR	LoadBattleHudGraphics
	JSR	LoadTownBattleGraphics
	TST.w	Saved_player_x_in_town.w
	BGT.b	GameState_InitBuildingEntry_SetSpawn
	BSR.w	SearchTownNPCData
	MOVE.w	Saved_town_room_1.w, Current_town_room.w
	JSR	LoadAndPlayAreaMusic
GameState_InitBuildingEntry_SetSpawn:
	MOVE.w	Saved_player_x_in_town.w, Player_spawn_position_x.w
	MOVE.w	Town_player_spawn_y.w, Player_spawn_tile_y.w
	MOVE.w	Town_saved_camera_x.w, Town_camera_spawn_x.w
	MOVE.w	Saved_camera_tile_y_room1.w, Town_camera_target_tile_y.w
	MOVE.w	Saved_town_tileset_index.w, Town_tileset_index.w
	MOVE.w	Saved_town_room_1.w, Current_town_room.w
	MOVE.l	Saved_town_npc_data_ptr.w, Town_npc_data_ptr.w
	MOVE.w	#GAMEPLAY_STATE_BUILDING_INTERIOR, Saved_game_state.w
	BSR.w	InitTownDisplay
GameState_InitBuildingEntry_Loop:
	RTS

; --- GameState_BuildingInterior ($04) ---
; Per-frame handler for building interiors.  Checks for:
;   - Inn awakening (Helwig only): triggers frying-pan event
;   - Boss event trigger: saves position, transitions to boss battle
;   - Tile-type transitions: exit (back to town) or entrance (next floor)
; Falls through to HandleOverworldMenuInput otherwise.
GameState_BuildingInterior:
	TST.b	Player_awakening_flag.w
	BNE.w	GameState_BuildingInterior_NoBossEvent_Loop
	TST.b	Helwig_inn_wakeup_trigger.w
	BEQ.b	GameState_BuildingInterior_NoBossEvent
	CLR.b	Helwig_inn_wakeup_trigger.w
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_HELWIG, D0
	BNE.b	GameState_BuildingInterior_NoBossEvent
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.w	#SLEEP_DELAY_FRAMES, Sleep_delay_timer.w
	PlaySound_b SOUND_SLEEP
	MOVE.w	#GAMEPLAY_STATE_FRYING_PAN_DELAY, Gameplay_state.w
	RTS

GameState_BuildingInterior_NoBossEvent:
	TST.b	Boss_event_trigger.w
	BEQ.b	GameState_BuildingInterior_CheckTile
	MOVEA.l	Player_entity_ptr.w, A6	
	MOVE.w	obj_world_x(A6), Saved_player_x_in_town.w	
	MOVE.w	obj_world_y(A6), Town_player_spawn_y.w	
	MOVE.w	Town_camera_tile_x.w, Town_saved_camera_x.w	
	MOVE.w	Town_camera_tile_y.w, Saved_camera_tile_y_room1.w	
	MOVE.w	Gameplay_state.w, Saved_game_state.w	
	MOVE.w	#GAMEPLAY_STATE_BOSS_BATTLE_INIT, Gameplay_state.w	
	PlaySound SOUND_LEVEL_UP	
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w	
	RTS
	
GameState_BuildingInterior_CheckTile:
	BSR.w	GetCurrentTileType
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w
	BEQ.b	GameState_BuildingInterior_ExitToTown
	CMPI.w	#TILE_TYPE_ENTRANCE, Current_tile_type.w
	BEQ.b	GameState_BuildingInterior_GoToNextFloor
	BRA.w	HandleOverworldMenuInput
GameState_BuildingInterior_ExitToTown:
	PlaySound_b SOUND_TRANSITION
	PlaySound SOUND_LEVEL_UP
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.w	#GAMEPLAY_STATE_LOAD_TOWN, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Player_is_moving.w
	MOVE.w	#DIRECTION_DOWN, Player_direction.w
	RTS

GameState_BuildingInterior_GoToNextFloor:
	PlaySound_b SOUND_TRANSITION
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	ADDQ.w	#1, Gameplay_state.w
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), Saved_player_x_in_town.w
	MOVE.w	obj_world_y(A6), D0
	ADDI.w	#$0010, D0
	MOVE.w	D0, Town_player_spawn_y.w
	MOVE.w	Town_camera_tile_x.w, Town_saved_camera_x.w
	MOVE.w	Town_camera_tile_y.w, Saved_camera_tile_y_room1.w
	RTS

GameState_BuildingInterior_NoBossEvent_Loop:
	MOVE.b	#FLAG_TRUE, Player_input_blocked.w
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	PRINT 	AwakenVoiceStr
	TST.b	Frying_pan_knockout_flag.w
	BEQ.b	GameState_BuildingInterior_CheckBanshee
	PRINT 	CarelessWarningStr	
	CLR.b	Frying_pan_knockout_flag.w	
	BRA.b	GameState_AwakeningMessage_SetState	
GameState_BuildingInterior_CheckBanshee:
	TST.b	Banshee_powder_active.w
	BNE.b	GameState_AwakeningMessage_SetState
	PRINT 	AriseWarriorStr
GameState_AwakeningMessage_SetState:
	MOVE.w	#GAMEPLAY_STATE_READ_AWAKENING_MESSAGE, Gameplay_state.w
	RTS

; ======================================================================
; Inn Awakening / Frying Pan Event States ($28-$2A)
; ======================================================================

; --- GameState_ReadAwakeningMessage ($28) ---
; Displays the inn wakeup text.  Waits for the script to finish, then
; waits for B or C press to dismiss.  Handles multi-page continuation.
; On dismiss: clears awakening/banshee flags and returns to BUILDING_INTERIOR.
GameState_ReadAwakeningMessage:
	TST.b	Script_text_complete.w
	BEQ.b	GameState_ReadAwakening_Dismiss_Loop
	TST.b	Script_has_continuation.w
	BNE.b	GameState_ReadAwakening_CheckPageTurn
	CheckButton BUTTON_BIT_B
	BNE.b	GameState_ReadAwakening_Dismiss
	CheckButton BUTTON_BIT_C
	BNE.b	GameState_ReadAwakening_Dismiss
	RTS

GameState_ReadAwakening_Dismiss:
	JSR	DrawStatusHudWindow
	CLR.b	Player_input_blocked.w
	CLR.b	Player_awakening_flag.w
	CLR.b	Banshee_powder_active.w
	MOVE.w	#GAMEPLAY_STATE_BUILDING_INTERIOR, Gameplay_state.w
	RTS

GameState_ReadAwakening_Dismiss_Loop:
	JSR	ProcessScriptText
	RTS

GameState_ReadAwakening_CheckPageTurn:
	CheckButton BUTTON_BIT_C
	BEQ.b	GameState_ReadAwakening_WaitPageTurn
	JSR	InitDialogueWindow
GameState_ReadAwakening_WaitPageTurn:
	RTS

; --- GameState_FryingPanDelay ($29) ---
; Helwig inn special event: the woman hits the player with a frying pan.
; Waits for fade, counts down Sleep_delay_timer, then halves player HP.
; If HP reaches 0, triggers full stat reset (resets level/stats to 0,
; re-applies equipment bonuses, calls UpgradeLevelStats) and routes
; to resurrection.  Otherwise prints "afraid killed" and advances to
; READ_FRYING_PAN_MESSAGE.
;GameState_FryingPanDelay:
GameState_FryingPanDelay: ; Woman hitting player with frying pan
	TST.b	Fade_out_lines_mask.w
	BNE.b	GameState_FryingPanDelay_Return
	SUBQ.w	#1, Sleep_delay_timer.w
	BGE.b	GameState_FryingPanDelay_Return
	MOVE.w	Player_hp.w, D0
	LSR.w	#1, D0
	BLE.b	GameState_FryingPanDelay_Return_Loop
	MOVE.w	D0, Player_hp.w
	ADDQ.w	#1, Helwig_frypan_hit_count.w
	PRINT 	AfraidKilledStr
	MOVE.w	#GAMEPLAY_STATE_READ_FRYING_PAN_MESSAGE, Gameplay_state.w
	JSR	LoadAndPlayAreaMusic
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#PALETTE_IDX_TOWN_TILES, Palette_line_0_index.w
	MOVE.w	Palette_line_1_index_saved.w, Palette_line_1_index.w
	MOVE.w	Palette_line_2_cycle_base.w, Palette_line_2_index.w
	MOVE.w	#PALETTE_IDX_TOWN_HUD, Palette_line_3_index.w
	JSR	LoadPalettesFromTable
GameState_FryingPanDelay_Return:
	RTS

GameState_FryingPanDelay_Return_Loop:
	MOVE.b	#FLAG_TRUE, Frying_pan_knockout_flag.w	
	PlaySound SOUND_SPELL_CAST	
	MOVE.w	#GAMEPLAY_STATE_BEGIN_RESURRECTION, Gameplay_state.w	
	CLR.w	Player_level.w	
	CLR.w	Player_str.w	
	CLR.w	Player_luk.w	
	CLR.w	Player_dex.w	
	CLR.w	Player_ac.w	
	CLR.w	Player_int.w	
	CLR.w	Player_mmp.w	
	CLR.w	Player_mhp.w	
	CLR.l	Player_experience.w	
	MOVE.w	Equipped_sword.w, D1	
	BLT.w	GameState_FryingPanDelay_ApplySwordBonus	
	LEA	EquipmentToStatModifierMap, A0	
	ANDI.w	#$00FF, D1	
	ADD.w	D1, D1	
	MOVE.w	(A0,D1.w), Player_str.w	
GameState_FryingPanDelay_ApplySwordBonus:
	MOVE.w	Equipped_shield.w, D1	
	BLT.w	GameState_FryingPanDelay_ApplyShieldBonus	
	LEA	EquipmentToStatModifierMap, A0	
	ANDI.w	#$FF, D1	
	ADD.w	D1, D1	
	MOVE.w	(A0,D1.w), Player_ac.w	
GameState_FryingPanDelay_ApplyShieldBonus:
	MOVE.w	Equipped_armor.w, D1	
	BLT.w	GameState_FryingPanDelay_ApplyArmorBonus	
	LEA	EquipmentToStatModifierMap, A0	
	ANDI.w	#$FF, D1	
	ADD.w	D1, D1	
	MOVE.w	(A0,D1.w), D1	
	ADD.w	D1, Player_ac.w	
GameState_FryingPanDelay_ApplyArmorBonus:
	JSR	UpgradeLevelStats	
	RTS
	
; --- GameState_ReadFryingPanMessage ($2A) ---
; Displays the frying-pan dialog text.  Waits for B or C to dismiss,
; then redraws the status HUD and returns to BUILDING_INTERIOR.
GameState_ReadFryingPanMessage:
	TST.b	Script_text_complete.w
	BEQ.b	GameState_ReadFryingPan_Dismiss_Loop
	TST.b	Script_has_continuation.w
	BNE.w	GameState_ReadFryingPan_CheckPageTurn
	CheckButton BUTTON_BIT_B
	BNE.b	GameState_ReadFryingPan_Dismiss
	CheckButton BUTTON_BIT_C
	BNE.b	GameState_ReadFryingPan_Dismiss
	RTS

GameState_ReadFryingPan_Dismiss:
	JSR	DrawStatusHudWindow
	CLR.w	Overworld_menu_state.w
	TriggerWindowRedraw WINDOW_DRAW_MSG_SPEED_ALT
	MOVE.w	#GAMEPLAY_STATE_BUILDING_INTERIOR, Gameplay_state.w
	RTS

GameState_ReadFryingPan_CheckPageTurn:
	CheckButton BUTTON_BIT_C
	BEQ.b	GameState_ReadFryingPan_WaitPageTurn
	JSR	InitDialogueWindow
GameState_ReadFryingPan_Dismiss_Loop:
	JSR	ProcessScriptText
GameState_ReadFryingPan_WaitPageTurn:
	RTS

; ======================================================================
; Floor / Room Transition State Handlers ($05-$0E)
; ======================================================================

; --- GameState_TransitionToSecondFloor ($05) ---
; Loads the second floor tilemap for the current building.  Waits for
; fade, disables display, sets spawn position from saved room data,
; and calls InitTownDisplay with Saved_game_state = SECOND_FLOOR_ACTIVE.
GameState_TransitionToSecondFloor:
	TST.b	Fade_out_lines_mask.w
	BNE.b	GameState_TransitionToSecondFloor_Loop
	JSR	DisableVDPDisplay
	MOVE.w	Saved_player_spawn_x.w, Player_spawn_position_x.w
	MOVE.w	Saved_player_y_room1.w, Player_spawn_tile_y.w
	MOVE.w	#0, Town_camera_spawn_x.w
	MOVE.w	#0, Town_camera_target_tile_y.w
	MOVE.w	Saved_town_tileset_index.w, Town_tileset_index.w
	MOVE.w	Saved_town_room_2.w, Current_town_room.w
	MOVE.l	Saved_npc_data_ptr.w, Town_npc_data_ptr.w
	MOVE.w	#GAMEPLAY_STATE_SECOND_FLOOR_ACTIVE, Saved_game_state.w
	BSR.w	InitTownDisplay
GameState_TransitionToSecondFloor_Loop:
	RTS

; --- GameState_SecondFloorActive ($06) ---
; Per-frame handler for the second floor.  Checks tile type for exit
; (back to first floor via INIT_BUILDING_ENTRY) or entrance (to third
; floor).  Falls through to HandleOverworldMenuInput otherwise.
GameState_SecondFloorActive:
	BSR.w	GetCurrentTileType
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w
	BEQ.b	GameState_SecondFloorActive_Loop
	CMPI.w	#TILE_TYPE_ENTRANCE, Current_tile_type.w
	BEQ.w	GameState_SecondFloorActive_GoToThirdFloor
	BRA.w	HandleOverworldMenuInput
GameState_SecondFloorActive_Loop:
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	PlaySound_b SOUND_TRANSITION
	MOVE.w	#GAMEPLAY_STATE_INIT_BUILDING_ENTRY, Gameplay_state.w
	LEA	DirectionOffsets_16Pixel, A0
	MOVE.w	Player_direction.w, D0
	ADD.w	D0, D0
	LEA	(A0,D0.w), A0
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), D0
	ADD.w	(A0)+, D0
	MOVE.w	D0, Saved_player_spawn_x.w
	MOVE.w	obj_world_y(A6), D0
	ADD.w	(A0), D0
	MOVE.w	D0, Saved_player_y_room1.w
	MOVE.w	Town_camera_tile_x.w, Saved_camera_tile_x_unused.w
	MOVE.w	Town_camera_tile_y.w, Saved_camera_tile_y_unused.w
	MOVE.b	#FLAG_TRUE, Player_is_moving.w
	MOVE.w	#DIRECTION_DOWN, Player_direction.w
	RTS

GameState_SecondFloorActive_GoToThirdFloor:
	PlaySound_b SOUND_TRANSITION
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	ADDQ.w	#1, Gameplay_state.w
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), Saved_player_spawn_x.w
	MOVE.w	obj_world_y(A6), D0
	ADDI.w	#$0010, D0
	MOVE.w	D0, Saved_player_y_room1.w
	RTS

; --- GameState_TransitionToThirdFloor ($07) ---
; Loads the third floor tilemap.  Same pattern as TransitionToSecondFloor
; but uses room 3 saved data.  Saved_game_state = THIRD_FLOOR_ACTIVE.
GameState_TransitionToThirdFloor:
	TST.b	Fade_out_lines_mask.w
	BNE.b	GameState_TransitionToThirdFloor_Loop
	JSR	DisableVDPDisplay
	MOVE.w	Saved_player_spawn_x_room2.w, Player_spawn_position_x.w
	MOVE.w	Saved_player_spawn_y_room2.w, Player_spawn_tile_y.w
	MOVE.w	#0, Town_camera_spawn_x.w
	MOVE.w	#0, Town_camera_target_tile_y.w
	MOVE.w	Saved_town_tileset_index.w, Town_tileset_index.w
	MOVE.w	Saved_town_room_3.w, Current_town_room.w
	MOVE.l	Saved_npc_data_ptr_room3.w, Town_npc_data_ptr.w
	MOVE.w	#GAMEPLAY_STATE_THIRD_FLOOR_ACTIVE, Saved_game_state.w
	BSR.w	InitTownDisplay
GameState_TransitionToThirdFloor_Loop:
	RTS

; --- InitTownDisplay ---
; Shared subroutine for room/floor transitions.  Loads tilemaps, spawns
; NPCs, sets fade-in palette targets, and enables the display.  Used by
; floor transitions, castle room loads, and building entry.
InitTownDisplay:
	JSR	LoadTownTilemaps
	MOVE.w	#TOWN_TILEMAP_VRAM_BASE_ALT, Town_tilemap_vram_base.w
	JSR	WriteTownTilemapToVRAM
	MOVEA.l	Enemy_list_ptr.w, A6
	BSET.b	#7, (A6)
	MOVE.l	#LoadTownNPCs, obj_tick_fn(A6)
	MOVE.w	#PALETTE_IDX_TOWN_TILES, Palette_line_0_fade_target.w
	MOVE.w	Palette_line_1_index_saved.w, Palette_line_1_fade_target.w
	MOVE.w	Palette_line_2_cycle_base.w, Palette_line_2_fade_target.w
	MOVE.w	#PALETTE_IDX_TOWN_HUD, Palette_line_3_fade_target.w
	MOVE.w	#GAMEPLAY_STATE_FADE_IN_COMPLETE, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Fade_in_lines_mask.w
	CLR.w	Overworld_menu_state.w
	JSR	EnableDisplay
	RTS

; --- GameState_ThirdFloorActive ($08) ---
; Per-frame handler for the third floor.  Only checks for exit tile
; (back to second floor).  Falls through to HandleOverworldMenuInput.
GameState_ThirdFloorActive:
	BSR.w	GetCurrentTileType
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w
	BEQ.b	GameState_ThirdFloorActive_Loop
	BRA.w	HandleOverworldMenuInput
GameState_ThirdFloorActive_Loop:
	PlaySound_b SOUND_TRANSITION
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w
	BNE.w	HandleOverworldMenuInput
	MOVE.w	#GAMEPLAY_STATE_TRANSITION_TO_SECOND_FLOOR, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Player_is_moving.w
	MOVE.w	#DIRECTION_DOWN, Player_direction.w
	RTS

; --- GameState_TransitionToCastleMain ($09) ---
; Loads the castle main room.  Similar to InitBuildingEntry but loads
; world battle graphics instead of town battle graphics.  Uses
; LoadTownStateData if first entry.  Saved_game_state = CASTLE_ROOM1_ACTIVE.
GameState_TransitionToCastleMain:
	TST.b	Fade_out_lines_mask.w
	BNE.b	GameState_TransitionToCastleMain_Loop
	JSR	DisableVDPDisplay
	JSR	LoadBattleHudGraphics
	JSR	LoadWorldBattleGraphics
	TST.w	Saved_player_x_in_town.w
	BGT.b	GameState_TransitionToCastleMain_SetSpawn
	BSR.w	LoadTownStateData
	MOVE.w	Saved_town_room_1.w, Current_town_room.w
	JSR	LoadAndPlayAreaMusic
GameState_TransitionToCastleMain_SetSpawn:
	MOVE.w	Saved_player_x_in_town.w, Player_spawn_position_x.w
	MOVE.w	Town_player_spawn_y.w, Player_spawn_tile_y.w
	MOVE.w	Town_saved_camera_x.w, Town_camera_spawn_x.w
	MOVE.w	Saved_camera_tile_y_room1.w, Town_camera_target_tile_y.w
	MOVE.w	Saved_town_tileset_index.w, Town_tileset_index.w
	MOVE.w	Saved_town_room_1.w, Current_town_room.w
	MOVE.l	Saved_town_npc_data_ptr.w, Town_npc_data_ptr.w
	MOVE.w	#GAMEPLAY_STATE_CASTLE_ROOM1_ACTIVE, Saved_game_state.w
	BSR.w	InitTownDisplay
GameState_TransitionToCastleMain_Loop:
	RTS

; --- GameState_CastleRoom1Active ($0A) ---
; Per-frame handler for castle room 1.  Checks boss trigger (saves
; position and transitions to boss battle), exit tile (back to town),
; or entrance tile (to castle room 2).
GameState_CastleRoom1Active:
	TST.b	Boss_event_trigger.w
	BEQ.b	GameState_CastleRoom1Active_Loop
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), Saved_player_x_in_town.w
	MOVE.w	obj_world_y(A6), Town_player_spawn_y.w
	MOVE.w	Town_camera_tile_x.w, Town_saved_camera_x.w
	MOVE.w	Town_camera_tile_y.w, Saved_camera_tile_y_room1.w
	MOVE.w	Gameplay_state.w, Saved_game_state.w
	MOVE.w	#GAMEPLAY_STATE_BOSS_BATTLE_INIT, Gameplay_state.w
	PlaySound SOUND_LEVEL_UP
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	RTS

GameState_CastleRoom1Active_Loop:
	BSR.w	GetCurrentTileType
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w
	BEQ.b	GameState_CastleRoom1Active_ExitToTown
	CMPI.w	#TILE_TYPE_ENTRANCE, Current_tile_type.w
	BEQ.w	GameState_CastleRoom1Active_GoToRoom2
	BRA.w	HandleOverworldMenuInput
GameState_CastleRoom1Active_ExitToTown:
	PlaySound_b SOUND_TRANSITION
	PlaySound SOUND_LEVEL_UP
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.w	#GAMEPLAY_STATE_LOAD_TOWN, Gameplay_state.w
	CLR.w	Saved_player_x_in_town.w
	MOVE.b	#FLAG_TRUE, Player_is_moving.w
	MOVE.w	#DIRECTION_DOWN, Player_direction.w
	RTS

GameState_CastleRoom1Active_GoToRoom2:
	PlaySound_b SOUND_TRANSITION
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	ADDQ.w	#1, Gameplay_state.w
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), Saved_player_x_in_town.w
	MOVE.w	obj_world_y(A6), D0
	SUBI.w	#$0010, D0
	MOVE.w	D0, Town_player_spawn_y.w
	MOVE.w	Town_camera_tile_x.w, Town_saved_camera_x.w
	MOVE.w	Town_camera_tile_y.w, Saved_camera_tile_y_room1.w
	RTS

; --- GameState_LoadCastleRoom2 ($0B) ---
; Loads castle room 2 tilemap and NPCs.  Sets spawn from saved room 2
; data.  Saved_game_state = CASTLE_ROOM2_ACTIVE.
GameState_LoadCastleRoom2:
	TST.b	Fade_out_lines_mask.w
	BNE.b	GameState_LoadCastleRoom2_Loop
	JSR	DisableVDPDisplay
	MOVE.w	Saved_player_spawn_x.w, Player_spawn_position_x.w
	MOVE.w	Saved_player_y_room1.w, Player_spawn_tile_y.w
	MOVE.w	#0, Town_camera_spawn_x.w
	MOVE.w	#0, Town_camera_target_tile_y.w
	MOVE.w	Saved_town_tileset_index.w, Town_tileset_index.w
	MOVE.w	Saved_town_room_2.w, Current_town_room.w
	MOVE.l	Saved_npc_data_ptr.w, Town_npc_data_ptr.w
	MOVE.w	#GAMEPLAY_STATE_CASTLE_ROOM2_ACTIVE, Saved_game_state.w
	BSR.w	InitTownDisplay
GameState_LoadCastleRoom2_Loop:
	RTS

; --- GameState_CastleRoom2Active ($0C) ---
; Per-frame handler for castle room 2.  Exit tile returns to castle main,
; entrance tile advances to room 3.
GameState_CastleRoom2Active:
	BSR.w	GetCurrentTileType
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w
	BEQ.b	GameState_CastleRoom2Active_Loop
	CMPI.w	#TILE_TYPE_ENTRANCE, Current_tile_type.w
	BEQ.b	GameState_CastleRoom2Active_GoToRoom3
	BRA.w	HandleOverworldMenuInput
GameState_CastleRoom2Active_Loop:
	PlaySound_b SOUND_TRANSITION
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.w	#GAMEPLAY_STATE_TRANSITION_TO_CASTLE_MAIN, Gameplay_state.w
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), Saved_player_spawn_x.w
	MOVE.w	obj_world_y(A6), D0
	ADDI.w	#$0010, D0
	MOVE.w	D0, Saved_player_y_room1.w
	MOVE.w	Town_camera_tile_x.w, Saved_camera_tile_x_unused.w
	MOVE.w	Town_camera_tile_y.w, Saved_camera_tile_y_unused.w
	MOVE.b	#FLAG_TRUE, Player_is_moving.w
	MOVE.w	#DIRECTION_DOWN, Player_direction.w
	RTS

GameState_CastleRoom2Active_GoToRoom3:
	PlaySound_b SOUND_TRANSITION	
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w	
	ADDQ.w	#1, Gameplay_state.w	
	MOVEA.l	Player_entity_ptr.w, A6	
	MOVE.w	obj_world_x(A6), Saved_player_spawn_x.w	
	MOVE.w	obj_world_y(A6), D0	
	ADDI.w	#$0010, D0	
	MOVE.w	D0, Saved_player_y_room1.w	
	RTS
	
; --- GameState_LoadCastleRoom3 ($0D) ---
; Loads castle room 3 tilemap and NPCs.  Sets spawn from saved room 3
; data.  Saved_game_state = CAVE_ENTRANCE.
GameState_LoadCastleRoom3:
	TST.b	Fade_out_lines_mask.w	
	BNE.b	GameState_LoadCastleRoom3_Loop	
	JSR	DisableVDPDisplay	
	MOVE.w	Saved_player_spawn_x_room2.w, Player_spawn_position_x.w	
	MOVE.w	Saved_player_spawn_y_room2.w, Player_spawn_tile_y.w	
	MOVE.w	#0, Town_camera_spawn_x.w	
	MOVE.w	#0, Town_camera_target_tile_y.w	
	MOVE.w	Saved_town_tileset_index.w, Town_tileset_index.w	
	MOVE.w	Saved_town_room_3.w, Current_town_room.w	
	MOVE.l	Saved_npc_data_ptr_room3.w, Town_npc_data_ptr.w	
	MOVE.w	#GAMEPLAY_STATE_CAVE_ENTRANCE, Saved_game_state.w	
	BSR.w	InitTownDisplay	
GameState_LoadCastleRoom3_Loop:
	RTS
	
; --- GameState_CaveEntrance ($0E) ---
; Per-frame handler for the castle room leading to a cave.  Exit tile
; returns to castle room 2.  Falls through to HandleOverworldMenuInput
; otherwise.
GameState_CaveEntrance:
	BSR.w	GetCurrentTileType	
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w	
	BNE.w	HandleOverworldMenuInput	
	PlaySound_b SOUND_TRANSITION	
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w	
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w	
	BNE.w	HandleOverworldMenuInput	
	MOVE.w	#GAMEPLAY_STATE_LOAD_CASTLE_ROOM2, Gameplay_state.w	
	MOVE.b	#FLAG_TRUE, Player_is_moving.w	
	MOVE.w	#DIRECTION_DOWN, Player_direction.w	
	RTS
	
; ======================================================================
; Field Battle State Handlers ($0F-$11)
; ======================================================================

; --- GameState_BattleInitialize ($0F) ---
; Sets up a field battle: clears VRAM, loads battle tiles/terrain/graphics,
; draws the terrain tilemap and status bar, positions the player entity,
; initializes the encounter with enemy groups, loads magic graphics if
; readied, and enables the display with a battle start sound.
GameState_BattleInitialize:
	TST.b	Fade_out_lines_mask.w
	BNE.w	GameState_BattleInitialize_Loop
	JSR	DisableVDPDisplay
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	JSR	ClearScrollData
	MOVE.w	Player_direction.w, Saved_player_direction.w
	BSR.w	ClearAllEnemyEntities
	JSR	InitGameplayObjects
	CLR.w	Sprite_attr_count.w
	JSR	FlushSpriteAttributesToVDP
	CLR.b	Is_boss_battle.w
	CLR.b	Boss_max_hp.w
	CLR.b	Encounter_behavior_flag.w
	JSR	LoadBattleTileGraphics
	JSR	LoadBattleTerrainGraphics
	BSR.w	DrawTerrainTilemap
	BSR.w	DrawBattleStatusBar
	CLR.w	Camera_scroll_x.w
	CLR.w	Camera_scroll_y.w
	JSR	LoadBattleTilesToBuffers
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	#$00A0, obj_world_x(A6)
	MOVE.w	#$0064, obj_world_y(A6)
	MOVE.w	#PALETTE_IDX_CAVE_WALLS, Palette_line_0_index.w
	MOVE.w	#PALETTE_IDX_BATTLE_OUTDOOR, Palette_line_3_index.w
	ADDQ.w	#1, Gameplay_state.w
	CLR.w	Overworld_menu_state.w
	MOVE.b	#FLAG_TRUE, Is_in_battle.w
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.l	#InitBattlePlayerObject, obj_tick_fn(A6)
	MOVEQ	#0, D0
	MOVE.w	Player_dex.w, D0
	ASR.l	#3, D0
	ADDI.l	#$00000180, D0
	MOVE.l	D0, obj_pos_x_fixed(A6)
	JSR	InitializeEncounter
	MOVE.w	Readied_magic.w, D0
	BLT.b	GameState_BattleInitialize_DisplayHud
	ANDI.w	#$00FF, D0
	JSR	LoadMagicGraphics
GameState_BattleInitialize_DisplayHud:
	JSR	DisplayPlayerMaxHpMp
	JSR	DisplayReadiedMagicName
	CLR.b	Player_in_first_person_mode.w
	PlaySound_b SOUND_BATTLE_START
	JSR	LoadPalettesFromTable
	JSR	EnableDisplay
GameState_BattleInitialize_Loop:
	RTS

; --- GameState_BattleActive ($10) ---
; Per-frame field battle tick.  Refreshes HP/MP display.  If HP <= 0,
; plays death sound and transitions to BEGIN_RESURRECTION (with special
; handling for the Bully first-fight flag).
GameState_BattleActive:
	JSR	DisplayPlayerHpMp
	TST.w	Player_hp.w
	BGT.b	GameState_BattleActive_Loop
	TST.b	Bully_first_fight_won.w
	BNE.b	GameState_BattleActive_TriggerDeath
	CLR.b	Soldier_fight_event_trigger.w
GameState_BattleActive_TriggerDeath:
	PlaySound SOUND_SPELL_CAST
	MOVE.w	#GAMEPLAY_STATE_BEGIN_RESURRECTION, Gameplay_state.w
	MOVE.b	#8, Fade_out_lines_mask.w
	CLR.w	Player_hp.w
	JSR	DisplayPlayerHpMp
GameState_BattleActive_Loop:
	RTS

; --- GameState_BattleExit ($11) ---
; Post-battle cleanup.  Re-checks death (same logic as BattleActive).
; On alive: restores player direction, routes to overworld or cave reload
; depending on Is_in_cave.  Special case: if Soldier_fight_event_trigger,
; marks fight won and routes through ReturnFromBossBattle instead.
GameState_BattleExit:
	TST.w	Player_hp.w
	BGT.b	GameState_BattleExit_Loop
	TST.b	Bully_first_fight_won.w	
	BNE.b	GameState_BattleExit_TriggerDeath	
	CLR.b	Soldier_fight_event_trigger.w	
GameState_BattleExit_TriggerDeath:
	PlaySound SOUND_SPELL_CAST	
	MOVE.w	#GAMEPLAY_STATE_BEGIN_RESURRECTION, Gameplay_state.w	
	MOVE.b	#8, Fade_out_lines_mask.w	
	CLR.w	Player_hp.w	
	JSR	DisplayPlayerHpMp	
	BRA.w	GameState_BeginResurrection_Return	
GameState_BattleExit_Loop:
	TST.b	Fade_out_lines_mask.w
	BNE.w	GameState_BeginResurrection_Return
	MOVE.w	Saved_player_direction.w, Player_direction.w
	CLR.b	Is_in_battle.w
	TST.b	Soldier_fight_event_trigger.w
	BEQ.b	GameState_BattleExit_CheckCaveReload
	CLR.b	Soldier_fight_event_trigger.w
	MOVE.b	#FLAG_TRUE, Bully_first_fight_won.w
	MOVE.b	#FLAG_TRUE, Skip_town_intro_after_fight.w
	BRA.w	GameState_ReturnFromBossBattle
GameState_BattleExit_CheckCaveReload:
	TST.b	Is_in_cave.w
	BNE.b	GameState_BattleExit_ReloadCave
	MOVE.w	#GAMEPLAY_STATE_OVERWORLD_RELOAD, Gameplay_state.w
	BRA.b	GameState_BattleExit_ClearEntities
GameState_BattleExit_ReloadCave:
	MOVE.w	#GAMEPLAY_STATE_ENTERING_CAVE, Gameplay_state.w
GameState_BattleExit_ClearEntities:
	JSR	ClearAllEnemyEntities
	CLR.w	Sprite_attr_count.w
	JSR	FlushSpriteAttributesToVDP
	MOVE.b	#FLAG_TRUE, Player_in_first_person_mode.w
GameState_BeginResurrection_Return:
	RTS

; ======================================================================
; Carthahenian Soldier Event States ($2B-$2C)
; ======================================================================

; --- GameState_SoldierTaunt ($2B) ---
; Displays the Carthahenian soldier's taunt dialog before battle.
; Blocks input and prints "You have not won yet!" text.
GameState_SoldierTaunt:
	JSR	ClearScrollData
	MOVE.b	#FLAG_TRUE, Player_input_blocked.w
	PRINT 	YouHaveNotWonYetStr
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#GAMEPLAY_STATE_READ_SOLDIER_TAUNT, Gameplay_state.w
	RTS

; --- GameState_ReadSoldierTaunt ($2C) ---
; Waits for soldier taunt text to finish, then waits for C or B press.
; On dismiss: transitions to BATTLE_EXIT with fade-out and transition sound.
GameState_ReadSoldierTaunt:
	TST.b	Script_text_complete.w
	BEQ.b	GameState_ReadSoldierTaunt_Dismiss_Loop
	CheckButton BUTTON_BIT_C
	BNE.b	GameState_ReadSoldierTaunt_Dismiss
	CheckButton BUTTON_BIT_B
	BNE.b	GameState_ReadSoldierTaunt_Dismiss
	RTS

GameState_ReadSoldierTaunt_Dismiss:
	MOVE.w	#GAMEPLAY_STATE_BATTLE_EXIT, Gameplay_state.w
	PlaySound_b SOUND_TRANSITION
	PlaySound SOUND_LEVEL_UP
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	RTS

GameState_ReadSoldierTaunt_Dismiss_Loop:
	JSR	ProcessScriptText
	RTS

; ======================================================================
; Overworld / Cave Exploration State Handlers ($12-$17)
; ======================================================================

; --- GameState_OverworldReload ($12) ---
; Reloads the first-person overworld view after a battle.  Initializes
; the battle display framework, loads all overworld tile graphics, updates
; the compass, loads first-person renderer, sets overworld palettes, clears
; cave state, and checks for pending level-up.
GameState_OverworldReload:
	TST.b	Fade_out_lines_mask.w
	BNE.w	GameState_OverworldReload_Loop
	BSR.w	InitBattleDisplay
	JSR	LoadBattleTileGraphics
	JSR	LoadBattleUiTileGraphics
	JSR	LoadBattleGroundTileGraphics
	JSR	LoadBattleEnemyTileGraphics
	JSR	LoadBattlePlayerTileGraphics
	JSR	LoadBattleStatusTileGraphics
	BSR.w	UpdateAndDisplayCompass
	JSR	LoadFirstPersonGraphics
	MOVE.b	#FLAG_TRUE, Player_in_first_person_mode.w
	MOVE.w	#PALETTE_IDX_OVERWORLD_LINE1, Palette_line_1_index.w
	MOVE.w	#PALETTE_IDX_CAVE_FLOOR, Palette_line_2_index.w
	JSR	LoadPalettesFromTable
	JSR	EnableDisplay
	CLR.b	Is_in_cave.w
	CLR.b	Cave_position_saved.w
	MOVE.w	#$FFFF, Inaudios_steps_remaining.w
	BSR.w	CheckLevelUpAndRestoreMusic
GameState_OverworldReload_Loop:
	RTS

; --- GameState_OverworldActive ($13) ---
; Alias state: immediately branches to GameState_CaveExploration.
; Overworld and cave share the same per-frame tick logic.
GameState_OverworldActive:
	BRA.w	GameState_CaveExploration

; --- GameState_TownFadeInComplete ($14) ---
; Post-town-exit fade completion.  Clears first-person mode and
; transitions back to INIT_TOWN_ENTRY to re-enter the town.
GameState_TownFadeInComplete:
	TST.b	Fade_out_lines_mask.w
	BNE.b	GameState_TownFadeInComplete_Loop
	CLR.b	Player_in_first_person_mode.w
	PlaySound SOUND_LEVEL_UP
	MOVE.w	#GAMEPLAY_STATE_INIT_TOWN_ENTRY, Gameplay_state.w
GameState_TownFadeInComplete_Loop:
	RTS

; --- GameState_EnteringCave ($15) ---
; Loads cave-specific graphics and palettes.  Sets cave encounter rate,
; applies lit palette if Cave_light_active, enables display, then checks
; for pending level-up.
GameState_EnteringCave:
	TST.b	Fade_out_lines_mask.w
	BNE.w	GameState_EnteringCave_Loop
	BSR.w	InitBattleDisplay
	JSR	LoadCaveTileGraphics
	JSR	LoadCaveEnemyTileGraphics
	JSR	LoadCaveItemTileGraphics
	JSR	LoadFirstPersonBattleGraphics
	BSR.w	DisplayKimsAndCompass
	TST.b	Cave_light_active.w
	BEQ.b	GameState_EnteringCave_ApplyLightPalette
	MOVE.w	#PALETTE_IDX_CAVE_FLOOR_LIT, Palette_line_1_index.w
	MOVE.w	#PALETTE_IDX_CAVE_ANIM_BASE, Palette_line_2_index.w
	JSR	LoadPalettesFromTable
GameState_EnteringCave_ApplyLightPalette:
	JSR	EnableDisplay
	MOVE.w	#ENCOUNTER_RATE_CAVE, Encounter_rate.w
	BSR.w	CheckLevelUpAndRestoreMusic
GameState_EnteringCave_Loop:
	RTS

; --- InitBattleDisplay ---
; Shared initialization for the first-person view (overworld and caves).
; Disables display, clears VRAM planes, resets scroll, clears enemy entities,
; initializes battle objects, loads world map tiles, draws the nametable,
; sets the player object to InitOverworldPlayerObject, increments state,
; clears all dialog/interaction flags, and loads palettes.
InitBattleDisplay:
	JSR	DisableVDPDisplay
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	JSR	ClearScrollData
	CLR.w	Camera_scroll_x.w
	CLR.w	Camera_scroll_y.w
	BSR.w	ClearAllEnemyEntities
	JSR	InitBattleObjects
	CLR.w	Sprite_attr_count.w
	JSR	FlushSpriteAttributesToVDP
	JSR	LoadWorldMapTileGraphics
	BSR.w	DrawBattleNametable
	JSR	ProcessAllObjectSlots
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.l	#InitOverworldPlayerObject, obj_tick_fn(A6)
	ADDQ.w	#1, Gameplay_state.w
	MOVE.w	#PALETTE_IDX_CAVE_WALLS, Palette_line_0_index.w
	MOVE.w	#PALETTE_IDX_TOWN_HUD, Palette_line_3_index.w
	CLR.b	Dialog_active_flag.w
	CLR.b	Encounter_triggered.w
	CLR.b	Dialog_state_flag.w
	CLR.b	Chest_opened_flag.w
	CLR.b	Reward_script_active.w
	CLR.b	Herbs_available.w
	CLR.b	Truffles_available.w
	CLR.b	Reward_script_available.w
	CLR.b	Talker_present_flag.w
	CLR.b	Chest_already_opened.w
	CLR.w	Overworld_menu_state.w
	BCLR.b	#0, Player_direction_flags.w
	JSR	LoadPalettesFromTable
	RTS

; --- CheckLevelUpAndRestoreMusic ---
; Checks if the player has enough experience for a level-up.  If so,
; saves current state, increments level, upgrades stats, displays the
; level-up banner, and transitions to LEVEL_UP_BANNER_DISPLAY.
; If no level-up, restores overworld or cave music and clears input block.
; Always refreshes the HP/MP/Kims/Experience/Magic HUD displays.
;CheckLevelUpAndRestoreMusic:
CheckLevelUpAndRestoreMusic: ; level up
	CMPI.w	#MAX_PLAYER_LEVEL, Player_level.w
	BGE.b	GameState_LevelUpComplete_Check
	MOVE.l	Player_experience.w, D0
	CMP.l	Player_next_level_experience.w, D0
	BLT.b	GameState_LevelUpComplete_Check
	MOVE.w	Gameplay_state.w, Saved_game_state.w
	MOVE.b	#FLAG_TRUE, Player_input_blocked.w
	MOVE.w	#GAMEPLAY_STATE_LEVEL_UP_BANNER_DISPLAY, Gameplay_state.w
	PlaySound_b SOUND_LEVEL_UP_BANNER
	ADDQ.w	#1, Player_level.w
	JSR	UpgradeLevelStats
	MOVE.w	#100, Level_up_timer.w
	JSR	SavePromptMenuToBuffer
	JSR	LoadLevelUpBannerTiles
	BRA.b	GameState_LevelUpComplete_Check_Loop
GameState_LevelUpComplete_Check:
	TST.b	Is_in_cave.w
	BEQ.b	GameState_LevelUpComplete_Check_OverworldMusic
	BSR.w	PlayCaveMusic
	BRA.b	GameState_LevelUpComplete_Check_ClearBlock
GameState_LevelUpComplete_Check_OverworldMusic:
	MOVE.b	#SOUND_OVERWORLD_MUSIC, D0
	MOVE.w	D0, Current_area_music.w
	JSR	QueueSoundEffect
GameState_LevelUpComplete_Check_ClearBlock:
	CLR.b	Player_input_blocked.w
GameState_LevelUpComplete_Check_Loop:
	JSR	DisplayPlayerHpMp
	JSR	DisplayPlayerMaxHpMp
	JSR	DisplayPlayerKimsAndExperience
	JSR	DisplayReadiedMagicName
	RTS

; --- GameState_CaveExploration ($16) ---
; Main per-frame tick for first-person overworld and cave exploration.
; Checks poison notification, player death, boss triggers, then processes
; movement (forward/backward/rotate).  If stationary, checks cave or
; overworld interactions, processes found-item rewards, dispatches the
; overworld menu, and finally checks for random encounters.
GameState_CaveExploration:
	TST.w	Player_poisoned.w
	BEQ.b	GameState_CaveExploration_CheckDeath
	TST.b	Poison_notified.w
	BNE.b	GameState_CaveExploration_CheckDeath
	MOVE.w	#GAMEPLAY_STATE_SHOW_POISON_NOTIFICATION, Gameplay_state.w
	RTS

GameState_CaveExploration_CheckDeath:
	BSR.w	CheckPlayerDeath
	BEQ.b	GameState_CaveExploration_CheckDeath_Loop
	RTS
	
GameState_CaveExploration_CheckDeath_Loop:
	TST.b	Boss_event_trigger.w
	BEQ.b	GameState_CaveExploration_CheckMovement
	MOVE.w	Gameplay_state.w, Saved_game_state.w
	MOVE.w	#GAMEPLAY_STATE_BOSS_BATTLE_INIT, Gameplay_state.w
	PlaySound SOUND_LEVEL_UP
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	RTS

GameState_CaveExploration_CheckMovement: ; process movement actions in overworld
	TST.b	Player_move_forward_in_overworld.w
	BNE.w	OverworldMovementTick_ClearEncounterCheck
	TST.b	Player_move_backward_in_overworld.w
	BNE.w	OverworldMovementTick_ClearEncounterCheck
	TST.b	Player_rotate_counter_clockwise_in_overworld.w
	BNE.w	OverworldMovementTick_ClearEncounterCheck
	TST.b	Player_rotate_clockwise_in_overworld.w
	BNE.w	OverworldMovementTick_ClearEncounterCheck
	TST.b	Dialog_active_flag.w
	BNE.b	OverworldMovementTick_HandleMenu
	TST.b	Is_in_cave.w
	BEQ.w	GameState_CaveExploration_CheckOverworld
	BSR.w	CheckCaveInteractions
	BRA.b	GameState_CaveExploration_CheckReward
GameState_CaveExploration_CheckOverworld:
	BSR.w	CheckOverworldInteractions
GameState_CaveExploration_CheckReward:
	TST.b	Dialog_state_flag.w
	BNE.b	OverworldMovementTick_HandleMenu
	TST.b	Found_something_nearby.w
	BEQ.b	OverworldMovementTick_HandleMenu
	JSR	SetupFoundItemReward
	CLR.b	Found_something_nearby.w
OverworldMovementTick_HandleMenu:
	BSR.w	HandleOverworldMenuInput
	TST.b	Checked_for_encounter.w
	BNE.b	OverworldMovementTick_Return
	TST.b	Tsarkon_is_dead.w
	BNE.w	OverworldMovementTick_Return
	TST.w	Inaudios_steps_remaining.w
	BGE.b	OverworldMovementTick_Return
	BSR.w	CheckForEncounter
	BNE.b	OverworldMovementTick_TriggerEncounter
	ADDQ.b	#1, Steps_since_last_encounter.w
	CMPI.b	#MAX_STEPS_BETWEEN_ENCOUNTERS, Steps_since_last_encounter.w
	BEQ.b	OverworldMovementTick_TriggerEncounter
	BRA.b	OverworldMovementTick_Return
OverworldMovementTick_ClearEncounterCheck:
	CLR.b	Checked_for_encounter.w
OverworldMovementTick_Return:
	RTS

OverworldMovementTick_TriggerEncounter:
	CLR.b	Steps_since_last_encounter.w
	CLR.b	Player_input_blocked.w
	MOVE.w	#GAMEPLAY_STATE_ENCOUNTER_INITIALIZE, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Encounter_triggered.w
	RTS

; --- GameState_CaveFadeOutComplete ($17) ---
; After exiting a cave, clears cave state flags and transitions to
; OVERWORLD_RELOAD to restore the surface overworld view.
GameState_CaveFadeOutComplete:
	TST.b	Fade_out_lines_mask.w
	BNE.b	GameState_CaveFadeOutComplete_Loop
	CLR.b	Is_in_cave.w
	CLR.b	Cave_light_active.w
	CLR.w	Cave_light_timer.w
	MOVE.w	#GAMEPLAY_STATE_OVERWORLD_RELOAD, Gameplay_state.w
	MOVEA.l	Player_entity_ptr.w, A6
GameState_CaveFadeOutComplete_Loop:
	RTS

; ======================================================================
; Encounter Chain State Handlers ($18-$1A)
; ======================================================================

; --- GameState_EncounterInitialize ($18) ---
; Selects the enemy group from EnemyEncounterTypesByMapSector (overworld)
; or EnemyEncounterTypesByCaveRoom (cave).  Picks a random variant (0-3),
; loads the encounter portrait graphics, DMA-fills the portrait VRAM area,
; sets up the encounter portrait object, and transitions to
; ENCOUNTER_GRAPHICS_FADE_IN.
GameState_EncounterInitialize:
	TST.b	Is_in_cave.w
	BNE.b	GameState_EncounterInitialize_Loop
	LEA	EnemyEncounterTypesByMapSector, A0
	MOVE.w	Player_map_sector_y.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVE.w	Player_map_sector_x.w, D1
	ADD.w	D1, D0
	MOVE.b	(A0,D0.w), Encounter_group_index.w
	BRA.b	GameState_EncounterInitialize_PickVariant
GameState_EncounterInitialize_Loop:
	LEA	EnemyEncounterTypesByCaveRoom, A0
	MOVE.w	Current_cave_room.w, D0
	MOVE.b	(A0,D0.w), Encounter_group_index.w
GameState_EncounterInitialize_PickVariant:
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	MOVE.w	D0, Random_number.w
	JSR	LoadEncounterTypeGraphics
	DMAFillVRAM $45600002, $03FF
	MOVEA.l	Current_actor_ptr.w, A6
	BSET.b	#7, (A6)
	MOVE.l	#InitEncounterPortrait, obj_tick_fn(A6)
	MOVE.w	#GAMEPLAY_STATE_ENCOUNTER_GRAPHICS_FADE_IN, Gameplay_state.w
	CLR.w	Dialog_timer.w
	CLR.w	Dialog_phase.w
	CLR.b	Chest_already_opened.w
	PlaySound SOUND_ENCOUNTER_START
	RTS

; --- GameState_EncounterGraphicsFadeIn ($19) ---
; Slides the enemy portrait in column-by-column.  Timing varies by
; region: PAL (bit 6 of IO_version set) updates every 4 frames, NTSC
; every 8 frames.  After all ENCOUNTER_FADE_PHASES columns are drawn,
; flushes the tile buffer and advances to ENCOUNTER_PAUSE_BEFORE_BATTLE.
GameState_EncounterGraphicsFadeIn:
	ADDQ.w	#1, Dialog_timer.w
	MOVE.w	Dialog_timer.w, D0
	BTST.b	#6, IO_version
	BNE.b	GameState_EncounterGraphicsFadeIn_Loop
	ANDI.w	#7, D0
	BNE.b	GameState_EncounterGraphicsFadeIn_Return
	BRA.b	GameState_EncounterGraphicsFadeIn_CheckPhase
GameState_EncounterGraphicsFadeIn_Loop:
	ANDI.w	#3, D0	
	BNE.b	GameState_EncounterGraphicsFadeIn_Return	
GameState_EncounterGraphicsFadeIn_CheckPhase:
	CMPI.w	#ENCOUNTER_FADE_PHASES, Dialog_phase.w
	BLT.b	GameState_EncounterGraphicsFadeIn_DrawColumn
	BSR.w	FlushDialogTileBuffer
	MOVE.w	#GAMEPLAY_STATE_ENCOUNTER_PAUSE_BEFORE_BATTLE, Gameplay_state.w
	BRA.b	GameState_EncounterGraphicsFadeIn_Return
GameState_EncounterGraphicsFadeIn_DrawColumn:
	BSR.w	UpdateDialogTileColumn
GameState_EncounterGraphicsFadeIn_Return:
	RTS

; --- GameState_EncounterPauseBeforeBattle ($1A) ---
; Brief pause (ENCOUNTER_PAUSE_FRAMES) after the portrait finishes,
; then transitions to BATTLE_INITIALIZE with a fade-out.
GameState_EncounterPauseBeforeBattle:
	ADDQ.w	#1, Dialog_timer.w
	CMPI.w	#ENCOUNTER_PAUSE_FRAMES, Dialog_timer.w
	BLE.b	GameState_EncounterPauseBeforeBattle_Loop
	MOVE.w	#GAMEPLAY_STATE_BATTLE_INITIALIZE, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
GameState_EncounterPauseBeforeBattle_Loop:
	RTS

; ======================================================================
; Level-Up State Handlers ($1B-$1D)
; ======================================================================

; --- GameState_LevelUpBannerDisplay ($1B) ---
; Counts down Level_up_timer (100 frames).  When it expires, saves the
; dialog area, draws the character stats window, and advances to
; LEVEL_UP_STATS_WAIT_INPUT.
GameState_LevelUpBannerDisplay:
	SUBQ.w	#1, Level_up_timer.w
	BGT.b	GameState_LevelUpBannerDisplay_Loop
	MOVE.w	#GAMEPLAY_STATE_LEVEL_UP_STATS_WAIT_INPUT, Gameplay_state.w
	JSR	SaveFullDialogAreaToBuffer
	JSR	DrawCharacterStatsWindow
GameState_LevelUpBannerDisplay_Loop:
	RTS

; --- GameState_LevelUpStatsWaitInput ($1C) ---
; Displays the new stats screen and waits for A, B, or C button press
; to dismiss.  While Window_tilemap_draw_active, input is ignored.
GameState_LevelUpStatsWaitInput:
	TST.b	Window_tilemap_draw_active.w
	BNE.b	GameState_LevelUpStats_Dismiss_Loop
	CheckButton BUTTON_BIT_A
	BNE.b	GameState_LevelUpStats_Dismiss
	CheckButton BUTTON_BIT_B
	BNE.b	GameState_LevelUpStats_Dismiss
	CheckButton BUTTON_BIT_C
	BNE.b	GameState_LevelUpStats_Dismiss
	RTS

GameState_LevelUpStats_Dismiss:
	TriggerWindowRedraw WINDOW_DRAW_SCRIPT
	MOVE.w	#GAMEPLAY_STATE_LEVEL_UP_COMPLETE, Gameplay_state.w
GameState_LevelUpStats_Dismiss_Loop:
	RTS

; --- GameState_LevelUpComplete ($1D) ---
; Checks if another level-up is pending (multi-level-up support).
; If so, loops back to LEVEL_UP_BANNER_DISPLAY.  Otherwise restores
; Saved_game_state and resumes overworld or cave music.
GameState_LevelUpComplete:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	GameState_LevelUpComplete_Exit_Loop
	JSR	DrawPromptMenuWindow
	CMPI.w	#MAX_PLAYER_LEVEL, Player_level.w
	BGE.b	GameState_LevelUpComplete_Exit
	MOVE.l	Player_experience.w, D0
	CMP.l	Player_next_level_experience.w, D0
	BLT.b	GameState_LevelUpComplete_Exit
	MOVE.w	#GAMEPLAY_STATE_LEVEL_UP_BANNER_DISPLAY, Gameplay_state.w
	PlaySound_b SOUND_LEVEL_UP_BANNER
	ADDQ.w	#1, Player_level.w
	JSR	UpgradeLevelStats
	MOVE.w	#100, Level_up_timer.w
	JSR	SavePromptMenuToBuffer
	JSR	LoadLevelUpBannerTiles
	JSR	DisplayPlayerHpMp
	JSR	DisplayPlayerMaxHpMp
	JSR	DisplayPlayerKimsAndExperience
	RTS

GameState_LevelUpComplete_Exit:
	CLR.b	Player_input_blocked.w
	MOVE.w	Saved_game_state.w, Gameplay_state.w
	MOVE.b	#SOUND_OVERWORLD_MUSIC, D0
	TST.b	Is_in_cave.w
	BEQ.b	GameState_LevelUpComplete_OverworldMusic
	BSR.w	PlayCaveMusic
	RTS

GameState_LevelUpComplete_OverworldMusic:
	MOVE.w	D0, Current_area_music.w
	JSR	QueueSoundEffect
GameState_LevelUpComplete_Exit_Loop:
	RTS

; --- GameState_ReturnToFirstPersonView ($1E) ---
; After a battle, waits for the fade-out, then calls UpdatePlayerOverworldPosition
; to step the overworld position in the player's facing direction, re-inits
; the first-person view, applies cave palettes if underground, plays the
; return sound, and resets encounter/menu state.
GameState_ReturnToFirstPersonView:
	TST.b	Fade_out_lines_mask.w
	BNE.b	GameState_ReturnToFirstPersonView_Loop
	BSR.w	UpdatePlayerOverworldPosition
	JSR	InitFirstPersonView
	MOVE.w	#GAMEPLAY_STATE_CAVE_EXPLORATION, Gameplay_state.w
	MOVE.w	#PALETTE_IDX_CAVE_WALLS, Palette_line_0_index.w
	TST.b	Cave_light_active.w
	BEQ.b	GameState_ReturnToFirstPersonView_ApplyLightPalette
	MOVE.w	#PALETTE_IDX_CAVE_FLOOR_LIT, Palette_line_1_index.w
	MOVE.w	#PALETTE_IDX_CAVE_ANIM_BASE, Palette_line_2_index.w
GameState_ReturnToFirstPersonView_ApplyLightPalette:
	PlaySound SOUND_OVERWORLD_RETURN
	MOVE.w	#PALETTE_IDX_TOWN_HUD, Palette_line_3_index.w
	CLR.b	Encounter_triggered.w
	CLR.b	Chest_already_opened.w
	CLR.w	Overworld_menu_state.w
	BCLR.b	#0, Player_direction_flags.w
	JSR	LoadPalettesFromTable
GameState_ReturnToFirstPersonView_Loop:
	RTS

; --- GameState_DialogDisplay ($20) ---
; NPC portrait/dialog tile animation (identical pacing logic to
; EncounterGraphicsFadeIn). Slides the dialog portrait in column-by-column.
; When all phases are done, flushes the tile buffer, clears Dialog_state_flag,
; and restores Saved_game_state.
GameState_DialogDisplay:
	ADDQ.w	#1, Dialog_timer.w
	MOVE.w	Dialog_timer.w, D0
	BTST.b	#6, IO_version
	BNE.w	GameState_DialogDisplay_Loop
	ANDI.w	#7, D0
	BNE.b	GameState_DialogDisplay_Return
	BRA.b	GameState_DialogDisplay_CheckPhase
GameState_DialogDisplay_Loop:
	ANDI.w	#3, D0	
	BNE.b	GameState_DialogDisplay_Return	
GameState_DialogDisplay_CheckPhase:
	CMPI.w	#ENCOUNTER_FADE_PHASES, Dialog_phase.w
	BLT.b	GameState_DialogDisplay_DrawColumn
	CLR.b	Dialog_state_flag.w
	BSR.w	FlushDialogTileBuffer
	MOVE.w	Saved_game_state.w, Gameplay_state.w
	BRA.b	GameState_DialogDisplay_Return
GameState_DialogDisplay_DrawColumn:
	BSR.w	UpdateDialogTileColumn
GameState_DialogDisplay_Return:
	RTS

; ======================================================================
; Boss Battle State Handlers
; ======================================================================

; --- GameState_BossBattleInit ($21) ---
; Scans Boss_battle_flags (up to 16 entries) to determine which boss fight
; is active (Battle_type). Clears all boss flags, then initialises boss
; battle objects via BossBattleObjectInitPtrs, loads graphics and palettes,
; and fades in. Player's tick function is set to BossBattlePlayerInit.
GameState_BossBattleInit:
	TST.b	Fade_out_lines_mask.w
	BNE.w	GameState_BossBattleInit_Loop
	JSR	DisableVDPDisplay
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	JSR	ClearScrollData
	CLR.b	Player_input_blocked.w
	CLR.w	D0
	LEA	Boss_battle_flags.w, A0
	MOVE.w	#$000F, D7
GameState_BossBattleInit_Done:
	MOVE.b	(A0)+, D1
	TST.b	D1
	BNE.b	GameState_BossBattleInit_FoundActiveBoss
	ADDQ.w	#1, D0
	DBF	D7, GameState_BossBattleInit_Done
GameState_BossBattleInit_FoundActiveBoss:
	CLR.b	Boss_event_trigger.w
	CLR.b	-$2(A0)
	MOVE.w	D0, Battle_type.w
	LEA	Boss_battle_flags.w, A0
	MOVE.w	#3, D7
GameState_BossBattleInit_ClearFlagNext:
	CLR.l	(A0)+
	DBF	D7, GameState_BossBattleInit_ClearFlagNext
	BSR.w	ClearAllEnemyEntities
	LEA	BossBattleObjectInitPtrs, A0
	MOVE.w	Battle_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	(A0)
	CLR.w	Sprite_attr_count.w
	JSR	FlushSpriteAttributesToVDP
	MOVE.b	#FLAG_TRUE, Is_boss_battle.w
	JSR	LoadBattleTileGraphics
	JSR	LoadBattleTerrainGraphics
	JSR	LoadBattleGraphics
	JSR	LoadBattleTilesToVram
	BSR.w	DrawTerrainTilemap
	BSR.w	DrawBattleStatusBar
	CLR.w	Camera_scroll_x.w
	CLR.w	Camera_scroll_y.w
	JSR	LoadBossGraphics
	MOVEA.l	Player_entity_ptr.w, A6
	ADDQ.w	#1, Gameplay_state.w
	CLR.w	Overworld_menu_state.w
	MOVE.b	#FLAG_TRUE, Is_in_battle.w
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.l	#BossBattlePlayerInit, obj_tick_fn(A6)
	MOVEQ	#0, D0
	MOVE.w	Player_dex.w, D0
	ASR.l	#4, D0
	ADDI.l	#$00000180, D0
	MOVE.l	D0, obj_pos_x_fixed(A6)
	JSR	InitBattleEntities
	JSR	DisplayMaxHpMp
	JSR	DisplayCantUseMessage
	CLR.b	Player_in_first_person_mode.w
	BSR.w	PlayBattleMusic
	LEA	BattlePaletteIndexTable, A0
	MOVE.w	Battle_type.w, D0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), Palette_line_1_fade_target.w
	MOVE.w	#PALETTE_IDX_CAVE_WALLS, Palette_line_0_fade_target.w
	MOVE.w	#$005E, Palette_line_2_fade_target.w
	MOVE.w	#$0060, Palette_line_3_fade_target.w
	MOVE.b	#FLAG_TRUE, Fade_in_lines_mask.w
	JSR	EnableDisplay
GameState_BossBattleInit_Loop:
	RTS

; --- GameState_BossBattleActive ($22) ---
; Per-frame boss battle tick: checks player death and refreshes the
; current HP/MP display. All battle logic runs in the object tick functions.
GameState_BossBattleActive:
	BSR.w	CheckPlayerDeath
	JSR	DisplayCurrentHpMp
	RTS

; --- GameState_ReturnFromBossBattle ($23) ---
; Post-boss-battle cleanup. Checks player death. On alive and fade done:
; disables display, tears down boss objects, restores player-overworld
; graphics and tick function, reloads VRAM, restores Saved_game_state - 1
; as the new state (i.e. the state before the boss fight), and re-enables
; the display. In cave context, sets first-person mode instead of music.
GameState_ReturnFromBossBattle:
	BSR.w	CheckPlayerDeath
	BEQ.b	GameState_ReturnFromBossBattle_Loop
	RTS
	
GameState_ReturnFromBossBattle_Loop:
	TST.b	Fade_out_lines_mask.w
	BNE.w	GameState_ReturnFromBossBattle_WaitFade
	JSR	DisableVDPDisplay
	CLR.b	Is_boss_battle.w
	CLR.b	Is_in_battle.w
	CLR.b	Boss_max_hp.w
	BSR.w	ClearAllEnemyEntities
	JSR	InitMenuObjects
	CLR.w	Sprite_attr_count.w
	JSR	FlushSpriteAttributesToVDP
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.l	#PlayerObjectHandler, obj_tick_fn(A6)
	MOVE.w	Saved_player_direction.w, Player_direction.w
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BCLR.b	#7, (A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BCLR.b	#7, (A6)
	JSR	LoadPlayerOverworldGraphics
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	JSR	ClearScrollData
	MOVE.w	Saved_game_state.w, D0
	SUBQ.w	#1, D0
	MOVE.w	D0, Gameplay_state.w
	TST.b	Is_in_cave.w
	BNE.b	GameState_ReturnFromBossBattle_InCaveMode
	MOVE.w	Current_area_music.w, D0
	JSR	QueueSoundEffect
	BRA.b	GameState_ReturnFromBossBattle_EnableDisplay
GameState_ReturnFromBossBattle_InCaveMode:
	MOVE.b	#FLAG_TRUE, Player_in_first_person_mode.w
GameState_ReturnFromBossBattle_EnableDisplay:
	JSR	EnableDisplay
GameState_ReturnFromBossBattle_WaitFade:
	RTS

; ======================================================================
; Death and Resurrection State Handlers
; ======================================================================

; --- GameState_BeginResurrection ($24) ---
; Entry point when the player dies. Waits for an in-progress fade to clear,
; then forces another fade-out and advances to PROCESS_RESURRECTION.
GameState_BeginResurrection:
	TST.b	Fade_out_lines_mask.w
	BNE.b	GameState_BeginResurrection_Loop
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	ADDQ.w	#1, Gameplay_state.w
GameState_BeginResurrection_Loop:
	RTS

; --- GameState_ProcessResurrection ($25) ---
; Actual resurrection logic. Waits for fade, then:
;   - Clears enemy entities and cave state flags
;   - Unless Banshee_powder_active: halves kims in BCD
;     (the inner loop processes 4 BCD bytes at a time)
;   - Restores HP and MP to full
;   - Calls InitializeTownMode to warp player to nearest church
;   - Sets Player_awakening_flag so the inn wakeup dialog fires
GameState_ProcessResurrection:
	TST.b	Fade_out_lines_mask.w
	BNE.w	GameState_ProcessResurrection_Loop
	BSR.w	ClearAllEnemyEntities
	CLR.b	Player_in_first_person_mode.w
	CLR.b	Is_in_cave.w
	CLR.b	Cave_light_active.w
	CLR.w	Cave_light_timer.w
	TST.b	Player_greatly_poisoned.w
	BNE.b	GameState_ProcessResurrection_HalveKims
	CLR.w	Player_poisoned.w
GameState_ProcessResurrection_HalveKims: ; ressurected in church?
	MOVE.w	Player_mhp.w, Player_hp.w
	MOVE.w	Player_mmp.w, Player_mp.w
	TST.b	Banshee_powder_active.w
	BNE.w	GameState_ProcessResurrection_InitTown
	LEA	Player_kims.w, A0
	CLR.l	D2
	MOVE.w	#3, D4
GameState_ProcessResurrection_BcdByteLoop:
	CLR.l	D0
	MOVE.b	(A0), D0
	CLR.l	D1
	MOVE.b	D0, D1
	ANDI.b	#$F0, D1
	BEQ.b	GameState_ProcessResurrection_BcdHighZero
	LSR.b	#4, D1
	DIVU.w	#2, D1
GameState_ProcessResurrection_BcdHighZero:
	TST.w	D2
	BEQ.b	GameState_ProcessResurrection_BcdHighNoCarry
	ADDQ.w	#5, D1
GameState_ProcessResurrection_BcdHighNoCarry:
	CLR.l	D2
	MOVE.l	D1, D2
	SWAP	D2
	LSL.b	#4, D1
	CLR.l	D3
	MOVE.b	D0, D3
	ANDI.b	#$0F, D3
	BEQ.b	GameState_ProcessResurrection_BcdLowZero
	DIVU.w	#2, D3
GameState_ProcessResurrection_BcdLowZero:
	TST.w	D2
	BEQ.b	GameState_ProcessResurrection_BcdLowNoCarry
	ADDQ.w	#5, D3
GameState_ProcessResurrection_BcdLowNoCarry:
	CLR.l	D2
	MOVE.l	D3, D2
	SWAP	D2
	OR.b	D1, D3
	MOVE.b	D3, (A0)+
	DBF	D4, GameState_ProcessResurrection_BcdByteLoop
GameState_ProcessResurrection_InitTown:
	BSR.w	InitializeTownMode
	MOVE.w	#GAMEPLAY_STATE_INIT_BUILDING_ENTRY, Gameplay_state.w
	MOVE.w	Saved_town_room_1.w, Current_town_room.w
	JSR	LoadAndPlayAreaMusic
	MOVE.b	#FLAG_TRUE, Player_awakening_flag.w
GameState_ProcessResurrection_Loop:
	RTS

; ======================================================================
; Notification State Handlers
; ======================================================================

; --- GameState_NotifyInaudiosExpired ($26) ---
; Saves status bar, prints "Inaudios has worn off", and advances to
; WAIT_FOR_NOTIFICATION_DISMISS with input blocked.
GameState_NotifyInaudiosExpired:
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	PRINT 	InaudiosWornOffStr
	MOVE.w	#GAMEPLAY_STATE_WAIT_FOR_NOTIFICATION_DISMISS, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Player_input_blocked.w
	RTS

; --- GameState_ShowPoisonNotification ($2D) ---
; First-time poison notification: saves status bar, prints "You are poisoned!",
; advances to WAIT_FOR_NOTIFICATION_DISMISS, and sets Poison_notified so
; this fires only once per poisoning.
GameState_ShowPoisonNotification:
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	PRINT 	PoisonedStr
	MOVE.w	#GAMEPLAY_STATE_WAIT_FOR_NOTIFICATION_DISMISS, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Player_input_blocked.w
	MOVE.b	#FLAG_TRUE, Poison_notified.w
	RTS

; --- GameState_WaitForNotificationDismiss ($27) ---
; Generic notification dismiss handler.  Waits for the window draw to
; finish and script text to complete, then waits for C or B button.
; On dismiss: redraws the status HUD, returns to OVERWORLD_ACTIVE,
; and clears the input block.
GameState_WaitForNotificationDismiss:
	TST.b	Window_tilemap_draw_pending.w
	BNE.b	GameState_WaitNotification_Dismiss_Loop
	TST.b	Script_text_complete.w
	BEQ.b	GameState_WaitNotification_ProcessText
	CheckButton BUTTON_BIT_C
	BNE.b	GameState_WaitNotification_Dismiss
	CheckButton BUTTON_BIT_B
	BNE.b	GameState_WaitNotification_Dismiss
	RTS

GameState_WaitNotification_Dismiss:
	JSR	DrawStatusHudWindow
	MOVE.w	#GAMEPLAY_STATE_OVERWORLD_ACTIVE, Gameplay_state.w
	CLR.b	Player_input_blocked.w
GameState_WaitNotification_ProcessText:
	JSR	ProcessScriptText
GameState_WaitNotification_Dismiss_Loop:
	RTS

; ======================================================================
; Town Spawn / Position Data Tables
; ======================================================================

; TownSpawnPositionData — 16 entries, 8 bytes each (4 words):
;   dc.w  spawn_x, spawn_y, camera_x, camera_y
; Indexed by town ID.  Used by GameState_LoadTown and InitializeTownMode.
TownSpawnPositionData:
	dc.w	$0208, $0138, $0016, $000B
	dc.w	$0278, $0228, $001C, $001A
	dc.w	$00D8, $00C8, $0003, $0004
	dc.w	$01C8, $00F8, $0011, $0007
	dc.w	$00A8, $01C8, $0000, $0014
	dc.w	$00A8, $01C8, $0000, $0014 
	dc.w	$01A8, $01A8, $000F, $0012
	dc.w	$0278, $0228, $001C, $001A
	dc.w	$00F8, $00E8, $0006, $0006
	dc.w	$00A8, $0198, $0000, $0011
	dc.w	$0208, $0218, $0016, $0019
	dc.w	$01B8, $00F8, $0010, $0007
	dc.w	$01B8, $00F8, $0010, $0007
	dc.w	$0208, $0138, $0017, $000B
	dc.w	$0208, $0138, $0017, $000B 
	dc.w	$0208, $0138, $0017, $000B 
; TownPlayerPositionData — 8 entries, 4 bytes each (2 words):
;   dc.w  player_x_in_town, player_y_in_town
; Used by InitializeTownMode to set Player_position_x/y_in_town after
; resurrection or teleport.
TownPlayerPositionData:
	dc.w	$20, $12, $27, $21 
	dc.w	$D, $B, $1C, $E 
	dc.w	$A, $1B, $A, $1B
	dc.w	$1A, $19, $27, $21 
	dc.w	$F, $D, $A, $18
	dc.w	$20, $20, $1B, $E
	dc.w	$1B, $E, $20, $12
	dc.w	$20, $12, $20, $12 
; -----------------------------------------------------------------------
; RAND-009: Town / Dungeon Connectivity Graph
; -----------------------------------------------------------------------
; This documents every town, its overworld sector coordinates, its
; associated cave dungeon (if any), and all story-flag gates that block
; progression.  Intended as a single authoritative reference for
; randomizer logic.
;
; Sector coordinates are (sector_x, sector_y) as stored in
; TownTeleportLocationData below.  All flag names are symbolic constants
; defined in constants.asm.
;
; FORMAT
;   Town ID  [sector_x, sector_y]  Town name
;     Dungeon: cave room ID(s) — dungeon name
;     Gate IN:  <flag> — description of what blocks arrival
;     Gate OUT: <flag> — description of what must be set to leave / progress
;     Notes: ...
;
; -----------------------------------------------------------------------
; TOWN_WYCLIF ($00)  [sector $0,$6]  Wyclif
;   Dungeon: none
;   Gate IN:  none (starting town)
;   Gate OUT: none
;   Notes:    Starting town.  Blade NPC killed here early in prologue.
;             Blade_is_dead ($FFFFC720) set after his fight.
;
; TOWN_PARMA ($01)  [sector $1,$4]  Parma
;   Dungeon: cave rooms $01–$03 (Parma dungeon / Treasure of Troy)
;   Gate IN:  none (free from Wyclif)
;   Gate OUT: Fake_king_killed ($FFFFC723) must be set before real-king
;             questline continues.  Sent_to_malaga ($FFFFC733) is set by
;             the Parma king conclusion dialogue, opening Malaga questline.
;   Notes:    Treasure_of_troy_found ($FFFFC726) acquired in cave room $02.
;             Treasure_of_troy_given_to_king ($FFFFC724) enables clue NPC.
;             Talked_to_real_king ($FFFFC725) starts Troy quest.
;
; TOWN_WATLING ($02)  [sector $6,$5]  Watling
;   Dungeon: cave room $04 (Watling cave)
;   Gate IN:  none (free from Parma after Fake_king_killed)
;   Gate OUT: none
;   Notes:    Side-area; no mandatory story flag.
;
; TOWN_DEEPDALE ($03)  [sector $4,$7]  Deepdale
;   Dungeon: cave room $06 (Deepdale / Truffle cave)
;   Gate IN:  none
;   Gate OUT: none
;   Notes:    Truffle_collected ($FFFFC72B) acquired here; delivered to
;             a Deepdale NPC for a side-quest reward.
;
; TOWN_STOW1 / TOWN_STOW2 ($04/$05)  [sector $B,$7]  Stow
;   Dungeon: cave room $08 (Stow cave)
;   Gate IN:  Malaga_king_crowned ($FFFFC73B) — Stow route is sealed
;             until the Malaga coronation event completes.
;   Gate OUT: none
;   Notes:    Two town IDs share the same sector; $04 = Stow exterior,
;             $05 = Stow church / secondary entrance.
;
; TOWN_KELTWICK ($06)  [sector $E,$4]  Keltwick
;   Dungeon: none
;   Gate IN:  Sent_to_malaga ($FFFFC733) — an NPC physically blocks the
;             path until the flag is set (npc.asm NPCTick_Keltwick_WaitForPlayer).
;   Gate OUT: none
;   Notes:    Waypoint town on the route to Malaga.
;
; TOWN_MALAGA ($07)  [sector $C,$2]  Malaga
;   Dungeon: cave room $0D (Malaga dungeon)
;   Gate IN:  Sent_to_malaga ($FFFFC733) (same gate as Keltwick)
;   Gate OUT: Malaga_king_crowned ($FFFFC73B) — must complete coronation
;             event before Barrow / Stow routes open.
;   Notes:    CaveImposterBoss fight in cave room $0D sets Imposter_killed
;             ($FFFFC73D).
;
; TOWN_BARROW ($08)  [sector $E,$0]  Barrow
;   Dungeon: cave rooms $00, $0B, $0C (Barrow dungeon / Imposter lair)
;   Gate IN:  Malaga_king_crowned ($FFFFC73B) — route north to Barrow
;             requires Malaga coronation.
;   Gate OUT (castle interior): Imposter_killed ($FFFFC73D) AND
;             Barrow_map_received ($FFFFC740) required for castle-interior
;             NPC to step aside (npc.asm NPCTick_Barrow_QuestGuard).
;   Notes:    Ring_of_earth_obtained ($FFFFC749) and
;             Ring_of_wind_received ($FFFFC74B) both acquired in Barrow
;             dungeon event chain.  Bearwulf_met ($FFFFC734) and
;             Bearwulf_returned_home ($FFFFC735) are Barrow-area side flags.
;
; TOWN_TADCASTER ($09)  [sector $9,$1]  Tadcaster
;   Dungeon: cave rooms $11, $13 (Tadcaster dungeon)
;   Gate IN:  Barrow_map_received ($FFFFC740) — map from Barrow quest
;             required; Tadcaster pass sold by NPC in Tadcaster.
;   Gate OUT: Pass_to_carthahena_purchased ($FFFFC754) — must buy pass
;             from the Tadcaster pass-seller NPC to unlock Carthahena
;             border guards (npc.asm NPCTick_Tadcaster_PassSeller).
;   Notes:    Helwig_men_rescued ($FFFFC744) flag originates from
;             cave room $13.
;
; TOWN_HELWIG ($0A)  [sector $6,$0]  Helwig
;   Dungeon: cave room $14 (Helwig cave / Stow prisoner cave)
;   Gate IN:  none (reachable after Barrow map)
;   Gate OUT: none mandatory
;   Notes:    Helwig_men_rescued ($FFFFC744) set by freeing prisoners in
;             cave room $14 (npc.asm FreePrisoners dialogue completion).
;             Post-rescue inn-wakeup event activates.
;
; TOWN_SWAFFHAM ($0B)  [sector $1,$0]  Swaffham
;   Dungeon: cave room $1E (Swaffham cave)
;   Gate IN:  none (reachable once northwest is open)
;   Gate OUT: none
;   Notes:    Late-game optional area; contains useful items and NPCs.
;
; TOWN_EXCALABRIA ($0C)  [sector $5,$2]  Excalabria
;   Dungeon: cave rooms $16, $24, $29 (Excalabria / blacksmith dungeon)
;   Gate IN:  none (geographically accessible from Tadcaster area)
;   Gate OUT: Sword_retrieved_from_blacksmith ($FFFFC756) — blacksmith
;             steals sword (Sword_stolen_by_blacksmith, $FFFFC755);
;             player must recover it before acquiring
;             Player_has_sword_of_vermilion ($FFFFC757).
;   Notes:    The Sword of Vermilion is the endgame key item.
;
; TOWN_HASTINGS1 / TOWN_HASTINGS2 ($0D/$0E)  [sector $9,$2]  Hastings
;   Dungeon: none identified
;   Gate IN:  none
;   Gate OUT: none
;   Notes:    Two town IDs share the same sector coordinates (duplicate
;             entry, same as TOWN_STOW1/2 pattern).
;
; TOWN_CARTHAHENA ($0F)  [sector $A,$5]  Carthahena
;   Dungeon: cave room $20 (Tsarkon final dungeon)
;   Gate IN:  Pass_to_carthahena_purchased ($FFFFC754) — border guards
;             block entry without the pass (townbuild.asm shop dialogue
;             sets the flag; npc.asm guard NPC reads it).
;   Gate OUT: Player_has_sword_of_vermilion ($FFFFC757) required to
;             trigger endgame fight with Tsarkon.
;   Notes:    Tsarkon_is_dead ($FFFFC758) set on final boss defeat.
;             Crown_received ($FFFFC75B) acquired here; triggers ending.
;             Soldier_fight_event_trigger ($FFFFC816) fires in Carthahena.
;
; -----------------------------------------------------------------------
; CRITICAL PATH SUMMARY (linear order):
;   Wyclif → Parma (Fake_king_killed → Sent_to_malaga)
;     → Deepdale/Watling (optional)
;     → Keltwick → Malaga (Malaga_king_crowned)
;     → Stow (optional, opens after Malaga)
;     → Barrow (Imposter_killed → Barrow_map_received)
;     → Tadcaster → Helwig (optional) → Swaffham (optional)
;     → Excalabria (sword retrieval)
;     → Carthahena (Pass_to_carthahena_purchased)
;     → Tsarkon fight → Crown_received → ENDING
;
; RANDOMIZER NOTES:
;   - Flags that physically gate movement (NPC blockers / border guards):
;       Sent_to_malaga, Malaga_king_crowned, Imposter_killed,
;       Barrow_map_received, Pass_to_carthahena_purchased
;   - Dungeon access is always free once the town sector is reachable
;     (no dungeon-specific gate flags)
;   - Four rings/crystals are required before the endgame sword fight;
;     a randomizer must guarantee all four are obtainable.
; -----------------------------------------------------------------------
TownTeleportLocationData: ; town teleport locations
	; format:
	; dc.w (x_in_sector), (y_in_sector), (sector_x), (sector_y)
	dc.w	$8, $D, $0, $6 ; TOWN_WYCLIF
	dc.w	$7, $6, $1, $4 ; TOWN_PARMA
	dc.w	$8, $4, $6, $5 ; TOWN_WATLING
	dc.w	$4, $8, $4, $7 ; TOWN_DEEPDALE
	dc.w	$A, $5, $B, $7 ; TOWN_STOW1
	dc.w	$A, $5, $B, $7 ; TOWN_STOW2
	dc.w	$4, $5, $E, $4 ; TOWN_KELTWICK
	dc.w	$4, $6, $C, $2 ; TOWN_MALAGA
	dc.w	$9, $5, $E, $0 ; TOWN_BARROW
	dc.w	$A, $6, $9, $1 ; TOWN_TADCASTER
	dc.w	$6, $F, $6, $0 ; TOWN_HELWIG
	dc.w	$7, $7, $1, $0 ; TOWN_SWAFFHAM
	dc.w	$A, $5, $5, $2 ; TOWN_EXCALABRIA
	dc.w	$5, $4, $9, $2 ; TOWN_HASTINGS1
	dc.w	$5, $4, $9, $2 ; TOWN_HASTINGS2
	dc.w	$8, $8, $A, $5 ; TOWN_CARTHAHENA
; TownSavedPositionData — 16 entries, 4 bytes each (2 words):
;   dc.w  saved_x, saved_y
; Used by InitializeTownMode to set Saved_player_x_in_town and
; Town_player_spawn_y for the church building the player warps to.
TownSavedPositionData:
	dc.w	$D8, $68 
	dc.w	$58, $68
	dc.w	$D8, $68 
	dc.w	$58, $68
	dc.w	$58, $68 
	dc.w	$58, $68
	dc.w	$58, $68 
	dc.w	$58, $68 
	dc.w	$D8, $68 
	dc.w	$58, $68
	dc.w	$D8, $68 
	dc.w	$58, $68
	dc.w	$58, $68 
	dc.w	$D8, $68
	dc.w	$D8, $68
	dc.w	$D8, $68 

; ======================================================================
; Utility Functions
; ======================================================================

; --- CheckPlayerDeath ---
; Tests Player_hp.  If HP <= 0: plays death sound, sets state to
; BEGIN_RESURRECTION, starts fade-out, clears HP, returns D0 = $FFFF.
; If HP > 0: returns D0 = 0.  Caller tests with BEQ (alive) / BNE (dead).
CheckPlayerDeath:
	TST.w	Player_hp.w
	BGT.b	CheckPlayerDeath_Loop
	PlaySound SOUND_SPELL_CAST
	MOVE.w	#GAMEPLAY_STATE_BEGIN_RESURRECTION, Gameplay_state.w
	MOVE.b	#8, Fade_out_lines_mask.w
	MOVE.w	#$FFFF, D0
	CLR.w	Player_hp.w
	RTS

CheckPlayerDeath_Loop:
	CLR.w	D0
	RTS

; --- UpdateDialogTileColumn ---
; Copies one column of tiles from Tile_gfx_buffer to VRAM for the
; portrait slide-in animation.  Each column is 103 ($67) tiles tall,
; spaced $A bytes apart in the buffer.  Tile index is shifted left 4
; to form VRAM tile ID.  Increments Dialog_phase after each column.
; Used by both EncounterGraphicsFadeIn and DialogDisplay.
UpdateDialogTileColumn:
	LEA	Tile_gfx_buffer.w, A0
	MOVE.l	#$45600002, D5
	MOVEQ	#0, D0
	MOVE.w	Dialog_phase.w, D0
	ADDA.w	D0, A0
	SWAP	D0
	ADD.l	D0, D5
	MOVE.w	#$0066, D7
	ORI	#$0700, SR
UpdateDialogTileColumn_Done:
	MOVE.l	D5, VDP_control_port
	CLR.w	D0
	MOVE.b	(A0), D0
	ASL.w	#4, D0
	MOVE.w	D0, VDP_data_port
	ADDI.l	#$000A0000, D5
	LEA	$A(A0), A0
	DBF	D7, UpdateDialogTileColumn_Done
	ANDI	#$F8FF, SR
	ADDQ.w	#1, Dialog_phase.w
	RTS

; --- FlushDialogTileBuffer ---
; Writes the entire Tile_gfx_buffer (512 words) to VRAM in one burst.
; Clears Dialog_timer afterward.  Called after all portrait columns have
; been drawn to ensure the full portrait is displayed cleanly.
FlushDialogTileBuffer:
	ORI	#$0700, SR
	LEA	Tile_gfx_buffer.w, A0
	MOVE.l	#$45600002, D5
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$01FF, D7
	ORI	#$0700, SR
FlushDialogTileBuffer_Done:
	MOVE.w	(A0)+, VDP_data_port
	DBF	D7, FlushDialogTileBuffer_Done
	ANDI	#$F8FF, SR
	CLR.w	Dialog_timer.w
	RTS

; --- DrawTerrainTilemap ---
; Writes the battle terrain tilemap to VDP plane B (VRAM $E000).
; Draws two halves: first at column 0 ($60000003), then at column 20
; ($60280003).  Each half is 22 rows x 20 columns.  Tile indices come
; from TerrainTilemapPtrs indexed by Terrain_tileset_index.
DrawTerrainTilemap:
	MOVE.l	#$60000003, D5
	BSR.b	DrawTerrainTilemapHelper
	MOVE.l	#$60280003, D5
DrawTerrainTilemapHelper:
	ORI	#$0700, SR
	LEA	TerrainTilemapPtrs, A0
	MOVE.w	Terrain_tileset_index.w, D0
	ANDI.w	#3, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	MOVE.w	#$0015, D7
DrawTerrainTilemapHelper_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$0013, D6
DrawTerrainTilemapHelper_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$4300, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawTerrainTilemapHelper_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, DrawTerrainTilemapHelper_Done
	ANDI	#$F8FF, SR
	RTS

; --- DrawBattleStatusBar ---
; Writes the battle status bar tilemap to VDP plane B.  6 rows x 40
; columns starting at VRAM command $6B000003.  Tile indices from
; DrawBattleStatusBar_Data are offset by $83CC (palette 2, high priority).
DrawBattleStatusBar:
	ORI	#$0700, SR
	MOVE.l	#$6B000003, D5
	LEA	DrawBattleStatusBar_Data, A0
	MOVE.w	#5, D7
DrawBattleStatusBar_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$0027, D6
DrawBattleStatusBar_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$83CC, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawBattleStatusBar_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, DrawBattleStatusBar_Done
	ANDI	#$F8FF, SR
	RTS

; --- DrawBattleNametable ---
; Writes the first-person view nametable to VDP plane A (VRAM $C000).
; 28 rows x 40 columns.  Tile indices from DrawBattleNametable_Data
; are OR'd with $8000 (high priority) and offset by $03CC.
DrawBattleNametable:
	ORI	#$0700, SR
	MOVE.l	#$40000003, D5
	LEA	DrawBattleNametable_Data, A0
	MOVE.w	#$001B, D7
DrawBattleNametable_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$0027, D6
DrawBattleNametable_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ORI.w	#$8000, D0
	ORI.w	#0, D0
	ADDI.w	#$03CC, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawBattleNametable_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, DrawBattleNametable_Done
	ANDI	#$F8FF, SR
	RTS

; ======================================================================
; Overworld Menu Input System
; ======================================================================

; --- HandleOverworldMenuInput ---
; Entry point for the overworld menu system.  Checks Start (message speed
; menu) and C (options menu) button presses to open menus.  If a menu is
; open (Overworld_menu_state != 0), dispatches to the active menu handler
; via OverworldMenuStateJumpTable.  Blocks player input while a menu is
; active.
HandleOverworldMenuInput:
	TST.w	Overworld_menu_state.w
	BNE.b	HandleOverworldMenuInput_DispatchMenu
	MOVE.w	#BUTTON_BIT_START, D2
	BSR.w	CheckButtonPress
	BEQ.b	HandleOverworldMenuInput_Loop
	MOVE.w	#OVERWORLD_MENU_STATE_MSG_SPEED, Overworld_menu_state.w	
	PlaySound_b SOUND_MENU_CURSOR	
	BRA.w	HandleOverworldMenuInput_Dispatch	
HandleOverworldMenuInput_Loop:
	MOVE.w	#BUTTON_BIT_C, D2
	BSR.w	CheckButtonPress
	BEQ.b	HandleOverworldMenuInput_DispatchMenu
	PlaySound_b SOUND_MENU_CURSOR
	MOVE.w	#OVERWORLD_MENU_STATE_OPTIONS_INIT, Overworld_menu_state.w
HandleOverworldMenuInput_DispatchMenu:
	BRA.w	HandleOverworldMenuInput_Dispatch
HandleOverworldMenuInput_Dispatch:
	TST.b	Window_tilemap_draw_active.w
	BNE.b	HandleOverworldMenuInput_Return
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.b	HandleOverworldMenuInput_Return
	MOVE.b	#FLAG_TRUE, Player_input_blocked.w
	MOVE.w	Overworld_menu_state.w, D0
	ANDI.w	#7, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	OverworldMenuStateJumpTable, A0
	JSR	(A0,D0.w)
HandleOverworldMenuInput_Return:
	RTS

; OverworldMenuStateJumpTable — BRA.w dispatch table for menu states 0-5:
;   0: Close menu (clear input block)
;   1: Message speed menu init
;   2: Message speed menu input
;   3: Options menu init
;   4: Options menu input
;   5: Execute selected option action
OverworldMenuStateJumpTable:
	BRA.w	OverworldMenuStateJumpTable_Loop
	BRA.w	OverworldMenuState0_Return_Loop	
	BRA.w	OverworldMenuMsgSpeed_HandleInput	
	BRA.w	OverworldMenuOptions_Init
	BRA.w	InitMenuCursorDefaults_Loop
	BRA.w	InitMenuCursorDefaults_ExecuteAction
OverworldMenuStateJumpTable_Loop:
	TST.b	Window_tilemap_draw_active.w
	BNE.b	OverworldMenuState0_Return
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.b	OverworldMenuState0_Return
	CLR.b	Player_input_blocked.w
OverworldMenuState0_Return:
	RTS

OverworldMenuState0_Return_Loop:
	MOVE.w	#2, Menu_cursor_column_break.w	
	MOVE.w  #MENU_CURSOR_NONE, Menu_cursor_last_index.w
	JSR	SaveMessageSpeedMenuToBuffer	
	JSR	DrawMessageSpeedMenu	
	ADDQ.w	#1, Overworld_menu_state.w	
	MOVE.w	#$000E, Menu_cursor_base_x.w	
	MOVE.w	#$000E, Menu_cursor_base_y.w	
	CLR.w	Main_menu_selection.w	
	RTS
	
OverworldMenuMsgSpeed_HandleInput:
	TST.b	Window_tilemap_draw_active.w	
	BNE.w	OverworldMenuMsgSpeed_WaitDraw	
	MOVE.w	#BUTTON_BIT_B, D2	
	BSR.w	CheckButtonPress	
	BEQ.b	OverworldMenuMsgSpeed_CheckConfirm	
	PlaySound_b SOUND_MENU_CANCEL	
	CLR.w	Overworld_menu_state.w	
	TriggerWindowRedraw WINDOW_DRAW_MSG_SPEED
	RTS
	
OverworldMenuMsgSpeed_CheckConfirm:
	MOVE.w	#BUTTON_BIT_C, D2	
	BSR.w	CheckButtonPress	
	BEQ.b	OverworldMenuMsgSpeed_MoveCursor	
	PlaySound_b SOUND_MENU_SELECT	
	MOVE.w	Main_menu_selection.w, D0	
	MOVE.b	D0, Message_speed.w	
	CLR.w	Overworld_menu_state.w	
	TriggerWindowRedraw WINDOW_DRAW_MSG_SPEED
	RTS
	
OverworldMenuMsgSpeed_MoveCursor:
	MOVE.w	Main_menu_selection.w, Menu_cursor_index.w	
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w	
	JSR	HandleMenuInput	
	MOVE.w	Menu_cursor_index.w, Main_menu_selection.w	
OverworldMenuMsgSpeed_WaitDraw:
	RTS
	
OverworldMenuOptions_Init:
	JSR	SaveMessageSpeedMenuToBuffer_Alt
	JSR	DrawOptionsMenu
	ADDQ.w	#1, Overworld_menu_state.w
	CLR.w	Main_menu_selection.w
	BSR.w	InitMenuCursorDefaults
	RTS

; --- InitMenuCursorDefaults ---
; Sets up default cursor parameters for the 8-option main menu:
; 3-item column break, 7 max index, column positions, and clears all
; sub-menu state machines (dialogue, item, equip, spellbook, etc.).
InitMenuCursorDefaults:
	MOVE.w	#3, Menu_cursor_column_break.w
	MOVE.w	#7, Menu_cursor_last_index.w
	MOVE.w	#5, Menu_cursor_second_column_x.w
	MOVE.w	#3, Menu_cursor_base_x.w
	MOVE.w	#4, Menu_cursor_base_y.w
	CLR.w	Dialogue_state.w
	CLR.w	Item_menu_state.w
	CLR.w	Equip_list_menu_state.w
	CLR.w	Spellbook_menu_state.w
	CLR.w	Ready_equipment_state.w
	CLR.w	Dialog_selection.w
	CLR.w	Open_menu_state.w
	CLR.w	Take_item_state.w
	RTS

InitMenuCursorDefaults_Loop:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	InitMenuCursorDefaults_WaitDraw
	MOVE.w	#BUTTON_BIT_B, D2
	BSR.w	CheckButtonPress
	BEQ.b	InitMenuCursorDefaults_CheckConfirm
	PlaySound_b SOUND_MENU_CANCEL
	CLR.w	Overworld_menu_state.w
	TriggerWindowRedraw WINDOW_DRAW_MSG_SPEED_ALT
	RTS

InitMenuCursorDefaults_CheckConfirm:
	MOVE.w	#BUTTON_BIT_C, D2
	BSR.w	CheckButtonPress
	BEQ.b	InitMenuCursorDefaults_MoveCursor
	PlaySound_b SOUND_MENU_SELECT
	ADDQ.w	#1, Overworld_menu_state.w
	RTS

InitMenuCursorDefaults_MoveCursor:
	MOVE.w	Main_menu_selection.w, Menu_cursor_index.w
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Main_menu_selection.w
InitMenuCursorDefaults_WaitDraw:
	RTS

InitMenuCursorDefaults_ExecuteAction:
	MOVE.w	Main_menu_selection.w, D0
	ANDI.w	#7, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	OverworldMenuActionPtrs, A0
	MOVEA.l	(A0,D0.w), A0
	JSR	(A0)
	RTS

; OverworldMenuActionPtrs — Pointer table for the 8 main menu options:
;   0: Dialogue (Talk)      4: Spellbook (Magic)
;   1: Item                 5: Ready Equipment
;   2: Equip List           6: Dialog Selection
;   3: Chest (Open)         7: Take Item
OverworldMenuActionPtrs:
	dc.l	DialogueStateMachine
	dc.l	ItemMenuStateMachine
	dc.l	EquipListMenuStateMachine
	dc.l	ChestOpeningStateMachine
	dc.l	SpellbookMenuStateMachine
	dc.l	ReadyEquipmentStateMachine
	dc.l	DialogSelectionStateMachine
	dc.l	TakeItemStateMachine

; --- GetCurrentTileType ---
; Reads the tile under the player from Tilemap_buffer_plane_b at
; Player_tilemap_offset, masks the upper 4 bits ($F000) to extract
; the tile type, and stores it in Current_tile_type.
; Tile types: TILE_TYPE_CASTLE, TILE_TYPE_EXIT, TILE_TYPE_ENTRANCE, etc.
GetCurrentTileType:
	CLR.w	Current_tile_type.w
	LEA	Tilemap_buffer_plane_b, A0
	MOVE.w	Player_tilemap_offset.w, D0
	MOVE.w	(A0,D0.w), D0
	ANDI.w	#$F000, D0
	MOVE.w	D0, Current_tile_type.w
	RTS

; --- DecrementTimerBCD ---
; Decrements a BCD countdown timer.  Each frame, decrements
; Timer_frame_counter.  When it reaches 0, resets from
; Timer_frames_per_second and performs a BCD subtract on
; Timer_seconds_bcd.  Returns D0 = -1 if time remains, D0 = 0 if expired.
DecrementTimerBCD:
	SUBQ.w	#1, Timer_frame_counter.w
	BGE.b	DecrementTimerBCD_Loop
	MOVE.w	Timer_frames_per_second.w, Timer_frame_counter.w
	MOVEQ	#0, D1
	ADDQ.w	#1, D1
	MOVE.b	Timer_seconds_bcd.w, D0
	SBCD	D1, D0
	BCS.w	DecrementTimerBCD_Expired
	MOVE.b	D0, Timer_seconds_bcd.w
DecrementTimerBCD_Loop:
	MOVEQ	#-1, D0
	RTS

DecrementTimerBCD_Expired:
	CLR.w	D0
	RTS

; GetScrollOffsetInTiles
; Get screen scroll offset in tile coordinates
; Input: $FFFFC40E (screen X), $FFFFC410 (screen Y)
; Output: D0 = X in tiles (pixels / 8), D1 = Y in tiles (pixels / 8)
GetScrollOffsetInTiles:
	MOVE.w	Camera_scroll_x.w, D0
	LSR.w	#3, D0
	MOVE.w	Camera_scroll_y.w, D1
	LSR.w	#3, D1
	RTS

; ============================================================================
; Search Town NPC Data for Player Position Match
; ============================================================================
; Searches through town NPC/interaction data to find an entry matching the
; player's current position. If found, loads associated town state data.
;
; Town Data Structure (40 bytes/$28 per entry):
;   +$00 (word): Player X position trigger
;   +$02 (word): Player Y position trigger
;   +$04-$27: Town state data (see LoadTownStateData_Store for details)
;
; Input:
;   Player_position_x_in_town, Player_position_y_in_town
;   Current_town - Town ID (0-15)
; Output:
;   If match found: Town state data loaded into RAM
; ============================================================================
; loc_00003338 - Read NPC info into town?
SearchTownNPCData:
	MOVE.w	Player_position_x_in_town.w, D0 ; D0 = player X
	MOVE.w	Player_position_y_in_town.w, D1 ; D1 = player Y
	LEA	TownNpcDataLookupJumpTable, A0                 ; A0 = town jump table
	MOVE.w	Current_town.w, D2               ; D2 = town ID
	ADD.w	D2, D2                           ; D2 *= 4
	ADD.w	D2, D2
	JSR	(A0,D2.w)                        ; Get town data array in A1
	
	; Search for position match
SearchTownNPCData_Done:
	LEA	(A1), A0                         ; A0 = current entry
	MOVE.w	(A0)+, D2                        ; D2 = entry X
	BLE.b	FindTownStateEntry_NextEntry_Loop                     ; If <= 0, end of list
	CMP.w	D2, D0                           ; X match?
	BEQ.b	SearchTownNPCData_Loop                     ; Yes: check Y
	BRA.b	FindTownStateEntry_NextEntry                     ; No: next entry
	
SearchTownNPCData_Loop:
	MOVE.w	(A0)+, D2                        ; D2 = entry Y
	CMP.w	D2, D1                           ; Y match?
	BNE.b	FindTownStateEntry_NextEntry                     ; No: next entry
	BRA.b	LoadTownStateData_Store                     ; Yes: load data
	
FindTownStateEntry_NextEntry:
	LEA	$28(A1), A1                      ; Skip to next entry
	BRA.b	SearchTownNPCData_Done
	
FindTownStateEntry_NextEntry_Loop:
	RTS                                  ; No match found
	
; --- LoadTownStateData ---
; Loads town state data for the current town by calling
; TownStateDataJumpTableStart to get the data pointer, then falls
; through to LoadTownStateData_Store to populate saved room variables.
LoadTownStateData:
	LEA	TownStateDataJumpTableStart, A0
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	JSR	(A0,D0.w)
	
	; Load town state data (40-byte structure)
LoadTownStateData_Store:
	MOVE.w	(A0)+, Saved_player_x_in_town.w      ; +$04: X in town
	MOVE.w	(A0)+, Town_player_spawn_y.w         ; +$06: Spawn Y
	MOVE.w	(A0)+, Town_saved_camera_x.w         ; +$08: Camera X
	MOVE.w	(A0)+, Saved_camera_tile_y_room1.w   ; +$0A: Camera Y
	MOVE.w	(A0)+, Saved_town_tileset_index.w    ; +$0C: Tileset
	MOVE.w	(A0)+, Saved_town_room_1.w           ; +$0E: Room 1 ID
	MOVE.l	(A0)+, Saved_town_npc_data_ptr.w     ; +$10: NPC ptr
	MOVE.w	(A0)+, Saved_player_spawn_x.w        ; +$14: Spawn X
	MOVE.w	(A0)+, Saved_player_y_room1.w        ; +$16: Player Y
	MOVE.w	(A0)+, Saved_town_room_2.w           ; +$18: Room 2 ID
	MOVE.l	(A0)+, Saved_npc_data_ptr.w          ; +$1A: NPC ptr 2
	MOVE.w	(A0)+, Saved_player_spawn_x_room2.w  ; +$1E: Spawn X 2
	MOVE.w	(A0)+, Saved_player_spawn_y_room2.w  ; +$20: Spawn Y 2
	MOVE.w	(A0)+, Saved_town_room_3.w           ; +$22: Room 3 ID
	MOVE.l	(A0), Saved_npc_data_ptr_room3.w     ; +$24: NPC ptr 3
	RTS

; --- LoadAndPlayAreaMusic ---
; Looks up the music ID for Current_town_room from AreaMusicIdByRoom.
; Special cases: Stow (room 4) plays different music depending on
; story flags; Swaffham (room $B) plays ruined music if destroyed.
; Queues the sound and saves it to Current_area_music.
LoadAndPlayAreaMusic:
	LEA	AreaMusicIdByRoom, A0
	MOVE.w	Current_town_room.w, D0
	ANDI.w	#$00FF, D0
	CMPI.w	#4, D0
	BEQ.b	LoadAndPlayAreaMusic_LookupRoom_Loop
	CMPI.w	#$B, D0
	BEQ.b	LoadAndPlayAreaMusic_CheckSwaffham
LoadAndPlayAreaMusic_LookupRoom:
	MOVE.b	(A0,D0.w), D0
	BRA.b	LoadAndPlayAreaMusic_Queue
LoadAndPlayAreaMusic_LookupRoom_Loop:
	TST.b	Stow_innocence_proven.w
	BNE.b	LoadAndPlayAreaMusic_StowInnocenceMusic
	TST.b	Girl_left_for_stow.w
	BEQ.b	LoadAndPlayAreaMusic_LookupRoom
	MOVE.w	#SOUND_STOW_MUSIC_GIRL_LEFT, D0
	BRA.b	LoadAndPlayAreaMusic_Queue
LoadAndPlayAreaMusic_StowInnocenceMusic:
	MOVE.w	#SOUND_STOW_MUSIC_INNOCENCE, D0
	BRA.b	LoadAndPlayAreaMusic_Queue
LoadAndPlayAreaMusic_CheckSwaffham:
	TST.b	Swaffham_ruined.w
	BEQ.b	LoadAndPlayAreaMusic_LookupRoom
	MOVE.w	#SOUND_SWAFFHAM_RUINED_MUSIC, D0
LoadAndPlayAreaMusic_Queue:
	MOVE.w	D0, Current_area_music.w
	JSR	QueueSoundEffect
	RTS

; --- UpdateAndDisplayCompass ---
; Wrapper: updates compass direction then displays it to VRAM.
UpdateAndDisplayCompass:
	JSR	UpdateCompassDisplay
	JSR	DisplayCompassToVRAM
	RTS

; --- DisplayKimsAndCompass ---
; Wrapper: displays kims (gold) and compass to VRAM.
DisplayKimsAndCompass:
	JSR	DisplayKimsToVRAM
	JSR	DisplayCompassToVRAM
	RTS

; --- CheckForEncounter ---
; RNG-based random encounter check.  Sets Checked_for_encounter flag,
; generates a random number, ANDs with Encounter_rate.  If result is 0,
; returns D0 = 1 (encounter triggered); otherwise returns D0 = 0.
CheckForEncounter:
	MOVE.b	#1, Checked_for_encounter.w
	JSR	GetRandomNumber
	AND.w	Encounter_rate.w, D0
	BEQ.b	CheckForEncounter_triggered
	CLR.w	D0
	RTS

CheckForEncounter_triggered:
	MOVEQ	#1, D0
	RTS

; ============================================================================
; Check Overworld Interactions
; ============================================================================
; Searches overworld interaction tables for triggers at player's current
; position and direction. Used for NPCs, signposts, special events.
;
; Entry Format (12 bytes): Sector Y, X pos, Y pos, Direction flags, Handler ptr
; Entry list terminated with $FFFF
; ============================================================================
CheckOverworldInteractions:
	MOVE.l	#NoOneHereStr, Script_talk_source.w ; Default message
	LEA	OverworldSectorInteractionPtrs, A0                     ; Interaction table base
	MOVE.w	Player_map_sector_x.w, D0            ; D0 = sector X
	ADD.w	D0, D0                               ; D0 *= 4
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0                        ; A0 = list for this sector
	
CheckOverworldInteractions_loop:
	LEA	(A0), A1                             ; A1 = current entry
	MOVE.w	(A1)+, D0                            ; D0 = sector Y
	BLT.w	CheckOverworldInteractions_end       ; If < 0, end of list
	CMP.w	Player_map_sector_y.w, D0            ; Sector Y match?
	BNE.w	CheckOverworldInteractions_next
	MOVE.w	(A1)+, D0                            ; D0 = X position
	CMP.w	Player_position_x_outside_town.w, D0 ; X match?
	BNE.w	CheckOverworldInteractions_next
	MOVE.w	(A1)+, D0                            ; D0 = Y position
	CMP.w	Player_position_y_outside_town.w, D0 ; Y match?
	BNE.w	CheckOverworldInteractions_next
	MOVE.w	(A1)+, D0                            ; D0 = direction flags
	MOVE.w	Player_direction.w, D1               ; D1 = player direction
	ASR.w	#1, D1                               ; Convert to bit index
	BTST.l	D1, D0                               ; Direction matches?
	BEQ.b	CheckOverworldInteractions_next
	MOVEA.l	(A1)+, A0                            ; A0 = handler pointer
	JMP	(A0)                                 ; Jump to handler
	
CheckOverworldInteractions_next:
	LEA	$C(A0), A0                           ; Next entry (12 bytes)
	BRA.b	CheckOverworldInteractions_loop
CheckOverworldInteractions_end:
	RTS

; ============================================================================
; Check Cave Interactions
; ============================================================================
; Searches cave interaction tables for triggers at player's current position
; and direction. Used for NPCs, treasures, and special events in caves.
;
; Entry Format (10 bytes): X pos, Y pos, Direction flags, Handler ptr
; Entry list terminated with $FFFF
; ============================================================================
CheckCaveInteractions:
	LEA	CaveRoomInteractionPtrs, A0                     ; Cave interaction table base
	MOVE.w	Current_cave_room.w, D0              ; D0 = cave room ID
	ADD.w	D0, D0                               ; D0 *= 4
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0                        ; A0 = list for this cave
	
CheckCaveInteractions_loop:
	LEA	(A0), A1                             ; A1 = current entry
	MOVE.w	(A1)+, D0                            ; D0 = X position
	BLT.w	CheckCaveInteractions_end            ; If < 0, end of list
	CMP.w	Player_position_x_outside_town.w, D0 ; X match?
	BNE.b	CheckCaveInteractions_next
	MOVE.w	(A1)+, D0                            ; D0 = Y position
	CMP.w	Player_position_y_outside_town.w, D0 ; Y match?
	BNE.b	CheckCaveInteractions_next
	MOVE.w	(A1)+, D0                            ; D0 = direction flags
	MOVE.w	Player_direction.w, D1               ; D1 = player direction
	ASR.w	#1, D1                               ; Convert to bit index
	BTST.l	D1, D0                               ; Direction matches?
	BEQ.b	CheckCaveInteractions_next
	MOVEA.l	(A1)+, A0                            ; A0 = handler pointer
	JMP	(A0)                                 ; Jump to handler
	
CheckCaveInteractions_next:
	LEA	$A(A0), A0                           ; Next entry (10 bytes)
	BRA.b	CheckCaveInteractions_loop
	
CheckCaveInteractions_end:
	MOVE.l	#NoOneHereStr, Script_talk_source.w  ; Default message
	RTS

; --- InitializeTownMode ---
; Full town mode reset used after resurrection or teleport.  Clears all
; enemy entities, resets player object, loads graphics, clears VRAM,
; and sets spawn position from town data tables.  Special redirects:
;   - Excalabria -> Swaffham (if not ruined) or Helwig (if ruined)
;   - Carthahena -> Hastings
; Then calls SearchTownNPCData to load building data for the church.
InitializeTownMode:
	BSR.w	ClearAllEnemyEntities
	JSR	InitMenuObjects
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	#DIRECTION_UP, Player_direction.w
	MOVE.l	#PlayerObjectHandler, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BCLR.b	#7, (A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BCLR.b	#7, (A6)
	JSR	LoadPlayerOverworldGraphics
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	JSR	ClearScrollData
	CLR.w	Saved_player_x_in_town.w
	CLR.b	Is_boss_battle.w
	CLR.b	Boss_max_hp.w
	CLR.b	Is_in_battle.w
	CLR.b	Is_in_cave.w
	CLR.b	Player_in_first_person_mode.w
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_EXCALABRIA, D0
	BNE.b	InitializeTownMode_check_swaffham
	MOVE.w	#TOWN_SWAFFHAM, Current_town.w
	MOVE.w	Current_town.w, D0
InitializeTownMode_check_swaffham:
	CMPI.w	#TOWN_SWAFFHAM, D0
	BNE.b	InitializeTownMode_check_town_0f
	TST.b	Swaffham_ruined.w
	BEQ.b	InitializeTownMode_spawn_setup
	MOVE.w	#TOWN_HELWIG, Current_town.w
	BRA.b	InitializeTownMode_spawn_setup
InitializeTownMode_check_town_0f:
	CMPI.w	#TOWN_CARTHAHENA, D0
	BNE.b	InitializeTownMode_spawn_setup
	MOVE.w	#TOWN_HASTINGS1, Current_town.w	
InitializeTownMode_spawn_setup:
	MOVE.w	Current_town.w, D0
	ASL.w	#3, D0
	LEA	TownSpawnPositionData, A0
	LEA	(A0,D0.w), A0
	MOVE.w	(A0)+, Town_spawn_x.w
	MOVE.w	(A0)+, Player_spawn_tile_y_buffer.w
	MOVE.w	(A0)+, Town_camera_initial_x.w
	MOVE.w	(A0), Town_default_camera_y.w
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	TownPlayerPositionData, A0
	LEA	(A0,D0.w), A0
	MOVE.w	(A0)+, Player_position_x_in_town.w
	MOVE.w	(A0)+, Player_position_y_in_town.w
	MOVE.w	Current_town.w, D0
	ASL.w	#3, D0
	LEA	TownTeleportLocationData, A0
	MOVE.w	(A0,D0.w), Player_position_x_outside_town.w
	MOVE.w	$2(A0,D0.w), Player_position_y_outside_town.w
	MOVE.w	$4(A0,D0.w), Player_map_sector_x.w
	MOVE.w	$6(A0,D0.w), Player_map_sector_y.w
	BSR.w	SearchTownNPCData
	LEA	TownSavedPositionData, A0
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), Saved_player_x_in_town.w
	MOVE.w	$2(A0,D0.w), Town_player_spawn_y.w
	RTS

; --- UpdatePlayerOverworldPosition ---
; Adjusts the player's overworld X/Y position by the offset corresponding
; to their current facing direction, using DirectionOffsets_GateEntry.
; Called after battles and cave exits to step the player forward.
UpdatePlayerOverworldPosition:
	LEA	DirectionOffsets_GateEntry, A0
	MOVE.w	Player_direction.w, D0
	ANDI.w	#6, D0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), D1
	ADD.w	D1, Player_position_x_outside_town.w
	MOVE.w	$2(A0,D0.w), D1
	ADD.w	D1, Player_position_y_outside_town.w
	RTS

; DirectionOffsets_GateEntry — 4 entries of (dx, dy) word pairs.
; Used by UpdatePlayerOverworldPosition.  Offsets are +-2 tiles.
DirectionOffsets_GateEntry: ; Going through gates or entering caves?
	dc.w	  0,  -2		; Up
	dc.w	 -2,   0		; Left
	dc.w	  0,   2		; Down
	dc.w	  2,   0		; Right
; DirectionOffsets_16Pixel — 4 entries of (dx, dy) word pairs.
; Used by floor transition exit handlers to offset player position
; by 16 pixels in the current direction.
DirectionOffsets_16Pixel:
	dc.w	  0,  16		; Up
	dc.w	 16,   0		; Left
	dc.w	  0, -16		; Down
	dc.w	-16,   0		; Right

