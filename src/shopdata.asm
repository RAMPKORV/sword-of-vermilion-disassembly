; ===========================================================================
; Shop & Economy Data
; Inn/church prices, shop assortments, item prices, magic cost/element tables
; ===========================================================================
;loc_00021F08:
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

;loc_00021F40:
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

;loc_00021F78:
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

;loc_00021FB0:
ShopAssortmentByTownAndShopType:
	dc.l	WyclifItemShopAssortment
	dc.l	WyclifEquipmentShopAssortment
	dc.l	ParmaMagicShopAssortment	
	dc.l	ParmaMagicShopAssortment	
	dc.l	ParmaItemShopAssortment
	dc.l	ParmaEquipmentShopAssortment
	dc.l	ParmaMagicShopAssortment
	dc.l	ParmaMagicShopAssortment	
	dc.l	DeepdaleItemShopAssortment	
	dc.l	DeepdaleEquipmentShopAssortment	
	dc.l	DeepdaleMagicShopAssortment	
	dc.l	ParmaMagicShopAssortment	
	dc.l	DeepdaleItemShopAssortment
	dc.l	DeepdaleEquipmentShopAssortment
	dc.l	DeepdaleMagicShopAssortment
	dc.l	ParmaMagicShopAssortment	
	dc.l	StowItemShopAssortment
	dc.l	MalagaEquipmentShopAssortment	
	dc.l	StowMagicShopAssortment
	dc.l	ParmaMagicShopAssortment	
	dc.l	KeltwickItemShopAssortment	
	dc.l	MalagaEquipmentShopAssortment	
	dc.l	KeltwickMagicShopAssortment	
	dc.l	ParmaMagicShopAssortment	
	dc.l	KeltwickItemShopAssortment
	dc.l	MalagaEquipmentShopAssortment	
	dc.l	KeltwickMagicShopAssortment
	dc.l	ParmaMagicShopAssortment	
	dc.l	MalagaItemShopAssortment
	dc.l	MalagaEquipmentShopAssortment
	dc.l	MalagaMagicShopAssortment
	dc.l	ParmaMagicShopAssortment	
	dc.l	BarrowItemShopAssortment
	dc.l	TadcasterEquipmentShopAssortment	
	dc.l	HelwigMagicShopAssortment	
	dc.l	ParmaMagicShopAssortment	
	dc.l	HelwigItemShopAssortment	
	dc.l	TadcasterEquipmentShopAssortment
	dc.l	HelwigMagicShopAssortment	
	dc.l	ParmaMagicShopAssortment	
	dc.l	HelwigItemShopAssortment
	dc.l	SwaffhamEquipmentShopAssortment	
	dc.l	HelwigMagicShopAssortment
	dc.l	ParmaMagicShopAssortment	
	dc.l	SwaffhamItemShopAssortment
	dc.l	SwaffhamEquipmentShopAssortment
	dc.l	SwaffhamMagicShopAssortment
	dc.l	ParmaMagicShopAssortment	
	dc.l	HastingsItemShopAssortment	
	dc.l	SwaffhamEquipmentShopAssortment	
	dc.l	HastingsMagicShopAssortment	
	dc.l	ParmaMagicShopAssortment	
	dc.l	HastingsItemShopAssortment
	dc.l	SwaffhamEquipmentShopAssortment	
	dc.l	HastingsMagicShopAssortment
	dc.l	ParmaMagicShopAssortment	
	dc.l	ParmaMagicShopAssortment	
	dc.l	SwaffhamEquipmentShopAssortment	
	dc.l	HastingsMagicShopAssortment	
	dc.l	ParmaMagicShopAssortment	
	dc.l	ParmaMagicShopAssortment	
	dc.l	SwaffhamEquipmentShopAssortment	
	dc.l	HastingsMagicShopAssortment	
	dc.l	ParmaMagicShopAssortment	

