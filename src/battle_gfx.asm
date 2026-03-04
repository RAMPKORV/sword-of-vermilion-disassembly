; ======================================================================
; src/battle_gfx.asm
; Battle graphics loading, DMA, tile decompression
; ======================================================================
WriteDirectionTilesForBoss:
	ORI	#$0700, SR
	LEA	BossDirectionTilePtrs, A0
	MOVEA.l	(A0,D0.w), A0
	MOVE.l	#$40080003, D5
	MOVE.w	#5, D7
WriteDirectionTilesForBoss_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#4, D6
WriteDirectionTilesForBoss_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$A200, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, WriteDirectionTilesForBoss_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, WriteDirectionTilesForBoss_Done
	ANDI	#$F8FF, SR
	RTS
	
CalculateDirectionToEntity:
	LEA	DirectionToEntityLookup, A1
	MOVE.w	obj_world_x(A6), D0
	SUB.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A6), D1
	SUB.w	obj_world_y(A5), D1
	BRA.w	GetDirectionFromDeltas
CalculateDirectionToPlayer:
	LEA	DirectionToPlayerLookup, A1
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), D0
	MOVE.w	obj_world_x(A5), D1
	ADDI.w	#$0018, D1
	SUB.w	D1, D0
	MOVE.w	obj_world_y(A6), D1
	MOVE.w	obj_world_y(A5), D2
	ADDI.w	#$0058, D2
	SUB.w	D2, D1
GetDirectionFromDeltas:
	CLR.w	D2
	TST.w	D0
	BGE.b	GetDirectionFromDeltas_Loop
	NEG.w	D0
	MOVE.w	#8, D2
GetDirectionFromDeltas_Loop:
	TST.w	D1
	BGE.b	GetDirectionFromDeltas_Loop2
	NEG.w	D1
	ORI.w	#4, D2
GetDirectionFromDeltas_Loop2:
	CMP.w	D1, D0
	BGE.b	GetDirectionFromDeltas_Loop3
	ORI.w	#2, D2
	ASR.w	#1, D1
	BGE.b	GetDirectionFromDeltas_Loop4
GetDirectionFromDeltas_Loop3:
	ASR.w	#1, D0
GetDirectionFromDeltas_Loop4:
	CMP.w	D1, D0
	BGE.b	GetDirectionFromDeltas_Loop5
	ORI.w	#1, D2
GetDirectionFromDeltas_Loop5:
	ADDA.w	D2, A1
	CLR.w	D0
	MOVE.b	(A1), D0
	CLR.w	D2
	MOVE.b	obj_direction(A5), D2
	MOVE.w	D2, D3
	SUB.w	D0, D3
	BNE.b	GetDirectionFromDeltas_Loop6
	MOVE.b	D0, obj_direction(A5)
	BRA.w	BossBody_AngleReturn
GetDirectionFromDeltas_Loop6:
	BGT.w	GetDirectionFromDeltas_Loop7
	NEG.w	D3
	MOVE.w	#$0100, D4
	SUB.w	D0, D4
	ADD.w	D2, D4
	CMP.w	D3, D4
	BLE.w	BossBody_AngleDecrease
	BRA.w	GetDirectionFromDeltas_Loop8
GetDirectionFromDeltas_Loop7:
	MOVE.w	#$0100, D4
	SUB.w	D2, D4
	ADD.w	D0, D4
	CMP.w	D3, D4
	BGE.w	BossBody_AngleDecrease
GetDirectionFromDeltas_Loop8:
	ADDQ.b	#1, obj_direction(A5)
	BRA.w	BossBody_AngleReturn
BossBody_AngleDecrease:
	SUBQ.b	#1, obj_direction(A5)
BossBody_AngleReturn:
	RTS
	
BossBodyUpperTilePtrs:
	dc.l	BossBodyUpperTilePtrs_Gfx_780E4
	dc.l	SpriteMetaTileTable_780F4
	dc.l	BossBodyUpperTilePtrs_Gfx_78104
	dc.l	SpriteMetaTileTable_780F4
BossBodyLowerTilePtrs:
	dc.l	BossBodyLowerTilePtrs_Gfx_78114
	dc.l	SpriteMetaTileTable_78120
	dc.l	BossBodyLowerTilePtrs_Gfx_7812C
	dc.l	SpriteMetaTileTable_78120
BossDirectionTilePtrs:
	dc.l	SpriteMetaTileTable_7808A
	dc.l	BossDirectionTilePtrs_Gfx_780A8
	dc.l	SpriteMetaTileTable_780C6
	dc.l	SpriteMetaTileTable_780C6	
WriteTilesToVRAM:
	LEA	BossTileSourceTable, A0
	MOVE.w	D0, D1
	ADD.w	D1, D1
	ADD.w	D1, D1
	ASL.w	#3, D0
	ADD.w	D1, D0
	LEA	(A0,D0.w), A0
	MOVEA.l	(A0)+, A1
	MOVE.w	(A0)+, D6
	MOVE.w	(A0)+, D7
	MOVE.l	(A0)+, D5
	ORI	#$0700, SR
WriteTilesToVRAM_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	D6, D4
WriteTilesToVRAM_Done2:
	CLR.w	D0
	MOVE.b	(A1)+, D0
	ADDI.w	#$2200, D0
	MOVE.w	D0, VDP_data_port
	DBF	D4, WriteTilesToVRAM_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, WriteTilesToVRAM_Done
	ANDI	#$F8FF, SR
	RTS
	
DirectionToPlayerLookup:
	dc.b	$C0, $A0, $A0, $80, $C0, $E0, $E0, $00, $40 
	dc.b	$60
	dc.b	$60
	dc.b	$80
	dc.b	$40, $20, $20, $00 
DirectionToEntityLookup:
	dc.b	$40, $60, $60, $00, $40, $60, $60 
	dc.b	$80
	dc.b	$C0
	dc.b	$E0
	dc.b	$E0, $00, $C0, $A0, $A0, $80 
