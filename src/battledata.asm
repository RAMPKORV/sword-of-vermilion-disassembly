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
EnemySpriteFrameDataA_00:
	dc.b	$0A, $0A, $00, $21, $04, $14, $01, $02, $0A, $0A, $00, $2A, $0A, $0A, $00, $33, $0A, $0A, $00, $3C, $05, $0A, $00, $F6 
EnemySpriteFrameDataA_01:
	dc.b	$00, $45, $01, $06, $00, $4E, $00, $57, $00, $60, $00, $F6 
EnemySpriteFrameDataA_02:
	dc.b	$00, $69, $01, $06, $00, $72, $00, $7B, $00, $84, $00, $F6 
EnemySpriteFrameDataA_03:
	dc.b	$0A, $09, $00, $8D, $0A, $09, $00, $96, $0A, $09, $00, $9F 
EnemySpriteFrameDataA_04:
	dc.b	$00, $A8, $00, $B1, $00, $BA 
EnemySpriteFrameDataA_05:
	dc.b	$00, $C3, $00, $CC, $00, $D5 
EnemySpriteFrameDataA_06:
	dc.b	$05, $C8, $00, $FE, $05, $C8, $00, $FA, $0E, $C8, $01, $2C 
EnemySpriteFrameDataA_07:
	dc.b	$00, $F0, $00, $A0, $00, $F0, $00, $90, $00, $E8, $00, $B8 
EnemySpriteFrameDataA_08:
	dc.b	$0E, $08, $01, $08, $0D, $08, $00, $DE 
EnemySpriteFrameDataA_09:
	dc.b	$0E, $07, $01, $08, $0D, $07, $00, $DE 
EnemySpriteFrameDataA_0A:
	dc.b	$0E, $06, $01, $08, $0D, $06, $00, $DE 
EnemySpriteFrameDataA_0B:
	dc.b	$01, $14, $00, $E6 
EnemySpriteFrameDataA_0C:
	dc.b	$01, $20, $00, $EE 
EnemySpriteFrameDataA_0D:
	dc.b	$00, $00, $FF, $E8 
EnemySpriteFrameDataA_0E:
	dc.b	$00, $00, $FF, $E8 
EnemySpriteFrameDataA_0F:
	dc.b	$00, $00, $FF, $E8 
EnemySpriteFrameDataA_10:
	dc.b	$00, $24, $FF, $F4, $00, $18, $00, $00, $00, $30, $FF, $F0, $00, $30, $00, $08, $00, $44, $FF, $F8 
EnemySpriteFrameDataA_11:
	dc.b	$00, $18, $00, $00, $00, $30, $FF, $FA 
EnemySpriteFrameDataA_12:
	dc.b	$01, $06, $01, $02, $01, $02, $01, $02, $01, $02, $01, $02, $01, $04, $01, $06 
EnemySpriteLayoutPtrsA:
	dc.l	EnemySpriteLayoutA_Frame0
	dc.l	EnemySpriteLayoutA_Frame1
	dc.l	EnemySpriteLayoutA_Frame2
	dc.l	EnemySpriteLayoutA_Frame3
EnemySpritePositionPtrsA:
	dc.l	EnemySpritePositionA_Frame0
	dc.l	EnemySpritePositionA_Frame1
	dc.l	EnemySpritePositionA_Frame23
	dc.l	EnemySpritePositionA_Frame23
EnemySpriteLayoutA_Frame0:
	dc.l	$0B0A0045	
	dc.l	$0B0A0099	
	dc.l	$050A00B5	
	dc.l	$050A00C5	
EnemySpriteLayoutA_Frame1:
	dc.l	$0B0A0045	
	dc.l	$0B0A008D	
	dc.l	$050A00B1	
	dc.l	$050A00C1	
EnemySpriteLayoutA_Frame2:
	dc.l	$0B0A0045	
	dc.l	$0A0A012B	
	dc.l	$0A0A0122	
	dc.l	$050A00BD	
EnemySpriteLayoutA_Frame3:
	dc.l	$0B0A0051	
	dc.l	$0A0A013D	
	dc.l	$0A0A0134	
	dc.l	$050A00BD	
EnemySpritePositionA_Frame0:
	dc.l	$00CD008A	
	dc.l	$00BD009E	
	dc.l	$00B900AE	
	dc.l	$00D1008E	
EnemySpritePositionA_Frame1:
	dc.l	$00CD008A	
	dc.l	$00BD009E	
	dc.l	$00B900AE	
	dc.l	$00D1008E	
EnemySpritePositionA_Frame23:
	dc.l	$00CD008A	
	dc.l	$00BD0096	
	dc.l	$00A50096	
	dc.l	$00D1008E	
EnemySpriteLayoutPtrsB:
	dc.l	EnemySpriteLayoutB_Frame0
	dc.l	EnemySpriteLayoutB_Frame1
	dc.l	EnemySpriteLayoutB_Frame2
	dc.l	EnemySpriteLayoutB_Frame3
EnemySpritePositionPtrsB:
	dc.l	EnemySpritePositionB_Frame0
	dc.l	EnemySpritePositionB_Frame1
	dc.l	EnemySpritePositionB_Frame23
	dc.l	EnemySpritePositionB_Frame23
EnemySpriteLayoutB_Frame0:
	dc.l	$0B280021	
	dc.l	$0B280069	
	dc.l	$052800B9	
	dc.l	$052800F1	
EnemySpriteLayoutB_Frame1:
	dc.l	$0B28002D	
	dc.l	$0B2800A5	
	dc.l	$0A280146	
	dc.l	$052800F1	
EnemySpriteLayoutB_Frame2:
	dc.l	$0B280039	
	dc.l	$0B280081	
	dc.l	$0A280110	
	dc.l	$052800C9	
EnemySpriteLayoutB_Frame3:
	dc.l	$0B28005D	
	dc.l	$0B280075	
	dc.l	$0A280119	
	dc.l	$052800ED	
EnemySpritePositionB_Frame0:
	dc.l	$01050082	
	dc.l	$010700A2	
	dc.l	$010300B2	
	dc.l	loc_00000000	
EnemySpritePositionB_Frame1:
	dc.l	$01050082	
	dc.l	$010A00A2	
	dc.l	$010200B2	
	dc.l	loc_00000000	
EnemySpritePositionB_Frame23:
	dc.l	$01050082	
	dc.l	$010800A2	
	dc.l	$00F800B2	
	dc.l	$00F4009A	
BossSpriteLayoutData_A:
	dc.l	$0E140173	
	dc.l	$051400E5	
	dc.l	$051400E9	
BossSpriteLayoutData_B:
	dc.l	$018B017F	
	dc.l	$0173017F	
BossSpriteLayoutData_C:
	dc.l	$0A1E00F5	
	dc.l	$0E1E0197	
BossSpriteLayoutData_D:
	dc.l	$00F500FE	
	dc.l	$010700FE	
BossSpriteLayoutData_E:
	dc.l	$00CD00D1	
	dc.l	$00D500D9	
	dc.l	$00DD00D9	
	dc.l	$00D500D1	
BossSpriteLayoutData_F:
	dc.l	$014F0158	
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
EncounterSpriteList_Hydra:
	dc.b	$00, $02, $35, $76, $FF, $E4, $FF, $DC 
	dc.w	$FFD8
	dc.b	$00, $02, $35, $76, $FF, $F0, $FF, $B8 
	dc.w	$FFD8
	dc.b	$00, $02, $35, $76, $FF, $AC, $FF, $A8, $FF, $D8, $00, $02, $35, $76, $00, $0C, $FF, $D4, $00, $2C, $00, $02, $35, $76, $00, $18, $FF, $B0 
	dc.w	$002C
	dc.b	$00, $02, $35, $76, $FF, $C4, $FF, $A0, $00, $2C, $01, $9D, $05, $00, $FF, $F8, $00, $10, $00, $E7, $0A, $00, $FF, $F4, $00, $18, $01, $49, $0F, $00, $FF, $F0 
	dc.b	$00, $20, $01, $59, $0F, $00, $FF, $F0, $00, $20, $01, $69, $0F, $00, $FF, $F0, $00, $20, $FF, $FF 
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
BossTileData_Tsarkon:
	dc.b	$00, $57 
	dc.l	BossTileData_Tsarkon_Gfx_7DBF0
	dc.l	BossTileData_Tsarkon_Gfx_7EBF4
	dc.l	$00AF0058	
	dc.l	BossTileData_Tsarkon_Gfx_7EE3C
	dc.l	BossTileData_Tsarkon_Gfx_7F4FC
	dc.l	$0050FFFF	
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
BattleGfxData_FakeKing:
	dc.l	BattleGfxData_FakeKing_Gfx_6E652
	dc.b	$00, $E2 
	dc.l	BattlePaletteData_FakeKing
