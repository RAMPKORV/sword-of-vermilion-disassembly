; ======================================================================
; src/npc.asm
; NPC ticks/inits, talker portraits, encounter initialization
; ======================================================================
NPCTick_Soldier_Init:
	MOVE.b	#SPRITE_SIZE_2x3, obj_sprite_size(A5)
	MOVE.l	#NPCTick_Soldier_UpdatePos, obj_tick_fn(A5)
	RTS

NPCTick_Soldier_UpdatePos:
	BRA.w	UpdateNPCScreenPosition
	MOVE.b	#SPRITE_SIZE_2x3, obj_sprite_size(A5)
	MOVE.l	#NPCTick_StowSoldier_DoctorHint, obj_tick_fn(A5)
	RTS

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
NPCInit_StowSoldier_DoctorHint:
	BSR.w	SetRandomDirection
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS

; UpdateNPCSpriteFrame
; Update NPC sprite animation frame
; Sets animation flag, calls sprite update, restores direction
UpdateNPCSpriteFrame:
	MOVEA.l	obj_anim_ptr(A5), A1
	MOVE.b	#FLAG_TRUE, obj_behavior_flag(A5)
	BSR.w	LoadNPCAnimFrame_Static
	MOVE.b	obj_npc_saved_dir(A5), obj_direction(A5)
	ADDQ.b	#1, obj_move_counter(A5)
	RTS

NPCInit_WalkingStatic:
	BSR.w	SetRandomDirection
	MOVE.l	#NPCTick_WalkingStatic, obj_tick_fn(A5)
	CLR.b	obj_behavior_flag(A5)
	RTS

NPCTick_WalkingStatic:
	BSR.w	ClearNPCFrozenState
	BSR.w	UpdateNPCMovement
	MOVEA.l	obj_anim_ptr(A5), A1
	BRA.w	LoadNPCAnimFrame_Static
NPCInit_WalkingStatic_LoadFrame:
	BSR.w	SetRandomDirection
	MOVE.l	#NPCBehavior_LoadFrame, obj_tick_fn(A5)
	RTS

; NPCBehavior_LoadFrame
; NPC behavior: Load animation frame and update state
NPCBehavior_LoadFrame:
	MOVEA.l	obj_anim_ptr(A5), A1
	MOVE.b	#FLAG_TRUE, obj_behavior_flag(A5)
	BSR.w	LoadNPCAnimationFrame
	MOVE.b	obj_npc_saved_dir(A5), obj_direction(A5)
	ADDQ.b	#1, obj_move_counter(A5)
	RTS

NPCInit_WalkingAnimated:
	BSR.w	SetRandomDirection
	MOVE.l	#NPCTick_WalkingAnimated, obj_tick_fn(A5)
	CLR.b	obj_behavior_flag(A5)
	RTS

NPCTick_WalkingAnimated:
	BSR.w	ClearNPCFrozenState
	BSR.w	UpdateNPCMovement
	MOVEA.l	obj_anim_ptr(A5), A1
	BRA.w	LoadNPCAnimationFrame
NPCInit_WalkingAnimated_Animate:
	MOVE.l	#NPCTick_AnimateEntity, obj_tick_fn(A5)
	RTS

NPCTick_AnimateEntity:
	MOVEA.l	obj_anim_ptr(A5), A1
	MOVE.b	#FLAG_TRUE, obj_behavior_flag(A5)
	BSR.w	AnimateEntitySprite
	ADDQ.b	#1, obj_move_counter(A5)
	RTS

NPCInit_ParmaFairy:
	TST.b	Blade_is_dead.w
	BEQ.b	NPCInit_ParmaFairy_Loop
	BCLR.b	#7, (A5)
	RTS

NPCInit_ParmaFairy_Loop:
	MOVE.l	#NPCTick_ParmaFairy, obj_tick_fn(A5)
	RTS

NPCTick_ParmaFairy:
	TST.b	Blade_is_dead.w
	BEQ.b	NPCTick_ParmaFairy_Loop
	MOVE.l	#NoAnswerStr, obj_npc_str_ptr(A5)
NPCTick_ParmaFairy_Loop:
	BRA.b	NPCTick_AnimateEntity
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

NPCTick_ParmaFindRing:   
	TST.b	Blade_is_dead.w
	BEQ.b	NPCTick_ParmaFindRing_Loop
	MOVE.l	#FindRingStr, obj_npc_str_ptr(A5)
NPCTick_ParmaFindRing_Loop:
	BRA.w	NPCBehavior_LoadFrame
