; ===========================================================================
; Game Text & Name Tables
; Item/equipment/spell names and pointer tables, shop dialogue, gameplay message strings
; ===========================================================================
YouHaveNothingToUseStr:
	dc.b	"You have nothing to use!", $FF, $00
DiscardWhichItemStr:
	dc.b	"Which item do you", $FE
	dc.b	"want to discard?", $FF, $00
UseWhichItemStr:
	dc.b	"Which item do you", $FE
	dc.b	"want to use?", $FF, $00
NoBooksOfSpellsStr:
	dc.b	"You have no Books of Spells.", $FF, $00
PutDownBookStr:
	dc.b	"Which Book of Spells do", $FE
	dc.b	"you want to put down?", $FF
CastSpellBookStr:
	dc.b	"From which Book do you", $FE
	dc.b	"wish to cast a spell?", $FF, $00
ReadyBookCombatStr:
	dc.b	"Which Book do you want", $FE
	dc.b	"to ready for combat?", $FF
NoCombatBooksStr:
	dc.b	"You have no Books of Spells", $FE
	dc.b	"that can be used in combat.", $FF
CantUseBookInCombatStr:
	dc.b	"That Book of Spells", $FE
	dc.b	"can't be used in combat.", $FF, $00
BookOfStr:
	dc.b	"The Book of ", $FF, $00
BookReadyStr:
	dc.b	" Spells", $FE
	dc.b	"is ready for use in battle!", $FF 
CantUseStr:
	dc.b	"CAN'T USE", $FF
AlreadyOpenStr:
	dc.b	"But it's already open!", $FF, $00
NothingToOpenStr:
	dc.b	"There's nothing", $FE
	dc.b	"to open here!", $FF
CantOpenStr:
	dc.b	"Sorry, you can't open that!", $FF
AlreadyOpenedStr:
	dc.b	"You already opened that!", $FF, $00
NothingInsideStr:
	dc.b	"Sorry, there's", $FE
	dc.b	"nothing inside.", $FF, $00
TrufflesStillThereStr2:
	dc.b	"Stop worrying, the", $FE
	dc.b	"truffles are still there!", $FF, $00
HerbsStillThereStr2:
	dc.b	"Stop worrying, the", $FE
	dc.b	"herbs are still there!", $FF
MoneyInsideStr:
	dc.b	"There's money inside.", $FF
MapInsideStr:
	dc.b	"There's a map inside!", $FF
ThereIsStr:
	dc.b	"There's ", $FF, $00
InsideStr:
	dc.b	" inside!", $FF, $00
CantCarryMoreStr:
	dc.b	"You can't carry any more!", $FE
	dc.b	"Do you want to drop", $FE
	dc.b	"something?", $FF, $00
DontWantCarryStr:
	dc.b	"OK, so you don't", $FE
	dc.b	"want to carry", $FF, $00
TakesStr:
	dc.b	"takes ", $FF, $00
AreaMapStr:
	dc.b	"Area Map", $FF, $00
HerbsStr:
	dc.b	"Herbs", $FF
CandleStr:
	dc.b	"Candle", $FF, $00
LanternStr:
	dc.b	"Lantern", $FF
PoisonBalmStr:
	dc.b	"Poison Balm", $FF
AlarmClockStr:
	dc.b	"Alarm Clock", $FF
VaseStr:
	dc.b	"Vase", $FF, $00
JokeBookStr:
	dc.b	"Joke Book", $FF
SmallBombStr:
	dc.b	"Small Bomb", $FF, $00
OldWomanSketchStr:
	dc.b	"Old Woman's Sketch", $FF, $00
OldManSketchStr:
	dc.b	"Old Man's Sketch", $FF, $00
PassToCartahenaStr:
	dc.b	"Pass to Cartahena", $FF
TrufflesStr:
	dc.b	"Truffles", $FF, $00
DigotPlantStr:
	dc.b	"Digot Plant", $FF
TreasureOfTroyStr:
	dc.b	"Treasure of Troy", $FF, $00
WhiteCrystalStr:
	dc.b	"White Crystal", $FF
RedCrystalStr:
	dc.b	"Red Crystal", $FF
BlueCrystalStr:
	dc.b	"Blue Crystal", $FF, $00
WhiteKeyStr:
	dc.b	"White Key", $FF
RedKeyStr:
	dc.b	"Red Key", $FF
BlueKeyStr:
	dc.b	"Blue Key", $FF, $00
CrownStr:
	dc.b	"Crown", $FF
