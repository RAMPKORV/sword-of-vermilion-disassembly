; ============================================================
; IsPalRegion Macro
; ============================================================
; Test whether the console is running in PAL mode (50 Hz).
; Bit 6 of IO_version ($A10001) is set on PAL hardware.
; After expansion, test the Z flag with BNE (PAL) or BEQ (NTSC).
;
; Usage:
;   IsPalRegion
;   BNE.b   .palPath     ; branch if PAL (bit 6 set)
;   ... NTSC path ...
; .palPath:
;   ... PAL path ...
;
; Note: all 11 call sites in the codebase use the explicit
;   BTST.b #6, IO_version
; form.  This macro is provided as the canonical named form
; for new code and documentation.  Replacing existing sites
; is safe since the expansion is byte-for-byte identical.
IsPalRegion macro
    BTST.b  #IO_VERSION_PAL_BIT, IO_version
    ENDM


; Sets the script source pointer for dialogue display
print macro strPtr
    MOVE.l  #strPtr, Script_source_base.w
    ENDM

; ============================================================
; PlaySound Macros
; ============================================================
; Play a sound effect by ID via QueueSoundEffect.
; Two variants exist to preserve the original instruction size:
;   PlaySound   - uses MOVE.w (word immediate, 4-byte instruction)
;   PlaySound_b - uses MOVE.b (byte immediate, 4-byte instruction)
; Both produce bit-identical output to the original code.
; Usage: PlaySound   SOUND_MENU_CANCEL
;        PlaySound_b SOUND_TRANSITION
PlaySound macro soundId
    MOVE.w  #soundId, D0
    JSR     QueueSoundEffect
    ENDM

PlaySound_b macro soundId
    MOVE.b  #soundId, D0
    JSR     QueueSoundEffect
    ENDM

; ============================================================
; CheckButton Macro
; ============================================================
; Check if a controller button was newly pressed this frame.
; Loads the button bit into D2 and calls CheckButtonPress.
; Result in D0: 1 = pressed, 0 = not pressed (test with BEQ/BNE).
; Note: 6 call sites in gameplay.asm use BSR.w instead of JSR
; and are left as explicit instructions for bit-perfect output.
; Usage: CheckButton BUTTON_BIT_C
;        BEQ.b   .notPressed
CheckButton macro button
    MOVE.w  #button, D2
    JSR     CheckButtonPress
    ENDM

; ============================================================
; Window Setup Macros
; ============================================================
; Set up window position/size and draw the border.
; All variants set Window_tile_attrs to 0 (the only value used in practice)
; and call DrawWindowBorder via BSR.w (all call sites are in script.asm).
;
; SetupWindow   x, y, w, h  - Full setup: position, size, and draw
; SetupWindowSize h          - Set height only (x/y/w already set), and draw
;
; Usage: SetupWindow $000E, $0013, $000B, 6
SetupWindow macro x, y, w, h
    MOVE.w  #x, Window_tilemap_x.w
    MOVE.w  #y, Window_tilemap_y.w
    MOVE.w  #w, Window_width.w
    MOVE.w  #h, Window_height.w
    MOVE.w  #0, Window_tile_attrs.w
    BSR.w   DrawWindowBorder
    ENDM

; Set only the window height (plus attrs=0) and draw, when x/y/w are
; already set from a prior code path (used by empty-inventory fallbacks).
; Usage: SetupWindowSize 5
SetupWindowSize macro h
    MOVE.w  #h, Window_height.w
    MOVE.w  #0, Window_tile_attrs.w
    BSR.w   DrawWindowBorder
    ENDM

; Set window height from D0 (computed at runtime), attrs=0, and draw.
; x/y/w must already be set. Used by dynamic-height windows (shops,
; inventory lists) where the height depends on an item count.
; Usage: <compute height in D0>
;        DrawWindowDynH
DrawWindowDynH macro
    MOVE.w  D0, Window_height.w
    MOVE.w  #0, Window_tile_attrs.w
    BSR.w   DrawWindowBorder
    ENDM

