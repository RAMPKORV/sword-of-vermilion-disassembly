; ======================================================================
; src/battle_gfx.asm
; Battle graphics loading, DMA, tile decompression
;
; NOTE — misplaced general-purpose utilities (see MOVE-001, MOVE-004):
;   GetRandomNumber   (line ~605) — LCG RNG; used by 59 call sites across
;                                   enemy.asm, combat.asm, boss.asm, etc.
;                                   Logically belongs in a math/util module.
;   QueueSoundEffect  (line ~1482) — sound queue push; used by 14 call sites
;                                   across gameplay.asm, items.asm, boss.asm,
;                                   player.asm, etc.
;                                   Logically belongs in sound.asm.
;   Both functions cannot be physically moved without breaking bit-perfect
;   output (absolute addresses change).  Annotated in place.
; ======================================================================

; ---------------------------------------------------------------------------
; WriteDirectionTilesForBoss — write 6 direction-tile rows to VDP VRAM
;
; Looks up a tile source pointer from BossDirectionTilePtrs using D0 as a
; word index (0-3), then writes 6 rows of 5 tiles each to VRAM starting at
; address $40080003 (plane A row), advancing the destination by $80 per row.
; Each source byte is offset by $A200 to form the tile attribute word.
;
; Input:
;   D0.w  direction index (0-3); word index into BossDirectionTilePtrs
;
; Scratch:  D0, D4-D7, A0
; Output:   6 × 5 tile words written to VDP nametable
; ---------------------------------------------------------------------------
WriteDirectionTilesForBoss:
	ORI	#$0700, SR
	LEA	BossDirectionTilePtrs, A0
	MOVEA.l	(A0,D0.w), A0
	MOVE.l	#$40080003, D5
	MOVE.w	#5, D7
WriteDirectionTilesForBoss_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#4, D6
WriteDirectionTilesForBoss_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$A200, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, WriteDirectionTilesForBoss_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, WriteDirectionTilesForBoss_Done
	ANDI	#$F8FF, SR
	RTS
	
; ---------------------------------------------------------------------------
; CalculateDirectionToEntity — compute facing direction from A5 toward A6
; CalculateDirectionToPlayer — compute facing direction from A5 toward player
;
; Both functions compute an 8-directional facing value and store it in
; obj_direction(A5), then step it one increment toward the desired angle
; (clamped rotation, not snap).  They share GetDirectionFromDeltas.
;
; CalculateDirectionToEntity uses the world positions of the objects
; at A5 and A6.  CalculateDirectionToPlayer loads the player entity
; pointer and offsets by ($18, $58) to account for sprite origin.
;
; Input:
;   A5    entity whose direction field is being updated
;   A6    (CalculateDirectionToEntity only) target entity
;
; Scratch:  D0-D4, A1, A6 (CalculateDirectionToPlayer clobbers A6)
; Output:   obj_direction(A5) incremented one step toward target
; ---------------------------------------------------------------------------
CalculateDirectionToEntity:
	LEA	DirectionToEntityLookup, A1
	MOVE.w	obj_world_x(A6), D0
	SUB.w	obj_world_x(A5), D0
	MOVE.w	obj_world_y(A6), D1
	SUB.w	obj_world_y(A5), D1
	BRA.w	GetDirectionFromDeltas
CalculateDirectionToPlayer:
	LEA	DirectionToPlayerLookup, A1
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.w	obj_world_x(A6), D0
	MOVE.w	obj_world_x(A5), D1
	ADDI.w	#$0018, D1
	SUB.w	D1, D0
	MOVE.w	obj_world_y(A6), D1
	MOVE.w	obj_world_y(A5), D2
	ADDI.w	#$0058, D2
	SUB.w	D2, D1
GetDirectionFromDeltas:
	CLR.w	D2
	TST.w	D0
	BGE.b	GetDirectionFromDeltas_Loop
	NEG.w	D0
	MOVE.w	#8, D2
GetDirectionFromDeltas_Loop:
	TST.w	D1
	BGE.b	GetDirectionFromDeltas_Loop2
	NEG.w	D1
	ORI.w	#4, D2
GetDirectionFromDeltas_Loop2:
	CMP.w	D1, D0
	BGE.b	GetDirectionFromDeltas_Loop3
	ORI.w	#2, D2
	ASR.w	#1, D1
	BGE.b	GetDirectionFromDeltas_Loop4
GetDirectionFromDeltas_Loop3:
	ASR.w	#1, D0
GetDirectionFromDeltas_Loop4:
	CMP.w	D1, D0
	BGE.b	GetDirectionFromDeltas_Loop5
	ORI.w	#1, D2
GetDirectionFromDeltas_Loop5:
	ADDA.w	D2, A1
	CLR.w	D0
	MOVE.b	(A1), D0
	CLR.w	D2
	MOVE.b	obj_direction(A5), D2
	MOVE.w	D2, D3
	SUB.w	D0, D3
	BNE.b	GetDirectionFromDeltas_Loop6
	MOVE.b	D0, obj_direction(A5)
	BRA.w	BossBody_AngleReturn
GetDirectionFromDeltas_Loop6:
	BGT.w	GetDirectionFromDeltas_Loop7
	NEG.w	D3
	MOVE.w	#$0100, D4
	SUB.w	D0, D4
	ADD.w	D2, D4
	CMP.w	D3, D4
	BLE.w	BossBody_AngleDecrease
	BRA.w	GetDirectionFromDeltas_Loop8
GetDirectionFromDeltas_Loop7:
	MOVE.w	#$0100, D4
	SUB.w	D2, D4
	ADD.w	D0, D4
	CMP.w	D3, D4
	BGE.w	BossBody_AngleDecrease
GetDirectionFromDeltas_Loop8:
	ADDQ.b	#1, obj_direction(A5)
	BRA.w	BossBody_AngleReturn
BossBody_AngleDecrease:
	SUBQ.b	#1, obj_direction(A5)
BossBody_AngleReturn:
	RTS
	
BossBodyUpperTilePtrs:
	dc.l	BossBodyUpperTilePtrs_Entry00
	dc.l	SpriteMetaTileTable_780F4
	dc.l	BossBodyUpperTilePtrs_Entry01
	dc.l	SpriteMetaTileTable_780F4
BossBodyLowerTilePtrs:
	dc.l	BossBodyLowerTilePtrs_Entry00
	dc.l	SpriteMetaTileTable_78120
	dc.l	BossBodyLowerTilePtrs_Entry01
	dc.l	SpriteMetaTileTable_78120
BossDirectionTilePtrs:
	dc.l	SpriteMetaTileTable_7808A
	dc.l	BossDirectionTilePtrs_Entry00
	dc.l	SpriteMetaTileTable_780C6
	dc.l	SpriteMetaTileTable_780C6	
; ---------------------------------------------------------------------------
; WriteTilesToVRAM — write one sprite tile set from BossTileSourceTable to VDP
;
; Selects a record from BossTileSourceTable using D0 as an entry index (each
; entry is 12 bytes: source ptr, col-count word, row-count word, VDP address
; long).  Writes col × row tiles to VDP nametable with interrupts masked.
;
; Input:
;   D0.w  entry index into BossTileSourceTable
;
; Scratch:  D0, D4-D7, A0, A1
; Output:   tiles written to VDP; interrupts restored via SR
; ---------------------------------------------------------------------------
WriteTilesToVRAM:
	LEA	BossTileSourceTable, A0
	MOVE.w	D0, D1
	ADD.w	D1, D1
	ADD.w	D1, D1
	ASL.w	#3, D0
	ADD.w	D1, D0
	LEA	(A0,D0.w), A0
	MOVEA.l	(A0)+, A1
	MOVE.w	(A0)+, D6
	MOVE.w	(A0)+, D7
	MOVE.l	(A0)+, D5
	ORI	#$0700, SR
WriteTilesToVRAM_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	D6, D4
WriteTilesToVRAM_Done2:
	CLR.w	D0
	MOVE.b	(A1)+, D0
	ADDI.w	#$2200, D0
	MOVE.w	D0, VDP_data_port
	DBF	D4, WriteTilesToVRAM_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, WriteTilesToVRAM_Done
	ANDI	#$F8FF, SR
	RTS
	
DirectionToPlayerLookup:
	dc.b	$C0, $A0, $A0, $80, $C0, $E0, $E0, $00, $40 
	dc.b	$60
	dc.b	$60
	dc.b	$80
	dc.b	$40, $20, $20, $00 
DirectionToEntityLookup:
	dc.b	$40, $60, $60, $00, $40, $60, $60 
	dc.b	$80
	dc.b	$C0
	dc.b	$E0
	dc.b	$E0, $00, $C0, $A0, $A0, $80 
; ---------------------------------------------------------------------------
; AddSpriteToDisplayList — add a sprite to the priority-sort display list
;
; Checks whether the sprite at A5 is on-screen, computes its priority slot
; from obj_sort_key, and inserts it into the priority bucket structure at
; Sprite_priority_slots.  Each bucket is 16 bytes; up to 15 sprites per
; bucket (the counter byte is $0F when full).
;
; Input:
;   A5    object data pointer (obj_screen_x, obj_screen_y, obj_sprite_size,
;         obj_sprite_flags, obj_tile_index, obj_sort_key)
;
; Scratch:  D0-D7, A0
; Output:   sprite added to sort buffer; Sprite_attr_count incremented
; ---------------------------------------------------------------------------
AddSpriteToDisplayList:
	ORI	#$0700, SR
	MOVE.w	obj_screen_y(A5), D5
	BLE.w	AddSpriteToDisplayList_Return
	MOVE.b	obj_sprite_size(A5), D0
	MOVE.b	D0, D1
	ANDI.w	#3, D0
	ADDQ.w	#1, D0
	ASL.w	#3, D0
	SUB.w	D0, D5
	CMPI.w	#$00E0, D5
	BGE.w	AddSpriteToDisplayList_Return
	ANDI.w	#$000C, D1
	ADDQ.w	#4, D1
	MOVE.w	obj_screen_x(A5), D6
	MOVE.w	D6, D4
	ADD.w	D1, D4
	BLE.w	AddSpriteToDisplayList_Return
	SUB.w	D1, D6
	CMPI.w	#BATTLE_FIELD_WIDTH, D6
	BGE.w	AddSpriteToDisplayList_Return
	LEA	Sprite_sort_buffer.w, A0
	MOVE.w	Sprite_attr_count.w, D0
	ASL.w	#3, D0
	ADDA.w	D0, A0
	ADDI.w	#$0080, D5
	ADDI.w	#$0080, D6
	MOVE.w	D5, (A0)+
	MOVE.b	obj_sprite_size(A5), D0
	ASL.w	#8, D0
	ANDI.w	#$0F00, D0
	MOVE.w	D0, (A0)+
	MOVE.b	obj_sprite_flags(A5), D0
	ASL.w	#8, D0
	MOVE.w	obj_tile_index(A5), D1
	ADD.w	D1, D0
	MOVE.w	D0, (A0)+
	MOVE.w	D6, (A0)
	LEA	Sprite_priority_slots.w, A0
	MOVE.w	obj_sort_key(A5), D0
	ANDI.w	#$00FF, D0
	MOVE.w	#$00FF, D7
	SUB.w	D0, D7
	ASL.w	#4, D7
	ADDA.w	D7, A0
AddSpriteToDisplayList_Done:
	CMPI.b	#$0F, (A0)
	BLT.b	AddSpriteToDisplayList_Loop
	LEA	$10(A0), A0
	DBF	D0, AddSpriteToDisplayList_Done
	BRA.b	AddSpriteToDisplayList_Return	
AddSpriteToDisplayList_Loop:
	ADDQ.b	#1, (A0)
	MOVE.b	(A0), D0
	ANDI.w	#$000F, D0
	MOVE.w	Sprite_attr_count.w, D1
	MOVE.b	D1, (A0,D0.w)
	ADDQ.w	#1, Sprite_attr_count.w
AddSpriteToDisplayList_Return:
	ANDI	#$F8FF, SR
	RTS
	
