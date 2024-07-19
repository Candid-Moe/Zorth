;   Zorth - (c) Candid Moe 2024

;   dictionary: operations that affect the word list
;
;   Words are store in lower case always.
;
;   Entry Format:
;
;   - address next entry (word)
;   - flags (byte)
;   - address of name
;   - address of code
;
;   Flags:
;   - bit 0: COLON (1) / CODE (0)
;   - bit 1: IMMEDIATE (1) / normal (0)

code_create:
;
;   Implements CREATE
;   ( "<spaces>name" -- )
;
;   Skip leading space delimiters. Parse name delimited by a space. 
;   Create a definition for name with the execution semantics defined below. 
;   If the data-space pointer is not aligned, reserve enough data space to align it. 
;   The new data-space pointer defines name's data field. 
;   CREATE does not allocate data space in name's data field.
;
;   name Execution:
;   ( -- a-addr )
;
;   a-addr is the address of name's data field. 
;   The execution semantics of name may be extended by using DOES>. 
;
;   Set Z flag to FALSE if word can't be created, TRUE otherwise
;

    fenter

    ;   Parse the word
    ld  hl, ' '
    push hl
    fcall code_word
    pop hl                  ; origin
            
    ;   Check word len
    ld  a, (hl)             ; len
    cp  0
    jz  _code_create_error

    ld   de, (_DP)  
    push de         ; destination   ( -- name_addr )
    ;   Calculate total len and save it onto the stack
    ld   d, 0
    ld   e, a       ; de = len
    inc  de         ; total len
    push de         ;               ( -- name_addr len )

    ;   Prepare moving the name
    push hl         ; origin        ( -- name_addr len origin)
    ld   hl, (_DP)  
    push hl         ; destination   ( -- name_addr len origin dest )
    push de         ; length        ( -- name_addr len origin dest len )

    fcall   code_move   ; copy name from input area to heap ( -- name_addr len )
    fcall   code_allot  ; total len already in stack        ( -- name_addr )

    ;   Add to dictionary

    ;   Args for dict_add
    ld      de, code_address
    push    de          ; code address    ( -- name_addr code_addr )
    fcall   code_swap   ;                 ( -- code_addr name_addr )

    fcall   dict_add
    
    ;
    ;   Add empty cell
    ;
    ld  hl, (_DP)
    inc hl
    inc hl
    ld  (_DP), hl

    sub a
    inc a   ; Set Z flag = 0
    fret

_code_create_error:

    ld  hl, err_missing_name
    push hl
    fcall   print_line

    sub a   ; Set Z flag = 1

    fret

        
dict_end:
    ;   
    ;   Add a fret to current word
    ;   ( -- )

    fenter

    ld  hl, (_DP)
    
    ld  (hl), $C3
    inc hl
    ld  de, return
    ld_hl_de
    ;
    ld  (_DP), hl

    fret
    
code_immediate:
;
;   Implements IMMEDIATE
;   ( -- )
;
;   Make the most recent definition an immediate word. 
;   An ambiguous condition exists if the most recent definition 
;   does not have a name or if it was defined as a SYNONYM. 
;
    fenter

    ld  hl, (_DICT)
    inc hl
    inc hl

    ld  a, (hl)
    or  BIT_IMMEDIATE
    ld  (hl), a

    fret

add_cell:
;
;   Add TOS to _DP
;   ( x -- )
;
    fenter
    
    pop de
    ld  hl, (_DP)
    ld  (hl), e
    inc hl
    ld  (hl), d
    inc hl
    ld  (_DP), hl

    fret    

dict_add:
    ;
    ;   Add a new Forth word 
    ;   ( c-addr addr -- )
    ;
    ;   Create new dictionary entry with name c-addr and code addr
    ;   Update _DICT to point to new entry
    ;   Update _DP
    ;
    fenter

    ;   Copy (_DICT) to (_DP)
    ld  de, (_DICT) ; de = last entry address
    ld  hl, (_DP)   ; hl = next free byte address
    ld  (_DICT), hl ; _DICT -> new entry   

    ;   Pointer to next entry
    ld_hl_de
    
    ;   Flags
    ld  (hl), 0
    inc hl

    ;   Copy name address
    pop de          ; c-addr
    ld_hl_de

    ;   Copy code adress
    pop de          ; addr
    ld_hl_de

    ;   Update DP
    ld (_DP), hl

    fret

