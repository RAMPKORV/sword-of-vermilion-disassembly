; ============================================================
; Print Macro
; ============================================================
; Sets the script source pointer for dialogue display
print macro strPtr
    MOVE.l  #strPtr, Script_source_base.w
    ENDM

; ============================================================
; PlaySound Macro
; ============================================================
; Plays a sound effect by ID
; Usage: PlaySound SOUND_MENU_CANCEL
;        PlaySound $00A8
PlaySound macro soundId
    MOVE.w  #soundId, D0
    JSR     loc_00010522
    ENDM