BattleGfxData_StowThief:
	dc.l	BattleGfxData_StowThief_Gfx_7182C
	dc.b	$00, $D1 
	dc.l	BattlePaletteData_StowThief
BattleGfxData_Null:
	dc.l	$00000000
	dc.b	$00, $00, $00, $00, $00, $00 
BattleGfxData_Excalabria:
	dc.l	BattleGfxData_Excalabria_Gfx_78138
	dc.b	$00, $C6 
	dc.l	BattlePaletteData_Excalabria
BattleGfxData_Tsarkon:
	dc.l	BattleGfxData_Tsarkon_Gfx_7F77A
	dc.b	$00, $DE 
	dc.l	BattlePaletteData_Tsarkon
BattlePaletteData_FakeKing:
	dc.l	$940E9330	
	dc.l	$96D09500	
	dc.l	$977F4000	
	dc.l	$00810000	
BattlePaletteData_StowThief:
	dc.l	$940D9320	
	dc.l	$96D09500	
	dc.l	$977F4000	
	dc.l	$00810000	
BattlePaletteData_Excalabria:
	dc.l	$940C9370	
	dc.l	$96D09500	
	dc.l	$977F4000	
	dc.l	$00810000	
BattlePaletteData_Tsarkon:
	dc.l	$940D93F0	
	dc.l	$96D09500	
	dc.l	$977F4000	
	dc.l	$00810000	
BattleVDPCmds_EnemySmall:
	dc.l	$00C10AC8	
	dc.l	$00CA0AC8	
	dc.l	$00210FC8	
BattleVDPCmds_EnemyLarge:
	dc.l	$00310FC8	
	dc.l	$00410FC8	
	dc.l	$00510FC8	
EncounterEnemySpriteByDirA:
	dc.l	EnemySpriteData_FacingDown
	dc.l	EnemySpriteData_FacingSide
	dc.l	EnemySpriteData_FacingUp
	dc.l	EnemySpriteData_FacingSide
EncounterEnemySpriteByDirB:
	dc.l	EnemySpriteDataB_FacingDown
	dc.l	EnemySpriteDataB_FacingSide
	dc.l	EnemySpriteDataB_FacingUp
	dc.l	EnemySpriteDataB_FacingSide
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
EnemySpriteDataB_FacingDown:
	dc.l	$00F7060A	
	dc.l	$0030FFF4	
	dc.l	$00D30A0A	
	dc.l	$FFFC0018	
EnemySpriteDataB_FacingSide:
	dc.l	$0121000A	
	dc.l	$002EFFF3	
	dc.l	$00FD060A	
	dc.l	OverworldMapSector_40018	
EnemySpriteDataB_FacingUp:
	dc.l	$0109060A	
	dc.l	$002CFFFB	
	dc.l	$0119050A	
	dc.l	EnemySpriteDataB_FacingUp_Gfx_80010	
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
BossProjectileSpriteFramePtrs:
	dc.l	BossSpriteFrame_FakeKing
	dc.l	BossProjectileSpriteFrame_B
	dc.l	BossProjectileSpriteFrame_C-2
	dc.l	BossProjectileSpriteFrame_D
BossSpriteFrame_FakeKing:
	dc.l	$024101B1	
	dc.l	loc_00000000	
	dc.l	InitEquipmentAndLevel-3	
BossSpriteFrame_StowThief:
	dc.l	$01C10000	
	dc.l	loc_00000000	
BossSpriteFrame_Asti:
	dc.l	$025901D1	
	dc.l	LoadCaveTileGraphics	
	dc.l	$FFDB0265	
BossSpriteFrame_Excalabria3:
	dc.l	$01E10000	
	dc.l	$FFF6FFDB	
BossSpriteFrame_Carthahena:
	dc.l	$027101F1	
	dc.l	LoadCaveTileGfxToBuffer-3	
	dc.l	$FFDC027D	
BossSpriteFrame_Luther:
	dc.l	$020102AD	
	dc.l	loc_00000000	
BossProjectileSpriteFrame_B:
	dc.l	$02890211	
	dc.l	loc_00000000	
	dc.l	ClearVRAMSprites_End-3	
BossProjectileSpriteFrame_C:
	dc.l	$02210000	
	dc.l	loc_00000000	
BossProjectileSpriteFrame_D:
	dc.l	$02A10231	
	dc.l	loc_00000000	
	dc.l	BossProjectileSpriteFrame_D_Frame_2B0	
HydraBoss_ProjectileSpriteFrames:
	dc.l	loc_00000000	
	dc.l	$02B402B8	
	dc.l	$02B402B8	
	dc.l	$02B402B8	
	dc.l	$02BC02C0	
	dc.l	$02BC02C0	
	dc.l	$02BC02C0	
HydraBoss_ProjectileFallFrames:
	dc.l	$02C402C8	
HydraBoss_BodyPartFrames:
	dc.l	$00F10000	
	dc.l	$00FD0000	
	dc.l	$01090061	
	dc.l	$011500B1	
HydraBoss_AttackFrames:
	dc.l	$01210021	
	dc.l	$012D0031	
	dc.l	$01390041	
	dc.l	$01450051	
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
HydraBoss_PartDeathFrames:
	dc.l	$018100C1	
	dc.l	$018D00D1	
	dc.l	$019900E1	
	dc.l	$01A50000	
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
OrbitBoss_SatelliteFrames:
	dc.l	$00210031	
	dc.l	$00410051	
OrbitBoss_InnerSatelliteFrame:
	dc.l	$00610071	
	dc.l	$00810091	
OrbitBoss_ProjectileFrames:
	dc.l	$00A100B1	
	dc.l	$00C100C1	
OrbitBoss_ProjectileFallFrames:
	dc.l	$00D100DA	
	dc.l	$00E300EC	
	dc.l	$00F500FE	
OrbitBoss_ProjectileExplodeFrames:
	dc.l	$01070110	
	dc.l	$01190041	
EncounterTileData_Entry:
	dc.l	EncounterTileData_Entry_Gfx_5D7A0
	dc.l	EncounterTileData_Entry_Gfx_5DC36
	dc.b	$00, $4F 

EnemyEncounterTypesByMapSector:  ; Maps current map sector to pointer index at EnemyEncounterGroupTable
	dc.b	$28, $28, $28, $27, $27, $27, $24, $00, $21, $23, $20, $20, $1E, $1E, $41, $00
	dc.b	$2A, $2A, $2C, $2E, $25, $25, $24, $24, $21, $21, $00, $00, $1E, $41, $00, $00
	dc.b	$00, $2D, $2D, $2D, $2E, $2E, $34, $36, $36, $36, $37, $37, $1B, $1C, $1C, $00
	dc.b	$00, $32, $32, $3F, $1E, $2E, $0B, $00, $00, $39, $00, $00, $1B, $1B, $1A, $1C
	dc.b	$03, $02, $05, $05, $08, $08, $0A, $00, $00, $39, $00, $3D, $18, $18, $17, $00 
	dc.b	$04, $02, $07, $07, $08, $08, $09, $00, $3A, $3A, $3B, $3C, $16, $17, $00, $00 
	dc.b	$00, $00, $0F, $00, $00, $0D, $11, $11, $12, $12, $14, $00, $16, $17, $00, $00 
	dc.b	$00, $00, $0E, $0E, $0D, $0F, $0F, $11, $00, $12, $15, $14, $16, $00, $00, $00 

; Maps current cave room to pointer index at EnemyEncounterGroupTable
EnemyEncounterTypesByCaveRoom:
	dc.b	$01, $06, $06, $0C, $0C, $10, $43, $13, $13, $40, $40, $19, $19, $1D, $1D, $1F 
	dc.b	$1F, $1F, $22, $42, $26, $26, $29, $2F, $2F, $30, $31, $31, $35, $35, $38, $38 
	dc.b	$3E, $3E, $3E, $29, $2B, $2D, $45, $2D, $2B, $2D, $33, $44 

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
; EnemyEncounterGroup_NN: 4 encounter-type words selected by Random_number (0-3).
; Each word is an index into EnemyGfxDataTable (12-byte entries).
; The group index comes from EnemyEncounterTypesByMapSector or EnemyEncounterTypesByCaveRoom.
EnemyEncounterGroup_00:
	dc.w	$0, $0, $A, $1 ; Bouncing_5A | Bouncing_5A | StandardMelee_4D | Bouncing_69