; ============================================================
; Window Redraw Trigger Macros
; ============================================================
; Set the window draw type and trigger a tilemap row redraw.
; Clears Window_text_row and sets Window_tilemap_row_draw_pending = FLAG_TRUE.
;
; Two variants exist because the original code uses two instruction orderings
; (both produce the same logical effect, but different binary encodings):
;   TriggerWindowRedraw     - canonical order (28 sites)
;   TriggerWindowRedraw_alt - swapped order (9 sites, all in items.asm)
;
; Usage: TriggerWindowRedraw WINDOW_DRAW_MSG_SPEED_ALT
TriggerWindowRedraw macro type
    MOVE.w  #type, Window_draw_type.w
    CLR.w   Window_text_row.w
    MOVE.b  #FLAG_TRUE, Window_tilemap_row_draw_pending.w
    ENDM

TriggerWindowRedraw_alt macro type
    MOVE.w  #type, Window_draw_type.w
    MOVE.b  #FLAG_TRUE, Window_tilemap_row_draw_pending.w
    CLR.w   Window_text_row.w
    ENDM

; ============================================================
; Window Tilemap Draw Activation
; ============================================================
; Reset the draw row counter and signal the VBlank handler that
; window tilemap data is ready to be transferred to VDP.
; Used as the epilogue of every Draw...Window function in script.asm.
;
; Usage: ActivateWindowDraw
ActivateWindowDraw macro
    CLR.w   Window_draw_row.w
    MOVE.b  #FLAG_TRUE, Window_tilemap_draw_active.w
    ENDM

; ============================================================
; Menu Cursor Initialization
; ============================================================
; Initialize the menu cursor position and column parameters.
; Sets column_break to cols, last_index to MENU_CURSOR_NONE,
; and base position to (x, y).
;
; Usage: InitMenuCursor 2, $000D, 6
InitMenuCursor macro cols, x, y
    MOVE.w  #cols, Menu_cursor_column_break.w
    MOVE.w  #MENU_CURSOR_NONE, Menu_cursor_last_index.w
    MOVE.w  #x, Menu_cursor_base_x.w
    MOVE.w  #y, Menu_cursor_base_y.w
    ENDM

; ============================================================
; State Completion Gate Macro
; ============================================================
; Advance Program_state and trigger a fade-out when a completion flag is set.
;
; Used in "blocker" state handlers that wait for an async operation to finish
; (name entry, file load, prologue animation, etc.).  When <flag> is zero the
; handler returns immediately (the operation is still in progress).  When <flag>
; is non-zero it advances Program_state to <next_state>, arms the fade-out, and
; falls through to RTS.
;
; The macro produces the same 5-instruction / 20-byte sequence as the inline
; code it replaces, so the assembled binary is bit-perfect.
;
; flag:       RAM flag byte address constant (without .w suffix)
; next_state: PROGRAM_STATE_* constant for the following state
;
; Usage: AdvanceStateOnComplete Prologue_complete_flag, PROGRAM_STATE_PROLOGUE_TO_GAME
; Note:  Pass the flag symbol WITHOUT the .w suffix; the macro appends .w internally
;        via \1.w to preserve the short (word) addressing mode that the original code
;        uses.  Named-arg references (e.g. "flag") are lowercased by ASM68K, which
;        would produce an undefined-symbol error; positional \1/\2 references are used
;        instead to avoid that assembler quirk.
AdvanceStateOnComplete macro flag, next_state
    TST.b   \1.w
    BEQ.b   .done\@
    MOVE.w  #\2, Program_state.w
    MOVE.b  #FLAG_TRUE, Fade_out_lines_mask.w
.done\@:
    RTS
    ENDM


; Zero-fill a region of VRAM via VDP DMA fill.
; dest: VDP command longword encoding the target VRAM address
; len:  Number of bytes to fill
; Every call site uses fill_value=0 and auto_increment=1.
; DMAFillVRAM uses JSR; DMAFillVRAM_bsr uses BSR.w (for battle_gfx.asm).
; Usage: DMAFillVRAM VDP_DMA_FILL_HSCROLL, VRAM_HSCROLL_FILL_SIZE
DMAFillVRAM macro dest, len
    MOVE.l  #dest, D7
    MOVE.w  #len, D6
    MOVE.b  #0, D5
    MOVE.w  #1, D4
    JSR     VDP_DMAFill
    ENDM

