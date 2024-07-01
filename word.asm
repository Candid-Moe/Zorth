code_word:
;
;   Implements WORD
;   ( char "<chars>ccc<char>" -- c-addr )
:
;   Skip leading delimiters. Parse characters ccc delimited by char.
;   An ambiguous condition exists if the length of the parsed 
;   string is greater than the implementation-defined length of a 
;   counted string.
;
;   c-addr is the address of a transient region containing the 
;   parsed word as a counted string. If the parse area was empty
;   or contained no characters other than the delimiter, the 
;   resulting string has a zero length. A program may replace
;   characters within the string. 

    fenter

    ld  hl, _TIB            ; entry buffer
    ld  b,  0
    ld  a,  (_gtIN)         ; current position in entry buffer
    ld  c,  a 
    add hl, bc              ; HL -> next char in entry buffer

    pop bc                  ; C contains delimiting char

    ld  a, (_gtIN)
    ld  b, a
    ld  a, (_gTIB)          
    sub b                   
    ld  b, a                ; B contains length remaining in entry buffer

    ld  de, _PAD            ; DE -> destination (pad)
    inc de                  ; Skip count byte

    xor a                   ;
    ld  (_PAD), a           ; Word length <- 0

_code_word_cycle:
    ;   Check how many bytes to examine 
    xor a   
    cp  b                   ; remaining == 0?
    jz  _code_word_exit

    ;   Look at the byte in entry buffer
    ld  a, (HL)
    cp  c                   ; A == char?
    jnz _code_word_found
    
    ;   
    inc hl                  ; Next char in entry buffer
    dec b                   ; Decrement count of remaining bytes

    inc_byte _gtIN          ; Move input index

    jp  _code_word_cycle
    
_code_word_found:
    ;   Copy one byte to PAD
    ld  (de), a             ; Store byte
    inc hl                  ; Pointer to next char (entry)
    inc de                  ; Pointer to next free position (PAD)

    inc_byte _gtIN          ; Increment index on _TIB
    inc_byte _PAD           ; Increment word length
    
    xor a
    dec b                   ; 
    cp  b                   ; End of entry buffer?
    jz  _code_word_exit

    ld  a, (hl)             ;
    cp  c
    jnz _code_word_found     
    
_code_word_exit:
    ld  hl, _PAD
    push hl

    fret