EnemyEncounterGroup_01:
	dc.w	$6, $A, $1, $1 ; StalkPause_4E | StandardMelee_4D | Bouncing_69 | Bouncing_69
EnemyEncounterGroup_02:
	dc.w	$A, $A, $1, $0 ; StandardMelee_4D | StandardMelee_4D | Bouncing_69 | Bouncing_5A
EnemyEncounterGroup_03:
	dc.w	$E, $A, $1, $A ; FleeChase_5B | StandardMelee_4D | Bouncing_69 | StandardMelee_4D
EnemyEncounterGroup_04:
	dc.w	$E, $12, $A, $1 ; FleeChase_5B | ProjectileFire_63 | StandardMelee_4D | Bouncing_69
EnemyEncounterGroup_05:
	dc.w	$E, $26, $12, $A ; FleeChase_5B | RandomShooter_66 | ProjectileFire_63 | StandardMelee_4D
EnemyEncounterGroup_06:
	dc.w	$E, $6, $6, $16 ; FleeChase_5B | StalkPause_4E | StalkPause_4E | ProximityChase_5C
EnemyEncounterGroup_07:
	dc.w	$5, $12, $E, $16 ; Bouncing_AD | ProjectileFire_63 | FleeChase_5B | ProximityChase_5C
EnemyEncounterGroup_08:
	dc.w	$B, $A, $12, $5 ; StandardMelee_6C | StandardMelee_4D | ProjectileFire_63 | Bouncing_AD
EnemyEncounterGroup_09:
	dc.w	$32, $B, $12, $16 ; BurstFire_63 | StandardMelee_6C | ProjectileFire_63 | ProximityChase_5C
EnemyEncounterGroup_0A:
	dc.w	$2A, $32, $5, $B ; StandardMeleeFast_61 | BurstFire_63 | Bouncing_AD | StandardMelee_6C
EnemyEncounterGroup_0B:
	dc.w	$F, $5, $2A, $32 ; FleeChase_6F | Bouncing_AD | StandardMeleeFast_61 | BurstFire_63
EnemyEncounterGroup_0C:
	dc.w	$2E, $6, $16, $2 ; OrbShield_75 | StalkPause_4E | ProximityChase_5C | Bouncing_6A
EnemyEncounterGroup_0D:
	dc.w	$1A, $2A, $32, $F ; StandardMeleeAlt_5D | StandardMeleeFast_61 | BurstFire_63 | FleeChase_6F
EnemyEncounterGroup_0E:
	dc.w	$42, $2E, $1A, $2A ; Teleporter_66 | OrbShield_75 | StandardMeleeAlt_5D | StandardMeleeFast_61
EnemyEncounterGroup_0F:
	dc.w	$4A, $2E, $1A, $42 ; MultiOrb_75 | OrbShield_75 | StandardMeleeAlt_5D | Teleporter_66
EnemyEncounterGroup_10:
	dc.w	$1E, $6, $4A, $2 ; StalkPauseAlt_64 | StalkPause_4E | MultiOrb_75 | Bouncing_6A
EnemyEncounterGroup_11:
	dc.w	$4E, $4A, $1A, $42 ; OrbRing_75 | MultiOrb_75 | StandardMeleeAlt_5D | Teleporter_66
EnemyEncounterGroup_12:
	dc.w	$13, $4E, $1A, $42 ; ProjectileFire_A4 | OrbRing_75 | StandardMeleeAlt_5D | Teleporter_66
EnemyEncounterGroup_13:
	dc.w	$22, $3A, $36, $1E ; HumanoidMelee_65 | FastBurstShooter_64 | StalkPause3_64 | StalkPauseAlt_64
EnemyEncounterGroup_14:
	dc.w	$1B, $4, $4E, $13 ; StandardMeleeAlt_A1 | Bouncing_AC | OrbRing_75 | ProjectileFire_A4
EnemyEncounterGroup_15:
	dc.w	$46, $32, $1B, $4 ; SequentialFire_66 | BurstFire_63 | StandardMeleeAlt_A1 | Bouncing_AC
EnemyEncounterGroup_16:
	dc.w	$2F, $22, $2A, $46 ; OrbShield_C0 | HumanoidMelee_65 | StandardMeleeFast_61 | SequentialFire_66
EnemyEncounterGroup_17:
	dc.w	$27, $C, $46, $4E ; RandomShooter_AA | StandardMelee_6D | SequentialFire_66 | OrbRing_75
EnemyEncounterGroup_18:
	dc.w	$2B, $22, $1B, $1A ; StandardMeleeFast_BD | HumanoidMelee_65 | StandardMeleeAlt_A1 | StandardMeleeAlt_5D
EnemyEncounterGroup_19:
	dc.w	$1F, $3E, $10, $7 ; StalkPauseAlt_B9 | HomingShooter_64 | FleeChase_70 | StalkPause_7B
EnemyEncounterGroup_1A:
	dc.w	$33, $22, $1B, $2F ; BurstFire_A4 | HumanoidMelee_65 | StandardMeleeAlt_A1 | OrbShield_C0
EnemyEncounterGroup_1B:
	dc.w	$43, $33, $10, $22 ; Teleporter_AA | BurstFire_A4 | FleeChase_70 | HumanoidMelee_65
EnemyEncounterGroup_1C:
	dc.w	$4B, $47, $33, $4 ; MultiOrb_C0 | SequentialFire_AA | BurstFire_A4 | Bouncing_AC
EnemyEncounterGroup_1D:
	dc.w	$3B, $4B, $47, $22 ; FastBurstShooter_B9 | MultiOrb_C0 | SequentialFire_AA | HumanoidMelee_65
EnemyEncounterGroup_1E:
	dc.w	$1C, $28, $47, $33 ; StandardMeleeAlt_A2 | RandomShooter_AB | SequentialFire_AA | BurstFire_A4
EnemyEncounterGroup_1F:
	dc.w	$3F, $17, $7, $1C ; HomingShooter_B9 | ProximityChase_9E | StalkPause_7B | StandardMeleeAlt_A2
EnemyEncounterGroup_20:
	dc.w	$23, $1C, $14, $4B ; HumanoidMelee_A7 | StandardMeleeAlt_A2 | ProjectileFire_A5 | MultiOrb_C0
EnemyEncounterGroup_21:
	dc.w	$14, $23, $1C, $33 ; ProjectileFire_A5 | HumanoidMelee_A7 | StandardMeleeAlt_A2 | BurstFire_A4
EnemyEncounterGroup_22:
	dc.w	$20, $1C, $8, $14 ; StalkPauseAlt_BA | StandardMeleeAlt_A2 | StalkPause_7C | ProjectileFire_A5
EnemyEncounterGroup_23:
	dc.w	$44, $4F, $14, $23 ; Teleporter_AB | OrbRing_C0 | ProjectileFire_A5 | HumanoidMelee_A7
EnemyEncounterGroup_24:
	dc.w	$D, $44, $4F, $1C ; StandardMelee_6E | Teleporter_AB | OrbRing_C0 | StandardMeleeAlt_A2
EnemyEncounterGroup_25:
	dc.w	$48, $30, $23, $1C ; SequentialFire_AB | OrbShield_C1 | HumanoidMelee_A7 | StandardMeleeAlt_A2
EnemyEncounterGroup_26:
	dc.w	$3C, $8, $7, $48 ; FastBurstShooter_BA | StalkPause_7C | StalkPause_7B | SequentialFire_AB
EnemyEncounterGroup_27:
	dc.w	$11, $D, $44, $48 ; FleeChase_71 | StandardMelee_6E | Teleporter_AB | SequentialFire_AB
EnemyEncounterGroup_28:
	dc.w	$34, $2C, $D, $11 ; BurstFire_A5 | StandardMeleeFast_BE | StandardMelee_6E | FleeChase_71
EnemyEncounterGroup_29:
	dc.w	$40, $11, $8, $30 ; HomingShooter_BA | FleeChase_71 | StalkPause_7C | OrbShield_C1
EnemyEncounterGroup_2A:
	dc.w	$29, $30, $48, $23 ; RandomShooter_BC | OrbShield_C1 | SequentialFire_AB | HumanoidMelee_A7
EnemyEncounterGroup_2B:
	dc.w	$21, $4C, $29, $40 ; StalkPauseAlt_BB | MultiOrb_C1 | RandomShooter_BC | HomingShooter_BA
EnemyEncounterGroup_2C:
	dc.w	$24, $29, $11, $4 ; HumanoidMeleeAlt_A8 | RandomShooter_BC | FleeChase_71 | Bouncing_AC
