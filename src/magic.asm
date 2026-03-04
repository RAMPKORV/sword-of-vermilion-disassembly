; ======================================================================
; src/magic.asm
; Magic/spell system, spellbook menu, Aries map
; ======================================================================
	ANDI	#$F8FF, SR
	RTS

ClearEndingTextArea:
	MOVE.l	D5, D4
	CLR.w	D0
	ANDI.l	#$5FFF0003, D4
	ORI.l	#$40000003, D4
	MOVE.w	#2, D7
ClearEndingTextArea_Done:
	MOVE.l	D4, VDP_control_port
	MOVE.w	#$0019, D6
ClearEndingTextArea_Done2:
	MOVE.w	D0, VDP_data_port
	DBF	D6, ClearEndingTextArea_Done2
	ADDI.l	#$00800000, D4
	ANDI.l	#$5FFF0003, D4
	ORI.l	#$40000003, D4
	DBF	D7, ClearEndingTextArea_Done
	ADDI.l	#$000E0000, D5
	ANDI.l	#$5FFF0003, D5
	ORI.l	#$40000003, D5
	LEA	ClearEndingTextArea_Done2_Data, A0
	MOVE.w	#2, D7
ClearEndingTextArea_Done3:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#8, D6
ClearEndingTextArea_Done4:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$4002, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, ClearEndingTextArea_Done4
	ADDI.l	#$00800000, D5
	ANDI.l	#$5FFF0003, D5
	ORI.l	#$40000003, D5
	DBF	D7, ClearEndingTextArea_Done3
	SUBI.l	#$000E0000, D5
	ANDI.l	#$5FFF0003, D5
	ORI.l	#$40000003, D5
	MOVE.w	#$000E, D7
ClearEndingTextArea_Done5:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$0018, D6
ClearEndingTextArea_Done6:
	CLR.w	D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, ClearEndingTextArea_Done6
	ADDI.l	#$00800000, D5
	ANDI.l	#$5FFF0003, D5
	ORI.l	#$40000003, D5
	DBF	D7, ClearEndingTextArea_Done5
	RTS

InitEndingCreditsScreen:
	ORI	#$0700, SR
	MOVE.l	#$40000003, D5
	MOVE.w	#$A080, D4
	MOVE.w	#$003F, D7
InitEndingCreditsScreen_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$003F, D6
InitEndingCreditsScreen_Done2:
	MOVE.w	D4, VDP_data_port
	DBF	D6, InitEndingCreditsScreen_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, InitEndingCreditsScreen_Done
	MOVE.l	#$40040003, D5
	LEA	InitEndingCreditsScreen_Done2_Data, A0
	MOVE.w	#$0019, D7
InitEndingCreditsScreen_Done3:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$001B, D6
InitEndingCreditsScreen_Done4:
	MOVE.w	(A0)+, D0
	ADDI.w	#$A080, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, InitEndingCreditsScreen_Done4
	ADDI.l	#$00800000, D5
	DBF	D7, InitEndingCreditsScreen_Done3
	MOVE.l	#$60000003, D5
	LEA	InitEndingCreditsScreen_Done4_Data, A0
	MOVE.w	#$001B, D7
InitEndingCreditsScreen_Done5:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$0027, D6
InitEndingCreditsScreen_Done6:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$601D, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, InitEndingCreditsScreen_Done6
	ADDI.l	#$00800000, D5
	DBF	D7, InitEndingCreditsScreen_Done5
	ANDI	#$F8FF, SR
	RTS

DrawCreditsStaffNames:
	ORI	#$0700, SR
	MOVE.l	#$69800003, D4
	MOVE.w	#3, D7
DrawCreditsStaffNames_Done:
	LEA	SpriteTileIndexTable_6195A, A0
	MOVE.w	#8, D6
	MOVE.l	D4, D3
DrawCreditsStaffNames_Done2:
	MOVE.w	#$000F, D5
	MOVE.l	D3, VDP_control_port
DrawCreditsStaffNames_Done3:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$41CD, D0
	MOVE.w	D0, VDP_data_port
	DBF	D5, DrawCreditsStaffNames_Done3
	ADDI.l	#$00800000, D3
	DBF	D6, DrawCreditsStaffNames_Done2
	ADDI.l	#$00200000, D4
	DBF	D7, DrawCreditsStaffNames_Done
	ANDI	#$F8FF, SR
	RTS

DrawEndingBorderPattern:
	MOVE.l	#$66940003, D5
	MOVE.w	#$84E0, D4
	MOVE.w	#5, D7
	ORI	#$0700, SR
DrawEndingBorderPattern_Done:
	MOVE.w	#$0017, D6
	MOVE.l	D5, VDP_control_port
DrawEndingBorderPattern_Done2:
	MOVE.w	D4, VDP_data_port
	DBF	D6, DrawEndingBorderPattern_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, DrawEndingBorderPattern_Done
	ANDI	#$F8FF, SR
	RTS

FillDialogAreaWithPattern:
	MOVE.l	#$40BC0003, D5
	MOVE.w	#$0019, D7
FillDialogAreaWithPattern_Done:
	MOVE.w	#$0014, D6
	MOVE.l	D5, VDP_control_port
FillDialogAreaWithPattern_Done2:
	MOVE.w	#$A080, VDP_data_port
	DBF	D6, FillDialogAreaWithPattern_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, FillDialogAreaWithPattern_Done
	RTS

ClearDialogSprites:
	MOVE.l	#$50000000, D5
	MOVEQ	#0, D0
	MOVE.w	Dialog_phase.w, D0
	ADD.w	D0, D0
	SWAP	D0
	ADD.l	D0, D5
	MOVE.w	#$028F, D7
	ORI	#$0700, SR
ClearDialogSprites_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#0, VDP_data_port
	ADDI.l	#$00100000, D5
	DBF	D7, ClearDialogSprites_Done
	ANDI	#$F8FF, SR
	ADDQ.w	#1, Dialog_phase.w
	RTS

UpdateEndingCursorBlink:
	ADDQ.w	#1, Cursor_blink_timer.w
	MOVE.w	Cursor_blink_timer.w, D0
	MOVE.w	D0, D1
	SUBQ.w	#1, D1
	EOR.w	D1, D0
	BTST.l	#3, D0
	BEQ.b	UpdateEndingCursorBlink_Loop
	ADDQ.w	#1, Palette_line_3_index.w
	CMPI.w	#PALETTE_IDX_ENDING_CURSOR_MAX, Palette_line_3_index.w
	BLE.b	UpdateEndingCursorBlink_Loop2
	MOVE.w	#PALETTE_IDX_ENDING_CURSOR_MIN, Palette_line_3_index.w
UpdateEndingCursorBlink_Loop2:
	JSR	LoadPalettesFromTable
UpdateEndingCursorBlink_Loop:
	RTS

Outro1Str:
	dc.b	"Mother, let's go back to", $FE
	dc.b	"the village where", $FE
	dc.b	"I was raised.", $FF, $00
