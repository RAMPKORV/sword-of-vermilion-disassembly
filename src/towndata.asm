; ======================================================================
; src/towndata.asm
; Town NPC data, tileset config, cave events, dialog helpers
; ======================================================================
;
; NOTE: This file begins mid-function. ASM68K assembles all included
; files as a single continuous stream, so the function body is split
; across the file boundary.
;
; The function ChestAnimation_Return starts in src/items.asm at the
; label ChestAnimation_Return (items.asm line 3283). items.asm ends
; without an RTS at line 3325, falling directly into this file.
;
; Code below (starting at BEQ ChestAnimation_Return_Loop8) is the
; reward-type dispatch within ChestAnimation_Return: it reads
; Reward_script_type and branches to the appropriate handler for each
; chest reward category (ring, money, map, or item/spell lookup).
;
	BEQ.w	ChestAnimation_Return_Loop8
	CMPI.w	#REWARD_TYPE_MONEY, D0
	BEQ.w	ChestAnimation_Return_Loop9
	CMPI.w	#REWARD_TYPE_MAP, D0
	BEQ.w	ChestAnimation_Return_Loop10
	ASL.w	#3, D0
	MOVEA.l	(A0,D0.w), A0
	MOVE.w	Reward_script_value.w, D0
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	CopyStringUntilFF
	LEA	InsideStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
	BRA.w	ChestReward_Display
ChestAnimation_Return_Loop8:
	LEA	RingNames, A0
	MOVE.w	Reward_script_value.w, D0
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	CopyStringUntilFF
	LEA	InsideStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
	BRA.w	ChestReward_Display
ChestAnimation_Return_Loop10:
	print	MapInsideStr
	BRA.w	ChestReward_Display
ChestAnimation_Return_Loop9:
	PRINT 	MoneyInsideStr
ChestReward_Display:
	JSR	ResetScriptOutputVars
	MOVE.w	#OPEN_MENU_STATE_MSG_WAIT, Open_menu_state.w
	RTS
	
ChestReward_Display_Loop:
	JSR	ProcessScriptText
	RTS
	
WriteChestAnimationToVRAM:
	MOVE.l	#$67100003, D5
	ORI	#$0700, SR
	MOVE.w	#5, D7
WriteChestAnimationToVRAM_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#3, D6
WriteChestAnimationToVRAM_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$A44C, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, WriteChestAnimationToVRAM_Done2
	MOVE.w	#2, D6
WriteChestAnimationToVRAM_Done3:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$AC4C, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, WriteChestAnimationToVRAM_Done3
	ADDI.l	#$00800000, D5
	DBF	D7, WriteChestAnimationToVRAM_Done
	ANDI	#$F8FF, SR
	RTS
	
CheckIfDoorIsLocked:
	LEA	FpDirectionDeltaForward, A2
	MOVE.w	Player_position_x_outside_town.w, D3
	MOVE.w	Player_position_y_outside_town.w, D4
	MOVE.w	Player_direction.w, D0
	ADD.w	D0, D0
	ADD.w	(A2,D0.w), D3
	ADD.w	$2(A2,D0.w), D4
	LEA	LockedDoorDataTable, A0
CheckIfDoorIsLocked_Done:
	LEA	(A0), A1
	MOVE.w	(A1)+, D0
	BLT.w	CheckBlockedDoor_NextEntry_Loop
	CMP.w	Current_cave_room.w, D0
	BNE.w	CheckBlockedDoor_NextEntry
	MOVE.w	(A1)+, D0
	CMP.w	D3, D0
	BNE.w	CheckBlockedDoor_NextEntry
	MOVE.w	(A1)+, D0
	CMP.w	D4, D0
	BNE.w	CheckBlockedDoor_NextEntry
	RTS
	
CheckBlockedDoor_NextEntry:
	LEA	$8(A0), A0
	BRA.b	CheckIfDoorIsLocked_Done
CheckBlockedDoor_NextEntry_Loop:
	MOVE.b	#FLAG_TRUE, Door_unlocked_flag.w
	RTS
	
LockedDoorDataTable:
	dc.b	$00, $16, $00, $0B, $00, $0D, $01, $11, $00, $28, $00, $02, $00, $05, $01, $12, $00, $23, $00, $03, $00, $0D, $01, $13, $00, $20, $00, $0C, $00, $0E, $01, $19 
	dc.b	$00, $20, $00, $03, $00, $03, $01, $16, $00, $20, $00, $0B, $00, $09, $01, $17, $00, $20, $00, $01, $00, $0F, $01, $18, $00, $22, $00, $01, $00, $05, $01, $16 
	dc.b	$00, $21, $00, $01, $00, $08, $01, $17, $00, $20, $00, $03, $00, $0B, $01, $18, $00, $2A, $00, $07, $00, $0D, $00, $1A, $00, $2B, $00, $0A, $00, $0A, $00, $25 
	dc.b	$FF, $FF 
DialogSelectionStateMachine:
	MOVE.w	Dialog_selection.w, D0
	ANDI.w	#$001F, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	DialogSelectionStateJumpTable, A0
	JSR	(A0,D0.w)
	RTS
	
DialogSelectionStateJumpTable:
	BRA.w	DialogSelectionStateJumpTable_Loop
	BRA.w	DialogSelection_Increment_Loop
	BRA.w	DialogSelection_Increment_Loop2
	BRA.w	DialogClose_RestoreHud_Loop
DialogSelectionStateJumpTable_Loop:
	MOVE.w	Main_menu_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.b	Player_in_first_person_mode.w
	BNE.w	DialogSelectionStateJumpTable_Loop2
	BSR.w	CheckIfTileIsEmpty
	BNE.w	DialogSelection_Increment
	MOVE.w	#3, Dialog_selection.w
	RTS
	
DialogSelectionStateJumpTable_Loop2:
	TST.b	Reward_script_active.w
	BNE.w	DialogSelectionStateJumpTable_Loop3
	TST.b	Herbs_available.w
	BNE.w	DialogSelectionStateJumpTable_Loop4
	TST.b	Truffles_available.w
	BNE.w	DialogSelectionStateJumpTable_Loop5
	TST.b	Talker_present_flag.w
	BNE.w	DialogSelectionStateJumpTable_Loop6
	BRA.w	DialogSelection_Increment
DialogSelectionStateJumpTable_Loop6:
	PRINT 	SomeoneStandingStr
	BRA.w	DialogSelect_ShowLookMessage
DialogSelectionStateJumpTable_Loop3:
	PRINT 	TreasureChestStr
	BRA.w	DialogSelect_ShowLookMessage
DialogSelectionStateJumpTable_Loop4:
	PRINT 	HerbsStillThereStr	
	BRA.w	DialogSelect_ShowLookMessage	
DialogSelectionStateJumpTable_Loop5:
	PRINT 	TrufflesStillThereStr	
DialogSelect_ShowLookMessage:
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#2, Dialog_selection.w
	RTS
	
DialogSelection_Increment:
	ADDQ.w	#1, Dialog_selection.w
	RTS
	
DialogSelection_Increment_Loop:
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	PRINT 	NoUnusualStr
	ADDQ.w	#1, Dialog_selection.w
	RTS
	
DialogSelection_Increment_Loop2:
	TST.b	Script_text_complete.w
	BEQ.w	DialogClose_RestoreHud_Loop2
	CheckButton BUTTON_BIT_C
	BNE.w	DialogClose_RestoreHud
	CheckButton BUTTON_BIT_B
	BNE.w	DialogClose_RestoreHud
	RTS
	
DialogClose_RestoreHud:
	JSR	DrawStatusHudWindow
	CLR.w	Overworld_menu_state.w
	TriggerWindowRedraw WINDOW_DRAW_MSG_SPEED_ALT
	RTS
	
DialogClose_RestoreHud_Loop2:
	JSR	ProcessScriptText
	RTS
	
DialogClose_RestoreHud_Loop:
	LEA	SeekCoordsByTown, A0
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
DialogClose_RestoreHud_Loop_Done:
	LEA	(A0), A1
	MOVE.w	(A1)+, D0
	BLT.w	DialogSelectState2_Wait_Loop
	CMP.w	Player_position_x_in_town.w, D0
	BNE.w	DialogSelectState2_Wait
	MOVE.w	(A1)+, D0
	CMP.w	Player_position_y_in_town.w, D0
	BNE.w	DialogSelectState2_Wait
	MOVE.w	(A1)+, D0
	MOVE.w	Player_direction.w, D1
	ASR.w	#1, D1
	BTST.l	D1, D0
	BEQ.w	DialogSelectState2_Wait
	MOVEA.l	(A1)+, A0
	JMP	(A0)
DialogSelectState2_Wait:
	LEA	$A(A0), A0
	BRA.b	DialogClose_RestoreHud_Loop_Done
DialogSelectState2_Wait_Loop:
	MOVE.w	#1, Dialog_selection.w
	RTS
	
CheckIfTileIsEmpty:
	JSR	GetCurrentTileType
	CMPI.w	#TOWN_TILE_PASSABLE_E, D0
	BNE.w	CheckIfTileIsEmpty_Loop
	CLR.w	D0
	RTS
	
CheckIfTileIsEmpty_Loop:
	MOVE.w	#$FFFF, D0
	RTS
	
SeekHandler_Tombstone:
	dc.b	$21, $FC 
	dc.l	TombstoneStr
	dc.b	$C2, $04, $60, $00, $01, $A2 
SeekHandler_TitaniasMirror:
	TST.b	Titanias_mirror_quest_prereq.w
	BEQ.w	SeekHandler_SetSelection1
	TST.b	Titanias_mirror_acquired.w	
	BNE.w	SeekHandler_SetSelection1	
	JSR	CheckInventoryFull	
	BGE.w	SeekHandler_TitaniasMirror_Loop	
	LEA	TitaniasMirrorStr, A2	
	BSR.w	DisplayFoundItemMessage	
	BSR.w	DisplayFoundItemWithName	
	JSR	AddItemToInventoryList	
	MOVE.w	#((ITEM_TYPE_DISCARDABLE<<8)|ITEM_TITANIAS_MIRROR), (A0,D0.w)
	MOVE.b	#FLAG_TRUE, Titanias_mirror_acquired.w	
	PlaySound SOUND_ATTACK	
	BRA.w	SeekHandler_TitaniasMirror_Loop2	
SeekHandler_TitaniasMirror_Loop:
	LEA	TitaniasMirrorStr, A2	
	BSR.w	DisplayFoundItemMessage	
	BSR.w	DisplayInventoryFullMessage	
SeekHandler_TitaniasMirror_Loop2:
	BRA.w	SeekHandler_DisplayAndReturn	
SeekHandler_SetSelection1:
	MOVE.w	#1, Dialog_selection.w
	RTS
	
SeekHandler_MegaBlast:
	TST.b	Mega_blast_acquired.w
	BNE.w	SeekHandler_MegaBlast_Loop
	JSR	CheckInventoryFull
	BGE.w	SeekHandler_MegaBlast_Loop2
	LEA	MegaBlastStr, A2
	BSR.w	DisplayFoundItemMessage
	BSR.w	DisplayFoundItemWithName
	JSR	AddItemToInventoryList
	MOVE.w	#((ITEM_TYPE_DISCARDABLE<<8)|ITEM_MEGA_BLAST), (A0,D0.w)
	MOVE.b	#FLAG_TRUE, Mega_blast_acquired.w
	PlaySound SOUND_ATTACK
	BRA.w	SeekHandler_MegaBlast_Loop3
SeekHandler_MegaBlast_Loop2:
	LEA	MegaBlastStr, A2
	BSR.w	DisplayFoundItemMessage
	BSR.w	DisplayInventoryFullMessage
SeekHandler_MegaBlast_Loop3:
	BRA.w	SeekHandler_DisplayAndReturn
SeekHandler_MegaBlast_Loop:
	MOVE.w	#1, Dialog_selection.w
	RTS
SeekHandler_RafaelsStick:
	TST.b	Rafaels_stick_acquired.w
	BNE.w	SeekHandler_RafaelsStick_Loop
	JSR	CheckInventoryFull
	BGE.w	SeekHandler_RafaelsStick_Loop2
	LEA	RafaelsStickStr, A2
	BSR.w	DisplayFoundItemMessage
	BSR.w	DisplayFoundItemWithName
	JSR	AddItemToInventoryList
	MOVE.w	#((ITEM_TYPE_DISCARDABLE<<8)|ITEM_RAFAELS_STICK), (A0,D0.w)
	MOVE.b	#FLAG_TRUE, Rafaels_stick_acquired.w
	PlaySound SOUND_ATTACK
	BRA.w	SeekHandler_RafaelsStick_Loop3
SeekHandler_RafaelsStick_Loop2:
	LEA	RafaelsStickStr, A2	
	BSR.w	DisplayFoundItemMessage	
	BSR.w	DisplayInventoryFullMessage	
SeekHandler_RafaelsStick_Loop3:
	BRA.w	SeekHandler_DisplayAndReturn
SeekHandler_RafaelsStick_Loop:
	MOVE.w	#1, Dialog_selection.w	
	RTS
	
SeekHandler_Herbs:
	JSR	CheckInventoryFull	
	BGE.w	SeekHandler_Herbs_Loop	
	LEA	HerbsStr, A2	
	BSR.w	DisplayFoundItemMessage	
	BSR.w	DisplayFoundItemWithName	
	JSR	AddItemToInventoryList	
	MOVE.w	#0, (A0,D0.w)	
	PlaySound SOUND_ATTACK	
	BRA.w	SeekHandler_Herbs_Loop2	
SeekHandler_Herbs_Loop:
	LEA	HerbsStr, A2	
	BSR.w	DisplayFoundItemMessage	
	BSR.w	DisplayInventoryFullMessage	
SeekHandler_Herbs_Loop2:
	BRA.w	SeekHandler_DisplayAndReturn	

SeekHandler_FindOneKim: ; Find 1kim
	LEA	OneKimStr, A2
	BSR.w	DisplayFoundItemMessage
	BSR.w	DisplayFoundItemWithName
	MOVE.l	#$00000001, Transaction_amount.w
	JSR	AddPaymentAmount
	PlaySound SOUND_ATTACK
	BRA.w	SeekHandler_DisplayAndReturn

SeekHandler_RegainAllHp: ; Regain all HP
	MOVE.w	Player_mhp.w, Player_hp.w
	PlaySound SOUND_ITEM_PICKUP
	MOVE.l	#AllHitPointsStr, Script_source_base.w
	BRA.w	SeekHandler_DisplayAndReturn

SeekHandler_DisplayAndReturn:
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#2, Dialog_selection.w
	RTS
	
SeekCoordsByTown: ; "Seek" coordinates by town
	dc.l	SeekData_BladesGrave
	dc.l	SeekData_BladesGrave
	dc.l	SeekData_BladesGrave
	dc.l	SeekData_Deepdale 
	dc.l	SeekData_BladesGrave
	dc.l	SeekData_BladesGrave 
	dc.l	SeekData_BladesGrave
	dc.l	SeekData_BladesGrave
	dc.l	SeekData_Tadcaster 
	dc.l	SeekData_BladesGrave 
	dc.l	SeekData_BladesGrave
	dc.l	SeekData_Excalabria
	dc.l	SeekData_Hastings
	dc.l	SeekData_BladesGrave 
	dc.l	SeekData_BladesGrave
	dc.l	SeekData_Swaffham
SeekData_BladesGrave: ; Blade's grave
	dc.w	$2B, $24
	dc.w	DIRECTION_DOWN
	dc.l	SeekHandler_Tombstone
	dc.w	$FFFF
SeekData_Deepdale:
	dc.w	$24, $26
	dc.w	DIRECTION_ANY
	dc.l	SeekHandler_RegainAllHp
	dc.w	$3, $10
	dc.w	DIRECTION_ANY
	dc.l	SeekHandler_FindOneKim
	dc.w	$FFFF
SeekData_Tadcaster:
	dc.w	$21, $F
	dc.w	DIRECTION_ANY
	dc.l	SeekHandler_MegaBlast 
	dc.w	$FFFF
SeekData_Excalabria:
	dc.w	$B, $15
	dc.w	DIRECTION_ANY
	dc.l	SeekHandler_RafaelsStick
	dc.w	$FFFF
SeekData_Hastings:
	dc.w	$A, $17
	dc.w	DIRECTION_ANY
	dc.l	SeekHandler_TitaniasMirror
	dc.w	$FFFF
SeekData_Swaffham:
	dc.w	$1F, $21
	dc.w	DIRECTION_ANY
	dc.l	SeekHandler_Herbs
	dc.w	$6, $21
	dc.w	DIRECTION_ANY
	dc.l	SeekHandler_RegainAllHp
	dc.w	$FFFF

FoundItemStr:
	dc.b	"found ", $FF, $00
FoundItemCommaStr:
	dc.b	",", $FE
	dc.b	"and received ", $FF
TooMuchToCarryStr:
	dc.b	",", $FE
	dc.b	"but there is too much", $FE
	dc.b	"here for you to carry.", $FF, $00
OneKimStr:
	dc.b	"1kim", $FF, $00

DisplayFoundItemMessage:
	JSR	CopyPlayerNameToTextBuffer
	LEA	FoundItemStr, A0
	JSR	CopyStringUntilFF
	MOVEA.l	A2, A0
	JSR	CopyStringUntilFF
	RTS
	
DisplayFoundItemWithName:
	LEA	FoundItemCommaStr, A0
	JSR	CopyStringUntilFF
	MOVEA.l	A2, A0
	JSR	CopyStringUntilFF
	MOVE.b	#$2E, (A1)+
	MOVE.b	#$FF, (A1)+
	PRINT 	Text_build_buffer
	RTS
	
DisplayInventoryFullMessage:
	LEA	TooMuchToCarryStr, A0	
	JSR	CopyStringUntilFF	
	MOVE.b	#$FF, (A1)+	
	PRINT 	Text_build_buffer	
	RTS
	
	
TakeItemStateMachine:
	MOVE.w	Take_item_state.w, D0
	ANDI.w	#$001F, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	TakeItemStateJumpTable, A0
	JSR	(A0,D0.w)
	RTS
	
TakeItemStateJumpTable:
	BRA.w	TakeItemStateJumpTable_Loop
	BRA.w	TakeItemStateJumpTable_Loop2
	BRA.w	TakeItemState_SetState2_Loop
	BRA.w	TakeItemState_SetState2_Loop2
	BRA.w	TakeItem_RestoreHud_Loop
	BRA.w	TakeItem_FinalizeTake_Loop
	BRA.w	TakeItem_FinalizeTake_Loop2
	BRA.w	TakeItem_DontWantMessage_Loop
	BRA.w	TakeItem_InitEquipCursor_Loop
	BRA.w	TakeItem_InitEquipCursor_Loop2
	BRA.w	TakeItem_InitEquipCursor_Loop3
TakeItemStateJumpTable_Loop:
	MOVE.w	Main_menu_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	ADDQ.w	#1, Take_item_state.w
	RTS
	
TakeItemStateJumpTable_Loop2:
	TST.b	Player_in_first_person_mode.w
	BEQ.w	TakeItemState_SetState2
	TST.b	Dialog_active_flag.w
	BEQ.w	TakeItemState_SetState2
	TST.b	Truffles_available.w
	BNE.w	TakeItemMenu_SetState4
	TST.b	Herbs_available.w
	BNE.w	TakeItemMenu_SetState4
	TST.b	Reward_script_active.w
	BEQ.w	TakeItemState_SetState2
TakeItemMenu_SetState4:
	MOVE.w	#TAKE_ITEM_STATE_BUILD_REWARD, Take_item_state.w
	RTS
	
TakeItemState_SetState2:
	MOVE.w	#TAKE_ITEM_STATE_NO_ITEM_MSG, Take_item_state.w
	RTS
	
TakeItemState_SetState2_Loop:
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	PRINT 	NothingToTakeStr
	ADDQ.w	#1, Take_item_state.w
	RTS
	
TakeItemState_SetState2_Loop2:
	TST.b	Script_text_complete.w
	BEQ.w	TakeItem_RestoreHud_Loop2
	CheckButton BUTTON_BIT_C
	BNE.w	TakeItem_RestoreHud
	CheckButton BUTTON_BIT_B
	BNE.w	TakeItem_RestoreHud
	RTS
	
TakeItem_RestoreHud:
	JSR	DrawStatusHudWindow
	CLR.w	Overworld_menu_state.w
	TriggerWindowRedraw WINDOW_DRAW_MSG_SPEED_ALT
	RTS
	
TakeItem_RestoreHud_Loop2:
	JSR	ProcessScriptText
	RTS
	
TakeItem_RestoreHud_Loop:
	TST.b	Herbs_available.w
	BNE.w	TakeItemState_BuildReward
	TST.b	Truffles_available.w
	BNE.w	TakeItemState_BuildReward
	TST.b	Chest_opened_flag.w
	BEQ.w	TakeItemState_BuildReward_Loop
	TST.b	Reward_script_available.w
	BNE.w	TakeItemState_BuildReward
	PRINT 	NothingToTakeStr	
	BRA.w	TakeItemState_BuildReward_Loop2	
TakeItemState_BuildReward:
	BSR.w	BuildRewardItemMessage
	RTS
	
TakeItemState_BuildReward_Loop:
	PRINT 	CantTakeBoxStr
TakeItemState_BuildReward_Loop2:
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#TAKE_ITEM_STATE_MSG_WAIT, Take_item_state.w
	RTS
	
