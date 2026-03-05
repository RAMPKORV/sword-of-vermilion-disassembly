; ======================================================================
; src/script.asm
; Script/text engine, HUD, windows, text rendering, dialogue
;
; Responsibilities:
;   - Dialogue script execution (text rendering, script opcodes)
;   - Window/HUD drawing and buffering
;   - Menu drawing (shops, items, equipment, magic, save files)
;   - Number formatting (BCD conversion, decimal string output)
;   - Transaction arithmetic (kims, experience, BCD add/subtract)
;   - Palette management (fade-in/fade-out, palette table loads)
;   - Name entry screen
;   - Prologue / Sega logo cutscene sequencer
; ======================================================================
;
; ======================================================================
; VM-001: SCRIPT OPCODE REFERENCE TABLE
; ======================================================================
; The script VM is driven by ProcessScriptText, which reads one byte
; per tick from the current script string (Script_source_base +
; Script_source_offset) and dispatches on control codes.
;
; Tile base: $04C0 added to every display byte before writing to VRAM.
; Palette:   bit 15 set ($8000 OR'd) → palette line 0.
;
; Opcode  Const              Size    Operands / Action
; ------  -----------------  ------  -------------------------------------------
; $FF     SCRIPT_END         1       End of dialogue. Mark text complete.
; $FE     SCRIPT_NEWLINE     1       Advance Y cursor 2 rows; reset X to 0.
; $FD     SCRIPT_CONTINUE    1       Draw continuation arrow at (20,27); wait for
;                                    player input (sets Script_has_continuation).
; $FC     SCRIPT_QUESTION    2       [opcode, response_idx]
;                                    Store response_idx → Dialog_response_index.
;                                    Set Script_has_yes_no_question = FLAG_TRUE.
;                                    (No text rendered; dialogue pauses for reply.)
; $FB     SCRIPT_YES_NO      4       [opcode, response_idx, trigger_offset, ext_trigger]
;                                    response_idx  → Dialog_response_index
;                                    trigger_offset→ Dialog_choice_event_trigger
;                                    ext_trigger   → Dialog_choice_extended_trigger
;                                    Set Dialogue_event_trigger_flag, Script_has_yes_no_question.
; $FA     SCRIPT_CHOICE      3       [opcode, expected_answer, map_trigger]
;                                    expected_answer → Quest_choice_expected_answer
;                                    map_trigger     → Quest_choice_map_trigger
;                                    Set Quest_choice_pending = FLAG_TRUE.
;                                    Store response_idx from byte[1].
; $F9     SCRIPT_ACTIONS     2+N*M   [opcode, count, entry0, entry1, ...]
;                                    Execute 'count' actions. Each entry:
;                                      [$00, offset.b]    Set Event_triggers_start[offset]=FF
;                                      [$01, sector.b]    Reveal world-map sector (offset+$100)
;                                      [$02, bcd0..3]     Add BCD kim reward via AddPaymentAmount
;                                      (entry 0 = 2 bytes; entries $02 = 6 bytes)
;                                    Plays SOUND_ATTACK after all actions.
; $F8     SCRIPT_TRIGGERS    2+N     [opcode, count, offset0, offset1, ...]
;                                    For each of 'count' offset bytes:
;                                      Set Event_triggers_start[offset] = $FF
;                                    Max 2 offsets in macro form; raw data may have more.
; $F7     SCRIPT_PLAYER_NAME 1       Switch source to Player_name buffer; resume
;                                    character-by-character output from there.
; $DF     SCRIPT_WIDE_CHAR_HI 1      Wide glyph high byte — render at (x-1, y-1).
; $DE     SCRIPT_WIDE_CHAR_LO 1      Wide glyph low byte — render at (x-1, y-1).
; $00–$DD Display char       1       Tile index = byte + $04C0; write to Plane B tilemap
; $E0–$F6 Display char       1       Tile index = byte + $04C0 (gap between wide and control)
;
; Rendering cursor state:
;   Script_output_x       (word)  current column offset (tiles)
;   Script_output_y       (word)  current row offset (tiles)
;   Script_output_base_x  (word)  window left margin (tiles)
;   Script_tile_attrs     (word)  extra VDP tile attributes to OR into each glyph
;
; Script pointer state:
;   Script_source_base    (long)  pointer to start of current script string
;   Script_source_offset  (word)  byte offset from base to current read position
;
; See tools/index/script_opcodes.json for machine-readable version.
; ======================================================================
;
; ======================================================================
; VM-002: SCRIPT ENGINE RUNTIME RAM STATE
; ======================================================================
; All variables are in 68000 RAM ($FFFF0000–$FFFFFFFF).
; Grouped by role; see constants.asm for addresses.
;
; --- Script Pointer / Program Counter ---
;   Script_source_base    (.l $FFFFC204)  Pointer to start of active script string.
;                                         Loaded from NPC dialogue table before each
;                                         conversation; changed by $F7 to Player_name.
;   Script_source_offset  (.w $FFFFC202)  Byte offset from Script_source_base to the
;                                         next byte to be consumed by ProcessScriptText.
;                                         Incremented after each byte is consumed.
;   Script_talk_source    (.l $FFFFC250)  Saved base pointer for the original NPC
;                                         script, preserved when $F7 temporarily
;                                         redirects the source to Player_name.
;   Script_continuation_ptr (.l $FFFFC254) Pointer to the continuation segment used
;                                         after a $FD (CONTINUE) page-break.
;
; --- Render Cursor ---
;   Script_output_x       (.w $FFFFC234)  Current column position (tile units) within
;                                         the dialogue window.
;   Script_output_y       (.w $FFFFC232)  Current row position (tile units).
;   Script_output_base_x  (.w $FFFFC230)  Left margin of the dialogue window (tiles).
;                                         Added to Script_output_x for absolute tile col.
;   Script_tile_attrs     (.w $FFFFC208)  Extra VDP tile attribute bits OR'd into every
;                                         written glyph (palette line, flip bits, etc.).
;
; --- Rate Control ---
;   Script_render_tick    (.w $FFFFC20C)  Frame counter incremented each tick by
;                                         ProcessScriptText; used with Message_speed to
;                                         gate one character per N frames.
;   Message_speed         (.b $FFFFC210)  Bit index (0–7) that controls character rate.
;                                         0 = fastest; higher = slower.
;                                         Saved/loaded per save slot.
;
; --- Status Flags ---
;   Script_text_complete      (.b $FFFFC20F)  Set to FLAG_TRUE ($FF) by SCRIPT_END ($FF).
;                                              Caller checks this to know dialogue ended.
;   Script_has_continuation   (.b $FFFFC211)  Set to FLAG_TRUE by SCRIPT_CONTINUE ($FD).
;                                              Caller draws the "more" arrow and waits.
;   Script_has_yes_no_question(.b $FFFFC212)  Set by SCRIPT_QUESTION ($FC) / YES_NO ($FB).
;                                              Caller shows Yes/No menu.
;   Script_reading_player_name(.b $FFFFC213)  Non-zero while $F7 has redirected the
;                                              source to the Player_name buffer.
;
; --- Player Name Insertion ---
;   Player_name_index     (.w $FFFFC214)  Byte offset into Player_name being output.
;                                         Cleared when $F7 is encountered; incremented
;                                         each character; source reverts when '\0' hit.
;   Player_name           (.l $FFFFC64C)  Player's name string (null-terminated, up to
;                                         8 chars).  Read-only from the script engine.
;
; --- Dialogue / Quest Response ---
;   Dialog_response_index     (.b $FFFFC240)  Response slot index stored by $FC/$FB for
;                                              the NPC dialogue handler to check.
;   Dialog_choice_event_trigger (.w $FFFFC700) Event-trigger offset stored by $FB ($FA).
;   Dialog_choice_extended_trigger (.b $FFFFC701) Secondary trigger offset (YES_NO $FB).
;   Quest_choice_pending      (.b $FFFFC703)  Set by SCRIPT_CHOICE ($FA); caller shows
;                                              the choice prompt.
;   Quest_choice_expected_answer (.b $FFFFC704) Expected player answer for $FA choices.
;   Quest_choice_map_trigger  (.b $FFFFC705)  Map-state trigger set on correct $FA reply.
;
; --- Window / Tilemap System ---
;   Window_tilemap_draw_pending  (.b $FFFF9900)  Non-zero while the window tilemap DMA
;                                                 is pending; ProcessScriptText blocks
;                                                 until this clears.
;   Window_tilemap_draw_active   (.b $FFFF9910)  Set while a window draw is in progress.
;   Window_tilemap_row_draw_pending (.b $FFFF9911) Per-row draw flag for incremental
;                                                   window rendering.
;   Window_tilemap_draw_x/y      (.w $FFFFC220/222) Top-left tile coords for next draw.
;   Window_tilemap_draw_width/height (.w $FFFFC228/22A) Dimensions of window in tiles.
;   Window_tile_x/y/width/height (.w $FFFFC224/226/22C/22E) Alternate tile-region dims
;                                                            used during row rendering.
;   Window_tilemap_buffer        ($FFFF9920)  64-byte scratch buffer for a single row of
;                                             tile data assembled before DMA transfer.
;
; --- Dialogue Phase (used by gameplay.asm / npc.asm callers) ---
;   Dialog_selection      (.w $FFFFC428)  Currently highlighted menu item index.
;   Dialog_phase          (.w $FFFFC552)  State step within the current dialogue phase
;                                          (0 = waiting to open, higher = sequenced).
;   Dialog_timer          (.w $FFFFC554)  Frame timer used by dialogue phase sequencer.
;   Dialog_active_flag    (.b $FFFFC561)  Non-zero while a dialogue window is open.
;   Dialog_state_flag     (.b $FFFFC56A)  Secondary flag set when dialogue is in
;                                          a "settled" (awaiting input) state.
;
; --- Cursor Blink ---
;   Cursor_blink_timer    (.w $FFFFC200)  Frame counter for blinking the dialogue
;                                         cursor / continuation arrow.
; ======================================================================
;
; ======================================================================
; VM-003: TEXT ENCODING
; ======================================================================
; Sword of Vermilion uses an ASCII-compatible custom character encoding.
;
; --- Byte-to-Glyph Formula ---
;   VRAM tile index = script_byte + FONT_TILE_BASE  ($04C0)
;   Example: 'A' ($41) → tile $0501 in VRAM font block
;
; --- Display Byte Ranges ---
;   $20–$7E   Standard printable ASCII (space, digits, A-Z, a-z, punct.)
;   $7F–$DD   Extended/special characters and symbols (punctuation,
;             accented letters, box-drawing, etc.)
;   $E0–$F6   Additional display characters (gap between wide chars
;             and control codes $F7–$FF)
;   NOTE: bytes $00–$1F are not used as display characters in practice.
;
; --- Control / Non-Display Bytes ---
;   $F7   SCRIPT_PLAYER_NAME  — redirect output to Player_name buffer
;   $F8   SCRIPT_TRIGGERS     — set event trigger flags
;   $F9   SCRIPT_ACTIONS      — execute give-item/kims/trigger actions
;   $FA   SCRIPT_CHOICE       — quest choice with expected answer
;   $FB   SCRIPT_YES_NO       — yes/no prompt with event trigger
;   $FC   SCRIPT_QUESTION     — show response choices
;   $FD   SCRIPT_CONTINUE     — page break: wait for button then continue
;   $FE   SCRIPT_NEWLINE      — advance 2 rows, reset X to left margin
;   $FF   SCRIPT_END          — end of string; $00 padding follows
;   $DE   SCRIPT_WIDE_CHAR_LO — wide glyph low surrogate
;   $DF   SCRIPT_WIDE_CHAR_HI — wide glyph high surrogate
;
; --- Wide Characters ($DE / $DF) ---
;   Wide glyphs occupy two tile columns. The $DF byte is the top/left
;   tile; the $DE byte is the bottom/right tile.
;   Both are rendered as: tile = byte + $04C0, with palette bit $8000
;   forced set. The glyph is written one tile left and one tile above
;   the normal cursor position (see ScriptRender_PortraitTile).
;
; --- Font Tile Data ---
;   Source binary: data/art/tiles/font/font_tiles.bin
;   Loaded at startup as CompressedFontTileData (RLE-compressed).
;   Tiles are 8×8 pixels, 4bpp planar, Mega Drive native format.
;   The continuation/page-break arrow glyph is at tile $04DF
;   ($DF display byte → written directly as #$04DF in the renderer).
;
; --- String Termination ---
;   Every string ends with SCRIPT_END ($FF).
;   A $00 padding byte frequently follows to maintain word alignment.
;   The assembler-emitted dc.b "..." form maps standard ASCII directly.
; ======================================================================

;==============================================================
; SCRIPT / DIALOGUE ENGINE
;==============================================================

; ---------------------------------------------------------------------------
; ProcessScriptText — advance script by one character per rate-gated tick
;
; Reads the next byte from the active script string (Script_source_base +
; Script_source_offset), substitutes Player_name when the SCRIPT_PLAYER_NAME
; code is encountered, and dispatches on control codes $F7–$FF.  Printable
; bytes are converted to tile indices and written directly to VDP VRAM
; (Plane B window layer).
;
; Called once per game tick from the dialogue state machine.
;
; Input:   (all state via RAM)
;   Script_source_base.w   — pointer to current script string
;   Script_source_offset.w — byte index within that string
;   Message_speed.w        — speed setting (bit number for rate gate)
;   Script_render_tick.w   — incremented each call; used for rate limiting
;
; Scratch:  D0-D3, A0
; Output:   VDP nametable updated; Script_source_offset.w advanced
; ---------------------------------------------------------------------------
ProcessScriptText:
	TST.b	Window_tilemap_draw_pending.w
	BNE.w	ScriptDecode_Return             ; wait until window has finished drawing
	ADDQ.w	#1, Script_render_tick.w
	MOVE.w	Script_render_tick.w, D0
	MOVE.b	Message_speed.w, D2             ; D2 = speed setting (bit number for rate gate)
	MOVE.w	D0, D1
	SUBQ.w	#1, D1
	EOR.w	D1, D0                          ; isolate lowest changed bit
	BTST.l	D2, D0                          ; is this the speed-rate bit?
	BEQ.w	ScriptDecode_Return
	BTST.l	D2, D1
	BEQ.w	ScriptDecode_Return             ; throttle: only advance on rising edge of bit D2
	PlaySound_b	SOUND_TEXT_BLIP                ; play text blip sound each displayed character
	TST.b	Script_reading_player_name.w
	BNE.b	ProcessScriptText_Loop          ; currently mid-player-name: skip source fetch
	MOVE.w	Script_source_offset.w, D2
	MOVEA.l	Script_source_base.w, A0       ; A0 = base address of current script string
	CLR.w	D3
	MOVE.b	(A0,D2.w), D3               ; D3 = next byte from script
	CMPI.b	#SCRIPT_PLAYER_NAME, D3
	BNE.b	ProcessScriptText_Loop2
ProcessScriptText_Loop:                     ; begin reading from Player_name buffer
	LEA	Player_name.w, A0
	MOVE.w	Player_name_index.w, D2
	CLR.w	D3
	MOVE.b	(A0,D2.w), D3               ; D3 = current character from player name
	MOVE.b	#FLAG_TRUE, Script_reading_player_name.w
ProcessScriptText_Loop2: ; Dispatch on script control codes
	CMPI.b	#SCRIPT_END, D3
	BEQ.w	ScriptDecode_Done
	CMPI.b	#SCRIPT_NEWLINE, D3
	BEQ.w	ScriptCmd_Newline                       ; advance to next row
	CMPI.b	#SCRIPT_CONTINUE, D3
	BEQ.w	ScriptCmd_Continue                      ; show continue arrow, wait
	CMPI.b	#SCRIPT_QUESTION, D3
	BEQ.w	ScriptDecode_SetResponse                ; set dialogue response index
	CMPI.b	#SCRIPT_YES_NO, D3
	BEQ.w	ScriptCmd_YesNo                         ; yes/no prompt
	CMPI.b	#SCRIPT_CHOICE, D3
	BEQ.w	ScriptCmd_Choice                        ; quest choice with expected answer
	CMPI.b	#SCRIPT_ACTIONS, D3
	BEQ.w	ScriptCmd_Actions                       ; execute give-item/kims/trigger actions
	CMPI.b	#SCRIPT_TRIGGERS, D3
	BEQ.w	ScriptCmd_Triggers                      ; set event triggers (simple format)
	CMPI.b	#SCRIPT_WIDE_CHAR_LO, D3
	BEQ.w	ScriptRender_PortraitTile               ; wide char low byte (2-column glyph)
	CMPI.b	#SCRIPT_WIDE_CHAR_HI, D3
	BEQ.w	ScriptRender_PortraitTile               ; wide char high byte
	ADDI.w	#$04C0, D3                      ; add tile base offset ($4C0 = font tiles base)
	ORI.w	#$8000, D3                      ; set palette bit (use palette line 0)
	OR.w	Script_tile_attrs.w, D3         ; merge any additional attributes (flip, priority)
	JSR	GetScrollOffsetInTiles
	ADD.w	Script_output_x.w, D0          ; D0 = output X in tilemap
	ADD.w	Script_output_base_x.w, D0
	ADD.w	Script_output_y.w, D1          ; D1 = output Y in tilemap
	ANDI.w	#$003F, D0                      ; wrap to 64-tile-wide tilemap
	ANDI.w	#$003F, D1
	ASL.w	#1, D0                          ; x * 2 (each entry is 2 bytes)
	ASL.w	#7, D1                          ; y * 128 (64 tiles * 2 bytes per row)
	ADD.w	D1, D0
	ANDI.l	#$00001FFF, D0                  ; mask to tilemap size
	SWAP	D0
	ORI.l	#$40000003, D0                  ; VDP write-to-VRAM command, Plane B
	ORI	#$0700, SR                      ; disable interrupts
	MOVE.l	D0, VDP_control_port
	MOVE.w	D3, VDP_data_port               ; write tile word to VRAM
	ANDI	#$F8FF, SR                      ; re-enable interrupts
	ADDQ.w	#1, Script_output_x.w          ; advance horizontal cursor
	BRA.w	ScriptDecode_AdvanceOffset
; ScriptRender_PortraitTile
; Render a wide character (2-column glyph) one tile to the left/above of normal position.
; Wide chars occupy the tile at (x-1, y-1) relative to the normal cursor.
ScriptRender_PortraitTile:
	ADDI.w	#$04C0, D3	
	ORI.w	#$8000, D3	
	OR.w	Script_tile_attrs.w, D3	
	JSR	GetScrollOffsetInTiles	
	ADD.w	Script_output_x.w, D0	
	ADD.w	Script_output_base_x.w, D0	
	ADD.w	Script_output_y.w, D1	
	SUBQ.w	#1, D0	
	SUBQ.w	#1, D1	
	ANDI.w	#$003F, D0	
	ANDI.w	#$003F, D1	
	ADD.w	D0, D0	
	ASL.w	#7, D1	
	ADD.w	D1, D0	
	ANDI.l	#$00001FFF, D0	
	SWAP	D0	
	ORI.l	#$40000003, D0	
	MOVE.l	D0, VDP_control_port	
	MOVE.w	D3, VDP_data_port	
	BRA.w	ScriptDecode_AdvanceOffset	
ScriptCmd_Newline:
	ADDQ.w	#2, Script_output_y.w          ; skip down 2 rows (double-height text lines)
	CLR.w	Script_output_x.w              ; reset to start of line
	BRA.w	ScriptDecode_AdvanceOffset
ScriptCmd_Continue:
	MOVE.b	#FLAG_TRUE, Script_has_continuation.w  ; mark: player must press button to continue
	JSR	GetScrollOffsetInTiles
	ADDI.w	#$0014, D0                      ; X offset = column 20 (right edge of dialog box)
	ADDI.w	#$001B, D1                      ; Y offset = row 27 (bottom of dialog box)
	SUBQ.w	#1, D0
	SUBQ.w	#1, D1
	ANDI.w	#$003F, D0
	ANDI.w	#$003F, D1
	ASL.w	#1, D0
	ASL.w	#7, D1
	ADD.w	D1, D0
	ANDI.l	#$00001FFF, D0
	SWAP	D0
	ORI.l	#$40000003, D0
	MOVE.l	D0, VDP_control_port
	MOVE.w	#$04DF, D3                      ; tile $04DF = continuation arrow glyph
	ORI.w	#$8000, D3
	OR.w	Script_tile_attrs.w, D3
	MOVE.w	D3, VDP_data_port
	BRA.w	ScriptDecode_Done
ScriptCmd_Choice:
	MOVE.b	$2(A0,D2.w), Quest_choice_expected_answer.w	
	MOVE.b	$3(A0,D2.w), Quest_choice_map_trigger.w	
	MOVE.b	#FLAG_TRUE, Quest_choice_pending.w	
	BRA.w	ScriptDecode_SetResponse	
ScriptCmd_Actions:
	CLR.l	D4
	CLR.l	D5
	LEA	Event_triggers_start.w, A2
	MOVE.b	$1(A0,D2.w), D4 ; Read the next character after $F9 into D4
	ADDA.w	D2, A0
	LEA	$2(A0), A4
	SUBQ.b	#1, D4
ScriptCmd_Actions_Loop:
	MOVE.b	(A4)+, D5 ; Read next to D5
	CMPI.b	#2, D5
	BEQ.b	ScriptCmd_Actions_GiveItem
	LSL.w	#8, D5
	MOVE.b	(A4)+, D5
	MOVE.b	#$FF, (A2,D5.w)
	BRA.b	ScriptCmd_Actions_Next
ScriptCmd_Actions_GiveItem:
	MOVE.b	(A4)+, Transaction_amount.w
	MOVE.b	(A4)+, Transaction_item_id.w
	MOVE.b	(A4)+, Transaction_item_quantity.w
	MOVE.b	(A4)+, Transaction_item_flags.w
	BSR.w	AddPaymentAmount
ScriptCmd_Actions_Next:
	DBF	D4, ScriptCmd_Actions_Loop
	PlaySound	SOUND_ATTACK
	BRA.w	ScriptDecode_Done
ScriptCmd_Triggers:
	CLR.l	D4
	CLR.l	D5
	LEA	Event_triggers_start.w, A2
	MOVE.b	$1(A0,D2.w), D4
	ADDA.w	D2, A0
	LEA	$2(A0), A4
	SUBQ.b	#1, D4
ScriptCmd_Triggers_Loop:
	MOVE.b	(A4)+, D5
	MOVE.b	#$FF, (A2,D5.w)
	DBF	D4, ScriptCmd_Triggers_Loop
	BRA.w	ScriptDecode_Done
ScriptCmd_YesNo:
	MOVE.b	$2(A0,D2.w), Dialog_choice_event_trigger.w
	MOVE.b	$3(A0,D2.w), Dialog_choice_extended_trigger.w
	MOVE.b	#FLAG_TRUE, Dialogue_event_trigger_flag.w
ScriptDecode_SetResponse:
	MOVE.b	$1(A0,D2.w), Dialog_response_index.w
	MOVE.b	#FLAG_TRUE, Script_has_yes_no_question.w
ScriptDecode_Done:
	TST.b	Script_reading_player_name.w
	BEQ.b	ScriptDecode_Done_Loop
	CLR.b	Script_reading_player_name.w
	CLR.w	Player_name_index.w
	ADDQ.w	#1, Script_source_offset.w
	BRA.b	ScriptDecode_Return
ScriptDecode_Done_Loop:
	MOVE.b	#FLAG_TRUE, Script_text_complete.w
ScriptDecode_AdvanceOffset:
	TST.b	Script_reading_player_name.w
	BNE.b	ScriptDecode_Return_Loop
	ADDQ.w	#1, Script_source_offset.w
ScriptDecode_Return:
	RTS
	
ScriptDecode_Return_Loop:
	ADDQ.w	#1, Player_name_index.w
	RTS
	
;==============================================================
; MENU / WINDOW DRAWING
;==============================================================

; DrawStartContinueMenu
; Draw the title screen Start/Continue selection menu.
DrawStartContinueMenu:
	CLR.w	Dialog_selection.w
	MOVE.w	#1, Menu_cursor_column_break.w
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w
	MOVE.w	#$000F, Menu_cursor_base_x.w
	MOVE.w	#$0015, Menu_cursor_base_y.w
	SetupWindow $000E, $0013, $000B, 6
	LEA	MenuStartContinueStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; ---------------------------------------------------------------------------
; ResetScriptAndInitDialogue — clear script offset then initialise window
;
; Resets Script_source_offset to 0, then falls through to InitDialogueWindow.
; Use this when starting a new dialogue from the beginning of a script string.
; Use InitDialogueWindow directly when the offset should be preserved.
;
; Input:   none
; Scratch:  (same as InitDialogueWindow)
; Output:   Script_source_offset.w = 0; dialogue window initialised
; ---------------------------------------------------------------------------
ResetScriptAndInitDialogue:
	CLR.w	Script_source_offset.w
; InitDialogueWindow
; Initialize the dialogue window without resetting script offset.
InitDialogueWindow:
	CLR.b	Script_text_complete.w
	CLR.b	Script_has_continuation.w
	CLR.b	Script_has_yes_no_question.w
	MOVE.w	#5, Script_output_base_x.w
	MOVE.w	#$0015, Script_output_y.w
	MOVE.w	#0, Script_tile_attrs.w
	CLR.w	Script_output_x.w
	SetupWindow 4, $0013, $001F, 8
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_pending.w
	RTS
	
; DrawOptionsMenu
; Draw the main options menu window.
DrawOptionsMenu:
	SetupWindow 2, 2, $000D, $000A
	LEA	MenuOptionsStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; DrawMessageSpeedMenu
; Draw the message speed selection menu.
DrawMessageSpeedMenu:
	SetupWindow $000A, $000A, $000E, $000A	
	LEA	MessageSpeedStr, A0	
	MOVE.w	#1, Window_text_x.w	
	MOVE.w	#2, Window_text_y.w	
	BSR.w	RenderTextToWindow	
	LEA	Window_tilemap_buffer.w, A1	
	CLR.w	D1	
	MOVE.b	Message_speed.w, D1	
	ADD.w	D1, D1	
	ADDQ.w	#4, D1	
	MOVE.w	#$000F, D0	
	MULU.w	D0, D1	
	ADDI.w	#$000C, D1	
	MOVE.b	#$2A, (A1,D1.w)	
	CLR.w	Window_draw_row.w	
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w	
	RTS
	
; DrawYesNoDialog
; Draw the Yes/No confirmation dialog window.
DrawYesNoDialog:
	CLR.w	Dialog_selection.w
	MOVE.w	#1, Menu_cursor_column_break.w
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w
	MOVE.w	#$001E, Menu_cursor_base_x.w
	MOVE.w	#$000F, Menu_cursor_base_y.w
	SetupWindow $001C, $000D, 6, 6
	LEA	YesNoStr, A0
	MOVE.w	#3, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_pending.w
	RTS
	
; DrawSavedGameOptionsMenu
; Draw the saved game options menu (load from slot 1/2/3).
DrawSavedGameOptionsMenu:
	CLR.w	Dialog_selection.w
	MOVE.w	#2, Menu_cursor_column_break.w
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w
	MOVE.w	#$0010, Menu_cursor_base_x.w
	MOVE.w	#$000E, Menu_cursor_base_y.w
	SetupWindow $000F, $000C, $0015, 7
	LEA	SavedGameOptionsStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	LEA	$00200001, A0
	BSR.w	LoadSavegameNameToBuffer
	LEA	Savegame_name_buffer.w, A0
	MOVE.w	#$003B, D0
	BSR.w	RenderTextAtOffset
	LEA	$00200A81, A0
	BSR.w	LoadSavegameNameToBuffer
	LEA	Savegame_name_buffer.w, A0
	MOVE.w	#$0067, D0
	BSR.w	RenderTextAtOffset
	LEA	$00201501, A0
	BSR.w	LoadSavegameNameToBuffer
	LEA	Savegame_name_buffer.w, A0
	MOVE.w	#$0093, D0
	BSR.w	RenderTextAtOffset
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_pending.w
	RTS
	
; DrawSpellActionMenu
; Draw the spell action menu (Cast/Ready/Discard).
DrawSpellActionMenu:
	MOVE.w	#2, Menu_cursor_column_break.w
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w
	MOVE.w	#3, Menu_cursor_base_x.w
	MOVE.w	#$000E, Menu_cursor_base_y.w
	SetupWindow 2, $000C, $000D, 8
	LEA	CastReadyDiscardStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; DrawUseDiscardMenuWindow
; Draw the item Use/Discard action menu window.
DrawUseDiscardMenuWindow:
	MOVE.w	#1, Menu_cursor_column_break.w
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w
	MOVE.w	#3, Menu_cursor_base_x.w
	MOVE.w	#$000E, Menu_cursor_base_y.w
	SetupWindow 2, $000C, $000D, 6
	LEA	UseDiscardStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; DrawEquipmentMenuWindow
; Draw the equipment action menu (Put On/Remove/Stop).
DrawEquipmentMenuWindow:
	MOVE.w	#2, Menu_cursor_column_break.w
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w
	MOVE.w	#3, Menu_cursor_base_x.w
	MOVE.w	#$000E, Menu_cursor_base_y.w
	SetupWindow 2, $000C, $000B, 8
	LEA	PutOnRemoveStopStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; DrawEquipOptionsMenuWindow
; Draw the equipment options submenu.
DrawEquipOptionsMenuWindow:
	MOVE.w	#2, Menu_cursor_column_break.w
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w
	MOVE.w	#$000D, Menu_cursor_base_x.w
	MOVE.w	#6, Menu_cursor_base_y.w
	SetupWindow $000C, 4, 9, 8
	LEA	EquipOptionsStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; DrawChurchMenuWindow
; Draw the church services menu window.
DrawChurchMenuWindow:
	MOVE.w	#3, Menu_cursor_column_break.w
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w
	MOVE.w	#3, Menu_cursor_base_x.w
	MOVE.w	#$000C, Menu_cursor_base_y.w
	SetupWindow 2, $000A, $0015, $000A
	LEA	ChurchOptionsStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; DrawShopMenuWindow
; Draw the shop action menu (Buy/Sell/Leave).
DrawShopMenuWindow:
	MOVE.w	#2, Menu_cursor_column_break.w
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w
	MOVE.w	#3, Menu_cursor_base_x.w
	MOVE.w	#$000E, Menu_cursor_base_y.w
	SetupWindow 2, $000C, 7, 8
	LEA	BuySellStopStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; DrawMoneyDisplayWindow
; Draw the player's current kims (gold) display window.
DrawMoneyDisplayWindow:
	SetupWindow 0, 2, 9, 6
	LEA	KimStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	MOVE.l	Player_kims.w, D2
	BSR.w	FormatLongNumberToText
	MOVE.w	#$002A, D0
	BSR.w	RenderTextToWindowAtPosition
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_pending.w
	RTS
	
; DrawItemListBorders
; Draw UI border tiles for the item list window.
DrawItemListBorders:
	MOVE.w	Possessed_items_length.w, D7
	BSR.w	DrawListTopBorders
	MOVE.w	Possessed_items_length.w, D0
	BSR.w	DrawListBottomBorder
	RTS
	
; DrawMagicListBorders
; Draw UI border tiles for the magic list window.
DrawMagicListBorders:
	MOVE.w	Possessed_magics_length.w, D7
	BSR.w	DrawListTopBorders
	MOVE.w	Possessed_magics_length.w, D0
	BSR.w	DrawListBottomBorder
	RTS
	
; DrawEquipmentListWindow
; Draw UI border tiles for the equipment list window.
DrawEquipmentListWindow:
	MOVE.w	Possessed_equipment_length.w, D7
	BSR.w	DrawListTopBorders
	MOVE.w	Possessed_equipment_length.w, D0
	BSR.w	DrawListBottomBorder
	RTS
	
; DrawReadyEquipmentMenuBorders
; Draw UI border tiles for the ready equipment menu.
DrawReadyEquipmentMenuBorders:
	MOVE.w	Ready_equipment_list_length.w, D7
	BSR.w	DrawListTopBorders
	MOVE.w	Ready_equipment_list_length.w, D0
	BSR.w	DrawListBottomBorder
	RTS
	
; DrawListTopBorders
; Draw the top and middle row borders for a scrollable list window.
; Input: D7 = list item count
DrawListTopBorders:
	LEA	UIBorder_SmallTop, A0
	MOVE.w	#$000F, Window_tilemap_draw_x.w
	MOVE.w	#2, Window_tilemap_draw_y.w
	MOVE.w	#$0015, Window_tilemap_draw_width.w
	MOVE.w	#0, Window_tilemap_draw_height.w
	MOVE.w	#0, Script_tile_attrs.w
	BSR.w	RenderTextToTilemap
	ADD.w	D7, D7
	ADDQ.w	#1, D7
	MOVEQ	#1, D6
DrawListTopBorders_Done:
	LEA	UIBorder_SmallMiddle, A0
	MOVE.w	#$000F, Window_tilemap_draw_x.w
	MOVE.w	#2, D0
	ADD.w	D6, D0
	MOVE.w	D0, Window_tilemap_draw_y.w
	MOVE.w	#$0015, Window_tilemap_draw_width.w
	MOVE.w	#0, Window_tilemap_draw_height.w
	MOVE.w	#0, Script_tile_attrs.w
	BSR.w	RenderTextToTilemap
	ADDQ.w	#1, D6
	DBF	D7, DrawListTopBorders_Done
	RTS
	
; DrawListBottomBorder
; Draw the bottom border row for a scrollable list window.
; Input: D0 = list item count
DrawListBottomBorder:
	LEA	UIBorder_LargeBox, A0
	ADDQ.w	#1, D0
	ADD.w	D0, D0
	MOVE.w	#$000F, Window_tilemap_draw_x.w
	MOVE.w	#2, D1
	ADD.w	D0, D1
	MOVE.w	D1, Window_tilemap_draw_y.w
	MOVE.w	#$0015, Window_tilemap_draw_width.w
	MOVE.w	#0, Window_tilemap_draw_height.w
	MOVE.w	#0, Script_tile_attrs.w
	BSR.w	RenderTextToTilemap
	RTS
	
; DrawShopItemListWindow
; Draw the shop buy list window with item names and prices.
DrawShopItemListWindow:
	MOVE.w	Shop_item_count.w, D0
	SUBQ.w	#1, D0
	MOVE.w	D0, Menu_cursor_column_break.w
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w
	MOVE.w	#$000B, Menu_cursor_base_x.w
	MOVE.w	#4, Menu_cursor_base_y.w
	MOVE.w	#$000A, Window_tilemap_x.w
	MOVE.w	#2, Window_tilemap_y.w
	MOVE.w	#$0018, Window_width.w
	MOVE.w	Shop_item_count.w, D0
	ADD.w	D0, D0
	ADDQ.w	#2, D0
	DrawWindowDynH
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	LEA	Shop_item_list.w, A3
	LEA	ShopCategoryNameTables, A4
	MOVE.w	Current_shop_type.w, D0
	ASL.w	#3, D0
	MOVEA.l	(A4,D0.w), A4
	MOVE.w	Shop_item_count.w, D7
	SUBQ.w	#1, D7
DrawShopItemListWindow_Done:
	MOVE.w	(A3)+, D4
	ANDI.w	#$00FF, D4
	ADD.w	D4, D4
	ADD.w	D4, D4
	MOVEA.l	(A4,D4.w), A0
	BSR.w	RenderTextToWindow
	ADDQ.w	#2, Window_text_y.w
	DBF	D7, DrawShopItemListWindow_Done
	MOVE.w	#$0012, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	LEA	ShopPricesByTownAndType, A3
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	ADD.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A3,D0.w), A3
	CLR.w	Shop_item_index.w
	MOVE.w	#0, D3
