; ======================================================================
; src/states.asm
; Program state machine: Sega logo, title, name entry, prologue init
; ======================================================================
ProgramState_SegaLogoInit:
	MOVE.b	#2, Timer_seconds_bcd.w
	MOVE.l	#SegaLogoScreen_Init, vobj_hblank_fn(A5)
	MOVE.w	#PROGRAM_STATE_SEGA_LOGO, Program_state.w
	CLR.b	Intro_animation_done.w
	RTS

ProgramState_SegaLogo
	MOVE.b	Controller_current_state.w, D0
	ANDI.b	#$F0, D0
	BNE.b	ProgramState_00_Loop
	TST.b	Intro_animation_done.w
	BEQ.b	ProgramState_01_Return
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.l	#HBlankObjectHandler, vobj_hblank_fn(A5)
	BSR.w	DecrementTimerBCD
	BNE.b	ProgramState_01_Return
ProgramState_00_Loop:
	MOVE.w	#PROGRAM_STATE_TITLE_INIT, Program_state.w
	CLR.b	Fade_out_lines_mask.w
	CLR.w	Palette_fade_step_counter.w
	MOVE.w	#0, Palette_line_0_index.w
	JSR	LoadPalettesFromTable
ProgramState_01_Return:
	RTS

ProgramState_TitleInit:
	MOVE.b	#$45, Timer_seconds_bcd.w
	BTST.b	#6, IO_version
	BEQ.b	ProgramState_02_Loop
	MOVE.b	#$37, Timer_seconds_bcd.w	
ProgramState_02_Loop:
	MOVE.l	#TitleScreen_Init, vobj_hblank_fn(A5)
	MOVE.w	#PROGRAM_STATE_TITLE_SCREEN, Program_state.w
	CLR.b	Title_intro_complete.w
	RTS

ProgramState_TitleScreen:
	TST.b	Title_intro_complete.w
	BEQ.w	ProgramState_03_Return
	TST.b	Window_tilemap_draw_active.w
	BNE.w	ProgramState_03_Return
	CheckButton BUTTON_BIT_START
	BEQ.w	ProgramState_03_Loop
	TST.w	Dialog_selection.w
	BEQ.b	ProgramState_03_Loop2
	MOVE.w	#PROGRAM_STATE_LOAD_SAVE_INIT, Program_state.w
	BRA.b	ProgramState_03_Loop3
ProgramState_03_Loop2:
	MOVE.w	#PROGRAM_STATE_NAME_ENTRY_INIT, Program_state.w
ProgramState_03_Loop3:
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	RTS

ProgramState_03_Loop:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	BSR.w	DecrementTimerBCD
	BNE.b	ProgramState_03_Return
	MOVE.w	#PROGRAM_STATE_TITLE_DEMO, Program_state.w
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	RTS

ProgramState_03_Return:
	RTS

ProgramState_TitleDemo:
	TST.b	Fade_out_lines_mask.w
	BNE.b	ProgramState_04_Loop
	MOVE.w	#SOUND_LEVEL_UP, D0
	JSR	QueueSoundEffect
	CLR.w	Program_state.w
	CLR.b	Scene_update_flag.w
	JSR	ClearScrollData
	JSR	ClearEnemyActiveFlags
	MOVE.l	#HBlankObjectHandler, vobj_hblank_fn(A5)
ProgramState_04_Loop:
	RTS

ProgramState_PrologueInit:
	TST.b	Fade_out_lines_mask.w
	BNE.b	ProgramState_08_Loop
	JSR	LoadTitleScreenGraphics
	MOVE.l	#PrologueScreen_Init, vobj_hblank_fn(A5)
	MOVE.w	#PROGRAM_STATE_PROLOGUE, Program_state.w
	CLR.b	Prologue_complete_flag.w
ProgramState_08_Loop:
	RTS

ProgramState_Prologue:
	TST.b	Prologue_complete_flag.w
	BEQ.b	ProgramState_09_Loop
	MOVE.w	#PROGRAM_STATE_PROLOGUE_TO_GAME, Program_state.w
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
ProgramState_09_Loop:
	RTS

ProgramState_PrologueToGame:
	TST.b	Fade_out_lines_mask.w
	BNE.b	ProgramState_0A_Loop
	JSR	Prologue_EmptyCallback
	MOVE.l	#HBlankObjectHandler, vobj_hblank_fn(A5)
	MOVE.w	#PROGRAM_STATE_GAME_FADE_IN, Program_state.w
	CLR.w	Current_town.w
	MOVE.w	#8, Player_position_x_outside_town.w
	MOVE.w	#$D, Player_position_y_outside_town.w
	MOVE.w	#0, Player_map_sector_x.w
	MOVE.w	#6, Player_map_sector_y.w
	MOVE.w	#SOUND_LEVEL_UP, D0
	JSR	QueueSoundEffect
