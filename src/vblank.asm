; ======================================================================
; src/vblank.asm
; VBlank handler, VDP scroll, controllers, input, palette DMA
; ======================================================================

; loc_00000628
ClearScrollData:
	ORI	#$0700, SR
	MOVE.l	#$7C000002, VDP_control_port
	MOVE.w	#$01FF, D7
ClearScrollData_hscroll_loop:
	MOVE.w	#0, VDP_data_port
	DBF	D7, ClearScrollData_hscroll_loop
	MOVE.l	#0, VDP_control_port
	MOVE.w	#$01FF, D7
ClearScrollData_vscroll_loop:
	MOVE.w	#0, VDP_data_port
	DBF	D7, ClearScrollData_vscroll_loop
	CLR.w	HScroll_base.w
	CLR.w	VScroll_base.w
	ANDI	#$F8FF, SR
	RTS

; loc_0000066E
EnableDisplay:
	MOVE.w	VDP_Reg1_cache.w, D0
	BSET.l	#6, D0
	MOVE.w	D0, VDP_Reg1_cache.w
	MOVE.w	D0, VDP_control_port
	RTS

DisableVDPDisplay:
	MOVE.w	VDP_Reg1_cache.w, D0
	BCLR.l	#6, D0
	MOVE.w	D0, VDP_Reg1_cache.w
	MOVE.w	D0, VDP_control_port
	RTS

VDPRegisterDefaults:
	dc.w	$8004, $8164, $9011, $8B00, $8C81, $855C, $8D2F, $8230, $8407, $8600, $8700, $8A00, $8E00, $8F02, $9100, $9200 

; ============================================================================
; Basic Object Initialization Table
; ============================================================================
; Sets up core system objects: VBlank, HBlank, and battle entity slots.
; Used during initial startup and basic game states.
; ============================================================================
; loc_000006B6
BasicObjectInitTable:
	dc.w	$0005                        ; 6 object groups
	
	; VBlank handler object
	objectInitGroup 1, 8, $10, $80, VBlankObjectHandler, VBlank_object_ptr
	
	; HBlank handler (currently just NOPs and returns)
	objectInitGroup 1, 8, $10, $80, HBlankObjectHandler, HBlank_object_ptr
	
	; Entity slot (appears unused in this table)
	objectInitGroup 1, 32, $40, 0, PlayerObjectHandler, Player_entity_ptr
	
	; Battle entity slot 1
	objectInitGroup 1, 32, $40, 0, $00000000, Battle_entity_slot_1_ptr
	
	; Battle entity slot 2
	objectInitGroup 1, 32, $40, 0, $00000000, Battle_entity_slot_2_ptr
	
	; Additional entity slots (30 copies)
	objectInitGroup 30, 32, $40, 0, $00000000, Enemy_list_ptr

; ============================================================================
; Menu Object Initialization Table
; ============================================================================
; Minimal object setup for menu screens and simple game states.
; Only initializes entity slots and menu handler.
; ============================================================================
; loc_00000718
MenuObjectInitTable:
	dc.w	$0001                        ; 2 object groups
	
	; Entity slots (30 copies)
	objectInitGroup 30, 32, $40, 0, $00000000, Enemy_list_ptr
	
	; Menu handler object
	objectInitGroup 1, 8, $10, $80, MenuObjectHandler, Menu_object_ptr