SixteenRingsStr:
	dc.b	"Sixteen Rings", $FF
BronzeKeyStr:
	dc.b	"Bronze Key", $FF, $00
SilverKeyStr:
	dc.b	"Silver Key", $FF, $00
GoldKeyStr:
	dc.b	"Gold Key", $FF, $00
ThuleKeyStr:
	dc.b	"Thule Key", $FF
SecretKeyStr:
	dc.b	"Secret Key", $FF, $00
MedicineStr:
	dc.b	"Medicine", $FF, $00
AgateJewelStr:
	dc.b	"Agate Jewel", $FF
GriffinWingStr:
	dc.b	"Griffin Wing", $FF, $00
TitaniasMirrorStr:
	dc.b	"Titania's Mirror", $FF, $00
GnomeStoneStr:
	dc.b	"Gnome Stone", $FF
TopazJewelStr:
	dc.b	"Topaz Jewel", $FF
BansheePowderStr:
	dc.b	"Banshee Powder", $FF, $00
RafaelsStickStr:
	dc.b	"Rafael's Stick", $FF, $00
MirrorOfAtlasStr:
	dc.b	"Mirror of Atlas", $FF
RubyBroochStr:
	dc.b	"Ruby Brooch", $FF
DungeonKeyStr:
	dc.b	"Dungeon Key", $FF
KulmVaseStr:
	dc.b	"Kulm Vase", $FF
KasanChiselStr:
	dc.b	"Kasan's Chisel", $FF, $00
BookOfKielStr:
	dc.b	"Book of Kiel", $FF, $00
DanegeldWaterStr:
	dc.b	"Danegeld Water", $FF, $00
MineralBarStr:
	dc.b	"Mineral Bar", $FF
MegaBlastStr:
	dc.b	"Mega Blast", $FF, $00
UsesTheStr:
	dc.b	"uses the", $FF, $00
PutStr:
	dc.b	"Put ", $FF, $00
PutDownStr:
	dc.b	" down", $FF
DiscardsTheStr:
	dc.b	"discards the", $FF, $00
CantUseHereStr:
	dc.b	"You can't use that here.", $FF, $00
SorryYouAreCursedStr:
	dc.b	"Sorry, but you're cursed.", $FF
NotEnoughMpStr:
	dc.b	"you don't have enough", $FE
	dc.b	"Magic Points.", $FF
NothingHappenedStr:
	dc.b	"Nothing happened!", $FF
BrightPlaceStr:
	dc.b	"If you use it in a bright", $FE
	dc.b	"place, nothing happens.", $FF
AreaBrightStr:
	dc.b	"The area has become bright.", $FF 
BronzeSwordStr:
	dc.b	"Bronze Sword", $FF, $00 
IronSwordStr:
	dc.b	"Iron Sword", $FF, $00 
SharpSwordStr:
	dc.b	"Sharp Sword", $FF 
LongSwordStr:
	dc.b	"Long Sword", $FF, $00 
SilverSwordStr:
	dc.b	"Silver Sword", $FF, $00 
PrimeSwordStr:
	dc.b	"Prime Sword", $FF 
GoldenSwordStr:
	dc.b	"Golden Sword", $FF, $00 
MirageSwordStr:
	dc.b	"Mirage Sword", $FF, $00 
PlatinumSwordStr:
	dc.b	"Platinum Sword", $FF, $00 
DiamondSwordStr:
	dc.b	"Diamond Sword", $FF 
GraphiteSwordStr:
	dc.b	"Graphite Sword", $FF, $00 
RoyalSwordStr:
	dc.b	"Royal Sword", $FF 
UltimateSwordStr:
	dc.b	"Ultimate Sword", $FF, $00 
SwordOfVermilionStr:
	dc.b	"Sword of Vermilion", $FF, $00 
DarkSwordStr:
	dc.b	"Dark Sword", $FF, $00 
DeathSwordStr:
	dc.b	"Death Sword", $FF 
BarbarianSwordStr:
	dc.b	"Barbarian Sword", $FF 
CriticalSwordStr:
	dc.b	"Critical Sword", $FF, $00 
LeatherShieldStr:
	dc.b	"Leather Shield", $FF, $00 
SmallShieldStr:
	dc.b	"Small Shield", $FF, $00 
LargeShieldStr:
	dc.b	"Large Shield", $FF, $00 
SilverShieldStr:
	dc.b	"Silver Shield", $FF 
GoldShieldStr:
	dc.b	"Gold Shield", $FF 
