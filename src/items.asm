; ======================================================================
; src/items.asm
; Item use, shop, sell dialog, chest animations
; ======================================================================
UseVase:
	PRINT 	SlippedHandStr	
	BSR.w	RemoveSelectedItemFromList	
	RTS
	

;loc_0001AEAE:
UseJokeBook:
	PRINT 	KnockJokesStr	
	BSR.w	RemoveSelectedItemFromList	
	RTS
	

;loc_0001AEBC:
UseSmallBomb:
	PRINT 	LoudRoarStr
	BSR.w	RemoveSelectedItemFromList
	MOVE.w	#SOUND_BOMB, D0
	JSR	QueueSoundEffect
	RTS

;loc_0001AED4:
UseOldWomansSketch:
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_KELTWICK, D0
	BNE.w	UseSketch_OldManWrongDir
	MOVE.w	Gameplay_state.w, D0
	CMPI.w	#GAMEPLAY_STATE_TOWN_EXPLORATION, D0
	BNE.w	UseSketch_OldManWrongDir
	CLR.w	D0
	CLR.w	D1
	LEA	OldManSketchPositionData, A0
	MOVE.w	#3, D7
UseOldWomansSketch_Done:
	MOVE.w	(A0), D0
	CMP.w	Player_position_x_in_town.w, D0
	BNE.b	UseSketch_OldManNextEntry
	MOVE.w	$2(A0), D0
	CMP.w	Player_position_y_in_town.w, D0
	BNE.b	UseSketch_OldManNextEntry
	MOVE.w	$4(A0), D0
	CMP.w	Player_direction.w, D0
	BEQ.b	UseSketch_OldManWrongDir_Loop
UseSketch_OldManNextEntry:
	LEA	$6(A0), A0	
	DBF	D7, UseOldWomansSketch_Done	
UseSketch_OldManWrongDir:
	PRINT 	YoungerBeautifulStr	
	RTS
	
UseSketch_OldManWrongDir_Loop:
	MOVE.b	#FLAG_TRUE, Old_man_has_received_sketch.w
	PRINT 	OldManTookStr
	BSR.w	RemoveSelectedItemFromList
	RTS
OldManSketchPositionData:
	dc.w	OLD_MAN_POSITION_X
	dc.w	OLD_MAN_POSITION_Y+1
	dc.w	DIRECTION_UP

	dc.w	OLD_MAN_POSITION_X-1
	dc.w	OLD_MAN_POSITION_Y
	dc.w	DIRECTION_RIGHT
	
	dc.w	OLD_MAN_POSITION_X+1
	dc.w	OLD_MAN_POSITION_Y
	dc.w	DIRECTION_LEFT
	
	dc.w	OLD_MAN_POSITION_X 
	dc.w	OLD_MAN_POSITION_Y-1
	dc.w	DIRECTION_DOWN

;loc_0001AF54:
UseOldMansSketch
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_HELWIG, D0
	BNE.w	UseSketch_OldWomanWrongDir
	MOVE.w	Gameplay_state.w, D0
	TST.b	Player_in_first_person_mode.w
	BNE.w	UseSketch_OldWomanWrongDir
	CLR.w	D0
	CLR.w	D1
	MOVEA.l	Player_entity_ptr.w, A6
	LEA	OldWomanSketchPositionData, A0
	MOVE.w	#3, D7
OldManSketchPositionData_Done:
	MOVE.w	(A0), D0
	CMP.w	Player_position_x_in_town.w, D0
	BNE.b	UseSketch_OldWomanNextEntry
	MOVE.w	$2(A0), D0
	CMP.w	Player_position_y_in_town.w, D0
	BNE.b	UseSketch_OldWomanNextEntry
	MOVE.w	$4(A0), D0
	CMP.w	Player_direction.w, D0
	BEQ.b	UseSketch_OldWomanWrongDir_Loop
UseSketch_OldWomanNextEntry:
	LEA	$6(A0), A0
	DBF	D7, OldManSketchPositionData_Done
UseSketch_OldWomanWrongDir:
	PRINT 	MeanLookStr	
	RTS
	
UseSketch_OldWomanWrongDir_Loop:
	MOVE.b	#FLAG_TRUE, Old_woman_has_received_sketch.w
	PRINT 	OldWomanTookStr
	BSR.w	RemoveSelectedItemFromList
	RTS

OldWomanSketchPositionData:
	dc.w	OLD_WOMAN_POSITION_X
	dc.w	OLD_WOMAN_POSITION_Y+1
	dc.w	DIRECTION_UP

	dc.w	OLD_WOMAN_POSITION_X-1
	dc.w	OLD_WOMAN_POSITION_Y
	dc.w	DIRECTION_RIGHT
	
	dc.w	OLD_WOMAN_POSITION_X+1
	dc.w	OLD_WOMAN_POSITION_Y
	dc.w	DIRECTION_LEFT
	
	dc.w	OLD_WOMAN_POSITION_X 
	dc.w	OLD_WOMAN_POSITION_Y-1
	dc.w	DIRECTION_DOWN

;loc_0001AFD8:
UseTreasureOfTroy:
	PRINT 	IncredibleTreasureStr	
	RTS
	
;loc_0001AFE2:
UseTruffle:
	PRINT 	RoastDuckStr	
	RTS
	
;loc_0001AFEC:
UseDigotPlant:
	TST.w	Player_poisoned.w
	BEQ.b	UseDigotPlant_Loop
	CLR.b	Poison_notified.w
	CLR.w	Player_poisoned.w
	CLR.b	Player_greatly_poisoned.w
	PRINT 	PoisonPurgedStr
	BRA.b	UseDigotPlant_Loop2
UseDigotPlant_Loop:
	PRINT 	NotPoisonousStr
UseDigotPlant_Loop2:
	BSR.w	RemoveSelectedItemFromList
	RTS

;loc_0001B016:
UsePassToCarthahena:
	PRINT 	PowerSurgeStr	
	RTS
	
UseCrown:
	PRINT 	PowerSurgeStr	
	RTS
	

UseSixteenRings:
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_CARTHAHENA, D0
	BNE.b	UseSixteenRings_WrongCondition
	MOVE.w	Gameplay_state.w, D0
	CMPI.w	#$A, D0
	BNE.b	UseSixteenRings_WrongCondition
	MOVE.w	#$15, D0
	CMP.w	Player_position_x_in_town.w, D0
	BNE.b	UseSixteenRings_WrongCondition
	MOVE.w	#4, D0
	CMP.w	Player_position_y_in_town.w, D0
	BNE.b	UseSixteenRings_WrongCondition
	PRINT 	RingsLeaveStr
	MOVE.b	#FLAG_TRUE, Sixteen_rings_used_at_throne.w
	MOVE.w	#SOUND_LEVEL_UP, D0
	JSR	QueueSoundEffect
	RTS

UseSixteenRings_WrongCondition:
	PRINT 	RingsFirmamentStr
	RTS

UseWhiteCrystal:
	PRINT 	WhiteBeautifulStr	
	RTS
	
UseRedCrystal:
	PRINT 	DeepRedStr	
	RTS
	
UseBlueCrystal:
	PRINT 	BrightBlue	
	RTS
	
UseGeneric:
	TST.b	Player_in_first_person_mode.w
	BNE.b	UseGeneric_Loop
	JSR	GetTileInFrontOfPlayer	
	CMPI.w	#TOWN_TILE_CHEST, D0	
	BEQ.w	UseKey_NoDoor_Loop	
	BRA.w	UseKey_NoDoor	
UseGeneric_Loop:
	LEA	FpDirectionDeltaForward, A0
	JSR	GetMapTileInDirection
	CMPI.b	#6, D0
	BNE.w	UseKey_NoDoor
	LEA	FpDirectionDeltaForward, A2
	MOVE.w	Player_position_x_outside_town.w, D3
	MOVE.w	Player_position_y_outside_town.w, D4
	MOVE.w	Player_direction.w, D0
	ADD.w	D0, D0
	ADD.w	(A2,D0.w), D3
	ADD.w	$2(A2,D0.w), D4
	LEA	LockedDoorDataTable, A0
UseGeneric_Loop_Done:
	LEA	(A0), A1
	MOVE.w	(A1)+, D0
	BLT.w	CheckLockedDoor_NextEntry_Loop
	CMP.w	Current_cave_room.w, D0
	BNE.w	CheckLockedDoor_NextEntry
	MOVE.w	(A1)+, D0
	CMP.w	D3, D0
	BNE.w	CheckLockedDoor_NextEntry
	MOVE.w	(A1)+, D0
	CMP.w	D4, D0
	BNE.w	CheckLockedDoor_NextEntry
	MOVE.w	(A1)+, D0
	ANDI.w	#$00FF, D0
	LEA	Possessed_items_list.w, A0
	MOVE.w	Selected_item_index.w, D1
	ADD.w	D1, D1
	MOVE.w	(A0,D1.w), D1
	ANDI.w	#$00FF, D1
	CMP.w	D1, D0
	BNE.b	UseKey_NoDoor_Loop2
	MOVE.w	#SOUND_ATTACK, D0
	JSR	QueueSoundEffect
	MOVE.b	#FLAG_TRUE, Door_unlocked_flag.w
	PRINT 	KeyUnlockedStr
	RTS

CheckLockedDoor_NextEntry:
	LEA	$8(A0), A0
	BRA.b	UseGeneric_Loop_Done
CheckLockedDoor_NextEntry_Loop:
	PRINT 	NoKeyholeStr	
	RTS
	
UseKey_NoDoor:
	PRINT 	NoDoorStr	
	RTS
	
UseKey_NoDoor_Loop2:
	PRINT 	KeyDoesntFitStr
	RTS
UseKey_NoDoor_Loop:
	PRINT 	EffortsFutileStr	
	RTS
	
;loc_0001B166:
RemoveSelectedItemFromList:
	MOVE.w	Selected_item_index.w, D0
	MOVE.w	#9, D2
	LEA	Possessed_items_list.w, A0
	SUBQ.w	#1, Possessed_items_length.w
	JSR	RemoveItemFromArray
	RTS

DialogueStateMachine:
	MOVE.w	Dialogue_state.w, D0
	ANDI.w	#$003F, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	DialogueStateHandlerMap, A0
	JSR	(A0,D0.w)
	RTS

;loc_0001B196:
DialogueStateHandlerMap:
	BRA.w	DialogState_Init
	BRA.w	DialogState_WaitScriptThenAdvance
	BRA.w	DialogState_WaitButtonThenCloseMenu
	BRA.w	DialogState_WaitCThenRestartDialogue
	BRA.w	DialogState_DrawYesNoDialog
	BRA.w	DialogState_ProcessYesNoAnswer
	BRA.w	DialogState_WaitScriptThenOpenShopMenu
	BRA.w	DialogState_ShopMenuInput
	BRA.w	DialogState_WaitScriptThenCloseToOverworld
	BRA.w	DialogState_RedrawHudAndClose
	BRA.w	DialogState_WaitScriptThenOpenSellListWindow
	BRA.w	DialogState_WaitDrawThenShowMoneyWindow
	BRA.w	DialogState_ShopSellItemSelectInput
	BRA.w	DialogState_ShopBuyConfirmAndPurchase
	BRA.w	DialogState_WaitScriptThenDrawSellConfirm
	BRA.w	DialogState_SellConfirmYesNoInput
	BRA.w	DialogState_WaitScriptThenGoToBuyMenu
	BRA.w	DialogState_WaitScriptThenOpenInventorySellList
	BRA.w	DialogState_WaitScriptThenReturnToSellList
	BRA.w	DialogState_SellInventoryItemSelectInput
	BRA.w	DialogState_WaitScriptThenDrawSellItemYesNo
	BRA.w	DialogState_SellInventoryConfirmAndSell
	BRA.w	DialogState_DrawSellInventoryYesNo
	BRA.w	DialogState_SellInventoryCancelOrConfirm
	BRA.w	DialogState_WaitScriptWithYesNoOrContinue
	BRA.w	DialogState_DrawFortuneTellerMoneyWindow
	BRA.w	DialogState_FortuneTellerPayAndRead
	BRA.w	DialogState_WaitFortuneTellerScriptThenClose
	BRA.w	DialogState_WaitScriptThenDrawInnYesNo
	BRA.w	DialogState_DrawInnMoneyWindow
	BRA.w	DialogState_InnPayAndSleep
	BRA.w	DialogState_WaitScriptThenStartSleepFade
	BRA.w	DialogState_SleepFadeAndRestore
	BRA.w	DialogState_WaitScriptThenOpenChurchMenu
	BRA.w	DialogState_ChurchMenuInput
	BRA.w	DialogState_WaitScriptThenCloseChurchToHud
	BRA.w	DialogState_WaitTileThenCloseToOverworld
	BRA.w	DialogState_WaitScriptThenDrawCurseYesNo
	BRA.w	DialogState_DrawCurseRemovalMoneyWindow
	BRA.w	DialogState_CurseRemovalPayAndCure
	BRA.w	DialogState_WaitScriptThenDrawPoisonYesNo
	BRA.w	DialogState_DrawPoisonCureMoneyWindow
	BRA.w	DialogState_PoisonCurePayAndCure
	BRA.w	DialogState_WaitScriptThenOpenSaveMenu
	BRA.w	DialogState_SaveMenuInput
	BRA.w	DialogState_MalageWaitScriptThenOpenSellList
	BRA.w	DialogState_MalageWaitDrawThenShowMoneySellWindow
	BRA.w	DialogState_MalageShopSelectItemToBuy
	BRA.w	DialogState_MalageShopConfirmOrCancel
	BRA.w	DialogState_MalageShopGiveVermilionSword
	BRA.w	DialogState_WaitScriptThenGoToOverworld
	BRA.w	DialogState_MalageBlacksmithIntro
DialogState_Init:
	MOVE.w	Main_menu_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	ADDQ.w	#1, Dialogue_state.w
	TST.b	Player_in_first_person_mode.w
	BNE.w	ShopInit_LoadAssortment_Loop
	JSR	GetTileInFrontOfPlayer
	CMPI.w	#TOWN_TILE_SHOP, D0
	BEQ.w	FortuneTeller_EnterState_Loop
	CMPI.w	#TOWN_TILE_FORTUNE_TELLER, D0
	BEQ.w	FortuneTeller_EnterState_Loop2
	CMPI.w	#TOWN_TILE_INN, D0
	BEQ.b	DialogState_Init_Loop
	CMPI.w	#TOWN_TILE_FORTUNE_TELLER_2, D0
	BEQ.b	DialogState_Init_Loop2
	CMPI.w	#TOWN_TILE_CHURCH, D0
	BEQ.b	DialogState_Init_Loop3
	BRA.w	ShopInit_LoadAssortment_Loop2
DialogState_Init_Loop3:
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_OPEN_CHURCH_MENU, Dialogue_state.w
	PRINT 	HelpPromptStr
	RTS

DialogState_Init_Loop2:
	LEA	FortuneTellerGreetingsByTown, A0
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	(A0)
	RTS

DialogState_Init_Loop:
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_WATLING, D0
	BNE.w	InnDialog_ShowPricePrompt
	TST.b	Watling_inn_free_stay_used.w
	BNE.w	InnDialog_ShowPricePrompt
	PRINT 	CustomerStayHereStr
	TST.b	Watling_youth_restored.w
	BNE.b	DialogState_Init_Loop4
	BRA.w	FortuneTeller_EnterState
DialogState_Init_Loop4:
	TST.w	Watling_inn_unpaid_nights.w
	BNE.b	DialogState_Init_Loop5
	MOVE.b	#FLAG_TRUE, Watling_inn_free_stay_used.w	
	BRA.w	InnDialog_ShowPricePrompt	
