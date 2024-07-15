;   Zorth - (c) Candid Moe 2024

;
;   itoa: routines to edit values
;

itoa:
;
;   Convert signed value to ASCII.
;   ( n -- )
;
;   Result in PAD
;
    fenter

    pop de          ; DE is the value to conver
    
    ;   Special case 1: value == 0
    ld  a, d
    or  e
    jr  nz, _itoa_sign

    ld  a, 1
    ld  (_PAD), a
    ld  a, '0'
    ld  (_PAD + 1), a

    ld      hl, _PAD    ; HL point to output text area
    push    hl
    jr  _itoa_end

_itoa_sign:

    ;   Special case 2: value is negative
    bit 7, d
    jz  _itoa_positive

    ;   Case negative value
    ;   Make it positive and add '-' in front of result

    push de
    fcall   code_negate
    pop     de

    ld      hl, _PAD
    inc     hl          ; Reserve one byte for the count
    inc     hl          ; Reserve another byte for sign

    call    itoa_16

    dec     hl          ; back a byte and put '-' in front
    ld      (hl), '-'
    jr      _itoa_len

_itoa_positive:
    ;   Case positive value

    ld      hl, _PAD
    inc     hl          ; Reserve one byte for the count

    call itoa_16

_itoa_len:
    ;   Convert ASCIIZ to counted string
    ;   hl -> start asciiz
    push    hl          ; Push edited value star address (it's not same as _PAD)

    ;   Search the final 0
    ld  bc, 0
    ld  a, 0

    cpir

    sub  a, c       ; Made count in c positive
    dec  a

    pop  hl
    dec  hl
    ld   (hl), a     ; Store count 
    
    push    hl

_itoa_end:

    fret