;loc_000220B0:
ShopPricesByTownAndType:
	dc.l	WyclifItemShopPrices
	dc.l	WyclifEquipmentShopPrices
	dc.l	ParmaMagicShopPrices	
	dc.l	ParmaMagicShopPrices	
	dc.l	ParmaItemShopPrices
	dc.l	ParmaEquipmentShopPrices
	dc.l	ParmaMagicShopPrices
	dc.l	ParmaMagicShopPrices	
	dc.l	DeepdaleItemShopPrices	
	dc.l	DeepdaleEquipmentShopPrices	
	dc.l	DeepdaleMagicShopPrices	
	dc.l	ParmaMagicShopPrices	
	dc.l	DeepdaleItemShopPrices
	dc.l	DeepdaleEquipmentShopPrices
	dc.l	DeepdaleMagicShopPrices
	dc.l	ParmaMagicShopPrices	
	dc.l	StowItemShopPrices
	dc.l	MalagaEquipmentShopPrices	
	dc.l	StowMagicShopPrices
	dc.l	ParmaMagicShopPrices	
	dc.l	KeltwickItemShopPrices	
	dc.l	MalagaEquipmentShopPrices	
	dc.l	KeltwickMagicShopPrices	
	dc.l	ParmaMagicShopPrices	
	dc.l	KeltwickItemShopPrices
	dc.l	MalagaEquipmentShopPrices	
	dc.l	KeltwickMagicShopPrices
	dc.l	ParmaMagicShopPrices	
	dc.l	MalagaItemShopPrices	
	dc.l	MalagaEquipmentShopPrices
	dc.l	MalagaMagicShopPrices
	dc.l	ParmaMagicShopPrices	
	dc.l	BarrowItemShopPrices
	dc.l	TadcasterEquipmentShopPrices	
	dc.l	HelwigMagicShopPrices	
	dc.l	ParmaMagicShopPrices	
	dc.l	HelwigItemShopPrices	
	dc.l	TadcasterEquipmentShopPrices
	dc.l	HelwigMagicShopPrices	
	dc.l	ParmaMagicShopPrices	
	dc.l	HelwigItemShopPrices
	dc.l	SwaffhamEquipmentShopPrices	
	dc.l	HelwigMagicShopPrices
	dc.l	ParmaMagicShopPrices	
	dc.l	SwaffhamItemShopPrices
	dc.l	SwaffhamEquipmentShopPrices
	dc.l	SwaffhamMagicShopPrices
	dc.l	ParmaMagicShopPrices	
	dc.l	HastingsItemShopPrices	
	dc.l	SwaffhamEquipmentShopPrices	
	dc.l	HastingsMagicShopPrices	
	dc.l	ParmaMagicShopPrices	
	dc.l	HastingsItemShopPrices
	dc.l	SwaffhamEquipmentShopPrices	
	dc.l	HastingsMagicShopPrices
	dc.l	ParmaMagicShopPrices	
	dc.l	ParmaMagicShopAssortment	
	dc.l	SwaffhamEquipmentShopPrices	
	dc.l	HastingsMagicShopPrices	
	dc.l	ParmaMagicShopPrices	
	dc.l	ParmaMagicShopAssortment	
	dc.l	SwaffhamEquipmentShopPrices	
	dc.l	HastingsMagicShopPrices	
	dc.l	ParmaMagicShopPrices	
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
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_HERBS
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_CANDLE
WyclifItemShopPrices:
	dc.l	$20
	dc.l	$10 
ParmaItemShopAssortment:
	dc.w	$5
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_CANDLE
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_HERBS
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_POISON_BALM
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_LANTERN
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_GNOME_STONE
ParmaItemShopPrices:
	dc.l	$15
	dc.l	$25
	dc.l	$40
	dc.l	$65
	dc.l	$300
DeepdaleItemShopAssortment:
	dc.w	$5
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_HERBS
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_MEDICINE
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_POISON_BALM
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_LANTERN
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_GNOME_STONE
DeepdaleItemShopPrices:
	dc.l	$30
	dc.l	$120
	dc.l	$60
	dc.l	$70
	dc.l	$350 