EnemyEncounterGroup_2D:
	dc.w	$15, $24, $34, $4C ; ProjectileFire_A6 | HumanoidMeleeAlt_A8 | BurstFire_A5 | MultiOrb_C1
EnemyEncounterGroup_2E:
	dc.w	$50, $24, $15, $29 ; OrbRing_C1 | HumanoidMeleeAlt_A8 | ProjectileFire_A6 | RandomShooter_BC
EnemyEncounterGroup_2F:
	dc.w	$45, $39, $24, $11 ; Teleporter_BC | StalkPause3_BB | HumanoidMeleeAlt_A8 | FleeChase_71
EnemyEncounterGroup_30:
	dc.w	$18, $45, $39, $15 ; ProximityChase_9F | Teleporter_BC | StalkPause3_BB | ProjectileFire_A6
EnemyEncounterGroup_31:
	dc.w	$18, $45, $50, $39 ; ProximityChase_9F | Teleporter_BC | OrbRing_C1 | StalkPause3_BB
EnemyEncounterGroup_32:
	dc.w	$31, $18, $50, $45 ; OrbShield_C2 | ProximityChase_9F | OrbRing_C1 | Teleporter_BC
EnemyEncounterGroup_33:
	dc.w	$53, $50, $18, $45 ; SpiralBurst_A6b | OrbRing_C1 | ProximityChase_9F | Teleporter_BC
EnemyEncounterGroup_34:
	dc.w	$1D, $31, $24, $45 ; StandardMeleeAlt_A3 | OrbShield_C2 | HumanoidMeleeAlt_A8 | Teleporter_BC
EnemyEncounterGroup_35:
	dc.w	$9, $3D, $18, $50 ; StalkPause_7D | FastBurstShooter_BB | ProximityChase_9F | OrbRing_C1
EnemyEncounterGroup_36:
	dc.w	$2D, $1D, $31, $50 ; StandardMeleeFast_BF | StandardMeleeAlt_A3 | OrbShield_C2 | OrbRing_C1
EnemyEncounterGroup_37:
	dc.w	$4D, $2D, $1D, $4 ; MultiOrb_C2 | StandardMeleeFast_BF | StandardMeleeAlt_A3 | Bouncing_AC
EnemyEncounterGroup_38:
	dc.w	$19, $41, $4D, $9 ; ProximityChase_A0 | HomingShooter_BB | MultiOrb_C2 | StalkPause_7D
EnemyEncounterGroup_39:
	dc.w	$4D, $19, $2D, $1D ; MultiOrb_C2 | ProximityChase_A0 | StandardMeleeFast_BF | StandardMeleeAlt_A3
EnemyEncounterGroup_3A:
	dc.w	$35, $2D, $4D, $24 ; BurstFire_A6 | StandardMeleeFast_BF | MultiOrb_C2 | HumanoidMeleeAlt_A8
EnemyEncounterGroup_3B:
	dc.w	$49, $4D, $35, $11 ; SequentialFire_BC | MultiOrb_C2 | BurstFire_A6 | FleeChase_71
EnemyEncounterGroup_3C:
	dc.w	$25, $49, $35, $19 ; HumanoidMeleeAlt_A9 | SequentialFire_BC | BurstFire_A6 | ProximityChase_A0
EnemyEncounterGroup_3D:
	dc.w	$25, $49, $35, $4D ; HumanoidMeleeAlt_A9 | SequentialFire_BC | BurstFire_A6 | MultiOrb_C2
EnemyEncounterGroup_3E:
	dc.w	$51, $25, $49, $52 ; OrbRing_C2 | HumanoidMeleeAlt_A9 | SequentialFire_BC | SpiralBurst_A6a
EnemyEncounterGroup_3F:
	dc.w	$3, $50, $50, $45 ; Bouncing_6B | OrbRing_C1 | OrbRing_C1 | Teleporter_BC
EnemyEncounterGroup_40:
	dc.w	$3E, $7, $3A, $22 ; HomingShooter_64 | StalkPause_7B | FastBurstShooter_64 | HumanoidMelee_65
EnemyEncounterGroup_41:
	dc.w	$28, $47, $22, $4B ; RandomShooter_AB | SequentialFire_AA | HumanoidMelee_65 | MultiOrb_C0
EnemyEncounterGroup_42:
	dc.w	$38, $8, $4, $23 ; StalkPause3_BA | StalkPause_7C | Bouncing_AC | HumanoidMelee_A7
EnemyEncounterGroup_43:
	dc.w	$1E, $36, $16, $2 ; StalkPauseAlt_64 | StalkPause3_64 | ProximityChase_5C | Bouncing_6A
EnemyEncounterGroup_44:
	dc.w	$37, $47, $7, $3A ; StationaryShooter_B9 | SequentialFire_AA | StalkPause_7B | FastBurstShooter_64
EnemyEncounterGroup_45:
	dc.w	$21, $1F, $1E, $4C ; StalkPauseAlt_BB | StalkPauseAlt_B9 | StalkPauseAlt_64 | MultiOrb_C1
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
EnemyAppearance_5A:
	enemyAppearance EnemyGfxFrameTable_OrbMain,EnemyGfxData_OrbMain,EnemyGfxFrameTable_OrbChild,EnemyGfxData_OrbChild,NullSpriteRoutine-2,$0E0D005A
EnemyAppearance_69:
	enemyAppearance EnemyGfxFrameTable_OrbMain,EnemyGfxData_OrbMain,EnemyGfxFrameTable_OrbChild,EnemyGfxData_OrbChild,NullSpriteRoutine-2,$0E0D0069
EnemyAppearance_6A:
	enemyAppearance EnemyGfxFrameTable_OrbMain,EnemyGfxData_OrbMain,EnemyGfxFrameTable_OrbChild,EnemyGfxData_OrbChild,NullSpriteRoutine-2,$0E0D006A
EnemyAppearance_6B:
	enemyAppearance EnemyGfxFrameTable_OrbMain,EnemyGfxData_OrbMain,EnemyGfxFrameTable_OrbChild,EnemyGfxData_OrbChild,NullSpriteRoutine-2,$0E0D006B
EnemyAppearance_AC:
	enemyAppearance EnemyGfxFrameTable_OrbMain,EnemyGfxData_OrbMain,EnemyGfxFrameTable_OrbChild,EnemyGfxData_OrbChild,NullSpriteRoutine-2,$0E0D00AC
EnemyAppearance_AD:
	enemyAppearance EnemyGfxFrameTable_OrbMain,EnemyGfxData_OrbMain,EnemyGfxFrameTable_OrbChild,EnemyGfxData_OrbChild,NullSpriteRoutine-2,$0E0D00AD
EnemyAppearance_4E:
	enemyAppearance EnemyGfxFrameTable_DragonMain,EnemyGfxData_DragonMain,EnemyGfxFrameTable_DragonChild,EnemyGfxData_DragonChild,NullSpriteRoutine-2,$0D0E004E
EnemyAppearance_7B:
	enemyAppearance EnemyGfxFrameTable_DragonMain,EnemyGfxData_DragonMain,EnemyGfxFrameTable_DragonChild,EnemyGfxData_DragonChild,NullSpriteRoutine-2,$0D0E007B
EnemyAppearance_7C:
	enemyAppearance EnemyGfxFrameTable_DragonMain,EnemyGfxData_DragonMain,EnemyGfxFrameTable_DragonChild,EnemyGfxData_DragonChild,NullSpriteRoutine-2,$0D0E007C
EnemyAppearance_7D:
	enemyAppearance EnemyGfxFrameTable_DragonMain,EnemyGfxData_DragonMain,EnemyGfxFrameTable_DragonChild,EnemyGfxData_DragonChild,NullSpriteRoutine-2,$0D0E007D
EnemyAppearance_4D:
	enemyAppearance EnemyGfxFrameTable_QuadrupedMain,EnemyGfxData_QuadrupedMain,EnemyGfxFrameTable_QuadrupedChild,EnemyGfxData_QuadrupedChild,NullSpriteRoutine-2,$0D0E004D
EnemyAppearance_6C:
	enemyAppearance EnemyGfxFrameTable_QuadrupedMain,EnemyGfxData_QuadrupedMain,EnemyGfxFrameTable_QuadrupedChild,EnemyGfxData_QuadrupedChild,NullSpriteRoutine-2,$0D0E006C
EnemyAppearance_6D:
	enemyAppearance EnemyGfxFrameTable_QuadrupedMain,EnemyGfxData_QuadrupedMain,EnemyGfxFrameTable_QuadrupedChild,EnemyGfxData_QuadrupedChild,NullSpriteRoutine-2,$0D0E006D
