; ======================================================================
; src/gameplay.asm
; Gameplay state machine: town, overworld, cave, battle, encounter states
; ======================================================================
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
	BLT.b	GameState_LoadTown_Loop2
	SUBQ.w	#1, D0
GameState_LoadTown_Loop2:
	CMPI.w	#TOWN_KELTWICK, D0
	BLT.b	GameState_LoadTown_Loop3
	SUBQ.w	#1, D0
GameState_LoadTown_Loop3:
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
	BNE.b	GameState_LoadTown_Loop4
	JSR	LoadAndPlayAreaMusic
GameState_LoadTown_Loop4:
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
	BRA.b	GameState_InitTownEntry_NormalPalette_Loop2
GameState_InitTownEntry_NormalPalette:
	MOVE.w	#PALETTE_IDX_TOWN_TILES, Palette_line_0_fade_target.w
GameState_InitTownEntry_NormalPalette_Loop2:
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

GameState_FadeInComplete:
	TST.b	Fade_in_lines_mask.w
	BNE.b	GameState_FadeInComplete_Loop
	MOVE.w	Saved_game_state.w, Gameplay_state.w
GameState_FadeInComplete_Loop:
	RTS

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
	BEQ.b	GameState_TownExploration_Loop2
	MOVE.w	Gameplay_state.w, Saved_game_state.w	
	BSR.w	SavePlayerTownPosition	
	MOVE.w	#GAMEPLAY_STATE_BOSS_BATTLE_INIT, Gameplay_state.w	
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w	
	RTS
	
GameState_TownExploration_Loop2:
	BSR.w	GetCurrentTileType
	CMPI.w	#TILE_TYPE_CASTLE, Current_tile_type.w
	BEQ.b	GameState_TownExploration_Loop3
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w
	BEQ.b	GameState_TownExploration_Loop4
	CMPI.w	#TILE_TYPE_ENTRANCE, Current_tile_type.w
	BEQ.w	GameState_TownExploration_Loop5
	BRA.w	HandleOverworldMenuInput
GameState_TownExploration_Loop3:
	MOVE.b	#SOUND_TRANSITION, D0
	JSR	QueueSoundEffect
	MOVE.w	#SOUND_LEVEL_UP, D0
	JSR	QueueSoundEffect
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.w	#GAMEPLAY_STATE_TRANSITION_TO_CASTLE_MAIN, Gameplay_state.w
	BRA.w	GameState_TownExploration_Loop6
GameState_TownExploration_Loop4:
	MOVE.b	#SOUND_TRANSITION, D0
	JSR	QueueSoundEffect
	MOVE.w	#SOUND_LEVEL_UP, D0
	JSR	QueueSoundEffect
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.w	#GAMEPLAY_STATE_OVERWORLD_RELOAD, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Player_is_moving.w
	RTS

GameState_TownExploration_Loop5:
	MOVE.b	#SOUND_TRANSITION, D0
	JSR	QueueSoundEffect
	MOVE.w	#SOUND_LEVEL_UP, D0
	JSR	QueueSoundEffect
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	ADDQ.w	#1, Gameplay_state.w
GameState_TownExploration_Loop6:
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

SavePlayerTownPosition:
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), Town_spawn_x.w
	MOVE.w	obj_world_y(A6), Player_spawn_tile_y_buffer.w
	MOVE.w	Town_camera_tile_x.w, Town_camera_initial_x.w
	MOVE.w	Town_camera_tile_y.w, Town_default_camera_y.w
	RTS

GameState_InitBuildingEntry:
	TST.b	Fade_out_lines_mask.w
	BNE.b	GameState_InitBuildingEntry_Loop
	JSR	DisableVDPDisplay
	JSR	LoadBattleHudGraphics
	JSR	LoadTownBattleGraphics
	TST.w	Saved_player_x_in_town.w
	BGT.b	GameState_InitBuildingEntry_Loop2
	BSR.w	SearchTownNPCData
	MOVE.w	Saved_town_room_1.w, Current_town_room.w
	JSR	LoadAndPlayAreaMusic
GameState_InitBuildingEntry_Loop2:
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
	MOVE.b	#SOUND_SLEEP, D0
	JSR	QueueSoundEffect
	MOVE.w	#GAMEPLAY_STATE_FRYING_PAN_DELAY, Gameplay_state.w
	RTS

GameState_BuildingInterior_NoBossEvent:
	TST.b	Boss_event_trigger.w
	BEQ.b	GameState_BuildingInterior_NoBossEvent_Loop2
	MOVEA.l	Player_entity_ptr.w, A6	
	MOVE.w	obj_world_x(A6), Saved_player_x_in_town.w	
	MOVE.w	obj_world_y(A6), Town_player_spawn_y.w	
	MOVE.w	Town_camera_tile_x.w, Town_saved_camera_x.w	
	MOVE.w	Town_camera_tile_y.w, Saved_camera_tile_y_room1.w	
	MOVE.w	Gameplay_state.w, Saved_game_state.w	
	MOVE.w	#GAMEPLAY_STATE_BOSS_BATTLE_INIT, Gameplay_state.w	
	MOVE.w	#SOUND_LEVEL_UP, D0	
	JSR	QueueSoundEffect	
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w	
	RTS
	
GameState_BuildingInterior_NoBossEvent_Loop2:
	BSR.w	GetCurrentTileType
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w
	BEQ.b	GameState_BuildingInterior_NoBossEvent_Loop3
	CMPI.w	#TILE_TYPE_ENTRANCE, Current_tile_type.w
	BEQ.b	GameState_BuildingInterior_NoBossEvent_Loop4
	BRA.w	HandleOverworldMenuInput
