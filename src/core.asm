; ======================================================================
; src/core.asm
; Core init: ErrorTrap, InitVDP, ClearRAM, Object init system
; ======================================================================
ErrorTrap:

	RTE	
InitVDP:
	LEA	Stack_base.w, A6
	MOVEQ	#0, D7
	MOVE.w	#$007F, D6
InitPSG:
	MOVE.l	D7, (A6)+
	DBF	D6, InitPSG
	RTS

ClearRAMAndInitHardware:
	clearRAM Tilemap_buffer_plane_a, Ram_clear_end
	BSR.w	InitZ80SoundDriver
	BSR.w	InitVDPAndClearVRAM
	BSR.w	InitYM2612
	RTS

InitPlayerInventoryDefaults:
	MOVE.w	#0, Possessed_items_length.w
	MOVE.w	#0, Possessed_magics_length.w
	MOVE.w	#0, Possessed_equipment_length.w
	MOVE.w	#EQUIP_NONE, Equipped_sword.w
	MOVE.w	#EQUIP_NONE, Equipped_shield.w
InitEquipmentAndLevel:
	MOVE.w	#EQUIP_NONE, Equipped_armor.w
	MOVE.w	#MAGIC_NONE, Readied_magic.w
	MOVE.w	#EQUIP_NONE, Equipped_unused.w
	MOVE.l	#0, Player_kims.w
	MOVE.w	#0, Player_level.w
	JSR	UpgradeLevelStats
	LEA	Player_name.w, A0
	MOVE.b	#$FF, (A0)
	RTS

ClearVRAMSprites:
	DMAFillVRAM $7C000002, $03BF
ClearVRAMSprites_End:
	RTS

ClearVSRAM:
	MOVE.l	#$40000010, D7
	MOVEQ	#$00000028, D6
	MOVEQ	#0, D5
	MOVE.l	D7, VDP_control_port
ClearVSRAM_loop:
	MOVE.w	D5, VDP_data_port
BossProjectileSpriteFrame_D_Frame_2B0: ; Referenced by data table at line 38051
	DBF	D6, ClearVSRAM_loop
	RTS

ClearVRAMHScroll:
	DMAFillVRAM $78000002, $013F
	RTS

ClearVRAMPlaneA:
	DMAFillVRAM $40000003, $1FFF
	RTS

ClearVRAMPlaneB:
	DMAFillVRAM $60000003, $1FFF
	RTS

; ---------------------------------------------------------------------------
; DMAFillPartial — DEAD CODE: incomplete DMA fill fragment
;
; DEAD CODE: No call sites exist.  Sets D6 = $1FFF and calls VDP_DMAFill,
; but VDP_DMAFill also requires D7 (VRAM destination command) and D5 (fill
; byte) to be pre-loaded by the caller — making this an incomplete wrapper.
; Likely a leftover from an early DMA abstraction that was superseded by the
; DMAFillVRAM macro.  Cannot be removed without breaking bit-perfect output.
; ---------------------------------------------------------------------------
DMAFillPartial:
	MOVE.w	#$1FFF, D6
	JSR	VDP_DMAFill
	RTS

; ---------------------------------------------------------------------------
; DMAFillWindowSpriteArea — DEAD CODE: fill window/sprite VRAM region
;
; DEAD CODE: No call sites exist.  Would fill 0x0E00 bytes of VRAM from
; address $B000 (the window plane / sprite attribute table region) with
; zero.  Likely an early initialization routine superseded by the VDP reset
; sequence in InitVDPAndClearVRAM/ClearVRAMScrollAndPlanes.
; Cannot be removed without breaking bit-perfect output.
; ---------------------------------------------------------------------------
DMAFillWindowSpriteArea:
	DMAFillVRAM $70000002, $0DFF
	RTS

InitYM2612:
	MOVEQ	#$00000040, D0
	stopZ80
	MOVE.b	D0, IO_ctrl_port_1
	MOVE.b	D0, IO_ctrl_port_2
	MOVE.b	D0, IO_ctrl_expansion
	startZ80
	RTS

InitVDPAndClearVRAM:
	LEA	VDPRegisterDefaults, A0
	MOVEQ	#$0000000F, D0
