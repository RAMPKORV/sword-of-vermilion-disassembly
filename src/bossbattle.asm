; ======================================================================
; src/bossbattle.asm
;
; Contents (ROM layout order):
;   1. Area/cave map rendering
;        CheckOverworldSectorMapRevealed  — set Area_map_revealed flag
;        CheckCaveRoomMapRevealed         — cave-room variant
;        LoadMapSector_FillDefault        — fill 16×16 grid with tree tiles
;        RenderAreaMap                    — blit 16×16 map icons to Plane A
;        UpdateAreaVisibility             — apply fog-of-war overlay on Plane B
;        UpdateCaveLightTimer             — count down torch/light duration
;   2. Wall-rendering data tables
;        WallTilemap_NearFront / NearSide — tile IDs for near wall faces
;        WallTileGfxPtrs                 — wall gfx pointer table (4 sets × 8 entries)
;        WallTileOffsets_*               — signed (delta_row, delta_col) pairs for
;                                          8 orientations × 14 perspective depths
;        FpObjectTileTable_Near/Mid/Far  — first-person object sprite tile offsets
;        WallRenderVdpParams_*           — VDP VRAM write commands for Near/Mid/Far panels
;        WallTileMidGfxPtrs             — gfx pointer table for mid-distance walls
;        FpSpritePositionTable           — (screen_x, screen_y) pairs for FP sprites
;   3. Boss battle player/weapon/shield tick objects
;        BossBattlePlayerInit            — set up player + weapon + shield entities
;        BossBattlePlayerTick_Intro      — walk-in animation (NTSC/PAL-aware)
;        BossBattlePlayerTick_Active     — real-time input: move, attack, clamp
;        BossBattleExitCleanup           — tear down entities, set exit state
;        BossBattleEntityNullTick        — placeholder tick (entity stays visible)
;        BossBattleWeaponTick            — weapon sprite tracks player position
;        BossBattleShieldTick            — shield sprite offset from player frame
;   4. Collision detection
;        DispatchBattleCollisionChecks   — route to per-boss collision handler
;        BossCollisionJumpTable          — BRA.w entries for 14 battle types
;        BossCollision_Standard          — check enemy + slot 2
;        BossCollision_MultiBody         — check slots 2-5 + fixed arena region
;        BossCollision_SingleTarget      — check enemy slot only
;        BossCollision_SingleTargetAlt   — alternate single-target (same logic)
;        BossCollision_MultiBodyAll      — check enemy + slots 2-9
;        BossCollision_FinalBoss         — check slots 1/3 + fixed arena region
;        CheckObjectCollisionBounds      — AABB test for one object
;        GetBoundingBoxFromTable         — load weapon hitbox from NPCBoundingBoxTable
;        CheckFixedAreaCollision         — test against a hard-coded arena rect
;        NPCBoundingBoxTable             — 10 hitbox entries (right, left, bottom, top)
;   5. Town NPC loading
;        LoadTownNPCs                    — initialize up to 30 NPC slots from data
;        ClearAllNPCSlots                — clear all 30 NPC active flags (dead code)
;
; VDP notes:
;   $40AE0003  VRAM write command: Plane A ($C000) + $AE bytes offset
;              = nametable row 0, col $57 — top-left of the 16×16 area map window
;   $60AE0003  VRAM write command: Plane B ($E000) + $AE bytes offset
;              = same position on the scroll-B overlay (fog-of-war layer)
;   ADDI.l #$00800000, Dx  advance VDP write address by one nametable row (128 bytes)
; ======================================================================

; ---------------------------------------------------------------------------
; CheckOverworldSectorMapRevealed
;
; Sets Area_map_revealed = FLAG_TRUE if the current overworld sector has been
; visited.  The trigger flag index is computed as:
;   index = Player_map_sector_x + Player_map_sector_y * 16
; which tiles into Map_trigger_flags[], an array of per-sector visit bytes.
;
; Output:  Area_map_revealed.w — FLAG_TRUE if sector was previously visited
; Scratch: D0, D1, A0
; ---------------------------------------------------------------------------
CheckOverworldSectorMapRevealed:
	CLR.b	Area_map_revealed.w
	MOVE.w	Player_map_sector_x.w, D0
	MOVE.w	Player_map_sector_y.w, D1
	ASL.w	#4, D1
	ADD.w	D1, D0
	LEA	Map_trigger_flags.w, A0
	MOVE.b	(A0,D0.w), D0
	BEQ.b	CheckOverworldSectorMapRevealed_Loop
	MOVE.b	#FLAG_TRUE, Area_map_revealed.w
CheckOverworldSectorMapRevealed_Loop:
	RTS

CheckCaveRoomMapRevealed:
	CLR.b	Area_map_revealed.w
	MOVE.w	Current_cave_room.w, D0
	ADDI.w	#$0090, D0
	LEA	Map_trigger_flags.w, A0
	MOVE.b	(A0,D0.w), D0
	BEQ.b	CheckCaveRoomMapRevealed_Loop
	MOVE.b	#FLAG_TRUE, Area_map_revealed.w
CheckCaveRoomMapRevealed_Loop:
	RTS

; ---------------------------------------------------------------------------
; LoadMapSector_FillDefault
;
; Fills the 16×16 map sector grid (pointed to by A2) with tile $01 (trees).
; Writes 4 bytes per inner iteration × 4 iterations = 16 bytes per row,
; for 16 rows = 256 bytes total.  Each row in the sector grid is $30 (48)
; bytes apart in RAM (stride includes padding for a wider map buffer).
;
; Input:   A2 — pointer to top-left of sector grid in RAM
; Scratch: A2, A3, D6, D7
; ---------------------------------------------------------------------------
LoadMapSector_FillDefault:
	MOVEQ	#$F, D7                 ; 16 rows (0..15)
LoadMapSector_FillDefault_OuterLoop:
	LEA	(A2), A3
	MOVEQ	#3, D6                  ; 4 longwords per row (16 bytes)
LoadMapSector_FillDefault_InnerLoop:
	MOVE.l	#$01010101, (A3)+ ; Fill map data with trees
	DBF	D6, LoadMapSector_FillDefault_InnerLoop
	LEA	$30(A2), A2             ; advance to next row ($30 = 48 byte row stride)
	DBF	D7, LoadMapSector_FillDefault_OuterLoop
	RTS

; ---------------------------------------------------------------------------
; RenderAreaMap
;
; Blits the 16×16 area map icon grid to Plane A of the VDP nametable.
; Each map tile byte is looked up in WallTilemap_NearFront (overworld) or
; WallTilemap_NearSide (cave) to obtain the tile attribute word written to
; the VDP data port.
;
; VDP write address starts at $40AE0003 (Plane A + $AE byte offset = col $57,
; row 0 of the area map display window).  Each row is advanced by $00800000
; (128 bytes = 64 tiles × 2 bytes per tile attribute).
;
; Byte values $00–$0F are written directly as tile indices.
; Bytes $10–$7F are cave-entrance tiles → clamped to FP_RENDER_DOOR.
; Bytes $80–$8F (signed negative, < OVERWORLD_TILE_UPPER_CAVE_MIN) → zeroed.
; Bytes $90–$FF (>= OVERWORLD_TILE_UPPER_CAVE_MIN) → FP_RENDER_DOOR_UPPER.
;
; Interrupts are disabled around VDP access (ORI/ANDI SR pair).
;
; Input:   Map_sector_center.w — base of 16×16 map data in RAM
;          Is_in_cave.w        — selects NearFront vs NearSide tilemap
; Scratch: D5, D6, D7, A0, A1, A2
; ---------------------------------------------------------------------------
RenderAreaMap:
	ORI	#$0700, SR
	MOVE.l	#$40AE0003, D5
	LEA	Map_sector_center.w, A0
	LEA	WallTilemap_NearFront, A2
	TST.b	Is_in_cave.w
	BEQ.b	RenderAreaMap_Loop
	LEA	WallTilemap_NearSide, A2
