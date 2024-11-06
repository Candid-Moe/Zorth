;   Zorth - (c) Candid Moe 2024

;   dictionary: operations that affect the word list
;
;   Words are store in lower case always.
;
;   Entry Format:
;
;   - address next entry (word)
;   - # words (byte)
;   - flags (byte)
;   - name address 
;   - Code Address (for code words) or List of XT (colon definition)
;
;   Flags:
;   - bit 0: COLON (1) / CODE (0)
;   - bit 1: IMMEDIATE (1) / normal (0)

;   Execution tokens for words with run-time semantic
xt_if:      dw  0           ; IF runtime execution token.
xt_jz:      dw  0           ; Jump if zero
xt_jp:      dw  0           ; Jump
xt_do:      dw  0           ; DO 
xt_does:    dw  0           ; DOES
xt_loop:    dw  0           ; LOOP
xt_plus_loop: dw 0          ; +LOOP
xt_unloop:  dw  0           ; UNLOOP
xt_leave:   dw  0           ; LEAVE
xt_literal: dw  0           ; LITERAL
xt_comma:   dw  0           ; ,
xt_postpone: dw 0           ; POSTPONE
xt_noop:     dw  0           ; No Operation


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

    ld      de, (_DP)  
    push    de         ; destination   ( -- name_addr )
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
    ;   We need cells for address/does> ops
    ld      de, (xt_noop)
    push    de          ; ( -- name_addr code_addr )
    fcall   code_swap   ; ( -- code_addr name_addr )
    fcall   dict_add
    
    ld      hl, (xt_address)
    push    hl
    fcall   code_comma    ; 

    ;   Make it a colon definition

    ld  hl, (_DICT)
    inc hl
    inc hl      ; # words
    ld  a, 2
    ld (hl), a
    inc hl      ; flag

    ld  a, (hl)
    or  BIT_COLON
    ld  (hl), a
    
    sub a
    inc a   ; Set Z flag = 0

    fret

_code_create_error:

    ld  hl, err_missing_name
    push hl
    fcall   print_line

    sub a   ; Set Z flag = 1

    fret

code_does:
;
;   Implements DOES>
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Compilation:
;   ( C: colon-sys1 -- colon-sys2 )
;
;   Append the run-time semantics below to the current definition. 
;   Whether or not the current definition is rendered findable in the 
;   dictionary by the compilation of DOES> is implementation defined. 
;   Consume colon-sys1 and produce colon-sys2. 
;   Append the initiation semantics given below to the current definition.
;
;   Run-time:
;   ( -- ) ( R: nest-sys1 -- )
;
;   Replace the execution semantics of the most recent definition, referred to as name,
;   with the name execution semantics given below. Return control to the calling 
;   definition specified by nest-sys1. 
;   An ambiguous condition exists if name was not defined with CREATE or a user-defined
;   word that calls CREATE.
;
;   Initiation:
;   ( i * x -- i * x a-addr ) ( R: -- nest-sys2 )
:
;   Save implementation-dependent information nest-sys2 about the calling definition.
;   Place name's data field address on the stack. 
;   The stack effects i * x represent arguments to name.
;
;   name Execution:
;   ( i * x -- j * x )
;
;   Execute the portion of the definition that begins with the initiation semantics
;   appended by the DOES> which modified name. The stack effects i * x and j * x 
;   represent arguments to and results from name, respectively. 
 
    fenter

    ;
    ;   Replace old default instruction from create
    ;   with does>
    ;

    ld  hl, (_DICT)
    inc hl  
    inc hl  ; # words
    inc hl  ; flags
    inc hl  ; name
    inc hl  
    inc hl  ; code
   
    ld  de, (xt_does)   ; Reeplace old code with DOES>
    ld  (hl), de
    
    inc hl
    inc hl
    ld  de, hl

    ex_pop
    ex  hl, de
    ld  (hl), de        ; Save address where does> start
    ld hl, _EXIT        ; Terminate word execution
    ex_push
                   
    fret       