; AddSpriteToDisplayList
; Add sprite to display list for rendering
; Checks sprite bounds, calculates position, and adds to sprite buffer
; Input: A5 = Object data pointer
AddSpriteToDisplayList:
	ORI	#$0700, SR
	MOVE.w	obj_screen_y(A5), D5
	BLE.w	AddSpriteToDisplayList_Return
	MOVE.b	obj_sprite_size(A5), D0
	MOVE.b	D0, D1
	ANDI.w	#3, D0
	ADDQ.w	#1, D0
	ASL.w	#3, D0
	SUB.w	D0, D5
	CMPI.w	#$00E0, D5
	BGE.w	AddSpriteToDisplayList_Return
	ANDI.w	#$000C, D1
	ADDQ.w	#4, D1
	MOVE.w	obj_screen_x(A5), D6
	MOVE.w	D6, D4
	ADD.w	D1, D4
	BLE.w	AddSpriteToDisplayList_Return
	SUB.w	D1, D6
	CMPI.w	#BATTLE_FIELD_WIDTH, D6
	BGE.w	AddSpriteToDisplayList_Return
	LEA	Sprite_sort_buffer.w, A0
	MOVE.w	Sprite_attr_count.w, D0
	ASL.w	#3, D0
	ADDA.w	D0, A0
	ADDI.w	#$0080, D5
	ADDI.w	#$0080, D6
	MOVE.w	D5, (A0)+
	MOVE.b	obj_sprite_size(A5), D0
	ASL.w	#8, D0
	ANDI.w	#$0F00, D0
	MOVE.w	D0, (A0)+
	MOVE.b	obj_sprite_flags(A5), D0
	ASL.w	#8, D0
	MOVE.w	obj_tile_index(A5), D1
	ADD.w	D1, D0
	MOVE.w	D0, (A0)+
	MOVE.w	D6, (A0)
	LEA	Sprite_priority_slots.w, A0
	MOVE.w	obj_sort_key(A5), D0
	ANDI.w	#$00FF, D0
	MOVE.w	#$00FF, D7
	SUB.w	D0, D7
	ASL.w	#4, D7
	ADDA.w	D7, A0
AddSpriteToDisplayList_Done:
	CMPI.b	#$0F, (A0)
	BLT.b	AddSpriteToDisplayList_Loop
	LEA	$10(A0), A0
	DBF	D0, AddSpriteToDisplayList_Done
	BRA.b	AddSpriteToDisplayList_Return	
AddSpriteToDisplayList_Loop:
	ADDQ.b	#1, (A0)
	MOVE.b	(A0), D0
	ANDI.w	#$000F, D0
	MOVE.w	Sprite_attr_count.w, D1
	MOVE.b	D1, (A0,D0.w)
	ADDQ.w	#1, Sprite_attr_count.w
AddSpriteToDisplayList_Return:
	ANDI	#$F8FF, SR
	RTS
	
FlushSpriteAttributesToVDP:
	MOVE.l	#$78000002, VDP_control_port
	MOVE.w	Sprite_attr_count.w, D0
	SUBQ.w	#1, D0
	BLT.b	FlushSpriteAttributesToVDP_Loop
	LEA	Sprite_attr_buffer.w, A2
FlushSpriteAttributesToVDP_Done:
	MOVE.w	(A2)+, VDP_data_port
	MOVE.w	(A2)+, VDP_data_port
	MOVE.w	(A2)+, VDP_data_port
	MOVE.w	(A2)+, VDP_data_port
	DBF	D0, FlushSpriteAttributesToVDP_Done
FlushSpriteAttributesToVDP_Loop:
	MOVE.w	#0, VDP_data_port
	MOVE.w	#0, VDP_data_port
	MOVE.w	#0, VDP_data_port
	MOVE.w	#0, VDP_data_port
	RTS
	
QueueSpriteOAMIfVisible:
	LEA	Sprite_attr_buffer.w, A0
	MOVE.w	Sprite_attr_count.w, D0
	MOVE.w	D0, D4
	ADDQ.w	#1, D4
	ASL.w	#3, D0
	LEA	(A0,D0.w), A0
	MOVE.w	obj_screen_y(A5), D3
	BLE.w	QueueSpriteOAM_Return
	MOVE.b	obj_sprite_size(A5), D1
	MOVE.b	D1, D0
	ANDI.w	#$000C, D0
	ANDI.w	#3, D1
	ADDQ.w	#1, D1
	ADDQ.w	#4, D0
	ASL.w	#3, D1
	SUB.w	D1, D3
	CMPI.w	#$00E0, D3
	BGE.w	QueueSpriteOAM_Return
	MOVE.w	obj_screen_x(A5), D1
	MOVE.w	D1, D2
	ADD.w	D0, D2
	BLE.w	QueueSpriteOAM_Return
	SUB.w	D0, D1
	CMPI.w	#BATTLE_FIELD_WIDTH, D1
	BGE.w	QueueSpriteOAM_Return
	ADDI.w	#$0080, D3
	ADDI.w	#$0080, D1
	MOVE.w	D3, (A0)
	MOVE.w	D1, $6(A0)
	MOVE.b	obj_sprite_size(A5), D0
	ASL.w	#8, D0
	ANDI.w	#$0F00, D0
	ADD.w	D4, D0
	MOVE.w	D0, $2(A0)
	MOVE.b	obj_sprite_flags(A5), D0
	ASL.w	#8, D0
	MOVE.w	obj_tile_index(A5), D1
	ADD.w	D1, D0
	MOVE.w	D0, $4(A0)
	ADDQ.w	#1, Sprite_attr_count.w
QueueSpriteOAM_Return:
	RTS
	
SortAndUploadSpriteOAM:
	ORI	#$0700, SR
	TST.w	Sprite_attr_count.w
	BLE.w	QueueSpriteOAM_Return_Loop
	LEA	Sprite_sort_temp_buffer.w, A1
	LEA	Sprite_attr_buffer.w, A4
	LEA	Sprite_sort_buffer.w, A2
	CLR.w	D1
	MOVE.w	#$0010, D5
	MOVE.w	#$00FF, D0
QueueSpriteOAM_Return_Done:
	ADDA.w	D5, A1
	TST.b	(A1)
	BEQ.w	QueueSpriteOAM_Return_Loop2
	CLR.w	D6
	MOVE.b	(A1), D6
	ANDI.w	#$000F, D6
	SUBQ.w	#1, D6
	BLT.w	QueueSpriteOAM_Return_Loop3
QueueSpriteOAM_Return_Done2:
	MOVE.b	$1(A1,D6.w), D4
	ANDI.w	#$007F, D4
	ASL.w	#3, D4
	LEA	(A2,D4.w), A3
	MOVE.w	(A3)+, (A4)+
	MOVE.w	(A3)+, D2
	ADDQ.w	#1, D1
	ADD.w	D1, D2
	MOVE.w	D2, (A4)+
	MOVE.w	(A3)+, (A4)+
	MOVE.w	(A3), (A4)+
	DBF	D6, QueueSpriteOAM_Return_Done2
	CLR.b	(A1)
QueueSpriteOAM_Return_Loop2:
	DBF	D0, QueueSpriteOAM_Return_Done
QueueSpriteOAM_Return_Loop:
	ANDI	#$F8FF, SR
	RTS
	