RenderAreaMap_Loop:
	MOVEQ	#$F, D7
RenderAreaMap_RowLoop:
	LEA	(A0), A1
	MOVE.l	D5, VDP_control_port
	MOVEQ	#$F, D6
RenderAreaMap_ColLoop:
	CLR.w	D0
	MOVE.b	(A1)+, D0
	BLT.b	RenderAreaMap_CaveEntrance
	CMPI.b	#OVERWORLD_TILE_CAVE_MIN, D0
	BLT.b	RenderAreaMap_WriteTile
	MOVE.b	#FP_RENDER_DOOR, D0
	BRA.b	RenderAreaMap_WriteTile
RenderAreaMap_CaveEntrance:
	CMPI.b	#OVERWORLD_TILE_UPPER_CAVE_MIN, D0
	BLT.b	RenderAreaMap_UpperCaveEntrance
	MOVE.b	#FP_RENDER_DOOR_UPPER, D0
	BRA.b	RenderAreaMap_WriteTile
RenderAreaMap_UpperCaveEntrance:
	CLR.w	D0
RenderAreaMap_WriteTile:
	ADD.w	D0, D0              ; tile index × 2 (word table)
	MOVE.w	(A2,D0.w), VDP_data_port
	DBF	D6, RenderAreaMap_ColLoop
	LEA	$30(A0), A0         ; advance map pointer by one row ($30 = 48 byte stride)
	ADDI.l	#VDP_VRAM_ROW_STRIDE, D5      ; advance VDP write address by one nametable row
	DBF	D7, RenderAreaMap_RowLoop
	ANDI	#$F8FF, SR          ; re-enable interrupts
	RTS

; ---------------------------------------------------------------------------
; UpdateAreaVisibility  /  RenderCaveDarknessTilemap
;
; Fills the 16×16 fog-of-war layer (Plane B) with either:
;   D4 = $0000  — transparent (area revealed, or in lit cave)
;   D4 = $85B7  — solid black fog tile (palette 2, priority 1, tile $01B7)
;
; Logic:
;   Area revealed AND (not in cave OR cave light active) → D4 = $0000 (clear)
;   Otherwise                                           → D4 = $85B7 (fog)
;
; If fog is needed AND in cave AND cave light is off, a second pass renders
; CaveWallTileIndices (9 partial-visibility tiles) at the player's position
; on Plane B to simulate a small circle of torchlight.
;
; The torchlight tiles are positioned by adding the player's world X/Y
; (shifted into VDP address space) to the base $60AE0003, then subtracting
; $00820000 (2 rows + 2 columns) to center the 3×3 tile window.
;
; Interrupts are disabled around VDP access.
;
; Input:   Area_map_revealed.w, Is_in_cave.w, Cave_light_active.w
;          Player_position_x/y_outside_town.w
; Scratch: D4, D5, D6, D7, A0
; ---------------------------------------------------------------------------
UpdateAreaVisibility:
	CLR.w	D4
	TST.b	Area_map_revealed.w
	BEQ.b	UpdateAreaVisibility_Loop
	TST.b	Is_in_cave.w
	BEQ.b	RenderCaveDarknessTilemap
	TST.b	Cave_light_active.w
	BNE.b	RenderCaveDarknessTilemap
UpdateAreaVisibility_Loop:
	; Area not revealed or in dark cave — use solid fog tile
	; $85B7: palette 2, priority 1, tile $01B7 (full-black fog tile)
	MOVE.w	#$85B7, D4
RenderCaveDarknessTilemap:
	ORI	#$0700, SR
	MOVE.l	#VDP_CMD_VRAM_WRITE_E0AE, D5
	MOVEQ	#$0000000F, D7
RenderCaveDarknessTilemap_RowLoop:
	MOVE.l	D5, VDP_control_port
	MOVEQ	#$0000000F, D6
RenderCaveDarknessTilemap_ColLoop:
	MOVE.w	D4, VDP_data_port
	DBF	D6, RenderCaveDarknessTilemap_ColLoop
	LEA	$30(A0), A0         ; advance map pointer (unused here, kept for struct symmetry)
	ADDI.l	#VDP_VRAM_ROW_STRIDE, D5      ; advance VDP write address by one nametable row
	DBF	D7, RenderCaveDarknessTilemap_RowLoop
	ANDI	#$F8FF, SR          ; re-enable interrupts
	TST.b	Area_map_revealed.w
	BNE.w	RenderCaveWallTiles_Return
	TST.b	Is_in_cave.w
	BEQ.b	RenderCaveDarknessTilemap_Loop
	TST.b	Cave_light_active.w
	BEQ.w	RenderCaveWallTiles_Return
	; In cave, light is active: draw 3×3 torchlight patch at player position
RenderCaveDarknessTilemap_Loop:
	LEA	CaveWallTileIndices, A0 ; 9 partial-fog tile attributes (3 rows × 3 cols)
	MOVE.l	#VDP_CMD_VRAM_WRITE_E0AE, D5       ; Plane B base for area map window
	MOVEQ	#0, D0
	MOVEQ	#0, D1
	MOVE.w	Player_position_x_outside_town.w, D0
	MOVE.w	Player_position_y_outside_town.w, D1
	ADD.w	D0, D0              ; X * 2 (bytes per tile column)
	SWAP	D0                  ; shift X offset into VDP address upper word
	ASL.w	#7, D1              ; Y * 128 (bytes per nametable row)
	SWAP	D1                  ; shift Y offset into VDP address upper word
	ADD.l	D1, D0
	ADD.l	D0, D5              ; place write pointer at player tile
	SUBI.l	#$00820000, D5      ; back up 1 row + 1 col to center 3×3 patch
	ORI	#$0700, SR          ; disable interrupts
	MOVEQ	#2, D7              ; 3 rows (0..2)
RenderCaveDarknessTilemap_RowLoopB:
	MOVE.l	D5, VDP_control_port
	MOVEQ	#2, D6              ; 3 columns (0..2)
RenderCaveDarknessTilemap_ColLoopB:
	MOVE.w	(A0)+, VDP_data_port
	DBF	D6, RenderCaveDarknessTilemap_ColLoopB
	ADDI.l	#VDP_VRAM_ROW_STRIDE, D5      ; advance VDP write address by one nametable row
	DBF	D7, RenderCaveDarknessTilemap_RowLoopB
	ANDI	#$F8FF, SR          ; re-enable interrupts
RenderCaveWallTiles_Return:
	RTS

; CaveWallTileIndices — 3×3 torchlight tile attributes
; Each word: palette 2 ($85xx), priority 1, gradient tile from $AE...$B6
; Arranged as 3 rows × 3 words, read in scan order.
; Tile $AE = darkest ring, $B6 = most transparent (lightest edge)
CaveWallTileIndices:
	dc.b	$85, $AE, $85, $AF, $85, $B0, $85, $B1, $85, $B2, $85, $B3, $85, $B4, $85, $B5, $85, $B6 