; ---------------------------------------------------------------------------
; FlushSpriteAttributesToVDP — write sprite attribute table to VDP
;
; Writes all queued sprite OAM entries (Sprite_attr_buffer) to the VDP
; sprite attribute table at VRAM $7800.  Terminates the list with a
; zero-filled entry (Y=0 terminates the VDP sprite chain).
;
; Input:   (none)  — reads Sprite_attr_count.w and Sprite_attr_buffer.w
; Scratch:  D0, A2
; Output:   VDP sprite attribute table updated
; ---------------------------------------------------------------------------
FlushSpriteAttributesToVDP:
	MOVE.l	#VDP_CMD_VRAM_WRITE_SAT, VDP_control_port
	MOVE.w	Sprite_attr_count.w, D0
	SUBQ.w	#1, D0
	BLT.b	FlushSpriteAttributesToVDP_Loop
	LEA	Sprite_attr_buffer.w, A2
FlushSpriteAttributesToVDP_Done:
	MOVE.w	(A2)+, VDP_data_port
	MOVE.w	(A2)+, VDP_data_port
	MOVE.w	(A2)+, VDP_data_port
	MOVE.w	(A2)+, VDP_data_port
	DBF	D0, FlushSpriteAttributesToVDP_Done
FlushSpriteAttributesToVDP_Loop:
	MOVE.w	#0, VDP_data_port
	MOVE.w	#0, VDP_data_port
	MOVE.w	#0, VDP_data_port
	MOVE.w	#0, VDP_data_port
	RTS
	
; ---------------------------------------------------------------------------
; QueueSpriteOAMIfVisible — build one OAM entry in Sprite_attr_buffer
;
; Checks if the sprite at A5 is on-screen, then writes a single 8-byte OAM
; entry (Y, size/link, tile attributes, X) directly into Sprite_attr_buffer
; at the slot indexed by Sprite_attr_count, then increments the count.
; Unlike AddSpriteToDisplayList this function bypasses the priority sort.
;
; Input:
;   A5    object data pointer
;
; Scratch:  D0-D4, A0
; Output:   OAM entry appended; Sprite_attr_count incremented
; ---------------------------------------------------------------------------
QueueSpriteOAMIfVisible:
	LEA	Sprite_attr_buffer.w, A0
	MOVE.w	Sprite_attr_count.w, D0
	MOVE.w	D0, D4
	ADDQ.w	#1, D4
	ASL.w	#3, D0
	LEA	(A0,D0.w), A0
	MOVE.w	obj_screen_y(A5), D3
	BLE.w	QueueSpriteOAM_Return
	MOVE.b	obj_sprite_size(A5), D1
	MOVE.b	D1, D0
	ANDI.w	#$000C, D0
	ANDI.w	#3, D1
	ADDQ.w	#1, D1
	ADDQ.w	#4, D0
	ASL.w	#3, D1
	SUB.w	D1, D3
	CMPI.w	#$00E0, D3
	BGE.w	QueueSpriteOAM_Return
	MOVE.w	obj_screen_x(A5), D1
	MOVE.w	D1, D2
	ADD.w	D0, D2
	BLE.w	QueueSpriteOAM_Return
	SUB.w	D0, D1
	CMPI.w	#BATTLE_FIELD_WIDTH, D1
	BGE.w	QueueSpriteOAM_Return
	ADDI.w	#$0080, D3
	ADDI.w	#$0080, D1
	MOVE.w	D3, (A0)
	MOVE.w	D1, $6(A0)
	MOVE.b	obj_sprite_size(A5), D0
	ASL.w	#8, D0
	ANDI.w	#$0F00, D0
	ADD.w	D4, D0
	MOVE.w	D0, $2(A0)
	MOVE.b	obj_sprite_flags(A5), D0
	ASL.w	#8, D0
	MOVE.w	obj_tile_index(A5), D1
	ADD.w	D1, D0
	MOVE.w	D0, $4(A0)
	ADDQ.w	#1, Sprite_attr_count.w
QueueSpriteOAM_Return:
	RTS
	
; ---------------------------------------------------------------------------
; SortAndUploadSpriteOAM — sort priority buckets and build final OAM list
;
; Iterates all 256 priority buckets in Sprite_priority_slots (16 bytes each,
; up to 15 sprite indices per bucket).  For each occupied bucket, copies the
; corresponding OAM records from the unsorted Sprite_attr_buffer into the
; final build buffer (Sprite_sort_temp_buffer) in priority order, patching
; the link chain as it goes.  Interrupts are masked during the operation.
;
; Input:   (none) — reads Sprite_priority_slots and Sprite_attr_buffer
; Scratch:  D0-D7, A0-A4
; Output:   Sprite_sort_temp_buffer populated with sorted, linked OAM
; ---------------------------------------------------------------------------
SortAndUploadSpriteOAM:
	ORI	#$0700, SR
	TST.w	Sprite_attr_count.w
	BLE.w	QueueSpriteOAM_Return_Loop
	LEA	Sprite_sort_temp_buffer.w, A1
	LEA	Sprite_attr_buffer.w, A4
	LEA	Sprite_sort_buffer.w, A2
	CLR.w	D1
	MOVE.w	#$0010, D5
	MOVE.w	#$00FF, D0
QueueSpriteOAM_Return_Done:
	ADDA.w	D5, A1
	TST.b	(A1)
	BEQ.w	QueueSpriteOAM_Return_Loop2
	CLR.w	D6
	MOVE.b	(A1), D6
	ANDI.w	#$000F, D6
	SUBQ.w	#1, D6
	BLT.w	QueueSpriteOAM_Return_Loop3
QueueSpriteOAM_Return_Done2:
	MOVE.b	$1(A1,D6.w), D4
	ANDI.w	#$007F, D4
	ASL.w	#3, D4
	LEA	(A2,D4.w), A3
	MOVE.w	(A3)+, (A4)+
	MOVE.w	(A3)+, D2
	ADDQ.w	#1, D1
	ADD.w	D1, D2
	MOVE.w	D2, (A4)+
	MOVE.w	(A3)+, (A4)+
	MOVE.w	(A3), (A4)+
	DBF	D6, QueueSpriteOAM_Return_Done2
	CLR.b	(A1)
QueueSpriteOAM_Return_Loop2:
	DBF	D0, QueueSpriteOAM_Return_Done
QueueSpriteOAM_Return_Loop:
	ANDI	#$F8FF, SR
	RTS
	
QueueSpriteOAM_Return_Loop3:
	RTE	
; ---------------------------------------------------------------------------
; SortAndUploadSpriteOAM_Alt — clear all priority-bucket slot counters
;
; Clears the first byte of all 32 priority buckets in Sprite_priority_slots.
; Each bucket is 16 bytes; this loop steps through 32 × 8 = 256 buckets via
; DBF, clearing the count byte of each.  Called at the start of each frame
; to reset the sort list before any new sprites are added.
;
; Input:   (none)
; Scratch:  D7, A0
; Output:   Sprite_priority_slots count bytes all zeroed
; ---------------------------------------------------------------------------
SortAndUploadSpriteOAM_Alt:
	MOVE.w	#$001F, D7
	LEA	Sprite_priority_slots.w, A0
QueueSpriteOAM_Return_Loop3_Done:
	CLR.b	(A0)
	LEA	$10(A0), A0
	CLR.b	(A0)
	LEA	$10(A0), A0
	CLR.b	(A0)
	LEA	$10(A0), A0
	CLR.b	(A0)
	LEA	$10(A0), A0
	CLR.b	(A0)
	LEA	$10(A0), A0
	CLR.b	(A0)
	LEA	$10(A0), A0
	CLR.b	(A0)
	LEA	$10(A0), A0
	CLR.b	(A0)
	LEA	$10(A0), A0
	DBF	D7, QueueSpriteOAM_Return_Loop3_Done
	ANDI	#$F8FF, SR
	RTS
	
; ---------------------------------------------------------------------------
; LoadEncounterGraphics — load all tile sets for a random encounter battle
;
; Loads four GFX groups:
;   1. EncounterTileData_Entry     — base encounter tiles (player + HUD)
;   2. GfxLoadList_OverworldBattle — overworld battle background tiles
;   3. EnemyGfxDataTable           — enemy sprite tiles (front + back banks)
;   4. Optional 3rd enemy tile set (if source pointer is non-null)
; Each group is decompressed into Tile_gfx_buffer and DMA'd to VRAM.
;
; Input:   (via RAM)  Current_encounter_type.w
; Scratch:  D0, D5, A2, A3, A4, A6
; Output:   VRAM loaded with encounter tile sets
;
; ---------------------------------------------------------------------------
; RAND-006: Enemy Graphics Swapping — Feasibility Analysis
; ---------------------------------------------------------------------------
; Enemy graphics are stored in 13 EnemySpriteSet groups (A–M), each a list
; of 10-byte records (4-byte frame table ptr + 4-byte GFX data ptr + 1-byte
; $00 + 1-byte tile_count), terminated by a NULL_PTR ($00000000).
; Most groups have 2 records; sets H, I, L, M have a 3rd record for ALT tiles.
;
; VRAM slots used during battles (see DMA_SLOT_* in constants.asm):
;   DMA_SLOT_ENEMY_FRONT = $0035  →  VRAM $3640  (96 tiles = 3072 bytes)
;   DMA_SLOT_ENEMY_BACK  = $0036  →  VRAM $0640  (96 tiles = 3072 bytes)
;   DMA_SLOT_ENEMY_ALT   = $003C  →  VRAM $6640  (80 tiles = 2560 bytes)
;   DMA_SLOT_MAGIC_SPELL = $0043  →  VRAM $9140  (93 tiles = 2976 bytes)
;
; Tile-count values seen in sprite sets (byte at record+$09):
;   $6B = 107,  $77 = 119,  $4F = 79,  $47 = 71,  $3B = 59,
;   $2F = 47,   $27 = 39,   $05 = 5
; All observed counts fit within their respective DMA slot maximums.
;
; Palette assignment:
;   Each enemy's palette lines are encoded in EnemyAppearance_* at offset
;   +$14 (eagfx_vfx): packed $PPQQSSTT — PP/QQ = palette hi/lo indices,
;   SS = sprite size code, TT = tile ID / palette bank.
;   Standard overworld enemies: PP=$0D, QQ=$0E (shared palette lines).
;   Boss-exclusive enemies:     PP=$0F, QQ=$00 (dedicated boss palette).
;
; Randomizer swapping rules:
;   SAFE (unconditional):
;     — Two enemies sharing the same EnemySpriteSet_* label can always swap;
;       tile counts, VRAM slots, and record counts are identical.
;
;   SAFE (conditional — same tile-count tier):
;     — Enemies from different sets but with matching tile counts per record
;       can swap if both use the same number of records (both 2-record or
;       both 3-record). Tile data will fill the slot exactly.
;
;   UNSAFE — mismatched record count (2-record vs 3-record sets):
;     — Swapping a 2-record enemy (no ALT) into a 3-record slot (or vice
;       versa) leaves the ALT VRAM region stale or unloaded. If the game
;       reads the ALT slot for that enemy type the display will corrupt.
;     — Sets with 3 records: H, I, L, M.
;
;   UNSAFE — mismatched tile count across records:
;     — If the replacement enemy's record has a larger tile_count than the
;       slot maximum, tiles will overflow into adjacent VRAM regions.
;     — If smaller, the upper portion of the slot retains stale tiles from
;       the previous battle; visible corruption may or may not occur.
;
;   UNSAFE — incompatible palette:
;     — Swapping a boss-palette enemy ($0F/$00) into a standard slot will
;       render with wrong colours unless the palette is also patched.
;       Swapping two standard-palette enemies ($0D/$0E) is always safe.
;
; Recommended swap groupings for a randomizer:
;   Group 1 — same EnemySpriteSet label          : free swap, zero risk
;   Group 2 — same tile-count tier, same rec count: swap with palette check
;   Group 3 — boss enemies (3-record or $0F pal) : swap only within group
; ---------------------------------------------------------------------------
LoadEncounterGraphics:
	LEA	EncounterTileData_Entry-2, A6
	MOVE.w	(A6)+, Vdp_dma_slot_index.w
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A6)+, A4
	MOVEA.l	(A6)+, A3
	MOVE.w	(A6)+, D5
	BSR.w	LoadMultipleTilesFromTable
	BSR.w	ExecuteVdpDmaTransfer
	LEA	GfxLoadList_OverworldBattle-2, A6
	MOVE.w	(A6)+, Vdp_dma_slot_index.w
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A6)+, A4
	MOVEA.l	(A6)+, A3
	MOVE.w	(A6)+, D5
	BSR.w	LoadMultipleTilesFromTable
	BSR.w	ExecuteVdpDmaTransfer
	LEA	EnemyGfxDataTable, A6
	MOVE.w	Current_encounter_type.w, D0
	MULU.w	#$000C, D0
	ADDQ.w	#8, D0
	MOVEA.l	(A6,D0.w), A6
	MOVE.w	#DMA_SLOT_ENEMY_FRONT, Vdp_dma_slot_index.w
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A6)+, A4
	MOVEA.l	(A6)+, A3
	MOVE.w	(A6)+, D5
	BSR.w	LoadMultipleTilesFromTable
	BSR.w	ExecuteVdpDmaTransfer
	MOVE.w	#DMA_SLOT_ENEMY_BACK, Vdp_dma_slot_index.w
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A6)+, A4
	MOVEA.l	(A6)+, A3
	MOVE.w	(A6)+, D5
	BSR.w	LoadMultipleTilesFromTable
	BSR.w	ExecuteVdpDmaTransfer
	MOVE.l	(A6), D0
	BLE.b	LoadEncounterGraphics_Loop
	MOVE.w	#DMA_SLOT_ENEMY_ALT, Vdp_dma_slot_index.w
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A6)+, A4
	MOVEA.l	(A6)+, A3
	MOVE.w	(A6)+, D5
	BSR.w	LoadMultipleTilesFromTable
	BSR.w	ExecuteVdpDmaTransfer
