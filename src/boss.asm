; ======================================================================
; src/boss.asm
; Boss AI: all boss types, boss tile updates
; ======================================================================
Boss1_DeathFall:
	CLR.w	D0
	TST.l	obj_vel_y(A5)
	BLE.b	Boss1_DeathFall_Loop
	ADDI.l	#$4000, obj_vel_y(A5)
	MOVE.w	#1, D0
Boss1_DeathFall_Loop:
	MOVEA.l	Object_slot_02_ptr.w, A6
	TST.l	obj_vel_y(A6)
	BLE.b	Boss1_DeathFall_Loop2
	ADDI.l	#$4000, obj_vel_y(A6)
	MOVE.w	#1, D0
Boss1_DeathFall_Loop2:
	MOVEA.l	Object_slot_03_ptr.w, A6
	TST.l	obj_vel_y(A6)
	BLE.b	Boss1_DeathFall_Loop3
	ADDI.l	#$4000, obj_vel_y(A6)
	MOVE.w	#1, D0
Boss1_DeathFall_Loop3:
	MOVEA.l	Object_slot_04_ptr.w, A6
	TST.l	obj_vel_y(A6)
	BLE.b	Boss1_DeathFall_Loop4
	ADDI.l	#$4000, obj_vel_y(A6)
	MOVE.w	#1, D0
Boss1_DeathFall_Loop4:
	MOVEA.l	Object_slot_05_ptr.w, A6
	TST.l	obj_vel_y(A6)
	BLE.b	Boss1_DeathFall_Loop5
	ADDI.l	#$4000, obj_vel_y(A6)
	MOVE.w	#1, D0
Boss1_DeathFall_Loop5:
	TST.w	D0
	BNE.b	Boss1_DeathFall_Loop6
	MOVE.l	#Boss1_VictoryPauseWait, obj_tick_fn(A5)
	CLR.w	Dialog_timer.w
	CLR.w	Dialog_phase.w
	MOVE.b	#BOSS_VICTORY_PAUSE, obj_invuln_timer(A5)
Boss1_DeathFall_Loop6:
	BSR.w	UpdateSpritePositionAndRender
	RTS

Boss1_VictoryPauseWait:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGE.b	Boss1_VictoryPauseWait_Loop
	BSR.w	SetBattleVictoryAnimFrames1
	MOVE.l	#Boss1_VictoryPose1Wait, obj_tick_fn(A5)
	MOVE.b	#BOSS_VICTORY_PAUSE, obj_invuln_timer(A5)
	MOVE.w	#SOUND_BOSS1_VICTORY, D0
	JSR	QueueSoundEffect
Boss1_VictoryPauseWait_Loop:
	BSR.w	UpdateSpritePositionAndRender
	RTS

Boss1_VictoryPose1Wait:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGE.b	Boss1_VictoryPose1Wait_Loop
	BSR.w	SetBattleVictoryAnimFrames2
	MOVE.b	#BOSS_VICTORY_PAUSE, obj_invuln_timer(A5)
	MOVE.l	#Boss1_VictoryFadeInit, obj_tick_fn(A5)
Boss1_VictoryPose1Wait_Loop:
	BSR.w	UpdateSpritePositionAndRender
	RTS

Boss1_VictoryFadeInit:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGE.b	Boss1_VictoryFadeInit_Loop
	MOVE.w	#$0067, Palette_line_1_fade_in_target.w
	MOVE.b	#2, Palette_fade_in_mask.w
	MOVE.l	#Boss1_VictoryFadeWait, obj_tick_fn(A5)
Boss1_VictoryFadeInit_Loop:
	BSR.w	UpdateSpritePositionAndRender
	RTS

Boss1_VictoryFadeWait:
	TST.b	Palette_fade_in_mask.w
	BNE.b	Boss1_VictoryFadeWait_Loop
	MOVE.l	#Boss1_VictoryFlash, obj_tick_fn(A5)
	MOVE.w	#SOUND_PURCHASE, D0
	JSR	QueueSoundEffect
Boss1_VictoryFadeWait_Loop:
	BSR.w	UpdateSpritePositionAndRender
	RTS

Boss1_VictoryFlash:
	ADDQ.w	#1, Dialog_timer.w
	MOVE.w	Dialog_timer.w, D0
	ANDI.w	#7, D0
	BNE.b	BossCommon_SpriteUpdate
	CMPI.w	#BOSS_VICTORY_FADE_PHASES, Dialog_phase.w
	BLT.b	Boss1_VictoryFlash_Loop
	MOVE.l	#BossCommon_VictoryRewardSequence, obj_tick_fn(A5)
	MOVE.w	#BOSS_VICTORY_DELAY_FRAMES, Dialog_timer.w
	BRA.b	BossCommon_SpriteUpdate
Boss1_VictoryFlash_Loop:
	BSR.w	ClearDialogPlane
BossCommon_SpriteUpdate:
	BSR.w	UpdateSpritePositionAndRender
	RTS

BossCommon_VictoryRewardSequence:
	SUBQ.w	#1, Dialog_timer.w
	BGE.b	BossCommon_VictoryRewardSequence_Loop
	JSR	ClearScrollData
	MOVE.w	#SOUND_ERROR, D0
	JSR	QueueSoundEffect
	MOVE.b	#FLAG_TRUE, Player_input_blocked.w
	BSR.w	AwardBattleRewards
	BSR.w	DisplayBattleVictoryMessage
	MOVE.l	#BossCommon_VictoryMessageWait, obj_tick_fn(A5)
BossCommon_VictoryRewardSequence_Loop:
	RTS

BossCommon_VictoryMessageWait:
	TST.b	Script_text_complete.w
	BEQ.b	BossBattle_SetExitFlag_Loop
	MOVE.w	#BUTTON_BIT_C, D2
	JSR	CheckButtonPress
	BNE.b	BossBattle_SetExitFlag
	MOVE.w	#BUTTON_BIT_B, D2
	JSR	CheckButtonPress
	BNE.b	BossBattle_SetExitFlag
	RTS

BossBattle_SetExitFlag:
	MOVE.b	#FLAG_TRUE, Boss_battle_exit_flag.w
	RTS

BossBattle_SetExitFlag_Loop:
	JSR	ProcessScriptText
	RTS

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
UpdateBattleParallax_ClearSlots:
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
UpdateSpritePositionAndRender:
	MOVE.l	obj_vel_x(A5), D0
	MOVE.l	obj_vel_y(A5), D1
	ADD.l	D0, obj_world_x(A5)
	ADD.l	D1, obj_world_y(A5)
	MOVE.w	obj_world_y(A5), D0
	CMPI.w	#BATTLE_ARENA_EDGE, D0
	BLT.b	BossBody_SpriteUpdate
	MOVE.w	#$00A8, obj_world_y(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
BossBody_SpriteUpdate:
	MOVEA.l	Object_slot_01_ptr.w, A6
	LEA	EnemySpriteFrameDataA_12, A0
	CLR.w	D0
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0070, D0
	ASR.w	#3, D0
	MOVE.w	(A0,D0.w), obj_tile_index(A6)
	LEA	EnemySpriteFrameDataA_10, A0
	MOVE.w	#4, D7
