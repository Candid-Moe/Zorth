; Convert signed ASCII integer to binary (two's complement) in stack

ascii2bin_int:
;   
;   Convert ASCII integer to binary
;   ( c-addr -- n )
;
    fenter 

    ;   Integer have at least 1 digit.

    pop     de      ; de -> counted string
    ld      a, (de) ; a = string len
    ld (_ascii2bin_count), a 
    inc     de      ; de -> first char

    ld      hl, 0   ; hl = result 

    ld      a, 0    ; Initialize to keep track of sign handling
    ld (_ascii2bin_sign), a

    ; Check if the number is negative
    cp      '-'     ; Check if it's a minus sign
    jr      nz, _ascii2bin_cycle
    
    ; Negative number handling
    inc     de      ; Move to the next character
    ld      a, 1    ; Set B to indicate negative sign
    ld (_ascii2bin_sign), a
    dec_byte _ascii2bin_count           

_ascii2bin_cycle:
    ; Process the rest of the digits
 
    ; Convert ASCII digit to binary (subtract ASCII '0')
    ld      a, (de) ; Load the next character of the string
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

    dec_byte _ascii2bin_count
    jr      nz, _ascii2bin_cycle ; Continue until end of string
    
_ascii2bin_adjust:

    ; Adjust for negative sign if necessary
    ld      a, (_ascii2bin_sign)
    ld      c, 1
    cp      c
    jr      nz, _ascii2bin_end     ; Check if it's negative
    
    ; Handle two's complement conversion for negative number
    push    hl
    fcall   code_negate       

    fret

ascii2bin_hex:
;   
;   Convert ASCII integer to binary
;   ( c-addr -- n )
;
    fenter

    pop de
    ld  a, (de)
    dec a
    ld (_ascii2bin_count), a

    inc de      ; Over count byte
    inc de      ; Over 0

    ld  hl, 0   ; HL is the result

_ascii2bin_hex_cycle:

    inc de    ; hex digit
    dec_byte _ascii2bin_count
    jr  z, _ascii2bin_end

    ld  a, (de)
    ld  c, 'a'  
    cp  c
    jr  c, _ascii2bin_hex_digit

    ;   It's a letter in range a-f
    sub c
    add 10      ; A = decimal value of letter
    jr _ascii2bin_hex_sum

_ascii2bin_hex_digit:
    ld  c, '0'
    sub c

_ascii2bin_hex_sum:
    ld  b, 0
    ld  c, a    ; A contains the binary value

    ;   Shift left by 4 bits
    add hl, hl  
    add hl, hl
    add hl, hl
    add hl, hl

    add hl, bc

    jr _ascii2bin_hex_cycle

_ascii2bin_end:
;
    push hl
    fret

_ascii2bin_sign: db 0
_ascii2bin_count: db 0