EnemyAppearance_6E:
	enemyAppearance EnemyGfxFrameTable_QuadrupedMain,EnemyGfxData_QuadrupedMain,EnemyGfxFrameTable_QuadrupedChild,EnemyGfxData_QuadrupedChild,NullSpriteRoutine-2,$0D0E006E
EnemyAppearance_5B:
	enemyAppearance EnemyGfxFrameTable_SerpentMain,EnemyGfxData_SerpentMain,EnemyGfxFrameTable_SerpentChild,EnemyGfxData_SerpentChild,NullSpriteRoutine-2,$0D0E005B
EnemyAppearance_6F:
	enemyAppearance EnemyGfxFrameTable_SerpentMain,EnemyGfxData_SerpentMain,EnemyGfxFrameTable_SerpentChild,EnemyGfxData_SerpentChild,NullSpriteRoutine-2,$0D0E006F
EnemyAppearance_70:
	enemyAppearance EnemyGfxFrameTable_SerpentMain,EnemyGfxData_SerpentMain,EnemyGfxFrameTable_SerpentChild,EnemyGfxData_SerpentChild,NullSpriteRoutine-2,$0D0E0070
EnemyAppearance_71:
	enemyAppearance EnemyGfxFrameTable_SerpentMain,EnemyGfxData_SerpentMain,EnemyGfxFrameTable_SerpentChild,EnemyGfxData_SerpentChild,NullSpriteRoutine-2,$0D0E0071
EnemyAppearance_63:
	enemyAppearance EnemyGfxFrameTable_WorldMapMain,EnemyGfxData_WorldMapMain,EnemyGfxFrameTable_WorldMapChild,EnemyGfxData_WorldMapChild,ExecuteWorldMapDma,$0E0E0063
EnemyAppearance_A4:
	enemyAppearance EnemyGfxFrameTable_WorldMapMain,EnemyGfxData_WorldMapMain,EnemyGfxFrameTable_WorldMapChild,EnemyGfxData_WorldMapChild,ExecuteWorldMapDma,$0E0E00A4
EnemyAppearance_A5:
	enemyAppearance EnemyGfxFrameTable_WorldMapMain,EnemyGfxData_WorldMapMain,EnemyGfxFrameTable_WorldMapChild,EnemyGfxData_WorldMapChild,ExecuteWorldMapDma,$0E0E00A5
EnemyAppearance_A6:
	enemyAppearance EnemyGfxFrameTable_WorldMapMain,EnemyGfxData_WorldMapMain,EnemyGfxFrameTable_WorldMapChild,EnemyGfxData_WorldMapChild,ExecuteWorldMapDma,$0E0E00A6
EnemyAppearance_5C:
	enemyAppearance EnemyGfxFrameTable_InsectMain,EnemyGfxData_InsectMain,EnemyGfxFrameTable_InsectChild,EnemyGfxData_InsectChild,NullSpriteRoutine-2,$0D0E005C
EnemyAppearance_9E:
	enemyAppearance EnemyGfxFrameTable_InsectMain,EnemyGfxData_InsectMain,EnemyGfxFrameTable_InsectChild,EnemyGfxData_InsectChild,NullSpriteRoutine-2,$0D0E009E
EnemyAppearance_9F:
	enemyAppearance EnemyGfxFrameTable_InsectMain,EnemyGfxData_InsectMain,EnemyGfxFrameTable_InsectChild,EnemyGfxData_InsectChild,NullSpriteRoutine-2,$0D0E009F
EnemyAppearance_A0:
	enemyAppearance EnemyGfxFrameTable_InsectMain,EnemyGfxData_InsectMain,EnemyGfxFrameTable_InsectChild,EnemyGfxData_InsectChild,NullSpriteRoutine-2,$0D0E00A0
EnemyAppearance_5D:
	enemyAppearance EnemyGfxFrameTable_GolemMain,EnemyGfxData_GolemMain,EnemyGfxFrameTable_GolemChild,EnemyGfxData_GolemChild,ExecuteWorldMapDma,$0E0E005D
EnemyAppearance_A1:
	enemyAppearance EnemyGfxFrameTable_GolemMain,EnemyGfxData_GolemMain,EnemyGfxFrameTable_GolemChild,EnemyGfxData_GolemChild,ExecuteWorldMapDma,$0E0E00A1
EnemyAppearance_A2:
	enemyAppearance EnemyGfxFrameTable_GolemMain,EnemyGfxData_GolemMain,EnemyGfxFrameTable_GolemChild,EnemyGfxData_GolemChild,ExecuteWorldMapDma,$0E0E00A2
EnemyAppearance_A3:
	enemyAppearance EnemyGfxFrameTable_GolemMain,EnemyGfxData_GolemMain,EnemyGfxFrameTable_GolemChild,EnemyGfxData_GolemChild,ExecuteWorldMapDma,$0E0E00A3
EnemyAppearance_64:
	enemyAppearance EnemyGfxFrameTable_BeastMain,EnemyGfxData_BeastMain,EnemyGfxFrameTable_BeastChild,EnemyGfxData_BeastChild,NullSpriteRoutine-2,$0D0E0064
EnemyAppearance_B9:
	enemyAppearance EnemyGfxFrameTable_BeastMain,EnemyGfxData_BeastMain,EnemyGfxFrameTable_BeastChild,EnemyGfxData_BeastChild,NullSpriteRoutine-2,$0D0E00B9
EnemyAppearance_BA:
	enemyAppearance EnemyGfxFrameTable_BeastMain,EnemyGfxData_BeastMain,EnemyGfxFrameTable_BeastChild,EnemyGfxData_BeastChild,NullSpriteRoutine-2,$0D0E00BA
EnemyAppearance_BB:
	enemyAppearance EnemyGfxFrameTable_BeastMain,EnemyGfxData_BeastMain,EnemyGfxFrameTable_BeastChild,EnemyGfxData_BeastChild,NullSpriteRoutine-2,$0D0E00BB
EnemyAppearance_65:
	enemyAppearance EnemyGfxFrameTable_SkeletonMain,EnemyGfxData_SkeletonMain,EnemyGfxFrameTable_SkeletonChild,EnemyGfxData_SkeletonChild,NullSpriteRoutine-2,$0D0E0065
EnemyAppearance_A7:
	enemyAppearance EnemyGfxFrameTable_SkeletonMain,EnemyGfxData_SkeletonMain,EnemyGfxFrameTable_SkeletonChild,EnemyGfxData_SkeletonChild,NullSpriteRoutine-2,$0D0E00A7
EnemyAppearance_A8:
	enemyAppearance EnemyGfxFrameTable_SkeletonMain,EnemyGfxData_SkeletonMain,EnemyGfxFrameTable_SkeletonChild,EnemyGfxData_SkeletonChild,NullSpriteRoutine-2,$0D0E00A8
EnemyAppearance_A9:
	enemyAppearance EnemyGfxFrameTable_SkeletonMain,EnemyGfxData_SkeletonMain,EnemyGfxFrameTable_SkeletonChild,EnemyGfxData_SkeletonChild,NullSpriteRoutine-2,$0D0E00A9
EnemyAppearance_66:
	enemyAppearance EnemyGfxFrameTable_HumanoidMain,EnemyGfxData_HumanoidMain,EnemyGfxFrameTable_HumanoidChild,EnemyGfxData_HumanoidChild,NullSpriteRoutine-2,$0D0E0066
EnemyAppearance_AA:
	enemyAppearance EnemyGfxFrameTable_HumanoidMain,EnemyGfxData_HumanoidMain,EnemyGfxFrameTable_HumanoidChild,EnemyGfxData_HumanoidChild,NullSpriteRoutine-2,$0D0E00AA
EnemyAppearance_AB:
	enemyAppearance EnemyGfxFrameTable_HumanoidMain,EnemyGfxData_HumanoidMain,EnemyGfxFrameTable_HumanoidChild,EnemyGfxData_HumanoidChild,NullSpriteRoutine-2,$0D0E00AB
EnemyAppearance_BC:
	enemyAppearance EnemyGfxFrameTable_HumanoidMain,EnemyGfxData_HumanoidMain,EnemyGfxFrameTable_HumanoidChild,EnemyGfxData_HumanoidChild,NullSpriteRoutine-2,$0D0E00BC
EnemyAppearance_61:
	enemyAppearance EnemyGfxFrameTable_GargoyleMain,EnemyGfxData_GargoyleMain,EnemyGfxFrameTable_GargoyleChild,EnemyGfxData_GargoyleChild,NullSpriteRoutine-2,$0D0E0061
