;   
;   alu: arithmetic and logic words
;
code_negate:
;
;   Implements NEGATE
;   ( n1 -- n2 )
;
;   Negate n1, giving its arithmetic inverse n2. 
;
    fenter

    set_carry_0    
    ld  hl, 0
    pop de
    sbc hl, de
    push hl

    fret

code_plus:
;
;   Implements +
;   ( n1 | u1 n2 | u2 -- n3 | u3 )
;
;   Add n2 | u2 to n1 | u1, giving the sum n3 | u3. 
;
    fenter 

    pop hl
    pop de
    add hl, de
    push hl

    fret

code_dup:
;
;   Implements DUP
;   ( x -- x x )
;
;   Duplicate x.
;    
    fenter
    
    pop  hl
    push hl
    push hl

    fret

code_lshift:
;
;   Implements LSHIFT
;   ( x1 u -- x2 )
;
;   Perform a logical left shift of u bit-places on x1, giving x2. 
;   Put zeroes into the least significant bits vacated by the shift. 
;   An ambiguous condition exists if u is greater than or equal to 
;   the number of bits in a cell. 
 
    fenter
   
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
    ;

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
