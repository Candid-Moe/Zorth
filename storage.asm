;   Zorth - (c) Candid Moe 2024
;   
;   Storage: All the variables, stack and work areas
;

defgroup {
    colon_sys = 1,
    do_sys,
    leave_sys,
    case_sys,
    of_sys
}

defc TRUE  = -1
defc FALSE = 0
defc BIT_COLON  = 1
defc BIT_IMMEDIATE = 2
defc STACK_SIZE = 128    
   
line_terminator:    db 0x0a

words:      counted_string "words:\n"
boot_file:  counted_string "forth.fs\000"

_EXIT:      dw   0          ;
_STATE:     dw   FALSE      ; True in compilation state, false otherwise
_DISCARD:   dw   FALSE      ; Discard next words until ';'
_BASE:      dw   10
_SOURCE_ID: dw   0          ; 0 = keyboard -1 = string
_gTIB:      dw   0          ; #TIB, len of string in _TIB
_TIB:       defs 80         ; Input line
gTIB:       dw  _gTIB
TIB:        dw  _TIB
_gtIN:      dw   0          ; >IN, Index into TIB
_PAD:       defs 80         ; PAD is a counted string.
_HEAP:      dw  $FFFD       ; Pointer to heap, grows downward.

_PROMPT:    counted_string  "\n>"
_BOOT_MSG:  counted_string  "Zorth 0.2, Copyright (c) 2024 Candid Moe\n"

err_word_not_found: counted_string "Error. Word not found: "
err_underflow:      counted_string "Error. Data Stack underflow.\n"
err_missing_name:   counted_string "Error. Attempt to use zero-length string as a name.\n"
err_mode_comp:      counted_string "Error. Already in compilation mode.\n"
err_mode_not_comp:  counted_string "Error. Not valid in interpreter mode: "
err_unstructed:     counted_string "Error. Unstructed.\n"
err_in_word:        counted_string " in word "
err_file_not_found: counted_string "Error. File not found."
err_bad_source:     counted_string "Bad SOURCE-ID for refill."

;------ Forth Leave Stack ------
;
        defs    STACK_SIZE
_LEAVE_STACK:
_L_GUARD:   dw 0x5050
_IX_LEAVE:  dw _LEAVE_STACK

;------ Forth Control Stack -----
;
        defs    STACK_SIZE
_CONTROL_STACK:
_C_GUARD:   dw   0x5050
_IX_CONTROL: dw _CONTROL_STACK

;----- Forth Execution Stack ----
;   This stack is indexed by IY
;
        defs    STACK_SIZE
_EX_STACK:
_X_GUARD:   dw 0x5050
;------ Forth Return Stack ------
;   This stack is indexed by IX
;
        defs    STACK_SIZE
_RETURN_STACK:
_R_GUARD:   dw   0x5050
            defs 10
;------ Forth Data Stack -----
;   This stack is indexed by SP
;
        defs    STACK_SIZE
_DATA_STACK:
_S_GUARD:   dw   0x5050
            defs 10
; ---- HEAP -----
; Heap extend up to 0xFFFF
;
_DICT:          dw 0    ; Forth dictionary
    
_DP:    dw $ + 2

        defs 4096

lstoff
defc _src_start = $
binary "forth.fs"
defc _src_end = $
_SRC_SIZE: dw _src_end - _src_start
lston
