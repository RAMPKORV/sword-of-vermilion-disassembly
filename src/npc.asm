; ======================================================================
; src/npc.asm
; NPC behavior tick and init functions for all town NPCs, plus shared
; movement, collision, and animation utilities.
;
; Key responsibilities:
;   - Per-NPC init routines: set initial tick function, direction, and
;     sprite state for every named NPC in the game world.
;   - Per-NPC tick routines: poll event-trigger flags each frame and
;     update dialogue string pointer and sprite accordingly.
;   - Generic NPC movement: wandering, direction changes, collision.
;   - Animation helpers: static/walking/animated sprite frame selection.
;   - Inventory helpers: add/remove/check items and magic in player lists.
;   - Object-slot initialization: set up chain, paired, single, and
;     map-indicator display objects used by the battle/portrait system.
;   - Talker portrait init/tick: NPC dialogue portrait display logic.
;   - Encounter initialization: place enemies with randomized positions.
; ======================================================================

;==============================================================
; GENERIC NPC BEHAVIORS
; Core behavior tick/init pairs shared across many NPC types.
;==============================================================

; NPCTick_Soldier_Init
; Init a 2x3-sprite soldier NPC; sets its tick to UpdatePos.
NPCTick_Soldier_Init:
	MOVE.b	#SPRITE_SIZE_2x3, obj_sprite_size(A5)
	MOVE.l	#NPCTick_Soldier_UpdatePos, obj_tick_fn(A5)
	RTS

NPCTick_Soldier_UpdatePos:
	BRA.w	UpdateNPCScreenPosition
	MOVE.b	#SPRITE_SIZE_2x3, obj_sprite_size(A5)
	MOVE.l	#NPCTick_StowSoldier_DoctorHint, obj_tick_fn(A5)
	RTS

; NPCTick_StowSoldier_DoctorHint
; Tick for the Stow soldier who hints about the doctor.
; Shows BringDoctorHereStr when innocence is not yet proven,
; the Asti monster has been defeated, and the hint trigger is set.
NPCTick_StowSoldier_DoctorHint:
	TST.b	Stow_innocence_proven.w
	BNE.b	NPCTick_StowSoldier_DoctorHint_Done
	TST.b	Asti_monster_defeated.w
	BEQ.b	NPCTick_StowSoldier_DoctorHint_Done
	LEA	Map_trigger_flags.w, A0
	MOVE.w	#$5D, D5
	TST.b	(A0,D5.w)
	BEQ.b	NPCTick_StowSoldier_DoctorHint_Done
	MOVE.l	#BringDoctorHereStr, obj_npc_str_ptr(A5)
NPCTick_StowSoldier_DoctorHint_Done:
	BRA.w	UpdateNPCScreenPosition
; NPCInit_StowSoldier_DoctorHint
; Init for the Stow doctor-hint soldier: randomize direction,
; then run UpdateNPCSpriteFrame each tick.
NPCInit_StowSoldier_DoctorHint:
	BSR.w	SetRandomDirection
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS

; UpdateNPCSpriteFrame
; Tick: load a static animation frame and restore saved direction.
; Uses LoadNPCAnimFrame_Static (no walking cycle), then increments
; obj_move_counter for animation timing.
UpdateNPCSpriteFrame:
	MOVEA.l	obj_anim_ptr(A5), A1
	MOVE.b	#FLAG_TRUE, obj_behavior_flag(A5)
	BSR.w	LoadNPCAnimFrame_Static
	MOVE.b	obj_npc_saved_dir(A5), obj_direction(A5)
	ADDQ.b	#1, obj_move_counter(A5)
	RTS

; NPCInit_WalkingStatic
; Init an NPC that walks around but uses a static (non-walking) sprite.
NPCInit_WalkingStatic:
	BSR.w	SetRandomDirection
	MOVE.l	#NPCTick_WalkingStatic, obj_tick_fn(A5)
	CLR.b	obj_behavior_flag(A5)
	RTS

; NPCTick_WalkingStatic
; Tick: unfreeze, move, then display a static animation frame.
NPCTick_WalkingStatic:
	BSR.w	ClearNPCFrozenState
	BSR.w	UpdateNPCMovement
	MOVEA.l	obj_anim_ptr(A5), A1
	BRA.w	LoadNPCAnimFrame_Static
; NPCInit_WalkingStatic_LoadFrame
; Variant init: sets tick to NPCBehavior_LoadFrame (animated frame load).
NPCInit_WalkingStatic_LoadFrame:
	BSR.w	SetRandomDirection
	MOVE.l	#NPCBehavior_LoadFrame, obj_tick_fn(A5)
	RTS

; NPCBehavior_LoadFrame
; Tick: load an animated frame (direction-cycled) and restore direction.
; Outputs: obj_tile_index updated; obj_move_counter incremented.
NPCBehavior_LoadFrame:
	MOVEA.l	obj_anim_ptr(A5), A1
	MOVE.b	#FLAG_TRUE, obj_behavior_flag(A5)
	BSR.w	LoadNPCAnimationFrame
	MOVE.b	obj_npc_saved_dir(A5), obj_direction(A5)
	ADDQ.b	#1, obj_move_counter(A5)
	RTS

; NPCInit_WalkingAnimated
; Init an NPC that walks around with a walking animation cycle.
NPCInit_WalkingAnimated:
	BSR.w	SetRandomDirection
	MOVE.l	#NPCTick_WalkingAnimated, obj_tick_fn(A5)
	CLR.b	obj_behavior_flag(A5)
	RTS

; NPCTick_WalkingAnimated
; Tick: unfreeze, move, then display a walking animation frame.
NPCTick_WalkingAnimated:
	BSR.w	ClearNPCFrozenState
	BSR.w	UpdateNPCMovement
	MOVEA.l	obj_anim_ptr(A5), A1
	BRA.w	LoadNPCAnimationFrame
; NPCInit_WalkingAnimated_Animate
; Variant init: plays AnimateEntitySprite tick (no movement).
NPCInit_WalkingAnimated_Animate:
	MOVE.l	#NPCTick_AnimateEntity, obj_tick_fn(A5)
	RTS

; NPCTick_AnimateEntity
; Tick: run AnimateEntitySprite (simple 2-frame flip cycle) in place.
NPCTick_AnimateEntity:
	MOVEA.l	obj_anim_ptr(A5), A1
	MOVE.b	#FLAG_TRUE, obj_behavior_flag(A5)
	BSR.w	AnimateEntitySprite
	ADDQ.b	#1, obj_move_counter(A5)
	RTS

;==============================================================
; PARMA TOWN NPCs
; NPCs located in Parma: fairy, Wyclif, and king's quest chain.
;==============================================================

; NPCInit_ParmaFairy
; Init the Parma fairy NPC.
; If Blade is dead, hides the object; otherwise sets ParmaFairy tick.
NPCInit_ParmaFairy:
	TST.b	Blade_is_dead.w
	BEQ.b	NPCInit_ParmaFairy_Loop
	BCLR.b	#7, (A5)
	RTS

NPCInit_ParmaFairy_Loop:
	MOVE.l	#NPCTick_ParmaFairy, obj_tick_fn(A5)
	RTS

; NPCTick_ParmaFairy
; Tick: if Blade is dead, show NoAnswerStr; then animate in place.
NPCTick_ParmaFairy:
	TST.b	Blade_is_dead.w
	BEQ.b	NPCTick_ParmaFairy_Loop
	MOVE.l	#NoAnswerStr, obj_npc_str_ptr(A5)
NPCTick_ParmaFairy_Loop:
	BRA.b	NPCTick_AnimateEntity
; NPCInit_Wyclif_ParmaFindRing
; Init Wyclif in Parma (find ring quest stage).
; If Blade is dead, uses LoadFrame tick; otherwise ParmaFindRing tick.
NPCInit_Wyclif_ParmaFindRing:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Blade_is_dead.w
	BEQ.b	NPCInit_Wyclif_ParmaFindRing_Loop
	MOVE.l	#NPCBehavior_LoadFrame, obj_tick_fn(A5)
	RTS

NPCInit_Wyclif_ParmaFindRing_Loop:
	MOVE.l	#NPCTick_ParmaFindRing, obj_tick_fn(A5)
	RTS

; NPCTick_ParmaFindRing
; Tick: if Blade is dead, show FindRingStr; else idle load frame.
NPCTick_ParmaFindRing:   
	TST.b	Blade_is_dead.w
	BEQ.b	NPCTick_ParmaFindRing_Loop
	MOVE.l	#FindRingStr, obj_npc_str_ptr(A5)
NPCTick_ParmaFindRing_Loop:
	BRA.w	NPCBehavior_LoadFrame
; NPCInit_Wyclif_UseMapHint1
; Init Wyclif for "use map" hint stage 1 (before rings collected).
NPCInit_Wyclif_UseMapHint1:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Wyclif_UseMapHint1, obj_tick_fn(A5)
	RTS

; NPCTick_Wyclif_UseMapHint1
; Tick: hint to use the map if rings not yet collected (trigger $70).
NPCTick_Wyclif_UseMapHint1:  
	TST.b	Rings_collected.w
	BNE.b	NPCTick_Wyclif_UseMapHint1_Loop
	MOVE.l	#UseMapStr, Pending_hint_text.w
	MOVE.w	#$0070, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Wyclif_UseMapHint1_Loop:
	BRA.w	UpdateNPCSpriteFrame
; NPCInit_Wyclif_UseMapHint2Init
; Init Wyclif for "use map" hint stage 2 (after rings collected).
NPCInit_Wyclif_UseMapHint2Init:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Wyclif_UseMapHint2, obj_tick_fn(A5)
	RTS

; NPCTick_Wyclif_UseMapHint2
; Tick: hint to use the map when rings ARE collected (trigger $51).
NPCTick_Wyclif_UseMapHint2:
	TST.b	Rings_collected.w
	BEQ.b	NPCTick_Wyclif_UseMapHint2_Loop
	MOVE.l	#UseMapStr, Pending_hint_text.w
	MOVE.w	#$0051, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Wyclif_UseMapHint2_Loop:
	BRA.w	UpdateNPCSpriteFrame
; NPCInit_Wyclif_UseMapHint2
; Init Wyclif for "use map" hint stage 3 (unconditional).
NPCInit_Wyclif_UseMapHint2:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Wyclif_UseMapHint3, obj_tick_fn(A5)
	RTS

; NPCTick_Wyclif_UseMapHint3
; Tick: always hint to use the map (trigger $40, no condition check).
NPCTick_Wyclif_UseMapHint3:   
	MOVE.l	#UseMapStr, Pending_hint_text.w
	MOVE.w	#$0040, D5
	BSR.w	SetHintTextIfTriggered
	BRA.w	UpdateNPCSpriteFrame
; NPCInit_Parma_AdviceHint
; Init a Parma townsperson who gives advice about the king's quest.
NPCInit_Parma_AdviceHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Parma_AdviceHint, obj_tick_fn(A5)
	RTS

; NPCTick_Parma_AdviceHint
; Tick: show advice hint based on story stage (real king talked to,
; or Treasure of Troy challenge issued).
NPCTick_Parma_AdviceHint:
	TST.b	Talked_to_real_king.w
	BEQ.b	NPCTick_Parma_AdviceHint_Loop
	MOVE.l	#AdviceForQuestionsStr, Pending_hint_text.w	
	MOVE.w	#$0044, D5	
	BSR.w	SetHintTextIfTriggered	
	BRA.b	NPCTick_Parma_HintDone	
NPCTick_Parma_AdviceHint_Loop:
	TST.b	Treasure_of_troy_challenge_issued.w
	BEQ.b	NPCTick_Parma_HintDone
	MOVE.l	#AdviceForQuestionsStr, Pending_hint_text.w
	MOVE.w	#$0052, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Parma_HintDone:
	BRA.w	UpdateNPCSpriteFrame
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Talked_to_real_king.w
	BEQ.b	NPCTick_Parma_HintDone_Loop
	MOVE.l	#GotRingStr, obj_npc_str_ptr(A5)
	BRA.b	NPCTick_Parma_AdviceHint_Done
NPCTick_Parma_HintDone_Loop:
	TST.b	Fake_king_killed.w
	BEQ.b	NPCTick_Parma_HintDone_Loop2
	BCLR.b	#7, (A5)
	RTS

NPCTick_Parma_HintDone_Loop2:
	TST.b	Talked_to_king_after_given_treasure_of_troy.w
	BEQ.b	NPCTick_Parma_HintDone_Loop3
	MOVE.l	#NeedPermanentSolutionStr, obj_npc_str_ptr(A5)
	BRA.b	NPCTick_Parma_AdviceHint_Done
NPCTick_Parma_HintDone_Loop3:
	TST.b	Treasure_of_troy_found.w
	BNE.b	NPCTick_Parma_HintDone_Loop4
	TST.b	Treasure_of_troy_challenge_issued.w
	BNE.b	NPCTick_Parma_AdviceHint_Done
NPCTick_Parma_HintDone_Loop4:
	MOVE.l	#NPCTick_Parma_TreasureQuest, obj_tick_fn(A5)
	RTS

NPCTick_Parma_AdviceHint_Done:
	MOVE.l	#NPCBehavior_LoadFrame, obj_tick_fn(A5)
	RTS

; NPCTick_Parma_TreasureQuest
; Tick: manage the Treasure of Troy quest dialogue for this Parma NPC.
; Removes the Treasure of Troy item once it has been given to the king.
NPCTick_Parma_TreasureQuest:  
	TST.b	Treasure_of_troy_given_to_king.w
	BEQ.b	NPCTick_Parma_TreasureQuest_Loop
	MOVE.l	#NicePlaceStr, obj_npc_str_ptr(A5)
	LEA	Possessed_items_list.w, A3
	LEA	Possessed_items_length.w, A2
	MOVE.w	#((ITEM_TYPE_NON_DISCARDABLE<<8)|ITEM_TREASURE_OF_TROY), D4
	BSR.w	RemoveItemFromList
	BRA.b	NPCTick_Parma_TreasureQuest_Done
NPCTick_Parma_TreasureQuest_Loop:
	TST.b	Treasure_of_troy_found.w
	BEQ.b	NPCTick_Parma_TreasureQuest_Loop2
	MOVE.l	#TreasureReturnedStr, obj_npc_str_ptr(A5)
	BRA.b	NPCTick_Parma_TreasureQuest_Done
NPCTick_Parma_TreasureQuest_Loop2:
	TST.b	Treasure_of_troy_challenge_issued.w
	BEQ.b	NPCTick_Parma_TreasureQuest_Done
	MOVE.l	#FindTreasureStr, obj_npc_str_ptr(A5)
NPCTick_Parma_TreasureQuest_Done:
	BRA.w	UpdateNPCSpriteFrame
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Talked_to_real_king.w
	BEQ.b	NPCTick_Parma_TreasureQuest_Done_Loop
	BCLR.b	#7, (A5)
	RTS

NPCTick_Parma_TreasureQuest_Done_Loop:
	MOVE.l	#NPCTick_Parma_GotRingReaction, obj_tick_fn(A5)
	RTS

; NPCTick_Parma_GotRingReaction
; Tick: show GotRingStr after player has talked to the real king.
NPCTick_Parma_GotRingReaction:
	TST.b	Talked_to_real_king.w
	BEQ.b	NPCTick_Parma_GotRingReaction_Loop
	MOVE.l	#GotRingStr, obj_npc_str_ptr(A5)
NPCTick_Parma_GotRingReaction_Loop:
	BRA.w	UpdateNPCSpriteFrame
; NPCInit_Parma_GotRingReaction
; Init: if Watling youth was restored, swap to ManA sprite.
; Then set WalkingStatic tick.
NPCInit_Parma_GotRingReaction:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Watling_youth_restored.w
	BEQ.b	NPCInit_Parma_GotRingReaction_Loop
	MOVE.w	#VRAM_TILE_NPC_MAN_A, obj_tile_index(A5)
	MOVE.l	#NPCSpriteFrames_ManA, obj_anim_ptr(A5)
NPCInit_Parma_GotRingReaction_Loop:
	MOVE.l	#NPCTick_WalkingStatic, obj_tick_fn(A5)
	RTS

;==============================================================
; WATLING TOWN NPCs
; NPCs in Watling: youth restoration, cave hints, and gratitude.
;==============================================================

; NPCInit_Watling_RestoredYouth
; Init: if youth was restored, swap to ManB sprite and static tick;
; otherwise set VerlinsCaveHint tick.
NPCInit_Watling_RestoredYouth:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Watling_youth_restored.w
	BEQ.b	NPCInit_Watling_RestoredYouth_Loop
	MOVE.w	#VRAM_TILE_NPC_MAN_B, obj_tile_index(A5)
	MOVE.l	#NPCSpriteFrames_ManB, obj_anim_ptr(A5)
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS

NPCInit_Watling_RestoredYouth_Loop:
	MOVE.l	#NPCTick_Watling_VerlinsCaveHint, obj_tick_fn(A5)
	RTS

; NPCTick_Watling_VerlinsCaveHint
; Tick: hint to go north to Verlin's Cave (trigger $36).
NPCTick_Watling_VerlinsCaveHint:       
	MOVE.l	#GoNorthVerlinsCaveStr, Pending_hint_text.w
	MOVE.w	#$36, D5
	BSR.w	SetHintTextIfTriggered
	BRA.w	UpdateNPCSpriteFrame
; NPCInit_Watling_VerlinsCaveHint
; Init: if youth restored, swap sprite and set ThankYou tick;
; otherwise static sprite tick.
NPCInit_Watling_VerlinsCaveHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Watling_youth_restored.w
	BEQ.b	NPCInit_Watling_VerlinsCaveHint_Loop
	MOVE.w	#VRAM_TILE_NPC_MAN_B, obj_tile_index(A5)
	MOVE.l	#NPCSpriteFrames_ManB, obj_anim_ptr(A5)
	MOVE.l	#NPCTick_Watling_ThankYou, obj_tick_fn(A5)
	RTS

NPCInit_Watling_VerlinsCaveHint_Loop:
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS

; NPCTick_Watling_ThankYou
; Tick: hint "thank you stranger" (trigger $65).
NPCTick_Watling_ThankYou:
	MOVE.l	#ThankYouStrangerStr, Pending_hint_text.w
	MOVE.w	#$65, D5
	BSR.w	SetHintTextIfTriggered
	BRA.w	UpdateNPCSpriteFrame