GameState_BuildingInterior_NoBossEvent_Loop3:
	MOVE.b	#SOUND_TRANSITION, D0
	JSR	QueueSoundEffect
	MOVE.w	#SOUND_LEVEL_UP, D0
	JSR	QueueSoundEffect
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.w	#GAMEPLAY_STATE_LOAD_TOWN, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Player_is_moving.w
	MOVE.w	#DIRECTION_DOWN, Player_direction.w
	RTS

GameState_BuildingInterior_NoBossEvent_Loop4:
	MOVE.b	#SOUND_TRANSITION, D0
	JSR	QueueSoundEffect
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
	BEQ.b	GameState_BuildingInterior_NoBossEvent_Loop5
	PRINT 	CarelessWarningStr	
	CLR.b	Frying_pan_knockout_flag.w	
	BRA.b	GameState_AwakeningMessage_SetState	
GameState_BuildingInterior_NoBossEvent_Loop5:
	TST.b	Banshee_powder_active.w
	BNE.b	GameState_AwakeningMessage_SetState
	PRINT 	AriseWarriorStr
GameState_AwakeningMessage_SetState:
	MOVE.w	#GAMEPLAY_STATE_READ_AWAKENING_MESSAGE, Gameplay_state.w
	RTS

GameState_ReadAwakeningMessage:
	TST.b	Script_text_complete.w
	BEQ.b	GameState_ReadAwakening_Dismiss_Loop
	TST.b	Script_has_continuation.w
	BNE.b	GameState_ReadAwakening_Dismiss_Loop2
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	GameState_ReadAwakening_Dismiss
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
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

GameState_ReadAwakening_Dismiss_Loop2:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.b	GameState_ReadAwakening_Dismiss_Loop3
	JSR	InitDialogueWindow
GameState_ReadAwakening_Dismiss_Loop3:
	RTS

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
	MOVE.w	#SOUND_SPELL_CAST, D0	
	JSR	QueueSoundEffect	
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
	BLT.w	GameState_FryingPanDelay_Return_Loop2	
	LEA	EquipmentToStatModifierMap, A0	
	ANDI.w	#$00FF, D1	
	ADD.w	D1, D1	
	MOVE.w	(A0,D1.w), Player_str.w	
GameState_FryingPanDelay_Return_Loop2:
	MOVE.w	Equipped_shield.w, D1	
	BLT.w	GameState_FryingPanDelay_Return_Loop3	
	LEA	EquipmentToStatModifierMap, A0	
	ANDI.w	#$FF, D1	
	ADD.w	D1, D1	
	MOVE.w	(A0,D1.w), Player_ac.w	
GameState_FryingPanDelay_Return_Loop3:
	MOVE.w	Equipped_armor.w, D1	
	BLT.w	GameState_FryingPanDelay_Return_Loop4	
	LEA	EquipmentToStatModifierMap, A0	
	ANDI.w	#$FF, D1	
	ADD.w	D1, D1	
	MOVE.w	(A0,D1.w), D1	
	ADD.w	D1, Player_ac.w	
GameState_FryingPanDelay_Return_Loop4:
	JSR	UpgradeLevelStats	
	RTS
	
GameState_ReadFryingPanMessage:
	TST.b	Script_text_complete.w
	BEQ.b	GameState_ReadFryingPan_Dismiss_Loop
	TST.b	Script_has_continuation.w
	BNE.w	GameState_ReadFryingPan_Dismiss_Loop2
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	GameState_ReadFryingPan_Dismiss
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	GameState_ReadFryingPan_Dismiss
	RTS

GameState_ReadFryingPan_Dismiss:
	JSR	DrawStatusHudWindow
	CLR.w	Overworld_menu_state.w
	MOVE.w	#WINDOW_DRAW_MSG_SPEED_ALT, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	MOVE.w	#GAMEPLAY_STATE_BUILDING_INTERIOR, Gameplay_state.w
	RTS

GameState_ReadFryingPan_Dismiss_Loop2:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.b	GameState_ReadFryingPan_Dismiss_Loop3
	JSR	InitDialogueWindow
GameState_ReadFryingPan_Dismiss_Loop:
	JSR	ProcessScriptText
GameState_ReadFryingPan_Dismiss_Loop3:
	RTS

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

GameState_SecondFloorActive:
	BSR.w	GetCurrentTileType
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w
	BEQ.b	GameState_SecondFloorActive_Loop
	CMPI.w	#TILE_TYPE_ENTRANCE, Current_tile_type.w
	BEQ.w	GameState_SecondFloorActive_Loop2
	BRA.w	HandleOverworldMenuInput
GameState_SecondFloorActive_Loop:
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.b	#SOUND_TRANSITION, D0
	JSR	QueueSoundEffect
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

GameState_SecondFloorActive_Loop2:
	MOVE.b	#SOUND_TRANSITION, D0
	JSR	QueueSoundEffect
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	ADDQ.w	#1, Gameplay_state.w
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), Saved_player_spawn_x.w
	MOVE.w	obj_world_y(A6), D0
	ADDI.w	#$0010, D0
	MOVE.w	D0, Saved_player_y_room1.w
	RTS

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

GameState_ThirdFloorActive:
	BSR.w	GetCurrentTileType
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w
	BEQ.b	GameState_ThirdFloorActive_Loop
	BRA.w	HandleOverworldMenuInput
GameState_ThirdFloorActive_Loop:
	MOVE.b	#SOUND_TRANSITION, D0
	JSR	QueueSoundEffect
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w
	BNE.w	HandleOverworldMenuInput
	MOVE.w	#GAMEPLAY_STATE_TRANSITION_TO_SECOND_FLOOR, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Player_is_moving.w
	MOVE.w	#DIRECTION_DOWN, Player_direction.w
	RTS

