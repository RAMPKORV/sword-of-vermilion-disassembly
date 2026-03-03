; ===========================================================================
; Battle & Enemy Data
; Sine table, battle sprite tables, DMA commands, enemy sprite frames, encounter tables, enemy stat definitions, enemy sprite sets
; ===========================================================================
	dc.l	$00FCF9F6	
	dc.l	$F3F0EDEA	
	dc.l	$E7E3E0DD	
	dc.l	$DAD7D4D1	
	dc.l	$CFCCC9C6	
	dc.l	$C3C0BEBB	
	dc.l	$B8B6B3B1	
	dc.l	$AEACAAA7	
	dc.l	$A5A3A19F	
	dc.l	$9D9B9997	
	dc.l	$95939290	
	dc.l	$8F8D8C8A	
	dc.l	$89888786	
	dc.l	$85848383	
	dc.l	$82818180	
	dc.l	$80808080	
	dc.l	$80808080	
	dc.l	$80808181	
	dc.l	$82838384	
	dc.l	$85868788	
	dc.l	$898A8C8D	
	dc.l	$8F909293	
	dc.l	$9597999B	
	dc.l	$9D9FA1A3	
	dc.l	$A5A7AAAC	
	dc.l	$AEB1B3B6	
	dc.l	$B8BBBEC0	
	dc.l	$C3C6C9CC	
	dc.l	$CFD1D4D7	
	dc.l	$DADDE0E3	
	dc.l	$E7EAEDF0	
	dc.l	$F3F6F9FC	
; SineTable
; Sine/Cosine lookup table (256 entries, values -128 to +127)
; Sine values: SineTable[angle]
; Cosine values: SineTable[angle + 64] (90 degree phase shift)
; Angle is in units of 256/360 = 1.40625 degrees per unit
SineTable:
	dc.b	$00, $03, $06, $09, $0C, $0F, $12, $15, $18, $1C, $1F, $22, $25, $28, $2B, $2E, $30, $33, $36, $39, $3C, $3F, $41, $44, $47, $49, $4C, $4E, $51, $53, $55, $58
	dc.b	$5A, $5C, $5E, $60, $62, $64, $66, $68, $6A, $6C, $6D, $6F, $70, $72, $73, $75, $76, $77, $78, $79, $7A, $7B, $7C, $7C, $7D, $7E, $7E, $7F, $7F, $7F, $7F, $7F 
	dc.b	$7F, $7F, $7F, $7F, $7F, $7F, $7E, $7E, $7D, $7C, $7C, $7B, $7A, $79, $78, $77, $76, $75, $73, $72, $70, $6F, $6D, $6C, $6A, $68, $66, $64, $62, $60, $5E, $5C 
	dc.b	$5A, $58, $55, $53, $51, $4E, $4C, $49, $47, $44, $41, $3F, $3C, $39, $36, $33, $30, $2E, $2B, $28, $25, $22, $1F, $1C, $18, $15, $12, $0F, $0C, $09, $06, $03 
	dc.b	$00, $FC, $F9, $F6, $F3, $F0, $ED, $EA, $E7, $E3, $E0, $DD, $DA, $D7, $D4, $D1, $CF, $CC, $C9, $C6, $C3, $C0, $BE, $BB, $B8, $B6, $B3, $B1, $AE, $AC, $AA, $A7 
	dc.b	$A5, $A3, $A1, $9F, $9D, $9B, $99, $97, $95, $93, $92, $90, $8F, $8D, $8C, $8A, $89, $88, $87, $86, $85, $84, $83, $83, $82, $81, $81, $80, $80, $80, $80, $80 
	dc.b	$80, $80, $80, $80, $80, $80, $81, $81, $82, $83, $83, $84, $85, $86, $87, $88, $89, $8A, $8C, $8D, $8F, $90, $92, $93, $95, $97, $99, $9B, $9D, $9F, $A1, $A3 
	dc.b	$A5, $A7, $AA, $AC, $AE, $B1, $B3, $B6, $B8, $BB, $BE, $C0, $C3, $C6, $C9, $CC, $CF, $D1, $D4, $D7, $DA, $DD, $E0, $E3, $E7, $EA, $ED, $F0, $F3, $F6, $F9, $FC 
	dc.b	$00, $03, $06, $09, $0C, $0F, $12, $15, $18, $1C, $1F, $22, $25, $28, $2B, $2E, $30, $33, $36, $39, $3C, $3F, $41, $44, $47, $49, $4C, $4E, $51, $53, $55, $58 
	dc.b	$5A, $5C, $5E, $60, $62, $64, $66, $68, $6A, $6C, $6D, $6F, $70, $72, $73, $75, $76, $77, $78, $79, $7A, $7B, $7C, $7C, $7D, $7E, $7E, $7F, $7F, $7F, $7F, $7F 
	dc.b	$7F, $7F, $7F, $7F, $7F, $7F, $7E, $7E, $7D, $7C, $7C, $7B, $7A, $79, $78, $77, $76, $75, $73, $72, $70, $6F, $6D, $6C, $6A, $68, $66, $64, $62, $60, $5E, $5C 
	dc.b	$5A, $58, $55, $53, $51, $4E, $4C, $49, $47, $44, $41, $3F, $3C, $39, $36, $33, $30, $2E, $2B, $28, $25, $22, $1F, $1C, $18, $15, $12, $0F, $0C, $09, $06, $03 
; loc_000228FE
BattleSpriteIndexTableA:
	dc.w	$0
	dc.w	$4
	dc.w	$4 
	dc.w	$2
	dc.w	$1
	dc.w	$3
	dc.w	$3 
	dc.w	$6
	dc.w	$7
	dc.w	$5
	dc.w	$5
	dc.w	$5
	dc.w	$5
	dc.w	$5
	dc.w	$5 
; loc_0002291C
BattleSpriteIndexTableB:
	dc.w	$0
	dc.w	$4
	dc.w	$4 
	dc.w	$2
	dc.w	$0
	dc.w	$4
	dc.w	$4 
	dc.w	$6
	dc.w	$0
	dc.w	$4
	dc.w	$5
	dc.w	$5
	dc.w	$5
	dc.w	$5
	dc.w	$5 
; loc_0002293A
BattleSpriteDMACommands:
	dc.b	$94, $04, $93, $80, $96, $D0, $95, $00, $97, $7F, $43, $20, $00, $80, $00, $00, $94, $03, $93, $00, $96, $D0, $95, $00, $97, $7F, $4C, $20, $00, $80, $00, $00 
	dc.b	$94, $03, $93, $C0, $96, $D0, $95, $00, $97, $7F, $52, $20, $00, $80, $00, $00, $94, $03, $93, $C0, $96, $D0, $95, $00, $97, $7F, $59, $A0, $00, $80, $00, $00 
	dc.b	$94, $04, $93, $80, $96, $D0, $95, $00, $97, $7F, $61, $20, $00, $80, $00, $00, $94, $03, $93, $00, $96, $D0, $95, $00, $97, $7F, $6A, $20, $00, $80, $00, $00 
	dc.b	$94, $05, $93, $40, $96, $D0, $95, $00, $97, $7F, $70, $20, $00, $80, $00, $00, $94, $03, $93, $00, $96, $D0, $95, $00, $97, $7F, $7A, $A0, $00, $80, $00, $00 
	dc.b	$94, $03, $93, $C0, $96, $D0, $95, $00, $97, $7F, $40, $A0, $00, $81, $00, $00, $94, $03, $93, $C0, $96, $D0, $95, $00, $97, $7F, $48, $20, $00, $81, $00, $00 
	dc.b	$94, $01, $93, $80, $96, $D0, $95, $00, $97, $7F, $40, $A0, $00, $81, $00, $00, $94, $01, $93, $80, $96, $D0, $95, $00, $97, $7F, $43, $A0, $00, $81, $00, $00 
	dc.b	$94, $03, $93, $60, $96, $D0, $95, $00, $97, $7F, $4F, $A0, $00, $81, $00, $00, $94, $00, $93, $40, $96, $D0, $95, $00, $97, $7F, $50, $60, $00, $82, $00, $00 
	dc.b	$94, $00, $93, $80, $96, $D0, $95, $00, $97, $7F, $50, $E0, $00, $82, $00, $00, $94, $00, $93, $00, $96, $D0, $95, $00, $97, $7F, $40, $00, $00, $80, $00, $00 
	dc.b	$94, $04, $93, $80, $96, $D0, $95, $00, $97, $7F, $42, $00, $00, $80, $00, $00, $94, $03, $93, $00, $96, $D0, $95, $00, $97, $7F, $4B, $00, $00, $80, $00, $00 
	dc.b	$94, $00, $93, $C0, $96, $D0, $95, $00, $97, $7F, $51, $00, $00, $80, $00, $00, $94, $04, $93, $80, $96, $D0, $95, $00, $97, $7F, $52, $80, $00, $80, $00, $00 
	dc.b	$94, $03, $93, $00, $96, $D0, $95, $00, $97, $7F, $5B, $80, $00, $80, $00, $00, $94, $00, $93, $C0, $96, $D0, $95, $00, $97, $7F, $61, $80, $00, $80, $00, $00 
	dc.b	$94, $04, $93, $80, $96, $D0, $95, $00, $97, $7F, $73, $80, $00, $80, $00, $00, $94, $03, $93, $00, $96, $D0, $95, $00, $97, $7F, $7C, $80, $00, $80, $00, $00 
	dc.b	$94, $00, $93, $C0, $96, $D0, $95, $00, $97, $7F, $42, $80, $00, $81, $00, $00, $94, $04, $93, $80, $96, $D0, $95, $00, $97, $7F, $63, $00, $00, $80, $00, $00 
	dc.b	$94, $03, $93, $00, $96, $D0, $95, $00, $97, $7F, $6C, $00, $00, $80, $00, $00, $94, $00, $93, $C0, $96, $D0, $95, $00, $97, $7F, $72, $00, $00, $80, $00, $00 
	dc.b	$94, $04, $93, $80, $96, $D0, $95, $00, $97, $7F, $42, $00, $00, $80, $00, $00, $94, $03, $93, $00, $96, $D0, $95, $00, $97, $7F, $4B, $00, $00, $80, $00, $00 
	dc.b	$94, $00, $93, $C0, $96, $D0, $95, $00, $97, $7F, $51, $00, $00, $80, $00, $00, $94, $04, $93, $80, $96, $D0, $95, $00, $97, $7F, $52, $80, $00, $80, $00, $00 
	dc.b	$94, $03, $93, $00, $96, $D0, $95, $00, $97, $7F, $5B, $80, $00, $80, $00, $00, $94, $00, $93, $C0, $96, $D0, $95, $00, $97, $7F, $61, $80, $00, $80, $00, $00 
	dc.b	$94, $04, $93, $80, $96, $D0, $95, $00, $97, $7F, $63, $00, $00, $80, $00, $00, $94, $03, $93, $00, $96, $D0, $95, $00, $97, $7F, $6C, $00, $00, $80, $00, $00 
	dc.b	$94, $00, $93, $C0, $96, $D0, $95, $00, $97, $7F, $72, $00, $00, $80, $00, $00, $94, $04, $93, $80, $96, $D0, $95, $00, $97, $7F, $73, $80, $00, $80, $00, $00 
	dc.b	$94, $03, $93, $00, $96, $D0, $95, $00, $97, $7F, $7C, $80, $00, $80, $00, $00, $94, $00, $93, $C0, $96, $D0, $95, $00, $97, $7F, $42, $80, $00, $81, $00, $00 
	dc.b	$94, $00, $93, $00, $96, $D0, $95, $00, $97, $7F, $40, $00, $00, $80, $00, $00, $94, $00, $93, $00, $96, $D0, $95, $00, $97, $7F, $40, $00, $00, $80, $00, $00 
	dc.b	$94, $03, $93, $C0, $96, $D0, $95, $00, $97, $7F, $46, $A0, $00, $81, $00, $00, $94, $03, $93, $C0, $96, $D0, $95, $00, $97, $7F, $7A, $A0, $00, $80, $00, $00 
	dc.b	$94, $03, $93, $C0, $96, $D0, $95, $00, $97, $7F, $42, $20, $00, $81, $00, $00, $94, $00, $93, $C0, $96, $D0, $95, $00, $97, $7F, $49, $A0, $00, $81, $00, $00 
	dc.b	$94, $03, $93, $00, $96, $D0, $95, $00, $97, $7F, $4B, $20, $00, $81, $00, $00, $94, $03, $93, $00, $96, $D0, $95, $00, $97, $7F, $51, $20, $00, $81, $00, $00 
	dc.b	$94, $01, $93, $80, $96, $D0, $95, $00, $97, $7F, $46, $A0, $00, $81, $00, $00, $94, $01, $93, $80, $96, $D0, $95, $00, $97, $7F, $49, $A0, $00, $81, $00, $00 
	dc.b	$94, $01, $93, $80, $96, $D0, $95, $00, $97, $7F, $4C, $A0, $00, $81, $00, $00, $94, $01, $93, $80, $96, $D0, $95, $00, $97, $7F, $4F, $A0, $00, $81, $00, $00 
	dc.b	$94, $01, $93, $80, $96, $D0, $95, $00, $97, $7F, $52, $A0, $00, $81, $00, $00, $94, $0C, $93, $00, $96, $D0, $95, $00, $97, $7F, $5B, $20, $00, $80, $00, $00 
	dc.b	$94, $0C, $93, $00, $96, $D0, $95, $00, $97, $7F, $43, $20, $00, $80, $00, $00, $94, $0B, $93, $D0, $96, $D0, $95, $00, $97, $7F, $44, $20, $00, $80, $00, $00 
	dc.b	$94, $01, $93, $80, $96, $D0, $95, $00, $97, $7F, $5B, $C0, $00, $80, $00, $00, $94, $00, $93, $C0, $96, $D0, $95, $00, $97, $7F, $5E, $C0, $00, $80, $00, $00 
	dc.b	$94, $00, $93, $60, $96, $D0, $95, $00, $97, $7F, $60, $40, $00, $80, $00, $00, $94, $03, $93, $00, $96, $D0, $95, $00, $97, $7F, $61, $00, $00, $80, $00, $00 
	dc.b	$94, $05, $93, $00, $96, $D0, $95, $00, $97, $7F, $73, $20, $00, $80, $00, $00, $94, $09, $93, $00, $96, $D0, $95, $00, $97, $7F, $44, $20, $00, $80, $00, $00 
	dc.b	$94, $04, $93, $40, $96, $D0, $95, $00, $97, $7F, $56, $20, $00, $80, $00, $00, $94, $07, $93, $E0, $96, $D0, $95, $00, $97, $7F, $5E, $A0, $00, $80, $00, $00 
	dc.b	$94, $03, $93, $00, $96, $D0, $95, $00, $97, $7F, $6E, $60, $00, $80, $00, $00, $94, $05, $93, $00, $96, $D0, $95, $00, $97, $7F, $7D, $20, $00, $80, $00, $00 
	dc.b	$94, $00, $93, $C0, $96, $D0, $95, $00, $97, $7F, $47, $20, $00, $81, $00, $00, $94, $0B, $93, $A0, $96, $D0, $95, $00, $97, $7F, $48, $A0, $00, $81, $00, $00 
	dc.b	$94, $01, $93, $80, $96, $D0, $95, $00, $97, $7F, $57, $20, $00, $81, $00, $00, $94, $0D, $93, $80, $96, $D0, $95, $00, $97, $7F, $44, $20, $00, $80, $00, $00 
	dc.b	$94, $09, $93, $00, $96, $D0, $95, $00, $97, $7F, $5F, $20, $00, $80, $00, $00, $94, $01, $93, $C0, $96, $D0, $95, $00, $97, $7F, $71, $20, $00, $80, $00, $00 
	dc.b	$94, $00, $93, $F0, $96, $D0, $95, $00, $97, $7F, $74, $A0, $00, $80, $00, $00, $94, $00, $93, $C0, $96, $D0, $95, $00, $97, $7F, $76, $80, $00, $80, $00, $00 
	dc.b	$94, $01, $93, $40, $96, $D0, $95, $00, $97, $7F, $78, $00, $00, $80, $00, $00, $94, $00, $93, $A0, $96, $D0, $95, $00, $97, $7F, $7A, $80, $00, $80, $00, $00 
	dc.b	$94, $0A, $93, $00, $96, $D0, $95, $00, $97, $7F, $44, $20, $00, $80, $00, $00, $94, $03, $93, $60, $96, $D0, $95, $00, $97, $7F, $58, $20, $00, $80, $00, $00 
	dc.b	$94, $01, $93, $E0, $96, $D0, $95, $00, $97, $7F, $5E, $E0, $00, $80, $00, $00, $94, $00, $93, $C0, $96, $D0, $95, $00, $97, $7F, $62, $A0, $00, $80, $00, $00 
	dc.b	$94, $00, $93, $20, $96, $D0, $95, $00, $97, $7F, $64, $20, $00, $80, $00, $00, $94, $0D, $93, $00, $96, $D0, $95, $00, $97, $7F, $44, $20, $00, $80, $00, $00 
	dc.b	$94, $0C, $93, $00, $96, $D0, $95, $00, $97, $7F, $5E, $20, $00, $80, $00, $00, $94, $09, $93, $00, $96, $D0, $95, $00, $97, $7F, $76, $20, $00, $80, $00, $00 
	dc.b	$94, $06, $93, $C0, $96, $D0, $95, $00, $97, $7F, $48, $20, $00, $81, $00, $00, $94, $00, $93, $30, $96, $D0, $95, $00, $97, $7F, $55, $A0, $00, $81, $00, $00 
	dc.b	$94, $01, $93, $C0, $96, $D0, $95, $00, $97, $7F, $56, $00, $00, $81, $00, $00, $94, $0B, $93, $00, $96, $D0, $95, $00, $97, $7F, $44, $20, $00, $80, $00, $00 
	dc.b	$94, $05, $93, $10, $96, $D0, $95, $00, $97, $7F, $5A, $20, $00, $80, $00, $00 
