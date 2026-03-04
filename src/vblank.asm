; ======================================================================
; src/vblank.asm
; VBlank handler, VDP scroll, controllers, input, palette DMA
; ======================================================================

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
GameplayObjectInitTable:
	dc.w	$0016                      ; 23 object groups (0-based)
	objectInitGroup 1, 40, $0050, $0000, $00000000, Enemy_list_ptr
	objectInitGroup 2, 32, $0040, $0000, $00000000, $00000000
	objectInitGroup 1, 40, $0050, $0000, $00000000, $00000000
	objectInitGroup 2, 32, $0040, $0000, $00000000, $00000000
	objectInitGroup 1, 40, $0050, $0000, $00000000, $00000000
	objectInitGroup 2, 32, $0040, $0000, $00000000, $00000000
	objectInitGroup 1, 40, $0050, $0000, $00000000, $00000000
	objectInitGroup 2, 32, $0040, $0000, $00000000, $00000000
	objectInitGroup 1, 40, $0050, $0000, $00000000, $00000000
	objectInitGroup 2, 32, $0040, $0000, $00000000, $00000000
	objectInitGroup 1, 40, $0050, $0000, $00000000, $00000000
	objectInitGroup 2, 32, $0040, $0000, $00000000, $00000000
	objectInitGroup 1, 40, $0050, $0000, $00000000, $00000000
	objectInitGroup 2, 32, $0040, $0000, $00000000, $00000000
	objectInitGroup 1, 40, $0050, $0000, $00000000, $00000000
	objectInitGroup 2, 32, $0040, $0000, $00000000, $00000000
	objectInitGroup 1, 40, $0050, $0000, $00000000, $00000000
	objectInitGroup 2, 32, $0040, $0000, $00000000, $00000000
	objectInitGroup 1, 40, $0050, $0000, $00000000, $00000000
	objectInitGroup 2, 32, $0040, $0000, $00000000, $00000000
	objectInitGroup 1, 32, $0040, $0000, $00000000, Object_slot_01_ptr
	objectInitGroup 1, 40, $0050, $0000, $00000000, Object_slot_02_ptr
	objectInitGroup 12, 32, $0040, $0000, $00000000, $00000000
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
	dc.w	$0009                      ; 10 object groups (0-based)
	objectInitGroup 1, 40, $0050, $0000, $00000000, Enemy_list_ptr
	objectInitGroup 2, 32, $0040, $0000, $00000000, $00000000
	objectInitGroup 1, 40, $0050, $0000, $00000000, Object_slot_01_ptr
	objectInitGroup 1, 32, $0040, $0000, $00000000, $00000000
	objectInitGroup 1, 40, $0050, $0000, $00000000, Object_slot_02_ptr
	objectInitGroup 3, 32, $0040, $0000, $00000000, $00000000
	objectInitGroup 1, 40, $0050, $0000, $00000000, Object_slot_03_ptr
	objectInitGroup 3, 32, $0040, $0000, $00000000, $00000000
	objectInitGroup 1, 40, $0050, $0000, $00000000, Object_slot_04_ptr
	objectInitGroup 1, 40, $0050, $0000, $00000000, Object_slot_05_ptr

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
	BTST.b	#6, IO_version
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
	MOVE.l	#DebugTestMenu, $42(A7)	
	MOVE.b	#FLAG_TRUE, Skip_tilemap_updates.w	
CheckDebugMode_end:
	RTS

ReadControllers:
	LEA	Controller_current_state.w, A0
	stopZ80
	LEA	IO_data_port_1, A1
	LEA	IO_ctrl_port_1, A2
	startZ80
	BSR.w	ReadControllerPort
	stopZ80
	LEA	IO_data_port_2, A1
	LEA	IO_ctrl_port_2, A2
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

; ============================================================================
; UpdateScrollRegs_Normal / UpdateScrollRegs_Boss
; ============================================================================
; Write the current HScroll and VScroll base values to the VDP.
;
; VDP control word $7C000002 = VRAM write to address $7C00 with auto-inc 2.
;   HScroll table at VRAM $7C00 — first two words (Plane A, Plane B) at offset 0.
;   Writing D0 twice updates both Plane A and Plane B with the same value.
;
; VDP control word $40000010 = VSRAM write to address $0000 with auto-inc 2.
;   VSRAM offset 0 = Plane A column 0 VScroll, offset 2 = Plane B column 0 VScroll.
;   Writing D0 twice scrolls both planes by the same amount.
;
; UpdateScrollRegs_Boss only writes one word for each scroll axis (single plane),
; while UpdateScrollRegs_Normal writes two (both Plane A and Plane B).
; ============================================================================
UpdateScrollRegs_Normal:
	MOVE.w	HScroll_base.w, D0
	ANDI.w	#$01FF, D0		; Clamp to 512-pixel scroll range
	MOVE.l	#$7C000002, VDP_control_port	; Set VRAM write address to HScroll table ($7C00)
	MOVE.w	D0, VDP_data_port	; Write HScroll for Plane A
	MOVE.w	D0, VDP_data_port	; Write HScroll for Plane B (same value)
	MOVE.w	VScroll_base.w, D0
	ANDI.w	#$01FF, D0		; Clamp to 512-pixel scroll range
	MOVE.l	#$40000010, VDP_control_port	; Set VSRAM write address to offset $0000
	MOVE.w	D0, VDP_data_port	; Write VScroll for Plane A
	MOVE.w	D0, VDP_data_port	; Write VScroll for Plane B (same value)
	RTS