; ============================================================================
; Gameplay Object Initialization Table
; ============================================================================
; Full object setup for active gameplay (overworld, caves, battles).
; Initializes 23 object groups with entity slots for player, NPCs, enemies, etc.
; ============================================================================
; loc_0000073A
GameplayObjectInitTable:
	dc.w	$16                        ; 23 object groups (0x16 = 22 decimal, 0-based)
	
	dc.w	$0000, $0027, $0050, $0000 
	dc.l	$00000000
	dc.l	Enemy_list_ptr
	
	dc.w	$0001, $001F, $0040, $0000 
	dc.l	$00000000 
	dc.l	$00000000
	
	dc.w	$0000, $0027, $0050, $0000
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0001, $001F, $0040, $0000
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0000, $0027, $0050, $0000
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0001, $001F, $0040, $0000
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0000, $0027, $0050, $0000
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0001, $001F, $0040, $0000
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0000, $0027, $0050, $0000
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0001, $001F, $0040, $0000 
	dc.l	$00000000 
	dc.l	$00000000
	
	dc.w	$0000, $0027, $0050, $0000
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0001, $001F, $0040, $0000
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0000, $0027, $0050, $0000
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0001, $001F, $0040, $0000
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0000, $0027, $0050, $0000
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0001, $001F, $0040, $0000
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0000, $0027, $0050, $0000 
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0001,$001F, $0040, $0000
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0000, $0027, $0050, $0000
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0001, $001F, $0040, $0000
	dc.l	$00000000
	dc.l	$00000000
	
	dc.w	$0000, $001F, $0040, $0000
	dc.l	$00000000
	dc.l	$FFFFCC18
	
	dc.w	$0000, $0027, $0050, $0000
	dc.l	$00000000
	dc.l	$FFFFCC1C
	
	dc.w	$000B, $001F, $0040, $0000
	dc.l	$00000000
	dc.l	$00000000
BattleObjectInitTable:
	dc.b	$00, $1C, $00, $00, $00, $07, $00, $10, $00, $00, $00, $00, $00, $00, $FF, $FF, $CC, $50, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $54, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $27, $00, $50, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $14, $00, $04, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $18, $00, $04, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $1C, $00, $04, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $20, $00, $04, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $24, $00, $04, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $28, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $2C, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $30, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $34, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $38, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $3C, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF, $CC, $40, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $44, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF, $CC, $48, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $4C, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
BossObjectInitTable_A:
	dc.b	$00, $0C, $00, $00, $00, $27, $00, $50, $00, $00, $00, $00, $00, $00, $FF, $FF, $CC, $14, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $18, $00, $03, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $27, $00, $50, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $1C, $00, $01, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $27, $00, $50, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $20, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $27, $00, $50, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $24, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $27, $00, $50, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $28, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $27, $00, $50, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $2C, $00, $01, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
BossObjectInitTable_B:
	dc.w	$9

	dc.w	$0000, $0027, $0050, $0000 
	dc.l	$00000000 
	dc.l	Enemy_list_ptr 

	dc.w	$0001, $001F, $0040, $0000 
	dc.l	$00000000 
	dc.l	$00000000 

	dc.w	$0000, $0027, $0050, $0000 
	dc.l	$00000000 
	dc.l	$FFFFCC18 

	dc.w	$0000, $001F, $0040, $0000
	dc.l	$00000000 
	dc.l	$00000000 

	dc.w	$0000, $0027, $0050, $0000
	dc.l	$00000000 
	dc.l	$FFFFCC1C 

	dc.w	$0002, $001F, $0040, $0000 
	dc.l	$00000000 
	dc.l	$00000000 

	dc.w	$0000, $0027, $0050, $0000 
	dc.l	$00000000 
	dc.l	$FFFFCC20 

	dc.w	$0002, $001F, $0040, $0000 
	dc.l	$00000000 
	dc.l	$00000000 

	dc.w	$0000, $0027, $0050, $0000
	dc.l	$00000000 
	dc.l	$FFFFCC24 

	dc.w	$0000, $0027, $0050, $0000 
	dc.l	$00000000 
	dc.l	$FFFFCC28 

BossObjectInitTable_C:
	dc.b	$00, $0E, $00, $00, $00, $27, $00, $50, $00, $00, $00, $00, $00, $00, $FF, $FF, $CC, $14, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $18, $00, $04, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $1C, $00, $07, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $20, $00, $07, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $24, $00, $07, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $28, $00, $08, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $2C, $00, $08, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $30, $00, $02, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