BuildRewardItemMessage:
	JSR	CopyPlayerNameToTextBuffer
	LEA	TakesStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	LEA	ShopCategoryNameTables, A0
	MOVE.w	Reward_script_type.w, D0
	CMPI.w	#REWARD_TYPE_RING, D0
	BEQ.w	BuildRewardItemMessage_Loop
	CMPI.w	#REWARD_TYPE_MONEY, D0
	BEQ.w	BuildRewardItemMessage_Loop2
	CMPI.w	#REWARD_TYPE_MAP, D0
	BEQ.w	BuildRewardItemMessage_Loop3
	ASL.w	#3, D0
	MOVEA.l	$4(A0,D0.w), A2
	MOVEA.l	(A0,D0.w), A0
	MOVE.w	Reward_script_value.w, D1
	MOVE.w	(A2), D0
	CMPI.w	#8, D0
	BGE.w	TakeItem_FinalizeTake_Loop3
	ADDQ.w	#1, (A2)
	ADD.w	D0, D0
	MOVE.w	Reward_script_value.w, D1
	MOVE.w	D1, $2(A2,D0.w)
	ANDI.w	#$00FF, D1
	ADD.w	D1, D1
	ADD.w	D1, D1
	MOVEA.l	(A0,D1.w), A0
	JSR	CopyStringUntilFF
	BRA.w	TakeItem_FinalizeTake
BuildRewardItemMessage_Loop3:
	LEA	Map_trigger_flags.w, A0
	MOVE.w	Reward_script_value.w, D0
	MOVE.b	#$FF, (A0,D0.w)
	MOVE.b	#FLAG_TRUE, Area_map_revealed.w
	JSR	UpdateAreaVisibility
	MOVEA.l	#AreaMapStr, A0
	JSR	CopyStringUntilFF
	BRA.w	TakeItem_FinalizeTake
BuildRewardItemMessage_Loop:
	LEA	RingNames, A0
	MOVE.w	Reward_script_value.w, D0
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	CopyStringUntilFF
	BRA.w	TakeItem_FinalizeTake
BuildRewardItemMessage_Loop2:
	MOVEQ	#0, D0
	MOVE.w	Reward_script_value.w, D0
	MOVE.l	D0, Transaction_amount.w
	JSR	AddPaymentAmount
	JSR	DisplayPlayerKimsAndExperience
	JSR	CopyPlayerNameToTextBuffer
	LEA	TakesStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	MOVEQ	#0, D0
	MOVE.w	Reward_script_value.w, D0
	JSR	FormatKimsAmount
TakeItem_FinalizeTake:
	MOVE.b	#$2E, (A1)+
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
	PlaySound SOUND_ERROR
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	BSR.w	ClearRewardScriptFlag
	MOVE.w	#TAKE_ITEM_STATE_FINALIZE, Take_item_state.w
	CLR.b	Herbs_available.w
	CLR.b	Truffles_available.w
	CLR.b	Reward_script_available.w
	RTS
	
TakeItem_FinalizeTake_Loop3:
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	PRINT 	CantCarryMoreStr
	MOVE.w	#TAKE_ITEM_STATE_FULL_MSG, Take_item_state.w
	RTS
	
TakeItem_FinalizeTake_Loop:
	TST.b	Script_text_complete.w
	BEQ.w	TakeItem_FinalizeTake_Loop4
	CLR.w	Dialog_selection.w
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
	MOVE.w	#TAKE_ITEM_STATE_CONFIRM, Take_item_state.w
	RTS
	
TakeItem_FinalizeTake_Loop4:
	JSR	ProcessScriptText
	RTS
	
TakeItem_FinalizeTake_Loop2:
	CheckButton BUTTON_BIT_B
	BNE.w	TakeItem_DontWantMessage
	CheckButton BUTTON_BIT_C
	BEQ.w	TakeItem_DontWantMessage_Loop2
	PlaySound SOUND_MENU_SELECT
	TST.w	Dialog_selection.w
	BNE.w	TakeItem_DontWantMessage
	JSR	DrawLeftMenuWindow
	PRINT 	DiscardWhichItemStr
	MOVE.w	#TAKE_ITEM_STATE_DISCARD_LIST, Take_item_state.w
	RTS
	
TakeItem_DontWantMessage:
	JSR	DrawLeftMenuWindow
	JSR	ResetScriptAndInitDialogue
	LEA	Text_build_buffer.w, A1
	LEA	DontWantCarryStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	LEA	ShopCategoryNameTables, A0
	MOVE.w	Reward_script_type.w, D0
	ASL.w	#3, D0
	MOVEA.l	(A0,D0.w), A0
	MOVE.w	Reward_script_value.w, D1
	ANDI.w	#$00FF, D1
	ADD.w	D1, D1
	ADD.w	D1, D1
	MOVEA.l	(A0,D1.w), A0
	JSR	CopyStringUntilFF
	MOVE.b	#$2E, (A1)+
	MOVE.b	#$FF, (A1)
	MOVE.w	#TAKE_ITEM_STATE_MSG_WAIT, Take_item_state.w
	PRINT 	Text_build_buffer
	RTS
	
TakeItem_DontWantMessage_Loop2:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS
	
TakeItem_DontWantMessage_Loop:
	TST.b	Script_text_complete.w
	BEQ.w	TakeItem_InitEquipCursor_Loop4
	JSR	SaveCenterDialogAreaToBuffer
	MOVE.w	Reward_script_type.w, D0
	BEQ.w	TakeItem_DontWantMessage_Loop3
	CMPI.w	#REWARD_TYPE_EQUIPMENT, D0
	BEQ.w	TakeItem_DontWantMessage_Loop4
	JSR	DrawMagicListBorders
	JSR	DrawMagicListWithMP
	MOVE.l	#Possessed_magics_list, Active_inventory_list_ptr.w
	MOVE.w	Possessed_magics_length.w, D0
	BRA.w	TakeItem_InitEquipCursor
TakeItem_DontWantMessage_Loop3:
	JSR	DrawItemListBorders
	JSR	DrawItemListNames
	MOVE.l	#Possessed_items_list, Active_inventory_list_ptr.w
	MOVE.w	Possessed_items_length.w, D0
	BRA.w	TakeItem_InitEquipCursor
TakeItem_DontWantMessage_Loop4:
	JSR	DrawEquipmentListWindow
	JSR	DrawPossessedEquipmentList
	MOVE.l	#Possessed_equipment_list, Active_inventory_list_ptr.w
	MOVE.w	Possessed_equipment_length.w, D0
TakeItem_InitEquipCursor:
	JSR	InitMenuCursorForList
	MOVE.w	#TAKE_ITEM_STATE_ITEM_CURSOR, Take_item_state.w
	RTS
	
TakeItem_InitEquipCursor_Loop4:
	JSR	ProcessScriptText	
	RTS
	
TakeItem_InitEquipCursor_Loop:
	CheckButton BUTTON_BIT_B
	BEQ.w	TakeItem_InitEquipCursor_Loop5
	PlaySound SOUND_MENU_CANCEL
	JSR	DrawCenterMenuWindow
	JSR	ResetScriptAndInitDialogue
	PRINT 	CantCarryMoreStr
	MOVE.w	#TAKE_ITEM_STATE_FULL_MSG, Take_item_state.w
	RTS
	
TakeItem_InitEquipCursor_Loop5:
	CheckButton BUTTON_BIT_C
	BEQ.w	TakeItem_InitEquipCursor_Loop6
	JSR	DrawMenuCursor
	PlaySound SOUND_MENU_SELECT
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
	MOVE.w	#TAKE_ITEM_STATE_DISCARD_CONFIRM, Take_item_state.w
	RTS
	
TakeItem_InitEquipCursor_Loop6:
	MOVE.w	Selected_item_index.w, Menu_cursor_index.w
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Selected_item_index.w
	RTS
	
TakeItem_InitEquipCursor_Loop2:
	CheckButton BUTTON_BIT_B
	BNE.w	TakeItem_InitEquipCursor_Loop7
	CheckButton BUTTON_BIT_C
	BEQ.w	TakeItem_InitEquipCursor_Loop8
	PlaySound SOUND_MENU_SELECT
	TST.w	Dialog_selection.w
	BEQ.w	TakeItem_InitEquipCursor_Loop9
TakeItem_InitEquipCursor_Loop7:
	PlaySound SOUND_MENU_CANCEL	
	JSR	DrawLeftMenuWindow	
	MOVEA.l	Active_inventory_list_ptr.w, A0	
	MOVE.w	-$2(A0), D0	
	JSR	InitMenuCursorForList	
	MOVE.w	#TAKE_ITEM_STATE_ITEM_CURSOR, Take_item_state.w	
	RTS
	
TakeItem_InitEquipCursor_Loop9: ; Discard item
	JSR	DrawLeftMenuWindow
	JSR	DrawCenterMenuWindow
	JSR	ResetScriptAndInitDialogue
	MOVEA.l	Active_inventory_list_ptr.w, A2
	MOVE.w	Selected_item_index.w, D0
	ADD.w	D0, D0
	MOVE.w	(A2,D0.w), D0
	ANDI.w	#(ITEM_TYPE_NON_DISCARDABLE<<8), D0
	BEQ.w	TakeItem_InitEquipCursor_Loop10
	PRINT 	CantPutDownStr
	BRA.w	TakeItem_InitEquipCursor_Loop11
TakeItem_InitEquipCursor_Loop10:
	PlaySound SOUND_ERROR
	LEA	Text_build_buffer.w, A1
	LEA	PutStr, A0
	JSR	CopyStringUntilFF
	LEA	ShopCategoryNameTables, A0
	MOVE.w	Reward_script_type.w, D0
	ASL.w	#3, D0
	MOVEA.l	$4(A0,D0.w), A2
	MOVEA.l	(A0,D0.w), A0
	MOVE.w	Selected_item_index.w, D0
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	LEA	$2(A2,D0.w), A2
	MOVE.w	(A2), D0
	MOVE.w	Reward_script_value.w, (A2)
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	CopyStringUntilFF
	LEA	PutDownStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	MOVE.b	#$61, (A1)+
	MOVE.b	#$6E, (A1)+
	MOVE.b	#$64, (A1)+
	MOVE.b	#$20, (A1)+
	LEA	TakesStr, A0
	JSR	CopyStringUntilFF
	LEA	ShopCategoryNameTables, A0
	MOVE.w	Reward_script_type.w, D0
	ASL.w	#3, D0
	MOVEA.l	(A0,D0.w), A0
	MOVE.w	Reward_script_value.w, D0
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	CopyStringUntilFF
	MOVE.b	#$2E, (A1)+
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
	BSR.w	ClearRewardScriptFlag
	CLR.b	Herbs_available.w
	CLR.b	Truffles_available.w
	CLR.b	Reward_script_available.w
	MOVE.w	#TAKE_ITEM_STATE_FINALIZE, Take_item_state.w
	RTS
	
TakeItem_InitEquipCursor_Loop11:
	MOVE.w	#TAKE_ITEM_STATE_MSG_WAIT, Take_item_state.w
	RTS
	
TakeItem_InitEquipCursor_Loop8:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS
	
TakeItem_InitEquipCursor_Loop3:
	TST.b	Script_text_complete.w
	BEQ.w	TakeItem_RestoreHudWithMusic_Loop
	CheckButton BUTTON_BIT_C
	BNE.w	TakeItem_RestoreHudWithMusic
	CheckButton BUTTON_BIT_B
	BNE.w	TakeItem_RestoreHudWithMusic
	RTS
	
TakeItem_RestoreHudWithMusic:
	MOVE.w	Current_area_music.w, D0
	JSR	QueueSoundEffect
	JSR	DrawStatusHudWindow
	CLR.w	Overworld_menu_state.w
	TriggerWindowRedraw WINDOW_DRAW_MSG_SPEED_ALT
	RTS
	
TakeItem_RestoreHudWithMusic_Loop:
	JSR	ProcessScriptText
	RTS
	
; ---------------------------------------------------------------------------
; ClearRewardScriptFlag
; If Reward_script_flag holds a RAM pointer, writes $FF to that address and
; clears the pointer.  Called after a chest/found-item reward is accepted.
; ---------------------------------------------------------------------------
ClearRewardScriptFlag:
	MOVEA.l	Reward_script_flag.w, A0
	CMPA.l	#0, A0
	BEQ.w	ClearRewardScriptFlag_Loop
	MOVE.b	#$FF, (A0)
	CLR.l	Reward_script_flag.w
ClearRewardScriptFlag_Loop:
	RTS
	
; ---------------------------------------------------------------------------
; BossParallaxEntry_Start — write one parallax nametable row to VDP
;
; Reads a packed parameter record from the address in A0 (auto-incremented)
; and DMA-writes one row of tile words to the VDP nametable, offset by the
; current HScroll/VScroll base values.
;
; Called 110 times — all call sites are in miscdata.asm and towndata.asm,
; each preceded by a LEA <RecordLabel>, A0.
;
; Input:
;   A0    pointer to BossParallaxEntry record:
;           +0  dc.l   VDP VRAM write-command (nametable row address)
;           +4  dc.w   column count - 1  (DBF loop counter)
;           +6  dc.w   tile index offset added to each tile byte
;           +8  dc.b[] tile bytes (one per column)
;
; Scratch:  D0-D4
; Output:   VDP nametable row written; A0 advanced past record
; ---------------------------------------------------------------------------
BossParallaxEntry_Start:
	MOVE.l	(A0)+, D0
	MOVE.w	(A0)+, D1
	MOVE.w	(A0)+, D2
	MOVE.w	HScroll_base.w, D3
	ASR.w	#3, D3
	MOVE.w	VScroll_base.w, D4
	ASR.w	#3, D4
	ASL.w	#6, D4
	ADD.w	D3, D4
	SWAP	D4
	ANDI.l	#$1FFF0000, D4
	ADD.l	D4, D0
	MOVE.l	D0, VDP_control_port
BossParallaxEntry_ColumnLoop:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADD.w	D2, D0
	MOVE.w	D0, VDP_data_port
	DBF	D1, BossParallaxEntry_ColumnLoop
	RTS
WyclifNpcDialogueDispatch:
	LEA	Wyclif_Npc1_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Wyclif_Npc1_DialogueStates:
	dc.l	TownDialogTable_Wyclif_State2
	dc.l	Rings_collected
	dc.l	TownDialogTable_Wyclif_State1
	dc.l	Event_triggers_start
	dc.l	TownDialogTable_Wyclif_State0
Wyclif_Npc2_Dispatch:
	LEA	Wyclif_Npc2_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Wyclif_Npc2_DialogueStates:
	dc.l	TownDialogTable_Wyclif_State5
	dc.l	Rings_collected
	dc.l	TownDialogTable_Wyclif_State4
	dc.l	Event_triggers_start
	dc.l	TownDialogTable_Wyclif_State3
Wyclif_Npc3_Dispatch:
	LEA	Wyclif_Npc3_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Wyclif_Npc3_DialogueStates:
	dc.l	TownDialogTable_Wyclif_State8 
	dc.l	Rings_collected
	dc.l	TownDialogTable_Wyclif_State7
	dc.l	Event_triggers_start
	dc.l	TownDialogTable_Wyclif_State6
Wyclif_Npc4_SimpleDispatch:
	LEA	TownDialogTable_Wyclif_State9, A1
	BRA.w	SelectDialogueSimple
Wyclif_Npc4_Dispatch:
	LEA	Wyclif_Npc4_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Wyclif_Npc4_DialogueStates:
	dc.l	TownDialogTable_Wyclif_State12
	dc.l	Rings_collected
	dc.l	TownDialogTable_Wyclif_State11
	dc.l	Event_triggers_start
	dc.l	TownDialogTable_Wyclif_State10	
Wyclif_Npc5_SimpleDispatch:
	LEA	TownDialogTable_Wyclif_State13, A1
	BRA.w	SelectDialogueSimple
Wyclif_Npc5_Dispatch:
	LEA	Wyclif_Npc5_DialogueStates, A1
	MOVE.w	#0, D7
	BRA.w	SelectDialogueByGameState
Wyclif_Npc5_DialogueStates:
	dc.l	TownDialogTable_Wyclif_State15
	dc.l	Rings_collected
	dc.l	TownDialogTable_Wyclif_State14
ParmaaNpcDialogueDispatch:
	LEA	Parma_Npc1_DialogueStates, A1
	MOVE.w	#4, D7
	BRA.w	SelectDialogueByGameState
Parma_Npc1_DialogueStates:
	dc.l	TownDialogTable_Parma_State4
	dc.l	Talked_to_real_king
	dc.l	TownDialogTable_Parma_State3	
	dc.l	Player_chose_to_stay_in_parma
	dc.l	TownDialogTable_Parma_State2
	dc.l	Fake_king_killed
	dc.l	TownDialogTable_Parma_State3
	dc.l	Treasure_of_troy_given_to_king
	dc.l	TownDialogTable_Parma_State1
	dc.l	Treasure_of_troy_challenge_issued
	dc.l	TownDialogTable_Parma_State0
Parma_Npc1_State5_Dispatch:
	LEA	TownDialogTable_Parma_State5, A1
	BRA.w	SelectDialogueSimple
Parma_Npc1_State6_Dispatch:
	LEA	TownDialogTable_Parma_State6, A1
	BRA.w	SelectDialogueSimple
Parma_Npc1_State7_Dispatch:
	LEA	TownDialogTable_Parma_State7, A1
	BRA.w	SelectDialogueSimple
Parma_Npc1_State8_Dispatch:
	LEA	TownDialogTable_Parma_State8, A1
	BRA.w	SelectDialogueSimple
Parma_Npc1_State9_Dispatch:
	LEA	TownDialogTable_Parma_State9, A1
	BRA.w	SelectDialogueSimple
Parma_Npc1_ConditionA_Dispatch:
	LEA	ParmaNpc1_ConditionData_A, A1
	MOVE.w	#0, D7
	BRA.w	SelectDialogueByGameState
ParmaNpc1_ConditionData_A:
	dc.l	TownDialogTable_Parma_State15_GameOver	; game-complete dialogue
	dc.l	Talked_to_real_king
	dc.l	TownDialogTable_Parma_State15
Parma_Npc1_ConditionB_Dispatch:
	LEA	ParmaNpc1_ConditionData_B, A1
	MOVE.w	#0, D7
	BRA.w	SelectDialogueByGameState
ParmaNpc1_ConditionData_B:
	dc.l	TownDialogTable_Parma_State10_GameOver	; game-complete dialogue
	dc.l	Fake_king_killed
	dc.l	TownDialogTable_Parma_State10
Parma_Npc1_ConditionC_Dispatch:
	LEA	ParmaNpc1_ConditionData_C, A1
	MOVE.w	#0, D7
	BRA.w	SelectDialogueByGameState
ParmaNpc1_ConditionData_C:
	dc.l	TownDialogTable_Parma_State11_GameOver	; game-complete dialogue
	dc.l	Fake_king_killed
	dc.l	TownDialogTable_Parma_State11
Parma_Npc1_ConditionD_Dispatch:
	LEA	ParmaNpc1_ConditionData_D, A1
	MOVE.w	#0, D7
	BRA.w	SelectDialogueByGameState
ParmaNpc1_ConditionData_D:
	dc.l	TownDialogTable_Parma_State12_GameOver	; game-complete dialogue
	dc.l	Fake_king_killed
	dc.l	TownDialogTable_Parma_State12
	LEA	Parma_Npc2_DialogueStates, A1
	MOVE.w	#4, D7
	BRA.w	SelectDialogueByGameState
Parma_Npc2_DialogueStates:
	dc.l	CastleDialogTable_Parma_State5
	dc.l	Talked_to_real_king
	dc.l	CastleDialogTable_Parma_State4
	dc.l	Fake_king_killed
	dc.l	CastleDialogTable_Parma_State3
	dc.l	Treasure_of_troy_given_to_king
	dc.l	CastleDialogTable_Parma_State2
	dc.l	Treasure_of_troy_found
	dc.l	CastleDialogTable_Parma_State1
	dc.l	Treasure_of_troy_challenge_issued
	dc.l	CastleDialogTable_Parma_State0
	LEA	ParmaNpc3_ConditionData, A1	; fall-through from Parma_Npc2_DialogueStates
	MOVE.w	#0, D7
	BRA.w	SelectDialogueByGameState
ParmaNpc3_ConditionData:
	dc.l	CastleDialogTable_Parma_State6_GameOver	; game-complete dialogue
	dc.l	Player_chose_to_stay_in_parma
	dc.l	CastleDialogTable_Parma_State6
Parma_Npc3_Condition_Dispatch:
	LEA	ParmaNpc4_ConditionData, A1
	MOVE.w	#2, D7
	BRA.w	SelectDialogueByGameState
ParmaNpc4_ConditionData:
	dc.l	TownDialogTable_Parma_State14_GameOver	; game-complete dialogue
	dc.l	Talked_to_real_king
	dc.l	TownDialogTable_Parma_State13
	dc.l	Treasure_of_troy_found
	dc.l	TownDialogTable_Parma_State14
	dc.l	Treasure_of_troy_challenge_issued
	dc.l	TownDialogTable_Parma_State13
WatlingNpcDialogueDispatch:
	LEA	Watling_Npc1_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Watling_Npc1_DialogueStates:
	dc.l	TownDialogTable_Watling_State3
	dc.l	Watling_villagers_asked_about_rings
	dc.l	TownDialogTable_Watling_State2
	dc.l	Watling_youth_restored
	dc.l	TownDialogTable_Watling_State1
Watling_Npc2_Dispatch:
	LEA	Watling_Npc2_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Watling_Npc2_DialogueStates:
	dc.l	TownDialogTable_Watling_State6
	dc.l	Watling_villagers_asked_about_rings
	dc.l	TownDialogTable_Watling_State5
	dc.l	Watling_youth_restored
	dc.l	TownDialogTable_Watling_State4
DeepdaleNpcDialogueDispatch:
	LEA	Deepdale_Npc1_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Deepdale_Npc1_DialogueStates:
	dc.l	TownDialogTable_Deepdale_State2
	dc.l	Deepdale_king_secret_kept
	dc.l	TownDialogTable_Deepdale_State1
	dc.l	Deepdale_truffle_quest_started
	dc.l	TownDialogTable_Deepdale_State0