GameState_TransitionToCastleMain:
	TST.b	Fade_out_lines_mask.w
	BNE.b	GameState_TransitionToCastleMain_Loop
	JSR	DisableVDPDisplay
	JSR	LoadBattleHudGraphics
	JSR	LoadWorldBattleGraphics
	TST.w	Saved_player_x_in_town.w
	BGT.b	GameState_TransitionToCastleMain_Loop2
	BSR.w	LoadTownStateData
	MOVE.w	Saved_town_room_1.w, Current_town_room.w
	JSR	LoadAndPlayAreaMusic
GameState_TransitionToCastleMain_Loop2:
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
	MOVE.w	#SOUND_LEVEL_UP, D0
	JSR	QueueSoundEffect
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	RTS

GameState_CastleRoom1Active_Loop:
	BSR.w	GetCurrentTileType
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w
	BEQ.b	GameState_CastleRoom1Active_Loop2
	CMPI.w	#TILE_TYPE_ENTRANCE, Current_tile_type.w
	BEQ.w	GameState_CastleRoom1Active_Loop3
	BRA.w	HandleOverworldMenuInput
GameState_CastleRoom1Active_Loop2:
	MOVE.b	#SOUND_TRANSITION, D0
	JSR	QueueSoundEffect
	MOVE.w	#SOUND_LEVEL_UP, D0
	JSR	QueueSoundEffect
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.w	#GAMEPLAY_STATE_LOAD_TOWN, Gameplay_state.w
	CLR.w	Saved_player_x_in_town.w
	MOVE.b	#FLAG_TRUE, Player_is_moving.w
	MOVE.w	#DIRECTION_DOWN, Player_direction.w
	RTS

GameState_CastleRoom1Active_Loop3:
	MOVE.b	#SOUND_TRANSITION, D0
	JSR	QueueSoundEffect
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

GameState_CastleRoom2Active:
	BSR.w	GetCurrentTileType
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w
	BEQ.b	GameState_CastleRoom2Active_Loop
	CMPI.w	#TILE_TYPE_ENTRANCE, Current_tile_type.w
	BEQ.b	GameState_CastleRoom2Active_Loop2
	BRA.w	HandleOverworldMenuInput
GameState_CastleRoom2Active_Loop:
	MOVE.b	#SOUND_TRANSITION, D0
	JSR	QueueSoundEffect
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

GameState_CastleRoom2Active_Loop2:
	MOVE.b	#SOUND_TRANSITION, D0	
	JSR	QueueSoundEffect	
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w	
	ADDQ.w	#1, Gameplay_state.w	
	MOVEA.l	Player_entity_ptr.w, A6	
	MOVE.w	obj_world_x(A6), Saved_player_spawn_x.w	
	MOVE.w	obj_world_y(A6), D0	
	ADDI.w	#$0010, D0	
	MOVE.w	D0, Saved_player_y_room1.w	
	RTS
	
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
	
GameState_CaveEntrance:
	BSR.w	GetCurrentTileType	
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w	
	BNE.w	HandleOverworldMenuInput	
	MOVE.b	#SOUND_TRANSITION, D0	
	JSR	QueueSoundEffect	
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w	
	CMPI.w	#TILE_TYPE_EXIT, Current_tile_type.w	
	BNE.w	HandleOverworldMenuInput	
	MOVE.w	#GAMEPLAY_STATE_LOAD_CASTLE_ROOM2, Gameplay_state.w	
	MOVE.b	#FLAG_TRUE, Player_is_moving.w	
	MOVE.w	#DIRECTION_DOWN, Player_direction.w	
	RTS
	
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
	BLT.b	GameState_BattleInitialize_Loop2
	ANDI.w	#$00FF, D0
	JSR	LoadMagicGraphics
GameState_BattleInitialize_Loop2:
	JSR	DisplayPlayerMaxHpMp
	JSR	DisplayReadiedMagicName
	CLR.b	Player_in_first_person_mode.w
	MOVE.b	#SOUND_BATTLE_START, D0
	JSR	QueueSoundEffect
	JSR	LoadPalettesFromTable
	JSR	EnableDisplay
GameState_BattleInitialize_Loop:
	RTS

GameState_BattleActive:
	JSR	DisplayPlayerHpMp
	TST.w	Player_hp.w
	BGT.b	GameState_BattleActive_Loop
	TST.b	Bully_first_fight_won.w
	BNE.b	GameState_BattleActive_Loop2
	CLR.b	Soldier_fight_event_trigger.w
GameState_BattleActive_Loop2:
	MOVE.w	#SOUND_SPELL_CAST, D0
	JSR	QueueSoundEffect
	MOVE.w	#GAMEPLAY_STATE_BEGIN_RESURRECTION, Gameplay_state.w
	MOVE.b	#8, Fade_out_lines_mask.w
	CLR.w	Player_hp.w
	JSR	DisplayPlayerHpMp
GameState_BattleActive_Loop:
	RTS

GameState_BattleExit:
	TST.w	Player_hp.w
	BGT.b	GameState_BattleExit_Loop
	TST.b	Bully_first_fight_won.w	
	BNE.b	GameState_BattleExit_Loop2	
	CLR.b	Soldier_fight_event_trigger.w	
GameState_BattleExit_Loop2:
	MOVE.w	#SOUND_SPELL_CAST, D0	
	JSR	QueueSoundEffect	
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
	BEQ.b	GameState_BattleExit_Loop3
	CLR.b	Soldier_fight_event_trigger.w
	MOVE.b	#FLAG_TRUE, Bully_first_fight_won.w
	MOVE.b	#FLAG_TRUE, Skip_town_intro_after_fight.w
	BRA.w	GameState_ReturnFromBossBattle
