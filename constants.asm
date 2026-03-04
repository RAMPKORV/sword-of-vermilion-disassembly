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

; I/O Ports
IO_version          = $A10001   ; Hardware version / region register
IO_data_port_1      = $A10003   ; Controller 1 data port
IO_data_port_2      = $A10005   ; Controller 2 data port
IO_expansion        = $A10007   ; Expansion port data
IO_init_status      = $A10008   ; I/O initialization status (longword)
IO_ctrl_port_1      = $A10009   ; Controller 1 control port
IO_ctrl_port_2      = $A1000B   ; Controller 2 control port
IO_ctrl_expansion   = $A1000D   ; Expansion port control
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
VRAM_Sprites        = $D800     ; Sprite attribute table (80 entries, $280 bytes)
VRAM_HScroll        = $DC00     ; Horizontal scroll table

; ============================================================
; Dialogue Script Opcodes & Text Encoding
; ============================================================
; These control codes are embedded in dialogue text strings
; to control text rendering and trigger game events.
;
; Text Encoding:
;   Dialogue strings use ASCII-compatible byte values.
;   The assembler encodes dc.b "text" as standard ASCII.
;   Display bytes $20–$DD and $E0–$F6 are rendered as glyphs.
;   Tile VRAM index = byte + FONT_TILE_BASE.
;   Font tiles are loaded from data/art/tiles/font/font_tiles.bin.
;   Wide characters ($DE/$DF pair) also use FONT_TILE_BASE but
;   with palette bit $8000 OR'd in and positioned at (x-1, y-1).
;
FONT_TILE_BASE          = $04C0 ; Base VRAM tile index for font glyphs (byte + $04C0 = tile)
;
; Text Control Codes:
SCRIPT_END              = $FF   ; End of dialogue script
SCRIPT_NEWLINE          = $FE   ; Carriage return / new line
SCRIPT_CONTINUE         = $FD   ; Show text, wait for input, then continue
SCRIPT_QUESTION         = $FC   ; Related to dialog questions (shows choices)
SCRIPT_YES_NO           = $FB   ; Yes/No choice with event trigger params
SCRIPT_CHOICE           = $FA   ; Quest choice - expects answer and map trigger
SCRIPT_ACTIONS          = $F9   ; Execute actions (give items/money, set triggers)
SCRIPT_TRIGGERS         = $F8   ; Set multiple event triggers (simpler format)
SCRIPT_PLAYER_NAME      = $F7   ; Insert player's name
; Wide character markers (occupy 2 display columns instead of 1):
SCRIPT_WIDE_CHAR_LO     = $DE   ; Wide character — low surrogate byte  (name validation counts 2 per pair)
SCRIPT_WIDE_CHAR_HI     = $DF   ; Wide character — high surrogate byte
;
; $F9 (SCRIPT_ACTIONS) Format:
; --------------------------
; Byte 0: $F9 opcode
; Byte 1: Number of actions
; Following bytes: Action entries (variable length)
;
; Action types:
;   - If first byte of action == $02: Give money
;     Format: $02, BCD0, BCD1, BCD2, BCD3 (4-byte BCD amount in kims)
;   - Otherwise: Set event trigger
;     Format: HI_BYTE, LO_BYTE (16-bit offset from Event_triggers_start)
;
; $F8 (SCRIPT_TRIGGERS) Format:
; ---------------------------
; Byte 0: $F8 opcode  
; Byte 1: Number of triggers
; Following bytes: Single-byte offsets from Event_triggers_start

SCRIPT_ACTION_GIVE_KIMS = $02   ; Action type: give money to player

; ============================================================
; Event Trigger Offsets (for use in SCRIPT_ACTIONS dc.w)
; ============================================================
; These are 16-bit offsets from Event_triggers_start ($FFFFC720)
; Used with SCRIPT_ACTIONS ($F9) to set event flags
; Formula: TRIGGER_xxx = RAM_address - $FFFFC720
;
TRIGGER_Blade_is_dead                       = $0000
TRIGGER_Treasure_of_troy_challenge_issued   = $0002
TRIGGER_Fake_king_killed                    = $0003
TRIGGER_Treasure_of_troy_given_to_king      = $0004
TRIGGER_Talked_to_real_king                 = $0005
TRIGGER_Treasure_of_troy_found              = $0006
TRIGGER_Talked_to_king_after_treasure       = $0007
TRIGGER_Player_chose_to_stay_in_parma       = $0008
TRIGGER_Watling_villagers_asked_about_rings    = $000A
TRIGGER_Treasure_of_troy_challenge_issued       = $0002
TRIGGER_Talked_to_king_after_given_treasure_of_troy = $0007
TRIGGER_Truffle_collected                   = $000B
TRIGGER_Deepdale_king_secret_kept           = $000D
TRIGGER_Sanguios_book_offered               = $000E
TRIGGER_Accused_of_theft                    = $000F
TRIGGER_Stow_thief_defeated                 = $0010
TRIGGER_Asti_monster_defeated               = $0011
TRIGGER_Stow_innocence_proven               = $0012
TRIGGER_Sent_to_malaga                      = $0013
TRIGGER_Bearwulf_met                        = $0014
TRIGGER_Bearwulf_returned_home              = $0015
TRIGGER_Helwig_old_woman_quest_started      = $0016
TRIGGER_Watling_monster_encounter           = $001E
TRIGGER_Tadcaster_treasure_quest_started    = $001F
TRIGGER_Tadcaster_treasure_found            = $0020
TRIGGER_Malaga_king_crowned                 = $001B
TRIGGER_Barrow_map_received                 = $001C
TRIGGER_Imposter_killed                     = $001D
TRIGGER_Bully_first_fight_won               = $0021
TRIGGER_Tadcaster_bully_triggered           = $0022
TRIGGER_Helwig_men_rescued                  = $0024
TRIGGER_Uncle_tibor_visited                 = $0025
TRIGGER_Old_man_waiting_for_letter          = $0026
TRIGGER_Old_man_and_woman_paired            = $0027
TRIGGER_Swaffham_ruined                     = $0028
TRIGGER_Ring_of_earth_obtained              = $0029
TRIGGER_White_crystal_quest_started         = $002A
TRIGGER_Ring_of_wind_received               = $002B
TRIGGER_Red_crystal_quest_started           = $002C
TRIGGER_Red_crystal_received                = $002D
TRIGGER_Blue_crystal_quest_started          = $002E
TRIGGER_Blue_crystal_received               = $002F
TRIGGER_Ate_spy_dinner                      = $0030
TRIGGER_Swaffham_ate_poisoned_food          = $0031
TRIGGER_Digot_plant_received                = $0032
TRIGGER_Spy_dinner_poisoned_flag            = $0033
TRIGGER_Pass_to_carthahena_purchased        = $0034
TRIGGER_Sword_stolen_by_blacksmith          = $0035
TRIGGER_Sword_retrieved_from_blacksmith     = $0036
TRIGGER_Player_has_sword_of_vermilion       = $0037
TRIGGER_Tsarkon_is_dead                     = $0038
TRIGGER_Carthahena_boss_met                 = $0039
TRIGGER_Alarm_clock_rang                    = $003A
TRIGGER_Crown_received                      = $003B
TRIGGER_Girl_left_for_stow                  = $003C
TRIGGER_Keltwick_girl_sleeping              = $003E
TRIGGER_Old_man_has_received_sketch         = $003F
TRIGGER_Old_woman_has_received_sketch       = $0040
TRIGGER_Dragon_shield_offered               = $0041
TRIGGER_Old_mans_sketch_given               = $0042
TRIGGER_Player_has_old_womans_sketch        = $0043
TRIGGER_Dragon_shield_received              = $0044
TRIGGER_Pass_to_carthahena_given            = $0045
TRIGGER_Sanguios_purchased                  = $0046
TRIGGER_Sanguios_confiscated                = $0047
TRIGGER_Sanguia_learned_from_book           = $0048
TRIGGER_Bearwulf_weapon_reward_given        = $0049
TRIGGER_Tadcaster_treasure_kims_received    = $004A
TRIGGER_Knute_informed_of_swaffham_ruin     = $004B
TRIGGER_Player_greatly_poisoned             = $004C
TRIGGER_Excalabria_boss_1_defeated          = $004D
TRIGGER_Excalabria_boss_2_defeated          = $004E
TRIGGER_Excalabria_boss_3_defeated          = $004F
TRIGGER_White_crystal_received              = $0050
TRIGGER_Red_key_received                    = $0051
TRIGGER_Blue_key_received                   = $0052
TRIGGER_Carthahena_boss_defeated            = $0053
TRIGGER_Swaffham_spy_defeated               = $0054
TRIGGER_Thar_defeated                       = $0055
TRIGGER_Luther_defeated                     = $0056
TRIGGER_Swaffham_miniboss_defeated          = $0057
TRIGGER_All_rings_collected                 = $0058
TRIGGER_Barrow_quest_1_complete             = $0059
TRIGGER_Barrow_quest_2_complete             = $005A
TRIGGER_Poison_trap_sprung                  = $005B
TRIGGER_Watling_inn_free_stay_used          = $005C
TRIGGER_Watling_inn_broke_penalty           = $005D
TRIGGER_Sixteen_rings_used_at_throne        = $005E
TRIGGER_Stow_tavern_free_meal_offered       = $005F
; Chest/Treasure flags
TRIGGER_Thar_bronze_key_collected           = $0060
TRIGGER_Thar_silver_key_collected           = $0061
TRIGGER_Luther_gold_key_collected           = $0062
TRIGGER_Knute_thule_key_dialog_shown        = $0063
TRIGGER_Thule_key_received                  = $0064
TRIGGER_Cave_key_dialog_shown               = $0065
TRIGGER_Secret_key_received                 = $0066
TRIGGER_Royal_shield_chest_opened           = $0067
TRIGGER_Money_chest_256_opened                      = $0088
TRIGGER_Herbs_chest_opened                          = $0089
TRIGGER_Herbs_chest_2_opened                        = $008A
TRIGGER_Crimson_armor_chest_opened                  = $008B
TRIGGER_Candle_chest_opened                         = $008C
TRIGGER_Herbs_chest_3_opened                        = $008D
TRIGGER_Dark_sword_chest_opened                     = $008F
TRIGGER_Herbs_chest_4_opened                        = $0090
TRIGGER_Scale_armor_chest_opened                    = $0091
TRIGGER_Money_chest_768_opened                      = $0093
TRIGGER_Candle_chest_2_opened                       = $0096
TRIGGER_Wyclif_outskirts_chest_opened               = $0098
TRIGGER_Medicine_chest_opened                       = $0099
TRIGGER_Crimson_armor_reward_enabled                = $009A
TRIGGER_Money_chest_768_b_opened                    = $009B
TRIGGER_Herbs_chest_5_opened                        = $009C
TRIGGER_Money_chest_1792_opened                     = $009E
TRIGGER_Lantern_chest_opened                        = $00A2
TRIGGER_Money_chest_8192_opened                     = $00A4
TRIGGER_Money_chest_12288_opened                    = $00A5
TRIGGER_Bearwulf_cave_entered                       = $00A7
TRIGGER_Malaga_dungeon_person_rescued               = $00A8
TRIGGER_Helwig_prison_entered                       = $00A9
TRIGGER_Malaga_key_dialog_shown                     = $00AA
TRIGGER_Dungeon_key_received                        = $00AB
TRIGGER_Replacement_key_enabled                     = $00AC
TRIGGER_Received_replacement_key                    = $00AD
TRIGGER_Candle_chest_3_opened                       = $00AE
TRIGGER_Lantern_chest_2_opened                      = $00AF
TRIGGER_Herbs_chest_6_opened                        = $00B0
TRIGGER_Ruby_brooch_chest_opened                    = $00B2
; Boss/pre-battle encounter triggers ($B3-$EC range)
TRIGGER_Cartahena_beast_challenged          = $00E0   ; CartahenaBeast pre-battle dialogue complete
TRIGGER_Tsarkon_lieutenant_challenged       = $00E1   ; "stole youth" vampire-boss pre-battle
TRIGGER_Book_thief_challenged               = $00E2   ; Book-borrowing boss pre-battle
TRIGGER_Ring_thief_challenged               = $00E3   ; "collecting rings" boss pre-battle
TRIGGER_Ring_spy_challenged                 = $00E4   ; Ring-to-Tsarkon spy boss pre-battle
TRIGGER_Thule_guardian_challenged           = $00E8   ; Tsarkon-lieutenant boss in Thule pre-battle
TRIGGER_Poison_villain_challenged           = $00E9   ; Poisoned-food villain boss pre-battle
TRIGGER_Luther_challenged                   = $00EA   ; Luther boss pre-battle
TRIGGER_Thar_challenged                     = $00EB   ; Thar boss pre-battle
TRIGGER_Tsarkon_final_challenged            = $00EC   ; Final boss (Tsarkon) pre-battle
TRIGGER_Blazon_quest_dad_acknowledged       = $0087   ; "father went to Blazon's Cave" NPC response
TRIGGER_Ancestor_treasure_clue_given        = $007A   ; Ancestor tree-treasure clue given
TRIGGER_Deepdale_crown_quest_given          = $00CD   ; Deepdale king crown-in-cave quest accepted
TRIGGER_Wyclif_women_rescue_triggered       = $00D2   ; Frying-pan lady: rescue-the-men quest active
TRIGGER_Chaos_villain_challenged            = $00A1   ; "let chaos reign" villain pre-battle
; Ring of Wisdom region
TRIGGER_Ring_of_wisdom_received             = $00F8
TRIGGER_Ring_of_sky_received                = $00F9
TRIGGER_Ring_of_earth_quest_complete        = $00FD
; Map reveal triggers (offset $100+)
; These are 16-bit offsets used to reveal areas on the world map
; Format: $01XX where XX is the map grid position
TRIGGER_Map_01_00                           = $0100
TRIGGER_Map_01_01                           = $0101
TRIGGER_Map_01_02                           = $0102
TRIGGER_Map_01_03                           = $0103
TRIGGER_Map_01_04                           = $0104
TRIGGER_Map_01_05                           = $0105
TRIGGER_Map_01_06                           = $0106
TRIGGER_Map_01_07                           = $0107
TRIGGER_Map_01_08                           = $0108
TRIGGER_Map_01_09                           = $0109
TRIGGER_Map_01_0A                           = $010A
TRIGGER_Map_01_0B                           = $010B
TRIGGER_Map_01_0C                           = $010C
TRIGGER_Map_01_0D                           = $010D
TRIGGER_Map_01_0E                           = $010E
TRIGGER_Map_01_10                           = $0110
TRIGGER_Map_01_11                           = $0111
TRIGGER_Map_01_12                           = $0112
TRIGGER_Map_01_13                           = $0113
TRIGGER_Map_01_14                           = $0114
TRIGGER_Map_01_15                           = $0115
TRIGGER_Map_01_16                           = $0116
TRIGGER_Map_01_17                           = $0117
TRIGGER_Map_01_18                           = $0118
TRIGGER_Map_01_19                           = $0119
TRIGGER_Map_01_1D                           = $011D
TRIGGER_Map_01_1C                           = $011C
TRIGGER_Map_01_21                           = $0121
TRIGGER_Map_01_22                           = $0122
TRIGGER_Map_01_23                           = $0123
TRIGGER_Map_01_24                           = $0124
TRIGGER_Map_01_25                           = $0125
TRIGGER_Map_01_26                           = $0126
TRIGGER_Map_01_27                           = $0127
TRIGGER_Map_01_28                           = $0128
TRIGGER_Map_01_29                           = $0129
TRIGGER_Map_01_2C                           = $012C
TRIGGER_Map_01_2D                           = $012D
TRIGGER_Map_01_2E                           = $012E
TRIGGER_Map_01_36                           = $0136
TRIGGER_Map_01_3C                           = $013C
TRIGGER_Map_01_3D                           = $013D
TRIGGER_Map_01_3E                           = $013E
TRIGGER_Map_01_3F                           = $013F
TRIGGER_Map_01_40                           = $0140
TRIGGER_Map_01_41                           = $0141
TRIGGER_Map_01_42                           = $0142
TRIGGER_Map_01_43                           = $0143
TRIGGER_Map_01_44                           = $0144
TRIGGER_Map_01_45                           = $0145
TRIGGER_Map_01_46                           = $0146
TRIGGER_Map_01_4C                           = $014C
TRIGGER_Map_01_4D                           = $014D
TRIGGER_Map_01_4E                           = $014E
TRIGGER_Map_01_50                           = $0150
TRIGGER_Map_01_51                           = $0151
TRIGGER_Map_01_52                           = $0152
TRIGGER_Map_01_53                           = $0153
TRIGGER_Map_01_54                           = $0154
TRIGGER_Map_01_55                           = $0155
TRIGGER_Map_01_56                           = $0156
TRIGGER_Map_01_5C                           = $015C
TRIGGER_Map_01_5D                           = $015D
TRIGGER_Map_01_60                           = $0160
TRIGGER_Map_01_62                           = $0162
TRIGGER_Map_01_65                           = $0165
TRIGGER_Map_01_66                           = $0166
TRIGGER_Map_01_67                           = $0167
TRIGGER_Map_01_68                           = $0168
TRIGGER_Map_01_69                           = $0169
TRIGGER_Map_01_6A                           = $016A
TRIGGER_Map_01_6C                           = $016C
TRIGGER_Map_01_6D                           = $016D
TRIGGER_Map_01_70                           = $0170
TRIGGER_Map_01_72                           = $0172
TRIGGER_Map_01_73                           = $0173
TRIGGER_Map_01_74                           = $0174
TRIGGER_Map_01_75                           = $0175
TRIGGER_Map_01_76                           = $0176
TRIGGER_Map_01_77                           = $0177
TRIGGER_Map_01_79                           = $0179
TRIGGER_Map_01_7A                           = $017A
TRIGGER_Map_01_7B                           = $017B
TRIGGER_Map_01_7C                           = $017C
; Additional trigger offsets for miscellaneous events
TRIGGER_Misc_00FA                           = $00FA
TRIGGER_Misc_00FC                           = $00FC
TRIGGER_Misc_00F2                           = $00F2
TRIGGER_Misc_00F3                           = $00F3
TRIGGER_Misc_00F4                           = $00F4
TRIGGER_Misc_00F5                           = $00F5
TRIGGER_Misc_00F6                           = $00F6
TRIGGER_Misc_00F7                           = $00F7
TRIGGER_Misc_011C                           = $011C

PROGRAM_STATE_SEGA_LOGO_INIT    = $00   ; Initialize Sega logo screen
PROGRAM_STATE_SEGA_LOGO         = $01   ; Sega logo display (wait for animation)
PROGRAM_STATE_TITLE_INIT        = $02   ; Initialize title screen
PROGRAM_STATE_TITLE_SCREEN      = $03   ; Title screen (handles Start/menu input)
PROGRAM_STATE_TITLE_DEMO        = $04   ; Demo loop / second Sega screen
PROGRAM_STATE_NAME_ENTRY_INIT   = $05   ; Transition: title -> name entry
PROGRAM_STATE_NAME_ENTRY        = $06   ; Name entry screen
PROGRAM_STATE_NAME_ENTRY_DONE   = $07   ; Transition: name entry -> prologue
PROGRAM_STATE_PROLOGUE_INIT     = $08   ; Initialize prologue sequence
PROGRAM_STATE_PROLOGUE          = $09   ; Prologue playing
PROGRAM_STATE_PROLOGUE_TO_GAME  = $0A   ; Transition: prologue -> main game
PROGRAM_STATE_LOAD_SAVE_INIT    = $0B   ; Transition: title -> file select screen
PROGRAM_STATE_LOAD_SAVE         = $0C   ; File select / continue screen
PROGRAM_STATE_LOAD_SAVE_DONE    = $0D   ; Transition: file select -> game
PROGRAM_STATE_GAME_FADE_IN      = $0E   ; Fade in to main game (shared with $10)
PROGRAM_STATE_GAME_ACTIVE       = $0F   ; Main game running (shared with $11)
PROGRAM_STATE_GAME_FADE_IN_2    = $10   ; Fade in to main game (alias for $0E)
PROGRAM_STATE_GAME_ACTIVE_2     = $11   ; Main game running (alias for $0F)
PROGRAM_STATE_ENDING_INIT       = $12   ; Initialize ending sequence
PROGRAM_STATE_ENDING            = $13   ; Ending sequence active (shared with $14)
PROGRAM_STATE_ENDING_2          = $14   ; Ending sequence active (alias for $13)
PROGRAM_STATE_LOAD_SAVED_GAME   = $15   ; Load saved game state, initialize town

