;   Zorth - (c) Candid Moe 2024
;
;   control: words that control execution
;

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

    ex_pop    ; extract pointer to next address

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

    ex_push           ;   Now use this as address next instruction

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
    
    
code_jp:
;
;   Implements JMP
;   ( -- )
;
;   Address is stored in the next cell
;
    fenter

    ex_pop        ; Recover next cell address
    
    ld de, (hl)     ; Take de address
    ld hl, de

    ex_push       ;

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

code_while:
;
;   WHILE
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Compilation:
;   ( C: dest -- orig dest )
;
;   Put the location of a new unresolved forward reference orig onto the control 
;   flow stack, under the existing dest. 
;   Append the run-time semantics given below to the current definition. 
;   The semantics are incomplete until orig and dest are resolved (e.g., by REPEAT).
;
;   Run-time:
;   ( x -- )
;
;   If all bits of x are zero, continue execution at the location specified by the
;   resolution of orig. 
;
    fenter

    ld  a, (_STATE)
    cp  FALSE
    jp  z, _code_mode_error

    ld      hl, (xt_jz)
    push    hl
    fcall   add_cell

    ctrl_pop        ; dest
    push    hl

    ld      hl, (_DP)
    ctrl_push       ; ( : C -- orig )
    pop     hl
    ctrl_push       ; ( : C orig -- orig dest )

    ld      hl, 0
    push    hl
    fcall   add_cell ; Address to jump
                
    fret

code_repeat:
;
;   Implements REPEAT
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Compilation:
;   ( C: orig dest -- )
;
;   Append the run-time semantics given below to the current definition, 
;   resolving the backward reference dest. 
;   Resolve the forward reference orig using the location following the 
;   appended run-time semantics.
;
;   Run-time:
;   ( -- )
;
;   Continue execution at the location given by dest. 
;
    fenter

    ld  a, (_STATE)
    cp  FALSE
    jp  z, _code_mode_error

    ld      hl, (xt_jp)
    push    hl
    fcall   add_cell

    ctrl_pop            ; dest
    push    hl
    fcall   add_cell

    ctrl_pop            ; orig
    ld      de, (_DP)
    ld      (hl), de    
   
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
    jp  z, _code_mode_error

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
    jp  z, _code_mode_error

    ld      bc, (xt_jz)
    push    bc
    fcall   add_cell    ; Add jump to word in after "begin"

    ctrl_pop
    push hl
    fcall   add_cell    ; Put the address for the jump.
    
    fret

code_do:
;
;   Implements DO
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Compilation:
;   ( C: -- do-sys )
;
;   Place do-sys onto the control-flow stack. 
;   Append the run-time semantics given below to the current definition. 
;   The semantics are incomplete until resolved by a consumer of do-sys 
;   such as LOOP.
;
;   Run-time:
;   ( n1 | u1 n2 | u2 -- ) ( R: -- loop-sys )
;
;   Set up loop control parameters with index n2 | u2 and limit n1 | u1. 
;   An ambiguous condition exists if n1 | u1 and n2 | u2 are not both the same type.
;   Anything already on the return stack becomes unavailable until the loop-control
;   parameters are discarded. 
;
;   Implementation: We don't use "fenter" in order to mantain control parameters on top
;   of stack.
;
    fenter
    
    ld  a, (_STATE)
    cp  FALSE
    jp  z, _code_mode_error

;    push    hl          ; Return address

    ;   Insert the load params instruction
    ld      hl, (xt_do)
    push    hl
    fcall   add_cell

    ld      hl, (_DP)   ; Put a do-sys in control stack: address first
    ctrl_push   

    ld      hl, do_sys  ; Then the mark.
    ctrl_push

    ld      hl, 0
    leave_push          ; Mark a new frame start

;    pop     hl
;    jp      (hl)        ; Return

    fret
    
code_do_runtime:
    ;
    ;   Implement run-time semantic of DO
    ;   (Cannot use the return stack for calls)
    ;

    pop     bc          ; BC = Index
    pop     de          ; DE = Limit
    push    hl          ; return address
    push    bc
    push    de          
    fcall   code_to_r   ; (R -- Limit )
    fcall   code_to_r   ; (R -- Index )

    pop     hl          ; return address 
    jp      (hl)        ; Return

code_loop:
;
;   Implements LOOP
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Compilation:
;   ( C: do-sys -- )
;
;   Append the run-time semantics given below to the current definition. 
;   Resolve the destination of all unresolved occurrences of LEAVE between 
;   the location given by do-sys and the next location for a transfer of 
;   control, to execute the words following the LOOP.
;
;   Run-time:
;   ( -- ) ( R: loop-sys1 -- | loop-sys2 )
;
;   An ambiguous condition exists if the loop control parameters are unavailable. 
;   Add one to the loop index. If the loop index is then equal to the loop limit,
;   discard the loop parameters and continue execution immediately following the loop.
;   Otherwise continue execution at the beginning of the loop. 
;
;   Implementation: We don't use "fenter" in order to save control parameters on top
;   of stack.
;

    fenter

    ld  a, (_STATE)
    cp  FALSE
    jp  z, _code_mode_error

;    push    hl      ; Save return address

_code_loop_comp:

    ld  bc, (_DP)   ; BC = address after 2 cells
    inc bc
    inc bc
    inc bc
    inc bc

_code_loop_comp_leave:
    ;   First, process all LEAVE for this DO
    leave_pop
    ld  a, h
    cp  l
    jr  z, _code_loop_next

    ld  (hl), bc
    jr  _code_loop_comp_leave

_code_loop_next:

    ctrl_pop

    xor a           ; HL = do_sys ?
    cp  h
    jp  nz, _code_loop_error
    ld  a, do_sys
    cp  l
    jp  nz, _code_loop_error

    ;   Write a LOOP XT
    ld      hl, (xt_loop)
    push    hl
    fcall   add_cell

    ctrl_pop        ; Extract address    
    push    hl
    fcall   add_cell

;    pop hl          ; Return address

;    jp  (hl)

    fret

code_loop_runtime:
    ;
    ;   Implements run-time semantic for LOOP
    ;   (Cannot use the return stack for calls)
    ;
    
    push    hl      ; Save return address

    fcall   code_r_from ; Index ( -- index : R limit index -- limit )
    pop     hl
    inc     hl
    push    hl          ; ( -- index+1 : R limit -- limit )

    fcall   code_r_from ; Limit ( index+1 -- index+1 limit : R limit -- )
    pop     de          ; ( index+1 limit -- index+1 )
    pop     hl          ; ( index+1 -- )
    push    hl          ; ( -- index+1 )

    set_carry_0         ; Compare for Index = Limit
    sbc     hl, de      ; HL = index - limit
    jr      z, _code_loop_end

    push    de          ; ( index+1 -- index+1 limit )
    fcall   code_to_r   ; ( index+1 limit -- index+1 : R -- limit )
    fcall   code_to_r   ; ( index+1 -- : R limit -- limit index+1 )

    ;   Replace next instruction address
    ex_pop            ; Extract current next cell address
    ld      de, (hl)    ; Take contains of next cell, an address
    ex      hl, de      
    ex_push           ; Make it the new next cell

    pop     hl
    jp      (hl)

_code_loop_end:

    pop hl      ; ( index+1 -- )

    ; Skip next instruction (address)

    ex_pop
    inc     hl
    inc     hl
    ex_push

    ; Recover return address
    pop hl
    jp  (hl)

_code_loop_error:

    jp  (hl)
    
    
code_i:
;
;   Implements I 
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Execution:
;   ( -- n | u ) ( R: loop-sys -- loop-sys )
;
;   n | u is a copy of the current (innermost) loop index. 
;   An ambiguous condition exists if the loop control parameters are unavailable. 
;
    ld      c, (ix)
    ld      b, (ix+1)
    push    bc

    jp  (hl)

code_j:
;
;   Implements J 
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Execution:
;   ( -- n | u ) ( R: loop-sys1 loop-sys2 -- loop-sys1 loop-sys2 )
;
;   n | u is a copy of the next-outer loop index. 
;   An ambiguous condition exists if the loop control parameters of the next-outer loop, 
;   loop-sys1, are unavailable. 
;
    ld      c, (ix+4)
    ld      b, (ix+5)
    push    bc

    jp  (hl)

code_leave:
;
;   Implements LEAVE 
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Execution:
;   ( -- ) ( R: loop-sys -- )
;
;   Discard the current loop control parameters. 
;   An ambiguous condition exists if they are unavailable. 
;   Continue execution immediately following the innermost 
;   syntactically enclosing DO...LOOP or DO...+LOOP.
; 

    fenter 

    ld  a, (_STATE)
    cp  FALSE
    jp  z, _code_mode_error

    ld      hl, (xt_leave)     ; Insert a jmp
    push    hl
    fcall   add_cell    

    ld      hl, (_DP)       ; Remember address location
    leave_push

    ld      hl, 0
    push    hl
    fcall   add_cell

    fret

code_leave_runtime:

    push    hl

    ;   Discard control parameters in return stack
    fcall   code_unloop_runtime

    ;   Jump outside
    ctrl_pop
    ld      bc, (hl)
    ld      hl, bc
    ctrl_push

    pop hl
    jp  (hl)

code_unloop:
;
;   Implements UNLOOP
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Execution:
;   ( -- ) ( R: loop-sys -- )
;
;   Discard the loop-control parameters for the current nesting level. 
;   An UNLOOP is required for each nesting level before the definition may be EXITed. 
;   An ambiguous condition exists if the loop-control parameters are unavailable.
;
    fenter 

    ld  a, (_STATE)
    cp  FALSE
    jp  z, _code_mode_error

    ld      hl, (xt_unloop) ; 
    push    hl
    fcall   add_cell    

    fret

code_unloop_runtime:
;
;   Implements run-time semantic for UNLOOP
;   (Cannot use the return stack for calls)
;
    push    hl

    fcall   code_r_from
    fcall   code_r_from
    pop     hl
    pop     hl

    pop     hl
    jp      (hl)


code_ctrl_push:
;
;   Implements >CTRL
;   ( x -- : C -- x )
;
    fenter

    pop hl
    ctrl_push

    fret

code_ctrl_pop:
;
;   Implements CTRL>
;   ( -- x : C x -- )
;
    fenter

    ctrl_pop
    push hl

    fret

code_cs_roll:
;    
;   CS-ROLL c-s-roll 
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Execution:
;   ( C: origu | destu origu-1 | destu-1 ... orig0 | dest0 -- origu-1 | destu-1 ... orig0 | dest0 origu | destu ) ( S: u -- )
;
;   Remove u. 
;   Rotate u+1 elements on top of the control-flow stack so that 
;   origu | destu is on top of the control-flow stack. 
;   An ambiguous condition exists if there are less than u+1 items, 
;   each of which shall be an orig or dest, on the control-flow stack 
;   before CS-ROLL is executed.
;
;   If the control-flow stack is implemented using the data stack, 
;   u shall be the topmost item on the data stack. 
;
    fenter

    pop     bc

    ;   Check u > 0

    ld      a, b
    or      c
    jr      z, _code_cs_roll_end    ; Nothing to do

    ld      hl, bc
    add     hl, bc      
    ld      bc, hl  ; bc = u * 2

    ;   u != 0

    ld      hl, (_IX_CONTROL)
    add     hl, bc      ; hl -> orig-u | dest-u

    ;   Mantain orig-u | dest-u in data stack

    ld      de, (hl)
    push    de

    ;   Move data block

    ld      de, hl  ; de -> destiny
    dec     hl      ; hl -> origin 
    dec     hl
    lddr            ; move

    ;   Put orig-u | dest-u at top

    pop     de
    ld      hl, (_IX_CONTROL)
    ld      (hl), e
    inc     hl
    ld      (hl), d

_code_cs_roll_end: 

    fret      
