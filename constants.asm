VDP_control_port    = $C00004
VDP_data_port       = $C00000
Z80_bus_request     = $A11100

; ============================================================
; Dialogue Script Opcodes
; ============================================================
; These control codes are embedded in dialogue text strings
; to control text rendering and trigger game events.
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
Script_player_name      = $F7   ; Insert player's name
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

; After masking a random number to 8 bits (ANDI.w #$00FF), comparing
; against this threshold gives a 50% probability split (0-127 vs 128-255).
RANDOM_HALF_THRESHOLD   = $0080   ; 50% RNG threshold (128 of 256)

; Tile-space visibility radius used by CheckEntityOnScreen.
; Entity tile coordinate (world_coord - camera) >> 4 is compared against this.
ENTITY_VISIBLE_TILE_RADIUS = $0019  ; 25 tiles — entity considered off-screen if >= this

; Pixel distance threshold for enemy proximity-chase activation.
; Compared against |player_world_x - enemy_world_x| and |player_world_y - enemy_world_y|.
ENEMY_CHASE_PROXIMITY   = $0040   ; 64 px — player within this range triggers chase

; Boss sprite animation phase endpoint.
; After masking obj_move_counter with $0030 or $0018 and shifting right,
; the result is compared against this to detect end-of-animation-cycle.
BOSS_ANIM_PHASE_END     = $000C   ; 12 — animation cycle complete when phase reaches this

; OrbitBoss fire-ring animation: obj_move_counter is masked with $0070 and
; compared against this to decide when to spawn a fire projectile.
ORBIT_BOSS_FIRE_PHASE   = $0030   ; 48 — fire phase threshold within move_counter cycle

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

;RAM

Fade_out_lines_mask     = $FFFFC08E
Fade_in_lines_mask      = $FFFFC0AA
Palette_fade_in_mask    = $FFFFC0AB
Palette_line_0_index    = $FFFFC080
Palette_line_1_index    = $FFFFC082
Palette_line_2_index    = $FFFFC084
Palette_line_0_fade_target = $FFFFC0AC
Palette_line_1_fade_target = $FFFFC0AE
Palette_line_2_fade_target = $FFFFC0B0
Palette_line_3_fade_target = $FFFFC0B2
Palette_line_3_index    = $FFFFC086
Palette_line_1_index_saved = $FFFFC096
Palette_line_2_cycle_base = $FFFFC098
Palette_fade_tick_counter = $FFFFC0A4
Palette_line_0_fade_in_target = $FFFFC0B6
Palette_line_0_buffer   = $FFFFC000
Palette_line_1_buffer   = $FFFFC020
Palette_line_2_buffer   = $FFFFC040
Palette_line_3_buffer   = $FFFFC060
Frame_delay_counter     = $FFFFC08A
Palette_fade_step_counter = $FFFFC08C
Palette_line_2_cycle_index_1 = $FFFFC09A
Palette_line_2_cycle_index_2 = $FFFFC09C
Palette_cycle_frame_counter = $FFFFC09E
Palette_line_2_cycle_step = $FFFFC09F
Rng_state               = $FFFFC0A0
Palette_fade_in_step    = $FFFFC0A8
Palette_fade_in_step_counter = $FFFFC0B4
Palette_line_1_fade_in_target = $FFFFC0B8
Palette_line_2_fade_in_target = $FFFFC0BA
Palette_line_3_fade_in_target = $FFFFC0BC
Palette_buffer_dirty    = $FFFFC0BD
Npc_count               = $FFFFC0FC
Vblank_flag             = $FFFFC0FF

Camera_scrolling_active = $FFFFC10C
Tilemap_row_overflow_flag = $FFFFC10D
Town_tilemap_width      = $FFFFC110
Town_tilemap_height     = $FFFFC112

; Town tilemap scroll guard: if the map dimension (width or height in tiles)
; is <= this value, the camera scroll routine skips tile-row/column updates.
TOWN_MAP_MIN_SCROLL_TILES = $0010   ; 16 tiles — minimum map size for scrolling

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

Town_tilemap_update_row = $FFFFC120
Town_tilemap_update_column = $FFFFC122
Town_tilemap_row_update_pending = $FFFFC124
Town_tilemap_column_update_pending = $FFFFC125
Town_tileset_index      = $FFFFC128
Town_vram_tile_base     = $FFFFC12A
Town_spawn_x            = $FFFFC12C
Player_spawn_tile_y_buffer = $FFFFC12E
Saved_player_x_in_town  = $FFFFC130
Town_player_spawn_y     = $FFFFC132
Saved_player_spawn_x    = $FFFFC134
Saved_player_y_room1    = $FFFFC136
Town_camera_initial_x   = $FFFFC138
Town_default_camera_y   = $FFFFC13A
Town_saved_camera_x     = $FFFFC13C
Saved_camera_tile_y_room1 = $FFFFC13E
Saved_camera_tile_x_unused = $FFFFC140
Saved_camera_tile_y_unused = $FFFFC142
Town_camera_spawn_x     = $FFFFC144
Town_camera_target_tile_y = $FFFFC146
Player_spawn_position_x = $FFFFC148
Player_spawn_tile_y     = $FFFFC14A
Saved_town_tileset_index = $FFFFC14E
Saved_town_room_1       = $FFFFC152
Saved_town_room_2       = $FFFFC154
Saved_town_room_3       = $FFFFC156
Town_tilemap_vram_base  = $FFFFC158
Saved_player_spawn_x_room2 = $FFFFC15A
Saved_player_spawn_y_room2 = $FFFFC15C
Town_npc_data_ptr       = $FFFFC15E
Saved_town_npc_data_ptr = $FFFFC162
Saved_npc_data_ptr      = $FFFFC166
Saved_npc_data_ptr_room3 = $FFFFC16A
Tilemap_plane_select    = $FFFFC174
Town_tilemap_plane_a_ptr = $FFFFC176
Tilemap_total_tiles     = $FFFFC118
Npc_init_routine_ptr    = $FFFFC170
Town_tilemap_plane_b_ptr = $FFFFC17A
Tilemap_width           = $FFFFC17E
Tilemap_height          = $FFFFC17F
Tilemap_buffer_size     = $FFFFC180
Ending_hscroll_offset   = $FFFFC18A
Current_town_room = $FFFFC126

Cursor_blink_timer      = $FFFFC200
Script_source_offset    = $FFFFC202
Script_source_base      = $FFFFC204
Script_tile_attrs       = $FFFFC208
Script_render_tick      = $FFFFC20C
Script_text_complete    = $FFFFC20F
Message_speed           = $FFFFC210
Script_has_continuation = $FFFFC211
Script_has_yes_no_question = $FFFFC212
Script_reading_player_name = $FFFFC213
Player_name_index       = $FFFFC214
Script_output_base_x    = $FFFFC230
Script_output_y         = $FFFFC232
Script_output_x         = $FFFFC234
Script_talk_source      = $FFFFC250
Script_continuation_ptr = $FFFFC254
Text_build_buffer       = $FFFFC260
Script_window_tiles_buffer = $FFFF7AB4
Message_speed_menu_tiles_buffer = $FFFF7980
Item_list_tiles_buffer     = $FFFF7D56
Small_menu_tiles_buffer    = $FFFF7CF4
Right_menu_tiles_buffer    = $FFFF7DCC
Large_menu_tiles_buffer    = $FFFF7E52
Status_menu_tiles_buffer   = $FFFF821A
Left_menu_tiles_buffer     = $FFFF862E
Shop_item_index            = $FFFF991A
Window_tilemap_buffer      = $FFFF9920
Window_text_scratch        = $FFFF9D80
Player_overworld_gfx_buffer = $FFFF4000

Window_tile_x              = $FFFFC224
Window_tile_y              = $FFFFC226
Window_tile_width          = $FFFFC22C
Window_tile_height         = $FFFFC22E
Window_text_x              = $FFFF9906
Window_text_y              = $FFFF990C
Window_width               = $FFFF9904
Window_height              = $FFFF990A
Window_tilemap_x           = $FFFF9902
Window_tilemap_y           = $FFFF9908
Window_tile_attrs          = $FFFF990E
Window_tilemap_draw_pending = $FFFF9900
Window_tilemap_draw_active  = $FFFF9910
Window_draw_row            = $FFFF9914
Window_draw_type           = $FFFF9912
Window_text_row            = $FFFF9916
Window_tilemap_row_draw_pending = $FFFF9911

Window_tilemap_draw_x       = $FFFFC220
Window_tilemap_draw_y       = $FFFFC222
Window_tilemap_draw_width   = $FFFFC228
Window_tilemap_draw_height  = $FFFFC22A
Window_number_cursor_x      = $FFFFC242
Window_number_cursor_y      = $FFFFC244
Menu_cursor_second_column_x = $FFFFC246

Reward_script_type          = $FFFFC570
Reward_script_value         = $FFFFC572
Reward_script_flag          = $FFFFC574
Reward_script_active        = $FFFFC56C
Herbs_available             = $FFFFC56D
Truffles_available          = $FFFFC56E
Reward_script_available     = $FFFFC56F
Found_something_nearby      = $FFFFC579
Enemy_reward_type           = $FFFFC57A
Enemy_reward_value          = $FFFFC57C
Pending_hint_text           = $FFFFC438
Map_trigger_index           = $FFFFC43C
Sleep_delay_timer           = $FFFFC434
Banshee_powder_active       = $FFFFC45C
Intro_timer                 = $FFFFC498
Map_trigger_flags           = $FFFFC820
Talker_gfx_descriptor_ptr   = $FFFFC566
Chest_opened_flag           = $FFFFC56B
Talker_present_flag         = $FFFFC578
Dialog_active_flag          = $FFFFC561
Dialog_state_flag           = $FFFFC56A
Dialog_timer                = $FFFFC554
Dialog_phase                = $FFFFC552
Saved_game_state            = $FFFFC414
Saved_player_direction      = $FFFFC616
Spellbook_menu_state        = $FFFFC424
Overworld_menu_state        = $FFFFC416
Main_menu_selection         = $FFFFC418
Player_input_blocked        = $FFFFC41C
Item_menu_state             = $FFFFC420
Equip_list_menu_state       = $FFFFC422
Ready_equipment_state       = $FFFFC426
Take_item_state             = $FFFFC42C
Open_menu_state             = $FFFFC42A
Item_menu_action_mode       = $FFFFC458

Menu_cursor_base_x          = $FFFFC236
Menu_cursor_base_y          = $FFFFC238
Menu_cursor_column_break    = $FFFFC23A
Menu_cursor_last_index      = $FFFFC23C
Menu_cursor_index           = $FFFFC23E
Dialog_response_index       = $FFFFC240

Player_entity_ptr           = $FFFFCC08
Battle_entity_slot_1_ptr    = $FFFFCC0C
Battle_entity_slot_2_ptr    = $FFFFCC10
Enemy_list_ptr              = $FFFFCC14
Current_encounter_gfx_ptr   = $FFFFC686
Inaudios_steps_remaining    = $FFFFC68E
Player_invulnerable         = $FFFFC661
Player_attacking_flag       = $FFFFC660
File_menu_phase             = $FFFFC672
File_load_complete          = $FFFFC67C
Cave_position_saved         = $FFFFC67D
Player_awakening_flag       = $FFFFC67F
Skip_town_intro_after_fight = $FFFFC6A8
Object_slot_01_ptr           = $FFFFCC18
Object_slot_02_ptr           = $FFFFCC1C
Object_slot_03_ptr           = $FFFFCC20
Object_slot_04_ptr           = $FFFFCC24
Object_slot_05_ptr           = $FFFFCC28
Object_slot_06_ptr           = $FFFFCC2C
Object_slot_07_ptr           = $FFFFCC30
Object_slot_08_ptr           = $FFFFCC34
Object_slot_09_ptr           = $FFFFCC38
Object_slot_0A_ptr           = $FFFFCC3C
Object_slot_0B_ptr           = $FFFFCC40
Object_slot_0C_ptr           = $FFFFCC44
Object_slot_0D_ptr           = $FFFFCC48
Object_slot_0E_ptr           = $FFFFCC4C
Current_actor_ptr            = $FFFFCC54

Enemy_anim_frame_mask        = $FFFFC690
Enemy_anim_frame_shift       = $FFFFC692
Enemy_anim_table_main        = $FFFFC694
Enemy_anim_table_child       = $FFFFC698
Enemy_pair_offset_flag       = $FFFFC69E
Enemy_direction_flag         = $FFFFC69F
Encounter_behavior_flag      = $FFFFC68C
Boss_ai_state                = $FFFFC536
Boss_part_count              = $FFFFC537
Boss_defeated_flag           = $FFFFC538
Boss_battle_exit_flag        = $FFFFC539
Boss_death_anim_done         = $FFFFC53A
Boss_active_parts            = $FFFFC53C
Boss_max_hp                  = $FFFFC53E
Boss_attack_direction        = $FFFFC53F
Is_boss_battle               = $FFFFC531
Terrain_tileset_index        = $FFFFC532
Battle_type                  = $FFFFC534
Is_in_battle                 = $FFFFC530
Battle_active_flag           = $FFFFC67E
First_person_wall_right      = $FFFFC545
First_person_center_wall     = $FFFFC546
Fp_wall_right_2              = $FFFFC547
First_person_wall_frame      = $FFFFC54C
Wall_render_y_offset         = $FFFFC54E
Overworld_movement_frame     = $FFFFC54A
Map_tile_base_index          = $FFFFC558
Player_compass_frame         = $FFFFC564
Chest_already_opened         = $FFFFC584
Chest_animation_frame        = $FFFFC580
Chest_animation_timer        = $FFFFC582
Open_chest_delay_timer       = $FFFFC585
Door_unlocked_flag           = $FFFFC586
Encounter_triggered          = $FFFFC550
Level_up_timer               = $FFFFC55C

Shop_selected_index          = $FFFFC4A0
Shop_item_count              = $FFFFC4A2
Shop_action_selection        = $FFFFC4A4
Shop_selected_price          = $FFFFC4B0
Shop_sell_price              = $FFFFC4AC
Shop_item_list               = $FFFFC4B4
Shop_purchase_made           = $FFFFC4C4

Town_camera_move_state       = $FFFFC100
Town_camera_move_counter     = $FFFFC102
HScroll_base                 = $FFFFC104
VScroll_base                 = $FFFFC106
HScroll_min_limit            = $FFFFC108
VScroll_max_limit            = $FFFFC10A
Town_camera_tile_x           = $FFFFC116
Town_camera_tile_y           = $FFFFC114
VDP_Reg1_cache               = $FFFFC3F2
HScroll_full_update_flag     = $FFFFC39A
Ending_sequence_step         = $FFFFC390
Ending_timer                 = $FFFFC392
HScroll_update_busy          = $FFFFC3B4
Intro_text_pending           = $FFFFC3B5
Scene_update_flag            = $FFFFC3B6
HScroll_run_table            = $FFFFC3B8
Vdp_dma_cmd                  = $FFFFC18C
Vdp_dma_cmd_hi               = $FFFFC18E
Vdp_dma_ram_routine          = $FFFFC190
Tilemap_data_ptr_plane_a     = $FFFFC182
Tilemap_data_ptr_plane_b     = $FFFFC186
Sprite_attr_count            = $FFFFE000
Sprite_update_pending        = $FFFFE002
Sprite_attr_buffer           = $FFFFE004
Sprite_sort_buffer           = $FFFFE200
Sprite_sort_temp_buffer      = $FFFFE3F0
Sprite_priority_slots        = $FFFFE400
Tile_gfx_buffer              = $FFFFA000
Enemy_gfx_buffer             = $FFFFA200
Tilemap_buffer_plane_a       = $FFFF0000
Tilemap_buffer_plane_b       = $FFFF2000
Town_tilemap_plane_b         = $FFFF6380
Map_sector_center            = $FFFF9310

; Map sector buffers
Map_sector_top_left          = $FFFF9000
Map_sector_top_center        = $FFFF9010
Map_sector_top_right         = $FFFF9020
Map_sector_middle_left       = $FFFF9300
Map_sector_middle_right      = $FFFF9320
Map_sector_bottom_left       = $FFFF9600
Map_sector_bottom_center     = $FFFF9610
Map_sector_bottom_right      = $FFFF9620

; Battle/Tilemap buffers
Battle_gfx_slot_1_buffer     = $FFFF1500
Boss_gfx_slot_1_buffer       = $FFFF1800
Boss_gfx_extra_buffer        = $FFFF3600
Boss_gfx_slot_2_buffer       = $FFFF3A00
Battle_gfx_slot_2_buffer     = $FFFF4200
Town_tilemap_plane_a         = $FFFF4D80
Town_tilemap_plane_a_data    = $FFFF4D84
Town_tilemap_plane_b_data    = $FFFF6384

; Menu tile buffers
Ready_equipment_menu_tiles_buffer = $FFFF7E80
Full_menu_tiles_buffer       = $FFFF7F4C
Equipment_list_tiles_buffer  = $FFFF820A
Shop_list_tiles_buffer       = $FFFF82AA
Prompt_menu_tiles_buffer     = $FFFF8366
Shop_submenu_tiles_buffer    = $FFFF83FE
Magic_list_tiles_buffer      = $FFFF85D0
Item_list_right_tiles_buffer = $FFFF88C4
Rings_list_tiles_buffer      = $FFFF8C8A

; Object/entity system
Object_table_base            = $FFFFD0E0
Object_slot_base             = $FFFFD000
VBlank_object_ptr            = $FFFFCC00
HBlank_object_ptr            = $FFFFCC04
Map_indicator_entity_ptr     = $FFFFCC50
Menu_object_ptr              = $FFFFCC74
Ram_clear_end                = $FFFFFD00    ; End of general RAM clear region (before stack gap)
Stack_base                   = $FFFFFE00

Area_map_revealed             = $FFFFC55F
Cave_light_active             = $FFFFC560
Cave_light_timer              = $FFFFC562

Camera_scroll_x               = $FFFFC40E
Camera_scroll_y               = $FFFFC410

Controller_current_state    = $FFFFC408
Controller_previous_state   = $FFFFC409
Controller_2_current_state  = $FFFFC40A

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

Sprite_dma_update_pending = $FFFFC302
Npc_load_done_flag          = $FFFFC303
Sound_queue_count           = $FFFFC320
Sound_queue_buffer          = $FFFFC322
Current_area_music          = $FFFFC32A
Vblank_frame_counter        = $FFFFC32C
Vdp_dma_slot_index          = $FFFFC304
Skip_tilemap_updates        = $FFFFC340
Savegame_name_buffer        = $FFFFC35A
Savegame_name_overflow      = $FFFFC35E
Name_entry_cursor_x         = $FFFFC380
Name_entry_cursor_row       = $FFFFC382
Name_entry_key_repeat_counter = $FFFFC384
Name_entry_complete         = $FFFFC385
Name_input_cursor_pos       = $FFFFC386
Name_entry_cursor_column    = $FFFFC388
Ending_vscroll_accumulator  = $FFFFC396
VDP_Reg11_cache             = $FFFFC3F6
Intro_animation_done        = $FFFFC3B0
Title_intro_complete        = $FFFFC3B1
Intro_scroll_accumulator    = $FFFFC3B2
Prologue_complete_flag      = $FFFFC3A5
Prologue_state              = $FFFFC3A0
Prologue_scroll_offset      = $FFFFC3A4

; Prologue_state (longword, upper word used as tile counter) reaches this value
; when the full intro scroll is complete. Compared in TitleScreen_ScrollAndWait
; and UpdatePrologueScrollVRAM to know when to switch to idle mode.
PROLOGUE_SCROLL_END         = $03FF   ; 1023 — scroll counter at which intro is done
VDP_regs_cache              = $FFFFC3F0
Sound_driver_play           = $FFFFF404


Current_town = $FFFFC40C
Current_cave_room = $FFFFC556

Program_state = $FFFFC400
Timer_seconds_bcd = $FFFFC403
Timer_frame_counter = $FFFFC404
Timer_frames_per_second = $FFFFC406
Controller_2_current_state = $FFFFC40A
Gameplay_state = $FFFFC412

Dialog_selection = $FFFFC428

Equipped_items  = $FFFFC4D0
Equipped_sword  = $FFFFC4D0
Equipped_shield = $FFFFC4D2
Equipped_armor  = $FFFFC4D4
Readied_magic   = $FFFFC4D6
Equipped_unused = $FFFFC4D8 ; Probably unused, at least

Selected_item_index         = $FFFFC440
Possessed_items_length      = $FFFFC442
Possessed_items_list        = $FFFFC444

Magic_list_cursor_index     = $FFFFC460

Possessed_magics_length     = $FFFFC462
Possessed_magics_list       = $FFFFC464
Possessed_equipment_length  = $FFFFC482
Possessed_equipment_list    = $FFFFC484

Dialogue_state              = $FFFFC41E

Ready_equipment_cursor_index = $FFFFC4E6
Ready_equipment_list        = $FFFFC4E8
Ready_equipment_category    = $FFFFC4E4
Ready_equipment_selection   = $FFFFC4E2
Ready_equipment_list_length = $FFFFC4E0
Active_inventory_list_ptr   = $FFFFC4A8
Intro_animation_frame       = $FFFFC49A

Current_shop_type = $FFFFC4A6

SHOP_TYPE_ITEM      = $00
SHOP_TYPE_EQUIPMENT = $01
SHOP_TYPE_MAGIC     = $02

Towns_visited                                   = $FFFFC508
Aries_selected_town          = $FFFFC506
Church_service_selection    = $FFFFC500
Possessed_rings_count       = $FFFFC502

Player_in_first_person_mode                     = $FFFFC540
Player_move_forward_in_overworld                = $FFFFC541
Player_move_backward_in_overworld               = $FFFFC544
Player_rotate_counter_clockwise_in_overworld    = $FFFFC542
Player_rotate_clockwise_in_overworld            = $FFFFC543

Is_in_cave = $FFFFC551

DIRECTION_UP    = 0
DIRECTION_LEFT  = 2
DIRECTION_DOWN  = 4
DIRECTION_RIGHT = 6
DIRECTION_ANY   = $F

; NPC sprite attribute flags (entity +$07, high byte of VDP tile name word)
; Bits 7=priority, 6-5=palette line, 4=vflip, 3=hflip
NPC_ATTR_PAL0   = $00           ; Palette line 0 (background palette)
NPC_ATTR_PAL3   = $60           ; Palette line 3 (character palette)

; NPC collision flags (entity +$2D)
NPC_NONSOLID    = 0             ; NPC does not block movement
NPC_SOLID       = 1             ; NPC blocks movement

Player_tile_x               = $FFFFC600
Player_tile_y               = $FFFFC602
Player_tilemap_offset       = $FFFFC604
Player_position_x_in_town       = $FFFFC606
Player_position_y_in_town       = $FFFFC608
Player_direction                = $FFFFC60C
Player_direction_flags          = $FFFFC60D
Player_is_moving                = $FFFFC60E
Player_movement_step_counter    = $FFFFC60F
Current_tile_type               = $FFFFC610
Town_movement_blocked           = $FFFFC612
Player_walk_anim_toggle         = $FFFFC613
Player_movement_flags           = $FFFFC614
Player_kims                     = $FFFFC620
Player_experience               = $FFFFC624
Player_next_level_experience    = $FFFFC628
Player_hp                       = $FFFFC62C
Player_mhp                      = $FFFFC62E
Player_mmp                      = $FFFFC630
Player_mp                       = $FFFFC632
Player_str                      = $FFFFC634
Player_ac                       = $FFFFC636
Player_int                      = $FFFFC638
Player_dex                      = $FFFFC63A
Player_luk                      = $FFFFC63C
Player_level                    = $FFFFC640
Player_poisoned                 = $FFFFC642
Ending_player_name_buffer       = $FFFFC646
Poison_notified                 = $FFFFC7C6
Player_name                     = $FFFFC64C
Transaction_amount              = $FFFFC65A
Transaction_item_id             = $FFFFC65B
Transaction_item_quantity       = $FFFFC65C
Transaction_item_flags          = $FFFFC65D
Transaction_amount_end          = $FFFFC65E

Player_position_x_outside_town  = $FFFFC662
Player_position_y_outside_town  = $FFFFC664
Player_map_sector_x             = $FFFFC666
Player_map_sector_y             = $FFFFC668

Player_cave_position_x          = $FFFFC66A
Player_cave_position_y          = $FFFFC66C
Player_cave_map_sector_x        = $FFFFC66E
Player_cave_map_sector_y        = $FFFFC670

Sram_save_slot_ptr              = $FFFFC674
Sram_backup_ptr                 = $FFFFC678
Random_number                   = $FFFFC680
Number_Of_Enemies               = $FFFFC682
Checked_for_encounter           = $FFFFC683
Encounter_group_index           = $FFFFC684
Steps_since_last_encounter      = $FFFFC685
Current_encounter_type          = $FFFFC68A

Encounter_rate                  = $FFFFC69C
Enemy_position_indices          = $FFFFC6A0
Dialog_choice_event_trigger     = $FFFFC700
Dialog_choice_extended_trigger  = $FFFFC701
Dialogue_event_trigger_flag     = $FFFFC702
Quest_choice_pending            = $FFFFC703
Quest_choice_expected_answer    = $FFFFC704
Quest_choice_map_trigger        = $FFFFC705
MAX_STEPS_BETWEEN_ENCOUNTERS    = 20

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

PRICE_PASS_TO_CARTHAHENA = $50000
PRICE_SANGUIOS = $1000

Event_triggers_start                        = $FFFFC720
Blade_is_dead                               = $FFFFC720
Treasure_of_troy_challenge_issued           = $FFFFC722
Fake_king_killed                            = $FFFFC723
Treasure_of_troy_given_to_king              = $FFFFC724
Talked_to_real_king                         = $FFFFC725
Treasure_of_troy_found                      = $FFFFC726
Talked_to_king_after_given_treasure_of_troy = $FFFFC727
Player_chose_to_stay_in_parma               = $FFFFC728
Watling_youth_restored                      = $FFFFC729
Watling_villagers_asked_about_rings         = $FFFFC72A
Deepdale_truffle_quest_started              = $FFFFC72B
Truffle_collected                           = $FFFFC72C
Deepdale_king_secret_kept                   = $FFFFC72D
Sanguios_book_offered                       = $FFFFC72E
Accused_of_theft                            = $FFFFC72F
Stow_thief_defeated                         = $FFFFC730
Asti_monster_defeated                       = $FFFFC731
Stow_innocence_proven                       = $FFFFC732
Sent_to_malaga                              = $FFFFC733
Bearwulf_met                                = $FFFFC734
Bearwulf_returned_home                      = $FFFFC735
Helwig_old_woman_quest_started              = $FFFFC736
Watling_monster_encounter_triggered         = $FFFFC73E
Tadcaster_treasure_quest_started            = $FFFFC73F
Tadcaster_treasure_found                    = $FFFFC740
Malaga_king_crowned                         = $FFFFC73B
Barrow_map_received                         = $FFFFC73C
Imposter_killed                             = $FFFFC73D
Bully_first_fight_won                       = $FFFFC741
Tadcaster_bully_triggered                   = $FFFFC742
Helwig_men_rescued                          = $FFFFC744
Uncle_tibor_visited                         = $FFFFC745
Old_man_waiting_for_letter                  = $FFFFC746
Old_man_and_woman_paired                    = $FFFFC747
Swaffham_ruined                             = $FFFFC748
Ring_of_earth_obtained                      = $FFFFC749
White_crystal_quest_started                 = $FFFFC74A
Ring_of_wind_received                       = $FFFFC74B
Red_crystal_quest_started                   = $FFFFC74C
Red_crystal_received                        = $FFFFC74D
Blue_crystal_quest_started                  = $FFFFC74E
Blue_crystal_received                       = $FFFFC74F
Ate_spy_dinner                              = $FFFFC750
Swaffham_ate_poisoned_food                  = $FFFFC751
Digot_plant_received                        = $FFFFC752
Spy_dinner_poisoned_flag                    = $FFFFC753
Pass_to_carthahena_purchased                = $FFFFC754
Sword_stolen_by_blacksmith                  = $FFFFC755
Sword_retrieved_from_blacksmith             = $FFFFC756
Player_has_received_sword_of_vermilion      = $FFFFC757
Tsarkon_is_dead                             = $FFFFC758
Carthahena_boss_met                         = $FFFFC759
Alarm_clock_rang                            = $FFFFC75A
Crown_received                              = $FFFFC75B
Girl_left_for_stow                          = $FFFFC75C
Keltwick_girl_sleeping                      = $FFFFC75E
Old_man_has_received_sketch                 = $FFFFC75F
Old_woman_has_received_sketch               = $FFFFC760
Dragon_shield_offered_to_player             = $FFFFC761
Old_mans_sketch_given                       = $FFFFC762
Player_has_received_old_womans_sketch       = $FFFFC763
Dragon_shield_received                      = $FFFFC764
Pass_to_carthahena_given                    = $FFFFC765
Sanguios_purchased                          = $FFFFC766
Sanguios_confiscated                        = $FFFFC767
Sanguia_learned_from_book                   = $FFFFC768
Bearwulf_weapon_reward_given                = $FFFFC769
Tadcaster_treasure_kims_received            = $FFFFC76A
Knute_informed_of_swaffham_ruin             = $FFFFC76B
Player_greatly_poisoned                     = $FFFFC76C
Excalabria_boss_1_defeated                  = $FFFFC76D
Excalabria_boss_2_defeated                  = $FFFFC76E
Excalabria_boss_3_defeated                  = $FFFFC76F
White_crystal_received                      = $FFFFC770
Red_key_received                            = $FFFFC771
Blue_key_received                           = $FFFFC772
Carthahena_boss_defeated                    = $FFFFC773
Swaffham_spy_defeated                       = $FFFFC774
Thar_defeated                               = $FFFFC775
Luther_defeated                             = $FFFFC776
Swaffham_miniboss_defeated                  = $FFFFC777
All_rings_collected                         = $FFFFC778
Barrow_quest_1_complete                     = $FFFFC779
Barrow_quest_2_complete                     = $FFFFC77A
Poison_trap_sprung                          = $FFFFC77B
Watling_inn_free_stay_used                  = $FFFFC77C
Watling_inn_broke_penalty                   = $FFFFC77D
Sixteen_rings_used_at_throne                = $FFFFC77E
Stow_tavern_free_meal_offered               = $FFFFC77F

; Chest/Treasure Flags ($FFFFC780-$FFFFC7B2)
Thar_bronze_key_collected                   = $FFFFC780
Thar_silver_key_collected                   = $FFFFC781
Luther_gold_key_collected                   = $FFFFC782
Knute_thule_key_dialog_shown                = $FFFFC783
Thule_key_received                          = $FFFFC784
Cave_key_dialog_shown                       = $FFFFC785
Secret_key_received                         = $FFFFC786
Royal_shield_chest_opened                   = $FFFFC787
Money_chest_256_opened                      = $FFFFC788
Herbs_chest_opened                          = $FFFFC789
Herbs_chest_2_opened                        = $FFFFC78A
Crimson_armor_chest_opened                  = $FFFFC78B
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
Crimson_armor_reward_enabled                = $FFFFC79A
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
Bearwulf_cave_entered                       = $FFFFC7A7
Malaga_dungeon_person_rescued               = $FFFFC7A8
Helwig_prison_entered                       = $FFFFC7A9
Malaga_key_dialog_shown                     = $FFFFC7AA
Dungeon_key_received                        = $FFFFC7AB
Replacement_key_enabled                     = $FFFFC7AC
Received_replacement_key                    = $FFFFC7AD
Candle_chest_3_opened                       = $FFFFC7AE
Lantern_chest_2_opened                      = $FFFFC7AF
Herbs_chest_6_opened                        = $FFFFC7B0
Ruby_brooch_chest_opened                    = $FFFFC7B2
Banshee_powder_chest_opened                 = $FFFFC7B3
Money_chest_512_opened                      = $FFFFC7B4
Money_chest_1280_opened                     = $FFFFC7B5
Money_chest_1792_b_opened                   = $FFFFC7B6

; Event Flags $FFFFC7B9-$FFFFC7F2
Money_chest_20480_opened                    = $FFFFC7B9
Chest_5888_kims_opened                      = $FFFFC7BA
Money_chest_864_opened                      = $FFFFC7BB
Chest_9999_kims_opened                      = $FFFFC7BC
Chest_sapphire_shield_opened                = $FFFFC7BD
Chest_gnome_stone_opened                    = $FFFFC7BE
Chest_gem_shield_opened                     = $FFFFC7BF
Deepdale_medicine_removed                   = $FFFFC7C0
Stepfather_ring_dialog_shown                = $FFFFC7C1
Titanias_mirror_quest_prereq                = $FFFFC7C2
Titanias_mirror_acquired                    = $FFFFC7C3
Mega_blast_acquired                         = $FFFFC7C4
Rafaels_stick_acquired                      = $FFFFC7C5
Poison_notified                             = $FFFFC7C6
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
Malaga_quest_progress                       = $FFFFC7ED
Chest_mirror_of_atlas_opened                = $FFFFC7EE
Chest_barbarian_sword_opened                = $FFFFC7EF
Helwig_frypan_hit_count                     = $FFFFC7F0
Helwig_inn_wakeup_trigger                   = $FFFFC7F2
Frying_pan_knockout_flag                    = $FFFFC7F3
Map_triggers_backup                         = $FFFFC7F4
Watling_inn_unpaid_nights                   = $FFFFC7F6
Boss_battle_flags                           = $FFFFC800
Imposter_boss_trigger                       = $FFFFC804
Ring_guardian_1_boss_trigger                = $FFFFC805
Ring_guardian_2_boss_trigger                = $FFFFC806
Ring_guardian_3_boss_trigger                = $FFFFC807
Boss_battle_type_marker                     = $FFFFC80D
Soldier_fight_event_trigger                 = $FFFFC816
Boss_event_trigger                          = $FFFFC817
Rings_collected                             = $FFFFC818
Asti_monster_battle_complete                = $FFFFC81B
Carthahena_soldier_1_defeated               = $FFFFC81D
Carthahena_soldier_2_defeated               = $FFFFC81E
Carthahena_soldier_3_defeated               = $FFFFC81F

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
TOWN_SWAFHAM        = $0B
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
ITEM_WHITE_CRYSTAL      = $11
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
ENCOUNTER_FADE_PHASES       = $000A   ; Number of fade-in phases for encounter/dialogue intro (2 uses)
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
; Object/Entity Struct Field Offsets
; ============================================================
; A5 and A6 both point into the object pool. A5 = primary entity
; (player, enemy body, NPC), A6 = secondary sprite slot (child
; part, linked via obj_next_offset).
;
; Usage: MOVE.w obj_world_x(A5), D0
;        MOVE.b obj_direction(A5), D1
;
; Fields marked (enemy only) or (NPC only) differ by object type.
; Fields at $2E-$31 are not globally renamed: NPC structs store a
; longword animation pointer at $2E, while enemy structs store four
; signed hitbox-extent bytes at $2E/$2F/$30/$31.
;
obj_active          equ $00   ; byte: bit 7 = active flag (BSET/BCLR #7)
obj_next_offset     equ $01   ; byte: linked-list next-slot stride (LEA (A6,D0.w),A6)
obj_tick_fn         equ $02   ; long: tick/behavior function pointer
obj_sprite_size     equ $06   ; byte: sprite size (bits 0-1 used)
obj_sprite_flags    equ $07   ; byte: flip/attribute flags (bit3=H-flip, bit4=V-flip)
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
obj_sprite_frame    equ $24   ; byte: current sprite frame index
obj_behavior_flag   equ $25   ; byte: NPC conditional behavior flag ($FF = triggered)
obj_hit_flag        equ $26   ; byte: collision/hit flag ($FF = hit this frame)
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
obj_attack_timer    equ $3A   ; word: attack/AI cooldown frame counter (enemy only)
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
demon_move_steps    equ $38   ; word: horizontal bounce step counter (set 1–4, decremented each step until rebound)
demon_wing_anim     equ $40   ; byte: wing animation frame toggle (bit0 used; incremented each frame when vel_y==8)

; Parma Castle Soldier exclusive scratch field:
soldier_home_tile_y equ $2B   ; byte: saved tile Y row of the soldier's home/patrol origin
