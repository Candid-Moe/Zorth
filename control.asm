;   Zorth - (c) Candid Moe 2024
;
;   control: words that control execution
;

xt_if:  dw  0           ; IF runtime execution token.
xt_jz:  dw  0
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

    ld  a, (_STATE)
    cp  FALSE
    jp  z, _code_mode_error

    ld      bc, (xt_jz)
    push    bc
    fcall   add_cell    ; Add IF xt to word in formation.

    ld  hl, (_DP)
    ctrl_push           ; Put the cell address to patch

    ld      bc, 0
    push    bc
    fcall   add_cell    ; Leave a cell for the destination address

    fret    
   
code_jz:
;
;   Implement Jump if Zero
;   ( x -- )
;
    fenter

    ctrl_pop    ; extract pointer to next address

    pop bc
    ld  a, c
    or  b       ; Test TOS
    
    jr  nz, _code_jz_non

    ;   Make the jump
    ;   The address is stored in the next cell

    ld  bc, (hl)    ;   Take de address
    ld  hl, bc
    
    jr  _code_jz_end

_code_jz_non:

    ;   Don't jump, skip over the address
    
    inc hl
    inc hl              ;   Add 2

_code_jz_end:

    ctrl_push           ;   Now use this as address next instruction

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
    fenter 

    ld  a, (_STATE)
    cp  FALSE
    jp  z, _code_mode_error

    ;   Write a JMP after the IF code

    ld  bc, (xt_jp)
    push    bc
    fcall   add_cell    ; Add jump to address after "then"

    ld      bc, 0 
    push    bc
    fcall   add_cell    ; Reserve a cell for the jump destination
    
    ;   Put the current address in the space following IF

    ctrl_pop            ; HL = IF address + 1
    ld  bc, (_DP)       :
    ld  (hl), bc

    ;   Remember the previous cell, the address to jump over the 
    ;   then part.

    ld  hl, bc      ; 
    dec hl
    dec hl

    ctrl_push

    fret
    
    
code_jp_runtime:
;
;   Implements JMP
;   ( -- )
;
;   Address is stored in the next cell
;
    fenter

    ctrl_pop        ; Recover next cell address
    
    ld de, (hl)     ; Take de address
    ld hl, de

    ctrl_push       ;

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

    ld  a, (_STATE)
    cp  FALSE
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

    ld  a, (_STATE)
    cp  FALSE
    jp  z, _code_mode_error

    ld  hl, (_DP)
    ctrl_push

    fret

code_again:
;
;   Implements AGAIN 
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
;   ( -- )
;
;   Continue execution at the location specified by dest. 
;   If no other control flow words are used, any program code after AGAIN
;   will not be executed. 
;
    fenter 

    ld  a, (_STATE)
    cp  FALSE
    jp  z, _code_until_runtime

    ld  bc, (xt_jp)
    push bc
    fcall add_cell      ; Add jump to word in after "begin"

    ctrl_pop
    push hl
    fcall add_cell      ; Put the address for the jump.
    
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
    
    ld  a, (_STATE)
    cp  FALSE
    jp  z, _code_until_runtime

    ld      bc, (xt_jz)
    push    bc
    fcall   add_cell    ; Add jump to word in after "begin"

    ctrl_pop
    push hl
    fcall   add_cell    ; Put the address for the jump.
    
    fret

_code_until_runtime:

    fenter

    pop bc
    ld  a, c
    cp  b
    jr  z, code_until_end

    ;   TOS != 0 -> end

;    fcall _ex_pop
;    pop hl
    ctrl_pop

    inc hl
    inc hl
;    push hl
;    fcall _ex_push
    ctrl_push

code_until_end:

    fret
