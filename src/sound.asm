; ======================================================================
; src/sound.asm
; Sound System — Sword of Vermilion music/SFX driver for YM2612 (FM) and PSG.
;
; Responsibilities:
;   - Sound channel state machine tick (UpdateBattleEntities)
;   - Per-channel FM and PSG note/script sequencing
;   - Sound script command dispatcher (30 script commands)
;   - YM2612 register write with Z80 bus arbitration
;   - DAC sample upload to Z80 RAM
;   - LFO vibrato tables and FM frequency table
;   - Fade-out and global volume control
;   - Command queue processing (play/stop music and SFX)
;
; Channel struct: each FM/PSG channel is $30 bytes (fmch_*).
;   A3 = pointer to current channel's struct during processing.
;   A4 = current sound script read pointer (reconstructed from
;        fmch_script_ptr_hi/lo + base $00093C00 each tick).
;
; RAM layout (key addresses):
;   $FFF400  Sound_cmd_queue   - pending sound command byte
;   $FFF401  Sound_tempo_ctr   - tempo tick countdown
;   $FFF402  Sound_tempo_reload- tempo reload value
;   $FFF41C  Sound_fade_volume - fade-out volume level ($00=off)
;   $FFF41D  Sound_fade_speed  - fade-out tick rate
;   $FFF421  Sound_part_flag   - FM bank selector ($00=bank1, $80=bank2)
;   $FFF430  FM channel 0 struct (bank 1, channels 0-8, stride $30)
;   $FFF5E0  FM channel 0 struct (bank 2, channels 0-3, stride $30)
;   $FFF520  DAC/special channel struct
; ======================================================================

;==============================================================
; GRAPHICS DATA — TOWN TILESETS AND Z80 DRIVER
; Tile index lookup tables and Z80 sound driver binary data
; embedded at fixed ROM addresses. Not directly executed by
; the 68000; the Z80 driver data is copied to Z80 RAM at init.
;
; MOVE-006 NOTE: TownTilesetPtrs_Entry02 and
; TownTilesetPtrs_Entry03 below are town tileset index
; lookup tables and belong logically in gfxdata.asm alongside
; other graphics data. They are stranded here because the
; disassembler placed them at these ROM addresses inside the
; sound driver region. Physical relocation would change all
; downstream ROM offsets and break bit-perfect output.
;==============================================================
TownTilesetPtrs_Entry02:
	dc.b	$00, $00 
	dc.b	$00, $00, $00, $00, $00, $00, $00, $01, $00, $02, $00, $03, $00, $04, $00, $05, $00, $06, $00, $07, $00, $08, $00, $09, $00, $0A, $00, $07, $00, $08, $00, $0B 
	dc.b	$00, $0C, $00, $0D, $00, $0E, $00, $0F, $00, $02, $00, $10, $00, $04, $00, $0F, $00, $11, $00, $10, $00, $12, $00, $13, $00, $14, $00, $15, $00, $16, $00, $17 
	dc.b	$00, $18, $00, $19, $00, $1A, $00, $17, $00, $18, $00, $1B, $00, $1C, $00, $17, $00, $18, $00, $1D, $00, $1E, $00, $17, $00, $18, $00, $1D, $00, $1D, $00, $17 
	dc.b	$00, $18, $00, $1F, $00, $1D, $00, $17, $00, $18, $00, $1D, $00, $20, $00, $17, $00, $18, $00, $21, $00, $22, $00, $23, $00, $24, $00, $1D, $00, $25, $00, $26 
	dc.b	$00, $27, $00, $28, $00, $29, $00, $1D, $00, $2A, $00, $1D, $00, $2B, $00, $2C, $00, $2D, $00, $2E, $00, $2F, $00, $1D, $00, $1D, $00, $1D, $00, $30, $00, $1D 
	dc.b	$00, $31, $00, $1D, $00, $1D, $00, $1D, $00, $32, $00, $1D, $00, $33, $00, $1D, $00, $20, $00, $1D, $00, $34, $00, $35, $00, $1D, $00, $36, $00, $1D, $00, $1D 
	dc.b	$00, $37, $00, $1D, $00, $25, $00, $38, $00, $16, $00, $39, $00, $16, $00, $1D, $00, $3A, $00, $1D, $00, $3B, $00, $1D, $00, $3C, $00, $3D, $00, $25, $00, $3E 
	dc.b	$00, $3F, $00, $40, $00, $41, $00, $42, $00, $43, $00, $44, $00, $45, $00, $46, $00, $47, $00, $48, $00, $49, $00, $4A, $00, $4B, $00, $44, $00, $45, $00, $4C 
	dc.b	$00, $4D, $00, $26, $00, $27, $00, $4E, $00, $4F, $00, $48, $00, $49, $00, $42, $00, $50, $00, $44, $00, $45, $00, $1D, $00, $51 
Z80DrvrData_90002:
	dc.b	$00, $52, $00, $1D, $00, $53 
Z80DrvrData_90008:
	dc.b	$00, $50, $00, $54, $00, $45, $00, $55, $00, $4B, $00, $44, $00, $45, $00, $56, $00, $57, $00, $58, $00, $59, $00, $4C, $00, $4D, $00, $58, $00, $59, $00, $28 
	dc.b	$00, $29, $00, $58, $00, $59, $00, $4C, $00, $4D, $00, $5A, $00, $5B, $00, $56, $00, $57, $00, $58, $00, $5C, $00, $28, $00, $29, $00, $5D, $00, $5E, $00, $5F 
	dc.b	$00, $59, $00, $5A, $00, $5B, $00, $58, $00, $5C, $00, $5A, $00, $60, $00, $61, $00, $59, $00, $62, $00, $60, $00, $63, $00, $59, $00, $5A, $00, $5B, $00, $64 
	dc.b	$00, $65, $00, $66, $00, $67, $00, $68, $00, $69, $00, $6A, $00, $6A, $00, $6B, $00, $6C, $00, $6A, $00, $6A, $00, $6B, $00, $6D, $00, $6A, $00, $6E, $00, $6F 
	dc.b	$00, $17, $00, $70, $00, $17, $00, $18, $00, $17, $00, $19, $00, $1A, $00, $18, $00, $17, $00, $1B, $00, $1C, $00, $18, $00, $17, $00, $1D, $00, $1E, $00, $18 
	dc.b	$00, $17, $00, $1D, $00, $1D, $00, $18, $00, $17, $00, $1F, $00, $33, $00, $18, $00, $71, $00, $1D, $00, $20, $00, $72, $00, $73, $00, $21, $00, $74, $00, $75 
	dc.b	$00, $76, $00, $77, $00, $78, $00, $79, $00, $17, $00, $7A, $00, $16, $00, $2C, $00, $2D, $00, $1D, $00, $1D, $00, $1D, $00, $1D, $00, $7B, $00, $7C, $00, $1D 
	dc.b	$00, $31, $00, $1D, $00, $31, $00, $35, $00, $7D, $00, $7E, $00, $7F, $00, $80, $00, $81, $00, $82, $00, $83, $00, $84, $00, $17, $00, $85, $00, $16, $00, $1D 
	dc.b	$00, $86, $00, $1D, $00, $87, $00, $88, $00, $89, $00, $8A, $00, $8B, $00, $8C, $00, $8D, $00, $8E, $00, $8F, $00, $90, $00, $91, $00, $8E, $00, $92, $00, $93 
	dc.b	$00, $94, $00, $95, $00, $96, $00, $97, $00, $98, $00, $99, $00, $9A, $00, $88, $00, $9B, $00, $8A, $00, $8B, $00, $6A, $00, $6A, $00, $8E, $00, $8E, $00, $9C 
	dc.b	$00, $9D, $00, $9E, $00, $9F, $00, $A0, $00, $A1, $00, $8E, $00, $8E, $00, $A2, $00, $A3, $00, $A4, $00, $A5, $00, $A6, $00, $A7, $00, $A8, $00, $A8, $00, $A9 
	dc.b	$00, $AA, $00, $A8, $00, $AB, $00, $AC, $00, $AD, $00, $8E, $00, $AE, $00, $AF, $00, $AF, $00, $AF, $00, $AF, $00, $AF, $00, $AC, $00, $AF, $00, $8E, $00, $61 
	dc.b	$00, $59, $00, $5F, $00, $59, $00, $5A, $00, $5B, $00, $5F, $00, $59, $00, $5A, $00, $5B, $00, $62, $00, $60, $00, $B0, $00, $B1, $00, $B2, $00, $B3, $00, $B4 
	dc.b	$00, $B5, $00, $B6, $00, $B7, $00, $B8, $00, $B9, $00, $BA, $00, $BB, $00, $BC, $00, $BD, $00, $BE, $00, $BF, $00, $C0, $00, $C0, $00, $C0, $00, $C0, $00, $C1 
	dc.b	$00, $C2, $00, $C3, $00, $C4, $00, $C2, $00, $C2, $00, $C2, $00, $C2, $00, $C2, $00, $C2, $00, $C5, $00, $C6, $00, $C2, $00, $C7, $00, $C8, $00, $C0, $00, $C9 
	dc.b	$00, $CA, $00, $CB, $00, $C0, $00, $CC, $00, $CD, $00, $C0, $00, $CE, $00, $C2, $00, $CF, $00, $D0, $00, $D1, $00, $D2, $00, $D3, $00, $D4, $00, $D5, $00, $D6 
	dc.b	$00, $D7, $00, $D8, $00, $D9, $00, $DA, $00, $DB, $00, $DA, $00, $DB, $00, $DC, $00, $DD, $00, $BD, $00, $BF, $00, $DE, $00, $DF, $00, $BD, $00, $BF, $00, $E0 
	dc.b	$00, $E1, $00, $BD, $00, $BF, $00, $E2, $00, $E3, $00, $BD, $00, $BF, $00, $E4, $00, $E4, $00, $C0, $00, $C0, $00, $E5, $00, $E6, $00, $E7, $00, $E8, $00, $E9 
	dc.b	$00, $EA, $00, $C0, $00, $EB, $00, $EC, $00, $ED, $00, $EE, $00, $C0, $00, $EF, $00, $F0, $00, $F1, $00, $F2, $00, $C0, $00, $F3, $00, $C0, $00, $F4, $00, $F5 
	dc.b	$00, $C0, $00, $C0, $00, $C0, $00, $F6, $00, $C0, $00, $C0, $00, $C0, $00, $F7, $00, $00, $00, $F8, $00, $00, $00, $00, $00, $F9, $00, $00, $00, $FA, $00, $00 
	dc.b	$00, $00, $00, $00, $00, $FB, $00, $FC, $00, $FD, $00, $FE, $00, $FF, $00, $00, $00, $00, $01, $00, $00, $00, $00, $42, $01, $01, $01, $02, $00, $45, $01, $03 
	dc.b	$01, $04, $01, $05, $01, $06, $01, $07, $01, $08, $01, $09, $01, $0A, $00, $4C, $00, $4D, $01, $0B, $00, $59, $01, $0C, $01, $0D, $01, $0E, $01, $0F, $01, $10 
	dc.b	$01, $11, $00, $BD, $00, $BF, $00, $BF, $01, $12, $00, $BD, $01, $13, $00, $BF, $01, $14, $01, $15, $01, $16, $00, $BF, $01, $17, $00, $BD, $01, $18, $00, $BF 
	dc.b	$00, $BD, $00, $BD, $00, $BF, $00, $00, $01, $19, $00, $00, $00, $C0, $01, $1A, $00, $00, $00, $C0, $00, $00, $00, $C0, $00, $00, $00, $C0, $00, $00, $00, $00 
	dc.b	$00, $C0, $00, $00, $00, $C0, $01, $1B, $00, $BD, $01, $1C, $00, $BF, $00, $BF, $01, $1D, $00, $BD, $01, $1E, $00, $BF, $00, $BD, $00, $BA, $00, $BB, $00, $B8 
	dc.b	$00, $B9, $00, $BD, $00, $BF 
LoadBattleHudGraphics_Data:
	incbin "data/art/tiles/battle/hud_gfx_1.bin"
LoadBattleHudGraphics_Done_Data:
	incbin "data/art/tiles/battle/hud_gfx_2.bin"
TownTilesetPtrs_Entry03:
	dc.b	$00, $00 
	dc.b	$00, $00, $00, $00, $00, $00, $00, $01, $00, $02, $00, $03, $00, $04, $00, $00, $00, $00, $00, $05, $00, $06, $00, $00, $00, $00, $00, $07, $00, $08, $00, $09 
	dc.b	$00, $0A, $00, $0B, $00, $0C, $00, $0D, $00, $0E, $00, $0F, $00, $10, $00, $03, $00, $04, $00, $03, $00, $04, $00, $11, $00, $12, $00, $13, $00, $14, $00, $15 
	dc.b	$00, $16, $00, $17, $00, $18, $00, $19, $00, $1A, $00, $1B, $00, $1C, $00, $1D, $00, $1E, $00, $1B, $00, $1C, $00, $1F, $00, $20, $00, $00, $00, $00, $00, $21 
	dc.b	$00, $22, $00, $23, $00, $24, $00, $25, $00, $25, $00, $25, $00, $25, $00, $00, $00, $26, $00, $00, $00, $00, $00, $01, $00, $02, $00, $27, $00, $28, $00, $01 
	dc.b	$00, $02, $00, $29, $00, $2A, $00, $2B, $00, $2C, $00, $2D, $00, $2E, $00, $2F, $00, $30, $00, $31, $00, $32, $00, $33, $00, $34, $00, $33, $00, $34, $00, $00 
	dc.b	$00, $00, $00, $26, $00, $00, $00, $27, $00, $28, $00, $27, $00, $28, $00, $29, $00, $35, $00, $29, $00, $36, $00, $37, $00, $37, $00, $38, $00, $39, $00, $00 
	dc.b	$00, $00, $00, $00, $00, $26, $00, $27, $00, $28, $00, $00, $00, $00, $00, $29, $00, $35, $00, $00, $00, $00, $00, $3A, $00, $3B, $00, $3C, $00, $3D, $00, $3E 
	dc.b	$00, $00, $00, $00, $00, $00, $00, $3F, $00, $40, $00, $41, $00, $42, $00, $43, $00, $44, $00, $45, $00, $46, $00, $47, $00, $48, $00, $49, $00, $4A, $00, $4B 
	dc.b	$00, $4C, $00, $4D, $00, $4E, $00, $4F, $00, $50, $00, $51, $00, $52, $00, $53, $00, $50, $00, $54, $00, $55, $00, $56, $00, $57, $00, $58, $00, $59, $00, $5A 
	dc.b	$00, $5B, $00, $5C, $00, $5D, $00, $5E, $00, $5F, $00, $00, $00, $00, $00, $60, $00, $61, $00, $62, $00, $62, $00, $63, $00, $64, $00, $62, $00, $62, $00, $65 
	dc.b	$00, $66, $00, $00, $00, $00, $00, $67, $00, $68, $00, $00, $00, $00, $00, $58, $00, $59, $00, $65, $00, $66, $00, $5C, $00, $5D, $00, $67, $00, $68, $00, $69 
	dc.b	$00, $6A, $00, $6B, $00, $6C, $00, $6D, $00, $6E, $00, $6F, $00, $70, $00, $71, $00, $72, $00, $73, $00, $74, $00, $75, $00, $75, $00, $76, $00, $76, $00, $77 
	dc.b	$00, $78, $00, $79, $00, $7A, $00, $7B, $00, $7C, $00, $7D, $00, $7E, $00, $7F, $00, $80, $00, $7F, $00, $80, $00, $81, $00, $81, $00, $00, $00, $00, $00, $82 
	dc.b	$00, $83, $00, $84, $00, $85, $00, $86, $00, $87, $00, $88, $00, $89, $00, $8A, $00, $8B, $00, $00, $00, $00, $00, $00, $00, $8C, $00, $00, $00, $00, $00, $00 
	dc.b	$00, $00, $00, $8C, $00, $00, $00, $8D, $00, $8E, $00, $8F, $00, $90, $00, $91, $00, $92, $00, $93, $00, $94, $00, $91, $00, $92, $00, $95, $00, $90, $00, $91 
	dc.b	$00, $96, $00, $95, $00, $97, $00, $8F, $00, $97, $00, $8F, $00, $97, $00, $98, $00, $99, $00, $9A, $00, $99, $00, $9B, $00, $99, $00, $9B, $00, $99, $00, $9C 
	dc.b	$00, $99, $00, $9C, $00, $99, $00, $9D, $00, $9E, $00, $9D, $00, $9F, $00, $8F, $00, $97, $00, $A0, $00, $A1, $00, $8D, $00, $96, $00, $8F, $00, $97, $00, $8F 
	dc.b	$00, $A2, $00, $A0, $00, $93, $00, $91, $00, $96, $00, $94, $00, $A1, $00, $8D, $00, $92, $00, $A0, $00, $93, $00, $A3, $00, $A2, $00, $94, $00, $93, $00, $A3 
	dc.b	$00, $A4, $00, $94, $00, $A1, $00, $A5, $00, $A6, $00, $A7, $00, $A8, $00, $A6, $00, $A6, $00, $A9, $00, $A9, $00, $A6, $00, $A6, $00, $AA, $00, $A8, $00, $A6 
	dc.b	$00, $AB, $00, $AA, $00, $AC, $00, $A7, $00, $AC, $00, $A7, $00, $AC, $00, $AD, $00, $AE, $00, $AF, $00, $AE, $00, $AE, $00, $AE, $00, $AE, $00, $AE, $00, $B0 
	dc.b	$00, $AD, $00, $B0, $00, $AF, $00, $A7, $00, $AC, $00, $B1, $00, $B2, $00, $A5, $00, $AB, $00, $A7, $00, $AC, $00, $A7, $00, $B3, $00, $B1, $00, $A9, $00, $A6 
	dc.b	$00, $AB, $00, $A9, $00, $B2, $00, $A5, $00, $A6, $00, $B1, $00, $A9, $00, $B4, $00, $B3, $00, $A9, $00, $A9, $00, $B4, $00, $AC, $00, $A9, $00, $B2, $00, $B5 
	dc.b	$00, $B6, $00, $B7, $00, $B8, $00, $B9, $00, $00, $00, $00, $00, $00, $00, $BA, $00, $00, $00, $00, $00, $00, $00, $BB, $00, $BA, $00, $BC, $00, $BD, $00, $BE 
	dc.b	$00, $BF, $00, $C0, $00, $BF, $00, $BF, $00, $BF, $00, $BF, $00, $BF, $00, $BA, $00, $BA, $00, $BD, $00, $BD, $00, $C1, $00, $C2, $00, $C3, $00, $C4, $00, $C5 
	dc.b	$00, $BE, $00, $C5, $00, $C0, $00, $BD, $00, $BD, $00, $C6, $00, $C7, $00, $C8, $00, $C8, $00, $C9, $00, $CA, $00, $CB, $00, $CB, $00, $CC, $00, $CC, $00, $CD 
	dc.b	$00, $CD, $00, $CA, $00, $CA, $00, $C9, $00, $CA, $00, $C9, $00, $CA, $00, $CC, $00, $CC, $00, $CC, $00, $CC, $00, $CA, $00, $CA, $00, $CA, $00, $CA, $00, $B5 
	dc.b	$00, $00, $00, $00, $00, $00, $00, $C9, $00, $C9, $00, $CA, $00, $CA, $00, $00, $00, $B9, $00, $00, $00, $CE, $00, $CF, $00, $CF, $00, $D0, $00, $D0, $00, $D1 
	dc.b	$00, $00, $00, $D2, $00, $00, $00, $00, $00, $D3, $00, $00, $00, $D4, $00, $D5, $00, $D5, $00, $D6, $00, $D6, $00, $D7, $00, $00, $00, $D8, $00, $00, $00, $D9 
	dc.b	$00, $D9, $00, $D9, $00, $DA, $00, $DB, $00, $DC, $00, $DC, $00, $DB, $00, $D9, $00, $DA, $00, $D9, $00, $DA, $00, $DD, $00, $DE, $00, $DF, $00, $E0, $00, $CC 
	dc.b	$00, $CC, $00, $E1, $00, $E1, $00, $D9, $00, $DA, $00, $DA, $00, $DA, $00, $E2, $00, $E3, $00, $E4, $00, $E5, $00, $D9, $00, $D9, $00, $DA, $00, $DA, $00, $E1 
	dc.b	$00, $E1, $00, $E1, $00, $E1, $00, $D9, $00, $D9, $00, $D9, $00, $D9, $00, $DA, $00, $DA, $00, $DA, $00, $DA, $00, $00, $00, $00, $00, $B5, $00, $00, $00, $E6 
	dc.b	$00, $E6, $00, $CC, $00, $CC, $00, $E7, $00, $E3, $00, $E8, $00, $E5, $00, $E9, $00, $EA, $00, $EB, $00, $EC, $00, $26, $00, $8C, $00, $8C, $00, $26, $00, $00 
	dc.b	$00, $B5, $00, $00, $00, $00, $00, $ED, $00, $EE, $00, $EF, $00, $00, $00, $F0, $00, $F1, $00, $00, $00, $F2, $00, $F3, $00, $00, $00, $F4, $00, $00, $00, $00 
	dc.b	$00, $F5, $00, $00, $00, $F6, $00, $F7, $00, $E3, $00, $F8, $00, $F9, $00, $E7, $00, $FA, $00, $FB, $00, $FC, $00, $FD, $00, $FE, $00, $FF, $01, $00, $00, $FE 
	dc.b	$01, $01, $01, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $BA, $01, $03, $00, $00, $00, $00, $00, $00, $00, $00, $01, $03, $00, $00, $00, $00, $00, $00 
	dc.b	$00, $00, $01, $03, $00, $00, $00, $00, $00, $00, $00, $00, $01, $03, $01, $04, $00, $00, $00, $00, $00, $00, $01, $05, $01, $06, $01, $07, $01, $08, $01, $09 
	dc.b	$01, $0A, $01, $0B, $01, $0C, $01, $0D, $01, $0E, $01, $0F, $01, $10, $01, $11, $01, $12, $01, $13, $01, $14, $01, $15, $01, $16, $01, $17, $01, $18, $01, $19 
	dc.b	$01, $12, $01, $1A, $01, $1B, $01, $1C, $01, $04, $01, $1D, $01, $1E, $01, $1F, $01, $20, $01, $21, $01, $22, $01, $23, $01, $24, $01, $1D, $01, $25, $01, $26 
	dc.b	$01, $27, $01, $28, $01, $29, $01, $2A, $01, $2B, $01, $1D, $01, $2C, $01, $2D, $01, $2E, $01, $2F, $01, $30, $00, $00, $01, $04, $00, $00, $00, $00, $00, $00 
	dc.b	$00, $00, $01, $04, $00, $00, $00, $00, $00, $00, $00, $00, $01, $04, $01, $06, $00, $00, $00, $00, $00, $00, $00, $00, $01, $06, $00, $00, $00, $00, $01, $31 
	dc.b	$01, $32, $01, $33, $01, $34, $01, $31, $01, $32, $01, $35, $01, $36, $01, $31, $01, $32, $00, $3E, $01, $37, $01, $38, $01, $39, $00, $3E, $01, $37, $01, $37 
	dc.b	$00, $3E, $00, $3E, $01, $37, $01, $37, $00, $3E, $01, $35, $01, $36, $00, $00, $00, $00, $01, $06, $00, $00, $00, $00, $00, $00, $00, $00, $01, $06, $01, $01 
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $00, $00, $00, $00, $00, $F0, $00, $EE, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b	$FF, $FF, $FF, $FF 
;==============================================================
; MAIN SOUND UPDATE ENTRY
; Called once per frame to tick the entire sound driver.
;==============================================================

