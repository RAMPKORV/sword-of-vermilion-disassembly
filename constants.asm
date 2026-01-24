VDP_control_port    = $C00004
VDP_data_port       = $C00000
Z80_bus_request     = $A11100
Script_player_name  = $F7

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

;RAM

Fade_out_buffer         = $FFFFC08E
Fade_in_buffer          = $FFFFC0AA
Palette_fade_in_mask    = $FFFFC0AB
Palette_line_0_index    = $FFFFC080
Palette_line_1_index    = $FFFFC082
Palette_line_2_index    = $FFFFC084
Palette_line_3_index    = $FFFFC086

Camera_movement_buffer_in_town = $FFFFC10C
Town_tileset_index      = $FFFFC128
Town_npc_data_ptr       = $FFFFC15E
Tilemap_plane_select    = $FFFFC174
Current_town_room = $FFFFC126

Script_source_offset    = $FFFFC202
Script_source_base      = $FFFFC204
Script_tile_attrs       = $FFFFC208
Script_text_complete    = $FFFFC20F
Script_output_y         = $FFFFC232
Script_output_x         = $FFFFC234
Script_talk_source      = $FFFFC250
Text_build_buffer       = $FFFFC260
Script_window_tiles_buffer = $FFFF7AB4
Small_menu_tiles_buffer    = $FFFF7CF4
Large_menu_tiles_buffer    = $FFFF7E52
Left_menu_tiles_buffer     = $FFFF862E
Window_tilemap_buffer      = $FFFF9920
Window_text_scratch        = $FFFF9D80

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

Reward_script_type          = $FFFFC570
Reward_script_value         = $FFFFC572
Reward_script_flag          = $FFFFC574
Reward_script_active        = $FFFFC56C
Reward_script_available     = $FFFFC56F
Pending_hint_text           = $FFFFC438
Map_trigger_flags           = $FFFFC820
Talker_gfx_descriptor_ptr   = $FFFFC566
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

Menu_cursor_column_break    = $FFFFC23A
Menu_cursor_last_index      = $FFFFC23C
Menu_cursor_index           = $FFFFC23E
Menu_cursor_base_x          = $FFFFC236
Menu_cursor_base_y          = $FFFFC238

Player_entity_ptr           = $FFFFCC08
Enemy_list_ptr              = $FFFFCC14
Current_encounter_gfx_ptr   = $FFFFC686
Player_invulnerable         = $FFFFC661
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

Shop_selected_index          = $FFFFC4A0
Shop_item_count              = $FFFFC4A2
Shop_selected_price          = $FFFFC4B0
Shop_item_list               = $FFFFC4B4

Town_camera_move_state       = $FFFFC100
Town_camera_move_counter     = $FFFFC102
HScroll_base                 = $FFFFC104
VScroll_base                 = $FFFFC106
Town_camera_tile_x           = $FFFFC116
Town_camera_tile_y           = $FFFFC114
VDP_Reg1_cache               = $FFFFC3F2
HScroll_full_update_flag     = $FFFFC39A
Ending_sequence_step         = $FFFFC390
Ending_timer                 = $FFFFC392
HScroll_update_busy          = $FFFFC3B4
Scene_update_flag            = $FFFFC3B6
HScroll_run_table            = $FFFFC3B8
Vdp_dma_cmd                  = $FFFFC18C
Vdp_dma_cmd_hi               = $FFFFC18E
Vdp_dma_ram_routine          = $FFFFC190
Tilemap_data_ptr_plane_a     = $FFFFC182
Tilemap_data_ptr_plane_b     = $FFFFC186
Sprite_attr_count            = $FFFFE000
Sprite_attr_buffer           = $FFFFE004
Tile_gfx_buffer              = $FFFFA000
Tilemap_buffer_plane_b       = $FFFF2000

Area_map_revealed             = $FFFFC55F
Cave_light_active             = $FFFFC560
Cave_light_timer              = $FFFFC562

Camera_scroll_x               = $FFFFC40E
Camera_scroll_y               = $FFFFC410

Controller_current_state    = $FFFFC408
Controller_previous_state   = $FFFFC409

Sound_queue_count           = $FFFFC320
Sound_queue_buffer          = $FFFFC322
Sound_driver_play           = $FFFFF404


Current_town = $FFFFC40C
Current_cave_room = $FFFFC556

Program_state = $FFFFC400
Game_state = $FFFFC412

Confirm_option = $FFFFC428

Equipped_items  = $FFFFC4D0
Equipped_sword  = $FFFFC4D0
Equipped_shield = $FFFFC4D2
Equipped_armor  = $FFFFC4D4
Readied_magic   = $FFFFC4D6
Equipped_unused = $FFFFC4D8 ; Probably unused, at least

Selected_item_option        = $FFFFC440
Possessed_items_length      = $FFFFC442
Possessed_items_list        = $FFFFC444

Selected_magic_option       = $FFFFC460

Possessed_magics_length     = $FFFFC462
Possessed_magics_list       = $FFFFC464
Possessed_equipment_length  = $FFFFC482
Possessed_equipment_list    = $FFFFC484

Dialogue_state              = $FFFFC41E

Selected_equipment_option   = $FFFFC4E6

Current_shop_type = $FFFFC4A6

SHOP_TYPE_ITEM      = $00
SHOP_TYPE_EQUIPMENT = $01
SHOP_TYPE_MAGIC     = $02

Towns_visited                                   = $FFFFC508

Player_is_in_overworld                          = $FFFFC540
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

Player_position_x_in_town       = $FFFFC606
Player_position_y_in_town       = $FFFFC608
Player_direction_in_town        = $FFFFC60C
Player_movement_buffer_in_town  = $FFFFC60E
Current_tile_type               = $FFFFC610
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
Player_name                     = $FFFFC64C
Transaction_amount              = $FFFFC65A

;$FFFFC65B.w
;$FFFFC65C.w
;$FFFFC65D.w

Player_position_x_outside_town  = $FFFFC662
Player_position_y_outside_town  = $FFFFC664
Player_map_sector_x             = $FFFFC666
Player_map_sector_y             = $FFFFC668

Player_cave_position_x          = $FFFFC66A
Player_cave_position_y          = $FFFFC66C
Player_cave_map_sector_x        = $FFFFC66E
Player_cave_map_sector_y        = $FFFFC670

Random_number                   = $FFFFC680
Number_Of_Enemies               = $FFFFC682
Checked_for_encounter           = $FFFFC683
Current_encounter_type_options  = $FFFFC684
Steps_since_last_encounter      = $FFFFC685
Current_encounter_type          = $FFFFC68A

Encounter_rate                  = $FFFFC69C
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
Swaffham_ruined                             = $FFFFC748
Player_has_received_sword_of_vermilion      = $FFFFC757
Tsarkon_is_dead                             = $FFFFC758
Old_man_has_received_sketch                 = $FFFFC75F
Old_woman_has_received_sketch               = $FFFFC760
Player_has_received_old_womans_sketch       = $FFFFC763
Player_greatly_poisoned                     = $FFFFC76C

Boss_event_trigger                      = $FFFFC817
Solidier_fight_event_trigger            = $FFFFC816
Map_triggers_start = $FFFFC818

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