QueueSpriteOAM_Return_Loop3:
	RTE	
SortAndUploadSpriteOAM_Alt:
	MOVE.w	#$001F, D7
	LEA	Sprite_priority_slots.w, A0
QueueSpriteOAM_Return_Loop3_Done:
	CLR.b	(A0)
	LEA	$10(A0), A0
	CLR.b	(A0)
	LEA	$10(A0), A0
	CLR.b	(A0)
	LEA	$10(A0), A0
	CLR.b	(A0)
	LEA	$10(A0), A0
	CLR.b	(A0)
	LEA	$10(A0), A0
	CLR.b	(A0)
	LEA	$10(A0), A0
	CLR.b	(A0)
	LEA	$10(A0), A0
	CLR.b	(A0)
	LEA	$10(A0), A0
	DBF	D7, QueueSpriteOAM_Return_Loop3_Done
	ANDI	#$F8FF, SR
	RTS
	
LoadEncounterGraphics:
	LEA	EncounterTileData_Entry-2, A6
	MOVE.w	(A6)+, Vdp_dma_slot_index.w
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A6)+, A4
	MOVEA.l	(A6)+, A3
	MOVE.w	(A6)+, D5
	BSR.w	LoadMultipleTilesFromTable
	BSR.w	ExecuteVdpDmaTransfer
	LEA	GfxLoadList_OverworldBattle-2, A6
	MOVE.w	(A6)+, Vdp_dma_slot_index.w
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A6)+, A4
	MOVEA.l	(A6)+, A3
	MOVE.w	(A6)+, D5
	BSR.w	LoadMultipleTilesFromTable
	BSR.w	ExecuteVdpDmaTransfer
	LEA	EnemyGfxDataTable, A6
	MOVE.w	Current_encounter_type.w, D0
	MULU.w	#$000C, D0
	ADDQ.w	#8, D0
	MOVEA.l	(A6,D0.w), A6
	MOVE.w	#$0035, Vdp_dma_slot_index.w
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A6)+, A4
	MOVEA.l	(A6)+, A3
	MOVE.w	(A6)+, D5
	BSR.w	LoadMultipleTilesFromTable
	BSR.w	ExecuteVdpDmaTransfer
	MOVE.w	#$0036, Vdp_dma_slot_index.w
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A6)+, A4
	MOVEA.l	(A6)+, A3
	MOVE.w	(A6)+, D5
	BSR.w	LoadMultipleTilesFromTable
	BSR.w	ExecuteVdpDmaTransfer
	MOVE.l	(A6), D0
	BLE.b	LoadEncounterGraphics_Loop
	MOVE.w	#$003C, Vdp_dma_slot_index.w
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A6)+, A4
	MOVEA.l	(A6)+, A3
	MOVE.w	(A6)+, D5
	BSR.w	LoadMultipleTilesFromTable
	BSR.w	ExecuteVdpDmaTransfer
LoadEncounterGraphics_Loop:
	RTS
	
LoadMagicGraphics:
	LEA	MagicGfxDataPtrs, A6
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A6,D0.w), A6
	MOVE.w	#$0043, Vdp_dma_slot_index.w
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A6)+, A4
	MOVEA.l	(A6)+, A3
	MOVE.w	(A6)+, D5
	MOVE.w	(A6), Palette_line_0_index.w
	BSR.w	LoadMultipleTilesFromTable
	BSR.w	ExecuteVdpDmaTransfer
	JSR	LoadPalettesFromTable
	RTS
	
LoadEncounterTypeGraphics:
	LEA	Tile_gfx_buffer.w, A2
	LEA	EnemyEncounterGroupTable, A1
	CLR.w	D2
	MOVE.b	Encounter_group_index.w, D2
	ADD.w	D2, D2
	ADD.w	D2, D2
	MOVEA.l	(A1,D2.w), A6
	MOVE.w	Random_number.w, D0
	ADD.w	D0, D0
	MOVE.w	(A6,D0.w), D1 ; Get the specific, of the 4 possible, encounter types
	MOVE.w	D1, Current_encounter_type.w
	LEA	EnemyGfxDataTable, A6
	MULU.w	#$C, D1
	MOVEA.l	(A6,D1.w), A6
	MOVE.l	A6, Current_encounter_gfx_ptr.w
	MOVEA.l	obj_active(A6), A4
	MOVEA.l	$4(A6), A3
	MOVE.w	#$000F, D5
	BSR.w	LoadMultipleTilesFromTable
	LEA	Enemy_gfx_buffer.w, A2
	MOVEA.l	Current_encounter_gfx_ptr.w, A6
	TST.l	obj_tile_index(A6)
	BEQ.b	LoadEncounterTypeGraphics_Loop
	MOVEA.l	obj_tile_index(A6), A4
	MOVEA.l	obj_screen_y(A6), A3
	MOVE.w	#$000F, D5
	BSR.w	LoadMultipleTilesFromTable
LoadEncounterTypeGraphics_Loop:
	RTS
	
LoadTalkerGraphics:
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	MOVEA.l	obj_active(A6), A4
	MOVEA.l	$4(A6), A3
	MOVE.w	obj_tile_index(A6), D5
	BSR.w	LoadMultipleTilesFromTable
	LEA	Enemy_gfx_buffer.w, A2
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	TST.l	obj_screen_x(A6)
	BEQ.b	LoadTalkerGraphics_Loop
	MOVEA.l	obj_screen_x(A6), A4
	MOVEA.l	obj_world_x(A6), A3
	MOVE.w	obj_world_y(A6), D5
	BSR.w	LoadMultipleTilesFromTable
LoadTalkerGraphics_Loop:
	RTS
	
LoadFirstPersonGraphics:
	LEA	GfxLoadList_FirstPerson-2, A6
	BSR.w	ProcessGraphicsLoadList
	DMAFillVRAM_bsr $40000000, $01FF
	RTS
	
LoadFirstPersonBattleGraphics:
	LEA	GfxLoadList_FirstPersonBattle, A6
	BSR.w	ProcessGraphicsLoadList
	RTS
	
LoadIntroSegalogGraphics:
	LEA	GfxLoadList_IntroSegalogo, A6
	BRA.w	ProcessGraphicsLoadList
LoadIntroTitleGraphics:
	LEA	GfxLoadList_IntroTitle, A6
	BRA.w	ProcessGraphicsLoadList
LoadTownGraphics:
	LEA	GfxLoadList_Town, A6
	BRA.w	ProcessGraphicsLoadList
LoadTownBattleGraphics:
	LEA	GfxLoadList_TownBattle, A6
	BRA.w	ProcessGraphicsLoadList
