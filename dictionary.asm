
;   ld (hl), de
;   Copy DE to (HL), HL = HL + 2 
macro ld_hl_de
    ld  (hl), e
    inc hl
    ld  (hl), d
    inc hl
endm

dict_add:
    ;
    ;   Add new Forth word to dictionary
    ;   ( addr c-addr -- )
    ;
    ;   Receive code addres and name (as a counted-string)
    ;
    fenter

    ;   Copy (_DICT) to (_DP)
    ld  de, (_DICT) ; de = last entry address
    ld  hl, (_DP)   ; hl = next free byte address   
    ld  bc, hl      ; bc = new value for _DICT
    ;   Pointer to next entry
    ld_hl_de
    ;   Flags
    ld  (hl), 0
    inc hl
    ;   Copy name address
    pop de          ; c-addr
    ld_hl_de
    ;   Copy code address
    pop de
    ld_hl_de

    ;   Update heap
    ld  (_DP), hl   ; _DP -> next free
    ld  (_DICT), bc ; _DICT -> new entry
    
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
    mdict_add st_plus,      code_plus
    mdict_add st_space,     code_space
    mdict_add st_bl,        code_bl
    mdict_add st_negate,    code_negate
    mdict_add st_tick,      code_tick
    mdict_add st_str_equals,code_str_equals
    mdict_add st_words,     code_words
    mdict_add st_pad,       code_pad
    mdict_add st_dot,       code_dot
    mdict_add st_dup,       code_dup

    fret

st_pad:         counted_string "PAD"
st_count:       counted_string "COUNT"
st_type:        counted_string "TYPE"
st_refill:      counted_string "REFILL"
st_plus:        counted_string "+"
st_words:       counted_string "WORDS"
st_space:       counted_string "SPACE"
st_bl:          counted_string "BL"
st_negate:      counted_string "NEGATE"
st_tick:        counted_string "'"
st_str_equals:  counted_string "STR="
st_dup:         counted_string "DUP"
st_dot:         counted_string "."