BossBody_SpriteUpdate_Done:
	MOVE.w	obj_world_x(A5), D0
	ADD.w	(A0)+, D0
	MOVE.w	D0, obj_screen_x(A6)
	MOVE.w	obj_world_y(A5), D0
	ADD.w	(A0)+, D0
	MOVE.w	D0, obj_screen_y(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, BossBody_SpriteUpdate_Done
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	BSR.w	UpdateBossAttackGraphic
	RTS

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
	TST.w	obj_hp(A6)
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

Boss1_MidBodyTick:
	MOVE.l	obj_vel_x(A5), D0
	MOVE.l	obj_vel_y(A5), D1
	ADD.l	D0, obj_world_x(A5)
	ADD.l	D1, obj_world_y(A5)
	BSR.w	ClampYPosition
	MOVEA.l	Enemy_list_ptr.w, A6
	TST.w	obj_hp(A6)
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
BossCommon_RenderOnly:
	JSR	AddSpriteToDisplayList
	RTS

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

InitSpriteSlot_DeadCode:					; unreferenced dead code
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#$001F, D7
InitNextSpriteSlot_Done:
	BCLR	#7, (A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	$0(A6,D0.w), A6
	DBF	D7, InitNextSpriteSlot_Done
	RTS
CheckPlayerLeftOfScreen:
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), D0
	CMPI.w	#$0050, D0
	BLE.b	CheckPlayerLeftOfScreen_Loop
	MOVE.w	#$FFFF, D0
	RTS

CheckPlayerLeftOfScreen_Loop:
	CLR.w	D0
	RTS

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
InitTwoHeadedDragon_Common_Done2:
	BSR.w	InitNextSpriteSlot
	DBF	D7, InitTwoHeadedDragon_Common_Done2
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
InitTwoHeadedDragon_Common_Done3:
	BSR.w	InitNextSpriteSlot
	DBF	D7, InitTwoHeadedDragon_Common_Done3
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
InitTwoHeadedDragon_Common_Done4:
	BSR.w	InitNextSpriteSlot
	DBF	D7, InitTwoHeadedDragon_Common_Done4
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
	
TwoHeadedDragon_FireballTickA:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVEA.l	Object_slot_02_ptr.w, A6
	BRA.w	TwoHeadedDragon_FireballTickB_Loop
TwoHeadedDragon_FireballTickB:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVEA.l	Object_slot_03_ptr.w, A6
TwoHeadedDragon_FireballTickB_Loop:
	TST.b	obj_npc_busy_flag(A6)
	BNE.b	TwoHeadedDragon_FireballTickB_Loop2
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
TwoHeadedDragon_FireballTickB_Loop2:
	TST.b	obj_hit_flag(A5)
	BEQ.b	TwoHeadedDragon_FireballTickB_Loop3
	TST.w	obj_knockback_timer(A5)
	BEQ.b	TwoHeadedDragon_FireballTickB_Loop4
	SUBQ.w	#1, obj_knockback_timer(A5)
	BLE.b	TwoHeadedDragon_FireballTickB_Loop5
	MOVE.w	obj_knockback_timer(A5), D0
	CMPI.b	#$0A, D0
	BGE.w	BossFireball_RenderDone
	MOVE.w	#VRAM_TILE_DRAGON_FIREBALL_A, obj_tile_index(A5)
	BRA.w	BossFireball_RenderDone
TwoHeadedDragon_FireballTickB_Loop5:
	CLR.w	obj_knockback_timer(A5)
	CLR.b	obj_hit_flag(A5)
	CLR.b	obj_move_counter(A5)
	CLR.b	obj_npc_busy_flag(A6)
	BRA.b	BossFireball_RenderDone
TwoHeadedDragon_FireballTickB_Loop4:
	CLR.l	obj_vel_x(A5)
	MOVE.w	#VRAM_TILE_DRAGON_FIREBALL_B, obj_tile_index(A5)
	MOVE.w	#$0014, obj_knockback_timer(A5)
	BRA.b	BossFireball_RenderDone
TwoHeadedDragon_FireballTickB_Loop3:
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#8, D0
	ASR.w	#2, D0
	LEA	BossSpriteLayoutData_F, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	MOVE.l	obj_vel_x(A5), D0
	ADD.l	D0, obj_world_x(A5)
	CMPI.w	#PROJ_OFFSCREEN_X_LEFT, obj_world_x(A5)
	BGE.b	TwoHeadedDragon_FireballTickB_Loop6
	CLR.b	obj_npc_busy_flag(A6)
	CLR.b	obj_move_counter(A5)
TwoHeadedDragon_FireballTickB_Loop6:
	MOVE.w	#SORT_KEY_BOSS_PROJ, obj_sort_key(A5)
BossFireball_RenderDone:
	BSR.w	CheckEntityPlayerCollisionAndDamage
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS
	
TwoHeadedDragon_MainTick:
	TST.b	Boss_defeated_flag.w
	BEQ.b	TwoHeadedDragon_MainTick_Loop
	TST.b	Boss_death_anim_done.w
	BNE.w	TwoHeadedDragon_MainTick_Loop2
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
	
TwoHeadedDragon_MainTick_Loop2:
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
	MOVE.w	#SOUND_DOOR_OPEN, D0
	JSR	QueueSoundEffect
	JSR	LoadPalettesFromTable
	RTS
	
TwoHeadedDragon_DeathDelayTick:
	SUBQ.w	#1, obj_knockback_timer(A5)
	BGT.b	TwoHeadedDragon_DeathDelayTick_Loop
	MOVE.l	#TwoHeadedDragon_VictoryFadeoutTick, obj_tick_fn(A5)
	MOVE.w	#SOUND_PURCHASE, D0
	JSR	QueueSoundEffect
TwoHeadedDragon_DeathDelayTick_Loop:
	JSR	AddSpriteToDisplayList
	RTS
	
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
	BCC.b	TwoHeadedDragon_HeadTickA_Loop2
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
	BCLR.b	#7, (A6)
	MOVE.w	#$012C, obj_knockback_timer(A5)
	MOVE.b	#FLAG_TRUE, Boss_defeated_flag.w
	RTS

TwoHeadedDragon_HeadTickA_Loop2:
	MOVE.w	#BOSS_HIT_STUN_FRAMES, obj_knockback_timer(A5)
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
	MOVE.w	#8, D0
	BRA.b	BossTick_Anim_A_Loop
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

TwoHeadedDragon_DeadHeadTick:
	JSR	AddSpriteToDisplayList
	RTS

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
	BCC.w	TwoHeadedDragon_HeadTickB_Loop2
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
	BCLR.b	#7, (A6)
	MOVE.b	#FLAG_TRUE, Boss_death_anim_done.w
	RTS

TwoHeadedDragon_HeadTickB_Loop2:
	MOVE.w	#BOSS_HIT_STUN_FRAMES, obj_knockback_timer(A5)
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
	MOVE.w	#8, D0
	BRA.b	BossTick_Anim_B_Loop
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

AnimateSpriteFromTable:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0030, D0
	ASR.w	#3, D0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
	RTS

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
	MOVE.w	#SOUND_PLAYER_HIT, D0
	JSR	QueueSoundEffect
	MOVE.b	#FLAG_TRUE, Player_invulnerable.w
	MOVE.b	#PLAYER_HIT_INVULN_FRAMES, obj_invuln_timer(A6)
	JSR	ApplyDamageToPlayer
	MOVE.l	obj_vel_x(A5), D0
	BGT.b	CheckEntityPlayerCollisionAndDamage_Loop
	CMPI.l	#$FFFF8000, D0
	BLE.b	CheckEntityPlayerCollisionAndDamage_Loop2
	MOVE.l	#$FFFF8000, D0
	BRA.b	CheckEntityCollision_ClampVelocity
CheckEntityPlayerCollisionAndDamage_Loop2:
	CMPI.l	#$FFFE0000, D0
	BGE.b	CheckEntityCollision_ClampVelocity
	MOVE.l	#$FFFE0000, D0
	BRA.b	CheckEntityCollision_ClampVelocity
CheckEntityPlayerCollisionAndDamage_Loop:
	CMPI.l	#$8000, D0
	BGE.b	CheckEntityPlayerCollisionAndDamage_Loop3
	MOVE.l	#$8000, D0
	BRA.b	CheckEntityCollision_ClampVelocity
