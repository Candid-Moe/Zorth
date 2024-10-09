;   Zorth - (c) Candid Moe 2024
;
;   main: Here start the kernel
;
    org     0x4000

init:
    ld      SP, _DATA_STACK
    ld      IX, _RETURN_STACK
    ld      IY, _EX_STACK
    ld      hl, _LEAVE_STACK
    ld      (_IX_LEAVE), hl
    ld      hl, _CONTROL_STACK
    ld      (_IX_CONTROL), hl
    ld      hl, (_HEAP)
    ld      de, 0
    ld      (hl), de

    fcall   clear_screen
    
    ld      HL, _BOOT_MSG
    push    HL
    fcall   print_line

    fcall   dict_init

    ld hl, _src_start
    push hl
    ld hl, (_SRC_SIZE)
    push hl
    fcall   code_evaluate

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

;   --- debugging ---
;    push    hl
;    push    hl
;    fcall   code_count
;    fcall   code_type
;    fcall   code_space
;    pop     hl
;   --- debugging ---

    ld      a, (hl)         ; Count byte
    cp      0
    jp      z, _repl_return ;   Do we have a word to process?    

    ;   See if we are discarting words

    ld      a, (_DISCARD)
    cp      FALSE
    jr      z, _repl_words_xt

    ;   Check for ';' to end discarting

    ld      bc, (hl)
    ld      a, 1
    cp      c
    jr      nz, _repl_words ;   Discard word
    ld      a, b
    cp      ';'
    jr      nz, _repl_words ;   Discard word
    
    ld      a, FALSE
    ld      (_DISCARD), a
    jr      _repl_words

_repl_words_xt:

    ;   Obtain the execution token for word

    push    hl
    fcall   code_find
    pop     bc             ; return code
    pop     hl             ; xt

    ld      a, b
    or      c        
    jr      nz, _repl_word_found

    ;   Not a word. Maybe a value?

    push    hl
    fcall   ascii2bin

    pop     hl      ; Flag
    ld      a, l
    or      h       ; Failed? 
    jr      z,      _repl_failed    
    
    ;   Success, value already in stack

    ;
    ;   A value was converted. Now actions depend on
    ;   which state we are.
    ;
    ld  a, (_STATE)
    cp  a, TRUE
    jr  nz, _repl_words
    :
    ;   Mode compile
    ;
    fcall  code_literal

    jr  _repl_words

_repl_word_found:

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
    jp  z, _repl_words  ; Stack OK

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
    fcall   error_word_not_found
    jr      _repl_end

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

code_find:
;
;   Implements FIND 
;   ( c-addr -- c-addr 0 | xt 1 | xt -1 )
;
;   Find the definition named in the counted string at c-addr. 
;   If the definition is not found, return c-addr and zero. 
;   If the definition is found, return its execution token xt. 
;   If the definition is immediate, also return one (1), otherwise 
;   also return minus-one (-1). 
;   For a given string, the values returned by FIND while compiling 
;   may differ from those returned while not compiling. 
;
    fenter 

    ;
    ;   Search the entry in the dictionary
    ;
    ;   If word is not found, return c-addr FALSE
    ;

    dup hl
    fcall code_to_r     ; ( : R -- c-addr )

    fcall dict_search

    pop hl
    ;   Test error
    ld  a, h
    or  l
    jr  nz, _code_find_found

    fcall code_r_from   ; Recover string address
    ld  hl, 0           ; Return code
    push hl

    fret 

_code_find_found:

    push    hl  ; xt
    ld      bc, 3
    add     hl, bc
    ld      a, (hl)
    ld      bc, 1
    and     BIT_IMMEDIATE
    jr      z, _code_find_end
    ld      bc, -1

_code_find_end:

    push    bc  ; return code

    fcall   code_r_from ; Discard string address
    pop     de

    fret

code_source_id:
;
;   Implements SOURCE-ID 
;   ( -- 0 | -1 )
;
;   Identifies the input source as follows:
;   SOURCE-ID 	Input source
;   -1 	String (via EVALUATE)
;    0 	User input device
;
    ld  bc, (_SOURCE_ID)
    push bc

    jp (hl)

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

    ld      bc, 0
    ld      (_SOURCE_ID), bc
    ld      (_gtIN), bc

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

code_c_quote:
;
;   Implements C" 
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Compilation:
;   ( "ccc<quote>" -- )
;
;   Parse ccc delimited by " (double-quote) and append the run-time semantics
;   given below to the current definition.
;
;   Run-time:
;   ( -- c-addr )
;
;   Return c-addr, a counted string consisting of the characters ccc. 
;   A program shall not alter the returned string. 
;
    fenter

    ld      hl, '"'
    push    hl
    fcall   code_parse

    ;   Compilation mode

    ;   Put the counted string address in the stack

    ld      hl, (xt_literal)
    push    hl
    fcall   add_cell        ; add a load for string address

    ld      hl, (_DP)
    ld      de, 6
    add     hl, de
    push    hl
    fcall   add_cell        ; string address to load

    ;   Add a jmp over the string

    ld      hl, (xt_jp)
    push    hl
    fcall   add_cell        ; jmp

    ld      hl, (_DP)
    pop     bc
    push    bc
    add     hl, bc          ; # chars in string
    inc     hl              ; one byte for the count byte
    inc     hl
    inc     hl              ; two byte for the address

    push    hl
    fcall   code_aligned    ;
    fcall   add_cell        ; address
    
    ;   Move the text
    pop     bc              ; length
    ld      hl, (_DP)       ; 
    ld      (hl), c         ; count length
    inc     hl
    push    hl
    push    bc

    add     hl, bc          ; Allot the space
    inc     hl              ; count byte
    push    hl
    fcall   code_aligned
    pop     hl
    ld      (_DP), hl

    fcall   code_move

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

    ld      a, (_STATE)
    cp      TRUE
    jp      z, _code_s_quote_comp
    
    ;   Interpretation mode
    
    fret 

