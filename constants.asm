VDP_control_port = $C00004
VDP_data_port = $C00000
Z80_bus_request = $A11100
Script_player_name = $F7


;RAM
Script_source_offset = $FFFFC202
Script_source_base = $FFFFC204
Script_output_y = $FFFFC232
Script_output_x = $FFFFC234

Current_town = $FFFFC40C

Possessed_items_length = $FFFFC442
Possessed_items_list = $FFFFC444

Possessed_magics_length = $FFFFC462
Possessed_magics_list = $FFFFC464

Possessed_equipment_length = $FFFFC482
Possessed_equipment_list = $FFFFC484

Player_name = $FFFFC64C
Player_position_x_in_town = $FFFFC606
Player_position_y_in_town = $FFFFC608
Player_direction_in_town = $FFFFC60C
Player_movement_buffer_in_town = $FFFFC60E
Player_kims = $FFFFC620
Player_experience = $FFFFC624
Player_next_level_experience = $FFFFC628
Player_hp = $FFFFC62C
Player_mhp = $FFFFC62E
Player_mmp = $FFFFC630
Player_mp = $FFFFC632
Player_str = $FFFFC634
Player_ac = $FFFFC636
Player_int = $FFFFC638
Player_dex = $FFFFC63A
Player_luk = $FFFFC63C
Player_level = $FFFFC640

Map_list = $FFFFC818
Event_triggers_list = $FFFFC720 ; TODO: Investigate more