EnemyAppearance_BD:
	enemyAppearance EnemyGfxFrameTable_GargoyleMain,EnemyGfxData_GargoyleMain,EnemyGfxFrameTable_GargoyleChild,EnemyGfxData_GargoyleChild,NullSpriteRoutine-2,$0D0E00BD
EnemyAppearance_BE:
	enemyAppearance EnemyGfxFrameTable_GargoyleMain,EnemyGfxData_GargoyleMain,EnemyGfxFrameTable_GargoyleChild,EnemyGfxData_GargoyleChild,NullSpriteRoutine-2,$0D0E00BE
EnemyAppearance_BF:
	enemyAppearance EnemyGfxFrameTable_GargoyleMain,EnemyGfxData_GargoyleMain,EnemyGfxFrameTable_GargoyleChild,EnemyGfxData_GargoyleChild,NullSpriteRoutine-2,$0D0E00BF
EnemyAppearance_75:
	enemyAppearance EnemyGfxFrameTable_BossMain,EnemyGfxData_BossMain,loc_00000000,loc_00000000,loc_00000000,$0F000075
EnemyAppearance_C0:
	enemyAppearance EnemyGfxFrameTable_BossMain,EnemyGfxData_BossMain,loc_00000000,loc_00000000,loc_00000000,$0F0000C0
EnemyAppearance_C1:
	enemyAppearance EnemyGfxFrameTable_BossMain,EnemyGfxData_BossMain,loc_00000000,loc_00000000,loc_00000000,$0F0000C1
EnemyAppearance_C2:
	dc.l	EnemyGfxFrameTable_BossMain
	dc.l	EnemyGfxData_BossMain
	dc.l	$00000000
	dc.b	$00, $00, $00, $00, $00, $00 
	dc.w	$0000
	dc.b	$0F
	dc.b	$00 
	dc.w	$00C2
; enemyData ai_fn, tile_id, reward_type, reward_value, extra_obj_slots, max_spawn,
;           hp, damage_per_hit, xp_reward, kim_reward, speed, sprite_frame, behavior_flag
EnemyData_Bouncing_5A:
	enemyData InitEnemy_Bouncing,$005A,ENEMY_REWARD_TYPE_0,$0000,$00,$07,$001C,$0004,$0001,$0002,$00000150,$00,$02
EnemyData_Bouncing_69:
	enemyData InitEnemy_Bouncing,$0069,ENEMY_REWARD_TYPE_0,$0000,$00,$07,$001C,$0005,$0002,$0002,$00000170,$00,$02
EnemyData_Bouncing_6A:
	enemyData InitEnemy_Bouncing,$006A,ENEMY_REWARD_TYPE_0,$001F,$00,$07,$0064,$001E,$0065,$0030,$00000240,$00,$02
EnemyData_Bouncing_6B:
	enemyData $00009A72,$006B,ENEMY_REWARD_TYPE_0,$0026,$00,$07,$1F40,$006E,$0396,$0100,$00000550,$00,$0E
EnemyData_Bouncing_AC:
	enemyData InitEnemy_Bouncing,$00AC,ENEMY_REWARD_TYPE_0,$0021,$00,$07,$00FA,$0052,$0180,$0070,$00000280,$00,$02
EnemyData_Bouncing_AD:
	enemyData InitEnemy_Bouncing,$00AD,ENEMY_REWARD_TYPE_0,$0003,$00,$07,$0059,$0017,$0039,$0010,$00000210,$00,$02
EnemyData_StalkPause_4E:
	enemyData InitEnemy_StalkPause,$004E,ENEMY_REWARD_TYPE_0,$0001,$00,$07,$0096,$0006,$0008,$0016,$00000180,$00,$02
EnemyData_StalkPause_7B:
	enemyData InitEnemy_StalkPause,$007B,ENEMY_REWARD_TYPE_1,$060E,$00,$07,$04B0,$003C,$0210,$0710,$00000200,$00,$02
EnemyData_StalkPause_7C:
	enemyData InitEnemy_StalkPause,$007C,ENEMY_REWARD_TYPE_1,$1036,$00,$07,$05DC,$004E,$0277,$0115,$00000260,$00,$02
EnemyData_StalkPause_7D:
	enemyData InitEnemy_StalkPause,$007D,ENEMY_REWARD_TYPE_1,$0410,$00,$07,$0898,$0063,$0441,$0161,$0000012C,$00,$02
EnemyData_StandardMelee_4D:
	enemyData InitEnemy_StandardMelee,$004D,ENEMY_REWARD_TYPE_1,$1028,$00,$07,$0058,$0006,$0004,$0005,$00000150,$00,$02
EnemyData_StandardMelee_6C:
	enemyData InitEnemy_StandardMelee,$006C,ENEMY_REWARD_TYPE_1,$0816,$00,$07,$018F,$001E,$0042,$0020,$00000165,$00,$02
EnemyData_StandardMelee_6D:
	enemyData InitEnemy_StandardMelee,$006D,ENEMY_REWARD_TYPE_1,$102A,$00,$07,$0258,$0036,$0206,$0068,$00000180,$00,$02
EnemyData_StandardMelee_6E:
	enemyData InitEnemy_StandardMelee,$006E,ENEMY_REWARD_TYPE_1,$1032,$00,$07,$05FA,$0062,$0284,$0109,$00000195,$00,$02
EnemyData_FleeChase_5B:
	enemyData InitEnemy_FleeChase,$005B,ENEMY_REWARD_NONE,$0000,$00,$07,$0064,$000C,$0010,$0009,$00000200,$00,$02
EnemyData_FleeChase_6F:
	enemyData InitEnemy_FleeChase,$006F,ENEMY_REWARD_TYPE_0,$0000,$00,$07,$00AA,$0027,$0077,$0027,$00000220,$00,$02
EnemyData_FleeChase_70:
	enemyData InitEnemy_FleeChase,$0070,ENEMY_REWARD_TYPE_0,$001B,$00,$07,$02E4,$0046,$0212,$0131,$00000260,$00,$02
EnemyData_FleeChase_71:
	enemyData InitEnemy_FleeChase,$0071,ENEMY_REWARD_TYPE_0,$0024,$00,$07,$044C,$0078,$0316,$0180,$00000300,$00,$02
EnemyData_ProjectileFire_63:
	enemyData InitEnemy_ProjectileFire,$0063,ENEMY_REWARD_NONE,$0000,$00,$07,$003A,$001D,$0017,$0011,$00000190,$00,$0A
EnemyData_ProjectileFire_A4:
	enemyData InitEnemy_ProjectileFire,$00A4,ENEMY_REWARD_TYPE_0,$001B,$00,$07,$00D2,$0032,$0152,$0023,$00000230,$00,$0A
EnemyData_ProjectileFire_A5:
	enemyData InitEnemy_ProjectileFire,$00A5,ENEMY_REWARD_TYPE_0,$001C,$00,$07,$01EA,$003C,$0249,$0068,$00000250,$00,$0A
EnemyData_ProjectileFire_A6:
	enemyData InitEnemy_ProjectileFire,$00A6,ENEMY_REWARD_TYPE_0,$0029,$00,$07,$04CE,$005E,$0329,$0247,$00000300,$00,$0A
EnemyData_ProximityChase_5C:
	enemyData InitEnemy_ProximityChase,$005C,ENEMY_REWARD_NONE,$0000,$00,$07,$0064,$0024,$0031,$0015,$00000200,$00,$06
EnemyData_ProximityChase_9E:
	enemyData InitEnemy_ProximityChase,$009E,ENEMY_REWARD_TYPE_0,$001B,$00,$07,$01C2,$006D,$0243,$0107,$00000220,$00,$06
EnemyData_ProximityChase_9F:
	enemyData InitEnemy_ProximityChase,$009F,ENEMY_REWARD_TYPE_0,$0027,$00,$07,$0276,$00F4,$0422,$0154,$00000240,$00,$06
EnemyData_ProximityChase_A0:
	enemyData InitEnemy_ProximityChase,$00A0,ENEMY_REWARD_TYPE_0,$0020,$00,$07,$0316,$00B4,$0455,$0276,$00000280,$00,$06
EnemyData_StandardMeleeAlt_5D:
	enemyData InitEnemy_StandardMeleeAlt,$005D,ENEMY_REWARD_NONE,$0000,$00,$07,$0172,$0042,$0085,$0040,$00000180,$00,$02
EnemyData_StandardMeleeAlt_A1:
	enemyData InitEnemy_StandardMeleeAlt,$00A1,ENEMY_REWARD_TYPE_1,$0402,$00,$07,$0348,$0052,$0173,$0065,$00000190,$00,$02