; NPCInit_Watling_ThankYou
; Init: if youth restored, swap to VillagerC sprite and LoadFrame tick.
NPCInit_Watling_ThankYou:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Watling_youth_restored.w
	BEQ.b	NPCInit_Watling_ThankYou_Loop
	MOVE.w	#VRAM_TILE_NPC_VILLAGER_C, obj_tile_index(A5)
	MOVE.l	#NPCSpriteFrames_VillagerC, obj_anim_ptr(A5)
	MOVE.l	#NPCBehavior_LoadFrame, obj_tick_fn(A5)
	RTS

NPCInit_Watling_ThankYou_Loop:
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS

;==============================================================
; DEEPDALE TOWN NPCs
; NPCs in Deepdale: secret keeper, Bremen's cave hint, road warning.
;==============================================================

; NPCInit_Deepdale_SecretKeeper
; Init: if king's secret is already kept, use static tick;
; otherwise set SecretKeeper tick to handle item removal.
NPCInit_Deepdale_SecretKeeper:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Deepdale_king_secret_kept.w
	BNE.b	NPCInit_Deepdale_SecretKeeper_Loop
	MOVE.l	#NPCTick_Deepdale_SecretKeeper, obj_tick_fn(A5)
	RTS

NPCInit_Deepdale_SecretKeeper_Loop:
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)	
	RTS
	
; NPCTick_Deepdale_SecretKeeper
; Tick: if secret was kept, show KeptSecretStr and remove medicine
; from inventory (item $010B) if not yet removed.
NPCTick_Deepdale_SecretKeeper:
	TST.b	Deepdale_king_secret_kept.w
	BEQ.b	NPCTick_Deepdale_MedicineDone
	MOVE.l	#KeptSecretStr, obj_npc_str_ptr(A5)
	TST.b	Deepdale_medicine_removed.w
	BNE.b	NPCTick_Deepdale_MedicineDone
	LEA	Possessed_items_list.w, A3
	LEA	Possessed_items_length.w, A2
	MOVE.w	#$010B, D4
	BSR.w	RemoveItemFromList
	MOVE.b	#FLAG_TRUE, Deepdale_medicine_removed.w
NPCTick_Deepdale_MedicineDone:
	BRA.w	UpdateNPCSpriteFrame
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Deepdale_BremensCaveHint, obj_tick_fn(A5)
	RTS

; NPCTick_Deepdale_BremensCaveHint
; Tick: if truffle quest started and secret not kept, hint about
; Bremen's Cave to the northwest (trigger $62).
NPCTick_Deepdale_BremensCaveHint:
	TST.b	Deepdale_king_secret_kept.w
	BNE.b	NPCTick_Deepdale_CaveHintDone
	TST.b	Deepdale_truffle_quest_started.w
	BEQ.b	NPCTick_Deepdale_CaveHintDone
	MOVE.l	#BremensCaveNorthwestStr, Pending_hint_text.w
	MOVE.w	#$62, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Deepdale_CaveHintDone:
	BRA.w	UpdateNPCSpriteFrame
; NPCInit_Deepdale_BremensCaveHint
; Init: sets StowRoadWarning as the NPC tick.
NPCInit_Deepdale_BremensCaveHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Deepdale_StowRoadWarning, obj_tick_fn(A5)
	RTS

; NPCTick_Deepdale_StowRoadWarning
; Tick: if king's secret was kept, warn about the dangerous road
; to Stow (trigger $7A).
NPCTick_Deepdale_StowRoadWarning:
	TST.b	Deepdale_king_secret_kept.w
	BEQ.b	NPCTick_Deepdale_StowRoadWarning_Loop
	MOVE.l	#RoadToStowDangerousStr, Pending_hint_text.w
	MOVE.w	#$7A, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Deepdale_StowRoadWarning_Loop:
	BRA.w	UpdateNPCSpriteFrame
;==============================================================
; STOW TOWN NPCs
; NPCs in Stow: Sanguios bookkeeper, thief accusers.
;==============================================================
; NPCInit_Stow_Bookkeeper (init falls through from Deepdale section)
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Stow_innocence_proven.w
	BNE.b	NPCTick_Stow_SetBookkeeperTick
	TST.b	Accused_of_theft.w
	BEQ.b	NPCTick_Stow_SetBookkeeperTick
	MOVE.l	#NPCBehavior_LoadFrame, obj_tick_fn(A5)	
	RTS
	
NPCTick_Stow_SetBookkeeperTick:
	MOVE.l	#NPCTick_Stow_SanguiosBookkeeper, obj_tick_fn(A5)
	RTS

; NPCTick_Stow_SanguiosBookkeeper
; Tick: manage the Sanguios bookkeeper's dialogue and magic grants.
; - If sent to Malaga: give Sanguia field magic (once), say HopesWithYouStr.
; - If innocence proven: give Sanguia field magic if magic list has room.
; - If accused of theft: show ReturnWhenInnocentStr, confiscate Sanguios.
NPCTick_Stow_SanguiosBookkeeper:
	TST.b	Sent_to_malaga.w
	BEQ.b	NPCTick_Stow_SanguiosBookkeeper_Loop
	MOVE.l	#HopesWithYouStr, obj_npc_str_ptr(A5)
	TST.b	Sanguia_learned_from_book.w
	BNE.w	NPCTick_Stow_Bookkeeper_Done
	LEA	Possessed_magics_length.w, A0
	MOVE.w	(A0), D0
	ADDQ.w	#1, (A0)+
	ADD.w	D0, D0
	MOVE.w	#((MAGIC_TYPE_FIELD<<8)|MAGIC_SANGUIA), (A0,D0.w)
	MOVE.b	#FLAG_TRUE, Sanguia_learned_from_book.w
	BRA.w	NPCTick_Stow_Bookkeeper_Done
NPCTick_Stow_SanguiosBookkeeper_Loop:
	TST.b	Stow_innocence_proven.w
	BEQ.b	NPCTick_Stow_SanguiosBookkeeper_Loop2
	LEA	Possessed_magics_length.w, A0
	MOVE.w	(A0), D0
	CMPI.w	#8, D0
	BLT.b	NPCTick_Stow_SanguiosBookkeeper_Loop3
	MOVE.l	#DiscardBookSpellsStr, obj_npc_str_ptr(A5)
	BRA.w	NPCTick_Stow_Bookkeeper_Done
NPCTick_Stow_SanguiosBookkeeper_Loop3:
	MOVE.l	#BookSanguiaEffortsStr, obj_npc_str_ptr(A5)
	BRA.w	NPCTick_Stow_Bookkeeper_Done
NPCTick_Stow_SanguiosBookkeeper_Loop2:
	TST.b	Accused_of_theft.w
	BEQ.w	NPCTick_Stow_Bookkeeper_Done
	MOVE.l	#ReturnWhenInnocentStr, obj_npc_str_ptr(A5)
	TST.b	Sanguios_confiscated.w
	BNE.b	NPCTick_Stow_Bookkeeper_Done
	LEA	Possessed_magics_list.w, A3
	LEA	Possessed_magics_length.w, A2
	MOVE.w	#$0116, D4
	BSR.w	RemoveItemFromList
	BSR.w	BackupRingsToMapTriggers
	MOVE.b	#FLAG_TRUE, Sanguios_confiscated.w
NPCTick_Stow_Bookkeeper_Done:
	BRA.w	NPCBehavior_LoadFrame
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Accused_of_theft.w
	BEQ.b	NPCTick_Stow_Bookkeeper_Done_Loop
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS

NPCTick_Stow_Bookkeeper_Done_Loop:
	MOVE.l	#NPCTick_Stow_ThiefAccuser1, obj_tick_fn(A5)
	RTS

; NPCTick_Stow_ThiefAccuser1
; Tick: show YoureTheThiefStr when the theft accusation is active.
NPCTick_Stow_ThiefAccuser1:
	TST.b	Accused_of_theft.w
	BEQ.b	NPCTick_Stow_ThiefAccuser1_Loop
	MOVE.l	#YoureTheThiefStr, obj_npc_str_ptr(A5)
NPCTick_Stow_ThiefAccuser1_Loop:
	BRA.w	UpdateNPCSpriteFrame
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Accused_of_theft.w
	BEQ.b	NPCTick_Stow_ThiefAccuser1_Loop2
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS

NPCTick_Stow_ThiefAccuser1_Loop2:
	MOVE.l	#NPCTick_Stow_ThiefAccuser2, obj_tick_fn(A5)
	RTS

; NPCTick_Stow_ThiefAccuser2
; Tick: show FaceOfCriminalStr when the theft accusation is active.
NPCTick_Stow_ThiefAccuser2:
	TST.b	Accused_of_theft.w
	BEQ.b	NPCTick_Stow_ThiefAccuser2_Loop
	MOVE.l	#FaceOfCriminalStr, obj_npc_str_ptr(A5)
NPCTick_Stow_ThiefAccuser2_Loop:
	BRA.w	UpdateNPCSpriteFrame
;==============================================================
; MALAGA TOWN NPCs
; NPCs in Malaga: dungeon key giver, Keltwick hint NPC.
;==============================================================

; NPCInit_Malaga_DungeonKeySetup
; Init: if Bearwulf not yet met, hide object and show static sprite;
; otherwise reset key state and set DungeonKeyGiver tick.
NPCInit_Malaga_DungeonKeySetup:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Bearwulf_met.w
	BNE.b	NPCInit_Malaga_DungeonKeySetup_Loop
	BCLR.b	#7, (A5)
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS

NPCInit_Malaga_DungeonKeySetup_Loop:
	CLR.b	Received_replacement_key.w
	CLR.b	Replacement_key_enabled.w
	MOVE.l	#NPCTick_Malaga_DungeonKeyGiver, obj_tick_fn(A5)
	RTS

; NPCTick_Malaga_DungeonKeyGiver
; Tick: give the player the dungeon key (item $0025) on first meeting.
; If the player lost the key, offer a replacement.
; Checks inventory capacity before granting.
NPCTick_Malaga_DungeonKeyGiver:
	TST.b	Dungeon_key_received.w
	BNE.b	NPCTick_Malaga_DungeonKeyGiver_Loop
	BSR.w	CheckInventoryFull
	BGE.w	NPCTick_Malaga_DungeonKeyGiver_Default_Loop
	MOVE.l	#MalagaNorthKeyStr, obj_npc_str_ptr(A5)
	TST.b	Malaga_key_dialog_shown.w
	BEQ.w	NPCTick_SetMessage_Done
	BSR.w	AddItemToInventoryList
	MOVE.w	#$0025, (A0,D0.w)
	MOVE.b	#FLAG_TRUE, Dungeon_key_received.w
	BRA.w	NPCTick_SetMessage_Done
NPCTick_Malaga_DungeonKeyGiver_Loop:
	BSR.w	CheckInventoryFull
	BGE.w	NPCTick_Malaga_DungeonKeyGiver_Default
	LEA	Possessed_items_list.w, A3
	LEA	Possessed_items_length.w, A2
	MOVE.w	#$0025, D4
	BSR.w	CheckItemInList
	BNE.w	NPCTick_Malaga_DungeonKeyGiver_Default
	TST.b	Received_replacement_key.w	
	BNE.b	NPCTick_Malaga_DungeonKeyGiver_Default	
	MOVE.l	#LostKeyStr, obj_npc_str_ptr(A5)	
	TST.b	Replacement_key_enabled.w	
	BEQ.w	NPCTick_SetMessage_Done	
	BSR.w	AddItemToInventoryList	
	MOVE.w	#$0025, (A0,D0.w)	
	MOVE.b	#FLAG_TRUE, Received_replacement_key.w	
	BRA.b	NPCTick_SetMessage_Done	
NPCTick_Malaga_DungeonKeyGiver_Default:
	MOVE.l	#FindPoisonShieldStr, obj_npc_str_ptr(A5)
	BRA.b	NPCTick_SetMessage_Done
NPCTick_Malaga_DungeonKeyGiver_Default_Loop:
	MOVE.l	#ComeBackLessGearStr, obj_npc_str_ptr(A5)	
NPCTick_SetMessage_Done:
	BRA.w	UpdateNPCSpriteFrame
; NPCInit_Malaga_DungeonKeyGiver
; Init: sets Keltwick_MalagaHint as the NPC tick.
NPCInit_Malaga_DungeonKeyGiver:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Keltwick_MalagaHint, obj_tick_fn(A5)
	RTS

;==============================================================
; KELTWICK TOWN NPCs
; NPCs in Keltwick: Malaga hint, Blazon's cave hint, old man sketch,
; alarm clock / sleeping girl, and wait-for-player NPC.
;==============================================================

; NPCTick_Keltwick_MalagaHint
; Tick: if sent to Malaga, hint Malaga is northeast (trigger $3D).
NPCTick_Keltwick_MalagaHint:
	TST.b	Sent_to_malaga.w
	BEQ.b	NPCTick_Keltwick_MalagaHint_Loop
	MOVE.l	#MalagaNortheastStr, Pending_hint_text.w
	MOVE.w	#$003D, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Keltwick_MalagaHint_Loop:
	BRA.w	UpdateNPCSpriteFrame
; NPCInit_Keltwick_MalagaHint
; Init: sets Keltwick_BlazonsCaveHint as the NPC tick.
NPCInit_Keltwick_MalagaHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Keltwick_BlazonsCaveHint, obj_tick_fn(A5)
	RTS

; NPCTick_Keltwick_BlazonsCaveHint
; Tick: if sent to Malaga, hint to go west to Blazon's Cave (trigger $4C).
NPCTick_Keltwick_BlazonsCaveHint:
	TST.b	Sent_to_malaga.w
	BEQ.b	NPCTick_Keltwick_BlazonsCaveHint_Loop
	MOVE.l	#GoWestBlazonsCaveStr, Pending_hint_text.w
	MOVE.w	#$004C, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Keltwick_BlazonsCaveHint_Loop:
	BRA.w	UpdateNPCSpriteFrame
; NPCInit_Keltwick_BlazonsCaveHint
; Init: if old man is waiting for letter, show WaitingForLetterStr
; and use LoadFrame tick; otherwise set OldManSketch tick.
NPCInit_Keltwick_BlazonsCaveHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Old_man_waiting_for_letter.w
	BEQ.b	NPCInit_Keltwick_BlazonsCaveHint_Loop
	MOVE.l	#WaitingForLetterStr, obj_npc_str_ptr(A5)
	BRA.b	NPCInit_Keltwick_BlazonsCaveHint_Loop2
NPCInit_Keltwick_BlazonsCaveHint_Loop:
	MOVE.l	#NPCTick_Keltwick_OldManSketch, obj_tick_fn(A5)
	RTS

NPCInit_Keltwick_BlazonsCaveHint_Loop2:
	MOVE.l	#NPCBehavior_LoadFrame, obj_tick_fn(A5)
	RTS

; NPCTick_Keltwick_OldManSketch
; Tick: manage the old man / lone-tree treasure sketch side-quest.
; Gives the old man's sketch item and tracks whether the
; treasure chest has been opened.
NPCTick_Keltwick_OldManSketch:
	TST.b	Old_man_waiting_for_letter.w
	BEQ.w	NPCTick_Keltwick_OldManSketch_Loop
	TST.b	Old_mans_sketch_given.w
	BNE.b	NPCTick_Keltwick_OldManSketch_Loop2
	BSR.w	AddItemToInventoryList
	MOVE.w	#((ITEM_TYPE_NON_DISCARDABLE<<8)|ITEM_OLD_MANS_SKETCH), (A0,D0.w)
	MOVE.b	#FLAG_TRUE, Old_mans_sketch_given.w
NPCTick_Keltwick_OldManSketch_Loop2:
	TST.b	Crimson_armor_chest_opened.w
	BEQ.b	NPCTick_Keltwick_OldManSketch_Loop3
	MOVE.l	#WaitingForLetterStr, obj_npc_str_ptr(A5)	
	BRA.w	NPCTick_LoneTreeOldMan_Display	
NPCTick_Keltwick_OldManSketch_Loop3:
	MOVE.l	#LoneTreeTreasureStr, obj_npc_str_ptr(A5)
	BRA.b	NPCTick_LoneTreeOldMan_Display
NPCTick_Keltwick_OldManSketch_Loop:
	TST.b	Old_man_has_received_sketch.w
	BEQ.b	NPCTick_LoneTreeOldMan_Display
	LEA	Possessed_items_length.w, A0
	MOVE.w	(A0), D0
	CMPI.w	#8, D0
	BLT.b	NPCTick_Keltwick_OldManSketch_Loop4
	MOVE.l	#ComeBackLessGearStr, obj_npc_str_ptr(A5)	
	BRA.b	NPCTick_LoneTreeOldMan_Display	
NPCTick_Keltwick_OldManSketch_Loop4:
	MOVE.l	#ShowSketchStr, obj_npc_str_ptr(A5)
NPCTick_LoneTreeOldMan_Display:
	BRA.w	NPCBehavior_LoadFrame

; NPCInit_Keltwick_AlarmClock
; Init for the alarm-clock prop NPC; determines whether the sleeping
; girl puzzle is active based on story-progress flags.
; Sets Keltwick_girl_sleeping flag and assigns SleepingGirl tick.
NPCInit_Keltwick_AlarmClock:
	CLR.b	Alarm_clock_rang.w
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Asti_monster_defeated.w
	BNE.b	NPCInit_Keltwick_AlarmClock_Loop
	BCLR.b	#7, (A5)	
	CLR.b	Keltwick_girl_sleeping.w	
	BRA.w	NPCInit_Keltwick_SleepingGirl_Done	
NPCInit_Keltwick_AlarmClock_Loop:
	TST.b	Sent_to_malaga.w
	BEQ.b	NPCInit_Keltwick_AlarmClock_Loop2
	CLR.b	Keltwick_girl_sleeping.w
	BRA.b	NPCInit_Keltwick_SleepingGirl_Done
NPCInit_Keltwick_AlarmClock_Loop2:
	TST.b	Stow_innocence_proven.w
	BEQ.b	NPCInit_Keltwick_AlarmClock_Loop3
	BCLR.b	#7, (A5)	
	CLR.b	Keltwick_girl_sleeping.w	
	BRA.b	NPCInit_Keltwick_SleepingGirl_Done	
NPCInit_Keltwick_AlarmClock_Loop3:
	MOVE.b	#FLAG_TRUE, Keltwick_girl_sleeping.w
NPCInit_Keltwick_SleepingGirl_Done:
	MOVE.l	#NPCTick_Keltwick_SleepingGirl, obj_tick_fn(A5)
	RTS

