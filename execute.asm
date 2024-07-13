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
    
    inc hl      ; hl -> name

    inc hl  
    inc hl      ; hl -> code/colon

    and 0x01    ; Test the CODE/COLON flag

    jr  nz, _ex_colon

    ;   Execute a code word
    ;   Putting the dest. address in the jp inst.

    ld bc, (hl)
    ld (_ex_jp + 1), bc
    ld hl, _ex_end

_ex_jp:    
    jp   0          ; dest. will be overwritten 

_ex_end:
    
    fret
    
_ex_colon:
    ;   ( addr -- )
    ;   HL is the address where the code address is stored

    ld  de, hl
    inc de
    inc de      ; address next instruction

    ;   Push address next instruction in our own stack
    ld  bc, (_EX_STACK)

    dec bc
    ld  a, e
    ld  (bc), a
    dec bc
    ld  a, d
    ld  (bc), a
    ld  (_EX_STACK), bc

    ;   Now, execute hl
    fcall   code_execute

    ;   Recover address next instruction    
    ld  hl, (_EX_STACK)
    ld  bc, (hl)
    inc hl
    inc hl
    ld (_EX_STACK), hl
    
    ld  a, b
    or  c
    jr  nz, _ex_colon
    
    jr  _ex_end

;--- Return Stack for Execute ---
            defs 128
_EX_STACK:  dw _EX_STACK
            dw  0x5050