Outro2Str:
	dc.b	"Yes, let's do that.", $FE
	dc.b	"You're grown now,", $FE 
	dc.b	"and you've become important.", $FE
	dc.b	"It's time for", $FE
	dc.b	"you to visit Blade's grave.", $FF, $00
Outro3Str:
	dc.b	"Whenever evil", $FE
	dc.b	"oversteps its",  $FE
	dc.b	"bounds and", $FE
	dc.b	"threatens to", $FE
	dc.b	"engulf the", $FE
	dc.b	"world, a hero", $FE
	dc.b	"arises to fight,crback the ", $FE
	dc.b	"darkness. You", $FE
	dc.b	"answered the", $FE
	dc.b	"call this time,", $FE
	dc.b	"and the balance", $FE
	dc.b	"between good", $FF, $00
Outro4Str:
	dc.b	"and evil has", $FE
	dc.b	"been restored.", $FE
	dc.b	"Who will answer", $FE
	dc.b	"the call next", $FE
	dc.b	"time? Peace now", $FE
	dc.b	"reigns ", $FE
	dc.b	"throughout the", $FE
	dc.b	"lands ruled by", $FE
	dc.b	"the Sword of", $FE
	dc.b	"Vermilion.", $FE
	dc.b	"You married", $FE
	dc.b	"your Princess", $FF
Outro5Str:
	dc.b	"and rebuilt", $FE
	dc.b	"Excalabria as", $FE
	dc.b	"the heart of", $FE
	dc.b	"your kingdom.", $FE
	dc.b	"Yet the wise", $FE
	dc.b	"say that evil", $FE
	dc.b	"can never be", $FE
	dc.b	"truly banished.", $FE
	dc.b	"Always it", $FE
	dc.b	"reappears in", $FE
	dc.b	"another guise,", $FE
	dc.b	"at another", $FE
	dc.b	"time....", $FF, $00
StaffTextStr:
	dc.b	"      STAFF", $FF
DirectorTextStr:
	dc.b	"DIRECTOR", $FF, $00
ScenarioWriterTextStr:
	dc.b	"SCENARIO WRITER", $FF
GameDesignTextStr:
	dc.b	"GAME DESIGN", $FF
ChiefProgrammerTextStr:
	dc.b	"CHIEF PROGRAMER", $FF
ChiefDesignerTextStr:
	dc.b	"CHIEF DESIGNER", $FF, $00
MainProgramTextStr:
	dc.b	"MAIN PROGRAM", $FF, $00
ProgramTextStr:
	dc.b	"PROGRAM", $FF
SoundProgramTextStr:
	dc.b	"SOUND PROGRAM", $FF
Cpu68000TextStr:
	dc.b	"68000", $FF
CpuZ80TextStr:
	dc.b	"Z80", $FF
BackgroundDesignTextStr:
	dc.b	"BACKGROUND DESIGN", $FF
PlayerDesignTextStr:
	dc.b	"PLAYER DESIGN", $FF
BossDesignTextStr:
	dc.b	"BOSS DESIGN", $FF
EnemyDesignTextStr:
	dc.b	"ENEMY DESIGN", $FF, $00
OpeningDesignTextStr:
	dc.b	"OPENING DESIGN", $FF, $00
TitleDesignTextStr:
	dc.b	"TITLE DESIGN", $FF, $00
AsciiDesignTextStr:
	dc.b	"ASCII DESIGN", $FF, $00
MapDesignTextStr:
	dc.b	"MAP DESIGN", $FF, $00
MapEditTextStr:
	dc.b	"MAP EDIT", $FF, $00
SoundBgmTextStr:
	dc.b	"SOUND (BGM)", $FF
SoundEffectTextStr:
	dc.b	"SOUND (EFFECT)", $FF, $00
GameCheckTextStr:
	dc.b	"GAME CHECK", $FF, $00
ManualWriteTextStr:
	dc.b	"MANUAL WRITE", $FF, $00
SpecialThanksTextStr:
	dc.b	"SPECIAL THANKS", $FF, $00
SadaTextStr:
	dc.b	"      SADA", $FF, $00
NamakoTextStr:
	dc.b	"      NAMAKO", $FF, $00
MadokaTextStr:
	dc.b	"      MADOKA", $FF, $00
ZeasQTextStr:
	dc.b	"      ZEAS-Q", $FF, $00
Lalf2TextStr:
	dc.b	"      LALF2", $FF
HiroTextStr:
	dc.b	"      HIRO", $FF, $00
YasTextStr:
	dc.b	"      YAS", $FF
KeyTextStr:
	dc.b	"      KEY", $FF
GudonTextStr:
	dc.b	"      GUDON", $FF
PapaTextStr:
	dc.b	"      PAPA", $FF, $00
JijiTextStr:
	dc.b	"      JIJI", $FF, $00
RoboTextStr:
	dc.b	"      ROBO", $FF, $00
LucyTextStr:
	dc.b	"      LUCY", $FF, $00
ComaTextStr:
	dc.b	"      COMA", $FF, $00
DogTextStr:
	dc.b	"      DOG", $FF
YuTextStr:
	dc.b	"      YU", $FF, $00
BinTextStr:
	dc.b	"      BIN", $FF
PlayerTextStr:
	dc.b	"PLAYER", $FF, $00
PutInYourPadTextStr:
	dc.b	"PUT IN YOUR PAD", $FF
OnThe2PSideTextStr:
	dc.b	"    ON THE 2P SIDE", $FF, $00
AndPushAbcStartTextStr:
	dc.b	'AND PUSH "A""B""C""START"', $FF

; EmptyTextStr
; Empty string used in credits/text tables
EmptyTextStr:
	dc.b	$00, $00
CreditsTextListTerminator:
	dc.b	$FE, $00