dict_delete_last:
    ;
    ;   Delete the last word in dictionary
    ;
    ;   Used to recover from aborted word creation
    ;
    fenter

    ld  hl, (_DICT)     ; Last word
    ld  bc, (hl)        ; Next to last word
    ld  (_DICT), bc

    fret

code_see:
;
;   Implements SEE
;   ( "<spaces>name" -- )
;
;   Display a human-readable representation of the named word's definition. 
;   The source of the representation (object-code decompilation, source block, etc.)
;   and the particular form of the display is implementation defined.
;
;   SEE may be implemented using pictured numeric output words. Consequently, its 
;   use may corrupt the transient region identified by #>. 
;
    fenter

    ld hl, ' '
    push hl
    fcall code_word

    fcall dict_search    
    pop hl
    ld  a, h
    or  l
    jp  z, _error_not_found

    ld  a, 16
    ld  (_BASE), a

    push hl
    push hl

    fcall code_dot
    fcall code_space    ; address

    pop hl
    inc hl
    inc hl      ; flags
    ld  a, (hl)
    push af
    inc hl      ; name

    ld de, (hl)
    inc hl
    inc hl
    push hl

    push de
    fcall print_line
    fcall code_space
    pop hl
    pop af

    push hl

    and BIT_COLON
    jz  _see_code_def
    ld  a, FALSE
    ld  (_see_type_code), a
    ld  hl, _see_colon
    jr  _see_imm

_see_code_def:
    ld  hl, _see_code
    ld  a, TRUE
    ld (_see_type_code), a

_see_imm:
    push hl
    fcall print_line
    fcall code_space

    and BIT_IMMEDIATE
    jz  _see_next
    ld  hl, _see_immediate
    push hl
    fcall print_line
    fcall code_space

_see_next:
    fcall code_cr
    pop hl

    
_see_cycle:
   
    ;   Check if end of colon definition

    ld  de, (hl)
    ld  a, d
    or  e
    jr  z, _see_end

    ;   Print the address
    push hl
    push hl
    fcall code_dot
    fcall code_space

    ;   Print the XT 
    pop  hl
    push hl

    ld   de, (hl)       ; xt address
    push de
    push de
    fcall code_dot
    fcall code_space

    ;   For code words, there only one entry to print.
    ld  a, (_see_type_code)
    cp  TRUE
    jr  z, _see_end

    ;   Print the name
    pop  hl             ; xt address
    inc  hl
    inc  hl ; flags
    inc  hl ; name    

    ld   de, (hl)       ; is it an address?
    ld   a, d
    cp   0x40
    jr   c, _see_cycle_next
    push de
    fcall print_line

_see_cycle_next:

    fcall code_cr
    ;   Next entry
    pop hl        
    inc hl
    inc hl

    jr  _see_cycle

_see_end:

    fret

_see_type_code: db 0            ; TRUE -> code, FALSE -> colon
_see_code:      counted_string "code"        
_see_colon:     counted_string "colon"
_see_immediate: counted_string "immediate"

_error_not_found:
    ld      hl, err_word_not_found
    push    hl
    fcall   print_line
    ld hl,  _PAD
    push hl
    fcall print_line
    ld hl, new_line
    push hl
    fcall print_line
    
    fret

dict_search:
    ;
    ;   Search a word in the dictionary
    ;   ( c-addr -- addr | flag )
    ;
    ;   Return address of dict entry if found, 0 if not
    ;

    fenter

    ld  hl, (_DICT) ; First entry
    ld (_dict_ptr), hl

_dict_search_cycle:

    ;   Test list end. HL -> entry
    ld  a, h
    or  a, l
    jr  z, _dict_search_not_found

    ;   Duplicate word address
    pop  hl             ; ( addr -- )  
    push hl
    push hl             ; ( -- addr add )
    fcall code_count    ; ( addr addr -- addr c-addr u )

    ld   hl, (_dict_ptr)
    inc  hl      
    inc  hl      ; hl -> flags
    inc  hl      ; hl -> name address    
    ld   bc, (hl)
    push bc
    fcall code_count        ; ( -- addr c-addr1 u1 c-addr2 u2 )
    fcall code_str_equals   ; ( -- addr flag )
    pop bc                  ; ( -- addr )
    jump_non_zero c, _dict_search_found

    ;   Not found here, try next
    ld  hl, (_dict_ptr)     ; ptr -> entry
    ld  c, (hl)     
    inc hl
    ld  b, (hl)             ; bc -> next_entry

    ld hl, bc
    ld (_dict_ptr), hl  

    jr  _dict_search_cycle

