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
    fenter

    ;   Parse the word
    ld  hl, ' '
    push hl
    fcall code_word
    pop hl
            
    ;   Check word len
    ld  a, (hl)
    cp  0
    jz  _code_create_error

    ;   Calculate total len and save it onto the stack
    ld   d, 0
    ld   e, a       ; de = len
    inc  de         ; total len
    push de

    ;   Prepare move
    push hl         ; origin
    ld   hl, (_DP)  
    push hl         ; destination
    push de         ; length

    fcall code_move ; copy name from input area to heap

    ;   Prepare call to add    

    ;   Update _DP

    pop     bc          ; len
    ld      hl, (_DP)   ; _DP

    ;   Args for dict_add
    ld      de, code_address
    push    de          ; code address    
    push    hl          ; name address

    add     hl, bc      ; hl = (_DP) + len
    ld      (_DP), hl   ; new _DP

    ;   Add to dictionary

    fcall dict_add
    
    fret

_code_create_error:
    ld  hl, err_missing_name
    push hl
    fcall   print_line
    fret

        
code_address:
;
;   Push _IP (instruction pointer) into the stack
;
    
    ret

dict_make_colon:
;
;   Mark a word as COLON definition
;   ( addr -- )
;
;   addr is the entry address for the word
;
    pop de
    inc de
    inc de
    ld  a, (de)
    or  1
    ld  (de), a

    jp (hl)

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
    ld  hl, FALSE
    jr _dict_search_end
_dict_search_found:
    ld  hl, (_dict_ptr)
_dict_search_end:
    pop  bc     ; Discard word address
    push hl     ; Push entry address | flag
    
    fret

_dict_ptr:   dw 0

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

    mdict_add st_count,     code_count
    mdict_add st_type,      code_type
    mdict_add st_refill,    code_refill
    mdict_add st_space,     code_space
    mdict_add st_bl,        code_bl
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
    mdict_add st_f_m_slash_mod, code_f_m_slash_mod
    mdict_add st_to_r,      code_to_r
    mdict_add st_r_from,    code_r_from
    mdict_add st_r_fetch,   code_r_fetch
    mdict_add st_cmove,     code_cmove
    mdict_add st_align,     code_align
    mdict_add st_aligned,   code_aligned
    mdict_add st_here,      code_here
    mdict_add st_allot,     code_allot
    mdict_add st_create,    code_create
    fret

st_pad:         counted_string "pad"
st_count:       counted_string "count"
st_type:        counted_string "type"
st_refill:      counted_string "refill"
st_plus:        counted_string "+"
st_words:       counted_string "words"
st_space:       counted_string "space"
st_bl:          counted_string "bl"
st_negate:      counted_string "negate"
st_tick:        counted_string "'"
st_str_equals:  counted_string "str="
st_dup:         counted_string "dup"
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