StowItemShopAssortment:
	dc.w	$6
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_HERBS
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_MEDICINE
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_POISON_BALM
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_LANTERN
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_GNOME_STONE
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_GRIFFIN_WING
StowItemShopPrices:
	dc.l	$30
	dc.l	$125
	dc.l	$65
	dc.l	$70
	dc.l	$375
	dc.l	$820 
KeltwickItemShopAssortment:
	dc.w	$5
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_MEDICINE
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_POISON_BALM
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_LANTERN
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_GRIFFIN_WING
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_ALARM_CLOCK 
KeltwickItemShopPrices:
	dc.l	$130
	dc.l	$70
	dc.l	$75
	dc.l	$910
	dc.l	$2000 
MalagaItemShopAssortment:
	dc.w	$3
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_VASE
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_JOKE_BOOK
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_SMALL_BOMB
MalagaItemShopPrices:
	dc.l	$10
	dc.l	$10
	dc.l	$10 
BarrowItemShopAssortment:
	dc.w	$6
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_MEDICINE
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_LANTERN
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_GRIFFIN_WING
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_AGATE_JEWEL
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_GNOME_STONE
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_BANSHEE_POWDER
BarrowItemShopPrices:
	dc.l	$142
	dc.l	$80
	dc.l	$990
	dc.l	$3200
	dc.l	$400
	dc.l	$2200 
HelwigItemShopAssortment:
	dc.w	$6
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_MEDICINE
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_GRIFFIN_WING
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_LANTERN
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_AGATE_JEWEL
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_GNOME_STONE
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_POISON_BALM
HelwigItemShopPrices:
	dc.l	$155
	dc.l	$1020
	dc.l	$92
	dc.l	$3780
	dc.l	$420
	dc.l	$90 
SwaffhamItemShopAssortment:
	dc.w	$5
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_MEDICINE
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_POISON_BALM
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_LANTERN
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_GRIFFIN_WING
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_AGATE_JEWEL 
SwaffhamItemShopPrices:
	dc.l	$171
	dc.l	$108
	dc.l	$102
	dc.l	$1050
	dc.l	$4120 
HastingsItemShopAssortment:
	dc.w	$5
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_MEDICINE
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_POISON_BALM
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_TOPAZ_JEWEL
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_LANTERN
	dc.b	ITEM_TYPE_DISCARDABLE, ITEM_BANSHEE_POWDER
HastingsItemShopPrices:
	dc.l	$190
	dc.l	$122
	dc.l	$9100
	dc.l	$115
	dc.l	$3750 
ParmaMagicShopAssortment: 
	dc.w	$2
	dc.b	MAGIC_TYPE_BATTLE, 	MAGIC_FERROS
	dc.b	MAGIC_TYPE_FIELD, 	MAGIC_SANGUA 
ParmaMagicShopPrices:
	dc.l	$500
	dc.l	$800 
DeepdaleMagicShopAssortment:
	dc.w	$2
	dc.b	MAGIC_TYPE_BATTLE, 	MAGIC_VOLTI
	dc.b	MAGIC_TYPE_FIELD,	MAGIC_SANGUA
DeepdaleMagicShopPrices:
	dc.l	$1200
	dc.l	$900 
StowMagicShopAssortment:
	dc.w	$3
	dc.b	MAGIC_TYPE_BATTLE, MAGIC_COPPEROS
	dc.b	MAGIC_TYPE_BATTLE, MAGIC_AERO
	dc.b	MAGIC_TYPE_BATTLE, MAGIC_VOLTI
StowMagicShopPrices:
	dc.l	$3700
	dc.l	$3200
	dc.l	$1400 
KeltwickMagicShopAssortment:
	dc.w	$5
	dc.b	MAGIC_TYPE_BATTLE, MAGIC_AERO
	dc.b	MAGIC_TYPE_FIELD, MAGIC_LUMINOS
	dc.b	MAGIC_TYPE_BATTLE, MAGIC_HYDRO
	dc.b	MAGIC_TYPE_BATTLE, MAGIC_CHRONO
	dc.b	MAGIC_TYPE_FIELD, MAGIC_TOXIOS 