PlatinumShieldStr:
	dc.b	"Platinum Shield", $FF 
GemShieldStr:
	dc.b	"Gem Shield", $FF, $00 
SapphireShieldStr:
	dc.b	"Sapphire Shiel", $64, $FF 
DiamondShieldStr:
	dc.b	"Diamond Shield", $FF, $00 
DragonShieldStr:
	dc.b	"Dragon Shield", $FF 
MagicShieldStr:
	dc.b	"Magic Shield", $FF, $00 
PhantomShieldStr:
	dc.b	"Phantom Shield", $FF, $00 
GrizzlyShieldStr:
	dc.b	"Grizzly Shield", $FF, $00 
CarmineShieldStr:
	dc.b	"Carmine Shield", $FF, $00 
RoyalShieldStr:
	dc.b	"Royal Shield", $FF, $00 
PoisonShieldStr:
	dc.b	"Poison Shield", $FF 
KnightShieldStr:
	dc.b	"Knight Shield", $FF 
LeatherArmorStr:
	dc.b	"Leather Armor", $FF 
BronzeArmorStr:
	dc.b	"Bronze Armor", $FF, $00 
MetalArmorStr:
	dc.b	"Metal Armor", $FF 
ScaleArmorStr:
	dc.b	"Scale Armor", $FF 
PlateArmorStr:
	dc.b	"Plate Armor", $FF 
SilverArmorStr:
	dc.b	"Silver Armor", $FF, $00 
GoldArmorStr:
	dc.b	"Gold Armor", $FF, $00 
CrystalArmorStr:
	dc.b	"Crystal Armor", $FF 
EmeraldArmorStr:
	dc.b	"Emerald Armor", $FF 
DiamondArmorStr:
	dc.b	"Diamond Armor", $FF 
KnightArmorStr:
	dc.b	"Knight Armor", $FF, $00 
UltimateArmorStr:
	dc.b	"Ultimate Armor", $FF, $00 
OdinArmorStr:
	dc.b	"Odin Armor", $FF, $00 
SecretArmorStr:
	dc.b	"Secret Armor", $FF, $00 
SkeletonArmorStr:
	dc.b	"Skeleton Armor", $FF, $00 
CrimsonArmorStr:
	dc.b	"Crimson Armor", $FF 
OldNickArmorStr:
	dc.b	"Old Nick Armor", $FF, $00 
AeroStr:
	dc.b	"Aero", $FF, $00 
AeriosStr:
	dc.b	"Aerios", $FF, $00 
VoltiStr:
	dc.b	"Volti", $FF 
VoltioStr:
	dc.b	"Voltio", $FF, $00 
VoltiosStr:
	dc.b	"Voltios", $FF 
FerrosStr:
	dc.b	"Ferros", $FF, $00 
CopperosStr:
	dc.b	"Copperos", $FF, $00 
MercuriosStr:
	dc.b	"Mercurios", $FF 
ArgentosStr:
	dc.b	"Argentos", $FF, $00 
HydroStr:
	dc.b	"Hydro", $FF 
HydriosStr:
	dc.b	"Hydrios", $FF 
ChronoStr:
	dc.b	"Chrono", $FF, $00 
ChroniosStr:
	dc.b	"Chronios", $FF, $00 
TerrafissiStr:
	dc.b	"Terrafissi", $FF, $00 
AriesStr:
	dc.b	"Aries", $FF 
ExtriosStr:
	dc.b	"Extrios", $FF 
InaudiosStr:
	dc.b	"Inaudios", $FF, $00 
LuminosStr:
	dc.b	"Luminos", $FF 
SanguaStr:
	dc.b	"Sangua", $FF, $00 
SanguiaStr:
	dc.b	"Sanguia", $FF 
SanguioStr:
	dc.b	"Sanguio", $FF
SanguiosStr:
	dc.b	"Sanguios", $FF, $00
ToxiosStr:
	dc.b	"Toxios", $FF, $00
CantPutDownStr: 
	dc.b	"You can't put that down.", $FF, $00
CantCarryMoreStr2:
	dc.b	"You can't carry any more.", $FF
