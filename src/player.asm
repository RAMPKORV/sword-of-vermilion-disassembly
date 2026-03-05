; ======================================================================
; src/player.asm
; Player movement, battle player input, entity clearing
; ======================================================================
ClearAllEnemyEntities:
	MOVEA.l	Enemy_list_ptr.w, A6
ClearAllEnemyEntities_loop:
	BCLR.b	#7, (A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	BEQ.b	ClearAllEnemyEntities_end
	LEA	(A6,D0.w), A6
	BRA.b	ClearAllEnemyEntities_loop
ClearAllEnemyEntities_end:
	RTS

PlayBattleMusic:
	LEA	BattleMusicIdTable, A0
	MOVE.w	Battle_type.w, D0
	MOVE.b	(A0,D0.w), D0
	JSR	QueueSoundEffect
	RTS

BattleMusicIdTable:
	dc.b	$88, $93, $88, $88, $93, $93, $93, $93, $88, $88, $93, $88, $93, $93 
BattlePaletteIndexTable:
	dc.w	$5F, $77, $68, $68, $81, $7E, $B1, $B2, $86, $B4, $B3, $87, $88, $82 
BossBattleObjectInitPtrs:
	dc.l	InitBossObjects_TypeA
	dc.l	InitBossObjects_TypeC
	dc.l	InitBossObjects_TypeB
	dc.l	InitBossObjects_TypeB
	dc.l	InitBossObjects_TypeE
	dc.l	InitBossObjects_TypeD
	dc.l	InitBossObjects_TypeD
	dc.l	InitBossObjects_TypeD
	dc.l	InitBossObjects_TypeA
	dc.l	InitBossObjects_TypeA
	dc.l	InitBossObjects_TypeC
	dc.l	InitBossObjects_TypeB
	dc.l	InitBossObjects_TypeE
	dc.l	InitBossObjects_TypeF

PlayCaveMusic:
	LEA	CaveMusicIdTable, A0
	MOVE.w	Current_cave_room.w, D1
	CLR.w	D0
	MOVE.b	(A0,D1.w), D0
	MOVE.w	D0, Current_area_music.w
	JSR	QueueSoundEffect
	RTS

CaveMusicIdTable:
	dc.b	$97, $8A, $8A, $98, $98, $8A, $8A, $97, $97, $98, $98, $97, $97, $97, $97, $8A, $8A, $8A, $8A, $98, $97, $97, $98, $8A, $8A, $8A, $8A, $8A, $8A, $8A, $8A, $8A 
	dc.b	$98, $98, $98, $98, $98, $98, $98, $98, $98, $98, $8A, $8A 

PlayerObjectHandler:
	BCLR.b	#7, obj_sprite_flags(A5)
	BCLR.b	#3, obj_sprite_flags(A5)
	BCLR.b	#4, obj_sprite_flags(A5)
	BSET.b	#5, obj_sprite_flags(A5)
	BSET.b	#6, obj_sprite_flags(A5)
	MOVE.b	#SPRITE_SIZE_4x3, obj_sprite_size(A5)
	MOVE.w	#1, obj_tile_index(A5)
	CLR.w	obj_sort_key(A5)
	MOVE.l	#PlayerObjectTick, obj_tick_fn(A5)
	MOVE.w	#PALETTE_IDX_TOWN_HUD, Palette_line_3_index.w
	MOVE.b	#1, obj_sprite_frame(A5)
	CLR.b	obj_move_counter(A5)
	MOVE.b	#PLAYER_MOVE_STEPS, Player_movement_step_counter.w
	CLR.b	Player_is_moving.w
	CLR.w	Player_movement_flags.w
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BCLR.b	#7, (A6)
	RTS

PlayerObjectTick:
	TST.b	Is_in_battle.w
	BNE.w	PlayerObjectTick_Loop
	MOVE.w	obj_world_x(A5), D0
	LSR.w	#3, D0
	MOVE.w	D0, D2
	LSR.w	#1, D2
	MOVE.w	D0, Player_tile_x.w
	MOVE.w	D2, Player_position_x_in_town.w
	ANDI.w	#$003F, D0
	MOVE.w	obj_world_y(A5), D1
	LSR.w	#3, D1
	MOVE.w	D1, D3
	LSR.w	#1, D3
	MOVE.w	D1, Player_tile_y.w
	MOVE.w	D3, Player_position_y_in_town.w
	ANDI.w	#$003F, D1
	ASL.w	#7, D1
	ASL.w	#1, D0
	ADD.w	D1, D0
	MOVE.w	D0, Player_tilemap_offset.w
	TST.b	Player_input_blocked.w
	BNE.w	TownMovement_UpdateIdleSprite
	TST.b	Fade_in_lines_mask.w
	BNE.w	TownMovement_UpdateIdleSprite
	TST.b	Fade_out_lines_mask.w
	BNE.w	TownMovement_UpdateIdleSprite
	TST.b	Player_is_moving.w
	BNE.w	PlayerObjectTick_Loop2
	MOVE.b	Controller_current_state.w, D0
	ANDI.w	#$000F, D0
	BEQ.w	TownMovement_UpdateIdleSprite
	SUBQ.w	#1, D0
	ADD.w	D0, D0
	LEA	BattleSpriteIndexTableB, A0
	MOVE.w	(A0,D0.w), D0
	ANDI.w	#$000E, D0
	MOVE.w	D0, Player_direction.w
	CLR.b	Town_movement_blocked.w
	BSR.w	GetTileInFrontOfPlayer
	TST.b	Town_movement_blocked.w
	BNE.w	TownMovement_UpdateIdleSprite
	BSR.w	CheckTownEnemyCollision
PlayerObjectTick_Loop2:
	TST.b	Town_movement_blocked.w
	BNE.w	TownMovement_UpdateIdleSprite
	MOVE.w	Player_direction.w, D0
	ANDI.w	#7, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	PlayerMovementJumpTable, A0
	JSR	(A0,D0.w)
PlayerObjectTick_Loop:
	RTS

PlayerObjectTick_DeadCode:					; unreferenced dead code
	JSR	AddSpriteToDisplayList
	RTS

PlayerMovementJumpTable:
	BRA.w	TownMovement_CameraUp
	BRA.w	TownMovement_CameraUp	
	BRA.w	TownMovement_CameraLeft
	BRA.w	TownMovement_CameraLeft	
	BRA.w	TownMovement_CameraDown
	BRA.w	TownMovement_CameraDown	
	BRA.w	TownMovement_CameraRight
	BRA.w	TownMovement_CameraRight	
