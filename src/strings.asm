; ===========================================================================
; String Data & UI Elements
; Overworld dialogue, menu strings, UI border tilemaps
; ===========================================================================
LongDangerousRoadAheadStr:
	dc.b	"You have a long and", $FE
	dc.b	"dangerous road ahead of", $FE
	dc.b	"you. Hurry or all is lost!", $FF, $00
WrongRoadStr:
	dc.b	"Oops. It must be the", $FE
	dc.b	"other road that leads to", $FE
	dc.b	"Verlin's Cave", $FF
MerchantFromParmaStr:
	dc.b	"I'm a merchant from Parma.", $FE
	dc.b	"I hope I'm going the right", $FE
	dc.b	"way to Wyclif.", $FF, $00
PreparedForTaskStr:
	dc.b	"Are you sure you're", $FE
	dc.b	"prepared for the task", $FE
	dc.b	"ahead?", $FF, $00
HeadedToWatlingStr:
	dc.b	"Headed to Watling? It's an", $FE
	dc.b	"odd place--not many young", $FE
	dc.b	"people.", $FF, $00
WayToDeepdaleStr:
	dc.b	"Do you know if this is the", $FE
	dc.b	"way to Deepdale?", $FF
LongWayToStowStr:
	dc.b	"Prepare yourself--it's a", $FE
	dc.b	"long way to Stow!", $FF, $00
GreetingsWarriorStr:
	dc.b	"Greetings, warrior! Off to", $FE
	dc.b	"combat evil, eh? Well, good", $FE
	dc.b	"luck!", $FF, $00
EvilFlourishesStr:
	dc.b	"Evil flourishes when the", $FE
	dc.b	"rings are scattered!", $FF
AppearancesDeceiveStr:
	dc.b	"Appearances deceive, as do", $FE
	dc.b	"Thar and Luther!", $FF
RingsHavePowerStr:
	dc.b	"The rings have tremendous", $FE
	dc.b	"power. Use them wisely.", $FF
ProgressingWellStr:
	dc.b	"You are progressing!", $FE
	dc.b	"Keep up the good work!", $FF
TharFashionsEvilStr:
	dc.b	"Thar can fashion evil", $FE
	dc.b	"beings from thin air.", $FF
UseBansheePowderStr:
	dc.b	"Use banshee powder", $FE
	dc.b	"only when you're", $FE
	dc.b	"in mortal danger.", $FF
TsarkonPawnOfEvilStr:
	dc.b	"Tsarkon is the", $FE
	dc.b	"pawn of evil.", $FF, $00
SpendWealthWiselyStr:
	dc.b	"Spend your wealth wisely!", $FF
LearnFromMistakesStr:
	dc.b	"Learn from the mistakes", $FE
	dc.b	"of Tsarkon and Erik!", $FF, $00
SawMotherInCartahenaStr:
	dc.b	"I saw your dear mother", $FE
	dc.b	"in Cartahena, but that", $FE
	dc.b	"was many years ago.", $FF
LostHereIsAMapStr_Wyclif:
	dc.b	"Lost again? Well, here's a", $FE
	dc.b	"map of the area."
	script_cmd_actions 7 ; 7 map areas
	script_reveal_map $00
	script_reveal_map $01
	script_reveal_map $10
	script_reveal_map $11
	script_reveal_map $12
	script_reveal_map $21
	script_reveal_map $22
	dc.b	$00 ; padding
LostHereIsAMapStr_Deepdale:
	dc.b	"Lost again? Well, here's a", $FE
	dc.b	"map of the area." 
	script_cmd_actions 4 ; 4 map areas
	script_reveal_map $13
	script_reveal_map $23
	script_reveal_map $24
	script_reveal_map $25
	dc.b	$00 ; padding
LostHereIsAMapStr_Stow:
	dc.b	"Lost again? Well, here's a", $FE
	dc.b	"map of the area."
	script_cmd_actions 4 ; 4 map areas
	script_reveal_map $26
	script_reveal_map $27
	script_reveal_map $28
	script_reveal_map $29
	dc.b	$00 ; padding
MenuStartContinueStr:
	dc.b	"Start", $FE
	dc.b	"Continue", $FF, $00
MenuOptionsStr:
	dc.b	"Talk Magic", $FE
	dc.b	"Item Equip", $FE
	dc.b	"Str  Seek", $FE
	dc.b	"Open Take", $FF
MessageSpeedStr:
	dc.b	"Message Speed", $FE
	dc.b	"    Fast", $FE
	dc.b	"    Normal", $FE
	dc.b	"    Slow", $FF, $00
YesNoStr:
	dc.b	"Yes", $FE
	dc.b	"No", $FF, $00
UseDiscardStr:
	dc.b	"Use", $FE
	dc.b	"Discard", $FF
CastReadyDiscardStr:
	dc.b	"Cast", $FE
	dc.b	"Ready", $FE
	dc.b	"Discard", $FF, $00
PutOnRemoveStopStr:
	dc.b	"Put on", $FE
	dc.b	"Remove", $FE
	dc.b	"Stop", $FF, $00
