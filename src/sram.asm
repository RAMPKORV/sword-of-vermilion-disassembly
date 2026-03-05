; ======================================================================
; src/sram.asm
; Save/Load SRAM, checksum, backup slots
; ======================================================================
SaveGameToSram:
	LEA	SramSaveSlotAddresses, A0
	LEA	SramBackupSlotAddresses, A1
	MOVE.w	Dialog_selection.w, D0
	ANDI.w	#3, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVE.l	(A0,D0.w), Sram_save_slot_ptr.w
	MOVE.l	(A1,D0.w), Sram_backup_ptr.w
	MOVEA.l	Sram_save_slot_ptr.w, A0
	LEA	Player_name.w, A1
	MOVE.w	#$000D, D7
SaveGameToSram_CopyNameLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyNameLoop
	LEA	Current_town.w, A1
	MOVE.w	#1, D7
SaveGameToSram_TownLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_TownLoop
	LEA	Towns_visited.w, A1
	MOVE.w	#$000D, D7
SaveGameToSram_CopyTownsVisitedLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyTownsVisitedLoop
	LEA	Player_position_x_outside_town.w, A1
	MOVE.w	#7, D7
SaveGameToSram_CopyPositionLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyPositionLoop
	LEA	Possessed_items_length.w, A1
	MOVE.w	#$0015, D7
SaveGameToSram_CopyItemsLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyItemsLoop
	LEA	Possessed_magics_length.w, A1
	MOVE.w	#$0015, D7
SaveGameToSram_CopyMagicsLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyMagicsLoop
	LEA	Possessed_equipment_length.w, A1
	MOVE.w	#$0015, D7
SaveGameToSram_CopyEquipmentLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyEquipmentLoop
	LEA	Equipped_sword.w, A1
	MOVE.w	#$000F, D7
SaveGameToSram_CopyEquippedLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyEquippedLoop
	LEA	Player_kims.w, A1
	MOVE.w	#$002F, D7
SaveGameToSram_CopyKimsLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyKimsLoop
	LEA	Event_triggers_start.w, A1
	MOVE.w	#$01FF, D7
SaveGameToSram_CopyEventsLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyEventsLoop
	JSR	CalculateChecksumAndBackupSram
	RTS

CopyByteToSram:
	MOVE.b	(A1)+, (A0)+
	LEA	$1(A0), A0
	RTS
	
CalculateChecksumAndBackupSram:
	MOVEA.l	Sram_save_slot_ptr.w, A0
	MOVE.w	#$014E, D7
	MOVEQ	#0, D1
CalculateChecksumAndBackupSram_ChecksumLoop:
	MOVE.b	(A0)+, D2
	ASL.w	#8, D2
	LEA	$1(A0), A0
	MOVE.b	(A0)+, D2
	LEA	$1(A0), A0
	EOR.w	D2, D1
	LSR.w	#1, D1
	BCC.b	CalculateChecksumAndBackupSram_ChecksumNext
	EORI.w	#$8810, D1
CalculateChecksumAndBackupSram_ChecksumNext:
	DBF	D7, CalculateChecksumAndBackupSram_ChecksumLoop
	MOVE.w	D1, D0
	ASR.w	#8, D1
	MOVE.b	D1, (A0)+
	LEA	$1(A0), A0
	MOVE.b	D0, (A0)+
	MOVEA.l	Sram_save_slot_ptr.w, A1
	MOVEA.l	Sram_backup_ptr.w, A0
	MOVE.w	#$029F, D0
CalculateChecksumAndBackupSram_BackupCopyLoop:
	MOVE.b	(A1)+, (A0)+
	LEA	$1(A0), A0
	LEA	$1(A1), A1
	DBF	D0, CalculateChecksumAndBackupSram_BackupCopyLoop
	RTS
	
FileMenuPhaseDispatch:
	LEA	FileMenuPhaseJumpTable, A0
	MOVE.w	File_menu_phase.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	JSR	(A0,D0.w)
	RTS
	
