; ======================================================================
; src/enemy.asm
; Enemy AI, projectiles, collision, damage, death rewards
; ======================================================================
; ======================================================================
; Projectile Boundary Helpers
; ======================================================================

; ClampProjectileToScreenBounds
; Each frame: re-applies the previous position (pos - vel) and checks it
; against the battle-field bounds.  If inside, stores the updated pos.
; If outside (or at the edge), deactivates the object (clears bit 7) and
; falls through to copy world coords to screen coords.
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


; CalculateVelocityFromAngle
; Convert obj_direction (0-7) into a fixed-point velocity vector
; using SineTable and obj_pos_x_fixed as the speed scalar.
; Output: obj_vel_x / obj_vel_y set on A5.
CalculateVelocityFromAngle:
	LEA	SineTable, A0
	MOVE.l	obj_pos_x_fixed(A5), D0	; D0 = speed scalar
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	ASL.w	#5, D1				; direction × 32 = sine table offset
	MOVE.b	(A0,D1.w), D2			; D2 = sin(dir) for X velocity
	MOVE.b	$40(A0,D1.w), D3		; D3 = sin(dir+64) = cos for Y velocity
	EXT.w	D2
	EXT.w	D3
	MULS.w	D0, D2				; vel_x = speed × sin
	MULS.w	D0, D3				; vel_y = speed × cos
	MOVE.l	D2, obj_vel_x(A5)
	MOVE.l	D3, obj_vel_y(A5)
	RTS

; ---------------------------------------------------------------------------
; CheckObjectOnScreen — clamp object to battle-field bounds, update display
;
; Subtracts the object's velocity from its world position and checks whether
; the resulting coordinate is within the battle-field rectangle
; (X: 0–BATTLE_FIELD_WIDTH, Y: BATTLE_FIELD_TOP–BATTLE_FIELD_BOTTOM).
; If in bounds the position is committed and the display coordinates are
; synced.  If out of bounds the velocity is zeroed, the timers cleared, and
; a random direction is added to obj_direction.
;
; Input:
;   A5    pointer to enemy object struct
;
; Scratch:  D0, D1
; Output:   obj_world_x/y updated; obj_screen_x/y/sort_key synced;
;           OR obj_vel_x/y zeroed and obj_direction randomised
; ---------------------------------------------------------------------------
; CheckObjectOnScreen
; Variant of ClampProjectileToScreenBounds for generic enemies.
; On out-of-bounds: zeroes velocity, zeroes timers, randomises direction
; by ±0-7 (keeps enemy from leaving the field entirely).
; Falls through to UpdateObjectDisplayPosition on both paths.
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
; UpdateObjectDisplayPosition
; Trivial helper: copies world_x/y to screen_x/y and sets sort_key
; from world_y (no bounds checking).
UpdateObjectDisplayPosition:
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	obj_screen_y(A5), obj_sort_key(A5)
	RTS


; UpdateObjectScreenPosition
; Like CheckObjectOnScreen but deactivates the object instead of
; randomising direction when it leaves the battle field.
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

; ---------------------------------------------------------------------------
; HandlePlayerTakeDamage — test enemy-player AABB overlap and apply damage
;
; Checks whether the enemy object (A5) overlaps the player hitbox (A6 =
; Player_entity_ptr).  Returns immediately if a screen fade is in progress
; or the player is currently invulnerable.
;
; On a hit: sets Player_invulnerable, starts the invulnerability timer,
; calls ApplyDamageToPlayer, plays SOUND_PLAYER_HIT, optionally inflicts
; poison (based on enemy type, equipped shield, and a LUK check), then
; calls CalculateAngleBetweenObjects to compute a knockback vector.
;
; Input:
;   A5    pointer to enemy object struct (attacker)
;
; Scratch:  D0-D2, A0, A6
; Output:   Player HP reduced; Player_invulnerable set; knockback applied;
;           Player_poisoned set if poison proc succeeds
; ---------------------------------------------------------------------------

; ======================================================================
; Collision and Damage Helpers
; ======================================================================
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
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A6)	; post-hit grace period
	BSR.w	ApplyDamageToPlayer
	PlaySound_b	SOUND_PLAYER_HIT		; hit sound
	TST.b	obj_sprite_frame(A5)			; enemy type has poison flag?
	BEQ.w	HandlePlayerTakeDamage_ApplyKnockback	; no → skip poison check
	MOVE.w	Equipped_shield.w, D0
	ANDI.w	#$00FF, D0
	CMPI.w	#EQUIPMENT_SHIELD_POISON, D0		; poison-resist shield equipped?
	BEQ.w	HandlePlayerTakeDamage_ApplyKnockback	; yes → skip poison
	JSR	GetRandomNumber
	ANDI.w	#$01FF, D0				; random 0-511
	CMP.w	Player_luk.w, D0			; RNG < LUK → resist
	BLT.b	HandlePlayerTakeDamage_ApplyKnockback
	MOVE.w	#POISONED_DURATION, Player_poisoned.w	; poison applied
HandlePlayerTakeDamage_ApplyKnockback:
	BSR.w	CalculateAngleBetweenObjects		; D0 = angle from enemy to player
	ANDI.w	#7, D0
	ADD.w	D0, D0
	ADD.w	D0, D0					; × 4 = word pair index into table
	LEA	EnemyPositionOffsetTable, A0
	MOVE.w	(A0,D0.w), D1
	ADD.w	D1, obj_world_x(A6)			; nudge player X
	MOVE.w	$2(A0,D0.w), D1
	ADD.w	D1, obj_world_y(A6)			; nudge player Y
	CLR.l	obj_vel_x(A5)				; stop enemy on contact
	CLR.l	obj_vel_y(A5)
HandlePlayerTakeDamage_Return:
	RTS


; CalculateAngleToObjectCentered
; Variant of CalculateAngleBetweenObjects that biases the angle
; toward the screen centre before computing the direction.
; Screen centre: X=$00A0 (160), Y=$0078 (120).
; If target X > 160: X_biased = (X/2) + 160  (pull toward right)
; If target Y > 120: Y_biased = (Y/2) + 120  (pull toward bottom)
; This gives a "herding" effect — enemies converge toward the screen
; middle rather than the exact player position.
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
	BLE.w	CalculateAngleToObjectCentered_OffsetY
	ADD.w	D2, D1
CalculateAngleToObjectCentered_OffsetY:
	SUB.w	obj_world_x(A5), D0
	SUB.w	obj_world_y(A5), D1
	BRA.w	CalculateAngleBetweenObjects_common
; CalculateAngleBetweenObjects
; Calculate angle from object A5 to object A6 using a 16-direction
; octant table.  Computes (dx, dy) = target minus source, classifies
; into one of 16 octants, then looks up the sprite direction index.
;
; Octant classification bits in D2:
;   bit 3: dx < 0  (west half)
;   bit 2: dy < 0  (north half)
;   bit 1: |dx| < |dy| (Y-dominant)
;   bit 0: second half of octant (finer sub-division)
;
; Input: A5 = source object, A6 = target object
; Output: D0 = direction index 0-7 (0=right, 2=down, 4=left, 6=up)
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
	BGE.w	CalculateAngleBetweenObjects_common_NegateY
	NEG.w	D1
	ORI.w	#4, D2
CalculateAngleBetweenObjects_common_NegateY:
	CMP.w	D1, D0
	BGE.w	CalculateAngleBetweenObjects_common_SwapAxes
	ORI.w	#2, D2
	ASR.w	#1, D1
	BGE.w	CalculateAngleBetweenObjects_common_HalvedX
CalculateAngleBetweenObjects_common_SwapAxes:
	ASR.w	#1, D0
CalculateAngleBetweenObjects_common_HalvedX:
	CMP.w	D1, D0
	BGE.w	CalculateAngleBetweenObjects_common_SetOctantBit
	ORI.w	#1, D2
CalculateAngleBetweenObjects_common_SetOctantBit:
	LEA	EnemyDirectionAnimTable, A1
	ADDA.w	D2, A1
	MOVE.b	(A1), D0
	RTS


; CheckEnemyCollision
; AABB test between A5 and all active enemies in Enemy_list_ptr.
; Zeroes velocity on A5 if an overlap is found.
; CheckEnemyCollision
; AABB collision test: checks if A5 (the moving object) overlaps any
; other active enemy in the enemy list.  On overlap, zeroes A5's velocity.
; Uses pre-battle position (world - vel) so collision is checked at the
; frame's START, not after movement has already been applied.
;
; D2 = enemy left edge, D3 = enemy right edge (X span of A5)
; D4 = enemy bottom edge, D5 = enemy top edge (Y span of A5)
; A6 walks the linked list via obj_next_offset; skips inactive slots.
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
CheckEnemyCollision_SkipInactive:
	BTST.b	#6, (A6)
	BNE.w	CheckEnemyCollision_Loop
	ADDA.w	D6, A6
	BRA.b	CheckEnemyCollision_SkipInactive
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


; ======================================================================
; Death Rewards and Death Animation
; ======================================================================

; EnemyDeathReward_OneSprite
; Award XP/kims, decrement enemy count, start death animation.
; Deactivates the single child sprite slot.
; EnemyDeathReward_OneSprite
; Awards XP and kims from obj_xp_reward/obj_kim_reward, decrements
; Number_Of_Enemies, switches tick function to EnemyDeathAnimation,
; sets death palette, and deactivates the single child sprite slot.
EnemyDeathReward_OneSprite:
	PlaySound_b	SOUND_MAGIC_EFFECT
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


; EnemyDeathReward_TwoSprites
; Like EnemyDeathReward_OneSprite but walks the next-offset chain twice
; to deactivate two child sprite slots.
EnemyDeathReward_TwoSprites:
	PlaySound_b	SOUND_MAGIC_EFFECT
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


; EnemyDeathAnimation
; Per-frame tick for the death flash sequence.  Cycles through
; EnemyDeathAnimation_Data tile indices; deactivates when done.
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


; ======================================================================
; Enemy Type: StandardMelee
; ======================================================================

; InitEnemy_StandardMelee / InitEnemy_StandardMeleeAlt / InitEnemy_StandardMeleeFast
; Set up two-sprite melee enemies that walk toward the player.
; Alt uses a slightly wider primary sprite.
; Fast uses a shorter animation mask for quicker walking animation.
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

; EnemyTick_StandardMelee
; Per-frame tick for standard two-sprite melee enemies.
; Priority: knockback flee > attack-timer wander > face-and-chase.
; When obj_knockback_timer > 0: face away from player (dir +4 mod 8).
; When obj_attack_timer > 0:    small random turn every ~1-in-8 frames.
; When both are zero:           1-in-256 chance to set a wander timer ($F0
;   frames); otherwise aim directly at the player each frame.
EnemyTick_StandardMelee:
	BSR.w	ProcessEnemyDamage
	BGT.w	EnemyTick_StandardMelee_Alive
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS

EnemyTick_StandardMelee_Alive:
	CLR.b	obj_hit_flag(A5)
	TST.b	Encounter_behavior_flag.w
	BNE.w	EnemyTick_UpdateSprite
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyTick_StandardMelee_CheckAttackTimer
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#4, D0			; face opposite direction (flee)
	ANDI.b	#7, D0
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyMovementTick_UpdateVelocity
EnemyTick_StandardMelee_CheckAttackTimer:
	TST.w	obj_attack_timer(A5)
	BEQ.w	EnemyTick_StandardMelee_ChooseDirection
	SUBQ.w	#1, obj_attack_timer(A5)
	JSR	GetRandomNumber
	ANDI.b	#7, D0
	BNE.w	EnemyMovementTick_UpdateVelocity
	BTST.l	#4, D0
	BEQ.w	EnemyTick_StandardMelee_TurnRight
	ADDQ.b	#1, obj_direction(A5)	; random left turn
	BRA.w	EnemyTick_StandardMelee_ApplyTurn	
EnemyTick_StandardMelee_TurnRight:
	SUBQ.b	#1, obj_direction(A5)	; random right turn
EnemyTick_StandardMelee_ApplyTurn:
	ANDI.b	#7, obj_direction(A5)
	BRA.w	EnemyMovementTick_UpdateVelocity
EnemyTick_StandardMelee_ChooseDirection:
	JSR	GetRandomNumber
	ANDI.w	#$00FF, D0
	BNE.w	EnemyTick_StandardMelee_RandomWander
	MOVE.w	#$00F0, obj_attack_timer(A5)	; ~240 frames of wander mode
EnemyTick_StandardMelee_RandomWander:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
; EnemyMovementTick_UpdateVelocity
; Shared tail section for all two-sprite melee enemy ticks.
; Recalculates velocity, checks collision, handles player damage, then
; updates the animation frame and flip bit for both main and child sprites.
; A6 is set to the child sprite object by reading obj_next_offset.
EnemyMovementTick_UpdateVelocity:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	EnemyMovementTick_UpdateVelocity_CheckMoving
	ADDQ.b	#1, obj_move_counter(A5)	; only advance walk-cycle when moving
EnemyMovementTick_UpdateVelocity_CheckMoving:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6			; A6 = child sprite object
	MOVE.b	obj_move_counter(A5), D0
	AND.w	Enemy_anim_frame_mask.w, D0
	MOVE.w	Enemy_anim_frame_shift.w, D1
	ASR.w	D1, D0				; D0 = animation frame index
	BCLR.b	#3, obj_sprite_flags(A5)	; clear H-flip
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	CMPI.b	#4, D1
	BLE.w	EnemyMovementTick_UpdateVelocity_SetFlip
	BSET.b	#3, obj_sprite_flags(A5)	; directions > 4 = facing left → H-flip
EnemyMovementTick_UpdateVelocity_SetFlip:
	ASL.w	#3, D1				; direction × 8 = row in anim table
	ADD.w	D0, D1				; + frame column
	MOVEA.l	Enemy_anim_table_main.w, A0
	MOVEA.l	Enemy_anim_table_child.w, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	TST.b	Enemy_pair_offset_flag.w
	BNE.w	EnemyMovementTick_UpdateVelocity_OffsetChild
	BSR.w	CopyPositionToLinkedSprite
	BRA.w	EnemyTick_UpdateSprite
EnemyMovementTick_UpdateVelocity_OffsetChild:
	BSR.w	CopyEnemyPositionToChildObject
; EnemyTick_UpdateSprite
; Final step shared by all melee tick paths: add to sprite display list.
EnemyTick_UpdateSprite:
	JSR	AddSpriteToDisplayList
	RTS


; ======================================================================
; Enemy Type: StalkPause
; ======================================================================

; InitEnemy_StalkPause / InitEnemy_StalkPauseAlt
; Two-sprite melee enemy that randomly pauses its movement for a
; period before resuming the chase.
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