TownMovement_UpdateIdleSprite:
	LEA	OverworldMapSector_D9E8, A0
	MOVE.w	Player_direction.w, D1
	BCLR.l	#0, D1
	ADD.w	D1, D1
	ADD.w	D1, D1
	MOVE.b	(A0,D1.w), obj_sprite_frame(A5)
	MOVE.b	#PLAYER_MOVE_STEPS, Player_movement_step_counter.w
	CLR.b	Player_is_moving.w
	TST.b	Player_walk_anim_toggle.w
	BEQ.b	TownMovement_UpdateIdleSprite_Loop
	CLR.b	Player_walk_anim_toggle.w
	BRA.b	TownMovement_UpdateIdleSprite_Loop2
TownMovement_UpdateIdleSprite_Loop:
	MOVE.b	#FLAG_TRUE, Player_walk_anim_toggle.w
TownMovement_UpdateIdleSprite_Loop2:
	BRA.w	TownMovementTick_UpdateFlags
TownMovement_CameraUp:
	MOVE.w	#CAMERA_MOVE_UP, Town_camera_move_state.w
	MOVE.w	obj_world_y(A5), D0
	SUB.w	Camera_scroll_y.w, D0
	BLE.b	TownMovement_CameraUp_Loop
	SUBQ.w	#1, obj_world_y(A5)
TownMovement_CameraUp_Loop:
	BRA.w	TownMovement_UpdateWalkAnim
TownMovement_CameraDown:
	MOVE.w	#CAMERA_MOVE_DOWN, Town_camera_move_state.w
	MOVE.w	obj_world_y(A5), D0
	SUB.w	Camera_scroll_y.w, D0
	CMPI.w	#$00E0, D0
	BGE.b	TownMovement_CameraDown_Loop
	ADDQ.w	#1, obj_world_y(A5)
TownMovement_CameraDown_Loop:
	BRA.w	TownMovement_UpdateWalkAnim
TownMovement_CameraLeft:
	MOVE.w	#CAMERA_MOVE_LEFT, Town_camera_move_state.w
	MOVE.w	obj_world_x(A5), D0
	SUB.w	Camera_scroll_x.w, D0
	CMPI.w	#$0010, D0
	BLE.w	TownMovement_CameraLeft_Loop
	SUBQ.w	#1, obj_world_x(A5)
TownMovement_CameraLeft_Loop:
	BRA.w	TownMovement_UpdateWalkAnim
TownMovement_CameraRight:
	MOVE.w	#CAMERA_MOVE_RIGHT, Town_camera_move_state.w
	MOVE.w	obj_world_x(A5), D0
	SUB.w	Camera_scroll_x.w, D0
	CMPI.w	#$0130, D0
	BGE.b	TownMovement_UpdateWalkAnim
	ADDQ.w	#1, obj_world_x(A5)
TownMovement_UpdateWalkAnim:
	MOVE.b	#FLAG_TRUE, Player_is_moving.w
	MOVE.w	Player_direction.w, D1
	BCLR.l	#0, D1
	ADD.w	D1, D1
	ADD.w	D1, D1
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	BTST.b	#6, IO_version
	BNE.w	TownMovement_UpdateWalkAnim_Loop
	ANDI.w	#$000F, D0
	BNE.b	TownMovement_UpdateWalkAnim_Loop2
	BSR.w	UpdatePlayerAnimation
TownMovement_UpdateWalkAnim_Loop2:
	ASR.w	#3, D0
	BRA.b	TownMovement_UpdateWalkAnim_Loop3
TownMovement_UpdateWalkAnim_Loop:
	ANDI.w	#7, D0	
	BNE.b	TownMovement_UpdateWalkAnim_Loop4	
	BSR.w	UpdatePlayerAnimation	
TownMovement_UpdateWalkAnim_Loop4:
	ASR.w	#2, D0	
TownMovement_UpdateWalkAnim_Loop3:
	TST.b	Player_walk_anim_toggle.w
	BEQ.b	TownMovement_UpdateWalkAnim_Loop5
	ADDQ.w	#2, D0
TownMovement_UpdateWalkAnim_Loop5:
	ADD.w	D1, D0
	LEA	OverworldMapSector_D9E8, A0
	MOVE.b	(A0,D0.w), obj_sprite_frame(A5)
	SUBQ.b	#1, Player_movement_step_counter.w
	BGT.b	TownMovementTick_UpdateFlags
	MOVE.b	#PLAYER_MOVE_STEPS, Player_movement_step_counter.w
	CLR.b	Player_is_moving.w
TownMovementTick_UpdateFlags:
	BCLR.b	#3, obj_sprite_flags(A5)
	MOVE.w	Player_direction.w, D1
	CMPI.w	#DIRECTION_DOWN, D1
	BLT.b	TownMovementTick_UpdateFlags_Loop
	BSET.b	#3, obj_sprite_flags(A5)
TownMovementTick_UpdateFlags_Loop:
	MOVE.b	#FLAG_TRUE, Sprite_dma_update_pending.w
	MOVE.w	obj_world_x(A5), D0
	SUB.w	Camera_scroll_x.w, D0
	MOVE.w	D0, obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), D0
	SUB.w	Camera_scroll_y.w, D0
	ADDI.w	#0, D0
	MOVE.w	D0, obj_screen_y(A5)
	MOVE.w	obj_screen_y(A5), obj_sort_key(A5)
	JSR	AddSpriteToDisplayList
	RTS

UpdatePlayerAnimation:
	TST.b	Player_walk_anim_toggle.w
	BEQ.b	UpdatePlayerAnimation_Loop
	CLR.b	Player_walk_anim_toggle.w
	BRA.b	UpdatePlayerAnimation_Loop2
UpdatePlayerAnimation_Loop:
	MOVE.b	#FLAG_TRUE, Player_walk_anim_toggle.w
UpdatePlayerAnimation_Loop2:
	RTS

