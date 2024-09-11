;   Zorth - (c) Candid Moe 2024
;
;   evaluate: process a Forth source text
;

code_evaluate:
;
;   Implements EVALUATE
;   ( i * x c-addr u -- j * x )
;
;   Save the current input source specification. 
;   Store minus-one (-1) in SOURCE-ID if it is present. 
;   Make the string described by c-addr and u both the input source and input buffer, 
;   set >IN to zero, and interpret. 
;   When the parse area is empty, restore the prior input source specification. 
;   Other stack effects are due to the words EVALUATEd. 
;
    fenter

    ld      a, (_SOURCE_ID)
    ld      b, 0
    ld      c, a
    push    bc
    fcall   code_to_r           ; old source-id to R
    ld      a, -1
    ld      (_SOURCE_ID), a

    ld      a, (_gtIN)
    ld      b, 0
    ld      c, a
    push    bc
    fcall   code_to_r           ; old >IN to R
    
    ld      bc, (gTIB)
    push    bc
    fcall   code_to_r           ; old gTIB to R

    ld      bc, (TIB)
    push    bc
    fcall   code_to_r           ; old TIB to R

    ld      a, (eval_gTIB)
    ld      b, 0
    ld      c, a
    push    bc
    fcall   code_to_r           ; old eval_gTIB to R

    pop     bc                  ; u
    ld      a, c

    ld      (eval_gTIB), a
    ld      bc, eval_gTIB

    ld      (gTIB), bc

    pop     hl
    ld      (TIB), hl

    xor     a
    ld      (_gtIN), a

    fcall   inner_interpreter

    fcall   code_r_from
    pop     hl
    ld      a, l
    ld      (eval_gTIB), a

    fcall   code_r_from
    pop     hl
    ld      (TIB), hl

    fcall   code_r_from
    pop     hl
    ld      (gTIB), hl

    fcall   code_r_from
    pop     hl
    ld      a, l
    ld      (_gtIN),a

    fcall   code_r_from
    pop     hl
    ld      a, l
    ld      (_SOURCE_ID), a

    fret

eval_gTIB:  db 0

