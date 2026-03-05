; ======================================================================
; src/dungeon.asm
; First-person dungeon view, map decompression, compass, sectors
; ======================================================================
DecrementInaudiosSteps_Done:
	RTS

HandleMapTileTransition:
	CMPI.b	#$FF, D0
	BEQ.w	HandleMapTileTransition_Loop
	CMPI.b	#OVERWORLD_TILE_CAVE_MIN, D0
	BGE.b	HandleMapTileTransition_EnterCave
	CMPI.b	#OVERWORLD_TILE_UPPER_CAVE_MIN, D0
	BLT.w	HandleMapTileTransition_EnterTown
	TST.b	D0
	BLT.b	HandleMapTileTransition_ClearHighBitAndEnterCave
	RTS

HandleMapTileTransition_ClearHighBitAndEnterCave:
	BCLR.l	#7, D0
HandleMapTileTransition_EnterCave: ; Enter cave
	SUBI.b	#$10, D0
	ANDI.w	#$007F, D0
	MOVE.w	D0, Current_cave_room.w
	MOVE.b	#FLAG_TRUE, Is_in_cave.w
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	TST.b	Cave_position_saved.w
	BNE.b	HandleMapTileTransition_SaveCavePosition
	MOVE.w	Player_position_x_outside_town.w, Player_cave_position_x.w
	MOVE.w	Player_position_y_outside_town.w, Player_cave_position_y.w
	MOVE.w	Player_map_sector_x.w, Player_cave_map_sector_x.w
	MOVE.w	Player_map_sector_y.w, Player_cave_map_sector_y.w
	MOVE.b	#FLAG_TRUE, Cave_position_saved.w
HandleMapTileTransition_SaveCavePosition:
	MOVE.w	#GAMEPLAY_STATE_ENTERING_CAVE, Gameplay_state.w
	PlaySound_b	SOUND_TRANSITION
	RTS

HandleMapTileTransition_EnterTown:
	ANDI.w	#$000F, D0
	MOVE.w	D0, Current_town.w
	MOVE.w	#GAMEPLAY_STATE_TOWN_FADE_IN_COMPLETE, Gameplay_state.w
	CLR.b	Cave_position_saved.w
	PlaySound_b	SOUND_TRANSITION
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	RTS

HandleMapTileTransition_Loop:
	PlaySound_b	SOUND_TRANSITION
	CLR.b	Cave_position_saved.w
	MOVE.w	#GAMEPLAY_STATE_CAVE_FADE_OUT_COMPLETE, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	RTS

RefreshFirstPersonView:
	CLR.b	Player_move_forward_in_overworld.w
	BSR.w	UpdateFirstPersonWallData
	MOVE.w	#0, First_person_wall_frame.w
	MOVE.w	#WALL_TILE_Y_OFFSET, Wall_render_y_offset.w
	BSR.w	DrawFirstPersonWalls
	BSR.w	ResetObjectOffscreenPositions
	RTS

RotateClockwiseJumpTable:
	BRA.w	RotateCounterClockwiseJumpTable_Loop
	BRA.w	RotateCounterClockwiseJumpTable_RotateCW_East
	BRA.w	RotateCounterClockwiseJumpTable_RotateCW_South
	BRA.w	RenderWallTile_NearTwoPalette_Loop
RotateCounterClockwiseJumpTable:
	BRA.w	RotateCounterClockwiseJumpTable_RotateCCW_South
	BRA.w	RotateCounterClockwiseJumpTable_RotateCCW_East
	BRA.w	RotateCounterClockwiseJumpTable_RotateCCW_West
	BRA.w	RenderWallTile_NearTwoPalette_RotateCW
RotateCounterClockwiseJumpTable_RotateCCW_West:
	LEA	RotateCCW_WestJumpTable, A0
	BRA.w	RotateCounterClockwiseJumpTable_Init21x13_And_Render
RotateCounterClockwiseJumpTable_Loop:
	LEA	RotateCW_NorthJumpTable, A0
RotateCounterClockwiseJumpTable_Init21x13_And_Render:
	BSR.w	InitObjectPositions_21x13
	LEA	Map_sector_center.w, A2
	BSR.w	UpdatePlayerMapSector
	BSR.w	RenderMapToVRAM_DualPalette_21x13
	TST.b	Is_in_cave.w
	BNE.b	RotateCounterClockwiseJumpTable_DisplayCaveStats_21x13
	BRA.w	DrawCompassTiles
RotateCounterClockwiseJumpTable_DisplayCaveStats_21x13:
	BRA.w	DisplayStatsToVRAM_SinglePalette
RotateCounterClockwiseJumpTable_RotateCCW_East:
	LEA	RotateCCW_EastJumpTable, A0
	BRA.w	RotateCounterClockwiseJumpTable_Init21x20_And_Render
RotateCounterClockwiseJumpTable_RotateCW_East:
	LEA	RotateCW_EastJumpTable, A0
RotateCounterClockwiseJumpTable_Init21x20_And_Render:
	BSR.w	InitObjectPositions_21x20
	BSR.w	UpdatePlayerMapSector
	BSR.w	RenderMapToVRAM_DualPalette_21x20
	TST.b	Is_in_cave.w
	BNE.b	RotateCounterClockwiseJumpTable_DisplayCaveStats_21x20
	BRA.w	DrawCompassTiles
RotateCounterClockwiseJumpTable_DisplayCaveStats_21x20:
	BRA.w	DisplayStatsToVRAM
RotateCounterClockwiseJumpTable_RotateCCW_South:
	LEA	RotateCCW_SouthJumpTable, A0
	BRA.w	RotateCounterClockwiseJumpTable_Init21x13Alt_And_Render
RotateCounterClockwiseJumpTable_RotateCW_South:
	LEA	RotateCW_SouthJumpTable, A0
RotateCounterClockwiseJumpTable_Init21x13Alt_And_Render:
	BSR.w	InitObjectPositions_21x13Alt
	BSR.w	UpdatePlayerMapSector
	BSR.w	RenderMapToVRAM_DualPalette_21x13_Alt
	TST.b	Is_in_cave.w
	BNE.b	RotateCounterClockwiseJumpTable_DisplayCaveStats_21x13Alt
	BRA.w	DrawCompassTiles
RotateCounterClockwiseJumpTable_DisplayCaveStats_21x13Alt:
	BRA.w	DisplayStatsToVRAM_AltPalette
UpdatePlayerMapSector:
	LEA	Map_sector_center.w, A2
	MOVE.w	Player_position_x_outside_town.w, D0
	MOVE.w	Player_position_y_outside_town.w, D1
	MOVE.w	Player_direction.w, D4
	ANDI.w	#6, D4
	ADD.w	D4, D4
	JSR	(A0,D4.w)
	RTS

RotateCW_NorthJumpTable:
	BRA.w	RenderFpWall_UpLeft
	BRA.w	RenderFpWall_DownRight
	BRA.w	RenderFpWall_DownLeft
	BRA.w	RenderFpWall_UpRight
RotateCW_EastJumpTable:
	BRA.w	RenderFpWall_LeftUp
	BRA.w	RenderFpWall_RightDown
	BRA.w	RenderFpWall_RightUp
	BRA.w	RenderFpWall_LeftDown
RotateCW_SouthJumpTable:
	BRA.w	RenderFpWall_FarLeft
	BRA.w	RenderFpWall_FarDownRight
	BRA.w	RenderFpWall_FarUpLeft
	BRA.w	RenderFpWall_FarRight
RotateCCW_WestJumpTable:
	BRA.w	RenderFpWall_DownRight
	BRA.w	RenderFpWall_DownLeft
	BRA.w	RenderFpWall_UpRight
	BRA.w	RenderFpWall_UpLeft
RotateCCW_EastJumpTable:
	BRA.w	RenderFpWall_RightDown
	BRA.w	RenderFpWall_RightUp
	BRA.w	RenderFpWall_LeftDown
	BRA.w	RenderFpWall_LeftUp
RotateCCW_SouthJumpTable:
	BRA.w	RenderFpWall_FarDownRight
	BRA.w	RenderFpWall_FarUpLeft
	BRA.w	RenderFpWall_FarRight
	BRA.w	RenderFpWall_FarLeft
RenderFpWall_DownRight:
	LEA	WallTileOffsets_DownRight, A4
	BRA.w	RenderFpSector_Near
RenderFpWall_DownLeft:
	LEA	WallTileOffsets_DownLeft, A4
	BRA.w	RenderFpSector_Near
RenderFpWall_UpRight:
	LEA	WallTileOffsets_UpRight, A4
	BRA.w	RenderFpSector_Near
RenderFpWall_UpLeft:
	LEA	WallTileOffsets_UpLeft, A4
	BRA.w	RenderFpSector_Near
RenderFpWall_RightDown:
	LEA	WallTileOffsets_RightDown, A4
	BRA.w	RenderFpSector_Far
RenderFpWall_RightUp:
	LEA	WallTileOffsets_RightUp, A4
	BRA.w	RenderFpSector_Far
RenderFpWall_LeftDown:
	LEA	WallTileOffsets_LeftDown, A4
	BRA.w	RenderFpSector_Far
RenderFpWall_LeftUp:
	LEA	WallTileOffsets_LeftUp, A4
	BRA.w	RenderFpSector_Far
RenderFpWall_FarDownRight:
	LEA	WallTileOffsets_FarDownRight, A4
	BRA.w	RenderFpSector_Mid
RenderFpWall_FarUpLeft:
	LEA	WallTileOffsets_FarUpLeft, A4
	BRA.w	RenderFpSector_Mid
RenderFpWall_FarRight:
	LEA	WallTileOffsets_FarRight, A4
	BRA.w	RenderFpSector_Mid
RenderFpWall_FarLeft:
	LEA	WallTileOffsets_FarLeft, A4
	BRA.w	RenderFpSector_Mid
RenderWallTileWithPalette:
	MOVE.w	D4, D3
	ADD.w	D3, D3
	ASL.w	#4, D4
	LEA	WallTileMidGfxPtrs, A1
	LEA	FpSpritePositionTable, A3
	MOVEA.l	$C(A1,D4.w), A0
	MOVE.w	(A3,D3.w), D4
	MOVE.w	D4, D1
	MOVE.w	D4, D2
	ORI.w	#$A000, D1
	ORI.w	#$A800, D2
	BRA.w	RenderWallTile_14x10_TwoPalette
RenderWallTile_NearFrontTwoPalette:
	LEA	WallTileGfxPtrs, A1
	LEA	FpSpritePositionTable, A3
	MOVE.w	D4, D3
	ADD.w	D3, D3
	ASL.w	#4, D4
	MOVEA.l	(A1,D4.w), A0
	MOVE.w	(A3,D3.w), D4
	MOVE.w	D4, D1
	MOVE.w	D4, D2
	ORI.w	#$A000, D1
	ORI.w	#$A800, D2
	BSR.w	RenderWallTile_16x11_TwoPalette
	RTS

RenderWallTile_MidSinglePalette:
	LEA	WallTileGfxPtrs, A1
	LEA	FpSpritePositionTable, A3
	MOVE.w	D4, D3
	ADD.w	D3, D3
	ASL.w	#4, D4
	MOVEA.l	$4(A1,D4.w), A0
	MOVE.w	(A3,D3.w), D4
	MOVE.w	D4, D1
	ORI.w	#$A800, D1
	BSR.w	RenderWallTile_16x5_Palette1
	RTS