CreditsTextPtrTable:
	dc.l	EmptyTextStr
	dc.l	StaffTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	DirectorTextStr
	dc.l	EmptyTextStr
	dc.l	SadaTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	ScenarioWriterTextStr
	dc.l	EmptyTextStr
	dc.l	NamakoTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	GameDesignTextStr
	dc.l	EmptyTextStr
	dc.l	SadaTextStr
	dc.l	EmptyTextStr
	dc.l	NamakoTextStr
	dc.l	EmptyTextStr
	dc.l	MadokaTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	ChiefProgrammerTextStr
	dc.l	EmptyTextStr
	dc.l	MadokaTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	ChiefDesignerTextStr
	dc.l	EmptyTextStr
	dc.l	KeyTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	MainProgramTextStr
	dc.l	EmptyTextStr
	dc.l	MadokaTextStr
	dc.l	EmptyTextStr
	dc.l	NamakoTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	ProgramTextStr
	dc.l	EmptyTextStr
	dc.l	BinTextStr
	dc.l	EmptyTextStr
	dc.l	ZeasQTextStr
	dc.l	EmptyTextStr
	dc.l	Lalf2TextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	SoundProgramTextStr
	dc.l	EmptyTextStr
	dc.l	Cpu68000TextStr
	dc.l	EmptyTextStr
	dc.l	HiroTextStr
	dc.l	CpuZ80TextStr
	dc.l	EmptyTextStr
	dc.l	YasTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	BackgroundDesignTextStr
	dc.l	EmptyTextStr
	dc.l	KeyTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	PlayerDesignTextStr
	dc.l	EmptyTextStr
	dc.l	GudonTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	BossDesignTextStr
	dc.l	EmptyTextStr
	dc.l	GudonTextStr
	dc.l	EmptyTextStr
	dc.l	PapaTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	EnemyDesignTextStr
	dc.l	EmptyTextStr
	dc.l	GudonTextStr
	dc.l	EmptyTextStr
	dc.l	PapaTextStr
	dc.l	EmptyTextStr
	dc.l	RoboTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	OpeningDesignTextStr
	dc.l	EmptyTextStr
	dc.l	JijiTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	TitleDesignTextStr
	dc.l	EmptyTextStr
	dc.l	KeyTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	AsciiDesignTextStr
	dc.l	EmptyTextStr
	dc.l	KeyTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	MapDesignTextStr
	dc.l	EmptyTextStr
	dc.l	SadaTextStr
	dc.l	EmptyTextStr
	dc.l	NamakoTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	MapEditTextStr
	dc.l	EmptyTextStr
	dc.l	ComaTextStr
	dc.l	EmptyTextStr
	dc.l	LucyTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	SoundBgmTextStr
	dc.l	EmptyTextStr
	dc.l	HiroTextStr
	dc.l	EmptyTextStr
	dc.l	YasTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	SoundEffectTextStr
	dc.l	EmptyTextStr
	dc.l	YasTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	GameCheckTextStr
	dc.l	EmptyTextStr
	dc.l	DogTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	ManualWriteTextStr
	dc.l	EmptyTextStr
	dc.l	MadokaTextStr
	dc.l	EmptyTextStr
	dc.l	NamakoTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	PlayerTextStr
	dc.l	EmptyTextStr
	dc.l	Ending_player_name_buffer
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	SpecialThanksTextStr
	dc.l	EmptyTextStr
	dc.l	YuTextStr
	dc.l	EmptyTextStr
	dc.l	BinTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	PutInYourPadTextStr
	dc.l	EmptyTextStr
	dc.l	OnThe2PSideTextStr
	dc.l	EmptyTextStr
	dc.l	AndPushAbcStartTextStr
	dc.l	EmptyTextStr

	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	EmptyTextStr
	dc.l	CreditsTextListTerminator
SpellbookMenuStateMachine:
	MOVE.w	Spellbook_menu_state.w, D0
	ANDI.w	#$001F, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	SpellbookMenuStateJumpTable, A0
	JSR	(A0,D0.w)
	RTS

SpellbookMenuStateJumpTable:
	BRA.w	SpellbookMenuStateJumpTable_Loop
	BRA.w	SpellbookMenuStateJumpTable_Loop2
	BRA.w	SpellbookMenu_Return_Loop
	BRA.w	SpellMenu_ScriptDoneShowStatus_Loop
	BRA.w	SpellMenu_ScriptDoneShowStatus_Loop2
	BRA.w	SpellMenu_ScriptDoneShowStatus_Loop3
	BRA.w	SpellMenu_ScriptDoneShowStatus_Loop4
	BRA.w	SpellMenu_ScriptDoneShowStatus_Loop5
	BRA.w	SpellMenu_ScriptDoneShowStatus_Loop6	
	BRA.w	SpellMenu_ScriptDoneShowStatus_Loop7
	BRA.w	SpellMenu_ScriptDoneShowStatus_Loop8
	BRA.w	SpellMenu_ScriptDoneShowHpMp_Loop
	BRA.w	SpellMenu_ScriptDoneShowStatus_Loop9
	BRA.w	SpellMenu_ScriptDoneShowStatus_Loop10
	BRA.w	SpellMenu_ScriptDoneShowStatus_Loop11
	BRA.w	SpellMenu_ScriptDoneShowStatus_Loop12
SpellbookMenuStateJumpTable_Loop:
	MOVE.w	Main_menu_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	JSR	SaveItemListAreaToBuffer_Large
	JSR	DrawSpellActionMenu
	CLR.w	Item_menu_action_mode.w
	ADDQ.w	#1, Spellbook_menu_state.w
	CLR.w	Menu_cursor_index.w
	RTS

SpellbookMenuStateJumpTable_Loop2:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	SpellbookMenu_Return
	CheckButton BUTTON_BIT_B
	BEQ.b	SpellbookMenuStateJumpTable_Loop3
	PlaySound SOUND_MENU_CANCEL
	TriggerWindowRedraw WINDOW_DRAW_ITEM_SELL_TALL
	MOVE.w	#OVERWORLD_MENU_STATE_OPTIONS_WAIT, Overworld_menu_state.w
	JSR	InitMenuCursorDefaults
	RTS

SpellbookMenuStateJumpTable_Loop3:
	CheckButton BUTTON_BIT_C
	BEQ.w	SpellbookMenu_Return_Loop2
	MOVE.w	Item_menu_action_mode.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	PlaySound SOUND_MENU_SELECT
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	TST.w	Possessed_magics_length.w
	BGT.b	SpellbookMenuStateJumpTable_Loop4
	PRINT 	NoBooksOfSpellsStr
	MOVE.w	#SPELLBOOK_STATE_CLOSE, Spellbook_menu_state.w
	BRA.w	SpellbookMenu_Return
SpellbookMenuStateJumpTable_Loop4:
	TST.w	Item_menu_action_mode.w
	BEQ.w	SpellbookMenuStateJumpTable_Loop5
	CMPI.w	#1, Item_menu_action_mode.w
	BEQ.b	SpellbookMenuStateJumpTable_Loop6
	PRINT 	PutDownBookStr
	MOVE.w	#SPELLBOOK_STATE_PUT_DOWN, Spellbook_menu_state.w
	BRA.b	SpellbookMenu_Return
SpellbookMenuStateJumpTable_Loop6:
	BSR.w	CheckAnyMagicReady
	BEQ.b	SpellbookMenuStateJumpTable_Loop7
	PRINT 	ReadyBookCombatStr
	MOVE.w	#SPELLBOOK_STATE_STATUS_C, Spellbook_menu_state.w
	BRA.b	SpellbookMenu_Return
SpellbookMenuStateJumpTable_Loop7:
	PRINT 	NoCombatBooksStr	
	MOVE.w	#SPELLBOOK_STATE_CLOSE, Spellbook_menu_state.w	
	BRA.b	SpellbookMenu_Return	
SpellbookMenuStateJumpTable_Loop5:
	PRINT 	CastSpellBookStr
	MOVE.w	#SPELLBOOK_STATE_USE_INIT, Spellbook_menu_state.w
SpellbookMenu_Return:
	RTS

