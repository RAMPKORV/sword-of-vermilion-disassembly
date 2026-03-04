; ======================================================================
; src/combat.asm
; Combat spells, projectile update routines, item use handlers
; ======================================================================

; ----------------------------------------------------------------------
; HomingProjectile_UpdateFlipFlag / HomingProjectile_AnimateFrame
; / HomingProjectile_ApplyVelocity
;
; Per-frame tick for homing projectiles (Aero, Argentos).
;
; obj_invuln_timer is repurposed as the current angle index (0-7).
; Each frame the flip flag mirrors the direction:
;   direction bits 0-3 of (angle & 7) -> H-flip on obj_sprite_flags bit 3.
;
; Velocity is derived from the sine table:
;   offset = angle * 32
;   vel_x  = speed * sin(offset)       (X component)
;   vel_y  = speed * sin(offset + $40) (Y component, quarter-period)
; Subtracting velocity from world position moves the projectile forward.
; ----------------------------------------------------------------------
HomingProjectile_UpdateFlipFlag:
	BSET.b	#3, obj_sprite_flags(A5)
	MOVE.b	obj_invuln_timer(A5), D0
	ANDI.w	#7, D0
	CMPI.b	#4, D0
	BLE.b	HomingProjectile_AnimateFrame
	BCLR.b	#3, obj_sprite_flags(A5)
HomingProjectile_AnimateFrame:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	MOVE.b	D0, D1
	SUBQ.b	#1, D1
	EOR.b	D1, D0          ; D0 has a bit set at each power-of-2 boundary
	BTST.l	#1, D0          ; Advance angle every 2 frames (bit 1 crossing)
	BEQ.b	HomingProjectile_ApplyVelocity
	ADDQ.b	#1, obj_invuln_timer(A5) ; Advance angle index
	ANDI.b	#7, obj_invuln_timer(A5) ; Wrap 0-7
HomingProjectile_ApplyVelocity:
	MOVE.b	obj_invuln_timer(A5), D0
	ANDI.w	#7, D0
	ADD.w	D0, D0          ; D0 = angle * 2 (word offset into sprite frame table)
	LEA	AeroSpriteFrameTable, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	LEA	SineTable, A0
	MOVE.l	obj_pos_x_fixed(A5), D0 ; Speed (fixed-point, upper word used)
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	ASL.w	#5, D1          ; D1 = angle * 32 (byte offset into sine table)
	MOVE.b	(A0,D1.w), D2   ; sin(angle)  -> X component
	MOVE.b	$40(A0,D1.w), D3 ; cos(angle) -> Y component (quarter-period offset)
	EXT.w	D2
	EXT.w	D3
	MULS.w	D0, D2          ; vel_x = speed * sin
	MULS.w	D0, D3          ; vel_y = speed * cos
	MOVE.l	D2, obj_vel_x(A5)
	MOVE.l	D3, obj_vel_y(A5)
	MOVE.l	obj_vel_x(A5), D0
	SUB.l	D0, obj_world_x(A5) ; Subtract = move forward in direction
	MOVE.l	obj_vel_y(A5), D0
	SUB.l	D0, obj_world_y(A5)
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A5), D1
	BSR.w	CheckCoordsInBounds
	BEQ.b	MarkProjectileFinished
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	obj_world_y(A5), obj_sort_key(A5)
	JSR	AddSpriteToDisplayList
	RTS
	
MarkProjectileFinished:
	MOVE.b	#FLAG_TRUE, obj_npc_busy_flag(A5) ; Signal projectile is done (deactivates it)
	RTS

; ----------------------------------------------------------------------
; CastVolti
;
; Fires a single fast bolt projectile from the player in the direction
; they are facing.  Uses object slot 02.  Speed = $400.
; Tick function: UpdateVoltiProjectile
; ----------------------------------------------------------------------
CastVolti:
	MOVEA.l	Object_slot_02_ptr.w, A6
	BTST.b	#7, (A6)
	BNE.w	CastVolti_Done
	BSR.w	CheckCursedAndConsumeReadiedMagicMp
	BNE.w	CastVolti_Done
	MOVE.w	#SOUND_TREASURE, D0
	JSR	QueueSoundEffect
	BSET.b	#7, (A6)
	BCLR.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_4x2, obj_sprite_size(A6)
	MOVE.w	#8, obj_hitbox_half_w(A6)
	MOVE.w	#$000C, obj_hitbox_half_h(A6)
	CLR.b	obj_move_counter(A6)
	CLR.b	obj_npc_busy_flag(A6)
	MOVE.w	#VRAM_TILE_PLAYER_SLASH, obj_tile_index(A6)
	BSR.w	InitMagicDamageAndFlags
	LEA	SineTable, A0
	MOVE.l	#$400, D0           ; Projectile speed
	MOVE.w	Player_direction.w, D1
	ASL.w	#5, D1              ; D1 = direction * 32 (sine table byte offset)
	MOVE.b	(A0,D1.w), D2       ; sin(angle) -> X component
	MOVE.b	$40(A0,D1.w), D3    ; cos(angle) -> Y component
	EXT.w	D2
	EXT.w	D3
	MULS.w	D0, D2              ; vel_x = speed * sin
	MULS.w	D0, D3              ; vel_y = speed * cos
	MOVE.l	D2, obj_vel_x(A6)
	MOVE.l	D3, obj_vel_y(A6)
	MOVE.w	obj_world_x(A5), obj_world_x(A6) ; Spawn at player's position
	MOVE.w	obj_world_y(A5), obj_world_y(A6)
	MOVE.l	#UpdateVoltiProjectile, obj_tick_fn(A6)
CastVolti_Done:
	RTS

UpdateVoltiProjectile:
	BSR.w	CheckProjectileHitEnemies
	TST.b	obj_npc_busy_flag(A5)
	BNE.w	DeactivateVoltiProjectile
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	LEA	VoltiSpriteFrameTable, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.l	obj_vel_x(A5), D0
	SUB.l	D0, obj_world_x(A5)
	MOVE.l	obj_vel_y(A5), D0
	SUB.l	D0, obj_world_y(A5)
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A5), D1
	BSR.w	CheckCoordsInBounds
	BEQ.b	DeactivateVoltiProjectile
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	obj_world_y(A5), obj_sort_key(A5)
	JSR	AddSpriteToDisplayList
	RTS

DeactivateVoltiProjectile:
	BCLR.b	#7, (A5)
	RTS

; ----------------------------------------------------------------------
; CastVoltio
;
; Fires 7 orbiting projectiles (1 lead + 2 followers + 4 ground) from
; VoltioProjectileOffsetData.  The lead uses UpdateVoltioLeadOrbitProjectile
; (orbits and fades after obj_attack_timer hits 0); followers use
; UpdateProjectileFollowPlayer (clones that track the lead tile and player
; position); ground projectiles use UpdateVoltioGroundProjectile (on-floor
; damage zones offset from the player).
; D6 = tile index: orbit slots $0245, ground slots $025D.
; ----------------------------------------------------------------------
CastVoltio:
	MOVEA.l	Object_slot_02_ptr.w, A6
	BTST.b	#7, (A6)
	BNE.w	CastVoltio_Done
	BSR.w	CheckCursedAndConsumeReadiedMagicMp
	BNE.w	CastVoltio_Done
	MOVE.w	#SOUND_TREASURE, D0
	JSR	QueueSoundEffect
	MOVE.w	#$0245, D6
	LEA	VoltioProjectileOffsetData, A0
	MOVE.l	#UpdateVoltioLeadOrbitProjectile, obj_tick_fn(A6)
	BSR.w	InitMagicProjectile
	MOVE.w	#2, D7
VoltioInitFollowerLoop:
	MOVE.l	#UpdateProjectileFollowPlayer, obj_tick_fn(A6)
	BSR.w	InitMagicProjectile
	DBF	D7, VoltioInitFollowerLoop
	MOVE.w	#$025D, D6
	MOVE.w	#3, D7
VoltioInitGroundLoop:
	MOVE.l	#UpdateVoltioGroundProjectile, obj_tick_fn(A6)
	BSR.w	InitMagicProjectile
	DBF	D7, VoltioInitGroundLoop
CastVoltio_Done:
	RTS

; ----------------------------------------------------------------------
; InitMagicProjectile
;
; Shared initialiser for Voltio orbit/ground projectile slots.
; Reads 4 words from (A0)+ per slot: offset_x, offset_y, knockback_timer,
; flip_flags (bit 0 = H-flip, bit 1 = V-flip).  Sets obj_attack_timer to
; $0096 (150 frames) and advances A6 to the next object slot via
; obj_next_offset.  Called in a loop from CastVoltio.
; ----------------------------------------------------------------------
InitMagicProjectile:
	BSET.b	#7, (A6)
	BCLR.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_2x4, obj_sprite_size(A6)
	MOVE.w	D6, obj_tile_index(A6)
	BSR.w	InitMagicDamageAndFlags
	MOVE.w	#$0096, obj_attack_timer(A6)
	CLR.b	obj_move_counter(A6)
	MOVE.w	#$0010, obj_hitbox_half_w(A6)
	MOVE.w	#$0010, obj_hitbox_half_h(A6)
	MOVE.w	(A0)+, obj_proj_offset_x(A6)
	MOVE.w	(A0)+, obj_proj_offset_y(A6)
	MOVE.w	(A0)+, obj_knockback_timer(A6)
	MOVE.w	(A0)+, D0
	BTST.l	#0, D0
	BEQ.b	InitMagicProjectile_SkipHFlip
	BSET.b	#3, obj_sprite_flags(A6)
InitMagicProjectile_SkipHFlip:
	BTST.l	#1, D0
	BEQ.b	InitMagicProjectile_CheckVFlip
	BSET.b	#4, obj_sprite_flags(A6)
InitMagicProjectile_CheckVFlip:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	RTS

UpdateVoltioLeadOrbitProjectile:
	SUBQ.w	#1, obj_attack_timer(A5)
	BLE.b	VoltioOrbitExpired
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#6, D0
	LEA	VoltioOrbitSpriteFrameTable, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	BSR.w	UpdateProjectileFollowPlayer
	RTS

VoltioOrbitExpired:
	BSR.w	ClearEnemyActiveFlags_Alt
	RTS

UpdateProjectileFollowPlayer:
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.w	obj_tile_index(A6), obj_tile_index(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), D0
	ADD.w	obj_proj_offset_x(A5), D0
	MOVE.w	D0, obj_world_x(A5)
	MOVE.w	obj_world_y(A6), D0
	ADD.w	obj_proj_offset_y(A5), D0
	MOVE.w	D0, obj_world_y(A5)
	MOVE.w	obj_sort_key(A6), D0
	ADD.w	obj_knockback_timer(A5), D0
	MOVE.w	D0, obj_sort_key(A5)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS

UpdateVoltioGroundProjectile:
	BSR.w	CheckProjectileHitEnemies
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), D0
	ADD.w	obj_proj_offset_x(A5), D0
	MOVE.w	D0, obj_world_x(A5)
	MOVE.w	obj_world_y(A6), D0
	ADD.w	obj_proj_offset_y(A5), D0
	MOVE.w	D0, obj_world_y(A5)
	MOVE.w	#1, obj_sort_key(A5)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS

VoltioProjectileOffsetData:
	dc.w	-16 
	dc.w	-16 
	dc.w	-1 
	dc.w	0 
	dc.w	16 
	dc.w	-16 
	dc.w	-1 
	dc.w	1 
	dc.w	-16 
	dc.w	0 
	dc.w	1 
	dc.w	2 
	dc.w	16 
	dc.w	0 
	dc.w	1 
	dc.w	3
	dc.w	-16 
	dc.w	-4 
	dc.w	-1 
	dc.w	0 
	dc.w	16 
	dc.w	-4 
	dc.w	-1 
	dc.w	1 
	dc.w	-16 
	dc.w	12 
	dc.w	1 
	dc.w	2 
	dc.w	16 
	dc.w	12 
	dc.w	1 
	dc.w	3 

; ----------------------------------------------------------------------
; CastVoltios
;
; Casts the Voltios lightning-bolt rain spell.  Activates slot 02,
; spawns it above the player (Y - $20), then cycles through four phases:
;   UpdateVoltiosDescendPhase       - bolts appear from top, one per tick
;   UpdateVoltiosClearDescendPhase  - deactivate descending bolts
;   UpdateVoltiosAscendPhase        - bolts rise from ground, one per tick
;   UpdateVoltiosClearAscendPhase   - deactivate ascending bolts
; After all phases VoltiosSpawnExplosion creates a damage explosion.
; ----------------------------------------------------------------------
CastVoltios:
	MOVEA.l	Object_slot_02_ptr.w, A6
	BTST.b	#7, (A6)
	BNE.b	CastVoltios_Done
	BSR.w	CheckCursedAndConsumeReadiedMagicMp
	BNE.b	CastVoltios_Done
	MOVE.w	#SOUND_VOLTIOS_CAST, D0
	JSR	QueueSoundEffect
	BSET.b	#7, (A6)
	CLR.w	obj_attack_timer(A6)
	BSR.w	InitMagicDamageAndFlags
	MOVEA.l	Player_entity_ptr.w, A4
	MOVE.w	obj_world_x(A4), obj_world_x(A6)
	MOVE.w	obj_world_y(A4), D0
	MOVE.w	obj_sort_key(A4), obj_sort_key(A6)
	SUBI.w	#$0020, D0
	MOVE.w	D0, obj_world_y(A6)
	MOVE.w	#$000C, obj_hitbox_half_w(A6)
	MOVE.w	#$0010, obj_hitbox_half_h(A6)
	MOVE.l	#UpdateVoltiosDescendPhase, obj_tick_fn(A6)
CastVoltios_Done:
	RTS

UpdateVoltiosDescendPhase:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.w	obj_attack_timer(A5), D7
	MOVE.w	D7, D6
	BEQ.b	VoltiosDescend_SpawnBolt
	SUBQ.w	#1, D7
