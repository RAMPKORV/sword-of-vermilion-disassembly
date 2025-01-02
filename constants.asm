VDP_control_port    = $C00004
VDP_data_port       = $C00000
Z80_bus_request     = $A11100
Script_player_name  = $F7


;RAM
Script_source_offset    = $FFFFC202
Script_source_base      = $FFFFC204
Script_output_y         = $FFFFC232
Script_output_x         = $FFFFC234

Current_town = $FFFFC40C

Equipped_sword  = $FFFFC4D0
Equipped_shield = $FFFFC4D2
Equipped_armor  = $FFFFC4D4
Readied_magic   = $FFFFC4D6
Equipped_Unused = $FFFFC4D8 ; Probably unused, at least

Possessed_items_length      = $FFFFC442
Possessed_items_list        = $FFFFC444
Possessed_magics_length     = $FFFFC462
Possessed_magics_list       = $FFFFC464
Possessed_equipment_length  = $FFFFC482
Possessed_equipment_list    = $FFFFC484

Current_shop_type = $FFFFC4A6

SHOP_TYPE_ITEM      = $00
SHOP_TYPE_EQUIPMENT = $01
SHOP_TYPE_MAGIC     = $02

Player_move_forward_in_overworld                = $FFFFC541
Player_move_backward_in_overworld               = $FFFFC544
Player_rotate_counter_clockwise_in_overworld    = $FFFFC542
Player_rotate_clockwise_in_overworld            = $FFFFC543

Player_position_x_in_town       = $FFFFC606
Player_position_y_in_town       = $FFFFC608
Player_direction_in_town        = $FFFFC60C
Player_movement_buffer_in_town  = $FFFFC60E
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
Player_greatly_poisoned         = $FFFFC76C

Map_list = $FFFFC818
Event_triggers_list = $FFFFC720 ; TODO: Investigate more

; Towns
TOWN_WYCLIF         = $00
TOWN_PARMA          = $01
TOWN_WATLING        = $02
TOWN_DEEPDALE       = $03
TOWN_STOW           = $04
TOWN_KELTWICK       = $05
TOWN_MALAGA         = $06
TOWN_BARROW         = $07
TOWN_TADCASTER      = $08
TOWN_HELWIG         = $09
TOWN_SWAFHAM        = $0A
TOWN_EXCALABRIA     = $0B
TOWN_HASTINGS       = $0C
TOWN_CARTHAHENA     = $0D

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
