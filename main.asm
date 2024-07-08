;
;   Main: Here start the kernel
;
    org     0x4000

init:
    ld      SP, _DATA_STACK
    ld      IX, _RETURN_STACK
    
    ld      hl, 1234
    push    hl
    fcall   code_dot

    fcall   dict_init
    ld      hl, words
    push    hl
    fcall   print_line
    fcall   code_words

    ld      hl, st_pad
    push    hl
    fcall   dict_search
    ld      HL, _BOOT_MSG
    push    HL
    fcall    print_line

repl:
;
;   Read a line and execute every word in it.
;
    ld     hl, _PROMPT
    push   hl
    fcall  print_line
    fcall  code_refill
    ;   Check return code
    pop     bc
    jump_zero c, repl

_repl_words:

    ;   Extract next word from TIB
    ld      de, ' '
    push    de
    fcall   code_word   

    ld  hl, _PAD    ; Word address
    ld  b, (hl)     ; Count byte
    ;   Do we have a word to process?    
    jump_zero b, repl ; No, read another line

    ;   Obtain the execution token for word
    fcall    get_xt
    pop hl
    ld  a, h
    or  a, l        
    jr  nz, _repl_execute

    ;   Error, word not found

    ld hl, err_word_not_found
    fcall print_line
    ld hl, _PAD
    fcall print_line
    jr  _repl_words

_repl_execute:
    ;   Putting the dest. address in the jp inst.
    ld (_repl_jp + 1), hl
    ld hl, _repl_end
_repl_jp:    
    jp   0          ; dest. will be overwritten 
_repl_end:
    jr  _repl_words

return:
;
;   Implement RET by jumping to address in return stack
;   (Every routine jump to this code in order to return)
;
    ld      l, (ix)     ; pop return address from return stack
    inc     ix
    ld      h, (ix)
    inc     ix
    jp      (hl)        ; return via jump

get_xt:
;
;   Get the execution token for the word just readed.
;   The word can be anything, including numeric values.
;   
;   ( -- xt )
;
;   The word is in _PAD

    fenter 

    ;   Classify the word

    ld hl, _PAD
    push hl
    fcall classify
    pop hl              ; result

    ld   a, class_word  ; Is it a word?
    cp   l
    jr   nz, _get_xt_int

_get_xt_word:
    ;   Search the entry in the dictionary
    ld hl, _PAD
    fcall dict_search
    pop hl
    ;   Test error
    ld a, h
    or l
    jr  z, _get_xt_end
    ;   Extract xt
    inc hl
    inc hl      ; hl -> flags
    inc hl      ; hl -> @name
    inc hl
    inc hl      ; hl -> @xt
    ld  c, (hl)
    inc hl
    ld  b, (hl) ; bc = @xt
    ld  hl, bc

    jr  _get_xt_end

_get_xt_int:    
    ;   Convert ascii to binary and push it
    ld  a, class_integer
    cp  l
    jr   nz, _get_xt_hex
    ld  hl, ascii2bin_int
    jr  _get_xt_end

_get_xt_hex:
    ld  hl, ascii2bin_hex    
    
_get_xt_end:
    push hl
    fret
;

code_tick:
;
;   ' tick
;   ( "<spaces>name" -- xt )
;
;   Skip leading space delimiters. Parse name delimited by a space. 
;   Find name and return xt, the execution token for name. 
;   An ambiguous condition exists if name is not found. 
;   When interpreting, 
;       ' xyz EXECUTE 
;   is equivalent to xyz. 
;
    fenter

    ld  hl, (_DICT)     ; First dict entry
    
    fret

code_dot:
;
;   Implements.
;   ( n -- )
;
;   Display n in free field format
;
    fenter
    
    pop de
    ld  hl, _PAD
    inc hl          ; Reserve a byte for the count

    call itoa_16
    ;  hl was changed by itoa_16, back 1 byte
    ld  de, hl
    dec de          ; DE -> count byte

    ld  bc, 0
    ld  a, 0
_code_dot_count:    
    cpir
    sub  a, c       ; Made count in c positive
    inc  a          ; Add 1 for the trailing space
    ld   (de), a    ; Store count 
    ld   (hl), ' '  ; Add a strailing space

    push de        
    fcall code_count
    fcall code_type

    fret

code_str_equals:
;   
;   Implements STR=
;   ( c-addr1 u1 c-addr2 u2 – flag ) gforth-0.6 “str-equals”
;
;   Compare string for equality (gforth extension)
;
;   Return TRUE if equals, FALSE in other case
;
    fenter

    pop bc      ; u2
    ld  a, c    ; A = u2
    pop hl      ; c-addr2
    pop bc      ;
    ld  b, c    ; B = u1
    pop de      ; c-addr1

    cp b        ; u1 == u2 ?
    jr nz, _code_str_equals_false

_code_str_equals_cycle:    
    ; Same length, compare contents
    ; B = count
    ld  a, (de)
    cpi
    jr  nz, _code_str_equals_false
    jump_non_zero b, _code_str_equals_cycle
    ;   Else, all chars are equals

_code_str_equals_true:
    ld  hl, TRUE
    jr  _code_str_end
        
_code_str_equals_false:
    ld  hl, FALSE

_code_str_end:
    push hl
    fret


code_type:
;
;   Implements TYPE
;   ( c-addr u -- )
;
;   If u is greater than zero, display the character string
;   specified by c-addr and u.
;
;   When passed a character in a character string whose 
;   character-defining bits have a value between hex 20 and 
;   7E inclusive, the corresponding standard character, 
;   specified by 3.1.2.1 Graphic characters, is displayed. 
;   Because different output devices can respond differently 
;   to control characters, programs that use control characters
;   to perform specific functions have an environmental dependency. 

    fenter

    ld  h, DEV_STDOUT
    pop bc
    pop de
    WRITE()   
    
    fret

