; ======================================================================
; sound_constants.asm
; Sound Effect IDs, Note-Sequence Script Control Bytes, and
; FM Sound Channel Struct Field Offsets.
; ======================================================================

; ============================================================
; Sound Effect IDs
; ============================================================
; These are passed to QueueSoundEffect to play sound effects.
;
SOUND_MENU_CANCEL       = $00A8   ; Cancel/back sound (36 uses)
SOUND_MENU_SELECT       = $00A1   ; Confirm/select sound (23 uses)
SOUND_MENU_CURSOR       = $00A0   ; Cursor movement (8 uses)
SOUND_ITEM_PICKUP       = $00AE   ; Item pickup/acquire (16 uses)
SOUND_LEVEL_UP          = $00E0   ; Level up fanfare (16 uses)
SOUND_PURCHASE          = $00AC   ; Shop purchase (6 uses)
SOUND_HEAL              = $00B5   ; Healing sound (6 uses)
SOUND_DOOR_OPEN         = $00C0   ; Door opening (5 uses)
SOUND_ATTACK            = $00A6   ; Attack sound (5 uses)
SOUND_HIT               = $00A9   ; Hit/damage sound (5 uses)
SOUND_SPELL_CAST        = $00B9   ; Spell casting (4 uses)
SOUND_MAGIC_EFFECT      = $00B1   ; Magic effect (4 uses)
SOUND_ERROR             = $0090   ; Error/invalid action (3 uses)
SOUND_TREASURE          = $00BE   ; Treasure chest (3 uses)
SOUND_SAVE              = $00BC   ; Save game (3 uses)
SOUND_FOOTSTEP          = $0089   ; Footstep/walk (3 uses)
SOUND_ENEMY_DEATH       = $00AD   ; Enemy death (3 uses)

; ============================================================
; Boss & Encounter Timing Constants
; ============================================================
; Frame-count delays used during boss fights and encounters.
;
BOSS_VICTORY_DELAY_FRAMES   = $0032   ; Frames to wait before boss reward sequence (4 uses)
BOSS_EXIT_DELAY_FRAMES      = $50     ; Frames to wait before processing battle victory event (1 use)
BOSS_VICTORY_FADE_PHASES    = 8       ; Dialog_phase threshold for boss victory fadeout complete (7 uses)
ENCOUNTER_FADE_PHASES       = $000A   ; Number of fade-in phases for encounter/dialogue intro (2 uses)
ENCOUNTER_PAUSE_FRAMES      = $0064   ; Frames to pause before battle begins after encounter (1 use)
ORBIT_ANGLE_INIT_INNER      = $80     ; OrbitBoss inner satellite initial orbit angle (180 degrees)
ORBIT_ANGLE_INIT_OUTER      = $C0     ; OrbitBoss outer satellite initial orbit angle (192 degrees)
ORBIT_APPROACH_ANGLE_MIN    = $B0     ; OrbitBoss approach arc lower clamp (176 degrees)
ORBIT_APPROACH_ANGLE_MAX    = $D0     ; OrbitBoss approach arc upper clamp (208 degrees)
SLEEP_DELAY_FRAMES          = $012C   ; Frames of sleep animation delay (2 uses)
; ============================================================
; Name Entry Grid Constants
; ============================================================
NAME_ENTRY_LAST_ROW         = $0010   ; Last valid row index in name entry grid (wraps to 0) (3 uses)
NAME_ENTRY_LAST_COL         = $001D   ; Last valid column index in name entry grid (wraps to 0) (2 uses)
; ============================================================
; Poison Duration
; ============================================================
POISONED_DURATION           = $FFFF   ; Player_poisoned: indefinite/permanent poison (2 uses)
; ============================================================
; Boss Hit Flash Palette Indices
; ============================================================
PALETTE_IDX_BOSS_FLASH_A    = $00B5   ; Boss hit flash palette A (two-headed dragon) (2 uses)
PALETTE_IDX_BOSS_FLASH_B    = $00B7   ; Boss hit flash palette B (orbit/ring boss) (2 uses)

