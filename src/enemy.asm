; ======================================================================
; src/enemy.asm
; Enemy AI, projectiles, collision, damage, death rewards
; ======================================================================
ClampProjectileToScreenBounds:
	MOVE.l	obj_world_x(A5), D0
	SUB.l	obj_vel_x(A5), D0
	SWAP	D0
	CMPI.w	#0, D0
	BLE.b	ClampProjectile_Kill
	CMPI.w	#BATTLE_FIELD_WIDTH, D0
	BGE.b	ClampProjectile_Kill
	SWAP	D0
	MOVE.l	D0, obj_world_x(A5)
	MOVE.l	obj_world_y(A5), D0
	SUB.l	obj_vel_y(A5), D0
	SWAP	D0
	CMPI.w	#BATTLE_FIELD_TOP, D0
	BLE.b	ClampProjectile_Kill
	CMPI.w	#BATTLE_FIELD_BOTTOM, D0
	BGE.b	ClampProjectile_Kill
	SWAP	D0
	MOVE.l	D0, obj_world_y(A5)
	BRA.b	ClampProjectile_Kill_Loop
ClampProjectile_Kill:
	BCLR.b	#7, (A5)
ClampProjectile_Kill_Loop:
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	obj_screen_y(A5), obj_sort_key(A5)
	RTS

EnemyObjectTick_DeadCode:					; unreferenced dead code
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#$0017, D7
ClampProjectile_Kill_Loop_Done:
	BCLR	#7, (A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	$0(A6,D0.w), A6
	DBF	D7, ClampProjectile_Kill_Loop_Done
	RTS

CalculateVelocityFromAngle:
	LEA	SineTable, A0
	MOVE.l	obj_pos_x_fixed(A5), D0
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	ASL.w	#5, D1
	MOVE.b	(A0,D1.w), D2
	MOVE.b	$40(A0,D1.w), D3
	EXT.w	D2
	EXT.w	D3
	MULS.w	D0, D2
	MULS.w	D0, D3
	MOVE.l	D2, obj_vel_x(A5)
	MOVE.l	D3, obj_vel_y(A5)
	RTS

; CheckObjectOnScreen
; Check if object is within visible screen bounds and update position
; Bounds: X = 0-320 pixels ($140), Y = 56-184 pixels ($38-$B8)
; If out of bounds: Clears scroll offset and randomizes direction
; If in bounds: Updates display position from world position
CheckObjectOnScreen:
	MOVE.l	obj_world_x(A5), D0
	SUB.l	obj_vel_x(A5), D0
	SWAP	D0
	CMPI.w	#0, D0
	BLE.w	ObjectOffScreen
	CMPI.w	#BATTLE_FIELD_WIDTH, D0
	BGE.w	ObjectOffScreen
	SWAP	D0
	MOVE.l	D0, obj_world_x(A5)
	MOVE.l	obj_world_y(A5), D0
	SUB.l	obj_vel_y(A5), D0
	SWAP	D0
	CMPI.w	#BATTLE_FIELD_TOP, D0
	BLE.w	ObjectOffScreen
	CMPI.w	#BATTLE_FIELD_BOTTOM, D0
	BGE.w	ObjectOffScreen
	SWAP	D0
	MOVE.l	D0, obj_world_y(A5)
	BRA.w	UpdateObjectDisplayPosition
ObjectOffScreen:
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	CLR.w	obj_attack_timer(A5)
	CLR.w	obj_knockback_timer(A5)
	JSR	GetRandomNumber
	ANDI.b	#7, D0
	ADD.b	D0, obj_direction(A5)
	ANDI.b	#7, obj_direction(A5)
UpdateObjectDisplayPosition:
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	obj_screen_y(A5), obj_sort_key(A5)
	RTS

UpdateObjectScreenPosition:
	MOVE.l	obj_world_x(A5), D0
	SUB.l	obj_vel_x(A5), D0
	SWAP	D0
	CMPI.w	#0, D0
	BLE.w	DeactivateOffScreenObject
	CMPI.w	#BATTLE_FIELD_WIDTH, D0
	BGE.w	DeactivateOffScreenObject
	SWAP	D0
	MOVE.l	D0, obj_world_x(A5)
	MOVE.l	obj_world_y(A5), D0
	SUB.l	obj_vel_y(A5), D0
	SWAP	D0
	CMPI.w	#BATTLE_FIELD_TOP, D0
	BLE.w	DeactivateOffScreenObject
	CMPI.w	#BATTLE_FIELD_BOTTOM, D0
	BGE.w	DeactivateOffScreenObject
	SWAP	D0
	MOVE.l	D0, obj_world_y(A5)
	BRA.w	DeactivateOffScreenObject_Loop
DeactivateOffScreenObject:
	BCLR.b	#7, (A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
DeactivateOffScreenObject_Loop:
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	obj_screen_y(A5), obj_sort_key(A5)
	RTS

; HandlePlayerTakeDamage
; Handle player taking damage from enemy collision
; Checks collision with enemy hitbox, applies damage, poison chance, and knockback
HandlePlayerTakeDamage:
	TST.b	Fade_out_lines_mask.w
	BNE.w	HandlePlayerTakeDamage_Return
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.l	obj_world_x(A5), D0
	SUB.l	obj_vel_x(A5), D0
	SWAP	D0
	MOVE.w	D0, D1
	SUB.w	obj_hitbox_half_w(A5), D0
	ADD.w	obj_hitbox_half_w(A5), D1
	MOVE.w	obj_world_x(A6), D2
	ADDQ.w	#8, D2
	CMP.w	D0, D2
	BLT.w	HandlePlayerTakeDamage_Return
	MOVE.w	obj_world_x(A6), D2
	SUBQ.w	#8, D2
	CMP.w	D1, D2
	BGT.w	HandlePlayerTakeDamage_Return
	MOVE.l	obj_world_y(A5), D0
	SUB.l	obj_vel_y(A5), D0
	SWAP	D0
	MOVE.w	D0, D1
	SUB.w	obj_hitbox_half_h(A5), D1
	MOVE.w	obj_world_y(A6), D2
	CMP.w	D1, D2
	BLT.w	HandlePlayerTakeDamage_Return
	SUBQ.w	#8, D2
	CMP.w	D0, D2
	BGT.w	HandlePlayerTakeDamage_Return
	TST.b	Player_invulnerable.w
	BNE.w	HandlePlayerTakeDamage_Return
	MOVE.b	#FLAG_TRUE, Player_invulnerable.w
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A6)
	BSR.w	ApplyDamageToPlayer
	MOVE.b	#SOUND_PLAYER_HIT, D0
	JSR	QueueSoundEffect
	TST.b	obj_sprite_frame(A5)
	BEQ.w	HandlePlayerTakeDamage_ApplyKnockback
	MOVE.w	Equipped_shield.w, D0
	ANDI.w	#$00FF, D0
	CMPI.w	#EQUIPMENT_SHIELD_POISON, D0
	BEQ.w	HandlePlayerTakeDamage_ApplyKnockback
	JSR	GetRandomNumber
	ANDI.w	#$01FF, D0
	CMP.w	Player_luk.w, D0
	BLT.b	HandlePlayerTakeDamage_ApplyKnockback
	MOVE.w	#POISONED_DURATION, Player_poisoned.w
; loc_00009244
HandlePlayerTakeDamage_ApplyKnockback:
	BSR.w	CalculateAngleBetweenObjects
	ANDI.w	#7, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	EnemyPositionOffsetTable, A0
	MOVE.w	(A0,D0.w), D1
	ADD.w	D1, obj_world_x(A6)
	MOVE.w	$2(A0,D0.w), D1
	ADD.w	D1, obj_world_y(A6)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
HandlePlayerTakeDamage_Return:
	RTS

CalculateAngleToObjectCentered:
	MOVE.w	#$00A0, D2
	MOVE.w	obj_world_x(A6), D0
	ASR.w	#1, D0
	CMP.w	obj_world_x(A6), D2
	BLE.w	CalculateAngleToObjectCentered_Loop
	ADD.w	D2, D0
CalculateAngleToObjectCentered_Loop:
	MOVE.w	#$0078, D2
	MOVE.w	obj_world_y(A6), D1
	ASR.w	#1, D1
	CMP.w	obj_world_y(A6), D2
	BLE.w	CalculateAngleToObjectCentered_Loop2
	ADD.w	D2, D1
CalculateAngleToObjectCentered_Loop2:
	SUB.w	obj_world_x(A5), D0
	SUB.w	obj_world_y(A5), D1
	BRA.w	CalculateAngleBetweenObjects_common
; CalculateAngleBetweenObjects
; Calculate angle from object A5 to object A6
; Input: A5 = Source object, A6 = Target object
; Output: D0 = Angle (0-15, where 0=right, 4=down, 8=left, 12=up)
CalculateAngleBetweenObjects:
	MOVE.w	obj_world_x(A6), D0
	SUB.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A6), D1
	SUB.w	obj_world_y(A5), D1
CalculateAngleBetweenObjects_common:
	CLR.w	D2
	TST.w	D0
	BGE.w	CalculateAngleBetweenObjects_common_Loop
	NEG.w	D0
	MOVE.w	#8, D2
CalculateAngleBetweenObjects_common_Loop:
	TST.w	D1
	BGE.w	CalculateAngleBetweenObjects_common_Loop2
	NEG.w	D1
	ORI.w	#4, D2
CalculateAngleBetweenObjects_common_Loop2:
	CMP.w	D1, D0
	BGE.w	CalculateAngleBetweenObjects_common_Loop3
	ORI.w	#2, D2
	ASR.w	#1, D1
	BGE.w	CalculateAngleBetweenObjects_common_Loop4
CalculateAngleBetweenObjects_common_Loop3:
	ASR.w	#1, D0
CalculateAngleBetweenObjects_common_Loop4:
	CMP.w	D1, D0
	BGE.w	CalculateAngleBetweenObjects_common_Loop5
	ORI.w	#1, D2
CalculateAngleBetweenObjects_common_Loop5:
	LEA	EnemyDirectionAnimTable, A1
	ADDA.w	D2, A1
	MOVE.b	(A1), D0
	RTS

CheckEnemyCollision:
	MOVEA.l	Enemy_list_ptr.w, A6
	TST.w	Number_Of_Enemies.w
	BEQ.w	EnemyCollision_NextEnemy_Loop
	MOVE.w	#7, D7
	CLR.w	D5
	CLR.w	D6
	MOVE.b	obj_next_offset(A6), D6
	MOVE.b	$1(A6,D6.w), D5
	ADD.w	D5, D6
	ADD.w	D5, D6
	MOVE.l	obj_world_x(A5), D2
	SUB.l	obj_vel_x(A5), D2
	SWAP	D2
	MOVE.w	D2, D3
	SUB.w	obj_hitbox_half_w(A5), D2
	ADD.w	obj_hitbox_half_w(A5), D3
	MOVE.l	obj_world_y(A5), D4
	SUB.l	obj_vel_y(A5), D4
	SWAP	D4
	MOVE.w	D4, D5
	SUB.w	obj_hitbox_half_h(A5), D5
CheckEnemyCollision_Done:
	CMPA.l	A5, A6
	BEQ.w	EnemyCollision_NextEnemy
	BTST.b	#7, (A6)
	BEQ.w	EnemyCollision_NextEnemy
CheckEnemyCollision_Done2:
	BTST.b	#6, (A6)
	BNE.w	CheckEnemyCollision_Loop
	ADDA.w	D6, A6
	BRA.b	CheckEnemyCollision_Done2
CheckEnemyCollision_Loop:
	MOVE.w	obj_world_x(A6), D1
	ADD.w	obj_hitbox_half_w(A6), D1
	CMP.w	D2, D1
	BLT.w	EnemyCollision_NextEnemy
	MOVE.w	obj_world_x(A6), D1
	SUB.w	obj_hitbox_half_w(A6), D1
	CMP.w	D3, D1
	BGT.w	EnemyCollision_NextEnemy
	MOVE.w	obj_world_y(A6), D1
	CMP.w	D5, D1
	BLT.w	EnemyCollision_NextEnemy
	SUB.w	obj_hitbox_half_h(A6), D1
	CMP.w	D4, D1
	BGT.w	EnemyCollision_NextEnemy
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
EnemyCollision_NextEnemy:
	ADDA.w	D6, A6
	DBF	D7, CheckEnemyCollision_Done
EnemyCollision_NextEnemy_Loop:
	RTS

EnemyDeathReward_OneSprite:
	MOVE.b	#SOUND_MAGIC_EFFECT, D0
	JSR	QueueSoundEffect
	MOVEQ	#0, D0
	MOVE.w	obj_xp_reward(A5), D0
	MOVE.l	D0, Transaction_amount.w
	JSR	AddExperiencePoints
	MOVEQ	#0, D0
	MOVE.w	obj_kim_reward(A5), D0
	MOVE.l	D0, Transaction_amount.w
	JSR	AddPaymentAmount
	SUBQ.w	#1, Number_Of_Enemies.w
	CLR.b	obj_move_counter(A5)
	MOVE.l	#EnemyDeathAnimation, obj_tick_fn(A5)
	MOVE.b	#NPC_ATTR_PAL3, obj_sprite_flags(A5)
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A5)
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	BCLR.b	#7, (A6)
	RTS

; loc_000093EA
EnemyDeathReward_TwoSprites:
	MOVE.b	#SOUND_MAGIC_EFFECT, D0
	JSR	QueueSoundEffect
	MOVEQ	#0, D0
	MOVE.w	obj_xp_reward(A5), D0
	MOVE.l	D0, Transaction_amount.w
	JSR	AddExperiencePoints
	MOVEQ	#0, D0
	MOVE.w	obj_kim_reward(A5), D0
	MOVE.l	D0, Transaction_amount.w
	JSR	AddPaymentAmount
	SUBQ.w	#1, Number_Of_Enemies.w
	CLR.b	obj_move_counter(A5)
	MOVE.l	#EnemyDeathAnimation, obj_tick_fn(A5)
	MOVE.b	#NPC_ATTR_PAL3, obj_sprite_flags(A5)
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A5)
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	BCLR.b	#7, (A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BCLR.b	#7, (A6)
	RTS

EnemyDeathAnimation:
	ADDQ.b	#1, obj_move_counter(A5)
	LEA	EnemyDeathAnimation_Data, A0
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$001C, D0
	ASR.w	#1, D0
	CMPI.w	#8, D0
	BLE.w	EnemyDeathAnimation_Loop
	BCLR.b	#7, (A5)
	RTS

EnemyDeathAnimation_Loop:
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList
	RTS

InitEnemy_StandardMelee:
	BSR.w	InitEnemyAI
	MOVE.w	#VRAM_TILE_ENEMY_BASE, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_2x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000A, obj_hitbox_half_h(A5)
	CLR.b	Enemy_pair_offset_flag.w
	MOVE.l	#EnemyTick_StandardMelee, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	MOVE.w	#ENEMY_ANIM_FRAME_MASK_24, Enemy_anim_frame_mask.w
	MOVE.w	#2, Enemy_anim_frame_shift.w
	MOVE.l	#EnemyAnimFrames_MeleeA_Main, Enemy_anim_table_main.w
	MOVE.l	#EnemyAnimFrames_MeleeA_Child, Enemy_anim_table_child.w
	RTS

