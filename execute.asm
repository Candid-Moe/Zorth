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
    ld   de, hl
    ;   Store address next xt en EX_STACK
    inc de
    inc de              ; address next xt  
    push de
    fcall   _ex_push    ; Store in own stack

    pop     hl
    ld      bc, (hl)    ; extract xt
    push    bc          ; Pass to EXECUTE

    fcall   code_execute

    ;   Recover address next xt.
    fcall _ex_pop
    pop hl            ; address next xt

    ;   Check for 0x0000 at the end of code.
    ld  de, (hl)      ; load xt
    ld  a, e
    or  d
    jr  nz, _ex_colon
    
    jr  _ex_end

_ex_end:
    
    fret

_ex_push:
;
;   Push address next instruction in our own stack
;   ( addr -- )
;
    fenter

    pop de

    ld  bc, (_EX_PTR)

    dec bc
    ld  a, d
    ld  (bc), a
    dec bc
    ld  a, e
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

    ld  c, (hl)
    inc hl
    ld  b, (hl)
    inc hl

    ld (_EX_PTR), hl
    
    push bc

    fret

code_address:
;
;   Extract next address from execution stack and push into stack
;
    fenter

    ld hl, (_EX_PTR)    ; hl = *next 
    ld de, (hl)         ; hl = next
    push de             ; copy into stack

    inc de
    inc de              ; replace next instruction address

    ld hl, _EX_PTR
    ld (hl), e
    inc hl
    ld (hl), d

    fret



;--- Return Stack for Execute ---
_EX_PTR:    dw _EX_STACK
            defs 128
_EX_STACK:  dw  0x5050