UpdateScrollRegs_Boss:
	MOVE.w	HScroll_base.w, D0
	ANDI.w	#$01FF, D0		; Clamp to 512-pixel scroll range
	MOVE.l	#$7C000002, VDP_control_port	; Set VRAM write address to HScroll table ($7C00)
	MOVE.w	D0, VDP_data_port	; Write HScroll (Plane A only — boss uses single plane)
	MOVE.w	VScroll_base.w, D0
	ANDI.w	#$01FF, D0		; Clamp to 512-pixel scroll range
	MOVE.l	#$40000010, VDP_control_port	; Set VSRAM write address to offset $0000
	MOVE.w	D0, VDP_data_port	; Write VScroll (Plane A only)
	RTS

; ============================================================================
; CheckButtonPress
; ============================================================================
; Check if a controller button was just pressed this frame (0→1 edge).
; Input:  D2.l = bit number to check (matches the bit layout in the state byte)
; Output: D0.w = 1 if the button was just pressed this frame, 0 otherwise
;
; Method: XOR current with previous state isolates bits that changed.
;         A changed bit that was 0 in the previous state = newly pressed.
; ============================================================================
CheckButtonPress:
	MOVE.b	Controller_current_state.w, D0
	MOVE.b	Controller_previous_state.w, D1
	EOR.b	D1, D0			; D0 = bits that changed between frames
	BTST.l	D2, D0			; Did this button's bit change?
	BEQ.b	CheckButtonPress_NotPressed	; No change → not a new press
	BTST.l	D2, D1			; Was the bit set in the previous state?
	BNE.b	CheckButtonPress_NotPressed	; Was set before → this is a release, not a press
	MOVEQ	#1, D0			; New press confirmed
	RTS

CheckButtonPress_NotPressed:
	CLR.w	D0
	RTS

