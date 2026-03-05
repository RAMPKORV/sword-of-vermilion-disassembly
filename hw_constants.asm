; ======================================================================
; hw_constants.asm
; Hardware port addresses, VRAM layout, VDP command words, DMA fill
; words, hardware init, and VBlank/scroll constants.
; ======================================================================

; ============================================================
; Hardware Port Addresses
; ============================================================
; VDP (Video Display Processor)
VDP_data_port       = $C00000
VDP_control_port    = $C00004
PSG_port            = $C00011   ; Programmable Sound Generator (directly accessed)

; Z80 Bus Control
Z80_bus_request     = $A11100
Z80_reset           = $A11200
Z80_ram             = $A00000   ; Start of Z80 address space (8 KB)
Z80_sound_ram       = $A00200   ; Sound driver data region in Z80 RAM
Z80_BUS_ON          = $0100    ; Value written to Z80_bus_request to request the bus
Z80_BUS_OFF         = $0000    ; Value written to Z80_bus_request to release the bus

; YM2612 FM Synthesis Chip Ports (accessed from 68000 via Z80 bus arbitration)
; Port A controls FM channels 1-3; Port B controls FM channels 4-6.
YM2612_addr_port_1  = $A04000  ; YM2612 port A: write register address (channels 1-3)
YM2612_data_port_1  = $A04001  ; YM2612 port A: write register data    (channels 1-3)
YM2612_addr_port_2  = $A04002  ; YM2612 port B: write register address (channels 4-6)
YM2612_data_port_2  = $A04003  ; YM2612 port B: write register data    (channels 4-6)

; Z80 DAC / PCM Sample Ports (mapped in Z80 address space, accessed by 68000 via bus grant)
; These addresses are in the Z80's local address space ($A00000-$A01FFF from 68K perspective).
Z80_dac_status      = $A01FFD  ; Bit 7: YM2612 busy flag (poll before writes)
Z80_dac_bank        = $A01FFE  ; PCM sample bank select (upper address bits)
Z80_dac_sample      = $A01FFF  ; PCM sample data byte (written to YM2612 DAC channel 6)

; I/O Ports
IO_version          = $A10001   ; Hardware version / region register
IO_data_port_1      = $A10003   ; Controller 1 data port
IO_data_port_2      = $A10005   ; Controller 2 data port
IO_expansion        = $A10007   ; Expansion port data
IO_init_status      = $A10008   ; I/O initialization status (longword)
IO_ctrl_port_1      = $A10009   ; Controller 1 control port
IO_ctrl_port_2      = $A1000B   ; Controller 2 control port
IO_ctrl_expansion   = $A1000D   ; Expansion port control
IO_VERSION_REGION_MASK_W = $0F00 ; Mask for region bits when IO_version read as word ($A10000)
IO_VERSION_REGION_MASK_B = $0F   ; Mask for region/version nibble when IO_version read as byte
IO_VERSION_PAL_BIT       = 6     ; Bit 6 of IO_version: set = PAL (50 Hz), clear = NTSC (60 Hz)
IO_init_status_w    = $A1000C   ; I/O initialization status (word check)

; TMSS (Trademark Security System)
TMSS_register       = $A14000   ; Write 'SEGA' here to unlock VDP

; YM2612 FM Synthesis
YM2612_addr_0       = $A04000   ; YM2612 address port (bank 0: channels 1-3)
YM2612_data_0       = $A04001   ; YM2612 data port (bank 0)
YM2612_addr_1       = $A04002   ; YM2612 address port (bank 1: channels 4-6)
YM2612_data_1       = $A04003   ; YM2612 data port (bank 1)

; ============================================================
; VRAM Layout
; ============================================================
; Addresses of major structures in VDP VRAM, as configured by
; VDPInitValues in init.asm. These are VRAM-internal addresses,
; not 68k bus addresses.
;
VRAM_Plane_A        = $C000     ; Scroll A nametable (64x32 = $1000 bytes)
VRAM_Plane_B        = $E000     ; Scroll B nametable (64x32 = $1000 bytes)
VRAM_Window         = $F000     ; Window plane nametable
VRAM_Sprites        = $B800     ; Sprite attribute table (80 entries, $280 bytes)
VRAM_HScroll        = $BC00     ; Horizontal scroll table

; ============================================================
; VDP Command Longwords
; ============================================================
; Longwords written directly to VDP_control_port to set the
; VRAM/CRAM/VSRAM write destination address.
; Formula: vram_write_cmd(A) = $40000000 | ((A & $3FFF) << 16) | ((A >> 14) & 3)
;
; Address mask: ANDI.l #VDP_CMD_VRAM_WRITE_ADDR_MASK, Dn
;   Clears the address portion while preserving command type bits.
;   Used after ADDI.l #VDP_VRAM_ROW_STRIDE to fix any carry overflow.