; UpdateBattleEntities
; Top-level sound driver tick. Processes command queue, tempo,
; fade-out, then steps all FM and PSG sound channels.
UpdateBattleEntities:
	LEA	$00FFF430, A3
	BSR.w	ProcessSound_CommandQueue
	BSR.w	ProcessSound_TempoCounter
	BSR.w	ProcessSound_FadeOut
	BSR.w	ProcessFMSoundChannels
	RTS

; ProcessFMSoundChannels
; Iterates over all 13 FM/PSG channels in two banks and calls
; ProcessSoundChannel_FM for each active channel (bit 7 set).
; Bank 1: 9 channels at $FFF430, Bank 2: 4 channels at $FFF5E0.
ProcessFMSoundChannels:
	MOVE.b	#0, $00FFF421
	MOVE.w	#8, D6
	LEA	$00FFF430, A3
ProcessFMSoundChannels_Done:
	MOVE.l	D6, -(A7)
	BTST.b	#7, (A3)
	BEQ.b	ProcessFMSoundChannels_Loop
	BSR.w	ProcessSoundChannel_FM
ProcessFMSoundChannels_Loop:
	ADDA.w	#$0030, A3
	MOVE.l	(A7)+, D6
	DBF	D6, ProcessFMSoundChannels_Done
	MOVE.b	#$80, $00FFF421
	MOVE.w	#3, D6
	LEA	$00FFF5E0, A3
ProcessFMSoundChannels_Loop_Done:
	MOVE.l	D6, -(A7)
	BTST.b	#7, (A3)
	BEQ.b	ProcessFMSoundChannels_Loop2
	BSR.w	ProcessSoundChannel_FM
ProcessFMSoundChannels_Loop2:
	ADDA.w	#$0030, A3
	MOVE.l	(A7)+, D6
	DBF	D6, ProcessFMSoundChannels_Loop_Done
	RTS

;==============================================================
; FM CHANNEL PROCESSOR
; Per-channel state machine: reads note/script data and drives
; YM2612 register writes and DAC output each tick.
;==============================================================

; ProcessSoundChannel_FM
; Dispatches channel processing based on channel_id flags.
; Bit 7 of channel_id set: use FM data sequencer path.
; Bit 4 of channel_id set: use pitch-slide path.
; Otherwise: read next script byte and process note/command.
; Inputs: A3 = channel struct pointer
ProcessSoundChannel_FM:
	MOVE.b	fmch_channel_id(A3), D7
	BPL.w	ProcessSoundChannel_FM_Loop
	JMP	ProcessSoundChannel_FM_Data
ProcessSoundChannel_FM_Loop:
	BTST.l	#4, D7
	BNE.w	ProcessSoundChannel_FM_Loop2
	BRA.w	SetSoundNote_Positive_Loop
ProcessSoundChannel_FM_Loop2:
	SUBQ.w	#1, fmch_tick_ctr(A3)
	BNE.w	WriteSoundRegister_Return
	BSR.w	LoadSoundScriptPointer
	MOVE.b	(A4)+, D5
SoundChannel_NoteLoop:
	CMPI.b	#SOUND_SCRIPT_CMD_THRESHOLD, D5
	BCS.b	SoundChannel_NoteLoop_Loop
	BSR.w	ProcessSoundScriptCommand
	BRA.b	SoundChannel_NoteLoop
SoundChannel_NoteLoop_Loop:
	BTST.b	#4, fmch_channel_id(A3)
	BNE.b	SoundChannel_NoteLoop_Loop2
	MOVE.l	#SoundChannel_NoteLoop_Loop_Data, -(A7)
	BRA.w	SoundChannel_NoteLoop2
SoundChannel_NoteLoop_Loop2:
	BTST.b	#6, fmch_flags(A3)
	BNE.w	SoundChannel_NoteLoop_Loop3
	BTST.b	#2, fmch_flags(A3)
	BNE.w	SoundChannel_NoteLoop_Loop4
	MOVE.w	#$0100, Z80_bus_request
	MOVE.b	D5, $00A01FFF
	MOVE.b	#0, $00A01FFE
	MOVE.w	#0, Z80_bus_request
SoundChannel_NoteLoop_Loop4:
	BRA.w	SetSoundNoteAndDuration
SoundChannel_NoteLoop_Loop3:
	BSR.w	SetSoundNoteAndDuration
	BTST.b	#2, fmch_flags(A3)
	BNE.w	WriteSoundRegister_Return
	MOVE.b	fmch_note_freq(A3), D7
	BNE.w	SoundChannel_NoteLoop_Loop5
	MOVE.w	#$0100, Z80_bus_request
	MOVE.b	#0, $00A01FFF
	MOVE.w	#0, Z80_bus_request
	RTS
	
SoundChannel_NoteLoop_Loop5:
	ADD.b	fmch_transpose(A3), D7
	MOVE.b	fmch_arpeggio_idx(A3), D5
	MOVE.w	#$0100, Z80_bus_request
	MOVE.b	D7, $00A01FFE
	MOVE.b	D5, $00A01FFF
	MOVE.w	#0, Z80_bus_request
WriteSoundRegister_Return:
	RTS

;==============================================================
; PSG / NOTE HELPERS
; Handle note frequency, duration, pitch modulation (vibrato
; and pitch-bend), and PSG hardware frequency writes.
;==============================================================

; SetSoundNoteAndDuration
; Decodes a note byte from the script. Negative (bit 7 set)
; means the high 7 bits are a frequency override; positive is
; a duration value. Calls UpdateSoundChannelPitch afterwards.
; Inputs: D5 = note byte, A3 = channel struct, A4 = script ptr
SetSoundNoteAndDuration:
	TST.b	D5
	BPL.b	SetSoundNote_Positive
	ANDI.b	#$7F, D5
	MOVE.b	D5, fmch_note_freq(A3)
	MOVE.b	(A4)+, D5
	TST.b	D5
	BPL.w	SetSoundNote_Positive
	MOVE.b	-(A4), D5
	BRA.w	SetSoundNote_Positive_Loop2
SetSoundNote_Positive:
	BSR.w	SetSoundNoteDuration
SetSoundNote_Positive_Loop2:
	BSR.w	UpdateSoundChannelPitch
	RTS
	
SetSoundNote_Positive_Loop:
	BTST.b	#5, (A3)
	BNE.w	SetSoundNote_Positive2_Loop
	SUBQ.w	#1, fmch_tick_ctr(A3)
	BNE.w	SetSoundNote_Positive_Loop3
	BSR.w	LoadNextSoundNote
SoundChannel_NoteLoop_Loop_Data:
	BSR.w	ProcessPSGChannelNoteSequence
	BSR.w	UpdateYM2612KeyOff
	RTS
	
SetSoundNote_Positive_Loop3:
	BSR.w	ApplyPSG_PitchModulation
	RTS
	
LoadNextSoundNote:
	BCLR.b	#1, fmch_flags(A3)
	BSR.w	LoadSoundScriptPointer
	MOVE.b	(A4)+, D5
SoundChannel_NoteLoop2:
	CMPI.b	#SOUND_SCRIPT_CMD_THRESHOLD, D5
	BCS.w	SoundChannel_NoteLoop2_Loop
	BSR.w	ProcessSoundScriptCommand
	BRA.b	SoundChannel_NoteLoop2
SoundChannel_NoteLoop2_Loop:
	BTST.b	#4, fmch_channel_id(A3)
	BNE.w	SoundChannel_NoteLoop
	BTST.b	#5, fmch_flags(A3)
	BNE.w	LoadNextSoundNote_WithPitchSlide_Loop
SoundChannel_NoteLoop2_Loop_Done:
	BSR.w	WriteFMChannelRegisters
	TST.b	D5
	BPL.w	SetSoundNote_Positive2
	BSR.w	SetPSGNoteFrequency
	MOVE.b	(A4)+, D5
	TST.b	D5
	BPL.w	SetSoundNote_Positive2
	MOVE.b	-(A4), D5
	BRA.w	SetSoundNote_Positive2_Loop2
SetSoundNote_Positive2:
	BSR.w	SetSoundNoteDuration
SetSoundNote_Positive2_Loop2:
	BSR.w	UpdateSoundChannelPitch
	RTS
	
SetSoundNote_Positive2_Loop:
	SUBQ.w	#1, fmch_tick_ctr(A3)
	BNE.w	SetSoundNote_Positive2_Loop3
	BSR.w	LoadNextSoundNote_WithPitchSlide
	BSR.w	ProcessPSGChannelNoteSequence
	BSR.w	UpdateYM2612KeyOff
	RTS
	
SetSoundNote_Positive2_Loop3:
	BSR.w	ApplyPSG_PitchBend
	BSR.w	ProcessPSGChannelNoteSequence
	RTS
	
LoadNextSoundNote_WithPitchSlide:
	BCLR.b	#1, fmch_flags(A3)
	BSR.w	LoadSoundScriptPointer
	MOVE.b	(A4)+, D5
LoadNextSoundNote_WithPitchSlide_Done:
	CMPI.b	#SOUND_SCRIPT_CMD_THRESHOLD, D5
	BCS.w	LoadNextSoundNote_WithPitchSlide_Loop2
	BSR.w	ProcessSoundScriptCommand
	BRA.b	LoadNextSoundNote_WithPitchSlide_Done
LoadNextSoundNote_WithPitchSlide_Loop2:
	BTST.b	#5, fmch_flags(A3)
	BEQ.w	SoundChannel_NoteLoop2_Loop_Done
LoadNextSoundNote_WithPitchSlide_Loop:
	BSR.w	WriteFMChannelRegisters
	BSR.w	SetPSGNoteFrequency
	MOVE.b	(A4)+, fmch_pitch_slide(A3)
	MOVE.b	(A4)+, D5
	BPL.w	LoadNextSoundNote_WithPitchSlide_Loop3
	BSR.w	UpdateSoundChannelPitch	
	RTS
	
LoadNextSoundNote_WithPitchSlide_Loop3:
	BSR.w	SetSoundNoteDuration
	BSR.w	UpdateSoundChannelPitch
	RTS
	
; ApplyPSG_PitchBend
; Adds or subtracts fmch_pitch_slide from note_freq each tick
; to produce a linear pitch-bend effect on PSG channels.
; Inputs: A3 = channel struct
ApplyPSG_PitchBend:
	MOVE.w	#0, D0
	MOVE.w	fmch_note_freq(A3), D1
	MOVE.b	fmch_pitch_slide(A3), D0
	BMI.w	ApplyPSG_PitchBend_Loop
	ADD.w	D0, D1
	MOVE.w	D1, fmch_note_freq(A3)
	RTS
	
ApplyPSG_PitchBend_Loop:
	NEG.b	D0
	SUB.w	D0, D1
	MOVE.w	D1, fmch_note_freq(A3)
	RTS
	
; SetSoundNoteDuration
; Stores D5 (note duration byte) into fmch_note_duration.
; If the double-tempo flag (bit 1 of tempo_flags) is set,
; duration is shifted left 1 (doubled).
; Inputs: D5 = duration, A3 = channel struct
SetSoundNoteDuration:
	ANDI.w	#$00FF, D5
	BTST.b	#1, fmch_tempo_flags(A3)
	BEQ.w	SetSoundNoteDuration_Loop
	LSL.w	#1, D5
SetSoundNoteDuration_Loop:
	MOVE.w	D5, fmch_note_duration(A3)
	RTS
	
; UpdateSoundChannelPitch
; Copies note_duration to tick_ctr and saves the current script
; pointer back into the channel struct (hi/lo byte pair).
; Resets LFO depth and phase if vibrato is not active.
; Inputs: A3 = channel struct, A4 = script pointer
UpdateSoundChannelPitch:
	MOVE.w	fmch_note_duration(A3), fmch_tick_ctr(A3)
	MOVE.l	A4, D5
	SUBI.l	#$00093C00, D5
	MOVE.b	D5, fmch_script_ptr_lo(A3)
	LSR.w	#8, D5
	MOVE.b	D5, fmch_script_ptr_hi(A3)
	BTST.b	#1, fmch_flags(A3)
	BNE.w	WaitPSG_ChannelFree_Return
	MOVEQ	#0, D0
	MOVE.b	D0, fmch_lfo_depth(A3)
	BTST.b	#1, fmch_flags(A3)
	BNE.b	WaitPSG_ChannelFree_Return
	MOVE.b	D0, fmch_lfo_phase(A3)
WaitPSG_ChannelFree_Return:
	RTS
	
; ApplyPSG_PitchModulation
; Checks whether vibrato is active (vibrato_idx != 0) and if so
; falls through to ProcessPSGChannelNoteSequence. Otherwise RTS.
; Inputs: A3 = channel struct
ApplyPSG_PitchModulation:
	MOVE.b	fmch_vibrato_idx(A3), D7
	BNE.w	ProcessPSGChannelNoteSequence
	RTS
	