CheckEntityPlayerCollisionAndDamage_Loop3:
	CMPI.l	#$00020000, D0	
	BLE.b	CheckEntityCollision_ClampVelocity	
	MOVE.l	#$00020000, D0	
CheckEntityCollision_ClampVelocity:
	ASL.l	#4, D0
	ADD.l	D0, obj_world_x(A6)
CheckEntityPlayerCollisionAndDamage_Return:
	RTS

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
	MOVE.w	#SOUND_PLAYER_HIT, D0
	JSR	QueueSoundEffect
BattleHit_Return:
	RTS

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
	MOVE.w	#SOUND_HEAL, D0
	JSR	QueueSoundEffect
	MOVE.w	Player_str.w, D0
	SUB.w	D0, obj_hp(A6)
	BCC.b	ProcessBattleDamageAndPalette_Loop2
	MOVE.l	#Boss1_DeathSequence, obj_tick_fn(A6)
	BSR.w	ProcessBattleVictoryEvent
	RTS

ProcessBattleDamageAndPalette_Loop2:
	MOVE.w	#BOSS_HIT_STUN_FRAMES, obj_knockback_timer(A6)
ProcessBattleDamage_Return:
	CLR.b	obj_hit_flag(A6)
	RTS
	
ClampYPosition:
	MOVE.w	obj_world_y(A5), D0
	CMPI.w	#$00B0, D0
	BLE.b	ClampYPosition_Loop
	MOVE.w	#$00B0, obj_world_y(A5)
	CLR.l	obj_vel_x(A5)
	CLR.l	obj_vel_y(A5)
ClampYPosition_Loop:
	RTS

DrawBossPortrait:
	ORI	#$0700, SR
	MOVE.l	#$44B40003, D5
	LEA	DrawBossPortrait_Data, A0
	MOVE.w	#$000D, D7
DrawBossPortrait_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$000B, D6
DrawBossPortrait_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$2200, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawBossPortrait_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, DrawBossPortrait_Done
	ANDI	#$F8FF, SR
	RTS

DrawBossNameplate:
	ORI	#$0700, SR
	MOVE.l	#$44300003, D5
	LEA	DrawBossNameplate_Data, A0
	MOVE.w	#$000D, D7
DrawBossNameplate_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$000C, D6
DrawBossNameplate_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$2200, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawBossNameplate_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, DrawBossNameplate_Done
	ANDI	#$F8FF, SR
	RTS

DrawBossHealthBar:
	ORI	#$0700, SR
	MOVE.l	#$40000003, D5
	LEA	DrawBossHealthBar_Data, A0
	MOVE.w	#$000C, D7
DrawBossHealthBar_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$000D, D6
DrawBossHealthBar_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$A200, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawBossHealthBar_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, DrawBossHealthBar_Done
	MOVE.l	#$40080003, D5
	LEA	SpriteMetaTileTable_7808A, A0
	MOVE.w	#5, D7
DrawBossHealthBar_Done3:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#4, D6
DrawBossHealthBar_Done4:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$A200, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawBossHealthBar_Done4
	ADDI.l	#$00800000, D5
	DBF	D7, DrawBossHealthBar_Done3
	ANDI	#$F8FF, SR
	RTS

UpdateBossAttackGraphic:
	CLR.w	D0
	MOVE.b	obj_move_counter(A5), D0
	MOVE.w	D0, D1
	ANDI.w	#$000F, D1
	BNE.b	UpdateBossAttackGraphic_Loop
	ANDI.w	#$0030, D0
	ASR.w	#2, D0
	LEA	BossAttackGfxJumpTable, A0
	JSR	(A0,D0.w)
UpdateBossAttackGraphic_Loop:
	RTS

BossAttackGfxJumpTable:
	BRA.w	DrawBossAttackGraphic1
	BRA.w	DrawDialogTextLine_Alt1
	BRA.w	DrawDialogTextLine_Alt1_Loop
	BRA.w	DrawDialogTextLine_Alt1
DrawBossAttackGraphic1:
	LEA	DrawBossAttackGraphic1_Data, A0
	MOVE.l	#$43BE0003, D5
	BSR.w	WriteTextToVRAM
	LEA	DrawBossAttackGraphic1_Data2, A0
	MOVE.l	#$48C20003, D5
	BSR.w	WriteTextToVRAM
	RTS

DrawDialogTextLine_Alt1:
	LEA	DrawDialogTextLine_Alt1_Data, A0
	MOVE.l	#$43BE0003, D5
	BSR.w	WriteTextToVRAM
	RTS

DrawDialogTextLine_Alt1_Loop:
	LEA	DrawDialogTextLine_Alt1_Loop_Data, A0
	MOVE.l	#$43BE0003, D5
	BSR.w	WriteTextToVRAM
	LEA	DrawDialogTextLine_Alt1_Loop_Data2, A0
	MOVE.l	#$48C20003, D5
	BSR.w	WriteTextToVRAM
	RTS

WriteTextToVRAM:
	ORI	#$0700, SR
	MOVE.w	#5, D7
WriteTextToVRAM_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#6, D6
WriteTextToVRAM_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$2200, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, WriteTextToVRAM_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, WriteTextToVRAM_Done
	ANDI	#$F8FF, SR
	RTS

AnimateBossAttackFlash:
	ADDQ.w	#1, obj_attack_timer(A5)
	MOVE.w	obj_attack_timer(A5), D0
	MOVE.w	D0, D1
	ANDI.w	#$000F, D1
	BNE.b	AnimateBossAttackFlash_Loop
	ANDI.w	#$0030, D0
	ASR.w	#2, D0
	LEA	BossAttackFlashJumpTable, A0
	JSR	(A0,D0.w)
AnimateBossAttackFlash_Loop:
	RTS

BossAttackFlashJumpTable:
	BRA.w	BossAttackFlashJumpTable_Loop
	BRA.w	DrawDialogTextLine_Alt2
	BRA.w	DrawDialogTextLine_Alt2_Loop
	BRA.w	DrawDialogTextLine_Alt2
BossAttackFlashJumpTable_Loop:
	LEA	BossAttackFlashJumpTable_Loop_Data, A0
	MOVE.l	#$46420003, D5
	BSR.w	Write7x8TilesToVRAM
	RTS

DrawDialogTextLine_Alt2:
	LEA	DrawDialogTextLine_Alt2_Data, A0
	MOVE.l	#$46420003, D5
	BSR.w	Write7x8TilesToVRAM
	RTS

DrawDialogTextLine_Alt2_Loop:
	LEA	DrawDialogTextLine_Alt2_Loop_Data, A0
	MOVE.l	#$46420003, D5
	BSR.w	Write7x8TilesToVRAM
	RTS

Write7x8TilesToVRAM:
	ORI	#$0700, SR
	MOVE.w	#6, D7
Write7x8TilesToVRAM_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#7, D6
Write7x8TilesToVRAM_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$2200, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, Write7x8TilesToVRAM_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, Write7x8TilesToVRAM_Done
	ANDI	#$F8FF, SR
	RTS

ClearDialogPlane:
	MOVE.l	#$44200000, D5
	MOVEQ	#0, D0
	MOVE.w	Dialog_phase.w, D0
	ADD.w	D0, D0
	SWAP	D0
	ADD.l	D0, D5
	MOVE.w	#$03BD, D7
	ORI	#$0700, SR
ClearDialogPlane_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#0, VDP_data_port
	ADDI.l	#$00100000, D5
	DBF	D7, ClearDialogPlane_Done
	ANDI	#$F8FF, SR
	MOVE.l	#$40000001, D5
	MOVEQ	#0, D0
	MOVE.w	Dialog_phase.w, D0
	ADD.w	D0, D0
	SWAP	D0
	ADD.l	D0, D5
	MOVE.w	#$01FF, D7
	ORI	#$0700, SR