DMAFillVRAM_bsr macro dest, len
    MOVE.l  #dest, D7
    MOVE.w  #len, D6
    MOVE.b  #0, D5
    MOVE.w  #1, D4
    BSR.w   VDP_DMAFill
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
; Trampoline to InitObjectsFromTable using Object_table_base.
; Creates a 3-instruction sequence: LEA A0 (base), LEA A1 (table), BRA.w.
; Each call site is a labeled function called via JSR from other modules.
; Usage:
;   InitMenuObjects:
;       initObjects MenuObjectInitTable
initObjects macro initTable
    LEA     Object_table_base.w, A0
    LEA     initTable, A1
    BRA.w   InitObjectsFromTable
    ENDM

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
; DMA Palette Transfer Macro
; ============================================================
; DMA-transfers the full 128-byte palette buffer ($FFFFC000) to CRAM.
; Initializes the VDP DMA RAM routine, sets auto-increment to 2,
; enables DMA, programs source/length registers, executes the transfer,
; then disables DMA.
;
; IMPORTANT: The caller must stop the Z80 bus BEFORE invoking this macro
; and restart it AFTER. Two styles exist in the codebase:
;   - stopZ80 / startZ80 macros (absolute long addressing)
;   - Inline MOVE.w #$0100 / #0 to Z80_bus_request (absolute short addressing)
; The macro does NOT handle Z80 bus control to preserve bit-perfect output
; for both addressing modes.
;
; Clobbers: D4
DMATransferPalette macro
    JSR     InitVdpDmaRamRoutine
    MOVE.w  #2, D4
    ORI.w   #$8F00, D4
    MOVE.w  D4, VDP_control_port
    MOVE.w  VDP_Reg1_cache.w, D4
    BSET.l  #4, D4
    MOVE.w  D4, VDP_control_port
    MOVE.l  #$94009340, VDP_control_port
    MOVE.l  #$96E09500, VDP_control_port
    MOVE.w  #$977F, VDP_control_port
    MOVE.l  #VDP_DMA_CMD_CRAM, Vdp_dma_cmd.w
    JSR     Vdp_dma_ram_routine.w
    MOVE.w  VDP_Reg1_cache.w, D4
    BCLR.l  #4, D4
    MOVE.w  D4, VDP_control_port
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

; ============================================================
; enemyAppearance Macro
; ============================================================
; Defines a single enemy sprite-appearance entry in battledata.asm.
; Each entry is exactly 24 bytes (6 × dc.l), read by the battle
; sprite setup routine.
;
; main_frames:  Pointer to frame table for main body sprite
; main_gfx:     Pointer to GFX data for main body sprite
; child_frames: Pointer to frame table for child sprite
;               (use StartOfRom if no child sprite)
; child_gfx:    Pointer to GFX data for child sprite
;               (use StartOfRom if no child sprite)
; dma_fn:       DMA routine pointer — NullSpriteRoutine-2,
;               ExecuteWorldMapDma, or StartOfRom for boss entries
; vfx:          Packed longword $PPQQSSTT
;               PP=pal_hi, QQ=pal_lo, SS=sprite_size, TT=tile_id
enemyAppearance macro main_frames,main_gfx,child_frames,child_gfx,dma_fn,vfx
    dc.l    main_frames
    dc.l    main_gfx
    dc.l    child_frames
    dc.l    child_gfx
    dc.l    dma_fn
    dc.l    vfx
    ENDM

; ============================================================
; enemyData Macro
; ============================================================
; Defines a single enemy stat/behaviour entry in battledata.asm.
; Each entry is exactly 26 bytes ($1A), read by InitializeEncounter.
;
; ai_fn:          AI/init function pointer (long)   — e.g. InitEnemy_Bouncing
; tile_id:        Sprite bank/palette index (word)  — VRAM tile table index
; reward_type:    Drop category (word)              — ENEMY_REWARD_NONE/$0000–$0003
; reward_value:   Drop value (word)                 — item ID, gold amount, etc.
; extra_obj_slots:Extra linked object slots (byte)  — 0 for single-sprite enemies
; max_spawn:      Max enemies per encounter (byte)  — capped at 7 by game code
; hp:             Hit points (word)
; damage_per_hit: Damage dealt per hit (word)
; xp_reward:      EXP awarded on kill (word)
; kim_reward:     Gold (kims) awarded on kill (word)
; speed:          Movement speed fixed-point (long)
; sprite_frame:   Initial sprite frame index (byte) — almost always $00
; behavior_flag:  AI behavior mode flag (byte)      — $02,$04,$06,$08,$0A,$0C,$0E
enemyData macro ai_fn,tile_id,reward_type,reward_value,extra_obj_slots,max_spawn,hp,damage_per_hit,xp_reward,kim_reward,speed,sprite_frame,behavior_flag
    dc.l    ai_fn
    dc.w    tile_id
    dc.w    reward_type
    dc.w    reward_value
    dc.b    extra_obj_slots
    dc.b    max_spawn
    dc.b    (hp)>>8, (hp)&$FF, (damage_per_hit)>>8, (damage_per_hit)&$FF
    dc.b    (xp_reward)>>8, (xp_reward)&$FF, (kim_reward)>>8, (kim_reward)&$FF
    dc.l    speed
    dc.b    sprite_frame
    dc.b    behavior_flag
    ENDM

