; ===========================================================================
; src/miscdata.asm
; Miscellaneous Game Data
; Debug/test menu (DebugTestMenu), boss parallax init tables,
; battle animation frames, NPC sprite frames
; ===========================================================================

; ---------------------------------------------------------------------------
; DebugTestMenu — factory debug/test menu dispatcher ($3C6E8)
;
; Called via JSR from game init (MOVE.l #DebugTestMenu, $42(A7) at $11DE).
; Presents a scrolling menu: INPUT TEST / SOUND TEST / C.R.T. TEST / EXIT.
; Never returns normally — exits by JMP EntryPoint.
;
; Register usage (throughout this section):
;   D5.l  current VDP HScroll write-address register value
;   D2.w  button mask for CheckButtonPress
;   D3.w  exit flag (non-zero = leave input-test loop)
;   A0    pointer to BossParallaxEntry_Start parameter record
; ---------------------------------------------------------------------------

; loc_003C6E8
DebugTestMenu:
	TST.b	Fade_out_lines_mask.w           ; wait for any pending fade to clear
	BNE.b	DebugTestMenu                   ; loop until zero
	MOVE.b	#$00, D0
	JSR	QueueSoundEffect                ; silence music
	JSR	DisableVDPDisplay
	JSR	loc_000010D8                    ; CLR Vblank_flag + WaitForVBlank
	MOVE.w	VDP_Reg11_cache.w, D0           ; read cached VDP register 11 (HScroll mode)
	ANDI.w	#$FFF8, D0                      ; mask off HScroll mode bits
	MOVE.w	D0, VDP_control_port            ; write back (set full-screen HScroll)
	MOVE.w	#$0000, $FFFFC104.w             ; HScroll_base = 0
	MOVE.w	#$0000, $FFFFC106.w             ; VScroll_base = 0
	MOVE.w	#$004F, Palette_line_0_index.w  ; palette slot 0 → index $4F
	MOVE.w	#$0053, Palette_line_1_index.w  ; palette slot 1 → index $53
	MOVE.w	#$0054, Palette_line_2_index.w  ; palette slot 2 → index $54
	MOVE.w	#$0001, Palette_line_3_index.w  ; palette slot 3 → index $01
	JSR	LoadPalettesFromTable
	JSR	EnableDisplay
	MOVE.l	#$44040003, D5                  ; VDP write addr for first menu tile row
	MOVE.l	D5, DebugMenu_vdp_cursor.w
	CLR.w	DebugMenu_selected_item.w
	CLR.w	DebugMenu_scroll_pos.w
	JSR	loc_00000396                    ; clear VRAM HScroll/PlaneA/PlaneB/sprites/VSRAM
	LEA	loc_0003D1BC, A0                ; parallax row 0 config
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D1D0, A0                ; parallax row 1 config
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D1E4, A0                ; parallax row 2 config
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D1F8, A0                ; parallax row 3 config
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D204, A0                ; parallax row 4 config (shared footer)
	JSR	BossParallaxEntry_Start
DebugTestMenu_WaitLoop:
	JSR	WaitForVBlank
	MOVE.b	#$00, D0
	JSR	QueueSoundEffect                ; keep music silent each frame
	BSR.w	DebugMenu_ScrollTick            ; update scroll + advance menu cursor
	MOVE.w	#$0006, D2                      ; check A or B button
	JSR	CheckButtonPress
	BEQ.b	DebugTestMenu_WaitLoop          ; no button → keep waiting
	MOVE.w	DebugMenu_selected_item.w, D0
	CMPI.w	#$0004, D0                      ; past last item?
	BGT.w	DebugTestMenu_Exit              ; yes → exit to game
	BRA.w	DebugTestMenu_Dispatch
	BRA.b	DebugTestMenu_WaitLoop          ; (unreachable — branch over jump table)
DebugTestMenu_Dispatch:
	ADD.w	D0, D0                          ; index × 4 (each entry is a BRA.w = 4 bytes)
	ADD.w	D0, D0
	JSR	DebugMainMenu_JumpTable(PC,D0.w)
	; --- jump table base at $3C7D4 (D0=0 → INPUT TEST) ---
	BRA.w	DebugTestMenu                   ; $3C7D0  D0=-1 (unreachable guard)
DebugMainMenu_JumpTable:
	BRA.w	DebugInputTest                  ; $3C7D4  item 0
	BRA.w	DebugSoundTest                  ; $3C7D8  item 1
	BRA.w	DebugCRTTest                    ; $3C7DC  item 2
	BRA.w	DebugTestMenu_NoOp              ; $3C7E0  item 3 (empty)
	BRA.w	DebugTestMenu_Exit              ; $3C7E4  item 4 (EXIT)

; ---------------------------------------------------------------------------
; DebugInputTest — show controller button state ($3C7E8)
; Draws 9 button indicators (Up/Down/Left/Right/A/B/C/Start + all-pressed)
; and loops until A+B+C+Start are all held simultaneously.
; ---------------------------------------------------------------------------
DebugInputTest:
	JSR	loc_000010D8                    ; CLR Vblank_flag + WaitForVBlank
	MOVE.w	#$004F, Palette_line_0_index.w
	MOVE.w	#$0053, Palette_line_1_index.w
	MOVE.w	#$0054, Palette_line_2_index.w
	JSR	LoadPalettesFromTable
	JSR	loc_00000396                    ; clear VRAM
	LEA	loc_0003D22C, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D236, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D242, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D24E, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D25C, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D266, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D270, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D27A, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D288, A0
	JSR	BossParallaxEntry_Start
DebugInputTest_Loop:
	JSR	ReadControllers
	CLR.w	D2
	MOVE.b	Controller_current_state.w, D2 ; load current button bits into D2
	; Directional buttons — draw tile using D0=VDP write addr, D1=tile index
	MOVE.l	#$45960003, D0
	MOVE.l	#$000004DE, D1              ; tile $04DE = "UP" indicator (released state)
	BTST	#0, D2                      ; bit 0 = Up
	BSR.w	DebugInput_DrawDirectionBtn
	MOVE.l	#$48960003, D0
	MOVE.l	#$000004DF, D1              ; tile $04DF = "DOWN" indicator
	BTST	#1, D2                      ; bit 1 = Down
	BSR.w	DebugInput_DrawDirectionBtn
	MOVE.l	#$47100003, D0
	MOVE.l	#$000004DD, D1              ; tile $04DD = "LEFT" indicator
	BTST	#2, D2                      ; bit 2 = Left
	BSR.w	DebugInput_DrawDirectionBtn
	MOVE.l	#$471C0003, D0
	MOVE.l	#$000004DC, D1              ; tile $04DC = "RIGHT" indicator
	BTST	#3, D2                      ; bit 3 = Right
	BSR.w	DebugInput_DrawDirectionBtn
	; Action buttons — draw solid/hollow box tile (no tile index needed)
	MOVE.l	#$4B320003, D0
	BTST	#6, D2                      ; bit 6 = A
	BSR.w	DebugInput_DrawActionBtn
	MOVE.l	#$49B80003, D0
	BTST	#4, D2                      ; bit 4 = B
	BSR.w	DebugInput_DrawActionBtn
	MOVE.l	#$483E0003, D0
	BTST	#5, D2                      ; bit 5 = C
	BSR.w	DebugInput_DrawActionBtn
	MOVE.l	#$443C0003, D0
	BTST	#7, D2                      ; bit 7 = Start
	BSR.w	DebugInput_DrawActionBtn
	BSR.w	DebugInput_CheckAllPressed  ; sets D3.w if A+B+C+Start all held
	TST.w	D3
	BEQ.w	DebugInputTest_Loop         ; not all pressed → keep reading
	RTS                                 ; all pressed → return to main menu loop

; DebugInput_DrawActionBtn — draw action-button tile (pressed or not) ($3C918)
;   In:  D0.l = VDP write-address command, D2.w = buttons, Z flag = button state
;   Side-effect: uses VDP_data_port to write 3 tile words
DebugInput_DrawActionBtn:
	BNE.w	DebugInput_DrawActionBtn_Pressed
	MOVE.l	D0, VDP_control_port
	MOVE.w	#$250F, VDP_data_port        ; tile $250F (released: hollow box top)
	MOVE.w	#$2506, VDP_data_port        ; tile $2506 (released: hollow box mid)
	MOVE.w	#$2506, VDP_data_port        ; tile $2506 (released: hollow box bot)
	RTS
DebugInput_DrawActionBtn_Pressed:
	MOVE.l	D0, VDP_control_port
	MOVE.w	#$450F, VDP_data_port        ; tile $450F (pressed: solid box top)
	MOVE.w	#$450E, VDP_data_port        ; tile $450E (pressed: solid box mid)
	MOVE.w	#$44C0, VDP_data_port        ; tile $44C0 (pressed: solid box bot)
	RTS

; DebugInput_DrawDirectionBtn — draw direction tile (Z=0: released, Z=1: pressed) ($3C95C)
;   In:  D0.l = VDP write-address command, D1.w = tile index for released state
DebugInput_DrawDirectionBtn:
	BNE.w	DebugInput_DrawDirectionBtn_Pressed
	MOVE.l	D0, VDP_control_port
	MOVE.w	D1, VDP_data_port
	RTS
DebugInput_DrawDirectionBtn_Pressed:
	ADDI.w	#$4000, D1                   ; flip palette bit (pressed highlight)
	MOVE.l	D0, VDP_control_port
	MOVE.w	D1, VDP_data_port
	RTS

; DebugInput_CheckAllPressed — set D3.w=1 if A+B+C+Start all held ($3C980)
DebugInput_CheckAllPressed:
	CLR.w	D3
	BTST	#6, D2                       ; A
	BEQ.b	DebugInput_CheckAllPressed_Done
	BTST	#4, D2                       ; B
	BEQ.b	DebugInput_CheckAllPressed_Done
	BTST	#5, D2                       ; C
	BEQ.b	DebugInput_CheckAllPressed_Done
	BTST	#7, D2                       ; Start
	BEQ.b	DebugInput_CheckAllPressed_Done
	MOVE.w	#$0001, D3
DebugInput_CheckAllPressed_Done:
	RTS

; ---------------------------------------------------------------------------
; DebugSoundTest — sound-test menu ($3C9A0)
; Presents a scrollable list of BGM/effect entries for all sound categories.
; Pressing a button plays the selected sound.  EXITS back to main menu on
; reaching item ≥ $14 (20 entries per category).
; ---------------------------------------------------------------------------
DebugSoundTest:
	JSR	QueueSoundEffect
	JSR	DisableVDPDisplay
	JSR	loc_000010D8                    ; CLR Vblank_flag + WaitForVBlank
	JSR	EnableDisplay
	MOVE.l	#$44040003, D5
	MOVE.l	D5, DebugMenu_vdp_cursor.w
	CLR.w	DebugMenu_selected_item.w
	CLR.w	DebugMenu_scroll_pos.w
	JSR	loc_00000396                    ; clear VRAM
	LEA	loc_0003D29A, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D2AA, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D2BC, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D2CE, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D1F8, A0                ; shared footer row
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D204, A0                ; shared footer row
	JSR	BossParallaxEntry_Start
DebugSoundTest_WaitLoop:
	JSR	WaitForVBlank
	MOVE.b	#$00, D0
	JSR	QueueSoundEffect
	BSR.w	DebugMenu_ScrollTick
	MOVE.w	#$0006, D2
	JSR	CheckButtonPress
	BEQ.b	DebugSoundTest_WaitLoop
	MOVE.w	DebugMenu_selected_item.w, D0
	CMPI.w	#$0004, D0                      ; ≥4 → EXIT
	BGE.w	DebugSoundTest_Return
	MOVE.w	D0, DebugMenu_sound_category.w  ; save selected category (0-3)
	BSR.w	DebugSoundCategory_Menu         ; open sub-menu for this category
	BRA.w	DebugSoundTest
DebugSoundTest_Return:
	RTS

; DebugSoundCategory_Menu — sub-menu that scrolls through entries for one category ($3CA52)
;   In:  DebugMenu_sound_category.w = category index (0-3)
DebugSoundCategory_Menu:
	JSR	loc_000010D8                    ; CLR Vblank_flag + WaitForVBlank
	MOVE.b	#$01, DebugMenu_in_submenu.w    ; flag: inside sub-menu
	MOVE.l	#$42040003, D5
	MOVE.l	D5, DebugMenu_vdp_cursor.w
	CLR.w	DebugMenu_sound_item.w
	CLR.w	DebugMenu_scroll_pos.w
	JSR	loc_00000396                    ; clear VRAM
	MOVE.w	DebugMenu_sound_category.w, D0
	ADD.w	D0, D0                          ; category × 4
	ADD.w	D0, D0
	JSR	DebugSoundCategory_JumpTable(PC,D0.w)
DebugSoundCategory_SubWaitLoop:             ; shared wait loop for all categories ($3CA82)
	JSR	WaitForVBlank
	BSR.w	DebugMenu_ScrollTick
	MOVE.w	#$0006, D2
	JSR	CheckButtonPress
	BEQ.b	DebugSoundCategory_SubWaitLoop
	MOVE.w	DebugMenu_sound_item.w, D1
	CMPI.w	#$0013, D1                      ; ≥ 19 entries → exit sub-menu
	BGE.w	DebugSoundCategory_SubDone
	LEA	loc_0003D880, A0                ; pointer table: category → sound-ID table
	MOVE.w	DebugMenu_sound_category.w, D0
	ADD.w	D0, D0                          ; category × 4 (long pointers)
	ADD.w	D0, D0
	MOVE.l	+0(A0,D0.w), A1                 ; A1 → sound-ID array for this category
	ADD.w	D1, D1                          ; item × 2 (word entries)
	MOVE.w	+0(A1,D1.w), D0                 ; D0 = sound ID
	JSR	QueueSoundEffect                ; play selected sound
	BRA.b	DebugSoundCategory_SubWaitLoop
DebugSoundCategory_SubDone:
	CLR.b	DebugMenu_in_submenu.w
	RTS
	; --- jump table base at $3CACA ---
DebugSoundCategory_JumpTable:
	BRA.w	DebugSoundCategory_BGM          ; $3CACA  cat 0 = BGM
	BRA.w	DebugSoundCategory_Effect       ; $3CACE  cat 1 = Effect
	BRA.w	DebugSoundCategory_BGM2         ; $3CAD2  cat 2 = BGM 2
	BRA.w	DebugSoundCategory_DA           ; $3CAD6  cat 3 = D/A

; DebugSoundCategory_BGM ($3CADA) — load BGM parallax tiles then enter sub-loop
DebugSoundCategory_BGM:
	LEA	loc_0003D2DE, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D2F0, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D300, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D314, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D324, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D334, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D348, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D35A, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D370, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D388, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D39A, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D3AC, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D3C0, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D3D2, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D3E4, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D3F6, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D408, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D41A, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D430, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D446, A0                ; shared footer row
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D456, A0                ; shared footer row
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D204, A0                ; shared footer row
	JSR	BossParallaxEntry_Start
	RTS

; DebugSoundCategory_Effect ($3CBE4) — load Effect parallax tiles
DebugSoundCategory_Effect:
	LEA	loc_0003D468, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D47E, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D494, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D4AC, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D4C4, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D4D6, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D4EA, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D4F8, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D506, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D51C, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D530, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D546, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D556, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D568, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D578, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D58A, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D59C, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D5B0, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D5C2, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D446, A0                ; shared footer row
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D456, A0                ; shared footer row
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D204, A0                ; shared footer row
	JSR	BossParallaxEntry_Start
	RTS

; DebugSoundCategory_BGM2 ($3CCEE) — load BGM2 parallax tiles
DebugSoundCategory_BGM2:
	LEA	loc_0003D5D2, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D5E8, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D5F6, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D608, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D616, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D628, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D63C, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D652, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D666, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D676, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D68A, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D6A0, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D6B4, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D6CA, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D6DE, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D6EA, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D6F6, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D702, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D70E, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D446, A0                ; shared footer row
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D456, A0                ; shared footer row
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D204, A0                ; shared footer row
	JSR	BossParallaxEntry_Start
	RTS

; DebugSoundCategory_DA ($3CDF8) — load D/A parallax tiles
DebugSoundCategory_DA:
	LEA	loc_0003D71A, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D730, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D744, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D75A, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D76E, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D786, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D79C, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D7AE, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D7C0, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D7D2, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D7E4, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D7F0, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D7FC, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D808, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D814, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D820, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D82C, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D838, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D844, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D446, A0                ; shared footer row
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D456, A0                ; shared footer row
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D204, A0                ; shared footer row
	JSR	BossParallaxEntry_Start
	RTS

; ---------------------------------------------------------------------------
; DebugCRTTest — CRT display test, fills screen with colour gradient ($3CF02)
; ---------------------------------------------------------------------------
DebugCRTTest:
	JSR	loc_000010D8                    ; CLR Vblank_flag + WaitForVBlank
	JSR	loc_00000396                    ; clear VRAM
	LEA	loc_0003D850, A0
	JSR	BossParallaxEntry_Start
	LEA	loc_0003D862, A0
	JSR	BossParallaxEntry_Start
	BSR.w	DebugCRT_DrawGrayGradient       ; draw 8×16 gray ramp on screen
	MOVE.w	#$0055, Palette_line_0_index.w
	MOVE.w	#$0056, Palette_line_1_index.w
	MOVE.w	#$0057, Palette_line_2_index.w
	MOVE.w	#$0058, Palette_line_3_index.w
	JSR	LoadPalettesFromTable
	BSR.w	DebugCRT_DrawColorRow0          ; draw colour-bar row 0
	BSR.w	DebugCRT_DrawColorRow1          ; draw colour-bar row 1
	BSR.w	DebugCRT_DrawColorRow2          ; draw colour-bar row 2
	BSR.w	DebugCRT_DrawColorRow3          ; draw colour-bar row 3
DebugCRTTest_WaitLoop:
	MOVE.w	#$0005, D2
	JSR	CheckButtonPress
	BEQ.b	DebugCRTTest_WaitLoop           ; wait for any button
	RTS

; DebugCRT_DrawGrayGradient — write 8×16 gray-ramp tiles directly to VRAM ($3CF66)
; Disables interrupts, writes 8 rows of 16 tiles each, incrementing colour $1111 per row.
DebugCRT_DrawGrayGradient:
	CLR.w	D0
	MOVE.w	#$1111, D0                      ; starting palette entry (dark gray)
	ORI	#$0700, SR                      ; disable interrupts
	MOVE.l	#$4F400001, VDP_control_port    ; set VDP write address for first tile
	MOVE.w	#$0007, D2                      ; 8 rows (7 downto 0)
DebugCRT_GrayGrad_RowLoop:
	MOVE.w	#$000F, D1                      ; 16 tiles per row (15 downto 0)
DebugCRT_GrayGrad_TileLoop:
	MOVE.w	D0, VDP_data_port               ; write tile colour word
	DBF	D1, DebugCRT_GrayGrad_TileLoop
	ADDI.w	#$1111, D0                      ; next shade
	DBF	D2, DebugCRT_GrayGrad_RowLoop
	ANDI	#$F8FF, SR                      ; re-enable interrupts
	RTS

; DebugCRT_DrawColorRow0-3 — write 3-row colour bars using palette offset in D5 ($3CF9A-$3CFCA)
DebugCRT_DrawColorRow0:
	MOVE.l	#$63100003, D5              ; VDP write addr for row 0
	MOVE.w	#$827A, D4                  ; starting colour word
	BSR.w	DebugCRT_DrawColorStrip
	RTS
DebugCRT_DrawColorRow1:
	MOVE.l	#$65100003, D5
	MOVE.w	#$A27A, D4
	BSR.w	DebugCRT_DrawColorStrip
	RTS
DebugCRT_DrawColorRow2:
	MOVE.l	#$67100003, D5
	MOVE.w	#$C27A, D4
	BSR.w	DebugCRT_DrawColorStrip
	RTS
DebugCRT_DrawColorRow3:
	MOVE.l	#$69100003, D5
	MOVE.w	#$E27A, D4
	BSR.w	DebugCRT_DrawColorStrip
	RTS

; DebugCRT_DrawColorStrip — draw one 3-row colour strip ($3CFDA)
;   In:  D5.l = VDP control word (write address),  D4.w = starting colour index
;   Writes 3 rows × 8 groups × 3 tiles each, incrementing colour index each group.
DebugCRT_DrawColorStrip:
	ORI	#$0700, SR                      ; disable interrupts
	MOVE.w	#$0002, D3                      ; 3 rows (2 downto 0)
DebugCRT_ColorStrip_RowLoop:
	MOVE.l	D5, VDP_control_port
	MOVE.w	D4, D0
	MOVE.w	#$0007, D2                      ; 8 groups per row
DebugCRT_ColorStrip_GroupLoop:
	MOVE.w	#$0002, D1                      ; 3 tiles per group
DebugCRT_ColorStrip_TileLoop:
	MOVE.w	D0, VDP_data_port
	DBF	D1, DebugCRT_ColorStrip_TileLoop
	ADDQ.w	#1, D0                          ; next colour
	DBF	D2, DebugCRT_ColorStrip_GroupLoop
	ADDI.l	#$800000, D5                    ; advance VDP write address by 1 row
	DBF	D3, DebugCRT_ColorStrip_RowLoop
	ANDI	#$F8FF, SR                      ; re-enable interrupts
	RTS

; DebugTestMenu_NoOp — empty menu item stub ($3D012)
DebugTestMenu_NoOp:
	RTS

; DebugTestMenu_Exit — wait one vblank, clear skip flag, restart game ($3D014)
DebugTestMenu_Exit:
	JSR	WaitForVBlank
	CLR.b	Skip_tilemap_updates.w
	JMP	EntryPoint

; ---------------------------------------------------------------------------
; DebugMenu_ScrollTick — update horizontal scroll each frame ($3D024)
;
; Reads left/right from Controller_previous_state, adds ±1 to scroll_pos.
; When scroll_pos reaches ±8 (full tile width), advances/retreats the selected
; menu item and writes the HScroll tile to VRAM.
; D5.l in/out = current VDP write-address register value (cached).
; ---------------------------------------------------------------------------
DebugMenu_ScrollTick:
	MOVE.l	DebugMenu_vdp_cursor.w, D5
	MOVEQ	#0, D0
	BTST	#0, Controller_previous_state.w    ; left bit
	BEQ.b	DebugMenu_ScrollTick_CheckRight
	MOVEQ	#-1, D0                             ; scrolling left
	BRA.b	DebugMenu_ScrollTick_Apply
DebugMenu_ScrollTick_CheckRight:
	BTST	#1, Controller_previous_state.w    ; right bit
	BEQ.b	DebugMenu_ScrollTick_Apply
	MOVEQ	#1, D0                              ; scrolling right
DebugMenu_ScrollTick_Apply:
	ADD.w	D0, DebugMenu_scroll_pos.w
	MOVE.w	DebugMenu_scroll_pos.w, D1
	CMPI.w	#$0008, D1                          ; reached +8 pixels?
	BGT.w	DebugMenu_ScrollTick_NextItem
	CMPI.w	#$FFF8, D1                          ; reached −8 pixels?
	BLT.w	DebugMenu_ScrollTick_PrevItem
	; still within ±8 — just write HScroll value
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$04DC, VDP_data_port               ; HScroll value (tile scroll position)
	MOVE.l	D5, DebugMenu_vdp_cursor.w
	RTS
DebugMenu_ScrollTick_NextItem:                  ; scroll_pos > +8 → advance item
	TST.b	DebugMenu_in_submenu.w
	BNE.w	DebugMenu_ScrollTick_NextSubItem
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$0000, VDP_data_port
	SUBQ.w	#8, DebugMenu_scroll_pos.w          ; subtract 8 pixels (one tile step)
	ADDI.l	#$1000000, D5                       ; advance VDP row pointer
	ADDQ.w	#1, DebugMenu_selected_item.w
	CMPI.w	#$0004, DebugMenu_selected_item.w   ; wraparound at item 4?
	BNE.b	DebugMenu_ScrollTick_NextItem_Check
	MOVE.l	#$4A040003, D5                      ; special VDP addr for item 4
	BRA.b	DebugMenu_ScrollTick_NextItem_Done
DebugMenu_ScrollTick_NextItem_Check:
	CMPI.w	#$0004, DebugMenu_selected_item.w
	BCS.b	DebugMenu_ScrollTick_NextItem_Done  ; < 4 → no wrap
	MOVE.l	#$44040003, D5                      ; reset VDP addr to item 0
	CLR.w	DebugMenu_selected_item.w
DebugMenu_ScrollTick_NextItem_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$04DC, VDP_data_port
	MOVE.l	D5, DebugMenu_vdp_cursor.w
	RTS
DebugMenu_ScrollTick_NextSubItem:               ; in sub-menu: advance sound item
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$0000, VDP_data_port
	SUBQ.w	#8, DebugMenu_scroll_pos.w
	ADDI.l	#$1000000, D5
	ADDQ.w	#1, DebugMenu_sound_item.w
	CMPI.w	#$0014, DebugMenu_sound_item.w      ; wraparound at 20 items?
	BCS.b	DebugMenu_ScrollTick_NextSubItem_Check
	MOVE.l	#$42040003, D5
	CLR.w	DebugMenu_sound_item.w
	BRA.b	DebugMenu_ScrollTick_NextSubItem_Done
DebugMenu_ScrollTick_NextSubItem_Check:
	CMPI.w	#$000A, DebugMenu_sound_item.w      ; item 10 → special VDP addr
	BNE.b	DebugMenu_ScrollTick_NextSubItem_Done
	MOVE.l	#$422C0003, D5
DebugMenu_ScrollTick_NextSubItem_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$04DC, VDP_data_port
	MOVE.l	D5, DebugMenu_vdp_cursor.w
	RTS
DebugMenu_ScrollTick_PrevItem:                  ; scroll_pos < −8 → retreat item
	TST.b	DebugMenu_in_submenu.w
	BNE.w	DebugMenu_ScrollTick_PrevSubItem
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$0000, VDP_data_port
	ADDQ.w	#8, DebugMenu_scroll_pos.w          ; add 8 pixels (one tile step back)
	SUBI.l	#$1000000, D5                       ; retreat VDP row pointer
	SUBQ.w	#1, DebugMenu_selected_item.w
	BCC.b	DebugMenu_ScrollTick_PrevItem_Check ; no underflow → check for item 3
	MOVE.l	#$4A040003, D5
	MOVE.w	#$0004, DebugMenu_selected_item.w   ; wrap to item 4
	BRA.b	DebugMenu_ScrollTick_PrevItem_Done
DebugMenu_ScrollTick_PrevItem_Check:
	CMPI.w	#$0003, DebugMenu_selected_item.w   ; item 3 → special VDP addr
	BNE.b	DebugMenu_ScrollTick_PrevItem_Done
	MOVE.l	#$47040003, D5
DebugMenu_ScrollTick_PrevItem_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$04DC, VDP_data_port
	MOVE.l	D5, DebugMenu_vdp_cursor.w
	RTS
DebugMenu_ScrollTick_PrevSubItem:               ; in sub-menu: retreat sound item
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$0000, VDP_data_port
	ADDQ.w	#8, DebugMenu_scroll_pos.w
	SUBI.l	#$1000000, D5
	SUBQ.w	#1, DebugMenu_sound_item.w
	BCC.b	DebugMenu_ScrollTick_PrevSubItem_Check ; no underflow
	MOVE.l	#$4B2C0003, D5
	MOVE.w	#$0013, DebugMenu_sound_item.w      ; wrap to item 19
	BRA.b	DebugMenu_ScrollTick_PrevSubItem_Done
DebugMenu_ScrollTick_PrevSubItem_Check:
	CMPI.w	#$0009, DebugMenu_sound_item.w      ; item 9 → special VDP addr
	BNE.b	DebugMenu_ScrollTick_PrevSubItem_Done
	MOVE.l	#$4B040003, D5
DebugMenu_ScrollTick_PrevSubItem_Done:
	MOVE.l	D5, VDP_control_port
	MOVE.w	#$04DC, VDP_data_port
	MOVE.l	D5, DebugMenu_vdp_cursor.w
	RTS

; ---------------------------------------------------------------------------
; BossParallaxEntry data records begin here ($3D1BC)
; Each record: dc.l VDP-control-word, dc.w column-count, dc.w base-offset,
;              then (column-count+1) bytes of HScroll data
; ---------------------------------------------------------------------------
loc_0003D1BC:
	dc.b	$44, $08, $00, $03, $00, $0B, $84, $C0, $49, $4E, $50, $55, $54, $20, $20, $20
	dc.b	$54, $45, $53, $54
loc_0003D1D0:
	dc.b	$45, $08, $00, $03, $00, $0B, $84, $C0, $53, $4F, $55, $4E, $44, $20, $20, $20
	dc.b	$54, $45, $53, $54
loc_0003D1E4:
	dc.b	$46, $08, $00, $03, $00, $0B, $84, $C0, $43, $2E, $52, $2E, $54, $2E, $20, $20
	dc.b	$54, $45, $53, $54
loc_0003D1F8:
	dc.b	$4A, $08, $00, $03, $00, $03, $84, $C0, $45, $58, $49, $54
loc_0003D204:
	dc.b	$4D, $06, $00, $03, $00, $1E, $84, $C0, $53, $45, $4C, $45, $43, $54, $20, $42
	dc.b	$59, $20, $53, $54, $49, $43, $4B, $21, $20, $50, $55, $53, $48, $20, $41, $20
	dc.b	$42, $55, $54, $54, $4F, $4E, $21, $00
loc_0003D22C:
	dc.b	$44, $16, $00, $03, $00, $01, $84, $C0, $55, $50
loc_0003D236:
	dc.b	$4A, $14, $00, $03, $00, $03, $84, $C0, $44, $4F, $57, $4E
loc_0003D242:
	dc.b	$47, $06, $00, $03, $00, $03, $84, $C0, $4C, $45, $46, $54
loc_0003D24E:
	dc.b	$47, $20, $00, $03, $00, $04, $84, $C0, $52, $49, $47, $48, $54, $00
loc_0003D25C:
	dc.b	$4B, $2E, $00, $03, $00, $00, $84, $C0, $41, $00
loc_0003D266:
	dc.b	$49, $B4, $00, $03, $00, $00, $84, $C0, $42, $00
loc_0003D270:
	dc.b	$48, $3A, $00, $03, $00, $00, $84, $C0, $43, $00
loc_0003D27A:
	dc.b	$44, $30, $00, $03, $00, $04, $84, $C0, $53, $54, $41, $52, $54, $00
loc_0003D288:
	dc.b	$40, $9C, $00, $03, $00, $09, $A4, $C0, $49, $4E, $50, $55, $54, $20, $54, $45
	dc.b	$53, $54
loc_0003D29A:
	dc.b	$44, $08, $00, $03, $00, $06, $84, $C0, $31, $2E, $20, $20, $42, $47, $4D, $00
loc_0003D2AA:
	dc.b	$45, $08, $00, $03, $00, $09, $84, $C0, $32, $2E, $20, $20, $45, $46, $46, $45
	dc.b	$43, $54
loc_0003D2BC:
	dc.b	$46, $08, $00, $03, $00, $08, $84, $C0, $33, $2E, $20, $20, $42, $47, $4D, $20
	dc.b	$32, $00
loc_0003D2CE:
	dc.b	$47, $08, $00, $03, $00, $06, $84, $C0, $34, $2E, $20, $20, $44, $2F, $41, $00
loc_0003D2DE:
	dc.b	$42, $0A, $00, $03, $00, $08, $84, $C0, $31, $2E, $4F, $50, $45, $4E, $49, $4E
	dc.b	$47, $00
loc_0003D2F0:
	dc.b	$43, $0A, $00, $03, $00, $06, $84, $C0, $32, $2E, $54, $49, $54, $4C, $45, $00
loc_0003D300:
	dc.b	$44, $0A, $00, $03, $00, $0B, $84, $C0, $33, $2E, $4E, $41, $4D, $45, $20, $45
	dc.b	$4E, $54, $52, $59
loc_0003D314:
	dc.b	$45, $0A, $00, $03, $00, $07, $84, $C0, $34, $2E, $53, $54, $41, $54, $54, $53
loc_0003D324:
	dc.b	$46, $0A, $00, $03, $00, $06, $84, $C0, $35, $2E, $45, $52, $49, $41, $53, $00
loc_0003D334:
	dc.b	$47, $0A, $00, $03, $00, $0A, $84, $C0, $36, $2E, $56, $49, $4C, $4C, $41, $47
	dc.b	$45, $20, $41, $00
loc_0003D348:
	dc.b	$48, $0A, $00, $03, $00, $08, $84, $C0, $37, $2E, $46, $55, $59, $4F, $44, $4F
	dc.b	$4C, $00
loc_0003D35A:
	dc.b	$49, $0A, $00, $03, $00, $0C, $84, $C0, $38, $2E, $53, $48, $4F, $50, $20, $28
	dc.b	$43, $49, $54, $59, $29, $00
loc_0003D370:
	dc.b	$4A, $0A, $00, $03, $00, $0F, $84, $C0, $39, $2E, $53, $48, $4F, $50, $20, $28
	dc.b	$56, $49, $4C, $4C, $41, $47, $45, $29
loc_0003D388:
	dc.b	$4B, $08, $00, $03, $00, $08, $84, $C0, $31, $30, $2E, $43, $48, $55, $52, $43
	dc.b	$48, $00
loc_0003D39A:
	dc.b	$42, $30, $00, $03, $00, $09, $84, $C0, $31, $31, $2E, $44, $55, $4E, $47, $45
	dc.b	$4F, $4E
loc_0003D3AC:
	dc.b	$43, $30, $00, $03, $00, $0B, $84, $C0, $31, $32, $2E, $44, $55, $4E, $47, $45
	dc.b	$4F, $4E, $20, $32
loc_0003D3C0:
	dc.b	$44, $30, $00, $03, $00, $08, $84, $C0, $31, $33, $2E, $42, $4F, $53, $53, $20
	dc.b	$41, $00
loc_0003D3D2:
	dc.b	$45, $30, $00, $03, $00, $08, $84, $C0, $31, $34, $2E, $42, $4F, $53, $53, $20
	dc.b	$42, $00
loc_0003D3E4:
	dc.b	$46, $30, $00, $03, $00, $09, $84, $C0, $31, $35, $2E, $33, $44, $20, $4D, $4F
	dc.b	$44, $45
loc_0003D3F6:
	dc.b	$47, $30, $00, $03, $00, $08, $84, $C0, $31, $36, $2E, $42, $41, $54, $54, $4C
	dc.b	$45, $00
loc_0003D408:
	dc.b	$48, $30, $00, $03, $00, $08, $84, $C0, $31, $37, $2E, $43, $41, $53, $54, $4C
	dc.b	$45, $00
loc_0003D41A:
	dc.b	$49, $30, $00, $03, $00, $0D, $84, $C0, $31, $38, $2E, $50, $4C, $41, $59, $45
	dc.b	$52, $20, $44, $45, $41, $44
loc_0003D430:
	dc.b	$4A, $30, $00, $03, $00, $0C, $84, $C0, $31, $39, $2E, $4A, $49, $4A, $49, $20
	dc.b	$54, $48, $45, $4D, $45, $00
loc_0003D446:
	dc.b	$4B, $30, $00, $03, $00, $07, $84, $C0, $32, $30, $2E, $20, $45, $58, $49, $54
loc_0003D456:
	dc.b	$41, $1C, $00, $03, $00, $09, $A4, $C0, $53, $4F, $55, $4E, $44, $20, $54, $45
	dc.b	$53, $54
loc_0003D468:
	dc.b	$42, $0A, $00, $03, $00, $0C, $84, $C0, $31, $2E, $57, $49, $4E, $44, $4F, $57
	dc.b	$20, $4F, $50, $45, $4E, $00
loc_0003D47E:
	dc.b	$43, $0A, $00, $03, $00, $0C, $84, $C0, $32, $2E, $43, $4F, $4D, $4D, $41, $4E
	dc.b	$44, $20, $53, $45, $54, $00
loc_0003D494:
	dc.b	$44, $0A, $00, $03, $00, $0F, $84, $C0, $33, $2E, $43, $4F, $4D, $4D, $41, $4E
	dc.b	$44, $20, $43, $41, $4E, $43, $45, $4C
loc_0003D4AC:
	dc.b	$45, $0A, $00, $03, $00, $0F, $84, $C0, $34, $2E, $43, $4F, $4D, $4D, $41, $4E
	dc.b	$44, $20, $53, $45, $4C, $45, $43, $54
loc_0003D4C4:
	dc.b	$46, $0A, $00, $03, $00, $08, $84, $C0, $35, $2E, $54, $41, $4C, $4B, $49, $4E
	dc.b	$47, $00
loc_0003D4D6:
	dc.b	$47, $0A, $00, $03, $00, $0B, $84, $C0, $36, $2E, $49, $4E, $54, $4F, $20, $48
	dc.b	$4F, $55, $53, $45
loc_0003D4EA:
	dc.b	$48, $0A, $00, $03, $00, $05, $84, $C0, $37, $2E, $52, $49, $4E, $47
loc_0003D4F8:
	dc.b	$49, $0A, $00, $03, $00, $05, $84, $C0, $38, $2E, $53, $54, $41, $52
loc_0003D506:
	dc.b	$4A, $0A, $00, $03, $00, $0D, $84, $C0, $39, $2E, $47, $45, $54, $20, $54, $48
	dc.b	$45, $20, $49, $54, $45, $4D
loc_0003D51C:
	dc.b	$4B, $08, $00, $03, $00, $0A, $84, $C0, $31, $30, $2E, $4F, $50, $45, $4E, $20
	dc.b	$42, $4F, $58, $00
loc_0003D530:
	dc.b	$42, $30, $00, $03, $00, $0C, $84, $C0, $31, $31, $2E, $44, $4F, $4F, $52, $20
	dc.b	$4B, $4E, $4F, $43, $4B, $00
loc_0003D546:
	dc.b	$43, $30, $00, $03, $00, $07, $84, $C0, $31, $32, $2E, $4C, $49, $47, $48, $54
loc_0003D556:
	dc.b	$44, $30, $00, $03, $00, $09, $84, $C0, $31, $33, $2E, $52, $45, $43, $4F, $56
	dc.b	$45, $52
loc_0003D568:
	dc.b	$45, $30, $00, $03, $00, $07, $84, $C0, $31, $34, $2E, $57, $41, $54, $45, $52
loc_0003D578:
	dc.b	$46, $30, $00, $03, $00, $08, $84, $C0, $31, $35, $2E, $46, $49, $52, $45, $20
	dc.b	$32, $00
loc_0003D58A:
	dc.b	$47, $30, $00, $03, $00, $08, $84, $C0, $31, $36, $2E, $46, $49, $52, $45, $20
	dc.b	$33, $00
loc_0003D59C:
	dc.b	$48, $30, $00, $03, $00, $0A, $84, $C0, $31, $37, $2E, $45, $4C, $45, $43, $54
	dc.b	$52, $49, $43, $00
loc_0003D5B0:
	dc.b	$49, $30, $00, $03, $00, $08, $84, $C0, $31, $38, $2E, $42, $4F, $4D, $42, $45
	dc.b	$52, $00
loc_0003D5C2:
	dc.b	$4A, $30, $00, $03, $00, $07, $84, $C0, $31, $39, $2E, $43, $4C, $4F, $43, $4B
loc_0003D5D2:
	dc.b	$42, $0A, $00, $03, $00, $0D, $84, $C0, $31, $2E, $45, $4E, $45, $4D, $59, $20
	dc.b	$41, $50, $50, $45, $41, $52
loc_0003D5E8:
	dc.b	$43, $0A, $00, $03, $00, $05, $84, $C0, $32, $2E, $52, $45, $53, $54
loc_0003D5F6:
	dc.b	$44, $0A, $00, $03, $00, $09, $84, $C0, $33, $2E, $4C, $45, $56, $45, $4C, $20
	dc.b	$55, $50
loc_0003D608:
	dc.b	$45, $0A, $00, $03, $00, $05, $84, $C0, $34, $2E, $57, $41, $52, $50
loc_0003D616:
	dc.b	$46, $0A, $00, $03, $00, $09, $84, $C0, $35, $2E, $53, $45, $54, $20, $46, $4C
	dc.b	$41, $47
loc_0003D628:
	dc.b	$47, $0A, $00, $03, $00, $0B, $84, $C0, $36, $2E, $45, $4E, $45, $4D, $59, $20
	dc.b	$4D, $45, $4C, $54
loc_0003D63C:
	dc.b	$48, $0A, $00, $03, $00, $0D, $84, $C0, $37, $2E, $45, $4E, $45, $4D, $59, $20
	dc.b	$44, $45, $4C, $45, $54, $45
loc_0003D652:
	dc.b	$49, $0A, $00, $03, $00, $0B, $84, $C0, $38, $2E, $45, $41, $52, $54, $48, $51
	dc.b	$55, $41, $4B, $45
loc_0003D666:
	dc.b	$4A, $0A, $00, $03, $00, $07, $84, $C0, $39, $2E, $45, $4E, $44, $49, $4E, $47
loc_0003D676:
	dc.b	$4B, $08, $00, $03, $00, $0B, $84, $C0, $31, $30, $2E, $4C, $41, $53, $54, $20
	dc.b	$43, $49, $54, $59
loc_0003D68A:
	dc.b	$42, $30, $00, $03, $00, $0C, $84, $C0, $31, $31, $2E, $4C, $49, $47, $48, $54
	dc.b	$20, $53, $4F, $4E, $47, $00
loc_0003D6A0:
	dc.b	$43, $30, $00, $03, $00, $0B, $84, $C0, $31, $32, $2E, $44, $4F, $4F, $52, $20
	dc.b	$4F, $50, $45, $4E
loc_0003D6B4:
	dc.b	$44, $30, $00, $03, $00, $0C, $84, $C0, $31, $33, $2E, $44, $4F, $4F, $52, $20
	dc.b	$43, $4C, $4F, $53, $45, $00
loc_0003D6CA:
	dc.b	$45, $30, $00, $03, $00, $0A, $84, $C0, $31, $34, $2E, $45, $4E, $44, $49, $4E
	dc.b	$47, $20, $32, $00
loc_0003D6DE:
	dc.b	$46, $30, $00, $03, $00, $02, $84, $C0, $31, $35, $2E, $00
loc_0003D6EA:
	dc.b	$47, $30, $00, $03, $00, $02, $84, $C0, $31, $36, $2E, $00
loc_0003D6F6:
	dc.b	$48, $30, $00, $03, $00, $02, $84, $C0, $31, $37, $2E, $00
loc_0003D702:
	dc.b	$49, $30, $00, $03, $00, $02, $84, $C0, $31, $38, $2E, $00
loc_0003D70E:
	dc.b	$4A, $30, $00, $03, $00, $02, $84, $C0, $31, $39, $2E, $00
loc_0003D71A:
	dc.b	$42, $0A, $00, $03, $00, $0C, $84, $C0, $31, $2E, $54, $48, $55, $4E, $44, $45
	dc.b	$52, $20, $4C, $4F, $57, $00
loc_0003D730:
	dc.b	$43, $0A, $00, $03, $00, $0B, $84, $C0, $32, $2E, $54, $48, $55, $4E, $44, $45
	dc.b	$52, $20, $48, $49
loc_0003D744:
	dc.b	$44, $0A, $00, $03, $00, $0D, $84, $C0, $33, $2E, $45, $4E, $45, $4D, $59, $20
	dc.b	$44, $41, $4D, $41, $47, $45
loc_0003D75A:
	dc.b	$45, $0A, $00, $03, $00, $0B, $84, $C0, $34, $2E, $45, $4E, $45, $4D, $59, $20
	dc.b	$44, $45, $41, $44
loc_0003D76E:
	dc.b	$46, $0A, $00, $03, $00, $0E, $84, $C0, $35, $2E, $50, $4C, $41, $59, $45, $52
	dc.b	$20, $44, $41, $4D, $41, $47, $45, $00
loc_0003D786:
	dc.b	$47, $0A, $00, $03, $00, $0C, $84, $C0, $36, $2E, $50, $4C, $41, $59, $45, $52
	dc.b	$20, $44, $45, $41, $44, $00
loc_0003D79C:
	dc.b	$48, $0A, $00, $03, $00, $08, $84, $C0, $37, $2E, $53, $57, $4F, $52, $44, $20
	dc.b	$31, $00
loc_0003D7AE:
	dc.b	$49, $0A, $00, $03, $00, $08, $84, $C0, $38, $2E, $53, $57, $4F, $52, $44, $20
	dc.b	$32, $00
loc_0003D7C0:
	dc.b	$4A, $0A, $00, $03, $00, $08, $84, $C0, $39, $2E, $53, $57, $4F, $52, $44, $20
	dc.b	$33, $00
loc_0003D7D2:
	dc.b	$4B, $08, $00, $03, $00, $09, $84, $C0, $31, $30, $2E, $53, $57, $4F, $52, $44
	dc.b	$20, $34
loc_0003D7E4:
	dc.b	$42, $30, $00, $03, $00, $02, $84, $C0, $31, $31, $2E, $00
loc_0003D7F0:
	dc.b	$43, $30, $00, $03, $00, $02, $84, $C0, $31, $32, $2E, $00
loc_0003D7FC:
	dc.b	$44, $30, $00, $03, $00, $02, $84, $C0, $31, $33, $2E, $00
loc_0003D808:
	dc.b	$45, $30, $00, $03, $00, $02, $84, $C0, $31, $34, $2E, $00
loc_0003D814:
	dc.b	$46, $30, $00, $03, $00, $02, $84, $C0, $31, $35, $2E, $00
loc_0003D820:
	dc.b	$47, $30, $00, $03, $00, $02, $84, $C0, $31, $36, $2E, $00
loc_0003D82C:
	dc.b	$48, $30, $00, $03, $00, $02, $84, $C0, $31, $37, $2E, $00
loc_0003D838:
	dc.b	$49, $30, $00, $03, $00, $02, $84, $C0, $31, $38, $2E, $00
loc_0003D844:
	dc.b	$4A, $30, $00, $03, $00, $02, $84, $C0, $31, $39, $2E, $00
loc_0003D850:
	dc.b	$41, $1C, $00, $03, $00, $09, $C4, $C0, $43, $52, $54, $20, $20, $20, $54, $45
	dc.b	$53, $54
loc_0003D862:
	dc.b	$4D, $14, $00, $03, $00, $14, $A4, $C0, $45, $58, $49, $54, $2E, $2E, $2E, $50
	dc.b	$55, $53, $48, $20, $43, $20, $42, $55, $54, $54, $4F, $4E, $21, $00

; loc_0003D880 — pointer table: 4 longs pointing to sound-ID arrays for each category
; (BGM pointer table at $3D890, Effect at $3D8B8, BGM2 at $3D8E0, D/A at $3D908)
loc_0003D880:
	dc.b	$00, $03, $D8, $90, $00, $03, $D8, $B8, $00, $03, $D8, $E0, $00, $03, $D9, $08
	dc.b	$00, $81, $00, $82, $00, $8D, $00, $87, $00, $8F, $00, $8B, $00, $83, $00, $8C
	dc.b	$00, $95, $00, $91, $00, $8A, $00, $98, $00, $88, $00, $93, $00, $8E, $00, $92
	dc.b	$00, $96, $00, $94, $00, $97, $00, $00, $00, $A0, $00, $A1, $00, $A8, $00, $A9
	dc.b	$00, $A2, $00, $A3, $00, $A4, $00, $A5, $00, $A6, $00, $A7, $00, $AA, $00, $AD
	dc.b	$00, $AE, $00, $BA, $00, $BC, $00, $BD, $00, $BE, $00, $BF, $00, $C1, $00, $00
	dc.b	$00, $84, $00, $85, $00, $86, $00, $89, $00, $90, $00, $AB, $00, $AC, $00, $AF
	dc.b	$00, $99, $00, $9A, $00, $9B, $00, $BB, $00, $B3, $00, $9C, $00, $00, $00, $00
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $B0, $00, $B7, $00, $B1, $00, $C0
	dc.b	$00, $B2, $00, $B9, $00, $B4, $00, $B5, $00, $B6, $00, $B8, $00, $00, $00, $00
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

PlayerSpritePositionClamp_Done_Data:
	dc.b	$00, $02, $FF, $FD, $00, $01, $FF, $FB, $00, $03, $FF, $FC, $FF, $FF, $FF, $ED, $FF, $FB, $FF, $E2, $FF, $FF, $00, $01, $00, $09, $FF, $FC, $00, $09, $FF, $FB 
	dc.b	$00, $04, $FF, $FB, $00, $0E, $FF, $ED, $00, $09, $FF, $DF, $00, $00, $00, $00, $00, $09, $FF, $FD, $00, $03, $FF, $FD, $00, $0F, $FF, $F7, $00, $11, $FF, $EB 
	dc.b	$00, $05, $FF, $E2, $00, $0F, $FF, $F6, $00, $04, $FF, $FD, $FF, $FF, $FF, $FC, $00, $0E, $FF, $FC, $00, $0F, $FF, $ED, $00, $05, $FF, $E3, $00, $0C, $FF, $ED 
	dc.b	$00, $0F, $FF, $FD, $00, $0A, $FF, $FE, $00, $11, $FF, $FC, $00, $0E, $FF, $E8, $00, $07, $FF, $E1, $00, $0F, $FF, $EB 
BossBattleShieldTick_Data:
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $E9, $FF, $FF, $00, $18, $00, $08, $00, $19, $FF, $DA, $FF, $F7, $FF, $C8 
	dc.b	$00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $17, $FF, $F6, $00, $17, $00, $00, $00, $17, $FF, $F5, $00, $17, $FF, $F6, $00, $17, $FF, $F5 
OverworldMapSector_D9E8:
	dc.b	$04, $03, $04, $05, $04, $03, $04, $05, $07, $06, $07, $08, $07, $06, $07, $08, $01, $00, $01, $02, $01, $00, $01, $02, $07, $06, $07, $08, $07, $06, $07, $08 
OverworldMapSector_DA08:
	dc.b	$06
	dc.b	$0C
	dc.b	$06
	dc.b	$00 
	dc.b	$07
	dc.b	$0D
	dc.b	$07
	dc.b	$00 
	dc.b	$06
	dc.b	$0C
	dc.b	$06
	dc.b	$00 
	dc.b	$08
	dc.b	$0E
	dc.b	$08
	dc.b	$00 
	dc.b	$12
	dc.b	$15
	dc.b	$18
	dc.b	$00 
	dc.b	$13
	dc.b	$16
	dc.b	$19
	dc.b	$00 
	dc.b	$12
	dc.b	$15
	dc.b	$18
	dc.b	$00 
	dc.b	$14
	dc.b	$17
	dc.b	$1A
	dc.b	$00 
	dc.b	$0C
	dc.b	$18
	dc.b	$0C
	dc.b	$00 
	dc.b	$0D
	dc.b	$19
	dc.b	$0D
	dc.b	$00 
	dc.b	$0C
	dc.b	$18
	dc.b	$0C
	dc.b	$00 
	dc.b	$0E
	dc.b	$1A
	dc.b	$0E
	dc.b	$00 
	dc.b	$0F
	dc.b	$09
	dc.b	$12
	dc.b	$00 
	dc.b	$10
	dc.b	$0A
	dc.b	$13
	dc.b	$00 
	dc.b	$0F
	dc.b	$09
	dc.b	$12
	dc.b	$00 
	dc.b	$11
	dc.b	$0B
	dc.b	$14
	dc.b	$00 
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00 
	dc.b	$01
	dc.b	$01
	dc.b	$01
	dc.b	$00 
	dc.b	$00
	dc.b	$00
	dc.b	$00
	dc.b	$00 
	dc.b	$02
	dc.b	$02
	dc.b	$02
	dc.b	$00 
	dc.b	$0F
	dc.b	$09
	dc.b	$12
	dc.b	$00 
	dc.b	$10
	dc.b	$0A
	dc.b	$13
	dc.b	$00 
	dc.b	$0F
	dc.b	$09
	dc.b	$12
	dc.b	$00 
	dc.b	$11
	dc.b	$0B
	dc.b	$14
	dc.b	$00 
	dc.b	$0C
	dc.b	$18
	dc.b	$0C
	dc.b	$00 
	dc.b	$0D
	dc.b	$19
	dc.b	$0D
	dc.b	$00 
	dc.b	$0C
	dc.b	$18
	dc.b	$0C
	dc.b	$00 
	dc.b	$0E
	dc.b	$1A
	dc.b	$0E
	dc.b	$00 
	dc.b	$12
	dc.b	$15
	dc.b	$18
	dc.b	$00 
	dc.b	$13
	dc.b	$16
	dc.b	$19
	dc.b	$00 
	dc.b	$12
	dc.b	$15
	dc.b	$18
	dc.b	$00 
	dc.b	$14
	dc.b	$17
	dc.b	$1A
	dc.b	$00 
BattleMovement_AttackCheck_Data:
	dc.b	$09
	dc.b	$12
	dc.b	$09
	dc.b	$00 
	dc.b	$0A
	dc.b	$13
	dc.b	$0A
	dc.b	$00 
	dc.b	$09
	dc.b	$12
	dc.b	$09
	dc.b	$00, $08, $0E, $08, $00 
	dc.b	$12
	dc.b	$1B
	dc.b	$1B
	dc.b	$00 
	dc.b	$13
	dc.b	$1C
	dc.b	$1C
	dc.b	$00 
	dc.b	$12
	dc.b	$1B
	dc.b	$1B
	dc.b	$00, $14, $17, $1A, $00 
	dc.b	$0C
	dc.b	$03
	dc.b	$0F
	dc.b	$00 
	dc.b	$0D
	dc.b	$04
	dc.b	$10
	dc.b	$00 
	dc.b	$0C
	dc.b	$03
	dc.b	$0F
	dc.b	$00, $0E, $1A, $0E, $00 
	dc.b	$0F
	dc.b	$0F
	dc.b	$15
	dc.b	$00 
	dc.b	$10
	dc.b	$10
	dc.b	$16
	dc.b	$00 
	dc.b	$0F
	dc.b	$0F
	dc.b	$15
	dc.b	$00, $11, $0B, $14, $00 
	dc.b	$03
	dc.b	$06
	dc.b	$03
	dc.b	$00 
	dc.b	$04
	dc.b	$07
	dc.b	$04
	dc.b	$00 
	dc.b	$03
	dc.b	$06
	dc.b	$03
	dc.b	$00, $02, $02, $02, $00 
	dc.b	$0F
	dc.b	$0F
	dc.b	$15
	dc.b	$00 
	dc.b	$10
	dc.b	$10
	dc.b	$16
	dc.b	$00 
	dc.b	$0F
	dc.b	$0F
	dc.b	$15
	dc.b	$00, $11, $0B, $14, $00 
	dc.b	$0C
	dc.b	$03
	dc.b	$0F
	dc.b	$00 
	dc.b	$0D
	dc.b	$04
	dc.b	$10
	dc.b	$00 
	dc.b	$0C
	dc.b	$03
	dc.b	$0F
	dc.b	$00, $0E, $1A, $0E, $00 
	dc.b	$12
	dc.b	$1B
	dc.b	$1B
	dc.b	$00 
	dc.b	$13
	dc.b	$1C
	dc.b	$1C
	dc.b	$00 
	dc.b	$12
	dc.b	$1B
	dc.b	$1B
	dc.b	$00, $14, $17, $1A, $00 
BossBattle_AttackCheck_Loop3_Data:
	dc.b	$0D
	dc.b	$0D
	dc.b	$04
	dc.b	$00 
	dc.b	$0E
	dc.b	$0E
	dc.b	$04
	dc.b	$00 
	dc.b	$0D
	dc.b	$0D
	dc.b	$04
	dc.b	$00 
	dc.b	$0F
	dc.b	$0E
	dc.b	$04
	dc.b	$00 
BossBattle_AttackCheck_Loop4_Data:
	dc.b	$00
	dc.b	$00
	dc.b	$06
	dc.b	$00 
	dc.b	$01
	dc.b	$01
	dc.b	$06
	dc.b	$00 
	dc.b	$02
	dc.b	$02
	dc.b	$06
	dc.b	$00 
	dc.b	$03
	dc.b	$03
	dc.b	$06
	dc.b	$00 
BossBattle_MoveDone_Data:
	dc.b	$09
	dc.b	$09
	dc.b	$06
	dc.b	$00 
	dc.b	$0A
	dc.b	$0A
	dc.b	$06
	dc.b	$00 
	dc.b	$04
	dc.b	$04
	dc.b	$00
	dc.b	$00 
	dc.b	$05
	dc.b	$05
	dc.b	$01
	dc.b	$00 
	dc.b	$06
	dc.b	$06
	dc.b	$02
	dc.b	$00 
	dc.b	$07
	dc.b	$07
	dc.b	$03
	dc.b	$00 
	dc.b	$07
	dc.b	$07
	dc.b	$03
	dc.b	$00 
	dc.b	$0B
	dc.b	$0B
	dc.b	$04
	dc.b	$00 
	dc.b	$0B
	dc.b	$0B
	dc.b	$04
	dc.b	$00 
	dc.b	$0B
	dc.b	$0B
	dc.b	$04
	dc.b	$00 
EnemyAnimFrames_MeleeA_Child:
	dc.b	$00, $FD, $01, $09, $00, $FD, $01, $15, $00, $FD, $01, $09, $00, $FD, $01, $15, $01, $21, $01, $2D, $01, $21, $01, $39, $01, $21, $01, $2D, $01, $21, $01, $39 
	dc.b	$00, $D9, $00, $E5, $00, $D9, $00, $F1, $00, $D9, $00, $E5, $00, $D9, $00, $F1, $01, $21, $01, $2D, $01, $21, $01, $39, $01, $21, $01, $2D, $01, $21, $01, $39 
EnemyAnimFrames_MeleeA_Main:
	dc.b	$00, $31, $00, $39, $00, $31, $00, $41, $00, $31, $00, $39, $00, $31, $00, $41, $00, $51, $00, $51, $00, $49, $00, $59, $00, $51, $00, $51, $00, $49, $00, $59 
	dc.b	$00, $19, $00, $21, $00, $19, $00, $29, $00, $19, $00, $21, $00, $19, $00, $29, $00, $51, $00, $51, $00, $49, $00, $59, $00, $51, $00, $51, $00, $49, $00, $59 
EnemyTick_Bouncing_Loop6_Data:
	dc.b	$00, $19, $00, $25, $00, $19, $00, $25, $00, $31, $00, $3D, $00, $49, $00, $55 
EnemyTick_Bouncing_Loop6_Data2:
	dc.b	$00, $D9, $00, $E1, $00, $D9, $00, $E1, $00, $E9, $00, $F1, $00, $F9, $01, $01 
EnemyTick_ProximityChase_Loop11_Data:
	dc.b	$00, $39, $00, $61, $00, $39, $00, $61, $00, $31, $00, $59, $00, $31, $00, $59, $00, $29, $00, $51, $00, $29, $00, $51, $00, $21, $00, $49, $00, $21, $00, $49 
	dc.b	$00, $19, $00, $41, $00, $19, $00, $41, $00, $21, $00, $49, $00, $21, $00, $49, $00, $29, $00, $51, $00, $29, $00, $51, $00, $31, $00, $59, $00, $31, $00, $59 
EnemyTick_ProximityChase_Loop11_Data2:
	dc.b	$01, $09, $01, $45, $01, $09, $01, $45, $00, $FD, $01, $39, $00, $FD, $01, $39, $00, $F1, $01, $2D, $00, $F1, $01, $2D, $00, $E5, $01, $21, $00, $E5, $01, $21 
	dc.b	$00, $D9, $01, $15, $00, $D9, $01, $15, $00, $E5, $01, $21, $00, $E5, $01, $21, $00, $F1, $01, $2D, $00, $F1, $01, $2D, $00, $FD, $01, $39, $00, $FD, $01, $39 
EnemyAnimFrames_MeleeB_Child:
	dc.b	$00, $FD, $01, $09, $00, $FD, $01, $15, $00, $FD, $01, $09, $00, $FD, $01, $15, $01, $21, $01, $2D, $01, $21, $01, $39, $01, $21, $01, $2D, $01, $21, $01, $39 
	dc.b	$00, $D9, $00, $E5, $00, $D9, $00, $F1, $00, $D9, $00, $E5, $00, $D9, $00, $F1, $01, $21, $01, $2D, $01, $21, $01, $39, $01, $21, $01, $2D, $01, $21, $01, $39 
EnemyAnimFrames_MeleeB_Main:
	dc.b	$00, $3D, $00, $49, $00, $3D, $00, $55, $00, $3D, $00, $49, $00, $3D, $00, $55, $00, $6D, $00, $6D, $00, $61, $00, $79, $00, $6D, $00, $6D, $00, $61, $00, $79 
	dc.b	$00, $19, $00, $25, $00, $19, $00, $31, $00, $19, $00, $25, $00, $19, $00, $31, $00, $6D, $00, $6D, $00, $61, $00, $79, $00, $6D, $00, $6D, $00, $61, $00, $79 
EnemyAnimFrames_Fireball:
	dc.b	$01, $99, $01, $9B, $01, $99, $01, $9D 
EnemyAnimFrames_Fireball_B:
	dc.b	$00, $19, $00, $21, $00, $29, $00, $31, $00, $39 
EnemyAnimFrames_Fireball_C:
	dc.b	$00, $D9, $00, $E5, $00, $F1, $00, $FD, $01, $09 
ProjectileTick_PostCollision_Loop2_Data:
	dc.b	$00, $21, $00, $39, $00, $21, $00, $39 
ProjectileTick_PostCollision_Loop2_Data2:
	dc.b	$00, $E5, $01, $09, $00, $E5, $01, $09 
EnemyAnimFrames_Fireball_D:
	dc.b	$00, $E9, $00, $D9, $00, $E9, $00, $F9 
EnemyDeathAnimation_Data:
	dc.b	$01, $E9, $01, $F9, $02, $09, $02, $19, $02, $29 
NPCSpriteFrames_Base:
	dc.b	$02, $39, $02, $3D, $02, $41
NPCSpriteFrames_Child:
	dc.b	$00, $49, $00, $55, $00, $49, $00, $55, $00, $19, $00, $25, $00, $19, $00, $25, $00, $31, $00, $3D, $00, $31, $00, $3D, $00, $19
	dc.b	$00, $25, $00, $19, $00, $25
NPCSpriteFrames_VillagerB:
	dc.b	$00, $85, $00, $85, $00, $85, $00, $85, $00, $61, $00, $6D, $00, $61, $00, $6D, $00, $79, $00, $79, $00, $79, $00, $79, $00, $61
	dc.b	$00, $6D, $00, $61, $00, $6D
NPCSpriteFrames_ManA:
	dc.b	$00, $C1, $00, $C1, $00, $C1, $00, $C1, $00, $9D, $00, $91, $00, $9D, $00, $A9, $00, $B5, $00, $B5, $00, $B5, $00, $B5, $00, $9D 
	dc.b	$00, $91, $00, $9D, $00, $A9 
NPCSpriteFrames_ManB:
	dc.b	$00, $FD, $00, $FD, $00, $FD, $00, $FD, $00, $D9, $00, $CD, $00, $D9, $00, $E5, $00, $F1, $00, $F1, $00, $F1, $00, $F1, $00, $D9 
	dc.b	$00, $CD, $00, $D9, $00, $E5
NPCSpriteFrames_ManD:
	dc.b	$00, $FD, $00, $FD, $00, $FD, $00, $FD, $00, $D9, $00, $D9, $00, $D9, $00, $D9, $00, $F1, $00, $F1, $00, $F1, $00, $F1, $00, $D9, $00, $D9, $00, $D9, $00, $D9
NPCSpriteFrames_VillagerC:	
	dc.b	$01, $39, $01, $45, $01, $39, $01, $45, $01, $09, $01, $15, $01, $09, $01, $15, $01, $21, $01, $2D, $01, $21, $01, $2D, $01, $09 
	dc.b	$01, $15, $01, $09, $01, $15
NPCSpriteFrames_Woman:
	dc.b	$01, $75, $01, $75, $01, $75, $01, $75, $01, $51, $01, $5D, $01, $51, $01, $5D, $01, $69, $01, $69, $01, $69, $01, $69, $01, $51
	dc.b	$01, $5D, $01, $51, $01, $5D
NPCSpriteFrames_Guard:
	dc.b	$01, $BD, $01, $C9, $01, $BD, $01, $C9, $01, $8D, $01, $81, $01, $8D, $01, $99, $01, $A5, $01, $B1, $01, $A5, $01, $B1, $01, $8D
	dc.b	$01, $81, $01, $8D, $01, $99
NPCSpriteFrames_Soldier:
	dc.b	$01, $F9, $01, $F9, $01, $F9, $01, $F9, $01, $D5, $01, $E1, $01, $D5, $01, $E1, $01, $ED, $01, $ED, $01, $ED, $01, $ED, $01, $D5, $01, $E1, $01, $D5, $01, $E1
NPCSpriteFrames_Elder:
	dc.b	$02, $35, $02, $35, $02, $35, $02, $35, $02, $11, $02, $05, $02, $11, $02, $1D, $02, $29, $02, $29, $02, $29, $02, $29, $02, $11
	dc.b	$02, $05, $02, $11, $02, $1D
NPCSpriteFrames_Priest:
	dc.b	$02, $71, $02, $71, $02, $71, $02, $71, $02, $4D, $02, $41, $02, $4D, $02, $59, $02, $65, $02, $65, $02, $65, $02, $65, $02, $4D
	dc.b	$02, $41, $02, $4D, $02, $59
NPCSpriteFrames_Shopkeeper:
	dc.b	$02, $05, $02, $11
NPCSpriteFrames_FairyA:
	dc.b	$02, $1D, $02, $1D
NPCSpriteFrames_FairyB:
	dc.b	$02, $29, $02, $29, $02, $05, $02, $05, $02, $05, $02, $05, $01, $E1, $01, $D5, $01, $E1
	dc.b	$01, $ED, $01, $F9, $01, $F9, $01, $F9, $01, $F9, $01, $E1, $01, $D5, $01, $E1, $01, $ED, $02, $35, $02, $35, $02, $35, $02, $35, $02, $11, $02, $1D, $02, $11 
	dc.b	$02, $1D, $02, $29, $02, $29, $02, $29, $02, $29, $02, $11, $02, $1D, $02, $11, $02, $1D, $02, $4D, $02, $4D, $02, $7D, $02, $7D, $02, $7D, $02, $7D, $02, $59 
	dc.b	$02, $65, $02, $59, $02, $65, $02, $71, $02, $71, $02, $71, $02, $71, $02, $59, $02, $65, $02, $59, $02, $65, $02, $AD, $02, $AD, $02, $AD, $02, $AD, $02, $89 
	dc.b	$02, $95, $02, $89, $02, $95, $02, $A1, $02, $A1, $02, $A1, $02, $A1, $02, $89, $02, $95, $02, $89, $02, $95
NPCSpriteFrames_IndoorNpcA:
	dc.b	$02, $35, $02, $41
NPCSpriteFrames_IndoorNpcB:
	dc.b	$02, $4D, $02, $59
NPCSpriteFrames_IndoorNpcC:
	dc.b	$02, $65
	dc.b	$02, $71
NPCSpriteFrames_IndoorNpcD:
	dc.b	$02, $7D, $02, $89
NPCSpriteFrames_IndoorNpcE:
	dc.b	$02, $95, $02, $A1
NPCSpriteFrames_IndoorNpcF:
	dc.b	$00, $79, $00, $79
AeroSpriteFrameTable:
	dc.b	$02, $51, $02, $57, $02, $45, $02, $5D, $02, $4B, $02, $5D, $02, $45, $02, $57 
MetalSpellSpriteFrameTable:
	dc.b	$02, $75, $02, $69, $02, $75, $02, $81, $02, $E1, $02, $D5, $02, $E1, $02, $ED, $02, $99, $02, $8D, $02, $99, $02, $A5, $02, $BD, $02, $B1, $02, $BD, $02, $C9 
	dc.b	$02, $51, $02, $45, $02, $51, $02, $5D, $02, $BD, $02, $B1, $02, $BD, $02, $C9, $02, $99, $02, $8D, $02, $99, $02, $A5, $02, $E1, $02, $D5, $02, $E1, $02, $ED 
ArgentosSpriteFrameTable:
	dc.b	$02, $45, $02, $51, $02, $5D, $02, $69 
HydroOpeningSpriteFrameTable:
	dc.b	$02, $45, $02, $55, $02, $65, $02, $75, $02, $85 
HydroExplosionSpriteFrameTable:
	dc.w	$02A5
	dc.w	$02B5
VoltiosDescendFrameTable:
	dc.w	$025D
	dc.w	$0251
	dc.w	$0245
VoltiosAscendFrameTable:
	dc.w	$024B
	dc.w	$0257
	dc.w	$0263
VoltiosClearFrameTable:
	dc.w	$0245
	dc.w	$0251
	dc.w	$025D
VoltiosExplosionFrameTable:
	dc.b	$02, $75, $02, $69, $02, $7B, $02, $6F, $02, $8D, $02, $81, $02, $93, $02, $87 
VoltioOrbitSpriteFrameTable:
	dc.b	$02, $45, $02, $4D, $02, $45, $02, $55 
VoltiSpriteFrameTable:
	dc.b	$02, $45, $02, $4D, $02, $45, $02, $55 