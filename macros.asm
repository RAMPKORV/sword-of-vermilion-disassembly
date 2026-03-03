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
    JSR     QueueSoundEffect
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

; ============================================================
; Chest Treasure Macros
; ============================================================
; These macros replace the common 4-instruction treasure setup
; pattern used for chests and reward pickups throughout the game.
;
; Each sets the reward value and opened-flag address, then calls
; the appropriate setup function which checks if the chest was
; already opened and initializes the reward dialog.
;
; value: Item/equipment ID or money amount (word)
; flag:  RAM address of the opened-flag byte

; Item chest: herbs, candles, lanterns, quest items, etc.
ItemChest macro value,flag
    MOVE.w  #value, Reward_script_value.w
    MOVE.l  #flag, Reward_script_flag.w
    BSR.w   SetupItemTreasure
    RTS
    ENDM

; Equipment chest: swords, armor, shields
; equipType: EQUIPMENT_TYPE_SWORD, EQUIPMENT_TYPE_SHIELD, or EQUIPMENT_TYPE_ARMOR
; equipId:   Equipment ID constant (e.g. EQUIPMENT_SWORD_GRAPHITE)
; cursed:    Optional - EQUIPMENT_FLAG_CURSED for cursed items
; flag:      RAM address of the opened-flag byte
EquipChest macro equipType,equipId,flag,cursed
    if NARG>3
    MOVE.w  #((equipType|cursed)<<8)|equipId, Reward_script_value.w
    else
    MOVE.w  #(equipType<<8)|equipId, Reward_script_value.w
    endc
    MOVE.l  #flag, Reward_script_flag.w
    BSR.w   SetupEquipmentTreasure
    RTS
    ENDM

; Money chest: kims (gold)
MoneyChest macro value,flag
    MOVE.w  #value, Reward_script_value.w
    MOVE.l  #flag, Reward_script_flag.w
    BSR.w   InitMoneyTreasure
    RTS
    ENDM

; Ring/special chest: rings of earth/wind, crystals, maps
; Uses SetupChestReward directly with explicit type
; type: Reward type (4=ring, 5=map, etc.)
RingChest macro type,value,flag
    MOVE.w  #type, Reward_script_type.w
    MOVE.w  #value, Reward_script_value.w
    MOVE.l  #flag, Reward_script_flag.w
    BSR.w   SetupChestReward
    RTS
    ENDM

; ============================================================
; Dialogue Script Command Macros
; ============================================================
; These macros emit the byte sequences consumed by ProcessScriptText
; (src/script.asm). They replace raw $F8/$F9/$FA/$FB/$FC byte sequences
; with readable names. Opcodes and constants are defined in constants.asm.
;
; IMPORTANT: script_actions <n> must be followed by exactly <n> entry macros
; (script_set_trigger / script_reveal_map / script_give_kims). The assembler
; cannot enforce this count — it is the programmer's responsibility.
;
; IMPORTANT: macros that emit multiple dc.b directives cannot be embedded
; inline inside a string dc.b. Split the dc.b line at the command byte first.

; --- $FC SCRIPT_QUESTION ---
; Reads the player's response into Dialog_response_index.
; Usage: script_cmd_question <response_index>
script_cmd_question macro response
    dc.b    SCRIPT_QUESTION, response
    ENDM

; --- $FB SCRIPT_YES_NO ---
; Shows a YES/NO prompt; on answer sets Dialog_choice_event_trigger.
; Usage: script_cmd_yes_no <response_index>, <event_trigger_offset>, <ext_trigger>
script_cmd_yes_no macro response, trigger, ext_trigger
    dc.b    SCRIPT_YES_NO, response, trigger, ext_trigger
    ENDM

; --- $FA SCRIPT_CHOICE ---
; Validates player's prior answer; sets Quest_choice_map_trigger if matched.
; Usage: script_cmd_choice <expected_answer>, <map_trigger>
script_cmd_choice macro answer, map_trigger
    dc.b    SCRIPT_CHOICE, answer, map_trigger
    ENDM

; --- $F8 SCRIPT_TRIGGERS: set story trigger flags ---
; Each argument is a 1-byte offset into Event_triggers_start.
; Writes FLAG_TRUE ($FF) to Event_triggers_start + offset.
; Usage: script_cmd_triggers <t1> [, <t2>]
script_cmd_triggers macro t1, t2
    if NARG=1
    dc.b    SCRIPT_TRIGGERS, 1, t1
    endc
    if NARG=2
    dc.b    SCRIPT_TRIGGERS, 2, t1, t2
    endc
    ENDM

; --- $F9 SCRIPT_ACTIONS: action list header ---
; Emits the opcode and entry count. Must be followed by exactly <count>
; entry macros: script_set_trigger, script_reveal_map, or script_give_kims.
; Usage: script_cmd_actions <count>
script_cmd_actions macro count
    dc.b    SCRIPT_ACTIONS, count
    ENDM

; --- $F9 entry: set story trigger ---
; Writes FLAG_TRUE to Event_triggers_start + offset (16-bit, high byte = $00).
; Usage: script_set_trigger <offset>
script_set_trigger macro offset
    dc.b    $00, offset
    ENDM

; --- $F9 entry: reveal world map sector ---
; Writes FLAG_TRUE to Event_triggers_start + $0100 + sector.
; Usage: script_reveal_map <sector>
script_reveal_map macro sector
    dc.b    $01, sector
    ENDM

; --- $F9 entry: give kims (BCD) ---
; Adds a BCD-encoded kim amount to the player's wallet via AddPaymentAmount.
; Amount is a 4-byte packed BCD longword (most-significant pair first).
; Example: 200 kims = $00000200
; Usage: script_give_kims <bcd_longword>
; Note: Transaction_item_id/quantity/flags are loaded from bytes 2-4 of the
;       longword and should be $00 for a pure kim reward.
script_give_kims macro bcd_amount
    dc.b    $02, (bcd_amount>>24)&$FF, (bcd_amount>>16)&$FF, (bcd_amount>>8)&$FF, bcd_amount&$FF
    ENDM

; ============================================================
; NPC Entry Macro
; ============================================================
; Defines a single NPC entry in a town NPC data table.
; Each entry is 16 bytes, read by LoadTownNPCs.
;
; xpos:  World X position in pixels (word, stored to entity +$0E)
; ypos:  World Y position in pixels (word, stored to entity +$12)
; tile:  Initial VRAM sprite tile index (word, stored to entity +$08)
; anim:  Sprite frame animation table pointer (long, stored to entity +$2E)
; tick:  NPC init/behavior function pointer (long, stored to entity +$02)
; attr:  Sprite attribute flags byte (palette/priority, stored to entity +$07)
;        Use NPC_ATTR_PAL3 ($60) for character palette, NPC_ATTR_PAL0 ($00) for BG palette
; solid: Collision flag byte (stored to entity +$2D)
;        Use NPC_SOLID ($01) for blocking NPCs, NPC_NONSOLID ($00) for walkthrough
npcEntry macro xpos,ypos,tile,anim,tick,attr,solid
    dc.w    xpos, ypos, tile
    dc.l    anim, tick
    dc.b    attr, solid
    ENDM