; ============================================================
; townTileGfxEntry Macro
; ============================================================
; Defines one entry in TownTileGfxTable (towndata.asm).
; Each entry is exactly 10 bytes (dc.l + dc.l + dc.w).
; The table is indexed by town ID to determine which tileset
; mappings and graphics to load.
;
; mappings: Pointer to tileset mapping data (e.g. TownTileSet_A_Mappings)
; gfx:      Pointer to tile graphics data   (e.g. TownTileSet_A_Gfx)
; count:    Number of tiles to load (word)  — $0097 for set A, $0039 for set B
townTileGfxEntry macro mappings,gfx,count
    dc.l    mappings
    dc.l    gfx
    dc.w    count
    ENDM

; ============================================================
; talkerGfxDesc Macro
; ============================================================
; Defines a standard talker NPC graphics descriptor in towndata.asm.
; Each entry is exactly 22 bytes. Used for NPCs with a distinct
; walking sprite (MapGiver, StowGirl, Bearwulf, Merchant, ImposterGuard).
; The portrait frame table (TalkerPortraitTileDataPtrs) and sprite frame
; table (TalkerSpriteFrameTable), plus all fixed fields, are baked in.
;
; portrait_gfx: Pointer to portrait tile data
; sprite_gfx:   Pointer to body/sprite tile data
; dialogue_id:  NPC dialogue/script ID (word)
talkerGfxDesc macro portrait_gfx,sprite_gfx,dialogue_id
    dc.l    portrait_gfx
    dc.l    TalkerPortraitTileDataPtrs
    dc.w    $0007
    dc.l    sprite_gfx
    dc.l    TalkerSpriteFrameTable
    dc.w    $000F
    dc.w    $0000
    dc.w    $FFF0
    dc.b    $0D
    dc.b    $0F
    dc.w    dialogue_id
    ENDM

; ============================================================
; talkerGfxDescPortrait Macro
; ============================================================
; Defines a portrait-only talker NPC graphics descriptor.
; Used for NPCs whose sprite is portrait-style (no walking animation):
; GenericNpc, DigotGiver, TruffleGiver.
; Differs from talkerGfxDesc: sprite_frame_table = TalkerPortraitTileDataPtrs
; and sprite_param = $0D instead of $0F.
;
; portrait_gfx: Pointer to portrait tile data
; sprite_gfx:   Pointer to sprite tile data (portrait-style)
; dialogue_id:  NPC dialogue/script ID (word)
talkerGfxDescPortrait macro portrait_gfx,sprite_gfx,dialogue_id
    dc.l    portrait_gfx
    dc.l    TalkerPortraitTileDataPtrs
    dc.w    $0007
    dc.l    sprite_gfx
    dc.l    TalkerPortraitTileDataPtrs
    dc.w    $000F
    dc.w    $0000
    dc.w    $FFF0
    dc.b    $0D
    dc.b    $0D
    dc.w    dialogue_id
    ENDM

; ============================================================
; magicGfxData Macro
; ============================================================
; Defines one magic graphics data entry in towndata.asm.
; Each entry is exactly 12 bytes (dc.l + dc.l + dc.w + dc.w).
; Indexed by town to load the correct magic/spell tile graphics.
;
; layout_ptr:  Pointer to sprite/tile layout data
; frame_ptr:   Pointer to frame pointer table
; tile_count:  Number of tiles (word)
; palette_id:  Palette/VRAM slot identifier (word)
magicGfxData macro layout_ptr,frame_ptr,tile_count,palette_id
    dc.l    layout_ptr
    dc.l    frame_ptr
    dc.w    tile_count
    dc.w    palette_id
    ENDM

