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

PROGRAM_STATE_00 = $00
PROGRAM_STATE_01 = $01;
PROGRAM_STATE_02 = $02;
PROGRAM_STATE_03 = $03;
PROGRAM_STATE_04 = $04;
PROGRAM_STATE_05 = $05;
PROGRAM_STATE_06 = $06;
PROGRAM_STATE_07 = $07;
PROGRAM_STATE_08 = $08;
PROGRAM_STATE_09 = $09;
PROGRAM_STATE_0A = $0A;
PROGRAM_STATE_0B = $0B;
PROGRAM_STATE_0C = $0C;
PROGRAM_STATE_0D = $0D;
PROGRAM_STATE_0E = $0E;
PROGRAM_STATE_0F = $0F;
PROGRAM_STATE_10 = $10;
PROGRAM_STATE_11 = $11;
PROGRAM_STATE_12 = $12;
PROGRAM_STATE_13 = $13;
PROGRAM_STATE_14 = $14;
PROGRAM_STATE_15 = $15;

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