DialogState_Init_Loop5:
	LEA	Text_build_buffer.w, A1
	LEA	StayingForFreeStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	MOVE.w	Watling_inn_unpaid_nights.w, D0
	MULU.w	#$0190, D0
	ADDI.w	#$0190, D0
	JSR	ConvertToBCD
	BSR.w	FormatKimsAmount
	MOVE.b	#$2C, (A1)+
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	LEA	PayOrWorkStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
	BRA.b	FortuneTeller_EnterState
InnDialog_ShowPricePrompt:
	LEA	Text_build_buffer.w, A1
	LEA	RoomRentStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_CONTINUE, (A1)+
	LEA	IsStr, A0
	JSR	CopyStringUntilFF
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	InnAndFortuneTellerPricesByTown, A0
	MOVE.l	(A0,D0.w), D0
	BSR.w	FormatKimsAmount
	MOVE.b	#$20, (A1)+
	LEA	AllRightStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
FortuneTeller_EnterState:
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_DRAW_INN_YES_NO, Dialogue_state.w
	RTS

FortuneTeller_EnterState_Loop2:
	LEA	Text_build_buffer.w, A1
	LEA	FortuneTellerStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_CONTINUE, (A1)+
	LEA	FeeStr, A0
	JSR	CopyStringUntilFF
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	InnAndFortuneTellerPricesByTown, A0
	MOVE.l	(A0,D0.w), D0
	BSR.w	FormatKimsAmount
	MOVE.b	#$2E, (A1)+
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	LEA	PayFirstStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_WITH_YES_NO_OR_CONTINUE, Dialogue_state.w
	RTS

FortuneTeller_EnterState_Loop:
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_OPEN_SHOP_MENU, Dialogue_state.w
	CLR.w	Current_shop_type.w
	MOVE.w	Current_town_room.w, D0
	ANDI.w	#$0100, D0
	BEQ.b	FortuneTeller_EnterState_Loop3
	CLR.w	Current_shop_type.w
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_MALAGA, D0
	BNE.b	ShopInit_LoadAssortment
	BRA.b	ShopInit_LoadAssortment_Loop3
FortuneTeller_EnterState_Loop3:
	MOVE.w	Current_town_room.w, D0
	ANDI.w	#$0200, D0
	BEQ.b	FortuneTeller_EnterState_Loop4
	MOVE.w	#SHOP_TYPE_EQUIPMENT, Current_shop_type.w
	BRA.b	ShopInit_LoadAssortment
FortuneTeller_EnterState_Loop4:
	MOVE.w	Current_town_room.w, D0
	ANDI.w	#$0400, D0
	BEQ.b	ShopInit_LoadAssortment
	MOVE.w	#SHOP_TYPE_MAGIC, Current_shop_type.w
ShopInit_LoadAssortment:
	LEA	ShopDialog_Welcome, A0
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVE.w	Current_town.w, D1
	ASL.w	#4, D1
	ADD.w	D0, D1
	LEA	ShopAssortmentByTownAndShopType, A1
	LEA	Shop_item_list.w, A2
	MOVE.l	(A0,D0.w), Script_source_base.w
	MOVEA.l	(A1,D1.w), A1
	MOVE.w	(A1)+, D7
	MOVE.w	D7, Shop_item_count.w
	SUBQ.w	#1, D7
ShopInit_LoadAssortment_Done:
	MOVE.w	(A1)+, (A2)+
	DBF	D7, ShopInit_LoadAssortment_Done
	RTS

ShopInit_LoadAssortment_Loop2:
	BSR.w	CheckPlayerTalkToNPC
	RTS

ShopInit_LoadAssortment_Loop:
	MOVE.l	Script_talk_source.w, Script_source_base.w
	RTS

ShopInit_LoadAssortment_Loop3:
	LEA	ShopGreetingStrPtrs, A0
	CLR.w	D2
	MOVE.w	#3, D2
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_GO_TO_OVERWORLD, Dialogue_state.w
	TST.b	Player_has_received_sword_of_vermilion.w
	BNE.b	MalagaShop_LoadAssortment
	MOVE.w	#2, D2
	MOVE.w	#DIALOG_STATE_MALAGE_SHOP_GIVE_VERMILION_SWORD, Dialogue_state.w
	TST.b	Sword_retrieved_from_blacksmith.w
	BNE.b	MalagaShop_LoadAssortment
	MOVE.w	#1, D2
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_GO_TO_OVERWORLD, Dialogue_state.w
	TST.b	Sword_stolen_by_blacksmith.w
	BNE.b	MalagaShop_LoadAssortment
	CLR.w	D2
	MOVE.w	#DIALOG_STATE_MALAGE_WAIT_SCRIPT_THEN_OPEN_SELL_LIST, Dialogue_state.w
MalagaShop_LoadAssortment:
	ADD.w	D2, D2
	ADD.w	D2, D2
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVE.w	Current_town.w, D1
	ASL.w	#4, D1
	ADD.w	D0, D1
	LEA	ShopAssortmentByTownAndShopType, A1
	LEA	Shop_item_list.w, A2
	MOVE.l	(A0,D2.w), Script_source_base.w
	MOVEA.l	(A1,D1.w), A1
	MOVE.w	(A1)+, D7
	MOVE.w	D7, Shop_item_count.w
	SUBQ.w	#1, D7
MalagaShop_LoadAssortment_Done:
	MOVE.w	(A1)+, (A2)+
	DBF	D7, MalagaShop_LoadAssortment_Done
	RTS

ShopGreetingStrPtrs:
	dc.l	WelcomeMessageStr
	dc.l	HostileGreetingStr
	dc.l	ExplanationStr
	dc.l	DoneMyBestStr
WelcomeMessageStr:
	dc.b	"Welcome! May I help you?", $FF, $00
HostileGreetingStr:
	dc.b	"You again! I'll have", $FE
	dc.b	"nothing to do with the", $FE
	dc.b	"likes of you! Go away!", $FF, $00
ExplanationStr:
	dc.b	"At last I can explain my", $FE
	dc.b	"actions. I took your sword", $FE
	dc.b	"and gold so that I could", $FD
	dc.b	"create the Sword of Vermilion", $FE
	dc.b	"for you! I was rude to you", $FE
	dc.b	"because the spies from", $FD
	dc.b	"Cartahena might have", $FE
	dc.b	"suspected me otherwise.", $FE
	dc.b	"Here is the Sword of", $FD
	dc.b	"Vermilion, the most powerful", $FE
	dc.b	"weapon in the world! Use it", $FE
	dc.b	"wisely, my Prince!", $FF, $00

DialogState_MalageWaitScriptThenOpenSellList:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_MalageWaitScriptThenOpenSellList_Loop
	JSR	SaveShopListToBuffer
	JSR	DrawShopSellListWindow
	CLR.w	Shop_selected_index.w
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_MalageWaitScriptThenOpenSellList_Loop:
	JMP	ProcessScriptText
DialogState_MalageWaitDrawThenShowMoneySellWindow:
	TST.b	Window_tilemap_draw_active.w
	BNE.b	DialogState_MalageWaitDrawThenShowMoneySellWindow_Loop
	JSR	SaveLeftMenuTiles
	JSR	DrawMoneyDisplayWindow
	ADDQ.w	#1, Dialogue_state.w
DialogState_MalageWaitDrawThenShowMoneySellWindow_Loop:
	RTS

DialogState_MalageShopSelectItemToBuy:
	TST.b	Script_text_complete.w
	BEQ.w	DialogState_MalageShopSelectItemToBuy_Loop
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BEQ.b	DialogState_MalageShopSelectItemToBuy_Loop2
	JSR	ResetScriptAndInitDialogue	
	PRINT 	NoLeaveWithoutBuyingStr	
	CLR.b	Script_text_complete.w	
	MOVE.w	#SOUND_MENU_CANCEL, D0	
	JSR	QueueSoundEffect	
	JSR	RestoreLeftMenuFromBuffer	
	JSR	RestoreShopListFromBuffer	
	MOVE.w	#DIALOG_STATE_MALAGE_WAIT_SCRIPT_THEN_OPEN_SELL_LIST, Dialogue_state.w	
	RTS
	
DialogState_MalageShopSelectItemToBuy_Loop:
	JMP	ProcessScriptText	
DialogState_MalageShopSelectItemToBuy_Loop2:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.b	DialogState_MalageShopSelectItemToBuy_Loop3
	MOVE.w	Shop_selected_index.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	MOVE.w	#SOUND_MENU_SELECT, D0
	JSR	QueueSoundEffect
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
	MOVE.w	#DIALOG_STATE_MALAGE_BLACKSMITH_INTRO, Dialogue_state.w
	RTS

DialogState_MalageShopSelectItemToBuy_Loop3:
	MOVE.w	Shop_selected_index.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Shop_selected_index.w
	RTS

DialogState_MalageBlacksmithIntro:
	JSR	ResetScriptAndInitDialogue
	MOVE.w	Current_shop_type.w, D0
	ASL.w	#3, D0
	LEA	Text_build_buffer.w, A1
	LEA	Shop_item_list.w, A2
	MOVE.w	Shop_selected_index.w, D0
	ADD.w	D0, D0
	MOVE.w	(A2,D0.w), D0
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	VeryExpensiveStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
	MOVE.w	#DIALOG_STATE_MALAGE_SHOP_CONFIRM_OR_CANCEL, Dialogue_state.w
	RTS

NoLeaveWithoutBuyingStr:
	dc.b	"You can't leave unless", $FE
	dc.b	"you buy something!", $FF
VeryExpensiveStr:
	dc.b	"OK, but that's", $FE
	dc.b	"very expensive.", $FF, $00
NotEnoughMoneyStr:
	dc.b	"It seems that you don't", $FE
	dc.b	"have enough money to buy", $FE
	dc.b	"that item. What can we do?", $FD
	dc.b	"I know, I'll take your", $FE
	dc.b	"sword, too. Well now,", $FE
	dc.b	"you're a poor warrior", $FD
	dc.b	"without a sword. Here, take", $FE
	dc.b	"this one and get out before", $FE
	dc.b	"I change my mind.", $FF, $00
InsufficientFundsStr:
	dc.b	"You don't have enough", $FE
	dc.b	"money to buy that item.", $FF
ComeBackWithLessStr:
	dc.b	"Please come back when you", $FE
	dc.b	"have less combat equipment.", $FF
DoneMyBestStr:
	dc.b	"I have done my best;", $FE
	dc.b	"the rest is up to you.", $FF

DialogState_MalageShopConfirmOrCancel:
	TST.b	Script_text_complete.w
	BEQ.w	ShopBuy_CancelReturn_Loop
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.w	ShopBuy_CancelReturn
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.w	ShopBuy_CancelReturn_Loop2
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.w	Dialog_selection.w
	BNE.w	ShopBuy_CancelReturn
	MOVE.w	#SOUND_MENU_SELECT, D0
	JSR	QueueSoundEffect
	JSR	DrawLeftMenuWindow
	JSR	ResetScriptAndInitDialogue
	LEA	Possessed_items_length.w, A0
	MOVE.w	(A0), D0
	CMPI.w	#8, D0
	BLT.b	DialogState_MalageShopConfirmOrCancel_Loop
	PRINT 	CantCarryMoreStr2	
	BRA.w	ShopBuy_RestoreAndReturn	
DialogState_MalageShopConfirmOrCancel_Loop:
	CLR.b	Script_text_complete.w
	PRINT 	NotEnoughMoneyStr
	LEA	Possessed_equipment_length.w, A2
	LEA	(A2), A1
	MOVE.w	(A2)+, D7
	BLE.b	ShopBuy_ConfirmBuy
	SUBQ.w	#1, D7
DialogState_MalageShopConfirmOrCancel_Loop_Done:
	MOVE.w	D7, D1
	ADD.w	D1, D1
	MOVE.w	(A2,D1.w), D3
	MOVE.w	#$000A, D0
	BTST.l	D0, D3
	BEQ.b	DialogState_MalageShopConfirmOrCancel_Loop2
	SUBQ.w	#1, (A1)
	BGE.b	DialogState_MalageShopConfirmOrCancel_Loop3
	CLR.w	(A1)	
DialogState_MalageShopConfirmOrCancel_Loop3:
	MOVE.w	D7, D0
	LEA	Possessed_equipment_list.w, A0
	MOVE.w	#8, D2
	JSR	RemoveItemFromArray
DialogState_MalageShopConfirmOrCancel_Loop2:
	DBF	D7, DialogState_MalageShopConfirmOrCancel_Loop_Done
	MOVE.w	(A1), D0
	CMPI.w	#8, D0
	BLT.b	ShopBuy_ConfirmBuy
	PRINT 	InsufficientFundsStr	
	BRA.b	ShopBuy_RestoreAndReturn	
ShopBuy_ConfirmBuy:
	MOVE.w	(A1), D0
	ADDQ.w	#1, (A1)+
	ADD.w	D0, D0
	MOVE.w	#$0401, (A1,D0.w)
	MOVE.w	Equipped_sword.w, D0
	BLT.b	ShopBuy_ConfirmBuy_Loop
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	LEA	EquipmentToStatModifierMap, A0
	MOVE.w	(A0,D0.w), D0
	SUB.w	D0, Player_str.w
ShopBuy_ConfirmBuy_Loop:
	MOVE.w	#EQUIP_NONE, Equipped_sword.w
	MOVE.b	#FLAG_TRUE, Sword_stolen_by_blacksmith.w
	CLR.l	Player_kims.w
	LEA	Possessed_items_length.w, A0
	MOVE.w	(A0), D0
	ADDQ.w	#1, (A0)+
	ADD.w	D0, D0
	LEA	Shop_item_list.w, A1
	MOVE.w	Shop_selected_index.w, D1
	ADD.w	D1, D1
	MOVE.w	(A1,D1.w), D1
	MOVE.w	D1, (A0,D0.w)
ShopBuy_RestoreAndReturn:
	JSR	RestoreLeftMenuFromBuffer
	JSR	RestoreShopListFromBuffer
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_ADVANCE, Dialogue_state.w
	RTS

ShopBuy_CancelReturn:
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	JSR	DrawLeftMenuWindow
	MOVE.w	#DIALOG_STATE_MALAGE_WAIT_SCRIPT_THEN_OPEN_SELL_LIST, Dialogue_state.w
	JSR	RestoreLeftMenuFromBuffer
	JSR	RestoreShopListFromBuffer
	JSR	ResetScriptAndInitDialogue
	PRINT 	NoLeaveWithoutBuyingStr
	CLR.b	Script_text_complete.w
	RTS

ShopBuy_CancelReturn_Loop2:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

ShopBuy_CancelReturn_Loop:
	JSR	ProcessScriptText
	RTS

DialogState_MalageShopGiveVermilionSword:
	LEA	Possessed_equipment_length.w, A0
	MOVE.w	(A0), D0
	CMPI.w	#8, D0 ; Max number of equipment
	BLT.b	DialogState_MalageShopGiveVermilionSword_Loop
	PRINT 	ComeBackWithLessStr	
	BRA.b	DialogState_MalageShopGiveVermilionSword_Loop2	
DialogState_MalageShopGiveVermilionSword_Loop:
	MOVE.w	(A0), D0
	ADDQ.w	#1, (A0)+
	ADD.w	D0, D0
	MOVE.w	#((EQUIPMENT_TYPE_SWORD<<8)|EQUIPMENT_SWORD_OF_VERMILION), (A0,D0.w)
	MOVE.b	#FLAG_TRUE, Player_has_received_sword_of_vermilion.w
DialogState_MalageShopGiveVermilionSword_Loop2:
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_ADVANCE, Dialogue_state.w
	RTS

DialogState_WaitScriptThenGoToOverworld:
	TST.b	Script_text_complete.w
	BEQ.b	DialogWait_ClearRow_Loop
	TST.b	Script_has_continuation.w
	BNE.w	DialogWait_ClearRow_Loop2
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	DialogWait_ClearRow
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	DialogWait_ClearRow
	RTS