code_refill:
;
;   Implement REFILL
;   ( -- flag ) 
;
;   Attempt to fill the input buffer from the input source, 
;   returning a true flag if successful.
;
;   When the input source is the user input device, attempt 
;   to receive input into the terminal input buffer. If successful, 
;   make the result the input buffer, set >IN to zero, and 
;   return true. Receipt of a line containing no characters 
;   is considered successful. If there is no input available from 
;   the current input source, return false.
;
;   When the input source is a string from EVALUATE, return false 
;   and perform no other action. 

    fenter

    ld  a, 0
    ld  (_gtIN), a      ; Reset index >IN
    ;
    ;   Read a line from device into TIB
    ;
    ld  h,   DEV_STDIN
    ld  de, _TIB
    ld  bc,  80
    READ   

    cp  a, ERR_SUCCESS    
    jz  _refill_true
    ld  hl, FALSE
    jp  _refill_ret

_refill_true:

    ;   move count
    ld  a, c
    ld  (_gTIB), a

    ;   replace ending '\n' with space
    ld  hl, _TIB    

    ld  b,  0       ; BC is the count
    dec bc
    add hl, bc
    
    ld  b, (hl)     ; B is the last char 
    ld  a, '\n'
    cp  b
    jnz _refill_true_next
    ld (hl), ' '  
  
_refill_true_next:     

    ld  hl, TRUE

_refill_ret:

    push hl    

    fret

code_pad:
;
;   Implements PAD
;   ( -- c-addr )
;
;   c-addr is the address of a transient region that can be used
;   to hold data for intermediate processing. 
;
    fenter

    ld      hl, _PAD
    push    hl

    fret

code_count:
;
;   Implement COUNT 
;   ( c-addr1 -- c-addr2 u ) 
;   
;   Return the character string specification for the counted
;   string stored at c-addr1. 
;   c-addr2 is the address of the first character after c-addr1. 
;   u is the contents of the character at c-addr1, which is the
;   length in characters of the string at c-addr2. 
;
    fenter
    
    pop  hl          ; hl <- counted string address 
    ld   a, (hl)     ; a  <- counted string len
    inc  hl          ; hl -> counted string first char
    push hl          ; c-addr2 
    ld   h, 0        ;
    ld   l, a        ; u
    push hl

    fret

code_words:
;
;   Implements WORDS 
;   ( -- )
;
;   List the definition names in the first word list of the search order. 
;   The format of the display is implementation-dependent.
;
    fenter

    ld  hl, (_DICT)       ; HL -> Dict Entry

_code_words_cycle:
    ;
    ;   Check end of linked list (HL == 0)
    ;
    or a        ; clear carry flag
    ld  bc, 0
    sbc hl, bc
    add hl, bc
    jr  z,_code_words_end

    push hl         ; Keep entry address

    inc hl          ; flags
    inc hl          ; Name address
    inc hl

    ld  e,  (hl)    ; Load name address in DE
    inc hl
    ld  d,  (hl)

    push de
    fcall    print_line

    pop hl          ; Advance pointer to next entry 
    ld  e, (hl)
    inc hl
    ld  d, (hl)
    
    push de         ; Remember next entry
    fcall code_space    
    pop hl          ; Recover next entry

    jr  _code_words_cycle

_code_words_end:

    ld  hl, new_line
    push hl
    fcall print_line

    fret

code_bl:
;
;   Implements BL
;   ( -- char )
;
;   char is the character value for a space. 

    fenter

    ld hl, ' '
    push hl

    fret    

code_spaces:
;
;   Implements SPACES
;   ( n -- )
;
;   If n is greater than zero, display n spaces. 

    fenter
    
    pop bc
    inc bc
    djnz _code_spaces_end

_code_spaces_cycle:

    push bc
    fcall code_space
    pop bc
    djnz _code_spaces_cycle

_code_spaces_end:
    
    fret

code_space:
;
;   Implement SPACE
;   ( -- )
;
;   Display one space. 
;
    fenter

    ld      hl, space
    push    hl
    fcall   code_count
    fcall   code_type

    fret

print_line:
;
;   Print message on standard output
;
;   Parameters:
;   TOS      Address of counted-string.
;
    fenter 

    fcall   code_count
    fcall   code_type

    fret

classify:
;
;   Examine a word an classify it.
;   ( c-addr -- flag)
;
;   - Integer
;   - Hexadecimal
;   - Other (probably a Forth Word)
;
    fenter

    pop hl
    ld  b, (hl)  ; word length
    inc hl
    
    ld  a, (hl) ; First char
    ld  c, '-'  ; If start with '-' and len > 2, it's an integer
    cp  c    
    jr  nz, _classify_next
    
    ; It start with '-'
    ld  c, 1
    cp  c       ; len = 1?
    jr  z, _classify_word

_classify_next:    
    ;   It not start with '-'
    ld  c, '0'
    cp  c
    jr  z, _classify_prefix
    jr  c, _classify_word   ; A < '0'
     
    ;   A > '0'. It's a digit?
    ld  c, 0x3A     
    cp  c
    jr  c, _classify_integer ; A < '9'
    jr  _classify_word

_classify_prefix:
    ;   Word start with '0', maybe it's hex
    inc hl
    ld  a, (hl)
    ld  c, 'x'
    cp  c
    jr  z, _classify_hex
    ld  c, 'X'
    cp  c
    jr  z, _classify_hex

    ;   It's not hex
_classify_word:
    ld  hl, class_word
    jr _classify_end
_classify_integer:
    ld  hl, class_integer
    jr _classify_end
_classify_hex:
    ld  hl, class_hexadecimal
_classify_end:
    push hl

    fret