ClearDialogPlane_Done2:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#0, VDP_data_port
	ADDI.l	#$00100000, D5
	DBF	D7, ClearDialogPlane_Done2
	ANDI	#$F8FF, SR
	ADDQ.w	#1, Dialog_phase.w
	RTS

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

SetEntityAnimFrames:
	MOVE.w	(A0)+, obj_tile_index(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, SetEntityAnimFrames
	RTS

ProcessBattleVictoryEvent:
	LEA	BattleVictoryEventJumpTable, A0
	MOVE.w	Battle_type.w, D0
	ANDI.w	#$000F, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	JSR	(A0,D0.w)
	RTS

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
	BGE.b	BossVictoryEvent_Tsarkon_Loop2
	CLR.w	(A1)	
BossVictoryEvent_Tsarkon_Loop2:
	MOVE.w	D7, D0
	LEA	Possessed_items_list.w, A0
	MOVE.w	#8, D2
	JSR	RemoveItemFromArray
	DBF	D7, BossVictoryEvent_Tsarkon_Done
BossVictoryEvent_Tsarkon_Loop:
	BSR.w	GetNextItemSlotOffset
	MOVE.w	#$0115, (A0,D0.w)
	BSR.w	GetNextItemSlotOffset
	MOVE.w	#$0116, (A0,D0.w)
	BSR.w	GetNextItemSlotOffset
	MOVE.w	#$0117, (A0,D0.w)
	BSR.w	GetNextItemSlotOffset
	MOVE.w	#$0118, (A0,D0.w)
	BSR.w	GetNextItemSlotOffset
	MOVE.w	#$0119, (A0,D0.w)
	RTS

GetNextItemSlotOffset:
	LEA	Possessed_items_length.w, A0
	MOVE.w	(A0), D0
	ADDQ.w	#1, (A0)+
	ADD.w	D0, D0
	RTS

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

AwardBattleRewards:
	LEA	BattleRewardTable, A2
	MOVE.w	Battle_type.w, D6
	ANDI.w	#$000F, D6
	ASL.w	#3, D6
	MOVE.l	(A2,D6.w), Transaction_amount.w
	JSR	AddExperiencePoints
	MOVE.l	$4(A2,D6.w), Transaction_amount.w
	JSR	AddPaymentAmount
	RTS

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

InitDemonBoss_Normal:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#BOSS_HP_ORBIT_NORMAL, obj_hp(A6)
	MOVE.w	#BOSS_HP_ORBIT_NORMAL, Boss_max_hp.w
	MOVE.w	#BOSS_DMG_DEMON_NORMAL, obj_max_hp(A6)
	BRA.w	InitDemonBoss_Common
InitDemonBoss_Hard:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#BOSS_HP_ORBIT_HARD, obj_hp(A6)
	MOVE.w	#BOSS_HP_ORBIT_HARD, Boss_max_hp.w
	MOVE.w	#BOSS_DMG_DEMON_HARD, obj_max_hp(A6)
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
InitDemonBoss_Common_Done2:
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
	DBF	D7, InitDemonBoss_Common_Done2
	RTS

DemonBoss_MainTick:
	TST.b	Fade_in_lines_mask.w
	BNE.b	DemonBoss_MainTick_Loop
	MOVE.b	demon_ai_state(A5), D0
	ANDI.w	#7, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	BossAiDemonJumpTable, A0
	JSR	(A0,D0.w)
	JSR	UpdateBossFlashAndDamage(PC)
	JSR	SpawnBossChildObjects(PC)
	JSR	CheckEntityPlayerCollisionAndDamage(PC)
DemonBoss_MainTick_Loop:
	RTS

BossAiDemonJumpTable:
	BRA.w	DemonBossState_WaitIdle
	BRA.w	DemonBossState_ChooseDirection
	BRA.w	DemonBossState_Move
	BRA.w	DemonBossState_FireProjectile
	BRA.w	DemonBossState_AttackAnimate
	BRA.w	DemonBossState_Cooldown
DemonBossState_WaitIdle:
	TST.b	Battle_active_flag.w
	BEQ.w	DemonBossState_WaitReturn
	SUBQ.w	#1, obj_attack_timer(A5)
	BGT.w	DemonBossState_WaitReturn
	ADDQ.b	#1, demon_ai_state(A5)
DemonBossState_WaitReturn:
	RTS

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
	MOVE.l	#$0000C000, obj_pos_x_fixed(A5)
	BRA.b	DemonBoss_MoveRight_Loop
DemonBoss_MoveRight:
	MOVE.l	#Player_overworld_gfx_buffer, obj_pos_x_fixed(A5)
DemonBoss_MoveRight_Loop:
	CLR.b	demon_dir_flag(A5)
	ANDI.w	#3, D0
	ADDQ.w	#1, D0
	MOVE.w	D0, demon_move_steps(A5)
	CLR.w	demon_move_timer(A5)
	MOVE.w	#$0010, obj_vel_y(A5)
	ADDQ.b	#1, demon_ai_state(A5)
	RTS

DemonBossState_Move:
	TST.w	demon_move_timer(A5)
	BLE.b	DemonBossState_Move_Loop
	SUBQ.w	#1, demon_move_timer(A5)
	BGT.w	DemonBossState_Move_Return
DemonBossState_Move_Loop:
	MOVE.l	obj_pos_x_fixed(A5), D0
	ADD.l	D0, obj_world_x(A5)
	CMPI.w	#8, obj_vel_y(A5)
	BNE.b	DemonBossState_Move_Loop2
	ADDQ.b	#1, demon_wing_anim(A5)
	MOVE.b	demon_wing_anim(A5), D0
	ANDI.w	#1, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	DemonBossWingFrameData, A0
	MOVE.w	(A0,D0.w), demon_seg4_y(A5)
	MOVE.w	$2(A0,D0.w), demon_seg5_y(A5)
DemonBossState_Move_Loop2:
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
	BGE.b	DemonBoss_SetFireFlag_Loop2
	NEG.w	D1
DemonBoss_SetFireFlag_Loop2:
	SWAP	D1
	CLR.w	D1
	ASR.l	#4, D1
	CMPI.l	#$000CE000, D1
	BLE.b	DemonBoss_SetFireFlag_Loop3
	MOVE.l	#$000CE000, D1
	BRA.b	DemonBoss_LaunchProjectile
DemonBoss_SetFireFlag_Loop3:
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
	MOVE.w	#SOUND_TREASURE, D0
	JSR	QueueSoundEffect
	MOVE.w	#$0064, obj_attack_timer(A5)
	ADDQ.b	#1, demon_ai_state(A5)
DemonBoss_LaunchProjectile_Loop:
	RTS

DemonBossState_AttackAnimate:
	SUBQ.w	#1, obj_attack_timer(A5)
	MOVE.w	obj_attack_timer(A5), D0
	ASR.w	#1, D0
	ANDI.w	#$003E, D0
	LEA	DemonBossAttackYOffsets, A0
	MOVE.w	(A0,D0.w), demon_seg0_y(A5)
	TST.w	obj_attack_timer(A5)
	BEQ.w	DemonBossState_AttackAnimate_UpdateFrame_Loop
	CMPI.w	#DEMON_BOSS_ATTACK_FIRE_TICK, obj_attack_timer(A5)
	BGT.b	DemonBossState_AttackAnimate_UpdateFrame
	BNE.b	DemonBossState_AttackAnimate_Loop
	MOVE.w	#SOUND_BOMB, D0
	JSR	QueueSoundEffect
	MOVEA.l	Object_slot_07_ptr.w, A6
	MOVE.b	#FLAG_TRUE, obj_move_counter(A6)
	MOVE.l	#$00020000, obj_vel_y(A6)
	CLR.w	obj_attack_timer(A6)
	MOVE.w	#6, obj_pos_x_fixed(A6)
	CLR.w	obj_knockback_timer(A6)
	CLR.w	$22(A6)
	BRA.b	DemonBossState_AttackAnimate_UpdateFrame
DemonBossState_AttackAnimate_Loop:
	CMPI.w	#6, obj_attack_timer(A5)
	BNE.b	DemonBossState_AttackAnimate_UpdateFrame
	MOVE.b	#0, demon_fire_dir(A5)
	JSR	SetEntityCoordFromDirection(PC)
	BRA.b	DemonBossState_FireReturn
DemonBossState_AttackAnimate_UpdateFrame:
	MOVEA.l	Object_slot_07_ptr.w, A6
	MOVE.w	obj_attack_timer(A5), D0
	ASR.w	#1, D0
	ANDI.w	#$003E, D0
	LEA	DemonBossProjectileFrames, A0
	MOVE.w	(A0,D0.w), obj_knockback_timer(A6)
	BRA.b	DemonBossState_FireReturn
DemonBossState_AttackAnimate_UpdateFrame_Loop:
	MOVE.b	#2, demon_fire_dir(A5)
	JSR	SetEntityCoordFromDirection(PC)
	MOVE.w	#$0028, obj_attack_timer(A5)
	ADDQ.b	#1, demon_ai_state(A5)
DemonBossState_FireReturn:
	RTS

DemonBossState_Cooldown:
	SUBQ.w	#1, obj_attack_timer(A5)
	BGT.b	DemonBossState_Cooldown_Loop
	CLR.b	demon_dir_flag(A5)
	MOVE.b	#0, demon_fire_dir(A5)
	JSR	SetEntityCoordFromDirection(PC)
	MOVE.w	#$003C, obj_attack_timer(A5)
	CLR.b	demon_ai_state(A5)
DemonBossState_Cooldown_Loop:
	RTS

SetEntityCoordFromDirection:
	BTST.b	#2, demon_wing_flags(A5)
	BNE.b	SetEntityCoordFromDirection_Loop
	LEA	EntityDirectionYOffsets, A0
	MOVE.b	demon_fire_dir(A5), D0
	ANDI.w	#3, D0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), demon_seg3_y(A5)
	BRA.b	SetEntityCoordFromDirection_Loop2
SetEntityCoordFromDirection_Loop:
	LEA	EntityDirectionXOffsets, A0
	MOVE.b	demon_fire_dir(A5), D0
	ANDI.w	#3, D0
	ADD.w	D0, D0
	MOVE.w	(A0,D0.w), demon_seg2_y(A5)
SetEntityCoordFromDirection_Loop2:
	RTS

DemonBossWingFrameData:
	dc.w	$78, $96
	dc.w	$82, $8C 
EntityDirectionXOffsets:
	dc.w	$28
	dc.w	$32
	dc.w	$3C
EntityDirectionYOffsets:
	dc.w	$50
	dc.w	$5A
	dc.w	$64
DemonBossAttackYOffsets:
	dc.b	$00, $00, $00, $00, $00, $00, $00, $0A, $00, $14, $00, $0A, $00, $00, $00, $0A, $00, $14, $00, $0A, $00, $00, $00, $0A, $00, $0A, $00, $14, $00, $14, $00, $0A 
	dc.b	$00, $0A, $00, $00, $00, $00, $00, $0A, $00, $0A, $00, $14, $00, $14, $00, $0A, $00, $0A 
DemonBossProjectileFrames:
	dc.b	$00, $00, $00, $08, $00, $10, $00, $18, $00, $20, $00, $00, $00, $08, $00, $10, $00, $18, $00, $20, $00, $00, $00, $08, $00, $10, $00, $18, $00, $20, $00, $00 
	dc.b	$00, $08, $00, $10, $00, $18, $00, $20, $00, $00, $00, $08, $00, $10, $00, $18, $00, $20 

UpdateBossFlashAndDamage:
	TST.w	obj_knockback_timer(A5)
	BLE.b	UpdateBossFlashAndDamage_Loop
	SUBQ.w	#1, obj_knockback_timer(A5)
	MOVE.w	#$0026, Palette_line_1_index.w
	JSR	LoadPalettesFromTable
	BRA.w	DemonBoss_AbilityReturn
UpdateBossFlashAndDamage_Loop:
	JSR	UpdateEncounterPalette
	TST.b	obj_hit_flag(A5)
	BEQ.w	DemonBoss_AbilityReturn
	MOVE.b	#$FF, demon_dir_flag(A5)
	MOVE.w	#SOUND_HEAL, D0
	JSR	QueueSoundEffect
	MOVE.w	Player_str.w, D0
	SUB.w	D0, obj_hp(A5)
	BCC.b	UpdateBossFlashAndDamage_Loop2
	MOVE.l	#DemonBoss_DeathInit, obj_tick_fn(A5)
	MOVE.b	#SOUND_MAGIC_EFFECT, D0
	JSR	QueueSoundEffect
	RTS

UpdateBossFlashAndDamage_Loop2:
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
	MOVE.b	#SOUND_MAGIC_EFFECT, D0
	JSR	QueueSoundEffect
	JSR	GetRandomNumber(PC)
	BTST.l	#4, D0
	BEQ.b	UpdateBossFlashAndDamage_Loop3
	BCLR.b	#0, demon_wing_flags(A5)
	MOVE.w	#$0046, demon_seg2_y(A5)
	BRA.b	BossTick_AbilityCheck_Done
UpdateBossFlashAndDamage_Loop3:
	BCLR.b	#1, demon_wing_flags(A5)
	MOVE.w	#$006E, demon_seg3_y(A5)
BossTick_AbilityCheck_Done:
	MOVE.w	#BOSS_HIT_STUN_FRAMES, obj_knockback_timer(A5)
DemonBoss_AbilityReturn:
	CLR.b	obj_hit_flag(A5)
	RTS

DemonBoss_DeathInit:
	MOVE.l	#DemonBoss_DeathSequence, obj_tick_fn(A5)
	CLR.w	Dialog_timer.w
	CLR.w	Dialog_phase.w
	MOVE.w	#SOUND_PURCHASE, D0
	JSR	QueueSoundEffect
	RTS

DemonBoss_DeathSequence:
	ADDQ.w	#1, Dialog_timer.w
	MOVE.w	Dialog_timer.w, D0
	ANDI.w	#7, D0
	BNE.b	DemonBoss_DeathSequence_Loop
	CMPI.w	#BOSS_VICTORY_FADE_PHASES, Dialog_phase.w
	BLT.b	DemonBoss_DeathSequence_Loop2
	JSR	ProcessBattleVictoryEvent
	MOVE.l	#BossCommon_VictoryRewardSequence, obj_tick_fn(A5)
	MOVE.w	#BOSS_VICTORY_DELAY_FRAMES, Dialog_timer.w
	RTS

DemonBoss_DeathSequence_Loop2:
	JSR	ClearDialogPlane
DemonBoss_DeathSequence_Loop:
	RTS

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

DemonBoss_ClearBodySegment:
	CLR.b	demon_seg_active(A6)
	CLR.w	D6
	MOVE.b	obj_next_offset(A6), D6
	LEA	(A6,D6.w), A6
	DBF	D7, DemonBoss_ClearBodySegment
	RTS

DemonBoss_BodySegmentTick:
	TST.b	demon_seg_active(A5)
	BEQ.b	DemonBoss_BodySegmentTick_Loop
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList(PC)
DemonBoss_BodySegmentTick_Loop:
	RTS

DemonBoss_ProjectileHeadTick:
	CMPI.b	#FLAG_TRUE, obj_move_counter(A5)
	BNE.w	DemonBoss_ProjectileHeadTick_Loop
	MOVE.w	$22(A5), D7
	CMPI.w	#2, D7
	BGT.w	DemonBoss_ProjectileSegmentTick
	SUBQ.w	#1, obj_pos_x_fixed(A5)
	BGT.w	DemonBoss_ProjectileSegmentTick
	MOVE.w	#6, obj_pos_x_fixed(A5)
	ADDQ.w	#1, $22(A5)
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
	BNE.b	DemonBoss_ProjectileHeadTick_Loop2
	ADDA.w	#$001E, A1
DemonBoss_ProjectileHeadTick_Loop2:
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
	BGT.b	DemonBoss_ProjectileSegmentTick_Loop2
	CLR.b	obj_move_counter(A5)
	BCLR.b	#7, (A5)
	BRA.w	DemonBoss_ProjectileSegmentTick_Loop3
DemonBoss_ProjectileSegmentTick_Loop2:
	MOVE.w	obj_attack_timer(A5), D0
	ASR.w	#1, D0
	ANDI.w	#$000E, D0
	LEA	DemonBossProjectileTileFrames, A0
	MOVE.w	(A0,D0.w), obj_knockback_timer(A5)
	BRA.w	DemonBoss_ProjectileSegmentTick_Loop4
DemonBoss_ProjectileSegmentTick_Loop:
	CMPI.w	#DEMON_BOSS_SEG_ANIM_FRAMES, obj_attack_timer(A5)
	BEQ.b	DemonBoss_ProjectileSegmentTick_Loop5
	ADDQ.w	#1, obj_attack_timer(A5)
	MOVE.w	obj_attack_timer(A5), D0
	ASR.w	#1, D0
	ANDI.w	#$000E, D0
	LEA	DemonBossProjectileTileFrames, A0
	MOVE.w	(A0,D0.w), obj_knockback_timer(A5)
DemonBoss_ProjectileSegmentTick_Loop5:
	MOVE.l	obj_vel_x(A5), D0
	ADD.l	D0, obj_world_x(A5)
	MOVE.l	obj_vel_y(A5), D0
	ADD.l	D0, obj_world_y(A5)
	JSR	CheckEntityPlayerCollisionAndDamage(PC)
DemonBoss_ProjectileSegmentTick_Loop4:
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList(PC)
DemonBoss_ProjectileSegmentTick_Loop3:
	RTS

DemonBossProjectileTileFrames:
	dc.w	$0
	dc.w	$8 
	dc.w	$10 
	dc.w	$18 
	dc.w	$20 
InitOrbitBoss:
	MOVEA.l	Enemy_list_ptr.w, A6
	BSET.b	#7, (A6)
	CLR.b	obj_move_counter(A6)
	CLR.b	obj_invuln_timer(A6)
	CLR.l	obj_vel_x(A6)
	MOVE.w	#0, D0
	JSR	QueueSoundEffect
	MOVE.w	#SOUND_TERRAFISSI, D0
	JSR	QueueSoundEffect
	CLR.l	obj_hp(A6)
	MOVE.w	#$0016, D0
	ASL.w	#3, D0
	MOVE.w	D0, obj_knockback_timer(A6)
	MOVE.w	#BOSS_DMG_ORBIT_PART, obj_max_hp(A6)
	MOVE.l	#OrbitBoss_MainTick, obj_tick_fn(A6)
	CLR.b	Boss_defeated_flag.w
	CLR.b	Boss_death_anim_done.w
	RTS
	
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
	BLT.b	OrbitBoss_MainTick_Loop2
	RTS
	
OrbitBoss_MainTick_Loop2:
	ASR.w	#5, D0
	BSR.w	WriteTilesToVRAM
	RTS
	
OrbitBoss_MainTick_Loop:
	MOVE.w	#SOUND_ORBIT_BOSS_MUSIC, D0
	JSR	QueueSoundEffect
	MOVE.l	#OrbitBoss_InitParts, obj_tick_fn(A5)
	CLR.l	HScroll_base.w
	RTS
	
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
OrbitBoss_InitParts_Done2:
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
	DBF	D7, OrbitBoss_InitParts_Done2
	MOVE.l	#OrbitBoss_InnerCheckVictory, obj_tick_fn(A5)
	RTS
	
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
	MOVE.w	#SOUND_DOOR_OPEN, D0
	JSR	QueueSoundEffect
	MOVE.l	#OrbitBoss_InnerVictoryDelay, obj_tick_fn(A5)
CheckBossDamageAndKnockback:
	MOVE.w	#$00D8, D1
	JSR	CheckPlayerDamageAndKnockback
	RTS
	
OrbitBoss_InnerVictoryDelay:
	SUBQ.w	#1, obj_attack_timer(A5)
	BGE.b	OrbitBoss_InnerVictoryDelay_Loop
	MOVE.w	#SOUND_PURCHASE, D0
	JSR	QueueSoundEffect
	MOVE.l	#RingGuardian_VictoryDialogContinue, obj_tick_fn(A5)
OrbitBoss_InnerVictoryDelay_Loop:
	RTS
	
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
OrbitBoss_InnerSelectTarget_Done2:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	MOVE.l	#OrbitBoss_SatelliteOrbitInactive, obj_tick_fn(A6)
	DBF	D7, OrbitBoss_InnerSelectTarget_Done2
OrbitBoss_InnerSelectTarget_Loop:
	MOVE.l	#OrbitBoss_InnerApproach, obj_tick_fn(A5)
	MOVE.w	#ORBIT_BOSS_APPROACH_TICKS, obj_attack_timer(A5)
	CLR.b	orbit_charge_dir(A5)
	JSR	ProcessPlayerStrengthCheck
	RTS
	
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
	
OrbitBoss_InnerWaitProjectile:
	MOVEA.l	Object_slot_02_ptr.w, A6
	BTST.b	#7, (A6)
	BNE.b	OrbitBoss_InnerWaitProjectile_Loop
	MOVE.l	#OrbitBoss_InnerSelectTarget, obj_tick_fn(A5)
OrbitBoss_InnerWaitProjectile_Loop:
	RTS
	
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
OrbitBoss_OuterSelectTarget_Done2:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	MOVE.l	#OrbitBoss_SatelliteOrbitInactive, obj_tick_fn(A6)
	DBF	D7, OrbitBoss_OuterSelectTarget_Done2
OrbitBoss_OuterSelectTarget_Loop:
	MOVE.l	#OrbitBoss_OuterApproach, obj_tick_fn(A5)
	MOVE.w	#ORBIT_BOSS_APPROACH_TICKS, obj_attack_timer(A5)
	CLR.b	orbit_charge_dir(A5)
	JSR	ProcessBossFightDamage
	RTS
	
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
	
OrbitBoss_OuterSpawnProjectile_DeadCode:					; unreferenced dead code
	MOVEA.l	Object_slot_02_ptr.w, A6
	BTST	#7, (A6)
	BNE.b	OrbitBoss_OuterSpawnProjectile_Loop
	MOVE.l	#OrbitBoss_OuterSelectTarget, obj_tick_fn(A5)
OrbitBoss_OuterSpawnProjectile_Loop:
	JSR	ProcessBossFightDamage
	RTS
OrbitBoss_OuterWaitProjectile:
	MOVEA.l	Object_slot_04_ptr.w, A6
	BTST.b	#7, (A6)
	BNE.b	OrbitBoss_OuterWaitProjectile_Loop
	MOVE.l	#OrbitBoss_OuterSelectTarget, obj_tick_fn(A5)
OrbitBoss_OuterWaitProjectile_Loop:
	JSR	ProcessBossFightDamage
	RTS

GetSignedVelocity:
	MOVE.w	obj_attack_timer(A5), D0
	TST.b	orbit_charge_dir(A5)
	BGE.b	GetSignedVelocity_Loop
	NEG.w	D0
GetSignedVelocity_Loop:
	RTS

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
	BLE.b	OrbitBossProjectileFallTick_Loop2
	MOVE.w	#ORBIT_PROJ_Y_FLOOR, obj_world_y(A5)
	CLR.b	obj_move_counter(A5)
	MOVE.l	#OrbitBoss_ProjectileExplode, obj_tick_fn(A5)
OrbitBossProjectileFallTick_Loop2:
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	CheckEntityPlayerCollisionAndDamage
	JSR	AddSpriteToDisplayList
	RTS

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
	BGT.b	ProcessPlayerStrengthCheck_Loop2
	MOVE.w	#SOUND_MAGIC_EFFECT, D0
	JSR	QueueSoundEffect
	CLR.b	obj_move_counter(A5)
	MOVE.l	#OrbitBoss_InnerPartDeath, obj_tick_fn(A5)
	RTS

ProcessPlayerStrengthCheck_Loop2:
	MOVE.w	#SOUND_HEAL, D0
	JSR	QueueSoundEffect
	MOVE.w	#BOSS_HIT_STUN_FRAMES, obj_knockback_timer(A5)
OrbitBoss_InnerPartHit_Return:
	CLR.b	obj_hit_flag(A5)
	RTS

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
	BGT.b	OrbitBoss_InnerPartDeath_Loop2
	MOVE.l	#OrbitBoss_InnerRingDefeated, obj_tick_fn(A5)
OrbitBoss_InnerPartDeath_Loop2:
	RTS

OrbitBoss_InnerPartDeath_Loop:
	ASR.w	#3, D0
	LEA	OrbitBoss_ProjectileFrames, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A6)
	RTS

