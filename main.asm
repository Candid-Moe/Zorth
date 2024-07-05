;
;   Main: Here start the kernel
;
    org     0x4000

init:
    ld      SP, _DATA_STACK
    ld      IX, _RETURN_STACK

    fcall   dict_init
    ld      hl, words
    push    hl
    fcall   print_line
    fcall   code_words

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

_repl_words:

    ;   Extract next word from TIB
    ld      de, ' '
    push    de
    fcall   code_word

    pop hl          ; Word address
    ld  a, (hl)     ; Count byte

    ;   Do we have a word to process?    
    ld  b, a
    xor a
    cp  b
 
    jz repl ; No, read another line

    ;   We read a word, process it.
    push    hl
    fcall    print_line
    ld      hl, new_line
    push    hl
    fcall    print_line

    jp      _repl_words

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


code_type:
;
;   Implement TYPE
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

code_space:
;
;   Implement SPACE
;   ( -- )
;
;   Display one space. 
;
    fenter

    ld   hl, space
    push hl
    fcall print_line

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