KeltwickMagicShopPrices:
	dc.l	$3400
	dc.l	$5200
	dc.l	$4500
	dc.l	$5700
	dc.l	$8500 
MalagaMagicShopAssortment:
	dc.w	$5
	dc.b	MAGIC_TYPE_FIELD, 	MAGIC_ARIES
	dc.b	MAGIC_TYPE_BATTLE, 	MAGIC_VOLTIO
	dc.b	MAGIC_TYPE_FIELD, 	MAGIC_SANGUIA
	dc.b	MAGIC_TYPE_BATTLE, 	MAGIC_AERIOS
	dc.b	MAGIC_TYPE_FIELD, 	MAGIC_TOXIOS
MalagaMagicShopPrices:
	dc.l	$9000
	dc.l	$11000
	dc.l	$4800
	dc.l	$11700
	dc.l	$9100 
HelwigMagicShopAssortment:
	dc.w	$5
	dc.b	MAGIC_TYPE_FIELD, 	MAGIC_ARIES
	dc.b	MAGIC_TYPE_FIELD, 	MAGIC_SANGUIA
	dc.b	MAGIC_TYPE_BATTLE, 	MAGIC_MERCURIOS
	dc.b	MAGIC_TYPE_FIELD, 	MAGIC_INAUDIOS
	dc.b	MAGIC_TYPE_FIELD, 	MAGIC_EXTRIOS
HelwigMagicShopPrices:
	dc.l	$12000
	dc.l	$5100
	dc.l	$8700
	dc.l	$3000
	dc.l	$6200 
SwaffhamMagicShopAssortment:
	dc.w	$3
	dc.b	MAGIC_TYPE_BATTLE, MAGIC_HYDRIOS
	dc.b	MAGIC_TYPE_BATTLE, MAGIC_ARGENTOS
	dc.b	MAGIC_TYPE_BATTLE, MAGIC_VOLTIO 
SwaffhamMagicShopPrices:
	dc.l	$20000
	dc.l	$40000
	dc.l	$35000 
HastingsMagicShopAssortment:
	dc.w	$4
	dc.b	MAGIC_TYPE_BATTLE, 	MAGIC_CHRONIOS
	dc.b	MAGIC_TYPE_BATTLE, 	MAGIC_VOLTIOS
	dc.b	MAGIC_TYPE_FIELD, 	MAGIC_SANGUIO
	dc.b	MAGIC_TYPE_BATTLE, 	MAGIC_TERRAFISSI 
HastingsMagicShopPrices:
	dc.l	$20000 
	dc.l	$47000 
	dc.l	$28000 
	dc.l	$70000 
WyclifEquipmentShopAssortment:
	dc.w	$5
	dc.b	EQUIPMENT_TYPE_SWORD, 	EQUIPMENT_SWORD_BRONZE
	dc.b	EQUIPMENT_TYPE_SHIELD, 	EQUIPMENT_SHIELD_LEATHER
	dc.b	EQUIPMENT_TYPE_SHIELD, 	EQUIPMENT_SHIELD_SMALL
	dc.b	EQUIPMENT_TYPE_ARMOR, 	EQUIPMENT_ARMOR_LEATHER
	dc.b	EQUIPMENT_TYPE_ARMOR, 	EQUIPMENT_ARMOR_BRONZE
WyclifEquipmentShopPrices:
	dc.l	$100
	dc.l	$50
	dc.l	$080
	dc.l	$200
	dc.l	$400
ParmaEquipmentShopAssortment:
	dc.w	$6
	dc.b	EQUIPMENT_TYPE_SWORD, 	EQUIPMENT_SWORD_IRON
	dc.b	EQUIPMENT_TYPE_SWORD, 	EQUIPMENT_SWORD_SHARP
	dc.b	EQUIPMENT_TYPE_SHIELD, 	EQUIPMENT_SHIELD_LARGE
	dc.b	EQUIPMENT_TYPE_SHIELD, 	EQUIPMENT_SHIELD_SILVER
	dc.b	EQUIPMENT_TYPE_ARMOR, 	EQUIPMENT_ARMOR_METAL
	dc.b	EQUIPMENT_TYPE_ARMOR, 	EQUIPMENT_ARMOR_SCALE