VoltiosDescend_SkipToSlotLoop:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, VoltiosDescend_SkipToSlotLoop
VoltiosDescend_SpawnBolt:
	MOVE.w	D6, D5
	MOVE.w	obj_world_y(A5), D0
	ASL.w	#4, D5
	SUB.w	D5, D0
	BLE.w	VoltiosDescend_Complete
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BCLR.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_2x3, obj_sprite_size(A6)
	MOVE.w	#$000C, obj_hitbox_half_w(A6)
	MOVE.w	#$0010, obj_hitbox_half_h(A6)
	MOVE.w	obj_world_x(A5), obj_world_x(A6)
	MOVE.w	D0, obj_world_y(A6)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
	MOVEQ	#0, D5
	MOVE.w	D6, D5
	DIVU.w	#3, D5
	SWAP	D5
	ADD.w	D5, D5
	LEA	VoltiosDescendFrameTable, A0
	MOVE.w	(A0,D5.w), obj_tile_index(A6)
	MOVE.l	#DrawSpriteAtCurrentPosition, obj_tick_fn(A6)
	ADDQ.w	#1, obj_attack_timer(A5)
	BSR.w	InitMagicDamageAndFlags
	RTS

VoltiosDescend_Complete:
	CLR.w	obj_knockback_timer(A5)
	MOVE.l	#UpdateVoltiosClearDescendPhase, obj_tick_fn(A5)
	RTS

UpdateVoltiosClearDescendPhase:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.w	obj_knockback_timer(A5), D7
	MOVE.w	D7, D6
	BEQ.b	VoltiosClearDescend_DeactivateSlot
	SUBQ.w	#1, D7
VoltiosClearDescend_SkipToSlotLoop:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, VoltiosClearDescend_SkipToSlotLoop
VoltiosClearDescend_DeactivateSlot:
	BCLR.b	#7, (A6)
	ADDQ.w	#1, obj_knockback_timer(A5)
	CMP.w	obj_attack_timer(A5), D6
	BGE.b	VoltiosClearDescend_TransitionToAscend
	RTS

VoltiosClearDescend_TransitionToAscend:
	BSR.w	FindActiveEnemyPosition
	MOVE.l	#UpdateVoltiosAscendPhase, obj_tick_fn(A5)
	CLR.w	obj_attack_timer(A5)
	RTS

UpdateVoltiosAscendPhase:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.w	obj_attack_timer(A5), D7
	MOVE.w	D7, D6
	BEQ.b	VoltiosAscend_SpawnBolt
	SUBQ.w	#1, D7
VoltiosAscend_SkipToSlotLoop:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, VoltiosAscend_SkipToSlotLoop
VoltiosAscend_SpawnBolt:
	MOVE.w	D6, D5
	MOVE.w	obj_world_y(A5), D0
	ASL.w	#4, D5
	CMP.w	D0, D5
	BGE.w	VoltiosAscend_Complete
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BCLR.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_2x3, obj_sprite_size(A6)
	MOVE.w	obj_world_x(A5), obj_world_x(A6)
	MOVE.w	D5, obj_world_y(A6)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
	MOVEQ	#0, D5
	MOVE.w	D6, D5
	DIVU.w	#3, D5
	SWAP	D5
	ADD.w	D5, D5
	LEA	VoltiosAscendFrameTable, A0
	MOVE.w	(A0,D5.w), obj_tile_index(A6)
	MOVE.l	#DrawSpriteAtCurrentPosition, obj_tick_fn(A6)
	ADDQ.w	#1, obj_attack_timer(A5)
	RTS

VoltiosAscend_Complete:
	CLR.w	obj_knockback_timer(A5)
	MOVE.l	#UpdateVoltiosClearAscendPhase, obj_tick_fn(A5)
	RTS

UpdateVoltiosClearAscendPhase:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.w	obj_knockback_timer(A5), D7
	MOVE.w	D7, D6
	BEQ.b	VoltiosClearAscend_UpdateSprite
	SUBQ.w	#1, D7
VoltiosClearAscend_SkipToSlotLoop:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, VoltiosClearAscend_SkipToSlotLoop
VoltiosClearAscend_UpdateSprite:
	MOVE.w	obj_knockback_timer(A5), D0
	CMP.w	obj_attack_timer(A5), D0
	BGE.b	VoltiosClearAscend_TransitionToDeactivate
	MOVEQ	#0, D5
	MOVE.w	D6, D5
	DIVU.w	#3, D5
	SWAP	D5
	ADD.w	D5, D5
	LEA	VoltiosClearFrameTable, A0
	MOVE.w	(A0,D5.w), obj_tile_index(A6)
	ADDQ.w	#1, obj_knockback_timer(A5)
	RTS

VoltiosClearAscend_TransitionToDeactivate:
	CLR.w	obj_knockback_timer(A5)
	MOVE.l	#UpdateVoltiosDeactivateAscendPhase, obj_tick_fn(A5)
	RTS

UpdateVoltiosDeactivateAscendPhase:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.w	obj_knockback_timer(A5), D7
	MOVE.w	D7, D6
	BEQ.b	VoltiosDeactivateAscend_ClearSlot
	SUBQ.w	#1, D7
VoltiosDeactivateAscend_SkipToSlotLoop:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, VoltiosDeactivateAscend_SkipToSlotLoop
VoltiosDeactivateAscend_ClearSlot:
	BCLR.b	#7, (A6)
	ADDQ.w	#1, obj_knockback_timer(A5)
	CMP.w	obj_attack_timer(A5), D6
	BGE.b	VoltiosSpawnExplosion
	RTS

VoltiosSpawnExplosion:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BCLR.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_2x3, obj_sprite_size(A6)
	MOVE.w	#VRAM_TILE_VOLTIOS_EXPLOSION, obj_tile_index(A6)
	MOVE.w	obj_world_x(A5), obj_world_x(A6)
	MOVE.w	obj_world_y(A5), obj_world_y(A6)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
	MOVE.l	#DrawSpriteAtCurrentPosition, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BCLR.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_2x3, obj_sprite_size(A6)
	MOVE.w	#VRAM_TILE_HYDRO_ICICLE, obj_tile_index(A6)
	MOVE.w	obj_world_x(A5), obj_world_x(A6)
	MOVE.w	obj_world_y(A5), D0
	SUBI.w	#$0010, D0
	MOVE.w	D0, obj_world_y(A6)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
	MOVE.l	#DrawSpriteAtCurrentPosition, obj_tick_fn(A6)
	CLR.w	obj_knockback_timer(A5)
	MOVE.l	#UpdateVoltiosExplosion, obj_tick_fn(A5)
	RTS

UpdateVoltiosExplosion:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A4
	ADDQ.w	#1, obj_knockback_timer(A5)
	MOVE.w	obj_knockback_timer(A5), D0
	ANDI.w	#$001C, D0
	CMPI.w	#$0010, D0
	BGE.b	VoltiosExplosion_Finished
	LEA	VoltiosExplosionFrameTable, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A6)
	MOVE.w	$2(A0,D0.w), obj_tile_index(A4)
	BSR.w	CheckProjectileHitEnemies
	RTS

VoltiosExplosion_Finished:
	BSR.w	ClearEnemyActiveFlags_Alt
	RTS

; ----------------------------------------------------------------------
; FindActiveEnemyPosition
;
; Scans the enemy list for the first slot that is active (bit 7 set),
; flagged alive (bit 6 set), and has HP > 0.  Writes the enemy pointer,
; world_x, world_y, and sort_key into A5 fields.  If no live enemy is
; found, writes a default screen-centre position ($00A0, $0070) and clears
; the stored pointer.  Iterates 8 slots, advancing 3 links per step.
; ----------------------------------------------------------------------
FindActiveEnemyPosition:
	MOVEA.l	Enemy_list_ptr.w, A4
	MOVE.w	#7, D6
FindActiveEnemy_CheckLoop:
	BTST.b	#7, (A4)
	BEQ.b	FindActiveEnemy_NextSlot
	BTST.b	#6, (A4)
	BEQ.b	FindActiveEnemy_NextSlot
	TST.w	obj_hp(A4)
	BLE.b	FindActiveEnemy_NextSlot
	MOVE.l	A4, obj_hp(A5)
	MOVE.w	obj_world_x(A4), obj_world_x(A5)
	MOVE.w	obj_world_y(A4), obj_world_y(A5)
	MOVE.w	obj_sort_key(A4), obj_sort_key(A5)
	BRA.b	FindActiveEnemy_Done
FindActiveEnemy_NextSlot:
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A4
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A4
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A4
	DBF	D6, FindActiveEnemy_CheckLoop
	MOVE.w	#$00A0, obj_world_x(A5)	
	MOVE.w	#$0070, obj_world_y(A5)	
	MOVE.w	obj_world_y(A5), obj_sort_key(A5)	
	MOVE.l	#0, obj_hp(A5)	
FindActiveEnemy_Done:
	RTS

; ----------------------------------------------------------------------
; DrawSpriteAtCurrentPosition
;
; Copies obj_world_x/obj_world_y to obj_screen_x/obj_screen_y and calls
; AddSpriteToDisplayList.  Convenience wrapper used by several projectile
; tick functions.
; ----------------------------------------------------------------------
DrawSpriteAtCurrentPosition:
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS

; ----------------------------------------------------------------------
; CastFerros
;
; Fires a spinning iron-ball projectile that orbits the player.
; Uses slot 02 with tick function UpdateFerrosOrbit.  The projectile
; orbits using an angle index stored in obj_invuln_timer (0-7); each
; frame the angle is advanced and the position is set by rotating
; obj_proj_offset_x/Y around the player via the sine table.
; On timeout (obj_attack_timer == 0) the slot is deactivated.
; ----------------------------------------------------------------------
CastFerros:
	MOVEA.l	Object_slot_02_ptr.w, A6
	BTST.b	#7, (A6)
	BNE.w	CastFerros_Done
	BSR.w	CheckCursedAndConsumeReadiedMagicMp
	BNE.w	CastFerros_Done
	MOVE.w	#SOUND_SAVE, D0
	JSR	QueueSoundEffect
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BCLR.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	MOVE.w	#8, obj_hitbox_half_w(A6)
	MOVE.w	#$000C, obj_hitbox_half_h(A6)
	CLR.b	obj_move_counter(A6)
	CLR.b	obj_npc_busy_flag(A6)
	CLR.l	obj_hp(A6)
	MOVE.w	Player_direction.w, D1
	ANDI.w	#7, D1
	ASL.w	#5, D1
	MOVE.b	D1, obj_direction(A6)
	MOVE.b	#SPRITE_SIZE_4x3, obj_sprite_size(A6)
	MOVE.w	#VRAM_TILE_PLAYER_SLASH, obj_tile_index(A6)
	BSR.w	InitMagicDamageAndFlags
	MOVE.w	#$00F0, obj_attack_timer(A6)
	MOVE.l	#$00080000, obj_pos_x_fixed(A6)
	MOVE.w	obj_world_x(A5), obj_world_x(A6)
	MOVE.w	obj_world_y(A5), obj_world_y(A6)
	MOVE.l	#UpdateFerrosOrbit, obj_tick_fn(A6)
CastFerros_Done:
	RTS

UpdateFerrosOrbit:
	CMPI.l	#FERROS_ORBIT_MAX_RADIUS, obj_pos_x_fixed(A5)
	BGE.b	FerrosOrbit_CheckHitAndLifetime
	ADDI.l	#$00010000, obj_pos_x_fixed(A5)
	BRA.b	FerrosOrbit_UpdatePosition
FerrosOrbit_CheckHitAndLifetime:
	JSR	CheckProjectileHitEnemies(PC)
	TST.b	obj_npc_busy_flag(A5)
	BNE.w	DeactivateFerrosProjectile
	SUBQ.w	#1, obj_attack_timer(A5)
	BLE.w	DeactivateFerrosProjectile
FerrosOrbit_UpdatePosition:
	SUBQ.b	#4, obj_direction(A5)
	LEA	SineTable, A0
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	MOVE.b	(A0,D1.w), D2
	MOVE.b	$40(A0,D1.w), D3
	EXT.w	D2
	EXT.w	D3
	MOVE.w	obj_pos_x_fixed(A5), D0
	MULS.w	D0, D2
	MULS.w	D0, D3
	ASR.l	#7, D2
	ASR.l	#7, D3
	MOVEA.l	Player_entity_ptr.w, A6
	ADD.w	obj_world_x(A6), D2
	ADD.w	obj_world_y(A6), D3
	MOVE.w	D2, obj_world_x(A5)
	MOVE.w	D3, obj_world_y(A5)
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A5), D1
	BSR.w	CheckCoordsInBounds
	BEQ.w	DeactivateFerrosProjectile
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	obj_world_y(A5), obj_sort_key(A5)
	JSR	UpdatePlayerSpriteFrame(PC)
	JSR	AddSpriteToDisplayList
	RTS

DeactivateFerrosProjectile:
	BCLR.b	#7, (A5)
	MOVE.b	#FLAG_TRUE, obj_npc_busy_flag(A5)
	RTS

