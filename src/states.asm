; ======================================================================
; src/states.asm
; Program state machine: Sega logo, title, name entry, prologue init
;
; PATTERN — fade-out gate (DRY-008):
;   The following two-instruction idiom appears at the top of every
;   transition state handler (states $03, $04, $08, $0A, $0B, $0D,
;   $0F, $15, and others in gameplay.asm):
;
;       TST.b   Fade_out_lines_mask.w
;       BNE.b   <StateLabel_Loop>       ; return if fade still running
;       ; ... one-shot init work ...
;   <StateLabel_Loop>:
;       RTS
;
;   This is a "wait for the previous screen's fade-out to complete before
;   doing setup" guard.  The VBlank handler decrements Fade_out_lines_mask
;   each frame until it reaches zero.  Cannot be extracted to a macro
;   without breaking bit-perfect output (instruction encoding would change).
;   Documented here for reader orientation.
;
; PATTERN — state completion gate (DRY-009):
;   Three "blocker" handlers wait for an async flag before advancing state:
;     ProgramState_Prologue    — waits for Prologue_complete_flag
;     ProgramState_LoadSave    — waits for File_load_complete
;     ProgramState_NameEntry   — waits for Name_entry_complete
;
;   All three now use the AdvanceStateOnComplete macro (macros.asm), which
;   expands to the identical 20-byte / 5-instruction sequence and is
;   bit-perfect.
; ======================================================================


; ProgramState_SegaLogoInit — $00 PROGRAM_STATE_SEGA_LOGO_INIT
; One-shot initialization of the Sega logo screen.
; Sets a 2-second BCD timer, installs SegaLogoScreen_Init as the
; HBlank handler (which loads and animates the logo), then advances
; Program_state to PROGRAM_STATE_SEGA_LOGO ($01).
ProgramState_SegaLogoInit:
	MOVE.b	#2, Timer_seconds_bcd.w
	MOVE.l	#SegaLogoScreen_Init, vobj_hblank_fn(A5)
	MOVE.w	#PROGRAM_STATE_SEGA_LOGO, Program_state.w
	CLR.b	Intro_animation_done.w
	RTS

ProgramState_SegaLogo
	MOVE.b	Controller_current_state.w, D0
	ANDI.b	#CONTROLLER_ACTION_BUTTONS_MASK, D0
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

; ProgramState_TitleInit — $02 PROGRAM_STATE_TITLE_INIT
; One-shot initialization of the title screen.
; Sets idle timer to $45 BCD seconds ($37 on PAL hardware detected via
; IO_version bit 6).  Installs TitleScreen_Init as the HBlank handler,
; advances to PROGRAM_STATE_TITLE_SCREEN ($03), and clears
; Title_intro_complete to gate input until animation finishes.
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

; ProgramState_TitleScreen — $03 PROGRAM_STATE_TITLE_SCREEN
; Per-frame handler for the title menu (New Game / Continue).
; Blocks until Title_intro_complete is set and window DMA has settled.
; On START press:
;   Dialog_selection == 0 → new game → PROGRAM_STATE_NAME_ENTRY_INIT ($05)
;   Dialog_selection != 0 → load game → PROGRAM_STATE_LOAD_SAVE_INIT ($0B)
; Both branches set Fade_out_lines_mask to begin the fade transition.
; If the idle timer expires (no input), advances to PROGRAM_STATE_TITLE_DEMO ($04).
; Otherwise, routes controller input through HandleMenuInput to move the cursor.
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

; ProgramState_TitleDemo — $04 PROGRAM_STATE_TITLE_DEMO
; Demo/attract loop entered after the title idle timer expires.
; Waits for the current fade-out to complete, then plays the level-up
; sound (used as a jingle), resets Program_state to $00
; (PROGRAM_STATE_SEGA_LOGO_INIT) to restart the intro sequence, clears
; scrolling state and enemy flags, and restores the default HBlank handler.
ProgramState_TitleDemo:
	TST.b	Fade_out_lines_mask.w
	BNE.b	ProgramState_04_Loop
	PlaySound	SOUND_LEVEL_UP
	CLR.w	Program_state.w
	CLR.b	Scene_update_flag.w
	JSR	ClearScrollData
	JSR	ClearEnemyActiveFlags
	MOVE.l	#HBlankObjectHandler, vobj_hblank_fn(A5)
ProgramState_04_Loop:
	RTS