; Gameplay state constants (for Gameplay_state variable)
GAMEPLAY_STATE_INIT_TOWN_ENTRY = $00
GAMEPLAY_STATE_LOAD_TOWN = $01
GAMEPLAY_STATE_TOWN_EXPLORATION = $02
GAMEPLAY_STATE_INIT_BUILDING_ENTRY = $03
GAMEPLAY_STATE_BUILDING_INTERIOR = $04
GAMEPLAY_STATE_TRANSITION_TO_SECOND_FLOOR = $05
GAMEPLAY_STATE_SECOND_FLOOR_ACTIVE = $06
GAMEPLAY_STATE_TRANSITION_TO_THIRD_FLOOR = $07
GAMEPLAY_STATE_THIRD_FLOOR_ACTIVE = $08
GAMEPLAY_STATE_TRANSITION_TO_CASTLE_MAIN = $09
GAMEPLAY_STATE_CASTLE_ROOM1_ACTIVE = $0A
GAMEPLAY_STATE_LOAD_CASTLE_ROOM2 = $0B
GAMEPLAY_STATE_CASTLE_ROOM2_ACTIVE = $0C
GAMEPLAY_STATE_LOAD_CASTLE_ROOM3 = $0D
GAMEPLAY_STATE_CAVE_ENTRANCE = $0E
GAMEPLAY_STATE_BATTLE_INITIALIZE = $0F
GAMEPLAY_STATE_BATTLE_ACTIVE = $10
GAMEPLAY_STATE_BATTLE_EXIT = $11
GAMEPLAY_STATE_OVERWORLD_RELOAD = $12
GAMEPLAY_STATE_OVERWORLD_ACTIVE = $13
GAMEPLAY_STATE_TOWN_FADE_IN_COMPLETE = $14
GAMEPLAY_STATE_ENTERING_CAVE = $15
GAMEPLAY_STATE_CAVE_EXPLORATION = $16
GAMEPLAY_STATE_CAVE_FADE_OUT_COMPLETE = $17
GAMEPLAY_STATE_ENCOUNTER_INITIALIZE = $18
GAMEPLAY_STATE_ENCOUNTER_GRAPHICS_FADE_IN = $19
GAMEPLAY_STATE_ENCOUNTER_PAUSE_BEFORE_BATTLE = $1A
GAMEPLAY_STATE_LEVEL_UP_BANNER_DISPLAY = $1B
GAMEPLAY_STATE_LEVEL_UP_STATS_WAIT_INPUT = $1C
GAMEPLAY_STATE_LEVEL_UP_COMPLETE = $1D
GAMEPLAY_STATE_RETURN_TO_FIRST_PERSON_VIEW = $1E
GAMEPLAY_STATE_FADE_IN_COMPLETE = $1F
GAMEPLAY_STATE_DIALOG_DISPLAY = $20
GAMEPLAY_STATE_BOSS_BATTLE_INIT = $21
GAMEPLAY_STATE_BOSS_BATTLE_ACTIVE = $22
GAMEPLAY_STATE_RETURN_FROM_BOSS_BATTLE = $23
GAMEPLAY_STATE_BEGIN_RESURRECTION = $24
GAMEPLAY_STATE_PROCESS_RESURRECTION = $25
GAMEPLAY_STATE_NOTIFY_INAUDIOS_EXPIRED = $26
GAMEPLAY_STATE_WAIT_FOR_NOTIFICATION_DISMISS = $27
GAMEPLAY_STATE_READ_AWAKENING_MESSAGE = $28
GAMEPLAY_STATE_FRYING_PAN_DELAY = $29
GAMEPLAY_STATE_READ_FRYING_PAN_MESSAGE = $2A
GAMEPLAY_STATE_SOLDIER_TAUNT = $2B
GAMEPLAY_STATE_READ_SOLDIER_TAUNT = $2C
GAMEPLAY_STATE_SHOW_POISON_NOTIFICATION = $2D

; Boss 1 (Hydra/Snake) AI state machine states (Boss_ai_state, BossAiStateJumpTable)
BOSS1_STATE_INIT_IDLE       = 0   ; Randomise idle timer, wait
BOSS1_STATE_CHOOSE_ACTION   = 1   ; Pick next attack/move
BOSS1_STATE_MOVE_DOWN       = 2   ; Descend toward player
BOSS1_STATE_HEAD_EXTEND     = 3   ; Extend head for bite attack
BOSS1_STATE_ATTACK_WAIT     = 4   ; Hold extended, check hit window
BOSS1_STATE_LUNGE_LEFT      = 5   ; Lunge across arena to left
BOSS1_STATE_RETURN_HOME     = 6   ; Return to home position
BOSS1_STATE_HEAD_RETRACT    = 7   ; Retract head after bite
BOSS1_STATE_CHARGE_DOWN_LEFT = 8  ; Charge diagonally down-left

; Spellbook menu state machine states (Spellbook_menu_state, SpellbookMenuStateJumpTable)
; Masked with $1F before indexing so only low 5 bits matter.
SPELLBOOK_STATE_INIT        = 0   ; Draw spell action menu window, init cursor
SPELLBOOK_STATE_WAIT_INPUT  = 1   ; Wait for spell/action selection or B to cancel
SPELLBOOK_STATE_CLOSE       = 2   ; Close menus, return to overworld menu
SPELLBOOK_STATE_PUT_DOWN    = 3   ; "Put down book" script running
SPELLBOOK_STATE_EQUIP_INIT  = 4   ; Equip flow: draw item list, init
SPELLBOOK_STATE_EQUIP_WAIT  = 5   ; Equip flow: wait for equip confirm
SPELLBOOK_STATE_USE_INIT    = 6   ; Use flow: init use-item prompt
SPELLBOOK_STATE_USE_WAIT    = 7   ; Use flow: wait for item selection
SPELLBOOK_STATE_CAST_INIT   = 8   ; Cast spell: init dialogue
SPELLBOOK_STATE_CAST_WAIT   = 9   ; Cast spell: wait for script / show "can't use here"
SPELLBOOK_STATE_CAST_DONE   = $A  ; Cast spell: script done, show HP/MP
SPELLBOOK_STATE_SHOW_HP_MP  = $B  ; Show HP/MP after cast
SPELLBOOK_STATE_STATUS_C    = $C  ; Status update step C
SPELLBOOK_STATE_STATUS_D    = $D  ; Status update step D
SPELLBOOK_STATE_STATUS_E    = $E  ; Status update step E
SPELLBOOK_STATE_STATUS_F    = $F  ; Status update step F (final)

; Item menu state machine states (Item_menu_state, ItemMenuStateJumpTable)
; Masked with $F before indexing so only low 4 bits matter.
ITEM_MENU_STATE_INIT         = 0  ; Draw use/discard window, init cursor
ITEM_MENU_STATE_WAIT_INPUT   = 1  ; Wait for use/discard/cancel selection
ITEM_MENU_STATE_CLOSE        = 2  ; Close menus ("nothing to use" or cancel)
ITEM_MENU_STATE_SCRIPT_DONE  = 3  ; Generic script done, restore HUD
ITEM_MENU_STATE_DISCARD_INIT = 4  ; Discard flow: show item list
ITEM_MENU_STATE_DISCARD_WAIT = 5  ; Discard flow: wait for item selection
ITEM_MENU_STATE_DISCARD_EXEC = 6  ; Discard flow: execute discard
ITEM_MENU_STATE_DISCARD_DONE = 7  ; Discard flow: done, restore
ITEM_MENU_STATE_USE_INIT     = 8  ; Use flow: show item list
ITEM_MENU_STATE_USE_WAIT     = 9  ; Use flow: wait for item selection
ITEM_MENU_STATE_USE_DESC     = $A ; Use flow: build item description string
ITEM_MENU_STATE_USE_CAVE     = $B ; Use flow: cave-light continuation (Candle/Lantern)
ITEM_MENU_STATE_CAVE_DONE    = $C ; Cave-light script done
ITEM_MENU_STATE_WARP_INIT    = $D ; Warp init (Griffin Wing / teleport)
ITEM_MENU_STATE_WARP_EXEC    = $E ; Warp execution (Gnome Stone / exit cave)

; ============================================================
; Overworld Menu State Machine (Overworld_menu_state)
; ============================================================
; Top-level overworld menu: Start=message speed, C=options menu,
; then dispatches into sub-menus via OverworldMenuActionPtrs.
;
OVERWORLD_MENU_STATE_IDLE         = 0  ; Idle — waiting for Start/C input
OVERWORLD_MENU_STATE_MSG_SPEED    = 1  ; Draw message speed menu
OVERWORLD_MENU_STATE_MSG_SPEED_WAIT = 2 ; Wait for message speed selection
OVERWORLD_MENU_STATE_OPTIONS_INIT = 3  ; Draw options/main menu
OVERWORLD_MENU_STATE_OPTIONS_WAIT = 4  ; Wait for main menu selection (cursor active)
OVERWORLD_MENU_STATE_DISPATCH     = 5  ; Dispatch selected sub-menu action

; ============================================================
; Open/Chest Menu State Machine (Open_menu_state)
; ============================================================
; Handles player "Open" action for treasure chests and doors.
;
OPEN_MENU_STATE_DETECT       = 0  ; Detect chest/door in front of player
OPEN_MENU_STATE_MSG_WAIT     = 1  ; Message displayed — waiting for dismiss
OPEN_MENU_STATE_CLOSE        = 2  ; Restore HUD after message
OPEN_MENU_STATE_ANIMATION    = 3  ; Chest open animation running
OPEN_MENU_STATE_TILE_DELAY   = 4  ; Wait for tile-change timer before reward
OPEN_MENU_STATE_OPEN_DELAY   = 5  ; Wait for open delay before showing contents
OPEN_MENU_STATE_CONTENTS     = 6  ; Display chest contents / reward

; ============================================================
; Take Item State Machine (Take_item_state)
; ============================================================
; Handles item/reward pick-up flow: detect, message, inventory full,
; yes/no confirmation, discard, and finalize.
;
TAKE_ITEM_STATE_INIT         = 0  ; Init cursor position
TAKE_ITEM_STATE_CHECK        = 1  ; Check for available reward (first-person / overworld)
TAKE_ITEM_STATE_NO_ITEM_MSG  = 2  ; Show "nothing to take" message
TAKE_ITEM_STATE_MSG_WAIT     = 3  ; Wait for message dismiss
TAKE_ITEM_STATE_BUILD_REWARD = 4  ; Build reward item message
TAKE_ITEM_STATE_FULL_MSG     = 5  ; Show "cannot carry more" message
TAKE_ITEM_STATE_CONFIRM      = 6  ; Show yes/no confirm discard dialog
TAKE_ITEM_STATE_DISCARD_LIST = 7  ; Show discard item list
TAKE_ITEM_STATE_ITEM_CURSOR  = 8  ; Navigate item list cursor
TAKE_ITEM_STATE_DISCARD_CONFIRM = 9 ; Confirm discard yes/no
TAKE_ITEM_STATE_FINALIZE     = $A ; Finalize take (clear flags, return)

; ============================================================
; Ready Equipment State Machine (Ready_equipment_state)
; ============================================================
; Handles equip/unequip flow from the overworld equipment menu.
;
READY_EQUIP_STATE_INIT       = 0  ; Init cursor / draw equipment menu
READY_EQUIP_STATE_WAIT       = 1  ; Wait for category selection
READY_EQUIP_STATE_OPTIONS    = 2  ; Draw equip-options sub-menu (equip/unequip)
READY_EQUIP_STATE_LIST_WAIT  = 3  ; Wait for equip-list selection
READY_EQUIP_STATE_SHOW_LIST_A = 4 ; Show equip list (same handler as 5 — category A)
READY_EQUIP_STATE_SHOW_LIST_B = 5 ; Show equip list (category B — unequip path)
READY_EQUIP_STATE_RESULT_MSG = 6  ; Show equip/unequip result message

; ============================================================
; Equip-List Viewer State Machine (Equip_list_menu_state)
; ============================================================
; Shows the full character-sheet gear/combat/magic/items/rings/status
; pages, cycling through each window page by page.
;
EQUIP_LIST_STATE_INIT        = 0  ; Init viewer, draw character stats
EQUIP_LIST_STATE_STATS_WAIT  = 1  ; Wait for page input on stats window
EQUIP_LIST_STATE_GEAR_PAGE   = 2  ; Draw equipped-gear window
EQUIP_LIST_STATE_COMBAT_PAGE = 3  ; Draw combat-stats window
EQUIP_LIST_STATE_MAGIC_PAGE  = 4  ; Draw magic-list window
EQUIP_LIST_STATE_ITEMS_PAGE  = 5  ; Draw items-list window
EQUIP_LIST_STATE_RINGS_PAGE  = 6  ; Draw rings-list window
EQUIP_LIST_STATE_STATUS_WAIT = 7  ; Status page — wait for input
EQUIP_LIST_STATE_EXIT_SCRIPT = 8  ; Exit to script/HUD draw
EQUIP_LIST_STATE_CURSOR_INIT = 9  ; Init item-list cursor
EQUIP_LIST_STATE_CURSOR_ITEM = $A ; Cursor active on items page
EQUIP_LIST_STATE_CURSOR_MAGIC = $B ; Cursor active on magic page
EQUIP_LIST_STATE_CURSOR_EQUIP = $C ; Cursor active on equip-list page
EQUIP_LIST_STATE_CURSOR_FULL = $D ; Cursor active on full-menu page

; ============================================================
; File Menu Phase State Machine (File_menu_phase)
; ============================================================
; Manages save-file select/load/save confirmation screens.
;
FILE_MENU_PHASE_DRAW_SELECT  = 0  ; Draw save-file select window
FILE_MENU_PHASE_WAIT_SELECT  = 1  ; Wait for save-slot selection
FILE_MENU_PHASE_VERIFY       = 2  ; Verify checksum / load selected file
FILE_MENU_PHASE_LOAD_ERROR   = 3  ; Display checksum error window
FILE_MENU_PHASE_NO_SAVE      = 4  ; Display "no saved game" window
FILE_MENU_PHASE_SUCCESS      = 5  ; Display load/save success window

; ============================================================
; Reward Script Type (Reward_script_type)
; ============================================================
; Identifies what kind of reward is in a treasure chest or field pickup.
; The code branches on these values to build the appropriate item-name
; string and to route into the correct inventory list.
; Types 0–2 index into ShopCategoryNameTables (items/equipment/magic).
; Types 3–5 are handled as special cases before the table lookup.
;
REWARD_TYPE_ITEM        = 0  ; Consumable item (indexes ItemNames)
REWARD_TYPE_EQUIPMENT   = 1  ; Weapon/armor/shield (indexes EquipmentNames)
REWARD_TYPE_MAGIC       = 2  ; Magic spell (indexes MagicNames)
REWARD_TYPE_MONEY       = 3  ; Kims (gold) — prints MoneyInsideStr
REWARD_TYPE_RING        = 4  ; Ring (indexes RingNames)
REWARD_TYPE_MAP         = 5  ; Area map reveal — sets Map_trigger_flags

; ============================================================
; Reward Script Values (Reward_script_value)
; ============================================================
; Packed word written to Reward_script_value before calling
; SetupItemTreasure or SetupEquipmentTreasure.
; High byte = category selector (equipment: EQUIPMENT_TYPE_*;
;             items: $01; the low byte is masked off at decode time).
; Low byte  = item/equipment index within its category.
; These constants correspond to the 12 unique chest/field reward
; sites in vermilion.asm.
;
REWARD_VALUE_TRUFFLE          = $010B  ; Truffle (item $0B)
REWARD_VALUE_DIGOT_PLANT      = $010C  ; Digot Plant (item $0C)
REWARD_VALUE_TREASURE_OF_TROY = $010D  ; Treasure of Troy (item $0D)
REWARD_VALUE_WHITE_CRYSTAL    = $010E  ; White Crystal (item $0E)
REWARD_VALUE_RED_CRYSTAL      = $010F  ; Red Crystal (item $0F)
REWARD_VALUE_BLUE_CRYSTAL     = $0110  ; Blue Crystal (item $10)
REWARD_VALUE_CROWN            = $0114  ; Crown (item $14)
REWARD_VALUE_BRONZE_KEY       = $0116  ; Bronze Key (item $16)
REWARD_VALUE_SILVER_KEY       = $0117  ; Silver Key (item $17)
REWARD_VALUE_GOLD_KEY         = $0118  ; Gold Key (item $18)
REWARD_VALUE_POISON_SHIELD    = $0823  ; Poison Shield (EQUIPMENT_TYPE_SHIELD | EQUIPMENT_SHIELD_POISON)
REWARD_VALUE_CRIMSON_ARMOR    = $1037  ; Crimson Armor (EQUIPMENT_TYPE_ARMOR | EQUIPMENT_ARMOR_CRIMSON)


; ============================================================
; Terrain Tileset Index (Terrain_tileset_index)
; ============================================================
; Selects which battle-field background tileset to load.
; Set by LoadBattleTerrainGraphics before loading tile graphics.
;
TERRAIN_TILESET_SOLDIER = 0  ; Town/soldier-fight grass tiles
TERRAIN_TILESET_FIELD   = 1  ; Overworld field (dominant tile type)
TERRAIN_TILESET_CAVE    = 2  ; Cave interior tiles
TERRAIN_TILESET_BOSS    = 3  ; Boss arena tiles

; ============================================================
; Town Tileset Index (Town_tileset_index)
; ============================================================
; Selects which town building/tile graphics set to load.
; Set per-town by SetTileset_* functions.
;
TOWN_TILESET_VILLAGE_A  = 0  ; Standard village style A (Wyclif, Watling, Barrow, Helwig, Hastings)
TOWN_TILESET_VILLAGE_B  = 1  ; Standard village style B (most other towns)
TOWN_TILESET_EXCALABRIA = 2  ; Excalabria / ruined-Swafham style

; ============================================================
; Battle / Overworld Play-Field Boundaries (pixels)
; ============================================================
; The battle and overworld play-field is 320×184 pixels but the
; top 56 pixels are reserved for the HUD, leaving a 320×128 active
; area. Entity world-space coordinates are clamped to these limits.
;
BATTLE_FIELD_WIDTH      = $0140   ; Play-field width  (320 px)
BATTLE_FIELD_TOP        = $0038   ; Top    boundary   ( 56 px — below HUD)
BATTLE_FIELD_BOTTOM     = $00B8   ; Bottom boundary   (184 px)
; Right/bottom edge for battle sprites: sprites with world_x or world_y >= this
; are off the visible arena. Also used as boss-body Y floor clamp.
BATTLE_ARENA_EDGE       = $00A8   ; 168 px — right edge / boss Y floor of battle arena