; loc_00022ECA
EnemySpriteFrameDataA_00:
	dc.b	$0A, $0A, $00, $21, $04, $14, $01, $02, $0A, $0A, $00, $2A, $0A, $0A, $00, $33, $0A, $0A, $00, $3C, $05, $0A, $00, $F6 
; loc_00022EE2
EnemySpriteFrameDataA_01:
	dc.b	$00, $45, $01, $06, $00, $4E, $00, $57, $00, $60, $00, $F6 
; loc_00022EEE
EnemySpriteFrameDataA_02:
	dc.b	$00, $69, $01, $06, $00, $72, $00, $7B, $00, $84, $00, $F6 
; loc_00022EFA
EnemySpriteFrameDataA_03:
	dc.b	$0A, $09, $00, $8D, $0A, $09, $00, $96, $0A, $09, $00, $9F 
; loc_00022F06
EnemySpriteFrameDataA_04:
	dc.b	$00, $A8, $00, $B1, $00, $BA 
; loc_00022F0C
EnemySpriteFrameDataA_05:
	dc.b	$00, $C3, $00, $CC, $00, $D5 
; loc_00022F12
EnemySpriteFrameDataA_06:
	dc.b	$05, $C8, $00, $FE, $05, $C8, $00, $FA, $0E, $C8, $01, $2C 
; loc_00022F1E
EnemySpriteFrameDataA_07:
	dc.b	$00, $F0, $00, $A0, $00, $F0, $00, $90, $00, $E8, $00, $B8 
; loc_00022F2A
EnemySpriteFrameDataA_08:
	dc.b	$0E, $08, $01, $08, $0D, $08, $00, $DE 
; loc_00022F32
EnemySpriteFrameDataA_09:
	dc.b	$0E, $07, $01, $08, $0D, $07, $00, $DE 
; loc_00022F3A
EnemySpriteFrameDataA_0A:
	dc.b	$0E, $06, $01, $08, $0D, $06, $00, $DE 
; loc_00022F42
EnemySpriteFrameDataA_0B:
	dc.b	$01, $14, $00, $E6 
; loc_00022F46
EnemySpriteFrameDataA_0C:
	dc.b	$01, $20, $00, $EE 
; loc_00022F4A
EnemySpriteFrameDataA_0D:
	dc.b	$00, $00, $FF, $E8 
; loc_00022F4E
EnemySpriteFrameDataA_0E:
	dc.b	$00, $00, $FF, $E8 
; loc_00022F52
EnemySpriteFrameDataA_0F:
	dc.b	$00, $00, $FF, $E8 
; loc_00022F56
EnemySpriteFrameDataA_10:
	dc.b	$00, $24, $FF, $F4, $00, $18, $00, $00, $00, $30, $FF, $F0, $00, $30, $00, $08, $00, $44, $FF, $F8 
; loc_00022F6A
EnemySpriteFrameDataA_11:
	dc.b	$00, $18, $00, $00, $00, $30, $FF, $FA 
; loc_00022F72
EnemySpriteFrameDataA_12:
	dc.b	$01, $06, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $04, $01, $06 
; loc_00022F82
EnemySpriteLayoutPtrsA:
	dc.l	EnemySpriteLayoutA_Frame0
	dc.l	EnemySpriteLayoutA_Frame1
	dc.l	EnemySpriteLayoutA_Frame2
	dc.l	EnemySpriteLayoutA_Frame3
; loc_00022F92
EnemySpritePositionPtrsA:
	dc.l	EnemySpritePositionA_Frame0
	dc.l	EnemySpritePositionA_Frame1
	dc.l	EnemySpritePositionA_Frame23
	dc.l	EnemySpritePositionA_Frame23
; loc_00022FA2
EnemySpriteLayoutA_Frame0:
	dc.l	$0B0A0045	
	dc.l	$0B0A0099	
	dc.l	$050A00B5	
	dc.l	$050A00C5	
; loc_00022FB2
EnemySpriteLayoutA_Frame1:
	dc.l	$0B0A0045	
	dc.l	$0B0A008D	
	dc.l	$050A00B1	
	dc.l	$050A00C1	
; loc_00022FC2
EnemySpriteLayoutA_Frame2:
	dc.l	$0B0A0045	
	dc.l	$0A0A012B	
	dc.l	$0A0A0122	
	dc.l	$050A00BD	
; loc_00022FD2
EnemySpriteLayoutA_Frame3:
	dc.l	$0B0A0051	
	dc.l	$0A0A013D	
	dc.l	$0A0A0134	
	dc.l	$050A00BD	
; loc_00022FE2
EnemySpritePositionA_Frame0:
	dc.l	$00CD008A	
	dc.l	$00BD009E	
	dc.l	$00B900AE	
	dc.l	$00D1008E	
; loc_00022FF2
EnemySpritePositionA_Frame1:
	dc.l	$00CD008A	
	dc.l	$00BD009E	
	dc.l	$00B900AE	
	dc.l	$00D1008E	
; loc_00023002
EnemySpritePositionA_Frame23:
	dc.l	$00CD008A	
	dc.l	$00BD0096	
	dc.l	$00A50096	
	dc.l	$00D1008E	
; loc_00023012
EnemySpriteLayoutPtrsB:
	dc.l	EnemySpriteLayoutB_Frame0
	dc.l	EnemySpriteLayoutB_Frame1
	dc.l	EnemySpriteLayoutB_Frame2
	dc.l	EnemySpriteLayoutB_Frame3
; loc_00023022
EnemySpritePositionPtrsB:
	dc.l	EnemySpritePositionB_Frame0
	dc.l	EnemySpritePositionB_Frame1
	dc.l	EnemySpritePositionB_Frame23
	dc.l	EnemySpritePositionB_Frame23
; loc_00023032
EnemySpriteLayoutB_Frame0:
	dc.l	$0B280021	
	dc.l	$0B280069	
	dc.l	$052800B9	
	dc.l	$052800F1	
; loc_00023042
EnemySpriteLayoutB_Frame1:
	dc.l	$0B28002D	
	dc.l	$0B2800A5	
	dc.l	$0A280146	
	dc.l	$052800F1	
; loc_00023052
EnemySpriteLayoutB_Frame2:
	dc.l	$0B280039	
	dc.l	$0B280081	
	dc.l	$0A280110	
	dc.l	$052800C9	
; loc_00023062
EnemySpriteLayoutB_Frame3:
	dc.l	$0B28005D	
	dc.l	$0B280075	
	dc.l	$0A280119	
	dc.l	$052800ED	
; loc_00023072
EnemySpritePositionB_Frame0:
	dc.l	$01050082	
	dc.l	$010700A2	
	dc.l	$010300B2	
	dc.l	loc_00000000	
; loc_00023082
EnemySpritePositionB_Frame1:
	dc.l	$01050082	
	dc.l	$010A00A2	
	dc.l	$010200B2	
	dc.l	loc_00000000	
; loc_00023092
EnemySpritePositionB_Frame23:
	dc.l	$01050082	
	dc.l	$010800A2	
	dc.l	$00F800B2	
	dc.l	$00F4009A	
; loc_000230A2
BossSpriteLayoutData_A:
	dc.l	$0E140173	
	dc.l	$051400E5	
	dc.l	$051400E9	
; loc_000230AE
BossSpriteLayoutData_B:
	dc.l	$018B017F	
	dc.l	$0173017F	
; loc_000230B6
BossSpriteLayoutData_C:
	dc.l	$0A1E00F5	
	dc.l	$0E1E0197	
; loc_000230BE
BossSpriteLayoutData_D:
	dc.l	$00F500FE	
	dc.l	$010700FE	
; loc_000230C6
BossSpriteLayoutData_E:
	dc.l	$00CD00D1	
	dc.l	$00D500D9	
	dc.l	$00DD00D9	
	dc.l	$00D500D1	
; loc_000230D6
BossSpriteLayoutData_F:
	dc.l	$014F0158	
; loc_000230DA
EncounterSpriteDescTable:
	dc.l	EncounterSpriteList_00A
	dc.b	$FF, $E8, $FF, $A8 
	dc.w	$000C
	dc.l	EncounterSpriteList_00B
	dc.b	$FF, $E8, $FF, $A8 
	dc.w	$000C
	dc.l	EncounterSpriteList_00C
	dc.b	$FF, $E8, $FF, $A8 
	dc.w	$000C
	dc.l	EncounterSpriteList_01A
	dc.b	$00, $00, $FF, $C0 
	dc.w	$0000
	dc.l	EncounterSpriteList_02A
	dc.b	$FF, $E8, $FF, $90 
	dc.w	$FFDC
	dc.l	EncounterSpriteList_03A
	dc.b	$FF, $E8, $FF, $90 
	dc.w	$FFDC
	dc.l	EncounterSpriteList_03B
	dc.b	$FF, $F0, $FF, $90 
	dc.w	$FFDC
	dc.l	EncounterSpriteList_04A
	dc.b	$FF, $E8, $FF, $90 
	dc.w	$FFDC
	dc.l	EncounterSpriteList_04B
	dc.b	$00, $10, $FF, $88 
	dc.w	$0024
	dc.l	EncounterSpriteList_05A
	dc.b	$00, $10, $FF, $88 
	dc.w	$0024
	dc.l	EncounterSpriteList_05B
	dc.b	$00, $08, $FF, $88 
	dc.w	$0024
	dc.l	EncounterSpriteList_06A
	dc.b	$00, $10, $FF, $88 
	dc.w	$0024
	dc.l	EncounterSpriteList_07A
	dc.b	$00, $00, $FF, $AD 
	dc.w	$FFF4
	dc.l	EncounterSpriteList_07B
	dc.b	$00, $00, $FF, $AD 
	dc.w	$FFF4
	dc.l	EncounterSpriteList_08A
	dc.b	$00, $10, $FF, $B0 
	dc.w	$0018
	dc.l	EncounterSpriteList_08B
	dc.b	$00, $10, $FF, $B0 
	dc.w	$0018
; loc_0002317A
EncounterSpriteList_00A:
	dc.w	$0119
	dc.b	$0F, $00, $FF, $FC, $FF, $F8 
	dc.w	$01B1
	dc.b	$08, $01, $FF, $F8, $FF, $D8 
	dc.w	$01BE
	dc.b	$04, $02, $00, $0C, $FF, $D8 
	dc.w	$01CA
	dc.b	$01, $03, $00, $10, $FF, $E8 
	dc.w	$01DD
	dc.b	$00, $04, $FF, $F8, $FF, $F9 
	dc.w	$FFFF
; loc_000231A4
EncounterSpriteList_00B:
	dc.w	$0129
	dc.b	$0F, $00, $FF, $FC, $FF, $F8 
	dc.w	$01B1
	dc.b	$08, $01, $FF, $F8, $FF, $D8 
	dc.w	$01BE
	dc.b	$04, $02, $00, $0C, $FF, $D8 
	dc.w	$01CC
	dc.b	$01, $03, $00, $10, $FF, $E8 
	dc.w	$01DD
	dc.b	$00, $04, $FF, $F8, $FF, $F9 
	dc.w	$FFFF
; loc_000231CE
EncounterSpriteList_00C:
	dc.w	$0139
	dc.b	$0F, $00, $FF, $FC, $FF, $F8 
	dc.w	$01B1
	dc.b	$08, $01, $FF, $F8, $FF, $D8 
	dc.w	$01BE
	dc.b	$04, $02, $00, $0C, $FF, $D8 
	dc.w	$01CE
	dc.b	$01, $03, $00, $10, $FF, $E8 
	dc.w	$01DD
	dc.b	$00, $04, $FF, $F8, $FF, $F9 
	dc.w	$FFFF
; loc_000231F8
EncounterSpriteList_01A:
	dc.w	$00CC
	dc.b	$0A, $00, $00, $08, $FF, $D8 
	dc.w	$00D5
	dc.b	$0A, $01, $FF, $F0, $FF, $F0 
	dc.w	$00DE
	dc.b	$0A, $02, $00, $08, $FF, $F0 
	dc.w	$0195
	dc.b	$05, $03, $FF, $FC, $00, $00 
	dc.w	$0199
	dc.b	$05, $04, $00, $0C, $00, $00 
	dc.w	$01AE
	dc.b	$08, $05, $FF, $F0, $FF, $D8 
	dc.w	$01C8
	dc.b	$01, $06, $00, $18, $FF, $F8 
	dc.w	$01D8
	dc.b	$00, $07, $FF, $F8, $FF, $D0 
	dc.w	$01D9
	dc.b	$00, $08, $00, $18, $FF, $E8
	dc.w	$FFFF 
; loc_00023242
EncounterSpriteList_02A:
	dc.w	$0021
	dc.b	$0A, $FA, $00, $00, $00, $18 
	dc.w	$002A
	dc.b	$0A, $FB, $00, $18, $00, $28 
	dc.w	$0189
	dc.b	$05, $FC, $00, $04, $00, $28 
	dc.w	$01D4
	dc.b	$00, $FD, $00, $10, $00, $10 
	dc.w	$0069
	dc.b	$0A, $FE, $00, $10, $00, $40 
	dc.w	$01C0
	dc.b	$01, $FF, $00, $20, $00, $38 
	dc.w	$00F9
	dc.b	$0F, $00, $00, $04, $00, $58 
	dc.w	$FFFF
; loc_0002327C
EncounterSpriteList_03A:
	dc.w	$0033
	dc.b	$0A, $F8, $00, $00, $00, $18 
	dc.w	$003C
	dc.b	$0A, $F9, $00, $18, $00, $20 
	dc.w	$018D
	dc.b	$05, $FA, $00, $2C, $00, $18 
	dc.w	$01B4
	dc.b	$04, $FB, $00, $2C, $00, $20 
	dc.w	$01D5
	dc.b	$00, $FC, $00, $10, $00, $08 
	dc.w	$01D6
	dc.b	$00, $FD, $00, $08, $00, $20 
	dc.w	$01A5
	dc.b	$08, $FE, $00, $18, $00, $28 
	dc.w	$01DB
	dc.b	$00, $FF, $00, $28, $00, $28 
	dc.w	$007B
	dc.b	$0A, $00, $00, $08, $00, $30
	dc.w	$FFFF 
; loc_000232C6
EncounterSpriteList_03B:
	dc.w	$0057
	dc.b	$0A, $FF, $00, $00, $00, $18 
	dc.w	$0060
	dc.b	$0A, $FE, $FF, $F0, $00, $30 
	dc.w	$01B6
	dc.b	$04, $FD, $FF, $EC, $00, $18 
	dc.w	$01B8
	dc.b	$04, $FC, $00, $04, $00, $20 
	dc.w	$0045
	dc.b	$0A, $FB, $FF, $D0, $00, $28 
	dc.w	$004E
	dc.b	$0A, $FA, $FF, $E8, $00, $30 
	dc.w	$01DA
	dc.b	$00, $F9, $FF, $D8, $00, $30 
	dc.w	$007B
	dc.b	$0A, $00, $FF, $B8, $00, $20 
	dc.w	$FFFF
; loc_00023308
EncounterSpriteList_04A:
	dc.w	$0084
	dc.b	$0A, $FA, $00, $00, $00, $18 
	dc.w	$008D
	dc.b	$0A, $FB, $00, $18, $00, $28 
	dc.w	$01A1
	dc.b	$05, $FC, $00, $0C, $00, $28 
	dc.w	$01D2
	dc.b	$01, $FD, $00, $10, $00, $10 
	dc.w	$00F0
	dc.b	$0A, $FE, $00, $10, $00, $40 
	dc.w	$01D0
	dc.b	$01, $FF, $00, $20, $00, $38 
	dc.w	$0179
	dc.b	$0F, $00, $00, $04, $00, $58 
	dc.w	$FFFF
; loc_00023342
EncounterSpriteList_04B:
	dc.w	$0021
	dc.b	$0A, $00, $00, $00, $00, $18 
	dc.w	$002A
	dc.b	$0A, $01, $00, $18, $00, $28 
	dc.w	$0189
	dc.b	$05, $02, $00, $04, $00, $28 
	dc.w	$01D4
	dc.b	$00, $03, $00, $10, $00, $10 
	dc.w	$0069
	dc.b	$0A, $04, $00, $10, $00, $40 
	dc.w	$01C0
	dc.b	$01, $05, $00, $20, $00, $38 
	dc.w	$0109
	dc.b	$0F, $06, $00, $04, $00, $58 
	dc.w	$FFFF