RenderWallTile_FarSinglePalette:
	LEA	WallTileGfxPtrs, A1
	LEA	FpSpritePositionTable, A3
	MOVE.w	D4, D3
	ADD.w	D3, D3
	ASL.w	#4, D4
	MOVEA.l	$8(A1,D4.w), A0
	MOVE.w	(A3,D3.w), D4
	MOVE.w	D4, D1
	ORI.w	#$A000, D1
	BSR.w	RenderWallTile_16x5_Palette0
	RTS

RenderWallTile_NearTwoPalette:
	LEA	WallTileGfxPtrs, A1
	LEA	FpSpritePositionTable, A3
	MOVE.w	D4, D3
	ADD.w	D3, D3
	ASL.w	#4, D4
	MOVEA.l	(A1,D4.w), A0
	MOVE.w	(A3,D3.w), D4
	MOVE.w	D4, D1
	MOVE.w	D4, D2
	ORI.w	#$A000, D1
	ORI.w	#$A800, D2
	BSR.w	RenderWallTile_16x11_TwoPalette
	RTS

RenderWallTile_NearTwoPalette_Loop:
	CLR.b	Player_rotate_clockwise_in_overworld.w
	SUBQ.w	#2, Player_direction.w
	ANDI.w	#7, Player_direction.w
	BSR.w	ClearFirstPersonTilemap
	BSR.w	RefreshFirstPersonView
	BSR.w	DisplayCompassToVRAM
	TST.b	Is_in_cave.w
	BNE.b	RenderWallTile_NearTwoPalette_RotateCCW_DisplayKims
	BSR.w	UpdateCompassDisplay
	BRA.b	RenderWallTile_NearTwoPalette_RotateCCW_UpdateArea
RenderWallTile_NearTwoPalette_RotateCCW_DisplayKims:
	BSR.w	DisplayKimsToVRAM
RenderWallTile_NearTwoPalette_RotateCCW_UpdateArea:
	BSR.w	UpdateAreaVisibility
	BSR.w	DecrementInaudiosSteps
	RTS

RenderWallTile_NearTwoPalette_RotateCW:
	CLR.b	Player_rotate_counter_clockwise_in_overworld.w
	ADDQ.w	#2, Player_direction.w
	ANDI.w	#7, Player_direction.w
	BSR.w	ClearFirstPersonTilemap
	BSR.w	RefreshFirstPersonView
	BSR.w	DisplayCompassToVRAM
	TST.b	Is_in_cave.w
	BNE.b	RenderWallTile_NearTwoPalette_RotateCW_DisplayKims
	BSR.w	UpdateCompassDisplay
	BRA.b	RenderWallTile_NearTwoPalette_RotateCW_UpdateArea
RenderWallTile_NearTwoPalette_RotateCW_DisplayKims:
	BSR.w	DisplayKimsToVRAM
RenderWallTile_NearTwoPalette_RotateCW_UpdateArea:
	BSR.w	UpdateAreaVisibility
	BSR.w	DecrementInaudiosSteps
	RTS

ForwardMovementJumpTable:
	BRA.w	ForwardMovementJumpTable_Loop
	BRA.w	ForwardMovementJumpTable_CheckPoison_Frame8
	BRA.w	ForwardMovementJumpTable_Frame12_CaveWalls
	BRA.w	ForwardMovementJumpTable_Frame16_PaletteCycle
ForwardMovementJumpTable_Loop:
	TST.w	Palette_line_2_index.w
	BEQ.b	ForwardMovementJumpTable_LoadPalette_Frame0
	ADDQ.w	#1, Palette_line_2_index.w
ForwardMovementJumpTable_LoadPalette_Frame0:
	JSR	LoadPalettesFromTable
	LEA	FpDirectionDeltaForward, A0
	BSR.w	UpdateMapSectorPosition
	BSR.w	UpdateFirstPersonWallData
	MOVE.w	#4, First_person_wall_frame.w
	MOVE.w	#0, Wall_render_y_offset.w
	BSR.w	DrawFirstPersonWalls
	BSR.w	UpdateAreaVisibility
	CLR.w	D7
	BRA.w	CaveBossStartPositions_Alt
ForwardMovementJumpTable_CheckPoison_Frame8:
	TST.w	Palette_line_2_index.w
	BEQ.b	ForwardMovementJumpTable_LoadPalette_Frame8
	ADDQ.w	#1, Palette_line_2_index.w
ForwardMovementJumpTable_LoadPalette_Frame8:
	TST.w	Player_poisoned.w
	BEQ.b	ForwardMovementJumpTable_LoadPaletteDone_Frame8
	MOVE.w	#PALETTE_IDX_CAVE_POISON, Palette_line_0_index.w
	MOVE.w	Player_str.w, D0
	ASR.w	#7, D0
	BGT.b	ForwardMovementJumpTable_ClampHpAfterHeal_Frame8
	MOVEQ	#1, D0	
ForwardMovementJumpTable_ClampHpAfterHeal_Frame8:
	SUB.w	D0, Player_hp.w
	JSR	DisplayPlayerHpMp
ForwardMovementJumpTable_LoadPaletteDone_Frame8:
	JSR	LoadPalettesFromTable
	MOVE.w	Equipped_armor.w, D0
	ANDI.w	#$00FF, D0
	CMPI.w	#EQUIPMENT_ARMOR_CRIMSON, D0
	BNE.b	ForwardMovementJumpTable_LoadPaletteDone_Frame12
	ADDQ.w	#5, Player_hp.w	
	MOVE.w	Player_hp.w, D0	
	CMP.w	Player_mhp.w, D0	
	BLE.b	ForwardMovementJumpTable_ClampHpAfterHeal_Frame12	
	MOVE.w	Player_mhp.w, Player_hp.w	
ForwardMovementJumpTable_ClampHpAfterHeal_Frame12:
	JSR	DisplayPlayerHpMp	
ForwardMovementJumpTable_LoadPaletteDone_Frame12:
	MOVE.w	#8, First_person_wall_frame.w
	MOVE.w	#4, Wall_render_y_offset.w
	BSR.w	DrawFirstPersonWalls
	CLR.w	D7
	BRA.w	DungeonTick_ApplyObjectOffsets
ForwardMovementJumpTable_Frame12_CaveWalls:
	TST.w	Palette_line_2_index.w
	BEQ.b	ForwardMovementJumpTable_LoadPalette_Frame12
	ADDQ.w	#1, Palette_line_2_index.w
ForwardMovementJumpTable_LoadPalette_Frame12:
	MOVE.w	#PALETTE_IDX_CAVE_WALLS, Palette_line_0_index.w
	JSR	LoadPalettesFromTable
	MOVE.w	#12, First_person_wall_frame.w
	MOVE.w	#8, Wall_render_y_offset.w
	BSR.w	DrawFirstPersonWalls
	CLR.w	D7
	BSR.w	ApplyAreaDamageToObjects
	CLR.w	D7
	BRA.w	DungeonTick_ApplyObjectOffsets
ForwardMovementJumpTable_Frame16_PaletteCycle:
	TST.w	Palette_line_2_index.w
	BEQ.b	DungeonForwardMove_LoadPaletteDraw
	TST.b	Is_in_cave.w
	BEQ.b	ForwardMovementJumpTable_PaletteCycleWrap_NonCave
	CMPI.w	#PALETTE_IDX_CAVE_ANIM_END, Palette_line_2_index.w
	BNE.b	DungeonForwardMove_PaletteStep
	MOVE.w	#PALETTE_IDX_CAVE_ANIM_BASE, Palette_line_2_index.w
	BRA.b	DungeonForwardMove_LoadPaletteDraw
ForwardMovementJumpTable_PaletteCycleWrap_NonCave:
	CMPI.w	#PALETTE_IDX_CAVE_ANIM_ALT, Palette_line_2_index.w
	BNE.b	DungeonForwardMove_PaletteStep
	MOVE.w	#PALETTE_IDX_CAVE_FLOOR, Palette_line_2_index.w
	BRA.b	DungeonForwardMove_LoadPaletteDraw
DungeonForwardMove_PaletteStep:
	ADDQ.w	#1, Palette_line_2_index.w
DungeonForwardMove_LoadPaletteDraw:
	JSR	LoadPalettesFromTable
	CLR.b	Player_move_forward_in_overworld.w
	MOVE.w	#0, First_person_wall_frame.w
	MOVE.w	#WALL_TILE_Y_OFFSET, Wall_render_y_offset.w
	BSR.w	DrawFirstPersonWalls
	BSR.w	DecrementInaudiosSteps
	BRA.w	ResetObjectOffscreenPositions
BackwardMovementJumpTable:
	BRA.w	BackwardMovementJumpTable_Loop
	BRA.w	DungeonBackwardMove_LoadPaletteDraw_Loop
	BRA.w	DungeonBackwardMove_Frame4_CaveWalls
	BRA.w	DungeonBackwardMove_Frame16_PaletteCycle
BackwardMovementJumpTable_Loop:
	TST.w	Palette_line_2_index.w
	BEQ.b	DungeonBackwardMove_LoadPaletteDraw
	TST.b	Is_in_cave.w
	BEQ.b	BackwardMovementJumpTable_PaletteCycleWrap_NonCave
	CMPI.w	#PALETTE_IDX_CAVE_ANIM_BASE, Palette_line_2_index.w
	BNE.b	DungeonBackwardMove_PaletteStep
	MOVE.w	#PALETTE_IDX_CAVE_ANIM_END, Palette_line_2_index.w
	BRA.b	DungeonBackwardMove_LoadPaletteDraw
BackwardMovementJumpTable_PaletteCycleWrap_NonCave:
	CMPI.w	#PALETTE_IDX_CAVE_FLOOR, Palette_line_2_index.w
	BNE.b	DungeonBackwardMove_PaletteStep
	MOVE.w	#PALETTE_IDX_CAVE_ANIM_ALT, Palette_line_2_index.w
	BRA.b	DungeonBackwardMove_LoadPaletteDraw
DungeonBackwardMove_PaletteStep:
	SUBQ.w	#1, Palette_line_2_index.w
DungeonBackwardMove_LoadPaletteDraw:
	JSR	LoadPalettesFromTable
	MOVE.w	#12, First_person_wall_frame.w
	MOVE.w	#8, Wall_render_y_offset.w
	BSR.w	DrawFirstPersonWalls
	MOVEQ	#1, D7
	BRA.w	DungeonTick_ApplyObjectOffsets
DungeonBackwardMove_LoadPaletteDraw_Loop:
	TST.w	Palette_line_2_index.w
	BEQ.b	DungeonBackwardMove_LoadPalette_Frame12
	SUBQ.w	#1, Palette_line_2_index.w
DungeonBackwardMove_LoadPalette_Frame12:
	TST.w	Player_poisoned.w
	BEQ.b	DungeonBackwardMove_CheckPoison_Frame8
	MOVE.w	#PALETTE_IDX_CAVE_POISON, Palette_line_0_index.w
	MOVE.w	Player_str.w, D0
	ASR.w	#7, D0
	BGT.b	DungeonBackwardMove_ClampHpAfterHeal_Frame8
	MOVEQ	#1, D0	