SpellbookMenu_Return_Loop2:
	MOVE.w	Item_menu_action_mode.w, Menu_cursor_index.w
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Item_menu_action_mode.w
	RTS

SpellbookMenu_Return_Loop:
	TST.b	Script_text_complete.w
	BEQ.w	SpellMenu_ScriptDoneShowStatus_Loop13
	CheckButton BUTTON_BIT_C
	BNE.b	SpellMenu_ScriptDoneShowStatus
	CheckButton BUTTON_BIT_B
	BNE.b	SpellMenu_ScriptDoneShowStatus
	RTS

SpellMenu_ScriptDoneShowStatus:
	JSR	DrawStatusHudWindow
	MOVE.w	#SPELLBOOK_STATE_CAST_DONE, Spellbook_menu_state.w
	TriggerWindowRedraw WINDOW_DRAW_ITEM_SELL_TALL
	RTS

SpellMenu_ScriptDoneShowStatus_Loop13:
	JSR	ProcessScriptText
	RTS

SpellMenu_ScriptDoneShowStatus_Loop8:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.b	SpellMenu_ScriptDoneShowStatus_Loop14
	TST.b	Player_in_first_person_mode.w
	BEQ.b	SpellMenu_ScriptDoneShowStatus_Loop15
	JSR	DisplayReadiedMagicName
SpellMenu_ScriptDoneShowStatus_Loop15:
	CLR.w	Overworld_menu_state.w
	TriggerWindowRedraw WINDOW_DRAW_MSG_SPEED_ALT
SpellMenu_ScriptDoneShowStatus_Loop14:
	RTS

SpellMenu_ScriptDoneShowStatus_Loop:
	TST.b	Script_text_complete.w
	BEQ.b	SpellMenu_ScriptDoneShowStatus_Loop16
	JSR	SaveCenterDialogAreaToBuffer
	JSR	DrawMagicListBorders
	JSR	DrawMagicListWithMP
	CLR.w	Magic_list_cursor_index.w
	MOVE.w	#SPELLBOOK_STATE_EQUIP_INIT, Spellbook_menu_state.w
	MOVE.w	Possessed_magics_length.w, D0
	JSR	InitMenuCursorForList
	RTS

SpellMenu_ScriptDoneShowStatus_Loop16:
	JSR	ProcessScriptText
	RTS

SpellMenu_ScriptDoneShowStatus_Loop2:
	CheckButton BUTTON_BIT_B
	BEQ.b	SpellMenu_ScriptDoneShowStatus_Loop17
	PlaySound SOUND_MENU_CANCEL	
	JSR	DrawCenterMenuWindow	
	JSR	DrawStatusHudWindow	
	MOVE.w	#SPELLBOOK_STATE_WAIT_INPUT, Spellbook_menu_state.w	
	BRA.w	InitSpellbookCursor	
SpellMenu_ScriptDoneShowStatus_Loop17:
	CheckButton BUTTON_BIT_C
	BEQ.b	SpellMenu_ScriptDoneShowStatus_Loop18
	MOVE.w	Magic_list_cursor_index.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	PlaySound SOUND_MENU_SELECT
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
	ADDQ.w	#1, Spellbook_menu_state.w
	RTS

SpellMenu_ScriptDoneShowStatus_Loop18:
	MOVE.w	Magic_list_cursor_index.w, Menu_cursor_index.w
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Magic_list_cursor_index.w
	RTS

SpellMenu_ScriptDoneShowStatus_Loop3:
	CheckButton BUTTON_BIT_B
	BNE.b	SpellMenu_ScriptDoneShowStatus_Loop19
	CheckButton BUTTON_BIT_C
	BEQ.w	SpellMenu_ScriptDoneShowStatus_Loop20
	PlaySound SOUND_MENU_SELECT
	TST.w	Dialog_selection.w
	BEQ.w	SpellMenu_ScriptDoneShowStatus_Loop21
	JSR	DrawLeftMenuWindow	
	JSR	DrawCenterMenuWindow	
	JSR	DrawStatusHudWindow	
	MOVE.w	#SPELLBOOK_STATE_WAIT_INPUT, Spellbook_menu_state.w	
	JSR	InitSpellbookCursor	
	RTS
	
SpellMenu_ScriptDoneShowStatus_Loop19:
	PlaySound SOUND_MENU_CANCEL	
	JSR	DrawLeftMenuWindow	
	MOVE.w	#SPELLBOOK_STATE_EQUIP_INIT, Spellbook_menu_state.w	
	MOVE.w	Possessed_magics_length.w, D0	
	JSR	InitMenuCursorForList	
	RTS
	
SpellMenu_ScriptDoneShowStatus_Loop21:
	LEA	Possessed_magics_list.w, A0
	MOVE.w	Magic_list_cursor_index.w, D0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), D0
	BGE.b	SpellMenu_ScriptDoneShowStatus_Loop22
	MOVE.w	#MAGIC_NONE, Readied_magic.w
SpellMenu_ScriptDoneShowStatus_Loop22:
	JSR	DrawLeftMenuWindow
	JSR	DrawCenterMenuWindow
	JSR	ResetScriptAndInitDialogue
	JSR	CopyPlayerNameToTextBuffer
	LEA	DiscardsTheStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	LEA	MagicNames, A0
	LEA	Possessed_magics_list.w, A2
	MOVE.w	Magic_list_cursor_index.w, D0
	ADD.w	D0, D0
	MOVE.w	(A2,D0.w), D0
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	CopyStringUntilFF
	MOVE.b	#$2E, (A1)+
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
	MOVE.w	#SPELLBOOK_STATE_CLOSE, Spellbook_menu_state.w
	SUBQ.w	#1, Possessed_magics_length.w
	LEA	Possessed_magics_list.w, A0
	MOVE.w	Magic_list_cursor_index.w, D0
	MOVE.w	#9, D2
	JSR	RemoveItemFromArray
	RTS

SpellMenu_ScriptDoneShowStatus_Loop20:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

SpellMenu_ScriptDoneShowStatus_Loop9:
	TST.b	Script_text_complete.w
	BEQ.b	SpellMenu_ScriptDoneShowStatus_Loop23
	JSR	SaveCenterDialogAreaToBuffer
	JSR	DrawMagicListBorders
	JSR	DrawMagicListWithMP
	CLR.w	Magic_list_cursor_index.w
	ADDQ.w	#1, Spellbook_menu_state.w
	MOVE.w	Possessed_magics_length.w, D0
	BRA.w	InitMenuCursorForList
	dc.b	$4E, $75 ; DEAD: orphan RTS opcode ($4E75) after unconditional BRA; unreachable
SpellMenu_ScriptDoneShowStatus_Loop23:
	JSR	ProcessScriptText
	RTS

SpellMenu_ScriptDoneShowStatus_Loop10:
	CheckButton BUTTON_BIT_B
	BEQ.b	SpellMenu_ScriptDoneShowStatus_Loop24
	PlaySound SOUND_MENU_CANCEL
	JSR	DrawCenterMenuWindow
	JSR	DrawStatusHudWindow
	MOVE.w	#SPELLBOOK_STATE_WAIT_INPUT, Spellbook_menu_state.w
	BRA.w	InitSpellbookCursor