InitEnemy_StandardMeleeAlt:
	BSR.w	InitEnemyAI
	MOVE.w	#VRAM_TILE_ENEMY_BASE, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000A, obj_hitbox_half_h(A5)
	MOVE.b	#FLAG_TRUE, Enemy_pair_offset_flag.w
	MOVE.l	#EnemyTick_StandardMelee, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	MOVE.w	#ENEMY_ANIM_FRAME_MASK_24, Enemy_anim_frame_mask.w
	MOVE.w	#2, Enemy_anim_frame_shift.w
	MOVE.l	#EnemyAnimFrames_MeleeB_Main, Enemy_anim_table_main.w
	MOVE.l	#EnemyAnimFrames_MeleeB_Child, Enemy_anim_table_child.w
	RTS

InitEnemy_StandardMeleeFast:
	BSR.w	InitEnemyAI
	MOVE.w	#VRAM_TILE_ENEMY_BASE, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_2x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000C, obj_hitbox_half_h(A5)
	CLR.b	Enemy_pair_offset_flag.w
	MOVE.l	#EnemyTick_StandardMelee, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	MOVE.w	#ENEMY_ANIM_FRAME_MASK_12, Enemy_anim_frame_mask.w
	MOVE.w	#1, Enemy_anim_frame_shift.w
	MOVE.l	#EnemyAnimFrames_MeleeA_Main, Enemy_anim_table_main.w
	MOVE.l	#EnemyAnimFrames_MeleeA_Child, Enemy_anim_table_child.w
	RTS

EnemyTick_StandardMelee:
	BSR.w	ProcessEnemyDamage
	BGT.w	EnemyTick_StandardMelee_Loop
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS

EnemyTick_StandardMelee_Loop:
	CLR.b	obj_hit_flag(A5)
	TST.b	Encounter_behavior_flag.w
	BNE.w	EnemyTick_UpdateSprite
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyTick_StandardMelee_Loop2
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#4, D0
	ANDI.b	#7, D0
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyMovementTick_UpdateVelocity
EnemyTick_StandardMelee_Loop2:
	TST.w	obj_attack_timer(A5)
	BEQ.w	EnemyTick_StandardMelee_Loop3
	SUBQ.w	#1, obj_attack_timer(A5)
	JSR	GetRandomNumber
	ANDI.b	#7, D0
	BNE.w	EnemyMovementTick_UpdateVelocity
	BTST.l	#4, D0
	BEQ.w	EnemyTick_StandardMelee_Loop4
	ADDQ.b	#1, obj_direction(A5)	
	BRA.w	EnemyTick_StandardMelee_Loop5	
EnemyTick_StandardMelee_Loop4:
	SUBQ.b	#1, obj_direction(A5)
EnemyTick_StandardMelee_Loop5:
	ANDI.b	#7, obj_direction(A5)
	BRA.w	EnemyMovementTick_UpdateVelocity
EnemyTick_StandardMelee_Loop3:
	JSR	GetRandomNumber
	ANDI.w	#$00FF, D0
	BNE.w	EnemyTick_StandardMelee_Loop6
	MOVE.w	#$00F0, obj_attack_timer(A5)
EnemyTick_StandardMelee_Loop6:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
; loc_00009614
EnemyMovementTick_UpdateVelocity:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	EnemyMovementTick_UpdateVelocity_Loop
	ADDQ.b	#1, obj_move_counter(A5)
EnemyMovementTick_UpdateVelocity_Loop:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.b	obj_move_counter(A5), D0
	AND.w	Enemy_anim_frame_mask.w, D0
	MOVE.w	Enemy_anim_frame_shift.w, D1
	ASR.w	D1, D0
	BCLR.b	#3, obj_sprite_flags(A5)
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	CMPI.b	#4, D1
	BLE.w	EnemyMovementTick_UpdateVelocity_Loop2
	BSET.b	#3, obj_sprite_flags(A5)
EnemyMovementTick_UpdateVelocity_Loop2:
	ASL.w	#3, D1
	ADD.w	D0, D1
	MOVEA.l	Enemy_anim_table_main.w, A0
	MOVEA.l	Enemy_anim_table_child.w, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	TST.b	Enemy_pair_offset_flag.w
	BNE.w	EnemyMovementTick_UpdateVelocity_Loop3
	BSR.w	CopyPositionToLinkedSprite
	BRA.w	EnemyTick_UpdateSprite
EnemyMovementTick_UpdateVelocity_Loop3:
	BSR.w	CopyEnemyPositionToChildObject
; loc_00009692
EnemyTick_UpdateSprite:
	JSR	AddSpriteToDisplayList
	RTS

InitEnemy_StalkPause:
	BSR.w	InitEnemyAI
	MOVE.w	#VRAM_TILE_ENEMY_BASE, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_2x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000A, obj_hitbox_half_h(A5)
	MOVE.l	#EnemyTick_StalkPause, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	MOVE.w	#ENEMY_ANIM_FRAME_MASK_24, Enemy_anim_frame_mask.w
	MOVE.w	#2, Enemy_anim_frame_shift.w
	MOVE.l	#EnemyAnimFrames_MeleeA_Main, Enemy_anim_table_main.w
	MOVE.l	#EnemyAnimFrames_MeleeA_Child, Enemy_anim_table_child.w
	RTS

InitEnemy_StalkPauseAlt:
	BSR.w	InitEnemyAI
	BSR.w	SetEnemyGraphicsParams
	MOVE.l	#EnemyTick_StalkPause, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	MOVE.w	#ENEMY_ANIM_FRAME_MASK_12, Enemy_anim_frame_mask.w
	MOVE.w	#1, Enemy_anim_frame_shift.w
	MOVE.l	#EnemyAnimFrames_MeleeA_Main, Enemy_anim_table_main.w
	MOVE.l	#EnemyAnimFrames_MeleeA_Child, Enemy_anim_table_child.w
	RTS

EnemyTick_StalkPause:
	BSR.w	ProcessEnemyDamage
	BGT.w	EnemyTick_StalkPause_Loop
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS

EnemyTick_StalkPause_Loop:
	CLR.b	obj_hit_flag(A5)
	TST.b	Encounter_behavior_flag.w
	BNE.w	EnemyTick_StalkPause_Loop2
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyTick_StalkPause_Loop3
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#4, D0
	ANDI.b	#7, D0
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyTick_StalkPause_Loop4
EnemyTick_StalkPause_Loop3:
	TST.w	obj_attack_timer(A5)
	BEQ.w	EnemyTick_StalkPause_Loop5
	SUBQ.w	#1, obj_attack_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	EnemyTick_StalkPause_Loop6
EnemyTick_StalkPause_Loop5:
	JSR	GetRandomNumber
	ANDI.w	#$007F, D0
	BNE.w	EnemyTick_StalkPause_Loop7
	MOVE.w	#ENEMY_STALK_RECHECK_DELAY, obj_attack_timer(A5)
EnemyTick_StalkPause_Loop7:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
EnemyTick_StalkPause_Loop4:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
EnemyTick_StalkPause_Loop6:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	EnemyTick_StalkPause_Loop8
	ADDQ.b	#1, obj_move_counter(A5)
EnemyTick_StalkPause_Loop8:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.b	obj_move_counter(A5), D0
	AND.w	Enemy_anim_frame_mask.w, D0
	MOVE.w	Enemy_anim_frame_shift.w, D1
	ASR.w	D1, D0
	BCLR.b	#3, obj_sprite_flags(A5)
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	CMPI.b	#4, D1
	BLE.w	EnemyTick_StalkPause_Loop9
	BSET.b	#3, obj_sprite_flags(A5)
EnemyTick_StalkPause_Loop9:
	ASL.w	#3, D1
	ADD.w	D0, D1
	MOVEA.l	Enemy_anim_table_main.w, A0
	MOVEA.l	Enemy_anim_table_child.w, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	BSR.w	CopyPositionToLinkedSprite
EnemyTick_StalkPause_Loop2:
	JSR	AddSpriteToDisplayList
	RTS

InitEnemy_ProximityChase:
	BSR.w	InitEnemyAI
	MOVE.w	#VRAM_TILE_ENEMY_BASE, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_2x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000C, obj_hitbox_half_h(A5)
	MOVE.l	#EnemyTick_ProximityChase, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	RTS

EnemyTick_ProximityChase:
	BSR.w	ProcessEnemyDamage
	BGT.w	EnemyTick_ProximityChase_Loop
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS

EnemyTick_ProximityChase_Loop:
	CLR.b	obj_hit_flag(A5)
	TST.b	Encounter_behavior_flag.w
	BNE.w	EnemyTick_ProximityChase_Loop2
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyTick_ProximityChase_Loop3
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#4, D0
	ANDI.b	#7, D0
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyTick_ProximityChase_Loop4
EnemyTick_ProximityChase_Loop3:
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), D0
	SUB.w	obj_world_x(A5), D0
	BGE.w	EnemyTick_ProximityChase_Loop5
	NEG.w	D0
EnemyTick_ProximityChase_Loop5:
	CMPI.w	#ENEMY_CHASE_PROXIMITY, D0
	BGT.w	EnemyTick_ProximityChase_Loop6
	MOVE.w	obj_world_y(A6), D0
	SUB.w	obj_world_y(A5), D0
	BGE.w	EnemyTick_ProximityChase_Loop7
	NEG.w	D0
EnemyTick_ProximityChase_Loop7:
	CMPI.w	#ENEMY_CHASE_PROXIMITY, D0
	BLE.w	EnemyTick_ProximityChase_Loop8
EnemyTick_ProximityChase_Loop6:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	EnemyTick_ProximityChase_Loop9
EnemyTick_ProximityChase_Loop8:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
EnemyTick_ProximityChase_Loop4:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
EnemyTick_ProximityChase_Loop9:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	EnemyTick_ProximityChase_Loop10
	ADDQ.b	#1, obj_move_counter(A5)
EnemyTick_ProximityChase_Loop10:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0018, D0
	ASR.w	#2, D0
	BCLR.b	#3, obj_sprite_flags(A5)
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	CMPI.b	#4, D1
	BLE.w	EnemyTick_ProximityChase_Loop11
	BSET.b	#3, obj_sprite_flags(A5)
EnemyTick_ProximityChase_Loop11:
	ASL.w	#3, D1
	ADD.w	D0, D1
	LEA	EnemyTick_ProximityChase_Loop11_Data, A0
	LEA	EnemyTick_ProximityChase_Loop11_Data2, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	BSR.w	CopyPositionToLinkedSprite
EnemyTick_ProximityChase_Loop2:
	JSR	AddSpriteToDisplayList
	RTS

InitEnemy_FleeChase:
	BSR.w	InitEnemyAI
	MOVE.w	#VRAM_TILE_ENEMY_BASE, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_2x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000E, obj_hitbox_half_h(A5)
	MOVE.l	#EnemyTick_FleeChase, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	RTS

EnemyTick_FleeChase:
	BSR.w	ProcessEnemyDamage
	BGT.w	EnemyTick_FleeChase_Loop
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS

EnemyTick_FleeChase_Loop:
	CLR.b	obj_hit_flag(A5)
	TST.b	Encounter_behavior_flag.w
	BNE.w	EnemyTick_FleeChase_Loop2
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyTick_FleeChase_Loop3
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#4, D0
	ANDI.b	#7, D0
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyTick_FleeChase_Loop4
EnemyTick_FleeChase_Loop3:
	JSR	GetRandomNumber
	MOVE.w	D0, D1
	ANDI.w	#$00FF, D0
	BNE.w	EnemyTick_FleeChase_Loop5
	ASR.w	#8, D1
	ANDI.w	#$00FF, D1
	ADDI.w	#$0078, D1
	MOVE.w	D1, obj_knockback_timer(A5)
EnemyTick_FleeChase_Loop5:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
EnemyTick_FleeChase_Loop4:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	EnemyTick_FleeChase_Loop6
	ADDQ.b	#1, obj_move_counter(A5)
EnemyTick_FleeChase_Loop6:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	BCLR.b	#3, obj_sprite_flags(A5)
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	CMPI.b	#4, D1
	BLE.w	EnemyTick_FleeChase_Loop7
	BSET.b	#3, obj_sprite_flags(A5)
EnemyTick_FleeChase_Loop7:
	ASL.w	#3, D1
	ADD.w	D0, D1
	LEA	EnemyAnimFrames_MeleeA_Main, A0
	LEA	EnemyAnimFrames_MeleeA_Child, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	BSR.w	CopyPositionToLinkedSprite
EnemyTick_FleeChase_Loop2:
	JSR	AddSpriteToDisplayList
	RTS

InitEnemy_Bouncing:
	BSR.w	InitEnemyAI
	MOVE.w	#VRAM_TILE_ENEMY_BASE, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000E, obj_hitbox_half_h(A5)
	MOVE.l	#EnemyTick_Bouncing, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_2x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	RTS

EnemyTick_Bouncing:
	BSR.w	ProcessEnemyDamage
	BGT.w	EnemyTick_Bouncing_Loop
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS

EnemyTick_Bouncing_Loop:
	CLR.b	obj_hit_flag(A5)
	TST.b	Encounter_behavior_flag.w
	BNE.w	EnemyTick_Bouncing_Loop2
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyTick_Bouncing_Loop3
	SUBQ.w	#1, obj_knockback_timer(A5)	
	MOVEA.l	Player_entity_ptr.w, A6	
	BSR.w	CalculateAngleBetweenObjects	
	ADDQ.b	#4, D0	
	ANDI.b	#7, D0	
	MOVE.b	D0, obj_direction(A5)	
	BRA.w	EnemyTick_Bouncing_Loop4	
EnemyTick_Bouncing_Loop3:
	TST.w	obj_attack_timer(A5)
	BEQ.w	EnemyTick_Bouncing_Loop5
	SUBQ.w	#1, obj_attack_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	EnemyTick_Bouncing_Loop6
EnemyTick_Bouncing_Loop5:
	JSR	GetRandomNumber
	ANDI.w	#$007F, D0
	BNE.w	EnemyTick_Bouncing_Loop7
	MOVE.w	#ENEMY_STALK_RECHECK_DELAY, obj_attack_timer(A5)
EnemyTick_Bouncing_Loop7:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
EnemyTick_Bouncing_Loop4:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
EnemyTick_Bouncing_Loop6:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$001C, D0
	ASR.w	#1, D0
	LEA	EnemyTick_Bouncing_Loop6_Data, A0
	LEA	EnemyTick_Bouncing_Loop6_Data2, A1
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.w	(A1,D0.w), obj_tile_index(A6)
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6)
	MOVE.w	obj_screen_x(A5), obj_screen_x(A6)
	MOVE.w	obj_screen_y(A5), D0
	SUBI.w	#$0018, D0
	MOVE.w	D0, obj_screen_y(A6)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
EnemyTick_Bouncing_Loop2:
	JSR	AddSpriteToDisplayList
	RTS

InitEnemy_ProjectileFire:
	BSR.w	InitEnemyAI
	BSR.w	SetObjectBoundsType1
	MOVE.l	#EnemyTick_ProjectileFire, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	RTS

EnemyTick_ProjectileFire:
	BSR.w	ProcessEnemyDamage
	BGT.w	EnemyTick_ProjectileFire_Loop
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS

EnemyTick_ProjectileFire_Loop:
	CLR.b	obj_hit_flag(A5)
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyTick_ProjectileFire_Loop2
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#4, D0
	ANDI.b	#7, D0
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyTick_ProjectileFire_Move
EnemyTick_ProjectileFire_Loop2:
	TST.w	obj_attack_timer(A5)
	BEQ.w	EnemyTick_ProjectileFire_Loop3
	SUBQ.w	#1, obj_attack_timer(A5)
	BRA.w	EnemyTick_ProjectileFire_Move
EnemyTick_ProjectileFire_Loop3:
	JSR	GetRandomNumber
	ANDI.b	#7, D0
	BNE.w	EnemyTick_ProjectileFire_Loop4
	BTST.l	#4, D0
	BEQ.w	EnemyTick_ProjectileFire_Loop5
	ADDQ.b	#1, obj_direction(A5)	
	BRA.w	EnemyTick_ProjectileFire_Loop6	
EnemyTick_ProjectileFire_Loop5:
	SUBQ.b	#1, obj_direction(A5)
EnemyTick_ProjectileFire_Loop6:
	ANDI.b	#7, obj_direction(A5)
	MOVE.w	#$0078, obj_attack_timer(A5)
	BRA.w	EnemyTick_ProjectileFire_Move
EnemyTick_ProjectileFire_Loop4:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	EnemyTick_ProjectileFire_Move_Loop
; loc_00009C42
EnemyTick_ProjectileFire_Move:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
EnemyTick_ProjectileFire_Move_Loop:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	EnemyTick_ProjectileFire_Move_Loop2
	ADDQ.b	#1, obj_move_counter(A5)
EnemyTick_ProjectileFire_Move_Loop2:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A4
	MOVEA.l	Player_entity_ptr.w, A6
	BTST.b	#7, (A4)
	BNE.w	EnemySplit_UpdateSprite
	MOVE.w	obj_world_x(A5), D0
	CMP.w	obj_world_x(A6), D0
	BEQ.w	EnemySplit_SpawnChild
	MOVE.w	obj_world_y(A5), D0
	CMP.w	obj_world_y(A6), D0
	BEQ.w	EnemySplit_SpawnChild
	CLR.b	obj_npc_busy_flag(A4)
	CLR.l	obj_vel_x(A4)
	CLR.l	obj_vel_y(A4)
	BRA.w	EnemySplit_UpdateSprite
; loc_00009CAA
EnemySplit_SpawnChild:
	BSET.b	#7, (A4)
	JSR	GetRandomNumber
	MOVE.b	D0, obj_move_counter(A4)
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A4)
	MOVE.l	obj_world_x(A5), obj_world_x(A4)
	MOVE.l	obj_world_y(A5), obj_world_y(A4)
	MOVE.w	obj_world_y(A4), D0
	MOVE.w	D0, obj_world_y(A4)
	MOVE.l	obj_pos_x_fixed(A5), D0
	ADD.l	D0, D0
	MOVE.l	D0, obj_pos_x_fixed(A4)
	MOVE.b	#1, obj_sprite_size(A4)
	MOVE.l	#ProjectileTick_Linear, obj_tick_fn(A4)
	MOVE.w	obj_max_hp(A5), obj_max_hp(A4)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A4)
	MOVE.b	D0, obj_direction(A5)
; loc_00009D00
EnemySplit_UpdateSprite:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0018, D0
	ASR.w	#2, D0
	BCLR.b	#3, obj_sprite_flags(A5)
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	CMPI.b	#4, D1
	BLE.w	EnemySplit_UpdateSprite_Loop
	BSET.b	#3, obj_sprite_flags(A5)
EnemySplit_UpdateSprite_Loop:
	ASL.w	#3, D1
	ADD.w	D0, D1
	LEA	EnemyAnimFrames_MeleeB_Main, A0
	LEA	EnemyAnimFrames_MeleeB_Child, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	BSR.w	CopyEnemyPositionToChildObject
	JSR	AddSpriteToDisplayList
	RTS

ProjectileTick_Linear:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	UpdateObjectScreenPosition
	BSR.w	HandlePlayerTakeDamage
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	ProjectileTick_Linear_Loop
	ADDQ.b	#1, obj_move_counter(A5)
ProjectileTick_Linear_Loop:
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	LEA	EnemyAnimFrames_Fireball, A2
	MOVE.w	(A2,D0.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList
	RTS

InitEnemy_StationaryShooter:
	BSR.w	InitEnemyAI
	BSR.w	SetEnemyGraphicsParams
	MOVE.l	#EnemyTick_StationaryShooter, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	RTS

EnemyTick_StationaryShooter:
	TST.b	obj_invuln_timer(A5)
	BLE.w	EnemyTick_StationaryShooter_Loop
	SUBQ.b	#1, obj_invuln_timer(A5)	
	BRA.w	EnemyTakeDamage_CheckDeath	
EnemyTick_StationaryShooter_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.w	EnemyTakeDamage_CheckDeath
	MOVE.b	#SOUND_HEAL, D0	
	JSR	QueueSoundEffect	
	MOVE.w	Player_str.w, D0	
	SUB.w	D0, obj_hp(A5)	
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A5)	
; loc_00009DE0
EnemyTakeDamage_CheckDeath:
	TST.w	obj_hp(A5)
	BGT.w	EnemyTakeDamage_CheckDeath_Loop
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)	
	RTS
	
EnemyTakeDamage_CheckDeath_Loop:
	CLR.b	obj_hit_flag(A5)
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.b	obj_next_offset(A6), D1
	LEA	(A6,D1.w), A4
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	BTST.b	#7, (A4)
	BNE.w	EnemyHoming_UpdateSprite
	JSR	GetRandomNumber
	MOVE.w	D0, D1
	ANDI.w	#$007F, D0
	BEQ.w	EnemyTakeDamage_CheckDeath_Loop2
	CLR.b	obj_npc_busy_flag(A4)
	CLR.l	obj_vel_x(A4)
	CLR.l	obj_vel_y(A4)
	BRA.w	EnemyHoming_UpdateSprite
EnemyTakeDamage_CheckDeath_Loop2:
	BSET.b	#7, (A4)
	JSR	GetRandomNumber
	MOVE.b	D0, obj_move_counter(A4)
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A4)
	MOVE.l	obj_world_x(A5), $E(A4)
	MOVE.l	obj_world_y(A5), obj_world_y(A4)
	MOVE.l	obj_pos_x_fixed(A5), obj_pos_x_fixed(A4)
	MOVE.w	#$0096, obj_attack_timer(A4)
	MOVE.b	#1, obj_sprite_size(A4)
	MOVE.l	#ProjectileTick_HomingAlt, obj_tick_fn(A4)
	MOVE.w	obj_max_hp(A5), obj_max_hp(A4)
; loc_00009E7A
EnemyHoming_UpdateSprite:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	BCLR.b	#3, obj_sprite_flags(A5)
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	CMPI.b	#4, D1
	BLE.w	EnemyHoming_UpdateSprite_Loop
	BSET.b	#3, obj_sprite_flags(A5)
EnemyHoming_UpdateSprite_Loop:
	ASL.w	#3, D1
	ADD.w	D0, D1
	LEA	EnemyAnimFrames_MeleeA_Main, A0
	LEA	EnemyAnimFrames_MeleeA_Child, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6)
	MOVE.w	obj_screen_x(A5), obj_screen_x(A6)
	MOVE.w	obj_screen_y(A5), D0
	SUBI.w	#$0010, D0
	MOVE.w	D0, obj_screen_y(A6)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
	JSR	AddSpriteToDisplayList
	RTS

