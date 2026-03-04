; ===========================================================================
; src/playerstats.asm
; Player Statistics Data
; ===========================================================================
;
; OVERVIEW
; --------
; This file contains all static lookup tables for the player character's
; progression system:
;
;   Table                              Lines    Size    Notes
;   ---------------------------------- -------- ------- --------------------
;   PlayerLevelToMmpMap                5–36     31 w    Max MP gained per level-up
;   PlayerLevelToMhpMap                37–68    31 w    Max HP gained per level-up
;   PlayerLevelToStrMap                69–100   31 w    STR gained per level-up
;   EquipmentToStatModifierMap         101–158  58 w    STR/AC bonus by equip index
;   PlayerLevelToAcMap                 159–190  31 w    AC gained per level-up
;   PlayerLevelToIntMap                191–222  31 w    INT gained per level-up
;   PlayerLevelToDexMap                223–254  31 w    DEX gained per level-up
;   PlayerLevelToLukMap                255–286  31 w    LUK gained per level-up
;   PlayerLevelToNextLevelExperienceMap 287–318 31 l    Cumulative EXP for next level
;
; ============================================================
; RANDOMIZER GUIDE
; ============================================================
;
; --- Level-Up Stat Delta Tables ---
; Each of the 7 level-up stat tables (Mmp, Mhp, Str, Ac, Int, Dex, Luk) contains
; exactly 31 dc.w entries (31 level transitions, covering levels 1–31).
; Entry N represents the amount added to the stat when the player reaches level N+1.
; Index 0 = gain when reaching level 1, index 30 = gain when reaching level 31.
;
; Usage: when leveling up from level L to L+1, the game reads:
;   PlayerLevelTo<Stat>Map[L] (0-based index = current level)
; and adds it to the corresponding Player_<stat> RAM variable.
;
; Key RAM addresses (constants.asm):
;   Player_level   $FFFFC640  (word)
;   Player_hp      $FFFFC62C  (word)  — current HP
;   Player_mhp     $FFFFC62E  (word)  — max HP
;   Player_str     $FFFFC642  (word)
;   Player_ac      $FFFFC644  (word)
;   Player_int     $FFFFC646  (word)  — INT (magic power)
;   Player_dex     $FFFFC648  (word)
;   Player_luk     $FFFFC64A  (word)
;   Player_mmp     (see constants.asm)
;
; To randomize level-up progression: modify dc.w values in these tables.
; WARNING: keep values non-zero; a level with 0 stat gain is legal but unusual.
;
; --- EquipmentToStatModifierMap ---
; 58 dc.w entries, indexed by equipment ID (equipment slot 0–57).
; For weapons (swords): value = added STR bonus while equipped.
; For shields and armor: value = added AC bonus while equipped.
; The map covers all equipment types in a flat array.
; Equipment type boundaries (approximate, from EquipmentResaleValueMap in shopdata.asm):
;   $00–$13  Swords  (20 entries, IDs match EQUIPMENT_SWORD_* constants)
;   $14–$27  Shields (20 entries, IDs match EQUIPMENT_SHIELD_* constants)
;   $28–$38  Armor   (17 entries, IDs match EQUIPMENT_ARMOR_* constants)
; NOTE: Total 57 entries in EquipmentResaleValueMap vs. 58 here — the extra
; entry at the end of the stat map is padding ($0000).
;
; --- Experience Table ---
; PlayerLevelToNextLevelExperienceMap: 31 dc.l entries.
; Entry N = total EXP required to reach level N+1 (not a delta — cumulative).
; Entry 0 = EXP to reach level 2 ($90 = 144 EXP).
; Entry 29 = EXP for level 31 cap ($999999 = 10,066,329 EXP).
; Entry 30 = sentinel value $FFFFFF (never reached normally).
; ===========================================================================
PlayerLevelToMmpMap: ; word-sized
	dc.w	$0
	dc.w	$11
	dc.w	$3
	dc.w	$4
	dc.w	$6
	dc.w	$5
	dc.w	$6
	dc.w	$6
	dc.w	$E
	dc.w	$7
	dc.w	$8
	dc.w	$8
	dc.w	$8
	dc.w	$8
	dc.w	$9
	dc.w	$A 
	dc.w	$A
	dc.w	$A
	dc.w	$B
	dc.w	$B
	dc.w	$B
	dc.w	$C
	dc.w	$C
	dc.w	$D
	dc.w	$D
	dc.w	$E
	dc.w	$10
	dc.w	$1E
	dc.w	$26
	dc.w	$57
	dc.w	$66 
PlayerLevelToMhpMap: ; word-sized
	dc.w	$21
	dc.w	$1B
	dc.w	$1B
	dc.w	$26
	dc.w	$1D
	dc.w	$1D
	dc.w	$20
	dc.w	$21
	dc.w	$20
	dc.w	$1A
	dc.w	$25
	dc.w	$23
	dc.w	$1A
	dc.w	$1D
	dc.w	$27
	dc.w	$1D 
	dc.w	$22
	dc.w	$24
	dc.w	$24
	dc.w	$20
	dc.w	$2B
	dc.w	$20
	dc.w	$21
	dc.w	$21
	dc.w	$1C
	dc.w	$1F
	dc.w	$2B
	dc.w	$22
	dc.w	$1F
	dc.w	$1C
	dc.w	$1D 
PlayerLevelToStrMap: ; Player_level -> Player_str mappings. How much is added to Player_str when reaching a level
	dc.w	$1
	dc.w	$7
	dc.w	$7
	dc.w	$9
	dc.w	$C
	dc.w	$C
	dc.w	$D
	dc.w	$E
	dc.w	$F
	dc.w	$10
	dc.w	$11
	dc.w	$12
	dc.w	$13
	dc.w	$15
	dc.w	$15 
	dc.w	$15 
	dc.w	$15
	dc.w	$16
	dc.w	$17
	dc.w	$D
	dc.w	$17
	dc.w	$21
	dc.w	$17
	dc.w	$18
	dc.w	$19
	dc.w	$3B
	dc.w	$28
	dc.w	$29
	dc.w	$2A
	dc.w	$2B
	dc.w	$2C 
EquipmentToStatModifierMap: ; For swords, this is the added str value. For shields and armor it's the added ac value
	dc.w	$1C
	dc.w	$29
	dc.w	$31
	dc.w	$52 
	dc.w	$67
	dc.w	$85 
	dc.w	$9C
	dc.w	$7B
	dc.w	$BD 
	dc.w	$D2
	dc.w	$AC
	dc.w	$100
	dc.w	$10F 
	dc.w	$12C 
	dc.w	$3D 
	dc.w	$154 
	dc.w	$EB 
	dc.w	$118 
	dc.w	$0 
	dc.w	$0 
	dc.w	$8 
	dc.w	$D
	dc.w	$1A 
	dc.w	$27
	dc.w	$42 
	dc.w	$4D
	dc.w	$39 
	dc.w	$3D 
	dc.w	$64
	dc.w	$7D
	dc.w	$46 
	dc.w	$61 
	dc.w	$6C 
	dc.w	$84
	dc.w	$52 
	dc.w	$59
	dc.w	$6D
	dc.w	$0
	dc.w	$0
	dc.w	$0
	dc.w	$B 
	dc.w	$1D
	dc.w	$23 
	dc.w	$26
	dc.w	$2F
	dc.w	$64
	dc.w	$8B 
	dc.w	$37
	dc.w	$47 
	dc.w	$AE
	dc.w	$6F
	dc.w	$96
	dc.w	$A7 
	dc.w	$C8
	dc.w	$45
	dc.w	$78
	dc.w	$C3 
PlayerLevelToAcMap: ; word-sized
	dc.w	$8
	dc.w	$3
	dc.w	$B
	dc.w	$C
	dc.w	$F
	dc.w	$D
	dc.w	$E
	dc.w	$F
	dc.w	$10
	dc.w	$11
	dc.w	$12
	dc.w	$13
	dc.w	$15
	dc.w	$15
	dc.w	$15
	dc.w	$15 
	dc.w	$16
	dc.w	$17
	dc.w	$D
	dc.w	$17
	dc.w	$21
	dc.w	$17
	dc.w	$18
	dc.w	$19
	dc.w	$3B
	dc.w	$28
	dc.w	$29
	dc.w	$2A
	dc.w	$2B
	dc.w	$2C
	dc.w	$0 
PlayerLevelToIntMap: ; word-sized
	dc.w	$7
	dc.w	$B 
	dc.w	$C 
	dc.w	$C 
	dc.w	$9 
	dc.w	$D 
	dc.w	$A 
	dc.w	$B 
	dc.w	$8 
	dc.w	$B 
	dc.w	$D 
	dc.w	$B
	dc.w	$8 
	dc.w	$C 
	dc.w	$D 
	dc.w	$C 
	dc.w	$C 
	dc.w	$C 
	dc.w	$C 
	dc.w	$D 
	dc.w	$F 
	dc.w	$A 
	dc.w	$B 
	dc.w	$E 
	dc.w	$E 
	dc.w	$C 
	dc.w	$E 
	dc.w	$C 
	dc.w	$D 
	dc.w	$C 
	dc.w	$B 
PlayerLevelToDexMap: ; word-sized
	dc.w	$64
	dc.w	$52 
	dc.w	$30 
	dc.w	$22 
	dc.w	$2C 
	dc.w	$44 
	dc.w	$3B 
	dc.w	$3F 
	dc.w	$2B
	dc.w	$40 
	dc.w	$41 
	dc.w	$36 
	dc.w	$68 
	dc.w	$42 
	dc.w	$36 
	dc.w	$36 
	dc.w	$2D 
	dc.w	$2D 
	dc.w	$23 
	dc.w	$26 
	dc.w	$1F 
	dc.w	$24 
	dc.w	$19 
	dc.w	$23 
	dc.w	$1B 
	dc.w	$1A 
	dc.w	$24 
	dc.w	$10 
	dc.w	$17 
	dc.w	$12 
	dc.w	$19 
PlayerLevelToLukMap: ; Player_level -> Player_luk mappings. How much is added to Player_luk  when reaching a level
	dc.w	$5
	dc.w	$5
	dc.w	$7
	dc.w	$8
	dc.w	$7
	dc.w	$6
	dc.w	$6
	dc.w	$6
	dc.w	$3
	dc.w	$5
	dc.w	$8
	dc.w	$7
	dc.w	$5
	dc.w	$6
	dc.w	$5
	dc.w	$8 
	dc.w	$15
	dc.w	$B
	dc.w	$C
	dc.w	$8
	dc.w	$1F
	dc.w	$24
	dc.w	$19
	dc.w	$23
	dc.w	$1B
	dc.w	$1A
	dc.w	$24
	dc.w	$10
	dc.w	$17
	dc.w	$12
	dc.w	$4A 
PlayerLevelToNextLevelExperienceMap:
	dc.l	$90
	dc.l	$320 
	dc.l	$660 
	dc.l	$1540 
	dc.l	$3000 
	dc.l	$6300 
	dc.l	$11000
	dc.l	$18000
	dc.l	$28000 
	dc.l	$40000 
	dc.l	$56000 
	dc.l	$77000 
	dc.l	$100000 
	dc.l	$140000 
	dc.l	$180000 
	dc.l	$240000
	dc.l	$300000 
	dc.l	$350000 
	dc.l	$400000 
	dc.l	$460000 
	dc.l	$520000 
	dc.l	$575000 
	dc.l	$630000 
	dc.l	$686000
	dc.l	$742000 
	dc.l	$800000 
	dc.l	$854000 
	dc.l	$910000 
	dc.l	$972000 
	dc.l	$999999 
	dc.l	$FFFFFF