; VRAM tile index of the two-headed dragon boss head in its idle/resting frame.
; Compared against obj_tile_index(A6) to detect when the head sprite is at rest
; before triggering a random attack animation.
DRAGON_HEAD_IDLE_TILE       = $00DD   ; Dragon head idle-frame tile index (2 uses)

; ============================================================
; Ending Sequence Timer Durations (Ending_timer)
; ============================================================
; Frame counts used during the ending sequence steps.
; At 60 fps: $0032=50f, $00C8=200f, $012C=300f, $0190=400f, $01F4=500f.
;
ENDING_DELAY_BRIEF          = $0032   ; Very short ending delay (1 use)
ENDING_DELAY_NORMAL         = $00C8   ; Standard ending step duration (5 uses)
ENDING_DELAY_LONG           = $012C   ; Long ending step duration (2 uses)
ENDING_DELAY_SCROLL         = $0190   ; Ending scroll phase duration (1 use)
ENDING_DELAY_LONGER         = $01F4   ; Extended ending step duration (2 uses)

; ============================================================
; Sound Effect IDs (additional)
; ============================================================
SOUND_TRANSITION            = $00A3   ; Screen/room fade transition sound (19 uses)
SOUND_SLEEP                 = $0085   ; Sleep/frying-pan sound effect (3 uses)
SOUND_LEVEL_UP_BANNER       = $0086   ; Sound played when level-up banner triggers (2 uses)
SOUND_NAME_ENTRY            = $008D   ; Sound played when entering name-entry or load-save screen (2 uses)
SOUND_OVERWORLD_RETURN      = $00B3   ; Sound when returning to overworld from dungeon/after chest (2 uses)
SOUND_PLAYER_HIT            = $00B2   ; Sound when player takes damage in overworld or battle (2 uses)
SOUND_BOMB                  = $00BF   ; Explosion/bomb sound (DemonBoss attack, SmallBomb item) (2 uses)
SOUND_MERCUSIOS             = $00BD   ; Mercusios magic projectile launch sound (2 uses)
SOUND_TERRAFISSI            = $00AF   ; Terrafissi spell / DemonBoss projectile activation sound (2 uses)
SOUND_BATTLE_START          = $0092   ; Sound played when battle initializes (1 use)
SOUND_OVERWORLD_MUSIC       = $008E   ; Overworld/field music; written to Current_area_music and queued (2 uses)
SOUND_SWORD_ATTACK          = $00B6   ; Player sword swing in battle (1 use)
SOUND_TEXT_BLIP             = $00A2   ; Per-character typewriter blip during script text (1 use)
SOUND_PROLOGUE_MUSIC        = $0081   ; Music cue queued at prologue scene init (1 use)
SOUND_TITLE_MUSIC           = $0082   ; Music cue queued at title screen fade-in (1 use)
SOUND_CHEST_OPEN            = $00AA   ; Sound queued when chest state begins opening sequence (1 use)
SOUND_CHEST_CREAK           = $00A7   ; Sound queued when chest lid is physically opened (1 use)
SOUND_SWAFFHAM_RUINED_MUSIC = $0083   ; Swaffham town music after it is ruined (1 use)
SOUND_ENCOUNTER_START       = $0084   ; Sound at encounter initialization before battle (1 use)
SOUND_STOW_MUSIC_GIRL_LEFT  = $0087   ; Stow town music while girl has left for Stow event (1 use)
SOUND_STOW_MUSIC_INNOCENCE  = $009B   ; Stow town music after innocence is proven (1 use)
SOUND_ORBIT_BOSS_MUSIC      = $0093   ; OrbitBoss battle music (1 use)
SOUND_SAVE_FAILED           = $0094   ; Sound when save operation fails (1 use)
SOUND_ENDING_CREDITS_MUSIC  = $0099   ; Ending credits scroll music (1 use)
SOUND_ENDING_STAFF_MUSIC    = $009C   ; Ending staff names screen music (1 use)
SOUND_ENDING_FANFARE_A      = $00A4   ; Ending sequence fanfare cue A (1 use)
SOUND_ENDING_FANFARE_B      = $00A5   ; Ending sequence fanfare cue B (1 use)
SOUND_BOSS1_VICTORY         = $00AB   ; Boss 1 (OrbitBoss) victory music (1 use)
SOUND_VOLTIOS_CAST          = $00B0   ; Voltios magic spell cast (1 use)
SOUND_HYDRA_BITE            = $00B4   ; Hydra boss bite/attack sound (1 use)
SOUND_BOSS_SWORD_ATTACK     = $00B8   ; Player sword swing in boss battle (1 use)
SOUND_HYDRO_ICICLE          = $00BA   ; Hydro boss icicle spawn (1 use)
SOUND_CHEST_RATTLE          = $00BB   ; Chest begins animating/rattling (1 use)
SOUND_ALARM_CLOCK           = $00C1   ; Alarm Clock item use (1 use)