LoadWorldBattleGraphics:
	LEA	GfxLoadList_WorldBattle, A6
	BRA.w	ProcessGraphicsLoadList
LoadPlayerOverworldGraphics:
	LEA	LoadPlayerOverworldGraphics_Data2, A3
	LEA	Player_overworld_gfx_buffer, A2
	LEA	LoadPlayerOverworldGraphics_Data, A4
	MOVE.w	#$006B, D5
	BSR.w	LoadMultipleTilesFromTable
	RTS
	
LoadBattleTilesToBuffers:
	LEA	Tilemap_buffer_plane_a, A2
	LEA	LoadBattleTilesToBuffers_Data3, A4
	LEA	LoadBattleTilesToBuffers_Data4, A3
	MOVE.w	#$00A7, D5
	BSR.w	LoadMultipleTilesFromTable
	LEA	Battle_gfx_slot_1_buffer, A2
	LEA	LoadBattleTilesToBuffers_Data5, A4
	LEA	LoadBattleTilesToBuffers_Data6, A3
	MOVE.w	#$0167, D5
	BSR.w	LoadMultipleTilesFromTable
	LEA	Battle_gfx_slot_2_buffer, A2
	LEA	LoadBattleTilesToBuffers_Data, A4
	LEA	LoadBattleTilesToBuffers_Data2, A3
	MOVE.w	#$0077, D5
	BSR.w	LoadMultipleTilesFromTable
	RTS
	
LoadBossGraphics:
	LEA	Tilemap_buffer_plane_a, A2
	LEA	LoadBossGraphics_Data, A4
	LEA	LoadBossGraphics_Data2, A3
	MOVE.w	#$00BF, D5
	BSR.w	LoadMultipleTilesFromTable
	LEA	Boss_gfx_slot_1_buffer, A2
	LEA	LoadBossGraphics_Data3, A4
	LEA	LoadBossGraphics_Data4, A3
	MOVE.w	#$00EF, D5
	BSR.w	LoadMultipleTilesFromTable
	LEA	Boss_gfx_extra_buffer, A2
	LEA	LoadBossGraphics_Data5, A4
	LEA	LoadBossGraphics_Data6, A3
	MOVE.w	#$001F, D5
	BSR.w	LoadMultipleTilesFromTable
	LEA	Boss_gfx_slot_2_buffer, A2
	LEA	LoadBossGraphics_Data7, A4
	LEA	LoadBossGraphics_Data8, A3
	MOVE.w	#$001B, D5
	BSR.w	LoadMultipleTilesFromTable
	RTS
	
ProcessGraphicsLoadList:
	MOVE.w	(A6)+, D0
	BLT.b	ProcessGraphicsLoadList_Loop
	MOVE.w	D0, Vdp_dma_slot_index.w
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A6)+, A4
	MOVEA.l	(A6)+, A3
	MOVE.w	(A6)+, D5
	BSR.w	LoadMultipleTilesFromTable
	BSR.w	ExecuteVdpDmaTransfer
	BRA.b	ProcessGraphicsLoadList
ProcessGraphicsLoadList_Loop:
	RTS
	
; LoadMultipleTilesFromTable
; Load and decompress multiple tiles from indexed table
; Input: A4 = Index list, A3 = Tile pointer table, A2 = Destination, D5 = Count
LoadMultipleTilesFromTable:
	CLR.w	D0
	MOVE.b	(A4)+, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A3,D0.w), A0
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadMultipleTilesFromTable
	RTS
	
ExecuteVdpDmaTransfer:
	ORI	#$0700, SR
	stopZ80
	BSR.w	InitVdpDmaRamRoutine
	MOVE.w	#2, D4
	ORI.w	#$8F00, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4
	MOVE.w	D4, VDP_control_port
	LEA	BattleSpriteDMACommands, A0
	MOVE.w	Vdp_dma_slot_index.w, D0
	ASL.w	#4, D0
	LEA	(A0,D0.w), A0
	MOVE.l	(A0)+, VDP_control_port
	MOVE.l	(A0)+, VDP_control_port
	MOVE.w	(A0)+, VDP_control_port
	MOVE.l	(A0)+, Vdp_dma_cmd.w
	JSR	Vdp_dma_ram_routine.w
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	#0, Z80_bus_request
	ANDI	#$F8FF, SR
	RTS

GetRandomNumber:
	MOVEM.l	D1, -(A7)
	MOVE.l	Rng_state.w, D1
	BNE.w	GetRandomNumber_Loop
	MOVE.l	#$2A6D365A, D1
GetRandomNumber_Loop:
	MOVE.l	D1, D0
	ASL.l	#2, D1
	ADD.l	D0, D1
	ASL.l	#3, D1
	ADD.l	D0, D1
	MOVE.w	D1, D0
	SWAP	D1
	ADD.w	D1, D0
	MOVE.w	D0, D1
	SWAP	D1
	MOVE.l	D1, Rng_state.w
	MOVEM.l	(A7)+, D1
	RTS

RemoveItemFromArray:
	MOVE.w	D0, D1
	ADD.w	D0, D0
	LEA	(A0,D0.w), A0
	SUB.w	D1, D2
	BEQ.b	RemoveItemFromArray_Loop
	SUBQ.w	#1, D2
RemoveItemFromArray_Done:
	MOVE.w	$2(A0), (A0)+
	DBF	D2, RemoveItemFromArray_Done
RemoveItemFromArray_Loop:
	RTS
	
; DecompressTileGraphics
; Decompress tile graphics data
; Input: A0 = Source compressed data, A2 = Destination buffer
; Uses bitfield (D3) to track which pixels are already set
DecompressTileGraphics:
	CLR.l	D3
DecompressTileGraphics_ReadByte:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	BEQ.w	DecompressTileGraphics_Loop
	SUBQ.w	#1, D0
DecompressTileGraphics_Done:
	CLR.w	D2
DecompressTileGraphics_ReadMask:
	MOVE.b	(A0)+, D2
	MOVE.b	(A0)+, D1
	ASL.l	#8, D1
	MOVE.b	(A0)+, D1
	ASL.l	#8, D1
	MOVE.b	(A0)+, D1
	ASL.l	#8, D1
	MOVE.b	(A0)+, D1
	OR.l	D1, D3
	BSR.w	WriteMaskedTileRow
	DBF	D0, DecompressTileGraphics_Done
	LEA	(A2), A1
	MOVEQ	#$00000020, D0
	MOVE.l	D3, D1
DecompressTileGraphics_Done2:
	CMPI.l	#$FFFFFFFF, D3