DrawShopItemListWindow_Done2:
	MOVE.l	(A3)+, D2
	BSR.w	FormatLongNumberToText
	BSR.w	RenderFormattedTextToWindow
	ADDQ.w	#2, Window_text_y.w
	ADDQ.w	#1, Shop_item_index.w
	MOVE.w	Shop_item_index.w, D0
	CMP.w	Shop_item_count.w, D0
	BLT.b	DrawShopItemListWindow_Done2
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; DrawShopSellListWindow
; Draw the shop sell list window with item names (no prices).
DrawShopSellListWindow:
	MOVE.w	Shop_item_count.w, D0
	SUBQ.w	#1, D0
	MOVE.w	D0, Menu_cursor_column_break.w
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w
	MOVE.w	#$000B, Menu_cursor_base_x.w
	MOVE.w	#4, Menu_cursor_base_y.w
	MOVE.w	#$000A, Window_tilemap_x.w
	MOVE.w	#2, Window_tilemap_y.w
	MOVE.w	#$0018, Window_width.w
	MOVE.w	Shop_item_count.w, D0
	ADD.w	D0, D0
	ADDQ.w	#2, D0
	DrawWindowDynH
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	LEA	Shop_item_list.w, A3
	LEA	ShopCategoryNameTables, A4
	MOVE.w	Current_shop_type.w, D0
	ASL.w	#3, D0
	MOVEA.l	(A4,D0.w), A4
	MOVE.w	Shop_item_count.w, D7
	SUBQ.w	#1, D7
DrawShopSellListWindow_Done:
	MOVE.w	(A3)+, D4
	ANDI.w	#$00FF, D4
	ADD.w	D4, D4
	ADD.w	D4, D4
	MOVEA.l	(A4,D4.w), A0
	BSR.w	RenderTextToWindow
	ADDQ.w	#2, Window_text_y.w
	DBF	D7, DrawShopSellListWindow_Done
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; DrawTownListWindow
; Draw the town/destination selection list window.
DrawTownListWindow:
	MOVE.w	#$000B, Menu_cursor_base_x.w
	MOVE.w	#4, Menu_cursor_base_y.w
	MOVE.w	#$000A, Window_tilemap_x.w
	MOVE.w	#2, Window_tilemap_y.w
	MOVE.w	#0, Window_tile_attrs.w
	MOVE.w	#$000D, D0
	MOVE.w	#6, Menu_cursor_column_break.w
	MOVE.w	#$000D, Menu_cursor_last_index.w
	MOVE.w	#$0016, Window_width.w
	MOVE.w	#$0010, Window_height.w
	BSR.w	DrawWindowBorder
	MOVE.w	#$000C, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	LEA	TownNames, A4
	LEA	Towns_visited.w, A6
	LEA	$1C(A4), A4
	LEA	obj_sprite_flags(A6), A6
	MOVE.w	#6, D7
DrawTownListWindow_Done:
	MOVEA.l	(A4)+, A0
	MOVE.b	(A6)+, D0
	BEQ.b	DrawTownListWindow_Loop
	BSR.w	RenderTextToWindow
DrawTownListWindow_Loop:
	ADDQ.w	#2, Window_text_y.w
	DBF	D7, DrawTownListWindow_Done
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	LEA	TownNames, A4
	LEA	Towns_visited.w, A6
	MOVE.w	#6, D7
DrawTownListWindow_Loop_Done:
	MOVEA.l	(A4)+, A0
	MOVE.b	(A6)+, D0
	BEQ.b	DrawTownListWindow_Loop2
	BSR.w	RenderTextToWindow
DrawTownListWindow_Loop2:
	ADDQ.w	#2, Window_text_y.w
	DBF	D7, DrawTownListWindow_Loop_Done
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
;==============================================================
; TILEMAP / TEXT RENDERING
;==============================================================

; RenderTextToTilemap
; Render a single character from A0 directly to the VDP tilemap.
; Inputs: A0 = source byte pointer, D0/D1 = tile offset, D2/D3 = col/row
; Tile index formula: char + $04C0 | $8000
RenderTextToTilemap:
	JSR	GetScrollOffsetInTiles
	CLR.w	D3
RenderTextToTilemap_Done:
	CLR.w	D2
RenderTextToTilemap_Done2:
	MOVE.w	D2, D4
	MOVE.w	D3, D5
	ADD.w	D0, D4
	ADD.w	D1, D5
	ADD.w	Window_tilemap_draw_x.w, D4
	ADD.w	Window_tilemap_draw_y.w, D5
	ANDI.w	#$003F, D4
	ANDI.w	#$003F, D5
	ASL.w	#1, D4
	ASL.w	#7, D5
	ADD.w	D4, D5
	ANDI.l	#$0000FFFF, D5
	SWAP	D5
	ADDI.l	#$40000003, D5
	ORI	#$0700, SR
	MOVE.l	D5, VDP_control_port
	CLR.w	D4
	MOVE.b	(A0)+, D4
	ADDI.w	#$04C0, D4
	ORI.w	#$8000, D4
	OR.w	Script_tile_attrs.w, D4
	MOVE.w	D4, VDP_data_port
	ANDI	#$F8FF, SR
	ADDQ.w	#1, D2
	CMP.w	Window_tilemap_draw_width.w, D2
	BLE.b	RenderTextToTilemap_Done2
	ADDQ.w	#1, D3
	CMP.w	Window_tilemap_draw_height.w, D3
	BLE.b	RenderTextToTilemap_Done
	RTS
	
;==============================================================
; NUMBER FORMATTING
;==============================================================

; (LongToDecimalString_Alt: thunk data — BRA.w prefix, do not call directly)
LongToDecimalString_Alt:
	dc.b	$7E, $01, $60, $00, $00, $04 
; LongToDecimalString
; Convert 32-bit BCD value in D2 to a 6-digit decimal string.
; Outputs each digit via WriteDigitToWindowAndAdvance or stores to (A0)+.
; Inputs: D2 = BCD long, D5 = 0 (write to VDP) or 1 (write to buffer A0)
LongToDecimalString:
	MOVEQ	#0, D7
	ROL.l	#8, D2
	MOVEQ	#5, D6
LongToDecimalString_Done:
	ROL.l	#4, D2
	MOVE.l	D2, D4
	ANDI.l	#$0000000F, D4
	BNE.b	LongToDecimalString_EncodeDigit
	TST.w	D7
	BNE.b	LongToDecimalString_EncodeDigit
	TST.w	D6
	BEQ.b	LongToDecimalString_EncodeDigit
	MOVE.b	#$20, D4
	BRA.b	LongToDecimalString_EncodeDigit_Loop
LongToDecimalString_EncodeDigit:
	ADDI.b	#$30, D4
	MOVEQ	#1, D7
LongToDecimalString_EncodeDigit_Loop:
	TST.w	D5
	BNE.b	LongToDecimalString_EncodeDigit_Loop2
	BSR.w	WriteDigitToWindowAndAdvance
	BRA.b	LongToDecimalString_EncodeDigit_Loop3
LongToDecimalString_EncodeDigit_Loop2:
	MOVE.b	D4, (A0)+
LongToDecimalString_EncodeDigit_Loop3:
	DBF	D6, LongToDecimalString_Done
	RTS
	
; FormatLongNumberToText
; Format a 32-bit BCD value to a null-terminated decimal string in Window_text_scratch.
; Inputs: D2 = BCD long value
FormatLongNumberToText:
	MOVE.w	#0, D3
	MOVEQ	#1, D5
	LEA	Window_text_scratch.w, A0
	BSR.b	LongToDecimalString
	MOVE.b	#$FF, (A0)
	RTS
	
; (FormatLongNumberToText_Alt: thunk data — BRA.w prefix, do not call directly)
FormatLongNumberToText_Alt:
	dc.b	$7E, $01, $60, $00, $00, $04 
; ConvertNumberToTextDigits
; Convert a 16-bit BCD value in D2 to a 4-digit decimal string.
; Inputs: D2 = BCD word, D5 = 0 (write to VDP) or 1 (write to buffer A0)
ConvertNumberToTextDigits:
	MOVEQ	#0, D7
	MOVEQ	#3, D6
ConvertNumberToTextDigits_Done:
	ROL.w	#4, D2
	MOVE.w	D2, D4
	ANDI.w	#$000F, D4
	BNE.b	ConvertNumberToTextDigits_EncodeDigit
	TST.w	D7
	BNE.b	ConvertNumberToTextDigits_EncodeDigit
	TST.w	D6
	BEQ.b	ConvertNumberToTextDigits_EncodeDigit
	MOVE.b	#$20, D4
	BRA.b	ConvertNumberToTextDigits_EncodeDigit_Loop
ConvertNumberToTextDigits_EncodeDigit:
	ADDI.b	#$30, D4
	MOVEQ	#1, D7
ConvertNumberToTextDigits_EncodeDigit_Loop:
	TST.w	D5
	BNE.b	ConvertNumberToTextDigits_EncodeDigit_Loop2
	BSR.w	WriteDigitToWindowAndAdvance
	BRA.b	ConvertNumberToTextDigits_EncodeDigit_Loop3
ConvertNumberToTextDigits_EncodeDigit_Loop2:
	MOVE.b	D4, (A0)+
ConvertNumberToTextDigits_EncodeDigit_Loop3:
	DBF	D6, ConvertNumberToTextDigits_Done
	RTS
	
; WordToDecimalString_NoPad
; Like ConvertNumberToTextDigits but outputs to window plane 3 via WriteDigitToWindowPlane3.
; Inputs: D2 = BCD word, D5 = 0 (write to VDP) or 1 (write to buffer A0)
WordToDecimalString_NoPad:
	MOVEQ	#0, D7
	MOVEQ	#3, D6
WordToDecimalString_NoPad_Done:
	ROL.w	#4, D2
	MOVE.w	D2, D4
	ANDI.w	#$000F, D4
	BNE.b	WordToDecimalString_NoPad_EncodeDigit
	TST.w	D7
	BNE.b	WordToDecimalString_NoPad_EncodeDigit
	TST.w	D6
	BEQ.b	WordToDecimalString_NoPad_EncodeDigit
	MOVE.b	#$20, D4
	BRA.b	WordToDecimalString_NoPad_EncodeDigit_Loop
WordToDecimalString_NoPad_EncodeDigit:
	ADDI.b	#$30, D4
	MOVEQ	#1, D7
WordToDecimalString_NoPad_EncodeDigit_Loop:
	TST.w	D5
	BNE.b	WordToDecimalString_NoPad_EncodeDigit_Loop2
	BSR.w	WriteDigitToWindowPlane3
	BRA.b	WordToDecimalString_NoPad_EncodeDigit_Loop3
WordToDecimalString_NoPad_EncodeDigit_Loop2:
	MOVE.b	D4, (A0)+	
WordToDecimalString_NoPad_EncodeDigit_Loop3:
	DBF	D6, WordToDecimalString_NoPad_Done
	RTS
	
; WordToDecimalString
; Format a 16-bit BCD value to a null-terminated decimal string in Window_text_scratch.
; Inputs: D2 = BCD word
WordToDecimalString:
	MOVE.w	#0, D3
	MOVEQ	#1, D5
	LEA	Window_text_scratch.w, A0
	BSR.b	ConvertNumberToTextDigits
	MOVE.b	#$FF, (A0)
	RTS
	
;==============================================================
; WINDOW DIGIT OUTPUT
;==============================================================

; WriteDigitToWindowAndAdvance
; Write a single character tile to the window plane at the current number cursor position.
; Inputs: D4 = tile character, D3 = palette attribute bits
WriteDigitToWindowAndAdvance:
	BSR.w	CalcWindowTileVramAddress
	ORI.l	#$40000003, D0
	MOVE.l	D0, VDP_control_port
	MOVE.w	D4, VDP_data_port
	ADDQ.w	#1, Window_number_cursor_x.w
	RTS

; WriteDigitToWindowPlane3
; Like WriteDigitToWindowAndAdvance but writes to window plane 3 (HUD plane).
; Inputs: D4 = tile character
WriteDigitToWindowPlane3:
	BSR.w	CalcWindowTileVramAddress
	ORI.l	#$60000003, D0
	MOVE.l	D0, VDP_control_port
	MOVE.w	D4, VDP_data_port
	ADDQ.w	#1, Window_number_cursor_x.w
	RTS

; CalcWindowTileVramAddress
; Calculate VDP VRAM write address for window tile at (Window_number_cursor_x, Window_number_cursor_y).
; Inputs: D4 = tile index, D3 = attribute bits. Outputs: D0 = VDP address word (swapped for control port)
CalcWindowTileVramAddress:
	ADDI.w	#$84C0, D4
	OR.w	D3, D4
	JSR	GetScrollOffsetInTiles
	ADD.w	Window_number_cursor_x.w, D0
	ADD.w	Window_number_cursor_y.w, D1
	ANDI.w	#$003F, D0
	ANDI.w	#$003F, D1
	ADD.w	D0, D0
	ASL.w	#7, D1
	ADD.w	D1, D0
	ANDI.l	#$00001FFF, D0
	SWAP	D0
	RTS

;==============================================================
; TRANSACTION ARITHMETIC
;==============================================================

; AddExperiencePoints
; Add Transaction_amount (BCD) to Player_next_level_experience using ABCD, clamp to MAX_PLAYER_EXP.
AddExperiencePoints:
	LEA	Transaction_amount_end.w, A0
	LEA	Player_next_level_experience.w, A1
	MOVEQ	#3, D1
AddExperiencePoints_Done:
	ABCD	-(A0), -(A1)
	DBF	D1, AddExperiencePoints_Done
	CLR.l	Transaction_amount.w
	CMPI.l	#SUP_PLAYER_EXP, Player_experience.w
	BLT.b	AddExperiencePoints_Loop
	MOVE.l	#MAX_PLAYER_EXP, Player_experience.w	
AddExperiencePoints_Loop:
	RTS

; AddPaymentAmount
; Add Transaction_amount (BCD) to Player_kims using ABCD, clamp to MAX_PLAYER_KIMS.
AddPaymentAmount:
	LEA	Transaction_amount_end.w, A0
	LEA	(Player_kims+4).w, A1
	MOVEQ	#3, D1
AddPaymentAmount_Done:
	ABCD	-(A0), -(A1)
	DBF	D1, AddPaymentAmount_Done
	CLR.l	Transaction_amount.w
	CMPI.l	#SUP_PLAYER_KIMS, Player_kims.w
	BLT.b	AddPaymentAmount_Loop
	MOVE.l	#MAX_PLAYER_KIMS, Player_kims.w	
AddPaymentAmount_Loop:
	RTS
	
; DeductPaymentAmount
; Subtract Transaction_amount (BCD) from Player_kims using SBCD, clamp to 0.
DeductPaymentAmount:
	LEA	Transaction_amount_end.w, A0
	LEA	(Player_kims+4).w, A1
	MOVEQ	#3, D1
