; ======================================================================
; init.asm
; ROM entry point, hardware initialization, startup sequence,
; main game object-dispatch loop, and VBlank synchronization.
;
; Execution order:
;   EntryPoint              — TMSS/Z80/VDP/RAM/VSRAM/HScroll cold-boot init
;     └─ StartupSequence    — game-level hardware + graphics setup
;          └─ MainGameLoop  — per-frame object dispatch, loops forever
;
; Interrupt model:
;   VBlank IRQ sets Vblank_flag byte.
;   WaitForVBlank spins until it is set, then clears it and returns.
;   MainGameLoop calls WaitForVBlank at the top of every frame so all
;   game logic runs at most once per frame.
;
; Object dispatch:
;   Object slots are stored in a variable-length linked list rooted at
;   Object_slot_base ($FFFFD000).  Each slot begins with:
;     +$00 .b  active flag  (bit 7 = slot is live)
;     +$01 .b  next-slot stride (0 = end of list, else add to A5)
;     +$02 .l  function pointer (JSR'd if slot is active)
;   The main loop iterates this list, calling each active slot's handler.
; ======================================================================

; -----------------------------------------------------------------------
; EntryPoint
; Cold-boot hardware initialization executed directly from the reset
; vector.  Uses BootParamTable to initialize all registers before the
; loop, making the code position-independent.
;
; Steps:
;   1. Check IO_init_status — if already initialized (BNE), skip cold
;      hardware init and jump to StartupSequence.
;   2. Read BootParamTable into D5–D7/A0–A4 via MOVEM.
;   3. TMSS handshake: if hardware region byte is non-zero, write 'SEGA'
;      to TMSS register (allows VDP access on Model 1 hardware).
;   4. Initialize VDP registers from VDPInitValues table.
;   5. Acquire Z80 bus, copy Z80 sound driver stub to Z80 RAM, release bus.
;   6. Clear 68000 main RAM (D6 count × 4 bytes from A6 downward).
;   7. Write VDP VSRAM-clear command, clear 32 VSRAM long-words.
;   8. Write VDP HScroll-clear command, clear 20 HScroll table entries.
;   9. Initialize Z80 sound registers (4 bytes from VDPInitValues_End+40).
;  10. Release Z80, restore all registers from cleared RAM, set SR = $2700,
;      fall through to StartupSequence.
;
; Registers on entry: all undefined (cold reset)
; Registers destroyed: all (restored from cleared RAM before falling through)
; -----------------------------------------------------------------------
EntryPoint:
	TST.l	IO_init_status
EntryPoint_RegionCheck:
	BNE.w	StartupSequence
	TST.w	IO_init_status_w
	BNE.b	EntryPoint_RegionCheck
	LEA	BootParamTable(PC), A5
	MOVEM.l	(A5)+, D5/D6/D7/A0/A1/A2/A3/A4
	; A0 = $00008000 (Z80 RAM base)
	; A1 = Z80_bus_request ($A11100)
	; A2 = Z80_reset ($A11200)
	; A3 = VDP_data_port ($C00000)
	; A4 = VDP_control_port ($C00004)
	; D5 = first VDP init byte (reused as VDP command accumulator)
	; D6 = RAM clear word count - 1 ($00003FFF = clear $10000 bytes)
	; D7 = VDP register stride $8100 (added to each VDP init byte → cmd)
	MOVE.w	-$1100(A1), D0	; read IO_version ($A10000)
	ANDI.w	#$0F00, D0		; isolate region bits (bits 8-11)
	BEQ.b	EntryPoint_SkipSega	; 0 = no TMSS required
	MOVE.l	#'SEGA', $2F00(A1)	; $A14000 — TMSS register: write 'SEGA' to unlock VDP
EntryPoint_SkipSega:
	MOVE.w	(A4), D0		; read VDP status (clears pending flags)
	MOVEQ	#0, D0			; D0 = 0 (used as zero value throughout)
	MOVEA.l	D0, A6			; A6 = $00000000 (top of RAM clear region — fills downward)
	MOVE.l	A6, USP			; clear user stack pointer
	MOVEQ	#VDPInitValues_End-VDPInitValues-1, D1	; loop count = 23 registers
EntryPoint_VdpInitLoop:
	MOVE.b	(A5)+, D5		; load next register value byte
	MOVE.w	D5, (A4)		; write as VDP register command (upper byte already $81xx)
	ADD.w	D7, D5			; advance register number (+$0100 → $82xx, $83xx, ...)
	DBF	D1, EntryPoint_VdpInitLoop
	MOVE.l	#$40000080, (A4)	; VDP: write address = VRAM $0000 (auto-inc 1 after)
	MOVE.w	D0, (A3)		; write $0000 to VDP data port (prime it)
	MOVE.w	D7, (A1)		; Z80_bus_request = $8100 → request Z80 bus
	MOVE.w	D7, (A2)		; Z80_reset = $8100 → hold Z80 in reset
WaitForZ80:
	BTST.b	D0, (A1)		; test bit 0 of Z80_bus_request → 0 = bus granted
	BNE.b	WaitForZ80
	MOVEQ	#$00000027, D2		; copy 40 bytes (39+1) of Z80 driver stub
EntryPoint_Z80DriverCopyLoop:
	MOVE.b	(A5)+, (A0)+		; copy from VDPInitValues_End into Z80 RAM
	DBF	D2, EntryPoint_Z80DriverCopyLoop
	MOVE.w	D0, (A2)		; Z80_reset = 0 → release Z80 reset
	MOVE.w	D0, (A1)		; Z80_bus_request = 0 → release Z80 bus
	MOVE.w	D7, (A2)		; Z80_reset = $8100 → hold Z80 in reset again
EntryPoint_ClearRamLoop:
	MOVE.l	D0, -(A6)		; fill RAM with $00000000, descending from $00000000
	DBF	D6, EntryPoint_ClearRamLoop	; clears $10000 bytes ($FFFF0000–$FFFFFFFF)
	MOVE.l	#$81048F02, (A4)	; VDP reg $81 = $04 (re-enable display off + DMA)
					; VDP reg $8F = $02 (auto-increment 2 bytes)
	MOVE.l	#$C0000000, (A4)	; VDP: write address = VSRAM $0000
	MOVEQ	#$0000001F, D3		; 32 long-words = 128 bytes of VSRAM
EntryPoint_VsramClearLoop:
	MOVE.l	D0, (A3)		; clear VSRAM entry
	DBF	D3, EntryPoint_VsramClearLoop
	MOVE.l	#$40000010, (A4)	; VDP: write address = VRAM $0000 (HScroll table)
	MOVEQ	#$00000013, D4		; 20 entries (19+1)
EntryPoint_HscrollClearLoop:
	MOVE.l	D0, (A3)		; clear HScroll table entry
	DBF	D4, EntryPoint_HscrollClearLoop
	MOVEQ	#3, D5			; 4 Z80 register init bytes
EntryPoint_Z80InitLoop:
	MOVE.b	(A5)+, $10(A3)		; write to VDP data port + $10 (= PSG port $C00011)
	DBF	D5, EntryPoint_Z80InitLoop
	MOVE.w	D0, (A2)		; release Z80 reset
	MOVEM.l	(A6), D0/D1/D2/D3/D4/D5/D6/D7/A0/A1/A2/A3/A4/A5/A6	; restore all regs from cleared RAM (all = 0)
	MOVE	#$2700, SR		; supervisor mode, interrupts disabled
	BRA.b	StartupSequence

; -----------------------------------------------------------------------
; BootParamTable
; Eight 32-bit values loaded into D5/D6/D7/A0/A1/A2/A3/A4 by EntryPoint.
; Sits immediately after EntryPoint in ROM so LEA BootParamTable(PC) works.
; -----------------------------------------------------------------------
BootParamTable:
	dc.l	$00008000	
	dc.l	$00003FFF	
	dc.l	$00000100	
	dc.l	$00A00000	
	dc.l	Z80_bus_request	
	dc.l	Z80_reset	
	dc.l	VDP_data_port	
	dc.l	VDP_control_port	

; -----------------------------------------------------------------------
; VDPInitValues
; Table of 23 bytes written to VDP registers $80–$96 during EntryPoint.
; EntryPoint_VdpInitLoop writes each byte as a VDP register command:
;   D5 = value byte, then MOVE.w D5, VDP_ctrl (sends $81xx, $82xx, … to VDP)
; Immediately followed by 40 bytes of Z80 driver stub + 4 Z80 init bytes.
; -----------------------------------------------------------------------
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
	; Z80 sound driver stub (40 bytes) — copied to Z80 RAM by EntryPoint_Z80DriverCopyLoop
	dc.b	$AF, $01, $D7, $1F, $11, $29, $00, $21 
	dc.b	$28, $00, $F9, $77, $ED, $B0, $DD, $E1, $FD, $E1, $ED, $47, $ED, $4F, $08, $D9, $F1, $C1, $D1, $E1, $08, $D9, $F1, $D1, $E1, $F9, $F3, $ED, $56, $36, $E9, $E9 
	; 4 Z80 PSG init bytes — written to PSG port ($C00011) by EntryPoint_Z80InitLoop
	dc.b	$9F, $BF, $DF, $FF 

; -----------------------------------------------------------------------
; StartupSequence
; Game-level hardware and graphics initialization, entered from EntryPoint
; (or directly if cold boot was already done on a warm reset path).
;
; Steps:
;   1. Briefly request Z80 bus to read the expansion port control byte
;      (bit 6 = connected expansion device; skips InitVDP if set).
;   2. TMSS handshake (Model 1): read IO_version region bits; if non-zero
;      write 'SEGA' to TMSS_register.
;   3. ClearRAMAndInitHardware  — zero game RAM + reinitialize VDP/hardware.
;   4. InitBasicObjectSlots     — set up the initial object slot list.
;   5. ExecuteVdpDmaFromPointer_Setup — install the self-modifying DMA stub.
;   6. LoadAndDecompressTileGfx — decompress and DMA base tile graphics.
;   7. LoadTownTileGfxSet1      — DMA town tileset 1 to VRAM.
;   8. InitPlayerInventoryDefaults — fill player inventory with defaults.
;   9. Enable interrupts and fall into MainGameLoop.
; -----------------------------------------------------------------------
StartupSequence:
	MOVE.w	#$0100, Z80_bus_request		; request Z80 bus
	MOVE.b	IO_ctrl_expansion, D0		; read expansion port control byte
	MOVE.w	#0, Z80_bus_request		; release Z80 bus
	BTST.l	#6, D0				; bit 6: expansion device connected?
	BNE.w	StartupSequence_Init		; yes → skip InitVDP (device handles it)
	JSR	InitVDP				; cold init: program all VDP registers
StartupSequence_Init:
	MOVE.b	IO_version, D0			; read hardware version register
	ANDI.b	#$0F, D0			; isolate region/version nibble
	BEQ.b	StartupSequence_SetupHardware	; 0 = no TMSS required (Model 2+)
	MOVE.l	#'SEGA', TMSS_register		; Model 1: write TMSS unlock token
StartupSequence_SetupHardware:
	ORI	#$0700, SR			; disable interrupts during setup
	JSR	ClearRAMAndInitHardware		; (core.asm) — clears game RAM, inits VDP/DMA
	JSR	InitBasicObjectSlots		; (core.asm) — builds initial object slot linked list
	JSR	ExecuteVdpDmaFromPointer_Setup	; (battle_gfx.asm) — primes DMA stub + loads tile buffer
	JSR	LoadAndDecompressTileGfx	; (battle_gfx.asm) — decompress + DMA base graphics
	JSR	LoadTownTileGfxSet1		; (battle_gfx.asm) — DMA town tileset 1
	JSR	InitPlayerInventoryDefaults	; (items.asm) — fill inventory with starting items
	ANDI	#$F8FF, SR			; re-enable interrupts (IPL = 0)

; -----------------------------------------------------------------------
; MainGameLoop
; Per-frame driver. Runs forever at VBlank rate (50 or 60 Hz).
;
; Each iteration:
;   1. Reset stack to Stack_base ($FFFFFE00) — prevents stack leaks.
;   2. WaitForVBlank — spin until VBlank interrupt fires.
;   3. Clear Sprite_update_pending flag, then upload queued sprite OAM
;      (SortAndUploadSpriteOAM_Alt — used during gameplay).
;   4. Clear Sprite_attr_count (sprite slot counter for this frame).
;   5. ObjectDispatchLoop — walk the object slot linked list; for each
;      active slot (bit 7 of byte 0 set), call its function pointer at +$02.
;   6. If NOT in first-person dungeon mode, call SortAndUploadSpriteOAM
;      (the second OAM upload, used outside first-person view).
;   7. Set Sprite_update_pending = $FF (signal VBlank handler).
;   8. Loop back.
; -----------------------------------------------------------------------
MainGameLoop:
	LEA	Stack_base.w, A7		; reset stack to top of stack region
	BSR.w	WaitForVBlank			; wait for next VBlank interrupt
	CLR.b	Sprite_update_pending.w		; clear pending flag
	JSR	SortAndUploadSpriteOAM_Alt	; (battle_gfx.asm) DMA sprite OAM (alt path)
	CLR.w	Sprite_attr_count.w		; reset sprite slot counter for this frame
	LEA	Object_slot_base.w, A5		; A5 = head of object slot linked list
ObjectDispatchLoop:
	BTST.b	#7, (A5)			; bit 7 of slot byte 0 = slot active?
	BEQ.b	ObjectDispatchNext		; no: skip this slot
	MOVEA.l	$2(A5), A0			; A0 = function pointer at slot+$02
	JSR	(A0)				; call slot's update function
ObjectDispatchNext:
	CLR.w	D0
	MOVE.b	$1(A5), D0			; load next-slot stride from slot+$01
	BEQ.b	ObjectDispatchEnd		; 0 = end of list
	ADDA.w	D0, A5				; advance A5 by stride
	BRA.b	ObjectDispatchLoop
ObjectDispatchEnd:
	TST.b	Player_in_first_person_mode.w	; in first-person dungeon view?
	BNE.b	ObjectDispatchDone		; yes: skip 2D sprite OAM upload
	JSR	SortAndUploadSpriteOAM		; (battle_gfx.asm) DMA sprite OAM (normal path)
ObjectDispatchDone:
	MOVE.b	#$FF, Sprite_update_pending.w	; signal VBlank handler: OAM data ready
	BRA.b	MainGameLoop			; loop forever

; -----------------------------------------------------------------------
; ClearVblankFlagAndWait
; Clears Vblank_flag as a word (zeroes both the flag byte and the next byte)
; then falls through to WaitForVBlank.  Encoded as raw dc.b because it uses
; a CLR.w addressing mode not expressible as a standard instruction here.
;   $4238 C0FF = CLR.w $FFFFC0FF.w  (Vblank_flag, word-clear)
; -----------------------------------------------------------------------
ClearVblankFlagAndWait:
	dc.b	$42, $38, $C0, $FF	; CLR.w Vblank_flag (word-clear), fall through

; -----------------------------------------------------------------------
; WaitForVBlank
; Spin-waits until the VBlank interrupt handler sets Vblank_flag ($FFFFC0FF),
; then clears the flag and returns.  Called at the top of every MainGameLoop
; iteration to synchronize game logic to the display refresh rate.
; -----------------------------------------------------------------------
WaitForVBlank:
	TST.b	Vblank_flag.w			; has VBlank interrupt fired?
	BEQ.b	WaitForVBlank			; no: keep spinning
	CLR.b	Vblank_flag.w			; yes: clear flag and return
	RTS