; Sound IDs confirmed from DebugSoundID_Table BGM/Effect/DA arrays in miscdata.asm:
SOUND_DUNGEON_MUSIC         = $008A   ; Dungeon BGM (DebugBGM row 11)
SOUND_VILLAGE_A_MUSIC       = $008B   ; Village A BGM (DebugBGM row 6)
SOUND_SHOP_CITY_MUSIC       = $008C   ; Shop (City) BGM (DebugBGM row 8)
SOUND_ERIAS_MUSIC           = $008F   ; Erias/Areas overworld BGM (DebugBGM row 5)
SOUND_CHURCH_MUSIC          = $0091   ; Church BGM (DebugBGM row 10)
SOUND_SHOP_VILLAGE_MUSIC    = $0095   ; Shop (Village) BGM (DebugBGM row 9)
SOUND_CASTLE_MUSIC          = $0096   ; Castle BGM (DebugBGM row 17)
SOUND_JIJI_THEME            = $0097   ; Jiji character theme BGM (DebugBGM row 19)
SOUND_DUNGEON2_MUSIC        = $0098   ; Dungeon 2 BGM (DebugBGM row 12)
SOUND_ENEMY_APPEAR_JINGLE   = $009A   ; Enemy appear jingle/sting (DebugBGM2 row 10)
SOUND_THUNDER_HI            = $00B7   ; Thunder D/A high variant (DebugDA row 2)

; Sound script byte threshold: bytes < $E0 are note values; bytes >= $E0 are commands.
SOUND_SCRIPT_CMD_THRESHOLD  = $E0   ; BCS/BCC boundary in SoundChannel_NoteLoop