; EnemyTick_StalkPause
; Per-frame tick: knockback flee > pause-timer stand-still > stalk/chase.
; obj_attack_timer: pause countdown (face player but stand still).
; obj_knockback_timer: flee countdown (face away, keep moving).
; 1-in-128 chance each frame to reset the pause timer.
EnemyTick_StalkPause:
	BSR.w	ProcessEnemyDamage
	BGT.w	EnemyTick_StalkPause_Alive
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS

EnemyTick_StalkPause_Alive:
	CLR.b	obj_hit_flag(A5)
	TST.b	Encounter_behavior_flag.w
	BNE.w	EnemyTick_StalkPause_AddToDisplay
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyTick_StalkPause_CheckPauseTimer
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#4, D0
	ANDI.b	#7, D0
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyTick_StalkPause_MoveToPlayer
EnemyTick_StalkPause_CheckPauseTimer:
	TST.w	obj_attack_timer(A5)
	BEQ.w	EnemyTick_StalkPause_CheckStalkTimer
	SUBQ.w	#1, obj_attack_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	EnemyTick_StalkPause_HandleDamage
EnemyTick_StalkPause_CheckStalkTimer:
	JSR	GetRandomNumber
	ANDI.w	#$007F, D0
	BNE.w	EnemyTick_StalkPause_RollPauseTimer
	MOVE.w	#ENEMY_STALK_RECHECK_DELAY, obj_attack_timer(A5)
EnemyTick_StalkPause_RollPauseTimer:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
EnemyTick_StalkPause_MoveToPlayer:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
EnemyTick_StalkPause_HandleDamage:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	EnemyTick_StalkPause_CheckMoving
	ADDQ.b	#1, obj_move_counter(A5)
EnemyTick_StalkPause_CheckMoving:
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
	BLE.w	EnemyTick_StalkPause_SetFlip
	BSET.b	#3, obj_sprite_flags(A5)
EnemyTick_StalkPause_SetFlip:
	ASL.w	#3, D1
	ADD.w	D0, D1
	MOVEA.l	Enemy_anim_table_main.w, A0
	MOVEA.l	Enemy_anim_table_child.w, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	BSR.w	CopyPositionToLinkedSprite
EnemyTick_StalkPause_AddToDisplay:
	JSR	AddSpriteToDisplayList
	RTS


; ======================================================================
; Enemy Type: ProximityChase
; ======================================================================

; InitEnemy_ProximityChase
; Two-sprite enemy that only chases when the player is within
; ENEMY_CHASE_PROXIMITY pixels; otherwise stands still facing the player.
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

; EnemyTick_ProximityChase
; Per-frame tick for proximity-triggered chase enemy.
; If |dx| > ENEMY_CHASE_PROXIMITY OR |dy| > ENEMY_CHASE_PROXIMITY:
;   face player, zero velocity (stand-still AI).
; Otherwise: aim and chase.
; obj_knockback_timer > 0 overrides both: flee in opposite direction.
EnemyTick_ProximityChase:
	BSR.w	ProcessEnemyDamage
	BGT.w	EnemyTick_ProximityChase_Alive
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS

EnemyTick_ProximityChase_Alive:
	CLR.b	obj_hit_flag(A5)
	TST.b	Encounter_behavior_flag.w
	BNE.w	EnemyTick_ProximityChase_AddToDisplay
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyTick_ProximityChase_CheckProximity
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#4, D0
	ANDI.b	#7, D0
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyTick_ProximityChase_Chase
EnemyTick_ProximityChase_CheckProximity:
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), D0
	SUB.w	obj_world_x(A5), D0
	BGE.w	EnemyTick_ProximityChase_AbsX
	NEG.w	D0
EnemyTick_ProximityChase_AbsX:
	CMPI.w	#ENEMY_CHASE_PROXIMITY, D0
	BGT.w	EnemyTick_ProximityChase_StandStill
	MOVE.w	obj_world_y(A6), D0
	SUB.w	obj_world_y(A5), D0
	BGE.w	EnemyTick_ProximityChase_AbsY
	NEG.w	D0
EnemyTick_ProximityChase_AbsY:
	CMPI.w	#ENEMY_CHASE_PROXIMITY, D0
	BLE.w	EnemyTick_ProximityChase_ChasePlayer
EnemyTick_ProximityChase_StandStill:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	EnemyTick_ProximityChase_HandleDamage
EnemyTick_ProximityChase_ChasePlayer:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
EnemyTick_ProximityChase_Chase:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
EnemyTick_ProximityChase_HandleDamage:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	EnemyTick_ProximityChase_CheckMoving
	ADDQ.b	#1, obj_move_counter(A5)
EnemyTick_ProximityChase_CheckMoving:
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
	BLE.w	EnemyTick_ProximityChase_SetFlip
	BSET.b	#3, obj_sprite_flags(A5)
EnemyTick_ProximityChase_SetFlip:
	ASL.w	#3, D1
	ADD.w	D0, D1
	LEA	EnemyTick_ProximityChase_Loop11_Data, A0
	LEA	EnemyTick_ProximityChase_Loop11_Data2, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	BSR.w	CopyPositionToLinkedSprite
EnemyTick_ProximityChase_AddToDisplay:
	JSR	AddSpriteToDisplayList
	RTS


; ======================================================================
; Enemy Type: FleeChase
; ======================================================================

; InitEnemy_FleeChase
; Two-sprite melee enemy that alternates between chasing and briefly
; fleeing (running away from player).  No special hitbox params set here —
; uses defaults from InitEnemyAI.
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

; EnemyTick_FleeChase
; Per-frame tick: knockback flee > random flee-timer > chase.
; When obj_knockback_timer > 0:  flee from player.
; When it reaches 0:  1-in-256 chance to set a new flee timer
;   (value = (RNG >> 8) & $FF + $78, i.e. 120–375 frames).
; Otherwise:  chase player directly.
EnemyTick_FleeChase:
	BSR.w	ProcessEnemyDamage
	BGT.w	EnemyTick_FleeChase_Alive
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS

EnemyTick_FleeChase_Alive:
	CLR.b	obj_hit_flag(A5)
	TST.b	Encounter_behavior_flag.w
	BNE.w	EnemyTick_FleeChase_AddToDisplay
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyTick_FleeChase_CheckFlee
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#4, D0
	ANDI.b	#7, D0
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyTick_FleeChase_Chase
EnemyTick_FleeChase_CheckFlee:
	JSR	GetRandomNumber
	MOVE.w	D0, D1
	ANDI.w	#$00FF, D0
	BNE.w	EnemyTick_FleeChase_SetFleeDir	; 255-in-256 frames: just chase
	ASR.w	#8, D1				; high byte of RNG
	ANDI.w	#$00FF, D1
	ADDI.w	#$0078, D1			; flee timer = 120–375 frames
	MOVE.w	D1, obj_knockback_timer(A5)	; start flee burst
EnemyTick_FleeChase_SetFleeDir:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
EnemyTick_FleeChase_Chase:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	EnemyTick_FleeChase_CheckMoving
	ADDQ.b	#1, obj_move_counter(A5)
EnemyTick_FleeChase_CheckMoving:
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
	BLE.w	EnemyTick_FleeChase_SetFlip
	BSET.b	#3, obj_sprite_flags(A5)
EnemyTick_FleeChase_SetFlip:
	ASL.w	#3, D1
	ADD.w	D0, D1
	LEA	EnemyAnimFrames_MeleeA_Main, A0
	LEA	EnemyAnimFrames_MeleeA_Child, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	BSR.w	CopyPositionToLinkedSprite
EnemyTick_FleeChase_AddToDisplay:
	JSR	AddSpriteToDisplayList
	RTS


; ======================================================================
; Enemy Type: Bouncing
; ======================================================================

; InitEnemy_Bouncing
; Two-sprite enemy that uses a stalk-pause movement style with a
; bounce animation (child sprite offset above the main sprite).
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

; EnemyTick_Bouncing
; Per-frame tick: stalk-pause AI with a two-part bounce animation.
; The child sprite is always drawn 24 px ($18) above the main sprite Y.
; Animation uses EnemyTick_Bouncing_Loop6_Data tables (bits 2-4 of counter).
EnemyTick_Bouncing:
	BSR.w	ProcessEnemyDamage
	BGT.w	EnemyTick_Bouncing_Alive
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS

EnemyTick_Bouncing_Alive:
	CLR.b	obj_hit_flag(A5)
	TST.b	Encounter_behavior_flag.w
	BNE.w	EnemyTick_Bouncing_AddToDisplay
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyTick_Bouncing_CheckPauseTimer
	SUBQ.w	#1, obj_knockback_timer(A5)	
	MOVEA.l	Player_entity_ptr.w, A6	
	BSR.w	CalculateAngleBetweenObjects	
	ADDQ.b	#4, D0	
	ANDI.b	#7, D0	
	MOVE.b	D0, obj_direction(A5)	
	BRA.w	EnemyTick_Bouncing_Chase	
EnemyTick_Bouncing_CheckPauseTimer:
	TST.w	obj_attack_timer(A5)
	BEQ.w	EnemyTick_Bouncing_CheckStalkTimer
	SUBQ.w	#1, obj_attack_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	EnemyTick_Bouncing_UpdateBounceAnim
EnemyTick_Bouncing_CheckStalkTimer:
	JSR	GetRandomNumber
	ANDI.w	#$007F, D0
	BNE.w	EnemyTick_Bouncing_RollPauseTimer
	MOVE.w	#ENEMY_STALK_RECHECK_DELAY, obj_attack_timer(A5)
EnemyTick_Bouncing_RollPauseTimer:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
EnemyTick_Bouncing_Chase:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
EnemyTick_Bouncing_UpdateBounceAnim:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$001C, D0			; bits 2-4 of counter → frame (0-14, step 2)
	ASR.w	#1, D0				; → word table index (0,2,4,6,8,10,12,14)
	LEA	EnemyTick_Bouncing_Loop6_Data, A0
	LEA	EnemyTick_Bouncing_Loop6_Data2, A1
	MOVE.w	(A0,D0.w), obj_tile_index(A5)	; main body tile
	MOVE.w	(A1,D0.w), obj_tile_index(A6)	; upper body tile
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6) ; sync flip/palette
	MOVE.w	obj_screen_x(A5), obj_screen_x(A6)
	MOVE.w	obj_screen_y(A5), D0
	SUBI.w	#$0018, D0			; child sprite 24 px above main
	MOVE.w	D0, obj_screen_y(A6)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
EnemyTick_Bouncing_AddToDisplay:
	JSR	AddSpriteToDisplayList
	RTS


; ======================================================================
; Enemy Type: ProjectileFire
; ======================================================================

; InitEnemy_ProjectileFire
; Two-sprite melee enemy that also spawns a linear projectile child
; (ProjectileTick_Linear) from its current position.
InitEnemy_ProjectileFire:
	BSR.w	InitEnemyAI
	BSR.w	SetObjectBoundsType1
	MOVE.l	#EnemyTick_ProjectileFire, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	RTS

; EnemyTick_ProjectileFire
; Per-frame tick: knockback flee > wander-timer > track-and-fire pattern.
; Uses a third child object (A4) as a projectile (ProjectileTick_Linear).
; When obj_attack_timer > 0: random turn (1-in-8) then move.
; When zero and RNG=0: set attack_timer = $0078 (120-frame wander), random turn.
; Otherwise: face player, zero velocity (pause before firing).
EnemyTick_ProjectileFire:
	BSR.w	ProcessEnemyDamage
	BGT.w	EnemyTick_ProjectileFire_Alive
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS

EnemyTick_ProjectileFire_Alive:
	CLR.b	obj_hit_flag(A5)
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyTick_ProjectileFire_CheckAttackTimer
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#4, D0
	ANDI.b	#7, D0
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyTick_ProjectileFire_Move
EnemyTick_ProjectileFire_CheckAttackTimer:
	TST.w	obj_attack_timer(A5)
	BEQ.w	EnemyTick_ProjectileFire_ChooseDirection
	SUBQ.w	#1, obj_attack_timer(A5)
	BRA.w	EnemyTick_ProjectileFire_Move
EnemyTick_ProjectileFire_ChooseDirection:
	JSR	GetRandomNumber
	ANDI.b	#7, D0
	BNE.w	EnemyTick_ProjectileFire_TrackPlayer
	BTST.l	#4, D0
	BEQ.w	EnemyTick_ProjectileFire_TurnRight
	ADDQ.b	#1, obj_direction(A5)	
	BRA.w	EnemyTick_ProjectileFire_ApplyTurn	
EnemyTick_ProjectileFire_TurnRight:
	SUBQ.b	#1, obj_direction(A5)
EnemyTick_ProjectileFire_ApplyTurn:
	ANDI.b	#7, obj_direction(A5)
	MOVE.w	#$0078, obj_attack_timer(A5)
	BRA.w	EnemyTick_ProjectileFire_Move
EnemyTick_ProjectileFire_TrackPlayer:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	EnemyTick_ProjectileFire_Move_HandleDamage
EnemyTick_ProjectileFire_Move:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
EnemyTick_ProjectileFire_Move_HandleDamage:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	EnemyTick_ProjectileFire_Move_CheckMoving
	ADDQ.b	#1, obj_move_counter(A5)
EnemyTick_ProjectileFire_Move_CheckMoving:
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
; ======================================================================
; Projectile Spawner: EnemySplit (ProjectileFire helper)
; ======================================================================

; EnemySplit_SpawnChild
; Activates the third object slot (A4) as a new linear projectile aimed
; at the player.  Copies position and speed from the parent (A5).
; Only called when A4 is not already active (bit 7 clear).
;
; EnemySplit_UpdateSprite
; Shared tail: update walk animation for the two-sprite parent enemy,
; copy child-sprite position via CopyEnemyPositionToChildObject, and
; submit to the display list.
EnemySplit_SpawnChild:
	BSET.b	#7, (A4)			; mark projectile slot active
	JSR	GetRandomNumber
	MOVE.b	D0, obj_move_counter(A4)
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A4)
	MOVE.l	obj_world_x(A5), obj_world_x(A4)
	MOVE.l	obj_world_y(A5), obj_world_y(A4)
	MOVE.w	obj_world_y(A4), D0
	MOVE.w	D0, obj_world_y(A4)		; re-store word (normalise fixed-point)
	MOVE.l	obj_pos_x_fixed(A5), D0
	ADD.l	D0, D0				; projectile speed = 2× parent speed
	MOVE.l	D0, obj_pos_x_fixed(A4)
	MOVE.b	#1, obj_sprite_size(A4)
	MOVE.l	#ProjectileTick_Linear, obj_tick_fn(A4)
	MOVE.w	obj_max_hp(A5), obj_max_hp(A4)	; carry damage value to projectile
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A4)		; projectile aims at player
	MOVE.b	D0, obj_direction(A5)		; parent faces same direction
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

; ProjectileTick_Linear
; Tick function for straight-line projectiles.  Recalculates velocity
; each frame, advances position, and deactivates on out-of-bounds.