; ProgramState_PrologueInit — $08 PROGRAM_STATE_PROLOGUE_INIT
; One-shot initialization of the story prologue sequence.
; Waits for current fade-out, then loads the title-screen tile graphics
; (reused as prologue background), installs PrologueScreen_Init as the
; HBlank handler, advances to PROGRAM_STATE_PROLOGUE ($09), and clears
; Prologue_complete_flag so the prologue handler waits for completion.
ProgramState_PrologueInit:
	TST.b	Fade_out_lines_mask.w
	BNE.b	ProgramState_08_Loop
	JSR	LoadTitleScreenGraphics
	MOVE.l	#PrologueScreen_Init, vobj_hblank_fn(A5)
	MOVE.w	#PROGRAM_STATE_PROLOGUE, Program_state.w
	CLR.b	Prologue_complete_flag.w
ProgramState_08_Loop:
	RTS

; ProgramState_Prologue — $09 PROGRAM_STATE_PROLOGUE
; Per-frame handler while the story prologue is playing.
; Blocks until Prologue_complete_flag is set (set by PrologueScreen_Init
; animation driver when the text scroll finishes).
; On completion: advances to PROGRAM_STATE_PROLOGUE_TO_GAME ($0A) and
; triggers a fade-out.
ProgramState_Prologue:
	AdvanceStateOnComplete Prologue_complete_flag, PROGRAM_STATE_PROLOGUE_TO_GAME

; ProgramState_PrologueToGame — $0A PROGRAM_STATE_PROLOGUE_TO_GAME
; Transition handler: prologue complete → main game start.
; Waits for fade-out, then:
;   - Calls Prologue_EmptyCallback (no-op placeholder)
;   - Restores default HBlank handler
;   - Advances to PROGRAM_STATE_GAME_FADE_IN ($0E)
;   - Sets initial overworld position: town 0, sector (0,6), tile (8,13)
;   - Plays level-up sound (jingle)
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
	PlaySound	SOUND_LEVEL_UP
ProgramState_0A_Loop:
	RTS

; ProgramState_LoadSaveInit — $0B PROGRAM_STATE_LOAD_SAVE_INIT
; One-shot initialization of the file select / continue screen.
; Waits for fade-out, then clears VRAM planes, scroll data, and enemy
; flags.  Resets VDP window scroll, installs FileMenuPhaseDispatch as
; the HBlank handler (drives the save-file menu), clears File_menu_phase
; and File_load_complete, loads town-tile palettes, advances to
; PROGRAM_STATE_LOAD_SAVE ($0C), and plays the name-entry music.
ProgramState_LoadSaveInit:
	TST.b	Fade_out_lines_mask.w
	BNE.b	ProgramState_0B_Loop
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	JSR	ClearScrollData
	JSR	ClearEnemyActiveFlags
	MOVE.w	VDP_Reg11_cache.w, D0
	ANDI.w	#VDP_REG11_WINDOW_CLEAR_MASK, D0
	MOVE.w	D0, VDP_control_port
	MOVE.l	#FileMenuPhaseDispatch, vobj_hblank_fn(A5)
	CLR.w	File_menu_phase.w
	CLR.b	File_load_complete.w
	MOVE.w	#PALETTE_IDX_TOWN_TILES, Palette_line_0_index.w
	MOVE.w	#PROGRAM_STATE_LOAD_SAVE, Program_state.w
	PlaySound	SOUND_NAME_ENTRY
	JSR	LoadPalettesFromTable
ProgramState_0B_Loop:
	RTS

; ProgramState_LoadSave — $0C PROGRAM_STATE_LOAD_SAVE
; Per-frame handler for the file select menu.
; Blocks until File_load_complete is set (by FileMenuPhaseDispatch when
; the player selects a save slot and the load finishes).
; On completion: advances to PROGRAM_STATE_LOAD_SAVE_DONE ($0D) and
; triggers a fade-out.
ProgramState_LoadSave:
	AdvanceStateOnComplete File_load_complete, PROGRAM_STATE_LOAD_SAVE_DONE

; ProgramState_LoadSaveDone — $0D PROGRAM_STATE_LOAD_SAVE_DONE
; Transition: file-select complete → saved game load.
; Waits for fade-out, then restores the default HBlank handler, advances
; to PROGRAM_STATE_LOAD_SAVED_GAME ($15), and plays the level-up jingle.
ProgramState_LoadSaveDone:
	TST.b	Fade_out_lines_mask.w	
	BNE.b	ProgramState_0D_Loop	
	MOVE.l	#HBlankObjectHandler, vobj_hblank_fn(A5)	
	MOVE.w	#PROGRAM_STATE_LOAD_SAVED_GAME, Program_state.w	
	PlaySound	SOUND_LEVEL_UP	