; loc_00009EF6
ProjectileTick_HomingAlt:
	TST.w	obj_attack_timer(A5)
	BNE.w	ProjectileTick_HomingAlt_Loop
	BCLR.b	#7, (A5)
	CLR.b	obj_npc_busy_flag(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	ProjectileTick_HomingAlt_Loop2
ProjectileTick_HomingAlt_Loop:
	SUBQ.w	#1, obj_attack_timer(A5)
	MOVE.w	obj_attack_timer(A5), D0
	MOVE.w	D0, D1
	SUBQ.w	#1, D1
	EOR.w	D0, D1
	BTST.l	#4, D1
	BEQ.w	ProjectileTick_HomingAlt_Loop3
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
ProjectileTick_HomingAlt_Loop3:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	UpdateObjectScreenPosition
ProjectileTick_HomingAlt_Loop2:
	BSR.w	HandlePlayerTakeDamage
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	ProjectileTick_HomingAlt_Loop4
	ADDQ.b	#1, obj_move_counter(A5)
ProjectileTick_HomingAlt_Loop4:
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0018, D0
	ASR.w	#2, D0
	LEA	EnemyAnimFrames_Fireball, A2
	MOVE.w	(A2,D0.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList
	RTS

InitEnemy_IntermittentChase_Random:
	BSR.w	InitEnemyAI
	BSR.w	SetEnemyCollisionBounds
	CLR.b	Enemy_direction_flag.w
	MOVE.l	#EnemyTick_IntermittentChase, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	RTS

InitEnemy_IntermittentChase_Homing:
	BSR.w	InitEnemyAI
	BSR.w	SetEnemyCollisionBounds
	MOVE.b	#FLAG_TRUE, Enemy_direction_flag.w
	MOVE.l	#EnemyTick_IntermittentChase, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	RTS

EnemyTick_IntermittentChase:
	BSR.w	ProcessEnemyDamage
	BGT.w	EnemyTick_IntermittentChase_Loop
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS

EnemyTick_IntermittentChase_Loop:
	CLR.b	obj_hit_flag(A5)
	TST.b	Encounter_behavior_flag.w
	BNE.w	EnemyCharge_UpdateSprite_Loop
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyTick_IntermittentChase_Loop2
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#4, D0
	ANDI.b	#7, D0
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyTick_IntermittentChase_Move
EnemyTick_IntermittentChase_Loop2:
	TST.w	obj_attack_timer(A5)
	BEQ.w	EnemyTick_IntermittentChase_Loop3
	SUBQ.w	#1, obj_attack_timer(A5)
	BRA.w	EnemyTick_IntermittentChase_Move
EnemyTick_IntermittentChase_Loop3:
	JSR	GetRandomNumber
	ANDI.w	#$003F, D0
	BNE.w	EnemyTick_IntermittentChase_Loop4
	TST.b	Enemy_direction_flag.w
	BNE.w	EnemyTick_IntermittentChase_Loop5
	JSR	GetRandomNumber
	ANDI.b	#7, D0
	BRA.w	EnemyTick_IntermittentChase_Loop6
EnemyTick_IntermittentChase_Loop5:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
EnemyTick_IntermittentChase_Loop6:
	MOVE.b	D0, obj_direction(A5)
	MOVE.w	#$0046, obj_attack_timer(A5)
	BRA.w	EnemyTick_IntermittentChase_Move
EnemyTick_IntermittentChase_Loop4:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	EnemyTick_IntermittentChase_Move_Loop
; loc_0000A05A
EnemyTick_IntermittentChase_Move:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
EnemyTick_IntermittentChase_Move_Loop:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	EnemyCharge_UpdateSprite
	MOVE.w	obj_attack_timer(A5), D0
	CMPI.w	#$0028, D0
	BLE.w	EnemyCharge_UpdateSprite
	ADDQ.b	#1, obj_move_counter(A5)
; loc_0000A086
EnemyCharge_UpdateSprite:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	BCLR.b	#3, obj_sprite_flags(A5)
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	CMPI.b	#4, D1
	BLE.w	EnemyCharge_UpdateSprite_Loop2
	BSET.b	#3, obj_sprite_flags(A5)
EnemyCharge_UpdateSprite_Loop2:
	ASL.w	#3, D1
	ADD.w	D0, D1
	LEA	EnemyAnimFrames_MeleeA_Main, A0
	LEA	EnemyAnimFrames_MeleeA_Child, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	BSR.w	CopyPositionToLinkedSprite
EnemyCharge_UpdateSprite_Loop:
	JSR	AddSpriteToDisplayList
	RTS
	
InitEnemy_RandomShooter:
	BSR.w	InitEnemyAI
	BSR.w	InitEnemyProjectileSpeed
	MOVE.l	#EnemyTick_RandomShooter, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	RTS
	
EnemyTick_RandomShooter:
	BSR.w	ProcessEnemyDamage
	BGT.w	EnemyTick_RandomShooter_Loop
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS
	
EnemyTick_RandomShooter_Loop:
	CLR.b	obj_hit_flag(A5)
	TST.b	Encounter_behavior_flag.w
	BNE.w	EnemyTick_RandomShooter_Move_Loop
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyTick_RandomShooter_Loop2
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#4, D0
	ANDI.b	#7, D0
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyTick_RandomShooter_Move
EnemyTick_RandomShooter_Loop2:
	TST.w	obj_attack_timer(A5)
	BEQ.w	EnemyTick_RandomShooter_Loop3
	SUBQ.w	#1, obj_attack_timer(A5)
	BRA.w	EnemyTick_RandomShooter_Move
EnemyTick_RandomShooter_Loop3:
	JSR	GetRandomNumber
	ANDI.w	#$001F, D0
	BNE.w	EnemyTick_RandomShooter_Loop4
	JSR	GetRandomNumber
	ANDI.b	#7, D0
	MOVE.b	D0, obj_direction(A5)
	MOVE.w	#$0050, obj_attack_timer(A5)
	BRA.w	EnemyTick_RandomShooter_Move
EnemyTick_RandomShooter_Loop4:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	EnemyTick_RandomShooter_Move_Loop2
; loc_0000A18A
EnemyTick_RandomShooter_Move:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
EnemyTick_RandomShooter_Move_Loop2:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0038, D0
	ASR.w	#2, D0
	CMPI.w	#8, D0
	BLE.w	EnemyTick_RandomShooter_Move_Loop3
	CLR.b	obj_move_counter(A5)
	CLR.w	D0
EnemyTick_RandomShooter_Move_Loop3:
	LEA	EnemyAnimFrames_Fireball_B, A0
	LEA	EnemyAnimFrames_Fireball_C, A1
	CLR.w	D1
	MOVE.b	obj_next_offset(A5), D1
	LEA	(A5,D1.w), A6
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.w	(A1,D0.w), obj_tile_index(A6)
	BSR.w	CopyPositionToLinkedSprite
EnemyTick_RandomShooter_Move_Loop:
	JSR	AddSpriteToDisplayList
	RTS
	
InitEnemy_Teleporter:
	BSR.w	InitEnemyAI
	BSR.w	InitEnemyProjectileSpeed
	MOVE.l	#EnemyTick_Teleporter, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	RTS
	
EnemyTick_Teleporter:	
	TST.w	obj_knockback_timer(A5)
	BNE.w	EnemyTick_Teleporter_Loop
	CLR.w	D0
	JSR	GetRandomNumber
	ORI.w	#$0060, D0
	ANDI.w	#$007F, D0
	MOVE.w	D0, obj_knockback_timer(A5)
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	BSR.w	SetRandomEnemyPosition
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
EnemyTick_Teleporter_Loop:
	BSR.w	CheckAndUpdateBattleTimer
	BGT.w	EnemyTick_Teleporter_Loop2
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS
	
EnemyTick_Teleporter_Loop2:
	CLR.b	obj_hit_flag(A5)
	SUBQ.w	#1, obj_knockback_timer(A5)
	BSR.w	CheckEnemyCollision
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0038, D0
	ASR.w	#2, D0
	CMPI.w	#8, D0
	BLE.w	EnemyTick_Teleporter_Loop3
	CLR.b	obj_move_counter(A5)
	CLR.w	D0
EnemyTick_Teleporter_Loop3:
	LEA	EnemyAnimFrames_Fireball_B, A0
	LEA	EnemyAnimFrames_Fireball_C, A1
	CLR.w	D1
	MOVE.b	obj_next_offset(A5), D1
	LEA	(A5,D1.w), A6
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.w	(A1,D0.w), obj_tile_index(A6)
	BSR.w	CopyPositionToLinkedSprite
	JSR	AddSpriteToDisplayList
	BRA.w	EnemyTick_Teleporter_Loop4
EnemyTick_Teleporter_Loop4:
	RTS
	
InitEnemy_BurstFire:
	BSR.w	InitEnemyAI
	BSR.w	SetObjectBoundsType1
	MOVE.l	#EnemyTick_BurstFire, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A5)
	MOVE.l	#AddSpriteToDisplayList, obj_tick_fn(A6)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	BSR.w	SetRandomEnemyPosition
	RTS
	
EnemyTick_BurstFire:
	BSR.w	CheckAndUpdateBattleTimer
	BGT.w	EnemyTick_BurstFire_Loop
	MOVE.l	#BossDeathReward_MultiSprite, obj_tick_fn(A5)
	RTS
	
EnemyTick_BurstFire_Loop:
	CLR.b	obj_hit_flag(A5)
	MOVE.w	obj_attack_timer(A5), D0
	ANDI.w	#3, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	EnemyAiChasePauseJumpTable, A0
	JMP	(A0,D0.w)
; loc_0000A300
EnemyAiChasePauseJumpTable:
	BRA.w	EnemyAiChasePause_Tick
	BRA.w	EnemyAiChasePause_Tick_Loop
	BRA.w	EnemyAiChasePause_Tick
	BRA.w	EnemyAiChasePause_Tick_Loop2
; loc_0000A310
EnemyAiChasePause_Tick:
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyAiChasePause_Tick_Loop3
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	EnemyAiChasePause_HandleDamage
EnemyAiChasePause_Tick_Loop3:
	ADDQ.w	#1, obj_attack_timer(A5)
	MOVE.w	#ENEMY_KNOCKBACK_DURATION, obj_knockback_timer(A5)
	BRA.w	EnemyAiChasePause_HandleDamage
EnemyAiChasePause_Tick_Loop:
	SUBQ.w	#1, obj_knockback_timer(A5)
	BLE.w	EnemyAiChasePause_Tick_Loop4
	MOVEA.l	Player_entity_ptr.w, A6
	JSR	CalculateAngleToObjectCentered(PC)
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyAiChasePause_Move
EnemyAiChasePause_Tick_Loop4:
	ADDQ.w	#1, obj_attack_timer(A5)
	MOVE.w	#ENEMY_KNOCKBACK_DURATION, obj_knockback_timer(A5)
	BRA.w	EnemyAiChasePause_Move
EnemyAiChasePause_Tick_Loop2:
	MOVE.l	obj_world_x(A5), D1
	MOVE.l	obj_world_y(A5), D2
	MOVE.l	#$400, D3
	MOVE.w	obj_max_hp(A5), D4
	MOVE.b	#1, D5
	MOVE.b	obj_sprite_flags(A5), D6
	MOVE.w	#7, D7
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
EnemyAiChasePause_Tick_Loop2_Done:
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BSET.b	#7, (A6)
	MOVE.l	D1, obj_world_x(A6)
	MOVE.l	D2, obj_world_y(A6)
	MOVE.l	D3, obj_pos_x_fixed(A6)
	MOVE.w	D4, obj_max_hp(A6)
	MOVE.b	D5, obj_sprite_size(A6)
	MOVE.b	D6, obj_sprite_flags(A6)
	MOVE.b	D7, obj_direction(A6)
	MOVE.l	#ProjectileTick_Straight, obj_tick_fn(A6)
	DBF	D7, EnemyAiChasePause_Tick_Loop2_Done
	ADDQ.w	#1, obj_attack_timer(A5)
	MOVE.w	#ENEMY_KNOCKBACK_DURATION, obj_knockback_timer(A5)
	BRA.w	EnemyAiChasePause_HandleDamage
; loc_0000A3D2
EnemyAiChasePause_Move:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
; loc_0000A3DA
EnemyAiChasePause_HandleDamage:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	EnemyAiChasePause_HandleDamage_Loop
	ADDQ.b	#1, obj_move_counter(A5)
EnemyAiChasePause_HandleDamage_Loop:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0018, D0
	ASR.w	#2, D0
	BCLR.b	#3, obj_sprite_flags(A5)
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	CMPI.b	#4, D1
	BLE.w	EnemyAiChasePause_HandleDamage_Loop2
	BSET.b	#3, obj_sprite_flags(A5)
EnemyAiChasePause_HandleDamage_Loop2:
	ASL.w	#3, D1
	ADD.w	D0, D1
	LEA	EnemyAnimFrames_MeleeB_Main, A0
	LEA	EnemyAnimFrames_MeleeB_Child, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	BSR.w	CopyEnemyPositionToChildObject
	JSR	AddSpriteToDisplayList(PC)
	RTS
	
ProjectileTick_Straight:
	JSR	CalculateVelocityFromAngle(PC)
	JSR	ClampProjectileToScreenBounds(PC)
	BTST.b	#7, (A5)
	BEQ.b	ProjectileTick_Straight_Loop
	JSR	HandlePlayerTakeDamage(PC)
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	LEA	EnemyAnimFrames_Fireball, A2
	MOVE.w	(A2,D0.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList(PC)
ProjectileTick_Straight_Loop:
	RTS
	
InitEnemy_HomingShooter:
	BSR.w	InitEnemyAI
	BSR.w	SetEnemyGraphicsParams
	MOVE.l	#EnemyTick_HomingShooter, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	BSR.w	SetRandomEnemyPosition
	RTS
	
EnemyTick_HomingShooter:
	BSR.w	CheckAndUpdateBattleTimer
	BGT.w	EnemyTick_HomingShooter_Loop
	MOVE.l	#EnemyDeathReward_OneSprite, obj_tick_fn(A5)
	RTS
	
EnemyTick_HomingShooter_Loop:
	CLR.b	obj_hit_flag(A5)
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.b	obj_next_offset(A6), D1
	LEA	(A6,D1.w), A4
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	BTST.b	#7, (A4)
	BNE.w	EnemyMultiProjectile_UpdateSprite
	JSR	GetRandomNumber
	MOVE.w	D0, D1
	ANDI.w	#$007F, D0
	BEQ.w	EnemyTick_HomingShooter_Loop2
	CLR.b	obj_npc_busy_flag(A4)
	CLR.l	obj_vel_x(A4)
	CLR.l	obj_vel_y(A4)
	BRA.w	EnemyMultiProjectile_UpdateSprite
EnemyTick_HomingShooter_Loop2:
	MOVE.l	obj_world_x(A5), D1
	MOVE.l	obj_world_y(A5), D2
	MOVE.l	#$180, D3
	MOVE.w	obj_max_hp(A5), D4
	MOVE.b	#1, D5
	MOVE.b	obj_sprite_flags(A5), D6
	MOVE.w	#7, D7
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
EnemyTick_HomingShooter_Loop2_Done:
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BSET.b	#7, (A6)
	MOVE.l	D1, obj_world_x(A6)
	MOVE.l	D2, obj_world_y(A6)
	MOVE.l	D3, obj_pos_x_fixed(A6)
	MOVE.w	D4, obj_max_hp(A6)
	MOVE.b	D5, obj_sprite_size(A6)
	MOVE.b	D6, obj_sprite_flags(A6)
	MOVE.b	D7, obj_direction(A6)
	MOVE.w	#$003C, obj_attack_timer(A6)
	MOVE.w	#$00B4, obj_knockback_timer(A6)
	MOVE.l	#ProjectileTick_Homing, obj_tick_fn(A6)
	DBF	D7, EnemyTick_HomingShooter_Loop2_Done
; loc_0000A55E
EnemyMultiProjectile_UpdateSprite:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	BCLR.b	#3, obj_sprite_flags(A5)
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	CMPI.b	#4, D1
	BLE.w	EnemyMultiProjectile_UpdateSprite_Loop
	BSET.b	#3, obj_sprite_flags(A5)
EnemyMultiProjectile_UpdateSprite_Loop:
	ASL.w	#3, D1
	ADD.w	D0, D1
	LEA	EnemyAnimFrames_MeleeA_Main, A0
	LEA	EnemyAnimFrames_MeleeA_Child, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6)
	MOVE.w	obj_screen_x(A5), obj_screen_x(A6)
	MOVE.w	obj_screen_y(A5), D0
	SUBI.w	#$0010, D0
	MOVE.w	D0, obj_screen_y(A6)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
	JSR	AddSpriteToDisplayList
	RTS
	
ProjectileTick_Homing:
	TST.w	obj_knockback_timer(A5)
	BNE.w	ProjectileTick_Homing_Loop
	BCLR.b	#7, (A5)
	CLR.b	obj_npc_busy_flag(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	EnemyChase_Move_Loop
ProjectileTick_Homing_Loop:
	SUBQ.w	#1, obj_knockback_timer(A5)
	TST.w	obj_attack_timer(A5)
	BNE.w	ProjectileTick_Homing_Loop2
	MOVE.w	obj_knockback_timer(A5), D0
	MOVE.w	D0, D1
	SUBQ.w	#1, D1
	EOR.w	D0, D1
	BTST.l	#4, D1
	BEQ.w	EnemyChase_Move
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyChase_Move
ProjectileTick_Homing_Loop2:
	SUBQ.w	#1, obj_attack_timer(A5)
; loc_0000A628
EnemyChase_Move:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	UpdateObjectScreenPosition
EnemyChase_Move_Loop:
	BSR.w	HandlePlayerTakeDamage
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	EnemyChase_Move_Loop2
	ADDQ.b	#1, obj_move_counter(A5)
EnemyChase_Move_Loop2:
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	LEA	EnemyAnimFrames_Fireball, A2
	MOVE.w	(A2,D0.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList
	RTS
	
EnemyChildSpriteTick:
	JSR	AddSpriteToDisplayList
	RTS
	
CopyPositionToLinkedSprite:
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6)
	MOVE.w	obj_screen_x(A5), obj_screen_x(A6)
	MOVE.w	obj_screen_y(A5), D0
	SUBI.w	#$0010, D0
	MOVE.w	D0, obj_screen_y(A6)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
	RTS
	
CopyEnemyPositionToChildObject:
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6)
	MOVE.w	obj_screen_x(A5), obj_screen_x(A6)
	MOVE.w	obj_screen_y(A5), D0
	SUBI.w	#$0018, D0
	MOVE.w	D0, obj_screen_y(A6)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
	RTS
	
InitEnemy_FastBurstShooter:
	BSR.w	InitEnemyAI
	BSR.w	SetEnemyGraphicsParams
	MOVE.l	#EnemyTick_FastBurstShooter, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	BSR.w	SetRandomEnemyPosition
	RTS
	
EnemyTick_FastBurstShooter:
	BSR.w	CheckAndUpdateBattleTimer
	BGT.w	EnemyTick_FastBurstShooter_Loop
	MOVE.l	#BossDeathReward_MultiSprite, obj_tick_fn(A5)
	RTS
	
EnemyTick_FastBurstShooter_Loop:
	CLR.b	obj_hit_flag(A5)
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.b	obj_next_offset(A6), D1
	LEA	(A6,D1.w), A4
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	BTST.b	#7, (A4)
	BNE.w	EnemySpreadShot_UpdateSprite
	JSR	GetRandomNumber
	MOVE.w	D0, D1
	ANDI.w	#$007F, D0
	BEQ.w	EnemyTick_FastBurstShooter_Loop2
	CLR.b	obj_npc_busy_flag(A4)
	CLR.l	obj_vel_x(A4)
	CLR.l	obj_vel_y(A4)
	BRA.w	EnemySpreadShot_UpdateSprite
EnemyTick_FastBurstShooter_Loop2:
	MOVE.l	obj_world_x(A5), D1
	MOVE.l	obj_world_y(A5), D2
	MOVE.l	#$380, D3
	MOVE.w	obj_max_hp(A5), D4
	MOVE.b	#1, D5
	MOVE.b	obj_sprite_flags(A5), D6
	MOVE.w	#7, D7
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
EnemyTick_FastBurstShooter_Loop2_Done:
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BSET.b	#7, (A6)
	MOVE.l	D1, obj_world_x(A6)
	MOVE.l	D2, obj_world_y(A6)
	MOVE.l	D3, obj_pos_x_fixed(A6)
	MOVE.w	D4, obj_max_hp(A6)
	MOVE.b	D5, obj_sprite_size(A6)
	MOVE.b	D6, obj_sprite_flags(A6)
	MOVE.b	D7, obj_direction(A6)
	MOVE.l	#ProjectileTick_Straight, obj_tick_fn(A6)
	DBF	D7, EnemyTick_FastBurstShooter_Loop2_Done
; loc_0000A784
EnemySpreadShot_UpdateSprite:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	BCLR.b	#3, obj_sprite_flags(A5)
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	CMPI.b	#4, D1
	BLE.w	EnemySpreadShot_UpdateSprite_Loop
	BSET.b	#3, obj_sprite_flags(A5)
EnemySpreadShot_UpdateSprite_Loop:
	ASL.w	#3, D1
	ADD.w	D0, D1
	LEA	EnemyAnimFrames_MeleeA_Main, A0
	LEA	EnemyAnimFrames_MeleeA_Child, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6)
	MOVE.w	obj_screen_x(A5), obj_screen_x(A6)
	MOVE.w	obj_screen_y(A5), D0
	SUBI.w	#$0010, D0
	MOVE.w	D0, obj_screen_y(A6)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
	JSR	AddSpriteToDisplayList
	RTS
	
InitEnemy_SequentialFire:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	BSET.b	#7, (A6)
	JSR	GetRandomNumber
	MOVE.b	D0, obj_move_counter(A5)
	MOVE.l	#EnemyTick_SequentialFire, obj_tick_fn(A5)
	BSR.w	InitEnemyProjectileSpeed
	MOVE.l	#AddSpriteToDisplayList, obj_tick_fn(A6)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	CLR.b	obj_invuln_timer(A5)
	CLR.w	obj_attack_timer(A5)
	MOVE.w	#ENEMY_KNOCKBACK_DURATION, obj_knockback_timer(A5)
	RTS
	
EnemyTick_SequentialFire:
	BSR.w	CheckAndUpdateBattleTimer
	BGT.w	EnemyTick_SequentialFire_Loop
	MOVE.l	#EnemyDeathReward_OneSprite, obj_tick_fn(A5)
	RTS
	
EnemyTick_SequentialFire_Loop:
	CLR.b	obj_hit_flag(A5)
	MOVE.b	obj_attack_timer(A5), D0
	ANDI.w	#7, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	EnemyAiChaseFireJumpTable, A0
	JMP	(A0,D0.w)
; loc_0000A86E
EnemyAiChaseFireJumpTable:
	BRA.w	EnemyAiChaseFireJumpTable_Loop
	BRA.w	ProjectileTick_Phase1
	BRA.w	ProjectileTick_Phase2
	BRA.w	ProjectileTick_Phase3
	BRA.w	EnemyAiChaseFireJumpTable_Loop2
	BRA.w	ProjectileTick_Phase1	
	BRA.w	ProjectileTick_Phase2	
	BRA.w	ProjectileTick_Phase3	
EnemyAiChaseFireJumpTable_Loop:
	SUBQ.w	#1, obj_knockback_timer(A5)
	BLE.w	EnemyAiChaseFireJumpTable_Loop3
	MOVEA.l	Player_entity_ptr.w, A6
	JSR	CalculateAngleToObjectCentered(PC)
	MOVE.b	D0, obj_direction(A5)
	BRA.w	ProjectileTick_Move
EnemyAiChaseFireJumpTable_Loop3:
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	ADDQ.b	#1, obj_attack_timer(A5)
	MOVE.w	#ENEMY_KNOCKBACK_DURATION, obj_knockback_timer(A5)
	BRA.w	ProjectileTick_PostCollision
EnemyAiChaseFireJumpTable_Loop2:
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyAiChaseFireJumpTable_Loop4
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	BRA.w	ProjectileTick_Move
EnemyAiChaseFireJumpTable_Loop4:
	CLR.l	obj_vel_x(A5)	
	CLR.l	obj_vel_y(A5)	
	ADDQ.b	#1, obj_attack_timer(A5)	
	MOVE.w	#ENEMY_KNOCKBACK_DURATION, obj_knockback_timer(A5)	
	BRA.w	ProjectileTick_PostCollision	
; loc_0000A8EE
ProjectileTick_Phase1:
	SUBQ.w	#1, obj_knockback_timer(A5)
	BNE.w	ProjectileTick_PostCollision
	ADDQ.b	#1, obj_attack_timer(A5)
	MOVE.b	#8, $3B(A5)
	MOVE.w	#$001E, obj_knockback_timer(A5)
	BRA.w	ProjectileTick_PostCollision
; loc_0000A90A
ProjectileTick_Phase2:
	SUBQ.w	#1, obj_knockback_timer(A5)
	BNE.w	ProjectileTick_PostCollision
	MOVE.w	#8, obj_knockback_timer(A5)
	MOVEQ	#0, D7
	MOVE.b	$3B(A5), D7
	CLR.w	D0
	LEA	(A5), A6
ProjectileTick_Phase2_Done:
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, ProjectileTick_Phase2_Done
	BSET.b	#7, (A6)
	MOVE.w	obj_world_x(A5), obj_pos_x_fixed(A6)
	MOVE.w	obj_world_y(A5), D1
	SUBI.w	#$0018, D1
	MOVE.w	D1, $22(A6)
	MOVE.w	#$0018, obj_xp_reward(A6)
	MOVE.w	obj_max_hp(A5), obj_max_hp(A6)
	MOVE.b	#SPRITE_SIZE_2x1, obj_sprite_size(A6)
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6)
	MOVE.b	obj_direction(A5), D1
	ADDQ.b	#4, D1
	ANDI.b	#7, D1
	ASL.b	#5, D1
	MOVE.b	D1, obj_direction(A6)
	MOVE.l	#ProjectileTick_Spiral, obj_tick_fn(A6)
	SUBQ.b	#1, $3B(A5)
	BNE.w	ProjectileTick_PostCollision
	ADDQ.b	#1, obj_attack_timer(A5)
	MOVE.w	#$005A, obj_knockback_timer(A5)
	BRA.w	ProjectileTick_PostCollision