DeductPaymentAmount_Done:
	SBCD	-(A0), -(A1)
	DBF	D1, DeductPaymentAmount_Done
	CLR.l	Transaction_amount.w
	TST.l	Player_kims.w
	BGE.b	DeductPaymentAmount_Loop
	CLR.l	Player_kims.w
DeductPaymentAmount_Loop:
	RTS

; ---------------------------------------------------------------------------
; DeductPaymentAmount_DeadCode — unreachable duplicate of payment deduction
;
; DEAD CODE: No call sites exist anywhere in the ROM.  This appears to be an
; earlier version of the payment deduction logic that was superseded by the
; live code above.  It uses SBCD (Subtract BCD) to update the player's money
; field via Transaction_item_quantity/Player_mhp, which differs from the
; live version.  Cannot be removed without breaking bit-perfect output.
; ---------------------------------------------------------------------------
DeductPaymentAmount_DeadCode:					; unreferenced dead code
	LEA	Transaction_item_quantity.w, A0
	LEA	Player_mhp.w, A1
	MOVEQ	#1, D1
DeductPaymentAmount_Loop_Done:
	SBCD	-(A0), -(A1)
	DBF	D1, DeductPaymentAmount_Loop_Done
	CLR.l	Transaction_amount.w
	TST.w	Player_hp.w
	BGE.b	DeductPaymentAmount_Loop2
	CLR.w	Player_hp.w
DeductPaymentAmount_Loop2:
	RTS
; DisplayPlayerKims
; Render Player_kims to the money display window at fixed cursor position (2, 6).
DisplayPlayerKims:
	MOVE.w	#2, Window_number_cursor_x.w
	MOVE.w	#6, Window_number_cursor_y.w
	MOVE.l	Player_kims.w, D2
	MOVE.w	#0, D3
	CLR.w	D5
	BSR.w	LongToDecimalString
	RTS
	
;==============================================================
; MENU CURSOR INIT
;==============================================================

; InitMenuCursorForList
; Initialize menu cursor for a generic list. Inputs: D0 = column count. Sets base to (0x10, 4).
InitMenuCursorForList:
	SUBQ.w	#1, D0
	MOVE.w	D0, Menu_cursor_column_break.w
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w
	MOVE.w	#$0010, Menu_cursor_base_x.w
	MOVE.w	#4, Menu_cursor_base_y.w
	RTS
	
; InitItemMenuCursor
; Initialize cursor for the item list menu (single column, base at (3, 14)).
InitItemMenuCursor:
	MOVE.w	#1, Menu_cursor_column_break.w
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w
	MOVE.w	#3, Menu_cursor_base_x.w
	MOVE.w	#$000E, Menu_cursor_base_y.w
	RTS
	
; InitSpellbookCursor
; Initialize cursor for the spellbook menu (3 columns, base at (3, 14)).
InitSpellbookCursor:
	MOVE.w	#2, Menu_cursor_column_break.w
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w
	MOVE.w	#3, Menu_cursor_base_x.w
	MOVE.w	#$000E, Menu_cursor_base_y.w
	RTS
	
; SetShopMenuCursorPosition
; Initialize cursor for the shop item list using Shop_item_count. Base at (11, 4).
SetShopMenuCursorPosition:
	MOVE.w	Shop_item_count.w, D0	
	SUBQ.w	#1, D0	
	MOVE.w	D0, Menu_cursor_column_break.w	
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w	
	MOVE.w	#$000B, Menu_cursor_base_x.w	
	MOVE.w	#4, Menu_cursor_base_y.w	
	RTS
	
; ResetScriptOutputVars
; Reset script output position, tile attributes, and completion flags for a new dialogue line.
ResetScriptOutputVars:
	MOVE.w	#5, Script_output_base_x.w
	ADDQ.w	#2, Script_output_y.w
	MOVE.w	#0, Script_tile_attrs.w
	CLR.b	Script_text_complete.w
	CLR.b	Script_has_continuation.w
	CLR.b	Script_has_yes_no_question.w
	CLR.w	Script_source_offset.w
	CLR.w	Script_output_x.w
	RTS
	
;==============================================================
; SAVE FILE WINDOWS
;==============================================================

; DrawSaveFileSelectWindow
; Draw the save-file selection window with 3 slot labels and any saved game names.
DrawSaveFileSelectWindow:
	SetupWindow 4, 1, $001B, $0010
	LEA	SelectNumberStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#4, Window_text_y.w
	BSR.w	RenderTextToWindow
	MOVE.w	#2, Menu_cursor_column_break.w
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w
	MOVE.w	#5, Menu_cursor_base_x.w
	MOVE.w	#$000B, Menu_cursor_base_y.w
	LEA	$00200001, A0
	BSR.w	LoadSavegameNameToBuffer
	LEA	Savegame_name_buffer.w, A0
	MOVE.w	#$0127, D0
	BSR.w	RenderTextAtOffset
	LEA	$00200A81, A0
	BSR.w	LoadSavegameNameToBuffer
	LEA	Savegame_name_buffer.w, A0
	MOVE.w	#$015F, D0
	BSR.w	RenderTextAtOffset
	LEA	$00201501, A0
	BSR.w	LoadSavegameNameToBuffer
	LEA	Savegame_name_buffer.w, A0
	MOVE.w	#$0197, D0
	BSR.w	RenderTextAtOffset
	LEA	$00200131, A0
	BSR.w	FormatItemCountToBCD
	MOVE.w	#$012E, D0
	BSR.w	RenderTextToWindowAtPosition
	LEA	$00200BB1, A0
	BSR.w	FormatItemCountToBCD
	MOVE.w	#$0166, D0
	BSR.w	RenderTextToWindowAtPosition
	LEA	$00201631, A0
	BSR.w	FormatItemCountToBCD
	MOVE.w	#$019E, D0
	BSR.w	RenderTextToWindowAtPosition
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; LoadSavegameNameToBuffer
; Load a saved game's name string from SRAM into Savegame_name_buffer. Inputs: A0 = SRAM name pointer.
LoadSavegameNameToBuffer:
	LEA	Savegame_name_buffer.w, A1
	TST.b	(A0)
	BNE.b	LoadSavegameName_Copy
	TST.b	$2(A0)
	BNE.b	LoadSavegameName_Copy
	TST.b	$4(A0)
	BNE.b	LoadSavegameName_Copy
	TST.b	$6(A0)
	BNE.b	LoadSavegameName_Copy
	MOVE.l	#$4E4557FF, (A1)
	RTS
	
; LoadSavegameName_Copy
; Inner copy loop: transfer name bytes from SRAM (every other byte) to buffer until 14 chars done.
LoadSavegameName_Copy:
	MOVE.w	#$000D, D7
LoadSavegameName_Copy_Done:
	MOVE.b	(A0)+, (A1)+
	LEA	$1(A0), A0
	DBF	D7, LoadSavegameName_Copy_Done
	MOVE.w	#$FFFF, (A1)
	BSR.b	ValidateSavegameName
	RTS
	
; ValidateSavegameName
; Check if a save slot contains a valid game name (truncates to "????" if too long).
ValidateSavegameName:
	LEA	Savegame_name_buffer.w, A1
	CLR.w	D0
ValidateSavegameName_Loop:
	MOVE.b	(A1)+, D1
	CMPI.b	#SCRIPT_END, D1
	BEQ.b	ValidateSavegameName_Loop_Loop
	CMPI.b	#SCRIPT_WIDE_CHAR_LO, D1
	BEQ.b	ValidateSavegameName_Loop
	CMPI.b	#SCRIPT_WIDE_CHAR_HI, D1
	BEQ.b	ValidateSavegameName_Loop
	ADDQ.w	#1, D0
	CMPI.w	#6, D0
	BGT.b	ValidateSavegameName_Loop_Loop2
	BRA.b	ValidateSavegameName_Loop
ValidateSavegameName_Loop_Loop:
	RTS
	
ValidateSavegameName_Loop_Loop2:
	MOVE.l	#$3F3F3F3F, Savegame_name_buffer.w	
	MOVE.w	#$FFFF, Savegame_name_overflow.w	
	RTS
	
; FormatItemCountToBCD
; Convert raw item count bytes at A0 to a BCD word and render as a decimal string.
FormatItemCountToBCD:
	CLR.w	D0
	MOVE.b	(A0), D0
	ASL.w	#4, D0
	MOVE.b	$2(A0), D0
	ADDQ.w	#1, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	BSR.w	WordToDecimalString
	RTS
	
; DrawSaveErrorWindow
; Draw the "save error" message window.
DrawSaveErrorWindow:
	SetupWindow $000A, $0010, $0019, $000A
	LEA	ErrorPressCStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; DrawSaveSuccessWindow
; Draw the "game saved" confirmation window.
DrawSaveSuccessWindow:
	SetupWindow $000A, $0010, $0019, $000A	
	LEA	LooksBetterPressCStr, A0	
	MOVE.w	#2, Window_text_x.w	
	MOVE.w	#2, Window_text_y.w	
	BSR.w	RenderTextToWindow	
	CLR.w	Window_draw_row.w	
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w	
	RTS
	
; DrawSaveFailedWindow
; Draw the "save failed" error window.
DrawSaveFailedWindow:
	SetupWindow $000A, $0010, $0019, $000A
	LEA	DidntWorkPressResetStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; DrawNoSavedGameWindow
; Draw the "no saved game" informational window.
DrawNoSavedGameWindow:
	SetupWindow $000A, $0010, $0019, $000A
	LEA	NoSavedGameStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; DrawGameReadyWindow
; Draw the "game is ready" / continue-prompt window.
DrawGameReadyWindow:
	SetupWindow $000A, $0010, $0019, $000A	
	LEA	GameReadyPressCStr, A0	
	MOVE.w	#2, Window_text_x.w	
	MOVE.w	#2, Window_text_y.w	
	BSR.w	RenderTextToWindow	
	CLR.w	Window_draw_row.w	
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w	
	RTS
	
;==============================================================
; CHARACTER STATS / EQUIPMENT WINDOWS
;==============================================================

; DrawCharacterStatsWindow
; Draw the character status screen showing name, level, HP/MP, stats, and current condition.
DrawCharacterStatsWindow:
	SetupWindow 2, 2, $001B, $0014
	LEA	CharacterStatsStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	TST.w	Player_poisoned.w
	BEQ.b	DrawCharacterStatsWindow_Loop
	LEA	BadPoisonStr, A0
	BRA.b	DrawStatusScreen_RenderCondition
DrawCharacterStatsWindow_Loop:
	JSR	CheckIfCursed
	BEQ.b	DrawCharacterStatsWindow_Loop2
	LEA	BadCurseStr, A0
	BRA.b	DrawStatusScreen_RenderCondition
DrawCharacterStatsWindow_Loop2:
	MOVE.w	Player_hp.w, D0
	CMP.w	Player_mhp.w, D0
	BGE.b	DrawCharacterStatsWindow_Loop3
	LEA	GoodStr, A0
	BRA.b	DrawStatusScreen_RenderCondition
DrawCharacterStatsWindow_Loop3:
	LEA	BestStr, A0
; DrawStatusScreen_RenderCondition
; Render the character condition/status flags sub-section of the stats screen.
; Inputs: A0 = pointer to condition string to display
DrawStatusScreen_RenderCondition: ; stats screen?
	MOVE.w	#$007E, D0
	BSR.w	RenderTextAtOffset
	LEA	Player_name.w, A0
	MOVE.w	#$0041, D0
	BSR.w	RenderTextAtOffset
	MOVE.w	Player_level.w, D0
	ADDQ.w	#1, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	BSR.w	WordToDecimalString
	MOVE.w	#$00B1, D0
	BSR.w	RenderTextToWindowAtPosition
	MOVE.l	Player_experience.w, D2
	BSR.w	FormatLongNumberToText
	MOVE.w	#$00BC, D0
	BSR.w	RenderTextToWindowAtPosition
	MOVE.w	Player_hp.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	BSR.w	WordToDecimalString
	MOVE.w	#$0121, D0
	BSR.w	RenderTextToWindowAtPosition
	MOVE.w	Player_mp.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	BSR.w	WordToDecimalString
	MOVE.w	#$0159, D0
	BSR.w	RenderTextToWindowAtPosition
	MOVE.w	Player_str.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	BSR.w	WordToDecimalString
	MOVE.w	#$0191, D0
	BSR.w	RenderTextToWindowAtPosition
	MOVE.w	Player_ac.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	BSR.w	WordToDecimalString
	MOVE.w	#$019E, D0
	BSR.w	RenderTextToWindowAtPosition
	MOVE.w	Player_int.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	BSR.w	WordToDecimalString
	MOVE.w	#$01C9, D0
	BSR.w	RenderTextToWindowAtPosition
	MOVE.w	Player_dex.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	BSR.w	WordToDecimalString
	MOVE.w	#$01D6, D0
	BSR.w	RenderTextToWindowAtPosition
	MOVE.w	Player_luk.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	BSR.w	WordToDecimalString
	MOVE.w	#$0201, D0
	BSR.w	RenderTextToWindowAtPosition
	MOVE.l	Player_kims.w, D2
	BSR.w	FormatLongNumberToText
	MOVE.w	#$020C, D0
	BSR.w	RenderTextToWindowAtPosition
	MOVE.w	Player_mmp.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	BSR.w	WordToDecimalString
	MOVE.w	#$0166, D0
	BSR.w	RenderTextToWindowAtPosition
	MOVE.w	Player_mhp.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	BSR.w	WordToDecimalString
	MOVE.w	#$012E, D0
	BSR.w	RenderTextToWindowAtPosition
	MOVE.l	Player_next_level_experience.w, D2
	BSR.w	FormatLongNumberToText
	MOVE.w	#$00F4, D0
	BSR.w	RenderTextToWindowAtPosition
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; DrawEquippedGearWindow
; Draw the equipped gear list window showing weapon, shield, armor, ring, and other slots.
DrawEquippedGearWindow:
	SetupWindow 2, 2, $001A, $000C
	LEA	EquipmentReadiedStr, A0
	MOVE.w	#1, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	LEA	NothingStr, A0
	MOVE.w	Equipped_sword.w, D0
	BLT.b	DrawEquippedGearWindow_Loop
	BSR.w	GetEquipmentNamePointer
DrawEquippedGearWindow_Loop:
	MOVE.w	#$0074, D0
	BSR.w	RenderTextAtOffset
	LEA	NothingStr, A0
	MOVE.w	Equipped_shield.w, D0
	BLT.b	DrawEquippedGearWindow_Loop2
	BSR.w	GetEquipmentNamePointer
DrawEquippedGearWindow_Loop2:
	MOVE.w	#$00AA, D0
	BSR.w	RenderTextAtOffset
	LEA	NothingStr, A0
	MOVE.w	Equipped_armor.w, D0
	BLT.b	DrawEquippedGearWindow_Loop3
	BSR.w	GetEquipmentNamePointer
DrawEquippedGearWindow_Loop3:
	MOVE.w	#$00DF, D0
	BSR.w	RenderTextAtOffset
	LEA	NothingStr, A0
	MOVE.w	Readied_magic.w, D0
	BLT.b	DrawEquippedGearWindow_Loop4
	BSR.w	GetMagicNamePointer
DrawEquippedGearWindow_Loop4:
	MOVE.w	#$0115, D0
	BSR.w	RenderTextAtOffset
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; GetEquipmentNamePointer
; Return a pointer to the equipment name string for a given equipment ID.
; Inputs: D0 = equipment ID. Outputs: A0 = pointer to name string.
GetEquipmentNamePointer:
	LEA	EquipmentNames, A1
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A1,D0.w), A0
	RTS
	
; GetMagicNamePointer
; Return a pointer to the magic spell name string for a given spell ID.
; Inputs: D0 = spell ID. Outputs: A0 = pointer to name string.
GetMagicNamePointer:
	LEA	MagicNames, A1
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A1,D0.w), A0
	RTS
	
;==============================================================
; INVENTORY LIST WINDOWS
;==============================================================

; DrawGearCombatWindow
; Draw the gear/combat stats window showing attack, defense, and magic values.
DrawGearCombatWindow:
	MOVE.w	#$000F, Window_tilemap_x.w
	MOVE.w	#2, Window_tilemap_y.w
	MOVE.w	#$0016, Window_width.w
	MOVE.w	Possessed_equipment_length.w, D0
	BLE.w	DrawGearCombatWindow_Loop
	ADD.w	D0, D0
	ADDQ.w	#3, D0
	DrawWindowDynH
	LEA	GearCombatStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	ADDQ.w	#2, Window_text_y.w
	LEA	Possessed_equipment_list.w, A3
	LEA	EquipmentNames, A4
	MOVE.w	Possessed_equipment_length.w, D7
	SUBQ.w	#1, D7
DrawGearCombatWindow_Done:
	MOVE.w	(A3)+, D4
	ANDI.w	#$00FF, D4
	ADD.w	D4, D4
	ADD.w	D4, D4
	MOVEA.l	(A4,D4.w), A0
	BSR.w	RenderTextToWindow
	ADDQ.w	#2, Window_text_y.w
	DBF	D7, DrawGearCombatWindow_Done
	MOVE.w	#$0014, Window_text_x.w
	MOVE.w	#4, Window_text_y.w
	LEA	Possessed_equipment_list.w, A2
	MOVE.w	Possessed_equipment_length.w, D7
	BSR.w	DrawEquippedMarkers
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
DrawGearCombatWindow_Loop:
	SetupWindowSize 5	
	LEA	GearCombatStr, A0	
	MOVE.w	#2, Window_text_x.w	
	MOVE.w	#2, Window_text_y.w	
	BSR.w	RenderTextToWindow	
	LEA	NothingStr, A0	
	MOVE.w	#$0060, D0	
	BSR.w	RenderTextAtOffset	
	CLR.w	Window_draw_row.w	
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w	
	RTS
	
; DrawEquippedMarkers
; Draw marker icons next to currently equipped items in the list. Inputs: A2 = item list, Window_height = row count.
DrawEquippedMarkers:
	MOVE.w	Window_height.w, D7
	SUBQ.w	#1, D7
	CLR.w	D3
DrawEquippedMarkers_Done:
	MOVE.w	(A2)+, D4
	ANDI.w	#$8000, D4
	BEQ.b	DrawEquippedMarkers_Loop
	MOVE.w	Window_width.w, D0
	ADDQ.w	#1, D0
	MOVE.w	Window_text_y.w, D1
	MULU.w	D1, D0
	ADD.w	Window_text_x.w, D0
	LEA	Window_tilemap_buffer.w, A1
	LEA	(A1,D0.w), A1
	MOVE.b	#$2A, (A1)
DrawEquippedMarkers_Loop:
	ADDQ.w	#2, Window_text_y.w
	DBF	D7, DrawEquippedMarkers_Done
	RTS
	
; DrawMagicListWindow
; Draw the magic spell list window with spell names and equipped markers.
DrawMagicListWindow:
	MOVE.w	#2, Window_tilemap_x.w
	MOVE.w	#2, Window_tilemap_y.w
	MOVE.w	#$0011, Window_width.w
	MOVE.w	Possessed_magics_length.w, D0
	BLE.w	DrawMagicListWindow_Loop
	ADD.w	D0, D0
	ADDQ.w	#3, D0
	DrawWindowDynH
	LEA	GearMagicStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	ADDQ.w	#2, Window_text_y.w
	LEA	Possessed_magics_list.w, A3
	LEA	MagicNames, A4
	MOVE.w	Possessed_magics_length.w, D7
	SUBQ.w	#1, D7
DrawMagicListWindow_Done:
	MOVE.w	(A3)+, D4
	ANDI.w	#$00FF, D4
	ADD.w	D4, D4
	ADD.w	D4, D4
	MOVEA.l	(A4,D4.w), A0
	BSR.w	RenderTextToWindow
	ADDQ.w	#2, Window_text_y.w
	DBF	D7, DrawMagicListWindow_Done
	MOVE.w	#$0021, Window_text_x.w
	MOVE.w	#3, Window_text_y.w
	LEA	Possessed_magics_list.w, A2
	MOVE.w	Possessed_magics_length.w, D7
	BSR.w	DrawEquippedMarkers
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
DrawMagicListWindow_Loop:
	SetupWindowSize 5
	LEA	GearMagicStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	LEA	NothingStr, A0
	MOVE.w	#$004C, D0
	BSR.w	RenderTextAtOffset
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
; DrawItemsListWindow
; Draw the inventory items list window.
DrawItemsListWindow:
	MOVE.w	#$000F, Window_tilemap_x.w
	MOVE.w	#2, Window_tilemap_y.w
	MOVE.w	#$0016, Window_width.w
	MOVE.w	Possessed_items_length.w, D0
	BLE.w	DrawItemsListWindow_Loop
	ADD.w	D0, D0
	ADDQ.w	#3, D0
	DrawWindowDynH
	LEA	GearItemStr, A0
	MOVE.w	#2, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	ADDQ.w	#2, Window_text_y.w
	LEA	Possessed_items_list.w, A3
	LEA	ItemNames, A4
	MOVE.w	Possessed_items_length.w, D7
	SUBQ.w	#1, D7
DrawItemsListWindow_Done:
	MOVE.w	(A3)+, D4
	ANDI.w	#$00FF, D4
	ADD.w	D4, D4
	ADD.w	D4, D4
	MOVEA.l	(A4,D4.w), A0
	BSR.w	RenderTextToWindow
	ADDQ.w	#2, Window_text_y.w
	DBF	D7, DrawItemsListWindow_Done
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
DrawItemsListWindow_Loop:
	SetupWindowSize 5	
	LEA	GearItemStr, A0	
	MOVE.w	#2, Window_text_x.w	
	MOVE.w	#2, Window_text_y.w	
	BSR.w	RenderTextToWindow	
	LEA	NothingStr, A0	
	MOVE.w	#$0060, D0	
	BSR.w	RenderTextAtOffset	
	CLR.w	Window_draw_row.w	
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w	
	RTS
	
; DrawRingsListWindow
; Draw the rings/accessories list window.
DrawRingsListWindow:
	LEA	Rings_collected.w, A0
	CLR.w	D0
	MOVE.w	#7, D7
DrawRingsListWindow_Done:
	TST.b	(A0)+
	BEQ.b	DrawRingsListWindow_Loop
	ADDQ.w	#1, D0
DrawRingsListWindow_Loop:
	DBF	D7, DrawRingsListWindow_Done
	MOVE.w	D0, Possessed_rings_count.w
	MOVE.w	#9, Window_tilemap_x.w
	MOVE.w	#2, Window_tilemap_y.w
	MOVE.w	#$0011, Window_width.w
	TST.w	D0
	BLE.w	RingsInventory_EmptyDisplay
	TST.b	All_rings_collected.w
	BNE.w	RingsInventory_EmptyDisplay
	ADD.w	D0, D0
	ADDQ.w	#3, D0
	DrawWindowDynH
	LEA	RingsStr, A0
	MOVE.w	#7, Window_text_x.w
	MOVE.w	#2, Window_text_y.w
	BSR.w	RenderTextToWindow
	MOVE.w	#2, Window_text_x.w
	ADDQ.w	#2, Window_text_y.w
	MOVE.w	#$FFFF, D4
	LEA	RingNames, A4
	LEA	Rings_collected.w, A3
	MOVE.w	Possessed_rings_count.w, D7
	SUBQ.w	#1, D7
RingsInventory_NextEntry:
	ADDQ.w	#1, D4
	MOVE.b	(A3)+, D0
	BEQ.b	RingsInventory_NextEntry
	MOVE.w	D4, D3
	ADD.w	D3, D3
	ADD.w	D3, D3
	MOVEA.l	(A4,D3.w), A0
	BSR.w	RenderTextToWindow
	ADDQ.w	#2, Window_text_y.w
	DBF	D7, RingsInventory_NextEntry
	CLR.w	Window_draw_row.w
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w
	RTS
	
RingsInventory_EmptyDisplay:
	SetupWindowSize 5	
	LEA	RingsStr, A0	
	MOVE.w	#2, Window_text_x.w	
	MOVE.w	#2, Window_text_y.w	
	BSR.w	RenderTextToWindow	
	LEA	NothingStr, A0	
	TST.b	All_rings_collected.w	
	BEQ.b	RingsInventory_EmptyDisplay_Loop	
	LEA	AllRingsStr, A0	
RingsInventory_EmptyDisplay_Loop:
	MOVE.w	#$004C, D0	
	BSR.w	RenderTextAtOffset	
	CLR.w	Window_draw_row.w	
	MOVE.b	#FLAG_TRUE, Window_tilemap_draw_active.w	
	RTS
	
;==============================================================
; WINDOW DRAW TYPE DISPATCH
;==============================================================

; DispatchWindowDrawType
; Dispatch to the appropriate window-draw routine based on Window_draw_type. Inputs: Window_draw_type = type index.
DispatchWindowDrawType:
	LEA	WindowDrawTypeJumpTable, A0
	MOVE.w	Window_draw_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	JSR	(A0,D0.w)
	RTS
	
