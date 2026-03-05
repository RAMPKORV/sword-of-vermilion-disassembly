; ======================================================================
; src/sram.asm
; Save/Load SRAM persistence, checksum verification, and backup slots
;
; SRAM LAYOUT
; -----------
; The cartridge SRAM occupies $200000-$20FFFF (odd bytes only; even bytes
; are unused on the Genesis bus, hence the interleaved read/write via
; CopyByteToSram / CopyByteFromInterleavedSave).
;
; Three save slots plus one backup copy per slot are supported:
;   Slot 0 primary  : $200001    Slot 0 backup  : $200541
;   Slot 1 primary  : $200A81    Slot 1 backup  : $200FC1
;   Slot 2 primary  : $201501    Slot 2 backup  : $201A41
;   (Slot 3 wraps back to slot 0 — only 3 real slots exist)
;
; SAVE SLOT LAYOUT (within each slot, interleaved SRAM bytes)
; -----------------------------------------------------------
;   Field                    RAM source                  Bytes  DBF count
;   -----------------------------------------------------------------------
;   Player name              Player_name                  14     $000D (+1)
;   Current town             Current_town                  2        1 (+1)
;   Towns visited            Towns_visited                14     $000D (+1)
;   Overworld position       Player_position_x_outside_town 8    7 (+1)
;   Items (len + array)      Possessed_items_length       22     $0015 (+1)
;   Magics (len + array)     Possessed_magics_length      22     $0015 (+1)
;   Equipment (len + array)  Possessed_equipment_length   22     $0015 (+1)
;   Equipped gear            Equipped_sword               16     $000F (+1)
;   Gold (kims + more)       Player_kims                  48     $002F (+1)
;   Event triggers           Event_triggers_start        512     $01FF (+1)
;   -----------------------------------------------------------------------
;   Total data bytes: ~680 ($02A8)
;   Checksum word:  2 bytes appended after data  (see CalculateChecksumAndBackupSram)
;   Backup copy:    $02A0 words ($02A0+1 = 673 loop iters, covering data+checksum)
;
; CHECKSUM ALGORITHM ($8810 CRC-style)
; -------------------------------------
; Reads the save data as 16-bit words (each word spans 4 interleaved SRAM
; bytes). Accumulator D1 starts at 0. For each word:
;   1. XOR the word into D1
;   2. Logical-shift D1 right 1 bit
;   3. If the bit shifted out (carry) was set: XOR D1 with $8810
; This is a 1-bit-per-step CRC using polynomial $8810 (reflected form).
; The final 16-bit checksum is stored big-endian after the data block.
; ======================================================================

; ----------------------------------------------------------------------
; SaveGameToSram
; Save current game state to the SRAM slot selected in Dialog_selection.
; Sets Sram_save_slot_ptr and Sram_backup_ptr for the chosen slot.
; Copies all save fields via CopyByteToSram, then calls
; CalculateChecksumAndBackupSram to write the checksum and backup copy.
; In:  Dialog_selection.w = slot index (0-2; 3 wraps to 0)
; Out: SRAM slot written; backup slot updated
; Uses: A0, A1, D0, D7 (via CopyByteToSram)
; ----------------------------------------------------------------------
SaveGameToSram:
	LEA	SramSaveSlotAddresses, A0
	LEA	SramBackupSlotAddresses, A1
	MOVE.w	Dialog_selection.w, D0
	ANDI.w	#3, D0		; wrap slot index to 0-2 (3 is an alias for 0)
	ADD.w	D0, D0		; * 4 (each table entry is a longword)
	ADD.w	D0, D0
	MOVE.l	(A0,D0.w), Sram_save_slot_ptr.w
	MOVE.l	(A1,D0.w), Sram_backup_ptr.w
	MOVEA.l	Sram_save_slot_ptr.w, A0
	; --- Copy player name (14 bytes; SRAM_NAME_SIZE_M1+1 iterations) ---
	LEA	Player_name.w, A1
	MOVE.w	#SRAM_NAME_SIZE_M1, D7		; 14 bytes: chars 0-13
SaveGameToSram_CopyNameLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyNameLoop
	; --- Copy current town (2 bytes) ---
	LEA	Current_town.w, A1
	MOVE.w	#1, D7			; 2 bytes