OrbitBoss_InnerRingDefeated:
	MOVE.b	#FLAG_TRUE, Boss_defeated_flag.w
	RTS

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
	BGT.b	ProcessBossFightDamage_Loop2
	MOVE.w	#SOUND_MAGIC_EFFECT, D0
	JSR	QueueSoundEffect
	CLR.b	obj_move_counter(A5)
	MOVE.l	#OrbitBoss_OuterPartDeath, obj_tick_fn(A5)
	RTS

ProcessBossFightDamage_Loop2:
	MOVE.w	#SOUND_HEAL, D0
	JSR	QueueSoundEffect
	MOVE.w	#BOSS_HIT_STUN_FRAMES, obj_knockback_timer(A5)
OrbitBoss_OuterPartHit_Return:
	CLR.b	obj_hit_flag(A5)
	RTS

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
	BGT.b	OrbitBoss_OuterPartDeath_Loop2
	MOVE.l	#OrbitBoss_OuterRingDefeated, obj_tick_fn(A5)
OrbitBoss_OuterPartDeath_Loop2:
	RTS

OrbitBoss_OuterPartDeath_Loop:
	ASR.w	#3, D0
	LEA	OrbitBoss_ProjectileFrames, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A6)
	RTS

OrbitBoss_OuterRingDefeated:
	MOVE.b	#FLAG_TRUE, Boss_death_anim_done.w
	RTS

