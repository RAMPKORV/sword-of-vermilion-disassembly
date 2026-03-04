; ======================================================================
; src/cutscene.asm
; Prologue scenes, title screen, town camera/tilemap, ending credits
; ======================================================================

; ======================================================================
; Prologue Scene Drawing
; ======================================================================
; Each DrawPrologueScene* function draws one full "page" of the story
; intro by writing tilemap blocks and text strings to the VDP.
; D5 = VDP control word (destination VRAM address + write command),
; D4 = tile attribute base (palette/priority flags ORed into tile IDs),
; A0 = pointer to source data or text string.
; ======================================================================

DrawPrologueScene3:
	ORI	#$0700, SR
	MOVE.l	#$63B00003, D5
	MOVE.w	#$A300, D4
	BSR.w	DrawTilemapBlock_15x12
	MOVE.l	#$64320003, D5
	LEA	DrawPrologueScene3_Data, A0
	MOVE.w	#$C180, D4
	BSR.w	DrawTilemapBlock_13x10
	MOVE.l	#$61820003, D5
	LEA	Prologue3Str, A0
	MOVE.w	#$84C0, D4
	BSR.w	DrawVerticalText
	ANDI	#$F8FF, SR
	RTS

; ----------------------------------------------------------------------
; DrawPrologueScene4and5 — prologue pages 4 and 5 (two panels)
; Draws two background blocks and two text columns in one call.
; ----------------------------------------------------------------------
DrawPrologueScene4and5:
	ORI	#$0700, SR
	MOVE.l	#$60840003, D5
	MOVE.w	#$A300, D4
	BSR.w	DrawTilemapBlock_15x12
	MOVE.l	#$61060003, D5
	LEA	DrawPrologueScene4and5_Data, A0
	MOVE.w	#$A200, D4
	BSR.w	DrawTilemapBlock_13x10
	MOVE.l	#$61A40003, D5
	LEA	Prologue4Str, A0
	MOVE.w	#$84C0, D4
	BSR.w	DrawVerticalText
	MOVE.l	#$67B00003, D5
	MOVE.w	#$E300, D4
	BSR.w	DrawTilemapBlock_15x12
	MOVE.l	#$68320003, D5
	LEA	DrawPrologueScene4and5_Data2, A0
	MOVE.w	#$E280, D4
	BSR.w	DrawTilemapBlock_13x10
	MOVE.l	#$68840003, D5
	LEA	Prologue5Str, A0
	MOVE.w	#$C4C0, D4
	BSR.w	DrawVerticalText
	ANDI	#$F8FF, SR
	RTS

; ----------------------------------------------------------------------
; DrawPrologueScene6 — prologue page 6 (text only, no background block)
; ----------------------------------------------------------------------
DrawPrologueScene6:
	ORI	#$0700, SR
	MOVE.l	#$648E0003, D5
	LEA	Prologue6Str, A0
	MOVE.w	#$84C0, D4
	BSR.w	DrawVerticalText
	ANDI	#$F8FF, SR
	RTS

; ======================================================================
; Tilemap Block Drawing Helpers
; ======================================================================

; ----------------------------------------------------------------------
; DrawTilemapBlock_15x12 — write a 15-column × 12-row tile block to VDP.
; D5 = initial VDP write-address command, D4 = tile attribute base.
; Source data is fixed at DrawTilemapBlock_15x12_Data (byte per tile).
; Advances VDP address by one row ($00800000) after each row.
; ----------------------------------------------------------------------
DrawTilemapBlock_15x12:
	LEA	DrawTilemapBlock_15x12_Data, A0
	MOVE.w	#$000B, D7
DrawTilemapBlock_15x12_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$000E, D6              ; 15 tiles per row (DBF loops 14+1)
DrawTilemapBlock_15x12_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADD.w	D4, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawTilemapBlock_15x12_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, DrawTilemapBlock_15x12_Done
	RTS

; ----------------------------------------------------------------------
; DrawTilemapBlock_13x10 — write a 13-column × 10-row tile block to VDP.
; Same register convention as DrawTilemapBlock_15x12.
; A0 = pointer to source tile index data (byte per tile, added to D4).
; ----------------------------------------------------------------------
DrawTilemapBlock_13x10:
	MOVE.w	#9, D7
DrawTilemapBlock_13x10_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$000C, D6              ; 13 tiles per row (DBF loops 12+1)
DrawTilemapBlock_13x10_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADD.w	D4, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawTilemapBlock_13x10_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, DrawTilemapBlock_13x10_Done
	RTS
	
; ----------------------------------------------------------------------
; DrawVerticalText — render a null-terminated text string into a vertical
; VDP tilemap column, handling wide characters and column advances.
; D5 = initial VDP write-address, D4 = tile attribute base,
; A0 = pointer to string.
; $FE (SCRIPT_NEWLINE) advances to the next text column ($10 tiles right).
; $FF (SCRIPT_END) terminates.
; $DE/$DF (SCRIPT_WIDE_CHAR_LO/HI) write the tile then step one column.
; ----------------------------------------------------------------------
DrawVerticalText:
	MOVE.l	D5, VDP_control_port
	MOVE.l	D5, D3
DrawVerticalText_Next:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	CMPI.b	#SCRIPT_NEWLINE, D0
	BEQ.w	DrawVerticalText_NewLine_Loop
	CMPI.b	#SCRIPT_END, D0
	BEQ.w	DrawVerticalText_NewLine_Loop2
	CMPI.b	#SCRIPT_WIDE_CHAR_LO, D0
	BEQ.b	DrawVerticalText_NewLine
	CMPI.b	#SCRIPT_WIDE_CHAR_HI, D0
	BEQ.b	DrawVerticalText_NewLine
	ADD.w	D4, D0
	MOVE.w	D0, VDP_data_port
	ADDI.l	#$00020000, D3
	BRA.b	DrawVerticalText_Next
DrawVerticalText_NewLine:
	SUBI.l	#$00820000, D3          ; back up one row in VRAM address
	MOVE.l	D3, VDP_control_port	
	ADD.w	D4, D0	
	MOVE.w	D0, VDP_data_port	
	ADDI.l	#$00820000, D3	
	MOVE.l	D3, VDP_control_port	
	BRA.b	DrawVerticalText_Next	
DrawVerticalText_NewLine_Loop:
	ADDI.l	#$01000000, D5          ; advance to next text column ($10 tiles)
	BRA.b	DrawVerticalText
DrawVerticalText_NewLine_Loop2:
	RTS

; ======================================================================
; Prologue Fade / Text Data
; ======================================================================

PrologueFadeParamData: ; Fade animation data during prologue
	dc.b	$01 
	dc.b	$02
	dc.b	$01 
	dc.b	$01
	dc.b	$00, $00, $03 
	dc.b	$02
	dc.b	$01 
	dc.b	$08
	dc.b	$01 
	dc.b	$04
	dc.b	$00, $00, $03 
	dc.b	$08
	dc.b	$02 
	dc.b	$FF
	dc.b	$00, $00, $01 
	dc.b	$06
	dc.b	$01 
	dc.b	$01
	dc.b	$00, $00, $03 
	dc.b	$06
	dc.b	$02 
	dc.b	$FF
	dc.b	$00, $00, $01 
	dc.b	$02
	dc.b	$01 
	dc.b	$01
	dc.b	$00, $00, $03 
	dc.b	$02
	dc.b	$01 
	dc.b	$08
	dc.b	$01 
	dc.b	$04
	dc.b	$00, $00, $03 
	dc.b	$08
	dc.b	$02 
	dc.b	$FF
	dc.b	$00, $00, $01 
	dc.b	$01
	dc.b	$00, $00, $02 
	dc.b	$FF
	dc.b	$00, $00, $00, $00 
Prologue1Str:
	dc.b	"Long ago, King", $FE
	dc.b	"Tsarkon of Cartahena", $FE
	dc.b	"unleashed his evil", $FE
	dc.b	"hordes upon the", $FE
	dc.b	"peaceful land of", $FE
	dc.b	"Excalabria.", $FF 
Prologue2Str: 
	dc.b	"Though the people of", $FE
	dc.b	"Excalabria fought", $FE
	dc.b	"bravely, in the end", $FE
	dc.b	"they were overwhelmed.", $FF
Prologue3Str:
	dc.b	"As his castle", $FE
	dc.b	"collapsed around him,", $FE
	dc.b	"King Erik V of", $FE
	dc.b	"Excalabria summoned", $FE
	dc.b	"Blade, his most", $FE
	dc.b	"trusted servant. Erik", $FE
	dc.b	"commanded Blade to", $FE
	dc.b	"escape with Erik's", $FE
	dc.b	"infant son and the", $FE
	dc.b	"Ring of Wisdom, an", $FE
	dc.b	"ancient family", $FE
	dc.b	"heirloom.", $FF
Prologue4Str:
	dc.b	"Blade slipped out a", $FE
	dc.b	"secret passage as the", $FE
	dc.b	"castle was engulfed", $FE
	dc.b	"in flames.", $FF, $00
Prologue5Str:
	dc.b	"He fled with the babe", $FE
	dc.b	"to a distant village", $FE
	dc.b	"and raised the child", $FE
	dc.b	"as his own.", $FF
Prologue6Str:
	dc.b	"Tsarkon vowed to devote", $FE
	dc.b	"all of Cartahena's power", $FE
	dc.b	"to searching for the", $FE
	dc.b	"Prince. Eighteen years", $FE
	dc.b	"have passed since Tsarkon", $FE
	dc.b	"began his search....", $FF
MenuObjectHandler:
	CLR.w	Town_camera_move_state.w
	MOVE.l	#TownCameraAndPaletteUpdate, obj_tick_fn(A5)
	CLR.b	Camera_scrolling_active.w
	RTS

TownCameraAndPaletteUpdate:
	TST.b	Is_in_battle.w
	BNE.b	TownCameraTick_Return
	TST.b	Player_in_first_person_mode.w
	BNE.b	TownCameraTick_Return
	TST.b	Fade_out_lines_mask.w
	BNE.b	TownCameraTick_Return
	TST.b	Fade_in_lines_mask.w
	BNE.b	TownCameraTick_Return
	TST.w	Palette_line_2_index.w
	BEQ.b	TownCameraAndPaletteUpdate_Loop
	BSR.w	UpdatePaletteCycle
TownCameraAndPaletteUpdate_Loop:
	MOVE.b	#FLAG_TRUE, Camera_scrolling_active.w
	MOVE.w	Town_camera_move_state.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	CameraMovementJumpTable, A0
	JSR	(A0,D0.w)
TownCameraTick_Return:
	RTS

CameraMovementJumpTable: ; suspected camera movement handling
	BRA.w	ResetTownCameraMovementState
	BRA.w	ResetTownCameraMovementState_Loop
	BRA.w	TownCameraScrollUp_TileStep_Loop
	BRA.w	TownCameraScrollDown_TileStep_Loop
	BRA.w	TownCameraScrollLeft_TileStep_Loop
ResetTownCameraMovementState:
	CLR.b	Camera_scrolling_active.w
	CLR.w	Town_camera_move_state.w
	MOVE.w	#$0010, Town_camera_move_counter.w
	RTS

ResetTownCameraMovementState_Loop:
	TST.w	VScroll_base.w
	BLE.b	ResetTownCameraMovementState
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_y(A6), D0
	SUB.w	Camera_scroll_y.w, D0
	ADDQ.w	#4, D0
	ASR.w	#4, D0
	CMPI.w	#8, D0
	BGE.b	ResetTownCameraMovementState
	SUBQ.w	#1, VScroll_base.w
	SUBQ.w	#1, Camera_scroll_y.w
	SUBQ.w	#1, Town_camera_move_counter.w
	BLE.b	ResetTownCameraMovementState_Loop2
	RTS

ResetTownCameraMovementState_Loop2:
	MOVE.w	Town_tilemap_height.w, D1
	CMPI.w	#TOWN_MAP_MIN_SCROLL_TILES, D1
	BLE.b	TownCameraScrollUp_TileStep
	MOVE.w	Town_camera_tile_y.w, D0
	BLE.b	TownCameraScrollUp_TileStep_Loop2
	CMPI.w	#3, D0
	BLT.b	TownCameraScrollUp_TileStep
	BSR.w	DrawTownRow_Up
