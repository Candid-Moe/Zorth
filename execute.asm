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

    pop hl

    inc hl
    inc hl      ; hl -> flags    
    
    ld  a, (hl) ; A = flags
    
    inc hl      ; hl -> name
    inc hl  
    inc hl      ; hl -> code/colon

    ld (_IP), hl    ; Save it just for reference

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

    push hl             ; Save it

    ;   Store address next xt en EX_STACK

    inc hl
    inc hl
    ctrl_push

    pop     hl
    ld      bc, (hl)    ; extract xt
    push    bc          ; Pass to EXECUTE

    fcall   code_execute

    ;   Recover address next xt.

    ctrl_pop

    ;   Check for 0x0000 at the end of code.
    ld  de, (hl)      ; load xt
    ld  a, e
    or  d
    jr  nz, _ex_colon
    
    jr  _ex_end

_ex_end:
    
    fret


