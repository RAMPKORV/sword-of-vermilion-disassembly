; ============================================================
; Print Macro
; ============================================================
; Sets the script source pointer for dialogue display
print macro strPtr
    MOVE.l  #strPtr, Script_source_base.w
    ENDM

; ============================================================
; PlaySound Macro
; ============================================================
; Plays a sound effect by ID
; Usage: PlaySound SOUND_MENU_CANCEL
;        PlaySound $00A8
PlaySound macro soundId
    MOVE.w  #soundId, D0
    JSR     loc_00010522
    ENDM

; ============================================================
; VDP Communication Macros
; ============================================================
; VDP memory type constants
VRAM = %100001
CRAM = %101011
VSRAM = %100101

; VDP access mode constants
READ = %001100
WRITE = %000111
DMA = %100111

; Generate VDP command longword for setting read/write address
; addr: VRAM/CRAM/VSRAM address
; type: VRAM, CRAM, or VSRAM constant
; rwd: READ, WRITE, or DMA constant
; Returns: Complete VDP command in D0
vdpComm macro addr,type,rwd,dest
    MOVE.l  #((((type&rwd)&3)<<30)|((addr&$3FFF)<<16)|(((type&rwd)&$FC)<<2)|((addr&$C000)>>14)), dest
    ENDM

; ============================================================
; Z80 Bus Control Macros
; ============================================================
; Stop the Z80 and wait for bus acquisition
stopZ80 macro
    MOVE.w  #$100, (Z80_bus_request).l
.loop\@:
    BTST.b  #0, (Z80_bus_request).l
    BNE.s   .loop\@
    ENDM

; Release the Z80 bus
startZ80 macro
    MOVE.w  #0, (Z80_bus_request).l
    ENDM

; ============================================================
; RAM Clearing Macro
; ============================================================
; Efficiently clear a range of RAM to zero
; Handles odd alignment and uses long moves for speed
; NOTE: Uses A0 and D0 to match original code patterns
clearRAM macro startaddr,endaddr
    LEA     startaddr, A0
    MOVE.w  #((endaddr-startaddr)/4-1), D0
.loop\@:
    CLR.l   (A0)+
    DBF     D0, .loop\@
    ENDM

; ============================================================
; Object Initialization Table Macros
; ============================================================
; Define an object initialization group
; copies: Number of objects to create (will store copies-1)
; words: Size in words of each object (will store words-1)
; type: Object type byte
; flags: Object flags byte
; handler: Address of handler routine (or 0)
; ptr_dest: Where to store the object pointer
objectInitGroup macro copies,words,type,flags,handler,ptr_dest
    dc.w    (copies)-1, (words)-1, type, flags
    dc.l    handler
    dc.l    ptr_dest
    ENDM

; ============================================================
; Offset Table Macros
; ============================================================
; Declare the start of an offset table
offsetTable macro
current_offset_table set *
    ENDM

; Declare a word-sized offset entry
offsetTableEntry.w macro ptr
    dc.w    ptr-current_offset_table
    ENDM

; Declare a long-sized offset entry
offsetTableEntry.l macro ptr
    dc.l    ptr-current_offset_table
    ENDM

; ============================================================
; Tile/VRAM Helper Macros
; ============================================================
; Convert tile count to byte count
; tiles: Number of tiles
; dest: Destination register
tiles_to_bytes macro tiles,dest
    MOVE.w  #((tiles)<<5), dest
    ENDM

; Make a tile attribute word with palette and priority
; addr: Tile index in VRAM
; pal: Palette number (0-3)
; pri: Priority (0 or 1)
; dest: Destination (register or memory)
make_art_tile macro addr,pal,pri,dest
    MOVE.w  #((((pri)&1)<<15)|(((pal)&3)<<13)|((addr)&$7FF)), dest
    ENDM