; loc_0002337C
EncounterSpriteList_05A:
	dc.w	$0033
	dc.b	$0A, $00, $00, $00, $00, $18 
	dc.w	$003C
	dc.b	$0A, $01, $00, $18, $00, $20 
	dc.w	$018D
	dc.b	$05, $02, $00, $2C, $00, $18 
	dc.w	$01B4
	dc.b	$04, $03, $00, $2C, $00, $20 
	dc.w	$01D5
	dc.b	$00, $04, $00, $10, $00, $08 
	dc.w	$01D6
	dc.b	$00, $05, $00, $08, $00, $20 
	dc.w	$01A5
	dc.b	$08, $06, $00, $18, $00, $28 
	dc.w	$01DB
	dc.b	$00, $07, $00, $28, $00, $28 
	dc.w	$0072
	dc.b	$0A, $08, $00, $08, $00, $30
	dc.w	$FFFF 
; loc_000233C6
EncounterSpriteList_05B:
	dc.w	$0057
	dc.b	$0A, $06, $00, $00, $00, $18 
	dc.w	$0060
	dc.b	$0A, $05, $FF, $F0, $00, $30 
	dc.w	$01B6
	dc.b	$04, $04, $FF, $EC, $00, $18 
	dc.w	$01B8
	dc.b	$04, $03, $00, $04, $00, $20 
	dc.w	$0045
	dc.b	$0A, $02, $FF, $D0, $00, $28 
	dc.w	$004E
	dc.b	$0A, $01, $FF, $E8, $00, $30 
	dc.w	$01DA
	dc.b	$00, $00, $FF, $D8, $00, $30 
	dc.w	$0072
	dc.b	$0A, $07, $FF, $B8, $00, $20 
	dc.w	$FFFF
; loc_00023408
EncounterSpriteList_06A:
	dc.w	$0084
	dc.b	$0A, $06, $00, $00, $00, $18 
	dc.w	$008D
	dc.b	$0A, $05, $00, $18, $00, $28 
	dc.w	$01A1
	dc.b	$05, $04, $00, $0C, $00, $28 
	dc.w	$01D2
	dc.b	$01, $03, $00, $10, $00, $10 
	dc.w	$00F0
	dc.b	$0A, $02, $00, $10, $00, $40 
	dc.w	$01D0
	dc.b	$01, $01, $00, $20, $00, $38 
	dc.w	$0179
	dc.b	$0F, $00, $00, $04, $00, $58 
	dc.w	$FFFF
; loc_00023442
EncounterSpriteList_07A:
	dc.w	$0096
	dc.b	$0A, $FC, $00, $00, $00, $18 
	dc.w	$009F
	dc.b	$0A, $FD, $00, $00, $00, $30 
	dc.w	$00A8
	dc.b	$0A, $FE, $00, $00, $00, $48 
	dc.w	$0191
	dc.b	$05, $FF, $FF, $EC, $00, $50 
	dc.w	$01A8
	dc.b	$08, $00, $00, $00, $00, $50 
	dc.w	$FFFF
; loc_0002346C
EncounterSpriteList_07B:
	dc.w	$00B1
	dc.b	$0A, $F7, $00, $00, $00, $18 
	dc.w	$00BA
	dc.b	$0A, $F8, $FF, $F0, $00, $30 
	dc.w	$00C3
	dc.b	$0A, $F9, $00, $00, $00, $48 
	dc.w	$01AB
	dc.b	$08, $FA, $00, $00, $00, $50 
	dc.w	$01BA
	dc.b	$04, $FB, $00, $04, $00, $20 
	dc.w	$01BC
	dc.b	$04, $FC, $FF, $EC, $00, $50 
	dc.w	$01C2
	dc.b	$01, $FD, $FF, $F0, $00, $18 
	dc.w	$01C4
	dc.b	$01, $FE, $00, $00, $00, $30 
	dc.w	$01C6
	dc.b	$01, $FF, $00, $08, $00, $40 
	dc.w	$01D7
	dc.b	$00, $00, $FF, $E8, $00, $38
	dc.w	$FFFF 
; loc_000234BE
EncounterSpriteList_08A:
	dc.w	$0096
	dc.b	$0A, $00, $00, $00, $00, $18 
	dc.w	$009F
	dc.b	$0A, $01, $00, $00, $00, $30 
	dc.w	$00A8
	dc.b	$0A, $02, $00, $00, $00, $48 
	dc.w	$0191
	dc.b	$05, $03, $FF, $EC, $00, $50 
	dc.w	$01A8
	dc.b	$08, $04, $00, $00, $00, $50 
	dc.w	$FFFF
; loc_000234E8
EncounterSpriteList_08B:
	dc.w	$00B1
	dc.b	$0A, $00, $00, $00, $00, $18 
	dc.w	$00BA
	dc.b	$0A, $01, $FF, $F0, $00, $30 
	dc.w	$00C3
	dc.b	$0A, $02, $00, $00, $00, $48 
	dc.w	$01AB
	dc.b	$08, $03, $00, $00, $00, $50 
	dc.w	$01BA
	dc.b	$04, $04, $00, $04, $00, $20 
	dc.w	$01BC
	dc.b	$04, $05, $FF, $EC, $00, $50 
	dc.w	$01C2
	dc.b	$01, $06, $FF, $F0, $00, $18 
	dc.w	$01C4
	dc.b	$01, $07, $00, $00, $00, $30 
	dc.w	$01C6
	dc.b	$01, $08, $00, $08, $00, $40 
	dc.w	$01D7
	dc.b	$00, $09, $FF, $E8, $00, $38
	dc.w	$FFFF 
; loc_0002353A
EncounterSpriteList_Hydra:
	dc.b	$00, $02, $35, $76, $FF, $E4, $FF, $DC 
	dc.w	$FFD8
	dc.b	$00, $02, $35, $76, $FF, $F0, $FF, $B8 
	dc.w	$FFD8
	dc.b	$00, $02, $35, $76, $FF, $AC, $FF, $A8, $FF, $D8, $00, $02, $35, $76, $00, $0C, $FF, $D4, $00, $2C, $00, $02, $35, $76, $00, $18, $FF, $B0 
	dc.w	$002C
	dc.b	$00, $02, $35, $76, $FF, $C4, $FF, $A0, $00, $2C, $01, $9D, $05, $00, $FF, $F8, $00, $10, $00, $E7, $0A, $00, $FF, $F4, $00, $18, $01, $49, $0F, $00, $FF, $F0 
	dc.b	$00, $20, $01, $59, $0F, $00, $FF, $F0, $00, $20, $01, $69, $0F, $00, $FF, $F0, $00, $20, $FF, $FF 
; loc_000235A0
BattleTileDataPtrs:
	dc.l	BossTileData_FakeKing
	dc.l	BossTileData_Watling
	dc.l	BossTileData_StowThief
	dc.l	BossTileData_StowThief
	dc.l	BossTileData_Imposter
	dc.l	BossTileData_Excalabria
	dc.l	BossTileData_Excalabria
	dc.l	BossTileData_Excalabria
	dc.l	BossTileData_FakeKing
	dc.l	BossTileData_FakeKing
	dc.l	BossTileData_Watling
	dc.l	BossTileData_StowThief
	dc.l	BossTileData_Imposter
	dc.l	BossTileData_Tsarkon
; loc_000235D8
BossTileData_FakeKing:
	dc.b	$00, $37 
	dc.l	BossTileData_FakeKing_Gfx_6FCDA
	dc.l	BossTileData_FakeKing_Gfx_70BFA
	dc.l	$00BC0038	
	dc.l	BossTileData_FakeKing_Gfx_70E32
	dc.l	BossTileData_FakeKing_Gfx_7100E
	dc.l	$00170039	
	dc.l	BossTileData_FakeKing_Gfx_7105A
	dc.l	BossTileData_FakeKing_Gfx_7114A
	dc.l	$000B003A	
	dc.l	BossTileData_FakeKing_Gfx_71176
	dc.l	BossTileData_FakeKing_Gfx_71248
	dc.l	BossTileData_FakeKing_Gfx_5003E-3	
	dc.l	BossTileData_FakeKing_Gfx_71260
	dc.l	BossTileData_FakeKing_Gfx_71774
	dc.b	$00, $2F, $FF, $FF 
; loc_00023616
BossTileData_StowThief:
	dc.b	$00, $3D 
	dc.l	BossTileData_StowThief_Gfx_72ABA
	dc.l	BossTileData_StowThief_Gfx_73686
	dc.l	$008F003E	
	dc.l	BossTileData_StowThief_Gfx_73856
	dc.l	BossTileData_StowThief_Gfx_73D82
	dc.l	$0043003F	
	dc.l	BossTileData_StowThief_Gfx_73E52
	dc.l	BossTileData_StowThief_Gfx_748AA
	dc.l	$007D0040	
	dc.l	BossTileData_StowThief_Gfx_74A6A
	dc.l	BossTileData_StowThief_Gfx_74F1E
	dc.b	$00, $2F, $FF, $FF 
; loc_00023648
BossTileData_Watling:
	dc.b	$00, $45 
	dc.l	BossTileData_Watling_Gfx_74FD2
	dc.l	BossTileData_Watling_Gfx_7653A
	dc.l	$00D70046	
	dc.l	BossTileData_Watling_Gfx_76862
	dc.l	BossTileData_Watling_Gfx_77506
	dc.l	$008F0047	
	dc.l	BossTileData_Watling_Gfx_77706
	dc.l	BossTileData_Watling_Gfx_77998
	dc.l	$001B0048	
	dc.l	BossTileData_Watling_Gfx_77A04
	dc.l	BossTileData_Watling_Gfx_77B74
	dc.l	$000E0049	
	dc.l	BossTileData_Watling_Gfx_77BB0
	dc.l	BossTileData_Watling_Gfx_77CCE
	dc.l	$000B004A	
	dc.l	BossTileData_Watling_Gfx_77CFE
	dc.l	BossTileData_Watling_Gfx_77EC4
	dc.l	$0013004B	
	dc.l	BossTileData_Watling_Gfx_77F10
	dc.l	BossTileData_Watling_Gfx_77FAC
	dc.b	$00, $09, $FF, $FF 
; loc_0002369E
BossTileData_Excalabria:
	dc.b	$00, $4C 
	dc.l	BossTileData_Excalabria_Gfx_79462
	dc.l	BossTileData_Excalabria_Gfx_7A182
	dc.l	$009F004D	
	dc.l	BossTileData_Excalabria_Gfx_7A3B6
	dc.l	BossTileData_Excalabria_Gfx_7A7A4
	dc.l	$0035004E	
	dc.l	BossTileData_Excalabria_Gfx_7A854
	dc.l	BossTileData_Excalabria_Gfx_7AA60
	dc.l	$001D004F	
	dc.l	BossTileData_Excalabria_Gfx_7AACC
	dc.l	BossTileData_Excalabria_Gfx_7ABD8
	dc.l	$000B0050	
	dc.l	BossTileData_Excalabria_Gfx_7AC08
	dc.l	BossTileData_Excalabria_Gfx_7AC2C
	dc.l	TownStateDataJumpTableStart_Parma-3	
; loc_000236DC
BossTileData_Imposter:
	dc.b	$00, $51 
	dc.l	BossTileData_Imposter_Gfx_7AC34
	dc.l	BossTileData_Imposter_Gfx_7B9B4
	dc.l	$00CF0052	
	dc.l	BossTileData_Imposter_Gfx_7BBC8
	dc.l	BossTileData_Imposter_Gfx_7C7E0
	dc.l	$00BF0053	
	dc.l	BossTileData_Imposter_Gfx_7C9EC
	dc.l	BossTileData_Imposter_Gfx_7D138
	dc.l	$008F0054	
	dc.l	BossTileData_Imposter_Gfx_7D250
	dc.l	BossTileData_Imposter_Gfx_7D844
	dc.l	$006B0055	
	dc.l	BossTileData_Imposter_Gfx_7D920
	dc.l	BossTileData_Imposter_Gfx_7D960
	dc.l	LoadTownStateData_Parma_Return-2	
	dc.l	BossTileData_Imposter_Gfx_7D96C
	dc.l	BossTileData_Imposter_Gfx_7DB80
	dc.b	$00, $1B, $FF, $FF 
; loc_00023726
BossTileData_Tsarkon:
	dc.b	$00, $57 
	dc.l	BossTileData_Tsarkon_Gfx_7DBF0
	dc.l	BossTileData_Tsarkon_Gfx_7EBF4
	dc.l	$00AF0058	
	dc.l	BossTileData_Tsarkon_Gfx_7EE3C
	dc.l	BossTileData_Tsarkon_Gfx_7F4FC
	dc.l	$0050FFFF	
; loc_00023740
BattleGfxDataPtrs:
	dc.l	BattleGfxData_FakeKing
	dc.l	BattleGfxData_Null
	dc.l	BattleGfxData_StowThief
	dc.l	BattleGfxData_StowThief
	dc.l	BattleGfxData_Null
	dc.l	BattleGfxData_Excalabria
	dc.l	BattleGfxData_Excalabria
	dc.l	BattleGfxData_Excalabria
	dc.l	BattleGfxData_FakeKing
	dc.l	BattleGfxData_FakeKing
	dc.l	BattleGfxData_Null
	dc.l	BattleGfxData_StowThief
	dc.l	BattleGfxData_Null
	dc.l	BattleGfxData_Tsarkon
; loc_00023778
BattleGfxData_FakeKing:
	dc.l	BattleGfxData_FakeKing_Gfx_6E652
	dc.b	$00, $E2 
	dc.l	BattlePaletteData_FakeKing
; loc_00023782
BattleGfxData_StowThief:
	dc.l	BattleGfxData_StowThief_Gfx_7182C
	dc.b	$00, $D1 
	dc.l	BattlePaletteData_StowThief
; loc_0002378C
BattleGfxData_Null:
	dc.l	$00000000
	dc.b	$00, $00, $00, $00, $00, $00 
; loc_00023796
BattleGfxData_Excalabria:
	dc.l	BattleGfxData_Excalabria_Gfx_78138
	dc.b	$00, $C6 
	dc.l	BattlePaletteData_Excalabria
; loc_000237A0
BattleGfxData_Tsarkon:
	dc.l	BattleGfxData_Tsarkon_Gfx_7F77A
	dc.b	$00, $DE 
	dc.l	BattlePaletteData_Tsarkon
; loc_000237AA
BattlePaletteData_FakeKing:
	dc.l	$940E9330	
	dc.l	$96D09500	
	dc.l	$977F4000	
	dc.l	$00810000	
; loc_000237BA
BattlePaletteData_StowThief:
	dc.l	$940D9320	
	dc.l	$96D09500	
	dc.l	$977F4000	
	dc.l	$00810000	
; loc_000237CA
BattlePaletteData_Excalabria:
	dc.l	$940C9370	
	dc.l	$96D09500	
	dc.l	$977F4000	
	dc.l	$00810000	
; loc_000237DA
BattlePaletteData_Tsarkon:
	dc.l	$940D93F0	
	dc.l	$96D09500	
	dc.l	$977F4000	
	dc.l	$00810000	
; loc_000237EA
BattleVDPCmds_EnemySmall:
	dc.l	$00C10AC8	
	dc.l	$00CA0AC8	
	dc.l	$00210FC8	
; loc_000237F6
BattleVDPCmds_EnemyLarge:
	dc.l	$00310FC8	
	dc.l	$00410FC8	
	dc.l	$00510FC8	
; loc_00023802
EncounterEnemySpriteByDirA:
	dc.l	EnemySpriteData_FacingDown
	dc.l	EnemySpriteData_FacingSide
	dc.l	EnemySpriteData_FacingUp
	dc.l	EnemySpriteData_FacingSide
; loc_00023812
EncounterEnemySpriteByDirB:
	dc.l	EnemySpriteDataB_FacingDown
	dc.l	EnemySpriteDataB_FacingSide
	dc.l	EnemySpriteDataB_FacingUp
	dc.l	EnemySpriteDataB_FacingSide
; loc_00023822
EnemySpriteData_FacingDown:
	dc.l	$0115050A	
	dc.l	$0048FFFC	
	dc.l	$00DC0A0A	
	dc.l	OverworldMapSector_40018	
	dc.l	$00710F0A	
	dc.l	$00180008	
	dc.l	$00810F0A	
	dc.l	$00380008	
	dc.l	$00E50A0A	
	dc.l	$001C0020	
; loc_0002384A
EnemySpriteData_FacingSide:
	dc.l	$0122000A	
	dc.l	$0046FFF3	
	dc.l	$0103060A	
	dc.l	EnemySpriteData_FacingSide_Gfx_40020	
	dc.l	$00910F0A	
	dc.l	$00140018	
	dc.l	$00A10F0A	
	dc.l	$00340018	
	dc.l	loc_00000000	
	dc.l	loc_00000000	
; loc_00023872
EnemySpriteData_FacingUp:
	dc.l	$010F060A	
	dc.l	$0054FFFB	
	dc.l	$011D050A	
	dc.l	$FFF80010	
	dc.l	$00EE0A0A	
	dc.l	OverworldMapSector_40028	
	dc.l	$00610F0A	
	dc.l	$00100010	
	dc.l	$00B10F0A	
	dc.l	$00200030	