; NPCTick_Keltwick_SleepingGirl
; Tick: show sleeping-girl sprite if girl is asleep and alarm rang.
; Changes to a waking sprite with different dialogue if innocence proven.
NPCTick_Keltwick_SleepingGirl:
	TST.b	Keltwick_girl_sleeping.w
	BEQ.b	NPCTick_Keltwick_Done
	TST.b	Alarm_clock_rang.w
	BEQ.b	NPCTick_Keltwick_Done
	MOVE.l	#ReadyToLeaveStowStr, obj_npc_str_ptr(A5)
	TST.b	Stow_innocence_proven.w
	BNE.b	NPCTick_Keltwick_SleepingGirl_Loop
	MOVE.l	#WhatsWrongStowStr, obj_npc_str_ptr(A5)
	MOVE.l	#NPCSpriteFrames_ManB, obj_anim_ptr(A5)
NPCTick_Keltwick_SleepingGirl_Loop:
	BSR.w	UpdateNPCSpriteFrame
	RTS

NPCTick_Keltwick_Done:
	BRA.w	NPCBehavior_LoadFrame

; NPCInit_Keltwick_WaitForPlayer
; Init: randomize direction and assign WaitForPlayer tick.
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Keltwick_WaitForPlayer, obj_tick_fn(A5)
	RTS

; NPCTick_Keltwick_WaitForPlayer
; Tick: if Tsarkon is dead, show "will wait" message.
; Otherwise hint about returning safely (trigger $2E).
NPCTick_Keltwick_WaitForPlayer:
	TST.b	Tsarkon_is_dead.w
	BEQ.b	NPCTick_Keltwick_WaitForPlayer_Loop
	MOVE.l	#WillWaitForYouStr, obj_npc_str_ptr(A5)
	BRA.w	NPCTick_Barrow_HintDone
NPCTick_Keltwick_WaitForPlayer_Loop:
	TST.b	Malaga_king_crowned.w
	BNE.b	NPCTick_Barrow_HintDone
	MOVE.l	#HopeReturnSafelyStr, Pending_hint_text.w
	MOVE.w	#$002E, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Barrow_HintDone:
	BRA.w	NPCBehavior_LoadFrame

;==============================================================
; BARROW TOWN NPCs
; NPCs in Barrow: northeast hint, quest guard, Bearwulf quest,
; and Tadcaster direction hint.
;==============================================================

; NPCInit_Barrow_NortheastHint
; Init: randomize direction and assign NortheastHint tick.
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Barrow_NortheastHint, obj_tick_fn(A5)
	RTS

; NPCTick_Barrow_NortheastHint
; Tick: if map received, hint that Tadcaster is northeast (trigger $1D).
NPCTick_Barrow_NortheastHint:
	TST.b	Barrow_map_received.w
	BEQ.b	NPCTick_Barrow_NortheastHint_Loop
	MOVE.l	#BarrowNortheastStr, Pending_hint_text.w
	MOVE.w	#$001D, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Barrow_NortheastHint_Loop:
	BRA.w	UpdateNPCSpriteFrame

; NPCInit_Barrow_QuestGuard
; Init: hide the guard if map already received; assign QuestGuard tick.
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Barrow_map_received.w
	BEQ.b	NPCTick_Barrow_NortheastHint_Loop2
	BCLR.b	#7, (A5)	
NPCTick_Barrow_NortheastHint_Loop2:
	MOVE.l	#NPCTick_Barrow_QuestGuard, obj_tick_fn(A5)
	RTS

; NPCTick_Barrow_QuestGuard
; Tick: hide guard once both Barrow quests are complete.
NPCTick_Barrow_QuestGuard:
	TST.b	Barrow_quest_1_complete.w
	BEQ.b	NPCTick_Barrow_BearwulfDone
	TST.b	Barrow_quest_2_complete.w
	BEQ.b	NPCTick_Barrow_BearwulfDone
	BCLR.b	#7, (A5)
NPCTick_Barrow_BearwulfDone:
	BRA.w	UpdateNPCSpriteFrame

; NPCInit_Barrow_BearwulfQuest
; Init: randomize direction and assign BearwulfQuest tick.
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Barrow_BearwulfQuest, obj_tick_fn(A5)
	RTS

; NPCTick_Barrow_BearwulfQuest
; Tick: update Bearwulf's dialogue based on quest progress.
; Shows journey-to-Carthahena message if Tsarkon dead, else
; "return after task" if Bearwulf has come home.
NPCTick_Barrow_BearwulfQuest:
	TST.b	Tsarkon_is_dead.w
	BEQ.b	NPCTick_Barrow_BearwulfQuest_Loop
	MOVE.l	#JourneyToCartahenaStr, obj_npc_str_ptr(A5)
	BRA.w	NPCTick_Barrow_SetNextTick
NPCTick_Barrow_BearwulfQuest_Loop:
	TST.b	Bearwulf_returned_home.w
	BEQ.b	NPCTick_Barrow_SetNextTick
	MOVE.l	#ReturnAfterTaskStr, obj_npc_str_ptr(A5)	
NPCTick_Barrow_SetNextTick:
	BRA.w	NPCBehavior_LoadFrame

; NPCInit_Barrow_BearwulfQuest (secondary init)
; Init: randomize direction and assign TadcasterHint tick.
NPCInit_Barrow_BearwulfQuest:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Barrow_TadcasterHint, obj_tick_fn(A5)
	RTS

; NPCTick_Barrow_TadcasterHint
; Tick: hint to reach Tadcaster (trigger $0A).
NPCTick_Barrow_TadcasterHint:
	MOVE.l	#ReachTadcasterStr, Pending_hint_text.w
	MOVE.w	#$000A, D5
	BSR.w	SetHintTextIfTriggered
	BRA.w	UpdateNPCSpriteFrame

;==============================================================
; TADCASTER TOWN NPCs
; NPCs in Tadcaster: treasure quest, pass seller, imposter hint,
; and Helwig direction hint.
;==============================================================

; NPCInit_Barrow_TadcasterHint (leads into Tadcaster)
; Init: randomize direction and assign TadcasterTreasureQuest tick.
NPCInit_Barrow_TadcasterHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Tadcaster_TreasureQuest, obj_tick_fn(A5)
	RTS

; NPCTick_Tadcaster_TreasureQuest
; Tick: manage the cave treasure quest side-chain.
; Hints about treasure in cave (trigger $1C); if found,
; splits kims reward ($7500) and updates dialogue.
NPCTick_Tadcaster_TreasureQuest:
	TST.b	Tadcaster_treasure_quest_started.w
	BEQ.b	NPCTick_Tadcaster_TreasureQuest_Loop
	MOVE.l	#ShareTreasureStr, obj_npc_str_ptr(A5)	
	TST.b	Tadcaster_treasure_found.w	
	BEQ.b	NPCTick_Tadcaster_HintDone	
	TST.b	Tadcaster_treasure_kims_received.w	
	BNE.b	NPCTick_Tadcaster_TreasureQuest_Loop2	
	MOVE.l	#$7500, Transaction_amount.w	
	JSR	DeductPaymentAmount	
	MOVE.b	#FLAG_TRUE, Tadcaster_treasure_kims_received.w	
NPCTick_Tadcaster_TreasureQuest_Loop2:
	MOVE.l	#DontSpendAllWealthStr, obj_npc_str_ptr(A5)	
	BRA.b	NPCTick_Tadcaster_HintDone	
NPCTick_Tadcaster_TreasureQuest_Loop:
	MOVE.l	#TreasureInCaveStr, Pending_hint_text.w
	MOVE.w	#$001C, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Tadcaster_HintDone:
	BRA.w	NPCBehavior_LoadFrame

; NPCInit_Tadcaster_PassSellerSetup
; Init: only activate pass seller if Uncle Tibor visited and
; pass not yet purchased; otherwise set static idle.
NPCInit_Tadcaster_PassSellerSetup:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Pass_to_carthahena_purchased.w
	BNE.b	NPCInit_PassSeller_SetStatic
	TST.b	Uncle_tibor_visited.w
	BEQ.b	NPCInit_PassSeller_SetStatic
	MOVE.l	#NPCTick_Tadcaster_PassSeller, obj_tick_fn(A5)
	RTS

NPCInit_PassSeller_SetStatic:
	MOVE.l	#NPCBehavior_LoadFrame, obj_tick_fn(A5)
	RTS

; NPCTick_Tadcaster_PassSeller
; Tick: sell the Pass to Carthahena to the player.
; Checks gold >= PRICE, inventory not full; deducts payment and
; adds ITEM_PASS_TO_CARTHAHENA if not already given.
NPCTick_Tadcaster_PassSeller:
	TST.b	Pass_to_carthahena_purchased.w
	BEQ.b	NPCTick_Tadcaster_PassSeller_Loop
	TST.b	Pass_to_carthahena_given.w
	BNE.b	NPCTick_Tadcaster_PassSeller_Loop2
	BSR.w	AddItemToInventoryList
	MOVE.w	#((ITEM_TYPE_NON_DISCARDABLE<<8)|ITEM_PASS_TO_CARTHAHENA), (A0,D0.w)
	MOVE.l	#PRICE_PASS_TO_CARTHAHENA, Transaction_amount.w
	JSR	DeductPaymentAmount
	MOVE.b	#FLAG_TRUE, Pass_to_carthahena_given.w
NPCTick_Tadcaster_PassSeller_Loop2:
	MOVE.l	#GoAwayStr, obj_npc_str_ptr(A5)
	BRA.w	NPCTick_Paofal_PassSeller_Done
NPCTick_Tadcaster_PassSeller_Loop:
	MOVE.l	#PRICE_PASS_TO_CARTHAHENA, D0
	MOVE.l	Player_kims.w, D1
	ANDI.l	#$00FFFFFF, D1
	CMP.l	D0, D1
	BLT.b	NPCTick_Tadcaster_PassSeller_Loop3
	BSR.w	CheckInventoryFull
	BLT.b	NPCTick_Tadcaster_PassSeller_Loop4
	MOVE.l	#BuyPassToCartahenaStr3, obj_npc_str_ptr(A5)	
	BRA.b	NPCTick_Paofal_PassSeller_Done	
NPCTick_Tadcaster_PassSeller_Loop3:
	MOVE.l	#BuyPassToCartahenaStr2, obj_npc_str_ptr(A5)	
	BRA.b	NPCTick_Paofal_PassSeller_Done	
NPCTick_Tadcaster_PassSeller_Loop4:
	MOVE.l	#BuyPassToCartahenaStr, obj_npc_str_ptr(A5)
NPCTick_Paofal_PassSeller_Done:
	BRA.w	NPCBehavior_LoadFrame

; NPCInit_Tadcaster_PassSeller
; Init: randomize direction and assign ImposterHint tick.
NPCInit_Tadcaster_PassSeller:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Tadcaster_ImposterHint, obj_tick_fn(A5)
	RTS

; NPCTick_Tadcaster_ImposterHint
; Tick: if imposter not yet killed, hint about Darmon's Cave (trigger $08).
NPCTick_Tadcaster_ImposterHint:
	TST.b	Imposter_killed.w
	BNE.b	NPCTick_Tadcaster_ImposterHint_Loop
	MOVE.l	#ImposterDarmonsCaveConfirmedStr, Pending_hint_text.w
	MOVE.w	#8, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Tadcaster_ImposterHint_Loop:
	BRA.w	UpdateNPCSpriteFrame

; NPCInit_Tadcaster_ImposterHint
; Init: randomize direction and assign HelwigHint tick.
NPCInit_Tadcaster_ImposterHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Tadcaster_HelwigHint, obj_tick_fn(A5)
	RTS

; NPCTick_Tadcaster_HelwigHint
; Tick: if imposter killed, hint to reach Helwig (trigger $17).
NPCTick_Tadcaster_HelwigHint:
	TST.b	Imposter_killed.w
	BEQ.b	NPCTick_Tadcaster_HelwigHint_Loop
	MOVE.l	#ReachHelwigStr, Pending_hint_text.w
	MOVE.w	#$0017, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Tadcaster_HelwigHint_Loop:
	BRA.w	UpdateNPCSpriteFrame

; NPCInit_Tadcaster_HelwigHint
; Init: hide bully NPC after first fight won; assign WalkingAnimated tick.
NPCInit_Tadcaster_HelwigHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Bully_first_fight_won.w
	BNE.b	NPCInit_Tadcaster_HelwigHint_Loop
	TST.b	Tadcaster_bully_triggered.w
	BNE.b	NPCInit_Tadcaster_HelwigHint_Loop2
NPCInit_Tadcaster_HelwigHint_Loop:
	BCLR.b	#7, (A5)
	MOVE.l	#NPCTick_WalkingAnimated, obj_tick_fn(A5)
	RTS

NPCInit_Tadcaster_HelwigHint_Loop2:
	MOVE.l	#NPCTick_WalkingAnimated, obj_tick_fn(A5)
	RTS

;==============================================================
; HELWIG TOWN NPCs
; NPCs in Helwig: generic count-on-you hint, Swaffham hint,
; rescued villager, secret key giver, old woman quest chain.
;==============================================================

; NPCInit_Helwig_Generic
; Init: randomize direction and assign CountOnYouHint tick.
NPCInit_Helwig_Generic:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Helwig_CountOnYouHint, obj_tick_fn(A5)
	RTS

; NPCTick_Helwig_CountOnYouHint
; Tick: if men not yet rescued, hint "counting on you" (trigger $14).
NPCTick_Helwig_CountOnYouHint:
	TST.b	Helwig_men_rescued.w
	BNE.b	NPCTick_Helwig_CountOnYouHint_Loop
	MOVE.l	#CountOnYouStr, Pending_hint_text.w
	MOVE.w	#$14, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Helwig_CountOnYouHint_Loop:
	BRA.w	UpdateNPCSpriteFrame

; NPCInit_Helwig_CountOnYouHint
; Init: randomize direction and assign SwaffhamHint tick.
NPCInit_Helwig_CountOnYouHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Helwig_SwaffhamHint, obj_tick_fn(A5)
	RTS

; NPCTick_Helwig_SwaffhamHint
; Tick: hint to journey west to Swaffham (trigger $03).
NPCTick_Helwig_SwaffhamHint:
	MOVE.l	#JourneyWestToSwaffhamStr, Pending_hint_text.w
	MOVE.w	#3, D5
	BSR.w	SetHintTextIfTriggered
	BRA.w	UpdateNPCSpriteFrame

; NPCInit_Helwig_SwaffhamHint
; Init: hide NPC if men not yet rescued; assign static tick.
NPCInit_Helwig_SwaffhamHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Helwig_men_rescued.w
	BNE.b	NPCInit_Helwig_SwaffhamHint_Loop
	BCLR.b	#7, (A5)
NPCInit_Helwig_SwaffhamHint_Loop:
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS

; NPCInit_Helwig_RescuedVillager
; Init: hide villager until Helwig men are rescued; assign WalkingStatic.
NPCInit_Helwig_RescuedVillager:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Helwig_men_rescued.w
	BNE.b	NPCInit_Helwig_RescuedVillager_Loop
	BCLR.b	#7, (A5)
NPCInit_Helwig_RescuedVillager_Loop:
	MOVE.l	#NPCTick_WalkingStatic, obj_tick_fn(A5)
	RTS

; NPCInit_Helwig_KeyGiverVisibility
; Init: hide key giver until men rescued; then assign SecretKeyGiver tick.
NPCInit_Helwig_KeyGiverVisibility:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Helwig_men_rescued.w
	BNE.b	NPCInit_Helwig_KeyGiverVisibility_Loop
	BCLR.b	#7, (A5)
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS

NPCInit_Helwig_KeyGiverVisibility_Loop:
	MOVE.l	#NPCTick_Helwig_SecretKeyGiver, obj_tick_fn(A5)
	RTS

; NPCTick_Helwig_SecretKeyGiver
; Tick: give ITEM_SECRET_KEY once cave-key dialog shown and inventory not full.
; After key given, shows "remembered as hero" dialogue.
NPCTick_Helwig_SecretKeyGiver:
	TST.b	Secret_key_received.w
	BNE.b	NPCTick_Helwig_SecretKeyGiver_Loop
	BSR.w	CheckInventoryFull
	BGE.b	NPCTick_Helwig_SecretKeyGiver_Loop2
	MOVE.l	#KeyFromCaveStr, obj_npc_str_ptr(A5)
	TST.b	Cave_key_dialog_shown.w
	BEQ.b	NPCTick_Helwig_SecretKeyGiver_Done
	BSR.w	AddItemToInventoryList
	MOVE.w	#((ITEM_TYPE_DISCARDABLE<<8)|ITEM_SECRET_KEY), (A0,D0.w)
	MOVE.b	#FLAG_TRUE, Secret_key_received.w
	BRA.b	NPCTick_Helwig_SecretKeyGiver_Done
NPCTick_Helwig_SecretKeyGiver_Loop:
	MOVE.l	#RememberedAsHeroStr, obj_npc_str_ptr(A5)
	BRA.b	NPCTick_Helwig_SecretKeyGiver_Done
NPCTick_Helwig_SecretKeyGiver_Loop2:
	MOVE.l	#CantCarryMoreItemsStr, obj_npc_str_ptr(A5)
NPCTick_Helwig_SecretKeyGiver_Done:
	BRA.w	UpdateNPCSpriteFrame
; NPCInit_Helwig_SecretKeyGiver (secondary init role)
; Init: if old-woman quest started, pre-load "found someone" string;
; then assign OldWomanQuest tick.
NPCInit_Helwig_SecretKeyGiver:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Helwig_old_woman_quest_started.w
	BEQ.b	NPCInit_Helwig_SecretKeyGiver_Loop
	MOVE.l	#FoundSomeoneForMeStr, obj_npc_str_ptr(A5)
NPCInit_Helwig_SecretKeyGiver_Loop:
	MOVE.l	#NPCTick_Helwig_OldWomanQuest, obj_tick_fn(A5)
	RTS

; NPCTick_Helwig_OldWomanQuest
; Tick: drive the old woman / old man matchmaking quest.
; Gives ITEM_OLD_WOMANS_SKETCH when quest starts; rewards
; EQUIPMENT_SHIELD_DRAGON once the pair are united.
NPCTick_Helwig_OldWomanQuest:
	TST.b	Old_man_and_woman_paired.w
	BEQ.b	NPCTick_Helwig_OldWomanQuest_Loop
	MOVE.l	#GetAlongFineStr, obj_npc_str_ptr(A5)
	TST.b	Dragon_shield_received.w
	BNE.w	NPCTick_Helwig_OldWomanQuest_Done
	LEA	Possessed_equipment_length.w, A0
	MOVE.w	(A0), D0
	ADDQ.w	#1, (A0)+
	ADD.w	D0, D0
	MOVE.w	#((EQUIPMENT_TYPE_SHIELD<<8)|EQUIPMENT_SHIELD_DRAGON), (A0,D0.w)
	MOVE.b	#FLAG_TRUE, Dragon_shield_received.w
	BRA.w	NPCTick_Helwig_OldWomanQuest_Done