ProgramState_0A_Loop:
	RTS

ProgramState_LoadSaveInit:
	TST.b	Fade_out_lines_mask.w
	BNE.b	ProgramState_0B_Loop
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	JSR	ClearScrollData
	JSR	ClearEnemyActiveFlags
	MOVE.w	VDP_Reg11_cache.w, D0
	ANDI.w	#$FFF8, D0
	MOVE.w	D0, VDP_control_port
	MOVE.l	#FileMenuPhaseDispatch, vobj_hblank_fn(A5)
	CLR.w	File_menu_phase.w
	CLR.b	File_load_complete.w
	MOVE.w	#PALETTE_IDX_TOWN_TILES, Palette_line_0_index.w
	MOVE.w	#PROGRAM_STATE_LOAD_SAVE, Program_state.w
	MOVE.w	#SOUND_NAME_ENTRY, D0
	JSR	QueueSoundEffect
	JSR	LoadPalettesFromTable
ProgramState_0B_Loop:
	RTS

ProgramState_LoadSave:
	TST.b	File_load_complete.w
	BEQ.b	ProgramState_0C_Loop
	MOVE.w	#PROGRAM_STATE_LOAD_SAVE_DONE, Program_state.w	
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w	
ProgramState_0C_Loop:
	RTS

ProgramState_LoadSaveDone:
	TST.b	Fade_out_lines_mask.w	
	BNE.b	ProgramState_0D_Loop	
	MOVE.l	#HBlankObjectHandler, vobj_hblank_fn(A5)	
	MOVE.w	#PROGRAM_STATE_LOAD_SAVED_GAME, Program_state.w	
	MOVE.w	#SOUND_LEVEL_UP, D0	
	JSR	QueueSoundEffect	
ProgramState_0D_Loop:
	RTS
	
ProgramState_LoadSavedGame:
	TST.b	Fade_out_lines_mask.w	
	BNE.b	ProgramState_15_Loop	
	MOVE.w	#TOWN_SPRITE_TILE_BASE, Town_vram_tile_base.w	
	BSR.w	ClearAllEnemyEntities
	CLR.b	Player_in_first_person_mode.w	
	CLR.b	Is_in_cave.w	
	CLR.b	Cave_light_active.w	
	CLR.w	Cave_light_timer.w	
	BSR.w	InitializeTownMode	
	MOVE.w	#PROGRAM_STATE_GAME_FADE_IN, Program_state.w ; Transition to main game?	
	MOVE.w	#GAMEPLAY_STATE_INIT_BUILDING_ENTRY, Gameplay_state.w 	 ; Entering building/town?
	MOVE.w	Saved_town_room_1.w, Current_town_room.w	
	JSR	LoadAndPlayAreaMusic	
ProgramState_15_Loop:
	RTS
	
ProgramState_NameEntryInit:
	TST.b	Fade_out_lines_mask.w
	BNE.b	ProgramState_05_Loop
	JSR	DisableVDPDisplay
	CLR.b	Scene_update_flag.w
	JSR	ClearScrollData
	JSR	ClearEnemyActiveFlags
	MOVE.w	VDP_Reg11_cache.w, D0
	ANDI.w	#$FFF8, D0
	MOVE.w	D0, VDP_control_port
	JSR	LoadOptionsMenuGraphics
	JSR	EnableDisplay
	MOVE.l	#NameEntryScreen_Init, vobj_hblank_fn(A5)
	MOVE.w	#PROGRAM_STATE_NAME_ENTRY, Program_state.w
	CLR.b	Name_entry_complete.w
	MOVE.b	#SOUND_NAME_ENTRY, D0
	JSR	QueueSoundEffect
ProgramState_05_Loop:
	RTS

ProgramState_NameEntry:
	TST.b	Name_entry_complete.w
	BEQ.b	ProgramState_06_Loop
	MOVE.w	#PROGRAM_STATE_NAME_ENTRY_DONE, Program_state.w
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
ProgramState_06_Loop:
	RTS

ProgramState_NameEntryDone:
	TST.b	Fade_out_lines_mask.w
	BNE.b	ProgramState_07_Loop
	JSR	ClearEnemyListFlags
	MOVE.l	#HBlankObjectHandler, vobj_hblank_fn(A5)
	MOVE.w	#PROGRAM_STATE_PROLOGUE_INIT, Program_state.w
	MOVE.w	#SOUND_LEVEL_UP, D0
	JSR	QueueSoundEffect
ProgramState_07_Loop:
	RTS