GetTileInFrontOfPlayer:
	MOVE.w	Player_direction.w, D2
	ADD.w	D2, D2
	LEA	BattleMoveOffsets, A1
	LEA	Tilemap_buffer_plane_b, A0
	MOVE.w	Player_tile_x.w, D0
	MOVE.w	Player_tile_y.w, D1
	ASL.w	#7, D1
	ASL.w	#1, D0
	ADD.w	(A1,D2.w), D0
	ADD.w	$2(A1,D2.w), D1
	ANDI.w	#$007F, D0
	ADD.w	D1, D0
	ANDI.w	#$1FFF, D0
	MOVE.w	(A0,D0.w), D0
	MOVE.w	D0, D1
	ANDI.w	#$F000, D0
	BEQ.b	TownMovement_Unblocked
	CMPI.w	#TOWN_TILE_PASSABLE_2, D0
	BEQ.b	TownMovement_Unblocked
	CMPI.w	#TOWN_TILE_PASSABLE_3, D0
	BEQ.b	TownMovement_Unblocked
	CMPI.w	#TOWN_TILE_PASSABLE_E, D0
	BEQ.b	TownMovement_Unblocked
	CMPI.w	#TOWN_TILE_PASSABLE_F, D0
	BEQ.b	TownMovement_Unblocked
	MOVE.b	#FLAG_TRUE, Town_movement_blocked.w
	RTS

TownMovement_Unblocked:
	CLR.b	Town_movement_blocked.w
	RTS

CheckTownEnemyCollision:
	MOVE.w	Player_direction.w, D4
	LSR.w	#1, D4
	ANDI.w	#3, D4
	ASL.w	#3, D4
	LEA	BattleCollisionBoxOffsets, A1
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A5), D2
	MOVE.w	D0, D1
	MOVE.w	D2, D3
	ADD.w	(A1,D4.w), D0
	ADD.w	$2(A1,D4.w), D1
	ADD.w	$4(A1,D4.w), D2
	ADD.w	$6(A1,D4.w), D3
	MOVEQ	#$1D, D7
	MOVEA.l	Enemy_list_ptr.w, A6
CheckTownEnemyCollision_Done:
	BTST.b	#7, (A6)
	BEQ.b	TownEnemyCollision_NextEnemy_Loop
	TST.b	obj_collidable(A6)
	BEQ.b	TownEnemyCollision_NextEnemy
	MOVE.w	obj_world_x(A6), D4
	CMP.w	D0, D4
	BLE.b	TownEnemyCollision_NextEnemy
	CMP.w	D1, D4
	BGE.b	TownEnemyCollision_NextEnemy
	MOVE.w	obj_world_y(A6), D4
	CMP.w	D2, D4
	BLE.b	TownEnemyCollision_NextEnemy
	CMP.w	D3, D4
	BGE.b	TownEnemyCollision_NextEnemy
	MOVE.b	#FLAG_TRUE, Town_movement_blocked.w
	RTS

TownEnemyCollision_NextEnemy:
	CLR.w	D4
	MOVE.b	obj_next_offset(A6), D4
	LEA	(A6,D4.w), A6
	DBF	D7, CheckTownEnemyCollision_Done
TownEnemyCollision_NextEnemy_Loop:
	RTS

; ---------------------------------------------------------------------------
; UpdatePlayerSpriteDMA — queue DMA transfers for player/enemy battle sprites
;
; Dispatches to one of three code paths based on battle state:
;
;   Overworld (Is_boss_battle=0, Is_in_battle=0):
;     DMA Player_overworld_gfx_buffer  → VRAM $1010  (stride $180/frame)
;
;   Normal battle (Is_in_battle≠0):
;     DMA Tilemap_buffer_plane_a       → VRAM $0D00  (player, stride $100/frame)
;     DMA Battle_gfx_slot_1_buffer     → VRAM $1010  (enemy 1, stride $180/frame)
;     DMA Battle_gfx_slot_2_buffer     → VRAM $1550  (enemy 2, stride $080/frame)
;
;   Boss battle (Is_boss_battle≠0):
;     DMA Tilemap_buffer_plane_a       → VRAM $1010  (player, stride $180/frame)
;     DMA Boss_gfx_slot_1_buffer       → VRAM $0980  (boss 1, stride $200/frame)
;     DMA Boss_gfx_slot_2_buffer       → VRAM $1550  (boss 2, stride $080/frame)
;
; Each per-entity block follows the pattern:
;   LEA buffer,A0 / MOVEA.l ptr,A6 / CLR.w D0 / MOVE.b frame(A6),D0
;   MULU stride,D0 / ADDA D0,A0 / EXG D0,A0
;   MOVE.l #D3_cmd,D3 / MOVE.l #D5_cmd,D5 / BSR SetupVdpDmaCommand
;
; DRY-007 NOTE: The 7-instruction entity-DMA pattern repeats 6 times across
; the three branches with unique (buffer, ptr, stride, D3, D5) values.
; Extracting a helper would change each BSR.w SetupVdpDmaCommand displacement,
; breaking bit-perfect output.  The pattern is documented here; physical
; deduplication is intentionally deferred.
;
; Input:   Is_boss_battle.w, Is_in_battle.w, Player/Battle entity ptrs+frames
; Scratch: D0-D5, A0, A6
; Output:  DMA command words written to DMA slot registers
; ---------------------------------------------------------------------------
UpdatePlayerSpriteDMA:
	TST.b	Is_boss_battle.w
	BNE.w	UpdatePlayerSpriteDMA_Loop
	TST.b	Is_in_battle.w
	BNE.b	UpdatePlayerSpriteDMA_Loop2
	LEA	Player_overworld_gfx_buffer, A0
	MOVEA.l	Player_entity_ptr.w, A6
	CLR.w	D0
	MOVE.b	obj_sprite_frame(A6), D0
	MULU.w	#$0180, D0
	ADDA.l	D0, A0
	EXG	D0, A0
	MOVE.l	#$40200080, D3
	MOVE.l	#$940093C0, D5
	BSR.w	SetupVdpDmaCommand
	RTS

UpdatePlayerSpriteDMA_Loop2:
	LEA	Tilemap_buffer_plane_a, A0
	MOVEA.l	Player_entity_ptr.w, A6
	CLR.w	D0
	MOVE.b	obj_sprite_frame(A6), D0
	MULU.w	#$0100, D0
	ADDA.l	D0, A0
	EXG	D0, A0
	MOVE.l	#$41A00080, D3
	MOVE.l	#$94009380, D5
	BSR.w	SetupVdpDmaCommand
	LEA	Battle_gfx_slot_1_buffer, A0
	MOVEA.l	Battle_entity_slot_1_ptr.w, A6
	CLR.w	D0
	MOVE.b	obj_sprite_frame(A6), D0
	MULU.w	#$0180, D0
	ADDA.l	D0, A0
	EXG	D0, A0
	MOVE.l	#$40200080, D3
	MOVE.l	#$940093C0, D5
	BSR.w	SetupVdpDmaCommand
	LEA	Battle_gfx_slot_2_buffer, A0
	MOVEA.l	Battle_entity_slot_2_ptr.w, A6
	CLR.w	D0
	MOVE.b	obj_sprite_frame(A6), D0
	MULU.w	#$0080, D0
	ADDA.l	D0, A0
	EXG	D0, A0
	MOVE.l	#$42A00080, D3
	MOVE.l	#$94009340, D5
	BSR.w	SetupVdpDmaCommand
	RTS

