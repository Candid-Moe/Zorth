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

    pop bc
    ld  a, c
    ld  (_code_word_compare + 1), a
    ld  (_code_word_compare2 + 1), a

    ;   Calculate size of remaining buffer
    set_carry_0
    ld  hl, (gTIB)
    ld  de, (hl)
    ld  hl, de

    ld  de, (_gtIN)
    sbc hl, de
    ld  bc, hl              ; BC -> bytes remaining in entry buffer

    ;   Calculate address first unprocessed char.
    ld  hl, (TIB)           ; entry buffer
    ld  de, (_gtIN)         ; current position in entry buffer
    add hl, de              ; HL -> next char in entry buffer

    ;   Initialize PAD
    ld  de, _PAD            ; DE -> destination (pad)
    inc de                  ; Skip count byte

    xor a                   ;
    ld  (_PAD), a           ; Word length <- 0

_code_word_cycle:
    ;   Check how many bytes to examine 
    ld  a, b                   ; remaining == 0?
    or  c
    jz  _code_word_exit

    ;   Look at the byte in entry buffer
    call _read_translate  

_code_word_compare:
    cp  0                   ; The actual value will be written in run-time.
    jr  nz, _code_word_found    
       
    inc hl                  ; Next char in entry buffer
    dec bc                  ; Decrement count of remaining bytes

    push bc
    ld bc, (_gtIN)
    inc bc
    ld (_gtIN), bc
    pop bc

    jp  _code_word_cycle
    
_code_word_found:
    ;   Copy one byte to PAD
    ld  (de), a             ; Store byte
    inc hl                  ; Pointer to next char (entry)
    inc de                  ; Pointer to next free position (PAD)

    push bc
    ld  bc, (_gtIN)
    inc bc
    ld (_gtIN), bc          ; Increment index on _TIB
    pop bc

    inc_byte _PAD           ; Increment word length
    
    dec bc                   ; 
    ld  a, b     
    or  c                    ; End of entry buffer?
    jz  _code_word_exit

    call _read_translate

_code_word_compare2:
    cp  0                   ; Value will be written in the machine code
    jr  z, _code_word_exit     
    cp '\n'
    jr  z, _code_word_exit

    jr  _code_word_found
    
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
;   Implements WORD copying word to second PAD area,
;   not to clobber with REPL in main.
;
    fenter

    fcall   code_word

    pop     hl
    push    hl      ; origin
    ld      a, (hl)
    ld      b, 0
    ld      c, a    ; string length
    inc     bc
    
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
    ld      hl, (gTIB)
    ld      bc, (hl)
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

    ld      bc, (_gtIN)     ; >IN
    ld      hl, (TIB)       
    add     hl, bc          ; HL = current position in the input area
    inc     hl              ; skip the white space between words
    inc     bc

    push    hl              ; Working copy

    ld      hl, (gTIB)      ; Calculating # chars left in input area
    ld      de, (hl)        ; String total length
    ld      hl, de
    ld      de, bc          ; >IN
    set_carry_0
    sbc     hl, de
    ld      bc, hl          ; BC -> chars left    
    jr      z, _code_parse_eol:
    
    pop     hl              ;
    pop     de              ; Char to search for
    ld      a, e
    push    hl              ; Return the string starting address 

    cpir

    dec     hl              ; HL -> char founded
    pop     de              ; Starting address
    push    de
    set_carry_0
    sbc hl, de

    push hl                 ; String len

    ld  de, (_gtIN)          ; 
    add hl, de
    inc hl                  ; One for the skipped char at begining
    inc hl                  ; One for the char found
    ld  (_gtIN), hl          ; Move >IN over the string
    
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

code_scan:
;
;   Implements SCAN
;   ( c-addr1 u1 c -- c-addr2 u2 )
;
;   Search character c in area pointed by c-addr1, of length u1.
;   On success, c-addr2 is the address after the found character and
;   u2 is the remaining length
;
    fenter

    pop bc
    ld  a, c
    pop bc
    pop hl

    cpir
    jr  nz, _code_scan_not_found

    dec hl      ;   Make results compatible with scan
    inc bc 

_code_scan_not_found:

    push hl
    push bc

    fret


   