; ---------------------------------------------------------------------------
; UpdateCaveLightTimer
;
; Decrements Cave_light_timer each frame.  When it reaches 0, deactivates
; the cave light, resets palettes, and redraws the fog overlay.
;
; Input:   Cave_light_timer.w
; Output:  Cave_light_active.w = 0 on expiry; palettes reset; fog redrawn
; ---------------------------------------------------------------------------
UpdateCaveLightTimer:
	MOVE.w	Cave_light_timer.w, D0
	BGT.b	UpdateCaveLightTimer_Loop
	CLR.b	Cave_light_active.w
	CLR.w	Cave_light_timer.w
	CLR.w	Palette_line_1_index.w
	CLR.w	Palette_line_2_index.w
	BSR.w	UpdateAreaVisibility
	JSR	LoadPalettesFromTable
	RTS

UpdateCaveLightTimer_Loop:
	SUBQ.w	#1, Cave_light_timer.w
	RTS

; ---------------------------------------------------------------------------
; WallTilemap_NearFront / WallTilemap_NearSide
;
; Word tables of VDP tile attribute words indexed by area map tile ID (0–15).
; Used by RenderAreaMap: tile_id × 2 → offset into one of these tables.
;
; NearFront: tile attributes for overworld map tiles (e.g. trees, road, water)
; NearSide:  tile attributes for cave interior map tiles
;
; Both tables contain 16 word entries (32 bytes).  The NearSide table starts
; mid-way through the layout due to overlapping dc.b/dc.w sequences; the
; assembler aligns them to the correct byte offsets matching the original ROM.
;
; Tile attribute word format (Genesis VDP):
;   bit 15      : priority (1 = in front of sprites at same priority)
;   bits 14-13  : palette line (0–3)
;   bit 11      : horizontal flip
;   bit 10      : vertical flip
;   bits 10-0   : VRAM tile index
; ---------------------------------------------------------------------------
WallTilemap_NearFront:
	dc.b	$04, $CA, $04, $CB, $04, $CE, $04, $CC, $04, $D1, $04, $CB, $04, $D0, $04, $C8, $04, $C9, $04, $C1, $04, $C2, $04, $C3, $04, $C4, $04, $C5, $04, $C6 
	dc.w	$04CD
WallTilemap_NearSide:
	dc.w	$04C7
	dc.b	$04, $CB, $04, $CE 
	dc.w	$04C9
	dc.b	$44, $D1 
	dc.w	$04CF
	dc.w	$04D0
	dc.w	$04C8
	dc.b	$04, $C9, $04, $C1, $04, $C2, $04, $C3, $04, $C4, $04, $C5, $04, $C6, $04, $CD 

; ---------------------------------------------------------------------------
; WallTileGfxPtrs
;
; Pointer table for first-person wall graphics data.  Indexed by dungeon
; wall-set ID × 4 (longword entries).  8 groups of 4 entries each:
;   [0] = left wall graphic    [1] = right wall graphic
;   [2] = front wall graphic   [3] = NULL_PTR (no ceiling tile at this depth)
;
; Floor tilesets (DungeonFloorTilemap_*) are interleaved to fill the null
; entries of dungeon sets that reuse the same floor graphics.
;
; Parallel table WallTileMidGfxPtrs (below) holds the mid-distance variant.
; ---------------------------------------------------------------------------
WallTileGfxPtrs:
	dc.l	WallTileGfxPtrs_Entry00
	dc.l	WallTileGfxPtrs_Entry02
	dc.l	WallTileGfxPtrs_Entry01
	dc.l	NULL_PTR	
	dc.l	DungeonFloorTilemap_82298
	dc.l	DungeonFloorTilemap_823A4
	dc.l	DungeonFloorTilemap_82354
	dc.l	NULL_PTR	
	dc.l	WallTileGfxPtrs_Entry06
	dc.l	WallTileGfxPtrs_Entry08
	dc.l	WallTileGfxPtrs_Entry07
	dc.l	NULL_PTR	
	dc.l	WallTileGfxPtrs_Entry09
	dc.l	WallTileGfxPtrs_Entry11
	dc.l	WallTileGfxPtrs_Entry10
	dc.l	NULL_PTR	
	dc.l	DungeonFloorTilemap_82298
	dc.l	DungeonFloorTilemap_823A4
	dc.l	DungeonFloorTilemap_82354
	dc.l	NULL_PTR	
	dc.l	WallTileGfxPtrs_Entry03
	dc.l	WallTileGfxPtrs_Entry05
	dc.l	WallTileGfxPtrs_Entry04
	dc.l	NULL_PTR	
	dc.l	WallTileGfxPtrs_Entry15
	dc.l	WallTileGfxPtrs_Entry17
	dc.l	WallTileGfxPtrs_Entry16
	dc.l	NULL_PTR	
	dc.l	WallTileGfxPtrs_Entry12
	dc.l	WallTileGfxPtrs_Entry14
	dc.l	WallTileGfxPtrs_Entry13
	dc.l	NULL_PTR	
WallTileOffsets_UpLeft:
; ---------------------------------------------------------------------------
; WallTileOffsets_* tables
;
; Twelve tables of signed (delta_row, delta_col) byte pairs for first-person
; wall rendering.  Each pair offsets into the source wall tile graphic to
; determine which tile sub-region to copy.
;
; Table layout: 14 entries × 2 bytes each = 28 bytes per table.
; (LeftUp/LeftDown/RightUp/RightDown have only 10 entries = 20 bytes.)
;
; The 14 perspectives correspond to the 14 visible wall positions in the
; first-person view (near front × 16 cols, mid-walls, far-walls, corners).
;
; Byte pairs are signed: $FF,$D0 = (-1, -48) meaning 1 tile row up and
; 48 columns left in the source tile sheet.
;
; Orientation naming convention:
;   UpLeft/UpRight/DownLeft/DownRight  = north-facing wall corners
;   LeftUp/LeftDown/RightUp/RightDown  = east/west-facing wall edges
;   FarLeft/FarRight                   = far-distance side walls
;   FarUpLeft/FarDownRight             = far-distance corner walls
; ---------------------------------------------------------------------------
	dc.b	$FF, $D0, $FF, $D1, $FF, $A0, $FF, $A1, $FF, $A2, $FF, $70, $FF, $71, $FF, $72, $FF, $73, $FF, $3F, $FF, $40, $FF, $41, $FF, $42, $FF, $43 
WallTileOffsets_UpRight:
	dc.b	$00, $01, $00, $31, $00, $02, $00, $32, $00, $62, $00, $03, $00, $33, $00, $63, $00, $93, $FF, $D4, $00, $04, $00, $34, $00, $64, $00, $94 
WallTileOffsets_DownLeft:
	dc.b	$00, $30, $00, $2F, $00, $60, $00, $5F, $00, $5E, $00, $90, $00, $8F, $00, $8E, $00, $8D, $00, $C1, $00, $C0, $00, $BF, $00, $BE, $00, $BD 
WallTileOffsets_DownRight:
	dc.b	$FF, $FF, $FF, $CF, $FF, $FE, $FF, $CE, $FF, $9E, $FF, $FD, $FF, $9E, $FF, $6E, $FF, $6D, $00, $2C, $FF, $FC, $FF, $CC, $FF, $9C, $FF, $6C 
WallTileOffsets_LeftUp:
	dc.b	$00, $01, $FF, $D1, $FF, $D0, $FF, $A1, $FF, $72, $FF, $A2, $FF, $D2, $FF, $A3, $FF, $43, $FF, $74 