UpdatePlayerSpriteDMA_Loop:
	LEA	Tilemap_buffer_plane_a, A0
	MOVEA.l	Player_entity_ptr.w, A6
	CLR.w	D0
	MOVE.b	obj_sprite_frame(A6), D0
	MULU.w	#$0180, D0
	ADDA.l	D0, A0
	EXG	D0, A0
	MOVE.l	#$42200080, D3
	MOVE.l	#$940093C0, D5
	BSR.w	SetupVdpDmaCommand
	LEA	Boss_gfx_slot_1_buffer, A0
	MOVEA.l	Battle_entity_slot_1_ptr.w, A6
	CLR.w	D0
	MOVE.b	obj_sprite_frame(A6), D0
	MULU.w	#$0200, D0
	ADDA.l	D0, A0
	EXG	D0, A0
	MOVE.l	#$40200080, D3
	MOVE.l	#$94019300, D5
	BSR.w	SetupVdpDmaCommand
	LEA	Boss_gfx_slot_2_buffer, A0
	MOVEA.l	Battle_entity_slot_2_ptr.w, A6
	CLR.w	D0
	MOVE.b	obj_sprite_frame(A6), D0
	MULU.w	#$0080, D0
	ADDA.l	D0, A0
	EXG	D0, A0
	MOVE.l	#$43A00080, D3
	MOVE.l	#$94009340, D5
	BSR.w	SetupVdpDmaCommand
	RTS

SetupVdpDmaCommand:
	ANDI.l	#$00FFFFFF, D0
	LSR.l	#1, D0
	MOVE.w	D0, D1
	MOVE.l	#$95009600, D2
	ANDI.w	#$FF00, D1
	LSR.w	#8, D1
	MOVE.b	D1, D2
	SWAP	D2
	MOVE.w	D0, D1
	ANDI.w	#$00FF, D1
	MOVE.b	D1, D2
	SWAP	D0
	MOVE.w	#$9700, D1
	MOVE.b	D0, D1
	stopZ80
	JSR	InitVdpDmaRamRoutine
	MOVE.w	#2, D4
	ORI.w	#$8F00, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.l	D5, VDP_control_port
	MOVE.l	D2, VDP_control_port
	MOVE.w	D1, VDP_control_port
	MOVE.l	D3, Vdp_dma_cmd.w
	JSR	Vdp_dma_ram_routine.w
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4
	MOVE.w	D4, VDP_control_port
	startZ80
	RTS

BattleMoveOffsets:
	dc.w	$0000, $FF00
	dc.w	$FFFC, $0000
	dc.w	$0000, $0100
	dc.w	$0004, $0000 
BattleCollisionBoxOffsets:
	dc.w	-15, 15, -30, 0
	dc.w	-30, 0, -15, 15
	dc.w	-15, 15, 0, 30
	dc.w	0, 30, -15, 15 

InitBattlePlayerObject:	
	BCLR.b	#7, obj_sprite_flags(A5)
	BCLR.b	#3, obj_sprite_flags(A5)
	BCLR.b	#4, obj_sprite_flags(A5)
	BSET.b	#5, obj_sprite_flags(A5)
	BSET.b	#6, obj_sprite_flags(A5)
	MOVE.b	#SPRITE_SIZE_2x4, obj_sprite_size(A5)
	MOVE.w	#VRAM_TILE_BATTLE_PLAYER, obj_tile_index(A5)
	CLR.w	obj_sort_key(A5)
	CLR.b	obj_move_counter(A5)
	CLR.b	Player_is_moving.w
	CLR.b	Player_attacking_flag.w
	MOVE.l	#BattlePlayerInputHandler, obj_tick_fn(A5)
	MOVEA.l	Battle_entity_slot_1_ptr.w, A6
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BSET.b	#5, obj_sprite_flags(A6)
	BSET.b	#6, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.w	#1, obj_tile_index(A6)
	CLR.w	obj_sort_key(A6)
	MOVE.l	#BattleSlot1PositionSync, obj_tick_fn(A6)
	TST.w	Equipped_sword.w
	BLT.b	InitBattlePlayerObject_Loop
	MOVEA.l	Battle_entity_slot_2_ptr.w, A6
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BSET.b	#5, obj_sprite_flags(A6)
	BSET.b	#6, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_2x2, obj_sprite_size(A6)
	MOVE.w	#VRAM_TILE_BATTLE_WEAPON, obj_tile_index(A6)
	CLR.w	obj_sort_key(A6)
	MOVE.l	#BattleSlot2WeaponHandler, obj_tick_fn(A6)
	MOVE.w	#PALETTE_IDX_BATTLE_OUTDOOR, Palette_line_3_index.w
	JSR	LoadPalettesFromTable
	RTS

InitBattlePlayerObject_Loop:
	MOVEA.l	Battle_entity_slot_2_ptr.w, A6
	BCLR.b	#7, (A6)
	RTS

BattlePlayerInputHandler:
	TST.b	Player_input_blocked.w
	BNE.w	BattlePlayerInputHandler_UpdateSprite
	TST.b	Fade_out_lines_mask.w
	BNE.w	BattlePlayerInputHandler_UpdateSprite
	TST.b	Player_invulnerable.w
	BEQ.b	BattlePlayerInputHandler_AttackCheck
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGT.b	BattlePlayerInputHandler_AttackCheck
	CLR.b	Player_invulnerable.w
BattlePlayerInputHandler_AttackCheck:
	TST.b	Player_attacking_flag.w
	BNE.b	BattlePlayerInputHandler_ProcessMovement
	CheckButton BUTTON_BIT_C
	BEQ.b	BattlePlayerInputHandler_ProcessMovement
	TST.w	Equipped_sword.w
	BLT.b	BattlePlayerInputHandler_ProcessMovement
	PlaySound_b	SOUND_SWORD_ATTACK
	MOVE.b	#FLAG_TRUE, Player_attacking_flag.w
	CLR.b	obj_hp(A5)