; Boss battle arena X boundaries for the player entity and spawning.
; The 320 px play-field runs from pixel 0 to $013F, but entities are
; clamped to a tighter 16–296 px range so sprites never clip the HUD frame.
BOSS_BATTLE_PLAYER_X_MIN = $0010  ; 16 px  — leftmost allowed player/entity X in boss arena
BOSS_BATTLE_PLAYER_X_MAX = $0128  ; 296 px — rightmost allowed player/entity X in boss arena

; DemonBoss (OrbitBoss) HP values for normal and hard difficulty.
; Written to obj_hp (entity HP) and Boss_max_hp (for the on-screen boss HP bar).
BOSS_HP_ORBIT_NORMAL    = $05DC   ; 1500 HP — OrbitBoss normal difficulty
BOSS_HP_ORBIT_HARD      = $270F   ; 9999 HP — OrbitBoss hard difficulty

; DemonBoss (OrbitBoss) body contact damage per hit (written to obj_max_hp of the boss entity).
BOSS_DMG_DEMON_NORMAL   = $0048   ; 72  damage — DemonBoss contact damage, normal difficulty
BOSS_DMG_DEMON_HARD     = $00C8   ; 200 damage — DemonBoss contact damage, hard difficulty

; OrbitBoss orbit-ring satellite HP and contact damage.
; obj_hp is reset to BOSS_HP_ORBIT_PART each time a ring part respawns.
BOSS_HP_ORBIT_PART      = $0960   ; 2400 HP   — OrbitBoss ring satellite part HP
BOSS_DMG_ORBIT_PART     = $008C   ; 140 damage — OrbitBoss ring satellite contact damage

; RingGuardian (Boss 1) HP and contact damage by difficulty.
; obj_max_hp is the boss body contact damage; obj_hp is the total boss HP pool.
BOSS_HP_RING_NORMAL     = $03E8   ; 1000 HP   — RingGuardian HP, normal difficulty
BOSS_HP_RING_HARD       = $1388   ; 5000 HP   — RingGuardian HP, hard / very-hard difficulty
BOSS_DMG_RING_NORMAL    = $0032   ; 50  damage — RingGuardian contact damage, normal
BOSS_DMG_RING_HARD      = $0186   ; 390 damage — RingGuardian contact damage, hard
BOSS_DMG_RING_VERYHARD  = $01D6   ; 470 damage — RingGuardian contact damage, very-hard

; TwoHeadedDragon HP and contact damage by difficulty.
BOSS_HP_DRAGON_NORMAL   = $0AF0   ; 2800 HP   — TwoHeadedDragon HP, normal difficulty
BOSS_HP_DRAGON_HARD     = $0DAC   ; 3500 HP   — TwoHeadedDragon HP, hard difficulty
BOSS_HP_DRAGON_VERYHARD = $1D4C   ; 7500 HP   — TwoHeadedDragon HP, very-hard difficulty
BOSS_DMG_DRAGON_NORMAL  = $003C   ; 60  damage — TwoHeadedDragon contact damage, normal
BOSS_DMG_DRAGON_HARD    = $0064   ; 100 damage — TwoHeadedDragon contact damage, hard
BOSS_DMG_DRAGON_VERYHARD= $00B4   ; 180 damage — TwoHeadedDragon contact damage, very-hard

; HydraBoss HP and contact damage by difficulty.
BOSS_HP_HYDRA_NORMAL    = $09C4   ; 2500 HP   — HydraBoss HP, normal difficulty
BOSS_HP_HYDRA_HARD      = $1388   ; 5000 HP   — HydraBoss HP, hard difficulty
BOSS_DMG_HYDRA_NORMAL   = $0064   ; 100 damage — HydraBoss contact damage, normal
BOSS_DMG_HYDRA_HARD     = $0078   ; 120 damage — HydraBoss contact damage, hard

; Chronos / Chronios spell duration timers.
; Written to obj_hp of a countdown object; the object deactivates when hp reaches 0.
CHRONOS_DURATION        = $00C8   ; 200 ticks — Chronos spell active duration
CHRONIOS_DURATION       = $01F4   ; 500 ticks — Chronios spell active duration