DungeonBackwardMove_ClampHpAfterHeal_Frame8:
	SUB.w	D0, Player_hp.w
	JSR	DisplayPlayerHpMp
DungeonBackwardMove_CheckPoison_Frame8:
	JSR	LoadPalettesFromTable
	MOVE.w	Equipped_armor.w, D0
	ANDI.w	#$00FF, D0
	CMPI.w	#EQUIPMENT_ARMOR_CRIMSON, D0
	BNE.b	DungeonBackwardMove_LoadPaletteDone_Frame4
	ADDQ.w	#2, Player_hp.w	
	MOVE.w	Player_hp.w, D0	
	CMP.w	Player_mhp.w, D0	
	BLE.b	DungeonBackwardMove_ClampHpAfterHeal_Frame4	
	MOVE.w	Player_mhp.w, Player_hp.w	
DungeonBackwardMove_ClampHpAfterHeal_Frame4:
	JSR	DisplayPlayerHpMp	
DungeonBackwardMove_LoadPaletteDone_Frame4:
	MOVE.w	#8, First_person_wall_frame.w
	MOVE.w	#4, Wall_render_y_offset.w
	BSR.w	DrawFirstPersonWalls
	MOVEQ	#1, D7
	BSR.w	ApplyAreaDamageToObjects
	MOVEQ	#1, D7
	BRA.w	DungeonTick_ApplyObjectOffsets
DungeonBackwardMove_Frame4_CaveWalls:
	TST.w	Palette_line_2_index.w
	BEQ.b	DungeonBackwardMove_LoadPalette_Frame4
	SUBQ.w	#1, Palette_line_2_index.w
DungeonBackwardMove_LoadPalette_Frame4:
	MOVE.w	#PALETTE_IDX_CAVE_WALLS, Palette_line_0_index.w
	JSR	LoadPalettesFromTable
	MOVE.w	#4, First_person_wall_frame.w
	MOVE.w	#0, Wall_render_y_offset.w
	BSR.w	DrawFirstPersonWalls
	MOVEQ	#1, D7
	BRA.w	CaveBossStartPositions_Alt
DungeonBackwardMove_Frame16_PaletteCycle:
	TST.w	Palette_line_2_index.w
	BEQ.b	DungeonBackwardMove_LoadPalette_Frame16
	SUBQ.w	#1, Palette_line_2_index.w
DungeonBackwardMove_LoadPalette_Frame16:
	JSR	LoadPalettesFromTable
	CLR.b	Player_move_backward_in_overworld.w
	LEA	FpDirectionDeltaBackward, A0
	BSR.w	UpdateMapSectorPosition
	BSR.w	UpdateFirstPersonWallData
	MOVE.w	#0, First_person_wall_frame.w
	MOVE.w	#WALL_TILE_Y_OFFSET, Wall_render_y_offset.w
	BSR.w	DrawFirstPersonWalls
	BSR.w	UpdateAreaVisibility
	BSR.w	DecrementInaudiosSteps
	BRA.w	ResetObjectOffscreenPositions
ResetObjectOffscreenPositions:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.l	#$00240000, obj_world_x(A6)
	MOVE.l	#$00800000, obj_world_y(A6)
	MOVEA.l	Object_slot_01_ptr.w, A6
	MOVE.l	#$00940000, obj_world_x(A6)
	MOVE.l	#$00800000, obj_world_y(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.l	#$005C0000, obj_world_x(A6)
	MOVE.l	#$00800000, obj_world_y(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.l	#$FFEC0000, obj_world_x(A6)
	MOVE.l	#$00800000, obj_world_y(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	MOVE.l	#$00CC0000, obj_world_x(A6)
	MOVE.l	#$00800000, obj_world_y(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	MOVE.l	#$003C0000, obj_world_x(A6)
	MOVE.l	#$00680000, obj_world_y(A6)
	MOVEA.l	Object_slot_06_ptr.w, A6
	MOVE.l	#$007C0000, obj_world_x(A6)
	MOVE.l	#$00680000, obj_world_y(A6)
	MOVEA.l	Object_slot_07_ptr.w, A6
	MOVE.l	#$005C0000, obj_world_x(A6)
	MOVE.l	#$00680000, obj_world_y(A6)
	MOVEA.l	Object_slot_08_ptr.w, A6
	MOVE.l	#$001C0000, obj_world_x(A6)
	MOVE.l	#$00680000, obj_world_y(A6)
	MOVEA.l	Object_slot_09_ptr.w, A6
	MOVE.l	#$009C0000, obj_world_x(A6)
	MOVE.l	#$00680000, obj_world_y(A6)
	MOVEA.l	Object_slot_0A_ptr.w, A6
	MOVE.l	#$004C0000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	MOVEA.l	Object_slot_0B_ptr.w, A6
	MOVE.l	#$006C0000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	MOVEA.l	Object_slot_0C_ptr.w, A6
	MOVE.l	#$005C0000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	MOVEA.l	Object_slot_0D_ptr.w, A6
	MOVE.l	#$003C0000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	MOVEA.l	Object_slot_0E_ptr.w, A6
	MOVE.l	#$007C0000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	RTS

CaveBossStartPositions_Alt:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.l	#$00360000, obj_world_x(A6)
	MOVE.l	#$006E0000, obj_world_y(A6)
	MOVEA.l	Object_slot_01_ptr.w, A6
	MOVE.l	#$00820000, obj_world_x(A6)
	MOVE.l	#$006E0000, obj_world_y(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.l	#$005C0000, obj_world_x(A6)
	MOVE.l	#$006E0000, obj_world_y(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.l	#$00220000, obj_world_x(A6)
	MOVE.l	#$006E0000, obj_world_y(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	MOVE.l	#$00960000, obj_world_x(A6)
	MOVE.l	#$006E0000, obj_world_y(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	MOVE.l	#$00480000, obj_world_x(A6)
	MOVE.l	#$005C0000, obj_world_y(A6)
	MOVEA.l	Object_slot_06_ptr.w, A6
	MOVE.l	#$00700000, obj_world_x(A6)
	MOVE.l	#$005C0000, obj_world_y(A6)
	MOVEA.l	Object_slot_07_ptr.w, A6
	MOVE.l	#$005C0000, obj_world_x(A6)
	MOVE.l	#$005C0000, obj_world_y(A6)
	MOVEA.l	Object_slot_08_ptr.w, A6
	MOVE.l	#$00340000, obj_world_x(A6)
	MOVE.l	#$005C0000, obj_world_y(A6)
	MOVEA.l	Object_slot_09_ptr.w, A6
	MOVE.l	#$00840000, obj_world_x(A6)
	MOVE.l	#$005C0000, obj_world_y(A6)
	MOVEA.l	Object_slot_0A_ptr.w, A6
	MOVE.l	#$00520000, obj_world_x(A6)
	MOVE.l	#$00520000, obj_world_y(A6)
	MOVEA.l	Object_slot_0B_ptr.w, A6
	MOVE.l	#$00660000, obj_world_x(A6)
	MOVE.l	#$00520000, obj_world_y(A6)
	MOVEA.l	Object_slot_0C_ptr.w, A6
	MOVE.l	#$005C0000, obj_world_x(A6)
	MOVE.l	#$00520000, obj_world_y(A6)
	MOVEA.l	Object_slot_0D_ptr.w, A6
	MOVE.l	#$00480000, obj_world_x(A6)
	MOVE.l	#$00520000, obj_world_y(A6)
	MOVEA.l	Object_slot_0E_ptr.w, A6
	MOVE.l	#$00700000, obj_world_x(A6)
	MOVE.l	#$00520000, obj_world_y(A6)
	TST.w	D7
	BNE.b	CaveBossStartPositions_Alt_Loop
	MOVEQ	#1, D7
	BSR.w	ApplyAreaDamageToObjects
CaveBossStartPositions_Alt_Loop:
	RTS

ApplyAreaDamageToObjects:
	TST.w	D7
	BEQ.b	ApplyAreaDamageToObjects_Loop
	MOVE.w	#$FFDC, D2
	MOVE.w	#$FFE8, D3
	MOVE.w	#$FFFA, D4
	BRA.b	ApplyAreaDamageToObjects_Apply
ApplyAreaDamageToObjects_Loop:
	MOVE.w	#$0024, D2
	MOVE.w	#$0018, D3
	MOVE.w	#6, D4
ApplyAreaDamageToObjects_Apply:
	MOVEA.l	Enemy_list_ptr.w, A6
	BSR.w	ApplyDamageToObjectIfAlive
	MOVEA.l	Object_slot_01_ptr.w, A6
	BSR.w	ApplyDamageToObjectIfAlive
	MOVEA.l	Object_slot_02_ptr.w, A6
	BSR.w	ApplyDamageToObjectIfAlive
	MOVEA.l	Object_slot_03_ptr.w, A6
	BSR.w	ApplyDamageToObjectIfAlive
	MOVEA.l	Object_slot_04_ptr.w, A6
	BSR.w	ApplyDamageToObjectIfAlive
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVEA.l	Object_slot_05_ptr.w, A6
	BSR.w	ApplyDamageToObjectIfAlive_D3
	MOVEA.l	Object_slot_06_ptr.w, A6
	BSR.w	ApplyDamageToObjectIfAlive_D3
	MOVEA.l	Object_slot_07_ptr.w, A6
	BSR.w	ApplyDamageToObjectIfAlive_D3
	MOVEA.l	Object_slot_08_ptr.w, A6
	BSR.w	ApplyDamageToObjectIfAlive_D3
	MOVEA.l	Object_slot_09_ptr.w, A6
	BSR.w	ApplyDamageToObjectIfAlive_D3
	MOVEA.l	Object_slot_0A_ptr.w, A6
	BSR.w	AddValueToObjectSlot_D4
	MOVEA.l	Object_slot_0B_ptr.w, A6
	BSR.w	AddValueToObjectSlot_D4
	MOVEA.l	Object_slot_0C_ptr.w, A6
	BSR.w	AddValueToObjectSlot_D4
	MOVEA.l	Object_slot_0D_ptr.w, A6
	BSR.w	AddValueToObjectSlot_D4
	MOVEA.l	Object_slot_0E_ptr.w, A6
	BSR.w	AddValueToObjectSlot_D4
	RTS

ApplyDamageToObjectIfAlive:
	TST.w	obj_tile_index(A6)
	BLE.b	ApplyDamageToObjectIfAlive_Loop
	ADD.w	D2, obj_tile_index(A6)
ApplyDamageToObjectIfAlive_Loop:
	RTS

ApplyDamageToObjectIfAlive_D3:
	TST.w	obj_tile_index(A6)
	BLE.b	ApplyDamageToObjectIfAlive_D3_Loop
	ADD.w	D3, obj_tile_index(A6)
ApplyDamageToObjectIfAlive_D3_Loop:
	RTS

AddValueToObjectSlot_D4:
	TST.w	obj_tile_index(A6)
	BLE.b	AddValueToObjectSlot_D4_Loop
	ADD.w	D4, obj_tile_index(A6)
AddValueToObjectSlot_D4_Loop:
	RTS

