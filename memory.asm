;   Zorth - (c) Candid Moe 2024

;   memory: words that deals with memory

code_move:
;
;   Implements MOVE
;   ( addr1 addr2 u -- )
;
;   If u is greater than zero, copy the contents of u consecutive address units
;   at addr1 to the u consecutive address units at addr2. After MOVE completes, 
;   the u consecutive address units at addr2 contain exactly what the u 
;   consecutive address units at addr1 contained before the move. 
;
    fenter

    pop     bc      ; u, count
    pop     de      ; c-addr2, destination
    pop     hl      ; c-addr1, origin

    ;   check bc != 0
    ld      a, b
    or      c
    jz      _code_move_end

    ldir

_code_move_end:

    fret

code_here:
;
;   Implements HERE
;   ( -- addr )
;
;   addr is the data-space pointer. 
;
    fenter

    ld  hl, (_DP)
    push hl

    fret

code_align:
;
;   Implements ALIGN
;   ( -- )
;
;   If the data-space pointer is not aligned, reserve enough space to align it. 
;
    fenter 

    fcall code_here
    fcall code_aligned
    pop de
    ld (_DP), de

    fret

code_aligned:
;
;   Implements ALIGNED
;   ( addr -- a-addr )
;
;   a-addr is the first aligned address greater than or equal to addr. 
;
    pop de
    ld  a, e
    and 1           ; test if even
    jr  z, _code_aligned_end

    inc de

_code_aligned_end:
;
    push de
    jp  (hl)


code_allot:
;
;   Implements ALLOT
;   ( n -- )
;
;   If n is greater than zero, reserve n address units of data space. 
;   If n is less than zero, release | n | address units of data space. 
;   If n is zero, leave the data-space pointer unchanged.
;
;   If the data-space pointer is aligned and n is a multiple of the 
;   size of a cell when ALLOT begins execution, it will remain aligned
;   when ALLOT finishes execution.
;
;   If the data-space pointer is character aligned and n is a multiple 
;   of the size of a character when ALLOT begins execution, it will 
;   remain character aligned when ALLOT finishes execution. 
;
    fenter

    pop de

    ld  hl, (_DP)
    add hl, de
    ld  (_DP), hl

    fret

code_fetch:
;
;   Implements @
;   ( a-addr -- x )
;
;   x is the value stored at a-addr. 
;
    fenter

    pop hl
    ld  de, (hl)
    push de

    fret    

code_store:
;
;   Implements ! 
;   ( x a-addr -- )
;
;   Store x at a-addr. 
;
    fenter

    pop hl
    pop bc
    ld  (hl), c
    inc hl
    ld  (hl), b

    fret

code_c_fetch:
;
;   Implements C@
;   ( c-addr -- char )
;
;   Fetch the character stored at c-addr. 
;   When the cell size is greater than character size, the unused high-order 
;   bits are all zeroes. 
;
    fenter

    pop de
    ld  b, 0
    ld  a, (de)
    ld  c, a
    
    push bc

    fret

code_c_store:
;
;   Implements C!
;   ( char c-addr -- )
:
;   Store char at c-addr. 
;   When character size is smaller than cell size, only the number of 
;   low-order bits corresponding to character size are transferred.
;
    fenter

    pop hl
    pop bc

    ld  (hl), c

    fret

code_depth:
;
;   Implement DEPTH
;   ( -- +n )
;
;   +n is the number of single-cell values contained in the data stack
;   before +n was placed on the stack. 
;
    fenter

    ld hl, _DATA_STACK
    ld de, SP
    set_carry_0
    sbc hl, de
    ld  de, 1

    push hl
    push de
    fcall code_rshift

    fret
