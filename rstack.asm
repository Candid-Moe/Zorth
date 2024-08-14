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
    pop bc

    dec iy              ; push TOS into control stack
    ld  (iy), b
    dec iy
    ld  (iy), c

    jp  (hl)    

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
    ld      c, (iy)     ; pop value from control stack
    inc     iy
    ld      b, (iy)
    inc     iy

    push    bc

    jp      (hl)

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
    ld      c, (iy)     ; pop control address from control stack
    ld      b, (iy + 1)

    push    bc

    jp      (hl)