LoadEncounterGraphics_Loop:
	RTS
	
; ---------------------------------------------------------------------------
; LoadMagicGraphics — load tile graphics and palette for a magic spell
;
; Uses D0.w as a spell index to look up a record in MagicGfxDataPtrs.
; Decompresses the spell's tile data into Tile_gfx_buffer, DMA's it to
; VRAM slot $43, then loads the spell's palette via LoadPalettesFromTable.
;
; Input:
;   D0.w  magic/spell index into MagicGfxDataPtrs
;
; Scratch:  D0, D5, A2, A4, A6
; Output:   VRAM slot $43 loaded; palette updated
; ---------------------------------------------------------------------------
LoadMagicGraphics:
	LEA	MagicGfxDataPtrs, A6
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A6,D0.w), A6
	MOVE.w	#DMA_SLOT_MAGIC_SPELL, Vdp_dma_slot_index.w
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A6)+, A4
	MOVEA.l	(A6)+, A3
	MOVE.w	(A6)+, D5
	MOVE.w	(A6), Palette_line_0_index.w
	BSR.w	LoadMultipleTilesFromTable
	BSR.w	ExecuteVdpDmaTransfer
	JSR	LoadPalettesFromTable
	RTS
	
; ---------------------------------------------------------------------------
; LoadEncounterTypeGraphics — load enemy tile graphics for current encounter
;
; Reads Encounter_group_index to pick a group from EnemyEncounterGroupTable,
; then uses Random_number to select one of 4 possible encounter types within
; that group.  Stores the selected type in Current_encounter_type.  Loads
; the primary tile set (16 tiles) and optional secondary tile set into
; Tile_gfx_buffer and Enemy_gfx_buffer respectively.
;
; Input:   (via RAM)  Encounter_group_index.w, Random_number.w
; Scratch:  D0-D2, D5, A1, A2, A3, A4, A6
; Output:   Current_encounter_type.w set; tile buffers loaded
; ---------------------------------------------------------------------------
LoadEncounterTypeGraphics:
	LEA	Tile_gfx_buffer.w, A2
	LEA	EnemyEncounterGroupTable, A1
	CLR.w	D2
	MOVE.b	Encounter_group_index.w, D2
	ADD.w	D2, D2
	ADD.w	D2, D2
	MOVEA.l	(A1,D2.w), A6
	MOVE.w	Random_number.w, D0
	ADD.w	D0, D0
	MOVE.w	(A6,D0.w), D1 ; Get the specific, of the 4 possible, encounter types
	MOVE.w	D1, Current_encounter_type.w
	LEA	EnemyGfxDataTable, A6
	MULU.w	#$C, D1
	MOVEA.l	(A6,D1.w), A6
	MOVE.l	A6, Current_encounter_gfx_ptr.w
	MOVEA.l	obj_active(A6), A4
	MOVEA.l	eagfx_main_gfx(A6), A3
	MOVE.w	#$000F, D5
	BSR.w	LoadMultipleTilesFromTable
	LEA	Enemy_gfx_buffer.w, A2
	MOVEA.l	Current_encounter_gfx_ptr.w, A6
	TST.l	obj_tile_index(A6)
	BEQ.b	LoadEncounterTypeGraphics_Loop
	MOVEA.l	obj_tile_index(A6), A4
	MOVEA.l	obj_screen_y(A6), A3
	MOVE.w	#$000F, D5
	BSR.w	LoadMultipleTilesFromTable
LoadEncounterTypeGraphics_Loop:
	RTS
	
; ---------------------------------------------------------------------------
; LoadTalkerGraphics — load tile graphics for an NPC talker/portrait
;
; Reads Talker_gfx_descriptor_ptr to get a graphics descriptor record.
; Loads the primary tile set into Tile_gfx_buffer and, if the secondary
; pointer is non-null, loads the secondary set into Enemy_gfx_buffer.
; Used during dialogue to load the NPC portrait/sprite tiles.
;
; Input:   (via RAM)  Talker_gfx_descriptor_ptr.w
; Scratch:  D5, A2, A3, A4, A6
; Output:   Tile_gfx_buffer (and optionally Enemy_gfx_buffer) loaded
; ---------------------------------------------------------------------------
LoadTalkerGraphics:
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	MOVEA.l	obj_active(A6), A4
	MOVEA.l	eagfx_main_gfx(A6), A3
	MOVE.w	obj_tile_index(A6), D5
	BSR.w	LoadMultipleTilesFromTable
	LEA	Enemy_gfx_buffer.w, A2
	MOVEA.l	Talker_gfx_descriptor_ptr.w, A6
	TST.l	obj_screen_x(A6)
	BEQ.b	LoadTalkerGraphics_Loop
	MOVEA.l	obj_screen_x(A6), A4
	MOVEA.l	obj_world_x(A6), A3
	MOVE.w	obj_world_y(A6), D5
	BSR.w	LoadMultipleTilesFromTable
LoadTalkerGraphics_Loop:
	RTS
	
; ---------------------------------------------------------------------------
; LoadFirstPersonGraphics — load tile sets for first-person dungeon view
;
; Processes GfxLoadList_FirstPerson via ProcessGraphicsLoadList, then
; DMA-fills $01FF bytes of VRAM at address $40000000 with zeros.
;
; Input:   (none)
; Scratch:  A6 (via ProcessGraphicsLoadList)
; Output:   VRAM first-person tile slots loaded and zeroed
; ---------------------------------------------------------------------------
LoadFirstPersonGraphics:
	LEA	GfxLoadList_FirstPerson-2, A6
	BSR.w	ProcessGraphicsLoadList
	DMAFillVRAM_bsr VDP_DMA_FILL_VRAM_START, $01FF
	RTS
	
; ---------------------------------------------------------------------------
; LoadFirstPersonBattleGraphics — load tile sets for first-person battle view
;
; Processes GfxLoadList_FirstPersonBattle via ProcessGraphicsLoadList.
;
; Input:   (none)
; Scratch:  A6 (via ProcessGraphicsLoadList)
; Output:   VRAM first-person battle tile slots loaded
; ---------------------------------------------------------------------------
LoadFirstPersonBattleGraphics:
	LEA	GfxLoadList_FirstPersonBattle, A6
	BSR.w	ProcessGraphicsLoadList
	RTS
	
; ---------------------------------------------------------------------------
; LoadIntroSegalogGraphics  — load Sega logo intro tile graphics
; LoadIntroTitleGraphics    — load title screen intro tile graphics
; LoadTownGraphics          — load town tile graphics
; LoadTownBattleGraphics    — load town battle tile graphics
; LoadWorldBattleGraphics   — load world/overworld battle tile graphics
;
; All five functions tail-call ProcessGraphicsLoadList with their
; respective GfxLoadList pointer in A6.  See ProcessGraphicsLoadList
; for the load loop.
;
; Input:   (none)
; Scratch:  A6 (via ProcessGraphicsLoadList)
; Output:   VRAM slots loaded for the respective context
; ---------------------------------------------------------------------------
LoadIntroSegalogGraphics:
	LEA	GfxLoadList_IntroSegalogo, A6
	BRA.w	ProcessGraphicsLoadList
LoadIntroTitleGraphics:
	LEA	GfxLoadList_IntroTitle, A6
	BRA.w	ProcessGraphicsLoadList
LoadTownGraphics:
	LEA	GfxLoadList_Town, A6
	BRA.w	ProcessGraphicsLoadList
LoadTownBattleGraphics:
	LEA	GfxLoadList_TownBattle, A6
	BRA.w	ProcessGraphicsLoadList
LoadWorldBattleGraphics:
	LEA	GfxLoadList_WorldBattle, A6
	BRA.w	ProcessGraphicsLoadList
; ---------------------------------------------------------------------------
; LoadPlayerOverworldGraphics — load player overworld sprite tile graphics
;
; Decompresses 108 ($6C) tiles from LoadPlayerOverworldGraphics_Data into
; Player_overworld_gfx_buffer using the indexed table loader.
;
; Input:   (none)
; Scratch:  D5, A2, A3, A4
; Output:   Player_overworld_gfx_buffer loaded with player sprite tiles
; ---------------------------------------------------------------------------
LoadPlayerOverworldGraphics:
	LEA	LoadPlayerOverworldGraphics_Data2, A3
	LEA	Player_overworld_gfx_buffer, A2
	LEA	LoadPlayerOverworldGraphics_Data, A4
	MOVE.w	#$006B, D5
	BSR.w	LoadMultipleTilesFromTable
	RTS
	
; ---------------------------------------------------------------------------
; LoadBattleTilesToBuffers — load tile sets for battle plane/slot buffers
;
; Decompresses three groups of tile data into three separate RAM buffers:
;   Tilemap_buffer_plane_a   — 168 ($A8) tiles from Data3/Data4
;   Battle_gfx_slot_1_buffer — 360 ($168) tiles from Data5/Data6
;   Battle_gfx_slot_2_buffer — 120 ($78) tiles from Data/Data2
; Uses LoadMultipleTilesFromTable for each group.
;
; Input:   (none)
; Scratch:  D5, A2, A3, A4, A6
; Output:   Battle tile RAM buffers populated
; ---------------------------------------------------------------------------
LoadBattleTilesToBuffers:
	LEA	Tilemap_buffer_plane_a, A2
	LEA	LoadBattleTilesToBuffers_Data3, A4
	LEA	LoadBattleTilesToBuffers_Data4, A3
	MOVE.w	#$00A7, D5
	BSR.w	LoadMultipleTilesFromTable
	LEA	Battle_gfx_slot_1_buffer, A2
	LEA	LoadBattleTilesToBuffers_Data5, A4
	LEA	LoadBattleTilesToBuffers_Data6, A3
	MOVE.w	#$0167, D5
	BSR.w	LoadMultipleTilesFromTable
	LEA	Battle_gfx_slot_2_buffer, A2
	LEA	LoadBattleTilesToBuffers_Data, A4
	LEA	LoadBattleTilesToBuffers_Data2, A3
	MOVE.w	#$0077, D5
	BSR.w	LoadMultipleTilesFromTable
	RTS
	
; ---------------------------------------------------------------------------
; LoadBossGraphics — load tile graphics for boss battle
;
; Decompresses four groups into separate RAM buffers:
;   Tilemap_buffer_plane_a   — 192 ($C0) tiles from Data/Data2
;   Boss_gfx_slot_1_buffer   — 240 ($F0) tiles from Data3/Data4
;   Boss_gfx_extra_buffer    —  32 ($20) tiles from Data5/Data6
;   Boss_gfx_slot_2_buffer   —  28 ($1C) tiles from Data7/Data8
;
; Input:   (none)
; Scratch:  D5, A2, A3, A4, A6
; Output:   Boss tile RAM buffers populated
; ---------------------------------------------------------------------------
LoadBossGraphics:
	LEA	Tilemap_buffer_plane_a, A2
	LEA	LoadBossGraphics_Data, A4
	LEA	LoadBossGraphics_Data2, A3
	MOVE.w	#$00BF, D5
	BSR.w	LoadMultipleTilesFromTable
	LEA	Boss_gfx_slot_1_buffer, A2
	LEA	LoadBossGraphics_Data3, A4
	LEA	LoadBossGraphics_Data4, A3
	MOVE.w	#$00EF, D5
	BSR.w	LoadMultipleTilesFromTable
	LEA	Boss_gfx_extra_buffer, A2
	LEA	LoadBossGraphics_Data5, A4
	LEA	LoadBossGraphics_Data6, A3
	MOVE.w	#$001F, D5
	BSR.w	LoadMultipleTilesFromTable
	LEA	Boss_gfx_slot_2_buffer, A2
	LEA	LoadBossGraphics_Data7, A4
	LEA	LoadBossGraphics_Data8, A3
	MOVE.w	#$001B, D5
	BSR.w	LoadMultipleTilesFromTable
	RTS
	