_does_exec:

    fenter

    ;   First, put next address into the stack
    ex_pop
    ld  de, (hl)        ; @does>

    inc     hl
    inc     hl
    push    hl          ; >BODY
    ;

    ld  hl, de
    ex_push
    ;       
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
    inc hl  ; # words
    inc hl  ; flags

    ld  a, (hl)
    or  BIT_IMMEDIATE
    ld  (hl), a

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

    fcall   code_align

    ;   Copy (_DICT) to (_DP)
    ld  de, (_DICT) ; de = last entry address
    ld  hl, (_DP)   ; hl = next free byte address
    ld  (_DICT), hl ; _DICT -> new entry   

    ;   Pointer to next entry
    ld_hl_de

    ;   # words
    ld  (hl), 1
    inc hl
    
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

xt_address: dw 0
code_address:
;
;   Push next cell address to the stack
;   Change ctrl stack to skip over the next cell
;
    fenter

    ex_pop        ; ctrl stack contain next cell address.
    push    hl

    ld hl, _EXIT
    ex_push       ; and end word

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
    ;   
    ;   In compilation mode, don't look at the first entry,
    ;   which is under construction and not yet valid.
    ;   (This way you can extend a previous word)
    ;
    ld  a, (_STATE)
    cp  FALSE
    jr  z, _dict_search_start

    ;   Compilation mode

    ld  bc, (hl)
    ld  hl, bc

_dict_search_start:

    ld (_dict_ptr), hl

_dict_search_cycle:

    ;   Test list end. HL -> entry
    ld  a, h
    or  l
    jr  z, _dict_search_not_found

    ;   Duplicate word address
    dup   hl            ; ( -- addr addr )
    fcall code_count    ; ( addr addr -- addr c-addr u )

    ld   hl, (_dict_ptr)
    inc  hl      
    inc  hl      ; # words
    inc  hl      ; hl -> flags
    inc  hl      ; hl -> name address    
    ld   bc, (hl)
    push bc
    fcall code_count        ; ( -- addr c-addr1 u1 c-addr2 u2 )
    fcall code_str_equals_i ; ( -- addr flag )
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
    
    ld      hl, FALSE
    jr      _dict_search_end

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
    jr _dict_search_end     ; word not found, not a value

_dict_search_xt_value:
    ;
    ;   A value was converted. Now actions depend on
    ;   which state we are.
    ;
    ld  a, (_STATE)
    cp  a, FALSE
    jr  nz, _dict_search_xt_compile:

    ;   Mode interpreter
    ;   Value alredady into the stack
    ;   Return a NOP xt

    ld   hl, (xt_noop)
    jr  _dict_search_end2

_dict_search_xt_compile:
    :
    ;   Mode compile
    ;
    fcall  code_literal

    ;
    ;   The code has been written already, but
    ;   the caller expect a XT, so we return an
    ;   immediate NOP that not change anything.

    ld  hl, (xt_noop)   
    jr  _dict_search_end2

_dict_search_found:
    ld  hl, (_dict_ptr)
_dict_search_end:
    pop  bc     ; Discard word address
_dict_search_end2:
    push hl     ; Push entry address | flag
    
    fret

_dict_ptr:   dw 0

code_noop:
;
;   Implements NOOP
;   ( -- )
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

    ld  a, (_STATE)
    cp  TRUE
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

code_literal_runtime:

    fenter

    ;   In interpreter mode, execution stack have the next execution token address
    ;   in the current word. It's used by code_execute to keep trace of what
    ;   word is executing.
    ;   
    ex_pop
    
    ;   Get the value
    ld      c, (hl)    
    inc     hl
    ld      b, (hl)
    inc     hl          ; HL -> next xt

    push    bc          ; Put value into stack

    ;   Now, change the "next inst" to skip over the value

    ex_push

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

code_postpone:
;
;   Implements POSTPONE
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Compilation:
;   ( "<spaces>name" -- )
;
;   Skip leading space delimiters. Parse name delimited by a space. Find name. 
;   Append the compilation semantics of name to the current definition.
;   An ambiguous condition exists if name is not found.
;
    fenter

    ld      a, (_STATE)
    cp      FALSE
    jp      z, _code_postpone_error

    ld      hl, ' '
    push    hl
    fcall   code_word   ; ( ' ' -- c-addr )
    fcall   dict_search ; ( c-addr -- xt )
    
    ;   
    pop     hl
    push    hl
    ld      a, h
    or      l
    jr      nz, _code_postpone_next

    ;   Word not found

    pop     hl          ; Discard value
    fcall   error_word_not_found
    fret