; ----------------------------------------------------------------------
; CastCopperos
;
; Fires a single spinning projectile that follows the player's facing
; direction.  Uses the same sine-table drive as CastVolti, but at
; speed $400 (quarter the forward speed).  On hitting an enemy the
; projectile's obj_npc_busy_flag goes negative, triggering
; CopperosExplodeIntoFragments: 8 fragment sub-projectiles are spawned
; in a star pattern (directions spaced 32 steps apart), each using
; UpdateProjectileAscendingArc as their tick function.
; Lead slot is then switched to UpdateCopperosFragmentsLead.
; ----------------------------------------------------------------------
CastCopperos:
	MOVEA.l	Object_slot_02_ptr.w, A6
	BTST.b	#7, (A6)
	BNE.w	CastCopperos_Done
	BSR.w	CheckCursedAndConsumeReadiedMagicMp
	BNE.w	CastCopperos_Done
	MOVE.w	#SOUND_SAVE, D0
	JSR	QueueSoundEffect
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BCLR.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	MOVE.w	#6, obj_hitbox_half_w(A6)
	MOVE.w	#8, obj_hitbox_half_h(A6)
	CLR.b	obj_invuln_timer(A6)
	CLR.b	obj_move_counter(A6)
	CLR.b	obj_npc_busy_flag(A6)
	CLR.l	obj_hp(A6)
	CLR.w	obj_attack_timer(A6)
	MOVE.w	Player_direction.w, D1
	ANDI.w	#7, D1
	MOVE.b	D1, obj_direction(A6)
	MOVE.b	#SPRITE_SIZE_4x3, obj_sprite_size(A6)
	MOVE.w	#VRAM_TILE_PLAYER_SLASH, obj_tile_index(A6)
	BSR.w	InitMagicDamageAndFlags
	MOVE.l	#$400, obj_pos_x_fixed(A6)
	MOVE.w	obj_world_x(A5), obj_world_x(A6)
	MOVE.w	obj_world_y(A5), obj_world_y(A6)
	MOVE.l	#UpdateCopperosProjectile, obj_tick_fn(A6)
CastCopperos_Done:
	RTS

UpdateCopperosProjectile:
	JSR	CheckProjectileHitEnemies(PC)
	TST.b	obj_npc_busy_flag(A5)
	BMI.w	CopperosExplodeIntoFragments
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
	MOVE.l	obj_vel_x(A5), D0
	SUB.l	D0, obj_world_x(A5)
	MOVE.l	obj_vel_y(A5), D0
	SUB.l	D0, obj_world_y(A5)
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A5), D1
	BSR.w	CheckCoordsInBounds
	BEQ.w	DeactivateCopperosProjectile
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	obj_world_y(A5), obj_sort_key(A5)
	BSET.b	#3, obj_sprite_flags(A5)
	CMPI.b	#4, obj_direction(A5)
	BLE.b	CopperosProjectile_AnimateSprite
	BCLR.b	#3, obj_sprite_flags(A5)
CopperosProjectile_AnimateSprite:
	LEA	MetalSpellSpriteFrameTable, A0
	MOVEQ	#0, D1
	MOVE.b	obj_direction(A5), D1
	ASL.w	#3, D1
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	ADD.w	D1, D0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList
	RTS

DeactivateCopperosProjectile:
	BCLR.b	#7, (A5)
	RTS

CopperosExplodeIntoFragments:
	LEA	(A5), A6
	MOVE.w	#7, D7
CopperosInitFragmentLoop:
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BCLR.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	MOVE.w	#1, obj_hitbox_half_w(A6)
	MOVE.w	#1, obj_hitbox_half_h(A6)
	CLR.b	obj_invuln_timer(A6)
	CLR.b	obj_move_counter(A6)
	CLR.b	obj_npc_busy_flag(A6)
	MOVE.b	#SPRITE_SIZE_4x3, obj_sprite_size(A6)
	MOVE.w	#VRAM_TILE_PLAYER_SLASH, obj_tile_index(A6)
	MOVE.w	D7, D2
	ASL.w	#5, D2
	MOVE.b	D2, obj_direction(A6)
	BSR.w	InitMagicDamageAndFlags
	CLR.l	obj_pos_x_fixed(A6)
	MOVE.l	#$00180000, obj_pos_x_fixed(A6)
	MOVE.w	#$003C, obj_attack_timer(A6)
	MOVE.w	obj_world_x(A5), obj_world_x(A6)
	MOVE.w	obj_world_y(A5), obj_world_y(A6)
	MOVE.w	obj_world_x(A5), obj_hp(A6)
	MOVE.w	obj_world_y(A5), obj_xp_reward(A6)
	MOVE.l	#UpdateProjectileAscendingArc, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, CopperosInitFragmentLoop
	MOVE.l	#UpdateCopperosFragmentsLead, obj_tick_fn(A5)
UpdateCopperosFragmentsLead:
	JSR	UpdateProjectileAscendingArc(PC)
	JSR	CheckMagicSlotActiveOrClearAll(PC)
	RTS

; ----------------------------------------------------------------------
; UpdateProjectileAscendingArc
;
; Shared tick for Copperos fragment projectiles.
; obj_pos_x_fixed is the current speed (starts at $00180000).
; obj_attack_timer counts down; while > 0 the projectile moves at
; constant speed.  Once the timer reaches 0 the projectile enters
; "decay phase": each frame direction advances by 4 and speed decreases
; by $8000 until the speed reaches 0.  The spawn position is stored in
; obj_hp (world_x) and obj_xp_reward (world_y); movement is applied
; relative to that origin each tick.
; ----------------------------------------------------------------------
UpdateProjectileAscendingArc:
	JSR	CheckProjectileHitEnemies(PC)
	CLR.b	obj_npc_busy_flag(A5)
	TST.w	obj_attack_timer(A5)
	BLE.b	AscendingArc_DecayPhase
	SUBQ.w	#1, obj_attack_timer(A5)
	BRA.b	AscendingArc_UpdatePosition
AscendingArc_DecayPhase:
	ADDQ.b	#4, obj_direction(A5)
	SUBI.l	#$8000, obj_pos_x_fixed(A5)
	BLE.w	DeactivateAscendingArcProjectile
AscendingArc_UpdatePosition:
	LEA	SineTable, A0
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	MOVE.b	(A0,D1.w), D2
	MOVE.b	$40(A0,D1.w), D3
	EXT.w	D2
	EXT.w	D3
	MOVE.w	obj_pos_x_fixed(A5), D0
	MULS.w	D0, D2
	MULS.w	D0, D3
	ASR.l	#7, D2
	ASR.l	#7, D3
	ADD.w	obj_hp(A5), D2
	ADD.w	obj_xp_reward(A5), D3
	MOVE.w	D2, obj_world_x(A5)
	MOVE.w	D3, obj_world_y(A5)
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A5), D1
	BSR.w	CheckCoordsInBounds
	BEQ.w	DeactivateAscendingArcProjectile
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	obj_world_y(A5), obj_sort_key(A5)
	LEA	MetalSpellSpriteFrameTable, A0
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	ADDI.w	#$0020, D0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList
	RTS

DeactivateAscendingArcProjectile:
	MOVE.b	#FLAG_TRUE, obj_npc_busy_flag(A5)
	RTS

; ----------------------------------------------------------------------
; CastMercusios
;
; Fires 8 descending-arc projectiles simultaneously, each at a
; different direction (D7 * 32, covering all 8 compass octants).
; Each projectile starts at speed $80000 and accelerates downward via
; UpdateProjectileDescendingArc.  The lead slot (slot 02) is promoted
; to UpdateMercusiosLeadProjectile which also calls
; CheckMagicSlotActiveOrClearAll each tick.
; ----------------------------------------------------------------------
CastMercusios:
	MOVEA.l	Object_slot_02_ptr.w, A6
	BTST.b	#7, (A6)
	BNE.w	CastMercusios_Done
	BSR.w	CheckCursedAndConsumeReadiedMagicMp
	BNE.w	CastMercusios_Done
	MOVE.w	#SOUND_MERCUSIOS, D0
	JSR	QueueSoundEffect
	MOVE.w	#7, D7
MercusiosInitProjectileLoop:
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BCLR.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	MOVE.w	#8, obj_hitbox_half_w(A6)
	MOVE.w	#$000C, obj_hitbox_half_h(A6)
	CLR.b	obj_invuln_timer(A6)
	CLR.b	obj_move_counter(A6)
	CLR.b	obj_npc_busy_flag(A6)
	CLR.l	obj_hp(A6)
	CLR.w	obj_attack_timer(A6)
	MOVE.w	D7, D1
	ASL.w	#5, D1
	MOVE.b	D1, obj_direction(A6)
	MOVE.b	#SPRITE_SIZE_4x3, obj_sprite_size(A6)
	MOVE.w	#VRAM_TILE_PLAYER_SLASH, obj_tile_index(A6)
	BSR.w	InitMagicDamageAndFlags
	CLR.w	obj_attack_timer(A6)
	MOVE.l	#$80000, obj_pos_x_fixed(A6)
	MOVE.w	obj_world_x(A5), obj_world_x(A6)
	MOVE.w	obj_world_y(A5), obj_world_y(A6)
	MOVE.w	obj_world_x(A5), obj_hp(A6)
	MOVE.w	obj_world_y(A5), obj_xp_reward(A6)
	MOVE.l	#UpdateProjectileDescendingArc, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	ADDQ.w	#1, D1
	DBF	D7, MercusiosInitProjectileLoop
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.l	#UpdateMercusiosLeadProjectile, obj_tick_fn(A6)
CastMercusios_Done:
	RTS

UpdateMercusiosLeadProjectile:
	JSR	UpdateProjectileDescendingArc(PC)
	JSR	CheckMagicSlotActiveOrClearAll(PC)
	RTS

; ----------------------------------------------------------------------
; UpdateProjectileDescendingArc
;
; Shared tick for Mercusios arc projectiles.
; obj_attack_timer ramps up until DESCENDING_ARC_GRAVITY_ONSET, then
; holds.  Each frame the current timer value is divided by 4 (+1) and
; subtracted from obj_direction, creating a curving downward arc.
; Speed (obj_pos_x_fixed) increases by $8000 each tick.
; Spawn position is stored in obj_hp (world_x) / obj_xp_reward
; (world_y).  On hitting an enemy or leaving bounds, obj_npc_busy_flag
; is set to FLAG_TRUE.
; ----------------------------------------------------------------------
UpdateProjectileDescendingArc:
	TST.b	obj_npc_busy_flag(A5)
	BNE.w	DeactivateDescendingArcProjectile
	JSR	CheckProjectileHitEnemies(PC)
	CMPI.w	#DESCENDING_ARC_GRAVITY_ONSET, obj_attack_timer(A5)
	BGE.b	DescendingArc_UpdateMovement
	ADDQ.w	#1, obj_attack_timer(A5)
DescendingArc_UpdateMovement:
	ADDI.l	#$8000, obj_pos_x_fixed(A5)
	MOVE.w	obj_attack_timer(A5), D0
	ASR.w	#2, D0
	ADDQ.w	#1, D0
	SUB.b	D0, obj_direction(A5)
	LEA	SineTable, A0
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	MOVE.b	(A0,D1.w), D2
	MOVE.b	$40(A0,D1.w), D3
	EXT.w	D2
	EXT.w	D3
	MOVE.w	obj_pos_x_fixed(A5), D0
	MULS.w	D0, D2
	MULS.w	D0, D3
	ASR.l	#7, D2
	ASR.l	#7, D3
	ADD.w	obj_hp(A5), D2
	ADD.w	obj_xp_reward(A5), D3
	MOVE.w	D2, obj_world_x(A5)
	MOVE.w	D3, obj_world_y(A5)
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A5), D1
	BSR.w	CheckCoordsInBounds
	BEQ.w	DeactivateDescendingArcProjectile
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	obj_world_y(A5), obj_sort_key(A5)
	JSR	UpdatePlayerSpriteFrame(PC)
	JSR	AddSpriteToDisplayList
	RTS
	
DeactivateDescendingArcProjectile:
	MOVE.b	#FLAG_TRUE, obj_npc_busy_flag(A5)
	RTS

; ----------------------------------------------------------------------
; CastArgentos
;
; Fires a single homing projectile that steers toward the nearest enemy.
; obj_knockback_timer ($00F0) is the lifetime counter.
; obj_hp holds a pointer to the target enemy (set via FindNthEnemyInList).
; Every 8 frames (XOR-with-previous trick on bit 3 of obj_attack_timer)
; the target is re-evaluated: if the stored enemy is still active it is
; re-used; otherwise a new search runs.  Leaves a trail of 8-slot-
; delayed ghost clones (UpdateArgentosTrailClone) using obj_invuln_timer
; as a ring-buffer index.
; Sprite frames come from ArgentosSpriteFrameTable.
; ----------------------------------------------------------------------
CastArgentos:
	MOVEA.l	Object_slot_02_ptr.w, A6
	BTST.b	#7, (A6)
	BNE.w	CastArgentos_Done
	BSR.w	CheckCursedAndConsumeReadiedMagicMp
	BNE.w	CastArgentos_Done
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BCLR.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	MOVE.w	#8, obj_hitbox_half_w(A6)
	MOVE.w	#$000C, obj_hitbox_half_h(A6)
	CLR.b	obj_invuln_timer(A6)
	CLR.b	obj_move_counter(A6)
	CLR.b	obj_npc_busy_flag(A6)
	CLR.l	obj_hp(A6)
	CLR.w	obj_attack_timer(A6)
	MOVE.w	#$00F0, obj_knockback_timer(A6)
	MOVE.w	Player_direction.w, D1
	ANDI.w	#7, D1
	MOVE.b	D1, obj_direction(A6)
	MOVE.b	#SPRITE_SIZE_4x3, obj_sprite_size(A6)
	MOVE.w	#VRAM_TILE_PLAYER_SLASH, obj_tile_index(A6)
	BSR.w	InitMagicDamageAndFlags
	MOVE.l	#$400, obj_pos_x_fixed(A6)
	MOVE.w	#7, D1
	JSR	FindNthEnemyInList(PC)
	MOVE.w	obj_world_x(A5), obj_world_x(A6)
	MOVE.w	obj_world_y(A5), obj_world_y(A6)
	MOVE.l	#UpdateArgentosProjectile, obj_tick_fn(A6)
	MOVE.w	#SOUND_MERCUSIOS, D0
	JSR	QueueSoundEffect
CastArgentos_Done:
	RTS