DecompressTileGraphics_CheckFull:
	BEQ.b	DecompressTileGraphics_Loop2
DecompressTileGraphics_Done3:
	ROL.l	#1, D1
DecompressTileGraphics_PixelLoop:
	SUBQ.w	#1, D0
	BTST.l	#0, D1
	BNE.b	DecompressTileGraphics_Loop3
	MOVE.b	(A0)+, (A1)+
	BSET.l	D0, D3
	BRA.b	DecompressTileGraphics_Done2
DecompressTileGraphics_Loop3:
	LEA	$1(A1), A1
DecompressTileGraphics_PixelSkip:
	BRA.b	DecompressTileGraphics_Done3
DecompressTileGraphics_Loop2:
	RTS
	
DecompressTileGraphics_Loop:
	LEA	(A2), A1
DecompressTileGraphics_UnmaskedEntry:
	MOVEQ	#7, D0
DecompressTileGraphics_Loop_Done:
	MOVE.b	(A0)+, (A1)+
DecompressTileGraphics_UnmaskedPixels:
	MOVE.b	(A0)+, (A1)+
	MOVE.b	(A0)+, (A1)+
	MOVE.b	(A0)+, (A1)+
	DBF	D0, DecompressTileGraphics_Loop_Done
	RTS
	
WriteMaskedTileRow:
	LEA	(A2), A1
WriteMaskedTileRow_PixelLoop:
	MOVEQ	#$0000001F, D4
WriteMaskedTileRow_Done:
	ROL.l	#1, D1
WriteMaskedTileRow_TestPixel:
	BTST.l	#0, D1
	BEQ.b	WriteMaskedTileRow_Loop
	MOVE.b	D2, (A1)
WriteMaskedTileRow_Loop:
	LEA	$1(A1), A1
WriteMaskedTileRow_NextPixel:
	DBF	D4, WriteMaskedTileRow_Done
	RTS
	
DecompressFontTile:
	CLR.l	D3
	CLR.w	D0
	MOVE.b	(A0)+, D0
	BEQ.w	DecompressFontTile_Loop
	SUBQ.w	#1, D0
DecompressFontTile_Done:
	CLR.w	D2
	MOVE.b	(A0)+, D2
	MOVE.b	(A0)+, D1
	ASL.l	#8, D1
	MOVE.b	(A0)+, D1
	ASL.l	#8, D1
	MOVE.b	(A0)+, D1
	ASL.l	#8, D1
	MOVE.b	(A0)+, D1
	OR.l	D1, D3
	MOVE.b	D2, D6
	BSR.w	ClampTileCoordinates
	MOVE.b	D6, D2
	BSR.w	WriteTileRowFromBitfield
	DBF	D0, DecompressFontTile_Done
	LEA	(A2), A1
	MOVEQ	#$00000020, D0
	MOVE.l	D3, D1
DecompressFontTile_Done2:
	CMPI.l	#$FFFFFFFF, D3
	BEQ.b	DecompressFontTile_Loop2
DecompressFontTile_Done3:
	ROL.l	#1, D1
	SUBQ.w	#1, D0
	BTST.l	#0, D1
	BNE.b	DecompressFontTile_Loop3
	MOVE.b	(A0)+, D6
	BSR.w	ClampTileCoordinates
	MOVE.b	D6, (A1)+
	BSET.l	D0, D3
	BRA.b	DecompressFontTile_Done2
DecompressFontTile_Loop3:
	LEA	$1(A1), A1
	BRA.b	DecompressFontTile_Done3
DecompressFontTile_Loop2:
	RTS
	
DecompressFontTile_Loop:
	LEA	(A2), A1
	MOVEQ	#7, D0
DecompressFontTile_Loop_Done:
	MOVE.b	(A0)+, D6
	BSR.w	ClampTileCoordinates
	MOVE.b	D6, (A1)+
	MOVE.b	(A0)+, D6
	BSR.w	ClampTileCoordinates
	MOVE.b	D6, (A1)+
	MOVE.b	(A0)+, D6
	BSR.w	ClampTileCoordinates
	MOVE.b	D6, (A1)+
	MOVE.b	(A0)+, D6
	BSR.w	ClampTileCoordinates
	MOVE.b	D6, (A1)+
	DBF	D0, DecompressFontTile_Loop_Done
	RTS
	
WriteTileRowFromBitfield:
	LEA	(A2), A1
	MOVEQ	#$0000001F, D4
WriteTileRowFromBitfield_Done:
	ROL.l	#1, D1
	BTST.l	#0, D1
	BEQ.b	WriteTileRowFromBitfield_Loop
	MOVE.b	D2, (A1)
WriteTileRowFromBitfield_Loop:
	LEA	$1(A1), A1
	DBF	D4, WriteTileRowFromBitfield_Done
	RTS
	
ClampTileCoordinates:
	MOVE.b	D6, D7
	ANDI.w	#$00F0, D7
	CMPI.w	#$0030, D7
	BNE.b	ClampTileCoordinates_Loop
	ANDI.b	#$0F, D6
ClampTileCoordinates_Loop:
	MOVE.b	D6, D7
	ANDI.w	#$000F, D7
	CMPI.w	#3, D7
	BNE.b	ClampTileCoordinates_Loop2
	ANDI.b	#$F0, D6
ClampTileCoordinates_Loop2:
	RTS

LoadAndDecompressTileGfx:
	LEA	Tile_gfx_buffer.w, A2
	LEA	CompressedFontTileData, A0
	MOVE.w	#$00FF, D5
ClampTileCoordinates_Loop2_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, ClampTileCoordinates_Loop2_Done
	BSR.w	TransferTilesViaDma
	RTS

InitFontTiles:
	LEA	Tile_gfx_buffer.w, A2
	LEA	CompressedFontTileData, A0
	MOVE.w	#$00FF, D5
InitFontTiles_Done:
	BSR.w	DecompressFontTile
	LEA	$20(A2), A2
	DBF	D5, InitFontTiles_Done
	BSR.w	TransferTilesViaDma
	RTS

TransferTilesViaDma:
	stopZ80
	JSR	InitVdpDmaRamRoutine
	MOVE.w	#2, D4
	ORI.w	#$8F00, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.l	#$94109300, VDP_control_port
	MOVE.l	#$96D09500, VDP_control_port
	MOVE.w	#$977F, VDP_control_port
	MOVE.l	#$58000082, Vdp_dma_cmd.w
	JSR	Vdp_dma_ram_routine.w
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	#0, Z80_bus_request
	RTS

