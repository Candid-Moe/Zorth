;   Zorth - (c) Candid Moe 2024
;
;   control: words that control execution
;

xt_if:  dw  0           ; IF runtime execution token.

code_if:
;
;   Implements IF
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Compilation:
;   ( C: -- orig )
;
;   Put the location of a new unresolved forward reference orig onto the
;   control flow stack. 
;   Append the run-time semantics given below to the current definition. 
;   The semantics are incomplete until orig is resolved, e.g., by THEN or ELSE.
;
;   Run-time:
;   ( x -- )
;
;   If all bits of x are zero, continue execution at the location specified by 
;   the resolution of orig. 
;
    fenter

    ld  a, (_MODE_INTERPRETER)
    cp  TRUE
    jp  z, _code_mode_error

    ld  hl, (_DP)
    ld  bc, (xt_if)
    ld  (hl), bc        ; Add IF xt to word in formation.

    inc hl
    inc hl     

    push hl
    ctrl_push           ; Put the cell address to patch

    inc hl
    inc hl              ; Leave a cell for the destination address

    ld  (_DP), hl       ; Update DP


    fret    
    
code_if_runtime:
    ;
    ;   To be called in runtime thru xt_if
    ;
    fenter

    pop hl
    ld  a, l
    or  h       ; Test TOS
    
    jr  nz, _code_if_runtime_conditional

    ;   Skip over the conditional code

    fcall _ex_pop   ;   
    pop hl
    ld  bc, (hl)
    push bc
    fcall _ex_push

    jr _code_if_runtime_end

_code_if_runtime_conditional:

    ;   Execute the conditional part
    
    fcall   _ex_pop     ;   Extra address next instruction.
    pop hl          
    inc hl
    inc hl              ;   Add 2
    push hl
    fcall   _ex_push    ;   Now use this as address next instruction

_code_if_runtime_end:

    fret

code_then:
;
;   Implements THEN 
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Compilation:
;   ( C: orig -- )
;
;   Append the run-time semantics given below to the current definition. 
;   Resolve the forward reference orig using the location of the appended 
;   run-time semantics.
;
;    Run-time:
;   ( -- )
;
;   Continue execution. 

    fenter

    ld  a, (_MODE_INTERPRETER)
    cp  TRUE
    jp  z, _code_mode_error

    ;   Put the current address in the space following IF

    ctrl_pop        ; 

    ld  bc, (_DP)
    ld  (hl), bc
    
    fret