TownCameraScrollUp_TileStep:
	SUBQ.w	#1, Town_camera_tile_y.w
	BRA.b	TownCameraScrollUp_TileStep_Loop3
TownCameraScrollUp_TileStep_Loop2:
	CLR.w	Town_camera_tile_y.w
TownCameraScrollUp_TileStep_Loop3:
	BRA.b	ResetTownCameraMovementState
TownCameraScrollUp_TileStep_Loop:
	MOVE.w	VScroll_base.w, D0
	CMP.w	VScroll_max_limit.w, D0
	BGE.b	ResetTownCameraMovementState
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_y(A6), D0
	SUB.w	Camera_scroll_y.w, D0
	ADDQ.w	#4, D0
	ASR.w	#4, D0
	CMPI.w	#6, D0
	BLE.w	ResetTownCameraMovementState
	ADDQ.w	#1, VScroll_base.w
	ADDQ.w	#1, Camera_scroll_y.w
	SUBQ.w	#1, Town_camera_move_counter.w
	BLE.b	TownCameraScrollUp_TileStep_Loop4
	RTS

TownCameraScrollUp_TileStep_Loop4:
	MOVE.w	Town_tilemap_height.w, D1
	CMPI.w	#TOWN_MAP_MIN_SCROLL_TILES, D1
	BLE.b	TownCameraScrollDown_TileStep
	SUBI.w	#$001C, D1
	CMP.w	Town_camera_tile_y.w, D1
	BLE.b	TownCameraScrollDown_TileStep
	BSR.w	DrawTownRow_Bottom
TownCameraScrollDown_TileStep:
	ADDQ.w	#1, Town_camera_tile_y.w
	BRA.w	ResetTownCameraMovementState
TownCameraScrollDown_TileStep_Loop:
	TST.w	HScroll_base.w
	BGE.w	ResetTownCameraMovementState
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), D0
	SUB.w	Camera_scroll_x.w, D0
	SUBQ.w	#8, D0
	ASR.w	#4, D0
	CMPI.w	#$000B, D0
	BGE.w	ResetTownCameraMovementState
	ADDQ.w	#1, HScroll_base.w
	SUBQ.w	#1, Camera_scroll_x.w
	SUBQ.w	#1, Town_camera_move_counter.w
	BLE.b	TownCameraScrollDown_TileStep_Loop2
	RTS

TownCameraScrollDown_TileStep_Loop2:
	MOVE.w	Town_tilemap_width.w, D1
	CMPI.w	#TOWN_MAP_MIN_SCROLL_TILES, D1
	BLE.b	TownCameraScrollLeft_TileStep
	MOVE.w	Town_camera_tile_x.w, D0
	BLE.b	TownCameraScrollLeft_TileStep_Loop2
	SUBQ.w	#3, D0
	BLT.b	TownCameraScrollLeft_TileStep
	BSR.w	DrawTownColumn_Left
TownCameraScrollLeft_TileStep:
	SUBQ.w	#1, Town_camera_tile_x.w
	BRA.b	TownCameraScrollLeft_TileStep_Loop3
TownCameraScrollLeft_TileStep_Loop2:
	CLR.w	Town_camera_tile_x.w
TownCameraScrollLeft_TileStep_Loop3:
	BRA.w	ResetTownCameraMovementState
TownCameraScrollLeft_TileStep_Loop:
	MOVE.w	HScroll_base.w, D0
	CMP.w	HScroll_min_limit.w, D0
	BLE.w	ResetTownCameraMovementState
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), D0
	SUB.w	Camera_scroll_x.w, D0
	SUBQ.w	#8, D0
	ASR.w	#4, D0
	CMPI.w	#8, D0
	BLE.w	ResetTownCameraMovementState
	SUBQ.w	#1, HScroll_base.w
	ADDQ.w	#1, Camera_scroll_x.w
	SUBQ.w	#1, Town_camera_move_counter.w
	BLE.b	TownCameraScrollLeft_TileStep_Loop4
	RTS
	
TownCameraScrollLeft_TileStep_Loop4:
	MOVE.w	Town_tilemap_width.w, D1
	CMPI.w	#TOWN_MAP_MIN_SCROLL_TILES, D1
	BLE.b	TownCameraScrollRight_TileStep
	SUBI.w	#$001C, D1
	CMP.w	Town_camera_tile_x.w, D1
	BLE.b	TownCameraScrollRight_TileStep
	BSR.w	DrawTownColumn_Right
TownCameraScrollRight_TileStep:
	ADDQ.w	#1, Town_camera_tile_x.w
	BRA.w	ResetTownCameraMovementState
LoadTownTilemaps:
	LEA	TownRoomTilemapPlaneAPtrs, A0
	MOVE.w	Current_town_room.w, D0
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	(A0)
	BSR.w	DecompressTilemaps_PlaneA
	LEA	Town_tilemap_plane_a, A0
	LEA	Town_tilemap_plane_a_ptr.w, A1
	LEA	Tilemap_buffer_plane_a, A6
	CLR.w	Tilemap_plane_select.w
	BSR.w	InitializeTilemapFromData
	LEA	TownRoomTilemapPlaneBPtrs, A0
	MOVE.w	Current_town_room.w, D0
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	(A0)
	BSR.w	DecompressTilemaps_PlaneB
	LEA	Town_tilemap_plane_b, A0
	LEA	Town_tilemap_plane_b_ptr.w, A1
	LEA	Tilemap_buffer_plane_b, A6
	MOVE.w	#TILEMAP_PLANE_B, Tilemap_plane_select.w
	BSR.w	InitializeTilemapFromData
	MOVE.w	Town_tilemap_height.w, D0
	ASL.w	#4, D0
	SUBI.w	#$00E0, D0
	MOVE.w	D0, VScroll_max_limit.w
	MOVE.w	Town_tilemap_width.w, D0
	ASL.w	#4, D0
	SUBI.w	#$0140, D0
	NEG.w	D0
	MOVE.w	D0, HScroll_min_limit.w
	MOVE.w	Town_camera_tile_x.w, D0
	MOVE.w	Town_camera_tile_y.w, D1
	ASL.w	#4, D0
	ASL.w	#4, D1
	MOVE.w	D0, Camera_scroll_x.w
	MOVE.w	D1, Camera_scroll_y.w
	NEG.w	D0
	MOVE.w	D0, HScroll_base.w
	MOVE.w	D1, VScroll_base.w
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	Player_spawn_position_x.w, obj_world_x(A6)
	MOVE.w	Player_spawn_tile_y.w, obj_world_y(A6)
	RTS

InitializeTilemapFromData:
	MOVE.l	A0, (A1)
	MOVE.w	(A0)+, D0
	MOVE.w	D0, Town_tilemap_width.w
	MOVE.w	(A0)+, D1
	MOVE.w	D1, Town_tilemap_height.w
	MOVE.w	D0, D2
	MULU.w	D1, D0
	MOVE.w	D0, Tilemap_total_tiles.w
	CLR.b	Tilemap_row_overflow_flag.w
	MOVE.w	Town_camera_spawn_x.w, D0
	MOVE.w	D0, Town_camera_tile_x.w
	MOVE.w	Town_camera_target_tile_y.w, D1
	MOVE.w	D1, Town_camera_tile_y.w
	CMPI.w	#3, D0
	BGE.b	InitializeTilemapFromData_Loop
	MOVEQ	#3, D0
InitializeTilemapFromData_Loop:
	SUBQ.w	#3, D0
	CMPI.w	#3, D1
	BGE.b	InitializeTilemapFromData_Loop2
	MOVEQ	#3, D1
InitializeTilemapFromData_Loop2:
	SUBQ.w	#3, D1
	MULU.w	D1, D2
	ADD.w	D2, D0
	ASL.w	#1, D0
	LEA	(A0,D0.w), A0
	MOVEQ	#$1F, D7
	MOVE.w	D1, D4
InitializeTilemapFromData_Loop2_Done:
	CMP.w	Town_tilemap_height.w, D4
	BLT.b	InitializeTilemapFromData_Loop3
	MOVE.b	#FLAG_TRUE, Tilemap_row_overflow_flag.w
InitializeTilemapFromData_Loop3:
	MOVEQ	#$1F, D6
	MOVE.w	Town_camera_tile_x.w, D5
	CMPI.w	#3, D5
	BGE.b	InitializeTilemapFromData_Loop4
	MOVEQ	#3, D5
InitializeTilemapFromData_Loop4:
	SUBQ.w	#3, D5
	LEA	(A0), A3
InitializeTilemapFromData_Loop4_Done:
	MOVE.w	D4, D0
	MOVE.w	D5, D1
	ANDI.w	#$1F, D0
	ANDI.w	#$1F, D1
	ASL.w	#8, D0
	ASL.w	#2, D1
	ADD.w	D1, D0
	LEA	(A6,D0.w), A2
	TST.b	Tilemap_row_overflow_flag.w
	BNE.b	WriteTownTilemap_ClearTile
	CMP.w	Town_tilemap_width.w, D5
	BGE.b	WriteTownTilemap_ClearTile
	MOVE.w	(A3)+, D0
	TST.w	Tilemap_plane_select.w
	BEQ.b	InitializeTilemapFromData_Loop5
	BSR.w	WriteTownTile2x2
	BRA.b	InitializeTilemapFromData_Loop6
InitializeTilemapFromData_Loop5:
	BSR.w	WriteTownTile2x2WithFlip
InitializeTilemapFromData_Loop6:
	BRA.b	WriteTownTilemap_ClearTile_Loop
WriteTownTilemap_ClearTile:
	MOVE.l	#0, (A2)
	MOVE.l	#0, $80(A2)
WriteTownTilemap_ClearTile_Loop:
	ADDQ.w	#1, D5
	DBF	D6, InitializeTilemapFromData_Loop4_Done
	ADDQ.w	#1, D4
	MOVE.w	Town_tilemap_width.w, D0
	ADD.w	D0, D0
	LEA	(A0,D0.w), A0
	LEA	$80(A2), A2
	DBF	D7, InitializeTilemapFromData_Loop2_Done
	RTS

WriteTownTile2x2WithFlip:
	MOVE.w	#$000C, D3
	LEA	TownTilesetPtrs, A1
	MOVE.w	Town_tileset_index.w, D1
	ADD.w	D1, D1
	ADD.w	D1, D1
	MOVEA.l	(A1,D1.w), A1
	MOVE.w	D0, D1
	ANDI.w	#$00FF, D0
	ANDI.w	#$FF00, D1
	ASL.w	#3, D0
	LEA	(A1,D0.w), A4
	MOVE.w	(A4)+, D0
	OR.w	D1, D0
	MOVE.w	D0, (A2)
	MOVE.w	(A4)+, D0
	OR.w	D1, D0
	MOVE.w	D0, $2(A2)
	BTST.l	D3, D1
	BEQ.b	WriteTownTile2x2WithFlip_Loop
	ANDI.w	#$7FFF, D1
WriteTownTile2x2WithFlip_Loop:
	MOVE.w	(A4)+, D0
	OR.w	D1, D0
	MOVE.w	D0, $80(A2)
	MOVE.w	(A4)+, D0
	OR.w	D1, D0
	MOVE.w	D0, $82(A2)
	RTS

WriteTownTile2x2:
	LEA	TownTilesetPtrs, A1
	MOVE.w	Town_tileset_index.w, D1
	ADD.w	D1, D1
	ADD.w	D1, D1
	MOVEA.l	(A1,D1.w), A1
	MOVE.w	D0, D1
	ANDI.w	#$00FF, D0
	ANDI.w	#$FF00, D1
	ASL.w	#3, D0
	LEA	(A1,D0.w), A4
	MOVE.w	(A4)+, D0
	OR.w	D1, D0
	MOVE.w	D0, (A2)
	MOVE.w	(A4)+, D0
	OR.w	D1, D0
	MOVE.w	D0, $2(A2)
	MOVE.w	(A4)+, D0
	OR.w	D1, D0
	MOVE.w	D0, $80(A2)
	MOVE.w	(A4)+, D0
	OR.w	D1, D0
	MOVE.w	D0, $82(A2)
	RTS