LoadTownTileGraphics:
	LEA	Tile_gfx_buffer.w, A2
	TST.b	Swaffham_ruined.w
	BEQ.b	LoadTownTileGfx_LookupTable
	CMPI.w	#TOWN_SWAFFHAM, Current_town.w
	BNE.b	LoadTownTileGfx_LookupTable
	MOVEA.l	LoadTownTileGraphics_Data, A0
	BRA.b	LoadTownTileGfx_LookupTable_Loop
LoadTownTileGfx_LookupTable:
	LEA	TownTileGfxTable, A1
	MOVE.w	Current_town.w, D0 
	MOVE.w	D0, D1  
	ADD.w	D1, D1  
	ASL.w	#3, D0 
	ADD.w	D1, D0
	MOVEA.l	(A1,D0.w), A0 ; Multiply current town by 10
LoadTownTileGfx_LookupTable_Loop:
	MOVE.w	#$00FF, D5
LoadTownTileGfx_LookupTable_Loop_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTownTileGfx_LookupTable_Loop_Done
	LEA	DmaCmd_TownTileset_Wyclif, A0
	BSR.w	ExecuteVdpDmaFromPointer
	LEA	Tile_gfx_buffer.w, A2
	TST.b	Swaffham_ruined.w
	BEQ.b	LoadTownObjectGfx_LookupTable
	CMPI.w	#TOWN_SWAFFHAM, Current_town.w
	BNE.b	LoadTownObjectGfx_LookupTable
	MOVEA.l	LoadTownTileGfx_LookupTable_Loop_Done_Data, A0
	MOVE.w	LoadTownTileGfx_LookupTable_Loop_Done_Data2, D5
	BRA.b	LoadTownObjectGfx_DecompressLoop
LoadTownObjectGfx_LookupTable:
	LEA	TownTileGfxTable, A1
	MOVE.w	Current_town.w, D0
	MOVE.w	D0, D1
	ADD.w	D1, D1
	ASL.w	#3, D0
	ADD.w	D1, D0
	MOVEA.l	$4(A1,D0.w), A0
	MOVE.w	$8(A1,D0.w), D5
LoadTownObjectGfx_DecompressLoop:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTownObjectGfx_DecompressLoop
	LEA	DmaCmd_TownTileset_Parma, A0
	BSR.w	ExecuteVdpDmaFromPointer
	RTS
	
LoadBattleHudGraphics:
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadBattleHudGraphics_Data, A0
	MOVE.w	#$00FF, D5
LoadBattleHudGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattleHudGraphics_Done
	LEA	DmaCmd_TownTileset_Wyclif, A0
	BSR.w	ExecuteVdpDmaFromPointer
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadBattleHudGraphics_Done_Data, A0
	MOVE.w	#$0039, D5
LoadBattleHudGraphics_Done2:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattleHudGraphics_Done2
	LEA	DmaCmd_TownTileset_Parma, A0
	BSR.w	ExecuteVdpDmaFromPointer
	RTS
	
ExecuteVdpDmaFromPointer:
	ORI	#$0700, SR
	stopZ80
	BSR.w	InitVdpDmaRamRoutine
	MOVE.w	#2, D4
	ORI.w	#$8F00, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.l	(A0)+, VDP_control_port
	MOVE.l	(A0)+, VDP_control_port
	MOVE.w	(A0)+, VDP_control_port
	MOVE.l	(A0)+, Vdp_dma_cmd.w
	JSR	Vdp_dma_ram_routine.w
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	#0, Z80_bus_request
	ANDI	#$F8FF, SR
	RTS
	
ExecuteVdpDmaFromPointer_Setup:
	LEA	ExecuteVdpDmaFromPointer_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$0039, D5
ExecuteVdpDmaFromPointer_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, ExecuteVdpDmaFromPointer_Done
	LEA	DmaCmd_OverworldStatusTiles, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
LoadBattleTerrainGraphics:
	TST.b	Is_boss_battle.w
	BEQ.b	LoadBattleTerrainGraphics_Loop
	MOVE.w	#TERRAIN_TILESET_BOSS, Terrain_tileset_index.w
	BRA.b	LoadBattleTerrainGraphics_LoadTiles
LoadBattleTerrainGraphics_Loop:
	TST.b	Is_in_cave.w
	BEQ.b	LoadBattleTerrainGraphics_Loop2
	MOVE.w	#TERRAIN_TILESET_CAVE, Terrain_tileset_index.w
	BRA.b	LoadBattleTerrainGraphics_LoadTiles
LoadBattleTerrainGraphics_Loop2:
	TST.b	Soldier_fight_event_trigger.w
	BEQ.b	LoadBattleTerrainGraphics_Loop3
	MOVE.w	#TERRAIN_TILESET_SOLDIER, Terrain_tileset_index.w
	BRA.b	LoadBattleTerrainGraphics_LoadTiles
LoadBattleTerrainGraphics_Loop3:
	BSR.w	DetermineTerrainTileset
LoadBattleTerrainGraphics_LoadTiles:
	MOVE.w	Terrain_tileset_index.w, D0
	LEA	TerrainTilemapMetadata, A1
	ASL.w	#3, D0
	LEA	(A1,D0.w), A1
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A1)+, A0
	MOVE.w	(A1)+, D5
	MOVE.w	(A1)+, Palette_line_2_index.w
	BSR.w	DecompressTileLoop
	LEA	TerrainTileGfxDmaPtrs, A1
	MOVE.w	Terrain_tileset_index.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A1,D0.w), A0
	BSR.w	ExecuteVdpDmaFromRam
	JSR	LoadPalettesFromTable
	RTS
	
DecompressTileLoop:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, DecompressTileLoop
	RTS
	
LoadBattleTileGraphics:
	LEA	LoadBattleTileGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$001A, D5
LoadBattleTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattleTileGraphics_Done
	LEA	DmaCmd_BattleTiles, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
LoadBattleUiTileGraphics:
	LEA	LoadBattleUiTileGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$003C, D5
LoadBattleUiTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattleUiTileGraphics_Done
	LEA	DmaCmd_BattleUiTiles, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
LoadWorldMapTileGraphics:
	LEA	LoadWorldMapTileGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$00EA, D5
LoadWorldMapTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadWorldMapTileGraphics_Done
ExecuteWorldMapDma:
	LEA	DmaCmd_WorldMapTiles, A0
	BSR.w	ExecuteVdpDmaFromRam
; NullSpriteRoutine
; Used as NullSpriteRoutine-2 in enemy data tables (points to BSR instruction)
NullSpriteRoutine:
	RTS
	
LoadCaveTileGraphics:
	LEA	LoadCaveTileGraphics_Data, A0
LoadCaveTileGfxToBuffer:
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$0075, D5
LoadCaveTileGfxToBuffer_Done:
	BSR.w	DecompressTileGraphics