; loc_0000A98A
ProjectileTick_Phase3:
	SUBQ.w	#1, obj_knockback_timer(A5)
	BNE.w	ProjectileTick_PostCollision
	ADDQ.b	#1, obj_attack_timer(A5)
	JSR	GetRandomNumber
	ANDI.w	#$00F0, D0
	ADDI.w	#$003C, D0
	MOVE.w	D0, obj_knockback_timer(A5)
	BRA.w	ProjectileTick_PostCollision
; loc_0000A9AC
ProjectileTick_Move:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
ProjectileTick_PostCollision:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	BCLR.b	#3, obj_sprite_flags(A5)
	ADDQ.b	#1, obj_move_counter(A5)
	CMPI.b	#4, obj_direction(A5)
	BLE.b	ProjectileTick_PostCollision_Loop
	BSET.b	#3, obj_sprite_flags(A5)
ProjectileTick_PostCollision_Loop:
	MOVE.b	obj_attack_timer(A5), D0
	ANDI.w	#3, D0
	CMPI.b	#2, D0
	BGE.b	ProjectileTick_PostCollision_Loop2
	LEA	EnemyAnimFrames_Fireball_B, A0
	LEA	EnemyAnimFrames_Fireball_C, A1
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0018, D0
	ASR.w	#2, D0
	BRA.b	ProjectileTick_PostCollision_Loop3
ProjectileTick_PostCollision_Loop2:
	LEA	ProjectileTick_PostCollision_Loop2_Data, A0
	LEA	ProjectileTick_PostCollision_Loop2_Data2, A1
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
ProjectileTick_PostCollision_Loop3:
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.w	(A1,D0.w), obj_tile_index(A6)
	JSR	CopyPositionToLinkedSprite(PC)
	JSR	AddSpriteToDisplayList(PC)
	RTS
	
ProjectileTick_Spiral:
	ADDQ.w	#1, obj_xp_reward(A5)
	ADDQ.b	#4, obj_direction(A5)
	LEA	SineTable, A0
	MOVE.w	obj_xp_reward(A5), D0
	ASR.w	#1, D0
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	MOVE.b	(A0,D1.w), D2
	MOVE.b	$40(A0,D1.w), D3
	EXT.w	D2
	EXT.w	D3
	MULS.w	D0, D2
	MULS.w	D0, D3
	ASR.l	#7, D2
	ASR.l	#7, D3
	ADD.w	obj_pos_x_fixed(A5), D2
	ADD.w	$22(A5), D3
	MOVE.w	D2, obj_world_x(A5)
	MOVE.w	D3, obj_world_y(A5)
	CMPI.w	#0, obj_world_x(A5)
	BLE.w	ProjectileTick_Spiral_OutOfBounds
	CMPI.w	#BATTLE_FIELD_WIDTH, obj_world_x(A5)
	BGE.w	ProjectileTick_Spiral_OutOfBounds
	CMPI.w	#BATTLE_PROJ_Y_TOP, obj_world_y(A5)
	BLE.w	ProjectileTick_Spiral_OutOfBounds
	CMPI.w	#BATTLE_FIELD_BOTTOM, obj_world_y(A5)
	BLE.w	ProjectileTick_Spiral_OutOfBounds_Loop
; loc_0000AA96
ProjectileTick_Spiral_OutOfBounds:
	BCLR.b	#7, (A5)
	BRA.w	ProjectileTick_Spiral_OutOfBounds_Loop2
ProjectileTick_Spiral_OutOfBounds_Loop:
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	obj_screen_y(A5), obj_sort_key(A5)
	JSR	HandlePlayerTakeDamage(PC)
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	LEA	EnemyAnimFrames_Fireball, A2
	MOVE.w	(A2,D0.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList(PC)
ProjectileTick_Spiral_OutOfBounds_Loop2:
	RTS
	
InitEnemy_SpiralBurst:
	BSR.w	InitEnemyAI
	BSR.w	SetObjectBoundsType1
	MOVE.l	#EnemyTick_SpiralBurst, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A5)
	MOVE.l	#AddSpriteToDisplayList, obj_tick_fn(A6)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	JSR	GetRandomNumber
	ANDI.w	#$00F0, D0
	ADDI.w	#$003C, D0
	MOVE.w	D0, obj_knockback_timer(A5)
	RTS
	
EnemyTick_SpiralBurst:
	BSR.w	CheckAndUpdateBattleTimer
	BGT.w	EnemyTick_SpiralBurst_Loop
	MOVE.l	#EnemyDeathReward_OneSprite, obj_tick_fn(A5)	
	RTS
	
EnemyTick_SpiralBurst_Loop:
	CLR.b	obj_hit_flag(A5)
	MOVE.w	obj_attack_timer(A5), D0
	ANDI.w	#7, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	EnemyAiSpiralJumpTable, A0
	JMP	(A0,D0.w)
; loc_0000AB38
EnemyAiSpiralJumpTable:
	BRA.w	EnemyAiSpiralJumpTable_Loop
	BRA.w	ProjectileTick2_Phase1
	BRA.w	ProjectileTick2_Phase2
	BRA.w	ProjectileTick2_Phase3
	BRA.w	EnemyAiSpiralJumpTable_Loop2	
	BRA.w	ProjectileTick2_Phase1	
	BRA.w	ProjectileTick2_Phase2	
	BRA.w	ProjectileTick2_Phase3	
EnemyAiSpiralJumpTable_Loop:
	SUBQ.w	#1, obj_knockback_timer(A5)
	BLE.w	EnemyAiSpiralJumpTable_Loop3
	MOVEA.l	Player_entity_ptr.w, A6
	JSR	CalculateAngleToObjectCentered(PC)
	MOVE.b	D0, obj_direction(A5)
	BRA.w	ProjectileTick2_Move
EnemyAiSpiralJumpTable_Loop3:
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	ADDQ.w	#1, obj_attack_timer(A5)
	MOVE.w	#ENEMY_KNOCKBACK_DURATION, obj_knockback_timer(A5)
	BRA.w	ProjectileTick2_PostCollision
EnemyAiSpiralJumpTable_Loop2:
	TST.w	obj_knockback_timer(A5)	
	BEQ.w	EnemyAiSpiralJumpTable_Loop4	
	SUBQ.w	#1, obj_knockback_timer(A5)	
	MOVEA.l	Player_entity_ptr.w, A6	
	BSR.w	CalculateAngleBetweenObjects	
	MOVE.b	D0, obj_direction(A5)	
	BRA.w	ProjectileTick2_Move	
EnemyAiSpiralJumpTable_Loop4:
	CLR.l	obj_vel_x(A5)	
	CLR.l	obj_vel_y(A5)	
	ADDQ.b	#1, obj_attack_timer(A5)	
	MOVE.w	#ENEMY_KNOCKBACK_DURATION, obj_knockback_timer(A5)	
	BRA.w	ProjectileTick2_PostCollision	
; loc_0000ABB8
ProjectileTick2_Phase1:
	TST.w	obj_knockback_timer(A5)
	BEQ.w	ProjectileTick2_Phase1_Loop
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	JSR	CalculateAngleBetweenObjects(PC)
	MOVE.b	D0, obj_direction(A5)
	BRA.w	ProjectileTick2_PostCollision
ProjectileTick2_Phase1_Loop:
	ADDQ.w	#1, obj_attack_timer(A5)
	BRA.w	ProjectileTick2_PostCollision
; loc_0000ABDC
ProjectileTick2_Phase2:
	MOVE.w	#3, D7
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
ProjectileTick2_Phase2_Done:
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BSET.b	#7, (A6)
	MOVE.w	obj_world_x(A5), obj_orbit_center_x(A6)
	CLR.w	obj_hitbox_y_neg(A6)
	MOVE.w	obj_world_y(A5), D1
	MOVE.w	D1, obj_attack_timer(A6)
	CLR.w	obj_knockback_timer(A6)
	MOVE.w	#$0010, obj_xp_reward(A6)
	MOVE.w	obj_max_hp(A5), obj_max_hp(A6)
	MOVE.b	#SPRITE_SIZE_2x1, obj_sprite_size(A6)
	MOVE.l	#$800, obj_pos_x_fixed(A6)
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6)
	MOVE.b	obj_direction(A5), obj_direction(A6)
	MOVE.w	D7, D1
	ASL.w	#6, D1
	MOVE.b	D1, obj_orbit_angle(A6)
	MOVE.l	#ProjectileTick_OrbitingSpiral, obj_tick_fn(A6)
	DBF	D7, ProjectileTick2_Phase2_Done
	ADDQ.w	#1, obj_attack_timer(A5)
	MOVE.w	#$0078, obj_knockback_timer(A5)
	BRA.w	ProjectileTick2_PostCollision
; loc_0000AC54
ProjectileTick2_Phase3:
	SUBQ.w	#1, obj_knockback_timer(A5)
	BNE.w	ProjectileTick2_PostCollision
	CLR.w	obj_attack_timer(A5)	
	JSR	GetRandomNumber	
	ANDI.w	#$00F0, D0	
	ADDI.w	#$003C, D0	
	MOVE.w	D0, obj_knockback_timer(A5)	
	BRA.w	ProjectileTick2_PostCollision	
; loc_0000AC76
ProjectileTick2_Move:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
ProjectileTick2_PostCollision:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	ProjectileTick2_PostCollision_Loop
	ADDQ.b	#1, obj_move_counter(A5)
ProjectileTick2_PostCollision_Loop:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	BCLR.b	#3, obj_sprite_flags(A5)
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	CMPI.b	#4, D1
	BLE.w	ProjectileTick2_PostCollision_Loop2
	BSET.b	#3, obj_sprite_flags(A5)
ProjectileTick2_PostCollision_Loop2:
	ASL.w	#3, D1
	ADD.w	D0, D1
	LEA	EnemyAnimFrames_MeleeB_Main, A0
	LEA	EnemyAnimFrames_MeleeB_Child, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	BSR.w	CopyEnemyPositionToChildObject
	JSR	AddSpriteToDisplayList(PC)
	RTS
	
ProjectileTick_OrbitingSpiral:
	CMPI.w	#ORBITING_SPIRAL_ORBIT_COUNT, obj_xp_reward(A5)
	BLT.w	ProjectileTick_OrbitingSpiral_Loop
	JSR	CalculateVelocityFromAngle(PC)
	MOVE.l	obj_vel_x(A5), D0
	SUB.l	D0, obj_orbit_center_x(A5)
	MOVE.l	obj_vel_y(A5), D0
	SUB.l	D0, obj_attack_timer(A5)
	BRA.w	ProjectileTick_OrbitingSpiral_Loop2
ProjectileTick_OrbitingSpiral_Loop:
	ADDQ.w	#1, obj_xp_reward(A5)
ProjectileTick_OrbitingSpiral_Loop2:
	MOVE.w	obj_xp_reward(A5), D0
	ASR.w	#2, D0
	MOVE.w	D0, D1
	ASR.w	#1, D1
	ADD.b	D1, obj_orbit_angle(A5)
	LEA	SineTable, A0
	CLR.w	D1
	MOVE.b	obj_orbit_angle(A5), D1
	MOVE.b	(A0,D1.w), D2
	MOVE.b	$40(A0,D1.w), D3
	EXT.w	D2
	EXT.w	D3
	MULS.w	D0, D2
	MULS.w	D0, D3
	ASR.l	#7, D2
	ASR.l	#7, D3
	ADD.w	obj_orbit_center_x(A5), D2
	ADD.w	obj_attack_timer(A5), D3
	MOVE.w	D2, obj_world_x(A5)
	MOVE.w	D3, obj_world_y(A5)
	CMPI.w	#0, obj_world_x(A5)
	BLE.w	ProjectileTick_OrbitingSpiral_OutOfBounds
	CMPI.w	#BATTLE_FIELD_WIDTH, obj_world_x(A5)
	BGE.w	ProjectileTick_OrbitingSpiral_OutOfBounds
	CMPI.w	#BATTLE_PROJ_Y_TOP, obj_world_y(A5)
	BLE.w	ProjectileTick_OrbitingSpiral_OutOfBounds
	CMPI.w	#BATTLE_FIELD_BOTTOM, obj_world_y(A5)
	BLE.w	ProjectileTick_OrbitingSpiral_OutOfBounds_Loop