; Window draw type jump table — indexed by window type ID (4 bytes per entry)
WindowDrawTypeJumpTable:
	BRA.w	WindowDrawTypeJumpTable_Loop
	BRA.w	WindowDrawTypeJumpTable_Loop2
	BRA.w	DrawWindowRow_MessageSpeed	
	BRA.w	DrawWindowRow_MessageSpeed_Loop
	BRA.w	DrawWindowRow_MessageSpeed_Loop2
	BRA.w	DrawWindowRow_MessageSpeed_Loop3
	BRA.w	DrawWindowRow_MessageSpeed_Loop4
	BRA.w	DrawWindowRow_MessageSpeed_Loop5	
	BRA.w	DrawWindowRow_MessageSpeed_Loop6
	BRA.w	WindowDrawTypeJumpTable_Loop3
	BRA.w	WindowDrawTypeJumpTable_Loop4
	BRA.w	WindowDrawTypeJumpTable_Loop5
	BRA.w	WindowDrawTypeJumpTable_Loop6
	BRA.w	DrawWindowRow_MessageSpeed	
	BRA.w	DrawWindowRow_MessageSpeed_Loop7
WindowDrawTypeJumpTable_Loop:
	TST.b	Dialog_active_flag.w
	BEQ.b	WindowDrawTypeJumpTable_Loop7
	MOVEA.l	Current_actor_ptr.w, A6
	BSET.b	#7, obj_sprite_flags(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BSET.b	#7, obj_sprite_flags(A6)
WindowDrawTypeJumpTable_Loop7:
	MOVE.w	#2, Window_tilemap_draw_x.w
	MOVE.w	#2, Window_tilemap_draw_y.w
	MOVE.w	#$001B, Window_tilemap_draw_width.w
	MOVE.w	#$0014, Window_tilemap_draw_height.w
	LEA	Script_window_tiles_buffer, A0
	BRA.w	DrawWindowRowFromBuffer
WindowDrawTypeJumpTable_Loop2:
	MOVE.w	#2, Window_tilemap_draw_x.w
	MOVE.w	#2, Window_tilemap_draw_y.w
	MOVE.w	#$001A, Window_tilemap_draw_width.w
	MOVE.w	#$000C, Window_tilemap_draw_height.w
	LEA	Full_menu_tiles_buffer, A0
	BRA.w	DrawWindowRowFromBuffer
WindowDrawTypeJumpTable_Loop3:
	MOVE.w	#$000F, Window_tilemap_draw_x.w
	MOVE.w	#2, Window_tilemap_draw_y.w
	MOVE.w	#$0016, Window_tilemap_draw_width.w
	MOVE.w	Possessed_equipment_length.w, D0
	BGT.b	WindowDrawTypeJumpTable_Loop8
	MOVE.w	#1, D0	
WindowDrawTypeJumpTable_Loop8:
	ADD.w	D0, D0
	ADDQ.w	#3, D0
	MOVE.w	D0, Window_tilemap_draw_height.w
	LEA	Equipment_list_tiles_buffer.w, A0
	BRA.w	DrawWindowRowFromBuffer
WindowDrawTypeJumpTable_Loop4:
	MOVE.w	#2, Window_tilemap_draw_x.w
	MOVE.w	#2, Window_tilemap_draw_y.w
	MOVE.w	#$0011, Window_tilemap_draw_width.w
	MOVE.w	Possessed_magics_length.w, D0
	BGT.b	WindowDrawTypeJumpTable_Loop9
	MOVE.w	#1, D0
WindowDrawTypeJumpTable_Loop9:
	ADD.w	D0, D0
	ADDQ.w	#3, D0
	MOVE.w	D0, Window_tilemap_draw_height.w
	LEA	Magic_list_tiles_buffer.w, A0
	BRA.w	DrawWindowRowFromBuffer
WindowDrawTypeJumpTable_Loop5:
	MOVE.w	#$000F, Window_tilemap_draw_x.w
	MOVE.w	#2, Window_tilemap_draw_y.w
	MOVE.w	#$0016, Window_tilemap_draw_width.w
	MOVE.w	Possessed_items_length.w, D0
	BGT.b	WindowDrawTypeJumpTable_Loop10
	MOVE.w	#1, D0	
WindowDrawTypeJumpTable_Loop10:
	ADD.w	D0, D0
	ADDQ.w	#3, D0
	MOVE.w	D0, Window_tilemap_draw_height.w
	LEA	Item_list_right_tiles_buffer.w, A0
	BRA.w	DrawWindowRowFromBuffer
WindowDrawTypeJumpTable_Loop6:
	MOVE.w	#9, Window_tilemap_draw_x.w
	MOVE.w	#2, Window_tilemap_draw_y.w
	MOVE.w	#$0011, Window_tilemap_draw_width.w
	MOVE.w	Possessed_rings_count.w, D0
	BGT.b	WindowDrawTypeJumpTable_Loop11
	MOVE.w	#1, D0	
WindowDrawTypeJumpTable_Loop11:
	ADD.w	D0, D0
	ADDQ.w	#3, D0
	MOVE.w	D0, Window_tilemap_draw_height.w
	LEA	Rings_list_tiles_buffer.w, A0
	BRA.w	DrawWindowRowFromBuffer
; DrawWindowRow_MessageSpeed
; Draw a single row of the message speed selection window from its tile buffer.
DrawWindowRow_MessageSpeed:
	MOVE.w	#$000A, Window_tilemap_draw_x.w	
	MOVE.w	#$000A, Window_tilemap_draw_y.w	
	MOVE.w	#$000E, Window_tilemap_draw_width.w	
	MOVE.w	#$000A, Window_tilemap_draw_height.w	
	LEA	Message_speed_menu_tiles_buffer, A0	
	BRA.w	DrawWindowRowFromBuffer	
DrawWindowRow_MessageSpeed_Loop:
	MOVE.w	#2, Window_tilemap_draw_x.w
	MOVE.w	#2, Window_tilemap_draw_y.w
	MOVE.w	#$000D, Window_tilemap_draw_width.w
	MOVE.w	#$000A, Window_tilemap_draw_height.w
	LEA	Message_speed_menu_tiles_buffer, A0
	BRA.w	DrawWindowRowFromBuffer
DrawWindowRow_MessageSpeed_Loop2:
	MOVE.w	#2, Window_tilemap_draw_x.w
	MOVE.w	#$000C, Window_tilemap_draw_y.w
	MOVE.w	#$000D, Window_tilemap_draw_width.w
	MOVE.w	#6, Window_tilemap_draw_height.w
	LEA	Item_list_tiles_buffer, A0
	BRA.w	DrawWindowRowFromBuffer
DrawWindowRow_MessageSpeed_Loop7:
	MOVE.w	#2, Window_tilemap_draw_x.w
	MOVE.w	#$000C, Window_tilemap_draw_y.w
	MOVE.w	#$000D, Window_tilemap_draw_width.w
	MOVE.w	#8, Window_tilemap_draw_height.w
	LEA	Item_list_tiles_buffer, A0
	BRA.w	DrawWindowRowFromBuffer
DrawWindowRow_MessageSpeed_Loop3:
	MOVE.w	#2, Window_tilemap_draw_x.w
	MOVE.w	#$000C, Window_tilemap_draw_y.w
	MOVE.w	#7, Window_tilemap_draw_width.w
	MOVE.w	#8, Window_tilemap_draw_height.w
	LEA	Status_menu_tiles_buffer.w, A0
	BRA.w	DrawWindowRowFromBuffer
DrawWindowRow_MessageSpeed_Loop4:
	MOVE.w	#2, Window_tilemap_draw_x.w
	MOVE.w	#$000C, Window_tilemap_draw_y.w
	MOVE.w	#$000B, Window_tilemap_draw_width.w
	MOVE.w	#8, Window_tilemap_draw_height.w
	LEA	Small_menu_tiles_buffer, A0
	BRA.w	DrawWindowRowFromBuffer
DrawWindowRow_MessageSpeed_Loop5:
	MOVE.w	#$000C, Window_tilemap_draw_x.w	
	MOVE.w	#4, Window_tilemap_draw_y.w	
	MOVE.w	#9, Window_tilemap_draw_width.w	
	MOVE.w	#8, Window_tilemap_draw_height.w	
	LEA	Right_menu_tiles_buffer, A0	
	BRA.w	DrawWindowRowFromBuffer	
DrawWindowRow_MessageSpeed_Loop6:
	MOVE.w	#2, Window_tilemap_draw_x.w
	MOVE.w	#$000A, Window_tilemap_draw_y.w
	MOVE.w	#$0015, Window_tilemap_draw_width.w
	MOVE.w	#$000A, Window_tilemap_draw_height.w
	LEA	Status_menu_tiles_buffer.w, A0
; DrawWindowRowFromBuffer
; Copy a saved window region from a tile buffer back to VRAM, one row per call.
; Inputs: A0 = tile buffer, Window_tilemap_draw_* = region parameters
DrawWindowRowFromBuffer:
	MOVE.w	Window_tilemap_draw_height.w, D0
	SUB.w	Window_text_row.w, D0
	BLE.w	DrawWindowTilemap_WriteVDP_Loop
	ADD.w	D0, Window_tilemap_draw_y.w
	MOVE.w	Window_tilemap_draw_width.w, D1
	ADDQ.w	#1, D1
	MULU.w	D1, D0
	ADD.w	D0, D0
	LEA	(A0,D0.w), A0
	JSR	GetScrollOffsetInTiles
	ADD.w	Window_tilemap_draw_y.w, D1
	SUBQ.w	#1, D1
	ANDI.w	#$003F, D1
	ASL.w	#7, D1
	CLR.w	D2
DrawWindowRowFromBuffer_Done:
	MOVE.w	D2, D4
	ADD.w	D0, D4
	MOVE.w	D1, D5
	ADD.w	Window_tilemap_draw_x.w, D4
	ANDI.w	#$003F, D4
	ASL.w	#1, D4
	ADD.w	D4, D5
	ANDI.l	#$0000FFFF, D5
	SWAP	D5
	ADDI.l	#$40000003, D5
	MOVE.w	#$85A6, D4
	TST.w	D2
	BEQ.b	DrawWindowTilemap_WriteVDP
	ADDQ.w	#1, D4
	CMP.w	Window_tilemap_draw_width.w, D2
	BNE.b	DrawWindowTilemap_WriteVDP
	ADDQ.w	#1, D4
; DrawWindowTilemap_WriteVDP
; Write a window tilemap row directly to VDP VRAM.
DrawWindowTilemap_WriteVDP:
	MOVE.l	D5, VDP_control_port
	MOVE.w	D4, VDP_data_port
	ADDQ.w	#1, D2
	CMP.w	Window_tilemap_draw_width.w, D2
	BLE.b	DrawWindowRowFromBuffer_Done
	BRA.b	DrawWindowTilemap_WriteVDP_Loop2
DrawWindowTilemap_WriteVDP_Loop:
	CLR.b	Window_tilemap_row_draw_pending.w
DrawWindowTilemap_WriteVDP_Loop2:
	JSR	GetScrollOffsetInTiles
	ADD.w	Window_tilemap_draw_y.w, D1
	ANDI.w	#$003F, D1
	ASL.w	#7, D1
	CLR.w	D2
DrawWindowTilemap_WriteVDP_Loop2_Done:
	MOVE.w	D2, D4
	ADD.w	D0, D4
	MOVE.w	D1, D5
	ADD.w	Window_tilemap_draw_x.w, D4
	ANDI.w	#$003F, D4
	ASL.w	#1, D4
	ADD.w	D4, D5
	ANDI.l	#$0000FFFF, D5
	SWAP	D5
	ADDI.l	#$40000003, D5
	MOVE.l	D5, VDP_control_port
	MOVE.w	(A0)+, VDP_data_port
	ADDQ.w	#1, D2
	CMP.w	Window_tilemap_draw_width.w, D2
	BLE.b	DrawWindowTilemap_WriteVDP_Loop2_Done
	ADDQ.w	#1, Window_text_row.w
	RTS
	
;==============================================================
; WINDOW BUFFER SAVE/RESTORE
;==============================================================

; SaveMessageSpeedMenuToBuffer_Alt
; Save the message speed menu area (small region) to buffer.
SaveMessageSpeedMenuToBuffer_Alt:
	LEA	Message_speed_menu_tiles_buffer, A0
	MOVE.w	#2, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#$000D, Window_tile_width.w
	MOVE.w	#$000A, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; ---------------------------------------------------------------------------
; SaveStatusBarToBuffer — snapshot the status-bar VRAM region to RAM
;
; Reads the 31×8 tile region at nametable position (4, 19) into
; Script_window_tiles_buffer so it can be restored later by
; DrawStatusHudWindow.  If Dialog_active_flag is set, also clears bit 7
; of obj_sprite_flags on Current_actor_ptr (hides its sprite while the
; dialogue window is open).
;
; Input:   (all state via RAM)
; Scratch:  A0, A6, D0
; Output:   Script_window_tiles_buffer filled; VDP nametable read
; ---------------------------------------------------------------------------
; SaveStatusBarToBuffer
; Save the status bar tile region to buffer for later restore.
SaveStatusBarToBuffer:
	TST.b	Dialog_active_flag.w
	BEQ.b	SaveStatusBarToBuffer_Loop
	MOVEA.l	Current_actor_ptr.w, A6
	BCLR.b	#7, obj_sprite_flags(A6)
SaveStatusBarToBuffer_Loop:
	LEA	Script_window_tiles_buffer, A0
	MOVE.w	#4, Window_tile_x.w
	MOVE.w	#$0013, Window_tile_y.w
	MOVE.w	#$001F, Window_tile_width.w
	MOVE.w	#8, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SavePromptMenuToBuffer
; Save the prompt menu area tiles to buffer.
SavePromptMenuToBuffer:
	LEA	Prompt_menu_tiles_buffer.w, A0
	MOVE.w	#5, Window_tile_x.w
	MOVE.w	#4, Window_tile_y.w
	MOVE.w	#$000B, Window_tile_width.w
	MOVE.w	#2, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveRightMenuAreaToBuffer
; Save the right menu panel area to buffer.
SaveRightMenuAreaToBuffer:
	LEA	Small_menu_tiles_buffer, A0
	MOVE.w	#$001C, Window_tile_x.w
	MOVE.w	#$000D, Window_tile_y.w
	MOVE.w	#6, Window_tile_width.w
	MOVE.w	#6, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveShopSubmenuAreaToBuffer
; Save the shop submenu area to buffer.
SaveShopSubmenuAreaToBuffer:
	LEA	Shop_submenu_tiles_buffer.w, A0
	MOVE.w	#$000F, Window_tile_x.w
	MOVE.w	#$000C, Window_tile_y.w
	MOVE.w	#$0015, Window_tile_width.w
	MOVE.w	#7, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveCenterDialogAreaToBuffer
; Save the center dialog area to buffer.
SaveCenterDialogAreaToBuffer:
	LEA	Large_menu_tiles_buffer, A0
	MOVE.w	#$000F, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#$0015, Window_tile_width.w
	MOVE.w	#$0015, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveItemListAreaToBuffer_Small
; Save a small item list region (6 rows) to buffer.
SaveItemListAreaToBuffer_Small:
	LEA	Item_list_tiles_buffer, A0
	MOVE.w	#2, Window_tile_x.w
	MOVE.w	#$000C, Window_tile_y.w
	MOVE.w	#$000D, Window_tile_width.w
	MOVE.w	#6, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveItemListAreaToBuffer_Large
; Save a large item list region (8 rows) to buffer.
SaveItemListAreaToBuffer_Large:
	LEA	Item_list_tiles_buffer, A0
	MOVE.w	#2, Window_tile_x.w
	MOVE.w	#$000C, Window_tile_y.w
	MOVE.w	#$000D, Window_tile_width.w
	MOVE.w	#8, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveStatusMenuAreaToBuffer_Small
; Save a small status menu region (narrow column) to buffer.
SaveStatusMenuAreaToBuffer_Small:
	LEA	Status_menu_tiles_buffer.w, A0
	MOVE.w	#2, Window_tile_x.w
	MOVE.w	#$000C, Window_tile_y.w
	MOVE.w	#7, Window_tile_width.w
	MOVE.w	#8, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveStatusMenuAreaToBuffer_Large
; Save a large status menu region (full width) to buffer.
SaveStatusMenuAreaToBuffer_Large:
	LEA	Status_menu_tiles_buffer.w, A0
	MOVE.w	#2, Window_tile_x.w
	MOVE.w	#$000A, Window_tile_y.w
	MOVE.w	#$0015, Window_tile_width.w
	MOVE.w	#$000A, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveShopListToBuffer
; Save the shop item list area to buffer.
SaveShopListToBuffer:
	LEA	Shop_list_tiles_buffer.w, A0
	MOVE.w	#$000A, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#$0018, Window_tile_width.w
	MOVE.w	#$0011, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveStatusMenuTiles
; Save the status menu tiles to buffer.
SaveStatusMenuTiles:
	LEA	Status_menu_tiles_buffer.w, A0
	MOVE.w	#$000A, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#$0016, Window_tile_width.w
	MOVE.w	#$0010, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveLeftMenuTiles
; Save the left menu tiles to buffer.
SaveLeftMenuTiles:
	LEA	Left_menu_tiles_buffer.w, A0
	MOVE.w	#0, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#9, Window_tile_width.w
	MOVE.w	#6, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveFullDialogAreaToBuffer
; Save the full dialog area tiles to buffer, hiding any active sprite first.
SaveFullDialogAreaToBuffer:
	TST.b	Dialog_active_flag.w
	BEQ.b	SaveFullDialogAreaToBuffer_Loop
	MOVEA.l	Current_actor_ptr.w, A6
	BCLR.b	#7, obj_sprite_flags(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BCLR.b	#7, obj_sprite_flags(A6)
SaveFullDialogAreaToBuffer_Loop:
	LEA	Script_window_tiles_buffer, A0
	MOVE.w	#2, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#$001B, Window_tile_width.w
	MOVE.w	#$0014, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveFullMenuTiles
; Save the full menu tile region (27×12) to buffer.
SaveFullMenuTiles:
	LEA	Full_menu_tiles_buffer, A0
	MOVE.w	#2, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#$001A, Window_tile_width.w
	MOVE.w	#$000C, D0
	MOVE.w	D0, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveEquipmentListTiles
; Save the equipment list tile region to buffer.
SaveEquipmentListTiles:
	LEA	Equipment_list_tiles_buffer.w, A0
	MOVE.w	#$000F, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#$0016, Window_tile_width.w
	MOVE.w	#$0014, D0
	MOVE.w	D0, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveMagicListTiles
; Save the magic list tile region to buffer.
SaveMagicListTiles:
	LEA	Magic_list_tiles_buffer.w, A0
	MOVE.w	#2, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#$0011, Window_tile_width.w
	MOVE.w	#$0014, D0
	MOVE.w	D0, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveItemListRightTiles
; Save the right portion of the item list to buffer.
SaveItemListRightTiles:
	LEA	Item_list_right_tiles_buffer.w, A0
	MOVE.w	#$000F, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#$0016, Window_tile_width.w
	MOVE.w	#$0014, D0
	MOVE.w	D0, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveRingsListMenuToBuffer
; Save the rings list menu area to buffer.
SaveRingsListMenuToBuffer:
	LEA	Rings_list_tiles_buffer.w, A0
	MOVE.w	#9, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#$0011, Window_tile_width.w
	MOVE.w	#$0014, D0
	MOVE.w	D0, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveMessageSpeedMenuToBuffer
; Save the message speed menu area (large region) to buffer.
SaveMessageSpeedMenuToBuffer:
	LEA	Message_speed_menu_tiles_buffer, A0	
	MOVE.w	#$000A, Window_tile_x.w	
	MOVE.w	#$000A, Window_tile_y.w	
	MOVE.w	#$000E, Window_tile_width.w	
	MOVE.w	#$000A, Window_tile_height.w	
	BSR.w	ReadWindowToBuffer	
	RTS
	
	
; SaveMainMenuToBuffer
; Save the main menu tile region to buffer.
SaveMainMenuToBuffer:
	LEA	Small_menu_tiles_buffer, A0
	MOVE.w	#2, Window_tile_x.w
	MOVE.w	#$000C, Window_tile_y.w
	MOVE.w	#$000B, Window_tile_width.w
	MOVE.w	#8, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveRightMenuToBuffer
; Save the right menu tile region to buffer.
SaveRightMenuToBuffer:
	LEA	Right_menu_tiles_buffer, A0
	MOVE.w	#$000C, Window_tile_x.w
	MOVE.w	#4, Window_tile_y.w
	MOVE.w	#9, Window_tile_width.w
	MOVE.w	#8, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; SaveReadyEquipmentMenuToBuffer
; Save the ready equipment menu tiles to buffer.
SaveReadyEquipmentMenuToBuffer:
	LEA	Ready_equipment_menu_tiles_buffer, A0
	MOVE.w	#$000F, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#$0015, Window_tile_width.w
	MOVE.w	#$0012, Window_tile_height.w
	BSR.w	ReadWindowToBuffer
	RTS
	
; ---------------------------------------------------------------------------
; ReadWindowToBuffer — copy a rectangular tile region from VDP VRAM to RAM
;
; Called by ~20 thin Save* wrapper functions above, each of which loads a
; unique (buffer, x, y, w, h) combination before jumping here.
;
; DRY-006 NOTE: The wrappers cannot be merged into a single parameterized
; function without changing every BSR.w call offset, which would break
; bit-perfect output.  The established pattern in this project is to leave
; the wrappers in place and document the constraint here.  Each wrapper is
; already fully commented with its region dimensions.
;
; Input:   A0  = destination RAM buffer (word-per-tile, row-major)
;          Window_tile_x.w   = nametable X origin (tiles)
;          Window_tile_y.w   = nametable Y origin (tiles)
;          Window_tile_width.w  = region width  (tiles, inclusive)
;          Window_tile_height.w = region height (tiles, inclusive)
; Scratch: D0-D5, A0
; Output:  buffer filled; A0 advanced past last written word
; ---------------------------------------------------------------------------
ReadWindowToBuffer:
	JSR	GetScrollOffsetInTiles
	CLR.w	D3
ReadWindowToBuffer_Done:
	CLR.w	D2
ReadWindowToBuffer_Done2:
	BSR.w	CalculateVDPAddress
	ADDQ.l	#3, D5
	ORI	#$0700, SR
	MOVE.l	D5, VDP_control_port
	MOVE.w	VDP_data_port, (A0)+
	ANDI	#$F8FF, SR
	ADDQ.w	#1, D2
	CMP.w	Window_tile_width.w, D2
	BLE.b	ReadWindowToBuffer_Done2
	ADDQ.w	#1, D3
	CMP.w	Window_tile_height.w, D3
	BLE.b	ReadWindowToBuffer_Done
	RTS
	
; ---------------------------------------------------------------------------
; DrawStatusHudWindow — restore the status-bar VRAM region from RAM buffer
;
; Writes Script_window_tiles_buffer back to the 31×8 nametable region at
; (4, 19).  If Dialog_active_flag is set, also sets bit 7 of
; obj_sprite_flags on Current_actor_ptr (re-shows its sprite).  If
; Player_in_first_person_mode is set, also calls
; DisplayPlayerKimsAndExperience to refresh the kims/XP overlay.
;
; Input:   (all state via RAM)
; Scratch:  A0, A6, D0
; Output:   VDP nametable updated from Script_window_tiles_buffer
; ---------------------------------------------------------------------------
; DrawStatusHudWindow
; Draw main status HUD window (bottom bar showing HP, level, etc.)
DrawStatusHudWindow:
	TST.b	Dialog_active_flag.w
	BEQ.b	DrawStatusHudWindow_Loop
	MOVEA.l	Current_actor_ptr.w, A6
	BSET.b	#7, obj_sprite_flags(A6)
DrawStatusHudWindow_Loop:
	LEA	Script_window_tiles_buffer, A0
	MOVE.w	#4, Window_tile_x.w
	MOVE.w	#$0013, Window_tile_y.w
	MOVE.w	#$001F, Window_tile_width.w
	MOVE.w	#8, Window_tile_height.w
	BSR.w	DrawWindowFromBuffer
	TST.b	Player_in_first_person_mode.w
	BEQ.b	DrawStatusHudWindow_Loop2
	BSR.w	DisplayPlayerKimsAndExperience
DrawStatusHudWindow_Loop2:
	RTS
	
; DrawPromptMenuWindow
; Draw the text prompt menu window from its tile buffer.
DrawPromptMenuWindow:
	LEA	Prompt_menu_tiles_buffer.w, A0
	MOVE.w	#5, Window_tile_x.w
	MOVE.w	#4, Window_tile_y.w
	MOVE.w	#$000B, Window_tile_width.w
	MOVE.w	#2, Window_tile_height.w
	BSR.w	DrawWindowFromBuffer
	RTS
	
; ---------------------------------------------------------------------------
; DrawLeftMenuWindow — blit Small_menu_tiles_buffer to the right-side panel
;
; Writes a 6×6 tile block at nametable position ($1C, $0D) from
; Small_menu_tiles_buffer.  Despite the name the physical position is on
; the right side of the screen (column 28).
;
; Input:   (all state via RAM)
; Scratch:  A0, D0-D3
; Output:   VDP nametable updated
; ---------------------------------------------------------------------------
; DrawLeftMenuWindow
; Draw left menu window (buffer at $FFFF7CF4, 28x13 at position 6,6)
DrawLeftMenuWindow:
	LEA	Small_menu_tiles_buffer, A0
	MOVE.w	#$001C, Window_tile_x.w
	MOVE.w	#$000D, Window_tile_y.w
	MOVE.w	#6, Window_tile_width.w
	MOVE.w	#6, Window_tile_height.w
	BSR.w	DrawWindowFromBuffer
	RTS
	