InitVDPAndClearVRAM_Done:
	MOVE.w	(A0)+, VDP_control_port
	DBF	D0, InitVDPAndClearVRAM_Done
	LEA	VDPRegisterDefaults, A0
	LEA	VDP_regs_cache.w, A1
	MOVE.l	(A0)+, (A1)+
	MOVE.l	(A0)+, (A1)+
	MOVE.w	(A0)+, (A1)+
	MOVE.l	#$C0000000, VDP_control_port
	MOVE.w	#0, VDP_data_port
	BSR.w	ClearVRAMSprites
	BSR.w	ClearVSRAM
; loc_00000396
ClearVRAMScrollAndPlanes:                   ; alternate entry: skip sprite table wipe (used by DebugTestMenu)
	BSR.w	ClearVRAMHScroll
	BSR.w	ClearVRAMPlaneA
	BSR.w	ClearVRAMPlaneB
	DMAFillVRAM $40000000, $001F
	RTS

; ---------------------------------------------------------------------------
; DMAFillEntireVRAM — DEAD CODE: fill entire VRAM ($0000–$FFFF) with zero
;
; DEAD CODE: No call sites exist.  Would DMA-fill all 64 KB of VRAM.
; Superseded by the selective per-region clear functions called from
; InitVDPAndClearVRAM.  Cannot be removed without breaking bit-perfect output.
; ---------------------------------------------------------------------------
DMAFillEntireVRAM:
	DMAFillVRAM $40000000, $FFFF
	RTS

InitZ80SoundDriver:
	MOVE.w	#$0100, Z80_bus_request
	MOVE.w	#$0100, Z80_reset
	MOVE.w	#0, Z80_reset
	MOVE.w	#$0013, D7
InitZ80SoundDriver_Done:
	DBF	D7, InitZ80SoundDriver_Done
	MOVE.w	#$0100, Z80_reset
	BSR.w	LoadZ80Driver
	RTS

;LoadZ80Driver:
LoadZ80Driver: ; Send below chunk of data into Z80 RAM
	LEA	Z80_ram, A1
	LEA	Z80DriverBinary, A2
	MOVE.w	#$013F, D6
LoadZ80Driver_Done:
	MOVE.b	(A2)+, (A1)+
	DBF	D6, LoadZ80Driver_Done
	RTS

Z80DriverBinary:
	dc.b	$F3, $F3, $31, $F0, $1F, $3E, $80, $32, $FF, $1F, $AF, $32, $FD, $1F, $C3, $68, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $ED, $4D, $00, $00, $00, $00, $00, $00 
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
	dc.b	$00, $00, $00, $00, $00, $00, $ED, $45, $3A, $FF, $1F, $FE, $81, $DA, $68, $00, $32, $FA, $1F, $3E, $80, $32, $FF, $1F, $3A, $FA, $1F, $E6, $3F, $FE, $09, $D2 
	dc.b	$68, $00, $21, $00, $02, $5E, $23, $56, $EB, $5F, $16, $00, $19, $19, $19, $19, $5E, $23, $56, $D5, $23, $7E, $5F, $23, $7E, $57, $EB, $D1, $E5, $D5, $3A, $FA 
	dc.b	$1F, $E6, $3F, $5F, $16, $00, $21, $02, $02, $19, $19, $5E, $23, $56, $EB, $3A, $FE, $1F, $5F, $16, $00, $19, $7E, $32, $FB, $1F, $D1, $E1, $D9, $11, $30, $01 
	dc.b	$D9, $06, $2B, $3E, $80, $CD, $19, $01, $7E, $E6, $F0, $0F, $0F, $0F, $0F, $D9, $6F, $26, $00, $19, $3A, $FC, $1F, $86, $32, $FC, $1F, $D9, $06, $2A, $CD, $19 
	dc.b	$01, $3A, $FB, $1F, $47, $10, $FE, $7E, $E6, $0F, $D9, $6F, $26, $00, $19, $3A, $FC, $1F, $86, $32, $FC, $1F, $D9, $06, $2A, $CD, $19, $01, $23, $1B, $3A, $FF 
	dc.b	$1F, $CB, $7F, $CA, $16, $01, $7B, $B2, $CA, $00, $00, $3A, $FF, $1F, $E6, $3F, $C2, $68, $00, $C3, $C8, $00, $C3, $00, $00, $E5, $21, $FD, $1F, $CB, $FE, $08 
	dc.b	$78, $32, $00, $40, $08, $00, $32, $01, $40, $32, $FC, $1F, $CB, $BE, $E1, $C9, $01, $03, $06, $0C, $18, $28, $50, $90, $FF, $FD, $FA, $F4, $E8, $D8, $B0, $70 

