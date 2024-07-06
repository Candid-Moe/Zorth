;
;   fcall: implement CALL XXX with JP XXX, putting return
;          address in HL.
;
macro fcall address
local next_inst
    ld  hl, next_inst
    jp  address
next_inst:
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
    
macro counted_string text
local start
local end
        db end - start
start:  db text
end:
endm

;   
;   Add 1 to the byte at address.
;
macro inc_byte  address
    ld  a, (address)
    inc a
    ld (address), a
endm

;
;   Decrement by 1 byte at address
;
macro dec_byte address
    ld  a, (address)
    dec a
    ld (address), a
endm

macro set_carry_0
    scf
    ccf
endm