; ============================================================
; townShopBlock Macro
; ============================================================
; Defines one town's slot in ShopAssortmentByTownAndShopType
; or ShopPricesByTownAndType (4 × dc.l = 16 bytes per town).
; Slot order: item shop, equipment shop, magic buy, magic sell.
; The magic-sell slot is always ParmaMagicShop* for all towns.
;
; item:    Pointer to item shop assortment/prices
; equip:   Pointer to equipment shop assortment/prices
; magic:   Pointer to magic shop assortment/prices (buy)
; msell:   Pointer to magic sell assortment/prices (always ParmaMagicShop*)
townShopBlock macro item,equip,magic,msell
    dc.l    item
    dc.l    equip
    dc.l    magic
    dc.l    msell
    ENDM

; ============================================================
; shopItem Macro
; ============================================================
; One entry in an item shop assortment block.
; All item shop entries use ITEM_TYPE_DISCARDABLE ($00).
; 2 bytes: dc.b ITEM_TYPE_DISCARDABLE, <item_id>
;
; id: Item constant (e.g. ITEM_HERBS, ITEM_MEDICINE)
shopItem macro id
    dc.b    ITEM_TYPE_DISCARDABLE, id
    ENDM

; ============================================================
; shopEquip Macro
; ============================================================
; One entry in an equipment shop assortment block.
; 2 bytes: dc.b <type>, <equipment_id>
;
; type: Equipment type constant (EQUIPMENT_TYPE_SWORD/SHIELD/ARMOR)
; id:   Equipment constant (e.g. EQUIPMENT_SWORD_BRONZE)
shopEquip macro type,id
    dc.b    type, id
    ENDM

; ============================================================
; shopMagic Macro
; ============================================================
; One entry in a magic shop assortment block.
; 2 bytes: dc.b <type>, <magic_id>
;
; type: Magic type constant (MAGIC_TYPE_BATTLE or MAGIC_TYPE_FIELD)
; id:   Magic constant (e.g. MAGIC_FERROS, MAGIC_SANGUA)
shopMagic macro type,id
    dc.b    type, id
    ENDM

; ============================================================
; vdpCmd Macro
; ============================================================
; Generate a VDP control-port command longword at assemble time.
; Encodes a VRAM, CRAM, or VSRAM access address into the format
; expected by the VDP control port.
;
; Usage:
;   vdpCmd addr, type
;
;   addr: VRAM/CRAM/VSRAM address (0-based within the space)
;   type: One of the VDP_TYPE_* constants below
;
; VDP_TYPE constants:
;   VDP_TYPE_VRAM_WRITE  = $01   CD bits = 0001
;   VDP_TYPE_VRAM_READ   = $00   CD bits = 0000
;   VDP_TYPE_CRAM_WRITE  = $03   CD bits = 0011
;   VDP_TYPE_CRAM_READ   = $08   CD bits = 1000
;   VDP_TYPE_VSRAM_WRITE = $05   CD bits = 0101
;   VDP_TYPE_VSRAM_READ  = $04   CD bits = 0100
;   VDP_TYPE_VRAM_DMA    = $21   CD bits = 1 in high byte + 0001
;
; Formula:
;   bits 31-30:  CD1-CD0  = (type & 3)
;   bits 29-16:  A13-A0   = (addr & $3FFF)
;   bits  7-4:   CD5-CD2  = (type >> 2) << 4
;   bits  1-0:   A15-A14  = (addr >> 14) & 3
;
; Example: write to VRAM $C000 (Plane A base):
;   vdpCmd $C000, VDP_TYPE_VRAM_WRITE
;   → $40000003  (same as VDP_CMD_VRAM_WRITE_PLANE_A)
;
; Named constants for common addresses exist in constants.asm
; (VDP_CMD_VRAM_WRITE_PLANE_A, etc.).  Use this macro for
; addresses not covered by those constants, or for new code.
VDP_TYPE_VRAM_WRITE  = $01
VDP_TYPE_VRAM_READ   = $00
VDP_TYPE_CRAM_WRITE  = $03
VDP_TYPE_CRAM_READ   = $08
VDP_TYPE_VSRAM_WRITE = $05
VDP_TYPE_VSRAM_READ  = $04
VDP_TYPE_VRAM_DMA    = $21

vdpCmd macro addr,type
    dc.l    (((type)&3)<<30) | (((addr)&$3FFF)<<16) | ((((type)>>2)&$F)<<4) | (((addr)>>14)&3)
    ENDM


