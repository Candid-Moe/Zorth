_SOURCE_ID: dw 0        ; 0 = keyboard
_TIB:       defs 80     ; Input line
_gtIN:      dw   0      ; >IN, Index into TIB
_PAD:       defs 80
_PROMPT:    db   2, "\n>"
;------ Forth Return Stack ------
;   This stack is indexed by IX
;
         defs    128
_RETURN_STACK:
;------ Forth Data Stack -----
;   This stack is indexed by SP
;
        defs 128
_DATA_STACK:
; ---- HEAP -----
_DP:         defs 1024