; loc_0000AD76
ProjectileTick_OrbitingSpiral_OutOfBounds:
	BCLR.b	#7, (A5)
	BRA.w	ProjectileTick_OrbitingSpiral_OutOfBounds_Loop2
ProjectileTick_OrbitingSpiral_OutOfBounds_Loop:
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	obj_screen_y(A5), obj_sort_key(A5)
	JSR	HandlePlayerTakeDamage(PC)
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	LEA	EnemyAnimFrames_Fireball, A2
	MOVE.w	(A2,D0.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList(PC)
ProjectileTick_OrbitingSpiral_OutOfBounds_Loop2:
	RTS
	
InitBoss_OrbShield:
	JSR	GetRandomNumber
	MOVE.b	D0, obj_move_counter(A5)
	ANDI.b	#6, D0
	MOVE.b	D0, obj_direction(A5)
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A5)
	MOVE.l	#BossTick_OrbShield, obj_tick_fn(A5)
	BSR.w	SetObjectBoundsType2
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	BSET.b	#7, (A6)
	MOVE.b	#SPRITE_SIZE_2x1, obj_sprite_size(A6)
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6)
	MOVE.w	#VRAM_TILE_ORBIT_BOSS_ORB, obj_tile_index(A6)
	MOVE.l	obj_world_x(A5), obj_world_x(A6)
	MOVE.l	obj_world_y(A5), D1
	SUBI.l	#$00080000, D1
	MOVE.l	D1, obj_world_y(A6)
	MOVE.l	#BossOrbTick_Static, obj_tick_fn(A6)
	CLR.l	obj_vel_x(A6)
	CLR.l	obj_vel_y(A6)
	MOVE.w	#4, obj_hitbox_half_w(A6)
	MOVE.w	#4, obj_hitbox_half_h(A6)
	MOVE.w	obj_max_hp(A5), obj_max_hp(A6)
	CLR.b	obj_invuln_timer(A6)
	MOVE.w	obj_world_x(A6), obj_screen_x(A6)
	MOVE.w	obj_world_y(A6), obj_screen_y(A6)
	MOVE.w	obj_world_y(A6), obj_sort_key(A6)
	CLR.w	obj_attack_timer(A6)
	MOVE.w	#4, obj_knockback_timer(A6)
	CLR.b	obj_invuln_timer(A5)
	CLR.w	obj_attack_timer(A5)
	CLR.w	obj_knockback_timer(A5)
	CLR.w	obj_vel_x(A5)
	CLR.w	obj_vel_y(A5)
	RTS
	
BossTick_OrbShield:
	TST.b	obj_invuln_timer(A5)
	BLE.w	BossTick_OrbShield_Loop
	SUBQ.b	#1, obj_invuln_timer(A5)	
	BRA.w	EnemyTakeDamage2_CheckDeath	
BossTick_OrbShield_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.w	EnemyTakeDamage2_CheckDeath
	MOVE.b	#SOUND_HEAL, D0	
	JSR	QueueSoundEffect	
	MOVE.w	Player_str.w, D0	
	SUB.w	D0, obj_hp(A5)	
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A5)	
; loc_0000AE94
EnemyTakeDamage2_CheckDeath:
	TST.w	obj_hp(A5)
	BGT.w	EnemyTakeDamage2_CheckDeath_Loop
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS
	
EnemyTakeDamage2_CheckDeath_Loop:
	CLR.b	obj_hit_flag(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	CMPI.b	#DEATH_SCATTER_ANGLE_COUNT, obj_attack_timer(A5)
	BCS.b	EnemyTakeDamage2_CheckDeath_Loop2
	JSR	GetRandomNumber
	ANDI.w	#$00FF, D0
	CMPI.w	#RANDOM_HALF_THRESHOLD, D0
	BLE.b	EnemyTakeDamage2_CheckDeath_Loop3
	CLR.b	obj_attack_timer(A5)
EnemyTakeDamage2_CheckDeath_Loop2:
	ADDQ.b	#1, obj_attack_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#2, D0
	ANDI.w	#7, D0
	ASL.w	#5, D0
	MOVE.w	D0, D5
	CLR.l	D0
	LEA	SineTable, A0
	MOVE.b	$40(A0,D5.w), D0
	ASL.w	#8, D0
	EXT.l	D0
	NEG.l	D0
	MOVE.l	D0, obj_vel_x(A5)
	CLR.l	D0
	LEA	SineTable, A0
	MOVE.b	(A0,D5.w), D0
	ASL.w	#8, D0
	EXT.l	D0
	MOVE.l	D0, obj_vel_y(A5)
EnemyTakeDamage2_CheckDeath_Loop3:
	BSR.w	CheckEnemyCollision
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	ADDQ.b	#1, obj_attack_timer(A6)
	CLR.w	D0
	MOVE.b	obj_knockback_timer(A6), D1
	EXT.w	D1
	CLR.l	D2
	MOVE.b	$3B(A6), D2
	CMPI.w	#$0040, D2
	BLE.b	EnemyTakeDamage2_CheckDeath_Loop4
	MOVE.w	#$FFFC, D1
EnemyTakeDamage2_CheckDeath_Loop4:
	TST.w	D2
	BGT.b	EnemyTakeDamage2_CheckDeath_Loop5
	CLR.w	D2
	MOVE.w	#4, D1
EnemyTakeDamage2_CheckDeath_Loop5:
	MOVE.b	D1, obj_knockback_timer(A6)
	ADD.w	D1, D2
	MOVE.b	D2, $3B(A6)
	CLR.w	D5
	MOVE.b	obj_attack_timer(A6), D5
	CLR.l	D0
	LEA	SineTable, A1
	MOVE.b	$40(A1,D5.w), D0
	ASL.w	#8, D0
	EXT.l	D0
	MULS.w	D2, D0
	ADD.l	obj_world_x(A5), D0
	MOVE.l	D0, obj_world_x(A6)
	CLR.l	D0
	LEA	SineTable, A1
	MOVE.b	(A1,D5.w), D0
	ASL.w	#8, D0
	EXT.l	D0
	MULS.w	D2, D0
	NEG.l	D0
	ADD.l	obj_world_y(A5), D0
	SUBI.l	#$00080000, D0
	MOVE.l	D0, obj_world_y(A6)
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D1
	ANDI.w	#$000C, D1
	LSR.w	#1, D1
	LEA	EnemyAnimFrames_Fireball_D, A0
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList(PC)
	RTS
	
InitBoss_MultiOrb:
	JSR	GetRandomNumber
	MOVE.b	D0, obj_move_counter(A5)
	ANDI.b	#6, D0
	MOVE.b	D0, obj_direction(A5)
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A5)
	BSR.w	SetObjectBoundsType2
	MOVE.l	#BossTick_MultiOrb, obj_tick_fn(A5)
	MOVE.b	obj_sprite_flags(A5), D2
	LEA	(A5), A6
	MOVE.w	#8, D7
InitBoss_MultiOrb_Done:
	LEA	(A6), A4
	CLR.w	D0
	MOVE.b	obj_next_offset(A4), D0
	LEA	(A4,D0.w), A6
	BSET.b	#7, (A6)
	MOVE.b	#SPRITE_SIZE_2x1, obj_sprite_size(A6)
	MOVE.b	D2, obj_sprite_flags(A6)
	MOVE.w	#VRAM_TILE_ORBIT_BOSS_ORB, obj_tile_index(A6)
	MOVE.l	obj_world_x(A5), obj_world_x(A6)
	MOVE.l	obj_world_y(A5), D1
	SUBI.l	#$00080000, D1
	MOVE.l	D1, obj_world_y(A6)
	MOVE.l	#BossOrbTick_Static, obj_tick_fn(A6)
	CLR.l	obj_vel_x(A6)
	CLR.l	obj_vel_y(A6)
	MOVE.w	#4, obj_hitbox_half_w(A6)
	MOVE.w	#4, obj_hitbox_half_h(A6)
	MOVE.w	obj_max_hp(A5), obj_max_hp(A6)
	CLR.b	obj_invuln_timer(A6)
	MOVE.w	obj_world_x(A6), obj_screen_x(A6)
	MOVE.w	obj_world_y(A6), obj_screen_y(A6)
	MOVE.w	obj_world_y(A6), obj_sort_key(A6)
	DBF	D7, InitBoss_MultiOrb_Done
	CLR.b	obj_invuln_timer(A5)
	CLR.w	obj_attack_timer(A5)
	CLR.w	obj_knockback_timer(A5)
	CLR.w	obj_vel_x(A5)
	CLR.w	obj_vel_y(A5)
	RTS
	
BossTick_MultiOrb:
	TST.b	obj_invuln_timer(A5)
	BLE.w	BossTick_MultiOrb_Loop
	SUBQ.b	#1, obj_invuln_timer(A5)	
	BRA.w	BossTakeDamage_CheckDeath	
BossTick_MultiOrb_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.w	BossTakeDamage_CheckDeath
	MOVE.b	#SOUND_HEAL, D0	
	JSR	QueueSoundEffect	
	MOVE.w	Player_str.w, D0	
	SUB.w	D0, obj_hp(A5)	
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A5)	
; loc_0000B09A
BossTakeDamage_CheckDeath:
	TST.w	obj_hp(A5)
	BGT.w	BossTakeDamage_CheckDeath_Loop
	MOVE.l	#BossDeathReward_MultiSprite, obj_tick_fn(A5)	
	RTS
	
BossTakeDamage_CheckDeath_Loop:
	CLR.b	obj_hit_flag(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	TST.b	$3B(A5)
	BNE.w	BossTakeDamage_CheckDeath_Loop2
	CMPI.b	#DEATH_SCATTER_ANGLE_COUNT, obj_attack_timer(A5)
	BCS.b	BossTakeDamage_CheckDeath_Loop3
	JSR	GetRandomNumber
	ANDI.w	#$00FF, D0
	CMPI.w	#RANDOM_HALF_THRESHOLD, D0
	BLE.b	BossTakeDamage_CheckDeath_Loop4
	CLR.b	obj_attack_timer(A5)
BossTakeDamage_CheckDeath_Loop3:
	ADDQ.b	#1, obj_attack_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#2, D0
	ANDI.w	#7, D0
	ASL.w	#5, D0
	MOVE.w	D0, D5
	CLR.l	D0
	LEA	SineTable, A0
	MOVE.b	$40(A0,D5.w), D0
	ASL.w	#8, D0
	EXT.l	D0
	NEG.l	D0
	MOVE.l	D0, obj_vel_x(A5)
	CLR.l	D0
	LEA	SineTable, A0
	MOVE.b	(A0,D5.w), D0
	ASL.w	#8, D0
	EXT.l	D0
	MOVE.l	D0, obj_vel_y(A5)
	BSR.w	CheckEnemyCollision
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.w	#8, D7
	LEA	(A5), A4
BossTakeDamage_CheckDeath_Loop3_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A4), D0
	LEA	(A4,D0.w), A4
	MOVE.l	obj_world_x(A5), obj_world_x(A4)
	MOVE.l	obj_world_y(A5), D0
	SUBI.l	#$00080000, D0
	MOVE.l	D0, obj_world_y(A4)
	DBF	D7, BossTakeDamage_CheckDeath_Loop3_Done
	BRA.w	BossTakeDamage_CheckDeath_Loop5
BossTakeDamage_CheckDeath_Loop4:
	MOVE.b	#$21, $3B(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#2, D0
	ANDI.w	#7, D0
	ASL.w	#5, D0
	MOVE.w	D0, obj_knockback_timer(A5)
BossTakeDamage_CheckDeath_Loop2:
	LEA	(A5), A0
	SUBQ.b	#1, $3B(A5)
	MOVE.w	#8, D7
	CLR.l	D0
	MOVE.b	$3B(A5), D0
	ASR.w	#1, D0
	SUBQ.w	#8, D0
	BGE.b	BossTakeDamage_CheckDeath_Loop6
	NEG.w	D0
BossTakeDamage_CheckDeath_Loop6:
	MOVE.w	obj_knockback_timer(A5), D5
	MOVEQ	#8, D6
	SUB.w	D0, D6
	ADD.w	D6, D6
	MOVE.w	D6, D3
	LEA	(A5), A6
BossTakeDamage_CheckDeath_Loop6_Done:
	LEA	(A6), A4
	MOVE.w	D6, D1
	CLR.w	D0
	MOVE.b	obj_next_offset(A4), D0
	LEA	(A4,D0.w), A6
	CLR.l	D0
	LEA	SineTable, A1
	MOVE.b	$40(A1,D5.w), D0
	ASL.w	#8, D0
	EXT.l	D0
	MULS.w	D1, D0
	ADD.l	$E(A0), D0
	MOVE.l	D0, obj_world_x(A6)
	CLR.l	D0
	LEA	SineTable, A1
	MOVE.b	(A1,D5.w), D0
	ASL.w	#8, D0
	EXT.l	D0
	MULS.w	D1, D0
	NEG.l	D0
	ADD.l	$12(A0), D0
	SUBI.l	#$00080000, D0
	MOVE.l	D0, obj_world_y(A6)
	ADD.w	D3, D6
	DBF	D7, BossTakeDamage_CheckDeath_Loop6_Done
	LEA	(A0), A5
	BSR.w	CheckEnemyCollision
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
BossTakeDamage_CheckDeath_Loop5:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D1
	ANDI.w	#$000C, D1
	LSR.w	#1, D1
	LEA	EnemyAnimFrames_Fireball_D, A0
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList(PC)
	RTS
	
InitBoss_OrbRing:
	JSR	GetRandomNumber
	MOVE.b	D0, obj_move_counter(A5)
	ANDI.b	#6, D0
	MOVE.b	D0, obj_direction(A5)
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A5)
	MOVE.l	#BossTick_OrbRing, obj_tick_fn(A5)
	BSR.w	SetObjectBoundsType2
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	BSET.b	#7, (A6)
	MOVE.l	obj_world_x(A5), obj_world_x(A6)
	MOVE.l	obj_world_y(A5), D1
	SUBI.l	#$00100000, D1
	MOVE.l	D1, obj_world_y(A6)
	MOVE.b	#0, obj_attack_timer(A6)
	MOVE.b	#SPRITE_SIZE_2x1, obj_sprite_size(A6)
	MOVE.b	obj_sprite_flags(A5), D2
	MOVE.b	D2, obj_sprite_flags(A6)
	MOVE.w	#$0199, D3
	MOVE.w	D3, obj_tile_index(A6)
	MOVE.l	#BossOrbTick_Static, obj_tick_fn(A6)
	CLR.l	obj_vel_x(A6)
	CLR.l	obj_vel_y(A6)
	MOVE.w	#4, obj_hitbox_half_w(A6)
	MOVE.w	#4, obj_hitbox_half_h(A6)
	CLR.b	obj_invuln_timer(A6)
	MOVE.w	obj_world_x(A6), obj_screen_x(A6)
	MOVE.w	obj_world_y(A6), obj_screen_y(A6)
	MOVE.w	obj_world_y(A6), obj_sort_key(A6)
	MOVE.w	#7, D7
