; ======================================================================
; src/mapdata.asm
; Overworld map pointer table, overworld sector data, cave room data
; ======================================================================
;
; MAP DATA OVERVIEW
; -----------------
; The world is divided into three map types, each with its own binary format
; and decompressor:
;
;   1. OVERWORLD SECTORS  — 96 RLE-compressed sector files
;   2. CAVE ROOMS         — 43 RLE-compressed room files
;   3. TOWN TILEMAPS      — inline RLE in townbuild.asm (different compressor)
;
; ---------------------------------------------------------------------------
; OVERWORLD SECTOR FORMAT  (data/maps/overworld/sector_X_Y.bin)
; ---------------------------------------------------------------------------
; The overworld is a 16×8 grid of sectors (128 total).
; Sectors are indexed by (sector_x, sector_y), accessed as:
;   index = sector_y * 16 + sector_x
;   pointer = OverworldMaps[index]   (128-entry dc.l table)
;
; Each sector encodes a 16×16 tile map using a simple RLE scheme:
;
;   Byte < $80  → emit byte as a literal tile index
;   Byte >= $80 → RLE run: count = (byte − $80), next byte is tile value;
;                 emit tile (count) times
;
; Decompressor: DecompressMapSectorRLE (src/dungeon.asm)
; Output: 256 tiles written into a buffer with 32-tile row stride
;         (16 tiles of map data + 16 bytes of padding per row)
;
; The game loads a 3×3 window of 9 sectors around the player at all times
; via Load9SectorMapWindow (src/dungeon.asm).
;
; Some OverworldMaps entries point to CaveMaps instead of sector data —
; these mark overworld tiles that act as cave entrances.
; Two entries (OverworldMapSector_40018, EnemySpriteData_FacingSide_Gfx_40020)
; are small blobs that are NOT sector maps.
;
; ---------------------------------------------------------------------------
; CAVE ROOM FORMAT  (data/maps/cave/room_NN.bin)
; ---------------------------------------------------------------------------
; Same RLE encoding as overworld sectors (byte < $80 literal, >= $80 run).
; Decompressor: DecompressMapSectorRLE (same routine).
; Output layout: same 16×16 grid with 32-tile stride.
;
; 44 rooms total (indices 0–28 + 31–43; indices 29–30 share room_28.bin).
; Cave room pointer table: CaveMaps (44-entry dc.l table in this file).
; Cave room index is the direct lookup key into CaveMaps.
;
; ---------------------------------------------------------------------------
; TOWN TILEMAP FORMAT  (inline in src/townbuild.asm)
; ---------------------------------------------------------------------------
; See townbuild.asm file header and src/cutscene.asm:DecompressTilemap for
; full documentation of the town-specific tilemap compression format.
;
; ---------------------------------------------------------------------------
; MAP CONSTANTS (src/constants.asm)
; ---------------------------------------------------------------------------
;   MAP_RLE_TILE_COUNT    = $100   (256 tiles per sector/room)
;   Player_map_sector_x   = $FFFFC???  current sector X
;   Player_map_sector_y   = $FFFFC???  current sector Y
;   Map_sector_*          = RAM buffers for the 9-sector window
;
; ---------------------------------------------------------------------------
; TILE VALUE LEGEND  (applies to both overworld sectors and cave rooms)
; ---------------------------------------------------------------------------
;   $00       Ground / floor
;   $01       Tree (impassable)
;   $02       Rock (impassable)
;   $05       Cave rock (impassable)
;   $0F       House (impassable)
;   $1x       Cave entrance — lower 4 bits = cave index (0–F)
;   $8x       Town entrance  — lower 4 bits = town ID (0–F)
;   $FF       Cave exit (returns player to overworld)
;
;   Other values are terrain tile indices for the current tileset.
; ---------------------------------------------------------------------------
; SPECIAL OverworldMaps ENTRIES
; ---------------------------------------------------------------------------
;   OverworldMapSector_Empty  — filler sector (ocean / blank)
;   OverworldMapSector_E21E   — shared sector used in multiple grid slots
;   OverworldMapSector_E6DA   — shared sector (sector_2_3.bin)
;   CaveMaps (dc.l pointer)   — overworld cell is a cave entrance hub;
;                               the cave room index is encoded in the tile
;   OverworldMapSector_40018  — small non-sector data blob (10 bytes)
;   EnemySpriteData_FacingSide_Gfx_40020 — 8-byte non-sector blob
;   OverworldMapSector_40028  — sector_14_4.bin (last real overworld sector)
; ---------------------------------------------------------------------------