OrbitBoss_SatelliteOrbitInactive:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	BSR.w	CalculateDirectionToEntity
OrbitBoss_SatelliteAnimate:
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	ANDI.w	#$0018, D0
	ASR.w	#2, D0
	LEA	OrbitBoss_SatelliteFrames, A0
	MOVE.w	(A0,D0.w), obj_tile_index(A5)
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

InitHydraBoss_Normal:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#BOSS_HP_HYDRA_NORMAL, obj_hp(A6)
	MOVE.w	#BOSS_DMG_HYDRA_NORMAL, obj_max_hp(A6)
	BRA.w	InitHydraBoss_Common
InitHydraBoss_Hard:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#BOSS_HP_HYDRA_HARD, obj_hp(A6)
	MOVE.w	#BOSS_DMG_HYDRA_HARD, obj_max_hp(A6)
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
	BCC.b	HydraBoss_PartIdleTick_Loop2
	MOVE.l	#HydraBoss_PartDeathAnim, obj_tick_fn(A5)
	MOVE.w	#SOUND_MAGIC_EFFECT, D0
	JSR	QueueSoundEffect
	CLR.b	obj_move_counter(A5)
	BRA.w	HydraBoss_PartIdleTick_UpdatePos
HydraBoss_PartIdleTick_Loop2:
	MOVE.w	#SOUND_HYDRA_BITE, D0
	JSR	QueueSoundEffect
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
	BGE.b	HydraBoss_PartIdleTick_Check_Loop2
	LEA	HydraBoss_AttackAnimFrames, A0
	LEA	(A0,D0.w), A0
	MOVE.w	(A0)+, obj_tile_index(A5)
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVE.b	(A0)+, obj_hitbox_x_neg(A5)
	MOVE.b	(A0), obj_hitbox_x_pos(A5)
	BRA.w	HydraBoss_PartIdleTick_UpdatePos