Deepdale_Npc2_Dispatch:
	LEA	Deepdale_Npc2_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Deepdale_Npc2_DialogueStates:
	dc.l	TownDialogTable_Deepdale_State5
	dc.l	Deepdale_king_secret_kept
	dc.l	TownDialogTable_Deepdale_State4
	dc.l	Truffle_collected
	dc.l	TownDialogTable_Deepdale_State3
	LEA	Deepdale_Npc3_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Deepdale_Npc3_DialogueStates:
	dc.l	CastleDialogTable_Deepdale_State2
	dc.l	Deepdale_king_secret_kept
	dc.l	CastleDialogTable_Deepdale_State1
	dc.l	Deepdale_truffle_quest_started
	dc.l	CastleDialogTable_Deepdale_State0
	dc.l	$43F90003	; inline bytes: LEA $00030A72,A1
	dc.l	$0A726000	; inline bytes: BRA.w Deepdale_Npc3_SimpleDispatch
	dc.b	$04, $18	; inline bytes: (branch displacement)
Deepdale_Npc3_SimpleDispatch:
	LEA	TownDialogTable_Deepdale_State6, A1
	BRA.w	SelectDialogueSimple
StowNpcDialogueDispatch:
	LEA	Stow_Npc1_DialogueStates, A1
	MOVE.w	#3, D7
	BRA.w	SelectDialogueByGameState
Stow_Npc1_DialogueStates:
	dc.l	TownDialogTable_Stow1_State4
	dc.l	Stow_innocence_proven
	dc.l	TownDialogTable_Stow1_State3
	dc.l	Girl_left_for_stow
	dc.l	TownDialogTable_Stow1_State2
	dc.l	Accused_of_theft
	dc.l	TownDialogTable_Stow1_State1
	dc.l	Sanguios_book_offered
	dc.l	TownDialogTable_Stow1_State0	
Stow_Npc2_Dispatch:
	LEA	Stow_Npc2_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Stow_Npc2_DialogueStates:
	dc.l	TownDialogTable_Stow1_State7
	dc.l	Stow_innocence_proven
	dc.l	TownDialogTable_Stow1_State6
	dc.l	Girl_left_for_stow
	dc.l	TownDialogTable_Stow1_State5
	LEA	Stow_Npc3_DialogueStates, A1	; fall-through from Stow_Npc2_DialogueStates
	MOVE.w	#4, D7
	BRA.w	SelectDialogueByGameState
Stow_Npc3_DialogueStates:
	dc.l	CastleDialogTable_Stow_State5
	dc.l	Stow_innocence_proven
	dc.l	CastleDialogTable_Stow_State4
	dc.l	Asti_monster_defeated
	dc.l	CastleDialogTable_Stow_State3
	dc.l	Girl_left_for_stow
	dc.l	CastleDialogTable_Stow_State2	
	dc.l	Accused_of_theft
	dc.l	CastleDialogTable_Stow_State1
	dc.l	Sanguios_book_offered
	dc.l	CastleDialogTable_Stow_State0	
Stow_Npc3_State8_Dispatch:
	LEA	TownDialogTable_Stow1_State8, A1
	BRA.w	SelectDialogueSimple
Stow_Npc3_State9_Dispatch:
	LEA	TownDialogTable_Stow1_State9, A1
	BRA.w	SelectDialogueSimple
Stow_Npc3_State10_Dispatch:
	LEA	TownDialogTable_Stow1_State10, A1
	BRA.w	SelectDialogueSimple
KeltwickNpcDialogueDispatch:
	LEA	Keltwick_Npc1_DialogueStates, A1
	MOVE.w	#3, D7
	BRA.w	SelectDialogueByGameState
Keltwick_Npc1_DialogueStates:
	dc.l	TownDialogTable_Keltwick_State3_GameOver	; game-complete dialogue
	dc.l	Bearwulf_returned_home
	dc.l	TownDialogTable_Keltwick_State3
	dc.l	Bearwulf_met
	dc.l	TownDialogTable_Keltwick_State2
	dc.l	Sent_to_malaga
	dc.l	TownDialogTable_Keltwick_State1
	dc.l	Asti_monster_defeated
	dc.l	TownDialogTable_Keltwick_State0	
Keltwick_Npc1_State4_Dispatch:
	LEA	TownDialogTable_Keltwick_State4, A1
	BRA.w	SelectDialogueSimple
Keltwick_Npc2_Dispatch:
	LEA	Keltwick_Npc2_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Keltwick_Npc2_DialogueStates:
	dc.l	TownDialogTable_Keltwick_State7
	dc.l	Sent_to_malaga
	dc.l	TownDialogTable_Keltwick_State6	
	dc.l	Alarm_clock_rang
	dc.l	TownDialogTable_Keltwick_State5
Keltwick_Npc2_State8_Dispatch:
	LEA	TownDialogTable_Keltwick_State8, A1
	BRA.w	SelectDialogueSimple
Keltwick_Npc2_State9_Dispatch:
	LEA	TownDialogTable_Keltwick_State9, A1
	BRA.w	SelectDialogueSimple
MalagaNpcDialogueDispatch:
	LEA	Malaga_Npc1_DialogueStates, A1
	MOVE.w	#2, D7
	BRA.w	SelectDialogueByGameState
Malaga_Npc1_DialogueStates:
	dc.l	TownDialogTable_Malaga_State2_GameOver	; game-complete dialogue
	dc.l	Bearwulf_returned_home
	dc.l	TownDialogTable_Malaga_State2
	dc.l	Barrow_map_received
	dc.l	TownDialogTable_Malaga_State1
	dc.l	Malaga_king_crowned
	dc.l	TownDialogTable_Malaga_State0
	LEA	Malaga_Npc2_DialogueStates, A1
	MOVE.w	#2, D7
	BRA.w	SelectDialogueByGameState
Malaga_Npc2_DialogueStates:
	dc.l	CastleDialogTable_Malaga_State2_GameOver	; game-complete dialogue
	dc.l	Bearwulf_returned_home
	dc.l	CastleDialogTable_Malaga_State2
	dc.l	Barrow_map_received
	dc.l	CastleDialogTable_Malaga_State1
	dc.l	Malaga_king_crowned
	dc.l	CastleDialogTable_Malaga_State0
Malaga_Npc2_SimpleDispatch:
	LEA	TownDialogTable_Malaga_State3, A1
	BRA.w	SelectDialogueSimple
BarrowNpcDialogueDispatch:
	LEA	Barrow_Npc1_DialogueStates, A1
	MOVE.w	#0, D7
	BRA.w	SelectDialogueByGameState
Barrow_Npc1_DialogueStates:
	dc.l	TownDialogTable_Barrow_State1
	dc.l	Uncle_tibor_visited
	dc.l	TownDialogTable_Barrow_State0
Barrow_Npc2_Dispatch:
	LEA	Barrow_Npc2_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Barrow_Npc2_DialogueStates:
	dc.l	TownDialogTable_Barrow_State4_GameOver	; game-complete dialogue
	dc.l	Pass_to_carthahena_purchased
	dc.l	TownDialogTable_Barrow_State4
	dc.l	Uncle_tibor_visited
	dc.l	TownDialogTable_Barrow_State3
Barrow_Npc2_SimpleDispatch:
	LEA	TownDialogTable_Barrow_State2, A1
	BRA.w	SelectDialogueSimple
TadcasterNpcDialogueDispatch:
	LEA	Tadcaster_Npc1_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Tadcaster_Npc1_DialogueStates:
	dc.l	TownDialogTable_Tadcaster_State2
	dc.l	Imposter_killed
	dc.l	TownDialogTable_Tadcaster_State1
	dc.l	Bully_first_fight_won
	dc.l	TownDialogTable_Tadcaster_State0
	LEA	Tadcaster_Npc2_DialogueStates, A1	; fall-through from Tadcaster_Npc1_DialogueStates
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Tadcaster_Npc2_DialogueStates:
	dc.l	CastleDialogTable_Tadcaster_State1_GameOver	; game-complete dialogue
	dc.l	Imposter_killed
	dc.l	CastleDialogTable_Tadcaster_State1	
	dc.l	Bully_first_fight_won
	dc.l	CastleDialogTable_Tadcaster_State0
Tadcaster_Npc3_Dispatch:
	LEA	Tadcaster_Npc3_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Tadcaster_Npc3_DialogueStates:
	dc.l	TownDialogTable_Tadcaster_State4_GameOver	; game-complete dialogue
	dc.l	Imposter_killed
	dc.l	TownDialogTable_Tadcaster_State4	
	dc.l	Bully_first_fight_won
	dc.l	TownDialogTable_Tadcaster_State3
Tadcaster_Npc3_State5_Dispatch:
	LEA	TownDialogTable_Tadcaster_State5, A1
	BRA.w	SelectDialogueSimple
Tadcaster_Npc4_Dispatch:
	LEA	Tadcaster_Npc4_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Tadcaster_Npc4_DialogueStates:
	dc.l	TownDialogTable_Tadcaster_State7_GameOver	; game-complete dialogue
	dc.l	Imposter_killed
	dc.l	TownDialogTable_Tadcaster_State7	
	dc.l	Bully_first_fight_won
	dc.l	TownDialogTable_Tadcaster_State6
HelwigNpcDialogueDispatch:
	LEA	Helwig_Npc1_DialogueStates, A1
	MOVE.w	#0, D7
	BRA.w	SelectDialogueByGameState
Helwig_Npc1_DialogueStates:
	dc.l	TownDialogTable_Helwig_State1
	dc.l	Helwig_men_rescued
	dc.l	TownDialogTable_Helwig_State0
Helwig_Npc2_Dispatch:
	LEA	Helwig_Npc2_DialogueStates, A1
	MOVE.w	#0, D7
	BRA.w	SelectDialogueByGameState
Helwig_Npc2_DialogueStates:
	dc.l	TownDialogTable_Helwig_State3
	dc.l	Helwig_men_rescued
	dc.l	TownDialogTable_Helwig_State2
Helwig_Npc2_SimpleDispatch:
	LEA	TownDialogTable_Helwig_State4, A1
	BRA.w	SelectDialogueSimple
SwaffhamNpcDialogueDispatch:
	LEA	Swaffham_Npc1_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Swaffham_Npc1_DialogueStates:
	dc.l	TownDialogTable_Swaffham_State2
	dc.l	Swaffham_ruined
	dc.l	TownDialogTable_Swaffham_State1
	dc.l	Ring_of_earth_obtained
	dc.l	TownDialogTable_Swaffham_State0
	LEA	Swaffham_Npc2_DialogueStates, A1
	MOVE.w	#6, D7
	BRA.w	SelectDialogueByGameState
Swaffham_Npc2_DialogueStates:
	dc.l	CastleDialogTable_Swaffham_State4_GameOver	; game-complete dialogue
	dc.l	Ring_of_earth_obtained
	dc.l	CastleDialogTable_Swaffham_State3
	dc.l	Blue_crystal_received
	dc.l	CastleDialogTable_Swaffham_State4	
	dc.l	Blue_crystal_quest_started
	dc.l	CastleDialogTable_Swaffham_State2
	dc.l	Red_crystal_received
	dc.l	CastleDialogTable_Swaffham_State4	
	dc.l	Red_crystal_quest_started
	dc.l	CastleDialogTable_Swaffham_State1
	dc.l	Ring_of_wind_received
	dc.l	CastleDialogTable_Swaffham_State4	
	dc.l	White_crystal_quest_started
	dc.l	CastleDialogTable_Swaffham_State0
ExcalabriaaNpcDialogueDispatch:
	LEA	Excalabria_Npc1_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Excalabria_Npc1_DialogueStates:
	dc.l	TownDialogTable_Excalabria_State2
	dc.l	Knute_informed_of_swaffham_ruin
	dc.l	TownDialogTable_Excalabria_State1
	dc.l	Ring_of_earth_obtained
	dc.l	TownDialogTable_Excalabria_State0	
HastingsNpcDialogueDispatch:
	LEA	Hastings_Npc1_DialogueStates, A1
	MOVE.w	#2, D7
	BRA.w	SelectDialogueByGameState
Hastings_Npc1_DialogueStates:
	dc.l	Hastings_Npc1_DialogueStates_TileData_3A0B2
	dc.l	Digot_plant_received
	dc.l	Hastings_Npc1_DialogueStates_TileData_3A08A
	dc.l	Swaffham_ate_poisoned_food
	dc.l	TownDialogTable_Hastings_State1
	dc.l	Ate_spy_dinner
	dc.l	TownDialogTable_Hastings_State0
Hastings_Npc2_Dispatch:
	LEA	Hastings_Npc2_DialogueStates, A1
	MOVE.w	#1, D7
	BRA.w	SelectDialogueByGameState
Hastings_Npc2_DialogueStates:
	dc.l	Hastings_Npc2_DialogueStates_TileData_3A0F6
	dc.l	Spy_dinner_poisoned_flag
	dc.l	Hastings_Npc2_DialogueStates_TileData_3A0F2
	dc.l	Ate_spy_dinner
	dc.l	Hastings_Npc2_DialogueStates_TileData_3A0EE
Hastings_Npc2_SubDispatch_A:
	dc.l	$43F90003	; inline bytes: LEA $0003A0DA,A1
	dc.l	$A0DA6000	; inline bytes: BRA.w Hastings_Npc2_SubDispatch_B
	dc.w	$0098		; inline bytes: (branch displacement)
Hastings_Npc2_SubDispatch_B:
	dc.w	$43F9		; inline bytes: LEA opword
	dc.l	Hastings_Npc2_SubDispatch_B_Entry_3A0E2	; inline bytes: LEA target address
	dc.l	$6000008E	; inline bytes: BRA.w Hastings_Npc3_Dispatch
Hastings_Npc3_Dispatch:
	LEA	Hastings_Npc3_DialogueStates, A1
	MOVE.w	#0, D7
	BRA.w	SelectDialogueByGameState
Hastings_Npc3_DialogueStates:
	dc.l	Hastings_Npc3_DialogueStates_TileData_3A0FA_GameOver	; game-complete dialogue
	dc.l	Pass_to_carthahena_purchased
	dc.l	Hastings_Npc3_DialogueStates_TileData_3A0FA
CarthahenaaNpcDialogueDispatch:
	LEA	CarthahenaaNpcDialogueDispatch_Data3, A0
	TST.b	Tsarkon_is_dead.w
	BNE.b	SelectCastleDialog_Carthahena_Return
	LEA	CarthahenaaNpcDialogueDispatch_Data2, A0
	TST.b	Pass_to_carthahena_purchased.w
	BNE.b	SelectCastleDialog_Carthahena_Return
	LEA	CarthahenaaNpcDialogueDispatch_Data, A0	
SelectCastleDialog_Carthahena_Return:
	RTS
	
SelectCastleDialog_Carthahena:
	LEA	CastleDialogTable_Carthahena_State1, A0
	TST.b	Tsarkon_is_dead.w
	BNE.b	SelectCastleDialog_Carthahena_Return_Loop
	LEA	CastleDialogTable_Carthahena_State0, A0
SelectCastleDialog_Carthahena_Return_Loop:
	RTS
	
CarthahenaaNpcSubDispatch:
	LEA	CarthahenaaNpcSubDispatch_Data2, A0
	TST.b	Tsarkon_is_dead.w
	BNE.b	CarthahenaaNpcSubDispatch_Loop
	LEA	CarthahenaaNpcSubDispatch_Data, A0
CarthahenaaNpcSubDispatch_Loop:
	RTS
	
; CheckGameComplete
; Check if game is completed (Tsarkon defeated)
; Output: D0 = 0 if not complete, $FFFF if complete
CheckGameComplete:
	LEA	EndingCelebrationStrings, A0
	TST.b	Tsarkon_is_dead.w
	BNE.b	CheckGameComplete_Loop
	CLR.w	D0
	RTS

CheckGameComplete_Loop:
	MOVE.w	#$FFFF, D0
	RTS

; SelectDialogueByGameState
; Select dialogue string from table based on game completion state
; Iterates through paired pointers until finding one with matching trigger state
SelectDialogueByGameState:
	BSR.b	CheckGameComplete
	BNE.b	SelectDialogTable_Found
SelectDialogueByGameState_Done:
	MOVEA.l	(A1)+, A0
	MOVEA.l	(A1)+, A2
	TST.b	(A2)
	BNE.b	SelectDialogTable_Found
	DBF	D7, SelectDialogueByGameState_Done
	MOVEA.l	(A1), A0
SelectDialogTable_Found:
	RTS
	
SelectDialogueSimple:
	BSR.b	CheckGameComplete
	BNE.b	SelectDialogueSimple_Loop
	MOVEA.l	A1, A0
SelectDialogueSimple_Loop:
	RTS
	
TalkDirectionDeltaTable:
	dc.w	0, -1 
	dc.w	-1, 0 
	dc.w	0, 1 
	dc.w	1, 0 
	dc.w	8, 8 
TownRoomTilemapPlaneAPtrs:
	dc.l	LoadTownTilemap_Wyclif_PlaneA
	dc.l	LoadTownTilemap_ParmaAndMalaga_PlaneA
	dc.l	LoadTownTilemap_Watling_PlaneA
	dc.l	LoadTownTilemap_Deepdale_PlaneA
	dc.l	LoadTownTilemap_Stow1_PlaneA
	dc.l	LoadTownTilemap_Stow2AndKeltwick_PlaneA	
	dc.l	LoadTownTilemap_Stow2AndKeltwick_PlaneA
	dc.l	LoadTownTilemap_ParmaAndMalaga_PlaneA
	dc.l	LoadTownTilemap_Barrow_PlaneA
	dc.l	LoadTownTilemap_Tadcaster_PlaneA
	dc.l	LoadTownTilemap_Helwig_PlaneA
	dc.l	LoadTownTilemap_Swaffham_PlaneA
	dc.l	LoadTownTilemap_Excalabria_PlaneA
	dc.l	LoadTownTilemap_Hastings_PlaneA
	dc.l	LoadTownTilemap_Hastings_PlaneA	
	dc.l	LoadTownTilemap_Carthahena_PlaneA
	dc.l	LoadCastleTilemap_DefaultSmall_PlaneA
	dc.l	LoadCastleTilemap_Parma_PlaneA
	dc.l	LoadCastleTilemap_MediumA_PlaneA	
	dc.l	LoadCastleTilemap_MediumA_PlaneA
	dc.l	LoadCastleTilemap_MediumB_PlaneA
	dc.l	LoadCastleTilemap_DefaultSmall_PlaneA	
	dc.l	LoadCastleTilemap_DefaultSmall_PlaneA	
	dc.l	LoadCastleTilemap_Malaga_PlaneA
	dc.l	LoadCastleTilemap_DefaultSmall_PlaneA	
	dc.l	LoadCastleTilemap_MediumA_PlaneA
	dc.l	LoadCastleTilemap_DefaultSmall_PlaneA	
	dc.l	LoadCastleTilemap_MediumB_PlaneA
	dc.l	LoadCastleTilemap_DefaultSmall_PlaneA	
	dc.l	LoadCastleTilemap_DefaultSmall_PlaneA	
	dc.l	LoadCastleTilemap_DefaultSmall_PlaneA	
	dc.l	LoadCastleTilemap_MediumA_PlaneA
	dc.l	LoadBuildingTilemap_20_PlaneA
	dc.l	LoadBuildingTilemap_21_PlaneA
	dc.l	LoadBuildingTilemap_22_PlaneA
	dc.l	LoadBuildingTilemap_23_PlaneA
	dc.l	LoadBuildingTilemap_24_PlaneA
	dc.l	LoadBuildingTilemap_25_PlaneA
	dc.l	LoadBuildingTilemap_26_PlaneA
	dc.l	LoadBuildingTilemap_27_PlaneA
	dc.l	LoadBuildingTilemap_28_PlaneA
	dc.l	LoadBuildingTilemap_29_PlaneA	
	dc.l	LoadBuildingTilemap_2A_PlaneA
	dc.l	LoadBuildingTilemap_2B_PlaneA
	dc.l	LoadBuildingTilemap_2C_PlaneA
	dc.l	LoadBuildingTilemap_2D_PlaneA
	dc.l	LoadBuildingTilemap_2E_PlaneA
	dc.l	LoadBuildingTilemap_2F_PlaneA
	dc.l	LoadBuildingTilemap_30_PlaneA
	dc.l	LoadBuildingTilemap_31_PlaneA
	dc.l	LoadBuildingTilemap_32_PlaneA
	dc.l	LoadBuildingTilemap_33_PlaneA
	dc.l	LoadBuildingTilemap_34_PlaneA
	dc.l	LoadBuildingTilemap_35_PlaneA