UpdateArgentosProjectile:
	TST.b	obj_npc_busy_flag(A5)
	BNE.w	CheckMagicSlotActiveOrClearAll
	JSR	CheckProjectileHitEnemies(PC)
	CLR.b	obj_npc_busy_flag(A5)
	SUBQ.w	#1, obj_knockback_timer(A5)
	BLE.w	DeactivateArgentosProjectile
	ADDQ.b	#1, obj_attack_timer(A5)
	MOVE.b	obj_attack_timer(A5), D0
	MOVE.b	D0, D1
	SUBQ.b	#1, D1
	EOR.b	D1, D0
	BTST.l	#3, D0
	BEQ.w	ArgentosProjectile_ApplyMovement
	TST.l	obj_hp(A5)
	BEQ.b	ArgentosProjectile_ApplyMovement
	MOVEA.l	obj_hp(A5), A6
	BTST.b	#7, (A6)
	BNE.b	ArgentosProjectile_SteerToTarget
	LEA	(A5), A6
	MOVE.w	#7, D1
	JSR	FindNthEnemyInList(PC)
	BRA.b	ArgentosProjectile_ApplyMovement
ArgentosProjectile_SteerToTarget:
	JSR	UpdateHomingProjectileDirection(PC)
ArgentosProjectile_ApplyMovement:
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
	MOVE.l	obj_vel_x(A5), D0
	SUB.l	D0, obj_world_x(A5)
	MOVE.l	obj_vel_y(A5), D0
	SUB.l	D0, obj_world_y(A5)
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A5), D1
	BSR.w	CheckCoordsInBounds
	BEQ.w	DeactivateArgentosProjectile
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	obj_world_y(A5), obj_sort_key(A5)
	LEA	ArgentosSpriteFrameTable, A0
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList
	ADDQ.b	#1, obj_sub_timer(A5)
	CMPI.b	#6, obj_sub_timer(A5)
	BLE.w	ArgentosProjectile_NoTrailThisTick
	CLR.b	obj_sub_timer(A5)
	MOVE.b	obj_invuln_timer(A5), D7
	ADDQ.b	#1, obj_invuln_timer(A5)
	ANDI.w	#7, D7
	LEA	(A5), A6
	CLR.w	D0
ArgentosTrail_AdvanceToSlotLoop:
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, ArgentosTrail_AdvanceToSlotLoop
	BSET.b	#7, (A6)
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6)
	MOVE.w	obj_hitbox_half_w(A5), obj_hitbox_half_w(A6)
	MOVE.w	obj_hitbox_half_h(A5), obj_hitbox_half_h(A6)
	MOVE.b	obj_sprite_size(A5), obj_sprite_size(A6)
	MOVE.w	obj_tile_index(A5), obj_tile_index(A6)
	MOVE.w	obj_max_hp(A5), obj_max_hp(A6)
	MOVE.w	obj_world_x(A5), obj_world_x(A6)
	MOVE.w	obj_world_y(A5), obj_world_y(A6)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
	MOVE.w	obj_screen_x(A5), obj_screen_x(A6)
	MOVE.w	obj_screen_y(A5), obj_screen_y(A6)
	CLR.b	obj_invuln_timer(A6)
	CLR.b	obj_move_counter(A6)
	CLR.b	obj_npc_busy_flag(A6)
	MOVE.w	#$0030, obj_attack_timer(A6)
	MOVE.l	#UpdateArgentosTrailClone, obj_tick_fn(A6)
ArgentosProjectile_NoTrailThisTick:
	RTS

DeactivateArgentosProjectile:
	MOVE.b	#FLAG_TRUE, obj_npc_busy_flag(A5)
	RTS

UpdateArgentosTrailClone:
	SUBQ.w	#1, obj_attack_timer(A5)
	BLE.b	DeactivateArgentosTrailClone
	JSR	CheckProjectileHitEnemies(PC)
	CLR.b	obj_npc_busy_flag(A5)
	LEA	ArgentosSpriteFrameTable, A0
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0018, D0
	ASR.w	#2, D0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	JSR	AddSpriteToDisplayList
	RTS

DeactivateArgentosTrailClone:
	BCLR.b	#7, (A5)
	MOVE.b	#FLAG_TRUE, obj_npc_busy_flag(A5)
	RTS

; ----------------------------------------------------------------------
; UpdatePlayerSpriteFrame
;
; Selects the current animation frame for the metal-spell player sprite.
; Maps obj_direction >> 4 to a 0-3 cardinal index, mirrors the H-flip
; flag for left-facing directions, then indexes MetalSpellSpriteFrameTable
; with (cardinal * 8 + (move_counter >> 1 & 6)) for a 4-frame walk cycle.
; Used by Ferros and similar melee-zone spell objects.
; ----------------------------------------------------------------------
UpdatePlayerSpriteFrame:
	MOVE.b	obj_direction(A5), D1
	ASR.b	#4, D1
	ADDQ.b	#5, D1
	ANDI.w	#$000E, D1
	ASR.w	#1, D1
	BCLR.b	#3, obj_sprite_flags(A5)
	BTST.l	#2, D1
	BNE.b	PlayerSpriteFrame_LookupAndAnimate
	BSET.b	#3, obj_sprite_flags(A5)
PlayerSpriteFrame_LookupAndAnimate:
	ASL.w	#3, D1
	LEA	MetalSpellSpriteFrameTable, A0
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	ASR.w	#1, D0
	ADD.w	D1, D0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	RTS
	
; ----------------------------------------------------------------------
; FindNthEnemyInList
;
; Input:  D1 = 0-based index into the enemy list; A6 = destination object.
; Scans the enemy list, advancing 3 links per iteration, until the
; Nth active slot is found.  Stores the enemy pointer in obj_hp(A6).
; If no matching slot is found, stores 0 in obj_hp(A6).
; ----------------------------------------------------------------------
FindNthEnemyInList:
	MOVEA.l	Enemy_list_ptr.w, A4
FindNthEnemy_SearchLoop:
	BTST.b	#7, (A4)
	BNE.w	FindNthEnemy_Found
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A4
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A4
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A4
	DBF	D1, FindNthEnemy_SearchLoop
	MOVE.l	#0, obj_hp(A6)
	RTS
	
FindNthEnemy_Found:
	MOVE.l	A4, obj_hp(A6)
	RTS

; ----------------------------------------------------------------------
; CastHydro
;
; Spawns a water-geyser spell centred on the first active enemy
; (SetPositionFromActiveEnemy).  Plays through three internal phases:
;   1. UpdateHydroOpeningAnimation   - 5-frame opening animation
;   2. UpdateHydroSpawnIcicles       - Spawn up to 5 icicle sub-objects
;                                      at 8-frame intervals; each icicle
;                                      rises then explodes.
;   3. UpdateHydroWaitForIciclesFinish - Waits until all sub-icicles are
;                                        deactivated, then deactivates self.
; obj_attack_timer counts icicles spawned (0-5).
; obj_invuln_timer is the spawn-cooldown for each icicle.
; obj_knockback_timer holds sort_key for child icicles.
; ----------------------------------------------------------------------
CastHydro:
	MOVEA.l	Object_slot_02_ptr.w, A6
	BTST.b	#7, (A6)
	BNE.w	CastHydro_Done
	BSR.w	CheckCursedAndConsumeReadiedMagicMp
	BNE.w	CastHydro_Done
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BCLR.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A6)
	MOVE.w	#VRAM_TILE_PLAYER_SLASH, obj_tile_index(A6)
	BSR.w	SetPositionFromActiveEnemy
	MOVE.w	#0, obj_sort_key(A6)
	MOVE.w	#$0070, obj_knockback_timer(A6)
	MOVE.w	#$0010, obj_hitbox_half_w(A6)
	MOVE.w	#$0014, obj_hitbox_half_h(A6)
	CLR.b	obj_invuln_timer(A6)
	CLR.b	obj_move_counter(A6)
	CLR.w	obj_attack_timer(A6)
	MOVE.l	#UpdateHydroOpeningAnimation, obj_tick_fn(A6)
	BSR.w	InitMagicDamageAndFlags
CastHydro_Done:
	RTS

UpdateHydroOpeningAnimation:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$001C, D0
	CMPI.w	#$0014, D0
	BLT.b	HydroOpening_LookupFrame
	MOVE.l	#UpdateHydroSpawnIcicles, obj_tick_fn(A5)
	BRA.b	HydroOpening_DrawSprite
HydroOpening_LookupFrame:
	LEA	HydroOpeningSpriteFrameTable, A0
	ASR.w	#1, D0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
HydroOpening_DrawSprite:
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS

UpdateHydroSpawnIcicles:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGT.w	HydroSpawnIcicle_PlaySoundAndDraw
	MOVE.b	#8, obj_invuln_timer(A5)
	LEA	(A5), A6
	MOVE.w	obj_attack_timer(A5), D7
HydroSpawnIcicle_AdvanceToSlotLoop:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, HydroSpawnIcicle_AdvanceToSlotLoop
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BCLR.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A6)
	MOVE.w	#VRAM_TILE_HYDRO_ICICLE_FALL, obj_tile_index(A6)
	MOVE.w	obj_world_x(A5), obj_world_x(A6)
	MOVE.w	obj_world_y(A5), D0
	SUBQ.w	#8, D0
	MOVE.w	D0, obj_world_y(A6)
	MOVE.w	obj_knockback_timer(A5), obj_sort_key(A6)
	CLR.l	obj_vel_x(A6)
	MOVE.l	#$FFFD0000, obj_vel_y(A6)
	MOVE.w	#$0014, D0
	MOVE.w	obj_attack_timer(A5), D1
	ADD.w	D1, D1
	ADD.w	D1, D1
	SUB.w	D1, D0
	MOVE.b	D0, obj_invuln_timer(A6)
	MOVE.l	#UpdateHydroIcicleRise, obj_tick_fn(A6)
	ADDQ.w	#1, obj_attack_timer(A5)
	CMPI.w	#5, obj_attack_timer(A5)
	BLE.b	HydroSpawnIcicle_PlaySoundAndDraw
	MOVE.l	#UpdateHydroWaitForIciclesFinish, obj_tick_fn(A5)
	MOVE.w	#VRAM_TILE_HYDRO_ICICLE, obj_tile_index(A5)
	BRA.b	HydroSpawnIcicle_HitCheckAndDraw
HydroSpawnIcicle_PlaySoundAndDraw:
	MOVE.w	#SOUND_HYDRO_ICICLE, D0
	JSR	QueueSoundEffect
HydroSpawnIcicle_HitCheckAndDraw:
	JSR	CheckProjectileHitEnemies(PC)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS

UpdateHydroWaitForIciclesFinish:
	LEA	(A5), A6
	MOVE.w	obj_attack_timer(A5), D7
	SUBQ.w	#1, D7
HydroWaitIcicles_AdvanceToSlotLoop:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, HydroWaitIcicles_AdvanceToSlotLoop
	BTST.b	#7, (A6)
	BNE.b	HydroWaitIcicles_DrawBaseSprite
	BCLR.b	#7, (A5)
HydroWaitIcicles_DrawBaseSprite:
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS

UpdateHydroIcicleRise:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGT.b	HydroIcicleRise_MoveUp
	CLR.b	obj_move_counter(A5)
	MOVE.l	#UpdateHydroIcicleExplode, obj_tick_fn(A5)
HydroIcicleRise_MoveUp:
	MOVE.l	obj_vel_y(A5), D0
	ADD.l	D0, obj_world_y(A5)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS

UpdateHydroIcicleExplode:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	CMPI.w	#4, D0
	BLE.b	HydroIcicleExplode_DrawFrame
	BCLR.b	#7, (A5)
	RTS

HydroIcicleExplode_DrawFrame:
	LEA	HydroExplosionSpriteFrameTable, A0
	ASR.w	#1, D0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS

; ----------------------------------------------------------------------
; SetPositionFromActiveEnemy
;
; Sets obj_world_x/Y of A6 to match the first active, alive enemy.
; Y is offset by +8 to centre the spell on the enemy sprite.
; Falls back to ($00A0, $0070) if no active enemy is found.
; Called by CastHydro and CastHydrios to anchor the spell target.
; ----------------------------------------------------------------------
SetPositionFromActiveEnemy:
	MOVEA.l	Enemy_list_ptr.w, A4
	MOVEQ	#7, D7
SetPosFromEnemy_SearchLoop:
	BTST.b	#7, (A4)
	BEQ.b	SetPosFromEnemy_NextSlot
	BTST.b	#6, (A4)
	BEQ.b	SetPosFromEnemy_NextSlot
	MOVE.w	obj_world_x(A4), obj_world_x(A6)
	MOVE.w	obj_world_y(A4), D0
	ADDQ.w	#8, D0
	MOVE.w	D0, obj_world_y(A6)
	RTS

SetPosFromEnemy_NextSlot:
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A4
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A4
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A4
	DBF	D7, SetPosFromEnemy_SearchLoop
	MOVE.w	#$00A0, obj_world_x(A6)	
	MOVE.w	#$0070, obj_world_y(A6)	
	RTS
	
; ----------------------------------------------------------------------
; CastChronos / CastChronios
;
; Time-stop spells.  Both activate slot 02, set a countdown in obj_hp,
; and set Encounter_behavior_flag = FLAG_TRUE to freeze enemies.
; UpdateChronoCountdown decrements obj_hp each tick; when it reaches 0
; the slot is deactivated and Encounter_behavior_flag is cleared.
; Chronios uses CHRONIOS_DURATION (longer duration than Chronos).
; ----------------------------------------------------------------------
CastChronos:
	BSR.w	CheckCursedAndConsumeReadiedMagicMp
	BNE.b	CastChronos_Done
	MOVEA.l	Object_slot_02_ptr.w, A6
	BSET.b	#7, (A6)
	MOVE.w	#CHRONOS_DURATION, obj_hp(A6)
	MOVE.l	#UpdateChronoCountdown, obj_tick_fn(A6)
	MOVE.b	#FLAG_TRUE, Encounter_behavior_flag.w
	MOVE.w	#SOUND_ITEM_PICKUP, D0
	JSR	QueueSoundEffect