; ProcessPSGChannelNoteSequence
; Applies LFO vibrato to the channel's note frequency and writes
; the result to the PSG/YM2612 via WriteYM2612Register.
; Reads LFO waveform from the table pointed to by vibrato_idx.
; Special bytes $80/$81/$82/$83/$84 control loop/jump/bend.
; Inputs: A3 = channel struct
ProcessPSGChannelNoteSequence:
	MOVE.w	fmch_note_freq(A3), D4
	BEQ.w	PSGPitch_WriteFrequency_Return
	CLR.w	D7
	MOVE.b	fmch_vibrato_idx(A3), D7
	BEQ.w	PSGPitch_WriteFrequency
	SUBQ.w	#1, D7
	MOVEQ	#0, D0
	MOVE.b	D7, D0
	LEA	SoundLFO_PointerTable, A0
	LSL.w	#2, D0
	MOVEA.l	(A0,D0.w), A0
	MOVEQ	#0, D0
	MOVE.w	D0, D1
	MOVE.b	fmch_lfo_phase(A3), D0
PSGChannel_NoteLoop:
	MOVE.b	(A0,D0.w), D1
	ADDQ.w	#1, D0
	MOVE.b	D0, fmch_lfo_phase(A3)
	CMPI.b	#NOTESCR_REST, D1
	BEQ.b	PSGPitch_ClampHigh_Loop
	CMPI.b	#NOTESCR_LOOP, D1
	BEQ.b	PSGPitch_ClampHigh_Loop2
	CMPI.b	#NOTESCR_JUMP, D1
	BEQ.b	PSGPitch_ClampHigh_Loop3
	CMPI.b	#NOTESCR_PITCHBEND, D1
	BEQ.b	PSGPitch_ClampHigh_Loop4
	CMPI.b	#NOTESCR_RESTART, D1
	BEQ.b	PSGPitch_ClampHigh_Loop5
	BCS.w	PSGPitch_ClampHigh
	ORI.w	#$FF00, D1
PSGPitch_ClampHigh:
	MOVE.b	fmch_lfo_depth(A3), D3
	BEQ.b	PSGPitch_ClampHigh_Loop6
	MULU.w	D3, D1
PSGPitch_ClampHigh_Loop6:
	ADD.w	D1, D4
	BRA.w	PSGPitch_WriteFrequency
PSGPitch_ClampHigh_Loop:
	SUBQ.b	#1, fmch_lfo_phase(A3)	
	MOVE.w	#0, D1	
	BRA.b	PSGPitch_ClampHigh	
PSGPitch_ClampHigh_Loop2:
	SUBQ.b	#2, fmch_lfo_phase(A3)
	SUBQ.b	#2, D0
	BRA.b	PSGChannel_NoteLoop
PSGPitch_ClampHigh_Loop3:
	MOVE.b	(A0,D0.w), D0
	BRA.b	PSGChannel_NoteLoop
PSGPitch_ClampHigh_Loop4:
	MOVE.b	(A0,D0.w), D1
	ADD.b	D1, fmch_lfo_depth(A3)
	MOVE.b	fmch_lfo_depth(A3), D3
	ADDQ.w	#1, D0
	BRA.b	PSGChannel_NoteLoop
PSGPitch_ClampHigh_Loop5:
	MOVE.b	#0, D0
	BRA.b	PSGChannel_NoteLoop
PSGPitch_WriteFrequency:
	MOVE.w	D4, D1
	BEQ.w	PSGPitch_WriteFrequency_Return
	LSR.w	#8, D1
	MOVE.b	#$A4, D0
	BSR.w	WriteYM2612Register
	MOVE.b	D4, D1
	MOVE.b	#SOUND_MENU_CURSOR, D0
	BSR.w	WriteYM2612Register
PSGPitch_WriteFrequency_Return:
	RTS

;==============================================================
; SOUND SCRIPT POINTER AND COMMAND DISPATCHER
; Rebuilds the script read pointer from the channel struct and
; dispatches script command bytes ($E0-$FF) via jump table.
;==============================================================

; LoadSoundScriptPointer
; Reconstructs A4 (script read pointer) from fmch_script_ptr_hi
; and fmch_script_ptr_lo stored in the channel struct, adding
; the base offset $00093C00.
; Inputs: A3 = channel struct
; Outputs: A4 = current script pointer
LoadSoundScriptPointer:
	MOVEA.l	#0, A4
	MOVEQ	#0, D5
	MOVE.w	#0, D0
	MOVE.w	D0, D1
	MOVE.b	fmch_script_ptr_hi(A3), D0
	MOVE.b	fmch_script_ptr_lo(A3), D1
	LSL.w	#8, D0
	ADD.w	D0, D1
	MOVEA.w	D1, A4
	ADDA.l	#$00093C00, A4
	RTS
	
; ProcessSoundScriptCommand
; Dispatches a sound script command byte to its handler.
; Subtracts $E0 from D5, uses result as PC-relative jump table
; index (4 bytes per entry). Reads next byte into D5 on return.
; Inputs: D5 = command byte (>= SOUND_SCRIPT_CMD_THRESHOLD=$E0)
; Outputs: D5 = next script byte after the command
ProcessSoundScriptCommand:
	SUBI.b	#$E0, D5
	ANDI.l	#$000000FF, D5
	LSL.w	#2, D5
	JSR	SoundScriptCommandJumpTable(PC,D5.w)
	MOVE.b	(A4)+, D5
	RTS
	
; SoundScriptCommandJumpTable
; 31 BRA.w entries (4 bytes each). Index = command - $E0.
; Commands $E0-$E3: NOP. $E4: set tempo. $E5: enable DAC.
; $E6: disable DAC. $E7: NOP. $E8: set echo flag. $E9: set arpegio.
; $EA: set volume (absolute). $EB/$EC/$ED: set volume (additive).
; $EE: jump to offset. $EF/$F0/$F1/$F2/$F3/$F4: loop/call/ret.
; $F5: set tempo flags. $F6: transpose. $F7: set pitch-slide mode.
; $F8: delta volume. $F9/$FA/$FB: pan left/right/center.
; See individual handlers below.
SoundScriptCommandJumpTable:
	BRA.w	SoundScript_NopCommand	
	BRA.w	SoundScript_NopCommand	
	BRA.w	SoundScript_NopCommand	
	BRA.w	SoundScript_NopCommand	
	BRA.w	SoundScript_NopCommand_Loop	
	BRA.w	SoundScript_NopCommand_Loop2
	BRA.w	SoundScript_NopCommand_Loop3
	BRA.w	SoundScript_NopCommand	
	BRA.w	SoundScript_NopCommand_Loop4
	BRA.w	SoundScript_NopCommand_Loop5
	BRA.w	SoundCmd_SetFrequency	
	BRA.w	SoundCmd_SetFrequency	
	BRA.w	SoundCmd_JumpToOffset_Loop
	BRA.w	SoundCmd_SetFrequency
	BRA.w	SoundScript_NopCommand	
	BRA.w	SoundCmd_SetFrequency_Loop
	BRA.w	LoadFM_AlgorithmData_Return_Loop	
	BRA.w	SoundScript_NopCommand	
	BRA.w	LoadFM_AlgorithmData_Return_Loop2
	BRA.w	LoadFM_AlgorithmData_Return_Loop3	
	BRA.w	LoadFM_AlgorithmData_Return_Loop4
	BRA.w	SoundScript_NopCommand	
	BRA.w	SoundCmd_JumpToOffset
	BRA.w	SoundCmd_JumpToOffset_Loop2
	BRA.w	SoundCmd_JumpToOffset_Loop3
	BRA.w	SoundCmd_JumpToOffset_Loop4
	BRA.w	SoundCmd_JumpToOffset_Loop5	
	BRA.w	SoundCmd_JumpToOffset_Loop6
	BRA.w	SoundCmd_JumpToOffset_Loop7
	BRA.w	SoundCmd_JumpToOffset_Loop8
	BRA.w	SoundCmd_JumpToOffset_Loop9
	BRA.w	SoundCmd_JumpToOffset_Loop10
SoundScript_NopCommand:
	RTS
	
SoundScript_NopCommand_Loop:
	MOVE.b	(A4)+, D0	
	ADD.b	D0, $00FFF402	
	MOVE.b	#1, $00FFF401	
	RTS
	
SoundScript_NopCommand_Loop2:
	BSET.b	#4, fmch_channel_id(A3)
	RTS
	
SoundScript_NopCommand_Loop3:
	BCLR.b	#4, fmch_channel_id(A3)
	MOVE.b	#$2B, D0
	MOVE.b	#0, D1
	BRA.w	WriteYM2612Register_Part1
SoundScript_NopCommand_Loop4:
	MOVE.b	(A4)+, D0
	BEQ.w	SoundScript_NopCommand_Loop6
	BSET.b	#6, fmch_flags(A3)
	BRA.w	SoundScript_NopCommand_Loop7
SoundScript_NopCommand_Loop6:
	BCLR.b	#6, fmch_flags(A3)
SoundScript_NopCommand_Loop7:
	RTS
	
SoundScript_NopCommand_Loop5:
	CLR.w	D0
	MOVE.b	(A4)+, D0
	BEQ.w	LoadDAC_SampleToZ80_Loop
	MOVE.b	D0, fmch_arp_phase(A3)
LoadDAC_SampleToZ80:
	LEA	LoadDAC_SampleToZ80_Data, A0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A6
	ADDQ.w	#4, D0
	MOVEA.l	(A0,D0.w), A5
	SUBA.l	A6, A5
	MOVE.w	A5, D6
	ASR.w	#4, D6
	MOVE.w	#$0100, Z80_bus_request
	LEA	$00A00200, A5
LoadDAC_SampleToZ80_Done:
	MOVE.b	(A6)+, (A5)+
	MOVE.b	(A6)+, (A5)+
	MOVE.b	(A6)+, (A5)+
	MOVE.b	(A6)+, (A5)+
	MOVE.b	(A6)+, (A5)+
	MOVE.b	(A6)+, (A5)+
	MOVE.b	(A6)+, (A5)+
	MOVE.b	(A6)+, (A5)+
	MOVE.b	(A6)+, (A5)+
	MOVE.b	(A6)+, (A5)+
	MOVE.b	(A6)+, (A5)+
	MOVE.b	(A6)+, (A5)+
	MOVE.b	(A6)+, (A5)+
	MOVE.b	(A6)+, (A5)+
	MOVE.b	(A6)+, (A5)+
	MOVE.b	(A6)+, (A5)+
	DBF	D6, LoadDAC_SampleToZ80_Done
	MOVE.w	#0, Z80_bus_request
	MOVE.b	fmch_pan_stereo(A3), D1
	MOVE.b	#$B4, D0
	BSR.w	WriteYM2612Register
LoadDAC_SampleToZ80_Loop:
	RTS
	
SoundCmd_SetFrequency:
	MOVE.b	(A4)+, D5
	ANDI.w	#$00FF, D5
	BTST.b	#1, fmch_tempo_flags(A3)
	BEQ.w	SoundCmd_SetFrequency_Loop2
	LSL.w	#1, D5
SoundCmd_SetFrequency_Loop2:
	MOVE.w	D5, fmch_note_duration(A3)
	MOVE.w	D5, fmch_tick_ctr(A3)
	MOVE.l	A4, D5
	SUBI.l	#$00093C00, D5
	MOVE.b	D5, fmch_script_ptr_lo(A3)
	LSR.w	#8, D5
	MOVE.b	D5, fmch_script_ptr_hi(A3)
	MOVE.l	(A7)+, D0
	MOVE.l	(A7)+, D0
	MOVE.l	(A7)+, D0
	RTS
	
SoundCmd_SetFrequency_Loop:
	MOVE.b	(A4)+, D0
	MOVE.b	D0, fmch_arpeggio_idx(A3)
	BTST.b	#7, fmch_channel_id(A3)
	BNE.w	LoadFM_AlgorithmData_Return
	BTST.b	#4, fmch_channel_id(A3)
	BNE.w	LoadFM_AlgorithmData_Return
	ANDI.w	#$00FF, D0
	LEA	FM_FrequencyTable, A0
	BSR.w	GetSoundDataPointer
	BRA.w	LoadFM_AlgorithmData
LoadFM_AlgorithmData_Return:
	RTS
	
LoadFM_AlgorithmData_Return_Loop:
	MOVE.b	(A4)+, D3	
	MOVE.b	D3, fmch_volume(A3)	
	BRA.w	UpdateFM_TotalLevelRegisters	
LoadFM_AlgorithmData_Return_Loop2:
	MOVEQ	#0, D0
	MOVE.b	D0, fmch_flags(A3)
	BTST.b	#4, fmch_channel_id(A3)
	BNE.w	LoadFM_AlgorithmData_Return_Loop5
	BTST.b	#7, fmch_channel_id(A3)
	BEQ.w	LoadFM_AlgorithmData_Return_Loop6
	BSR.w	UpdateYM2612Channel
	BRA.w	LoadFM_AlgorithmData_Return_Loop7
LoadFM_AlgorithmData_Return_Loop6:
	BSR.w	WriteFMChannelRegisters
	BSET.b	#1, fmch_flags(A3)
LoadFM_AlgorithmData_Return_Loop7:
	TST.b	$00FFF421
	BEQ.b	LoadFM_AlgorithmData_Return_Loop8
	BSR.w	InitSoundChannel_FM
LoadFM_AlgorithmData_Return_Loop8:
	MOVE.l	(A7)+, D0
	RTS
	
LoadFM_AlgorithmData_Return_Loop5:
	BSET.b	#1, fmch_flags(A3)
	TST.b	$00FFF421
	BEQ.b	LoadFM_AlgorithmData_Return_Loop9
	BSR.w	InitSoundChannel_FM
LoadFM_AlgorithmData_Return_Loop9:
	MOVE.w	#$0100, Z80_bus_request
	MOVE.b	#0, $00A01FFF
	MOVE.w	#0, Z80_bus_request
	CLR.w	D0
	MOVE.w	D0, D1
	MOVE.b	#$2B, D0
	MOVE.b	#0, D1
	BSR.w	WriteYM2612Register_Part1
	MOVEA.l	A3, A1
	MOVEA.l	#$00FFF520, A3
	BCLR.b	#2, $0(A3)
	MOVE.b	$13(A3), D0
	ANDI.w	#$00FF, D0
	BEQ.w	LoadFM_AlgorithmData_Return_Loop10
	BSR.w	LoadDAC_SampleToZ80
LoadFM_AlgorithmData_Return_Loop10:
	MOVEA.l	A1, A3
	MOVE.l	(A7)+, D0
	MOVE.l	(A7)+, D0
	RTS
	
LoadFM_AlgorithmData_Return_Loop3:
	MOVE.b	(A4)+, D0	
	ANDI.b	#$E0, D0	
	MOVE.b	D0, PSG_port	
	RTS
	
LoadFM_AlgorithmData_Return_Loop4:
	MOVE.b	(A4)+, fmch_vibrato_idx(A3)
	RTS
	
SoundCmd_JumpToOffset:
	MOVEQ	#0, D1
	MOVE.b	(A4)+, D0
	ANDI.w	#$00FF, D0
	LSL.w	#8, D0
	MOVE.b	(A4), D1
	ADD.w	D0, D1
	ADDI.l	#$00093C00, D1
	MOVEA.l	D1, A4
	RTS
	
SoundCmd_JumpToOffset_Loop2:
	MOVEQ	#0, D0
	MOVE.w	D0, D1
	MOVE.b	(A4)+, D0
	MOVE.b	(A4)+, D1
	TST.b	$22(A3,D0.w)
	BNE.w	SoundCmd_JumpToOffset_Loop11
	MOVE.b	D1, $22(A3,D0.w)
SoundCmd_JumpToOffset_Loop11:
	SUBQ.b	#1, $22(A3,D0.w)
	BNE.b	SoundCmd_JumpToOffset
	MOVE.b	(A4)+, D0
	MOVE.b	(A4)+, D0
	RTS
	
SoundCmd_JumpToOffset_Loop3:
	MOVE.b	fmch_call_sp(A3), D0
	ANDI.l	#$000000FF, D0
	SUBQ.b	#4, D0
	MOVE.l	A4, (A3,D0.w)
	MOVE.b	D0, fmch_call_sp(A3)
	BRA.b	SoundCmd_JumpToOffset
SoundCmd_JumpToOffset_Loop4:
	MOVEQ	#0, D0
	MOVE.b	fmch_call_sp(A3), D0
	MOVEA.l	(A3,D0.w), A4
	ADDA.l	#2, A4
	ADDQ.b	#4, D0
	MOVE.b	D0, fmch_call_sp(A3)
	RTS
	
SoundCmd_JumpToOffset_Loop5:
	MOVE.b	(A4)+, fmch_tempo_flags(A3)	
	RTS
	
SoundCmd_JumpToOffset_Loop6:
	MOVE.b	(A4)+, D0
	ADD.b	D0, fmch_transpose(A3)
	RTS
	
SoundCmd_JumpToOffset_Loop7:
	TST.b	(A4)+
	BEQ.b	SoundCmd_JumpToOffset_Loop12
	BSET.b	#5, fmch_flags(A3)
	RTS
	
SoundCmd_JumpToOffset_Loop12:
	BCLR.b	#5, fmch_flags(A3)
	RTS
	
SoundCmd_JumpToOffset_Loop:
	MOVE.b	(A4)+, D3
	ADD.b	D3, fmch_volume(A3)
	MOVE.b	fmch_volume(A3), D3
	BRA.w	UpdateFM_TotalLevelRegisters
SoundCmd_JumpToOffset_Loop8:
	MOVE.b	#$C0, D1
	MOVE.b	D1, fmch_pan_stereo(A3)
	MOVE.b	#$B4, D0
	BRA.w	WriteYM2612Register
SoundCmd_JumpToOffset_Loop9:
	MOVE.b	#$40, D1
	MOVE.b	D1, fmch_pan_stereo(A3)
	MOVE.b	#$B4, D0
	BRA.w	WriteYM2612Register
