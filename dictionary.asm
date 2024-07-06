
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
    ;   ( c-addr -- xt | flag )
    ;
    ;   Return xt if found, 0 in other case
    ;
    fenter

    pop hl          ; Word to be searched
    ld  de, _DICT

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

    mdict_add st_words,     code_words
    mdict_add st_pad,       code_pad
    mdict_add st_count,     code_count
    mdict_add st_type,      code_type
    mdict_add st_refill,    code_refill
    mdict_add st_plus,      code_plus
    mdict_add st_space,     code_space
    mdict_add st_bl,        code_bl
    mdict_add st_negate,    code_negate

    fret

st_pad:     counted_string "PAD"
st_count:   counted_string "COUNT"
st_type:    counted_string "TYPE"
st_refill:  counted_string "REFILL"
st_plus:    counted_string "PLUS"
st_words:   counted_string "WORDS"
st_space:   counted_string "SPACE"
st_bl:      counted_string "BL"
st_negate:  counted_string "NEGATE"