SpellMenu_ScriptDoneShowStatus_Loop24:
	CheckButton BUTTON_BIT_C
	BEQ.b	SpellMenu_ScriptDoneShowStatus_Loop25
	MOVE.w	Magic_list_cursor_index.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	PlaySound SOUND_MENU_SELECT
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
	ADDQ.w	#1, Spellbook_menu_state.w
	RTS

SpellMenu_ScriptDoneShowStatus_Loop25:
	MOVE.w	Magic_list_cursor_index.w, Menu_cursor_index.w
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Magic_list_cursor_index.w
	RTS

SpellMenu_ScriptDoneShowStatus_Loop11:
	CheckButton BUTTON_BIT_B
	BNE.b	SpellMenu_ScriptDoneShowStatus_Loop26
	CheckButton BUTTON_BIT_C
	BEQ.w	SpellMenu_ScriptDoneShowStatus_Loop27
	PlaySound SOUND_MENU_SELECT
	TST.w	Dialog_selection.w
	BEQ.b	SpellMenu_ScriptDoneShowStatus_Loop28
	JSR	DrawLeftMenuWindow	
	JSR	DrawCenterMenuWindow	
	JSR	DrawStatusHudWindow	
	MOVE.w	#SPELLBOOK_STATE_WAIT_INPUT, Spellbook_menu_state.w	
	JSR	InitSpellbookCursor	
	RTS
	
SpellMenu_ScriptDoneShowStatus_Loop26:
	PlaySound SOUND_MENU_CANCEL
	JSR	DrawLeftMenuWindow
	MOVE.w	#SPELLBOOK_STATE_STATUS_D, Spellbook_menu_state.w
	MOVE.w	Possessed_magics_length.w, D0
	BRA.w	InitMenuCursorForList
	dc.b	$4E, $75 ; DEAD: orphan RTS opcode ($4E75) after unconditional BRA; unreachable
SpellMenu_ScriptDoneShowStatus_Loop28:
	JSR	DrawLeftMenuWindow
	JSR	DrawCenterMenuWindow
	JSR	ResetScriptAndInitDialogue
	LEA	Possessed_magics_list.w, A0
	MOVE.w	Magic_list_cursor_index.w, D0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), D0
	MOVE.w	#9, D1
	BTST.l	D1, D0
	BEQ.w	SpellMenu_ScriptDoneShowStatus_Loop29
	BSR.w	ClearMagicReadyFlags
	LEA	Text_build_buffer.w, A1
	LEA	BookOfStr, A0
	JSR	CopyStringUntilFF
	LEA	MagicNames, A0
	LEA	Possessed_magics_list.w, A2
	MOVE.w	Magic_list_cursor_index.w, D0
	ADD.w	D0, D0
	MOVE.w	(A2,D0.w), D0
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	CopyStringUntilFF
	LEA	BookReadyStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
	MOVE.w	#SPELLBOOK_STATE_CLOSE, Spellbook_menu_state.w
	LEA	Possessed_magics_list.w, A0
	MOVE.w	Magic_list_cursor_index.w, D0
	ADD.w	D0, D0
	LEA	(A0,D0.w), A0
	MOVE.w	(A0), Readied_magic.w
	ORI.w	#$8000, (A0)
	RTS

SpellMenu_ScriptDoneShowStatus_Loop29:
	PRINT 	CantUseBookInCombatStr
	MOVE.w	#SPELLBOOK_STATE_CLOSE, Spellbook_menu_state.w
	RTS

SpellMenu_ScriptDoneShowStatus_Loop27:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

SpellMenu_ScriptDoneShowStatus_Loop12:
	TST.b	Fade_in_lines_mask.w
	BNE.b	SpellMenu_ScriptDoneShowStatus_Loop30
	PRINT 	AreaBrightStr
	JSR	UpdateAreaVisibility
	MOVE.w	#SPELLBOOK_STATE_CAST_WAIT, Spellbook_menu_state.w
SpellMenu_ScriptDoneShowStatus_Loop30:
	RTS

SpellMenu_ScriptDoneShowStatus_Loop4:
	TST.b	Script_text_complete.w
	BEQ.b	SpellMenu_ScriptDoneShowStatus_Loop31
	JSR	SaveCenterDialogAreaToBuffer
	JSR	DrawMagicListBorders
	JSR	DrawMagicListWithMP
	CLR.w	Magic_list_cursor_index.w
	ADDQ.w	#1, Spellbook_menu_state.w
	MOVE.w	Possessed_magics_length.w, D0
	BRA.w	InitMenuCursorForList
SpellMenu_ScriptDoneShowStatus_Loop31:
	JSR	ProcessScriptText
	RTS

SpellMenu_ScriptDoneShowStatus_Loop5:
	CheckButton BUTTON_BIT_B
	BEQ.b	SpellMenu_ScriptDoneShowStatus_Loop32
	PlaySound SOUND_MENU_CANCEL
	BSR.w	DrawCenterMenuWindow
	BSR.w	DrawStatusHudWindow
	MOVE.w	#SPELLBOOK_STATE_WAIT_INPUT, Spellbook_menu_state.w
	BRA.w	InitSpellbookCursor
	dc.b	$4E, $75 ; DEAD: orphan RTS opcode ($4E75) after unconditional BRA; unreachable
SpellMenu_ScriptDoneShowStatus_Loop32:
	CheckButton BUTTON_BIT_C
	BEQ.w	SpellMenu_ScriptDoneShowStatus_Loop33
	MOVE.w	Magic_list_cursor_index.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	PlaySound SOUND_MENU_SELECT
	JSR	DrawCenterMenuWindow
	LEA	Possessed_magics_list.w, A0
	MOVE.w	Magic_list_cursor_index.w, D0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), D0
	ANDI.w	#$00FF, D0
	LEA	CastFieldMagicMap, A0
	ADD.w	D0, D0
	ADD.w	D0, D0
	JSR	(A0,D0.w)
	RTS

SpellMenu_ScriptDoneShowStatus_Loop33:
	MOVE.w	Magic_list_cursor_index.w, Menu_cursor_index.w
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Magic_list_cursor_index.w
	RTS

SpellMenu_ScriptDoneShowStatus_Loop6:
	TST.b	Script_text_complete.w	
	BEQ.b	SpellMenu_ScriptDoneShowStatus_Loop34	
	JSR	ResetScriptOutputVars	
	MOVE.l	Script_continuation_ptr.w, Script_source_base.w	
	ADDQ.w	#1, Spellbook_menu_state.w	
	RTS
	
SpellMenu_ScriptDoneShowStatus_Loop34:
	JSR	ProcessScriptText	
	RTS
	