; ===========================================================================
;loc_00025DB4:
ItemNames:
	dc.l	HerbsStr
	dc.l	CandleStr
	dc.l	LanternStr
	dc.l	PoisonBalmStr
	dc.l	AlarmClockStr
	dc.l	VaseStr
	dc.l	JokeBookStr
	dc.l	SmallBombStr
	dc.l	OldWomanSketchStr
	dc.l	OldManSketchStr
	dc.l	PassToCartahenaStr
	dc.l	TrufflesStr
	dc.l	DigotPlantStr
	dc.l	TreasureOfTroyStr
	dc.l	WhiteCrystalStr
	dc.l	RedCrystalStr
	dc.l	BlueCrystalStr
	dc.l	WhiteKeyStr
	dc.l	RedKeyStr
	dc.l	BlueKeyStr
	dc.l	CrownStr
	dc.l	SixteenRingsStr
	dc.l	BronzeKeyStr
	dc.l	SilverKeyStr
	dc.l	GoldKeyStr
	dc.l	ThuleKeyStr
	dc.l	SecretKeyStr
	dc.l	MedicineStr
	dc.l	AgateJewelStr
	dc.l	GriffinWingStr
	dc.l	TitaniasMirrorStr	
	dc.l	GnomeStoneStr
	dc.l	TopazJewelStr
	dc.l	BansheePowderStr
	dc.l	RafaelsStickStr
	dc.l	MirrorOfAtlasStr
	dc.l	RubyBroochStr
	dc.l	DungeonKeyStr
	dc.l	KulmVaseStr	
	dc.l	KasanChiselStr	
	dc.l	BookOfKielStr	
	dc.l	DanegeldWaterStr	
	dc.l	MineralBarStr	
	dc.l	MegaBlastStr	
; ===========================================================================
;loc_00025E64
MagicNames:
	dc.l	AeroStr
	dc.l	AeriosStr
	dc.l	VoltiStr
	dc.l	VoltioStr
	dc.l	VoltiosStr
	dc.l	FerrosStr
	dc.l	CopperosStr
	dc.l	MercuriosStr
	dc.l	ArgentosStr
	dc.l	HydroStr
	dc.l	HydriosStr
	dc.l	ChronoStr
	dc.l	ChroniosStr
	dc.l	TerrafissiStr
	dc.l	AriesStr
	dc.l	ExtriosStr
	dc.l	InaudiosStr
	dc.l	LuminosStr
	dc.l	SanguaStr
	dc.l	SanguiaStr
	dc.l	SanguioStr
	dc.l	ToxiosStr
	dc.l	SanguiosStr
; ===========================================================================
;loc_00025EC0:
EquipmentNames:
	dc.l	BronzeSwordStr
	dc.l	IronSwordStr
	dc.l	SharpSwordStr
	dc.l	LongSwordStr
	dc.l	SilverSwordStr
	dc.l	PrimeSwordStr
	dc.l	GoldenSwordStr
	dc.l	MirageSwordStr
	dc.l	PlatinumSwordStr
	dc.l	DiamondSwordStr
	dc.l	GraphiteSwordStr
	dc.l	RoyalSwordStr
	dc.l	UltimateSwordStr
	dc.l	SwordOfVermilionStr
	dc.l	DarkSwordStr
	dc.l	DeathSwordStr
	dc.l	BarbarianSwordStr
	dc.l	CriticalSwordStr
	dc.l	DarkSwordStr	
	dc.l	DarkSwordStr	
	dc.l	LeatherShieldStr
	dc.l	SmallShieldStr
	dc.l	LargeShieldStr
	dc.l	SilverShieldStr
	dc.l	GoldShieldStr
	dc.l	PlatinumShieldStr
	dc.l	GemShieldStr	
	dc.l	SapphireShieldStr	
	dc.l	DiamondShieldStr
	dc.l	DragonShieldStr
	dc.l	MagicShieldStr	
	dc.l	PhantomShieldStr	
	dc.l	GrizzlyShieldStr	
	dc.l	CarmineShieldStr
	dc.l	RoyalShieldStr	
	dc.l	PoisonShieldStr
	dc.l	KnightShieldStr
	dc.l	CarmineShieldStr	
	dc.l	CarmineShieldStr	
	dc.l	CarmineShieldStr	
	dc.l	LeatherArmorStr
	dc.l	BronzeArmorStr
	dc.l	MetalArmorStr
	dc.l	ScaleArmorStr
	dc.l	PlateArmorStr
	dc.l	SilverArmorStr
	dc.l	GoldArmorStr
	dc.l	CrystalArmorStr
	dc.l	EmeraldArmorStr	
	dc.l	DiamondArmorStr
	dc.l	KnightArmorStr
	dc.l	UltimateArmorStr
	dc.l	OdinArmorStr
	dc.l	SecretArmorStr
	dc.l	SkeletonArmorStr	
	dc.l	CrimsonArmorStr
	dc.l	OldNickArmorStr	