BossObjectInitTable_D:
	dc.b	$00, $06, $00, $00, $00, $27, $00, $50, $00, $00, $00, $00, $00, $00, $FF, $FF, $CC, $14, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $18, $00, $04, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $1C, $00, $03, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $20, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
BossObjectInitTable_E:
	dc.b	$00, $12, $00, $00, $00, $27, $00, $50, $00, $00, $00, $00, $00, $00, $FF, $FF, $CC, $14, $00, $01, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00 
	dc.b	$00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF, $CC, $18, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $1C, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $20, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $24, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $28, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $2C, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $30, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $34, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $38, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 
BossObjectInitTable_F:
	dc.b	$00, $06, $00, $00, $00, $27, $00, $50, $00, $00, $00, $00, $00, $00, $FF, $FF, $CC, $14, $00, $00, $00, $27, $00, $50, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $18, $00, $03, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF 
	dc.b	$CC, $1C, $00, $00, $00, $27, $00, $50, $00, $00, $00, $00, $00, $00, $FF, $FF, $CC, $20, $00, $03, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $00, $00 
	dc.b	$00, $00, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00, $FF, $FF, $CC, $24, $00, $02, $00, $00, $00, $1F, $00, $40, $00, $00, $00, $00, $00, $00 
	dc.b	$FF, $FF, $CC, $14, $00, $3F, $00, $0F, $00, $20, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $0F, $00, $0F, $00, $20, $00, $00, $00, $00, $00, $00 
	dc.b	$00, $00, $00, $00 

	include "init.asm"

VerticalInterrupt:

	MOVEM.l	A6/A5/A4/A3/A2/A1/A0/D7/D6/D5/D4/D3/D2/D1/D0, -(A7)
	MOVE.w	VDP_control_port, D0
	TST.b	Boss_max_hp.w
	BEQ.b	VerticalInterrupt_Loop
	BSR.w	UpdateScrollRegs_Boss
	BRA.b	VerticalInterrupt_Loop2
VerticalInterrupt_Loop:
	BSR.w	UpdateScrollRegs_Normal
VerticalInterrupt_Loop2:
	TST.b	Sprite_update_pending.w
	BEQ.b	VerticalInterrupt_Loop3
	JSR	FlushSpriteAttributesToVDP
	CLR.b	Sprite_update_pending.w
VerticalInterrupt_Loop3:
	TST.b	Sprite_dma_update_pending.w
	BEQ.b	VerticalInterrupt_Loop4
	JSR	UpdatePlayerSpriteDMA
	CLR.b	Sprite_dma_update_pending.w
VerticalInterrupt_Loop4:
	BSR.w	ProcessSoundQueue
	BTST.b	#6, $00A10001
	BEQ.b	VBlank_ProcessPalette
	ADDQ.w	#1, Vblank_frame_counter.w	
	MOVE.w	Vblank_frame_counter.w, D4	
	ANDI.w	#3, D4	
	BNE.w	VerticalInterrupt_Loop5	
	JSR	UpdateBattleEntities	
	MOVE.w	#$021D, D7	
VerticalInterrupt_Loop4_Done:
	NOP	
	DBF	D7, VerticalInterrupt_Loop4_Done	
	BRA.b	VBlank_ProcessPalette	
VerticalInterrupt_Loop5:
	MOVE.w	#$0657, D7	
VerticalInterrupt_Loop5_Done:
	NOP	
	DBF	D7, VerticalInterrupt_Loop5_Done	
; loc_0000115C
VBlank_ProcessPalette:
	JSR	UpdatePaletteBuffer
	TST.b	Skip_tilemap_updates.w
	BNE.w	VBlank_ProcessPalette_Loop
	TST.b	Town_tilemap_row_update_pending.w
	BEQ.b	VBlank_ProcessPalette_Loop2
	JSR	UpdateTownTilemapRow
	CLR.b	Town_tilemap_row_update_pending.w
VBlank_ProcessPalette_Loop2:
	TST.b	Town_tilemap_column_update_pending.w
	BEQ.b	VBlank_ProcessPalette_Loop3
	JSR	UpdateTownTilemapColumn
	CLR.b	Town_tilemap_column_update_pending.w