CastChronos_Done:
	RTS
	
UpdateChronoCountdown:
	SUBQ.w	#1, obj_hp(A5)
	BGT.b	ChronoCountdown_StillActive
	BCLR.b	#7, (A5)
	CLR.b	Encounter_behavior_flag.w
ChronoCountdown_StillActive:
	RTS

CastChronios:
	BSR.w	CheckCursedAndConsumeReadiedMagicMp
	BNE.b	CastChronios_Done
	MOVEA.l	Object_slot_02_ptr.w, A6
	BSET.b	#7, (A6)
	MOVE.w	#CHRONIOS_DURATION, obj_hp(A6)
	MOVE.l	#UpdateChronoCountdown, obj_tick_fn(A6)
	MOVE.b	#FLAG_TRUE, Encounter_behavior_flag.w
	MOVE.w	#SOUND_ITEM_PICKUP, D0
	JSR	QueueSoundEffect
CastChronios_Done:
	RTS

; ----------------------------------------------------------------------
; CastTerrafissi
;
; Screen-shake earthquake spell.  obj_knockback_timer is initialised
; to 9 * 8 = 72 and counts down each frame.  Each tick:
;   - ApplyScreenShakeToEnemies subtracts obj_max_hp from every active
;     enemy's obj_hp (i.e. deals continuous magic damage).
;   - A displacement byte from TerrafissiShakeDisplacementTable
;     (indexed by obj_knockback_timer) is sign-extended, shifted into
;     the upper word as a fixed-point value, accumulated in obj_hp, and
;     written to HScroll_base for the horizontal-scroll shake effect.
; When the counter reaches 0, HScroll_base is zeroed and the slot
; deactivated.
; ----------------------------------------------------------------------
CastTerrafissi:
	MOVEA.l	Object_slot_02_ptr.w, A6
	BTST.b	#7, (A6)
	BNE.b	CastTerrafissi_Done
	BSR.w	CheckCursedAndConsumeReadiedMagicMp
	BNE.b	CastTerrafissi_Done
	MOVE.w	#SOUND_TERRAFISSI, D0
	JSR	QueueSoundEffect
	BSET.b	#7, (A6)
	CLR.l	obj_hp(A6)
	MOVE.w	#9, D0
	ASL.w	#3, D0
	MOVE.w	D0, obj_knockback_timer(A6)
	BSR.w	InitMagicDamageAndFlags
	MOVE.l	#UpdateTerrafissiShake, obj_tick_fn(A6)
CastTerrafissi_Done:
	RTS

UpdateTerrafissiShake:
	TST.w	obj_knockback_timer(A5)
	BLE.b	TerrafissiShake_Finished
	BSR.w	ApplyScreenShakeToEnemies
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVE.w	obj_knockback_timer(A5), D0
	LEA	TerrafissiShakeDisplacementTable, A0
	CLR.l	D1
	MOVE.b	(A0,D0.w), D1
	EXT.w	D1
	SWAP	D1
	ASR.l	#4, D1
	ADD.l	D1, obj_hp(A5)
	MOVE.w	obj_hp(A5), HScroll_base.w
	RTS

TerrafissiShake_Finished:
	CLR.l	HScroll_base.w
	BCLR.b	#7, (A5)
	RTS

ApplyScreenShakeToEnemies:
	MOVEA.l	Enemy_list_ptr.w, A4
	MOVE.w	#7, D6
ApplyShakeToEnemies_Loop:
	BTST.b	#7, (A4)
	BEQ.b	ApplyShakeToEnemies_NextSlot
	MOVE.w	obj_max_hp(A5), D0
	SUB.w	D0, obj_hp(A4)
ApplyShakeToEnemies_NextSlot:
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A4
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A4
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A4
	DBF	D6, ApplyShakeToEnemies_Loop
	RTS

; TerrafissiShakeDisplacementTable
; 192 bytes of signed horizontal-scroll displacement values.
; Indexed by obj_knockback_timer (72 → 0, counting down).
; Values alternate between equal positive and negative pairs to create
; an oscillating left-right shake that gradually grows in amplitude
; (from $04/$FC near the end to $40/$C0 at peak), then fades back.
TerrafissiShakeDisplacementTable:
	dc.b	$04, $04, $04, $04, $FC, $FC, $FC, $FC, $08, $08, $F8, $F8, $08, $08, $F8, $F8, $10, $F0, $10, $F0, $10, $10, $F0, $F0, $20, $E0, $20, $E0, $20, $20, $E0, $E0 
	dc.b	$20, $E0, $20, $E0, $20, $20, $E0, $E0, $30, $D0, $30, $D0, $30, $30, $D0, $D0, $30, $D0, $30, $D0, $30, $30, $D0, $D0, $40, $C0, $40, $C0, $40, $40, $C0, $C0 
	dc.b	$40, $C0, $40, $C0, $40, $40, $C0, $C0, $40, $C0, $40, $C0, $40, $40, $C0, $C0, $40, $C0, $40, $C0, $40, $40, $C0, $C0, $40, $C0, $40, $C0, $40, $40, $C0, $C0 
	dc.b	$40, $C0, $40, $C0, $40, $40, $C0, $C0, $40, $C0, $40, $C0, $40, $40, $C0, $C0, $40, $C0, $40, $C0, $40, $40, $C0, $C0, $40, $C0, $40, $C0, $40, $40, $C0, $C0 
	dc.b	$30, $D0, $30, $D0, $30, $30, $D0, $D0, $30, $D0, $30, $D0, $30, $30, $D0, $D0, $20, $E0, $20, $E0, $20, $20, $E0, $E0, $20, $E0, $20, $E0, $20, $20, $E0, $E0 
	dc.b	$10, $F0, $10, $F0, $10, $10, $F0, $F0, $08, $08, $F8, $F8, $08, $08, $F8, $F8, $04, $04, $04, $04, $FC, $FC, $FC, $FC, $2C, $78, $CC, $1C, $4A, $2E, $00, $19 
	dc.b	$67, $12, $42, $40, $10, $2E, $00, $01, $4D, $F6, $00, $00, $51, $CF, $FF, $EE, $61, $00, $00, $2C, $4E, $75 
; ----------------------------------------------------------------------
; CheckMagicSlotActiveOrClearAll
;
; Scans up to 8 object slots starting from Object_slot_02_ptr.
; If any active slot (bit 7 set) has obj_npc_busy_flag == 0, returns
; immediately (at least one projectile is still alive).
; If all slots are either inactive or have obj_npc_busy_flag != 0, calls
; ClearEnemyActiveFlags_Alt to deactivate all 13 object slots and
; signal spell completion.
; ----------------------------------------------------------------------
CheckMagicSlotActiveOrClearAll:
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.w	#7, D7
CheckMagicSlotActive_Loop:
	BTST.b	#7, (A6)
	BEQ.b	CheckMagicSlotActive_NextSlot
	TST.b	obj_npc_busy_flag(A6)
	BEQ.b	CheckMagicSlotActive_FoundAlive
CheckMagicSlotActive_NextSlot:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, CheckMagicSlotActive_Loop
	BSR.w	ClearEnemyActiveFlags_Alt
CheckMagicSlotActive_FoundAlive:
	RTS

; ----------------------------------------------------------------------
; ClearEnemyActiveFlags_Alt
;
; Force-deactivates 13 consecutive object slots starting from
; Object_slot_02_ptr (clears bit 7 in each slot's first byte).
; Used to clean up all magic projectile slots at once when a spell ends.
; ----------------------------------------------------------------------
ClearEnemyActiveFlags_Alt:
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.w	#$000C, D7
ClearEnemyActiveFlags_Loop:
	BCLR.b	#7, (A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, ClearEnemyActiveFlags_Loop
	RTS

; ----------------------------------------------------------------------
; CheckProjectileHitEnemies
;
; AABB collision test between the calling projectile (A5) and all active
; enemies.  Iterates up to 8 enemy slots (3 hops per iteration).
; For each active, visible, living enemy, tests:
;   projectile.right  > enemy.left  (D0 = proj.world_x - hitbox_half_w)
;   projectile.left   < enemy.right (D1 = proj.world_x + hitbox_half_w)
;   projectile.top    < enemy.bottom (D2 = proj.world_y - hitbox_half_h)
;   projectile.bottom > enemy.top   (D3 = proj.world_y)
; On a hit: subtracts obj_max_hp from the enemy's obj_hp, accounting for
; elemental resistance (if obj_behavior_flag bit matches, damage ÷ 8).
; Sets obj_npc_busy_flag = FLAG_TRUE on the projectile after each hit.
; ----------------------------------------------------------------------
CheckProjectileHitEnemies:
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	D0, D1
	ADD.w	obj_hitbox_half_w(A5), D1
	SUB.w	obj_hitbox_half_w(A5), D0
	MOVE.w	obj_world_y(A5), D3
	MOVE.w	D3, D2
	SUB.w	obj_hitbox_half_h(A5), D2
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#7, D7
CheckHitEnemies_Loop:
	BTST.b	#7, (A6)
	BEQ.w	CheckHitEnemies_NextEnemy
	BTST.b	#6, (A6)
	BEQ.w	CheckHitEnemies_NextEnemy
	TST.w	obj_hp(A6)
	BLE.w	CheckHitEnemies_NextEnemy
	MOVE.w	obj_world_x(A6), D4
	ADD.w	obj_hitbox_half_w(A6), D4
	CMP.w	D4, D0
	BGT.w	CheckHitEnemies_NextEnemy
	MOVE.w	obj_world_x(A6), D4
	SUB.w	obj_hitbox_half_w(A6), D4
	CMP.w	D4, D1
	BLT.w	CheckHitEnemies_NextEnemy
	MOVE.w	obj_world_y(A6), D4
	CMP.w	D4, D2
	BGT.w	CheckHitEnemies_NextEnemy
	SUB.w	obj_hitbox_half_h(A6), D4
	CMP.w	D4, D3
	BLT.w	CheckHitEnemies_NextEnemy
	MOVE.w	obj_max_hp(A5), D0
	CLR.w	D1
	MOVE.b	obj_behavior_flag(A5), D1
	MOVE.b	obj_behavior_flag(A6), D2
	BTST.l	D1, D2
	BEQ.b	CheckHitEnemies_ApplyDamage
	ASR.w	#3, D0
CheckHitEnemies_ApplyDamage:
	SUB.w	D0, obj_hp(A6)
	MOVE.b	#FLAG_TRUE, obj_npc_busy_flag(A5)
CheckHitEnemies_NextEnemy:
	CLR.w	D5
	MOVE.b	obj_next_offset(A6), D5
	LEA	(A6,D5.w), A6
	CLR.w	D5
	MOVE.b	obj_next_offset(A6), D5
	LEA	(A6,D5.w), A6
	CLR.w	D5
	MOVE.b	obj_next_offset(A6), D5
	LEA	(A6,D5.w), A6
	DBF	D7, CheckHitEnemies_Loop
	RTS

; ----------------------------------------------------------------------
; UpdateHomingProjectileDirection
;
; Steers the projectile in A5 one step (±1 direction unit, 0-7) toward
; the target enemy stored in obj_hp(A5) / A6.
; Calls CalculateAngleBetweenObjects to get a target angle (0-7), then
; picks the shorter arc (clockwise or counter-clockwise) by comparing
; the direct delta with the wrap-around delta.
; Clamps the stored direction to 0-7 after each step.
; ----------------------------------------------------------------------
UpdateHomingProjectileDirection:
	JSR	CalculateAngleBetweenObjects
	ANDI.w	#7, D0
	CLR.w	D2
	MOVE.b	obj_direction(A5), D2
	MOVE.w	D2, D3
	SUB.w	D0, D3
	BNE.b	HomingDirection_CompareSigns
	MOVE.b	D0, obj_direction(A5)
	BRA.w	HomingDirection_WrapAngle
HomingDirection_CompareSigns:
	BGT.b	HomingDirection_CheckWrapRight
	NEG.w	D3
	MOVE.w	#8, D4
	SUB.w	D0, D4
	ADD.w	D2, D4
	CMP.w	D3, D4
	BLE.b	HomingDirection_TurnCW
	BRA.b	HomingDirection_TurnCCW
HomingDirection_CheckWrapRight:
	MOVE.w	#8, D4
	SUB.w	D2, D4
	ADD.w	D0, D4
	CMP.w	D3, D4
	BGE.b	HomingDirection_TurnCW
HomingDirection_TurnCCW:
	ADDQ.b	#1, obj_direction(A5)
	BRA.w	HomingDirection_WrapAngle
HomingDirection_TurnCW:
	SUBQ.b	#1, obj_direction(A5)
HomingDirection_WrapAngle:
	ANDI.b	#7, obj_direction(A5)
	RTS

FindTargetEnemyForHoming:
	MOVEA.l	Enemy_list_ptr.w, A4
	MOVE.w	D1, D6
	BLE.b	FindTargetEnemy_CheckIfActive
	SUBQ.w	#1, D6
FindTargetEnemy_SkipToNthLoop:
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A4
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A4
	CLR.w	D5
	MOVE.b	obj_next_offset(A4), D5
	LEA	(A4,D5.w), A4
	DBF	D6, FindTargetEnemy_SkipToNthLoop
FindTargetEnemy_CheckIfActive:
	BTST.b	#7, (A4)
	BEQ.b	FindTargetEnemy_NoTarget
	BTST.b	#6, (A4)
	BEQ.b	FindTargetEnemy_NoTarget
	MOVE.l	A4, obj_hp(A6)
	RTS

FindTargetEnemy_NoTarget:
	MOVE.l	#0, obj_hp(A6)
	RTS

; ----------------------------------------------------------------------
; CheckCursedAndConsumeReadiedMagicMp
;
; Pre-cast guard: verifies the player is not cursed (CheckIfCursed),
; then looks up the MP cost of Readied_magic in MagicMpConsumptionMap
; and deducts it from Player_mp.  Returns D0=0 (Z set) on success,
; D0=$FFFF (NE) on failure (cursed or insufficient MP).
; Used as the first call in every CastXxx function.
; ----------------------------------------------------------------------
CheckCursedAndConsumeReadiedMagicMp:
	JSR	CheckIfCursed
	BNE.b	ConsumeReadiedMagicMp_Fail
	LEA	MagicMpConsumptionMap, A0
	MOVE.w	Readied_magic.w, D0
	ANDI.w	#$001F, D0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), D0
	MOVE.w	Player_mp.w, D1
	SUB.w	D0, D1
	BLT.b	ConsumeReadiedMagicMp_Fail
	SUB.w	D0, Player_mp.w
	CLR.w	D0
	RTS

ConsumeReadiedMagicMp_Fail:
	MOVE.w	#$FFFF, D0	
	RTS
	
; ----------------------------------------------------------------------
; DeductMagicMP
;
; Deducts MP for the spell currently selected in the magic menu
; (Magic_list_cursor_index -> Possessed_magics_list -> MagicMpConsumptionMap).
; Returns D0=0 on success, D0=$FFFF if Player_mp would go negative.
; Used by the magic-menu confirm path (distinct from the battle cast path).
; ----------------------------------------------------------------------
DeductMagicMP:
	LEA	Possessed_magics_list.w, A0
	MOVE.w	Magic_list_cursor_index.w, D0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), D0
	ANDI.w	#$00FF, D0
	LEA	MagicMpConsumptionMap, A0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), D0
	MOVE.w	Player_mp.w, D1
	SUB.w	D0, D1
	BLT.b	DeductMagicMP_Fail
	SUB.w	D0, Player_mp.w
	CLR.w	D0
	RTS

