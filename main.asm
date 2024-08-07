;   Zorth - (c) Candid Moe 2024
;
;   main: Here start the kernel
;
    org     0x4000

init:
    ld      SP, _DATA_STACK
    ld      IX, _RETURN_STACK
    ld      IY, _CONTROL_STACK
    ld      hl, _LEAVE_STACK
    ld      (_IX_LEAVE), hl
    
    ld      HL, _BOOT_MSG
    push    HL
    fcall   print_line

    fcall   dict_init

    ld      hl, boot_file
    push    hl
    fcall   load_fs

    ld      hl, words
    push    hl
    fcall   print_line
    fcall   code_words

repl:
;
;   Read a line and execute every word in it.
;
    ld     hl, _PROMPT
    push   hl
    fcall  print_line

    fcall  code_refill
    ;   Check return code
    pop         bc
    jump_zero   c, repl

_repl_words:
;
;   Extract next word from TIB
;
    ld      de, ' '
    push    de
    fcall   code_word
    pop     hl              ; Word address

    ld      a, (hl)         ; Count byte
    cp      0
    jp      z, _repl_return ;   Do we have a word to process?    

    ;   Obtain the execution token for word
    push    hl
    fcall   get_xt
    pop     hl      ;     
    ld      a, h
    or      a, l        
    jr      z, _repl_failed

    push    hl              ; xt
    ld      a, (_STATE)
    cp      FALSE
    jr      z, _repl_execute
    
    ;   check for immediate words (always be executed)
    ld      de, hl          ; xt 
    inc     de      
    inc     de              ; # words
    inc     de              ; flag
    ld      a, (de) 
    and     BIT_IMMEDIATE   ; mode immediate
    jr      nz, _repl_execute

    ;   Mode compilation, not immediate
    ;   Add the xt to the last word in dictionary

    fcall   add_cell

    jr      _repl_end

_repl_execute:
    ;
    ;   See how xt must be executed.
    ;   Code words are jumped directly
    ;   Colon definitions are run by code_execute
    call    _ex_classify
    jr      nz, _repl_execute_colon

    pop     bc  ; Discard XT 

    ;   Execute a CODE works.
    ;   Call the code directly

    ld bc, (hl)
    ld (_repl_jp + 1), bc
    ld hl, _repl_end

_repl_jp:    
    jp   0          ; dest. will be overwritten 

_repl_execute_colon:

    fcall   code_execute    
    jr      _repl_end
       
_repl_end:
;
;   After each instruction, check data stack (only underflow for now)
;
    ld  a, (_S_GUARD)
    cp  0x50
    jr  z, _repl_words  ; Stack OK

    ;   Restore stack
    ld  SP, _DATA_STACK
    ld  a, 0x50
    ld  (_S_GUARD), a

    ;   print error message and discard rest of the line

    ld  hl, err_underflow
    push hl
    fcall print_line

    jr  _repl_return

_repl_failed:
;
;   Not a word, not a value
;
    pop     hl          ; Discard value
    ld      hl, err_word_not_found
    push    hl
    fcall   print_line
    ld hl,  _PAD
    push hl
    fcall print_line
    fcall code_cr
    
    ;   Discard rest of line and start again
    fcall   code_backslash
    ;   Back to INTERPRETER mode
    ld  a, FALSE
    ld  (_STATE), a
    ;   Empty control stack
    ld  IY, _CONTROL_STACK

    jr  _repl_end

_repl_return:
    
    ;   Don't return unless we were called
    ld  a, (_repl_depth)
    cp  0
    jp  z, repl
    
    ld  hl, _repl_depth
    dec (hl)

    fret                ; This returns to inner_interpreter caller

_repl_depth:    db  0
inner_interpreter:

    fenter
    
    ld  hl, _repl_depth
    inc (hl)

    fcall   _repl_words ; This call never return.

    
return:
;
;   For routines called with fenter/fret, return is via
;   jumping here. The return address is poped from return stack.
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
;   ( c-addr -- xt )
;
;   c-addr is word as counted-string

    fenter 

