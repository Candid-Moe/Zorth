;   Zorth - (c) Candid Moe 2024
;   
;   Storage: All the variables, stack and work areas
;

defgroup {
    colon_sys = 1,
    do_sys,
    leave_sys
}

defc TRUE  = -1
defc FALSE = 0
defc BIT_COLON  = 1
defc BIT_IMMEDIATE = 2
new_line:   counted_string '\n'
space:      counted_string ' '
words:      counted_string "words:\n"
boot_file:  counted_string "forth.fs\000"

_STATE:     dw   FALSE      ; True in compilation state, false otherwise
_BASE:      dw   10
_SOURCE_ID: db   DEV_STDIN  ; 1 = keyboard
_gTIB:      db   0          ; #TIB, len of string in _TIB
_TIB:       defs 80         ; Input line
gTIB:       dw  _gTIB
TIB:        dw  _TIB
_gtIN:      db   0          ; >IN, Index into TIB
_PAD:       defs 80         ; PAD is a counted string.

_PROMPT:    counted_string  "\n>"
_BOOT_MSG:  counted_string  "Zorth 0.1, Copyright (c) 2024 Candid Moe\n"

err_word_not_found: counted_string "Error. Word not found: "
err_underflow:      counted_string "Error. Data Stack underflow"
err_missing_name:   counted_string "Error. Attempt to use zero-length string as a name"
err_mode_comp:      counted_string "Error. Already in compilation mode"
err_mode_not_comp:  counted_string "Error. Not valid in interpreter mode: "
err_unstructed:     counted_string "Error. Unstructed: "

;------ Forth Leave Stack ------
;
        defs 128
_LEAVE_STACK:
_L_GUARD:   dw 0x5050
_IX_LEAVE:  dw _LEAVE_STACK
;------ Forth Control Stack -----
;   This stack is indexed by YX
;
            defs 128
_CONTROL_STACK:
_C_GUARD:   dw   0x5050
            defs 10 
;------ Forth Return Stack ------
;   This stack is indexed by IX
;
            defs    128
_RETURN_STACK:
_R_GUARD:   dw   0x5050
            defs 10
;------ Forth Data Stack -----
;   This stack is indexed by SP
;
            defs    128
_DATA_STACK:
_S_GUARD:   dw   0x5050
            defs 10
; ---- HEAP -----
; Heap extend up to 0xFFFF
;
_DICT:  dw 0        ; Pointer to last entry in Forth dictionary
    
_DP:    dw $ + 2