GameState_BattleExit_Loop3:
	TST.b	Is_in_cave.w
	BNE.b	GameState_BattleExit_Loop4
	MOVE.w	#GAMEPLAY_STATE_OVERWORLD_RELOAD, Gameplay_state.w
	BRA.b	GameState_BattleExit_Loop5
GameState_BattleExit_Loop4:
	MOVE.w	#GAMEPLAY_STATE_ENTERING_CAVE, Gameplay_state.w
GameState_BattleExit_Loop5:
	JSR	ClearAllEnemyEntities
	CLR.w	Sprite_attr_count.w
	JSR	FlushSpriteAttributesToVDP
	MOVE.b	#FLAG_TRUE, Player_in_first_person_mode.w
GameState_BeginResurrection_Return:
	RTS

GameState_SoldierTaunt:
	JSR	ClearScrollData
	MOVE.b	#FLAG_TRUE, Player_input_blocked.w
	PRINT 	YouHaveNotWonYetStr
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#GAMEPLAY_STATE_READ_SOLDIER_TAUNT, Gameplay_state.w
	RTS

GameState_ReadSoldierTaunt:
	TST.b	Script_text_complete.w
	BEQ.b	GameState_ReadSoldierTaunt_Dismiss_Loop
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	GameState_ReadSoldierTaunt_Dismiss
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	GameState_ReadSoldierTaunt_Dismiss
	RTS

GameState_ReadSoldierTaunt_Dismiss:
	MOVE.w	#GAMEPLAY_STATE_BATTLE_EXIT, Gameplay_state.w
	MOVE.b	#SOUND_TRANSITION, D0
	JSR	QueueSoundEffect
	MOVE.w	#SOUND_LEVEL_UP, D0
	JSR	QueueSoundEffect
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	RTS

GameState_ReadSoldierTaunt_Dismiss_Loop:
	JSR	ProcessScriptText
	RTS

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

GameState_OverworldActive:
	BRA.w	GameState_CaveExploration
GameState_TownFadeInComplete:
	TST.b	Fade_out_lines_mask.w
	BNE.b	GameState_TownFadeInComplete_Loop
	CLR.b	Player_in_first_person_mode.w
	MOVE.w	#SOUND_LEVEL_UP, D0
	JSR	QueueSoundEffect
	MOVE.w	#GAMEPLAY_STATE_INIT_TOWN_ENTRY, Gameplay_state.w
GameState_TownFadeInComplete_Loop:
	RTS

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
	BEQ.b	GameState_EnteringCave_Loop2
	MOVE.w	#PALETTE_IDX_CAVE_FLOOR_LIT, Palette_line_1_index.w
	MOVE.w	#PALETTE_IDX_CAVE_ANIM_BASE, Palette_line_2_index.w
	JSR	LoadPalettesFromTable
GameState_EnteringCave_Loop2:
	JSR	EnableDisplay
	MOVE.w	#ENCOUNTER_RATE_CAVE, Encounter_rate.w
	BSR.w	CheckLevelUpAndRestoreMusic
GameState_EnteringCave_Loop:
	RTS

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
	MOVE.b	#SOUND_LEVEL_UP_BANNER, D0
	JSR	QueueSoundEffect
	ADDQ.w	#1, Player_level.w
	JSR	UpgradeLevelStats
	MOVE.w	#100, Level_up_timer.w
	JSR	SavePromptMenuToBuffer
	JSR	LoadLevelUpBannerTiles
	BRA.b	GameState_LevelUpComplete_Check_Loop
GameState_LevelUpComplete_Check:
	TST.b	Is_in_cave.w
	BEQ.b	GameState_LevelUpComplete_Check_Loop2
	BSR.w	PlayCaveMusic
	BRA.b	GameState_LevelUpComplete_Check_Loop3
GameState_LevelUpComplete_Check_Loop2:
	MOVE.b	#SOUND_OVERWORLD_MUSIC, D0
	MOVE.w	D0, Current_area_music.w
	JSR	QueueSoundEffect
GameState_LevelUpComplete_Check_Loop3:
	CLR.b	Player_input_blocked.w
GameState_LevelUpComplete_Check_Loop:
	JSR	DisplayPlayerHpMp
	JSR	DisplayPlayerMaxHpMp
	JSR	DisplayPlayerKimsAndExperience
	JSR	DisplayReadiedMagicName
	RTS

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
	BEQ.b	GameState_CaveExploration_CheckDeath_Loop2
	MOVE.w	Gameplay_state.w, Saved_game_state.w
	MOVE.w	#GAMEPLAY_STATE_BOSS_BATTLE_INIT, Gameplay_state.w
	MOVE.w	#SOUND_LEVEL_UP, D0
	JSR	QueueSoundEffect
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	RTS

GameState_CaveExploration_CheckDeath_Loop2: ; process movement actions in overworld
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
	BEQ.w	GameState_CaveExploration_CheckDeath_Loop3
	BSR.w	CheckCaveInteractions
	BRA.b	GameState_CaveExploration_CheckDeath_Loop4
GameState_CaveExploration_CheckDeath_Loop3:
	BSR.w	CheckOverworldInteractions
GameState_CaveExploration_CheckDeath_Loop4:
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
	BRA.b	GameState_EncounterInitialize_Loop2
GameState_EncounterInitialize_Loop:
	LEA	EnemyEncounterTypesByCaveRoom, A0
	MOVE.w	Current_cave_room.w, D0
	MOVE.b	(A0,D0.w), Encounter_group_index.w