; ======================================================================
; Projectile: Linear
; ======================================================================
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

; ======================================================================
; Enemy Type: StationaryShooter
; ======================================================================

; InitEnemy_StationaryShooter
; Single-sprite stationary enemy that fires a homing projectile at the
; player.  Uses SetEnemyGraphicsParams for sprite/hitbox setup.
InitEnemy_StationaryShooter:
	BSR.w	InitEnemyAI
	BSR.w	SetEnemyGraphicsParams
	MOVE.l	#EnemyTick_StationaryShooter, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	RTS

; EnemyTick_StationaryShooter
; Per-frame tick: applies damage, aims at the player, and randomly spawns
; a ProjectileTick_HomingAlt projectile toward the player.
EnemyTick_StationaryShooter:
	TST.b	obj_invuln_timer(A5)
	BLE.w	EnemyTick_StationaryShooter_Loop
	SUBQ.b	#1, obj_invuln_timer(A5)	
	BRA.w	EnemyTakeDamage_CheckDeath	
EnemyTick_StationaryShooter_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.w	EnemyTakeDamage_CheckDeath
	PlaySound_b	SOUND_HEAL	
	MOVE.w	Player_str.w, D0	
	SUB.w	D0, obj_hp(A5)	
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A5)	
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
	BEQ.w	EnemyTick_StationaryShooter_SpawnProjectile
	CLR.b	obj_npc_busy_flag(A4)
	CLR.l	obj_vel_x(A4)
	CLR.l	obj_vel_y(A4)
	BRA.w	EnemyHoming_UpdateSprite
EnemyTick_StationaryShooter_SpawnProjectile:
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
	BLE.w	EnemyHoming_UpdateSprite_SetFlip
	BSET.b	#3, obj_sprite_flags(A5)
EnemyHoming_UpdateSprite_SetFlip:
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