; --- Named VRAM destinations (Plane A = $C000, Plane B = $E000) ---
VDP_CMD_VRAM_WRITE_PLANE_A  = $40000003  ; VRAM write to $C000 (Plane A nametable base)
VDP_CMD_VRAM_WRITE_PLANE_B  = $60000003  ; VRAM write to $E000 (Plane B nametable base)
VDP_CMD_VRAM_WRITE_HSCROLL  = $7C000002  ; VRAM write to $BC00 (HScroll table base)
VDP_CMD_VRAM_WRITE_SAT      = $78000002  ; VRAM write to $B800 (Sprite Attribute Table)
VDP_CMD_CRAM_WRITE_0        = $C0000000  ; CRAM write to address 0 (palette entry 0)
VDP_CMD_VSRAM_WRITE_0       = $40000010  ; VSRAM write to address 0 (scroll table entry 0)

; --- Address mask for row-advance fixup ---
VDP_CMD_VRAM_WRITE_ADDR_MASK = $5FFF0003  ; Clears addr bits after row-stride add (ANDI.l mask)

; --- Plane A VRAM write commands (specific offsets, multi-use) ---
VDP_CMD_VRAM_WRITE_C082     = $40820003  ; VRAM write to $C082 (Plane A, dungeon wall tile row 1)
VDP_CMD_VRAM_WRITE_C13C     = $413C0003  ; VRAM write to $C13C (Plane A, town tilemap render start)
VDP_CMD_VRAM_WRITE_C1A2     = $41A20003  ; VRAM write to $C1A2 (Plane A row 3, col 81)
VDP_CMD_VRAM_WRITE_C204     = $42040003  ; VRAM write to $C204 (Plane A row 4, col 2)
VDP_CMD_VRAM_WRITE_C3BE     = $43BE0003  ; VRAM write to $C3BE (Plane A, boss text row 1)
VDP_CMD_VRAM_WRITE_C404     = $44040003  ; VRAM write to $C404 (Plane A row 8, col 2)
VDP_CMD_VRAM_WRITE_C482     = $44820003  ; VRAM write to $C482 (Plane A, dungeon wall tile row 9)
VDP_CMD_VRAM_WRITE_C642     = $46420003  ; VRAM write to $C642 (Plane A, boss HP gauge row)
VDP_CMD_VRAM_WRITE_C8C2     = $48C20003  ; VRAM write to $C8C2 (Plane A, boss text row 2)
VDP_CMD_VRAM_WRITE_CA04     = $4A040003  ; VRAM write to $CA04 (Plane A row 10, col 2)
VDP_CMD_VRAM_WRITE_CCB6     = $4CB60003  ; VRAM write to $CCB6 (Plane A, HUD message area row 1)
VDP_CMD_VRAM_WRITE_CD36     = $4D360003  ; VRAM write to $CD36 (Plane A, HUD message area row 2)

; --- Plane B VRAM write commands (specific offsets, multi-use) ---
VDP_CMD_VRAM_WRITE_E0AA     = $60AA0003  ; VRAM write to $E0AA (Plane B row 1, col 85)
VDP_CMD_VRAM_WRITE_E0AE     = $60AE0003  ; VRAM write to $E0AE (Plane B row 1, col 87)
VDP_CMD_VRAM_WRITE_E106     = $61060003  ; VRAM write to $E106 (Plane B row 2, col 3)
VDP_CMD_VRAM_WRITE_E710     = $67100003  ; VRAM write to $E710 (Plane B row 14, col 8)
VDP_CMD_VRAM_WRITE_E714     = $67140003  ; VRAM write to $E714 (Plane B row 14, col 10)
VDP_CMD_VRAM_WRITE_E980     = $69800003  ; VRAM write to $E980 (Plane B, credits staff names area)
VDP_CMD_VRAM_WRITE_ECB6     = $6CB60003  ; VRAM write to $ECB6 (Plane B, HUD message area row 1)
VDP_CMD_VRAM_WRITE_ED36     = $6D360003  ; VRAM write to $ED36 (Plane B, HUD message area row 2)

; --- Other VRAM write commands (multi-use) ---
VDP_CMD_VRAM_WRITE_8560     = $45600002  ; VRAM write to $8560 (overworld tilemap window area)

; --- VRAM DMA write commands (battle sprite tile transfer destinations) ---
; These are VRAM DMA write commands (CD bits = 0x21) used by UpdatePlayerSpriteDMA.
; Each names a sprite tile slot in VRAM for battle animation DMA transfers.
VDP_DMA_VRAM_WRITE_0200     = $40200080  ; VRAM DMA write to $0200 (battle sprite slot: enemy main)
VDP_DMA_VRAM_WRITE_1A00     = $41A00080  ; VRAM DMA write to $1A00 (battle sprite slot: player)
VDP_DMA_VRAM_WRITE_2200     = $42200080  ; VRAM DMA write to $2200 (battle sprite slot: player boss battle)
VDP_DMA_VRAM_WRITE_2A00     = $42A00080  ; VRAM DMA write to $2A00 (battle sprite slot: ally/partner)
VDP_DMA_VRAM_WRITE_3A00     = $43A00080  ; VRAM DMA write to $3A00 (battle sprite slot: boss slot 2)