LoadCaveTileGfxToBuffer_NextTile:
	LEA	$20(A2), A2
LoadCaveTileGfxToBuffer_Loop:
	DBF	D5, LoadCaveTileGfxToBuffer_Done
LoadCaveTileGfxToBuffer_DmaTransfer:
	LEA	DmaCmd_CaveTiles, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
LoadBattleGroundTileGraphics:
	LEA	LoadBattleGroundTileGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$0064, D5
LoadBattleGroundTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattleGroundTileGraphics_Done
	LEA	DmaCmd_BattleGroundGfx, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
LoadBattleEnemyTileGraphics:
	LEA	SpriteGfxData_8287C, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$0056, D5
LoadBattleEnemyTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattleEnemyTileGraphics_Done
	LEA	DmaCmd_BattleEnemyGfx, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
LoadBattleStatusTileGraphics:
	LEA	LoadBattleStatusTileGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$0058, D5
LoadBattleStatusTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattleStatusTileGraphics_Done
	LEA	DmaCmd_BattleStatusGfx, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
LoadCaveEnemyTileGraphics:
	LEA	SpriteGfxData_8287C, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$0056, D5
LoadCaveEnemyTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadCaveEnemyTileGraphics_Done
	LEA	DmaCmd_CaveEnemyGfx, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
LoadCaveItemTileGraphics:
	LEA	LoadCaveItemTileGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$005D, D5
LoadCaveItemTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadCaveItemTileGraphics_Done
	LEA	DmaCmd_CaveItemGfx, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
LoadBattlePlayerTileGraphics:
	LEA	LoadBattlePlayerTileGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$004F, D5
LoadBattlePlayerTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattlePlayerTileGraphics_Done
	LEA	DmaCmd_BattlePlayerGfx, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
LoadTownTileGfxSet1:
	LEA	LoadTownTileGfxSet1_Data, A0
LoadTownTileGfxToBuffer:
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$00B6, D5
LoadTownTileGfxToBuffer_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTownTileGfxToBuffer_Done
	LEA	DmaCmd_TownTileGfxSet1_A, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadTownTileGfxToBuffer_Done_Data, A0
	MOVE.w	#$00D9, D5
LoadTownTileGfxToBuffer_Done2:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTownTileGfxToBuffer_Done2
	LEA	DmaCmd_TownTileGfxSet1_B, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	Tile_gfx_buffer.w, A2
	LEA	SpriteGfxData_607AA, A0
	MOVE.w	#$006B, D5
LoadTownTileGfxToBuffer_Done3:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTownTileGfxToBuffer_Done3
	LEA	DmaCmd_TownNpcGfx, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadTownTileGfxToBuffer_Done3_Data, A0
	MOVE.w	#$009D, D5
LoadTownTileGfxToBuffer_Done4:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTownTileGfxToBuffer_Done4
	LEA	DmaCmd_TownTileGfxSet1_D, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadTownTileGfxToBuffer_Done4_Data, A0
	MOVE.w	#$0029, D5
LoadTownTileGfxToBuffer_Done5:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTownTileGfxToBuffer_Done5
	LEA	DmaCmd_TownTileGfxSet1_E, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
LoadMenuTileGraphics:
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadMenuTileGraphics_Data, A0
	MOVE.w	#$00FF, D5
LoadMenuTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadMenuTileGraphics_Done
	LEA	DmaCmd_MenuTilesA, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadMenuTileGraphics_Done_Data, A0
	MOVE.w	#$00FF, D5
LoadMenuTileGraphics_Done2:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadMenuTileGraphics_Done2
	LEA	DmaCmd_MenuTilesB, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	Tile_gfx_buffer.w, A2
LoadMenuTileGfxSet2:
	LEA	SpriteGfxData_607AA, A0
LoadMenuTileGfxSet3:
	MOVE.w	#$006B, D5
LoadMenuTileGfxSet3_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadMenuTileGfxSet3_Done
	LEA	DmaCmd_TownNpcGfx, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadMenuTileGfxSet3_Done_Data, A0
	MOVE.w	#$001A, D5
LoadMenuTileGfxSet3_Done2:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadMenuTileGfxSet3_Done2
	LEA	DmaCmd_MenuMiscTilesA, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadMenuTileGfxSet3_Done2_Data, A0
	MOVE.w	#7, D5
LoadMenuTileGfxSet3_Done3:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadMenuTileGfxSet3_Done3
	LEA	DmaCmd_MenuMiscTilesB, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
LoadTitleScreenGraphics:
	LEA	LoadTitleScreenGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$004D, D5
LoadTitleScreenGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTitleScreenGraphics_Done
	LEA	DmaCmd_TitleScreenTilesA, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	LoadTitleScreenGraphics_Done_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$006C, D5
LoadTitleScreenGraphics_Done2:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTitleScreenGraphics_Done2
	LEA	DmaCmd_TitleScreenTilesB, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	LoadTitleScreenGraphics_Done2_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$0062, D5
LoadTitleScreenGraphics_Done3:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTitleScreenGraphics_Done3
	LEA	DmaCmd_TitleScreenTilesC, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	LoadTitleScreenGraphics_Done3_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$004F, D5
LoadTitleScreenGraphics_Done4:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTitleScreenGraphics_Done4
	LEA	DmaCmd_TitleScreenTilesD, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	LoadTitleScreenGraphics_Done4_Data, A0
LoadTitleScreenTileGfx:
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$0051, D5
LoadTitleScreenTileGfx_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTitleScreenTileGfx_Done
	LEA	DmaCmd_TitleScreenTilesE, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	LoadTitleScreenTileGfx_Done_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#5, D5
LoadTitleScreenTileGfx_Done2:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTitleScreenTileGfx_Done2
	LEA	DmaCmd_TitleScreenTilesF, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
LoadOptionsMenuGraphics:
	LEA	LoadOptionsMenuGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$003C, D5
LoadOptionsMenuGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadOptionsMenuGraphics_Done
	LEA	DmaCmd_OptionsMenuTiles, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
; ExecuteVdpDmaFromRam
; Execute VDP DMA transfer from RAM to VRAM
; Input: A0 = Pointer to DMA command data (destination, length, source)
ExecuteVdpDmaFromRam:
	ORI	#$0700, SR
ExecuteVdpDmaFromRam_DmaStart:
	stopZ80
	BSR.w	InitVdpDmaRamRoutine
	MOVE.w	#2, D4
	ORI.w	#$8F00, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.l	(A0)+, VDP_control_port
	MOVE.l	(A0)+, VDP_control_port
	MOVE.w	(A0)+, VDP_control_port
	MOVE.l	(A0)+, Vdp_dma_cmd.w
	JSR	Vdp_dma_ram_routine.w
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	#0, Z80_bus_request
	ANDI	#$F8FF, SR
	RTS
	