DeductMagicMP_Fail:
	MOVE.w	#$FFFF, D0	
	RTS
	
; ----------------------------------------------------------------------
; InitMagicDamageAndFlags
;
; Computes projectile damage for A6 based on Readied_magic and Player_int.
; High-damage spells (Volti, Copperos, Argentos, Hydro, Hydrios,
; Terrafissi) scale INT by >> 8 (low scale); others use >> 4 (high scale).
; Looks up base damage from MagicBaseDamageTable[spell] and adds the
; scaled INT value, storing in obj_max_hp(A6).  Also sets obj_behavior_flag
; from MagicElementTypeTable[spell] to encode elemental type.
; ----------------------------------------------------------------------
InitMagicDamageAndFlags:
	LEA	MagicBaseDamageTable, A4
	MOVE.w	Readied_magic.w, D0
	ANDI.w	#$000F, D0
	MOVE.w	D0, D2
	MOVE.w	Player_int.w, D1
	CMPI.w	#MAGIC_VOLTIO, D0
	BEQ.b	InitMagicDamage_LowIntScale
	CMPI.w	#MAGIC_COPPEROS, D0
	BEQ.b	InitMagicDamage_LowIntScale
	CMPI.w	#MAGIC_ARGENTOS, D0
	BEQ.b	InitMagicDamage_LowIntScale
	CMPI.w	#MAGIC_HYDRO, D0
	BEQ.b	InitMagicDamage_LowIntScale
	CMPI.w	#MAGIC_HYDRIOS, D0
	BEQ.b	InitMagicDamage_LowIntScale
	CMPI.w	#MAGIC_TERRAFISSI, D0
	BEQ.b	InitMagicDamage_LowIntScale
	ASR.w	#4, D1
	BRA.b	InitMagicDamage_LookupAndStore
InitMagicDamage_LowIntScale:
	ASR.w	#8, D1
InitMagicDamage_LookupAndStore:
	ADD.w	D0, D0
	MOVE.w	(A4,D0.w), D0
	ADD.w	D1, D0
	MOVE.w	D0, obj_max_hp(A6)
	LEA	MagicElementTypeTable, A4
	MOVE.w	Readied_magic.w, D0
	MOVE.b	(A4,D2.w), obj_behavior_flag(A6)
	RTS

; ----------------------------------------------------------------------
; CheckCoordsInBounds
;
; Validates world (X, Y) coordinates against the battle field boundary.
; Input:  D0 = world_x,  D1 = world_y
; Output: D0 = $FFFF if in-bounds, D0 = 0 if out-of-bounds (Z flag set)
; Boundary constants (from constants.asm):
;   X: 0 .. BATTLE_FIELD_WIDTH
;   Y: BATTLE_FIELD_TOP .. BATTLE_FIELD_BOTTOM
; ----------------------------------------------------------------------
CheckCoordsInBounds:
	CMPI.w	#0, D0
	BLT.b	CoordsOutOfBounds
	CMPI.w	#BATTLE_FIELD_WIDTH, D0
	BGT.b	CoordsOutOfBounds
	CMPI.w	#BATTLE_FIELD_TOP, D1
	BLT.b	CoordsOutOfBounds
	CMPI.w	#BATTLE_FIELD_BOTTOM, D1
	BGT.b	CoordsOutOfBounds
	MOVE.w	#$FFFF, D0
	RTS

CoordsOutOfBounds:
	CLR.w	D0
	RTS

; ======================================================================
; Item Menu State Machine
; ======================================================================

; ----------------------------------------------------------------------
; ItemMenuStateMachine / ItemMenuStateJumpTable
;
; Dispatches to the current item-menu handler using Item_menu_state
; (low nibble) as an index into ItemMenuStateJumpTable.
;
; State table (BRA entries, 6 bytes each):
;   $0  ItemMenuStateJumpTable_Loop     - Init: draw Use/Discard menu
;   $1  ItemMenuStateJumpTable_Loop2    - Wait for input, handle B/C
;   $2  ItemMenuUseOrDiscard_Done_Loop  - Close menus / "nothing to use"
;   $3  ItemMenu_ScriptDone_Loop        - Script running after discard
;   $4  ItemMenu_ItemUsed_Return_Loop   - Show item discard menu
;   $5  ItemMenu_ItemUsed_Return_Loop2  - Confirm discard yes/no
;   $6  ItemMenu_ItemUsed_Return_Loop3  - After discard confirm
;   $7  ItemMenu_ItemUsed_Return_Loop4  - Post-discard cleanup
;   $8  ItemMenu_ScriptDone2_Loop       - Show item use menu
;   $9  ItemMenu_ScriptDone2_Loop2      - Wait for use menu input
;   $A  UseItemDescription_Build_Loop   - Use item: build description
;   $B  UseItemDescription_Build_Loop2  - Light up cave (continued)
;   $C  ItemMenu_ScriptDoneCheckCave_Loop - Light up cave / Candle / Lantern
;   $D  ItemMenu_ScriptDoneCheckCave_Loop2 - Teleport / Griffin Wing
;   $E  UseExtrios_Warp_Loop            - Exit cave / Gnome Stone
; ----------------------------------------------------------------------
ItemMenuStateMachine:
	MOVE.w	Item_menu_state.w, D0
	ANDI.w	#$F, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	ItemMenuStateJumpTable, A0
	JSR	(A0,D0.w)
	RTS

ItemMenuStateJumpTable: ; Item effect routines map
	BRA.w	ItemMenuStateJumpTable_Loop
	BRA.w	ItemMenuStateJumpTable_Loop2
	BRA.w	ItemMenuUseOrDiscard_Done_Loop ; Close menus / "You have nothing to use"
	BRA.w	ItemMenu_ScriptDone_Loop
	BRA.w	ItemMenu_ItemUsed_Return_Loop ; Show item discard menu
	BRA.w	ItemMenu_ItemUsed_Return_Loop2
	BRA.w	ItemMenu_ItemUsed_Return_Loop3
	BRA.w	ItemMenu_ItemUsed_Return_Loop4
	BRA.w	ItemMenu_ScriptDone2_Loop ; Show item use menu
	BRA.w	ItemMenu_ScriptDone2_Loop2
	BRA.w	UseItemDescription_Build_Loop
	BRA.w	UseItemDescription_Build_Loop2 ; Light up cave, continued
	BRA.w	ItemMenu_ScriptDoneCheckCave_Loop ; Light up cave / Candle / Lantern
	BRA.w	ItemMenu_ScriptDoneCheckCave_Loop2 ; Teleport to last town / Griffin Wing
	BRA.w	UseExtrios_Warp_Loop ; Exit cave / Gnome Stone
ItemMenuStateJumpTable_Loop:
	MOVE.w	Main_menu_selection.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	JSR	SaveItemListAreaToBuffer_Small
	JSR	DrawUseDiscardMenuWindow
	CLR.w	Item_menu_action_mode.w
	ADDQ.w	#1, Item_menu_state.w
	RTS

ItemMenuStateJumpTable_Loop2:
	TST.b	Window_tilemap_draw_active.w
	BNE.w	ItemMenuUseOrDiscard_Done
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BEQ.b	ItemMenuStateJumpTable_Loop3
	MOVE.w	#WINDOW_DRAW_ITEM_LIST_SHORT, Window_draw_type.w
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	MOVE.w	#OVERWORLD_MENU_STATE_OPTIONS_WAIT, Overworld_menu_state.w
	JSR	InitMenuCursorDefaults
	RTS

ItemMenuStateJumpTable_Loop3:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.w	ItemMenuUseOrDiscard_Done_Loop2
	MOVE.w	Item_menu_action_mode.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	MOVE.w	#SOUND_MENU_SELECT, D0
	JSR	QueueSoundEffect
	JSR	SaveStatusBarToBuffer
	JSR	ResetScriptAndInitDialogue
	TST.w	Possessed_items_length.w
	BNE.b	ItemMenuStateJumpTable_Loop4
	PRINT 	YouHaveNothingToUseStr
	MOVE.w	#ITEM_MENU_STATE_CLOSE, Item_menu_state.w
	BRA.b	ItemMenuUseOrDiscard_Done
ItemMenuStateJumpTable_Loop4:
	TST.w	Item_menu_action_mode.w
	BEQ.b	ItemMenuStateJumpTable_Loop5
	PRINT 	DiscardWhichItemStr
	MOVE.w	#ITEM_MENU_STATE_DISCARD_INIT, Item_menu_state.w
	BRA.b	ItemMenuUseOrDiscard_Done
ItemMenuStateJumpTable_Loop5:
	PRINT 	UseWhichItemStr
	MOVE.w	#ITEM_MENU_STATE_USE_INIT, Item_menu_state.w
ItemMenuUseOrDiscard_Done:
	RTS

ItemMenuUseOrDiscard_Done_Loop2:
	MOVE.w	Item_menu_action_mode.w, Menu_cursor_index.w
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Item_menu_action_mode.w
	RTS

ItemMenuUseOrDiscard_Done_Loop:
	TST.b	Script_text_complete.w
	BEQ.w	ItemMenu_ScriptDone_Loop2
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	ItemMenu_ScriptDone
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	ItemMenu_ScriptDone
	RTS

; ----------------------------------------------------------------------
; ItemMenu_ScriptDone / ItemMenu state machine
;
; Called after a UseItemXxx function prints its result text.  Draws the
; status HUD and sets Item_menu_state to ITEM_MENU_STATE_SCRIPT_DONE,
; then re-draws the short item list and marks the tilemap row as pending.
; The caller loops here each tick until the script text scrolls out.
; UseItemDescription_Build builds the item-description string for display.
; ----------------------------------------------------------------------
ItemMenu_ScriptDone:
	JSR	DrawStatusHudWindow
	MOVE.w	#ITEM_MENU_STATE_SCRIPT_DONE, Item_menu_state.w
	MOVE.w	#WINDOW_DRAW_ITEM_LIST_SHORT, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	RTS

ItemMenu_ScriptDone_Loop2:
	JSR	ProcessScriptText
	RTS

ItemMenu_ScriptDone_Loop:
	TST.b	Window_tilemap_row_draw_pending.w
	BNE.b	ItemMenu_ItemUsed_Return
	CLR.w	Overworld_menu_state.w
	MOVE.w	#WINDOW_DRAW_MSG_SPEED_ALT, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	TST.b	Sixteen_rings_used_at_throne.w
	BEQ.b	ItemMenu_ItemUsed_Return
	MOVE.w	#PROGRAM_STATE_ENDING_INIT, Program_state.w
ItemMenu_ItemUsed_Return:
	RTS

ItemMenu_ItemUsed_Return_Loop:
	TST.b	Script_text_complete.w
	BEQ.b	ItemMenu_ItemUsed_Return_Loop5
	JSR	SaveCenterDialogAreaToBuffer
	JSR	DrawItemListBorders
	JSR	DrawItemListNames
	CLR.w	Selected_item_index.w
	MOVE.w	#ITEM_MENU_STATE_DISCARD_WAIT, Item_menu_state.w
	MOVE.w	Possessed_items_length.w, D0
	JSR	InitMenuCursorForList
	RTS

ItemMenu_ItemUsed_Return_Loop5:
	JSR	ProcessScriptText
	RTS

ItemMenu_ItemUsed_Return_Loop2:
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BEQ.b	ItemMenu_ItemUsed_Return_Loop6
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	JSR	DrawCenterMenuWindow
	JSR	DrawStatusHudWindow
	MOVE.w	#ITEM_MENU_STATE_WAIT_INPUT, Item_menu_state.w
	JSR	InitItemMenuCursor
	RTS

ItemMenu_ItemUsed_Return_Loop6:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.b	ItemMenu_ItemUsed_Return_Loop7
	MOVE.w	Selected_item_index.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	MOVE.w	#SOUND_MENU_SELECT, D0
	JSR	QueueSoundEffect
	JSR	SaveRightMenuAreaToBuffer
	JSR	DrawYesNoDialog
	MOVE.w	#ITEM_MENU_STATE_DISCARD_EXEC, Item_menu_state.w
	RTS

ItemMenu_ItemUsed_Return_Loop7:
	MOVE.w	Selected_item_index.w, Menu_cursor_index.w
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Selected_item_index.w
	RTS

