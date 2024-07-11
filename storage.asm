;   Zorth - (c) Candid Moe 2024
;   
;   Storage: All the variables, stack and work areas
;

defgroup {
    colon_sys
}

defc TRUE  = -1
defc FALSE = 0
new_line:   counted_string '\n'
space:      counted_string ' '
words:      counted_string "words:\n"

_MODE_EXECUTION: db TRUE
_BASE:      db  10
_SOURCE_ID: db  DEV_STDIN     ; 1 = keyboard
_gTIB:      db  0        ; #TIB, len of string in _TIB
_TIB:       defs 80     ; Input line
_gtIN:      dw   0      ; >IN, Index into TIB
_PAD:       defs 80     ; PAD is a counted string.
_PROMPT:    counted_string   "\n>"
_BOOT_MSG:  counted_string  "Zorth 0.1, Copyright (c) 2024 Candid Moe\n"

err_word_not_found: counted_string "Error: word not found: "
err_underflow:  counted_string "Error: stack underflow:"
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