NPCInit_Wyclif_UseMapHint1:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Wyclif_UseMapHint1, obj_tick_fn(A5)
	RTS

NPCTick_Wyclif_UseMapHint1:  
	TST.b	Rings_collected.w
	BNE.b	NPCTick_Wyclif_UseMapHint1_Loop
	MOVE.l	#UseMapStr, Pending_hint_text.w
	MOVE.w	#$0070, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Wyclif_UseMapHint1_Loop:
	BRA.w	UpdateNPCSpriteFrame
NPCInit_Wyclif_UseMapHint2Init:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Wyclif_UseMapHint2, obj_tick_fn(A5)
	RTS

NPCTick_Wyclif_UseMapHint2:
	TST.b	Rings_collected.w
	BEQ.b	NPCTick_Wyclif_UseMapHint2_Loop
	MOVE.l	#UseMapStr, Pending_hint_text.w
	MOVE.w	#$0051, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Wyclif_UseMapHint2_Loop:
	BRA.w	UpdateNPCSpriteFrame
NPCInit_Wyclif_UseMapHint2:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Wyclif_UseMapHint3, obj_tick_fn(A5)
	RTS

NPCTick_Wyclif_UseMapHint3:   
	MOVE.l	#UseMapStr, Pending_hint_text.w
	MOVE.w	#$0040, D5
	BSR.w	SetHintTextIfTriggered
	BRA.w	UpdateNPCSpriteFrame
NPCInit_Parma_AdviceHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Parma_AdviceHint, obj_tick_fn(A5)
	RTS

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

NPCTick_Parma_GotRingReaction:
	TST.b	Talked_to_real_king.w
	BEQ.b	NPCTick_Parma_GotRingReaction_Loop
	MOVE.l	#GotRingStr, obj_npc_str_ptr(A5)
NPCTick_Parma_GotRingReaction_Loop:
	BRA.w	UpdateNPCSpriteFrame
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

NPCTick_Watling_VerlinsCaveHint:       
	MOVE.l	#GoNorthVerlinsCaveStr, Pending_hint_text.w
	MOVE.w	#$36, D5
	BSR.w	SetHintTextIfTriggered
	BRA.w	UpdateNPCSpriteFrame
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

NPCTick_Watling_ThankYou:
	MOVE.l	#ThankYouStrangerStr, Pending_hint_text.w
	MOVE.w	#$65, D5
	BSR.w	SetHintTextIfTriggered
	BRA.w	UpdateNPCSpriteFrame
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
NPCInit_Deepdale_BremensCaveHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Deepdale_StowRoadWarning, obj_tick_fn(A5)
	RTS

NPCTick_Deepdale_StowRoadWarning:
	TST.b	Deepdale_king_secret_kept.w
	BEQ.b	NPCTick_Deepdale_StowRoadWarning_Loop
	MOVE.l	#RoadToStowDangerousStr, Pending_hint_text.w
	MOVE.w	#$7A, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Deepdale_StowRoadWarning_Loop:
	BRA.w	UpdateNPCSpriteFrame
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

NPCTick_Stow_ThiefAccuser2:
	TST.b	Accused_of_theft.w
	BEQ.b	NPCTick_Stow_ThiefAccuser2_Loop
	MOVE.l	#FaceOfCriminalStr, obj_npc_str_ptr(A5)
NPCTick_Stow_ThiefAccuser2_Loop:
	BRA.w	UpdateNPCSpriteFrame
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
NPCInit_Malaga_DungeonKeyGiver:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Keltwick_MalagaHint, obj_tick_fn(A5)
	RTS

NPCTick_Keltwick_MalagaHint:
	TST.b	Sent_to_malaga.w
	BEQ.b	NPCTick_Keltwick_MalagaHint_Loop
	MOVE.l	#MalagaNortheastStr, Pending_hint_text.w
	MOVE.w	#$003D, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Keltwick_MalagaHint_Loop:
	BRA.w	UpdateNPCSpriteFrame
NPCInit_Keltwick_MalagaHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Keltwick_BlazonsCaveHint, obj_tick_fn(A5)
	RTS

NPCTick_Keltwick_BlazonsCaveHint:
	TST.b	Sent_to_malaga.w
	BEQ.b	NPCTick_Keltwick_BlazonsCaveHint_Loop
	MOVE.l	#GoWestBlazonsCaveStr, Pending_hint_text.w
	MOVE.w	#$004C, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Keltwick_BlazonsCaveHint_Loop:
	BRA.w	UpdateNPCSpriteFrame
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
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Keltwick_WaitForPlayer, obj_tick_fn(A5)
	RTS

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
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Barrow_NortheastHint, obj_tick_fn(A5)
	RTS