DialogWait_ClearRow:
	CLR.w	Window_text_row.w
	MOVE.w	#DIALOG_STATE_REDRAW_HUD_AND_CLOSE, Dialogue_state.w
	RTS

DialogWait_ClearRow_Loop2:
	MOVE.w	#BUTTON_BIT_C, D2	
	JSR	CheckButtonPress	
	BEQ.b	DialogWait_ClearRow_Loop3	
	JSR	InitDialogueWindow	
DialogWait_ClearRow_Loop:
	JSR	ProcessScriptText
DialogWait_ClearRow_Loop3:
	RTS

DialogState_WaitScriptThenAdvance:
	TST.b	Window_tilemap_draw_pending.w
	BNE.b	DialogState_WaitScriptThenAdvance_Loop
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptThenAdvance_Loop2
	TST.b	Script_has_continuation.w
	BNE.b	DialogState_WaitScriptThenAdvance_Loop3
	TST.b	Script_has_yes_no_question.w
	BNE.b	DialogState_WaitScriptThenAdvance_Loop4
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_WaitScriptThenAdvance_Loop3:
	MOVE.w	#DIALOG_STATE_WAIT_C_THEN_RESTART_DIALOGUE, Dialogue_state.w
	RTS

DialogState_WaitScriptThenAdvance_Loop4:
	MOVE.w	#DIALOG_STATE_DRAW_YES_NO_DIALOG, Dialogue_state.w
	RTS

DialogState_WaitScriptThenAdvance_Loop2:
	JSR	ProcessScriptText
DialogState_WaitScriptThenAdvance_Loop:
	RTS

DialogState_WaitButtonThenCloseMenu:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	DialogWait_CloseToOverworld
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	DialogWait_CloseToOverworld
	RTS

DialogWait_CloseToOverworld:
	CLR.w	Overworld_menu_state.w
	JSR	DrawStatusHudWindow
	MOVE.w	#WINDOW_DRAW_MSG_SPEED_ALT, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	RTS

DialogState_WaitCThenRestartDialogue:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.b	DialogState_WaitCThenRestartDialogue_Loop
	JSR	InitDialogueWindow
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_ADVANCE, Dialogue_state.w
DialogState_WaitCThenRestartDialogue_Loop:
	RTS

DialogState_DrawYesNoDialog:
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_ProcessYesNoAnswer:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.w	DialogueChoice_Continue_Loop
	JSR	DrawLeftMenuWindow
	JSR	ResetScriptAndInitDialogue
	TST.b	Dialogue_event_trigger_flag.w
	BNE.b	DialogState_ProcessYesNoAnswer_Loop
	TST.b	Quest_choice_pending.w
	BEQ.b	DialogueChoice_Continue
	MOVE.w	Quest_choice_expected_answer.w, D0	
	MOVE.w	Dialog_selection.w, D1	
	CMP.b	D1, D0	
	BNE.b	DialogueChoice_Continue	
	LSR.w	#8, D0	
	ANDI.w	#$00FF, D0	
	LEA	Map_trigger_flags.w, A0	
	MOVE.b	#1, (A0,D0.w)	
	BRA.b	DialogueChoice_Continue	
DialogState_ProcessYesNoAnswer_Loop:
	MOVE.w	Dialog_choice_event_trigger.w, D0
	MOVE.w	Dialog_selection.w, D1
	CMP.b	D1, D0
	BNE.b	DialogueChoice_Continue
	LSR.w	#8, D0
	ANDI.w	#$00FF, D0
	LEA	Event_triggers_start.w, A0
	MOVE.b	#1, (A0,D0.w)
DialogueChoice_Continue:
	TST.w	Dialog_selection.w
	BEQ.b	DialogueChoice_Continue_Loop2
	LEA	DialogueChoiceNoStrPtrs, A0
	BRA.b	DialogueChoice_Continue_Loop3
DialogueChoice_Continue_Loop2:
	LEA	DialogueChoiceYesStrPtrs, A0
DialogueChoice_Continue_Loop3:
	CLR.w	Dialog_choice_event_trigger.w
	CLR.b	Dialogue_event_trigger_flag.w
	CLR.b	Quest_choice_pending.w
	CLR.w	D0
	MOVE.b	Dialog_response_index.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVE.l	(A0,D0.w), Script_source_base.w
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_ADVANCE, Dialogue_state.w
	RTS

DialogueChoice_Continue_Loop:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

DialogState_WaitScriptThenOpenShopMenu:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptThenOpenShopMenu_Loop
	CLR.b	Shop_purchase_made.w
	JSR	SaveStatusMenuAreaToBuffer_Small
	JSR	DrawShopMenuWindow
	CLR.w	Shop_action_selection.w
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_WaitScriptThenOpenShopMenu_Loop:
	JMP	ProcessScriptText
DialogState_ShopMenuInput:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	ShopSell_ListReturn
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	ShopSell_ListReturn
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BEQ.b	DialogState_ShopMenuInput_Loop
	BRA.b	DialogState_ShopMenuInput_Loop2
DialogState_ShopMenuInput_Loop:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.b	ShopSell_ShowPrompt_Loop
	MOVE.w	Shop_action_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.w	Shop_action_selection.w
	BEQ.b	DialogState_ShopMenuInput_Loop3
	CMPI.w	#1, Shop_action_selection.w
	BEQ.b	DialogState_ShopMenuInput_Loop4
DialogState_ShopMenuInput_Loop2:
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_NextTime, A0
	TST.b	Shop_purchase_made.w
	BEQ.b	DialogState_ShopMenuInput_Loop5
	LEA	ShopDialog_BusinessThanks, A0	
DialogState_ShopMenuInput_Loop5:
	MOVE.l	(A0,D0.w), Script_source_base.w
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_TO_OVERWORLD, Dialogue_state.w
	BRA.b	ShopSell_ShowPrompt
DialogState_ShopMenuInput_Loop3:
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_BuyPrompt, A0
	MOVE.l	(A0,D0.w), Script_source_base.w
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_OPEN_SELL_LIST_WINDOW, Dialogue_state.w
	BRA.b	ShopSell_ShowPrompt
DialogState_ShopMenuInput_Loop4:
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_SellPrompt, A0
	MOVE.l	(A0,D0.w), Script_source_base.w
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_OPEN_INVENTORY_SELL_LIST, Dialogue_state.w
ShopSell_ShowPrompt:
	JMP	ResetScriptAndInitDialogue
ShopSell_ShowPrompt_Loop:
	MOVE.w	Shop_action_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Shop_action_selection.w
ShopSell_ListReturn:
	RTS

DialogState_WaitScriptThenCloseToOverworld:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_ShowWindowReturn_Loop
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	DialogState_ShowWindowReturn
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	DialogState_ShowWindowReturn
	RTS

DialogState_ShowWindowReturn:
	MOVE.w	#WINDOW_DRAW_ITEM_LIST_TALL, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	MOVE.w	#DIALOG_STATE_REDRAW_HUD_AND_CLOSE, Dialogue_state.w
	RTS

DialogState_ShowWindowReturn_Loop:
	JMP	ProcessScriptText
DialogState_RedrawHudAndClose:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.b	DialogState_RedrawHudAndClose_Loop
	JSR	DrawStatusHudWindow
	CLR.w	Overworld_menu_state.w
	MOVE.w	#WINDOW_DRAW_MSG_SPEED_ALT, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
DialogState_RedrawHudAndClose_Loop:
	RTS

DialogState_WaitScriptThenOpenSellListWindow:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptThenOpenSellListWindow_Loop
	JSR	SaveShopListToBuffer
	JSR	DrawShopItemListWindow
	CLR.w	Shop_selected_index.w
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_WaitScriptThenOpenSellListWindow_Loop:
	JSR	ProcessScriptText
	RTS

DialogState_WaitDrawThenShowMoneyWindow:
	TST.b	Window_tilemap_draw_active.w
	BNE.b	DialogState_WaitDrawThenShowMoneyWindow_Loop
	JSR	SaveLeftMenuTiles
	JSR	DrawMoneyDisplayWindow
	ADDQ.w	#1, Dialogue_state.w
DialogState_WaitDrawThenShowMoneyWindow_Loop:
	RTS

DialogState_ShopSellItemSelectInput:
	TST.b	Script_text_complete.w
	BEQ.w	DialogState_ShopSellItemSelectInput_Loop
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BEQ.b	DialogState_ShopSellItemSelectInput_Loop2
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	JSR	RestoreLeftMenuFromBuffer
	JSR	RestoreShopListFromBuffer
	JSR	DrawShopMenuWindow
	MOVE.w	#DIALOG_STATE_SHOP_MENU_INPUT, Dialogue_state.w
	RTS

DialogState_ShopSellItemSelectInput_Loop2:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.w	DialogState_ShopSellItemSelectInput_Loop3
	MOVE.w	#SOUND_MENU_SELECT, D0
	JSR	QueueSoundEffect
	MOVE.w	Shop_selected_index.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
	JSR	ResetScriptOutputVars
	LEA	Text_build_buffer.w, A1
	LEA	IsStr, A0
	JSR	CopyStringUntilFF
	LEA	ShopCategoryNameTables, A0
	MOVE.w	Current_shop_type.w, D0
	ASL.w	#3, D0
	MOVEA.l	(A0,D0.w), A0
	LEA	Shop_item_list.w, A2
	MOVE.w	Shop_selected_index.w, D0
	ADD.w	D0, D0
	MOVE.w	(A2,D0.w), D0
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	CopyStringUntilFF
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_Ok, A0
	MOVEA.l	(A0,D0.w), A0
	JSR	CopyStringUntilFF
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_ShopSellItemSelectInput_Loop3:
	MOVE.w	Shop_selected_index.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Shop_selected_index.w
	RTS

DialogState_ShopSellItemSelectInput_Loop:
	JMP	ProcessScriptText	
DialogState_ShopBuyConfirmAndPurchase:
	TST.b	Script_text_complete.w
	BEQ.w	ShopCancel_RedrawBuyPrompt_Loop
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.w	ShopCancel_RedrawBuyPrompt
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.w	ShopCancel_RedrawBuyPrompt_Loop2
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.w	Dialog_selection.w
	BNE.w	ShopCancel_RedrawBuyPrompt
	MOVE.w	#SOUND_MENU_SELECT, D0
	JSR	QueueSoundEffect
	JSR	DrawLeftMenuWindow
	JSR	ResetScriptAndInitDialogue
	LEA	ShopPricesByTownAndType, A0
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	ADD.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	MOVE.w	Shop_selected_index.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVE.l	(A0,D0.w), Shop_selected_price.w
	MOVE.l	(A0,D0.w), D0
	MOVE.l	Player_kims.w, D1
	ANDI.l	#$00FFFFFF, D1
	CMP.l	D0, D1
	BLT.b	DialogState_ShopBuyConfirmAndPurchase_Loop
	LEA	ShopCategoryNameTables, A0
	MOVE.w	Current_shop_type.w, D0
	ASL.w	#3, D0
	MOVEA.l	$4(A0,D0.w), A0
	MOVE.w	(A0), D0
	CMPI.w	#8, D0
	BLT.b	DialogState_ShopBuyConfirmAndPurchase_Loop2
	PRINT 	CantCarryMoreStr2
	BRA.b	ShopGiveaway_RestoreList
DialogState_ShopBuyConfirmAndPurchase_Loop2:
	ADDQ.w	#1, (A0)+
	ADD.w	D0, D0
	LEA	Shop_item_list.w, A1
	MOVE.w	Shop_selected_index.w, D1
	ADD.w	D1, D1
	MOVE.w	(A1,D1.w), D1
	MOVE.w	D1, (A0,D0.w)
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_ThankYou, A0
	MOVE.l	(A0,D0.w), Script_source_base.w
	MOVE.l	Shop_selected_price.w, Transaction_amount.w
	JSR	DeductPaymentAmount
	JSR	DisplayPlayerKims
	BRA.b	ShopGiveaway_RestoreList
DialogState_ShopBuyConfirmAndPurchase_Loop:
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_GivingAway, A0
	MOVE.l	(A0,D0.w), Script_source_base.w
ShopGiveaway_RestoreList:
	JSR	RestoreShopListFromBuffer
	ADDQ.w	#1, Dialogue_state.w
	RTS

ShopCancel_RedrawBuyPrompt:
	MOVE.w	#SOUND_MENU_CANCEL, D0	
	JSR	QueueSoundEffect	
	JSR	DrawLeftMenuWindow	
	MOVE.w	#DIALOG_STATE_SHOP_SELL_ITEM_SELECT_INPUT, Dialogue_state.w	
	JSR	SetShopMenuCursorPosition	
	JSR	ResetScriptAndInitDialogue	
	MOVE.w	Current_shop_type.w, D0	
	ADD.w	D0, D0	
	ADD.w	D0, D0	
	LEA	ShopDialog_BuyPrompt, A0	
	MOVE.l	(A0,D0.w), Script_source_base.w	
	RTS
	
ShopCancel_RedrawBuyPrompt_Loop2:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

ShopCancel_RedrawBuyPrompt_Loop:
	JMP	ProcessScriptText
DialogState_WaitScriptThenDrawSellConfirm:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptThenDrawSellConfirm_Loop
	JSR	SaveRightMenuAreaToBuffer
	ADDQ.w	#1, Dialogue_state.w
	JSR	ResetScriptOutputVars
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_AnythingElse, A0
	MOVE.l	(A0,D0.w), Script_source_base.w
	MOVE.b	#FLAG_TRUE, Shop_purchase_made.w
	JSR	DrawYesNoDialog
	RTS

DialogState_WaitScriptThenDrawSellConfirm_Loop:
	JMP	ProcessScriptText
DialogState_SellConfirmYesNoInput:
	TST.b	Script_text_complete.w
	BEQ.w	ShopBuyDone_ThankYou_Loop
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	ShopBuyDone_ThankYou
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	DialogState_SellConfirmYesNoInput_Loop
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

DialogState_SellConfirmYesNoInput_Loop:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.w	Dialog_selection.w
	BNE.b	ShopBuyDone_ThankYou
	JSR	DrawShopMenuWindow
	JSR	RestoreLeftMenuFromBuffer
	JSR	DrawLeftMenuWindow
	MOVE.w	#DIALOG_STATE_SHOP_MENU_INPUT, Dialogue_state.w
	RTS

ShopBuyDone_ThankYou:
	JSR	RestoreLeftMenuFromBuffer
	JSR	DrawLeftMenuWindow
	JSR	ResetScriptAndInitDialogue
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_BusinessThanks, A0
	MOVE.l	(A0,D0.w), Script_source_base.w
	ADDQ.w	#1, Dialogue_state.w
	RTS

ShopBuyDone_ThankYou_Loop:
	JMP	ProcessScriptText
DialogState_WaitScriptThenGoToBuyMenu:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptThenGoToBuyMenu_Loop
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_TO_OVERWORLD, Dialogue_state.w
	RTS

DialogState_WaitScriptThenGoToBuyMenu_Loop:
	JSR	ProcessScriptText
	RTS

DialogState_WaitScriptThenOpenInventorySellList:
	TST.b	Script_text_complete.w
	BEQ.w	ShopEquip_InitCursor_Loop
	MOVE.w	Current_shop_type.w, D0
	ASL.w	#3, D0
	LEA	ShopCategoryNameTables, A0
	MOVEA.l	$4(A0,D0.w), A0
	MOVE.w	(A0), D0
	BEQ.w	ShopEquip_InitCursor_Loop2
	JSR	SaveCenterDialogAreaToBuffer
	MOVE.w	Current_shop_type.w, D0
	BEQ.b	DialogState_WaitScriptThenOpenInventorySellList_Loop
	CMPI.w	#SHOP_TYPE_EQUIPMENT, D0
	BEQ.b	DialogState_WaitScriptThenOpenInventorySellList_Loop2
	JSR	DrawMagicListBorders
	JSR	DrawMagicListWithMP
	MOVE.l	#Possessed_magics_list, Active_inventory_list_ptr.w
	MOVE.w	Possessed_magics_length.w, D0
	BRA.b	ShopEquip_InitCursor
