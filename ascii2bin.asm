;   Zorth - (c) Candid Moe 2024
;
;   ascii2bin: Convert ASCII numeric values to binary
;
;   Accept numbers, possibly with the following prefix
;   
;    # – decimal
;    % – binary
;    $ – hexadecimal
;    & – decimal (non-standard)
;    0x – hexadecimal (non-standard). 
;
;   Also convert single char 'c' to his ASCII value
;
;   For negative numbers, start it with '-'
;

code_ascii2bin:

    fenter
    
    ld  hl, _PAD
    push hl
    fcall ascii2bin

    fret

_ascii2bin_advance:
    ;
    ;   Advance DE, pointer to digit
    ;   Decrement len
    ;   Set Z flag if len == 0
    ;
    inc de
    dec_byte _ascii2bin_count     
    ret

ascii2bin:
;
;   Convert an ascii numeric value to binary
;
;   ( c-addr -- value flag)
;
;   flag is TRUE is the number is a valid value
;
    fenter 

    pop de
    ld  a, (de) ; a = string len
    ld (_ascii2bin_count), a 
    ld  a, 0    ; Initialize to keep track of sign handling
    ld (_ascii2bin_sign), a

    inc de
    
    ;   Check for a valid prefix. 
    ld  a, (de)
    cp  '-'     
    jr  nz, _ascii2bin_prefix
    
    ; It start with '-'

    ld  a, 1
    ld (_ascii2bin_sign), a     ; remember sign
    call _ascii2bin_advance     ; It can't be only "-"
    
_ascii2bin_prefix:
    ;
    ;   Use the prefix to set the base
    ;
    ld  a, (de)

    cp  '$'
    jr  z, _ascii2bin_hex_pre
    cp  '#'
    jr  z, _ascii2bin_int_pre
    cp '&'
    jr  z, _ascii2bin_int_pre
    cp '%'
    jp  z, _ascii2bin_bin_pre
    cp '\''
    jp  z, _ascii2bin_char_pre

    cp  '0'
    jr  nz, _ascii2bin_base

    call _ascii2bin_advance
    jr  z, _ascii2bin_int_0      ; It's only "0"

    ld  a, (de)    
    cp  'x'
    jr  nz, _ascii2bin_prefix_X
    jr  _ascii2bin_hex_pre

_ascii2bin_prefix_X:
    cp  'X'
    jr  nz, _ascii2bin_base
    jr  _ascii2bin_hex_pre

_ascii2bin_base:    
    ;   It's not hex, use BASE
    ld  a, (_BASE)
    cp 2
    jr  z, _ascii2bin_bin
    cp 10
    jr  z, _ascii2bin_int
    cp 16
    jr  z, _ascii2bin_hex

    jp  _ascii2bin_error
    
_ascii2bin_int_pre:
    ;   Number start with a prefix
    call _ascii2bin_advance
    jp  z, _ascii2bin_error ; Error: only prefix

_ascii2bin_int:
;   
;   Convert ASCII integer area to binary
;
    ld      hl, 0   ; hl = result 

_ascii2bin_int_cycle:
    ;   
    ; Convert ASCII digit to binary (subtract ASCII '0')

    ld      a, (de) ; Load the next character of the string
    call    is_digit
    cp      0
    jp      z, _ascii2bin_error

    ld      a, (de) ; Reload
    sub     '0'
    ld      b, 0
    ld      c, a

    ; Multiply current result by 10 (HL = HL * 10)
    push    de
    push    bc
    push    hl
    fcall   multiply_by_10
    pop     hl
    pop     bc
    add     hl, bc
    pop     de

    call _ascii2bin_advance
    jr   z, _ascii2bin_adjust ; Continue until end of string
    jr  _ascii2bin_int_cycle

_ascii2bin_int_0:
    ;   Special case: converting "0"
    ld  hl, 0
    jp  _ascii2bin_end

_ascii2bin_hex_pre:
    ;   Number start with a prefix
    call _ascii2bin_advance
    jp  z, _ascii2bin_error ; Error: only prefix

_ascii2bin_hex:
;   
;   Convert ASCII hexadecimal to binary
;   ( -- n )
;
;   HL: @ counted_string
;

    ld      hl, 0   ; hl = result 

_ascii2bin_hex_cycle:

    ld      a, (de)
    call    is_hex_digit
    cp      0
    jr      z, _ascii2bin_error

    ld      a, (de)
    cp      'a' - 1
    jr      c, _ascii2bin_hex_A
    sub     'a' - 10
    jr      _ascii2bin_hex_sum

_ascii2bin_hex_A:
    ld      a, (de)
    cp      'A' - 1
    jr      c, _ascii2bin_hex_0
    sub     'A' - 10
    jr      _ascii2bin_hex_sum

_ascii2bin_hex_0:
    ld      a, (de)
    sub     '0'
    jr      _ascii2bin_hex_sum

_ascii2bin_hex_sum:
    ld  b, 0
    ld  c, a    ; A contains the binary value

    ;   Shift left by 4 bits
    add hl, hl  
    add hl, hl
    add hl, hl
    add hl, hl

    add hl, bc

    call _ascii2bin_advance
    jr  z, _ascii2bin_adjust
    jr _ascii2bin_hex_cycle

_ascii2bin_bin_pre:
    ;   Number start with a prefix
    call _ascii2bin_advance
    jr  z, _ascii2bin_error ; Error: only prefix

_ascii2bin_bin:
    
    ld  hl, 0   ; hl = result 
    
_ascii2bin_bin_cycle:
;
    ld  bc, 1

    push de
    push hl
    push bc

    fcall code_lshift

    pop hl
    pop de
;
    ld  a, (de)
    cp  '0'
    jr  z, _ascii2bin_bin_next

_ascii2bin_bin_1:
;
    cp  '1'
    jr  nz, _ascii2bin_error
    inc hl

_ascii2bin_bin_next:
;
    call _ascii2bin_advance
    jr  z, _ascii2bin_adjust
    jr  _ascii2bin_bin_cycle

_ascii2bin_char_pre:
    ;   Number start with a prefix
    call _ascii2bin_advance
    jr  z, _ascii2bin_error ; Error: only prefix

_ascii2bin_char:
;
    ld h, 0
    ld l, (de)    

    push hl

    call _ascii2bin_advance
    
    ;   Check for final "'"
    ld a, (de)
    cp '\''
    jr  nz, _ascii2bin_error
    jr  _ascii2bin_adjust

_ascii2bin_adjust:

    ; Adjust for negative sign if necessary

    ld      a, (_ascii2bin_sign)
    cp      1
    jr      nz, _ascii2bin_end     ; Check if it's negative
    
    ; Handle two's complement conversion for negative number
    push    hl
    fcall   code_negate       
    pop     hl

_ascii2bin_end:

    push hl
    ld   hl, TRUE
    push hl

    fret

_ascii2bin_error:
    ld  hl, FALSE
    push hl
    push hl
    
    fret    
    
_ascii2bin_sign: db 0
_ascii2bin_count: db 0