_code_postpone_next:

    dup     hl              ; ( xt -- xt xt )
    fcall   check_immediate ; ( -- xt flag)
    pop     bc              ; ( -- xt )
    ld      a, b
    or      c
    jr      z, _code_postpone_save

    ;   It's an immediate word

    fcall   code_comma        ; ( -- )

    fret

_code_postpone_save:
    
    ;   Store xt as a literal (non immediate word)
    
    fcall   code_literal

    ld      hl, (xt_comma)
    push    hl
    fcall   code_comma    ; ( xt -- )

    fret    
    
_code_postpone_runtime:
    ;
    ;   Take the XT from the next cell and 
    ;   call execute
    ;
    fenter

    ex_pop        ; Recover address of next xt.
    push hl         ; ( -- @XT )
    inc hl
    inc hl
    ex_push       ; Jump over to the next address

    pop     hl      ; ( @XT -- ) Take de address, recover the XT
    ld      de, (hl)
    push    de      ; ( -- XT )
    ld      hl, de
    ;
    call    _ex_classify
    jr      nz, _code_postpone_execute

    ;   Execute a CODE works.
    ;   Call the code directly

    pop bc          ; ( xt -- ) discard XT
    ld  bc, (hl)
    ld (_postpone_jp + 1), bc   ; HL was filled by _ex_classify
    ld hl, _code_postpone_end

_postpone_jp:    
    jp   0          ; dest. will be overwritten 


_code_postpone_execute:

    fcall   code_execute

_code_postpone_end:
    
    fret
    
_code_postpone_error:

    jp  _code_mode_error

code_comma:
;
;   Implements , 
;   ( x -- )
;
;   Reserve one cell of data space and store x in the cell. 
;   If the data-space pointer is aligned when , begins execution, 
;   it will remain aligned when , finishes execution. 
;   An ambiguous condition exists if the data-space pointer is not 
;   aligned prior to execution of ,. 

    fenter
    
    pop de
    ld  hl, (_DP)
    ld  (hl), e
    inc hl
    ld  (hl), d
    inc hl
    ld  (_DP), hl

    fret    

code_hide:
;
;   Implement hide
;   ( -- )
;
;   Take the word out of the dictionary
;   xt remains valid
;
    fenter

    ld  hl, (_DICT)     ; last entry 
    ld  de, (hl)        ; next entry
    ld  (_DICT), de     ; 
   
    fret

code_dict:
;
;   Implements DICT
;   ( -- addr )
;
;   Return address of dictionary head
;
    ld      bc, _DICT
    push    bc
    jp      (hl)

macro mdict_add st, code
    ld hl, code
    push hl
    ld hl, st
    push hl
    fcall dict_add
endm

macro mdict_xt xt
    ld hl, (_DICT)
    ld (xt), hl
    fcall code_hide
endm