EquipOptionsStr:
	dc.b	"Weapon", $FE
	dc.b	"Shield", $FE
	dc.b	"Armor", $FF
ChurchOptionsStr:
	dc.b	"Remove a curse", $FE
	dc.b	"Apply poison balm", $FE
	dc.b	"Save your game", $FE
	dc.b	"Stop", $FF, $00
BuySellStopStr:
	dc.b	"Buy", $FE
	dc.b	"Sell", $FE
	dc.b	"Stop", $FF
KimStr:
	dc.b	"Kim", $FF
CharacterStatsStr:
	dc.b	"Name:", $FE
	dc.b	"Condition:", $FE
	dc.b	"Level:       EXP:", $FE
	dc.b	"Next level EXP:", $FE
	dc.b	"HP:          MHP:", $FE
	dc.b	"MP:          MMP:", $FE
	dc.b	"STR:         AC:", $FE
	dc.b	"INT:         DEX:", $FE
	dc.b	"LUK:         KIM:", $FF
EquipmentReadiedStr:
	dc.b	"Equipment Readied", $FE
	dc.b	"Weapon:", $FE
	dc.b	"Shield:", $FE
	dc.b	"Armor:", $FE
	dc.b	"Magic:", $FF
GearCombatStr:
	dc.b	"Gear (Combat)", $FF
GearMagicStr:
	dc.b	"Gear (Magic)", $FF, $00
GearItemStr:
	dc.b	"Gear (Item)", $FF
RingsStr:
	dc.b	"Rings", $FF

; ===========================================================================
RingNames:
	dc.l	RingWisdomStr
	dc.l	RingSkyStr
	dc.l	RingWindStr
	dc.l	RingFireStr
	dc.l	RingWaterStr
	dc.l	RingEarthStr
	dc.l	RingSunStr
	dc.l	RingPowerStr
RingWisdomStr:
	dc.b	"Ring of Wisdom", $FF, $00
RingSkyStr:
	dc.b	"Ring of Sky", $FF
RingWindStr:
	dc.b	"Ring of Wind", $FF, $00
RingFireStr:
	dc.b	"Ring of Fire", $FF, $00
RingWaterStr:
	dc.b	"Ring of Water", $FF
RingEarthStr:
	dc.b	"Ring of Earth", $FF
RingSunStr:
	dc.b	"Ring of Sun", $FF
RingPowerStr:
	dc.b	"Ring of Power", $FF
	
SelectNumberStr:
	dc.b	"Select a number", $FE
	dc.b	"and press Button C.", $FE
	dc.b	"             Name  Level", $FE
	dc.b	"Saved Game 1", $FE
	dc.b	"Saved Game 2", $FE
	dc.b	"Saved Game 3", $FF
ErrorPressCStr:
	dc.b	"If an error occurs,", $FE
	dc.b	"press button C.", $FF
LooksBetterPressCStr:
	dc.b	"That looks better.", $FE
	dc.b	"Please press button C.", $FF
DidntWorkPressResetStr:
	dc.b	"Sorry, it didn't work.", $FE
	dc.b	"Please press", $FE
	dc.b	"the Reset button.", $FF
NoSavedGameStr:
	dc.b	"You don't have a", $FE
	dc.b	"saved game to retrieve!", $FE
	dc.b	"Please press button C.", $FF
GameReadyPressCStr:
	dc.b	"Your game is ready!", $FE
	dc.b	"Please press button C.", $FF, $00
SavedGameOptionsStr:
	dc.b	"Saved Game 1", $FE
	dc.b	"Saved Game 2", $FE
	dc.b	"Saved Game 3", $FF, $00
	dc.b	$E0, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1
	dc.b	$E2, $00, $E3, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E5, $E3, $E4, $E4, $E4, $E4
	dc.b	$E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E5, $E6, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7
	dc.b	$E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E8, $00
UIBorder_SmallTop:
	dc.b	$E0, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E2
UIBorder_SmallMiddle:
	dc.b	$E3, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E5, $E3, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4
	dc.b	$E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E5
UIBorder_LargeBox:
	dc.b	$E6, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E8, $E0, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1
	dc.b	$E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E2, $E3, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4
	dc.b	$E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E5, $E3, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4
	dc.b	$E4, $E4, $E4, $E5, $E3, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E5, $E3, $E4
	dc.b	$E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E5, $E3, $E4, $E4, $E4, $E4, $E4, $E4, $E4
	dc.b	$E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E5, $E3, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4
	dc.b	$E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E5, $E3, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4, $E4
	dc.b	$E4, $E4, $E4, $E4, $E4, $E5, $E6, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7, $E8
UIBorder_LevelUp:
	dc.b	$E0, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E1, $E2, $E3, $E4, $4C, $45, $56, $45, $4C, $E4, $55, $50, $E4, $E5, $E6, $E7, $E7, $E7, $E7, $E7, $E7, $E7
	dc.b	$E7, $E7, $E7, $E8