_get_xt_word:
    ;
    ;   Search the entry in the dictionary
    ;
    ;   If word is not found, return FALSE
    ;

    fcall dict_search
    pop hl
    ;   Test error
    ld a, h
    or l
    jr  z, _get_xt_not_word

    ; The xt is the dictionary entry 

    jr  _get_xt_end

_get_xt_not_word:

    ld  hl, 0

_get_xt_end:

    push hl
    fret

code_bye:
;
;
;
    EXIT()

code_abort:
;
;   Implements ABORT 
;   ( i * x -- ) ( R: j * x -- )
;
;   Empty the data stack and perform the function of QUIT, which includes
;   emptying the return stack, without displaying a message. 
;
        ld      SP, _DATA_STACK
        jr      code_quit

code_quit:
;
;   Implements QUIT
;   ( -- ) ( R: i * x -- )
;
;   Empty the return stack, store zero in SOURCE-ID if it is present, 
;   make the user input device the input source, and enter interpretation state.
;   Do not display a message. Repeat the following:
;
;   Accept a line from the input source into the input buffer, set >IN to zero,
;   and interpret.
;
;   Display the implementation-defined system prompt if in interpretation state, 
;   all processing has been completed, and no ambiguous condition exists.
;
    ld      IX, _RETURN_STACK
    ld      IY, _CONTROL_STACK

    xor     a
    ld      (_SOURCE_ID), a
    ld      (_gtIN), a

    ld      a, FALSE
    ld      (_STATE), a    
    
    jp      repl
    
code_search:
;
;   Implements SEARCH
;   ( c -- c-addr | flag )
;
;   Search char c in the TIB
;
    fenter
    
    ld  hl, (gTIB)
    ld  bc, (hl)    ; BC = Len of TIB area
    ld  hl, bc
    ld  de, (_gtIN)
    set_carry_0
    sbc hl, de
    ld  bc, hl      ; BC = remaining char is TIB area

    ld  hl, (TIB)
    ld  de, (hl)    
    ex  hl, de      ; HL = pointer to TIB area
    ld  de, bc

    ld  de, (_gtIN) ;
    add hl, de      ; HL = starting position for searching

_code_search_cycle:

    ;   Check buffer end
    ld  a, b
    or  c
    jr  z, _code_search_not_found

    pop de
    ld  a, e
    push de

    ;   Check the character

    ld  d, (HL)     ; Char to inspect
    cp  d
    jz  _code_search_found

    ;   Check EOL

    ld  a, '\n'
    cp  d
    jz  _code_search_not_found

    jr  _code_search_cycle

_code_search_found:

    pop     de
    push    hl

    fret

_code_search_not_found:

    pop     de
    ld      de, 0
    push    de

    fret

code_s_quote:
;
;   Implement S" 
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Compilation:
;   ( "ccc<quote>" -- )
;
;   Parse ccc delimited by " (double-quote). 
;   Append the run-time semantics given below to the current definition.
;
;   Run-time:
;   ( -- c-addr u )
;
;   Return c-addr and u describing a string consisting of the characters ccc. 
;   A program shall not alter the returned string. 
;
    fenter

    ld      hl, '"'
    push    hl
    fcall   code_parse

    ;   The final string address
    ld      hl, (xt_literal)
    push    hl
    fcall   add_cell        ; add a load for address

    ld      hl, (_DP)
    ld      de, 10
    add     hl, de
    push    hl
    fcall   add_cell        ; address to load

    ld      hl, (xt_literal)
    push    hl
    fcall   add_cell        ; add a load for length

    pop     hl
    push    hl
    push    hl
    fcall   add_cell        ; length to load

    ;   Add a jmp over the string

    ld      hl, (xt_jp)
    push    hl
    fcall   add_cell        ; jmp

    ld      hl, (_DP)

    pop     bc
    push    bc
    add     hl, bc          ; # chars in string
    inc     hl
    inc     hl              ; One cell for the address

    push    hl
    fcall   add_cell        ; address

    ;   Move the text
    pop     bc              ; length
    ld      hl, (_DP)
    push    hl
    push    bc

    add     hl, bc          ; Allot the space
    ld      (_DP), hl

    fcall   code_move

    fret

