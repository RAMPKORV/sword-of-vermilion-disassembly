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
VDP_CMD_VRAM_WRITE_PLANE_A  = $40000003  ; VRAM write to $C000 (Plane A nametable base)
VDP_CMD_VRAM_WRITE_PLANE_B  = $60000003  ; VRAM write to $E000 (Plane B nametable base)
VDP_CMD_VRAM_WRITE_HSCROLL  = $7C000002  ; VRAM write to $BC00 (HScroll table base)
VDP_CMD_VRAM_WRITE_SAT      = $78000002  ; VRAM write to $B800 (Sprite Attribute Table)
VDP_CMD_CRAM_WRITE_0        = $C0000000  ; CRAM write to address 0 (palette entry 0)
VDP_CMD_VSRAM_WRITE_0       = $40000010  ; VSRAM write to address 0 (scroll table entry 0)

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