NPCTick_Helwig_OldWomanQuest_Loop:
	TST.b	Old_woman_has_received_sketch.w
	BEQ.w	NPCTick_Helwig_OldWomanQuest_Loop2
	MOVE.l	#WriteLetterGiftDragonShieldStr, obj_npc_str_ptr(A5)
	TST.b	Dragon_shield_offered_to_player.w
	BEQ.b	NPCTick_Helwig_OldWomanQuest_Loop3
	MOVE.l	#GiftDragonShieldStr, obj_npc_str_ptr(A5)
NPCTick_Helwig_OldWomanQuest_Loop3:
	LEA	Possessed_equipment_length.w, A0
	MOVE.w	(A0), D0
	CMPI.w	#8, D0
	BLT.w	NPCTick_Helwig_OldWomanQuest_Done
	MOVE.l	#FriendGiftDragonShieldStr, obj_npc_str_ptr(A5)
	MOVE.b	#FLAG_TRUE, Dragon_shield_offered_to_player.w
	BRA.w	NPCTick_Helwig_OldWomanQuest_Done
NPCTick_Helwig_OldWomanQuest_Loop2:
	TST.b	Helwig_old_woman_quest_started.w
	BEQ.b	NPCTick_Helwig_OldWomanQuest_Loop4
	TST.b	Player_has_received_old_womans_sketch.w
	BNE.w	NPCTick_Helwig_OldWomanQuest_Loop5
	BSR.w	AddItemToInventoryList
	MOVE.w	#((ITEM_TYPE_NON_DISCARDABLE<<8)|ITEM_OLD_WOMANS_SKETCH), (A0,D0.w)
	MOVE.b	#FLAG_TRUE, Player_has_received_old_womans_sketch.w
	BRA.w	NPCTick_Helwig_OldWomanQuest_Done
NPCTick_Helwig_OldWomanQuest_Loop4:
	TST.b	Helwig_men_rescued.w
	BEQ.b	NPCTick_Helwig_OldWomanQuest_Done
	BSR.w	CheckInventoryFull
	BLT.b	NPCTick_Helwig_OldWomanQuest_Loop6
	MOVE.l	#ComeBackLessGearStr2, obj_npc_str_ptr(A5)
	BRA.b	NPCTick_Helwig_OldWomanQuest_Done
NPCTick_Helwig_OldWomanQuest_Loop6:
	MOVE.l	#FindSomeoneForMeStr, obj_npc_str_ptr(A5)
	BRA.b	NPCTick_Helwig_OldWomanQuest_Done
NPCTick_Helwig_OldWomanQuest_Loop5:
	MOVE.l	#FoundSomeoneForMeStr, obj_npc_str_ptr(A5)
NPCTick_Helwig_OldWomanQuest_Done:
	BRA.w	NPCBehavior_LoadFrame

; NPCInit_Helwig_OldWomanQuest (bridges into Swaffham section)
; Init: set 2x3 soldier sprite size and assign KnuteNoAnswer tick.
NPCInit_Helwig_OldWomanQuest:
	MOVE.b	#SPRITE_SIZE_2x3, obj_sprite_size(A5)
	MOVE.l	#NPCTick_Swaffham_KnuteNoAnswer, obj_tick_fn(A5)
	RTS

;==============================================================
; SWAFFHAM AND EXCALABRIA NPCs
; Knute (Swaffham), crystal exchange wizard (Excalabria),
; Swaffham ruin wait, spy dinner trap.
;==============================================================

; NPCTick_Swaffham_KnuteNoAnswer
; Tick: once Swaffham is ruined, Knute stops responding.
NPCTick_Swaffham_KnuteNoAnswer:
	TST.b	Knute_informed_of_swaffham_ruin.w
	BEQ.b	NPCTick_Swaffham_KnuteNoAnswer_Loop
	MOVE.l	#NoAnswerStr, obj_npc_str_ptr(A5)
NPCTick_Swaffham_KnuteNoAnswer_Loop:
	BRA.w	UpdateNPCScreenPosition

; NPCInit_Excalabria_CrystalExchange (setup)
; Init: randomize direction and assign CrystalExchange tick.
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Excalabria_CrystalExchange, obj_tick_fn(A5)
	RTS

; NPCTick_Excalabria_CrystalExchange
; Tick: crystal merchant in Excalabria; trades rings for colored keys.
; Checks ring progress (earth, red, blue, white) and gives corresponding
; key item once crystals are returned.
NPCTick_Excalabria_CrystalExchange:
	TST.b	Ring_of_earth_obtained.w
	BEQ.w	NPCTick_Excalabria_CrystalExchange_Loop
	LEA	Possessed_items_list.w, A3
	LEA	Possessed_items_length.w, A2
	MOVE.w	#$0110, D4
	BSR.w	RemoveItemFromList
	LEA	Possessed_items_list.w, A3
	LEA	Possessed_items_length.w, A2
	MOVE.w	#$0113, D4
	BSR.w	RemoveItemFromList
	MOVE.l	#BegoneNothingMoreStr, obj_npc_str_ptr(A5)
	BRA.w	NPCTick_Excalabria_CrystalExchange_Done
NPCTick_Excalabria_CrystalExchange_Loop:
	TST.b	Blue_crystal_received.w
	BEQ.b	NPCTick_Excalabria_CrystalExchange_Loop2
	BRA.w	NPCTick_Excalabria_CrystalExchange_Done
NPCTick_Excalabria_CrystalExchange_Loop2:
	TST.b	Blue_crystal_quest_started.w
	BEQ.w	NPCTick_Excalabria_CrystalExchange_Loop3
	TST.b	Blue_key_received.w
	BNE.w	NPCTick_Excalabria_CrystalExchange_Loop4
	LEA	Possessed_items_list.w, A3
	LEA	Possessed_items_length.w, A2
	MOVE.w	#$010F, D4
	BSR.w	RemoveItemFromList
	LEA	Possessed_items_list.w, A3
	LEA	Possessed_items_length.w, A2
	MOVE.w	#$0112, D4
	BSR.w	RemoveItemFromList
	BSR.w	AddItemToInventoryList
	MOVE.w	#((ITEM_TYPE_NON_DISCARDABLE<<8)|ITEM_BLUE_KEY), (A0,D0.w)
	MOVE.b	#FLAG_TRUE, Blue_key_received.w
NPCTick_Excalabria_CrystalExchange_Loop4:
	MOVE.l	#BackSoSoonStr, obj_npc_str_ptr(A5)
	BRA.w	NPCTick_Excalabria_CrystalExchange_Done
NPCTick_Excalabria_CrystalExchange_Loop3:
	TST.b	Red_crystal_received.w
	BEQ.w	NPCTick_Excalabria_CrystalExchange_Loop5
	BRA.w	NPCTick_Excalabria_CrystalExchange_Done
NPCTick_Excalabria_CrystalExchange_Loop5:
	TST.b	Red_crystal_quest_started.w
	BEQ.w	NPCTick_Excalabria_CrystalExchange_Loop6
	TST.b	Red_key_received.w
	BNE.w	NPCTick_Excalabria_CrystalExchange_Loop7
	LEA	Possessed_items_list.w, A3
	LEA	Possessed_items_length.w, A2
	MOVE.w	#$010E, D4
	BSR.w	RemoveItemFromList
	LEA	Possessed_items_list.w, A3
	LEA	Possessed_items_length.w, A2
	MOVE.w	#$0111, D4
	BSR.w	RemoveItemFromList
	BSR.w	AddItemToInventoryList
	MOVE.w	#((ITEM_TYPE_NON_DISCARDABLE<<8)|ITEM_RED_KEY), (A0,D0.w)
	MOVE.b	#FLAG_TRUE, Red_key_received.w
NPCTick_Excalabria_CrystalExchange_Loop7:
	MOVE.l	#BackSoSoonStr, obj_npc_str_ptr(A5)
	BRA.w	NPCTick_Excalabria_CrystalExchange_Done
NPCTick_Excalabria_CrystalExchange_Loop6:
	TST.b	Ring_of_wind_received.w
	BEQ.b	NPCTick_Excalabria_CrystalExchange_Loop8
	BRA.w	NPCTick_Excalabria_CrystalExchange_Done
NPCTick_Excalabria_CrystalExchange_Loop8:
	TST.b	White_crystal_quest_started.w
	BEQ.b	NPCTick_Excalabria_CrystalExchange_Loop9
	TST.b	White_crystal_received.w
	BNE.b	NPCTick_Excalabria_CrystalExchange_Loop10
	BSR.w	AddItemToInventoryList
	MOVE.w	#((ITEM_TYPE_NON_DISCARDABLE<<8)|ITEM_WHITE_KEY), (A0,D0.w)
	MOVE.b	#FLAG_TRUE, White_crystal_received.w
NPCTick_Excalabria_CrystalExchange_Loop10:
	MOVE.l	#BackSoSoonStr, obj_npc_str_ptr(A5)
	BRA.w	NPCTick_Excalabria_CrystalExchange_Done
NPCTick_Excalabria_CrystalExchange_Loop9:
	BSR.w	CheckInventoryFull
	BLT.b	NPCTick_Excalabria_CrystalExchange_Loop11
	MOVE.l	#CantGiveKeyStr, obj_npc_str_ptr(A5)	
	BRA.b	NPCTick_Excalabria_CrystalExchange_Done	
NPCTick_Excalabria_CrystalExchange_Loop11:
	MOVE.l	#RingOfEarthQuestStr, obj_npc_str_ptr(A5)
NPCTick_Excalabria_CrystalExchange_Done:
	BRA.w	NPCBehavior_LoadFrame

; NPCInit_Excalabria_CrystalExchange
; Init: if all 4 rings not collected, set static tick.
; If Ring of Earth obtained but Swaffham not yet informed,
; assign SwaffhamRuinWait tick instead.
NPCInit_Excalabria_CrystalExchange:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.w	#4, D7
	BSR.w	CheckRingsCollected
	BEQ.b	NPCInit_Excalabria_CrystalExchange_Loop
	MOVE.l	#GetAllRingsStr, obj_npc_str_ptr(A5)	
	BRA.b	NPCInit_Excalabria_CrystalExchange_Done	
NPCInit_Excalabria_CrystalExchange_Loop:
	TST.b	Knute_informed_of_swaffham_ruin.w
	BNE.b	NPCInit_Excalabria_CrystalExchange_Done
	TST.b	Ring_of_earth_obtained.w
	BEQ.b	NPCInit_Excalabria_CrystalExchange_Done
	MOVE.l	#NPCTick_Excalabria_SwaffhamRuinWait, obj_tick_fn(A5)
	RTS

NPCInit_Excalabria_CrystalExchange_Done:
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS

; NPCTick_Excalabria_SwaffhamRuinWait
; Tick: if Swaffham is ruined, clear Carthahena fight trigger and
; show "waiting in Excalabria" string; else idle.
NPCTick_Excalabria_SwaffhamRuinWait:
	TST.b	Swaffham_ruined.w
	BEQ.b	NPCTick_Excalabria_SwaffhamRuinWait_Loop
	CLR.b	Carthahena_soldier_1_defeated.w
	MOVE.l	#WaitingExcalabriaStr, obj_npc_str_ptr(A5)
NPCTick_Excalabria_SwaffhamRuinWait_Loop:
	BRA.w	NPCBehavior_LoadFrame

; NPCInit_Swaffham_SpyDinnerTrap
; Init: if poisoned food already eaten, hide NPC; else assign SpyDinnerTrap tick.
NPCInit_Swaffham_SpyDinnerTrap:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Swaffham_ate_poisoned_food.w
	BNE.b	NPCInit_Swaffham_SpyDinnerTrap_Loop
	MOVE.l	#NPCTick_Swaffham_SpyDinnerTrap, obj_tick_fn(A5)
	RTS

NPCInit_Swaffham_SpyDinnerTrap_Loop:
	BCLR.b	#7, (A5)
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS

; NPCTick_Swaffham_SpyDinnerTrap
; Tick: manage the spy-dinner poison trap event.
; Once player eats poisoned food, triggers sleep sound, gameplay
; state reset to building entry, and full HP/MP restore.
NPCTick_Swaffham_SpyDinnerTrap:
	TST.b	Swaffham_ate_poisoned_food.w
	BEQ.b	NPCTick_Swaffham_SpyDinnerTrap_Loop
	BCLR.b	#7, (A5)
	BRA.w	NPCTick_Swaffham_SpyDinnerTrap_Done_Loop
NPCTick_Swaffham_SpyDinnerTrap_Loop:
	TST.b	Spy_dinner_poisoned_flag.w
	BEQ.b	NPCTick_Swaffham_SpyDinnerTrap_Loop2
	MOVE.l	#PoisonedFoodStr, obj_npc_str_ptr(A5)
	BRA.w	NPCTick_Swaffham_SpyDinnerTrap_Done
NPCTick_Swaffham_SpyDinnerTrap_Loop2:
	TST.b	Ate_spy_dinner.w
	BEQ.w	NPCTick_Swaffham_SpyDinnerTrap_Done
	MOVE.l	#WasItGoodStr, obj_npc_str_ptr(A5)
	TST.b	Poison_trap_sprung.w
	BNE.b	NPCTick_Swaffham_SpyDinnerTrap_Done
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), Saved_player_x_in_town.w
	MOVE.w	obj_world_y(A6), Town_player_spawn_y.w
	MOVE.w	Town_camera_tile_x.w, Town_saved_camera_x.w
	MOVE.w	Town_camera_tile_y.w, Saved_camera_tile_y_room1.w
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	MOVE.b	#SOUND_SLEEP, D0
	JSR	QueueSoundEffect
	MOVE.w	#GAMEPLAY_STATE_INIT_BUILDING_ENTRY, Gameplay_state.w
	MOVE.w	#POISONED_DURATION, Player_poisoned.w
	MOVE.b	#FLAG_TRUE, Poison_notified.w
	MOVE.w	Player_mhp.w, Player_hp.w
	MOVE.w	Player_mmp.w, Player_mp.w
	MOVE.b	#FLAG_TRUE, Poison_trap_sprung.w
NPCTick_Swaffham_SpyDinnerTrap_Done:
	BSR.w	UpdateNPCSpriteFrame
NPCTick_Swaffham_SpyDinnerTrap_Done_Loop:
	RTS

;==============================================================
; HASTINGS AND CARTHAHENA NPCs
; NPCs in Hastings: hide-after-Tsarkon NPC, welcome prince,
; gate guard. Carthahena: boss guard, King Thule key giver.
;==============================================================

; NPCInit_Hastings_HideAfterTsarkon
; Init: if Tsarkon dead, hide NPC immediately; else assign static tick.
NPCInit_Hastings_HideAfterTsarkon:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Tsarkon_is_dead.w
	BEQ.b	NPCInit_Hastings_HideAfterTsarkon_Loop
	BCLR.b	#7, (A5)	
	RTS
	
NPCInit_Hastings_HideAfterTsarkon_Loop:
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS

; NPCInit_Hastings_WelcomePrince
; Init: select welcome/waiting dialogue based on sword and story state.
NPCInit_Hastings_WelcomePrince:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#SeveralPeopleWaitingStr, obj_npc_str_ptr(A5)
	TST.b	Player_has_received_sword_of_vermilion.w
	BNE.b	NPCTick_Hastings_SetStaticBehavior
	MOVE.l	#WelcomePrinceStr, obj_npc_str_ptr(A5)
	TST.b	Sword_stolen_by_blacksmith.w
	BNE.b	NPCTick_Hastings_SetStaticBehavior
	MOVE.l	#SeveralPeopleWaitingStr, obj_npc_str_ptr(A5)	
NPCTick_Hastings_SetStaticBehavior:
	MOVE.l	#NPCBehavior_LoadFrame, obj_tick_fn(A5)
	RTS

; NPCInit_Hastings_GateGuard
; Init: if Tsarkon dead, hide guard; if pass purchased, move guard
; aside ($00F8); then set static LoadFrame tick.
NPCInit_Hastings_GateGuard:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Tsarkon_is_dead.w
	BEQ.b	NPCInit_Hastings_GateGuard_Loop
	BCLR.b	#7, (A5)	
	BRA.b	NPCInit_Hastings_SetBehavior	
NPCInit_Hastings_GateGuard_Loop:
	TST.b	Pass_to_carthahena_purchased.w
	BEQ.b	NPCInit_Hastings_SetBehavior
	MOVE.w	#$00F8, obj_world_x(A5)
NPCInit_Hastings_SetBehavior:
	MOVE.l	#NPCBehavior_LoadFrame, obj_tick_fn(A5)
	RTS

; NPCInit_Carthahena_BossGuard
; Init: if boss defeated, hide guard and set static; else BossGuard tick.
NPCInit_Carthahena_BossGuard:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Carthahena_boss_defeated.w
	BEQ.b	NPCInit_Carthahena_BossGuard_Loop
	BCLR.b	#7, (A5)	
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)	
	RTS
	
NPCInit_Carthahena_BossGuard_Loop:
	MOVE.l	#NPCTick_Carthahena_BossGuard, obj_tick_fn(A5)
	RTS

; NPCTick_Carthahena_BossGuard
; Tick: hide guard once boss defeated; else show "bested me" post-fight.
NPCTick_Carthahena_BossGuard:
	TST.b	Carthahena_boss_defeated.w
	BEQ.b	NPCTick_Carthahena_BossGuard_Loop
	BCLR.b	#7, (A5)
	BRA.b	NPCTick_CarthahenaFinalBoss_Done
NPCTick_Carthahena_BossGuard_Loop:
	TST.b	Carthahena_boss_met.w
	BEQ.b	NPCTick_CarthahenaFinalBoss_Done
	MOVE.l	#BestedMeStr, obj_npc_str_ptr(A5)
NPCTick_CarthahenaFinalBoss_Done:
	BRA.w	UpdateNPCSpriteFrame
NPCTick_CarthahenaFinalBoss_DeadCode:					; unreferenced dead code
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Tsarkon_is_dead.w
	BNE.b	NPCTick_CarthahenaFinalBoss_Done_Loop
	BCLR	#7, (A5)
NPCTick_CarthahenaFinalBoss_Done_Loop:
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS
NPCTick_CarthahenaFinalBoss_AltEntry_DeadCode:					; unreferenced dead code
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Tsarkon_is_dead.w
	BNE.b	NPCTick_CarthahenaFinalBoss_Done_Loop2
	BCLR	#7, (A5)
