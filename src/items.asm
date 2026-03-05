; ======================================================================
; src/items.asm
; Item use, shop, dialogue state machine, equipment menus, chest system
; ======================================================================
;
; Contents
; --------
;  Item Use Handlers (lines ~5-290)
;    UseVase, UseJokeBook, UseSmallBomb      — flavour-text items
;    UseOldWomansSketch / UseOldMansSketch   — proximity/direction checks
;    UseDigotPlant                           — poison cure
;    UseGeneric                              — key/chest tile dispatch
;    UsePassToCarthahena, UseCrown, etc.     — quest-item stubs
;    UseSixteenRings                         — throne placement check
;    RemoveSelectedItemFromList              — inventory slot removal
;
;  Dialogue State Machine (lines ~300-953)
;    DialogueStateMachine                   — master dispatcher (6-bit state)
;    DialogueStateHandlerMap                — 46-entry BRA.w jump table
;    DialogState_Init                       — tile detection & NPC talk
;    DialogState_WaitScript*                — script + button wait helpers
;    DialogState_DrawYesNo / ProcessYesNo   — yes/no choice handling
;
;  Shop System (lines ~955-1586)
;    ShopInit_LoadAssortment                — populate Shop_item_list[]
;    MalagaShop states (39-45)             — sword-trade special shop
;    Standard shop buy/sell states (6-23)   — buy menu, sell menu, inventory sell
;    DialogState_WaitScriptWithYesNoOrContinue — multi-branch continuation
;
;  Service Menus (lines ~1587-2143)
;    Fortune Teller states (24-26)          — per-town greetings + readings
;    Inn states (27-31)                     — Watling credit / pay / sleep
;    Church states (32-36)                  — curse removal, poison cure, save
;    Save Menu states (37-38)              — SRAM write from church
;
;  Equipment Helpers (lines ~2145-2820)
;    CheckIfCursed / RemoveCursedEquipment  — curse scan & stat rollback
;    CheckPlayerTalkToNPC                   — NPC proximity + script load
;    FormatShopItemPrice                    — BCD sell-price builder
;    FormatKimsAmount                       — BCD → ASCII digit formatter
;    NpcFacingDirectionLookup               — player dir → NPC facing byte
;    FortuneTellerGreetingsByTown           — per-town greeting fn ptrs
;    FortuneTellerReadingsByTown            — per-town reading fn ptrs
;
;  Ready Equipment State Machine (lines ~2336-2643)
;    ReadyEquipmentStateMachine             — equip/unequip menu (5 states)
;    BuildEquipmentListForCategory          — filter equipment by slot
;    GetCurrentEquippedItemID               — read Equipped_sword/shield/armor
;    GetSelectedEquipmentID / EquipSelectedItem
;    ClearEquipmentCursedFlag / UnequipItemByID
;    EquipStatAddJumpTable / EquipStatRemoveJumpTable
;
;  Equip List Menu State Machine (lines ~2824-3065)
;    EquipListMenuStateMachine              — character-sheet page browser
;    14-state BRA jump table               — stats, gear, combat, magic,
;                                            items, rings, status pages
;
;  Level-Up Stat Upgrade (lines ~3073-3151)
;    UpgradeLevelStats                      — apply randomised stat gains on level
;
;  Chest/Door Opening State Machine (lines ~3162-3339)
;    ChestOpeningStateMachine               — 7-state chest/door opener
;
; ANDI.l #$00FFFFFF — appears in 6 places to mask Player_kims to 24 bits
;   (the high byte is unused; masking prevents overflow comparisons from
;    seeing garbage in the high byte of the 32-bit RAM word).
;
; ======================================================================

; ---------------------------------------------------------------------------
; Item Use Handlers
; ---------------------------------------------------------------------------
; Each Use* function is called by the item menu when the player activates the
; matching item. They print a message, optionally play a sound, optionally
; remove the item from inventory (RemoveSelectedItemFromList), and return.
; ---------------------------------------------------------------------------

; UseVase: Flavour-text item. Prints "slipped from hand" message and removes.
UseVase:
	PRINT 	SlippedHandStr	
	BSR.w	RemoveSelectedItemFromList	
	RTS
	

; UseJokeBook: Flavour-text item. Prints "knock knock jokes" message and removes.
UseJokeBook:
	PRINT 	KnockJokesStr	
	BSR.w	RemoveSelectedItemFromList	
	RTS
	

; UseSmallBomb: Prints "loud roar" message, plays SOUND_BOMB, and removes.
UseSmallBomb:
	PRINT 	LoudRoarStr
	BSR.w	RemoveSelectedItemFromList
	PlaySound SOUND_BOMB
	RTS

; UseOldWomansSketch: Use the Old Man's Sketch item. Must be in Keltwick,
; in town exploration mode, and standing at one of the four tiles adjacent
; to the old man NPC (one per cardinal direction). Triggers the hand-off.
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
; OldManSketchPositionData: Four (x, y, direction) entries — one per
; cardinal side of the old man NPC. Player must be at these coordinates
; and facing the matching direction to trigger the hand-off.
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

; UseOldMansSketch: Use the Old Woman's Sketch item. Must be in Helwig,
; in town mode (not first-person), at one of the four tiles adjacent to
; the old woman NPC. Triggers the hand-off.
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

; OldWomanSketchPositionData: Four (x, y, direction) entries — one per
; cardinal side of the old woman NPC.
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

; UseTreasureOfTroy: Quest item stub — prints flavour text, does not remove.
UseTreasureOfTroy:
	PRINT 	IncredibleTreasureStr	
	RTS
	
; UseTruffle: Quest item stub — prints flavour text, does not remove.
UseTruffle:
	PRINT 	RoastDuckStr	
	RTS
	
; UseDigotPlant: Cure poison if player is poisoned; otherwise display
; "not poisonous" message. Always removes the item from inventory.
UseDigotPlant:
	TST.w	Player_poisoned.w
	BEQ.b	UseDigotPlant_NotPoisoned
	CLR.b	Poison_notified.w
	CLR.w	Player_poisoned.w
	CLR.b	Player_greatly_poisoned.w
	PRINT 	PoisonPurgedStr
	BRA.b	UseDigotPlant_RemoveItem
UseDigotPlant_NotPoisoned:
	PRINT 	NotPoisonousStr
UseDigotPlant_RemoveItem:
	BSR.w	RemoveSelectedItemFromList
	RTS

; UsePassToCarthahena: Quest item stub — prints power-surge flavour text.
UsePassToCarthahena:
	PRINT 	PowerSurgeStr	
	RTS
	
; UseCrown: Quest item stub — prints power-surge flavour text.
UseCrown:
	PRINT 	PowerSurgeStr	
	RTS
	

; UseSixteenRings: Use the Sixteen Rings at the throne in Carthahena castle.
; Must be in Carthahena, in castle room state ($A), at tile position ($15, 4).
; Sets the Sixteen_rings_used_at_throne flag and plays a level-up sound.
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
	PlaySound SOUND_LEVEL_UP
	RTS

UseSixteenRings_WrongCondition:
	PRINT 	RingsFirmamentStr
	RTS

; UseWhiteCrystal: Quest item stub — prints flavour text, does not remove.
UseWhiteCrystal:
	PRINT 	WhiteBeautifulStr	
	RTS
	
; UseRedCrystal: Quest item stub — prints flavour text, does not remove.
UseRedCrystal:
	PRINT 	DeepRedStr	
	RTS
	
; UseBlueCrystal: Quest item stub — prints flavour text, does not remove.
UseBlueCrystal:
	PRINT 	BrightBlue	
	RTS
	
; ---------------------------------------------------------------------------
; UseGeneric: Handle generic item use (keys, etc.).
;
; In top-down town mode (Player_in_first_person_mode = 0):
;   Gets the tile in front of the player. If it is a chest tile
;   (TOWN_TILE_CHEST), jumps to UseKey_NoDoor_Loop (prints futile message).
;   Otherwise falls through to UseKey_NoDoor.
;
; In first-person dungeon mode:
;   Gets the map tile one step ahead. If tile type != 6 (locked door),
;   prints NoDoorStr. Otherwise scans LockedDoorDataTable for a matching
;   (room, x, y, key_id) record. On match: plays SOUND_ATTACK, sets
;   Door_unlocked_flag, prints KeyUnlockedStr. On mismatch: KeyDoesntFitStr.
;
; LockedDoorDataTable record layout (8 bytes each):
;   Word 0: room ID       (negative = end-of-table sentinel)
;   Word 1: tile X
;   Word 2: tile Y
;   Word 3: required key item ID (low byte compared against selected item)
;
; Input:  (all state via RAM)
;   Player_in_first_person_mode.w
;   Selected_item_index.w, Possessed_items_list[].w
;   Player_position_x/y_outside_town.w, Player_direction.w
; Scratch: D0, D1, D3, D4, A0, A1, A2
; ---------------------------------------------------------------------------
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
	BNE.b	UseKey_NoDoor_WrongKey
	PlaySound SOUND_ATTACK
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
	
UseKey_NoDoor_WrongKey:
	PRINT 	KeyDoesntFitStr
	RTS
UseKey_NoDoor_Loop:
	PRINT 	EffortsFutileStr	
	RTS
	
; ---------------------------------------------------------------------------
; RemoveSelectedItemFromList — remove the selected item from the inventory
;
; Reads Selected_item_index.w as the element to remove from the
; Possessed_items_list array (max 10 entries, indices 0–9).  Shifts the
; tail of the array down by one entry by calling RemoveItemFromArray, then
; decrements Possessed_items_length.w.
;
; Input:   (all state via RAM)
;   Selected_item_index.w   — index of the item to remove (0-based)
;
; Scratch:  D0, D2, A0
; Output:   Possessed_items_list updated; Possessed_items_length decremented
; ---------------------------------------------------------------------------
; RemoveSelectedItemFromList: Remove the currently selected item from the
; player's inventory by shifting the array and decrementing the length.
RemoveSelectedItemFromList:
	MOVE.w	Selected_item_index.w, D0
	MOVE.w	#9, D2
	LEA	Possessed_items_list.w, A0
	SUBQ.w	#1, Possessed_items_length.w
	JSR	RemoveItemFromArray
	RTS

; ---------------------------------------------------------------------------
; Dialogue State Machine
; ---------------------------------------------------------------------------
; DialogueStateMachine: Dispatches to the current dialogue handler.
; Reads Dialogue_state, masks to 6 bits (max 63 states), and jumps through
; DialogueStateHandlerMap (a table of BRA.w entries, 4 bytes each).
DialogueStateMachine:
	MOVE.w	Dialogue_state.w, D0
	ANDI.w	#$003F, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	DialogueStateHandlerMap, A0
	JSR	(A0,D0.w)
	RTS

; DialogueStateHandlerMap: Jump table of BRA.w entries (4 bytes each).
; Entry index = Dialogue_state & $3F. States are assigned in order:
;   0  = Init          1  = WaitScript     2  = WaitButton
;   3  = WaitC         4  = DrawYesNo      5  = ProcessYesNo
;   6-14 = Shop buy    15-23 = Shop sell   24-26 = FortuneTeller
;  27-31 = Inn        32-36 = Church       37-38 = Save
;  39-45 = Malage blacksmith shop
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

; ---------------------------------------------------------------------------
; Dialogue State Handlers
; ---------------------------------------------------------------------------

; State 0 - Init: Save status bar, run opening script, detect tile type to
; determine which service (shop/inn/fortune teller/church) to enter.
; ---------------------------------------------------------------------------
; DialogState_Init: Entry point for all dialogue/service interactions.
;
; Called when the player presses C to talk. Saves the status bar, resets the
; script engine, increments Dialogue_state by 1, then dispatches based on the
; tile in front of the player (GetTileInFrontOfPlayer → D0):
;
;   TOWN_TILE_SHOP           → FortuneTeller_EnterState_Loop (load shop assortment)
;   TOWN_TILE_FORTUNE_TELLER → FortuneTeller_EnterState_FeePrompt (build fee msg)
;   TOWN_TILE_INN            → DialogState_Init_InnEntry (Watling credit check)
;   TOWN_TILE_FORTUNE_TELLER_2 → DialogState_Init_FortuneTeller2Entry (per-town greeting)
;   TOWN_TILE_CHURCH         → DialogState_Init_ChurchEntry (set church state)
;   anything else            → ShopInit_LoadAssortment_TalkToNPC (NPC scan)
;
; If the player is in first-person mode, skips tile check and goes straight to
; ShopInit_LoadAssortment_Loop (load NPC script from Script_talk_source).
;
; Input:  Player_in_first_person_mode.w, GetTileInFrontOfPlayer → D0
; Output: Dialogue_state.w updated; script / shop assortment loaded
; Scratch: D0
; ---------------------------------------------------------------------------
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
	BEQ.w	FortuneTeller_EnterState_FeePrompt
	CMPI.w	#TOWN_TILE_INN, D0
	BEQ.b	DialogState_Init_InnEntry
	CMPI.w	#TOWN_TILE_FORTUNE_TELLER_2, D0
	BEQ.b	DialogState_Init_FortuneTeller2Entry
	CMPI.w	#TOWN_TILE_CHURCH, D0
	BEQ.b	DialogState_Init_ChurchEntry
	BRA.w	ShopInit_LoadAssortment_TalkToNPC
DialogState_Init_ChurchEntry:
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_OPEN_CHURCH_MENU, Dialogue_state.w
	PRINT 	HelpPromptStr
	RTS

DialogState_Init_FortuneTeller2Entry:
	LEA	FortuneTellerGreetingsByTown, A0
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	(A0)
	RTS

