; linked_list.asm - (c) Candid Moe - 2024
;
; Collection of generic linked list routines
;

public linked_list_add

linked_list_add:
    ;   Add a new entry at the linked list start
    ;   
    ;   Stack parameters:
    ;   - Address of new entry
    ;   - Address of pointer to list.
    ;
    ;   Returns nothing.
    ;    
    exx
    push IY

    ld  IY, 0
    add IY, sp

    ld  DE, (iy + 4);   @ new entry
    ld  HL, (iy + 6);   @ list head
    ld  BC, 2
    ldir            ;   new entry -> previous entry
    ;
    ld  DE, (iy + 4);    @ new entry
    ld  HL, (iy + 6);   @ list head
    ld  (HL), DE    ;   list head -> new entry
    
    pop IY
    exx

    ret
    
linked_list_next:
    ;   Return address next entry in linked list
    ;
    ;   Stack parameters:
    ;   - Entry address
    ;
    ;   Returns:
    ;   