; ============================================================
; Sound Driver RAM Addresses
; ============================================================
; The sound driver occupies $FFF400-$FFF69F.
; Bank 1: 9 FM/PSG channels at SndRAM_ch_bank1, stride fmch_size ($30).
; Bank 2: 4 FM channels at SndRAM_ch_bank2, stride fmch_size ($30).
; DAC channel: SndRAM_ch_dac (bank 1 channel 5, $FFF520).
; DAC extra channel data buffer: SndRAM_dac_ext ($FFF670).
;
SndRAM_cmd_queue    = $00FFF400   ; byte: pending sound command byte (written by 68k, read by driver)
SndRAM_tempo_ctr    = $00FFF401   ; byte: tempo tick countdown (decremented each frame)
SndRAM_tempo_reload = $00FFF402   ; byte: tempo reload value (reloaded into tempo_ctr when it hits 0)
SndRAM_cmd_pending  = $00FFF404   ; byte: sound command currently being processed (bit7=ready flag)
SndRAM_fade_volume  = $00FFF41C   ; byte: current fade-out volume level ($00 = fade inactive)
SndRAM_fade_speed   = $00FFF41D   ; byte: fade-out decrement rate (ticks between each volume step)
SndRAM_part_flag    = $00FFF421   ; byte: FM bank selector ($00=bank1/part1, $80=bank2/part2)
SndRAM_ch_bank1     = $00FFF430   ; FM/PSG channel struct base — bank 1, channel 0 (9 channels, stride $30)
SndRAM_ch2          = $00FFF490   ; FM channel 2 struct (bank 1, channel slot 2)
SndRAM_ch3          = $00FFF4C0   ; FM channel 3 struct (bank 1, channel slot 3)
SndRAM_ch4          = $00FFF4F0   ; FM channel 4 struct (bank 1, channel slot 4)
SndRAM_ch_dac       = $00FFF520   ; DAC/special channel struct (bank 1, channel slot 5)
SndRAM_ch6          = $00FFF550   ; FM channel 6 struct (bank 1, channel slot 6)
SndRAM_ch7          = $00FFF580   ; FM channel 7 struct (bank 1, channel slot 7)
SndRAM_ch8          = $00FFF5B0   ; FM channel 8 struct (bank 1, channel slot 8)
SndRAM_ch_bank2     = $00FFF5E0   ; FM channel struct base — bank 2, channel 0 (4 channels, stride $30)
SndRAM_dac_ext      = $00FFF670   ; DAC extra channel data buffer (9 bytes, used by StartDACMusic)

; ============================================================
; Note-Sequence Script Control Bytes
; ============================================================
; Used in PSGChannel_NoteLoop, FMChannel_NoteLoop, FMArpeggio_ReadNote.
; Bytes $80-$8F in a pitch/arpeggio sequence are control codes;
; bytes below $80 are raw pitch/note values.
;
NOTESCR_RESTART     = $80   ; Reset sequence position to 0 and restart
NOTESCR_LOOP        = $81   ; Step back 2 positions and loop (repeat last interval)
NOTESCR_REST        = $83   ; Step back 1 position, output silence (rest)
NOTESCR_PITCHBEND   = $84   ; Read next byte and add to channel pitch-LFO offset
NOTESCR_JUMP        = $85   ; Read next byte as absolute jump target position

