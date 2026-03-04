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
SaveGameToSram_Done:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_Done
	LEA	Current_town.w, A1
	MOVE.w	#1, D7
SaveGameToSram_Done2:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_Done2
	LEA	Towns_visited.w, A1
	MOVE.w	#$000D, D7
SaveGameToSram_Done3:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_Done3
	LEA	Player_position_x_outside_town.w, A1
	MOVE.w	#7, D7
SaveGameToSram_Done4:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_Done4
	LEA	Possessed_items_length.w, A1
	MOVE.w	#$0015, D7
SaveGameToSram_Done5:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_Done5
	LEA	Possessed_magics_length.w, A1
	MOVE.w	#$0015, D7
SaveGameToSram_Done6:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_Done6
	LEA	Possessed_equipment_length.w, A1
	MOVE.w	#$0015, D7
SaveGameToSram_Done7:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_Done7
	LEA	Equipped_sword.w, A1
	MOVE.w	#$000F, D7
SaveGameToSram_Done8:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_Done8
	LEA	Player_kims.w, A1
	MOVE.w	#$002F, D7
SaveGameToSram_Done9:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_Done9
	LEA	Event_triggers_start.w, A1
	MOVE.w	#$01FF, D7
SaveGameToSram_Done10:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_Done10
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
CalculateChecksumAndBackupSram_Done:
	MOVE.b	(A0)+, D2
	ASL.w	#8, D2
	LEA	$1(A0), A0
	MOVE.b	(A0)+, D2
	LEA	$1(A0), A0
	EOR.w	D2, D1
	LSR.w	#1, D1
	BCC.b	CalculateChecksumAndBackupSram_Loop
	EORI.w	#$8810, D1
CalculateChecksumAndBackupSram_Loop:
	DBF	D7, CalculateChecksumAndBackupSram_Done
	MOVE.w	D1, D0
	ASR.w	#8, D1
	MOVE.b	D1, (A0)+
	LEA	$1(A0), A0
	MOVE.b	D0, (A0)+
	MOVEA.l	Sram_save_slot_ptr.w, A1
	MOVEA.l	Sram_backup_ptr.w, A0
	MOVE.w	#$029F, D0
CalculateChecksumAndBackupSram_Loop_Done:
	MOVE.b	(A1)+, (A0)+
	LEA	$1(A0), A0
	LEA	$1(A1), A1
	DBF	D0, CalculateChecksumAndBackupSram_Loop_Done
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
	BRA.w	FileMenuPhaseJumpTable_Loop2
	BRA.w	FileMenu_VerifyChecksum_Loop
	BRA.w	FileSave_Return_Loop
	BRA.w	FileSave_Return_Loop2
	BRA.w	FileMenuSaveConfirm_Return_Loop	
FileMenuPhaseJumpTable_Loop:
	CLR.w	Dialog_selection.w
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	JSR	DrawSaveFileSelectWindow
	ADDQ.w	#1, File_menu_phase.w
	RTS
	
FileMenuPhaseJumpTable_Loop2:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	FileMenu_VerifyChecksum_Loop2
	CheckButton BUTTON_BIT_C
	BEQ.w	FileMenu_VerifyChecksum_Loop3
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
	BNE.b	FileMenu_VerifyChecksum
	TST.b	$2(A0)
	BNE.b	FileMenu_VerifyChecksum
	TST.b	$4(A0)
	BNE.b	FileMenu_VerifyChecksum
	TST.b	$6(A0)
	BNE.b	FileMenu_VerifyChecksum
	BRA.b	FileMenu_VerifyChecksum_Loop4
FileMenu_VerifyChecksum:
	BSR.w	VerifySaveChecksum
	BEQ.b	FileMenu_VerifyChecksum_Loop5
	ADDQ.w	#1, File_menu_phase.w
	JSR	DrawSaveErrorWindow
	RTS
	
FileMenu_VerifyChecksum_Loop5:
	MOVEA.l	Sram_save_slot_ptr.w, A0	
	BSR.w	LoadGameFromSave	
	JSR	DrawGameReadyWindow	
	MOVE.w	#FILE_MENU_PHASE_SUCCESS, File_menu_phase.w	
	RTS
	