BattlePlayerInputHandler_ProcessMovement:
	CheckButton BUTTON_BIT_A
	BEQ.b	BattlePlayerInputHandler_ProcessMovement_Loop
	BSR.w	DispatchBattleMagic
BattlePlayerInputHandler_ProcessMovement_Loop:
	MOVE.b	Controller_current_state.w, D0
	ANDI.w	#$F, D0
	BEQ.w	BattlePlayerInputHandler_UpdateSprite
	SUBQ.w	#1, D0
	ADD.w	D0, D0
	LEA	BattleSpriteIndexTableA, A0
	MOVE.w	(A0,D0.w), Player_direction.w
	LEA	SineTable, A0
	MOVE.l	obj_pos_x_fixed(A5), D0
	MOVE.w	Player_direction.w, D1
	ASL.w	#5, D1
	MOVE.b	(A0,D1.w), D2
	MOVE.b	$40(A0,D1.w), D3
	EXT.w	D2
	EXT.w	D3
	MULS.w	D0, D2
	MULS.w	D0, D3
	SUB.l	D2, obj_world_x(A5)
	SUB.l	D3, obj_world_y(A5)
	BRA.w	BattlePlayerInputHandler_UpdateSprite_Loop
BattlePostVictoryTickHandler:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGE.w	BattlePostVictory_NoReward_Loop
	TST.w	Enemy_reward_type.w
	BLT.b	BattlePostVictory_NoReward
	JSR	GetRandomNumber
	MOVE.w	D0, D1
	ANDI.w	#$000F, D0
	BNE.b	BattlePostVictory_NoReward
	ANDI.w	#$0030, D1
	MOVE.w	Player_luk.w, D0
	ANDI.w	#$01FF, D0
	ASR.w	#4, D0
	ADD.w	D1, D0
	CMPI.w	#$0030, D0
	BLT.b	BattlePostVictory_NoReward
	MOVE.b	#FLAG_TRUE, Found_something_nearby.w
BattlePostVictory_NoReward:
	BRA.w	BattlePostVictory_ResetEntities
BattlePostVictory_NoReward_Loop:
	MOVE.b	#FLAG_TRUE, Sprite_dma_update_pending.w
	JSR	AddSpriteToDisplayList
	RTS

BattlePostVictory_ResetEntities:
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.l	#BattleEntityIdleTickHandler, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	MOVE.l	#BattleEntityIdleTickHandler, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	MOVE.l	#BattleEntityIdleTickHandler, obj_tick_fn(A6)
	BSR.w	ClearObjectActiveFlags
	TST.b	Soldier_fight_event_trigger.w
	BEQ.b	BattlePostVictory_ResetEntities_Loop
	MOVE.w	#GAMEPLAY_STATE_SOLDIER_TAUNT, Gameplay_state.w
	BRA.b	BattlePostVictory_ResetEntities_Loop2
BattlePostVictory_ResetEntities_Loop:
	MOVE.w	#GAMEPLAY_STATE_BATTLE_EXIT, Gameplay_state.w
	PlaySound_b	SOUND_TRANSITION
	PlaySound	SOUND_LEVEL_UP
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
BattlePostVictory_ResetEntities_Loop2:
	MOVE.b	#FLAG_TRUE, Sprite_dma_update_pending.w
	CLR.b	Player_is_moving.w
	JSR	AddSpriteToDisplayList
	RTS

BattleEntityIdleTickHandler:
	JSR	AddSpriteToDisplayList
	RTS

BattlePlayerInputHandler_UpdateSprite:
	MOVEA.l	Battle_entity_slot_1_ptr.w, A6
	MOVEA.l	Battle_entity_slot_2_ptr.w, A4
	LEA	OverworldMapSector_DA08, A0
	MOVE.w	Player_direction.w, D1
	ASL.w	#4, D1
	MOVE.b	(A0,D1.w), obj_sprite_frame(A5)
	MOVE.b	$1(A0,D1.w), obj_sprite_frame(A6)
	MOVE.b	$2(A0,D1.w), obj_sprite_frame(A4)
	MOVE.b	#PLAYER_MOVE_STEPS, Player_movement_step_counter.w
	CLR.b	Player_is_moving.w
	BRA.w	BattleMovement_AttackCheck
BattlePlayerInputHandler_UpdateSprite_Loop:
	MOVE.b	#FLAG_TRUE, Player_is_moving.w
	MOVE.w	Player_direction.w, D1
	ASL.w	#4, D1
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	BTST.b	#6, IO_version
	BNE.w	BattlePlayerInputHandler_UpdateSprite_Loop2
	ANDI.w	#$0018, D0
	ASR.w	#1, D0
	ADD.w	D1, D0
	BRA.b	BattlePlayerInputHandler_UpdateSprite_Loop3
BattlePlayerInputHandler_UpdateSprite_Loop2:
	ANDI.w	#$000C, D0	
	ADD.w	D1, D0	
BattlePlayerInputHandler_UpdateSprite_Loop3:
	MOVEA.l	Battle_entity_slot_1_ptr.w, A6
	MOVEA.l	Battle_entity_slot_2_ptr.w, A4
	LEA	OverworldMapSector_DA08, A0
	MOVE.b	(A0,D0.w), obj_sprite_frame(A5)
	MOVE.b	$1(A0,D0.w), obj_sprite_frame(A6)
	MOVE.b	$2(A0,D0.w), obj_sprite_frame(A4)
	SUBQ.b	#1, Player_movement_step_counter.w
	BGT.b	BattleMovement_AttackCheck
	MOVE.b	#PLAYER_MOVE_STEPS, Player_movement_step_counter.w
	CLR.b	Player_is_moving.w
BattleMovement_AttackCheck:
	TST.b	Player_attacking_flag.w
	BEQ.w	BattleMovement_UpdateSprite
	MOVEA.l	Battle_entity_slot_1_ptr.w, A6
	MOVEA.l	Battle_entity_slot_2_ptr.w, A4
	ADDQ.b	#1, obj_hp(A5)
	MOVE.b	obj_hp(A5), D0
	ASR.w	#3, D0
	CMPI.w	#3, D0
	BGE.b	BattleMovement_AttackCheck_Loop
	ADD.w	D0, D0
	ADD.w	D0, D0
	ADD.w	D1, D0
	LEA	BattleMovement_AttackCheck_Data, A0
	MOVE.b	(A0,D0.w), obj_sprite_frame(A5)
	MOVE.b	$1(A0,D0.w), obj_sprite_frame(A6)
	MOVE.b	$2(A0,D0.w), obj_sprite_frame(A4)
	BSR.w	CheckBattleAttackHitbox
	BRA.w	BattleMovement_UpdateSprite