; ProjectileTick_HomingAlt
; Homing projectile with a limited lifetime (obj_attack_timer counts
; down to zero then deactivates).  Re-aims toward the player every 16
; ticks using a change-in-timer XOR trick.
;
; XOR trick: (timer) XOR (timer-1) flips bit N if bit N was the lowest
; set bit.  BTST #4 is true exactly once every 16 frames (when bit 4
; transitions 1→0), giving a retarget every 16 ticks.
ProjectileTick_HomingAlt:
	TST.w	obj_attack_timer(A5)
	BNE.w	ProjectileTick_HomingAlt_Active
	BCLR.b	#7, (A5)			; deactivate projectile
	CLR.b	obj_npc_busy_flag(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	ProjectileTick_HomingAlt_HandleDamage
ProjectileTick_HomingAlt_Active:
	SUBQ.w	#1, obj_attack_timer(A5)
	MOVE.w	obj_attack_timer(A5), D0
	MOVE.w	D0, D1
	SUBQ.w	#1, D1
	EOR.w	D0, D1				; D1 = D0 XOR (D0-1) — bit N set iff N was lowest bit
	BTST.l	#4, D1				; true once every 16 frames
	BEQ.w	ProjectileTick_HomingAlt_Retarget
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects	; re-aim
	MOVE.b	D0, obj_direction(A5)
ProjectileTick_HomingAlt_Retarget:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	UpdateObjectScreenPosition
ProjectileTick_HomingAlt_HandleDamage:
	BSR.w	HandlePlayerTakeDamage
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	ProjectileTick_HomingAlt_CheckMoving
	ADDQ.b	#1, obj_move_counter(A5)
ProjectileTick_HomingAlt_CheckMoving:
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0018, D0
	ASR.w	#2, D0
	LEA	EnemyAnimFrames_Fireball, A2
	MOVE.w	(A2,D0.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList
	RTS

; ======================================================================
; Enemy Type: IntermittentChase
; ======================================================================

; InitEnemy_IntermittentChase_Random
; Enemy that chases randomly: direction chosen at random each movement
; interval.  Enemy_direction_flag cleared to select random mode.
InitEnemy_IntermittentChase_Random:
	BSR.w	InitEnemyAI
	BSR.w	SetEnemyCollisionBounds
	CLR.b	Enemy_direction_flag.w
	MOVE.l	#EnemyTick_IntermittentChase, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	RTS

; InitEnemy_IntermittentChase_Homing
; Enemy that chases toward the player direction.  Enemy_direction_flag
; set to FLAG_TRUE to select homing mode in EnemyTick_IntermittentChase.
InitEnemy_IntermittentChase_Homing:
	BSR.w	InitEnemyAI
	BSR.w	SetEnemyCollisionBounds
	MOVE.b	#FLAG_TRUE, Enemy_direction_flag.w
	MOVE.l	#EnemyTick_IntermittentChase, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	RTS

; EnemyTick_IntermittentChase
; Shared tick for both Random and Homing variants.  Moves toward the
; player when attack_timer is zero; idles and decrements timer otherwise.
; Direction chosen randomly or by angle based on Enemy_direction_flag.
EnemyTick_IntermittentChase:
	BSR.w	ProcessEnemyDamage
	BGT.w	EnemyTick_IntermittentChase_Alive
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS

EnemyTick_IntermittentChase_Alive:
	CLR.b	obj_hit_flag(A5)
	TST.b	Encounter_behavior_flag.w
	BNE.w	EnemyCharge_UpdateSprite_AddToDisplay
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyTick_IntermittentChase_CheckMoveTimer
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#4, D0
	ANDI.b	#7, D0
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyTick_IntermittentChase_Move
EnemyTick_IntermittentChase_CheckMoveTimer:
	TST.w	obj_attack_timer(A5)
	BEQ.w	EnemyTick_IntermittentChase_ChooseMove
	SUBQ.w	#1, obj_attack_timer(A5)
	BRA.w	EnemyTick_IntermittentChase_Move
EnemyTick_IntermittentChase_ChooseMove:
	JSR	GetRandomNumber
	ANDI.w	#$003F, D0
	BNE.w	EnemyTick_IntermittentChase_TrackPlayer
	TST.b	Enemy_direction_flag.w
	BNE.w	EnemyTick_IntermittentChase_HomingDir
	JSR	GetRandomNumber
	ANDI.b	#7, D0
	BRA.w	EnemyTick_IntermittentChase_ApplyDirection
EnemyTick_IntermittentChase_HomingDir:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
EnemyTick_IntermittentChase_ApplyDirection:
	MOVE.b	D0, obj_direction(A5)
	MOVE.w	#$0046, obj_attack_timer(A5)
	BRA.w	EnemyTick_IntermittentChase_Move
EnemyTick_IntermittentChase_TrackPlayer:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	EnemyTick_IntermittentChase_Move_Loop
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
	BLE.w	EnemyCharge_UpdateSprite_SetFlip
	BSET.b	#3, obj_sprite_flags(A5)
EnemyCharge_UpdateSprite_SetFlip:
	ASL.w	#3, D1
	ADD.w	D0, D1
	LEA	EnemyAnimFrames_MeleeA_Main, A0
	LEA	EnemyAnimFrames_MeleeA_Child, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	BSR.w	CopyPositionToLinkedSprite
EnemyCharge_UpdateSprite_AddToDisplay:
	JSR	AddSpriteToDisplayList
	RTS
	

; ======================================================================
; Enemy Type: RandomShooter
; ======================================================================

; InitEnemy_RandomShooter
; Two-sprite enemy that periodically randomises its facing direction
; and fires a linear projectile when idle.
InitEnemy_RandomShooter:
	BSR.w	InitEnemyAI
	BSR.w	InitEnemyProjectileSpeed
	MOVE.l	#EnemyTick_RandomShooter, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	RTS
	
; EnemyTick_RandomShooter
; Per-frame tick: knockback flee > attack-timer cooldown > 1-in-32 chance
; to randomise direction and set a $50-frame shoot cooldown.  Otherwise
; tracks player but stands still.
; Fires a single-sprite projectile via the child slot (A4).
EnemyTick_RandomShooter:
	BSR.w	ProcessEnemyDamage
	BGT.w	EnemyTick_RandomShooter_Alive
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS
	
EnemyTick_RandomShooter_Alive:
	CLR.b	obj_hit_flag(A5)
	TST.b	Encounter_behavior_flag.w
	BNE.w	EnemyTick_RandomShooter_Move_AddToDisplay
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyTick_RandomShooter_CheckAttackTimer
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#4, D0
	ANDI.b	#7, D0
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyTick_RandomShooter_Move
EnemyTick_RandomShooter_CheckAttackTimer:
	TST.w	obj_attack_timer(A5)
	BEQ.w	EnemyTick_RandomShooter_RollShoot
	SUBQ.w	#1, obj_attack_timer(A5)
	BRA.w	EnemyTick_RandomShooter_Move
EnemyTick_RandomShooter_RollShoot:
	JSR	GetRandomNumber
	ANDI.w	#$001F, D0
	BNE.w	EnemyTick_RandomShooter_TrackPlayer
	JSR	GetRandomNumber
	ANDI.b	#7, D0
	MOVE.b	D0, obj_direction(A5)
	MOVE.w	#$0050, obj_attack_timer(A5)
	BRA.w	EnemyTick_RandomShooter_Move
EnemyTick_RandomShooter_TrackPlayer:
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	EnemyTick_RandomShooter_Move_HandleDamage
EnemyTick_RandomShooter_Move:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
EnemyTick_RandomShooter_Move_HandleDamage:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0038, D0
	ASR.w	#2, D0
	CMPI.w	#8, D0
	BLE.w	EnemyTick_RandomShooter_Move_UpdateAnim
	CLR.b	obj_move_counter(A5)
	CLR.w	D0
EnemyTick_RandomShooter_Move_UpdateAnim:
	LEA	EnemyAnimFrames_Fireball_B, A0
	LEA	EnemyAnimFrames_Fireball_C, A1
	CLR.w	D1
	MOVE.b	obj_next_offset(A5), D1
	LEA	(A5,D1.w), A6
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.w	(A1,D0.w), obj_tile_index(A6)
	BSR.w	CopyPositionToLinkedSprite
EnemyTick_RandomShooter_Move_AddToDisplay:
	JSR	AddSpriteToDisplayList
	RTS
	

; ======================================================================
; Enemy Type: Teleporter
; ======================================================================

; InitEnemy_Teleporter
; Single-sprite stationary enemy that teleports to a random position
; on a random timer using SetRandomEnemyPosition.  Uses
; CheckAndUpdateBattleTimer so it dies when the encounter timer runs out.
InitEnemy_Teleporter:
	BSR.w	InitEnemyAI
	BSR.w	InitEnemyProjectileSpeed
	MOVE.l	#EnemyTick_Teleporter, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	RTS
	
; EnemyTick_Teleporter
; Per-frame tick: when obj_knockback_timer reaches 0, picks a new random
; teleport delay in range [$60, $7F] (96-127 frames) and calls
; SetRandomEnemyPosition to warp to a new spot.  Then falls through to
; CheckAndUpdateBattleTimer / the animation update.
EnemyTick_Teleporter:	
	TST.w	obj_knockback_timer(A5)
	BNE.w	EnemyTick_Teleporter_Countdown
	CLR.w	D0
	JSR	GetRandomNumber
	ORI.w	#$0060, D0			; ensure minimum delay of $60 frames
	ANDI.w	#$007F, D0			; cap at $7F
	MOVE.w	D0, obj_knockback_timer(A5)
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	BSR.w	SetRandomEnemyPosition
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
EnemyTick_Teleporter_Countdown:
	BSR.w	CheckAndUpdateBattleTimer
	BGT.w	EnemyTick_Teleporter_Alive
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS
	
EnemyTick_Teleporter_Alive:
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
	BLE.w	EnemyTick_Teleporter_UpdateAnim
	CLR.b	obj_move_counter(A5)
	CLR.w	D0
EnemyTick_Teleporter_UpdateAnim:
	LEA	EnemyAnimFrames_Fireball_B, A0
	LEA	EnemyAnimFrames_Fireball_C, A1
	CLR.w	D1
	MOVE.b	obj_next_offset(A5), D1
	LEA	(A5,D1.w), A6
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.w	(A1,D0.w), obj_tile_index(A6)
	BSR.w	CopyPositionToLinkedSprite
	JSR	AddSpriteToDisplayList
	BRA.w	EnemyTick_Teleporter_Return
EnemyTick_Teleporter_Return:
	RTS
	

; ======================================================================
; Enemy Type: BurstFire
; ======================================================================

; InitEnemy_BurstFire
; Enemy that alternates between chasing and firing an 8-way burst of
; ProjectileTick_Straight projectiles.  Uses the 4-state
; EnemyAiChasePauseJumpTable.
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
EnemyAiChasePauseJumpTable:
	BRA.w	EnemyAiChasePause_Tick
	BRA.w	EnemyAiChasePause_Tick_Loop
	BRA.w	EnemyAiChasePause_Tick
	BRA.w	EnemyAiChasePause_Tick_SpawnBurst
EnemyAiChasePause_Tick:
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyAiChasePause_Tick_AdvancePhase
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	EnemyAiChasePause_HandleDamage
EnemyAiChasePause_Tick_AdvancePhase:
	ADDQ.w	#1, obj_attack_timer(A5)
	MOVE.w	#ENEMY_KNOCKBACK_DURATION, obj_knockback_timer(A5)
	BRA.w	EnemyAiChasePause_HandleDamage
EnemyAiChasePause_Tick_Loop:
	SUBQ.w	#1, obj_knockback_timer(A5)
	BLE.w	EnemyAiChasePause_Tick_ChaseAdvance
	MOVEA.l	Player_entity_ptr.w, A6
	JSR	CalculateAngleToObjectCentered(PC)
	MOVE.b	D0, obj_direction(A5)
	BRA.w	EnemyAiChasePause_Move
EnemyAiChasePause_Tick_ChaseAdvance:
	ADDQ.w	#1, obj_attack_timer(A5)
	MOVE.w	#ENEMY_KNOCKBACK_DURATION, obj_knockback_timer(A5)
	BRA.w	EnemyAiChasePause_Move
EnemyAiChasePause_Tick_SpawnBurst:
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
EnemyAiChasePause_Tick_SpawnNext:
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
	DBF	D7, EnemyAiChasePause_Tick_SpawnNext
	ADDQ.w	#1, obj_attack_timer(A5)
	MOVE.w	#ENEMY_KNOCKBACK_DURATION, obj_knockback_timer(A5)
	BRA.w	EnemyAiChasePause_HandleDamage
EnemyAiChasePause_Move:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
EnemyAiChasePause_HandleDamage:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	EnemyAiChasePause_HandleDamage_CheckMoving
	ADDQ.b	#1, obj_move_counter(A5)
EnemyAiChasePause_HandleDamage_CheckMoving:
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
	BLE.w	EnemyAiChasePause_HandleDamage_SetFlip
	BSET.b	#3, obj_sprite_flags(A5)
EnemyAiChasePause_HandleDamage_SetFlip:
	ASL.w	#3, D1
	ADD.w	D0, D1
	LEA	EnemyAnimFrames_MeleeB_Main, A0
	LEA	EnemyAnimFrames_MeleeB_Child, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	BSR.w	CopyEnemyPositionToChildObject
	JSR	AddSpriteToDisplayList(PC)
	RTS
	

; ======================================================================
; Projectile: Straight (8-direction burst)
; ======================================================================

; ProjectileTick_Straight
; Single-sprite projectile that travels in a fixed direction until it
; leaves the battle field.  Used by BurstFire and FastBurstShooter.
ProjectileTick_Straight:
	JSR	CalculateVelocityFromAngle(PC)
	JSR	ClampProjectileToScreenBounds(PC)
	BTST.b	#7, (A5)
	BEQ.b	ProjectileTick_Straight_Return
	JSR	HandlePlayerTakeDamage(PC)
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	LEA	EnemyAnimFrames_Fireball, A2
	MOVE.w	(A2,D0.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList(PC)
ProjectileTick_Straight_Return:
	RTS
	

; ======================================================================
; Enemy Type: HomingShooter
; ======================================================================

; InitEnemy_HomingShooter
; Stationary enemy (uses CheckAndUpdateBattleTimer).  Randomly fires
; an 8-way fan of ProjectileTick_Homing projectiles that home toward
; the player.
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
	BGT.w	EnemyTick_HomingShooter_Alive
	MOVE.l	#EnemyDeathReward_OneSprite, obj_tick_fn(A5)
	RTS
	
EnemyTick_HomingShooter_Alive:
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
	BEQ.w	EnemyTick_HomingShooter_SpawnProjectiles
	CLR.b	obj_npc_busy_flag(A4)
	CLR.l	obj_vel_x(A4)
	CLR.l	obj_vel_y(A4)
	BRA.w	EnemyMultiProjectile_UpdateSprite
EnemyTick_HomingShooter_SpawnProjectiles:
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
EnemyTick_HomingShooter_SpawnNext:
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
	DBF	D7, EnemyTick_HomingShooter_SpawnNext
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
	BLE.w	EnemyMultiProjectile_UpdateSprite_SetFlip
	BSET.b	#3, obj_sprite_flags(A5)
EnemyMultiProjectile_UpdateSprite_SetFlip:
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
	

; ======================================================================
; Projectile: Homing
; ======================================================================

; ProjectileTick_Homing
; Homing projectile with a two-timer system: obj_attack_timer counts
; down a brief arming delay before the projectile begins homing;
; obj_knockback_timer is the total lifetime.
ProjectileTick_Homing:
	TST.w	obj_knockback_timer(A5)
	BNE.w	ProjectileTick_Homing_Active
	BCLR.b	#7, (A5)
	CLR.b	obj_npc_busy_flag(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	BRA.w	EnemyChase_Move_HandleDamage
ProjectileTick_Homing_Active:
	SUBQ.w	#1, obj_knockback_timer(A5)
	TST.w	obj_attack_timer(A5)
	BNE.w	ProjectileTick_Homing_ArmingDelay
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
ProjectileTick_Homing_ArmingDelay:
	SUBQ.w	#1, obj_attack_timer(A5)
EnemyChase_Move:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	UpdateObjectScreenPosition
EnemyChase_Move_HandleDamage:
	BSR.w	HandlePlayerTakeDamage
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	EnemyChase_Move_UpdateAnim
	ADDQ.b	#1, obj_move_counter(A5)
EnemyChase_Move_UpdateAnim:
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	LEA	EnemyAnimFrames_Fireball, A2
	MOVE.w	(A2,D0.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList
	RTS
	

; ======================================================================
; Child Sprite Helpers
; ======================================================================

; EnemyChildSpriteTick
; Default tick function for passive child sprites; just adds them to
; the display list.
EnemyChildSpriteTick:
	JSR	AddSpriteToDisplayList
	RTS
	

; CopyPositionToLinkedSprite
; Copy sprite_flags, screen_x, and screen_y (offset -16 px) from A5
; to A6 for two-part enemy sprites drawn side-by-side.
CopyPositionToLinkedSprite:
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6)
	MOVE.w	obj_screen_x(A5), obj_screen_x(A6)
	MOVE.w	obj_screen_y(A5), D0
	SUBI.w	#$0010, D0
	MOVE.w	D0, obj_screen_y(A6)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
	RTS
	

; CopyEnemyPositionToChildObject
; Same as CopyPositionToLinkedSprite but offsets screen_y by -24 px
; (used by enemies where the child sprite sits higher above the main).
CopyEnemyPositionToChildObject:
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6)
	MOVE.w	obj_screen_x(A5), obj_screen_x(A6)
	MOVE.w	obj_screen_y(A5), D0
	SUBI.w	#$0018, D0
	MOVE.w	D0, obj_screen_y(A6)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
	RTS
	

; ======================================================================
; Enemy Type: FastBurstShooter
; ======================================================================

; InitEnemy_FastBurstShooter
; Like HomingShooter but fires 8 ProjectileTick_Straight projectiles
; at speed $380 instead of homing ones.  Uses CheckAndUpdateBattleTimer.
InitEnemy_FastBurstShooter:
	BSR.w	InitEnemyAI
	BSR.w	SetEnemyGraphicsParams
	MOVE.l	#EnemyTick_FastBurstShooter, obj_tick_fn(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#EnemyChildSpriteTick, obj_tick_fn(A6)
	BSR.w	SetRandomEnemyPosition
	RTS
	
; EnemyTick_FastBurstShooter
; Per-frame tick: aims at player, then 1-in-128 chance spawns 8
; ProjectileTick_Straight projectiles (one per direction 0-7).
; Speed $380 (fixed-point 3.5 px/frame) per projectile.
EnemyTick_FastBurstShooter:
	BSR.w	CheckAndUpdateBattleTimer
	BGT.w	EnemyTick_FastBurstShooter_Alive
	MOVE.l	#BossDeathReward_MultiSprite, obj_tick_fn(A5)
	RTS
	
EnemyTick_FastBurstShooter_Alive:
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
	BEQ.w	EnemyTick_FastBurstShooter_SpawnProjectiles
	CLR.b	obj_npc_busy_flag(A4)
	CLR.l	obj_vel_x(A4)
	CLR.l	obj_vel_y(A4)
	BRA.w	EnemySpreadShot_UpdateSprite
EnemyTick_FastBurstShooter_SpawnProjectiles:
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
EnemyTick_FastBurstShooter_SpawnNext:
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
	DBF	D7, EnemyTick_FastBurstShooter_SpawnNext
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
	BLE.w	EnemySpreadShot_UpdateSprite_SetFlip
	BSET.b	#3, obj_sprite_flags(A5)
EnemySpreadShot_UpdateSprite_SetFlip:
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
	

; ======================================================================
; Enemy Type: SequentialFire
; ======================================================================

; InitEnemy_SequentialFire
; Moves toward the player, pauses, then fires a slow spread of
; ProjectileTick_Spiral projectiles via an 8-phase jump table.
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
	BGT.w	EnemyTick_SequentialFire_Alive
	MOVE.l	#EnemyDeathReward_OneSprite, obj_tick_fn(A5)
	RTS
	
EnemyTick_SequentialFire_Alive:
	CLR.b	obj_hit_flag(A5)
	MOVE.b	obj_attack_timer(A5), D0
	ANDI.w	#7, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	EnemyAiChaseFireJumpTable, A0
	JMP	(A0,D0.w)
EnemyAiChaseFireJumpTable:
	BRA.w	EnemyAiChaseFireJumpTable_ChasePhase
	BRA.w	ProjectileTick_Phase1
	BRA.w	ProjectileTick_Phase2
	BRA.w	ProjectileTick_Phase3
	BRA.w	EnemyAiChaseFireJumpTable_RetargetPhase
	BRA.w	ProjectileTick_Phase1	
	BRA.w	ProjectileTick_Phase2	
	BRA.w	ProjectileTick_Phase3	
EnemyAiChaseFireJumpTable_ChasePhase:
	SUBQ.w	#1, obj_knockback_timer(A5)
	BLE.w	EnemyAiChaseFireJumpTable_ChaseStop
	MOVEA.l	Player_entity_ptr.w, A6
	JSR	CalculateAngleToObjectCentered(PC)
	MOVE.b	D0, obj_direction(A5)
	BRA.w	ProjectileTick_Move
EnemyAiChaseFireJumpTable_ChaseStop:
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	ADDQ.b	#1, obj_attack_timer(A5)
	MOVE.w	#ENEMY_KNOCKBACK_DURATION, obj_knockback_timer(A5)
	BRA.w	ProjectileTick_PostCollision
EnemyAiChaseFireJumpTable_RetargetPhase:
	TST.w	obj_knockback_timer(A5)
	BEQ.w	EnemyAiChaseFireJumpTable_RetargetStop
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	MOVE.b	D0, obj_direction(A5)
	BRA.w	ProjectileTick_Move
EnemyAiChaseFireJumpTable_RetargetStop:
	CLR.l	obj_vel_x(A5)	
	CLR.l	obj_vel_y(A5)	
	ADDQ.b	#1, obj_attack_timer(A5)	
	MOVE.w	#ENEMY_KNOCKBACK_DURATION, obj_knockback_timer(A5)	
	BRA.w	ProjectileTick_PostCollision	
ProjectileTick_Phase1:
	SUBQ.w	#1, obj_knockback_timer(A5)
	BNE.w	ProjectileTick_PostCollision
	ADDQ.b	#1, obj_attack_timer(A5)
	MOVE.b	#8, obj_sub_timer(A5)
	MOVE.w	#$001E, obj_knockback_timer(A5)
	BRA.w	ProjectileTick_PostCollision
ProjectileTick_Phase2:
	SUBQ.w	#1, obj_knockback_timer(A5)
	BNE.w	ProjectileTick_PostCollision
	MOVE.w	#8, obj_knockback_timer(A5)
	MOVEQ	#0, D7
	MOVE.b	obj_sub_timer(A5), D7
	CLR.w	D0
	LEA	(A5), A6
ProjectileTick_Phase2_SpawnNext:
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, ProjectileTick_Phase2_SpawnNext
	BSET.b	#7, (A6)
	MOVE.w	obj_world_x(A5), obj_pos_x_fixed(A6)
	MOVE.w	obj_world_y(A5), D1
	SUBI.w	#$0018, D1
	MOVE.w	D1, obj_seg_counter(A6)
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
	SUBQ.b	#1, obj_sub_timer(A5)
	BNE.w	ProjectileTick_PostCollision
	ADDQ.b	#1, obj_attack_timer(A5)
	MOVE.w	#$005A, obj_knockback_timer(A5)
	BRA.w	ProjectileTick_PostCollision
ProjectileTick_Phase3:
	SUBQ.w	#1, obj_knockback_timer(A5)
	BNE.w	ProjectileTick_PostCollision
	ADDQ.b	#1, obj_attack_timer(A5)
	JSR	GetRandomNumber
	ANDI.w	#$00F0, D0
	ADDI.w	#$003C, D0
	MOVE.w	D0, obj_knockback_timer(A5)
	BRA.w	ProjectileTick_PostCollision
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
	BLE.b	ProjectileTick_PostCollision_SetFlip
	BSET.b	#3, obj_sprite_flags(A5)
ProjectileTick_PostCollision_SetFlip:
	MOVE.b	obj_attack_timer(A5), D0
	ANDI.w	#3, D0
	CMPI.b	#2, D0
	BGE.b	ProjectileTick_PostCollision_FirePhase
	LEA	EnemyAnimFrames_Fireball_B, A0
	LEA	EnemyAnimFrames_Fireball_C, A1
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0018, D0
	ASR.w	#2, D0
	BRA.b	ProjectileTick_PostCollision_DrawSprite
ProjectileTick_PostCollision_FirePhase:
	LEA	ProjectileTick_PostCollision_Loop2_Data, A0
	LEA	ProjectileTick_PostCollision_Loop2_Data2, A1
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
ProjectileTick_PostCollision_DrawSprite:
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.w	(A1,D0.w), obj_tile_index(A6)
	JSR	CopyPositionToLinkedSprite(PC)
	JSR	AddSpriteToDisplayList(PC)
	RTS
	

; ======================================================================
; Projectile: Spiral
; ======================================================================

; ProjectileTick_Spiral
; Projectile that travels outward in an expanding spiral.  Uses
; obj_xp_reward as a radius counter and obj_direction as the current
; angle into SineTable.
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
	ADD.w	obj_seg_counter(A5), D3
	MOVE.w	D2, obj_world_x(A5)
	MOVE.w	D3, obj_world_y(A5)
	CMPI.w	#0, obj_world_x(A5)
	BLE.w	ProjectileTick_Spiral_OutOfBounds
	CMPI.w	#BATTLE_FIELD_WIDTH, obj_world_x(A5)
	BGE.w	ProjectileTick_Spiral_OutOfBounds
	CMPI.w	#BATTLE_PROJ_Y_TOP, obj_world_y(A5)
	BLE.w	ProjectileTick_Spiral_OutOfBounds
	CMPI.w	#BATTLE_FIELD_BOTTOM, obj_world_y(A5)
	BLE.w	ProjectileTick_Spiral_OutOfBounds_Render
ProjectileTick_Spiral_OutOfBounds:
	BCLR.b	#7, (A5)
	BRA.w	ProjectileTick_Spiral_OutOfBounds_Return
ProjectileTick_Spiral_OutOfBounds_Render:
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
ProjectileTick_Spiral_OutOfBounds_Return:
	RTS
	

; ======================================================================
; Enemy Type: SpiralBurst
; ======================================================================

; InitEnemy_SpiralBurst
; Boss-tier enemy that spawns groups of ProjectileTick_OrbitingSpiral
; projectiles that orbit it before flying outward.  Uses
; CheckAndUpdateBattleTimer and the EnemyAiSpiralJumpTable.
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
	BGT.w	EnemyTick_SpiralBurst_Alive
	MOVE.l	#EnemyDeathReward_OneSprite, obj_tick_fn(A5)	
	RTS
	
EnemyTick_SpiralBurst_Alive:
	CLR.b	obj_hit_flag(A5)
	MOVE.w	obj_attack_timer(A5), D0
	ANDI.w	#7, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	EnemyAiSpiralJumpTable, A0
	JMP	(A0,D0.w)
EnemyAiSpiralJumpTable:
	BRA.w	EnemyAiSpiralJumpTable_ChasePhase
	BRA.w	ProjectileTick2_Phase1
	BRA.w	ProjectileTick2_Phase2
	BRA.w	ProjectileTick2_Phase3
	BRA.w	EnemyAiSpiralJumpTable_RetargetPhase	
	BRA.w	ProjectileTick2_Phase1	
	BRA.w	ProjectileTick2_Phase2	
	BRA.w	ProjectileTick2_Phase3	
EnemyAiSpiralJumpTable_ChasePhase:
	SUBQ.w	#1, obj_knockback_timer(A5)
	BLE.w	EnemyAiSpiralJumpTable_ChaseStop
	MOVEA.l	Player_entity_ptr.w, A6
	JSR	CalculateAngleToObjectCentered(PC)
	MOVE.b	D0, obj_direction(A5)
	BRA.w	ProjectileTick2_Move
EnemyAiSpiralJumpTable_ChaseStop:
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	ADDQ.w	#1, obj_attack_timer(A5)
	MOVE.w	#ENEMY_KNOCKBACK_DURATION, obj_knockback_timer(A5)
	BRA.w	ProjectileTick2_PostCollision
EnemyAiSpiralJumpTable_RetargetPhase:
	TST.w	obj_knockback_timer(A5)	
	BEQ.w	EnemyAiSpiralJumpTable_RetargetStop	
	SUBQ.w	#1, obj_knockback_timer(A5)	
	MOVEA.l	Player_entity_ptr.w, A6	
	BSR.w	CalculateAngleBetweenObjects	
	MOVE.b	D0, obj_direction(A5)	
	BRA.w	ProjectileTick2_Move	
EnemyAiSpiralJumpTable_RetargetStop:
	CLR.l	obj_vel_x(A5)	
	CLR.l	obj_vel_y(A5)	
	ADDQ.b	#1, obj_attack_timer(A5)	
	MOVE.w	#ENEMY_KNOCKBACK_DURATION, obj_knockback_timer(A5)	
	BRA.w	ProjectileTick2_PostCollision	
ProjectileTick2_Phase1:
	TST.w	obj_knockback_timer(A5)
	BEQ.w	ProjectileTick2_Phase1_Advance
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	JSR	CalculateAngleBetweenObjects(PC)
	MOVE.b	D0, obj_direction(A5)
	BRA.w	ProjectileTick2_PostCollision
ProjectileTick2_Phase1_Advance:
	ADDQ.w	#1, obj_attack_timer(A5)
	BRA.w	ProjectileTick2_PostCollision
ProjectileTick2_Phase2:
	MOVE.w	#3, D7
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
ProjectileTick2_Phase2_SpawnNext:
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
	DBF	D7, ProjectileTick2_Phase2_SpawnNext
	ADDQ.w	#1, obj_attack_timer(A5)
	MOVE.w	#$0078, obj_knockback_timer(A5)
	BRA.w	ProjectileTick2_PostCollision
ProjectileTick2_Phase3:
	SUBQ.w	#1, obj_knockback_timer(A5)
	BNE.w	ProjectileTick2_PostCollision
	CLR.w	obj_attack_timer(A5)	
	JSR	GetRandomNumber	
	ANDI.w	#$00F0, D0	
	ADDI.w	#$003C, D0	
	MOVE.w	D0, obj_knockback_timer(A5)	
	BRA.w	ProjectileTick2_PostCollision	
ProjectileTick2_Move:
	BSR.w	CalculateVelocityFromAngle
	BSR.w	CheckEnemyCollision
ProjectileTick2_PostCollision:
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.l	obj_vel_x(A5), D0
	OR.l	obj_vel_y(A5), D0
	BEQ.w	ProjectileTick2_PostCollision_CheckMoving
	ADDQ.b	#1, obj_move_counter(A5)
ProjectileTick2_PostCollision_CheckMoving:
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
	BLE.w	ProjectileTick2_PostCollision_SetFlip
	BSET.b	#3, obj_sprite_flags(A5)
ProjectileTick2_PostCollision_SetFlip:
	ASL.w	#3, D1
	ADD.w	D0, D1
	LEA	EnemyAnimFrames_MeleeB_Main, A0
	LEA	EnemyAnimFrames_MeleeB_Child, A1
	MOVE.w	(A0,D1.w), obj_tile_index(A5)
	MOVE.w	(A1,D1.w), obj_tile_index(A6)
	BSR.w	CopyEnemyPositionToChildObject
	JSR	AddSpriteToDisplayList(PC)
	RTS
	

; ======================================================================
; Projectile: OrbitingSpiral
; ======================================================================

; ProjectileTick_OrbitingSpiral
; Orbits a centre point (obj_orbit_center_x / obj_attack_timer as Y)
; with growing radius until ORBITING_SPIRAL_ORBIT_COUNT is reached,
; then transitions to straight outward movement.
ProjectileTick_OrbitingSpiral:
	CMPI.w	#ORBITING_SPIRAL_ORBIT_COUNT, obj_xp_reward(A5)
	BLT.w	ProjectileTick_OrbitingSpiral_Orbiting
	JSR	CalculateVelocityFromAngle(PC)
	MOVE.l	obj_vel_x(A5), D0
	SUB.l	D0, obj_orbit_center_x(A5)
	MOVE.l	obj_vel_y(A5), D0
	SUB.l	D0, obj_attack_timer(A5)
	BRA.w	ProjectileTick_OrbitingSpiral_UpdatePos
ProjectileTick_OrbitingSpiral_Orbiting:
	ADDQ.w	#1, obj_xp_reward(A5)
ProjectileTick_OrbitingSpiral_UpdatePos:
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
	BLE.w	ProjectileTick_OrbitingSpiral_OutOfBounds_Render
ProjectileTick_OrbitingSpiral_OutOfBounds:
	BCLR.b	#7, (A5)
	BRA.w	ProjectileTick_OrbitingSpiral_OutOfBounds_Return
ProjectileTick_OrbitingSpiral_OutOfBounds_Render:
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
ProjectileTick_OrbitingSpiral_OutOfBounds_Return:
	RTS
	

; ======================================================================
; Boss Type: OrbShield
; ======================================================================

; InitBoss_OrbShield
; Initialises a large boss enemy with a single orbiting shield orb.
; Main body uses BossTick_OrbShield; orb uses BossOrbTick_Static.
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
	

; BossTick_OrbShield
; Per-frame tick: processes damage / invulnerability, then moves the
; orb in a circular scatter pattern around the boss.
BossTick_OrbShield:
	TST.b	obj_invuln_timer(A5)
	BLE.w	BossTick_OrbShield_Loop
	SUBQ.b	#1, obj_invuln_timer(A5)	
	BRA.w	EnemyTakeDamage2_CheckDeath	
BossTick_OrbShield_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.w	EnemyTakeDamage2_CheckDeath
	PlaySound_b	SOUND_HEAL	
	MOVE.w	Player_str.w, D0	
	SUB.w	D0, obj_hp(A5)	
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A5)	
EnemyTakeDamage2_CheckDeath:
	TST.w	obj_hp(A5)
	BGT.w	EnemyTakeDamage2_CheckDeath_Alive
	MOVE.l	#EnemyDeathReward_TwoSprites, obj_tick_fn(A5)
	RTS
	
EnemyTakeDamage2_CheckDeath_Alive:
	CLR.b	obj_hit_flag(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	CMPI.b	#DEATH_SCATTER_ANGLE_COUNT, obj_attack_timer(A5)
	BCS.b	EnemyTakeDamage2_CheckDeath_AnglePhase
	JSR	GetRandomNumber
	ANDI.w	#$00FF, D0
	CMPI.w	#RANDOM_HALF_THRESHOLD, D0
	BLE.b	EnemyTakeDamage2_CheckDeath_ResetAngle
	CLR.b	obj_attack_timer(A5)
EnemyTakeDamage2_CheckDeath_AnglePhase:
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
EnemyTakeDamage2_CheckDeath_ResetAngle:
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
	MOVE.b	obj_sub_timer(A6), D2
	CMPI.w	#$0040, D2
	BLE.b	EnemyTakeDamage2_CheckDeath_ClampRadius
	MOVE.w	#$FFFC, D1
EnemyTakeDamage2_CheckDeath_ClampRadius:
	TST.w	D2
	BGT.b	EnemyTakeDamage2_CheckDeath_CheckRadiusSign
	CLR.w	D2
	MOVE.w	#4, D1
EnemyTakeDamage2_CheckDeath_CheckRadiusSign:
	MOVE.b	D1, obj_knockback_timer(A6)
	ADD.w	D1, D2
	MOVE.b	D2, obj_sub_timer(A6)
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
	

; ======================================================================
; Boss Type: MultiOrb
; ======================================================================

; InitBoss_MultiOrb
; Large boss surrounded by 9 orbiting shield orbs (BossOrbTick_Static).
; Uses BossTick_MultiOrb / BossDeathReward_MultiSprite.
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
	LEA	(A6), A4			; A4 = previous slot
	CLR.w	D0
	MOVE.b	obj_next_offset(A4), D0
	LEA	(A4,D0.w), A6			; A6 = next orb slot
	BSET.b	#7, (A6)			; activate orb
	MOVE.b	#SPRITE_SIZE_2x1, obj_sprite_size(A6)
	MOVE.b	D2, obj_sprite_flags(A6)	; shared palette
	MOVE.w	#VRAM_TILE_ORBIT_BOSS_ORB, obj_tile_index(A6)
	MOVE.l	obj_world_x(A5), obj_world_x(A6); inherit boss X
	MOVE.l	obj_world_y(A5), D1
	SUBI.l	#$00080000, D1			; 8 px above boss centre
	MOVE.l	D1, obj_world_y(A6)
	MOVE.l	#BossOrbTick_Static, obj_tick_fn(A6)
	CLR.l	obj_vel_x(A6)
	CLR.l	obj_vel_y(A6)
	MOVE.w	#4, obj_hitbox_half_w(A6)	; 4 px half-width hitbox
	MOVE.w	#4, obj_hitbox_half_h(A6)	; 4 px half-height hitbox
	MOVE.w	obj_max_hp(A5), obj_max_hp(A6)	; orbs share boss max HP (damage ring)
	CLR.b	obj_invuln_timer(A6)
	MOVE.w	obj_world_x(A6), obj_screen_x(A6)
	MOVE.w	obj_world_y(A6), obj_screen_y(A6)
	MOVE.w	obj_world_y(A6), obj_sort_key(A6)
	DBF	D7, InitBoss_MultiOrb_Done	; repeat for all 9 orb slots
	CLR.b	obj_invuln_timer(A5)
	CLR.w	obj_attack_timer(A5)
	CLR.w	obj_knockback_timer(A5)
	CLR.w	obj_vel_x(A5)
	CLR.w	obj_vel_y(A5)
	RTS
	

; BossTick_MultiOrb
; Per-frame tick: damage / invulnerability; scatter-moves all 9 orbs
; outward when HP falls below threshold.
BossTick_MultiOrb:
	TST.b	obj_invuln_timer(A5)
	BLE.w	BossTick_MultiOrb_Loop
	SUBQ.b	#1, obj_invuln_timer(A5)	
	BRA.w	BossTakeDamage_CheckDeath	
BossTick_MultiOrb_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.w	BossTakeDamage_CheckDeath
	PlaySound_b	SOUND_HEAL	
	MOVE.w	Player_str.w, D0	
	SUB.w	D0, obj_hp(A5)	
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A5)	
BossTakeDamage_CheckDeath:
	TST.w	obj_hp(A5)
	BGT.w	BossTakeDamage_CheckDeath_Alive
	MOVE.l	#BossDeathReward_MultiSprite, obj_tick_fn(A5)	
	RTS
	
BossTakeDamage_CheckDeath_Alive:
	CLR.b	obj_hit_flag(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	TST.b	obj_sub_timer(A5)
	BNE.w	BossTakeDamage_CheckDeath_StaticPhase	; sub_timer > 0 = orb wobble phase
	CMPI.b	#DEATH_SCATTER_ANGLE_COUNT, obj_attack_timer(A5)
	BCS.b	BossTakeDamage_CheckDeath_AnglePhase
	JSR	GetRandomNumber
	ANDI.w	#$00FF, D0
	CMPI.w	#RANDOM_HALF_THRESHOLD, D0		; 50% chance to reset orb scatter angle
	BLE.b	BossTakeDamage_CheckDeath_ResetAngle
	CLR.b	obj_attack_timer(A5)
BossTakeDamage_CheckDeath_AnglePhase:
	ADDQ.b	#1, obj_attack_timer(A5)		; advance angle phase counter
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#2, D0				; offset angle by 2 (45° rotation)
	ANDI.w	#7, D0
	ASL.w	#5, D0				; D0 = sine table offset (dir × 32)
	MOVE.w	D0, D5
	CLR.l	D0
	LEA	SineTable, A0
	MOVE.b	$40(A0,D5.w), D0			; X = cosine component
	ASL.w	#8, D0				; scale to fixed-point
	EXT.l	D0
	NEG.l	D0				; negate for correct X direction
	MOVE.l	D0, obj_vel_x(A5)
	CLR.l	D0
	LEA	SineTable, A0
	MOVE.b	(A0,D5.w), D0			; Y = sine component
	ASL.w	#8, D0				; scale to fixed-point
	EXT.l	D0
	MOVE.l	D0, obj_vel_y(A5)
	BSR.w	CheckEnemyCollision
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	MOVE.w	#8, D7
	LEA	(A5), A4
BossTakeDamage_CheckDeath_ResetOrbPositions:
	CLR.w	D0
	MOVE.b	obj_next_offset(A4), D0
	LEA	(A4,D0.w), A4
	MOVE.l	obj_world_x(A5), obj_world_x(A4)
	MOVE.l	obj_world_y(A5), D0
	SUBI.l	#$00080000, D0
	MOVE.l	D0, obj_world_y(A4)
	DBF	D7, BossTakeDamage_CheckDeath_ResetOrbPositions
	BRA.w	BossTakeDamage_CheckDeath_WobblePhase
BossTakeDamage_CheckDeath_ResetAngle:
	MOVE.b	#$21, obj_sub_timer(A5)		; arm wobble timer (33 frames)
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects	; D0 = 8-dir angle toward player
	ADDQ.b	#2, D0				; rotate 45° for scatter direction
	ANDI.w	#7, D0
	ASL.w	#5, D0				; × 32 = sine table offset
	MOVE.w	D0, obj_knockback_timer(A5)	; save angle for StaticPhase loop
; BossTakeDamage_CheckDeath_StaticPhase
; Orb wobble / scatter phase active while obj_sub_timer > 0.
; Each frame the 9 orbs are repositioned on an expanding/contracting ring
; using a sine-based radius that pulses with sub_timer.
;
; Algorithm:
;   sub_timer counts down from $21 (33).  Half it and subtract 8 to get
;   a signed wobble value in [-8, +8].  ABS gives distance from mid-point.
;   Radius D6 = 2 × (8 - |wobble|), so it peaks at 16 when timer≈$11
;   and tapers to 0 at the ends.  D3 = D6 is the per-orb ring step.
;   Each orb i gets: X = boss_X + cosine(angle) × (D6 + i×D3) >> 8
;                    Y = boss_Y - sine(angle)   × (D6 + i×D3) >> 8  - 8
;
; D5 = obj_knockback_timer (saved sine table offset, set in ResetAngle)
; D6 = current radius (even, 0-16)
; D7 = orb count - 1 (8 orbs)
; A0 = boss object base (kept throughout loop to read boss world_x/y)
BossTakeDamage_CheckDeath_StaticPhase:
	LEA	(A5), A0			; A0 = boss base (for X/Y each iteration)
	SUBQ.b	#1, obj_sub_timer(A5)		; count down wobble timer
	MOVE.w	#8, D7				; 9 orbs (DBF 8→0)
	CLR.l	D0
	MOVE.b	obj_sub_timer(A5), D0
	ASR.w	#1, D0				; half timer → wobble value
	SUBQ.w	#8, D0				; centre around 0: range [-8, +8]
	BGE.b	BossTakeDamage_CheckDeath_AbsWobble
	NEG.w	D0				; ABS: always positive distance from mid
BossTakeDamage_CheckDeath_AbsWobble:
	MOVE.w	obj_knockback_timer(A5), D5	; D5 = saved sine table offset
	MOVEQ	#8, D6
	SUB.w	D0, D6				; D6 = 8 - |wobble|  (peak = 8)
	ADD.w	D6, D6				; × 2  (peak radius = 16 px)
	MOVE.w	D6, D3				; D3 = per-orb ring step (constant)
	LEA	(A5), A6
BossTakeDamage_CheckDeath_UpdateOrbPositions:
	LEA	(A6), A4			; A4 = current orb
	MOVE.w	D6, D1				; D1 = this orb's radius multiplier
	CLR.w	D0
	MOVE.b	obj_next_offset(A4), D0
	LEA	(A4,D0.w), A6			; advance to next orb in list
	CLR.l	D0
	LEA	SineTable, A1
	MOVE.b	$40(A1,D5.w), D0		; cosine (sine offset $40)
	ASL.w	#8, D0				; scale to fixed-point
	EXT.l	D0
	MULS.w	D1, D0				; X offset = cos × radius
	ADD.l	$E(A0), D0			; + boss world_x ($E = obj_world_x)
	MOVE.l	D0, obj_world_x(A6)
	CLR.l	D0
	LEA	SineTable, A1
	MOVE.b	(A1,D5.w), D0			; sine
	ASL.w	#8, D0				; scale to fixed-point
	EXT.l	D0
	MULS.w	D1, D0				; Y offset = sin × radius
	NEG.l	D0				; negate (Y axis is inverted)
	ADD.l	$12(A0), D0			; + boss world_y ($12 = obj_world_y)
	SUBI.l	#$00080000, D0			; shift up by 8 px (orb above boss centre)
	MOVE.l	D0, obj_world_y(A6)
	ADD.w	D3, D6				; advance radius for next orb
	DBF	D7, BossTakeDamage_CheckDeath_UpdateOrbPositions
	LEA	(A0), A5			; restore A5 → boss
	BSR.w	CheckEnemyCollision
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
; BossTakeDamage_CheckDeath_WobblePhase
; Advance and apply boss body animation (fireball loop, 4 frames of 2 ticks each).
BossTakeDamage_CheckDeath_WobblePhase:
	ADDQ.b	#1, obj_move_counter(A5)	; global frame counter
	MOVE.b	obj_move_counter(A5), D1
	ANDI.w	#$000C, D1			; bits 2-3 → 0,4,8,12 (4-frame cycle)
	LSR.w	#1, D1				; → 0,2,4,6  (word table index)
	LEA	EnemyAnimFrames_Fireball_D, A0
	MOVE.w	(A0,D1.w), obj_tile_index(A5)	; select animation frame
	JSR	AddSpriteToDisplayList(PC)
	RTS
	

; ======================================================================
; Boss Type: OrbRing
; ======================================================================

; InitBoss_OrbRing
; Large boss with a ring of 9 orbs positioned on a circle using
; CalculateCircularPosition.  Uses BossTick_OrbRing.
;
; Layout: boss body (A5) + 1 centre orb (slot+1) + 8 ring orbs (slots+2..+9).
;   Centre orb: Y = boss_Y - $10 (16 px above boss), tile $0199, BossOrbTick_Static.
;   Ring orbs:  angle = centre_orb.attack_timer + $10 each; same tile, BossOrbTick_Static.
InitBoss_OrbRing:
	JSR	GetRandomNumber
	MOVE.b	D0, obj_move_counter(A5)	; randomise animation phase
	ANDI.b	#6, D0
	MOVE.b	D0, obj_direction(A5)		; initial facing (even, 0-6)
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A5)
	MOVE.l	#BossTick_OrbRing, obj_tick_fn(A5)
	BSR.w	SetObjectBoundsType2
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6			; A6 = centre orb slot
	BSET.b	#7, (A6)			; activate centre orb
	MOVE.l	obj_world_x(A5), obj_world_x(A6); align X with boss
	MOVE.l	obj_world_y(A5), D1
	SUBI.l	#$00100000, D1			; 16 px above boss
	MOVE.l	D1, obj_world_y(A6)
	MOVE.b	#0, obj_attack_timer(A6)	; angle index starts at 0
	MOVE.b	#SPRITE_SIZE_2x1, obj_sprite_size(A6)
	MOVE.b	obj_sprite_flags(A5), D2	; D2 = palette flags (shared by all orbs)
	MOVE.b	D2, obj_sprite_flags(A6)
	MOVE.w	#$0199, D3			; D3 = orb tile index (shared)
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
	MOVE.w	#7, D7				; 8 ring orbs (DBF 7→0)
InitBoss_OrbRing_Done:
	LEA	(A6), A4			; A4 = previous orb (parent for angle)
	CLR.w	D0
	MOVE.b	obj_next_offset(A4), D0
	LEA	(A4,D0.w), A6			; A6 = next ring orb slot
	BSET.b	#7, (A6)			; activate
	MOVE.b	#SPRITE_SIZE_2x1, obj_sprite_size(A6)
	MOVE.b	D2, obj_sprite_flags(A6)	; shared palette
	MOVE.w	D3, obj_tile_index(A6)		; shared tile $0199
	MOVE.b	$3A(A4), D0			; prev orb's attack_timer (angle index)
	ADDI.w	#$0010, D0			; advance angle by $10 (22.5° apart)
	MOVE.b	D0, obj_attack_timer(A6)	; store this orb's angle index
	JSR	CalculateCircularPosition(PC)	; set world_x/y from angle+radius
	MOVE.l	#BossOrbTick_Static, obj_tick_fn(A6)
	CLR.l	obj_vel_x(A6)
	CLR.l	obj_vel_y(A6)
	MOVE.w	#4, obj_hitbox_half_w(A6)
	MOVE.w	#4, obj_hitbox_half_h(A6)
	MOVE.w	obj_max_hp(A5), obj_max_hp(A6)	; ring orbs inherit boss max HP
	CLR.b	obj_invuln_timer(A6)
	MOVE.w	obj_world_x(A6), obj_screen_x(A6)
	MOVE.w	obj_world_y(A6), obj_screen_y(A6)
	MOVE.w	obj_world_y(A6), obj_sort_key(A6)
	DBF	D7, InitBoss_OrbRing_Done	; repeat for all 8 ring orbs
	CLR.b	obj_invuln_timer(A5)
	CLR.w	obj_attack_timer(A5)
	CLR.w	obj_knockback_timer(A5)
	CLR.w	obj_vel_x(A5)
	CLR.w	obj_vel_y(A5)
	RTS
	

; BossTick_OrbRing
; Per-frame tick: damage / invulnerability; rotates all ring orbs by
; incrementing their angle index each frame.
;
; Hit handling:
;   obj_invuln_timer > 0 → count down, jump to BossTakeDamage2_CheckDeath.
;   obj_hit_flag set     → subtract Player_str from HP, start invuln.
;   SOUND_HEAL is the hit-confirm sfx (misnamed constant).
BossTick_OrbRing:
	TST.b	obj_invuln_timer(A5)
	BLE.w	BossTick_OrbRing_Loop
	SUBQ.b	#1, obj_invuln_timer(A5)	; decrement invulnerability timer
	BRA.w	BossTakeDamage2_CheckDeath	; no new damage while invuln
BossTick_OrbRing_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.w	BossTakeDamage2_CheckDeath	; no hit this frame
	PlaySound_b	SOUND_HEAL		; hit-confirm sfx
	MOVE.w	Player_str.w, D0		; D0 = player STR
	SUB.w	D0, obj_hp(A5)			; subtract damage from boss HP
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A5)	; start invuln window
; BossTakeDamage2_CheckDeath
; Check HP; if ≤ 0 transition to multi-sprite death reward handler.
BossTakeDamage2_CheckDeath:
	TST.w	obj_hp(A5)
	BGT.w	BossTakeDamage2_CheckDeath_Alive
	MOVE.l	#BossDeathReward_MultiSprite, obj_tick_fn(A5)	; switch to death sequence
	RTS
	
; BossTakeDamage2_CheckDeath_Alive
; Scatter-velocity AI for OrbRing boss.  Mirrors BossTakeDamage_CheckDeath_Alive
; but operates on the OrbRing body.
;   obj_knockback_timer: scatter angle counter (0 → DEATH_SCATTER_ANGLE_COUNT)
;   50% RNG chance to reset angle each cycle.
BossTakeDamage2_CheckDeath_Alive:
	CLR.b	obj_hit_flag(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
	CMPI.b	#DEATH_SCATTER_ANGLE_COUNT, obj_knockback_timer(A5)
	BCS.b	BossTakeDamage2_CheckDeath_AnglePhase
	JSR	GetRandomNumber
	ANDI.w	#$00FF, D0
	CMPI.w	#RANDOM_HALF_THRESHOLD, D0		; 50% chance to reset scatter cycle
	BLE.b	BossTakeDamage2_CheckDeath_ResetAngle
	CLR.b	obj_knockback_timer(A5)			; reset angle counter
BossTakeDamage2_CheckDeath_AnglePhase:
	ADDQ.b	#1, obj_knockback_timer(A5)		; advance scatter angle
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects
	ADDQ.b	#2, D0					; offset by 2 (45°)
	ANDI.w	#7, D0
	ASL.w	#5, D0					; × 32 = sine table offset
	MOVE.w	D0, D5
	CLR.l	D0
	LEA	SineTable, A0
	MOVE.b	$40(A0,D5.w), D0			; cosine component
	ASL.w	#8, D0					; scale to fixed-point
	EXT.l	D0
	NEG.l	D0					; negate for correct X direction
	MOVE.l	D0, obj_vel_x(A5)
	CLR.l	D0
	LEA	SineTable, A0
	MOVE.b	(A0,D5.w), D0				; sine component
	ASL.w	#8, D0					; scale to fixed-point
	EXT.l	D0
	MOVE.l	D0, obj_vel_y(A5)
BossTakeDamage2_CheckDeath_ResetAngle:
	BSR.w	CheckEnemyCollision
	BSR.w	HandlePlayerTakeDamage
	BSR.w	CheckObjectOnScreen
	ADDQ.b	#1, obj_move_counter(A5)		; advance body animation counter
	MOVE.b	obj_move_counter(A5), D1
	ANDI.w	#$000C, D1				; 4-frame animation cycle
	LSR.w	#1, D1					; → word table index (0,2,4,6)
	LEA	EnemyAnimFrames_Fireball_D, A0
	MOVE.w	(A0,D1.w), obj_tile_index(A5)		; apply boss body frame
	LEA	(A5), A0				; A0 = boss (preserved across orb loop)
	CLR.w	D5
	MOVE.b	obj_next_offset(A5), D5
	LEA	(A5,D5.w), A6				; A6 = centre orb
	MOVE.l	obj_world_x(A5), obj_world_x(A6)	; keep centre orb aligned
	MOVE.l	obj_world_y(A5), D1
	SUBI.l	#$00100000, D1				; 16 px above boss
	MOVE.l	D1, obj_world_y(A6)
	BSET.b	#7, (A6)				; ensure centre orb is active
	CLR.w	D6					; D6 = cumulative angle adjustment
	MOVE.w	#7, D7					; 8 ring orbs (DBF 7→0)
; BossTakeDamage2_CheckDeath_RotateOrbs
; Each ring orb: check if its slot-index (obj_move_counter & 7) ≥ 6 to decide
; whether to fire a projectile toward the player.  Rotate angle toward player
; using a signed delta, then re-position via CalculateCircularPosition.
BossTakeDamage2_CheckDeath_RotateOrbs:
	MOVE.b	$1B(A0), D0				; A0.orb move_counter
	ANDI.b	#7, D0					; keep low 3 bits
	CMPI.b	#6, D0					; ≥ 6 → launch projectile
	BLT.b	BossTakeDamage2_CheckDeath_SkipLaunch
	LEA	(A6), A4				; A4 = this orb
	LEA	(A4), A5
	MOVEA.l	Player_entity_ptr.w, A6
	BSR.w	CalculateAngleBetweenObjects		; D0 = raw 8-dir angle to player
	ADDQ.b	#2, D0
	ANDI.w	#7, D0
	ASL.w	#5, D0					; × 32 = target sine offset
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A6				; next orb
	CLR.w	D1
	MOVE.b	obj_attack_timer(A6), D1		; current orb angle
	ADD.b	D6, D1					; add cumulative rotation
	ANDI.w	#$00FF, D1
	MOVE.w	#1, D2					; D2 = rotation direction (+1 or -1)
	SUB.w	D1, D0					; angular delta
	BGE.b	BossTakeDamage2_CheckDeath_CheckAngleDir
	NEG.w	D0
	NEG.w	D2					; flip direction
BossTakeDamage2_CheckDeath_CheckAngleDir:
	CMPI.w	#$0080, D0				; if delta > 128 (half-circle), flip
	BLE.b	BossTakeDamage2_CheckDeath_CheckAngleRange
	NEG.w	D2
BossTakeDamage2_CheckDeath_CheckAngleRange:
	ADD.w	D2, D1					; step angle toward target
	ADD.w	D2, D6					; accumulate rotation for next orb
	MOVE.b	D1, obj_attack_timer(A6)		; store updated angle
BossTakeDamage2_CheckDeath_SkipLaunch:
	JSR	CalculateCircularPosition(PC)		; reposition orb on ring
	BSET.b	#7, (A6)				; activate orb
	DBF	D7, BossTakeDamage2_CheckDeath_RotateOrbs
	LEA	(A0), A5
	JSR	AddSpriteToDisplayList(PC)
	RTS


; BossOrbTick_Static
; Per-frame tick for individual boss orbs.  Zeroes velocity, syncs
; screen position from world position, and calls HandlePlayerTakeDamage.
; Skips AddSpriteToDisplayList if the orb is off-screen.
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

; ======================================================================
; Utility: Shared Helpers
; ======================================================================

; CalculateCircularPosition
; Compute a world-space (X, Y) coordinate on a circle given a radius
; and an angle index (0-15).  Used by boss orb positioning each frame.
CalculateCircularPosition:
	CLR.w	D5
	MOVE.b	obj_attack_timer(A6), D5	; D5 = orbit angle index (0-63)
	LEA	SineTable, A2
	MOVE.b	$40(A2,D5.w), D0		; X = sine[angle + $40] = cosine[angle]
	EXT.w	D0
	ASR.w	#4, D0				; scale: divide by 16 (→ orbit radius)
	ADD.w	obj_world_x(A4), D0		; offset from parent X
	MOVE.w	D0, obj_world_x(A6)
	LEA	SineTable, A2
	MOVE.b	(A2,D5.w), D0			; Y = -sine[angle]
	EXT.w	D0
	ASR.w	#4, D0				; scale by 16
	NEG.w	D0				; negate (Y increases downward)
	ADD.w	obj_world_y(A4), D0		; offset from parent Y
	MOVE.w	D0, obj_world_y(A6)
	RTS

; BossDeathReward_MultiSprite
; Death reward handler for multi-sprite bosses.  Awards XP and kims,
; decrements enemy count, and deactivates all child orb objects.
;
; Transition: sets obj_tick_fn = EnemyDeathAnimation on A5, clears
; move_counter, then walks the 9 child slots via obj_next_offset and
; clears bit 7 (active flag) on each one.
BossDeathReward_MultiSprite:
	PlaySound_b	SOUND_MAGIC_EFFECT		; boss-death fanfare
	MOVEQ	#0, D0
	MOVE.w	obj_xp_reward(A5), D0
	MOVE.l	D0, Transaction_amount.w
	JSR	AddExperiencePoints			; award XP
	MOVEQ	#0, D0
	MOVE.w	obj_kim_reward(A5), D0
	MOVE.l	D0, Transaction_amount.w
	JSR	AddPaymentAmount			; award kims
	SUBQ.w	#1, Number_Of_Enemies.w			; decrement enemy counter
	CLR.b	obj_move_counter(A5)
	MOVE.l	#EnemyDeathAnimation, obj_tick_fn(A5)	; start body death flash
	MOVE.b	#NPC_ATTR_PAL3, obj_sprite_flags(A5)	; death palette
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A5)
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6				; A6 = first child orb
	BCLR.b	#7, (A6)				; deactivate orb 1
	MOVE.w	#8, D6					; 9 children total (1 done, 8 remain)
BossDeathReward_MultiSprite_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6				; advance to next child
	BCLR.b	#7, (A6)				; deactivate
	DBF	D6, BossDeathReward_MultiSprite_Done
	RTS

; ======================================================================
; Data Tables
; ======================================================================

; EnemyDirectionAnimTable
; Maps a 4-bit quadrant code (built by CalculateAngleBetweenObjects) to
; a sprite-direction index (0-7: right, up-right, up, up-left, left, …).
EnemyDirectionAnimTable:
	dc.b	$06, $05, $05, $04, $06, $07, $07, $00, $02, $03, $03, $04, $02, $01, $01, $00 

; EnemyPositionOffsetTable
; 8 (X, Y) word pairs, one per direction.  Used by HandlePlayerTakeDamage
; to nudge the player away from the enemy on contact.
EnemyPositionOffsetTable:
	dc.w	0, -16
	dc.w	-8, -8 
	dc.w	-16, 0 
	dc.w	-8, 8 
	dc.w	0, 16 
	dc.w	8, 8 
	dc.w	16, 0 
	dc.w	8, -8 

; ApplyDamageToPlayer
; Computes damage = enemy's obj_max_hp minus (Player_AC >> 3), minimum 1.
; Subtracts from Player_hp, clamped at 0.
ApplyDamageToPlayer:
	MOVE.w	obj_max_hp(A5), D1		; D1 = base damage (enemy attack power)
	MOVE.w	Player_ac.w, D0
	ASR.w	#3, D0				; AC / 8 = defence reduction
	SUB.w	D0, D1				; net damage = attack - defence
	BGT.w	ApplyDamageToPlayer_ClampMin
	MOVEQ	#1, D1				; minimum 1 damage (always hurts)
ApplyDamageToPlayer_ClampMin:
	SUB.w	D1, Player_hp.w			; apply damage to player HP
	BGE.w	ApplyDamageToPlayer_ClampZero
	CLR.w	Player_hp.w			; clamp to 0 (no negative HP)
ApplyDamageToPlayer_ClampZero:
	RTS

; SetRandomEnemyPosition
; Picks random X in [1, SPAWN_ZONE_X_MAX] and Y in [SPAWN_ZONE_Y_MIN,
; SPAWN_ZONE_Y_MAX], wrapping values that fall outside those ranges.
; Then checks whether the result falls inside the player-safe zone
; (SPAWN_SAFE_X_MIN–BATTLE_FIELD_BOTTOM × SPAWN_SAFE_Y_MIN–SPAWN_SAFE_Y_MAX);
; if so, retries recursively until a valid position is found.
SetRandomEnemyPosition:
	CLR.w	D0
	JSR	GetRandomNumber
	ANDI.w	#$01FF, D0			; 9-bit random X (0-511)
	CMPI.w	#1, D0				; X < 1 → mirror wrap
	BGT.w	SetRandomEnemyPosition_WrapX
	MOVE.w	#1, D1
	SUB.w	D0, D1
	MOVE.w	#SPAWN_ZONE_X_MAX, D0		; wrap from right edge
	SUB.w	D1, D0
	BRA.w	SetRandomEnemyPosition_SetX
SetRandomEnemyPosition_WrapX:
	CMPI.w	#SPAWN_ZONE_X_MAX, D0		; X ≥ max → wrap to low end
	BLT.w	SetRandomEnemyPosition_SetX
	SUBI.w	#SPAWN_ZONE_X_MAX, D0
	ADDQ.w	#1, D0
SetRandomEnemyPosition_SetX:
	MOVE.w	D0, obj_world_x(A5)		; store clamped X
	CLR.w	D0
	JSR	GetRandomNumber
	ANDI.w	#$00FF, D0			; 8-bit random Y (0-255)
	CMPI.w	#SPAWN_ZONE_Y_MIN, D0		; Y < min → mirror wrap
	BGT.w	SetRandomEnemyPosition_WrapY
	MOVE.w	#SPAWN_ZONE_Y_MIN, D1
	SUB.w	D0, D1
	MOVE.w	#SPAWN_ZONE_Y_MAX, D0		; wrap from bottom edge
	SUB.w	D1, D0
	BRA.w	SetRandomEnemyPosition_SetY
SetRandomEnemyPosition_WrapY:
	CMPI.w	#SPAWN_ZONE_Y_MAX, D0		; Y ≥ max → wrap to low end
	BLT.b	SetRandomEnemyPosition_SetX
	SUBI.w	#SPAWN_ZONE_Y_MAX, D0
	ADDI.w	#SPAWN_ZONE_Y_MIN, D0
SetRandomEnemyPosition_SetY:
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

; InitEnemyAI
; Common enemy initialisation: load stats from the encounter table,
; set HP, attack, and speed; call SetRandomEnemyPosition; load A6 to
; point at the next (child) object in the linked list.
;
; Sets a random initial obj_direction (even value 0-6) and randomises
; obj_move_counter for animation phase staggering.
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

; ProcessEnemyDamage
; Check for a pending hit (obj_hit_flag), apply player STR damage, and
; start the invulnerability timer.  Returns CC with HP sign in flags so
; callers can BGT/BLE to branch on alive/dead.
;
; Registers: D0 scratch; A5 enemy object.
; Side-effects: obj_invuln_timer decremented each frame;
;   obj_knockback_timer set to $0078 on a new hit.
ProcessEnemyDamage:
	TST.b	obj_invuln_timer(A5)
	BLE.w	ProcessEnemyDamage_Loop
	SUBQ.b	#1, obj_invuln_timer(A5)
	BRA.w	EnemyTakeDamage_Done
ProcessEnemyDamage_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.w	EnemyTakeDamage_Done
	PlaySound_b	SOUND_HEAL			; hit-confirm sfx
	MOVE.w	#$0078, obj_knockback_timer(A5)		; set knockback window (120 frames)
	MOVE.w	Player_str.w, D0
	SUB.w	D0, obj_hp(A5)				; subtract player STR from HP
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A5)
EnemyTakeDamage_Done:
	TST.w	obj_hp(A5)
	RTS