dict_init:
    ;   
    ;   Initialize the dictionary with some Forth words
    ;
    fenter

    mdict_add st_literal,       code_literal_runtime
    mdict_xt xt_literal

    mdict_add st_address,       code_address
    mdict_xt xt_address

    mdict_add st_postpone,      _code_postpone_runtime
    mdict_xt xt_postpone

    mdict_add st_do,            code_do_runtime
    mdict_xt xt_do

    mdict_add st_loop,          code_loop_runtime
    mdict_xt xt_loop

    mdict_add st_plus_loop,     code_plus_loop_runtime
    mdict_xt xt_plus_loop
    
    mdict_add st_leave,         code_leave_runtime
    mdict_xt xt_leave

    mdict_add st_unloop,        code_loop_runtime
    mdict_xt xt_unloop

    ;   Add visible words

    mdict_add st_noop,      code_noop
    fcall code_immediate    
    ld  hl, (_DICT)
    ld  (xt_noop), hl

    mdict_add st_jz,        code_jz
    ld  hl, (_DICT)
    ld  (xt_jz), hl

    mdict_add st_jump,      code_jp
    ld  hl, (_DICT)
    ld  (xt_jp), hl

    mdict_add st_comma,     code_comma
    ld  hl, (_DICT)
    ld  (xt_comma), hl

    mdict_add st_does,      _does_exec
    ld hl, (_DICT)
    ld (xt_does), hl


    mdict_add st_less_number_sign, code_less_number_sign
    mdict_add st_number_sign,   code_number_sign
    mdict_add st_number_sign_greater, code_number_sign_greater
    mdict_add st_hold,          code_hold   
    mdict_add st_number_sign_s, code_number_sign_s
    mdict_add st_sign,          code_sign

    mdict_add st_int2bcd,   code_int2bcd
    mdict_add st_scan,      code_scan
    mdict_add st_z80_syscall,   code_z80_syscall
    mdict_add st_heap,      code_heap
    mdict_add st_hide,      code_hide
    mdict_add st_key,       code_key
    mdict_add st_key_question, code_key_question
    mdict_add st_accept,    code_accept
    mdict_add st_count,     code_count
    mdict_add st_type,      code_type
    mdict_add st_in,        code_in
    mdict_add st_refill,    code_refill
    mdict_add st_space,     code_space
    mdict_add st_negate,    code_negate
    mdict_add st_str_equals,code_str_equals
    mdict_add st_word,      code_word
    mdict_add st_pad,       code_pad
    mdict_add st_dup,       code_dup
    mdict_add st_plus,      code_plus
    mdict_add st_minus,     code_minus
    mdict_add st_star,      code_star
    mdict_add st_rshift,    code_rshift
    mdict_add st_lshift,    code_lshift
    mdict_add st_swap,      code_swap
    mdict_add st_s_m_slash_rem, code_s_m_slash_rem
    mdict_add st_immediate, code_immediate
    mdict_add st_to_r,      code_to_r
    mdict_add st_r_from,    code_r_from
    mdict_add st_r_fetch,   code_r_fetch
    mdict_add st_rdrop,     code_rdrop
    mdict_add st_two_to_r,  code_two_to_r
    mdict_add st_two_r_from, code_two_r_from
    mdict_add st_to_cs,     code_to_cs
    mdict_add st_cs_from,   code_cs_from
    mdict_add st_cs_fetch,  code_cs_fetch
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
    mdict_add st_or,        code_or
    mdict_add st_false,     code_false
    mdict_add st_true,      code_true
    mdict_add st_drop,      code_drop
    mdict_add st_emit,      code_emit
    mdict_add st_pick,      code_pick
    
    mdict_add st_cr,        code_cr
    mdict_add st_invert,    code_invert

    mdict_add st_c_fetch,   code_c_fetch
    mdict_add st_c_store,   code_c_store
    mdict_add st_depth,     code_depth

    mdict_add st_postpone,  code_postpone
    fcall code_immediate 

    mdict_add st_abort,     code_abort
    mdict_add st_quit,      code_quit
    mdict_add st_parse,     code_parse
    mdict_add st_does,      code_does
    

    mdict_add st_state,     code_state

    mdict_add st_do,        code_do
    fcall code_immediate

    mdict_add st_loop,      code_loop
    fcall code_immediate

    mdict_add st_plus_loop, code_plus_loop
    fcall code_immediate

    mdict_add st_i,         code_i
    mdict_add st_s_quote,   code_s_quote
    fcall code_immediate

    mdict_add st_leave,     code_leave
    fcall code_immediate

    mdict_add st_ud_slash_mod, code_ud_slash_mod
    mdict_add st_two_slash, code_two_slash
    mdict_add st_m_star,    code_m_star
    mdict_add st_u_m_star,  code_u_m_star
    mdict_add st_xor,       code_xor
    mdict_add st_source,    code_source
    mdict_add st_unloop,    code_unloop
    mdict_add st_j,         code_j
    mdict_add st_execute,   code_execute
    mdict_add st_dict,      code_dict
    mdict_add st_move,      code_move
    mdict_add st_ioctl,     code_ioctl
    mdict_add st_at_xy,     code_at_xy
    mdict_add st_page,      code_page
    mdict_add st_colors,    code_colors
    mdict_add st_c_quote,   code_c_quote
    fcall code_immediate
    mdict_add st_find,      code_find
    mdict_add st_source_id, code_source_id
    mdict_add st_s_to_d,    code_s_to_d
    mdict_add st_cs_roll,   code_cs_roll
    mdict_add st_t_open,    code_t_open
    mdict_add st_rigth_arrow, code_right_arrow
    mdict_add st_t_close,   code_t_close

    mdict_add st_less_than, code_less_than
    mdict_add st_greater_than, code_greater_than
    mdict_add st_equals,    code_equals
    mdict_add st_u_less_than, code_u_less_than
    mdict_add st_u_greater_than, code_u_greater_than    

    fret