DialogState_WaitScriptThenOpenInventorySellList_Loop:
	JSR	DrawItemListBorders
	JSR	DrawItemListNames
	MOVE.l	#Possessed_items_list, Active_inventory_list_ptr.w
	MOVE.w	Possessed_items_length.w, D0
	BRA.b	ShopEquip_InitCursor
DialogState_WaitScriptThenOpenInventorySellList_Loop2:
	JSR	DrawEquipmentListWindow
	JSR	DrawPossessedEquipmentList
	MOVE.l	#Possessed_equipment_list, Active_inventory_list_ptr.w
	MOVE.w	Possessed_equipment_length.w, D0
ShopEquip_InitCursor:
	JSR	InitMenuCursorForList
	JSR	SaveLeftMenuTiles
	JSR	DrawMoneyDisplayWindow
	JSR	DisplayPlayerKims
	CLR.w	Shop_selected_index.w
	MOVE.w	#DIALOG_STATE_SELL_INVENTORY_ITEM_SELECT_INPUT, Dialogue_state.w
	RTS

ShopEquip_InitCursor_Loop2:
	JSR	ResetScriptAndInitDialogue
	JSR	SaveLeftMenuTiles
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_SellAnything, A0
	MOVE.l	(A0,D0.w), Script_source_base.w
	ADDQ.w	#1, Dialogue_state.w
	RTS

ShopEquip_InitCursor_Loop:
	JMP	ProcessScriptText
DialogState_WaitScriptThenReturnToSellList:
	TST.b	Script_text_complete.w
	BEQ.b	DialogWait_ShowAnythingElse_Loop
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	DialogWait_ShowAnythingElse
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	DialogWait_ShowAnythingElse
	RTS

DialogWait_ShowAnythingElse:
	JSR	ResetScriptAndInitDialogue
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_AnythingElse, A0
	MOVE.l	(A0,D0.w), Script_source_base.w
	MOVE.w	#DIALOG_STATE_DRAW_SELL_INVENTORY_YES_NO, Dialogue_state.w
	RTS

DialogWait_ShowAnythingElse_Loop:
	JMP	ProcessScriptText
DialogState_SellInventoryItemSelectInput:
	TST.b	Script_text_complete.w
	BEQ.w	ShopBuy_ScanItem_Loop
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BEQ.b	DialogState_SellInventoryItemSelectInput_Loop
	JSR	DrawCenterMenuWindow
	JSR	RestoreLeftMenuFromBuffer
	JSR	DrawShopMenuWindow
	MOVE.w	#DIALOG_STATE_SHOP_MENU_INPUT, Dialogue_state.w
	RTS

DialogState_SellInventoryItemSelectInput_Loop:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.w	ShopBuy_ScanItem_Loop2
	MOVE.w	Shop_selected_index.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	JSR	ResetScriptAndInitDialogue
	LEA	Text_build_buffer.w, A1
	MOVEA.l	Active_inventory_list_ptr.w, A2
	MOVE.w	Shop_selected_index.w, D0
	ADD.w	D0, D0
	MOVE.w	(A2,D0.w), D0
	MOVE.w	#8, D1
	BTST.l	D1, D0
	BNE.w	ShopBuy_ScanItem_Loop3
	CMPI.w	#SHOP_TYPE_EQUIPMENT, Current_shop_type.w
	BNE.b	ShopBuy_ScanItem
	MOVE.w	#9, D1
	BTST.l	D1, D0
	BEQ.b	ShopBuy_ScanItem
	MOVE.w	#$000F, D1
	BTST.l	D1, D0
	BNE.b	ShopBuy_ScanItem_Loop4
ShopBuy_ScanItem:
	MOVE.w	D0, D2
	LEA	IsStr, A0
	JSR	CopyStringUntilFF
	BSR.w	FormatShopItemPrice
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_AllRight, A0
	MOVEA.l	(A0,D0.w), A0
	JSR	CopyStringUntilFF
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
	ADDQ.w	#1, Dialogue_state.w
	RTS

ShopBuy_ScanItem_Loop4:
	PRINT 	CursedItemStr	
	BRA.b	ShopBuy_ScanItem_Loop5	
ShopBuy_ScanItem_Loop3:
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_NoNeed, A0
	MOVE.l	(A0,D0.w), Script_source_base.w
ShopBuy_ScanItem_Loop5:
	JSR	DrawCenterMenuWindow
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_RETURN_TO_SELL_LIST, Dialogue_state.w
	RTS

ShopBuy_ScanItem_Loop2:
	MOVE.w	Shop_selected_index.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Shop_selected_index.w
	RTS

ShopBuy_ScanItem_Loop:
	JMP	ProcessScriptText	
DialogState_WaitScriptThenDrawSellItemYesNo:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptThenDrawSellItemYesNo_Loop
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_WaitScriptThenDrawSellItemYesNo_Loop:
	JMP	ProcessScriptText
DialogState_SellInventoryConfirmAndSell:
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.w	ShopEquip_DrawAndSetState
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.w	ShopEquip_DrawAndSetState_Loop
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.w	Dialog_selection.w
	BNE.w	ShopEquip_DrawAndSetState
	MOVE.l	Shop_sell_price.w, Transaction_amount.w
	JSR	AddPaymentAmount
	JSR	DisplayPlayerKims
	LEA	ShopCategoryNameTables, A0
	MOVE.w	Current_shop_type.w, D0
	ASL.w	#3, D0
	MOVEA.l	$4(A0,D0.w), A0
	SUBQ.w	#1, (A0)+
	MOVEA.l	Active_inventory_list_ptr.w, A2
	MOVE.w	Shop_selected_index.w, D0
	ADD.w	D0, D0
	MOVE.w	(A2,D0.w), D0
	BGE.w	ShopSell_RemoveFromList
	CMPI.l	#Possessed_magics_list, Active_inventory_list_ptr.w
	BNE.w	DialogState_SellInventoryConfirmAndSell_Loop
	MOVE.w	#MAGIC_NONE, Readied_magic.w
	BRA.w	ShopSell_RemoveFromList
DialogState_SellInventoryConfirmAndSell_Loop:
	LEA	Equipped_items.w, A2
	MOVE.w	D0, D2
	MOVE.w	#$000A, D1
	ASR.w	D1, D0
DialogState_SellInventoryConfirmAndSell_Loop_Done:
	BTST.l	#0, D0
	BNE.b	DialogState_SellInventoryConfirmAndSell_Loop2
	LEA	$2(A2), A2
	ASR.w	#1, D0
	BRA.b	DialogState_SellInventoryConfirmAndSell_Loop_Done
DialogState_SellInventoryConfirmAndSell_Loop2:
	MOVE.w	#$FFFF, (A2)
	MOVE.w	D2, D0
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	LEA	EquipmentToStatModifierMap, A3
	ANDI.w	#$0400, D2
	BEQ.b	DialogState_SellInventoryConfirmAndSell_Loop3
	MOVE.w	Player_str.w, D1	
	SUB.w	(A3,D0.w), D1	
	ANDI.w	#$7FFF, D1	
	MOVE.w	D1, Player_str.w	
	BRA.b	ShopSell_RemoveFromList	
DialogState_SellInventoryConfirmAndSell_Loop3:
	MOVE.w	Player_ac.w, D1
	SUB.w	(A3,D0.w), D1
	ANDI.w	#$7FFF, D1
	MOVE.w	D1, Player_ac.w
ShopSell_RemoveFromList:
	MOVE.w	Shop_selected_index.w, D0
	MOVE.w	#8, D2
	JSR	RemoveItemFromArray
	JSR	DrawLeftMenuWindow
	JSR	DrawCenterMenuWindow
	JSR	ResetScriptAndInitDialogue
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_ThankYou, A0
	MOVE.l	(A0,D0.w), Script_source_base.w
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_DRAW_SELL_CONFIRM, Dialogue_state.w
	RTS

ShopEquip_DrawAndSetState:
	JSR	DrawLeftMenuWindow	
	MOVE.w	#DIALOG_STATE_SELL_INVENTORY_ITEM_SELECT_INPUT, Dialogue_state.w	
	MOVEA.l	Active_inventory_list_ptr.w, A0	
	MOVE.w	-$2(A0), D0	
	JSR	InitMenuCursorForList	
	JSR	ResetScriptAndInitDialogue	
	MOVE.w	Current_shop_type.w, D0	
	ADD.w	D0, D0	
	ADD.w	D0, D0	
	LEA	ShopDialog_SellPrompt, A0	
	MOVE.l	(A0,D0.w), Script_source_base.w	
	RTS
	
ShopEquip_DrawAndSetState_Loop:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

DialogState_DrawSellInventoryYesNo:
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
	MOVE.w	#DIALOG_STATE_SELL_INVENTORY_CANCEL_OR_CONFIRM, Dialogue_state.w
	RTS

DialogState_SellInventoryCancelOrConfirm:
	TST.b	Script_text_complete.w
	BEQ.w	ShopSell_RestoreAndInit_Loop
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	ShopSell_RestoreAndInit
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	DialogState_SellInventoryCancelOrConfirm_Loop
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

DialogState_SellInventoryCancelOrConfirm_Loop:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.w	Dialog_selection.w
	BNE.b	ShopSell_RestoreAndInit
	JSR	RestoreLeftMenuFromBuffer	
	JSR	DrawShopMenuWindow	
	JSR	DrawLeftMenuWindow	
	MOVE.w	#DIALOG_STATE_SHOP_MENU_INPUT, Dialogue_state.w	
	RTS
	
ShopSell_RestoreAndInit:
	JSR	RestoreLeftMenuFromBuffer
	JSR	DrawLeftMenuWindow
	JSR	ResetScriptAndInitDialogue
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_BusinessThanks, A0
	MOVE.l	(A0,D0.w), Script_source_base.w
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_GO_TO_BUY_MENU, Dialogue_state.w
	RTS

ShopSell_RestoreAndInit_Loop:
	JMP	ProcessScriptText
DialogState_WaitScriptWithYesNoOrContinue:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptWithYesNoOrContinue_Loop
	TST.b	Script_has_continuation.w
	BNE.w	DialogState_WaitScriptWithYesNoOrContinue_Loop2
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_WaitScriptWithYesNoOrContinue_Loop2:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.b	DialogState_WaitScriptWithYesNoOrContinue_Loop3
	JSR	InitDialogueWindow
DialogState_WaitScriptWithYesNoOrContinue_Loop:
	JSR	ProcessScriptText
DialogState_WaitScriptWithYesNoOrContinue_Loop3:
	RTS

DialogState_DrawFortuneTellerMoneyWindow:
	JSR	SaveLeftMenuTiles
	JSR	DrawMoneyDisplayWindow
	JSR	DisplayPlayerKims
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_FortuneTellerPayAndRead:
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.w	FortuneTeller_NoQuestionsLeft
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.w	FortuneTeller_DrawAndSetState_Loop
	TST.w	Dialog_selection.w
	BNE.w	FortuneTeller_NoQuestionsLeft
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	InnAndFortuneTellerPricesByTown, A0
	MOVE.l	(A0,D0.w), D0
	MOVE.l	Player_kims.w, D1
	ANDI.l	#$00FFFFFF, D1
	CMP.l	D0, D1
	BLT.w	DialogState_FortuneTellerPayAndRead_Loop
	MOVE.l	D0, Transaction_amount.w
	JSR	DeductPaymentAmount
	JSR	DisplayPlayerKims
	LEA	FortuneTellerReadingsByTown, A0
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	(A0)
	BRA.b	FortuneTeller_DrawAndSetState
DialogState_FortuneTellerPayAndRead_Loop:
	PRINT 	NoPayNoFortuneStr
	BRA.b	FortuneTeller_DrawAndSetState
FortuneTeller_NoQuestionsLeft:
	PRINT 	NoQuestionsStr
FortuneTeller_DrawAndSetState:
	JSR	DrawLeftMenuWindow
	MOVE.w	#DIALOG_STATE_WAIT_FORTUNE_TELLER_SCRIPT_THEN_CLOSE, Dialogue_state.w
	JMP	ResetScriptAndInitDialogue
FortuneTeller_DrawAndSetState_Loop:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

DialogState_WaitFortuneTellerScriptThenClose:
	TST.b	Script_text_complete.w
	BEQ.b	ShopExit_RestoreHud_Loop
	TST.b	Script_has_continuation.w
	BNE.b	ShopExit_RestoreHud_Loop2
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	ShopExit_RestoreHud
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	ShopExit_RestoreHud
	RTS

ShopExit_RestoreHud:
	JSR	DrawStatusHudWindow
	JSR	RestoreLeftMenuFromBuffer
	CLR.w	Overworld_menu_state.w
	MOVE.w	#WINDOW_DRAW_MSG_SPEED_ALT, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	RTS

ShopExit_RestoreHud_Loop:
	JMP	ProcessScriptText
ShopExit_RestoreHud_Loop2:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.b	ShopExit_RestoreHud_Loop3
	JSR	InitDialogueWindow
ShopExit_RestoreHud_Loop3:
	RTS

DialogState_WaitScriptThenDrawInnYesNo:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptThenDrawInnYesNo_Loop
	TST.b	Script_has_continuation.w
	BNE.b	DialogState_WaitScriptThenDrawInnYesNo_Loop2
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_WATLING, D0
	BNE.b	DialogState_WaitScriptThenDrawInnYesNo_Loop3
	TST.b	Watling_inn_free_stay_used.w
	BEQ.b	DialogState_WaitScriptThenDrawInnYesNo_Loop4
DialogState_WaitScriptThenDrawInnYesNo_Loop3:
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
DialogState_WaitScriptThenDrawInnYesNo_Loop4:
	MOVE.w	#DIALOG_STATE_DRAW_INN_MONEY_WINDOW, Dialogue_state.w
	RTS

DialogState_WaitScriptThenDrawInnYesNo_Loop:
	JMP	ProcessScriptText
DialogState_WaitScriptThenDrawInnYesNo_Loop2:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.b	DialogState_WaitScriptThenDrawInnYesNo_Loop5
	JSR	InitDialogueWindow
DialogState_WaitScriptThenDrawInnYesNo_Loop5:
	RTS

DialogState_DrawInnMoneyWindow:
	JSR	SaveLeftMenuTiles
	JSR	DrawMoneyDisplayWindow
	JSR	DisplayPlayerKims
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_InnPayAndSleep:
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_WATLING, D0
	BNE.w	InnWatling_ConfirmPayment
	TST.b	Watling_inn_free_stay_used.w
	BNE.w	InnWatling_ConfirmPayment
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	InnWatling_CreditNight
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	InnWatling_CreditNight
	RTS

InnWatling_CreditNight:
	ADDQ.w	#1, Watling_inn_unpaid_nights.w
	TST.b	Watling_youth_restored.w
	BEQ.w	InnWatling_SetRestState
	MOVE.w	Watling_inn_unpaid_nights.w, D7
	SUBQ.w	#1, D7
InnWatling_CreditNight_Done:
	MOVE.l	Player_kims.w, D1
	ANDI.l	#$00FFFFFF, D1
	CMPI.l	#$400, D1
	BLT.b	InnWatling_CreditNight_Loop
	MOVE.l	#$400, Transaction_amount.w
	JSR	DeductPaymentAmount
	DBF	D7, InnWatling_CreditNight_Done
	BRA.b	InnWatling_CreditNight_Loop2