GameState_EncounterInitialize_Loop2:
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	MOVE.w	D0, Random_number.w
	JSR	LoadEncounterTypeGraphics
	MOVE.l	#$45600002, D7
	MOVE.w	#$03FF, D6
	MOVE.b	#0, D5
	MOVE.w	#1, D4
	JSR	VDP_DMAFill
	MOVEA.l	Current_actor_ptr.w, A6
	BSET.b	#7, (A6)
	MOVE.l	#InitEncounterPortrait, obj_tick_fn(A6)
	MOVE.w	#GAMEPLAY_STATE_ENCOUNTER_GRAPHICS_FADE_IN, Gameplay_state.w
	CLR.w	Dialog_timer.w
	CLR.w	Dialog_phase.w
	CLR.b	Chest_already_opened.w
	MOVE.w	#SOUND_ENCOUNTER_START, D0
	JSR	QueueSoundEffect
	RTS

GameState_EncounterGraphicsFadeIn:
	ADDQ.w	#1, Dialog_timer.w
	MOVE.w	Dialog_timer.w, D0
	BTST.b	#6, $00A10001
	BNE.b	GameState_EncounterGraphicsFadeIn_Loop
	ANDI.w	#7, D0
	BNE.b	GameState_EncounterGraphicsFadeIn_Return
	BRA.b	GameState_EncounterGraphicsFadeIn_Loop2
GameState_EncounterGraphicsFadeIn_Loop:
	ANDI.w	#3, D0	
	BNE.b	GameState_EncounterGraphicsFadeIn_Return	
GameState_EncounterGraphicsFadeIn_Loop2:
	CMPI.w	#ENCOUNTER_FADE_PHASES, Dialog_phase.w
	BLT.b	GameState_EncounterGraphicsFadeIn_Loop3
	BSR.w	FlushDialogTileBuffer
	MOVE.w	#GAMEPLAY_STATE_ENCOUNTER_PAUSE_BEFORE_BATTLE, Gameplay_state.w
	BRA.b	GameState_EncounterGraphicsFadeIn_Return
GameState_EncounterGraphicsFadeIn_Loop3:
	BSR.w	UpdateDialogTileColumn
GameState_EncounterGraphicsFadeIn_Return:
	RTS

GameState_EncounterPauseBeforeBattle:
	ADDQ.w	#1, Dialog_timer.w
	CMPI.w	#ENCOUNTER_PAUSE_FRAMES, Dialog_timer.w
	BLE.b	GameState_EncounterPauseBeforeBattle_Loop
	MOVE.w	#GAMEPLAY_STATE_BATTLE_INITIALIZE, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
GameState_EncounterPauseBeforeBattle_Loop:
	RTS

GameState_LevelUpBannerDisplay:
	SUBQ.w	#1, Level_up_timer.w
	BGT.b	GameState_LevelUpBannerDisplay_Loop
	MOVE.w	#GAMEPLAY_STATE_LEVEL_UP_STATS_WAIT_INPUT, Gameplay_state.w
	JSR	SaveFullDialogAreaToBuffer
	JSR	DrawCharacterStatsWindow
GameState_LevelUpBannerDisplay_Loop:
	RTS

GameState_LevelUpStatsWaitInput:
	TST.b	Window_tilemap_draw_active.w
	BNE.b	GameState_LevelUpStats_Dismiss_Loop
	MOVE.w	#BUTTON_BIT_A, D2
	JSR	CheckButtonPress
	BNE.b	GameState_LevelUpStats_Dismiss
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	GameState_LevelUpStats_Dismiss
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	GameState_LevelUpStats_Dismiss
	RTS

GameState_LevelUpStats_Dismiss:
	MOVE.w	#WINDOW_DRAW_SCRIPT, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	MOVE.w	#GAMEPLAY_STATE_LEVEL_UP_COMPLETE, Gameplay_state.w
GameState_LevelUpStats_Dismiss_Loop:
	RTS

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
	MOVE.b	#SOUND_LEVEL_UP_BANNER, D0
	JSR	QueueSoundEffect
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
	BEQ.b	GameState_LevelUpComplete_Exit_Loop2
	BSR.w	PlayCaveMusic
	RTS

GameState_LevelUpComplete_Exit_Loop2:
	MOVE.w	D0, Current_area_music.w
	JSR	QueueSoundEffect
GameState_LevelUpComplete_Exit_Loop:
	RTS

GameState_ReturnToFirstPersonView:
	TST.b	Fade_out_lines_mask.w
	BNE.b	GameState_ReturnToFirstPersonView_Loop
	BSR.w	UpdatePlayerOverworldPosition
	JSR	InitFirstPersonView
	MOVE.w	#GAMEPLAY_STATE_CAVE_EXPLORATION, Gameplay_state.w
	MOVE.w	#PALETTE_IDX_CAVE_WALLS, Palette_line_0_index.w
	TST.b	Cave_light_active.w
	BEQ.b	GameState_ReturnToFirstPersonView_Loop2
	MOVE.w	#PALETTE_IDX_CAVE_FLOOR_LIT, Palette_line_1_index.w
	MOVE.w	#PALETTE_IDX_CAVE_ANIM_BASE, Palette_line_2_index.w
GameState_ReturnToFirstPersonView_Loop2:
	MOVE.w	#SOUND_OVERWORLD_RETURN, D0
	JSR	QueueSoundEffect
	MOVE.w	#PALETTE_IDX_TOWN_HUD, Palette_line_3_index.w
	CLR.b	Encounter_triggered.w
	CLR.b	Chest_already_opened.w
	CLR.w	Overworld_menu_state.w
	BCLR.b	#0, Player_direction_flags.w
	JSR	LoadPalettesFromTable
GameState_ReturnToFirstPersonView_Loop:
	RTS