NPCTick_CarthahenaFinalBoss_Done_Loop2:
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS

; NPCInit_Carthahena_KingThuleKey
; Init: if Tsarkon dead, set static; else assign KingThuleKey tick.
NPCInit_Carthahena_KingThuleKey:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Tsarkon_is_dead.w
	BNE.b	NPCInit_Carthahena_KingThuleKey_Loop
	MOVE.l	#NPCTick_Carthahena_KingThuleKey, obj_tick_fn(A5)
	RTS

NPCInit_Carthahena_KingThuleKey_Loop:
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS

; NPCTick_Carthahena_KingThuleKey
; Tick: Knute the king distributes ITEM_THULE_KEY once Carthahena
; boss defeated and all 4 rings collected; manages "must have all
; rings" and "come back less gear" edge cases.
NPCTick_Carthahena_KingThuleKey:
	TST.b	Carthahena_boss_defeated.w
	BEQ.w	NPCTick_SetMessage2_Done
	TST.b	Knute_informed_of_swaffham_ruin.w
	BEQ.w	NPCTick_Helwig_SetRingsMessage
	MOVE.w	#4, D7
	BSR.w	CheckRingsCollected
	BNE.w	NPCTick_Helwig_SetRingsMessage
	MOVE.l	#TsarkonFledEastwardStr, obj_npc_str_ptr(A5)
	TST.b	Thule_key_received.w
	BNE.w	NPCTick_SetMessage2_Done
	BSR.w	CheckInventoryFull
	BGE.b	NPCTick_Carthahena_KingThuleKey_Loop
	MOVE.l	#TsarkonFledEastStr, obj_npc_str_ptr(A5)
	TST.b	Knute_thule_key_dialog_shown.w
	BEQ.b	NPCTick_SetMessage2_Done
	BSR.w	AddItemToInventoryList
	MOVE.w	#((ITEM_TYPE_NON_DISCARDABLE<<8)|ITEM_THULE_KEY), (A0,D0.w)
	MOVE.b	#FLAG_TRUE, Thule_key_received.w
	BRA.b	NPCTick_SetMessage2_Done
NPCTick_Carthahena_KingThuleKey_Loop:
	MOVE.l	#ComeBackLessGearStr3, obj_npc_str_ptr(A5)
	BRA.b	NPCTick_SetMessage2_Done
NPCTick_Helwig_SetRingsMessage:
	MOVE.l	#MustHaveAllRingsStr, obj_npc_str_ptr(A5)	
NPCTick_SetMessage2_Done:
	BRA.w	UpdateNPCSpriteFrame

;==============================================================
; HELWIG INN AND PARMA CASTLE NPCs
; Inn frying-pan innkeeper in Helwig; castle patrol soldiers
; and rotation logic in Parma.
;==============================================================

; NPCInit_Helwig_InnFryingPan
; Init: randomize direction and assign InnFryingPan tick.
NPCInit_Helwig_InnFryingPan:
	BSR.w	SetRandomDirection
	MOVE.l	#NPCTick_Helwig_InnFryingPan, obj_tick_fn(A5)
	RTS

; NPCTick_Helwig_InnFryingPan
; Tick: innkeeper changes dialogue based on how many times the
; frying pan has been struck (Helwig_frypan_hit_count).
; Different strings at hit counts 0, 4, and >= 10.
NPCTick_Helwig_InnFryingPan:
	TST.b	Helwig_men_rescued.w
	BNE.b	NPCTick_Helwig_InnFryingPan_Display
	MOVE.w	Helwig_frypan_hit_count.w, D0
	BEQ.b	NPCTick_Helwig_InnFryingPan_Display
	CMPI.w	#$000A, D0
	BGE.b	NPCTick_Helwig_InnFryingPan_Loop
	CMPI.w	#4, D0
	BEQ.b	NPCTick_Helwig_InnFryingPan_Loop2
	MOVE.l	#SleepInSoftBedStr, obj_npc_str_ptr(A5)
	BRA.b	NPCTick_Helwig_InnFryingPan_Display
NPCTick_Helwig_InnFryingPan_Loop2:
	MOVE.l	#SleepInSoftBedStr, obj_npc_str_ptr(A5)	
	BRA.b	NPCTick_Helwig_InnFryingPan_Display	
NPCTick_Helwig_InnFryingPan_Loop:
	MOVE.l	#SleepInSoftBedStr2, obj_npc_str_ptr(A5)	
NPCTick_Helwig_InnFryingPan_Display:
	MOVEA.l	obj_anim_ptr(A5), A1
	MOVE.b	#FLAG_TRUE, obj_behavior_flag(A5)
	BSR.w	LoadNPCAnimFrame_Static
	MOVE.b	obj_npc_saved_dir(A5), obj_direction(A5)
	ADDQ.b	#1, obj_move_counter(A5)
	RTS

; NPCInit_Parma_CastleSoldier
; Init: face down and assign static castle-soldier tick.
NPCInit_Parma_CastleSoldier:
	MOVE.b	#DIRECTION_DOWN, obj_direction(A5)
	MOVE.b	#4, obj_npc_saved_dir(A5)
	MOVE.l	#NPCTick_Parma_CastleSoldierStatic, obj_tick_fn(A5)
	RTS

NPCTick_Parma_CastleSoldierStatic:
	BRA.w	NPCBehavior_LoadFrame

; NPCInit_Parma_CastleSoldierFaceDown
; Init: facing-down variant; sets patrol target direction to $06 (left).
NPCInit_Parma_CastleSoldierFaceDown:
	MOVE.b	#2, obj_hp(A5)
	MOVE.b	#6, soldier_patrol_state(A5)
	BRA.w	NPCInit_Parma_CastleSoldierFaceRight_Loop
; NPCInit_Parma_CastleSoldierFaceRight
; Init: facing-right variant; patrol target direction $02 (right).
; Stores home tile coords from world position and starts patrol tick.
NPCInit_Parma_CastleSoldierFaceRight:
	MOVE.b	#6, obj_hp(A5)
	MOVE.b	#2, soldier_patrol_state(A5)
NPCInit_Parma_CastleSoldierFaceRight_Loop:
	CLR.b	obj_npc_busy_flag(A5)
	MOVE.w	obj_world_x(A5), D0
	ASR.w	#4, D0
	MOVE.b	D0, obj_xp_reward(A5)
	MOVE.w	obj_world_y(A5), D0
	ASR.w	#4, D0
	MOVE.b	D0, soldier_home_tile_y(A5)
	MOVE.b	#4, obj_npc_saved_dir(A5)
	MOVE.b	#DIRECTION_DOWN, obj_direction(A5)
	MOVE.l	#NPCTick_Parma_CastleSoldierPatrol, obj_tick_fn(A5)
	RTS

; NPCTick_Parma_CastleSoldierPatrol
; Tick: patrol the Parma castle room; if fake king killed while in
; castle-room-1, switch to static tick. Otherwise rotate patrol.
NPCTick_Parma_CastleSoldierPatrol:
	MOVE.w	Gameplay_state.w, D0
	CMPI.w	#GAMEPLAY_STATE_CASTLE_ROOM1_ACTIVE, D0
	BNE.b	NPCTick_ParmaSoldier_Rotate
	TST.b	Fake_king_killed.w
	BEQ.b	NPCTick_ParmaSoldier_Rotate
	MOVE.l	#NPCTick_Parma_CastleSoldierStatic, obj_tick_fn(A5)
	RTS

NPCTick_ParmaSoldier_Rotate:
	BSR.w	UpdateParmaSoldierRotation
	BSR.w	GetNPCAnimationOffset
	MOVEA.l	obj_anim_ptr(A5), A1
	MOVE.w	(A1,D0.w), obj_tile_index(A5)
	BRA.w	UpdateNPCScreenPosition
; UpdateParmaSoldierRotation
; Handle patrol rotation for a Parma castle soldier.
; Checks player bounding box; oscillates soldier's x position
; by ±$8000 each frame for NPC_ROTATION_FRAMES, then resets.
UpdateParmaSoldierRotation:
	CLR.b	obj_behavior_flag(A5)
	TST.b	obj_npc_busy_flag(A5)
	BNE.w	UpdateParmaSoldierRotation_Loop
	MOVE.b	obj_npc_saved_dir(A5), obj_direction(A5)
	BSR.w	CheckPlayerInBoundingBox
	BEQ.b	UpdateParmaSoldierRotation_Loop2
	TST.b	obj_max_hp(A5)
	BNE.w	ParmaSoldierRotation_Return
	MOVE.b	#FLAG_TRUE, obj_npc_busy_flag(A5)
	MOVE.b	obj_hp(A5), obj_direction(A5)
	BNE.w	ParmaSoldierRotation_Return
UpdateParmaSoldierRotation_Loop2:
	TST.b	obj_max_hp(A5)
	BEQ.w	ParmaSoldierRotation_Return
	MOVE.b	#FLAG_TRUE, obj_npc_busy_flag(A5)
	MOVE.b	$29(A5), obj_direction(A5)
	BNE.w	ParmaSoldierRotation_Return
UpdateParmaSoldierRotation_Loop:
	CMPI.b	#2, obj_direction(A5)
	BLE.b	UpdateParmaSoldierRotation_Loop3
	ADDI.l	#$8000, obj_world_x(A5)
	BRA.b	UpdateParmaSoldierRotation_Loop4
UpdateParmaSoldierRotation_Loop3:
	SUBI.l	#$8000, obj_world_x(A5)
UpdateParmaSoldierRotation_Loop4:
	MOVE.b	#FLAG_TRUE, obj_behavior_flag(A5)
	ADDQ.b	#1, obj_hit_flag(A5)
	ADDQ.b	#1, obj_move_counter(A5)
	CMPI.b	#NPC_ROTATION_FRAMES, obj_hit_flag(A5)
	BLT.b	ParmaSoldierRotation_Return
	CLR.b	obj_max_hp(A5)
	MOVE.b	obj_direction(A5), D0
	CMP.b	obj_hp(A5), D0
	BNE.b	UpdateParmaSoldierRotation_Loop5
	MOVE.b	#$FF, obj_max_hp(A5)
UpdateParmaSoldierRotation_Loop5:
	CLR.b	obj_hit_flag(A5)
	CLR.b	obj_move_counter(A5)
	CLR.b	obj_npc_busy_flag(A5)
	MOVE.b	#DIRECTION_DOWN, obj_direction(A5)
	MOVE.b	#4, obj_npc_saved_dir(A5)
ParmaSoldierRotation_Return:
	RTS

;==============================================================
; NPC MOVEMENT AND ANIMATION UTILITIES
; Bounding box check, animation offset calculations, screen
; position update, tile collision, frame loaders, random
; direction, wander movement loop.
;==============================================================

; CheckPlayerInBoundingBox
; Check whether the player tile-position falls within the
; patrol bounding box of the current Parma soldier (A5).
; Outputs: D0 = 1 if inside box, 0 if outside.
;CheckPlayerInBoundingBox:
CheckPlayerInBoundingBox: ; Check whether player is in the bounding box for Parma soldiers
	CLR.w	D0
	MOVE.b	obj_xp_reward(A5), D0
	MOVE.w	D0, D1
	CLR.w	D2
	MOVE.b	soldier_home_tile_y(A5), D2
	MOVE.w	D2, D3
	LEA	ParmaSoldierBoundingBoxTable, A0
	CLR.w	D4
	MOVE.b	obj_hp(A5), D4
	ASR.w	#1, D4
	ASL.w	#3, D4
	LEA	(A0,D4.w), A0
	ADD.w	(A0)+, D0
	ADD.w	(A0)+, D1
	ADD.w	(A0)+, D2
	ADD.w	(A0), D3
	CMP.w	Player_position_x_in_town.w, D0
	BGT.b	ParmaSoldierCollision_NoHit
	CMP.w	Player_position_x_in_town.w, D1
	BLT.b	ParmaSoldierCollision_NoHit
	CMP.w	Player_position_y_in_town.w, D2
	BGT.b	ParmaSoldierCollision_NoHit
	CMP.w	Player_position_y_in_town.w, D3
	BLT.b	ParmaSoldierCollision_NoHit
	MOVEQ	#1, D0
	RTS

ParmaSoldierCollision_NoHit:
	CLR.w	D0
	RTS

; GetStaticNPCAnimationOffset
; Compute word offset into a static NPC animation table.
; Handles horizontal flip (direction > 4 sets sprite flag bit 3).
; Inputs: A5 = NPC object (obj_direction, obj_move_counter used)
; Outputs: D0 = word offset into animation table
GetStaticNPCAnimationOffset:
	BCLR.b	#3, obj_sprite_flags(A5)
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	CMPI.b	#4, D1
	BLE.b	GetStaticNPCAnimationOffset_Loop
	BSET.b	#3, obj_sprite_flags(A5)
GetStaticNPCAnimationOffset_Loop:
	ASR.w	#1, D1
	ADD.w	D1, D1
	ADD.w	D1, D1
	TST.b	obj_behavior_flag(A5)
	BNE.b	GetStaticNPCAnimationOffset_Loop2
	MOVE.w	D1, D0
	BRA.w	GetStaticNPCAnimationOffset_Return
GetStaticNPCAnimationOffset_Loop2:
	MOVE.b	obj_move_counter(A5), D0
	BTST.b	#6, $00A10001
	BNE.w	GetStaticNPCAnimationOffset_Loop3
	ASR.w	#4, D0
	ANDI.w	#3, D0
	BRA.b	GetStaticNPCAnimationOffset_Loop4
GetStaticNPCAnimationOffset_Loop3:
	ASR.w	#3, D0	
	ANDI.w	#3, D0	
GetStaticNPCAnimationOffset_Loop4:
	ADD.w	D1, D0
	TST.b	obj_direction(A5)
	BEQ.b	GetStaticNPCAnimOffset_FlipCheck
	CMPI.b	#4, obj_direction(A5)
	BEQ.b	GetStaticNPCAnimOffset_FlipCheck
	BRA.b	GetStaticNPCAnimationOffset_Return
GetStaticNPCAnimOffset_FlipCheck:
	BTST.l	#0, D0
	BNE.b	GetStaticNPCAnimationOffset_Return
	BSET.b	#3, obj_sprite_flags(A5)
GetStaticNPCAnimationOffset_Return:
	ADD.w	D0, D0
	RTS

; GetNPCAnimationOffset
; Like GetStaticNPCAnimationOffset but for walking/animated NPCs.
; Inputs: A5 = NPC object
; Outputs: D0 = word offset into animation table
GetNPCAnimationOffset:
	BCLR.b	#3, obj_sprite_flags(A5)
	CLR.w	D1
	MOVE.b	obj_direction(A5), D1
	CMPI.b	#4, D1
	BLE.b	GetNPCAnimationOffset_Loop
	BSET.b	#3, obj_sprite_flags(A5)
GetNPCAnimationOffset_Loop:
	ASR.w	#1, D1
	ADD.w	D1, D1
	ADD.w	D1, D1
	TST.b	obj_behavior_flag(A5)
	BNE.b	GetNPCAnimationOffset_Loop2
	MOVE.w	D1, D0
	BRA.b	GetNPCAnimationOffset_Loop3
GetNPCAnimationOffset_Loop2:
	MOVE.b	obj_move_counter(A5), D0
	BTST.b	#6, $00A10001
	BNE.w	GetNPCAnimationOffset_Loop4
	ASR.w	#4, D0
	ANDI.w	#3, D0
	BRA.b	GetNPCAnimationOffset_Loop5
GetNPCAnimationOffset_Loop4:
	ASR.w	#3, D0	
	ANDI.w	#3, D0	
GetNPCAnimationOffset_Loop5:
	ADD.w	D1, D0
GetNPCAnimationOffset_Loop3:
	ADD.w	D0, D0
	RTS

; UpdateNPCScreenPosition
; Convert NPC world position to screen position relative to camera.
; Adjusts X by 1 pixel when sprite-flip bit and direction alignment
; require it, then calls AddSpriteToDisplayList.
UpdateNPCScreenPosition:
	MOVE.w	obj_world_x(A5), D0
	SUB.w	Camera_scroll_x.w, D0
	MOVE.w	D0, obj_screen_x(A5)
	TST.b	obj_direction(A5)
	BEQ.b	NPCScreenPosition_FlipCheck
	CMPI.b	#4, obj_direction(A5)
	BEQ.b	NPCScreenPosition_FlipCheck
	BRA.b	NPCScreenPosition_UpdateY
NPCScreenPosition_FlipCheck:
	BTST.b	#3, obj_sprite_flags(A5)
	BEQ.b	NPCScreenPosition_UpdateY
	SUBQ.w	#1, obj_screen_x(A5)
NPCScreenPosition_UpdateY:
	MOVE.w	obj_world_y(A5), D0
	SUB.w	Camera_scroll_y.w, D0
	ADDI.w	#0, D0
	MOVE.w	D0, obj_screen_y(A5)
	MOVE.w	obj_screen_y(A5), obj_sort_key(A5)
	JSR	AddSpriteToDisplayList
	RTS

; CheckTileCollision
; Check if the tile in direction D2 (from NPCMoveDeltaTable) at
; the NPC's world position is solid (high nibble of tile word != 0).
; Inputs: A5 = NPC object, D2 = direction index (raw)
; Outputs: D0 = $FFFF if solid (no-match), 0 if passable
CheckTileCollision:
	LSR.w	#1, D2
	ANDI.w	#3, D2
	ADD.w	D2, D2
	ADD.w	D2, D2
	LEA	BattleMoveOffsets, A1
	LEA	Tilemap_buffer_plane_b, A0
	MOVE.w	obj_world_x(A5), D0
	ASR.w	#3, D0
	CMPI.w	#1, D0
	BLE.w	CheckTileCollision_NoMatch
	MOVE.w	obj_world_y(A5), D1
	ASR.w	#3, D1
	BLE.b	CheckTileCollision_NoMatch
	ASL.w	#7, D1
	ASL.w	#1, D0
	ADD.w	(A1,D2.w), D0
	ADD.w	$2(A1,D2.w), D1
	ANDI.w	#$007F, D0
	ADD.w	D1, D0
	ANDI.w	#$1FFF, D0
	MOVE.w	(A0,D0.w), D0
	ANDI.w	#$F000, D0
	BEQ.b	CheckTileCollision_NoMatch_Loop
CheckTileCollision_NoMatch:
	MOVE.w	#$FFFF, D0
	RTS

CheckTileCollision_NoMatch_Loop:
	CLR.w	D0
	RTS