EnemyData_StandardMeleeAlt_A2:
	enemyData InitEnemy_StandardMeleeAlt,$00A2,ENEMY_REWARD_TYPE_0,$0003,$00,$07,$0384,$0052,$0234,$0105,$00000200,$00,$02
EnemyData_StandardMeleeAlt_A3:
	enemyData InitEnemy_StandardMeleeAlt,$00A3,ENEMY_REWARD_TYPE_1,$0819,$00,$07,$05C8,$00AD,$0437,$0360,$00000210,$00,$06
EnemyData_StalkPauseAlt_64:
	enemyData InitEnemy_StalkPauseAlt,$0064,ENEMY_REWARD_TYPE_0,$001B,$00,$07,$021D,$0026,$0224,$0037,$00000080,$01,$02
EnemyData_StalkPauseAlt_B9:
	enemyData InitEnemy_StalkPauseAlt,$00B9,ENEMY_REWARD_TYPE_0,$001F,$00,$07,$0550,$0039,$0318,$0067,$00000120,$01,$02
EnemyData_StalkPauseAlt_BA:
	enemyData InitEnemy_StalkPauseAlt,$00BA,ENEMY_REWARD_TYPE_0,$001C,$00,$07,$08AC,$0056,$0351,$0099,$00000140,$01,$02
EnemyData_StalkPauseAlt_BB:
	enemyData InitEnemy_StalkPauseAlt,$00BB,ENEMY_REWARD_TYPE_0,$002A,$00,$07,$0D34,$006A,$0437,$0130,$00000160,$01,$06
EnemyData_HumanoidMelee_65:
	enemyData InitEnemy_IntermittentChase_Random,$0065,ENEMY_REWARD_TYPE_1,$1028,$00,$07,$05DC,$005C,$0169,$0063,$00000110,$00,$02
EnemyData_HumanoidMelee_A7:
	enemyData InitEnemy_IntermittentChase_Random,$00A7,ENEMY_REWARD_TYPE_1,$102A,$00,$07,$0A28,$008D,$0458,$0110,$00000150,$00,$02
EnemyData_HumanoidMeleeAlt_A8:
	enemyData InitEnemy_IntermittentChase_Homing,$00A8,ENEMY_REWARD_TYPE_1,$081E,$00,$07,$0E10,$00A0,$0501,$0135,$00000170,$00,$0E
EnemyData_HumanoidMeleeAlt_A9:
	enemyData InitEnemy_IntermittentChase_Homing,$00A9,ENEMY_REWARD_TYPE_1,$002A,$00,$07,$0FA0,$00B4,$0600,$0250,$00000300,$00,$02
EnemyData_RandomShooter_66:
	enemyData InitEnemy_RandomShooter,$0066,ENEMY_REWARD_NONE,$0000,$00,$07,$0123,$001E,$0025,$0013,$00000180,$00,$08
EnemyData_RandomShooter_AA:
	enemyData InitEnemy_RandomShooter,$00AA,ENEMY_REWARD_TYPE_0,$0002,$00,$07,$0258,$0040,$0203,$0070,$00000200,$00,$0C
EnemyData_RandomShooter_AB:
	enemyData InitEnemy_RandomShooter,$00AB,ENEMY_REWARD_TYPE_0,$0002,$00,$07,$035C,$0063,$0233,$0099,$00000220,$00,$0C
EnemyData_RandomShooter_BC:
	enemyData InitEnemy_RandomShooter,$00BC,ENEMY_REWARD_TYPE_2,$0207,$00,$07,$049C,$0097,$0301,$0140,$00000240,$00,$0C
EnemyData_StandardMeleeFast_61:
	enemyData InitEnemy_StandardMeleeFast,$0061,ENEMY_REWARD_TYPE_1,$102C,$00,$07,$04B0,$0018,$0090,$0033,$00000120,$01,$02
EnemyData_StandardMeleeFast_BD:
	enemyData $00009528,$00BD,ENEMY_REWARD_TYPE_1,$102D,$00,$07,$0898,$0031,$0208,$0068,$00000160,$01,$02
EnemyData_StandardMeleeFast_BE:
	enemyData InitEnemy_StandardMeleeFast,$00BE,ENEMY_REWARD_TYPE_1,$0028,$00,$07,$0BB8,$0061,$0366,$0145,$00000200,$01,$02
EnemyData_StandardMeleeFast_BF:
	enemyData InitEnemy_StandardMeleeFast,$00BF,ENEMY_REWARD_TYPE_1,$002B,$00,$07,$11F8,$0093,$0452,$0209,$00000220,$01,$02
EnemyData_OrbShield_75:
	enemyData InitBoss_OrbShield,$0075,ENEMY_REWARD_TYPE_0,$001B,$01,$03,$0070,$001E,$0076,$0038,$00000160,$00,$02
EnemyData_OrbShield_C0:
	enemyData InitBoss_OrbShield,$00C0,ENEMY_REWARD_TYPE_0,$001B,$03,$01,$0172,$0052,$0192,$0068,$00000180,$00,$02
EnemyData_OrbShield_C1:
	enemyData InitBoss_OrbShield,$00C1,ENEMY_REWARD_TYPE_0,$001C,$03,$01,$05FA,$006C,$0302,$0136,$00000200,$00,$02
EnemyData_OrbShield_C2:
	enemyData InitBoss_OrbShield,$00C2,ENEMY_REWARD_TYPE_0,$0020,$03,$01,$0898,$008C,$0925,$0172,$00000220,$00,$02
EnemyData_BurstFire_63:
	enemyData InitEnemy_BurstFire,$0063,ENEMY_REWARD_TYPE_0,$0000,$03,$01,$0096,$0049,$0057,$0026,$00000200,$00,$0A
EnemyData_BurstFire_A4:
	enemyData InitEnemy_BurstFire,$00A4,ENEMY_REWARD_TYPE_0,$001D,$03,$01,$0172,$006B,$0213,$0072,$00000220,$00,$0A
EnemyData_BurstFire_A5:
	enemyData InitEnemy_BurstFire,$00A5,ENEMY_REWARD_TYPE_3,$3000,$03,$01,$0258,$009C,$0319,$0152,$00000240,$00,$0A
EnemyData_BurstFire_A6:
	enemyData InitEnemy_BurstFire,$00A6,ENEMY_REWARD_NONE,$0002,$03,$01,$06A4,$00B1,$0472,$0206,$00000260,$00,$0A
EnemyData_StalkPause3_64:
	enemyData InitEnemy_StationaryShooter,$0064,ENEMY_REWARD_TYPE_0,$001B,$00,$07,$01E0,$0039,$0333,$0039,$00000180,$01,$02
EnemyData_StationaryShooter_B9:
	enemyData $00009D90,$00B9,ENEMY_REWARD_TYPE_0,$0003,$00,$07,$0348,$004D,$0416,$0070,$00000200,$01,$02
EnemyData_StalkPause3_BA:
	enemyData InitEnemy_StationaryShooter,$00BA,ENEMY_REWARD_TYPE_0,$001C,$00,$07,$03FC,$006C,$0472,$0113,$00000220,$01,$02
EnemyData_StalkPause3_BB:
	enemyData InitEnemy_StationaryShooter,$00BB,ENEMY_REWARD_TYPE_3,$3000,$00,$07,$04F6,$0097,$0618,$0143,$00000240,$01,$02
EnemyData_FastBurstShooter_64:
	enemyData InitEnemy_FastBurstShooter,$0064,ENEMY_REWARD_TYPE_3,$0500,$03,$01,$0398,$0039,$0267,$0052,$00000180,$01,$02
EnemyData_FastBurstShooter_B9:
	enemyData InitEnemy_FastBurstShooter,$00B9,ENEMY_REWARD_TYPE_0,$001C,$03,$01,$0578,$0048,$0321,$0095,$00000180,$01,$02
EnemyData_FastBurstShooter_BA:
	enemyData InitEnemy_FastBurstShooter,$00BA,ENEMY_REWARD_TYPE_0,$002B,$03,$01,$0703,$005C,$0414,$0129,$00000180,$01,$02
EnemyData_FastBurstShooter_BB:
	enemyData $0000A6AA,$00BB,ENEMY_REWARD_TYPE_0,$0020,$03,$01,$0A8C,$0075,$0544,$0182,$00000180,$01,$02
EnemyData_HomingShooter_64:
	enemyData InitEnemy_HomingShooter,$0064,ENEMY_REWARD_TYPE_0,$001B,$03,$01,$0398,$003A,$0395,$0070,$00000180,$01,$02