; RestoreShopSubmenuFromBuffer
; Restore the shop submenu area from its tile buffer.
RestoreShopSubmenuFromBuffer:
	LEA	Shop_submenu_tiles_buffer.w, A0
	MOVE.w	#$000F, Window_tile_x.w
	MOVE.w	#$000C, Window_tile_y.w
	MOVE.w	#$0015, Window_tile_width.w
	MOVE.w	#7, Window_tile_height.w
	BSR.w	DrawWindowFromBuffer
	RTS
	
; ---------------------------------------------------------------------------
; DrawCenterMenuWindow — blit Large_menu_tiles_buffer to the center panel
;
; Writes a 21×21 tile block at nametable position ($0F, 2) from
; Large_menu_tiles_buffer.  Used for inventory, equipment, status, and
; shop item-list windows.
;
; Input:   (all state via RAM)
; Scratch:  A0, D0-D3
; Output:   VDP nametable updated
; ---------------------------------------------------------------------------
; DrawCenterMenuWindow
; Draw center menu window (buffer at $FFFF7E52, 21x21 at position 15,2)
DrawCenterMenuWindow:
	LEA	Large_menu_tiles_buffer, A0
	MOVE.w	#$000F, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#$0015, Window_tile_width.w
	MOVE.w	#$0015, Window_tile_height.w
	BSR.w	DrawWindowFromBuffer
	RTS
	
; RestoreShopListFromBuffer
; Restore the shop item list area from its tile buffer.
RestoreShopListFromBuffer:
	LEA	Shop_list_tiles_buffer.w, A0
	MOVE.w	#$000A, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#$0018, Window_tile_width.w
	MOVE.w	#$0011, Window_tile_height.w
	BSR.w	DrawWindowFromBuffer
	RTS
	
; DrawStatusMenuWindow
; Draw the status menu window from its tile buffer.
DrawStatusMenuWindow:
	LEA	Status_menu_tiles_buffer.w, A0
	MOVE.w	#$000A, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#$0016, Window_tile_width.w
	MOVE.w	#$0010, Window_tile_height.w
	BSR.w	DrawWindowFromBuffer
	RTS
	
; RestoreRightMenuFromBuffer
; Restore the right menu area from its tile buffer.
RestoreRightMenuFromBuffer:
	LEA	Right_menu_tiles_buffer, A0
	MOVE.w	#$000C, Window_tile_x.w
	MOVE.w	#4, Window_tile_y.w
	MOVE.w	#9, Window_tile_width.w
	MOVE.w	#8, Window_tile_height.w
	BSR.w	DrawWindowFromBuffer
	RTS
	
; RestoreReadyEquipmentMenuFromBuffer
; Restore the ready equipment menu from its tile buffer.
RestoreReadyEquipmentMenuFromBuffer:
	LEA	Ready_equipment_menu_tiles_buffer, A0
	MOVE.w	#$000F, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#$0015, Window_tile_width.w
	MOVE.w	#$0012, Window_tile_height.w
	BSR.w	DrawWindowFromBuffer
	RTS
	
; RestoreLeftMenuFromBuffer
; Restore the left menu area from its tile buffer.
RestoreLeftMenuFromBuffer:
	LEA	Left_menu_tiles_buffer.w, A0
	MOVE.w	#0, Window_tile_x.w
	MOVE.w	#2, Window_tile_y.w
	MOVE.w	#9, Window_tile_width.w
	MOVE.w	#6, Window_tile_height.w
	BSR.w	DrawWindowFromBuffer
	RTS
	
; ---------------------------------------------------------------------------
; DrawWindowFromBuffer — write a rectangular tile region from RAM back to VDP
;
; Called by ~10 thin Restore*/Draw* wrapper functions above, each of which
; loads a unique (buffer, x, y, w, h) combination before jumping here.
;
; DRY-006 NOTE: Same bit-perfect constraint as ReadWindowToBuffer — see that
; function's header for the full explanation.  Wrappers are intentionally
; left as-is; each is individually commented.
;
; Input:   A0  = source RAM buffer (word-per-tile, row-major)
;          Window_tile_x.w   = nametable X origin (tiles)
;          Window_tile_y.w   = nametable Y origin (tiles)
;          Window_tile_width.w  = region width  (tiles, inclusive)
;          Window_tile_height.w = region height (tiles, inclusive)
; Scratch: D0-D5, A0
; Output:  VDP nametable updated; A0 advanced past last read word
; ---------------------------------------------------------------------------
DrawWindowFromBuffer:
	JSR	GetScrollOffsetInTiles
	CLR.w	D3
DrawWindowFromBuffer_Done:
	CLR.w	D2
DrawWindowFromBuffer_Done2:
	BSR.w	CalculateVDPAddress
	ADDI.l	#$40000003, D5
	ORI	#$0700, SR
	MOVE.l	D5, VDP_control_port
	MOVE.w	(A0)+, VDP_data_port
	ANDI	#$F8FF, SR
	ADDQ.w	#1, D2
	CMP.w	Window_tile_width.w, D2
	BLE.b	DrawWindowFromBuffer_Done2
	ADDQ.w	#1, D3
	CMP.w	Window_tile_height.w, D3
	BLE.b	DrawWindowFromBuffer_Done
	RTS
	
; CalculateVDPAddress
; Calculate a VDP VRAM address for a given tile coordinate.
; Inputs: D2 = col offset, D3 = row offset, D0 = scroll X, D1 = scroll Y. Outputs: D5 = VDP address (swapped).
CalculateVDPAddress:
	MOVE.w	D2, D4
	MOVE.w	D3, D5
	ADD.w	D0, D4
	ADD.w	D1, D5
	ADD.w	Window_tile_x.w, D4
	ADD.w	Window_tile_y.w, D5
	ANDI.w	#$003F, D4
	ANDI.w	#$003F, D5
	ASL.w	#1, D4
	ASL.w	#7, D5
	ADD.w	D4, D5
	ANDI.l	#$0000FFFF, D5
	SWAP	D5
	RTS
	
;==============================================================
; MENU INPUT HANDLING
;==============================================================

; ---------------------------------------------------------------------------
; HandleMenuInput — read D-pad and move the menu cursor one step
;
; Compares Controller_current_state with Controller_previous_state to detect
; a freshly-pressed directional button, then calls the appropriate
; MenuCursorUp/Down/Left/Right handler.  If no direction is newly pressed,
; falls through to BlinkMenuCursor to toggle cursor visibility on a timer.
;
; Called every game tick while a menu is open.
;
; Input:   (all state via RAM)
;   Controller_current_state.w  — current joypad byte
;   Controller_previous_state.w — joypad byte from previous tick
;
; Scratch:  D2, D3
; Output:   Menu_cursor_index.w updated; cursor tile written to VDP
; ---------------------------------------------------------------------------
; HandleMenuInput
; Main menu input handler - processes D-pad input for cursor movement
HandleMenuInput:
	MOVE.b	Controller_current_state.w, D2
	MOVE.b	Controller_previous_state.w, D3
	EOR.b	D2, D3
	BEQ.w	BlinkMenuCursor
	ANDI.w	#$000F, D2
	BEQ.w	BlinkMenuCursor
	PlaySound	SOUND_HIT
	BTST.l	#0, D3
	BEQ.b	MenuCursor_CheckUp
	BTST.l	#0, D2
	BEQ.b	MenuCursor_CheckUp
	BRA.w	MenuCursorUp
MenuCursor_CheckUp:
	BTST.l	#1, D3
	BEQ.b	MenuCursor_CheckDown
	BTST.l	#1, D2
	BEQ.b	MenuCursor_CheckDown
	BRA.w	MenuCursorDown
MenuCursor_CheckDown:
	BTST.l	#2, D3
	BEQ.b	MenuCursor_CheckLeft
	BTST.l	#2, D2
	BEQ.b	MenuCursor_CheckLeft
	BRA.w	MenuCursorLeft
MenuCursor_CheckLeft:
	BTST.l	#3, D3
	BEQ.b	BlinkMenuCursor
	BTST.l	#3, D2
	BEQ.b	BlinkMenuCursor
	BRA.w	MenuCursorRight
; BlinkMenuCursor
; Toggle the menu cursor visibility on a timer, then draw or erase it.
BlinkMenuCursor:
	ADDQ.w	#1, Cursor_blink_timer.w
	MOVE.w	Cursor_blink_timer.w, D0
	MOVE.w	D0, D1
	SUBQ.w	#1, D1
	EOR.w	D1, D0
	BTST.l	#2, D0
	BEQ.b	BlinkMenuCursor_Loop
	BTST.l	#2, D1
	BEQ.w	DrawMenuCursor
	BRA.w	EraseMenuCursor
BlinkMenuCursor_Loop:
	RTS
	
; Handle UP button - move cursor up in menu
MenuCursorUp:
	MOVE.w	Menu_cursor_index.w, D0
	BLE.b	MenuCursorUp_Return
	SUB.w	Menu_cursor_column_break.w, D0
	SUBQ.w	#1, D0
	BEQ.b	MenuCursorUp_Return
	BSR.w	EraseMenuCursor
	SUBQ.w	#1, Menu_cursor_index.w
	BSR.w	DrawMenuCursor
MenuCursorUp_Return:
	RTS
	
; Handle DOWN button - move cursor down in menu
MenuCursorDown:
	MOVE.w	Menu_cursor_index.w, D0
	CMP.w	Menu_cursor_column_break.w, D0
	BEQ.b	MenuCursorDown_Return
	CMP.w	Menu_cursor_last_index.w, D0
	BEQ.b	MenuCursorDown_Return
	BSR.w	EraseMenuCursor
	ADDQ.w	#1, Menu_cursor_index.w
	BSR.w	DrawMenuCursor
MenuCursorDown_Return:
	RTS
	
; Handle LEFT button - move cursor to left column
MenuCursorLeft:
	MOVE.w	Menu_cursor_index.w, D0
	CMP.w	Menu_cursor_column_break.w, D0
	BLE.b	MenuCursorLeft_Loop
	BSR.w	EraseMenuCursor
	MOVE.w	Menu_cursor_column_break.w, D0
	ADDQ.w	#1, D0
	SUB.w	D0, Menu_cursor_index.w
	BSR.w	DrawMenuCursor
MenuCursorLeft_Loop:
	RTS
	
; Handle RIGHT button - move cursor to right column
MenuCursorRight:
	MOVE.w	Menu_cursor_index.w, D0
	CMP.w	Menu_cursor_column_break.w, D0
	BGT.b	MenuCursorRight_Return
	ADD.w	Menu_cursor_column_break.w, D0
	ADDQ.w	#1, D0
	CMP.w	Menu_cursor_last_index.w, D0
	BGT.b	MenuCursorRight_Return
	BSR.w	EraseMenuCursor
	MOVE.w	Menu_cursor_column_break.w, D0
	ADDQ.w	#1, D0
	ADD.w	D0, Menu_cursor_index.w
	BSR.w	DrawMenuCursor
MenuCursorRight_Return:
	RTS
	
; ---------------------------------------------------------------------------
; MenuCursorRight_DeadCode — unreachable cursor-restore sequence
;
; DEAD CODE: No call sites exist.  This appears to be a fragment of a
; "move cursor right" handler that was never wired into the menu dispatch
; table.  It restores the cursor to Menu_cursor_last_index and redraws it,
; which would undo a right-move.  Superseded by the live HandleMenuInput
; cursor logic.  Cannot be removed without breaking bit-perfect output.
; ---------------------------------------------------------------------------
MenuCursorRight_DeadCode:					; unreferenced dead code
	BSR.w	EraseMenuCursor
	MOVE.w	Menu_cursor_last_index.w, Menu_cursor_index.w
	BSR.w	DrawMenuCursor
	RTS
; EraseMenuCursor
; Erase the menu cursor tile from VRAM (write blank tile).
EraseMenuCursor:
	MOVE.w	#$84E0, D6
	OR.w	Window_tile_attrs.w, D6
	BSR.w	WriteMenuCursorTile
	RTS
	
; ---------------------------------------------------------------------------
; DrawMenuCursor — write the cursor tile to VRAM at the current position
;
; Sets D6 to tile $84DC (cursor glyph) OR'd with Window_tile_attrs, then
; calls WriteMenuCursorTile.  The tile is written to the nametable cell
; computed from Menu_cursor_index and the menu base coordinates.
;
; Input:   (all state via RAM)
;   Menu_cursor_index.w        — current cursor row (0-based)
;   Menu_cursor_column_break.w — row at which a second column starts
;   Menu_cursor_base_x/y.w     — nametable origin of the menu
;   Window_tile_attrs.w        — palette/priority bits OR'd into tile word
;
; Scratch:  D0-D4, D6
; Output:   cursor tile written to VDP nametable
; ---------------------------------------------------------------------------
; DrawMenuCursor
; Draw the menu cursor tile to VRAM at the current cursor position.
DrawMenuCursor:
	MOVE.w	#$84DC, D6
	OR.w	Window_tile_attrs.w, D6
	BSR.w	WriteMenuCursorTile
	RTS
	
; WriteMenuCursorTile
; Writes menu cursor tile to VRAM at calculated position
; Input: D6 = Tile ID with attributes
WriteMenuCursorTile:
	CLR.w	D2
	MOVE.w	Menu_cursor_index.w, D3
	CMP.w	Menu_cursor_column_break.w, D3
	BLE.b	WriteMenuCursorTile_Loop
	MOVE.w	Menu_cursor_second_column_x.w, D2
	SUB.w	Menu_cursor_column_break.w, D3
	SUBQ.w	#1, D3
WriteMenuCursorTile_Loop:
	JSR	GetScrollOffsetInTiles
	ADD.w	Menu_cursor_base_x.w, D0
	ADD.w	Menu_cursor_base_y.w, D1
	ASL.w	#1, D3
	ADD.w	D2, D0
	ADD.w	D3, D1
	ANDI.w	#$003F, D0
	ANDI.w	#$003F, D1
	ASL.w	#1, D0
	ASL.w	#7, D1
	ADD.w	D1, D0
	ANDI.l	#$0000FFFF, D0
	SWAP	D0
	ORI.l	#$40000003, D0
	ORI	#$0700, SR
	MOVE.l	D0, VDP_control_port
	MOVE.w	D6, VDP_data_port
	ANDI	#$F8FF, SR
	RTS
	
; ---------------------------------------------------------------------------
; DrawShopWindow_DeadCode — unreachable shop window draw call
;
; DEAD CODE: No call sites exist.  Appears to be an early version of the
; shop UI setup that renders items to a hard-coded window position ($D, $4).
; The live code path builds the shop window via script commands instead.
; Cannot be removed without breaking bit-perfect output.
; ---------------------------------------------------------------------------
DrawShopWindow_DeadCode:					; unreferenced dead code
	MOVE.w	#$000D, Window_tilemap_draw_x.w
	MOVE.w	#$0004, Window_tilemap_draw_y.w
	LEA	Shop_item_list.w, A2
	LEA	ShopCategoryNameTables, A1
	MOVE.w	Current_shop_type.w, D0
	ASL.w	#3, D0
	MOVEA.l	$0(A1,D0.w), A1
	MOVE.w	Shop_item_count.w, D7
	BSR.w	DrawShopItemNames
	RTS
;==============================================================
; SHOP / ITEM LIST DRAWING
;==============================================================

; DrawShopItemNames
; Draw item names in the shop purchase or sell list. Inputs: A1 = item name pointer table, D7 = item count.
DrawShopItemNames:
	SUBQ.w	#1, D7
DrawShopItemNames_Alt:
	CLR.w	D3
DrawShopItemNames_Done:
	MOVE.w	(A2)+, D4
	ANDI.w	#$00FF, D4
	ADD.w	D4, D4
	ADD.w	D4, D4
	MOVEA.l	$0(A1,D4.w), A0
	CLR.w	D2
; DrawWindowChar_WriteVDP
; Write a character tile to the window plane via VDP, advancing the column counter.
DrawWindowChar_WriteVDP:
	JSR	GetScrollOffsetInTiles
	ADD.w	D2, D0
	ADD.w	D3, D1
	ADD.w	Window_tilemap_draw_x.w, D0
	ADD.w	Window_tilemap_draw_y.w, D1
	ANDI.w	#$003F, D0
	ANDI.w	#$003F, D1
	ASL.w	#1, D0
	ASL.w	#7, D1
	ADD.w	D1, D0
	ANDI.l	#$0000FFFF, D0
	SWAP	D0
	ADDI.l	#$40000003, D0
	MOVE.l	D0, VDP_control_port
	CLR.w	D6
	MOVE.b	(A0)+, D6
	CMPI.b	#SCRIPT_END, D6
	BEQ.b	DrawWindowChar_WriteVDP_Loop
	CMPI.b	#SCRIPT_WIDE_CHAR_LO, D6
	BEQ.b	DrawWindowChar_Special
	CMPI.b	#SCRIPT_WIDE_CHAR_HI, D6
	BEQ.b	DrawWindowChar_Special
	ADDI.w	#$4C0, D6
	ORI.w	#$8000, D6
	ORI.w	#$0000, D6
	MOVE.w	D6, VDP_data_port
	ADDQ.w	#1, D2
	BRA.b	DrawWindowChar_WriteVDP
DrawWindowChar_WriteVDP_Loop:
	ADDQ.w	#2, D3
	CMP.w	Window_tilemap_draw_height.w, D3
	DBF	D7, DrawShopItemNames_Done
	RTS
; DrawWindowChar_Special
; Handle special character codes (e.g. price display) during shop list rendering.
DrawWindowChar_Special:
	BSR.w	DrawSpecialCharToVRAM
	BRA.b	DrawWindowChar_WriteVDP
; ---------------------------------------------------------------------------
; DrawWindowChar_DeadCode — unreachable shop price list renderer
;
; DEAD CODE: No call sites exist.  Renders a column of shop prices by
; iterating ShopPricesByTownAndType for Current_town/Current_shop_type.
; The live code draws prices via the script dialogue system instead.
; Cannot be removed without breaking bit-perfect output.
; ---------------------------------------------------------------------------
DrawWindowChar_DeadCode:					; unreferenced dead code
	MOVE.w	#$0012, Window_number_cursor_x.w
	MOVE.w	#$0002, Window_number_cursor_y.w
	LEA	ShopPricesByTownAndType, A1
	MOVE.w	Current_town.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	ADD.w	Current_shop_type.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	$0(A1,D0.w), A1
	MOVE.w	Shop_item_count.w, D5
	SUBQ.w	#1, D5
	MOVE.w	#$0000, D3
DrawWindowChar_Special_Done:
	MOVE.l	(A1)+, D2
	BSR.w	LongToDecimalString
	MOVE.w	#$0012, Window_number_cursor_x.w
	ADDQ.w	#2, Window_number_cursor_y.w
	DBF	D5, DrawWindowChar_Special_Done
	RTS
; CopyStringUntilFF
; Copy string from A0 to A1 until $FF terminator
; Input: A0 = Source string pointer, A1 = Destination pointer
; Output: A0, A1 advanced past copied data
CopyStringUntilFF:
	MOVE.b	(A0), D0
	CMPI.b	#SCRIPT_END, D0
	BEQ.b	CopyStringUntilFF_Loop
	MOVE.b	(A0)+, (A1)+
	BRA.b	CopyStringUntilFF
CopyStringUntilFF_Loop:
	RTS
	
; DrawItemListNames
; Draw item names in the inventory item list.
DrawItemListNames:
	MOVE.w	#$0011, Window_tilemap_draw_x.w
	MOVE.w	#4, Window_tilemap_draw_y.w
	LEA	Possessed_items_list.w, A2
	LEA	ItemNames, A1
	MOVE.w	Possessed_items_length.w, D7
	BSR.w	DrawListItems
	RTS
	
; DrawMagicListWithMP
; Draw magic spell names alongside their MP costs in the magic list.
DrawMagicListWithMP:
	MOVE.w	#$0011, Window_tilemap_draw_x.w
	MOVE.w	#4, Window_tilemap_draw_y.w
	LEA	Possessed_magics_list.w, A2
	LEA	MagicNames, A1
	MOVE.w	Possessed_magics_length.w, D7
	BSR.w	DrawListItems
	MOVE.w	#$0021, Window_tilemap_draw_x.w
	MOVE.w	#4, Window_tilemap_draw_y.w
	LEA	Possessed_magics_list.w, A2
	MOVE.w	Possessed_magics_length.w, D7
	BSR.w	DrawInventorySelectionMarkers
	RTS
	
; DrawPossessedEquipmentList
; Draw the list of possessed equipment items in the equipment list window.
DrawPossessedEquipmentList:
	MOVE.w	#$0011, Window_tilemap_draw_x.w
	MOVE.w	#4, Window_tilemap_draw_y.w
	LEA	Possessed_equipment_list.w, A2
	LEA	EquipmentNames, A1
	MOVE.w	Possessed_equipment_length.w, D7
	BSR.w	DrawListItems
	MOVE.w	#$0023, Window_tilemap_draw_x.w
	MOVE.w	#4, Window_tilemap_draw_y.w
	LEA	Possessed_equipment_list.w, A2
	MOVE.w	Possessed_equipment_length.w, D7
	BSR.w	DrawInventorySelectionMarkers
	RTS
	
; DrawReadyEquipmentList
; Draw the list of items that are readied/equipped in the ready equipment window.
DrawReadyEquipmentList:
	MOVE.w	Ready_equipment_list_length.w, D7
	MOVE.w	D7, D0
	SUBQ.w	#1, D0
	MOVE.w	D0, Menu_cursor_column_break.w
	MOVE.w	#MENU_CURSOR_NONE, Menu_cursor_last_index.w
	MOVE.w	#$0010, Menu_cursor_base_x.w
	MOVE.w	#4, Menu_cursor_base_y.w
	MOVE.w	#$0011, Window_tilemap_draw_x.w
	MOVE.w	#4, Window_tilemap_draw_y.w
	LEA	Ready_equipment_list.w, A2
	LEA	EquipmentNames, A1
	BSR.w	DrawListItems
	MOVE.w	Ready_equipment_list_length.w, D7
	MOVE.w	#$0023, Window_tilemap_draw_x.w
	MOVE.w	#4, Window_tilemap_draw_y.w
	LEA	Ready_equipment_list.w, A2
	BSR.w	DrawInventorySelectionMarkers
	RTS
	
; DrawListItems
; Core routine: draw a list of items to the window, one per row.
; Inputs: A1 = name pointer table, A2 = item ID list, D7 = item count
DrawListItems:
	SUBQ.w	#1, D7
	CLR.w	D3
DrawListItems_Done:
	MOVE.w	(A2)+, D4
	ANDI.w	#$00FF, D4
	ADD.w	D4, D4
	ADD.w	D4, D4
	MOVEA.l	(A1,D4.w), A0
	CLR.w	D2
; DrawWindowChar2_WriteVDP
; Alternate window character writer: write a character tile to VDP for item list rendering.
DrawWindowChar2_WriteVDP:
	JSR	GetScrollOffsetInTiles
	ADD.w	D2, D0
	ADD.w	D3, D1
	ADD.w	Window_tilemap_draw_x.w, D0
	ADD.w	Window_tilemap_draw_y.w, D1
	ANDI.w	#$003F, D0
	ANDI.w	#$003F, D1
	ASL.w	#1, D0
	ASL.w	#7, D1
	ADD.w	D1, D0
	ANDI.l	#$0000FFFF, D0
	SWAP	D0
	ADDI.l	#$40000003, D0
	CLR.w	D6
	MOVE.b	(A0)+, D6
	CMPI.b	#SCRIPT_END, D6
	BEQ.b	DrawWindowChar2_WriteVDP_Loop
	CMPI.b	#SCRIPT_WIDE_CHAR_LO, D6
	BEQ.b	DrawWindowChar2_Special
	CMPI.b	#SCRIPT_WIDE_CHAR_HI, D6
	BEQ.b	DrawWindowChar2_Special
	ADDI.w	#$04C0, D6
	ORI.w	#$8000, D6
	ORI.w	#0, D6
	ORI	#$0700, SR
	MOVE.l	D0, VDP_control_port
	MOVE.w	D6, VDP_data_port
	ANDI	#$F8FF, SR
	ADDQ.w	#1, D2
	BRA.b	DrawWindowChar2_WriteVDP
DrawWindowChar2_WriteVDP_Loop:
	ADDQ.w	#2, D3
	DBF	D7, DrawListItems_Done
	RTS
	
; DrawWindowChar2_Special
; Handle special character codes in the alternate window character writer.
DrawWindowChar2_Special:
	BSR.w	DrawSpecialCharToVRAM	
	BRA.b	DrawWindowChar2_WriteVDP	
; DrawSpecialCharToVRAM
; Write a special/extended character tile directly to VRAM. Inputs: D6 = tile index, D3 = row offset.
DrawSpecialCharToVRAM:
	ADDI.w	#$04C0, D6	
	ORI.w	#$8000, D6	
	ORI.w	#0, D6	
	JSR	GetScrollOffsetInTiles	
	MOVE.w	D2, D4	
	MOVE.w	D3, D5	
	ADD.w	D0, D4	
	ADD.w	D1, D5	
	ADD.w	Window_tilemap_draw_x.w, D4	
	ADD.w	Window_tilemap_draw_y.w, D5	
	SUBQ.w	#1, D4	
	SUBQ.w	#1, D5	
	ANDI.w	#$003F, D4	
	ANDI.w	#$003F, D5	
	ASL.w	#1, D4	
	ASL.w	#7, D5	
	ADD.w	D4, D5	
	ANDI.l	#$0000FFFF, D5	
	SWAP	D5	
	ADDI.l	#$40000003, D5	
	ORI	#$0700, SR	
	MOVE.l	D5, VDP_control_port	
	MOVE.w	D6, VDP_data_port	
	ANDI	#$F8FF, SR	
	RTS
	
