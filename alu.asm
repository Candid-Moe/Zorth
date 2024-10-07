;   Zorth - (c) Candid Moe 2024
;   
;   alu: arithmetic and logic words
;

code_false:
;
;   Implements FALSE 
;   ( -- false )
;
;   Return a false flag. 

    ld   bc, FALSE
    push bc
    jp   (hl)

code_true:
;
;   Implements TRUE
;   ( -- true )
;
;   Return a true flag, a single-cell value with all bits set. 

    ld   bc, TRUE
    push bc
    jp   (hl)

code_drop:
;
;   Implements DROP CORE
;   ( x -- )
;
;   Remove x from the stack. 
;
    pop bc
    jp  (hl)

code_invert:
;
;   Implements INVERT
;   ( x1 -- x2 )
;
;   Invert all bits of x1, giving its logical inverse x2. 
;
    pop bc

    ld  a, b
    cpl
    ld  b, a

    ld  a, c
    cpl
    ld  c, a

    push bc

    jp  (hl)

code_or:
;
;   Implements OR
;   ( x1 x2 -- x3 )
;
;   x3 is the bit-by-bit inclusive-or of x1 with x2. 

    pop bc
    pop de

    ld  a, b
    or  d
    ld  b, a

    ld  a, c
    or  e
    ld  c, a

    push bc

    jp (hl)

code_xor:
;
;   Implements XOR
;   ( x1 x2 -- x3 )
;
;   x3 is the bit-by-bit exclusive-or of x1 with x2. 
;
    pop     bc
    pop     de

    ld      a, b
    xor     d
    ld      b, a

    ld      a, c
    xor     e
    ld      c, a

    push    bc

    jp (hl)

    
code_and:
;
;   Implements AND
;
;   ( x1 x2 -- x3 )
;
;   x3 is the bit-by-bit logical "and" of x1 with x2. 
;
    pop     bc
    pop     de

    ld      a, b
    and     d
    ld      b, a

    ld      a, c
    and     e
    ld      c, a

    push    bc

    jp  (hl)

code_negate:
;
;   Implements NEGATE
;   ( n1 -- n2 )
;
;   Negate n1, giving its arithmetic inverse n2. 
;
    ld  bc, hl

    set_carry_0    
    ld  hl, 0
    pop de
    sbc hl, de
    push hl

    ld  hl, bc
    jp  (hl)

code_plus:
;
;   Implements +
;   ( n1 | u1 n2 | u2 -- n3 | u3 )
;
;   Add n2 | u2 to n1 | u1, giving the sum n3 | u3. 
;
    ld  bc, hl  ; Save return address

    pop hl
    pop de

    add hl, de

    push hl

    ld  hl, bc  ; return 
    jp  (hl)

code_minus:
;
;   Implements -
;
;   ( n1 | u1 n2 | u2 -- n3 | u3 )
;
;   Subtract n2 | u2 from n1 | u1, giving the difference n3 | u3.
;
    ld  bc, hl

    pop de
    pop hl
    or  a       ; set carry = 0
    sbc hl, de
    push hl

    ld  hl, bc
    jp  (hl)

code_star:
;
;   Implements *
;   ( n1 | u1 n2 | u2 -- n3 | u3 )
;
;   Multiply n1 | u1 by n2 | u2 giving the product n3 | u3. 
;
    fenter 
    
    pop hl
    pop de

    call l_small_mul_16_16x16

    push hl

	fret

code_s_to_d:
;
;   Implements S>D
;   ( n -- d )
;
;   Convert the number n to the double-cell number d with the same numerical val

    fenter

    pop     hl
    push    hl                  ; low word

    bit     7, h
    jr      z, _code_s_to_d_pos
    ;   Negative
    ld      hl, $FFFF
    jr      _code_s_to_d_end

_code_s_to_d_pos:
    ld      hl, 0

_code_s_to_d_end:
    push    hl                  ; high word
    fret

code_m_star:
;
;   Implements M* 
;   ( n1 n2 -- d )
;
;   d is the signed product of n1 times n2. 
;
    fenter

    pop     hl
    ctrl_push    
    fcall   code_s_to_d
    ctrl_pop
    push    hl
    fcall   code_s_to_d

    pop     de
    pop     hl
    exx
    pop     de
    pop     hl
    exx
    
    call l_small_muls_32_32x32

    push hl
    push de

    fret
    
code_u_m_star:
;
;   Implements UM* 
;
;   ( u1 u2 -- ud )
;
;   Multiply u1 by u2, giving the unsigned double-cell product ud. 
;   All values and arithmetic are unsigned. 
;
    fenter 

    pop hl
    pop de

    call l_small_mul_32_16x16

    push hl
    push de

    fret