_dict_search_not_found:   
    ;
    ;   Word not found; try to convert to value
    ;   ( addr -- )
    ;

    fcall ascii2bin

    pop hl      ; Flag
    ld  a, l
    or  h       ; Failed? 
    jr  nz, _dict_search_xt_value

    ld  hl, FALSE
    jr _dict_search_end2

_dict_search_xt_value:
    ;
    ;   A value was converted. Now actions depend on
    ;   which state we are.
    ;
    ld  a, (_MODE_INTERPRETER)
    cp  a, TRUE
    jr  nz, _dict_search_xt_compile:

    ;   Mode interpreter
    ;   Value alredady into the stack
    ;   Return a NOP xt

    ld   hl, (xt_nop)
    jr  _dict_search_end2

_dict_search_xt_compile:
    :
    ;   Mode compile
    ;
    fcall  code_literal

;    ld  hl, (xt_literal)
    ;
    ;   The code has been written already, but
    ;   the caller expect a XT, so we return an
    ;   immediate NOP that not change anything.

    ld  hl, (xt_nop)   
    jr  _dict_search_end2

_dict_search_found:
    ld  hl, (_dict_ptr)
_dict_search_end:
    pop  bc     ; Discard word address
_dict_search_end2:
    push hl     ; Push entry address | flag
    
    fret

_dict_ptr:   dw 0

xt_nop: dw 0
code_nop:
;
;   Do nothing, return immediatly
;
    jp  (hl)


code_literal:
;
;   Implements LITERAL
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Compilation:
;   ( x -- )
;
;   Append the run-time semantics given below to the current definition.
;
;   Run-time:
;   ( -- x )
;
;    Place x on the stack.   
;
    fenter

    ld  a, (_MODE_INTERPRETER)
    cp  FALSE
    jp  nz, _code_literal_error

    ;   Compilation mode
    ;   Append the xt for literal to the last word

    ld  hl, (_DP)
    ld  de, (xt_literal)
    ld  (hl), e
    inc hl
    ld  (hl), d
    inc hl

    ;   Now append the value 
    pop de
    ld  (hl), e
    inc hl
    ld  (hl), d
    inc hl
    
    ;   Update DP
    ld  (_DP), hl

    fret


xt_literal: dw   0          ; code_literal_runtime XT  
code_literal_runtime:

    fenter

    ;   In interpreter mode, _EX_STACK give the next execution token address
    ;   in the current word. It's used by code_execute to keep trace of what
    ;   word is executing.
    ;   
    ld      hl, (_EX_PTR)
    
    ;   Get the value address
    ld      c, (hl)     ; bc = @ cell
    inc     hl
    ld      b, (hl)

    ld      de, bc      ; Remember the value address
    
    ;   Extract the value
    ld      hl, bc      ; load value at cell
    ld      c, (hl)
    inc     hl
    ld      b, (hl)

    push    bc

    ;   Now, change the "next inst" to skip over the value
    inc     de
    inc     de              ; DE point to next xt

    ld      hl, (_EX_PTR)   ; Get second to last address in EX_STACK 
    ld      (hl), e         ; Change the xt token address
    inc     hl
    ld      (hl), d    

    fret
    
_code_literal_error:
    ;
    ld  hl, err_mode_not_comp
    push hl
    fcall   print_line
    ld  hl, _PAD
    push hl
    fcall   print_line
    fcall   code_backslash       ; Forget the remaining words
    fret

    
macro mdict_add st, code
    ld hl, code
    push hl
    ld hl, st
    push hl
    fcall dict_add
endm