HydraBoss_PartIdleTick_Check_Loop2:
	CLR.b	obj_move_counter(A5)
	CLR.b	obj_npc_busy_flag(A5)
	BRA.w	HydraBoss_PartIdleTick_UpdatePos
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
	BCC.b	HydraBoss_MainTick_Loop2
	MOVE.l	#HydraBoss_MainDeathAnim, obj_tick_fn(A5)
	MOVE.w	#SOUND_MAGIC_EFFECT, D0
	JSR	QueueSoundEffect
	CLR.b	obj_move_counter(A5)
	BRA.w	HydraBoss_MainTick_SpriteUpdate
HydraBoss_MainTick_Loop2:
	MOVE.w	#SOUND_HEAL, D0
	JSR	QueueSoundEffect
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
	MOVE.w	#SOUND_DOOR_OPEN, D0
	JSR	QueueSoundEffect
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
	
HydraBoss_DeathPauseWait:
	SUBQ.b	#1, obj_move_counter(A5)
	BGT.b	HydraBoss_DeathPauseWait_Loop
	MOVE.l	#HydraBoss_DeathClearScreen, obj_tick_fn(A5)
	CLR.w	Dialog_timer.w
	CLR.w	Dialog_phase.w
	MOVE.w	#SOUND_PURCHASE, D0
	JSR	QueueSoundEffect
HydraBoss_DeathPauseWait_Loop:
	JSR	AddSpriteToDisplayList
	RTS
	
HydraBoss_DeathClearScreen:
	ADDQ.w	#1, Dialog_timer.w
	MOVE.w	Dialog_timer.w, D0
	ANDI.w	#7, D0
	BNE.b	HydraBoss_DeathClearScreen_Loop
	CMPI.w	#BOSS_VICTORY_FADE_PHASES, Dialog_phase.w
	BLT.b	HydraBoss_DeathClearScreen_Loop2
	MOVE.l	#HydraBoss_VictoryCheck, obj_tick_fn(A5)
	MOVE.b	#BOSS_VICTORY_PAUSE, obj_invuln_timer(A5)
	BSR.w	DeactivateBossBodyParts
	RTS
	
HydraBoss_DeathClearScreen_Loop2:
	JSR	ClearDialogPlane
HydraBoss_DeathClearScreen_Loop:
	JSR	AddSpriteToDisplayList
	RTS
	
HydraBoss_VictoryCheck:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BNE.b	HydraBoss_VictoryCheck_Loop
	BSR.w	ProcessBattleVictoryEvent
	TST.b	Swaffham_miniboss_defeated.w
	BNE.b	HydraBoss_VictoryCheck_Loop2
	MOVE.l	#BossCommon_VictoryRewardSequence, obj_tick_fn(A5)
	MOVE.w	#BOSS_VICTORY_DELAY_FRAMES, Dialog_timer.w
	RTS
	
HydraBoss_VictoryCheck_Loop2:
	MOVE.l	#HydraBoss_StartNextBattle, obj_tick_fn(A5)