st_less_than:   counted_string "<"
st_greater_than: counted_string ">"
st_equals:      counted_string "="
st_u_less_than: counted_string "u<"
st_u_greater_than: counted_string "u>"

st_less_number_sign: counted_string "<#"
st_number_sign: counted_string "#"
st_number_sign_greater: counted_string "#>"
st_hold:        counted_string "hold"
st_number_sign_s: counted_string "#s"
st_sign:        counted_string "sign"

st_int2bcd:     counted_string "int2bcd"
st_scan:        counted_string "scan"
st_z80_syscall: counted_string "z80-syscall"
st_heap:        counted_string "heap"
st_hide:        counted_string "hide"
st_ud_slash_mod: counted_string "ud/mod"
st_key:         counted_string "key"
st_key_question: counted_string "key?"
st_accept:      counted_string "accept"
st_comma:       counted_string ","
st_address:     counted_string "address"
st_noop:        counted_string "noop"
st_pad:         counted_string "pad"
st_count:       counted_string "count"
st_type:        counted_string "type"
st_refill:      counted_string "refill"
st_plus:        counted_string "+"
st_word:        counted_string "word"
st_space:       counted_string "space"
st_negate:      counted_string "negate"
st_str_equals:  counted_string "str="
st_dup:         counted_string "dup"
st_and:         counted_string "and"
st_or:          counted_string "or"
st_star:        counted_string "*"
st_m_star:      counted_string "m*"
st_minus:       counted_string "-"
st_slash:       counted_string "/"
st_to_r:        counted_string ">r"
st_r_from:      counted_string "r>"
st_r_fetch:     counted_string "r@"
st_rdrop:       counted_string "rdrop"
st_two_to_r:    counted_string "2>r"
st_two_r_from:  counted_string "2r>"
st_to_cs:       counted_string  ">cs"
st_cs_from:     counted_string  "cs>"
st_cs_fetch:    counted_string "cs@"    
st_s_m_slash_rem: counted_string "sm/rem"
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
st_jump:        counted_string "jmp"
st_rshift:      counted_string "rshift"
st_lshift:      counted_string "lshift"
st_cr:          counted_string "cr"
st_invert:      counted_string "invert"
st_jz:          counted_string "jz"
st_c_fetch:     counted_string "c@"
st_c_store:     counted_string "c!"
st_depth:       counted_string "depth"
st_postpone:    counted_string "postpone"
st_abort:       counted_string "abort"
st_quit:        counted_string "quit"
st_parse:       counted_string "parse"
st_s_quote:     counted_string "s\""
st_does:        counted_string "does>"
st_state:       counted_string "state"
st_do:          counted_string "do"
st_loop:        counted_string "loop"
st_plus_loop:   counted_string "+loop"
st_i:           counted_string "i"
st_leave:       counted_string "leave"
st_two_slash:   counted_string "2/"
st_u_m_star:    counted_string "um*"
st_xor:         counted_string "xor"
st_source:      counted_string "source"
st_unloop:      counted_string "unloop"
st_j:           counted_string "j"
st_execute:     counted_string "execute"
st_dict:        counted_string "dict"
st_move:        counted_string "move"
st_ioctl:       counted_string "ioctl"
st_at_xy:       counted_string "at-xy"
st_page:        counted_string "page"
st_colors:      counted_string "colors"
st_ctrl_push:   counted_string ">ctrl"
st_ctrl_pop:    counted_string "ctrl>"
st_c_quote:     counted_string "c\""
st_find:        counted_string "find"
st_source_id:   counted_string "source-id"
st_in:          counted_string ">in"
st_s_to_d:      counted_string "s>d"
st_cs_roll:     counted_string "cs-roll"
st_t_open:      counted_string "T{"
st_rigth_arrow: counted_string "->"
st_t_close:     counted_string "}T"