InnWatling_CreditNight_Loop:
	MOVE.b	#FLAG_TRUE, Watling_inn_broke_penalty.w	
	CLR.l	Player_kims.w	
InnWatling_CreditNight_Loop2:
	JSR	DisplayPlayerKims
	CLR.w	Watling_inn_unpaid_nights.w
	BRA.w	InnWatling_SetRestState
InnWatling_ConfirmPayment:
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.w	InnWatling_ServicesCost
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.w	InnWatling_ServicesCost_Loop
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.w	Dialog_selection.w
	BNE.w	InnWatling_ServicesCost
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	InnAndFortuneTellerPricesByTown, A0
	MOVE.l	(A0,D0.w), D0
	MOVE.l	Player_kims.w, D1
	ANDI.l	#$00FFFFFF, D1
	CMP.l	D0, D1
	BLT.b	InnWatling_SetRestState_Loop
	MOVE.l	D0, Transaction_amount.w
	JSR	DeductPaymentAmount
	JSR	DisplayPlayerKims
	PRINT 	RestWellStr
	JSR	DrawLeftMenuWindow
	JSR	ResetScriptAndInitDialogue
InnWatling_SetRestState:
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_START_SLEEP_FADE, Dialogue_state.w
	RTS

InnWatling_SetRestState_Loop:
	PRINT 	NoPaySleepStreetStr
	BRA.b	InnWatling_ServicesCost_Loop2
InnWatling_ServicesCost:
	PRINT 	ServicesCostStr
InnWatling_ServicesCost_Loop2:
	JSR	DrawLeftMenuWindow
	MOVE.w	#DIALOG_STATE_WAIT_FORTUNE_TELLER_SCRIPT_THEN_CLOSE, Dialogue_state.w
	JSR	ResetScriptAndInitDialogue
	RTS

InnWatling_ServicesCost_Loop:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

DialogState_WaitScriptThenStartSleepFade:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptThenStartSleepFade_Loop
	MOVE.w	#DIALOG_STATE_SLEEP_FADE_AND_RESTORE, Dialogue_state.w
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.w	#SLEEP_DELAY_FRAMES, Sleep_delay_timer.w
	MOVE.b	#SOUND_SLEEP, D0
	JMP	QueueSoundEffect
DialogState_WaitScriptThenStartSleepFade_Loop:
	JMP	ProcessScriptText
DialogState_SleepFadeAndRestore:
	TST.b	Fade_out_lines_mask.w
	BNE.w	ChurchDialog_SetState_Return
	SUBQ.w	#1, Sleep_delay_timer.w
	BGE.w	ChurchDialog_SetState_Return
	TST.b	Watling_inn_broke_penalty.w
	BEQ.b	DialogState_SleepFadeAndRestore_Loop
	MOVE.w	Player_hp.w, D0	
	CMPI.w	#1, D0	
	BEQ.b	DialogState_SleepFadeAndRestore_Loop2	
	LSR.w	#1, D0	
DialogState_SleepFadeAndRestore_Loop2:
	MOVE.w	D0, Player_hp.w	
	MOVE.w	Player_mp.w, D0	
	LSR.w	#1, D0	
	MOVE.w	D0, Player_mp.w	
	CLR.b	Watling_inn_broke_penalty.w	
	BRA.b	DialogState_SleepFadeAndRestore_Loop3	
DialogState_SleepFadeAndRestore_Loop:
	MOVE.w	Player_mhp.w, Player_hp.w
	MOVE.w	Player_mmp.w, Player_mp.w
DialogState_SleepFadeAndRestore_Loop3:
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_WATLING, D0
	BNE.b	InnWatling_GoodMorning
	TST.b	Watling_inn_free_stay_used.w
	BNE.b	InnWatling_GoodMorning
	TST.b	Watling_youth_restored.w
	BEQ.b	DialogState_SleepFadeAndRestore_Loop4
	PRINT 	DontPullOnMeStr
	MOVE.b	#FLAG_TRUE, Watling_inn_free_stay_used.w
	BRA.b	InnWatling_RestoreAndExit
DialogState_SleepFadeAndRestore_Loop4:
	PRINT 	MoveAlongStr
	BRA.b	InnWatling_RestoreAndExit
InnWatling_GoodMorning:
	PRINT 	BetterMorningStr
InnWatling_RestoreAndExit:
	MOVE.w	#PALETTE_IDX_TOWN_TILES, Palette_line_0_index.w
	MOVE.w	Palette_line_1_index_saved.w, Palette_line_1_index.w
	MOVE.w	Palette_line_2_cycle_base.w, Palette_line_2_index.w
	MOVE.w	#PALETTE_IDX_TOWN_HUD, Palette_line_3_index.w
	JSR	LoadPalettesFromTable
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#DIALOG_STATE_WAIT_FORTUNE_TELLER_SCRIPT_THEN_CLOSE, Dialogue_state.w
	JSR	LoadAndPlayAreaMusic
	JSR	ResetScriptAndInitDialogue
ChurchDialog_SetState_Return:
	RTS

DialogState_WaitScriptThenOpenChurchMenu:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptThenOpenChurchMenu_Loop
	JSR	SaveStatusMenuAreaToBuffer_Large
	JSR	DrawChurchMenuWindow
	MOVE.w	#SOUND_MENU_CURSOR, D0
	JSR	QueueSoundEffect
	CLR.w	Church_service_selection.w
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_WaitScriptThenOpenChurchMenu_Loop:
	JMP	ProcessScriptText
DialogState_ChurchMenuInput:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	ChurchMenu_HandleInput_Return
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	ChurchMenu_HandleInput_Return
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BEQ.b	DialogState_ChurchMenuInput_Loop
	BRA.b	DialogState_ChurchMenuInput_Loop2
DialogState_ChurchMenuInput_Loop:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.w	ChurchService_InitDialogue_Loop
	MOVE.w	Church_service_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.w	Church_service_selection.w
	BEQ.b	DialogState_ChurchMenuInput_Loop3
	CMPI.w	#1, Church_service_selection.w
	BEQ.w	DialogState_ChurchMenuInput_Loop4
	CMPI.w	#2, Church_service_selection.w
	BEQ.w	DialogState_ChurchMenuInput_Loop5
DialogState_ChurchMenuInput_Loop2:
	PRINT 	NeverGiveUpStr
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD, Dialogue_state.w
	BRA.w	ChurchService_InitDialogue
DialogState_ChurchMenuInput_Loop3:
	BSR.w	CheckIfCursed
	BEQ.b	DialogState_ChurchMenuInput_Loop6
	LEA	Text_build_buffer.w, A1
	LEA	GiveToCharityStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ChurchCurseRemovalPricesByTown, A0
	MOVE.l	(A0,D0.w), D0
	BSR.w	FormatKimsAmount
	LEA	CharityAgreeStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_DRAW_CURSE_YES_NO, Dialogue_state.w
	BRA.w	ChurchService_InitDialogue
DialogState_ChurchMenuInput_Loop6:
	PRINT 	NoCurseStr
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD, Dialogue_state.w
	BRA.b	ChurchService_InitDialogue
DialogState_ChurchMenuInput_Loop4:
	MOVE.w	Player_poisoned.w, D0
	BEQ.b	DialogState_ChurchMenuInput_Loop7
	LEA	Text_build_buffer.w, A1
	LEA	GiveToCharityStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ChurchPoisonCurePricesByTown, A0
	MOVE.l	(A0,D0.w), D0
	BSR.w	FormatKimsAmount
	LEA	CharityAgreeStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_DRAW_POISON_YES_NO, Dialogue_state.w
	BRA.b	ChurchService_InitDialogue
DialogState_ChurchMenuInput_Loop7:
	PRINT 	NotPoisonedStr
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD, Dialogue_state.w
	BRA.b	ChurchService_InitDialogue
DialogState_ChurchMenuInput_Loop5:
	PRINT 	SaveNumberStr
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_OPEN_SAVE_MENU, Dialogue_state.w
ChurchService_InitDialogue:
	JMP	ResetScriptAndInitDialogue
ChurchService_InitDialogue_Loop:
	MOVE.w	Church_service_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Church_service_selection.w
ChurchMenu_HandleInput_Return:
	RTS

DialogState_WaitScriptThenCloseChurchToHud:
	TST.b	Script_text_complete.w
	BEQ.b	ChurchExit_RestoreAndSetState_Loop
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	ChurchExit_RestoreAndSetState
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	ChurchExit_RestoreAndSetState
	RTS

ChurchExit_RestoreAndSetState:
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	MOVE.w	#WINDOW_DRAW_RIGHT_MENU, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	MOVE.w	#DIALOG_STATE_WAIT_TILE_THEN_CLOSE_TO_OVERWORLD, Dialogue_state.w
	RTS

ChurchExit_RestoreAndSetState_Loop:
	JMP	ProcessScriptText
DialogState_WaitTileThenCloseToOverworld:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.b	DialogState_WaitTileThenCloseToOverworld_Loop
	JSR	DrawStatusHudWindow
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	CLR.w	Overworld_menu_state.w
	MOVE.w	#WINDOW_DRAW_MSG_SPEED_ALT, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
DialogState_WaitTileThenCloseToOverworld_Loop:
	RTS

DialogState_WaitScriptThenDrawCurseYesNo:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptThenDrawCurseYesNo_Loop
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_WaitScriptThenDrawCurseYesNo_Loop:
	JMP	ProcessScriptText
DialogState_DrawCurseRemovalMoneyWindow:
	TST.b	Window_tilemap_draw_active.w
	BNE.b	DialogState_DrawCurseRemovalMoneyWindow_Loop
	JSR	SaveLeftMenuTiles
	JSR	DrawMoneyDisplayWindow
	JSR	DisplayPlayerKims
	ADDQ.w	#1, Dialogue_state.w
DialogState_DrawCurseRemovalMoneyWindow_Loop:
	RTS

DialogState_CurseRemovalPayAndCure:
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.w	ShopNoTakeBack_Sell
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.w	ShopNoTakeBack_Sell_Loop
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.w	Dialog_selection.w
	BNE.w	ShopNoTakeBack_Sell
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ChurchCurseRemovalPricesByTown, A0
	MOVE.l	(A0,D0.w), D0
	MOVE.l	Player_kims.w, D1
	ANDI.l	#$00FFFFFF, D1
	CMP.l	D0, D1
	BLT.b	DialogState_CurseRemovalPayAndCure_Loop
	MOVE.l	D0, Transaction_amount.w
	JSR	DeductPaymentAmount
	JSR	DisplayPlayerKims
	BSR.w	RemoveCursedEquipment
	PRINT 	CurseRemovedStr
	JSR	DrawLeftMenuWindow
	JSR	RestoreLeftMenuFromBuffer
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD, Dialogue_state.w
	RTS

DialogState_CurseRemovalPayAndCure_Loop:
	PRINT 	NoTakeBackStr	
	BRA.b	ShopNoTakeBack_Sell_Loop2	
ShopNoTakeBack_Sell:
	PRINT 	NoTakeBackStr	
ShopNoTakeBack_Sell_Loop2:
	JSR	DrawLeftMenuWindow	
	JSR	RestoreLeftMenuFromBuffer	
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD, Dialogue_state.w	
	JSR	ResetScriptAndInitDialogue	
	RTS
	
ShopNoTakeBack_Sell_Loop:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

DialogState_WaitScriptThenDrawPoisonYesNo:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptThenDrawPoisonYesNo_Loop
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_WaitScriptThenDrawPoisonYesNo_Loop:
	JMP	ProcessScriptText
DialogState_DrawPoisonCureMoneyWindow:
	JSR	SaveLeftMenuTiles
	JSR	DrawMoneyDisplayWindow
	JSR	DisplayPlayerKims
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_PoisonCurePayAndCure:
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.w	ShopNoTakeBack_Giveaway
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.w	ShopNoTakeBack_Giveaway_Loop
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.w	Dialog_selection.w
	BNE.w	ShopNoTakeBack_Giveaway
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ChurchPoisonCurePricesByTown, A0
	MOVE.l	(A0,D0.w), D0
	MOVE.l	Player_kims.w, D1
	ANDI.l	#$00FFFFFF, D1
	CMP.l	D0, D1
	BLT.w	DialogState_PoisonCurePayAndCure_Loop
	MOVE.l	D0, Transaction_amount.w
	JSR	DeductPaymentAmount
	JSR	DisplayPlayerKims
	TST.w	Player_greatly_poisoned.w
	BNE.b	DialogState_PoisonCurePayAndCure_Loop2
	CLR.w	Player_poisoned.w
	CLR.b	Poison_notified.w
	PRINT 	PoisonPurgedStr
	BRA.b	DialogState_PoisonCurePayAndCure_Loop3
DialogState_PoisonCurePayAndCure_Loop2:
	PRINT 	CantCureStr
DialogState_PoisonCurePayAndCure_Loop3:
	JSR	DrawLeftMenuWindow
	JSR	RestoreLeftMenuFromBuffer
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD, Dialogue_state.w
	RTS

DialogState_PoisonCurePayAndCure_Loop:
	PRINT 	NoTakeBackStr	
	BRA.b	ShopNoTakeBack_Giveaway_Loop2	
ShopNoTakeBack_Giveaway:
	PRINT 	NoTakeBackStr	
ShopNoTakeBack_Giveaway_Loop2:
	JSR	DrawLeftMenuWindow	
	JSR	RestoreLeftMenuFromBuffer	
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD, Dialogue_state.w	
	JMP	ResetScriptAndInitDialogue	
ShopNoTakeBack_Giveaway_Loop:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

DialogState_WaitScriptThenOpenSaveMenu:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptThenOpenSaveMenu_Loop
	JSR	SaveShopSubmenuAreaToBuffer
	JSR	DrawSavedGameOptionsMenu
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_WaitScriptThenOpenSaveMenu_Loop:
	JMP	ProcessScriptText
DialogState_SaveMenuInput:
	TST.b	Window_tilemap_draw_active.w
	BNE.b	DialogState_SaveMenuInput_Loop
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	DialogState_SaveMenuInput_Loop2
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.b	DialogState_SaveMenuInput_Loop3
	JSR	SaveGameToSram
	JSR	RestoreShopSubmenuFromBuffer
	JSR	ResetScriptAndInitDialogue
	PRINT 	GameSavedStr
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD, Dialogue_state.w
	RTS

DialogState_SaveMenuInput_Loop2:
	JSR	RestoreShopSubmenuFromBuffer	
	JSR	DrawChurchMenuWindow	
	MOVE.w	#SOUND_MENU_CURSOR, D0	
	JSR	QueueSoundEffect	
	CLR.w	Church_service_selection.w	
	MOVE.w	#DIALOG_STATE_CHURCH_MENU_INPUT, Dialogue_state.w	
	RTS
	
DialogState_SaveMenuInput_Loop3:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
DialogState_SaveMenuInput_Loop:
	RTS

;loc_0001CDFE:
CheckIfCursed:
	MOVE.w	#2, D7
	LEA	Equipped_items.w, A0
CheckIfCursed_Done:
	MOVE.w	(A0)+, D3
	BLT.b	ScanInventory_NotFound
	MOVE.w	#9, D0
	BTST.l	D0, D3
	BEQ.b	ScanInventory_NotFound
	MOVE.w	#$FFFF, D0
	BRA.b	ScanInventory_NotFound_Loop
ScanInventory_NotFound:
	DBF	D7, CheckIfCursed_Done
	CLR.w	D0
ScanInventory_NotFound_Loop:
	RTS

;loc_0001CE20:
RemoveCursedEquipment:
	MOVE.w	#2, D7
	LEA	Equipped_items.w, A0
