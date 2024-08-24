l0_small_mul_32_16x16:

    ; multiplication of two 16-bit numbers into a 32-bit product
    ;
    ; enter : hl'= 16-bit multiplier   = y
    ;         hl = 16-bit multiplicand = x
    ;
    ; exit  : dehl = 32-bit product
    ;         carry reset
    ;
    ; uses  : af, bc, de, hl, bc', de', hl'

    push hl
    exx
    pop de
    jp l_small_mul_32_16x16

l_small_mul_32_32x32:

    ; multiplication of two 32-bit numbers into a 32-bit product
    ;
    ; enter : dehl = 32-bit multiplicand (more leading zeroes = better performance)
    ;         dehl'= 32-bit multiplier
    ;
    ; exit  : dehl = 32-bit product
    ;         carry reset
    ;
    ; uses  : af, bc, de, hl, bc', de', hl'

    ld a,e
    or d
    exx

    or e
    or d
    jr Z,l0_small_mul_32_16x16  ; demote if both are uint16_t

    xor a
    push hl
    exx
    ld bc,hl
    pop hl
    push de
    ex de,hl
    ld l,a
    ld h,a
    exx
    pop bc
    ld l,a
    ld h,a

l0_small_mul_32_32x32:

    ; dede' = 32-bit multiplicand
    ; bcbc' = 32-bit multiplicand
    ; hlhl' = 0

    ld a,b
    ld b,32

loop_0m:

    rra
    rr c
    exx
    rr b
    rr c
    jr nc, loop_1m

    add hl,de
    exx
    adc hl,de
    exx

loop_1m:

    sla e
    rl d
    exx
    rl de

    djnz loop_0m

    push hl
    exx
    pop de

    or a
    ret