BattleMovement_AttackCheck_Loop:
	CLR.b	Player_attacking_flag.w
BattleMovement_UpdateSprite:
	BSET.b	#3, obj_sprite_flags(A5)
	MOVE.w	Player_direction.w, D1
	CMPI.w	#5, D1
	BLT.b	BattleMovement_UpdateSprite_Loop
	BCLR.b	#3, obj_sprite_flags(A5)
BattleMovement_UpdateSprite_Loop:
	TST.w	Number_Of_Enemies.w
	BGE.b	BattleMovement_UpdateSprite_Loop2
	MOVE.b	#BATTLE_VICTORY_DELAY, obj_invuln_timer(A5)
	MOVE.l	#BattlePostVictoryTickHandler, obj_tick_fn(A5)
	RTS

BattleMovement_UpdateSprite_Loop2:
	TST.b	Soldier_fight_event_trigger.w
	BEQ.b	BattleMovement_UpdateSprite_Loop3
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A5), D1
	CMPI.w	#0, D0
	BLT.w	BattleMovement_UpdateSprite_Loop4
	CMPI.w	#BATTLE_FIELD_WIDTH, D0
	BGT.w	BattleMovement_UpdateSprite_Loop5
	CMPI.w	#BATTLE_FIELD_TOP, D1
	BLT.w	PlayerSpritePositionClamp_TopEdge
	CMPI.w	#BATTLE_FIELD_BOTTOM, D1
	BGT.w	PlayerSpritePositionClamp_BottomEdge
	BRA.w	PlayerSpritePositionClamp_Done
BattleMovement_UpdateSprite_Loop3:
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A5), D1
	CMPI.w	#0, D0
	BLT.w	BattlePostVictory_ResetEntities
	CMPI.w	#BATTLE_FIELD_WIDTH, D0
	BGT.w	BattlePostVictory_ResetEntities
	CMPI.w	#BATTLE_FIELD_TOP, D1
	BLT.b	PlayerSpritePositionClamp_TopEdge
	CMPI.w	#BATTLE_FIELD_BOTTOM, D1
	BGT.b	PlayerSpritePositionClamp_BottomEdge
	BRA.b	PlayerSpritePositionClamp_Done
BattleMovement_UpdateSprite_Loop4:
	MOVE.w	#0, obj_world_x(A5)	
	BRA.b	PlayerSpritePositionClamp_Done	
BattleMovement_UpdateSprite_Loop5:
	MOVE.w	#BATTLE_FIELD_WIDTH, obj_world_x(A5)
	BRA.b	PlayerSpritePositionClamp_Done
PlayerSpritePositionClamp_TopEdge:
	MOVE.w	#BATTLE_FIELD_TOP, obj_world_y(A5)
	BRA.b	PlayerSpritePositionClamp_Done
PlayerSpritePositionClamp_BottomEdge:
	MOVE.w	#BATTLE_FIELD_BOTTOM, obj_world_y(A5)
PlayerSpritePositionClamp_Done:
	MOVE.b	#FLAG_TRUE, Sprite_dma_update_pending.w
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), D0
	ADDQ.w	#5, D0
	MOVE.w	D0, obj_screen_y(A5)
	MOVE.w	obj_screen_y(A5), obj_sort_key(A5)
	JSR	AddSpriteToDisplayList
	RTS

BattleSlot1PositionSync
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.b	obj_sprite_flags(A6), obj_sprite_flags(A5)
	MOVE.w	obj_screen_x(A6), obj_screen_x(A5)
	MOVE.w	obj_screen_y(A6), D2
	SUBI.w	#$0010, D2
	MOVE.w	D2, obj_screen_y(A5)
	MOVE.w	obj_screen_y(A6), obj_sort_key(A5)
	JSR	AddSpriteToDisplayList
	RTS

BattleSlot2WeaponHandler 
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.b	obj_sprite_flags(A6), obj_sprite_flags(A5)
	CLR.w	D0
	MOVE.b	obj_sprite_frame(A5), D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	PlayerSpritePositionClamp_Done_Data, A0
	MOVE.w	(A0,D0.w), D1
	BTST.b	#3, obj_sprite_flags(A5)
	BEQ.b	PlayerSpritePositionClamp_Done_Loop
	NEG.w	D1
PlayerSpritePositionClamp_Done_Loop:
	MOVE.w	obj_screen_x(A6), D2
	ADD.w	D1, D2
	MOVE.w	D2, obj_screen_x(A5)
	MOVE.w	obj_screen_y(A6), D2
	ADD.w	$2(A0,D0.w), D2
	MOVE.w	D2, obj_screen_y(A5)
	MOVE.w	obj_screen_y(A6), obj_sort_key(A5)
	JSR	AddSpriteToDisplayList
	RTS

;CheckBattleAttackHitbox:
CheckBattleAttackHitbox: ; suspected collision detection
	LEA	AttackHitboxData, A0
	MOVEA.l	Battle_entity_slot_1_ptr.w, A6
	CLR.w	D0
	MOVE.b	obj_sprite_frame(A6), D0
	ASL.w	#3, D0
	LEA	(A0,D0.w), A0
	BTST.b	#3, obj_sprite_flags(A5)
	BNE.b	CheckBattleAttackHitbox_Loop
	MOVE.w	(A0)+, D0
	MOVE.w	(A0)+, D1
	ADD.w	obj_world_x(A5), D0
	ADD.w	obj_world_x(A5), D1
	BRA.b	CheckBattleAttackHitbox_Loop2
CheckBattleAttackHitbox_Loop:
	MOVE.w	(A0)+, D1
	MOVE.w	(A0)+, D0
	NEG.w	D0
	NEG.w	D1
	ADD.w	obj_world_x(A5), D1
	ADD.w	obj_world_x(A5), D0