; loc_00025FA4
ShopDialog_NextTime:
	dc.l	NextTimeStr	
	dc.l	NextTimeStr	
	dc.l	NextTimeStr	
; loc_00025FB0
ShopDialog_ThankYou:
	dc.l	ThankYouStr	
	dc.l	ThankYouStr	
	dc.l	ThankYouStr	
; loc_00025FBC
ShopDialog_AnythingElse:
	dc.l	AnythingElseStr	
	dc.l	AnythingElseStr	
	dc.l	AnythingElseStr	
; loc_00025FC8
ShopDialog_BusinessThanks:
	dc.l	BusinessThanksStr	
	dc.l	BusinessThanksStr	
	dc.l	BusinessThanksStr	
; loc_00025FD4
ShopDialog_SellAnything:
	dc.l	SellAnythingStr	
	dc.l	SellAnythingStr	
	dc.l	SellAnythingStr	
; loc_00025FE0
ShopDialog_NoNeed:
	dc.l	NoNeedStr	
	dc.l	NoNeedStr	
	dc.l	NoNeedStr	
; loc_00025FEC
ShopDialog_GivingAway:
	dc.l	GivingAwayStr	
	dc.l	GivingAwayStr	
	dc.l	GivingAwayStr	
; loc_00025FF8
ShopDialog_BuyPrompt:
	dc.l	BuyPromptStr	
	dc.l	BuyPromptStr	
	dc.l	BuyPromptStr	
; loc_00026004
ShopDialog_Ok:
	dc.l	OkStr
	dc.l	OkStr
	dc.l	OkStr
; loc_00026010
ShopDialog_SellPrompt:
	dc.l	SellPromptStr	
	dc.l	SellPromptStr	
	dc.l	SellPromptStr	
; loc_0002601C
ShopDialog_AllRight:
	dc.l	AllRightStr
	dc.l	AllRightStr
	dc.l	AllRightStr
; loc_00026028
ShopDialog_Welcome:
	dc.l	ShopWelcomeStr
	dc.l	WeaponsArmorStr
	dc.l	SpellBooksStr
NoOneHereStr:
	dc.b	"There's no one", $FE
	dc.b	"here to talk to.", $FF 
NothingStr:
	dc.b	"nothing", $FF 
AllRingsStr:
	dc.b	"All Rings", $FF
ShopWelcomeStr:
	dc.b	"Welcome to my shop.", $FE
	dc.b	"Does anything interest you?", $FF 
BuyPromptStr:
	dc.b	"What would you like to buy?", $FF 
SellPromptStr:
	dc.b	"What do you want to sell?", $FF 
IsStr:
	dc.b	"Is ", $FF 
OkStr:
	dc.b	" OK?", $FF, $00 
AllRightStr:
	dc.b	"all right?", $FF, $00 
ThankYouStr:
	dc.b	"Thank you.", $FF, $00 
AnythingElseStr:
	dc.b	"Anything else for you today?", $FF, $00 
BusinessThanksStr:
	dc.b	"Thank you for your business!", $FF, $00 
GivingAwayStr:
	dc.b	"Hmmph! You think I'm", $FE
	dc.b	"giving this stuff away?", $FF, $00 
SellAnythingStr:
	dc.b	"Do you have", $FE
	dc.b	"anything to sell?", $FF 
NextTimeStr:
	dc.b	"Maybe next time!", $FF, $00 
NoNeedStr:
	dc.b	"Sorry, sir, but I have", $FE
	dc.b	"no need for that.", $FF, $00
SpellBooksStr:
	dc.b	"Books of Spells", $FE
	dc.b	"are my specialty.", $FE
	dc.b	"May I help you?", $FF
WeaponsArmorStr:
	dc.b	"You can buy weapons,", $FE
	dc.b	"armor, and shields here.", $FF
CursedItemStr:
	dc.b	"I don't want to buy", $FE
	dc.b	"that--it's cursed!", $FF, $00 
RoomRentStr:
	dc.b	"Welcome!", $FE
	dc.b	"We rent rooms", $FE
	dc.b	"for the night.", $FF
RestWellStr:
	dc.b	"Relax and enjoy a", $FE
	dc.b	"well-deserved rest.", $FF
BetterMorningStr:
	dc.b	"You look much better", $FE
	dc.b	"this morning!", $FF, $00
NoPaySleepStreetStr:
	dc.b	"I'm sorry, but if you", $FE
	dc.b	"can't pay, you'll have", $FE
	dc.b	"to sleep in the street!", $FF, $00
ServicesCostStr:
	dc.b	"My services cost money,", $FE
	dc.b	"you know. You can't stay", $FE
	dc.b	"if you don't pay!", $FF, $00
NothingToUseStr:
	dc.b	"You have nothing to use!", $FF, $00 
ReadiedStr:
	dc.b	"readied ", $FF, $00 
RemovedStr:
	dc.b	"removed ", $FF, $00
ProperEquipmentStr:
	dc.b	"You don't have the", $FE
	dc.b	"proper equipment!", $FF, $00
ReadyPromptStr:
	dc.b	"What do you want to ready?", $FF, $00
AlreadyReadiedStr:
	dc.b	"You readied that earlier.", $FF
DropCursedStr:
	dc.b	"You can't drop", $FE
	dc.b	"a cursed item!", $FF
ExchangeCursedStr:
	dc.b	"You can't exchange", $FE
	dc.b	"a cursed item.", $FF
CursedStr:
	dc.b	"It's cursed!", $FF, $00
NoUnusualStr:
	dc.b	"You searched carefully,", $FE
	dc.b	"but you didn't notice", $FE
	dc.b	"anything unusual.", $FF
SomeoneStandingStr:
	dc.b	"Someone is standing in", $FE
	dc.b	"front of you!", $FF, $00
TreasureChestStr:
	dc.b	"It's a treasure chest!", $FF, $00
HerbsStillThereStr:
	dc.b	"Stop worrying, the", $FE
	dc.b	"herbs are still there!", $FF
TrufflesStillThereStr:
	dc.b	"Stop worrying, the", $FE
	dc.b	"truffles are still there!", $FF, $00 
FortuneTellerStr:
	dc.b	"I can tell your fortune,", $FE
	dc.b	"if your money is good.", $FF 
FeeStr:
	dc.b	"The fee is ", $FF 
PayFirstStr:
	dc.b	"You must pay first!", $FF
NoPayNoFortuneStr:
	dc.b	"If you can't pay,", $FE
	dc.b	"I won't tell your fortune.", $FF, $00
NoQuestionsStr:
	dc.b	"If you have no questions,", $FE
	dc.b	"then why are you here?", $FF, $00
HelpPromptStr:
	dc.b	"How may we help you?", $FF, $00 
NotPoisonedStr:
	dc.b	"You haven't been poisoned.", $FF, $00 
GiveToCharityStr:
	dc.b	"You must give ", $FF, $00 
CharityAgreeStr:
	dc.b	" to charity.", $FE
	dc.b	"Do you agree?", $FF, $00
CantCureStr:
	dc.b	"I'm sorry. I can't cure", $FE
	dc.b	"you. Your donation is", $FE
	dc.b	"appreciated, though.", $FF, $00 
PoisonPurgedStr:
	dc.b	"The poison has been", $FE
	dc.b	"purged from your body.", $FF, $00
NoTakeBackStr:
	dc.b	"Don't even think of taking", $FE
	dc.b	"back your donation.", $FF, $00
NoCurseStr:
	dc.b	"There is no curse on you.", $FF
CurseRemovedStr:
	dc.b	"The curse has been removed.", $FF
SaveNumberStr:
	dc.b	"Save under", $FE
	dc.b	"which number?", $FF, $00
GameSavedStr:
	dc.b	"Your game was saved", $FE 
	dc.b	"successfully!", $FF
NeverGiveUpStr:
	dc.b	"Never give up. Every obstacle", $FE
	dc.b	"can be overcome!", $FF, $00
NotPoisonousStr:
	dc.b	"Go ahead--it's", $FE
	dc.b	"not poisonous!", $FF
PoisonTooStrongStr:
	dc.b	"The poison is too", $FE
	dc.b	"strong for that cure.", $FF
AriseWarriorStr:
	dc.b	"Arise, brave warrior! Our", $FE
	dc.b	"world needs you! But half", $FE
	dc.b	"your money goes to the poor.", $FF, $00
AwakenVoiceStr:
	dc.b	"As you awaken, you seem to", $FE
	dc.b	"hear a stern voice inside", $FE
	dc.b	"your head say:", $FD
	dc.b	'"Don''t gamble with your', $FE
	dc.b	'life like that again. Too', $FE
	dc.b	'much depends on you!"', $FF