;==============================================================
; OVERWORLD MAP POINTER TABLE
; 128 dc.l pointers (16 columns × 8 rows).
; Index = sector_y * 16 + sector_x.
; Each entry points to a sector .bin incbin below, or to CaveMaps
; for cells that act as cave entrance hubs.
;==============================================================
OverworldMaps: ; 128
	dc.l	OverworldMaps_Map_3E1D4
	dc.l	OverworldMaps_Map_3E40E
	dc.l	OverworldMapSector_E5FC
	dc.l	OverworldMaps_Map_3E848
	dc.l	OverworldMaps_Map_3EA62
	dc.l	OverworldMaps_Map_3EBEE
	dc.l	OverworldMaps_Map_3EE1C
	dc.l	SpriteFrameData_3F134
	dc.l	OverworldMaps_Map_3F250
	dc.l	SpriteFrameData_3F402
	dc.l	SpriteFrameData_3F64E
	dc.l	OverworldMaps_Map_3F85A
	dc.l	OverworldMaps_Map_3FAF0
	dc.l	OverworldMaps_Map_3FD42
	dc.l	OverworldMapSector_FF68
	dc.l	OverworldMapSector_Empty
	dc.l	OverworldMapSector_E21E
	dc.l	OverworldMaps_Map_3E498
	dc.l	OverworldMaps_Map_3E618
	dc.l	OverworldMaps_Map_3E866
	dc.l	OverworldMaps_Map_3EA6A
	dc.l	OverworldMaps_Map_3EBFC
	dc.l	OverworldMaps_Map_3EE30
	dc.l	SpriteFrameData_3F134
	dc.l	OverworldMaps_Map_3F2CE
	dc.l	OverworldMaps_Map_3F438
	dc.l	SpriteFrameData_3F6DC
	dc.l	SpriteFrameData_3F880
	dc.l	OverworldMaps_Map_3FB28
	dc.l	OverworldMaps_Map_3FD8A
	dc.l	OverworldMapSector_FFA0
	dc.l	OverworldMapSector_Empty
	dc.l	OverworldMapSector_E21E
	dc.l	OverworldMaps_Map_3E4DA
	dc.l	OverworldMaps_Map_3E684
	dc.l	OverworldMaps_Map_3E8E4
	dc.l	OverworldMaps_Map_3EACC
	dc.l	OverworldMaps_Map_3EC32
	dc.l	OverworldMaps_Map_3EE9A
	dc.l	OverworldMaps_Map_3F188
	dc.l	OverworldMaps_Map_3F304
	dc.l	OverworldMaps_Map_3F486
	dc.l	SpriteFrameData_3F6DC
	dc.l	SpriteFrameData_3F880
	dc.l	OverworldMaps_Map_3FB70
	dc.l	OverworldMaps_Map_3FE08
	dc.l	OverworldMapSector_FFA0
	dc.l	OverworldMapSector_Empty
	dc.l	OverworldMapSector_E21E
	dc.l	OverworldMaps_Map_3E508
	dc.l	OverworldMapSector_E6DA
	dc.l	OverworldMapSector_E6DA
	dc.l	OverworldMapSector_E6DA
	dc.l	OverworldMaps_Map_3EC84
	dc.l	OverworldMaps_Map_3EF12
	dc.l	OverworldMapSector_F1AC
	dc.l	OverworldMapSector_F33E
	dc.l	OverworldMaps_Map_3F4DA
	dc.l	OverworldMapSector_F70A
	dc.l	SpriteFrameData_3F8F8
	dc.l	OverworldMaps_Map_3FBD2
	dc.l	OverworldMaps_Map_3FE5E
	dc.l	OverworldMaps_Map_3FFD6
	dc.l	OverworldMapSector_Empty
	dc.l	OverworldMaps_Map_3E23C
	dc.l	OverworldMaps_Map_3E512
	dc.l	OverworldMaps_Map_3E6E2
	dc.l	OverworldMaps_Map_3E97A
	dc.l	OverworldMaps_Map_3EB22
	dc.l	OverworldMaps_Map_3ECA2
	dc.l	OverworldMaps_Map_3EF60
	dc.l	OverworldMapSector_F1AC
	dc.l	OverworldMapSector_F33E
	dc.l	OverworldMaps_Map_3F574
	dc.l	OverworldMapSector_F70A
	dc.l	SpriteFrameData_3F8F8
	dc.l	OverworldMaps_Map_3FC1C
	dc.l	OverworldMaps_Map_3FE6C
	dc.l	OverworldMapSector_40028
	dc.l	CaveMaps
	dc.l	OverworldMaps_Map_3E2B6
	dc.l	OverworldMaps_Map_3E586
	dc.l	OverworldMaps_Map_3E720
	dc.l	OverworldMaps_Map_3E9C0
	dc.l	OverworldMaps_Map_3EB4E
	dc.l	OverworldMaps_Map_3ECEA
	dc.l	OverworldMaps_Map_3EFDA
	dc.l	OverworldMapSector_F1AC
	dc.l	OverworldMapSector_F33E
	dc.l	OverworldMaps_Map_3F5DC
	dc.l	OverworldMapSector_F70A
	dc.l	OverworldMaps_Map_3F992
	dc.l	OverworldMaps_Map_3FC6A
	dc.l	OverworldMaps_Map_3FEB6
	dc.l	OverworldMapSector_Empty
	dc.l	CaveMaps
	dc.l	OverworldMaps_Map_3E35C
	dc.l	OverworldMapSector_E5FC
	dc.l	OverworldMaps_Map_3E784
	dc.l	SpriteFrameData_3EA04
	dc.l	SpriteFrameData_3EBA4
	dc.l	OverworldMaps_Map_3ED68
	dc.l	OverworldMaps_Map_3F05A
	dc.l	OverworldMapSector_F1AC
	dc.l	OverworldMaps_Map_3F388
	dc.l	OverworldMaps_Map_3F61E
	dc.l	OverworldMaps_Map_3F76E
	dc.l	SpriteFrameData_3FA54
	dc.l	OverworldMaps_Map_3FCB2
	dc.l	OverworldMaps_Map_3FF24
	dc.l	OverworldMapSector_Empty
	dc.l	CaveMaps	
	dc.l	OverworldMaps_Map_3E3B8
	dc.l	OverworldMapSector_E5FC
	dc.l	OverworldMaps_Map_3E7CA
	dc.l	SpriteFrameData_3EA04
	dc.l	SpriteFrameData_3EBA4
	dc.l	OverworldMaps_Map_3EDC8
	dc.l	OverworldMaps_Map_3F0D8
	dc.l	OverworldMaps_Map_3F20C
	dc.l	SpriteFrameData_3F402
	dc.l	SpriteFrameData_3F64E
	dc.l	OverworldMaps_Map_3F7CE
	dc.l	SpriteFrameData_3FA54
	dc.l	OverworldMaps_Map_3FD10
	dc.l	OverworldMapSector_FF68
	dc.l	OverworldMapSector_Empty	
	dc.l	CaveMaps	
;==============================================================
; OVERWORLD SECTOR DATA
; RLE-compressed 16×16 tile maps, one per sector file.
; Labels use ROM-address suffix (DATA-001 — rename pending).
;==============================================================
OverworldMaps_Map_3E1D4:
	incbin "data/maps/overworld/sector_0_0.bin"
OverworldMapSector_E21E:
	incbin "data/maps/overworld/sector_0_1.bin"
OverworldMaps_Map_3E23C:
	incbin "data/maps/overworld/sector_0_4.bin"
OverworldMaps_Map_3E2B6:
	incbin "data/maps/overworld/sector_0_5.bin"
OverworldMaps_Map_3E35C:
	incbin "data/maps/overworld/sector_0_6.bin"
OverworldMaps_Map_3E3B8:
	incbin "data/maps/overworld/sector_0_7.bin"
OverworldMaps_Map_3E40E:
	incbin "data/maps/overworld/sector_1_0.bin"
OverworldMaps_Map_3E498:
	incbin "data/maps/overworld/sector_1_1.bin"
OverworldMaps_Map_3E4DA:
	incbin "data/maps/overworld/sector_1_2.bin"
OverworldMaps_Map_3E508:
	incbin "data/maps/overworld/sector_1_3.bin"
OverworldMaps_Map_3E512:
	incbin "data/maps/overworld/sector_1_4.bin"
OverworldMaps_Map_3E586:
	incbin "data/maps/overworld/sector_1_5.bin"
OverworldMapSector_E5FC:
	incbin "data/maps/overworld/sector_2_0.bin"
OverworldMaps_Map_3E618:
	incbin "data/maps/overworld/sector_2_1.bin"
OverworldMaps_Map_3E684:
	incbin "data/maps/overworld/sector_2_2.bin"
OverworldMapSector_E6DA:
	incbin "data/maps/overworld/sector_2_3.bin"
OverworldMaps_Map_3E6E2:
	incbin "data/maps/overworld/sector_2_4.bin"
OverworldMaps_Map_3E720:
	incbin "data/maps/overworld/sector_2_5.bin"
OverworldMaps_Map_3E784:
	incbin "data/maps/overworld/sector_2_6.bin"
OverworldMaps_Map_3E7CA:
	incbin "data/maps/overworld/sector_2_7.bin"
OverworldMaps_Map_3E848:
	incbin "data/maps/overworld/sector_3_0.bin"
OverworldMaps_Map_3E866:
	incbin "data/maps/overworld/sector_3_1.bin"
OverworldMaps_Map_3E8E4:
	incbin "data/maps/overworld/sector_3_2.bin"
OverworldMaps_Map_3E97A:
	incbin "data/maps/overworld/sector_3_4.bin"
OverworldMaps_Map_3E9C0:
	incbin "data/maps/overworld/sector_3_5.bin"
SpriteFrameData_3EA04:
	incbin "data/maps/overworld/sector_3_6.bin"
OverworldMaps_Map_3EA62:
	incbin "data/maps/overworld/sector_4_0.bin"
OverworldMaps_Map_3EA6A:
	incbin "data/maps/overworld/sector_4_1.bin"
OverworldMaps_Map_3EACC:
	incbin "data/maps/overworld/sector_4_2.bin"
OverworldMaps_Map_3EB22:
	incbin "data/maps/overworld/sector_4_4.bin"
OverworldMaps_Map_3EB4E:
	incbin "data/maps/overworld/sector_4_5.bin"
SpriteFrameData_3EBA4:
	incbin "data/maps/overworld/sector_4_6.bin"
OverworldMaps_Map_3EBEE:
	incbin "data/maps/overworld/sector_5_0.bin"
OverworldMaps_Map_3EBFC:
	incbin "data/maps/overworld/sector_5_1.bin"
OverworldMaps_Map_3EC32:
	incbin "data/maps/overworld/sector_5_2.bin"
OverworldMaps_Map_3EC84:
	incbin "data/maps/overworld/sector_5_3.bin"
OverworldMaps_Map_3ECA2:
	incbin "data/maps/overworld/sector_5_4.bin"
OverworldMaps_Map_3ECEA:
	incbin "data/maps/overworld/sector_5_5.bin"
OverworldMaps_Map_3ED68:
	incbin "data/maps/overworld/sector_5_6.bin"
OverworldMaps_Map_3EDC8:
	incbin "data/maps/overworld/sector_5_7.bin"
OverworldMaps_Map_3EE1C:
	incbin "data/maps/overworld/sector_6_0.bin"
OverworldMaps_Map_3EE30:
	incbin "data/maps/overworld/sector_6_1.bin"
OverworldMaps_Map_3EE9A:
	incbin "data/maps/overworld/sector_6_2.bin"
OverworldMaps_Map_3EF12:
	incbin "data/maps/overworld/sector_6_3.bin"
OverworldMaps_Map_3EF60:
	incbin "data/maps/overworld/sector_6_4.bin"
OverworldMaps_Map_3EFDA:
	incbin "data/maps/overworld/sector_6_5.bin"
OverworldMaps_Map_3F05A:
	incbin "data/maps/overworld/sector_6_6.bin"
OverworldMaps_Map_3F0D8:
	incbin "data/maps/overworld/sector_6_7.bin"
SpriteFrameData_3F134:
	incbin "data/maps/overworld/sector_7_0.bin"
OverworldMaps_Map_3F188:
	incbin "data/maps/overworld/sector_7_2.bin"
OverworldMapSector_F1AC:
	incbin "data/maps/overworld/sector_7_3.bin"
OverworldMaps_Map_3F20C:
	incbin "data/maps/overworld/sector_7_7.bin"
OverworldMaps_Map_3F250:
	incbin "data/maps/overworld/sector_8_0.bin"
OverworldMaps_Map_3F2CE:
	incbin "data/maps/overworld/sector_8_1.bin"
OverworldMaps_Map_3F304:
	incbin "data/maps/overworld/sector_8_2.bin"
OverworldMapSector_F33E:
	incbin "data/maps/overworld/sector_8_3.bin"
OverworldMaps_Map_3F388:
	incbin "data/maps/overworld/sector_8_6.bin"
SpriteFrameData_3F402:
	incbin "data/maps/overworld/sector_9_0.bin"
OverworldMaps_Map_3F438:
	incbin "data/maps/overworld/sector_9_1.bin"
OverworldMaps_Map_3F486:
	incbin "data/maps/overworld/sector_9_2.bin"
OverworldMaps_Map_3F4DA:
	incbin "data/maps/overworld/sector_9_3.bin"
OverworldMaps_Map_3F574:
	incbin "data/maps/overworld/sector_9_4.bin"
OverworldMaps_Map_3F5DC:
	incbin "data/maps/overworld/sector_9_5.bin"
OverworldMaps_Map_3F61E:
	incbin "data/maps/overworld/sector_9_6.bin"
SpriteFrameData_3F64E:
	incbin "data/maps/overworld/sector_10_0.bin"
SpriteFrameData_3F6DC:
	incbin "data/maps/overworld/sector_10_1.bin"
OverworldMapSector_F70A:
	incbin "data/maps/overworld/sector_10_3.bin"
OverworldMaps_Map_3F76E:
	incbin "data/maps/overworld/sector_10_6.bin"
OverworldMaps_Map_3F7CE:
	incbin "data/maps/overworld/sector_10_7.bin"
OverworldMaps_Map_3F85A:
	incbin "data/maps/overworld/sector_11_0.bin"
SpriteFrameData_3F880:
	incbin "data/maps/overworld/sector_11_1.bin"
SpriteFrameData_3F8F8:
	incbin "data/maps/overworld/sector_11_3.bin"
OverworldMaps_Map_3F992:
	incbin "data/maps/overworld/sector_11_5.bin"
SpriteFrameData_3FA54:
	incbin "data/maps/overworld/sector_11_6.bin"
OverworldMaps_Map_3FAF0:
	incbin "data/maps/overworld/sector_12_0.bin"
OverworldMaps_Map_3FB28:
	incbin "data/maps/overworld/sector_12_1.bin"
OverworldMaps_Map_3FB70:
	incbin "data/maps/overworld/sector_12_2.bin"
OverworldMaps_Map_3FBD2:
	incbin "data/maps/overworld/sector_12_3.bin"
OverworldMaps_Map_3FC1C:
	incbin "data/maps/overworld/sector_12_4.bin"
OverworldMaps_Map_3FC6A:
	incbin "data/maps/overworld/sector_12_5.bin"
OverworldMaps_Map_3FCB2:
	incbin "data/maps/overworld/sector_12_6.bin"
OverworldMaps_Map_3FD10:
	incbin "data/maps/overworld/sector_12_7.bin"
OverworldMaps_Map_3FD42:
	incbin "data/maps/overworld/sector_13_0.bin"
OverworldMaps_Map_3FD8A:
	incbin "data/maps/overworld/sector_13_1.bin"
OverworldMaps_Map_3FE08:
	incbin "data/maps/overworld/sector_13_2.bin"
OverworldMaps_Map_3FE5E:
	incbin "data/maps/overworld/sector_13_3.bin"
OverworldMaps_Map_3FE6C:
	incbin "data/maps/overworld/sector_13_4.bin"
OverworldMaps_Map_3FEB6:
	incbin "data/maps/overworld/sector_13_5.bin"
OverworldMaps_Map_3FF24:
	incbin "data/maps/overworld/sector_13_6.bin"
OverworldMapSector_FF68:
	incbin "data/maps/overworld/sector_14_0.bin"
OverworldMapSector_FFA0:
	incbin "data/maps/overworld/sector_14_1.bin"
OverworldMaps_Map_3FFD6:
	incbin "data/maps/overworld/sector_14_3.bin"
OverworldMapSector_40018:
	incbin "data/maps/overworld/data_40018.bin"
EnemySpriteData_FacingSide_Gfx_40020:
	incbin "data/maps/overworld/data_40020.bin"
OverworldMapSector_40028:
	incbin "data/maps/overworld/sector_14_4.bin"
OverworldMapSector_Empty:
	incbin "data/maps/overworld/sector_15_0.bin"

;==============================================================
; CAVE MAP POINTER TABLE
; 44 dc.l pointers (indices 0–43).
; Indices 29–30 share room_28.bin (same physical room).
;==============================================================
CaveMaps: ; 44 pointers
	dc.l	CaveMaps_Map_4014C
	dc.l	CaveMaps_Map_401BC
	dc.l	CaveMaps_Map_40270
	dc.l	CaveMaps_Map_402F4
	dc.l	CaveMaps_Map_403A4
	dc.l	CaveMaps_Map_40456
	dc.l	CaveMaps_Map_40506
	dc.l	CaveMaps_Map_405A8
	dc.l	CaveMaps_Map_4064A
	dc.l	CaveMaps_Map_406F0
	dc.l	CaveMaps_Map_40794
	dc.l	CaveMaps_Map_4082A
	dc.l	CaveMaps_Map_408C8
	dc.l	CaveMaps_Map_40984
	dc.l	CaveMaps_Map_40A10
	dc.l	CaveMaps_Map_40A78
	dc.l	CaveMaps_Map_40AF8
	dc.l	CaveMaps_Map_40B80
	dc.l	CaveMaps_Map_40BBC
	dc.l	CaveMaps_Map_40C56
	dc.l	CaveMaps_Map_40D0A
	dc.l	CaveMaps_Map_40DC6
	dc.l	CaveMaps_Map_40E46
	dc.l	CaveMaps_Map_40F14
	dc.l	CaveMaps_Map_40FAA
	dc.l	CaveMaps_Map_40FF6
	dc.l	CaveMaps_Map_41092
	dc.l	CaveMaps_Map_4112A
	dc.l	CaveMapSector_411C0	
	dc.l	CaveMapSector_411C0	
	dc.l	CaveMapSector_411C0
	dc.l	CaveMaps_Map_4125E
	dc.l	CaveMaps_Map_4131E
	dc.l	CaveMaps_Map_413B0
	dc.l	CaveMaps_Map_41456
	dc.l	CaveMaps_Map_41500
	dc.l	CaveMaps_Map_4158A
	dc.l	CaveMaps_Map_41622
	dc.l	CaveMaps_Map_41690
	dc.l	CaveMaps_Map_4170C
	dc.l	CaveMaps_Map_41794
	dc.l	CaveMaps_Map_4183C
	dc.l	CaveMaps_Map_418E0
	dc.l	CaveMaps_Map_4198E
