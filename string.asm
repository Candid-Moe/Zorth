;   Zorth - (c) Candid Moe 2024

;   string: string operations

code_cmove:
;
;   Implements CMOVE
;   ( c-addr1 c-addr2 u -- )
;
;   If u is greater than zero, copy u consecutive characters from 
;   the data space starting at c-addr1 to that starting at c-addr2, 
;   proceeding character-by-character from lower addresses to 
;   higher addresses. 
;
    jp  code_move

code_str_equals:
;   
;   Implements STR=
;   ( c-addr1 u1 c-addr2 u2 – flag )
;
;   Compare string for equality (gforth extension)
;
;   Return TRUE if equals, FALSE in other case
;
    fenter

    pop bc      ; u2
    ld  a, c    ; A = u2
    pop hl      ; c-addr2
    pop bc      ; BC = u1
    pop de      ; c-addr1

    cp c        ; u1 == u2 ? Lenght < 256
    jr nz, _code_str_equals_false

_code_str_equals_cycle:    
    ; Same length, compare contents
    ; B = count
    ld  a, (de)
    cpi
    jr  nz, _code_str_equals_false
    inc de
    jump_non_zero c, _code_str_equals_cycle
    ;   Else, all chars are equals

_code_str_equals_true:
    ld  hl, TRUE
    jr  _code_str_end
        
_code_str_equals_false:
    ld  hl, FALSE

_code_str_end:
    push hl
    fret

code_str_equals_i:
;   
;   Implements STRI=
;   ( c-addr1 u1 c-addr2 u2 – flag ) 
;
;   Compare string for equality (case insensitive)
;
;   Return TRUE if equals, FALSE in other case
;
    fenter

    pop bc      ; u2
    ld  a, c    ; A = u2
    pop hl      ; c-addr2
    pop bc      ; BC = u1
    pop de      ; c-addr1

    cp c        ; u1 == u2 ? Lenght < 256
    jr nz, _code_stri_equals_false

_code_stri_equals_cycle:    
    ; Same length, compare contents

    ; C = count
    xor a
    cp  c
    jr  z, _code_stri_equals_true
    dec c

    ld  a, (de)
    call to_lower
    ld  b, a
    ld  a, (hl)
    call to_lower
    cp  b
    inc hl
    inc de
    jr  z, _code_stri_equals_cycle
    
_code_stri_equals_false:
    ld   hl, FALSE
    push hl
    fret

_code_stri_equals_true:
    ld   hl, TRUE
    push hl
    fret
        

to_lower:
;
;   Convert A to lower case
;
    cp      'A'
    jr      c,  _to_lower_end
    cp      'Z' + 1
    jr      nc, _to_lower_end

    sub     'A'
    add     'a'
    
_to_lower_end:

    ret