dict_init:
    ;   
    ;   Initialize the dictionary with some Forth words
    ;
    fenter

    mdict_add st_nop,       code_nop
    fcall code_immediate    
    ld  hl, (_DICT)
    ld  (xt_nop), hl    

    mdict_add st_literal,   code_literal_runtime
    ld  hl, (_DICT)
    ld  (xt_literal), hl

    mdict_add st_if,        code_if_runtime
    ld  hl, (_DICT)
    ld  (xt_if), hl

    ;   Previous entries are shadowed by the "official" entries, later

    mdict_add st_count,     code_count
    mdict_add st_type,      code_type
    mdict_add st_refill,    code_refill
    mdict_add st_space,     code_space
    mdict_add st_negate,    code_negate
    mdict_add st_tick,      code_tick
    mdict_add st_str_equals,code_str_equals
    mdict_add st_words,     code_words
    mdict_add st_pad,       code_pad
    mdict_add st_dot,       code_dot
    mdict_add st_dup,       code_dup
    mdict_add st_plus,      code_plus
    mdict_add st_minus,     code_minus
    mdict_add st_star,      code_star
    mdict_add st_slash,     code_slash
    mdict_add st_rshift,    code_rshift
    mdict_add st_lshift,    code_lshift
    mdict_add st_swap,      code_swap
    mdict_add st_f_m_slash_mod, code_f_m_slash_mod
    mdict_add st_immediate, code_immediate
    mdict_add st_to_r,      code_to_r
    mdict_add st_r_from,    code_r_from
    mdict_add st_r_fetch,   code_r_fetch
    mdict_add st_cmove,     code_cmove
    mdict_add st_align,     code_align
    mdict_add st_aligned,   code_aligned
    mdict_add st_here,      code_here
    mdict_add st_allot,     code_allot
    mdict_add st_create,    code_create
    mdict_add st_colon,     code_colon
    mdict_add st_semmicolon,code_semmicolon
    fcall code_immediate
    mdict_add st_store,     code_store
    mdict_add st_fetch,     code_fetch
    mdict_add st_literal,   code_literal
    mdict_add st_backslash, code_backslash
    fcall code_immediate
    mdict_add st_bye,       code_bye
    mdict_add st_evaluate,  code_evaluate
    mdict_add st_base,      code_base
    mdict_add st_and,       code_and
    mdict_add st_false,     code_false
    mdict_add st_true,      code_true
    mdict_add st_drop,      code_drop
    mdict_add st_emit,      code_emit
    mdict_add st_pick,      code_pick
    mdict_add st_if,        code_if
    fcall code_immediate
    mdict_add st_then,      code_then
    fcall code_immediate
    
    mdict_add st_see,       code_see
    mdict_add st_cr,        code_cr
    
    fret

st_nop:         counted_string ""
st_pad:         counted_string "pad"
st_count:       counted_string "count"
st_type:        counted_string "type"
st_refill:      counted_string "refill"
st_plus:        counted_string "+"
st_words:       counted_string "words"
st_space:       counted_string "space"
st_negate:      counted_string "negate"
st_tick:        counted_string "'"
st_str_equals:  counted_string "str="
st_dup:         counted_string "dup"
st_and:         counted_string "and"
st_dot:         counted_string "."
st_star:        counted_string "*"
st_minus:       counted_string "-"
st_slash:       counted_string "/"
st_to_r:        counted_string ">r"
st_r_from:      counted_string "r>"
st_r_fetch:     counted_string "r@"
st_f_m_slash_mod: counted_string "fm/mod"
st_cmove:       counted_string "cmove"
st_align:       counted_string "align"
st_aligned:     counted_string "aligned"
st_here:        counted_string "here"
st_create:      counted_string "create"
st_allot:       counted_string "allot"
st_colon:       counted_string ":"
st_semmicolon:  counted_string ";"
st_store:       counted_string "!"
st_fetch:       counted_string "@"
st_swap:        counted_string "swap"
st_immediate:   counted_string "immediate"
st_literal:     counted_string "literal"
st_backslash:   counted_string "\\"
st_evaluate:    counted_string "evaluate"
st_bye:         counted_string "bye"
st_base:        counted_string "base"
st_true:        counted_string "true"
st_false:       counted_string "false"
st_drop:        counted_string "drop"
st_emit:        counted_string "emit"
st_pick:        counted_string "pick"
st_if:          counted_string "if"
st_then:        counted_string "then"
st_see:         counted_string "see"
st_rshift:      counted_string "rshift"
st_lshift:      counted_string "lshift"
st_cr:          counted_string "cr"