ProgramState_0D_Loop:
	RTS
	
; ProgramState_LoadSavedGame — $15 PROGRAM_STATE_LOAD_SAVED_GAME
; Restores a saved game and transitions to the main game.
; Waits for fade-out, then:
;   - Sets Town_vram_tile_base to TOWN_SPRITE_TILE_BASE
;   - Clears all enemy entities, first-person mode, cave state
;   - Calls InitializeTownMode to set up the town environment
;   - Advances Program_state to PROGRAM_STATE_GAME_FADE_IN ($0E)
;   - Sets Gameplay_state to GAMEPLAY_STATE_INIT_BUILDING_ENTRY ($03)
;     so the player resumes inside the last saved town/building
;   - Restores Current_town_room from Saved_town_room_1
;   - Starts area music via LoadAndPlayAreaMusic
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
	
; ProgramState_NameEntryInit — $05 PROGRAM_STATE_NAME_ENTRY_INIT
; One-shot initialization of the name entry screen.
; Waits for fade-out, then:
;   - Disables VDP display, clears scroll/enemy state
;   - Resets VDP window scroll
;   - Loads the options-menu tile graphics (shared with name entry)
;   - Re-enables display, installs NameEntryScreen_Init as HBlank handler
;   - Advances to PROGRAM_STATE_NAME_ENTRY ($06)
;   - Clears Name_entry_complete, plays name-entry music
ProgramState_NameEntryInit:
	TST.b	Fade_out_lines_mask.w
	BNE.b	ProgramState_05_Loop
	JSR	DisableVDPDisplay
	CLR.b	Scene_update_flag.w
	JSR	ClearScrollData
	JSR	ClearEnemyActiveFlags
	MOVE.w	VDP_Reg11_cache.w, D0
	ANDI.w	#VDP_REG11_WINDOW_CLEAR_MASK, D0
	MOVE.w	D0, VDP_control_port
	JSR	LoadOptionsMenuGraphics
	JSR	EnableDisplay
	MOVE.l	#NameEntryScreen_Init, vobj_hblank_fn(A5)
	MOVE.w	#PROGRAM_STATE_NAME_ENTRY, Program_state.w
	CLR.b	Name_entry_complete.w
	PlaySound_b	SOUND_NAME_ENTRY
ProgramState_05_Loop:
	RTS

; ProgramState_NameEntry — $06 PROGRAM_STATE_NAME_ENTRY
; Per-frame handler for the name entry screen.
; Blocks until Name_entry_complete is set (by NameEntryScreen_Init when
; the player confirms their name).
; On completion: advances to PROGRAM_STATE_NAME_ENTRY_DONE ($07) and
; triggers a fade-out.
ProgramState_NameEntry:
	AdvanceStateOnComplete Name_entry_complete, PROGRAM_STATE_NAME_ENTRY_DONE

; ProgramState_NameEntryDone — $07 PROGRAM_STATE_NAME_ENTRY_DONE
; Transition: name confirmed → prologue.
; Waits for fade-out, then clears the enemy list flags, restores the
; default HBlank handler, advances to PROGRAM_STATE_PROLOGUE_INIT ($08),
; and plays the level-up jingle.
ProgramState_NameEntryDone:
	TST.b	Fade_out_lines_mask.w
	BNE.b	ProgramState_07_Loop
	JSR	ClearEnemyListFlags
	MOVE.l	#HBlankObjectHandler, vobj_hblank_fn(A5)
	MOVE.w	#PROGRAM_STATE_PROLOGUE_INIT, Program_state.w
	PlaySound	SOUND_LEVEL_UP
ProgramState_07_Loop:
	RTS

; ProgramState_EndingInit — $12 PROGRAM_STATE_ENDING_INIT
; One-shot initialization of the ending sequence.
; Installs EndingSequence_Init as the HBlank handler, then immediately
; advances to PROGRAM_STATE_ENDING ($13).
; EndingSequence_Init drives the full ending animation independently.
ProgramState_EndingInit:
	MOVE.l	#EndingSequence_Init, vobj_hblank_fn(A5)
	MOVE.w	#PROGRAM_STATE_ENDING, Program_state.w
	RTS

; ProgramState_Ending — $13/$14 PROGRAM_STATE_ENDING / PROGRAM_STATE_ENDING_2
; Per-frame handler for the ending sequence.
; Currently a no-op stub — the ending is entirely driven by
; EndingSequence_Init (the installed HBlank handler).
ProgramState_Ending:
	RTS