FileMenuPhaseJumpTable:
	BRA.w	FileMenuPhaseJumpTable_Loop
	BRA.w	FileMenuPhase_WaitSelection
	BRA.w	FileMenu_VerifyBackup
	BRA.w	FileSave_Return_Loop
	BRA.w	FileMenuPhase_SaveConfirmWait
	BRA.w	FileMenuSaveConfirm_Return_Loop	
FileMenuPhaseJumpTable_Loop:
	CLR.w	Dialog_selection.w
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	JSR	DrawSaveFileSelectWindow
	ADDQ.w	#1, File_menu_phase.w
	RTS
	
FileMenuPhase_WaitSelection:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	FileMenuPhase_WaitSelection_Return
	CheckButton BUTTON_BIT_C
	BEQ.w	FileMenu_MoveCursor
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	LEA	SramSaveSlotAddresses, A0
	LEA	SramBackupSlotAddresses, A1
	MOVE.w	Dialog_selection.w, D0
	ANDI.w	#3, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVE.l	(A0,D0.w), Sram_save_slot_ptr.w
	MOVE.l	(A1,D0.w), Sram_backup_ptr.w
	MOVEA.l	Sram_save_slot_ptr.w, A0
	TST.b	(A0)
	BNE.b	FileMenu_ChecksumAndLoad
	TST.b	$2(A0)
	BNE.b	FileMenu_ChecksumAndLoad
	TST.b	$4(A0)
	BNE.b	FileMenu_ChecksumAndLoad
	TST.b	$6(A0)
	BNE.b	FileMenu_ChecksumAndLoad
	BRA.b	FileMenu_NoSave
FileMenu_ChecksumAndLoad:
	BSR.w	VerifySaveChecksum
	BEQ.b	FileMenu_LoadFromSlot
	ADDQ.w	#1, File_menu_phase.w
	JSR	DrawSaveErrorWindow
	RTS
	
FileMenu_LoadFromSlot:
	MOVEA.l	Sram_save_slot_ptr.w, A0	
	BSR.w	LoadGameFromSave	
	JSR	DrawGameReadyWindow	
	MOVE.w	#FILE_MENU_PHASE_SUCCESS, File_menu_phase.w	
	RTS
	
FileMenu_NoSave:
	MOVE.w	#FILE_MENU_PHASE_NO_SAVE, File_menu_phase.w
	JSR	DrawNoSavedGameWindow
	RTS
	
FileMenu_MoveCursor:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
FileMenuPhase_WaitSelection_Return:
	RTS
	
FileMenu_VerifyBackup:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	FileSave_Return
	CheckButton BUTTON_BIT_C
	BEQ.w	FileSave_Return
	MOVEA.l	Sram_backup_ptr.w, A0
	BSR.w	VerifySaveChecksum
	BEQ.b	FileMenu_RestoreFromBackup
	JSR	DrawSaveFailedWindow
	ADDQ.w	#1, File_menu_phase.w
	PlaySound	SOUND_SAVE_FAILED
	PlaySound	SOUND_SPELL_CAST
	RTS
	
FileMenu_RestoreFromBackup:
	MOVEA.l	Sram_backup_ptr.w, A0	
	BSR.w	CopySramBackupToSlot	
	BSR.w	LoadGameFromSave	
	JSR	DrawSaveSuccessWindow	
	MOVE.w	#FILE_MENU_PHASE_SUCCESS, File_menu_phase.w	
	PlaySound	SOUND_LEVEL_UP_BANNER	
FileSave_Return:
	RTS
	
FileSave_Return_Loop:
	TST.b	Window_tilemap_draw_active.w
	RTS
	
FileMenuPhase_SaveConfirmWait:
	TST.b	Window_tilemap_draw_active.w
	BNE.b	FileMenuSaveConfirm_Return
	CheckButton BUTTON_BIT_C
	BEQ.b	FileMenuSaveConfirm_Return
	MOVE.w	#FILE_MENU_PHASE_DRAW_SELECT, File_menu_phase.w