DialogState_Init_InnEntry:
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_WATLING, D0
	BNE.w	InnDialog_ShowPricePrompt
	TST.b	Watling_inn_free_stay_used.w
	BNE.w	InnDialog_ShowPricePrompt
	PRINT 	CustomerStayHereStr
	TST.b	Watling_youth_restored.w
	BNE.b	DialogState_Init_WatlingCheck
	BRA.w	FortuneTeller_EnterState
DialogState_Init_WatlingCheck:
	TST.w	Watling_inn_unpaid_nights.w
	BNE.b	DialogState_Init_WatlingFreeStay
	MOVE.b	#FLAG_TRUE, Watling_inn_free_stay_used.w	
	BRA.w	InnDialog_ShowPricePrompt	
DialogState_Init_WatlingFreeStay:
	LEA	Text_build_buffer.w, A1
	LEA	StayingForFreeStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	MOVE.w	Watling_inn_unpaid_nights.w, D0
	MULU.w	#$0190, D0          ; 0x190 = 400 kims per night (BCD)
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

FortuneTeller_EnterState_FeePrompt:
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
	BEQ.b	FortuneTeller_EnterState_CheckShopType
	CLR.w	Current_shop_type.w
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_MALAGA, D0
	BNE.b	ShopInit_LoadAssortment
	BRA.b	ShopInit_LoadAssortment_MalagaShop
FortuneTeller_EnterState_CheckShopType:
	MOVE.w	Current_town_room.w, D0
	ANDI.w	#$0200, D0
	BEQ.b	FortuneTeller_EnterState_CheckEquipShop
	MOVE.w	#SHOP_TYPE_EQUIPMENT, Current_shop_type.w
	BRA.b	ShopInit_LoadAssortment
FortuneTeller_EnterState_CheckEquipShop:
	MOVE.w	Current_town_room.w, D0
	ANDI.w	#$0400, D0
	BEQ.b	ShopInit_LoadAssortment
	MOVE.w	#SHOP_TYPE_MAGIC, Current_shop_type.w
; ---------------------------------------------------------------------------
; ShopInit_LoadAssortment: Populate Shop_item_list[] from the per-town,
; per-shop-type assortment table (ShopAssortmentByTownAndShopType).
;
; Also loads the shop greeting script into Script_source_base.
;
; Shop type is read from Current_shop_type.w:
;   0 = item shop, 1 = equipment shop, 2 = magic shop
;
; Input:  Current_town.w, Current_shop_type.w
; Output: Shop_item_list[], Shop_item_count.w, Script_source_base.w
; Scratch: D0, D1, D7, A0, A1, A2
; ---------------------------------------------------------------------------
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

ShopInit_LoadAssortment_TalkToNPC:
	BSR.w	CheckPlayerTalkToNPC
	RTS

ShopInit_LoadAssortment_Loop:
	MOVE.l	Script_talk_source.w, Script_source_base.w
	RTS

; ---------------------------------------------------------------------------
; ShopInit_LoadAssortment_MalagaShop: Malaga blacksmith shop entry handler.
;
; Picks the correct next dialogue state and greeting index (D2) based on
; story-progress flags (most recent event wins, checked in reverse order):
;
;   Player_has_received_sword_of_vermilion → greeting 3, state WAIT_SCRIPT_THEN_GO_TO_OVERWORLD
;   Sword_retrieved_from_blacksmith         → greeting 2, state MALAGE_SHOP_GIVE_VERMILION_SWORD
;   Sword_stolen_by_blacksmith              → greeting 1, state WAIT_SCRIPT_THEN_GO_TO_OVERWORLD
;   (none)                                  → greeting 0, state MALAGE_WAIT_SCRIPT_THEN_OPEN_SELL_LIST
;
; Falls through to MalagaShop_LoadAssortment, which loads the per-town shop
; assortment for Malaga (ShopAssortmentByTownAndShopType) and loads the
; selected greeting script (ShopGreetingStrPtrs[D2]).
;
; Input:  Player_has_received_sword_of_vermilion.w, Sword_retrieved_from_blacksmith.w,
;         Sword_stolen_by_blacksmith.w, Current_town.w, Current_shop_type.w
; Output: Dialogue_state.w set; Script_source_base.w loaded; Shop_item_list[] populated
; Scratch: D0, D1, D2, D7, A0, A1, A2
; ---------------------------------------------------------------------------
ShopInit_LoadAssortment_MalagaShop:
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

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Malage Blacksmith States (states 39-45): special shop to trade rings for
; the Vermilion Sword
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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
	BEQ.w	DialogState_MalageShopSelectItemToBuy_ProcessText
	CheckButton BUTTON_BIT_B
	BEQ.b	DialogState_MalageShopSelectItemToBuy_CheckConfirm
	JSR	ResetScriptAndInitDialogue	
	PRINT 	NoLeaveWithoutBuyingStr	
	CLR.b	Script_text_complete.w	
	PlaySound SOUND_MENU_CANCEL	
	JSR	RestoreLeftMenuFromBuffer	
	JSR	RestoreShopListFromBuffer	
	MOVE.w	#DIALOG_STATE_MALAGE_WAIT_SCRIPT_THEN_OPEN_SELL_LIST, Dialogue_state.w	
	RTS
	
DialogState_MalageShopSelectItemToBuy_ProcessText:
	JMP	ProcessScriptText	
DialogState_MalageShopSelectItemToBuy_CheckConfirm:
	CheckButton BUTTON_BIT_C
	BEQ.b	DialogState_MalageShopSelectItemToBuy_HandleCursor
	MOVE.w	Shop_selected_index.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	PlaySound SOUND_MENU_SELECT
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
	MOVE.w	#DIALOG_STATE_MALAGE_BLACKSMITH_INTRO, Dialogue_state.w
	RTS

DialogState_MalageShopSelectItemToBuy_HandleCursor:
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
	BEQ.w	ShopBuy_CancelReturn_ProcessText
	CheckButton BUTTON_BIT_B
	BNE.w	ShopBuy_CancelReturn
	CheckButton BUTTON_BIT_C
	BEQ.w	ShopBuy_CancelReturn_HandleYesNo
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.w	Dialog_selection.w
	BNE.w	ShopBuy_CancelReturn
	PlaySound SOUND_MENU_SELECT
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
	BEQ.b	DialogState_MalageShopConfirmOrCancel_ScanNext
	SUBQ.w	#1, (A1)
	BGE.b	DialogState_MalageShopConfirmOrCancel_ClampLength
	CLR.w	(A1)	
DialogState_MalageShopConfirmOrCancel_ClampLength:
	MOVE.w	D7, D0
	LEA	Possessed_equipment_list.w, A0
	MOVE.w	#8, D2
	JSR	RemoveItemFromArray
DialogState_MalageShopConfirmOrCancel_ScanNext:
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
	BLT.b	ShopBuy_ConfirmBuy_ClearSword
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	LEA	EquipmentToStatModifierMap, A0
	MOVE.w	(A0,D0.w), D0
	SUB.w	D0, Player_str.w
ShopBuy_ConfirmBuy_ClearSword:
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
	PlaySound SOUND_MENU_CANCEL
	JSR	DrawLeftMenuWindow
	MOVE.w	#DIALOG_STATE_MALAGE_WAIT_SCRIPT_THEN_OPEN_SELL_LIST, Dialogue_state.w
	JSR	RestoreLeftMenuFromBuffer
	JSR	RestoreShopListFromBuffer
	JSR	ResetScriptAndInitDialogue
	PRINT 	NoLeaveWithoutBuyingStr
	CLR.b	Script_text_complete.w
	RTS

ShopBuy_CancelReturn_HandleYesNo:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

ShopBuy_CancelReturn_ProcessText:
	JSR	ProcessScriptText
	RTS

; ---------------------------------------------------------------------------
; DialogState_MalageShopGiveVermilionSword: Award the Sword of Vermilion (state 42).
;
; Checks if the player's equipment inventory is full (≥ 8 items):
;   Full   → prints ComeBackWithLessStr, stays in current state.
;   Room   → appends EQUIPMENT_SWORD_OF_VERMILION to Possessed_equipment_list,
;             sets Player_has_received_sword_of_vermilion flag.
;
; In both cases: transitions to DIALOG_STATE_WAIT_SCRIPT_THEN_ADVANCE.
;
; Input:  Possessed_equipment_length.w, Possessed_equipment_list.w
; Output: Sword added to inventory (if not full); story flag set;
;         Dialogue_state.w = DIALOG_STATE_WAIT_SCRIPT_THEN_ADVANCE
; Scratch: D0, A0
; ---------------------------------------------------------------------------
DialogState_MalageShopGiveVermilionSword:
	LEA	Possessed_equipment_length.w, A0
	MOVE.w	(A0), D0
	CMPI.w	#8, D0 ; Max number of equipment
	BLT.b	DialogState_MalageShopGiveVermilionSword_AddSword
	PRINT 	ComeBackWithLessStr	
	BRA.b	DialogState_MalageShopGiveVermilionSword_SetState	
DialogState_MalageShopGiveVermilionSword_AddSword:
	MOVE.w	(A0), D0
	ADDQ.w	#1, (A0)+
	ADD.w	D0, D0
	MOVE.w	#((EQUIPMENT_TYPE_SWORD<<8)|EQUIPMENT_SWORD_OF_VERMILION), (A0,D0.w)
	MOVE.b	#FLAG_TRUE, Player_has_received_sword_of_vermilion.w
DialogState_MalageShopGiveVermilionSword_SetState:
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_ADVANCE, Dialogue_state.w
	RTS

DialogState_WaitScriptThenGoToOverworld:
	TST.b	Script_text_complete.w
	BEQ.b	DialogWait_ClearRow_ProcessText
	TST.b	Script_has_continuation.w
	BNE.w	DialogWait_ClearRow_WaitContinue
	CheckButton BUTTON_BIT_C
	BNE.b	DialogWait_ClearRow
	CheckButton BUTTON_BIT_B
	BNE.b	DialogWait_ClearRow
	RTS

DialogWait_ClearRow:
	CLR.w	Window_text_row.w
	MOVE.w	#DIALOG_STATE_REDRAW_HUD_AND_CLOSE, Dialogue_state.w
	RTS

DialogWait_ClearRow_WaitContinue:
	CheckButton BUTTON_BIT_C	
	BEQ.b	DialogWait_ClearRow_Return	
	JSR	InitDialogueWindow	
DialogWait_ClearRow_ProcessText:
	JSR	ProcessScriptText
DialogWait_ClearRow_Return:
	RTS

DialogState_WaitScriptThenAdvance:
	TST.b	Window_tilemap_draw_pending.w
	BNE.b	DialogState_WaitScriptThenAdvance_Return
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptThenAdvance_ProcessText
	TST.b	Script_has_continuation.w
	BNE.b	DialogState_WaitScriptThenAdvance_SetContinueState
	TST.b	Script_has_yes_no_question.w
	BNE.b	DialogState_WaitScriptThenAdvance_SetYesNoState
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_WaitScriptThenAdvance_SetContinueState:
	MOVE.w	#DIALOG_STATE_WAIT_C_THEN_RESTART_DIALOGUE, Dialogue_state.w
	RTS

DialogState_WaitScriptThenAdvance_SetYesNoState:
	MOVE.w	#DIALOG_STATE_DRAW_YES_NO_DIALOG, Dialogue_state.w
	RTS

DialogState_WaitScriptThenAdvance_ProcessText:
	JSR	ProcessScriptText
DialogState_WaitScriptThenAdvance_Return:
	RTS

DialogState_WaitButtonThenCloseMenu:
	CheckButton BUTTON_BIT_C
	BNE.b	DialogWait_CloseToOverworld
	CheckButton BUTTON_BIT_B
	BNE.b	DialogWait_CloseToOverworld
	RTS

DialogWait_CloseToOverworld:
	CLR.w	Overworld_menu_state.w
	JSR	DrawStatusHudWindow
	TriggerWindowRedraw WINDOW_DRAW_MSG_SPEED_ALT
	RTS

DialogState_WaitCThenRestartDialogue:
	CheckButton BUTTON_BIT_C
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
	CheckButton BUTTON_BIT_C
	BEQ.w	DialogueChoice_Continue_HandleCursor
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
	BEQ.b	DialogueChoice_Continue_SelectYes
	LEA	DialogueChoiceNoStrPtrs, A0
	BRA.b	DialogueChoice_Continue_LoadScript
DialogueChoice_Continue_SelectYes:
	LEA	DialogueChoiceYesStrPtrs, A0
DialogueChoice_Continue_LoadScript:
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

DialogueChoice_Continue_HandleCursor:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Shop States (states 6-23): buy menu, sell menu, inventory sell
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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
	CheckButton BUTTON_BIT_B
	BEQ.b	DialogState_ShopMenuInput_CheckConfirm
	BRA.b	DialogState_ShopMenuInput_SelectExit
DialogState_ShopMenuInput_CheckConfirm:
	CheckButton BUTTON_BIT_C
	BEQ.b	ShopSell_ShowPrompt_Loop
	MOVE.w	Shop_action_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.w	Shop_action_selection.w
	BEQ.b	DialogState_ShopMenuInput_SelectBuy
	CMPI.w	#1, Shop_action_selection.w
	BEQ.b	DialogState_ShopMenuInput_SelectSell
DialogState_ShopMenuInput_SelectExit:
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_NextTime, A0
	TST.b	Shop_purchase_made.w
	BEQ.b	DialogState_ShopMenuInput_LoadGoodbye
	LEA	ShopDialog_BusinessThanks, A0	
DialogState_ShopMenuInput_LoadGoodbye:
	MOVE.l	(A0,D0.w), Script_source_base.w
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_TO_OVERWORLD, Dialogue_state.w
	BRA.b	ShopSell_ShowPrompt