code_state:
;
;   Implements STATE
;   ( -- a-addr )
;
;   a-addr is the address of a cell containing the compilation-state flag. 
;   STATE is true when in compilation state, false otherwise. 
;   The true value in STATE is non-zero, but is otherwise implementation-defined. 
;   Only the following standard words alter the value in STATE: : 
;       (colon), ; (semicolon), ABORT, QUIT, :NONAME, [ (left-bracket), ] (right-bracket).
;
;   Note:
;   A program shall not directly alter the contents of STATE. 

    ld      bc, _STATE
    push    bc

    jp      (hl)

code_backslash:
;
;   Implements \
;
;   Compilation:
;   Perform the execution semantics given below.
;
;   Execution:
;   ( "ccc<eol>" -- )
;
;   Parse and discard the remainder of the parse area. \ is an immediate word. 
;
;   Note: this word search for a '\n' in the input area, so it process correctly
;   things like ": 1+ 1 + ; \ sum \n 1- 1 - ;", which have two logical lines.
;
    fenter

    ld      hl, '\n'
    push    hl
    fcall   code_parse
    pop     hl
    pop     hl

    fret 


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

    ld    hl, ' '
    push  hl
    fcall code_word
    pop hl                  ; origin
            
    ;   Check word len
    ld  a, (hl)             ; len
    cp  0
    jz  _code_tick_error

    push    hl
    fcall   dict_search
    pop     hl

    ld      a, l
    or      h
    jz      _code_tick_not_found


    push    hl
        
    fret

_code_tick_error:

    ld  hl, err_missing_name
    push hl
    fcall   print_line

    fret

_code_tick_not_found:

    ld      hl, err_word_not_found
    push    hl
    fcall   print_line

    fret

code_dot:
;
;   Implements .
;   ( n -- )
;
;   Display n in free field format
;
    fenter

    ld  bc, (_BASE)
    ld  a, c
    cp  16
    jr  z, _code_dot_hex
    fcall itoa
    jr  _code_dot_print

_code_dot_hex:
    fcall htoa

_code_dot_print:
    fcall code_count
    fcall code_type
    fcall code_space
    
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
    ld  de,  (TIB)
    ld  bc,  80
    READ   

    cp  a, ERR_SUCCESS    
    jz  _refill_true
    ld  hl, FALSE
    jp  _refill_ret

_refill_true:

    ;   move count
    ld  hl, (gTIB)
    ld  a, c
    ld  (hl), a

    ;   replace ending '\n' with space
    ld  hl, (TIB)

    ld  b,  0       ; BC is the count
    dec bc
    add hl, bc
    
    ld  a, (hl)     ; B is the last char 
    cp  '\n'
    jnz _refill_true_next
    ld  (hl), ' '  
  
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

    ld      bc, _PAD
    push    bc

    jp  (hl)

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

    inc hl          ; # words
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

code_cr:
;
;   Implements CR 
;   ( -- )
;
;   Cause subsequent output to appear at the beginning of the next line. 
;
    fenter

    ld  hl, new_line
    push hl
    fcall code_count
    fcall code_type

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

code_emit:
;
;   Implements EMIT
;   ( x -- )
;
;   If x is a graphic character in the implementation-defined character set, display x. 
;   The effect of EMIT for all other values of x is implementation-defined.
;
;   When passed a character whose character-defining bits have a value between 
;   hex 20 and 7E inclusive, the corresponding standard character, specified 
;   by 3.1.2.1 Graphic characters, is displayed. Because different output devices
;   can respond differently to control characters, programs that use control 
;   characters to perform specific functions have an environmental dependency. 
;   Each EMIT deals with only one character. 
    
    fenter

    ld  hl, _PAD

    pop bc
    ld  (hl), c
    push hl
    ld  bc, 1
    push bc

    fcall code_type

    fret
    
_code_mode_error:
    
    ld  hl, err_mode_not_comp
    push hl
    fcall print_line

    ld  hl, _PAD
    push hl
    fcall print_line
    fcall code_backslash
    fcall code_cr
    
    fret