CheckBattleAttackHitbox_Loop2:
	MOVE.w	(A0)+, D2
	ADD.w	obj_world_y(A5), D2
	MOVE.w	(A0), D3
	ADD.w	obj_world_y(A5), D3
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#9, D7
CheckBattleAttackHitbox_Loop2_Done:
	BTST.b	#7, (A6)
	BEQ.w	NpcProximityCheck_NextSlot
	BTST.b	#6, (A6)
	BEQ.w	NpcProximityCheck_NextSlot
	MOVE.w	obj_world_x(A6), D4
	ADD.w	obj_hitbox_half_w(A6), D4
	CMP.w	D4, D0
	BGT.w	NpcProximityCheck_NextSlot
	MOVE.w	obj_world_x(A6), D4
	SUB.w	obj_hitbox_half_w(A6), D4
	CMP.w	D4, D1
	BLT.w	NpcProximityCheck_NextSlot
	MOVE.w	obj_world_y(A6), D4
	CMP.w	D4, D2
	BGT.w	NpcProximityCheck_NextSlot
	SUB.w	obj_hitbox_half_h(A6), D4
	CMP.w	D4, D3
	BLT.b	NpcProximityCheck_NextSlot
	MOVE.b	#FLAG_TRUE, obj_hit_flag(A6)
	MOVEA.l	Object_slot_01_ptr.w, A4
	BSET.b	#7, (A4)
	MOVE.l	#NPCInteractionTickHandler, obj_tick_fn(A4)
	MOVE.w	obj_world_x(A6), obj_world_x(A4)
	MOVE.w	obj_world_y(A6), D4
	SUBI.w	#$0010, D4
	MOVE.w	D4, obj_world_y(A4)
	MOVE.w	obj_sort_key(A6), D4
	ADDQ.w	#1, D4
	MOVE.w	D4, obj_sort_key(A4)
NpcProximityCheck_NextSlot:
	CLR.w	D5
	MOVE.b	obj_next_offset(A6), D5
	LEA	(A6,D5.w), A6
	CLR.w	D5
	MOVE.b	obj_next_offset(A6), D5
	LEA	(A6,D5.w), A6
	CLR.w	D5
	MOVE.b	obj_next_offset(A6), D5
	LEA	(A6,D5.w), A6
	DBF	D7, CheckBattleAttackHitbox_Loop2_Done
	RTS

NPCInteractionTickHandler:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	#NPC_ATTR_PAL3, obj_sprite_flags(A5)
	MOVE.b	#SPRITE_SIZE_2x2, obj_sprite_size(A5)
	LEA	NPCSpriteFrames_Base, A0
	MOVE.b	obj_move_counter(A5), D0
	BTST.b	#6, IO_version
	BNE.w	NPCInteractionTickHandler_Loop
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	BRA.b	NPCInteractionTickHandler_Loop2
NPCInteractionTickHandler_Loop:
	ANDI.w	#6, D0	
NPCInteractionTickHandler_Loop2:
	CMPI.w	#4, D0
	BLE.b	NPCInteractionTickHandler_Loop3
	BCLR.b	#7, (A5)
	RTS

NPCInteractionTickHandler_Loop3:
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS

DispatchBattleMagic:
	MOVE.w	Readied_magic.w, D0
	BLT.b	DispatchBattleMagic_Loop
	ANDI.w	#$001F, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	CastBattleMagicMap, A0
	JSR	(A0,D0.w)
DispatchBattleMagic_Loop:
	RTS

ClearObjectActiveFlags:
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.w	#$000B, D7
ClearObjectActiveFlags_Done:
	BCLR.b	#7, (A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, ClearObjectActiveFlags_Done
	RTS

AttackHitboxData:
	dc.w	 0,   0,   0,   0,   0,   0
	dc.w	 0,   0,   0,   0,   0,   0
	dc.w	 8,  16, -12,   0,   0,   0
	dc.w	 0,   0,   4,  20, -12,   0
	dc.w	-8,   8,   0,   8,   0,   0
	dc.w	 0,   0,  -8,   8,   0,  16
	dc.w	 0,   0,   0,   0,   0,   0
	dc.w	 0,   0,   0,   0,   0,   0
	dc.w	 0,   0,   0,   0,   0,   0
	dc.w	 0,   0,   0,   0,   0,   0
	dc.w	 4,   8,   0,   6,   0,   0
	dc.w	 0,   0,   4,  12,   0,  12
	dc.w	-8,   8, -16,   0,   0,   0
	dc.w	 0,   0,  -8,   8, -24,   0
	dc.w	 0,   0,   0,   0,   0,   0
	dc.w	 0,   0,   0,   0,   0,   0
	dc.w	 0,   0,   0,   0,   0,   0
	dc.w	 0,   0,   0,   0,   0,   0
	dc.w	 4,   8, -12,   0,   0,   0
	dc.w	 0,   0,   4,  12, -20,   0

	
InitOverworldPlayerObject:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.l	#NullTickHandler, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	MOVE.l	#NullTickHandler, obj_tick_fn(A6)
	MOVE.l	#OverworldPlayerTickHandler, obj_tick_fn(A5)
	CLR.w	Overworld_movement_frame.w
	CLR.b	Player_move_forward_in_overworld.w
	CLR.b	Player_move_backward_in_overworld.w
	CLR.b	Player_rotate_counter_clockwise_in_overworld.w
	CLR.b	Player_rotate_clockwise_in_overworld.w
	BSR.w	LoadMapSectors
InitFirstPersonView:
	BSR.w	ClearFirstPersonTilemap
	BSR.w	UpdateFirstPersonWallData
	MOVE.w	#0, First_person_wall_frame.w
	MOVE.w	#WALL_TILE_Y_OFFSET, Wall_render_y_offset.w
	BSR.w	DrawFirstPersonWalls
	BSR.w	UpdateAreaVisibility
	BSR.w	ResetObjectOffscreenPositions
	RTS

