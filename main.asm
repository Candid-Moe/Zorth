;
;   Main: Read a line and executed it
;
    org     0x4000

    ld      SP, _DATA_STACK
    ld      IX, _RETURN_STACK
repl:
    ld      HL, _PROMPT
    push    HL

    fcall   code_count
    fcall   code_type

    call    read_line
    jp      repl
    
return:
;
;   Implement RET by jumping to address in return stack
;   (Every routine return via this code)
;
    ld      l, (ix)     ; pop return address from return stack
    inc     ix
    ld      h, (ix)
    inc     ix
    jp      (hl)        ; return via jump

code_count:
;
;   Implement COUNT 
;   ( c-addr1 -- c-addr2 u ) 
;   
    fenter
    
    pop  hl          ; hl <- counted string address 
    ld   a, (hl)     ; a  <- counted string len
    inc  hl          ; hl -> counted string first char
    push hl
    ld   h, 0
    ld   l, a
    push hl

    fret
    
code_type:
    fenter
    fret