WriteTownTilemapToVRAM:
	ORI	#$0700, SR
	MOVE.l	#$40000003, VDP_control_port
	LEA	Tilemap_buffer_plane_a, A0
	MOVE.w	#$0FFF, D4
WriteTownTilemapToVRAM_Done:
	MOVE.w	(A0)+, D1
	MOVE.w	D1, D2
	ANDI.w	#$01FF, D1
	ANDI.w	#$E000, D2
	OR.w	D1, D2
	ADDI.w	#$0300, D2
	MOVE.w	D2, VDP_data_port
	DBF	D4, WriteTownTilemapToVRAM_Done
	MOVE.l	#$60000003, VDP_control_port
	LEA	Tilemap_buffer_plane_b, A0
	MOVE.w	#$0FFF, D4
WriteTownTilemapToVRAM_Done2:
	MOVE.w	(A0)+, D1
	MOVE.w	D1, D2
	ANDI.w	#$01FF, D1
	ANDI.w	#$0E00, D2
	ASL.w	#4, D2
	OR.w	D1, D2
	ADDI.w	#$0300, D2
	MOVE.w	D2, VDP_data_port
	DBF	D4, WriteTownTilemapToVRAM_Done2
	ANDI	#$F8FF, SR
	LEA	TownPaletteConfigTable, A0
	MOVE.w	Current_town_room.w, D0
	CMPI.w	#$000F, D0
	BLE.w	LoadTownTilesetPalette
	CMPI.w	#$001F, D0
	BLE.b	WriteTownTilemapToVRAM_Loop
	CMPI.w	#$002A, D0
	BLE.w	LoadTownTilesetPalette
	CMPI.w	#$002D, D0
	BLE.b	WriteTownTilemapToVRAM_Loop2
	MOVE.w	#6, D0
	BRA.b	WriteTownTilemapToVRAM_SetPalette
WriteTownTilemapToVRAM_Loop2:
	MOVE.w	#5, D0
	BRA.b	WriteTownTilemapToVRAM_SetPalette
WriteTownTilemapToVRAM_Loop:
	MOVE.w	#7, D0
WriteTownTilemapToVRAM_SetPalette:
	ASL.w	#3, D0
	LEA	(A0,D0.w), A0
	MOVE.w	(A0), Palette_line_1_index.w
	MOVE.w	(A0)+, Palette_line_1_index_saved.w
	MOVE.w	(A0), Palette_line_2_index.w
	MOVE.w	(A0)+, Palette_line_2_cycle_base.w
	MOVE.w	(A0)+, Palette_line_2_cycle_index_1.w
	MOVE.w	(A0)+, Palette_line_2_cycle_index_2.w
	RTS

LoadTownTilesetPalette:
	MOVE.w	Town_tileset_index.w, D0
	CMPI.w	#TOWN_TILESET_VILLAGE_B, D0
	BEQ.b	LoadTownTilesetPalette_Loop
	BRA.b	WriteTownTilemapToVRAM_SetPalette
LoadTownTilesetPalette_Loop:
	ASL.w	#3, D0
	LEA	(A0,D0.w), A0
	MOVE.w	(A0)+, D0
	MOVE.w	(A0), Palette_line_2_index.w
	MOVE.w	(A0)+, Palette_line_2_cycle_base.w
	MOVE.w	(A0)+, Palette_line_2_cycle_index_1.w
	MOVE.w	(A0)+, Palette_line_2_cycle_index_2.w
	LEA	TownPaletteLine1IndexTable, A0
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), Palette_line_1_index.w
	MOVE.w	Palette_line_1_index.w, Palette_line_1_index_saved.w
	RTS

DrawTownRow_Up:
	MOVE.w	Town_camera_tile_y.w, D0
	SUBQ.w	#3, D0
	MOVE.w	Town_camera_tile_x.w, D6
	LEA	Tilemap_buffer_plane_a, A3
	MOVEA.l	Town_tilemap_plane_a_ptr.w, A0
	MOVEQ	#$1D, D5
	CLR.w	Tilemap_plane_select.w
	BSR.w	DrawTownTilemapRow
	MOVE.w	Town_camera_tile_y.w, D0
	SUBQ.w	#3, D0
	MOVE.w	Town_camera_tile_x.w, D6
	LEA	Tilemap_buffer_plane_b, A3
	MOVEA.l	Town_tilemap_plane_b_ptr.w, A0
	MOVEQ	#$1D, D5
	MOVE.w	#TILEMAP_PLANE_B, Tilemap_plane_select.w
	BSR.w	DrawTownTilemapRow
	MOVE.w	Town_camera_tile_y.w, D0
	SUBQ.w	#3, D0
	MOVE.w	Town_camera_tile_x.w, D6
	SUBQ.w	#2, D6
	LEA	Tilemap_buffer_plane_a, A3
	MOVEA.l	Town_tilemap_plane_a_ptr.w, A0
	MOVEQ	#1, D5
	CLR.w	Tilemap_plane_select.w
	BSR.w	DrawTownTilemapRow
	MOVE.w	Town_camera_tile_y.w, D0
	SUBQ.w	#3, D0
	MOVE.w	Town_camera_tile_x.w, D6
	SUBQ.w	#2, D6
	LEA	Tilemap_buffer_plane_b, A3
	MOVEA.l	Town_tilemap_plane_b_ptr.w, A0
	MOVEQ	#1, D5
	MOVE.w	#TILEMAP_PLANE_B, Tilemap_plane_select.w
	BSR.w	DrawTownTilemapRow
	MOVE.w	Town_camera_tile_y.w, D0
	SUBQ.w	#3, D0
	MOVE.w	D0, Town_tilemap_update_row.w
	MOVE.b	#FLAG_TRUE, Town_tilemap_row_update_pending.w
	RTS

DrawTownColumn_Left:
	MOVE.w	Town_camera_tile_x.w, D0
	SUBQ.w	#3, D0
	MOVE.w	Town_camera_tile_y.w, D6
	LEA	Tilemap_buffer_plane_a, A3
	MOVEA.l	Town_tilemap_plane_a_ptr.w, A0
	MOVEQ	#$1D, D5
	CLR.w	Tilemap_plane_select.w
	BSR.w	DrawTownTilemapColumn
	MOVE.w	Town_camera_tile_x.w, D0
	SUBQ.w	#3, D0
	MOVE.w	Town_camera_tile_y.w, D6
	LEA	Tilemap_buffer_plane_b, A3
	MOVEA.l	Town_tilemap_plane_b_ptr.w, A0
	MOVEQ	#$1D, D5
	MOVE.w	#TILEMAP_PLANE_B, Tilemap_plane_select.w
	BSR.w	DrawTownTilemapColumn
	MOVE.w	Town_camera_tile_x.w, D0
	SUBQ.w	#3, D0
	MOVE.w	Town_camera_tile_y.w, D6
	SUBQ.w	#2, D6
	LEA	Tilemap_buffer_plane_a, A3
	MOVEA.l	Town_tilemap_plane_a_ptr.w, A0
	MOVEQ	#1, D5
	CLR.w	Tilemap_plane_select.w
	BSR.w	DrawTownTilemapColumn
	MOVE.w	Town_camera_tile_x.w, D0
	SUBQ.w	#3, D0
	MOVE.w	Town_camera_tile_y.w, D6
	SUBQ.w	#2, D6
	LEA	Tilemap_buffer_plane_b, A3
	LEA	Town_tilemap_plane_b, A0
	MOVEQ	#1, D5
	MOVE.w	#TILEMAP_PLANE_B, Tilemap_plane_select.w
	BSR.w	DrawTownTilemapColumn
	MOVE.w	Town_camera_tile_x.w, D0
	SUBQ.w	#3, D0
	MOVE.w	D0, Town_tilemap_update_column.w
	MOVE.b	#FLAG_TRUE, Town_tilemap_column_update_pending.w
	RTS

DrawTownRow_Bottom:
	MOVE.w	Town_camera_tile_y.w, D0
	ADDI.w	#$1C, D0
	MOVE.w	Town_camera_tile_x.w, D6
	LEA	Tilemap_buffer_plane_a, A3
	MOVEA.l	Town_tilemap_plane_a_ptr.w, A0
	MOVEQ	#$1D, D5
	CLR.w	Tilemap_plane_select.w
	BSR.w	DrawTownTilemapRow
	MOVE.w	Town_camera_tile_y.w, D0
	ADDI.w	#$001C, D0
	MOVE.w	Town_camera_tile_x.w, D6
	LEA	Tilemap_buffer_plane_b, A3
	LEA	Town_tilemap_plane_b, A0
	MOVEQ	#$1D, D5
	MOVE.w	#TILEMAP_PLANE_B, Tilemap_plane_select.w
	BSR.w	DrawTownTilemapRow
	MOVE.w	Town_camera_tile_y.w, D0
	ADDI.w	#$1C, D0
	MOVE.w	Town_camera_tile_x.w, D6
	SUBQ.w	#2, D6
	LEA	Tilemap_buffer_plane_a, A3
	MOVEA.l	Town_tilemap_plane_a_ptr.w, A0
	MOVEQ	#1, D5
	CLR.w	Tilemap_plane_select.w
	BSR.w	DrawTownTilemapRow
	MOVE.w	Town_camera_tile_y.w, D0
	ADDI.w	#$1C, D0
	MOVE.w	Town_camera_tile_x.w, D6
	SUBQ.w	#2, D6
	LEA	Tilemap_buffer_plane_b, A3
	LEA	Town_tilemap_plane_b, A0
	MOVEQ	#1, D5
	MOVE.w	#TILEMAP_PLANE_B, Tilemap_plane_select.w
	BSR.w	DrawTownTilemapRow
	MOVE.w	Town_camera_tile_y.w, D0
	ADDI.w	#$1C, D0
	MOVE.w	D0, Town_tilemap_update_row.w
	MOVE.b	#FLAG_TRUE, Town_tilemap_row_update_pending.w
	RTS

DrawTownColumn_Right:
	MOVE.w	Town_camera_tile_x.w, D0
	ADDI.w	#$1C, D0
	MOVE.w	Town_camera_tile_y.w, D6
	LEA	Tilemap_buffer_plane_a, A3
	MOVEA.l	Town_tilemap_plane_a_ptr.w, A0
	MOVEQ	#$0000001D, D5
	CLR.w	Tilemap_plane_select.w
	BSR.w	DrawTownTilemapColumn
	MOVE.w	Town_camera_tile_x.w, D0
	ADDI.w	#$1C, D0
	MOVE.w	Town_camera_tile_y.w, D6
	LEA	Tilemap_buffer_plane_b, A3
	LEA	Town_tilemap_plane_b, A0
	MOVEQ	#$0000001D, D5
	MOVE.w	#TILEMAP_PLANE_B, Tilemap_plane_select.w
	BSR.w	DrawTownTilemapColumn
	MOVE.w	Town_camera_tile_x.w, D0
	ADDI.w	#$1C, D0
	MOVE.w	Town_camera_tile_y.w, D6
	SUBQ.w	#2, D6
	LEA	Tilemap_buffer_plane_a, A3
	MOVEA.l	Town_tilemap_plane_a_ptr.w, A0
	MOVEQ	#1, D5
	CLR.w	Tilemap_plane_select.w
	BSR.w	DrawTownTilemapColumn
	MOVE.w	Town_camera_tile_x.w, D0
	ADDI.w	#$1C, D0
	MOVE.w	Town_camera_tile_y.w, D6
	SUBQ.w	#2, D6
	LEA	Tilemap_buffer_plane_b, A3
	LEA	Town_tilemap_plane_b, A0
	MOVEQ	#1, D5
	MOVE.w	#TILEMAP_PLANE_B, Tilemap_plane_select.w
	BSR.w	DrawTownTilemapColumn
	MOVE.w	Town_camera_tile_x.w, D0
	ADDI.w	#$1C, D0
	MOVE.w	D0, Town_tilemap_update_column.w
	MOVE.b	#FLAG_TRUE, Town_tilemap_column_update_pending.w
	RTS

