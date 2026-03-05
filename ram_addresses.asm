; ======================================================================
; ram_addresses.asm
; All RAM address definitions ($FFFF...)
; ======================================================================

; ============================================================
; RAM Addresses
; ============================================================

; ------------------------------------------------------------
; Tilemap Plane Buffers
; ------------------------------------------------------------
Tilemap_buffer_plane_a       = $FFFF0000   ; buf  tilemap nametable for VDP plane A (DMA source)
Battle_gfx_slot_1_buffer     = $FFFF1500   ; buf  decompressed graphics for battle enemy slot 1
Boss_gfx_slot_1_buffer       = $FFFF1800   ; buf  decompressed graphics for boss slot 1
Tilemap_buffer_plane_b       = $FFFF2000   ; buf  tilemap nametable for VDP plane B (DMA source)
Boss_gfx_extra_buffer        = $FFFF3600   ; buf  extra decompressed graphics for boss sprite parts
Boss_gfx_slot_2_buffer       = $FFFF3A00   ; buf  decompressed graphics for boss slot 2
Player_overworld_gfx_buffer = $FFFF4000    ; buf  player sprite tiles during overworld/cave movement
Battle_gfx_slot_2_buffer     = $FFFF4200   ; buf  decompressed graphics for battle enemy slot 2
Town_tilemap_plane_a         = $FFFF4D80   ; buf  town tilemap plane A DMA header (4-byte VDP cmd)
Town_tilemap_plane_a_data    = $FFFF4D84   ; buf  town plane A tile data (follows 4-byte header)
Town_tilemap_plane_b         = $FFFF6380   ; buf  town tilemap plane B DMA header (4-byte VDP cmd)
Town_tilemap_plane_b_data    = $FFFF6384   ; buf  town plane B tile data (follows 4-byte header)
Message_speed_menu_tiles_buffer = $FFFF7980 ; buf  tile scratch area for message-speed menu window
Script_window_tiles_buffer = $FFFF7AB4     ; buf  tile scratch area for main dialogue script window
Small_menu_tiles_buffer    = $FFFF7CF4     ; buf  tile scratch area for small menu windows
Item_list_tiles_buffer     = $FFFF7D56     ; buf  tile scratch area for item list window
Right_menu_tiles_buffer    = $FFFF7DCC     ; buf  tile scratch area for right-side menu window
Large_menu_tiles_buffer    = $FFFF7E52     ; buf  tile scratch area for large menu window
Ready_equipment_menu_tiles_buffer = $FFFF7E80 ; buf  tile scratch area for ready-equipment menu
Full_menu_tiles_buffer       = $FFFF7F4C   ; buf  tile scratch area for full-screen menu window
Equipment_list_tiles_buffer  = $FFFF820A   ; buf  tile scratch area for equipment list window
Status_menu_tiles_buffer   = $FFFF821A     ; buf  tile scratch area for player status menu
Shop_list_tiles_buffer       = $FFFF82AA   ; buf  tile scratch area for shop item list window
Prompt_menu_tiles_buffer     = $FFFF8366   ; buf  tile scratch area for yes/no prompt window
Shop_submenu_tiles_buffer    = $FFFF83FE   ; buf  tile scratch area for shop buy/sell submenu
Magic_list_tiles_buffer      = $FFFF85D0   ; buf  tile scratch area for magic/spell list window
Left_menu_tiles_buffer     = $FFFF862E     ; buf  tile scratch area for left-side menu window
Item_list_right_tiles_buffer = $FFFF88C4   ; buf  tile scratch area for right item-list window
Rings_list_tiles_buffer      = $FFFF8C8A   ; buf  tile scratch area for rings/equip list window
Map_sector_top_left          = $FFFF9000   ; buf  decompressed RLE overworld sector: top-left
Map_sector_top_center        = $FFFF9010   ; buf  decompressed RLE overworld sector: top-center
Map_sector_top_right         = $FFFF9020   ; buf  decompressed RLE overworld sector: top-right
Map_sector_middle_left       = $FFFF9300   ; buf  decompressed RLE overworld sector: middle-left
Map_sector_center            = $FFFF9310   ; buf  decompressed RLE overworld sector: center
Map_sector_middle_right      = $FFFF9320   ; buf  decompressed RLE overworld sector: middle-right
Map_sector_bottom_left       = $FFFF9600   ; buf  decompressed RLE overworld sector: bottom-left
Map_sector_bottom_center     = $FFFF9610   ; buf  decompressed RLE overworld sector: bottom-center
Map_sector_bottom_right      = $FFFF9620   ; buf  decompressed RLE overworld sector: bottom-right
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
Window_tilemap_buffer      = $FFFF9920   ; buf  tilemap word array built by window drawing routines (DMA source)
Window_text_scratch        = $FFFF9D80   ; buf  text-tile scratch area used during window rendering

; ------------------------------------------------------------
; Graphics Buffers
; ------------------------------------------------------------
Tile_gfx_buffer              = $FFFFA000   ; buf  general-purpose decompressed tile graphics staging area
Enemy_gfx_buffer             = $FFFFA200   ; buf  decompressed enemy tile graphics staging area

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
Vblank_flag             = $FFFFC0FF   ; .b  set to $FF by VBlank ISR each frame; cleared by WaitForVBlank spin-loop

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
Vdp_dma_ram_routine          = $FFFFC190   ; buf  self-modifying DMA trampoline code copied to RAM at init