NPCTick_Barrow_NortheastHint:
	TST.b	Barrow_map_received.w
	BEQ.b	NPCTick_Barrow_NortheastHint_Loop
	MOVE.l	#BarrowNortheastStr, Pending_hint_text.w
	MOVE.w	#$001D, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Barrow_NortheastHint_Loop:
	BRA.w	UpdateNPCSpriteFrame
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Barrow_map_received.w
	BEQ.b	NPCTick_Barrow_NortheastHint_Loop2
	BCLR.b	#7, (A5)	
NPCTick_Barrow_NortheastHint_Loop2:
	MOVE.l	#NPCTick_Barrow_QuestGuard, obj_tick_fn(A5)
	RTS

NPCTick_Barrow_QuestGuard:
	TST.b	Barrow_quest_1_complete.w
	BEQ.b	NPCTick_Barrow_BearwulfDone
	TST.b	Barrow_quest_2_complete.w
	BEQ.b	NPCTick_Barrow_BearwulfDone
	BCLR.b	#7, (A5)
NPCTick_Barrow_BearwulfDone:
	BRA.w	UpdateNPCSpriteFrame
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Barrow_BearwulfQuest, obj_tick_fn(A5)
	RTS

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
NPCInit_Barrow_BearwulfQuest:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Barrow_TadcasterHint, obj_tick_fn(A5)
	RTS

NPCTick_Barrow_TadcasterHint:
	MOVE.l	#ReachTadcasterStr, Pending_hint_text.w
	MOVE.w	#$000A, D5
	BSR.w	SetHintTextIfTriggered
	BRA.w	UpdateNPCSpriteFrame
NPCInit_Barrow_TadcasterHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Tadcaster_TreasureQuest, obj_tick_fn(A5)
	RTS

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
NPCInit_Tadcaster_PassSeller:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Tadcaster_ImposterHint, obj_tick_fn(A5)
	RTS

NPCTick_Tadcaster_ImposterHint:
	TST.b	Imposter_killed.w
	BNE.b	NPCTick_Tadcaster_ImposterHint_Loop
	MOVE.l	#ImposterDarmonsCaveConfirmedStr, Pending_hint_text.w
	MOVE.w	#8, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Tadcaster_ImposterHint_Loop:
	BRA.w	UpdateNPCSpriteFrame
NPCInit_Tadcaster_ImposterHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Tadcaster_HelwigHint, obj_tick_fn(A5)
	RTS

NPCTick_Tadcaster_HelwigHint:
	TST.b	Imposter_killed.w
	BEQ.b	NPCTick_Tadcaster_HelwigHint_Loop
	MOVE.l	#ReachHelwigStr, Pending_hint_text.w
	MOVE.w	#$0017, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Tadcaster_HelwigHint_Loop:
	BRA.w	UpdateNPCSpriteFrame
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

NPCInit_Helwig_Generic:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Helwig_CountOnYouHint, obj_tick_fn(A5)
	RTS

NPCTick_Helwig_CountOnYouHint:
	TST.b	Helwig_men_rescued.w
	BNE.b	NPCTick_Helwig_CountOnYouHint_Loop
	MOVE.l	#CountOnYouStr, Pending_hint_text.w
	MOVE.w	#$14, D5
	BSR.w	SetHintTextIfTriggered
NPCTick_Helwig_CountOnYouHint_Loop:
	BRA.w	UpdateNPCSpriteFrame
NPCInit_Helwig_CountOnYouHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Helwig_SwaffhamHint, obj_tick_fn(A5)
	RTS

NPCTick_Helwig_SwaffhamHint:
	MOVE.l	#JourneyWestToSwaffhamStr, Pending_hint_text.w
	MOVE.w	#3, D5
	BSR.w	SetHintTextIfTriggered
	BRA.w	UpdateNPCSpriteFrame
NPCInit_Helwig_SwaffhamHint:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Helwig_men_rescued.w
	BNE.b	NPCInit_Helwig_SwaffhamHint_Loop
	BCLR.b	#7, (A5)
NPCInit_Helwig_SwaffhamHint_Loop:
	MOVE.l	#UpdateNPCSpriteFrame, obj_tick_fn(A5)
	RTS

NPCInit_Helwig_RescuedVillager:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Helwig_men_rescued.w
	BNE.b	NPCInit_Helwig_RescuedVillager_Loop
	BCLR.b	#7, (A5)