InitBoss_OrbRing_Done:
	LEA	(A6), A4
	CLR.w	D0
	MOVE.b	obj_next_offset(A4), D0
	LEA	(A4,D0.w), A6
	BSET.b	#7, (A6)
	MOVE.b	#SPRITE_SIZE_2x1, obj_sprite_size(A6)
	MOVE.b	D2, obj_sprite_flags(A6)
	MOVE.w	D3, obj_tile_index(A6)
	MOVE.b	$3A(A4), D0
	ADDI.w	#$0010, D0
	MOVE.b	D0, obj_attack_timer(A6)
	JSR	CalculateCircularPosition(PC)
	MOVE.l	#BossOrbTick_Static, obj_tick_fn(A6)
	CLR.l	obj_vel_x(A6)
	CLR.l	obj_vel_y(A6)
	MOVE.w	#4, obj_hitbox_half_w(A6)
	MOVE.w	#4, obj_hitbox_half_h(A6)
	MOVE.w	obj_max_hp(A5), obj_max_hp(A6)
	CLR.b	obj_invuln_timer(A6)
	MOVE.w	obj_world_x(A6), obj_screen_x(A6)
	MOVE.w	obj_world_y(A6), obj_screen_y(A6)
	MOVE.w	obj_world_y(A6), obj_sort_key(A6)
	DBF	D7, InitBoss_OrbRing_Done
	CLR.b	obj_invuln_timer(A5)
	CLR.w	obj_attack_timer(A5)
	CLR.w	obj_knockback_timer(A5)
	CLR.w	obj_vel_x(A5)
	CLR.w	obj_vel_y(A5)
	RTS
	
BossTick_OrbRing:
	TST.b	obj_invuln_timer(A5)
	BLE.w	BossTick_OrbRing_Loop
	SUBQ.b	#1, obj_invuln_timer(A5)	
	BRA.w	BossTakeDamage2_CheckDeath	
BossTick_OrbRing_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.w	BossTakeDamage2_CheckDeath
	MOVE.b	#SOUND_HEAL, D0	
	JSR	QueueSoundEffect	
	MOVE.w	Player_str.w, D0	
	SUB.w	D0, obj_hp(A5)	
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A5)	
; loc_0000B35A
BossTakeDamage2_CheckDeath:
	TST.w	obj_hp(A5)
	BGT.w	BossTakeDamage2_CheckDeath_Loop
	MOVE.l	#BossDeathReward_MultiSprite, obj_tick_fn(A5)
	RTS
	
BossTakeDamage2_CheckDeath_Loop:
	CLR.b	obj_hit_flag(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	CMPI.b	#DEATH_SCATTER_ANGLE_COUNT, obj_knockback_timer(A5)
	BCS.b	BossTakeDamage2_CheckDeath_Loop2
	JSR	GetRandomNumber
	ANDI.w	#$00FF, D0
	CMPI.w	#RANDOM_HALF_THRESHOLD, D0
	BLE.b	BossTakeDamage2_CheckDeath_Loop3
	CLR.b	obj_knockback_timer(A5)
BossTakeDamage2_CheckDeath_Loop2:
	ADDQ.b	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#2, D0
	ANDI.w	#7, D0
	ASL.w	#5, D0
	MOVE.w	D0, D5
	CLR.l	D0
	LEA	SineTable, A0
	MOVE.b	$40(A0,D5.w), D0
	ASL.w	#8, D0
	EXT.l	D0
	NEG.l	D0
	MOVE.l	D0, obj_vel_x(A5)
	CLR.l	D0
	LEA	SineTable, A0
	MOVE.b	(A0,D5.w), D0
	ASL.w	#8, D0
	EXT.l	D0
	MOVE.l	D0, obj_vel_y(A5)
BossTakeDamage2_CheckDeath_Loop3:
	BSR.w	CheckEnemyCollision
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D1
	ANDI.w	#$000C, D1
	LSR.w	#1, D1
	LEA	EnemyAnimFrames_Fireball_D, A0
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	LEA	(A5), A0
	CLR.w	D5
	MOVE.b	obj_next_offset(A5), D5
	LEA	(A5,D5.w), A6
	MOVE.l	obj_world_x(A5), obj_world_x(A6)
	MOVE.l	obj_world_y(A5), D1
	SUBI.l	#$00100000, D1
	MOVE.l	D1, obj_world_y(A6)
	BSET.b	#7, (A6)
	CLR.w	D6
	MOVE.w	#7, D7
BossTakeDamage2_CheckDeath_Loop3_Done:
	MOVE.b	$1B(A0), D0
	ANDI.b	#7, D0
	CMPI.b	#6, D0
	BLT.b	BossTakeDamage2_CheckDeath_Loop4
	LEA	(A6), A4
	LEA	(A4), A5
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#2, D0
	ANDI.w	#7, D0
	ASL.w	#5, D0
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A6
	CLR.w	D1
	MOVE.b	obj_attack_timer(A6), D1
	ADD.b	D6, D1
	ANDI.w	#$00FF, D1
	MOVE.w	#1, D2
	SUB.w	D1, D0
	BGE.b	BossTakeDamage2_CheckDeath_Loop5
	NEG.w	D0
	NEG.w	D2
BossTakeDamage2_CheckDeath_Loop5:
	CMPI.w	#$0080, D0
	BLE.b	BossTakeDamage2_CheckDeath_Loop6
	NEG.w	D2
BossTakeDamage2_CheckDeath_Loop6:
	ADD.w	D2, D1
	ADD.w	D2, D6
	MOVE.b	D1, obj_attack_timer(A6)
BossTakeDamage2_CheckDeath_Loop4:
	JSR	CalculateCircularPosition(PC)
	BSET.b	#7, (A6)
	DBF	D7, BossTakeDamage2_CheckDeath_Loop3_Done
	LEA	(A0), A5
	JSR	AddSpriteToDisplayList(PC)
	RTS

BossOrbTick_Static:	
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	obj_world_y(A5), obj_sort_key(A5)
	JSR	HandlePlayerTakeDamage(PC)
	MOVE.w	obj_world_x(A5), D0
	CMPI.w	#0, D0
	BLE.w	BossOrbTick_Return
	CMPI.w	#BATTLE_FIELD_WIDTH, D0
	BGE.w	BossOrbTick_Return
	MOVE.w	obj_world_y(A5), D0
	TST.w	D0
	BLE.w	BossOrbTick_Return
	CMPI.w	#BATTLE_FIELD_BOTTOM, D0
	BGE.w	BossOrbTick_Return
	JSR	AddSpriteToDisplayList(PC)
BossOrbTick_Return:
	RTS

CalculateCircularPosition:
	CLR.w	D5
	MOVE.b	obj_attack_timer(A6), D5
	LEA	SineTable, A2
	MOVE.b	$40(A2,D5.w), D0
	EXT.w	D0
	ASR.w	#4, D0
	ADD.w	obj_world_x(A4), D0
	MOVE.w	D0, obj_world_x(A6)
	LEA	SineTable, A2
	MOVE.b	(A2,D5.w), D0
	EXT.w	D0
	ASR.w	#4, D0
	NEG.w	D0
	ADD.w	obj_world_y(A4), D0
	MOVE.w	D0, obj_world_y(A6)
	RTS

BossDeathReward_MultiSprite:
	MOVE.b	#SOUND_MAGIC_EFFECT, D0
	JSR	QueueSoundEffect
	MOVEQ	#0, D0
	MOVE.w	obj_xp_reward(A5), D0
	MOVE.l	D0, Transaction_amount.w
	JSR	AddExperiencePoints
	MOVEQ	#0, D0
	MOVE.w	obj_kim_reward(A5), D0
	MOVE.l	D0, Transaction_amount.w
	JSR	AddPaymentAmount
	SUBQ.w	#1, Number_Of_Enemies.w
	CLR.b	obj_move_counter(A5)
	MOVE.l	#EnemyDeathAnimation, obj_tick_fn(A5)
	MOVE.b	#NPC_ATTR_PAL3, obj_sprite_flags(A5)
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A5)
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	BCLR.b	#7, (A6)
	MOVE.w	#8, D6
BossDeathReward_MultiSprite_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BCLR.b	#7, (A6)
	DBF	D6, BossDeathReward_MultiSprite_Done
	RTS

EnemyDirectionAnimTable:
	dc.b	$06, $05, $05, $04, $06, $07, $07, $00, $02, $03, $03, $04, $02, $01, $01, $00 
EnemyPositionOffsetTable:
	dc.w	0, -16
	dc.w	-8, -8 
	dc.w	-16, 0 
	dc.w	-8, 8 
	dc.w	0, 16 
	dc.w	8, 8 
	dc.w	16, 0 
	dc.w	8, -8 

ApplyDamageToPlayer:
	MOVE.w	obj_max_hp(A5), D1
	MOVE.w	Player_ac.w, D0
	ASR.w	#3, D0
	SUB.w	D0, D1
	BGT.w	ApplyDamageToPlayer_Loop
	MOVEQ	#1, D1
ApplyDamageToPlayer_Loop:
	SUB.w	D1, Player_hp.w
	BGE.w	ApplyDamageToPlayer_Loop2
	CLR.w	Player_hp.w
ApplyDamageToPlayer_Loop2:
	RTS

SetRandomEnemyPosition:
	CLR.w	D0
	JSR	GetRandomNumber
	ANDI.w	#$01FF, D0
	CMPI.w	#1, D0
	BGT.w	SetRandomEnemyPosition_Loop
	MOVE.w	#1, D1
	SUB.w	D0, D1
	MOVE.w	#SPAWN_ZONE_X_MAX, D0
	SUB.w	D1, D0
	BRA.w	SetRandomEnemyPosition_SetX
SetRandomEnemyPosition_Loop:
	CMPI.w	#SPAWN_ZONE_X_MAX, D0
	BLT.w	SetRandomEnemyPosition_SetX
	SUBI.w	#SPAWN_ZONE_X_MAX, D0
	ADDQ.w	#1, D0
; loc_0000B5FA
SetRandomEnemyPosition_SetX:
	MOVE.w	D0, obj_world_x(A5)
	CLR.w	D0
	JSR	GetRandomNumber
	ANDI.w	#$00FF, D0
	CMPI.w	#SPAWN_ZONE_Y_MIN, D0
	BGT.w	SetRandomEnemyPosition_SetX_Loop
	MOVE.w	#SPAWN_ZONE_Y_MIN, D1
	SUB.w	D0, D1
	MOVE.w	#SPAWN_ZONE_Y_MAX, D0
	SUB.w	D1, D0
	BRA.w	SetRandomEnemyPosition_SetX_Loop2
SetRandomEnemyPosition_SetX_Loop:
	CMPI.w	#SPAWN_ZONE_Y_MAX, D0
	BLT.b	SetRandomEnemyPosition_SetX
	SUBI.w	#SPAWN_ZONE_Y_MAX, D0
	ADDI.w	#SPAWN_ZONE_Y_MIN, D0
SetRandomEnemyPosition_SetX_Loop2:
	MOVE.w	D0, obj_world_y(A5)
	MOVE.w	obj_world_x(A5), D0
	CMPI.w	#SPAWN_SAFE_X_MIN, D0
	BLT.w	SetRandomEnemyPosition_Return
	CMPI.w	#BATTLE_FIELD_BOTTOM, D0
	BGT.w	SetRandomEnemyPosition_Return
	MOVE.w	obj_world_y(A5), D0
	CMPI.w	#SPAWN_SAFE_Y_MIN, D0
	BLT.w	SetRandomEnemyPosition_Return
	CMPI.w	#SPAWN_SAFE_Y_MAX, D0
	BGT.w	SetRandomEnemyPosition_Return
	BRA.w	SetRandomEnemyPosition
SetRandomEnemyPosition_Return:
	RTS
	
InitEnemyAI:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	BSET.b	#7, (A6)
	JSR	GetRandomNumber
	MOVE.b	D0, obj_move_counter(A5)
	ANDI.b	#6, D0
	MOVE.b	D0, obj_direction(A5)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	CLR.b	obj_invuln_timer(A5)
	CLR.w	obj_attack_timer(A5)
	CLR.w	obj_knockback_timer(A5)
	RTS
	
ProcessEnemyDamage:
	TST.b	obj_invuln_timer(A5)
	BLE.w	ProcessEnemyDamage_Loop
	SUBQ.b	#1, obj_invuln_timer(A5)
	BRA.w	EnemyTakeDamage_Done
ProcessEnemyDamage_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.w	EnemyTakeDamage_Done
	MOVE.b	#SOUND_HEAL, D0
	JSR	QueueSoundEffect
	MOVE.w	#$0078, obj_knockback_timer(A5)
	MOVE.w	Player_str.w, D0
	SUB.w	D0, obj_hp(A5)
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A5)
; loc_0000B6CE
EnemyTakeDamage_Done:
	TST.w	obj_hp(A5)
	RTS
	
CheckAndUpdateBattleTimer:
	TST.b	obj_invuln_timer(A5)
	BLE.w	CheckAndUpdateBattleTimer_Loop
	SUBQ.b	#1, obj_invuln_timer(A5)
	BRA.w	EnemyTakeDamage3_Done
CheckAndUpdateBattleTimer_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.w	EnemyTakeDamage3_Done
	MOVE.b	#SOUND_HEAL, D0
	JSR	QueueSoundEffect
	MOVE.w	Player_str.w, D0
	SUB.w	D0, obj_hp(A5)
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A5)
; loc_0000B704
EnemyTakeDamage3_Done:
	TST.w	obj_hp(A5)
	RTS
	
SetEnemyGraphicsParams:
	MOVE.w	#VRAM_TILE_ENEMY_BASE, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_2x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000E, obj_hitbox_half_h(A5)
	RTS
	
SetObjectBoundsType2:
	MOVE.w	#VRAM_TILE_ENEMY_ALT, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000E, obj_hitbox_half_h(A5)
	RTS
	
SetObjectBoundsType1:
	MOVE.w	#VRAM_TILE_ENEMY_BASE, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000C, obj_hitbox_half_h(A5)
	RTS
	
InitEnemyProjectileSpeed:
	MOVE.w	#VRAM_TILE_ENEMY_BASE, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_2x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000C, obj_hitbox_half_h(A5)
	RTS
	
SetEnemyCollisionBounds:
	MOVE.w	#VRAM_TILE_ENEMY_BASE, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_2x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000C, obj_hitbox_half_h(A5)
	RTS
	
;loc_0000B78C:
EnemyStartingPositions:
	dc.w	$1E, $40
	dc.w	$5E, $40
	dc.w	$9E, $40
	dc.w	$DE, $40
	dc.w	$1E, $A0
	dc.w	$5E, $A0
	dc.w	$9E, $A0
	dc.w	$DE, $A0 
InitBattleEntities:
	LEA	BattleEntityInitJumpTable, A0
	MOVE.w	Battle_type.w, D0
	ANDI.w	#$000F, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	JSR	(A0,D0.w)
	RTS
	
