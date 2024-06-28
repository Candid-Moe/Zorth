; Read a text line from a opened device into TIB
;
; Parameters:
;   None
;          
; Returns:
;   A   - ERR_SUCCESS on success, error value else
;
   
read_line:
    push h
    push de
    push bc

    xor a, a
    ld  (_gtIN), a      ; Reset index >IN
    ;
    ;   Read a line from device into TIB
    ;
    ld  hl,  (_SOURCE_ID)
    ld  h, l
    ld  de, _TIB
    ld  bc, 80
    READ   

    pop bc
    pop de
    pop h    

    ret    