OverworldPlayerTickHandler:
	TST.b	Player_input_blocked.w
	BNE.w	OverworldTick_Return
	TST.b	Encounter_triggered.w
	BNE.w	OverworldTick_Return
	TST.b	Dialog_state_flag.w
	BNE.w	OverworldTick_Return
	TST.b	Fade_out_lines_mask.w
	BNE.w	OverworldTick_Return
	TST.b	Player_in_first_person_mode.w
	BEQ.w	OverworldTick_Return
	TST.b	Player_move_forward_in_overworld.w
	BNE.w	OverworldTick_RotateCounterClockwise_Loop
	TST.b	Player_move_backward_in_overworld.w
	BNE.w	OverworldTick_RotateCounterClockwise_Loop2
	TST.b	Player_rotate_counter_clockwise_in_overworld.w
	BNE.w	OverworldTick_RotateCounterClockwise
	TST.b	Player_rotate_clockwise_in_overworld.w
	BNE.b	OverworldTick_RotateClockwise
	CLR.w	Overworld_movement_frame.w
	MOVE.b	Controller_current_state.w, D0
	ANDI.w	#$000F, D0
	BEQ.w	OverworldTick_CaveLightCheck
	BTST.l	#0, D0
	BNE.w	OverworldTick_RotateCounterClockwise_Loop3
	BTST.l	#1, D0
	BNE.w	OverworldTick_RotateCounterClockwise_Loop4
	BTST.l	#2, D0
	BNE.w	OverworldTick_RotateCounterClockwise
	BTST.l	#3, D0
	BNE.b	OverworldTick_RotateClockwise
	BRA.w	OverworldTick_Return	
OverworldTick_RotateClockwise:
	MOVE.w	Overworld_movement_frame.w, D0
	MOVE.w	D0, D1
	ANDI.w	#7, D1
	BNE.w	OverworldTick_ClearInteractionFlags
	BSR.w	ClearFirstPersonTilemap
	MOVE.b	#FLAG_TRUE, Player_rotate_clockwise_in_overworld.w
	ANDI.w	#$0018, D0
	ASR.w	#1, D0
	LEA	RotateClockwiseJumpTable, A0
	ADDQ.w	#1, Player_compass_frame.w
OverworldRotateDispatch:
	JSR	(A0,D0.w)
	BRA.w	OverworldTick_ClearInteractionFlags
OverworldTick_RotateCounterClockwise:
	MOVE.w	Overworld_movement_frame.w, D0
	MOVE.w	D0, D1
	ANDI.w	#7, D1
	BNE.w	OverworldTick_ClearInteractionFlags
	BSR.w	ClearFirstPersonTilemap
	MOVE.b	#FLAG_TRUE, Player_rotate_counter_clockwise_in_overworld.w
	ANDI.w	#$0018, D0
	ASR.w	#1, D0
	SUBQ.w	#1, Player_compass_frame.w
	BGE.b	OverworldTick_RotateCounterClockwise_Loop5
	MOVE.w	#$000F, Player_compass_frame.w
OverworldTick_RotateCounterClockwise_Loop5:
	LEA	RotateCounterClockwiseJumpTable, A0
	JSR	(A0,D0.w)
	BRA.w	OverworldTick_ClearInteractionFlags
OverworldTick_RotateCounterClockwise_Loop4:
	LEA	FpDirectionDeltaBackward, A0
	BSR.w	GetMapTileInDirection
	BSR.w	HandleMapTileTransition
	BNE.w	OverworldTick_Return
OverworldTick_RotateCounterClockwise_Loop2:
	MOVE.w	Overworld_movement_frame.w, D0
	MOVE.w	D0, D1
	ANDI.w	#3, D1
	BNE.w	OverworldTick_ClearInteractionFlags
	BSR.w	ClearFirstPersonTilemap
	MOVE.b	#FLAG_TRUE, Player_move_backward_in_overworld.w
	ANDI.w	#$000C, D0
	LEA	BackwardMovementJumpTable, A0
	JSR	(A0,D0.w)
	BRA.w	OverworldTick_ClearInteractionFlags
OverworldTick_RotateCounterClockwise_Loop3:
	TST.b	Chest_already_opened.w
	BEQ.b	OverworldTick_RotateCounterClockwise_Loop6
	MOVE.b	#6, Fade_out_lines_mask.w
	MOVE.w	#GAMEPLAY_STATE_RETURN_TO_FIRST_PERSON_VIEW, Gameplay_state.w
	PlaySound_b	SOUND_TRANSITION
	RTS

OverworldTick_RotateCounterClockwise_Loop6:
	LEA	FpDirectionDeltaForward, A0
	BSR.w	GetMapTileInDirection
	BSR.w	HandleMapTileTransition
	BNE.w	OverworldTick_Return
OverworldTick_RotateCounterClockwise_Loop:
	MOVE.w	Overworld_movement_frame.w, D0
	MOVE.w	D0, D1
	ANDI.w	#3, D1
	BNE.b	OverworldTick_ClearInteractionFlags
	BSR.w	ClearFirstPersonTilemap
	MOVE.b	#FLAG_TRUE, Player_move_forward_in_overworld.w
	ANDI.w	#$000C, D0
	LEA	ForwardMovementJumpTable, A0
	JSR	(A0,D0.w)
OverworldTick_ClearInteractionFlags:
	CLR.b	Dialog_active_flag.w
	CLR.b	Chest_opened_flag.w
	CLR.b	Reward_script_active.w
	CLR.b	Herbs_available.w
	CLR.b	Truffles_available.w
	CLR.b	Reward_script_available.w
	CLR.b	Talker_present_flag.w
	MOVEA.l	Current_actor_ptr.w, A6
	BCLR.b	#7, (A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BCLR.b	#7, (A6)
	TST.b	Chest_already_opened.w
	BEQ.b	OverworldTick_ClearInteractionFlags_Loop
	PlaySound	SOUND_OVERWORLD_RETURN	
	CLR.b	Chest_already_opened.w	
OverworldTick_ClearInteractionFlags_Loop:
	CLR.b	Door_unlocked_flag.w
	ADDQ.w	#1, Overworld_movement_frame.w
	RTS

OverworldTick_CaveLightCheck:
	TST.b	Is_in_cave.w
	BEQ.b	OverworldTick_Return
	TST.b	Chest_already_opened.w
	BNE.b	OverworldTick_Return
	TST.b	Cave_light_active.w
	BGE.b	OverworldTick_Return
	BSR.w	UpdateCaveLightTimer
OverworldTick_Return:
	RTS

DecrementInaudiosSteps:
	TST.w	Inaudios_steps_remaining.w
	BNE.b	DecrementInaudiosSteps_Loop
	MOVE.w	#GAMEPLAY_STATE_NOTIFY_INAUDIOS_EXPIRED, Gameplay_state.w
	BRA.b	DecrementInaudiosSteps_Loop2
DecrementInaudiosSteps_Loop:
	BLT.b	DecrementInaudiosSteps_Loop3
DecrementInaudiosSteps_Loop2:
	SUBQ.w	#1, Inaudios_steps_remaining.w
