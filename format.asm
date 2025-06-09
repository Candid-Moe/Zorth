;   Zorth - (c) Candid Moe 2024
;
;   format: words for formatting values <# #>
;

defc FMT_SIZE = 40
fmt_str:    defs FMT_SIZE
defc FMT_LAST = $ - 1

fmt_len:    dw  0
fmt_ptr:    dw  FMT_LAST

_table:     defb "0123456789ABCDEF"

code_less_number_sign:
;
;   Implements <#
;   ( -- )
;
;   Initialize the pictured numeric output conversion process. 
;
    fenter

    xor a
    ld  (fmt_len), a

    ld  hl, FMT_LAST
    ld  (fmt_ptr), hl

    ; If high word is exactly $FFFF, replace with 0

    set_carry_0
    pop de
    ld  hl, TRUE
    sbc hl, de
    jr  nz, _code_less_number_sign_end
    ld  de, 0

_code_less_number_sign_end:

    push de
    fret

code_number_sign:
;
;   Implements #
;   ( ud1 -- ud2 )
;
;   Divide ud1 by the number in BASE giving the quotient ud2 and the
;   remainder n. (n is the least significant digit of ud1.) 
;   Convert n to external form and add the resulting character to the
;   beginning of the pictured numeric output string. 
;   An ambiguous condition exists if # executes outside of a 
;   <# #> delimited number conversion. 
    
    fenter

    ld      bc, (_BASE)
    push    bc

    fcall   code_ud_slash_mod
    
    pop     bc
    pop     hl
    pop     de          ; Remainder
    push    hl
    push    bc

    ld      hl, _table
    add     hl, de      ; HL = @table + remainder

    ld      a, (hl)     ; The ascii for remainder
    ld      hl, (fmt_ptr)
    ld      (hl), a     ; out the ascii value for digit

    dec     hl    
    ld      (fmt_ptr), hl ; fmt_ptr--

    fret

code_number_sign_s:
;
;   Implements #S 
;   ( ud1 -- ud2 )
;
;   Convert one digit of ud1 according to the rule for #. 
;   Continue conversion until the quotient is zero. ud2 is zero. 
;   An ambiguous condition exists if #S executes outside of a <# #>
;   delimited number conversion. 
;
    fenter

_code_number_sign_s_cycle:

    fcall code_number_sign

    pop hl
    pop de
    
    push de
    push hl

    ld  a, h
    cp  l
    jr  nz, _code_number_sign_s_cycle

    ld  a, d
    cp  e
    jr  nz, _code_number_sign_s_cycle

    ;   Double value is zero

    fret

code_hold:
;
;   Implements HOLD
;   ( char -- )
;
;   Add char to the beginning of the pictured numeric output string. 
;   An ambiguous condition exists if HOLD executes outside of a <# #>
;   delimited number conversion. 
;
    fenter

    pop bc

    ld  hl, (fmt_ptr)
    ld  (hl), c
    
    dec hl
    ld  (fmt_ptr), hl

    fret

code_number_sign_greater:
;
;   Implements #>
;   ( xd -- c-addr u )
;
;   Drop xd. 
;   Make the pictured numeric output string available as a character string.
;   c-addr and u specify the resulting character string. 
;   A program may replace characters within the string.     
;
    fenter

    pop     hl
    pop     hl

    ld      hl, (fmt_ptr)
    inc     hl
    push    hl              ; string address

    set_carry_0
    ld      de, FMT_LAST
    ex      hl, de
    sbc     hl, de
    inc     hl
    push    hl              ; string len

    fret

code_sign:
;
;   Implements SIGN 
;   ( n -- )
;
;   If n is negative, add a minus sign to the beginning of the pictured 
;   numeric output string. An ambiguous condition exists if SIGN executes 
;   outside of a <# #> delimited number conversion. 
;
    fenter

    pop     hl
    ld      a, h
    and     $80
    jr      z, _code_sign_end

    ;   Negative; put a "-" in front.

    ld      hl, (fmt_ptr)
    ld      (hl), '-'    

    dec     hl    
    ld      (fmt_ptr), hl ; fmt_ptr--

_code_sign_end:

    fret