WallTileOffsets_LeftDown:
	dc.b	$00, $30, $00, $31, $00, $01, $00, $32, $00, $63, $00, $62, $00, $61, $00, $92, $00, $94, $00, $C3 
WallTileOffsets_RightUp:
	dc.b	$FF, $FF, $00, $2F, $00, $30, $00, $5F, $00, $8E, $00, $5E, $00, $2E, $00, $5D, $00, $BD, $00, $8C 
WallTileOffsets_RightDown:
	dc.b	$FF, $D0, $FF, $CF, $FF, $FF, $FF, $CE, $FF, $9D, $FF, $9E, $FF, $9F, $FF, $6E, $FF, $6C, $FF, $3D 
WallTileOffsets_FarLeft:
	dc.b	$00, $01, $FF, $D1, $00, $02, $FF, $D2, $FF, $A2, $00, $03, $FF, $D3, $FF, $A3, $FF, $73, $00, $34, $00, $04, $FF, $D4, $FF, $74, $FF, $74 
WallTileOffsets_FarRight:
	dc.b	$00, $30, $00, $31, $00, $60, $00, $61, $00, $62, $00, $90, $00, $91, $00, $92, $00, $93, $00, $BF, $00, $C0, $00, $C1, $00, $C2, $00, $C3 
WallTileOffsets_FarUpLeft:
	dc.b	$FF, $FF, $00, $2F, $FF, $FE, $00, $2E, $00, $5E, $FF, $FD, $00, $2D, $00, $5D, $00, $8D, $FF, $CC, $FF, $FC, $00, $2C, $00, $5C, $00, $8C 
WallTileOffsets_FarDownRight:
	dc.b	$FF, $D0, $FF, $CF, $FF, $A0, $FF, $9F, $FF, $9E, $FF, $70, $FF, $6F, $FF, $6E, $FF, $6D, $FF, $41, $FF, $40, $FF, $3F, $FF, $3E, $FF, $3D 
FpObjectTileTable_Near:
; ---------------------------------------------------------------------------
; FpObjectTileTable_Near / _Mid / _Far
;
; Word tables of VRAM tile index offsets for first-person object sprites
; (enemies, NPCs, doors, chests) at three depth levels.
;
; Each table has 11 word entries (0–10) indexed by object type/orientation.
; Entry 0 and entries 9–10 are zero (no sprite / invalid).
; Entry values are added to the base VRAM tile index for the object's sprite
; sheet to compute the actual tile to display.
;
; Near values are largest (object is closest, uses most VRAM tiles);
; Far values are smallest (object is farthest, uses fewest tiles).
; ---------------------------------------------------------------------------
	dc.b	$00, $00, $00, $34, $00, $B8, $01, $C0, $01, $3C, $00, $34, $00, $B8, $01, $3C, $01, $C0, $00, $00, $00, $00 
FpObjectTileTable_Mid:
	dc.b	$00, $00, $00, $70, $00, $F4, $01, $FC, $01, $78, $00, $70, $00, $F4, $01, $78, $01, $FC, $00, $00, $00, $00 
FpObjectTileTable_Far:
	dc.b	$00, $00, $00, $8E, $01, $12, $02, $1A, $01, $96, $00, $8E, $01, $12, $01, $96, $02, $1A, $00, $00, $00, $00 
WallRenderVdpParams_Near:
; ---------------------------------------------------------------------------
; WallRenderVdpParams_Near / _Mid / _Far
;
; VDP control-port command longwords for the four first-person wall panels
; at each of the three depth levels.  Stored as dc.b sequences matching the
; raw byte layout of the VDP longword (big-endian).
;
; Each entry is 4 bytes = one VDP VRAM write command longword.
; Four entries per distance level (4 panels: top-left, bottom-left,
; top-right, bottom-right of the visible wall face).
;
; Decoded VRAM addresses (Plane B, $E000 base):
;   Near: $E2F6, $E17C, $E1FA, $E278  (central wall region)
;   Mid:  $E30C, $E18C, $E20C, $E28C  (mid-distance wall)
;   Far:  $E322, $E19C, $E21E, $E2A0  (far-distance wall)
; ---------------------------------------------------------------------------
	dc.b	$62, $F6, $00, $03, $61, $7C, $00, $03, $61, $FA, $00, $03, $62, $78, $00, $03 
WallRenderVdpParams_Mid:
	dc.b	$63, $0C, $00, $03, $61, $8C, $00, $03, $62, $0C, $00, $03, $62, $8C, $00, $03 
WallRenderVdpParams_Far:
	dc.b	$63, $22, $00, $03, $61, $9C, $00, $03, $62, $1E, $00, $03, $62, $A0, $00, $03 
WallTileMidGfxPtrs:
	dc.l	WallTileMidGfxPtrs_Entry00
	dc.l	WallTileMidGfxPtrs_Entry01
	dc.l	WallTileMidGfxPtrs_Entry02
	dc.l	WallTileMidGfxPtrs_Entry03
	dc.l	DungeonFloorTilemap_82030
	dc.l	DungeonFloorTilemap_820CA
	dc.l	DungeonFloorTilemap_82164
	dc.l	DungeonFloorTilemap_821FE
	dc.l	WallTileMidGfxPtrs_Entry08
	dc.l	WallTileMidGfxPtrs_Entry09
	dc.l	WallTileMidGfxPtrs_Entry10
	dc.l	WallTileMidGfxPtrs_Entry11
	dc.l	WallTileMidGfxPtrs_Entry12
	dc.l	WallTileMidGfxPtrs_Entry13
	dc.l	WallTileMidGfxPtrs_Entry14
	dc.l	WallTileMidGfxPtrs_Entry15
	dc.l	DungeonFloorTilemap_82030
	dc.l	DungeonFloorTilemap_820CA
	dc.l	DungeonFloorTilemap_82164
	dc.l	DungeonFloorTilemap_821FE
	dc.l	WallTileMidGfxPtrs_Entry04
	dc.l	WallTileMidGfxPtrs_Entry05
	dc.l	WallTileMidGfxPtrs_Entry06
	dc.l	WallTileMidGfxPtrs_Entry07
	dc.l	WallTileMidGfxPtrs_Entry20
	dc.l	WallTileMidGfxPtrs_Entry21
	dc.l	WallTileMidGfxPtrs_Entry22
	dc.l	WallTileMidGfxPtrs_Entry23
	dc.l	WallTileMidGfxPtrs_Entry16
	dc.l	WallTileMidGfxPtrs_Entry17
	dc.l	WallTileMidGfxPtrs_Entry18
	dc.l	WallTileMidGfxPtrs_Entry19
FpSpritePositionTable:
; ---------------------------------------------------------------------------
; FpSpritePositionTable
;
; Screen (X, Y) byte pairs for first-person sprite placement at 8 positions.
; Indexed by slot/orientation; consumed by the FP sprite drawing code.
; Format: dc.b screen_x_hi, screen_x_lo, screen_y_hi, screen_y_lo  (signed words)
; Entry 0: ($044C, $0220) = (1100, 544)  — far center
; Entry 1: ($0670, $0770) = (1648, 1904) — near right
; ... etc.
; ---------------------------------------------------------------------------
	dc.b	$04, $4C, $02, $20, $06, $70, $07, $70, $04, $4C, $04, $4C, $06, $70, $06, $70 

; ---------------------------------------------------------------------------
; BossBattlePlayerInit
;
; Initializes the boss battle entity triad:
;   A5 / Player entity     — the player character sprite (3×4 tiles)
;   Battle_entity_slot_1   — weapon sprite (4×4 tiles)
;   Battle_entity_slot_2   — shield sprite (2×2 tiles)
;
; Clears move/attack state, assigns tick functions, and sets initial
; Y position to $00AC (172 px) for all three entities.
;
; Input:   A5 = player entity pointer
;          Battle_entity_slot_1_ptr, Battle_entity_slot_2_ptr
; Output:  All three entities initialized; Battle_active_flag = 0;
;          Boss_battle_exit_flag = 0; Player_attacking_flag = 0
; ---------------------------------------------------------------------------
BossBattlePlayerInit:
	BCLR.b	#7, obj_sprite_flags(A5)
	BCLR.b	#3, obj_sprite_flags(A5)
	BCLR.b	#4, obj_sprite_flags(A5)
	BSET.b	#5, obj_sprite_flags(A5)
	BSET.b	#6, obj_sprite_flags(A5)
	MOVE.b	#SPRITE_SIZE_3x4, obj_sprite_size(A5)
	MOVE.w	#VRAM_TILE_BOSS_BATTLE_PLAYER, obj_tile_index(A5)
	MOVE.w	#BOSS_BATTLE_PLAYER_X_MIN, obj_world_x(A5)
	MOVE.w	#$00AC, obj_world_y(A5)         ; initial Y = 172 px (fixed boss arena row)
	CLR.w	obj_sort_key(A5)
	CLR.b	obj_move_counter(A5)
	CLR.b	Player_is_moving.w
	CLR.b	Battle_active_flag.w
	MOVE.l	#BossBattlePlayerTick_Intro, obj_tick_fn(A5)
	MOVEA.l	Battle_entity_slot_1_ptr.w, A6
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BSET.b	#5, obj_sprite_flags(A6)
	BSET.b	#6, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_4x4, obj_sprite_size(A6)
	MOVE.w	#1, obj_tile_index(A6)
	CLR.w	obj_sort_key(A6)
	MOVE.l	#BossBattleWeaponTick, obj_tick_fn(A6)
	MOVEA.l	Battle_entity_slot_2_ptr.w, A6
	BSET.b	#7, (A6)
	BCLR.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BSET.b	#5, obj_sprite_flags(A6)
	BSET.b	#6, obj_sprite_flags(A6)
	MOVE.b	#SPRITE_SIZE_2x2, obj_sprite_size(A6)
	MOVE.w	#VRAM_TILE_BOSS_BATTLE_SHIELD, obj_tile_index(A6)
	CLR.w	obj_sort_key(A6)
	MOVE.l	#BossBattleShieldTick, obj_tick_fn(A6)
	CLR.b	Boss_battle_exit_flag.w
	CLR.b	Player_attacking_flag.w
	RTS

; ---------------------------------------------------------------------------
; BossBattlePlayerTick_Intro
;
; Plays a two-frame walk-in animation while the screen fades in, then
; transitions to BossBattlePlayerTick_Active.
;
; Frame rate is NTSC/PAL-aware (IO_version bit 6):
;   NTSC: counter & $60 >> 5 → frame index at 32-frame intervals (2 frames at 60fps)
;   PAL:  counter & $30 >> 4 → frame index at 16-frame intervals (2 frames at 50fps)
; When frame index reaches 2 (both frames shown), intro is complete.
;
; Input:   A5 = player entity; Fade_in_lines_mask.w
; ---------------------------------------------------------------------------
BossBattlePlayerTick_Intro:
	TST.b	Fade_in_lines_mask.w
	BNE.b	BossBattlePlayerTick_Intro_Loop
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	BTST.b	#6, IO_version
	BNE.w	BossBattlePlayerTick_Intro_PAL
	ANDI.w	#$0060, D0
	ASR.w	#5, D0
	BRA.b	BossBattlePlayerTick_Intro_CheckFrame
BossBattlePlayerTick_Intro_PAL:
	ANDI.w	#$0030, D0	
	ASR.w	#4, D0	
BossBattlePlayerTick_Intro_CheckFrame:
	CMPI.w	#2, D0
	BLT.b	BossBattlePlayerTick_Intro_DisplayFrame
	CLR.b	obj_move_counter(A5)
	MOVE.l	#BossBattlePlayerTick_Active, obj_tick_fn(A5)
	MOVE.b	#FLAG_TRUE, Battle_active_flag.w
	BRA.w	BossBattle_MoveDone
BossBattlePlayerTick_Intro_Loop:
	CLR.w	D0
BossBattlePlayerTick_Intro_DisplayFrame:
	MOVEA.l	Battle_entity_slot_1_ptr.w, A6
	LEA	BossBattleIntroFrameData, A0
	MOVE.b	(A0,D0.w), obj_sprite_frame(A6)
	MOVE.b	#8, obj_sprite_frame(A5)
	MOVEA.l	Battle_entity_slot_2_ptr.w, A4
	MOVE.b	#6, obj_sprite_frame(A4)
	CLR.b	Player_is_moving.w
	BRA.w	BossBattle_PostAttack_ClampAndDisplay
BossBattleIntroFrameData:
	dc.b	$0F
	dc.b	$10

; ---------------------------------------------------------------------------
; BossBattlePlayerTick_Active
;
; Main per-frame player tick for the boss battle arena.
;
; Each frame:
;   1. Skip input if blocked, fading out, or (on attack) until attack resolves
;   2. Check invulnerability timer; clear flag when it expires
;   3. C button → start sword attack (PlaySound, set Player_attacking_flag)
;   4. D-pad left → BossBattle_AttackLeft (left-facing hitbox and frames)
;   5. D-pad down → BossBattle_MoveLeft  (step left, uses BossBattle_MoveLeft_Data)
;   6. D-pad right → BossBattle_MoveRight (step right, uses BossBattle_MoveRight_Data)
;   7. No input → BossBattle_PlayerIdle  (idle stance frames)
;
; During an active attack (Player_attacking_flag set):
;   obj_hp(A5) is repurposed as an attack frame counter (0..39).
;   At frame 39 (CMPI #$0A after >> 2) the attack ends automatically.
;   Each frame calls DispatchBattleCollisionChecks to test weapon contact.
;
; Hitbox half-heights:
;   Idle/moving: $0030 (48 px)
;   Attacking:   $0027 (39 px, slightly narrower for lunge posture)
;
; Frame rate adaptation is NTSC/PAL-aware (same bit-6 check as intro tick).
; Movement animation cycles through BossBattle_MoveLeft/Right_Data (in miscdata.asm).
;
; Input:   A5 = player entity
;          Player_input_blocked, Fade_out_lines_mask, Player_invulnerable
;          Controller_current_state (bits 0–3: right/left/down/up)
; ---------------------------------------------------------------------------
BossBattlePlayerTick_Active:
	TST.b	Player_input_blocked.w
	BNE.w	BossBattle_PlayerIdle
	TST.b	Fade_out_lines_mask.w
	BNE.w	BossBattle_PlayerIdle
	TST.b	Player_invulnerable.w
	BEQ.b	BossBattle_AttackCheck
	SUBQ.b	#1, obj_invuln_timer(A5)
	BGT.b	BossBattle_AttackCheck
	CLR.b	Player_invulnerable.w
BossBattle_AttackCheck:
	TST.b	Player_attacking_flag.w
	BNE.w	BossBattle_MoveDone
	CheckButton BUTTON_BIT_C
	BEQ.b	BossBattle_AttackCheck_Loop
	PlaySound SOUND_BOSS_SWORD_ATTACK
	MOVE.b	#FLAG_TRUE, Player_attacking_flag.w
	CLR.b	obj_hp(A5)
BossBattle_AttackCheck_Loop:
	MOVE.b	Controller_current_state.w, D0
	ANDI.w	#$000F, D0
	BEQ.w	BossBattle_PlayerIdle
	BTST.l	#1, D0
	BNE.b	BossBattle_AttackLeft
	BTST.l	#2, D0
	BNE.b	BossBattle_MoveLeft
	BTST.l	#3, D0
	BNE.w	BossBattle_MoveRight
	BRA.w	BossBattle_PlayerIdle
BossBattle_AttackLeft:
	MOVE.w	#$0027, obj_hitbox_half_h(A5)
	MOVEA.l	Battle_entity_slot_1_ptr.w, A6
	MOVEA.l	Battle_entity_slot_2_ptr.w, A4
	MOVE.b	#$0C, obj_sprite_frame(A5)
	MOVE.b	#$0C, obj_sprite_frame(A6)
	MOVE.b	#5, obj_sprite_frame(A4)
	BRA.w	BossBattle_PostAttack_ClampAndDisplay
BossBattle_MoveLeft:
	MOVE.l	obj_pos_x_fixed(A5), D0
	ASL.l	#7, D0
	SUB.l	D0, obj_world_x(A5)
	MOVE.w	#DIRECTION_LEFT, Player_direction.w
	LEA	BossBattle_MoveLeft_Data, A0
	BRA.w	BossBattle_ApplyMovement
BossBattle_MoveRight:
	MOVE.l	obj_pos_x_fixed(A5), D0
	ASL.l	#7, D0
	ADD.l	D0, obj_world_x(A5)
	MOVE.w	#DIRECTION_DOWN, Player_direction.w
	LEA	BossBattle_MoveRight_Data, A0
	BRA.w	BossBattle_ApplyMovement
BossBattle_PlayerIdle:
	MOVE.w	#$0030, obj_hitbox_half_h(A5)
	MOVEA.l	Battle_entity_slot_1_ptr.w, A6
	MOVEA.l	Battle_entity_slot_2_ptr.w, A4
	MOVE.b	#8, obj_sprite_frame(A5)
	MOVE.b	#8, obj_sprite_frame(A6)
	MOVE.b	#6, obj_sprite_frame(A4)
	MOVE.b	#PLAYER_MOVE_STEPS, Player_movement_step_counter.w
	CLR.b	Player_is_moving.w
	BRA.w	BossBattle_MoveDone
BossBattle_ApplyMovement:
	MOVE.w	#$0030, obj_hitbox_half_h(A5)
	MOVE.b	#FLAG_TRUE, Player_is_moving.w
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	BTST.b	#6, IO_version
	BNE.b	BossBattle_ApplyMovement_PAL
	ANDI.w	#$000C, D0
	BRA.b	BossBattle_ApplyMovement_DisplayFrame
BossBattle_ApplyMovement_PAL:
	ANDI.w	#6, D0	
	ASL.w	#1, D0	
BossBattle_ApplyMovement_DisplayFrame:
	MOVEA.l	Battle_entity_slot_1_ptr.w, A6
	MOVEA.l	Battle_entity_slot_2_ptr.w, A4
	MOVE.b	(A0,D0.w), obj_sprite_frame(A5)
	MOVE.b	$1(A0,D0.w), obj_sprite_frame(A6)
	MOVE.b	$2(A0,D0.w), obj_sprite_frame(A4)
	SUBQ.b	#1, Player_movement_step_counter.w
	BGT.b	BossBattle_MoveDone
	MOVE.b	#PLAYER_MOVE_STEPS, Player_movement_step_counter.w
	CLR.b	Player_is_moving.w
BossBattle_MoveDone:
	TST.b	Player_attacking_flag.w
	BEQ.w	BossBattle_PostAttack_ClampAndDisplay
	MOVEA.l	Battle_entity_slot_1_ptr.w, A6
	MOVEA.l	Battle_entity_slot_2_ptr.w, A4
	ADDQ.b	#1, obj_hp(A5)
	MOVE.b	obj_hp(A5), D0
	ASR.w	#2, D0
	CMPI.w	#$000A, D0
	BGE.b	BossBattle_MoveDone_Loop
	ANDI.w	#$000F, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	BossBattle_MoveDone_Data, A0
	MOVE.b	(A0,D0.w), obj_sprite_frame(A5)
	MOVE.b	$1(A0,D0.w), obj_sprite_frame(A6)
	MOVE.b	$2(A0,D0.w), obj_sprite_frame(A4)
	BSR.w	DispatchBattleCollisionChecks
	BRA.w	BossBattle_PostAttack_ClampAndDisplay
BossBattle_MoveDone_Loop:
	CLR.b	Player_attacking_flag.w
BossBattle_PostAttack_ClampAndDisplay:
	MOVE.w	obj_world_x(A5), D0
	CMPI.w	#BOSS_BATTLE_PLAYER_X_MIN, D0
	BGE.b	BossBattle_PostAttack_ClampAndDisplay_Loop
	MOVE.w	#BOSS_BATTLE_PLAYER_X_MIN, obj_world_x(A5)
	BRA.b	BossBattle_SpriteUpdate
BossBattle_PostAttack_ClampAndDisplay_Loop:
	CMPI.w	#BOSS_BATTLE_PLAYER_X_MAX, D0
	BLT.b	BossBattle_SpriteUpdate
	MOVE.w	#BOSS_BATTLE_PLAYER_X_MAX, obj_world_x(A5)	
BossBattle_SpriteUpdate:
	TST.b	Boss_battle_exit_flag.w
	BNE.w	BossBattleExitCleanup
	MOVE.b	#FLAG_TRUE, Sprite_dma_update_pending.w
	MOVE.w	obj_world_x(A5), obj_screen_x(A5)
	MOVE.w	obj_world_y(A5), obj_screen_y(A5)
	MOVE.w	obj_screen_y(A5), obj_sort_key(A5)
	JSR	AddSpriteToDisplayList
	RTS

; ---------------------------------------------------------------------------
; BossBattleExitCleanup
;
; Called when Boss_battle_exit_flag is set (boss defeated).
; Walks the entity linked list from Player_entity_ptr through two obj_next_offset
; links (weapon and shield entities) and replaces all three tick functions with
; BossBattleEntityNullTick.  Then triggers the gameplay state transition and
; initiates the fade-out.
; ---------------------------------------------------------------------------
BossBattleExitCleanup:
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.l	#BossBattleEntityNullTick, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	MOVE.l	#BossBattleEntityNullTick, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	MOVE.l	#BossBattleEntityNullTick, obj_tick_fn(A6)
	MOVE.w	#GAMEPLAY_STATE_RETURN_FROM_BOSS_BATTLE, Gameplay_state.w
	MOVE.b	#FLAG_TRUE, Fade_out_lines_mask.w
	CLR.b	Player_is_moving.w
	JSR	AddSpriteToDisplayList
	RTS

BossBattleEntityNullTick:
	JSR	AddSpriteToDisplayList
	RTS

; ---------------------------------------------------------------------------
; BossBattleWeaponTick
;
; Mirrors the player entity's position and flip flags onto the weapon sprite,
; placing it $0018 (24 px) above the player's screen Y (sword raised position).
; ---------------------------------------------------------------------------
BossBattleWeaponTick:
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.b	obj_sprite_flags(A6), obj_sprite_flags(A5)
	MOVE.w	obj_screen_x(A6), obj_screen_x(A5)
	MOVE.w	obj_screen_y(A6), D2
	SUBI.w	#$0018, D2
	MOVE.w	D2, obj_screen_y(A5)
	MOVE.w	obj_screen_y(A6), obj_sort_key(A5)
	JSR	AddSpriteToDisplayList
	RTS

; ---------------------------------------------------------------------------
; BossBattleShieldTick
;
; Positions the shield sprite relative to the player using a per-frame offset
; table (BossBattleShieldTick_Data in miscdata.asm).  The player's current
; sprite frame × 4 indexes the table to get (delta_x, delta_y) offset words
; which are added to the player's screen position.
;
; $2(A0,D0.w) reads the Y offset word (2 bytes after the X offset word).
; ---------------------------------------------------------------------------
BossBattleShieldTick: 
	MOVEA.l	Player_entity_ptr.w, A6
	MOVE.b	obj_sprite_flags(A6), obj_sprite_flags(A5)
	MOVEA.l	Player_entity_ptr.w, A6
	CLR.w	D0
	MOVE.b	obj_sprite_frame(A6), D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	BossBattleShieldTick_Data, A0
	MOVE.w	(A0,D0.w), D1
	MOVE.w	obj_screen_x(A6), D2
	ADD.w	D1, D2
	MOVE.w	D2, obj_screen_x(A5)
	MOVE.w	obj_screen_y(A6), D2
	ADD.w	$2(A0,D0.w), D2
	MOVE.w	D2, obj_screen_y(A5)
	MOVE.w	obj_screen_y(A6), obj_sort_key(A5)
	JSR	AddSpriteToDisplayList
	RTS

; ---------------------------------------------------------------------------
; DispatchBattleCollisionChecks
;
; Routes to the appropriate boss collision handler based on Battle_type.
; Battle_type × 4 = byte offset into BossCollisionJumpTable (each entry is
; a 4-byte BRA.w instruction).
;
; Input:  Battle_type.w (0–13)
; ---------------------------------------------------------------------------
DispatchBattleCollisionChecks:
	LEA	BossCollisionJumpTable, A0
	MOVE.w	Battle_type.w, D2
	ADD.w	D2, D2
	ADD.w	D2, D2
	JSR	(A0,D2.w)
	RTS

BossCollisionJumpTable:
	BRA.w	BossCollision_Standard
	BRA.w	BossCollision_SingleTarget
	BRA.w	BossCollision_MultiBody
	BRA.w	BossCollision_MultiBody
	BRA.w	BossCollision_MultiBodyAll
	BRA.w	BossCollision_SingleTargetAlt
	BRA.w	BossCollision_SingleTargetAlt
	BRA.w	BossCollision_SingleTargetAlt
	BRA.w	BossCollision_Standard
	BRA.w	BossCollision_Standard
	BRA.w	BossCollision_SingleTarget
	BRA.w	BossCollision_MultiBody
	BRA.w	BossCollision_MultiBodyAll
	BRA.w	BossCollision_FinalBoss
BossCollision_Standard:
	BSR.w	GetBoundingBoxFromTable
	MOVEA.l	Enemy_list_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	MOVEA.l	Object_slot_02_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	RTS

BossCollision_MultiBody:
	BSR.w	GetBoundingBoxFromTable
	MOVEA.l	Object_slot_02_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	MOVEA.l	Object_slot_04_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	MOVEA.l	Object_slot_05_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	MOVEA.l	Object_slot_03_ptr.w, A6
	MOVE.w	#$00C8, D4          ; arena Y bottom = 200 px (multi-body boss floor)
	MOVE.w	#BATTLE_FIELD_WIDTH, D5
	MOVE.w	#0, D6              ; arena Y top = 0 px
	MOVE.w	#$00E0, D7          ; arena X right = 224 px
	BSR.w	CheckFixedAreaCollision
	RTS

BossCollision_SingleTarget:
	BSR.w	GetBoundingBoxFromTable
	MOVEA.l	Enemy_list_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	RTS

BossCollision_SingleTargetAlt:
	BSR.w	GetBoundingBoxFromTable
	MOVEA.l	Enemy_list_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	RTS

BossCollision_MultiBodyAll:
	BSR.w	GetBoundingBoxFromTable
	MOVEA.l	Enemy_list_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	MOVEA.l	Object_slot_02_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	MOVEA.l	Object_slot_03_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	MOVEA.l	Object_slot_04_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	MOVEA.l	Object_slot_05_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	MOVEA.l	Object_slot_06_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	MOVEA.l	Object_slot_07_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	MOVEA.l	Object_slot_08_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	MOVEA.l	Object_slot_09_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	RTS

BossCollision_FinalBoss:
	BSR.w	GetBoundingBoxFromTable
	MOVEA.l	Object_slot_01_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	MOVEA.l	Object_slot_03_ptr.w, A6
	BSR.w	CheckObjectCollisionBounds
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVE.w	#$00D8, D4          ; arena Y bottom = 216 px (final boss floor)
	MOVE.w	#BATTLE_FIELD_WIDTH, D5
	MOVE.w	#0, D6              ; arena Y top = 0 px
	MOVE.w	#$00E0, D7          ; arena X right = 224 px
	BSR.w	CheckFixedAreaCollision
	RTS

; ---------------------------------------------------------------------------
; CheckObjectCollisionBounds — AABB hit-test against a caller-supplied rect
;
; Tests whether the object at A6 overlaps the axis-aligned bounding box
; defined by D0–D3.  Returns immediately (no hit) if bit 7 of (A6) is
; clear (object inactive or not collidable).
;
; The object's hitbox is read from the signed byte fields obj_hitbox_x_pos,
; obj_hitbox_x_neg, obj_hitbox_y_pos, and obj_hitbox_y_neg (offsets into
; the struct at A6), each sign-extended and added to the world position.
;
; Input:
;   A6    pointer to the object struct to test
;   D0.w  right  edge of test rectangle  (x_max)
;   D1.w  left   edge of test rectangle  (x_min)
;   D2.w  bottom edge of test rectangle  (y_max)
;   D3.w  top    edge of test rectangle  (y_min)
;
; Scratch:  D4
; Output:   obj_hit_flag(A6) = FLAG_TRUE if overlap, else unchanged
; ---------------------------------------------------------------------------
CheckObjectCollisionBounds:
	BTST.b	#7, (A6)
	BEQ.b	ObjectCollisionBounds_Done
	CLR.w	D4
	MOVE.b	obj_hitbox_x_pos(A6), D4
	EXT.w	D4
	ADD.w	obj_world_x(A6), D4
	CMP.w	D0, D4
	BLT.b	ObjectCollisionBounds_Done
	CLR.w	D4
	MOVE.b	obj_hitbox_x_neg(A6), D4
	EXT.w	D4
	ADD.w	obj_world_x(A6), D4
	CMP.w	D1, D4
	BGT.b	ObjectCollisionBounds_Done
	CLR.w	D4
	MOVE.b	obj_hitbox_y_pos(A6), D4
	EXT.w	D4
	ADD.w	obj_world_y(A6), D4
	CMP.w	D2, D4
	BLT.b	ObjectCollisionBounds_Done
	CLR.w	D4
	MOVE.b	obj_hitbox_y_neg(A6), D4
	EXT.w	D4
	ADD.w	obj_world_y(A6), D4
	CMP.w	D3, D4
	BGT.b	ObjectCollisionBounds_Done
	MOVE.b	#FLAG_TRUE, obj_hit_flag(A6)
ObjectCollisionBounds_Done:
	RTS

GetBoundingBoxFromTable:
	LEA	NPCBoundingBoxTable, A0
	ADD.w	D0, D0
	LEA	(A0,D0.w), A0
	MOVE.w	(A0)+, D0
	MOVE.w	(A0)+, D1
	MOVE.w	(A0)+, D2
	MOVE.w	(A0), D3
	ADD.w	obj_world_x(A5), D0
	ADD.w	obj_world_x(A5), D1
	ADD.w	obj_world_y(A5), D2
	ADD.w	obj_world_y(A5), D3
	RTS

; ---------------------------------------------------------------------------
; CheckFixedAreaCollision
;
; Tests the object at A6 against a caller-supplied fixed rectangular arena
; region rather than reading hitbox fields from the object struct.
; Used by BossCollision_MultiBody and BossCollision_FinalBoss to check
; whether the player's weapon overlaps the boss's fixed floor area.
;
; Input:
;   A6    pointer to object to set hit flag on if collision
;   D0.w  right  edge of weapon (x_max)
;   D1.w  left   edge of weapon (x_min)
;   D2.w  bottom edge of weapon (y_max)
;   D3.w  top    edge of weapon (y_min)
;   D4.w  arena  Y bottom bound
;   D5.w  arena  X right  bound
;   D6.w  arena  Y top    bound
;   D7.w  arena  X left   bound
; Output: obj_hit_flag(A6) = FLAG_TRUE on overlap
; ---------------------------------------------------------------------------
CheckFixedAreaCollision:
	CMP.w	D4, D1
	BLT.b	CheckFixedAreaCollision_Return
	CMP.w	D5, D0
	BGT.b	CheckFixedAreaCollision_Return
	CMP.w	D6, D3
	BLT.b	CheckFixedAreaCollision_Return
	CMP.w	D7, D2
	BGT.b	CheckFixedAreaCollision_Return
	MOVE.b	#FLAG_TRUE, obj_hit_flag(A6)
CheckFixedAreaCollision_Return:
	RTS

NPCBoundingBoxTable:
; ---------------------------------------------------------------------------
; NPCBoundingBoxTable
;
; 10 entries × 4 words each = 80 bytes.
; Each entry is (right_offset, left_offset, bottom_offset, top_offset) in
; signed pixels relative to the object's world (X, Y) position.
; Indexed by D0 (weapon hitbox type) via GetBoundingBoxFromTable.
;
; Entry 0–1: zero (unused / no hitbox)
; Entry 2:   small centered box   (-20, 0, -18, 0)
; Entry 3:   standing enemy hitbox  (8, 24, -24, 8)
; Entry 4:   tall enemy hitbox   (16, 32, -56, -30)
; Entry 5–6: wide boss hitbox   (-20, 16, -64, -48)
; Entry 7–9: standard boss hitbox (4, 32, -32, -12)
; ---------------------------------------------------------------------------
	dc.w	0, 0, 0, 0
	dc.w	0, 0, 0, 0
	dc.w	-20, 0, -18, 0
	dc.w	8, 24, -24, 8
	dc.w	16, 32, -56, -30
	dc.w	-20, 16, -64, -48
	dc.w	-20, 16, -64, -48
	dc.w	4, 32, -32, -12
	dc.w	4, 32, -32, -12
	dc.w	4, 32, -32, -12

; ---------------------------------------------------------------------------
; LoadTownNPCs
;
; Loads up to 30 NPC entities for the current town from Town_npc_data_ptr.
; Data format at Town_npc_data_ptr:
;   [0]    .l  NPC init routine pointer (loaded into Npc_init_routine_ptr)
;   [4+]   Per-NPC records until a record with X < 0 (terminator):
;             .w  world_x   (negative = end-of-list sentinel)
;             .w  world_y
;             .w  tile_index
;             .l  anim_ptr
;             .l  tick_fn
;             .b  sprite_flags
;             .b  collidable flag
; After loading all entities, calls the NPC init routine (which appends
; dialogue string pointers from a second table immediately following).
;
; D5 counts NPCs loaded (written to Npc_count.w after loop).
; D7 counts remaining entity slots (DBF loop from $1D = 29 down to 0).
; Slots beyond the NPC count have their active flag (bit 7) cleared.
;
; Input:   Town_npc_data_ptr.w
; Output:  Enemy_list_ptr slots initialized; Npc_count.w set
; Scratch: D0, D5, D6, D7, A0, A6
; ---------------------------------------------------------------------------
LoadTownNPCs:
	CLR.b	Npc_load_done_flag.w
	CLR.w	D5
	MOVEQ	#$1D, D7                ; for $1D (29) {
	CLR.w	D6
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVEA.l	Town_npc_data_ptr.w, A0
	MOVE.l	(A0)+, Npc_init_routine_ptr.w
LoadTownNPCs_Done:
	TST.b	Npc_load_done_flag.w
	BNE.w	NpcInit_ClearActiveFlag
	MOVE.w	(A0)+, D0
	BPL.w	LoadTownNPCs_Loop
	MOVE.b	#FLAG_TRUE, Npc_load_done_flag.w
	BRA.w	NpcInit_ClearActiveFlag
LoadTownNPCs_Loop:
	MOVE.w	D0, obj_world_x(A6)
	ADDQ.w	#1, D5
	BSET.b	#7, (A6)
	MOVE.b	#DIRECTION_DOWN, obj_direction(A6)
	CLR.b	obj_max_hp(A6)
	CLR.l	obj_hp(A6)
	CLR.b	obj_invuln_timer(A6)
	CLR.b	obj_move_counter(A6)
	CLR.b	obj_behavior_flag(A6)
	CLR.b	obj_npc_busy_flag(A6)
	MOVE.w	(A0)+, obj_world_y(A6)
	MOVE.w	(A0)+, obj_tile_index(A6)
	MOVE.l	(A0)+, obj_anim_ptr(A6)
	MOVE.l	(A0)+, obj_tick_fn(A6)
	MOVE.b	#SPRITE_SIZE_4x3, obj_sprite_size(A6)
	MOVE.b	(A0)+, obj_sprite_flags(A6)
	MOVE.b	(A0)+, obj_collidable(A6)
	BRA.b	NpcInit_ClearActiveFlag_Loop
NpcInit_ClearActiveFlag:
	BCLR.b	#7, (A6)
NpcInit_ClearActiveFlag_Loop:
	CLR.b	obj_hit_flag(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, LoadTownNPCs_Done			; }
	MOVE.w	D5, Npc_count.w
	MOVEA.l	Npc_init_routine_ptr.w, A0
	JSR	(A0)
	MOVE.w	Npc_count.w, D7
	SUBQ.w	#1, D7
	BLT.b	NpcInit_ClearActiveFlag_Done
	MOVEA.l	Enemy_list_ptr.w, A6
NpcInit_ClearActiveFlag_Loop_Done:
	MOVE.l	(A0)+, obj_npc_str_ptr(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	DBF	D7, NpcInit_ClearActiveFlag_Loop_Done
NpcInit_ClearActiveFlag_Done:
	RTS

ClearAllNPCSlots:					; unreferenced dead code
	MOVEA.l	Enemy_list_ptr.w, A6
	MOVEQ	#$1D, D7
ClearAllNPCSlots_Done:
	BCLR	#7, (A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	$0(A6,D0.w), A6
	DBF	D7, ClearAllNPCSlots_Done
	RTS

