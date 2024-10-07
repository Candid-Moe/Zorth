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

    ld      bc, (_SOURCE_ID)
    push    bc
    fcall   code_to_r           ; old source-id to R

    ld      bc, (_gtIN)
    push    bc
    fcall   code_to_r           ; old >IN to R
    
    ld      bc, (gTIB)
    push    bc
    fcall   code_to_r           ; old gTIB to R

    ld      bc, (TIB)
    push    bc
    fcall   code_to_r           ; old TIB to R

    ld      bc, (eval_gTIB)
    push    bc
    fcall   code_to_r           ; old eval_gTIB to R

    pop     bc                  ; u
    ld      (eval_gTIB), bc

    ld      bc, eval_gTIB
    ld      (gTIB), bc

    pop     hl
    ld      (TIB), hl

    ld      hl, 0
    ld      (_gtIN), hl

    ld      hl, -1
    ld      (_SOURCE_ID), hl

    fcall   inner_interpreter

    fcall   code_r_from
    pop     hl
    ld      (eval_gTIB), hl

    fcall   code_r_from
    pop     hl
    ld      (TIB), hl

    fcall   code_r_from
    pop     hl
    ld      (gTIB), hl

    fcall   code_r_from
    pop     hl
    ld      (_gtIN), hl

    fcall   code_r_from
    pop     hl
    ld      (_SOURCE_ID), hl

    fret

eval_gTIB:  dw 0