SaveGameToSram_TownLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_TownLoop
	; --- Copy towns-visited flags (14 bytes) ---
	LEA	Towns_visited.w, A1
	MOVE.w	#SRAM_TOWNS_SIZE_M1, D7		; 14 bytes
SaveGameToSram_CopyTownsVisitedLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyTownsVisitedLoop
	; --- Copy overworld position (8 bytes) ---
	LEA	Player_position_x_outside_town.w, A1
	MOVE.w	#7, D7			; 8 bytes: x, y, facing, subpixel, etc.
SaveGameToSram_CopyPositionLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyPositionLoop
	; --- Copy item inventory (22 bytes: length word + 20-item array) ---
	LEA	Possessed_items_length.w, A1
	MOVE.w	#SRAM_INVENTORY_SIZE_M1, D7		; 22 bytes
SaveGameToSram_CopyItemsLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyItemsLoop
	; --- Copy magic inventory (22 bytes) ---
	LEA	Possessed_magics_length.w, A1
	MOVE.w	#SRAM_INVENTORY_SIZE_M1, D7		; 22 bytes
SaveGameToSram_CopyMagicsLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyMagicsLoop
	; --- Copy equipment inventory (22 bytes) ---
	LEA	Possessed_equipment_length.w, A1
	MOVE.w	#SRAM_INVENTORY_SIZE_M1, D7		; 22 bytes
SaveGameToSram_CopyEquipmentLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyEquipmentLoop
	; --- Copy currently equipped gear (16 bytes: sword, shield, armor, ring, etc.) ---
	LEA	Equipped_sword.w, A1
	MOVE.w	#SRAM_EQUIPPED_SIZE_M1, D7		; 16 bytes
SaveGameToSram_CopyEquippedLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyEquippedLoop
	; --- Copy gold and stats block (48 bytes: kims long + remaining stat words) ---
	LEA	Player_kims.w, A1
	MOVE.w	#SRAM_STATS_SIZE_M1, D7		; 48 bytes
SaveGameToSram_CopyKimsLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyKimsLoop
	; --- Copy event/story trigger flags (512 bytes) ---
	LEA	Event_triggers_start.w, A1
	MOVE.w	#SRAM_EVENTS_SIZE_M1, D7		; 512 bytes
SaveGameToSram_CopyEventsLoop:
	BSR.w	CopyByteToSram
	DBF	D7, SaveGameToSram_CopyEventsLoop
	; Compute checksum over saved data and write backup copy
	JSR	CalculateChecksumAndBackupSram
	RTS

; ----------------------------------------------------------------------
; CopyByteToSram
; Copy one byte from RAM to SRAM, skipping the even (unused) SRAM byte.
; SRAM on the Genesis is mapped to odd addresses only; each logical byte
; occupies two physical address positions.
; In:  A0 = current SRAM write pointer (odd address)
;      A1 = current RAM read pointer
; Out: A0 advanced by 2 (past data byte + skipped even byte)
;      A1 advanced by 1
; ----------------------------------------------------------------------
CopyByteToSram:
	MOVE.b	(A1)+, (A0)+
	LEA	$1(A0), A0	; skip the even (unused) SRAM byte
	RTS
	
; ----------------------------------------------------------------------
; CalculateChecksumAndBackupSram
; Compute the $8810 CRC checksum over the save data in the primary slot,
; append it to the slot, then copy the entire slot (data + checksum) to
; the backup slot.
;
; Checksum covers $014E+1 = 335 16-bit words (670 data bytes), reading
; each word from 4 interleaved SRAM bytes (two logical bytes per word).
; After the loop the checksum is stored big-endian: high byte first.
;
; Backup copy covers $029F+1 = 672 iterations, each copying 1 byte and
; skipping 1 even byte (interleaved), covering 672 data+checksum bytes.
;
; In:  Sram_save_slot_ptr.w = pointer to primary slot start
;      Sram_backup_ptr.w    = pointer to backup slot start
; Out: Primary slot checksum bytes written; backup slot is a full copy
; Uses: A0, A1, D0, D1, D2, D7
; ----------------------------------------------------------------------
CalculateChecksumAndBackupSram:
	MOVEA.l	Sram_save_slot_ptr.w, A0
	MOVE.w	#SRAM_CHECKSUM_WORD_COUNT_M1, D7	; 335 iterations = 335 words of save data
	MOVEQ	#0, D1		; D1 = running checksum accumulator
