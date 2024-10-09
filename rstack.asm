;   Zorth - (c) Candid Moe 2024
;
;   rstack: words that operate the return stack and control stack
;
code_to_r:
;
;   Implements >R
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;    Execution:
;   ( x -- ) ( R: -- x )
;
;   Move x to the return stack. 
;
    pop bc

    dec ix              ; push TOS into return stack
    ld  (ix), b
    dec ix
    ld  (ix), c

    jp  (hl)    

code_r_from: 
;
;   Implements R>
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Execution:
;   ( -- x ) ( R: x -- )
;
;   Move x from the return stack to the data stack. 
;
    ld      c, (ix)     ; pop value from return stack
    inc     ix
    ld      b, (ix)
    inc     ix

    push    bc

    jp      (hl)

code_r_fetch:
;
;   Implements R@
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Execution:
;   ( -- x ) ( R: x -- x )
;
;   Copy x from the return stack to the data stack. 
;
    ld      c, (ix)     ; pop return address from return stack
    ld      b, (ix + 1)

    push    bc

    jp      (hl)

code_rdrop:
;
;   Implements RDROP
;   ( R: w -- )
;
    inc ix
    inc ix
    jp  (hl)

code_two_to_r:
;
;   Implements 2>R
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Execution:
;   ( x1 x2 -- ) ( R: -- x1 x2 )
;
;   Transfer cell pair x1 x2 to the return stack. 
;   Semantically equivalent to SWAP >R >R. 
;

    pop bc
    pop de

    dec ix              ; push TOS into return stack
    ld  (ix), d
    dec ix
    ld  (ix), e

    dec ix              ; push TOS into return stack
    ld  (ix), b
    dec ix
    ld  (ix), c

    jp  (hl)    

code_two_r_from:
;
;   Implements 2R>
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Execution:
;   ( -- x1 x2 ) ( R: x1 x2 -- )
;
;   Transfer cell pair x1 x2 from the return stack.
;   Semantically equivalent to R> R> SWAP.

    ld      c, (ix)     ; pop value from return stack
    inc     ix
    ld      b, (ix)
    inc     ix

    ld      e, (ix)     ; pop value from return stack
    inc     ix
    ld      d, (ix)
    inc     ix

    push    de
    push    bc

    jp  (hl)

code_to_cs:
;
;   Implements >CS
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;    Execution:
;   ( x -- ) ( C: -- x )
;
;   Move x to the control stack. 
;
    fenter

    pop hl
    ctrl_push

    fret

code_cs_from: 
;
;   Implements CS>
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Execution:
;   ( -- x ) ( C: x -- )
;
;   Move x from the control stack to the data stack. 
;
    fenter

    ctrl_pop
    push    hl

    fret

code_cs_fetch:
;
;   Implements CS@
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Execution:
;   ( -- x ) ( C: x -- x )
;
;   Copy x from the control stack to the data stack. 
;
    fenter

    ctrl_pop
    push hl
    ctrl_push

    fret