RemoveCursedEquipment_Done:
	MOVE.w	(A0)+, D3
	MOVE.w	#9, D0
	BTST.l	D0, D3
	BEQ.b	RecalcArmorClass_NextItem
	MOVE.w	#$FFFF, -$2(A0)
	LEA	EquipmentToStatModifierMap, A4
	MOVE.w	D3, D1
	ANDI.w	#$00FF, D1
	ADD.w	D1, D1
	MOVE.w	(A4,D1.w), D1
	MOVE.w	#$000A, D0
	BTST.l	D0, D3
	BEQ.b	RemoveCursedEquipment_Loop
	SUB.w	D1, Player_str.w
	BRA.b	RecalcArmorClass_NextItem
RemoveCursedEquipment_Loop:
	SUB.w	D1, Player_ac.w	
RecalcArmorClass_NextItem:
	DBF	D7, RemoveCursedEquipment_Done
	LEA	Possessed_equipment_list.w, A0
	MOVE.w	Possessed_equipment_length.w, D7
RecalcArmorClass_NextItem_Done:
	MOVE.w	(A0)+, D3
	MOVE.w	#9, D0
	BTST.l	D0, D3
	BEQ.b	RecalcArmorClass_NextItem_Loop
	ANDI.w	#$7FFF, D3
	MOVE.w	D3, -$2(A0)
RecalcArmorClass_NextItem_Loop:
	DBF	D7, RecalcArmorClass_NextItem_Done
	RTS

CheckPlayerTalkToNPC:
	MOVE.w	Player_direction.w, D2
	BCLR.l	#0, D2
	ADD.w	D2, D2
	LEA	TalkDirectionDeltaTable, A1
	MOVE.w	Player_position_x_in_town.w, D0
	MOVE.w	Player_position_y_in_town.w, D1
	ADD.w	(A1,D2.w), D0
	ADD.w	$2(A1,D2.w), D1
	MOVEQ	#$0000001D, D7
	MOVEA.l	Enemy_list_ptr.w, A6
CheckPlayerTalkToNPC_Done:
	BTST.b	#7, (A6)
	BEQ.b	FindNpcByScript_NextEntry_Loop
	MOVE.w	obj_world_x(A6), D2
	ASR.w	#4, D2
	CMP.w	D0, D2
	BNE.b	FindNpcByScript_NextEntry
	MOVE.w	obj_world_y(A6), D2
	ASR.w	#4, D2
	CMP.w	D1, D2
	BNE.b	FindNpcByScript_NextEntry
	MOVE.w	Player_direction.w, D0
	ASR.w	#1, D0
	LEA	NpcFacingDirectionLookup, A0
	MOVE.b	(A0,D0.w), obj_npc_saved_dir(A6)
	MOVE.l	obj_npc_str_ptr(A6), Script_source_base.w
	MOVE.b	#$FF, obj_vel_x(A6)
	RTS

FindNpcByScript_NextEntry:
	CLR.w	D2
	MOVE.b	obj_next_offset(A6), D2
	LEA	(A6,D2.w), A6
	DBF	D7, CheckPlayerTalkToNPC_Done
FindNpcByScript_NextEntry_Loop:
	PRINT 	NoOneHereStr
	RTS

FormatShopItemPrice:
	LEA	ShopResaleValueMapPtrs, A0
	LEA	ShopPossessionListPtrs, A2
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	MOVEA.l	(A2,D0.w), A2
	MOVE.w	Shop_selected_index.w, D0
	ADD.w	D0, D0
	MOVE.w	(A2,D0.w), D0
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVE.l	(A0,D0.w), D0
	MOVE.l	D0, Shop_sell_price.w
	BSR.w	FormatKimsAmount
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	RTS

FormatKimsAmount:
	MOVEQ	#0, D7
	ROL.l	#8, D0
	MOVEQ	#5, D6
FormatKimsAmount_SkipLeadingZero:
	ROL.l	#4, D0
	MOVE.l	D0, D1
	ANDI.l	#$0000000F, D1
	BNE.b	FormatKimsAmount_WriteDigit
	TST.w	D7
	BNE.b	FormatKimsAmount_WriteDigit
	TST.w	D6
	BEQ.b	FormatKimsAmount_WriteDigit
	DBF	D6, FormatKimsAmount_SkipLeadingZero
	BRA.b	FormatKimsAmount_WriteDigit_Loop	
FormatKimsAmount_WriteDigit:
	ADDI.b	#$30, D1
	MOVEQ	#1, D7
	MOVE.b	D1, (A1)+
	DBF	D6, FormatKimsAmount_SkipLeadingZero
FormatKimsAmount_WriteDigit_Loop:
	MOVE.b	#$20, (A1)+
	MOVE.b	#$6B, (A1)+
	MOVE.b	#$69, (A1)+
	MOVE.b	#$6D, (A1)+
	MOVE.b	#$73, (A1)+
	RTS

NpcFacingDirectionLookup:
	dc.b	$04, $06, $00, $02 
FortuneTellerGreetingsByTown:
	dc.l	FortuneTellerGreeting_Wyclif
	dc.l	FortuneTellerGreeting_Watling
	dc.l	NpcSubRoomData_Watling	
	dc.l	FortuneTellerGreeting_Deepdale	
	dc.l	FortuneTellerGreeting_Stow
	dc.l	FortuneTellerGreeting_Keltwick	
	dc.l	FortuneTellerGreeting_Keltwick	
	dc.l	FortuneTellerGreeting_Malaga
	dc.l	FortuneTellerGreeting_Barrow	
	dc.l	FortuneTellerGreeting_Helwig
	dc.l	FortuneTellerGreeting_Swafham	
	dc.l	FortuneTellerGreeting_Excalabria	
	dc.l	FortuneTellerGreeting_ExcalabriaCastle	
	dc.l	NpcDialog_NotHungryCantHelp	
	dc.l	NpcDialog_NotHungryCantHelp	
	dc.l	NpcDialog_MotherAwaits	
FortuneTellerReadingsByTown:
	dc.l	FortuneTellerReading_Wyclif
	dc.l	FortuneTellerReading_Watling
	dc.l	NpcSubRoomData_Watling	
	dc.l	FortuneTellerGreeting_Deepdale	
	dc.l	FortuneTellerReading_Keltwick
	dc.l	FortuneTellerGreeting_Keltwick	
	dc.l	FortuneTellerGreeting_Keltwick	
	dc.l	FortuneTellerReading_Malaga
	dc.l	FortuneTellerGreeting_Barrow	
	dc.l	FortuneTellerReading_Helwig
	dc.l	FortuneTellerGreeting_Swafham
	dc.l	FortuneTellerGreeting_Excalabria
	dc.l	FortuneTellerGreeting_ExcalabriaCastle	
	dc.l	NpcDialog_FindRingsInCartahena	
	dc.l	NpcDialog_FindRingsInCartahena	
	dc.l	NpcDialog_MotherAwaits	
ReadyEquipmentStateMachine:
	MOVE.w	Ready_equipment_state.w, D0
	ANDI.w	#$001F, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ReadyEquipmentStateJumpTable, A0
	JSR	(A0,D0.w)
	RTS

ReadyEquipmentStateJumpTable:
	BRA.w	ReadyEquipmentStateJumpTable_Loop
	BRA.w	ReadyEquipmentStateJumpTable_Loop2
	BRA.w	ReadyEquipmentMenu_Done_Loop
	BRA.w	ReadyEquipmentMenu_Done_Loop2
	BRA.w	ReadyEquipmentState_ShowCategory	
	BRA.w	ReadyEquipmentState_ShowCategory
	BRA.w	ReadyEquipmentState_ShowCategory_Loop
	BRA.w	ReadyEquipmentState_ShowCategory	
ReadyEquipmentStateJumpTable_Loop:
	MOVE.w	Main_menu_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	JSR	SaveMainMenuToBuffer
	JSR	DrawEquipmentMenuWindow
	ADDQ.w	#1, Ready_equipment_state.w
	CLR.w	Ready_equipment_selection.w
	CLR.w	Menu_cursor_index.w
	RTS

ReadyEquipmentStateJumpTable_Loop2:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	ReadyEquipmentMenu_Done
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	ReadyEquipmentMenu_Done
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	ReadyEquip_ConfirmAndSetState
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	ReadyEquip_ConfirmAndSetState_Loop
	MOVE.w	Ready_equipment_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Ready_equipment_selection.w
	RTS

ReadyEquip_ConfirmAndSetState:
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	MOVE.w	#WINDOW_DRAW_STATUS_MENU, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	MOVE.w	#OVERWORLD_MENU_STATE_OPTIONS_WAIT, Overworld_menu_state.w
	JSR	InitMenuCursorDefaults
	RTS
	
ReadyEquip_ConfirmAndSetState_Loop:
	MOVE.w	Ready_equipment_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	MOVE.w	Ready_equipment_selection.w, D0
	CMPI.w	#2, D0
	BEQ.b	ReadyEquip_ConfirmAndSetState
	MOVE.w	#SOUND_MENU_SELECT, D0
	JSR	QueueSoundEffect
	CLR.w	Ready_equipment_category.w
	MOVE.w	#READY_EQUIP_STATE_OPTIONS, Ready_equipment_state.w
	JSR	SaveRightMenuToBuffer
	JSR	DrawEquipOptionsMenuWindow
	MOVE.w	Ready_equipment_selection.w, D0
	BEQ.b	ReadyEquipmentMenu_Done
	MOVE.w	#READY_EQUIP_STATE_SHOW_LIST_B, Ready_equipment_state.w
ReadyEquipmentMenu_Done:
	RTS

ReadyEquipmentMenu_Done_Loop:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	ReadyEquipmentMenu_Done_Loop3
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	ReadyEquipmentMenu_Done_Loop4
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	ReadyEquipmentMenu_Done_Loop5
	MOVE.w	Ready_equipment_category.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Ready_equipment_category.w
	RTS

ReadyEquipmentMenu_Done_Loop4:
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	JSR	RestoreRightMenuFromBuffer
	JSR	DrawEquipmentMenuWindow
	MOVE.w	#READY_EQUIP_STATE_WAIT, Ready_equipment_state.w
	RTS

ReadyEquipmentMenu_Done_Loop5:
	MOVE.w	Ready_equipment_category.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	MOVE.w	#SOUND_MENU_SELECT, D0
	JSR	QueueSoundEffect
	BSR.w	BuildEquipmentListForCategory
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	TST.w	Ready_equipment_list_length.w
	BLE.b	ReadyEquipmentMenu_Done_Loop6
	JSR	SaveReadyEquipmentMenuToBuffer
	JSR	DrawReadyEquipmentMenuBorders
	JSR	DrawReadyEquipmentList
	PRINT 	ReadyPromptStr
	MOVE.w	#READY_EQUIP_STATE_LIST_WAIT, Ready_equipment_state.w
	CLR.w	Ready_equipment_cursor_index.w
	RTS

ReadyEquipmentMenu_Done_Loop6:
	PRINT 	ProperEquipmentStr
	MOVE.w	#READY_EQUIP_STATE_RESULT_MSG, Ready_equipment_state.w
ReadyEquipmentMenu_Done_Loop3:
	RTS

ReadyEquipmentMenu_Done_Loop2:
	TST.b	Script_text_complete.w
	BEQ.w	ReadyEquip_CursedReturn_Loop
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	ReadyEquipmentMenu_Done_Loop7
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	ReadyEquipmentMenu_Done_Loop8
	MOVE.w	Ready_equipment_cursor_index.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Ready_equipment_cursor_index.w
	RTS

ReadyEquipmentMenu_Done_Loop7:
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	JSR	RestoreReadyEquipmentMenuFromBuffer
	JSR	DrawStatusHudWindow
	JSR	RestoreRightMenuFromBuffer
	JSR	DrawEquipmentMenuWindow
	MOVE.w	#READY_EQUIP_STATE_WAIT, Ready_equipment_state.w
	RTS

ReadyEquipmentMenu_Done_Loop8:
	MOVE.w	Ready_equipment_cursor_index.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	MOVE.w	#SOUND_MENU_SELECT, D0
	JSR	QueueSoundEffect
	JSR	ResetScriptAndInitDialogue
	BSR.w	GetCurrentEquippedItemID
	TST.w	D0
	BGE.w	ReadyEquipmentMenu_Done_Loop9
	BSR.w	EquipSelectedItem
	BSR.w	CopyPlayerNameToTextBuffer
	BSR.w	GetSelectedEquipmentID
	MOVE.w	#9, D2
	BTST.l	D2, D1
	BNE.w	ReadyEquipmentMenu_Done_Loop10
	MOVE.w	D1, D2
	MOVE.w	Ready_equipment_category.w, D0
	ANDI.w	#3, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	EquipStatAddJumpTable, A0
	JSR	(A0,D0.w)
	LEA	ReadiedStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	BSR.w	CopyEquipmentNameToTextBuffer
	MOVE.b	#$2E, (A1)+
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
	MOVE.w	#READY_EQUIP_STATE_RESULT_MSG, Ready_equipment_state.w
	JSR	RestoreReadyEquipmentMenuFromBuffer
	RTS

ReadyEquipmentMenu_Done_Loop9:
	PRINT 	AlreadyReadiedStr
	BSR.w	GetSelectedEquipmentID
	CMP.b	D0, D1
	BEQ.w	ReadyEquipmentMenu_Done_Loop11
	MOVE.w	#9, D2
	BTST.l	D2, D0
	BNE.w	ReadyEquipmentMenu_Done_Loop12
	BSR.w	ClearEquipmentCursedFlag
	BSR.w	CopyPlayerNameToTextBuffer
	BSR.w	GetCurrentEquippedItemID
	MOVE.w	D0, D2
	MOVE.w	D0, D6
	MOVE.w	Ready_equipment_category.w, D0
	ANDI.w	#3, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	EquipStatRemoveJumpTable, A0
	JSR	(A0,D0.w)
	MOVE.w	Ready_equipment_category.w, D0
	ANDI.w	#3, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	EquipStatAddJumpTable, A0
	JSR	(A0,D0.w)
	LEA	RemovedStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	BSR.w	CopyEquipmentNameToTextBuffer
	MOVE.b	#$20, (A1)+
	MOVE.b	#$61, (A1)+
	MOVE.b	#$6E, (A1)+
	MOVE.b	#$64, (A1)+
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	BSR.w	GetSelectedEquipmentID
	MOVE.w	D1, D2
	LEA	ReadiedStr, A0
	JSR	CopyStringUntilFF
	BSR.w	CopyEquipmentNameToTextBuffer
	MOVE.b	#$2E, (A1)+
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
ReadyEquipmentMenu_Done_Loop11:
	BSR.w	EquipSelectedItem
	BRA.b	ReadyEquip_CursedReturn
ReadyEquipmentMenu_Done_Loop12:
	PRINT 	ExchangeCursedStr
	BRA.b	ReadyEquip_CursedReturn
ReadyEquipmentMenu_Done_Loop10:
	PRINT 	CursedStr
ReadyEquip_CursedReturn:
	MOVE.w	#READY_EQUIP_STATE_RESULT_MSG, Ready_equipment_state.w
	JSR	RestoreReadyEquipmentMenuFromBuffer
	RTS

ReadyEquip_CursedReturn_Loop:
	JSR	ProcessScriptText
	RTS

ReadyEquipmentState_ShowCategory:
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	ReadyEquipmentState_ShowCategory_Loop2
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	ReadyEquipmentState_ShowCategory_Loop3
	MOVE.w	Ready_equipment_category.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Ready_equipment_category.w
	RTS

ReadyEquipmentState_ShowCategory_Loop2:
	MOVE.w	#SOUND_MENU_CANCEL, D0	
	JSR	QueueSoundEffect	
	JSR	RestoreRightMenuFromBuffer	
	JSR	DrawEquipmentMenuWindow	
	MOVE.w	#READY_EQUIP_STATE_WAIT, Ready_equipment_state.w	
	RTS
	
