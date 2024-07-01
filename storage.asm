TRUE:       dw -1
FALSE:      dw  0
_SOURCE_ID: db   DEV_STDIN     ; 1 = keyboard
_gTIB:      db  0        ; #TIB, len of string in _TIB
_TIB:       defs 80     ; Input line
_gtIN:      dw   0      ; >IN, Index into TIB
_PAD:       defs 80     ; PAD is a counted string.
_PROMPT:    counted_string   ">"
_BOOT_MSG:  counted_string  "Zorth 0.1, Copyright (c) 2024 Candid Moe\n"
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
_DP:         

