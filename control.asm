;   Zorth - (c) Candid Moe 2024
;
;   control: words that control execution
;

xt_if:  dw  0           ; IF runtime execution token.
xt_jp:  dw  0

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

code_else:
;
;   Implements ELSE
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Compilation:
;   ( C: orig1 -- orig2 )
;
;   Put the location of a new unresolved forward reference orig2 onto the 
;   control flow stack. 
;   Append the run-time semantics given below to the current definition. 
;   The semantics will be incomplete until orig2 is resolved (e.g., by THEN). 
;   Resolve the forward reference orig1 using the location following the 
;   appended run-time semantics.
;
;   Run-time:
;   ( -- )
;
;   Continue execution at the location given by the resolution of orig2. 
;
    ld  a, (_MODE_INTERPRETER)
    cp  TRUE
    jp  z, _code_mode_error

    ;   Write a JMP after the IF code

    ld  hl, (_DP)
    ld  bc, (xt_jp)
    ld  (hl), bc        ; Add jump to word in after "then"

    inc hl
    inc hl              ; Advance next free cell

    inc hl
    inc hl              ; Reserve a cell for the jmp destination

    
    ld  (_DP), hl

    ;   Put the current address in the space following IF

    ctrl_pop        ; 

    ld  bc, (_DP)
    ld  (hl), bc

    ld  hl, bc      ; 
    dec hl
    dec hl

    ctrl_push

    fret
    
    
code_jp_runtime:

    fenter

    fcall _ex_pop
    pop hl
    
    ld de, (hl)
    push de

    fcall _ex_push

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

code_begin:
;
;   Implements BEGIN
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Compilation:
;   ( C: -- dest )
;
;   Put the next location for a transfer of control, dest, onto the control flow stack. 
;   Append the run-time semantics given below to the current definition.
;
;   Run-time:
;   ( -- )
;
;   Continue execution. 

    fenter

    ld  a, (_MODE_INTERPRETER)
    cp  TRUE
    jp  z, _code_mode_error

    ld  hl, (_DP)
    ctrl_push

    fret

code_until:
;
;   Implements UNTIL
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Compilation:
;   ( C: dest -- )
;
;   Append the run-time semantics given below to the current definition, 
;   resolving the backward reference dest.
;
;   Run-time:
;   ( x -- )
;
;   If all bits of x are zero, continue execution at the location specified by dest. 

    fenter
    
    ld  a, (_MODE_INTERPRETER)
    cp  TRUE
    jp  z, _code_until_runtime

    ld  hl, (_DP)
    ld  bc, (xt_jp)
    ld  (hl), bc        ; Add jump to word in after "then"

    inc hl
    inc hl              ; Advance next free cell

    ld  (_DP), hl
    ctrl_pop
    ld  bc, hl
    ld  hl, (_DP)
    ld  (hl), bc        ; Put the address for the jump.
    
    inc hl
    inc hl
    ld  (_DP), hl
    
    fret

_code_until_runtime:

    pop bc
    ld  a, c
    cp  b
    jr  z, code_until_end

    ;   TOS != 0 -> end

    fcall _ex_pop
    pop hl
    inc hl
    inc hl
    push hl
    fcall _ex_push

code_until_end:

    fret