ReadyEquipmentState_ShowCategory_Loop3:
	MOVE.w	Ready_equipment_category.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	MOVE.w	#SOUND_MENU_SELECT, D0
	JSR	QueueSoundEffect
	BSR.w	BuildEquipmentListForCategory
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	BSR.w	GetCurrentEquippedItemID
	TST.w	D0
	BLT.w	ReadyEquipmentState_ShowCategory_Loop4
	MOVE.w	#9, D1
	BTST.l	D1, D0
	BNE.w	ReadyEquipmentState_ShowCategory_Loop5
	MOVE.w	D0, D6
	BSR.w	UnequipItemByID
	MOVE.w	Ready_equipment_category.w, D0
	ANDI.w	#3, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	EquipStatRemoveJumpTable, A0
	JSR	(A0,D0.w)
	BSR.w	CopyPlayerNameToTextBuffer
	BSR.w	GetCurrentEquippedItemID
	MOVE.w	D0, D2
	LEA	RemovedStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	BSR.w	CopyEquipmentNameToTextBuffer
	MOVE.b	#$2E, (A1)+
	MOVE.b	#$FF, (A1)
	MOVE.w	Ready_equipment_category.w, D0
	ADD.w	D0, D0
	LEA	Equipped_sword.w, A2
	MOVE.w	#$FFFF, (A2,D0.w)
	PRINT 	Text_build_buffer
	MOVE.w	#READY_EQUIP_STATE_RESULT_MSG, Ready_equipment_state.w
	RTS

ReadyEquipmentState_ShowCategory_Loop4:
	PRINT 	NothingToUseStr
	MOVE.w	#READY_EQUIP_STATE_RESULT_MSG, Ready_equipment_state.w
	RTS

ReadyEquipmentState_ShowCategory_Loop5:
	PRINT 	DropCursedStr	
	MOVE.w	#READY_EQUIP_STATE_RESULT_MSG, Ready_equipment_state.w	
	RTS
	
ReadyEquipmentState_ShowCategory_Loop:
	TST.b	Script_text_complete.w
	BEQ.b	ReadyEquip_ExitToHud_Loop
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	ReadyEquip_ExitToHud
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	ReadyEquip_ExitToHud
	RTS

ReadyEquip_ExitToHud:
	JSR	DrawStatusHudWindow
	JSR	RestoreRightMenuFromBuffer
	JSR	DrawEquipmentMenuWindow
	MOVE.w	#READY_EQUIP_STATE_WAIT, Ready_equipment_state.w
	RTS

ReadyEquip_ExitToHud_Loop:
	JSR	ProcessScriptText
	RTS

EquipStatAddJumpTable:
	BRA.w	EquipStatAddJumpTable_Loop
	BRA.w	EquipStatAddJumpTable_Loop2
	BRA.w	EquipItem_AddAcBonus
	BRA.w	EquipItem_AddAcBonus	
EquipStatAddJumpTable_Loop:
	LEA	EquipmentToStatModifierMap, A0
	ANDI.w	#$00FF, D1
	ADD.w	D1, D1
	MOVE.w	Player_str.w, D0
	ADD.w	(A0,D1.w), D0
	ANDI.w	#$7FFF, D0
	MOVE.w	D0, Player_str.w
	RTS

EquipStatAddJumpTable_Loop2:
	LEA	EquipmentToStatModifierMap, A0
	ANDI.w	#$00FF, D1
	ADD.w	D1, D1
	MOVE.w	Player_ac.w, D0
	ADD.w	(A0,D1.w), D0
	ANDI.w	#$7FFF, D0
	MOVE.w	D0, Player_ac.w
	RTS

EquipItem_AddAcBonus:
	LEA	EquipmentToStatModifierMap, A0
	ANDI.w	#$00FF, D1
	ADD.w	D1, D1
	MOVE.w	Player_ac.w, D0
	ADD.w	(A0,D1.w), D0
	ANDI.w	#$7FFF, D0
	MOVE.w	D0, Player_ac.w
	RTS

EquipStatRemoveJumpTable:
	BRA.w	EquipStatRemoveJumpTable_Loop
	BRA.w	EquipStatRemoveJumpTable_Loop2
	BRA.w	UnequipItem_SubAcBonus
	BRA.w	UnequipItem_SubAcBonus	
EquipStatRemoveJumpTable_Loop:
	LEA	EquipmentToStatModifierMap, A0
	ANDI.w	#$00FF, D6
	ADD.w	D6, D6
	MOVE.w	Player_str.w, D0
	SUB.w	(A0,D6.w), D0
	ANDI.w	#$7FFF, D0
	MOVE.w	D0, Player_str.w
	RTS

EquipStatRemoveJumpTable_Loop2:
	LEA	EquipmentToStatModifierMap, A0
	ANDI.w	#$00FF, D6
	ADD.w	D6, D6
	MOVE.w	Player_ac.w, D0
	SUB.w	(A0,D6.w), D0
	ANDI.w	#$7FFF, D0
	MOVE.w	D0, Player_ac.w
	RTS

UnequipItem_SubAcBonus:
	LEA	EquipmentToStatModifierMap, A0
	ANDI.w	#$00FF, D6
	ADD.w	D6, D6
	MOVE.w	Player_ac.w, D0
	SUB.w	(A0,D6.w), D0
	ANDI.w	#$7FFF, D0
	MOVE.w	D0, Player_ac.w
	RTS

UnequipItemByID:
	LEA	Possessed_equipment_length.w, A1
	MOVE.w	(A1)+, D7
	SUBQ.w	#1, D7
UnequipItemByID_Done:
	MOVE.w	(A1)+, D1
	CMP.b	D0, D1
	BNE.b	FindEquipSlot_Done
	ANDI.w	#$8000, D1
	BEQ.b	FindEquipSlot_Done
	MOVE.w	D0, -$2(A1)
	BRA.b	FindEquipSlot_Done_Loop
FindEquipSlot_Done:
	DBF	D7, UnequipItemByID_Done
FindEquipSlot_Done_Loop:
	RTS

BuildEquipmentListForCategory:
	MOVE.w	Ready_equipment_category.w, D0
	ADDI.w	#$000A, D0
	CLR.w	D2
	LEA	Ready_equipment_list.w, A2
	LEA	Possessed_equipment_length.w, A1
	MOVE.w	(A1)+, D7
	BLE.b	BuildEquipmentListForCategory_Loop
	SUBQ.w	#1, D7
BuildEquipmentListForCategory_Done:
	MOVE.w	(A1)+, D1
	BTST.l	D0, D1
	BEQ.b	BuildEquipmentListForCategory_Loop2
	MOVE.w	D1, (A2)+
	ADDQ.w	#1, D2
BuildEquipmentListForCategory_Loop2:
	DBF	D7, BuildEquipmentListForCategory_Done
BuildEquipmentListForCategory_Loop:
	MOVE.w	D2, Ready_equipment_list_length.w
	RTS

GetCurrentEquippedItemID:
	MOVE.w	Ready_equipment_category.w, D0
	ADD.w	D0, D0
	LEA	Equipped_items.w, A2
	MOVE.w	(A2,D0.w), D0
	RTS

GetSelectedEquipmentID:
	MOVE.w	Ready_equipment_cursor_index.w, D1
	ADD.w	D1, D1
	LEA	Ready_equipment_list.w, A2
	MOVE.w	(A2,D1.w), D1
	ANDI.w	#$7FFF, D1
	RTS

EquipSelectedItem:
	BSR.b	GetSelectedEquipmentID
	MOVE.w	Ready_equipment_category.w, D2
	ADD.w	D2, D2
	LEA	Equipped_items.w, A2
	MOVE.w	D1, (A2,D2.w)
	LEA	Possessed_equipment_list.w, A2
	MOVE.w	Possessed_equipment_length.w, D7
EquipSelectedItem_Done:
	MOVE.w	(A2)+, D3
	CMP.b	D3, D1
	BNE.b	EquipSelectedItem_Loop
	ORI.w	#$8000, D3
	MOVE.w	D3, -$2(A2)
	BRA.b	EquipSelectedItem_Loop2
EquipSelectedItem_Loop:
	DBF	D7, EquipSelectedItem_Done
EquipSelectedItem_Loop2:
	RTS

ClearEquipmentCursedFlag:
	LEA	Possessed_equipment_list.w, A0
	MOVE.w	Possessed_equipment_length.w, D7
ClearEquipmentCursedFlag_Done:
	MOVE.w	(A0)+, D3
	MOVE.w	D3, D4
	CMP.b	D3, D0
	BNE.b	FindUnequipSlot_Done
	ANDI.w	#$8000, D4
	BEQ.b	FindUnequipSlot_Done
	ANDI.w	#$7FFF, D3
	MOVE.w	D3, -$2(A0)
	BRA.b	FindUnequipSlot_Done_Loop
FindUnequipSlot_Done:
	DBF	D7, ClearEquipmentCursedFlag_Done
FindUnequipSlot_Done_Loop:
	RTS

CopyPlayerNameToTextBuffer:
	LEA	Player_name.w, A0
	LEA	Text_build_buffer.w, A1
	JSR	CopyStringUntilFF
	MOVE.b	#$20, (A1)+
	RTS

CopyEquipmentNameToTextBuffer:
	LEA	EquipmentNames, A2
	ANDI.w	#$00FF, D2
	ADD.w	D2, D2
	ADD.w	D2, D2
	MOVEA.l	(A2,D2.w), A0
	JSR	CopyStringUntilFF
	RTS

EquipListMenuStateMachine:
	MOVE.w	Equip_list_menu_state.w, D0
	ANDI.w	#$000F, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	EquipListMenuStateJumpTable, A0
	JSR	(A0,D0.w)
	RTS

EquipListMenuStateJumpTable:
	BRA.w	EquipListMenuStateJumpTable_Loop
	BRA.w	EquipListMenuStateJumpTable_Loop2
	BRA.w	EquipListMenu_DrawGear_Return_Loop
	BRA.w	EquipListMenu_DrawCombat_Return_Loop
	BRA.w	EquipListMenu_DrawMagic_Return_Loop
	BRA.w	EquipListMenu_DrawItems_Return_Loop
	BRA.w	EquipListMenu_DrawRings_Return_Loop
	BRA.w	EquipListMenu_DrawStatus_Return_Loop	
	BRA.w	EquipListMenu_DrawWindow_Return_Loop
	BRA.w	EquipListMenu_CursorReady_Return_Loop
	BRA.w	EquipListMenu_CursorReady_Return_Loop2
	BRA.w	EquipListMenu_CursorReady_Return_Loop3
	BRA.w	EquipListMenu_CursorReady_Return_Loop4
	BRA.w	EquipListMenu_CursorReady_Return_Loop5
EquipListMenuStateJumpTable_Loop:
	MOVE.w	Main_menu_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	MOVE.w	#SOUND_MENU_CURSOR, D0
	JSR	QueueSoundEffect
	JSR	SaveFullDialogAreaToBuffer
	JSR	DrawCharacterStatsWindow
	ADDQ.w	#1, Equip_list_menu_state.w
	RTS

EquipListMenuStateJumpTable_Loop2:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	EquipListMenu_DrawGear_Return
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_DrawGear_Return
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.w	EquipListMenuStateJumpTable_Loop3
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.w	EquipListMenuStateJumpTable_Loop4
	RTS

EquipListMenuStateJumpTable_Loop4:
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	MOVE.w	#EQUIP_LIST_STATE_EXIT_SCRIPT, Equip_list_menu_state.w
	MOVE.w	#WINDOW_DRAW_SCRIPT, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	RTS

EquipListMenuStateJumpTable_Loop3:
	MOVE.w	#SOUND_MENU_CURSOR, D0
	JSR	QueueSoundEffect
	JSR	SaveFullMenuTiles
	JSR	DrawEquippedGearWindow
	ADDQ.w	#1, Equip_list_menu_state.w
EquipListMenu_DrawGear_Return:
	RTS

EquipListMenu_DrawGear_Return_Loop:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	EquipListMenu_DrawCombat_Return
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_DrawCombat_Return
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.w	EquipListMenu_DrawGear_Return_Loop2
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.w	EquipListMenu_DrawGear_Return_Loop3
	RTS

EquipListMenu_DrawGear_Return_Loop3:
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	MOVE.w	#WINDOW_DRAW_FULL_MENU, Window_draw_type.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	CLR.w	Window_text_row.w
	MOVE.w	#EQUIP_LIST_STATE_STATS_WAIT, Equip_list_menu_state.w
	RTS

EquipListMenu_DrawGear_Return_Loop2:
	MOVE.w	#SOUND_MENU_CURSOR, D0
	JSR	QueueSoundEffect
	JSR	SaveEquipmentListTiles
	JSR	DrawGearCombatWindow
	ADDQ.w	#1, Equip_list_menu_state.w
EquipListMenu_DrawCombat_Return:
	RTS

EquipListMenu_DrawCombat_Return_Loop:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	EquipListMenu_DrawMagic_Return
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_DrawMagic_Return
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.w	EquipListMenu_DrawCombat_Return_Loop2
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.w	EquipListMenu_DrawCombat_Return_Loop3
	RTS

EquipListMenu_DrawCombat_Return_Loop3:
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	MOVE.w	#WINDOW_DRAW_EQUIP_LIST, Window_draw_type.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	CLR.w	Window_text_row.w
	MOVE.w	#EQUIP_LIST_STATE_GEAR_PAGE, Equip_list_menu_state.w
	RTS

EquipListMenu_DrawCombat_Return_Loop2:
	MOVE.w	#SOUND_MENU_CURSOR, D0
	JSR	QueueSoundEffect
	JSR	SaveMagicListTiles
	JSR	DrawMagicListWindow
	ADDQ.w	#1, Equip_list_menu_state.w
EquipListMenu_DrawMagic_Return:
	RTS

EquipListMenu_DrawMagic_Return_Loop:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	EquipListMenu_DrawItems_Return
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_DrawItems_Return
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.w	EquipListMenu_DrawMagic_Return_Loop2
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.w	EquipListMenu_DrawMagic_Return_Loop3
	RTS

EquipListMenu_DrawMagic_Return_Loop3:
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	MOVE.w	#WINDOW_DRAW_MAGIC_LIST, Window_draw_type.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	CLR.w	Window_text_row.w
	MOVE.w	#EQUIP_LIST_STATE_COMBAT_PAGE, Equip_list_menu_state.w
	RTS

EquipListMenu_DrawMagic_Return_Loop2:
	MOVE.w	#SOUND_MENU_CURSOR, D0
	JSR	QueueSoundEffect
	JSR	SaveItemListRightTiles
	JSR	DrawItemsListWindow
	ADDQ.w	#1, Equip_list_menu_state.w
EquipListMenu_DrawItems_Return:
	RTS

EquipListMenu_DrawItems_Return_Loop:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	EquipListMenu_DrawRings_Return
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_DrawRings_Return
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.w	EquipListMenu_DrawItems_Return_Loop2
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.w	EquipListMenu_DrawItems_Return_Loop3
	RTS

EquipListMenu_DrawItems_Return_Loop3:
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	MOVE.w	#WINDOW_DRAW_ITEM_RIGHT, Window_draw_type.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	CLR.w	Window_text_row.w
	MOVE.w	#EQUIP_LIST_STATE_MAGIC_PAGE, Equip_list_menu_state.w
	RTS

EquipListMenu_DrawItems_Return_Loop2:
	MOVE.w	#SOUND_MENU_CURSOR, D0
	JSR	QueueSoundEffect
	JSR	SaveRingsListMenuToBuffer
	JSR	DrawRingsListWindow
	ADDQ.w	#1, Equip_list_menu_state.w
EquipListMenu_DrawRings_Return:
	RTS

EquipListMenu_DrawRings_Return_Loop:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	EquipListMenu_DrawStatus_Return
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_DrawStatus_Return
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.w	EquipListMenu_DrawRings_Return_Loop2
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.w	EquipListMenu_DrawRings_Return_Loop3
	RTS