; loc_0002389A
EnemySpriteDataB_FacingDown:
	dc.l	$00F7060A	
	dc.l	$0030FFF4	
	dc.l	$00D30A0A	
	dc.l	$FFFC0018	
; loc_000238AA
EnemySpriteDataB_FacingSide:
	dc.l	$0121000A	
	dc.l	$002EFFF3	
	dc.l	$00FD060A	
	dc.l	OverworldMapSector_40018	
; loc_000238BA
EnemySpriteDataB_FacingUp:
	dc.l	$0109060A	
	dc.l	$002CFFFB	
	dc.l	$0119050A	
	dc.l	EnemySpriteDataB_FacingUp_Gfx_80010	
; loc_000238CA
BossSpriteFramePtrs:
	dc.l	BossSpriteFrame_FakeKing
	dc.l	BossSpriteFrame_FakeKing
	dc.l	BossSpriteFrame_StowThief-2
	dc.l	BossSpriteFrame_Asti
	dc.l	BossSpriteFrame_Asti
	dc.l	BossSpriteFrame_Asti
	dc.l	BossSpriteFrame_Asti
	dc.l	BossSpriteFrame_Excalabria3-2
	dc.l	BossSpriteFrame_Carthahena
	dc.l	BossSpriteFrame_Carthahena
	dc.l	BossSpriteFrame_Luther-2
	dc.l	BossSpriteFrame_Luther-2
	dc.l	BossSpriteFrame_Luther-2
	dc.l	BossSpriteFrame_Excalabria3-2
	dc.l	BossSpriteFrame_StowThief-2
	dc.l	BossSpriteFrame_StowThief-2
; loc_0002390A
BossProjectileSpriteFramePtrs:
	dc.l	BossSpriteFrame_FakeKing
	dc.l	BossProjectileSpriteFrame_B
	dc.l	BossProjectileSpriteFrame_C-2
	dc.l	BossProjectileSpriteFrame_D
; loc_0002391A
BossSpriteFrame_FakeKing:
	dc.l	$024101B1	
	dc.l	loc_00000000	
	dc.l	InitEquipmentAndLevel-3	
; loc_00023926
BossSpriteFrame_StowThief:
	dc.l	$01C10000	
	dc.l	loc_00000000	
; loc_0002392E
BossSpriteFrame_Asti:
	dc.l	$025901D1	
	dc.l	LoadCaveTileGraphics	
	dc.l	$FFDB0265	
; loc_0002393A
BossSpriteFrame_Excalabria3:
	dc.l	$01E10000	
	dc.l	$FFF6FFDB	
; loc_00023942
BossSpriteFrame_Carthahena:
	dc.l	$027101F1	
	dc.l	LoadCaveTileGfxToBuffer-3	
	dc.l	$FFDC027D	
; loc_0002394E
BossSpriteFrame_Luther:
	dc.l	$020102AD	
	dc.l	loc_00000000	
; loc_00023956
BossProjectileSpriteFrame_B:
	dc.l	$02890211	
	dc.l	loc_00000000	
	dc.l	ClearVRAMSprites_End-3	
; loc_00023962
BossProjectileSpriteFrame_C:
	dc.l	$02210000	
	dc.l	loc_00000000	
; loc_0002396A
BossProjectileSpriteFrame_D:
	dc.l	$02A10231	
	dc.l	loc_00000000	
	dc.l	BossProjectileSpriteFrame_D_Frame_2B0	
; loc_00023976
HydraBoss_ProjectileSpriteFrames:
	dc.l	loc_00000000	
	dc.l	$02B402B8	
	dc.l	$02B402B8	
	dc.l	$02B402B8	
	dc.l	$02BC02C0	
	dc.l	$02BC02C0	
	dc.l	$02BC02C0	
; loc_00023992
HydraBoss_ProjectileFallFrames:
	dc.l	$02C402C8	
; loc_00023996
HydraBoss_BodyPartFrames:
	dc.l	$00F10000	
	dc.l	$00FD0000	
	dc.l	$01090061	
	dc.l	$011500B1	
; loc_000239A6
HydraBoss_AttackFrames:
	dc.l	$01210021	
	dc.l	$012D0031	
	dc.l	$01390041	
	dc.l	$01450051	
; loc_000239B6
HydraBoss_AttackAnimFrames:
	dc.l	$01450051	
	dc.l	$F4100000	
	dc.l	$01510071	
	dc.l	$F4100000	
	dc.l	$015D0081	
	dc.l	$F4100000	
	dc.l	$01510071	
	dc.l	$F4100000	
	dc.l	$01690091	
	dc.l	$EC100000	
	dc.l	$017500A1	
	dc.l	$F0100000	
	dc.l	$01450051	
	dc.l	$F4100000	
; loc_000239EE
HydraBoss_PartDeathFrames:
	dc.l	$018100C1	
	dc.l	$018D00D1	
	dc.l	$019900E1	
	dc.l	$01A50000	
; loc_000239FE
BossTileSourceTable:
	dc.l	BossTileSourceTable_Gfx_7F618
	dc.l	$000A0003	
	dc.l	$49360003	
	dc.l	BossTileSourceTable_Gfx_7F644
	dc.l	$000A0003	
	dc.l	$49360003	
	dc.l	BossTileSourceTable_Gfx_7F670
	dc.l	$000A0003	
	dc.l	$49360003	
	dc.l	BossTileSourceTable_Gfx_7F69C
	dc.l	$000A0003	
	dc.l	$49360003	
	dc.l	BossTileSourceTable_Gfx_7F6D4
	dc.l	$000A0005	
	dc.l	$48360003	
	dc.l	BossTileSourceTable_Gfx_7F716
	dc.l	$000A0008	
	dc.l	$46B60003	
; loc_00023A46
OrbitBoss_SatelliteFrames:
	dc.l	$00210031	
	dc.l	$00410051	
; loc_00023A4E
OrbitBoss_InnerSatelliteFrame:
	dc.l	$00610071	
	dc.l	$00810091	
; loc_00023A56
OrbitBoss_ProjectileFrames:
	dc.l	$00A100B1	
	dc.l	$00C100C1	
; loc_00023A5E
OrbitBoss_ProjectileFallFrames:
	dc.l	$00D100DA	
	dc.l	$00E300EC	
	dc.l	$00F500FE	
; loc_00023A6A
OrbitBoss_ProjectileExplodeFrames:
	dc.l	$01070110	
	dc.l	$01190041	
; loc_00023A72
EncounterTileData_Entry:
	dc.l	EncounterTileData_Entry_Gfx_5D7A0
	dc.l	EncounterTileData_Entry_Gfx_5DC36
	dc.b	$00, $4F 

;loc_00023A7C:
EnemyEncounterTypesByMapSector:  ; Maps current map sector to pointer index at EnemyEncounterGroupTable
	dc.b	$28, $28, $28, $27, $27, $27, $24, $00, $21, $23, $20, $20, $1E, $1E, $41, $00
	dc.b	$2A, $2A, $2C, $2E, $25, $25, $24, $24, $21, $21, $00, $00, $1E, $41, $00, $00
	dc.b	$00, $2D, $2D, $2D, $2E, $2E, $34, $36, $36, $36, $37, $37, $1B, $1C, $1C, $00
	dc.b	$00, $32, $32, $3F, $1E, $2E, $0B, $00, $00, $39, $00, $00, $1B, $1B, $1A, $1C
	dc.b	$03, $02, $05, $05, $08, $08, $0A, $00, $00, $39, $00, $3D, $18, $18, $17, $00 
	dc.b	$04, $02, $07, $07, $08, $08, $09, $00, $3A, $3A, $3B, $3C, $16, $17, $00, $00 
	dc.b	$00, $00, $0F, $00, $00, $0D, $11, $11, $12, $12, $14, $00, $16, $17, $00, $00 
	dc.b	$00, $00, $0E, $0E, $0D, $0F, $0F, $11, $00, $12, $15, $14, $16, $00, $00, $00 

;loc_00023AFC: ; Maps current cave room to pointer index at EnemyEncounterGroupTable
EnemyEncounterTypesByCaveRoom:
	dc.b	$01, $06, $06, $0C, $0C, $10, $43, $13, $13, $40, $40, $19, $19, $1D, $1D, $1F 
	dc.b	$1F, $1F, $22, $42, $26, $26, $29, $2F, $2F, $30, $31, $31, $35, $35, $38, $38 
	dc.b	$3E, $3E, $3E, $29, $2B, $2D, $45, $2D, $2B, $2D, $33, $44 

; loc_00023B28
EnemyEncounterGroupTable: ; Enemy encounters map
	dc.l	EnemyEncounterGroup_00
	dc.l	EnemyEncounterGroup_01
	dc.l	EnemyEncounterGroup_02
	dc.l	EnemyEncounterGroup_03
	dc.l	EnemyEncounterGroup_04
	dc.l	EnemyEncounterGroup_05
	dc.l	EnemyEncounterGroup_06
	dc.l	EnemyEncounterGroup_07
	dc.l	EnemyEncounterGroup_08
	dc.l	EnemyEncounterGroup_09
	dc.l	EnemyEncounterGroup_0A
	dc.l	EnemyEncounterGroup_0B
	dc.l	EnemyEncounterGroup_0C
	dc.l	EnemyEncounterGroup_0D
	dc.l	EnemyEncounterGroup_0E
	dc.l	EnemyEncounterGroup_0F
	dc.l	EnemyEncounterGroup_10
	dc.l	EnemyEncounterGroup_11
	dc.l	EnemyEncounterGroup_12
	dc.l	EnemyEncounterGroup_13
	dc.l	EnemyEncounterGroup_14
	dc.l	EnemyEncounterGroup_15
	dc.l	EnemyEncounterGroup_16
	dc.l	EnemyEncounterGroup_17
	dc.l	EnemyEncounterGroup_18
	dc.l	EnemyEncounterGroup_19
	dc.l	EnemyEncounterGroup_1A
	dc.l	EnemyEncounterGroup_1B
	dc.l	EnemyEncounterGroup_1C
	dc.l	EnemyEncounterGroup_1D
	dc.l	EnemyEncounterGroup_1E
	dc.l	EnemyEncounterGroup_1F
	dc.l	EnemyEncounterGroup_20
	dc.l	EnemyEncounterGroup_21
	dc.l	EnemyEncounterGroup_22
	dc.l	EnemyEncounterGroup_23
	dc.l	EnemyEncounterGroup_24
	dc.l	EnemyEncounterGroup_25
	dc.l	EnemyEncounterGroup_26
	dc.l	EnemyEncounterGroup_27
	dc.l	EnemyEncounterGroup_28
	dc.l	EnemyEncounterGroup_29
	dc.l	EnemyEncounterGroup_2A
	dc.l	EnemyEncounterGroup_2B
	dc.l	EnemyEncounterGroup_2C
	dc.l	EnemyEncounterGroup_2D
	dc.l	EnemyEncounterGroup_2E
	dc.l	EnemyEncounterGroup_2F
	dc.l	EnemyEncounterGroup_30
	dc.l	EnemyEncounterGroup_31
	dc.l	EnemyEncounterGroup_32
	dc.l	EnemyEncounterGroup_33
	dc.l	EnemyEncounterGroup_34
	dc.l	EnemyEncounterGroup_35	
	dc.l	EnemyEncounterGroup_36
	dc.l	EnemyEncounterGroup_37
	dc.l	EnemyEncounterGroup_38
	dc.l	EnemyEncounterGroup_39
	dc.l	EnemyEncounterGroup_3A
	dc.l	EnemyEncounterGroup_3B
	dc.l	EnemyEncounterGroup_3C
	dc.l	EnemyEncounterGroup_3D
	dc.l	EnemyEncounterGroup_3E
	dc.l	EnemyEncounterGroup_3F
	dc.l	EnemyEncounterGroup_40
	dc.l	EnemyEncounterGroup_41
	dc.l	EnemyEncounterGroup_42
	dc.l	EnemyEncounterGroup_43
	dc.l	EnemyEncounterGroup_44
	dc.l	EnemyEncounterGroup_45
EnemyEncounterGroup_00: ; Each map segment or cave has a set of 4 encounter types
	dc.w	$0, $0, $A, $1 
; loc_00023C48
EnemyEncounterGroup_01:
	dc.w	$6, $A, $1, $1 
; loc_00023C50
EnemyEncounterGroup_02:
	dc.w	$A, $A, $1, $0 
; loc_00023C58
EnemyEncounterGroup_03:
	dc.w	$E, $A, $1, $A 
; loc_00023C60
EnemyEncounterGroup_04:
	dc.w	$E, $12, $A, $1 
; loc_00023C68
EnemyEncounterGroup_05:
	dc.w	$E, $26, $12, $A 
; loc_00023C70
EnemyEncounterGroup_06:
	dc.w	$E, $6, $6, $16 
; loc_00023C78
EnemyEncounterGroup_07:
	dc.w	$5, $12, $E, $16 
; loc_00023C80
EnemyEncounterGroup_08:
	dc.w	$B, $A, $12, $5 
; loc_00023C88
EnemyEncounterGroup_09:
	dc.w	$32, $B, $12, $16 
; loc_00023C90
EnemyEncounterGroup_0A:
	dc.w	$2A, $32, $5, $B 
; loc_00023C98
EnemyEncounterGroup_0B:
	dc.w	$F, $5, $2A, $32 
; loc_00023CA0
EnemyEncounterGroup_0C:
	dc.w	$2E, $6, $16, $2 
; loc_00023CA8
EnemyEncounterGroup_0D:
	dc.w	$1A, $2A, $32, $F
; loc_00023CB0
EnemyEncounterGroup_0E:
	dc.w	$42, $2E, $1A, $2A 
; loc_00023CB8
EnemyEncounterGroup_0F:
	dc.w	$4A, $2E, $1A, $42
; loc_00023CC0
EnemyEncounterGroup_10:
	dc.w	$1E, $6, $4A, $2
; loc_00023CC8
EnemyEncounterGroup_11:
	dc.w	$4E, $4A, $1A, $42 
; loc_00023CD0
EnemyEncounterGroup_12:
	dc.w	$13, $4E, $1A, $42
; loc_00023CD8
EnemyEncounterGroup_13:
	dc.w	$22, $3A, $36, $1E 
; loc_00023CE0
EnemyEncounterGroup_14:
	dc.w	$1B, $4, $4E, $13
; loc_00023CE8
EnemyEncounterGroup_15:
	dc.w	$46, $32, $1B, $4 
; loc_00023CF0
EnemyEncounterGroup_16:
	dc.w	$2F, $22, $2A, $46 
; loc_00023CF8
EnemyEncounterGroup_17:
	dc.w	$27, $C, $46, $4E 
; loc_00023D00
EnemyEncounterGroup_18:
	dc.w	$2B, $22, $1B, $1A
; loc_00023D08
EnemyEncounterGroup_19:
	dc.w	$1F, $3E, $10, $7 
; loc_00023D10
EnemyEncounterGroup_1A:
	dc.w	$33, $22, $1B, $2F 
; loc_00023D18
EnemyEncounterGroup_1B:
	dc.w	$43, $33, $10, $22 
; loc_00023D20
EnemyEncounterGroup_1C:
	dc.w	$4B, $47, $33, $4 
; loc_00023D28
EnemyEncounterGroup_1D:
	dc.w	$3B, $4B, $47, $22 
; loc_00023D30
EnemyEncounterGroup_1E:
	dc.w	$1C, $28, $47, $33 
; loc_00023D38
EnemyEncounterGroup_1F:
	dc.w	$3F, $17, $7, $1C 
; loc_00023D40
EnemyEncounterGroup_20:
	dc.w	$23, $1C, $14, $4B 
; loc_00023D48
EnemyEncounterGroup_21:
	dc.w	$14, $23, $1C, $33 
; loc_00023D50
EnemyEncounterGroup_22:
	dc.w	$20, $1C, $8, $14 
; loc_00023D58
EnemyEncounterGroup_23:
	dc.w	$44, $4F, $14, $23 
; loc_00023D60
EnemyEncounterGroup_24:
	dc.w	$D, $44, $4F, $1C
; loc_00023D68
EnemyEncounterGroup_25:
	dc.w	$48, $30, $23, $1C 
; loc_00023D70
EnemyEncounterGroup_26:
	dc.w	$3C, $8, $7, $48 
; loc_00023D78
EnemyEncounterGroup_27:
	dc.w	$11, $D, $44, $48
; loc_00023D80
EnemyEncounterGroup_28:
	dc.w	$34, $2C, $D, $11 
; loc_00023D88
EnemyEncounterGroup_29:
	dc.w	$40, $11, $8, $30 
; loc_00023D90
EnemyEncounterGroup_2A:
	dc.w	$29, $30, $48, $23 
; loc_00023D98
EnemyEncounterGroup_2B:
	dc.w	$21, $4C, $29, $40 
; loc_00023DA0
EnemyEncounterGroup_2C:
	dc.w	$24, $29, $11, $4
; loc_00023DA8
EnemyEncounterGroup_2D:
	dc.w	$15, $24, $34, $4C 