; CheckAndUpdateBattleTimer
; Variant of ProcessEnemyDamage used by shooter/boss enemies.  Also
; decrements the battle encounter timer and ends the encounter when
; the timer reaches zero.
;
; Identical hit/invuln logic to ProcessEnemyDamage; the "battle timer"
; aspect is handled by the callers that check EnemyTakeDamage3_Done CC.
CheckAndUpdateBattleTimer:
	TST.b	obj_invuln_timer(A5)
	BLE.w	CheckAndUpdateBattleTimer_Loop
	SUBQ.b	#1, obj_invuln_timer(A5)
	BRA.w	EnemyTakeDamage3_Done
CheckAndUpdateBattleTimer_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.w	EnemyTakeDamage3_Done
	PlaySound_b	SOUND_HEAL
	MOVE.w	Player_str.w, D0
	SUB.w	D0, obj_hp(A5)
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A5)
EnemyTakeDamage3_Done:
	TST.w	obj_hp(A5)
	RTS

; SetEnemyGraphicsParams
; Set tile index, sprite size, and hitbox half-widths for the main
; enemy sprite using hardcoded defaults.
SetEnemyGraphicsParams:
	MOVE.w	#VRAM_TILE_ENEMY_BASE, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_2x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000E, obj_hitbox_half_h(A5)
	RTS