; One 16-byte entry in BattleSpriteDMACommands (battledata.asm).
; Consumed by ExecuteVdpDmaTransfer (battle_gfx.asm) which reads
; three longwords + one word as VDP control port writes, then
; stores the DMA destination command longword to Vdp_dma_cmd.
;
; The DMA source is always $FFA000 (the battle sprite RAM buffer):
;   reg $16 (source mid) = $D0, reg $15 (source lo) = $00,
;   reg $17 (source hi / mode) = $7F  =>  $7FD000 >> 1 = $FFA000 (pre-shifted).
;
; len_words : DMA transfer length in words (16-bit big-endian)
; vram_addr : VRAM destination address
;
; Byte layout (16 bytes):
;   $94, len_hi, $93, len_lo          VDP regs $14/$13 = DMA length
;   $96, $D0,   $95, $00              VDP regs $16/$15 = DMA source mid/lo
;   $97, $7F                          VDP reg  $17    = DMA source hi / mode
;   <4-byte DMA destination command>  encodes vram_addr for DMA write
;   $00, $00                          padding (never consumed)
dmaCmd macro len_words,vram_addr
    dc.b    $94, ((len_words)>>8)&$FF, $93, (len_words)&$FF
    dc.b    $96, $D0, $95, $00
    dc.b    $97, $7F
    dc.l    $40000080|((vram_addr&$3FFF)<<16)|((vram_addr>>14)&3)
    dc.w    $0000
    ENDM

; ============================================================
; VdpRowAdvance Macro
; ============================================================
; Advance a VDP nametable write-address register by one row.
; One nametable row = 64 tiles × 2 bytes = 128 bytes = $80,
; which in VDP command-word format is VDP_VRAM_ROW_STRIDE ($00800000).
;
; reg : data register holding the current VDP write-address command
;       (typically D3, D4, or D5)
;
; Usage:
;   VdpRowAdvance D5    ; move write address down by one row
;
; Expands to a single ADDI.l instruction — byte-identical to the
; explicit ADDI.l #VDP_VRAM_ROW_STRIDE, Dn form.
;
VdpRowAdvance macro reg
    ADDI.l  #VDP_VRAM_ROW_STRIDE, \reg
    ENDM

; ============================================================
; InterruptDisable / InterruptEnable Macros
; ============================================================
; Disable or re-enable the 68000 interrupt priority mask in the
; Status Register (SR).  This is the standard Genesis pattern for
; protecting VDP write sequences from VBlank interference.
;
; InterruptDisable  sets   interrupt mask bits to level 7 (all masked):
;   ORI  #$0700, SR    —    opcode $007C, immediate $0700
;
; InterruptEnable   clears interrupt mask bits to level 0 (all enabled):
;   ANDI #$F8FF, SR    —    opcode $027C, immediate $F8FF
;
; Both macros expand to a single instruction and are byte-identical
; to the inline ORI/ANDI forms used throughout the codebase.
;
; Usage:
;   InterruptDisable          ; mask all interrupts before VDP writes
;   ... VDP write sequence ...
;   InterruptEnable           ; restore interrupts when done
;
; CAUTION: InterruptDisable is a privileged instruction on the 68000
; (SR is supervisor-only).  This code always runs in supervisor mode
; (the Genesis boots into supervisor mode and never drops to user mode),
; so this is safe.  Do not use in code paths that could run in user mode.
InterruptDisable macro
    ORI     #$0700, SR
    ENDM

InterruptEnable macro
    ANDI    #$F8FF, SR
    ENDM

; ============================================================
; RomAddrMask Macro
; ============================================================
; Mask a 32-bit register to a 24-bit ROM address by clearing the
; high byte.  The Genesis 68000 has a 24-bit address bus; ROM
; pointers stored as longwords must be masked before use as
; effective addresses.
;
; The pattern ANDI.l #ROM_ADDRESS_MASK, Dn appears 9+ times across
; items.asm, npc.asm, and player.asm to strip the high byte from a
; Player_kims value or other 32-bit value before address arithmetic.
;
; reg: any data register (D0–D7)
;
; Usage:
;   MOVE.l  Player_kims.w, D1
;   RomAddrMask D1          ; clear high byte, keep 24-bit value
;
; Expands to:
;   ANDI.l  #ROM_ADDRESS_MASK, D1
; which is byte-identical to the explicit ANDI.l #$00FFFFFF, D1 form.
;
RomAddrMask macro reg
    ANDI.l  #ROM_ADDRESS_MASK, \reg
    ENDM