; After masking a random number to 8 bits (ANDI.w #$00FF), comparing
; against this threshold gives a 50% probability split (0-127 vs 128-255).
RANDOM_HALF_THRESHOLD   = $0080   ; 50% RNG threshold (128 of 256)

; Player post-hit invulnerability frame countdown.
; Written to obj_invuln_timer(player entity) in every player damage handler.
PLAYER_HIT_INVULN_FRAMES = $10   ; 16 frames — player invulnerability after taking damage

; Standard enemy knockback timer duration.
; Written to obj_knockback_timer(A5) after an enemy is hit, controlling
; the knockback-and-pause phase before the enemy resumes its AI.
ENEMY_KNOCKBACK_DURATION = $0028  ; 40 frames — standard enemy knockback duration

; Battle victory delay: after all enemies in the field are defeated
; (Number_Of_Enemies < 0), the player entity waits this many ticks before
; switching to the post-victory tick handler (score tally, item drop, etc.).
BATTLE_VICTORY_DELAY    = $3C    ; 60 ticks — post-battle win delay before victory handler (1 write site)

; Tile-space visibility radius used by CheckEntityOnScreen.
; Entity tile coordinate (world_coord - camera) >> 4 is compared against this.
ENTITY_VISIBLE_TILE_RADIUS = $0019  ; 25 tiles — entity considered off-screen if >= this

; Pixel distance threshold for enemy proximity-chase activation.
; Compared against |player_world_x - enemy_world_x| and |player_world_y - enemy_world_y|.
ENEMY_CHASE_PROXIMITY   = $0040   ; 64 px — player within this range triggers chase

; Enemy stalk/bounce AI: direction recheck cooldown.
; After calculating angle toward the player, obj_attack_timer is set to this value.
; The enemy will not recalculate its direction until the timer expires (180 ticks ≈ 3 s).
ENEMY_STALK_RECHECK_DELAY = $00B4  ; 180 ticks — stalk/bounce enemy direction-recheck cooldown (2 write sites)

; Y offset used when drawing first-person dungeon wall tiles.
; Applied to the tile screen Y coordinate during wall rendering.
WALL_TILE_Y_OFFSET      = $000C   ; 12 px — standard wall tile Y offset (4 write sites)

; Enemy animation frame mask values. Used for Enemy_anim_frame_mask to
; control the animation cycle length. Masked against obj_move_counter,
; then shifted right by Enemy_anim_frame_shift to get the current frame.
ENEMY_ANIM_FRAME_MASK_24 = $0018  ; 24-frame animation cycle (MeleeA/B large-sprite enemies)
ENEMY_ANIM_FRAME_MASK_12 = $000C  ; 12-frame animation cycle (StalkPause and small-sprite enemies)

; Boss sprite animation phase endpoint.
; After masking obj_move_counter with $0030 or $0018 and shifting right,
; the result is compared against this to detect end-of-animation-cycle.
BOSS_ANIM_PHASE_END     = $000C   ; 12 — animation cycle complete when phase reaches this

; OrbitBoss fire-ring animation: obj_move_counter is masked with $0070 and
; compared against this to decide when to spawn a fire projectile.
ORBIT_BOSS_FIRE_PHASE   = $0030   ; 48 — fire phase threshold within move_counter cycle

; DemonBoss horizontal patrol/fire-zone limits (obj_world_x comparisons).
DEMON_BOSS_X_LEFT_BOUND = $0070   ; 112 px — left  edge of DemonBoss patrol/fire zone
DEMON_BOSS_X_RIGHT_BOUND= $0120   ; 288 px — right edge of DemonBoss patrol/fire zone

; DemonBoss projectile Y floor — segment deactivates below this Y.
DEMON_BOSS_PROJ_Y_FLOOR = $00B0   ; 176 px — projectile segment Y deactivation threshold

; DemonBoss attack-animation timer: obj_attack_timer counts down from $0064.
; When it reaches this value, the boss fires its wing-bomb mid-animation.
DEMON_BOSS_ATTACK_FIRE_TICK = $000A  ; 10 — timer tick at which DemonBoss wing attack fires

; DemonBoss projectile segment animation frame count.
; Segment tick function counts obj_attack_timer up; animation stops at this value.
DEMON_BOSS_SEG_ANIM_FRAMES = $0010   ; 16 — DemonBoss projectile segment animation frame count

; DemonBoss wing movement pause: 30-tick delay used at three points in the wing AI —
; initial delay before the wing starts moving (obj_attack_timer at init), inter-segment
; bounce pause (demon_move_timer during movement), and wall-rebound delay (obj_attack_timer).
DEMON_BOSS_MOVE_DELAY   = $001E   ; 30 ticks — DemonBoss wing pause at init/bounce/rebound (3 write sites)

; Falling projectile Y floor shared by OrbitBoss and RingGuardian child projectiles.
; Projectiles clamp to and impact at this Y.
ORBIT_PROJ_Y_FLOOR      = $00AC   ; 172 px — falling projectile floor Y (OrbitBoss & RingGuardian)

; RingGuardian (Boss 1) horizontal position clamps during attack charge.
RING_GUARDIAN_X_LEFT    = $0018   ; 24 px  — RingGuardian left X clamp
RING_GUARDIAN_X_RIGHT   = $00E8   ; 232 px — RingGuardian right X clamp

; RingGuardian head-extend Y threshold: boss triggers head attack when player Y >= this.
RING_GUARDIAN_HEAD_Y    = $0044   ; 68 px  — RingGuardian head-extend activation Y

; NPC behavior timing thresholds (used via obj_hit_flag / obj_invuln_timer as counters).
NPC_ROTATION_FRAMES     = $20     ; 32 frames — NPC rotation/turn animation frame count
NPC_WANDER_DELAY        = $32     ; 50 ticks  — NPC wander direction change delay
NPC_STUCK_THRESHOLD     = $78     ; 120 ticks — NPC stuck-repath trigger threshold

; Boss part hit stun: written to obj_knockback_timer on all boss body-part entities
; immediately after they take a hit. The part is paused for this many frames before
; resuming its AI. Distinct from ENEMY_KNOCKBACK_DURATION (standard field enemies).
BOSS_HIT_STUN_FRAMES    = $0010   ; 16 frames — boss body-part post-hit pause duration (9 write sites)

; RingGuardian (Boss 1) state-machine phase timers (written to obj_invuln_timer).
; The boss AI cycles: pause-and-reset → head-extend → attack-wait → head-retract → return-home.
BOSS1_HEAD_PAUSE_TICKS  = $28    ; 40 ticks — pause before head extends / dwell in attack-wait state
BOSS1_HEAD_EXTEND_TICKS = $64    ; 100 ticks — dwell time while boss head is extending

; Boss state-transition delay: written to obj_invuln_timer on OrbitBoss inner/outer
; parts and RingGuardian when transitioning back to the "select target / choose action"
; state. Acts as a cool-down between attack phases (80 ticks ≈ 1.3 s at 60 Hz).
BOSS_STATE_DELAY        = $50     ; 80 ticks — boss inter-phase cool-down delay (4 write sites)

; Boss victory/death inter-phase pause: written to obj_invuln_timer during the
; post-battle victory sequence (death fall → victory pose → fade) and HydraBoss
; death clear-screen. Controls the dwell time between each cutscene phase (50 ticks).
BOSS_VICTORY_PAUSE      = $32     ; 50 ticks — boss victory/death sequence phase dwell time (4 write sites)

; Death-scatter projectile spread: enemy/boss death handlers cycle an angle index
; from 0 to (DEATH_SCATTER_ANGLE_COUNT-1) = 34 before resetting direction.
DEATH_SCATTER_ANGLE_COUNT = $23   ; 35 — number of spread angles in the death scatter loop

; RingGuardian (Boss 1) lower Y limit for state transitions.
; Boss deactivates or changes state when obj_world_y > this value.
RING_GUARDIAN_Y_LOWER   = $0096   ; 150 px — RingGuardian lower Y boundary for state change

; OrbitBoss maximum orbit radius (stored in obj_pos_x_fixed of orbit child).
; Orbit-expand functions continue until radius reaches this value.
ORBIT_BOSS_MAX_RADIUS   = $1388   ; 5000 — orbit radius ceiling for OrbitBoss expand phase

; OrbitBoss charge direction accumulates each frame; when it reaches this
; value the boss transitions to its fire state.
ORBIT_BOSS_DIRECTION_WRAP = $A0   ; 160 — OrbitBoss charge direction wraparound threshold

; OrbitBoss outer approach: only initiates charge if player X is above this value.
ORBIT_BOSS_CHARGE_X_MIN = $0046   ; 70 px — minimum player X for OrbitBoss outer charge

; OrbitBoss approach-phase timer: after selecting a target the boss has this many ticks
; to close distance before transitioning to the charge state (inner and outer parts share).
ORBIT_BOSS_APPROACH_TICKS = $0080  ; 128 ticks — approach phase budget (2 write sites)

; OrbitBoss victory-cutscene delay: after the boss is defeated, obj_attack_timer counts
; down from this value before transitioning to the post-victory dialog handler.
ORBIT_BOSS_VICTORY_DELAY = $0080   ; 128 ticks — post-defeat cutscene delay (1 write site)

; OrbitBoss charge-phase timer: set when the boss begins its charge, giving it this many
; ticks to complete the dash before the attack phase expires (inner and outer parts share).
ORBIT_BOSS_CHARGE_TICKS = $0100   ; 256 ticks — charge phase budget (2 write sites)

; OrbitBoss satellite part initial invuln timer. Written to obj_invuln_timer when the
; inner and outer orbit parts first spawn, preventing immediate damage before they appear.
ORBIT_BOSS_PART_SPAWN_INVULN = $14  ; 20 ticks — orbit part spawn invulnerability (2 write sites)

; OrbitingSpiral projectile orbit cycle count (stored in obj_xp_reward as scratch counter).
; When the counter reaches this value, the projectile transitions to straight-line travel.
ORBITING_SPIRAL_ORBIT_COUNT = $0040  ; 64 — OrbitingSpiral orbit cycles before breaking out

; Projectile top-of-field boundary (Y). Spiral and OrbitingSpiral projectiles
; deactivate when obj_world_y <= this, which is above the HUD (BATTLE_FIELD_TOP = $0038).
BATTLE_PROJ_Y_TOP       = $0020   ; 32 px — projectile upper boundary (spiral/orbiting projectiles)

; Projectile off-screen left boundary (X).
; TwoHeadedDragon and HydraBoss projectiles deactivate when obj_world_x < this.
PROJ_OFFSCREEN_X_LEFT   = $FFF6   ; -10 px — projectile left-edge deactivation threshold

; HydraBoss split X threshold: boss activates its second head only when player X < this.
HYDRA_BOSS_SPLIT_X      = $00E0   ; 224 px — HydraBoss second-head activation player X threshold

; Ferros spell orbit: orbit radius expands (via obj_pos_x_fixed) until it reaches this
; 16.16 fixed-point value before the projectile begins hitting enemies.
FERROS_ORBIT_MAX_RADIUS = $00180000  ; 24.0 (fixed 16.16) — Ferros orbit expansion ceiling

; DescendingArc projectile: attack timer counts up from 0; gravity fully engages at this value.
DESCENDING_ARC_GRAVITY_ONSET = $0014  ; 20 ticks — DescendingArc timer threshold for full gravity

; ============================================================
; Sprite Sort-Key (obj_sort_key) Layer Constants
; ============================================================
; obj_sort_key controls sprite rendering Z-depth. Higher values draw in front.
; Three standard layers are used by the object tick helpers:
SORT_KEY_SINGLE_OBJ     = $000A   ; 10 — standalone single-sprite objects (SingleObjectTick)
SORT_KEY_PAIRED_OBJ     = $0014   ; 20 — paired two-sprite objects (PairedObjectTick)
SORT_KEY_CHAIN_OBJ      = $001E   ; 30 — multi-sprite chain/portrait objects (ChainObjectTick)

; Boss-specific sort keys (set during entity init):
SORT_KEY_ORBIT_INNER    = $0032   ; 50  — OrbitBoss inner ring satellite
SORT_KEY_ORBIT_OUTER    = $0046   ; 70  — OrbitBoss outer ring satellite
SORT_KEY_HYDRA_HEAD     = $00AC   ; 172 — HydraBoss head entity
SORT_KEY_DEMON_WING     = $00B0   ; 176 — DemonBoss wing entity

; Boss projectile sort key — used by TwoHeadedDragon fireballs, OrbitBoss falling
; projectiles, and HydraBoss bite projectiles. Draws above all enemy bodies.
SORT_KEY_BOSS_PROJ      = $00FA   ; 250 — boss projectile front-layer sort key (4 write sites)

; SetRandomEnemyPosition spawn-zone boundaries.
; These define where enemies may be placed in the battle field.
; The "safe zone" is a central area near the player where enemies are
; NOT allowed to spawn (the function re-rolls if the result lands inside it).
SPAWN_ZONE_X_MAX        = $013F   ; 319 px — maximum random X before wrapping
SPAWN_ZONE_Y_MIN        = $0039   ; 57 px  — minimum valid Y position
SPAWN_ZONE_Y_MAX        = $00B7   ; 183 px — maximum valid Y before wrapping
SPAWN_SAFE_X_MIN        = $0088   ; 136 px — safe-zone left X (no-spawn center begins here)
SPAWN_SAFE_Y_MIN        = $004C   ; 76 px  — safe-zone top Y
SPAWN_SAFE_Y_MAX        = $006C   ; 108 px — safe-zone bottom Y

; ============================================================
; RAM Addresses
; ============================================================

; ------------------------------------------------------------
; Tilemap Plane Buffers
; ------------------------------------------------------------
Tilemap_buffer_plane_a       = $FFFF0000
Battle_gfx_slot_1_buffer     = $FFFF1500
Boss_gfx_slot_1_buffer       = $FFFF1800
Tilemap_buffer_plane_b       = $FFFF2000
Boss_gfx_extra_buffer        = $FFFF3600
Boss_gfx_slot_2_buffer       = $FFFF3A00
Player_overworld_gfx_buffer = $FFFF4000
Battle_gfx_slot_2_buffer     = $FFFF4200
Town_tilemap_plane_a         = $FFFF4D80
Town_tilemap_plane_a_data    = $FFFF4D84
Town_tilemap_plane_b         = $FFFF6380
Town_tilemap_plane_b_data    = $FFFF6384
Message_speed_menu_tiles_buffer = $FFFF7980
Script_window_tiles_buffer = $FFFF7AB4
Small_menu_tiles_buffer    = $FFFF7CF4
Item_list_tiles_buffer     = $FFFF7D56
Right_menu_tiles_buffer    = $FFFF7DCC
Large_menu_tiles_buffer    = $FFFF7E52
Ready_equipment_menu_tiles_buffer = $FFFF7E80
Full_menu_tiles_buffer       = $FFFF7F4C
Equipment_list_tiles_buffer  = $FFFF820A
Status_menu_tiles_buffer   = $FFFF821A
Shop_list_tiles_buffer       = $FFFF82AA
Prompt_menu_tiles_buffer     = $FFFF8366
Shop_submenu_tiles_buffer    = $FFFF83FE
Magic_list_tiles_buffer      = $FFFF85D0
Left_menu_tiles_buffer     = $FFFF862E
Item_list_right_tiles_buffer = $FFFF88C4
Rings_list_tiles_buffer      = $FFFF8C8A
Map_sector_top_left          = $FFFF9000
Map_sector_top_center        = $FFFF9010
Map_sector_top_right         = $FFFF9020
Map_sector_middle_left       = $FFFF9300
Map_sector_center            = $FFFF9310
Map_sector_middle_right      = $FFFF9320
Map_sector_bottom_left       = $FFFF9600
Map_sector_bottom_center     = $FFFF9610
Map_sector_bottom_right      = $FFFF9620
Window_tilemap_draw_pending = $FFFF9900   ; .b
Window_tilemap_x           = $FFFF9902   ; .w
Window_width               = $FFFF9904   ; .w
Window_text_x              = $FFFF9906   ; .w
Window_tilemap_y           = $FFFF9908   ; .w
Window_height              = $FFFF990A   ; .w
Window_text_y              = $FFFF990C   ; .w
Window_tile_attrs          = $FFFF990E   ; .w
Window_tilemap_draw_active  = $FFFF9910   ; .b
Window_tilemap_row_draw_pending = $FFFF9911   ; .b
Window_draw_type           = $FFFF9912   ; .w
Window_draw_row            = $FFFF9914   ; .w
Window_text_row            = $FFFF9916   ; .w
Shop_item_index            = $FFFF991A   ; .w
Window_tilemap_buffer      = $FFFF9920
Window_text_scratch        = $FFFF9D80

; ------------------------------------------------------------
; Graphics Buffers
; ------------------------------------------------------------
Tile_gfx_buffer              = $FFFFA000
Enemy_gfx_buffer             = $FFFFA200

; ------------------------------------------------------------
; Palette & Fade Control
; ------------------------------------------------------------
Palette_line_0_buffer   = $FFFFC000
Palette_line_1_buffer   = $FFFFC020
Palette_line_2_buffer   = $FFFFC040
Palette_line_3_buffer   = $FFFFC060
Palette_line_0_index    = $FFFFC080   ; .w
Palette_line_1_index    = $FFFFC082   ; .w
Palette_line_2_index    = $FFFFC084   ; .w
Palette_line_3_index    = $FFFFC086   ; .w
Frame_delay_counter     = $FFFFC08A   ; .w
Palette_fade_step_counter = $FFFFC08C   ; .w
Fade_out_lines_mask     = $FFFFC08E   ; .b
Palette_line_1_index_saved = $FFFFC096   ; .w
Palette_line_2_cycle_base = $FFFFC098   ; .w
Palette_line_2_cycle_index_1 = $FFFFC09A   ; .w
Palette_line_2_cycle_index_2 = $FFFFC09C   ; .w
Palette_cycle_frame_counter = $FFFFC09E   ; .b
Palette_line_2_cycle_step = $FFFFC09F   ; .b
Rng_state               = $FFFFC0A0   ; .l
Palette_fade_tick_counter = $FFFFC0A4   ; .w
Palette_fade_in_step    = $FFFFC0A8   ; .w
Fade_in_lines_mask      = $FFFFC0AA   ; .b
Palette_fade_in_mask    = $FFFFC0AB   ; .b
Palette_line_0_fade_target = $FFFFC0AC   ; .w
Palette_line_1_fade_target = $FFFFC0AE   ; .w
Palette_line_2_fade_target = $FFFFC0B0   ; .w
Palette_line_3_fade_target = $FFFFC0B2   ; .w
Palette_fade_in_step_counter = $FFFFC0B4   ; .w
Palette_line_0_fade_in_target = $FFFFC0B6   ; .w
Palette_line_1_fade_in_target = $FFFFC0B8   ; .w
Palette_line_2_fade_in_target = $FFFFC0BA   ; .w
Palette_line_3_fade_in_target = $FFFFC0BC   ; .w
Palette_buffer_dirty    = $FFFFC0BD   ; .b
Npc_count               = $FFFFC0FC   ; .w
Vblank_flag             = $FFFFC0FF

; ------------------------------------------------------------
; Town Tilemap & Camera
; ------------------------------------------------------------
Town_camera_move_state       = $FFFFC100   ; .w
Town_camera_move_counter     = $FFFFC102   ; .w
HScroll_base                 = $FFFFC104   ; .w
VScroll_base                 = $FFFFC106   ; .w
HScroll_min_limit            = $FFFFC108   ; .w
VScroll_max_limit            = $FFFFC10A   ; .w
Camera_scrolling_active = $FFFFC10C   ; .b
Tilemap_row_overflow_flag = $FFFFC10D   ; .b
Town_tilemap_width      = $FFFFC110   ; .w
Town_tilemap_height     = $FFFFC112   ; .w
Town_camera_tile_y           = $FFFFC114   ; .w
Town_camera_tile_x           = $FFFFC116   ; .w
Tilemap_total_tiles     = $FFFFC118   ; .w
Town_tilemap_update_row = $FFFFC120   ; .w
Town_tilemap_update_column = $FFFFC122   ; .w
Town_tilemap_row_update_pending = $FFFFC124   ; .b
Town_tilemap_column_update_pending = $FFFFC125   ; .b
Current_town_room = $FFFFC126   ; .w
Town_tileset_index      = $FFFFC128   ; .w
Town_vram_tile_base     = $FFFFC12A   ; .w
Town_spawn_x            = $FFFFC12C   ; .w
Player_spawn_tile_y_buffer = $FFFFC12E   ; .w
Saved_player_x_in_town  = $FFFFC130   ; .w
Town_player_spawn_y     = $FFFFC132   ; .w
Saved_player_spawn_x    = $FFFFC134   ; .w
Saved_player_y_room1    = $FFFFC136   ; .w
Town_camera_initial_x   = $FFFFC138   ; .w
Town_default_camera_y   = $FFFFC13A   ; .w
Town_saved_camera_x     = $FFFFC13C   ; .w
Saved_camera_tile_y_room1 = $FFFFC13E   ; .w
Saved_camera_tile_x_unused = $FFFFC140   ; .w
Saved_camera_tile_y_unused = $FFFFC142   ; .w
Town_camera_spawn_x     = $FFFFC144   ; .w
Town_camera_target_tile_y = $FFFFC146   ; .w
Player_spawn_position_x = $FFFFC148   ; .w
Player_spawn_tile_y     = $FFFFC14A   ; .w
Saved_town_tileset_index = $FFFFC14E   ; .w
Saved_town_room_1       = $FFFFC152   ; .w
Saved_town_room_2       = $FFFFC154   ; .w
Saved_town_room_3       = $FFFFC156   ; .w
Town_tilemap_vram_base  = $FFFFC158   ; .w
Saved_player_spawn_x_room2 = $FFFFC15A   ; .w
Saved_player_spawn_y_room2 = $FFFFC15C   ; .w
Town_npc_data_ptr       = $FFFFC15E   ; .l
Saved_town_npc_data_ptr = $FFFFC162   ; .l
Saved_npc_data_ptr      = $FFFFC166   ; .l
Saved_npc_data_ptr_room3 = $FFFFC16A   ; .l
Npc_init_routine_ptr    = $FFFFC170   ; .l
Tilemap_plane_select    = $FFFFC174   ; .w
Town_tilemap_plane_a_ptr = $FFFFC176   ; .l
Town_tilemap_plane_b_ptr = $FFFFC17A   ; .l
Tilemap_width           = $FFFFC17E   ; .b
Tilemap_height          = $FFFFC17F   ; .b
Tilemap_buffer_size     = $FFFFC180   ; .w
Tilemap_data_ptr_plane_a     = $FFFFC182   ; .l
Tilemap_data_ptr_plane_b     = $FFFFC186   ; .l
Ending_hscroll_offset   = $FFFFC18A   ; .w
Vdp_dma_cmd                  = $FFFFC18C   ; .l
Vdp_dma_cmd_hi               = $FFFFC18E   ; .w
Vdp_dma_ram_routine          = $FFFFC190

; Town tilemap scroll guard: if the map dimension (width or height in tiles)
; is <= this value, the camera scroll routine skips tile-row/column updates.
TOWN_MAP_MIN_SCROLL_TILES = $0010   ; 16 tiles — minimum map size for scrolling

; VRAM base addresses for the town sprite/tile banks.
; Town_vram_tile_base holds the sprite tile bank ($0300 = tile 768).
; Town_tilemap_vram_base selects which VRAM plane table receives tilemap data.
TOWN_SPRITE_TILE_BASE       = $0300  ; Sprite tile bank base for all town scenes (tiles 768+)
TOWN_TILEMAP_VRAM_BASE_TOWN = $4000  ; Tilemap VRAM base used during normal town entry
TOWN_TILEMAP_VRAM_BASE_ALT  = $2000  ; Tilemap VRAM base used during InitTownDisplay (battle re-entry)

; Number of tiles written per map sector by the RLE decompressor.
; DecompressMapTile_Next counts writes and exits after this many tiles.
MAP_RLE_TILE_COUNT      = $0100   ; 256 tiles per decompressed sector

; Town map tile type IDs — upper nibble of tile word (after ANDI.w #$F000).
; Used by DialogState_Init to dispatch to the correct service handler,
; and by walkability checks (passable types) and chest/item detection.
; Passable tile groups: $0000 (ground), $2000, $3000, $E000, $F000
TOWN_TILE_PASSABLE_2    = $2000   ; Passable tile group 2
TOWN_TILE_PASSABLE_3    = $3000   ; Passable tile group 3
TOWN_TILE_SHOP          = $4000   ; Weapon/armor shop entrance tile
TOWN_TILE_CHURCH        = $5000   ; Church entrance tile
TOWN_TILE_INN           = $6000   ; Inn entrance tile
TOWN_TILE_FORTUNE_TELLER = $7000  ; Fortune teller (town-specific greeting)
TOWN_TILE_FORTUNE_TELLER_2 = $8000 ; Fortune teller (alternate variant)
TOWN_TILE_CHEST         = $9000   ; Chest tile
TOWN_TILE_PASSABLE_E    = $E000   ; Passable tile group E (empty/open)
TOWN_TILE_PASSABLE_F    = $F000   ; Passable tile group F

; Overworld map tile type thresholds (raw byte values in the overworld tile array).
; Values $00-$0F are passable ground tiles (no transition).
; Values $10-$7F are cave/dungeon entrance tiles; the room index = tile - $10.
; Values $80-$8F ($80 | town_id) are town entrance tiles.
; Values $90-$FE map to cave entrances after BCLR #7 (clears the high bit).
; Value $FF is the cave/dungeon exit.
OVERWORLD_TILE_CAVE_MIN       = $10  ; byte: cave entrance tile lower bound
OVERWORLD_TILE_UPPER_CAVE_MIN = $90  ; byte (signed): upper-range cave/town boundary
OVERWORLD_TILE_EXIT           = $FF  ; byte: cave/dungeon exit tile

; First-person dungeon rendering type indices.
; MapTileToTypeIndex / ValidateDungeonTileType map raw tile bytes to these indices,
; which are used to look up wall/object graphics in FpObjectTileTable_Near/Mid/Far.
FP_RENDER_OPEN          = 0  ; open/passable (no wall)
FP_RENDER_DOOR          = 3  ; cave entrance visible on overworld (not inside cave)
FP_RENDER_WALL          = 4  ; impassable wall (town-range tile $80-$8F)
FP_RENDER_MAX_TERRAIN   = 6  ; highest basic terrain index (0-6 used as-is)
FP_RENDER_DOOR_UPPER    = 7  ; upper-range entrance (tile >= $90, signed negative)
FP_RENDER_CAVE_WALL     = 8  ; cave interior wall (tile >= $10 while inside cave)

; ------------------------------------------------------------
; Script & Dialogue Engine
; ------------------------------------------------------------
Cursor_blink_timer      = $FFFFC200   ; .w
Script_source_offset    = $FFFFC202   ; .w
Script_source_base      = $FFFFC204   ; .l
Script_tile_attrs       = $FFFFC208   ; .w
Script_render_tick      = $FFFFC20C   ; .w
Script_text_complete    = $FFFFC20F   ; .b
Message_speed           = $FFFFC210   ; .b
Script_has_continuation = $FFFFC211   ; .b
Script_has_yes_no_question = $FFFFC212   ; .b
Script_reading_player_name = $FFFFC213   ; .b
Player_name_index       = $FFFFC214   ; .w
Window_tilemap_draw_x       = $FFFFC220   ; .w
Window_tilemap_draw_y       = $FFFFC222   ; .w
Window_tile_x              = $FFFFC224   ; .w
Window_tile_y              = $FFFFC226   ; .w
Window_tilemap_draw_width   = $FFFFC228   ; .w
Window_tilemap_draw_height  = $FFFFC22A   ; .w
Window_tile_width          = $FFFFC22C   ; .w
Window_tile_height         = $FFFFC22E   ; .w
Script_output_base_x    = $FFFFC230   ; .w
Script_output_y         = $FFFFC232   ; .w
Script_output_x         = $FFFFC234   ; .w
Menu_cursor_base_x          = $FFFFC236   ; .w
Menu_cursor_base_y          = $FFFFC238   ; .w
Menu_cursor_column_break    = $FFFFC23A   ; .w
Menu_cursor_last_index      = $FFFFC23C   ; .w
Menu_cursor_index           = $FFFFC23E   ; .w
Dialog_response_index       = $FFFFC240   ; .b
Window_number_cursor_x      = $FFFFC242   ; .w
Window_number_cursor_y      = $FFFFC244   ; .w
Menu_cursor_second_column_x = $FFFFC246   ; .w
Script_talk_source      = $FFFFC250   ; .l
Script_continuation_ptr = $FFFFC254   ; .l
Text_build_buffer       = $FFFFC260

; ------------------------------------------------------------
; DMA, Sound Queue & VDP State
; ------------------------------------------------------------
Sprite_dma_update_pending = $FFFFC302   ; .b
Npc_load_done_flag          = $FFFFC303   ; .b
Vdp_dma_slot_index          = $FFFFC304   ; .w
Sound_queue_count           = $FFFFC320   ; .w
Sound_queue_buffer          = $FFFFC322
Current_area_music          = $FFFFC32A   ; .w
Vblank_frame_counter        = $FFFFC32C   ; .w
Skip_tilemap_updates        = $FFFFC340   ; .b
; $FFFFC341-$FFFFC359: debug/test menu temporaries (DebugTestMenu only)
DebugMenu_in_submenu        = $FFFFC341   ; .b  non-zero while inside a sound-test sub-menu
DebugMenu_scroll_pos        = $FFFFC342   ; .w  current horizontal scroll counter (−8..+8)
DebugMenu_selected_item     = $FFFFC344   ; .w  currently highlighted main-menu item (0-based)
DebugMenu_vdp_cursor        = $FFFFC346   ; .l  cached VDP write-address register value
DebugMenu_sound_item        = $FFFFC34A   ; .w  currently highlighted sound-test entry (0-based)
DebugMenu_sound_category    = $FFFFC358   ; .w  selected sound category (0=BGM, 1=Effect, 2=BGM2, 3=D/A)
Savegame_name_buffer        = $FFFFC35A   ; .l
Savegame_name_overflow      = $FFFFC35E   ; .w
Name_entry_cursor_x         = $FFFFC380   ; .w
Name_entry_cursor_row       = $FFFFC382   ; .w
Name_entry_key_repeat_counter = $FFFFC384   ; .b
Name_entry_complete         = $FFFFC385   ; .b
Name_input_cursor_pos       = $FFFFC386   ; .w
Name_entry_cursor_column    = $FFFFC388   ; .w
Ending_sequence_step         = $FFFFC390   ; .w
Ending_timer                 = $FFFFC392   ; .w
Ending_vscroll_accumulator  = $FFFFC396   ; .l(3)/w(2)
HScroll_full_update_flag     = $FFFFC39A   ; .b
Prologue_state              = $FFFFC3A0   ; .w
Prologue_scroll_offset      = $FFFFC3A4   ; .w
Prologue_complete_flag      = $FFFFC3A5   ; .b
Intro_animation_done        = $FFFFC3B0   ; .b
Title_intro_complete        = $FFFFC3B1   ; .b
Intro_scroll_accumulator    = $FFFFC3B2   ; .w
HScroll_update_busy          = $FFFFC3B4   ; .b
Intro_text_pending           = $FFFFC3B5   ; .b
Scene_update_flag            = $FFFFC3B6   ; .b
HScroll_run_table            = $FFFFC3B8
VDP_regs_cache              = $FFFFC3F0
VDP_Reg1_cache               = $FFFFC3F2   ; .w
VDP_Reg11_cache             = $FFFFC3F6   ; .w

; Town_camera_move_state values: 0 = no scroll, 1-4 = direction
CAMERA_MOVE_UP    = 1  ; Scroll camera upward
CAMERA_MOVE_DOWN  = 2  ; Scroll camera downward
CAMERA_MOVE_LEFT  = 3  ; Scroll camera left
CAMERA_MOVE_RIGHT = 4  ; Scroll camera right

; Map sector buffers

; Battle/Tilemap buffers

; Menu tile buffers

; Object/entity system




; Controller Button Bit Numbers (for use with CheckButtonPress)
; Genesis controller button bits:
BUTTON_BIT_UP       = 0
BUTTON_BIT_DOWN     = 1
BUTTON_BIT_LEFT     = 2
BUTTON_BIT_RIGHT    = 3
BUTTON_BIT_B        = 4
BUTTON_BIT_C        = 5
BUTTON_BIT_A        = 6
BUTTON_BIT_START    = 7


; Prologue_state (longword, upper word used as tile counter) reaches this value
; when the full intro scroll is complete. Compared in TitleScreen_ScrollAndWait
; and UpdatePrologueScrollVRAM to know when to switch to idle mode.
PROLOGUE_SCROLL_END         = $03FF   ; 1023 — scroll counter at which intro is done

; ------------------------------------------------------------
; Core Game State
; ------------------------------------------------------------
Program_state = $FFFFC400   ; .w
Timer_seconds_bcd = $FFFFC403   ; .b
Timer_frame_counter = $FFFFC404   ; .w
Timer_frames_per_second = $FFFFC406   ; .w
Controller_current_state    = $FFFFC408   ; .b
Controller_previous_state   = $FFFFC409   ; .b
Controller_2_current_state  = $FFFFC40A   ; .b
Current_town = $FFFFC40C   ; .w
Camera_scroll_x               = $FFFFC40E   ; .w
Camera_scroll_y               = $FFFFC410   ; .w
Gameplay_state = $FFFFC412   ; .w
Saved_game_state            = $FFFFC414   ; .w
Overworld_menu_state        = $FFFFC416   ; .w
Main_menu_selection         = $FFFFC418   ; .w
Player_input_blocked        = $FFFFC41C   ; .b
Dialogue_state              = $FFFFC41E   ; .w
Item_menu_state             = $FFFFC420   ; .w
Equip_list_menu_state       = $FFFFC422   ; .w
Spellbook_menu_state        = $FFFFC424   ; .w
Ready_equipment_state       = $FFFFC426   ; .w
Dialog_selection = $FFFFC428   ; .w
Open_menu_state             = $FFFFC42A   ; .w
Take_item_state             = $FFFFC42C   ; .w
Sleep_delay_timer           = $FFFFC434   ; .w
Pending_hint_text           = $FFFFC438   ; .l
Map_trigger_index           = $FFFFC43C   ; .w

; Map_trigger_index values used by map-giver NPCs
MAP_TRIGGER_MAP_GIVER_WYCLIF    = $0011  ; Map giver NPC in Wyclif
MAP_TRIGGER_MAP_GIVER_DEEPDALE  = $0013  ; Map giver NPC in Deepdale
MAP_TRIGGER_MAP_GIVER_STOW      = $0028  ; Map giver NPC in Stow

; ------------------------------------------------------------
; Inventory & Equipment
; ------------------------------------------------------------
Selected_item_index         = $FFFFC440   ; .w
Possessed_items_length      = $FFFFC442   ; .w
Possessed_items_list        = $FFFFC444
Item_menu_action_mode       = $FFFFC458   ; .w
Banshee_powder_active       = $FFFFC45C   ; .b
Magic_list_cursor_index     = $FFFFC460   ; .w
Possessed_magics_length     = $FFFFC462   ; .w
Possessed_magics_list       = $FFFFC464
Possessed_equipment_length  = $FFFFC482   ; .w
Possessed_equipment_list    = $FFFFC484
Intro_timer                 = $FFFFC498   ; .w
Intro_animation_frame       = $FFFFC49A   ; .w
Shop_selected_index          = $FFFFC4A0   ; .w
Shop_item_count              = $FFFFC4A2   ; .w
Shop_action_selection        = $FFFFC4A4   ; .w
Current_shop_type = $FFFFC4A6   ; .w
Active_inventory_list_ptr   = $FFFFC4A8   ; .l
Shop_sell_price              = $FFFFC4AC   ; .l
Shop_selected_price          = $FFFFC4B0   ; .l
Shop_item_list               = $FFFFC4B4
Shop_purchase_made           = $FFFFC4C4   ; .b
Equipped_items  = $FFFFC4D0
Equipped_sword  = $FFFFC4D0   ; .w
Equipped_shield = $FFFFC4D2   ; .w
Equipped_armor  = $FFFFC4D4   ; .w
Readied_magic   = $FFFFC4D6   ; .w
Equipped_unused = $FFFFC4D8 ; .w — Probably unused, at least
Ready_equipment_list_length = $FFFFC4E0   ; .w
Ready_equipment_selection   = $FFFFC4E2   ; .w
Ready_equipment_category    = $FFFFC4E4   ; .w
Ready_equipment_cursor_index = $FFFFC4E6   ; .w
Ready_equipment_list        = $FFFFC4E8

SHOP_TYPE_ITEM      = $00
SHOP_TYPE_EQUIPMENT = $01
SHOP_TYPE_MAGIC     = $02

PRICE_PASS_TO_CARTHAHENA = $50000
PRICE_SANGUIOS = $1000

; ------------------------------------------------------------
; Church, Rings & Towns Visited
; ------------------------------------------------------------
Church_service_selection    = $FFFFC500   ; .w
Possessed_rings_count       = $FFFFC502   ; .w
Aries_selected_town          = $FFFFC506   ; .w
Towns_visited                                   = $FFFFC508

; ------------------------------------------------------------
; Battle & First-Person State
; ------------------------------------------------------------
Is_in_battle                 = $FFFFC530   ; .b
Is_boss_battle               = $FFFFC531   ; .b
Terrain_tileset_index        = $FFFFC532   ; .w
Battle_type                  = $FFFFC534   ; .w
Boss_ai_state                = $FFFFC536   ; .w(25)/b(9)
Boss_part_count              = $FFFFC537   ; .b
Boss_defeated_flag           = $FFFFC538   ; .b
Boss_battle_exit_flag        = $FFFFC539   ; .b
Boss_death_anim_done         = $FFFFC53A   ; .b
Boss_active_parts            = $FFFFC53C   ; .w
Boss_max_hp                  = $FFFFC53E   ; .b(6)/w(3)
Boss_attack_direction        = $FFFFC53F   ; .b
Player_in_first_person_mode                     = $FFFFC540   ; .b
Player_move_forward_in_overworld                = $FFFFC541   ; .b
Player_rotate_counter_clockwise_in_overworld    = $FFFFC542   ; .b
Player_rotate_clockwise_in_overworld            = $FFFFC543   ; .b
Player_move_backward_in_overworld               = $FFFFC544   ; .b
First_person_wall_right      = $FFFFC545   ; .b
First_person_center_wall     = $FFFFC546   ; .b
Fp_wall_right_2              = $FFFFC547   ; .b
Overworld_movement_frame     = $FFFFC54A   ; .w
First_person_wall_frame      = $FFFFC54C   ; .w
Wall_render_y_offset         = $FFFFC54E   ; .w
Encounter_triggered          = $FFFFC550   ; .b
Is_in_cave = $FFFFC551   ; .b
Dialog_phase                = $FFFFC552   ; .w
Dialog_timer                = $FFFFC554   ; .w
Current_cave_room = $FFFFC556   ; .w
Map_tile_base_index          = $FFFFC558   ; .w
Level_up_timer               = $FFFFC55C   ; .w
Area_map_revealed             = $FFFFC55F   ; .b
Cave_light_active             = $FFFFC560   ; .b
Dialog_active_flag          = $FFFFC561   ; .b
Cave_light_timer              = $FFFFC562   ; .w
Player_compass_frame         = $FFFFC564   ; .w
Talker_gfx_descriptor_ptr   = $FFFFC566   ; .l
Dialog_state_flag           = $FFFFC56A   ; .b
Chest_opened_flag           = $FFFFC56B   ; .b
Reward_script_active        = $FFFFC56C   ; .b
Herbs_available             = $FFFFC56D   ; .b
Truffles_available          = $FFFFC56E   ; .b
Reward_script_available     = $FFFFC56F   ; .b
Reward_script_type          = $FFFFC570   ; .w
Reward_script_value         = $FFFFC572   ; .w
Reward_script_flag          = $FFFFC574   ; .l
Talker_present_flag         = $FFFFC578   ; .b
Found_something_nearby      = $FFFFC579   ; .b
Enemy_reward_type           = $FFFFC57A   ; .w
Enemy_reward_value          = $FFFFC57C   ; .w
Chest_animation_frame        = $FFFFC580   ; .w
Chest_animation_timer        = $FFFFC582   ; .w
Chest_already_opened         = $FFFFC584   ; .b
Open_chest_delay_timer       = $FFFFC585   ; .b
Door_unlocked_flag           = $FFFFC586   ; .b

CHEST_OPEN_DELAY_FRAMES      = $50  ; 80 frames: chest lid animation delay before menu opens

; ------------------------------------------------------------
; Player Town State
; ------------------------------------------------------------
Player_tile_x               = $FFFFC600   ; .w
Player_tile_y               = $FFFFC602   ; .w
Player_tilemap_offset       = $FFFFC604   ; .w
Player_position_x_in_town       = $FFFFC606   ; .w
Player_position_y_in_town       = $FFFFC608   ; .w
Player_direction                = $FFFFC60C   ; .w
Player_direction_flags          = $FFFFC60D   ; .b
Player_is_moving                = $FFFFC60E   ; .b
Player_movement_step_counter    = $FFFFC60F   ; .b
Current_tile_type               = $FFFFC610   ; .w
Town_movement_blocked           = $FFFFC612   ; .b
Player_walk_anim_toggle         = $FFFFC613   ; .b
Player_movement_flags           = $FFFFC614   ; .w
Saved_player_direction      = $FFFFC616   ; .w
Player_kims                     = $FFFFC620   ; .l
Player_experience               = $FFFFC624   ; .l
Player_next_level_experience    = $FFFFC628   ; .l
Player_hp                       = $FFFFC62C   ; .w
Player_mhp                      = $FFFFC62E   ; .w
Player_mmp                      = $FFFFC630   ; .w
Player_mp                       = $FFFFC632   ; .w
Player_str                      = $FFFFC634   ; .w
Player_ac                       = $FFFFC636   ; .w
Player_int                      = $FFFFC638   ; .w
Player_dex                      = $FFFFC63A   ; .w
Player_luk                      = $FFFFC63C   ; .w
Player_level                    = $FFFFC640   ; .w
Player_poisoned                 = $FFFFC642   ; .w
Ending_player_name_buffer       = $FFFFC646
Player_name                     = $FFFFC64C   ; .l
Transaction_amount              = $FFFFC65A   ; .l
Transaction_item_id             = $FFFFC65B   ; .b
Transaction_item_quantity       = $FFFFC65C   ; .b
Transaction_item_flags          = $FFFFC65D   ; .b
Transaction_amount_end          = $FFFFC65E

DIRECTION_UP    = 0
DIRECTION_LEFT  = 2
DIRECTION_DOWN  = 4
DIRECTION_RIGHT = 6
DIRECTION_ANY   = $F

; NPC sprite attribute flags (entity +$07, high byte of VDP tile name word)
; Bits 7=priority, 6-5=palette line, 4=vflip, 3=hflip
NPC_ATTR_PAL0   = $00           ; Palette line 0 (background palette)
NPC_ATTR_PAL1   = $20           ; Palette line 1 (enemy palette)
NPC_ATTR_PAL3   = $60           ; Palette line 3 (character/player palette)

MAX_PLAYER_LEVEL    = 30
MAX_PLAYER_MMP      = 600
MAX_PLAYER_MHP      = 1200
MAX_PLAYER_STR      = 1500
MAX_PLAYER_DEX      = 2000
MAX_PLAYER_INT      = 500
MAX_PLAYER_LUK      = 700
MAX_PLAYER_AC       = 1500
MAX_PLAYER_EXP      = $00999999
MAX_PLAYER_KIMS     = $00999999
SUP_PLAYER_EXP      = $01000000
SUP_PLAYER_KIMS     = $01000000

; ------------------------------------------------------------
; Player Overworld & Cave State
; ------------------------------------------------------------
Player_attacking_flag       = $FFFFC660   ; .b
Player_invulnerable         = $FFFFC661   ; .b
Player_position_x_outside_town  = $FFFFC662   ; .w
Player_position_y_outside_town  = $FFFFC664   ; .w
Player_map_sector_x             = $FFFFC666   ; .w
Player_map_sector_y             = $FFFFC668   ; .w
Player_cave_position_x          = $FFFFC66A   ; .w
Player_cave_position_y          = $FFFFC66C   ; .w
Player_cave_map_sector_x        = $FFFFC66E   ; .w
Player_cave_map_sector_y        = $FFFFC670   ; .w
File_menu_phase             = $FFFFC672   ; .w
Sram_save_slot_ptr              = $FFFFC674   ; .l
Sram_backup_ptr                 = $FFFFC678   ; .l
File_load_complete          = $FFFFC67C   ; .b
Cave_position_saved         = $FFFFC67D   ; .b
Battle_active_flag           = $FFFFC67E   ; .b
Player_awakening_flag       = $FFFFC67F   ; .b
Random_number                   = $FFFFC680   ; .w
Number_Of_Enemies               = $FFFFC682   ; .w
Checked_for_encounter           = $FFFFC683   ; .b
Encounter_group_index           = $FFFFC684   ; .b
Steps_since_last_encounter      = $FFFFC685   ; .b
Current_encounter_gfx_ptr   = $FFFFC686   ; .l
Current_encounter_type          = $FFFFC68A   ; .w
Encounter_behavior_flag      = $FFFFC68C   ; .b
Inaudios_steps_remaining    = $FFFFC68E   ; .w
Enemy_anim_frame_mask        = $FFFFC690   ; .w
Enemy_anim_frame_shift       = $FFFFC692   ; .w
Enemy_anim_table_main        = $FFFFC694   ; .l
Enemy_anim_table_child       = $FFFFC698   ; .l
Encounter_rate                  = $FFFFC69C   ; .w
Enemy_pair_offset_flag       = $FFFFC69E   ; .b
Enemy_direction_flag         = $FFFFC69F   ; .b
Enemy_position_indices          = $FFFFC6A0
Skip_town_intro_after_fight = $FFFFC6A8   ; .b

; NPC collision flags (entity +$2D)
NPC_NONSOLID    = 0             ; NPC does not block movement
NPC_SOLID       = 1             ; NPC blocks movement





; Encounter_rate mask values (AND'd with random number to check for encounter)
ENCOUNTER_RATE_TOWN     = $0F   ; Town overworld: 1-in-16 chance per step
ENCOUNTER_RATE_CAVE     = $1F   ; Cave/dungeon: 1-in-32 chance per step
ENCOUNTER_RATE_BROOCH   = $7F   ; Ruby Brooch active: 1-in-128 chance per step
MAX_STEPS_BETWEEN_ENCOUNTERS    = 20

; ------------------------------------------------------------
; Dialog Choice System
; ------------------------------------------------------------
Dialog_choice_event_trigger     = $FFFFC700   ; .w(2)/b(1)
Dialog_choice_extended_trigger  = $FFFFC701   ; .b
Dialogue_event_trigger_flag     = $FFFFC702   ; .b
Quest_choice_pending            = $FFFFC703   ; .b
Quest_choice_expected_answer    = $FFFFC704   ; .w(1)/b(1)
Quest_choice_map_trigger        = $FFFFC705   ; .b

; ------------------------------------------------------------
; Event Triggers ($FFFFC720-$FFFFC91F)  [RAM-003]
; ------------------------------------------------------------
; A flat 512-byte ($200) array of single-byte flag slots that
; record all story/quest progress.  Cleared to $00 on new game;
; saved/loaded verbatim by sram.asm (512 bytes per save slot).
;
; Layout by offset range:
;   $0000–$00FF : Story/quest progress flags (1 byte each)
;   $0100–$01FF : World-map reveal flags (1 byte per map sector)
;
; Value semantics:
;   $00 = not set (FLAG_FALSE)
;   $FF = set     (FLAG_TRUE)
;   (Any non-zero value is treated as set by TST.b checks.)
;
; HOW FLAGS ARE SET:
;   1. Via script bytecode (townbuild.asm data, evaluated by script VM):
;        SCRIPT_TRIGGERS ($F8) — up to 2 flags (1-byte offsets, low half only)
;          → macro: script_cmd_triggers <TRIGGER_xxx>
;        SCRIPT_ACTIONS  ($F9) — action list with 16-bit offsets:
;          · entry $00 xx : set Event_triggers_start[$00_xx] = FLAG_TRUE
;          · entry $01 xx : set Event_triggers_start[$01_xx] = FLAG_TRUE (map reveal)
;          · entry $02 .. : give kims (not a trigger)
;          → macros: script_set_trigger, script_reveal_map, script_give_kims
;   2. Via ASM code (items.asm):
;        MOVE.b #FLAG_TRUE, <FullRAMAddr>.w   (direct byte write)
;   3. Via quest-choice scripting:
;        SCRIPT_YES_NO ($FB) records an answer;
;        SCRIPT_CHOICE ($FA) conditionally sets Quest_choice_map_trigger.
;
; HOW FLAGS ARE READ:
;   1. NPC dialogue dispatch in npc.asm checks individual flags to decide
;      which script to run (e.g. TST.b Blade_is_dead.w → branch to alt text).
;   2. Items.asm item-use handlers check flags before applying effects
;      (e.g. check Sword_retrieved_from_blacksmith before allowing retrieval).
;   3. gameplay.asm boss-trigger check: compares flag bytes to decide whether
;      to start a boss encounter dialogue sequence.
;
; SAVE/LOAD (sram.asm):
;   LEA Event_triggers_start.w, A1
;   MOVE.w #$01FF, D7   ; 512 bytes = $0200 = $01FF+1 DBF iterations
;   loop: copy byte ↔ SRAM
;
; TRIGGER_ constants (below) are OFFSETS from Event_triggers_start.
; The Blade_is_dead … style labels (further below) are the full RAM addresses.
; Both refer to the same flags; prefer TRIGGER_ in script data.
;
; -----------------------------------------------------------------------
; RAND-007: STORY PROGRESSION GRAPH
; -----------------------------------------------------------------------
; For a randomizer, these are the KEY flags that gate story advancement.
; Format: FLAG_NAME (offset) — SET by: … | GATES: …
;
; === MAIN STORY CRITICAL PATH ===
;
; Fake_king_killed ($0003)
;   SET by: boss.asm — imposter-king boss defeat
;   GATES:  Parma king questline continues; triggers reveal of real king
;
; Talked_to_real_king ($0005)
;   SET by: townbuild.asm script ($F8 trigger) after real-king dialogue
;   GATES:  Treasure of Troy questline starts
;
; Treasure_of_troy_found ($0006)
;   SET by: townbuild.asm script on chest pick-up in Parma dungeon
;   GATES:  Player can give treasure to king for reward
;
; Treasure_of_troy_given_to_king ($0004)
;   SET by: townbuild.asm script ($F9 actions) on dialogue completion
;   GATES:  King gives clue about next destination
;
; Sent_to_malaga ($0013)
;   SET by: townbuild.asm script (Parma king dialogue conclusion)
;   GATES:  Malaga questline becomes active
;
; Malaga_king_crowned ($001B)
;   SET by: townbuild.asm script_set_trigger in Malaga event sequence
;   GATES:  Malaga NPCs give post-coronation dialogue; Stow route opens
;
; Imposter_killed ($001D)
;   SET by: boss.asm — CaveImposterBoss defeat
;   GATES:  Barrow castle interior accessible (npc.asm/towndata.asm gate)
;
; Ring_of_earth_obtained ($0029)
;   SET by: townbuild.asm script_set_trigger in Barrow ring-guardian event
;   GATES:  One of four rings acquired (ending check)
;
; Ring_of_wind_received ($002B)
;   SET by: towndata.asm (Reward_script_flag mechanism after ring-guardian fight)
;   GATES:  Second ring acquired
;
; Player_has_sword_of_vermilion ($0037)
;   SET by: items.asm — using the sword retrieval sequence
;   GATES:  Endgame sword fight with Tsarkon becomes available
;
; Tsarkon_is_dead ($0038)
;   SET by: townbuild.asm script_cmd_triggers in Tsarkon final-battle script
;   GATES:  Ending sequence triggers; all "Tsarkon fled" NPCs switch
;           dialogue (npc.asm widespread TST.b Tsarkon_is_dead checks)
;
; Crown_received ($003B)
;   SET by: towndata.asm Reward_script_flag mechanism (crown chest event)
;   GATES:  Crowning ceremony in final town; game-complete flag
;
; === BOSS FIGHT TRIGGERS (separate from Event_triggers array) ===
; These live above $FFFFC800, outside the save-slot-backed trigger array.
;
; Imposter_boss_trigger    ($FFFFC804)  — set by towndata.asm dungeon event;
;   read by npc.asm to initiate imposter boss fight portrait sequence
; Ring_guardian_1_boss_trigger ($FFFFC805) — set by towndata.asm ($3454)
;   when player enters ring-guardian dungeon room
; Ring_guardian_2_boss_trigger ($FFFFC806) — set by towndata.asm ($3467)
; Ring_guardian_3_boss_trigger ($FFFFC807) — set by towndata.asm ($3480)
; Boss_event_trigger       ($FFFFC817)  — transient flag set by towndata.asm;
;   read by gameplay.asm (GameState_BuildingInterior and GameState_TownExploration)
;   to trigger the boss dialogue/cutscene state ($21 GAMEPLAY_STATE_BOSS_BATTLE_INIT)
; Soldier_fight_event_trigger ($FFFFC816) — set by towndata.asm Carthahena event;
;   read by gameplay.asm to trigger the soldier fight interlude ($2B/$2C states)
;
; === SWORD / KEY ITEM SEQUENCE ===
;
; Sword_stolen_by_blacksmith ($0035)
;   SET by: items.asm when player uses Wrong_item near blacksmith
;   GATES:  Player must retrieve sword (blacksmith NPC changes dialogue)
;
; Sword_retrieved_from_blacksmith ($0036)
;   SET by: townbuild.asm script when sword is taken back
;   GATES:  Player_has_sword_of_vermilion can now be acquired
;
; Pass_to_carthahena_purchased ($0034)
;   SET by: townbuild.asm script (shop dialogue) — buy the pass
;   GATES:  Carthahena town border guards let player through
;           (npc.asm checks Pass_to_carthahena_given for guard NPC)
;
; === SIDE QUEST FLAGS RELEVANT TO RANDOMIZER ===
;
; Truffle_collected ($000B)
;   SET by: townbuild.asm script on truffle chest pick-up
;   GATES:  Deepdale truffle-giver NPC accepts delivery
;
; Bearwulf_met ($0014)
;   SET by: townbuild.asm script on first Bearwulf conversation
;   GATES:  Bearwulf questline begins; npc.asm shows travelling dialogue
;
; Bearwulf_returned_home ($0015)
;   SET by: townbuild.asm SCRIPT_YES_NO callback when Bearwulf quest completes
;   GATES:  Barrow NPCs react to Bearwulf's safe return
;
; Helwig_men_rescued ($0024)
;   SET by: npc.asm — FreePrisoners dialogue completion
;   GATES:  Helwig inn-wakeup event; towndata.asm cave event
;
; Ring_of_earth_obtained / Ring_of_wind_received / White_crystal_received /
; Red_crystal_received / Blue_crystal_received — the four ring/crystal flags
;   are gated by their respective dungeon bosses or NPC quests.
;   A complete randomizer must treat all four as prerequisite for the endgame.
; -----------------------------------------------------------------------
;
Event_triggers_start                        = $FFFFC720   ; .b
Blade_is_dead                               = $FFFFC720   ; .b
Treasure_of_troy_challenge_issued           = $FFFFC722   ; .b
Fake_king_killed                            = $FFFFC723   ; .b
Treasure_of_troy_given_to_king              = $FFFFC724   ; .b
Talked_to_real_king                         = $FFFFC725   ; .b
Treasure_of_troy_found                      = $FFFFC726   ; .b
Talked_to_king_after_given_treasure_of_troy = $FFFFC727   ; .b
Player_chose_to_stay_in_parma               = $FFFFC728   ; .b
Watling_youth_restored                      = $FFFFC729   ; .b
Watling_villagers_asked_about_rings         = $FFFFC72A
Deepdale_truffle_quest_started              = $FFFFC72B   ; .b
Truffle_collected                           = $FFFFC72C   ; .b
Deepdale_king_secret_kept                   = $FFFFC72D   ; .b
Sanguios_book_offered                       = $FFFFC72E   ; .b
Accused_of_theft                            = $FFFFC72F   ; .b
Stow_thief_defeated                         = $FFFFC730   ; .b
Asti_monster_defeated                       = $FFFFC731   ; .b
Stow_innocence_proven                       = $FFFFC732   ; .b
Sent_to_malaga                              = $FFFFC733   ; .b
Bearwulf_met                                = $FFFFC734   ; .b
Bearwulf_returned_home                      = $FFFFC735   ; .b
Helwig_old_woman_quest_started              = $FFFFC736   ; .b
Malaga_king_crowned                         = $FFFFC73B   ; .b
Barrow_map_received                         = $FFFFC73C   ; .b
Imposter_killed                             = $FFFFC73D   ; .b
Watling_monster_encounter_triggered         = $FFFFC73E   ; .b
Tadcaster_treasure_quest_started            = $FFFFC73F   ; .b
Tadcaster_treasure_found                    = $FFFFC740   ; .b
Bully_first_fight_won                       = $FFFFC741   ; .b
Tadcaster_bully_triggered                   = $FFFFC742   ; .b
Helwig_men_rescued                          = $FFFFC744   ; .b
Uncle_tibor_visited                         = $FFFFC745   ; .b
Old_man_waiting_for_letter                  = $FFFFC746   ; .b
Old_man_and_woman_paired                    = $FFFFC747   ; .b
Swaffham_ruined                             = $FFFFC748   ; .b
Ring_of_earth_obtained                      = $FFFFC749   ; .b
White_crystal_quest_started                 = $FFFFC74A   ; .b
Ring_of_wind_received                       = $FFFFC74B   ; .b
Red_crystal_quest_started                   = $FFFFC74C   ; .b
Red_crystal_received                        = $FFFFC74D   ; .b
Blue_crystal_quest_started                  = $FFFFC74E   ; .b
Blue_crystal_received                       = $FFFFC74F   ; .b
Ate_spy_dinner                              = $FFFFC750   ; .b
Swaffham_ate_poisoned_food                  = $FFFFC751   ; .b
Digot_plant_received                        = $FFFFC752   ; .b
Spy_dinner_poisoned_flag                    = $FFFFC753   ; .b
Pass_to_carthahena_purchased                = $FFFFC754   ; .b
Sword_stolen_by_blacksmith                  = $FFFFC755   ; .b
Sword_retrieved_from_blacksmith             = $FFFFC756   ; .b
Player_has_received_sword_of_vermilion      = $FFFFC757   ; .b
Tsarkon_is_dead                             = $FFFFC758   ; .b
Carthahena_boss_met                         = $FFFFC759   ; .b
Alarm_clock_rang                            = $FFFFC75A   ; .b
Crown_received                              = $FFFFC75B   ; .b
Girl_left_for_stow                          = $FFFFC75C   ; .b
Keltwick_girl_sleeping                      = $FFFFC75E   ; .b
Old_man_has_received_sketch                 = $FFFFC75F   ; .b
Old_woman_has_received_sketch               = $FFFFC760   ; .b
Dragon_shield_offered_to_player             = $FFFFC761   ; .b
Old_mans_sketch_given                       = $FFFFC762   ; .b
Player_has_received_old_womans_sketch       = $FFFFC763   ; .b
Dragon_shield_received                      = $FFFFC764   ; .b
Pass_to_carthahena_given                    = $FFFFC765   ; .b
Sanguios_purchased                          = $FFFFC766   ; .b
Sanguios_confiscated                        = $FFFFC767   ; .b
Sanguia_learned_from_book                   = $FFFFC768   ; .b
Bearwulf_weapon_reward_given                = $FFFFC769
Tadcaster_treasure_kims_received            = $FFFFC76A   ; .b
Knute_informed_of_swaffham_ruin             = $FFFFC76B   ; .b
Player_greatly_poisoned                     = $FFFFC76C   ; .b
Excalabria_boss_1_defeated                  = $FFFFC76D   ; .b
Excalabria_boss_2_defeated                  = $FFFFC76E   ; .b
Excalabria_boss_3_defeated                  = $FFFFC76F   ; .b
White_crystal_received                      = $FFFFC770   ; .b
Red_key_received                            = $FFFFC771   ; .b
Blue_key_received                           = $FFFFC772   ; .b
Carthahena_boss_defeated                    = $FFFFC773   ; .b
Swaffham_spy_defeated                       = $FFFFC774   ; .b
Thar_defeated                               = $FFFFC775   ; .b
Luther_defeated                             = $FFFFC776   ; .b
Swaffham_miniboss_defeated                  = $FFFFC777   ; .b
All_rings_collected                         = $FFFFC778   ; .b
Barrow_quest_1_complete                     = $FFFFC779   ; .b
Barrow_quest_2_complete                     = $FFFFC77A   ; .b
Poison_trap_sprung                          = $FFFFC77B   ; .b
Watling_inn_free_stay_used                  = $FFFFC77C   ; .b
Watling_inn_broke_penalty                   = $FFFFC77D   ; .b
Sixteen_rings_used_at_throne                = $FFFFC77E   ; .b
Stow_tavern_free_meal_offered               = $FFFFC77F   ; .b
Thar_bronze_key_collected                   = $FFFFC780
Thar_silver_key_collected                   = $FFFFC781
Luther_gold_key_collected                   = $FFFFC782
Knute_thule_key_dialog_shown                = $FFFFC783   ; .b
Thule_key_received                          = $FFFFC784   ; .b
Cave_key_dialog_shown                       = $FFFFC785   ; .b
Secret_key_received                         = $FFFFC786   ; .b
Royal_shield_chest_opened                   = $FFFFC787
Money_chest_256_opened                      = $FFFFC788
Herbs_chest_opened                          = $FFFFC789
Herbs_chest_2_opened                        = $FFFFC78A
Crimson_armor_chest_opened                  = $FFFFC78B   ; .b
Candle_chest_opened                         = $FFFFC78C
Herbs_chest_3_opened                        = $FFFFC78D
Money_chest_768_stow_opened                 = $FFFFC78E
Dark_sword_chest_opened                     = $FFFFC78F
Herbs_chest_4_opened                        = $FFFFC790
Scale_armor_chest_opened                    = $FFFFC791
Candle_chest_parma_opened                   = $FFFFC792
Money_chest_768_opened                      = $FFFFC793
Money_chest_1536_opened                     = $FFFFC794
Candle_chest_2_opened                       = $FFFFC796
Herbs_chest_watling_opened                  = $FFFFC797
Wyclif_outskirts_chest_opened               = $FFFFC798
Medicine_chest_opened                       = $FFFFC799
Crimson_armor_reward_enabled                = $FFFFC79A   ; .b
Money_chest_768_b_opened                    = $FFFFC79B
Herbs_chest_5_opened                        = $FFFFC79C
Magic_shield_chest_opened                   = $FFFFC79D
Money_chest_1792_opened                     = $FFFFC79E
Large_shield_chest_opened                   = $FFFFC79F
Metal_armor_chest_opened                    = $FFFFC7A0
Money_chest_2128_opened                     = $FFFFC7A1
Lantern_chest_opened                        = $FFFFC7A2
Skeleton_armor_chest_opened                 = $FFFFC7A3
Money_chest_8192_opened                     = $FFFFC7A4
Money_chest_12288_opened                    = $FFFFC7A5
Money_chest_8192_b_opened                   = $FFFFC7A6
Bearwulf_cave_entered                       = $FFFFC7A7   ; .b
Malaga_dungeon_person_rescued               = $FFFFC7A8   ; .b
Helwig_prison_entered                       = $FFFFC7A9   ; .b
Malaga_key_dialog_shown                     = $FFFFC7AA   ; .b
Dungeon_key_received                        = $FFFFC7AB   ; .b
Replacement_key_enabled                     = $FFFFC7AC   ; .b
Received_replacement_key                    = $FFFFC7AD   ; .b
Candle_chest_3_opened                       = $FFFFC7AE
Lantern_chest_2_opened                      = $FFFFC7AF
Herbs_chest_6_opened                        = $FFFFC7B0
Ruby_brooch_chest_opened                    = $FFFFC7B2
Banshee_powder_chest_opened                 = $FFFFC7B3
Money_chest_512_opened                      = $FFFFC7B4
Money_chest_1280_opened                     = $FFFFC7B5
Money_chest_1792_b_opened                   = $FFFFC7B6
Money_chest_20480_opened                    = $FFFFC7B9
Chest_5888_kims_opened                      = $FFFFC7BA
Money_chest_864_opened                      = $FFFFC7BB
Chest_9999_kims_opened                      = $FFFFC7BC
Chest_sapphire_shield_opened                = $FFFFC7BD
Chest_gnome_stone_opened                    = $FFFFC7BE
Chest_gem_shield_opened                     = $FFFFC7BF
Deepdale_medicine_removed                   = $FFFFC7C0   ; .b
Stepfather_ring_dialog_shown                = $FFFFC7C1   ; .b
Titanias_mirror_quest_prereq                = $FFFFC7C2   ; .b
Titanias_mirror_acquired                    = $FFFFC7C3   ; .b
Mega_blast_acquired                         = $FFFFC7C4   ; .b
Rafaels_stick_acquired                      = $FFFFC7C5   ; .b
Poison_notified                 = $FFFFC7C6   ; .b
Chest_256_kims_opened                       = $FFFFC7E0
Chest_graphite_sword_opened                 = $FFFFC7E1
Chest_grizzly_shield_opened                 = $FFFFC7E2
Chest_critical_sword_opened                 = $FFFFC7E3
Chest_emerald_armor_opened                  = $FFFFC7E4
Chest_secret_armor_opened                   = $FFFFC7E6
Chest_old_nick_armor_opened                 = $FFFFC7E7
Chest_mirage_sword_opened                   = $FFFFC7E8
Chest_phantom_shield_opened                 = $FFFFC7E9
Chest_death_sword_opened                    = $FFFFC7EA
Chest_4096_kims_opened                      = $FFFFC7EC
Malaga_quest_progress                       = $FFFFC7ED   ; .b
Chest_mirror_of_atlas_opened                = $FFFFC7EE
Chest_barbarian_sword_opened                = $FFFFC7EF
Helwig_frypan_hit_count                     = $FFFFC7F0   ; .w
Helwig_inn_wakeup_trigger                   = $FFFFC7F2   ; .b
Frying_pan_knockout_flag                    = $FFFFC7F3   ; .b
Map_triggers_backup                         = $FFFFC7F4   ; .b
Watling_inn_unpaid_nights                   = $FFFFC7F6   ; .w
Boss_battle_flags                           = $FFFFC800
Imposter_boss_trigger                       = $FFFFC804   ; .b
Ring_guardian_1_boss_trigger                = $FFFFC805   ; .b
Ring_guardian_2_boss_trigger                = $FFFFC806   ; .b
Ring_guardian_3_boss_trigger                = $FFFFC807   ; .b
Boss_battle_type_marker                     = $FFFFC80D   ; .b
Soldier_fight_event_trigger                 = $FFFFC816   ; .b
Boss_event_trigger                          = $FFFFC817   ; .b
Rings_collected                             = $FFFFC818   ; .b
Asti_monster_battle_complete                = $FFFFC81B   ; .b
Carthahena_soldier_1_defeated               = $FFFFC81D   ; .b
Carthahena_soldier_2_defeated               = $FFFFC81E
Carthahena_soldier_3_defeated               = $FFFFC81F
Map_trigger_flags           = $FFFFC820

; ------------------------------------------------------------
; Object/Entity System
; ------------------------------------------------------------
VBlank_object_ptr            = $FFFFCC00
HBlank_object_ptr            = $FFFFCC04
Player_entity_ptr           = $FFFFCC08   ; .l
Battle_entity_slot_1_ptr    = $FFFFCC0C   ; .l
Battle_entity_slot_2_ptr    = $FFFFCC10   ; .l
Enemy_list_ptr              = $FFFFCC14   ; .l
Object_slot_01_ptr           = $FFFFCC18   ; .l
Object_slot_02_ptr           = $FFFFCC1C   ; .l
Object_slot_03_ptr           = $FFFFCC20   ; .l
Object_slot_04_ptr           = $FFFFCC24   ; .l
Object_slot_05_ptr           = $FFFFCC28   ; .l
Object_slot_06_ptr           = $FFFFCC2C   ; .l
Object_slot_07_ptr           = $FFFFCC30   ; .l
Object_slot_08_ptr           = $FFFFCC34   ; .l
Object_slot_09_ptr           = $FFFFCC38   ; .l
Object_slot_0A_ptr           = $FFFFCC3C   ; .l
Object_slot_0B_ptr           = $FFFFCC40   ; .l
Object_slot_0C_ptr           = $FFFFCC44   ; .l
Object_slot_0D_ptr           = $FFFFCC48   ; .l
Object_slot_0E_ptr           = $FFFFCC4C   ; .l
Map_indicator_entity_ptr     = $FFFFCC50   ; .l
Current_actor_ptr            = $FFFFCC54   ; .l
Menu_object_ptr              = $FFFFCC74

; ------------------------------------------------------------
; Object RAM & Sprite Tables
; ------------------------------------------------------------
Object_slot_base             = $FFFFD000
Object_table_base            = $FFFFD0E0
Sprite_attr_count            = $FFFFE000   ; .w
Sprite_update_pending        = $FFFFE002   ; .b
Sprite_attr_buffer           = $FFFFE004
Sprite_sort_buffer           = $FFFFE200
Sprite_sort_temp_buffer      = $FFFFE3F0
Sprite_priority_slots        = $FFFFE400

; ------------------------------------------------------------
; Sound Driver
; ------------------------------------------------------------
Sound_driver_play           = $FFFFF404   ; .b
Ram_clear_end                = $FFFFFD00    ; End of general RAM clear region (before stack gap)

; ------------------------------------------------------------
; Stack
; ------------------------------------------------------------
Stack_base                   = $FFFFFE00

; Chest/Treasure Flags ($FFFFC780-$FFFFC7B2)

; Event Flags $FFFFC7B9-$FFFFC7F2

; Towns
TOWN_WYCLIF         = $00
TOWN_PARMA          = $01
TOWN_WATLING        = $02
TOWN_DEEPDALE       = $03
TOWN_STOW1          = $04
TOWN_STOW2          = $05
TOWN_KELTWICK       = $06
TOWN_MALAGA         = $07
TOWN_BARROW         = $08
TOWN_TADCASTER      = $09
TOWN_HELWIG         = $0A
TOWN_SWAFFHAM       = $0B
TOWN_EXCALABRIA     = $0C
TOWN_HASTINGS1      = $0D
TOWN_HASTINGS2      = $0E
TOWN_CARTHAHENA     = $0F

ITEM_TYPE_DISCARDABLE       = $00
ITEM_TYPE_NON_DISCARDABLE   = $01

; Items
ITEM_HERBS              = $00
ITEM_CANDLE             = $01
ITEM_LANTERN            = $02
ITEM_POISON_BALM        = $03
ITEM_ALARM_CLOCK        = $04
ITEM_VASE               = $05
ITEM_JOKE_BOOK          = $06
ITEM_SMALL_BOMB         = $07
ITEM_OLD_WOMANS_SKETCH  = $08
ITEM_OLD_MANS_SKETCH    = $09
ITEM_PASS_TO_CARTHAHENA = $0A
ITEM_TRUFFLE            = $0B
ITEM_DIGOT_PLANT        = $0C
ITEM_TREASURE_OF_TROY   = $0D
ITEM_WHITE_CRYSTAL      = $0E 
ITEM_RED_CRYSTAL        = $0F 
ITEM_BLUE_CRYSTAL       = $10
ITEM_WHITE_KEY          = $11
ITEM_RED_KEY            = $12
ITEM_BLUE_KEY           = $13
ITEM_CROWN              = $14
ITEM_SIXTEEN_RINGS      = $15
ITEM_BRONZE_KEY         = $16
ITEM_SILVER_KEY         = $17
ITEM_GOLD_KEY           = $18 
ITEM_THULE_KEY          = $19 
ITEM_SECRET_KEY         = $1A 
ITEM_MEDICINE           = $1B
ITEM_AGATE_JEWEL        = $1C
ITEM_GRIFFIN_WING       = $1D 
ITEM_TITANIAS_MIRROR    = $1E 
ITEM_GNOME_STONE        = $1F 
ITEM_TOPAZ_JEWEL        = $20 
ITEM_BANSHEE_POWDER     = $21 
ITEM_RAFAELS_STICK      = $22 
ITEM_MIRROR_OF_ATLAS    = $23 
ITEM_RUBY_BROOCH        = $24
ITEM_DUNGEON_KEY        = $25
ITEM_KULMS_VASE         = $26
ITEM_KASANS_CHISEL      = $27
ITEM_BOOK_OF_KIEL       = $28 
ITEM_DANEGELD_WATER     = $29 
ITEM_MINERAL_BAR        = $2A
ITEM_MEGA_BLAST         = $2B

FLAG_MAGIC_READIED  = $80
MAGIC_TYPE_FIELD    = $00
MAGIC_TYPE_BATTLE   = $02

; Magic
MAGIC_AERO          = $00
MAGIC_AERIOS        = $01
MAGIC_VOLTI         = $02
MAGIC_VOLTIO        = $03
MAGIC_VOLTIOS       = $04
MAGIC_FERROS        = $05
MAGIC_COPPEROS      = $06
MAGIC_MERCURIOS     = $07
MAGIC_ARGENTOS      = $08
MAGIC_HYDRO         = $09
MAGIC_HYDRIOS       = $0A
MAGIC_CHRONO        = $0B
MAGIC_CHRONIOS      = $0C
MAGIC_TERRAFISSI    = $0D
MAGIC_ARIES         = $0E
MAGIC_EXTRIOS       = $0F
MAGIC_INAUDIOS      = $10
MAGIC_LUMINOS       = $11
MAGIC_SANGUA        = $12
MAGIC_SANGUIA       = $13
MAGIC_SANGUIO       = $14
MAGIC_TOXIOS        = $15
MAGIC_SANGUIOS      = $16

EQUIPMENT_TYPE_SWORD    = $04
EQUIPMENT_TYPE_SHIELD   = $08
EQUIPMENT_TYPE_ARMOR    = $10
EQUIPMENT_FLAG_CURSED   = $02
FLAG_IS_EQUIPPED        = $80

; Swords 
EQUIPMENT_SWORD_BRONZE          = $00
EQUIPMENT_SWORD_IRON            = $01
EQUIPMENT_SWORD_SHARP           = $02
EQUIPMENT_SWORD_LONG            = $03
EQUIPMENT_SWORD_SILVER          = $04
EQUIPMENT_SWORD_PRIME           = $05
EQUIPMENT_SWORD_GOLDEN          = $06
EQUIPMENT_SWORD_MIRAGE          = $07
EQUIPMENT_SWORD_PLATINUM        = $08
EQUIPMENT_SWORD_DIAMOND         = $09
EQUIPMENT_SWORD_GRAPHITE        = $0A
EQUIPMENT_SWORD_ROYAL           = $0B
EQUIPMENT_SWORD_ULTIMATE        = $0C
EQUIPMENT_SWORD_OF_VERMILION    = $0D
EQUIPMENT_SWORD_DARK1           = $0E
EQUIPMENT_SWORD_DEATH           = $0F
EQUIPMENT_SWORD_BARBARIAN       = $10
EQUIPMENT_SWORD_CRITICAL        = $11
EQUIPMENT_SWORD_DARK2           = $12
EQUIPMENT_SWORD_DARK3           = $13

; Shields
EQUIPMENT_SHIELD_LEATHER        = $14
EQUIPMENT_SHIELD_SMALL          = $15
EQUIPMENT_SHIELD_LARGE          = $16
EQUIPMENT_SHIELD_SILVER         = $17
EQUIPMENT_SHIELD_GOLD           = $18
EQUIPMENT_SHIELD_PLATINUM       = $19
EQUIPMENT_SHIELD_GEM            = $1A
EQUIPMENT_SHIELD_SAPPHIRE       = $1B
EQUIPMENT_SHIELD_DIAMOND        = $1C
EQUIPMENT_SHIELD_DRAGON         = $1D
EQUIPMENT_SHIELD_MAGIC          = $1E
EQUIPMENT_SHIELD_PHANTOM        = $1F
EQUIPMENT_SHIELD_GRIZZLY        = $20
EQUIPMENT_SHIELD_CARMINE1       = $21
EQUIPMENT_SHIELD_ROYAL          = $22
EQUIPMENT_SHIELD_POISON         = $23
EQUIPMENT_SHIELD_KNIGHT         = $24
EQUIPMENT_SHIELD_CARMINE2       = $25
EQUIPMENT_SHIELD_CARMINE3       = $26
EQUIPMENT_SHIELD_CARMINE4       = $27

; Armors
EQUIPMENT_ARMOR_LEATHER         = $28
EQUIPMENT_ARMOR_BRONZE          = $29
EQUIPMENT_ARMOR_METAL           = $2A
EQUIPMENT_ARMOR_SCALE           = $2B
EQUIPMENT_ARMOR_PLATE           = $2C
EQUIPMENT_ARMOR_SILVER          = $2D
EQUIPMENT_ARMOR_GOLD            = $2E
EQUIPMENT_ARMOR_CRYSTAL         = $2F
EQUIPMENT_ARMOR_EMERALD         = $30
EQUIPMENT_ARMOR_DIAMOND         = $31
EQUIPMENT_ARMOR_KNIGHT          = $32
EQUIPMENT_ARMOR_ULTIMATE        = $33
EQUIPMENT_ARMOR_ODIN            = $34
EQUIPMENT_ARMOR_SECRET          = $35
EQUIPMENT_ARMOR_SKELETON        = $36
EQUIPMENT_ARMOR_CRIMSON         = $37
EQUIPMENT_ARMOR_OLD_NICK        = $38

OLD_MAN_POSITION_X = $0019
OLD_MAN_POSITION_Y = $000D

OLD_WOMAN_POSITION_X = $0027
OLD_WOMAN_POSITION_Y = $0003

; ============================================================
; Palette Data Table Indices
; ============================================================
; These are indices into PaletteDataTable, used with Palette_line_X_index
; and related RAM fields. Each entry is 32 bytes (16 Genesis colors).
;
; Town / Overworld
PALETTE_IDX_TOWN_TILES      = $0012   ; Town tile palette (line 0): torches, walls, floor
PALETTE_IDX_TOWN_HUD        = $0011   ; Town HUD palette (line 3): player sprite, status bar
PALETTE_IDX_TOWN_DARK       = $0083   ; Carthahena dark palette (line 0): under Tsarkon rule
PALETTE_IDX_BATTLE_OUTDOOR  = $0013   ; Outdoor battle terrain (line 0): grass/field ground

; Overworld Map
PALETTE_IDX_OVERWORLD_LINE1 = $0037   ; Overworld map palette (line 1)
PALETTE_IDX_OVERWORLD_LINE2 = $0038   ; Overworld map palette (line 2): fire animation base

; Cave / Dungeon (first-person view)
PALETTE_IDX_CAVE_WALLS      = $0036   ; Cave wall tile palette (line 0)
PALETTE_IDX_CAVE_FLOOR      = $0038   ; Cave floor palette (line 2) / overworld map line 2 base
PALETTE_IDX_CAVE_FLOOR_LIT  = $0048   ; Cave floor with light spell active (line 1)
PALETTE_IDX_CAVE_ANIM_BASE  = $0040   ; Cave torch/fire animation start (line 2 cycle)
PALETTE_IDX_CAVE_ANIM_END   = $0047   ; Cave torch/fire animation end (forward loop limit)
PALETTE_IDX_CAVE_ANIM_ALT   = $003F   ; Cave torch/fire animation alt end (reverse loop)
PALETTE_IDX_CAVE_POISON     = $0072   ; Cave poison tint (line 0, when player is poisoned)

; Title Screen
PALETTE_IDX_TITLE_LOGO      = $0029   ; Title screen logo palette (line 1)
PALETTE_IDX_TITLE_TILES     = $0027   ; Title screen tile palette (line 3)
PALETTE_IDX_TITLE_BG        = $0028   ; Title screen background palette (line 2)
PALETTE_IDX_TITLE_LIGHTNING = $0030   ; Title screen lightning flash (line 0)

; Prologue / Name Entry
PALETTE_IDX_PROLOGUE_BG     = $004F   ; Prologue screen background (lines 0, 2)
PALETTE_IDX_PROLOGUE_SCENE  = $0052   ; Prologue scene tile palette (lines 1, 3)
PALETTE_IDX_PROLOGUE_LINE1  = $0050   ; Prologue palette line 1 fade target
PALETTE_IDX_PROLOGUE_LINE2  = $0051   ; Prologue palette line 2 fade target
PALETTE_IDX_NAMEENTRY_BG    = $0032   ; Name entry screen background
PALETTE_IDX_NAMEENTRY_GLOW1 = $0033   ; Name entry glow animation 1
PALETTE_IDX_NAMEENTRY_GLOW2 = $0034   ; Name entry glow animation 2

; Ending / Special
PALETTE_IDX_ALL_WHITE       = $0084   ; All-white flash palette (ending/lightning effect)
PALETTE_IDX_ALL_BLACK       = $0094   ; All-black palette (ending screen blanks)
PALETTE_IDX_ENDING_FIRE     = $0095   ; Ending sequence fire palette
PALETTE_IDX_ENDING_TEXT_BG  = $0085   ; Ending outro text background (fade-in target for text)
PALETTE_IDX_ENDING_CURSOR_MIN = $0096 ; Ending cursor blink palette range start
PALETTE_IDX_ENDING_CURSOR_MAX = $009D ; Ending cursor blink palette range end

; ============================================================
; Window Draw Type IDs (Window_draw_type)
; ============================================================
; WindowDrawTypeJumpTable dispatches on Window_draw_type to choose
; which tile buffer and screen region to flush to the VDP tilemap.
;
WINDOW_DRAW_SCRIPT          = $00   ; Script/dialogue window (Script_window_tiles_buffer)
WINDOW_DRAW_FULL_MENU       = $01   ; Full menu area (Full_menu_tiles_buffer)
WINDOW_DRAW_MSG_SPEED       = $02   ; Message speed menu (Message_speed_menu_tiles_buffer)
WINDOW_DRAW_MSG_SPEED_ALT   = $03   ; Message speed menu alternate position
WINDOW_DRAW_ITEM_LIST_SHORT = $04   ; Item list, 6-row height (Item_list_tiles_buffer)
WINDOW_DRAW_ITEM_LIST_TALL  = $05   ; Item list, 8-row height (Item_list_tiles_buffer)
WINDOW_DRAW_STATUS_MENU     = $06   ; Character status menu (Status_menu_tiles_buffer)
WINDOW_DRAW_SMALL_MENU      = $07   ; Small menu panel (Small_menu_tiles_buffer)
WINDOW_DRAW_RIGHT_MENU      = $08   ; Right-side menu panel (Right_menu_tiles_buffer)
WINDOW_DRAW_EQUIP_LIST      = $09   ; Equipment list (Equipment_list_tiles_buffer)
WINDOW_DRAW_MAGIC_LIST      = $0A   ; Magic/spell list (Magic_list_tiles_buffer)
WINDOW_DRAW_ITEM_RIGHT      = $0B   ; Item list right panel (Item_list_right_tiles_buffer)
WINDOW_DRAW_RING_LIST       = $0C   ; Ring list (Rings_list_tiles_buffer)
WINDOW_DRAW_SELL_LIST       = $0D   ; Sell list / item list (Message_speed draw path)
WINDOW_DRAW_ITEM_SELL_TALL  = $0E   ; Item/sell list, 8-row (Item_list_tiles_buffer tall)
; ============================================================
; Dialogue State Machine IDs (Dialogue_state)
; ============================================================
; DialogueStateMachine dispatches on Dialogue_state & $3F via
; DialogueStateHandlerMap.  Each constant names the handler that
; will be called on the next tick.
;
DIALOG_STATE_INIT                                 = $00   ; -> DialogState_Init
DIALOG_STATE_WAIT_SCRIPT_THEN_ADVANCE             = $01   ; -> DialogState_WaitScriptThenAdvance
DIALOG_STATE_WAIT_BUTTON_THEN_CLOSE_MENU          = $02   ; -> DialogState_WaitButtonThenCloseMenu
DIALOG_STATE_WAIT_C_THEN_RESTART_DIALOGUE         = $03   ; -> DialogState_WaitCThenRestartDialogue
DIALOG_STATE_DRAW_YES_NO_DIALOG                   = $04   ; -> DialogState_DrawYesNoDialog
DIALOG_STATE_PROCESS_YES_NO_ANSWER                = $05   ; -> DialogState_ProcessYesNoAnswer
DIALOG_STATE_WAIT_SCRIPT_THEN_OPEN_SHOP_MENU      = $06   ; -> DialogState_WaitScriptThenOpenShopMenu
DIALOG_STATE_SHOP_MENU_INPUT                      = $07   ; -> DialogState_ShopMenuInput
DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_TO_OVERWORLD  = $08   ; -> DialogState_WaitScriptThenCloseToOverworld
DIALOG_STATE_REDRAW_HUD_AND_CLOSE                 = $09   ; -> DialogState_RedrawHudAndClose
DIALOG_STATE_WAIT_SCRIPT_THEN_OPEN_SELL_LIST_WINDOW= $0A   ; -> DialogState_WaitScriptThenOpenSellListWindow
DIALOG_STATE_WAIT_DRAW_THEN_SHOW_MONEY_WINDOW     = $0B   ; -> DialogState_WaitDrawThenShowMoneyWindow
DIALOG_STATE_SHOP_SELL_ITEM_SELECT_INPUT          = $0C   ; -> DialogState_ShopSellItemSelectInput
DIALOG_STATE_SHOP_BUY_CONFIRM_AND_PURCHASE        = $0D   ; -> DialogState_ShopBuyConfirmAndPurchase
DIALOG_STATE_WAIT_SCRIPT_THEN_DRAW_SELL_CONFIRM   = $0E   ; -> DialogState_WaitScriptThenDrawSellConfirm
DIALOG_STATE_SELL_CONFIRM_YES_NO_INPUT            = $0F   ; -> DialogState_SellConfirmYesNoInput
DIALOG_STATE_WAIT_SCRIPT_THEN_GO_TO_BUY_MENU      = $10   ; -> DialogState_WaitScriptThenGoToBuyMenu
DIALOG_STATE_WAIT_SCRIPT_THEN_OPEN_INVENTORY_SELL_LIST= $11   ; -> DialogState_WaitScriptThenOpenInventorySellList
DIALOG_STATE_WAIT_SCRIPT_THEN_RETURN_TO_SELL_LIST = $12   ; -> DialogState_WaitScriptThenReturnToSellList
DIALOG_STATE_SELL_INVENTORY_ITEM_SELECT_INPUT     = $13   ; -> DialogState_SellInventoryItemSelectInput
DIALOG_STATE_WAIT_SCRIPT_THEN_DRAW_SELL_ITEM_YES_NO= $14   ; -> DialogState_WaitScriptThenDrawSellItemYesNo
DIALOG_STATE_SELL_INVENTORY_CONFIRM_AND_SELL      = $15   ; -> DialogState_SellInventoryConfirmAndSell
DIALOG_STATE_DRAW_SELL_INVENTORY_YES_NO           = $16   ; -> DialogState_DrawSellInventoryYesNo
DIALOG_STATE_SELL_INVENTORY_CANCEL_OR_CONFIRM     = $17   ; -> DialogState_SellInventoryCancelOrConfirm
DIALOG_STATE_WAIT_SCRIPT_WITH_YES_NO_OR_CONTINUE  = $18   ; -> DialogState_WaitScriptWithYesNoOrContinue
DIALOG_STATE_DRAW_FORTUNE_TELLER_MONEY_WINDOW     = $19   ; -> DialogState_DrawFortuneTellerMoneyWindow
DIALOG_STATE_FORTUNE_TELLER_PAY_AND_READ          = $1A   ; -> DialogState_FortuneTellerPayAndRead
DIALOG_STATE_WAIT_FORTUNE_TELLER_SCRIPT_THEN_CLOSE= $1B   ; -> DialogState_WaitFortuneTellerScriptThenClose
DIALOG_STATE_WAIT_SCRIPT_THEN_DRAW_INN_YES_NO     = $1C   ; -> DialogState_WaitScriptThenDrawInnYesNo
DIALOG_STATE_DRAW_INN_MONEY_WINDOW                = $1D   ; -> DialogState_DrawInnMoneyWindow
DIALOG_STATE_INN_PAY_AND_SLEEP                    = $1E   ; -> DialogState_InnPayAndSleep
DIALOG_STATE_WAIT_SCRIPT_THEN_START_SLEEP_FADE    = $1F   ; -> DialogState_WaitScriptThenStartSleepFade
DIALOG_STATE_SLEEP_FADE_AND_RESTORE               = $20   ; -> DialogState_SleepFadeAndRestore
DIALOG_STATE_WAIT_SCRIPT_THEN_OPEN_CHURCH_MENU    = $21   ; -> DialogState_WaitScriptThenOpenChurchMenu
DIALOG_STATE_CHURCH_MENU_INPUT                    = $22   ; -> DialogState_ChurchMenuInput
DIALOG_STATE_WAIT_SCRIPT_THEN_CLOSE_CHURCH_TO_HUD = $23   ; -> DialogState_WaitScriptThenCloseChurchToHud
DIALOG_STATE_WAIT_TILE_THEN_CLOSE_TO_OVERWORLD    = $24   ; -> DialogState_WaitTileThenCloseToOverworld
DIALOG_STATE_WAIT_SCRIPT_THEN_DRAW_CURSE_YES_NO   = $25   ; -> DialogState_WaitScriptThenDrawCurseYesNo
DIALOG_STATE_DRAW_CURSE_REMOVAL_MONEY_WINDOW      = $26   ; -> DialogState_DrawCurseRemovalMoneyWindow
DIALOG_STATE_CURSE_REMOVAL_PAY_AND_CURE           = $27   ; -> DialogState_CurseRemovalPayAndCure
DIALOG_STATE_WAIT_SCRIPT_THEN_DRAW_POISON_YES_NO  = $28   ; -> DialogState_WaitScriptThenDrawPoisonYesNo
DIALOG_STATE_DRAW_POISON_CURE_MONEY_WINDOW        = $29   ; -> DialogState_DrawPoisonCureMoneyWindow
DIALOG_STATE_POISON_CURE_PAY_AND_CURE             = $2A   ; -> DialogState_PoisonCurePayAndCure
DIALOG_STATE_WAIT_SCRIPT_THEN_OPEN_SAVE_MENU      = $2B   ; -> DialogState_WaitScriptThenOpenSaveMenu
DIALOG_STATE_SAVE_MENU_INPUT                      = $2C   ; -> DialogState_SaveMenuInput
DIALOG_STATE_MALAGE_WAIT_SCRIPT_THEN_OPEN_SELL_LIST= $2D   ; -> DialogState_MalageWaitScriptThenOpenSellList
DIALOG_STATE_MALAGE_WAIT_DRAW_THEN_SHOW_MONEY_SELL_WINDOW= $2E   ; -> DialogState_MalageWaitDrawThenShowMoneySellWindow
DIALOG_STATE_MALAGE_SHOP_SELECT_ITEM_TO_BUY       = $2F   ; -> DialogState_MalageShopSelectItemToBuy
DIALOG_STATE_MALAGE_SHOP_CONFIRM_OR_CANCEL        = $30   ; -> DialogState_MalageShopConfirmOrCancel
DIALOG_STATE_MALAGE_SHOP_GIVE_VERMILION_SWORD     = $31   ; -> DialogState_MalageShopGiveVermilionSword
DIALOG_STATE_WAIT_SCRIPT_THEN_GO_TO_OVERWORLD     = $32   ; -> DialogState_WaitScriptThenGoToOverworld
DIALOG_STATE_MALAGE_BLACKSMITH_INTRO              = $33   ; -> DialogState_MalageBlacksmithIntro
; ============================================================
; Movement Constants
; ============================================================
; The player moves one tile at a time.  Each tile is 16 pixels,
; so the movement step counter counts down from 16 to 0.
;
PLAYER_MOVE_STEPS   = $10     ; Steps (pixels) per tile movement (16)

; ============================================================
; VDP DMA Control Words
; ============================================================
; Pre-built VDP control port command words for DMA operations.
; Written to Vdp_dma_cmd before triggering a DMA transfer.
;
VDP_DMA_CMD_CRAM    = $C0000080 ; DMA write to CRAM (palette RAM) at offset 0
; ============================================================
; Boolean Flag Values
; ============================================================
; Boolean flag fields throughout the game use $FF as "true/active"
; and 0 (CLR) as "false/inactive".  TST.b is used to read them.
;
FLAG_TRUE           = $FF     ; Set a boolean flag to true / active
; ============================================================
; Sentinel / "None" Constants
; ============================================================
; $FFFF is used as a sentinel meaning "none / not set" across
; several fields.
;
MENU_CURSOR_NONE    = $FFFF   ; Menu_cursor_last_index: no previous position (force redraw)
TILEMAP_PLANE_B     = $FFFF   ; Tilemap_plane_select: non-zero means use plane B
EQUIP_NONE          = $FFFF   ; Equipped_*: slot is empty / nothing equipped
MAGIC_NONE          = $FFFF   ; Readied_magic: no spell is readied
; ============================================================
; Tile Type Values (Current_tile_type)
; ============================================================
; Stored in Current_tile_type after GetCurrentTileType masks the
; tilemap word with $F000.  The upper nibble encodes what kind of
; tile transition the player is standing on.
;
TILE_TYPE_ENTRANCE  = $2000   ; Building / cave entrance tile (go deeper)
TILE_TYPE_CASTLE    = $3000   ; Castle door tile (enter castle)
TILE_TYPE_EXIT      = $F000   ; Exit tile (return to overworld / higher floor)

; ============================================================
; VDP Tile Attribute Constants
; ============================================================
; OR'd into tile index words when writing tiles to VRAM.
; $6000 = priority bit set + palette line 3 (used for dialogue/script tiles).
;
VDP_ATTR_SCRIPT     = $6000   ; VDP tile attributes for script/dialogue rendering
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

; Note-sequence script control bytes (used in PSGChannel_NoteLoop, FMChannel_NoteLoop,
; FMArpeggio_ReadNote).  Bytes $80-$8F in a pitch/arpeggio sequence are control codes;
; bytes below $80 are raw pitch/note values.
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
; Object/Entity Struct Field Offsets  (RAM-001)
; ============================================================
; A5 and A6 both point into the object pool at $FFFFD000.
;   A5 = primary entity (player, field enemy, NPC, boss body)
;   A6 = secondary sprite slot (child part, linked via obj_next_offset)
;
; Usage: MOVE.w obj_world_x(A5), D0
;        MOVE.b obj_direction(A5), D1
;
; Full struct layout (all objects share offsets $00–$27; upper fields
; are type-specific and share offsets with different semantics):
;
; Off  Size  Name                 Roles / notes
; ---- ----  ---------------      -------------------------------------------
; $00   .b   obj_active           bit 7 = active flag (BSET/BCLR #7)
; $01   .b   obj_next_offset      linked-list stride to next slot (LEA (A6,D0.w),A6)
; $02   .l   obj_tick_fn          behavior/tick function pointer
; $06   .b   obj_sprite_size      VDP sprite size nibble (bits[3:2]=W-1, [1:0]=H-1)
; $07   .b   obj_sprite_flags     VDP tile-attr high byte (priority/palette/flip)
; $08   .w   obj_tile_index       VRAM tile index for sprite
; $0A   .w   obj_screen_x         on-screen X (pixels, added to world pos)
; $0C   .w   obj_screen_y         on-screen Y (pixels)
; $0E   .l   obj_world_x          world X position (fixed-point: .w integer, $10=sub)
; $12   .l   obj_world_y          world Y position  (also vobj_hblank_fn for mini-objs)
; $16   .w   obj_sort_key         sprite Z-depth sort value
; $18   .b   obj_direction        facing direction (0=up,2=left,4=down,6=right)
; $19   .b   obj_npc_busy_flag    NPC busy flag ($FF=busy)
; $1A   .b   obj_invuln_timer     invulnerability frame countdown
; $1B   .b   obj_move_counter     movement/animation step counter
; $1C   .l   obj_npc_str_ptr      NPC: hint-text/script pointer
; $1C   .w   obj_hitbox_half_w    enemy/projectile: hitbox half-width  (same offset)
; $1E   .w   obj_hitbox_half_h    enemy/projectile: hitbox half-height
; $20   .l   obj_pos_x_fixed      1st-person fixed-point X  (dungeon movement)
; $22   .w   obj_seg_counter      battle: segment sub-state / center-Y counter
; $24   .b   obj_sprite_frame     current sprite frame index
; $25   .b   obj_behavior_flag    NPC conditional behavior flag ($FF=triggered)
; $26   .b   obj_hit_flag         collision/hit flag ($FF=hit this frame)
; $27   .b   obj_npc_saved_dir    NPC: saved wander direction
; $27   .b   obj_orbit_angle      orbiting projectile: sine-table angle (same offset)
; $27   .b   demon_dir_flag       DemonBoss: reverse-direction sentinel (same offset)
; $28   .w   obj_hp               enemy: current HP
; $2A   .w   obj_xp_reward        enemy: XP awarded on kill
; $2C   .w   obj_max_hp           enemy: max HP  (also boss damage, see BOSS_ constants)
; $2D   .b   obj_collidable       NPC: solid flag ($01=solid)
; $2E   .l   obj_anim_ptr         NPC: animation table pointer
; $2E   .b   obj_hitbox_x_neg     enemy: hitbox left extent, signed  (same offset)
; $2F   .b   obj_hitbox_x_pos     enemy: hitbox right extent, signed
; $30   .b   obj_hitbox_y_neg     enemy: hitbox top extent, signed
; $31   .b   obj_hitbox_y_pos     enemy: hitbox bottom extent, signed
; $32   .l   obj_vel_x            enemy: X velocity (fixed-point)
; $36   .l   obj_vel_y            enemy: Y velocity (fixed-point)
; $3A   .w   obj_attack_timer     enemy: attack/AI cooldown counter
; $3B   .b   obj_sub_timer        projectile: trail count / scatter counter (low byte of $3A)
; $3C   .w   obj_knockback_timer  enemy: knockback stun countdown
; $3E   .w   obj_kim_reward       enemy: gold (kims) awarded on kill
; $40+       boss-specific fields (demon_*, orbit_*, soldier_*)
;
; See individual field definitions below for full semantics.
;
obj_active          equ $00   ; byte: bit 7 = active flag (BSET/BCLR #7)
obj_next_offset     equ $01   ; byte: linked-list next-slot stride (LEA (A6,D0.w),A6)
obj_tick_fn         equ $02   ; long: tick/behavior function pointer
obj_sprite_size     equ $06   ; byte: VDP sprite size nibble (bits[3:2]=H cells-1, bits[1:0]=V cells-1)
obj_sprite_flags    equ $07   ; byte: VDP tile attr high byte (bit7=priority, bits6-5=palette, bit4=V-flip, bit3=H-flip)

; obj_sprite_size values: bits[3:2]=horizontal cells-1, bits[1:0]=vertical cells-1
SPRITE_SIZE_1x1     = $00   ; 1×1 cells (8×8 px)
SPRITE_SIZE_2x1     = $01   ; 2×1 cells (16×8 px)
SPRITE_SIZE_3x1     = $02   ; 3×1 cells (24×8 px)
SPRITE_SIZE_2x2     = $05   ; 2×2 cells (16×16 px)
SPRITE_SIZE_3x2     = $06   ; 3×2 cells (24×16 px)
SPRITE_SIZE_4x2     = $07   ; 4×2 cells (32×16 px)
SPRITE_SIZE_2x3     = $09   ; 2×3 cells (16×24 px)
SPRITE_SIZE_3x3     = $0A   ; 3×3 cells (24×24 px)
SPRITE_SIZE_4x3     = $0B   ; 4×3 cells (32×24 px)
SPRITE_SIZE_1x4     = $0C   ; 1×4 cells (8×32 px)
SPRITE_SIZE_2x4     = $0D   ; 2×4 cells (16×32 px)
SPRITE_SIZE_3x4     = $0E   ; 3×4 cells (24×32 px)
SPRITE_SIZE_4x4     = $0F   ; 4×4 cells (32×32 px)
obj_tile_index      equ $08   ; word: VRAM tile index for sprite
obj_screen_x        equ $0A   ; word: on-screen X position (pixels)
obj_screen_y        equ $0C   ; word: on-screen Y position (pixels)
obj_world_x         equ $0E   ; word: world X position (pixels)
obj_world_y         equ $12   ; word: world Y position (pixels)
; NOTE: obj_world_y ($12) is also used as the HBlank handler function pointer
;       in the VBlank/HBlank mini-objects (8-word slots). Those uses are named
;       vobj_hblank_fn below.
vobj_hblank_fn      equ $12   ; long: HBlank handler fn ptr (VBlank/HBlank handler objects only)
obj_sort_key        equ $16   ; word: sprite priority sort value (low byte used)
obj_direction       equ $18   ; byte: facing direction (0=up,2=left,4=down,6=right)
obj_npc_busy_flag   equ $19   ; byte: NPC busy/interacting flag ($FF = busy, $00 = free)
obj_invuln_timer    equ $1A   ; byte: invulnerability frame countdown
obj_move_counter    equ $1B   ; byte: movement/animation step counter
; NOTE: $1C is context-dependent — NPC: longword hint-text/script pointer (obj_npc_str_ptr);
;       enemy/projectile: word hitbox half-width (obj_hitbox_half_w). Not globally renamed.
obj_npc_str_ptr     equ $1C   ; long: NPC hint-text / script string pointer (NPC only)
obj_hitbox_half_w   equ $1C   ; word: hitbox half-width (enemy/projectile only, same offset)
obj_hitbox_half_h   equ $1E   ; word: hitbox half-height (enemy/projectile only)
obj_pos_x_fixed     equ $20   ; long: fixed-point world X position (first-person movement)
; NOTE: $22 is context-dependent — battle/projectile: word sub-state or center-Y counter (obj_seg_counter);
;       first-person: low word of obj_pos_x_fixed (not independently named in that context).
obj_seg_counter     equ $22   ; word: segment/sub-state counter (battle objects: projectile trail, boss attack phase)
obj_sprite_frame    equ $24   ; byte: current sprite frame index
obj_behavior_flag   equ $25   ; byte: NPC conditional behavior flag ($FF = triggered)
obj_hit_flag        equ $26   ; byte: collision/hit flag ($FF = hit this frame)
; NOTE: $27 is context-dependent — NPC: saved/target wander direction (obj_npc_saved_dir);
;       orbiting spiral projectile: sine-table angle accumulator (obj_orbit_angle);
;       DemonBoss: reverse-direction sentinel (demon_dir_flag).
obj_npc_saved_dir   equ $27   ; byte: NPC saved wander direction (restored after NPC interaction, NPC only)
obj_orbit_angle     equ $27   ; byte: sine-table index / angle accumulator (orbiting spiral projectile only)
obj_hp              equ $28   ; word: current hit points (enemy only)
obj_xp_reward       equ $2A   ; word: experience points awarded on kill (enemy only)
obj_max_hp          equ $2C   ; word: maximum hit points (enemy only)
obj_collidable      equ $2D   ; byte: NPC solid/collision flag ($01 = solid, NPC only)
; NOTE: $2E is context-dependent — NPC: longword animation table pointer (obj_anim_ptr);
;       enemy: four signed hitbox extent bytes at $2E/$2F/$30/$31. Not globally renamed.
obj_anim_ptr        equ $2E   ; long: NPC animation table pointer (NPC only)
obj_hitbox_x_neg    equ $2E   ; byte: hitbox left extent, signed (enemy only, same offset)
obj_hitbox_x_pos    equ $2F   ; byte: hitbox right extent, signed (enemy only)
obj_hitbox_y_neg    equ $30   ; byte: hitbox top extent, signed (enemy only)
obj_hitbox_y_pos    equ $31   ; byte: hitbox bottom extent, signed (enemy only)
obj_vel_x           equ $32   ; long: X velocity fixed-point (enemy only)
obj_vel_y           equ $36   ; long: Y velocity fixed-point (enemy only)
; NOTE: magic/follow projectiles reuse hitbox fields as word-size position offsets:
obj_proj_offset_x   equ $2E   ; word: follow-projectile X offset from player (overlaps obj_hitbox_x_neg)
obj_proj_offset_y   equ $30   ; word: follow-projectile Y offset from player (overlaps obj_hitbox_y_neg)
; NOTE: orbiting spiral projectile reuses $2E as long orbit_center_x (overlaps obj_hitbox_x_neg)
obj_orbit_center_x  equ $2E   ; word/long: orbit center X position (orbiting spiral projectile only)
obj_attack_timer    equ $3A   ; word: attack/AI cooldown frame counter (enemy only)
; NOTE: $3B is the low byte of the obj_attack_timer word, used independently as a byte counter
;       in projectile trail emission and boss scatter logic.
obj_sub_timer       equ $3B   ; byte: secondary timer/counter low byte (projectile trail count, scatter counter)
obj_knockback_timer equ $3C   ; word: knockback/stun frame countdown (enemy only)
obj_kim_reward      equ $3E   ; word: gold (kims) awarded on kill (enemy only)

; Boss-specific scratch fields — used only by a single boss and therefore
; safe to name.  They REUSE the same offsets as the general struct but with
; boss-specific semantics.
;
; DemonBoss (lines ~15990–16530) exclusive fields:
demon_ai_state      equ $42   ; byte: AI phase index (0–5), jump-table index into BossAiDemonJumpTable
demon_wing_flags    equ $1D   ; byte: wing-fire capability bits (bit0=left, bit1=right, bit2=fire-along-X)
; Body-segment initial Y-coordinate slots — set at spawn, used to position the
; 6 worm-body child objects via SpawnChildObjects.  Offsets $44–$4E (words).
demon_seg0_y        equ $44   ; word: body segment 0 initial Y world coord
demon_seg1_y        equ $46   ; word: body segment 1 initial Y world coord
demon_seg2_y        equ $48   ; word: body segment 2 initial Y world coord
demon_seg3_y        equ $4A   ; word: body segment 3 initial Y world coord
demon_seg4_y        equ $4C   ; word: body segment 4 initial Y world coord
demon_seg5_y        equ $4E   ; word: body segment 5 initial Y world coord
;
; Dual-use — DemonBoss fire-direction (0/1/2) AND OrbitBoss charge-dir flag ($FF/$00)
; Defined here for documentation; NOT globally replaced due to conflicting semantics.
demon_fire_dir      equ $41   ; DemonBoss: fire direction (0=straight,1=left,2=right)
orbit_charge_dir    equ $41   ; OrbitBoss: charge direction flag ($FF=positive clamp, $00=negative)
;
; Additional DemonBoss-exclusive scratch fields:
demon_seg_active    equ $1C   ; byte: body-segment visible flag ($FF = active/visible, $00 = inactive)
demon_move_timer    equ $1E   ; word: movement-phase frame countdown (set to $1E=30, decremented each tick)
demon_move_steps    equ $38   ; word: horizontal bounce step counter (set 1–4, decremented each step until rebound)
demon_dir_flag      equ $27   ; byte: reverse-direction sentinel ($FF = should reverse X velocity, $00 = normal)
demon_wing_anim     equ $40   ; byte: wing animation frame toggle (bit0 used; incremented each frame when vel_y==8)

; Parma Castle Soldier exclusive scratch field:
soldier_home_tile_y equ $2B   ; byte: saved tile Y row of the soldier's home/patrol origin
soldier_patrol_state equ $29  ; byte: patrol direction state (6 = face-right/wander, 2 = face-down/home)

; ============================================================
; VRAM Sprite Tile Base Addresses (obj_tile_index values)
; ============================================================
; These are the VRAM tile index values loaded into obj_tile_index
; when spawning or initialising specific sprite types.
; Each value is the base tile in VRAM where that sprite's graphics
; are stored.
;
VRAM_TILE_ENEMY_BASE        = $0019  ; Standard field/town enemy sprite bank (all melee/ranged AI types)
VRAM_TILE_NPC_MAN_B         = $00CD  ; NPC "Man B" sprite bank (Watling restored-youth form, etc.)
VRAM_TILE_ORBIT_BOSS_ORB    = $0199  ; OrbitBoss central orb sprite bank (BossOrbTick_Static)
VRAM_TILE_ORBIT_BOSS_RING   = $0021  ; OrbitBoss satellite ring sprite bank
VRAM_TILE_DRAGON_HEAD       = $014F  ; Dragon boss head sprite bank (DragonHeadA/B_IdleTick)
VRAM_TILE_ENCOUNTER_PORTRAIT = $042B  ; Battle encounter portrait sprite bank (InitEncounterPortrait)
VRAM_TILE_PLAYER_SLASH      = $0245  ; Player sword-slash attack sprite bank
VRAM_TILE_HYDRO_ICICLE      = $0275  ; Hydro boss icicle projectile sprite bank
VRAM_TILE_BATTLE_PLAYER     = $000D  ; Standard battle scene player sprite bank (BattlePlayerInputHandler)
VRAM_TILE_BATTLE_WEAPON     = $0015  ; Battle scene player weapon sprite bank (BattleSlot2WeaponHandler)
VRAM_TILE_BOSS_BATTLE_PLAYER = $0011 ; Boss battle player intro sprite bank
VRAM_TILE_BOSS_BATTLE_SHIELD = $001D ; BossBattleShieldTick sprite bank
VRAM_TILE_NPC_MAN_A         = $0091  ; NPC "Man A" sprite bank (Watling/Parma conditional alternate)
VRAM_TILE_NPC_VILLAGER_C    = $0109  ; NPC "Villager C" sprite bank (Watling thank-you form)
VRAM_TILE_ENEMY_ALT         = $00D9  ; Enemy variant sprite bank (SetObjectBoundsType2)
VRAM_TILE_DRAGON_FIREBALL_A = $016A  ; Dragon boss fireball sprite phase A
VRAM_TILE_DRAGON_FIREBALL_B = $0161  ; Dragon boss fireball sprite phase B
VRAM_TILE_HYDRA_PROJECTILE  = $02C8  ; Hydra boss thrown projectile sprite bank
VRAM_TILE_NAME_ENTRY_GRID   = $04DA  ; Name entry screen grid cursor sprite bank
VRAM_TILE_NAME_ENTRY_TEXT   = $04DB  ; Name entry screen text cursor sprite bank
VRAM_TILE_INTRO_SWORD       = $0483  ; Intro/title sword animation sprite bank
VRAM_TILE_MENU_CURSOR_L     = $0487  ; Menu cursor left-half sprite bank
VRAM_TILE_MENU_CURSOR_R     = $048B  ; Menu cursor right-half sprite bank
VRAM_TILE_VOLTIOS_EXPLOSION = $0269  ; Voltios deactivate/ascend explosion sprite bank
VRAM_TILE_HYDRO_ICICLE_FALL = $0295  ; Hydro boss large falling icicle sprite bank

; ============================================================
; Null Pointer Sentinel
; ============================================================
NULL_PTR            = 0     ; Null pointer / list terminator used in dc.l data tables

; ============================================================
; Enemy Reward Type Constants (EnemyData reward_type field)
; ============================================================
; Used in the reward_type word of each EnemyData entry.
; $FFFF = no drop; $0000–$0003 = drop category.
ENEMY_REWARD_NONE   = $FFFF ; No item/gold drop
ENEMY_REWARD_TYPE_0 = $0000 ; Drop type 0 (gold/common)
ENEMY_REWARD_TYPE_1 = $0001 ; Drop type 1 (item; reward_value encodes item ID)
ENEMY_REWARD_TYPE_2 = $0002 ; Drop type 2
ENEMY_REWARD_TYPE_3 = $0003 ; Drop type 3