SoundCmd_JumpToOffset_Loop10:
	MOVE.b	#$80, D1
	MOVE.b	D1, fmch_pan_stereo(A3)
	MOVE.b	#$B4, D0
	BRA.w	WriteYM2612Register
; SetPSGNoteFrequency
; Looks up a 16-bit PSG frequency word from SetPSGNoteFrequency_Loop2_Data
; for the note index in D5 (after subtracting $80 and applying
; transpose) and stores it in fmch_note_freq.
; D5 = $80 alone is a rest: sets bit 1 of fmch_flags.
; Inputs: D5 = note byte (bit 7 set = PSG note), A3 = channel struct
SetPSGNoteFrequency:
	SUBI.b	#$80, D5
	BNE.w	SetPSGNoteFrequency_Loop
	BSET.b	#1, fmch_flags(A3)
	BRA.w	SetPSGNoteFrequency_Loop2
SetPSGNoteFrequency_Loop:
	ADD.b	fmch_transpose(A3), D5
SetPSGNoteFrequency_Loop2:
	ANDI.w	#$007F, D5
	LEA	SetPSGNoteFrequency_Loop2_Data, A0
	LSL.w	#1, D5
	MOVE.w	(A0,D5.w), fmch_note_freq(A3)
	RTS
	
;==============================================================
; SOUND COMMAND QUEUE, TEMPO, AND FADE-OUT
; Handles top-level commands from the game (play/stop music),
; per-frame tempo countdown, and global fade-out processing.
;==============================================================

; ProcessSound_CommandQueue
; Reads the pending sound command byte from $FFF404.
; Routes to music start, SFX start, or stop handlers based on
; the command value range. Clears the queue byte when done.
ProcessSound_CommandQueue:
	CLR.w	D0
	BTST.b	#7, $00FFF404
	BEQ.w	SoundInit_StopAndConfigure
	MOVE.b	$00FFF404, D0
	CMPI.b	#$9D, D0
	BCS.w	SoundCommand_JumpTable_Loop
	CMPI.b	#$A0, D0
	BCS.w	SoundInit_StopAndConfigure
	CMPI.b	#$C2, D0
	BCS.w	SoundCommand_JumpTable_Loop2
	CMPI.b	#$DF, D0
	BCS.w	SoundInit_StopAndConfigure
	CMPI.b	#$E3, D0
	BCS.b	ProcessSound_CommandQueue_Loop
	BRA.w	SoundInit_StopAndConfigure	
ProcessSound_CommandQueue_Loop:
	SUBI.b	#$E0, D0
	ANDI.l	#$000000FF, D0
	LSL.w	#2, D0
	JSR	SoundCommand_JumpTable(PC,D0.w)
	BRA.w	SoundInit_Done
SoundCommand_JumpTable:
	BRA.w	SoundObjTick_Return_Loop
	dc.b	$60, $00, $01, $3C 
SoundCommand_JumpTable_Loop2:
	MOVE.w	D0, -(A7)
	MOVE.w	(A7)+, D0
	SUBI.b	#$A0, D0
	LEA	SoundCommand_JumpTable_Loop2_Data, A0
	BSR.w	GetSoundDataPointer
	CLR.w	D0
	BTST.b	#4, $2(A0)
	BNE.w	SoundCommand_JumpTable_Loop3
	MOVE.w	#0, D5
	MOVE.b	(A0)+, D5
	SUBQ.b	#1, D5
SoundCommand_JumpTable_Loop2_Done:
	CLR.w	D0
	MOVE.b	$1(A0), D0
	SUBQ.b	#2, D0
	LSL.b	#2, D0
	LEA	SoundCommand_JumpTable_Loop2_Done_Data, A1
	MOVEA.l	(A1,D0.w), A2
	BSET.b	#2, $0(A2)
	ADDA.l	#$00000150, A2
	MOVEA.l	A2, A1
	MOVEQ	#0, D0
	MOVEQ	#$0000000B, D6
SoundCommand_JumpTable_Loop2_Done2:
	MOVE.l	D0, (A1)+
	DBF	D6, SoundCommand_JumpTable_Loop2_Done2
	MOVEA.l	A0, A3
	MOVEA.l	A2, A1
	MOVE.w	#8, D6
SoundCommand_JumpTable_Loop2_Done3:
	MOVE.b	(A0)+, (A1)+
	DBF	D6, SoundCommand_JumpTable_Loop2_Done3
	MOVE.b	#$C0, $21(A2)
	MOVE.w	#1, $A(A2)
	ADDA.w	#$0030, A2
	DBF	D5, SoundCommand_JumpTable_Loop2_Done
	BRA.w	SoundInit_Done
SoundCommand_JumpTable_Loop3:
	LEA	$00FFF520, A2
	BSET.b	#2, $0(A2)
	MOVE.b	(A0)+, D0
	LEA	$00FFF670, A1
	MOVE.w	#8, D6
SoundCommand_JumpTable_Loop3_Done:
	MOVE.b	(A0)+, (A1)+
	DBF	D6, SoundCommand_JumpTable_Loop3_Done
	LEA	$00FFF670, A1
	MOVE.b	#$C0, $21(A1)
	MOVE.w	#1, $A(A1)
	MOVE.b	#$C0, $21(A1)
	BRA.w	SoundInit_Done
SoundCommand_JumpTable_Loop2_Done_Data:
	dc.l	$00FFF490
	dc.l	$00FFF4C0	
	dc.l	$00FFF4C0
	dc.l	$00FFF4F0
	dc.l	$00FFF520	
	dc.l	$00FFF550	
	dc.l	$00FFF580	
	dc.l	$00FFF5B0	
SoundCommand_JumpTable_Loop:
	SUBI.b	#$81, D0
	BCS.w	SoundInit_Done
	MOVE.l	D0, -(A7)
	BSR.w	StopAllActiveSounds
	MOVE.l	(A7)+, D0
	LEA	SoundCommand_JumpTable_Loop_Data, A0
	MOVE.b	(A0,D0.w), $00FFF402
	MOVE.b	(A0,D0.w), $00FFF401
	LEA	SoundCommand_JumpTable_Loop_Data2, A0
	BSR.w	GetSoundDataPointer
	MOVEQ	#0, D5
	MOVE.b	(A0)+, D5
	SUBQ.b	#1, D5
	LEA	$00FFF430, A2
SoundCommand_JumpTable_Loop_Done:
	MOVEA.l	A2, A1
	MOVE.w	#8, D6
SoundCommand_JumpTable_Loop_Done2:
	MOVE.b	(A0)+, (A1)+
	DBF	D6, SoundCommand_JumpTable_Loop_Done2
	MOVE.b	#$C0, $21(A2)
	MOVE.b	#$30, $9(A2)
	MOVE.w	#1, $A(A2)
	ADDA.l	#$00000030, A2
	DBF	D5, SoundCommand_JumpTable_Loop_Done
	BRA.w	SoundInit_Done
SoundInit_StopAndConfigure:
	BSR.w	StopAllActiveSounds
SoundInit_Done:
	MOVE.b	#$80, $00FFF404
	RTS
	
; GetSoundDataPointer
; Looks up a 16-bit relative offset from table at A0 indexed by
; D0, adds base $00093C00, and returns the pointer in A0.
; Inputs: A0 = base table, D0 = index
; Outputs: A0 = resolved pointer
GetSoundDataPointer:
	LSL.w	#1, D0
	MOVEA.w	(A0,D0.w), A0
	ADDA.l	#$00093C00, A0
	RTS
	
; StopAllActiveSounds
; Disables DAC, silences all FM channels (key-off all ops),
; zeros sound RAM $FFF400-$FFF59B, and mutes all PSG channels.
StopAllActiveSounds:
	MOVE.b	#$2B, D0
	MOVE.b	#0, D1
	BSR.w	WriteYM2612Register_Part1
	MOVE.l	A3, -(A7)
	BSR.w	InitFM_ChannelsToSilence
	MOVEA.l	(A7)+, A3
	LEA	$00FFF400, A6
	MOVE.w	#$009B, D6
StopAllActiveSounds_Done:
	MOVE.l	#0, (A6)+
	DBF	D6, StopAllActiveSounds_Done
	BSR.w	MutePSG_AllChannels
	RTS
	
; ProcessSound_TempoCounter
; Decrements the tempo tick counter ($FFF401). When it reaches
; zero, reloads from $FFF402 and increments tick_ctr on all 9
; active bank-1 channels to advance them one script step.
ProcessSound_TempoCounter:
	LEA	$00FFF402, A0
	LEA	$00FFF401, A1
	TST.b	(A0)
	BEQ.b	SoundObjTick_Return
	SUBQ.b	#1, (A1)
	BNE.w	SoundObjTick_Return
	MOVE.b	(A0), (A1)
	LEA	$00FFF430, A0
	MOVE.w	#8, D6
ProcessSound_TempoCounter_Done:
	ADDQ.w	#1, $A(A0)
	ADDA.l	#$30, A0
	DBF	D6, ProcessSound_TempoCounter_Done
SoundObjTick_Return:
	RTS
	
SoundObjTick_Return_Loop:
	MOVE.b	#$3F, $00FFF41C
	MOVE.b	#2, $00FFF41D
	MOVE.b	#0, $00FFF520
	RTS
	
; ProcessSound_FadeOut
; Drives the global fade-out effect. Each tick it decrements
; the fade speed counter ($FFF41D); when expired, increments
; volume attenuation on all FM channels by 1 step. When fully
; faded ($FFF41C reaches 0), calls StopAllActiveSounds.
ProcessSound_FadeOut:
	MOVEQ	#0, D0
	MOVE.b	$00FFF41C, D0
	BEQ.b	ProcessSound_FadeOut_Loop
	MOVE.b	$00FFF41D, D0
	BEQ.b	ProcessSound_FadeOut_Loop2
	SUBQ.b	#1, $00FFF41D
	RTS
	
ProcessSound_FadeOut_Loop2:
	SUBQ.b	#1, $00FFF41C
	BEQ.w	StopAllActiveSounds
	MOVE.b	#2, $00FFF41D
	LEA	$00FFF430, A3
	MOVE.w	#8, D6
ProcessSound_FadeOut_Loop2_Done:
	ADDQ.b	#1, fmch_volume(A3)
	MOVE.b	fmch_volume(A3), D3
	BSR.w	UpdateFM_TotalLevelRegisters
	ADDA.w	#$0030, A3
	DBF	D6, ProcessSound_FadeOut_Loop2_Done
ProcessSound_FadeOut_Loop:
	RTS
	
; InitSoundChannel_FM
; Re-initialises a bank-2 FM channel using the instrument data
; pointed to by A0. Temporarily sets A3 to the bank-1 mirror
; struct, loads FM algorithm data, then restores A3.
; Inputs: A3 = bank-2 channel struct, A0 = instrument data ptr
InitSoundChannel_FM:
	MOVEA.l	A3, A6
	SUBA.l	#$00000150, A3
	BTST.b	#4, $2(A0)
	BNE.w	InitSoundChannel_FM_Loop
	BCLR.b	#2, fmch_flags(A3)
	MOVE.b	fmch_arpeggio_idx(A3), D0
	ANDI.w	#$00FF, D0
	LEA	FM_FrequencyTable, A0
	BSR.w	GetSoundDataPointer
	BSR.w	LoadFM_AlgorithmData
InitSoundChannel_FM_Loop:
	MOVEA.l	A6, A3
	RTS
	
; ---------------------------------------------------------------------------
; InitSoundChannel_FM_DeadCode — DEAD CODE: orphaned FM key-off loop
;
; DEAD CODE: No call sites exist.  Would write $80 to FM register D0 with
; $0F in D1, looping 4 times while incrementing D0 by 4 each iteration —
; effectively keying off 4 FM operators.  Likely an early FM-off helper that
; was superseded by InitFM_ChannelsToSilence / WriteYM2612Register.
; Cannot be removed without breaking bit-perfect output.
; ---------------------------------------------------------------------------
InitSoundChannel_FM_DeadCode:
	MOVE.b	#$80, D0
	MOVE.b	#$0F, D1
	MOVE.w	#$0003, D7
WriteYM2612_RegisterLoop:
	BSR.w	WriteYM2612Register
	ADDQ.w	#4, D0
	DBF	D7, WriteYM2612_RegisterLoop
	RTS
; InitFM_ChannelsToSilence
; Keys off all 7 FM channels, then writes a full set of
; register values to silence all 6 YM2612 FM channels using
; the data table at InitFM_ChannelsToSilence_RegData.
InitFM_ChannelsToSilence:
	MOVEQ	#6, D6
	MOVE.b	#$28, D0
	MOVE.b	#0, D1
InitFM_ChannelsToSilence_Done:
	BSR.w	WriteYM2612Register
	ADDQ.b	#1, D1
	DBF	D6, InitFM_ChannelsToSilence_Done
	LEA	$00FFF430, A3
	MOVE.w	#5, D7
InitFM_ChannelsToSilence_ChannelLoop:
	LEA	InitFM_ChannelsToSilence_RegData, A0
	BSR.w	WriteFM_ChannelRegisters
	ADDA.w	#$0030, A3
	DBF	D7, InitFM_ChannelsToSilence_ChannelLoop
	RTS
	
InitFM_ChannelsToSilence_RegData:
	dc.b	$F8, $3F, $3F, $3F, $3F, $00, $00, $00, $00, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $FF, $FF, $FF, $FF, $00 
; MutePSG_AllChannels
; Sets maximum attenuation ($F) on all 4 PSG channels by
; writing the latch+attenuation bytes to the PSG data port.
MutePSG_AllChannels:
	MOVE.b	#$9F, PSG_port
	MOVE.b	#$BF, PSG_port
	MOVE.b	#$DF, PSG_port
	MOVE.b	#$FF, PSG_port
	MOVE.b	#SOUND_LEVEL_UP, PSG_port
	RTS
	
; LoadFM_AlgorithmData
; Copies 5 bytes of instrument/algorithm data from (A0) into
; the channel struct at fmch_op_algo..fmch_op4_tl (offsets
; $1C-$20), then falls through to WriteFM_ChannelRegisters.
; Inputs: A0 = instrument data, A3 = channel struct
LoadFM_AlgorithmData:
	MOVE.w	#4, D6
	CLR.w	D0
LoadFM_AlgorithmData_Done:
	MOVE.b	(A0)+, $1C(A3,D0.w)
	ADDQ.b	#1, D0
	DBF	D6, LoadFM_AlgorithmData_Done
	SUBQ.w	#5, A0
; WriteFM_ChannelRegisters
; Writes all 25 YM2612 operator/channel registers for one FM
; channel using the register address table WriteFM_ChannelRegisters_Data,
; then writes the stereo pan register ($B4) and calls
; UpdateFM_TotalLevelRegisters for operator volume.
; Inputs: A0 = register data, A3 = channel struct
WriteFM_ChannelRegisters:
	MOVEA.l	#WriteFM_ChannelRegisters_Data, A2
	MOVE.w	#$0018, D6
WriteFM_ChannelRegisters_Done:
	MOVE.b	(A2)+, D0
	MOVE.b	(A0)+, D1
	BSR.w	WriteYM2612Register
	DBF	D6, WriteFM_ChannelRegisters_Done
	MOVE.b	#$B4, D0
	MOVE.b	fmch_pan_stereo(A3), D1
	BSR.w	WriteYM2612Register
	MOVE.b	fmch_volume(A3), D3
	BEQ.w	WriteFM_ChannelRegisters_Loop
	BRA.b	UpdateFM_TotalLevelRegisters
WriteFM_ChannelRegisters_Loop:
	RTS
	
WriteFM_ChannelRegisters_Data:
	dc.b	$B0, $40, $48, $44, $4C, $30, $38, $34, $3C, $50, $58, $54, $5C, $60, $68, $64, $6C, $70, $78, $74, $7C, $80, $88, $84, $8C, $00 
; UpdateFM_TotalLevelRegisters
; Writes the Total Level (TL) registers for the operators that
; produce output according to the FM algorithm. Which operators
; carry output varies by algorithm (0-7); the jump table at
; UpdateFM_OperatorRegisters dispatches accordingly.
; Inputs: D3 = global volume offset, A3 = channel struct
UpdateFM_TotalLevelRegisters:
	BTST.b	#7, fmch_channel_id(A3)
	BNE.w	UpdateFM_WriteOperator4_Loop
	MOVE.b	fmch_op_algo(A3), D5
	ANDI.w	#7, D5
	LSL.w	#2, D5
	JSR	UpdateFM_OperatorRegisters(PC,D5.w)
UpdateFM_OperatorRegisters:
	BRA.w	UpdateFM_WriteOperator4
	BRA.w	UpdateFM_WriteOperator4
	BRA.w	UpdateFM_WriteOperator4
	BRA.w	UpdateFM_WriteOperator4
	BRA.w	UpdateFMLevel_Operator4_Loop
	BRA.w	UpdateFMLevel_Operator4
	BRA.w	UpdateFMLevel_Operator4
	BRA.w	UpdateFM_OperatorRegisters_Loop
UpdateFM_OperatorRegisters_Loop:
	MOVE.b	#$40, D0
	MOVE.b	D3, D1
	ADD.b	fmch_op1_tl(A3), D1
	BSR.w	WriteYM2612Register
UpdateFMLevel_Operator4:
	MOVE.b	#$44, D0
	MOVE.b	D3, D1
	ADD.b	fmch_op2_tl(A3), D1
	BSR.w	WriteYM2612Register
UpdateFMLevel_Operator4_Loop:
	MOVE.b	#$48, D0
	MOVE.b	D3, D1
	ADD.b	fmch_op3_tl(A3), D1
	BSR.w	WriteYM2612Register
UpdateFM_WriteOperator4:
	MOVE.b	#$4C, D0
	MOVE.b	D3, D1
	ADD.b	fmch_op4_tl(A3), D1
	BSR.w	WriteYM2612Register
UpdateFM_WriteOperator4_Loop:
	RTS
	