VBlank_ProcessPalette_Loop3:
	TST.b	Window_tilemap_draw_active.w
	BEQ.b	VBlank_ProcessPalette_Loop4
	JSR	DrawWindowTilemapRow
VBlank_ProcessPalette_Loop4:
	TST.b	Window_tilemap_row_draw_pending.w
	BEQ.b	VBlank_ProcessPalette_Loop5
	JSR	DispatchWindowDrawType
VBlank_ProcessPalette_Loop5:
	TST.b	Window_tilemap_draw_pending.w
	BEQ.b	VBlank_ProcessPalette_Loop6
	JSR	DrawWindowTilemapFull
VBlank_ProcessPalette_Loop6:
	TST.b	Scene_update_flag.w
	BEQ.b	VBlank_ProcessPalette_Loop7
	BSR.w	UpdateSceneScrollBuffers
	CLR.b	Scene_update_flag.w
VBlank_ProcessPalette_Loop7:
	BSR.w	CheckDebugMode
VBlank_ProcessPalette_Loop:
	JSR	UpdateBattleEntities
	BSR.w	ReadControllers
	ST	Vblank_flag.w
	MOVEM.l	(A7)+, D0/D1/D2/D3/D4/D5/D6/D7/A0/A1/A2/A3/A4/A5/A6
	RTE
CheckDebugMode:
	MOVE.b	Controller_2_current_state.w, D0
	CMPI.b	#$F0, D0
	BNE.b	CheckDebugMode_end
	MOVE.l	#loc_003C6E8, $42(A7)	
	MOVE.b	#FLAG_TRUE, Skip_tilemap_updates.w	
CheckDebugMode_end:
	RTS

ReadControllers:
	LEA	Controller_current_state.w, A0
	stopZ80
	LEA	$00A10003, A1
	LEA	$00A10009, A2
	startZ80
	BSR.w	ReadControllerPort
	stopZ80
	LEA	$00A10005, A1
	LEA	$00A1000B, A2
	startZ80
ReadControllerPort:
	MOVE.b	(A0), $1(A0)
	BSET.b	#6, (A2)
	BCLR.b	#6, (A1)
	NOP
	NOP
	MOVE.b	(A1), D0
	MOVE.b	D0, D1
	ANDI.b	#$0C, D0
	BEQ.b	ReadControllerPort_Loop
	MOVE.b	#$FF, D1
ReadControllerPort_Loop:
	ASL.b	#2, D1
	ANDI.b	#$C0, D1
	BSET.b	#6, (A1)
	NOP
	NOP
	NOP
	MOVE.b	(A1), D0
	ANDI.b	#$3F, D0
	OR.b	D1, D0
	NOT.b	D0
	MOVE.b	D0, (A0)
	LEA	$2(A0), A0
	RTS

UpdateScrollRegs_Normal:
	MOVE.w	HScroll_base.w, D0
	ANDI.w	#$01FF, D0
	MOVE.l	#$7C000002, VDP_control_port
	MOVE.w	D0, VDP_data_port
	MOVE.w	D0, VDP_data_port
	MOVE.w	VScroll_base.w, D0
	ANDI.w	#$01FF, D0
	MOVE.l	#$40000010, VDP_control_port
	MOVE.w	D0, VDP_data_port
	MOVE.w	D0, VDP_data_port
	RTS

UpdateScrollRegs_Boss:
	MOVE.w	HScroll_base.w, D0
	ANDI.w	#$01FF, D0
	MOVE.l	#$7C000002, VDP_control_port
	MOVE.w	D0, VDP_data_port
	MOVE.w	VScroll_base.w, D0
	ANDI.w	#$01FF, D0
	MOVE.l	#$40000010, VDP_control_port
	MOVE.w	D0, VDP_data_port
	RTS