; DrawInventorySelectionMarkers
; Draw selection marker tiles next to selected inventory items in the list. Inputs: A2 = item list, D7 = count.
DrawInventorySelectionMarkers:
	SUBQ.w	#1, D7
	CLR.w	D3
DrawInventorySelectionMarkers_Done:
	MOVE.w	(A2)+, D4
	ANDI.w	#$8000, D4
	BEQ.w	DrawInventorySelectionMarkers_Loop
	CLR.w	D2
	JSR	GetScrollOffsetInTiles
	ADD.w	D2, D0
	ADD.w	D3, D1
	ADD.w	Window_tilemap_draw_x.w, D0
	ADD.w	Window_tilemap_draw_y.w, D1
	ANDI.w	#$003F, D0
	ANDI.w	#$003F, D1
	ASL.w	#1, D0
	ASL.w	#7, D1
	ADD.w	D1, D0
	ANDI.l	#$0000FFFF, D0
	SWAP	D0
	ADDI.l	#$40000003, D0
	MOVE.w	#$84EA, D6
	ORI.w	#0, D6
	MOVE.l	D0, VDP_control_port
	MOVE.w	D6, VDP_data_port
	ADDQ.w	#1, D2
DrawInventorySelectionMarkers_Loop:
	ADDQ.w	#2, D3
	DBF	D7, DrawInventorySelectionMarkers_Done
	RTS

;==============================================================
; WINDOW BORDER / TEXT
;==============================================================

; ---------------------------------------------------------------------------
; DrawWindowBorder — fill Window_tilemap_buffer with border tile bytes
;
; Iterates over a (Window_width+1) × (Window_height+1) grid and writes a
; border-tile index byte for each cell into Window_tilemap_buffer.  Tile
; indices start at SOUND_LEVEL_UP ($B0) and are adjusted +1 for right/left
; edges and +3 for bottom/top rows, producing a 9-tile corner+edge set.
;
; The filled buffer is later transferred to VDP VRAM by the window-draw DMA
; routine triggered when Window_tilemap_draw_pending/active is set.
;
; Input:   (all state via RAM)
;   Window_width.w   — inner width in tiles (border adds 1 column each side)
;   Window_height.w  — inner height in tiles (border adds 1 row each side)
;
; Scratch:  D0-D2, D6, D7, A0
; Output:   Window_tilemap_buffer filled
; ---------------------------------------------------------------------------
; DrawWindowBorder
; Draw window border/frame tiles
; Fills window tilemap buffer with border tiles (corners, edges)
; Uses tile $E0 + offsets for different border parts
DrawWindowBorder:
	LEA	Window_tilemap_buffer.w, A0
	MOVE.w	Window_height.w, D7
	CLR.w	D1
DrawWindowBorder_Done:
	MOVE.w	Window_width.w, D6
	CLR.w	D0
DrawWindowBorder_Done2:
	MOVE.b	#SOUND_LEVEL_UP, D2
	TST.w	D1
	BEQ.b	DrawWindowBorder_Loop
	CMP.w	Window_height.w, D1
	BNE.b	DrawWindowBorder_Loop2
	ADDQ.b	#3, D2
DrawWindowBorder_Loop2:
	ADDQ.b	#3, D2
DrawWindowBorder_Loop:
	TST.w	D0
	BEQ.b	DrawWindowBorder_Loop3
	CMP.w	Window_width.w, D0
	BNE.b	DrawWindowBorder_Loop4
	ADDQ.b	#1, D2
DrawWindowBorder_Loop4:
	ADDQ.b	#1, D2
DrawWindowBorder_Loop3:
	MOVE.b	D2, (A0)+
	ADDQ.w	#1, D0
	DBF	D6, DrawWindowBorder_Done2
	ADDQ.w	#1, D1
	DBF	D7, DrawWindowBorder_Done
	RTS

; RenderTextToWindowAtPosition
; Render text from Window_text_scratch to the window at a packed (x<<5|y) position. Inputs: D0 = packed position.
RenderTextToWindowAtPosition:
	LEA	Window_text_scratch.w, A0
	BRA.w	RenderTextAtOffset
; RenderFormattedTextToWindow
; Render formatted text from Window_text_scratch to the current window position.
RenderFormattedTextToWindow:
	LEA	Window_text_scratch.w, A0
; RenderTextToWindow
; Render text string to window tilemap buffer
; Input: A0 = Text string pointer
; Processes text codes: $FF=end, $FE=newline, $20→$E4, etc.
RenderTextToWindow:
	MOVE.w	Window_width.w, D0
	ADDQ.w	#1, D0
	MOVE.w	Window_text_y.w, D1
	MULU.w	D1, D0
	ADD.w	Window_text_x.w, D0
; RenderTextAtOffset
; Render text string to the window tilemap buffer at a given tile offset. Inputs: A0 = text, D0 = tile offset.
RenderTextAtOffset:
	LEA	Window_tilemap_buffer.w, A1
	LEA	(A1,D0.w), A1
RenderTextAtOffset_Done:
	LEA	(A1), A2
WindowTextDecode_Next:
	CLR.w	D6
	MOVE.b	(A0)+, D6
	CMPI.b	#SCRIPT_END, D6
	BEQ.w	WindowTextDecode_Special_Loop
	CMPI.b	#SCRIPT_NEWLINE, D6
	BEQ.w	WindowTextDecode_Next_Loop
	CMPI.b	#SCRIPT_WIDE_CHAR_LO, D6
	BEQ.b	WindowTextDecode_Special
	CMPI.b	#SCRIPT_WIDE_CHAR_HI, D6
	BEQ.b	WindowTextDecode_Special
	CMPI.b	#$20, D6
	BNE.b	WindowTextDecode_Next_Loop2
	MOVE.b	#$E4, D6
WindowTextDecode_Next_Loop2:
	MOVE.b	D6, (A2)+
	BRA.b	WindowTextDecode_Next
WindowTextDecode_Next_Loop:
	MOVE.w	Window_width.w, D0
	ADDQ.w	#1, D0
	ADD.w	D0, D0
	LEA	(A1,D0.w), A1
	BRA.b	RenderTextAtOffset_Done
; WindowTextDecode_Special
; Handle special (wide/double-width) character codes during window text decoding.
WindowTextDecode_Special:
	MOVE.w	Window_width.w, D0	
	ADDQ.w	#1, D0	
	NEG.w	D0	
	MOVE.b	D6, -$1(A2,D0.w)	
	BRA.b	WindowTextDecode_Next	
WindowTextDecode_Special_Loop:
	RTS
	
; DrawWindowTilemapFull
; Write the entire window tilemap buffer to VRAM (all rows and columns).
DrawWindowTilemapFull:
	LEA	Window_tilemap_buffer.w, A0
	JSR	GetScrollOffsetInTiles
	CLR.w	D3
DrawWindowTilemapFull_Done:
	CLR.w	D2
DrawWindowTilemapFull_Done2:
	MOVE.w	D2, D4
	MOVE.w	D3, D5
	ADD.w	D0, D4
	ADD.w	D1, D5
	ADD.w	Window_tilemap_x.w, D4
	ADD.w	Window_tilemap_y.w, D5
	ANDI.w	#$003F, D4
	ANDI.w	#$003F, D5
	ASL.w	#1, D4
	ASL.w	#7, D5
	ADD.w	D4, D5
	ANDI.l	#$0000FFFF, D5
	SWAP	D5
	ADDI.l	#$40000003, D5
	MOVE.l	D5, VDP_control_port
	CLR.w	D4
	MOVE.b	(A0)+, D4
	ADDI.w	#$04C0, D4
	ORI.w	#$8000, D4
	OR.w	Window_tile_attrs.w, D4
	MOVE.w	D4, VDP_data_port
	ADDQ.w	#1, D2
	CMP.w	Window_width.w, D2
	BLE.b	DrawWindowTilemapFull_Done2
	ADDQ.w	#1, D3
	CMP.w	Window_height.w, D3
	BLE.b	DrawWindowTilemapFull_Done
	CLR.b	Window_tilemap_draw_pending.w
	RTS

; DrawWindowTilemapRow
; Write one row of the window tilemap buffer to VRAM, incrementing Window_draw_row each call.
DrawWindowTilemapRow:
	LEA	Window_tilemap_buffer.w, A0
	MOVE.w	Window_width.w, D2
	MOVE.w	Window_draw_row.w, D0
	CMP.w	Window_height.w, D0
	BGE.w	DrawWindowTilemapRow_Loop
	ADDQ.w	#1, D2
	MULU.w	D2, D0
	LEA	(A0,D0.w), A0
	JSR	GetScrollOffsetInTiles
	ADD.w	Window_tilemap_y.w, D1
	ADD.w	Window_draw_row.w, D1
	ANDI.w	#$003F, D1
	ASL.w	#7, D1
	BSR.w	WriteWindowRowToVDP
	LEA	Window_tilemap_buffer.w, A0
	MOVE.w	Window_width.w, D2
	MOVE.w	Window_height.w, D0
	ADDQ.w	#1, D2
	MULU.w	D2, D0
	LEA	(A0,D0.w), A0
	JSR	GetScrollOffsetInTiles
	ADD.w	Window_tilemap_y.w, D1
	ADD.w	Window_draw_row.w, D1
	ADDQ.w	#1, D1
	ANDI.w	#$003F, D1
	ASL.w	#7, D1
	BSR.w	WriteWindowRowToVDP
	ADDQ.w	#1, Window_draw_row.w
	RTS

DrawWindowTilemapRow_Loop:
	CLR.b	Window_tilemap_draw_active.w
	RTS

; WriteWindowRowToVDP
; Low-level: write a single row of tile data from buffer to VDP VRAM.
WriteWindowRowToVDP:
	CLR.w	D2
WriteWindowRowToVDP_Done:
	MOVE.w	D2, D4
	ADD.w	D0, D4
	MOVE.w	D1, D5
	ADD.w	Window_tilemap_x.w, D4
	ANDI.w	#$003F, D4
	ASL.w	#1, D4
	ADD.w	D4, D5
	ANDI.l	#$0000FFFF, D5
	SWAP	D5
	ADDI.l	#$40000003, D5
	MOVE.b	(A0)+, D4
	ADDI.w	#$84C0, D4
	OR.w	Window_tile_attrs.w, D4
	MOVE.l	D5, VDP_control_port
	MOVE.w	D4, VDP_data_port
	ADDQ.w	#1, D2
	CMP.w	Window_width.w, D2
	BLE.b	WriteWindowRowToVDP_Done
	RTS

; LoadLevelUpBannerTiles
; Load and display the level-up notification banner tiles to VRAM.
LoadLevelUpBannerTiles:
	LEA	UIBorder_LevelUp, A0
	MOVE.l	#$420A0003, D5
	ORI	#$0700, SR
	MOVE.w	#2, D7
LoadLevelUpBannerTiles_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$000B, D6
LoadLevelUpBannerTiles_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ADDI.w	#$84C0, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, LoadLevelUpBannerTiles_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, LoadLevelUpBannerTiles_Done
	ANDI	#$F8FF, SR
	RTS

;==============================================================
; HUD STATUS DISPLAY
;==============================================================

; DisplayHpMpAlt
; Display current HP and MP at alternate HUD column (x=6).
; Variant of DisplayPlayerHpMp used for a different HUD layout position.
DisplayHpMpAlt:
	ORI	#$0700, SR
	MOVE.w	#6, Window_number_cursor_x.w
	MOVE.w	#$0018, Window_number_cursor_y.w
	MOVE.w	Player_hp.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	MOVE.w	#0, D3
	CLR.w	D5
	BSR.w	ConvertNumberToTextDigits
	MOVE.w	#6, Window_number_cursor_x.w
	MOVE.w	#$001A, Window_number_cursor_y.w
	MOVE.w	Player_mp.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	MOVE.w	#0, D3
	CLR.w	D5
	BSR.w	ConvertNumberToTextDigits
	ANDI	#$F8FF, SR
	RTS
; DisplayPlayerHpMp
; Display the player's current HP and MP values on the HUD.
DisplayPlayerHpMp:
	ORI	#$0700, SR
	MOVE.w	#7, Window_number_cursor_x.w
	MOVE.w	#$0018, Window_number_cursor_y.w
	MOVE.w	Player_hp.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	MOVE.w	#0, D3
	CLR.w	D5
	BSR.w	ConvertNumberToTextDigits
	MOVE.w	#7, Window_number_cursor_x.w
	MOVE.w	#$001A, Window_number_cursor_y.w
	MOVE.w	Player_mp.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	MOVE.w	#0, D3
	CLR.w	D5
	BSR.w	ConvertNumberToTextDigits
	ANDI	#$F8FF, SR
	RTS

; DisplayCurrentHpMp
; Render the current HP/MP numeric values to the HUD window plane.
DisplayCurrentHpMp:
	ORI	#$0700, SR
	MOVE.w	#7, Window_number_cursor_x.w
	MOVE.w	#$0018, Window_number_cursor_y.w
	MOVE.w	Player_hp.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	MOVE.w	#0, D3
	CLR.w	D5
	BSR.w	WordToDecimalString_NoPad
	MOVE.w	#7, Window_number_cursor_x.w
	MOVE.w	#$001A, Window_number_cursor_y.w
	MOVE.w	Player_mp.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	MOVE.w	#0, D3
	CLR.w	D5
	BSR.w	WordToDecimalString_NoPad
	ANDI	#$F8FF, SR
	RTS

; DisplayMaxHpMpAlt
; Display max HP and MP at alternate HUD column (x=$C).
; Variant of DisplayMaxHpMp used for a different HUD layout position.
DisplayMaxHpMpAlt:
	ORI	#$0700, SR
	MOVE.w	#$000C, Window_number_cursor_x.w
	MOVE.w	#$0018, Window_number_cursor_y.w
	MOVE.w	Player_mhp.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	MOVE.w	#0, D3
	CLR.w	D5
	BSR.w	WordToDecimalString_NoPad
	MOVE.w	#$000C, Window_number_cursor_x.w
	MOVE.w	#$001A, Window_number_cursor_y.w
	MOVE.w	Player_mmp.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	MOVE.w	#0, D3
	CLR.w	D5
	BSR.w	WordToDecimalString_NoPad
	ANDI	#$F8FF, SR
	RTS
; DisplayCantUseMessage
; Display the "can't use" error message in the HUD title bar.
DisplayCantUseMessage:
	LEA	CantUseStr, A0
	ORI	#$0700, SR
	MOVE.l	#$6CB60003, VDP_control_port
	MOVE.w	#9, D7
DisplayCantUseMessage_Done:
	MOVE.w	#$84E0, VDP_data_port
	DBF	D7, DisplayCantUseMessage_Done
	MOVE.l	#$6D360003, VDP_control_port
	MOVE.w	#9, D7
DisplayCantUseMessage_Done2:
	MOVE.w	#$84E0, VDP_data_port
	DBF	D7, DisplayCantUseMessage_Done2
	MOVE.l	#$6D360003, D5
	BRA.w	DisplayReadiedMagicName_Loop
; DisplayReadiedMagicName
; Display the name of the currently readied magic spell in the HUD title bar.
DisplayReadiedMagicName:
	LEA	MagicNames, A0
	MOVE.w	Readied_magic.w, D0
	BLT.b	DisplayReadiedMagicName_Loop2
	ANDI.w	#$00FF, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	MOVEA.l	(A0,D0.w), A0
	BRA.w	DisplayReadiedMagicName_Loop3
DisplayReadiedMagicName_Loop2:
	LEA	NothingStr, A0
DisplayReadiedMagicName_Loop3:
	ORI	#$0700, SR
	MOVE.l	#$4CB60003, VDP_control_port
	MOVE.w	#9, D7
DisplayReadiedMagicName_Loop3_Done:
	MOVE.w	#$84E0, VDP_data_port
	DBF	D7, DisplayReadiedMagicName_Loop3_Done
	MOVE.l	#$4D360003, VDP_control_port
	MOVE.w	#9, D7
DisplayReadiedMagicName_Loop3_Done2:
	MOVE.w	#$84E0, VDP_data_port
	DBF	D7, DisplayReadiedMagicName_Loop3_Done2
	MOVE.l	#$4D360003, D5
DisplayReadiedMagicName_Loop:
	CLR.w	D2
TitleBarText_Next:
	MOVE.w	D2, D3
	ANDI.l	#$0000FFFF, D3
	ADD.w	D3, D3
	SWAP	D3
	ADD.l	D5, D3
	CLR.w	D0
	MOVE.b	(A0)+, D0
	CMPI.b	#SCRIPT_END, D0
	BEQ.w	TitleBarText_SpecialChar_Loop
	CMPI.b	#SCRIPT_WIDE_CHAR_LO, D0
	BEQ.b	TitleBarText_SpecialChar
	CMPI.b	#SCRIPT_WIDE_CHAR_HI, D0
	BEQ.b	TitleBarText_SpecialChar
	ADDI.w	#$84C0, D0
	MOVE.l	D3, VDP_control_port
	MOVE.w	D0, VDP_data_port
	ANDI	#$F8FF, SR
	ADDQ.w	#1, D2
	BRA.b	TitleBarText_Next
TitleBarText_SpecialChar:
	ADDI.w	#$84C0, D0	
	SUBI.l	#$00820000, D3	
	ORI	#$0700, SR	
	MOVE.l	D3, VDP_control_port	
	MOVE.w	D0, VDP_data_port	
	ANDI	#$F8FF, SR	
	BRA.b	TitleBarText_Next	
TitleBarText_SpecialChar_Loop:
	RTS

; DisplayPlayerMaxHpMp
; Display the player's maximum HP and MP on the HUD.
DisplayPlayerMaxHpMp:
	ORI	#$0700, SR
	MOVE.w	#$000D, Window_number_cursor_x.w
	MOVE.w	#$0018, Window_number_cursor_y.w
	MOVE.w	Player_mhp.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	MOVE.w	#0, D3
	CLR.w	D5
	BSR.w	ConvertNumberToTextDigits
	MOVE.w	#$000D, Window_number_cursor_x.w
	MOVE.w	#$001A, Window_number_cursor_y.w
	MOVE.w	Player_mmp.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	MOVE.w	#0, D3
	CLR.w	D5
	BSR.w	ConvertNumberToTextDigits
	ANDI	#$F8FF, SR
	RTS

; DisplayMaxHpMp
; Render the max HP/MP numeric values to the HUD window plane.
DisplayMaxHpMp:
	ORI	#$0700, SR
	MOVE.w	#$000D, Window_number_cursor_x.w
	MOVE.w	#$0018, Window_number_cursor_y.w
	MOVE.w	Player_mhp.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	MOVE.w	#0, D3
	CLR.w	D5
	BSR.w	WordToDecimalString_NoPad
	MOVE.w	#$000D, Window_number_cursor_x.w
	MOVE.w	#$001A, Window_number_cursor_y.w
	MOVE.w	Player_mmp.w, D0
	JSR	ConvertToBCD
	MOVE.w	D0, D2
	MOVE.w	#0, D3
	CLR.w	D5
	BSR.w	WordToDecimalString_NoPad
	ANDI	#$F8FF, SR
	RTS

; DisplayPlayerKimsAndExperience
; Display the player's kims (gold) and experience totals on the HUD.
DisplayPlayerKimsAndExperience:
	ORI	#$0700, SR
	MOVE.w	#$001C, Window_number_cursor_x.w
	MOVE.w	#$0013, Window_number_cursor_y.w
	MOVE.l	Player_kims.w, D2
	MOVE.w	#0, D3
	CLR.w	D5
	BSR.w	LongToDecimalString
	MOVE.w	#$001C, Window_number_cursor_x.w
	MOVE.w	#$0015, Window_number_cursor_y.w
	MOVE.l	Player_experience.w, D2
	MOVE.w	#0, D3
	CLR.w	D5
	BSR.w	LongToDecimalString
	ANDI	#$F8FF, SR
	RTS

;==============================================================
; PALETTE MANAGEMENT
;==============================================================

; UpdatePaletteBuffer
; Flush palette buffer to CRAM via DMA if dirty.
; Dispatches to fade-in or fade-out routines based on active masks.
UpdatePaletteBuffer:
	LEA	Palette_line_0_buffer.w, A1
	TST.b	Palette_fade_in_mask.w
	BNE.w	BuildFadeInTable_Store_Loop
	TST.b	Fade_out_lines_mask.w
	BNE.w	LoadPalettesFromTable_Return_Loop
	TST.b	Fade_in_lines_mask.w
	BNE.w	BuildFadeTable_Store_Loop
	BCLR.b	#7, Palette_buffer_dirty.w
	BEQ.w	UpdatePaletteBuffer_Loop
	stopZ80
	JSR	InitVdpDmaRamRoutine
	MOVE.w	#2, D4
	ORI.w	#$8F00, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.l	#$94009340, VDP_control_port
	MOVE.l	#$96E09500, VDP_control_port
	MOVE.w	#$977F, VDP_control_port
	MOVE.l	#VDP_DMA_CMD_CRAM, Vdp_dma_cmd.w
	JSR	Vdp_dma_ram_routine.w
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4
	MOVE.w	D4, VDP_control_port
	startZ80
UpdatePaletteBuffer_Loop:
	RTS

; ---------------------------------------------------------------------------
; LoadPalettesFromTable — copy four palettes from PaletteDataTable to RAM
;
; Reads four 16-entry (32-byte) palette slots from PaletteDataTable using
; the indices in Palette_line_0_index through Palette_line_3_index, and
; copies them into Palette_line_0_buffer (128 bytes total).  Sets bit 7 of
; Palette_buffer_dirty so the VBlank DMA routine uploads them to CRAM.
;
; Returns immediately without copying if any fade is in progress
; (Palette_fade_in_mask, Fade_out_lines_mask, or Fade_in_lines_mask set).
;
; Input:   (all state via RAM)
;   Palette_line_0_index.w – Palette_line_3_index.w  — palette table indices
;
; Scratch:  D1, D2, A0-A3
; Output:   Palette_line_0_buffer filled; Palette_buffer_dirty bit 7 set
; ---------------------------------------------------------------------------
; LoadPalettesFromTable
; Load palettes from table into palette buffer.
; Checks fade flags, then copies 4 palettes (32 bytes each) from indexed palette table.
LoadPalettesFromTable:
	TST.b	Palette_fade_in_mask.w
	BNE.w	LoadPalettesFromTable_Return
	TST.b	Fade_out_lines_mask.w
	BNE.w	LoadPalettesFromTable_Return
	TST.b	Fade_in_lines_mask.w
	BNE.w	LoadPalettesFromTable_Return
	LEA	Palette_line_0_buffer.w, A1
	LEA	Palette_line_0_index.w, A0
	LEA	PaletteDataTable, A2
	MOVEQ	#3, D2
LoadPalettesFromTable_Done:
	MOVEQ	#0, D1
	MOVE.w	(A0)+, D1
	ASL.w	#5, D1
	LEA	(A2,D1.w), A3
	MOVE.l	(A3)+, (A1)+
	MOVE.l	(A3)+, (A1)+
	MOVE.l	(A3)+, (A1)+
	MOVE.l	(A3)+, (A1)+
	MOVE.l	(A3)+, (A1)+
	MOVE.l	(A3)+, (A1)+
	MOVE.l	(A3)+, (A1)+
	MOVE.l	(A3)+, (A1)+
	DBF	D2, LoadPalettesFromTable_Done
	BSET.b	#7, Palette_buffer_dirty.w
LoadPalettesFromTable_Return:
	RTS

LoadPalettesFromTable_Return_Loop:
	ADDQ.w	#1, Palette_fade_tick_counter.w
	MOVE.w	Palette_fade_tick_counter.w, D0
	MOVE.w	D0, D1
	SUBQ.w	#1, D1
	EOR.w	D0, D1
	BTST.l	#3, D1
	BEQ.w	FadeOutPalette_WriteVDP
	ADDQ.w	#1, Palette_fade_step_counter.w
	CMPI.w	#8, Palette_fade_step_counter.w
	BGE.w	BuildFadeTable_Store_Loop2
	MOVE.b	Fade_out_lines_mask.w, D3
	BTST.l	#0, D3
	BEQ.b	LoadPalettesFromTable_Return_Loop2
	LEA	Palette_line_0_buffer.w, A1
	BSR.w	DecrementPaletteRGBValues
LoadPalettesFromTable_Return_Loop2:
	BTST.l	#1, D3
	BEQ.b	LoadPalettesFromTable_Return_Loop3
	LEA	Palette_line_1_buffer.w, A1
	BSR.w	DecrementPaletteRGBValues
LoadPalettesFromTable_Return_Loop3:
	BTST.l	#2, D3
	BEQ.b	LoadPalettesFromTable_Return_Loop4
	LEA	Palette_line_2_buffer.w, A1
	BSR.w	DecrementPaletteRGBValues
LoadPalettesFromTable_Return_Loop4:
	BTST.l	#3, D3
	BEQ.b	FadeOutPalette_WriteVDP
	LEA	Palette_line_3_buffer.w, A1
	BSR.w	DecrementPaletteRGBValues
