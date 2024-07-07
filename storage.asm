;   Word class
defgroup    {
    class_integer,
    class_hexadecimal,
    class_word
    }

TRUE:       dw -1
FALSE:      dw  0
new_line:   counted_string '\n'
space:      counted_string ' '
words:      counted_string "words:\n"
_SOURCE_ID: db   DEV_STDIN     ; 1 = keyboard
_gTIB:      db  0        ; #TIB, len of string in _TIB
_TIB:       defs 80     ; Input line
_gtIN:      dw   0      ; >IN, Index into TIB
_PAD:       defs 80     ; PAD is a counted string.
_PROMPT:    counted_string   ">"
_BOOT_MSG:  counted_string  "Zorth 0.1, Copyright (c) 2024 Candid Moe\n"
_test:      counted_string "0x1234 25 +"
err_word_not_found: counted_string "Error: word not found\n"
;------ Forth Return Stack ------
;   This stack is indexed by IX
;
            defs    128
_RETURN_STACK:
;------ Forth Data Stack -----
;   This stack is indexed by SP
;
            defs    128
_DATA_STACK:

; ---- HEAP -----
; Heap extend up to 0xFFFF
;
_DICT:  dw 0        ; Pointer to last entry in Forth dictionary
    
_DP:    dw $ + 2