; CheckButtonPress
; Check if a controller button was just pressed
; Input: D2.l = Bit number to check
; Output: D0.w = 1 if button was just pressed, 0 otherwise
; Detects 0→1 transition (button was released, now pressed)
CheckButtonPress:
	MOVE.b	Controller_current_state.w, D0
	MOVE.b	Controller_previous_state.w, D1
	EOR.b	D1, D0
	BTST.l	D2, D0
	BEQ.b	CheckButtonPress_NotPressed
	BTST.l	D2, D1
	BNE.b	CheckButtonPress_NotPressed
	MOVEQ	#1, D0
	RTS

; loc_00001308
CheckButtonPress_NotPressed:
	CLR.w	D0
	RTS

DisplayHexDigits:					; unreferenced dead code
	MOVEQ	#3, D6
DisplayHexDigits_Done:
	ROL.w	#4, D2
	MOVE.w	D2, D4
	ANDI.w	#$000F, D4
	CMPI.w	#$9, D4
	BLE.b	DisplayHexDigits_Loop
	ADDQ.w	#7, D4
DisplayHexDigits_Loop:
	ADDI.w	#$30, D4
	BSR.w	WriteDigitToVRAM
	DBF	D6, DisplayHexDigits_Done
	RTS
WriteDigitToVRAM:
	ADDI.w	#$4C0, D4
	ORI.w	#$8000, D4
	OR.w	D3, D4
	MOVE.w	Window_number_cursor_x.w, D0
	MOVE.w	Window_number_cursor_y.w, D1
	ADD.w	D0, D0
	ASL.w	#7, D1
	ADD.w	D1, D0
	ANDI.l	#$00001FFF, D0
	SWAP	D0
	ORI.l	#$40000003, D0
	MOVE.l	D0, VDP_control_port
	MOVE.w	D4, VDP_data_port
	ADDQ.w	#1, Window_number_cursor_x.w
	RTS

UpdateSceneScrollBuffers:
	TST.b	HScroll_full_update_flag.w
	BNE.b	UpdateSceneScrollBuffers_Loop
	MOVE.w	VScroll_base.w, D0
	BEQ.b	UpdateSceneScrollBuffers_Loop2
	ADDQ.w	#1, VScroll_base.w
	ANDI.w	#$01FF, D0
	MOVE.l	#$40000010, VDP_control_port
	MOVE.w	D0, VDP_data_port
	MOVE.w	D0, VDP_data_port
	RTS

UpdateSceneScrollBuffers_Loop:
	BSR.w	FillVScrollTable
UpdateSceneScrollBuffers_Loop2:
	CLR.b	HScroll_update_busy.w
	LEA	HScroll_run_table.w, A0
	MOVE.l	#$7E620002, D0
	MOVE.w	#2, D7
	BSR.w	WriteHScrollRunToVRAM
	MOVE.w	#3, D7
	BSR.w	WriteHScrollRunToVRAM
	MOVE.w	#4, D7
	BSR.w	WriteHScrollRunToVRAM
	MOVE.w	#4, D7
	BSR.w	WriteHScrollRunToVRAM
	MOVE.w	#5, D7
	BSR.w	WriteHScrollRunToVRAM
	MOVE.w	#6, D7
	BSR.w	WriteHScrollRunToVRAM
	MOVE.w	#7, D7
	BSR.w	WriteHScrollRunToVRAM
	MOVE.w	#8, D7
	BSR.w	WriteHScrollRunToVRAM
	MOVE.w	#8, D7
	BSR.w	WriteHScrollRunToVRAM
	MOVE.w	#11, D7
	BSR.w	WriteHScrollRunToVRAM
	MOVE.w	#11, D7
	BSR.w	WriteHScrollRunToVRAM
	RTS

; loc_000013FC
WriteHScrollRunToVRAM:
	MOVE.w	(A0), D1
	ANDI.w	#$01FF, D1
	MOVE.l	D0, VDP_control_port
	MOVE.w	D1, VDP_data_port
	ADDI.l	#$00040000, D0
	DBF	D7, WriteHScrollRunToVRAM
	LEA	$4(A0), A0
	RTS