;==============================================================
; CAVE ROOM DATA
; RLE-compressed 16×16 tile maps, one per cave room file.
; Same RLE encoding as overworld sectors.
; Labels use ROM-address suffix (DATA-001 — rename pending).
;==============================================================
CaveMaps_Map_4014C:
	incbin "data/maps/cave/room_00.bin"
CaveMaps_Map_401BC:
	incbin "data/maps/cave/room_01.bin"
CaveMaps_Map_40270:
	incbin "data/maps/cave/room_02.bin"
CaveMaps_Map_402F4:
	incbin "data/maps/cave/room_03.bin"
CaveMaps_Map_403A4:
	incbin "data/maps/cave/room_04.bin"
CaveMaps_Map_40456:
	incbin "data/maps/cave/room_05.bin"
CaveMaps_Map_40506:
	incbin "data/maps/cave/room_06.bin"
CaveMaps_Map_405A8:
	incbin "data/maps/cave/room_07.bin"
CaveMaps_Map_4064A:
	incbin "data/maps/cave/room_08.bin"
CaveMaps_Map_406F0:
	incbin "data/maps/cave/room_09.bin"
CaveMaps_Map_40794:
	incbin "data/maps/cave/room_10.bin"
CaveMaps_Map_4082A:
	incbin "data/maps/cave/room_11.bin"
CaveMaps_Map_408C8:
	incbin "data/maps/cave/room_12.bin"
CaveMaps_Map_40984:
	incbin "data/maps/cave/room_13.bin"
CaveMaps_Map_40A10:
	incbin "data/maps/cave/room_14.bin"
CaveMaps_Map_40A78:
	incbin "data/maps/cave/room_15.bin"
CaveMaps_Map_40AF8:
	incbin "data/maps/cave/room_16.bin"
CaveMaps_Map_40B80:
	incbin "data/maps/cave/room_17.bin"
CaveMaps_Map_40BBC:
	incbin "data/maps/cave/room_18.bin"
CaveMaps_Map_40C56:
	incbin "data/maps/cave/room_19.bin"
CaveMaps_Map_40D0A:
	incbin "data/maps/cave/room_20.bin"
CaveMaps_Map_40DC6:
	incbin "data/maps/cave/room_21.bin"
CaveMaps_Map_40E46:
	incbin "data/maps/cave/room_22.bin"
CaveMaps_Map_40F14:
	incbin "data/maps/cave/room_23.bin"
CaveMaps_Map_40FAA:
	incbin "data/maps/cave/room_24.bin"
CaveMaps_Map_40FF6:
	incbin "data/maps/cave/room_25.bin"
CaveMaps_Map_41092:
	incbin "data/maps/cave/room_26.bin"
CaveMaps_Map_4112A:
	incbin "data/maps/cave/room_27.bin"
CaveMapSector_411C0:
	incbin "data/maps/cave/room_28.bin"
CaveMaps_Map_4125E:
	incbin "data/maps/cave/room_31.bin"
CaveMaps_Map_4131E:
	incbin "data/maps/cave/room_32.bin"
CaveMaps_Map_413B0:
	incbin "data/maps/cave/room_33.bin"
CaveMaps_Map_41456:
	incbin "data/maps/cave/room_34.bin"
CaveMaps_Map_41500:
	incbin "data/maps/cave/room_35.bin"
CaveMaps_Map_4158A:
	incbin "data/maps/cave/room_36.bin"
CaveMaps_Map_41622:
	incbin "data/maps/cave/room_37.bin"
CaveMaps_Map_41690:
	incbin "data/maps/cave/room_38.bin"
CaveMaps_Map_4170C:
	incbin "data/maps/cave/room_39.bin"
CaveMaps_Map_41794:
	incbin "data/maps/cave/room_40.bin"
CaveMaps_Map_4183C:
	incbin "data/maps/cave/room_41.bin"
CaveMaps_Map_418E0:
	incbin "data/maps/cave/room_42.bin"
CaveMaps_Map_4198E:
	incbin "data/maps/cave/room_43.bin"