GameState_DialogDisplay:
	ADDQ.w	#1, Dialog_timer.w
	MOVE.w	Dialog_timer.w, D0
	BTST.b	#6, $00A10001
	BNE.w	GameState_DialogDisplay_Loop
	ANDI.w	#7, D0
	BNE.b	GameState_DialogDisplay_Return
	BRA.b	GameState_DialogDisplay_Loop2
GameState_DialogDisplay_Loop:
	ANDI.w	#3, D0	
	BNE.b	GameState_DialogDisplay_Return	
GameState_DialogDisplay_Loop2:
	CMPI.w	#ENCOUNTER_FADE_PHASES, Dialog_phase.w
	BLT.b	GameState_DialogDisplay_Loop3
	CLR.b	Dialog_state_flag.w
	BSR.w	FlushDialogTileBuffer
	MOVE.w	Saved_game_state.w, Gameplay_state.w
	BRA.b	GameState_DialogDisplay_Return
GameState_DialogDisplay_Loop3:
	BSR.w	UpdateDialogTileColumn
GameState_DialogDisplay_Return:
	RTS

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
	BNE.b	GameState_BossBattleInit_Loop2
	ADDQ.w	#1, D0
	DBF	D7, GameState_BossBattleInit_Done
GameState_BossBattleInit_Loop2:
	CLR.b	Boss_event_trigger.w
	CLR.b	-$2(A0)
	MOVE.w	D0, Battle_type.w
	LEA	Boss_battle_flags.w, A0
	MOVE.w	#3, D7
GameState_BossBattleInit_Loop2_Done:
	CLR.l	(A0)+
	DBF	D7, GameState_BossBattleInit_Loop2_Done
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

GameState_BossBattleActive:
	BSR.w	CheckPlayerDeath
	JSR	DisplayCurrentHpMp
	RTS

GameState_ReturnFromBossBattle:
	BSR.w	CheckPlayerDeath
	BEQ.b	GameState_ReturnFromBossBattle_Loop
	RTS
	
GameState_ReturnFromBossBattle_Loop:
	TST.b	Fade_out_lines_mask.w
	BNE.w	GameState_ReturnFromBossBattle_Loop2
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
	BNE.b	GameState_ReturnFromBossBattle_Loop3
	MOVE.w	Current_area_music.w, D0
	JSR	QueueSoundEffect
	BRA.b	GameState_ReturnFromBossBattle_Loop4
GameState_ReturnFromBossBattle_Loop3:
	MOVE.b	#FLAG_TRUE, Player_in_first_person_mode.w
GameState_ReturnFromBossBattle_Loop4:
	JSR	EnableDisplay
GameState_ReturnFromBossBattle_Loop2:
	RTS

GameState_BeginResurrection:
	TST.b	Fade_out_lines_mask.w
	BNE.b	GameState_BeginResurrection_Loop
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	ADDQ.w	#1, Gameplay_state.w
GameState_BeginResurrection_Loop:
	RTS

GameState_ProcessResurrection:
	TST.b	Fade_out_lines_mask.w
	BNE.w	GameState_ProcessResurrection_Loop
	BSR.w	ClearAllEnemyEntities
	CLR.b	Player_in_first_person_mode.w
	CLR.b	Is_in_cave.w
	CLR.b	Cave_light_active.w
	CLR.w	Cave_light_timer.w
	TST.b	Player_greatly_poisoned.w
	BNE.b	GameState_ProcessResurrection_Loop2
	CLR.w	Player_poisoned.w
GameState_ProcessResurrection_Loop2: ; ressurected in church?
	MOVE.w	Player_mhp.w, Player_hp.w
	MOVE.w	Player_mmp.w, Player_mp.w
	TST.b	Banshee_powder_active.w
	BNE.w	GameState_ProcessResurrection_Loop3
	LEA	Player_kims.w, A0
	CLR.l	D2
	MOVE.w	#3, D4
GameState_ProcessResurrection_Loop2_Done:
	CLR.l	D0
	MOVE.b	(A0), D0
	CLR.l	D1
	MOVE.b	D0, D1
	ANDI.b	#$F0, D1
	BEQ.b	GameState_ProcessResurrection_Loop4
	LSR.b	#4, D1
	DIVU.w	#2, D1
GameState_ProcessResurrection_Loop4:
	TST.w	D2
	BEQ.b	GameState_ProcessResurrection_Loop5
	ADDQ.w	#5, D1
GameState_ProcessResurrection_Loop5:
	CLR.l	D2
	MOVE.l	D1, D2
	SWAP	D2
	LSL.b	#4, D1
	CLR.l	D3
	MOVE.b	D0, D3
	ANDI.b	#$0F, D3
	BEQ.b	GameState_ProcessResurrection_Loop6
	DIVU.w	#2, D3
GameState_ProcessResurrection_Loop6:
	TST.w	D2
	BEQ.b	GameState_ProcessResurrection_Loop7
	ADDQ.w	#5, D3
GameState_ProcessResurrection_Loop7:
	CLR.l	D2
	MOVE.l	D3, D2
	SWAP	D2
	OR.b	D1, D3
	MOVE.b	D3, (A0)+
	DBF	D4, GameState_ProcessResurrection_Loop2_Done
GameState_ProcessResurrection_Loop3:
	BSR.w	InitializeTownMode
	MOVE.w	#GAMEPLAY_STATE_INIT_BUILDING_ENTRY, Gameplay_state.w
	MOVE.w	Saved_town_room_1.w, Current_town_room.w
	JSR	LoadAndPlayAreaMusic
	MOVE.b	#FLAG_TRUE, Player_awakening_flag.w
GameState_ProcessResurrection_Loop:
	RTS