; ============================================================================
; DisplayHexDigits / WriteDigitToVRAM  [DEAD CODE — unreferenced]
; ============================================================================
; Render a 4-digit hex value to the window plane at the current cursor
; position.  D2.w = 16-bit value to display; D3.w = tile attribute flags.
;
; DisplayHexDigits iterates 4 times, extracting each nibble from D2 MSB-first
; (ROL #4 brings the next nibble into bits 3-0).  Nibbles 0-9 map to ASCII
; '0'–'9' ($30–$39); A–F get +7 offset to skip ':'-'@', giving $41–$46 ('A'–'F').
;
; WriteDigitToVRAM converts the ASCII digit into a tile index ($4C0 base +
; code point), applies the attribute flags in D3, then computes the VDP VRAM
; write address for the window plane cell at (Window_number_cursor_x,
; Window_number_cursor_y) and writes the tile word.
; ============================================================================
DisplayHexDigits:					; unreferenced dead code
	MOVEQ	#3, D6				; 4 digits (loop counter 3..0)
DisplayHexDigits_Done:
	ROL.w	#4, D2				; Rotate next nibble into bits 3-0
	MOVE.w	D2, D4
	ANDI.w	#$000F, D4			; Isolate nibble (0–$F)
	CMPI.w	#$9, D4				; Digit 0–9?
	BLE.b	DisplayHexDigits_Loop		; Yes → no extra offset needed
	ADDQ.w	#7, D4				; A–F: skip ':'-'@' gap in ASCII
DisplayHexDigits_Loop:
	ADDI.w	#$30, D4			; Convert to ASCII ('0'=$30 .. 'F'=$46)
	BSR.w	WriteDigitToVRAM
	DBF	D6, DisplayHexDigits_Done
	RTS
WriteDigitToVRAM:
	ADDI.w	#$4C0, D4			; Add tile base offset (tile $4C0 = '0' in font)
	ORI.w	#$8000, D4			; Set tile priority bit
	OR.w	D3, D4				; Merge palette/flip attribute flags
	MOVE.w	Window_number_cursor_x.w, D0
	MOVE.w	Window_number_cursor_y.w, D1
	ADD.w	D0, D0				; X * 2 (word offset within row)
	ASL.w	#7, D1				; Y * 128 (64 tiles/row * 2 bytes each)
	ADD.w	D1, D0				; Combined byte offset into window plane
	ANDI.l	#$00001FFF, D0			; Clamp to 8 KB window plane size
	SWAP	D0				; Move offset to upper word for VDP control word
	ORI.l	#$40000003, D0			; Set VDP VRAM write command bits
	MOVE.l	D0, VDP_control_port		; Set VDP write address
	MOVE.w	D4, VDP_data_port		; Write tile entry
	ADDQ.w	#1, Window_number_cursor_x.w	; Advance cursor one cell right
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

; HBlank interrupt handler - currently just placeholder NOPs
HBlankObjectHandler:
	NOP
	NOP
	RTS

; VBlank interrupt handler - manages program state execution
; VBlankObjectHandler
; Top-level program-state dispatcher, called every VBlank frame.
;
; On first call: clears Program_state (→ PROGRAM_STATE_SEGA_LOGO_INIT),
; sets Timer_frames_per_second = $3C (60 fps), and installs
; VBlankObjectHandler_loop as the tick function for this object so
; subsequent calls skip the one-time init.
;
; Each frame: reads Program_state, masks to 5 bits (& $1F), and if the
; value is < $16 (22), dispatches via ProgramStateMap as a computed BRA:
;   index = Program_state & $1F
;   jump  = ProgramStateMap + index * 4   (each BRA.w is 4 bytes)
;
; States >= $16 are silently ignored (no jump).
;
; State handlers are responsible for advancing Program_state when their
; phase is complete (typically MOVE.w #NEXT_STATE, Program_state.w).
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

; MOD-003: PROGRAM STATE DISPATCH TABLE
; ProgramStateMap — computed-branch table for top-level game flow.
; Indexed by Program_state (RAM $FFFFC400) masked to 5 bits.
; Each entry is a BRA.w (4 bytes); index * 4 = byte offset into table.
; See constants.asm PROGRAM_STATE_* for the symbolic index values.
;
; Index  Constant                       Target Handler
; -----  -----------------------------  --------------------------------
; $00    PROGRAM_STATE_SEGA_LOGO_INIT   ProgramState_SegaLogoInit
; $01    PROGRAM_STATE_SEGA_LOGO        ProgramState_SegaLogo
; $02    PROGRAM_STATE_TITLE_INIT       ProgramState_TitleInit
; $03    PROGRAM_STATE_TITLE_SCREEN     ProgramState_TitleScreen
; $04    PROGRAM_STATE_TITLE_DEMO       ProgramState_TitleDemo
; $05    PROGRAM_STATE_NAME_ENTRY_INIT  ProgramState_NameEntryInit
; $06    PROGRAM_STATE_NAME_ENTRY       ProgramState_NameEntry
; $07    PROGRAM_STATE_NAME_ENTRY_DONE  ProgramState_NameEntryDone
; $08    PROGRAM_STATE_PROLOGUE_INIT    ProgramState_PrologueInit
; $09    PROGRAM_STATE_PROLOGUE         ProgramState_Prologue
; $0A    PROGRAM_STATE_PROLOGUE_TO_GAME ProgramState_PrologueToGame
; $0B    PROGRAM_STATE_LOAD_SAVE_INIT   ProgramState_LoadSaveInit
; $0C    PROGRAM_STATE_LOAD_SAVE        ProgramState_LoadSave
; $0D    PROGRAM_STATE_LOAD_SAVE_DONE   ProgramState_LoadSaveDone
; $0E    PROGRAM_STATE_GAME_FADE_IN     ProgramState_GameFadeIn
; $0F    PROGRAM_STATE_GAME_ACTIVE      ProgramState_GameActive
; $10    PROGRAM_STATE_GAME_FADE_IN_2   ProgramState_GameFadeIn  (alias)
; $11    PROGRAM_STATE_GAME_ACTIVE_2    ProgramState_GameActive  (alias)
; $12    PROGRAM_STATE_ENDING_INIT      ProgramState_EndingInit
; $13    PROGRAM_STATE_ENDING           ProgramState_Ending
; $14    PROGRAM_STATE_ENDING_2         ProgramState_Ending      (alias)
; $15    PROGRAM_STATE_LOAD_SAVED_GAME  ProgramState_LoadSavedGame
;
; State flow (new game):
;   $00 → $01 → $02 → $03 → $05 → $06 → $07 → $08 → $09 → $0A → $0F
; State flow (continue/load):
;   $00 → $01 → $02 → $03 → $0B → $0C → $0D → $0E → $0F  (or $15→$0E)
; Ending:
;   $0F → ... → $12 → $13/$14
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
VBlankObjectHandler_Return:
	RTS