TownRoomTilemapPlaneBPtrs:
	dc.l	LoadTownTilemap_Wyclif_PlaneB
	dc.l	LoadTownTilemap_ParmaAndMalaga_PlaneB
	dc.l	LoadTownTilemap_Watling_PlaneB
	dc.l	LoadTownTilemap_Deepdale_PlaneB
	dc.l	LoadTownTilemap_Stow1_PlaneB
	dc.l	LoadTownTilemap_Stow2AndKeltwick_PlaneB	
	dc.l	LoadTownTilemap_Stow2AndKeltwick_PlaneB
	dc.l	LoadTownTilemap_ParmaAndMalaga_PlaneB
	dc.l	LoadTownTilemap_Barrow_PlaneB
	dc.l	LoadTownTilemap_Tadcaster_PlaneB
	dc.l	LoadTownTilemap_Helwig_PlaneB
	dc.l	LoadTownTilemap_Swaffham_PlaneB
	dc.l	LoadTownTilemap_Excalabria_PlaneB
	dc.l	LoadTownTilemap_Hastings_PlaneB
	dc.l	LoadTownTilemap_Hastings_PlaneB	
	dc.l	LoadTownTilemap_Carthahena_PlaneB
	dc.l	LoadCastleTilemap_DefaultSmall_PlaneB
	dc.l	LoadCastleTilemap_Parma_PlaneB
	dc.l	LoadCastleTilemap_MediumA_PlaneB	
	dc.l	LoadCastleTilemap_MediumA_PlaneB
	dc.l	LoadCastleTilemap_MediumB_PlaneB
	dc.l	LoadCastleTilemap_DefaultSmall_PlaneB	
	dc.l	LoadCastleTilemap_DefaultSmall_PlaneB	
	dc.l	LoadCastleTilemap_Malaga_PlaneB
	dc.l	LoadCastleTilemap_DefaultSmall_PlaneB	
	dc.l	LoadCastleTilemap_MediumA_PlaneB
	dc.l	LoadCastleTilemap_DefaultSmall_PlaneB	
	dc.l	LoadCastleTilemap_MediumB_PlaneB
	dc.l	LoadCastleTilemap_DefaultSmall_PlaneB	
	dc.l	LoadCastleTilemap_DefaultSmall_PlaneB	
	dc.l	LoadCastleTilemap_DefaultSmall_PlaneB	
	dc.l	LoadCastleTilemap_MediumA_PlaneB
	dc.l	LoadBuildingTilemap_20_PlaneB
	dc.l	LoadBuildingTilemap_21_PlaneB
	dc.l	LoadBuildingTilemap_22_PlaneB
	dc.l	LoadBuildingTilemap_23_PlaneB
	dc.l	LoadBuildingTilemap_24_PlaneB
	dc.l	LoadBuildingTilemap_25_PlaneB
	dc.l	LoadBuildingTilemap_26_PlaneB
	dc.l	LoadBuildingTilemap_27_PlaneB
	dc.l	LoadBuildingTilemap_28_PlaneB
	dc.l	LoadBuildingTilemap_29_PlaneB	
	dc.l	LoadBuildingTilemap_2A_PlaneB
	dc.l	LoadBuildingTilemap_2B_PlaneB
	dc.l	LoadBuildingTilemap_2C_PlaneB
	dc.l	LoadBuildingTilemap_2D_PlaneB
	dc.l	LoadBuildingTilemap_2E_PlaneB
	dc.l	LoadBuildingTilemap_2F_PlaneB
	dc.l	LoadBuildingTilemap_30_PlaneB
	dc.l	LoadBuildingTilemap_31_PlaneB
	dc.l	LoadBuildingTilemap_32_PlaneB
	dc.l	LoadBuildingTilemap_33_PlaneB
	dc.l	LoadBuildingTilemap_34_PlaneB
	dc.l	LoadBuildingTilemap_35_PlaneB
TownTilesetPtrs:
	dc.l	TownTilesetPtrs_Gfx_8B38A
	dc.l	TownTilesetPtrs_Gfx_8DAE0
	dc.l	TownTilesetPtrs_Gfx_8FEE6
	dc.l	NULL_PTR 
	dc.l	TownTilesetPtrs_Gfx_9239A
DialogueChoiceNoStrPtrs:
	dc.l	NoChoiceStr
	dc.l	RingOfSkyGiftStr
	dc.l	WhyHereStr
	dc.l	BuyItStr 
	dc.l	JustBorrowedBookStr
	dc.l	DontRefuseUsStr
	dc.l	WhyHereStr
	dc.l	WhyHereStr
	dc.l	TurnDownBargainStr
	dc.l	TurnDownBargainStr2 
	dc.l	HurryBringBackHusbandsStr
	dc.l	BreakMothersHeartStr
	dc.l	OneOfUsWillDieStr
DialogueChoiceYesStrPtrs:
	dc.l	OffYouGoStr
	dc.l	DecideToLiveHereStr
	dc.l	BoughtFromMeStr
	dc.l	MoreNeatStuffStr
	dc.l	ThankYouStr3
	dc.l	KeepRingOfWaterStr
	dc.l	CantAffordPassStr
	dc.l	TooMuchGearStr 
	dc.l	NotEnoughMoneyStr2
	dc.l	NoRoomMoreBooksStr 
	dc.l	LazySlugStr
	dc.l	ChaosReignStr
	dc.l	ChaosReignStr
TownTileGfxTable: ; Tile mappings + graphics by town
	townTileGfxEntry TownTileSet_A_Mappings,TownTileSet_A_Gfx,$0097

	townTileGfxEntry TownTileSet_B_Mappings,TownTileSet_B_Gfx,$0039

	townTileGfxEntry TownTileSet_A_Mappings,TownTileSet_A_Gfx,$0097

	townTileGfxEntry TownTileSet_B_Mappings,TownTileSet_B_Gfx,$0039

	townTileGfxEntry TownTileSet_B_Mappings,TownTileSet_B_Gfx,$0039

	townTileGfxEntry TownTileSet_B_Mappings,TownTileSet_B_Gfx,$0039

	townTileGfxEntry TownTileSet_B_Mappings,TownTileSet_B_Gfx,$0039

	townTileGfxEntry TownTileSet_B_Mappings,TownTileSet_B_Gfx,$0039

	townTileGfxEntry TownTileSet_A_Mappings,TownTileSet_A_Gfx,$0097

	townTileGfxEntry TownTileSet_B_Mappings,TownTileSet_B_Gfx,$0039

	townTileGfxEntry TownTileSet_A_Mappings,TownTileSet_A_Gfx,$0097

	townTileGfxEntry TownTileSet_B_Mappings,TownTileSet_B_Gfx,$0039

	dc.l	SpriteGfxData_8E0C8	; Excalabria/ruin tileset (anomalous — raw sprite data ptrs)
	dc.l	SpriteGfxData_8FB08
	dc.w	$001E

	townTileGfxEntry TownTileSet_A_Mappings,TownTileSet_A_Gfx,$0097

	townTileGfxEntry TownTileSet_B_Mappings,TownTileSet_B_Gfx,$0039

	townTileGfxEntry TownTileSet_B_Mappings,TownTileSet_B_Gfx,$0039
LoadTownTileGraphics_Data:
	dc.l	SpriteGfxData_8E0C8
LoadTownTileGfx_LookupTable_Loop_Done_Data:
	dc.l	SpriteGfxData_8FB08
LoadTownTileGfx_LookupTable_Loop_Done_Data2:
	dc.w	$001E
DmaCmd_TownTileset_Wyclif:
	dc.b	$94, $10, $93, $00, $96, $D0, $95, $00, $97, $7F, $60, $00, $00, $81, $00, $00 
DmaCmd_TownTileset_Parma:
	dc.b	$94, $0C, $93, $00, $96, $D0, $95, $00, $97, $7F, $40, $00, $00, $82, $00, $00 
DmaCmd_TownTileGfxSet1_A:
	dc.b	$94, $0B, $93, $70, $96, $D0, $95, $00, $97, $7F, $47, $80, $00, $80, $00, $00 
DmaCmd_TownTileGfxSet1_B:
	dc.b	$94, $0D, $93, $A0, $96, $D0, $95, $00, $97, $7F, $5E, $60, $00, $80, $00, $00 
DmaCmd_TownNpcGfx:
	dc.b	$94, $06, $93, $C0, $96, $D0, $95, $00, $97, $7F, $79, $A0, $00, $80, $00, $00 
DmaCmd_TownTileGfxSet1_D:
	dc.b	$94, $09, $93, $E0, $96, $D0, $95, $00, $97, $7F, $4C, $60, $00, $81, $00, $00 
DmaCmd_TownTileGfxSet1_E:
	dc.b	$94, $02, $93, $A0, $96, $D0, $95, $00, $97, $7F, $47, $20, $00, $81, $00, $00 
DmaCmd_OverworldStatusTiles:
	dc.b	$94, $03, $93, $A0, $96, $D0, $95, $00, $97, $7F, $40, $40, $00, $80, $00, $00 
DmaCmd_MenuTilesA:
	dc.b	$94, $10, $93, $00, $96, $D0, $95, $00, $97, $7F, $50, $00, $00, $80, $00, $00 
DmaCmd_MenuTilesB:
	dc.b	$94, $04, $93, $30, $96, $D0, $95, $00, $97, $7F, $70, $00, $00, $80, $00, $00 
DmaCmd_MenuMiscTilesA:
	dc.b	$94, $01, $93, $B0, $96, $D0, $95, $00, $97, $7F, $40, $40, $00, $80, $00, $00 
DmaCmd_MenuMiscTilesB:
	dc.b	$94, $00, $93, $80, $96, $D0, $95, $00, $97, $7F, $43, $A0, $00, $80, $00, $00 
DmaCmd_OptionsMenuTiles:
	dc.b	$94, $03, $93, $D0, $96, $D0, $95, $00, $97, $7F, $47, $80, $00, $80, $00, $00 
DmaCmd_TitleScreenTilesA:
	dc.b	$94, $04, $93, $E0, $96, $D0, $95, $00, $97, $7F, $50, $00, $00, $80, $00, $00 
DmaCmd_TitleScreenTilesB:
	dc.b	$94, $06, $93, $D0, $96, $D0, $95, $00, $97, $7F, $60, $00, $00, $80, $00, $00 
DmaCmd_TitleScreenTilesC:
	dc.b	$94, $06, $93, $30, $96, $D0, $95, $00, $97, $7F, $70, $00, $00, $80, $00, $00 
DmaCmd_TitleScreenTilesD:
	dc.b	$94, $05, $93, $00, $96, $D0, $95, $00, $97, $7F, $40, $00, $00, $81, $00, $00 
DmaCmd_TitleScreenTilesE:
	dc.b	$94, $05, $93, $20, $96, $D0, $95, $00, $97, $7F, $50, $00, $00, $81, $00, $00 
DmaCmd_TitleScreenTilesF:
	dc.b	$94, $00, $93, $60, $96, $D0, $95, $00 
	dc.l	$977F6000	
	dc.l	$00810000	
TerrainTileGfxDmaPtrs:
	dc.l	DmaCmd_TerrainTileset_0
	dc.l	DmaCmd_TerrainTileset_1
	dc.l	DmaCmd_TerrainTileset_2
	dc.l	DmaCmd_TerrainTileset_3
DmaCmd_TerrainTileset_0:
	dc.l	$94049330	
	dc.l	$96D09500	
	dc.l	$977F6000	
	dc.l	$00810000	
DmaCmd_TerrainTileset_1:
	dc.l	$94049350	
	dc.l	$96D09500	
	dc.l	$977F6000	
	dc.l	$00810000	
DmaCmd_TerrainTileset_2:
	dc.l	$94049350	
	dc.l	$96D09500	
	dc.l	$977F6000	
	dc.l	$00810000	
DmaCmd_TerrainTileset_3:
	dc.l	$94039390	
	dc.l	$96D09500	
	dc.l	$977F6000	
	dc.l	$00810000	
DmaCmd_BattleTiles:
	dc.l	$940193B0	
	dc.l	$96D09500	
	dc.l	$977F7980	
	dc.l	$00810000	
TerrainTilemapPtrs:
	dc.l	TerrainTilemapPtrs_Gfx_68CA2
	dc.l	SpriteAnimFrameTable_69592
	dc.l	SpriteAnimFrameTable_69592
	dc.l	TerrainTilemapPtrs_Gfx_6E028
TerrainTilemapMetadata:
	dc.l	TerrainTilemapMetadata_Gfx_68E5A
	dc.l	$00430049	
	dc.l	SpriteGfxData_6974A
	dc.l	$0045004A	
	dc.l	SpriteGfxData_6974A
	dc.l	$0045004B	
	dc.l	TerrainTilemapMetadata_Gfx_6E1E0
	dc.l	$0039005E	
DmaCmd_BattleGroundGfx:
	dc.l	$94069350	
	dc.l	$96D09500	
	dc.l	$977F4980	
	dc.l	$00820000	
DmaCmd_BattleEnemyGfx:
	dc.l	$94059370	
	dc.l	$96D09500	
	dc.l	$977F4400	
	dc.l	$00810000	
DmaCmd_BattleStatusGfx:
	dc.l	$94059390	
	dc.l	$96D09500	
	dc.l	$977F4E00	
	dc.l	$00830000	
DmaCmd_BattlePlayerGfx:
	dc.l	$94059300	
	dc.l	$96D09500	
	dc.l	$977F6E00	
	dc.l	$00830000	
DmaCmd_CaveEnemyGfx:
	dc.l	$94059370	
	dc.l	$96D09500	
	dc.l	$977F4980	
	dc.l	$00820000	
DmaCmd_CaveItemGfx:
	dc.l	$940593E0	
	dc.l	$96D09500	
	dc.l	$977F4E00	
	dc.l	$00830000	
DmaCmd_WorldMapTiles:
	dc.l	$940E93B0	
	dc.l	$96D09500	
	dc.l	$977F5480	
	dc.l	$00810000	
DmaCmd_BattleUiTiles:
	dc.l	$940393D0	
	dc.l	$96D09500	
	dc.l	$977F71E0	
	dc.l	$00810000	
DmaCmd_CaveTiles:
	dc.l	$94079360	
	dc.l	$96D09500	
	dc.l	$977F6E00	
	dc.l	$00830000	
TalkerGfxDesc_MapGiver:
	talkerGfxDesc TalkerGfxDesc_MapGiver_Gfx_51E44,TalkerGfxDesc_MapGiver_Gfx_51534,$0011
TalkerGfxDesc_StowGirl:
	talkerGfxDesc TalkerGfxDesc_StowGirl_Gfx_51E4C,TalkerGfxDesc_StowGirl_Gfx_51544,$0012
TalkerGfxDesc_Bearwulf:
	talkerGfxDesc TalkerGfxDesc_Bearwulf_Gfx_51E54,TalkerGfxDesc_Bearwulf_Gfx_51554,$0011
TalkerGfxDesc_Merchant:
	talkerGfxDesc TalkerGfxDesc_Merchant_Gfx_51E5C,TalkerGfxDesc_Merchant_Gfx_51564,$0011
TalkerGfxDesc_GenericNpc:
	talkerGfxDescPortrait TalkerGfxDesc_GenericNpc_Gfx_51EA4,TalkerGfxDesc_GenericNpc_Gfx_51E94,$0079
TalkerGfxDesc_DigotGiver:
	talkerGfxDescPortrait TalkerGfxDesc_DigotGiver_Gfx_51E8C,TalkerGfxDesc_DigotGiver_Gfx_51E84,$0078
TalkerGfxDesc_TruffleGiver:
	talkerGfxDescPortrait TalkerGfxDesc_TruffleGiver_Gfx_51E7C,TalkerGfxDesc_TruffleGiver_Gfx_51E74,$0078
TalkerGfxDesc_ImposterGuard:
	talkerGfxDesc TalkerGfxDesc_ImposterGuard_Gfx_51E64,TalkerGfxDesc_ImposterGuard_Gfx_51574,$00C3
TalkerGfxDesc_Tsarkon:
	dc.l	TalkerGfxDesc_Tsarkon_Gfx_51E6C
	dc.l	TalkerPortraitTileDataPtrs
	dc.w	$0007
	dc.l	TalkerGfxDesc_Tsarkon_Gfx_51584
	dc.l	TalkerSpriteFrameTable
	dc.l	$000F0000	
	dc.l	$FFF00D0F	
	dc.l	$00AE0042	
GfxLoadList_OverworldBattle:
	dc.l	GfxLoadList_OverworldBattle_Gfx_5DD16
	dc.l	GfxLoadList_OverworldBattle_Gfx_5DD9E
	dc.l	$000B0010	
GfxLoadList_FirstPerson:
	dc.l	GfxLoadList_FirstPerson_Gfx_81782
	dc.l	SpriteFramePointerTable_81E28
	dc.l	$00470011	
	dc.l	GfxLoadList_FirstPerson_Gfx_817CA
	dc.l	SpriteFramePointerTable_81E28
	dc.l	$002F0012	
	dc.l	GfxLoadList_FirstPerson_Gfx_81F24
	dc.l	GfxLoadList_FirstPerson_Gfx_82004
	dc.l	$000B0013	
	dc.l	SpriteMetaTileTable_83108
	dc.l	FPDungeonSpriteFrameTable
	dc.l	$00470014	
	dc.l	SpriteMetaTileTable_83150
	dc.l	FPDungeonSpriteFrameTable
	dc.l	$002F0015	
	dc.l	SpriteLayout_83F24
	dc.l	FPEnemySpriteFrameTable_15
	dc.l	$000B0016	
	dc.l	GfxLoadList_FirstPerson_Gfx_84DD0
	dc.l	SpriteFramePointerTable_855C0
	dc.l	$00470017	
	dc.l	GfxLoadList_FirstPerson_Gfx_84E18
	dc.l	SpriteFramePointerTable_855C0
	dc.l	$002F0018	
	dc.l	GfxLoadList_FirstPerson_Gfx_856F8
	dc.l	GfxLoadList_FirstPerson_Gfx_857EC
	dc.l	$000B0019	
	dc.l	GfxLoadList_FirstPerson_Gfx_86496
	dc.l	SpriteFramePointerTable_86CB8
	dc.l	$0047001A	
	dc.l	GfxLoadList_FirstPerson_Gfx_864DE
	dc.l	SpriteFramePointerTable_86CB8
	dc.l	$002F001B	
	dc.l	GfxLoadList_FirstPerson_Gfx_86DEC
	dc.l	GfxLoadList_FirstPerson_Gfx_86F12
	dc.b	$00, $0B, $FF, $FF 
GfxLoadList_FirstPersonBattle:
	dc.b	$00, $1C 
	dc.l	SpriteMetaTileTable_83108
	dc.l	FPDungeonSpriteFrameTable
	dc.l	$0047001D	
	dc.l	SpriteMetaTileTable_83150
	dc.l	FPDungeonSpriteFrameTable
	dc.l	$002F001E	
	dc.l	SpriteLayout_83F24
	dc.l	FPEnemySpriteFrameTable_15
	dc.l	$000B001F	
	dc.l	GfxLoadList_FirstPersonBattle_Gfx_83180
	dc.l	FPDungeonSpriteFrameTable
	dc.l	$00470020	
	dc.l	GfxLoadList_FirstPersonBattle_Gfx_831C8
	dc.l	FPDungeonSpriteFrameTable
	dc.l	$002F0021	
	dc.l	GfxLoadList_FirstPersonBattle_Gfx_83F30
	dc.l	FPEnemySpriteFrameTable_15
	dc.l	$000B0022	
	dc.l	GfxLoadList_FirstPersonBattle_Gfx_87E18
	dc.l	SpriteFramePointerTable_880F8
	dc.l	$00470023	
	dc.l	GfxLoadList_FirstPersonBattle_Gfx_87E60
	dc.l	SpriteFramePointerTable_880F8
	dc.l	$002F0024	
	dc.l	GfxLoadList_FirstPersonBattle_Gfx_88188
	dc.l	GfxLoadList_FirstPersonBattle_Gfx_88202
	dc.l	$000B0025	
	dc.l	GfxLoadList_FirstPersonBattle_Gfx_88226
	dc.l	SpriteFramePointerTable_88528
	dc.l	$00470026	
	dc.l	GfxLoadList_FirstPersonBattle_Gfx_8826E
	dc.l	SpriteFramePointerTable_88528
	dc.l	$002F0027	
	dc.l	GfxLoadList_FirstPersonBattle_Gfx_885B0
	dc.l	GfxLoadList_FirstPersonBattle_Gfx_88622
	dc.b	$00, $0B, $FF, $FF 
GfxLoadList_IntroSegalogo:
	dc.b	$00, $0D 
	dc.l	GfxLoadList_IntroSegalogo_Gfx_628CC
	dc.l	GfxLoadList_IntroSegalogo_Gfx_62900
	dc.b	$00, $03, $FF, $FF 
GfxLoadList_IntroTitle:
	dc.b	$00, $0E 
	dc.l	GfxLoadList_IntroTitle_Gfx_62910
	dc.l	GfxLoadList_IntroTitle_Gfx_62A08
	dc.b	$00, $07, $FF, $FF 
GfxLoadList_Town:
	dc.b	$00, $00 
	dc.l	FPEnemyTileLayout_A
	dc.l	FPEnemyTileLayout_B
	dc.l	$00470001	
	dc.l	FPEnemyTileLayout_C
	dc.l	FPEnemyTileLayout_D
	dc.l	$002F0002	
	dc.l	FPEnemyTileLayout_E
	dc.l	FPEnemyTileLayout_F
	dc.l	$003B0003	
	dc.l	FPEnemyTileLayout_G
	dc.l	FPEnemyTileLayout_H
	dc.l	$003B0004	
	dc.l	FPEnemyTileLayout_I
	dc.l	FPEnemyTileLayout_J
	dc.l	$00470005	
	dc.l	FPEnemyTileLayout_K
	dc.l	FPEnemyTileLayout_L
	dc.l	$002F0006	
	dc.l	FPEnemyTileLayout_M
	dc.l	FPEnemyTileLayout_N
	dc.l	$00530007	
	dc.l	SpriteLayout_4E582
	dc.l	SpriteFramePointerTable_4E890
	dc.l	$002F0008	
	dc.l	GfxLoadList_Town_Gfx_4D2DA
	dc.l	GfxLoadList_Town_Gfx_4D5AA
	dc.l	$003B0009	
	dc.l	GfxLoadList_Town_Gfx_4D62E
	dc.l	GfxLoadList_Town_Gfx_4D92A
	dc.l	$003B000C	
	dc.l	GfxLoadList_Town_Gfx_50C86
	dc.l	SpriteFramePointerTable_51414
	dc.b	$00, $35, $FF, $FF 