; loc_00023DB0
EnemyEncounterGroup_2E:
	dc.w	$50, $24, $15, $29 
; loc_00023DB8
EnemyEncounterGroup_2F:
	dc.w	$45, $39, $24, $11 
; loc_00023DC0
EnemyEncounterGroup_30:
	dc.w	$18, $45, $39, $15 
; loc_00023DC8
EnemyEncounterGroup_31:
	dc.w	$18, $45, $50, $39 
; loc_00023DD0
EnemyEncounterGroup_32:
	dc.w	$31, $18, $50, $45
; loc_00023DD8
EnemyEncounterGroup_33:
	dc.w	$53, $50, $18, $45 
; loc_00023DE0
EnemyEncounterGroup_34:
	dc.w	$1D, $31, $24, $45 
; loc_00023DE8
EnemyEncounterGroup_35:
	dc.w	$9, $3D, $18, $50 
; loc_00023DF0
EnemyEncounterGroup_36:
	dc.w	$2D, $1D, $31, $50 
; loc_00023DF8
EnemyEncounterGroup_37:
	dc.w	$4D, $2D, $1D, $4 
; loc_00023E00
EnemyEncounterGroup_38:
	dc.w	$19, $41, $4D, $9 
; loc_00023E08
EnemyEncounterGroup_39:
	dc.w	$4D, $19, $2D, $1D 
; loc_00023E10
EnemyEncounterGroup_3A:
	dc.w	$35, $2D, $4D, $24 
; loc_00023E18
EnemyEncounterGroup_3B:
	dc.w	$49, $4D, $35, $11 
; loc_00023E20
EnemyEncounterGroup_3C:
	dc.w	$25, $49, $35, $19 
; loc_00023E28
EnemyEncounterGroup_3D:
	dc.w	$25, $49, $35, $4D
; loc_00023E30
EnemyEncounterGroup_3E:
	dc.w	$51, $25, $49, $52 
; loc_00023E38
EnemyEncounterGroup_3F:
	dc.w	$3, $50, $50, $45 
; loc_00023E40
EnemyEncounterGroup_40:
	dc.w	$3E, $7, $3A, $22 
; loc_00023E48
EnemyEncounterGroup_41:
	dc.w	$28, $47, $22, $4B
; loc_00023E50
EnemyEncounterGroup_42:
	dc.w	$38, $8, $4, $23
; loc_00023E58
EnemyEncounterGroup_43:
	dc.w	$1E, $36, $16, $2
; loc_00023E60
EnemyEncounterGroup_44:
	dc.w	$37, $47, $7, $3A
; loc_00023E68
EnemyEncounterGroup_45:
	dc.w	$21, $1F, $1E, $4C 
; loc_00023E70
EnemyGfxDataTable:
	dc.l	EnemyAppearance_5A ; Appearance
	dc.l	EnemyData_Bouncing_5A ; Sprite mappings
	dc.l	EnemySpriteSet_C ; Sprites
	dc.l	EnemyAppearance_69
	dc.l	EnemyData_Bouncing_69
	dc.l	EnemySpriteSet_C
	dc.l	EnemyAppearance_6A
	dc.l	EnemyData_Bouncing_6A
	dc.l	EnemySpriteSet_C
	dc.l	EnemyAppearance_6B	
	dc.l	EnemyData_Bouncing_6B	
	dc.l	EnemySpriteSet_C	
	dc.l	EnemyAppearance_AC
	dc.l	EnemyData_Bouncing_AC
	dc.l	EnemySpriteSet_C
	dc.l	EnemyAppearance_AD
	dc.l	EnemyData_Bouncing_AD
	dc.l	EnemySpriteSet_C
	dc.l	EnemyAppearance_4E
	dc.l	EnemyData_StalkPause_4E
	dc.l	EnemySpriteSet_A
	dc.l	EnemyAppearance_7B
	dc.l	EnemyData_StalkPause_7B
	dc.l	EnemySpriteSet_A
	dc.l	EnemyAppearance_7C
	dc.l	EnemyData_StalkPause_7C
	dc.l	EnemySpriteSet_A
	dc.l	EnemyAppearance_7D
	dc.l	EnemyData_StalkPause_7D
	dc.l	EnemySpriteSet_A
	dc.l	EnemyAppearance_4D
	dc.l	EnemyData_StandardMelee_4D
	dc.l	EnemySpriteSet_B
	dc.l	EnemyAppearance_6C
	dc.l	EnemyData_StandardMelee_6C
	dc.l	EnemySpriteSet_B
	dc.l	EnemyAppearance_6D
	dc.l	EnemyData_StandardMelee_6D
	dc.l	EnemySpriteSet_B
	dc.l	EnemyAppearance_6E
	dc.l	EnemyData_StandardMelee_6E
	dc.l	EnemySpriteSet_B
	dc.l	EnemyAppearance_5B
	dc.l	EnemyData_FleeChase_5B
	dc.l	EnemySpriteSet_D
	dc.l	EnemyAppearance_6F
	dc.l	EnemyData_FleeChase_6F
	dc.l	EnemySpriteSet_D
	dc.l	EnemyAppearance_70
	dc.l	EnemyData_FleeChase_70
	dc.l	EnemySpriteSet_D
	dc.l	EnemyAppearance_71
	dc.l	EnemyData_FleeChase_71
	dc.l	EnemySpriteSet_D
	dc.l	EnemyAppearance_63
	dc.l	EnemyData_ProjectileFire_63
	dc.l	EnemySpriteSet_H
	dc.l	EnemyAppearance_A4
	dc.l	EnemyData_ProjectileFire_A4
	dc.l	EnemySpriteSet_H
	dc.l	EnemyAppearance_A5
	dc.l	EnemyData_ProjectileFire_A5
	dc.l	EnemySpriteSet_H
	dc.l	EnemyAppearance_A6
	dc.l	EnemyData_ProjectileFire_A6
	dc.l	EnemySpriteSet_H
	dc.l	EnemyAppearance_5C
	dc.l	EnemyData_ProximityChase_5C
	dc.l	EnemySpriteSet_E
	dc.l	EnemyAppearance_9E
	dc.l	EnemyData_ProximityChase_9E
	dc.l	EnemySpriteSet_E
	dc.l	EnemyAppearance_9F
	dc.l	EnemyData_ProximityChase_9F
	dc.l	EnemySpriteSet_E
	dc.l	EnemyAppearance_A0
	dc.l	EnemyData_ProximityChase_A0
	dc.l	EnemySpriteSet_E
	dc.l	EnemyAppearance_5D
	dc.l	EnemyData_StandardMeleeAlt_5D
	dc.l	EnemySpriteSet_F
	dc.l	EnemyAppearance_A1
	dc.l	EnemyData_StandardMeleeAlt_A1
	dc.l	EnemySpriteSet_F
	dc.l	EnemyAppearance_A2
	dc.l	EnemyData_StandardMeleeAlt_A2
	dc.l	EnemySpriteSet_F
	dc.l	EnemyAppearance_A3
	dc.l	EnemyData_StandardMeleeAlt_A3
	dc.l	EnemySpriteSet_F
	dc.l	EnemyAppearance_64
	dc.l	EnemyData_StalkPauseAlt_64
	dc.l	EnemySpriteSet_I
	dc.l	EnemyAppearance_B9
	dc.l	EnemyData_StalkPauseAlt_B9
	dc.l	EnemySpriteSet_I
	dc.l	EnemyAppearance_BA
	dc.l	EnemyData_StalkPauseAlt_BA
	dc.l	EnemySpriteSet_I
	dc.l	EnemyAppearance_BB
	dc.l	EnemyData_StalkPauseAlt_BB
	dc.l	EnemySpriteSet_I
	dc.l	EnemyAppearance_65
	dc.l	EnemyData_HumanoidMelee_65
	dc.l	EnemySpriteSet_J
	dc.l	EnemyAppearance_A7
	dc.l	EnemyData_HumanoidMelee_A7
	dc.l	EnemySpriteSet_J
	dc.l	EnemyAppearance_A8
	dc.l	EnemyData_HumanoidMeleeAlt_A8
	dc.l	EnemySpriteSet_J
	dc.l	EnemyAppearance_A9
	dc.l	EnemyData_HumanoidMeleeAlt_A9
	dc.l	EnemySpriteSet_J
	dc.l	EnemyAppearance_66
	dc.l	EnemyData_RandomShooter_66
	dc.l	EnemySpriteSet_K
	dc.l	EnemyAppearance_AA
	dc.l	EnemyData_RandomShooter_AA
	dc.l	EnemySpriteSet_K
	dc.l	EnemyAppearance_AB
	dc.l	EnemyData_RandomShooter_AB
	dc.l	EnemySpriteSet_K
	dc.l	EnemyAppearance_BC
	dc.l	EnemyData_RandomShooter_BC
	dc.l	EnemySpriteSet_K
	dc.l	EnemyAppearance_61
	dc.l	EnemyData_StandardMeleeFast_61
	dc.l	EnemySpriteSet_G
	dc.l	EnemyAppearance_BD	
	dc.l	EnemyData_StandardMeleeFast_BD	
	dc.l	EnemySpriteSet_G	
	dc.l	EnemyAppearance_BE
	dc.l	EnemyData_StandardMeleeFast_BE
	dc.l	EnemySpriteSet_G
	dc.l	EnemyAppearance_BF
	dc.l	EnemyData_StandardMeleeFast_BF
	dc.l	EnemySpriteSet_G
	dc.l	EnemyAppearance_75
	dc.l	EnemyData_OrbShield_75
	dc.l	EnemySpriteSet_M
	dc.l	EnemyAppearance_C0
	dc.l	EnemyData_OrbShield_C0
	dc.l	EnemySpriteSet_M
	dc.l	EnemyAppearance_C1
	dc.l	EnemyData_OrbShield_C1
	dc.l	EnemySpriteSet_M
	dc.l	EnemyAppearance_C2
	dc.l	EnemyData_OrbShield_C2
	dc.l	EnemySpriteSet_M
	dc.l	EnemyAppearance_63
	dc.l	EnemyData_BurstFire_63
	dc.l	EnemySpriteSet_H
	dc.l	EnemyAppearance_A4
	dc.l	EnemyData_BurstFire_A4
	dc.l	EnemySpriteSet_H
	dc.l	EnemyAppearance_A5
	dc.l	EnemyData_BurstFire_A5
	dc.l	EnemySpriteSet_H
	dc.l	EnemyAppearance_A6
	dc.l	EnemyData_BurstFire_A6
	dc.l	EnemySpriteSet_H
	dc.l	EnemyAppearance_64
	dc.l	EnemyData_StalkPause3_64
	dc.l	EnemySpriteSet_I
	dc.l	EnemyAppearance_B9	
	dc.l	EnemyData_StationaryShooter_B9	
	dc.l	EnemySpriteSet_I	
	dc.l	EnemyAppearance_BA
	dc.l	EnemyData_StalkPause3_BA
	dc.l	EnemySpriteSet_I
	dc.l	EnemyAppearance_BB
	dc.l	EnemyData_StalkPause3_BB
	dc.l	EnemySpriteSet_I
	dc.l	EnemyAppearance_64
	dc.l	EnemyData_FastBurstShooter_64
	dc.l	EnemySpriteSet_I
	dc.l	EnemyAppearance_B9
	dc.l	EnemyData_FastBurstShooter_B9
	dc.l	EnemySpriteSet_I
	dc.l	EnemyAppearance_BA
	dc.l	EnemyData_FastBurstShooter_BA
	dc.l	EnemySpriteSet_I
	dc.l	EnemyAppearance_BB	
	dc.l	EnemyData_FastBurstShooter_BB	
	dc.l	EnemySpriteSet_I	
	dc.l	EnemyAppearance_64
	dc.l	EnemyData_HomingShooter_64
	dc.l	EnemySpriteSet_I
	dc.l	EnemyAppearance_B9
	dc.l	EnemyData_HomingShooter_B9
	dc.l	EnemySpriteSet_I
	dc.l	EnemyAppearance_BA
	dc.l	EnemyData_HomingShooter_BA
	dc.l	EnemySpriteSet_I
	dc.l	EnemyAppearance_BB
	dc.l	EnemyData_HomingShooter_BB
	dc.l	EnemySpriteSet_I
	dc.l	EnemyAppearance_66
	dc.l	EnemyData_Teleporter_66
	dc.l	EnemySpriteSet_K
	dc.l	EnemyAppearance_AA
	dc.l	EnemyData_Teleporter_AA
	dc.l	EnemySpriteSet_K
	dc.l	EnemyAppearance_AB
	dc.l	EnemyData_Teleporter_AB
	dc.l	EnemySpriteSet_K
	dc.l	EnemyAppearance_BC
	dc.l	EnemyData_Teleporter_BC
	dc.l	EnemySpriteSet_K
	dc.l	EnemyAppearance_66
	dc.l	EnemyData_SequentialFire_66
	dc.l	EnemySpriteSet_L
	dc.l	EnemyAppearance_AA
	dc.l	EnemyData_SequentialFire_AA
	dc.l	EnemySpriteSet_L
	dc.l	EnemyAppearance_AB
	dc.l	EnemyData_SequentialFire_AB
	dc.l	EnemySpriteSet_L
	dc.l	EnemyAppearance_BC
	dc.l	EnemyData_SequentialFire_BC
	dc.l	EnemySpriteSet_L
	dc.l	EnemyAppearance_75
	dc.l	EnemyData_MultiOrb_75
	dc.l	EnemySpriteSet_M
	dc.l	EnemyAppearance_C0
	dc.l	EnemyData_MultiOrb_C0
	dc.l	EnemySpriteSet_M
	dc.l	EnemyAppearance_C1
	dc.l	EnemyData_MultiOrb_C1
	dc.l	EnemySpriteSet_M
	dc.l	EnemyAppearance_C2
	dc.l	EnemyData_MultiOrb_C2
	dc.l	EnemySpriteSet_M
	dc.l	EnemyAppearance_75
	dc.l	EnemyData_OrbRing_75
	dc.l	EnemySpriteSet_M
	dc.l	EnemyAppearance_C0
	dc.l	EnemyData_OrbRing_C0
	dc.l	EnemySpriteSet_M
	dc.l	EnemyAppearance_C1
	dc.l	EnemyData_OrbRing_C1
	dc.l	EnemySpriteSet_M
	dc.l	EnemyAppearance_C2
	dc.l	EnemyData_OrbRing_C2
	dc.l	EnemySpriteSet_M
	dc.l	EnemyAppearance_A6
	dc.l	EnemyData_SpiralBurst_A6a
	dc.l	EnemySpriteSet_H
	dc.l	EnemyAppearance_A6
	dc.l	EnemyData_SpiralBurst_A6b
	dc.l	EnemySpriteSet_H
	dc.l	EnemyAppearance_7B	
	dc.l	EnemyData_StalkPause_7B_Last
	dc.l	EnemySpriteSet_A
; loc_0002426C
EnemyAppearance_5A:
	dc.l	EnemyGfxFrameTable_OrbMain
	dc.l	EnemyGfxData_OrbMain
	dc.l	EnemyGfxFrameTable_OrbChild
	dc.l	EnemyGfxData_OrbChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0E0D005A	; Appearance palette/vfx
; loc_00024284
EnemyAppearance_69:
	dc.l	EnemyGfxFrameTable_OrbMain
	dc.l	EnemyGfxData_OrbMain
	dc.l	EnemyGfxFrameTable_OrbChild
	dc.l	EnemyGfxData_OrbChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0E0D0069	
; loc_0002429C
EnemyAppearance_6A:
	dc.l	EnemyGfxFrameTable_OrbMain
	dc.l	EnemyGfxData_OrbMain
	dc.l	EnemyGfxFrameTable_OrbChild
	dc.l	EnemyGfxData_OrbChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0E0D006A	
; loc_000242B4
EnemyAppearance_6B:
	dc.l	EnemyGfxFrameTable_OrbMain	
	dc.l	EnemyGfxData_OrbMain	
	dc.l	EnemyGfxFrameTable_OrbChild	
	dc.l	EnemyGfxData_OrbChild	
	dc.l	NullSpriteRoutine-2	
	dc.l	$0E0D006B	
; loc_000242CC
EnemyAppearance_AC:
	dc.l	EnemyGfxFrameTable_OrbMain
	dc.l	EnemyGfxData_OrbMain
	dc.l	EnemyGfxFrameTable_OrbChild
	dc.l	EnemyGfxData_OrbChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0E0D00AC	
; loc_000242E4
EnemyAppearance_AD:
	dc.l	EnemyGfxFrameTable_OrbMain
	dc.l	EnemyGfxData_OrbMain
	dc.l	EnemyGfxFrameTable_OrbChild
	dc.l	EnemyGfxData_OrbChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0E0D00AD	
; loc_000242FC
EnemyAppearance_4E:
	dc.l	EnemyGfxFrameTable_DragonMain
	dc.l	EnemyGfxData_DragonMain
	dc.l	EnemyGfxFrameTable_DragonChild
	dc.l	EnemyGfxData_DragonChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E004E	