; SetObjectBoundsType2
; Alternate graphics/hitbox setup: uses VRAM_TILE_ENEMY_ALT, 4x4 sprite,
; 12x14 half-extents.
SetObjectBoundsType2:
	MOVE.w	#VRAM_TILE_ENEMY_ALT, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000E, obj_hitbox_half_h(A5)
	RTS

; SetObjectBoundsType1
; Standard graphics/hitbox setup: uses VRAM_TILE_ENEMY_BASE, 3x4 sprite,
; 12x12 half-extents.
SetObjectBoundsType1:
	MOVE.w	#VRAM_TILE_ENEMY_BASE, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000C, obj_hitbox_half_h(A5)
	RTS

; InitEnemyProjectileSpeed
; Set up graphics and hitbox for the projectile slot (third child object)
; and store the speed value in obj_pos_x_fixed ready for
; CalculateVelocityFromAngle.
InitEnemyProjectileSpeed:
	MOVE.w	#VRAM_TILE_ENEMY_BASE, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_2x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000C, obj_hitbox_half_h(A5)
	RTS

; SetEnemyCollisionBounds
; Set tile index, 2x4 sprite size, and 12x12 hitbox half-extents.
; Used by IntermittentChase enemies that also need collision bounds.
SetEnemyCollisionBounds:
	MOVE.w	#VRAM_TILE_ENEMY_BASE, obj_tile_index(A5)
	MOVE.b	#SPRITE_SIZE_2x4, obj_sprite_size(A5)
	MOVE.w	#$000C, obj_hitbox_half_w(A5)
	MOVE.w	#$000C, obj_hitbox_half_h(A5)
	RTS

