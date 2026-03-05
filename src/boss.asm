; ======================================================================
; src/boss.asm
; Boss battle AI, animation, and reward logic for all boss encounters.
;
; Covers six boss types:
;   Boss 1 (multi-segment serpent), Two-Headed Dragon, Demon Boss,
;   Orbit Boss, Hydra Boss, Ring Guardian
;
; Key responsibilities:
;   - Per-frame tick functions for each boss state machine
;   - Parallax layer scrolling during battle
;   - Sprite animation, collision, and damage processing
;   - VDP drawing: boss portrait, nameplate, health bar, attack graphics
;   - Victory sequence: fade, reward award, dialog, exit flag
;
; Register conventions (used throughout this file):
;   A5 = current object pointer (the boss or body-part object)
;   A6 = secondary object pointer (scratch / child object)
;   obj_tick_fn(A5) = function pointer for the current state;
;                     writing a new address transitions the state machine
;   obj_invuln_timer(A5) = repurposed as a general-purpose countdown
;                          timer in many boss states
; ======================================================================

;==============================================================
; BOSS 1 — VICTORY SEQUENCE
; Handles the death-fall gravity loop, victory pose, palette
; fade, screen-flash, and transition to the reward sequence.
;==============================================================

; Boss1_DeathFall
; Per-frame tick while Boss 1's body segments are falling.
; Applies gravity ($4000/frame) to each of the five body-part
; slots (slots 02–05 plus A5).  When all velocities reach zero
; (segments have landed), transitions to Boss1_VictoryPauseWait.
; Inputs:  A5 = main boss object; Object_slot_02_ptr–05_ptr = body parts
; Outputs: obj_tick_fn(A5) set to Boss1_VictoryPauseWait when done
Boss1_DeathFall:
	CLR.w	D0
	TST.l	obj_vel_y(A5)
	BLE.b	Boss1_DeathFall_Loop
	ADDI.l	#$4000, obj_vel_y(A5)
	MOVE.w	#1, D0
Boss1_DeathFall_Loop:
	MOVEA.l	Object_slot_02_ptr.w, A6
	TST.l	obj_vel_y(A6)
	BLE.b	Boss1_DeathFall_Slot2
	ADDI.l	#$4000, obj_vel_y(A6)
	MOVE.w	#1, D0
Boss1_DeathFall_Slot2:
	MOVEA.l	Object_slot_03_ptr.w, A6
	TST.l	obj_vel_y(A6)
	BLE.b	Boss1_DeathFall_Slot3
	ADDI.l	#$4000, obj_vel_y(A6)
	MOVE.w	#1, D0
Boss1_DeathFall_Slot3:
	MOVEA.l	Object_slot_04_ptr.w, A6
	TST.l	obj_vel_y(A6)
	BLE.b	Boss1_DeathFall_Slot4
	ADDI.l	#$4000, obj_vel_y(A6)
	MOVE.w	#1, D0
Boss1_DeathFall_Slot4:
	MOVEA.l	Object_slot_05_ptr.w, A6
	TST.l	obj_vel_y(A6)
	BLE.b	Boss1_DeathFall_Slot5
	ADDI.l	#$4000, obj_vel_y(A6)
	MOVE.w	#1, D0
Boss1_DeathFall_Slot5:
	TST.w	D0                              ; D0 nonzero = at least one segment still moving
	BNE.b	Boss1_DeathFall_CheckDone
	MOVE.l	#Boss1_VictoryPauseWait, obj_tick_fn(A5) ; all segments landed — begin victory
	CLR.w	Dialog_timer.w                  ; reset general-purpose frame counter
	CLR.w	Dialog_phase.w                  ; reset flash phase counter
	MOVE.b	#BOSS_VICTORY_PAUSE, obj_invuln_timer(A5) ; set initial pause duration
Boss1_DeathFall_CheckDone:
	BSR.w	UpdateSpritePositionAndRender
	RTS

; Boss1_VictoryPauseWait
; Counts down a brief pause after all segments land, then switches
; to the first victory pose and queues the victory fanfare.
Boss1_VictoryPauseWait:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGE.b	Boss1_VictoryPauseWait_Loop
	BSR.w	SetBattleVictoryAnimFrames1
	MOVE.l	#Boss1_VictoryPose1Wait, obj_tick_fn(A5)
	MOVE.b	#BOSS_VICTORY_PAUSE, obj_invuln_timer(A5)
	PlaySound	SOUND_BOSS1_VICTORY
Boss1_VictoryPauseWait_Loop:
	BSR.w	UpdateSpritePositionAndRender
	RTS

; Boss1_VictoryPose1Wait
; Holds the first victory animation pose for BOSS_VICTORY_PAUSE frames,
; then switches to Boss1_VictoryFadeInit to begin the palette fade.
Boss1_VictoryPose1Wait:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGE.b	Boss1_VictoryPose1Wait_Loop
	BSR.w	SetBattleVictoryAnimFrames2
	MOVE.b	#BOSS_VICTORY_PAUSE, obj_invuln_timer(A5)
	MOVE.l	#Boss1_VictoryFadeInit, obj_tick_fn(A5)
Boss1_VictoryPose1Wait_Loop:
	BSR.w	UpdateSpritePositionAndRender
	RTS

; Boss1_VictoryFadeInit
; After a second pause, sets the palette fade target ($0067 = dark blue)
; and enables palette line 1 fade-in (mask bit 1), then waits for
; the fade to complete in Boss1_VictoryFadeWait.
Boss1_VictoryFadeInit:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGE.b	Boss1_VictoryFadeInit_Loop
	MOVE.w	#$0067, Palette_line_1_fade_in_target.w
	MOVE.b	#2, Palette_fade_in_mask.w
	MOVE.l	#Boss1_VictoryFadeWait, obj_tick_fn(A5)
Boss1_VictoryFadeInit_Loop:
	BSR.w	UpdateSpritePositionAndRender
	RTS

; Boss1_VictoryFadeWait
; Spins until Palette_fade_in_mask clears (fade complete), then
; advances to the screen-flash phase and plays the purchase jingle.
Boss1_VictoryFadeWait:
	TST.b	Palette_fade_in_mask.w
	BNE.b	Boss1_VictoryFadeWait_Loop
	MOVE.l	#Boss1_VictoryFlash, obj_tick_fn(A5)
	PlaySound	SOUND_PURCHASE
Boss1_VictoryFadeWait_Loop:
	BSR.w	UpdateSpritePositionAndRender
	RTS

; Boss1_VictoryFlash
; Flashes the dialog plane every 8 frames (timer & 7 == 0) for
; BOSS_VICTORY_FADE_PHASES cycles, then transitions to the reward
; sequence.  Each cycle calls ClearDialogPlane to produce the flash.
Boss1_VictoryFlash:
	ADDQ.w	#1, Dialog_timer.w              ; advance frame counter
	MOVE.w	Dialog_timer.w, D0
	ANDI.w	#7, D0                          ; fire every 8 frames
	BNE.b	BossCommon_SpriteUpdate
	CMPI.w	#BOSS_VICTORY_FADE_PHASES, Dialog_phase.w ; all flash cycles done?
	BLT.b	Boss1_VictoryFlash_Loop
	MOVE.l	#BossCommon_VictoryRewardSequence, obj_tick_fn(A5)
	MOVE.w	#BOSS_VICTORY_DELAY_FRAMES, Dialog_timer.w ; pre-load reward delay
	BRA.b	BossCommon_SpriteUpdate
Boss1_VictoryFlash_Loop:
	BSR.w	ClearDialogPlane                ; clear dialog plane to produce one flash
; BossCommon_SpriteUpdate — shared tail: update position + render, then return
BossCommon_SpriteUpdate:
	BSR.w	UpdateSpritePositionAndRender
	RTS

;==============================================================
; BOSS COMMON — VICTORY / EXIT FLOW
; Shared reward dispatch and dialog wait used by all bosses.
;==============================================================

; BossCommon_VictoryRewardSequence
; Counts down Dialog_timer, then clears scroll data, blocks player
; input, awards XP/kims, displays the victory message, and advances
; to BossCommon_VictoryMessageWait.
BossCommon_VictoryRewardSequence:
	SUBQ.w	#1, Dialog_timer.w
	BGE.b	BossCommon_VictoryRewardSequence_Loop
	JSR	ClearScrollData
	PlaySound	SOUND_ERROR
	MOVE.b	#FLAG_TRUE, Player_input_blocked.w
	BSR.w	AwardBattleRewards
	BSR.w	DisplayBattleVictoryMessage
	MOVE.l	#BossCommon_VictoryMessageWait, obj_tick_fn(A5)
BossCommon_VictoryRewardSequence_Loop:
	RTS

; BossCommon_VictoryMessageWait
; Waits for victory dialog to finish (Script_text_complete), then
; watches for button B or C press to proceed to exit.
BossCommon_VictoryMessageWait:
	TST.b	Script_text_complete.w
	BEQ.b	BossBattle_SetExitFlag_Loop
	CheckButton BUTTON_BIT_C
	BNE.b	BossBattle_SetExitFlag
	CheckButton BUTTON_BIT_B
	BNE.b	BossBattle_SetExitFlag
	RTS

; BossBattle_SetExitFlag
; Sets Boss_battle_exit_flag to FLAG_TRUE to signal the battle
; engine that the boss encounter should end.
BossBattle_SetExitFlag:
	MOVE.b	#FLAG_TRUE, Boss_battle_exit_flag.w
	RTS

; BossBattle_SetExitFlag_Loop
; Drives the script/dialog text engine while waiting for the
; player to confirm the victory message.
BossBattle_SetExitFlag_Loop:
	JSR	ProcessScriptText
	RTS

;==============================================================
; BATTLE PARALLAX / SPRITE SYSTEM
; Drives the four background parallax layers and the Boss 1
; body-segment sprite rendering each frame.
;==============================================================