; UpdateYM2612KeyOff
; Sends a key-off command (reg $28) for this channel unless
; bits 1 or 2 of fmch_flags are set (muted/suppressed).
; Inputs: A3 = channel struct
UpdateYM2612KeyOff:
	MOVE.b	fmch_flags(A3), D2
	ANDI.b	#6, D2
	BNE.w	UpdateYM2612KeyOff_Loop
	MOVE.b	#$28, D0
	MOVE.b	fmch_channel_id(A3), D1
	ORI.b	#$F0, D1
	BSR.w	WriteYM2612Register_Part1
UpdateYM2612KeyOff_Loop:
	RTS
	
; WriteFMChannelRegisters
; Sends a key-on command (reg $28) for this channel unless
; bits 1 or 2 of fmch_flags are set (muted/suppressed).
; Inputs: A3 = channel struct
WriteFMChannelRegisters:
	MOVE.b	fmch_flags(A3), D2
	ANDI.b	#6, D2
	BNE.w	WriteFMChannelRegisters_Loop
	MOVE.b	#$28, D0
	MOVE.b	fmch_channel_id(A3), D1
	BSR.w	WriteYM2612Register_Part1
WriteFMChannelRegisters_Loop:
	RTS
	
;==============================================================
; YM2612 / FM HARDWARE ACCESS
; Low-level register writes with Z80 bus arbitration and busy
; polling. Also handles PSG note frequency table writes.
;==============================================================

; WriteYM2612Register
; Writes one YM2612 register. Selects port A ($A04000/$A04001)
; or port B ($A04002/$A04003) based on channel_id bit 2.
; Adds channel index (bits 0-1 of channel_id) to register addr.
; Inputs: D0 = register address, D1 = value, A3 = channel struct
WriteYM2612Register:
	BTST.b	#2, fmch_flags(A3)
	BNE.w	WriteYM2612Register_Part1_Loop
	MOVE.b	fmch_channel_id(A3), D2
	BTST.l	#2, D2
	BNE.b	WriteYM2612Register_Part1_Loop2
	ANDI.b	#3, D2
	ADD.b	D2, D0
WriteYM2612Register_Part1:
	BSR.w	WaitYM2612Ready
	MOVE.b	D0, $00A04000
	NOP
	NOP
	NOP
	MOVE.b	D1, $00A04001
	MOVE.w	#0, Z80_bus_request
	RTS
	
WriteYM2612Register_Part1_Loop2:
	ANDI.b	#3, D2
	ADD.b	D2, D0
	BSR.b	WaitYM2612Ready
	MOVE.b	D0, $00A04002
	NOP
	NOP
	NOP
	MOVE.b	D1, $00A04003
	MOVE.w	#0, Z80_bus_request
WriteYM2612Register_Part1_Loop:
	RTS
	
; WaitYM2612Ready
; Acquires the Z80 bus (writes $0100 to Z80_bus_request) then
; polls until the bus grant bit clears. Also polls the YM2612
; busy flag (bit 7 of $A01FFD); if busy, releases bus, waits,
; and retries. Returns with Z80 bus still held.
WaitYM2612Ready:
	MOVE.w	#$0100, Z80_bus_request
WaitYM2612Ready_Done:
	BTST.b	#0, Z80_bus_request
	BNE.b	WaitYM2612Ready_Done
	BTST.b	#7, $00A01FFD
	BEQ.b	WaitYM2612Ready_Loop
	MOVE.w	#0, Z80_bus_request
	NOP
	NOP
	NOP
	NOP
	NOP
	BRA.b	WaitYM2612Ready
WaitYM2612Ready_Loop:
	RTS
	
SetPSGNoteFrequency_Loop2_Data:
	dc.b	$00, $00, $0A, $83, $0A, $AA, $0A, $D3, $0A, $FF, $0B, $2D, $0B, $5E, $0B, $92, $0B, $C9, $0C, $03, $0C, $41, $0C, $82, $12, $5F, $12, $85, $12, $AA, $12, $D3 
	dc.b	$12, $FF, $13, $2D, $13, $5C, $13, $8F, $13, $C7, $13, $FD, $14, $3B, $14, $7C, $1A, $60, $1A, $84, $1A, $AB, $1A, $D2, $1A, $FF, $1B, $2C, $1B, $5C, $1B, $8F 
	dc.b	$1B, $C6, $1B, $FF, $1C, $3C, $1C, $7D, $22, $61, $22, $85, $22, $AB, $22, $D2, $22, $FF, $23, $2C, $23, $5C, $23, $8F, $23, $C6, $23, $FF, $24, $3C, $24, $7C 
	dc.b	$2A, $61, $2A, $83, $2A, $A9, $2A, $D5, $2A, $FD, $2B, $2A, $2B, $5C, $2B, $90, $2B, $C6, $2B, $FB, $2C, $3C, $2C, $7B, $32, $61, $32, $83, $32, $A9, $32, $D4 
	dc.b	$32, $FC, $33, $2A, $33, $5C, $33, $90, $33, $C9, $34, $03, $34, $33, $34, $7B, $3A, $5D, $3A, $83, $3A, $AA, $3A, $D3, $3A, $FD, $3B, $2A, $3B, $5C, $3B, $8E 
	dc.b	$3B, $C5, $3C, $01, $3C, $3B, $3C, $7C 

;==============================================================
; FM CHANNEL DATA SEQUENCER
; Secondary channel processing path for FM channels with the
; data-sequencer flag set (bit 7 of channel_id). Handles
; FM pitch-bend, LFO vibrato, arpeggio, and key-on/off.
;==============================================================

; ProcessSoundChannel_FM_Data
; Entry for FM channels using the data sequencer (bit 7 of
; channel_id is set). Counts down tick_ctr; when expired,
; loads and processes the next script note. Otherwise applies
; pitch-bend and PSG/FM note output each frame.
; Inputs: A3 = channel struct
ProcessSoundChannel_FM_Data:
	BTST.b	#5, fmch_flags(A3)
	BNE.w	WaitYM2612Ready_Loop2
	SUBQ.w	#1, fmch_tick_ctr(A3)
	BNE.w	WaitYM2612Ready_Loop3
	BSR.w	ProcessSoundScriptNote
	BSR.w	ProcessFMChannelNoteSequence
	BSR.w	ProcessSoundChannelSequencer
	RTS
	
WaitYM2612Ready_Loop3:
	BSR.w	ProcessFMChannelPitchBend
	BSR.w	ProcessSoundCommand
	RTS
	
WaitYM2612Ready_Loop2:
	SUBQ.w	#1, fmch_tick_ctr(A3)	
	dc.w	$6600
	dc.b	$00, $10 
	dc.w	$6100
	dc.w	$0052
	BSR.w	ProcessFMChannelNoteSequence	
	BSR.w	ProcessSoundChannelSequencer	
	RTS
	
SoundChannel_PitchSlideEntry:
	BSR.w	ApplyChannelPitchSlide	
	BSR.w	ProcessFMChannelNoteSequence	
	BSR.w	ProcessSoundCommand	
	dc.w	$4E75
; ProcessSoundScriptNote
; Loads the current script pointer, reads next byte, dispatches
; command bytes. For note bytes: if negative sets frequency
; override, if positive calls SetSoundNoteDuration.
; Inputs: A3 = channel struct
ProcessSoundScriptNote:
	BSR.w	LoadSoundScriptPointer
	MOVE.b	(A4)+, D5
ProcessSoundScriptNote_Done:
	CMPI.b	#SOUND_SCRIPT_CMD_THRESHOLD, D5
	BCS.w	ProcessSoundScriptNote_Loop
	BSR.w	ProcessSoundScriptCommand
	BRA.b	ProcessSoundScriptNote_Done
ProcessSoundScriptNote_Loop:
	TST.b	D5
	BPL.w	SoundChannel_NoteLoop3
	BSR.w	SetSoundNoteFrequency
	MOVE.b	(A4)+, D5
	TST.b	D5
	BPL.w	SoundChannel_NoteLoop3
	MOVE.b	-(A4), D5
	BSR.w	UpdateSoundChannelPitch
	RTS
SoundChannel_NoteLoop3:
	BSR.w	SetSoundNoteDuration
	BSR.w	UpdateSoundChannelPitch
	RTS
	
SoundChannel_ScriptLoadEntry:
	BSR.w	LoadSoundScriptPointer	
	MOVE.b	(A4)+, D5	
SoundChannel_NoteLoop3_Done:
	CMPI.b	#SOUND_SCRIPT_CMD_THRESHOLD, D5	
	BCS.w	SoundChannel_NoteLoop3_Loop	
	BSR.w	ProcessSoundScriptCommand	
	BRA.b	SoundChannel_NoteLoop3_Done	
SoundChannel_NoteLoop3_Loop:
	BSR.w	SetSoundNoteFrequency	
	MOVE.b	(A4)+, fmch_pitch_slide(A3)	
	MOVE.b	(A4)+, D0	
	MOVE.b	(A4)+, D5	
	BSR.w	SetSoundNoteDuration	
	BSR.w	UpdateSoundChannelPitch	
	RTS
	
; SetSoundNoteFrequency
; Sets the FM channel frequency from the note index in D5.
; D5 = $80 is a rest (sets pitch_bend=$1F, bit 1 of flags).
; Otherwise applies transpose, looks up fmch_note_freq from
; SetSoundNoteFrequency_Loop2_Data (FM frequency table).
; Inputs: D5 = note byte, A3 = channel struct
SetSoundNoteFrequency:
	SUBI.b	#$80, D5
	BNE.w	SetSoundNoteFrequency_Loop
	MOVE.b	#$1F, fmch_pitch_bend(A3)
	BSET.b	#1, fmch_flags(A3)
	BRA.w	SetSoundNoteFrequency_Loop2
SetSoundNoteFrequency_Loop:
	MOVE.b	#0, fmch_pitch_bend(A3)
	BCLR.b	#1, fmch_flags(A3)
	ADD.b	fmch_transpose(A3), D5
SetSoundNoteFrequency_Loop2:
	ANDI.w	#$00FF, D5
	LEA	SetSoundNoteFrequency_Loop2_Data, A0
	LSL.w	#1, D5
	MOVE.w	(A0,D5.w), fmch_note_freq(A3)
	RTS
	
; ProcessFMChannelPitchBend
; Entry point for per-frame pitch bend. Skips if pitch_bend is
; $1F (rest) or $FF (no bend), or if vibrato_idx is 0.
; Falls through to ProcessFMChannelNoteSequence.
; Inputs: A3 = channel struct
ProcessFMChannelPitchBend:
	CMPI.b	#$1F, fmch_pitch_bend(A3)
	BEQ.w	FMPitchBend_Return
	CMPI.b	#$FF, fmch_pitch_bend(A3)
	BEQ.w	FMPitchBend_Return
	MOVE.b	fmch_vibrato_idx(A3), D7
	BEQ.w	FMPitchBend_Return
; ProcessFMChannelNoteSequence
; Applies LFO vibrato to the FM channel's note frequency and
; writes the result to PSG output ($C00011).
; Reads LFO waveform from the table pointed to by vibrato_idx.
; Writes high nibble and low nibble to PSG frequency registers.
; Inputs: A3 = channel struct
ProcessFMChannelNoteSequence:
	MOVE.w	fmch_note_freq(A3), D4
	CLR.w	D0
	MOVE.b	fmch_vibrato_idx(A3), D0
	BEQ.w	FMPitch_WriteFrequency
	SUBQ.w	#1, D0
	MOVEQ	#0, D3
	MOVE.b	fmch_lfo_depth(A3), D3
	LEA	SoundLFO_PointerTable, A0
	LSL.w	#2, D0
	MOVEA.l	(A0,D0.w), A0
	CLR.w	D0
	MOVE.b	fmch_lfo_phase(A3), D0
FMChannel_NoteLoop:
	CLR.w	D1
	MOVE.b	(A0,D0.w), D1
	ADDQ.w	#1, D0
	MOVE.b	D0, fmch_lfo_phase(A3)
	CMPI.b	#NOTESCR_REST, D1
	BEQ.w	FMPitch_ClampHigh_Loop
	CMPI.b	#NOTESCR_LOOP, D1
	BEQ.w	FMPitch_ClampHigh_Loop2
	CMPI.b	#NOTESCR_JUMP, D1
	BEQ.w	FMPitch_ClampHigh_Loop3
	CMPI.b	#NOTESCR_PITCHBEND, D1
	BEQ.w	FMPitch_ClampHigh_Loop4
	CMPI.b	#NOTESCR_RESTART, D1
	BEQ.w	FMPitch_ClampHigh_Loop5
	BCS.w	FMPitch_ClampHigh
	ORI.w	#$FF00, D1
FMPitch_ClampHigh:
	ADD.w	D1, D4
	BRA.w	FMPitch_WriteFrequency
FMPitch_ClampHigh_Loop:
	SUBQ.b	#1, fmch_lfo_phase(A3)	
	MOVE.w	#0, D1	
	BRA.b	FMPitch_ClampHigh	
FMPitch_ClampHigh_Loop2:
	SUBQ.b	#2, fmch_lfo_phase(A3)
	SUBQ.b	#2, D0
	BRA.b	FMChannel_NoteLoop
FMPitch_ClampHigh_Loop3:
	MOVE.b	(A0,D0.w), D0
	BRA.b	FMChannel_NoteLoop
FMPitch_ClampHigh_Loop4:
	MOVE.b	(A0,D0.w), D1
	ADD.b	D1, fmch_lfo_depth(A3)
	MOVE.b	fmch_lfo_depth(A3), D3
	ADDQ.w	#1, D0
	BRA.b	FMChannel_NoteLoop
FMPitch_ClampHigh_Loop5:
	MOVE.b	#0, D0
	BRA.b	FMChannel_NoteLoop
FMPitch_WriteFrequency:
	BTST.b	#6, fmch_flags(A3)
	BNE.w	FMPitchBend_Return
	CLR.w	D0
	MOVE.b	fmch_channel_id(A3), D0
	CMPI.b	#SOUND_SCRIPT_CMD_THRESHOLD, D0
	BNE.w	FMPitch_WriteFrequency_Loop
	MOVE.w	#$00C0, D0	
FMPitch_WriteFrequency_Loop:
	MOVE.w	D4, D5
	BNE.w	FMPitch_WriteFrequency_Loop2
	MOVE.b	#$1F, fmch_pitch_bend(A3)
FMPitch_WriteFrequency_Loop2:
	ANDI.w	#$000F, D5
	OR.w	D5, D0
	MOVE.b	D0, PSG_port
	ANDI.w	#$0FF0, D4
	LSR.w	#4, D4
	MOVE.b	D4, PSG_port
FMPitchBend_Return:
	RTS
	
; ProcessSoundChannelSequencer
; Resets arp_phase. If pitch_bend is $1F (rest), does key-on
; via UpdateYM2612Channel_Loop. Otherwise runs arpeggio via
; ProcessSoundCommand_Loop.
; Inputs: A3 = channel struct
ProcessSoundChannelSequencer:
	MOVE.b	#0, fmch_arp_phase(A3)
	CMPI.b	#$1F, fmch_pitch_bend(A3)
	BEQ.w	UpdateYM2612Channel_Loop
	BRA.w	ProcessSoundCommand_Loop
; ProcessSoundCommand
; Per-frame arpeggio processor. If arpeggio_idx is zero or
; pitch_bend is a rest/no-bend value, returns immediately.
; Otherwise steps through the arpeggio table and writes the
; resulting volume+channel byte to PSG output ($C00011).
; Inputs: A3 = channel struct
ProcessSoundCommand:
	MOVE.b	fmch_arpeggio_idx(A3), D7
	BEQ.w	SoundCommand_Return
	CMPI.b	#$1F, fmch_pitch_bend(A3)
	BEQ.w	SoundCommand_Return
	CMPI.b	#$FF, fmch_pitch_bend(A3)
	BEQ.w	SoundCommand_Return
ProcessSoundCommand_Loop:
	MOVE.b	fmch_volume(A3), D4
	MOVE.b	fmch_arpeggio_idx(A3), D7
	BEQ.w	FMArpeggio_ReadNote_Loop
	CLR.w	D0
	MOVE.b	D7, D0
	LEA	ProcessSoundCommand_Loop_Data, A0
	BSR.w	GetSoundDataPointer
	CLR.w	D0
	MOVE.b	fmch_arp_phase(A3), D0
FMArpeggio_ReadNote:
	MOVE.b	(A0,D0.w), D1
	ADDQ.w	#1, D0
	MOVE.b	D0, fmch_arp_phase(A3)
	BTST.l	#7, D1
	BEQ.w	FMArpeggio_ReadNote_Loop2
	CMPI.b	#NOTESCR_REST, D1
	BEQ.w	SoundCommand_Return_Loop
	CMPI.b	#NOTESCR_LOOP, D1
	BEQ.w	SoundCommand_Return_Loop2
	CMPI.b	#NOTESCR_RESTART, D1	
	BEQ.w	SoundCommand_Return_Loop3	
FMArpeggio_ReadNote_Loop2:
	ADD.b	D1, D4
	CMPI.b	#$0F, D4
	BCS.w	FMArpeggio_ReadNote_Loop3
	MOVE.w	#$000F, D4
FMArpeggio_ReadNote_Loop3:
	ANDI.w	#$000F, D4
FMArpeggio_ReadNote_Loop:
	BTST.b	#7, fmch_flags(A3)
	BEQ.w	SoundCommand_Return
	OR.b	fmch_channel_id(A3), D4
	ADDI.b	#$10, D4
	MOVE.b	D4, PSG_port
SoundCommand_Return:
	RTS
	
SoundCommand_Return_Loop:
	SUBQ.b	#1, fmch_arp_phase(A3)
	BSR.w	UpdateYM2612Channel
	RTS
	
SoundCommand_Return_Loop2:
	SUBQ.b	#2, D0
	BRA.b	FMArpeggio_ReadNote
SoundCommand_Return_Loop3:
	MOVE.b	#0, D0	
	BRA.b	FMArpeggio_ReadNote	
; ApplyChannelPitchSlide
; Adds or subtracts fmch_pitch_slide from fmch_note_freq to
; produce a linear pitch-bend/glide for FM channels.
; Inputs: A3 = channel struct
ApplyChannelPitchSlide:
	MOVE.w	#0, D0	
	MOVE.w	fmch_note_freq(A3), D1	
	MOVE.b	fmch_pitch_slide(A3), D0	
	BMI.w	ApplyChannelPitchSlide_Loop	
	ADD.w	D0, D1	
	BRA.w	ApplyChannelPitchSlide_Loop2	