CalculateChecksumAndBackupSram_ChecksumLoop:
	; Read high byte of next word (from odd SRAM address)
	MOVE.b	(A0)+, D2
	ASL.w	#8, D2		; shift to high byte of D2.w
	LEA	$1(A0), A0	; skip even (unused) SRAM byte
	; Read low byte of the same word
	MOVE.b	(A0)+, D2
	LEA	$1(A0), A0	; skip even SRAM byte
	; CRC step: XOR word into accumulator, then right-shift with poly feedback
	EOR.w	D2, D1
	LSR.w	#1, D1		; shift right; carry = bit that was shifted out
	BCC.b	CalculateChecksumAndBackupSram_ChecksumNext
	EORI.w	#SRAM_CHECKSUM_POLY, D1	; bit was 1: XOR with polynomial $8810
CalculateChecksumAndBackupSram_ChecksumNext:
	DBF	D7, CalculateChecksumAndBackupSram_ChecksumLoop
	; Write checksum big-endian after the data block
	MOVE.w	D1, D0		; preserve full checksum word
	ASR.w	#8, D1
	MOVE.b	D1, (A0)+	; write high byte
	LEA	$1(A0), A0	; skip even SRAM byte
	MOVE.b	D0, (A0)+	; write low byte
	; Copy primary slot (data + checksum) to backup slot
	MOVEA.l	Sram_save_slot_ptr.w, A1
	MOVEA.l	Sram_backup_ptr.w, A0
	MOVE.w	#SRAM_SLOT_TOTAL_SIZE_M1, D0	; 672 bytes total (data + 2-byte checksum)
CalculateChecksumAndBackupSram_BackupCopyLoop:
	MOVE.b	(A1)+, (A0)+
	LEA	$1(A0), A0	; skip even SRAM byte (destination)
	LEA	$1(A1), A1	; skip even SRAM byte (source)
	DBF	D0, CalculateChecksumAndBackupSram_BackupCopyLoop
	RTS
	
; ----------------------------------------------------------------------
; FileMenuPhaseDispatch
; Dispatch to the current phase handler for the file select / save menu.
; Phase is stored in File_menu_phase.w and indexes FileMenuPhaseJumpTable.
; In:  File_menu_phase.w = current phase index (0-5)
; Out: Depends on the dispatched phase handler
; ----------------------------------------------------------------------
FileMenuPhaseDispatch:
	LEA	FileMenuPhaseJumpTable, A0
	MOVE.w	File_menu_phase.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	JSR	(A0,D0.w)
	RTS
	
FileMenuPhaseJumpTable:
	; Phase 0 (FILE_MENU_PHASE_DRAW_SELECT) : draw save-file select window
	BRA.w	FileMenuPhaseJumpTable_Loop
	; Phase 1 (FILE_MENU_PHASE_WAIT_SELECT) : wait for player to pick a slot
	BRA.w	FileMenuPhase_WaitSelection
	; Phase 2 (FILE_MENU_PHASE_VERIFY)      : verify checksum / load file
	BRA.w	FileMenu_VerifyBackup
	; Phase 3 (FILE_MENU_PHASE_LOAD_ERROR)  : wait for load-error dismiss
	BRA.w	FileSave_Return_Loop
	; Phase 4 (FILE_MENU_PHASE_NO_SAVE)     : wait for save-confirm dismiss
	BRA.w	FileMenuPhase_SaveConfirmWait
	; Phase 5 (FILE_MENU_PHASE_SUCCESS)     : wait for success-screen dismiss
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
	; Check first four interleaved bytes of slot for any non-zero data.
	; Each logical save byte occupies 2 SRAM bytes (odd only), so:
	;   sram_slot_name0 offset $0000 = name[0], sram_slot_name1 $0002 = name[1], ...
	TST.b	(A0)				; name byte 0 (sram_slot_name0 = $0000)
	BNE.b	FileMenu_ChecksumAndLoad
	TST.b	sram_slot_name1(A0)	; name byte 1
	BNE.b	FileMenu_ChecksumAndLoad
	TST.b	sram_slot_name2(A0)	; name byte 2
	BNE.b	FileMenu_ChecksumAndLoad
	TST.b	sram_slot_name3(A0)	; name byte 3
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
	