GfxLoadList_TownBattle:
	dc.b	$00, $00 
	dc.l	FPEnemyTileLayout_A
	dc.l	FPEnemyTileLayout_B
	dc.l	$00470001	
	dc.l	FPEnemyTileLayout_C
	dc.l	FPEnemyTileLayout_D
	dc.l	$002F0002	
	dc.l	FPEnemyTileLayout_E
	dc.l	FPEnemyTileLayout_F
	dc.l	$003B0003	
	dc.l	FPEnemyTileLayout_G
	dc.l	FPEnemyTileLayout_H
	dc.l	$003B0004	
	dc.l	FPEnemyTileLayout_I
	dc.l	FPEnemyTileLayout_J
	dc.l	$00470005	
	dc.l	FPEnemyTileLayout_K
	dc.l	FPEnemyTileLayout_L
	dc.l	$002F0006	
	dc.l	FPEnemyTileLayout_M
	dc.l	FPEnemyTileLayout_N
	dc.l	$00530007	
	dc.l	SpriteLayout_4E582
	dc.l	SpriteFramePointerTable_4E890
	dc.l	$002F000A	
	dc.l	GfxLoadList_TownBattle_Gfx_4E2DC
	dc.l	GfxLoadList_TownBattle_Gfx_4E526
	dc.l	$0017000B	
	dc.l	GfxLoadList_TownBattle_Gfx_500B6
	dc.l	GfxLoadList_TownBattle_Gfx_5024C
	dc.l	$00170030	
	dc.l	GfxLoadList_TownBattle_Gfx_50294
	dc.l	GfxLoadList_TownBattle_Gfx_50452
	dc.l	$00170031	
	dc.l	GfxLoadList_TownBattle_Gfx_5049A
	dc.l	GfxLoadList_TownBattle_Gfx_50620
	dc.l	$00170032	
	dc.l	GfxLoadList_TownBattle_Gfx_50A6C
	dc.l	GfxLoadList_TownBattle_Gfx_50C3A
	dc.l	$00170033	
	dc.l	GfxLoadList_TownBattle_Gfx_50660
	dc.l	GfxLoadList_TownBattle_Gfx_50818
	dc.l	$00170034	
	dc.l	GfxLoadList_TownBattle_Gfx_50860
	dc.l	GfxLoadList_TownBattle_Gfx_50A20
	dc.b	$00, $17, $FF, $FF 
GfxLoadList_WorldBattle:
	dc.b	$00, $00 
	dc.l	FPEnemyTileLayout_A
	dc.l	FPEnemyTileLayout_B
	dc.l	$00470001	
	dc.l	FPEnemyTileLayout_C
	dc.l	FPEnemyTileLayout_D
	dc.l	$002F0002	
	dc.l	FPEnemyTileLayout_E
	dc.l	FPEnemyTileLayout_F
	dc.l	$003B0003	
	dc.l	FPEnemyTileLayout_G
	dc.l	FPEnemyTileLayout_H
	dc.l	$003B0004	
	dc.l	FPEnemyTileLayout_I
	dc.l	FPEnemyTileLayout_J
	dc.l	$00470005	
	dc.l	FPEnemyTileLayout_K
	dc.l	FPEnemyTileLayout_L
	dc.l	$002F0006	
	dc.l	FPEnemyTileLayout_M
	dc.l	FPEnemyTileLayout_N
	dc.l	$0053002B	
	dc.l	GfxLoadList_WorldBattle_Gfx_4FB28
	dc.l	GfxLoadList_WorldBattle_Gfx_4FFE6
	dc.l	$003B002C	
	dc.l	GfxLoadList_WorldBattle_Gfx_4F2AE
	dc.l	GfxLoadList_WorldBattle_Gfx_4F8A2
	dc.l	$003B002D	
	dc.l	GfxLoadList_WorldBattle_Gfx_4F98E
	dc.l	GfxLoadList_WorldBattle_Gfx_4FAFC
	dc.l	$000B002E	
	dc.l	GfxLoadList_WorldBattle_Gfx_4EDFE
	dc.l	GfxLoadList_WorldBattle_Gfx_4F202
	dc.l	$002F002F	
	dc.l	GfxLoadList_WorldBattle_Gfx_4E924
	dc.l	GfxLoadList_WorldBattle_Gfx_4ED4E
	dc.l	$002F0044	
	dc.l	GfxLoadList_WorldBattle_Gfx_50CBC
	dc.l	SpriteFramePointerTable_51414
	dc.l	$0017FFFF	
MagicGfxDataPtrs:
	dc.l	MagicGfxData_WyclifParma
	dc.l	MagicGfxData_WyclifParma
	dc.l	MagicGfxData_Barrow
	dc.l	MagicGfxData_Tadcaster
	dc.l	MagicGfxData_Helwig
	dc.l	MagicGfxData_DeepdaleStow
	dc.l	MagicGfxData_DeepdaleStow
	dc.l	MagicGfxData_DeepdaleStow
	dc.l	MagicGfxData_Keltwick
	dc.l	MagicGfxData_SwaffhamExcalabria
	dc.l	MagicGfxData_SwaffhamExcalabria
	dc.l	MagicGfxData_HastingsCarthahena
	dc.l	MagicGfxData_HastingsCarthahena
	dc.l	MagicGfxData_HastingsCarthahena
	dc.l	MagicGfxData_HastingsCarthahena	
	dc.l	MagicGfxData_HastingsCarthahena	
MagicGfxData_WyclifParma:
	magicGfxData MagicGfxData_WyclifParma_Gfx_4A8F4,MagicGfxData_WyclifParma_Gfx_4AA82,$001D,$0036
MagicGfxData_DeepdaleStow:
	magicGfxData MagicGfxData_DeepdaleStow_Gfx_48EFE,MagicGfxData_DeepdaleStow_Gfx_498D0,$00B3,$0073
MagicGfxData_Keltwick:
	magicGfxData MagicGfxData_Keltwick_Gfx_49Ad8,MagicGfxData_Keltwick_Gfx_49E3C,$002F,$0073
MagicGfxData_Barrow:
	magicGfxData SpriteLayout_4A77A,SpriteFramePointerTable_4A8B8,$0017,$0076
MagicGfxData_Tadcaster:
	magicGfxData MagicGfxData_Tadcaster_Gfx_4A548,MagicGfxData_Tadcaster_Gfx_4A70E,$001F,$0076
MagicGfxData_Helwig:
	magicGfxData MagicGfxData_Helwig_Gfx_49ECC,MagicGfxData_Helwig_Gfx_4A42C,$0053,$007A
MagicGfxData_SwaffhamExcalabria:
	magicGfxData MagicGfxData_SwaffhamExcalabria_Gfx_4AAD6,MagicGfxData_SwaffhamExcalabria_Gfx_4B1E6,$007F,$0074
MagicGfxData_HastingsCarthahena:
	magicGfxData SpriteLayout_4A77A,SpriteFramePointerTable_4A8B8,$0017,$0036
; ===========================================================================
TownNames:
	dc.l	TownName_Wyclif
	dc.l	TownName_Parma
	dc.l	TownName_Watling
	dc.l	TownName_Deepdale
	dc.l	TownName_Stow
	dc.l	TownName_Keltwick
	dc.l	TownName_Malaga
	dc.l	TownName_Barrow
	dc.l	TownName_Tadcaster
	dc.l	TownName_Helwig
	dc.l	TownName_Swaffham
	dc.l	TownName_Excalabria
	dc.l	TownName_Hastings
	dc.l	TownName_Carthahena
TownName_Wyclif:
	dc.b	"Wyclif", $FF, $00
TownName_Parma:
	dc.b	"Parma", $FF
TownName_Watling:
	dc.b	"Watling", $FF
TownName_Deepdale:
	dc.b	"Deepdale", $FF, $00
TownName_Stow:
	dc.b	"Stow", $FF, $00
TownName_Keltwick:
	dc.b	"Keltwick", $FF, $00
TownName_Malaga:
	dc.b	"Malaga", $FF, $00
TownName_Barrow:
	dc.b	"Barrow", $FF, $00
TownName_Tadcaster:
	dc.b	"Tadcaster", $FF
TownName_Helwig:
	dc.b	"Helwig", $FF, $00
TownName_Swaffham:
	dc.b	"Swaffham", $FF, $00
TownName_Excalabria:
	dc.b	"Excalabria", $FF, $00
TownName_Hastings:
	dc.b	"Hastings", $FF, $00
TownName_Carthahena:
	dc.b	"Cartahena", $FF

TownTilesetLoadJumpTable: ; suspected town loading routines that set tilemap
	BRA.w	SetTileset_Wyclif
	BRA.w	SetTileset_Parma
	BRA.w	SetTileset_Watling
	BRA.w	SetTileset_Deepdale
	BRA.w	SetTileset_Stow1
	BRA.w	SetTileset_Stow2	
	BRA.w	SetTileset_Keltwick
	BRA.w	SetTileset_Malaga
	BRA.w	SetTileset_Barrow
	BRA.w	SetTileset_Tadcaster
	BRA.w	SetTileset_Helwig
	BRA.w	SetTileset_Swaffham
	BRA.w	SetTileset_Excalabria
	BRA.w	SetTileset_Hastings1
	BRA.w	SetTileset_Hastings2	
	BRA.w	SetTileset_Carthahena
SetTileset_Wyclif:
	MOVE.w	#TOWN_TILESET_VILLAGE_A, Town_tileset_index.w
	RTS

SetTileset_Parma:
	MOVE.w	#TOWN_TILESET_VILLAGE_B, Town_tileset_index.w
	RTS

SetTileset_Watling:
	MOVE.w	#TOWN_TILESET_VILLAGE_A, Town_tileset_index.w
	RTS

SetTileset_Deepdale:
	MOVE.w	#TOWN_TILESET_VILLAGE_B, Town_tileset_index.w
	RTS

SetTileset_Stow1:
	MOVE.w	#TOWN_TILESET_VILLAGE_B, Town_tileset_index.w
	RTS

SetTileset_Stow2:
	MOVE.w	#TOWN_TILESET_VILLAGE_B, Town_tileset_index.w	
	RTS

SetTileset_Keltwick:
	MOVE.w	#TOWN_TILESET_VILLAGE_B, Town_tileset_index.w
	RTS

SetTileset_Malaga:
	MOVE.w	#TOWN_TILESET_VILLAGE_B, Town_tileset_index.w
	RTS

SetTileset_Barrow:
	MOVE.w	#TOWN_TILESET_VILLAGE_A, Town_tileset_index.w
	RTS

SetTileset_Tadcaster:
	MOVE.w	#TOWN_TILESET_VILLAGE_B, Town_tileset_index.w
	RTS

SetTileset_Helwig:
	MOVE.w	#TOWN_TILESET_VILLAGE_A, Town_tileset_index.w
	RTS

SetTileset_Swaffham:
	MOVE.w	#TOWN_TILESET_VILLAGE_B, Town_tileset_index.w
	TST.b	Swaffham_ruined.w
	BEQ.b	SetTileset_Swaffham_Loop
	MOVE.w	#TOWN_TILESET_EXCALABRIA, Town_tileset_index.w
SetTileset_Swaffham_Loop:
	RTS

SetTileset_Excalabria:
	MOVE.w	#TOWN_TILESET_EXCALABRIA, Town_tileset_index.w
	RTS

SetTileset_Hastings1:
	MOVE.w	#TOWN_TILESET_VILLAGE_A, Town_tileset_index.w
	RTS

SetTileset_Hastings2:
	MOVE.w	#TOWN_TILESET_VILLAGE_B, Town_tileset_index.w	
	RTS
	
SetTileset_Carthahena:
	MOVE.w	#TOWN_TILESET_VILLAGE_B, Town_tileset_index.w
	RTS

; TownSpawnPositionTable
; Indexed by Current_town (0-$0F), stride 8 bytes (4 words).
; Each entry sets player spawn and initial camera position on town entry.
; Format: spawn_x, spawn_tile_y, camera_tile_x, camera_tile_y
; Loaded into: Town_spawn_x / Player_spawn_tile_y_buffer / Town_camera_initial_x / Town_default_camera_y
TownSpawnPositionTable:
	dc.w	$00D8, $02B8, $0003, $001F	; $00 Wyclif
	dc.w	$01E8, $0268, $0014, $001A	; $01 Parma
	dc.w	$0138, $0218, $0009, $0015	; $02 Watling
	dc.w	$0128, $0268, $0008, $001A	; $03 Deepdale
	dc.w	$0128, $0208, $0008, $0014	; $04 Stow1
	dc.w	$0128, $0208, $0008, $0014	; $05 Stow2
	dc.w	$0118, $01E8, $0008, $0012	; $06 Keltwick
	dc.w	$01E8, $0268, $0014, $001A	; $07 Malaga
	dc.w	$00E8, $0268, $0005, $001A	; $08 Barrow
	dc.w	$0138, $01D8, $0009, $0011	; $09 Tadcaster
	dc.w	$0168, $02B8, $000C, $001F	; $0A Helwig
	dc.w	$0118, $01B8, $0007, $000F	; $0B Swaffham
	dc.w	$0118, $01C8, $0007, $0010	; $0C Excalabria
	dc.w	$01E8, $01F8, $0015, $0013	; $0D Hastings1
	dc.w	$0118, $0198, $0008, $000D	; $0E Hastings2
	dc.w	$0108, $0218, $0007, $0015	; $0F Carthahena
TownNpcDataLookupJumpTable: ; suspected: Town NPCs?
	BRA.w	LoadNpcData_Wyclif
	BRA.w	LoadNpcData_Parma
	BRA.w	LoadNpcData_Watling
	BRA.w	LoadNpcData_Deepdale
	BRA.w	LoadNpcData_Stow1
	BRA.w	LoadNpcData_Stow2	
	BRA.w	LoadNpcData_Keltwick
	BRA.w	LoadNpcData_Malaga
	BRA.w	LoadNpcData_Barrow
	BRA.w	LoadNpcData_Tadcaster
	BRA.w	LoadNpcData_Helwig
	BRA.w	LoadNpcData_Swaffham
	BRA.w	LoadNpcData_Excalabria	
	BRA.w	LoadNpcData_Hastings1
	BRA.w	LoadNpcData_Hastings2	
	BRA.w	LoadNpcData_Carthahena
LoadNpcData_Wyclif:
	LEA	NpcDataTable_Wyclif, A1
	RTS

LoadNpcData_Parma:
	LEA	NpcDataTable_Parma, A1
	RTS

LoadNpcData_Watling:
	LEA	NpcDataTable_Watling, A1
	RTS

LoadNpcData_Deepdale:
	LEA	NpcDataTable_Deepdale, A1
	RTS

LoadNpcData_Stow1:
	LEA	NpcDataTable_Stow1, A1
	RTS

LoadNpcData_Stow2:
	LEA	NpcDataTable_Stow2, A1	
	RTS

LoadNpcData_Keltwick:
	LEA	NpcDataTable_Stow2, A1
	RTS

LoadNpcData_Malaga:
	LEA	NpcDataTable_Malaga, A1
	RTS

LoadNpcData_Barrow:
	LEA	NpcDataTable_Barrow, A1
	RTS

LoadNpcData_Tadcaster:
	LEA	NpcDataTable_Tadcaster, A1
	RTS

LoadNpcData_Helwig:
	LEA	NpcDataTable_Helwig, A1
	RTS

LoadNpcData_Swaffham:
	LEA	NpcDataTable_Swaffham, A1
	RTS

LoadNpcData_Excalabria:
	LEA	NpcDataTable_Excalabria, A1	
	RTS

LoadNpcData_Hastings1:
	LEA	NpcDataTable_Hastings1, A1
	RTS
	
LoadNpcData_Hastings2:
	LEA	NpcDataTable_Hastings1, A1	
	RTS
	
LoadNpcData_Carthahena:
	LEA	NpcDataTable_Carthahena, A1
	RTS
	
; AreaMusicIdByRoom
; Indexed by Current_town_room (.w, lower byte used) via LoadAndPlayAreaMusic.
; Value is the SOUND_* ID to queue for that area's background music.
; Rooms $00-$0F: town interiors (one entry per TOWN_* constant).
;   Room $04 (Stow1) and $0B (Swaffham) are special-cased in code to
;   override this table value based on story flags.
; Rooms $10+: castle / dungeon inner rooms, ordered by TownStateConfig Room IDs.
AreaMusicIdByRoom:
	; Towns ($00-$0F) — SOUND_ERIAS_MUSIC ($8F), SOUND_VILLAGE_A_MUSIC ($8B),
	;   SOUND_STOW_MUSIC_GIRL_LEFT ($87), SOUND_SWAFFHAM_RUINED_MUSIC ($83)
	dc.b	$87	; $00 Wyclif          — SOUND_STOW_MUSIC_GIRL_LEFT
	dc.b	$8F	; $01 Parma            — SOUND_ERIAS_MUSIC
	dc.b	$8B	; $02 Watling          — SOUND_VILLAGE_A_MUSIC
	dc.b	$8F	; $03 Deepdale         — SOUND_ERIAS_MUSIC
	dc.b	$8F	; $04 Stow1            — SOUND_ERIAS_MUSIC (overridden by code)
	dc.b	$8F	; $05 Stow2            — SOUND_ERIAS_MUSIC
	dc.b	$8F	; $06 Keltwick         — SOUND_ERIAS_MUSIC
	dc.b	$8F	; $07 Malaga           — SOUND_ERIAS_MUSIC
	dc.b	$8B	; $08 Barrow           — SOUND_VILLAGE_A_MUSIC
	dc.b	$8F	; $09 Tadcaster        — SOUND_ERIAS_MUSIC
	dc.b	$8B	; $0A Helwig           — SOUND_VILLAGE_A_MUSIC
	dc.b	$8F	; $0B Swaffham         — SOUND_ERIAS_MUSIC (overridden when ruined)
	dc.b	$83	; $0C Excalabria       — SOUND_SWAFFHAM_RUINED_MUSIC
	dc.b	$8B	; $0D Hastings1        — SOUND_VILLAGE_A_MUSIC
	dc.b	$87	; $0E Hastings2        — SOUND_STOW_MUSIC_GIRL_LEFT
	dc.b	$9A	; $0F Carthahena       — SOUND_ENEMY_APPEAR_JINGLE
	; Castle rooms ($10+) — SOUND_CASTLE_MUSIC ($96)
	dc.b	$96	; $10 (castle room)    — SOUND_CASTLE_MUSIC
	dc.b	$96	; $11 (castle room)    — SOUND_CASTLE_MUSIC
	dc.b	$96	; $12 (castle room)    — SOUND_CASTLE_MUSIC
	dc.b	$96	; $13 (castle room)    — SOUND_CASTLE_MUSIC
	dc.b	$96	; $14 (castle room)    — SOUND_CASTLE_MUSIC
	dc.b	$96	; $15 (castle room)    — SOUND_CASTLE_MUSIC
	dc.b	$96	; $16 (castle room)    — SOUND_CASTLE_MUSIC
	dc.b	$96	; $17 (castle room)    — SOUND_CASTLE_MUSIC
	dc.b	$96	; $18 (castle room)    — SOUND_CASTLE_MUSIC
	dc.b	$96	; $19 (castle room)    — SOUND_CASTLE_MUSIC
	dc.b	$96	; $1A (castle room)    — SOUND_CASTLE_MUSIC
	dc.b	$96	; $1B (castle room)    — SOUND_CASTLE_MUSIC
	dc.b	$96	; $1C (castle room)    — SOUND_CASTLE_MUSIC
	dc.b	$96	; $1D (castle room)    — SOUND_CASTLE_MUSIC
	dc.b	$96	; $1E (castle room)    — SOUND_CASTLE_MUSIC
	dc.b	$96	; $1F (castle room)    — SOUND_CASTLE_MUSIC
	; Mixed rooms ($20+) — SOUND_SHOP_VILLAGE_MUSIC ($95), SOUND_CHURCH_MUSIC ($91)
	dc.b	$95	; $20                  — SOUND_SHOP_VILLAGE_MUSIC
	dc.b	$95	; $21                  — SOUND_SHOP_VILLAGE_MUSIC
	dc.b	$95	; $22                  — SOUND_SHOP_VILLAGE_MUSIC
	dc.b	$95	; $23                  — SOUND_SHOP_VILLAGE_MUSIC
	dc.b	$95	; $24                  — SOUND_SHOP_VILLAGE_MUSIC
	dc.b	$91	; $25                  — SOUND_CHURCH_MUSIC
	dc.b	$95	; $26                  — SOUND_SHOP_VILLAGE_MUSIC
	dc.b	$95	; $27                  — SOUND_SHOP_VILLAGE_MUSIC
	dc.b	$87	; $28                  — SOUND_STOW_MUSIC_GIRL_LEFT
	dc.b	$95	; $29                  — SOUND_SHOP_VILLAGE_MUSIC
	dc.b	$95	; $2A                  — SOUND_SHOP_VILLAGE_MUSIC
	dc.b	$91	; $2B                  — SOUND_CHURCH_MUSIC
	; City shop rooms ($2C-$35) — SOUND_SHOP_CITY_MUSIC ($8C)
	dc.b	$91	; $2C                  — SOUND_CHURCH_MUSIC
	dc.b	$91	; $2D                  — SOUND_CHURCH_MUSIC
	dc.b	$8C	; $2E                  — SOUND_SHOP_CITY_MUSIC
	dc.b	$8C	; $2F                  — SOUND_SHOP_CITY_MUSIC
	dc.b	$8C	; $30                  — SOUND_SHOP_CITY_MUSIC
	dc.b	$8C	; $31                  — SOUND_SHOP_CITY_MUSIC
	dc.b	$8C	; $32                  — SOUND_SHOP_CITY_MUSIC
	dc.b	$8C	; $33                  — SOUND_SHOP_CITY_MUSIC
	dc.b	$8C	; $34                  — SOUND_SHOP_CITY_MUSIC
	dc.b	$8C	; $35                  — SOUND_SHOP_CITY_MUSIC
TownNpcSetupJumpTable: ; Town NPC setup scripts
	BRA.w	SetupTownNpcs_Wyclif
	BRA.w	SetupTownNpcs_Parma
	BRA.w	SetupTownNpcs_Watling
	BRA.w	SetupTownNpcs_Deepdale
	BRA.w	SetupTownNpcs_Stow1
	BRA.w	SetupTownNpcs_Stow2	
	BRA.w	SetupTownNpcs_Keltwick
	BRA.w	SetupTownNpcs_Malaga
	BRA.w	SetupTownNpcs_Barrow
	BRA.w	SetupTownNpcs_Tadcaster
	BRA.w	SetupTownNpcs_Helwig
	BRA.w	SetupTownNpcs_Swaffham
	BRA.w	SetupTownNpcs_Excalabria
	BRA.w	SetupTownNpcs_Hastings1
	BRA.w	SetupTownNpcs_Hastings2	
	BRA.w	SetupTownNpcs_Carthahena
SetupTownNpcs_Wyclif:
	MOVE.l	#NpcEntryList_Wyclif, Town_npc_data_ptr.w
	RTS
	
SetupTownNpcs_Parma:
	TST.b	Talked_to_real_king.w
	BNE.b	SetupTownNpcs_Parma_Normal
	TST.b	Player_chose_to_stay_in_parma.w ; Locked in parma?
	BNE.b	SetupTownNpcs_Parma_Locked
	TST.b	Fake_king_killed.w
	BNE.b	SetupTownNpcs_Parma_Normal
	TST.b	Treasure_of_troy_given_to_king.w
	BNE.b	SetupTownNpcs_Parma_Locked
SetupTownNpcs_Parma_Normal:
	MOVE.l	#NpcEntryList_Parma, Town_npc_data_ptr.w
	RTS
	
SetupTownNpcs_Parma_Locked:
	MOVE.l	#NpcEntryList_Parma_Locked, Town_npc_data_ptr.w
	RTS
	
SetupTownNpcs_Watling:
	MOVE.l	#NpcEntryList_Watling, Town_npc_data_ptr.w
	RTS
	
SetupTownNpcs_Deepdale:
	MOVE.l	#NpcEntryList_Deepdale, Town_npc_data_ptr.w
	RTS
	
SetupTownNpcs_Stow1:
	TST.b	Stow_innocence_proven.w
	BNE.b	SetupTownNpcs_Stow1_Simple
	MOVE.l	#NpcEntryList_Stow1_SoldiersPresent, Town_npc_data_ptr.w
	TST.b	Girl_left_for_stow.w
	BEQ.b	SetupTownNpcs_Stow1_Simple
	RTS
	
SetupTownNpcs_Stow1_Simple:
	MOVE.l	#NpcEntryList_Stow1, Town_npc_data_ptr.w
	RTS
	
SetupTownNpcs_Stow2:
	MOVE.l	#NpcEntryList_Stow2AndKeltwick, Town_npc_data_ptr.w	
	RTS
	
	
SetupTownNpcs_Keltwick:
	MOVE.l	#NpcEntryList_Stow2AndKeltwick, Town_npc_data_ptr.w
	RTS
	
SetupTownNpcs_Malaga:
	MOVE.l	#NpcEntryList_Malaga, Town_npc_data_ptr.w
	RTS
	
SetupTownNpcs_Barrow:
	MOVE.l	#NpcEntryList_Barrow, Town_npc_data_ptr.w
	RTS
	
SetupTownNpcs_Tadcaster:
	MOVE.l	#NpcEntryList_Tadcaster, Town_npc_data_ptr.w
	RTS
	
SetupTownNpcs_Helwig:
	MOVE.l	#NpcEntryList_Helwig, Town_npc_data_ptr.w
	RTS
	
SetupTownNpcs_Swaffham:
	MOVE.l	#NpcEntryList_Swaffham, Town_npc_data_ptr.w
	TST.b	Swaffham_ruined.w
	BEQ.b	SetupTownNpcs_Swaffham_Loop
	MOVE.l	#NpcEntryList_Swaffham_Ruined, Town_npc_data_ptr.w
SetupTownNpcs_Swaffham_Loop:
	RTS
	
SetupTownNpcs_Excalabria:
	MOVE.l	#NpcEntryList_Excalabria, Town_npc_data_ptr.w
	RTS
	
SetupTownNpcs_Hastings1:
	MOVE.l	#NpcEntryList_Hastings, Town_npc_data_ptr.w
	RTS
	
SetupTownNpcs_Hastings2:
	MOVE.l	#NpcEntryList_Hastings, Town_npc_data_ptr.w	
	RTS
	
	
SetupTownNpcs_Carthahena:
	MOVE.l	#NpcEntryList_Carthahena, Town_npc_data_ptr.w
	TST.b	Tsarkon_is_dead.w
	BEQ.b	SetupTownNpcs_Carthahena_Loop
	MOVE.l	#NpcEntryList_Carthahena_TsarkonDead, Town_npc_data_ptr.w
SetupTownNpcs_Carthahena_Loop:
	RTS
	
TownStateDataJumpTableStart:
	BRA.w	LoadTownStateData_Default	
TownStateDataJumpTableStart_Parma:
	BRA.w	LoadTownStateData_Parma
TownStateDataJumpTableStart_Default:
	BRA.w	LoadTownStateData_Default	
TownStateDataJumpTableStart_Deepdale:
	BRA.w	LoadTownStateData_Deepdale
TownStateDataJumpTableStart_Stow:
	BRA.w	LoadTownStateData_Stow1
TownStateDataJumpTable:
	BRA.w	LoadTownStateData_Default	
	BRA.w	LoadTownStateData_Default	
	BRA.w	LoadTownStateData_Malaga
	BRA.w	LoadTownStateData_Default	
	BRA.w	LoadTownStateData_Tadcaster
	BRA.w	LoadTownStateData_Default	
	BRA.w	LoadTownStateData_Swaffham
	BRA.w	LoadTownStateData_Default	
	BRA.w	LoadTownStateData_Default	
	BRA.w	LoadTownStateData_Default	
	BRA.w	LoadTownStateData_Carthahena
LoadTownStateData_Default:
	LEA	TownStateConfig_Default, A0	
	RTS
	
LoadTownStateData_Parma:
	LEA	TownStateConfig_Parma, A0
LoadTownStateData_Parma_FakeKingCheck:
	TST.b	Fake_king_killed.w
	BNE.b	LoadTownStateData_Parma_Return
	LEA	TownStateConfig_Default, A0
LoadTownStateData_Parma_Return:
	RTS
	
LoadTownStateData_Deepdale:
	LEA	TownStateConfig_Deepdale, A0
	RTS
	
LoadTownStateData_Stow1:
	TST.b	Stow_innocence_proven.w
LoadTownStateData_Parma_AltPath:
	BNE.b	LoadTownStateData_Stow1_Simple
	LEA	TownStateConfig_Stow1_Arrested, A0
	TST.b	Girl_left_for_stow.w
	BEQ.b	LoadTownStateData_Stow1_Simple
	RTS
	
LoadTownStateData_Stow1_Simple:
	LEA	TownStateConfig_Stow1, A0
; loc_0002007C (was LoadTownStateData_Parma_Return comment - actually Stow1_Simple end)
LoadTownStateData_Stow1_Simple_Return:
	RTS
	
LoadTownStateData_Malaga:
	LEA	TownStateConfig_Malaga_MapReceived, A0
	TST.b	Barrow_map_received.w
	BNE.b	LoadTownStateData_Malaga_Loop
	LEA	TownStateConfig_Malaga, A0
LoadTownStateData_Malaga_Loop:
	RTS
	
LoadTownStateData_Tadcaster:
	LEA	TownStateConfig_Tadcaster, A0
	RTS
	
LoadTownStateData_Swaffham:
	LEA	TownStateConfig_Swaffham, A0
	RTS
	
LoadTownStateData_Carthahena:
	LEA	TownStateConfig_Carthahena, A0
	TST.b	Tsarkon_is_dead.w
	BEQ.b	LoadTownStateData_Carthahena_Loop
	LEA	TownStateConfig_Carthahena_TsarkonDead, A0
LoadTownStateData_Carthahena_Loop:
	RTS
	
OverworldSectorInteractionPtrs:
	dc.l	OverworldInteractions_Sector0
	dc.l	OverworldInteractions_Sector1
	dc.l	OverworldInteractions_Sector2
	dc.l	OverworldInteractions_Sector3
	dc.l	OverworldInteractions_Sector4
	dc.l	OverworldInteractions_Sector5
	dc.l	OverworldInteractions_Sector6
	dc.l	OverworldInteractions_Sector7 
	dc.l	OverworldInteractions_Sector8
	dc.l	OverworldInteractions_Sector9
	dc.l	OverworldInteractions_Sector10
	dc.l	OverworldInteractions_Sector11
	dc.l	OverworldInteractions_Sector12
	dc.l	OverworldInteractions_Sector13
	dc.l	OverworldInteractions_Sector14
	dc.l	OverworldInteractions_Sector15 
OverworldInteractions_Sector0:
	dc.w	$4, $1, $1, $2 
	dc.l	OverworldChest_Money256
	dc.w	$0004, $000B, $0004, $0001 
	dc.l	OverworldChest_Herbs
	dc.w	$0005, $0009, $000A, $0002 
	dc.l	OverworldChest_Herbs2
	dc.w	$0005, $0007, $000E, $0004 
	dc.l	SetupNoOneTalker
	dc.w	$0005, $0002, $000E, $0004 
	dc.l	OverworldChest_Candle3
	dc.w	$0007, $000C, $0001, $0001 
	dc.l	OverworldChest_Money80_Wyclif
	dc.w	$FFFF
OverworldInteractions_Sector1:	
	dc.w	$5, $5, $2, $1 
	dc.l	OverworldNpc_MerchantFromParma
	dc.w	$0004, $000F, $0006, $0008	
	dc.l	OverworldNpc_PreparedForTask
	dc.w	$0002, $0005, $0006, $000A	
	dc.l	OverworldNpc_UseBansheePowder
	dc.w	$FFFF
OverworldInteractions_Sector2:
	dc.w	$4, $8, $B, $1 
	dc.l	OverworldChest_DarkSword
	dc.w	$0005, $0009, $000D, $0002	
	dc.l	OverworldChest_Money768B	
	dc.w	$0005, $000E, $0002, $0008	
	dc.l	OverworldNpc_LongDangerousRoad	
	dc.w	$0006, $000E, $0009, $0008	
	dc.l	OverworldChest_Herbs5
	dc.w	$0000, $000B, $0006, $000A	
	dc.l	OverworldNpc_SpendWealthWisely
	dc.w	$0001, $000D, $0001, $0005	
	dc.l	OverworldNpc_MapGiver_Wyclif
	dc.w	$FFFF
OverworldInteractions_Sector3:
	dc.w	$5, $5, $7, $8
	dc.l	OverworldChest_SapphireShield
	dc.w	$0005, $0002, $000C, $0002
	dc.l	OverworldChest_Money512 
	dc.w	$0007, $000E, $0006, $0008
	dc.l	OverworldChest_Money1280 
	dc.w	$0007, $0004, $000E, $0008
	dc.l	OverworldChest_Money1792B 
	dc.w	$0001, $0006, $000C, $0005 
	dc.l	OverworldNpc_MapGiver_Deepdale
	dc.w	$FFFF
OverworldInteractions_Sector4:
	dc.w	$5, $2, $1, $1
	dc.l	SetupNoOneTalker
	dc.w	$0005, $0008, $0001, $0001
	dc.l	OverworldChest_Money768_Stow
	dc.w	$FFFF
OverworldInteractions_Sector5:
	dc.w	$4, $C, $5, $8	
	dc.l	OverworldChest_GemShield	
	dc.w	$0005, $0005, $0005, $0005
	dc.l	OverworldNpc_HeadedToWatling
	dc.w	$0007, $0002, $0002, $0002	
	dc.l	OverworldNpc_WayToDeepdale
	dc.w	$0007, $000A, $000A, $0008	
	dc.l	OverworldNpc_LongWayToStow
	dc.w	$0002, $0009, $0008, $0008	
	dc.l	OverworldNpc_TsarkonPawnOfEvil
	dc.w	$FFFF
OverworldInteractions_Sector6:	
	dc.w	$3, $E, $2, $8 
	dc.l	OverworldChest_Medicine
	dc.w	$0003, $000B, $0007, $0001	
	dc.l	OverworldNpc_WrongRoad
	dc.w	$0004, $0002, $000C, $0004	
	dc.l	OverworldChest_Lantern2
	dc.w	$0007, $000D, $000E, $0004	
	dc.l	OverworldChest_Herbs6	
	dc.w	$0002, $0008, $0001, $0008
	dc.l	OverworldNpc_MapGiver_Stow
	dc.w	$FFFF
OverworldInteractions_Sector7:
	dc.w	$1, $1, $C, $2
	dc.l	SetupNoOneTalker
	dc.w	$0007, $0007, $0005, $0008
	dc.l	SetupNoOneTalker
	dc.w	$FFFF
OverworldInteractions_Sector8:
	dc.w	$2, $D, $1, $8
	dc.l	OverworldChest_Money9999
	dc.w	$0005, $000C, $0003, $000A	
	dc.l	OverworldNpc_LearnFromMistakes
	dc.w	$0006, $0007, $0003, $0008	
	dc.l	OverworldChest_GnomeStone
	dc.w	$FFFF
OverworldInteractions_Sector9:	
	dc.w	$4, $A, $3, $8
	dc.l	OverworldChest_Money20480
	dc.w	$0005, $0006, $000D, $0008 
	dc.l	OverworldNpc_SawMotherInCarthahena
	dc.w	$FFFF
OverworldInteractions_Sector10:
	dc.w	$0, $6, $5, $4
	dc.l	OverworldChest_Money864
	dc.w	$0000, $0009, $000C, $000A 
	dc.l	OverworldNpc_ProgressingWell
	dc.w	$0002, $0003, $000A, $0001	
	dc.l	OverworldNpc_TharFashionsEvil	
	dc.w	$0006, $000E, $0005, $0008
	dc.l	SetupNoOneTalker	
	dc.w	$0007, $000F, $0004, $0008	
	dc.l	OverworldNpc_GreetingsWarrior	
	dc.w	$FFFF
OverworldInteractions_Sector11:
	dc.w	$2, $B, $1, $8
	dc.l	OverworldChest_BansheePowder
	dc.w	$FFFF	
OverworldInteractions_Sector12:
	dc.w	$1, $B, $2, $8
	dc.l	OverworldChest_Money5888	
	dc.w	$0002, $0001, $000C, $0002	
	dc.l	OverworldNpc_AppearancesDeceive	
	dc.w	$0006, $0006, $0004, $0001	
	dc.l	SetupNoOneTalker	
	dc.w	$0006, $0004, $0006, $0001	
	dc.l	OverworldChest_RubyBrooch
	dc.w	$FFFF
OverworldInteractions_Sector13:
	dc.w	$1, $8, $E, $A 
	dc.l	OverworldNpc_EvilFlourishes
	dc.w	$0006, $0009, $0003, $0008	
	dc.l	SetupNoOneTalker	
	dc.w	$0006, $0009, $000C, $0008	
	dc.l	SetupNoOneTalker	
	dc.w	$FFFF
OverworldInteractions_Sector14:
	dc.w	$4, $B, $7, $9
	dc.l	OverworldNpc_RingsHavePower
	dc.w	$FFFF	
OverworldInteractions_Sector15:
	dc.w	$3, $D, $7, $8	
	dc.l	OverworldChest_CrimsonArmor
	dc.w	$FFFF
OverworldChest_CrimsonArmor:
	TST.b	Crimson_armor_reward_enabled.w
	BEQ.b	OverworldChest_CrimsonArmor_Loop
	MOVE.w	#REWARD_TYPE_EQUIPMENT, Reward_script_type.w
	MOVE.w	#REWARD_VALUE_CRIMSON_ARMOR, Reward_script_value.w
	MOVE.l	#Crimson_armor_chest_opened, Reward_script_flag.w
	MOVEA.l	Reward_script_flag.w, A0
	TST.b	(A0)
	BNE.b	OverworldChest_CrimsonArmor_Loop2
	MOVE.b	#FLAG_TRUE, Reward_script_available.w
OverworldChest_CrimsonArmor_Loop2:
	MOVE.b	#FLAG_TRUE, Reward_script_active.w
	BSR.w	InitTalkerWithGfxDescriptor_1F782
	MOVE.l	#NoOneHereStr, Script_talk_source.w
OverworldChest_CrimsonArmor_Loop:
	RTS
	
OverworldChest_Money256:
	MoneyChest $100, Money_chest_256_opened
	
OverworldChest_Money768_Stow:
	MoneyChest $0300, Money_chest_768_stow_opened
OverworldChest_Money80_Wyclif:
	MoneyChest $50, Wyclif_outskirts_chest_opened
	
OverworldChest_Money768B:
	MoneyChest $300, Money_chest_768_b_opened
	
OverworldChest_Money512:
	MoneyChest $0200, Money_chest_512_opened
OverworldChest_Money1280:
	MoneyChest $0500, Money_chest_1280_opened
OverworldChest_Money1792B:
	MoneyChest $0700, Money_chest_1792_b_opened
OverworldChest_Money20480:
	MoneyChest $5000, Money_chest_20480_opened
OverworldChest_Money5888:
	MoneyChest $1700, Chest_5888_kims_opened
	
OverworldChest_Money864:	
	MoneyChest $0360, Money_chest_864_opened
OverworldChest_Money9999:
	MoneyChest $9999, Chest_9999_kims_opened
	
OverworldChest_Candle3:
	ItemChest ITEM_CANDLE, Candle_chest_3_opened
	
OverworldChest_Lantern2:
	ItemChest ITEM_LANTERN, Lantern_chest_2_opened
	
OverworldChest_Herbs:
	ItemChest ITEM_HERBS, Herbs_chest_opened
	
OverworldChest_Herbs2:
	ItemChest ITEM_HERBS, Herbs_chest_2_opened
	
OverworldChest_DarkSword:
	EquipChest EQUIPMENT_TYPE_SWORD, EQUIPMENT_SWORD_DARK1, Dark_sword_chest_opened, EQUIPMENT_FLAG_CURSED
	
SetupNoOneTalker:
	MOVE.w	#REWARD_TYPE_ITEM, Reward_script_type.w
	MOVE.w	#0, Reward_script_value.w
	MOVE.l	#0, Reward_script_flag.w
	MOVE.b	#FLAG_TRUE, Reward_script_active.w
	BSR.w	InitTalkerWithGfxDescriptor_1F782
	MOVE.l	#NoOneHereStr, Script_talk_source.w
	RTS
	
OverworldNpc_LongDangerousRoad:
	BSR.w	InitTalkerWithGfxDescriptor_1F712	
	MOVE.l	#LongDangerousRoadAheadStr, Script_talk_source.w	
	RTS
	
	
OverworldChest_Medicine:
	ItemChest ITEM_MEDICINE, Medicine_chest_opened
	
OverworldNpc_WrongRoad:
	BSR.w	InitTalkerWithGfxDescriptor_1F712
	MOVE.l	#WrongRoadStr, Script_talk_source.w
	RTS
	
OverworldChest_Herbs5:
	ItemChest ITEM_HERBS, Herbs_chest_5_opened
	
OverworldChest_Herbs6:
	ItemChest ITEM_HERBS, Herbs_chest_6_opened
	
OverworldChest_RubyBrooch:
	ItemChest ITEM_RUBY_BROOCH, Ruby_brooch_chest_opened
	
OverworldChest_SapphireShield:
	EquipChest EQUIPMENT_TYPE_SHIELD, EQUIPMENT_SHIELD_SAPPHIRE, Chest_sapphire_shield_opened
OverworldChest_BansheePowder:	
	ItemChest ITEM_BANSHEE_POWDER, Banshee_powder_chest_opened
OverworldChest_GnomeStone:
	ItemChest ITEM_GNOME_STONE, Chest_gnome_stone_opened
	
OverworldChest_GemShield:
	EquipChest EQUIPMENT_TYPE_SHIELD, EQUIPMENT_SHIELD_GEM, Chest_gem_shield_opened
	
OverworldNpc_MerchantFromParma:
	BSR.w	InitTalkerWithGfxDescriptor_1F74A
	MOVE.l	#MerchantFromParmaStr, Script_talk_source.w
	RTS
	
OverworldNpc_PreparedForTask:
	BSR.w	InitTalkerWithGfxDescriptor_1F74A
	MOVE.l	#PreparedForTaskStr, Script_talk_source.w
	RTS
	
OverworldNpc_HeadedToWatling:
	BSR.w	InitTalkerWithGfxDescriptor_1F74A
	MOVE.l	#HeadedToWatlingStr, Script_talk_source.w
	RTS
	
OverworldNpc_WayToDeepdale:
	BSR.w	InitTalkerWithGfxDescriptor_1F74A
	MOVE.l	#WayToDeepdaleStr, Script_talk_source.w
	RTS
	
OverworldNpc_LongWayToStow:
	BSR.w	InitTalkerWithGfxDescriptor_1F712
	MOVE.l	#LongWayToStowStr, Script_talk_source.w
	RTS
	
OverworldNpc_GreetingsWarrior:
	BSR.w	InitTalkerWithGfxDescriptor_1F712	
	MOVE.l	#GreetingsWarriorStr, Script_talk_source.w	
	RTS
	
OverworldNpc_EvilFlourishes:
	BSR.w	InitTalkerWithGfxDescriptor_1F74A
	MOVE.l	#EvilFlourishesStr, Script_talk_source.w
	RTS
	
OverworldNpc_AppearancesDeceive:
	BSR.w	InitTalkerWithGfxDescriptor_1F712	
	MOVE.l	#AppearancesDeceiveStr, Script_talk_source.w	
	RTS
	
OverworldNpc_RingsHavePower:
	BSR.w	InitTalkerWithGfxDescriptor_1F712
	MOVE.l	#RingsHavePowerStr, Script_talk_source.w
	RTS
OverworldNpc_ProgressingWell:
	BSR.w	InitTalkerWithGfxDescriptor_1F712
	MOVE.l	#ProgressingWellStr, Script_talk_source.w
	RTS
	
OverworldNpc_TharFashionsEvil:
	BSR.w	InitTalkerWithGfxDescriptor_1F712	
	MOVE.l	#TharFashionsEvilStr, Script_talk_source.w	
	RTS
	
OverworldNpc_UseBansheePowder:
	BSR.w	InitTalkerWithGfxDescriptor_1F712
	MOVE.l	#UseBansheePowderStr, Script_talk_source.w
	RTS
	
OverworldNpc_TsarkonPawnOfEvil:
	BSR.w	InitTalkerWithGfxDescriptor_1F712
	MOVE.l	#TsarkonPawnOfEvilStr, Script_talk_source.w
	RTS
	
OverworldNpc_SpendWealthWisely:
	BSR.w	InitTalkerWithGfxDescriptor_1F712
	MOVE.l	#SpendWealthWiselyStr, Script_talk_source.w
	RTS
	
OverworldNpc_LearnFromMistakes:
	BSR.w	InitTalkerWithGfxDescriptor_1F712
	MOVE.l	#LearnFromMistakesStr, Script_talk_source.w
	RTS
	
OverworldNpc_SawMotherInCarthahena:
	BSR.w	InitTalkerWithGfxDescriptor_1F712
	MOVE.l	#SawMotherInCartahenaStr, Script_talk_source.w
	RTS
	
OverworldNpc_MapGiver_Wyclif:
	LEA	Map_trigger_flags.w, A0
	MOVE.w	#MAP_TRIGGER_MAP_GIVER_WYCLIF, Map_trigger_index.w
	MOVE.w	Map_trigger_index.w, D5
	TST.b	(A0,D5.w)
	BNE.b	OverworldNpc_MapGiver_Wyclif_Loop
	BSR.w	InitDialogMode
	MOVE.l	#PortraitInit_MapGiver, obj_tick_fn(A6)
	MOVE.l	#TalkerGfxDesc_MapGiver, Talker_gfx_descriptor_ptr.w
	BSR.w	InitDialogGraphics
	MOVE.l	#LostHereIsAMapStr_Wyclif, Script_talk_source.w
OverworldNpc_MapGiver_Wyclif_Loop:
	RTS
	
OverworldNpc_MapGiver_Deepdale:
	LEA	Map_trigger_flags.w, A0
	MOVE.w	#MAP_TRIGGER_MAP_GIVER_DEEPDALE, Map_trigger_index.w
	MOVE.w	Map_trigger_index.w, D5
	TST.b	(A0,D5.w)
	BNE.b	OverworldNpc_MapGiver_Deepdale_Loop
	BSR.w	InitDialogMode
	MOVE.l	#PortraitInit_MapGiver, obj_tick_fn(A6)
	MOVE.l	#TalkerGfxDesc_MapGiver, Talker_gfx_descriptor_ptr.w
	BSR.w	InitDialogGraphics
	MOVE.l	#LostHereIsAMapStr_Deepdale, Script_talk_source.w
OverworldNpc_MapGiver_Deepdale_Loop:
	RTS
	
OverworldNpc_MapGiver_Stow:
	LEA	Map_trigger_flags.w, A0
	MOVE.w	#MAP_TRIGGER_MAP_GIVER_STOW, Map_trigger_index.w
	MOVE.w	Map_trigger_index.w, D5
	TST.b	(A0,D5.w)
	BNE.b	OverworldNpc_MapGiver_Stow_Loop
	BSR.w	InitDialogMode
	MOVE.l	#PortraitInit_MapGiver, obj_tick_fn(A6)
	MOVE.l	#TalkerGfxDesc_MapGiver, Talker_gfx_descriptor_ptr.w
	BSR.w	InitDialogGraphics
	MOVE.l	#LostHereIsAMapStr_Stow, Script_talk_source.w
OverworldNpc_MapGiver_Stow_Loop:
	RTS
	
CaveRoomInteractionPtrs:
	dc.l	CaveRoomInteractions_00
	dc.l	CaveRoomInteractions_01
	dc.l	CaveRoomInteractions_02
	dc.l	CaveRoomInteractions_03
	dc.l	CaveRoomInteractions_04
	dc.l	CaveRoomInteractions_05
	dc.l	CaveRoomInteractions_06
	dc.l	CaveRoomInteractions_07
	dc.l	CaveRoomInteractions_08
	dc.l	CaveRoomInteractions_09
	dc.l	CaveRoomInteractions_0A
	dc.l	CaveRoomInteractions_0B
	dc.l	CaveRoomInteractions_0C
	dc.l	CaveRoomInteractions_0D
	dc.l	CaveRoomInteractions_0E
	dc.l	CaveRoomInteractions_0F 
	dc.l	CaveRoomInteractions_10
	dc.l	CaveRoomInteractions_11
	dc.l	CaveRoomInteractions_12
	dc.l	CaveRoomInteractions_13
	dc.l	CaveRoomInteractions_14
	dc.l	CaveRoomInteractions_15
	dc.l	CaveRoomInteractions_16
	dc.l	CaveRoomInteractions_17 
	dc.l	CaveRoomInteractions_18
	dc.l	CaveRoomInteractions_19
	dc.l	CaveRoomInteractions_1A
	dc.l	CaveRoomInteractions_1B
	dc.l	CaveRoomInteractions_1C
	dc.l	CaveRoomInteractions_1D
	dc.l	CaveRoomInteractions_1E
	dc.l	CaveRoomInteractions_1F 
	dc.l	CaveRoomInteractions_20
	dc.l	CaveRoomInteractions_21
	dc.l	CaveRoomInteractions_22
	dc.l	CaveRoomInteractions_23
	dc.l	CaveRoomInteractions_24
	dc.l	CaveRoomInteractions_25
	dc.l	CaveRoomInteractions_26
	dc.l	CaveRoomInteractions_27 
	dc.l	CaveRoomInteractions_28
	dc.l	CaveRoomInteractions_29
	dc.l	CaveRoomInteractions_2A
	dc.l	CaveRoomInteractions_2B
CaveRoomInteractions_00:
	dc.w	$2, $4, $4 ; x, y, direction
	dc.l	CaveEvent_RingOfWisdom
	dc.w	$000B, $000B, $0002 
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0002, $000B, $0002 
	dc.l	CaveChest_Money256
	dc.w	$0003, $0009, $0008 
	dc.l	CaveChest_Herbs3
	dc.w	$000A, $0005, $0004 
	dc.l	CaveChest_Candle
	dc.w	$FFFF
CaveRoomInteractions_01:
	dc.w	$3, $D, $4	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0002, $0003, $0004 
	dc.l	CaveChest_Herbs4
	dc.w	$0008, $0000, $0001 
	dc.l	CaveChest_Candle_Parma 
	dc.w	$FFFF 
CaveRoomInteractions_02:
	dc.w	$F, $F, $8 
	dc.l	CaveChest_ScaleArmor
	dc.w	$000F, $0000, $0001 
	dc.l	CaveEvent_TreasureOfTroy
	dc.w	$0002, $000C, $0002 
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0008, $0008, $0002 
	dc.l	CaveChest_Money768
	dc.w	$FFFF
CaveRoomInteractions_03:
	dc.w	$3, $6, $8	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0000, $000E, $0001
	dc.l	CaveChest_Money1536
	dc.w	$000B, $0000, $0002
	dc.l	CaveChest_Candle2	
	dc.w	$FFFF
CaveRoomInteractions_04:
	dc.w	$0, $7, $1	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$000A, $0001, $0008
	dc.l	CaveChest_Herbs_Watling
	dc.w	$000C, $0001, $0002	
	dc.l	CaveEvent_WatlingMonster
	dc.w	$FFFF
CaveRoomInteractions_05:
	dc.w	$0, $1, $4	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$000B, $0004, $0008
	dc.l	CaveChest_LargeShield
	dc.w	$0008, $000F, $0008	
	dc.l	CaveChest_Money1792	
	dc.w	$FFFF
CaveRoomInteractions_06:
	dc.w	$3, $C, $2	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$000E, $000F, $0004 
	dc.l	CaveChest_MagicShield 
	dc.w	$000C, $0004, $0002 
	dc.l	CaveChest_MetalArmor 
	dc.w	$0006, $0004, $0001 
	dc.l	CaveEvent_Truffle
	dc.w	$FFFF
CaveRoomInteractions_07:
	dc.w	$4, $D, $8	
	dc.l	CheckCaveRoomEnemyState	
	dc.w	$0008, $000F, $0002
	dc.l	CaveChest_Money2128
	dc.w	$0007, $0005, $0004	
	dc.l	CaveChest_Lantern	
	dc.w	$FFFF
CaveRoomInteractions_08:
	dc.w	$D, $B, $4	
	dc.l	CheckCaveRoomEnemyState	
	dc.w	$000F, $0000, $0001
	dc.l	CaveChest_SkeletonArmor
	dc.w	$0000, $0000, $0002	
	dc.l	CaveEvent_StowThief
	dc.w	$FFFF
CaveRoomInteractions_09:
	dc.w	$2, $A, $4	
	dc.l	CheckCaveRoomEnemyState	
	dc.w	$0002, $000F, $0008
	dc.l	CaveChest_SkeletonArmor
	dc.w	$0002, $0003, $0004	
	dc.l	CaveChest_RoyalShield	
	dc.w	$FFFF
CaveRoomInteractions_0A:
	dc.w	$B, $B, $B	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0007, $0006, $0001 
	dc.l	CaveEvent_AstiMonster
	dc.w	$FFFF
CaveRoomInteractions_0B:
	dc.w	$4, $D, $4	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0006, $0002, $0001
	dc.l	CaveChest_EmeraldArmor
	dc.w	$000D, $0007, $0005	
	dc.l	CaveEvent_BearwulfMeeting
	dc.w	$FFFF
CaveRoomInteractions_0C:
	dc.w	$B, $3, $2	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0001, $000E, $0004 
	dc.l	CaveEvent_BearwulfWeaponReward
	dc.w	$0005, $000E, $0004
	dc.l	CaveChest_Money4096
	dc.w	$000B, $000B, $0001	
	dc.l	CaveChest_Money4096	
	dc.w	$0009, $0007, $0004
	dc.l	CaveChest_Money4096
	dc.w	$0007, $000E, $0004	
	dc.l	CaveChest_MirageSword
	dc.w	$FFFF
CaveRoomInteractions_0D:
	dc.w	$5, $2, $2	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0003, $0007, $000A 
	dc.l	CaveEvent_MalagaDungeonPrisoner
	dc.w	$000E, $0009, $0001 
	dc.l	CaveEvent_MalagaCrownReward
	dc.w	$FFFF
CaveRoomInteractions_0E:
	dc.w	$9, $A, $8	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0009, $0000, $0002 
	dc.l	CaveChest_PhantomShield 
	dc.w	$FFFF 
CaveRoomInteractions_0F:
	dc.w	$3, $3, $2 
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0008, $0004, $0002 
	dc.l	CaveChest_Money8192
	dc.w	$FFFF
CaveRoomInteractions_10:
	dc.w	$0, $0, $2	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0003, $0004, $0002
	dc.l	SetupNoOneTalker
	dc.w	$0003, $000C, $0004	
	dc.l	CaveChest_Money12288	
	dc.w	$FFFF
CaveRoomInteractions_11:
	dc.w	$1, $E, $2	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0004, $0004, $0002
	dc.l	CaveEvent_TadcasterTreasureChest
	dc.w	$0000, $0001, $0002	
	dc.l	CaveChest_GraphiteSword
	dc.w	$000E, $0006, $0008
	dc.l	CaveChest_Money8192B
	dc.w	$0001, $000C, $0008	
	dc.l	CaveChest_Money12288	
	dc.w	$000E, $0008, $0008
	dc.l	CaveChest_Money8192
	dc.w	$000D, $0003, $0008	
	dc.l	CaveChest_Money8192	
	dc.w	$FFFF
CaveRoomInteractions_12:
	dc.w	$A, $7, $4	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0000, $0000, $0002 
	dc.l	CaveChest_GrizzlyShield 
	dc.w	$FFFF 
CaveRoomInteractions_13:
	dc.w	$0, $0, $1 
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0007, $000F, $000A 
	dc.l	CaveEvent_TadcasterBully
	dc.w	$0000, $000C, $0002 
	dc.l	CaveChest_BarbarianSword
	dc.w	$FFFF
CaveRoomInteractions_14:
	dc.w	$0, $E, $4	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$000A, $000E, $0008 
	dc.l	CaveEvent_HelwigMenRescued
	dc.w	$FFFF
CaveRoomInteractions_15:
	dc.w	$B, $4, $A	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$FFFF
CaveRoomInteractions_16:
	dc.w	$8, $B, $4	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0000, $0007, $0005 
	dc.l	CaveEvent_ExcalabriaRingGuardian1
	dc.w	$FFFF 
CaveRoomInteractions_17:
	dc.w	$3, $C, $4 
	dc.l	CheckCaveRoomEnemyState
	dc.w	$FFFF 
CaveRoomInteractions_18:
	dc.w	$4, $7, $2 
	dc.l	CheckCaveRoomEnemyState
	dc.w	$FFFF 
CaveRoomInteractions_19:
	dc.w	$1, $5, $1 
	dc.l	CheckCaveRoomEnemyState
	dc.w	$FFFF 
CaveRoomInteractions_1A:
	dc.w	$B, $E, $4 
	dc.l	CheckCaveRoomEnemyState
	dc.w	$FFFF 
CaveRoomInteractions_1B:	
	dc.w	$A, $6, $8 
	dc.l	CheckCaveRoomEnemyState
	dc.w	$FFFF 
CaveRoomInteractions_1C:
	dc.w	$FFFF 
CaveRoomInteractions_1D:
	dc.w	$FFFF 
CaveRoomInteractions_1E:
	dc.w	$9, $7, $1 
	dc.l	CheckCaveRoomEnemyState 
	dc.w	$000D, $0008, $0004 
	dc.l	CaveEvent_SwaffhamDigotPlant
	dc.w	$0005, $000E, $0004 
	dc.l	CaveChest_OldNickArmor 
	dc.w	$FFFF 
CaveRoomInteractions_1F:
	dc.w	$3, $7, $1 
	dc.l	CheckCaveRoomEnemyState 
	dc.w	$FFFF 
CaveRoomInteractions_20:
	dc.w	$5, $3, $A 
	dc.l	CaveEvent_SwaffhamSpy
	dc.w	$0002, $0003, $0002 
	dc.l	CaveChest_RingSoldier1
	dc.w	$000A, $000A, $0005 
	dc.l	CaveEvent_TharEncounter
	dc.w	$000C, $0009, $0008 
	dc.l	CaveChest_RingSoldier2
	dc.w	$0003, $000F, $000A 
	dc.l	CaveEvent_LutherEncounter
	dc.w	$0000, $000F, $0002 
	dc.l	CaveChest_RingSoldier3
	dc.w	$0004, $000B, $000D 
	dc.l	CaveEvent_TsarkonFinalEncounter
	dc.w	$FFFF 
CaveRoomInteractions_21:
	dc.w	$FFFF 
CaveRoomInteractions_22:
	dc.w	$9, $F, $8 
	dc.l	CaveChest_SecretArmor
	dc.w	$0009, $0000, $0008 
	dc.l	CaveChest_MirrorOfAtlas
	dc.w	$FFFF
CaveRoomInteractions_23:
	dc.w	$9, $5, $1	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$FFFF
CaveRoomInteractions_24:
	dc.w	$A, $B, $A	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0004, $000C, $0005 
	dc.l	CaveEvent_ExcalabriaRingGuardian3
	dc.w	$FFFF 
CaveRoomInteractions_25:
	dc.w	$C, $3, $8 
	dc.l	CheckCaveRoomEnemyState
	dc.w	$FFFF 
CaveRoomInteractions_26:
	dc.w	$F, $C, $8 
	dc.l	CheckCaveRoomEnemyState
	dc.w	$FFFF 
CaveRoomInteractions_27:
	dc.w	$9, $9, $2 
	dc.l	CheckCaveRoomEnemyState
	dc.w	$0001, $0001, $0001 
	dc.l	CaveChest_CriticalSword
	dc.w	$FFFF
CaveRoomInteractions_28:
	dc.w	$8, $0, $2	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$FFFF
CaveRoomInteractions_29:
	dc.w	$0, $D, $1	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$000A, $000B, $0005 
	dc.l	CaveEvent_ExcalabriaRingGuardian2
	dc.w	$FFFF 
CaveRoomInteractions_2A:
	dc.w	$2, $D, $2 
	dc.l	CheckCaveRoomEnemyState 
	dc.w	$000F, $0007, $0001 
	dc.l	CaveChest_DeathSword
	dc.w	$FFFF
CaveRoomInteractions_2B:
	dc.w	$1, $E, $4	
	dc.l	CheckCaveRoomEnemyState
	dc.w	$FFFF 
CaveEvent_RingOfWisdom:
	TST.b	Rings_collected.w
	BNE.b	CaveEvent_RingOfWisdom_Loop
	MOVE.b	#FLAG_TRUE, Talker_present_flag.w
	BSR.w	InitDialogMode
	MOVE.l	#PortraitInit_RingOfWisdom, obj_tick_fn(A6)
	MOVE.l	#TalkerGfxDesc_MapGiver, Talker_gfx_descriptor_ptr.w
	BSR.w	InitDialogGraphics
	MOVE.l	#RingOfWisdomStr, Script_talk_source.w
CaveEvent_RingOfWisdom_Loop:
	RTS
	
CaveChest_MirrorOfAtlas:
	ItemChest ITEM_MIRROR_OF_ATLAS, Chest_mirror_of_atlas_opened
	
CaveChest_Money256:
	MoneyChest $100, Chest_256_kims_opened
	
CaveChest_Money4096:
	MoneyChest $1000, Chest_4096_kims_opened
	
CaveChest_GraphiteSword:
	EquipChest EQUIPMENT_TYPE_SWORD, EQUIPMENT_SWORD_GRAPHITE, Chest_graphite_sword_opened
	
CaveChest_CriticalSword:
	EquipChest EQUIPMENT_TYPE_SWORD, EQUIPMENT_SWORD_CRITICAL, Chest_critical_sword_opened
	
CaveChest_GrizzlyShield:
	EquipChest EQUIPMENT_TYPE_SHIELD, EQUIPMENT_SHIELD_GRIZZLY, Chest_grizzly_shield_opened
CaveChest_BarbarianSword:
	EquipChest EQUIPMENT_TYPE_SWORD, EQUIPMENT_SWORD_BARBARIAN, Chest_barbarian_sword_opened
	
CaveChest_EmeraldArmor:
	EquipChest EQUIPMENT_TYPE_ARMOR, EQUIPMENT_ARMOR_EMERALD, Chest_emerald_armor_opened
CaveChest_SecretArmor:
	EquipChest EQUIPMENT_TYPE_ARMOR, EQUIPMENT_ARMOR_SECRET, Chest_secret_armor_opened
	
CaveChest_OldNickArmor:
	EquipChest EQUIPMENT_TYPE_ARMOR, EQUIPMENT_ARMOR_OLD_NICK, Chest_old_nick_armor_opened, EQUIPMENT_FLAG_CURSED
CaveChest_PhantomShield:	
	EquipChest EQUIPMENT_TYPE_SHIELD, EQUIPMENT_SHIELD_PHANTOM, Chest_phantom_shield_opened
CaveChest_DeathSword:
	EquipChest EQUIPMENT_TYPE_SWORD, EQUIPMENT_SWORD_DEATH, Chest_death_sword_opened, EQUIPMENT_FLAG_CURSED
	
CaveChest_Herbs3:
	ItemChest ITEM_HERBS, Herbs_chest_3_opened
	
CaveChest_Candle:
	ItemChest ITEM_CANDLE, Candle_chest_opened
	
CaveChest_Herbs4:
	ItemChest ITEM_HERBS, Herbs_chest_4_opened
	
CaveChest_ScaleArmor:
	EquipChest EQUIPMENT_TYPE_ARMOR, EQUIPMENT_ARMOR_SCALE, Scale_armor_chest_opened
	
CaveChest_Candle_Parma:
	ItemChest ITEM_CANDLE, Candle_chest_parma_opened
CaveChest_Money768:
	MoneyChest $0300, Money_chest_768_opened
	
CaveChest_Money1536:
	MoneyChest $0600, Money_chest_1536_opened
CaveChest_Candle2:
	ItemChest ITEM_CANDLE, Candle_chest_2_opened
	
CaveChest_Herbs_Watling:	
	ItemChest ITEM_HERBS, Herbs_chest_watling_opened
CaveChest_MagicShield:
	EquipChest EQUIPMENT_TYPE_SHIELD, EQUIPMENT_SHIELD_MAGIC, Magic_shield_chest_opened
CaveChest_Money1792:
	MoneyChest $700, Money_chest_1792_opened
	
CaveChest_MirageSword:
	EquipChest EQUIPMENT_TYPE_SWORD, EQUIPMENT_SWORD_MIRAGE, Chest_mirage_sword_opened
	
CaveChest_LargeShield:
	EquipChest EQUIPMENT_TYPE_SHIELD, EQUIPMENT_SHIELD_LARGE, Large_shield_chest_opened