; LoadNPCAnimFrame_Static
; Load tile index from static animation table and update screen position.
; Inputs: A1 = animation table pointer, A5 = NPC object
LoadNPCAnimFrame_Static:
	BSR.w	GetStaticNPCAnimationOffset
	MOVE.w	(A1,D0.w), obj_tile_index(A5)
	BRA.w	UpdateNPCScreenPosition
; LoadNPCAnimationFrame
; Load NPC animation frame from table
; Input: A1 = Animation table pointer, A5 = NPC object
LoadNPCAnimationFrame:
	BSR.w	GetNPCAnimationOffset
	MOVE.w	(A1,D0.w), obj_tile_index(A5)
	BRA.w	UpdateNPCScreenPosition
; AnimateEntitySprite
; Two-frame entity animation using obj_move_counter.
; Reads bit 6 of $A10001 to choose frame rate (PAL vs NTSC speed).
; Inputs: A1 = animation table, A5 = NPC/entity object
AnimateEntitySprite:
	MOVE.b	obj_move_counter(A5), D0
	BTST.b	#6, $00A10001
	BNE.w	AnimateEntitySprite_Loop
	ASR.w	#3, D0
	ANDI.w	#2, D0
	BRA.b	AnimateEntitySprite_Loop2
AnimateEntitySprite_Loop:
	ASR.w	#2, D0	
	ANDI.w	#2, D0	
AnimateEntitySprite_Loop2:
	MOVE.w	(A1,D0.w), obj_tile_index(A5)
	BRA.w	UpdateNPCScreenPosition
; SetRandomDirection
; Set random direction for NPC/entity
; Gets random number, masks to valid direction (0,2,4,6), stores in entity data
SetRandomDirection:
	JSR	GetRandomNumber
	ANDI.b	#6, D0
	MOVE.b	D0, obj_direction(A5)
	MOVE.b	D0, obj_npc_saved_dir(A5)
	RTS

; UpdateNPCMovement
; Advance a wandering NPC by one step in its saved direction.
; Checks for screen bounds, tile collision, and NPC-NPC collision before moving.
; If stuck for NPC_STUCK_THRESHOLD frames, tries to rotate 90° to find a clear path.
; Inputs: A5 = NPC entity pointer
UpdateNPCMovement:
	TST.b	obj_npc_busy_flag(A5)
	BNE.w	NPCMovement_ChangeDirection_Loop
	BSR.w	CheckEntityOnScreen
	BNE.w	NPCWander_Return
	MOVE.b	obj_npc_saved_dir(A5), obj_direction(A5)
	BSR.w	CheckSurroundingTileCollision
	BEQ.w	NPCMovement_ChangeDirection_Loop2
	MOVE.b	#FLAG_TRUE, obj_behavior_flag(A5)
	TST.b	obj_vel_x(A5)
	BNE.w	UpdateNPCMovement_Loop
	ADDQ.b	#1, obj_invuln_timer(A5)
	CMPI.b	#NPC_STUCK_THRESHOLD, obj_invuln_timer(A5)
	BLE.w	UpdateNPCMovement_Loop2
	BSR.w	CheckAdjacentTileCollision
	BNE.w	NPCMovement_ChangeDirection
	CLR.w	D6
	CLR.w	D2
	MOVE.b	obj_direction(A5), D6
	ANDI.b	#7, D6
	MOVE.b	D6, D2
	BSR.w	CheckTileCollision
	BNE.b	NPCMovement_ChangeDirection
	MOVE.b	obj_direction(A5), D6
	ANDI.b	#7, D6
	BSR.w	CheckNPCCollision
	BNE.b	NPCMovement_ChangeDirection
	MOVE.b	#FLAG_TRUE, obj_npc_busy_flag(A5)
	CLR.b	obj_move_counter(A5)
	CLR.b	obj_behavior_flag(A5)
UpdateNPCMovement_Loop:
	CLR.b	obj_invuln_timer(A5)
UpdateNPCMovement_Loop2:
	RTS

; NPCMovement_ChangeDirection
; Rotate the NPC's direction by 90° clockwise (add 2, mask to 0-7) and clear stuck timer.
NPCMovement_ChangeDirection:
	MOVE.b	obj_direction(A5), D6
	ADDQ.b	#2, D6
	ANDI.b	#7, D6
	MOVE.b	D6, obj_direction(A5)
	MOVE.b	D6, obj_npc_saved_dir(A5)
	CLR.b	obj_invuln_timer(A5)
	RTS

NPCMovement_ChangeDirection_Loop2:
	CLR.w	D2
	MOVE.b	obj_direction(A5), D2
	BSR.w	CheckTileCollision
	BNE.w	NPCWander_UpdateDirection
	MOVE.b	obj_direction(A5), D6
	BSR.w	CheckNPCCollision
	BNE.w	NPCWander_UpdateDirection
NPCMovement_ChangeDirection_Loop:
	CLR.w	D0
	MOVE.b	obj_direction(A5), D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	NPCMoveDeltaTable, A0
	MOVE.l	obj_world_x(A5), D1
	MOVE.l	obj_world_y(A5), D2
	ADD.l	(A0,D0.w), D1
	MOVE.l	D1, obj_world_x(A5)
	ADD.l	$4(A0,D0.w), D2
	MOVE.l	D2, obj_world_y(A5)
	MOVE.b	#FLAG_TRUE, obj_npc_busy_flag(A5)
	MOVE.b	#FLAG_TRUE, obj_behavior_flag(A5)
	ADDQ.b	#1, obj_hit_flag(A5)
	ADDQ.b	#1, obj_move_counter(A5)
	CMPI.b	#NPC_ROTATION_FRAMES, obj_hit_flag(A5)
	BLT.b	NPCMovement_ChangeDirection_Loop3
	CLR.b	obj_hit_flag(A5)
	CLR.b	obj_npc_busy_flag(A5)
NPCMovement_ChangeDirection_Loop3:
	RTS

; NPCWander_UpdateDirection
; Called after a blocked wander attempt. After NPC_WANDER_DELAY idle frames,
; pick a new random direction offset and resume wandering.
NPCWander_UpdateDirection:
	CLR.b	obj_behavior_flag(A5)
	ADDQ.b	#1, obj_invuln_timer(A5)
	CMPI.b	#NPC_WANDER_DELAY, obj_invuln_timer(A5)
	BLE.b	NPCWander_Return
	CLR.b	obj_invuln_timer(A5)
	CLR.b	obj_move_counter(A5)
	MOVE.b	obj_direction(A5), D1
	JSR	GetRandomNumber
	ANDI.w	#6, D0
	ADD.b	D0, D1
	ANDI.b	#7, D1
	MOVE.b	D1, obj_direction(A5)
	MOVE.b	D1, obj_npc_saved_dir(A5)
NPCWander_Return:
	RTS

;==============================================================
; COLLISION UTILITIES
;==============================================================

; CheckEntityOnScreen
; Test whether entity A5 is within ENTITY_VISIBLE_TILE_RADIUS tiles of the camera.
; Outputs: D0 = 0 if on-screen, 1 if off-screen (sets NE flag when off-screen)
CheckEntityOnScreen:
	MOVE.w	obj_world_x(A5), D0
	SUB.w	Camera_scroll_x.w, D0
	ASR.w	#4, D0
	CMPI.w	#ENTITY_VISIBLE_TILE_RADIUS, D0
	BGE.b	CheckEntityOnScreen_Offscreen
	CMPI.w	#-1, D0
	BLE.b	CheckEntityOnScreen_Offscreen
	MOVE.w	obj_world_y(A5), D0
	SUB.w	Camera_scroll_y.w, D0
	ASR.w	#4, D0
	CMPI.w	#ENTITY_VISIBLE_TILE_RADIUS, D0
	BGE.b	CheckEntityOnScreen_Offscreen
	CMPI.w	#-1, D0
	BLE.b	CheckEntityOnScreen_Offscreen
	CLR.w	D0
	RTS

CheckEntityOnScreen_Offscreen:
	MOVEQ	#1, D0
	RTS

; CheckSurroundingTileCollision
; Check all 10 tile offsets in NPCCollisionOffsetTable for A5's direction
; against the player's current tile position. Returns NE (D0=1) if any match.
; Inputs: A5 = NPC entity; D0/D1 = player tile X/Y on return
; Outputs: D0 = 0 if no overlap, 1 if player occupies one of the surrounding tiles
CheckSurroundingTileCollision:
	MOVE.w	Player_position_x_in_town.w, D0
	MOVE.w	Player_position_y_in_town.w, D1
	MOVE.w	obj_world_x(A5), D2
	ASR.w	#4, D2
	MOVE.w	obj_world_y(A5), D4
	ASR.w	#4, D4
	CLR.w	D6
	MOVE.b	obj_direction(A5), D6
	MOVE.w	D6, D7
	ADD.w	D7, D7
	ADD.w	D7, D7
	ASL.w	#4, D6
	ADD.w	D7, D6
	LEA	NPCCollisionOffsetTable, A0
	LEA	(A0,D6.w), A0
	MOVEQ	#9, D7
CheckSurroundingTileCollision_Done:
	MOVE.w	D2, D3
	MOVE.w	D4, D5
	ADD.w	(A0)+, D3
	ADD.w	(A0)+, D5
	CMP.w	D3, D0
	BNE.b	CheckEntityOverlap_NoMatch
	CMP.w	D5, D1
	BNE.b	CheckEntityOverlap_NoMatch
	BRA.b	CheckEntityOverlap_NoMatch_Loop
CheckEntityOverlap_NoMatch:
	DBF	D7, CheckSurroundingTileCollision_Done
	CLR.w	D0
	RTS

CheckEntityOverlap_NoMatch_Loop:
	MOVEQ	#1, D0
	RTS

; CheckAdjacentTileCollision
; Like CheckSurroundingTileCollision but checks only 4 adjacent offsets instead of 10.
; Used to see if the player is immediately in the NPC's path.
; Inputs: A5 = NPC entity
; Outputs: D0 = 0 if no match, 1 if player is in an adjacent tile
CheckAdjacentTileCollision:
	MOVE.w	Player_position_x_in_town.w, D0
	MOVE.w	Player_position_y_in_town.w, D1
	MOVE.w	obj_world_x(A5), D2
	ASR.w	#4, D2
	MOVE.w	obj_world_y(A5), D4
	ASR.w	#4, D4
	CLR.w	D6
	MOVE.b	obj_direction(A5), D6
	MOVE.w	D6, D7
	ADD.w	D7, D7
	ADD.w	D7, D7
	ASL.w	#4, D6
	ADD.w	D7, D6
	LEA	NPCCollisionOffsetTable, A0
	LEA	(A0,D6.w), A0
	MOVEQ	#3, D7
CheckAdjacentTileCollision_Done:
	MOVE.w	D2, D3
	MOVE.w	D4, D5
	ADD.w	(A0)+, D3
	ADD.w	(A0)+, D5
	CMP.w	D3, D0
	BNE.b	CheckAdjacentTileCollision_NoMatch
	CMP.w	D5, D1
	BNE.b	CheckAdjacentTileCollision_NoMatch
	BRA.b	CheckAdjacentTileCollision_NoMatch_Loop
CheckAdjacentTileCollision_NoMatch:
	DBF	D7, CheckAdjacentTileCollision_Done
	CLR.w	D0
	RTS

CheckAdjacentTileCollision_NoMatch_Loop:
	MOVEQ	#1, D0
	RTS

; CheckNPCCollision
; Walk the enemy/NPC linked list and check if any other active, collidable entity
; occupies the same tile offsets as A5 in direction D6.
; Inputs: A5 = NPC entity, D6 = direction (0-7)
; Outputs: D0 = 0 if path clear, 1 if another NPC is blocking
CheckNPCCollision:
	MOVE.w	obj_world_x(A5), D0
	ASR.w	#4, D0
	MOVE.w	obj_world_y(A5), D1
	ASR.w	#4, D1
	CLR.w	D4
	MOVE.w	D6, D7
	ADD.w	D7, D7
	ADD.w	D7, D7
	ASL.w	#4, D6
	ADD.w	D7, D6
	LEA	NPCCollisionOffsetTable, A0
	LEA	(A0,D6.w), A0
	MOVEQ	#$0000001D, D7
	MOVEA.l	Enemy_list_ptr.w, A6
CheckNPCCollision_Done:
	LEA	(A0), A1
	BTST.b	#7, (A6)
	BEQ.w	CheckNPCCollision_NextEntity_Loop
	CMPA.l	A5, A6
	BEQ.w	CheckNPCCollision_NextEntity
	TST.b	obj_collidable(A6)
	BEQ.w	CheckNPCCollision_NextEntity
	MOVEQ	#3, D6
	MOVE.w	obj_world_x(A6), D4
	ASR.w	#4, D4
	MOVE.w	obj_world_y(A6), D5
	ASR.w	#4, D5
CheckNPCCollision_Done2:
	MOVE.w	D0, D2
	MOVE.w	D1, D3
	ADD.w	(A1)+, D2
	ADD.w	(A1)+, D3
	CMP.w	D2, D4
	BNE.b	CheckNPCCollision_NoEntityMatch
	CMP.w	D3, D5
	BNE.b	CheckNPCCollision_NoEntityMatch
	BRA.b	CheckNPCCollision_NextEntity_Loop2
CheckNPCCollision_NoEntityMatch:
	DBF	D6, CheckNPCCollision_Done2
CheckNPCCollision_NextEntity:
	CLR.w	D2
	MOVE.b	obj_next_offset(A6), D2
	LEA	(A6,D2.w), A6
	DBF	D7, CheckNPCCollision_Done
CheckNPCCollision_NextEntity_Loop:
	CLR.w	D0
	RTS

CheckNPCCollision_NextEntity_Loop2:
	MOVEQ	#1, D0
	RTS

;==============================================================
; INVENTORY UTILITIES
;==============================================================

; RemoveItemFromList
; Remove the item matching D4 from the list at A2/A3, decrementing the count at A2.
; Inputs: A2 = pointer to item list (first word = count), A3 = list base, D4 = item ID
RemoveItemFromList:
	LEA	(A2), A1
	MOVE.w	(A2)+, D7
	BLE.w	RemoveItemFromList_Loop
	SUBQ.w	#1, D7
RemoveItemFromList_Done:
	MOVE.w	D7, D1
	ADD.w	D1, D1
	MOVE.w	(A2,D1.w), D3
	MOVE.w	D4, D0
	CMP.w	D0, D3
	BNE.b	RemoveItemFromList_Loop2
	SUBQ.w	#1, (A1)
	BGE.b	RemoveItemFromList_Loop3
	CLR.w	(A1)	
RemoveItemFromList_Loop3:
	MOVE.w	D7, D0
	MOVEA.l	A3, A0
	MOVE.w	#8, D2
	JSR	RemoveItemFromArray
RemoveItemFromList_Loop2:
	DBF	D7, RemoveItemFromList_Done
RemoveItemFromList_Loop:
	RTS

; CheckItemInList
; Search the item list at A2 for item ID D4.
; Inputs: A2 = item list pointer (first word = count), D4 = item ID to find
; Outputs: D0 = $FFFF if found, 0 if not found
CheckItemInList:
	LEA	(A2), A1
	MOVE.w	(A2)+, D7
	BLE.w	CheckCollision_Return
	SUBQ.w	#1, D7
CheckItemInList_Done:
	MOVE.w	D7, D1
	ADD.w	D1, D1
	MOVE.w	(A2,D1.w), D3
	MOVE.w	D4, D0
	CMP.w	D0, D3
	BEQ.b	CheckItemInList_Loop
	DBF	D7, CheckItemInList_Done	
	CLR.w	D0	
	BRA.b	CheckCollision_Return	
CheckItemInList_Loop:
	MOVE.w	#$FFFF, D0
CheckCollision_Return:
	RTS

;CheckRingsCollected:
; CheckRingsCollected
; Verify that all 8 ring-collected flags in Rings_collected are set.
; Outputs: D0 = 0 if all rings collected, 1 if any ring is missing
CheckRingsCollected: ; Check that we have D7 consecutive number of flags set starting from A0
	LEA	Rings_collected.w, A0
CheckRingsCollected_Done:
	TST.b	(A0)+
	BEQ.b	CheckRingsCollected_Loop
	DBF	D7, CheckRingsCollected_Done
	CLR.w	D0
	RTS

CheckRingsCollected_Loop:
	MOVE.w	#1, D0	
	RTS
	
; BackupRingsToMapTriggers
; Pack the 8 Rings_collected flags into single byte Map_triggers_backup (one bit each),
; then clear all Rings_collected entries.
BackupRingsToMapTriggers:
	CLR.b	Map_triggers_backup.w
	LEA	Rings_collected.w, A0
	MOVE.w	#7, D7
BackupRingsToMapTriggers_Done:
	TST.b	(A0)
	BEQ.b	BackupRingsToMapTriggers_Loop
	BSET.b	D7, Map_triggers_backup.w
BackupRingsToMapTriggers_Loop:
	CLR.b	(A0)
	ADDA.l	#1, A0
	DBF	D7, BackupRingsToMapTriggers_Done
	RTS

; RestoreRingsFromBackup
; Unpack the bit-packed ring flags from Map_triggers_backup back into Rings_collected,
; clearing each backup bit as it is restored.
RestoreRingsFromBackup:
	LEA	Rings_collected.w, A0
	MOVE.w	#7, D7
RestoreRingsFromBackup_Done:
	BTST.b	D7, Map_triggers_backup.w
	BEQ.b	RestoreRingsFromBackup_Loop
	MOVE.b	#$FF, (A0)
RestoreRingsFromBackup_Loop:
	BCLR.b	D7, Map_triggers_backup.w
	ADDA.l	#1, A0
	DBF	D7, RestoreRingsFromBackup_Done
	RTS

; AddItemToInventoryList
; Increment the possessed-items count and return the doubled old count in D0,
; which the caller uses as a word-array index for writing the new item entry.
; Outputs: D0 = byte offset for the new item slot in the list
AddItemToInventoryList:
	LEA	Possessed_items_length.w, A0
	MOVE.w	(A0), D0
	ADDQ.w	#1, (A0)+
	ADD.w	D0, D0
	RTS

; CheckInventoryFull
; Compare the current possessed-items count against the maximum of 8.
; Outputs: flags set by CMP — BLT if room remains, BGE if full
CheckInventoryFull:
	LEA	Possessed_items_length.w, A0
	MOVE.w	(A0), D0
	CMPI.w	#8, D0
	RTS

;==============================================================
; HINT / STATE HELPERS
;==============================================================