DungeonTick_ApplyObjectOffsets:
	TST.w	D7
	BEQ.w	DungeonTick_ApplyObjectOffsets_Loop
	MOVEA.l	Enemy_list_ptr.w, A6
	ADDI.l	#$00060000, obj_world_x(A6)
	SUBI.l	#$00060000, obj_world_y(A6)
	MOVEA.l	Object_slot_01_ptr.w, A6
	SUBI.l	#$00060000, obj_world_x(A6)
	SUBI.l	#$00060000, obj_world_y(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	SUBI.l	#$00060000, obj_world_y(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	ADDI.l	#$00120000, obj_world_x(A6)
	SUBI.l	#$00060000, obj_world_y(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	SUBI.l	#$00120000, obj_world_x(A6)
	SUBI.l	#$00060000, obj_world_y(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	ADDI.l	#$00040000, obj_world_x(A6)
	SUBI.l	#$00040000, obj_world_y(A6)
	MOVEA.l	Object_slot_06_ptr.w, A6
	SUBI.l	#$00040000, obj_world_x(A6)
	SUBI.l	#$00040000, obj_world_y(A6)
	MOVEA.l	Object_slot_07_ptr.w, A6
	SUBI.l	#$00040000, obj_world_y(A6)
	MOVEA.l	Object_slot_08_ptr.w, A6
	ADDI.l	#$00080000, obj_world_x(A6)
	SUBI.l	#$00040000, obj_world_y(A6)
	MOVEA.l	Object_slot_09_ptr.w, A6
	SUBI.l	#$00080000, obj_world_x(A6)
	SUBI.l	#$00040000, obj_world_y(A6)
	MOVEA.l	Object_slot_0A_ptr.w, A6
	ADDI.l	#$00020000, obj_world_x(A6)
	SUBI.l	#$00020000, obj_world_y(A6)
	MOVEA.l	Object_slot_0B_ptr.w, A6
	SUBI.l	#$00020000, obj_world_x(A6)
	SUBI.l	#$00020000, obj_world_y(A6)
	MOVEA.l	Object_slot_0C_ptr.w, A6
	SUBI.l	#$00020000, obj_world_y(A6)
	MOVEA.l	Object_slot_0D_ptr.w, A6
	ADDI.l	#$00040000, obj_world_x(A6)
	SUBI.l	#$00020000, obj_world_y(A6)
	MOVEA.l	Object_slot_0E_ptr.w, A6
	SUBI.l	#$00040000, obj_world_x(A6)
	SUBI.l	#$00020000, obj_world_y(A6)
	RTS

DungeonTick_ApplyObjectOffsets_Loop:
	MOVEA.l	Enemy_list_ptr.w, A6
	SUBI.l	#$00060000, obj_world_x(A6)
	ADDI.l	#$00060000, obj_world_y(A6)
	MOVEA.l	Object_slot_01_ptr.w, A6
	ADDI.l	#$00060000, obj_world_x(A6)
	ADDI.l	#$00060000, obj_world_y(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	ADDI.l	#$00060000, obj_world_y(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	SUBI.l	#$00120000, obj_world_x(A6)
	ADDI.l	#$00060000, obj_world_y(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	ADDI.l	#$00120000, obj_world_x(A6)
	ADDI.l	#$00060000, obj_world_y(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	SUBI.l	#$00040000, obj_world_x(A6)
	ADDI.l	#$00040000, obj_world_y(A6)
	MOVEA.l	Object_slot_06_ptr.w, A6
	ADDI.l	#$00040000, obj_world_x(A6)
	ADDI.l	#$00040000, obj_world_y(A6)
	MOVEA.l	Object_slot_07_ptr.w, A6
	ADDI.l	#$00040000, obj_world_y(A6)
	MOVEA.l	Object_slot_08_ptr.w, A6
	SUBI.l	#$00080000, obj_world_x(A6)
	ADDI.l	#$00040000, obj_world_y(A6)
	MOVEA.l	Object_slot_09_ptr.w, A6
	ADDI.l	#$00080000, obj_world_x(A6)
	ADDI.l	#$00040000, obj_world_y(A6)
	MOVEA.l	Object_slot_0A_ptr.w, A6
	SUBI.l	#$00020000, obj_world_x(A6)
	ADDI.l	#$00020000, obj_world_y(A6)
	MOVEA.l	Object_slot_0B_ptr.w, A6
	ADDI.l	#$00020000, obj_world_x(A6)
	ADDI.l	#$00020000, obj_world_y(A6)
	MOVEA.l	Object_slot_0C_ptr.w, A6
	ADDI.l	#$00020000, obj_world_y(A6)
	MOVEA.l	Object_slot_0D_ptr.w, A6
	SUBI.l	#$00040000, obj_world_x(A6)
	ADDI.l	#$00020000, obj_world_y(A6)
	MOVEA.l	Object_slot_0E_ptr.w, A6
	ADDI.l	#$00040000, obj_world_x(A6)
	ADDI.l	#$00020000, obj_world_y(A6)
	RTS

DrawFirstPersonWalls:
	CLR.w	D0
	MOVE.b	First_person_wall_right.w, D0
	BLE.b	DrawFirstPersonWalls_Loop
	LEA	WallRenderVdpParams_Near, A2
	BSR.w	PrepareWallTileRenderData
	BSR.w	RenderWallTile_14x10_TwoPalette
DrawFirstPersonWalls_Loop:
	CLR.w	D0
	MOVE.b	First_person_center_wall.w, D0
	BLE.b	DrawFirstPersonWalls_DrawCenterWall
	LEA	WallRenderVdpParams_Mid, A2
	BSR.w	PrepareWallTileRenderData
	BSR.w	RenderWallTile_14x10_TwoPalette
DrawFirstPersonWalls_DrawCenterWall:
	CLR.w	D0
	MOVE.b	Fp_wall_right_2.w, D0
	BLE.b	DrawFirstPersonWalls_Return
	LEA	WallRenderVdpParams_Far, A2
	BSR.w	PrepareWallTileRenderData
	BSR.w	RenderWallTile_14x10_TwoPalette_RightWall
DrawFirstPersonWalls_Return:
	RTS

PrepareWallTileRenderData:
	MOVE.w	First_person_wall_frame.w, D1
	MOVE.w	Wall_render_y_offset.w, D2
	SUBQ.w	#1, D0
	MOVE.w	D0, D3
	ADD.w	D3, D3
	ASL.w	#4, D0
	ADD.w	D0, D2
	LEA	WallTileMidGfxPtrs, A1
	LEA	FpSpritePositionTable, A3
	MOVE.l	(A2,D1.w), D5
	MOVEA.l	(A1,D2.w), A0
	MOVE.w	(A3,D3.w), D4
	MOVE.w	D4, D1
	MOVE.w	D4, D2
	ORI.w	#$A000, D1
	ORI.w	#$A800, D2
	RTS

RenderWallTile_14x10_TwoPalette:
	ORI	#$0700, SR
	MOVE.w	#$000D, D7
RenderWallTile_14x10_TwoPalette_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#5, D6
RenderWallTile_14x10_TwoPalette_WritePalette1Tile:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADD.w	D1, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, RenderWallTile_14x10_TwoPalette_WritePalette1Tile
	MOVE.w	#4, D6
RenderWallTile_14x10_TwoPalette_WritePalette2Tile:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADD.w	D2, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, RenderWallTile_14x10_TwoPalette_WritePalette2Tile
	ADDI.l	#$00800000, D5
	DBF	D7, RenderWallTile_14x10_TwoPalette_Done
	ANDI	#$F8FF, SR
	RTS

RenderWallTile_14x10_TwoPalette_RightWall:
	ORI	#$0700, SR
	MOVE.w	#$000D, D7
RenderWallTile_14x10_TwoPalette_RightWall_Done:
	MOVE.l	D5, D4
	MOVE.w	#5, D6
RenderWallTile_14x10_TwoPalette_RightWall_WritePalette1Tile:
	MOVE.l	D4, VDP_control_port
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADD.w	D1, D0
	MOVE.w	D0, VDP_data_port
	ADDI.l	#$00020000, D4
	DBF	D6, RenderWallTile_14x10_TwoPalette_RightWall_WritePalette1Tile
	MOVE.w	#4, D6
RenderWallTile_14x10_TwoPalette_RightWall_WritePalette2Tile:
	MOVE.l	D4, VDP_control_port
	CLR.w	D0
	MOVE.b	(A0)+, D0
	MOVE.l	D4, D3
	ANDI.l	#$007F0000, D3
	CMPI.l	#$002C0000, D3
	BGT.b	RenderWallTile_14x10_TwoPalette_RightWall_Loop
	ADD.w	D2, D0
	MOVE.w	D0, VDP_data_port
RenderWallTile_14x10_TwoPalette_RightWall_Loop:
	ADDI.l	#$00020000, D4
	DBF	D6, RenderWallTile_14x10_TwoPalette_RightWall_WritePalette2Tile
	ADDI.l	#$00800000, D5
	DBF	D7, RenderWallTile_14x10_TwoPalette_RightWall_Done
	ANDI	#$F8FF, SR
	RTS

RenderWallTile_16x5_Palette1:
	ORI	#$0700, SR
	MOVE.w	#$000F, D7
RenderWallTile_16x5_Palette1_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#4, D6
RenderWallTile_16x5_Palette1_WriteTile:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADD.w	D1, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, RenderWallTile_16x5_Palette1_WriteTile
	ADDI.l	#$00800000, D5
	DBF	D7, RenderWallTile_16x5_Palette1_Done
	ANDI	#$F8FF, SR
	RTS

RenderWallTile_16x5_Palette0:
	ORI	#$0700, SR
	MOVE.w	#$000F, D7
RenderWallTile_16x5_Palette0_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#4, D6
RenderWallTile_16x5_Palette0_WriteTile:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADD.w	D1, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, RenderWallTile_16x5_Palette0_WriteTile
	ADDI.l	#$00800000, D5
	DBF	D7, RenderWallTile_16x5_Palette0_Done
	ANDI	#$F8FF, SR
	RTS

RenderWallTile_16x11_TwoPalette:
	ORI	#$0700, SR
	MOVE.w	#$0010, D7
RenderWallTile_16x11_TwoPalette_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#5, D6
RenderWallTile_16x11_TwoPalette_WritePalette1Tile:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADD.w	D1, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, RenderWallTile_16x11_TwoPalette_WritePalette1Tile
	MOVE.w	#4, D6
RenderWallTile_16x11_TwoPalette_WritePalette2Tile:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADD.w	D2, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, RenderWallTile_16x11_TwoPalette_WritePalette2Tile
	ADDI.l	#$00800000, D5
	DBF	D7, RenderWallTile_16x11_TwoPalette_Done
	ANDI	#$F8FF, SR
	RTS
NullTickHandler:
	RTS
ClearFirstPersonTilemap:
	ORI	#$0700, SR
	MOVE.l	#$60820003, D5
	MOVE.w	#$0014, D7
ClearFirstPersonTilemap_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$0014, D6
ClearFirstPersonTilemap_ClearTile:
	MOVE.w	#0, VDP_data_port
	DBF	D6, ClearFirstPersonTilemap_ClearTile
	ADDI.l	#$00800000, D5
	DBF	D7, ClearFirstPersonTilemap_Done
	ANDI	#$F8FF, SR
	RTS