ProgramState_EndingInit:
	MOVE.l	#EndingSequence_Init, vobj_hblank_fn(A5)
	MOVE.w	#PROGRAM_STATE_ENDING, Program_state.w
	RTS

ProgramState_Ending:
	RTS

ProgramState_GameFadeIn:
	TST.b	Fade_out_lines_mask.w
	BNE.w	ProgramState_0E_and_10_Loop
	JSR	DisableVDPDisplay
	MOVEA.l	Player_entity_ptr.w, A6
	BSET.b	#7, (A6)
	ADDQ.w	#1, Program_state.w
	MOVE.b	#1, Message_speed.w
ProgramState_0E_and_10_Loop:
	RTS

ProgramState_GameActive:
	TST.b	Player_is_moving.w
	BNE.b	ProgramState_0F_Return
	TST.b	Camera_scrolling_active.w
	BNE.b	ProgramState_0F_Return
	MOVE.w	Gameplay_state.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	GameStateMap, A0
	JSR	(A0,D0.w)
ProgramState_0F_Return:
	RTS

; $FFFFC410 - $FFFFC414
GameStateMap:
	BRA.w	GameState_InitTownEntry ; $00
	BRA.w	GameState_LoadTown ; $01 Exiting building
	BRA.w	GameState_TownExploration ; $02 In town
	BRA.w	GameState_InitBuildingEntry ; $03 Entering building
	BRA.w	GameState_BuildingInterior ; $04 Inside building
	BRA.w	GameState_TransitionToSecondFloor ; $05 Going upstairs/downstairs in church
	BRA.w	GameState_SecondFloorActive ; $06 Upstairs in church
	BRA.w	GameState_TransitionToThirdFloor ; $07 Going on 2nd floor in church
	BRA.w	GameState_ThirdFloorActive ; $08 Being on second floor in church
	BRA.w	GameState_TransitionToCastleMain ; $09 Entering castle
	BRA.w	GameState_CastleRoom1Active ; $0A Entering castle #2
	BRA.w	GameState_LoadCastleRoom2 ; $0B Inside castle
	BRA.w	GameState_CastleRoom2Active ; $0C 
	BRA.w	GameState_LoadCastleRoom3 ; $0D 	
	BRA.w	GameState_CaveEntrance ; $0E Enter cave
	BRA.w	GameState_BattleInitialize ; $0F Battle
	BRA.w	GameState_BattleActive ; $10 Overworld?
	BRA.w	GameState_BattleExit ; $11 Exit town
	BRA.w	GameState_OverworldReload ; $12 Exit town #2
	BRA.w	GameState_OverworldActive ; $13 Outside town
	BRA.w	GameState_TownFadeInComplete ; $14 Entering town
	BRA.w	GameState_EnteringCave ; $15 Entering cave #2
	BRA.w	GameState_CaveExploration ; $16 Inside cave
	BRA.w	GameState_CaveFadeOutComplete ; $17 Exiting cave
	BRA.w	GameState_EncounterInitialize ; $18 Encounter
	BRA.w	GameState_EncounterGraphicsFadeIn ; $19 
	BRA.w	GameState_EncounterPauseBeforeBattle ; $1A 
	BRA.w	GameState_LevelUpBannerDisplay ; $1B Start showing stats
	BRA.w	GameState_LevelUpStatsWaitInput ; $1C 
	BRA.w	GameState_LevelUpComplete ; $1D 
	BRA.w	GameState_ReturnToFirstPersonView ; $1E Walk forward (Maybe just walk?)
	BRA.w	GameState_FadeInComplete ; $1F Loading/initialization of town or building
	BRA.w	GameState_DialogDisplay ; $20 Finding chest/character
	BRA.w	GameState_BossBattleInit ; $21 
	BRA.w	GameState_BossBattleActive ; $22 
	BRA.w	GameState_ReturnFromBossBattle ; $23 Reload town?
	BRA.w	GameState_BeginResurrection ; $24 Resurrect in church
	BRA.w	GameState_ProcessResurrection ; $25 Resurrect in church #2
	BRA.w	GameState_NotifyInaudiosExpired ; $26 Inaudios wear off
	BRA.w	GameState_WaitForNotificationDismiss ; $27 
	BRA.w	GameState_ReadAwakeningMessage ; $28 
	BRA.w	GameState_FryingPanDelay ; $29 Get hit by frying pan message
	BRA.w	GameState_ReadFryingPanMessage ; $2A 
	BRA.w	GameState_SoldierTaunt ; $2B "You haven't won yet"
	BRA.w	GameState_ReadSoldierTaunt ; $2C 
	BRA.w	GameState_ShowPoisonNotification ; $2D Get poisoned messsage

