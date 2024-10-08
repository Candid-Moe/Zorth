;   Zorth - (c) Candid Moe 2024
;
;   word: implementation
;

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

    ld  hl, (TIB)            ; entry buffer

    ld  b,  0
    ld  a,  (_gtIN)         ; current position in entry buffer
    ld  c,  a 
    add hl, bc              ; HL -> next char in entry buffer

    pop bc                  ; C contains delimiting char

    ld  a, (_gtIN)
    ld  b, a
    ld  de, (gTIB)
    ld  a, (de)          
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
    call _read_translate  
    cp  c                   ; A == char?
    jr  nz, _code_word_found
    
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

    call _read_translate
    cp  c
    jr  nz, _code_word_found     
    
_code_word_exit:
    ld  hl, _PAD
    push hl

    fret

_read_translate:
    ;   Read next char from input area, replacing '\n' with ' '.
    ;   Return char in A
    ld  a, (hl)
    cp  '\n'
    jr  z, _read_translate_space
    cp  '\t'
    jr  z, _read_translate_space
    jr  _read_translate_end

_read_translate_space:
    ld  a, ' '

_read_translate_end:
    ret

code_word_no_clobber:
;
;   Implements WORD copying word to second area,
;   not to clobber with REPL in main.
;
    fenter

    fcall   code_word
    pop     hl
    push    hl      ; origin
    ld      b, 0
    ld      a, (hl)
    inc     a
    ld      c, a
    
    ld      hl, _PAD_NO_CLOBBER
    push    hl      ; destination
    push    bc      ; len
    fcall   code_move
    ld      hl, _PAD_NO_CLOBBER
    push    hl
    
    fret

_PAD_NO_CLOBBER:    db 80

code_tib:
;
;   Implements TIB
;   ( -- addr )
;
;   Put the address of the current Text Input Buffer in the stack
;
    ld      bc, (TIB)
    push    bc
    jp      (hl)

code_gtib:
;
;   Implements #TIB
;
;   Put the address of the TIB length in the stack
;
    ld      bc, (gTIB)
    push    bc
    jp      (hl)

code_source:
;
;   Implements SOURCE
;   ( -- c-addr u )
;
;   c-addr is the address of, and u is the number of characters in, the input buffer. 
;
    ld      bc, (TIB)
    push    bc
    ld      b, 0
    ld      a, (gTIB)
    ld      c, a
    push    bc

    jp      (hl)

code_parse:
;
;   Implements PARSE 
;   ( char "ccc<char>" -- c-addr u )
;
;   Parse ccc delimited by the delimiter char.
;
;   c-addr is the address (within the input buffer) and u is the length of 
;   the parsed string. 
;   If the parse area was empty, the resulting string has a zero length. 
;
    fenter

    ld      b, 0
    ld      a, (_gtIN)      ; >IN
    ld      c, a

    ld      hl, (TIB)       
    add     hl, bc          ; HL = current position in the input area
    inc     hl              ; skip the white space between words

    push    hl              ; Working copy

    ld      hl, (gTIB)      ; Calculating # chars left in input area
    ld      a,  (hl)        ; String total length
    sub     c
    dec     a               ; Count the white space just skipped
    jr      z, _code_parse_eol:

    ld      c, a
    ld      b, 0            ; BC = # chars left
    
    pop     hl              ;
    pop     de              ; Char to search for
    ld      a, e
    push    hl              ; Return the string starting address 

    cpir

    dec     hl              ; HL -> char founded
    pop     de              ; Starting address
    push    de
    or  a
    sbc hl, de

    push hl                 ; String len

    ld  a, (_gtIN)          ; 
    ld  d,  0
    ld  e,  a
    add hl, de
    inc hl                  ; One for the skipped char at begining
    inc hl                  ; One for the char found
    ld  a, l
    ld  (_gtIN), a          ; Move >IN over the string
    
    fret

_code_parse_eol:

    ;   Char not found
    ld  hl, _gtIN
    inc (hl)

    ld  hl, 0
    push hl
    push hl

    fret

code_in:
;
;   Implements >IN to-in CORE
;   ( -- a-addr )
;
;   a-addr is the address of a cell containing the offset in characters from
;   the start of the input buffer to the start of the parse area. 
;
    ld bc, _gtIN
    push bc

    jp  (hl)