; SetHintTextIfTriggered
; If the map trigger at index D5 is set, copy Pending_hint_text into the NPC's
; string pointer so it displays an updated hint on next talk.
; Inputs: A5 = NPC entity, D5 = trigger index
SetHintTextIfTriggered:
	LEA	Map_trigger_flags.w, A0
	TST.b	(A0,D5.w)
	BEQ.b	SetHintTextIfTriggered_Loop
	MOVE.l	Pending_hint_text.w, obj_npc_str_ptr(A5)
SetHintTextIfTriggered_Loop:
	RTS

; ClearNPCFrozenState
; If player input is no longer blocked, clear the NPC's velocity to unfreeze it.
; Inputs: A5 = NPC entity
ClearNPCFrozenState:
	TST.b	Player_input_blocked.w
	BNE.b	ClearNPCFrozenState_Loop
	CLR.b	obj_vel_x(A5)
ClearNPCFrozenState_Loop:
	RTS

;==============================================================
; DATA TABLES
;==============================================================

; NPCCollisionOffsetTable
; 8 rows of 10 tile-offset pairs (dx, dy) indexed by direction * 20 bytes.
; Used by CheckSurroundingTileCollision / CheckAdjacentTileCollision / CheckNPCCollision.
; Each row covers the tiles the NPC occupies when moving in that direction.
NPCCollisionOffsetTable:
	dc.w	 0, -2,  0, -1, -1, -1,  1, -1, -1,  0,  1,  0, -1,  1,  0,  1
	dc.w	 1,  1,  0,  2, -2,  0, -1,  0, -1, -1, -1,  1,  0,  1,  0, -1 
	dc.w	 1,  1,  1,  0,  1, -1,  2,  0,  0,  2,  0,  1, -1,  1,  1,  1
	dc.w	-1, -1, -1,  0,  0, -1,  1, -1,  1,  0,  0, -2,  2,  0,  1,  0 
	dc.w	 1, -1,  1,  1, -1, -1, -1,  0, -1,  1,  0, -1,  0,  1, -2,  0
; NPCMoveDeltaTable
; Four long-word pairs (dx, dy) giving the sub-pixel world displacement per step
; for each cardinal direction: Up, Left, Down, Right.
; $FFFF8000 = -1/2 tile (negative step), $00008000 = +1/2 tile (positive step).
NPCMoveDeltaTable:
	dc.l	$00000000, $FFFF8000 
	dc.l	$FFFF8000, $00000000 
	dc.l	$00000000, $00008000 
	dc.l	$00008000, $00000000 
ParmaSoldierBoundingBoxTable: ; Parma soldiers detection area
	dc.w -3, 0,  0, 3
	dc.w -3, 1, -3, 3
	dc.w -3, 1, -3, 3
	dc.w -1, 3, -3, 3

;==============================================================
; OBJECT SLOT PROCESSING
;==============================================================

; ProcessAllObjectSlots
; Initialize all map-object entity slots: 5 chains of 7 entities, 5 paired entities,
; 5 single-sprite entities, and the map indicator entity.
ProcessAllObjectSlots:
	MOVEA.l	Enemy_list_ptr.w, A6
	BSR.w	InitObjectChain_7Entities
	MOVEA.l	Object_slot_01_ptr.w, A6
	BSR.w	InitObjectChain_7Entities
	MOVEA.l	Object_slot_02_ptr.w, A6
	BSR.w	InitObjectChain_7Entities
	MOVEA.l	Object_slot_03_ptr.w, A6
	BSR.w	InitObjectChain_7Entities
	MOVEA.l	Object_slot_04_ptr.w, A6
	BSR.w	InitObjectChain_7Entities
	MOVEA.l	Object_slot_05_ptr.w, A6
	BSR.w	InitPairedObjectEntities
	MOVEA.l	Object_slot_06_ptr.w, A6
	BSR.w	InitPairedObjectEntities
	MOVEA.l	Object_slot_07_ptr.w, A6
	BSR.w	InitPairedObjectEntities
	MOVEA.l	Object_slot_08_ptr.w, A6
	BSR.w	InitPairedObjectEntities
	MOVEA.l	Object_slot_09_ptr.w, A6
	BSR.w	InitPairedObjectEntities
	MOVEA.l	Object_slot_0A_ptr.w, A6
	BSR.w	InitObjectEntity_Type6
	MOVEA.l	Object_slot_0B_ptr.w, A6
	BSR.w	InitObjectEntity_Type6
	MOVEA.l	Object_slot_0C_ptr.w, A6
	BSR.w	InitObjectEntity_Type6
	MOVEA.l	Object_slot_0D_ptr.w, A6
	BSR.w	InitObjectEntity_Type6
	MOVEA.l	Object_slot_0E_ptr.w, A6
	BSR.w	InitObjectEntity_Type6
	BSR.w	InitMapIndicatorEntity
	RTS

ProcessAllObjectSlots_DeadCode:					; unreferenced dead code
	MOVEA.l	Map_indicator_entity_ptr.w, A6
	MOVE.w	#$0030, D7
ProcessAllObjectSlots_Done:
	BCLR	#7, (A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	$0(A6,D0.w), A6
	DBF	D7, ProcessAllObjectSlots_Done
	RTS

; InitObjectChain_7Entities
; Activate and configure a chain of 7 linked entity slots starting at A6.
; Parent gets ChainObjectTick_Parent tick; remaining 6 get ChildObjectTick.
; Every other child has sprite bit 3 set (alternate palette / row).
; Inputs: A6 = pointer to first entity in the chain
InitObjectChain_7Entities:
	BSR.w	InitObjectEntity_Type14
	MOVE.l	#ChainObjectTick_Parent, obj_tick_fn(A6)
	BSR.w	InitNextObjectEntity
	BSET.b	#3, obj_sprite_flags(A6)
	BSR.w	InitNextObjectEntity
	BSR.w	InitNextObjectEntity
	BSET.b	#3, obj_sprite_flags(A6)
	BSR.w	InitNextObjectEntity
	BSR.w	InitNextObjectEntity
	BSET.b	#3, obj_sprite_flags(A6)
	RTS

; InitNextObjectEntity
; Advance A6 to the next entity via obj_next_offset and assign ChildObjectTick.
; Falls through into InitObjectEntity_Type14 to set flags/size.
; Inputs: A6 = current entity; updated on return to next entity
InitNextObjectEntity:
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	MOVE.l	#ChildObjectTick, obj_tick_fn(A6)
InitObjectEntity_Type14:
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BSET.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	RTS

; InitPairedObjectEntities
; Activate and configure two consecutive linked entity slots as a pair.
; First entity gets PairedObjectTick_A; the second gets ChildObjectTick.
; Inputs: A6 = pointer to first entity of the pair
InitPairedObjectEntities:
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BSET.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#PairedObjectTick_A, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BSET.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A6)
	MOVE.l	#ChildObjectTick, obj_tick_fn(A6)
	RTS

; InitObjectEntity_Type6
; Activate a single standalone entity slot with SingleObjectTick and a 3x2 sprite size.
; Inputs: A6 = entity pointer
InitObjectEntity_Type6:
	BSET.b	#7, (A6)
	MOVE.l	#SingleObjectTick, obj_tick_fn(A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BSET.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_3x2, obj_sprite_size(A6)
	RTS

; InitMapIndicatorEntity
; Activate the map-indicator entity (the arrow showing player position on the overworld).
; Sets MapIndicatorEntityTick, 2x1 sprite size, and enables the high-priority sprite flag.
InitMapIndicatorEntity:
	MOVEA.l	Map_indicator_entity_ptr.w, A6
	BSET.b	#7, (A6)
	MOVE.l	#MapIndicatorEntityTick, obj_tick_fn(A6)
	BSET.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BCLR.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_2x1, obj_sprite_size(A6)
	RTS

;==============================================================
; OBJECT TICK FUNCTIONS
;==============================================================

; MapIndicatorEntityTick
; Each frame: if not in a town, compute screen position from the player's overworld
; tile, pick the correct directional arrow tile from MapIndicatorTileIDs, and queue OAM.
; Inputs: A5 = map indicator entity
MapIndicatorEntityTick:
	TST.b	Player_input_blocked.w
	BNE.b	MapIndicatorEntityTick_Loop
	MOVE.w	Player_position_x_outside_town.w, D0
	MOVE.w	Player_position_y_outside_town.w, D1
	ANDI.w	#$000F, D0
	ANDI.w	#$000F, D1
	ASL.w	#3, D0
	ASL.w	#3, D1
	ADDI.w	#$00BC, D0
	ADDI.w	#$0010, D1
	MOVE.w	D0, obj_screen_x(A5)
	MOVE.w	D1, obj_screen_y(A5)
	LEA	MapIndicatorTileIDs, A0
	MOVE.w	Player_direction.w, D4
	ANDI.w	#6, D4
	MOVE.w	(A0,D4.w), obj_tile_index(A5)
	JSR	QueueSpriteOAMIfVisible
MapIndicatorEntityTick_Loop:
	RTS

; MapIndicatorTileIDs
; Four VRAM tile indices for the directional arrows (Up, Left, Down, Right).
; Indexed by (Player_direction & 6) as a word offset.
MapIndicatorTileIDs:
	dc.w	$04D5 
	dc.w	$04D3 
	dc.w	$04D7 
	dc.w	$04D1 

; ChainObjectTick_Parent
; Each frame: distribute tile indices and screen positions to all 6 child entities in
; the chain, then queue OAM for the parent sprite if visible within the battle arena.
; Reads PortraitPositionOffsets for per-child screen offsets.
; Inputs: A5 = parent entity
ChainObjectTick_Parent:
	BSET.b	#5, obj_sprite_flags(A5)
	BCLR.b	#6, obj_sprite_flags(A5)
	TST.b	obj_direction(A5)
	BEQ.b	ChainObjectTick_Parent_Loop
	BCLR.b	#5, obj_sprite_flags(A5)	
	BSET.b	#6, obj_sprite_flags(A5)	
ChainObjectTick_Parent_Loop:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.w	obj_tile_index(A5), D6
	CMPI.w	#0, D6
	BLE.w	ChainObjectTick_Parent_Loop2
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6)
	BSET.b	#3, obj_sprite_flags(A6)
	MOVE.w	D6, obj_tile_index(A6)
	MOVEQ	#1, D7
ChainObjectTick_Parent_Loop_Done:
	ADDI.w	#$000C, D6
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	MOVE.w	D6, obj_tile_index(A6)
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	MOVE.w	D6, obj_tile_index(A6)
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6)
	BSET.b	#3, obj_sprite_flags(A6)
	DBF	D7, ChainObjectTick_Parent_Loop_Done
	BRA.w	ChainObjectTick_Parent_Loop3
ChainObjectTick_Parent_Loop2:
	MOVEQ	#4, D7
ChainObjectTick_Parent_Loop2_Done:
	MOVE.w	#0, obj_tile_index(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, ChainObjectTick_Parent_Loop2_Done
ChainObjectTick_Parent_Loop3:
	LEA	PortraitPositionOffsets, A0
	MOVE.w	obj_world_x(A5), D3
	MOVE.w	obj_world_y(A5), D4
	MOVE.w	#SORT_KEY_CHAIN_OBJ, obj_sort_key(A5)
	MOVE.w	D3, D1
	MOVE.w	D4, D2
	ADD.w	(A0)+, D1
	ADD.w	(A0)+, D2
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.w	D1, obj_screen_x(A5)
	MOVE.w	D2, obj_screen_y(A5)
	MOVEQ	#4, D7
ChainObjectTick_Parent_Loop3_Done:
	MOVE.w	D3, D1
	MOVE.w	D4, D2
	ADD.w	(A0)+, D1
	ADD.w	(A0)+, D2
	MOVE.w	D1, obj_screen_x(A6)
	MOVE.w	D2, obj_screen_y(A6)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
	MOVE.w	obj_world_x(A5), obj_world_x(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, ChainObjectTick_Parent_Loop3_Done
	TST.w	obj_tile_index(A5)
	BEQ.b	ChainObjectTick_Parent_Return
	MOVE.w	obj_world_x(A5), D0
	BLE.b	ChainObjectTick_Parent_Return
	CMPI.w	#BATTLE_ARENA_EDGE, D0
	BGE.b	ChainObjectTick_Parent_Return
	JSR	QueueSpriteOAMIfVisible
ChainObjectTick_Parent_Return:
	RTS

; PairedObjectTick_A
; Each frame: mirror tile index +12 and sprite flags to the paired child entity,
; position both at obj_world coords (child 24 pixels above parent), then queue OAM.
; Inputs: A5 = primary (parent) entity of the pair
PairedObjectTick_A:
	BSET.b	#5, obj_sprite_flags(A5)
	BCLR.b	#6, obj_sprite_flags(A5)
	TST.b	obj_direction(A5)
	BEQ.b	PairedObjectTick_A_Loop
	BCLR.b	#5, obj_sprite_flags(A5)	
	BSET.b	#6, obj_sprite_flags(A5)	
PairedObjectTick_A_Loop:
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A6
	MOVE.w	#SORT_KEY_PAIRED_OBJ, obj_sort_key(A5)
	MOVE.w	obj_tile_index(A5), D6
	CMPI.w	#0, D6
	BLE.b	PairedObjectTick_A_Loop2
	ADDI.w	#$000C, D6
	MOVE.w	D6, obj_tile_index(A6)
	MOVE.b	obj_sprite_flags(A5), obj_sprite_flags(A6)
	BRA.b	PairedObjectTick_A_Loop3
PairedObjectTick_A_Loop2:
	MOVE.w	#0, obj_tile_index(A6)
PairedObjectTick_A_Loop3:
	MOVE.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A5), D1
	MOVE.w	D0, obj_screen_x(A6)
	MOVE.w	D1, obj_screen_y(A6)
	SUBI.w	#$0018, D1
	MOVE.w	D0, obj_screen_x(A5)
	MOVE.w	D1, obj_screen_y(A5)
	MOVE.w	obj_sort_key(A5), obj_sort_key(A6)
	MOVE.w	obj_world_x(A5), obj_world_x(A6)
	TST.w	obj_tile_index(A5)
	BEQ.b	PairedObjectTick_A_Return
	MOVE.w	obj_world_x(A5), D0
	BLE.b	PairedObjectTick_A_Return
	CMPI.w	#BATTLE_ARENA_EDGE, D0
	BGE.b	PairedObjectTick_A_Return
	JSR	QueueSpriteOAMIfVisible
PairedObjectTick_A_Return:
	RTS

; SingleObjectTick
; Each frame: set screen position from world coords, assign sort key, and queue OAM
; if tile index is set and the entity is inside the battle arena.
; Inputs: A5 = entity
SingleObjectTick:
	BSET.b	#5, obj_sprite_flags(A5)
	BCLR.b	#6, obj_sprite_flags(A5)
	TST.b	obj_direction(A5)
	BEQ.b	SingleObjectTick_Loop
	BCLR.b	#5, obj_sprite_flags(A5)	
	BSET.b	#6, obj_sprite_flags(A5)	
SingleObjectTick_Loop:
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	#SORT_KEY_SINGLE_OBJ, obj_sort_key(A5)
	TST.w	obj_tile_index(A5)
	BLE.b	SingleObjectTick_Return
	MOVE.w	obj_world_x(A5), D0
	BLE.b	SingleObjectTick_Return
	CMPI.w	#BATTLE_ARENA_EDGE, D0
	BGE.b	SingleObjectTick_Return
	JSR	QueueSpriteOAMIfVisible
SingleObjectTick_Return:
	RTS

; ChildObjectTick
; Each frame: if tile index is non-zero and inside the battle arena, queue OAM.
; Screen position was already set by the parent tick function.
; Inputs: A5 = child entity
ChildObjectTick:
	MOVE.w	obj_tile_index(A5), D0
	BEQ.b	ChildObjectTick_Return
	MOVE.w	obj_world_x(A5), D0
	BLE.b	ChildObjectTick_Return
	CMPI.w	#BATTLE_ARENA_EDGE, D0
	BGE.b	ChildObjectTick_Return
	JSR	QueueSpriteOAMIfVisible
ChildObjectTick_Return:
	RTS

;==============================================================
; TALKER PORTRAIT INITS
;==============================================================

; PortraitInit_Simple
; Load the talker portrait sprite with no special tick behaviour.
PortraitInit_Simple:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	RTS

; PortraitInit_MapGiver
; Load portrait and assign PortraitTick_MapGiver to both the primary and secondary
; entity slots, activating the secondary slot via SetObjectActiveFlag.
PortraitInit_MapGiver:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_MapGiver, obj_tick_fn(A5)
	BSR.w	SetObjectActiveFlag
	MOVE.l	#PortraitTick_MapGiver, obj_tick_fn(A4)
	RTS

; PortraitInit_StowGirl
; Load portrait and assign PortraitTick_StowGirl (handles Sanguios book sale)
; to both entity slots.
PortraitInit_StowGirl:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_StowGirl, obj_tick_fn(A5)
	BSR.w	SetObjectActiveFlag
	MOVE.l	#PortraitTick_StowGirl, obj_tick_fn(A4)
	RTS

; PortraitInit_RingOfWisdom
; Load portrait and assign PortraitTick_RingOfWisdom (checks ring collection status).
PortraitInit_RingOfWisdom:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_RingOfWisdom, obj_tick_fn(A5)
	RTS

; PortraitInit_ImposterGuard
; Load portrait and assign PortraitTick_ImposterGuard (hides guard after boss trigger).
PortraitInit_ImposterGuard:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_ImposterGuard, obj_tick_fn(A5)
	RTS

; PortraitInit_MalagaPrisoner
; Load portrait and assign PortraitTick_MalagaPrisoner (handles crown/quest dialog).
PortraitInit_MalagaPrisoner:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_MalagaPrisoner, obj_tick_fn(A5)
	RTS

; PortraitInit_TsarkonFinal
; Load portrait and assign PortraitTick_TsarkonFinal to both entity slots.
; Tsarkon disappears from dialog after he is defeated.
PortraitInit_TsarkonFinal:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_TsarkonFinal, obj_tick_fn(A5)
	BSR.w	SetObjectActiveFlag
	MOVE.l	#PortraitTick_TsarkonFinal, obj_tick_fn(A4)
	RTS

; PortraitInit_Bearwulf
; Load portrait and assign PortraitTick_Bearwulf to both slots.
; Bearwulf disappears after his quest flag is set.
PortraitInit_Bearwulf:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_Bearwulf, obj_tick_fn(A5)
	BSR.w	SetObjectActiveFlag
	MOVE.l	#PortraitTick_Bearwulf, obj_tick_fn(A4)
	RTS