GameState_NotifyInaudiosExpired:
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	PRINT 	InaudiosWornOffStr
	MOVE.w	#GAMEPLAY_STATE_WAIT_FOR_NOTIFICATION_DISMISS, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Player_input_blocked.w
	RTS

GameState_ShowPoisonNotification:
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	PRINT 	PoisonedStr
	MOVE.w	#GAMEPLAY_STATE_WAIT_FOR_NOTIFICATION_DISMISS, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Player_input_blocked.w
	MOVE.b	#FLAG_TRUE, Poison_notified.w
	RTS

GameState_WaitForNotificationDismiss:
	TST.b	Window_tilemap_draw_pending.w
	BNE.b	GameState_WaitNotification_Dismiss_Loop
	TST.b	Script_text_complete.w
	BEQ.b	GameState_WaitNotification_Dismiss_Loop2
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	GameState_WaitNotification_Dismiss
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	GameState_WaitNotification_Dismiss
	RTS

GameState_WaitNotification_Dismiss:
	JSR	DrawStatusHudWindow
	MOVE.w	#GAMEPLAY_STATE_OVERWORLD_ACTIVE, Gameplay_state.w
	CLR.b	Player_input_blocked.w
GameState_WaitNotification_Dismiss_Loop2:
	JSR	ProcessScriptText
GameState_WaitNotification_Dismiss_Loop:
	RTS

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
TownPlayerPositionData:
	dc.w	$20, $12, $27, $21 
	dc.w	$D, $B, $1C, $E 
	dc.w	$A, $1B, $A, $1B
	dc.w	$1A, $19, $27, $21 
	dc.w	$F, $D, $A, $18
	dc.w	$20, $20, $1B, $E
	dc.w	$1B, $E, $20, $12
	dc.w	$20, $12, $20, $12 
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
	dc.w	$7, $7, $1, $0 ; TOWN_SWAFHAM
	dc.w	$A, $5, $5, $2 ; TOWN_EXCALABRIA
	dc.w	$5, $4, $9, $2 ; TOWN_HASTINGS1
	dc.w	$5, $4, $9, $2 ; TOWN_HASTINGS2
	dc.w	$8, $8, $A, $5 ; TOWN_CARTHAHENA
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

CheckPlayerDeath:
	TST.w	Player_hp.w
	BGT.b	CheckPlayerDeath_Loop
	MOVE.w	#SOUND_SPELL_CAST, D0
	JSR	QueueSoundEffect
	MOVE.w	#GAMEPLAY_STATE_BEGIN_RESURRECTION, Gameplay_state.w
	MOVE.b	#8, Fade_out_lines_mask.w
	MOVE.w	#$FFFF, D0
	CLR.w	Player_hp.w
	RTS

CheckPlayerDeath_Loop:
	CLR.w	D0
	RTS

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

HandleOverworldMenuInput:
	TST.w	Overworld_menu_state.w
	BNE.b	HandleOverworldMenuInput_DispatchMenu
	MOVE.w	#BUTTON_BIT_START, D2
	BSR.w	CheckButtonPress
	BEQ.b	HandleOverworldMenuInput_Loop
	MOVE.w	#OVERWORLD_MENU_STATE_MSG_SPEED, Overworld_menu_state.w	
	MOVE.b	#SOUND_MENU_CURSOR, D0	
	JSR	QueueSoundEffect	
	BRA.w	HandleOverworldMenuInput_Dispatch	
HandleOverworldMenuInput_Loop:
	MOVE.w	#BUTTON_BIT_C, D2
	BSR.w	CheckButtonPress
	BEQ.b	HandleOverworldMenuInput_DispatchMenu
	MOVE.b	#SOUND_MENU_CURSOR, D0
	JSR	QueueSoundEffect
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

OverworldMenuStateJumpTable:
	BRA.w	OverworldMenuStateJumpTable_Loop
	BRA.w	OverworldMenuState0_Return_Loop	
	BRA.w	OverworldMenuState0_Return_Loop2	
	BRA.w	OverworldMenuState0_Return_Loop3
	BRA.w	InitMenuCursorDefaults_Loop
	BRA.w	InitMenuCursorDefaults_Loop2
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
	
OverworldMenuState0_Return_Loop2:
	TST.b	Window_tilemap_draw_active.w	
	BNE.w	OverworldMenuState0_Return_Loop4	
	MOVE.w	#BUTTON_BIT_B, D2	
	BSR.w	CheckButtonPress	
	BEQ.b	OverworldMenuState0_Return_Loop5	
	MOVE.b	#SOUND_MENU_CANCEL, D0	
	JSR	QueueSoundEffect	
	CLR.w	Overworld_menu_state.w	
	MOVE.w	#WINDOW_DRAW_MSG_SPEED, Window_draw_type.w	
	CLR.w	Window_text_row.w	
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w	
	RTS
	
OverworldMenuState0_Return_Loop5:
	MOVE.w	#BUTTON_BIT_C, D2	
	BSR.w	CheckButtonPress	
	BEQ.b	OverworldMenuState0_Return_Loop6	
	MOVE.b	#SOUND_MENU_SELECT, D0	
	JSR	QueueSoundEffect	
	MOVE.w	Main_menu_selection.w, D0	
	MOVE.b	D0, Message_speed.w	
	CLR.w	Overworld_menu_state.w	
	MOVE.w	#WINDOW_DRAW_MSG_SPEED, Window_draw_type.w	
	CLR.w	Window_text_row.w	
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w	
	RTS
	
OverworldMenuState0_Return_Loop6:
	MOVE.w	Main_menu_selection.w, Menu_cursor_index.w	
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w	
	JSR	HandleMenuInput	
	MOVE.w	Menu_cursor_index.w, Main_menu_selection.w	
OverworldMenuState0_Return_Loop4:
	RTS
	