CarelessWarningStr:
	dc.b	"Don't be careless! The", $FE
	dc.b	"world is depending on you!", $FD
	dc.b	"You should start over", $FE
	dc.b	"from the beginning.", $FF
AfraidKilledStr:
	dc.b	"Whew! For a moment there, I", $FE
	dc.b	"was afraid I'd killed you.", $FD
	dc.b	"You deserved it though! Now", $FE
	dc.b	"don't come back until you've", $FE
	dc.b	"rescued our men.", $FF, $00 
InaudiosSpellsStr:
	dc.b	"Casting from the Book of", $FE
	dc.b	"Inaudios Spells helps", $FE
	dc.b	"you to evade monsters.", $FF
InaudiosWornOffStr:
	dc.b	"The effects of the Inaudios", $FE
	dc.b	"Spell have worn off.", $FF, $00
PoisonedStr:
	dc.b	"You suddenly feel weak.", $FE
	dc.b	"You were poisoned", $FE
	dc.b	"during the battle!", $FF, $00
MagicRestoredStr:
	dc.b	"Some of your magic points", $FE
	dc.b	"have been restored.", $FF
AllMagicRestoredStr:
	dc.b	"All of your magic points", $FE
	dc.b	"have been restored.", $FF, $00
PartialHitPointsStr:
	dc.b	"Your lost hit points have", $FE
	dc.b	"been partially regained.", $FF, $00
HitPointsRegainedStr:
	dc.b	"Your lost hit points have", $FE 
	dc.b	"been regained.", $FF, $00
AllHitPointsStr:
	dc.b	"All of your lost hit points", $FE
	dc.b	"have been regained.", $FF 
PowderSpillsStr:
	dc.b	"The powder spills all over", $FE
	dc.b	"you. Wrenching pain courses", $FE
	dc.b	"through your body.", $FF
TownUseWarningStr:
	dc.b	"If you use that in town,", $FE
	dc.b	"the townspeople aren't", $FE
	dc.b	"going to like it one bit!", $FF
MonstersHardTimeStr:
	dc.b	"The monsters will have", $FE
	dc.b	"a hard time finding you.", $FF
NotWorkHereStr:
	dc.b	"That won't work here.", $FF
WorldMapsStr:
	dc.b	"We have maps of", $FE
	dc.b	"the whole world.", $FF, $00
GlowingMapStr:
	dc.b	"A glowing map of this area", $FE
	dc.b	"appears in the mirror.", $FF
NoisyStr:
	dc.b	"Brrrnnngg!", $FE
	dc.b	"It was very noisy!", $FF
BrrrnnnggStr:
	dc.b	"Brrrnnngg!", $FF, $00
SlippedHandStr:
	dc.b	"Oh, no! It slipped from", $FE
	dc.b	"your hand! What a waste--it", $FE
	dc.b	"might have been valuable.", $FF
KnockJokesStr:
	dc.b	'Looking for good "knock,', $FE
	dc.b	'knock" jokes, maybe?', $FE
	dc.b	"Sorry, no such thing!", $FF
LoudRoarStr:
	dc.b	"It gave out a loud roar and", $FE
	dc.b	"shot brilliant streamers of", $FE
	dc.b	"color into the sky.", $FF
YoungerBeautifulStr:
	dc.b	"When she was younger, she", $FE
	dc.b	"must have been beautiful.", $FF
OldManTookStr:
	dc.b	"The old man took it.", $FF, $00 
MeanLookStr:
	dc.b	"He looks mean.", $FF, $00
OldWomanTookStr:
	dc.b	"The old woman took it.", $FF, $00
RoastDuckStr:
	dc.b	"You ate a little bit of it.", $FE
	dc.b	"It tastes like roast duck.", $FF, $00 
IncredibleTreasureStr:
	dc.b	"This is an incredible", $FE
	dc.b	"treasure! Get it out of", $FE
	dc.b	"here before you lose it.", $FF, $00
JarBreaksStr:
	dc.b	"The jar breaks! Strange", $FE 
	dc.b	"fragrances fill the air and", $FE
	dc.b	"tickle your nose.", $FF
SweetTasteStr:
	dc.b	"It tastes very sweet.", $FE
	dc.b	"The magical power makes", $FE
	dc.b	"your hands tingle.", $FF, $00
BitterTasteStr:
	dc.b	"It is very bitter.", $FE
	dc.b	"Your body suddenly", $FE
	dc.b	"feels wobbly and weak.", $FF, $00