CaveChest_MetalArmor:	
	EquipChest EQUIPMENT_TYPE_ARMOR, EQUIPMENT_ARMOR_METAL, Metal_armor_chest_opened
CaveChest_Money2128:	
	MoneyChest $0850, Money_chest_2128_opened
CaveChest_Lantern:
	ItemChest ITEM_LANTERN, Lantern_chest_opened
	
CaveChest_RoyalShield:
	EquipChest EQUIPMENT_TYPE_SHIELD, EQUIPMENT_SHIELD_ROYAL, Royal_shield_chest_opened
	
CaveChest_SkeletonArmor:	
	EquipChest EQUIPMENT_TYPE_ARMOR, EQUIPMENT_ARMOR_SKELETON, Skeleton_armor_chest_opened
CaveChest_Money8192:
	MoneyChest $2000, Money_chest_8192_opened
	
CaveChest_Money12288:
	MoneyChest $3000, Money_chest_12288_opened
	
CaveChest_Money8192B:
	MoneyChest $2000, Money_chest_8192_b_opened
CaveEvent_TreasureOfTroy:
	TST.b	Treasure_of_troy_challenge_issued.w
	BEQ.b	CaveEvent_TreasureOfTroy_Loop
	MOVE.w	#REWARD_VALUE_TREASURE_OF_TROY, Reward_script_value.w
	MOVE.l	#Treasure_of_troy_found, Reward_script_flag.w
	BSR.w	SetupItemTreasure
CaveEvent_TreasureOfTroy_Loop:
	RTS
	
; CheckCaveRoomEnemyState
; Check cave room enemy state and setup default "no one here" message
; Checks if current cave room has been cleared, sets script accordingly
CheckCaveRoomEnemyState:
	LEA	Map_trigger_flags.w, A0
	CLR.w	D0
	MOVE.w	Current_cave_room.w, D0
	ADDI.w	#$0090, D0
	TST.b	(A0,D0.w)
	BNE.b	CheckCaveRoomEnemyState_Loop
	MOVE.b	#FLAG_TRUE, Reward_script_available.w
CheckCaveRoomEnemyState_Loop:
	MOVE.w	#REWARD_TYPE_MAP, Reward_script_type.w
	MOVE.w	D0, Reward_script_value.w
	MOVE.b	#FLAG_TRUE, Reward_script_active.w
	BSR.w	InitTalkerWithGfxDescriptor_1F782
	MOVE.l	#NoOneHereStr, Script_talk_source.w
	RTS
	
CaveEvent_Truffle:
	TST.b	Truffle_collected.w
	BNE.b	CaveEvent_Truffle_Loop
	MOVE.b	#FLAG_TRUE, Truffles_available.w
	MOVE.w	#REWARD_TYPE_ITEM, Reward_script_type.w
	MOVE.w	#REWARD_VALUE_TRUFFLE, Reward_script_value.w
	MOVE.l	#Truffle_collected, Reward_script_flag.w
	BSR.w	InitDialogMode
	MOVE.l	#PortraitInit_TruffleGiver, obj_tick_fn(A6)
	MOVE.l	#TalkerGfxDesc_TruffleGiver, Talker_gfx_descriptor_ptr.w
	BSR.w	InitDialogGraphics
	MOVE.l	#NoOneHereStr, Script_talk_source.w
CaveEvent_Truffle_Loop:
	RTS
	
CaveEvent_WatlingMonster:
	MOVE.l	#NoOneHereStr, Script_talk_source.w
	TST.b	Watling_monster_encounter_triggered.w
	BEQ.b	CaveEvent_WatlingThief_Return
	TST.b	Watling_youth_restored.w
	BNE.b	CaveEvent_WatlingThief_Return
	BSR.w	InitMerchantDialog_Variant3
	MOVE.l	#StoleYouthStr, Script_talk_source.w
CaveEvent_WatlingThief_Return:
	RTS
	
CaveEvent_StowThief:
	TST.b	Girl_left_for_stow.w
	BNE.b	CaveEvent_StowThief_Return
	MOVE.b	#FLAG_TRUE, Talker_present_flag.w
	BSR.w	InitDialogMode
	MOVE.l	#PortraitInit_StowGirl, obj_tick_fn(A6)
	MOVE.l	#TalkerGfxDesc_StowGirl, Talker_gfx_descriptor_ptr.w
	BSR.w	InitDialogGraphics
	MOVE.l	#SorryForStealingStr, Script_talk_source.w
	TST.b	Stow_thief_defeated.w
	BNE.b	CaveEvent_StowThief_Return
	MOVE.l	#DidntStealBookStr, Script_talk_source.w
	TST.b	Accused_of_theft.w
	BNE.b	CaveEvent_StowThief_Return
	MOVE.l	#NothingForYouStr, Script_talk_source.w
	TST.b	Sanguios_book_offered.w
	BNE.b	CaveEvent_StowThief_Return
	MOVE.l	#BuyBookSanguiosStr, Script_talk_source.w
CaveEvent_StowThief_Return:
	RTS
	
CaveEvent_AstiMonster:
	TST.b	Girl_left_for_stow.w
	BEQ.b	CaveEvent_CarthahenaGuard_NoOne
	TST.b	Asti_monster_defeated.w
	BNE.b	CaveEvent_CarthahenaGuard_NoOne
	BSR.w	InitMerchantDialog_Variant2
	MOVE.l	#MeetAgainStr2, Script_talk_source.w
	BRA.b	CaveEvent_CarthahenaGuard_NoOne_Loop
CaveEvent_CarthahenaGuard_NoOne:
	MOVE.l	#NoOneHereStr, Script_talk_source.w
CaveEvent_CarthahenaGuard_NoOne_Loop:
	RTS
	
CaveEvent_BearwulfMeeting:
	MOVE.l	#NoOneHereStr, Script_talk_source.w
	TST.b	Bearwulf_cave_entered.w
	BEQ.b	CaveEvent_BearwulfMeeting_Return
	TST.b	Bearwulf_met.w
	BNE.b	CaveEvent_BearwulfMeeting_Return
	MOVE.b	#FLAG_TRUE, Talker_present_flag.w
	BSR.w	InitDialogMode
	MOVE.l	#PortraitInit_Bearwulf, obj_tick_fn(A6)
	MOVE.l	#TalkerGfxDesc_Bearwulf, Talker_gfx_descriptor_ptr.w
	BSR.w	InitDialogGraphics
	MOVE.l	#BearwulfIntroductionStr, Script_talk_source.w
CaveEvent_BearwulfMeeting_Return:
	RTS

CaveEvent_BearwulfWeaponReward:
	MOVE.l	#NoOneHereStr, Script_talk_source.w
	TST.b	Bearwulf_cave_entered.w
	BEQ.b	CaveEvent_BearwulfWeaponReward_Loop
	MOVE.w	#REWARD_VALUE_POISON_SHIELD, Reward_script_value.w
	MOVE.l	#Bearwulf_weapon_reward_given, Reward_script_flag.w
	BSR.w	SetupEquipmentTreasure
CaveEvent_BearwulfWeaponReward_Loop:
	RTS

CaveEvent_MalagaDungeonPrisoner:
	MOVE.l	#NoOneHereStr, Script_talk_source.w
	TST.b	Malaga_dungeon_person_rescued.w
	BEQ.b	CaveEvent_MalagaPrisoner_Done
	TST.b	Malaga_king_crowned.w
	BNE.b	CaveEvent_MalagaPrisoner_Done
	MOVE.b	#FLAG_TRUE, Talker_present_flag.w
	BSR.w	InitDialogMode
	MOVE.l	#PortraitInit_MalagaPrisoner, obj_tick_fn(A6)
	MOVE.l	#TalkerGfxDesc_MapGiver, Talker_gfx_descriptor_ptr.w
	BSR.w	InitDialogGraphics
	MOVE.l	#NeverExpectedSucceedStr, Script_talk_source.w
	TST.b	Crown_received.w
	BNE.b	CaveEvent_MalagaPrisoner_Done
	MOVE.l	#WaitingForPlayerNameStr, Script_talk_source.w
CaveEvent_MalagaPrisoner_Done:
	RTS

CaveEvent_MalagaCrownReward:
	MOVE.l	#NoOneHereStr, Script_talk_source.w
	TST.b	Malaga_dungeon_person_rescued.w
	BEQ.b	CaveEvent_MalagaCrownReward_Loop
	MOVE.w	#REWARD_VALUE_CROWN, Reward_script_value.w
	MOVE.l	#Crown_received, Reward_script_flag.w
	BSR.w	SetupItemTreasure
CaveEvent_MalagaCrownReward_Loop:
	RTS

CaveEvent_TadcasterTreasureChest:
	MoneyChest $8000, Tadcaster_treasure_quest_started
CaveEvent_TadcasterBully:
	MOVE.l	#NoOneHereStr, Script_talk_source.w
	TST.b	Bully_first_fight_won.w
	BEQ.b	CaveEvent_ImposterGuardScene_Return
	TST.b	Imposter_killed.w
	BNE.b	CaveEvent_ImposterGuardScene_Return
	MOVE.b	#FLAG_TRUE, Talker_present_flag.w
	BSR.w	InitDialogMode
	MOVE.l	#PortraitInit_ImposterGuard, obj_tick_fn(A6)
	MOVE.l	#TalkerGfxDesc_ImposterGuard, Talker_gfx_descriptor_ptr.w
	BSR.w	InitDialogGraphics
	MOVE.l	#AwaitingYouStr, Script_talk_source.w
CaveEvent_ImposterGuardScene_Return:
	RTS

CaveEvent_HelwigMenRescued:
	MOVE.l	#NoOneHereStr, Script_talk_source.w
	TST.b	Helwig_prison_entered.w
	BEQ.b	CaveEvent_HelwigPrisonerFreed_Return
	TST.b	Helwig_men_rescued.w
	BNE.b	CaveEvent_HelwigPrisonerFreed_Return
	BSR.w	InitMerchantDialog_Variant3
	MOVE.l	#FreeAtLastStr, Script_talk_source.w
CaveEvent_HelwigPrisonerFreed_Return:
	RTS

CaveEvent_SwaffhamDigotPlant:
	TST.b	Swaffham_ate_poisoned_food.w
	BEQ.b	CaveEvent_DigotPlant_Return
	TST.b	Digot_plant_received.w
	BNE.b	CaveEvent_DigotPlant_Return
	MOVE.b	#FLAG_TRUE, Herbs_available.w
	MOVE.w	#REWARD_TYPE_ITEM, Reward_script_type.w
	MOVE.w	#REWARD_VALUE_DIGOT_PLANT, Reward_script_value.w
	MOVE.l	#Digot_plant_received, Reward_script_flag.w
	BSR.w	InitDialogMode
	MOVE.l	#PortraitInit_DigotGiver, obj_tick_fn(A6)
	MOVE.l	#TalkerGfxDesc_DigotGiver, Talker_gfx_descriptor_ptr.w
	BSR.w	InitDialogGraphics
	MOVE.l	#NoOneHereStr, Script_talk_source.w
CaveEvent_DigotPlant_Return:
	RTS
	
CaveEvent_ExcalabriaRingGuardian1:
	TST.b	Excalabria_boss_1_defeated.w
	BNE.w	CaveEvent_RingOfWindReward
	MOVE.b	#FLAG_TRUE, Boss_event_trigger.w
	MOVE.b	#FLAG_TRUE, Ring_guardian_1_boss_trigger.w
	RTS
	
CaveEvent_RingOfWindReward:
	MOVE.w	#REWARD_VALUE_WHITE_CRYSTAL, Reward_script_value.w
	MOVE.l	#Ring_of_wind_received, Reward_script_flag.w
	BSR.w	SetupItemTreasure
	RTS
	
CaveEvent_ExcalabriaRingGuardian2:
	TST.b	Excalabria_boss_2_defeated.w
	BNE.w	CaveEvent_RedCrystalReward
	MOVE.b	#FLAG_TRUE, Boss_event_trigger.w
	MOVE.b	#FLAG_TRUE, Ring_guardian_2_boss_trigger.w
	RTS
	
CaveEvent_RedCrystalReward:
	MOVE.w	#REWARD_VALUE_RED_CRYSTAL, Reward_script_value.w
	MOVE.l	#Red_crystal_received, Reward_script_flag.w
	BSR.w	SetupItemTreasure
	RTS
	
CaveEvent_ExcalabriaRingGuardian3:
	TST.b	Excalabria_boss_3_defeated.w
	BNE.w	CaveEvent_BlueCrystalReward
	MOVE.b	#FLAG_TRUE, Boss_event_trigger.w
	MOVE.b	#FLAG_TRUE, Ring_guardian_3_boss_trigger.w
	RTS
	
CaveEvent_BlueCrystalReward:
	MOVE.w	#REWARD_VALUE_BLUE_CRYSTAL, Reward_script_value.w
	MOVE.l	#Blue_crystal_received, Reward_script_flag.w
	BSR.w	SetupItemTreasure
	RTS
	
CaveEvent_SwaffhamSpy:
	TST.b	Swaffham_spy_defeated.w
	BNE.w	CaveEvent_SwaffhamSpyKeyReward
	BSR.w	InitMerchantDialog_Variant2
	MOVE.l	#DieLaughStr, Script_talk_source.w
	TST.b	Ate_spy_dinner.w
	BEQ.w	CaveEvent_SwaffhamSpy_Loop
	MOVE.l	#WishPoisonKilledStr, Script_talk_source.w
CaveEvent_SwaffhamSpy_Loop:
	RTS
	
CaveEvent_SwaffhamSpyKeyReward:
	MOVE.w	#REWARD_VALUE_BRONZE_KEY, Reward_script_value.w
	MOVE.l	#Thar_bronze_key_collected, Reward_script_flag.w
	BSR.w	SetupItemTreasure
	RTS
	
CaveChest_RingSoldier1:
	RingChest 4, 5, Carthahena_soldier_1_defeated
	
CaveEvent_TharEncounter:
	TST.b	Thar_defeated.w
	BNE.w	CaveEvent_TharKeyReward
	BSR.w	InitTalkerWithGfxDescriptor_1F712
	MOVE.l	#TharRevengeStr, Script_talk_source.w
	RTS
	
CaveEvent_TharKeyReward:
	MOVE.w	#REWARD_VALUE_SILVER_KEY, Reward_script_value.w
	MOVE.l	#Thar_silver_key_collected, Reward_script_flag.w
	BSR.w	SetupItemTreasure
	RTS
	
CaveChest_RingSoldier2:
	RingChest 4, 6, Carthahena_soldier_2_defeated
	
CaveEvent_LutherEncounter:
	TST.b	Luther_defeated.w
	BNE.w	CaveEvent_LutherKeyReward
	BSR.w	InitTalkerWithGfxDescriptor_1F712
	MOVE.l	#LutherDevastatedSwaffhamStr, Script_talk_source.w
	RTS
	
CaveEvent_LutherKeyReward:
	MOVE.w	#REWARD_VALUE_GOLD_KEY, Reward_script_value.w
	MOVE.l	#Luther_gold_key_collected, Reward_script_flag.w
	BSR.w	SetupItemTreasure
	RTS
	
CaveChest_RingSoldier3:
	RingChest 4, 7, Carthahena_soldier_3_defeated
	
CaveEvent_TsarkonFinalEncounter:
	TST.b	Tsarkon_is_dead.w
	BNE.w	CaveEvent_TsarkonFinalEncounter_Loop
	MOVE.w	#7, D7
	JSR	CheckRingsCollected
	BNE.w	CaveEvent_TsarkonFinalEncounter_Loop2
	MOVE.b	#FLAG_TRUE, Talker_present_flag.w
	BSR.w	InitDialogMode
	MOVE.l	#PortraitInit_TsarkonFinal, obj_tick_fn(A6)
	MOVE.l	#TalkerGfxDesc_Tsarkon, Talker_gfx_descriptor_ptr.w
	BSR.w	InitDialogGraphics
	MOVE.l	#FreedAtLastStr, Script_talk_source.w
	TST.b	All_rings_collected.w
	BNE.b	CaveEvent_Tsarkon_Return
	MOVE.l	#BreakMothersHeartStr, Script_talk_source.w
	TST.b	Stepfather_ring_dialog_shown.w
	BNE.b	CaveEvent_Tsarkon_Return
	MOVE.l	#StepfatherRingsStr, Script_talk_source.w
	BRA.b	CaveEvent_Tsarkon_Return
CaveEvent_TsarkonFinalEncounter_Loop2:
	MOVE.l	#FeelChillsStr, Script_talk_source.w	
	BRA.b	CaveEvent_Tsarkon_Return	
CaveEvent_TsarkonFinalEncounter_Loop:
	MOVE.l	#EvilDiedWithTsarkonStr, Script_talk_source.w	
CaveEvent_Tsarkon_Return:
	RTS
	
InitDialogMode:
	MOVEA.l	Current_actor_ptr.w, A6
	BSET.b	#7, (A6)
	MOVE.b	#FLAG_TRUE, Dialog_active_flag.w
	MOVE.b	#FLAG_TRUE, Dialog_state_flag.w
	CLR.w	Dialog_timer.w
	CLR.w	Dialog_phase.w
	MOVE.w	Gameplay_state.w, Saved_game_state.w
	MOVE.w	Player_direction.w, Saved_player_direction.w
	MOVE.w	#GAMEPLAY_STATE_DIALOG_DISPLAY, Gameplay_state.w
	RTS
	
InitDialogGraphics:
	JSR	LoadTalkerGraphics
	DMAFillVRAM $45600002, $03FF
	RTS
; ============================================================================
; Treasure Chest Initialization Functions
; ============================================================================
; Set up treasure chests with different content types.
;
; Treasure Types ($FFFFC570):
;   0 = Item, 1 = Equipment, 3 = Money (Kims), 4 = Ring, 5 = Map
;
; Chest State Variables:
;   $FFFFC56C = Chest present flag ($FF = exists)
;   $FFFFC56F = Chest contains treasure ($FF = has item)
;   $FFFFC570 = Treasure type
;   $FFFFC572 = Treasure value/ID (set before calling)
;   $FFFFC574 = Pointer to flag byte (set before calling, $FF if opened)
; ============================================================================
	
; Initialize item chest (type 0)
SetupItemTreasure:
	MOVE.w	#REWARD_TYPE_ITEM, Reward_script_type.w          ; Type 0 = Item
	BRA.w	SetupChestReward
	
; Initialize equipment chest (type 1)
SetupEquipmentTreasure:
	MOVE.w	#REWARD_TYPE_EQUIPMENT, Reward_script_type.w          ; Type 1 = Equipment
	BRA.w	SetupChestReward
	
; Initialize money chest (type 3)
InitMoneyTreasure:
	MOVE.w	#REWARD_TYPE_MONEY, Reward_script_type.w          ; Type 3 = Money
	
	; Common chest initialization
SetupChestReward:
	MOVEA.l	Reward_script_flag.w, A0          ; A0 = flag byte pointer
	TST.b	(A0)                     ; Already opened?
	BNE.b	SetupChestReward_Loop             ; Yes: skip treasure flag
	MOVE.b	#FLAG_TRUE, Reward_script_available.w        ; Mark chest contains treasure
	
SetupChestReward_Loop:
	MOVE.b	#FLAG_TRUE, Reward_script_active.w        ; Mark chest present
	BSR.w	InitTalkerWithGfxDescriptor_1F782             ; Spawn chest sprite
	MOVE.l	#NoOneHereStr, Script_talk_source.w
	RTS
	
SetupFoundItemReward:
	MOVE.w	Enemy_reward_type.w, Reward_script_type.w
	MOVE.w	Enemy_reward_value.w, Reward_script_value.w
	MOVE.b	#FLAG_TRUE, Reward_script_available.w
	MOVE.b	#FLAG_TRUE, Reward_script_active.w
	BSR.w	InitTalkerWithGfxDescriptor_1F782
	MOVE.l	#NoOneHereStr, Script_talk_source.w
	RTS
	
InitTalkerWithGfxDescriptor_1F782:
	BSR.w	InitDialogMode
	MOVE.l	#PortraitInit_Simple, obj_tick_fn(A6)
	MOVE.l	#TalkerGfxDesc_GenericNpc, Talker_gfx_descriptor_ptr.w
	BRA.w	InitDialogGraphics
InitTalkerWithGfxDescriptor_1F712:
	MOVE.b	#FLAG_TRUE, Talker_present_flag.w
	BSR.w	InitDialogMode
	MOVE.l	#PortraitInit_Simple, obj_tick_fn(A6)
	MOVE.l	#TalkerGfxDesc_MapGiver, Talker_gfx_descriptor_ptr.w
	BRA.w	InitDialogGraphics
InitTalkerWithGfxDescriptor_1F74A:
	MOVE.b	#FLAG_TRUE, Talker_present_flag.w
	BSR.w	InitDialogMode
	MOVE.l	#PortraitInit_Simple, obj_tick_fn(A6)
	MOVE.l	#TalkerGfxDesc_Bearwulf, Talker_gfx_descriptor_ptr.w
	BRA.w	InitDialogGraphics
InitMerchantDialog_Variant2:
	MOVE.b	#FLAG_TRUE, Talker_present_flag.w
	BSR.w	InitDialogMode
	MOVE.l	#PortraitInit_Simple, obj_tick_fn(A6)
	MOVE.l	#TalkerGfxDesc_StowGirl, Talker_gfx_descriptor_ptr.w
	BRA.w	InitDialogGraphics
InitMerchantDialog_Variant3:
	MOVE.b	#FLAG_TRUE, Talker_present_flag.w
	BSR.w	InitDialogMode
	MOVE.l	#PortraitInit_Simple, obj_tick_fn(A6)
	MOVE.l	#TalkerGfxDesc_Merchant, Talker_gfx_descriptor_ptr.w
	BRA.w	InitDialogGraphics