NPCInit_Helwig_RescuedVillager_Loop:
	MOVE.l	#NPCTick_WalkingStatic, obj_tick_fn(A5)
	RTS

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
NPCInit_Helwig_SecretKeyGiver:
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	TST.b	Helwig_old_woman_quest_started.w
	BEQ.b	NPCInit_Helwig_SecretKeyGiver_Loop
	MOVE.l	#FoundSomeoneForMeStr, obj_npc_str_ptr(A5)
NPCInit_Helwig_SecretKeyGiver_Loop:
	MOVE.l	#NPCTick_Helwig_OldWomanQuest, obj_tick_fn(A5)
	RTS

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
NPCInit_Helwig_OldWomanQuest:
	MOVE.b	#SPRITE_SIZE_2x3, obj_sprite_size(A5)
	MOVE.l	#NPCTick_Swaffham_KnuteNoAnswer, obj_tick_fn(A5)
	RTS

NPCTick_Swaffham_KnuteNoAnswer:
	TST.b	Knute_informed_of_swaffham_ruin.w
	BEQ.b	NPCTick_Swaffham_KnuteNoAnswer_Loop
	MOVE.l	#NoAnswerStr, obj_npc_str_ptr(A5)
NPCTick_Swaffham_KnuteNoAnswer_Loop:
	BRA.w	UpdateNPCScreenPosition
	BSR.w	SetRandomDirection
	CLR.b	obj_behavior_flag(A5)
	MOVE.l	#NPCTick_Excalabria_CrystalExchange, obj_tick_fn(A5)
	RTS

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

NPCTick_Excalabria_SwaffhamRuinWait:
	TST.b	Swaffham_ruined.w
	BEQ.b	NPCTick_Excalabria_SwaffhamRuinWait_Loop
	CLR.b	Carthahena_soldier_1_defeated.w
	MOVE.l	#WaitingExcalabriaStr, obj_npc_str_ptr(A5)
NPCTick_Excalabria_SwaffhamRuinWait_Loop:
	BRA.w	NPCBehavior_LoadFrame
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
NPCInit_Helwig_InnFryingPan:
	BSR.w	SetRandomDirection
	MOVE.l	#NPCTick_Helwig_InnFryingPan, obj_tick_fn(A5)
	RTS

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

NPCInit_Parma_CastleSoldier:
	MOVE.b	#DIRECTION_DOWN, obj_direction(A5)
	MOVE.b	#4, obj_npc_saved_dir(A5)
	MOVE.l	#NPCTick_Parma_CastleSoldierStatic, obj_tick_fn(A5)
	RTS

NPCTick_Parma_CastleSoldierStatic:
	BRA.w	NPCBehavior_LoadFrame
NPCInit_Parma_CastleSoldierFaceDown:
	MOVE.b	#2, obj_hp(A5)
	MOVE.b	#6, soldier_patrol_state(A5)
	BRA.w	NPCInit_Parma_CastleSoldierFaceRight_Loop
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

AddItemToInventoryList:
	LEA	Possessed_items_length.w, A0
	MOVE.w	(A0), D0
	ADDQ.w	#1, (A0)+
	ADD.w	D0, D0
	RTS

CheckInventoryFull:
	LEA	Possessed_items_length.w, A0
	MOVE.w	(A0), D0
	CMPI.w	#8, D0
	RTS

SetHintTextIfTriggered:
	LEA	Map_trigger_flags.w, A0
	TST.b	(A0,D5.w)
	BEQ.b	SetHintTextIfTriggered_Loop
	MOVE.l	Pending_hint_text.w, obj_npc_str_ptr(A5)
SetHintTextIfTriggered_Loop:
	RTS

ClearNPCFrozenState:
	TST.b	Player_input_blocked.w
	BNE.b	ClearNPCFrozenState_Loop
	CLR.b	obj_vel_x(A5)
ClearNPCFrozenState_Loop:
	RTS

NPCCollisionOffsetTable:
	dc.w	 0, -2,  0, -1, -1, -1,  1, -1, -1,  0,  1,  0, -1,  1,  0,  1
	dc.w	 1,  1,  0,  2, -2,  0, -1,  0, -1, -1, -1,  1,  0,  1,  0, -1 
	dc.w	 1,  1,  1,  0,  1, -1,  2,  0,  0,  2,  0,  1, -1,  1,  1,  1
	dc.w	-1, -1, -1,  0,  0, -1,  1, -1,  1,  0,  0, -2,  2,  0,  1,  0 
	dc.w	 1, -1,  1,  1, -1, -1, -1,  0, -1,  1,  0, -1,  0,  1, -2,  0
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