; loc_00024314
EnemyAppearance_7B:
	dc.l	EnemyGfxFrameTable_DragonMain
	dc.l	EnemyGfxData_DragonMain
	dc.l	EnemyGfxFrameTable_DragonChild
	dc.l	EnemyGfxData_DragonChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E007B	
; loc_0002432C
EnemyAppearance_7C:
	dc.l	EnemyGfxFrameTable_DragonMain
	dc.l	EnemyGfxData_DragonMain
	dc.l	EnemyGfxFrameTable_DragonChild
	dc.l	EnemyGfxData_DragonChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E007C	
; loc_00024344
EnemyAppearance_7D:
	dc.l	EnemyGfxFrameTable_DragonMain
	dc.l	EnemyGfxData_DragonMain
	dc.l	EnemyGfxFrameTable_DragonChild
	dc.l	EnemyGfxData_DragonChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E007D	
; loc_0002435C
EnemyAppearance_4D:
	dc.l	EnemyGfxFrameTable_QuadrupedMain
	dc.l	EnemyGfxData_QuadrupedMain
	dc.l	EnemyGfxFrameTable_QuadrupedChild
	dc.l	EnemyGfxData_QuadrupedChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E004D	
; loc_00024374
EnemyAppearance_6C:
	dc.l	EnemyGfxFrameTable_QuadrupedMain
	dc.l	EnemyGfxData_QuadrupedMain
	dc.l	EnemyGfxFrameTable_QuadrupedChild
	dc.l	EnemyGfxData_QuadrupedChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E006C	
; loc_0002438C
EnemyAppearance_6D:
	dc.l	EnemyGfxFrameTable_QuadrupedMain
	dc.l	EnemyGfxData_QuadrupedMain
	dc.l	EnemyGfxFrameTable_QuadrupedChild
	dc.l	EnemyGfxData_QuadrupedChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E006D	
; loc_000243A4
EnemyAppearance_6E:
	dc.l	EnemyGfxFrameTable_QuadrupedMain
	dc.l	EnemyGfxData_QuadrupedMain
	dc.l	EnemyGfxFrameTable_QuadrupedChild
	dc.l	EnemyGfxData_QuadrupedChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E006E	
; loc_000243BC
EnemyAppearance_5B:
	dc.l	EnemyGfxFrameTable_SerpentMain
	dc.l	EnemyGfxData_SerpentMain
	dc.l	EnemyGfxFrameTable_SerpentChild
	dc.l	EnemyGfxData_SerpentChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E005B	
; loc_000243D4
EnemyAppearance_6F:
	dc.l	EnemyGfxFrameTable_SerpentMain
	dc.l	EnemyGfxData_SerpentMain
	dc.l	EnemyGfxFrameTable_SerpentChild
	dc.l	EnemyGfxData_SerpentChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E006F	
; loc_000243EC
EnemyAppearance_70:
	dc.l	EnemyGfxFrameTable_SerpentMain
	dc.l	EnemyGfxData_SerpentMain
	dc.l	EnemyGfxFrameTable_SerpentChild
	dc.l	EnemyGfxData_SerpentChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E0070	
; loc_00024404
EnemyAppearance_71:
	dc.l	EnemyGfxFrameTable_SerpentMain
	dc.l	EnemyGfxData_SerpentMain
	dc.l	EnemyGfxFrameTable_SerpentChild
	dc.l	EnemyGfxData_SerpentChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E0071	
; loc_0002441C
EnemyAppearance_63:
	dc.l	EnemyGfxFrameTable_WorldMapMain
	dc.l	EnemyGfxData_WorldMapMain
	dc.l	EnemyGfxFrameTable_WorldMapChild
	dc.l	EnemyGfxData_WorldMapChild
	dc.l	ExecuteWorldMapDma	
	dc.l	$0E0E0063	
; loc_00024434
EnemyAppearance_A4:
	dc.l	EnemyGfxFrameTable_WorldMapMain
	dc.l	EnemyGfxData_WorldMapMain
	dc.l	EnemyGfxFrameTable_WorldMapChild
	dc.l	EnemyGfxData_WorldMapChild
	dc.l	ExecuteWorldMapDma	
	dc.l	$0E0E00A4	
; loc_0002444C
EnemyAppearance_A5:
	dc.l	EnemyGfxFrameTable_WorldMapMain
	dc.l	EnemyGfxData_WorldMapMain
	dc.l	EnemyGfxFrameTable_WorldMapChild
	dc.l	EnemyGfxData_WorldMapChild
	dc.l	ExecuteWorldMapDma	
	dc.l	$0E0E00A5	
; loc_00024464
EnemyAppearance_A6:
	dc.l	EnemyGfxFrameTable_WorldMapMain
	dc.l	EnemyGfxData_WorldMapMain
	dc.l	EnemyGfxFrameTable_WorldMapChild
	dc.l	EnemyGfxData_WorldMapChild
	dc.l	ExecuteWorldMapDma	
	dc.l	$0E0E00A6	
; loc_0002447C
EnemyAppearance_5C:
	dc.l	EnemyGfxFrameTable_InsectMain
	dc.l	EnemyGfxData_InsectMain
	dc.l	EnemyGfxFrameTable_InsectChild
	dc.l	EnemyGfxData_InsectChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E005C	
; loc_00024494
EnemyAppearance_9E:
	dc.l	EnemyGfxFrameTable_InsectMain
	dc.l	EnemyGfxData_InsectMain
	dc.l	EnemyGfxFrameTable_InsectChild
	dc.l	EnemyGfxData_InsectChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E009E	
; loc_000244AC
EnemyAppearance_9F:
	dc.l	EnemyGfxFrameTable_InsectMain
	dc.l	EnemyGfxData_InsectMain
	dc.l	EnemyGfxFrameTable_InsectChild
	dc.l	EnemyGfxData_InsectChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E009F	
; loc_000244C4
EnemyAppearance_A0:
	dc.l	EnemyGfxFrameTable_InsectMain
	dc.l	EnemyGfxData_InsectMain
	dc.l	EnemyGfxFrameTable_InsectChild
	dc.l	EnemyGfxData_InsectChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E00A0	
; loc_000244DC
EnemyAppearance_5D:
	dc.l	EnemyGfxFrameTable_GolemMain
	dc.l	EnemyGfxData_GolemMain
	dc.l	EnemyGfxFrameTable_GolemChild
	dc.l	EnemyGfxData_GolemChild
	dc.l	ExecuteWorldMapDma	
	dc.l	$0E0E005D	
; loc_000244F4
EnemyAppearance_A1:
	dc.l	EnemyGfxFrameTable_GolemMain
	dc.l	EnemyGfxData_GolemMain
	dc.l	EnemyGfxFrameTable_GolemChild
	dc.l	EnemyGfxData_GolemChild
	dc.l	ExecuteWorldMapDma	
	dc.l	$0E0E00A1	
; loc_0002450C
EnemyAppearance_A2:
	dc.l	EnemyGfxFrameTable_GolemMain
	dc.l	EnemyGfxData_GolemMain
	dc.l	EnemyGfxFrameTable_GolemChild
	dc.l	EnemyGfxData_GolemChild
	dc.l	ExecuteWorldMapDma	
	dc.l	$0E0E00A2	
; loc_00024524
EnemyAppearance_A3:
	dc.l	EnemyGfxFrameTable_GolemMain
	dc.l	EnemyGfxData_GolemMain
	dc.l	EnemyGfxFrameTable_GolemChild
	dc.l	EnemyGfxData_GolemChild
	dc.l	ExecuteWorldMapDma	
	dc.l	$0E0E00A3	
; loc_0002453C
EnemyAppearance_64:
	dc.l	EnemyGfxFrameTable_BeastMain
	dc.l	EnemyGfxData_BeastMain
	dc.l	EnemyGfxFrameTable_BeastChild
	dc.l	EnemyGfxData_BeastChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E0064	
; loc_00024554
EnemyAppearance_B9:
	dc.l	EnemyGfxFrameTable_BeastMain
	dc.l	EnemyGfxData_BeastMain
	dc.l	EnemyGfxFrameTable_BeastChild
	dc.l	EnemyGfxData_BeastChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E00B9	
; loc_0002456C
EnemyAppearance_BA:
	dc.l	EnemyGfxFrameTable_BeastMain
	dc.l	EnemyGfxData_BeastMain
	dc.l	EnemyGfxFrameTable_BeastChild
	dc.l	EnemyGfxData_BeastChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E00BA	
; loc_00024584
EnemyAppearance_BB:
	dc.l	EnemyGfxFrameTable_BeastMain
	dc.l	EnemyGfxData_BeastMain
	dc.l	EnemyGfxFrameTable_BeastChild
	dc.l	EnemyGfxData_BeastChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E00BB	
; loc_0002459C
EnemyAppearance_65:
	dc.l	EnemyGfxFrameTable_SkeletonMain
	dc.l	EnemyGfxData_SkeletonMain
	dc.l	EnemyGfxFrameTable_SkeletonChild
	dc.l	EnemyGfxData_SkeletonChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E0065	
; loc_000245B4
EnemyAppearance_A7:
	dc.l	EnemyGfxFrameTable_SkeletonMain
	dc.l	EnemyGfxData_SkeletonMain
	dc.l	EnemyGfxFrameTable_SkeletonChild
	dc.l	EnemyGfxData_SkeletonChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E00A7	
; loc_000245CC
EnemyAppearance_A8:
	dc.l	EnemyGfxFrameTable_SkeletonMain
	dc.l	EnemyGfxData_SkeletonMain
	dc.l	EnemyGfxFrameTable_SkeletonChild
	dc.l	EnemyGfxData_SkeletonChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E00A8	
; loc_000245E4
EnemyAppearance_A9:
	dc.l	EnemyGfxFrameTable_SkeletonMain
	dc.l	EnemyGfxData_SkeletonMain
	dc.l	EnemyGfxFrameTable_SkeletonChild
	dc.l	EnemyGfxData_SkeletonChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E00A9	
; loc_000245FC
EnemyAppearance_66:
	dc.l	EnemyGfxFrameTable_HumanoidMain
	dc.l	EnemyGfxData_HumanoidMain
	dc.l	EnemyGfxFrameTable_HumanoidChild
	dc.l	EnemyGfxData_HumanoidChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E0066	
; loc_00024614
EnemyAppearance_AA:
	dc.l	EnemyGfxFrameTable_HumanoidMain
	dc.l	EnemyGfxData_HumanoidMain
	dc.l	EnemyGfxFrameTable_HumanoidChild
	dc.l	EnemyGfxData_HumanoidChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E00AA	
; loc_0002462C
EnemyAppearance_AB:
	dc.l	EnemyGfxFrameTable_HumanoidMain
	dc.l	EnemyGfxData_HumanoidMain
	dc.l	EnemyGfxFrameTable_HumanoidChild
	dc.l	EnemyGfxData_HumanoidChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E00AB	
; loc_00024644
EnemyAppearance_BC:
	dc.l	EnemyGfxFrameTable_HumanoidMain
	dc.l	EnemyGfxData_HumanoidMain
	dc.l	EnemyGfxFrameTable_HumanoidChild
	dc.l	EnemyGfxData_HumanoidChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E00BC	
; loc_0002465C
EnemyAppearance_61:
	dc.l	EnemyGfxFrameTable_GargoyleMain
	dc.l	EnemyGfxData_GargoyleMain
	dc.l	EnemyGfxFrameTable_GargoyleChild
	dc.l	EnemyGfxData_GargoyleChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E0061	
; loc_00024674
EnemyAppearance_BD:
	dc.l	EnemyGfxFrameTable_GargoyleMain	
	dc.l	EnemyGfxData_GargoyleMain	
	dc.l	EnemyGfxFrameTable_GargoyleChild	
	dc.l	EnemyGfxData_GargoyleChild	
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E00BD	
; loc_0002468C
EnemyAppearance_BE:
	dc.l	EnemyGfxFrameTable_GargoyleMain
	dc.l	EnemyGfxData_GargoyleMain
	dc.l	EnemyGfxFrameTable_GargoyleChild
	dc.l	EnemyGfxData_GargoyleChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E00BE	
; loc_000246A4
EnemyAppearance_BF:
	dc.l	EnemyGfxFrameTable_GargoyleMain
	dc.l	EnemyGfxData_GargoyleMain
	dc.l	EnemyGfxFrameTable_GargoyleChild
	dc.l	EnemyGfxData_GargoyleChild
	dc.l	NullSpriteRoutine-2	
	dc.l	$0D0E00BF	
; loc_000246BC
EnemyAppearance_75:
	dc.l	EnemyGfxFrameTable_BossMain
	dc.l	EnemyGfxData_BossMain
	dc.l	loc_00000000	
	dc.l	loc_00000000	
	dc.l	loc_00000000	
	dc.l	$0F000075	
; loc_000246D4
EnemyAppearance_C0:
	dc.l	EnemyGfxFrameTable_BossMain
	dc.l	EnemyGfxData_BossMain
	dc.l	loc_00000000	
	dc.l	loc_00000000	
	dc.l	loc_00000000	
	dc.l	$0F0000C0	
; loc_000246EC
EnemyAppearance_C1:
	dc.l	EnemyGfxFrameTable_BossMain
	dc.l	EnemyGfxData_BossMain
	dc.l	loc_00000000	
	dc.l	loc_00000000	
	dc.l	loc_00000000	
	dc.l	$0F0000C1	
; loc_00024704
EnemyAppearance_C2:
	dc.l	EnemyGfxFrameTable_BossMain
	dc.l	EnemyGfxData_BossMain
	dc.l	$00000000
	dc.b	$00, $00, $00, $00, $00, $00 
	dc.w	$0000
	dc.b	$0F
	dc.b	$00 
	dc.w	$00C2
; loc_0002471C
EnemyData_Bouncing_5A:
	dc.l	InitEnemy_Bouncing
	dc.w	$005A
	dc.w	$0000
	dc.w	$0000
	dc.b	$00
	dc.b	$07
	dc.b	$00, $1C, $00, $04, $00, $01, $00, $02 
	dc.l	$00000150
	dc.b	$00
	dc.b	$02
; loc_00024736
EnemyData_Bouncing_69:
	dc.l	InitEnemy_Bouncing
	dc.w	$0069
	dc.w	$0000
	dc.w	$0000
	dc.b	$00
	dc.b	$07
	dc.b	$00, $1C, $00, $05, $00, $02, $00, $02 
	dc.l	$00000170
	dc.b	$00
	dc.b	$02
; loc_00024750
EnemyData_Bouncing_6A:
	dc.l	InitEnemy_Bouncing
	dc.w	$006A
	dc.w	$0000
	dc.w	$001F
	dc.b	$00
	dc.b	$07
	dc.b	$00, $64, $00, $1E, $00, $65, $00, $30 
	dc.l	$00000240
	dc.b	$00
	dc.b	$02
; loc_0002476A
EnemyData_Bouncing_6B:
	dc.b	$00, $00, $9A, $72, $00, $6B, $00, $00, $00, $26, $00, $07, $1F, $40, $00, $6E, $03, $96, $01, $00, $00, $00, $05, $50, $00, $0E 
; loc_00024784
EnemyData_Bouncing_AC:
	dc.l	InitEnemy_Bouncing
	dc.w	$00AC
	dc.w	$0000
	dc.w	$0021
	dc.b	$00
	dc.b	$07
	dc.b	$00, $FA, $00, $52, $01, $80, $00, $70 
	dc.l	$00000280
	dc.b	$00
	dc.b	$02
; loc_0002479E
EnemyData_Bouncing_AD:
	dc.l	InitEnemy_Bouncing
	dc.w	$00AD
	dc.w	$0000
	dc.w	$0003
	dc.b	$00
	dc.b	$07
	dc.b	$00, $59, $00, $17, $00, $39, $00, $10 
	dc.l	$00000210
	dc.b	$00
	dc.b	$02
; loc_000247B8
EnemyData_StalkPause_4E:
	dc.l	InitEnemy_StalkPause
	dc.w	$004E
	dc.w	$0000
	dc.w	$0001
	dc.b	$00
	dc.b	$07
	dc.b	$00, $96, $00, $06, $00, $08, $00, $16 
	dc.l	$00000180
	dc.b	$00
	dc.b	$02
; loc_000247D2
EnemyData_StalkPause_7B:
	dc.l	InitEnemy_StalkPause
	dc.w	$007B
	dc.w	$0001
	dc.w	$060E
	dc.b	$00
	dc.b	$07
	dc.b	$04, $B0, $00, $3C, $02, $10, $07, $10 
	dc.l	$00000200
	dc.b	$00
	dc.b	$02
; loc_000247EC
EnemyData_StalkPause_7C:
	dc.l	InitEnemy_StalkPause
	dc.w	$007C
	dc.w	$0001
	dc.w	$1036
	dc.b	$00
	dc.b	$07
	dc.b	$05, $DC, $00, $4E, $02, $77, $01, $15 
	dc.l	$00000260
	dc.b	$00
	dc.b	$02
; loc_00024806
EnemyData_StalkPause_7D:
	dc.l	InitEnemy_StalkPause
	dc.w	$007D
	dc.w	$0001
	dc.w	$0410
	dc.b	$00
	dc.b	$07
	dc.b	$08, $98, $00, $63, $04, $41, $01, $61 
	dc.l	$0000012C
	dc.b	$00
	dc.b	$02
