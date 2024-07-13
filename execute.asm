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
    
    ld  a, (hl) ;
    and 0x01    ; Test the CODE/COLON flag
    push af     ; Keep it
    
    inc hl      ; hl -> name

    inc hl  
    inc hl      ; hl -> code/colon

    ;   Address next xt

    push    hl      ; Remember address
    ld  de, hl
    inc de
    inc de          ; address next xt
    
    push de
    fcall _ex_push  ; Store in own stack
    pop hl          ; Recover address
    ;   Push address next instruction 

    pop af

    jr  nz, _ex_colon
    jr  _ex_code

_ex_end:
    
    fret

_ex_code:
    ;
    ;   Execute a code word
    ;   HL = code address

    ;   Putting the dest. address in the jp inst.

    ld bc, (hl)
    ld (_ex_jp + 1), bc
    ld hl, _ex_code_end

_ex_jp:    
    jp   0          ; dest. will be overwritten 

_ex_code_end:

    ;   Discard next xt
    fcall _ex_pop
    pop hl
    
    fret    

_ex_colon:
    ;   ( -- )
    ;   HL is the address where the code address is stored
    
    fcall   code_execute

    fcall _ex_pop
    pop hl

    ld  a, l
    or  h
    jr  nz, _ex_colon
    
    jr  _ex_end

_ex_push:
;
;   Push address next instruction in our own stack
;   ( addr -- )
;
    fenter

    pop de

    ld  bc, (_EX_PTR)

    dec bc
    ld  a, e
    ld  (bc), a
    dec bc
    ld  a, d
    ld  (bc), a
    ld  (_EX_PTR), bc

    fret

_ex_pop:
;
;   Recover address next instruction    
;   ( -- addr )
;
    fenter

    ld  hl, (_EX_PTR)
    ld  bc, (hl)
    inc hl
    inc hl
    ld (_EX_PTR), hl
    
    push hl

    fret

code_address:
;
;   Extract next address from execution stack and push into stack
;
    fenter

    ld de, (_EX_PTR)
    push de             ; copy into stack

    inc de
    inc de              ; replace next instruction address

    ld hl, _EX_PTR
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl

    fret



;--- Return Stack for Execute ---
_EX_PTR:    dw _EX_STACK
            defs 128
_EX_STACK:  dw _EX_STACK
            dw  0x5050