ItemMenu_ItemUsed_Return_Loop3:
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	ItemMenu_ItemUsed_Return_Loop8
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.w	ItemMenu_ItemUsed_Return_Loop9
	MOVE.w	#SOUND_MENU_SELECT, D0
	JSR	QueueSoundEffect
	TST.w	Dialog_selection.w
	BEQ.b	ItemMenu_ItemUsed_Return_Loop10
	JSR	DrawLeftMenuWindow
	JSR	DrawCenterMenuWindow
	JSR	DrawStatusHudWindow
	MOVE.w	#ITEM_MENU_STATE_WAIT_INPUT, Item_menu_state.w
	JSR	InitItemMenuCursor
	RTS

ItemMenu_ItemUsed_Return_Loop8:
	MOVE.w	#SOUND_MENU_CANCEL, D0	
	JSR	QueueSoundEffect	
	JSR	DrawLeftMenuWindow	
	CLR.w	Selected_item_index.w	
	MOVE.w	#ITEM_MENU_STATE_DISCARD_WAIT, Item_menu_state.w	
	MOVE.w	Possessed_items_length.w, D0	
	JSR	InitMenuCursorForList	
	RTS
	
ItemMenu_ItemUsed_Return_Loop10:
	JSR	DrawLeftMenuWindow
	JSR	DrawCenterMenuWindow
	JSR	ResetScriptAndInitDialogue
	LEA	ItemNames, A0
	LEA	Possessed_items_list.w, A2
	MOVE.w	Selected_item_index.w, D0
	ADD.w	D0, D0
	MOVE.w	(A2,D0.w), D0
	ANDI.w	#(ITEM_TYPE_NON_DISCARDABLE<<8), D0 ; Check if we can discard item
	BEQ.b	ItemMenu_ItemUsed_Return_Loop11
	PRINT 	CantPutDownStr
	BRA.w	ItemMenu_ItemUsed_Return_Loop12
ItemMenu_ItemUsed_Return_Loop11:
	JSR	CopyPlayerNameToTextBuffer
	LEA	DiscardsTheStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	LEA	ItemNames, A0
	LEA	Possessed_items_list.w, A2
	MOVE.w	Selected_item_index.w, D0
	ADD.w	D0, D0
	MOVE.w	(A2,D0.w), D0
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	CopyStringUntilFF
	MOVE.b	#$2E, (A1)+
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
	SUBQ.w	#1, Possessed_items_length.w
	LEA	Possessed_items_list.w, A0
	MOVE.w	Selected_item_index.w, D0
	MOVE.w	#9, D2
	JSR	RemoveItemFromArray
ItemMenu_ItemUsed_Return_Loop12:
	ADDQ.w	#1, Item_menu_state.w
	RTS

ItemMenu_ItemUsed_Return_Loop9:
	MOVE.w	Dialog_selection.w, Menu_cursor_index.w
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Dialog_selection.w
	RTS

ItemMenu_ItemUsed_Return_Loop4:
	TST.b	Script_text_complete.w
	BEQ.w	ItemMenu_ScriptDone2_Loop3
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	ItemMenu_ScriptDone2
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	ItemMenu_ScriptDone2
	RTS

ItemMenu_ScriptDone2:
	JSR	DrawStatusHudWindow
	MOVE.w	#WINDOW_DRAW_ITEM_LIST_SHORT, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	MOVE.w	#ITEM_MENU_STATE_SCRIPT_DONE, Item_menu_state.w
	RTS

ItemMenu_ScriptDone2_Loop3:
	JSR	ProcessScriptText
	RTS

ItemMenu_ScriptDone2_Loop:
	TST.b	Script_text_complete.w
	BEQ.b	ItemMenu_ScriptDone2_Loop4
	JSR	SaveCenterDialogAreaToBuffer
	JSR	DrawItemListBorders
	JSR	DrawItemListNames
	CLR.w	Selected_item_index.w
	ADDQ.w	#1, Item_menu_state.w
	MOVE.w	Possessed_items_length.w, D0
	JSR	InitMenuCursorForList
	RTS

ItemMenu_ScriptDone2_Loop4:
	JSR	ProcessScriptText
	RTS

ItemMenu_ScriptDone2_Loop2:
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BEQ.b	ItemMenu_ScriptDone2_Loop5
	MOVE.w	#SOUND_MENU_CANCEL, D0
	JSR	QueueSoundEffect
	JSR	DrawCenterMenuWindow
	JSR	DrawStatusHudWindow
	MOVE.w	#ITEM_MENU_STATE_WAIT_INPUT, Item_menu_state.w
	JSR	InitItemMenuCursor
	RTS

ItemMenu_ScriptDone2_Loop5:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.w	UseItemDescription_Build_Loop3
	MOVE.w	Selected_item_index.w, Menu_cursor_index.w
	JSR	DrawMenuCursor
	MOVE.w	#SOUND_MENU_SELECT, D0
	JSR	QueueSoundEffect
	JSR	DrawCenterMenuWindow
	JSR	ResetScriptAndInitDialogue
	JSR	CopyPlayerNameToTextBuffer
	LEA	UsesTheStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	LEA	ItemNames, A0
	LEA	Possessed_items_list.w, A2
	MOVE.w	Selected_item_index.w, D0
	ADD.w	D0, D0
	MOVE.w	(A2,D0.w), D0
	ANDI.w	#$00FF, D0
	CMPI.w	#ITEM_GRIFFIN_WING, D0
	BEQ.w	UseItemDescription_Build
	CMPI.w	#ITEM_GNOME_STONE, D0
	BEQ.w	UseItemDescription_Build
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	CopyStringUntilFF
	MOVE.b	#$2E, (A1)+
	MOVE.b	#SCRIPT_CONTINUE, (A1)+
	PRINT 	Text_build_buffer
	ADDQ.w	#1, Item_menu_state.w
	RTS

UseItemDescription_Build:
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	CopyStringUntilFF
	MOVE.b	#$2E, (A1)+
	MOVE.b	#$FF, (A1)+
	PRINT 	Text_build_buffer
	ADDQ.w	#1, Item_menu_state.w
	RTS

UseItemDescription_Build_Loop3:
	MOVE.w	Selected_item_index.w, Menu_cursor_index.w
	MOVE.w	#VDP_ATTR_SCRIPT, Script_tile_attrs.w
	JSR	HandleMenuInput
	MOVE.w	Menu_cursor_index.w, Selected_item_index.w
	RTS

UseItemDescription_Build_Loop:
	TST.b	Script_has_continuation.w
	BNE.w	UseItemDescription_Build_Loop4
	TST.b	Script_text_complete.w
	BEQ.b	UseItemDescription_Build_Loop5
	JSR	ResetScriptOutputVars
	BRA.w	UseItemDescription_Build_Loop6
UseItemDescription_Build_Loop5:
	JSR	ProcessScriptText
	RTS

UseItemDescription_Build_Loop4:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.b	UseItemDescription_Build_Loop7
	JSR	ResetScriptAndInitDialogue
UseItemDescription_Build_Loop6:
	ADDQ.w	#1, Item_menu_state.w
	LEA	Possessed_items_list.w, A0
	MOVE.w	Selected_item_index.w, D0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), D0
	ANDI.w	#$00FF, D0
	LEA	UseItemMap, A0
	ADD.w	D0, D0
	ADD.w	D0, D0
	JSR	(A0,D0.w)
UseItemDescription_Build_Loop7:
	RTS

UseItemDescription_Build_Loop2:
	TST.b	Script_text_complete.w
	BEQ.w	ItemMenu_ScriptDoneCheckCave_Loop3
	TST.b	Script_has_continuation.w
	BNE.w	ItemMenu_ScriptDoneCheckCave_Loop4
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	ItemMenu_ScriptDoneCheckCave
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	ItemMenu_ScriptDoneCheckCave
	RTS

ItemMenu_ScriptDoneCheckCave:
	JSR	DrawStatusHudWindow
	TST.b	Player_in_first_person_mode.w
	BEQ.b	ItemMenu_ScriptDoneCheckCave_Loop5
	TST.b	Banshee_powder_active.w
	BEQ.b	ItemMenu_ScriptDoneCheckCave_Loop6
	CLR.w	Player_hp.w
ItemMenu_ScriptDoneCheckCave_Loop6:
	JSR	DisplayPlayerHpMp
ItemMenu_ScriptDoneCheckCave_Loop5:
	MOVE.w	#WINDOW_DRAW_ITEM_LIST_SHORT, Window_draw_type.w
	CLR.w	Window_text_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_row_draw_pending.w
	MOVE.w	#ITEM_MENU_STATE_SCRIPT_DONE, Item_menu_state.w
	RTS

ItemMenu_ScriptDoneCheckCave_Loop3:
	JSR	ProcessScriptText
	RTS

ItemMenu_ScriptDoneCheckCave_Loop4:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BEQ.b	ItemMenu_ScriptDoneCheckCave_Loop7
	JSR	InitDialogueWindow
ItemMenu_ScriptDoneCheckCave_Loop7:
	RTS

ItemMenu_ScriptDoneCheckCave_Loop:
	TST.b	Fade_in_lines_mask.w
	BNE.b	ItemMenu_ScriptDoneCheckCave_Loop8
	PRINT 	AreaBrightStr
	JSR	UpdateAreaVisibility
	MOVE.w	#ITEM_MENU_STATE_USE_CAVE, Item_menu_state.w
ItemMenu_ScriptDoneCheckCave_Loop8:
	RTS

ItemMenu_ScriptDoneCheckCave_Loop2:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	UseExtrios_Warp
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	UseExtrios_Warp
	RTS

UseExtrios_Warp:
	LEA	TownOverworldCoords, A0
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_STOW1, D0
	BLE.b	UseExtrios_Warp_Loop2
	CMPI.w	#TOWN_HASTINGS2, D0
	BLE.b	UseExtrios_Warp_Loop3
	SUBQ.w	#1, D0	
UseExtrios_Warp_Loop3:
	SUBQ.w	#1, D0
UseExtrios_Warp_Loop2:
	ANDI.w	#$F, D0
	ASL.w	#3, D0
	MOVE.w	(A0,D0.w), Player_position_x_outside_town.w
	MOVE.w	$2(A0,D0.w), Player_position_y_outside_town.w
	MOVE.w	$4(A0,D0.w), Player_map_sector_x.w
	MOVE.w	$6(A0,D0.w), Player_map_sector_y.w
	MOVE.w	#DIRECTION_UP, Player_direction.w
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.w	#GAMEPLAY_STATE_OVERWORLD_RELOAD, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Player_in_first_person_mode.w
	CLR.b	Is_in_cave.w
	MOVE.w	#SOUND_FOOTSTEP, D0
	JSR	QueueSoundEffect
	RTS

UseExtrios_Warp_Loop:
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	UseExtrios_CaveReturn
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	UseExtrios_CaveReturn
	RTS

UseExtrios_CaveReturn:
	MOVE.w	Player_cave_position_x.w, Player_position_x_outside_town.w
	MOVE.w	Player_cave_position_y.w, Player_position_y_outside_town.w
	MOVE.w	Player_cave_map_sector_x.w, Player_map_sector_x.w
	MOVE.w	Player_cave_map_sector_y.w, Player_map_sector_y.w
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.w	#GAMEPLAY_STATE_OVERWORLD_RELOAD, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Player_in_first_person_mode.w
	CLR.b	Is_in_cave.w
	CLR.b	Cave_light_active.w
	CLR.w	Cave_light_timer.w
	MOVE.w	#SOUND_FOOTSTEP, D0
	JSR	QueueSoundEffect
	RTS

UseItemMap:
	BRA.w	UseHerbs
	BRA.w	UseCandle
	BRA.w	UseLantern
	BRA.w	UsePoisonBalm
	BRA.w	UseAlarmClock
	BRA.w	UseVase
	BRA.w	UseJokeBook
	BRA.w	UseSmallBomb
	BRA.w	UseOldWomansSketch
	BRA.w	UseOldMansSketch
	BRA.w	UsePassToCarthahena
	BRA.w	UseTruffle
	BRA.w	UseDigotPlant
	BRA.w	UseTreasureOfTroy
	BRA.w	UseWhiteCrystal
	BRA.w	UseRedCrystal
	BRA.w	UseBlueCrystal
	BRA.w	UseGeneric ; White crystal
	BRA.w	UseGeneric ; Red key
	BRA.w	UseGeneric ; Blue key
	BRA.w	UseCrown
	BRA.w	UseSixteenRings
	BRA.w	UseGeneric ; Bronze key
	BRA.w	UseGeneric ; Silver key
	BRA.w	UseGeneric ; Gold key
	BRA.w	UseGeneric ; Thule key
	BRA.w	UseGeneric ; Secret key
	BRA.w	UseMedicine
	BRA.w	UseAgateJewel
	BRA.w	UseGriffinWing
	BRA.w	UseTitaniasMirror
	BRA.w	UseGnomeStone
	BRA.w	UseTopazJewel
	BRA.w	UseBansheePowder
	BRA.w	UseRafaelsStick
	BRA.w	UseMirrorOfAtlas
	BRA.w	UseRubyBrooch
	BRA.w	UseGeneric
	BRA.w	UseKulmsVase
	BRA.w	UseKasansChisel
	BRA.w	UseBookOfKiel
	BRA.w	UseDanegeldWater
	BRA.w	UseMineralBar
	BRA.w	UseMegaBlast

UseRubyBrooch:
	TST.b	Is_in_cave.w
	BNE.b	UseRubyBrooch_Loop
	TST.b	Player_in_first_person_mode.w
	BNE.b	UseRubyBrooch_Loop2
UseRubyBrooch_Loop:
	PRINT 	NotWorkHereStr	
	BRA.b	UseRubyBrooch_Loop3	