FillVScrollTable:
	MOVE.l	#$7C000002, D0
	MOVE.w	Ending_hscroll_offset.w, D1
	ANDI.w	#$01FF, D1
	MOVE.w	#$00DF, D7
FillVScrollTable_loop:
	MOVE.l	D0, VDP_control_port
	MOVE.w	D1, VDP_data_port
	ADDI.l	#$00040000, D0
	DBF	D7, FillVScrollTable_loop
	RTS

ProcessSoundQueue:
	MOVE.w	Sound_queue_count.w, D0
	BLE.b	ProcessSoundQueue_empty
	LEA	Sound_queue_buffer.w, A0
	MOVE.b	(A0), Sound_driver_play.w
	LEA	$1(A0), A1
	MOVE.b	(A1)+, (A0)+
	MOVE.b	(A1)+, (A0)+
	MOVE.b	(A1)+, (A0)+
	MOVE.b	(A1)+, (A0)+
	MOVE.b	(A1)+, (A0)+
	MOVE.b	(A1)+, (A0)+
	MOVE.b	(A1)+, (A0)+
	SUBQ.w	#1, Sound_queue_count.w
ProcessSoundQueue_empty:
	RTS

; loc_0000146E
; HBlank interrupt handler - currently just placeholder NOPs
HBlankObjectHandler:
	NOP
	NOP
	RTS

; loc_00001474
; VBlank interrupt handler - manages program state execution
VBlankObjectHandler:
	CLR.w	Program_state.w
	MOVE.w	#$3C, Timer_frames_per_second.w
	MOVE.l	#VBlankObjectHandler_loop, obj_tick_fn(A5)
VBlankObjectHandler_loop:
	MOVE.w	Program_state.w, D0
	ANDI.w	#$1F, D0
	CMPI.w	#$16, D0
	BGE.w	VBlankObjectHandler_Return
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ProgramStateMap, A0
	JSR	(A0,D0.w)
	BRA.w	VBlankObjectHandler_Return

;loc_000014A8:
ProgramStateMap:
	BRA.w	ProgramState_SegaLogoInit		; $00 Initialize Sega logo
	BRA.w	ProgramState_SegaLogo			; $01 Sega logo display
	BRA.w	ProgramState_TitleInit			; $02 Initialize title screen
	BRA.w	ProgramState_TitleScreen		; $03 Title screen (menu input)
	BRA.w	ProgramState_TitleDemo			; $04 Demo loop / second Sega screen
	BRA.w	ProgramState_NameEntryInit		; $05 Transition: title -> name entry
	BRA.w	ProgramState_NameEntry			; $06 Name entry screen
	BRA.w	ProgramState_NameEntryDone		; $07 Transition: name entry -> prologue
	BRA.w	ProgramState_PrologueInit		; $08 Initialize prologue
	BRA.w	ProgramState_Prologue			; $09 Prologue playing
	BRA.w	ProgramState_PrologueToGame		; $0A Transition: prologue -> main game
	BRA.w	ProgramState_LoadSaveInit		; $0B Transition: title -> file select
	BRA.w	ProgramState_LoadSave			; $0C File select / continue screen
	BRA.w	ProgramState_LoadSaveDone		; $0D Transition: file select -> game
	BRA.w	ProgramState_GameFadeIn			; $0E Fade in to main game
	BRA.w	ProgramState_GameActive			; $0F Main game running
	BRA.w	ProgramState_GameFadeIn			; $10 Fade in to main game (alias)
	BRA.w	ProgramState_GameActive			; $11 Main game running (alias)
	BRA.w	ProgramState_EndingInit			; $12 Initialize ending sequence
	BRA.w	ProgramState_Ending			; $13 Ending sequence
	BRA.w	ProgramState_Ending			; $14 Ending sequence (alias)
	BRA.w	ProgramState_LoadSavedGame		; $15 Load saved game, initialize town
; loc_00001500
VBlankObjectHandler_Return:
	RTS

;loc_00001502:
