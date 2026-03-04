; ===========================================================================
; Shop & Economy Data
; Inn/church prices, shop assortments, item prices, magic cost/element tables
; ===========================================================================
InnAndFortuneTellerPricesByTown:
	dc.l	$10
	dc.l	$13 
	dc.l	$18 
	dc.l	$28 
	dc.l	$50 
	dc.l	$64 
	dc.l	$96 
	dc.l	$124
	dc.l	$148 
	dc.l	$156 
	dc.l	$172 
	dc.l	$190 
	dc.l	$224
	dc.l	$250

ChurchCurseRemovalPricesByTown:
	dc.l	$100
	dc.l	$110
	dc.l	$120
	dc.l	$130
	dc.l	$140
	dc.l	$150
	dc.l	$160
	dc.l	$170
	dc.l	$180
	dc.l	$190
	dc.l	$200
	dc.l	$210
	dc.l	$220
	dc.l	$230

ChurchPoisonCurePricesByTown:
	dc.l	$2
	dc.l	$4
	dc.l	$6
	dc.l	$8
	dc.l	$10
	dc.l	$12
	dc.l	$14
	dc.l	$16
	dc.l	$18
	dc.l	$20
	dc.l	$22
	dc.l	$24
	dc.l	$26
	dc.l	$28

ShopAssortmentByTownAndShopType:
; townShopBlock item, equip, magic_buy, magic_sell
; Indexed by: town_id*16 + shop_type*4
	townShopBlock WyclifItemShopAssortment,WyclifEquipmentShopAssortment,ParmaMagicShopAssortment,ParmaMagicShopAssortment	; TOWN_WYCLIF ($00)
	townShopBlock ParmaItemShopAssortment,ParmaEquipmentShopAssortment,ParmaMagicShopAssortment,ParmaMagicShopAssortment	; TOWN_PARMA ($01)
	townShopBlock DeepdaleItemShopAssortment,DeepdaleEquipmentShopAssortment,DeepdaleMagicShopAssortment,ParmaMagicShopAssortment	; TOWN_WATLING ($02) — uses Deepdale data
	townShopBlock DeepdaleItemShopAssortment,DeepdaleEquipmentShopAssortment,DeepdaleMagicShopAssortment,ParmaMagicShopAssortment	; TOWN_DEEPDALE ($03)
	townShopBlock StowItemShopAssortment,MalagaEquipmentShopAssortment,StowMagicShopAssortment,ParmaMagicShopAssortment	; TOWN_STOW1 ($04)
	townShopBlock KeltwickItemShopAssortment,MalagaEquipmentShopAssortment,KeltwickMagicShopAssortment,ParmaMagicShopAssortment	; TOWN_STOW2 ($05) — uses Keltwick item/magic
	townShopBlock KeltwickItemShopAssortment,MalagaEquipmentShopAssortment,KeltwickMagicShopAssortment,ParmaMagicShopAssortment	; TOWN_KELTWICK ($06)
	townShopBlock MalagaItemShopAssortment,MalagaEquipmentShopAssortment,MalagaMagicShopAssortment,ParmaMagicShopAssortment	; TOWN_MALAGA ($07)
	townShopBlock BarrowItemShopAssortment,TadcasterEquipmentShopAssortment,HelwigMagicShopAssortment,ParmaMagicShopAssortment	; TOWN_BARROW ($08) — uses Tadcaster equip, Helwig magic
	townShopBlock HelwigItemShopAssortment,TadcasterEquipmentShopAssortment,HelwigMagicShopAssortment,ParmaMagicShopAssortment	; TOWN_TADCASTER ($09)
	townShopBlock HelwigItemShopAssortment,SwaffhamEquipmentShopAssortment,HelwigMagicShopAssortment,ParmaMagicShopAssortment	; TOWN_HELWIG ($0A)
	townShopBlock SwaffhamItemShopAssortment,SwaffhamEquipmentShopAssortment,SwaffhamMagicShopAssortment,ParmaMagicShopAssortment	; TOWN_SWAFFHAM ($0B)
	townShopBlock HastingsItemShopAssortment,SwaffhamEquipmentShopAssortment,HastingsMagicShopAssortment,ParmaMagicShopAssortment	; TOWN_EXCALABRIA ($0C)
	townShopBlock HastingsItemShopAssortment,SwaffhamEquipmentShopAssortment,HastingsMagicShopAssortment,ParmaMagicShopAssortment	; TOWN_HASTINGS1 ($0D)
	townShopBlock ParmaMagicShopAssortment,SwaffhamEquipmentShopAssortment,HastingsMagicShopAssortment,ParmaMagicShopAssortment	; TOWN_HASTINGS2 ($0E) — no item shop
	townShopBlock ParmaMagicShopAssortment,SwaffhamEquipmentShopAssortment,HastingsMagicShopAssortment,ParmaMagicShopAssortment	; TOWN_CARTHAHENA ($0F) — no item shop

ShopPricesByTownAndType:
; townShopBlock item, equip, magic_buy, magic_sell
; Indexed by: town_id*16 + shop_type*4
	townShopBlock WyclifItemShopPrices,WyclifEquipmentShopPrices,ParmaMagicShopPrices,ParmaMagicShopPrices	; TOWN_WYCLIF ($00)
	townShopBlock ParmaItemShopPrices,ParmaEquipmentShopPrices,ParmaMagicShopPrices,ParmaMagicShopPrices	; TOWN_PARMA ($01)
	townShopBlock DeepdaleItemShopPrices,DeepdaleEquipmentShopPrices,DeepdaleMagicShopPrices,ParmaMagicShopPrices	; TOWN_WATLING ($02) — uses Deepdale data
	townShopBlock DeepdaleItemShopPrices,DeepdaleEquipmentShopPrices,DeepdaleMagicShopPrices,ParmaMagicShopPrices	; TOWN_DEEPDALE ($03)
	townShopBlock StowItemShopPrices,MalagaEquipmentShopPrices,StowMagicShopPrices,ParmaMagicShopPrices	; TOWN_STOW1 ($04)
	townShopBlock KeltwickItemShopPrices,MalagaEquipmentShopPrices,KeltwickMagicShopPrices,ParmaMagicShopPrices	; TOWN_STOW2 ($05) — uses Keltwick item/magic
	townShopBlock KeltwickItemShopPrices,MalagaEquipmentShopPrices,KeltwickMagicShopPrices,ParmaMagicShopPrices	; TOWN_KELTWICK ($06)
	townShopBlock MalagaItemShopPrices,MalagaEquipmentShopPrices,MalagaMagicShopPrices,ParmaMagicShopPrices	; TOWN_MALAGA ($07)
	townShopBlock BarrowItemShopPrices,TadcasterEquipmentShopPrices,HelwigMagicShopPrices,ParmaMagicShopPrices	; TOWN_BARROW ($08)
	townShopBlock HelwigItemShopPrices,TadcasterEquipmentShopPrices,HelwigMagicShopPrices,ParmaMagicShopPrices	; TOWN_TADCASTER ($09)
	townShopBlock HelwigItemShopPrices,SwaffhamEquipmentShopPrices,HelwigMagicShopPrices,ParmaMagicShopPrices	; TOWN_HELWIG ($0A)
	townShopBlock SwaffhamItemShopPrices,SwaffhamEquipmentShopPrices,SwaffhamMagicShopPrices,ParmaMagicShopPrices	; TOWN_SWAFFHAM ($0B)
	townShopBlock HastingsItemShopPrices,SwaffhamEquipmentShopPrices,HastingsMagicShopPrices,ParmaMagicShopPrices	; TOWN_EXCALABRIA ($0C)
	townShopBlock HastingsItemShopPrices,SwaffhamEquipmentShopPrices,HastingsMagicShopPrices,ParmaMagicShopPrices	; TOWN_HASTINGS1 ($0D)
	townShopBlock ParmaMagicShopAssortment,SwaffhamEquipmentShopPrices,HastingsMagicShopPrices,ParmaMagicShopPrices	; TOWN_HASTINGS2 ($0E) — item slot: wrong ptr (assortment not prices), no item shop
	townShopBlock ParmaMagicShopAssortment,SwaffhamEquipmentShopPrices,HastingsMagicShopPrices,ParmaMagicShopPrices	; TOWN_CARTHAHENA ($0F) — item slot: wrong ptr (assortment not prices), no item shop
ShopResaleValueMapPtrs:
	dc.l	ItemResaleValueMap
	dc.l	EquipmentResaleValueMap
	dc.l	MagicResaleValueMap
	dc.l	MagicResaleValueMap	
ShopPossessionListPtrs:
	dc.l	Possessed_items_list
	dc.l	Possessed_equipment_list
	dc.l	Possessed_magics_list
	dc.l	Possessed_magics_list	
WyclifItemShopAssortment:
	dc.w	$2
	shopItem ITEM_HERBS
	shopItem ITEM_CANDLE
WyclifItemShopPrices:
	dc.l	$20	; Herbs:       32 kims
	dc.l	$10	; Candle:      16 kims
ParmaItemShopAssortment:
	dc.w	$5
	shopItem ITEM_CANDLE
	shopItem ITEM_HERBS
	shopItem ITEM_POISON_BALM
	shopItem ITEM_LANTERN
	shopItem ITEM_GNOME_STONE
ParmaItemShopPrices:
	dc.l	$15	; Candle:      21 kims
	dc.l	$25	; Herbs:       37 kims
	dc.l	$40	; Poison Balm: 64 kims
	dc.l	$65	; Lantern:    101 kims
	dc.l	$300	; Gnome Stone: 768 kims
DeepdaleItemShopAssortment:
	dc.w	$5
	shopItem ITEM_HERBS
	shopItem ITEM_MEDICINE
	shopItem ITEM_POISON_BALM
	shopItem ITEM_LANTERN
	shopItem ITEM_GNOME_STONE
DeepdaleItemShopPrices:
	dc.l	$30	; Herbs:        48 kims
	dc.l	$120	; Medicine:    288 kims
	dc.l	$60	; Poison Balm:  96 kims
	dc.l	$70	; Lantern:     112 kims
	dc.l	$350	; Gnome Stone: 848 kims
StowItemShopAssortment:
	dc.w	$6
	shopItem ITEM_HERBS
	shopItem ITEM_MEDICINE
	shopItem ITEM_POISON_BALM
	shopItem ITEM_LANTERN
	shopItem ITEM_GNOME_STONE
	shopItem ITEM_GRIFFIN_WING
StowItemShopPrices:
	dc.l	$30	; Herbs:         48 kims
	dc.l	$125	; Medicine:     293 kims
	dc.l	$65	; Poison Balm:  101 kims
	dc.l	$70	; Lantern:      112 kims
	dc.l	$375	; Gnome Stone:  885 kims
	dc.l	$820	; Griffin Wing: 2080 kims
KeltwickItemShopAssortment:
	dc.w	$5
	shopItem ITEM_MEDICINE
	shopItem ITEM_POISON_BALM
	shopItem ITEM_LANTERN
	shopItem ITEM_GRIFFIN_WING
	shopItem ITEM_ALARM_CLOCK
KeltwickItemShopPrices:
	dc.l	$130	; Medicine:      304 kims
	dc.l	$70	; Poison Balm:   112 kims
	dc.l	$75	; Lantern:       117 kims
	dc.l	$910	; Griffin Wing:  2320 kims
	dc.l	$2000	; Alarm Clock:  8192 kims
MalagaItemShopAssortment:
	dc.w	$3
	shopItem ITEM_VASE
	shopItem ITEM_JOKE_BOOK
	shopItem ITEM_SMALL_BOMB
MalagaItemShopPrices:
	dc.l	$10	; Vase:       16 kims
	dc.l	$10	; Joke Book:  16 kims
	dc.l	$10	; Small Bomb: 16 kims
BarrowItemShopAssortment:
	dc.w	$6
	shopItem ITEM_MEDICINE
	shopItem ITEM_LANTERN
	shopItem ITEM_GRIFFIN_WING
	shopItem ITEM_AGATE_JEWEL
	shopItem ITEM_GNOME_STONE
	shopItem ITEM_BANSHEE_POWDER
BarrowItemShopPrices:
	dc.l	$142	; Medicine:       322 kims
	dc.l	$80	; Lantern:        128 kims
	dc.l	$990	; Griffin Wing:  2448 kims
	dc.l	$3200	; Agate Jewel:  12800 kims
	dc.l	$400	; Gnome Stone:   1024 kims
	dc.l	$2200	; Banshee Powder: 8704 kims
HelwigItemShopAssortment:
	dc.w	$6
	shopItem ITEM_MEDICINE
	shopItem ITEM_GRIFFIN_WING
	shopItem ITEM_LANTERN
	shopItem ITEM_AGATE_JEWEL
	shopItem ITEM_GNOME_STONE
	shopItem ITEM_POISON_BALM
HelwigItemShopPrices:
	dc.l	$155	; Medicine:        341 kims
	dc.l	$1020	; Griffin Wing:  2592 kims
	dc.l	$92	; Lantern:         146 kims
	dc.l	$3780	; Agate Jewel:  14208 kims
	dc.l	$420	; Gnome Stone:    1056 kims
	dc.l	$90	; Poison Balm:     144 kims
SwaffhamItemShopAssortment:
	dc.w	$5
	shopItem ITEM_MEDICINE
	shopItem ITEM_POISON_BALM
	shopItem ITEM_LANTERN
	shopItem ITEM_GRIFFIN_WING
	shopItem ITEM_AGATE_JEWEL
SwaffhamItemShopPrices:
	dc.l	$171	; Medicine:        369 kims
	dc.l	$108	; Poison Balm:     264 kims
	dc.l	$102	; Lantern:         258 kims
	dc.l	$1050	; Griffin Wing:  2640 kims
	dc.l	$4120	; Agate Jewel:  16672 kims
HastingsItemShopAssortment:
	dc.w	$5
	shopItem ITEM_MEDICINE
	shopItem ITEM_POISON_BALM
	shopItem ITEM_TOPAZ_JEWEL
	shopItem ITEM_LANTERN
	shopItem ITEM_BANSHEE_POWDER
HastingsItemShopPrices:
	dc.l	$190	; Medicine:          400 kims
	dc.l	$122	; Poison Balm:       290 kims
	dc.l	$9100	; Topaz Jewel:     37120 kims
	dc.l	$115	; Lantern:           277 kims
	dc.l	$3750	; Banshee Powder:  14160 kims
ParmaMagicShopAssortment:
	dc.w	$2
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_FERROS
	shopMagic MAGIC_TYPE_FIELD,  MAGIC_SANGUA
ParmaMagicShopPrices:
	dc.l	$500	; Ferros:   1280 kims
	dc.l	$800	; Sangua:   2048 kims
DeepdaleMagicShopAssortment:
	dc.w	$2
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_VOLTI
	shopMagic MAGIC_TYPE_FIELD,  MAGIC_SANGUA
DeepdaleMagicShopPrices:
	dc.l	$1200	; Volti:    4608 kims
	dc.l	$900	; Sangua:   2304 kims
StowMagicShopAssortment:
	dc.w	$3
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_COPPEROS
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_AERO
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_VOLTI
StowMagicShopPrices:
	dc.l	$3700	; Copperos: 14336 kims
	dc.l	$3200	; Aero:     12800 kims
	dc.l	$1400	; Volti:     5120 kims
KeltwickMagicShopAssortment:
	dc.w	$5
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_AERO
	shopMagic MAGIC_TYPE_FIELD,  MAGIC_LUMINOS
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_HYDRO
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_CHRONO
	shopMagic MAGIC_TYPE_FIELD,  MAGIC_TOXIOS
KeltwickMagicShopPrices:
	dc.l	$3400	; Aero:     13312 kims
	dc.l	$5200	; Luminos:  20992 kims
	dc.l	$4500	; Hydro:    17920 kims
	dc.l	$5700	; Chrono:   22528 kims
	dc.l	$8500	; Toxios:   34048 kims
MalagaMagicShopAssortment:
	dc.w	$5
	shopMagic MAGIC_TYPE_FIELD,  MAGIC_ARIES
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_VOLTIO
	shopMagic MAGIC_TYPE_FIELD,  MAGIC_SANGUIA
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_AERIOS
	shopMagic MAGIC_TYPE_FIELD,  MAGIC_TOXIOS
MalagaMagicShopPrices:
	dc.l	$9000	; Aries:    36864 kims
	dc.l	$11000	; Voltio:   69632 kims
	dc.l	$4800	; Sanguia:  18432 kims
	dc.l	$11700	; Aerios:   71680 kims
	dc.l	$9100	; Toxios:   37120 kims
HelwigMagicShopAssortment:
	dc.w	$5
	shopMagic MAGIC_TYPE_FIELD,  MAGIC_ARIES
	shopMagic MAGIC_TYPE_FIELD,  MAGIC_SANGUIA
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_MERCURIOS
	shopMagic MAGIC_TYPE_FIELD,  MAGIC_INAUDIOS
	shopMagic MAGIC_TYPE_FIELD,  MAGIC_EXTRIOS
HelwigMagicShopPrices:
	dc.l	$12000	; Aries:      73728 kims
	dc.l	$5100	; Sanguia:    20736 kims
	dc.l	$8700	; Mercurios:  35328 kims
	dc.l	$3000	; Inaudios:   12288 kims
	dc.l	$6200	; Extrios:    25088 kims
SwaffhamMagicShopAssortment:
	dc.w	$3
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_HYDRIOS
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_ARGENTOS
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_VOLTIO
SwaffhamMagicShopPrices:
	dc.l	$20000	; Hydrios:   131072 kims
	dc.l	$40000	; Argentos:  262144 kims
	dc.l	$35000	; Voltio:    221184 kims
HastingsMagicShopAssortment:
	dc.w	$4
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_CHRONIOS
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_VOLTIOS
	shopMagic MAGIC_TYPE_FIELD,  MAGIC_SANGUIO
	shopMagic MAGIC_TYPE_BATTLE, MAGIC_TERRAFISSI
HastingsMagicShopPrices:
	dc.l	$20000	; Chronios:    131072 kims
	dc.l	$47000	; Voltios:     290816 kims
	dc.l	$28000	; Sanguio:     163840 kims
	dc.l	$70000	; Terrafissi:  458752 kims
WyclifEquipmentShopAssortment:
	dc.w	$5
	shopEquip EQUIPMENT_TYPE_SWORD,  EQUIPMENT_SWORD_BRONZE
	shopEquip EQUIPMENT_TYPE_SHIELD, EQUIPMENT_SHIELD_LEATHER
	shopEquip EQUIPMENT_TYPE_SHIELD, EQUIPMENT_SHIELD_SMALL
	shopEquip EQUIPMENT_TYPE_ARMOR,  EQUIPMENT_ARMOR_LEATHER
	shopEquip EQUIPMENT_TYPE_ARMOR,  EQUIPMENT_ARMOR_BRONZE
WyclifEquipmentShopPrices:
	dc.l	$100	; Bronze Sword:    256 kims
	dc.l	$50	; Leather Shield:  128 kims
	dc.l	$080	; Small Shield:    128 kims
	dc.l	$200	; Leather Armor:   512 kims
	dc.l	$400	; Bronze Armor:   1024 kims
ParmaEquipmentShopAssortment:
	dc.w	$6
	shopEquip EQUIPMENT_TYPE_SWORD,  EQUIPMENT_SWORD_IRON
	shopEquip EQUIPMENT_TYPE_SWORD,  EQUIPMENT_SWORD_SHARP
	shopEquip EQUIPMENT_TYPE_SHIELD, EQUIPMENT_SHIELD_LARGE
	shopEquip EQUIPMENT_TYPE_SHIELD, EQUIPMENT_SHIELD_SILVER
	shopEquip EQUIPMENT_TYPE_ARMOR,  EQUIPMENT_ARMOR_METAL
	shopEquip EQUIPMENT_TYPE_ARMOR,  EQUIPMENT_ARMOR_SCALE
ParmaEquipmentShopPrices:
	dc.l	$400	; Iron Sword:     1024 kims
	dc.l	$800	; Sharp Sword:    2048 kims
	dc.l	$250	; Large Shield:    640 kims
	dc.l	$500	; Silver Shield:  1280 kims
	dc.l	$900	; Metal Armor:    2304 kims
	dc.l	$1100	; Scale Armor:    4352 kims
DeepdaleEquipmentShopAssortment:
	dc.w	$6
	shopEquip EQUIPMENT_TYPE_SWORD,  EQUIPMENT_SWORD_LONG
	shopEquip EQUIPMENT_TYPE_SWORD,  EQUIPMENT_SWORD_SILVER
	shopEquip EQUIPMENT_TYPE_SHIELD, EQUIPMENT_SHIELD_GOLD
	shopEquip EQUIPMENT_TYPE_SHIELD, EQUIPMENT_SHIELD_PLATINUM
	shopEquip EQUIPMENT_TYPE_ARMOR,  EQUIPMENT_ARMOR_PLATE
	shopEquip EQUIPMENT_TYPE_ARMOR,  EQUIPMENT_ARMOR_CRYSTAL
DeepdaleEquipmentShopPrices:
	dc.l	$1800	; Long Sword:      6144 kims
	dc.l	$3700	; Silver Sword:   14336 kims
	dc.l	$1500	; Gold Shield:     5376 kims
	dc.l	$3200	; Platinum Shield: 12800 kims
	dc.l	$2800	; Plate Armor:     10240 kims
	dc.l	$4500	; Crystal Armor:   17408 kims
MalagaEquipmentShopAssortment:
	dc.w	$5
	shopEquip EQUIPMENT_TYPE_SWORD,  EQUIPMENT_SWORD_PRIME
	shopEquip EQUIPMENT_TYPE_SWORD,  EQUIPMENT_SWORD_GOLDEN
	shopEquip EQUIPMENT_TYPE_SHIELD, EQUIPMENT_SHIELD_DIAMOND
	shopEquip EQUIPMENT_TYPE_ARMOR,  EQUIPMENT_ARMOR_SILVER
	shopEquip EQUIPMENT_TYPE_ARMOR,  EQUIPMENT_ARMOR_KNIGHT
MalagaEquipmentShopPrices:
	dc.l	$5100	; Prime Sword:    20480 kims
	dc.l	$8200	; Golden Sword:   33280 kims
	dc.l	$4100	; Diamond Shield: 16640 kims
	dc.l	$7000	; Silver Armor:   28672 kims
	dc.l	$9200	; Knight Armor:   37376 kims
TadcasterEquipmentShopAssortment:
	dc.w	$5
	shopEquip EQUIPMENT_TYPE_SWORD,  EQUIPMENT_SWORD_DIAMOND
	shopEquip EQUIPMENT_TYPE_SWORD,  EQUIPMENT_SWORD_PLATINUM
	shopEquip EQUIPMENT_TYPE_SHIELD, EQUIPMENT_SHIELD_KNIGHT
	shopEquip EQUIPMENT_TYPE_ARMOR,  EQUIPMENT_ARMOR_GOLD
	shopEquip EQUIPMENT_TYPE_ARMOR,  EQUIPMENT_ARMOR_ULTIMATE
TadcasterEquipmentShopPrices:
	dc.l	$21000	; Diamond Sword:    135168 kims
	dc.l	$14800	; Platinum Sword:    92160 kims
	dc.l	$6300	; Knight Shield:     25344 kims
	dc.l	$15000	; Gold Armor:        86016 kims
	dc.l	$24000	; Ultimate Armor:   147456 kims
SwaffhamEquipmentShopAssortment:
	dc.w	$5
	shopEquip EQUIPMENT_TYPE_SWORD,  EQUIPMENT_SWORD_ULTIMATE
	shopEquip EQUIPMENT_TYPE_SWORD,  EQUIPMENT_SWORD_ROYAL
	shopEquip EQUIPMENT_TYPE_SHIELD, EQUIPMENT_SHIELD_CARMINE1
	shopEquip EQUIPMENT_TYPE_ARMOR,  EQUIPMENT_ARMOR_ODIN
	shopEquip EQUIPMENT_TYPE_ARMOR,  EQUIPMENT_ARMOR_DIAMOND
SwaffhamEquipmentShopPrices:
	dc.l	$42000	; Ultimate Sword:   270336 kims
	dc.l	$34600	; Royal Sword:      215040 kims
	dc.l	$12700	; Carmine Shield:    75776 kims
	dc.l	$38000	; Odin Armor:       245760 kims
	dc.l	$50000	; Diamond Armor:    327680 kims

ItemResaleValueMap:
	dc.l	$8	; ITEM_HERBS ($00):               8 kims
	dc.l	$4	; ITEM_CANDLE ($01):              4 kims
	dc.l	$30	; ITEM_LANTERN ($02):            48 kims
	dc.l	$15	; ITEM_POISON_BALM ($03):        21 kims
	dc.l	$1000	; ITEM_ALARM_CLOCK ($04):      4096 kims
	dc.l	$10000	; ITEM_VASE ($05):            65536 kims
	dc.l	$1100	; ITEM_JOKE_BOOK ($06):        4352 kims
	dc.l	$5	; ITEM_SMALL_BOMB ($07):          5 kims
	dc.l	$0	; ITEM_OLD_WOMANS_SKETCH ($08):   0 kims (quest item)
	dc.l	$0	; ITEM_OLD_MANS_SKETCH ($09):     0 kims (quest item)
	dc.l	$0	; ITEM_PASS_TO_CARTHAHENA ($0A):  0 kims (quest item)
	dc.l	$0	; ITEM_TRUFFLE ($0B):             0 kims (quest item)
	dc.l	$0	; ITEM_DIGOT_PLANT ($0C):         0 kims (quest item)
	dc.l	$0	; ITEM_TREASURE_OF_TROY ($0D):    0 kims (quest item)
	dc.l	$0	; ITEM_WHITE_CRYSTAL ($0E):       0 kims (quest item)
	dc.l	$0	; ITEM_RED_CRYSTAL ($0F):         0 kims (quest item)
	dc.l	$0	; ITEM_BLUE_CRYSTAL ($10):        0 kims (quest item)
	dc.l	$0	; ITEM_WHITE_KEY ($11):           0 kims (quest item)
	dc.l	$0	; ITEM_RED_KEY ($12):             0 kims (quest item)
	dc.l	$0	; ITEM_BLUE_KEY ($13):            0 kims (quest item)
	dc.l	$0	; ITEM_CROWN ($14):               0 kims (quest item)
	dc.l	$0	; ITEM_SIXTEEN_RINGS ($15):       0 kims (quest item)
	dc.l	$0	; ITEM_BRONZE_KEY ($16):          0 kims (quest item)
	dc.l	$0	; ITEM_SILVER_KEY ($17):          0 kims (quest item)
	dc.l	$0	; ITEM_GOLD_KEY ($18):            0 kims (quest item)
	dc.l	$0	; ITEM_THULE_KEY ($19):           0 kims (quest item)
	dc.l	$380	; ITEM_SECRET_KEY ($1A):        896 kims
	dc.l	$50	; ITEM_MEDICINE ($1B):           80 kims
	dc.l	$1200	; ITEM_AGATE_JEWEL ($1C):      4608 kims
	dc.l	$400	; ITEM_GRIFFIN_WING ($1D):     1024 kims
	dc.l	$13000	; ITEM_TITANIAS_MIRROR ($1E): 77824 kims
	dc.l	$124	; ITEM_GNOME_STONE ($1F):       292 kims
	dc.l	$4200	; ITEM_TOPAZ_JEWEL ($20):    16896 kims
	dc.l	$1230	; ITEM_BANSHEE_POWDER ($21):   4656 kims
	dc.l	$20000	; ITEM_RAFAELS_STICK ($22):  131072 kims
	dc.l	$50000	; ITEM_MIRROR_OF_ATLAS ($23): 327680 kims
	dc.l	$2950	; ITEM_RUBY_BROOCH ($24):    11584 kims
	dc.l	$1000	; ITEM_DUNGEON_KEY ($25):     4096 kims
	dc.l	$2000	; ITEM_KULMS_VASE ($26):      8192 kims
	dc.l	$1000	; ITEM_KASANS_CHISEL ($27):   4096 kims
	dc.l	$2000	; ITEM_BOOK_OF_KIEL ($28):    8192 kims
	dc.l	$700	; ITEM_DANEGELD_WATER ($29):  1792 kims
	dc.l	$3000	; ITEM_MINERAL_BAR ($2A):    12288 kims
	dc.l	$3000	; ITEM_MEGA_BLAST ($2B):     12288 kims

EquipmentResaleValueMap:
	dc.l	$30	; EQUIPMENT_SWORD_BRONZE ($00):     48 kims
	dc.l	$150	; EQUIPMENT_SWORD_IRON ($01):      336 kims
	dc.l	$350	; EQUIPMENT_SWORD_SHARP ($02):     848 kims
	dc.l	$800	; EQUIPMENT_SWORD_LONG ($03):     2048 kims
	dc.l	$2000	; EQUIPMENT_SWORD_SILVER ($04):   8192 kims
	dc.l	$2000	; EQUIPMENT_SWORD_PRIME ($05):    8192 kims
	dc.l	$7000	; EQUIPMENT_SWORD_GOLDEN ($06):  28672 kims
	dc.l	$197	; EQUIPMENT_SWORD_MIRAGE ($07):    407 kims
	dc.l	$12000	; EQUIPMENT_SWORD_PLATINUM ($08): 73728 kims
	dc.l	$18000	; EQUIPMENT_SWORD_DIAMOND ($09): 98304 kims
	dc.l	$1397	; EQUIPMENT_SWORD_GRAPHITE ($0A):  5271 kims
	dc.l	$10000	; EQUIPMENT_SWORD_ROYAL ($0B):   65536 kims
	dc.l	$20000	; EQUIPMENT_SWORD_ULTIMATE ($0C): 131072 kims
	dc.l	$1	; EQUIPMENT_SWORD_OF_VERMILION ($0D): 1 kim
	dc.l	$3	; EQUIPMENT_SWORD_DARK1 ($0E):        3 kims
	dc.l	$40000	; EQUIPMENT_SWORD_DEATH ($0F):   262144 kims
	dc.l	$53	; EQUIPMENT_SWORD_BARBARIAN ($10):   83 kims
	dc.l	$9200	; EQUIPMENT_SWORD_CRITICAL ($11): 37376 kims
	dc.l	$0	; EQUIPMENT_SWORD_DARK2 ($12):        0 kims
	dc.l	$0	; EQUIPMENT_SWORD_DARK3 ($13):        0 kims
	dc.l	$20	; EQUIPMENT_SHIELD_LEATHER ($14):    32 kims
	dc.l	$30	; EQUIPMENT_SHIELD_SMALL ($15):      48 kims
	dc.l	$100	; EQUIPMENT_SHIELD_LARGE ($16):     256 kims
	dc.l	$230	; EQUIPMENT_SHIELD_SILVER ($17):    560 kims
	dc.l	$800	; EQUIPMENT_SHIELD_GOLD ($18):     2048 kims
	dc.l	$2500	; EQUIPMENT_SHIELD_PLATINUM ($19): 9472 kims
	dc.l	$13	; EQUIPMENT_SHIELD_GEM ($1A):        19 kims
	dc.l	$2000	; EQUIPMENT_SHIELD_SAPPHIRE ($1B): 8192 kims
	dc.l	$3500	; EQUIPMENT_SHIELD_DIAMOND ($1C): 13568 kims
	dc.l	$992	; EQUIPMENT_SHIELD_DRAGON ($1D):   2450 kims
	dc.l	$372	; EQUIPMENT_SHIELD_MAGIC ($1E):     882 kims
	dc.l	$682	; EQUIPMENT_SHIELD_PHANTOM ($1F):  1666 kims
	dc.l	$724	; EQUIPMENT_SHIELD_GRIZZLY ($20):  1828 kims
	dc.l	$5000	; EQUIPMENT_SHIELD_CARMINE1 ($21): 20480 kims
	dc.l	$401	; EQUIPMENT_SHIELD_ROYAL ($22):    1025 kims
	dc.l	$1050	; EQUIPMENT_SHIELD_POISON ($23):   4176 kims
	dc.l	$3000	; EQUIPMENT_SHIELD_KNIGHT ($24):  12288 kims
	dc.l	$0	; EQUIPMENT_SHIELD_CARMINE2 ($25):    0 kims
	dc.l	$0	; EQUIPMENT_SHIELD_CARMINE3 ($26):    0 kims
	dc.l	$0	; EQUIPMENT_SHIELD_CARMINE4 ($27):    0 kims
	dc.l	$80	; EQUIPMENT_ARMOR_LEATHER ($28):    128 kims
	dc.l	$170	; EQUIPMENT_ARMOR_BRONZE ($29):     368 kims
	dc.l	$300	; EQUIPMENT_ARMOR_METAL ($2A):      768 kims
	dc.l	$450	; EQUIPMENT_ARMOR_SCALE ($2B):     1104 kims
	dc.l	$1030	; EQUIPMENT_ARMOR_PLATE ($2C):     4144 kims
	dc.l	$5000	; EQUIPMENT_ARMOR_SILVER ($2D):   20480 kims
	dc.l	$12000	; EQUIPMENT_ARMOR_GOLD ($2E):     73728 kims
	dc.l	$1800	; EQUIPMENT_ARMOR_CRYSTAL ($2F):   6144 kims
	dc.l	$7000	; EQUIPMENT_ARMOR_EMERALD ($30):  28672 kims
	dc.l	$40000	; EQUIPMENT_ARMOR_DIAMOND ($31):  262144 kims
	dc.l	$223	; EQUIPMENT_ARMOR_KNIGHT ($32):      547 kims
	dc.l	$2000	; EQUIPMENT_ARMOR_ULTIMATE ($33):  8192 kims
	dc.l	$15000	; EQUIPMENT_ARMOR_ODIN ($34):     86016 kims
	dc.l	$20000	; EQUIPMENT_ARMOR_SECRET ($35):   131072 kims
	dc.l	$510	; EQUIPMENT_ARMOR_SKELETON ($36):   1296 kims
	dc.l	$2	; EQUIPMENT_ARMOR_CRIMSON ($37):       2 kims
	dc.l	$30000	; EQUIPMENT_ARMOR_OLD_NICK ($38): 196608 kims

MagicResaleValueMap:
	dc.l	$1500	; MAGIC_AERO ($00):          5376 kims
	dc.l	$5500	; MAGIC_AERIOS ($01):       21504 kims
	dc.l	$520	; MAGIC_VOLTI ($02):         1312 kims
	dc.l	$5400	; MAGIC_VOLTIO ($03):       21504 kims
	dc.l	$23000	; MAGIC_VOLTIOS ($04):     143360 kims
	dc.l	$200	; MAGIC_FERROS ($05):          512 kims
	dc.l	$1400	; MAGIC_COPPEROS ($06):      5120 kims
	dc.l	$4300	; MAGIC_MERCURIOS ($07):    17152 kims
	dc.l	$2000	; MAGIC_ARGENTOS ($08):      8192 kims (NOTE: sell < buy price of 40000)
	dc.l	$2300	; MAGIC_HYDRO ($09):         8960 kims
	dc.l	$9900	; MAGIC_HYDRIOS ($0A):      39936 kims
	dc.l	$2650	; MAGIC_CHRONO ($0B):       10496 kims
	dc.l	$8000	; MAGIC_CHRONIOS ($0C):     32768 kims
	dc.l	$25000	; MAGIC_TERRAFISSI ($0D):  151552 kims
	dc.l	$4400	; MAGIC_ARIES ($0E):        17408 kims
	dc.l	$3000	; MAGIC_EXTRIOS ($0F):      12288 kims
	dc.l	$2000	; MAGIC_INAUDIOS ($10):      8192 kims
	dc.l	$2600	; MAGIC_LUMINOS ($11):      10240 kims
	dc.l	$300	; MAGIC_SANGUA ($12):          768 kims
	dc.l	$2100	; MAGIC_SANGUIA ($13):       8448 kims
	dc.l	$14500	; MAGIC_SANGUIO ($14):      91136 kims
	dc.l	$4400	; MAGIC_TOXIOS ($15):        17408 kims
	dc.l	$0	; MAGIC_SANGUIOS ($16):            0 kims
MagicMpConsumptionMap:
	dc.w	$3	; MAGIC_AERO ($00):        3 MP
	dc.w	$9	; MAGIC_AERIOS ($01):      9 MP
	dc.w	$2	; MAGIC_VOLTI ($02):       2 MP
	dc.w	$C	; MAGIC_VOLTIO ($03):     12 MP
	dc.w	$10	; MAGIC_VOLTIOS ($04):   16 MP
	dc.w	$1	; MAGIC_FERROS ($05):      1 MP
	dc.w	$4	; MAGIC_COPPEROS ($06):    4 MP
	dc.w	$7	; MAGIC_MERCURIOS ($07):   7 MP
	dc.w	$A	; MAGIC_ARGENTOS ($08):   10 MP
	dc.w	$4	; MAGIC_HYDRO ($09):       4 MP
	dc.w	$8	; MAGIC_HYDRIOS ($0A):     8 MP
	dc.w	$5	; MAGIC_CHRONO ($0B):      5 MP
	dc.w	$A	; MAGIC_CHRONIOS ($0C):   10 MP
	dc.w	$19	; MAGIC_TERRAFISSI ($0D): 25 MP
	dc.w	$D	; MAGIC_ARIES ($0E):      13 MP
	dc.w	$5	; MAGIC_EXTRIOS ($0F):     5 MP
	dc.w	$8	; MAGIC_INAUDIOS ($10):    8 MP
	dc.w	$5	; MAGIC_LUMINOS ($11):     5 MP
	dc.w	$6	; MAGIC_SANGUA ($12):      6 MP
	dc.w	$C	; MAGIC_SANGUIA ($13):    12 MP
	dc.w	$1F	; MAGIC_SANGUIO ($14):   31 MP
	dc.w	$6	; MAGIC_TOXIOS ($15):      6 MP
	dc.w	$2	; MAGIC_SANGUIOS ($16):    2 MP
MagicBaseDamageTable: ; Per battle magic: (tier, base_damage) pairs
; Indexed by battle magic ID (AERO=0, AERIOS=1, VOLTI=2 ... TERRAFISSI=$0D)
	dc.b	$04, $B0	; MAGIC_AERO ($00):       tier=$04 base=$B0 (176)
	dc.b	$06, $A4	; MAGIC_AERIOS ($01):     tier=$06 base=$A4 (164)
	dc.b	$03, $57	; MAGIC_VOLTI ($02):      tier=$03 base=$57 (87)
	dc.b	$00, $32	; MAGIC_VOLTIO ($03):     tier=$00 base=$32 (50)
	dc.b	$0F, $1E	; MAGIC_VOLTIOS ($04):    tier=$0F base=$1E (30)
	dc.b	$02, $64	; MAGIC_FERROS ($05):     tier=$02 base=$64 (100)
	dc.b	$00, $50	; MAGIC_COPPEROS ($06):   tier=$00 base=$50 (80)
	dc.b	$01, $B6	; MAGIC_MERCURIOS ($07):  tier=$01 base=$B6 (182)
	dc.b	$00, $1E	; MAGIC_ARGENTOS ($08):   tier=$00 base=$1E (30)
	dc.b	$00, $A0	; MAGIC_HYDRO ($09):      tier=$00 base=$A0 (160)
	dc.b	$01, $4A	; MAGIC_HYDRIOS ($0A):    tier=$01 base=$4A (74)
	dc.b	$00, $00	; MAGIC_CHRONO ($0B):     tier=$00 base=$00 (status)
	dc.b	$00, $00	; MAGIC_TERRAFISSI ($0D): tier=$00 base=$00 (status)
	dc.w	$0050
MagicElementTypeTable: ; Something indexed by battle magic
	dc.b	$00, $00, $02, $02, $02, $03, $03, $03, $03, $01, $01, $00, $00, $00
ShopCategoryNameTables:
	dc.l	ItemNames
	dc.l	Possessed_items_length
	dc.l	EquipmentNames
	dc.l	Possessed_equipment_length
	dc.l	MagicNames
	dc.l	Possessed_magics_length
	dc.l	MagicNames	
	dc.l	Possessed_magics_length	
	dc.l	NULL_PTR	
	dc.l	NULL_PTR	