; ---------------------------------------------------------------------------
; ProcessGraphicsLoadList — process a GFX load list and DMA each slot
;
; Reads a GFX load list pointed to by A6.  Each entry is:
;   word  DMA slot index (negative value = end of list)
;   long  source index table pointer (A4)
;   long  tile pointer table pointer (A3)
;   word  tile count (D5)
; For each entry, decompresses tiles into Tile_gfx_buffer and DMA-transfers
; them to the slot.  Terminates when the slot word is negative.
;
; Input:
;   A6    pointer to GFX load list
;
; Scratch:  D0, D5, A2, A3, A4, A6
; Output:   VRAM slots loaded per list entries
; ---------------------------------------------------------------------------
ProcessGraphicsLoadList:
	MOVE.w	(A6)+, D0
	BLT.b	ProcessGraphicsLoadList_Loop
	MOVE.w	D0, Vdp_dma_slot_index.w
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A6)+, A4
	MOVEA.l	(A6)+, A3
	MOVE.w	(A6)+, D5
	BSR.w	LoadMultipleTilesFromTable
	BSR.w	ExecuteVdpDmaTransfer
	BRA.b	ProcessGraphicsLoadList
ProcessGraphicsLoadList_Loop:
	RTS
	
; ---------------------------------------------------------------------------
; LoadMultipleTilesFromTable — decompress N tiles from an indexed tile table
;
; Reads byte indices from A4; for each index, looks up the source pointer
; in a long-pointer table at A3 (index×4), decompresses the tile into A2,
; then advances A2 by $20 (32 bytes per tile). Iterates D5+1 tiles (DBF).
;
; Input:
;   A4    index list (one byte per tile)
;   A3    tile pointer table (one long ptr per unique tile)
;   A2    destination buffer
;   D5.w  tile count minus 1 (DBF loop counter)
;
; Scratch:  D0, D5, A0, A2
; Output:   A2 advanced past written tiles; tiles decompressed in buffer
; ---------------------------------------------------------------------------
LoadMultipleTilesFromTable:
	CLR.w	D0
	MOVE.b	(A4)+, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A3,D0.w), A0
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadMultipleTilesFromTable
	RTS
	
; ---------------------------------------------------------------------------
; ExecuteVdpDmaTransfer — DMA Tile_gfx_buffer to VRAM slot from command table
;
; Looks up the DMA command record for the current Vdp_dma_slot_index in
; BattleSpriteDMACommands (each record is 16 bytes), programs the VDP DMA
; registers, copies the command routine to RAM, and executes it.
; Stops and restarts the Z80 around the DMA.
;
; Input:   (via RAM)
;   Vdp_dma_slot_index.w  — slot index into BattleSpriteDMACommands
;
; Scratch:  D0, D4, A0
; Output:   Tile_gfx_buffer DMA'd to VRAM at selected slot
; ---------------------------------------------------------------------------
ExecuteVdpDmaTransfer:
	ORI	#$0700, SR
	stopZ80
	BSR.w	InitVdpDmaRamRoutine
	MOVE.w	#2, D4
	ORI.w	#$8F00, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4
	MOVE.w	D4, VDP_control_port
	LEA	BattleSpriteDMACommands, A0
	MOVE.w	Vdp_dma_slot_index.w, D0
	ASL.w	#4, D0
	LEA	(A0,D0.w), A0
	MOVE.l	(A0)+, VDP_control_port
	MOVE.l	(A0)+, VDP_control_port
	MOVE.w	(A0)+, VDP_control_port
	MOVE.l	(A0)+, Vdp_dma_cmd.w
	JSR	Vdp_dma_ram_routine.w
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	#0, Z80_bus_request
	ANDI	#$F8FF, SR
	RTS

; ---------------------------------------------------------------------------
; GetRandomNumber — advance the LCG RNG and return a pseudo-random word
;
; Uses a 32-bit linear-congruential generator stored in Rng_state.  The
; multiplier is effectively 41 (2²+1)×(2³+1) = 45, then the high and low
; words are XOR-folded to produce a 16-bit result in D0.w.
;
; NOTE: This function is physically located in battle_gfx.asm because it
; was not yet extracted to a dedicated module.  Logically it belongs with
; the core math utilities.  See MOVE-001 for the annotation task.
;
; Input:   (none)
; Scratch:  D1 (saved/restored via stack)
; Output:   D0.w = 16-bit pseudo-random value; Rng_state.w updated
;
; RANDOMIZER SEED INJECTION POINT
; --------------------------------
; Rng_state ($FFFFC0A0, .l) is the sole RNG state variable.  It is cleared
; to zero during ClearRAMAndInitHardware (init.asm:StartupSequence) and then
; first used on the frame that triggers the first GetRandomNumber call.
;
; When Rng_state == 0 on entry, the BNE guard falls through to the seed
; constant MOVE.l #$2A6D365A, D1 — this is the game's hard-coded seed.
;
; To inject a randomizer seed:
;   1. After ClearRAMAndInitHardware returns (init.asm:StartupSequence+4),
;      insert: MOVE.l #<seed_value>, Rng_state.w
;   2. Any non-zero 32-bit value is a valid seed; the LCG will produce a
;      different sequence for every distinct seed.
;   3. The seed must be written BEFORE the first JSR GetRandomNumber, which
;      occurs during the first enemy encounter after startup.
;   4. 59 call sites spread across enemy.asm, combat.asm, items.asm,
;      boss.asm, npc.asm, player.asm, gameplay.asm — all funnel through
;      this single function.
; ---------------------------------------------------------------------------
GetRandomNumber:
	MOVEM.l	D1, -(A7)
	MOVE.l	Rng_state.w, D1
	BNE.w	GetRandomNumber_Loop
	MOVE.l	#$2A6D365A, D1
GetRandomNumber_Loop:
	MOVE.l	D1, D0
	ASL.l	#2, D1
	ADD.l	D0, D1
	ASL.l	#3, D1
	ADD.l	D0, D1
	MOVE.w	D1, D0
	SWAP	D1
	ADD.w	D1, D0
	MOVE.w	D0, D1
	SWAP	D1
	MOVE.l	D1, Rng_state.w
	MOVEM.l	(A7)+, D1
	RTS

; ---------------------------------------------------------------------------
; RemoveItemFromArray — remove element at index D0 from a word array at A0
;
; Shifts all words after the removed index one slot forward (left-compaction),
; effectively removing the element at index D0. The array length (in entries)
; is D2; the caller is responsible for decrementing the length after the call.
;
; MOVE-002 NOTE: This is a generic array utility; it belongs in core.asm.
; Callers: combat.asm, npc.asm, boss.asm, items.asm, magic.asm.
; Physical move would change all JSR/BSR displacements and break bit-perfect.
;
; Input:
;   D0.w  index of element to remove (0-based)
;   D2.w  current array length (number of entries)
;   A0    base address of word array
;
; Scratch:  D1, A0
; Output:   Array compacted; entry at D0 overwritten
; ---------------------------------------------------------------------------
RemoveItemFromArray:
	MOVE.w	D0, D1
	ADD.w	D0, D0
	LEA	(A0,D0.w), A0
	SUB.w	D1, D2
	BEQ.b	RemoveItemFromArray_Loop
	SUBQ.w	#1, D2
RemoveItemFromArray_Done:
	MOVE.w	$2(A0), (A0)+
	DBF	D2, RemoveItemFromArray_Done
RemoveItemFromArray_Loop:
	RTS
	
; ---------------------------------------------------------------------------
; DecompressTileGraphics — decompress a masked tile from ROM into A2
;
; Decodes a custom bit-masked tile format.  Each tile record consists of
; mask runs followed by unmasked pixel bytes.  The mask bitmask (D3.l)
; accumulates 1 bits for pixels that were explicitly set; pixels still
; zero in the mask are filled by reading additional bytes from the source.
;
; Input:
;   A0    pointer to compressed tile data
;   A2    destination tile buffer (32 bytes, 8×8 4bpp)
;
; Scratch:  D0-D4, A0-A1, A2 unchanged (A1 is a working pointer into A2)
; Output:   32 bytes of 4bpp tile data written at A2
; ---------------------------------------------------------------------------
DecompressTileGraphics:
	CLR.l	D3
DecompressTileGraphics_ReadByte:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	BEQ.w	DecompressTileGraphics_Loop
	SUBQ.w	#1, D0
DecompressTileGraphics_Done:
	CLR.w	D2
DecompressTileGraphics_ReadMask:
	MOVE.b	(A0)+, D2
	MOVE.b	(A0)+, D1
	ASL.l	#8, D1
	MOVE.b	(A0)+, D1
	ASL.l	#8, D1
	MOVE.b	(A0)+, D1
	ASL.l	#8, D1
	MOVE.b	(A0)+, D1
	OR.l	D1, D3
	BSR.w	WriteMaskedTileRow
	DBF	D0, DecompressTileGraphics_Done
	LEA	(A2), A1
	MOVEQ	#$00000020, D0
	MOVE.l	D3, D1
DecompressTileGraphics_Done2:
	CMPI.l	#$FFFFFFFF, D3
DecompressTileGraphics_CheckFull:
	BEQ.b	DecompressTileGraphics_Loop2
DecompressTileGraphics_Done3:
	ROL.l	#1, D1
DecompressTileGraphics_PixelLoop:
	SUBQ.w	#1, D0
	BTST.l	#0, D1
	BNE.b	DecompressTileGraphics_Loop3
	MOVE.b	(A0)+, (A1)+
	BSET.l	D0, D3
	BRA.b	DecompressTileGraphics_Done2
DecompressTileGraphics_Loop3:
	LEA	$1(A1), A1
DecompressTileGraphics_PixelSkip:
	BRA.b	DecompressTileGraphics_Done3
DecompressTileGraphics_Loop2:
	RTS
	
DecompressTileGraphics_Loop:
	LEA	(A2), A1
DecompressTileGraphics_UnmaskedEntry:
	MOVEQ	#7, D0
DecompressTileGraphics_Loop_Done:
	MOVE.b	(A0)+, (A1)+
DecompressTileGraphics_UnmaskedPixels:
	MOVE.b	(A0)+, (A1)+
	MOVE.b	(A0)+, (A1)+
	MOVE.b	(A0)+, (A1)+
	DBF	D0, DecompressTileGraphics_Loop_Done
	RTS
	
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
; WriteMaskedTileRow — write 32 pixels using a mask bitfield
;
; Iterates 32 pixels (one tile row of 4bpp data, 4 bits per pixel = 32 nibbles
; packed into 16 bytes).  For each pixel position, tests the corresponding bit
; in D1; if set, writes D2 to (A1) (color index byte); if clear, leaves it.
; Advances A1 one byte per pixel regardless.
;
; DRY-010 NOTE: WriteTileRowFromBitfield (below) is byte-for-byte identical to
; this function.  The only difference is the set of intermediate labels.
; Replacing WriteTileRowFromBitfield with a BRA.w here would save 14 bytes
; but changes the binary encoding of the branch and breaks bit-perfect output.
; Cross-reference: see WriteTileRowFromBitfield at the note below for the
; corresponding documentation.
;
; Input:
;   D1.l  mask bitfield (bit 31 = pixel 0, left-shifted each iteration)
;   D2.b  color byte to write for masked pixels
;   A2    base tile buffer (A1 is initialized from A2)
;
; Scratch:  D1, D4, A1
; Output:   Masked pixels in tile row written with D2
; ---------------------------------------------------------------------------
WriteMaskedTileRow:
	LEA	(A2), A1
WriteMaskedTileRow_PixelLoop:
	MOVEQ	#$0000001F, D4
WriteMaskedTileRow_Done:
	ROL.l	#1, D1