FileMenuSaveConfirm_Return:
	RTS
	
FileMenuSaveConfirm_Return_Loop:
	TST.b	Window_tilemap_draw_active.w	
	BNE.b	FileMenuLoad_Return	
	CheckButton BUTTON_BIT_C	
	BEQ.b	FileMenuLoad_Return	
	MOVE.b	#FLAG_TRUE, File_load_complete.w	
FileMenuLoad_Return:
	RTS
	
LoadGameFromSave:
	LEA	Player_name.w, A1	
	MOVE.w	#$000D, D7	
LoadGameFromSave_CopyNameLoop:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_CopyNameLoop	
	LEA	Current_town.w, A1	
	MOVE.w	#1, D7	
LoadGameFromSave_TownLoop:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_TownLoop
	LEA	Towns_visited.w, A1	
	MOVE.w	#$000D, D7	
LoadGameFromSave_CopyTownsVisitedLoop:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_CopyTownsVisitedLoop	
	LEA	Player_position_x_outside_town.w, A1	
	MOVE.w	#7, D7	
LoadGameFromSave_CopyPositionLoop:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_CopyPositionLoop	
	LEA	Possessed_items_length.w, A1	
	MOVE.w	#$0015, D7	
LoadGameFromSave_CopyItemsLoop:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_CopyItemsLoop	
	LEA	Possessed_magics_length.w, A1	
	MOVE.w	#$0015, D7	
LoadGameFromSave_CopyMagicsLoop:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_CopyMagicsLoop	
	LEA	Possessed_equipment_length.w, A1	
	MOVE.w	#$0015, D7	
LoadGameFromSave_CopyEquipmentLoop:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_CopyEquipmentLoop	
	LEA	Equipped_sword.w, A1	
	MOVE.w	#$000F, D7	
LoadGameFromSave_CopyEquippedLoop:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_CopyEquippedLoop	
	LEA	Player_kims.w, A1	
	MOVE.w	#$002F, D7	
LoadGameFromSave_CopyKimsLoop:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_CopyKimsLoop	
	LEA	Event_triggers_start.w, A1	
	MOVE.w	#$01FF, D7	
LoadGameFromSave_CopyEventsLoop:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_CopyEventsLoop	
	RTS
	
CopyByteFromInterleavedSave:
	MOVE.b	(A0)+, (A1)+	
	LEA	$1(A0), A0	
	RTS
	
VerifySaveChecksum:
	MOVE.w	#$014E, D7
	MOVEQ	#0, D1
VerifySaveChecksum_Loop:
	MOVE.b	(A0)+, D2
	ASL.w	#8, D2
	LEA	$1(A0), A0
	MOVE.b	(A0)+, D2
	LEA	$1(A0), A0
	EOR.w	D2, D1
	LSR.w	#1, D1
	BCC.b	VerifySaveChecksum_SkipXor
	EORI.w	#$8810, D1
VerifySaveChecksum_SkipXor:
	DBF	D7, VerifySaveChecksum_Loop
	MOVE.b	(A0)+, D0
	LEA	$1(A0), A0
	ASL.w	#8, D0
	MOVE.b	(A0)+, D0
	CMP.w	D0, D1
	RTS
	
CopySramBackupToSlot:
	MOVEA.l	Sram_save_slot_ptr.w, A0	
	MOVEA.l	Sram_backup_ptr.w, A1	
	MOVE.w	#$029F, D0	
CopySramBackupToSlot_CopyLoop:
	MOVE.b	(A1)+, (A0)+	
	LEA	$1(A0), A0	
	LEA	$1(A1), A1	
	DBF	D0, CopySramBackupToSlot_CopyLoop	
	RTS
	
SramSaveSlotAddresses:
	dc.l	$00200001
	dc.l	$00200A81
	dc.l	$00201501
	dc.l	$00200001 
SramBackupSlotAddresses:
	dc.l	$00200541
	dc.l	$00200FC1
	dc.l	$00201A41
	dc.l	$00200541 