ParmaEquipmentShopPrices:
	dc.l	$400 
	dc.l	$800 
	dc.l	$250 
	dc.l	$500 
	dc.l	$900 
	dc.l	$1100 
DeepdaleEquipmentShopAssortment:
	dc.w	$6
	dc.b	EQUIPMENT_TYPE_SWORD, 	EQUIPMENT_SWORD_LONG
	dc.b	EQUIPMENT_TYPE_SWORD, 	EQUIPMENT_SWORD_SILVER
	dc.b	EQUIPMENT_TYPE_SHIELD, 	EQUIPMENT_SHIELD_GOLD
	dc.b	EQUIPMENT_TYPE_SHIELD, 	EQUIPMENT_SHIELD_PLATINUM
	dc.b	EQUIPMENT_TYPE_ARMOR, 	EQUIPMENT_ARMOR_PLATE
	dc.b	EQUIPMENT_TYPE_ARMOR, 	EQUIPMENT_ARMOR_CRYSTAL
DeepdaleEquipmentShopPrices:
	dc.l	$1800 
	dc.l	$3700 
	dc.l	$1500 
	dc.l	$3200 
	dc.l	$2800 
	dc.l	$4500 
MalagaEquipmentShopAssortment: 
	dc.w	$5
	dc.b	EQUIPMENT_TYPE_SWORD, 	EQUIPMENT_SWORD_PRIME
	dc.b	EQUIPMENT_TYPE_SWORD, 	EQUIPMENT_SWORD_GOLDEN
	dc.b	EQUIPMENT_TYPE_SHIELD, 	EQUIPMENT_SHIELD_DIAMOND
	dc.b	EQUIPMENT_TYPE_ARMOR, 	EQUIPMENT_ARMOR_SILVER
	dc.b	EQUIPMENT_TYPE_ARMOR, 	EQUIPMENT_ARMOR_KNIGHT
MalagaEquipmentShopPrices:
	dc.l	$5100
	dc.l	$8200
	dc.l	$4100
	dc.l	$7000
	dc.l	$9200
TadcasterEquipmentShopAssortment:
	dc.w	$5
	dc.b	EQUIPMENT_TYPE_SWORD, 	EQUIPMENT_SWORD_DIAMOND
	dc.b	EQUIPMENT_TYPE_SWORD, 	EQUIPMENT_SWORD_PLATINUM
	dc.b	EQUIPMENT_TYPE_SHIELD, 	EQUIPMENT_SHIELD_KNIGHT
	dc.b	EQUIPMENT_TYPE_ARMOR, 	EQUIPMENT_ARMOR_GOLD
	dc.b	EQUIPMENT_TYPE_ARMOR, 	EQUIPMENT_ARMOR_ULTIMATE
TadcasterEquipmentShopPrices: ; Tadcaster equipment store prices
	dc.l	$21000
	dc.l	$14800
	dc.l	$6300
	dc.l	$15000
	dc.l	$24000
SwaffhamEquipmentShopAssortment:
	dc.w	$5
	dc.b	EQUIPMENT_TYPE_SWORD, 	EQUIPMENT_SWORD_ULTIMATE 
	dc.b	EQUIPMENT_TYPE_SWORD, 	EQUIPMENT_SWORD_ROYAL
	dc.b	EQUIPMENT_TYPE_SHIELD, 	EQUIPMENT_SHIELD_CARMINE1
	dc.b	EQUIPMENT_TYPE_ARMOR, 	EQUIPMENT_ARMOR_ODIN
	dc.b	EQUIPMENT_TYPE_ARMOR, 	EQUIPMENT_ARMOR_DIAMOND 
SwaffhamEquipmentShopPrices:
	dc.l	$42000 
	dc.l	$34600 
	dc.l	$12700 
	dc.l	$38000 
	dc.l	$50000 