; loc_0000B7C4
BattleEntityInitJumpTable:
	BRA.w	InitBoss1_Normal
	BRA.w	InitDemonBoss_Normal
	BRA.w	InitTwoHeadedDragon_Normal
	BRA.w	InitTwoHeadedDragon_Hard
	BRA.w	InitHydraBoss_Normal
	BRA.w	InitRingGuardian_Normal
	BRA.w	InitRingGuardian_Hard
	BRA.w	InitRingGuardian_VeryHard
	BRA.w	InitBoss1_Hard
	BRA.w	InitBoss1_VeryHard
	BRA.w	InitDemonBoss_Hard
	BRA.w	InitTwoHeadedDragon_VeryHard
	BRA.w	InitHydraBoss_Hard
	BRA.w	InitOrbitBoss
InitBoss1_Normal:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#BOSS_DMG_RING_NORMAL, obj_max_hp(A6)
	MOVE.w	#BOSS_HP_RING_NORMAL, obj_hp(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.w	#BOSS_DMG_RING_NORMAL, obj_max_hp(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	MOVE.w	#BOSS_DMG_RING_NORMAL, obj_max_hp(A6)
	BRA.w	InitBoss1_Common
InitBoss1_Hard:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#BOSS_DMG_RING_HARD, obj_max_hp(A6)
	MOVE.w	#BOSS_HP_RING_HARD, obj_hp(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.w	#BOSS_DMG_RING_HARD, obj_max_hp(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	MOVE.w	#BOSS_DMG_RING_HARD, obj_max_hp(A6)
	BRA.w	InitBoss1_Common
InitBoss1_VeryHard:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#BOSS_DMG_RING_VERYHARD, obj_max_hp(A6)
	MOVE.w	#BOSS_HP_RING_HARD, obj_hp(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.w	#BOSS_DMG_RING_VERYHARD, obj_max_hp(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	MOVE.w	#BOSS_DMG_RING_VERYHARD, obj_max_hp(A6)
InitBoss1_Common:
	MOVEA.l	Enemy_list_ptr.w, A6
	CLR.w	Boss_ai_state.w
	CLR.b	obj_move_counter(A6)
	LEA	EnemySpriteFrameDataA_00, A0
	BSET.b	#7, (A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	#$F4, obj_hitbox_x_neg(A6)
	MOVE.b	#$3C, obj_hitbox_x_pos(A6)
	MOVE.b	#$EC, obj_hitbox_y_neg(A6)
	MOVE.b	#$F8, obj_hitbox_y_pos(A6)
	CLR.w	obj_knockback_timer(A6)
	MOVE.l	#$FFFFE000, obj_vel_x(A6)
	MOVE.l	#$8000, obj_vel_y(A6)
	MOVE.b	(A0)+, obj_sprite_size(A6)
	CLR.w	D0
	MOVE.b	(A0)+, D0
	MOVE.w	D0, obj_sort_key(A6)
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVE.w	#$006E, obj_world_x(A6)
	MOVE.w	#$0060, obj_world_y(A6)
	MOVE.l	#Boss1_MainTick, obj_tick_fn(A6)
	MOVE.w	#4, D7
InitBoss1_Common_Done:
	BSR.w	InitNextSpriteSlot
	DBF	D7, InitBoss1_Common_Done
	MOVEA.l	Object_slot_02_ptr.w, A6
	LEA	EnemySpriteFrameDataA_03, A0
	BSET.b	#7, (A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	#$F8, obj_hitbox_x_neg(A6)
	MOVE.b	#$38, obj_hitbox_x_pos(A6)
	MOVE.b	#$F0, obj_hitbox_y_neg(A6)
	MOVE.b	#$F8, obj_hitbox_y_pos(A6)
	MOVE.b	(A0)+, obj_sprite_size(A6)
	CLR.w	D0
	MOVE.b	(A0)+, D0
	MOVE.w	D0, obj_sort_key(A6)
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVE.w	#$006E, obj_world_x(A6)
	MOVE.w	#$006C, obj_world_y(A6)
	MOVE.l	#Boss1_NeckTick, obj_tick_fn(A6)
	MOVE.w	#1, D7
InitBoss1_Common_Done2:
	BSR.w	InitNextSpriteSlot
	DBF	D7, InitBoss1_Common_Done2
	MOVEA.l	Object_slot_03_ptr.w, A6
	LEA	EnemySpriteFrameDataA_08, A0
	BSET.b	#7, (A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	(A0)+, obj_sprite_size(A6)
	CLR.w	D0
	MOVE.b	(A0)+, D0
	MOVE.w	D0, obj_sort_key(A6)
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVE.w	#SOUND_PLAYER_HIT, obj_world_x(A6)
	MOVE.w	#$0070, obj_world_y(A6)
	MOVE.l	#Boss1_UpperBodyTick, obj_tick_fn(A6)
	MOVE.b	#$F0, obj_hitbox_x_neg(A6)
	MOVE.b	#$10, obj_hitbox_x_pos(A6)
	MOVE.b	#SOUND_LEVEL_UP, obj_hitbox_y_neg(A6)
	MOVE.b	#0, obj_hitbox_y_pos(A6)
	MOVE.w	#0, D7
InitBoss1_Common_Done3:
	BSR.w	InitNextSpriteSlot
	DBF	D7, InitBoss1_Common_Done3
	MOVEA.l	Object_slot_04_ptr.w, A6
	LEA	EnemySpriteFrameDataA_09, A0
	BSET.b	#7, (A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	(A0)+, obj_sprite_size(A6)
	CLR.w	D0
	MOVE.b	(A0)+, D0
	MOVE.w	D0, obj_sort_key(A6)
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVE.w	#$00C8, obj_world_x(A6)
	MOVE.w	#$0070, obj_world_y(A6)
	MOVE.l	#Boss1_MidBodyTick, obj_tick_fn(A6)
	MOVE.b	#$F0, obj_hitbox_x_neg(A6)
	MOVE.b	#$10, obj_hitbox_x_pos(A6)
	MOVE.b	#SOUND_LEVEL_UP, obj_hitbox_y_neg(A6)
	MOVE.b	#0, obj_hitbox_y_pos(A6)
	MOVE.w	#0, D7
InitBoss1_Common_Done4:
	BSR.w	InitNextSpriteSlot
	DBF	D7, InitBoss1_Common_Done4
	MOVEA.l	Object_slot_05_ptr.w, A6
	LEA	EnemySpriteFrameDataA_0A, A0
	BSET.b	#7, (A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	(A0)+, obj_sprite_size(A6)
	CLR.w	D0
	MOVE.b	(A0)+, D0
	MOVE.w	D0, obj_sort_key(A6)
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVE.w	#$00DA, obj_world_x(A6)
	MOVE.w	#$0070, obj_world_y(A6)
	MOVE.l	#Boss1_TailTick, obj_tick_fn(A6)
	MOVE.w	#0, D7
InitBoss1_Common_Done5:
	BSR.w	InitNextSpriteSlot
	DBF	D7, InitBoss1_Common_Done5
	MOVEA.l	Object_slot_06_ptr.w, A6
	LEA	EnemySpriteFrameDataA_06, A0
	LEA	EnemySpriteFrameDataA_07, A1
	MOVE.w	#2, D7
InitBoss1_Common_Done6:
	BSET.b	#7, (A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	(A0)+, obj_sprite_size(A6)
	CLR.w	D0
	MOVE.b	(A0)+, D0
	MOVE.w	D0, obj_sort_key(A6)
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVE.w	(A1)+, obj_screen_x(A6)
	MOVE.w	(A1)+, obj_screen_y(A6)
	MOVE.l	#BossCommon_RenderOnly, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, InitBoss1_Common_Done6
	BSR.w	DrawBossPortrait
	BSR.w	DrawBossAttackGraphic1
	RTS
	
Boss1_MainTick:
	MOVE.w	Boss_ai_state.w, D0
	ANDI.w	#$000F, D0
	LEA	BossAiStateJumpTable, A0
	ADD.w	D0, D0
	ADD.w	D0, D0
	JSR	(A0,D0.w)
	BSR.w	ProcessBattleDamageAndPalette
	BSR.w	UpdateBattleParallaxLayers
	BSR.w	CheckEntityPlayerCollisionAndDamage
	MOVE.w	#$00E0, D1
	BSR.w	CheckPlayerDamageAndKnockback
	RTS
	
; loc_0000BB2E
BossAiStateJumpTable:
	BRA.w	Boss1State_InitIdle
	BRA.w	Boss1State_ChooseAction
	BRA.w	Boss1State_MoveDown
	BRA.w	Boss1State_HeadExtend
	BRA.w	Boss1State_AttackWait
	BRA.w	Boss1State_LungeLeft
	BRA.w	Boss1State_ReturnHome
	BRA.w	Boss1State_HeadRetract
	BRA.w	Boss1State_ChargeDownLeft
Boss1State_InitIdle:
	JSR	GetRandomNumber
	ANDI.w	#$003F, D0
	MOVE.b	D0, obj_invuln_timer(A5)
	ADDQ.w	#1, Boss_ai_state.w
	RTS
	
Boss1State_ChooseAction:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGE.w	Boss1State_MoveRight_Loop
	BSR.w	CheckPlayerLeftOfScreen
	BEQ.b	Boss1State_MoveRight
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	BEQ.b	Boss1State_MoveRight
	MOVE.w	#BOSS1_STATE_CHARGE_DOWN_LEFT, Boss_ai_state.w
	MOVE.l	#$FFFF8000, obj_vel_x(A5)
	MOVE.l	#$00020000, obj_vel_y(A5)
	RTS
	
; loc_0000BB98
Boss1State_MoveRight:
	MOVE.w	#BOSS1_STATE_MOVE_DOWN, Boss_ai_state.w
	MOVE.l	#$4000, obj_vel_x(A5)
	MOVE.l	#$8000, obj_vel_y(A5)
Boss1State_MoveRight_Loop:
	RTS
	
Boss1State_MoveDown:
	CMPI.w	#RING_GUARDIAN_Y_LOWER, obj_world_y(A5)
	BLE.b	Boss1State_PauseAndReset_Loop
	MOVE.w	#BOSS1_STATE_HEAD_EXTEND, Boss_ai_state.w
Boss1State_PauseAndReset:
	MOVE.b	#BOSS1_HEAD_PAUSE_TICKS, obj_invuln_timer(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
Boss1State_PauseAndReset_Loop:
	RTS
	
Boss1State_HeadExtend:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGE.b	Boss1State_HeadExtend_Loop
	MOVE.w	#BOSS1_STATE_ATTACK_WAIT, Boss_ai_state.w
	MOVE.b	#BOSS1_HEAD_EXTEND_TICKS, obj_invuln_timer(A5)
Boss1State_HeadExtend_Loop:
	MOVEA.l	Object_slot_02_ptr.w, A6
	ADDI.l	#$1000, obj_world_x(A6)
	ADDI.l	#$4000, obj_world_y(A6)
	RTS
	
Boss1State_HeadRetract:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGE.b	Boss1State_HeadRetract_Loop
	MOVE.w	#BOSS1_STATE_RETURN_HOME, Boss_ai_state.w
	MOVE.l	#$FFFFC000, obj_vel_x(A5)
	MOVE.l	#$FFFF8000, obj_vel_y(A5)
Boss1State_HeadRetract_Loop:
	MOVEA.l	Object_slot_02_ptr.w, A6
	SUBI.l	#$1000, obj_world_x(A6)
	SUBI.l	#$4000, obj_world_y(A6)
	RTS
	
Boss1State_AttackWait:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGE.b	Boss1State_AttackWait_Loop
	MOVE.b	#BOSS1_HEAD_PAUSE_TICKS, obj_invuln_timer(A5)
	MOVE.w	#BOSS1_STATE_HEAD_RETRACT, Boss_ai_state.w
	RTS
	
Boss1State_AttackWait_Loop:
	BSR.w	CheckPlayerLeftOfScreen
	BEQ.b	Boss1State_AttackWait_Loop2
	MOVE.w	#BOSS1_STATE_LUNGE_LEFT, Boss_ai_state.w
	MOVE.l	#$FFFE0000, obj_vel_x(A5)
	MOVE.l	#0, obj_vel_y(A5)
	RTS
	
Boss1State_AttackWait_Loop2:
	RTS
	
Boss1State_LungeLeft:
	MOVE.w	obj_world_x(A5), D0
	CMPI.w	#$005A, D0
	BGE.b	Boss1State_LungeLeft_Loop
	MOVE.w	#BOSS1_STATE_RETURN_HOME, Boss_ai_state.w
	MOVE.l	#$4000, obj_vel_x(A5)
	MOVE.l	#$FFFF8000, obj_vel_y(A5)
Boss1State_LungeLeft_Loop:
	RTS

Boss1State_ChargeDownLeft:
	CMPI.w	#RING_GUARDIAN_Y_LOWER, obj_world_y(A5)
	BLE.b	Boss1State_ChargeDownLeft_Loop
	MOVE.w	#BOSS1_STATE_RETURN_HOME, Boss_ai_state.w
	MOVE.l	#$4000, obj_vel_x(A5)
	MOVE.l	#Tilemap_buffer_plane_a, obj_vel_y(A5)
Boss1State_ChargeDownLeft_Loop:
	RTS

Boss1State_ReturnHome:
	MOVE.w	obj_world_y(A5), D0
	CMPI.w	#$0060, D0
	BGT.b	Boss1State_ReturnHome_Loop
	MOVE.w	#$006E, obj_world_x(A5)
	MOVE.w	#$0060, obj_world_y(A5)
	MOVEA.l	Object_slot_05_ptr.w, A6
	MOVE.w	#$00DA, obj_world_x(A6)
	MOVE.w	#$0070, obj_world_y(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	MOVE.w	#$00C8, obj_world_x(A6)
	MOVE.w	#$0070, obj_world_y(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.w	#SOUND_PLAYER_HIT, obj_world_x(A6)
	MOVE.w	#$0070, obj_world_y(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.w	#$006E, obj_world_x(A6)
	MOVE.w	#$006C, obj_world_y(A6)
	MOVE.w	#BOSS1_STATE_INIT_IDLE, Boss_ai_state.w
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
Boss1State_ReturnHome_Loop:
	RTS

Boss1_DeathSequence:
	CLR.l	obj_vel_x(A5)
	MOVE.l	#$8000, obj_vel_y(A5)
	MOVE.b	#0, obj_move_counter(A5)
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.l	#Boss1_NeckTickNoCollision, obj_tick_fn(A6)
	CLR.l	obj_vel_x(A6)
	MOVE.l	#$8000, obj_vel_y(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	CLR.l	obj_vel_x(A6)
	MOVE.l	#$8000, obj_vel_y(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	CLR.l	obj_vel_x(A6)
	MOVE.l	#$8000, obj_vel_y(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	CLR.l	obj_vel_x(A6)
	MOVE.l	#$8000, obj_vel_y(A6)
	BSR.w	UpdateSpritePositionAndRender
	MOVE.l	#Boss1_DeathFall, obj_tick_fn(A5)
	MOVE.w	#SOUND_DOOR_OPEN, D0
	JSR	QueueSoundEffect
	RTS