; loc_00024820
EnemyData_StandardMelee_4D:
	dc.l	InitEnemy_StandardMelee
	dc.w	$004D
	dc.w	$0001
	dc.w	$1028
	dc.b	$00
	dc.b	$07
	dc.b	$00, $58, $00, $06, $00, $04, $00, $05 
	dc.l	$00000150
	dc.b	$00
	dc.b	$02
; loc_0002483A
EnemyData_StandardMelee_6C:
	dc.l	InitEnemy_StandardMelee
	dc.w	$006C
	dc.w	$0001
	dc.w	$0816
	dc.b	$00
	dc.b	$07
	dc.b	$01, $8F, $00, $1E, $00, $42, $00, $20 
	dc.l	$00000165
	dc.b	$00
	dc.b	$02
; loc_00024854
EnemyData_StandardMelee_6D:
	dc.l	InitEnemy_StandardMelee
	dc.w	$006D
	dc.w	$0001
	dc.w	$102A
	dc.b	$00
	dc.b	$07
	dc.b	$02, $58, $00, $36, $02, $06, $00, $68 
	dc.l	$00000180
	dc.b	$00
	dc.b	$02
; loc_0002486E
EnemyData_StandardMelee_6E:
	dc.l	InitEnemy_StandardMelee
	dc.w	$006E
	dc.w	$0001
	dc.w	$1032
	dc.b	$00
	dc.b	$07
	dc.b	$05, $FA, $00, $62, $02, $84, $01, $09 
	dc.l	$00000195
	dc.b	$00
	dc.b	$02
; loc_00024888
EnemyData_FleeChase_5B:
	dc.l	InitEnemy_FleeChase
	dc.w	$005B
	dc.w	$FFFF
	dc.w	$0000
	dc.b	$00
	dc.b	$07
	dc.b	$00, $64, $00, $0C, $00, $10, $00, $09 
	dc.l	$00000200
	dc.b	$00
	dc.b	$02
; loc_000248A2
EnemyData_FleeChase_6F:
	dc.l	InitEnemy_FleeChase
	dc.w	$006F
	dc.w	$0000
	dc.w	$0000
	dc.b	$00
	dc.b	$07
	dc.b	$00, $AA, $00, $27, $00, $77, $00, $27 
	dc.l	$00000220
	dc.b	$00
	dc.b	$02
; loc_000248BC
EnemyData_FleeChase_70:
	dc.l	InitEnemy_FleeChase
	dc.w	$0070
	dc.w	$0000
	dc.w	$001B
	dc.b	$00
	dc.b	$07
	dc.b	$02, $E4, $00, $46, $02, $12, $01, $31 
	dc.l	$00000260
	dc.b	$00
	dc.b	$02
; loc_000248D6
EnemyData_FleeChase_71:
	dc.l	InitEnemy_FleeChase
	dc.w	$0071
	dc.w	$0000
	dc.w	$0024
	dc.b	$00
	dc.b	$07
	dc.b	$04, $4C, $00, $78, $03, $16, $01, $80 
	dc.l	$00000300
	dc.b	$00
	dc.b	$02
; loc_000248F0
EnemyData_ProjectileFire_63:
	dc.l	InitEnemy_ProjectileFire
	dc.w	$0063
	dc.w	$FFFF
	dc.w	$0000
	dc.b	$00
	dc.b	$07
	dc.b	$00, $3A, $00, $1D, $00, $17, $00, $11 
	dc.l	$00000190
	dc.b	$00
	dc.b	$0A
; loc_0002490A
EnemyData_ProjectileFire_A4:
	dc.l	InitEnemy_ProjectileFire
	dc.w	$00A4
	dc.w	$0000
	dc.w	$001B
	dc.b	$00
	dc.b	$07
	dc.b	$00, $D2, $00, $32, $01, $52, $00, $23 
	dc.l	$00000230
	dc.b	$00
	dc.b	$0A
; loc_00024924
EnemyData_ProjectileFire_A5:
	dc.l	InitEnemy_ProjectileFire
	dc.w	$00A5
	dc.w	$0000
	dc.w	$001C
	dc.b	$00
	dc.b	$07
	dc.b	$01, $EA, $00, $3C, $02, $49, $00, $68 
	dc.l	$00000250
	dc.b	$00
	dc.b	$0A
; loc_0002493E
EnemyData_ProjectileFire_A6:
	dc.l	InitEnemy_ProjectileFire
	dc.w	$00A6
	dc.w	$0000
	dc.w	$0029
	dc.b	$00
	dc.b	$07
	dc.b	$04, $CE, $00, $5E, $03, $29, $02, $47 
	dc.l	$00000300
	dc.b	$00
	dc.b	$0A
; loc_00024958
EnemyData_ProximityChase_5C:
	dc.l	InitEnemy_ProximityChase
	dc.w	$005C
	dc.w	$FFFF
	dc.w	$0000
	dc.b	$00
	dc.b	$07
	dc.b	$00, $64, $00, $24, $00, $31, $00, $15 
	dc.l	$00000200
	dc.b	$00
	dc.b	$06
; loc_00024972
EnemyData_ProximityChase_9E:
	dc.l	InitEnemy_ProximityChase
	dc.w	$009E
	dc.w	$0000
	dc.w	$001B
	dc.b	$00
	dc.b	$07
	dc.b	$01, $C2, $00, $6D, $02, $43, $01, $07 
	dc.l	$00000220
	dc.b	$00
	dc.b	$06
; loc_0002498C
EnemyData_ProximityChase_9F:
	dc.l	InitEnemy_ProximityChase
	dc.w	$009F
	dc.w	$0000
	dc.w	$0027
	dc.b	$00
	dc.b	$07
	dc.b	$02, $76, $00, $F4, $04, $22, $01, $54 
	dc.l	$00000240
	dc.b	$00
	dc.b	$06
; loc_000249A6
EnemyData_ProximityChase_A0:
	dc.l	InitEnemy_ProximityChase
	dc.w	$00A0
	dc.w	$0000
	dc.w	$0020
	dc.b	$00
	dc.b	$07
	dc.b	$03, $16, $00, $B4, $04, $55, $02, $76 
	dc.l	$00000280
	dc.b	$00
	dc.b	$06
; loc_000249C0
EnemyData_StandardMeleeAlt_5D:
	dc.l	InitEnemy_StandardMeleeAlt
	dc.w	$005D
	dc.w	$FFFF
	dc.w	$0000
	dc.b	$00
	dc.b	$07
	dc.b	$01, $72, $00, $42, $00, $85, $00, $40 
	dc.l	$00000180
	dc.b	$00
	dc.b	$02
; loc_000249DA
EnemyData_StandardMeleeAlt_A1:
	dc.l	InitEnemy_StandardMeleeAlt
	dc.w	$00A1
	dc.w	$0001
	dc.w	$0402
	dc.b	$00
	dc.b	$07
	dc.b	$03, $48, $00, $52, $01, $73, $00, $65 
	dc.l	$00000190
	dc.b	$00
	dc.b	$02
; loc_000249F4
EnemyData_StandardMeleeAlt_A2:
	dc.l	InitEnemy_StandardMeleeAlt
	dc.w	$00A2
	dc.w	$0000
	dc.w	$0003
	dc.b	$00
	dc.b	$07
	dc.b	$03, $84, $00, $52, $02, $34, $01, $05 
	dc.l	$00000200
	dc.b	$00
	dc.b	$02
; loc_00024A0E
EnemyData_StandardMeleeAlt_A3:
	dc.l	InitEnemy_StandardMeleeAlt
	dc.w	$00A3
	dc.w	$0001
	dc.w	$0819
	dc.b	$00
	dc.b	$07
	dc.b	$05, $C8, $00, $AD, $04, $37, $03, $60 
	dc.l	$00000210
	dc.b	$00
	dc.b	$06
; loc_00024A28
EnemyData_StalkPauseAlt_64:
	dc.l	InitEnemy_StalkPauseAlt
	dc.w	$0064
	dc.w	$0000
	dc.w	$001B
	dc.b	$00
	dc.b	$07
	dc.b	$02, $1D, $00, $26, $02, $24, $00, $37 
	dc.l	$00000080
	dc.b	$01
	dc.b	$02
; loc_00024A42
EnemyData_StalkPauseAlt_B9:
	dc.l	InitEnemy_StalkPauseAlt
	dc.w	$00B9
	dc.w	$0000
	dc.w	$001F
	dc.b	$00
	dc.b	$07
	dc.b	$05, $50, $00, $39, $03, $18, $00, $67 
	dc.l	$00000120
	dc.b	$01
	dc.b	$02
; loc_00024A5C
EnemyData_StalkPauseAlt_BA:
	dc.l	InitEnemy_StalkPauseAlt
	dc.w	$00BA
	dc.w	$0000
	dc.w	$001C
	dc.b	$00
	dc.b	$07
	dc.b	$08, $AC, $00, $56, $03, $51, $00, $99 
	dc.l	$00000140
	dc.b	$01
	dc.b	$02
; loc_00024A76
EnemyData_StalkPauseAlt_BB:
	dc.l	InitEnemy_StalkPauseAlt
	dc.w	$00BB
	dc.w	$0000
	dc.w	$002A
	dc.b	$00
	dc.b	$07
	dc.b	$0D, $34, $00, $6A, $04, $37, $01, $30 
	dc.l	$00000160
	dc.b	$01
	dc.b	$06
; loc_00024A90
EnemyData_HumanoidMelee_65:
	dc.l	InitEnemy_IntermittentChase_Random
	dc.w	$0065
	dc.w	$0001
	dc.w	$1028
	dc.b	$00
	dc.b	$07
	dc.b	$05, $DC, $00, $5C, $01, $69, $00, $63 
	dc.l	$00000110
	dc.b	$00
	dc.b	$02
; loc_00024AAA
EnemyData_HumanoidMelee_A7:
	dc.l	InitEnemy_IntermittentChase_Random
	dc.w	$00A7
	dc.w	$0001
	dc.w	$102A
	dc.b	$00
	dc.b	$07
	dc.b	$0A, $28, $00, $8D, $04, $58, $01, $10 
	dc.l	$00000150
	dc.b	$00
	dc.b	$02
; loc_00024AC4
EnemyData_HumanoidMeleeAlt_A8:
	dc.l	InitEnemy_IntermittentChase_Homing
	dc.w	$00A8
	dc.w	$0001
	dc.w	$081E
	dc.b	$00
	dc.b	$07
	dc.b	$0E, $10, $00, $A0, $05, $01, $01, $35 
	dc.l	$00000170
	dc.b	$00
	dc.b	$0E
; loc_00024ADE
EnemyData_HumanoidMeleeAlt_A9:
	dc.l	InitEnemy_IntermittentChase_Homing
	dc.w	$00A9
	dc.w	$0001
	dc.w	$002A
	dc.b	$00
	dc.b	$07
	dc.b	$0F, $A0, $00, $B4, $06, $00, $02, $50 
	dc.l	$00000300
	dc.b	$00
	dc.b	$02
; loc_00024AF8
EnemyData_RandomShooter_66:
	dc.l	InitEnemy_RandomShooter
	dc.w	$0066
	dc.w	$FFFF
	dc.w	$0000
	dc.b	$00
	dc.b	$07
	dc.b	$01, $23, $00, $1E, $00, $25, $00, $13 
	dc.l	$00000180
	dc.b	$00
	dc.b	$08
; loc_00024B12
EnemyData_RandomShooter_AA:
	dc.l	InitEnemy_RandomShooter
	dc.w	$00AA
	dc.w	$0000
	dc.w	$0002
	dc.b	$00
	dc.b	$07
	dc.b	$02, $58, $00, $40, $02, $03, $00, $70 
	dc.l	$00000200
	dc.b	$00
	dc.b	$0C
; loc_00024B2C
EnemyData_RandomShooter_AB:
	dc.l	InitEnemy_RandomShooter
	dc.w	$00AB
	dc.w	$0000
	dc.w	$0002
	dc.b	$00
	dc.b	$07
	dc.b	$03, $5C, $00, $63, $02, $33, $00, $99 
	dc.l	$00000220
	dc.b	$00
	dc.b	$0C
; loc_00024B46
EnemyData_RandomShooter_BC:
	dc.l	InitEnemy_RandomShooter
	dc.w	$00BC
	dc.w	$0002
	dc.w	$0207
	dc.b	$00
	dc.b	$07
	dc.b	$04, $9C, $00, $97, $03, $01, $01, $40 
	dc.l	$00000240
	dc.b	$00
	dc.b	$0C
; loc_00024B60
EnemyData_StandardMeleeFast_61:
	dc.l	InitEnemy_StandardMeleeFast
	dc.w	$0061
	dc.w	$0001
	dc.w	$102C
	dc.b	$00
	dc.b	$07
	dc.b	$04, $B0, $00, $18, $00, $90, $00, $33 
	dc.l	$00000120
	dc.b	$01
	dc.b	$02
; loc_00024B7A
EnemyData_StandardMeleeFast_BD:
	dc.b	$00, $00, $95, $28, $00, $BD, $00, $01, $10, $2D, $00, $07, $08, $98, $00, $31, $02, $08, $00, $68, $00, $00, $01, $60, $01, $02 
; loc_00024B94
EnemyData_StandardMeleeFast_BE:
	dc.l	InitEnemy_StandardMeleeFast
	dc.w	$00BE
	dc.w	$0001
	dc.w	$0028
	dc.b	$00
	dc.b	$07
	dc.b	$0B, $B8, $00, $61, $03, $66, $01, $45 
	dc.l	$00000200
	dc.b	$01
	dc.b	$02
; loc_00024BAE
EnemyData_StandardMeleeFast_BF:
	dc.l	InitEnemy_StandardMeleeFast
	dc.w	$00BF
	dc.w	$0001
	dc.w	$002B
	dc.b	$00
	dc.b	$07
	dc.b	$11, $F8, $00, $93, $04, $52, $02, $09 
	dc.l	$00000220
	dc.b	$01
	dc.b	$02
; loc_00024BC8
EnemyData_OrbShield_75:
	dc.l	InitBoss_OrbShield
	dc.w	$0075
	dc.w	$0000
	dc.w	$001B
	dc.b	$01
	dc.b	$03
	dc.b	$00, $70, $00, $1E, $00, $76, $00, $38 
	dc.l	$00000160
	dc.b	$00
	dc.b	$02
; loc_00024BE2
EnemyData_OrbShield_C0:
	dc.l	InitBoss_OrbShield
	dc.w	$00C0
	dc.w	$0000
	dc.w	$001B
	dc.b	$03
	dc.b	$01
	dc.b	$01, $72, $00, $52, $01, $92, $00, $68 
	dc.l	$00000180
	dc.b	$00
	dc.b	$02
; loc_00024BFC
EnemyData_OrbShield_C1:
	dc.l	InitBoss_OrbShield
	dc.w	$00C1
	dc.w	$0000
	dc.w	$001C
	dc.b	$03
	dc.b	$01
	dc.b	$05, $FA, $00, $6C, $03, $02, $01, $36 
	dc.l	$00000200
	dc.b	$00
	dc.b	$02
; loc_00024C16
EnemyData_OrbShield_C2:
	dc.l	InitBoss_OrbShield
	dc.w	$00C2
	dc.w	$0000
	dc.w	$0020
	dc.b	$03
	dc.b	$01
	dc.b	$08, $98, $00, $8C, $09, $25, $01, $72 
	dc.l	$00000220
	dc.b	$00
	dc.b	$02
; loc_00024C30
EnemyData_BurstFire_63:
	dc.l	InitEnemy_BurstFire
	dc.w	$0063
	dc.w	$0000
	dc.w	$0000
	dc.b	$03
	dc.b	$01
	dc.b	$00, $96, $00, $49, $00, $57, $00, $26 
	dc.l	$00000200
	dc.b	$00
	dc.b	$0A
; loc_00024C4A
EnemyData_BurstFire_A4:
	dc.l	InitEnemy_BurstFire
	dc.w	$00A4
	dc.w	$0000
	dc.w	$001D
	dc.b	$03
	dc.b	$01
	dc.b	$01, $72, $00, $6B, $02, $13, $00, $72 
	dc.l	$00000220
	dc.b	$00
	dc.b	$0A
; loc_00024C64
EnemyData_BurstFire_A5:
	dc.l	InitEnemy_BurstFire
	dc.w	$00A5
	dc.w	$0003
	dc.w	$3000
	dc.b	$03
	dc.b	$01
	dc.b	$02, $58, $00, $9C, $03, $19, $01, $52 
	dc.l	$00000240
	dc.b	$00
	dc.b	$0A
; loc_00024C7E
EnemyData_BurstFire_A6:
	dc.l	InitEnemy_BurstFire
	dc.w	$00A6
	dc.w	$FFFF
	dc.w	$0002
	dc.b	$03
	dc.b	$01
	dc.b	$06, $A4, $00, $B1, $04, $72, $02, $06 
	dc.l	$00000260
	dc.b	$00
	dc.b	$0A