; ======================================================================
; Battle Initialization
; ======================================================================

; EnemyStartingPositions
; 8 (X, Y) world-coordinate pairs used as preset spawn locations for
; enemies at the start of a random encounter.
EnemyStartingPositions:
	dc.w	$1E, $40
	dc.w	$5E, $40
	dc.w	$9E, $40
	dc.w	$DE, $40
	dc.w	$1E, $A0
	dc.w	$5E, $A0
	dc.w	$9E, $A0
	dc.w	$DE, $A0 

; InitBattleEntities
; Entry point called when a battle starts.  Reads Battle_type, masks
; to the lower nibble, and dispatches through BattleEntityInitJumpTable.
; The nibble selects among 14 possible boss/encounter configurations
; (0–13 defined in BattleEntityInitJumpTable below).
InitBattleEntities:
	LEA	BattleEntityInitJumpTable, A0
	MOVE.w	Battle_type.w, D0
	ANDI.w	#$000F, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	JSR	(A0,D0.w)
	RTS

; BattleEntityInitJumpTable
; BRA table indexed by the lower nibble of Battle_type.
; Each entry calls the appropriate boss/encounter initialiser.
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

; ======================================================================
; Boss 1 (Demon Ring): Initialization
; ======================================================================

; InitBoss1_Normal / InitBoss1_Hard / InitBoss1_VeryHard
; Set up the Boss1 HP ring values based on difficulty then fall through
; to InitBoss1_Common.
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
	MOVE.l	#BOSS1_VEL_SPAWN_LEFT, obj_vel_x(A6)	; initial leftward drift (-0.875 px/frame)
	MOVE.l	#BOSS1_VEL_HALF_DOWN, obj_vel_y(A6)	; slow downward drift (+0.5 px/frame)
	MOVE.b	(A0)+, obj_sprite_size(A6)
	CLR.w	D0
	MOVE.b	(A0)+, D0
	MOVE.w	D0, obj_sort_key(A6)
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVE.w	#BOSS1_HEAD_HOME_X, obj_world_x(A6)	; spawn X = 110 (centre-right of field)
	MOVE.w	#BOSS1_HEAD_HOME_Y, obj_world_y(A6)	; spawn Y = 96 (upper-middle of field)
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
	MOVE.w	#BOSS1_HEAD_HOME_X, obj_world_x(A6)		; neck spawn X = 110 (aligned with head)
	MOVE.w	#$006C, obj_world_y(A6)		; neck spawn Y = 108 (just below head)
	MOVE.l	#Boss1_NeckTick, obj_tick_fn(A6)
	MOVE.w	#1, D7
InitBoss1_Common_NeckLoop:
	BSR.w	InitNextSpriteSlot
	DBF	D7, InitBoss1_Common_NeckLoop
	MOVEA.l	Object_slot_03_ptr.w, A6		; upper body (wing joint)
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
	MOVE.w	#SOUND_PLAYER_HIT, obj_world_x(A6)	; upper-body spawn X (raw constant = pixel pos)
	MOVE.w	#BOSS1_BODY_HOME_Y, obj_world_y(A6)		; upper-body spawn Y = 112
	MOVE.l	#Boss1_UpperBodyTick, obj_tick_fn(A6)
	MOVE.b	#$F0, obj_hitbox_x_neg(A6)		; hitbox: -16 px left
	MOVE.b	#$10, obj_hitbox_x_pos(A6)		; hitbox: +16 px right
	MOVE.b	#SOUND_LEVEL_UP, obj_hitbox_y_neg(A6)	; hitbox: raw constant = -$xx px up
	MOVE.b	#0, obj_hitbox_y_pos(A6)
	MOVE.w	#0, D7