EnemyData_HomingShooter_B9:
	enemyData InitEnemy_HomingShooter,$00B9,ENEMY_REWARD_TYPE_0,$0021,$03,$01,$044C,$004A,$0441,$0093,$00000220,$01,$02
EnemyData_HomingShooter_BA:
	enemyData InitEnemy_HomingShooter,$00BA,ENEMY_REWARD_TYPE_0,$001C,$03,$01,$0640,$0063,$0524,$0156,$00000260,$01,$02
EnemyData_HomingShooter_BB:
	enemyData InitEnemy_HomingShooter,$00BB,ENEMY_REWARD_TYPE_0,$0026,$03,$01,$076C,$0079,$0657,$0609,$00000300,$01,$02
EnemyData_Teleporter_66:
	enemyData InitEnemy_Teleporter,$0066,ENEMY_REWARD_TYPE_0,$0001,$00,$07,$00DE,$0029,$0094,$0043,$00000250,$00,$08
EnemyData_Teleporter_AA:
	enemyData InitEnemy_Teleporter,$00AA,ENEMY_REWARD_NONE,$0000,$00,$07,$0186,$0068,$0215,$0090,$00000300,$00,$0C
EnemyData_Teleporter_AB:
	enemyData InitEnemy_Teleporter,$00AB,ENEMY_REWARD_TYPE_3,$1000,$00,$07,$01FE,$0080,$0260,$0120,$00000350,$00,$0C
EnemyData_Teleporter_BC:
	enemyData InitEnemy_Teleporter,$00BC,ENEMY_REWARD_TYPE_2,$0205,$00,$07,$0276,$00BB,$0412,$0172,$00000400,$00,$0C
EnemyData_SequentialFire_66:
	enemyData InitEnemy_SequentialFire,$0066,ENEMY_REWARD_TYPE_0,$0001,$03,$01,$0352,$003E,$0183,$0067,$00000160,$00,$08
EnemyData_SequentialFire_AA:
	enemyData InitEnemy_SequentialFire,$00AA,ENEMY_REWARD_TYPE_0,$0001,$03,$01,$044C,$004A,$0217,$0100,$00000180,$00,$0C
EnemyData_SequentialFire_AB:
	enemyData InitEnemy_SequentialFire,$00AB,ENEMY_REWARD_TYPE_0,$0002,$03,$01,$05FA,$006C,$0293,$0133,$00000200,$00,$0C
EnemyData_SequentialFire_BC:
	enemyData InitEnemy_SequentialFire,$00BC,ENEMY_REWARD_TYPE_3,$1000,$03,$01,$06B8,$00C8,$0618,$0220,$00000220,$00,$04
EnemyData_MultiOrb_75:
	enemyData InitBoss_MultiOrb,$0075,ENEMY_REWARD_TYPE_0,$0000,$03,$01,$02BC,$0024,$0104,$0045,$00000180,$00,$02
EnemyData_MultiOrb_C0:
	enemyData InitBoss_MultiOrb,$00C0,ENEMY_REWARD_TYPE_0,$001C,$03,$01,$04B0,$0054,$0219,$0093,$00000185,$00,$02
EnemyData_MultiOrb_C1:
	enemyData InitBoss_MultiOrb,$00C1,ENEMY_REWARD_TYPE_0,$001B,$03,$01,$06A4,$0082,$0361,$0158,$00000190,$00,$02
EnemyData_MultiOrb_C2:
	enemyData InitBoss_MultiOrb,$00C2,ENEMY_REWARD_TYPE_0,$001C,$03,$01,$08FC,$008D,$0451,$0197,$00000195,$00,$06
EnemyData_OrbRing_75:
	enemyData InitBoss_OrbRing,$0075,ENEMY_REWARD_TYPE_0,$001B,$03,$01,$030C,$002F,$0141,$0050,$00000180,$00,$02
EnemyData_OrbRing_C0:
	enemyData InitBoss_OrbRing,$00C0,ENEMY_REWARD_TYPE_0,$001C,$03,$01,$05DC,$0062,$0269,$0123,$00000200,$00,$02
EnemyData_OrbRing_C1:
	enemyData InitBoss_OrbRing,$00C1,ENEMY_REWARD_TYPE_3,$5000,$03,$01,$0988,$0072,$0374,$0168,$00000220,$00,$02
EnemyData_OrbRing_C2:
	enemyData InitBoss_OrbRing,$00C2,ENEMY_REWARD_TYPE_0,$0027,$03,$01,$0A8C,$00A8,$0512,$0390,$00000240,$00,$0A
EnemyData_SpiralBurst_A6a:
	enemyData InitEnemy_SpiralBurst,$00A6,ENEMY_REWARD_TYPE_0,$0029,$01,$03,$06A4,$009D,$0472,$0206,$00000260,$00,$0A
EnemyData_SpiralBurst_A6b:
	enemyData InitEnemy_SpiralBurst,$00A6,ENEMY_REWARD_TYPE_0,$0020,$01,$00,$06A4,$00C8,$0472,$0206,$00000360,$00,$0E
EnemyData_StalkPause_7B_Last:
	enemyData InitEnemy_StalkPause,$007B,ENEMY_REWARD_TYPE_3,$3000,$00,$04,$04B0,$0064,$0000,$1200,$00000190,$00,$0E
EnemySpriteSet_A:
	dc.l	EnemyGfxFrameTable_DragonChild
	dc.l	EnemyGfxData_DragonChild
	dc.b	$00, $6B 
	dc.l	EnemyGfxFrameTable_DragonMain
	dc.l	EnemyGfxData_DragonMain
	dc.b	$00, $47 
	dc.l	NULL_PTR
EnemySpriteSet_B:
	dc.l	EnemyGfxFrameTable_QuadrupedChild
	dc.l	EnemyGfxData_QuadrupedChild
	dc.b	$00, $6B 
	dc.l	EnemyGfxFrameTable_QuadrupedMain
	dc.l	EnemyGfxData_QuadrupedMain
	dc.b	$00, $47 
	dc.l	NULL_PTR
EnemySpriteSet_C:
	dc.l	EnemyGfxFrameTable_OrbChild
	dc.l	EnemyGfxData_OrbChild
	dc.b	$00, $2F 
	dc.l	EnemyGfxFrameTable_OrbMain
	dc.l	EnemyGfxData_OrbMain
	dc.b	$00, $47 
	dc.l	NULL_PTR
EnemySpriteSet_D:
	dc.l	EnemyGfxFrameTable_SerpentChild
	dc.l	EnemyGfxData_SerpentChild
	dc.b	$00, $6B 
	dc.l	EnemyGfxFrameTable_SerpentMain
	dc.l	EnemyGfxData_SerpentMain
	dc.b	$00, $47 
	dc.l	NULL_PTR
EnemySpriteSet_E:
	dc.l	EnemyGfxFrameTable_InsectChild
	dc.l	EnemyGfxData_InsectChild
	dc.b	$00, $77 
	dc.l	EnemyGfxFrameTable_InsectMain
	dc.l	EnemyGfxData_InsectMain
	dc.b	$00, $4F 
	dc.l	NULL_PTR
EnemySpriteSet_F:
	dc.l	EnemyGfxFrameTable_GolemChild
	dc.l	EnemyGfxData_GolemChild
	dc.b	$00, $6B 
	dc.l	EnemyGfxFrameTable_GolemMain
	dc.l	EnemyGfxData_GolemMain
	dc.b	$00, $6B 
	dc.l	NULL_PTR
EnemySpriteSet_G:
	dc.l	EnemyGfxFrameTable_GargoyleChild
	dc.l	EnemyGfxData_GargoyleChild
	dc.b	$00, $6B 
	dc.l	EnemyGfxFrameTable_GargoyleMain
	dc.l	EnemyGfxData_GargoyleMain
	dc.b	$00, $47 
	dc.l	NULL_PTR
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
EnemySpriteSet_J:
	dc.l	EnemyGfxFrameTable_SkeletonChild
	dc.l	EnemyGfxData_SkeletonChild
	dc.b	$00, $6B 
	dc.l	EnemyGfxFrameTable_SkeletonMain
	dc.l	EnemyGfxData_SkeletonMain
	dc.b	$00, $47 
	dc.l	NULL_PTR
EnemySpriteSet_K:
	dc.l	EnemyGfxFrameTable_HumanoidChild
	dc.l	EnemyGfxData_HumanoidChild
	dc.b	$00, $3B 
	dc.l	EnemyGfxFrameTable_HumanoidMain
	dc.l	EnemyGfxData_HumanoidMain
	dc.b	$00, $27 
	dc.l	NULL_PTR
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