HydraBoss_VictoryCheck_Loop:
	RTS
	
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
	
HydraBoss_LaunchProjectile:
	MOVEA.l	Object_slot_01_ptr.w, A6
	MOVE.l	#$FFFD0000, obj_vel_x(A6)
	MOVE.w	#$0114, obj_world_x(A6)
	MOVE.w	#$0084, obj_world_y(A6)
	MOVE.w	#VRAM_TILE_HYDRA_PROJECTILE, obj_tile_index(A6)
	MOVE.l	#HydraBoss_ProjectileFalling, obj_tick_fn(A6)
	RTS
	
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
	
HydraBoss_DeactivateProjectile:
	MOVEA.l	Object_slot_01_ptr.w, A6
	BCLR.b	#7, (A6)
	RTS
	
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
	
InitRingGuardian_Normal:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#6500, obj_hp(A6)
	MOVE.w	#180, obj_max_hp(A6)
	BRA.b	InitRingGuardian_Common
InitRingGuardian_Hard:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#7000, obj_hp(A6)
	MOVE.w	#200, obj_max_hp(A6)
	BRA.b	InitRingGuardian_Common
InitRingGuardian_VeryHard:
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#7000, obj_hp(A6)
	MOVE.w	#200, obj_max_hp(A6)
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
InitRingGuardian_Common_Done2:
	BSET.b	#7, (A4)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A4)
	BCLR.b	#7, obj_sprite_flags(A4)
	BCLR.b	#3, obj_sprite_flags(A4)
	BCLR.b	#4, obj_sprite_flags(A4)
	MOVE.l	#BossCommon_DisplaySprite, obj_tick_fn(A4)
	CLR.w	D0
	MOVE.b	obj_next_offset(A4), D0
	LEA	(A4,D0.w), A4
	DBF	D7, InitRingGuardian_Common_Done2
	CLR.b	obj_move_counter(A6)
	MOVE.l	#RingGuardian_BodyGroupBTick, obj_tick_fn(A6)
	RTS
	
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
BossCommon_DisplaySprite:
	TST.w	obj_tile_index(A5)
	BEQ.b	BossCommon_DisplaySprite_Loop
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
BossCommon_DisplaySprite_Loop:
	RTS
	
RingGuardian_MainTick:
	MOVE.w	Boss_ai_state.w, D0
	ANDI.w	#$000F, D0
	LEA	BossAiRingGuardianJumpTable, A0
	ADD.w	D0, D0
	ADD.w	D0, D0
	JSR	(A0,D0.w)
	RTS
	
BossAiRingGuardianJumpTable:
	BRA.w	RingGuardianState_WaitBattleStart
	BRA.w	RingGuardianState_Descend
	BRA.w	RingGuardianState_ChasePlayer
	BRA.w	RingGuardianState_AttackWindup
	BRA.w	RingGuardianState_WaitProjectile
	BRA.w	RingGuardianState_ChasePlayer	
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
RingGuardianState_Descend:
	SUBQ.b	#1, obj_invuln_timer(A5)
	BLT.b	RingGuardianState_Descend_Loop
	MOVE.w	#$00D0, D0
	SUB.w	obj_world_x(A5), D0
	BGE.b	RingGuardianState_Descend_Loop2
	MOVE.w	#8, D1	
	SUB.w	obj_world_y(A5), D1	
	BRA.b	RingGuardianState_Patrol_GetDir	
RingGuardianState_Descend_Loop2:
	MOVE.w	#8, D1
	SUB.w	obj_world_y(A5), D1
	BLT.b	RingGuardianState_Patrol_GetDir
RingGuardianState_Descend_Loop:
	TST.w	obj_hp(A5)
	BGT.b	RingGuardianState_Descend_Loop3
	MOVE.b	#FLAG_TRUE, Boss_defeated_flag.w
	MOVE.l	#RingGuardian_DeathFall, obj_tick_fn(A5)
	MOVE.l	#$8000, obj_vel_y(A5)
	RTS
	
RingGuardianState_Descend_Loop3:
	MOVE.w	#BOSS1_STATE_MOVE_DOWN, Boss_ai_state.w
	MOVE.l	#$400, obj_pos_x_fixed(A5)
	RTS
	
RingGuardianState_Patrol_GetDir:
	BSR.w	GetDirectionFromDeltas
	BRA.w	RingGuardianState_ApplyVelocity
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
	BLE.b	RingGuardianState_ApplyVelocity_Loop2
	MOVE.w	#RING_GUARDIAN_X_RIGHT, obj_world_x(A5)	
	CLR.l	obj_vel_x(A5)	
RingGuardianState_ApplyVelocity_Loop2:
	SUB.l	D3, obj_world_y(A5)
	BGE.b	RingGuardianState_ApplyVelocity_Loop3
	CLR.w	obj_world_y(A5)
RingGuardianState_ApplyVelocity_Loop3:
	CMPI.w	#RING_GUARDIAN_HEAD_Y, obj_world_y(A5)
	BLE.b	BossMoveTick_Clamped
	MOVE.w	#RING_GUARDIAN_HEAD_Y, obj_world_y(A5)
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
	MOVE.w	#SOUND_HEAL, D0
	JSR	QueueSoundEffect
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
	MOVE.w	#SOUND_DOOR_OPEN, D0
	JSR	QueueSoundEffect
	MOVE.w	#SOUND_PURCHASE, D0
	JSR	QueueSoundEffect
RingGuardian_DeathFall_Loop:
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	D0, HScroll_base.w
	MOVE.w	#$0200, D0
	SUB.w	obj_world_y(A5), D0
	MOVE.w	D0, VScroll_base.w
	RTS
	
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
	
RingGuardian_ExitWait:
	SUBQ.w	#1, Dialog_timer.w
	BGT.b	RingGuardian_ExitWait_Loop
	JSR	ProcessBattleVictoryEvent
	MOVE.b	#FLAG_TRUE, Boss_battle_exit_flag.w
RingGuardian_ExitWait_Loop:
	RTS
	
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
	BLE.b	RingGuardian_ProjectileSpawner_Loop2
	MOVE.l	#RingGuardian_WaitChildrenDone, obj_tick_fn(A5)
	RTS
	
RingGuardian_ProjectileSpawner_Loop2:
	LEA	(A5), A6
	SUBQ.w	#1, D0
RingGuardian_ProjectileSpawner_Loop2_Done:
	CLR.w	D1
	MOVE.b	obj_next_offset(A6), D1
	LEA	(A6,D1.w), A6
	DBF	D0, RingGuardian_ProjectileSpawner_Loop2_Done
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
	MOVE.w	#SOUND_SAVE, D0
	JSR	QueueSoundEffect
RingGuardian_ProjectileSpawner_Loop:
	RTS
	
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
	BLT.b	RingGuardian_ChildProjectileTick_Loop2
	MOVE.w	#ORBIT_PROJ_Y_FLOOR, obj_world_y(A5)
	MOVE.l	#RingGuardian_ChildGroundImpact, obj_tick_fn(A5)
	CLR.b	obj_move_counter(A5)
RingGuardian_ChildProjectileTick_Loop2:
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS
	
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
UpdateBossBodyTiles_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$A200, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, UpdateBossBodyTiles_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, UpdateBossBodyTiles_Done
	MOVE.l	#$41800003, D5
	MOVE.w	#2, D7
UpdateBossBodyTiles_Done3:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#3, D6
UpdateBossBodyTiles_Done4:
	CLR.w	D0
	MOVE.b	(A1)+, D0
	ADDI.w	#$A200, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, UpdateBossBodyTiles_Done4
	ADDI.l	#$00800000, D5
	DBF	D7, UpdateBossBodyTiles_Done3
	ANDI	#$F8FF, SR
	RTS
	
