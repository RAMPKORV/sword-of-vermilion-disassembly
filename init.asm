EntryPoint:
	TST.l	$00A10008
loc_00000F32:
	BNE.w	loc_0000102C
	TST.w	$00A1000C
	BNE.b	loc_00000F32
	LEA	loc_00000FC8(PC), A5
	MOVEM.l	(A5)+, D5/D6/D7/A0/A1/A2/A3/A4
	MOVE.w	-$1100(A1), D0
	ANDI.w	#$0F00, D0
	BEQ.b	loc_00000F58
	MOVE.l	#'SEGA', $2F00(A1)	
loc_00000F58:
	MOVE.w	(A4), D0
	MOVEQ	#0, D0
	MOVEA.l	D0, A6
	MOVE.l	A6, USP
	MOVEQ	#VDPInitValues_End-VDPInitValues-1, D1
loc_00000F62:
	MOVE.b	(A5)+, D5
	MOVE.w	D5, (A4)
	ADD.w	D7, D5
	DBF	D1, loc_00000F62
	MOVE.l	#$40000080, (A4)
	MOVE.w	D0, (A3)
	MOVE.w	D7, (A1)
	MOVE.w	D7, (A2)
WaitForZ80:
	BTST.b	D0, (A1)
	BNE.b	WaitForZ80
	MOVEQ	#$00000027, D2
loc_00000F7E:
	MOVE.b	(A5)+, (A0)+
	DBF	D2, loc_00000F7E
	MOVE.w	D0, (A2)
	MOVE.w	D0, (A1)
	MOVE.w	D7, (A2)
loc_00000F8A:
	MOVE.l	D0, -(A6)
	DBF	D6, loc_00000F8A
	MOVE.l	#$81048F02, (A4)
	MOVE.l	#$C0000000, (A4)
	MOVEQ	#$0000001F, D3
loc_00000F9E:
	MOVE.l	D0, (A3)
	DBF	D3, loc_00000F9E
	MOVE.l	#$40000010, (A4)
	MOVEQ	#$00000013, D4
loc_00000FAC:
	MOVE.l	D0, (A3)
	DBF	D4, loc_00000FAC
	MOVEQ	#3, D5
loc_00000FB4:
	MOVE.b	(A5)+, $10(A3)
	DBF	D5, loc_00000FB4
	MOVE.w	D0, (A2)
	MOVEM.l	(A6), D0/D1/D2/D3/D4/D5/D6/D7/A0/A1/A2/A3/A4/A5/A6
	MOVE	#$2700, SR
	BRA.b	loc_0000102C

loc_00000FC8:
	dc.l	$00008000	
	dc.l	$00003FFF	
	dc.l	$00000100	
	dc.l	$00A00000	
	dc.l	Z80_bus_request	
	dc.l	$00A11200	
	dc.l	VDP_data_port	
	dc.l	VDP_control_port	

VDPInitValues:	; values for VDP registers
	dc.b 4			; Command $8004 - HInt off, Enable HV counter read
	dc.b $14		; Command $8114 - Display off, VInt off, DMA on, PAL off
	dc.b $30		; Command $8230 - Scroll A Address $C000
	dc.b $3C		; Command $833C - Window Address $F000
	dc.b 7			; Command $8407 - Scroll B Address $E000
	dc.b $6C		; Command $856C - Sprite Table Address $D800
	dc.b 0			; Command $8600 - Null
	dc.b 0			; Command $8700 - Background color Pal 0 Color 0
	dc.b 0			; Command $8800 - Null
	dc.b 0			; Command $8900 - Null
	dc.b $FF		; Command $8AFF - Hint timing $FF scanlines
	dc.b 0			; Command $8B00 - Ext Int off, VScroll full, HScroll full
	dc.b $81		; Command $8C81 - 40 cell mode, shadow/highlight off, no interlace
	dc.b $37		; Command $8D37 - HScroll Table Address $DC00
	dc.b 0			; Command $8E00 - Null
	dc.b 1			; Command $8F01 - VDP auto increment 1 byte
	dc.b 1			; Command $9001 - 64x32 cell scroll size
	dc.b 0			; Command $9100 - Window H left side, Base Point 0
	dc.b 0			; Command $9200 - Window V upside, Base Point 0
	dc.b $FF		; Command $93FF - DMA Length Counter $FFFF
	dc.b $FF		; Command $94FF - See above
	dc.b 0			; Command $9500 - DMA Source Address $0
	dc.b 0			; Command $9600 - See above
	dc.b $80		; Command $9780	- See above + VRAM fill mode

VDPInitValues_End:
	dc.b	$AF, $01, $D7, $1F, $11, $29, $00, $21 
	dc.b	$28, $00, $F9, $77, $ED, $B0, $DD, $E1, $FD, $E1, $ED, $47, $ED, $4F, $08, $D9, $F1, $C1, $D1, $E1, $08, $D9, $F1, $D1, $E1, $F9, $F3, $ED, $56, $36, $E9, $E9 
	dc.b	$9F, $BF, $DF, $FF 

loc_0000102C:
	MOVE.w	#$0100, Z80_bus_request
	MOVE.b	$00A1000D, D0
	MOVE.w	#0, Z80_bus_request
	BTST.l	#6, D0
	BNE.w	loc_00001050
	JSR	InitVDP
loc_00001050:
	MOVE.b	$00A10001, D0
	ANDI.b	#$0F, D0
	BEQ.b	loc_00001066
	MOVE.l	#$53454741, $00A14000	
loc_00001066:
	ORI	#$0700, SR
	JSR	loc_00000214
	JSR	loc_000005E8
	JSR	loc_0000FEE2
	JSR	loc_0000FCDC
	JSR	loc_000100FE
	JSR	loc_00000232
	ANDI	#$F8FF, SR
loc_00001092:
	LEA	$FFFFFE00.w, A7
	BSR.w	loc_000010DC
	CLR.b	$FFFFE002.w
	JSR	loc_0000F7C4
	CLR.w	$FFFFE000.w
	LEA	$FFFFD000.w, A5
loc_000010AC:
	BTST.b	#7, (A5)
	BEQ.b	loc_000010B8
	MOVEA.l	$2(A5), A0
	JSR	(A0)
loc_000010B8:
	CLR.w	D0
	MOVE.b	$1(A5), D0
	BEQ.b	loc_000010C4
	ADDA.w	D0, A5
	BRA.b	loc_000010AC
loc_000010C4:
	TST.b	Player_in_first_person_mode.w
	BNE.b	loc_000010D0
	JSR	loc_0000F75E
loc_000010D0:
	MOVE.b	#$FF, $FFFFE002.w
	BRA.b	loc_00001092
	dc.b	$42, $38, $C0, $FF 

loc_000010DC:
	TST.b	$FFFFC0FF.w
	BEQ.b	loc_000010DC
	CLR.b	$FFFFC0FF.w
	RTS