EquipListMenu_DrawRings_Return_Loop2:
	MOVE.w	#EQUIP_LIST_STATE_CURSOR_INIT, Equip_list_menu_state.w
	BRA.w	EquipListMenu_DrawRings_Return_Loop4
EquipListMenu_DrawRings_Return_Loop3:
	MOVE.w	#EQUIP_LIST_STATE_ITEMS_PAGE, Equip_list_menu_state.w
EquipListMenu_DrawRings_Return_Loop4:
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	MOVE.w	#WINDOW_DRAW_RING_LIST, Window_draw_type.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	CLR.w	Window_text_row.w
EquipListMenu_DrawStatus_Return:
	RTS

EquipListMenu_DrawStatus_Return_Loop:
	TST.b	Window_tilemap_draw_active.w	
	BNE.w	EquipListMenu_DrawWindow_Return	
	TST.b	Window_tilemap_row_draw_pending.w	
	BNE.w	EquipListMenu_DrawWindow_Return	
	MOVE.w	#SOUND_MENU_CANCEL, D0	
	JSR	QueueSoundEffect	
	MOVE.w	#EQUIP_LIST_STATE_EXIT_SCRIPT, Equip_list_menu_state.w	
	MOVE.w	#WINDOW_DRAW_SCRIPT, Window_draw_type.w	
	CLR.w	Window_text_row.w	
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w	
EquipListMenu_DrawWindow_Return:
	RTS
	
EquipListMenu_DrawWindow_Return_Loop:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	EquipListMenu_CursorReady_Return
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_CursorReady_Return
	MOVE.w	#OVERWORLD_MENU_STATE_OPTIONS_WAIT, Overworld_menu_state.w
	JSR	InitMenuCursorDefaults
EquipListMenu_CursorReady_Return:
	RTS

EquipListMenu_CursorReady_Return_Loop:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_CursorReady_Return_Loop6
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	MOVE.w	#WINDOW_DRAW_ITEM_RIGHT, Window_draw_type.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	CLR.w	Window_text_row.w
	MOVE.w	#EQUIP_LIST_STATE_CURSOR_ITEM, Equip_list_menu_state.w
EquipListMenu_CursorReady_Return_Loop6:
	RTS

EquipListMenu_CursorReady_Return_Loop2:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_CursorReady_Return_Loop7
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	MOVE.w	#WINDOW_DRAW_MAGIC_LIST, Window_draw_type.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	CLR.w	Window_text_row.w
	MOVE.w	#EQUIP_LIST_STATE_CURSOR_MAGIC, Equip_list_menu_state.w
EquipListMenu_CursorReady_Return_Loop7:
	RTS
EquipListMenu_CursorReady_Return_Loop3:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_CursorReady_Return_Loop8
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	MOVE.w	#WINDOW_DRAW_EQUIP_LIST, Window_draw_type.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	CLR.w	Window_text_row.w
	MOVE.w	#EQUIP_LIST_STATE_CURSOR_EQUIP, Equip_list_menu_state.w
EquipListMenu_CursorReady_Return_Loop8:
	RTS
EquipListMenu_CursorReady_Return_Loop4:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_CursorReady_Return_Loop9
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	MOVE.w	#WINDOW_DRAW_FULL_MENU, Window_draw_type.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	CLR.w	Window_text_row.w
	MOVE.w	#EQUIP_LIST_STATE_CURSOR_FULL, Equip_list_menu_state.w
EquipListMenu_CursorReady_Return_Loop9:
	RTS
EquipListMenu_CursorReady_Return_Loop5:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_CursorReady_Return_Loop10
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	MOVE.w	#EQUIP_LIST_STATE_EXIT_SCRIPT, Equip_list_menu_state.w
	MOVE.w	#WINDOW_DRAW_SCRIPT, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
EquipListMenu_CursorReady_Return_Loop10:
	RTS

;loc_0001DA8E:
UpgradeLevelStats:
	MOVE.w	Player_level.w, D7
	ADD.w	D7, D7
	LEA	PlayerLevelToStrMap, A0
	MOVE.w	(A0,D7.w), D1
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	ADD.w	D0, D1
	ADD.w	D1, Player_str.w
	CMPI.w	#MAX_PLAYER_STR, Player_str.w
	BLE.b	UpgradeLevelStats_Loop
	MOVE.w	#MAX_PLAYER_STR, Player_str.w	
UpgradeLevelStats_Loop:
	LEA	PlayerLevelToLukMap, A0
	MOVE.w	(A0,D7.w), D1
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	ADD.w	D0, D1
	ADD.w	D1, Player_luk.w
	CMPI.w	#MAX_PLAYER_LUK, Player_luk.w
	BLE.b	UpgradeLevelStats_Loop2
	MOVE.w	#MAX_PLAYER_LUK, Player_luk.w	
UpgradeLevelStats_Loop2:
	LEA	PlayerLevelToDexMap, A0
	MOVE.w	(A0,D7.w), D1
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	ADD.w	D0, D1
	ADD.w	D1, Player_dex.w
	CMPI.w	#MAX_PLAYER_DEX, Player_dex.w
	BLE.b	UpgradeLevelStats_Loop3
	MOVE.w	#MAX_PLAYER_DEX, Player_dex.w	
UpgradeLevelStats_Loop3:
	LEA	PlayerLevelToAcMap, A0
	MOVE.w	(A0,D7.w), D1
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	ADD.w	D0, D1
	ADD.w	D1, Player_ac.w
	CMPI.w	#MAX_PLAYER_AC, Player_ac.w
	BLE.b	UpgradeLevelStats_Loop4
	MOVE.w	#MAX_PLAYER_AC, Player_ac.w	
UpgradeLevelStats_Loop4:
	LEA	PlayerLevelToIntMap, A0
	MOVE.w	(A0,D7.w), D1
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	ADD.w	D0, D1
	ADD.w	D1, Player_int.w
	CMPI.w	#MAX_PLAYER_INT, Player_int.w
	BLE.b	UpgradeLevelStats_Loop5
	MOVE.w	#MAX_PLAYER_INT, Player_int.w	
UpgradeLevelStats_Loop5:
	LEA	PlayerLevelToMmpMap, A0
	MOVE.w	(A0,D7.w), D1
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	ADD.w	D0, D1
	ADD.w	D1, Player_mmp.w
	CMPI.w	#MAX_PLAYER_MMP, Player_mmp.w
	BLE.b	UpgradeLevelStats_Loop6
	MOVE.w	#MAX_PLAYER_MMP, Player_mmp.w
UpgradeLevelStats_Loop6:
	MOVE.w	Player_mmp.w, Player_mp.w
	LEA	PlayerLevelToMhpMap, A0
	MOVE.w	(A0,D7.w), D1
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	ADD.w	D0, D1
	ADD.w	D1, Player_mhp.w
	CMPI.w	#MAX_PLAYER_MHP, Player_mhp.w
	BLE.b	UpgradeLevelStats_Loop7
	MOVE.w	#MAX_PLAYER_MHP, Player_mhp.w	
UpgradeLevelStats_Loop7:
	MOVE.w	Player_mhp.w, Player_hp.w
	ADD.w	D7, D7
	LEA	PlayerLevelToNextLevelExperienceMap, A0
	MOVE.l	(A0,D7.w), Player_next_level_experience.w
	RTS

; ============================================================================
; Chest/Door Opening State Machine
; ============================================================================
; Handles player interaction with treasure chests and doors via Open command.
; Uses a multi-state system to manage detection, animation, and rewards.
;
; States: 0=Detect, 1=Message wait, 2=Close window, 3=Animation,
;         4=Tile delay, 5=Open delay, 6=Display contents
; ============================================================================
ChestOpeningStateMachine:
	TST.b	Player_in_first_person_mode.w
	BNE.w	ChestOpeningStateMachine_Loop
ChestOpeningStateMachine_Loop:
	MOVE.w	Open_menu_state.w, D0        ; Get current state
	ANDI.w	#$000F, D0
	ADD.w	D0, D0                       ; D0 *= 4
	ADD.w	D0, D0
	LEA	ChestOpenStateJumpTable, A0             ; State jump table
	JSR	(A0,D0.w)                    ; Call state handler
	RTS

	; State handler jump table
ChestOpenStateJumpTable:
	BRA.w	ChestOpenStateJumpTable_Loop            ; State 0: Detect
	BRA.w	OpenMenu_ShowMessage_Init_Loop            ; State 1: Message wait
	BRA.w	OpenChestMenu_ExitToHud_Loop            ; State 2: Close
	BRA.w	OpenChestMenu_ExitToHud_Loop2            ; State 3: Animation
	BRA.w	ChestAnimation_Return_Loop            ; State 4: Tile delay
	BRA.w	ChestAnimation_Return_Loop2            ; State 5: Open delay
	BRA.w	ChestAnimation_Return_Loop3            ; State 6: Contents
	
; State 0: Initial detection
ChestOpenStateJumpTable_Loop:
	MOVE.w	Main_menu_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.b	Player_in_first_person_mode.w
	BNE.w	ChestOpenStateJumpTable_Loop2             ; First-person: check sprite
	
	; Top-down: Check tile type
	JSR	GetTileInFrontOfPlayer             ; Get tile in front of player
	CMPI.w	#TOWN_TILE_CHEST, D0               ; Chest tile?
	BEQ.w	ChestOpenStateJumpTable_Loop3             ; Yes: play sound, advance
	BRA.w	OpenChestMenu_CheckChest             ; No: check chest sprite
	
	; First-person: Check chest sprite
ChestOpenStateJumpTable_Loop2:
	TST.b	Chest_already_opened.w       ; Already opened?
	BNE.w	OpenChestMenu_CheckChest_Loop             ; Yes: "Already open"
	LEA	FpDirectionDeltaForward, A0
	JSR	GetMapTileInDirection             ; Search for object
	CMPI.b	#6, D0                   ; Type 6 = chest sprite?
	BNE.w	OpenChestMenu_CheckChest
	BSR.w	CheckIfDoorIsLocked             ; Check if locked
	TST.b	Door_unlocked_flag.w
	BEQ.w	OpenChestMenu_CheckChest_Loop2             ; Locked
	
	; Start opening animation
	CLR.w	Chest_animation_frame.w
	CLR.w	Chest_animation_timer.w
	MOVE.w	#SOUND_CHEST_RATTLE, D0               ; Sound effect
	JSR	QueueSoundEffect
	MOVE.w	#OPEN_MENU_STATE_ANIMATION, Open_menu_state.w    ; State 3: Animation
	MOVE.w	#WINDOW_DRAW_MSG_SPEED_ALT, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	RTS
	
ChestOpenStateJumpTable_Loop3:
	MOVE.b	#SOUND_CHEST_OPEN, D0	
	JSR	QueueSoundEffect	
	MOVE.b	#CHEST_OPEN_DELAY_FRAMES, Open_chest_delay_timer.w	
	MOVE.w	#OPEN_MENU_STATE_TILE_DELAY, Open_menu_state.w	
	RTS
	
OpenChestMenu_CheckChest:
	TST.b	Reward_script_active.w              ; Chest present?
	BEQ.w	OpenChestMenu_CheckChest_Loop3             ; No
	TST.b	Chest_opened_flag.w      ; Already opened?
	BNE.w	OpenChestMenu_CheckChest_Loop4             ; Yes
	
	; Open the chest
	MOVE.b	#SOUND_CHEST_CREAK, D0
	JSR	QueueSoundEffect             ; Sound effect
	MOVE.b	#FLAG_TRUE, Chest_opened_flag.w
	MOVEA.l	Current_actor_ptr.w, A6          ; Chest sprite
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	ADDQ.w	#8, obj_tile_index(A6)               ; Adjust sprite Y
	MOVE.b	#CHEST_OPEN_DELAY_FRAMES, Open_chest_delay_timer.w
	MOVE.w	#OPEN_MENU_STATE_OPEN_DELAY, Open_menu_state.w    ; State 5
	RTS

OpenChestMenu_CheckChest_Loop2:
	PRINT 	LockedStr
	BRA.w	OpenMenu_ShowMessage_Init
OpenChestMenu_CheckChest_Loop4:
	PRINT 	AlreadyOpenedStr
	BRA.w	OpenMenu_ShowMessage_Init
OpenChestMenu_CheckChest_Loop3:
	PRINT 	NothingToOpenStr
	BRA.w	OpenMenu_ShowMessage_Init
OpenChestMenu_CheckChest_Loop:
	PRINT 	AlreadyOpenStr	
OpenMenu_ShowMessage_Init:
	JSR	SaveStatusBarToBuffer             ; Display message
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#OPEN_MENU_STATE_MSG_WAIT, Open_menu_state.w    ; State 1
	RTS
	
OpenMenu_ShowMessage_Init_Loop:
	TST.b	Script_text_complete.w
	BEQ.w	OpenChestMenu_ExitToHud_Loop3
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.w	OpenChestMenu_ExitToHud
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.w	OpenChestMenu_ExitToHud
	RTS
	
OpenChestMenu_ExitToHud:
	JSR	DrawStatusHudWindow
	MOVE.w	#OPEN_MENU_STATE_CLOSE, Open_menu_state.w
	RTS
	
OpenChestMenu_ExitToHud_Loop3:
	JSR	ProcessScriptText
	RTS
	
OpenChestMenu_ExitToHud_Loop:
	CLR.w	Overworld_menu_state.w
	MOVE.w	#WINDOW_DRAW_MSG_SPEED_ALT, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	RTS
	
OpenChestMenu_ExitToHud_Loop2:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	ChestAnimation_Return
	ADDQ.w	#1, Chest_animation_timer.w
	MOVE.w	Chest_animation_timer.w, D0
	ANDI.w	#$000F, D0
	BNE.w	ChestAnimation_Return
	CMPI.w	#4, Chest_animation_frame.w
	BGE.w	ChestAnimation_Return_Loop4
	LEA	OpenChestMenu_ExitToHud_Loop2_Data, A0
	MOVE.w	Chest_animation_frame.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	BSR.w	WriteChestAnimationToVRAM
	ADDQ.w	#1, Chest_animation_frame.w
ChestAnimation_Return:
	RTS
	
ChestAnimation_Return_Loop4:
	MOVE.b	#FLAG_TRUE, Chest_already_opened.w
	CLR.w	Overworld_menu_state.w
	RTS
	
ChestAnimation_Return_Loop:
	SUBQ.b	#1, Open_chest_delay_timer.w	
	BNE.w	ChestAnimation_Return_Loop5	
	PRINT 	CantOpenStr	
	JSR	SaveStatusBarToBuffer	
	JSR	ResetScriptAndInitDialogue	
	MOVE.w	#OPEN_MENU_STATE_MSG_WAIT, Open_menu_state.w	
ChestAnimation_Return_Loop5:
	RTS
	
ChestAnimation_Return_Loop2:
	SUBQ.b	#1, Open_chest_delay_timer.w
	BNE.w	ChestAnimation_Return_Loop6
	PRINT 	OpenedChestStr
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#OPEN_MENU_STATE_CONTENTS, Open_menu_state.w
ChestAnimation_Return_Loop6:
	RTS
	
ChestAnimation_Return_Loop3:
	TST.b	Script_text_complete.w
	BEQ.w	ChestReward_Display_Loop
	TST.b	Reward_script_available.w
	BNE.w	ChestAnimation_Return_Loop7
	PRINT 	NothingInsideStr
	BRA.w	ChestReward_Display
ChestAnimation_Return_Loop7:
	LEA	Text_build_buffer.w, A1
	LEA	ThereIsStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	LEA	ShopCategoryNameTables, A0
	MOVE.w	Reward_script_type.w, D0
	CMPI.w	#REWARD_TYPE_RING, D0