InitVdpDmaRamRoutine:
	LEA	VdpDmaRoutineTemplate, A2
InitVdpDmaRamRoutine_CopyLoop:
	LEA	Vdp_dma_ram_routine.w, A3
	MOVE.l	(A2)+, (A3)+
	MOVE.l	(A2)+, (A3)+
	MOVE.l	(A2)+, (A3)+
	MOVE.l	(A2)+, (A3)+
	MOVE.w	(A2)+, (A3)+
	RTS
	
VdpDmaRoutineTemplate:
	dc.l	$33F8C18C
	dc.l	$00C00004
	dc.l	$33F8C18E
	dc.l	$00C00004
	dc.w	$4E75 
VDP_DMAFill:
	ORI	#$0700, SR
	ORI.w	#$8F00, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.l	#$00940000, D4
	MOVE.w	D6, D4
	LSL.l	#8, D4
	MOVE.w	#$9300, D4
	MOVE.b	D6, D4
	MOVE.l	D4, VDP_control_port
	MOVE.w	#$9780, VDP_control_port
	ORI.l	#$40000080, D7
	MOVE.l	D7, Vdp_dma_cmd.w
	MOVE.w	Vdp_dma_cmd.w, VDP_control_port
	MOVE.w	Vdp_dma_cmd_hi.w, VDP_control_port
	MOVE.b	D5, VDP_data_port
VDP_DMAFill_Done:
	MOVE.w	VDP_control_port, D4
	BTST.l	#1, D4
	BNE.b	VDP_DMAFill_Done
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	#$8F02, VDP_control_port
	ANDI	#$F8FF, SR
	RTS
	
Z80SoundDriver_Data_10480:
	dc.b	$76, $00, $02, $80, $00, $00, $00, $FF, $60, $00, $00, $1A 
; ConvertToBCD
; Convert binary number to BCD (Binary Coded Decimal) format
; Input: D0 = Binary number (0-99999)
; Output: D0 = BCD representation (each nibble is a decimal digit)
; Example: 12345 ($3039) -> $00012345 BCD
ConvertToBCD:
	MOVEQ	#0, D3
	ANDI.l	#$0000FFFF, D0
	MOVE.w	#$2710, D1		; 10000
	BSR.w	ExtractBCDDigit
	MOVE.w	#$03E8, D1		; 1000
	BSR.w	ExtractBCDDigit
	MOVE.w	#$0064, D1		; 100
	BSR.w	ExtractBCDDigit
	MOVE.w	#$000A, D1		; 10
	BSR.w	ExtractBCDDigit
	OR.b	D0, D3			; Ones digit
	MOVE.l	D3, D0
	RTS
	
; ExtractBCDDigit
; Extract one BCD digit by division
; Input: D0 = Number, D1 = Divisor, D3 = Accumulated BCD
; Output: D0 = Remainder, D3 = BCD with new digit added
ExtractBCDDigit:
	DIVU.w	D1, D0
	OR.b	D0, D3
	LSL.l	#4, D3
	ANDI.l	#Tilemap_buffer_plane_a, D0
	SWAP	D0
	RTS
	
DetermineTerrainTileset:
	CLR.w	Terrain_tileset_index.w
	LEA	Map_sector_center.w, A0
	MOVE.w	Player_position_x_outside_town.w, D0
	MOVE.w	Player_position_y_outside_town.w, D1
	SUBQ.w	#1, D0
	SUBQ.w	#1, D1
	MULU.w	#$0030, D1
	ADD.w	D0, D1
	LEA	(A0,D1.w), A2
	CLR.w	D1
	CLR.w	D2
	MOVEQ	#2, D7
DetermineTerrainTileset_Done:
	MOVEQ	#2, D6
DetermineTerrainTileset_Done2:
	MOVE.b	(A2)+, D0
	BSR.w	CountTerrainTileType
	DBF	D6, DetermineTerrainTileset_Done2
	LEA	$2D(A2), A2
	DBF	D7, DetermineTerrainTileset_Done
	CMP.w	D2, D1
	BGE.b	DetermineTerrainTileset_Loop
	MOVE.w	#TERRAIN_TILESET_FIELD, Terrain_tileset_index.w
DetermineTerrainTileset_Loop:
	RTS
	
CountTerrainTileType:
	CMPI.b	#1, D0
	BNE.b	CountTerrainTileType_Loop
	ADDQ.w	#1, D1
	BRA.b	CountDialogBytes_Return
CountTerrainTileType_Loop:
	CMPI.b	#2, D0
	BNE.b	CountDialogBytes_Return
	ADDQ.w	#1, D2
CountDialogBytes_Return:
	RTS
	
; QueueSoundEffect
; Queue a sound effect for playback
; Input: D0.b = Sound effect ID
; Adds sound to queue if not full (max 8 entries)
QueueSoundEffect:
	MOVE.w	Sound_queue_count.w, D1
	CMPI.w	#8, D1
	BGE.b	QueueSoundEffect_Loop
	LEA	Sound_queue_buffer.w, A0
	MOVE.b	D0, (A0,D1.w)
	ADDQ.w	#1, Sound_queue_count.w
QueueSoundEffect_Loop:
	RTS
	
LoadBattleTilesToVram:
	LEA	BattleTileDataPtrs, A6
	MOVE.w	Battle_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A6,D0.w), A6
LoadBattleTilesToVram_Done:
	MOVE.w	(A6)+, D0
	BLT.b	LoadBattleTilesToVram_Loop
	MOVE.w	D0, Vdp_dma_slot_index.w
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A6)+, A4
	MOVEA.l	(A6)+, A3
	MOVE.w	(A6)+, D5
	BSR.w	LoadMultipleTilesFromTable
	BSR.w	ExecuteVdpDmaTransfer
	BRA.b	LoadBattleTilesToVram_Done
LoadBattleTilesToVram_Loop:
	RTS
	
LoadBattleGraphics:
	LEA	BattleGfxDataPtrs, A6
	MOVE.w	Battle_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A6,D0.w), A6
	TST.l	(A6)
	BEQ.b	LoadBattleGraphics_Loop
	MOVEA.l	(A6)+, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	(A6)+, D5
LoadBattleGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattleGraphics_Done
	MOVEA.l	(A6), A0
	BSR.w	ExecuteVdpDmaFromRam
LoadBattleGraphics_Loop:
	RTS
	