ReadDisappearsStr:
	dc.b	"As soon as you read it, it", $FE
	dc.b	"disappears and you can't", $FE
	dc.b	"recall what it said.", $FF, $00
BrokePowerStr:
	dc.b	"It broke! A strange power", $FE
	dc.b	"ripples through your body.", $FF, $00
NoFeelStr:
	dc.b	"You don't feel anything.", $FE
	dc.b	"What could have happened?", $FF, $00
HorribleTasteStr:
	dc.b	"It tastes horrible, but", $FE
	dc.b	"your body feels very light.", $FF
PowerSurgeStr:
	dc.b	"Power surges through you.", $FF
RingsLeaveStr:
	dc.b	"The sixteen rings leave", $FE
	dc.b	"your hands and rise up", $FE
	dc.b	"into the sky.", $FD
	dc.b	"Thousands of brilliant", $FE
	dc.b	"stars gleam down upon you.", $FF, $00 
RingsFirmamentStr:
	dc.b	"The rings take their place", $FE
	dc.b	"among the firmament, once", $FE
	dc.b	"again beyond man's grasp.", $FF, $00
NothingToTakeStr:
	dc.b	"There is nothing to take.", $FF
WhiteBeautifulStr:
	dc.b	"It is white and", $FE
	dc.b	"very beautiful.", $FF
DeepRedStr:
	dc.b	"It is deep red;", $FE
	dc.b	"it sparkles in the light.", $FF
BrightBlue:
	dc.b	"It is bright blue", $FE
	dc.b	"and beautiful!", $FF, $00
NoKeyholeStr:
	dc.b	"There's no keyhole here!", $FF, $00
NoDoorStr:
	dc.b	"It doesn't have a door,", $FE
	dc.b	"so how can you use it?", $FF, $00 
KeyUnlockedStr:
	dc.b	"The key unlocked it.", $FF, $00
KeyDoesntFitStr:
	dc.b	"The key doesn't fit.", $FF, $00
EffortsFutileStr:
	dc.b	"You sense that your", $FE 
	dc.b	"efforts are futile.", $FF
LockedStr:
	dc.b	"It's locked.", $FF, $00
TombstoneStr:
	dc.b	'"Blade rests here in peace"', $FE
	dc.b	"is written on his tombstone.", $FF, $00
CantTakeBoxStr:
	dc.b	"You can't take it,", $FE
	dc.b	"it's a box!", $FF, $00
TookTreasureStr:
	dc.b	"You took the treasure."
	script_cmd_actions 1
	script_set_trigger TRIGGER_Treasure_of_troy_found
OpenedChestStr:
	dc.b	"You opened"
	dc.b	" the chest.", $FF 
BadPoisonStr:
	dc.b	"Bad(poison)", $FF 
BadCurseStr:
	dc.b	"Bad(curse)", $FF, $00 
BestStr:
	dc.b	"Best", $FF, $00 
GoodStr:
	dc.b	"Good", $FF, $00
ExpStr:
	dc.b	"EXP. ", $FF
ThankYouStr2:
	dc.b	"Thank you!", $FF, $00
LongLiveKingStr:
	dc.b	"Long live King ", SCRIPT_PLAYER_NAME, "!", $FF
BanishedEvilStr:
	dc.b	"You've banished", $FE
	dc.b	"evil from our land!", $FF 
; loc_000272AC
EndingCelebrationStrings:
	dc.l	ThankYouStr2
	dc.l	LongLiveKingStr
	dc.l	BanishedEvilStr
	dc.l	ThankYouStr2
	dc.l	LongLiveKingStr
	dc.l	BanishedEvilStr
	dc.l	ThankYouStr2
	dc.l	LongLiveKingStr 
	dc.l	BanishedEvilStr
	dc.l	ThankYouStr2
	dc.l	LongLiveKingStr
	dc.l	BanishedEvilStr
	dc.l	ThankYouStr2
	dc.l	LongLiveKingStr
	dc.l	BanishedEvilStr
	dc.l	ThankYouStr2 
	dc.l	LongLiveKingStr
	dc.l	BanishedEvilStr
	dc.l	ThankYouStr2
	dc.l	LongLiveKingStr
	dc.l	BanishedEvilStr
	dc.l	ThankYouStr2
	dc.l	LongLiveKingStr
	dc.l	BanishedEvilStr 
	dc.l	ThankYouStr2
	dc.l	LongLiveKingStr
	dc.l	BanishedEvilStr
	dc.l	ThankYouStr2
	dc.l	LongLiveKingStr
	dc.l	BanishedEvilStr