; ----------------------------------------------------------------------
; LoadGameFromSave
; Load game state from a save slot into RAM. Reads all save fields via
; CopyByteFromInterleavedSave in the same order they were written by
; SaveGameToSram.
; In:  A0 = pointer to start of SRAM save slot (odd address)
; Out: All player RAM fields restored from SRAM
; Uses: A0, A1, D7 (via CopyByteFromInterleavedSave)
; ----------------------------------------------------------------------
LoadGameFromSave:
	LEA	Player_name.w, A1
	MOVE.w	#SRAM_NAME_SIZE_M1, D7	; 14 bytes: player name
LoadGameFromSave_CopyNameLoop:
	BSR.w	CopyByteFromInterleavedSave
	DBF	D7, LoadGameFromSave_CopyNameLoop
	LEA	Current_town.w, A1
	MOVE.w	#1, D7		; 2 bytes: current town ID
LoadGameFromSave_TownLoop:
	BSR.w	CopyByteFromInterleavedSave
	DBF	D7, LoadGameFromSave_TownLoop
	LEA	Towns_visited.w, A1
	MOVE.w	#SRAM_TOWNS_SIZE_M1, D7	; 14 bytes: towns-visited flags
LoadGameFromSave_CopyTownsVisitedLoop:
	BSR.w	CopyByteFromInterleavedSave
	DBF	D7, LoadGameFromSave_CopyTownsVisitedLoop
	LEA	Player_position_x_outside_town.w, A1
	MOVE.w	#7, D7		; 8 bytes: overworld position
LoadGameFromSave_CopyPositionLoop:
	BSR.w	CopyByteFromInterleavedSave
	DBF	D7, LoadGameFromSave_CopyPositionLoop
	LEA	Possessed_items_length.w, A1
	MOVE.w	#SRAM_INVENTORY_SIZE_M1, D7	; 22 bytes: item inventory
LoadGameFromSave_CopyItemsLoop:
	BSR.w	CopyByteFromInterleavedSave
	DBF	D7, LoadGameFromSave_CopyItemsLoop
	LEA	Possessed_magics_length.w, A1
	MOVE.w	#SRAM_INVENTORY_SIZE_M1, D7	; 22 bytes: magic inventory
LoadGameFromSave_CopyMagicsLoop:
	BSR.w	CopyByteFromInterleavedSave
	DBF	D7, LoadGameFromSave_CopyMagicsLoop
	LEA	Possessed_equipment_length.w, A1
	MOVE.w	#SRAM_INVENTORY_SIZE_M1, D7	; 22 bytes: equipment inventory
LoadGameFromSave_CopyEquipmentLoop:
	BSR.w	CopyByteFromInterleavedSave
	DBF	D7, LoadGameFromSave_CopyEquipmentLoop
	LEA	Equipped_sword.w, A1
	MOVE.w	#SRAM_EQUIPPED_SIZE_M1, D7	; 16 bytes: equipped gear
LoadGameFromSave_CopyEquippedLoop:
	BSR.w	CopyByteFromInterleavedSave
	DBF	D7, LoadGameFromSave_CopyEquippedLoop
	LEA	Player_kims.w, A1
	MOVE.w	#SRAM_STATS_SIZE_M1, D7	; 48 bytes: gold + stat block
LoadGameFromSave_CopyKimsLoop:
	BSR.w	CopyByteFromInterleavedSave
	DBF	D7, LoadGameFromSave_CopyKimsLoop
	LEA	Event_triggers_start.w, A1
	MOVE.w	#SRAM_EVENTS_SIZE_M1, D7	; 512 bytes: event/story trigger flags
LoadGameFromSave_CopyEventsLoop:
	BSR.w	CopyByteFromInterleavedSave
	DBF	D7, LoadGameFromSave_CopyEventsLoop
	RTS
	
; ----------------------------------------------------------------------
; CopyByteFromInterleavedSave
; Read one byte from an interleaved SRAM slot into RAM.
; Mirror of CopyByteToSram: advances source by 2 (skip even SRAM byte).
; In:  A0 = SRAM read pointer (odd address)
;      A1 = RAM write pointer
; Out: A0 advanced by 2; A1 advanced by 1
; ----------------------------------------------------------------------
CopyByteFromInterleavedSave:
	MOVE.b	(A0)+, (A1)+
	LEA	$1(A0), A0	; skip even (unused) SRAM byte
	RTS
	