; ============================================================
; VDP DMA Fill Destination Words
; ============================================================
; Longwords passed as the 'dest' argument to DMAFillVRAM /
; VDP_DMAFill.  The subroutine ORs in $40000080 (VRAM write +
; DMA fill CD bits) before issuing the VDP command.
;
VDP_DMA_FILL_SAT            = $78000002  ; DMA fill destination: Sprite Attribute Table ($B800)
VDP_DMA_FILL_HSCROLL        = $7C000002  ; DMA fill destination: HScroll table ($BC00)
VDP_DMA_FILL_PLANE_A        = $40000003  ; DMA fill destination: Plane A nametable ($C000)
VDP_DMA_FILL_PLANE_B        = $60000003  ; DMA fill destination: Plane B nametable ($E000)
VDP_DMA_FILL_WINDOW         = $70000002  ; DMA fill destination: Window plane ($B000)
VDP_DMA_FILL_VRAM_START     = $40000000  ; DMA fill destination: VRAM address 0

; VRAM region fill sizes (byte count - 1, as passed to DMAFillVRAM)
VRAM_PLANE_FILL_SIZE        = $1FFF      ; 8192 bytes per nametable plane (64×64 tiles × 2)
VRAM_SAT_FILL_SIZE          = $013F      ; 320 bytes (sprite attribute table fill region)
VRAM_HSCROLL_FILL_SIZE      = $03BF      ; 960 bytes (horizontal scroll table)
VRAM_WINDOW_FILL_SIZE       = $0DFF      ; 3584 bytes (window plane fill region)

; ============================================================
; Hardware Init Constants
; ============================================================
IO_CTRL_DIR_OUTPUT          = $40       ; IO control port value: all data pins = output
VDP_INIT_REG_COUNT_MINUS1   = $0F       ; 16 VDP registers initialized at startup
VSRAM_CLEAR_COUNT           = $28       ; DBF count for VSRAM clear (41 entries, words)
STACK_CLEAR_LONGS_MINUS1    = $7F       ; DBF count for stack clear (128 longs = $200 bytes)
Z80_RESET_DELAY_LOOPS       = $0013     ; DBF count for Z80 reset stabilization delay
Z80_DRIVER_SIZE_MINUS1      = $013F     ; Z80 sound driver binary size in bytes - 1 (320 bytes)

; ============================================================
; VBlank / Scroll Constants
; ============================================================
SCROLL_RANGE_MASK           = $01FF     ; 9-bit mask for 512-pixel scroll range
HSCROLL_CLEAR_COUNT         = $01FF     ; DBF count for HScroll/VScroll clear (512 entries - 1)
HSCROLL_TABLE_ENTRY_STRIDE  = $00040000 ; VDP cmd address increment per HScroll row (4 bytes)
VDP_VRAM_ROW_STRIDE         = $00800000 ; VDP cmd address increment per nametable row (64 tiles × 2 bytes = 128 = $80)
HSCROLL_ROW_COUNT_MINUS1    = $00DF     ; Per-line HScroll fill: 224 rows - 1 (DBF count)
PAL_DELAY_LOOP_COUNT        = $021D     ; PAL 50 Hz timing delay (long, every 4th frame)
PAL_SHORT_DELAY_LOOP_COUNT  = $0657     ; PAL 50 Hz timing delay (short, other frames)
NTSC_FRAMES_PER_SECOND      = $3C       ; Frames per second (60 for NTSC)
PROGRAM_STATE_COUNT         = $16       ; Number of program states (22)

; ============================================================
; CPU / Address Space Constants
; ============================================================
; The 68000 has a 24-bit address bus. ROM pointers stored in 32-bit
; registers must be masked to 24 bits before use as effective addresses.
; This mask strips the high byte of any 32-bit ROM pointer.
ROM_ADDRESS_MASK            = $00FFFFFF ; Mask 32-bit value to 24-bit ROM address

; ============================================================
; PSG Mute Register Bytes
; ============================================================
; Written to PSG_port to set maximum attenuation ($F) on each
; PSG channel.  Each byte encodes: bit7=1 (latch), bits5-4=ch
; index, bit4=1 (volume register), bits3-0=$F (max attenuation).
;
PSG_CH0_MUTE        = $9F   ; PSG channel 0 latch: max attenuation (vol reg, $F)
PSG_CH1_MUTE        = $BF   ; PSG channel 1 latch: max attenuation
PSG_CH2_MUTE        = $DF   ; PSG channel 2 latch: max attenuation
PSG_CH3_MUTE        = $FF   ; PSG channel 3 latch: max attenuation (noise ch)
