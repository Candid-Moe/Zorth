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

code_cs_roll:
;    
;   Implements CS-ROLL 
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

