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

    ; TODO: Save and retrieve old values
    ld      hl, _TIB
    ld      (TIB), hl

    ld      hl, _gTIB
    ld      (gTIB), hl
        
    fret

eval_gTIB:  db 0