; FadeOutPalette_WriteVDP
; DMA-transfer the current palette buffer to CRAM (fade-out flush).
FadeOutPalette_WriteVDP:
	stopZ80
	JSR	InitVdpDmaRamRoutine
	MOVE.w	#2, D4
	ORI.w	#$8F00, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.l	#$94009340, VDP_control_port
	MOVE.l	#$96E09500, VDP_control_port
	MOVE.w	#$977F, VDP_control_port
	MOVE.l	#VDP_DMA_CMD_CRAM, Vdp_dma_cmd.w
	JSR	Vdp_dma_ram_routine.w
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4
	MOVE.w	D4, VDP_control_port
	startZ80
	RTS

; DecrementPaletteRGBValues
; Step one palette line (16 colors) one step toward black.
; Inputs: A1 = palette line buffer pointer
DecrementPaletteRGBValues:
	MOVEQ	#$0000000F, D2
DecrementPaletteRGBValues_Done:
	MOVE.w	(A1), D0
	BEQ.w	BuildFadeTable_Store
	MOVE.w	D0, D1
	ANDI.w	#$0F00, D1
	BEQ.b	DecrementPaletteRGBValues_Loop
	SUBI.w	#$0200, D0
DecrementPaletteRGBValues_Loop:
	MOVE.w	D0, D1
	ANDI.w	#$00F0, D1
	BEQ.b	DecrementPaletteRGBValues_Loop2
	SUBI.w	#$0020, D0
DecrementPaletteRGBValues_Loop2:
	MOVE.w	D0, D1
	ANDI.w	#$000F, D1
	BEQ.b	BuildFadeTable_Store
	SUBQ.w	#2, D0
BuildFadeTable_Store:
	MOVE.w	D0, (A1)+
	DBF	D2, DecrementPaletteRGBValues_Done
	RTS

BuildFadeTable_Store_Loop2:
	CLR.b	Fade_out_lines_mask.w
	CLR.w	Palette_fade_step_counter.w
	LEA	Palette_line_0_index.w, A0
	MOVE.l	#0, (A0)+
	MOVE.l	#0, (A0)+
	stopZ80
	JSR	InitVdpDmaRamRoutine
	MOVE.w	#2, D4
	ORI.w	#$8F00, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.l	#$94009340, VDP_control_port
	MOVE.l	#$96E09500, VDP_control_port
	MOVE.w	#$977F, VDP_control_port
	MOVE.l	#VDP_DMA_CMD_CRAM, Vdp_dma_cmd.w
	JSR	Vdp_dma_ram_routine.w
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4
	MOVE.w	D4, VDP_control_port
	startZ80
	RTS

BuildFadeTable_Store_Loop:
	ADDQ.w	#1, Palette_fade_tick_counter.w
	MOVE.w	Palette_fade_tick_counter.w, D0
	MOVE.w	D0, D1
	SUBQ.w	#1, D1
	EOR.w	D0, D1
	BTST.l	#3, D1
	BEQ.w	FadeInPalette_WriteVDP
	ADDQ.w	#1, Palette_fade_in_step.w
	CMPI.w	#8, Palette_fade_in_step.w
	BGE.w	BuildFadeInTable_Store_Loop2
	MOVE.b	Fade_in_lines_mask.w, D3
	BTST.l	#0, D3
	BEQ.b	BuildFadeTable_Store_Loop3
	LEA	Palette_line_0_buffer.w, A1
	MOVE.w	Palette_line_0_fade_target.w, D1
	BSR.w	ShiftPaletteTowardsTarget
BuildFadeTable_Store_Loop3:
	BTST.l	#1, D3
	BEQ.b	BuildFadeTable_Store_Loop4
	LEA	Palette_line_1_buffer.w, A1
	MOVE.w	Palette_line_1_fade_target.w, D1
	BSR.w	ShiftPaletteTowardsTarget
BuildFadeTable_Store_Loop4:
	BTST.l	#2, D3
	BEQ.b	BuildFadeTable_Store_Loop5
	LEA	Palette_line_2_buffer.w, A1
	MOVE.w	Palette_line_2_fade_target.w, D1
	BSR.w	ShiftPaletteTowardsTarget
BuildFadeTable_Store_Loop5:
	BTST.l	#3, D3
	BEQ.b	FadeInPalette_WriteVDP
	LEA	Palette_line_3_buffer.w, A1
	MOVE.w	Palette_line_3_fade_target.w, D1
	BSR.w	ShiftPaletteTowardsTarget
; FadeInPalette_WriteVDP
; DMA-transfer the current palette buffer to CRAM (fade-in flush).
FadeInPalette_WriteVDP:
	MOVE.w	#$0100, Z80_bus_request
FadeInPalette_WriteVDP_Done:
	BTST.b	#0, Z80_bus_request
	BNE.b	FadeInPalette_WriteVDP_Done
	JSR	InitVdpDmaRamRoutine
	MOVE.w	#2, D4
	ORI.w	#$8F00, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.l	#$94009340, VDP_control_port
	MOVE.l	#$96E09500, VDP_control_port
	MOVE.w	#$977F, VDP_control_port
	MOVE.l	#VDP_DMA_CMD_CRAM, Vdp_dma_cmd.w
	JSR	Vdp_dma_ram_routine.w
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	#0, Z80_bus_request
	RTS

; ShiftPaletteTowardsTarget
; Step one palette line (16 colors) one step toward a target palette.
; Inputs: A1 = current palette buffer, D1 = target palette index
ShiftPaletteTowardsTarget:
	LEA	PaletteDataTable, A3
	ASL.w	#5, D1
	LEA	(A3,D1.w), A3
	MOVEQ	#$0000000F, D7
ShiftPaletteTowardsTarget_Done:
	MOVE.w	(A3)+, D4
	MOVE.w	(A1), D0
	CMP.w	D4, D0
	BEQ.w	BuildFadeInTable_Store
	MOVE.w	D0, D1
	ANDI.w	#$0F00, D1
	MOVE.w	D4, D5
	ANDI.w	#$0F00, D5
	CMP.w	D5, D1
	BGE.b	ShiftPaletteTowardsTarget_Loop
	ADDI.w	#$0200, D0
ShiftPaletteTowardsTarget_Loop:
	MOVE.w	D0, D1
	ANDI.w	#$00F0, D1
	MOVE.w	D4, D5
	ANDI.w	#$00F0, D5
	CMP.w	D5, D1
	BGE.b	ShiftPaletteTowardsTarget_Loop2
	ADDI.w	#$0020, D0
ShiftPaletteTowardsTarget_Loop2:
	MOVE.w	D0, D1
	ANDI.w	#$000F, D1
	MOVE.w	D4, D5
	ANDI.w	#$000F, D5
	CMP.w	D5, D1
	BGE.b	BuildFadeInTable_Store
	ADDQ.w	#2, D0
BuildFadeInTable_Store:
	MOVE.w	D0, (A1)+
	DBF	D7, ShiftPaletteTowardsTarget_Done
	RTS

BuildFadeInTable_Store_Loop2:
	MOVE.b	Fade_in_lines_mask.w, D3
	BTST.l	#0, D3
	BEQ.b	BuildFadeInTable_Store_Loop3
	MOVE.w	Palette_line_0_fade_target.w, Palette_line_0_index.w
BuildFadeInTable_Store_Loop3:
	BTST.l	#1, D3
	BEQ.b	BuildFadeInTable_Store_Loop4
	MOVE.w	Palette_line_1_fade_target.w, Palette_line_1_index.w
BuildFadeInTable_Store_Loop4:
	BTST.l	#2, D3
	BEQ.b	BuildFadeInTable_Store_Loop5
	MOVE.w	Palette_line_2_fade_target.w, Palette_line_2_index.w
BuildFadeInTable_Store_Loop5:
	BTST.l	#3, D3
	BEQ.b	BuildFadeInTable_Store_Loop6
	MOVE.w	Palette_line_3_fade_target.w, Palette_line_3_index.w
BuildFadeInTable_Store_Loop6:
	CLR.b	Fade_in_lines_mask.w
	CLR.w	Palette_fade_in_step.w
	MOVE.w	#$0100, Z80_bus_request
BuildFadeInTable_Store_Loop6_Done:
	BTST.b	#0, Z80_bus_request
	BNE.b	BuildFadeInTable_Store_Loop6_Done
	JSR	InitVdpDmaRamRoutine
	MOVE.w	#2, D4
	ORI.w	#$8F00, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.l	#$94009340, VDP_control_port
	MOVE.l	#$96E09500, VDP_control_port
	MOVE.w	#$977F, VDP_control_port
	MOVE.l	#VDP_DMA_CMD_CRAM, Vdp_dma_cmd.w
	JSR	Vdp_dma_ram_routine.w
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	#0, Z80_bus_request
	RTS

BuildFadeInTable_Store_Loop:
	ADDQ.w	#1, Palette_fade_tick_counter.w
	MOVE.w	Palette_fade_tick_counter.w, D0
	MOVE.w	D0, D1
	SUBQ.w	#1, D1
	EOR.w	D0, D1
	BTST.l	#3, D1
	BEQ.w	FadePaletteLine3_WriteVDP
	ADDQ.w	#1, Palette_fade_in_step_counter.w
	CMPI.w	#8, Palette_fade_in_step_counter.w
	BGE.w	FadePaletteTowardsTarget_NextEntry_Loop
	MOVE.b	Palette_fade_in_mask.w, D3
	LEA	Palette_line_0_buffer.w, A1
	BTST.l	#0, D3
	BEQ.b	BuildFadeInTable_Store_Loop7
	MOVE.w	Palette_line_0_fade_in_target.w, D1
	BSR.w	FadePaletteTowardsTarget
	BRA.b	BuildFadeInTable_Store_Loop8
BuildFadeInTable_Store_Loop7:
	MOVE.w	Palette_line_0_index.w, D1
	BSR.w	LoadPaletteByIndex
BuildFadeInTable_Store_Loop8:
	LEA	Palette_line_1_buffer.w, A1
	BTST.l	#1, D3
	BEQ.b	BuildFadeInTable_Store_Loop9
	MOVE.w	Palette_line_1_fade_in_target.w, D1
	BSR.w	FadePaletteTowardsTarget
	BRA.b	BuildFadeInTable_Store_Loop10
BuildFadeInTable_Store_Loop9:
	MOVE.w	Palette_line_1_index.w, D1
	BSR.w	LoadPaletteByIndex
BuildFadeInTable_Store_Loop10:
	LEA	Palette_line_2_buffer.w, A1
	BTST.l	#2, D3
	BEQ.b	BuildFadeInTable_Store_Loop11
	MOVE.w	Palette_line_2_fade_in_target.w, D1
	BSR.w	FadePaletteTowardsTarget
	BRA.b	BuildFadeInTable_Store_Loop12
BuildFadeInTable_Store_Loop11:
	MOVE.w	Palette_line_2_index.w, D1
	BSR.w	LoadPaletteByIndex
BuildFadeInTable_Store_Loop12:
	LEA	Palette_line_3_buffer.w, A1
	BTST.l	#3, D3
	BEQ.b	BuildFadeInTable_Store_Loop13
	MOVE.w	Palette_line_3_fade_in_target.w, D1
	BSR.w	FadePaletteTowardsTarget
	BRA.b	FadePaletteLine3_WriteVDP
BuildFadeInTable_Store_Loop13:
	MOVE.w	Palette_line_3_index.w, D1
	BSR.w	LoadPaletteByIndex
; FadePaletteLine3_WriteVDP
; DMA-transfer the current palette buffer to CRAM (cross-fade line 3 flush).
FadePaletteLine3_WriteVDP:
	MOVE.w	#$0100, Z80_bus_request
FadePaletteLine3_WriteVDP_Done:
	BTST.b	#0, Z80_bus_request
	BNE.b	FadePaletteLine3_WriteVDP_Done
	JSR	InitVdpDmaRamRoutine
	MOVE.w	#2, D4
	ORI.w	#$8F00, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.l	#$94009340, VDP_control_port
	MOVE.l	#$96E09500, VDP_control_port
	MOVE.w	#$977F, VDP_control_port
	MOVE.l	#VDP_DMA_CMD_CRAM, Vdp_dma_cmd.w
	JSR	Vdp_dma_ram_routine.w
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	#0, Z80_bus_request
	RTS

; LoadPaletteByIndex
; Copy one palette (16 colors, 32 bytes) from PaletteDataTable into palette buffer.
; Inputs: A1 = destination palette line buffer, D1 = palette index
LoadPaletteByIndex:
	LEA	PaletteDataTable, A2
	ASL.w	#5, D1
	LEA	(A2,D1.w), A3
	MOVE.l	(A3)+, (A1)+
	MOVE.l	(A3)+, (A1)+
	MOVE.l	(A3)+, (A1)+
	MOVE.l	(A3)+, (A1)+
	MOVE.l	(A3)+, (A1)+
	MOVE.l	(A3)+, (A1)+
	MOVE.l	(A3)+, (A1)+
	MOVE.l	(A3)+, (A1)+
	RTS

; FadePaletteTowardsTarget
; Step one palette line (16 colors) toward a target, adjusting R/G/B independently.
; Inputs: A1 = current palette line buffer, D1 = target palette index
FadePaletteTowardsTarget:
	LEA	PaletteDataTable, A3
	ASL.w	#5, D1
	LEA	(A3,D1.w), A3
	MOVEQ	#$0000000F, D7
FadePaletteTowardsTarget_Done:
	MOVE.w	(A3)+, D4
	MOVE.w	(A1), D0
	CMP.w	D4, D0
	BEQ.w	FadePaletteTowardsTarget_NextEntry
	MOVE.w	D0, D1
	ANDI.w	#$0F00, D1
	MOVE.w	D4, D5
	ANDI.w	#$0F00, D5
	CMP.w	D5, D1
	BEQ.b	ShiftColorGreenComponent
	BLT.b	FadePaletteTowardsTarget_Loop
	SUBI.w	#$0200, D0
	BRA.b	ShiftColorGreenComponent
FadePaletteTowardsTarget_Loop:
	ADDI.w	#$0200, D0
ShiftColorGreenComponent:
	MOVE.w	D0, D1
	ANDI.w	#$00F0, D1
	MOVE.w	D4, D5
	ANDI.w	#$00F0, D5
	CMP.w	D5, D1
	BEQ.b	ShiftColorBlueComponent
	BLT.b	ShiftColorGreenComponent_Loop
	SUBI.w	#$0020, D0
	BRA.b	ShiftColorBlueComponent
ShiftColorGreenComponent_Loop:
	ADDI.w	#$0020, D0
ShiftColorBlueComponent:
	MOVE.w	D0, D1
	ANDI.w	#$000F, D1
	MOVE.w	D4, D5
	ANDI.w	#$000F, D5
	CMP.w	D5, D1
	BEQ.b	FadePaletteTowardsTarget_NextEntry
	BLT.b	ShiftColorBlueComponent_Loop
	SUBQ.w	#2, D0
	BRA.b	FadePaletteTowardsTarget_NextEntry
ShiftColorBlueComponent_Loop:
	ADDQ.w	#2, D0
FadePaletteTowardsTarget_NextEntry:
	MOVE.w	D0, (A1)+
	DBF	D7, FadePaletteTowardsTarget_Done
	RTS

FadePaletteTowardsTarget_NextEntry_Loop:
	MOVE.b	Palette_fade_in_mask.w, D3
	BTST.l	#0, D3
	BEQ.b	FadePaletteTowardsTarget_NextEntry_Loop2
	MOVE.w	Palette_line_0_fade_in_target.w, Palette_line_0_index.w
FadePaletteTowardsTarget_NextEntry_Loop2:
	BTST.l	#1, D3
	BEQ.b	FadePaletteTowardsTarget_NextEntry_Loop3
	MOVE.w	Palette_line_1_fade_in_target.w, Palette_line_1_index.w
FadePaletteTowardsTarget_NextEntry_Loop3:
	BTST.l	#2, D3
	BEQ.b	FadePaletteTowardsTarget_NextEntry_Loop4
	MOVE.w	Palette_line_2_fade_in_target.w, Palette_line_2_index.w
FadePaletteTowardsTarget_NextEntry_Loop4:
	BTST.l	#3, D3
	BEQ.b	FadePaletteTowardsTarget_NextEntry_Loop5
	MOVE.w	Palette_line_3_fade_in_target.w, Palette_line_3_index.w
FadePaletteTowardsTarget_NextEntry_Loop5:
	CLR.b	Palette_fade_in_mask.w
	CLR.w	Palette_fade_in_step_counter.w
	MOVE.w	#$0100, Z80_bus_request
FadePaletteTowardsTarget_NextEntry_Loop5_Done:
	BTST.b	#0, Z80_bus_request
	BNE.b	FadePaletteTowardsTarget_NextEntry_Loop5_Done
	JSR	InitVdpDmaRamRoutine
	MOVE.w	#2, D4
	ORI.w	#$8F00, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	VDP_Reg1_cache.w, D4
	BSET.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.l	#$94009340, VDP_control_port
	MOVE.l	#$96E09500, VDP_control_port
	MOVE.w	#$977F, VDP_control_port
	MOVE.l	#VDP_DMA_CMD_CRAM, Vdp_dma_cmd.w
	JSR	Vdp_dma_ram_routine.w
	MOVE.w	VDP_Reg1_cache.w, D4
	BCLR.l	#4, D4
	MOVE.w	D4, VDP_control_port
	MOVE.w	#0, Z80_bus_request
	RTS
	
; Palette data table — indexed by palette ID, 32 bytes each (16 colors × 2 bytes)
PaletteDataTable:
	incbin "data/art/palettes/palette_data.bin"

;==============================================================
; NAME ENTRY SCREEN
;==============================================================

; NameEntryScreen_Init
; Initialize the player name entry screen.
; Clears VRAM, sets up fade targets, draws character grid and sprites.
NameEntryScreen_Init:
	JSR	DisableVDPDisplay
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	MOVE.w	#PALETTE_IDX_NAMEENTRY_GLOW1, Palette_line_1_fade_target.w
	MOVE.w	#PALETTE_IDX_NAMEENTRY_GLOW2, Palette_line_2_fade_target.w
	MOVE.w	#PALETTE_IDX_NAMEENTRY_BG, Palette_line_3_fade_target.w
	MOVE.b	#FLAG_TRUE, Fade_in_lines_mask.w
	BSR.w	DrawNameEntryBackground
	BSR.w	DrawNameEntryCharGrid
	MOVEA.l	Enemy_list_ptr.w, A6
	BSET.b	#7, (A6)
	BSET.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BSET.b	#5, obj_sprite_flags(A6)
	BCLR.b	#6, obj_sprite_flags(A6)
	CLR.b	obj_move_counter(A6)
	MOVE.w	#1, Name_entry_cursor_x.w
	MOVE.w	#0, obj_screen_x(A6)
	MOVE.w	#0, obj_screen_y(A6)
	MOVE.w	#VRAM_TILE_NAME_ENTRY_GRID, obj_tile_index(A6)
	MOVE.b	#SPRITE_SIZE_1x1, obj_sprite_size(A6)
	MOVE.l	#NameEntryGridCursor_Tick, obj_tick_fn(A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BSET.b	#7, (A6)
	BSET.b	#7, obj_sprite_flags(A6)
	BCLR.b	#3, obj_sprite_flags(A6)
	BCLR.b	#4, obj_sprite_flags(A6)
	BCLR.b	#5, obj_sprite_flags(A6)
	BSET.b	#6, obj_sprite_flags(A6)
	CLR.b	obj_move_counter(A6)
	MOVE.w	#$008C, obj_screen_x(A6)
	MOVE.w	#$0020, obj_screen_y(A6)
	MOVE.w	#VRAM_TILE_NAME_ENTRY_TEXT, obj_tile_index(A6)
	MOVE.b	#SPRITE_SIZE_1x1, obj_sprite_size(A6)
	MOVE.l	#NameEntryTextCursor_Tick, obj_tick_fn(A6)
	JSR	EnableDisplay
	MOVE.l	#NameEntryScreen_InputHandler, obj_tick_fn(A5)
	CLR.w	Name_input_cursor_pos.w
	CLR.w	Name_entry_cursor_column.w
	RTS

; NameEntryScreen_InputHandler
; Per-frame input handler for the name entry screen.
; Handles A/B/Start buttons and D-pad cursor movement.
NameEntryScreen_InputHandler:
	TST.b	Fade_in_lines_mask.w
	BNE.b	NameEntryScreen_InputHandler_Loop
	CheckButton BUTTON_BIT_C
	BNE.b	NameEntryScreen_InputHandler_Loop2
	CheckButton BUTTON_BIT_B
	BNE.w	NameEntry_ConfirmDone_Loop
	CheckButton BUTTON_BIT_START
	BEQ.b	NameEntryScreen_InputHandler_Loop3
	LEA	Player_name.w, A0	
	MOVE.w	Name_input_cursor_pos.w, D0	
	LEA	(A0,D0.w), A0	
	BRA.w	NameEntry_ConfirmDone	
NameEntryScreen_InputHandler_Loop3:
	BSR.w	HandleNameEntryDPad
NameEntryScreen_InputHandler_Loop:
	RTS

NameEntryScreen_InputHandler_Loop2:
	PlaySound	SOUND_MENU_SELECT
	LEA	Player_name.w, A0
	LEA	NameEntryCharacterTable, A1
	MOVE.l	#$41A20003, D6
	MOVE.w	Name_input_cursor_pos.w, D0
	LEA	(A0,D0.w), A0
	MOVEQ	#0, D1
	MOVE.w	Name_entry_cursor_column.w, D1
	ADD.w	D1, D1
	SWAP	D1
	ADD.l	D1, D6
	MOVE.w	Name_entry_cursor_row.w, D2
	MULU.w	#$001E, D2
	ADD.w	Name_entry_cursor_x.w, D2
	MOVE.b	(A1,D2.w), D3
	CMPI.b	#SCRIPT_NEWLINE, D3
	BEQ.w	NameEntry_ConfirmDone
	CMPI.w	#5, Name_entry_cursor_column.w
	BLE.b	NameEntryScreen_InputHandler_Loop4
	RTS
	
NameEntryScreen_InputHandler_Loop4:
	CMPI.b	#SCRIPT_WIDE_CHAR_LO, D3
	BEQ.w	WriteCharacterToNameEntry_Loop
	CMPI.b	#SCRIPT_WIDE_CHAR_HI, D3
	BEQ.w	WriteCharacterToNameEntry_Loop2
; WriteCharacterToNameEntry
; Write the selected character tile to the player name buffer and VRAM.
WriteCharacterToNameEntry:
	CLR.w	D3
	MOVE.b	$1E(A1,D2.w), D3
	MOVE.b	D3, (A0)
	ADDI.w	#$04C0, D3
	ORI.w	#$8000, D3
	ORI.w	#$4000, D3
	MOVE.l	D6, VDP_control_port
	MOVE.w	D3, VDP_data_port
	ADDQ.w	#1, Name_entry_cursor_column.w
	ADDQ.w	#1, Name_input_cursor_pos.w
	CMPI.w	#5, Name_entry_cursor_column.w
	BLE.b	WriteCharacterToNameEntry_Loop3
	MOVE.w	#$001C, Name_entry_cursor_x.w
	MOVE.w	#NAME_ENTRY_LAST_ROW, Name_entry_cursor_row.w
WriteCharacterToNameEntry_Loop3:
	RTS

WriteCharacterToNameEntry_Loop:
	BSR.b	WriteCharacterToNameEntry	
	SUBI.l	#$00800000, D6	
	MOVE.l	D6, VDP_control_port	
	MOVE.w	#$C5AC, VDP_data_port	
	ADDQ.w	#1, Name_input_cursor_pos.w	
	MOVE.b	#$DE, $1(A0)	
	RTS
	
WriteCharacterToNameEntry_Loop2:
	BSR.b	WriteCharacterToNameEntry	
	SUBI.l	#$00800000, D6	
	MOVE.l	D6, VDP_control_port	
	MOVE.w	#$C5AD, VDP_data_port	
	ADDQ.w	#1, Name_input_cursor_pos.w	
	MOVE.b	#$DF, $1(A0)	
	RTS
	
; NameEntry_ConfirmDone
; Terminate name entry: write null terminator and switch to Done tick handler.
NameEntry_ConfirmDone:
	MOVE.b	#$FF, (A0)
	MOVE.b	#FLAG_TRUE, Name_entry_complete.w
	MOVE.l	#NameEntryScreen_Done, obj_tick_fn(A5)
	RTS

; NameEntry_ConfirmDone_Loop
; Handle backspace: erase last entered character from buffer and VRAM.
NameEntry_ConfirmDone_Loop:
	PlaySound	SOUND_MENU_CANCEL
	TST.w	Name_entry_cursor_column.w
	BLE.w	NameEntry_ConfirmDone_Loop2
	LEA	Player_name.w, A0
	MOVE.l	#$41A20003, D6
	MOVE.w	Name_input_cursor_pos.w, D0
	LEA	-$1(A0,D0.w), A0
	SUBQ.w	#1, D0
	MOVEQ	#0, D1
	MOVE.w	Name_entry_cursor_column.w, D1
	SUBQ.w	#1, D1
	ADD.w	D1, D1
	SWAP	D1
	ADD.l	D1, D6
	MOVE.b	(A0), D0
	CMPI.b	#SCRIPT_WIDE_CHAR_LO, D0
	BEQ.b	NameEntry_ConfirmDone_Loop3
	CMPI.b	#SCRIPT_WIDE_CHAR_HI, D0
	BNE.b	NameEntry_ConfirmDone_Loop4