; ----------------------------------------------------------------------
; VerifySaveChecksum
; Recompute the SRAM_CHECKSUM_POLY CRC over the data portion of a save slot and compare
; against the stored checksum. Identical algorithm to
; CalculateChecksumAndBackupSram.
; In:  A0 = pointer to start of SRAM slot to verify
; Out: Z flag set if checksum matches (CMP.w sets Z if D0 == D1)
;      A0 advanced past the slot data and checksum bytes
; Uses: A0, D0, D1, D2, D7
; ----------------------------------------------------------------------
VerifySaveChecksum:
	MOVE.w	#SRAM_CHECKSUM_WORD_COUNT_M1, D7	; 335 iterations (same as save)
	MOVEQ	#0, D1		; D1 = checksum accumulator
VerifySaveChecksum_Loop:
	MOVE.b	(A0)+, D2
	ASL.w	#8, D2		; high byte of word
	LEA	$1(A0), A0	; skip even SRAM byte
	MOVE.b	(A0)+, D2	; low byte of word
	LEA	$1(A0), A0	; skip even SRAM byte
	EOR.w	D2, D1
	LSR.w	#1, D1
	BCC.b	VerifySaveChecksum_SkipXor
	EORI.w	#SRAM_CHECKSUM_POLY, D1	; polynomial feedback
VerifySaveChecksum_SkipXor:
	DBF	D7, VerifySaveChecksum_Loop
	; Read stored big-endian checksum from SRAM into D0
	MOVE.b	(A0)+, D0	; high byte
	LEA	$1(A0), A0	; skip even SRAM byte
	ASL.w	#8, D0
	MOVE.b	(A0)+, D0	; low byte
	CMP.w	D0, D1		; sets Z if computed == stored
	RTS
	
; ----------------------------------------------------------------------
; CopySramBackupToSlot
; Copy the backup slot back to the primary slot (disaster recovery).
; Used when the primary slot fails checksum but the backup is intact.
; Copies SRAM_SLOT_TOTAL_SIZE_M1+1 = 672 interleaved bytes (data + checksum).
; In:  Sram_save_slot_ptr.w = destination (primary slot)
;      Sram_backup_ptr.w    = source (backup slot)
; Out: Primary slot overwritten with backup data
; Uses: A0, A1, D0
; ----------------------------------------------------------------------
CopySramBackupToSlot:
	MOVEA.l	Sram_save_slot_ptr.w, A0	; destination: primary slot
	MOVEA.l	Sram_backup_ptr.w, A1		; source: backup slot
	MOVE.w	#SRAM_SLOT_TOTAL_SIZE_M1, D0		; 672 bytes total
CopySramBackupToSlot_CopyLoop:
	MOVE.b	(A1)+, (A0)+
	LEA	$1(A0), A0	; skip even SRAM byte (destination)
	LEA	$1(A1), A1	; skip even SRAM byte (source)
	DBF	D0, CopySramBackupToSlot_CopyLoop
	RTS
	
; SRAM slot address tables (odd-byte addresses; Genesis SRAM is odd-mapped)
; Each slot is $0540 bytes apart in SRAM address space (1344 byte stride,
; because each logical byte occupies 2 physical SRAM bytes).
; Slot 3 is an alias for slot 0 (only 3 real save slots exist).
SramSaveSlotAddresses:
	dc.l	$00200001	; Slot 0 primary: SRAM base + 0
	dc.l	$00200A81	; Slot 1 primary: SRAM base + $A80
	dc.l	$00201501	; Slot 2 primary: SRAM base + $1500
	dc.l	$00200001	; Slot 3 (alias for slot 0)
SramBackupSlotAddresses:
	dc.l	$00200541	; Slot 0 backup:  SRAM base + $540
	dc.l	$00200FC1	; Slot 1 backup:  SRAM base + $FC0
	dc.l	$00201A41	; Slot 2 backup:  SRAM base + $1A40
	dc.l	$00200541	; Slot 3 (alias for slot 0 backup)