; ============================================================
; FM Sound Channel Struct Field Offsets (A3)
; ============================================================
; Each FM channel occupies $30 bytes.  The struct base is stored
; in A3.  Channels start at $00FFF430 and step by fmch_size each.
;
; Usage: MOVE.b fmch_flags(A3), D0
;        SUBQ.w #1, fmch_tick_ctr(A3)
;
; Note: offsets $1C–$20 are the 5-byte FM algorithm/operator-TL
; block loaded by LoadFM_AlgorithmData from the instrument table.
; Offset $22(A3,D0.w) is a loop-counter array indexed by a script
; variable D0; not separately named.
;
fmch_flags          equ $00   ; byte: status flags (bit7=active, bit6=DAC/echo, bit5=pitch-slide, bit2=muted, bit1=key-off)
fmch_channel_id     equ $01   ; byte: YM2612 channel index + mode flags (bit4=hold/sustain, bit7=PSG)
fmch_tempo_flags    equ $02   ; byte: tempo modifier flags (bit1=double-tempo, written by script cmd)
fmch_script_ptr_hi  equ $03   ; byte: high byte of current script offset (relative to $00093C00)
fmch_script_ptr_lo  equ $04   ; byte: low byte of current script offset
fmch_transpose      equ $05   ; byte: semitone transpose added to note values
fmch_vibrato_idx    equ $06   ; byte: LFO vibrato table index (0=none)
fmch_arpeggio_idx   equ $07   ; byte: arpeggio sequence table index (0=none)
fmch_volume         equ $08   ; byte: channel volume (FM total-level offset, added to operator TL)
fmch_call_sp        equ $09   ; byte: script subroutine call-stack pointer (offset into struct)
fmch_tick_ctr       equ $0A   ; word: tick countdown; decremented each frame, triggers next note at 0
fmch_note_freq      equ $0C   ; word: current note frequency (PSG: period value; FM: F-number)
fmch_note_duration  equ $0E   ; word: note duration in ticks; reloaded into tick_ctr on new note
fmch_pitch_slide    equ $10   ; byte: pitch-slide rate (signed; added to note_freq each frame)
fmch_lfo_phase      equ $11   ; byte: LFO vibrato table read position index
fmch_op_algo        equ $1C   ; byte: FM algorithm/feedback byte (first of 5-byte instrument block)
fmch_op1_tl         equ $1D   ; byte: operator 1 total-level offset (FM instrument data)
fmch_op3_tl         equ $1E   ; byte: operator 3 total-level offset (FM instrument data)
fmch_op2_tl         equ $1F   ; byte: operator 2 total-level offset (FM instrument data)
fmch_op4_tl         equ $20   ; byte: operator 4 total-level offset (FM instrument data)
fmch_pan_stereo     equ $21   ; byte: stereo panning byte written to YM2612 register $B4
fmch_arp_phase      equ $13   ; byte: arpeggio sequence read position index
fmch_pitch_bend     equ $14   ; byte: pitch-bend counter ($1F=key-off/note-end, $FF=no-bend)
fmch_lfo_depth      equ $16   ; byte: LFO depth/amplitude accumulator (scaled by vibrato table)
fmch_size           equ $30   ; struct stride: each channel slot is $30 bytes wide

; ============================================================
; Sound Driver Timing and Architecture Constants
; ============================================================

; Sound script data base address in ROM.
; All script pointers are stored as 16-bit offsets relative to
; this address; reconstructed as: A4 = offset + SND_SCRIPT_BASE.
SND_SCRIPT_BASE             = $00093C00 ; ROM address of sound script data start

; Fade-out parameters (used by ProcessSound_FadeOut):
; Volume steps from SND_FADE_VOLUME_INIT down to 0.
; One step is applied every SND_FADE_SPEED_INIT frames.
; Total fade time = SND_FADE_VOLUME_INIT × SND_FADE_SPEED_INIT frames
;   = $3F × 2 = 126 frames ≈ 2.1 s at 60 fps.
SND_FADE_VOLUME_INIT        = $3F       ; Initial fade-out volume level (63 attenuation steps)
SND_FADE_SPEED_INIT         = 2        ; Frames between each volume decrement step

; Sound RAM clear loop count for StopAllActiveSounds.
; DBF loops SND_RAM_CLEAR_COUNT+1 = $9C (156) times × 4 bytes = 624 bytes
; ($FFF400..$FFF66F; rounds up to cover the full driver RAM region).
SND_RAM_CLEAR_COUNT         = $009B     ; DBF count for zeroing sound driver RAM

; YM2612 register address for key-on/key-off control.
YM2612_REG_KEY_ONOFF        = $28       ; YM2612 global key on/off register address

; FM channel register write count (used by WriteFM_ChannelRegisters).
; One channel requires 25 register address+data byte pairs written.
; DBF loop uses FM_CHANNEL_REG_COUNT_M1 = 25 - 1 = 24 = $18.
FM_CHANNEL_REG_COUNT_M1     = $0018     ; 25 FM operator register pairs per channel (DBF count)

; Channel bank iteration DBF counts.
; Bank 1 has 9 channels (DBF 8..0); bank 2 has 4 channels (DBF 3..0).
SND_BANK1_CH_COUNT_M1       = 8        ; DBF count for 9 bank-1 FM/PSG channels (indices 0..8)
SND_BANK2_CH_COUNT_M1       = 3        ; DBF count for 4 bank-2 FM channels (indices 0..3)