DrawTownTilemapRow:
	ASL.w	#1, D6
	MOVE.w	D0, D2
	ANDI.w	#$1F, D2
	MOVE.w	Town_tilemap_width.w, D4
	MULU.w	D4, D0
	ASL.w	#8, D2
	ASL.w	#1, D0
	ADD.w	D6, D0
	ADDQ.w	#4, D0
	MOVE.w	D0, D7
	ANDI.w	#$3F, D6
	ASL.w	#1, D6
	MOVE.w	D2, D4
	ADD.w	D6, D2
DrawTownTilemapRow_Done:
	ANDI.w	#$1FFF, D2
	LEA	(A3,D2.w), A2
	MOVE.w	(A0,D7.w), D0
	MOVE.w	D6, D1
	LSR.w	#1, D1
	SUB.w	D1, D2
	LSR.w	#2, D2
	LEA	(A4,D2.w), A6
	TST.w	Tilemap_plane_select.w
	BEQ.b	DrawTownTilemapRow_Loop
	BSR.w	WriteTownTile2x2
	BRA.b	DrawTownTilemapRow_Loop2
DrawTownTilemapRow_Loop:
	BSR.w	WriteTownTile2x2WithFlip
DrawTownTilemapRow_Loop2:
	ADDQ.w	#2, D7
	ADDQ.w	#4, D6
	ANDI.w	#$7F, D6
	CLR.w	D2
	MOVE.w	D4, D2
	ADD.w	D6, D2
	DBF	D5, DrawTownTilemapRow_Done
	RTS

DrawTownTilemapColumn:
	ASL.w	#1, D0
	MOVE.w	D0, D2
	ASL.w	#1, D2
	ANDI.w	#$7F, D2
	MOVE.w	D2, D4
	MOVE.w	Town_tilemap_width.w, D1
	MULU.w	D6, D1
	ANDI.w	#$1F, D6
	ASL.w	#8, D6
	ASL.w	#1, D1
	ADD.w	D1, D0
	ADDQ.w	#4, D0
	MOVE.w	D0, D7
	ADD.w	D6, D2
DrawTownTilemapColumn_Done:
	ANDI.w	#$1FFF, D2
	LEA	(A3,D2.w), A2
	MOVE.w	(A0,D7.w), D0
	TST.w	Tilemap_plane_select.w
	BEQ.b	DrawTownTilemapColumn_Loop
	BSR.w	WriteTownTile2x2
	BRA.b	DrawTownTilemapColumn_Loop2
DrawTownTilemapColumn_Loop:
	BSR.w	WriteTownTile2x2WithFlip
DrawTownTilemapColumn_Loop2:
	MOVE.w	Town_tilemap_width.w, D1
	ASL.w	#1, D1
	ADD.w	D1, D7
	MOVE.w	Town_camera_tile_y.w, D3
	ANDI.w	#$000F, D3
	ADDI.w	#$0100, D6
	ANDI.w	#$1F00, D6
	CLR.w	D2
	MOVE.w	D4, D2
	ADD.w	D6, D2
	DBF	D5, DrawTownTilemapColumn_Done
	RTS

UpdateTownTilemapRow:
	LEA	Tilemap_buffer_plane_a, A3
	MOVE.w	#$C000, D5
	BSR.w	WriteTilemapRowToVDP
	LEA	Tilemap_buffer_plane_b, A3
	MOVE.w	#$E000, D5
	BSR.w	WriteTilemapRowToVDP
	RTS

WriteTilemapRowToVDP:
	MOVE.w	Town_tilemap_update_row.w, D0
	ANDI.l	#$1F, D0
	ASL.w	#8, D0
	LEA	(A3,D0.w), A0
	MOVEQ	#0, D1
	MOVE.w	D5, D1
	ADD.w	D0, D1
	MOVE.l	D1, D0
	ANDI.w	#$3FFF, D0
	ORI.w	#$4000, D0
	SWAP	D0
	AND.w	D5, D1
	MOVEQ	#$E, D2
	LSR.w	D2, D1
	ADD.w	D1, D0
	MOVE.l	D0, VDP_control_port
	MOVEQ	#$7F, D5
WriteTilemapRowToVDP_Done:
	MOVE.w	(A0)+, D1
	MOVE.w	D1, D2
	ANDI.w	#$01FF, D1
	CMPA.l	#Tilemap_buffer_plane_b, A3
	BNE.b	WriteTilemapRowToVDP_Loop
	ANDI.w	#$0E00, D2
	ASL.w	#4, D2
	BRA.b	WriteTilemapRowToVDP_Loop2
WriteTilemapRowToVDP_Loop:
	ANDI.w	#$E000, D2
WriteTilemapRowToVDP_Loop2:
	OR.w	D1, D2
	ADD.w	Town_vram_tile_base.w, D2
	MOVE.w	D2, VDP_data_port
	DBF	D5, WriteTilemapRowToVDP_Done
	RTS

UpdateTownTilemapColumn:
	LEA	Tilemap_buffer_plane_a, A3
	MOVE.w	#$C000, D5
	BSR.w	WriteTilemapColumnToVDP
	LEA	Tilemap_buffer_plane_b, A3
	MOVE.w	#$E000, D5
	BSR.w	WriteTilemapColumnToVDP
	RTS

WriteTilemapColumnToVDP:
	MOVE.w	Town_tilemap_update_column.w, D0
	ANDI.w	#$1F, D0
	ASL.w	#2, D0
	LEA	(A3,D0.w), A0
	MOVEQ	#0, D1
	MOVE.w	D5, D1
	ADD.w	D0, D1
	MOVE.l	D1, D0
	ANDI.w	#$3FFF, D0
	ORI.w	#$4000, D0
	SWAP	D0
	AND.w	D5, D1
	MOVEQ	#$E, D2
	LSR.w	D2, D1
	ADD.w	D1, D0
	MOVEQ	#$3F, D5
WriteTilemapColumnToVDP_Done:
	MOVE.l	D0, VDP_control_port
	MOVE.w	(A0), D1
	MOVE.w	D1, D2
	ANDI.w	#$01FF, D1
	CMPA.l	#Tilemap_buffer_plane_b, A3
	BNE.b	WriteTilemapColumnToVDP_Loop
	ANDI.w	#$0E00, D2
	ASL.w	#4, D2
	BRA.b	WriteTilemapColumnToVDP_Loop2
WriteTilemapColumnToVDP_Loop:
	ANDI.w	#$E000, D2
WriteTilemapColumnToVDP_Loop2:
	OR.w	D1, D2
	ADD.w	Town_vram_tile_base.w, D2
	MOVE.w	D2, VDP_data_port
	MOVE.w	$2(A0), D1
	MOVE.w	D1, D2
	ANDI.w	#$01FF, D1
	CMPA.l	#Tilemap_buffer_plane_b, A3
	BNE.b	WriteTilemapColumnToVDP_Loop3
	ANDI.w	#$0E00, D2
	ASL.w	#4, D2
	BRA.b	WriteTilemapColumnToVDP_Loop4
WriteTilemapColumnToVDP_Loop3:
	ANDI.w	#$E000, D2
WriteTilemapColumnToVDP_Loop4:
	OR.w	D1, D2
	ADD.w	Town_vram_tile_base.w, D2
	MOVE.w	D2, VDP_data_port
	LEA	$80(A0), A0
	ADDI.l	#$00800000, D0
	DBF	D5, WriteTilemapColumnToVDP_Done
	RTS

; === Palette Cycling ===

; UpdatePaletteCycle
; Steps the palette line 2 cycle index forward by one every 8 frames.
; Detects the 0→1 transition of bit 3 in the frame counter (fires once every 8 frames).
; Wraps the cycle step back to 0 after step 2 (3 steps total: 0, 1, 2).
; If the resolved palette index is 0 the step resets and the base entry is used.
UpdatePaletteCycle:
	ADDQ.b	#1, Palette_cycle_frame_counter.w
	MOVE.b	Palette_cycle_frame_counter.w, D0
	MOVE.b	D0, D1
	SUBQ.b	#1, D1
	EOR.b	D0, D1
	BTST.l	#3, D1
	BEQ.w	TownPaletteCycle_Return
	BTST.l	#3, D0
	BEQ.w	TownPaletteCycle_Return
	ADDQ.b	#1, Palette_line_2_cycle_step.w
	CMPI.b	#2, Palette_line_2_cycle_step.w
	BLE.b	UpdatePaletteCycle_Loop
	CLR.b	Palette_line_2_cycle_step.w
UpdatePaletteCycle_Loop:
	MOVE.b	Palette_line_2_cycle_step.w, D0
	LEA	Palette_line_2_cycle_base.w, A0
	ANDI.w	#3, D0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), D0
	BNE.b	UpdatePaletteCycle_Loop2
	CLR.b	Palette_line_2_cycle_step.w	
	MOVE.w	(A0), D0	
UpdatePaletteCycle_Loop2:
	MOVE.w	D0, Palette_line_2_index.w
	JSR	LoadPalettesFromTable
TownPaletteCycle_Return:
	RTS

; === Town Palette Config Data Tables ===

; TownPaletteConfigTable
; 8 entries, one per town. Each entry is variable-length but pairs of words:
;   word 0: palette line 1 index (tile graphics palette)
;   word 1: palette line 2 base index (primary NPC/object palette)
;   words 2+: palette line 2 cycle indices (used by UpdatePaletteCycle; $0000 = end of cycle)
TownPaletteConfigTable:
	dc.w	$0015
	dc.w	$0016
	dc.b	$00, $17, $00, $18, $00, $19 
	dc.w	$001A
	dc.b	$00, $1B, $00, $1C 
	dc.w	$0024
	dc.w	$0025
	dc.b	$00, $25, $00, $25, $00, $19, $00, $1A, $00, $1B, $00, $1C 
	dc.w	$001D
	dc.w	$001E
	dc.b	$00, $1F, $00, $20 
	dc.w	$0021
	dc.w	$001E
	dc.b	$00, $1F, $00, $20 
	dc.w	$0022
	dc.w	$001E
	dc.b	$00, $1F, $00, $20 
	dc.w	$0023
	dc.w	$001E
	dc.b	$00, $1F, $00, $20 
; TownPaletteLine1IndexTable
; One word per town: the palette index for the town tile line 1 graphics.
TownPaletteLine1IndexTable:
	dc.b	$00, $15 
	dc.w	$002A
	dc.b	$00, $15 
	dc.w	$002B
	dc.w	$002C
	dc.b	$00, $00 
	dc.w	$002D
	dc.w	$002E
	dc.b	$00, $15 
	dc.w	$002F
	dc.b	$00, $15 
	dc.w	$00AF
	dc.b	$00, $00, $00, $15, $00, $00 
	dc.w	$00B0
DecompressTilemaps_PlaneA:
	LEA	Town_tilemap_plane_a_data, A2
	MOVEA.l	Tilemap_data_ptr_plane_a.w, A1
	JSR	DecompressTilemap(PC)
	LEA	Town_tilemap_plane_a_data, A2
	MOVEA.l	Tilemap_data_ptr_plane_b.w, A1
	JSR	DecompressTilemap_WithOffset(PC)
	RTS

; DecompressTilemaps_PlaneB
; Same as DecompressTilemaps_PlaneA but targets the Plane B tilemap data buffer.
DecompressTilemaps_PlaneB:
	LEA	Town_tilemap_plane_b_data, A2
	MOVEA.l	Tilemap_data_ptr_plane_a.w, A1
	JSR	DecompressTilemap(PC)
	LEA	Town_tilemap_plane_b_data, A2
	MOVEA.l	Tilemap_data_ptr_plane_b.w, A1
	JSR	DecompressTilemap_WithOffset(PC)
	RTS

; DecompressTilemap
; Primary decompression entry. Reads width/height header from stream A1, stores them,
; then decompresses data into A2 starting at byte offset 0 (low bytes of each word).
; D6 tracks the current write position (byte index, stepping by 2 per tile).
DecompressTilemap:
	CLR.w	D6
	CLR.w	D0
	CLR.w	D1
	MOVE.b	(A1)+, D1
	MOVE.w	D1, -$4(A2)
	MOVE.b	D1, Tilemap_width.w
	MOVE.b	(A1)+, D0
	MOVE.b	D0, Tilemap_height.w
	MOVE.w	D0, -$2(A2)
	MULU.w	D1, D0
	ADD.w	D0, D0
	MOVE.w	D0, Tilemap_buffer_size.w
	BRA.w	DecompressTilemap_Next