UpdateFirstPersonWallData:
	LEA	Map_sector_center.w, A0
	LEA	UpdateFpWallJumpTable, A2
	MOVE.w	Player_position_x_outside_town.w, D0
	MOVE.w	Player_position_y_outside_town.w, D1
	MOVE.w	Player_direction.w, D4
	ANDI.w	#6, D4
	ADD.w	D4, D4
	JSR	(A2,D4.w)
	RTS

UpdateFpWallJumpTable:
	BRA.w	UpdateFpWalls_FacingUp
	BRA.w	UpdateFpWalls_FacingLeft
	BRA.w	UpdateFpWalls_FacingDown
	BRA.w	UpdateFpWalls_FacingRight
; -----------------------------------------------------------------------
; UpdateFpWalls_FacingLeft / FacingDown / FacingRight / FacingUp
; Update first-person wall tile indices for all 15 visible object slots
;   across 3 depth tiers (Near/Mid/Far) and 5 lateral positions.
;
; Called exclusively via UpdateFpWallJumpTable dispatch above.
; Inputs (from UpdateFirstPersonWallData):
;   D0.w = Player X position    D1.w = Player Y position
;   A0   = Map_sector_center base pointer
;
; All four functions share the same skeleton and differ only in:
;   - Which axis is "forward" vs "lateral"  (X or Y)
;   - The sign of the forward step          (+1 or -1)
;   - Assignment of wall-side variables     (center/left/right naming)
;   - Object slot ordering across lateral positions
;
; Facing   Forward-step   Lateral stride   Wall-left var       Wall-right var
; Left     X-1, D1*$30    ±$30 (Y rows)    Fp_wall_right_2     First_person_wall_right
; Down     Y+1, *$30+D0   ±$01 (X cols)    Fp_wall_right_2     First_person_wall_right
; Right    X+1, D1*$30    ±$30 (Y rows)    First_person_wall_right  Fp_wall_right_2
; Up       Y-1, *$30+D0   ±$01 (X cols)    First_person_wall_right  Fp_wall_right_2
;
; Left/Down share identical object slot ordering.
; Right/Up share the mirror-image slot ordering.
;
; NOTE: FacingDown has a spurious extra LEA FpObjectTileTable_Far,A1 at the
;       start of its Far tier — a no-op bug present in the original ROM binary.
; NOTE: These four functions are logically unifiable into one parameterized
;       routine, but cannot be merged without changing ROM bytes (bit-perfect
;       constraint). They are preserved as-is from the original binary.
; -----------------------------------------------------------------------
UpdateFpWalls_FacingLeft:
	SUBQ.w	#1, D0
	MULU.w	#$0030, D1
	ADD.w	D0, D1
	LEA	(A0,D1.w), A2
	MOVE.b	(A2), D4
	BSR.w	ValidateDungeonTileType
	MOVE.b	D4, First_person_center_wall.w
	MOVE.b	-$30(A2), D4
	BSR.w	ValidateDungeonTileType
	MOVE.b	D4, Fp_wall_right_2.w
	MOVE.b	$30(A2), D4
	BSR.w	ValidateDungeonTileType
	MOVE.b	D4, First_person_wall_right.w
	LEA	FpObjectTileTable_Near, A1
	LEA	-$1(A2), A2
	MOVEA.l	Object_slot_04_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$60(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_01_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$30(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	CLR.w	D4
	MOVE.b	(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Enemy_list_ptr.w, A6
	CLR.w	D4
	MOVE.b	$30(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	CLR.w	D4
	MOVE.b	$60(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	LEA	-$1(A2), A2
	LEA	FpObjectTileTable_Mid, A1
	MOVEA.l	Object_slot_09_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$60(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_06_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$30(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_07_ptr.w, A6
	CLR.w	D4
	MOVE.b	(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	CLR.w	D4
	MOVE.b	$30(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_08_ptr.w, A6
	CLR.w	D4
	MOVE.b	$60(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	LEA	-$1(A2), A2
	LEA	FpObjectTileTable_Far, A1
	MOVEA.l	Object_slot_0E_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$60(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_0B_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$30(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_0C_ptr.w, A6
	CLR.w	D4
	MOVE.b	(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_0A_ptr.w, A6
	CLR.w	D4
	MOVE.b	$30(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_0D_ptr.w, A6
	CLR.w	D4
	MOVE.b	$60(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	RTS

; See block comment above UpdateFpWalls_FacingLeft for full analysis.
; FacingDown: forward = Y+1, lateral stride = ±$01, slots = Left/Down order
; NOTE: contains a spurious extra LEA FpObjectTileTable_Far,A1 at Far tier start (no-op)
UpdateFpWalls_FacingDown:
	ADDQ.w	#1, D1
	MULU.w	#$0030, D1
	ADD.w	D0, D1
	LEA	(A0,D1.w), A2
	MOVE.b	-$1(A2), D4
	BSR.w	ValidateDungeonTileType
	MOVE.b	D4, Fp_wall_right_2.w
	MOVE.b	(A2), D4
	BSR.w	ValidateDungeonTileType
	MOVE.b	D4, First_person_center_wall.w
	MOVE.b	$1(A2), D4
	BSR.w	ValidateDungeonTileType
	MOVE.b	D4, First_person_wall_right.w
	LEA	$30(A2), A2
	LEA	FpObjectTileTable_Near, A1
	MOVEA.l	Object_slot_04_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$2(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_01_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$1(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	CLR.w	D4
	MOVE.b	(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Enemy_list_ptr.w, A6
	CLR.w	D4
	MOVE.b	$1(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	CLR.w	D4
	MOVE.b	$2(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	LEA	$30(A2), A2
	LEA	FpObjectTileTable_Mid, A1
	MOVEA.l	Object_slot_09_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$2(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_06_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$1(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_07_ptr.w, A6
	CLR.w	D4
	MOVE.b	(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	CLR.w	D4
	MOVE.b	$1(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_08_ptr.w, A6
	CLR.w	D4
	MOVE.b	$2(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	LEA	$30(A2), A2
	LEA	FpObjectTileTable_Far, A1
	MOVEA.l	Object_slot_0E_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$2(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	LEA	FpObjectTileTable_Far, A1
	MOVEA.l	Object_slot_0B_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$1(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_0C_ptr.w, A6
	CLR.w	D4
	MOVE.b	(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_0A_ptr.w, A6
	CLR.w	D4
	MOVE.b	$1(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_0D_ptr.w, A6
	CLR.w	D4
	MOVE.b	$2(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	RTS

; See block comment above UpdateFpWalls_FacingLeft for full analysis.
; FacingRight: forward = X+1, lateral stride = ±$30, slots = Right/Up order (mirrored)
UpdateFpWalls_FacingRight:
	ADDQ.w	#1, D0
	MULU.w	#$0030, D1
	ADD.w	D1, D0
	LEA	(A0,D0.w), A2
	MOVE.b	-$30(A2), D4
	BSR.w	ValidateDungeonTileType
	MOVE.b	D4, First_person_wall_right.w
	MOVE.b	(A2), D4
	BSR.w	ValidateDungeonTileType
	MOVE.b	D4, First_person_center_wall.w
	MOVE.b	$30(A2), D4
	BSR.w	ValidateDungeonTileType
	MOVE.b	D4, Fp_wall_right_2.w
	LEA	$1(A2), A2
	LEA	FpObjectTileTable_Near, A1
	MOVEA.l	Object_slot_03_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$60(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Enemy_list_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$30(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	CLR.w	D4
	MOVE.b	(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_01_ptr.w, A6
	CLR.w	D4
	MOVE.b	$30(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	CLR.w	D4
	MOVE.b	$60(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	LEA	$1(A2), A2
	LEA	FpObjectTileTable_Mid, A1
	MOVEA.l	Object_slot_08_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$60(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$30(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_07_ptr.w, A6
	CLR.w	D4
	MOVE.b	(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_06_ptr.w, A6
	CLR.w	D4
	MOVE.b	$30(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_09_ptr.w, A6
	CLR.w	D4
	MOVE.b	$60(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	LEA	$1(A2), A2
	LEA	FpObjectTileTable_Far, A1
	MOVEA.l	Object_slot_0D_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$60(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_0A_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$30(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_0C_ptr.w, A6
	CLR.w	D4
	MOVE.b	(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_0B_ptr.w, A6
	CLR.w	D4
	MOVE.b	$30(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_0E_ptr.w, A6
	CLR.w	D4
	MOVE.b	$60(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	RTS

; See block comment above UpdateFpWalls_FacingLeft for full analysis.
; FacingUp: forward = Y-1, lateral stride = ±$01, slots = Right/Up order (mirrored)
; Saves D0/D1 into D2/D3 before computing (only function that preserves inputs)
UpdateFpWalls_FacingUp:
	MOVE.w	D0, D2
	MOVE.w	D1, D3
	SUBQ.w	#1, D3
	MULU.w	#$0030, D3
	ADD.w	D2, D3
	LEA	(A0,D3.w), A2
	MOVE.b	-$1(A2), D4
	BSR.w	ValidateDungeonTileType
	MOVE.b	D4, First_person_wall_right.w
	MOVE.b	(A2), D4
	BSR.w	ValidateDungeonTileType
	MOVE.b	D4, First_person_center_wall.w
	MOVE.b	$1(A2), D4
	BSR.w	ValidateDungeonTileType
	MOVE.b	D4, Fp_wall_right_2.w
	LEA	-$30(A2), A2
	LEA	FpObjectTileTable_Near, A1
	MOVEA.l	Object_slot_03_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$2(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Enemy_list_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$1(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	CLR.w	D4
	MOVE.b	(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_01_ptr.w, A6
	CLR.w	D4
	MOVE.b	$1(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	CLR.w	D4
	MOVE.b	$2(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	LEA	-$30(A2), A2
	LEA	FpObjectTileTable_Mid, A1
	MOVEA.l	Object_slot_08_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$2(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$1(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_07_ptr.w, A6
	CLR.w	D4
	MOVE.b	(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_06_ptr.w, A6
	CLR.w	D4
	MOVE.b	$1(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_09_ptr.w, A6
	CLR.w	D4
	MOVE.b	$2(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	LEA	-$30(A2), A2
	LEA	FpObjectTileTable_Far, A1
	MOVEA.l	Object_slot_0D_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$2(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_0A_ptr.w, A6
	CLR.w	D4
	MOVE.b	-$1(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_0C_ptr.w, A6
	CLR.w	D4
	MOVE.b	(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_0B_ptr.w, A6
	CLR.w	D4
	MOVE.b	$1(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	MOVEA.l	Object_slot_0E_ptr.w, A6
	CLR.w	D4
	MOVE.b	$2(A2), D4
	BSR.w	ValidateDungeonTileType
	ADD.w	D4, D4
	MOVE.w	(A1,D4.w), obj_tile_index(A6)
	RTS

GetMapTileInDirection:
	MOVE.w	Player_position_x_outside_town.w, D0
	MOVE.w	Player_position_y_outside_town.w, D1
	MOVE.w	Player_direction.w, D2
	ADD.w	D2, D2
	ADD.w	(A0,D2.w), D0
	ADD.w	$2(A0,D2.w), D1
	MULU.w	#$0030, D1
	ADD.w	D1, D0
	LEA	Map_sector_center.w, A0
	MOVE.b	(A0,D0.w), D0
	RTS

;UpdateMapSectorPosition:
UpdateMapSectorPosition: ; Go left from current map sector
	MOVE.w	Player_direction.w, D0
	ANDI.w	#6, D0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), D1
	ADD.w	D1, Player_position_x_outside_town.w
	BGE.b	UpdateMapSectorPosition_Loop
	SUBQ.w	#1, Player_map_sector_x.w
	MOVE.w	#$000F, Player_position_x_outside_town.w
	BSR.w	LoadMapSectors
	BRA.w	MapSectorScroll_Return
UpdateMapSectorPosition_Loop: ; Go right from current map sector
	CMPI.w	#$0010, Player_position_x_outside_town.w
	BLT.b	UpdateMapSectorPosition_ScrollRight
	ADDQ.w	#1, Player_map_sector_x.w
	CLR.w	Player_position_x_outside_town.w
	BSR.w	LoadMapSectors
	BRA.w	MapSectorScroll_Return
UpdateMapSectorPosition_ScrollRight: ; Go up from current map sector
	MOVE.w	$2(A0,D0.w), D1
	ADD.w	D1, Player_position_y_outside_town.w
	BGE.b	UpdateMapSectorPosition_ScrollDown
	SUBQ.w	#1, Player_map_sector_y.w
	MOVE.w	#$000F, Player_position_y_outside_town.w
	BSR.w	LoadMapSectors
	BRA.b	MapSectorScroll_Return
UpdateMapSectorPosition_ScrollDown: ; Go down from current map sector
	CMPI.w	#$0010, Player_position_y_outside_town.w
	BLT.b	MapSectorScroll_Return
	ADDQ.w	#1, Player_map_sector_y.w
	CLR.w	Player_position_y_outside_town.w
	BSR.w	LoadMapSectors
MapSectorScroll_Return:
	RTS

FpDirectionDeltaForward:
	dc.b	0,  0, -1, -1, -1, -1,  0,  0,  0,  0,  0,  1,  0,  1,  0,  0
FpDirectionDeltaBackward:
	dc.b	0,  0,  0,  1,  0,  1,  0,  0,  0,  0, -1, -1, -1, -1,  0,  0

InitObjectPositions_21x13:
	MOVEA.l	Object_slot_01_ptr.w, A6
	MOVE.l	#$00980000, obj_world_x(A6)
	MOVE.l	#$00800000, obj_world_y(A6)
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.l	#$00280000, obj_world_x(A6)
	MOVE.l	#$00800000, obj_world_y(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.l	#$00600000, obj_world_x(A6)
	MOVE.l	#$00800000, obj_world_y(A6)
	MOVEA.l	Object_slot_06_ptr.w, A6
	MOVE.l	#$00640000, obj_world_x(A6)
	MOVE.l	#$00680000, obj_world_y(A6)
	MOVEA.l	Object_slot_09_ptr.w, A6
	MOVE.l	#$00840000, obj_world_x(A6)
	MOVE.l	#$00680000, obj_world_y(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	MOVE.l	#$00240000, obj_world_x(A6)
	MOVE.l	#$00680000, obj_world_y(A6)
	MOVEA.l	Object_slot_07_ptr.w, A6
	MOVE.l	#$00440000, obj_world_x(A6)
	MOVE.l	#$00680000, obj_world_y(A6)
	MOVEA.l	Object_slot_0C_ptr.w, A6
	MOVE.l	#$00300000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	MOVEA.l	Object_slot_0A_ptr.w, A6
	MOVE.l	#$00240000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	MOVEA.l	Object_slot_0D_ptr.w, A6
	MOVE.l	#$00100000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	MOVEA.l	Object_slot_0B_ptr.w, A6
	MOVE.l	#$00400000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	MOVEA.l	Object_slot_0E_ptr.w, A6
	MOVE.l	#$00500000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	RTS

RenderFpSector_Near:
	MULU.w	#$0030, D1
	ADD.w	D1, D0
	MOVE.w	D0, Map_tile_base_index.w
	ADD.w	(A4)+, D0
	CLR.w	D4
	MOVE.b	(A2,D0.w), D4
	BSR.w	MapTileToTypeIndex
	SUBQ.w	#1, D4
	BLT.b	RenderFpSector_Near_Loop
	MOVE.l	#$62820003, D5
	BSR.w	RenderWallTile_NearFrontTwoPalette
RenderFpSector_Near_Loop:
	MOVE.w	Map_tile_base_index.w, D0
	ADD.w	(A4)+, D0
	CLR.w	D4
	MOVE.b	(A2,D0.w), D4
	BSR.w	MapTileToTypeIndex
	SUBQ.w	#1, D4
	BLT.b	RenderFpSector_Near_LoadObjectTiles
	MOVE.l	#$63180003, D5
	BSR.w	RenderWallTileWithPalette
RenderFpSector_Near_LoadObjectTiles:
	LEA	FpObjectTileTable_Near, A0
	MOVEA.l	Enemy_list_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_02_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_01_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	LEA	FpObjectTileTable_Mid, A0
	MOVEA.l	Object_slot_05_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_07_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_06_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_09_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	LEA	FpObjectTileTable_Far, A0
	MOVEA.l	Object_slot_0D_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_0A_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_0C_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_0B_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_0E_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.w	#0, obj_tile_index(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	MOVE.w	#0, obj_tile_index(A6)
	MOVEA.l	Object_slot_08_ptr.w, A6
	MOVE.w	#0, obj_tile_index(A6)
	RTS

InitObjectPositions_21x20:
	MOVEA.l	Object_slot_04_ptr.w, A6
	MOVE.l	#$00900000, obj_world_x(A6)
	MOVE.l	#$006C0000, obj_world_y(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.l	#$00280000, obj_world_x(A6)
	MOVE.l	#$006C0000, obj_world_y(A6)
	MOVEA.l	Object_slot_01_ptr.w, A6
	MOVE.l	#$00940000, obj_world_x(A6)
	MOVE.l	#$00840000, obj_world_y(A6)
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.l	#$00240000, obj_world_x(A6)
	MOVE.l	#$00840000, obj_world_y(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.l	#$005C0000, obj_world_x(A6)
	MOVE.l	#$007C0000, obj_world_y(A6)
	MOVEA.l	Object_slot_06_ptr.w, A6
	MOVE.l	#$007C0000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	MOVE.l	#$003C0000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	RTS

RenderFpSector_Far:
	MULU.w	#$0030, D1
	ADD.w	D1, D0
	MOVE.w	D0, Map_tile_base_index.w
	ADD.w	(A4)+, D0
	CLR.w	D4
	MOVE.b	(A2,D0.w), D4
	BSR.w	MapTileToTypeIndex
	SUBQ.w	#1, D4
	BLT.b	RenderFpSector_Far_Loop
	MOVE.l	#$63220003, D5
	BSR.w	RenderWallTile_FarSinglePalette
RenderFpSector_Far_Loop:
	MOVE.w	Map_tile_base_index.w, D0
	ADD.w	(A4)+, D0
	CLR.w	D4
	MOVE.b	(A2,D0.w), D4
	BSR.w	MapTileToTypeIndex
	SUBQ.w	#1, D4
	BLT.b	RenderFpSector_Far_RenderMidWall
	MOVE.l	#$630C0003, D5
	BSR.w	RenderWallTileWithPalette
RenderFpSector_Far_RenderMidWall:
	MOVE.w	Map_tile_base_index.w, D0
	ADD.w	(A4)+, D0
	CLR.w	D4
	MOVE.b	(A2,D0.w), D4
	BSR.w	MapTileToTypeIndex
	SUBQ.w	#1, D4
	BLT.b	RenderFpSector_Far_LoadObjectTiles
	MOVE.l	#$63020003, D5
	BSR.w	RenderWallTile_MidSinglePalette
RenderFpSector_Far_LoadObjectTiles:
	LEA	FpObjectTileTable_Near, A0
	MOVEA.l	Enemy_list_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_03_ptr.w, A6
	BSR.w	LoadMapTileGfxIndexAlt1
	MOVEA.l	Object_slot_02_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_01_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_04_ptr.w, A6
	BSR.w	LoadMapTileGfxIndexAlt1
	LEA	FpObjectTileTable_Mid, A0
	MOVEA.l	Object_slot_05_ptr.w, A6
	BSR.w	LoadMapTileGfxIndexAlt2
	MOVEA.l	Object_slot_06_ptr.w, A6
	BSR.w	LoadMapTileGfxIndexAlt2
	MOVEA.l	Object_slot_08_ptr.w, A6
	MOVE.w	#0, obj_tile_index(A6)
	MOVEA.l	Object_slot_07_ptr.w, A6
	MOVE.w	#0, obj_tile_index(A6)
	MOVEA.l	Object_slot_09_ptr.w, A6
	MOVE.w	#0, obj_tile_index(A6)
	MOVEA.l	Object_slot_0E_ptr.w, A6
	MOVE.w	#0, obj_tile_index(A6)
	MOVEA.l	Object_slot_0B_ptr.w, A6
	MOVE.w	#0, obj_tile_index(A6)
	MOVEA.l	Object_slot_0C_ptr.w, A6
	MOVE.w	#0, obj_tile_index(A6)
	MOVEA.l	Object_slot_0A_ptr.w, A6
	MOVE.w	#0, obj_tile_index(A6)
	MOVEA.l	Object_slot_0D_ptr.w, A6
	MOVE.w	#0, obj_tile_index(A6)
	RTS

InitObjectPositions_21x13Alt:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.l	#$00200000, obj_world_x(A6)
	MOVE.l	#$00800000, obj_world_y(A6)
	MOVEA.l	Object_slot_01_ptr.w, A6
	MOVE.l	#$00900000, obj_world_x(A6)
	MOVE.l	#$00800000, obj_world_y(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.l	#$00580000, obj_world_x(A6)
	MOVE.l	#$00800000, obj_world_y(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	MOVE.l	#$00580000, obj_world_x(A6)
	MOVE.l	#$00680000, obj_world_y(A6)
	MOVEA.l	Object_slot_08_ptr.w, A6
	MOVE.l	#$00380000, obj_world_x(A6)
	MOVE.l	#$00680000, obj_world_y(A6)
	MOVEA.l	Object_slot_06_ptr.w, A6
	MOVE.l	#$00980000, obj_world_x(A6)
	MOVE.l	#$00680000, obj_world_y(A6)
	MOVEA.l	Object_slot_07_ptr.w, A6
	MOVE.l	#$00780000, obj_world_x(A6)
	MOVE.l	#$00680000, obj_world_y(A6)
	MOVEA.l	Object_slot_0C_ptr.w, A6
	MOVE.l	#$008C0000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	MOVEA.l	Object_slot_0B_ptr.w, A6
	MOVE.l	#$009C0000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	MOVEA.l	Object_slot_0E_ptr.w, A6
	MOVE.l	#$00AC0000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	MOVEA.l	Object_slot_0A_ptr.w, A6
	MOVE.l	#$007C0000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	MOVEA.l	Object_slot_0D_ptr.w, A6
	MOVE.l	#$006C0000, obj_world_x(A6)
	MOVE.l	#$00580000, obj_world_y(A6)
	RTS

RenderFpSector_Mid:
	MULU.w	#$0030, D1
	ADD.w	D1, D0
	MOVE.w	D0, Map_tile_base_index.w
	ADD.w	(A4)+, D0
	CLR.w	D4
	MOVE.b	(A2,D0.w), D4
	BSR.w	MapTileToTypeIndex
	SUBQ.w	#1, D4
	BLT.b	RenderFpSector_Mid_Loop
	MOVE.l	#$62960003, D5
	BSR.w	RenderWallTile_NearTwoPalette
RenderFpSector_Mid_Loop:
	MOVE.w	Map_tile_base_index.w, D0
	ADD.w	(A4)+, D0
	CLR.w	D4
	MOVE.b	(A2,D0.w), D4
	BSR.w	MapTileToTypeIndex
	SUBQ.w	#1, D4
	BLT.b	RenderFpSector_Mid_LoadObjectTiles
	MOVE.l	#$63000003, D5
	BSR.w	RenderWallTileWithPalette
RenderFpSector_Mid_LoadObjectTiles:
	LEA	FpObjectTileTable_Near, A0
	MOVEA.l	Object_slot_01_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_02_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Enemy_list_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	LEA	FpObjectTileTable_Mid, A0
	MOVEA.l	Object_slot_06_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_07_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_05_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_08_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	LEA	FpObjectTileTable_Far, A0
	MOVEA.l	Object_slot_0E_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_0B_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_0C_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_0A_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_0D_ptr.w, A6
	BSR.w	LoadMapTileGfxIndex
	MOVEA.l	Object_slot_04_ptr.w, A6
	MOVE.w	#0, obj_tile_index(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.w	#0, obj_tile_index(A6)
	MOVEA.l	Object_slot_09_ptr.w, A6
	MOVE.w	#0, obj_tile_index(A6)
	RTS

; LoadMapTileGfxIndex
; Load map tile graphics index for object
; Input: A2 = Map data, A4 = Offset pointer, A0 = Tile type table, A6 = Object
; Output: Sets object+$8 to tile graphics index
LoadMapTileGfxIndex:
	MOVE.w	Map_tile_base_index.w, D0
	ADD.w	(A4)+, D0
	CLR.w	D4
	MOVE.b	(A2,D0.w), D4
	BEQ.w	ClearObjectGfxIndex
	BSR.w	MapTileToTypeIndex
	ADD.w	D4, D4
	MOVE.w	(A0,D4.w), D0
	MOVE.w	D0, obj_tile_index(A6)
	RTS

; LoadMapTileGfxIndexAlt1
; Load map tile graphics index for object (variant - subtracts $24)
LoadMapTileGfxIndexAlt1:
	MOVE.w	Map_tile_base_index.w, D0
	ADD.w	(A4)+, D0
	CLR.w	D4
	MOVE.b	(A2,D0.w), D4
	BEQ.w	ClearObjectGfxIndex
	BSR.w	MapTileToTypeIndex
	BEQ.w	ClearObjectGfxIndex
	ADD.w	D4, D4
	MOVE.w	(A0,D4.w), D0
	SUBI.w	#$0024, D0
	MOVE.w	D0, obj_tile_index(A6)
	RTS

; LoadMapTileGfxIndexAlt2
; Load map tile graphics index for object (variant - subtracts $18)
LoadMapTileGfxIndexAlt2:
	MOVE.w	Map_tile_base_index.w, D0
	ADD.w	(A4)+, D0
	CLR.w	D4
	MOVE.b	(A2,D0.w), D4
	BEQ.w	ClearObjectGfxIndex
	BSR.w	MapTileToTypeIndex
	BEQ.w	ClearObjectGfxIndex
	ADD.w	D4, D4
	MOVE.w	(A0,D4.w), D0
	SUBI.w	#$0018, D0
	MOVE.w	D0, obj_tile_index(A6)
	RTS

ClearObjectGfxIndex:
	MOVE.w	#0, obj_tile_index(A6)
	RTS

; MapTileToTypeIndex
; Map an overworld tile type byte to a dungeon terrain index.
; Input:  D4.b = raw overworld tile type
; Output: D4.b = terrain type index used by dungeon renderer
; Trashes: A6 byte at obj_direction offset (cleared on entry)
;
; NOTE (DRY-002): Near-duplicate of ValidateDungeonTileType below.
; See comment on ValidateDungeonTileType for why these cannot be physically merged.
MapTileToTypeIndex:
	CLR.b	obj_direction(A6)
	TST.b	D4
	BGE.b	MapTileToTypeIndex_Loop
	CMPI.b	#OVERWORLD_TILE_UPPER_CAVE_MIN, D4
	BLT.b	MapTileToTypeIndex_SetType4_UpperCave
	MOVE.b	#7, D4
	RTS

MapTileToTypeIndex_Loop:
	CMPI.b	#6, D4
	BLE.b	MapTileToTypeIndex_NormalType
	CMPI.b	#OVERWORLD_TILE_CAVE_MIN, D4
	BLT.b	MapTileToTypeIndex_ClearType
	TST.b	Is_in_cave.w
	BEQ.b	MapTileToTypeIndex_SetType3_OverworldCave
	MOVE.b	#8, D4
	RTS

MapTileToTypeIndex_SetType4_UpperCave:
	MOVE.b	#4, D4
	RTS

MapTileToTypeIndex_SetType3_OverworldCave:
	MOVE.b	#3, D4
	RTS

MapTileToTypeIndex_ClearType:
	CLR.w	D4
MapTileToTypeIndex_NormalType:
	RTS

; ValidateDungeonTileType
; Validate and normalize map tile type for first-person dungeon rendering.
; Input:  D4.b = raw tile type value
; Output: D4.b = validated/normalized tile type
; Trashes: A6 byte at obj_direction offset (cleared on entry)
;
; NOTE (DRY-002): Near-duplicate of MapTileToTypeIndex above. The two functions
; share identical logic for all inputs except D4 = 0:
;   MapTileToTypeIndex  : D4=0 → BGE takes the ≥0 branch → CLR.w D4 → RTS (D4=0 out)
;   ValidateDungeonTileType: D4=0 → BEQ exits immediately              (D4=0 out)
; Behaviorally equivalent for all reachable inputs, but the different branch
; encoding (BGE vs BEQ+BGT) prevents physical merging without altering the
; assembled binary. Callers use BSR.w so address proximity is not a constraint;
; the issue is pure byte-level encoding. Left as two functions to maintain
; bit-perfect output.
ValidateDungeonTileType:
	CLR.b	obj_direction(A6)
	TST.b	D4
	BEQ.b	RenderMapToVRAM_Return
	BGT.b	ValidateDungeonTileType_Loop
	CMPI.b	#OVERWORLD_TILE_UPPER_CAVE_MIN, D4
	BLT.b	ValidateDungeonTileType_SetType4_UpperCave
	MOVE.b	#7, D4
	RTS

ValidateDungeonTileType_Loop:
	CMPI.b	#6, D4
	BLE.b	RenderMapToVRAM_Return
	CMPI.b	#OVERWORLD_TILE_CAVE_MIN, D4
	BLT.b	ValidateDungeonTileType_NormalType
	TST.b	Is_in_cave.w
	BEQ.b	ValidateDungeonTileType_SetType3_OverworldCave
	MOVE.b	#8, D4
	RTS

ValidateDungeonTileType_SetType4_UpperCave:
	MOVE.b	#4, D4
	RTS

ValidateDungeonTileType_SetType3_OverworldCave:
	MOVE.b	#3, D4
	RTS

ValidateDungeonTileType_NormalType:
	CLR.w	D4
RenderMapToVRAM_Return:
	RTS

DisplayCompassToVRAM:
	LEA	DisplayCompassToVRAM_Data, A0
	BRA.w	RenderMapToVRAM_NoPalette
RenderMapToVRAM_DualPalette_21x20:
	LEA	RenderMapToVRAM_DualPalette_21x20_Data, A0
	BRA.w	RenderMapToVRAM_NoPalette
RenderMapToVRAM_DualPalette_21x13:
	LEA	RenderMapToVRAM_DualPalette_21x13_Data, A0
	MOVE.w	#$42A4, D4
	BRA.w	RenderMapToVRAM_WithPalette
RenderMapToVRAM_DualPalette_21x13_Alt:
	LEA	RenderMapToVRAM_DualPalette_21x13_Alt_Data, A0
	MOVE.w	#$4AA4, D4
	BRA.w	RenderMapToVRAM_WithPalette
RenderMapToVRAM_NoPalette:
	ORI	#$0700, SR
	MOVE.l	#$44820003, D5
	MOVE.w	#$000C, D7
RenderMapToVRAM_NoPalette_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$000A, D6
RenderMapToVRAM_NoPalette_WritePalette1Tile:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$42A4, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, RenderMapToVRAM_NoPalette_WritePalette1Tile
	MOVE.w	#9, D6
RenderMapToVRAM_NoPalette_WritePalette2Tile:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$4AA4, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, RenderMapToVRAM_NoPalette_WritePalette2Tile
	ADDI.l	#$00800000, D5
	DBF	D7, RenderMapToVRAM_NoPalette_Done
	ANDI	#$F8FF, SR
	RTS

RenderMapToVRAM_WithPalette:
	ORI	#$0700, SR
	MOVE.l	#$44820003, D5
	MOVE.w	#$000C, D7
RenderMapToVRAM_WithPalette_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$0014, D6
RenderMapToVRAM_WithPalette_WriteTile:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADD.w	D4, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, RenderMapToVRAM_WithPalette_WriteTile
	ADDI.l	#$00800000, D5
	DBF	D7, RenderMapToVRAM_WithPalette_Done
	ANDI	#$F8FF, SR
	RTS

DisplayKimsToVRAM:
	LEA	DisplayKimsToVRAM_Data, A0
	BRA.w	DisplayStatsToVRAM_NoPalette
DisplayStatsToVRAM:
	LEA	DisplayStatsToVRAM_Data, A0
	BRA.w	DisplayStatsToVRAM_NoPalette
DisplayStatsToVRAM_SinglePalette:
	LEA	DisplayStatsToVRAM_SinglePalette_Data, A0
	MOVE.w	#$4770, D4
	BRA.w	DisplayStatsToVRAM_WithPalette
DisplayStatsToVRAM_AltPalette:
	LEA	DisplayStatsToVRAM_AltPalette_Data, A0
	MOVE.w	#$4F70, D4
	BRA.w	DisplayStatsToVRAM_WithPalette
DisplayStatsToVRAM_NoPalette:
	ORI	#$0700, SR
	MOVE.l	#$40820003, D5
	MOVE.w	#7, D7
DisplayStatsToVRAM_NoPalette_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$000A, D6
DisplayStatsToVRAM_NoPalette_WritePalette1Tile:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$4770, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DisplayStatsToVRAM_NoPalette_WritePalette1Tile
	MOVE.w	#9, D6
DisplayStatsToVRAM_NoPalette_WritePalette2Tile:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$4F70, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DisplayStatsToVRAM_NoPalette_WritePalette2Tile
	ADDI.l	#$00800000, D5
	DBF	D7, DisplayStatsToVRAM_NoPalette_Done
	ANDI	#$F8FF, SR
	RTS

DisplayStatsToVRAM_WithPalette:
	ORI	#$0700, SR
	MOVE.l	#$40820003, D5
	MOVE.w	#7, D7
DisplayStatsToVRAM_WithPalette_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$0014, D6
DisplayStatsToVRAM_WithPalette_WriteTile:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADD.w	D4, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DisplayStatsToVRAM_WithPalette_WriteTile
	ADDI.l	#$00800000, D5
	DBF	D7, DisplayStatsToVRAM_WithPalette_Done
	ANDI	#$F8FF, SR
	RTS

UpdateCompassDisplay:
	MOVE.w	Player_direction.w, D0
	CMPI.w	#DIRECTION_LEFT, D0
	BEQ.b	UpdateCompassDisplay_Loop
	CMPI.w	#DIRECTION_RIGHT, D0
	BNE.b	UpdateCompassDisplay_SetFrameFromDirection
	MOVE.w	#4, Player_compass_frame.w
	BRA.w	DrawCompassTiles
UpdateCompassDisplay_Loop:
	MOVE.w	#$000C, Player_compass_frame.w
	BRA.w	DrawCompassTiles
UpdateCompassDisplay_SetFrameFromDirection:
	ADD.w	D0, D0
	MOVE.w	D0, Player_compass_frame.w
DrawCompassTiles:
	MOVE.w	Player_compass_frame.w, D0
	MULU.w	#5, D0
	LEA	DrawCompassTiles_Data, A0
	LEA	(A0,D0.w), A0
	ORI	#$0700, SR
	MOVE.l	#$40820003, D5
	MOVE.w	#7, D7
DrawCompassTiles_Done:
	LEA	(A0), A1
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$0014, D6
DrawCompassTiles_WriteTile:
	CLR.w	D0
	MOVE.b	(A1)+, D0
	ADDI.w	#$438F, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawCompassTiles_WriteTile
	ADDI.l	#$00800000, D5
	LEA	$64(A0), A0
	DBF	D7, DrawCompassTiles_Done
	ANDI	#$F8FF, SR
	RTS

LoadMapSectors:
	TST.b	Is_in_cave.w
	BEQ.w	Load9SectorMapWindow
	LEA	Map_sector_top_left.w, A2
	MOVE.w	#$023F, D7
LoadMapSectors_Done:
	MOVE.l	#$05050505, (A2)+ ; Fill up map data with cave rocks
	DBF	D7, LoadMapSectors_Done
	LEA	Map_sector_center.w, A3
	LEA	CaveMaps, A0
	MOVE.w	Current_cave_room.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A1
	BSR.w	DecompressMapSectorRLE
	BSR.w	CheckCaveRoomMapRevealed
	BSR.w	UpdateAreaVisibility
	BSR.w	RenderAreaMap
	RTS

; ============================================================================
; Load 9-Sector Map Window (3x3 Grid Around Player)
; ============================================================================
; Loads a 3x3 grid of map sectors centered on the player's current position.
; This creates a 48x48 tile play area (3 sectors x 16 tiles each).
;
; Sector Layout in RAM:
;   [Top-Left]    [Top-Center]    [Top-Right]
;   [Mid-Left]    [Center]        [Mid-Right]
;   [Bot-Left]    [Bot-Center]    [Bot-Right]
;
; The center sector is always the player's current sector. Surrounding
; sectors are loaded if in bounds, otherwise filled with default tiles.
;
; Overworld Map Bounds: X: 0-15, Y: 0-7 (128 sectors total in 16x8 grid)
;
; Input:
;   Player_map_sector_x, Player_map_sector_y - Player's current sector
; Output:
;   9 sectors loaded into RAM buffers starting at Map_sector_top_left
; ============================================================================
; The game keeps 9 map sectors in memory
Load9SectorMapWindow:
	LEA	OverworldMaps, A0
	MOVE.w	Player_map_sector_x.w, D0
	MOVE.w	Player_map_sector_y.w, D1
	MOVE.w	D0, D2
	MOVE.w	D1, D3
	SUBQ.w	#1, D2
	SUBQ.w	#1, D3
	LEA	Map_sector_top_left.w, A2
	BSR.w	LoadMapSectorIfInBounds
	MOVE.w	D0, D2
	MOVE.w	D1, D3
	SUBQ.w	#1, D3
	LEA	Map_sector_top_center.w, A2
	BSR.w	LoadMapSectorIfInBounds
	MOVE.w	D0, D2
	MOVE.w	D1, D3
	ADDQ.w	#1, D2
	SUBQ.w	#1, D3
	LEA	Map_sector_top_right.w, A2
	BSR.w	LoadMapSectorIfInBounds
	MOVE.w	D0, D2
	MOVE.w	D1, D3
	SUBQ.w	#1, D2
	LEA	Map_sector_middle_left.w, A2
	BSR.w	LoadMapSectorIfInBounds
	MOVE.w	D0, D2
	MOVE.w	D1, D3
	LEA	Map_sector_center.w, A2
	BSR.w	LoadMapSector_NoBoundsCheck
	MOVE.w	D0, D2
	MOVE.w	D1, D3
	ADDQ.w	#1, D2
	LEA	Map_sector_middle_right.w, A2
	BSR.w	LoadMapSectorIfInBounds
	MOVE.w	D0, D2
	MOVE.w	D1, D3
	SUBQ.w	#1, D2
	ADDQ.w	#1, D3
	LEA	Map_sector_bottom_left.w, A2
	BSR.w	LoadMapSectorIfInBounds
	MOVE.w	D0, D2
	MOVE.w	D1, D3
	ADDQ.w	#1, D3
	LEA	Map_sector_bottom_center.w, A2
	BSR.w	LoadMapSectorIfInBounds
	MOVE.w	D0, D2
	MOVE.w	D1, D3
	ADDQ.w	#1, D2
	ADDQ.w	#1, D3
	LEA	Map_sector_bottom_right.w, A2
	BSR.w	LoadMapSectorIfInBounds
	BSR.w	CheckOverworldSectorMapRevealed
	BSR.w	UpdateAreaVisibility
	BSR.w	RenderAreaMap
	RTS

; ============================================================================
; LoadMapSectorIfInBounds
; ============================================================================
; Loads a map sector at coordinates (D2, D3) if within map bounds.
; If out of bounds, fills destination buffer with default tiles.
;
; Map bounds: X (D2): 0-15, Y (D3): 0-7
;
; Input:
;   D2 = Sector X coordinate
;   D3 = Sector Y coordinate
;   A0 = Pointer to map table (OverworldMaps or CaveMaps)
;   A2 = Destination buffer for decompressed sector
; Output:
;   Sector decompressed to buffer pointed to by A2
; ============================================================================
LoadMapSectorIfInBounds:
	TST.w	D2                      ; Check if X < 0
	BLT.w	LoadMapSector_FillDefault            ; Out of bounds
	CMPI.w	#$F, D2                 ; Check if X > 15
	BGT.w	LoadMapSector_FillDefault            ; Out of bounds
	TST.w	D3                      ; Check if Y < 0
	BLT.w	LoadMapSector_FillDefault            ; Out of bounds
	CMPI.w	#7, D3                  ; Check if Y > 7
	BGT.w	LoadMapSector_FillDefault            ; Out of bounds
	
	; Sector is in bounds - calculate index and load
LoadMapSector_NoBoundsCheck:
	ASL.w	#4, D3                  ; D3 = Y * 16
	ADD.w	D3, D2                  ; D2 = Y*16 + X (sector index)
	ADD.w	D2, D2                  ; D2 *= 4 (long pointer offset)
	ADD.w	D2, D2
	MOVEA.l	(A0,D2.w), A1           ; A1 = compressed sector data
	LEA	(A2), A3                ; A3 = destination buffer
	BSR.w	DecompressMapSectorRLE            ; Decompress sector
	RTS

; ============================================================================
; RLE Decompression Routine for Map Sector Data
; ============================================================================
; Decompresses a single 16x16 tile sector from RLE-encoded map data.
; 
; RLE Format:
;   - Byte < $80: Output tile value directly
;   - Byte >= $80: Run length encoding
;       * Subtract $80 to get repeat count
;       * Read next byte as tile value
;       * Output that tile (repeat count) times
;
; Output Layout:
;   - Writes 256 tiles ($100) in 16x16 grid format
;   - Grid has 32-tile-wide stride (16 tiles data + 16 tiles padding per row)
;   - Each row of 16 tiles is followed by $20-byte alignment for next row
;
; Input:
;   A1 = Pointer to compressed map data
;   A3 = Destination buffer (adjusted -$20 before write)
; Output:
;   256 tiles written to buffer in 16x16 grid with 32-tile stride
; ============================================================================
DecompressMapSectorRLE:
	MOVEM.w	D1/D0, -(A7)        ; Save registers D0, D1
	LEA	-$20(A3), A3            ; Adjust output pointer back $20 bytes
	CLR.w	D0                      ; D0 = tile counter (0-255)
	MOVE.w	D0, D1                  ; D1 = repeat counter for RLE runs
	
	; Main decompression loop
DecompressMapSectorRLE_Done:
	MOVE.w	D0, D2                  ; Check if at end of row (every 16 tiles)
	ANDI.w	#$000F, D2              ; D2 = tile counter % 16
	BNE.b	DecompressMapTile_Next            ; If not multiple of 16, continue
	LEA	$20(A3), A3             ; Skip $20 bytes to next row
	
DecompressMapTile_Next:
	MOVE.b	(A1)+, D1               ; Read next compressed byte
	CMPI.w	#$80, D1                ; Check if RLE marker (>= $80)
	BLT.b	DecompressMapTile_Next_Loop            ; If < $80, it's a literal tile
	
	; RLE run handling
	SUBI.w	#$80, D1                ; D1 = repeat count
	MOVE.b	(A1)+, D3               ; D3 = tile value to repeat
	
DecompressMapTile_Next_Done:
	MOVE.b	D3, (A3)+               ; Write tile value
	ADDQ.w	#1, D0                  ; Increment tile counter
	MOVE.w	D0, D2                  ; Check if end of row
	ANDI.w	#$000F, D2
	BNE.b	DecompressMapTile_Next_CheckRleDone
	LEA	$20(A3), A3             ; Skip to next row
	
DecompressMapTile_Next_CheckRleDone:
	CMPI.w	#MAP_RLE_TILE_COUNT, D0              ; 256 tiles written?
	BGE.b	DecompressMapTile_Next_Exit            ; Yes: exit
	DBF	D1, DecompressMapTile_Next_Done        ; Loop while repeat count > 0
	CLR.w	D1
	BRA.b	DecompressMapTile_Next            ; Read next byte
	
	; Literal tile handling
DecompressMapTile_Next_Loop:
	MOVE.b	D1, (A3)+               ; Write tile directly
	ADDQ.w	#1, D0                  ; Increment counter
	CMPI.w	#MAP_RLE_TILE_COUNT, D0              ; 256 tiles written?
	BLT.b	DecompressMapSectorRLE_Done            ; No: continue
	
DecompressMapTile_Next_Exit:
	MOVEM.w	(A7)+, D0/D1            ; Restore registers
	RTS