SpellMenu_ScriptDoneShowStatus_Loop7:
	TST.b	Script_text_complete.w
	BEQ.w	SpellMenu_ScriptDoneShowHpMp
	CheckButton BUTTON_BIT_C
	BNE.b	SpellMenu_ScriptDoneShowStatus2
	CheckButton BUTTON_BIT_B
	BNE.b	SpellMenu_ScriptDoneShowStatus2
	RTS

SpellMenu_ScriptDoneShowStatus2:
	JSR	DrawStatusHudWindow
	MOVE.w	#SPELLBOOK_STATE_CAST_DONE, Spellbook_menu_state.w
	TriggerWindowRedraw WINDOW_DRAW_ITEM_SELL_TALL
	TST.b	Player_in_first_person_mode.w
	BEQ.b	SpellMenu_ScriptDoneShowHpMp
	JSR	DisplayPlayerHpMp
SpellMenu_ScriptDoneShowHpMp:
	JSR	ProcessScriptText
	RTS

SpellMenu_ScriptDoneShowHpMp_Loop:
	CheckButton BUTTON_BIT_B
	BEQ.b	SpellMenu_ScriptDoneShowHpMp_Loop2
	PlaySound SOUND_MENU_CANCEL
	BSR.w	DrawStatusMenuWindow
	MOVE.w	#SPELLBOOK_STATE_USE_INIT, Spellbook_menu_state.w
	RTS

SpellMenu_ScriptDoneShowHpMp_Loop2:
	CheckButton BUTTON_BIT_C
	BEQ.w	AriesMapMenu_HandleInput
	PlaySound SOUND_MENU_SELECT
	MOVE.w	Aries_selected_town.w, D0
	CMPI.w	#TOWN_HASTINGS1, D0
	BGT.w	AriesMapMenu_HandleInput
	LEA	Towns_visited.w, A0
	MOVE.b	(A0,D0.w), D1
	BEQ.w	AriesMapMenu_HandleInput
	JSR	DrawStatusMenuWindow
	LEA	TownOverworldCoords, A0
	MOVE.w	Aries_selected_town.w, D0
	ANDI.w	#$000F, D0
	ASL.w	#3, D0
	MOVE.w	(A0,D0.w), Player_position_x_outside_town.w
	MOVE.w	$2(A0,D0.w), Player_position_y_outside_town.w
	MOVE.w	$4(A0,D0.w), Player_map_sector_x.w
	MOVE.w	$6(A0,D0.w), Player_map_sector_y.w
	MOVE.w	#DIRECTION_UP, Player_direction.w
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.w	#GAMEPLAY_STATE_OVERWORLD_RELOAD, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Player_in_first_person_mode.w
	CLR.b	Is_in_cave.w
	PlaySound SOUND_FOOTSTEP
	RTS

AriesMapMenu_HandleInput:
	MOVE.w	#$000A, Menu_cursor_second_column_x.w
	MOVE.w	Aries_selected_town.w, Menu_cursor_index.w
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Aries_selected_town.w
	RTS

CheckAnyMagicReady:
	MOVE.w	Possessed_magics_length.w, D7
	SUBQ.w	#1, D7
	LEA	Possessed_magics_list.w, A0
CheckAnyMagicReady_Done:
	MOVE.w	(A0)+, D0
	MOVE.w	#9, D1
	BTST.l	D1, D0
	BEQ.b	CheckAnyMagicReady_Loop
	RTS

CheckAnyMagicReady_Loop:
	DBF	D7, CheckAnyMagicReady_Done
	CLR.w	D0	
	RTS
	
ClearMagicReadyFlags:
	MOVE.w	Possessed_magics_length.w, D7
	SUBQ.w	#1, D7
	LEA	Possessed_magics_list.w, A0
ClearMagicReadyFlags_Done:
	MOVE.w	#$000F, D1
	MOVE.w	(A0), D0
	BCLR.l	D1, D0
	MOVE.w	D0, (A0)+
	DBF	D7, ClearMagicReadyFlags_Done
	CLR.w	D0
	RTS

CastFieldMagicMap:
	BRA.w	CastFieldMagicNotAllowed	
	BRA.w	CastFieldMagicNotAllowed	
	BRA.w	CastFieldMagicNotAllowed	
	BRA.w	CastFieldMagicNotAllowed	
	BRA.w	CastFieldMagicNotAllowed	
	BRA.w	CastFieldMagicNotAllowed	
	BRA.w	CastFieldMagicNotAllowed	
	BRA.w	CastFieldMagicNotAllowed	
	BRA.w	CastFieldMagicNotAllowed	
	BRA.w	CastFieldMagicNotAllowed	
	BRA.w	CastFieldMagicNotAllowed	
	BRA.w	CastFieldMagicNotAllowed	
	BRA.w	CastFieldMagicNotAllowed	
	BRA.w	CastFieldMagicNotAllowed	
	BRA.w	CastAries
	BRA.w	CastExtrios
	BRA.w	CastInaudios
	BRA.w	CastLuminos
	BRA.w	CastSangua
	BRA.w	CastSanguia
	BRA.w	CastSanguio
	BRA.w	CastToxios
	BRA.w	CastSanguio

; Attempting to use battle magic in field
CastFieldMagicNotAllowed:
	JSR	ResetScriptAndInitDialogue	
	PRINT 	CantUseHereStr	
	MOVE.w	#SPELLBOOK_STATE_CAST_WAIT, Spellbook_menu_state.w	
	RTS

CastInaudios:
	JSR	CheckIfCursed
	BNE.w	SpellMenu_CursedError
	BSR.w	DeductMagicMP
	BNE.w	SpellMenu_NotEnoughMp
	TST.b	Player_in_first_person_mode.w
	BEQ.b	SpellMenu_CantUseHere1
	TST.b	Is_in_cave.w
	BNE.b	SpellMenu_CantUseHere1
	MOVE.w	#$001E, Inaudios_steps_remaining.w
	PlaySound SOUND_ITEM_PICKUP
	JSR	ResetScriptAndInitDialogue
	PRINT 	InaudiosSpellsStr
	MOVE.w	#SPELLBOOK_STATE_CAST_WAIT, Spellbook_menu_state.w
	RTS

SpellMenu_CantUseHere1:
	JSR	ResetScriptAndInitDialogue	
	PRINT 	CantUseHereStr	
	MOVE.w	#SPELLBOOK_STATE_CAST_WAIT, Spellbook_menu_state.w	
	RTS
	
CastLuminos:
	JSR	CheckIfCursed
	BNE.w	SpellMenu_CursedError
	BSR.w	DeductMagicMP
	BNE.w	SpellMenu_NotEnoughMp
	TST.b	Is_in_cave.w
	BEQ.b	SpellMenu_CantUseHere2
	TST.b	Cave_light_active.w
	BNE.b	SpellMenu_CantUseHere2
	MOVE.w	#SPELLBOOK_STATE_STATUS_F, Spellbook_menu_state.w
	MOVE.w	#PALETTE_IDX_CAVE_FLOOR_LIT, Palette_line_1_fade_target.w
	MOVE.w	#PALETTE_IDX_CAVE_ANIM_BASE, Palette_line_2_fade_target.w
	MOVE.b	#6, Fade_in_lines_mask.w
	CLR.w	Cave_light_timer.w
	MOVE.b	#1, Cave_light_active.w
	PlaySound SOUND_ENEMY_DEATH
	RTS