ApplyChannelPitchSlide_Loop:
	NEG.b	D0	
	SUB.w	D0, D1	
ApplyChannelPitchSlide_Loop2:
	MOVE.w	D1, fmch_note_freq(A3)	
	RTS
	
; UpdateYM2612Channel
; Sets the key-on bit (bit 1 of fmch_flags), sets pitch_bend
; to $1F (rest), then falls through to UpdateYM2612Channel_Loop
; to write the key-on/off byte to PSG port $C00011.
; Inputs: A3 = channel struct
UpdateYM2612Channel:
	BSET.b	#1, fmch_flags(A3)
	MOVE.b	#$1F, fmch_pitch_bend(A3)
UpdateYM2612Channel_Loop:
	MOVE.b	fmch_pitch_bend(A3), D4
	ADD.b	fmch_channel_id(A3), D4
	CMPI.b	#$FF, D4
	BNE.w	UpdateYM2612Channel_Loop2
	MOVE.b	#$DF, D7	
	MOVE.b	D7, PSG_port	
	NOP	
	NOP	
	NOP	
UpdateYM2612Channel_Loop2:
	MOVE.b	D4, PSG_port
	RTS
	
SetSoundNoteFrequency_Loop2_Data:
	dc.w	$0000
	dc.b	$00
	dc.b	$00, $00, $00, $00, $00, $00, $00 
	dc.w	$0000
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $03, $F8, $03, $BF, $03, $89, $03, $56, $03, $26, $02, $FA, $02, $CE, $02, $A6, $02, $80, $02, $5C, $02, $3A, $02, $1A 
	dc.b	$01, $FC, $01, $DF, $01, $C4, $01, $AB, $01, $93, $01, $7D, $01, $67, $01, $53, $01, $40, $01, $2E, $01, $1D, $01, $0D, $00, $FE, $00, $F0, $00, $E2, $00, $D6 
	dc.b	$00, $CA, $00, $BE, $00, $B4, $00, $AA, $00, $A0, $00, $97, $00, $8F, $00, $87, $00, $7F, $00, $78, $00, $71, $00, $6B, $00, $65, $00, $5F, $00, $5A, $00, $55 
	dc.b	$00, $50, $00, $4B, $00, $47, $00, $43, $00, $40, $00, $3C, $00, $38, $00, $36, $00, $33, $00, $30, $00, $2D, $00, $2B, $00, $28, $00, $25, $00, $23, $00, $21 
	dc.b	$00, $1F, $00, $1E, $00, $1B, $00, $1A, $00, $19, $00, $17, $00, $16, $00, $15, $00, $14, $00, $13, $00, $12, $00, $11, $00, $00, $00, $00, $00, $00 
SoundCommand_JumpTable_Loop_Data:
	dc.b	$03, $05, $0A, $10, $00, $00, $06, $02, $14, $0A, $08, $09, $26, $18, $05, $0A, $05, $06, $16, $03, $03, $0B, $0B, $05, $05, $07, $06, $08, $00, $00, $00, $00 

;==============================================================
; DATA TABLES — FREQUENCY, LFO, AND COMMAND DATA
; Frequency lookup tables for FM and PSG notes, LFO vibrato
; waveform tables, arpeggio patterns, and music command data.
;==============================================================

; SoundLFO_PointerTable
; Table of 48 longword pointers to LFO waveform data.
; Indexed by fmch_vibrato_idx - 1. Entries 5-9 point to
; SoundLFO_NullEntry (no vibrato). Each waveform is a series
; of signed byte pitch offsets terminated by control bytes
; ($80=end, $81=loop, $83=set repeat count, $84/$85=pitch-bend).
SoundLFO_PointerTable:
	dc.l	SoundLFO_PointerTable_Entry_939CA
	dc.l	SoundLFO_PointerTable_Entry_939DC
	dc.l	SoundLFO_PointerTable_Entry_939EE
	dc.l	SoundLFO_PointerTable_Entry_939FC
	dc.l	SoundLFO_PointerTable_Entry_93A0C
	dc.l	SoundLFO_NullEntry	
	dc.l	SoundLFO_NullEntry	
	dc.l	SoundLFO_NullEntry	
	dc.l	SoundLFO_NullEntry	
	dc.l	SoundLFO_NullEntry	
	dc.l	SoundLFO_PointerTable_Entry_93A60
	dc.l	SoundLFO_PointerTable_Entry_93A8E	
	dc.l	SoundLFO_PointerTable_Entry_93AA6
	dc.l	SoundLFO_PointerTable_Entry_93ABC	
	dc.l	SoundLFO_PointerTable_Entry_93AD0	
	dc.l	SoundLFO_PointerTable_Entry_93AF6
	dc.l	SoundLFO_PointerTable_Entry_93AF8
	dc.l	SoundLFO_PointerTable_Entry_93AFA
	dc.l	SoundLFO_PointerTable_Entry_93AFC
	dc.l	SoundLFO_PointerTable_Entry_93AFE
	dc.l	SoundLFO_PointerTable_Entry_93B00
	dc.l	SoundLFO_PointerTable_Entry_93B02
	dc.l	SoundLFO_PointerTable_Entry_93B04	
	dc.l	SoundLFO_PointerTable_Entry_93B06
	dc.l	SoundLFO_PointerTable_Entry_93B08	
	dc.l	SoundLFO_PointerTable_Entry_93B0A	
	dc.l	SoundLFO_PointerTable_Entry_93B0C	
	dc.l	SoundLFO_PointerTable_Entry_93B0E	
	dc.l	SoundLFO_PointerTable_Entry_93B10	
	dc.l	SoundLFO_PointerTable_Entry_93B12	
	dc.l	SoundLFO_PointerTable_Entry_93B14	
	dc.l	SoundLFO_PointerTable_Entry_93B16	
	dc.l	SoundLFO_PointerTable_Entry_93B18	
	dc.l	SoundLFO_PointerTable_Entry_93B1A	
	dc.l	SoundLFO_PointerTable_Entry_93B1C	
	dc.l	SoundLFO_PointerTable_Entry_93B1E	
	dc.l	SoundLFO_PointerTable_Entry_93B20	
	dc.l	SoundLFO_PointerTable_Entry_93B22	
	dc.l	SoundLFO_PointerTable_Entry_93B24	
	dc.l	SoundLFO_PointerTable_Entry_93B26	
	dc.l	SoundLFO_PointerTable_Entry_93B28	
	dc.l	SoundLFO_PointerTable_Entry_93B2A	
	dc.l	SoundLFO_PointerTable_Entry_93B2C	
	dc.l	SoundLFO_PointerTable_Entry_93B2E	
	dc.l	SoundLFO_PointerTable_Entry_93B30	
	dc.l	SoundLFO_PointerTable_Entry_93B32	
	dc.l	SoundLFO_PointerTable_Entry_93B34	
SoundLFO_PointerTable_Entry_939CA:
	dc.b	$01, $02, $03, $04, $03, $02, $01, $00, $FF, $FE, $FD, $FC, $FD, $FE, $FF, $00, $80, $00 
SoundLFO_PointerTable_Entry_939DC:
	dc.b	$01, $02, $04, $08, $04, $02, $01, $00, $FF, $FE, $FC, $F8, $FC, $FE, $FF, $00, $80, $00 
SoundLFO_PointerTable_Entry_939EE:
	dc.b	$02, $04, $08, $04, $02, $00, $FE, $FC, $F8, $FC, $FE, $00, $80, $00 
SoundLFO_PointerTable_Entry_939FC:
	dc.b	$C0, $F0, $F8, $00, $00, $01, $01, $00, $00, $FF, $FF, $84, $02, $85, $03, $00 
SoundLFO_PointerTable_Entry_93A0C:
	dc.b	$C0
	dc.b	$D0
	dc.b	$F0
	dc.b	$00, $00, $00, $01, $01, $02, $01, $00, $00, $FF, $FF, $FE, $FF, $FF, $84, $01, $85, $03, $00 
SoundLFO_NullEntry:
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $02, $02 
	dc.b	$03, $03, $04, $04, $03, $03, $02, $02, $01, $01, $00, $00, $FF, $FF, $FE, $FE, $FD, $FD, $FC, $FC, $FD, $FD, $FE, $FE, $FF, $FF, $00, $00, $85, $20 
SoundLFO_PointerTable_Entry_93A60:
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $03, $04 
	dc.b	$03, $02, $01, $00, $FF, $FE, $FD, $FC, $FD, $FE, $FF, $00, $80, $00 
SoundLFO_PointerTable_Entry_93A8E:
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FE, $FF, $84, $01, $85, $04, $00 
SoundLFO_PointerTable_Entry_93AA6:
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $84, $01, $85, $03, $00 
SoundLFO_PointerTable_Entry_93ABC:
	dc.b	$01, $01, $01, $02, $02, $02, $03, $03, $03, $02, $02, $02, $01, $01, $01, $00, $00, $00, $80, $00 
SoundLFO_PointerTable_Entry_93AD0:
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, $02, $04, $04, $06, $06, $04, $04, $02, $02, $00, $00, $FE, $FE, $FC, $FC, $FA, $FA, $FC 
	dc.b	$FC, $FE, $FE, $85, $18, $00 
SoundLFO_PointerTable_Entry_93AF6:
	dc.b	$00
	dc.b	$81
SoundLFO_PointerTable_Entry_93AF8:
	dc.b	$01
	dc.b	$81
SoundLFO_PointerTable_Entry_93AFA:
	dc.b	$02
	dc.b	$81
SoundLFO_PointerTable_Entry_93AFC:
	dc.b	$03
	dc.b	$81
SoundLFO_PointerTable_Entry_93AFE:
	dc.b	$04
	dc.b	$81
SoundLFO_PointerTable_Entry_93B00:
	dc.b	$05
	dc.b	$81
SoundLFO_PointerTable_Entry_93B02:
	dc.b	$06
	dc.b	$81
SoundLFO_PointerTable_Entry_93B04:
	dc.b	$07
	dc.b	$81 
SoundLFO_PointerTable_Entry_93B06:
	dc.b	$08
	dc.b	$81
SoundLFO_PointerTable_Entry_93B08:
	dc.b	$09
	dc.b	$81 
SoundLFO_PointerTable_Entry_93B0A:
	dc.b	$0A, $81 
SoundLFO_PointerTable_Entry_93B0C:
	dc.b	$0B, $81 
SoundLFO_PointerTable_Entry_93B0E:
	dc.b	$0C, $81 
SoundLFO_PointerTable_Entry_93B10:
	dc.b	$0D, $81 
SoundLFO_PointerTable_Entry_93B12:
	dc.b	$0E, $81 
SoundLFO_PointerTable_Entry_93B14:
	dc.b	$0F, $81 
SoundLFO_PointerTable_Entry_93B16:
	dc.b	$00, $81 
SoundLFO_PointerTable_Entry_93B18:
	dc.b	$FF, $81 
SoundLFO_PointerTable_Entry_93B1A:
	dc.b	$FE, $81 
SoundLFO_PointerTable_Entry_93B1C:
	dc.b	$FD, $81 
SoundLFO_PointerTable_Entry_93B1E:
	dc.b	$FC, $81 
SoundLFO_PointerTable_Entry_93B20:
	dc.b	$FB, $81 
SoundLFO_PointerTable_Entry_93B22:
	dc.b	$FA, $81 
SoundLFO_PointerTable_Entry_93B24:
	dc.b	$F9, $81 
SoundLFO_PointerTable_Entry_93B26:
	dc.b	$F8, $81 
SoundLFO_PointerTable_Entry_93B28:
	dc.b	$F7, $81 
SoundLFO_PointerTable_Entry_93B2A:
	dc.b	$F6, $81 
SoundLFO_PointerTable_Entry_93B2C:
	dc.b	$F5, $81 
SoundLFO_PointerTable_Entry_93B2E:
	dc.b	$F4, $81 
SoundLFO_PointerTable_Entry_93B30:
	dc.b	$F3, $81 
SoundLFO_PointerTable_Entry_93B32:
	dc.b	$F2, $81 
SoundLFO_PointerTable_Entry_93B34:
	dc.b	$F1, $81 
SoundCommand_JumpTable_Loop_Data2:
	dc.b	$4E, $92, $00, $00, $03, $92, $06, $B4, $07, $48, $07, $D6, $09, $08, $0B, $80, $0F, $70, $0F, $F0, $13, $C8, $19, $3A, $1C, $3E, $1D, $38, $20, $60, $26, $34 
	dc.b	$26, $FC, $29, $14, $2C, $E2, $2F, $EE, $31, $12, $32, $A8, $37, $5E, $38, $42, $39, $D0, $40, $D4, $48, $08, $50, $F2 
SoundCommand_JumpTable_Loop2_Data:
	incbin "data/sound/sound_cmd_data.bin"