; DecompressTilemap_WithOffset
; Secondary decompression entry. Same as DecompressTilemap but starts A2 at +1
; (ADDQ.w #1, A2 before the loop), so writes land in the high bytes of each word pair.
DecompressTilemap_WithOffset:
	CLR.w	D6
	CLR.w	D0
	CLR.w	D1
	MOVE.b	(A1)+, D1
	MOVE.w	D1, -$4(A2)
	MOVE.b	D1, Tilemap_width.w
	MOVE.b	(A1)+, D0
	MOVE.b	D0, Tilemap_height.w
	MOVE.w	D0, -$2(A2)
	MULU.w	D1, D0
	ADD.w	D0, D0
	MOVE.w	D0, Tilemap_buffer_size.w
	ADDQ.w	#1, A2
DecompressTilemap_Next:
	CLR.w	D0
	CMP.w	Tilemap_buffer_size.w, D6
	BGE.w	TilemapDecompression_JumpTable_Loop
	MOVE.b	(A1)+, D0
	MOVE.w	D0, D1
	ANDI.w	#$00E0, D1
	LSR.w	#5, D1
	MOVE.w	D1, D2
	ASL.w	#2, D2
	JSR	TilemapDecompression_JumpTable(PC,D2.w)
	BRA.b	DecompressTilemap_Next
; TilemapDecompression_JumpTable
; Dispatch table indexed by the 3-bit opcode (bits 7-5 of the command byte).
; Each entry is a BRA.w (4 bytes), so the caller multiplies the opcode by 4.
;   op 0 → TilemapDecompression_JumpTable_Loop2  ; literal run (N bytes, one per entry)
;   op 1 → TilemapDecompression_JumpTable_Loop3  ; RLE run (1 byte repeated N times)
;   op 2 → TilemapDecompression_JumpTable_Loop4  ; RLE run (2-byte sequence repeated)
;   op 3 → TilemapDecompression_JumpTable_Loop5  ; RLE run (3-byte sequence repeated)
;   op 4 → TilemapDecompression_JumpTable_Loop6  ; RLE run (4-byte sequence repeated)
;   op 5 → TilemapDecompression_JumpTable_Loop7  ; copy from 1 row back
;   op 6 → TilemapDecompression_JumpTable_Loop8  ; copy from 2 rows back
;   op 7 → $4E75 (RTS = end of stream)
TilemapDecompression_JumpTable:
	BRA.w	TilemapDecompression_JumpTable_Loop2
	BRA.w	TilemapDecompression_JumpTable_Loop3
	BRA.w	TilemapDecompression_JumpTable_Loop4
	BRA.w	TilemapDecompression_JumpTable_Loop5
	BRA.w	TilemapDecompression_JumpTable_Loop6
	BRA.w	TilemapDecompression_JumpTable_Loop7
	BRA.w	TilemapDecompression_JumpTable_Loop8
	dc.b	$4E, $75 
TilemapDecompression_JumpTable_Loop2:
	ANDI.w	#$001F, D0
	SUBQ.w	#1, D0
TilemapDecompression_JumpTable_Loop2_Done:
	MOVE.b	(A1)+, D1
	MOVE.b	D1, (A2,D6.w)
	ADDQ.w	#2, D6
	DBF	D0, TilemapDecompression_JumpTable_Loop2_Done
	RTS

TilemapDecompression_JumpTable_Loop3:
	ANDI.w	#$001F, D0
	SUBQ.w	#1, D0
	MOVE.b	(A1)+, D1
TilemapDecompression_JumpTable_Loop3_Done:
	MOVE.b	D1, (A2,D6.w)
	ADDQ.w	#2, D6
	DBF	D0, TilemapDecompression_JumpTable_Loop3_Done
	RTS
	
TilemapDecompression_JumpTable_Loop4:
	ANDI.w	#$001F, D0
	SUBQ.w	#1, D0
	MOVE.b	(A1)+, D1
	MOVE.b	(A1)+, D2
TilemapDecompression_JumpTable_Loop4_Done:
	MOVE.b	D1, (A2,D6.w)
	ADDQ.w	#2, D6
	MOVE.b	D2, (A2,D6.w)
	ADDQ.w	#2, D6
	DBF	D0, TilemapDecompression_JumpTable_Loop4_Done
	RTS
	
TilemapDecompression_JumpTable_Loop5:
	ANDI.w	#$001F, D0
	SUBQ.w	#1, D0
	MOVE.b	(A1)+, D1
	MOVE.b	(A1)+, D2
	MOVE.b	(A1)+, D3
TilemapDecompression_JumpTable_Loop5_Done:
	MOVE.b	D1, (A2,D6.w)
	ADDQ.w	#2, D6
	MOVE.b	D2, (A2,D6.w)
	ADDQ.w	#2, D6
	MOVE.b	D3, (A2,D6.w)
	ADDQ.w	#2, D6
	DBF	D0, TilemapDecompression_JumpTable_Loop5_Done
	RTS
	
TilemapDecompression_JumpTable_Loop6:
	ANDI.w	#$001F, D0
	SUBQ.w	#1, D0
	MOVE.b	(A1)+, D1
	MOVE.b	(A1)+, D2
	MOVE.b	(A1)+, D3
	MOVE.b	(A1)+, D4
TilemapDecompression_JumpTable_Loop6_Done:
	MOVE.b	D1, (A2,D6.w)
	ADDQ.w	#2, D6
	MOVE.b	D2, (A2,D6.w)
	ADDQ.w	#2, D6
	MOVE.b	D3, (A2,D6.w)
	ADDQ.w	#2, D6
	MOVE.b	D4, (A2,D6.w)
	ADDQ.w	#2, D6
	DBF	D0, TilemapDecompression_JumpTable_Loop6_Done
	RTS
	
TilemapDecompression_JumpTable_Loop7:
	ANDI.w	#$001F, D0
	SUBQ.w	#1, D0
	MOVE.w	D6, D2
	CLR.w	D3
	MOVE.b	Tilemap_width.w, D3
	SUB.w	D3, D2
	SUB.w	D3, D2
TilemapDecompression_JumpTable_Loop7_Done:
	MOVE.b	(A2,D2.w), (A2,D6.w)
	ADDQ.w	#2, D2
	ADDQ.w	#2, D6
	DBF	D0, TilemapDecompression_JumpTable_Loop7_Done
	RTS
	
TilemapDecompression_JumpTable_Loop8:
	ANDI.w	#$001F, D0
	SUBQ.w	#1, D0
	MOVE.w	D6, D2
	CLR.w	D3
	MOVE.b	Tilemap_width.w, D3
	ADD.w	D3, D3
	SUB.w	D3, D2
	SUB.w	D3, D2
	SUB.w	D3, D2
TilemapDecompression_JumpTable_Loop8_Done:
	MOVE.b	(A2,D2.w), (A2,D6.w)
	ADDQ.w	#2, D2
	ADDQ.w	#2, D6
	DBF	D0, TilemapDecompression_JumpTable_Loop8_Done
	RTS
	
TilemapDecompression_JumpTable_Loop:
	RTS

; === Title Screen ===
; State machine for the title screen sequence. Tick function advances through states:
;   TitleScreen_Init → TitleScreen_WaitForHScroll → TitleScreen_FadeAndAnimate
;   → TitleScreen_LightningFlash → TitleScreen_ShowPressStart
;   → TitleScreen_ScrollAndWait → TitleScreen_IdleWithScroll

; TitleScreen_Init
; One-time setup: clears VRAM planes, draws background/graphics, sets initial palette
; indices, enables HScroll mode 3, triggers the initial HScroll update and fade-in.
TitleScreen_Init:
	CLR.w	Intro_timer.w
	JSR	DisableVDPDisplay
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	BSR.w	DrawIntroBackground
	BSR.w	DrawIntroGraphics
	MOVE.l	#TitleScreen_WaitForHScroll, obj_tick_fn(A5)
	MOVE.w	#0, Palette_line_0_index.w
	MOVE.w	#PALETTE_IDX_TITLE_LOGO, Palette_line_1_index.w
	MOVE.w	#0, Palette_line_2_index.w
	CLR.w	Intro_animation_frame.w
	MOVE.w	#PALETTE_IDX_TITLE_TILES, Palette_line_3_index.w
	MOVE.w	VDP_Reg11_cache.w, D0
	ORI.w	#3, D0
	MOVE.w	D0, VDP_control_port
	CLR.w	Cursor_blink_timer.w
	CLR.w	Intro_scroll_accumulator.w
	MOVE.w	#$FF20, VScroll_base.w
	MOVE.w	VScroll_base.w, D0
	ANDI.w	#$01FF, D0
	MOVE.l	#$40000010, VDP_control_port
	MOVE.w	D0, VDP_data_port
	MOVE.w	D0, VDP_data_port
	MOVE.b	#FLAG_TRUE, HScroll_update_busy.w
	MOVE.b	#FLAG_TRUE, Intro_text_pending.w
	JSR	LoadIntroSegalogGraphics
	JSR	LoadIntroTitleGraphics
	JSR	LoadPalettesFromTable
	JSR	EnableDisplay
	RTS

; ClearEnemyActiveFlags
; Clears the active flag (bit 7) on all 20 enemy list entries without fully deallocating them.
ClearEnemyActiveFlags:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVEQ	#$13, D7
ClearEnemyActiveFlags_Done:
	BCLR.b	#7, (A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, ClearEnemyActiveFlags_Done
	RTS

; TitleScreen_WaitForHScroll
; Spins until the initial HScroll DMA completes, then starts the palette fade-in
; and queues the title screen music.
TitleScreen_WaitForHScroll:
	MOVE.b	#FLAG_TRUE, Scene_update_flag.w
	TST.b	HScroll_update_busy.w
	BNE.b	TitleScreen_WaitForHScroll_Loop
	MOVE.l	#TitleScreen_FadeAndAnimate, obj_tick_fn(A5)
	MOVE.b	#4, Fade_in_lines_mask.w
	MOVE.w	#PALETTE_IDX_TITLE_BG, Palette_line_2_fade_target.w
	PlaySound_b	SOUND_TITLE_MUSIC
TitleScreen_WaitForHScroll_Loop:
	RTS

; TitleScreen_FadeAndAnimate
; Waits for the palette fade-in to complete, then advances the logo animation frame
; every 2 frames (bit 1 edge detect). Transitions to TitleScreen_LightningFlash
; after frame $91.
TitleScreen_FadeAndAnimate:
	BSR.w	UpdateEndingHScrollValues
	TST.b	Fade_in_lines_mask.w
	BNE.b	TitleScreen_FadeAndAnimate_Return
	ADDQ.w	#1, Intro_timer.w
	MOVE.w	Intro_timer.w, D0
	MOVE.w	D0, D1
	SUBQ.w	#1, D1
	EOR.w	D0, D1
	BTST.l	#1, D1
	BEQ.b	TitleScreen_FadeAndAnimate_Return
	MOVE.w	Intro_animation_frame.w, D0
	CMPI.w	#$0018, D0
	BLT.b	TitleScreen_FadeAndAnimate_Loop
	CMPI.w	#$0089, D0
	BGE.b	TitleScreen_FadeAndAnimate_Loop2
	MOVE.w	#$0089, Intro_animation_frame.w
TitleScreen_FadeAndAnimate_Loop2:
	MOVE.w	Intro_animation_frame.w, Palette_line_0_index.w
	JSR	LoadPalettesFromTable
TitleScreen_FadeAndAnimate_Loop:
	ADDQ.w	#1, Intro_animation_frame.w
	MOVE.w	Intro_animation_frame.w, D0
	CMPI.w	#$0091, D0
	BLE.b	TitleScreen_FadeAndAnimate_Return
	CLR.w	Intro_animation_frame.w
	MOVE.l	#TitleScreen_LightningFlash, obj_tick_fn(A5)
TitleScreen_FadeAndAnimate_Return:
	RTS

; TitleScreen_LightningFlash
; Alternates the title palette between the lightning and all-white sets on a 2-frame
; interval, toggling for up to 5 flashes (tracked by Intro_animation_frame).
; After the 5th flash, transitions to TitleScreen_ShowPressStart.
TitleScreen_LightningFlash:
	BSR.w	UpdateEndingHScrollValues
	ADDQ.w	#1, Intro_timer.w
	MOVE.w	Intro_timer.w, D0
	MOVE.w	D0, D1
	SUBQ.w	#1, D1
	EOR.w	D0, D1
	MOVE.w	Intro_animation_frame.w, D2
	CMPI.w	#2, D2
	BLT.b	TitleScreen_LightningFlash_Loop
	BTST.l	#1, D1
	BNE.b	TitleScreen_LightningFlash_Loop2
	RTS

TitleScreen_LightningFlash_Loop:
	BTST.l	#3, D1
	BEQ.b	TitleScreen_LoadPalette_Loop
TitleScreen_LightningFlash_Loop2:
	CMPI.w	#5, D2
	BEQ.b	TitleScreen_LightningFlash_Loop3
	BTST.l	#0, D2
	BEQ.b	TitleScreen_LightningFlash_Loop4
	MOVE.w	#PALETTE_IDX_TITLE_LIGHTNING, Palette_line_0_index.w
	MOVE.w	#PALETTE_IDX_TITLE_TILES, Palette_line_3_index.w
	ADDQ.w	#1, Intro_animation_frame.w
	BRA.b	TitleScreen_LoadPalette
TitleScreen_LightningFlash_Loop4:
	MOVE.w	#PALETTE_IDX_ALL_WHITE, Palette_line_0_index.w
	MOVE.w	#PALETTE_IDX_TITLE_LOGO, Palette_line_3_index.w
	ADDQ.w	#1, Intro_animation_frame.w
	BRA.b	TitleScreen_LoadPalette
TitleScreen_LightningFlash_Loop3:
	MOVE.w	#PALETTE_IDX_TITLE_LIGHTNING, Palette_line_0_index.w
	MOVE.w	#PALETTE_IDX_TITLE_TILES, Palette_line_3_index.w
	MOVE.l	#TitleScreen_ShowPressStart, obj_tick_fn(A5)
TitleScreen_LoadPalette:
	JSR	LoadPalettesFromTable
TitleScreen_LoadPalette_Loop:
	RTS

; TitleScreen_ShowPressStart
; Waits for any pending fade to finish, then draws the "Press Start" text and loads
; the final title palette. On first entry with Intro_text_pending clear, draws the
; logo overlay and transitions the scroll into TitleScreen_ScrollAndWait.
TitleScreen_ShowPressStart:
	BSR.w	UpdateEndingHScrollValues
	TST.b	Intro_text_pending.w
	BEQ.b	TitleScreen_ShowPressStart_Loop
	TST.b	Fade_in_lines_mask.w
	BNE.b	TitleScreen_ShowPressStart_Loop2
	CLR.b	Intro_text_pending.w
	BSR.w	DrawPressStartText
	MOVE.w	#$0031, Palette_line_0_index.w
	JSR	LoadPalettesFromTable
TitleScreen_ShowPressStart_Loop2:
	RTS

TitleScreen_ShowPressStart_Loop:
	MOVE.w	#PALETTE_IDX_TITLE_LOGO, Palette_line_1_index.w
	LEA	TitleScreen_ShowPressStart_Loop_Data, A0
	BSR.w	DrawTilemapToVRAM_PlaneA
	MOVE.w	#$00FF, Prologue_state.w
	MOVE.w	#$02FF, Prologue_scroll_offset.w
	MOVE.l	#TitleScreen_ScrollAndWait, obj_tick_fn(A5)
	BSR.w	SpawnIntroSwordSprite
	JSR	LoadPalettesFromTable
	RTS

; TitleScreen_ScrollAndWait
; Advances the background scroll each frame until PROLOGUE_SCROLL_END is reached,
; then draws the Start/Continue menu, spawns cursor sprites, and moves to IdleWithScroll.
TitleScreen_ScrollAndWait:
	MOVE.w	Prologue_state.w, D1
	CMPI.w	#PROLOGUE_SCROLL_END, D1
	BLT.b	TitleScreen_ScrollAndWait_Loop
	MOVE.b	#FLAG_TRUE, Title_intro_complete.w
	JSR	DrawStartContinueMenu
	BSR.w	SpawnMenuCursorSprites
	MOVE.l	#TitleScreen_IdleWithScroll, obj_tick_fn(A5)
TitleScreen_ScrollAndWait_Loop:
	BSR.w	UpdateEndingHScrollValues
	BSR.w	UpdatePrologueScrollVRAM
	RTS
	
; TitleScreen_IdleWithScroll
; Steady state while the Start/Continue menu is visible; just keeps the HScroll animating.
TitleScreen_IdleWithScroll:
	BSR.w	UpdateEndingHScrollValues
	RTS

; UpdateEndingHScrollValues
; Adds 11 per-scanline speed values from EndingHScrollSpeedTable to the HScroll run
; table each frame, producing the parallax wave effect on the title/ending screen.
UpdateEndingHScrollValues:
	MOVE.b	#FLAG_TRUE, Scene_update_flag.w
	LEA	HScroll_run_table.w, A0
	LEA	EndingHScrollSpeedTable, A1
	MOVE.w	#$A, D7
UpdateEndingHScrollValues_Done:
	MOVE.l	(A1)+, D0
	ADD.l	D0, (A0)+
	DBF	D7, UpdateEndingHScrollValues_Done
	RTS

; UpdatePrologueScrollVRAM
; Writes 85 HScroll values directly to VDP each frame to scroll the background
; during the prologue/intro sequence. Even scanlines use Prologue_state (forward
; scroll), odd scanlines use Prologue_scroll_offset (reverse scroll). Both clamp
; to 0 once their respective limits are reached.
UpdatePrologueScrollVRAM:
	MOVE.l	#$7C440002, D0
	LEA	Prologue_state.w, A0
	ADDI.l	#$000A0000, (A0)
	LEA	Prologue_scroll_offset.w, A1
	SUBI.l	#$000A0000, (A1)
	MOVE.w	#$0054, D7
UpdatePrologueScrollVRAM_Done:
	BTST.l	#0, D7
	BNE.b	UpdatePrologueScrollVRAM_Loop
	MOVE.w	(A0), D1
	CMPI.w	#PROLOGUE_SCROLL_END, D1
	BGE.b	UpdatePrologueScrollVRAM_Loop2
	ANDI.w	#$01FF, D1
	BRA.b	UpdatePrologueScrollVRAM_WriteVDP
UpdatePrologueScrollVRAM_Loop2:
	MOVE.w	#0, D1
	BRA.b	UpdatePrologueScrollVRAM_WriteVDP
UpdatePrologueScrollVRAM_Loop:
	MOVE.w	(A1), D1
	CMPI.w	#0, D1
	BLE.b	UpdatePrologueScrollVRAM_Loop3
	ANDI.w	#$01FF, D1
	BRA.b	UpdatePrologueScrollVRAM_WriteVDP
UpdatePrologueScrollVRAM_Loop3:
	MOVE.w	#0, D1
UpdatePrologueScrollVRAM_WriteVDP:
	MOVE.l	D0, VDP_control_port
	MOVE.w	D1, VDP_data_port
	ADDI.l	#$00040000, D0
	DBF	D7, UpdatePrologueScrollVRAM_Done
	RTS

; === Intro Graphics Drawing ===

; DrawIntroBackground
; Fills 10 rows of VDP Plane B (32 tiles wide) with background tile data from
; DrawIntroBackground_Data, with interrupts disabled during the write.
DrawIntroBackground:
	ORI	#$0700, SR
	MOVE.l	#$49000003, D5
	LEA	DrawIntroBackground_Data, A0
	MOVE.w	#9, D7
DrawIntroBackground_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$001F, D6
DrawIntroBackground_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$E0F3, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawIntroBackground_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, DrawIntroBackground_Done
	ANDI	#$F8FF, SR
	RTS

; DrawIntroGraphics
; Writes the title logo and sword sprite tile data to VRAM in three passes:
;   1. 15 rows × 21 tiles of background tile indices from DrawIntroGraphics_Data.
;   2. 14 rows × 10 tiles of sprite tile indices from SpriteTileIndexTable_619EA.
;   3. 4 groups × 9 rows × 16 tiles of sword sprite tiles from SpriteTileIndexTable_6195A.
DrawIntroGraphics:
	ORI	#$0700, SR
	MOVE.l	#$61800003, D5
	LEA	DrawIntroGraphics_Data, A0
	MOVE.w	#$000E, D7
DrawIntroGraphics_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$0014, D6
DrawIntroGraphics_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$603C, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawIntroGraphics_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, DrawIntroGraphics_Done
	MOVE.l	#$69800003, D4
	MOVE.l	#$60AA0003, D5
	LEA	SpriteTileIndexTable_619EA, A0
	MOVE.w	#$000D, D7
DrawIntroGraphics_Done3:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#9, D6
DrawIntroGraphics_Done4:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$0239, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawIntroGraphics_Done4
	ADDI.l	#$00800000, D5
	DBF	D7, DrawIntroGraphics_Done3
	MOVE.l	#$69800003, D4
	MOVE.w	#3, D7
DrawIntroGraphics_Done5:
	LEA	SpriteTileIndexTable_6195A, A0
	MOVE.w	#8, D6
	MOVE.l	D4, D3
DrawIntroGraphics_Done6:
	MOVE.w	#$F, D5
	MOVE.l	D3, VDP_control_port
DrawIntroGraphics_Done7:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$41CD, D0
	MOVE.w	D0, VDP_data_port
	DBF	D5, DrawIntroGraphics_Done7
	ADDI.l	#$00800000, D3
	DBF	D6, DrawIntroGraphics_Done6
	ADDI.l	#$00200000, D4
	DBF	D7, DrawIntroGraphics_Done5
	ANDI	#$F8FF, SR
	RTS

; DrawTilemapToVRAM_PlaneA
; Writes 10 rows × 33 tiles from A0 into Plane A VRAM, with interrupts disabled.
; Used to draw the "Press Start" / "Continue" overlay on the title screen.
DrawTilemapToVRAM_PlaneA:
	ORI	#$0700, SR
	MOVE.l	#$41880003, D5
	MOVE.w	#9, D7
DrawTilemapToVRAM_PlaneA_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$0020, D6
DrawTilemapToVRAM_PlaneA_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$A263, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawTilemapToVRAM_PlaneA_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, DrawTilemapToVRAM_PlaneA_Done
	ANDI	#$F8FF, SR
	RTS

; SpawnIntroSwordSprite
; Activates the first enemy slot as the animated sword sprite on the title screen.
; Sets position (164, 129), tile VRAM_TILE_INTRO_SWORD, size 1×1, tick = IntroSwordSprite_Tick.
SpawnIntroSwordSprite:
	MOVEA.l	Enemy_list_ptr.w, A6
	BSET.b	#7, (A6)
	BSET.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BCLR.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	CLR.b	obj_move_counter(A6)
	MOVE.w	#$00A4, obj_screen_x(A6)
	MOVE.w	#$0081, obj_screen_y(A6)
	CLR.w	obj_sort_key(A6)
	MOVE.w	#VRAM_TILE_INTRO_SWORD, obj_tile_index(A6)
	MOVE.b	#SPRITE_SIZE_1x1, obj_sprite_size(A6)
	MOVE.l	#IntroSwordSprite_Tick, obj_tick_fn(A6)
	RTS

; IntroSwordSprite_Tick
; Animates the sword sprite by stepping through IntroSwordFrameTable.
; Frame index = (move_counter & $78) >> 2, clamped to 14 ($E).
IntroSwordSprite_Tick:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0078, D0
	ASR.w	#2, D0
	CMPI.w	#$E, D0
	BLE.b	IntroSwordSprite_Tick_Loop
	MOVE.w	#$E, D0
IntroSwordSprite_Tick_Loop:
	LEA	IntroSwordFrameTable, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList
	RTS

; EndingHScrollSpeedTable
; 11 long-word speed deltas (4 bytes each) added to HScroll_run_table every frame.
; Values increase from $00004000 to $00024000, creating the parallax band gradient.
EndingHScrollSpeedTable:
	dc.b	$00, $00, $40, $00, $00, $00, $60, $00, $00, $00, $80, $00, $00, $00, $A0, $00, $00, $00, $C0, $00, $00, $01, $00, $00, $00, $01, $40, $00, $00, $01, $80, $00 
	dc.b	$00, $01, $A0, $00, $00, $02, $00, $00, $00, $02, $40, $00 
; IntroSwordFrameTable
; 8 entries × 2 bytes: high byte = tile page offset, low byte = tile index within page.
; Sequence: frames 483→484→485→486→485→486→484, then end ($0000).
IntroSwordFrameTable:
	dc.b	$04, $83, $04, $84, $04, $85, $04, $86, $04, $85, $04, $86, $04, $84, $00, $00 
; === Menu Cursor Sprites ===

; SpawnMenuCursorSprites
; Activates two adjacent enemy slots as left/right menu cursor sprites.
; Left cursor: position (240, 100), tile VRAM_TILE_MENU_CURSOR_L, size 1×4.
; Right cursor: position (272, 100), tile VRAM_TILE_MENU_CURSOR_R, size 1×4.
; Both use MenuCursorSprite_Tick.
SpawnMenuCursorSprites:
	MOVEA.l	Enemy_list_ptr.w, A6
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BSET.b	#7, (A6)
	BSET.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BSET.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	CLR.b	obj_move_counter(A6)
	MOVE.w	#$00F0, obj_screen_x(A6)
	MOVE.w	#$0064, obj_screen_y(A6)
	CLR.w	obj_sort_key(A6)
	MOVE.w	#VRAM_TILE_MENU_CURSOR_L, obj_tile_index(A6)
	MOVE.b	#SPRITE_SIZE_1x4, obj_sprite_size(A6)
	MOVE.l	#MenuCursorSprite_Tick, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BSET.b	#7, (A6)
	BSET.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BSET.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	CLR.b	obj_move_counter(A6)
	MOVE.w	#$0110, obj_screen_x(A6)
	MOVE.w	#$0064, obj_screen_y(A6)
	CLR.w	obj_sort_key(A6)
	MOVE.w	#VRAM_TILE_MENU_CURSOR_R, obj_tile_index(A6)
	MOVE.b	#SPRITE_SIZE_1x4, obj_sprite_size(A6)
	MOVE.l	#MenuCursorSprite_Tick, obj_tick_fn(A6)
	RTS

; MenuCursorSprite_Tick
; Simply re-submits the cursor sprite to the display list each frame.
MenuCursorSprite_Tick:
	JSR	AddSpriteToDisplayList
	RTS

; DrawPressStartText
; Rewrites the "Press Start" tile area in VRAM using SpriteTileIndexTable_619EA,
; 14 rows × 10 tiles. Interrupts disabled during the write.
DrawPressStartText:
	ORI	#$0700, SR
	MOVE.l	#$69800003, D4
	MOVE.l	#$60AA0003, D5
	LEA	SpriteTileIndexTable_619EA, A0
	MOVE.w	#$D, D7
DrawPressStartText_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#9, D6
DrawPressStartText_Done2:
	CLR.w	D0
	MOVE.b	(A0), D0
	ADDI.w	#$0239, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawPressStartText_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, DrawPressStartText_Done
	ANDI	#$F8FF, SR
	RTS

; === Ending Sequence ===
; State machine for the post-boss ending. Tick function is EndingSequence_StepDispatcher
; which jumps through EndingSequenceStepJumpTable using Ending_sequence_step as index.

; EndingSequence_Init
; Sets all palette fade targets to white, clears entities, sets a brief initial delay,
; and installs EndingSequence_StepDispatcher as the tick function.
EndingSequence_Init:
	MOVE.w	#PALETTE_IDX_ALL_WHITE, Palette_line_0_fade_in_target.w
	MOVE.w	#PALETTE_IDX_ALL_WHITE, Palette_line_1_fade_in_target.w
	MOVE.w	#PALETTE_IDX_ALL_WHITE, Palette_line_2_fade_in_target.w
	MOVE.w	#PALETTE_IDX_ALL_WHITE, Palette_line_3_fade_in_target.w
	MOVE.b	#$0F, Palette_fade_in_mask.w
	CLR.w	Ending_sequence_step.w
	JSR	ClearAllEnemyEntities
	MOVEA.l	Player_entity_ptr.w, A6
	BCLR.b	#7, (A6)
	MOVEA.l	Battle_entity_slot_1_ptr.w, A6
	BCLR.b	#7, (A6)
	MOVEA.l	Battle_entity_slot_2_ptr.w, A6
	BCLR.b	#7, (A6)
	MOVE.w	#ENDING_DELAY_BRIEF, Ending_timer.w
	MOVE.l	#EndingSequence_StepDispatcher, obj_tick_fn(A5)
	MOVE.b	#FLAG_TRUE, HScroll_full_update_flag.w
	RTS

; EndingSequence_StepDispatcher
; Dispatches to the handler for the current Ending_sequence_step via jump table.
EndingSequence_StepDispatcher:
	LEA	EndingSequenceStepJumpTable, A0
	MOVE.w	Ending_sequence_step.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	JSR	(A0,D0.w)
	RTS

; EndingSequenceStepJumpTable
; 20 entries (steps 0–19), each a BRA.w (4 bytes). Step index × 4 = table offset.
;   step  0 → EndingSequenceStepJumpTable_Loop  ; wait for fade, play fanfare B, clear scroll
;   step  1 → EndingStep_Return1_Loop           ; wait, play fanfare A, clear planes
;   step  2 → EndingStep_Return1_Loop2          ; wait, draw Outro1, fade in
;   step  3 → EndingStep_Return1_Loop3          ; wait for fade, fade to white
;   step  4 → EndingStep_Return2_Loop           ; draw border+Outro2, fade in
;   step  5 → EndingStep_Return2_Loop2          ; wait, fade out
;   step  6 → EndingStep_Return3_Loop           ; wait for fade, init credits screen
;   step  7 → EndingStep_Return3_Loop2          ; wait, scroll fire, draw Outro3
;   step  8 → EndingSequenceStep_Done_Loop      ; wait, fade to black
;   step  9 → EndingStep_Return4_Loop           ; draw Outro4, fade in
;   step 10 → EndingStep_Return4_Loop2          ; wait
;   step 11 → EndingStep_Return5_Loop           ; draw Outro5, fade in
;   step 12 → EndingStep_Return5_Loop2          ; wait
;   step 13 → EndingStep_Return6_Loop           ; fill pattern
;   step 14 → EndingStep_Return6_Loop2          ; scroll up, advance
;   step 15 → EndingStep_Return7_Loop           ; wait, init font tiles
;   step 16 → EndingStep_Return7_Loop2          ; scroll credits text (pad=A)
;   step 17 → EndingSequence_ScrollText_Done_Loop   ; display credit lines
;   step 18 → EndingSequence_ScrollText_Done_Loop2  ; wait for end of credits
;   step 19 → EndingSequence_CommonUpdate       ; loop idle
EndingSequenceStepJumpTable:
	BRA.w	EndingSequenceStepJumpTable_Loop
	BRA.w	EndingStep_Return1_Loop
	BRA.w	EndingStep_Return1_Loop2
	BRA.w	EndingStep_Return1_Loop3
	BRA.w	EndingStep_Return2_Loop
	BRA.w	EndingStep_Return2_Loop2
	BRA.w	EndingStep_Return3_Loop
	BRA.w	EndingStep_Return3_Loop2
	BRA.w	EndingSequenceStep_Done_Loop
	BRA.w	EndingStep_Return4_Loop
	BRA.w	EndingStep_Return4_Loop2
	BRA.w	EndingStep_Return5_Loop
	BRA.w	EndingStep_Return5_Loop2
	BRA.w	EndingStep_Return6_Loop
	BRA.w	EndingStep_Return6_Loop2
	BRA.w	EndingStep_Return7_Loop
	BRA.w	EndingStep_Return7_Loop2
	BRA.w	EndingSequence_ScrollText_Done_Loop
	BRA.w	EndingSequence_ScrollText_Done_Loop2
	BRA.w	EndingSequence_CommonUpdate
EndingSequenceStepJumpTable_Loop:
	TST.b	Palette_fade_in_mask.w
	BNE.b	EndingStep_Return1
	SUBQ.w	#1, Ending_timer.w
	BGT.b	EndingStep_Return1
	JSR	ClearScrollData
	PlaySound	SOUND_ENDING_FANFARE_B
	MOVE.w	#ENDING_DELAY_NORMAL, Ending_timer.w
	ADDQ.w	#1, Ending_sequence_step.w
EndingStep_Return1:
	RTS

EndingStep_Return1_Loop:
	SUBQ.w	#1, Ending_timer.w
	BGT.b	EndingStep_Return1_Loop4
	PlaySound	SOUND_ENDING_FANFARE_A
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	MOVE.w	#ENDING_DELAY_NORMAL, Ending_timer.w
	ADDQ.w	#1, Ending_sequence_step.w
EndingStep_Return1_Loop4:
	RTS

EndingStep_Return1_Loop2:
	SUBQ.w	#1, Ending_timer.w
	BGT.b	EndingStep_Return1_Loop5
	MOVE.w	#PALETTE_IDX_ENDING_TEXT_BG, Palette_line_0_fade_in_target.w
	MOVE.l	#$67140003, D5
	LEA	Outro1Str, A0
	MOVE.w	#$84C0, D4
	JSR	DrawVerticalText
	MOVE.b	#1, Palette_fade_in_mask.w
	ADDQ.w	#1, Ending_sequence_step.w
	MOVE.w	#ENDING_DELAY_NORMAL, Ending_timer.w
EndingStep_Return1_Loop5:
	RTS

EndingStep_Return1_Loop3:
	TST.b	Palette_fade_in_mask.w
	BNE.b	EndingStep_Return2
	SUBQ.w	#1, Ending_timer.w
	BGT.b	EndingStep_Return2
	MOVE.w	#PALETTE_IDX_ALL_WHITE, Palette_line_0_fade_in_target.w
	MOVE.b	#1, Palette_fade_in_mask.w
	ADDQ.w	#1, Ending_sequence_step.w
EndingStep_Return2:
	RTS

EndingStep_Return2_Loop:
	TST.b	Palette_fade_in_mask.w
	BNE.b	EndingStep_Return2_Loop3
	BSR.w	DrawEndingBorderPattern
	MOVE.w	#PALETTE_IDX_ENDING_TEXT_BG, Palette_line_0_fade_in_target.w
	MOVE.l	#$67140003, D5
	LEA	Outro2Str, A0
	MOVE.w	#$84C0, D4
	JSR	DrawVerticalText
	MOVE.b	#1, Palette_fade_in_mask.w
	ADDQ.w	#1, Ending_sequence_step.w
	MOVE.w	#ENDING_DELAY_LONG, Ending_timer.w
EndingStep_Return2_Loop3:
	RTS

EndingStep_Return2_Loop2:
	TST.b	Palette_fade_in_mask.w
	BNE.b	EndingStep_Return3
	SUBQ.w	#1, Ending_timer.w
	BGT.b	EndingStep_Return3
	MOVE.w	#PALETTE_IDX_ALL_WHITE, Palette_line_0_fade_in_target.w
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	ADDQ.w	#1, Ending_sequence_step.w
EndingStep_Return3:
	RTS

EndingStep_Return3_Loop:
	TST.b	Fade_out_lines_mask.w
	BNE.b	EndingStep_Return3_Loop3
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	MOVE.w	VDP_Reg11_cache.w, D0
	ORI.w	#3, D0
	MOVE.w	D0, VDP_control_port
	JSR	LoadMenuTileGraphics
	BSR.w	InitEndingCreditsScreen
	BSR.w	DrawCreditsStaffNames
	MOVE.b	#6, Fade_in_lines_mask.w
	MOVE.w	#PALETTE_IDX_ALL_BLACK, Palette_line_0_index.w
	MOVE.w	#$0092, Palette_line_1_fade_target.w
	MOVE.w	#PALETTE_IDX_TITLE_BG, Palette_line_2_fade_target.w
	MOVE.w	#PALETTE_IDX_ENDING_CURSOR_MIN, Palette_line_3_index.w
	ADDQ.w	#1, Ending_sequence_step.w
	PlaySound	SOUND_ENDING_STAFF_MUSIC
	MOVE.w	#ENDING_DELAY_NORMAL, Ending_timer.w
	JSR	LoadPalettesFromTable
EndingStep_Return3_Loop3:
	RTS

EndingStep_Return3_Loop2:
	TST.b	Fade_in_lines_mask.w
	BNE.b	EndingSequenceStep_Done
	SUBQ.w	#1, Ending_timer.w
	BGT.b	EndingSequenceStep_Done
	CMPI.w	#$FFCE, Ending_hscroll_offset.w
	BGT.b	EndingStep_Return3_Loop4
	MOVE.l	#$413C0003, D5
	LEA	Outro3Str, A0
	MOVE.w	#$84C0, D4
	JSR	DrawVerticalText
	MOVE.w	#PALETTE_IDX_ENDING_FIRE, Palette_line_0_fade_in_target.w
	MOVE.b	#1, Palette_fade_in_mask.w
	MOVE.w	#ENDING_DELAY_LONG, Ending_timer.w
	ADDQ.w	#1, Ending_sequence_step.w
	BRA.b	EndingSequenceStep_Done
EndingStep_Return3_Loop4:
	SUBQ.w	#1, Ending_hscroll_offset.w
EndingSequenceStep_Done:
	BRA.w	EndingSequence_CommonUpdate
EndingSequenceStep_Done_Loop:
	TST.b	Palette_fade_in_mask.w
	BNE.b	EndingStep_Return4
	SUBQ.w	#1, Ending_timer.w
	BGT.b	EndingStep_Return4
	ADDQ.w	#1, Ending_sequence_step.w
	MOVE.w	#PALETTE_IDX_ALL_BLACK, Palette_line_0_fade_in_target.w
	MOVE.b	#1, Palette_fade_in_mask.w
EndingStep_Return4:
	BRA.w	EndingSequence_CommonUpdate
EndingStep_Return4_Loop:
	TST.b	Palette_fade_in_mask.w
	BNE.b	EndingStep_Return4_Loop3
	BSR.w	FillDialogAreaWithPattern
	MOVE.l	#$413C0003, D5
	LEA	Outro4Str, A0
	MOVE.w	#$84C0, D4
	JSR	DrawVerticalText
	MOVE.w	#PALETTE_IDX_ENDING_FIRE, Palette_line_0_fade_in_target.w
	MOVE.b	#1, Palette_fade_in_mask.w
	ADDQ.w	#1, Ending_sequence_step.w
	MOVE.w	#ENDING_DELAY_LONGER, Ending_timer.w
EndingStep_Return4_Loop3:
	BRA.w	EndingSequence_CommonUpdate
EndingStep_Return4_Loop2:
	TST.b	Palette_fade_in_mask.w
	BNE.b	EndingStep_Return5
	SUBQ.w	#1, Ending_timer.w
	BGT.b	EndingStep_Return5
	ADDQ.w	#1, Ending_sequence_step.w
	MOVE.w	#PALETTE_IDX_ALL_BLACK, Palette_line_0_fade_in_target.w
	MOVE.b	#1, Palette_fade_in_mask.w
EndingStep_Return5:
	BRA.w	EndingSequence_CommonUpdate
EndingStep_Return5_Loop:
	TST.b	Palette_fade_in_mask.w
	BNE.b	EndingStep_Return5_Loop3
	BSR.w	FillDialogAreaWithPattern
	MOVE.l	#$413C0003, D5
	LEA	Outro5Str, A0
	MOVE.w	#$84C0, D4
	JSR	DrawVerticalText
	MOVE.w	#PALETTE_IDX_ENDING_FIRE, Palette_line_0_fade_in_target.w
	MOVE.b	#1, Palette_fade_in_mask.w
	ADDQ.w	#1, Ending_sequence_step.w
	MOVE.w	#ENDING_DELAY_LONGER, Ending_timer.w
EndingStep_Return5_Loop3:
	BRA.w	EndingSequence_CommonUpdate
EndingStep_Return5_Loop2:
	TST.b	Palette_fade_in_mask.w
	BNE.b	EndingStep_Return6
	SUBQ.w	#1, Ending_timer.w
	BGT.b	EndingStep_Return6
	ADDQ.w	#1, Ending_sequence_step.w
	MOVE.w	#PALETTE_IDX_ALL_BLACK, Palette_line_0_fade_in_target.w
	MOVE.b	#1, Palette_fade_in_mask.w
EndingStep_Return6:
	BRA.w	EndingSequence_CommonUpdate
EndingStep_Return6_Loop:
	TST.b	Palette_fade_in_mask.w
	BNE.b	EndingStep_Return6_Loop3
	BSR.w	FillDialogAreaWithPattern
	MOVE.w	#ENDING_DELAY_NORMAL, Ending_timer.w
	ADDQ.w	#1, Ending_sequence_step.w
EndingStep_Return6_Loop3:
	BRA.w	EndingSequence_CommonUpdate
EndingStep_Return6_Loop2:
	SUBQ.w	#1, Ending_timer.w
	BGT.b	EndingStep_Return7
	TST.w	Ending_hscroll_offset.w
	BLT.b	EndingStep_Return6_Loop4
	ADDQ.w	#1, Ending_sequence_step.w
	CLR.w	Dialog_timer.w
	CLR.w	Dialog_phase.w
	MOVE.w	#ENDING_DELAY_SCROLL, Ending_timer.w
	BRA.b	EndingStep_Return7
EndingStep_Return6_Loop4:
	ADDQ.w	#1, Ending_hscroll_offset.w
EndingStep_Return7:
	BRA.w	EndingSequence_CommonUpdate
EndingStep_Return7_Loop:
	SUBQ.w	#1, Ending_timer.w
	BGT.b	EndingStep_Return7_Loop3
	PlaySound	SOUND_LEVEL_UP
	ADDQ.w	#1, Ending_sequence_step.w
	JSR	InitFontTiles
EndingStep_Return7_Loop3:
	BRA.w	EndingSequence_CommonUpdate
EndingStep_Return7_Loop2:
	ADDQ.w	#1, Dialog_timer.w
	MOVE.w	Dialog_timer.w, D0
	BTST.b	#6, IO_version
	BNE.w	EndingStep_Return7_Loop4
	ANDI.w	#7, D0
	BNE.b	EndingSequence_ScrollText_Done
	BRA.b	EndingStep_Return7_Loop5
EndingStep_Return7_Loop4:
	ANDI.w	#3, D0	
	BNE.b	EndingSequence_ScrollText_Done	
EndingStep_Return7_Loop5:
	CMPI.w	#BOSS_VICTORY_FADE_PHASES, Dialog_phase.w
	BLT.b	EndingStep_Return7_Loop6
	ADDQ.w	#1, Ending_sequence_step.w
	CLR.w	Ending_timer.w
	CLR.l	Ending_vscroll_accumulator.w
	MOVE.b	#FLAG_TRUE, Boss_max_hp.w
	PlaySound	SOUND_ENDING_CREDITS_MUSIC
	MOVE.w	#PALETTE_IDX_TOWN_TILES, Palette_line_0_index.w
	MOVE.w	#$0093, Palette_line_1_index.w
	JSR	LoadPalettesFromTable
	LEA	Ending_player_name_buffer.w, A0
	MOVE.w	#5, D7
EndingStep_Return7_Loop5_Done:
	MOVE.b	#$20, (A0)+
	DBF	D7, EndingStep_Return7_Loop5_Done
	BRA.w	EndingSequence_ScrollText_Done
EndingStep_Return7_Loop6:
	BSR.w	ClearDialogSprites
EndingSequence_ScrollText_Done:
	BRA.w	EndingSequence_CommonUpdate
EndingSequence_ScrollText_Done_Loop:
	MOVE.l	Ending_timer.w, D0
	MOVE.l	D0, D1
	ANDI.w	#$001F, D1
	BNE.b	EndingSequence_ScrollText_Done_Loop3
	ASR.l	#5, D0
	BSR.w	DisplayEndingTextLine
EndingSequence_ScrollText_Done_Loop3:
	ADDQ.l	#1, Ending_timer.w
	ADDI.l	#$4000, Ending_vscroll_accumulator.w
	MOVE.w	Ending_vscroll_accumulator.w, VScroll_base.w
	BRA.w	EndingSequence_CommonUpdate
EndingSequence_ScrollText_Done_Loop2:
	MOVE.w	Ending_timer.w, D0
	CMPI.w	#$0200, D0
	BLE.b	EndingSequence_ScrollText_Done_Loop4
	ADDQ.w	#1, Ending_sequence_step.w
EndingSequence_ScrollText_Done_Loop4:
	ADDQ.w	#1, Ending_timer.w
	ADDI.l	#$4000, Ending_vscroll_accumulator.w
	MOVE.w	Ending_vscroll_accumulator.w, VScroll_base.w
	BRA.w	EndingSequence_CommonUpdate
; EndingSequence_CommonUpdate
; Per-frame common update called by most ending steps: blinks cursor, updates HScroll.
EndingSequence_CommonUpdate:
	BSR.w	UpdateEndingCursorBlink
	JSR	UpdateEndingHScrollValues
	RTS

; === Credits Text Display ===

; DisplayEndingTextLine
; Clears one credits row in VRAM (40 words of tile $04E0) then writes the text for
; line D0 from CreditsTextPtrTable. VDP address is computed from D0 × $80 within
; the credits VRAM region. Falls through to DrawEndingCreditsText_Next.
DisplayEndingTextLine:
	LEA	CreditsTextPtrTable, A0
	MOVEQ	#0, D1
	MOVE.w	D0, D1
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	MOVE.l	#$4E100003, D5
	MULU.w	#$0080, D1
	SWAP	D1
	ADD.l	D1, D5
	ANDI.l	#$5FFF0003, D5
	ORI.l	#$40000003, D5
	ORI	#$0700, SR
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$04E0, D0
	MOVE.w	#$0027, D7
DisplayEndingTextLine_Done:
	MOVE.w	D0, VDP_data_port
	DBF	D7, DisplayEndingTextLine_Done
	ANDI	#$F8FF, SR
	ORI	#$0700, SR
; DrawEndingCreditsText_Next
; Writes one credits text string character by character to VRAM.
; SCRIPT_WIDE_CHAR_LO / SCRIPT_WIDE_CHAR_HI → write a wide-char tile then newline.
; SCRIPT_NEWLINE → advance Ending_sequence_step and clear the text area.
; SCRIPT_END / $00  → return.
; Each normal character adds $04C0 to get its tile index. D5 holds the VDP address
; (incremented by $00020000 per character; $00820000 for wide-char line offset).
DrawEndingCreditsText_Next:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	BEQ.b	DrawEndingCreditsText_Return
	CMPI.b	#SCRIPT_WIDE_CHAR_LO, D0
	BEQ.b	DrawEndingCreditsText_NewLine
	CMPI.b	#SCRIPT_WIDE_CHAR_HI, D0
	BEQ.b	DrawEndingCreditsText_NewLine
	CMPI.b	#SCRIPT_END, D0
	BEQ.b	DrawEndingCreditsText_Return
	CMPI.b	#SCRIPT_NEWLINE, D0
	BEQ.b	DrawEndingCreditsText_NewLine_Loop
	ADDI.w	#$04C0, D0
	MOVE.l	D5, VDP_control_port
	MOVE.w	D0, VDP_data_port
	ADDI.l	#$00020000, D5
	BRA.b	DrawEndingCreditsText_Next
DrawEndingCreditsText_NewLine:
	SUBI.l	#$00820000, D5	
	ADDI.w	#$04C0, D0	
	MOVE.l	D5, VDP_control_port	
	MOVE.w	D0, VDP_data_port	
	ADDI.l	#$00820000, D5	
	BRA.b	DrawEndingCreditsText_Next	
DrawEndingCreditsText_NewLine_Loop:
	ADDQ.w	#1, Ending_sequence_step.w
	CLR.w	Ending_timer.w
	BSR.w	ClearEndingTextArea
DrawEndingCreditsText_Return:
