;   Zorth - (c) Candid Moe 2024
;
;   control: words that control execution
;

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
    
    check_compile_mode

;    push    hl          ; Return address

    ;   Insert the load params instruction
    ld      hl, (xt_do)
    push    hl
    fcall   code_comma

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

xt_xloop:   dw 0        ; xt (loop/+loop) to use 
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
    fenter

    ld  hl, (xt_loop)
    ld  (xt_xloop), hl

    fcall code_xloop_compile

    fret

code_plus_loop:
;
;   Implements +LOOP
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
;   control, to execute the words following +LOOP.
;
;   Run-time:
;   ( n -- ) ( R: loop-sys1 -- | loop-sys2 )
;
;   An ambiguous condition exists if the loop control parameters are unavailable.
;   Add n to the loop index. If the loop index did not cross the boundary between
;   the loop limit minus one and the loop limit, continue execution at the beginning
;   of the loop. Otherwise, discard the current loop control parameters and continue
;   execution immediately following the loop. 
;


    fenter

    ld  hl, (xt_plus_loop)
    ld  (xt_xloop), hl

    fcall code_xloop_compile

    fret

code_xloop_compile:

    fenter

    check_compile_mode

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
    or  l
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

    ;   Write a LOOP/+LOOP XT
    ld      hl, (xt_xloop)
    push    hl
    fcall   code_comma

    ctrl_pop        ; Extract address    
    push    hl
    fcall   code_comma

    fret

code_loop_runtime:
    ;
    ;   Implements run-time semantic for LOOP
    ;   (Cannot use the return stack for calls)
    ;   ( -- )
    
    push    hl          ; Save return address

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
    jz      _code_loop_end

    push    de          ; ( index+1 -- index+1 limit )
    fcall   code_to_r   ; ( index+1 limit -- index+1 : R -- limit )
    fcall   code_to_r   ; ( index+1 -- : R limit -- limit index+1 )

    ;   Replace next instruction address
    ex_pop              ; Extract current next cell address
    ld      de, (hl)    ; Take contains of next cell, an address
    ex      hl, de      
    ex_push             ; Make it the new next cell

    pop     hl
    jp      (hl)


code_plus_loop_runtime:
    ;
    ;   Implements run-time semantic for +LOOP
    ;   (Cannot use the return stack for calls)
    ;   ( n -- )
    ;

    push    hl                  ; ( n -- n ret ) Save return address
    fcall   code_swap           ; ( -- ret n )

    fcall   code_r_fetch    ; Index ( n -- n index : R limit index -- limit index )
    fcall   code_plus           ; ( -- index+n )

    fcall   code_r_from     ; Limit ( index+n -- index+n index : R limit index -- limit )
    fcall   code_r_fetch        ; ( -- index+n index limit : R limit -- limit )
    fcall   code_less_than      ; ( -- index+n index<limit : R limit -- limit )
    fcall   code_swap           ; ( -- index<limit index+n : R limit -- limit )
    fcall   code_dup            ; ( -- index<limit index+n index+n : R limit -- limit )
    fcall   code_r_fetch        ; ( -- index<limit index+n index+n limit : R limit -- limit )
    fcall   code_swap           ; ( -- index<limit index+n limit index+n : R limit -- limit )
    fcall   code_to_r           ; ( -- index<limit index+n limit : R limit -- limit index+n )
    fcall   code_less_than      ; ( -- index<limit index+n<limit : R limit -- limit index+n )
    fcall   code_xor            ; ( -- flag : R limit -- limit index+n )

    pop     bc
    ld      a, b
    or      c
    jr      nz, _code_plus_loop_end

    ;   Replace next instruction address
    ex_pop              ; Extract current next cell address
    ld      de, (hl)    ; Take contains of next cell, an address
    ex      hl, de      
    ex_push             ; Make it the new next cell

    ; Recover return address
    pop     hl
    jp      (hl)
    

_code_plus_loop_end:

    fcall   code_rdrop      ; ( : R limit index -- limit )
    fcall   code_rdrop      ; ( : R limit -- )
    push    hl              ; doesn't matter

_code_loop_end:

    pop hl                  ; ( index+1 -- )

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

    check_compile_mode

    ld      hl, (xt_leave)     ; Insert a jmp
    push    hl
    fcall   code_comma    

    ld      hl, (_DP)       ; Remember address location
    leave_push

    ld      hl, 0
    push    hl
    fcall   code_comma

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

    check_compile_mode

    ld      hl, (xt_unloop) ; 
    push    hl
    fcall   code_comma    

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


