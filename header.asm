	include "macros.asm"
	include "constants.asm"
StartOfRom:
loc_00000000:
	dc.l	$FFFFFE00 			; Initial stack pointer value
BusError:
	dc.l	EntryPoint 			; Start of program
	dc.l	ErrorTrap 			; Bus error
AddressError:
	dc.l	ErrorTrap 			; Address error (4)
IllegalInstruction:
	dc.l	ErrorTrap			; Illegal instruction
	dc.l	ErrorTrap			; Division by zero
	dc.l	ErrorTrap			; CHK exception
	dc.l	ErrorTrap			; TRAPV exception (8)
	dc.l	ErrorTrap			; Privilege violation
	dc.l	ErrorTrap			; TRACE exception
	dc.l	ErrorTrap			; Line-A emulator
	dc.l	ErrorTrap			; Line-F emulator (12)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved) (16)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved) (20)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved) (24)
	dc.l	ErrorTrap			; Spurious exception
	dc.l	ErrorTrap			; IRQ level 1
	dc.l	ErrorTrap			; IRQ level 2
	dc.l	ErrorTrap			; IRQ level 3 (28)
	dc.l	ErrorTrap			; IRQ level 4 (horizontal retrace interrupt)
	dc.l	ErrorTrap			; IRQ level 5
	dc.l	VerticalInterrupt 	; IRQ level 6 (vertical retrace interrupt)
	dc.l	ErrorTrap			; IRQ level 7 (32)
	dc.l	ErrorTrap			; TRAP #00 exception
	dc.l	ErrorTrap			; TRAP #01 exception
	dc.l	ErrorTrap			; TRAP #02 exception
	dc.l	ErrorTrap			; TRAP #03 exception (36)
	dc.l	ErrorTrap			; TRAP #04 exception
	dc.l	ErrorTrap			; TRAP #05 exception
	dc.l	ErrorTrap			; TRAP #06 exception
	dc.l	ErrorTrap			; TRAP #07 exception (40)
	dc.l	ErrorTrap			; TRAP #08 exception
	dc.l	ErrorTrap			; TRAP #09 exception
	dc.l	ErrorTrap			; TRAP #10 exception
	dc.l	ErrorTrap			; TRAP #11 exception (44)
	dc.l	ErrorTrap			; TRAP #12 exception
	dc.l	ErrorTrap			; TRAP #13 exception
	dc.l	ErrorTrap			; TRAP #14 exception
	dc.l	ErrorTrap			; TRAP #15 exception (48)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved) (52)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved) (56)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved) (60)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved)
	dc.l	ErrorTrap			; Unused (reserved) (64)
Header:
	dc.b "SEGA_MEGA_DRIVE " 	; Console name
	dc.b "(C)SEGA 1990.SEP" 	; Copyright holder and release date
	dc.b "VERMILION                                       " ; Domestic name
	dc.b "SWORD OF VERMILION                              " ; International name
	dc.b "GM 00005502-00" 		; Version
InitZ80:
	dc.w	$06B5 				; Checksum
	dc.b	'J               '
	dc.l StartOfRom
;loc_000001A4:
ROMEndLoc:
	dc.l EndOfRom-1
	dc.l $00FF0000 		; Start of RAM
	dc.l $00FFFFFF 		; End of RAM
	dc.l $5241F820		; Backup RAM ID
	dc.l $00200001		; Backup RAM start address
	dc.l $00203FFF		; Backup RAM end address
	dc.b "            "	; Modem support
	dc.b "                                        "	; Notes (unused, anything can be put in this space, but it has to be 52 bytes.)
	dc.b "U               " ; Region