; PortraitInit_TruffleGiver
; Load portrait and assign PortraitTick_Truffle to both slots.
; NPC disappears after Truffle is collected.
PortraitInit_TruffleGiver:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_Truffle, obj_tick_fn(A5)
	BSR.w	SetObjectActiveFlag
	MOVE.l	#PortraitTick_Truffle, obj_tick_fn(A4)
	RTS

; PortraitInit_DigotGiver
; Load portrait and assign PortraitTick_Digot to both slots.
; NPC disappears after the Digot plant is received.
PortraitInit_DigotGiver:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_Digot, obj_tick_fn(A5)
	BSR.w	SetObjectActiveFlag
	MOVE.l	#PortraitTick_Digot, obj_tick_fn(A4)
	RTS

;==============================================================
; PORTRAIT SPRITE SETUP
;==============================================================

; InitEncounterPortrait
; Set up the enemy encounter portrait sprite(s) for the current battle.
; Looks up the encounter type from EnemyEncounterGroupTable + Random_number,
; reads graphics data from EnemyGfxDataTable, and positions the sprite at
; screen coords ($5C, $A8). Optionally activates a second sprite for large enemies.
; Inputs: A5 = primary portrait entity
InitEncounterPortrait:
	LEA	EnemyEncounterGroupTable, A1
	CLR.w	D2
	MOVE.b	Encounter_group_index.w, D2
	ADD.w	D2, D2
	ADD.w	D2, D2
	MOVEA.l	(A1,D2.w), A6
	MOVE.w	Random_number.w, D0 ; The specific encounter option
	ADD.w	D0, D0
	MOVE.w	(A6,D0.w), D1
	MOVE.w	D1, Current_encounter_type.w
	LEA	EnemyGfxDataTable, A6
	MULU.w	#$C, D1 ; Each encounter encompasses three pointers
	MOVEA.l	(A6,D1.w), A6
	MOVE.b	$14(A6), obj_sprite_size(A5)
	MOVE.w	obj_sort_key(A6), Palette_line_3_index.w
	MOVE.b	#NPC_ATTR_PAL3, obj_sprite_flags(A5)
	BSET.b	#7, obj_sprite_flags(A5)
	BCLR.b	#3, obj_sprite_flags(A5)
	BCLR.b	#4, obj_sprite_flags(A5)
	MOVE.w	#VRAM_TILE_ENCOUNTER_PORTRAIT, obj_tile_index(A5)
	MOVE.l	#PortraitIdleLoop, obj_tick_fn(A5)
	MOVE.w	#$005C, obj_screen_x(A5)
	MOVE.w	#$00A8, obj_screen_y(A5)
	MOVE.w	obj_world_y(A6), D0
	BEQ.b	InitEncounterPortrait_Loop
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A4
	BSET.b	#7, (A4)
	MOVE.b	$15(A6), obj_sprite_size(A4)
	MOVE.b	#NPC_ATTR_PAL3, obj_sprite_flags(A4)
	BSET.b	#7, obj_sprite_flags(A4)
	BCLR.b	#3, obj_sprite_flags(A4)
	BCLR.b	#4, obj_sprite_flags(A4)
	MOVE.w	#$043B, obj_tile_index(A4)
	MOVE.l	#PortraitIdleLoop, obj_tick_fn(A4)
	MOVE.w	#$005C, D0
	ADD.w	$10(A6), D0
	MOVE.w	D0, obj_screen_x(A4)
	MOVE.w	#$00A8, D0
	ADD.w	obj_world_y(A6), D0
	MOVE.w	D0, obj_screen_y(A4)
InitEncounterPortrait_Loop:
	JSR	LoadPalettesFromTable
	RTS

; InitTalkerPortraitSprite
; Set up the portrait sprite for an NPC talker dialog.
; Reads sprite size and palette index from the graphics descriptor at A6,
; positions at screen ($5C, $A8), sets PortraitIdleLoop tick, and optionally
; activates a secondary sprite via A4 for two-part portraits.
; Inputs: A5 = portrait entity, A6 = talker graphics descriptor pointer
InitTalkerPortraitSprite:
	MOVE.b	obj_direction(A6), obj_sprite_size(A5)
	MOVE.w	obj_invuln_timer(A6), Palette_line_3_index.w
	MOVE.b	#NPC_ATTR_PAL3, obj_sprite_flags(A5)
	BSET.b	#7, obj_sprite_flags(A5)
	BCLR.b	#3, obj_sprite_flags(A5)
	BCLR.b	#4, obj_sprite_flags(A5)
	MOVE.w	#VRAM_TILE_ENCOUNTER_PORTRAIT, obj_tile_index(A5)
	MOVE.l	#PortraitIdleLoop, obj_tick_fn(A5)
	MOVE.w	#$005C, obj_screen_x(A5)
	MOVE.w	#$00A8, obj_screen_y(A5)
	MOVE.w	obj_sort_key(A6), D0
	BEQ.b	InitTalkerPortraitSprite_Loop
	CLR.w	D0
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A4
	BSET.b	#7, (A4)
	MOVE.b	$19(A6), obj_sprite_size(A4)
	MOVE.b	#NPC_ATTR_PAL3, obj_sprite_flags(A4)
	BSET.b	#7, obj_sprite_flags(A4)
	BCLR.b	#3, obj_sprite_flags(A4)
	BCLR.b	#4, obj_sprite_flags(A4)
	MOVE.w	#$043B, obj_tile_index(A4)
	MOVE.l	#PortraitIdleLoop, obj_tick_fn(A4)
	MOVE.w	#$005C, D0
	ADD.w	$14(A6), D0
	MOVE.w	D0, obj_screen_x(A4)
	MOVE.w	#$00A8, D0
	ADD.w	obj_sort_key(A6), D0
	MOVE.w	D0, obj_screen_y(A4)
InitTalkerPortraitSprite_Loop:
	JSR	LoadPalettesFromTable
	RTS

;==============================================================
; TALKER PORTRAIT TICKS
;==============================================================

; PortraitIdleLoop
; Default per-frame tick for a portrait entity: simply queue OAM if visible.
PortraitIdleLoop:
	JMP	QueueSpriteOAMIfVisible

; PortraitTick_RingOfWisdom
; If the first ring has been collected, switch dialog to the post-ring message.
PortraitTick_RingOfWisdom:
	TST.b	Rings_collected.w
	BEQ.b	PortraitTick_RingOfWisdom_Loop
	MOVE.l	#OnlyYouCanSaveUsStr, Script_talk_source.w
PortraitTick_RingOfWisdom_Loop:
	JMP	QueueSpriteOAMIfVisible

; PortraitTick_StowGirl
; Handle the Sanguios book vendor in Stow. Deactivates the portrait if the girl has
; already left town, selects appropriate price/sold-out dialog, and charges the player.
PortraitTick_StowGirl:
	TST.b	Girl_left_for_stow.w
	BEQ.b	PortraitTick_StowGirl_Loop
	MOVE.l	#NoOneHereStr, Script_talk_source.w
	BCLR.b	#7, (A5)
	CLR.b	Talker_present_flag.w
	RTS

PortraitTick_StowGirl_Loop:
	TST.b	Accused_of_theft.w
	BNE.b	NPCTick_SanguiosVendor_Display
	TST.b	Sanguios_book_offered.w
	BEQ.b	PortraitTick_StowGirl_Loop2
	TST.b	Sanguios_purchased.w
	BNE.b	PortraitTick_StowGirl_Loop3
	LEA	Possessed_magics_length.w, A0
	MOVE.w	(A0), D0
	ADDQ.w	#1, (A0)+
	ADD.w	D0, D0
	MOVE.w	#((ITEM_TYPE_NON_DISCARDABLE<<8)|MAGIC_SANGUIOS), (A0,D0.w)
	MOVE.l	#PRICE_SANGUIOS, Transaction_amount.w
	JSR	DeductPaymentAmount
	MOVE.b	#FLAG_TRUE, Sanguios_purchased.w
PortraitTick_StowGirl_Loop3:
	MOVE.l	#NothingForYouStr, Script_talk_source.w
	BRA.b	NPCTick_SanguiosVendor_Display
PortraitTick_StowGirl_Loop2: ; buy Sanguios from little girl
	MOVE.l	#PRICE_SANGUIOS, D0
	MOVE.l	Player_kims.w, D1
	ANDI.l	#$00FFFFFF, D1
	CMP.l	D0, D1
	BLT.b	PortraitTick_StowGirl_Loop4
	LEA	Possessed_magics_length.w, A0
	MOVE.w	(A0), D0
	CMPI.w	#8, D0
	BLT.b	PortraitTick_StowGirl_Loop5
	MOVE.l	#BuyBookSanguiosThirdStr3, Script_talk_source.w	
	BRA.b	NPCTick_SanguiosVendor_Display	
PortraitTick_StowGirl_Loop4:
	MOVE.l	#BuyBookSanguiosStr2, Script_talk_source.w	
	BRA.b	NPCTick_SanguiosVendor_Display	
PortraitTick_StowGirl_Loop5:
	MOVE.l	#BuyBookSanguiosStr, Script_talk_source.w
NPCTick_SanguiosVendor_Display:
	JMP	QueueSpriteOAMIfVisible

; PortraitTick_ImposterGuard
; If the imposter boss event has triggered, replace dialog with "NoOneHere" to
; indicate the guard has been dispatched.
PortraitTick_ImposterGuard:
	TST.b	Imposter_boss_trigger.w
	BEQ.b	PortraitTick_ImposterGuard_Loop
	MOVE.l	#NoOneHereStr, Script_talk_source.w
PortraitTick_ImposterGuard_Loop:
	JMP	QueueSpriteOAMIfVisible

; PortraitTick_MalagaPrisoner
; Select the correct dialog based on crown/quest progress flags.
; Removes the crown from inventory once the king is crowned.
PortraitTick_MalagaPrisoner:
	TST.b	Malaga_king_crowned.w
	BEQ.b	PortraitTick_MalagaPrisoner_Loop
	LEA	Possessed_items_list.w, A3
	LEA	Possessed_items_length.w, A2
	MOVE.w	#$0114, D4 ; Crown?
	JSR	RemoveItemFromList
	MOVE.l	#ReturnToMalagaStr, Script_talk_source.w
	BRA.b	PortraitTick_MalagaPrisoner_Done
PortraitTick_MalagaPrisoner_Loop:
	MOVE.l	#NeverExpectedSucceedStr, Script_talk_source.w
	TST.b	Crown_received.w
	BNE.b	PortraitTick_MalagaPrisoner_Done
	MOVE.l	#HaveYouGivenUpStr, Script_talk_source.w
	TST.b	Malaga_quest_progress.w
	BNE.b	PortraitTick_MalagaPrisoner_Done
	MOVE.l	#WaitingForPlayerNameStr, Script_talk_source.w
PortraitTick_MalagaPrisoner_Done:
	JMP	QueueSpriteOAMIfVisible

; PortraitTick_TsarkonFinal
; Once Tsarkon is dead, switch to the ending message and deactivate the portrait entity.
PortraitTick_TsarkonFinal:
	TST.b	Tsarkon_is_dead.w
	BEQ.b	PortraitTick_TsarkonFinal_Loop
	MOVE.l	#EvilDiedWithTsarkonStr, Script_talk_source.w
	BCLR.b	#7, (A5)
	CLR.b	Talker_present_flag.w
	RTS

PortraitTick_TsarkonFinal_Loop:
	JMP	QueueSpriteOAMIfVisible

; PortraitTick_Bearwulf / PortraitTick_Truffle / PortraitTick_Digot
; Generic quest-item givers: load the relevant "collected" flag address into A0
; and fall through to PortraitTick_CheckCollectedFlag.
PortraitTick_Bearwulf:
	LEA	Bearwulf_met.w, A0
	BRA.w	PortraitTick_CheckCollectedFlag

; PortraitTick_Truffle
; Check Truffle_collected flag and deactivate the portrait if it is set.
PortraitTick_Truffle:
	LEA	Truffle_collected.w, A0
	BRA.w	PortraitTick_CheckCollectedFlag

; PortraitTick_Digot
; Check Digot_plant_received flag and deactivate the portrait if it is set.
PortraitTick_Digot:
	LEA	Digot_plant_received.w, A0
	BRA.w	PortraitTick_CheckCollectedFlag

; PortraitTick_MapGiver
; Check the map-trigger flag for this NPC. If set, reveal the area map and deactivate.
PortraitTick_MapGiver:
	LEA	Map_trigger_flags.w, A0
	MOVE.w	Map_trigger_index.w, D5
	TST.b	(A0,D5.w)
	BEQ.b	PortraitTick_MapGiver_Loop
	MOVE.l	#NoOneHereStr, Script_talk_source.w
	BCLR.b	#7, (A5)
	MOVE.b	#FLAG_TRUE, Area_map_revealed.w
	JMP	UpdateAreaVisibility
PortraitTick_MapGiver_Loop:
	JMP	QueueSpriteOAMIfVisible

; PortraitTick_CheckCollectedFlag
; Shared tail for quest-item givers. If flag at A0 is set, hide the portrait entity
; and clear Talker_present_flag so the NPC is no longer available for dialog.
; Inputs: A0 = pointer to the "collected" flag byte, A5 = portrait entity
PortraitTick_CheckCollectedFlag:
	TST.b	(A0)
	BEQ.b	PortraitTick_CheckCollectedFlag_Loop
	MOVE.l	#NoOneHereStr, Script_talk_source.w
	BCLR.b	#7, (A5)
	CLR.b	Talker_present_flag.w
	RTS

PortraitTick_CheckCollectedFlag_Loop:
	JMP	QueueSpriteOAMIfVisible

; PortraitPositionOffsets
; Six (dx, dy) word pairs giving screen offsets for each child entity in a 3-row chain:
; two sprites per row at X -16/+16, rows at Y -48, -24, 0.
PortraitPositionOffsets:
	dc.w	-16, -48, 16, -48 
	dc.w	-16, -24, 16, -24
	dc.w	-16, 0, 16, 0 

; SetObjectActiveFlag
; Advance to the next entity slot from A5 via obj_next_offset and set its active bit.
; Outputs: A4 = pointer to the activated secondary entity
SetObjectActiveFlag:
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A4
	BSET.b	#7, (A4)
	RTS

;==============================================================
; ENCOUNTER INITIALIZATION
;==============================================================

; InitializeEncounter
; Prepare an encounter: fill Enemy_position_indices with 0-7, shuffle them randomly,
; then for each enemy up to Number_Of_Enemies, activate an entity slot and copy stats
; (HP, XP, gold reward, sprite size, etc.) from EnemyGfxDataTable.
; Loads palettes and encounter graphics when done.
InitializeEncounter:
	LEA	Enemy_position_indices.w, A1
	CLR.w	D0
	MOVE.w	#7, D7
InitializeEncounter_Done:
	MOVE.b	D0, (A1)+
	ADDQ.b	#1, D0
	DBF	D7, InitializeEncounter_Done
	MOVEA.l	Enemy_list_ptr.w, A6 ; Where to load enemies into
	LEA	EnemyGfxDataTable, A0
	MOVE.w	Current_encounter_type.w, D0
	MULU.w	#$C, D0
	ADDQ.w	#4, D0
	MOVEA.l	(A0,D0.w), A0
	TST.b	Soldier_fight_event_trigger.w
	BEQ.w	InitializeEncounter_Loop
	MOVE.w	#4, D7
	BRA.w	EncounterInit_FinalizeEnemyCount
InitializeEncounter_Loop:
	JSR	GetRandomNumber
	ANDI.w	#7, D0
	MOVE.w	D0, D7
	MOVE.b	$B(A0), D0
	CMP.w	D0, D7
	BLE.w	EncounterInit_FinalizeEnemyCount
	MOVE.w	D0, D7
EncounterInit_FinalizeEnemyCount:
	MOVE.w	D7, Number_Of_Enemies.w
	LEA	Enemy_position_indices.w, A1
	MOVE.w	#7, D7
EncounterInit_FinalizeEnemyCount_Done:
	JSR	GetRandomNumber
	ANDI.w	#7, D0
	MOVE.w	D0, D1
	JSR	GetRandomNumber
	ANDI.w	#7, D0
	MOVE.b	(A1,D1.w), D2
	MOVE.b	(A1,D0.w), D3
	MOVE.b	D3, (A1,D1.w)
	MOVE.b	D2, (A1,D0.w)
	DBF	D7, EncounterInit_FinalizeEnemyCount_Done
	LEA	Enemy_position_indices.w, A1
	MOVE.w	Number_Of_Enemies.w, D7
EncounterInit_FinalizeEnemyCount_Done2: ; Loop number of enemies
	BSET.b	#7, (A6)
	BSET.b	#6, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	CLR.b	obj_hit_flag(A6)
	MOVE.b	#DIRECTION_DOWN, obj_direction(A6)
	MOVE.b	#NPC_ATTR_PAL1, obj_sprite_flags(A6)
	CLR.b	obj_max_hp(A6)
	CLR.b	obj_invuln_timer(A6)
	CLR.b	obj_move_counter(A6)
	CLR.b	obj_behavior_flag(A6)
	LEA	EnemyStartingPositions, A2
	CLR.w	D0
	MOVE.b	(A1)+, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVE.w	(A2,D0.w), obj_world_x(A6)		; x position
	MOVE.w	$2(A2,D0.w), obj_world_y(A6)	; y position
	MOVE.w	$4(A0), Palette_line_1_index.w
	MOVE.w	$6(A0), Enemy_reward_type.w
	MOVE.w	$8(A0), Enemy_reward_value.w
	MOVE.w	$C(A0), obj_hp(A6)
	MOVE.w	$E(A0), obj_max_hp(A6)
	MOVE.w	$10(A0), obj_xp_reward(A6)
	MOVE.w	$12(A0), obj_kim_reward(A6)
	MOVE.l	$14(A0), obj_pos_x_fixed(A6)
	MOVE.b	$18(A0), obj_sprite_frame(A6)
	MOVE.b	$19(A0), obj_behavior_flag(A6)
	MOVE.l	$0(A0), obj_tick_fn(A6)
	CLR.w	D6
	MOVE.b	$A(A0), D6
	CLR.w	D0
	CLR.w	D1
	MOVE.b	obj_next_offset(A6), D0
	MOVE.b	$1(A6,D0.w), D1
	ADD.w	D1, D0
	ADD.w	D1, D0
EncounterInit_FinalizeEnemyCount_Done3:
	LEA	(A6,D0.w), A6
	DBF	D6, EncounterInit_FinalizeEnemyCount_Done3
	DBF	D7, EncounterInit_FinalizeEnemyCount_Done2
	JSR	LoadPalettesFromTable
	JSR	LoadEncounterGraphics
	RTS