OverworldMenuState0_Return_Loop3:
	JSR	SaveMessageSpeedMenuToBuffer_Alt
	JSR	DrawOptionsMenu
	ADDQ.w	#1, Overworld_menu_state.w
	CLR.w	Main_menu_selection.w
	BSR.w	InitMenuCursorDefaults
	RTS

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
	BNE.w	InitMenuCursorDefaults_Loop3
	MOVE.w	#BUTTON_BIT_B, D2
	BSR.w	CheckButtonPress
	BEQ.b	InitMenuCursorDefaults_Loop4
	MOVE.b	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	CLR.w	Overworld_menu_state.w
	MOVE.w	#WINDOW_DRAW_MSG_SPEED_ALT, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	RTS

InitMenuCursorDefaults_Loop4:
	MOVE.w	#BUTTON_BIT_C, D2
	BSR.w	CheckButtonPress
	BEQ.b	InitMenuCursorDefaults_Loop5
	MOVE.b	#SOUND_MENU_SELECT, D0
	JSR	QueueSoundEffect
	ADDQ.w	#1, Overworld_menu_state.w
	RTS

InitMenuCursorDefaults_Loop5:
	MOVE.w	Main_menu_selection.w, Menu_cursor_index.w
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Main_menu_selection.w
InitMenuCursorDefaults_Loop3:
	RTS

InitMenuCursorDefaults_Loop2:
	MOVE.w	Main_menu_selection.w, D0
	ANDI.w	#7, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	OverworldMenuActionPtrs, A0
	MOVEA.l	(A0,D0.w), A0
	JSR	(A0)
	RTS

OverworldMenuActionPtrs:
	dc.l	DialogueStateMachine
	dc.l	ItemMenuStateMachine
	dc.l	EquipListMenuStateMachine
	dc.l	ChestOpeningStateMachine
	dc.l	SpellbookMenuStateMachine
	dc.l	ReadyEquipmentStateMachine
	dc.l	DialogSelectionStateMachine
	dc.l	TakeItemStateMachine

GetCurrentTileType:
	CLR.w	Current_tile_type.w
	LEA	Tilemap_buffer_plane_b, A0
	MOVE.w	Player_tilemap_offset.w, D0
	MOVE.w	(A0,D0.w), D0
	ANDI.w	#$F000, D0
	MOVE.w	D0, Current_tile_type.w
	RTS

DecrementTimerBCD:
	SUBQ.w	#1, Timer_frame_counter.w
	BGE.b	DecrementTimerBCD_Loop
	MOVE.w	Timer_frames_per_second.w, Timer_frame_counter.w
	MOVEQ	#0, D1
	ADDQ.w	#1, D1
	MOVE.b	Timer_seconds_bcd.w, D0
	SBCD	D1, D0
	BCS.w	DecrementTimerBCD_Loop2
	MOVE.b	D0, Timer_seconds_bcd.w
DecrementTimerBCD_Loop:
	MOVEQ	#-1, D0
	RTS

DecrementTimerBCD_Loop2:
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

LoadAndPlayAreaMusic:
	LEA	AreaMusicIdByRoom, A0
	MOVE.w	Current_town_room.w, D0
	ANDI.w	#$00FF, D0
	CMPI.w	#4, D0
	BEQ.b	LoadAndPlayAreaMusic_LookupRoom_Loop
	CMPI.w	#$B, D0
	BEQ.b	LoadAndPlayAreaMusic_LookupRoom_Loop2
LoadAndPlayAreaMusic_LookupRoom:
	MOVE.b	(A0,D0.w), D0
	BRA.b	LoadAndPlayAreaMusic_Queue
LoadAndPlayAreaMusic_LookupRoom_Loop:
	TST.b	Stow_innocence_proven.w
	BNE.b	LoadAndPlayAreaMusic_LookupRoom_Loop3
	TST.b	Girl_left_for_stow.w
	BEQ.b	LoadAndPlayAreaMusic_LookupRoom
	MOVE.w	#SOUND_STOW_MUSIC_GIRL_LEFT, D0
	BRA.b	LoadAndPlayAreaMusic_Queue
LoadAndPlayAreaMusic_LookupRoom_Loop3:
	MOVE.w	#SOUND_STOW_MUSIC_INNOCENCE, D0
	BRA.b	LoadAndPlayAreaMusic_Queue
LoadAndPlayAreaMusic_LookupRoom_Loop2:
	TST.b	Swaffham_ruined.w
	BEQ.b	LoadAndPlayAreaMusic_LookupRoom
	MOVE.w	#SOUND_SWAFFHAM_RUINED_MUSIC, D0
LoadAndPlayAreaMusic_Queue:
	MOVE.w	D0, Current_area_music.w
	JSR	QueueSoundEffect
	RTS

UpdateAndDisplayCompass:
	JSR	UpdateCompassDisplay
	JSR	DisplayCompassToVRAM
	RTS

DisplayKimsAndCompass:
	JSR	DisplayKimsToVRAM
	JSR	DisplayCompassToVRAM
	RTS

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
	MOVE.w	#TOWN_SWAFHAM, Current_town.w
	MOVE.w	Current_town.w, D0
InitializeTownMode_check_swaffham:
	CMPI.w	#TOWN_SWAFHAM, D0
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

DirectionOffsets_GateEntry: ; Going through gates or entering caves?
	dc.w	  0,  -2		; Up
	dc.w	 -2,   0		; Left
	dc.w	  0,   2		; Down
	dc.w	  2,   0		; Right
DirectionOffsets_16Pixel:
	dc.w	  0,  16		; Up
	dc.w	 16,   0		; Left
	dc.w	  0, -16		; Down
	dc.w	-16,   0		; Right