InitBoss1_Common_UpperBodyLoop:
	BSR.w	InitNextSpriteSlot
	DBF	D7, InitBoss1_Common_UpperBodyLoop
	MOVEA.l	Object_slot_04_ptr.w, A6		; mid-body
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
	MOVE.w	#BOSS1_MIDBODY_HOME_X, obj_world_x(A6)		; mid-body spawn X = 200
	MOVE.w	#BOSS1_BODY_HOME_Y, obj_world_y(A6)		; mid-body spawn Y = 112
	MOVE.l	#Boss1_MidBodyTick, obj_tick_fn(A6)
	MOVE.b	#$F0, obj_hitbox_x_neg(A6)
	MOVE.b	#$10, obj_hitbox_x_pos(A6)
	MOVE.b	#SOUND_LEVEL_UP, obj_hitbox_y_neg(A6)
	MOVE.b	#0, obj_hitbox_y_pos(A6)
	MOVE.w	#0, D7
InitBoss1_Common_MidBodyLoop:
	BSR.w	InitNextSpriteSlot
	DBF	D7, InitBoss1_Common_MidBodyLoop
	MOVEA.l	Object_slot_05_ptr.w, A6		; tail
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
	MOVE.w	#BOSS1_TAIL_HOME_X, obj_world_x(A6)		; tail spawn X = 218
	MOVE.w	#BOSS1_BODY_HOME_Y, obj_world_y(A6)		; tail spawn Y = 112
	MOVE.l	#Boss1_TailTick, obj_tick_fn(A6)
	MOVE.w	#0, D7
InitBoss1_Common_TailLoop:
	BSR.w	InitNextSpriteSlot
	DBF	D7, InitBoss1_Common_TailLoop
	MOVEA.l	Object_slot_06_ptr.w, A6		; wings (slots 06-08, 3 sprites)
	LEA	EnemySpriteFrameDataA_06, A0		; wing frame data
	LEA	EnemySpriteFrameDataA_07, A1		; wing screen position table
	MOVE.w	#2, D7					; 3 wing sprites (DBF = 0-2)
InitBoss1_Common_WingLoop:
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
	DBF	D7, InitBoss1_Common_WingLoop
	BSR.w	DrawBossPortrait
	BSR.w	DrawBossAttackGraphic1
	RTS
	

; Boss1_MainTick
; Per-frame tick: dispatch through BossAiStateJumpTable, then run
; damage/palette, parallax, and player-collision helpers.
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
	
; BossAiStateJumpTable
; Indexed by Boss_ai_state & $F (0-8).  Each entry is a BRA.w to the
; corresponding AI state handler.
BossAiStateJumpTable:
	BRA.w	Boss1State_InitIdle		; 0 = BOSS1_STATE_INIT_IDLE
	BRA.w	Boss1State_ChooseAction		; 1 = BOSS1_STATE_CHOOSE_ACTION
	BRA.w	Boss1State_MoveDown		; 2 = BOSS1_STATE_MOVE_DOWN
	BRA.w	Boss1State_HeadExtend		; 3 = BOSS1_STATE_HEAD_EXTEND
	BRA.w	Boss1State_AttackWait		; 4 = BOSS1_STATE_ATTACK_WAIT
	BRA.w	Boss1State_LungeLeft		; 5 = BOSS1_STATE_LUNGE_LEFT
	BRA.w	Boss1State_ReturnHome		; 6 = BOSS1_STATE_RETURN_HOME
	BRA.w	Boss1State_HeadRetract		; 7 = BOSS1_STATE_HEAD_RETRACT
	BRA.w	Boss1State_ChargeDownLeft	; 8 = BOSS1_STATE_CHARGE_DOWN_LEFT

; ======================================================================
; Boss 1 AI State Machine
; ======================================================================

; Boss1State_InitIdle
; Entry state: randomly choose the first movement direction and transition
; to Boss1State_ChooseAction.
Boss1State_InitIdle:
	JSR	GetRandomNumber
	ANDI.w	#$003F, D0
	MOVE.b	D0, obj_invuln_timer(A5)
	ADDQ.w	#1, Boss_ai_state.w
	RTS

; Boss1State_ChooseAction
; Decrements cooldown timer.  On expiry: if player is right-of-screen,
; 75% chance to charge diagonally down-left; otherwise drift right+down.
Boss1State_ChooseAction:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGE.w	Boss1State_MoveRight_Loop
	BSR.w	CheckPlayerLeftOfScreen
	BEQ.b	Boss1State_MoveRight
	JSR	GetRandomNumber
	ANDI.w	#3, D0
	BEQ.b	Boss1State_MoveRight
	MOVE.w	#BOSS1_STATE_CHARGE_DOWN_LEFT, Boss_ai_state.w
	MOVE.l	#BOSS1_VEL_HALF_UP, obj_vel_x(A5)	; charge left at -0.5 px/frame
	MOVE.l	#BOSS1_VEL_CHARGE_DOWN, obj_vel_y(A5)	; charge down at +2.0 px/frame
	RTS

; Boss1State_MoveRight / Boss1State_MoveRight_Loop
; Sets MOVE_DOWN state and gives the body a slow right+down drift.
; Boss1State_MoveRight_Loop is the idle fall-through RTS.
Boss1State_MoveRight:
	MOVE.w	#BOSS1_STATE_MOVE_DOWN, Boss_ai_state.w
	MOVE.l	#BOSS1_VEL_QUARTER_RIGHT, obj_vel_x(A5)	; drift right at +0.25 px/frame
	MOVE.l	#BOSS1_VEL_HALF_DOWN, obj_vel_y(A5)	; drift down at +0.5 px/frame
Boss1State_MoveRight_Loop:
	RTS

; Boss1State_MoveDown / Boss1State_PauseAndReset
; Waits until Y > RING_GUARDIAN_Y_LOWER then stops movement and
; transitions to HEAD_EXTEND so the boss can strike downward.
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

; Boss1State_HeadExtend
; Counts down timer; on expiry advances to ATTACK_WAIT and rearms timer.
; Each frame nudges the neck (slot 02) right and down by $10/$40 pixels.
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
	
; Boss1State_HeadRetract
; Counts down obj_invuln_timer; when expired transitions to ReturnHome
; and sets the body moving up-left.  Each frame shifts the neck (slot 02)
; back toward its resting position.
Boss1State_HeadRetract:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGE.b	Boss1State_HeadRetract_Loop
	MOVE.w	#BOSS1_STATE_RETURN_HOME, Boss_ai_state.w
	MOVE.l	#BOSS1_VEL_QUARTER_LEFT, obj_vel_x(A5)	; retreat left at -0.25 px/frame
	MOVE.l	#BOSS1_VEL_HALF_UP, obj_vel_y(A5)	; retreat up at -0.5 px/frame
Boss1State_HeadRetract_Loop:
	MOVEA.l	Object_slot_02_ptr.w, A6
	SUBI.l	#$1000, obj_world_x(A6)
	SUBI.l	#$4000, obj_world_y(A6)
	RTS
	
; Boss1State_AttackWait
; Holds the head extended for BOSS1_HEAD_PAUSE_TICKS frames.
; Falls through each frame to Boss1State_AttackWait_CheckLunge which
; will trigger a lunge if the player is to the left of the screen.
Boss1State_AttackWait:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGE.b	Boss1State_AttackWait_CheckLunge
	MOVE.b	#BOSS1_HEAD_PAUSE_TICKS, obj_invuln_timer(A5)
	MOVE.w	#BOSS1_STATE_HEAD_RETRACT, Boss_ai_state.w
	RTS
	
Boss1State_AttackWait_CheckLunge:
	BSR.w	CheckPlayerLeftOfScreen
	BEQ.b	Boss1State_AttackWait_Return
	MOVE.w	#BOSS1_STATE_LUNGE_LEFT, Boss_ai_state.w
	MOVE.l	#BOSS1_VEL_LUNGE_LEFT, obj_vel_x(A5)	; lunge left at -2.0 px/frame
	MOVE.l	#0, obj_vel_y(A5)
	RTS
	
Boss1State_AttackWait_Return:
	RTS
	
; Boss1State_LungeLeft
; Drives the head leftward at high speed until X ≤ $005A (90 pixels),
; then transitions to ReturnHome with a rightward bounce velocity.
Boss1State_LungeLeft:
	MOVE.w	obj_world_x(A5), D0
	CMPI.w	#BOSS1_LUNGE_TARGET_X, D0		; lunge target X = 90 px from left edge
	BGE.b	Boss1State_LungeLeft_Loop
	MOVE.w	#BOSS1_STATE_RETURN_HOME, Boss_ai_state.w
	MOVE.l	#BOSS1_VEL_QUARTER_RIGHT, obj_vel_x(A5)	; bounce right at +0.25 px/frame
	MOVE.l	#BOSS1_VEL_HALF_UP, obj_vel_y(A5)	; drift up at -0.5 px/frame
Boss1State_LungeLeft_Loop:
	RTS

; Boss1State_ChargeDownLeft
; Charges diagonally down-left until Y reaches RING_GUARDIAN_Y_LOWER,
; then transitions to ReturnHome.
; NOTE: obj_vel_y is set to #Tilemap_buffer_plane_a (the address value),
; which is used as a raw word velocity constant — a quirk of the original
; code that happens to produce the correct downward drift speed.
Boss1State_ChargeDownLeft:
	CMPI.w	#RING_GUARDIAN_Y_LOWER, obj_world_y(A5)
	BLE.b	Boss1State_ChargeDownLeft_Loop
	MOVE.w	#BOSS1_STATE_RETURN_HOME, Boss_ai_state.w
	MOVE.l	#BOSS1_VEL_QUARTER_RIGHT, obj_vel_x(A5)	; drift right at +0.25 px/frame
	MOVE.l	#Tilemap_buffer_plane_a, obj_vel_y(A5)	; raw addr used as velocity word
Boss1State_ChargeDownLeft_Loop:
	RTS

; Boss1State_ReturnHome
; Waits until the head Y ≤ BOSS1_HEAD_HOME_Y (96 px), then snaps ALL five
; body slots back to their resting coordinates and resets the AI state
; to BOSS1_STATE_INIT_IDLE.  Velocities are zeroed so the boss pauses
; before the next attack cycle begins.
;   Tail  (slot 05): X=BOSS1_TAIL_HOME_X ($00DA), Y=BOSS1_BODY_HOME_Y ($0070)
;   MidBody (slot 04): X=BOSS1_MIDBODY_HOME_X ($00C8), Y=BOSS1_BODY_HOME_Y ($0070)
;   UpperBody (slot 03): X=SOUND_PLAYER_HIT (raw value), Y=BOSS1_BODY_HOME_Y ($0070)
;   Neck  (slot 02): X=BOSS1_HEAD_HOME_X ($006E), Y=BOSS1_NECK_HOME_Y ($006C)
;   Head  (A5 = slot 01): X=BOSS1_HEAD_HOME_X ($006E), Y=BOSS1_HEAD_HOME_Y ($0060)
Boss1State_ReturnHome:
	MOVE.w	obj_world_y(A5), D0
	CMPI.w	#BOSS1_HEAD_HOME_Y, D0			; home Y = 96 px (upper-middle)
	BGT.b	Boss1State_ReturnHome_Loop
	MOVE.w	#BOSS1_HEAD_HOME_X, obj_world_x(A5)	; head home X = 110
	MOVE.w	#BOSS1_HEAD_HOME_Y, obj_world_y(A5)	; head home Y = 96
	MOVEA.l	Object_slot_05_ptr.w, A6
	MOVE.w	#BOSS1_TAIL_HOME_X, obj_world_x(A6)	; tail home X = 218
	MOVE.w	#BOSS1_BODY_HOME_Y, obj_world_y(A6)	; tail home Y = 112
	MOVEA.l	Object_slot_04_ptr.w, A6
	MOVE.w	#BOSS1_MIDBODY_HOME_X, obj_world_x(A6)	; mid-body home X = 200
	MOVE.w	#BOSS1_BODY_HOME_Y, obj_world_y(A6)	; mid-body home Y = 112
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.w	#SOUND_PLAYER_HIT, obj_world_x(A6)	; upper-body home X (raw constant)
	MOVE.w	#BOSS1_BODY_HOME_Y, obj_world_y(A6)	; upper-body home Y = 112
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.w	#BOSS1_HEAD_HOME_X, obj_world_x(A6)	; neck home X = 110 (aligned with head)
	MOVE.w	#BOSS1_NECK_HOME_Y, obj_world_y(A6)	; neck home Y = 108
	MOVE.w	#BOSS1_STATE_INIT_IDLE, Boss_ai_state.w
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
Boss1State_ReturnHome_Loop:
	RTS

; Boss1_DeathSequence
; Plays the boss death animation, awards XP/kims, and triggers the
; post-battle cutscene once the flash sequence finishes.
; Sets all five body slots to fall downward at +0.5 px/frame ($8000),
; clears horizontal velocity, then swaps the neck tick function to
; Boss1_NeckTickNoCollision so the body can scroll off-screen safely.
Boss1_DeathSequence:
	CLR.l	obj_vel_x(A5)
	MOVE.l	#BOSS1_VEL_HALF_DOWN, obj_vel_y(A5)	; head falls down at +0.5 px/frame
	MOVE.b	#0, obj_move_counter(A5)
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.l	#Boss1_NeckTickNoCollision, obj_tick_fn(A6)
	CLR.l	obj_vel_x(A6)
	MOVE.l	#BOSS1_VEL_HALF_DOWN, obj_vel_y(A6)	; neck falls at +0.5 px/frame
	MOVEA.l	Object_slot_03_ptr.w, A6
	CLR.l	obj_vel_x(A6)
	MOVE.l	#BOSS1_VEL_HALF_DOWN, obj_vel_y(A6)	; upper-body falls at +0.5 px/frame
	MOVEA.l	Object_slot_04_ptr.w, A6
	CLR.l	obj_vel_x(A6)
	MOVE.l	#BOSS1_VEL_HALF_DOWN, obj_vel_y(A6)	; mid-body falls at +0.5 px/frame
	MOVEA.l	Object_slot_05_ptr.w, A6
	CLR.l	obj_vel_x(A6)
	MOVE.l	#BOSS1_VEL_HALF_DOWN, obj_vel_y(A6)	; tail falls at +0.5 px/frame
	BSR.w	UpdateSpritePositionAndRender
	MOVE.l	#Boss1_DeathFall, obj_tick_fn(A5)
	PlaySound	SOUND_DOOR_OPEN
	RTS

