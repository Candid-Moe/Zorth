;   Zorth - (c) Candid Moe 2024
;
;   execute: colon and code execution
;
;   An execution token (xt) is the address of the entry in the dictionary
;

code_execute:
;
;   Implements EXECUTE
;   ( i * x xt -- j * x )
;
;   Remove xt from the stack and perform the semantics identified by it. 
;   Other stack effects are due to the word EXECUTEd. 
;
    fenter

    pop hl              ; ( xt -- )

    inc hl
    inc hl      ; # words

    ld  e, 0
    ld  d, (hl)

    inc hl      ; hl -> flags        
    ld  a, (hl) ; A = flags
    
    inc hl      ; hl -> name
    inc hl  
    inc hl      ; hl -> code/colon

    and BIT_COLON   ; Test the CODE/COLON flag

    jr  nz, _ex_colon
    jr  _ex_code

_ex_code:
    ;
    ;   Execute a code word
    ;   HL = code address

    ;   Putting the dest. address in the jp inst.

    ld bc, (hl)
    ld (_ex_jp + 1), bc
    ld hl, _ex_end

_ex_jp:    
    jp   0          ; dest. will be overwritten 

_ex_colon:
    ;   Execute a colon word
    ;   ( -- )
    ;
    ;   Colon word is a list of xt addresses.
    ;
    ;   HL is the list address
    ;   DE # cells in the list

    push hl

    add hl, de
    add hl, de
    ex  hl, de  ;   DE = @last instruction + 1

    pop hl
    push de

_ex_colon_cycle:

    push hl             ; Save it           ( -- @xt )

    ;   Store address next xt en ctrl stack

    inc hl
    inc hl
    ctrl_push           ;                  ( -- @xt )

    pop     hl          ;                  ( @xt -- )
    ld      bc, (hl)    ; extract xt
    push    bc          ; Pass to EXECUTE   ( -- xt )

    fcall   code_execute

    ;   Recover address next xt.
    ctrl_pop
    pop de
    ld  a, h
    cp  d
    jr  nz, _ex_end
    ld  a, l
    cp  e
    jr  nz, _ex_end
    push de

    jr  _ex_colon_cycle

_ex_end:
    
    fret