ItemResaleValueMap:
	dc.l	$8
	dc.l	$4
	dc.l	$30
	dc.l	$15
	dc.l	$1000
	dc.l	$10000
	dc.l	$1100
	dc.l	$5
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$0 
	dc.l	$380 
	dc.l	$50 
	dc.l	$1200 
	dc.l	$400 
	dc.l	$13000 
	dc.l	$124 
	dc.l	$4200 
	dc.l	$1230 
	dc.l	$20000 
	dc.l	$50000 
	dc.l	$2950 
	dc.l	$1000 
	dc.l	$2000 
	dc.l	$1000 
	dc.l	$2000 
	dc.l	$700 
	dc.l	$3000 
	dc.l	$3000 

EquipmentResaleValueMap:
	dc.l	$30
	dc.l	$150
	dc.l	$350
	dc.l	$800
	dc.l	$2000
	dc.l	$2000 
	dc.l	$7000
	dc.l	$197
	dc.l	$12000 
	dc.l	$18000
	dc.l	$1397
	dc.l	$10000
	dc.l	$20000 
	dc.l	$1
	dc.l	$3
	dc.l	$40000 
	dc.l	$53
	dc.l	$9200
	dc.l	$0
	dc.l	$0
	dc.l	$20 
	dc.l	$30
	dc.l	$100 
	dc.l	$230
	dc.l	$800 
	dc.l	$2500
	dc.l	$13
	dc.l	$2000 
	dc.l	$3500
	dc.l	$992
	dc.l	$372
	dc.l	$682
	dc.l	$724 
	dc.l	$5000
	dc.l	$401 
	dc.l	$1050
	dc.l	$3000
	dc.l	$0
	dc.l	$0
	dc.l	$0
	dc.l	$80 
	dc.l	$170
	dc.l	$300 
	dc.l	$450
	dc.l	$1030
	dc.l	$5000
	dc.l	$12000
	dc.l	$1800
	dc.l	$7000 
	dc.l	$40000
	dc.l	$223 
	dc.l	$2000
	dc.l	$15000 
	dc.l	$20000
	dc.l	$510 
	dc.l	$2
	dc.l	$30000 

;loc_00022622:
MagicResaleValueMap:
	dc.l	$1500
	dc.l	$5500
	dc.l	$520
	dc.l	$5400
	dc.l	$23000
	dc.l	$200
	dc.l	$1400
	dc.l	$4300 
	dc.l	$2000 
	dc.l	$2300
	dc.l	$9900 
	dc.l	$2650
	dc.l	$8000
	dc.l	$25000 
	dc.l	$4400
	dc.l	$3000 
	dc.l	$2000 
	dc.l	$2600 
	dc.l	$300 
	dc.l	$2100
	dc.l	$14500 
	dc.l	$4400
	dc.l	$0
;loc_0002267E:
MagicMpConsumptionMap:
	dc.w	$3
	dc.w	$9
	dc.w	$2
	dc.w	$C
	dc.w	$10
	dc.w	$1
	dc.w	$4
	dc.w	$7
	dc.w	$A
	dc.w	$4
	dc.w	$8
	dc.w	$5
	dc.w	$A
	dc.w	$19
	dc.w	$D
	dc.w	$5 
	dc.w	$8 
	dc.w	$5 
	dc.w	$6 
	dc.w	$C 
	dc.w	$1F 
	dc.w	$6
	dc.w	$2 
MagicBaseDamageTable: ; Something indexed by battle magic
	dc.b	$04, $B0
	dc.b	$06, $A4
	dc.b	$03, $57
	dc.b	$00, $32
	dc.b	$0F, $1E
	dc.b	$02, $64
	dc.b	$00, $50
	dc.b	$01, $B6
	dc.b	$00, $1E
	dc.b	$00, $A0
	dc.b	$01, $4A
	dc.b	$00, $00
	dc.b	$00, $00 
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
	dc.l	loc_00000000	
	dc.l	loc_00000000	