MapIndicatorTileIDs:
	dc.w	$04D5 
	dc.w	$04D3 
	dc.w	$04D7 
	dc.w	$04D1 

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

PortraitInit_Simple:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	RTS

PortraitInit_MapGiver:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_MapGiver, obj_tick_fn(A5)
	BSR.w	SetObjectActiveFlag
	MOVE.l	#PortraitTick_MapGiver, obj_tick_fn(A4)
	RTS

PortraitInit_StowGirl:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_StowGirl, obj_tick_fn(A5)
	BSR.w	SetObjectActiveFlag
	MOVE.l	#PortraitTick_StowGirl, obj_tick_fn(A4)
	RTS

PortraitInit_RingOfWisdom:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_RingOfWisdom, obj_tick_fn(A5)
	RTS

PortraitInit_ImposterGuard:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_ImposterGuard, obj_tick_fn(A5)
	RTS

PortraitInit_MalagaPrisoner:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_MalagaPrisoner, obj_tick_fn(A5)
	RTS

PortraitInit_TsarkonFinal:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_TsarkonFinal, obj_tick_fn(A5)
	BSR.w	SetObjectActiveFlag
	MOVE.l	#PortraitTick_TsarkonFinal, obj_tick_fn(A4)
	RTS

PortraitInit_Bearwulf:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_Bearwulf, obj_tick_fn(A5)
	BSR.w	SetObjectActiveFlag
	MOVE.l	#PortraitTick_Bearwulf, obj_tick_fn(A4)
	RTS

PortraitInit_TruffleGiver:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_Truffle, obj_tick_fn(A5)
	BSR.w	SetObjectActiveFlag
	MOVE.l	#PortraitTick_Truffle, obj_tick_fn(A4)
	RTS

PortraitInit_DigotGiver:
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	BSR.w	InitTalkerPortraitSprite
	MOVE.l	#PortraitTick_Digot, obj_tick_fn(A5)
	BSR.w	SetObjectActiveFlag
	MOVE.l	#PortraitTick_Digot, obj_tick_fn(A4)
	RTS

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

PortraitIdleLoop:
	JMP	QueueSpriteOAMIfVisible
PortraitTick_RingOfWisdom:
	TST.b	Rings_collected.w
	BEQ.b	PortraitTick_RingOfWisdom_Loop
	MOVE.l	#OnlyYouCanSaveUsStr, Script_talk_source.w
PortraitTick_RingOfWisdom_Loop:
	JMP	QueueSpriteOAMIfVisible
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
PortraitTick_ImposterGuard:
	TST.b	Imposter_boss_trigger.w
	BEQ.b	PortraitTick_ImposterGuard_Loop
	MOVE.l	#NoOneHereStr, Script_talk_source.w
PortraitTick_ImposterGuard_Loop:
	JMP	QueueSpriteOAMIfVisible
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
PortraitTick_TsarkonFinal:
	TST.b	Tsarkon_is_dead.w
	BEQ.b	PortraitTick_TsarkonFinal_Loop
	MOVE.l	#EvilDiedWithTsarkonStr, Script_talk_source.w
	BCLR.b	#7, (A5)
	CLR.b	Talker_present_flag.w
	RTS

PortraitTick_TsarkonFinal_Loop:
	JMP	QueueSpriteOAMIfVisible
PortraitTick_Bearwulf:
	LEA	Bearwulf_met.w, A0
	BRA.w	PortraitTick_CheckCollectedFlag
PortraitTick_Truffle:
	LEA	Truffle_collected.w, A0
	BRA.w	PortraitTick_CheckCollectedFlag
PortraitTick_Digot:
	LEA	Digot_plant_received.w, A0
	BRA.w	PortraitTick_CheckCollectedFlag
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
PortraitTick_CheckCollectedFlag:
	TST.b	(A0)
	BEQ.b	PortraitTick_CheckCollectedFlag_Loop
	MOVE.l	#NoOneHereStr, Script_talk_source.w
	BCLR.b	#7, (A5)
	CLR.b	Talker_present_flag.w
	RTS

PortraitTick_CheckCollectedFlag_Loop:
	JMP	QueueSpriteOAMIfVisible
PortraitPositionOffsets:
	dc.w	-16, -48, 16, -48 
	dc.w	-16, -24, 16, -24
	dc.w	-16, 0, 16, 0 

SetObjectActiveFlag:
	MOVE.b	obj_next_offset(A5), D0
	LEA	(A5,D0.w), A4
	BSET.b	#7, (A4)
	RTS

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