code_s_m_slash_rem:
;
;   Implements SM/REM 
;   ( d1 n1 -- n2 n3 )
;
;   Divide d1 by n1, giving the symmetric quotient n3 and the remainder n2.
;   Input and output stack arguments are signed. 
;   An ambiguous condition exists if n1 is zero or if the quotient lies outside 
;   the range of a single-cell signed integer. 

    fenter

    pop hl

    bit 0, h            ; Expand hl sign into de
    jr  z, _zero_op
    ld  de, $FFFF
    jmp _code_s_m_slash_rem2

_zero_op:
    ld  de, 0       ; divisor

_code_s_m_slash_rem2:
    exx

    pop de          ; dividend
    pop hl
    exx

    call l_small_divs_32_32x32

    exx
    push hl     ; remainder
    exx
    push hl     ; quotient

    fret

code_slash_mod:
;
;   Implements /MOD 
;   ( n1 n2 -- n3 n4 )
;
;   Divide n1 by n2, giving the single-cell remainder n3 and the single-cell quotient n4. 
;   An ambiguous condition exists if n2 is zero. 
;   If n1 and n2 differ in sign, the implementation-defined result returned will be the 
;   same as that returned by either the phrase >R S>D R> FM/MOD or the 
;   phrase >R S>D R> SM/REM.    
;

    fenter

    pop     de  ; divisor
    pop     hl  ; dividend

    call    l_small_divs_16_16x16
    
    push    de  ; remainder
    push    hl  ; quotient

    fret

code_ud_slash_mod:
;
;   Implements ud/mod 
;   ( ud1 u2 – urem udquot  ) gforth-0.2 “ud/mod”
;
;   Divide unsigned double ud1 by u2, resulting in a unsigned double
;   quotient udquot and a single remainder urem. 
;

    fenter

    pop hl

    bit 0, h            ; Expand hl sign into de
    jr  z, _code_ud_slash_mod_op
    ld  de, $FFFF
    jmp _code_ud_slash_mod2

_code_ud_slash_mod_op:
    ld  de, 0       ; divisor

_code_ud_slash_mod2:

    exx
    pop de          ; dividend
    pop hl
    exx

    call l_small_divu_32_32x32

    exx    
    push hl     ; remainder
    exx
    push hl     ; quotient
    push de

    fret

code_dup:
;
;   Implements DUP
;   ( x -- x x )
;
;   Duplicate x.
;    
    pop  bc
    push bc
    push bc

    jp  (hl)

code_swap:
;
;   Implements SWAP
;   ( x1 x2 -- x2 x1 )
;
;   Exchange the top two stack items. 
;
    pop de
    pop bc
    push de
    push bc
    
    jp  (hl)

code_pick:
;
;   Implements PICK
;   ( xu...x1 x0 u -- xu...x1 x0 xu )
;
;   Remove u. Copy the xu to the top of the stack. 
;   An ambiguous condition exists if there are less than u+2 items 
;   on the stack before PICK is executed. 
;
    fenter

    pop bc  ; u
    ld  hl, sp
    add hl, bc
    add hl, bc
    
    ld  bc, (hl)
    push bc

    fret

code_rshift:
;
;   Implements RSHIFT 
;   ( x1 u -- x2 )
;
;   Perform a logical right shift of u bit-places on x1, giving x2. 
;   Put zeroes into the most significant bits vacated by the shift. 
;   An ambiguous condition exists if u is greater than or equal to the 
;   number of bits in a cell. 
;
    ld  de, hl  ; save return address
   
    pop bc      
    ld  b, c    ; b = how many bits to shift
    pop hl      ; x1

    xor a
    cp  b
    jz  _code_rshift_end

_code_rshift_cycle:

    srl  h      ;   Shift right high byte by 1, bit0 -> carry    
    ld  a, l    
    rra         ;   Shift low byte by 1, carry -> bit7
    ld  l, a

    djnz _code_rshift_cycle

_code_rshift_end:

    push hl
    ld   hl, de
    jp  (hl)

code_lshift:
;
;   Implements LSHIFT
;   ( x1 u -- x2 )
;
;   Perform a logical left shift of u bit-places on x1, giving x2. 
;   Put zeroes into the least significant bits vacated by the shift. 
;   An ambiguous condition exists if u is greater than or equal to 
;   the number of bits in a cell. 
 
    ld  de, hl  ; save return address
   
    pop bc      
    ld  b, c    ; b = how many bits to shift
    pop hl      ; x1

    xor a
    cp  b
    jz  _code_lshift_end

_code_lshift_cycle:

    ld  a, l    ;   Shift low byte by 1
    sla a
    ld  l, a

    ld  a, h    ;   Shift high byte by 1
    rl  a
    ld  h, a
    
    djnz _code_lshift_cycle