DialogState_ShopMenuInput_SelectBuy:
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_BuyPrompt, A0
	MOVE.l	(A0,D0.w), Script_source_base.w
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_OPEN_SELL_LIST_WINDOW, Dialogue_state.w
	BRA.b	ShopSell_ShowPrompt
DialogState_ShopMenuInput_SelectSell:
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
	CheckButton BUTTON_BIT_C
	BNE.b	DialogState_ShowWindowReturn
	CheckButton BUTTON_BIT_B
	BNE.b	DialogState_ShowWindowReturn
	RTS

DialogState_ShowWindowReturn:
	TriggerWindowRedraw WINDOW_DRAW_ITEM_LIST_TALL
	MOVE.w	#DIALOG_STATE_REDRAW_HUD_AND_CLOSE, Dialogue_state.w
	RTS

DialogState_ShowWindowReturn_Loop:
	JMP	ProcessScriptText
DialogState_RedrawHudAndClose:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.b	DialogState_RedrawHudAndClose_Loop
	JSR	DrawStatusHudWindow
	CLR.w	Overworld_menu_state.w
	TriggerWindowRedraw WINDOW_DRAW_MSG_SPEED_ALT
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
	BEQ.w	DialogState_ShopSellItemSelectInput_ProcessText
	CheckButton BUTTON_BIT_B
	BEQ.b	DialogState_ShopSellItemSelectInput_CheckConfirm
	PlaySound SOUND_MENU_CANCEL
	JSR	RestoreLeftMenuFromBuffer
	JSR	RestoreShopListFromBuffer
	JSR	DrawShopMenuWindow
	MOVE.w	#DIALOG_STATE_SHOP_MENU_INPUT, Dialogue_state.w
	RTS

DialogState_ShopSellItemSelectInput_CheckConfirm:
	CheckButton BUTTON_BIT_C
	BEQ.w	DialogState_ShopSellItemSelectInput_HandleCursor
	PlaySound SOUND_MENU_SELECT
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

DialogState_ShopSellItemSelectInput_HandleCursor:
	MOVE.w	Shop_selected_index.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Shop_selected_index.w
	RTS

DialogState_ShopSellItemSelectInput_ProcessText:
	JMP	ProcessScriptText	
DialogState_ShopBuyConfirmAndPurchase:
	TST.b	Script_text_complete.w
	BEQ.w	ShopCancel_RedrawBuyPrompt_ProcessText
	CheckButton BUTTON_BIT_B
	BNE.w	ShopCancel_RedrawBuyPrompt
	CheckButton BUTTON_BIT_C
	BEQ.w	ShopCancel_RedrawBuyPrompt_HandleYesNo
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.w	Dialog_selection.w
	BNE.w	ShopCancel_RedrawBuyPrompt
	PlaySound SOUND_MENU_SELECT
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
	ANDI.l	#$00FFFFFF, D1          ; mask high byte — Player_kims is 24-bit BCD
	CMP.l	D0, D1
	BLT.b	DialogState_ShopBuyConfirmAndPurchase_InsufficientFunds
	LEA	ShopCategoryNameTables, A0
	MOVE.w	Current_shop_type.w, D0
	ASL.w	#3, D0
	MOVEA.l	$4(A0,D0.w), A0
	MOVE.w	(A0), D0
	CMPI.w	#8, D0
	BLT.b	DialogState_ShopBuyConfirmAndPurchase_AddItem
	PRINT 	CantCarryMoreStr2
	BRA.b	ShopGiveaway_RestoreList
DialogState_ShopBuyConfirmAndPurchase_AddItem:
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
DialogState_ShopBuyConfirmAndPurchase_InsufficientFunds:
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
	PlaySound SOUND_MENU_CANCEL	
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
	
ShopCancel_RedrawBuyPrompt_HandleYesNo:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

ShopCancel_RedrawBuyPrompt_ProcessText:
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
	CheckButton BUTTON_BIT_B
	BNE.b	ShopBuyDone_ThankYou
	CheckButton BUTTON_BIT_C
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
	BEQ.w	ShopEquip_InitCursor_ProcessText
	MOVE.w	Current_shop_type.w, D0
	ASL.w	#3, D0
	LEA	ShopCategoryNameTables, A0
	MOVEA.l	$4(A0,D0.w), A0
	MOVE.w	(A0), D0
	BEQ.w	ShopEquip_InitCursor_NothingToSell
	JSR	SaveCenterDialogAreaToBuffer
	MOVE.w	Current_shop_type.w, D0
	BEQ.b	DialogState_WaitScriptThenOpenInventorySellList_DrawItemList
	CMPI.w	#SHOP_TYPE_EQUIPMENT, D0
	BEQ.b	DialogState_WaitScriptThenOpenInventorySellList_DrawEquipList
	JSR	DrawMagicListBorders
	JSR	DrawMagicListWithMP
	MOVE.l	#Possessed_magics_list, Active_inventory_list_ptr.w
	MOVE.w	Possessed_magics_length.w, D0
	BRA.b	ShopEquip_InitCursor
DialogState_WaitScriptThenOpenInventorySellList_DrawItemList:
	JSR	DrawItemListBorders
	JSR	DrawItemListNames
	MOVE.l	#Possessed_items_list, Active_inventory_list_ptr.w
	MOVE.w	Possessed_items_length.w, D0
	BRA.b	ShopEquip_InitCursor
DialogState_WaitScriptThenOpenInventorySellList_DrawEquipList:
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

ShopEquip_InitCursor_NothingToSell:
	JSR	ResetScriptAndInitDialogue
	JSR	SaveLeftMenuTiles
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_SellAnything, A0
	MOVE.l	(A0,D0.w), Script_source_base.w
	ADDQ.w	#1, Dialogue_state.w
	RTS

ShopEquip_InitCursor_ProcessText:
	JMP	ProcessScriptText
DialogState_WaitScriptThenReturnToSellList:
	TST.b	Script_text_complete.w
	BEQ.b	DialogWait_ShowAnythingElse_Loop
	CheckButton BUTTON_BIT_C
	BNE.b	DialogWait_ShowAnythingElse
	CheckButton BUTTON_BIT_B
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
	BEQ.w	ShopBuy_ScanItem_ProcessText
	CheckButton BUTTON_BIT_B
	BEQ.b	DialogState_SellInventoryItemSelectInput_Loop
	JSR	DrawCenterMenuWindow
	JSR	RestoreLeftMenuFromBuffer
	JSR	DrawShopMenuWindow
	MOVE.w	#DIALOG_STATE_SHOP_MENU_INPUT, Dialogue_state.w
	RTS

DialogState_SellInventoryItemSelectInput_Loop:
	CheckButton BUTTON_BIT_C
	BEQ.w	ShopBuy_ScanItem_HandleCursor
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
	BNE.w	ShopBuy_ScanItem_ItemUnwanted
	CMPI.w	#SHOP_TYPE_EQUIPMENT, Current_shop_type.w
	BNE.b	ShopBuy_ScanItem
	MOVE.w	#9, D1
	BTST.l	D1, D0
	BEQ.b	ShopBuy_ScanItem
	MOVE.w	#$000F, D1
	BTST.l	D1, D0
	BNE.b	ShopBuy_ScanItem_ItemCursed
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

ShopBuy_ScanItem_ItemCursed:
	PRINT 	CursedItemStr	
	BRA.b	ShopBuy_ScanItem_ShowRejectAndReturn	
ShopBuy_ScanItem_ItemUnwanted:
	MOVE.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ShopDialog_NoNeed, A0
	MOVE.l	(A0,D0.w), Script_source_base.w
ShopBuy_ScanItem_ShowRejectAndReturn:
	JSR	DrawCenterMenuWindow
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_RETURN_TO_SELL_LIST, Dialogue_state.w
	RTS

ShopBuy_ScanItem_HandleCursor:
	MOVE.w	Shop_selected_index.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Shop_selected_index.w
	RTS

ShopBuy_ScanItem_ProcessText:
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
; ---------------------------------------------------------------------------
; DialogState_SellInventoryConfirmAndSell: Sell-confirmation yes/no handler.
;
; On confirm-yes:
;   - Adds Shop_sell_price to Player_kims (AddPaymentAmount) and refreshes display.
;   - If equipment: checks bit 10 (sword) or AC flag to determine stat rollback
;     (subtract EquipmentToStatModifierMap entry from Player_str or Player_ac).
;   - Decrements the possession-list length counter (ShopCategoryNameTables+$4).
;   - Removes item from the active inventory list via RemoveItemFromArray.
;   - Redraws menus, loads "thank you" script, sets
;     DIALOG_STATE_WAIT_SCRIPT_THEN_DRAW_SELL_CONFIRM.
;
; On cancel (B or no in yes/no): restores left menu, redraws shop menu,
;   resets to DIALOG_STATE_SELL_INVENTORY_ITEM_SELECT_INPUT.
;
; Input:  Dialog_selection.w, Shop_sell_price.w, Shop_selected_index.w,
;         Active_inventory_list_ptr.w, Current_shop_type.w
; Output: Player_kims updated; item removed from possession list;
;         Dialogue_state.w updated
; Scratch: D0, D1, D2, A0, A2, A3
; ---------------------------------------------------------------------------
DialogState_SellInventoryConfirmAndSell:
	CheckButton BUTTON_BIT_B
	BNE.w	ShopEquip_DrawAndSetState
	CheckButton BUTTON_BIT_C
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
	BNE.w	DialogState_SellInventoryConfirmAndSell_ClearMagic
	MOVE.w	#MAGIC_NONE, Readied_magic.w
	BRA.w	ShopSell_RemoveFromList
DialogState_SellInventoryConfirmAndSell_ClearMagic:
	LEA	Equipped_items.w, A2
	MOVE.w	D0, D2
	MOVE.w	#$000A, D1
	ASR.w	D1, D0
DialogState_SellInventoryConfirmAndSell_Loop_Done:
	BTST.l	#0, D0
	BNE.b	DialogState_SellInventoryConfirmAndSell_UnequipItem
	LEA	$2(A2), A2
	ASR.w	#1, D0
	BRA.b	DialogState_SellInventoryConfirmAndSell_Loop_Done
DialogState_SellInventoryConfirmAndSell_UnequipItem:
	MOVE.w	#$FFFF, (A2)
	MOVE.w	D2, D0
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	LEA	EquipmentToStatModifierMap, A3
	ANDI.w	#$0400, D2
	BEQ.b	DialogState_SellInventoryConfirmAndSell_AdjustAC
	MOVE.w	Player_str.w, D1	
	SUB.w	(A3,D0.w), D1	
	ANDI.w	#$7FFF, D1	
	MOVE.w	D1, Player_str.w	
	BRA.b	ShopSell_RemoveFromList	
DialogState_SellInventoryConfirmAndSell_AdjustAC:
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
	CheckButton BUTTON_BIT_B
	BNE.b	ShopSell_RestoreAndInit
	CheckButton BUTTON_BIT_C
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
; ---------------------------------------------------------------------------
; DialogState_WaitScriptWithYesNoOrContinue: Multi-branch script wait (state 5).
;
; Used for fortune teller fee prompt and similar scripts that may have either
; a yes/no decision or a multi-page continuation:
;
;   Script still running         → ProcessScriptText
;   Script complete + continuation present → wait for C, then InitDialogueWindow
;   Script complete + no continuation   → SaveRightMenuAreaToBuffer,
;                                          DrawYesNoDialog, advance state
;
; Input:  Script_text_complete.w, Script_has_continuation.w
; Output: Dialogue_state.w advanced (no continuation) or held for page-turn
; ---------------------------------------------------------------------------
DialogState_WaitScriptWithYesNoOrContinue:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptWithYesNoOrContinue_ProcessText
	TST.b	Script_has_continuation.w
	BNE.w	DialogState_WaitScriptWithYesNoOrContinue_WaitContinue
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_WaitScriptWithYesNoOrContinue_WaitContinue:
	CheckButton BUTTON_BIT_C
	BEQ.b	DialogState_WaitScriptWithYesNoOrContinue_Return
	JSR	InitDialogueWindow
DialogState_WaitScriptWithYesNoOrContinue_ProcessText:
	JSR	ProcessScriptText
DialogState_WaitScriptWithYesNoOrContinue_Return:
	RTS

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Fortune Teller States (states 24-26)
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DialogState_DrawFortuneTellerMoneyWindow:
	JSR	SaveLeftMenuTiles
	JSR	DrawMoneyDisplayWindow
	JSR	DisplayPlayerKims
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_FortuneTellerPayAndRead:
	CheckButton BUTTON_BIT_B
	BNE.w	FortuneTeller_NoQuestionsLeft
	CheckButton BUTTON_BIT_C
	BEQ.w	FortuneTeller_DrawAndSetState_Loop
	TST.w	Dialog_selection.w
	BNE.w	FortuneTeller_NoQuestionsLeft
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	InnAndFortuneTellerPricesByTown, A0
	MOVE.l	(A0,D0.w), D0
	MOVE.l	Player_kims.w, D1
	ANDI.l	#$00FFFFFF, D1          ; mask high byte — Player_kims is 24-bit BCD
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
	BEQ.b	ShopExit_RestoreHud_ProcessText
	TST.b	Script_has_continuation.w
	BNE.b	ShopExit_RestoreHud_CheckContinue
	CheckButton BUTTON_BIT_C
	BNE.b	ShopExit_RestoreHud
	CheckButton BUTTON_BIT_B
	BNE.b	ShopExit_RestoreHud
	RTS

ShopExit_RestoreHud:
	JSR	DrawStatusHudWindow
	JSR	RestoreLeftMenuFromBuffer
	CLR.w	Overworld_menu_state.w
	TriggerWindowRedraw WINDOW_DRAW_MSG_SPEED_ALT
	RTS

ShopExit_RestoreHud_ProcessText:
	JMP	ProcessScriptText