FM_FrequencyTable:
	dc.b	$58, $BC, $58, $D6, $58, $F0, $59, $0A, $59, $24, $59, $3E, $59, $58, $59, $72, $59, $8C, $59, $A6, $59, $C0, $59, $DA, $59, $F4, $5A, $0E, $5A, $28, $5A, $42 
	dc.b	$5A, $5C, $5A, $76, $5A, $76, $5A, $76, $5A, $76, $5A, $76, $5A, $76, $5A, $76, $5A, $76, $5A, $76, $5A, $76, $5A, $76, $5A, $76, $5A, $76, $5A, $76, $5A, $76 
	dc.b	$5A, $76, $5A, $76, $5A, $76 
	dc.w	$5A76
	dc.w	$5A90
	dc.w	$5AAA
	dc.b	$5A, $C4, $5A, $C4 
	dc.w	$5ADE
	dc.w	$5AF8
	dc.w	$5B12
	dc.b	$5B, $2C, $5B, $2C, $5B, $2C 
	dc.w	$5B2C
	dc.b	$5B, $46 
	dc.w	$5B46
	dc.b	$5B, $60 
	dc.w	$5B60
	dc.w	$5B7A
	dc.w	$5B7A
	dc.b	$5B, $94, $5B, $94 
	dc.w	$5B94
	dc.b	$5B, $AE, $5B, $AE 
	dc.w	$5BAE
	dc.w	$5BAE
	dc.b	$5B, $C8, $5B, $C8, $5B, $C8, $5B, $C8, $5B, $C8, $5B, $C8, $5B, $C8, $5B, $C8, $5B, $C8, $5B, $C8, $5B, $C8, $5B, $C8 
	dc.w	$5BC8
	dc.b	$5B, $E2, $5B, $E2, $5B, $E2 
	dc.w	$5BE2
	dc.b	$5B, $FC, $5B, $FC, $5B, $FC, $5B, $FC, $5B, $FC, $5B, $FC 
	dc.w	$5BFC
	dc.b	$5C, $16, $5C, $16, $5C, $16 
	dc.w	$5C16
	dc.w	$5C30
	dc.b	'\\J\\J\\J\\J\\J\\J\\J\\J\\J\\J\\J' 
	dc.w	$5C4A
	dc.b	$5C, $64, $5C, $64 
	dc.w	$5C64
	dc.b	'\\z\\z\\z\\z\\z' 
	dc.w	$5C7A
	dc.b	$5C, $94, $5C, $94 
	dc.w	$5C94
	dc.w	$5CAE
	dc.b	$5C, $C8, $5C, $C8, $5C, $C8, $5C, $C8 
	dc.w	$5CC8
	dc.b	$5C, $C8, $5C, $C8, $5C, $C8 
	dc.w	$5CC8
	dc.b	$5C, $E2, $5C, $E2, $5C, $E2, $5C, $E2 
	dc.w	$5CE2
	dc.b	$5C, $FC, $5C, $FC, $5C, $FC, $5C, $FC 
	dc.w	$5CFC
	dc.b	$5D, $16 
	dc.w	$5D16
	dc.b	$5D, $30, $5D, $30, $5D, $30 
	dc.w	$5D30
	dc.w	$5D4A
	dc.b	']d]d]d]d]d]d]d]d]d]d' 
	dc.w	$5D64
	dc.b	$5D, $7E, $5D, $7E 
	dc.w	$5D7E
	dc.w	$5D98
	dc.w	$5DB2
	dc.b	$5D, $CC 
	dc.w	$5DCC
	dc.b	$5D, $E6, $5D, $E6, $5D, $E6, $5D, $E6, $5D, $E6, $5D, $E6 
	dc.w	$5DE6
	dc.b	$5E, $00, $5E, $00, $5E, $00, $5E, $00, $5E, $00 
	dc.w	$5E00
	dc.b	$5E, $1A 
	dc.w	$5E1A
	dc.w	$5E34
	dc.b	'^N^N^N^N^N^N^N^N^N' 
	dc.w	$5E4E
	dc.b	'^h^h^h^h^h^h' 
	dc.w	$5E68
	dc.b	$5E, $82, $5E, $82, $5E, $82, $5E, $82 
	dc.w	$5E82
	dc.b	$5E, $9C 
	dc.w	$5E9C
	dc.b	$5E, $B6, $5E, $B6, $5E, $B6 
	dc.w	$5EB6
	dc.b	$5E, $D0, $5E, $D0, $5E, $D0, $5E, $D0, $5E, $D0, $5E, $D0, $5E, $D0, $5E, $D0, $5E, $D0, $5E, $D0, $5E, $D0, $5E, $D0, $5E, $D0, $5E, $D0, $5E, $D0, $5E, $D0 
	dc.b	$5E, $D0 
	dc.w	$5ED0
	dc.w	$5EEA
	dc.b	$5F, $04, $5F, $04, $5F, $04, $5F, $04, $5F, $04, $5F, $04 
	dc.w	$5F04
	dc.b	$5F, $1E, $5F, $1E 
	dc.w	$5F1E
	dc.w	$5F38
	dc.w	$5F52
	dc.b	$5F, $6C 
	dc.w	$5F6C
	dc.b	$5F, $86, $5F, $86, $5F, $86 
	dc.w	$5F86
	dc.b	$5F, $A0, $5F, $A0, $5F, $A0, $5F, $A0, $5F, $A0, $5F, $A0, $5F, $A0 
	dc.w	$5FA0
	dc.b	$5F, $BA, $5F, $BA, $5F, $BA, $5F, $BA, $5F, $BA, $5F, $BA, $5F, $BA, $5F, $BA, $5F, $BA, $17, $00, $0E, $00, $0E, $45, $21, $58, $32, $15, $1A, $18, $15, $09 
	dc.b	$08, $0C, $0C, $00, $00, $26, $09, $DD, $DD, $DD, $DD, $00, $3C, $20, $00, $30, $00, $34, $52, $52, $32, $15, $15, $15, $15, $10, $10, $17, $0C, $01, $03, $07 
	dc.b	$0A, $DD, $DD, $DD, $DD, $00, $28, $17, $32, $14, $00, $39, $53, $02, $12, $DF, $DF, $81, $9F, $0C, $07, $0A, $0A, $07, $07, $07, $09, $CC, $CC, $CC, $CC, $00 
	dc.b	$3D, $0C, $00, $00, $00, $79, $73, $70, $70, $1F, $1F, $10, $1F, $00, $00, $04, $00, $09, $05, $08, $05, $6F, $6F, $4F, $4F, $00, $02, $10, $00, $00, $00, $8A 
	dc.b	$48, $43, $10, $1F, $1E, $1F, $1F, $08, $08, $08, $08, $15, $15, $15, $15, $6F, $7A, $88, $9F, $00, $3C, $20, $00, $30, $00, $34, $52, $52, $32, $1F, $1F, $1F 
	dc.b	$1F, $10, $10, $17, $0C, $01, $03, $05, $07, $CF, $EF, $DC, $CE, $00, $83, $20, $20, $3C, $00, $64, $3C, $33, $64, $1F, $1C, $10, $1B, $10, $0E, $04, $10, $06 
	dc.b	$08, $1A, $0B, $4C, $4C, $48, $4C, $00, $3C, $38, $00, $1D, $00, $30, $01, $0F, $04, $8D, $52, $9F, $1F, $09, $00, $00, $0D, $00, $00, $00, $00, $CC, $CC, $CC 
	dc.b	$CC, $00, $2F, $0A, $0E, $0A, $0E, $45, $21, $58, $32, $1F, $1A, $18, $1F, $09, $08, $0C, $0C, $00, $00, $26, $09, $DD, $DD, $DD, $DD, $00, $3C, $20, $00, $30 
	dc.b	$00, $34, $52, $52, $32, $1F, $1F, $1F, $1F, $10, $10, $17, $0C, $01, $03, $05, $07, $CF, $EF, $DC, $CE, $00, $18, $02, $10, $10, $00, $01, $03, $53, $00, $1B 
	dc.b	$1F, $1F, $1F, $14, $14, $14, $14, $00, $00, $00, $07, $CC, $CC, $CC, $CC, $00, $13, $11, $04, $0F, $04, $30, $10, $10, $00, $97, $1B, $9F, $1F, $09, $0D, $00 
	dc.b	$0D, $00, $06, $00, $00, $29, $AC, $02, $AE, $00, $D1, $32, $32, $08, $00, $73, $12, $60, $21, $1F, $1F, $19, $D9, $1F, $1F, $1F, $1F, $00, $00, $01, $00, $00 
	dc.b	$00, $00, $06, $00, $24, $1E, $00, $1E, $00, $38, $74, $76, $33, $14, $0F, $14, $0B, $02, $05, $04, $05, $03, $03, $03, $03, $CC, $CC, $CC, $CC, $00, $FA, $24 
	dc.b	$27, $20, $00, $31, $25, $63, $01, $5F, $1F, $1F, $D9, $08, $05, $04, $1F, $03, $04, $02, $01, $FF, $25, $25, $25, $00, $28, $1E, $19, $16, $00, $03, $70, $31 
	dc.b	$00, $1F, $1F, $5F, $5F, $03, $03, $03, $02, $01, $02, $02, $03, $A0, $27, $20, $56, $00, $03, $12, $16, $1C, $00, $18, $71, $01, $01, $1F, $1F, $10, $1F, $0C 
	dc.b	$12, $0B, $08, $00, $01, $0B, $0D, $C7, $26, $20, $F7, $00, $3A, $20, $2A, $2D, $00, $51, $01, $11, $01, $0F, $10, $0F, $10, $08, $0A, $00, $06, $01, $01, $01 
	dc.b	$01, $12, $12, $12, $18, $00, $3D, $1C, $02, $02, $02, $01, $02, $02, $02, $10, $50, $50, $50, $07, $08, $08, $08, $01, $00, $00, $00, $24, $18, $18, $18, $00 
	dc.b	$3D, $1D, $00, $06, $00, $01, $01, $02, $01, $4C, $0F, $50, $12, $0B, $05, $01, $02, $01, $00, $00, $00, $28, $29, $2A, $19, $00, $3A, $25, $22, $19, $00, $01 
	dc.b	$03, $01, $01, $58, $10, $15, $14, $0A, $0D, $08, $07, $00, $00, $00, $00, $09, $F9, $06, $1B, $00, $3A, $18, $22, $18, $00, $01, $01, $01, $02, $8D, $07, $07 
	dc.b	$52, $09, $00, $00, $03, $01, $02, $02, $00, $52, $02, $02, $28, $00, $3C, $15, $00, $1D, $07, $01, $02, $0F, $04, $8D, $52, $9F, $1F, $09, $00, $00, $0D, $00 
	dc.b	$00, $00, $00, $23, $08, $02, $F6, $00, $3B, $1E, $19, $1E, $00, $51, $32, $31, $52, $1F, $1F, $1F, $1F, $0F, $00, $0F, $00, $00, $00, $00, $01, $55, $0A, $55 
	dc.b	$5A, $00, $20, $19, $37, $13, $00, $36, $35, $30, $31, $DF, $DF, $9F, $9F, $07, $06, $09, $06, $07, $06, $06, $08, $29, $19, $19, $F9, $00, $31, $17, $32, $14 
	dc.b	$00, $34, $35, $30, $31, $DF, $DF, $9F, $9F, $0C, $07, $0C, $0B, $07, $07, $07, $09, $29, $19, $19, $F9, $00, $18, $2C, $22, $14, $00, $37, $30, $30, $31, $9E 
	dc.b	$DC, $1C, $9C, $0D, $06, $04, $01, $08, $0A, $03, $05, $B6, $B6, $36, $26, $00, $28, $1E, $16, $19, $00, $07, $70, $30, $01, $1F, $1F, $5F, $54, $0D, $03, $03 
	dc.b	$02, $01, $02, $02, $03, $30, $27, $20, $56, $00, $38, $22, $22, $0E, $00, $07, $04, $00, $01, $DF, $1F, $1F, $DF, $04, $17, $04, $00, $06, $09, $04, $1B, $05 
	dc.b	$05, $15, $AC, $00, $3A, $1E, $20, $2A, $00, $71, $04, $30, $01, $0F, $19, $14, $16, $08, $0B, $0A, $05, $03, $03, $03, $05, $15, $85, $65, $57, $00, $3C, $38 
	dc.b	$00, $1D, $00, $30, $01, $0F, $04, $8D, $52, $9F, $1F, $09, $00, $00, $0D, $00, $00, $00, $00, $23, $08, $02, $F6, $00, $38, $20, $20, $20, $00, $01, $03, $53 
	dc.b	$00, $1B, $1F, $1F, $1F, $14, $14, $14, $14, $00, $00, $00, $07, $F3, $F3, $F3, $8A, $00, $3A, $18, $1F, $17, $00, $50, $60, $30, $00, $9F, $89, $5B, $4B, $09 
	dc.b	$09, $1F, $03, $00, $00, $00, $00, $13, $F5, $06, $06, $00, $0C, $18, $10, $21, $00, $58, $02, $20, $01, $1F, $1F, $05, $1F, $0A, $0B, $04, $02, $01, $04, $00 
	dc.b	$00, $52, $62, $56, $96, $00, $0C, $18, $08, $21, $00, $58, $02, $20, $01, $1F, $1F, $05, $1F, $0A, $0B, $04, $06, $01, $04, $00, $00, $52, $62, $56, $66, $00 
	dc.b	$36, $18, $00, $00, $00, $14, $01, $01, $02, $8F, $1F, $1F, $14, $1F, $1F, $0B, $3D, $09, $08, $07, $00, $04, $04, $04, $75, $00, $07, $00, $00, $00, $00, $02 
	dc.b	$41, $31, $60, $05, $03, $08, $09, $03, $05, $05, $00, $20, $20, $26, $06, $00, $2C, $19, $00, $17, $05, $72, $72, $33, $32, $1F, $0F, $1F, $0F, $01, $03, $01 
	dc.b	$03, $01, $01, $01, $01, $10, $27, $10, $27, $00, $3C, $1A, $00, $16, $00, $31, $52, $50, $30, $52, $53, $52, $53, $08, $00, $08, $00, $04, $00, $04, $00, $14 
	dc.b	$07, $14, $06, $00, $F5, $18, $00, $27, $02, $10, $41, $00, $11, $5F, $5F, $5F, $5F, $0E, $1F, $1F, $1F, $00, $00, $00, $00, $46, $07, $07, $07, $00, $FC, $1B 
	dc.b	$00, $2F, $00, $31, $61, $3E, $61, $4B, $8C, $96, $96, $0D, $10, $0C, $08, $01, $07, $08, $07, $27, $25, $44, $25, $00, $22, $1B, $18, $30, $00, $10, $20, $10 
	dc.b	$10, $10, $08, $08, $15, $0E, $10, $04, $09, $01, $00, $00, $01, $F1, $F0, $F0, $E1, $00, $FA, $1B, $7F, $7F, $00, $61, $01, $02, $31, $11, $1F, $1F, $15, $0B 
	dc.b	$1F, $1F, $09, $09, $00, $00, $07, $37, $0F, $0F, $5C, $00, $E0, $18, $1A, $20, $00, $01, $00, $00, $01, $9F, $1F, $1E, $5B, $0F, $10, $0D, $14, $08, $05, $08 
	dc.b	$08, $6F, $0F, $07, $1C, $00, $DF, $00, $00, $00, $06, $33, $36, $61, $31, $1F, $1F, $1F, $1F, $0D, $12, $1F, $9F, $01, $0E, $01, $01, $FB, $0A, $0A, $0A, $00 
	dc.b	$E4, $2F, $00, $1F, $00, $3F, $31, $65, $61, $1F, $18, $1F, $1F, $13, $11, $0E, $11, $0B, $07, $0A, $07, $0A, $14, $0D, $14, $00, $D2, $18, $28, $15, $00, $00 
	dc.b	$08, $00, $01, $1F, $1F, $1F, $1F, $1F, $0C, $0E, $0B, $00, $0C, $0A, $09, $0A, $8B, $38, $16, $00, $FA, $1B, $7F, $7F, $00, $61, $01, $02, $31, $11, $1F, $1F 
	dc.b	$15, $0B, $1F, $1F, $09, $09, $00, $00, $07, $37, $0F, $0F, $5C, $00, $FA, $18, $1D, $24, $00, $12, $04, $56, $04, $5F, $5D, $5D, $5A, $0B, $1F, $1F, $1F, $00 
	dc.b	$00, $00, $00, $05, $05, $04, $06, $00, $FC, $18, $00, $18, $00, $32, $32, $61, $02, $1F, $1C, $1F, $1C, $0C, $10, $07, $10, $02, $04, $04, $04, $12, $16, $12 
	dc.b	$17, $00, $F3, $2E, $17, $32, $00, $00, $10, $70, $00, $1F, $5F, $5F, $5F, $0D, $0A, $09, $08, $18, $0F, $0F, $0F, $B8, $48, $F8, $F8, $00, $F5, $18, $14, $2B 
	dc.b	$00, $10, $41, $00, $11, $5F, $5F, $5F, $5F, $0E, $1F, $1F, $1F, $00, $00, $00, $00, $46, $07, $07, $07, $00, $FA, $1B, $7F, $7F, $00, $61, $01, $02, $31, $11 
	dc.b	$1F, $1F, $15, $0B, $1F, $1F, $09, $09, $00, $00, $07, $37, $0F, $0F, $5C, $00, $FC, $16, $00, $1D, $10, $41, $51, $31, $31, $1F, $1A, $1C, $17, $03, $02, $03 
	dc.b	$1F, $08, $00, $08, $00, $16, $F9, $19, $09, $00, $FA, $1E, $25, $28, $00, $51, $04, $61, $02, $59, $59, $56, $58, $04, $0F, $1F, $1F, $00, $80, $00, $05, $16 
	dc.b	$58, $03, $0A, $00, $C4, $26, $00, $3C, $04, $12, $71, $77, $11, $59, $5F, $5F, $1F, $1C, $0A, $10, $0D, $00, $00, $00, $00, $E6, $E6, $E6, $E4, $00, $FB, $2E 
	dc.b	$24, $13, $00, $3C, $39, $30, $31, $DF, $1F, $1F, $DF, $04, $05, $04, $01, $04, $04, $04, $02, $F7, $07, $17, $AC, $00, $C6, $2D, $00, $00, $00, $43, $16, $72 
	dc.b	$11, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F, $00, $00, $00, $00, $08, $08, $08, $08, $00, $FE, $2E, $06, $00, $00, $04, $04, $02, $01, $1F, $1F, $1F, $1F, $00 
	dc.b	$00, $00, $00, $00, $00, $00, $00, $05, $05, $05, $05, $00, $FA, $16, $29, $28, $00, $10, $20, $70, $00, $9F, $89, $5B, $4B, $09, $09, $1F, $03, $00, $00, $00 
	dc.b	$00, $13, $F5, $06, $06, $00, $FB, $24, $06, $1F, $00, $01, $71, $72, $12, $D7, $9F, $9F, $DF, $0E, $06, $06, $05, $09, $04, $03, $08, $10, $81, $A0, $80, $00 
	dc.b	$F0, $1B, $1F, $18, $00, $00, $00, $00, $00, $1F, $1F, $1F, $1F, $06, $1F, $1F, $1F, $00, $00, $00, $00, $F0, $00, $00, $01, $00, $F3, $45, $00, $16, $00, $13 
	dc.b	$10, $15, $10, $12, $14, $14, $0F, $08, $07, $0B, $06, $01, $01, $04, $00, $A3, $A3, $61, $31, $00, $D2, $1B, $2B, $15, $00, $00, $08, $00, $01, $1F, $1F, $1F 
	dc.b	$1F, $1F, $0C, $0E, $0B, $00, $0C, $0A, $09, $0A, $8B, $38, $1C, $00, $D1, $32, $32, $08, $00, $73, $12, $60, $21, $1F, $1F, $19, $D9, $1F, $1F, $1F, $1F, $00 
	dc.b	$00, $01, $00, $00, $00, $00, $06, $00, $E4, $25, $00, $3E, $00, $7F, $71, $15, $11, $1F, $58, $1F, $1F, $13, $11, $0E, $11, $04, $08, $05, $08, $55, $05, $62 
	dc.b	$05, $00, $F3, $19, $13, $1B, $00, $12, $01, $03, $01, $1F, $1F, $14, $15, $05, $0F, $0B, $0A, $00, $07, $06, $00, $12, $32, $22, $06, $00, $C7, $00, $00, $0A 
	dc.b	$00, $71, $74, $7E, $11, $1F, $1F, $5F, $1F, $14, $14, $10, $14, $07, $0B, $15, $07, $27, $27, $F6, $27, $00, $D2, $1B, $2B, $15, $00, $00, $08, $00, $01, $1F 
	dc.b	$1F, $1F, $1F, $1F, $0C, $0E, $0B, $00, $0C, $0A, $09, $0A, $8B, $38, $1C, $00 
ProcessSoundCommand_Loop_Data:
	dc.b	$00, $00 
	dc.w	$5FD4
	dc.w	$5FE0
	dc.b	$60, $12, $60, $1C, $60, $28, $60, $32, $60, $4C, $60, $5E, $60, $68, $60, $92, $60, $9C, $60, $9C, $01, $00, $00, $00, $01, $02, $03, $03, $04, $04, $05, $81 
	dc.b	$00, $01, $01, $01, $02, $02, $02, $03, $03, $03, $04, $04, $04, $04, $05, $05, $05, $05, $06, $06, $06, $06, $07, $07, $07, $07, $08, $08, $08, $08, $09, $09 
	dc.b	$0A, $0A, $0A, $0A, $0B, $0B, $0B, $0B, $0C, $0C, $0C, $0D, $0D, $0E, $0E, $0F, $83, $00, $02, $02, $05, $05, $0B, $0A, $04, $04, $80, $00, $01, $00, $00, $00 
	dc.b	$01, $02, $03, $03, $03, $03, $04, $81, $00, $00, $00, $00, $01, $02, $03, $03, $81, $00, $06, $07, $06, $06, $05, $06, $05, $05, $04, $05, $04, $04, $03, $04 
	dc.b	$03, $03, $02, $03, $02, $02, $01, $02, $01, $01, $81, $00, $04, $03, $02, $01, $00, $00, $00, $01, $01, $01, $01, $01, $02, $01, $02, $02, $81, $00, $03, $02 
	dc.b	$01, $00, $00, $00, $00, $00, $81, $00, $0A, $0B, $0A, $0A, $09, $0A, $09, $09, $08, $09, $08, $08, $07, $08, $07, $07, $06, $07, $06, $06, $05, $06, $05, $05 
	dc.b	$04, $05, $04, $04, $03, $04, $03, $03, $02, $03, $02, $02, $01, $02, $01, $01, $81, $00, $04, $03, $02, $01, $00, $00, $00, $00, $81, $00 

;==============================================================
; DAC SAMPLE TABLE AND PCM AUDIO DATA
; Table of (start, end) pointer pairs for PCM samples uploaded
; to Z80 RAM at $A00200. Index 0 is a null entry. Samples are
; raw signed 8-bit PCM. Two entries use equ aliases pointing
; into the middle of incbin blocks.
;==============================================================

