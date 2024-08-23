;   Zorth - (c) Candid Moe 2024
;
;   execute: colon and code execution
;
;   An execution token (xt) is the address of the entry in the dictionary
;

code_execute:
;
;   Implements EXECUTE
;   ( i * x xt -- j * x )
;
;   Remove xt from the stack and perform the semantics identified by it. 
;   Other stack effects are due to the word EXECUTEd. 
;
    fenter

    pop  hl                ; ( @xt -- )

    call   _ex_classify    ; HL = @
    jr     nz, _ex_colon_cycle

    ;   It's a code word

    ld bc, (hl)
    ld (_ex_code_jp + 1), bc
    ld hl, _ex_end

_ex_code_jp:    
    jp   0          ; dest. will be overwritten 

_ex_colon_cycle:
    ;   Execute a colon word
    ;   ( -- )
    ;
    ;   Colon word is a list of xt addresses.
    ;
    ;   HL is the address of the list element where XT is.

    push    hl          ; Save it          ( -- @xt )
    inc     hl
    inc     hl
    ex_push             ; Use execution stack to remember next step (can be modified by others)

    pop     hl          ;                  ( @xt -- )
    ld      bc, (hl)    ; extract xt

    ld      a, b        ; Is the last one ?
    or      c
    jr      z, _ex_cycle_end

    ld      hl, bc
    call   _ex_classify
    jr      nz, _ex_colon_execute

    ;   Don't call CODE words via EXECUTE because code may manipulate the R stack

    ld bc, (hl)
    ld (_ex_colon_jp + 1), bc
    ld hl, _ex_colon_next

_ex_colon_jp:    
    jp   0          ; dest. will be overwritten 

_ex_colon_execute:
    
    push    bc          ; Pass to EXECUTE   ( -- xt )
    fcall   code_execute

_ex_colon_next:

    ;   Recover address next xt

    ex_pop            ; HL = @xt+1
    jr  _ex_colon_cycle

_ex_cycle_end:
    
    ex_pop

_ex_end:

    fret


_ex_classify:
    
    ;   Classify the xt in HL as code or colon.
    ;   Set Z flag if code, reset is colon

    inc hl
    inc hl      ; # words
    inc hl      ; hl -> flags        
    ld  a, (hl) ; A = flags
    
    inc hl      ; hl -> name
    inc hl  
    inc hl      ; hl -> code/colon

    and BIT_COLON   ; Test the CODE/COLON flag

    ret