SpellMenu_CantUseHere2:
	JSR	ResetScriptAndInitDialogue
	PRINT 	BrightPlaceStr
	MOVE.w	#SPELLBOOK_STATE_CAST_WAIT, Spellbook_menu_state.w
	RTS

CastSangua:
	JSR	CheckIfCursed
	BNE.w	SpellMenu_CursedError
	BSR.w	DeductMagicMP
	BNE.w	SpellMenu_NotEnoughMp
	MOVE.w	#$0032, D0
	MOVE.w	Player_int.w, D1
	ASR.w	#3, D1
	ADD.w	D1, D0
	ADD.w	D0, Player_hp.w
	BRA.w	CastSanguia_Loop

CastSanguia:
	JSR	CheckIfCursed
	BNE.w	SpellMenu_CursedError
	BSR.w	DeductMagicMP
	BNE.w	SpellMenu_NotEnoughMp
	MOVE.w	#$00B4, D0
	MOVE.w	Player_int.w, D1
	ASR.w	#3, D1
	ADD.w	D1, D0
	ADD.w	D0, Player_hp.w
CastSanguia_Loop:
	MOVE.w	Player_hp.w, D0
	CMP.w	Player_mhp.w, D0
	BLE.b	CastSanguia_Loop2
	MOVE.w	Player_mhp.w, Player_hp.w
	PRINT 	AllHitPointsStr
	BRA.b	CastSanguia_Loop3
CastSanguia_Loop2:
	PRINT 	HitPointsRegainedStr
CastSanguia_Loop3:
	PlaySound SOUND_ITEM_PICKUP
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#SPELLBOOK_STATE_CAST_WAIT, Spellbook_menu_state.w
	RTS

CastSanguio:
	JSR	CheckIfCursed
	BNE.w	SpellMenu_CursedError
	BSR.w	DeductMagicMP
	BNE.w	SpellMenu_NotEnoughMp
	MOVE.w	Player_mhp.w, Player_hp.w
	PRINT 	AllHitPointsStr
	PlaySound SOUND_ITEM_PICKUP
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#SPELLBOOK_STATE_CAST_WAIT, Spellbook_menu_state.w
	RTS

CastToxios:
	JSR	CheckIfCursed
	BNE.w	SpellMenu_CursedError
	BSR.w	DeductMagicMP
	BNE.w	SpellMenu_NotEnoughMp
	PRINT 	PoisonPurgedStr
	TST.w	Player_poisoned.w
	BNE.b	CastToxios_Loop
	PRINT 	NotPoisonousStr
	BRA.b	UseAntidote_RemovePoison
CastToxios_Loop:
	TST.b	Player_greatly_poisoned.w
	BEQ.b	UseAntidote_RemovePoison
	PRINT 	PoisonTooStrongStr
	BRA.b	UseAntidote_RemovePoison_Loop
UseAntidote_RemovePoison:
	CLR.w	Player_poisoned.w
	CLR.b	Poison_notified.w
	PlaySound SOUND_ITEM_PICKUP
UseAntidote_RemovePoison_Loop:
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#SPELLBOOK_STATE_CAST_WAIT, Spellbook_menu_state.w
	RTS

CastAries:
	JSR	CheckIfCursed
	BNE.w	SpellMenu_CursedError
	BSR.w	DeductMagicMP
	BNE.w	SpellMenu_NotEnoughMp
	TST.b	Player_in_first_person_mode.w
	BEQ.b	SpellMenu_CantUseHere3
	TST.b	Is_in_cave.w
	BNE.w	SpellMenu_CantUseHere3
	JSR	SaveStatusMenuTiles
	JSR	DrawTownListWindow
	MOVE.w	#SPELLBOOK_STATE_SHOW_HP_MP, Spellbook_menu_state.w
	RTS
SpellMenu_CantUseHere3:
	PRINT 	CantUseHereStr
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#SPELLBOOK_STATE_CAST_WAIT, Spellbook_menu_state.w
	RTS

CastExtrios:
	JSR	CheckIfCursed
	BNE.w	SpellMenu_CursedError
	BSR.w	DeductMagicMP
	BNE.w	SpellMenu_NotEnoughMp
	TST.b	Is_in_cave.w
	BEQ.b	CastExtrios_Loop
	MOVE.w	Player_cave_position_x.w, Player_position_x_outside_town.w
	MOVE.w	Player_cave_position_y.w, Player_position_y_outside_town.w
	MOVE.w	Player_cave_map_sector_x.w, Player_map_sector_x.w
	MOVE.w	Player_cave_map_sector_y.w, Player_map_sector_y.w
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.w	#GAMEPLAY_STATE_OVERWORLD_RELOAD, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Player_in_first_person_mode.w
	CLR.b	Is_in_cave.w
	CLR.b	Cave_light_active.w
	CLR.w	Cave_light_timer.w
	PlaySound SOUND_FOOTSTEP
	RTS

CastExtrios_Loop:
	JSR	ResetScriptAndInitDialogue
	PRINT 	CantUseHereStr
	ADDQ.w	#2, Spellbook_menu_state.w
	RTS

SpellMenu_NotEnoughMp:
	PRINT 	NotEnoughMpStr	
	JSR	ResetScriptAndInitDialogue	
	MOVE.w	#SPELLBOOK_STATE_CAST_WAIT, Spellbook_menu_state.w	
	RTS
	
SpellMenu_CursedError:
	PRINT 	SorryYouAreCursedStr
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#SPELLBOOK_STATE_CAST_WAIT, Spellbook_menu_state.w
	RTS

TownOverworldCoords: ; Town locations. Without duplicates.
	; format:
	; dc.w (x_in_sector), (y_in_sector), (sector_x), (sector_y)
	dc.w	$8, $D, $0, $6 ; TOWN_WYCLIF
	dc.w	$7, $6, $1, $4 ; TOWN_PARMA
	dc.w	$8, $4, $6, $5 ; TOWN_WATLING
	dc.w	$4, $8, $4, $7 ; TOWN_DEEPDALE
	dc.w	$A, $5, $B, $7 ; TOWN_STOW
	dc.w	$4, $5, $E, $4 ; TOWN_KELTWICK
	dc.w	$4, $6, $C, $2 ; TOWN_MALAGA
	dc.w	$9, $5, $E, $0 ; TOWN_BARROW
	dc.w	$A, $6, $9, $1 ; TOWN_TADCASTER
	dc.w	$6, $F, $6, $0 ; TOWN_HELWIG
	dc.w	$7, $7, $1, $0 ; TOWN_SWAFFHAM
	dc.w	$A, $5, $5, $2 ; TOWN_EXCALABRIA
	dc.w	$5, $4, $9, $2 ; TOWN_HASTINGS
	dc.w	$8, $8, $A, $5 ; TOWN_CARTHAHENA