WriteMaskedTileRow_TestPixel:
	BTST.l	#0, D1
	BEQ.b	WriteMaskedTileRow_Loop
	MOVE.b	D2, (A1)
WriteMaskedTileRow_Loop:
	LEA	$1(A1), A1
WriteMaskedTileRow_NextPixel:
	DBF	D4, WriteMaskedTileRow_Done
	RTS
	
; ---------------------------------------------------------------------------
; DecompressFontTile — decompress a masked font tile with color clamping
;
; Same structure as DecompressTileGraphics but applies ClampTileCoordinates
; to each pixel byte before writing, which clamps the color index to a safe
; palette range.  Used exclusively for font/UI tiles.
;
; Input:
;   A0    pointer to compressed font tile data
;   A2    destination tile buffer (32 bytes)
;
; Scratch:  D0-D3, D6-D7, A0-A1
; Output:   32 bytes of clamped 4bpp tile data written at A2
; ---------------------------------------------------------------------------
DecompressFontTile:
	CLR.l	D3
	CLR.w	D0
	MOVE.b	(A0)+, D0
	BEQ.w	DecompressFontTile_Loop
	SUBQ.w	#1, D0
DecompressFontTile_Done:
	CLR.w	D2
	MOVE.b	(A0)+, D2
	MOVE.b	(A0)+, D1
	ASL.l	#8, D1
	MOVE.b	(A0)+, D1
	ASL.l	#8, D1
	MOVE.b	(A0)+, D1
	ASL.l	#8, D1
	MOVE.b	(A0)+, D1
	OR.l	D1, D3
	MOVE.b	D2, D6
	BSR.w	ClampTileCoordinates
	MOVE.b	D6, D2
	BSR.w	WriteTileRowFromBitfield
	DBF	D0, DecompressFontTile_Done
	LEA	(A2), A1
	MOVEQ	#$00000020, D0
	MOVE.l	D3, D1
DecompressFontTile_Done2:
	CMPI.l	#$FFFFFFFF, D3
	BEQ.b	DecompressFontTile_Loop2
DecompressFontTile_Done3:
	ROL.l	#1, D1
	SUBQ.w	#1, D0
	BTST.l	#0, D1
	BNE.b	DecompressFontTile_Loop3
	MOVE.b	(A0)+, D6
	BSR.w	ClampTileCoordinates
	MOVE.b	D6, (A1)+
	BSET.l	D0, D3
	BRA.b	DecompressFontTile_Done2
DecompressFontTile_Loop3:
	LEA	$1(A1), A1
	BRA.b	DecompressFontTile_Done3
DecompressFontTile_Loop2:
	RTS
	
DecompressFontTile_Loop:
	LEA	(A2), A1
	MOVEQ	#7, D0
DecompressFontTile_Loop_Done:
	MOVE.b	(A0)+, D6
	BSR.w	ClampTileCoordinates
	MOVE.b	D6, (A1)+
	MOVE.b	(A0)+, D6
	BSR.w	ClampTileCoordinates
	MOVE.b	D6, (A1)+
	MOVE.b	(A0)+, D6
	BSR.w	ClampTileCoordinates
	MOVE.b	D6, (A1)+
	MOVE.b	(A0)+, D6
	BSR.w	ClampTileCoordinates
	MOVE.b	D6, (A1)+
	DBF	D0, DecompressFontTile_Loop_Done
	RTS
	
; ---------------------------------------------------------------------------
; WriteTileRowFromBitfield — write 32 pixels using a mask bitfield (font)
;
; Byte-for-byte identical to WriteMaskedTileRow (above).  Used exclusively
; by DecompressFontTile; WriteMaskedTileRow is used by DecompressTileGraphics.
; They were kept separate in the original ROM — consolidating them into a
; shared entry point (BRA.w WriteMaskedTileRow) would change the BSR.w
; displacement and break bit-perfect output.
;
; DRY-010 NOTE: See WriteMaskedTileRow for the full explanation.
;
; Input:
;   D1.l  mask bitfield
;   D2.b  color byte for masked pixels
;   A2    base tile buffer
;
; Scratch:  D1, D4, A1
; Output:   Masked pixels written; A1 advanced past row
; ---------------------------------------------------------------------------
WriteTileRowFromBitfield:
	LEA	(A2), A1
	MOVEQ	#$0000001F, D4
WriteTileRowFromBitfield_Done:
	ROL.l	#1, D1
	BTST.l	#0, D1
	BEQ.b	WriteTileRowFromBitfield_Loop
	MOVE.b	D2, (A1)
WriteTileRowFromBitfield_Loop:
	LEA	$1(A1), A1
	DBF	D4, WriteTileRowFromBitfield_Done
	RTS
	
; ---------------------------------------------------------------------------
; ClampTileCoordinates — clamp a font pixel byte to a safe palette range
;
; Font color bytes encode two nibbles (high = row offset, low = column).
; This function clamps each nibble: if the high nibble is $3x it is zeroed,
; and if the low nibble is $x3 it is zeroed.  Used to prevent color index
; overflow when blitting font tiles.
;
; Input:
;   D6.b  raw pixel byte (packed nibble pair)
;
; Scratch:  D7
; Output:   D6.b clamped
; ---------------------------------------------------------------------------
ClampTileCoordinates:
	MOVE.b	D6, D7
	ANDI.w	#$00F0, D7
	CMPI.w	#$0030, D7
	BNE.b	ClampTileCoordinates_Loop
	ANDI.b	#$0F, D6
ClampTileCoordinates_Loop:
	MOVE.b	D6, D7
	ANDI.w	#$000F, D7
	CMPI.w	#3, D7
	BNE.b	ClampTileCoordinates_Loop2
	ANDI.b	#$F0, D6
ClampTileCoordinates_Loop2:
	RTS

; ---------------------------------------------------------------------------
; LoadAndDecompressTileGfx — decompress all 256 tiles and DMA to VRAM
;
; Decompresses 256 tiles from CompressedFontTileData into Tile_gfx_buffer
; using DecompressTileGraphics (no clamping), then DMA's the buffer to
; VRAM via TransferTilesViaDma.
;
; Input:   (none)
; Scratch:  D5, A0, A2
; Output:   VRAM tile area loaded with 256 decompressed (unclamped) tiles
; ---------------------------------------------------------------------------
LoadAndDecompressTileGfx:
	LEA	Tile_gfx_buffer.w, A2
	LEA	CompressedFontTileData, A0
	MOVE.w	#$00FF, D5
ClampTileCoordinates_Loop2_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, ClampTileCoordinates_Loop2_Done
	BSR.w	TransferTilesViaDma
	RTS

; ---------------------------------------------------------------------------
; InitFontTiles — decompress font tiles (with clamping) and DMA to VRAM
;
; Decompresses 256 tiles from CompressedFontTileData into Tile_gfx_buffer
; using DecompressFontTile (with ClampTileCoordinates applied per pixel),
; then DMA's the buffer to VRAM via TransferTilesViaDma.
;
; Input:   (none)
; Scratch:  D5, A0, A2
; Output:   VRAM tile area loaded with 256 clamped font tiles
; ---------------------------------------------------------------------------
InitFontTiles:
	LEA	Tile_gfx_buffer.w, A2
	LEA	CompressedFontTileData, A0
	MOVE.w	#$00FF, D5
InitFontTiles_Done:
	BSR.w	DecompressFontTile
	LEA	$20(A2), A2
	DBF	D5, InitFontTiles_Done
	BSR.w	TransferTilesViaDma
	RTS

; ---------------------------------------------------------------------------
; TransferTilesViaDma — DMA Tile_gfx_buffer to VRAM at $C000 (font area)
;
; Hard-wired DMA transfer: copies Tile_gfx_buffer ($0000–$1FFF in RAM) to
; VRAM address $C000 (256 tiles × 32 bytes, slot offset $4C00/2 = $2600).
; Uses self-modifying code stub in RAM (see InitVdpDmaRamRoutine).
;
; Input:   (none) — source is always Tile_gfx_buffer, dest always $C000
; Scratch:  D4
; Output:   VRAM font area updated
; ---------------------------------------------------------------------------
TransferTilesViaDma:
	stopZ80
	JSR	InitVdpDmaRamRoutine
	MOVE.w	#2, D4
	ORI.w	#$8F00, D4			; VDP reg 15 = 2: auto-increment
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4				; Enable DMA in reg 1
	MOVE.w	D4, VDP_control_port
	MOVE.l	#$94109300, VDP_control_port	; Regs 19-20: DMA length = $1000 bytes
	MOVE.l	#$96D09500, VDP_control_port	; Regs 21-22: DMA source = $xxD000
	MOVE.w	#$977F, VDP_control_port	; Reg 23 = $7F: DMA source high + 68k→VRAM mode
	MOVE.l	#$58000082, Vdp_dma_cmd.w	; VRAM write to $6000 with DMA trigger
	JSR	Vdp_dma_ram_routine.w
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4				; Clear DMA enable bit
	MOVE.w	D4, VDP_control_port
	MOVE.w	#0, Z80_bus_request
	RTS

; ---------------------------------------------------------------------------
; LoadTownTileGraphics — decompress and DMA town tileset for Current_town
;
; Selects the town tileset from TownTileGfxTable using Current_town.w
; (each entry is 10 bytes).  Special-cases Swaffham when ruined.
; Decompresses 256 tiles into Tile_gfx_buffer, DMA's to VRAM (Wyclif slot),
; then decompresses object tiles and DMA's to VRAM (Parma slot).
;
; Input:   (via RAM)  Current_town.w, Swaffham_ruined.w
; Scratch:  D0-D1, D5, A0-A2
; Output:   Town tileset and object tiles loaded into VRAM
; ---------------------------------------------------------------------------
LoadTownTileGraphics:
	LEA	Tile_gfx_buffer.w, A2
	TST.b	Swaffham_ruined.w
	BEQ.b	LoadTownTileGfx_LookupTable
	CMPI.w	#TOWN_SWAFFHAM, Current_town.w
	BNE.b	LoadTownTileGfx_LookupTable
	MOVEA.l	LoadTownTileGraphics_Data, A0
	BRA.b	LoadTownTileGfx_LookupTable_Loop
LoadTownTileGfx_LookupTable:
	LEA	TownTileGfxTable, A1
	MOVE.w	Current_town.w, D0 
	MOVE.w	D0, D1  
	ADD.w	D1, D1  
	ASL.w	#3, D0 
	ADD.w	D1, D0
	MOVEA.l	(A1,D0.w), A0 ; Multiply current town by 10
LoadTownTileGfx_LookupTable_Loop:
	MOVE.w	#$00FF, D5
LoadTownTileGfx_LookupTable_Loop_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTownTileGfx_LookupTable_Loop_Done
	LEA	DmaCmd_TownTileset_Wyclif, A0
	BSR.w	ExecuteVdpDmaFromPointer
	LEA	Tile_gfx_buffer.w, A2
	TST.b	Swaffham_ruined.w
	BEQ.b	LoadTownObjectGfx_LookupTable
	CMPI.w	#TOWN_SWAFFHAM, Current_town.w
	BNE.b	LoadTownObjectGfx_LookupTable
	MOVEA.l	LoadTownTileGfx_LookupTable_Loop_Done_Data, A0
	MOVE.w	LoadTownTileGfx_LookupTable_Loop_Done_Data2, D5
	BRA.b	LoadTownObjectGfx_DecompressLoop
LoadTownObjectGfx_LookupTable:
	LEA	TownTileGfxTable, A1
	MOVE.w	Current_town.w, D0
	MOVE.w	D0, D1
	ADD.w	D1, D1
	ASL.w	#3, D0
	ADD.w	D1, D0
	MOVEA.l	$4(A1,D0.w), A0
	MOVE.w	$8(A1,D0.w), D5
LoadTownObjectGfx_DecompressLoop:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTownObjectGfx_DecompressLoop
	LEA	DmaCmd_TownTileset_Parma, A0
	BSR.w	ExecuteVdpDmaFromPointer
	RTS
	
; ---------------------------------------------------------------------------
; LoadBattleHudGraphics — load battle HUD tile graphics to VRAM
;
; Decompresses 256 HUD tiles into Tile_gfx_buffer, DMA's to VRAM Wyclif
; slot, then decompresses 58 ($3A) additional HUD tiles and DMA's to the
; Parma slot.
;
; Input:   (none)
; Scratch:  D5, A0, A2
; Output:   VRAM Wyclif and Parma slots loaded with battle HUD tiles
; ---------------------------------------------------------------------------
LoadBattleHudGraphics:
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadBattleHudGraphics_Data, A0
	MOVE.w	#$00FF, D5
LoadBattleHudGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattleHudGraphics_Done
	LEA	DmaCmd_TownTileset_Wyclif, A0
	BSR.w	ExecuteVdpDmaFromPointer
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadBattleHudGraphics_Done_Data, A0
	MOVE.w	#$0039, D5
LoadBattleHudGraphics_Done2:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattleHudGraphics_Done2
	LEA	DmaCmd_TownTileset_Parma, A0
	BSR.w	ExecuteVdpDmaFromPointer
	RTS
	
; ExecuteVdpDmaFromPointer
; Execute VDP DMA transfer from a pointer table entry to VRAM
; Input: A0 = Pointer to DMA command data (destination, length, source)
; NOTE: Byte-for-byte identical to ExecuteVdpDmaFromRam (line ~1281).
;       Both exist in the original ROM; neither can be removed without breaking bit-perfectness.
ExecuteVdpDmaFromPointer:
	ORI	#$0700, SR
	stopZ80
	BSR.w	InitVdpDmaRamRoutine
	MOVE.w	#2, D4
	ORI.w	#$8F00, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.l	(A0)+, VDP_control_port
	MOVE.l	(A0)+, VDP_control_port
	MOVE.w	(A0)+, VDP_control_port
	MOVE.l	(A0)+, Vdp_dma_cmd.w
	JSR	Vdp_dma_ram_routine.w
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	#0, Z80_bus_request
	ANDI	#$F8FF, SR
	RTS
	
; ---------------------------------------------------------------------------
; ExecuteVdpDmaFromPointer_Setup — decompress overworld status tiles and DMA
;
; Decompresses 58 ($3A) tiles from ExecuteVdpDmaFromPointer_Data into
; Tile_gfx_buffer and DMA's them to VRAM via ExecuteVdpDmaFromRam using
; the DmaCmd_OverworldStatusTiles command.
;
; Input:   (none)
; Scratch:  D5, A0, A2
; Output:   VRAM overworld status tile area loaded
; ---------------------------------------------------------------------------
ExecuteVdpDmaFromPointer_Setup:
	LEA	ExecuteVdpDmaFromPointer_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$0039, D5
ExecuteVdpDmaFromPointer_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, ExecuteVdpDmaFromPointer_Done
	LEA	DmaCmd_OverworldStatusTiles, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
; ---------------------------------------------------------------------------
; LoadBattleTerrainGraphics — load battle terrain tileset and palette
;
; Determines the terrain tileset index (boss, cave, soldier, or overworld)
; by checking battle flags and calling DetermineTerrainTileset.  Then
; decompresses the tiles from TerrainTilemapMetadata, DMA's them to VRAM,
; and loads the terrain palette via LoadPalettesFromTable.
;
; Input:   (via RAM)  Is_boss_battle.w, Is_in_cave.w, Soldier_fight_event_trigger.w
; Scratch:  D0, D5, A0-A2
; Output:   Terrain tileset in VRAM; Terrain_tileset_index.w set; palette updated
; ---------------------------------------------------------------------------
LoadBattleTerrainGraphics:
	TST.b	Is_boss_battle.w
	BEQ.b	LoadBattleTerrainGraphics_Loop
	MOVE.w	#TERRAIN_TILESET_BOSS, Terrain_tileset_index.w
	BRA.b	LoadBattleTerrainGraphics_LoadTiles
LoadBattleTerrainGraphics_Loop:
	TST.b	Is_in_cave.w
	BEQ.b	LoadBattleTerrainGraphics_Loop2
	MOVE.w	#TERRAIN_TILESET_CAVE, Terrain_tileset_index.w
	BRA.b	LoadBattleTerrainGraphics_LoadTiles
LoadBattleTerrainGraphics_Loop2:
	TST.b	Soldier_fight_event_trigger.w
	BEQ.b	LoadBattleTerrainGraphics_Loop3
	MOVE.w	#TERRAIN_TILESET_SOLDIER, Terrain_tileset_index.w
	BRA.b	LoadBattleTerrainGraphics_LoadTiles
LoadBattleTerrainGraphics_Loop3:
	BSR.w	DetermineTerrainTileset
LoadBattleTerrainGraphics_LoadTiles:
	MOVE.w	Terrain_tileset_index.w, D0
	LEA	TerrainTilemapMetadata, A1
	ASL.w	#3, D0
	LEA	(A1,D0.w), A1
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A1)+, A0
	MOVE.w	(A1)+, D5
	MOVE.w	(A1)+, Palette_line_2_index.w
	BSR.w	DecompressTileLoop
	LEA	TerrainTileGfxDmaPtrs, A1
	MOVE.w	Terrain_tileset_index.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A1,D0.w), A0
	BSR.w	ExecuteVdpDmaFromRam
	JSR	LoadPalettesFromTable
	RTS
	
; ---------------------------------------------------------------------------
; DecompressTileLoop — decompress D5+1 tiles into A2, advancing by $20 each
;
; Simple loop helper shared by several callers.  Decompresses D5+1 tiles
; from A0 into sequential $20-byte slots starting at A2.
;
; Input:
;   A0    source compressed tile data
;   A2    destination buffer
;   D5.w  tile count minus 1 (DBF loop counter)
;
; Scratch:  A0, A2, D5
; Output:   Tiles decompressed; A2 advanced past last tile
;
; NOTE (DRY-004): ~20 Load*TileGraphics functions below use an inline copy of
; this three-instruction loop (BSR.w DecompressTileGraphics / LEA $20(A2),A2 /
; DBF D5,<local_label>) rather than calling DecompressTileLoop.  The outer
; pattern — setup src/dst/count, run loop, LEA DmaCmd, BSR ExecuteVdpDmaFromRam
; — is also identical across all of them except for the data pointer, count,
; and DMA command label.
;
; A macro or shared subroutine CAN'T be used: each inline loop encodes 14 bytes
; of instructions whereas a BSR.w DecompressTileLoop call encodes only 6 bytes,
; changing the binary.  This is the fundamental bit-perfect constraint.
; DecompressTileLoop IS used by a subset of callers (LoadBattleTerrainGraphics)
; that were assembled after this function existed; the earlier functions were
; assembled with inline loops and cannot be altered.
; ---------------------------------------------------------------------------
DecompressTileLoop:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, DecompressTileLoop
	RTS
	
; ---------------------------------------------------------------------------
; LoadBattleTileGraphics — load battle floor/field tile graphics to VRAM
;
; Decompresses 27 ($1B) tiles from LoadBattleTileGraphics_Data and DMA's
; them to the DmaCmd_BattleTiles VRAM slot.
;
; Input:   (none)
; Scratch:  D5, A0, A2
; Output:   VRAM battle tile slot loaded
; ---------------------------------------------------------------------------
LoadBattleTileGraphics:
	LEA	LoadBattleTileGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$001A, D5
LoadBattleTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattleTileGraphics_Done
	LEA	DmaCmd_BattleTiles, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
; ---------------------------------------------------------------------------
; LoadBattleUiTileGraphics — load battle UI tile graphics to VRAM
;
; Decompresses 61 ($3D) tiles from LoadBattleUiTileGraphics_Data and DMA's
; them to the DmaCmd_BattleUiTiles VRAM slot.
;
; Input:   (none)
; Scratch:  D5, A0, A2
; Output:   VRAM battle UI tile slot loaded
; ---------------------------------------------------------------------------
LoadBattleUiTileGraphics:
	LEA	LoadBattleUiTileGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$003C, D5
LoadBattleUiTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattleUiTileGraphics_Done
	LEA	DmaCmd_BattleUiTiles, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
; ---------------------------------------------------------------------------
; LoadWorldMapTileGraphics — load world map tile graphics to VRAM
;
; Decompresses 235 ($EB) tiles from LoadWorldMapTileGraphics_Data and DMA's
; them to the DmaCmd_WorldMapTiles VRAM slot.  Falls through to the
; ExecuteWorldMapDma label (which is also a named entry point for just the
; DMA step).
;
; Input:   (none)
; Scratch:  D5, A0, A2
; Output:   VRAM world map tile area loaded
; ---------------------------------------------------------------------------
LoadWorldMapTileGraphics:
	LEA	LoadWorldMapTileGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$00EA, D5
LoadWorldMapTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadWorldMapTileGraphics_Done
ExecuteWorldMapDma:
	LEA	DmaCmd_WorldMapTiles, A0
	BSR.w	ExecuteVdpDmaFromRam
; NullSpriteRoutine
; Used as NullSpriteRoutine-2 in enemy data tables (points to BSR instruction)
NullSpriteRoutine:
	RTS
	
; ---------------------------------------------------------------------------
; LoadCaveTileGraphics — load compressed cave tileset from ROM data pointer
; LoadCaveTileGfxToBuffer — decompress 118 ($76) cave tiles into Tile_gfx_buffer
;
; LoadCaveTileGraphics sets A0 = LoadCaveTileGraphics_Data then falls through
; to LoadCaveTileGfxToBuffer, which decompresses the tiles and DMA's them
; to VRAM via DmaCmd_CaveTiles.
;
; Input:   (none)
; Scratch:  D5, A0, A2
; Output:   VRAM cave tile slot loaded
; ---------------------------------------------------------------------------
LoadCaveTileGraphics:
	LEA	LoadCaveTileGraphics_Data, A0
LoadCaveTileGfxToBuffer:
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$0075, D5
LoadCaveTileGfxToBuffer_Done:
	BSR.w	DecompressTileGraphics
LoadCaveTileGfxToBuffer_NextTile:
	LEA	$20(A2), A2
LoadCaveTileGfxToBuffer_Loop:
	DBF	D5, LoadCaveTileGfxToBuffer_Done
LoadCaveTileGfxToBuffer_DmaTransfer:
	LEA	DmaCmd_CaveTiles, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
; ---------------------------------------------------------------------------
; LoadBattleGroundTileGraphics — load battle ground/floor tile graphics
;
; Decompresses 101 ($65) tiles from LoadBattleGroundTileGraphics_Data and
; DMA's them to DmaCmd_BattleGroundGfx.
;
; Input:   (none)  Scratch:  D5, A0, A2  Output:   VRAM ground tile slot loaded
; ---------------------------------------------------------------------------
LoadBattleGroundTileGraphics:
	LEA	LoadBattleGroundTileGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$0064, D5
LoadBattleGroundTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattleGroundTileGraphics_Done
	LEA	DmaCmd_BattleGroundGfx, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
; ---------------------------------------------------------------------------
; LoadBattleEnemyTileGraphics — load battle enemy sprite tile graphics
;
; Decompresses 87 ($57) tiles from SpriteGfxData_8287C and DMA's them
; to DmaCmd_BattleEnemyGfx.
;
; Input:   (none)  Scratch:  D5, A0, A2  Output:   VRAM enemy tile slot loaded
; ---------------------------------------------------------------------------
LoadBattleEnemyTileGraphics:
	LEA	SpriteGfxData_8287C, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$0056, D5
LoadBattleEnemyTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattleEnemyTileGraphics_Done
	LEA	DmaCmd_BattleEnemyGfx, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
; ---------------------------------------------------------------------------
; LoadBattleStatusTileGraphics — load battle status bar tile graphics
;
; Decompresses 89 ($59) tiles from LoadBattleStatusTileGraphics_Data and
; DMA's them to DmaCmd_BattleStatusGfx.
;
; Input:   (none)  Scratch:  D5, A0, A2  Output:   VRAM battle status tile slot loaded
; ---------------------------------------------------------------------------
LoadBattleStatusTileGraphics:
	LEA	LoadBattleStatusTileGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$0058, D5
LoadBattleStatusTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattleStatusTileGraphics_Done
	LEA	DmaCmd_BattleStatusGfx, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
; ---------------------------------------------------------------------------
; LoadCaveEnemyTileGraphics — load cave enemy sprite tile graphics
;
; Decompresses 87 ($57) tiles from SpriteGfxData_8287C and DMA's them
; to DmaCmd_CaveEnemyGfx.  Same source as LoadBattleEnemyTileGraphics
; but targets a different DMA command / VRAM destination.
;
; Input:   (none)  Scratch:  D5, A0, A2  Output:   VRAM cave enemy tile slot loaded
; ---------------------------------------------------------------------------
LoadCaveEnemyTileGraphics:
	LEA	SpriteGfxData_8287C, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$0056, D5
LoadCaveEnemyTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadCaveEnemyTileGraphics_Done
	LEA	DmaCmd_CaveEnemyGfx, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
; ---------------------------------------------------------------------------
; LoadCaveItemTileGraphics — load cave item/chest tile graphics
;
; Decompresses 94 ($5E) tiles from LoadCaveItemTileGraphics_Data and DMA's
; them to DmaCmd_CaveItemGfx.
;
; Input:   (none)  Scratch:  D5, A0, A2  Output:   VRAM cave item tile slot loaded
; ---------------------------------------------------------------------------
LoadCaveItemTileGraphics:
	LEA	LoadCaveItemTileGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$005D, D5
LoadCaveItemTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadCaveItemTileGraphics_Done
	LEA	DmaCmd_CaveItemGfx, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
; ---------------------------------------------------------------------------
; LoadBattlePlayerTileGraphics — load player sprite tile graphics for battle
;
; Decompresses 80 ($50) tiles from LoadBattlePlayerTileGraphics_Data and
; DMA's them to DmaCmd_BattlePlayerGfx.
;
; Input:   (none)  Scratch:  D5, A0, A2  Output:   VRAM battle player tile slot loaded
; ---------------------------------------------------------------------------
LoadBattlePlayerTileGraphics:
	LEA	LoadBattlePlayerTileGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$004F, D5
LoadBattlePlayerTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattlePlayerTileGraphics_Done
	LEA	DmaCmd_BattlePlayerGfx, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
; ---------------------------------------------------------------------------
; LoadTownTileGfxSet1   — load tile GFX set 1 from LoadTownTileGfxSet1_Data
; LoadTownTileGfxToBuffer — decompress and DMA full town tile GFX set (5 groups)
;
; LoadTownTileGfxSet1 sets A0 to a fixed data pointer then falls through to
; LoadTownTileGfxToBuffer, which loads 5 tile groups into VRAM:
;   Group A: 183 tiles → DmaCmd_TownTileGfxSet1_A
;   Group B: 218 tiles → DmaCmd_TownTileGfxSet1_B
;   Group C: 108 tiles (NPCs) → DmaCmd_TownNpcGfx
;   Group D: 158 tiles → DmaCmd_TownTileGfxSet1_D
;   Group E:  42 tiles → DmaCmd_TownTileGfxSet1_E
;
; Input:   (none)  Scratch:  D5, A0, A2  Output:   VRAM town tile GFX set 1 loaded
; ---------------------------------------------------------------------------
LoadTownTileGfxSet1:
	LEA	LoadTownTileGfxSet1_Data, A0
LoadTownTileGfxToBuffer:
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$00B6, D5
LoadTownTileGfxToBuffer_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTownTileGfxToBuffer_Done
	LEA	DmaCmd_TownTileGfxSet1_A, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadTownTileGfxToBuffer_Done_Data, A0
	MOVE.w	#$00D9, D5
LoadTownTileGfxToBuffer_Done2:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTownTileGfxToBuffer_Done2
	LEA	DmaCmd_TownTileGfxSet1_B, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	Tile_gfx_buffer.w, A2
	LEA	SpriteGfxData_607AA, A0
	MOVE.w	#$006B, D5
LoadTownTileGfxToBuffer_Done3:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTownTileGfxToBuffer_Done3
	LEA	DmaCmd_TownNpcGfx, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadTownTileGfxToBuffer_Done3_Data, A0
	MOVE.w	#$009D, D5
LoadTownTileGfxToBuffer_Done4:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTownTileGfxToBuffer_Done4
	LEA	DmaCmd_TownTileGfxSet1_D, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadTownTileGfxToBuffer_Done4_Data, A0
	MOVE.w	#$0029, D5
LoadTownTileGfxToBuffer_Done5:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTownTileGfxToBuffer_Done5
	LEA	DmaCmd_TownTileGfxSet1_E, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
; ---------------------------------------------------------------------------
; LoadMenuTileGraphics — load all menu tile graphics to VRAM
;
; Loads 6 tile groups into VRAM:
;   Group A: 256 tiles → DmaCmd_MenuTilesA
;   Group B: 256 tiles → DmaCmd_MenuTilesB
;   Group C: 108 NPC tiles → DmaCmd_TownNpcGfx  (shared with town)
;   Group D:  27 misc tiles → DmaCmd_MenuMiscTilesA
;   Group E:   8 misc tiles → DmaCmd_MenuMiscTilesB
; LoadMenuTileGfxSet2 and LoadMenuTileGfxSet3 are mid-function entry points
; that skip groups A and B respectively.
;
; Input:   (none)  Scratch:  D5, A0, A2  Output:   VRAM menu tile areas loaded
; ---------------------------------------------------------------------------
LoadMenuTileGraphics:
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadMenuTileGraphics_Data, A0
	MOVE.w	#$00FF, D5
LoadMenuTileGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadMenuTileGraphics_Done
	LEA	DmaCmd_MenuTilesA, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadMenuTileGraphics_Done_Data, A0
	MOVE.w	#$00FF, D5
LoadMenuTileGraphics_Done2:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadMenuTileGraphics_Done2
	LEA	DmaCmd_MenuTilesB, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	Tile_gfx_buffer.w, A2
LoadMenuTileGfxSet2:
	LEA	SpriteGfxData_607AA, A0
LoadMenuTileGfxSet3:
	MOVE.w	#$006B, D5
LoadMenuTileGfxSet3_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadMenuTileGfxSet3_Done
	LEA	DmaCmd_TownNpcGfx, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadMenuTileGfxSet3_Done_Data, A0
	MOVE.w	#$001A, D5
LoadMenuTileGfxSet3_Set2Loop:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadMenuTileGfxSet3_Set2Loop
	LEA	DmaCmd_MenuMiscTilesA, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	Tile_gfx_buffer.w, A2
	LEA	LoadMenuTileGfxSet3_Set2Data, A0
	MOVE.w	#7, D5
LoadMenuTileGfxSet3_Done3:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadMenuTileGfxSet3_Done3
	LEA	DmaCmd_MenuMiscTilesB, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
; ---------------------------------------------------------------------------
; LoadTitleScreenGraphics — load all title screen tile graphics to VRAM
;
; Loads 6 tile groups into VRAM:
;   Group A: 78  tiles → DmaCmd_TitleScreenTilesA
;   Group B: 109 tiles → DmaCmd_TitleScreenTilesB
;   Group C:  99 tiles → DmaCmd_TitleScreenTilesC
;   Group D:  80 tiles → DmaCmd_TitleScreenTilesD
;   Group E:  82 tiles → DmaCmd_TitleScreenTilesE
;   Group F:   6 tiles → DmaCmd_TitleScreenTilesF
; LoadTitleScreenTileGfx is a mid-function entry that skips groups A-D.
;
; Input:   (none)  Scratch:  D5, A0, A2  Output:   VRAM title screen tile areas loaded
; ---------------------------------------------------------------------------
LoadTitleScreenGraphics:
	LEA	LoadTitleScreenGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$004D, D5
LoadTitleScreenGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTitleScreenGraphics_Done
	LEA	DmaCmd_TitleScreenTilesA, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	LoadTitleScreenGraphics_Done_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$006C, D5
LoadTitleScreenGraphics_Set2Loop:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTitleScreenGraphics_Set2Loop
	LEA	DmaCmd_TitleScreenTilesB, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	LoadTitleScreenGraphics_Set2Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$0062, D5
LoadTitleScreenGraphics_Done3:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTitleScreenGraphics_Done3
	LEA	DmaCmd_TitleScreenTilesC, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	LoadTitleScreenGraphics_Done3_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$004F, D5
LoadTitleScreenGraphics_Done4:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTitleScreenGraphics_Done4
	LEA	DmaCmd_TitleScreenTilesD, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	LoadTitleScreenGraphics_Done4_Data, A0
LoadTitleScreenTileGfx:
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$0051, D5
LoadTitleScreenTileGfx_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTitleScreenTileGfx_Done
	LEA	DmaCmd_TitleScreenTilesE, A0
	BSR.w	ExecuteVdpDmaFromRam
	LEA	LoadTitleScreenTileGfx_Done_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#5, D5
LoadTitleScreenTileGfx_Done2:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadTitleScreenTileGfx_Done2
	LEA	DmaCmd_TitleScreenTilesF, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
; ---------------------------------------------------------------------------
; LoadOptionsMenuGraphics — load options menu tile graphics to VRAM
;
; Decompresses 61 ($3D) tiles from LoadOptionsMenuGraphics_Data and DMA's
; them to DmaCmd_OptionsMenuTiles.
;
; Input:   (none)  Scratch:  D5, A0, A2  Output:   VRAM options menu tile slot loaded
; ---------------------------------------------------------------------------
LoadOptionsMenuGraphics:
	LEA	LoadOptionsMenuGraphics_Data, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	#$003C, D5
LoadOptionsMenuGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadOptionsMenuGraphics_Done
	LEA	DmaCmd_OptionsMenuTiles, A0
	BSR.w	ExecuteVdpDmaFromRam
	RTS
	
; ExecuteVdpDmaFromRam
; Execute VDP DMA transfer from RAM to VRAM
; Input: A0 = Pointer to DMA command data (destination, length, source)
; NOTE: This function is byte-for-byte identical to ExecuteVdpDmaFromPointer above.
;       Both exist in the original ROM binary. ExecuteVdpDmaFromRam is used for ~29
;       DMA transfers; ExecuteVdpDmaFromPointer is used for ~4 town/HUD tile loads.
ExecuteVdpDmaFromRam:
	ORI	#$0700, SR
	stopZ80
	BSR.w	InitVdpDmaRamRoutine
	MOVE.w	#2, D4
	ORI.w	#$8F00, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.l	(A0)+, VDP_control_port
	MOVE.l	(A0)+, VDP_control_port
	MOVE.w	(A0)+, VDP_control_port
	MOVE.l	(A0)+, Vdp_dma_cmd.w
	JSR	Vdp_dma_ram_routine.w
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	#0, Z80_bus_request
	ANDI	#$F8FF, SR
	RTS
	
; -----------------------------------------------------------------------
; InitVdpDmaRamRoutine / VdpDmaRoutineTemplate
;
; The VDP DMA-start trigger requires two consecutive 16-bit writes to the
; VDP control port ($C00004). A 68000 MOVE.l to a memory-mapped I/O port
; does NOT reliably produce two separate command words. To work around this,
; the game uses SELF-MODIFYING CODE: a tiny 3-instruction subroutine is
; stored as raw bytes in ROM (VdpDmaRoutineTemplate), copied into RAM at
; Vdp_dma_ram_routine ($FFFFC190) by InitVdpDmaRamRoutine, and then called
; via JSR Vdp_dma_ram_routine.w.
;
; The stub does the following when called:
;   MOVE.w  Vdp_dma_cmd.w ($FFFFC18C), VDP_control_port    ; cmd word lo
;   MOVE.w  Vdp_dma_cmd_hi.w ($FFFFC18E), VDP_control_port ; cmd word hi
;   RTS
;
; Callers preload the 32-bit VDP destination-address command (with DMA-enable
; bit set) into Vdp_dma_cmd ($FFFFC18C) using MOVE.l before calling the stub.
; Vdp_dma_cmd_hi ($FFFFC18E) overlaps the upper half of Vdp_dma_cmd.
;
; The stub is re-copied on every top-level DMA call (not cached). This is safe
; because the template is read-only and never modified.
;
; The sub-label InitVdpDmaRamRoutine_CopyLoop is vestigial — there is no loop;
; the copy is fully unrolled: 4× MOVE.l (16 bytes) + 1× MOVE.w (2 bytes) = 18.
;
; Template bytes decoded:
;   $33F8 C18C 00C0 0004  = MOVE.w $FFFFC18C.w, $00C00004.l  (cmd lo → VDP ctrl)
;   $33F8 C18E 00C0 0004  = MOVE.w $FFFFC18E.w, $00C00004.l  (cmd hi → VDP ctrl)
;   $4E75                 = RTS
; -----------------------------------------------------------------------
InitVdpDmaRamRoutine:
	LEA	VdpDmaRoutineTemplate, A2