_code_s_quote_comp:

    ;   Compilation mode
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

    ;   Get next char in input area
    ld      de, (_gtIN)
    ld      hl, (TIB)
    add     hl, de

    ld      a, (hl)
    cp      '\n'    
    jr      z, _code_backslash_end

    ;   If not '\n', search for it.
    ;   Note: code_parse start searching one char past next one,
    ;   on the assumptions that's a white space (true) and not
    ;   relevante (false). 
    ;   TODO: correct this mess
        
    ld      hl, '\n'
    push    hl
    fcall   code_parse
    pop     hl
    pop     hl

_code_backslash_end:

    fret 

print_error_word_not_found:
    
    fenter 

    ld      hl, err_word_not_found
    push    hl
    fcall   print_line

    ld hl,  _PAD
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

code_accept:
;
;   ACCEPT 
;   ( c-addr +n1 -- +n2 )
;
;   Receive a string of at most +n1 characters. An ambiguous condition exists
;   if +n1 is zero or greater than 32,767. 
;   Display graphic characters as they are received. A program that depends on 
;   the presence or absence of non-graphic characters in the string has an 
;   environmental dependency. 
;   The editing functions, if any, that the system performs in order to construct
;   the string are implementation-defined.
;
;   Input terminates when an implementation-defined line terminator is received.
;   When input terminates, nothing is appended to the string, and the display is
;   maintained in an implementation-defined way.
;
;   +n2 is the length of the string stored at c-addr. 
;
    fenter

    call kbd_cooked_mode
    pop bc              ; +n1
    pop de              ; c-addr
    ld  h, DEV_STDIN
    READ   
    
    push bc
    
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

    ld      bc, (_SOURCE_ID)
    ld      a, b
    or      c
    jr      nz, _refill_bad_source

    call    kbd_cooked_mode

    ld  hl, 0
    ld  (_gtIN), hl      ; Reset index >IN
    ;
    ;   Read a line from device into TIB
    ;
    ld  h,   DEV_STDIN
    ld  de,  (TIB)      ;   Buffer address
    ld  bc,  80         ;   Buffer length
    READ   

    cp  a, ERR_SUCCESS    
    jz  _refill_true
    ld  hl, FALSE
    jp  _refill_ret

_refill_true:

    ld  (_gTIB), bc     ;   move count
    ld  hl, (TIB)       ;   replace ending '\n' with space
    add hl, bc
    dec hl
    
    ld  a, (hl)     ; B is the last char 
    cp  '\n'
    jnz _refill_true_next
    ld  (hl), ' '  
  
_refill_true_next:     

    ld  hl, TRUE

_refill_ret:

    push hl    

    fret

_refill_bad_source:
    
    ld  hl, err_bad_source
    push hl
    fcall print_line
    fcall code_backslash
    fcall code_cr
    
    ld  hl, FALSE
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


code_space:
;
;   Implement SPACE
;   ( -- )
;
;   Display one space. 
;
    fenter

    ld      hl, ' '
    push    hl
    fcall   code_emit

    fret

code_cr:
;
;   Implements CR 
;   ( -- )
;
;   Cause subsequent output to appear at the beginning of the next line. 
;
    fenter

    ld      hl, '\n'
    push    hl
    fcall   code_emit

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

    pop de
    ld  a, e
    ld  (_emit_buffer), a
    ld  de, _emit_buffer
    ld  bc, 1

    ld  h, DEV_STDOUT
    WRITE()   
  
    fret

_emit_buffer:   db 0
    
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

code_ioctl:
;
;   Implements IOCTL
;   ( device_number command_number param -- )
;
;    
    fenter

    pop de
    pop bc
    pop hl
    ld  h, l
    IOCTL

    fret

code_ioctl_set_xy:
;
;   Implements IOCTL_SET_XY
;   ( x y -- )
;
    fenter

    pop     bc
    ld  e, c
    pop     bc
    ld  d, c

    fcall   code_ioctl

    fret

clear_screen:

    fenter

    ld hl, 0
    push hl
    ld hl, 6
    push hl
    ld hl, 0
    push hl

    fcall code_ioctl

    fret

error_word_not_found:    

    fenter

    fcall   print_error_word_not_found
   
    ;   Discard rest of line and start again
    ld  a, (_STATE)
    cp  TRUE
    jr  z, _set_discard_mode

    ;   Interpreting mode, discard the rest of the line
    fcall   code_backslash
    jr      _repl_failed_next

_set_discard_mode:
    ;   
    ;   Print the word name that failed
    ;
    ld      hl, err_in_word
    push    hl
    fcall   print_line

    ld      hl, (_DICT)
    inc     hl
    inc     hl  ; # words
    inc     hl  ; flags
    inc     hl  ; name
    ld      de, (hl)
    push    de
    fcall   print_line
    
    ld      a, TRUE
    ld      (_DISCARD), a       ; Discard next words until semmicolon is found
    fcall   dict_delete_last

_repl_failed_next:

    fcall   code_cr

    ;   Back to INTERPRETER mode

    ld      a, FALSE
    ld      (_STATE), a

    fret