FileMenu_VerifyChecksum_Loop4:
	MOVE.w	#FILE_MENU_PHASE_NO_SAVE, File_menu_phase.w
	JSR	DrawNoSavedGameWindow
	RTS
	
FileMenu_VerifyChecksum_Loop3:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
FileMenu_VerifyChecksum_Loop2:
	RTS
	
FileMenu_VerifyChecksum_Loop:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	FileSave_Return
	CheckButton BUTTON_BIT_C
	BEQ.w	FileSave_Return
	MOVEA.l	Sram_backup_ptr.w, A0
	BSR.w	VerifySaveChecksum
	BEQ.b	FileMenu_VerifyChecksum_Loop6
	JSR	DrawSaveFailedWindow
	ADDQ.w	#1, File_menu_phase.w
	MOVE.w	#SOUND_SAVE_FAILED, D0
	JSR	QueueSoundEffect
	MOVE.w	#SOUND_SPELL_CAST, D0
	JSR	QueueSoundEffect
	RTS
	
FileMenu_VerifyChecksum_Loop6:
	MOVEA.l	Sram_backup_ptr.w, A0	
	BSR.w	CopySramBackupToSlot	
	BSR.w	LoadGameFromSave	
	JSR	DrawSaveSuccessWindow	
	MOVE.w	#FILE_MENU_PHASE_SUCCESS, File_menu_phase.w	
	MOVE.w	#SOUND_LEVEL_UP_BANNER, D0	
	JSR	QueueSoundEffect	
FileSave_Return:
	RTS
	
FileSave_Return_Loop:
	TST.b	Window_tilemap_draw_active.w
	RTS
	
FileSave_Return_Loop2:
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
LoadGameFromSave_Done:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_Done	
	LEA	Current_town.w, A1	
	MOVE.w	#1, D7	
LoadGameFromSave_Done2:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_Done2	
	LEA	Towns_visited.w, A1	
	MOVE.w	#$000D, D7	
LoadGameFromSave_Done3:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_Done3	
	LEA	Player_position_x_outside_town.w, A1	
	MOVE.w	#7, D7	
LoadGameFromSave_Done4:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_Done4	
	LEA	Possessed_items_length.w, A1	
	MOVE.w	#$0015, D7	
LoadGameFromSave_Done5:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_Done5	
	LEA	Possessed_magics_length.w, A1	
	MOVE.w	#$0015, D7	
LoadGameFromSave_Done6:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_Done6	
	LEA	Possessed_equipment_length.w, A1	
	MOVE.w	#$0015, D7	
LoadGameFromSave_Done7:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_Done7	
	LEA	Equipped_sword.w, A1	
	MOVE.w	#$000F, D7	
LoadGameFromSave_Done8:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_Done8	
	LEA	Player_kims.w, A1	
	MOVE.w	#$002F, D7	
LoadGameFromSave_Done9:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_Done9	
	LEA	Event_triggers_start.w, A1	
	MOVE.w	#$01FF, D7	
LoadGameFromSave_Done10:
	BSR.w	CopyByteFromInterleavedSave	
	DBF	D7, LoadGameFromSave_Done10	
	RTS
	
CopyByteFromInterleavedSave:
	MOVE.b	(A0)+, (A1)+	
	LEA	$1(A0), A0	
	RTS
	
VerifySaveChecksum:
	MOVE.w	#$014E, D7
	MOVEQ	#0, D1
VerifySaveChecksum_Done:
	MOVE.b	(A0)+, D2
	ASL.w	#8, D2
	LEA	$1(A0), A0
	MOVE.b	(A0)+, D2
	LEA	$1(A0), A0
	EOR.w	D2, D1
	LSR.w	#1, D1
	BCC.b	VerifySaveChecksum_Loop
	EORI.w	#$8810, D1
VerifySaveChecksum_Loop:
	DBF	D7, VerifySaveChecksum_Done
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
CopySramBackupToSlot_Done:
	MOVE.b	(A1)+, (A0)+	
	LEA	$1(A0), A0	
	LEA	$1(A1), A1	
	DBF	D0, CopySramBackupToSlot_Done	
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