InitVdpDmaRamRoutine_CopyLoop:
	LEA	Vdp_dma_ram_routine.w, A3
	MOVE.l	(A2)+, (A3)+
	MOVE.l	(A2)+, (A3)+
	MOVE.l	(A2)+, (A3)+
	MOVE.l	(A2)+, (A3)+
	MOVE.w	(A2)+, (A3)+
	RTS
	
; 18-byte ROM template that is copied into RAM and executed as a subroutine.
; See InitVdpDmaRamRoutine above for full explanation.
; Decoded: MOVE.w Vdp_dma_cmd, VDP_ctrl / MOVE.w Vdp_dma_cmd_hi, VDP_ctrl / RTS
VdpDmaRoutineTemplate:
	dc.l	$33F8C18C	; MOVE.w $FFFFC18C.w, ...
	dc.l	$00C00004	; ... $00C00004.l  (cmd lo word → VDP control port)
	dc.l	$33F8C18E	; MOVE.w $FFFFC18E.w, ...
	dc.l	$00C00004	; ... $00C00004.l  (cmd hi word → VDP control port)
	dc.w	$4E75 		; RTS
; ---------------------------------------------------------------------------
; VDP_DMAFill — fill VRAM with a single byte value via DMA fill mode
;
; Performs a VDP DMA fill: fills D6.w bytes of VRAM starting at the address
; encoded in D7.l with the byte value in D5.b.  Waits for the DMA busy flag
; to clear before returning.
;
; Input:
;   D5.b  fill byte value
;   D6.w  fill length in bytes
;   D7.l  VRAM destination address (bits set for DMA fill command word)
;
; Scratch:  D4
; Output:   VRAM region filled; VDP DMA mode restored
; ---------------------------------------------------------------------------
VDP_DMAFill:
	ORI	#$0700, SR
	ORI.w	#$8F00, D4			; VDP reg 15: auto-increment = D4 (caller-supplied)
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4				; Set bit 4 = enable DMA in reg 1
	MOVE.w	D4, VDP_control_port
	MOVE.l	#$00940000, D4			; Template for regs 19-20 (DMA length)
	MOVE.w	D6, D4				; D6 = fill length
	LSL.l	#8, D4				; Shift length high byte into reg 20 position
	MOVE.w	#$9300, D4			; VDP reg 19 template (DMA length low)
	MOVE.b	D6, D4				; Merge length low byte
	MOVE.l	D4, VDP_control_port		; Write regs 19+20 (DMA length)
	MOVE.w	#$9780, VDP_control_port	; VDP reg 23 = $80: DMA mode = VRAM fill
	ORI.l	#$40000080, D7			; Set VRAM write + DMA CD bits
	MOVE.l	D7, Vdp_dma_cmd.w
	MOVE.w	Vdp_dma_cmd.w, VDP_control_port	; Write DMA command (low word first)
	MOVE.w	Vdp_dma_cmd_hi.w, VDP_control_port	; Write DMA command (high word triggers DMA)
	MOVE.b	D5, VDP_data_port		; Fill value byte
VDP_DMAFill_Done:
	MOVE.w	VDP_control_port, D4		; Read VDP status
	BTST.l	#1, D4				; Check DMA busy bit
	BNE.b	VDP_DMAFill_Done		; Wait until DMA completes
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4				; Clear DMA enable bit
	MOVE.w	D4, VDP_control_port		; Restore reg 1
	MOVE.w	#$8F02, VDP_control_port	; VDP reg 15 = 2: restore auto-increment
	ANDI	#$F8FF, SR
	RTS
	
Z80SoundDriver_Data_10480:
	dc.b	$76, $00, $02, $80, $00, $00, $00, $FF, $60, $00, $00, $1A 
; ---------------------------------------------------------------------------
; ConvertToBCD — convert a 16-bit binary number (0–99999) to 5-digit BCD
;
; Extracts digits by successive division and accumulates them into D3 as
; packed BCD (each nibble = one decimal digit, MSD in the highest nibble).
;
; MOVE-003 NOTE: This is a numeric conversion utility; it belongs in core.asm.
; Called 23+ times from script.asm and items.asm.
; Physical move would change all JSR/BSR displacements and break bit-perfect.
;
; Input:
;   D0.w  binary value (0–99999; upper word ignored)
;
; Scratch:  D1, D3
; Output:   D0.l = 5-digit BCD (e.g. 12345 → $00012345)
; ---------------------------------------------------------------------------
ConvertToBCD:
	MOVEQ	#0, D3
	ANDI.l	#$0000FFFF, D0
	MOVE.w	#$2710, D1		; 10000
	BSR.w	ExtractBCDDigit
	MOVE.w	#$03E8, D1		; 1000
	BSR.w	ExtractBCDDigit
	MOVE.w	#$0064, D1		; 100
	BSR.w	ExtractBCDDigit
	MOVE.w	#$000A, D1		; 10
	BSR.w	ExtractBCDDigit
	OR.b	D0, D3			; Ones digit
	MOVE.l	D3, D0
	RTS
	
; ---------------------------------------------------------------------------
; ExtractBCDDigit — extract one BCD decimal digit by division
;
; Divides D0.w by D1.w (the place value: 10000, 1000, 100, 10) to get one
; digit, ORs it into D3 as a nibble (LSB), then shifts D3 left by 4 for
; the next digit.  The remainder is kept in D0 for the next call.
;
; MOVE-003 NOTE: Helper for ConvertToBCD; both belong in core.asm.
; Physical move would change all BSR displacements and break bit-perfect.
;
; Input:
;   D0.w  current value
;   D1.w  divisor (place value)
;   D3.l  accumulated BCD (new digit OR'd into LSB, then shifted)
;
; Scratch:  (none)
; Output:   D0.w = remainder; D3.l updated
; ---------------------------------------------------------------------------
ExtractBCDDigit:
	DIVU.w	D1, D0
	OR.b	D0, D3
	LSL.l	#4, D3
	ANDI.l	#Tilemap_buffer_plane_a, D0
	SWAP	D0
	RTS
	
; ---------------------------------------------------------------------------
; DetermineTerrainTileset — pick overworld battle terrain tileset by tile type
;
; Samples a 3×3 region of the overworld sector map centered on the player's
; current position (Map_sector_center), counts "forest" (type 1) and "water"
; (type 2) tiles via CountTerrainTileType.  If water tiles outnumber forest,
; sets Terrain_tileset_index to TERRAIN_TILESET_FIELD (0); otherwise leaves
; the index at 0 (the caller pre-clears it).
;
; MOVE-005 NOTE: Terrain/map logic; belongs in gameplay.asm.
; Also called internally via BSR.w from battle_gfx.asm:953 — moving it would
; require changing that call to JSR and all other site displacements, breaking
; bit-perfect.
;
; Input:   (via RAM)
;   Player_position_x_outside_town.w, Player_position_y_outside_town.w
;
; Scratch:  D0-D2, D6-D7, A0, A2
; Output:   Terrain_tileset_index.w set
; ---------------------------------------------------------------------------
DetermineTerrainTileset:
	CLR.w	Terrain_tileset_index.w
	LEA	Map_sector_center.w, A0
	MOVE.w	Player_position_x_outside_town.w, D0
	MOVE.w	Player_position_y_outside_town.w, D1
	SUBQ.w	#1, D0
	SUBQ.w	#1, D1
	MULU.w	#$0030, D1
	ADD.w	D0, D1
	LEA	(A0,D1.w), A2
	CLR.w	D1
	CLR.w	D2
	MOVEQ	#2, D7
DetermineTerrainTileset_Done:
	MOVEQ	#2, D6
DetermineTerrainTileset_Done2:
	MOVE.b	(A2)+, D0
	BSR.w	CountTerrainTileType
	DBF	D6, DetermineTerrainTileset_Done2
	LEA	$2D(A2), A2
	DBF	D7, DetermineTerrainTileset_Done
	CMP.w	D2, D1
	BGE.b	DetermineTerrainTileset_Loop
	MOVE.w	#TERRAIN_TILESET_FIELD, Terrain_tileset_index.w
DetermineTerrainTileset_Loop:
	RTS
	
; ---------------------------------------------------------------------------
; CountTerrainTileType — tally forest (1) and water (2) tile counts
;
; Helper for DetermineTerrainTileset.  Increments D1 if D0=1 (forest),
; increments D2 if D0=2 (water/field).
;
; Input:
;   D0.b  tile type byte
;   D1.w  forest tile count accumulator
;   D2.w  water tile count accumulator
;
; Scratch:  (none)
; Output:   D1 or D2 incremented
; ---------------------------------------------------------------------------
CountTerrainTileType:
	CMPI.b	#1, D0
	BNE.b	CountTerrainTileType_Loop
	ADDQ.w	#1, D1
	BRA.b	CountDialogBytes_Return
CountTerrainTileType_Loop:
	CMPI.b	#2, D0
	BNE.b	CountDialogBytes_Return
	ADDQ.w	#1, D2
CountDialogBytes_Return:
	RTS
	
; ---------------------------------------------------------------------------
; QueueSoundEffect — push a sound effect ID onto the sound queue
;
; NOTE: Physically located in battle_gfx.asm due to original ROM layout.
; Logically belongs in sound.asm.  Cannot be moved without breaking
; bit-perfect output.  See MOVE-004.
;
; Checks Sound_queue_count; if the queue has room (< 8), appends D0.b to
; Sound_queue_buffer and increments the count.
;
; Input:
;   D0.b  sound effect ID
;
; Scratch:  D1, A0
; Output:   sound ID appended to queue (if not full)
; ---------------------------------------------------------------------------
QueueSoundEffect:
	MOVE.w	Sound_queue_count.w, D1
	CMPI.w	#8, D1
	BGE.b	QueueSoundEffect_Loop
	LEA	Sound_queue_buffer.w, A0
	MOVE.b	D0, (A0,D1.w)
	ADDQ.w	#1, Sound_queue_count.w
QueueSoundEffect_Loop:
	RTS
	
; ---------------------------------------------------------------------------
; LoadBattleTilesToVram — DMA tile sets for current battle type to VRAM
;
; Looks up a list pointer from BattleTileDataPtrs using Battle_type.w.
; Each list entry has the same format as a ProcessGraphicsLoadList record
; (slot word, A4 ptr, A3 ptr, tile count).  Processes entries until the
; slot word is negative.
;
; Input:   (via RAM)  Battle_type.w
; Scratch:  D0, D5, A2, A3, A4, A6
; Output:   VRAM battle tile slots loaded per BattleTileDataPtrs list
; ---------------------------------------------------------------------------
LoadBattleTilesToVram:
	LEA	BattleTileDataPtrs, A6
	MOVE.w	Battle_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A6,D0.w), A6
LoadBattleTilesToVram_Done:
	MOVE.w	(A6)+, D0
	BLT.b	LoadBattleTilesToVram_Loop
	MOVE.w	D0, Vdp_dma_slot_index.w
	LEA	Tile_gfx_buffer.w, A2
	MOVEA.l	(A6)+, A4
	MOVEA.l	(A6)+, A3
	MOVE.w	(A6)+, D5
	BSR.w	LoadMultipleTilesFromTable
	BSR.w	ExecuteVdpDmaTransfer
	BRA.b	LoadBattleTilesToVram_Done
LoadBattleTilesToVram_Loop:
	RTS
	
; ---------------------------------------------------------------------------
; LoadBattleGraphics — decompress and DMA a single-source battle tile set
;
; Reads Battle_type.w, looks up a record in BattleGfxDataPtrs. The record
; contains: source pointer (long), tile count (word), DMA command pointer
; (long). If the source pointer is null (0), the function returns without
; doing anything.
;
; Input:   (via RAM)
;   Battle_type.w  — index into BattleGfxDataPtrs
;
; Scratch:  D5, A0, A2, A6
; Output:   VRAM tile slot populated for this battle type (if source != null)
; ---------------------------------------------------------------------------
LoadBattleGraphics:
	LEA	BattleGfxDataPtrs, A6
	MOVE.w	Battle_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A6,D0.w), A6
	TST.l	(A6)
	BEQ.b	LoadBattleGraphics_Loop
	MOVEA.l	(A6)+, A0
	LEA	Tile_gfx_buffer.w, A2
	MOVE.w	(A6)+, D5
LoadBattleGraphics_Done:
	BSR.w	DecompressTileGraphics
	LEA	$20(A2), A2
	DBF	D5, LoadBattleGraphics_Done
	MOVEA.l	(A6), A0
	BSR.w	ExecuteVdpDmaFromRam
LoadBattleGraphics_Loop:
	RTS
	