InitMenuObjects:
	initObjects MenuObjectInitTable
InitGameplayObjects:
	initObjects GameplayObjectInitTable
InitBattleObjects:
	initObjects BattleObjectInitTable
InitBossObjects_TypeA:
	initObjects BossObjectInitTable_A
InitBossObjects_TypeB:
	initObjects BossObjectInitTable_B
InitBossObjects_TypeC:
	initObjects BossObjectInitTable_C
InitBossObjects_TypeD:
	initObjects BossObjectInitTable_D
InitBossObjects_TypeE:
	initObjects BossObjectInitTable_E
InitBossObjects_TypeF:
	initObjects BossObjectInitTable_F
InitBossObjects_InlineData:
	dc.b	$41, $F8, $D0, $E0, $43, $F9, $00, $00, $0E, $FA, $60, $00, $00, $0C 

InitBasicObjectSlots:
	LEA	Object_slot_base.w, A0
	LEA	BasicObjectInitTable, A1
	
; ============================================================================
; InitObjectsFromTable
; ============================================================================
; Initializes game objects (entities, handlers, sprites) from a table.
; Sets up RAM structures for VBlank/HBlank handlers, player, NPCs, enemies, etc.
;
; Input:
;   A0 = Base RAM address for object slots
;   A1 = Pointer to object initialization table
;
; Table Format:
;   Header:
;     dc.w  <count>        ; Number of object groups to initialize
;
;   Each Entry (16 bytes):
;     dc.w  <copies>       ; Number of instances to create (0-based)
;     dc.w  <size>         ; Size of each object in words minus 1
;     dc.w  <type>         ; Object type/ID
;     dc.w  <flags>        ; Attribute flags
;     dc.l  <handler>      ; Code pointer for object behavior
;     dc.l  <ram_ptr>      ; Optional: RAM address to store object pointer
;
; Object Structure Created (at A0):
;   +$00.b: Flags (from <flags>)
;   +$01.b: Type (from <type>)
;   +$02.l: Handler pointer (from <handler>)
;   +$06+:  Cleared RAM for object data
; ============================================================================
InitObjectsFromTable:
	MOVE.w	(A1)+, D7                    ; D7 = number of groups - 1 (outer loop)
.group_loop:
	MOVE.w	(A1)+, D6                    ; D6 = copies - 1 (middle loop)
	MOVE.w	(A1)+, D5                    ; D5 = object size in words - 1
	MOVE.w	(A1)+, D2                    ; D2 = object type
	MOVE.w	(A1)+, D4                    ; D4 = flags
	MOVEA.l	(A1)+, A2                    ; A2 = handler code pointer
	MOVE.l	(A1)+, D0                    ; D0 = RAM pointer destination (optional)
	BEQ.b	.init_object                 ; Skip if NULL
	MOVEA.l	D0, A4                       ; A4 = pointer to store location
	MOVE.l	A0, (A4)                     ; Store object's RAM address
.init_object:
	MOVE.w	D5, D3                       ; D3 = size counter for clearing
	LEA	(A0), A3                     ; A3 = object base address
.clear_loop:
	CLR.w	(A0)+                        ; Clear 2 bytes
	DBF	D3, .clear_loop              ; Loop until object cleared
	OR.b	D4, (A3)                     ; Set flags at +$00
	MOVE.b	D2, $1(A3)                   ; Set type at +$01
	MOVE.l	A2, $2(A3)                   ; Set handler pointer at +$02
	DBF	D6, .init_object             ; Next copy
	DBF	D7, .group_loop              ; Next group
	CLR.b	$1(A3)                       ; Clear last object's type (terminator)
	RTS