; LoadDAC_SampleToZ80_Data
; Pairs of (start, end) pointers for each DAC sample slot.
; Entry 0: null ($00000000 start = no sample).
; Entries 1-10: point to PCM data below or in incbin files.
LoadDAC_SampleToZ80_Data:
	dc.l	$00000000 
	dc.l	LoadDAC_SampleToZ80_Data_Entry_99CC8
	dc.l	LoadDAC_SampleToZ80_Data_Entry_9AAB4
	dc.l	LoadDAC_SampleToZ80_Data_Entry_9B492
	dc.l	LoadDAC_SampleToZ80_Data_Entry_9C888
	dc.l	LoadDAC_SampleToZ80_Data_Entry_9CAF0
	dc.l	LoadDAC_SampleToZ80_Data_Entry_9CF28
	dc.l	LoadDAC_SampleToZ80_Data_Entry_9E9D8
	dc.l	LoadDAC_SampleToZ80_Data_Entry_9EC38
	dc.l	LoadDAC_SampleToZ80_Data_Entry_9FD86
	dc.l	LoadDAC_SampleToZ80_Data_Entry_9FF7E
LoadDAC_SampleToZ80_Data_Entry_99CC8:
	incbin "data/sound/dac/dac_sample_99cc8.bin"
LoadDAC_SampleToZ80_Data_Entry_9AAB4:
	incbin "data/sound/dac/dac_sample_9aab4.bin"
LoadDAC_SampleToZ80_Data_Entry_9B492:
	incbin "data/sound/dac/dac_sample_9b492.bin"
LoadDAC_SampleToZ80_Data_Entry_9C888:
	dc.b	$08, $02, $00, $00, $14, $02, $15, $02, $00, $00, $00, $00, $80, $02, $16, $02, $80, $02, $16, $02, $10, $55, $08, $08, $08, $09, $89, $09, $80, $00, $01, $02 
	dc.b	$01, $00, $88, $99, $9A, $98, $98, $00, $11, $12, $11, $10, $98, $99, $99, $98, $90, $81, $01, $10, $10, $00, $00, $09, $0A, $99, $99, $A1, $88, $11, $10, $20 
	dc.b	$11, $00, $A0, $99, $98, $81, $90, $00, $00, $01, $18, $80, $98, $09, $08, $08, $00, $18, $08, $99, $01, $09, $00, $01, $89, $00, $90, $00, $11, $10, $00, $90 
	dc.b	$98, $99, $9A, $08, $91, $10, $00, $99, $00, $80, $00, $10, $00, $08, $8A, $99, $09, $11, $21, $21, $09, $9A, $AB, $A9, $00, $23, $23, $32, $29, $AB, $BC, $BA 
	dc.b	$91, $32, $33, $33, $89, $AA, $AB, $AB, $91, $22, $33, $32, $9A, $BB, $CB, $A2, $33, $33, $22, $09, $AA, $BB, $82, $13, $32, $89, $B9, $9A, $9A, $AA, $9A, $23 
	dc.b	$23, $32, $39, $AC, $AA, $24, $43, $9B, $CC, $B4, $34, $29, $CC, $B2, $34, $2C, $CC, $B3, $44, $3B, $D9, $44, $23, $BC, $D4, $44, $32, $8C, $29, $22, $3A, $B9 
	dc.b	$B3, $BB, $43, $0C, $DB, $35, $4C, $DD, $05, $51, $CC, $1A, $33, $AB, $34, $5C, $DC, $33, $44, $CC, $13, $3B, $C1, $54, $3C, $CD, $15, $5A, $CC, $C3, $4B, $D4 
	dc.b	$3C, $52, $C0, $8C, $36, $CC, $BC, $45, $58, $EC, $35, $54, $DE, $24, $63, $DE, $C5, $55, $CE, $D5, $6A, $DD, $D4, $65, $DE, $D5, $55, $CD, $B3, $55, $DD, $45 
	dc.b	$4A, $C4, $2C, $60, $E5, $4D, $5B, $1E, $0C, $48, $C4, $5D, $E5, $54, $D4, $03, $B3, $2D, $C6, $C5, $C5, $DE, $7D, $BD, $4E, $6C, $5C, $FF, $5C, $2A, $5E, $D5 
	dc.b	$D4, $62, $E5, $C9, $35, $D6, $D2, $5F, $56, $4E, $56, $F6, $58, $F4, $6E, $65, $2E, $EB, $C7, $15, $D5, $FC, $36, $55, $DD, $EA, $A6, $6C, $E3, $E5, $5C, $56 
	dc.b	$EE, $46, $E6, $5A, $FC, $17, $53, $DD, $E0, $66, $DD, $E6, $6C, $E5, $E7, $E6, $F5, $D7, $E6, $EC, $D6, $6C, $DA, $E4, $C6, $D6, $E6, $E6, $D4, $25, $E4, $F2 
	dc.b	$7E, $3D, $7F, $6C, $C5, $E7, $F7, $F6, $D0, $6F, $7E, $65, $F7, $0F, $55, $3E, $E7, $E1, $D7, $5E, $5D, $53, $E6, $EC, $62, $F7, $4F, $6E, $66, $ED, $6E, $56 
	dc.b	$F6, $53, $D4, $E6, $D5, $F6, $E7, $F6, $C5, $AD, $6E, $06, $EA, $64, $E2, $6F, $55, $5A, $5C, $E5, $E5, $45, $4E, $44, $2C, $4C, $D5, $E5, $6E, $45, $4E, $4E 
	dc.b	$6C, $DC, $7E, $B6, $ED, $64, $DD, $6E, $5E, $6B, $B3, $5E, $44, $5E, $6E, $6D, $5E, $65, $09, $4E, $CC, $B6, $CA, $6C, $D9, $D6, $4C, $D6, $ED, $5D, $63, $EB 
	dc.b	$54, $AD, $55, $DE, $59, $AD, $6E, $5D, $54, $8E, $2C, $6A, $42, $D0, $20, $DC, $64, $A4, $DE, $54, $44, $4B, $DD, $5B, $D6, $6D, $CE, $35, $D7, $DC, $D4, $DD 
	dc.b	$65, $3E, $45, $E4, $5D, $E5, $33, $35, $3C, $ED, $A6, $55, $AD, $DD, $CC, $56, $5A, $DD, $E1, $55, $64, $AD, $ED, $C5, $56, $3B, $2E, $DD, $25, $56, $CB, $BD 
	dc.b	$DA, $54, $C6, $0D, $AB, $9C, $54, $4D, $BC, $DB, $64, $C8, $5B, $E5, $3A, $34, $D9, $BC, $55, $9C, $BB, $D5, $95, $5D, $3D, $2C, $D5, $55, $4D, $3C, $CE, $34 
	dc.b	$54, $3A, $CC, $B0, $B5, $50, $CC, $E5, $4A, $61, $4C, $E5, $E5, $34, $4B, $4E, $4D, $5A, $44, $2D, $44, $BC, $D5, $CB, $44, $D5, $A4, $CB, $D4, $2C, $48, $4D 
	dc.b	$8C, $5A, $6C, $CC, $3E, $54, $44, $4C, $C0, $AC, $3A, $B4, $D5, $5A, $2A, $E8, $C0, $56, $4A, $CD, $DC, $22, $64, $0C, $3D, $E4, $12, $55, $8C, $3E, $5C, $A4 
	dc.b	$35, $4C, $CC, $CB, $B4, $55, $08, $00 
LoadDAC_SampleToZ80_Data_Entry_9CAF0:
	dc.b	$06, $02, $00, $00, $0E, $02, $00, $00, $00, $00, $E0, $03, $0F, $02, $05, $08, $08, $08, $0A, $2B, $4A, $B0, $B3, $3B, $93, $1C, $C4, $29, $01, $3A, $24, $3C 
	dc.b	$B4, $CC, $A4, $4B, $C1, $A4, $18, $AC, $C4, $43, $14, $CC, $B4, $4B, $CC, $45, $32, $CC, $BC, $34, $3C, $14, $3B, $BA, $BC, $14, $3A, $94, $4C, $A3, $2C, $3B 
	dc.b	$B4, $CB, $AB, $3C, $30, $22, $35, $3B, $CB, $B0, $23, $A8, $99, $24, $9C, $B2, $33, $A2, $0C, $C2, $44, $0A, $C3, $4C, $43, $BC, $CC, $23, $38, $23, $35, $A3 
	dc.b	$4C, $CD, $0B, $9B, $B4, $32, $4B, $8A, $14, $4B, $CC, $B4, $BD, $A5, $04, $24, $CD, $04, $BB, $54, $AA, $0B, $BB, $CD, $43, $05, $4A, $C4, $5C, $DB, $BC, $43 
	dc.b	$92, $09, $52, $D3, $3C, $54, $DD, $B4, $B3, $34, $1D, $D5, $2C, $C5, $62, $2D, $CC, $DC, $24, $54, $54, $2D, $DD, $D4, $44, $B3, $44, $DD, $C1, $B0, $55, $5D 
	dc.b	$C3, $A3, $DD, $54, $94, $AC, $1B, $4C, $44, $4C, $E5, $55, $BE, $DD, $46, $58, $C3, $BE, $61, $E4, $C5, $CB, $50, $3A, $4C, $33, $CB, $D5, $64, $29, $8D, $DE 
	dc.b	$44, $DD, $56, $53, $E3, $4C, $44, $9D, $E4, $42, $0A, $45, $3A, $90, $33, $DD, $B4, $21, $DC, $46, $2C, $C4, $3B, $0C, $BB, $04, $B4, $2B, $5C, $D3, $33, $BC 
	dc.b	$B3, $31, $01, $0C, $44, $CC, $82, $2A, $BB, $01, $C9, $43, $01, $44, $51, $A3, $AC, $C4, $3B, $DD, $C4, $AC, $4B, $85, $5C, $BC, $D5, $5C, $CC, $43, $D4, $65 
	dc.b	$DE, $56, $3D, $C5, $3E, $B5, $4D, $E5, $4D, $36, $3E, $45, $33, $00, $DC, $4D, $D5, $9D, $44, $22, $C5, $52, $DD, $4D, $35, $BD, $6C, $DD, $45, $33, $5E, $43 
	dc.b	$DB, $52, $D5, $CD, $D5, $35, $4D, $94, $3B, $B5, $4D, $D8, $34, $AB, $A3, $BB, $6D, $D3, $E4, $55, $4D, $BC, $3B, $C4, $54, $C4, $D2, $2E, $54, $5C, $D5, $B5 
	dc.b	$1E, $45, $8E, $35, $52, $DC, $03, $5D, $4A, $3C, $05, $4A, $D2, $D4, $BD, $6D, $39, $D5, $4D, $2A, $B5, $3D, $9C, $54, $D6, $DB, $3D, $5C, $83, $D5, $43, $0A 
	dc.b	$D2, $BC, $6D, $B3, $D5, $32, $3C, $D5, $3D, $5C, $25, $D4, $BC, $5B, $BC, $A5, $D4, $BC, $B5, $3E, $6C, $43, $D5, $AA, $1D, $43, $39, $D4, $BC, $55, $DD, $B9 
	dc.b	$50, $25, $D3, $90, $5D, $3B, $CC, $3B, $26, $D0, $B9, $5B, $4C, $C5, $B3, $D3, $B9, $3D, $5A, $29, $06, $E2, $3D, $91, $5C, $C0, $A5, $4D, $29, $A5, $5D, $C3 
	dc.b	$0B, $13, $DC, $5C, $D5, $5D, $35, $4B, $D4, $CD, $5A, $C3, $C4, $33, $3D, $36, $DC, $4D, $C4, $35, $CA, $9D, $4A, $94, $C5, $AC, $5A, $D4, $BD, $42, $A5, $B0 
	dc.b	$AC, $42, $05, $8C, $DA, $3C, $14, $1C, $0A, $44, $D5, $4A, $CC, $5C, $CA, $B3, $D5, $3C, $31, $9C, $45, $5C, $BD, $33, $CC, $54, $C5, $3C, $B3, $DC, $B4, $A3 
	dc.b	$4D, $54, $C5, $E5, $54, $0D, $E5, $21, $4E, $55, $9C, $D4, $53, $3C, $E6, $D4, $3D, $35, $C3, $C1, $45, $BD, $D4, $53, $DD, $46, $E4, $CB, $55, $DD, $25, $5D 
	dc.b	$DD, $55, $B3, $D4, $6D, $CD, $45, $2B, $DD, $35, $9D, $D5, $4B, $C4, $53, $5D, $D4, $53, $BE, $A5, $44, $CE, $45, $4D, $DC, $46, $DD, $C4, $56, $DD, $D5, $5A 
	dc.b	$CC, $43, $CC, $C4, $55, $DC, $44, $CD, $D5, $54, $DC, $51, $A4, $DC, $43, $93, $D9, $54, $DE, $55, $5B, $DD, $55, $AD, $C5, $59, $D3, $45, $BB, $DB, $44, $1D 
	dc.b	$9C, $03, $DB, $35, $5C, $C5, $55, $DE, $95, $4C, $DC, $45, $4D, $D4, $52, $1D, $C5, $4C, $DB, $55, $3D, $D4, $54, $CE, $35, $4B, $DC, $45, $2A, $AC, $54, $BD 
	dc.b	$C5, $3C, $D2, $55, $CD, $45, $4C, $DD, $35, $4D, $E3, $55, $AD, $C4, $6D, $C9, $45, $BD, $D5, $54, $CD, $D5, $B2, $4D, $44, $5D, $DC, $46, $DD, $D5, $49, $D2 
	dc.b	$56, $DD, $D4, $54, $CE, $45, $4D, $DD, $55, $5C, $DD, $56, $BD, $D4, $51, $BC, $B5, $4D, $DA, $54, $DD, $34, $53, $DB, $55, $CD, $D2, $55, $BE, $45, $5C, $DD 
	dc.b	$35, $3D, $36, $DD, $4D, $35, $4D, $DD, $56, $CD, $C5, $54, $DE, $45, $5C, $DD, $36, $AD, $CB, $69, $DA, $85, $5B, $EA, $62, $DD, $D5, $55, $DD, $C5, $5B, $DC 
	dc.b	$55, $4D, $B4, $43, $DD, $C5, $4D, $C2, $55, $DD, $A4, $5A, $DD, $46, $BD, $D3, $56, $DD, $D4, $6C, $DD, $45, $4C, $DC, $55, $CD, $D4, $55, $CE, $55, $5C, $DD 
	dc.b	$55, $BD, $D5, $54, $DD, $45, $1D, $D3, $55, $CE, $45, $5B, $DD, $15, $5A, $DD, $45, $5D, $D3, $55, $DD, $D4, $6D, $DC, $46, $BD, $D4, $55, $DD, $D4, $6C, $DB 
	dc.b	$55, $CD, $D4, $55, $BD, $C5, $5B, $DD, $45, $5D, $DC, $55, $DC, $A5, $5B, $DD, $45, $8D, $D5, $5B, $CD, $35, $5C, $DD, $56, $CD, $D5, $54, $DD, $C4, $6C, $DD 
	dc.b	$45, $4D, $DB, $55, $CD, $25, $5C, $DD, $26, $AD, $A5, $53, $DE, $45, $5D, $DB, $55, $2D, $DC, $36, $BD, $D5, $6D, $DD, $45, $5D, $D9, $55, $CD, $34, $3D, $CC 
	dc.b	$56, $2E, $C5, $52, $DD, $B4, $5B, $DD, $56, $CD, $D4, $55, $CE, $45, $4A, $DD, $35, $5B, $DC, $56, $DD, $D4, $5C, $C9, $36, $DD, $D4, $6C, $DD, $45, $5D, $DC 
	dc.b	$56, $DD, $D5, $55, $DE, $45, $5C, $DD, $45, $5D, $DC, $55, $2E, $45, $5C, $DB, $25, $1D, $C4, $53, $CE, $45, $5B, $DD, $55, $BD, $D5, $55, $CD, $D4, $6C, $DD 
	dc.b	$45, $5C, $EA, $55, $AD, $D4, $55, $CD, $C5, $5C, $DC, $55, $3D, $D3, $6D, $DD, $55, $4D, $D4, $55, $DD, $C5, $50, $DD, $15, $6D, $E3, $55, $CD, $D4, $55, $DD 
	dc.b	$B5, $5C, $DC, $55, $2D, $D0, $54, $DD, $45, $5C, $DC, $55, $AD, $C4, $53, $DD, $95, $5C, $DC, $55, $3D, $D1, $55, $CD, $D4, $54, $DD, $45, $3C, $D9, $55, $CE 
	dc.b	$54, $5B, $DD, $25, $5D, $D4, $55, $DD, $C4, $6C, $DD, $45, $4D, $D1, $55, $CD, $D5, $5A, $DD, $45, $5B, $DC, $55, $CD, $C4, $53, $DD, $45, $3D, $D5, $54, $DD 
	dc.b	$B5, $5B, $DD, $45, $4D, $D9, $55, $9D, $D5, $54, $CD, $D4, $6C, $DB, $54, $1D, $DA, $55, $DD, $25, $5C, $DD, $45, $5D, $D4, $53, $DD, $B4, $5A, $DB, $55, $AD 
	dc.b	$D3, $55, $CE, $45, $5C, $DD, $55, $2D, $D4, $55, $DD, $05, $42, $DD, $25, $5D, $D2, $55, $CD, $C5, $5C, $DC, $55, $3D, $D9, $55, $DD, $95, $5A, $DD, $54, $2D 
	dc.b	$CC, $46, $CD, $B5, $51, $DD, $54, $4D, $DD, $55, $CD, $35, $43, $DD, $15, $4D, $C0, $55, $DC, $24, $53, $DD, $32, $00 
LoadDAC_SampleToZ80_Data_Entry_9CF28:
	incbin "data/sound/dac/dac_sample_9cf28.bin"
LoadDAC_SampleToZ80_Data_Entry_9E9D8 equ LoadDAC_SampleToZ80_Data_Entry_9CF28+$1AB0
LoadDAC_SampleToZ80_Data_Entry_9EC38:
	incbin "data/sound/dac/dac_sample_9ec38.bin"
LoadDAC_SampleToZ80_Data_Entry_9FD86 equ LoadDAC_SampleToZ80_Data_Entry_9EC38+$114E
LoadDAC_SampleToZ80_Data_Entry_9FF7E:	
	dc.b	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
	dc.b	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF 
EndOfRom:
	END