UseRubyBrooch_Loop2:
	CLR.b	Steps_since_last_encounter.w
	MOVE.w	#ENCOUNTER_RATE_BROOCH, Encounter_rate.w
	PRINT 	MonstersHardTimeStr
	BSR.w	RemoveSelectedItemFromList
UseRubyBrooch_Loop3:
	RTS

UseBansheePowder:
	TST.b	Player_in_first_person_mode.w
	BNE.b	UseBansheePowder_Loop
	PRINT 	TownUseWarningStr	
	BRA.b	UseBansheePowder_Loop2	
UseBansheePowder_Loop:
	MOVE.b	#FLAG_TRUE, Banshee_powder_active.w
	PRINT 	PowderSpillsStr
	BSR.w	RemoveSelectedItemFromList
UseBansheePowder_Loop2:
	RTS

UseKulmsVase:
	ADDI.w	#10, Player_ac.w	
	CMPI.w	#1500, Player_ac.w	
	BLE.b	UseKulmsVase_Loop	
	MOVE.w	#1500, Player_ac.w	
UseKulmsVase_Loop:
	PRINT 	JarBreaksStr	
	BSR.w	RemoveSelectedItemFromList	
	MOVE.w	#SOUND_ITEM_PICKUP, D0	
	JSR	QueueSoundEffect	
	RTS
	
UseKasansChisel:
	ADDI.w	#10, Player_dex.w	
	CMPI.w	#MAX_PLAYER_DEX, Player_dex.w	
	BLE.b	UseKasansChisel_Loop	
	MOVE.w	#MAX_PLAYER_DEX, Player_dex.w	
UseKasansChisel_Loop:
	PRINT 	HorribleTasteStr	
	BSR.w	RemoveSelectedItemFromList	
	MOVE.w	#SOUND_ITEM_PICKUP, D0	
	JSR	QueueSoundEffect	
	RTS
	
UseBookOfKiel:
	ADDI.w	#10, Player_int.w	
	CMPI.w	#MAX_PLAYER_INT, Player_int.w	
	BLE.b	UseBookOfKiel_Loop	
	MOVE.w	#MAX_PLAYER_INT, Player_int.w	
UseBookOfKiel_Loop:
	PRINT 	ReadDisappearsStr	
	BSR.w	RemoveSelectedItemFromList	
	MOVE.w	#SOUND_ITEM_PICKUP, D0	
	JSR	QueueSoundEffect	
	RTS
	
UseDanegeldWater:
	ADDQ.w	#8, Player_mmp.w	
	CMPI.w	#MAX_PLAYER_MMP, Player_mmp.w	
	BLE.b	UseDanegeldWater_Loop	
	MOVE.w	#MAX_PLAYER_MMP, Player_mmp.w	
UseDanegeldWater_Loop:
	PRINT 	SweetTasteStr	
	JSR	GetRandomNumber	
	ANDI.w	#3, D0	
	BNE.b	UseDanegeldWater_Loop2	
	SUBQ.w	#8, Player_mhp.w	
	BGE.b	UseDanegeldWater_Loop3	
	CLR.w	Player_mhp.w	
UseDanegeldWater_Loop3:
	PRINT 	BitterTasteStr	
UseDanegeldWater_Loop2:
	BSR.w	RemoveSelectedItemFromList	
	MOVE.w	#SOUND_ITEM_PICKUP, D0	
	JSR	QueueSoundEffect	
	RTS

UseMineralBar:
	ADDI.w	#10, Player_str.w	
	CMPI.w	#1500, Player_str.w	
	BLE.b	UseMineralBar_Loop	
	MOVE.w	#1500, Player_str.w	
UseMineralBar_Loop:
	PRINT 	BrokePowerStr	
	BSR.w	RemoveSelectedItemFromList	
	MOVE.w	#SOUND_ITEM_PICKUP, D0	
	JSR	QueueSoundEffect	
	RTS
	
UseMegaBlast:
	ADDI.w	#10, Player_luk.w	
	CMPI.w	#MAX_PLAYER_LUK, Player_luk.w	
	BLE.b	UseMegaBlast_Loop	
	MOVE.w	#MAX_PLAYER_LUK, Player_luk.w	
UseMegaBlast_Loop:
	PRINT 	NoFeelStr	
	BSR.w	RemoveSelectedItemFromList	
	MOVE.w	#SOUND_ITEM_PICKUP, D0	
	JSR	QueueSoundEffect	
	RTS
	
UseRafaelsStick:
	JSR	CheckIfCursed
	BEQ.b	UseRafaelsStick_Loop
	JSR	RemoveCursedEquipment	
	PRINT 	CurseRemovedStr	
	MOVE.w	#SOUND_ITEM_PICKUP, D0	
	JSR	QueueSoundEffect	
	RTS
	
UseRafaelsStick_Loop:
	PRINT 	NothingHappenedStr
	RTS

UseTopazJewel:
	MOVE.w	#30, D1	
	JSR	GetRandomNumber	
	ANDI.w	#$000F, D0	
	ADD.w	D0, D1	
	ADD.w	D1, Player_mp.w	
	BRA.w	UseAgateJewel_Loop	

UseAgateJewel:
	MOVE.w	#10, D1
	JSR	GetRandomNumber
	ANDI.w	#7, D0
	ADD.w	D0, D1
	ADD.w	D1, Player_mp.w
UseAgateJewel_Loop:
	PRINT 	MagicRestoredStr
	MOVE.w	Player_mp.w, D0
	CMP.w	Player_mmp.w, D0
	BLE.b	UseAgateJewel_Loop2
	MOVE.w	Player_mmp.w, Player_mp.w	
	PRINT 	AllMagicRestoredStr	
UseAgateJewel_Loop2:
	BSR.w	RemoveSelectedItemFromList
	MOVE.w	#SOUND_ITEM_PICKUP, D0
	JSR	QueueSoundEffect
	RTS

UseMedicine:
	ADDI.w	#100, Player_hp.w	
	BRA.w	UseHerbs_Loop	

UseHerbs:
	ADDI.w	#40, Player_hp.w
UseHerbs_Loop:
	PRINT 	PartialHitPointsStr
	MOVE.w	Player_hp.w, D0
	CMP.w	Player_mhp.w, D0
	BLE.b	UseHerbs_Loop2
	MOVE.w	Player_mhp.w, Player_hp.w
	PRINT 	AllHitPointsStr
UseHerbs_Loop2:
	BSR.w	RemoveSelectedItemFromList
	MOVE.w	#SOUND_ITEM_PICKUP, D0
	JSR	QueueSoundEffect
	RTS

UseGriffinWing:
	TST.b	Player_in_first_person_mode.w
	BEQ.b	UseItem_NothingHappened1
	TST.b	Is_in_cave.w
	BNE.b	UseItem_NothingHappened1
	BSR.w	RemoveSelectedItemFromList
	MOVE.w	#ITEM_MENU_STATE_WARP_INIT, Item_menu_state.w
UseItem_NothingHappened1:
	PRINT 	NothingHappenedStr
	RTS

UseMirrorOfAtlas:
	PRINT 	WorldMapsStr
	LEA	Map_trigger_flags.w, A0
	MOVE.w	#$FF, D7
UseMirrorOfAtlas_Done:
	MOVE.b	#$FF, (A0)+ ; Fill 255 entries with $FF
	DBF	D7, UseMirrorOfAtlas_Done
	TST.b	Player_in_first_person_mode.w
	BEQ.b	UseMirrorOfAtlas_Loop
	MOVE.b	#FLAG_TRUE, Area_map_revealed.w
	JSR	UpdateAreaVisibility
UseMirrorOfAtlas_Loop:
	BSR.w	RemoveSelectedItemFromList
	RTS

UseTitaniasMirror:
	TST.b	Player_in_first_person_mode.w	
	BEQ.b	UseItem_NothingHappened2	
	TST.b	Is_in_cave.w	
	BNE.b	UseItem_NothingHappened2	
	MOVE.b	#FLAG_TRUE, Area_map_revealed.w	
	JSR	UpdateAreaVisibility	
	PRINT 	GlowingMapStr	
	RTS
	
UseItem_NothingHappened2:
	PRINT 	NothingHappenedStr	
	RTS
	
UseGnomeStone:
	TST.b	Is_in_cave.w
	BEQ.b	UseGnomeStone_Loop
	BSR.w	RemoveSelectedItemFromList
	MOVE.w	#ITEM_MENU_STATE_WARP_EXEC, Item_menu_state.w
	RTS

UseGnomeStone_Loop:
	PRINT 	NothingHappenedStr
	RTS

UsePoisonBalm:
	TST.w	Player_poisoned.w
	BEQ.b	UsePoisonBalm_Loop
	TST.b	Player_greatly_poisoned.w
	BNE.b	UsePoisonBalm_Loop2
	CLR.b	Poison_notified.w
	CLR.w	Player_poisoned.w
	PRINT 	PoisonPurgedStr
	MOVE.w	#SOUND_ITEM_PICKUP, D0
	JSR	QueueSoundEffect
	BRA.b	UseHerbs_Done
UsePoisonBalm_Loop:
	PRINT 	NotPoisonousStr
	BRA.b	UseHerbs_Done
UsePoisonBalm_Loop2:
	PRINT 	PoisonTooStrongStr	
UseHerbs_Done:
	BSR.w	RemoveSelectedItemFromList
	RTS

UseCandle:
	TST.b	Is_in_cave.w
	BEQ.b	UseCandle_BrightPlace
	TST.b	Cave_light_active.w
	BNE.b	UseCandle_BrightPlace
	MOVE.w	#ITEM_MENU_STATE_CAVE_DONE, Item_menu_state.w
	MOVE.w	#$48, Palette_line_1_fade_target.w
	MOVE.w	#$40, Palette_line_2_fade_target.w
	MOVE.b	#6, Fade_in_lines_mask.w
	MOVE.w	#$0800, Cave_light_timer.w
	MOVE.b	#FLAG_TRUE, Cave_light_active.w
	BSR.w	RemoveSelectedItemFromList
	MOVE.w	#SOUND_ENEMY_DEATH, D0
	JSR	QueueSoundEffect
	RTS

UseCandle_BrightPlace:
	BSR.w	RemoveSelectedItemFromList
	PRINT 	BrightPlaceStr
	RTS

UseLantern:
	TST.b	Is_in_cave.w
	BEQ.b	UseLantern_BrightPlace
	TST.b	Cave_light_active.w
	BNE.b	UseLantern_BrightPlace
	MOVE.w	#ITEM_MENU_STATE_CAVE_DONE, Item_menu_state.w
	MOVE.w	#$48, Palette_line_1_fade_target.w
	MOVE.w	#$40, Palette_line_2_fade_target.w
	MOVE.b	#6, Fade_in_lines_mask.w
	CLR.w	Cave_light_timer.w
	MOVE.b	#1, Cave_light_active.w
	BSR.w	RemoveSelectedItemFromList
	MOVE.w	#SOUND_ENEMY_DEATH, D0
	JSR	QueueSoundEffect
	RTS

UseLantern_BrightPlace:
	BSR.w	RemoveSelectedItemFromList	
	PRINT 	BrightPlaceStr	
	RTS
	
UseAlarmClock:
	MOVE.w	#SOUND_ALARM_CLOCK, D0
	JSR	QueueSoundEffect
	TST.b	Keltwick_girl_sleeping.w
	BEQ.w	AlarmClockCheck_Return
	MOVE.w	Current_town.w, D0
	CMPI.w	#TOWN_KELTWICK, D0
	BNE.w	AlarmClockCheck_Return
	MOVE.w	Gameplay_state.w, D0
	CMPI.w	#GAMEPLAY_STATE_SECOND_FLOOR_ACTIVE, D0
	BNE.w	AlarmClockCheck_Return
	MOVE.w	Current_town_room.w, D0
	CMPI.w	#$0034, D0 ; The upper floor of Keltwick's inn
	BNE.w	AlarmClockCheck_Return
	CLR.w	D0
	CLR.w	D1
	CLR.w	D2
	MOVEA.l	Player_entity_ptr.w, A6
	LEA	AlarmClockPositionData, A0
	MOVE.w	#3, D7
UseAlarmClock_Done:
	MOVE.w	D1, D0
	ADD.w	D0, D0
	MOVE.w	D0, D2
	ADD.w	D0, D0
	ADD.w	D2, D0
	MOVE.w	(A0,D0.w), D2
	CMP.w	obj_screen_x(A6), D2
	BNE.b	UseAlarmClock_NextNPC
	MOVE.w	$2(A0,D0.w), D2
	CMP.w	obj_screen_y(A6), D2
	BNE.b	UseAlarmClock_NextNPC
	MOVE.w	$4(A0,D0.w), D2
	CMP.w	Player_direction.w, D2
	BEQ.b	AlarmClockCheck_Return_Loop
UseAlarmClock_NextNPC:
	ADDQ.w	#1, D1
	DBF	D7, UseAlarmClock_Done
AlarmClockCheck_Return:
	PRINT 	NoisyStr
	RTS

AlarmClockCheck_Return_Loop:
	MOVE.b	#FLAG_TRUE, Alarm_clock_rang.w
	PRINT 	BrrrnnnggStr
	RTS

; AlarmClockPositionData
; 4 entries x 3 words each: screen_x, screen_y, direction
; Used by the alarm clock item effect to place the ringing clock sprite
; at one of four fixed screen positions depending on context.
;   Entry 0: ($D8, $98) facing direction 0  (right)
;   Entry 1: ($C8, $88) facing direction 6  (down-left)
;   Entry 2: ($E8, $88) facing direction 2  (left)
;   Entry 3: ($D8, $78) facing direction 4  (up)
AlarmClockPositionData:
	dc.w	$D8
	dc.w	$98
	dc.w	$0 
	dc.w	$C8
	dc.w	$88
	dc.w	$6 
	dc.w	$E8
	dc.w	$88
	dc.w	$2
	dc.w	$D8
	dc.w	$78
	dc.w	$4 