CastBattleMagicMap:
	BRA.w	CastAero
	BRA.w	CastAerios
	BRA.w	CastVolti
	BRA.w	CastVoltio
	BRA.w	CastVoltios
	BRA.w	CastFerros
	BRA.w	CastCopperos
	BRA.w	CastMercusios
	BRA.w	CastArgentos
	BRA.w	CastHydro
	BRA.w	CastHydro
	BRA.w	CastChronos
	BRA.w	CastChronios
	BRA.w	CastTerrafissi

CastAero:
	MOVEA.l	Object_slot_02_ptr.w, A6
	BTST.b	#7, (A6)
	BNE.w	CastAero_AlreadyActive
	BSR.w	CheckCursedAndConsumeReadiedMagicMp
	BNE.w	CastAero_AlreadyActive
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BSET.b	#5, obj_sprite_flags(A6)
	BSET.b	#6, obj_sprite_flags(A6)
	MOVE.w	#8, obj_hitbox_half_w(A6)
	MOVE.w	#$000C, obj_hitbox_half_h(A6)
	CLR.b	obj_move_counter(A6)
	CLR.b	obj_npc_busy_flag(A6)
	MOVE.b	#SPRITE_SIZE_3x2, obj_sprite_size(A6)
	MOVE.w	Player_direction.w, D1
	ANDI.w	#7, D1
	MOVE.b	D1, obj_direction(A6)
	MOVE.w	D1, D0
	ASL.w	#3, D0
	MOVE.w	D0, obj_attack_timer(A6)
	MOVE.w	#VRAM_TILE_PLAYER_SLASH, obj_tile_index(A6)
	LEA	SineTable, A0
	MOVE.l	#$400, D0
	ASL.w	#5, D1
	MOVE.b	(A0,D1.w), D2
	MOVE.b	$40(A0,D1.w), D3
	EXT.w	D2
	EXT.w	D3
	MULS.w	D0, D2
	MULS.w	D0, D3
	MOVE.l	D2, obj_vel_x(A6)
	MOVE.l	D3, obj_vel_y(A6)
	MOVE.w	obj_world_x(A5), obj_world_x(A6)
	MOVE.w	obj_world_y(A5), obj_world_y(A6)
	MOVE.l	#UpdateAeroProjectile, obj_tick_fn(A6)
	BSR.w	InitMagicDamageAndFlags
CastAero_AlreadyActive:
	RTS

UpdateAeroProjectile:
	TST.b	obj_npc_busy_flag(A5)
	BNE.w	DeactivateProjectile
	BSR.w	CheckProjectileHitEnemies
	BSET.b	#3, obj_sprite_flags(A5)
	CMPI.b	#4, obj_direction(A5)
	BLE.b	AeroProjectile_SkipFlipClear
	BCLR.b	#3, obj_sprite_flags(A5)
AeroProjectile_SkipFlipClear:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	MOVE.b	D0, D1
	SUBQ.b	#1, D1
	EOR.b	D1, D0
	BTST.l	#1, D0
	BEQ.b	AeroProjectile_UpdateSpriteAndMove
	ADDQ.b	#1, obj_direction(A5)
	ANDI.b	#7, obj_direction(A5)
AeroProjectile_UpdateSpriteAndMove:
	MOVE.b	obj_direction(A5), D0
	ANDI.w	#7, D0
	ADD.w	D0, D0
	LEA	AeroSpriteFrameTable, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.l	obj_vel_x(A5), D0
	SUB.l	D0, obj_world_x(A5)
	MOVE.l	obj_vel_y(A5), D0
	SUB.l	D0, obj_world_y(A5)
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A5), D1
	BSR.w	CheckCoordsInBounds
	BEQ.b	DeactivateProjectile
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	obj_world_y(A5), obj_sort_key(A5)
	JSR	AddSpriteToDisplayList
	RTS
DeactivateProjectile:
	BCLR.b	#7, (A5)
	RTS

CastAerios:
	MOVEA.l	Object_slot_02_ptr.w, A6
	BTST.b	#7, (A6)
	BNE.w	CastAerios_Done
	BSR.w	CheckCursedAndConsumeReadiedMagicMp
	BNE.w	CastAerios_Done
	BSR.w	InitMagicDamageAndFlags
	MOVEA.l	Object_slot_02_ptr.w, A3
	CLR.w	D1
	MOVE.w	#7, D7
AeriosInitProjectileLoop:
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BSET.b	#5, obj_sprite_flags(A6)
	BSET.b	#6, obj_sprite_flags(A6)
	MOVE.w	#8, obj_hitbox_half_w(A6)
	MOVE.w	#$000C, obj_hitbox_half_h(A6)
	CLR.b	obj_invuln_timer(A6)
	CLR.b	obj_move_counter(A6)
	CLR.b	obj_npc_busy_flag(A6)
	CLR.l	obj_hp(A6)
	CLR.w	obj_attack_timer(A6)
	MOVE.b	#SPRITE_SIZE_3x2, obj_sprite_size(A6)
	MOVE.b	D1, obj_direction(A6)
	MOVE.w	#VRAM_TILE_PLAYER_SLASH, obj_tile_index(A6)
	MOVE.l	#$400, obj_pos_x_fixed(A6)
	MOVE.w	$2C(A3), obj_max_hp(A6)
	MOVE.b	obj_behavior_flag(A3), obj_behavior_flag(A6)
	BSR.w	FindTargetEnemyForHoming
	MOVE.w	obj_world_x(A5), obj_world_x(A6)
	MOVE.w	obj_world_y(A5), obj_world_y(A6)
	MOVE.l	#UpdateHomingProjectile, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	ADDQ.w	#1, D1
	DBF	D7, AeriosInitProjectileLoop
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.l	#UpdateAeriosLeadProjectile, obj_tick_fn(A6)
CastAerios_Done:
	RTS

UpdateAeriosLeadProjectile:
	BSR.w	UpdateHomingProjectile
	BSR.w	CheckMagicSlotActiveOrClearAll
	RTS

UpdateHomingProjectile:
	TST.b	obj_npc_busy_flag(A5)
	BNE.w	MarkProjectileFinished
	BSR.w	CheckProjectileHitEnemies
	ADDQ.w	#1, obj_attack_timer(A5)
	MOVE.w	obj_attack_timer(A5), D0
	MOVE.b	D0, D1
	SUBQ.b	#1, D1
	EOR.b	D1, D0
	BTST.l	#3, D0
	BEQ.b	HomingProjectile_UpdateFlipFlag
	TST.l	obj_hp(A5)
	BEQ.b	HomingProjectile_UpdateFlipFlag
	MOVEA.l	obj_hp(A5), A6
	BTST.b	#7, (A6)
	BEQ.b	HomingProjectile_UpdateFlipFlag
	BSR.w	UpdateHomingProjectileDirection