; UpdateBattleParallaxLayers
; Per-frame tick for the parallax controller object (slot 01).
; Copies the main object's velocity to slots 02–05 at scaled rates:
;   slot 02 = full speed (1x)
;   slot 03 = 75% (velocity - velocity/4)
;   slot 04 = 50% (velocity >> 1)
;   slot 05 = 25% (velocity >> 2)
; If Fade_in_lines_mask or Battle_active_flag is inactive, all
; velocities are zeroed (layers frozen).
; Inputs:  A5 = parallax controller object
;          obj_vel_x/y(A5) = current scroll velocity
UpdateBattleParallaxLayers:
	ADDQ.b	#1, obj_move_counter(A5)
	TST.b	Fade_in_lines_mask.w
	BNE.w	UpdateBattleParallax_ClearSlots
	TST.b	Battle_active_flag.w
	BEQ.w	UpdateBattleParallax_ClearSlots
	MOVE.l	obj_vel_x(A5), D0
	MOVE.l	obj_vel_y(A5), D1
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.l	D0, obj_vel_x(A6)
	MOVE.l	D1, obj_vel_y(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.l	D0, D2
	MOVE.l	D0, D4
	MOVE.l	D1, D3
	MOVE.l	D1, D5
	ASR.l	#2, D4
	ASR.l	#2, D5
	SUB.l	D4, D2
	SUB.l	D5, D3
	MOVE.l	D2, obj_vel_x(A6)
	MOVE.l	D3, obj_vel_y(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	MOVE.l	D0, D2
	MOVE.l	D1, D3
	ASR.l	#1, D2
	ASR.l	#1, D3
	MOVE.l	D2, obj_vel_x(A6)
	MOVE.l	D3, obj_vel_y(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	MOVE.l	D0, D2
	MOVE.l	D1, D3
	ASR.l	#2, D2
	ASR.l	#2, D3
	MOVE.l	D2, obj_vel_x(A6)
	MOVE.l	D3, obj_vel_y(A6)
	BRA.w	UpdateSpritePositionAndRender
UpdateBattleParallax_ClearSlots:                ; battle inactive — freeze all layers
	MOVEA.l	Object_slot_02_ptr.w, A6
	CLR.l	obj_vel_x(A6)
	CLR.l	obj_vel_y(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	CLR.l	obj_vel_x(A6)
	CLR.l	obj_vel_y(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	CLR.l	obj_vel_x(A6)
	CLR.l	obj_vel_y(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	CLR.l	obj_vel_x(A6)
	CLR.l	obj_vel_y(A6)
	BRA.w	BossBody_SpriteUpdate

; UpdateSpritePositionAndRender
; Integrates velocity into world position for A5, clamps the Y
; coordinate to BATTLE_ARENA_EDGE (resetting velocity if exceeded),
; then falls through to BossBody_SpriteUpdate.
; Inputs:  A5 = object to move
UpdateSpritePositionAndRender:
	MOVE.l	obj_vel_x(A5), D0
	MOVE.l	obj_vel_y(A5), D1
	ADD.l	D0, obj_world_x(A5)
	ADD.l	D1, obj_world_y(A5)
	MOVE.w	obj_world_y(A5), D0
	CMPI.w	#BATTLE_ARENA_EDGE, D0          ; has the segment fallen off the bottom?
	BLT.b	BossBody_SpriteUpdate
	MOVE.w	#$00A8, obj_world_y(A5)         ; clamp to arena floor (168 pixels)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
; BossBody_SpriteUpdate
; Copies world position to all five body-part sprite slots (slot 01
; plus slots at obj_next_offset chain) using EnemySpriteFrameDataA_10
; offsets, selects the tile index from EnemySpriteFrameDataA_12 via
; the animated move counter, then submits A5 to the sprite display
; list and updates the attack graphic overlay.
; Inputs:  A5 = main body object
BossBody_SpriteUpdate:
	MOVEA.l	Object_slot_01_ptr.w, A6
	LEA	EnemySpriteFrameDataA_12, A0
	CLR.w	D0
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0070, D0                      ; bits 6–4 select anim frame (0–7, steps of $10)
	ASR.w	#3, D0                          ; shift right 3 → word index into frame table
	MOVE.w	(A0,D0.w), obj_tile_index(A6)  ; set tile for main display slot
	LEA	EnemySpriteFrameDataA_10, A0       ; X/Y offset table for body sub-sprites
	MOVE.w	#4, D7                          ; loop 5 sub-sprites (DBF: 4 down to 0)
BossBody_SpriteUpdate_Done:
	MOVE.w	obj_world_x(A5), D0
	ADD.w	(A0)+, D0                       ; apply X offset for this sub-sprite
	MOVE.w	D0, obj_screen_x(A6)
	MOVE.w	obj_world_y(A5), D0
	ADD.w	(A0)+, D0                       ; apply Y offset for this sub-sprite
	MOVE.w	D0, obj_screen_y(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0        ; follow linked-list chain to next sub-object
	LEA	(A6,D0.w), A6
	DBF	D7, BossBody_SpriteUpdate_Done
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	BSR.w	UpdateBossAttackGraphic
	RTS

;==============================================================
; BOSS 1 — BODY SEGMENT TICKS
; Per-frame update functions for each of the five Boss 1 body
; segments: neck, upper body, mid body, tail, and the shared
; next-slot initialiser.
;==============================================================

; Boss1_NeckTick
; Checks player collision (deals damage), integrates velocity,
; clamps Y, then positions screen coordinates for the neck's
; two sub-sprites via EnemySpriteFrameDataA_11 offsets.
Boss1_NeckTick:
	BSR.w	CheckEntityPlayerCollisionAndDamage
Boss1_NeckTickNoCollision:
	MOVE.l	obj_vel_x(A5), D0
	MOVE.l	obj_vel_y(A5), D1
	ADD.l	D0, obj_world_x(A5)
	ADD.l	D1, obj_world_y(A5)
	BSR.w	ClampYPosition
	LEA	EnemySpriteFrameDataA_11, A0
	LEA	(A5), A6
	MOVE.w	#1, D7
Boss1_NeckTickNoCollision_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	MOVE.w	obj_world_x(A5), D0
	ADD.w	(A0)+, D0
	MOVE.w	D0, obj_screen_x(A6)
	MOVE.w	obj_world_y(A5), D0
	ADD.w	(A0)+, D0
	MOVE.w	D0, obj_screen_y(A6)
	DBF	D7, Boss1_NeckTickNoCollision_Done
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS

Boss1_UpperBodyTick:
	MOVE.l	obj_vel_x(A5), D0
	MOVE.l	obj_vel_y(A5), D1
	ADD.l	D0, obj_world_x(A5)
	ADD.l	D1, obj_world_y(A5)
	BSR.w	ClampYPosition
	MOVEA.l	Enemy_list_ptr.w, A6
	TST.w	obj_hp(A6)                      ; skip collision if boss is already dead
	BLE.b	Boss1_UpperBodyTick_Loop
	BSR.w	CheckEntityPlayerCollisionAndDamage
Boss1_UpperBodyTick_Loop:
	LEA	EnemySpriteFrameDataA_0D, A0
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.w	obj_world_x(A5), D0
	ADD.w	(A0)+, D0
	MOVE.w	D0, obj_screen_x(A6)
	MOVE.w	obj_world_y(A5), D0
	ADD.w	(A0)+, D0
	MOVE.w	D0, obj_screen_y(A6)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS

; Boss1_MidBodyTick
; Same as Boss1_UpperBodyTick but uses EnemySpriteFrameDataA_0E offsets.
Boss1_MidBodyTick:
	MOVE.l	obj_vel_x(A5), D0
	MOVE.l	obj_vel_y(A5), D1
	ADD.l	D0, obj_world_x(A5)
	ADD.l	D1, obj_world_y(A5)
	BSR.w	ClampYPosition
	MOVEA.l	Enemy_list_ptr.w, A6
	TST.w	obj_hp(A6)                      ; skip collision if boss is already dead
	BLE.b	Boss1_MidBodyTick_Loop
	BSR.w	CheckEntityPlayerCollisionAndDamage
Boss1_MidBodyTick_Loop:
	LEA	EnemySpriteFrameDataA_0E, A0
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.w	obj_world_x(A5), D0
	ADD.w	(A0)+, D0
	MOVE.w	D0, obj_screen_x(A6)
	MOVE.w	obj_world_y(A5), D0
	ADD.w	(A0)+, D0
	MOVE.w	D0, obj_screen_y(A6)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS

; Boss1_TailTick
; Tail segment: no collision check, uses EnemySpriteFrameDataA_0F.
; Falls through to BossCommon_RenderOnly for the final sprite submit.
Boss1_TailTick:
	MOVE.l	obj_vel_x(A5), D0
	MOVE.l	obj_vel_y(A5), D1
	ADD.l	D0, obj_world_x(A5)
	ADD.l	D1, obj_world_y(A5)
	BSR.w	ClampYPosition
	LEA	EnemySpriteFrameDataA_0F, A0
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.w	obj_world_x(A5), D0
	ADD.w	(A0)+, D0
	MOVE.w	D0, obj_screen_x(A6)
	MOVE.w	obj_world_y(A5), D0
	ADD.w	(A0)+, D0
	MOVE.w	D0, obj_screen_y(A6)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
BossCommon_RenderOnly:                          ; shared tail: just submit and return
	JSR	AddSpriteToDisplayList
	RTS

; InitNextSpriteSlot
; Advances A6 to the next linked sub-object (via obj_next_offset),
; marks it active (bit 7), sets palette 1 sprite flags, and clears
; the flip/rotation bits (7, 3, 4) on obj_sprite_flags.
; Inputs:  A6 = current sub-object pointer
; Outputs: A6 = next sub-object pointer, initialised
InitNextSpriteSlot:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
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
	MOVE.l	#BossCommon_RenderOnly, obj_tick_fn(A6)
	RTS

;==============================================================
; DEAD CODE + PLAYER SCREEN EDGE CHECK
;==============================================================

; InitSpriteSlot_DeadCode
; Unreferenced dead code — clears all 32 sub-objects in the enemy
; linked list.  Not called anywhere in the ROM.
InitSpriteSlot_DeadCode:				; unreferenced dead code
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#$001F, D7
InitNextSpriteSlot_Done:
	BCLR	#7, (A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	$0(A6,D0.w), A6
	DBF	D7, InitNextSpriteSlot_Done
	RTS

; CheckPlayerLeftOfScreen
; Returns D0 = $FFFF if the player's world X > $0050 (right of left
; edge), or D0 = 0 if the player is at or left of the threshold.
; Inputs:  Player_entity_ptr = pointer to player object
; Outputs: D0 = $FFFF (player is right of edge) or 0 (at/left of edge)
CheckPlayerLeftOfScreen:
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), D0
	CMPI.w	#$0050, D0                      ; $50 = left-edge threshold (80 pixels)
	BLE.b	CheckPlayerLeftOfScreen_Loop
	MOVE.w	#$FFFF, D0                      ; player is right of edge
	RTS

CheckPlayerLeftOfScreen_Loop:
	CLR.w	D0                              ; player is at or left of edge
	RTS

;==============================================================
; TWO-HEADED DRAGON — INIT
; Difficulty-scaled HP/damage setup followed by common init
; for sprites, AI state, positions, and fireball objects.
;==============================================================

; InitTwoHeadedDragon_Normal / _Hard / _VeryHard
; Sets HP and max-damage values for the dragon body (Enemy_list_ptr)
; and the two head objects (slots 04, 05), then falls through to
; InitTwoHeadedDragon_Common for shared initialisation.
InitTwoHeadedDragon_Normal:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#BOSS_DMG_DRAGON_NORMAL, obj_max_hp(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	MOVE.w	#BOSS_DMG_DRAGON_NORMAL, obj_max_hp(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	MOVE.w	#BOSS_DMG_DRAGON_NORMAL, obj_max_hp(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.w	#BOSS_HP_DRAGON_NORMAL, obj_hp(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.w	#BOSS_HP_DRAGON_NORMAL, obj_hp(A6)
	BRA.w	InitTwoHeadedDragon_Common
InitTwoHeadedDragon_Hard:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#BOSS_DMG_DRAGON_HARD, obj_max_hp(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	MOVE.w	#BOSS_DMG_DRAGON_HARD, obj_max_hp(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	MOVE.w	#BOSS_DMG_DRAGON_HARD, obj_max_hp(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.w	#BOSS_HP_DRAGON_HARD, obj_hp(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.w	#BOSS_HP_DRAGON_HARD, obj_hp(A6)
	BRA.w	InitTwoHeadedDragon_Common
InitTwoHeadedDragon_VeryHard:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#BOSS_DMG_DRAGON_VERYHARD, obj_max_hp(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	MOVE.w	#BOSS_DMG_DRAGON_VERYHARD, obj_max_hp(A6)
	MOVEA.l	Object_slot_04_ptr.w, A6
	MOVE.w	#BOSS_DMG_DRAGON_VERYHARD, obj_max_hp(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.w	#BOSS_HP_DRAGON_VERYHARD, obj_hp(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.w	#BOSS_HP_DRAGON_VERYHARD, obj_hp(A6)

; InitTwoHeadedDragon_Common
; Shared init: clears defeat/death flags, loads sprite layout data for
; the body (BossSpriteLayoutData_A) and body-part chain
; (BossSpriteLayoutData_C), initialises both head objects (slots 02/03)
; with their head tick functions, and sets up fireball child objects
; (slots 04/05).
InitTwoHeadedDragon_Common:
	CLR.b	Boss_defeated_flag.w
	CLR.b	Boss_death_anim_done.w
	MOVEA.l	Enemy_list_ptr.w, A6
	CLR.b	obj_move_counter(A6)
	CLR.w	obj_attack_timer(A6)
	CLR.w	obj_knockback_timer(A6)
	LEA	BossSpriteLayoutData_A, A0
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
	MOVE.w	#$00D1, obj_world_x(A6)
	MOVE.w	#$007D, obj_world_y(A6)
	MOVE.l	#TwoHeadedDragon_MainTick, obj_tick_fn(A6)
	MOVE.w	#1, D7
InitTwoHeadedDragon_Common_Done:
	BSR.w	InitNextSpriteSlot
	DBF	D7, InitTwoHeadedDragon_Common_Done
	MOVEA.l	Object_slot_01_ptr.w, A6
	CLR.b	obj_move_counter(A6)
	CLR.w	obj_knockback_timer(A6)
	LEA	BossSpriteLayoutData_C, A0
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
	MOVE.w	#$00EC, obj_world_x(A6)
	MOVE.w	#$0087, obj_world_y(A6)
	MOVE.l	#TwoHeadedDragon_BodyTick, obj_tick_fn(A6)
	MOVE.w	#0, D7
InitTwoHeadedDragon_BodySlotLoop:
	BSR.w	InitNextSpriteSlot
	DBF	D7, InitTwoHeadedDragon_BodySlotLoop
	MOVEA.l	Object_slot_02_ptr.w, A6
	BSET.b	#7, (A6)
	CLR.b	obj_move_counter(A6)
	CLR.w	obj_knockback_timer(A6)
	LEA	EnemySpriteLayoutA_Frame0, A0
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	#SOUND_LEVEL_UP, obj_hitbox_x_neg(A6)
	MOVE.b	#8, obj_hitbox_x_pos(A6)
	MOVE.b	#SOUND_LEVEL_UP, obj_hitbox_y_neg(A6)
	MOVE.b	#$0C, obj_hitbox_y_pos(A6)
	MOVE.b	(A0)+, obj_sprite_size(A6)
	CLR.w	D0
	MOVE.b	(A0)+, D0
	MOVE.w	D0, obj_sort_key(A6)
	MOVE.w	(A0)+, obj_tile_index(A6)
	LEA	EnemySpritePositionA_Frame0, A1
	MOVE.w	(A1)+, obj_world_x(A6)
	MOVE.w	(A1), obj_world_y(A6)
	MOVE.l	#TwoHeadedDragon_HeadTickA, obj_tick_fn(A6)
	MOVE.w	#2, D7
InitTwoHeadedDragon_HeadASlotLoop:
	BSR.w	InitNextSpriteSlot
	DBF	D7, InitTwoHeadedDragon_HeadASlotLoop
	MOVEA.l	Object_slot_03_ptr.w, A6
	BSET.b	#7, (A6)
	CLR.b	obj_move_counter(A6)
	CLR.w	obj_knockback_timer(A6)
	LEA	EnemySpriteLayoutB_Frame0, A0
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	(A0)+, obj_sprite_size(A6)
	CLR.w	D0
	MOVE.b	(A0)+, D0
	MOVE.w	D0, obj_sort_key(A6)
	MOVE.w	(A0)+, obj_tile_index(A6)
	LEA	EnemySpritePositionB_Frame0, A1
	MOVE.w	(A1)+, obj_world_x(A6)
	MOVE.w	(A1), obj_world_y(A6)
	MOVE.l	#TwoHeadedDragon_HeadTickB, obj_tick_fn(A6)
	MOVE.w	#2, D7
InitTwoHeadedDragon_HeadBSlotLoop:
	BSR.w	InitNextSpriteSlot
	DBF	D7, InitTwoHeadedDragon_HeadBSlotLoop
	MOVEA.l	Object_slot_04_ptr.w, A6
	BSET.b	#7, (A6)
	MOVE.b	#$F8, obj_hitbox_x_neg(A6)
	MOVE.b	#8, obj_hitbox_x_pos(A6)
	MOVE.b	#$EC, obj_hitbox_y_neg(A6)
	MOVE.b	#0, obj_hitbox_y_pos(A6)
	CLR.b	obj_move_counter(A6)
	CLR.w	obj_knockback_timer(A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_2x2, obj_sprite_size(A6)
	MOVE.l	#TwoHeadedDragon_FireballTickA, obj_tick_fn(A6)
	MOVEA.l	Object_slot_05_ptr.w, A6
	BSET.b	#7, (A6)
	MOVE.b	#$F8, obj_hitbox_x_neg(A6)
	MOVE.b	#8, obj_hitbox_x_pos(A6)
	MOVE.b	#$EC, obj_hitbox_y_neg(A6)
	MOVE.b	#0, obj_hitbox_y_pos(A6)
	CLR.b	obj_move_counter(A6)
	CLR.w	obj_knockback_timer(A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_2x2, obj_sprite_size(A6)
	MOVE.l	#TwoHeadedDragon_FireballTickB, obj_tick_fn(A6)
	BSR.w	DrawBossNameplate
	RTS

;==============================================================
; TWO-HEADED DRAGON — FIREBALL TICKS
; Per-frame update for the two fireball projectile objects
; (slots 04 and 05), one per dragon head.
;==============================================================

; TwoHeadedDragon_FireballTickA / _FireballTickB
; Animate and move a fireball from a given dragon head (slot 02 or 03).
; While the head is busy, the fireball tracks the head's mouth position.
; When fired, it travels left and checks for off-screen exit.
; Collision with the player triggers a knockback/flash sequence.
TwoHeadedDragon_FireballTickA:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVEA.l	Object_slot_02_ptr.w, A6
	BRA.w	TwoHeadedDragon_FireballTickB_Loop
TwoHeadedDragon_FireballTickB:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVEA.l	Object_slot_03_ptr.w, A6
TwoHeadedDragon_FireballTickB_Loop:
	TST.b	obj_npc_busy_flag(A6)
	BNE.b	TwoHeadedDragon_FireballTickB_ActiveBranch
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0038, D0
	MOVE.b	#SPRITE_SIZE_2x2, obj_sprite_size(A5)
	ASR.w	#2, D0
	LEA	BossSpriteLayoutData_E, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	MOVE.w	obj_screen_x(A6), obj_world_x(A5)
	MOVE.w	obj_screen_y(A6), obj_world_y(A5)
	MOVE.w	obj_sort_key(A6), D0
	SUBQ.w	#1, D0
	MOVE.w	D0, obj_sort_key(A5)
	BRA.w	BossFireball_RenderDone
TwoHeadedDragon_FireballTickB_ActiveBranch:
	TST.b	obj_hit_flag(A5)
	BEQ.b	TwoHeadedDragon_FireballTickB_Flying
	TST.w	obj_knockback_timer(A5)
	BEQ.b	TwoHeadedDragon_FireballTickB_InitKnockback
	SUBQ.w	#1, obj_knockback_timer(A5)
	BLE.b	TwoHeadedDragon_FireballTickB_KnockbackDone
	MOVE.w	obj_knockback_timer(A5), D0
	CMPI.b	#$0A, D0
	BGE.w	BossFireball_RenderDone
	MOVE.w	#VRAM_TILE_DRAGON_FIREBALL_A, obj_tile_index(A5)
	BRA.w	BossFireball_RenderDone
TwoHeadedDragon_FireballTickB_KnockbackDone:
	CLR.w	obj_knockback_timer(A5)
	CLR.b	obj_hit_flag(A5)
	CLR.b	obj_move_counter(A5)
	CLR.b	obj_npc_busy_flag(A6)
	BRA.b	BossFireball_RenderDone
TwoHeadedDragon_FireballTickB_InitKnockback:
	CLR.l	obj_vel_x(A5)
	MOVE.w	#VRAM_TILE_DRAGON_FIREBALL_B, obj_tile_index(A5)
	MOVE.w	#$0014, obj_knockback_timer(A5)
	BRA.b	BossFireball_RenderDone
TwoHeadedDragon_FireballTickB_Flying:
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#8, D0                          ; alternate between two tile frames every 8 ticks
	ASR.w	#2, D0
	LEA	BossSpriteLayoutData_F, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.l	obj_vel_x(A5), D0
	ADD.l	D0, obj_world_x(A5)
	CMPI.w	#PROJ_OFFSCREEN_X_LEFT, obj_world_x(A5) ; gone off the left edge?
	BGE.b	TwoHeadedDragon_FireballTickB_OffscreenCheck
	CLR.b	obj_npc_busy_flag(A6)           ; deactivate fireball on head
	CLR.b	obj_move_counter(A5)
TwoHeadedDragon_FireballTickB_OffscreenCheck:
	MOVE.w	#SORT_KEY_BOSS_PROJ, obj_sort_key(A5)
BossFireball_RenderDone:
	BSR.w	CheckEntityPlayerCollisionAndDamage
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS

;==============================================================
; TWO-HEADED DRAGON — MAIN / BODY / HEAD TICKS
; State machine for the dragon body, individual head AI, and
; the shared dead-head display tick.
;==============================================================

; TwoHeadedDragon_MainTick
; Per-frame body tick. Animates the body sprite from
; BossSpriteLayoutData_B, positions the two neck sub-sprites,
; submits the body to the display list, drives the attack flash,
; and checks player contact damage (range $00C8).
; Switches to death/victory sequence when Boss_defeated_flag is set.
TwoHeadedDragon_MainTick:
	TST.b	Boss_defeated_flag.w
	BEQ.b	TwoHeadedDragon_MainTick_Loop
	TST.b	Boss_death_anim_done.w
	BNE.w	TwoHeadedDragon_MainTick_DeathTransition
TwoHeadedDragon_MainTick_Loop:
	LEA	BossSpriteLayoutData_B, A0
	BSR.w	AnimateSpriteFromTable
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.w	obj_world_x(A5), D0
	ADDI.w	#$FFF8, D0
	MOVE.w	D0, obj_screen_x(A6)
	MOVE.w	obj_world_y(A5), D0
	ADDI.w	#$FFE8, D0
	MOVE.w	D0, obj_screen_y(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	MOVE.w	obj_world_x(A5), D0
	ADDQ.w	#8, D0
	MOVE.w	D0, obj_screen_x(A6)
	MOVE.w	obj_world_y(A5), D0
	ADDI.w	#$FFE8, D0
	MOVE.w	D0, obj_screen_y(A6)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	BSR.w	AnimateBossAttackFlash
	MOVE.w	#$00C8, D1
	BSR.w	CheckPlayerDamageAndKnockback
	RTS

; TwoHeadedDragon_MainTick_DeathTransition (death transition)
; Entered once Boss_defeated_flag is set and Boss_death_anim_done is clear.
; Freezes all body/head/wing objects on their last frame, fires the
; victory event, resets dialog counters, and hands off to
; TwoHeadedDragon_DeathDelayTick via obj_tick_fn.
TwoHeadedDragon_MainTick_DeathTransition:
	MOVE.w	#$00B6, Palette_line_1_index.w
	MOVE.w	#$0064, obj_knockback_timer(A5)
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.l	#TwoHeadedDragon_DeathDelayTick, obj_tick_fn(A6)
	MOVEA.l	Object_slot_01_ptr.w, A6
	MOVE.l	#BossCommon_RenderOnly, obj_tick_fn(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.l	#BossCommon_RenderOnly, obj_tick_fn(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.l	#BossCommon_RenderOnly, obj_tick_fn(A6)
	BSR.w	ProcessBattleVictoryEvent
	CLR.w	Dialog_timer.w
	CLR.w	Dialog_phase.w
	PlaySound	SOUND_DOOR_OPEN
	JSR	LoadPalettesFromTable
	RTS

; TwoHeadedDragon_DeathDelayTick
; Counts down obj_knockback_timer then switches to the fadeout/flash
; victory phase and plays the purchase jingle.
TwoHeadedDragon_DeathDelayTick:
	SUBQ.w	#1, obj_knockback_timer(A5)
	BGT.b	TwoHeadedDragon_DeathDelayTick_Loop
	MOVE.l	#TwoHeadedDragon_VictoryFadeoutTick, obj_tick_fn(A5)
	PlaySound	SOUND_PURCHASE
TwoHeadedDragon_DeathDelayTick_Loop:
	JSR	AddSpriteToDisplayList
	RTS

; TwoHeadedDragon_VictoryFadeoutTick
; Screen-flash victory phase — identical logic to Boss1_VictoryFlash:
; clears the dialog plane every 8 frames for BOSS_VICTORY_FADE_PHASES
; cycles then transitions to BossCommon_VictoryRewardSequence.
TwoHeadedDragon_VictoryFadeoutTick:
	ADDQ.w	#1, Dialog_timer.w
	MOVE.w	Dialog_timer.w, D0
	ANDI.w	#7, D0
	BNE.b	TwoHeadedDragon_SpriteUpdate
	CMPI.w	#BOSS_VICTORY_FADE_PHASES, Dialog_phase.w
	BLT.b	TwoHeadedDragon_VictoryFadeoutTick_Loop
	MOVE.l	#BossCommon_VictoryRewardSequence, obj_tick_fn(A5)
	BRA.b	TwoHeadedDragon_SpriteUpdate
TwoHeadedDragon_VictoryFadeoutTick_Loop:
	BSR.w	ClearDialogPlane
TwoHeadedDragon_SpriteUpdate:
	JSR	AddSpriteToDisplayList
	RTS

; TwoHeadedDragon_BodyTick
; Animates the dragon's mid-body segment from BossSpriteLayoutData_D,
; positions the single neck sub-sprite, and submits to the display list.
TwoHeadedDragon_BodyTick:
	LEA	BossSpriteLayoutData_D, A0
	BSR.w	AnimateSpriteFromTable
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.w	obj_world_x(A5), D0
	ADDQ.w	#4, D0
	MOVE.w	D0, obj_screen_x(A6)
	MOVE.w	obj_world_y(A5), D0
	ADDI.w	#$FFE8, D0
	MOVE.w	D0, obj_screen_y(A6)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS

; TwoHeadedDragon_HeadTickA / _HeadTickB
; Per-frame AI for each dragon head.  When battle is active:
;   - Counts down knockback timer and flashes palette during stun.
;   - On obj_hit_flag: subtracts player strength from head HP.
;     If HP goes negative, transitions to TwoHeadedDragon_DeadHeadTick
;     and loads the dead-head sprite layout (frame 3 of EnemySpriteLayoutPtrsA/B).
;   - Otherwise falls through to DragonHeadA/B_IdleTick for normal AI.
; When battle is not active, runs BossTick_Anim_A/B instead.
TwoHeadedDragon_HeadTickA:
	TST.b	Fade_in_lines_mask.w
	BNE.w	BossTick_Anim_A
	TST.b	Battle_active_flag.w
	BEQ.w	BossTick_Anim_A
	TST.w	obj_knockback_timer(A5)
	BLE.b	TwoHeadedDragon_HeadTickA_Loop
	SUBQ.w	#1, obj_knockback_timer(A5)
	BSR.w	UpdateEncounterPalette
	BRA.w	DragonHeadA_IdleTick
TwoHeadedDragon_HeadTickA_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.w	DragonHeadA_IdleTick
	MOVE.w	#PALETTE_IDX_BOSS_FLASH_A, Palette_line_1_index.w
	JSR	LoadPalettesFromTable
	MOVE.w	Player_str.w, D0
	SUB.w	D0, obj_hp(A5)
	BCC.b	TwoHeadedDragon_HeadTickA_SetHitStun
	BSR.w	UpdateEncounterPalette
	MOVE.l	#TwoHeadedDragon_DeadHeadTick, obj_tick_fn(A5)
	LEA	EnemySpriteLayoutPtrsA, A0
	LEA	EnemySpritePositionPtrsA, A1
	MOVEA.l	$C(A0), A0
	MOVEA.l	$C(A1), A1
	LEA	(A5), A6
	MOVE.w	#3, D7
TwoHeadedDragon_HeadTickA_Loop_Done:
	MOVE.b	(A0)+, obj_sprite_size(A6)
	CLR.w	D0
	MOVE.b	(A0)+, D0
	MOVE.w	D0, obj_sort_key(A6)
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVE.w	(A1)+, obj_world_x(A6)
	MOVE.w	(A1)+, obj_world_y(A6)
	MOVE.w	obj_world_x(A6), obj_screen_x(A6)
	MOVE.w	obj_world_y(A6), obj_screen_y(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, TwoHeadedDragon_HeadTickA_Loop_Done
	MOVEA.l	Object_slot_04_ptr.w, A6
	BCLR.b	#7, (A6)                        ; deactivate fireball A when head A dies
	MOVE.w	#$012C, obj_knockback_timer(A5) ; $12C = 300 frame death delay
	MOVE.b	#FLAG_TRUE, Boss_defeated_flag.w
	RTS

TwoHeadedDragon_HeadTickA_SetHitStun:
	MOVE.w	#BOSS_HIT_STUN_FRAMES, obj_knockback_timer(A5)

; DragonHeadA_IdleTick
; Normal head-A idle behaviour: clears hit flag, and randomly (1-in-8
; chance per frame) fires a fireball by marking the head busy and
; launching fireball object slot 04 toward the player.
DragonHeadA_IdleTick:
	CLR.b	obj_hit_flag(A5)
	TST.b	obj_npc_busy_flag(A5)
	BNE.b	DragonHeadA_IdleTick_Loop
	MOVEA.l	Object_slot_04_ptr.w, A6
	MOVE.w	obj_tile_index(A6), D0
	CMPI.w	#DRAGON_HEAD_IDLE_TILE, D0
	BNE.b	BossTick_Anim_A
	JSR	GetRandomNumber
	ANDI.w	#7, D0
	BNE.b	BossTick_Anim_A
	MOVE.b	#FLAG_TRUE, obj_npc_busy_flag(A5)
	MOVE.b	#SPRITE_SIZE_3x3, obj_sprite_size(A6)
	MOVE.w	#VRAM_TILE_DRAGON_HEAD, obj_tile_index(A6)
	MOVE.w	#$00AA, obj_world_x(A6)
	MOVE.w	#$0080, obj_world_y(A6)
	MOVE.l	#$FFFD8000, obj_vel_x(A6)
	CLR.b	obj_hit_flag(A6)
DragonHeadA_IdleTick_Loop:
	MOVE.w	#8, D0                          ; frame index offset 8 = open-mouth sub-frame
	BRA.b	BossTick_Anim_A_Loop

; BossTick_Anim_A
; Selects animation frame for head A from EnemySpriteLayoutPtrsA /
; EnemySpritePositionPtrsA based on bit 4 of obj_move_counter (toggles
; every 16 frames), then copies sprite data to the 4 sub-object chain.
BossTick_Anim_A:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0010, D0
	ASR.w	#2, D0
BossTick_Anim_A_Loop:
	LEA	EnemySpriteLayoutPtrsA, A0
	LEA	EnemySpritePositionPtrsA, A1
	MOVEA.l	(A0,D0.w), A0
	MOVEA.l	(A1,D0.w), A1
	LEA	(A5), A6
	MOVE.w	#3, D7
BossTick_Anim_A_Loop_Done:
	MOVE.b	(A0)+, obj_sprite_size(A6)
	CLR.w	D0
	MOVE.b	(A0)+, D0
	MOVE.w	D0, obj_sort_key(A6)
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVE.w	(A1)+, obj_world_x(A6)
	MOVE.w	(A1)+, obj_world_y(A6)
	MOVE.w	obj_world_x(A6), obj_screen_x(A6)
	MOVE.w	obj_world_y(A6), obj_screen_y(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, BossTick_Anim_A_Loop_Done
	JSR	AddSpriteToDisplayList
	RTS

; TwoHeadedDragon_DeadHeadTick
; Tick for a defeated head — just re-submits the frozen sprite.
TwoHeadedDragon_DeadHeadTick:
	JSR	AddSpriteToDisplayList
	RTS

; TwoHeadedDragon_HeadTickB
; Identical to TwoHeadedDragon_HeadTickA but handles the second head
; (slot 03 / fireball slot 05).  Uses EnemySpriteLayoutPtrsB and
; BossTick_Anim_B for its animations.
TwoHeadedDragon_HeadTickB:
	TST.b	Fade_in_lines_mask.w
	BNE.w	BossTick_Anim_B
	TST.b	Battle_active_flag.w
	BEQ.w	BossTick_Anim_B
	TST.w	obj_knockback_timer(A5)
	BLE.b	TwoHeadedDragon_HeadTickB_Loop
	SUBQ.w	#1, obj_knockback_timer(A5)
	BSR.w	UpdateEncounterPalette
	BRA.w	DragonHeadB_IdleTick
TwoHeadedDragon_HeadTickB_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.w	DragonHeadB_IdleTick
	MOVE.w	#PALETTE_IDX_BOSS_FLASH_A, Palette_line_1_index.w
	JSR	LoadPalettesFromTable
	MOVE.w	Player_str.w, D0
	SUB.w	D0, obj_hp(A5)
	BCC.w	TwoHeadedDragon_HeadTickB_SetHitStun
	MOVE.l	#TwoHeadedDragon_DeadHeadTick, obj_tick_fn(A5)
	LEA	EnemySpriteLayoutPtrsB, A0
	LEA	EnemySpritePositionPtrsB, A1
	MOVEA.l	$C(A0), A0
	MOVEA.l	$C(A1), A1
	LEA	(A5), A6
	MOVE.w	#3, D7
TwoHeadedDragon_HeadTickB_Loop_Done:
	MOVE.b	(A0)+, obj_sprite_size(A6)
	CLR.w	D0
	MOVE.b	(A0)+, D0
	MOVE.w	D0, obj_sort_key(A6)
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVE.w	(A1)+, obj_world_x(A6)
	MOVE.w	(A1)+, obj_world_y(A6)
	MOVE.w	obj_world_x(A6), obj_screen_x(A6)
	MOVE.w	obj_world_y(A6), obj_screen_y(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, TwoHeadedDragon_HeadTickB_Loop_Done
	MOVEA.l	Object_slot_05_ptr.w, A6
	BCLR.b	#7, (A6)                        ; deactivate fireball B when head B dies
	MOVE.b	#FLAG_TRUE, Boss_death_anim_done.w
	RTS

TwoHeadedDragon_HeadTickB_SetHitStun:
	MOVE.w	#BOSS_HIT_STUN_FRAMES, obj_knockback_timer(A5)

; DragonHeadB_IdleTick
; Normal head-B idle: 1-in-32 chance per frame to fire fireball B
; (slot 05) at the player.
DragonHeadB_IdleTick:
	CLR.b	obj_hit_flag(A5)
	TST.b	obj_npc_busy_flag(A5)
	BNE.w	DragonHeadB_IdleTick_Loop
	MOVEA.l	Object_slot_05_ptr.w, A6
	MOVE.w	obj_tile_index(A6), D0
	CMPI.w	#DRAGON_HEAD_IDLE_TILE, D0
	BNE.b	BossTick_Anim_B
	JSR	GetRandomNumber
	ANDI.w	#$001F, D0
	BNE.b	BossTick_Anim_B
	MOVE.b	#FLAG_TRUE, obj_npc_busy_flag(A5)
	MOVE.b	#SPRITE_SIZE_3x3, obj_sprite_size(A6)
	MOVE.w	#VRAM_TILE_DRAGON_HEAD, obj_tile_index(A6)
	MOVE.w	#$00E2, obj_world_x(A6)
	MOVE.w	#SOUND_PLAYER_HIT, obj_world_y(A6)
	MOVE.l	#$FFFD0000, obj_vel_x(A6)
	CLR.b	obj_hit_flag(A6)
DragonHeadB_IdleTick_Loop:
	MOVE.w	#8, D0                          ; open-mouth frame offset
	BRA.b	BossTick_Anim_B_Loop

; BossTick_Anim_B
; Same as BossTick_Anim_A but uses EnemySpriteLayoutPtrsB.
BossTick_Anim_B:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0010, D0
	ASR.w	#2, D0
BossTick_Anim_B_Loop:
	LEA	EnemySpriteLayoutPtrsB, A0
	LEA	EnemySpritePositionPtrsB, A1
	LEA	(A5), A6
	MOVEA.l	(A0,D0.w), A0
	MOVEA.l	(A1,D0.w), A1
	MOVE.w	#3, D7
BossTick_Anim_B_Loop_Done:
	MOVE.b	(A0)+, obj_sprite_size(A6)
	CLR.w	D0
	MOVE.b	(A0)+, D0
	MOVE.w	D0, obj_sort_key(A6)
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVE.w	(A1)+, obj_world_x(A6)
	MOVE.w	(A1)+, obj_world_y(A6)
	MOVE.w	obj_world_x(A6), obj_screen_x(A6)
	MOVE.w	obj_world_y(A6), obj_screen_y(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, BossTick_Anim_B_Loop_Done
	JSR	AddSpriteToDisplayList
	RTS

;==============================================================
; SPRITE ANIMATION + COLLISION HELPERS
; Shared utilities used by multiple boss types.
;==============================================================

; AnimateSpriteFromTable
; Increments obj_move_counter, extracts bits 5–4 (>> 3) as a word
; index into the supplied tile-index table (A0), and stores the
; result in obj_tile_index(A5).  Produces a 4-frame animation that
; cycles every 16 ticks (frames 0/1/2/3 at 16 fps).
; Inputs:  A0 = pointer to word table of tile indices (4 entries)
;          A5 = object to animate
AnimateSpriteFromTable:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0030, D0                      ; mask bits 5–4 → frame 0–3
	ASR.w	#3, D0                          ; convert to word offset (×2)
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	RTS

; CheckEntityPlayerCollisionAndDamage
; Performs an AABB hit test between A5's hitbox and the player.
; If the player overlaps, sets obj_hit_flag(A5) = FLAG_TRUE and
; calls ProcessBattleDamageAndPalette to apply damage.
; Inputs:  A5 = attacker object (hitbox fields: obj_hitbox_x_neg/pos,
;               obj_hitbox_y_neg/pos relative to obj_world_x/y)
;          Player_entity_ptr = player object
CheckEntityPlayerCollisionAndDamage:
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	D0, D1
	CLR.w	D2
	MOVE.b	obj_hitbox_x_pos(A5), D2
	EXT.w	D2
	ADD.w	D2, D1
	CLR.w	D2
	MOVE.b	obj_hitbox_x_neg(A5), D2
	EXT.w	D2
	ADD.w	D2, D0
	MOVE.w	obj_world_x(A6), D2
	ADDI.w	#$000C, D2
	CMP.w	D0, D2
	BLT.w	CheckEntityPlayerCollisionAndDamage_Return
	MOVE.w	obj_world_x(A6), D2
	SUBI.w	#$000C, D2
	CMP.w	D1, D2
	BGT.w	CheckEntityPlayerCollisionAndDamage_Return
	MOVE.w	obj_world_y(A5), D0
	MOVE.w	D0, D1
	CLR.w	D2
	MOVE.b	obj_hitbox_y_neg(A5), D2
	EXT.w	D2
	ADD.w	D2, D0
	CLR.w	D2
	MOVE.b	obj_hitbox_y_pos(A5), D2
	EXT.w	D2
	ADD.w	D2, D1
	MOVE.w	obj_world_y(A6), D2
	CMP.w	D0, D2
	BLT.w	CheckEntityPlayerCollisionAndDamage_Return
	SUB.w	obj_hitbox_half_h(A6), D2
	CMP.w	D1, D2
	BGT.w	CheckEntityPlayerCollisionAndDamage_Return
	TST.b	Player_invulnerable.w
	BNE.w	CheckEntityPlayerCollisionAndDamage_Return
	PlaySound	SOUND_PLAYER_HIT
	MOVE.b	#FLAG_TRUE, Player_invulnerable.w
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A6)
	JSR	ApplyDamageToPlayer
	MOVE.l	obj_vel_x(A5), D0
	BGT.b	CheckEntityPlayerCollisionAndDamage_Loop
	CMPI.l	#$FFFF8000, D0
	BLE.b	CheckEntityPlayerCollisionAndDamage_ClampNegLow
	MOVE.l	#$FFFF8000, D0
	BRA.b	CheckEntityCollision_ClampVelocity
CheckEntityPlayerCollisionAndDamage_ClampNegLow:
	CMPI.l	#$FFFE0000, D0
	BGE.b	CheckEntityCollision_ClampVelocity
	MOVE.l	#$FFFE0000, D0
	BRA.b	CheckEntityCollision_ClampVelocity
CheckEntityPlayerCollisionAndDamage_Loop:
	CMPI.l	#$8000, D0
	BGE.b	CheckEntityPlayerCollisionAndDamage_ClampPosHigh
	MOVE.l	#$8000, D0
	BRA.b	CheckEntityCollision_ClampVelocity
CheckEntityPlayerCollisionAndDamage_ClampPosHigh:
	CMPI.l	#$00020000, D0	
	BLE.b	CheckEntityCollision_ClampVelocity	
	MOVE.l	#$00020000, D0	
CheckEntityCollision_ClampVelocity:
	ASL.l	#4, D0
	ADD.l	D0, obj_world_x(A6)
CheckEntityPlayerCollisionAndDamage_Return:
	RTS

;==============================================================
; DAMAGE / KNOCKBACK / CLAMP HELPERS
;==============================================================

; CheckPlayerDamageAndKnockback
; Simple proximity damage check: if the player's world X >= D1,
; applies damage, sets invulnerability, nudges the player left
; ($14 pixels), and plays the hit sound.
; Inputs:  D1 = minimum X threshold for the hit zone
;          Player_entity_ptr = player object
CheckPlayerDamageAndKnockback:
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), D0
	CMP.w	D1, D0
	BLT.b	BattleHit_Return
	TST.b	Player_invulnerable.w
	BNE.b	BattleHit_Return
	MOVE.b	#FLAG_TRUE, Player_invulnerable.w
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A6)
	JSR	ApplyDamageToPlayer
	SUBI.w	#$0014, obj_world_x(A6)
	PlaySound	SOUND_PLAYER_HIT
BattleHit_Return:
	RTS

; ProcessBattleDamageAndPalette
; Manages the boss's hit-stun timer (obj_knockback_timer on Enemy_list)
; and applies damage from obj_hit_flag.  While stunned, loads the
; flash palette ($0062).  On a killing blow, transitions to
; Boss1_DeathSequence and fires the victory event.
; Inputs:  Enemy_list_ptr = main boss object
;          Player_str = damage amount
ProcessBattleDamageAndPalette:
	MOVEA.l	Enemy_list_ptr.w, A6
	TST.w	obj_knockback_timer(A6)
	BLE.b	ProcessBattleDamageAndPalette_Loop
	SUBQ.w	#1, obj_knockback_timer(A6)
	MOVE.w	#$0062, Palette_line_1_index.w
	JSR	LoadPalettesFromTable
	BRA.b	ProcessBattleDamage_Return
ProcessBattleDamageAndPalette_Loop:
	BSR.w	UpdateEncounterPalette
	TST.b	obj_hit_flag(A6)
	BEQ.b	ProcessBattleDamage_Return
	PlaySound	SOUND_HEAL
	MOVE.w	Player_str.w, D0
	SUB.w	D0, obj_hp(A6)
	BCC.b	ProcessBattleDamageAndPalette_SetHitStun
	MOVE.l	#Boss1_DeathSequence, obj_tick_fn(A6)
	BSR.w	ProcessBattleVictoryEvent
	RTS

ProcessBattleDamageAndPalette_SetHitStun:
	MOVE.w	#BOSS_HIT_STUN_FRAMES, obj_knockback_timer(A6)
ProcessBattleDamage_Return:
	CLR.b	obj_hit_flag(A6)
	RTS

; ClampYPosition
; Clamps obj_world_y(A5) to a maximum of $00B0 (176 pixels).
; If the limit is exceeded, zeroes both velocity components.
; Inputs:  A5 = object to clamp
ClampYPosition:
	MOVE.w	obj_world_y(A5), D0
	CMPI.w	#$00B0, D0
	BLE.b	ClampYPosition_Loop
	MOVE.w	#$00B0, obj_world_y(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
ClampYPosition_Loop:
	RTS

;==============================================================
; VDP DRAW ROUTINES — BOSS UI
; Write pre-built tile data for the boss portrait, nameplate, and
; health bar directly to VRAM with interrupts disabled.
;
; VDP command word layout in D5:
;   $44B40003 = write to VRAM address $04B4 (nametable row for portrait)
;   $44300003 = write to VRAM address $0430 (nametable row for nameplate)
;   $40000003 = write to VRAM address $0000 (plane A top-left)
; ADDI.l #$00800000, D5 advances the write address by one nametable
; row ($80 bytes = 64 tiles × 2 bytes per entry) each loop iteration.
;==============================================================

; DrawBossPortrait
; Writes 14 rows × 12 tiles of portrait tile data (from DrawBossPortrait_Data)
; to VRAM nametable plane B starting at $04B4, with interrupts disabled.
; Each tile entry = byte from table + $2200 (palette 1, priority 0).
DrawBossPortrait:
	ORI	#$0700, SR                          ; disable interrupts (mask level 7)
	MOVE.l	#$44B40003, D5                  ; VDP write command: plane B, VRAM $04B4
	LEA	DrawBossPortrait_Data, A0
	MOVE.w	#$000D, D7                      ; 14 rows (DBF: 13 down to 0)
DrawBossPortrait_Done:
	MOVE.l	D5, VDP_control_port            ; set VRAM write address for this row
	MOVE.w	#$000B, D6                      ; 12 tiles per row (DBF: 11 down to 0)
DrawBossPortrait_TileLoop:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$2200, D0                      ; add palette 1 attribute bits
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawBossPortrait_TileLoop
	ADDI.l	#VDP_VRAM_ROW_STRIDE, D5                  ; advance to next nametable row
	DBF	D7, DrawBossPortrait_Done
	ANDI	#$F8FF, SR                          ; re-enable interrupts
	RTS

; DrawBossNameplate
; Writes 14 rows × 13 tiles of nameplate tile data to VRAM plane B
; starting at $0430 (just above the portrait area).
DrawBossNameplate:
	ORI	#$0700, SR                          ; disable interrupts
	MOVE.l	#$44300003, D5                  ; VDP write command: plane B, VRAM $0430
	LEA	DrawBossNameplate_Data, A0
	MOVE.w	#$000D, D7                      ; 14 rows
DrawBossNameplate_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$000C, D6                      ; 13 tiles per row
DrawBossNameplate_TileLoop:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$2200, D0                      ; palette 1 attribute
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawBossNameplate_TileLoop
	ADDI.l	#VDP_VRAM_ROW_STRIDE, D5
	DBF	D7, DrawBossNameplate_Done
	ANDI	#$F8FF, SR                          ; re-enable interrupts
	RTS

; DrawBossHealthBar
; Writes the health bar background (13 rows × 14 tiles from
; DrawBossHealthBar_Data, palette 2) then overlays 6 rows × 5 tiles
; of the HP gauge graphic from SpriteMetaTileTable_7808A.
DrawBossHealthBar:
	ORI	#$0700, SR                          ; disable interrupts
	MOVE.l	#$40000003, D5                  ; VDP write command: plane A, VRAM $0000
	LEA	DrawBossHealthBar_Data, A0
	MOVE.w	#$000C, D7                      ; 13 rows
DrawBossHealthBar_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$000D, D6                      ; 14 tiles per row
DrawBossHealthBar_TileLoop:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$A200, D0                      ; palette 2 attribute bits
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawBossHealthBar_TileLoop
	ADDI.l	#VDP_VRAM_ROW_STRIDE, D5
	DBF	D7, DrawBossHealthBar_Done
	MOVE.l	#$40080003, D5                  ; start of HP gauge overlay area
	LEA	SpriteMetaTileTable_7808A, A0
	MOVE.w	#5, D7                          ; 6 rows of gauge tiles
DrawBossHealthBar_GaugeRowLoop:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#4, D6                          ; 5 tiles per row
DrawBossHealthBar_GaugeTileLoop:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$A200, D0                      ; palette 2 attribute bits
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawBossHealthBar_GaugeTileLoop
	ADDI.l	#VDP_VRAM_ROW_STRIDE, D5
	DBF	D7, DrawBossHealthBar_GaugeRowLoop
	ANDI	#$F8FF, SR                          ; re-enable interrupts
	RTS

;==============================================================
; BOSS ATTACK GRAPHIC ANIMATION
; Draws the attack/dialog overlay graphics that appear during
; battle.  Two jump tables select which graphic to draw based
; on the frame counter, updated every 16 frames.
;==============================================================

; UpdateBossAttackGraphic
; Called every frame from BossBody_SpriteUpdate.  Every 16 ticks
; (counter & $F == 0), uses bits 5–4 of obj_move_counter as an
; index into BossAttackGfxJumpTable to draw one of four variants
; of the attack text graphic.
; Inputs:  A5 = boss object (obj_move_counter drives the cycle)
UpdateBossAttackGraphic:
	CLR.w	D0
	MOVE.b	obj_move_counter(A5), D0
	MOVE.w	D0, D1
	ANDI.w	#$000F, D1                      ; only update every 16 frames
	BNE.b	UpdateBossAttackGraphic_Loop
	ANDI.w	#$0030, D0                      ; bits 5–4 → frame select (0/1/2/3)
	ASR.w	#2, D0                          ; → word offset into jump table
	LEA	BossAttackGfxJumpTable, A0
	JSR	(A0,D0.w)
UpdateBossAttackGraphic_Loop:
	RTS

; BossAttackGfxJumpTable
; Four BRA entries dispatching to the four attack-text drawing routines.
BossAttackGfxJumpTable:
	BRA.w	DrawBossAttackGraphic1
	BRA.w	DrawDialogTextLine_Alt1
	BRA.w	DrawDialogTextLine_Alt1_Loop
	BRA.w	DrawDialogTextLine_Alt1

; DrawBossAttackGraphic1
; Draws the primary boss attack text graphic (two rows) at VRAM
; addresses $43BE and $48C2 on plane B.
DrawBossAttackGraphic1:
	LEA	DrawBossAttackGraphic1_Data, A0
	MOVE.l	#$43BE0003, D5                  ; plane B, VRAM $03BE (first text row)
	BSR.w	WriteTextToVRAM
	LEA	DrawBossAttackGraphic1_Data2, A0
	MOVE.l	#$48C20003, D5                  ; plane B, VRAM $08C2 (second text row)
	BSR.w	WriteTextToVRAM
	RTS

; DrawDialogTextLine_Alt1
; Draws the single-row alternate dialog text at VRAM $43BE.
DrawDialogTextLine_Alt1:
	LEA	DrawDialogTextLine_Alt1_Data, A0
	MOVE.l	#$43BE0003, D5
	BSR.w	WriteTextToVRAM
	RTS

; DrawDialogTextLine_Alt1_Loop
; Two-row variant: draws Alt1 and a second row at $48C2.
DrawDialogTextLine_Alt1_Loop:
	LEA	DrawDialogTextLine_Alt1_Loop_Data, A0
	MOVE.l	#$43BE0003, D5
	BSR.w	WriteTextToVRAM
	LEA	DrawDialogTextLine_Alt1_Loop_Data2, A0
	MOVE.l	#$48C20003, D5
	BSR.w	WriteTextToVRAM
	RTS

; WriteTextToVRAM
; Writes 6 rows × 7 tiles of text tile data from (A0) to VRAM
; at the address encoded in D5 (VDP command word), with interrupts
; disabled.  Each byte from the data table is OR'd with $2200
; (palette 1) before writing to VDP_data_port.
; Inputs:  A0 = source tile byte table (6×7 = 42 bytes)
;          D5 = VDP write command word (VRAM address + write flag)
WriteTextToVRAM:
	ORI	#$0700, SR                          ; disable interrupts
	MOVE.w	#5, D7                          ; 6 rows (DBF: 5 down to 0)
WriteTextToVRAM_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#6, D6                          ; 7 tiles per row (DBF: 6 down to 0)
WriteTextToVRAM_TileLoop:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$2200, D0                      ; palette 1 attribute
	MOVE.w	D0, VDP_data_port
	DBF	D6, WriteTextToVRAM_TileLoop
	ADDI.l	#VDP_VRAM_ROW_STRIDE, D5                  ; next nametable row
	DBF	D7, WriteTextToVRAM_Done
	ANDI	#$F8FF, SR                          ; re-enable interrupts
	RTS

; AnimateBossAttackFlash
; Drives the attack-flash overlay animation.  Every 16 frames,
; uses bits 5–4 of obj_attack_timer as an index into
; BossAttackFlashJumpTable to draw one of four flash variants.
; Inputs:  A5 = boss object (obj_attack_timer incremented each call)
AnimateBossAttackFlash:
	ADDQ.w	#1, obj_attack_timer(A5)
	MOVE.w	obj_attack_timer(A5), D0
	MOVE.w	D0, D1
	ANDI.w	#$000F, D1                      ; only update every 16 frames
	BNE.b	AnimateBossAttackFlash_Loop
	ANDI.w	#$0030, D0                      ; bits 5–4 → flash variant (0–3)
	ASR.w	#2, D0
	LEA	BossAttackFlashJumpTable, A0
	JSR	(A0,D0.w)
AnimateBossAttackFlash_Loop:
	RTS

; BossAttackFlashJumpTable
; Four entries for the attack-flash animation variants.
BossAttackFlashJumpTable:
	BRA.w	BossAttackFlashJumpTable_Loop
	BRA.w	DrawDialogTextLine_Alt2
	BRA.w	DrawDialogTextLine_Alt2_Loop
	BRA.w	DrawDialogTextLine_Alt2

; BossAttackFlashJumpTable_Loop
; Entry 0: draws the blank/reset flash state at VRAM $4642.
BossAttackFlashJumpTable_Loop:
	LEA	BossAttackFlashJumpTable_Loop_Data, A0
	MOVE.l	#$46420003, D5
	BSR.w	Write7x8TilesToVRAM
	RTS

; DrawDialogTextLine_Alt2
; Draws the single-row Alt2 flash graphic at VRAM $4642 (plane B).
DrawDialogTextLine_Alt2:
	LEA	DrawDialogTextLine_Alt2_Data, A0
	MOVE.l	#$46420003, D5
	BSR.w	Write7x8TilesToVRAM
	RTS

; DrawDialogTextLine_Alt2_Loop
; Alternate two-row variant of the flash graphic.
DrawDialogTextLine_Alt2_Loop:
	LEA	DrawDialogTextLine_Alt2_Loop_Data, A0
	MOVE.l	#$46420003, D5
	BSR.w	Write7x8TilesToVRAM
	RTS

; Write7x8TilesToVRAM
; Writes 8 rows × 8 tiles of tile data from (A0) to VRAM at the
; address in D5, with interrupts disabled.  Palette 1 attribute
; ($2200) is OR'd into each tile word.
; Inputs:  A0 = source tile byte table (8×8 = 64 bytes)
;          D5 = VDP write command word
Write7x8TilesToVRAM:
	ORI	#$0700, SR                          ; disable interrupts
	MOVE.w	#6, D7                          ; 7 rows (DBF: 6 down to 0)
Write7x8TilesToVRAM_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#7, D6                          ; 8 tiles per row (DBF: 7 down to 0)
Write7x8TilesToVRAM_TileLoop:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$2200, D0                      ; palette 1 attribute
	MOVE.w	D0, VDP_data_port
	DBF	D6, Write7x8TilesToVRAM_TileLoop
	ADDI.l	#VDP_VRAM_ROW_STRIDE, D5                  ; next nametable row
	DBF	D7, Write7x8TilesToVRAM_Done
	ANDI	#$F8FF, SR                          ; re-enable interrupts
	RTS

;==============================================================
; DIALOG PLANE + ANIM FRAME HELPERS
;==============================================================

; ClearDialogPlane
; Clears one column-strip of the dialog plane per call (used for
; the Boss 1 / Dragon victory flash effect).  Dialog_phase selects
; which VRAM column to clear; it is incremented at the end so each
; successive call wipes the next strip.
;
; First pass:  clears $03BE tiles on plane B ($44200000 base).
; Second pass: clears $0200 tiles on plane A ($40000001 base).
; Both passes advance the VRAM address by 2 tiles ($00100000) per step.
ClearDialogPlane:
	MOVE.l	#$44200000, D5              ; plane B write command base
	MOVEQ	#0, D0
	MOVE.w	Dialog_phase.w, D0
	ADD.w	D0, D0                      ; phase × 2 = word offset
	SWAP	D0                          ; move offset into high word for VDP address
	ADD.l	D0, D5
	MOVE.w	#$03BD, D7                  ; $03BE tiles to clear (DBF: $03BD down to 0)
	ORI	#$0700, SR
ClearDialogPlane_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#0, VDP_data_port
	ADDI.l	#$00100000, D5              ; advance by 2 tiles per step
	DBF	D7, ClearDialogPlane_Done
	ANDI	#$F8FF, SR
	MOVE.l	#$40000001, D5              ; plane A write command base
	MOVEQ	#0, D0
	MOVE.w	Dialog_phase.w, D0
	ADD.w	D0, D0
	SWAP	D0
	ADD.l	D0, D5
	MOVE.w	#$01FF, D7                  ; $0200 tiles to clear
	ORI	#$0700, SR
ClearDialogPlane_PlaneATileLoop:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#0, VDP_data_port
	ADDI.l	#$00100000, D5
	DBF	D7, ClearDialogPlane_PlaneATileLoop
	ANDI	#$F8FF, SR
	ADDQ.w	#1, Dialog_phase.w          ; advance to next column strip next call
	RTS

; SetBattleVictoryAnimFrames1
; Loads the first set of victory animation frames across all five
; Boss 1 object slots using EnemySpriteFrameDataA_01/04/0B tables.
SetBattleVictoryAnimFrames1:
	MOVEA.l	Enemy_list_ptr.w, A6
	LEA	EnemySpriteFrameDataA_01, A0
	MOVE.w	#5, D7
	BSR.w	SetEntityAnimFrames
	MOVEA.l	Object_slot_02_ptr.w, A6
	LEA	EnemySpriteFrameDataA_04, A0
	MOVE.w	#2, D7
	BSR.w	SetEntityAnimFrames
	MOVEA.l	Object_slot_03_ptr.w, A6
	LEA	EnemySpriteFrameDataA_0B, A0
	MOVE.w	#1, D7
	BSR.w	SetEntityAnimFrames
	MOVEA.l	Object_slot_04_ptr.w, A6
	LEA	EnemySpriteFrameDataA_0B, A0
	MOVE.w	#1, D7
	BSR.w	SetEntityAnimFrames
	MOVEA.l	Object_slot_05_ptr.w, A6
	LEA	EnemySpriteFrameDataA_0B, A0
	MOVE.w	#1, D7
	BSR.w	SetEntityAnimFrames
	RTS

; SetBattleVictoryAnimFrames2
; Loads the second set of victory animation frames (different poses)
; across all five Boss 1 object slots using tables _02/05/0C.
SetBattleVictoryAnimFrames2:
	MOVEA.l	Enemy_list_ptr.w, A6
	LEA	EnemySpriteFrameDataA_02, A0
	MOVE.w	#5, D7
	BSR.w	SetEntityAnimFrames
	MOVEA.l	Object_slot_02_ptr.w, A6
	LEA	EnemySpriteFrameDataA_05, A0
	MOVE.w	#2, D7
	BSR.w	SetEntityAnimFrames
	MOVEA.l	Object_slot_03_ptr.w, A6
	LEA	EnemySpriteFrameDataA_0C, A0
	MOVE.w	#1, D7
	BSR.w	SetEntityAnimFrames
	MOVEA.l	Object_slot_04_ptr.w, A6
	LEA	EnemySpriteFrameDataA_0C, A0
	MOVE.w	#1, D7
	BSR.w	SetEntityAnimFrames
	MOVEA.l	Object_slot_05_ptr.w, A6
	LEA	EnemySpriteFrameDataA_0C, A0
	MOVE.w	#1, D7
	BSR.w	SetEntityAnimFrames
	RTS

; SetEntityAnimFrames
; Writes D7+1 consecutive tile-index words from (A0) into the linked
; sub-object chain starting at A6, following obj_next_offset each step.
; Inputs:  A0 = source tile index word table
;          A6 = starting sub-object pointer
;          D7 = number of additional sub-objects (DBF loop count)
SetEntityAnimFrames:
	MOVE.w	(A0)+, obj_tile_index(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, SetEntityAnimFrames
	RTS

;==============================================================
; BATTLE VICTORY EVENT DISPATCH
; Sets the appropriate world-state flag for each boss encounter
; when the player wins.  Indexed by Battle_type (low nibble).
;==============================================================

; ProcessBattleVictoryEvent
; Dispatches to the correct BossVictoryEvent_* handler for the
; current battle type (Battle_type & $0F) via BattleVictoryEventJumpTable.
ProcessBattleVictoryEvent:
	LEA	BattleVictoryEventJumpTable, A0
	MOVE.w	Battle_type.w, D0
	ANDI.w	#$000F, D0                      ; low nibble = battle type index
	ADD.w	D0, D0                          ; × 2
	ADD.w	D0, D0                          ; × 4 = long BRA instruction size
	JSR	(A0,D0.w)
	RTS

; BattleVictoryEventJumpTable
; 14 entries — one BRA per battle type (0–13).
; Indexed by Battle_type & $0F.
BattleVictoryEventJumpTable:
	BRA.w	BossVictoryEvent_FakeKing
	BRA.w	BossVictoryEvent_Watling
	BRA.w	BossVictoryEvent_StowThief
	BRA.w	BossVictoryEvent_Asti
	BRA.w	BossVictoryEvent_Imposter
	BRA.w	BossVictoryEvent_Excalabria1
	BRA.w	BossVictoryEvent_Excalabria2
	BRA.w	BossVictoryEvent_Excalabria3
	BRA.w	BossVictoryEvent_Carthahena
	BRA.w	BossVictoryEvent_SwaffhamSpy
	BRA.w	BossVictoryEvent_Luther
	BRA.w	BossVictoryEvent_Thar
	BRA.w	BossVictoryEvent_SwaffhamMiniboss
	BRA.w	BossVictoryEvent_Tsarkon
BossVictoryEvent_FakeKing:
	MOVE.b	#FLAG_TRUE, Fake_king_killed.w
	RTS
	
BossVictoryEvent_Watling:
	MOVE.b	#FLAG_TRUE, Watling_youth_restored.w
	RTS
	
BossVictoryEvent_StowThief:
	MOVE.b	#FLAG_TRUE, Stow_thief_defeated.w
	RTS
	
BossVictoryEvent_Asti:
	MOVE.b	#FLAG_TRUE, Asti_monster_defeated.w
	JSR	RestoreRingsFromBackup
	MOVE.b	#FLAG_TRUE, Asti_monster_battle_complete.w
	RTS
	
BossVictoryEvent_Imposter:
	MOVE.b	#FLAG_TRUE, Imposter_killed.w
	RTS
	
BossVictoryEvent_Excalabria1:
	MOVE.b	#FLAG_TRUE, Excalabria_boss_1_defeated.w
	RTS
	
BossVictoryEvent_Excalabria2:
	MOVE.b	#FLAG_TRUE, Excalabria_boss_2_defeated.w
	RTS
	
BossVictoryEvent_Excalabria3:
	MOVE.b	#FLAG_TRUE, Excalabria_boss_3_defeated.w
	RTS
	
BossVictoryEvent_Carthahena:
	MOVE.b	#FLAG_TRUE, Carthahena_boss_met.w
	RTS
	
BossVictoryEvent_SwaffhamSpy:
	MOVE.b	#FLAG_TRUE, Swaffham_spy_defeated.w
	RTS
	
BossVictoryEvent_Luther:
	MOVE.b	#FLAG_TRUE, Luther_defeated.w
	RTS
	
BossVictoryEvent_Thar:
	MOVE.b	#FLAG_TRUE, Thar_defeated.w
	RTS
	
BossVictoryEvent_SwaffhamMiniboss:
	MOVE.b	#FLAG_TRUE, Swaffham_miniboss_defeated.w
	RTS
	
BossVictoryEvent_Tsarkon:
	MOVE.b	#FLAG_TRUE, All_rings_collected.w
	LEA	Possessed_items_length.w, A2
	LEA	(A2), A1
	MOVE.w	(A2)+, D7
	BLE.b	BossVictoryEvent_Tsarkon_Loop
	SUBQ.w	#1, D7
BossVictoryEvent_Tsarkon_Done:
	SUBQ.w	#1, (A1)
	BGE.b	BossVictoryEvent_Tsarkon_ClampCount
	CLR.w	(A1)	
BossVictoryEvent_Tsarkon_ClampCount:
	MOVE.w	D7, D0
	LEA	Possessed_items_list.w, A0
	MOVE.w	#8, D2
	JSR	RemoveItemFromArray
	DBF	D7, BossVictoryEvent_Tsarkon_Done
BossVictoryEvent_Tsarkon_Loop:
	BSR.w	GetNextItemSlotOffset
	MOVE.w	#$0115, (A0,D0.w)           ; add Ring 1 to inventory
	BSR.w	GetNextItemSlotOffset
	MOVE.w	#$0116, (A0,D0.w)           ; add Ring 2
	BSR.w	GetNextItemSlotOffset
	MOVE.w	#$0117, (A0,D0.w)           ; add Ring 3
	BSR.w	GetNextItemSlotOffset
	MOVE.w	#$0118, (A0,D0.w)           ; add Ring 4
	BSR.w	GetNextItemSlotOffset
	MOVE.w	#$0119, (A0,D0.w)           ; add Ring 5
	RTS

; GetNextItemSlotOffset
; Reads the current item count from Possessed_items_length, increments
; it, and returns the byte offset into the item list as a word in D0
; (count × 2).  Also returns A0 = pointer to item list base + length.
; Outputs: D0 = word offset for next free item slot
;          A0 = Possessed_items_length pointer (pointing past length word)
GetNextItemSlotOffset:
	LEA	Possessed_items_length.w, A0
	MOVE.w	(A0), D0
	ADDQ.w	#1, (A0)+
	ADD.w	D0, D0
	RTS

;==============================================================
; PALETTE HELPERS
;==============================================================

; UpdateEncounterPalette
; Looks up the correct palette index for the current Battle_type
; from BattlePaletteIndexTable.  If it differs from the current
; Palette_line_1_index, updates it and reloads the palette.
UpdateEncounterPalette:
	LEA	BattlePaletteIndexTable, A0
	MOVE.w	Battle_type.w, D0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), D0
	CMP.w	Palette_line_1_index.w, D0
	BEQ.w	UpdateEncounterPalette_Loop
	MOVE.w	D0, Palette_line_1_index.w
	JSR	LoadPalettesFromTable
UpdateEncounterPalette_Loop:
	RTS

;==============================================================
; REWARD / MESSAGE + DATA TABLE
; Awards XP and kims after a boss battle, shows the victory
; message, and stores the reward lookup table.
;==============================================================

; AwardBattleRewards
; Reads the XP and kims reward for the current battle from
; BattleRewardTable (indexed by Battle_type), adds them to the
; player's totals, and calls BSR.w DrawBossHealthBar to refresh
; the UI.
; Inputs:  Battle_type = current boss encounter index
AwardBattleRewards:
	LEA	BattleRewardTable, A2
	MOVE.w	Battle_type.w, D6
	ANDI.w	#$000F, D6
	ASL.w	#3, D6                          ; × 8 = offset of 2 dc.l pairs per entry
	MOVE.l	(A2,D6.w), Transaction_amount.w ; XP reward
	JSR	AddExperiencePoints
	MOVE.l	$4(A2,D6.w), Transaction_amount.w ; kims reward
	JSR	AddPaymentAmount
	RTS

; DisplayBattleVictoryMessage
; Builds the victory text string "<player name> takes <XP> EXP\nand <kims> KIMS"
; into Text_build_buffer using the reward values from BattleRewardTable,
; then calls PRINT to display it as a script dialog box.
DisplayBattleVictoryMessage:
	LEA	Player_name.w, A0
	LEA	Text_build_buffer.w, A1
	JSR	CopyStringUntilFF
	MOVE.b	#$20, (A1)+
	MOVEA.l	#TakesStr, A0
	JSR	CopyStringUntilFF
	MOVE.w	Battle_type.w, D6
	ASL.w	#3, D6
	LEA	BattleRewardTable, A2
	MOVE.l	(A2,D6.w), D0
	JSR	FormatKimsAmount
	MOVE.b	#SCRIPT_NEWLINE, (A1)+
	MOVE.b	#$61, (A1)+
	MOVE.b	#$6E, (A1)+
	MOVE.b	#$64, (A1)+
	MOVE.b	#$20, (A1)+
	MOVE.w	Battle_type.w, D6
	ASL.w	#3, D6
	LEA	BattleRewardTable, A2
	MOVE.l	$4(A2,D6.w), D0
	JSR	FormatKimsAmount
	LEA	-$4(A1), A1
	MOVEA.l	#ExpStr, A0
	JSR	CopyStringUntilFF
	MOVE.b	#$FF, (A1)
	PRINT 	Text_build_buffer
	JSR	ResetScriptAndInitDialogue
	RTS

; BattleRewardTable
; Parallel pairs of dc.l values: (XP reward, kims reward) per battle type.
; Indexed by Battle_type & $0F, offset = Battle_type × 8.
; Entry 0 corresponds to Battle_type 0 (FakeKing), etc.
;
; Format per entry:
;   dc.l  <XP reward>
;   dc.l  <kims reward>
BattleRewardTable:
	dc.l	$500
	dc.l	$500
	dc.l	$1000 
	dc.l	$1000 
	dc.l	$3000 
	dc.l	$3000 
	dc.l	$5000 
	dc.l	$5000 
	dc.l	$10000 
	dc.l	$8000 
	dc.l	$15000 
	dc.l	$10000 
	dc.l	$20000 
	dc.l	$15000 
	dc.l	$25000 
	dc.l	$20000 
	dc.l	$30000 
	dc.l	$25000 
	dc.l	$30000 
	dc.l	$25000 
	dc.l	$25000 
	dc.l	$30000 
	dc.l	$35000
	dc.l	$35000 
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$0

;==============================================================
; DEMON BOSS — INIT
; Difficulty-scaled HP/damage setup followed by shared sprite,
; hitbox, and AI state initialisation for the Demon Boss.
;==============================================================

; InitDemonBoss_Normal / _Hard
; Sets HP and max-damage values then falls through to InitDemonBoss_Common.
InitDemonBoss_Normal:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#BOSS_HP_ORBIT_NORMAL, obj_hp(A6)
	MOVE.w	#BOSS_HP_ORBIT_NORMAL, Boss_max_hp.w
	MOVE.w	#BOSS_DMG_DEMON_NORMAL, obj_max_hp(A6)
	BRA.w	InitDemonBoss_Common

; InitDemonBoss_Common
; Shared init: positions the demon at world ($0120, $00B0), sets
; hitbox ($E8/$18 X, $C0/$00 Y), clears all AI state fields, loads
; sprite data, spawns child body segments, and draws the boss portrait.
InitDemonBoss_Hard:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#BOSS_HP_ORBIT_HARD, obj_hp(A6)
	MOVE.w	#BOSS_HP_ORBIT_HARD, Boss_max_hp.w
	MOVE.w	#BOSS_DMG_DEMON_HARD, obj_max_hp(A6)

; InitDemonBoss_Common
; Shared init: positions the demon at world ($0120, $00B0), sets
; hitbox ($E8/$18 X, $C0/$00 Y), clears all AI state fields, loads
; sprite layout, spawns child body segments, and draws the boss portrait.
InitDemonBoss_Common:
	MOVEA.l	Enemy_list_ptr.w, A6
	BSET.b	#7, (A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	CLR.b	demon_ai_state(A6)
	MOVE.w	#DEMON_BOSS_MOVE_DELAY, obj_attack_timer(A6)
	CLR.w	obj_knockback_timer(A6)
	CLR.b	obj_hit_flag(A6)
	CLR.b	demon_dir_flag(A6)
	MOVE.l	#$01200000, obj_world_x(A6)
	MOVE.l	#$00B00000, obj_world_y(A6)
	MOVE.w	#SORT_KEY_DEMON_WING, obj_sort_key(A6)
	MOVE.b	#$E8, obj_hitbox_x_neg(A6)
	MOVE.b	#$18, obj_hitbox_x_pos(A6)
	MOVE.b	#$C0, obj_hitbox_y_neg(A6)
	MOVE.b	#0, obj_hitbox_y_pos(A6)
	CLR.b	demon_wing_anim(A6)
	CLR.b	demon_fire_dir(A6)
	CLR.b	demon_wing_flags(A6)
	BSET.b	#0, demon_wing_flags(A6)
	BSET.b	#1, demon_wing_flags(A6)
	MOVE.w	#0, demon_seg0_y(A6)
	MOVE.w	#$001E, demon_seg1_y(A6)
	MOVE.w	#$0028, demon_seg2_y(A6)
	MOVE.w	#$0050, demon_seg3_y(A6)
	MOVE.w	#$0078, demon_seg4_y(A6)
	MOVE.w	#$0096, demon_seg5_y(A6)
	MOVE.l	#DemonBoss_MainTick, obj_tick_fn(A6)
	MOVE.w	#$0034, D7
InitDemonBoss_Common_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BSET.b	#7, (A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	CLR.b	demon_seg_active(A6)
	MOVE.l	#DemonBoss_BodySegmentTick, obj_tick_fn(A6)
	DBF	D7, InitDemonBoss_Common_Done
	MOVEA.l	Enemy_list_ptr.w, A4
	MOVEA.l	Object_slot_07_ptr.w, A6
	MOVE.w	#3, D7
InitDemonBoss_HeadSlotLoop:
	CLR.w	obj_knockback_timer(A6)
	CLR.b	obj_move_counter(A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.w	obj_max_hp(A4), obj_max_hp(A6)
	MOVE.b	#$F4, obj_hitbox_x_neg(A6)
	MOVE.b	#$0C, obj_hitbox_x_pos(A6)
	MOVE.b	#$E4, obj_hitbox_y_neg(A6)
	MOVE.b	#4, obj_hitbox_y_pos(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, InitDemonBoss_HeadSlotLoop
	RTS

;==============================================================
; DEMON BOSS — AI STATE MACHINE
; Per-frame main tick and six states:
;   0 = WaitIdle     — countdown before choosing a direction
;   1 = ChooseDirection — pick X direction and move-step count
;   2 = Move         — fly horizontally, animate wings
;   3 = FireProjectile — launch serpent head projectile
;   4 = AttackAnimate — play fire-breath animation
;   5 = Cooldown     — wait before returning to WaitIdle
;==============================================================

; DemonBoss_MainTick
; Per-frame tick for the Demon Boss.  Skips during fade-in.
; Dispatches to the state machine via BossAiDemonJumpTable, then
; runs UpdateBossFlashAndDamage, SpawnBossChildObjects, and
; CheckEntityPlayerCollisionAndDamage.
DemonBoss_MainTick:
	TST.b	Fade_in_lines_mask.w
	BNE.b	DemonBoss_MainTick_Loop
	MOVE.b	demon_ai_state(A5), D0
	ANDI.w	#7, D0                          ; 8 states max (3-bit mask)
	ADD.w	D0, D0                          ; × 2
	ADD.w	D0, D0                          ; × 4 = long BRA instruction size
	LEA	BossAiDemonJumpTable, A0
	JSR	(A0,D0.w)
	JSR	UpdateBossFlashAndDamage(PC)
	JSR	SpawnBossChildObjects(PC)
	JSR	CheckEntityPlayerCollisionAndDamage(PC)
DemonBoss_MainTick_Loop:
	RTS

; BossAiDemonJumpTable
; Six BRA entries for the six Demon Boss AI states.
BossAiDemonJumpTable:
	BRA.w	DemonBossState_WaitIdle
	BRA.w	DemonBossState_ChooseDirection
	BRA.w	DemonBossState_Move
	BRA.w	DemonBossState_FireProjectile
	BRA.w	DemonBossState_AttackAnimate
	BRA.w	DemonBossState_Cooldown

; DemonBossState_WaitIdle
; Counts down obj_attack_timer; advances to ChooseDirection when done.
DemonBossState_WaitIdle:
	TST.b	Battle_active_flag.w
	BEQ.w	DemonBossState_WaitReturn
	SUBQ.w	#1, obj_attack_timer(A5)
	BGT.w	DemonBossState_WaitReturn
	ADDQ.b	#1, demon_ai_state(A5)
DemonBossState_WaitReturn:
	RTS

; DemonBossState_ChooseDirection
; Uses RNG + X position to pick move direction (left/right).  Forces
; to the opposite edge if already at a boundary.  Selects 1–4 move
; steps and a small vertical bob velocity ($0010).
DemonBossState_ChooseDirection:
	JSR	GetRandomNumber(PC)
	CMPI.w	#DEMON_BOSS_X_LEFT_BOUND, obj_world_x(A5)
	BLE.b	DemonBoss_MoveLeft
	CMPI.w	#DEMON_BOSS_X_RIGHT_BOUND, obj_world_x(A5)
	BGE.b	DemonBoss_MoveRight
	CMPI.b	#$FF, demon_dir_flag(A5)
	BEQ.b	DemonBoss_MoveLeft
	MOVE.w	D0, D1
	ANDI.w	#3, D0
	BNE.b	DemonBoss_MoveRight
DemonBoss_MoveLeft:
	MOVE.l	#$0000C000, obj_pos_x_fixed(A5) ; left velocity ($C000 = negative fixed-point)
	BRA.b	DemonBoss_MoveRight_Loop
DemonBoss_MoveRight:
	MOVE.l	#Player_overworld_gfx_buffer, obj_pos_x_fixed(A5) ; right velocity
DemonBoss_MoveRight_Loop:
	CLR.b	demon_dir_flag(A5)
	ANDI.w	#3, D0
	ADDQ.w	#1, D0                          ; 1–4 move steps
	MOVE.w	D0, demon_move_steps(A5)
	CLR.w	demon_move_timer(A5)
	MOVE.w	#$0010, obj_vel_y(A5)           ; small vertical bob counter
	ADDQ.b	#1, demon_ai_state(A5)          ; advance to Move state
	RTS

; DemonBossState_Move
; Moves the demon horizontally each step, animates wings, and handles
; boundary rebound.  Advances to FireProjectile after all steps.
DemonBossState_Move:
	TST.w	demon_move_timer(A5)
	BLE.b	DemonBossState_Move_Loop
	SUBQ.w	#1, demon_move_timer(A5)
	BGT.w	DemonBossState_Move_Return
DemonBossState_Move_Loop:
	MOVE.l	obj_pos_x_fixed(A5), D0
	ADD.l	D0, obj_world_x(A5)
	CMPI.w	#8, obj_vel_y(A5)
	BNE.b	DemonBossState_Move_WingAnim
	ADDQ.b	#1, demon_wing_anim(A5)
	MOVE.b	demon_wing_anim(A5), D0
	ANDI.w	#1, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	DemonBossWingFrameData, A0
	MOVE.w	(A0,D0.w), demon_seg4_y(A5)
	MOVE.w	$2(A0,D0.w), demon_seg5_y(A5)
DemonBossState_Move_WingAnim:
	SUBQ.w	#1, obj_vel_y(A5)
	BGT.b	DemonBossState_Move_Return
	CMPI.w	#DEMON_BOSS_X_LEFT_BOUND, obj_world_x(A5)
	BLE.b	DemonBossState_Move_Rebound
	CMPI.w	#DEMON_BOSS_X_RIGHT_BOUND, obj_world_x(A5)
	BGE.b	DemonBossState_Move_Rebound
	SUBQ.w	#1, demon_move_steps(A5)
	BLE.b	DemonBossState_Move_Rebound
	CMPI.b	#$FF, demon_dir_flag(A5)
	BNE.b	DemonBossState_Move_BounceCheck
	CLR.b	demon_dir_flag(A5)
	TST.l	obj_pos_x_fixed(A5)
	BGE.b	DemonBossState_Move_BounceCheck
	NEG.l	obj_pos_x_fixed(A5)
DemonBossState_Move_BounceCheck:
	MOVE.w	#DEMON_BOSS_MOVE_DELAY, demon_move_timer(A5)
	MOVE.w	#$0010, obj_vel_y(A5)
	BRA.b	DemonBossState_Move_Return
DemonBossState_Move_Rebound:
	MOVE.w	#DEMON_BOSS_MOVE_DELAY, obj_attack_timer(A5)
	ADDQ.b	#1, demon_ai_state(A5)
DemonBossState_Move_Return:
	RTS

; DemonBossState_FireProjectile
; Counts down obj_attack_timer, then determines whether to fire a
; second projectile (based on wing_flags bits 0/1 and RNG bit 5).
; Calculates a scaled X velocity toward the player (clamped to
; [$5E00, $CE00] range), launches the projectile via slot 07, and
; advances to AttackAnimate.
DemonBossState_FireProjectile:
	SUBQ.w	#1, obj_attack_timer(A5)
	BGT.w	DemonBoss_LaunchProjectile_Loop
	BTST.b	#0, demon_wing_flags(A5)
	BEQ.b	DemonBossState_FireProjectile_Loop
	BTST.b	#1, demon_wing_flags(A5)
	BEQ.b	DemonBoss_SetFireFlag
	JSR	GetRandomNumber(PC)
	BTST.l	#5, D0
	BEQ.b	DemonBoss_SetFireFlag
DemonBossState_FireProjectile_Loop:
	BCLR.b	#2, demon_wing_flags(A5)
	BRA.b	DemonBoss_SetFireFlag_Loop
DemonBoss_SetFireFlag:
	BSET.b	#2, demon_wing_flags(A5)
DemonBoss_SetFireFlag_Loop:
	MOVE.b	#1, demon_fire_dir(A5)
	JSR	SetEntityCoordFromDirection(PC)
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), D1
	MOVE.w	obj_world_x(A5), D2
	ADDI.w	#$0046, D2
	SUB.w	D2, D1
	BGE.b	DemonBoss_SetFireFlag_AbsVelocity
	NEG.w	D1
DemonBoss_SetFireFlag_AbsVelocity:
	SWAP	D1
	CLR.w	D1
	ASR.l	#4, D1
	CMPI.l	#$000CE000, D1
	BLE.b	DemonBoss_SetFireFlag_ClampLow
	MOVE.l	#$000CE000, D1
	BRA.b	DemonBoss_LaunchProjectile
DemonBoss_SetFireFlag_ClampLow:
	CMPI.l	#$0005E000, D1
	BGE.b	DemonBoss_LaunchProjectile
	MOVE.l	#$0005E000, D1	
DemonBoss_LaunchProjectile:
	DIVU.w	#$002C, D1
	EXT.l	D1
	ASL.l	#4, D1
	NEG.l	D1
	MOVEA.l	Object_slot_07_ptr.w, A6
	MOVE.l	D1, obj_vel_x(A6)
	BSET.b	#7, (A6)
	MOVE.l	#DemonBoss_ProjectileHeadTick, obj_tick_fn(A6)
	PlaySound	SOUND_TREASURE
	MOVE.w	#$0064, obj_attack_timer(A5)
	ADDQ.b	#1, demon_ai_state(A5)
DemonBoss_LaunchProjectile_Loop:
	RTS

; DemonBossState_AttackAnimate
; Animates the demon boss body during the attack swing.
; Counts down obj_attack_timer; at DEMON_BOSS_ATTACK_FIRE_TICK releases the
; projectile (slot 07) downward; at timer==6 resets wing pose; at 0 advances state.
DemonBossState_AttackAnimate:
	SUBQ.w	#1, obj_attack_timer(A5)
	MOVE.w	obj_attack_timer(A5), D0
	ASR.w	#1, D0
	ANDI.w	#$003E, D0                          ; 32-entry table index (even offsets)
	LEA	DemonBossAttackYOffsets, A0
	MOVE.w	(A0,D0.w), demon_seg0_y(A5)          ; drive head Y from lunge table
	TST.w	obj_attack_timer(A5)
	BEQ.w	DemonBossState_AttackAnimate_UpdateFrame_Loop   ; timer expired → next state
	CMPI.w	#DEMON_BOSS_ATTACK_FIRE_TICK, obj_attack_timer(A5)
	BGT.b	DemonBossState_AttackAnimate_UpdateFrame        ; still winding up
	BNE.b	DemonBossState_AttackAnimate_Loop               ; past fire tick, not yet end
	; Exactly at fire tick: launch the projectile
	PlaySound	SOUND_BOMB
	MOVEA.l	Object_slot_07_ptr.w, A6
	MOVE.b	#FLAG_TRUE, obj_move_counter(A6)    ; mark projectile as active/falling
	MOVE.l	#$00020000, obj_vel_y(A6)           ; initial downward velocity
	CLR.w	obj_attack_timer(A6)
	MOVE.w	#6, obj_pos_x_fixed(A6)             ; reset sub-pixel X
	CLR.w	obj_knockback_timer(A6)
	CLR.w	obj_seg_counter(A6)                              ; clear segment counter
	BRA.b	DemonBossState_AttackAnimate_UpdateFrame
DemonBossState_AttackAnimate_Loop:
	CMPI.w	#6, obj_attack_timer(A5)            ; near end of swing: reset wing pose
	BNE.b	DemonBossState_AttackAnimate_UpdateFrame
	MOVE.b	#0, demon_fire_dir(A5)              ; pose 0 = folded/neutral
	JSR	SetEntityCoordFromDirection(PC)
	BRA.b	DemonBossState_FireReturn
DemonBossState_AttackAnimate_UpdateFrame:
	; Update the projectile sprite frame from DemonBossProjectileFrames table
	MOVEA.l	Object_slot_07_ptr.w, A6
	MOVE.w	obj_attack_timer(A5), D0
	ASR.w	#1, D0
	ANDI.w	#$003E, D0
	LEA	DemonBossProjectileFrames, A0
	MOVE.w	(A0,D0.w), obj_knockback_timer(A6)  ; tile frame index stored in knockback_timer
	BRA.b	DemonBossState_FireReturn
DemonBossState_AttackAnimate_UpdateFrame_Loop:
	; Attack complete: return wing to retracted pose, set cooldown
	MOVE.b	#2, demon_fire_dir(A5)              ; pose 2 = retracted
	JSR	SetEntityCoordFromDirection(PC)
	MOVE.w	#$0028, obj_attack_timer(A5)        ; 40-frame cooldown
	ADDQ.b	#1, demon_ai_state(A5)              ; advance to Cooldown state
DemonBossState_FireReturn:
	RTS

; DemonBossState_Cooldown
; Counts down obj_attack_timer after an attack sequence.
; When expired, clears direction flags, resets wing pose, and returns to WaitIdle.
DemonBossState_Cooldown:
	SUBQ.w	#1, obj_attack_timer(A5)
	BGT.b	DemonBossState_Cooldown_Loop        ; still cooling down
	CLR.b	demon_dir_flag(A5)                  ; clear directional movement flag
	MOVE.b	#0, demon_fire_dir(A5)              ; fold wings to neutral pose
	JSR	SetEntityCoordFromDirection(PC)
	MOVE.w	#$003C, obj_attack_timer(A5)        ; 60-frame idle delay
	CLR.b	demon_ai_state(A5)                  ; return to state 0 (WaitIdle)
DemonBossState_Cooldown_Loop:
	RTS

; SetEntityCoordFromDirection
; Updates the demon boss wing/body segment Y-offsets based on demon_fire_dir.
; If wing_flags bit 2 is set, uses EntityDirectionXOffsets → demon_seg2_y;
; otherwise uses EntityDirectionYOffsets → demon_seg3_y.
; Inputs: A5 = demon boss object; demon_fire_dir(A5) = pose index (0-2/3)
SetEntityCoordFromDirection:
	BTST.b	#2, demon_wing_flags(A5)            ; bit 2 = use X-offset table
	BNE.b	SetEntityCoordFromDirection_Loop
	LEA	EntityDirectionYOffsets, A0
	MOVE.b	demon_fire_dir(A5), D0
	ANDI.w	#3, D0                              ; clamp to 0-3
	ADD.w	D0, D0                              ; × 2 for word offset
	MOVE.w	(A0,D0.w), demon_seg3_y(A5)
	BRA.b	SetEntityCoordFromDirection_UseXOffset
SetEntityCoordFromDirection_Loop:
	LEA	EntityDirectionXOffsets, A0
	MOVE.b	demon_fire_dir(A5), D0
	ANDI.w	#3, D0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), demon_seg2_y(A5)
SetEntityCoordFromDirection_UseXOffset:
	RTS

;==============================================================
; DEMON BOSS DATA TABLES
;==============================================================

; DemonBossWingFrameData
; Four wing tile offsets (two pairs: open / closed) used by wing animation.
DemonBossWingFrameData:
	dc.w	$78, $96
	dc.w	$82, $8C 
; EntityDirectionXOffsets
; X-component segment offsets for the three fire-direction poses (indexed 0-2).
EntityDirectionXOffsets:
	dc.w	$28
	dc.w	$32
	dc.w	$3C
; EntityDirectionYOffsets
; Y-component segment offsets for the three fire-direction poses (indexed 0-2).
EntityDirectionYOffsets:
	dc.w	$50
	dc.w	$5A
	dc.w	$64
; DemonBossAttackYOffsets
; Per-frame head-Y lunge offsets for the 50-frame attack animation.
; Indexed as (timer >> 1) & $3E (even bytes → word table, 32 entries × 2 bytes).
DemonBossAttackYOffsets:
	dc.b	$00, $00, $00, $00, $00, $00, $00, $0A, $00, $14, $00, $0A, $00, $00, $00, $0A, $00, $14, $00, $0A, $00, $00, $00, $0A, $00, $0A, $00, $14, $00, $14, $00, $0A 
	dc.b	$00, $0A, $00, $00, $00, $00, $00, $0A, $00, $0A, $00, $14, $00, $14, $00, $0A, $00, $0A 
; DemonBossProjectileFrames
; Per-frame tile index offsets for the projectile sprite (50-frame cycle, same indexing).
DemonBossProjectileFrames:
	dc.b	$00, $00, $00, $08, $00, $10, $00, $18, $00, $20, $00, $00, $00, $08, $00, $10, $00, $18, $00, $20, $00, $00, $00, $08, $00, $10, $00, $18, $00, $20, $00, $00 
	dc.b	$00, $08, $00, $10, $00, $18, $00, $20, $00, $00, $00, $08, $00, $10, $00, $18, $00, $20 

;==============================================================
; DEMON BOSS — DAMAGE, DEATH, AND VICTORY
;==============================================================

; UpdateBossFlashAndDamage
; Called every tick. Handles the flash stun timer and processes player hits.
; On killing blow, installs DemonBoss_DeathInit as the tick function.
; Below half HP, randomly strips one wing flag (bit 0 or bit 1) to disable wings.
UpdateBossFlashAndDamage:
	TST.w	obj_knockback_timer(A5)
	BLE.b	UpdateBossFlashAndDamage_Loop
	SUBQ.w	#1, obj_knockback_timer(A5)         ; still in hit-stun: flash palette
	MOVE.w	#$0026, Palette_line_1_index.w
	JSR	LoadPalettesFromTable
	BRA.w	DemonBoss_AbilityReturn
UpdateBossFlashAndDamage_Loop:
	JSR	UpdateEncounterPalette
	TST.b	obj_hit_flag(A5)
	BEQ.w	DemonBoss_AbilityReturn
	MOVE.b	#$FF, demon_dir_flag(A5)            ; force direction re-evaluation
	PlaySound	SOUND_HEAL
	MOVE.w	Player_str.w, D0
	SUB.w	D0, obj_hp(A5)
	BCC.b	UpdateBossFlashAndDamage_SetHitStun      ; still alive
	MOVE.l	#DemonBoss_DeathInit, obj_tick_fn(A5)   ; killing blow
	PlaySound_b	SOUND_MAGIC_EFFECT
	RTS

UpdateBossFlashAndDamage_SetHitStun:
	CMPI.b	#4, demon_ai_state(A5)
	BGE.w	BossTick_AbilityCheck_Done
	MOVE.w	Boss_max_hp.w, D0
	ASR.w	#1, D0
	MOVE.w	obj_hp(A5), D1
	CMP.w	D0, D1
	BGT.w	BossTick_AbilityCheck_Done
	MOVE.b	demon_wing_flags(A5), D1
	ANDI.b	#3, D1
	CMPI.b	#3, D1
	BNE.b	BossTick_AbilityCheck_Done
	PlaySound_b	SOUND_MAGIC_EFFECT
	JSR	GetRandomNumber(PC)
	BTST.l	#4, D0
	BEQ.b	UpdateBossFlashAndDamage_DisableWingB
	BCLR.b	#0, demon_wing_flags(A5)
	MOVE.w	#$0046, demon_seg2_y(A5)
	BRA.b	BossTick_AbilityCheck_Done
UpdateBossFlashAndDamage_DisableWingB:
	BCLR.b	#1, demon_wing_flags(A5)
	MOVE.w	#$006E, demon_seg3_y(A5)
BossTick_AbilityCheck_Done:
	MOVE.w	#BOSS_HIT_STUN_FRAMES, obj_knockback_timer(A5)
DemonBoss_AbilityReturn:
	CLR.b	obj_hit_flag(A5)
	RTS


;==============================================================
; DEMON BOSS — DEATH SEQUENCE + CHILD OBJECTS
;==============================================================
; DemonBoss_DeathInit
; Begins the demon boss death sequence: sets tick function, resets dialog
; timers, and plays the death sound.
DemonBoss_DeathInit:
	MOVE.l	#DemonBoss_DeathSequence, obj_tick_fn(A5)
	CLR.w	Dialog_timer.w
	CLR.w	Dialog_phase.w
	PlaySound	SOUND_PURCHASE
	RTS

; DemonBoss_DeathSequence
; Ticks the death fade: clears the dialog plane every 8 frames until all
; BOSS_VICTORY_FADE_PHASES have elapsed, then triggers the victory event.
DemonBoss_DeathSequence:
	ADDQ.w	#1, Dialog_timer.w
	MOVE.w	Dialog_timer.w, D0
	ANDI.w	#7, D0
	BNE.b	DemonBoss_DeathSequence_Loop
	CMPI.w	#BOSS_VICTORY_FADE_PHASES, Dialog_phase.w
	BLT.b	DemonBoss_DeathSequence_ClearPlane
	JSR	ProcessBattleVictoryEvent
	MOVE.l	#BossCommon_VictoryRewardSequence, obj_tick_fn(A5)
	MOVE.w	#BOSS_VICTORY_DELAY_FRAMES, Dialog_timer.w
	RTS

DemonBoss_DeathSequence_ClearPlane:
	JSR	ClearDialogPlane
DemonBoss_DeathSequence_Loop:
	RTS

; SpawnBossChildObjects
; Spawns all six demon boss body-segment child objects into the six enemy
; slots, passing each segment's Y offset and sprite descriptor to SpawnChildObjects.
SpawnBossChildObjects:
	MOVE.w	demon_seg0_y(A5), D0
	MOVEA.l	Object_slot_01_ptr.w, A6
	MOVE.w	#6, D7
	JSR	SpawnChildObjects(PC)
	MOVE.w	demon_seg1_y(A5), D0
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.w	#9, D7
	JSR	SpawnChildObjects(PC)
	MOVE.w	demon_seg2_y(A5), D0
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.w	#9, D7
	JSR	SpawnChildObjects(PC)
	MOVE.w	demon_seg3_y(A5), D0
	MOVEA.l	Object_slot_04_ptr.w, A6
	MOVE.w	#9, D7
	JSR	SpawnChildObjects(PC)
	MOVE.w	demon_seg4_y(A5), D0
	MOVEA.l	Object_slot_05_ptr.w, A6
	MOVE.w	#$000A, D7
	JSR	SpawnChildObjects(PC)
	MOVE.w	demon_seg5_y(A5), D0
	MOVEA.l	Object_slot_06_ptr.w, A6
	MOVE.w	#$000A, D7
	JSR	SpawnChildObjects(PC)
	RTS
	
; SpawnChildObjects
; Populates a chain of object slots with sprite data from EncounterSpriteDescTable.
; Inputs: A1 = sprite descriptor entry, A6 = first object slot, D7 = count-1
; Each entry sets tile index, sprite size, sort key, world X/Y relative to the boss.
SpawnChildObjects:
	LEA	EncounterSpriteDescTable, A1
	ADDA.w	D0, A1
	MOVEA.l	(A1)+, A2
	MOVE.w	(A1)+, D0
	MOVE.w	(A1)+, D1
	MOVE.w	(A1), D2
	SUBQ.w	#1, D7
SpawnChildObjects_Done:
	CMPI.w	#$FFFF, (A2)
	BEQ.w	DemonBoss_ClearBodySegment
	MOVE.w	(A2)+, obj_tile_index(A6)
	MOVE.b	(A2)+, obj_sprite_size(A6)
	MOVE.b	(A2)+, D3
	EXT.w	D3
	ADD.w	D2, D3
	ADD.w	obj_sort_key(A5), D3
	MOVE.w	D3, obj_sort_key(A6)
	MOVE.w	(A2)+, D3
	ADD.w	D0, D3
	ADD.w	obj_world_x(A5), D3
	MOVE.w	D3, obj_world_x(A6)
	MOVE.w	(A2)+, D3
	ADD.w	D1, D3
	ADD.w	obj_world_y(A5), D3
	MOVE.w	D3, obj_world_y(A6)
	MOVE.b	#$FF, demon_seg_active(A6)
	CLR.w	D6
	MOVE.b	obj_next_offset(A6), D6
	LEA	(A6,D6.w), A6
	DBF	D7, SpawnChildObjects_Done
	RTS

; DemonBoss_ClearBodySegment
; Marks body-segment object slots as inactive (clears demon_seg_active).
; Called when the sprite descriptor list ends (sentinel $FFFF encountered).
DemonBoss_ClearBodySegment:
	CLR.b	demon_seg_active(A6)
	CLR.w	D6
	MOVE.b	obj_next_offset(A6), D6
	LEA	(A6,D6.w), A6
	DBF	D7, DemonBoss_ClearBodySegment
	RTS

; DemonBoss_BodySegmentTick
; Per-frame tick for a static demon boss body segment.
; If the segment is active, copies world position to screen position and queues sprite.
DemonBoss_BodySegmentTick:
	TST.b	demon_seg_active(A5)
	BEQ.b	DemonBoss_BodySegmentTick_Loop
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList(PC)
DemonBoss_BodySegmentTick_Loop:
	RTS

; DemonBoss_ProjectileHeadTick
; Tick function for the head segment of the demon boss projectile.
; Advances the animation frame counter, spawns trailing segment objects, and
; delegates rendering to DemonBoss_ProjectileSegmentTick.
DemonBoss_ProjectileHeadTick:
	CMPI.b	#FLAG_TRUE, obj_move_counter(A5)
	BNE.w	DemonBoss_ProjectileHeadTick_Loop
	MOVE.w	obj_seg_counter(A5), D7
	CMPI.w	#2, D7
	BGT.w	DemonBoss_ProjectileSegmentTick
	SUBQ.w	#1, obj_pos_x_fixed(A5)
	BGT.w	DemonBoss_ProjectileSegmentTick
	MOVE.w	#6, obj_pos_x_fixed(A5)
	ADDQ.w	#1, obj_seg_counter(A5)
	MOVEA.l	Object_slot_07_ptr.w, A6
DemonBoss_ProjectileHeadTick_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, DemonBoss_ProjectileHeadTick_Done
	BSET.b	#7, (A6)
	CLR.w	obj_attack_timer(A6)
	CLR.w	obj_knockback_timer(A6)
	MOVE.w	obj_hitbox_half_w(A5), obj_world_x(A6)
	MOVE.w	obj_hitbox_half_h(A5), obj_world_y(A6)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
	MOVE.l	obj_vel_x(A5), obj_vel_x(A6)
	MOVE.l	obj_vel_y(A5), obj_vel_y(A6)
	MOVE.l	#DemonBoss_ProjectileSegmentTick, obj_tick_fn(A6)
	BRA.w	DemonBoss_ProjectileSegmentTick
DemonBoss_ProjectileHeadTick_Loop:
	MOVEA.l	Enemy_list_ptr.w, A6
	LEA	EncounterSpriteList_Hydra, A1
	BTST.b	#2, demon_wing_flags(A6)
	BNE.b	DemonBoss_ProjectileHeadTick_GetFireDir
	ADDA.w	#$001E, A1
DemonBoss_ProjectileHeadTick_GetFireDir:
	MOVEQ	#0, D0
	MOVE.b	demon_fire_dir(A6), D0
	ADD.w	D0, D0
	MOVE.w	D0, D1
	ASL.w	#2, D1
	ADD.w	D1, D0
	ADDA.w	D0, A1
	MOVEA.l	(A1)+, A2
	MOVE.w	(A1)+, D0
	MOVE.w	(A1)+, D1
	MOVE.w	(A1), D2
	MOVE.w	obj_knockback_timer(A5), D3
	ADDA.w	D3, A2
	MOVE.w	(A2)+, obj_tile_index(A5)
	MOVE.b	(A2)+, obj_sprite_size(A5)
	MOVE.b	(A2)+, D3
	EXT.w	D3
	ADD.w	D2, D3
	ADD.w	obj_sort_key(A6), D3
	MOVE.w	D3, obj_sort_key(A5)
	MOVE.w	(A2)+, D3
	ADD.w	D0, D3
	ADD.w	obj_world_x(A6), D3
	MOVE.w	D3, obj_world_x(A5)
	MOVE.w	(A2)+, D3
	ADD.w	D1, D3
	ADD.w	obj_world_y(A6), D3
	MOVE.w	D3, obj_world_y(A5)
	MOVE.w	obj_world_x(A5), $1C(A5)
	MOVE.w	obj_world_y(A5), obj_hitbox_half_h(A5)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList(PC)
	RTS

; DemonBoss_ProjectileSegmentTick
; Tick function for each trailing segment of the demon boss projectile.
; Moves the segment along its velocity vector, checks player collision,
; cycles through DemonBossProjectileTileFrames for animation, and deactivates
; the segment when the attack_timer reaches zero after passing the Y floor.
DemonBoss_ProjectileSegmentTick:
	LEA	EncounterSpriteList_Hydra, A1
	MOVEA.l	(A1)+, A2
	MOVE.w	(A1)+, D0
	MOVE.w	(A1)+, D1
	MOVE.w	(A1), D2
	MOVE.w	obj_knockback_timer(A5), D3
	ADDA.w	D3, A2
	MOVE.w	(A2)+, obj_tile_index(A5)
	MOVE.b	(A2)+, obj_sprite_size(A5)
	CMPI.w	#DEMON_BOSS_PROJ_Y_FLOOR, obj_world_y(A5)
	BLT.b	DemonBoss_ProjectileSegmentTick_Loop
	SUBQ.w	#1, obj_attack_timer(A5)
	BGT.b	DemonBoss_ProjectileSegmentTick_AnimTimer
	CLR.b	obj_move_counter(A5)
	BCLR.b	#7, (A5)
	BRA.w	DemonBoss_ProjectileSegmentTick_Render
DemonBoss_ProjectileSegmentTick_AnimTimer:
	MOVE.w	obj_attack_timer(A5), D0
	ASR.w	#1, D0
	ANDI.w	#$000E, D0
	LEA	DemonBossProjectileTileFrames, A0
	MOVE.w	(A0,D0.w), obj_knockback_timer(A5)
	BRA.w	DemonBoss_ProjectileSegmentTick_RenderAndReturn
DemonBoss_ProjectileSegmentTick_Loop:
	CMPI.w	#DEMON_BOSS_SEG_ANIM_FRAMES, obj_attack_timer(A5)
	BEQ.b	DemonBoss_ProjectileSegmentTick_RisingAnim
	ADDQ.w	#1, obj_attack_timer(A5)
	MOVE.w	obj_attack_timer(A5), D0
	ASR.w	#1, D0
	ANDI.w	#$000E, D0
	LEA	DemonBossProjectileTileFrames, A0
	MOVE.w	(A0,D0.w), obj_knockback_timer(A5)
DemonBoss_ProjectileSegmentTick_RisingAnim:
	MOVE.l	obj_vel_x(A5), D0
	ADD.l	D0, obj_world_x(A5)
	MOVE.l	obj_vel_y(A5), D0
	ADD.l	D0, obj_world_y(A5)
	JSR	CheckEntityPlayerCollisionAndDamage(PC)
DemonBoss_ProjectileSegmentTick_RenderAndReturn:
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList(PC)
DemonBoss_ProjectileSegmentTick_Render:
	RTS

; DemonBossProjectileTileFrames
; Animation frame table for demon boss projectile segments.
; Five word entries (indices 0-4) giving VRAM tile offsets ($0, $8, $10, $18, $20).
; Indexed via obj_knockback_timer as a tile-offset selector.
DemonBossProjectileTileFrames:
	dc.w	$0
	dc.w	$8 
	dc.w	$10 
	dc.w	$18 
	dc.w	$20 

;==============================================================
; ORBIT BOSS — INIT
;==============================================================
; InitOrbitBoss
; Initialises the orbit boss main entity: activates it, clears velocity,
; plays the earthquake sound, sets HP/damage constants, and installs
; OrbitBoss_MainTick as the tick function.
InitOrbitBoss:
	MOVEA.l	Enemy_list_ptr.w, A6
	BSET.b	#7, (A6)
	CLR.b	obj_move_counter(A6)
	CLR.b	obj_invuln_timer(A6)
	CLR.l	obj_vel_x(A6)
	MOVE.w	#0, D0
	JSR	QueueSoundEffect
	PlaySound	SOUND_TERRAFISSI
	CLR.l	obj_hp(A6)
	MOVE.w	#$0016, D0
	ASL.w	#3, D0
	MOVE.w	D0, obj_knockback_timer(A6)
	MOVE.w	#BOSS_DMG_ORBIT_PART, obj_max_hp(A6)
	MOVE.l	#OrbitBoss_MainTick, obj_tick_fn(A6)
	CLR.b	Boss_defeated_flag.w
	CLR.b	Boss_death_anim_done.w
	RTS
	
; OrbitBoss_MainTick
; Entry tick while the earthquake intro is running.
; Counts down obj_knockback_timer, applies horizontal screen shake from
; TerrafissiShakeDisplacementTable, then transitions to OrbitBoss_InitParts
; once the timer expires and plays the boss battle music.
OrbitBoss_MainTick:
	BSR.w	CheckBossDamageAndKnockback
	TST.w	obj_knockback_timer(A5)
	BLE.b	OrbitBoss_MainTick_Loop
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
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$00E0, D0
	CMPI.w	#$00C0, D0
	BLT.b	OrbitBoss_MainTick_DrawPhase
	RTS
	
OrbitBoss_MainTick_DrawPhase:
	ASR.w	#5, D0
	BSR.w	WriteTilesToVRAM
	RTS
	
OrbitBoss_MainTick_Loop:
	PlaySound	SOUND_ORBIT_BOSS_MUSIC
	MOVE.l	#OrbitBoss_InitParts, obj_tick_fn(A5)
	CLR.l	HScroll_base.w
	RTS
	
; OrbitBoss_InitParts
; Spawns and initialises all inner-ring and outer-ring satellite objects.
; Sets up two groups of four satellites each with initial orbit radii,
; hitboxes, HP, and assigns OrbitBoss_SatelliteAnimate as their tick function.
; Transitions the main entity to OrbitBoss_InnerCheckVictory.
OrbitBoss_InitParts:
	MOVE.b	#4, Boss_ai_state.w
	MOVEA.l	Object_slot_01_ptr.w, A6
	BSET.b	#7, (A6)
	MOVE.l	#OrbitBoss_InnerExpandOrbit, obj_tick_fn(A6)
	MOVE.b	#ORBIT_BOSS_PART_SPAWN_INVULN, obj_invuln_timer(A6)
	MOVE.b	#$F0, obj_hitbox_x_neg(A6)
	MOVE.b	#$10, obj_hitbox_x_pos(A6)
	MOVE.b	#SOUND_LEVEL_UP, obj_hitbox_y_neg(A6)
	MOVE.b	#$F9, obj_hitbox_y_pos(A6)
	MOVE.w	#BOSS_DMG_ORBIT_PART, obj_max_hp(A6)
	MOVE.w	#BOSS_HP_ORBIT_PART, obj_hp(A6)
	MOVE.w	#$0032, D4
	MOVE.w	D4, D2
	MOVE.w	#3, D7
OrbitBoss_InitParts_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BSET.b	#7, (A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A6)
	MOVE.w	#VRAM_TILE_ORBIT_BOSS_RING, obj_tile_index(A6)
	MOVE.w	#$0100, obj_hitbox_half_w(A6)
	MOVE.w	#$0088, obj_hitbox_half_h(A6)
	MOVE.b	#$F0, obj_hitbox_x_neg(A6)
	MOVE.b	#$10, obj_hitbox_x_pos(A6)
	MOVE.b	#SOUND_LEVEL_UP, obj_hitbox_y_neg(A6)
	MOVE.b	#$F9, obj_hitbox_y_pos(A6)
	MOVE.w	#BOSS_DMG_ORBIT_PART, obj_max_hp(A6)
	MOVE.w	#SORT_KEY_ORBIT_INNER, obj_sort_key(A6)
	MOVE.b	#ORBIT_ANGLE_INIT_INNER, obj_direction(A6)
	MOVE.w	D2, obj_pos_x_fixed(A6)
	MOVE.w	D7, D6
	ASL.w	#2, D6
	MOVE.b	D6, obj_move_counter(A6)
	MOVE.l	#OrbitBoss_SatelliteAnimate, obj_tick_fn(A6)
	ADD.w	D4, D2
	DBF	D7, OrbitBoss_InitParts_Done
	MOVE.b	#4, Boss_part_count.w
	MOVEA.l	Object_slot_03_ptr.w, A6
	BSET.b	#7, (A6)
	MOVE.l	#OrbitBoss_OuterExpandOrbit, obj_tick_fn(A6)
	MOVE.b	#ORBIT_BOSS_PART_SPAWN_INVULN, obj_invuln_timer(A6)
	MOVE.b	#$F0, obj_hitbox_x_neg(A6)
	MOVE.b	#$10, obj_hitbox_x_pos(A6)
	MOVE.b	#SOUND_LEVEL_UP, obj_hitbox_y_neg(A6)
	MOVE.b	#$F9, obj_hitbox_y_pos(A6)
	MOVE.w	#BOSS_DMG_ORBIT_PART, obj_max_hp(A6)
	MOVE.w	#BOSS_HP_ORBIT_PART, obj_hp(A6)
	MOVE.w	#$0032, D4
	MOVE.w	D4, D2
	MOVE.w	#3, D7
OrbitBoss_InitParts_OuterRingSlotLoop:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BSET.b	#7, (A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A6)
	MOVE.w	#VRAM_TILE_ORBIT_BOSS_RING, obj_tile_index(A6)
	MOVE.w	#$0100, obj_hitbox_half_w(A6)
	MOVE.w	#$0088, obj_hitbox_half_h(A6)
	MOVE.b	#$F0, obj_hitbox_x_neg(A6)
	MOVE.b	#$10, obj_hitbox_x_pos(A6)
	MOVE.b	#SOUND_LEVEL_UP, obj_hitbox_y_neg(A6)
	MOVE.b	#$F9, obj_hitbox_y_pos(A6)
	MOVE.w	#BOSS_DMG_ORBIT_PART, obj_max_hp(A6)
	MOVE.w	#SORT_KEY_ORBIT_OUTER, obj_sort_key(A6)
	MOVE.b	#ORBIT_ANGLE_INIT_OUTER, obj_direction(A6)
	MOVE.w	D2, obj_pos_x_fixed(A6)
	MOVE.w	D7, D6
	ASL.w	#2, D6
	MOVE.b	D6, obj_move_counter(A6)
	MOVE.l	#OrbitBoss_SatelliteAnimate, obj_tick_fn(A6)
	ADD.w	D4, D2
	DBF	D7, OrbitBoss_InitParts_OuterRingSlotLoop
	MOVE.l	#OrbitBoss_InnerCheckVictory, obj_tick_fn(A5)
	RTS
	

;==============================================================
; ORBIT BOSS — INNER RING AI
;==============================================================
; OrbitBoss_InnerCheckVictory
; Checks whether both Boss_defeated_flag and Boss_death_anim_done are set.
; If so, loads the victory palette and transitions to OrbitBoss_InnerVictoryDelay.
; Otherwise falls through to CheckBossDamageAndKnockback.
OrbitBoss_InnerCheckVictory:
	TST.b	Boss_defeated_flag.w
	BEQ.b	CheckBossDamageAndKnockback
	TST.b	Boss_death_anim_done.w
	BEQ.b	CheckBossDamageAndKnockback
	MOVE.w	#$00B8, Palette_line_1_index.w
	JSR	LoadPalettesFromTable
	CLR.w	Dialog_timer.w
	CLR.w	Dialog_phase.w
	MOVE.w	#ORBIT_BOSS_VICTORY_DELAY, obj_attack_timer(A5)
	PlaySound	SOUND_DOOR_OPEN
	MOVE.l	#OrbitBoss_InnerVictoryDelay, obj_tick_fn(A5)
; CheckBossDamageAndKnockback
; Applies player-collision damage knockback to the main orbit boss entity.
; Calls CheckPlayerDamageAndKnockback with a fixed Y-clamp of $00D8.
CheckBossDamageAndKnockback:
	MOVE.w	#$00D8, D1
	JSR	CheckPlayerDamageAndKnockback
	RTS
	
; OrbitBoss_InnerVictoryDelay
; Countdown delay after inner ring defeat before showing the victory dialog.
; Decrements obj_attack_timer; when it reaches zero plays the victory sound
; and transitions to RingGuardian_VictoryDialogContinue.
OrbitBoss_InnerVictoryDelay:
	SUBQ.w	#1, obj_attack_timer(A5)
	BGE.b	OrbitBoss_InnerVictoryDelay_Loop
	PlaySound	SOUND_PURCHASE
	MOVE.l	#RingGuardian_VictoryDialogContinue, obj_tick_fn(A5)
OrbitBoss_InnerVictoryDelay_Loop:
	RTS
	
; OrbitBoss_InnerExpandOrbit
; Expands the inner ring satellites outward each tick until they reach
; ORBIT_BOSS_MAX_RADIUS, then transitions to OrbitBoss_InnerSelectTarget.
OrbitBoss_InnerExpandOrbit:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	CMPI.w	#ORBIT_BOSS_MAX_RADIUS, obj_pos_x_fixed(A6)
	BLT.b	OrbitBoss_InnerExpandOrbit_Loop
	CLR.b	obj_move_counter(A5)
	MOVE.l	#OrbitBoss_InnerSelectTarget, obj_tick_fn(A5)
	RTS
	
OrbitBoss_InnerExpandOrbit_Loop:
	MOVE.w	#$0032, D4
	MOVE.w	D4, D2
	MOVE.w	#3, D7
OrbitBoss_InnerExpandOrbit_Loop_Done:
	ADD.w	D2, obj_pos_x_fixed(A6)
	ADD.w	D4, D2
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, OrbitBoss_InnerExpandOrbit_Loop_Done
	RTS
	
; OrbitBoss_InnerSelectTarget
; Selects which inner-ring satellite will be the active attacker this round.
; Walks the object chain by Boss_ai_state steps, activates that satellite's
; position tracking, idles the remaining ones, then sets OrbitBoss_InnerApproach.
OrbitBoss_InnerSelectTarget:
	LEA	(A5), A6
	CLR.w	D7
	MOVE.b	Boss_ai_state.w, D7
	SUBQ.w	#1, D7
OrbitBoss_InnerSelectTarget_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, OrbitBoss_InnerSelectTarget_Done
	LEA	OrbitBoss_InnerSatelliteFrame, A0
	MOVE.w	(A0), obj_tile_index(A6)
	MOVE.l	#OrbitBoss_SatelliteUpdatePosition, obj_tick_fn(A6)
	MOVE.w	obj_world_x(A6), obj_world_x(A5)
	MOVE.w	obj_world_y(A6), obj_world_y(A5)
	LEA	(A5), A6
	CLR.w	D7
	MOVE.b	Boss_ai_state.w, D7
	SUBQ.w	#2, D7
	BLT.b	OrbitBoss_InnerSelectTarget_Loop
OrbitBoss_InnerSelectTarget_InactivateLoop:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	MOVE.l	#OrbitBoss_SatelliteOrbitInactive, obj_tick_fn(A6)
	DBF	D7, OrbitBoss_InnerSelectTarget_InactivateLoop
OrbitBoss_InnerSelectTarget_Loop:
	MOVE.l	#OrbitBoss_InnerApproach, obj_tick_fn(A5)
	MOVE.w	#ORBIT_BOSS_APPROACH_TICKS, obj_attack_timer(A5)
	CLR.b	orbit_charge_dir(A5)
	JSR	ProcessPlayerStrengthCheck
	RTS
	
; OrbitBoss_InnerApproach
; Moves the active inner satellite toward the player during the approach phase.
; Tracks the chosen satellite's screen position, checks invulnerability delay,
; and transitions to OrbitBoss_InnerCharge when the player is within range.
OrbitBoss_InnerApproach:
	LEA	(A5), A6
	CLR.w	D7
	MOVE.b	Boss_ai_state.w, D7
	SUBQ.w	#1, D7
OrbitBoss_InnerApproach_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, OrbitBoss_InnerApproach_Done
	MOVE.w	obj_world_x(A6), obj_world_x(A5)
	MOVE.w	obj_world_y(A6), obj_world_y(A5)
	TST.b	obj_invuln_timer(A5)
	BLE.b	OrbitBoss_InnerApproach_Loop
	SUBQ.b	#1, obj_invuln_timer(A5)
	BRA.b	OrbitBoss_InnerApproach_Tick
OrbitBoss_InnerApproach_Loop:
	MOVEA.l	Player_entity_ptr.w, A4
	MOVE.w	obj_world_x(A5), D0
	SUBI.w	#$0046, D0
	MOVE.w	obj_world_x(A4), D1
	CMP.w	D0, D1
	BLE.b	OrbitBoss_InnerApproach_Tick
	JSR	GetRandomNumber
	ANDI.b	#1, D0
	MOVE.b	D0, Boss_attack_direction.w
	MOVE.l	#OrbitBoss_InnerCharge, obj_tick_fn(A5)
	MOVE.w	#ORBIT_BOSS_CHARGE_TICKS, obj_attack_timer(A5)
	MOVE.b	#$FF, orbit_charge_dir(A5)
	RTS
	
OrbitBoss_InnerApproach_Tick:
	BSR.w	GetSignedVelocity
	ADD.w	D0, obj_direction(A6)
	TST.b	orbit_charge_dir(A5)
	BGE.b	OrbitBoss_InnerApproach_Tick_Loop
	CMPI.b	#ORBIT_APPROACH_ANGLE_MIN, obj_direction(A6)
	BGT.b	OrbitBoss_InnerApproach_ClampDone
	MOVE.b	#ORBIT_APPROACH_ANGLE_MIN, obj_direction(A6)
	CLR.b	orbit_charge_dir(A5)
	BRA.b	OrbitBoss_InnerApproach_ClampDone
OrbitBoss_InnerApproach_Tick_Loop:
	CMPI.b	#ORBIT_APPROACH_ANGLE_MAX, obj_direction(A6)
	BLT.b	OrbitBoss_InnerApproach_ClampDone
	MOVE.b	#ORBIT_APPROACH_ANGLE_MAX, obj_direction(A6)
	MOVE.b	#$FF, orbit_charge_dir(A5)
OrbitBoss_InnerApproach_ClampDone:
	JSR	ProcessPlayerStrengthCheck
	RTS
	
; OrbitBoss_InnerCharge
; Spins the inner satellite rapidly toward the fire angle.
; Transitions to OrbitBoss_InnerFireAnim (or back to InnerSelectTarget if
; attack direction is set) once ORBIT_BOSS_DIRECTION_WRAP is reached.
OrbitBoss_InnerCharge:
	LEA	(A5), A6
	CLR.w	D7
	MOVE.b	Boss_ai_state.w, D7
	SUBQ.w	#1, D7
OrbitBoss_InnerCharge_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, OrbitBoss_InnerCharge_Done
	MOVE.w	obj_world_x(A6), obj_world_x(A5)
	MOVE.w	obj_world_y(A6), obj_world_y(A5)
	BSR.w	GetSignedVelocity
	ADD.w	D0, obj_direction(A6)
	CMPI.b	#ORBIT_BOSS_DIRECTION_WRAP, obj_direction(A6)
	BGT.b	OrbitBoss_InnerFireWait
	MOVE.b	#SOUND_MENU_CURSOR, obj_direction(A6)
	CLR.b	obj_move_counter(A5)
	MOVE.l	#OrbitBoss_InnerFireAnim, obj_tick_fn(A5)
	TST.b	Boss_attack_direction.w
	BEQ.b	OrbitBoss_InnerFireWait
	MOVE.l	#OrbitBoss_InnerSelectTarget, obj_tick_fn(A5)
	MOVE.b	#BOSS_STATE_DELAY, obj_invuln_timer(A5)
OrbitBoss_InnerFireWait:
	JSR	ProcessPlayerStrengthCheck
	RTS
	
; OrbitBoss_InnerFireAnim
; Plays the pre-fire animation for the inner satellite by cycling through
; OrbitBoss_InnerSatelliteFrame tiles until ORBIT_BOSS_FIRE_PHASE frames pass,
; then transitions to OrbitBoss_InnerSpawnProjectile.
OrbitBoss_InnerFireAnim:
	LEA	(A5), A6
	CLR.w	D7
	MOVE.b	Boss_ai_state.w, D7
	SUBQ.w	#1, D7
OrbitBoss_InnerFireAnim_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, OrbitBoss_InnerFireAnim_Done
	MOVE.w	obj_world_x(A6), obj_world_x(A5)
	MOVE.w	obj_world_y(A6), obj_world_y(A5)
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0070, D0
	CMPI.w	#ORBIT_BOSS_FIRE_PHASE, D0
	BLE.b	OrbitBoss_InnerFireAnim_Loop
	MOVE.l	#OrbitBoss_InnerSpawnProjectile, obj_tick_fn(A5)
	RTS
	
OrbitBoss_InnerFireAnim_Loop:
	ASR.w	#3, D0
	LEA	OrbitBoss_InnerSatelliteFrame, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A6)
	JSR	ProcessPlayerStrengthCheck
	RTS
	
; OrbitBoss_InnerSpawnProjectile
; Spawns a falling projectile from the active inner satellite into Object_slot_02.
; Configures velocity, hitbox, tile, sort key, and assigns
; OrbitBossProjectileFallTick; then sets OrbitBoss_InnerWaitProjectile.
OrbitBoss_InnerSpawnProjectile:
	LEA	(A5), A6
	CLR.w	D7
	MOVE.b	Boss_ai_state.w, D7
	SUBQ.w	#1, D7
OrbitBoss_InnerSpawnProjectile_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, OrbitBoss_InnerSpawnProjectile_Done
	MOVE.w	obj_world_x(A6), obj_world_x(A5)
	MOVE.w	obj_world_y(A6), obj_world_y(A5)
	MOVEA.l	Object_slot_02_ptr.w, A4
	BSET.b	#7, (A4)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A4)
	BCLR.b	#7, obj_sprite_flags(A4)
	BCLR.b	#3, obj_sprite_flags(A4)
	BCLR.b	#4, obj_sprite_flags(A4)
	MOVE.b	#SPRITE_SIZE_3x3, obj_sprite_size(A4)
	MOVE.w	#$00D1, obj_tile_index(A4)
	MOVE.b	#$F4, obj_hitbox_x_neg(A4)
	MOVE.b	#$0C, obj_hitbox_x_pos(A4)
	MOVE.b	#$E8, obj_hitbox_y_neg(A4)
	MOVE.b	#0, obj_hitbox_y_pos(A4)
	MOVE.l	#$FFFD0000, obj_vel_x(A4)
	MOVE.l	#$00030000, obj_vel_y(A4)
	MOVE.w	obj_max_hp(A6), obj_max_hp(A4)
	MOVE.w	obj_world_x(A6), D0
	ADDI.w	#$FFF4, D0
	MOVE.w	D0, obj_world_x(A4)
	MOVE.w	obj_world_y(A6), D0
	ADDI.w	#$0010, D0
	MOVE.w	D0, obj_world_y(A4)
	MOVE.w	#SORT_KEY_BOSS_PROJ, obj_sort_key(A4)
	CLR.b	obj_move_counter(A4)
	MOVE.l	#OrbitBossProjectileFallTick, obj_tick_fn(A4)
	MOVE.l	#OrbitBoss_InnerWaitProjectile, obj_tick_fn(A5)
	RTS
	
; OrbitBoss_InnerWaitProjectile
; Idles the inner ring AI until the projectile in Object_slot_02 is deactivated
; (bit 7 cleared), then returns to OrbitBoss_InnerSelectTarget.
OrbitBoss_InnerWaitProjectile:
	MOVEA.l	Object_slot_02_ptr.w, A6
	BTST.b	#7, (A6)
	BNE.b	OrbitBoss_InnerWaitProjectile_Loop
	MOVE.l	#OrbitBoss_InnerSelectTarget, obj_tick_fn(A5)
OrbitBoss_InnerWaitProjectile_Loop:
	RTS
	

;==============================================================
; ORBIT BOSS — OUTER RING AI
;==============================================================
; OrbitBoss_OuterExpandOrbit
; Expands the outer ring satellites outward each tick until they reach
; ORBIT_BOSS_MAX_RADIUS, then transitions to OrbitBoss_OuterSelectTarget.
; Also calls ProcessBossFightDamage while expanding.
OrbitBoss_OuterExpandOrbit:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	CMPI.w	#ORBIT_BOSS_MAX_RADIUS, obj_pos_x_fixed(A6)
	BLT.b	OrbitBoss_OuterExpandOrbit_Loop
	CLR.b	obj_move_counter(A5)
	MOVE.l	#OrbitBoss_OuterSelectTarget, obj_tick_fn(A5)
	RTS
	
OrbitBoss_OuterExpandOrbit_Loop:
	MOVE.w	#$0032, D4
	MOVE.w	D4, D2
	MOVE.w	#3, D7
OrbitBoss_OuterExpandOrbit_Loop_Done:
	ADD.w	D2, obj_pos_x_fixed(A6)
	ADD.w	D4, D2
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, OrbitBoss_OuterExpandOrbit_Loop_Done
	JSR	ProcessBossFightDamage
	RTS
	
; OrbitBoss_OuterSelectTarget
; Selects the active outer-ring satellite for this attack cycle.
; Mirrors OrbitBoss_InnerSelectTarget but uses Boss_part_count as the
; satellite index. Transitions to OrbitBoss_OuterApproach.
OrbitBoss_OuterSelectTarget:
	LEA	(A5), A6
	CLR.w	D7
	MOVE.b	Boss_part_count.w, D7
	SUBQ.w	#1, D7
OrbitBoss_OuterSelectTarget_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, OrbitBoss_OuterSelectTarget_Done
	LEA	OrbitBoss_InnerSatelliteFrame, A0
	MOVE.w	(A0), obj_tile_index(A6)
	MOVE.l	#OrbitBoss_SatelliteUpdatePosition, obj_tick_fn(A6)
	MOVE.w	obj_world_x(A6), obj_world_x(A5)
	MOVE.w	obj_world_y(A6), obj_world_y(A5)
	LEA	(A5), A6
	CLR.w	D7
	MOVE.b	Boss_part_count.w, D7
	SUBQ.w	#2, D7
	BLT.b	OrbitBoss_OuterSelectTarget_Loop
OrbitBoss_OuterSelectTarget_InactivateLoop:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	MOVE.l	#OrbitBoss_SatelliteOrbitInactive, obj_tick_fn(A6)
	DBF	D7, OrbitBoss_OuterSelectTarget_InactivateLoop
OrbitBoss_OuterSelectTarget_Loop:
	MOVE.l	#OrbitBoss_OuterApproach, obj_tick_fn(A5)
	MOVE.w	#ORBIT_BOSS_APPROACH_TICKS, obj_attack_timer(A5)
	CLR.b	orbit_charge_dir(A5)
	JSR	ProcessBossFightDamage
	RTS
	
; OrbitBoss_OuterApproach
; Moves the active outer satellite toward the player.
; Mirrors OrbitBoss_InnerApproach but checks ORBIT_BOSS_CHARGE_X_MIN and
; uses ProcessBossFightDamage; transitions to OrbitBoss_OuterCharge.
OrbitBoss_OuterApproach:
	LEA	(A5), A6
	CLR.w	D7
	MOVE.b	Boss_part_count.w, D7
	SUBQ.w	#1, D7
OrbitBoss_OuterApproach_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, OrbitBoss_OuterApproach_Done
	MOVE.w	obj_world_x(A6), obj_world_x(A5)
	MOVE.w	obj_world_y(A6), obj_world_y(A5)
	TST.b	obj_invuln_timer(A5)
	BLE.b	OrbitBoss_OuterApproach_Loop
	SUBQ.b	#1, obj_invuln_timer(A5)
	BRA.b	OrbitBoss_OuterApproach_Tick
OrbitBoss_OuterApproach_Loop:
	MOVEA.l	Player_entity_ptr.w, A4
	CMPI.w	#ORBIT_BOSS_CHARGE_X_MIN, obj_world_x(A4)
	BLE.b	OrbitBoss_OuterApproach_Tick
	MOVE.w	#ORBIT_BOSS_CHARGE_TICKS, obj_attack_timer(A5)
	MOVE.b	#$FF, orbit_charge_dir(A5)
	MOVE.l	#OrbitBoss_OuterCharge, obj_tick_fn(A5)
	RTS
	
OrbitBoss_OuterApproach_Tick:
	BSR.w	GetSignedVelocity
	ADD.w	D0, obj_direction(A6)
	TST.b	orbit_charge_dir(A5)
	BGE.b	OrbitBoss_OuterApproach_Tick_Loop
	CMPI.b	#ORBIT_APPROACH_ANGLE_MIN, obj_direction(A6)
	BGT.b	OrbitBoss_OuterApproach_ClampDone
	MOVE.b	#ORBIT_APPROACH_ANGLE_MIN, obj_direction(A6)
	CLR.b	orbit_charge_dir(A5)
	BRA.b	OrbitBoss_OuterApproach_ClampDone
OrbitBoss_OuterApproach_Tick_Loop:
	CMPI.b	#ORBIT_APPROACH_ANGLE_MAX, obj_direction(A6)
	BLT.b	OrbitBoss_OuterApproach_ClampDone
	MOVE.b	#ORBIT_APPROACH_ANGLE_MAX, obj_direction(A6)
	MOVE.b	#$FF, orbit_charge_dir(A5)
OrbitBoss_OuterApproach_ClampDone:
	JSR	ProcessBossFightDamage
	RTS
	
; OrbitBoss_OuterCharge
; Spins the outer satellite toward the fire angle.
; Transitions to OrbitBoss_OuterFireAnim (or back to OuterSelectTarget)
; once ORBIT_APPROACH_ANGLE_MIN is reached.
OrbitBoss_OuterCharge:
	LEA	(A5), A6
	CLR.w	D7
	MOVE.b	Boss_part_count.w, D7
	SUBQ.w	#1, D7
OrbitBoss_OuterCharge_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, OrbitBoss_OuterCharge_Done
	MOVE.w	obj_world_x(A6), obj_world_x(A5)
	MOVE.w	obj_world_y(A6), obj_world_y(A5)
	BSR.w	GetSignedVelocity
	ADD.w	D0, obj_direction(A6)
	CMPI.b	#ORBIT_APPROACH_ANGLE_MIN, obj_direction(A6)
	BGT.b	OrbitBoss_OuterFireWait
	MOVE.b	#ORBIT_APPROACH_ANGLE_MIN, obj_direction(A6)
	CLR.b	obj_move_counter(A5)
	MOVE.l	#OrbitBoss_OuterFireAnim, obj_tick_fn(A5)
	TST.b	Boss_attack_direction.w
	BNE.b	OrbitBoss_OuterFireWait
	MOVE.l	#OrbitBoss_OuterSelectTarget, obj_tick_fn(A5)
	MOVE.b	#BOSS_STATE_DELAY, obj_invuln_timer(A5)
OrbitBoss_OuterFireWait:
	JSR	ProcessBossFightDamage
	RTS
	
; OrbitBoss_OuterFireAnim
; Pre-fire animation for the outer satellite, cycling tile frames until
; ORBIT_BOSS_FIRE_PHASE is reached, then transitions to OrbitBoss_OuterSpawnProjectile.
OrbitBoss_OuterFireAnim:
	LEA	(A5), A6
	CLR.w	D7
	MOVE.b	Boss_part_count.w, D7
	SUBQ.w	#1, D7
OrbitBoss_OuterFireAnim_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, OrbitBoss_OuterFireAnim_Done
	MOVE.w	obj_world_x(A6), obj_world_x(A5)
	MOVE.w	obj_world_y(A6), obj_world_y(A5)
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0070, D0
	CMPI.w	#ORBIT_BOSS_FIRE_PHASE, D0
	BLE.b	OrbitBoss_OuterFireAnim_Loop
	MOVE.l	#OrbitBoss_OuterSpawnProjectile, obj_tick_fn(A5)
	RTS
	
OrbitBoss_OuterFireAnim_Loop:
	ASR.w	#3, D0
	LEA	OrbitBoss_InnerSatelliteFrame, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A6)
	JSR	ProcessBossFightDamage
	RTS
	
; OrbitBoss_OuterSpawnProjectile
; Spawns a falling projectile from the active outer satellite into Object_slot_04.
; Configuration mirrors InnerSpawnProjectile; transitions to OrbitBoss_OuterWaitProjectile.
OrbitBoss_OuterSpawnProjectile:
	LEA	(A5), A6
	CLR.w	D7
	MOVE.b	Boss_part_count.w, D7
	SUBQ.w	#1, D7
OrbitBoss_OuterSpawnProjectile_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, OrbitBoss_OuterSpawnProjectile_Done
	MOVE.w	obj_world_x(A6), obj_world_x(A5)
	MOVE.w	obj_world_y(A6), obj_world_y(A5)
	MOVEA.l	Object_slot_04_ptr.w, A4
	BSET.b	#7, (A4)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A4)
	BCLR.b	#7, obj_sprite_flags(A4)
	BCLR.b	#3, obj_sprite_flags(A4)
	BCLR.b	#4, obj_sprite_flags(A4)
	MOVE.b	#SPRITE_SIZE_3x3, obj_sprite_size(A4)
	MOVE.w	#$00D1, obj_tile_index(A4)
	MOVE.b	#$F4, obj_hitbox_x_neg(A4)
	MOVE.b	#$0C, obj_hitbox_x_pos(A4)
	MOVE.b	#$E8, obj_hitbox_y_neg(A4)
	MOVE.b	#0, obj_hitbox_y_pos(A4)
	MOVE.l	#$FFFD0000, obj_vel_x(A4)
	MOVE.l	#$00030000, obj_vel_y(A4)
	MOVE.w	obj_max_hp(A6), obj_max_hp(A4)
	MOVE.w	obj_world_x(A6), D0
	ADDI.w	#$FFF4, D0
	MOVE.w	D0, obj_world_x(A4)
	MOVE.w	obj_world_y(A6), D0
	ADDI.w	#$0010, D0
	MOVE.w	D0, obj_world_y(A4)
	MOVE.w	#SORT_KEY_BOSS_PROJ, obj_sort_key(A4)
	CLR.b	obj_move_counter(A4)
	MOVE.l	#OrbitBossProjectileFallTick, obj_tick_fn(A4)
	MOVE.l	#OrbitBoss_OuterWaitProjectile, obj_tick_fn(A5)
	RTS
	
; OrbitBoss_OuterSpawnProjectile_DeadCode
; Dead code — unreferenced alternative wait loop that checks Object_slot_02.
; Superseded by OrbitBoss_OuterWaitProjectile below.
OrbitBoss_OuterSpawnProjectile_DeadCode:					; unreferenced dead code
	MOVEA.l	Object_slot_02_ptr.w, A6
	BTST	#7, (A6)
	BNE.b	OrbitBoss_OuterSpawnProjectile_Loop
	MOVE.l	#OrbitBoss_OuterSelectTarget, obj_tick_fn(A5)
OrbitBoss_OuterSpawnProjectile_Loop:
	JSR	ProcessBossFightDamage
	RTS
; OrbitBoss_OuterWaitProjectile
; Idles the outer ring AI until the projectile in Object_slot_04 is deactivated,
; then returns to OrbitBoss_OuterSelectTarget.
OrbitBoss_OuterWaitProjectile:
	MOVEA.l	Object_slot_04_ptr.w, A6
	BTST.b	#7, (A6)
	BNE.b	OrbitBoss_OuterWaitProjectile_Loop
	MOVE.l	#OrbitBoss_OuterSelectTarget, obj_tick_fn(A5)
OrbitBoss_OuterWaitProjectile_Loop:
	JSR	ProcessBossFightDamage
	RTS


;==============================================================
; ORBIT BOSS — SHARED HELPERS + PROJECTILES
;==============================================================
; GetSignedVelocity
; Returns a signed angular velocity for satellite orbital movement.
; Inputs: obj_attack_timer(A5) = magnitude, orbit_charge_dir(A5) = sign flag
; Outputs: D0.w = velocity (negated if orbit_charge_dir < 0)
GetSignedVelocity:
	MOVE.w	obj_attack_timer(A5), D0
	TST.b	orbit_charge_dir(A5)
	BGE.b	GetSignedVelocity_Loop
	NEG.w	D0
GetSignedVelocity_Loop:
	RTS

; OrbitBossProjectileFallTick
; Per-frame tick for a falling orbit boss projectile.
; Cycles through OrbitBoss_ProjectileFallFrames for animation, applies
; velocity, clamps to ORBIT_PROJ_Y_FLOOR, checks player collision,
; and transitions to OrbitBoss_ProjectileExplode on landing.
OrbitBossProjectileFallTick:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$001C, D0
	CMPI.w	#$0014, D0
	BLE.b	OrbitBossProjectileFallTick_Loop
	MOVE.w	#$0028, D0
OrbitBossProjectileFallTick_Loop:
	ASR.w	#1, D0
	LEA	OrbitBoss_ProjectileFallFrames, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.l	obj_vel_x(A5), D0
	ADD.l	D0, obj_world_x(A5)
	MOVE.l	obj_vel_y(A5), D0
	ADD.l	D0, obj_world_y(A5)
	CMPI.w	#ORBIT_PROJ_Y_FLOOR, obj_world_y(A5)
	BLE.b	OrbitBossProjectileFallTick_RenderAndReturn
	MOVE.w	#ORBIT_PROJ_Y_FLOOR, obj_world_y(A5)
	CLR.b	obj_move_counter(A5)
	MOVE.l	#OrbitBoss_ProjectileExplode, obj_tick_fn(A5)
OrbitBossProjectileFallTick_RenderAndReturn:
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	CheckEntityPlayerCollisionAndDamage
	JSR	AddSpriteToDisplayList
	RTS

; OrbitBoss_ProjectileExplode
; Plays the projectile explosion animation using OrbitBoss_ProjectileExplodeFrames.
; Checks player collision during the explosion; deactivates the object when done.
OrbitBoss_ProjectileExplode:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0038, D0
	CMPI.w	#$0018, D0
	BLE.b	OrbitBoss_ProjectileExplode_Loop
	BCLR.b	#7, (A5)
	RTS

OrbitBoss_ProjectileExplode_Loop:
	ASR.w	#2, D0
	LEA	OrbitBoss_ProjectileExplodeFrames-2, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	CheckEntityPlayerCollisionAndDamage
	JSR	AddSpriteToDisplayList
	RTS


;==============================================================
; ORBIT BOSS — DAMAGE + DEATH
;==============================================================
; ProcessPlayerStrengthCheck
; Handles damage and hit-stun for inner-ring satellite parts.
; Decrements knockback timer if active; otherwise checks obj_hit_flag,
; flashes palette, applies Player_str damage, and transitions to
; OrbitBoss_InnerPartDeath if HP reaches zero.
ProcessPlayerStrengthCheck:
	TST.w	obj_knockback_timer(A5)
	BLE.b	ProcessPlayerStrengthCheck_Loop
	SUBQ.w	#1, obj_knockback_timer(A5)
	JSR	UpdateEncounterPalette
	BRA.w	OrbitBoss_InnerPartHit_Return
ProcessPlayerStrengthCheck_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.b	OrbitBoss_InnerPartHit_Return
	MOVE.w	#PALETTE_IDX_BOSS_FLASH_B, Palette_line_1_index.w
	JSR	LoadPalettesFromTable
	MOVE.w	Player_str.w, D0
	SUB.w	D0, obj_hp(A5)
	BGT.b	ProcessPlayerStrengthCheck_SetHitStun
	PlaySound	SOUND_MAGIC_EFFECT
	CLR.b	obj_move_counter(A5)
	MOVE.l	#OrbitBoss_InnerPartDeath, obj_tick_fn(A5)
	RTS

ProcessPlayerStrengthCheck_SetHitStun:
	PlaySound	SOUND_HEAL
	MOVE.w	#BOSS_HIT_STUN_FRAMES, obj_knockback_timer(A5)
OrbitBoss_InnerPartHit_Return:
	CLR.b	obj_hit_flag(A5)
	RTS

; OrbitBoss_InnerPartDeath
; Death animation for a defeated inner-ring satellite.
; Plays explosion frames via OrbitBoss_ProjectileFrames; when complete,
; deactivates the satellite, restores HP, and decrements Boss_ai_state.
; If all inner satellites are defeated, transitions to OrbitBoss_InnerRingDefeated.
OrbitBoss_InnerPartDeath:
	BSR.w	UpdateEncounterPalette
	LEA	(A5), A6
	CLR.w	D7
	MOVE.b	Boss_ai_state.w, D7
	SUBQ.w	#1, D7
OrbitBoss_InnerPartDeath_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, OrbitBoss_InnerPartDeath_Done
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0070, D0
	CMPI.w	#ORBIT_BOSS_FIRE_PHASE, D0
	BLT.b	OrbitBoss_InnerPartDeath_Loop
	BCLR.b	#7, (A6)
	CLR.b	obj_hit_flag(A5)
	MOVE.w	#BOSS_HP_ORBIT_PART, obj_hp(A5)
	MOVE.l	#OrbitBoss_InnerSelectTarget, obj_tick_fn(A5)
	SUBQ.b	#1, Boss_ai_state.w
	BGT.b	OrbitBoss_InnerPartDeath_RingDefeated
	MOVE.l	#OrbitBoss_InnerRingDefeated, obj_tick_fn(A5)
OrbitBoss_InnerPartDeath_RingDefeated:
	RTS

OrbitBoss_InnerPartDeath_Loop:
	ASR.w	#3, D0
	LEA	OrbitBoss_ProjectileFrames, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A6)
	RTS

; OrbitBoss_InnerRingDefeated
; Sets Boss_defeated_flag to signal that the inner ring has been cleared.
OrbitBoss_InnerRingDefeated:
	MOVE.b	#FLAG_TRUE, Boss_defeated_flag.w
	RTS

; ProcessBossFightDamage
; Handles damage and hit-stun for outer-ring satellite parts.
; Mirrors ProcessPlayerStrengthCheck but transitions to OrbitBoss_OuterPartDeath
; on death instead.
ProcessBossFightDamage:
	TST.w	obj_knockback_timer(A5)
	BLE.b	ProcessBossFightDamage_Loop
	SUBQ.w	#1, obj_knockback_timer(A5)
	JSR	UpdateEncounterPalette
	BRA.w	OrbitBoss_OuterPartHit_Return
ProcessBossFightDamage_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.b	OrbitBoss_OuterPartHit_Return
	MOVE.w	#PALETTE_IDX_BOSS_FLASH_B, Palette_line_1_index.w
	JSR	LoadPalettesFromTable
	MOVE.w	Player_str.w, D0
	SUB.w	D0, obj_hp(A5)
	BGT.b	ProcessBossFightDamage_SetHitStun
	PlaySound	SOUND_MAGIC_EFFECT
	CLR.b	obj_move_counter(A5)
	MOVE.l	#OrbitBoss_OuterPartDeath, obj_tick_fn(A5)
	RTS

ProcessBossFightDamage_SetHitStun:
	PlaySound	SOUND_HEAL
	MOVE.w	#BOSS_HIT_STUN_FRAMES, obj_knockback_timer(A5)
OrbitBoss_OuterPartHit_Return:
	CLR.b	obj_hit_flag(A5)
	RTS

; OrbitBoss_OuterPartDeath
; Death animation for a defeated outer-ring satellite.
; Mirrors OrbitBoss_InnerPartDeath but decrements Boss_part_count.
; If all outer satellites are defeated, transitions to OrbitBoss_OuterRingDefeated.
OrbitBoss_OuterPartDeath:
	BSR.w	UpdateEncounterPalette
	LEA	(A5), A6
	CLR.w	D7
	MOVE.b	Boss_part_count.w, D7
	SUBQ.w	#1, D7
OrbitBoss_OuterPartDeath_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, OrbitBoss_OuterPartDeath_Done
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0070, D0
	CMPI.w	#ORBIT_BOSS_FIRE_PHASE, D0
	BLT.b	OrbitBoss_OuterPartDeath_Loop
	BCLR.b	#7, (A6)
	CLR.b	obj_hit_flag(A5)
	MOVE.w	#BOSS_HP_ORBIT_PART, obj_hp(A5)
	MOVE.l	#OrbitBoss_OuterSelectTarget, obj_tick_fn(A5)
	SUBQ.b	#1, Boss_part_count.w
	BGT.b	OrbitBoss_OuterPartDeath_RingDefeated
	MOVE.l	#OrbitBoss_OuterRingDefeated, obj_tick_fn(A5)
OrbitBoss_OuterPartDeath_RingDefeated:
	RTS

OrbitBoss_OuterPartDeath_Loop:
	ASR.w	#3, D0
	LEA	OrbitBoss_ProjectileFrames, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A6)
	RTS

; OrbitBoss_OuterRingDefeated
; Sets Boss_death_anim_done to signal that the outer ring has been cleared.
OrbitBoss_OuterRingDefeated:
	MOVE.b	#FLAG_TRUE, Boss_death_anim_done.w
	RTS


;==============================================================
; ORBIT BOSS — SATELLITE ANIMATION
;==============================================================
; OrbitBoss_SatelliteOrbitInactive
; Tick for a satellite that is not the current attacker.
; Calculates direction to the next object in chain, then falls through
; to OrbitBoss_SatelliteAnimate to cycle the idle animation.
OrbitBoss_SatelliteOrbitInactive:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	BSR.w	CalculateDirectionToEntity
; OrbitBoss_SatelliteAnimate
; Advances the satellite idle animation by cycling through OrbitBoss_SatelliteFrames,
; then falls through to OrbitBoss_SatelliteUpdatePosition.
OrbitBoss_SatelliteAnimate:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0018, D0
	ASR.w	#2, D0
	LEA	OrbitBoss_SatelliteFrames, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
; OrbitBoss_SatelliteUpdatePosition
; Recomputes the satellite's world position from its orbit parameters.
; Calls CalculateSineVelocity to get X/Y velocity components, adds the
; orbit centre offset, then checks collision and queues the sprite.
OrbitBoss_SatelliteUpdatePosition:
	BSR.w	CalculateSineVelocity
	MOVE.w	obj_vel_x(A5), D0
	ADD.w	obj_hitbox_half_w(A5), D0
	MOVE.w	D0, obj_world_x(A5)
	MOVE.w	obj_vel_y(A5), D0
	ADD.w	obj_hitbox_half_h(A5), D0
	MOVE.w	D0, obj_world_y(A5)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	CheckEntityPlayerCollisionAndDamage
	JSR	AddSpriteToDisplayList
	RTS


;==============================================================
; ORBIT BOSS — MATH HELPERS
;==============================================================
; CalculateSineVelocity
; Computes orbit velocity components from a radius and angle using SineTable.
; Inputs: obj_pos_x_fixed(A5) = orbit radius, obj_direction(A5) = angle (0-$3F)
; Outputs: obj_vel_x(A5), obj_vel_y(A5) = scaled sine/cosine velocity (long)
CalculateSineVelocity:
	LEA	SineTable, A0
	MOVE.w	obj_pos_x_fixed(A5), D0
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	MOVE.b	(A0,D1.w), D2
	MOVE.b	$40(A0,D1.w), D3
	EXT.w	D2
	EXT.w	D3
	MULS.w	D0, D2
	MULS.w	D0, D3
	ASL.l	#1, D2
	ASL.l	#1, D3
	MOVE.l	D2, obj_vel_x(A5)
	MOVE.l	D3, obj_vel_y(A5)
	RTS


;==============================================================
; HYDRA BOSS — INIT
;==============================================================
; InitHydraBoss_Normal
; Entry point for normal-difficulty Hydra boss: sets normal HP/damage,
; then falls through to InitHydraBoss_Common.
InitHydraBoss_Normal:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#BOSS_HP_HYDRA_NORMAL, obj_hp(A6)
	MOVE.w	#BOSS_DMG_HYDRA_NORMAL, obj_max_hp(A6)
	BRA.w	InitHydraBoss_Common
; InitHydraBoss_Hard
; Entry point for hard-difficulty Hydra boss: sets hard HP/damage,
; then falls through to InitHydraBoss_Common.
InitHydraBoss_Hard:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#BOSS_HP_HYDRA_HARD, obj_hp(A6)
	MOVE.w	#BOSS_DMG_HYDRA_HARD, obj_max_hp(A6)
; InitHydraBoss_Common
; Shared Hydra boss initialisation: resets AI state and active-part counter,
; sets up the main body sprite object and two additional body-segment objects,
; then initialises the first two active body parts via InitBossBodyPart.
InitHydraBoss_Common:
	CLR.w	Boss_ai_state.w
	CLR.w	Boss_active_parts.w
	MOVEA.l	Enemy_list_ptr.w, A6
	BSET.b	#7, (A6)
	MOVE.b	#$F4, obj_hitbox_x_neg(A6)
	MOVE.b	#$0C, obj_hitbox_x_pos(A6)
	MOVE.b	#$C8, obj_hitbox_y_neg(A6)
	MOVE.b	#0, obj_hitbox_y_pos(A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.w	#BOSS_BATTLE_PLAYER_X_MAX, obj_world_x(A6)
	MOVE.w	#ORBIT_PROJ_Y_FLOOR, obj_world_y(A6)
	MOVE.w	obj_world_y(A6), obj_sort_key(A6)
	CLR.b	obj_move_counter(A6)
	MOVE.l	#HydraBoss_MainTick, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BSET.b	#7, (A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A6)
	MOVE.w	#BOSS_BATTLE_PLAYER_X_MAX, obj_world_x(A6)
	MOVE.w	#$0094, obj_world_y(A6)
	MOVE.w	#SORT_KEY_HYDRA_HEAD, obj_sort_key(A6)
	MOVE.l	#BossCommon_DisplaySprite, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BSET.b	#7, (A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_3x1, obj_sprite_size(A6)
	MOVE.w	#$0114, obj_world_x(A6)
	MOVE.w	#$0094, obj_world_y(A6)
	MOVE.l	#BossCommon_DisplaySprite, obj_tick_fn(A6)
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.w	#1, D7
	MOVE.w	#$0078, D6
InitHydraBoss_Common_Done:
	BSR.w	InitBossBodyPart
	ADDI.w	#$0050, D6
	ADDQ.w	#1, Boss_ai_state.w
	ADDQ.w	#1, Boss_active_parts.w
	DBF	D7, InitHydraBoss_Common_Done
	RTS
	

;==============================================================
; HYDRA BOSS — PART MANAGEMENT
;==============================================================
; ActivateNextBossPart
; Walks the object chain to the next inactive body-part slot (skipping two
; slots per part) and calls InitBossBodyPart to activate it.
; Increments Boss_ai_state and Boss_active_parts.
ActivateNextBossPart:
	MOVEA.l	Object_slot_02_ptr.w, A6
	MOVE.w	Boss_ai_state.w, D7
	SUBQ.w	#1, D7
ActivateNextBossPart_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, ActivateNextBossPart_Done
	MOVE.w	#$0100, D6
	BSR.w	InitBossBodyPart
	ADDQ.w	#1, Boss_ai_state.w
	ADDQ.w	#1, Boss_active_parts.w
	RTS
	
; InitBossBodyPart
; Initialises a single Hydra body part and its associated head sprite object.
; Sets sprite flags, size, world position from D6, hitbox, HP from the main
; entity, and installs HydraBoss_PartIntroAnim as the tick function.
InitBossBodyPart:
	BSET.b	#7, (A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.w	D6, obj_world_x(A6)
	MOVE.w	#ORBIT_PROJ_Y_FLOOR, obj_world_y(A6)
	MOVE.b	#$F4, obj_hitbox_x_neg(A6)
	MOVE.b	#$10, obj_hitbox_x_pos(A6)
	MOVE.b	#$C8, obj_hitbox_y_neg(A6)
	MOVE.b	#0, obj_hitbox_y_pos(A6)
	MOVEA.l	Enemy_list_ptr.w, A4
	MOVE.w	obj_hp(A4), obj_hp(A6)
	MOVE.w	obj_max_hp(A4), obj_max_hp(A6)
	CLR.b	obj_move_counter(A6)
	CLR.b	obj_hit_flag(A6)
	MOVE.l	#HydraBoss_PartIntroAnim, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BSET.b	#7, (A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A6)
	MOVE.w	D6, obj_world_x(A6)
	MOVE.w	#$0094, obj_world_y(A6)
	MOVE.l	#BossCommon_DisplaySprite, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	RTS


;==============================================================
; HYDRA BOSS — BODY PART TICKS
;==============================================================
; HydraBoss_PartIntroAnim
; Plays the intro animation for a Hydra body part rising into position.
; Cycles HydraBoss_BodyPartFrames until BOSS_ANIM_PHASE_END, then transitions
; to HydraBoss_PartIdleTick and enables the leftward slide velocity.
HydraBoss_PartIntroAnim:
	TST.b	Fade_in_lines_mask.w
	BNE.w	HydraBoss_PartSpriteDone
	TST.b	Battle_active_flag.w
	BEQ.w	HydraBoss_PartSpriteDone
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0030, D0
	ASR.w	#2, D0
	CMPI.w	#BOSS_ANIM_PHASE_END, D0
	BLT.b	HydraBoss_PartIntroAnim_Loop
	CLR.b	obj_move_counter(A5)
	CLR.b	obj_npc_busy_flag(A5)
	MOVE.l	#$FFFE8000, obj_vel_x(A5)
	MOVE.l	#HydraBoss_PartIdleTick, obj_tick_fn(A5)
HydraBoss_PartIntroAnim_Loop:
	LEA	HydraBoss_BodyPartFrames, A0
	LEA	(A0,D0.w), A0
	MOVE.w	(A0)+, obj_tile_index(A5)
	MOVE.w	(A0), obj_tile_index(A6)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
HydraBoss_PartSpriteDone:
	RTS

; HydraBoss_PartIdleTick
; Main idle/attack tick for a Hydra body part.
; Handles hit-stun, applies Player_str damage on hit, transitions to
; HydraBoss_PartDeathAnim when HP depletes, and triggers HydraBoss_PartAttackTick
; when the player is within range and the attack cooldown has elapsed.
HydraBoss_PartIdleTick:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	TST.w	obj_knockback_timer(A5)
	BLE.b	HydraBoss_PartIdleTick_Loop
	SUBQ.w	#1, obj_knockback_timer(A5)
	BRA.w	HydraBoss_PartIdleTick_Check
HydraBoss_PartIdleTick_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.b	HydraBoss_PartIdleTick_Check
	ADDI.w	#$0014, obj_world_x(A5)
	MOVE.w	Player_str.w, D0
	SUB.w	D0, obj_hp(A5)
	BCC.b	HydraBoss_PartIdleTick_SetHitStun
	MOVE.l	#HydraBoss_PartDeathAnim, obj_tick_fn(A5)
	PlaySound	SOUND_MAGIC_EFFECT
	CLR.b	obj_move_counter(A5)
	BRA.w	HydraBoss_PartIdleTick_UpdatePos
HydraBoss_PartIdleTick_SetHitStun:
	PlaySound	SOUND_HYDRA_BITE
	MOVE.w	#BOSS_HIT_STUN_FRAMES, obj_knockback_timer(A5)
HydraBoss_PartIdleTick_Check:
	CLR.b	obj_hit_flag(A5)
	TST.b	obj_npc_busy_flag(A5)
	BNE.b	HydraBoss_PartIdleTick_Check_Loop
	TST.b	obj_invuln_timer(A5)
	BNE.w	HydraBoss_PartAttackTick
	BSR.w	CheckPlayerWithinRange
	BEQ.w	HydraBoss_PartAttackTick
	MOVE.b	#FLAG_TRUE, obj_npc_busy_flag(A5)
	MOVE.b	#$32, D1
	JSR	GetRandomNumber
	ANDI.w	#$000F, D0
	ADD.w	D0, D1
	MOVE.b	D1, obj_invuln_timer(A5)
	CLR.b	obj_move_counter(A5)
HydraBoss_PartIdleTick_Check_Loop:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$001C, D0
	ASL.w	#1, D0
	CMPI.w	#$0038, D0
	BGE.b	HydraBoss_PartIdleTick_AnimComplete
	LEA	HydraBoss_AttackAnimFrames, A0
	LEA	(A0,D0.w), A0
	MOVE.w	(A0)+, obj_tile_index(A5)
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVE.b	(A0)+, obj_hitbox_x_neg(A5)
	MOVE.b	(A0), obj_hitbox_x_pos(A5)
	BRA.w	HydraBoss_PartIdleTick_UpdatePos
HydraBoss_PartIdleTick_AnimComplete:
	CLR.b	obj_move_counter(A5)
	CLR.b	obj_npc_busy_flag(A5)
	BRA.w	HydraBoss_PartIdleTick_UpdatePos
; HydraBoss_PartAttackTick
; Animates a Hydra body part during its forward lunge attack.
; Cycles HydraBoss_AttackFrames; applies the slide velocity (or reverses it
; during the retract phase) until obj_invuln_timer expires.
HydraBoss_PartAttackTick:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0018, D0
	ASR.w	#1, D0
	LEA	HydraBoss_AttackFrames, A0
	LEA	(A0,D0.w), A0
	MOVE.w	(A0)+, obj_tile_index(A5)
	MOVE.w	(A0), obj_tile_index(A6)
	MOVE.l	obj_vel_x(A5), D0
	TST.b	obj_invuln_timer(A5)
	BLE.b	HydraBoss_PartAttackTick_Loop
	SUBQ.b	#1, obj_invuln_timer(A5)
	NEG.l	D0
HydraBoss_PartAttackTick_Loop:
	ADD.l	D0, obj_world_x(A5)
HydraBoss_PartIdleTick_UpdatePos:
	MOVE.w	obj_world_x(A5), obj_world_x(A6)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	CheckEntityPlayerCollisionAndDamage
	JSR	AddSpriteToDisplayList
	RTS

; HydraBoss_PartDeathAnim
; Plays the death animation for a single Hydra body part.
; Cycles HydraBoss_PartDeathFrames; on completion decrements Boss_active_parts
; and transitions to HydraBoss_PartDeadDisplay (static display).
HydraBoss_PartDeathAnim:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0018, D0
	ASR.w	#1, D0
	CMPI.w	#BOSS_ANIM_PHASE_END, D0
	BLT.b	HydraBoss_PartDeathAnim_Loop
	SUBQ.w	#1, Boss_active_parts.w
	MOVE.l	#HydraBoss_PartDeadDisplay, obj_tick_fn(A5)
HydraBoss_PartDeathAnim_Loop:
	LEA	HydraBoss_PartDeathFrames, A0
	LEA	(A0,D0.w), A0
	MOVE.w	(A0)+, obj_tile_index(A5)
	MOVE.w	(A0), obj_tile_index(A6)
HydraBoss_PartDeadDisplay:
	MOVE.w	obj_world_x(A5), obj_screen_x(A6)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS
	

;==============================================================
; HYDRA BOSS — MAIN TICK + DEATH + VICTORY
;==============================================================
; HydraBoss_MainTick
; Per-frame tick for the Hydra boss main head.
; Handles hit-stun, damage, and death. Animates the main head sprite,
; periodically initialises a projectile, and activates new body parts
; when the player approaches the split threshold.
HydraBoss_MainTick:
	TST.b	Fade_in_lines_mask.w
	BNE.w	HydraBoss_MainTick_Return
	TST.b	Battle_active_flag.w
	BEQ.w	HydraBoss_MainTick_Return
	TST.w	obj_knockback_timer(A5)
	BLE.b	HydraBoss_MainTick_Loop
	SUBQ.w	#1, obj_knockback_timer(A5)
	BRA.b	HydraBoss_MainTick_Animate
HydraBoss_MainTick_Loop:
	TST.b	obj_hit_flag(A5)
	BEQ.b	HydraBoss_MainTick_Animate
	MOVE.w	Player_str.w, D0
	SUB.w	D0, obj_hp(A5)
	BCC.b	HydraBoss_MainTick_SetHitStun
	MOVE.l	#HydraBoss_MainDeathAnim, obj_tick_fn(A5)
	PlaySound	SOUND_MAGIC_EFFECT
	CLR.b	obj_move_counter(A5)
	BRA.w	HydraBoss_MainTick_SpriteUpdate
HydraBoss_MainTick_SetHitStun:
	PlaySound	SOUND_HEAL
	MOVE.w	#BOSS_HIT_STUN_FRAMES, obj_knockback_timer(A5)
HydraBoss_MainTick_Animate:
	CLR.b	obj_hit_flag(A5)
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D5
	MOVE.b	D5, D4
	ANDI.w	#$00F0, D5
	ASR.w	#2, D5
	CMPI.b	#$30, D4
	BNE.b	HydraBoss_MainTick_Animate_Loop
	BSR.w	InitBossProjectile
	BRA.w	HydraBoss_MainTick_UpdateFrame
HydraBoss_MainTick_Animate_Loop:
	CMPI.b	#$A0, D4
	BNE.w	HydraBoss_MainTick_UpdateFrame
	CMPI.w	#BOSS1_STATE_CHARGE_DOWN_LEFT, Boss_ai_state.w
	BGE.b	HydraBoss_MainTick_LaunchProjectile
	CMPI.w	#3, Boss_active_parts.w
	BGE.b	HydraBoss_MainTick_LaunchProjectile
	MOVEA.l	Player_entity_ptr.w, A6
	CMPI.w	#HYDRA_BOSS_SPLIT_X, obj_world_x(A6)
	BGE.b	HydraBoss_MainTick_LaunchProjectile
	MOVEA.l	Object_slot_01_ptr.w, A6
	MOVE.l	#HydraBoss_DeactivateProjectile, obj_tick_fn(A6)
	BSR.w	ActivateNextBossPart
	BRA.b	HydraBoss_MainTick_UpdateFrame
HydraBoss_MainTick_LaunchProjectile:
	MOVEA.l	Object_slot_01_ptr.w, A6
	MOVE.l	#HydraBoss_LaunchProjectile, obj_tick_fn(A6)
HydraBoss_MainTick_UpdateFrame:
	LEA	BossSpriteFramePtrs, A0
	MOVEA.l	(A0,D5.w), A0
	MOVE.w	(A0)+, obj_tile_index(A5)
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.w	(A0)+, obj_tile_index(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVEA.l	Object_slot_01_ptr.w, A6
	TST.l	obj_vel_x(A6)
	BNE.b	HydraBoss_MainTick_SpriteUpdate
	MOVE.w	obj_world_x(A5), D0
	ADD.w	(A0)+, D0
	MOVE.w	D0, obj_world_x(A6)
	MOVE.w	obj_world_y(A5), D0
	ADD.w	(A0)+, D0
	MOVE.w	D0, obj_world_y(A6)
HydraBoss_MainTick_SpriteUpdate:
	JSR	CheckEntityPlayerCollisionAndDamage
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
HydraBoss_MainTick_Return:
	RTS
	
; HydraBoss_MainDeathAnim
; Plays the main Hydra head death animation.
; Deactivates supplementary head objects, cycles BossProjectileSpriteFramePtrs
; frames; on completion transitions to HydraBoss_DeathPauseWait.
HydraBoss_MainDeathAnim:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A4
	BCLR.b	#7, (A4)
	MOVEA.l	Object_slot_01_ptr.w, A4
	BCLR.b	#7, (A4)
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0030, D0
	ASR.w	#2, D0
	CMPI.w	#BOSS_ANIM_PHASE_END, D0
	BLT.b	HydraBoss_MainDeathAnim_Loop
	SUBQ.w	#1, Boss_active_parts.w
	MOVE.l	#HydraBoss_DeathPauseWait, obj_tick_fn(A5)
	MOVE.b	#$28, obj_move_counter(A5)
	PlaySound	SOUND_DOOR_OPEN
	MOVE.w	#$000C, D0
HydraBoss_MainDeathAnim_Loop:
	LEA	BossProjectileSpriteFramePtrs, A0
	MOVEA.l	(A0,D0.w), A0
	MOVE.w	(A0)+, obj_tile_index(A5)
	MOVE.w	(A0), obj_tile_index(A6)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS
	
; HydraBoss_DeathPauseWait
; Brief pause after the death animation completes.
; Counts down obj_move_counter then transitions to HydraBoss_DeathClearScreen,
; resets dialog timers, and plays the victory sound.
HydraBoss_DeathPauseWait:
	SUBQ.b	#1, obj_move_counter(A5)
	BGT.b	HydraBoss_DeathPauseWait_Loop
	MOVE.l	#HydraBoss_DeathClearScreen, obj_tick_fn(A5)
	CLR.w	Dialog_timer.w
	CLR.w	Dialog_phase.w
	PlaySound	SOUND_PURCHASE
HydraBoss_DeathPauseWait_Loop:
	JSR	AddSpriteToDisplayList
	RTS
	
; HydraBoss_DeathClearScreen
; Clears the dialog plane over BOSS_VICTORY_FADE_PHASES steps (every 8 frames).
; Once complete, transitions to HydraBoss_VictoryCheck and deactivates body parts.
HydraBoss_DeathClearScreen:
	ADDQ.w	#1, Dialog_timer.w
	MOVE.w	Dialog_timer.w, D0
	ANDI.w	#7, D0
	BNE.b	HydraBoss_DeathClearScreen_Loop
	CMPI.w	#BOSS_VICTORY_FADE_PHASES, Dialog_phase.w
	BLT.b	HydraBoss_DeathClearScreen_ClearPlane
	MOVE.l	#HydraBoss_VictoryCheck, obj_tick_fn(A5)
	MOVE.b	#BOSS_VICTORY_PAUSE, obj_invuln_timer(A5)
	BSR.w	DeactivateBossBodyParts
	RTS
	
HydraBoss_DeathClearScreen_ClearPlane:
	JSR	ClearDialogPlane
HydraBoss_DeathClearScreen_Loop:
	JSR	AddSpriteToDisplayList
	RTS
	
; HydraBoss_VictoryCheck
; Post-death check: triggers the battle victory event and either awards
; rewards (normal ending) or starts the next phase via HydraBoss_StartNextBattle
; if Swaffham_miniboss_defeated is set.
HydraBoss_VictoryCheck:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BNE.b	HydraBoss_VictoryCheck_Loop
	BSR.w	ProcessBattleVictoryEvent
	TST.b	Swaffham_miniboss_defeated.w
	BNE.b	HydraBoss_VictoryCheck_StartNextBattle
	MOVE.l	#BossCommon_VictoryRewardSequence, obj_tick_fn(A5)
	MOVE.w	#BOSS_VICTORY_DELAY_FRAMES, Dialog_timer.w
	RTS
	
HydraBoss_VictoryCheck_StartNextBattle:
	MOVE.l	#HydraBoss_StartNextBattle, obj_tick_fn(A5)
HydraBoss_VictoryCheck_Loop:
	RTS
	
; HydraBoss_StartNextBattle
; Transitions directly to the next boss battle phase (Swaffham multi-phase fight).
; Scans Boss_battle_flags to determine the next battle type, clears all enemy
; entities, re-initialises objects, reloads graphics and tiles, and restarts battle.
HydraBoss_StartNextBattle:
	MOVE.b	#FLAG_TRUE, Boss_battle_type_marker.w
	CLR.w	D0
	LEA	Boss_battle_flags.w, A0
	MOVE.w	#$000F, D7
HydraBoss_StartNextBattle_Done:
	MOVE.b	(A0)+, D1
	TST.b	D1
	BNE.w	HydraBoss_StartNextBattle_Loop
	ADDQ.w	#1, D0
	DBF	D7, HydraBoss_StartNextBattle_Done
HydraBoss_StartNextBattle_Loop:
	CLR.b	Boss_event_trigger.w
	CLR.b	-$2(A0)
	MOVE.w	D0, Battle_type.w
	LEA	Boss_battle_flags.w, A0
	MOVE.w	#3, D7
HydraBoss_StartNextBattle_Loop_Done:
	CLR.l	(A0)+
	DBF	D7, HydraBoss_StartNextBattle_Loop_Done
	JSR	ClearAllEnemyEntities
	LEA	BossBattleObjectInitPtrs, A0
	MOVE.w	Battle_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	JSR	(A0)
	JSR	LoadBattleGraphics
	JSR	LoadBattleTilesToVram
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.b	#FLAG_TRUE, Is_in_battle.w
	JSR	InitBattleEntities
	CLR.b	Player_in_first_person_mode.w
	JSR	UpdateEncounterPalette
	RTS
	
; DeactivateBossBodyParts
; Deactivates all Hydra body-part object slots by clearing bit 7.
; Walks the object chain from the first slot after the main entity until
; obj_next_offset is zero.
DeactivateBossBodyParts:
	MOVEA.l	Enemy_list_ptr.w, A6
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
DeactivateBossBodyParts_Done:
	BCLR.b	#7, (A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	BEQ.b	DeactivateBossBodyParts_Loop
	LEA	(A6,D0.w), A6
	BRA.b	DeactivateBossBodyParts_Done
DeactivateBossBodyParts_Loop:
	RTS
	

;==============================================================
; HYDRA BOSS — PROJECTILE SYSTEM
;==============================================================
; InitBossProjectile
; Initialises the Hydra boss projectile in Object_slot_01.
; Sets hitbox, sprite flags, tile, sort key, and installs
; HydraBoss_ProjectileAnimate as the tick function.
InitBossProjectile:
	MOVEA.l	Object_slot_01_ptr.w, A6
	BSET.b	#7, (A6)
	MOVE.b	#$F8, obj_hitbox_x_neg(A6)
	MOVE.b	#8, obj_hitbox_x_pos(A6)
	MOVE.b	#$F0, obj_hitbox_y_neg(A6)
	MOVE.b	#0, obj_hitbox_y_pos(A6)
	MOVEA.l	Enemy_list_ptr.w, A4
	MOVE.w	obj_max_hp(A4), obj_max_hp(A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_2x2, obj_sprite_size(A6)
	MOVE.w	#SORT_KEY_BOSS_PROJ, obj_sort_key(A6)
	CLR.l	obj_vel_x(A6)
	CLR.b	obj_move_counter(A6)
	MOVE.l	#HydraBoss_ProjectileAnimate, obj_tick_fn(A6)
	RTS
	
; HydraBoss_ProjectileAnimate
; Idle animation for the Hydra projectile before it is launched.
; Cycles HydraBoss_ProjectileSpriteFrames and keeps the sprite visible
; at its current world position.
HydraBoss_ProjectileAnimate:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$00F8, D0
	ASR.w	#2, D0
	LEA	HydraBoss_ProjectileSpriteFrames-2, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS
	
; HydraBoss_LaunchProjectile
; Launches the Hydra projectile from the right side of the screen.
; Sets leftward velocity, positions at the head's fire origin, and
; transitions to HydraBoss_ProjectileFalling.
HydraBoss_LaunchProjectile:
	MOVEA.l	Object_slot_01_ptr.w, A6
	MOVE.l	#$FFFD0000, obj_vel_x(A6)
	MOVE.w	#$0114, obj_world_x(A6)
	MOVE.w	#$0084, obj_world_y(A6)
	MOVE.w	#VRAM_TILE_HYDRA_PROJECTILE, obj_tile_index(A6)
	MOVE.l	#HydraBoss_ProjectileFalling, obj_tick_fn(A6)
	RTS
	
; HydraBoss_ProjectileFalling
; Moves the Hydra projectile leftward each frame and checks collision.
; Deactivates via HydraBoss_DeactivateProjectile when it leaves the screen.
HydraBoss_ProjectileFalling:
	CMPI.w	#PROJ_OFFSCREEN_X_LEFT, obj_world_x(A5)
	BGE.b	HydraBoss_ProjectileFalling_Loop
	BRA.w	HydraBoss_DeactivateProjectile
HydraBoss_ProjectileFalling_Loop:
	MOVE.l	obj_vel_x(A5), D0
	ADD.l	D0, obj_world_x(A5)
	JSR	CheckEntityPlayerCollisionAndDamage
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#2, D0
	LEA	HydraBoss_ProjectileFallFrames, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS
	
; HydraBoss_DeactivateProjectile
; Deactivates the Hydra projectile by clearing bit 7 of Object_slot_01.
HydraBoss_DeactivateProjectile:
	MOVEA.l	Object_slot_01_ptr.w, A6
	BCLR.b	#7, (A6)
	RTS
	

;==============================================================
; HYDRA BOSS — UTILITY HELPERS
;==============================================================
; CheckPlayerWithinRange
; Checks whether the player is within $0020 pixels to the left of the boss part.
; Inputs: A5 = body part object, Player_entity_ptr = player
; Outputs: D0 = $FFFF if in range, $0000 otherwise
CheckPlayerWithinRange:
	MOVEA.l	Player_entity_ptr.w, A4
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	obj_world_x(A4), D1
	SUB.w	D1, D0
	CMPI.w	#$0020, D0
	BGT.b	CheckPlayerWithinRange_Loop
	MOVE.w	#$FFFF, D0
	RTS
	
CheckPlayerWithinRange_Loop:
	CLR.w	D0
	RTS
	

;==============================================================
; RING GUARDIAN — INIT
;==============================================================
; InitRingGuardian_Normal
; Entry point for normal-difficulty Ring Guardian: sets 6500 HP / 180 damage,
; then falls through to InitRingGuardian_Common.
InitRingGuardian_Normal:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#6500, obj_hp(A6)
	MOVE.w	#180, obj_max_hp(A6)
	BRA.b	InitRingGuardian_Common
; InitRingGuardian_Hard
; Entry point for hard-difficulty Ring Guardian: sets 7000 HP / 200 damage,
; then falls through to InitRingGuardian_Common.
InitRingGuardian_Hard:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#7000, obj_hp(A6)
	MOVE.w	#200, obj_max_hp(A6)
	BRA.b	InitRingGuardian_Common
; InitRingGuardian_VeryHard
; Entry point for very-hard-difficulty Ring Guardian: sets 7000 HP / 200 damage,
; then falls through to InitRingGuardian_Common.
InitRingGuardian_VeryHard:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#7000, obj_hp(A6)
	MOVE.w	#200, obj_max_hp(A6)
; InitRingGuardian_Common
; Shared Ring Guardian initialisation: sets Boss_max_hp flag, clears defeat flag,
; draws the health bar, positions the boss, and configures hitbox and movement.
; Spawns five body sprite objects (groups A and B) and installs tick functions.
InitRingGuardian_Common:
	MOVE.b	#FLAG_TRUE, Boss_max_hp.w
	CLR.b	Boss_defeated_flag.w
	MOVEA.l	Enemy_list_ptr.w, A6
	BSET.b	#7, (A6)
	JSR	DrawBossHealthBar
	MOVE.w	#100, obj_world_x(A6)
	MOVE.w	#50, obj_world_y(A6)
	MOVE.b	#50, obj_invuln_timer(A6)
	CLR.w	obj_knockback_timer(A6)
	CLR.b	obj_move_counter(A6)
	MOVE.b	#8, obj_hitbox_x_neg(A6)
	MOVE.b	#$58, obj_hitbox_x_pos(A6)
	MOVE.b	#0, obj_hitbox_y_neg(A6)
	MOVE.b	#$60, obj_hitbox_y_pos(A6)
	MOVE.l	#$400, obj_pos_x_fixed(A6)
	CLR.b	obj_direction(A6)
	MOVE.l	#RingGuardian_MainTick, obj_tick_fn(A6)
	CLR.w	Boss_ai_state.w
	MOVEA.l	Object_slot_02_ptr.w, A6
	LEA	(A6), A4
	MOVE.w	#4, D7
InitRingGuardian_Common_Done:
	BSET.b	#7, (A4)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A4)
	BCLR.b	#7, obj_sprite_flags(A4)
	BCLR.b	#3, obj_sprite_flags(A4)
	BCLR.b	#4, obj_sprite_flags(A4)
	MOVE.l	#BossCommon_DisplaySprite, obj_tick_fn(A4)
	CLR.w	D0
	MOVE.b	obj_next_offset(A4), D0
	LEA	(A4,D0.w), A4
	DBF	D7, InitRingGuardian_Common_Done
	CLR.b	obj_move_counter(A6)
	MOVE.l	#RingGuardian_BodyGroupATick, obj_tick_fn(A6)
	MOVEA.l	Object_slot_03_ptr.w, A6
	LEA	(A6), A4
	MOVE.w	#1, D7
InitRingGuardian_GroupBSlotLoop:
	BSET.b	#7, (A4)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A4)
	BCLR.b	#7, obj_sprite_flags(A4)
	BCLR.b	#3, obj_sprite_flags(A4)
	BCLR.b	#4, obj_sprite_flags(A4)
	MOVE.l	#BossCommon_DisplaySprite, obj_tick_fn(A4)
	CLR.w	D0
	MOVE.b	obj_next_offset(A4), D0
	LEA	(A4,D0.w), A4
	DBF	D7, InitRingGuardian_GroupBSlotLoop
	CLR.b	obj_move_counter(A6)
	MOVE.l	#RingGuardian_BodyGroupBTick, obj_tick_fn(A6)
	RTS
	

;==============================================================
; RING GUARDIAN — BODY GROUP TICKS
;==============================================================
; RingGuardian_BodyGroupATick
; Per-frame tick for Ring Guardian body sprite group A (front segments).
; Advances animation counter (unless defeated), looks up sprite data from
; EncounterEnemySpriteByDirA, positions all four child sprites relative to the
; main entity, and then falls through to BossCommon_DisplaySprite.
RingGuardian_BodyGroupATick:
	TST.b	Boss_defeated_flag.w
	BNE.b	RingGuardian_BodyGroupATick_Loop
	ADDQ.b	#1, obj_move_counter(A5)
RingGuardian_BodyGroupATick_Loop:
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0030, D0
	ASR.w	#2, D0
	LEA	EncounterEnemySpriteByDirA, A0
	MOVEA.l	(A0,D0.w), A0
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	obj_world_x(A6), D0
	MOVE.w	obj_world_y(A6), D1
	MOVE.w	(A0)+, obj_tile_index(A5)
	MOVE.b	(A0)+, obj_sprite_size(A5)
	CLR.w	D2
	MOVE.b	(A0)+, D2
	MOVE.w	D2, obj_sort_key(A5)
	ADD.w	(A0)+, D0
	MOVE.w	D0, obj_world_x(A5)
	ADD.w	(A0)+, D1
	MOVE.w	D1, obj_world_y(A5)
	LEA	(A5), A6
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A5), D1
	MOVE.w	#3, D7
RingGuardian_BodyGroupATick_Loop_Done:
	CLR.w	D2
	MOVE.b	obj_next_offset(A6), D2
	LEA	(A6,D2.w), A6
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVE.b	(A0)+, obj_sprite_size(A6)
	CLR.w	D2
	MOVE.b	(A0)+, D2
	MOVE.w	D2, obj_sort_key(A6)
	MOVE.w	D0, D3
	ADD.w	(A0)+, D3
	MOVE.w	D3, obj_world_x(A6)
	MOVE.w	D1, D4
	ADD.w	(A0)+, D4
	MOVE.w	D4, obj_world_y(A6)
	DBF	D7, RingGuardian_BodyGroupATick_Loop_Done
	BRA.w	BossCommon_DisplaySprite
; RingGuardian_BodyGroupBTick
; Per-frame tick for Ring Guardian body sprite group B (rear segments).
; Mirrors RingGuardian_BodyGroupATick but uses EncounterEnemySpriteByDirB
; and only positions two child sprites.
RingGuardian_BodyGroupBTick:
	TST.b	Boss_defeated_flag.w
	BNE.b	RingGuardian_BodyGroupBTick_Loop
	ADDQ.b	#1, obj_move_counter(A5)
RingGuardian_BodyGroupBTick_Loop:
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0030, D0
	ASR.w	#2, D0
	LEA	EncounterEnemySpriteByDirB, A0
	MOVEA.l	(A0,D0.w), A0
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	obj_world_x(A6), D0
	MOVE.w	obj_world_y(A6), D1
	MOVE.w	(A0)+, obj_tile_index(A5)
	MOVE.b	(A0)+, obj_sprite_size(A5)
	CLR.w	D2
	MOVE.b	(A0)+, D2
	MOVE.w	D2, obj_sort_key(A5)
	ADD.w	(A0)+, D0
	MOVE.w	D0, obj_world_x(A5)
	ADD.w	(A0)+, D1
	MOVE.w	D1, obj_world_y(A5)
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A5), D1
	CLR.w	D2
	MOVE.b	obj_next_offset(A5), D2
	LEA	(A5,D2.w), A6
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVE.b	(A0)+, obj_sprite_size(A6)
	CLR.w	D2
	MOVE.b	(A0)+, D2
	MOVE.w	D2, obj_sort_key(A6)
	ADD.w	(A0)+, D0
	MOVE.w	D0, obj_world_x(A6)
	ADD.w	(A0)+, D1
	MOVE.w	D1, obj_world_y(A6)
; BossCommon_DisplaySprite
; Displays a boss sub-sprite if its tile index is non-zero.
; Copies world position to screen position and queues the sprite for rendering.
BossCommon_DisplaySprite:
	TST.w	obj_tile_index(A5)
	BEQ.b	BossCommon_DisplaySprite_Loop
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
BossCommon_DisplaySprite_Loop:
	RTS
	

;==============================================================
; RING GUARDIAN — MAIN TICK + STATE MACHINE
;==============================================================
; RingGuardian_MainTick
; Main per-frame tick for the Ring Guardian boss.
; Dispatches to the current AI state handler via BossAiRingGuardianJumpTable.
RingGuardian_MainTick:
	MOVE.w	Boss_ai_state.w, D0
	ANDI.w	#$000F, D0
	LEA	BossAiRingGuardianJumpTable, A0
	ADD.w	D0, D0
	ADD.w	D0, D0
	JSR	(A0,D0.w)
	RTS
	
; BossAiRingGuardianJumpTable
; Jump table for Ring Guardian AI states (indexed by Boss_ai_state & $0F).
; States: 0=WaitBattleStart, 1=Descend, 2=ChasePlayer, 3=AttackWindup,
; 4=WaitProjectile, 5=ChasePlayer (repeat).
BossAiRingGuardianJumpTable:
	BRA.w	RingGuardianState_WaitBattleStart
	BRA.w	RingGuardianState_Descend
	BRA.w	RingGuardianState_ChasePlayer
	BRA.w	RingGuardianState_AttackWindup
	BRA.w	RingGuardianState_WaitProjectile
	BRA.w	RingGuardianState_ChasePlayer	
; RingGuardianState_WaitBattleStart
; Waits for the battle intro fade to complete and the battle-active flag to be set.
; Counts down obj_invuln_timer before transitioning to the first chase state.
RingGuardianState_WaitBattleStart:
	TST.b	Fade_in_lines_mask.w
	BNE.b	RingGuardianState_WaitBattleStart_Done
	TST.b	Battle_active_flag.w
	BEQ.b	RingGuardianState_WaitBattleStart_Done
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGT.b	RingGuardianState_WaitBattleStart_Done
	MOVE.b	#BOSS_STATE_DELAY, obj_invuln_timer(A5)
	MOVE.w	#BOSS1_STATE_CHOOSE_ACTION, Boss_ai_state.w
	MOVE.l	#$200, obj_pos_x_fixed(A5)
RingGuardianState_WaitBattleStart_Done:
	BRA.w	BossMoveTick_Clamped
; RingGuardianState_Descend
; Descend/patrol state: moves toward Y=8 while checking HP.
; On HP depletion, sets Boss_defeated_flag and transitions to RingGuardian_DeathFall.
; Otherwise transitions to the move-down state to begin chasing the player.
RingGuardianState_Descend:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BLT.b	RingGuardianState_Descend_Loop
	MOVE.w	#$00D0, D0
	SUB.w	obj_world_x(A5), D0
	BGE.b	RingGuardianState_Descend_CheckY
	MOVE.w	#8, D1	
	SUB.w	obj_world_y(A5), D1	
	BRA.b	RingGuardianState_Patrol_GetDir	
RingGuardianState_Descend_CheckY:
	MOVE.w	#8, D1
	SUB.w	obj_world_y(A5), D1
	BLT.b	RingGuardianState_Patrol_GetDir
RingGuardianState_Descend_Loop:
	TST.w	obj_hp(A5)
	BGT.b	RingGuardianState_Descend_PatrolDir
	MOVE.b	#FLAG_TRUE, Boss_defeated_flag.w
	MOVE.l	#RingGuardian_DeathFall, obj_tick_fn(A5)
	MOVE.l	#$8000, obj_vel_y(A5)
	RTS
	
RingGuardianState_Descend_PatrolDir:
	MOVE.w	#BOSS1_STATE_MOVE_DOWN, Boss_ai_state.w
	MOVE.l	#$400, obj_pos_x_fixed(A5)
	RTS
	
RingGuardianState_Patrol_GetDir:
	BSR.w	GetDirectionFromDeltas
	BRA.w	RingGuardianState_ApplyVelocity
; RingGuardianState_ChasePlayer
; Chases the player using directional sine-based movement.
; When the player is within horizontal range and at RING_GUARDIAN_HEAD_Y,
; transitions to the attack windup state.
RingGuardianState_ChasePlayer:
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), D0
	MOVE.w	obj_world_x(A5), D1
	SUBI.w	#$0018, D1
	CMP.w	D0, D1
	BGT.b	RingGuardianState_Chase_GetDir
	CMPI.w	#RING_GUARDIAN_HEAD_Y, obj_world_y(A5)
	BLT.b	RingGuardianState_Chase_GetDir
	MOVE.w	#BOSS1_STATE_HEAD_EXTEND, Boss_ai_state.w
	CLR.b	obj_invuln_timer(A5)
	RTS
	
RingGuardianState_Chase_GetDir:
	BSR.w	CalculateDirectionToPlayer
	BRA.w	RingGuardianState_ApplyVelocity
; RingGuardianState_AttackWindup
; Animates the Ring Guardian's attack wind-up over BOSS_ANIM_PHASE_END steps.
; When complete, activates Object_slot_01 as the projectile spawner and
; transitions to RingGuardianState_WaitProjectile.
RingGuardianState_AttackWindup:
	ADDQ.b	#1, obj_invuln_timer(A5)
	MOVE.b	obj_invuln_timer(A5), D0
	ANDI.w	#$0030, D0
	ASR.w	#2, D0
	CMPI.w	#BOSS_ANIM_PHASE_END, D0
	BLT.b	RingGuardianState_AttackWindup_Loop
	MOVEA.l	Object_slot_01_ptr.w, A6
	BSET.b	#7, (A6)
	CLR.b	obj_move_counter(A6)
	CLR.w	obj_attack_timer(A6)
	MOVE.l	#RingGuardian_ProjectileSpawner, obj_tick_fn(A6)
	MOVE.w	#BOSS1_STATE_ATTACK_WAIT, Boss_ai_state.w
	RTS
	
RingGuardianState_AttackWindup_Loop:
	BSR.w	WriteDirectionTilesForBoss
	BRA.w	BossMoveTick_Clamped
; RingGuardianState_WaitProjectile
; Waits until the projectile spawner in Object_slot_01 is deactivated.
; Randomises the next direction angle, resets the cooldown timer, and
; returns to the chase state.
RingGuardianState_WaitProjectile:
	MOVEA.l	Object_slot_01_ptr.w, A6
	BTST.b	#7, (A6)
	BNE.b	RingGuardianState_WaitProjectile_Loop
	JSR	GetRandomNumber
	MOVE.b	D0, obj_direction(A5)
	MOVE.b	#BOSS_STATE_DELAY, obj_invuln_timer(A5)
	MOVE.w	#BOSS1_STATE_CHOOSE_ACTION, Boss_ai_state.w
	MOVE.l	#$200, obj_pos_x_fixed(A5)
	CLR.w	D0
	BSR.w	WriteDirectionTilesForBoss
RingGuardianState_WaitProjectile_Loop:
	BRA.w	BossMoveTick_Clamped
; RingGuardianState_ApplyVelocity
; Applies sine-based directional velocity to the Ring Guardian.
; Clamps world X to [RING_GUARDIAN_X_LEFT, RING_GUARDIAN_X_RIGHT] and
; world Y to [0, RING_GUARDIAN_HEAD_Y], then falls through to BossMoveTick_Clamped.
RingGuardianState_ApplyVelocity:
	LEA	SineTable, A0
	MOVE.l	obj_pos_x_fixed(A5), D0
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	MOVE.b	(A0,D1.w), D2
	MOVE.b	$40(A0,D1.w), D3
	EXT.w	D2
	EXT.w	D3
	MULS.w	D0, D2
	MULS.w	D0, D3
	SUB.l	D2, obj_world_x(A5)
	NEG.l	D2
	MOVE.l	D2, obj_vel_x(A5)
	CMPI.w	#RING_GUARDIAN_X_LEFT, obj_world_x(A5)
	BGE.b	RingGuardianState_ApplyVelocity_Loop
	MOVE.w	#RING_GUARDIAN_X_LEFT, obj_world_x(A5)
RingGuardianState_ApplyVelocity_Loop:
	CMPI.w	#RING_GUARDIAN_X_RIGHT, obj_world_x(A5)
	BLE.b	RingGuardianState_ApplyVelocity_ClampXRight
	MOVE.w	#RING_GUARDIAN_X_RIGHT, obj_world_x(A5)	
	CLR.l	obj_vel_x(A5)	
RingGuardianState_ApplyVelocity_ClampXRight:
	SUB.l	D3, obj_world_y(A5)
	BGE.b	RingGuardianState_ApplyVelocity_ClampYTop
	CLR.w	obj_world_y(A5)
RingGuardianState_ApplyVelocity_ClampYTop:
	CMPI.w	#RING_GUARDIAN_HEAD_Y, obj_world_y(A5)
	BLE.b	BossMoveTick_Clamped
	MOVE.w	#RING_GUARDIAN_HEAD_Y, obj_world_y(A5)
; BossMoveTick_Clamped
; Shared movement tail called by all Ring Guardian state handlers.
; Advances animation counter, updates body tiles, checks player collision,
; handles hit-stun flash and damage, updates HScroll/VScroll parallax.
BossMoveTick_Clamped:
	ADDQ.b	#1, obj_move_counter(A5)
	BSR.w	UpdateBossBodyTiles
	JSR	CheckEntityPlayerCollisionAndDamage
	TST.w	obj_knockback_timer(A5)
	BLE.b	BossMoveTick_Clamped_Loop
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVE.w	#$007F, Palette_line_1_index.w
	JSR	LoadPalettesFromTable
	BRA.b	RingGuardian_TakeDamage_Return
BossMoveTick_Clamped_Loop:
	JSR	UpdateEncounterPalette
	TST.b	obj_hit_flag(A5)
	BEQ.b	RingGuardian_TakeDamage_Return
	PlaySound	SOUND_HEAL
	MOVE.w	Player_str.w, D0
	SUB.w	D0, obj_hp(A5)
	MOVE.w	#BOSS_HIT_STUN_FRAMES, obj_knockback_timer(A5)
RingGuardian_TakeDamage_Return:
	CLR.b	obj_hit_flag(A5)
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	D0, HScroll_base.w
	MOVE.w	#$200, D0
	SUB.w	obj_world_y(A5), D0
	MOVE.w	D0, VScroll_base.w
	RTS
	

;==============================================================
; RING GUARDIAN — DEATH + VICTORY
;==============================================================
; RingGuardian_DeathFall
; Accelerates the Ring Guardian downward under gravity after defeat.
; Clamps to RING_GUARDIAN_HEAD_Y, loads the victory palette, queues death
; and victory sounds, and transitions to RingGuardian_VictoryDialog.
RingGuardian_DeathFall:
	ADDI.l	#$8000, obj_vel_y(A5)
	MOVE.l	obj_vel_y(A5), D0
	ADD.l	D0, obj_world_y(A5)
	CMPI.w	#RING_GUARDIAN_HEAD_Y, obj_world_y(A5)
	BLE.b	RingGuardian_DeathFall_Loop
	MOVE.w	#RING_GUARDIAN_HEAD_Y, obj_world_y(A5)
	MOVE.w	#$0080, Palette_line_1_index.w
	JSR	LoadPalettesFromTable
	MOVE.l	#RingGuardian_VictoryDialog, obj_tick_fn(A5)
	CLR.w	Dialog_timer.w
	CLR.w	Dialog_phase.w
	PlaySound	SOUND_DOOR_OPEN
	PlaySound	SOUND_PURCHASE
RingGuardian_DeathFall_Loop:
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	D0, HScroll_base.w
	MOVE.w	#$0200, D0
	SUB.w	obj_world_y(A5), D0
	MOVE.w	D0, VScroll_base.w
	RTS
	
; RingGuardian_VictoryDialog
; Clears the dialog plane over BOSS_VICTORY_FADE_PHASES steps.
; Once complete, triggers the battle victory event and transitions to
; BossCommon_VictoryRewardSequence.
RingGuardian_VictoryDialog:
	ADDQ.w	#1, Dialog_timer.w
	MOVE.w	Dialog_timer.w, D0
	ANDI.w	#7, D0
	BNE.b	RingGuardian_VictoryWait
	CMPI.w	#BOSS_VICTORY_FADE_PHASES, Dialog_phase.w
	BLT.b	RingGuardian_VictoryDialog_Loop
	MOVE.l	#BossCommon_VictoryRewardSequence, obj_tick_fn(A5)
	MOVE.w	#BOSS_VICTORY_DELAY_FRAMES, Dialog_timer.w
	JSR	ProcessBattleVictoryEvent
	BRA.b	RingGuardian_VictoryWait
RingGuardian_VictoryDialog_Loop:
	JSR	ClearDialogPlane
RingGuardian_VictoryWait:
	RTS
	
; RingGuardian_VictoryDialogContinue
; Secondary victory dialog clear used by the Orbit Boss victory path.
; Clears the dialog plane then transitions to RingGuardian_ExitWait.
RingGuardian_VictoryDialogContinue:
	ADDQ.w	#1, Dialog_timer.w
	MOVE.w	Dialog_timer.w, D0
	ANDI.w	#7, D0
	BNE.b	RingGuardian_DialogReturn
	CMPI.w	#BOSS_VICTORY_FADE_PHASES, Dialog_phase.w
	BLT.b	RingGuardian_VictoryDialogContinue_Loop
	MOVE.l	#RingGuardian_ExitWait, obj_tick_fn(A5)
	MOVE.w	#BOSS_EXIT_DELAY_FRAMES, Dialog_timer.w
	BRA.b	RingGuardian_DialogReturn
RingGuardian_VictoryDialogContinue_Loop:
	JSR	ClearDialogPlane
RingGuardian_DialogReturn:
	RTS
	
; RingGuardian_ExitWait
; Countdown before triggering the final battle exit.
; Decrements Dialog_timer; when zero fires ProcessBattleVictoryEvent and
; sets Boss_battle_exit_flag to leave the battle screen.
RingGuardian_ExitWait:
	SUBQ.w	#1, Dialog_timer.w
	BGT.b	RingGuardian_ExitWait_Loop
	JSR	ProcessBattleVictoryEvent
	MOVE.b	#FLAG_TRUE, Boss_battle_exit_flag.w
RingGuardian_ExitWait_Loop:
	RTS
	

;==============================================================
; RING GUARDIAN — PROJECTILE SYSTEM
;==============================================================
; RingGuardian_ProjectileSpawner
; Tick function for the Ring Guardian projectile manager (runs in Object_slot_01).
; Fires one child projectile per two frames, up to 4 total (obj_attack_timer).
; Each projectile is initialised with leftward+downward velocity and assigned
; RingGuardian_ChildProjectileTick; deactivates self after all are fired.
RingGuardian_ProjectileSpawner:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	MOVE.b	D0, D1
	SUBQ.b	#1, D1
	EOR.w	D1, D0
	BTST.l	#2, D0
	BEQ.w	RingGuardian_ProjectileSpawner_Loop
	ADDQ.w	#1, obj_attack_timer(A5)
	MOVE.w	obj_attack_timer(A5), D0
	CMPI.w	#4, D0
	BLE.b	RingGuardian_ProjectileSpawner_FireProjectile
	MOVE.l	#RingGuardian_WaitChildrenDone, obj_tick_fn(A5)
	RTS
	
RingGuardian_ProjectileSpawner_FireProjectile:
	LEA	(A5), A6
	SUBQ.w	#1, D0
RingGuardian_ProjectileSpawner_WalkChain:
	CLR.w	D1
	MOVE.b	obj_next_offset(A6), D1
	LEA	(A6,D1.w), A6
	DBF	D0, RingGuardian_ProjectileSpawner_WalkChain
	BSET.b	#7, (A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	MOVE.l	#RingGuardian_ProjectileSpawner, obj_tick_fn(A6)
	CLR.b	obj_move_counter(A6)
	MOVEA.l	Enemy_list_ptr.w, A4
	MOVE.w	obj_world_x(A4), D0
	ADDI.w	#$001C, D0
	MOVE.w	D0, obj_world_x(A6)
	MOVE.w	obj_world_y(A4), D0
	ADDI.w	#$0040, D0
	MOVE.w	D0, obj_world_y(A6)
	MOVE.b	#$F0, obj_hitbox_x_neg(A6)
	MOVE.b	#$10, obj_hitbox_x_pos(A6)
	MOVE.b	#SOUND_LEVEL_UP, obj_hitbox_y_neg(A6)
	MOVE.b	#0, obj_hitbox_y_pos(A6)
	MOVE.w	obj_max_hp(A4), obj_max_hp(A6)
	MOVE.l	#$FFFE0000, obj_vel_x(A6)
	MOVE.l	#$00030000, obj_vel_y(A6)
	CLR.b	obj_move_counter(A6)
	MOVE.l	#RingGuardian_ChildProjectileTick, obj_tick_fn(A6)
	PlaySound	SOUND_SAVE
RingGuardian_ProjectileSpawner_Loop:
	RTS
	
; RingGuardian_WaitChildrenDone
; Waits until all four child projectile objects are deactivated.
; Walks four slots from the spawner; deactivates the spawner itself once done.
RingGuardian_WaitChildrenDone:
	LEA	(A5), A6
	MOVE.w	#3, D7
RingGuardian_WaitChildrenDone_Done:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, RingGuardian_WaitChildrenDone_Done
	BTST.b	#7, (A6)
	BNE.b	RingGuardian_WaitChildrenDone_Loop
	BCLR.b	#7, (A5)
RingGuardian_WaitChildrenDone_Loop:
	RTS
	
; RingGuardian_ChildProjectileTick
; Per-frame tick for a Ring Guardian child projectile in flight.
; Checks collision, applies velocity, cycles BattleVDPCmds_EnemySmall frames,
; and transitions to RingGuardian_ChildGroundImpact on hitting ORBIT_PROJ_Y_FLOOR.
RingGuardian_ChildProjectileTick:
	JSR	CheckEntityPlayerCollisionAndDamage
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$00F8, D0
	ASR.w	#1, D0
	CMPI.w	#8, D0
	BLE.b	RingGuardian_ChildProjectileTick_Loop
	MOVE.w	#8, D0	
RingGuardian_ChildProjectileTick_Loop:
	LEA	BattleVDPCmds_EnemySmall, A0
	LEA	(A0,D0.w), A0
	MOVE.w	(A0)+, obj_tile_index(A5)
	MOVE.b	(A0)+, obj_sprite_size(A5)
	CLR.w	D0
	MOVE.b	(A0)+, D0
	MOVE.w	D0, obj_sort_key(A5)
	MOVE.l	obj_vel_x(A5), D0
	ADD.l	D0, obj_world_x(A5)
	MOVE.l	obj_vel_y(A5), D0
	ADD.l	D0, obj_world_y(A5)
	CMPI.w	#ORBIT_PROJ_Y_FLOOR, obj_world_y(A5)
	BLT.b	RingGuardian_ChildProjectileTick_RenderAndReturn
	MOVE.w	#ORBIT_PROJ_Y_FLOOR, obj_world_y(A5)
	MOVE.l	#RingGuardian_ChildGroundImpact, obj_tick_fn(A5)
	CLR.b	obj_move_counter(A5)
RingGuardian_ChildProjectileTick_RenderAndReturn:
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS
	
; RingGuardian_ChildGroundImpact
; Ground-impact explosion animation for a Ring Guardian child projectile.
; Cycles BattleVDPCmds_EnemyLarge frames, checks collision during explosion,
; and deactivates the object when the animation completes.
RingGuardian_ChildGroundImpact:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0018, D0
	ASR.w	#1, D0
	CMPI.w	#8, D0
	BLE.b	RingGuardian_ChildGroundImpact_Loop
	BCLR.b	#7, (A5)
	RTS
	
RingGuardian_ChildGroundImpact_Loop:
	LEA	BattleVDPCmds_EnemyLarge, A0
	LEA	(A0,D0.w), A0
	MOVE.w	(A0)+, obj_tile_index(A5)
	MOVE.b	(A0)+, obj_sprite_size(A5)
	CLR.w	D0
	MOVE.b	(A0)+, D0
	MOVE.w	D0, obj_sort_key(A5)
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS
	

;==============================================================
; RING GUARDIAN — VDP TILE UPDATES
;==============================================================
; UpdateBossBodyTiles
; Writes animated Ring Guardian body tiles directly to VDP VRAM.
; Disables interrupts (ORI #$0700, SR), streams 4 rows of upper body tiles
; from BossBodyUpperTilePtrs and 3 rows of lower tiles from BossBodyLowerTilePtrs,
; adding $A200 as the palette/priority attribute to each tile index.
UpdateBossBodyTiles:
	ORI	#$0700, SR
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$000C, D0
	LEA	BossBodyUpperTilePtrs, A0
	MOVEA.l	(A0,D0.w), A0
	LEA	BossBodyLowerTilePtrs, A1
	MOVEA.l	(A1,D0.w), A1
	MOVE.l	#$43160003, D5
	MOVE.w	#3, D7
UpdateBossBodyTiles_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#3, D6
UpdateBossBodyTiles_UpperTileLoop:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$A200, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, UpdateBossBodyTiles_UpperTileLoop
	ADDI.l	#VDP_VRAM_ROW_STRIDE, D5
	DBF	D7, UpdateBossBodyTiles_Done
	MOVE.l	#$41800003, D5
	MOVE.w	#2, D7
UpdateBossBodyTiles_LowerRowLoop:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#3, D6
UpdateBossBodyTiles_LowerTileLoop:
	CLR.w	D0
	MOVE.b	(A1)+, D0
	ADDI.w	#$A200, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, UpdateBossBodyTiles_LowerTileLoop
	ADDI.l	#VDP_VRAM_ROW_STRIDE, D5
	DBF	D7, UpdateBossBodyTiles_LowerRowLoop
	ANDI	#$F8FF, SR
	RTS
	