_code_lshift_end:

    push hl
    ld   hl, de
    jp  (hl)

code_two_slash:
;
;   Implements 2/
;   ( x1 -- x2 )
;
;   x2 is the result of shifting x1 one bit toward the least-significant bit,
;   leaving the most-significant bit unchanged. 
;

    pop     bc
    ld      a, c
    sra     b
    rra     
    ld      c, a
    push    bc

    jp  (hl)

classify_signs:
;
;   Classify two values
;   HL  First value
;   DE  Second value
;
;   Result in A:
;
;   00  Both equal signs
;   01  HL positive, DE negative
;   10  HL negative, DE positive
;
    xor a

    bit 7, h
    jr  z, classify_second
    or  2

classify_second:
    bit 7, d
    jr  z, classify_both
    or  1

classify_both:
    cp  3   ; both negative
    jr  nz, classify_end
    xor a   ; both equal signs
classify_end:
    ret

code_less_than:
;
;   Implements < 
;   ( n1 n2 -- flag )
;
;   flag is true if and only if n1 is less than n2. 
;
    fenter
    
    pop de      ; n2
    pop hl      ; n1
    call classify_signs

    cp  1       ; +n1 > -n2
    jr  nz, _code_less_2
    ld  hl, FALSE
    jr  code_less_than_end

_code_less_2:
    cp  2       ; -n1 < +n2
    jr  nz, _code_less_3
    ld  hl, TRUE
    jr  code_less_than_end

_code_less_3:       ; equal sign
    set_carry_0
    sbc hl, de      ;   hl - de
    jp  p, _code_less_4
    ld  hl, TRUE
    jr  code_less_than_end

_code_less_4:

    ld  hl, FALSE

code_less_than_end:
    push    hl
    
    fret  
    
code_greater_than:
;
;   Implements > 
;   ( n1 n2 -- flag )
;
;   flag is true if and only if n1 is greater than n2. 

    fenter

    fcall code_swap
    fcall code_less_than

    fret
    
code_equals:
;
;   Implements =
;   ( x1 x2 -- flag )
;
;   flag is true if and only if x1 is bit-for-bit the same as x2. 
;
    fenter

    pop hl
    pop de

    set_carry_0
    sbc hl, de
    ld  hl, FALSE
    jr  nz, code_equals_end
    ld  hl, TRUE

code_equals_end:
    
    push    hl
    
    fret

code_u_less_than:
;
;   Implements U< u-less-than
;   ( u1 u2 -- flag )
;
;   flag is true if and only if u1 is less than u2. 

    fenter

    pop de
    pop hl
    set_carry_0
    sbc hl, de
    
    jr  z, _code_u_less_false
    jr  nc, _code_u_less_false
    ld  hl, TRUE
    jr  _code_u_less_end

_code_u_less_false:
    ld  hl, FALSE
_code_u_less_end:
    push    hl

    fret

code_u_greater_than:
;   
;   Implements U>
;   ( u1 u2 -- flag )
;
;   flag is true if and only if u1 is greater than u2. 

    fenter

    fcall code_swap
    fcall code_u_less_than

    fret

code_z80_syscall:
;
;   Implements Z80-CALL
;   ( hl de bc a -- a' bc' de' hl' )
;
    fenter
    
    pop hl
    ld  a, l
    pop bc
    pop de
    pop hl

    SYSCALL

    push hl
    push de
    push bc
    ld  b, 0
    ld  c, a
    push bc
    
    fret

multiply_by_10:
;   ( n -- n * 10 )
;
;   n * 10 = n * (2 + 8)
;   n * 10 = n << 1 + n << 3

    fenter

    ld    hl, 1
    push  hl    
    fcall code_lshift   
    fcall code_dup
    ld    hl, 2         ; TOS is already shifted 1 place
    push  hl
    fcall code_lshift
    fcall code_plus

    fret

is_hex_digit:
    ;   
    ;   Test if A is 0-9, a-f, A-F
    ;   Return 1 in A if true, 0 otherwise
    ;   (use call, not fcall)

_is_hex_digit_A:
    cp 'A'
    jr  c, _is_hex_digit_a
    cp 'F' + 1
    jr  c, _is_digit_success

_is_hex_digit_a:
    cp 'a'
    jr  c, is_digit
    cp 'f' + 1
    jr  c, _is_digit_success

is_digit:
    ;
    ;   Test if A is an ascii digit 0-9
    ;   Return 1 in A if true, 0 otherwise
    ;   (use call, not fcall)
    ;
    cp '0' 
    jr  c, _is_digit_fail
    cp '9' + 1
    jr  c, _is_digit_success

_is_digit_fail:    
    ld  a, 0
    ret
_is_digit_success:
    ld a, 1
    ret
