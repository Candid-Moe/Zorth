;
;   fcall: implement CALL XXX with JP XXX, putting return
;          address in HL.
;
macro fcall address
    ld  hl, $+3
    jp  address
endm

;
;   fenter: copy return address in HL to return stack in IX
;
macro fenter
    dec ix              ; push address into return stack
    ld  (ix), h
    dec ix
    ld  (ix), l
endm

;
;   fret: execute a RET by JP to return rutine.
;
macro fret
    jp return
endm
    