NameEntry_ConfirmDone_Loop3:
	SUBQ.w	#1, Name_input_cursor_pos.w	
	CLR.b	-$1(A0)	
	MOVE.l	D6, D5	
	SUBI.l	#$00800000, D5	
	MOVE.l	D5, VDP_control_port	
	MOVE.w	#$E040, VDP_data_port	
NameEntry_ConfirmDone_Loop4:
	SUBQ.w	#1, Name_input_cursor_pos.w
	SUBQ.w	#1, Name_entry_cursor_column.w
	CLR.b	(A0)
	MOVE.l	D6, VDP_control_port
	MOVE.w	#$E04E, VDP_data_port
NameEntry_ConfirmDone_Loop2:
	RTS
; NameEntryScreen_Done
; No-op tick handler after name entry is complete.
NameEntryScreen_Done:
	RTS

; NameEntryGridCursor_Tick
; Per-frame tick: position the grid cursor sprite over the selected character cell.
NameEntryGridCursor_Tick:
	MOVE.w	Name_entry_cursor_x.w, D0
	ASL.w	#3, D0
	ADDI.w	#$002C, D0
	MOVE.w	D0, obj_screen_x(A5)
	MOVE.w	Name_entry_cursor_row.w, D0
	ASL.w	#3, D0
	ADDI.w	#$0030, D0
	MOVE.w	D0, obj_screen_y(A5)
	JSR	AddSpriteToDisplayList
	RTS

; NameEntryTextCursor_Tick
; Per-frame tick: position and blink the text cursor at the current name position.
NameEntryTextCursor_Tick:
	MOVE.w	Name_entry_cursor_column.w, D0
	CMPI.w	#5, D0
	BGT.b	EnemySprite_BlinkReturn
	ASL.w	#3, D0
	ADDI.w	#$008C, D0
	MOVE.w	D0, obj_screen_x(A5)
	ADDQ.b	#1, obj_move_counter(A5)
	MOVE.b	obj_move_counter(A5), D0
	BTST.l	#3, D0
	BEQ.b	EnemySprite_BlinkReturn
	JSR	AddSpriteToDisplayList
EnemySprite_BlinkReturn:
	RTS

; ClearEnemyListFlags
; Disable both enemy sprite slots used during the name entry screen.
ClearEnemyListFlags:
	MOVEA.l	Enemy_list_ptr.w, A6
	BCLR.b	#7, (A6)
	CLR.w	D0
	MOVE.b	obj_next_offset(A6), D0
	LEA	(A6,D0.w), A6
	BCLR.b	#7, (A6)
	RTS

; DrawNameEntryBackground
; Write the background tilemap for the name entry screen to VRAM.
DrawNameEntryBackground:
	ORI	#$0700, SR
	MOVE.l	#$61060003, D5
	LEA	DrawNameEntryBackground_Data, A0
	MOVE.w	#$0016, D7
DrawNameEntryBackground_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$0021, D6
DrawNameEntryBackground_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ANDI.w	#$7FFF, D0
	ORI.w	#$6000, D0
	ADDI.w	#$003C, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawNameEntryBackground_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, DrawNameEntryBackground_Done
	ANDI	#$F8FF, SR
	RTS

; DrawNameEntryCharGrid
; Write the selectable character grid to VRAM for the name entry screen.
DrawNameEntryCharGrid:
	ORI	#$0700, SR
	MOVE.l	#$428A0003, D5
	LEA	NameEntryCharacterTable, A0
	MOVE.w	#$0011, D7
DrawNameEntryCharGrid_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$001D, D6
DrawNameEntryCharGrid_Done2:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ORI.w	#$8000, D0
	ORI.w	#$2000, D0
	ADDI.w	#$04C0, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, DrawNameEntryCharGrid_Done2
	ADDI.l	#$00800000, D5
	DBF	D7, DrawNameEntryCharGrid_Done
	ANDI	#$F8FF, SR
	RTS

; HandleNameEntryDPad
; Dispatch D-pad input to the appropriate cursor movement routine.
; Also handles key-repeat logic.
HandleNameEntryDPad:
	MOVE.b	Controller_current_state.w, D0
	ANDI.w	#$000F, D0
	BEQ.w	HandleNameEntryDPad_Return
	MOVE.b	Controller_previous_state.w, D1
	ANDI.w	#$000F, D1
	EOR.b	D0, D1
	BEQ.w	CheckNameEntryCharValid_Loop
	CLR.b	Name_entry_key_repeat_counter.w
	BTST.l	#0, D0
	BNE.w	NameEntryCursor_Up_Sound
	BTST.l	#1, D0
	BNE.w	NameEntryCursor_Down_Sound
	BTST.l	#2, D0
	BNE.w	NameEntryCursor_Left_Sound
HandleNameEntryDPad_Done:
	PlaySound	SOUND_HIT
; NameEntryCursor_Right
; Move grid cursor right, skipping invalid cells, wrapping at the end of the row.
NameEntryCursor_Right:
	CMPI.w	#NAME_ENTRY_LAST_COL, Name_entry_cursor_x.w
	BGE.b	NameEntryCursor_Right_Loop
	ADDQ.w	#1, Name_entry_cursor_x.w
	BSR.w	CheckNameEntryCharValid
	BNE.b	NameEntryCursor_Right
	RTS
	
NameEntryCursor_Right_Loop:
	CLR.w	Name_entry_cursor_x.w
	BSR.w	CheckNameEntryCharValid
	BNE.b	NameEntryCursor_Right
	RTS
	
; NameEntryCursor_Left_Sound
; Play cursor move sound then fall through to NameEntryCursor_Left.
NameEntryCursor_Left_Sound:
	PlaySound	SOUND_HIT
; NameEntryCursor_Left
; Move grid cursor left, skipping invalid (spacer) cells.
NameEntryCursor_Left:
	TST.w	Name_entry_cursor_x.w
	BLE.b	NameEntryCursor_Left_Loop
	SUBQ.w	#1, Name_entry_cursor_x.w
	BSR.w	CheckNameEntryCharValid
	BNE.b	NameEntryCursor_Left
	RTS
NameEntryCursor_Left_Loop:
	MOVE.w	#NAME_ENTRY_LAST_COL, Name_entry_cursor_x.w
	BSR.w	CheckNameEntryCharValid
	BNE.b	NameEntryCursor_Left
	RTS
	
; NameEntryCursor_Down_Sound
; Play cursor move sound then fall through to NameEntryCursor_Down.
NameEntryCursor_Down_Sound:
	PlaySound	SOUND_HIT
; NameEntryCursor_Down
; Move grid cursor down, skipping invalid cells, wrapping at the bottom.
NameEntryCursor_Down:
	CMPI.w	#NAME_ENTRY_LAST_ROW, Name_entry_cursor_row.w
	BGE.b	NameEntryCursor_Down_Loop
	ADDQ.w	#2, Name_entry_cursor_row.w
	BSR.w	CheckNameEntryCharValid
	BNE.b	NameEntryCursor_Down
	RTS
	
NameEntryCursor_Down_Loop:
	CLR.w	Name_entry_cursor_row.w
	BSR.w	CheckNameEntryCharValid
	BNE.b	NameEntryCursor_Down
	RTS

; NameEntryCursor_Up_Sound
; Play cursor move sound then fall through to NameEntryCursor_Up.
NameEntryCursor_Up_Sound:
	PlaySound	SOUND_HIT
; NameEntryCursor_Up
; Move grid cursor up, skipping invalid cells, wrapping at the top.
NameEntryCursor_Up:
	TST.w	Name_entry_cursor_row.w
	BLE.b	NameEntryCursor_Up_Loop
	SUBQ.w	#2, Name_entry_cursor_row.w
	BSR.w	CheckNameEntryCharValid
	BNE.b	NameEntryCursor_Up
	RTS
	
NameEntryCursor_Up_Loop:
	MOVE.w	#NAME_ENTRY_LAST_ROW, Name_entry_cursor_row.w
	BSR.w	CheckNameEntryCharValid
	BNE.b	NameEntryCursor_Up
	RTS
	
; CheckNameEntryCharValid
; Check whether the character at the current grid position is selectable.
; Outputs: D0 = 0 if valid, $FFFF if invalid (SCRIPT_END spacer)
CheckNameEntryCharValid:
	LEA	NameEntryCharacterTable, A0
	MOVE.w	Name_entry_cursor_row.w, D0
	MULU.w	#$001E, D0
	ADD.w	Name_entry_cursor_x.w, D0
	MOVE.b	(A0,D0.w), D0
	CMPI.b	#SCRIPT_END, D0
	BEQ.b	CheckNameEntryCharValid_Loop2
	CLR.w	D0
	RTS
	
CheckNameEntryCharValid_Loop2:
	MOVE.w	#$FFFF, D0
	RTS

CheckNameEntryCharValid_Loop:
	ADDQ.b	#1, Name_entry_key_repeat_counter.w
	BTST.l	#0, D0
	BNE.w	CheckNameEntryCharValid_Loop3
	BTST.l	#1, D0
	BNE.w	CheckNameEntryCharValid_Loop4
	BTST.l	#2, D0
	BNE.w	CheckNameEntryCharValid_Loop5
	CMPI.b	#8, Name_entry_key_repeat_counter.w
	BLT.w	HandleNameEntryDPad_Return
	CLR.b	Name_entry_key_repeat_counter.w
	BRA.w	HandleNameEntryDPad_Done
CheckNameEntryCharValid_Loop5:
	CMPI.b	#8, Name_entry_key_repeat_counter.w
	BLT.w	HandleNameEntryDPad_Return
	CLR.b	Name_entry_key_repeat_counter.w
	BRA.w	NameEntryCursor_Left_Sound
CheckNameEntryCharValid_Loop3:
	CMPI.b	#8, Name_entry_key_repeat_counter.w
	BLT.w	HandleNameEntryDPad_Return
	CLR.b	Name_entry_key_repeat_counter.w
	BRA.w	NameEntryCursor_Up_Sound
CheckNameEntryCharValid_Loop4:
	CMPI.b	#8, Name_entry_key_repeat_counter.w
	BLT.w	HandleNameEntryDPad_Return
	CLR.b	Name_entry_key_repeat_counter.w
	BRA.w	NameEntryCursor_Down_Sound
HandleNameEntryDPad_Return:
	RTS

;==============================================================
; SEGA LOGO / PROLOGUE CUTSCENE
;==============================================================

; SegaLogoScreen_Init
; Initialize and display the Sega logo screen.
; Clears VRAM, writes logo tilemap, enables display, and starts fade-in.
SegaLogoScreen_Init:
	ORI	#$0700, SR
	JSR	DisableVDPDisplay
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	LEA	SegaLogoScreen_Init_Data, A0
	ORI	#$0700, SR
	MOVE.l	#$40000000, VDP_control_port
	MOVEQ	#$0000001F, D7
SegaLogoScreen_Init_Done:
	MOVE.w	#0, VDP_data_port
	DBF	D7, SegaLogoScreen_Init_Done
	MOVE.l	#$46180003, D5
	MOVE.w	#3, D7
SegaLogoScreen_Init_Done2:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$000E, D6
SegaLogoScreen_Init_Done3:
	CLR.w	D0
	MOVE.b	(A0)+, D0
	ORI.w	#$8000, D0
	ORI.w	#0, D0
	ADDQ.w	#2, D0
	MOVE.w	D0, VDP_data_port
	DBF	D6, SegaLogoScreen_Init_Done3
	ADDI.l	#$00800000, D5
	DBF	D7, SegaLogoScreen_Init_Done2
	ANDI	#$F8FF, SR
	JSR	EnableDisplay
	MOVE.w	#1, Palette_line_0_index.w
	MOVE.l	#SegaLogoScreen_FadeIn, obj_tick_fn(A5)
	JSR	LoadPalettesFromTable
	RTS

; SegaLogoScreen_FadeIn
; Per-frame tick: step palette index to fade in the Sega logo.
; Advances to prologue once fade is complete.
SegaLogoScreen_FadeIn:
	ADDQ.w	#1, Frame_delay_counter.w
	BTST.b	#6, IO_version
	BNE.w	SegaLogoScreen_FadeIn_Loop
	ANDI.w	#7, Frame_delay_counter.w
	BNE.b	ProloguePaletteStep_Return
	BRA.b	SegaLogoScreen_FadeIn_Loop2
SegaLogoScreen_FadeIn_Loop:
	ANDI.w	#3, Frame_delay_counter.w	
	BNE.b	ProloguePaletteStep_Return	
SegaLogoScreen_FadeIn_Loop2:
	CMPI.w	#$0010, Palette_line_0_index.w
	BLT.b	SegaLogoScreen_FadeIn_Loop3
	MOVE.b	#FLAG_TRUE, Intro_animation_done.w
	BRA.b	SegaLogoScreen_FadeIn_Loop4
SegaLogoScreen_FadeIn_Loop3:
	ADDQ.w	#1, Palette_line_0_index.w
SegaLogoScreen_FadeIn_Loop4:
	JSR	LoadPalettesFromTable
ProloguePaletteStep_Return:
	RTS

; PrologueScreen_Init
; Initialize the prologue cutscene: set palette targets, draw scene, start music.
PrologueScreen_Init:
	JSR	DisableVDPDisplay
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	MOVE.w	#PALETTE_IDX_PROLOGUE_BG, Palette_line_0_fade_target.w
	MOVE.w	#PALETTE_IDX_PROLOGUE_LINE1, Palette_line_1_fade_target.w
	MOVE.w	#PALETTE_IDX_PROLOGUE_BG, Palette_line_2_fade_target.w
	MOVE.w	#PALETTE_IDX_PROLOGUE_SCENE, Palette_line_3_fade_target.w
	MOVE.w	#PALETTE_IDX_NAMEENTRY_GLOW1, Palette_line_0_fade_in_target.w
	MOVE.w	#PALETTE_IDX_NAMEENTRY_BG, Palette_line_1_fade_in_target.w
	MOVE.w	#PALETTE_IDX_NAMEENTRY_BG, Palette_line_2_fade_in_target.w
	MOVE.w	#PALETTE_IDX_NAMEENTRY_BG, Palette_line_3_fade_in_target.w
	CLR.w	Prologue_state.w
	BSR.w	DrawPrologueScene1and2
	BSR.w	LoadPrologueFadeParams
	MOVE.b	#6, Timer_seconds_bcd.w
	JSR	EnableDisplay
	PlaySound_b	SOUND_PROLOGUE_MUSIC
	MOVE.l	#PrologueStateDispatcher, obj_tick_fn(A5)
	RTS

; LoadPrologueFadeParams
; Load fade-in/fade-out mask for the current prologue state from PrologueFadeParamData.
LoadPrologueFadeParams:
	LEA	PrologueFadeParamData, A0
	MOVE.w	Prologue_state.w, D0
	ADD.w	D0, D0
	LEA	(A0,D0.w), A0
	MOVE.b	(A0)+, D1
	CMPI.b	#1, D1
	BNE.b	LoadPrologueFadeParams_Loop
	MOVE.b	(A0), Fade_in_lines_mask.w
	BRA.b	LoadPrologueFadeParams_Return
LoadPrologueFadeParams_Loop:
	CMPI.b	#2, D1
	BNE.b	LoadPrologueFadeParams_Loop2
	MOVE.b	(A0), Fade_out_lines_mask.w
	BRA.b	LoadPrologueFadeParams_Return
LoadPrologueFadeParams_Loop2:
	CMPI.b	#3, D1
	BNE.b	LoadPrologueFadeParams_Return
	MOVE.b	(A0), Palette_fade_in_mask.w
LoadPrologueFadeParams_Return:
	RTS

; PrologueStateDispatcher
; Per-frame tick: dispatch to the handler for the current prologue state.
PrologueStateDispatcher:
	MOVE.w	Prologue_state.w, D0
	ADD.w	D0, D0
	ADD.w	D0, D0
	LEA	PrologueStateJumpTable, A0
	JSR	(A0,D0.w)
	RTS

; PrologueStateJumpTable
; Jump table indexed by Prologue_state. Each entry is a BRA to the handler for that state.
PrologueStateJumpTable:
	BRA.w	PrologueWaitAndAdvanceState
	BRA.w	PrologueWaitAndAdvanceState
	BRA.w	PrologueTick_WaitTimer
	BRA.w	PrologueTick_WaitFadeIn
	BRA.w	PrologueWaitAndAdvanceState
	BRA.w	PrologueWaitAndAdvanceState
	BRA.w	PrologueTick_WaitTimer
	BRA.w	PrologueTick_WaitFadeIn
	BRA.w	PrologueTick_WaitFadeOut
	BRA.w	PrologueStateJumpTable_Loop
	BRA.w	PrologueWaitAndAdvanceState
	BRA.w	PrologueWaitAndAdvanceState
	BRA.w	PrologueTick_WaitTimer
	BRA.w	PrologueTick_WaitFadeIn
	BRA.w	PrologueTick_WaitFadeOut
	BRA.w	DebugMaxStats_Return_Loop
	BRA.w	PrologueWaitAndAdvanceState
	BRA.w	PrologueWaitAndAdvanceState
	BRA.w	PrologueTick_WaitTimer
	BRA.w	PrologueTick_WaitFadeIn
	BRA.w	PrologueWaitAndAdvanceState
	BRA.w	PrologueWaitAndAdvanceState
	BRA.w	PrologueTick_WaitTimer
	BRA.w	PrologueTick_WaitFadeIn
	BRA.w	PrologueTick_WaitFadeOut
	BRA.w	DebugMaxStats_Return_Loop2
	BRA.w	PrologueWaitAndAdvanceState
	BRA.w	PrologueTick_WaitTimer
	BRA.w	PrologueTick_WaitFadeOut
	BRA.w	PrologueTick_WaitTimer_Loop
PrologueStateJumpTable_Loop:
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	BSR.w	DrawPrologueScene3
	MOVE.w	#PALETTE_IDX_PROLOGUE_BG, Palette_line_0_fade_target.w
	MOVE.w	#PALETTE_IDX_PROLOGUE_LINE1, Palette_line_1_fade_target.w
	MOVE.w	#PALETTE_IDX_PROLOGUE_LINE2, Palette_line_2_fade_target.w
	MOVE.w	#PALETTE_IDX_PROLOGUE_SCENE, Palette_line_3_fade_target.w
	ADDQ.w	#1, Prologue_state.w
	BSR.w	LoadPrologueFadeParams
	CMPI.l	#$8F84DE76, Player_name.w
	BNE.b	DebugMaxStats_Return
	MOVE.b	Controller_2_current_state.w, D0	
	MOVE.b	D0, D1	
	ANDI.w	#1, D0	
	BEQ.b	DebugMaxStats_Return	
	ANDI.w	#$0020, D1	
	BEQ.b	PrologueStateJumpTable_Loop2	
	MOVE.w	#$0023, D7	
	LEA	Event_triggers_start.w, A0	
PrologueStateJumpTable_Loop_Done:
	MOVE.l	#$FFFFFFFF, (A0)+ ; Fill all event triggers
	DBF	D7, PrologueStateJumpTable_Loop_Done	
PrologueStateJumpTable_Loop2:
	LEA	Towns_visited.w, A0	
	MOVE.w	#TOWN_HASTINGS1, D7	
PrologueStateJumpTable_Loop2_Done: ; god mode?
	MOVE.b	#$FF, (A0)+	
	DBF	D7, PrologueStateJumpTable_Loop2_Done	
	MOVE.w	#1, Possessed_magics_length.w	
	LEA	Possessed_magics_list.w, A0	
	MOVE.w	#((MAGIC_TYPE_FIELD<<8)|MAGIC_ARIES), (A0)	
	MOVE.w	#MAX_PLAYER_MMP, Player_mmp.w	
	MOVE.w	#MAX_PLAYER_MHP, Player_mhp.w	
	MOVE.w	#MAX_PLAYER_AC, Player_ac.w	
	MOVE.w	#MAX_PLAYER_STR, Player_str.w	
	MOVE.w	#MAX_PLAYER_DEX, Player_dex.w	
	MOVE.w	#MAX_PLAYER_INT, Player_int.w	
	MOVE.w	#MAX_PLAYER_LUK, Player_luk.w	
	MOVE.l	#MAX_PLAYER_KIMS, Player_kims.w	
DebugMaxStats_Return:
	RTS

; DebugMaxStats_Return_Loop
; Prologue state handler: draw scenes 4 and 5, update palette targets, advance state.
DebugMaxStats_Return_Loop:
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	BSR.w	DrawPrologueScene4and5
	MOVE.w	#PALETTE_IDX_PROLOGUE_BG, Palette_line_0_fade_target.w
	MOVE.w	#PALETTE_IDX_PROLOGUE_SCENE, Palette_line_1_fade_target.w
	MOVE.w	#PALETTE_IDX_PROLOGUE_BG, Palette_line_2_fade_target.w
	MOVE.w	#PALETTE_IDX_PROLOGUE_SCENE, Palette_line_3_fade_target.w
	ADDQ.w	#1, Prologue_state.w
	BSR.w	LoadPrologueFadeParams
	RTS

; DebugMaxStats_Return_Loop2
; Prologue state handler: play level-up sound, draw scene 6, advance state.
DebugMaxStats_Return_Loop2:
	PlaySound_b	SOUND_LEVEL_UP
	JSR	ClearVRAMPlaneA
	JSR	ClearVRAMPlaneB
	BSR.w	DrawPrologueScene6
	MOVE.w	#PALETTE_IDX_PROLOGUE_BG, Palette_line_0_fade_target.w
	MOVE.w	#PALETTE_IDX_PROLOGUE_SCENE, Palette_line_1_fade_target.w
	MOVE.w	#PALETTE_IDX_PROLOGUE_BG, Palette_line_2_fade_target.w
	MOVE.w	#PALETTE_IDX_PROLOGUE_SCENE, Palette_line_3_fade_target.w
	ADDQ.w	#1, Prologue_state.w
	BSR.w	LoadPrologueFadeParams
	RTS

; PrologueTick_WaitFadeOut
; Wait until fade-out completes, then advance to next prologue state.
PrologueTick_WaitFadeOut:
	TST.b	Fade_out_lines_mask.w
	BNE.b	PrologueTick_WaitFadeOut_Loop
	ADDQ.w	#1, Prologue_state.w
	BSR.w	LoadPrologueFadeParams
PrologueTick_WaitFadeOut_Loop:
	RTS

; PrologueWaitAndAdvanceState
; Wait until fade-in completes, reset display timer, then advance prologue state.
PrologueWaitAndAdvanceState:
	TST.b	Fade_in_lines_mask.w
	BNE.b	PrologueWaitAndAdvanceState_Loop
	MOVE.b	#6, Timer_seconds_bcd.w
	ADDQ.w	#1, Prologue_state.w
	BSR.w	LoadPrologueFadeParams
PrologueWaitAndAdvanceState_Loop:
	RTS

; PrologueTick_WaitFadeIn
; Wait until cross-fade completes, then advance to next prologue state.
PrologueTick_WaitFadeIn:
	TST.b	Palette_fade_in_mask.w
	BNE.b	PrologueTick_WaitFadeIn_Loop
	ADDQ.w	#1, Prologue_state.w
	BSR.w	LoadPrologueFadeParams
PrologueTick_WaitFadeIn_Loop:
	RTS

; PrologueTick_WaitTimer
; Decrement BCD display timer; advance prologue state when it reaches zero.
PrologueTick_WaitTimer:
	JSR	DecrementTimerBCD
	BEQ.b	PrologueTick_WaitTimer_Loop2
	RTS

PrologueTick_WaitTimer_Loop2:
	ADDQ.w	#1, Prologue_state.w
	BRA.w	LoadPrologueFadeParams
PrologueTick_WaitTimer_Loop:
	MOVE.b	#FLAG_TRUE, Prologue_complete_flag.w
	MOVE.l	#Prologue_EmptyCallback, obj_tick_fn(A5)
	RTS

; Prologue_EmptyCallback
; No-op tick handler; installed after prologue is fully complete.
Prologue_EmptyCallback:
	RTS

; DrawPrologueScene1and2
; Render prologue scenes 1 and 2 tilemaps and text strings to VRAM.
DrawPrologueScene1and2:
	ORI	#$0700, SR
	MOVE.l	#$60B00003, D5
	MOVE.w	#$A300, D4
	BSR.w	DrawTilemapBlock_15x12
	MOVE.l	#$61320003, D5
	LEA	DrawPrologueScene1and2_Data, A0
	MOVE.w	#$A080, D4
	BSR.w	DrawTilemapBlock_13x10
	MOVE.l	#$61060003, D5
	LEA	Prologue1Str, A0
	MOVE.w	#$84C0, D4
	BSR.w	DrawVerticalText
	MOVE.l	#$67840003, D5
	MOVE.w	#$E300, D4
	BSR.w	DrawTilemapBlock_15x12
	MOVE.l	#$68060003, D5
	LEA	DrawPrologueScene1and2_Data2, A0
	MOVE.w	#$E100, D4
	BSR.w	DrawTilemapBlock_13x10
	MOVE.l	#$67A40003, D5
	LEA	Prologue2Str, A0
	MOVE.w	#$C4C0, D4
	BSR.w	DrawVerticalText
	ANDI	#$F8FF, SR
	RTS