ShopExit_RestoreHud_CheckContinue:
	CheckButton BUTTON_BIT_C
	BEQ.b	ShopExit_RestoreHud_Return
	JSR	InitDialogueWindow
ShopExit_RestoreHud_Return:
	RTS

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Inn States (states 27-31): price prompt, pay, sleep, fade
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DialogState_WaitScriptThenDrawInnYesNo:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptThenDrawInnYesNo_ProcessText
	TST.b	Script_has_continuation.w
	BNE.b	DialogState_WaitScriptThenDrawInnYesNo_CheckContinue
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_WATLING, D0
	BNE.b	DialogState_WaitScriptThenDrawInnYesNo_DrawYesNo
	TST.b	Watling_inn_free_stay_used.w
	BEQ.b	DialogState_WaitScriptThenDrawInnYesNo_SetState
DialogState_WaitScriptThenDrawInnYesNo_DrawYesNo:
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
DialogState_WaitScriptThenDrawInnYesNo_SetState:
	MOVE.w	#DIALOG_STATE_DRAW_INN_MONEY_WINDOW, Dialogue_state.w
	RTS

DialogState_WaitScriptThenDrawInnYesNo_ProcessText:
	JMP	ProcessScriptText
DialogState_WaitScriptThenDrawInnYesNo_CheckContinue:
	CheckButton BUTTON_BIT_C
	BEQ.b	DialogState_WaitScriptThenDrawInnYesNo_Return
	JSR	InitDialogueWindow
DialogState_WaitScriptThenDrawInnYesNo_Return:
	RTS

DialogState_DrawInnMoneyWindow:
	JSR	SaveLeftMenuTiles
	JSR	DrawMoneyDisplayWindow
	JSR	DisplayPlayerKims
	ADDQ.w	#1, Dialogue_state.w
	RTS

; ---------------------------------------------------------------------------
; DialogState_InnPayAndSleep: Inn payment / credit handler (state 29).
;
; For Watling inn WITHOUT free-stay used: pressing B or C credits one more
; night of debt (InnWatling_CreditNight), paying off as many nights as possible
; from current kims and setting the broke-penalty flag if funds run out.
;
; For all other inns (and Watling with free-stay used): shows the yes/no
; confirmation dialog. On confirm-yes: deducts the per-town inn price from
; Player_kims, prints "Rest well", then transitions to
; DIALOG_STATE_WAIT_SCRIPT_THEN_START_SLEEP_FADE.
;
; On cancel / insufficient funds: prints the appropriate refusal string and
; transitions to DIALOG_STATE_WAIT_FORTUNE_TELLER_SCRIPT_THEN_CLOSE.
;
; InnWatling_CreditNight: Iterates Watling_inn_unpaid_nights times, each
;   iteration paying $400 kims (400 BCD) until funds run dry. Sets
;   Watling_inn_broke_penalty flag if payment cannot be completed.
;
; Input:  Current_town.w, Watling_inn_free_stay_used.w, Player_kims.w
;         InnAndFortuneTellerPricesByTown, Watling_inn_unpaid_nights.w
; Output: Player_kims updated; Dialogue_state.w set
; Scratch: D0, D1, D7, A0
; ---------------------------------------------------------------------------
DialogState_InnPayAndSleep:
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_WATLING, D0
	BNE.w	InnWatling_ConfirmPayment
	TST.b	Watling_inn_free_stay_used.w
	BNE.w	InnWatling_ConfirmPayment
	CheckButton BUTTON_BIT_B
	BNE.b	InnWatling_CreditNight
	CheckButton BUTTON_BIT_C
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
	ANDI.l	#$00FFFFFF, D1          ; mask high byte — Player_kims is 24-bit BCD
	CMPI.l	#$400, D1               ; $400 = 400 kims per night (BCD)
	BLT.b	InnWatling_CreditNight_Broke
	MOVE.l	#$400, Transaction_amount.w
	JSR	DeductPaymentAmount
	DBF	D7, InnWatling_CreditNight_Done
	BRA.b	InnWatling_CreditNight_AfterPayment
InnWatling_CreditNight_Broke:
	MOVE.b	#FLAG_TRUE, Watling_inn_broke_penalty.w	
	CLR.l	Player_kims.w	
InnWatling_CreditNight_AfterPayment:
	JSR	DisplayPlayerKims
	CLR.w	Watling_inn_unpaid_nights.w
	BRA.w	InnWatling_SetRestState
InnWatling_ConfirmPayment:
	CheckButton BUTTON_BIT_B
	BNE.w	InnWatling_ServicesCost
	CheckButton BUTTON_BIT_C
	BEQ.w	InnWatling_ServicesCost_HandleCursor
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
	BLT.b	InnWatling_SetRestState_NoPayStreet
	MOVE.l	D0, Transaction_amount.w
	JSR	DeductPaymentAmount
	JSR	DisplayPlayerKims
	PRINT 	RestWellStr
	JSR	DrawLeftMenuWindow
	JSR	ResetScriptAndInitDialogue
InnWatling_SetRestState:
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_START_SLEEP_FADE, Dialogue_state.w
	RTS

InnWatling_SetRestState_NoPayStreet:
	PRINT 	NoPaySleepStreetStr
	BRA.b	InnWatling_ServicesCost_SetStateAndReset
InnWatling_ServicesCost:
	PRINT 	ServicesCostStr
InnWatling_ServicesCost_SetStateAndReset:
	JSR	DrawLeftMenuWindow
	MOVE.w	#DIALOG_STATE_WAIT_FORTUNE_TELLER_SCRIPT_THEN_CLOSE, Dialogue_state.w
	JSR	ResetScriptAndInitDialogue
	RTS