; ProgramState_GameFadeIn — $0E/$10 PROGRAM_STATE_GAME_FADE_IN / PROGRAM_STATE_GAME_FADE_IN_2
; Transition handler: wait for screen fade-in before entering main game.
; Waits for Fade_out_lines_mask to clear (fade complete), then:
;   - Disables VDP display
;   - Sets the player entity's active bit (bit 7 of its object struct)
;   - Advances Program_state by 1 ($0E→$0F, $10→$11) to GAME_ACTIVE
;   - Sets Message_speed = 1 (normal text speed)
; States $0E and $10 both point here; ADDQ advances to $0F or $11 respectively.
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

; MOD-004: GAMEPLAY STATE DISPATCH TABLE
; GameStateMap — computed-branch table for all in-game states.
; Called each frame by ProgramState_GameActive (PROGRAM_STATE_GAME_ACTIVE, $0F/$11),
; provided the player is not moving and no camera scroll is active.
;
; Dispatch formula:
;   D0 = Gameplay_state (RAM $FFFFC410)
;   jump = GameStateMap + D0 * 4  (each BRA.w is 4 bytes)
;
; State constants are defined in constants.asm as GAMEPLAY_STATE_*.
; Handlers in src/gameplay.asm; transitions write GAMEPLAY_STATE_* to
; Gameplay_state.w.  Saved_game_state.w preserves the pre-battle state
; so encounters can return to the correct exploration context.
;
; Index  Constant                              Handler
; -----  ------------------------------------  --------------------------------
; $00    GAMEPLAY_STATE_INIT_TOWN_ENTRY        GameState_InitTownEntry
; $01    GAMEPLAY_STATE_LOAD_TOWN              GameState_LoadTown
; $02    GAMEPLAY_STATE_TOWN_EXPLORATION       GameState_TownExploration
; $03    GAMEPLAY_STATE_INIT_BUILDING_ENTRY    GameState_InitBuildingEntry
; $04    GAMEPLAY_STATE_BUILDING_INTERIOR      GameState_BuildingInterior
; $05    GAMEPLAY_STATE_TRANSITION_TO_2F       GameState_TransitionToSecondFloor
; $06    GAMEPLAY_STATE_SECOND_FLOOR           GameState_SecondFloorActive
; $07    GAMEPLAY_STATE_TRANSITION_TO_3F       GameState_TransitionToThirdFloor
; $08    GAMEPLAY_STATE_THIRD_FLOOR            GameState_ThirdFloorActive
; $09    GAMEPLAY_STATE_TRANSITION_TO_CASTLE   GameState_TransitionToCastleMain
; $0A    GAMEPLAY_STATE_CASTLE_ROOM1           GameState_CastleRoom1Active
; $0B    GAMEPLAY_STATE_LOAD_CASTLE_ROOM2      GameState_LoadCastleRoom2
; $0C    GAMEPLAY_STATE_CASTLE_ROOM2           GameState_CastleRoom2Active
; $0D    GAMEPLAY_STATE_LOAD_CASTLE_ROOM3      GameState_LoadCastleRoom3
; $0E    GAMEPLAY_STATE_CAVE_ENTRANCE          GameState_CaveEntrance
; $0F    GAMEPLAY_STATE_BATTLE_INITIALIZE      GameState_BattleInitialize
; $10    GAMEPLAY_STATE_BATTLE_ACTIVE          GameState_BattleActive
; $11    GAMEPLAY_STATE_BATTLE_EXIT            GameState_BattleExit
; $12    GAMEPLAY_STATE_OVERWORLD_RELOAD       GameState_OverworldReload
; $13    GAMEPLAY_STATE_OVERWORLD_ACTIVE       GameState_OverworldActive
; $14    GAMEPLAY_STATE_TOWN_FADE_IN_COMPLETE  GameState_TownFadeInComplete
; $15    GAMEPLAY_STATE_ENTERING_CAVE          GameState_EnteringCave
; $16    GAMEPLAY_STATE_CAVE_EXPLORATION       GameState_CaveExploration
; $17    GAMEPLAY_STATE_CAVE_FADE_OUT_COMPLETE GameState_CaveFadeOutComplete
; $18    GAMEPLAY_STATE_ENCOUNTER_INITIALIZE   GameState_EncounterInitialize
; $19    GAMEPLAY_STATE_ENCOUNTER_FADE_IN      GameState_EncounterGraphicsFadeIn
; $1A    GAMEPLAY_STATE_ENCOUNTER_PAUSE        GameState_EncounterPauseBeforeBattle
; $1B    GAMEPLAY_STATE_LEVEL_UP_BANNER        GameState_LevelUpBannerDisplay
; $1C    GAMEPLAY_STATE_LEVEL_UP_WAIT          GameState_LevelUpStatsWaitInput
; $1D    GAMEPLAY_STATE_LEVEL_UP_COMPLETE      GameState_LevelUpComplete
; $1E    GAMEPLAY_STATE_RETURN_TO_FIRST_PERSON GameState_ReturnToFirstPersonView
; $1F    GAMEPLAY_STATE_FADE_IN_COMPLETE       GameState_FadeInComplete
; $20    GAMEPLAY_STATE_DIALOG_DISPLAY         GameState_DialogDisplay
; $21    GAMEPLAY_STATE_BOSS_BATTLE_INIT       GameState_BossBattleInit
; $22    GAMEPLAY_STATE_BOSS_BATTLE_ACTIVE     GameState_BossBattleActive
; $23    GAMEPLAY_STATE_RETURN_FROM_BOSS       GameState_ReturnFromBossBattle
; $24    GAMEPLAY_STATE_BEGIN_RESURRECTION     GameState_BeginResurrection
; $25    GAMEPLAY_STATE_PROCESS_RESURRECTION   GameState_ProcessResurrection
; $26    GAMEPLAY_STATE_NOTIFY_INAUDIOS        GameState_NotifyInaudiosExpired
; $27    GAMEPLAY_STATE_WAIT_DISMISS           GameState_WaitForNotificationDismiss
; $28    GAMEPLAY_STATE_READ_AWAKENING         GameState_ReadAwakeningMessage
; $29    GAMEPLAY_STATE_FRYING_PAN_DELAY       GameState_FryingPanDelay
; $2A    GAMEPLAY_STATE_READ_FRYING_PAN        GameState_ReadFryingPanMessage
; $2B    GAMEPLAY_STATE_SOLDIER_TAUNT          GameState_SoldierTaunt
; $2C    GAMEPLAY_STATE_READ_SOLDIER_TAUNT     GameState_ReadSoldierTaunt
; $2D    GAMEPLAY_STATE_SHOW_POISON_NOTIFY     GameState_ShowPoisonNotification
;
; Typical state flows:
;   New-game town entry: $00 → $01 → $1F → $02
;   Enter building:      $02 → $03 → $04
;   Leave building:      $04 → $01 → $1F → $02
;   Overworld/cave:      $02 → $0E → $15 → $16
;   Encounter chain:     $16 → $17 → $18 → $19 → $1A → (battle) → $1E → $16
;   Boss battle:         $04/$02 → $21 → $22 → $23 → (restore saved state)
;   Death/resurrection:  $any → $24 → $25 → $00
GameStateMap:
	BRA.w	GameState_InitTownEntry			; $00 GAMEPLAY_STATE_INIT_TOWN_ENTRY
	BRA.w	GameState_LoadTown			; $01 GAMEPLAY_STATE_LOAD_TOWN
	BRA.w	GameState_TownExploration		; $02 GAMEPLAY_STATE_TOWN_EXPLORATION
	BRA.w	GameState_InitBuildingEntry		; $03 GAMEPLAY_STATE_INIT_BUILDING_ENTRY
	BRA.w	GameState_BuildingInterior		; $04 GAMEPLAY_STATE_BUILDING_INTERIOR
	BRA.w	GameState_TransitionToSecondFloor	; $05 GAMEPLAY_STATE_TRANSITION_TO_2F
	BRA.w	GameState_SecondFloorActive		; $06 GAMEPLAY_STATE_SECOND_FLOOR
	BRA.w	GameState_TransitionToThirdFloor	; $07 GAMEPLAY_STATE_TRANSITION_TO_3F
	BRA.w	GameState_ThirdFloorActive		; $08 GAMEPLAY_STATE_THIRD_FLOOR
	BRA.w	GameState_TransitionToCastleMain	; $09 GAMEPLAY_STATE_TRANSITION_TO_CASTLE
	BRA.w	GameState_CastleRoom1Active		; $0A GAMEPLAY_STATE_CASTLE_ROOM1
	BRA.w	GameState_LoadCastleRoom2		; $0B GAMEPLAY_STATE_LOAD_CASTLE_ROOM2
	BRA.w	GameState_CastleRoom2Active		; $0C GAMEPLAY_STATE_CASTLE_ROOM2
	BRA.w	GameState_LoadCastleRoom3		; $0D GAMEPLAY_STATE_LOAD_CASTLE_ROOM3
	BRA.w	GameState_CaveEntrance			; $0E GAMEPLAY_STATE_CAVE_ENTRANCE
	BRA.w	GameState_BattleInitialize		; $0F GAMEPLAY_STATE_BATTLE_INITIALIZE
	BRA.w	GameState_BattleActive			; $10 GAMEPLAY_STATE_BATTLE_ACTIVE
	BRA.w	GameState_BattleExit			; $11 GAMEPLAY_STATE_BATTLE_EXIT
	BRA.w	GameState_OverworldReload		; $12 GAMEPLAY_STATE_OVERWORLD_RELOAD
	BRA.w	GameState_OverworldActive		; $13 GAMEPLAY_STATE_OVERWORLD_ACTIVE
	BRA.w	GameState_TownFadeInComplete		; $14 GAMEPLAY_STATE_TOWN_FADE_IN_COMPLETE
	BRA.w	GameState_EnteringCave			; $15 GAMEPLAY_STATE_ENTERING_CAVE
	BRA.w	GameState_CaveExploration		; $16 GAMEPLAY_STATE_CAVE_EXPLORATION
	BRA.w	GameState_CaveFadeOutComplete		; $17 GAMEPLAY_STATE_CAVE_FADE_OUT_COMPLETE
	BRA.w	GameState_EncounterInitialize		; $18 GAMEPLAY_STATE_ENCOUNTER_INITIALIZE
	BRA.w	GameState_EncounterGraphicsFadeIn	; $19 GAMEPLAY_STATE_ENCOUNTER_FADE_IN
	BRA.w	GameState_EncounterPauseBeforeBattle	; $1A GAMEPLAY_STATE_ENCOUNTER_PAUSE
	BRA.w	GameState_LevelUpBannerDisplay		; $1B GAMEPLAY_STATE_LEVEL_UP_BANNER
	BRA.w	GameState_LevelUpStatsWaitInput		; $1C GAMEPLAY_STATE_LEVEL_UP_WAIT
	BRA.w	GameState_LevelUpComplete		; $1D GAMEPLAY_STATE_LEVEL_UP_COMPLETE
	BRA.w	GameState_ReturnToFirstPersonView	; $1E GAMEPLAY_STATE_RETURN_TO_FIRST_PERSON
	BRA.w	GameState_FadeInComplete		; $1F GAMEPLAY_STATE_FADE_IN_COMPLETE
	BRA.w	GameState_DialogDisplay			; $20 GAMEPLAY_STATE_DIALOG_DISPLAY
	BRA.w	GameState_BossBattleInit		; $21 GAMEPLAY_STATE_BOSS_BATTLE_INIT
	BRA.w	GameState_BossBattleActive		; $22 GAMEPLAY_STATE_BOSS_BATTLE_ACTIVE
	BRA.w	GameState_ReturnFromBossBattle		; $23 GAMEPLAY_STATE_RETURN_FROM_BOSS
	BRA.w	GameState_BeginResurrection		; $24 GAMEPLAY_STATE_BEGIN_RESURRECTION
	BRA.w	GameState_ProcessResurrection		; $25 GAMEPLAY_STATE_PROCESS_RESURRECTION
	BRA.w	GameState_NotifyInaudiosExpired		; $26 GAMEPLAY_STATE_NOTIFY_INAUDIOS
	BRA.w	GameState_WaitForNotificationDismiss	; $27 GAMEPLAY_STATE_WAIT_DISMISS
	BRA.w	GameState_ReadAwakeningMessage		; $28 GAMEPLAY_STATE_READ_AWAKENING
	BRA.w	GameState_FryingPanDelay		; $29 GAMEPLAY_STATE_FRYING_PAN_DELAY
	BRA.w	GameState_ReadFryingPanMessage		; $2A GAMEPLAY_STATE_READ_FRYING_PAN
	BRA.w	GameState_SoldierTaunt			; $2B GAMEPLAY_STATE_SOLDIER_TAUNT
	BRA.w	GameState_ReadSoldierTaunt		; $2C GAMEPLAY_STATE_READ_SOLDIER_TAUNT
	BRA.w	GameState_ShowPoisonNotification	; $2D GAMEPLAY_STATE_SHOW_POISON_NOTIFY

