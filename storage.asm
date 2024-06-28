TRUE:       dw -1
FALSE:      dw  0
_SOURCE_ID: db  1      ; 1 = keyboard
_TIB:       defs 80     ; Input line
_gtIN:      dw   0      ; >IN, Index into TIB
_PAD:       defs 80
_PROMPT:    counted_string   ">"
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