InnWatling_ServicesCost_HandleCursor:
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
; ---------------------------------------------------------------------------
; DialogState_SleepFadeAndRestore: Sleep fade-out and HP/MP restore (state 31).
;
; Waits for the fade-out (Fade_out_lines_mask) to complete, then counts down
; Sleep_delay_timer. When both finish:
;
;   Broke penalty (Watling_inn_broke_penalty set):
;     - HP  → halved (LSR.w #1), minimum 1
;     - MP  → halved
;     - Clears Watling_inn_broke_penalty
;
;   Normal sleep:
;     - HP  → Player_mhp (full restore)
;     - MP  → Player_mmp (full restore)
;
; After restore: loads town palettes, resets script, prints morning message,
; and transitions to DIALOG_STATE_WAIT_FORTUNE_TELLER_SCRIPT_THEN_CLOSE.
;
; For Watling with youth-not-yet-restored: prints "Move along" (credits still
; owed); for youth-restored: prints "Don't pull on me" and marks free stay used.
;
; Input:  Fade_out_lines_mask.w, Sleep_delay_timer.w,
;         Watling_inn_broke_penalty.w, Watling_inn_free_stay_used.w
; Output: Player_hp.w, Player_mp.w restored; palettes reloaded
; Scratch: D0
; ---------------------------------------------------------------------------
DialogState_SleepFadeAndRestore:
	TST.b	Fade_out_lines_mask.w
	BNE.w	ChurchDialog_SetState_Return
	SUBQ.w	#1, Sleep_delay_timer.w
	BGE.w	ChurchDialog_SetState_Return
	TST.b	Watling_inn_broke_penalty.w
	BEQ.b	DialogState_SleepFadeAndRestore_FullRestore
	MOVE.w	Player_hp.w, D0	
	CMPI.w	#1, D0	
	BEQ.b	DialogState_SleepFadeAndRestore_HalveHp	
	LSR.w	#1, D0	
DialogState_SleepFadeAndRestore_HalveHp:
	MOVE.w	D0, Player_hp.w	
	MOVE.w	Player_mp.w, D0	
	LSR.w	#1, D0	
	MOVE.w	D0, Player_mp.w	
	CLR.b	Watling_inn_broke_penalty.w	
	BRA.b	DialogState_SleepFadeAndRestore_RestoreStats	
DialogState_SleepFadeAndRestore_FullRestore:
	MOVE.w	Player_mhp.w, Player_hp.w
	MOVE.w	Player_mmp.w, Player_mp.w
DialogState_SleepFadeAndRestore_RestoreStats:
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_WATLING, D0
	BNE.b	InnWatling_GoodMorning
	TST.b	Watling_inn_free_stay_used.w
	BNE.b	InnWatling_GoodMorning
	TST.b	Watling_youth_restored.w
	BEQ.b	DialogState_SleepFadeAndRestore_WatlingNoPay
	PRINT 	DontPullOnMeStr
	MOVE.b	#FLAG_TRUE, Watling_inn_free_stay_used.w
	BRA.b	InnWatling_RestoreAndExit
DialogState_SleepFadeAndRestore_WatlingNoPay:
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

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Church States (states 32-36): menu, curse removal, poison cure
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DialogState_WaitScriptThenOpenChurchMenu:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptThenOpenChurchMenu_Loop
	JSR	SaveStatusMenuAreaToBuffer_Large
	JSR	DrawChurchMenuWindow
	PlaySound SOUND_MENU_CURSOR
	CLR.w	Church_service_selection.w
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_WaitScriptThenOpenChurchMenu_Loop:
	JMP	ProcessScriptText
; ---------------------------------------------------------------------------
; DialogState_ChurchMenuInput: Church service selection menu handler (state 33).
;
; Waits for any pending window draws, then dispatches on Church_service_selection:
;   0 = Remove Curse  → CheckIfCursed; if cursed: build donation+price message
;                        and set DIALOG_STATE_WAIT_SCRIPT_THEN_DRAW_CURSE_YES_NO;
;                        if not cursed: print NoCurseStr, close.
;   1 = Cure Poison   → Check Player_poisoned; if poisoned: build donation+price
;                        message and set DIALOG_STATE_WAIT_SCRIPT_THEN_DRAW_POISON_YES_NO;
;                        if not poisoned: print NotPoisonedStr, close.
;   2 = Save Game     → Print slot prompt, set DIALOG_STATE_WAIT_SCRIPT_THEN_OPEN_SAVE_MENU.
;   3 = Leave         → Print farewell, set DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD.
;
; All confirmed paths call ResetScriptAndInitDialogue (via ChurchService_InitDialogue).
; Cursor navigation uses Church_service_selection via HandleMenuInput.
;
; Input:  Church_service_selection.w, Player_poisoned.w, Equipped_items.w
; Output: Dialogue_state.w updated; script loaded or message printed
; Scratch: D0, A0, A1
; ---------------------------------------------------------------------------
DialogState_ChurchMenuInput:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	ChurchMenu_HandleInput_Return
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	ChurchMenu_HandleInput_Return
	CheckButton BUTTON_BIT_B
	BEQ.b	DialogState_ChurchMenuInput_CheckConfirm
	BRA.b	DialogState_ChurchMenuInput_SelectLeave
DialogState_ChurchMenuInput_CheckConfirm:
	CheckButton BUTTON_BIT_C
	BEQ.w	ChurchService_InitDialogue_Loop
	MOVE.w	Church_service_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.w	Church_service_selection.w
	BEQ.b	DialogState_ChurchMenuInput_SelectCurse
	CMPI.w	#1, Church_service_selection.w
	BEQ.w	DialogState_ChurchMenuInput_SelectPoison
	CMPI.w	#2, Church_service_selection.w
	BEQ.w	DialogState_ChurchMenuInput_SelectSave
DialogState_ChurchMenuInput_SelectLeave:
	PRINT 	NeverGiveUpStr
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD, Dialogue_state.w
	BRA.w	ChurchService_InitDialogue
DialogState_ChurchMenuInput_SelectCurse:
	BSR.w	CheckIfCursed
	BEQ.b	DialogState_ChurchMenuInput_NotCursed
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
DialogState_ChurchMenuInput_NotCursed:
	PRINT 	NoCurseStr
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD, Dialogue_state.w
	BRA.b	ChurchService_InitDialogue
DialogState_ChurchMenuInput_SelectPoison:
	MOVE.w	Player_poisoned.w, D0
	BEQ.b	DialogState_ChurchMenuInput_NotPoisoned
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
DialogState_ChurchMenuInput_NotPoisoned:
	PRINT 	NotPoisonedStr
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD, Dialogue_state.w
	BRA.b	ChurchService_InitDialogue
DialogState_ChurchMenuInput_SelectSave:
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
	CheckButton BUTTON_BIT_C
	BNE.b	ChurchExit_RestoreAndSetState
	CheckButton BUTTON_BIT_B
	BNE.b	ChurchExit_RestoreAndSetState
	RTS

ChurchExit_RestoreAndSetState:
	PlaySound SOUND_MENU_CANCEL
	TriggerWindowRedraw WINDOW_DRAW_RIGHT_MENU
	MOVE.w	#DIALOG_STATE_WAIT_TILE_THEN_CLOSE_TO_OVERWORLD, Dialogue_state.w
	RTS

ChurchExit_RestoreAndSetState_Loop:
	JMP	ProcessScriptText
DialogState_WaitTileThenCloseToOverworld:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.b	DialogState_WaitTileThenCloseToOverworld_Loop
	JSR	DrawStatusHudWindow
	PlaySound SOUND_MENU_CANCEL
	CLR.w	Overworld_menu_state.w
	TriggerWindowRedraw WINDOW_DRAW_MSG_SPEED_ALT
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

; ---------------------------------------------------------------------------
; DialogState_CurseRemovalPayAndCure: Church curse-removal payment (state 35).
;
; Presents yes/no dialog. On confirm-yes:
;   - Loads ChurchCurseRemovalPricesByTown[Current_town] into D0.
;   - Masks Player_kims to 24 bits and compares with price.
;   - If sufficient: deducts payment, calls RemoveCursedEquipment, prints
;     CurseRemovedStr, transitions to DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD.
;   - If insufficient: prints NoTakeBackStr, transitions to close.
;
; On cancel (B button): prints NoTakeBackStr, transitions to close.
;
; Input:  Dialog_selection.w, Player_kims.w, ChurchCurseRemovalPricesByTown
; Output: Player_kims updated; cursed equipment removed; Dialogue_state.w set
; Scratch: D0, D1, A0
; ---------------------------------------------------------------------------
DialogState_CurseRemovalPayAndCure:
	CheckButton BUTTON_BIT_B
	BNE.w	ShopNoTakeBack_Sell
	CheckButton BUTTON_BIT_C
	BEQ.w	ShopNoTakeBack_Sell_HandleCursor
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
	BRA.b	ShopNoTakeBack_Sell_SetStateAndReset	
ShopNoTakeBack_Sell:
	PRINT 	NoTakeBackStr	
ShopNoTakeBack_Sell_SetStateAndReset:
	JSR	DrawLeftMenuWindow	
	JSR	RestoreLeftMenuFromBuffer	
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD, Dialogue_state.w	
	JSR	ResetScriptAndInitDialogue	
	RTS
	
ShopNoTakeBack_Sell_HandleCursor:
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

; ---------------------------------------------------------------------------
; DialogState_PoisonCurePayAndCure: Church poison-cure payment (state 36+1).
;
; Presents yes/no dialog. On confirm-yes:
;   - Loads ChurchPoisonCurePricesByTown[Current_town] into D0.
;   - Masks Player_kims to 24 bits and compares with price.
;   - If sufficient: deducts payment.
;       - If Player_greatly_poisoned is set: prints CantCureStr (serious poison
;         cannot be cured by the church — requires a specific item).
;       - Otherwise: clears Player_poisoned and Poison_notified, prints
;         PoisonPurgedStr.
;   - If insufficient: prints NoTakeBackStr, transitions to close.
;
; On cancel (B button): prints NoTakeBackStr, transitions to close.
;
; Input:  Dialog_selection.w, Player_kims.w, Player_greatly_poisoned.w
;         ChurchPoisonCurePricesByTown
; Output: Player_kims updated; Player_poisoned cleared (if curable);
;         Dialogue_state.w set to DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD
; Scratch: D0, D1, A0
; ---------------------------------------------------------------------------
DialogState_PoisonCurePayAndCure:
	CheckButton BUTTON_BIT_B
	BNE.w	ShopNoTakeBack_Giveaway
	CheckButton BUTTON_BIT_C
	BEQ.w	ShopNoTakeBack_Giveaway_HandleCursor
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
	BLT.w	DialogState_PoisonCurePayAndCure_NoFunds
	MOVE.l	D0, Transaction_amount.w
	JSR	DeductPaymentAmount
	JSR	DisplayPlayerKims
	TST.w	Player_greatly_poisoned.w
	BNE.b	DialogState_PoisonCurePayAndCure_SeriousPoisoned
	CLR.w	Player_poisoned.w
	CLR.b	Poison_notified.w
	PRINT 	PoisonPurgedStr
	BRA.b	DialogState_PoisonCurePayAndCure_ExitChurch
DialogState_PoisonCurePayAndCure_SeriousPoisoned:
	PRINT 	CantCureStr
DialogState_PoisonCurePayAndCure_ExitChurch:
	JSR	DrawLeftMenuWindow
	JSR	RestoreLeftMenuFromBuffer
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD, Dialogue_state.w
	RTS

DialogState_PoisonCurePayAndCure_NoFunds:
	PRINT 	NoTakeBackStr	
	BRA.b	ShopNoTakeBack_Giveaway_SetStateAndReset	
ShopNoTakeBack_Giveaway:
	PRINT 	NoTakeBackStr	
ShopNoTakeBack_Giveaway_SetStateAndReset:
	JSR	DrawLeftMenuWindow	
	JSR	RestoreLeftMenuFromBuffer	
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD, Dialogue_state.w	
	JMP	ResetScriptAndInitDialogue	
ShopNoTakeBack_Giveaway_HandleCursor:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Save Menu States (states 37-38)
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

DialogState_WaitScriptThenOpenSaveMenu:
	TST.b	Script_text_complete.w
	BEQ.b	DialogState_WaitScriptThenOpenSaveMenu_Loop
	JSR	SaveShopSubmenuAreaToBuffer
	JSR	DrawSavedGameOptionsMenu
	ADDQ.w	#1, Dialogue_state.w
	RTS

DialogState_WaitScriptThenOpenSaveMenu_Loop:
	JMP	ProcessScriptText
; ---------------------------------------------------------------------------
; DialogState_SaveMenuInput: Save-slot selection and SRAM write (state 38).
;
; Waits for window draw to finish, then:
;   B button → restore submenu, redraw church menu, reset Church_service_selection
;              and state to DIALOG_STATE_CHURCH_MENU_INPUT (back to church menu).
;   C button → call SaveGameToSram, restore submenu, print "Game saved" message,
;              set DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD.
;   neither  → HandleMenuInput on Dialog_selection (cursor navigation).
;
; Input:  Window_tilemap_draw_active.w, Dialog_selection.w
; Output: Save game written to SRAM on confirm; Dialogue_state.w updated
; Scratch: D0
; ---------------------------------------------------------------------------
DialogState_SaveMenuInput:
	TST.b	Window_tilemap_draw_active.w
	BNE.b	DialogState_SaveMenuInput_Return
	CheckButton BUTTON_BIT_B
	BNE.b	DialogState_SaveMenuInput_BackToChurch
	CheckButton BUTTON_BIT_C
	BEQ.b	DialogState_SaveMenuInput_HandleCursor
	JSR	SaveGameToSram
	JSR	RestoreShopSubmenuFromBuffer
	JSR	ResetScriptAndInitDialogue
	PRINT 	GameSavedStr
	MOVE.w	#DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD, Dialogue_state.w
	RTS

DialogState_SaveMenuInput_BackToChurch:
	JSR	RestoreShopSubmenuFromBuffer	
	JSR	DrawChurchMenuWindow	
	PlaySound SOUND_MENU_CURSOR	
	CLR.w	Church_service_selection.w	
	MOVE.w	#DIALOG_STATE_CHURCH_MENU_INPUT, Dialogue_state.w	
	RTS
	
DialogState_SaveMenuInput_HandleCursor:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
DialogState_SaveMenuInput_Return:
	RTS

; ---------------------------------------------------------------------------
; CheckIfCursed: Scan weapon + armor slots for any cursed item.
;
; Iterates Equipped_items (Equipped_sword, Equipped_shield, Equipped_armor —
; 3 entries × 1 word each) and tests bit 9 of each entry (the curse flag).
; Returns immediately on the first cursed item found.
;
; Input:  Equipped_items.w (3-entry word array)
; Output: D0 = $FFFF if a cursed item found, 0 if none
;         D3 = item word of the cursed item (if found)
; Scratch: D7, A0
; ---------------------------------------------------------------------------
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

; ---------------------------------------------------------------------------
; RemoveCursedEquipment: Clear all cursed items from the equipped slots and
; roll back the associated stat bonuses.
;
; Pass 1: Scan Equipped_items (3 words). For each item with bit 9 (curse) set:
;   - Set the equipped slot to $FFFF (empty).
;   - Look up stat modifier in EquipmentToStatModifierMap (indexed by low byte).
;   - If bit 10 set (sword type): subtract modifier from Player_str.
;   - Otherwise: subtract modifier from Player_ac.
;
; Pass 2: Scan Possessed_equipment_list for the same cursed item and clear its
;   bit 9 in the list entry (so it can be sold or re-equipped later).
;
; Input:  Equipped_items.w, Possessed_equipment_list.w
; Output: Equipped_items updated; Player_str or Player_ac decremented;
;         curse bit cleared in Possessed_equipment_list entry
; Scratch: D0, D1, D3, D7, A0, A1, A4
; ---------------------------------------------------------------------------
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

; ---------------------------------------------------------------------------
; CheckPlayerTalkToNPC: Search NPC/enemy object list for an NPC occupying
; the tile directly in front of the player, and initiate dialogue.
;
; Computes the target tile (player position + facing delta from
; TalkDirectionDeltaTable), then scans up to 30 live object slots
; (Enemy_list_ptr; bit 7 of first byte = active flag).
;
; For each active slot: converts obj_world_x/y (sub-pixel, >>4 = tile) and
; compares with the target tile. On match:
;   - Writes the appropriate NPC facing direction via NpcFacingDirectionLookup.
;   - Loads obj_npc_str_ptr into Script_source_base.
;   - Sets obj_vel_x to $FF (signals NPC is being talked to).
;   - Returns.
; If no matching NPC found: prints NoOneHereStr.
;
; Input:  Player_position_x/y_in_town.w, Player_direction.w, Enemy_list_ptr.w
; Output: Script_source_base.w loaded (on success); NPC object updated
; Scratch: D0, D1, D2, D7, A0, A1, A6
; ---------------------------------------------------------------------------
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

; ---------------------------------------------------------------------------
; FormatShopItemPrice: Build the BCD sell-price string for the currently
; highlighted sell-list item and write it into Text_build_buffer via A1.
;
; Uses Current_shop_type to pick ShopResaleValueMapPtrs (BCD price table)
; and ShopPossessionListPtrs (which possession list to index). The selected
; item's low byte is the item ID used as the price table index.
;
; Writes the ASCII price digits (via FormatKimsAmount) followed by SCRIPT_NEWLINE.
;
; Input:  Shop_selected_index.w, Current_shop_type.w, A1 = output ptr
; Output: Shop_sell_price.w = BCD price; A1 advanced; digits written to buffer
; Scratch: D0, A0, A2
; ---------------------------------------------------------------------------
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

; ---------------------------------------------------------------------------
; FormatKimsAmount: Convert a packed BCD kims value in D0 into ASCII decimal
; digits (leading-zero suppressed) and append them + " kims" to A1.
;
; D0 holds up to 6 BCD digits packed into 3 bytes (e.g. $012345 = 12,345 kims).
; The function rotates through 6 half-byte nibbles, skipping leading zeros,
; then writes each digit as ASCII ($30 + nibble), followed by " kims".
;
; Input:  D0 = BCD kims amount (24-bit, 6 BCD digits)
;         A1 = destination pointer into Text_build_buffer
; Output: A1 advanced past the written digits and " kims" suffix
; Scratch: D0, D1, D6, D7
; ---------------------------------------------------------------------------
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

; NpcFacingDirectionLookup: Maps player direction index (0-3) to the NPC
; facing direction value used when initiating talk. One byte per direction.
NpcFacingDirectionLookup:
	dc.b	$04, $06, $00, $02 
; FortuneTellerGreetingsByTown: Per-town function pointer table for the
; fortune teller opening greeting. One longword per town ID.
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
	dc.l	FortuneTellerGreeting_Swaffham	
	dc.l	FortuneTellerGreeting_Excalabria	
	dc.l	FortuneTellerGreeting_ExcalabriaCastle	
	dc.l	NpcDialog_NotHungryCantHelp	
	dc.l	NpcDialog_NotHungryCantHelp	
	dc.l	NpcDialog_MotherAwaits	
; FortuneTellerReadingsByTown: Per-town function pointer table for the
; fortune teller main reading/prophecy. One longword per town ID.
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
	dc.l	FortuneTellerGreeting_Swaffham
	dc.l	FortuneTellerGreeting_Excalabria
	dc.l	FortuneTellerGreeting_ExcalabriaCastle	
	dc.l	NpcDialog_FindRingsInCartahena	
	dc.l	NpcDialog_FindRingsInCartahena	
	dc.l	NpcDialog_MotherAwaits	

; ---------------------------------------------------------------------------
; Ready Equipment State Machine
; ---------------------------------------------------------------------------
; Dispatches on Ready_equipment_state.w (low 5 bits), jumping through
; ReadyEquipmentStateJumpTable (BRA.w entries, 4 bytes each).
;
; State map:
;   0 = Init          — draw equipment menu, reset cursor
;   1 = WaitInput     — handle B/C on weapon/shield/armor choice
;   2 = ShowList      — wait for window, handle select/cancel for unequip
;   3 = WaitListInput — wait script, handle equip list selection
;   4 = ShowCatA      — unequip flow for weapon slot
;   5 = ShowCatB      — unequip flow (shared handler ShowCategory)
;   6 = WaitDraw      — wait for window then exit
;   7 = ShowCatC      — equip flow (shared handler ShowCategory)
;
; Register conventions inside the state handlers:
;   D0 = state index / item ID / scratch
;   D1 = equipment ID / stat modifier index
;   D2 = old equipped item ID / scratch
;   D6 = saved old equipment ID (for swap)
;   A0 = jump table / equipment name table / stat modifier table
;   A2 = Equipped_items / Possessed_equipment_list pointer
; ---------------------------------------------------------------------------
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
	BRA.w	ReadyEquipmentStateJumpTable_WaitInput
	BRA.w	ReadyEquipmentMenu_Done_Loop
	BRA.w	ReadyEquipmentMenu_Done_WaitInput
	BRA.w	ReadyEquipmentState_ShowCategory	
	BRA.w	ReadyEquipmentState_ShowCategory
	BRA.w	ReadyEquipmentState_ShowCategory_WaitDraw
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

ReadyEquipmentStateJumpTable_WaitInput:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	ReadyEquipmentMenu_Done
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	ReadyEquipmentMenu_Done
	CheckButton BUTTON_BIT_B
	BNE.b	ReadyEquip_ConfirmAndSetState
	CheckButton BUTTON_BIT_C
	BNE.b	ReadyEquip_ConfirmAndSetState_SelectItem
	MOVE.w	Ready_equipment_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Ready_equipment_selection.w
	RTS

ReadyEquip_ConfirmAndSetState:
	PlaySound SOUND_MENU_CANCEL
	TriggerWindowRedraw WINDOW_DRAW_STATUS_MENU
	MOVE.w	#OVERWORLD_MENU_STATE_OPTIONS_WAIT, Overworld_menu_state.w
	JSR	InitMenuCursorDefaults
	RTS
	
ReadyEquip_ConfirmAndSetState_SelectItem:
	MOVE.w	Ready_equipment_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	MOVE.w	Ready_equipment_selection.w, D0
	CMPI.w	#2, D0
	BEQ.b	ReadyEquip_ConfirmAndSetState
	PlaySound SOUND_MENU_SELECT
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
	BNE.w	ReadyEquipmentMenu_Done_WaitDraw
	CheckButton BUTTON_BIT_B
	BNE.b	ReadyEquipmentMenu_Done_CancelToEquipMenu
	CheckButton BUTTON_BIT_C
	BNE.b	ReadyEquipmentMenu_Done_ConfirmSelection
	MOVE.w	Ready_equipment_category.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Ready_equipment_category.w
	RTS

ReadyEquipmentMenu_Done_CancelToEquipMenu:
	PlaySound SOUND_MENU_CANCEL
	JSR	RestoreRightMenuFromBuffer
	JSR	DrawEquipmentMenuWindow
	MOVE.w	#READY_EQUIP_STATE_WAIT, Ready_equipment_state.w
	RTS

ReadyEquipmentMenu_Done_ConfirmSelection:
	MOVE.w	Ready_equipment_category.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	PlaySound SOUND_MENU_SELECT
	BSR.w	BuildEquipmentListForCategory
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	TST.w	Ready_equipment_list_length.w
	BLE.b	ReadyEquipmentMenu_Done_NothingAvailable
	JSR	SaveReadyEquipmentMenuToBuffer
	JSR	DrawReadyEquipmentMenuBorders
	JSR	DrawReadyEquipmentList
	PRINT 	ReadyPromptStr
	MOVE.w	#READY_EQUIP_STATE_LIST_WAIT, Ready_equipment_state.w
	CLR.w	Ready_equipment_cursor_index.w
	RTS

ReadyEquipmentMenu_Done_NothingAvailable:
	PRINT 	ProperEquipmentStr
	MOVE.w	#READY_EQUIP_STATE_RESULT_MSG, Ready_equipment_state.w
ReadyEquipmentMenu_Done_WaitDraw:
	RTS

ReadyEquipmentMenu_Done_WaitInput:
	TST.b	Script_text_complete.w
	BEQ.w	ReadyEquip_CursedReturn_ProcessText
	CheckButton BUTTON_BIT_B
	BNE.b	ReadyEquipmentMenu_Done_CancelAndRestore
	CheckButton BUTTON_BIT_C
	BNE.b	ReadyEquipmentMenu_Done_ConfirmEquip
	MOVE.w	Ready_equipment_cursor_index.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Ready_equipment_cursor_index.w
	RTS

ReadyEquipmentMenu_Done_CancelAndRestore:
	PlaySound SOUND_MENU_CANCEL
	JSR	RestoreReadyEquipmentMenuFromBuffer
	JSR	DrawStatusHudWindow
	JSR	RestoreRightMenuFromBuffer
	JSR	DrawEquipmentMenuWindow
	MOVE.w	#READY_EQUIP_STATE_WAIT, Ready_equipment_state.w
	RTS

; ---------------------------------------------------------------------------
; ReadyEquipmentMenu_Done_ConfirmEquip: Process equip confirmation (C button).
;
; Called when the player presses C on a highlighted equipment item. Behavior:
;
;   No item currently equipped in slot (GetCurrentEquippedItemID returns < 0):
;     - EquipSelectedItem, apply stat bonus (EquipStatAddJumpTable),
;       print "readied <name>" message. → READY_EQUIP_STATE_RESULT_MSG
;
;   Slot already has a different item (GetCurrentEquippedItemID returns ≥ 0):
;     - Print "already readied" message.
;     - If existing item is cursed (bit 9): print ExchangeCursedStr → can't swap.
;     - Otherwise: call ClearEquipmentCursedFlag, remove old stat
;       (EquipStatRemoveJumpTable), add new stat (EquipStatAddJumpTable),
;       print "removed <old> and readied <new>" message, EquipSelectedItem.
;
;   Same item already equipped: go to ReadyEquipmentMenu_Done_DoEquip (re-equip).
;
; In all cases: restores the equip menu buffer and sets READY_EQUIP_STATE_RESULT_MSG.
;
; Input:  Ready_equipment_cursor_index.w, Ready_equipment_category.w,
;         Equipped_sword/shield/armor.w
; Output: Equipment slot updated; stats adjusted; Text_build_buffer built;
;         Ready_equipment_state.w = READY_EQUIP_STATE_RESULT_MSG
; Scratch: D0, D1, D2, D6, A0, A1
; ---------------------------------------------------------------------------
ReadyEquipmentMenu_Done_ConfirmEquip:
	MOVE.w	Ready_equipment_cursor_index.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	PlaySound SOUND_MENU_SELECT
	JSR	ResetScriptAndInitDialogue
	BSR.w	GetCurrentEquippedItemID
	TST.w	D0
	BGE.w	ReadyEquipmentMenu_Done_AlreadyEquipped
	BSR.w	EquipSelectedItem
	BSR.w	CopyPlayerNameToTextBuffer
	BSR.w	GetSelectedEquipmentID
	MOVE.w	#9, D2
	BTST.l	D2, D1
	BNE.w	ReadyEquipmentMenu_Done_CursedEquip
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

ReadyEquipmentMenu_Done_AlreadyEquipped:
	PRINT 	AlreadyReadiedStr
	BSR.w	GetSelectedEquipmentID
	CMP.b	D0, D1
	BEQ.w	ReadyEquipmentMenu_Done_DoEquip
	MOVE.w	#9, D2
	BTST.l	D2, D0
	BNE.w	ReadyEquipmentMenu_Done_CursedSwap
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
ReadyEquipmentMenu_Done_DoEquip:
	BSR.w	EquipSelectedItem
	BRA.b	ReadyEquip_CursedReturn
ReadyEquipmentMenu_Done_CursedSwap:
	PRINT 	ExchangeCursedStr
	BRA.b	ReadyEquip_CursedReturn
ReadyEquipmentMenu_Done_CursedEquip:
	PRINT 	CursedStr
ReadyEquip_CursedReturn:
	MOVE.w	#READY_EQUIP_STATE_RESULT_MSG, Ready_equipment_state.w
	JSR	RestoreReadyEquipmentMenuFromBuffer
	RTS

ReadyEquip_CursedReturn_ProcessText:
	JSR	ProcessScriptText
	RTS

ReadyEquipmentState_ShowCategory:
	CheckButton BUTTON_BIT_B
	BNE.b	ReadyEquipmentState_ShowCategory_CancelToEquipMenu
	CheckButton BUTTON_BIT_C
	BNE.b	ReadyEquipmentState_ShowCategory_ConfirmUnequip
	MOVE.w	Ready_equipment_category.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Ready_equipment_category.w
	RTS

ReadyEquipmentState_ShowCategory_CancelToEquipMenu:
	PlaySound SOUND_MENU_CANCEL	
	JSR	RestoreRightMenuFromBuffer	
	JSR	DrawEquipmentMenuWindow	
	MOVE.w	#READY_EQUIP_STATE_WAIT, Ready_equipment_state.w	
	RTS
	
ReadyEquipmentState_ShowCategory_ConfirmUnequip:
	MOVE.w	Ready_equipment_category.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	PlaySound SOUND_MENU_SELECT
	BSR.w	BuildEquipmentListForCategory
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	BSR.w	GetCurrentEquippedItemID
	TST.w	D0
	BLT.w	ReadyEquipmentState_ShowCategory_NothingEquipped
	MOVE.w	#9, D1
	BTST.l	D1, D0
	BNE.w	ReadyEquipmentState_ShowCategory_CursedUnequip
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

ReadyEquipmentState_ShowCategory_NothingEquipped:
	PRINT 	NothingToUseStr
	MOVE.w	#READY_EQUIP_STATE_RESULT_MSG, Ready_equipment_state.w
	RTS

ReadyEquipmentState_ShowCategory_CursedUnequip:
	PRINT 	DropCursedStr	
	MOVE.w	#READY_EQUIP_STATE_RESULT_MSG, Ready_equipment_state.w	
	RTS
	
ReadyEquipmentState_ShowCategory_WaitDraw:
	TST.b	Script_text_complete.w
	BEQ.b	ReadyEquip_ExitToHud_ProcessText
	CheckButton BUTTON_BIT_C
	BNE.b	ReadyEquip_ExitToHud
	CheckButton BUTTON_BIT_B
	BNE.b	ReadyEquip_ExitToHud
	RTS

ReadyEquip_ExitToHud:
	JSR	DrawStatusHudWindow
	JSR	RestoreRightMenuFromBuffer
	JSR	DrawEquipmentMenuWindow
	MOVE.w	#READY_EQUIP_STATE_WAIT, Ready_equipment_state.w
	RTS

ReadyEquip_ExitToHud_ProcessText:
	JSR	ProcessScriptText
	RTS

; ---------------------------------------------------------------------------
; EquipStatAddJumpTable: Apply stat bonus for the selected equipment category.
;   Entry 0 (offset 0): sword   — add modifier to Player_str
;   Entry 1 (offset 4): shield  — add modifier to Player_ac
;   Entry 2 (offset 8): armor   — add modifier to Player_ac (shared)
;   Entry 3 (offset C): ring    — add modifier to Player_ac (shared)
;
; Input:  D1 = equipment item word (low byte = item ID for modifier lookup)
;         Ready_equipment_category.w selects the entry (0-3)
; ---------------------------------------------------------------------------
EquipStatAddJumpTable:
	BRA.w	EquipStatAddJumpTable_AddStrBonus
	BRA.w	EquipStatAddJumpTable_AddAcBonus
	BRA.w	EquipItem_AddAcBonus
	BRA.w	EquipItem_AddAcBonus	
EquipStatAddJumpTable_AddStrBonus:
	LEA	EquipmentToStatModifierMap, A0
	ANDI.w	#$00FF, D1
	ADD.w	D1, D1
	MOVE.w	Player_str.w, D0
	ADD.w	(A0,D1.w), D0
	ANDI.w	#$7FFF, D0
	MOVE.w	D0, Player_str.w
	RTS

EquipStatAddJumpTable_AddAcBonus:
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

; ---------------------------------------------------------------------------
; EquipStatRemoveJumpTable: Reverse the stat bonus for the previously equipped
; item when swapping or unequipping. Mirror of EquipStatAddJumpTable.
;   Entry 0: sword  — subtract modifier from Player_str
;   Entry 1: shield — subtract modifier from Player_ac
;   Entry 2: armor  — subtract modifier from Player_ac (shared)
;   Entry 3: ring   — subtract modifier from Player_ac (shared)
;
; Input:  D6 = old equipment item word (low byte = item ID)
;         Ready_equipment_category.w selects the entry (0-3)
; ---------------------------------------------------------------------------
EquipStatRemoveJumpTable:
	BRA.w	EquipStatRemoveJumpTable_SubStrBonus
	BRA.w	EquipStatRemoveJumpTable_SubAcBonus
	BRA.w	UnequipItem_SubAcBonus
	BRA.w	UnequipItem_SubAcBonus	
EquipStatRemoveJumpTable_SubStrBonus:
	LEA	EquipmentToStatModifierMap, A0
	ANDI.w	#$00FF, D6
	ADD.w	D6, D6
	MOVE.w	Player_str.w, D0
	SUB.w	(A0,D6.w), D0
	ANDI.w	#$7FFF, D0
	MOVE.w	D0, Player_str.w
	RTS

EquipStatRemoveJumpTable_SubAcBonus:
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

; ---------------------------------------------------------------------------
; UnequipItemByID: Find item D0 in Possessed_equipment_list and clear bit 15
; (equipped marker) on the matching entry, marking it as unequipped.
;
; Input:  D0 = item ID (low byte comparison)
; Output: Matching Possessed_equipment_list entry has bit 15 cleared
; Scratch: D1, D7, A1
; ---------------------------------------------------------------------------
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

; ---------------------------------------------------------------------------
; BuildEquipmentListForCategory: Filter Possessed_equipment_list into
; Ready_equipment_list keeping only items that match the selected equip slot.
;
; The category bit tested is (Ready_equipment_category + 10): bit 10 = sword,
; bit 11 = shield, bit 12 = armor. Each possessed equipment word has the
; corresponding bit set by the item type.
;
; Input:  Ready_equipment_category.w (0=sword, 1=shield, 2=armor)
;         Possessed_equipment_list.w / Possessed_equipment_length.w
; Output: Ready_equipment_list.w filled; Ready_equipment_list_length.w updated
; Scratch: D0, D1, D2, D7, A1, A2
; ---------------------------------------------------------------------------
BuildEquipmentListForCategory:
	MOVE.w	Ready_equipment_category.w, D0
	ADDI.w	#$000A, D0
	CLR.w	D2
	LEA	Ready_equipment_list.w, A2
	LEA	Possessed_equipment_length.w, A1
	MOVE.w	(A1)+, D7
	BLE.b	BuildEquipmentListForCategory_StoreLength
	SUBQ.w	#1, D7
BuildEquipmentListForCategory_CheckSlot:
	MOVE.w	(A1)+, D1
	BTST.l	D0, D1
	BEQ.b	BuildEquipmentListForCategory_NextSlot
	MOVE.w	D1, (A2)+
	ADDQ.w	#1, D2
BuildEquipmentListForCategory_NextSlot:
	DBF	D7, BuildEquipmentListForCategory_CheckSlot
BuildEquipmentListForCategory_StoreLength:
	MOVE.w	D2, Ready_equipment_list_length.w
	RTS

; ---------------------------------------------------------------------------
; GetCurrentEquippedItemID: Read the item word currently in the equipped slot
; for the active category (sword / shield / armor).
;
; Input:  Ready_equipment_category.w (0=sword, 1=shield, 2=armor)
; Output: D0 = word at Equipped_items + (category*2); $FFFF if slot empty
; ---------------------------------------------------------------------------
GetCurrentEquippedItemID:
	MOVE.w	Ready_equipment_category.w, D0
	ADD.w	D0, D0
	LEA	Equipped_items.w, A2
	MOVE.w	(A2,D0.w), D0
	RTS

; ---------------------------------------------------------------------------
; GetSelectedEquipmentID: Return the item word for the currently highlighted
; entry in Ready_equipment_list, with bit 15 (equipped marker) cleared.
;
; Input:  Ready_equipment_cursor_index.w
; Output: D1 = item word & $7FFF
; ---------------------------------------------------------------------------
GetSelectedEquipmentID:
	MOVE.w	Ready_equipment_cursor_index.w, D1
	ADD.w	D1, D1
	LEA	Ready_equipment_list.w, A2
	MOVE.w	(A2,D1.w), D1
	ANDI.w	#$7FFF, D1
	RTS

; ---------------------------------------------------------------------------
; EquipSelectedItem: Write the selected item into the equipped slot and set
; bit 15 (equipped marker) in the Possessed_equipment_list entry.
;
; Calls GetSelectedEquipmentID internally to get D1.
; Input:  Ready_equipment_category.w, Ready_equipment_cursor_index.w
; Output: Equipped_items slot updated; equipped marker set in possession list
; Scratch: D1, D2, D3, D7, A2
; ---------------------------------------------------------------------------
EquipSelectedItem:
	BSR.b	GetSelectedEquipmentID
	MOVE.w	Ready_equipment_category.w, D2
	ADD.w	D2, D2
	LEA	Equipped_items.w, A2
	MOVE.w	D1, (A2,D2.w)
	LEA	Possessed_equipment_list.w, A2
	MOVE.w	Possessed_equipment_length.w, D7
EquipSelectedItem_CheckSlot:
	MOVE.w	(A2)+, D3
	CMP.b	D3, D1
	BNE.b	EquipSelectedItem_NextSlot
	ORI.w	#$8000, D3
	MOVE.w	D3, -$2(A2)
	BRA.b	EquipSelectedItem_Return
EquipSelectedItem_NextSlot:
	DBF	D7, EquipSelectedItem_CheckSlot
EquipSelectedItem_Return:
	RTS

; ---------------------------------------------------------------------------
; ClearEquipmentCursedFlag: Find the currently equipped item (D0 = item ID)
; in Possessed_equipment_list and clear bit 9 (curse flag), leaving bit 15
; (equipped marker) intact, so the item can be re-examined or re-equipped.
;
; Input:  D0 = item ID to find (low byte compared against list entries)
; Output: Matching list entry has bit 9 cleared
; Scratch: D3, D4, D7, A0
; ---------------------------------------------------------------------------
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

; ---------------------------------------------------------------------------
; CopyPlayerNameToTextBuffer: Copy the null-terminated player name string
; from Player_name into Text_build_buffer (via A1), appending a space.
;
; Input:  Player_name.w (null-terminated ASCII)
; Output: A1 advanced; name + ' ' written to Text_build_buffer
; ---------------------------------------------------------------------------
CopyPlayerNameToTextBuffer:
	LEA	Player_name.w, A0
	LEA	Text_build_buffer.w, A1
	JSR	CopyStringUntilFF
	MOVE.b	#$20, (A1)+
	RTS

; ---------------------------------------------------------------------------
; CopyEquipmentNameToTextBuffer: Copy the name string for equipment item D2
; (low byte = item ID) from EquipmentNames pointer table into Text_build_buffer
; starting at A1.
;
; Input:  D2 = equipment item word (low byte = item ID); A1 = output ptr
; Output: A1 advanced past the copied name
; ---------------------------------------------------------------------------
CopyEquipmentNameToTextBuffer:
	LEA	EquipmentNames, A2
	ANDI.w	#$00FF, D2
	ADD.w	D2, D2
	ADD.w	D2, D2
	MOVEA.l	(A2,D2.w), A0
	JSR	CopyStringUntilFF
	RTS

; ---------------------------------------------------------------------------
; Equip List Menu State Machine
; ---------------------------------------------------------------------------
; Dispatches on Equip_list_menu_state.w (low 4 bits), jumping through
; EquipListMenuStateJumpTable (BRA.w entries, 4 bytes each).
;
; This machine drives the multi-page character sheet (C button cycles forward
; through pages; B button goes back one page or exits):
;
;   State  0 = Init         — draw stats window, advance cursor
;   State  1 = StatsWait    — wait draw, handle B (exit) / C (next)
;   State  2 = GearPage     — show equipped gear window
;   State  3 = CombatPage   — show combat stats window
;   State  4 = MagicPage    — show magic list window
;   State  5 = ItemsPage    — show items window
;   State  6 = RingsPage    — show rings window
;   State  7 = StatusPage   — auto-cycles back to exit (no input)
;   State  8 = WindowWait   — wait for window draw then restore menu cursor
;   State  9 = CursorItem   — restore item-page window redraw
;   State 10 = CursorMagic  — restore magic-page window redraw
;   State 11 = CursorEquip  — restore equip-list window redraw
;   State 12 = CursorFull   — restore full-menu window redraw
;   State 13 = ExitScript   — trigger WINDOW_DRAW_SCRIPT and exit
;
; Register conventions: same as ReadyEquipmentStateMachine above.
; ---------------------------------------------------------------------------
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
	BRA.w	EquipListMenuStateJumpTable_WaitInput
	BRA.w	EquipListMenu_DrawGear_Return_Loop
	BRA.w	EquipListMenu_DrawCombat_Return_Loop
	BRA.w	EquipListMenu_DrawMagic_Return_Loop
	BRA.w	EquipListMenu_DrawItems_Return_Loop
	BRA.w	EquipListMenu_DrawRings_Return_Loop
	BRA.w	EquipListMenu_DrawStatus_Return_Loop	
	BRA.w	EquipListMenu_DrawWindow_Return_Loop
	BRA.w	EquipListMenu_CursorReady_Return_ToItemPage
	BRA.w	EquipListMenu_CursorReady_Return_ToMagicPage
	BRA.w	EquipListMenu_CursorReady_Return_ToEquipPage
	BRA.w	EquipListMenu_CursorReady_Return_ToFullPage
	BRA.w	EquipListMenu_CursorReady_Return_ToScript
EquipListMenuStateJumpTable_Loop:
	MOVE.w	Main_menu_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	PlaySound SOUND_MENU_CURSOR
	JSR	SaveFullDialogAreaToBuffer
	JSR	DrawCharacterStatsWindow
	ADDQ.w	#1, Equip_list_menu_state.w
	RTS

EquipListMenuStateJumpTable_WaitInput:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	EquipListMenu_DrawGear_Return
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_DrawGear_Return
	CheckButton BUTTON_BIT_C
	BNE.w	EquipListMenuStateJumpTable_ShowGearPage
	CheckButton BUTTON_BIT_B
	BNE.w	EquipListMenuStateJumpTable_CancelToScript
	RTS

EquipListMenuStateJumpTable_CancelToScript:
	PlaySound SOUND_MENU_CANCEL
	MOVE.w	#EQUIP_LIST_STATE_EXIT_SCRIPT, Equip_list_menu_state.w
	TriggerWindowRedraw WINDOW_DRAW_SCRIPT
	RTS

EquipListMenuStateJumpTable_ShowGearPage:
	PlaySound SOUND_MENU_CURSOR
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
	CheckButton BUTTON_BIT_C
	BNE.w	EquipListMenu_DrawGear_Return_ShowCombatPage
	CheckButton BUTTON_BIT_B
	BNE.w	EquipListMenu_DrawGear_Return_CancelToStats
	RTS

EquipListMenu_DrawGear_Return_CancelToStats:
	PlaySound SOUND_MENU_CANCEL
	TriggerWindowRedraw_alt WINDOW_DRAW_FULL_MENU
	MOVE.w	#EQUIP_LIST_STATE_STATS_WAIT, Equip_list_menu_state.w
	RTS

EquipListMenu_DrawGear_Return_ShowCombatPage:
	PlaySound SOUND_MENU_CURSOR
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
	CheckButton BUTTON_BIT_C
	BNE.w	EquipListMenu_DrawCombat_Return_ShowMagicPage
	CheckButton BUTTON_BIT_B
	BNE.w	EquipListMenu_DrawCombat_Return_CancelToGear
	RTS

EquipListMenu_DrawCombat_Return_CancelToGear:
	PlaySound SOUND_MENU_CANCEL
	TriggerWindowRedraw_alt WINDOW_DRAW_EQUIP_LIST
	MOVE.w	#EQUIP_LIST_STATE_GEAR_PAGE, Equip_list_menu_state.w
	RTS

EquipListMenu_DrawCombat_Return_ShowMagicPage:
	PlaySound SOUND_MENU_CURSOR
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
	CheckButton BUTTON_BIT_C
	BNE.w	EquipListMenu_DrawMagic_Return_ShowItemsPage
	CheckButton BUTTON_BIT_B
	BNE.w	EquipListMenu_DrawMagic_Return_CancelToCombat
	RTS

EquipListMenu_DrawMagic_Return_CancelToCombat:
	PlaySound SOUND_MENU_CANCEL
	TriggerWindowRedraw_alt WINDOW_DRAW_MAGIC_LIST
	MOVE.w	#EQUIP_LIST_STATE_COMBAT_PAGE, Equip_list_menu_state.w
	RTS

EquipListMenu_DrawMagic_Return_ShowItemsPage:
	PlaySound SOUND_MENU_CURSOR
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
	CheckButton BUTTON_BIT_C
	BNE.w	EquipListMenu_DrawItems_Return_ShowRingsPage
	CheckButton BUTTON_BIT_B
	BNE.w	EquipListMenu_DrawItems_Return_CancelToMagic
	RTS

EquipListMenu_DrawItems_Return_CancelToMagic:
	PlaySound SOUND_MENU_CANCEL
	TriggerWindowRedraw_alt WINDOW_DRAW_ITEM_RIGHT
	MOVE.w	#EQUIP_LIST_STATE_MAGIC_PAGE, Equip_list_menu_state.w
	RTS

EquipListMenu_DrawItems_Return_ShowRingsPage:
	PlaySound SOUND_MENU_CURSOR
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
	CheckButton BUTTON_BIT_C
	BNE.w	EquipListMenu_DrawRings_Return_ShowCursorInit
	CheckButton BUTTON_BIT_B
	BNE.w	EquipListMenu_DrawRings_Return_CancelToItems
	RTS

EquipListMenu_DrawRings_Return_ShowCursorInit:
	MOVE.w	#EQUIP_LIST_STATE_CURSOR_INIT, Equip_list_menu_state.w
	BRA.w	EquipListMenu_DrawRings_Return_CancelAndRedraw
EquipListMenu_DrawRings_Return_CancelToItems:
	MOVE.w	#EQUIP_LIST_STATE_ITEMS_PAGE, Equip_list_menu_state.w
EquipListMenu_DrawRings_Return_CancelAndRedraw:
	PlaySound SOUND_MENU_CANCEL
	TriggerWindowRedraw_alt WINDOW_DRAW_RING_LIST
EquipListMenu_DrawStatus_Return:
	RTS

EquipListMenu_DrawStatus_Return_Loop:
	TST.b	Window_tilemap_draw_active.w	
	BNE.w	EquipListMenu_DrawWindow_Return	
	TST.b	Window_tilemap_row_draw_pending.w	
	BNE.w	EquipListMenu_DrawWindow_Return	
	PlaySound SOUND_MENU_CANCEL	
	MOVE.w	#EQUIP_LIST_STATE_EXIT_SCRIPT, Equip_list_menu_state.w	
	TriggerWindowRedraw WINDOW_DRAW_SCRIPT
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

EquipListMenu_CursorReady_Return_ToItemPage:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_CursorReady_Return_WaitItem
	PlaySound SOUND_MENU_CANCEL
	TriggerWindowRedraw_alt WINDOW_DRAW_ITEM_RIGHT
	MOVE.w	#EQUIP_LIST_STATE_CURSOR_ITEM, Equip_list_menu_state.w
EquipListMenu_CursorReady_Return_WaitItem:
	RTS

EquipListMenu_CursorReady_Return_ToMagicPage:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_CursorReady_Return_WaitMagic
	PlaySound SOUND_MENU_CANCEL
	TriggerWindowRedraw_alt WINDOW_DRAW_MAGIC_LIST
	MOVE.w	#EQUIP_LIST_STATE_CURSOR_MAGIC, Equip_list_menu_state.w
EquipListMenu_CursorReady_Return_WaitMagic:
	RTS
EquipListMenu_CursorReady_Return_ToEquipPage:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_CursorReady_Return_WaitEquip
	PlaySound SOUND_MENU_CANCEL
	TriggerWindowRedraw_alt WINDOW_DRAW_EQUIP_LIST
	MOVE.w	#EQUIP_LIST_STATE_CURSOR_EQUIP, Equip_list_menu_state.w
EquipListMenu_CursorReady_Return_WaitEquip:
	RTS
EquipListMenu_CursorReady_Return_ToFullPage:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_CursorReady_Return_WaitFull
	PlaySound SOUND_MENU_CANCEL
	TriggerWindowRedraw_alt WINDOW_DRAW_FULL_MENU
	MOVE.w	#EQUIP_LIST_STATE_CURSOR_FULL, Equip_list_menu_state.w
EquipListMenu_CursorReady_Return_WaitFull:
	RTS
EquipListMenu_CursorReady_Return_ToScript:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	EquipListMenu_CursorReady_Return_WaitScript
	PlaySound SOUND_MENU_CANCEL
	MOVE.w	#EQUIP_LIST_STATE_EXIT_SCRIPT, Equip_list_menu_state.w
	TriggerWindowRedraw WINDOW_DRAW_SCRIPT
EquipListMenu_CursorReady_Return_WaitScript:
	RTS

; ---------------------------------------------------------------------------
; Level-Up Stat Upgrade
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
; UpgradeLevelStats: Apply randomised stat gains on level-up.
;
; Looks up the player's current level (Player_level) in each per-stat level
; table (PlayerLevelToStrMap, LukMap, DexMap, AcMap, IntMap, MmpMap, MhpMap)
; to get a base increment. Adds a random 0–3 bonus (GetRandomNumber & 3) to
; each stat. Caps each stat at its corresponding MAX_PLAYER_* constant.
;
; Stat sequence: STR → LUK → DEX → AC → INT → MMP (sets Player_mp) →
;                MHP (sets Player_hp) → experience threshold update.
;
; Also looks up PlayerLevelToNextLevelExperienceMap to set the XP threshold
; for the new level.
;
; Input:  Player_level.w, PlayerLevel*Map tables, GetRandomNumber
; Output: Player_str/luk/dex/ac/int/mmp/mhp/hp/mp updated; XP threshold set
; Scratch: D0, D1, D7, A0
; ---------------------------------------------------------------------------
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
	BLE.b	UpgradeLevelStats_CapLuk
	MOVE.w	#MAX_PLAYER_STR, Player_str.w	
UpgradeLevelStats_CapLuk:
	LEA	PlayerLevelToLukMap, A0
	MOVE.w	(A0,D7.w), D1
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	ADD.w	D0, D1
	ADD.w	D1, Player_luk.w
	CMPI.w	#MAX_PLAYER_LUK, Player_luk.w
	BLE.b	UpgradeLevelStats_CapDex
	MOVE.w	#MAX_PLAYER_LUK, Player_luk.w	
UpgradeLevelStats_CapDex:
	LEA	PlayerLevelToDexMap, A0
	MOVE.w	(A0,D7.w), D1
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	ADD.w	D0, D1
	ADD.w	D1, Player_dex.w
	CMPI.w	#MAX_PLAYER_DEX, Player_dex.w
	BLE.b	UpgradeLevelStats_CapAc
	MOVE.w	#MAX_PLAYER_DEX, Player_dex.w	
UpgradeLevelStats_CapAc:
	LEA	PlayerLevelToAcMap, A0
	MOVE.w	(A0,D7.w), D1
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	ADD.w	D0, D1
	ADD.w	D1, Player_ac.w
	CMPI.w	#MAX_PLAYER_AC, Player_ac.w
	BLE.b	UpgradeLevelStats_CapInt
	MOVE.w	#MAX_PLAYER_AC, Player_ac.w	
UpgradeLevelStats_CapInt:
	LEA	PlayerLevelToIntMap, A0
	MOVE.w	(A0,D7.w), D1
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	ADD.w	D0, D1
	ADD.w	D1, Player_int.w
	CMPI.w	#MAX_PLAYER_INT, Player_int.w
	BLE.b	UpgradeLevelStats_CapMmp
	MOVE.w	#MAX_PLAYER_INT, Player_int.w	
UpgradeLevelStats_CapMmp:
	LEA	PlayerLevelToMmpMap, A0
	MOVE.w	(A0,D7.w), D1
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	ADD.w	D0, D1
	ADD.w	D1, Player_mmp.w
	CMPI.w	#MAX_PLAYER_MMP, Player_mmp.w
	BLE.b	UpgradeLevelStats_ApplyMhp
	MOVE.w	#MAX_PLAYER_MMP, Player_mmp.w
UpgradeLevelStats_ApplyMhp:
	MOVE.w	Player_mmp.w, Player_mp.w
	LEA	PlayerLevelToMhpMap, A0
	MOVE.w	(A0,D7.w), D1
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	ADD.w	D0, D1
	ADD.w	D1, Player_mhp.w
	CMPI.w	#MAX_PLAYER_MHP, Player_mhp.w
	BLE.b	UpgradeLevelStats_CapMhp
	MOVE.w	#MAX_PLAYER_MHP, Player_mhp.w	
UpgradeLevelStats_CapMhp:
	MOVE.w	Player_mhp.w, Player_hp.w
	ADD.w	D7, D7
	LEA	PlayerLevelToNextLevelExperienceMap, A0
	MOVE.l	(A0,D7.w), Player_next_level_experience.w
	RTS

; ============================================================================
; Chest/Door Opening State Machine
; ============================================================================
; Handles player interaction with treasure chests and doors via Open command.
; Uses a multi-state system to manage detection, animation, and reward display.
;
; Dispatched via ChestOpenStateJumpTable (7 BRA.w entries):
;   State 0: ChestOpenStateJumpTable_FirstPersonCheck / TopDownOpen
;              — GetTileInFrontOfPlayer, look up in chest data table
;   State 1: OpenMenu_ShowMessage_Init — show locked/empty/already-open message
;   State 2: OpenChestMenu_ExitToHud  — close window and return to HUD
;   State 3: ChestAnimation_Return    — run the tile-flip chest-open animation
;   State 4: ChestAnimation_Return_WaitDelay — frame delay before opening
;   State 5: ChestAnimation_Return_OpenDelay — delay after lid opens
;   State 6: ChestAnimation_Return_ShowContents — display item/gold reward
;
; In first-person mode (Player_in_first_person_mode ≠ 0): drops through to
; ChestOpeningStateMachine_Loop (no-op, cannot open chests in first person).
;
; Input:  Open_menu_state.w (4-bit state index), Player_in_first_person_mode.w
; Output: Chest tile flipped to opened; item/gold reward added to inventory;
;         Open_menu_state.w advanced through states
; Scratch: D0, D7, A0
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
	BRA.w	OpenMenu_ShowMessage_Init_WaitInput            ; State 1: Message wait
	BRA.w	OpenChestMenu_ExitToHud_Loop            ; State 2: Close
	BRA.w	OpenChestMenu_ExitToHud_Animate            ; State 3: Animation
	BRA.w	ChestAnimation_Return_Loop            ; State 4: Tile delay
	BRA.w	ChestAnimation_Return_OpenDelay            ; State 5: Open delay
	BRA.w	ChestAnimation_Return_ShowContents            ; State 6: Contents
	
; State 0: Initial detection
ChestOpenStateJumpTable_Loop:
	MOVE.w	Main_menu_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	TST.b	Player_in_first_person_mode.w
	BNE.w	ChestOpenStateJumpTable_FirstPersonCheck             ; First-person: check sprite
	
	; Top-down: Check tile type
	JSR	GetTileInFrontOfPlayer             ; Get tile in front of player
	CMPI.w	#TOWN_TILE_CHEST, D0               ; Chest tile?
	BEQ.w	ChestOpenStateJumpTable_TopDownOpen             ; Yes: play sound, advance
	BRA.w	OpenChestMenu_CheckChest             ; No: check chest sprite
	
	; First-person: Check chest sprite
ChestOpenStateJumpTable_FirstPersonCheck:
	TST.b	Chest_already_opened.w       ; Already opened?
	BNE.w	OpenChestMenu_CheckChest_AlreadyOpen             ; Yes: "Already open"
	LEA	FpDirectionDeltaForward, A0
	JSR	GetMapTileInDirection             ; Search for object
	CMPI.b	#6, D0                   ; Type 6 = chest sprite?
	BNE.w	OpenChestMenu_CheckChest
	BSR.w	CheckIfDoorIsLocked             ; Check if locked
	TST.b	Door_unlocked_flag.w
	BEQ.w	OpenChestMenu_CheckChest_Locked             ; Locked
	
	; Start opening animation
	CLR.w	Chest_animation_frame.w
	CLR.w	Chest_animation_timer.w
	PlaySound SOUND_CHEST_RATTLE
	MOVE.w	#OPEN_MENU_STATE_ANIMATION, Open_menu_state.w    ; State 3: Animation
	TriggerWindowRedraw WINDOW_DRAW_MSG_SPEED_ALT
	RTS
	
ChestOpenStateJumpTable_TopDownOpen:
	PlaySound_b SOUND_CHEST_OPEN	
	MOVE.b	#CHEST_OPEN_DELAY_FRAMES, Open_chest_delay_timer.w	
	MOVE.w	#OPEN_MENU_STATE_TILE_DELAY, Open_menu_state.w	
	RTS
	
OpenChestMenu_CheckChest:
	TST.b	Reward_script_active.w              ; Chest present?
	BEQ.w	OpenChestMenu_CheckChest_NothingHere             ; No
	TST.b	Chest_opened_flag.w      ; Already opened?
	BNE.w	OpenChestMenu_CheckChest_AlreadyOpened             ; Yes
	
	; Open the chest
	PlaySound_b SOUND_CHEST_CREAK             ; Sound effect
	MOVE.b	#FLAG_TRUE, Chest_opened_flag.w
	MOVEA.l	Current_actor_ptr.w, A6          ; Chest sprite
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	ADDQ.w	#8, obj_tile_index(A6)               ; Adjust sprite Y
	MOVE.b	#CHEST_OPEN_DELAY_FRAMES, Open_chest_delay_timer.w
	MOVE.w	#OPEN_MENU_STATE_OPEN_DELAY, Open_menu_state.w    ; State 5
	RTS

OpenChestMenu_CheckChest_Locked:
	PRINT 	LockedStr
	BRA.w	OpenMenu_ShowMessage_Init
OpenChestMenu_CheckChest_AlreadyOpened:
	PRINT 	AlreadyOpenedStr
	BRA.w	OpenMenu_ShowMessage_Init
OpenChestMenu_CheckChest_NothingHere:
	PRINT 	NothingToOpenStr
	BRA.w	OpenMenu_ShowMessage_Init
OpenChestMenu_CheckChest_AlreadyOpen:
	PRINT 	AlreadyOpenStr	
OpenMenu_ShowMessage_Init:
	JSR	SaveStatusBarToBuffer             ; Display message
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#OPEN_MENU_STATE_MSG_WAIT, Open_menu_state.w    ; State 1
	RTS
	
OpenMenu_ShowMessage_Init_WaitInput:
	TST.b	Script_text_complete.w
	BEQ.w	OpenChestMenu_ExitToHud_ProcessText
	CheckButton BUTTON_BIT_C
	BNE.w	OpenChestMenu_ExitToHud
	CheckButton BUTTON_BIT_B
	BNE.w	OpenChestMenu_ExitToHud
	RTS
	
OpenChestMenu_ExitToHud:
	JSR	DrawStatusHudWindow
	MOVE.w	#OPEN_MENU_STATE_CLOSE, Open_menu_state.w
	RTS
	
OpenChestMenu_ExitToHud_ProcessText:
	JSR	ProcessScriptText
	RTS
	
OpenChestMenu_ExitToHud_Loop:
	CLR.w	Overworld_menu_state.w
	TriggerWindowRedraw WINDOW_DRAW_MSG_SPEED_ALT
	RTS
	
OpenChestMenu_ExitToHud_Animate:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.w	ChestAnimation_Return
	ADDQ.w	#1, Chest_animation_timer.w
	MOVE.w	Chest_animation_timer.w, D0
	ANDI.w	#$000F, D0
	BNE.w	ChestAnimation_Return
	CMPI.w	#4, Chest_animation_frame.w
	BGE.w	ChestAnimation_Return_FullyOpen
	LEA	OpenChestMenu_ExitToHud_Loop2_Data, A0
	MOVE.w	Chest_animation_frame.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	BSR.w	WriteChestAnimationToVRAM
	ADDQ.w	#1, Chest_animation_frame.w
ChestAnimation_Return:
	RTS
	
ChestAnimation_Return_FullyOpen:
	MOVE.b	#FLAG_TRUE, Chest_already_opened.w
	CLR.w	Overworld_menu_state.w
	RTS
	
ChestAnimation_Return_Loop:
	SUBQ.b	#1, Open_chest_delay_timer.w	
	BNE.w	ChestAnimation_Return_WaitDelay	
	PRINT 	CantOpenStr	
	JSR	SaveStatusBarToBuffer	
	JSR	ResetScriptAndInitDialogue	
	MOVE.w	#OPEN_MENU_STATE_MSG_WAIT, Open_menu_state.w	
ChestAnimation_Return_WaitDelay:
	RTS
	
ChestAnimation_Return_OpenDelay:
	SUBQ.b	#1, Open_chest_delay_timer.w
	BNE.w	ChestAnimation_Return_WaitOpen
	PRINT 	OpenedChestStr
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	MOVE.w	#OPEN_MENU_STATE_CONTENTS, Open_menu_state.w
ChestAnimation_Return_WaitOpen:
	RTS
	
ChestAnimation_Return_ShowContents:
	TST.b	Script_text_complete.w
	BEQ.w	ChestReward_Display_Loop
	TST.b	Reward_script_available.w
	BNE.w	ChestAnimation_Return_BuildRewardMsg
	PRINT 	NothingInsideStr
	BRA.w	ChestReward_Display
ChestAnimation_Return_BuildRewardMsg:
	LEA	Text_build_buffer.w, A1
	LEA	ThereIsStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	LEA	ShopCategoryNameTables, A0
	MOVE.w	Reward_script_type.w, D0
	CMPI.w	#REWARD_TYPE_RING, D0