; loc_00024C98
EnemyData_StalkPause3_64:
	dc.l	InitEnemy_StationaryShooter
	dc.w	$0064
	dc.w	$0000
	dc.w	$001B
	dc.b	$00
	dc.b	$07
	dc.b	$01, $E0, $00, $39, $03, $33, $00, $39 
	dc.l	$00000180
	dc.b	$01
	dc.b	$02
; loc_00024CB2
EnemyData_StationaryShooter_B9:
	dc.b	$00, $00, $9D, $90, $00, $B9, $00, $00, $00, $03, $00, $07, $03, $48, $00, $4D, $04, $16, $00, $70, $00, $00, $02, $00, $01, $02 
; loc_00024CCC
EnemyData_StalkPause3_BA:
	dc.l	InitEnemy_StationaryShooter
	dc.w	$00BA
	dc.w	$0000
	dc.w	$001C
	dc.b	$00
	dc.b	$07
	dc.b	$03, $FC, $00, $6C, $04, $72, $01, $13 
	dc.l	$00000220
	dc.b	$01
	dc.b	$02
; loc_00024CE6
EnemyData_StalkPause3_BB:
	dc.l	InitEnemy_StationaryShooter
	dc.w	$00BB
	dc.w	$0003
	dc.w	$3000
	dc.b	$00
	dc.b	$07
	dc.b	$04, $F6, $00, $97, $06, $18, $01, $43 
	dc.l	$00000240
	dc.b	$01
	dc.b	$02
; loc_00024D00
EnemyData_FastBurstShooter_64:
	dc.l	InitEnemy_FastBurstShooter
	dc.w	$0064
	dc.w	$0003
	dc.w	$0500
	dc.b	$03
	dc.b	$01
	dc.b	$03, $98, $00, $39, $02, $67, $00, $52 
	dc.l	$00000180
	dc.b	$01
	dc.b	$02
; loc_00024D1A
EnemyData_FastBurstShooter_B9:
	dc.l	InitEnemy_FastBurstShooter
	dc.w	$00B9
	dc.w	$0000
	dc.w	$001C
	dc.b	$03
	dc.b	$01
	dc.b	$05, $78, $00, $48, $03, $21, $00, $95 
	dc.l	$00000180
	dc.b	$01
	dc.b	$02
; loc_00024D34
EnemyData_FastBurstShooter_BA:
	dc.l	InitEnemy_FastBurstShooter
	dc.w	$00BA
	dc.w	$0000
	dc.w	$002B
	dc.b	$03
	dc.b	$01
	dc.b	$07, $03, $00, $5C, $04, $14, $01, $29 
	dc.l	$00000180
	dc.b	$01
	dc.b	$02
; loc_00024D4E
EnemyData_FastBurstShooter_BB:
	dc.b	$00, $00, $A6, $AA, $00, $BB, $00, $00, $00, $20, $03, $01, $0A, $8C, $00, $75, $05, $44, $01, $82, $00, $00, $01, $80, $01, $02 
; loc_00024D68
EnemyData_HomingShooter_64:
	dc.l	InitEnemy_HomingShooter
	dc.w	$0064
	dc.w	$0000
	dc.w	$001B
	dc.b	$03
	dc.b	$01
	dc.b	$03, $98, $00, $3A, $03, $95, $00, $70 
	dc.l	$00000180
	dc.b	$01
	dc.b	$02
; loc_00024D82
EnemyData_HomingShooter_B9:
	dc.l	InitEnemy_HomingShooter
	dc.w	$00B9
	dc.w	$0000
	dc.w	$0021
	dc.b	$03
	dc.b	$01
	dc.b	$04, $4C, $00, $4A, $04, $41, $00, $93 
	dc.l	$00000220
	dc.b	$01
	dc.b	$02
; loc_00024D9C
EnemyData_HomingShooter_BA:
	dc.l	InitEnemy_HomingShooter
	dc.w	$00BA
	dc.w	$0000
	dc.w	$001C
	dc.b	$03
	dc.b	$01
	dc.b	$06, $40, $00, $63, $05, $24, $01, $56 
	dc.l	$00000260
	dc.b	$01
	dc.b	$02
; loc_00024DB6
EnemyData_HomingShooter_BB:
	dc.l	InitEnemy_HomingShooter
	dc.w	$00BB
	dc.w	$0000
	dc.w	$0026
	dc.b	$03
	dc.b	$01
	dc.b	$07, $6C, $00, $79, $06, $57, $06, $09 
	dc.l	$00000300
	dc.b	$01
	dc.b	$02
; loc_00024DD0
EnemyData_Teleporter_66:
	dc.l	InitEnemy_Teleporter
	dc.w	$0066
	dc.w	$0000
	dc.w	$0001
	dc.b	$00
	dc.b	$07
	dc.b	$00, $DE, $00, $29, $00, $94, $00, $43 
	dc.l	$00000250
	dc.b	$00
	dc.b	$08
; loc_00024DEA
EnemyData_Teleporter_AA:
	dc.l	InitEnemy_Teleporter
	dc.w	$00AA
	dc.w	$FFFF
	dc.w	$0000
	dc.b	$00
	dc.b	$07
	dc.b	$01, $86, $00, $68, $02, $15, $00, $90 
	dc.l	$00000300
	dc.b	$00
	dc.b	$0C
; loc_00024E04
EnemyData_Teleporter_AB:
	dc.l	InitEnemy_Teleporter
	dc.w	$00AB
	dc.w	$0003
	dc.w	$1000
	dc.b	$00
	dc.b	$07
	dc.b	$01, $FE, $00, $80, $02, $60, $01, $20 
	dc.l	$00000350
	dc.b	$00
	dc.b	$0C
; loc_00024E1E
EnemyData_Teleporter_BC:
	dc.l	InitEnemy_Teleporter
	dc.w	$00BC
	dc.w	$0002
	dc.w	$0205
	dc.b	$00
	dc.b	$07
	dc.b	$02, $76, $00, $BB, $04, $12, $01, $72 
	dc.l	$00000400
	dc.b	$00
	dc.b	$0C
; loc_00024E38
EnemyData_SequentialFire_66:
	dc.l	InitEnemy_SequentialFire
	dc.w	$0066
	dc.w	$0000
	dc.w	$0001
	dc.b	$03
	dc.b	$01
	dc.b	$03, $52, $00, $3E, $01, $83, $00, $67 
	dc.l	$00000160
	dc.b	$00
	dc.b	$08
; loc_00024E52
EnemyData_SequentialFire_AA:
	dc.l	InitEnemy_SequentialFire
	dc.w	$00AA
	dc.w	$0000
	dc.w	$0001
	dc.b	$03
	dc.b	$01
	dc.b	$04, $4C, $00, $4A, $02, $17, $01, $00 
	dc.l	$00000180
	dc.b	$00
	dc.b	$0C
; loc_00024E6C
EnemyData_SequentialFire_AB:
	dc.l	InitEnemy_SequentialFire
	dc.w	$00AB
	dc.w	$0000
	dc.w	$0002
	dc.b	$03
	dc.b	$01
	dc.b	$05, $FA, $00, $6C, $02, $93, $01, $33 
	dc.l	$00000200
	dc.b	$00
	dc.b	$0C
; loc_00024E86
EnemyData_SequentialFire_BC:
	dc.l	InitEnemy_SequentialFire
	dc.w	$00BC
	dc.w	$0003
	dc.w	$1000
	dc.b	$03
	dc.b	$01
	dc.b	$06, $B8, $00, $C8, $06, $18, $02, $20 
	dc.l	$00000220
	dc.b	$00
	dc.b	$04
; loc_00024EA0
EnemyData_MultiOrb_75:
	dc.l	InitBoss_MultiOrb
	dc.w	$0075
	dc.w	$0000
	dc.w	$0000
	dc.b	$03
	dc.b	$01
	dc.b	$02, $BC, $00, $24, $01, $04, $00, $45 
	dc.l	$00000180
	dc.b	$00
	dc.b	$02
; loc_00024EBA
EnemyData_MultiOrb_C0:
	dc.l	InitBoss_MultiOrb
	dc.w	$00C0
	dc.w	$0000
	dc.w	$001C
	dc.b	$03
	dc.b	$01
	dc.b	$04, $B0, $00, $54, $02, $19, $00, $93 
	dc.l	$00000185
	dc.b	$00
	dc.b	$02
; loc_00024ED4
EnemyData_MultiOrb_C1:
	dc.l	InitBoss_MultiOrb
	dc.w	$00C1
	dc.w	$0000
	dc.w	$001B
	dc.b	$03
	dc.b	$01
	dc.b	$06, $A4, $00, $82, $03, $61, $01, $58 
	dc.l	$00000190
	dc.b	$00
	dc.b	$02
; loc_00024EEE
EnemyData_MultiOrb_C2:
	dc.l	InitBoss_MultiOrb
	dc.w	$00C2
	dc.w	$0000
	dc.w	$001C
	dc.b	$03
	dc.b	$01
	dc.b	$08, $FC, $00, $8D, $04, $51, $01, $97 
	dc.l	$00000195
	dc.b	$00
	dc.b	$06
; loc_00024F08
EnemyData_OrbRing_75:
	dc.l	InitBoss_OrbRing
	dc.w	$0075
	dc.w	$0000
	dc.w	$001B
	dc.b	$03
	dc.b	$01
	dc.b	$03, $0C, $00, $2F, $01, $41, $00, $50 
	dc.l	$00000180
	dc.b	$00
	dc.b	$02
; loc_00024F22
EnemyData_OrbRing_C0:
	dc.l	InitBoss_OrbRing
	dc.w	$00C0
	dc.w	$0000
	dc.w	$001C
	dc.b	$03
	dc.b	$01
	dc.b	$05, $DC, $00, $62, $02, $69, $01, $23 
	dc.l	$00000200
	dc.b	$00
	dc.b	$02
; loc_00024F3C
EnemyData_OrbRing_C1:
	dc.l	InitBoss_OrbRing
	dc.w	$00C1
	dc.w	$0003
	dc.w	$5000
	dc.b	$03
	dc.b	$01
	dc.b	$09, $88, $00, $72, $03, $74, $01, $68 
	dc.l	$00000220
	dc.b	$00
	dc.b	$02
; loc_00024F56
EnemyData_OrbRing_C2:
	dc.l	InitBoss_OrbRing
	dc.w	$00C2
	dc.w	$0000
	dc.w	$0027
	dc.b	$03
	dc.b	$01
	dc.b	$0A, $8C, $00, $A8, $05, $12, $03, $90 
	dc.l	$00000240
	dc.b	$00
	dc.b	$0A
; loc_00024F70
EnemyData_SpiralBurst_A6a:
	dc.l	InitEnemy_SpiralBurst
	dc.w	$00A6
	dc.w	$0000
	dc.w	$0029
	dc.b	$01
	dc.b	$03
	dc.b	$06, $A4, $00, $9D, $04, $72, $02, $06 
	dc.l	$00000260
	dc.b	$00
	dc.b	$0A
; loc_00024F8A
EnemyData_SpiralBurst_A6b:
	dc.l	InitEnemy_SpiralBurst
	dc.w	$00A6
	dc.w	$0000
	dc.w	$0020
	dc.b	$01
	dc.b	$00
	dc.b	$06, $A4, $00, $C8, $04, $72, $02, $06 
	dc.l	$00000360
	dc.b	$00
	dc.b	$0E
; loc_00024FA4
EnemyData_StalkPause_7B_Last:
	dc.l	InitEnemy_StalkPause
	dc.w	$007B
	dc.w	$0003
	dc.w	$3000
	dc.b	$00
	dc.b	$04, $04, $B0, $00, $64, $00, $00, $12, $00 
	dc.l	$00000190
	dc.b	$00
	dc.b	$0E
; loc_00024FBE
EnemySpriteSet_A:
	dc.l	EnemyGfxFrameTable_DragonChild
	dc.l	EnemyGfxData_DragonChild
	dc.b	$00, $6B 
	dc.l	EnemyGfxFrameTable_DragonMain
	dc.l	EnemyGfxData_DragonMain
	dc.b	$00, $47 
	dc.l	$00000000
; loc_00024FD6
EnemySpriteSet_B:
	dc.l	EnemyGfxFrameTable_QuadrupedChild
	dc.l	EnemyGfxData_QuadrupedChild
	dc.b	$00, $6B 
	dc.l	EnemyGfxFrameTable_QuadrupedMain
	dc.l	EnemyGfxData_QuadrupedMain
	dc.b	$00, $47 
	dc.l	$00000000
; loc_00024FEE
EnemySpriteSet_C:
	dc.l	EnemyGfxFrameTable_OrbChild
	dc.l	EnemyGfxData_OrbChild
	dc.b	$00, $2F 
	dc.l	EnemyGfxFrameTable_OrbMain
	dc.l	EnemyGfxData_OrbMain
	dc.b	$00, $47 
	dc.l	$00000000
; loc_00025006
EnemySpriteSet_D:
	dc.l	EnemyGfxFrameTable_SerpentChild
	dc.l	EnemyGfxData_SerpentChild
	dc.b	$00, $6B 
	dc.l	EnemyGfxFrameTable_SerpentMain
	dc.l	EnemyGfxData_SerpentMain
	dc.b	$00, $47 
	dc.l	$00000000
; loc_0002501E
EnemySpriteSet_E:
	dc.l	EnemyGfxFrameTable_InsectChild
	dc.l	EnemyGfxData_InsectChild
	dc.b	$00, $77 
	dc.l	EnemyGfxFrameTable_InsectMain
	dc.l	EnemyGfxData_InsectMain
	dc.b	$00, $4F 
	dc.l	$00000000
; loc_00025036
EnemySpriteSet_F:
	dc.l	EnemyGfxFrameTable_GolemChild
	dc.l	EnemyGfxData_GolemChild
	dc.b	$00, $6B 
	dc.l	EnemyGfxFrameTable_GolemMain
	dc.l	EnemyGfxData_GolemMain
	dc.b	$00, $6B 
	dc.l	$00000000
; loc_0002504E
EnemySpriteSet_G:
	dc.l	EnemyGfxFrameTable_GargoyleChild
	dc.l	EnemyGfxData_GargoyleChild
	dc.b	$00, $6B 
	dc.l	EnemyGfxFrameTable_GargoyleMain
	dc.l	EnemyGfxData_GargoyleMain
	dc.b	$00, $47 
	dc.l	$00000000
; loc_00025066
EnemySpriteSet_H:
	dc.l	EnemyGfxFrameTable_WorldMapChild
	dc.l	EnemyGfxData_WorldMapChild
	dc.b	$00, $6B 
	dc.l	EnemyGfxFrameTable_WorldMapMain
	dc.l	EnemyGfxData_WorldMapMain
	dc.b	$00, $6B 
	dc.l	MenuTileGfxDescriptor_5A32E
	dc.l	MenuTileGfxPointerTable_5A3AE
	dc.b	$00, $05 
; loc_00025084
EnemySpriteSet_I:
	dc.l	EnemyGfxFrameTable_BeastChild
	dc.l	EnemyGfxData_BeastChild
	dc.b	$00, $6B 
	dc.l	EnemyGfxFrameTable_BeastMain
	dc.l	EnemyGfxData_BeastMain
	dc.b	$00, $47 
	dc.l	MenuTileGfxDescriptor_5A32E
	dc.l	MenuTileGfxPointerTable_5A3AE
	dc.b	$00, $05 
; loc_000250A2
EnemySpriteSet_J:
	dc.l	EnemyGfxFrameTable_SkeletonChild
	dc.l	EnemyGfxData_SkeletonChild
	dc.b	$00, $6B 
	dc.l	EnemyGfxFrameTable_SkeletonMain
	dc.l	EnemyGfxData_SkeletonMain
	dc.b	$00, $47 
	dc.l	$00000000
; loc_000250BA
EnemySpriteSet_K:
	dc.l	EnemyGfxFrameTable_HumanoidChild
	dc.l	EnemyGfxData_HumanoidChild
	dc.b	$00, $3B 
	dc.l	EnemyGfxFrameTable_HumanoidMain
	dc.l	EnemyGfxData_HumanoidMain
	dc.b	$00, $27 
	dc.l	$00000000
; loc_000250D2
EnemySpriteSet_L:
	dc.l	EnemyGfxFrameTable_HumanoidChild
	dc.l	EnemyGfxData_HumanoidChild
	dc.b	$00, $3B 
	dc.l	EnemyGfxFrameTable_HumanoidMain
	dc.l	EnemyGfxData_HumanoidMain
	dc.b	$00, $27 
	dc.l	EnemySpriteSet_L_Gfx_5D1E4
	dc.l	EnemySpriteSet_L_Gfx_5D286
	dc.b	$00, $05 
; loc_000250F0
EnemySpriteSet_M:
	dc.l	EnemyGfxFrameTable_BossMain
	dc.l	EnemyGfxData_BossMain
	dc.b	$00, $2F 
	dc.l	EnemyGfxFrameTable_HumanoidMain
	dc.l	EnemyGfxData_HumanoidMain
	dc.b	$00, $27 
	dc.l	EnemySpriteSet_M_Gfx_5D764
	dc.l	EnemySpriteSet_M_Gfx_5D798
	dc.b	$00, $01 