;   Zorth - (c) Candid Moe 2024
;
;   
; The tester defines functions that compare the results of a test with a set of expected
; results. The syntax for each test starts with "T{" (T-open brace) followed by a code
; sequence to test. This is followed by "->", the expected results, and "}T" (close brace-T).
;
; For example, the following:
;
; T{ 1 1 + -> 2 }T
;
; tests that one plus one indeed equals two.
;
; The "T{" records the stack depth prior to the test code so that they can be eliminated
; from the test. 
; The "->" records the stack depth and moves the entire stack contents to an array. 
; In the example test, the recorded stack depth is one and the saved array contains 
; one value, two. 
; The "}T" compares the current stack depth to the saved stack depth. 
; If they are equal each value on the stack is removed from the stack and compared to its
; corresponding value in the array. If the depths are not equal or if the stack comparison 
; fails, an error is reported. For example:
;
; T{ 1 2 3 SWAP -> 1 3 2 }T
; T{ 1 2 3 SWAP -> 1 2 3 }T INCORRECT RESULT: T{ 1 2 3 SWAP -> 1 2 3 }T
; T{ 1 2 SWAP -> 1 }T WRONG NUMBER OF RESULTS: T{ 1 2 SWAP -> 1 }T


stack_pointer_origin:   dw  0
stack_pointer_after:    dw  0
stack_depth:            dw  0
stack_copy:             defs 128
stack_pointer:          dw  stack_copy
test_str:               dw  0
test_start:             db  0
err_depth_differ:   counted_string "\nDepths not equal. "
err_content_differ: counted_string "\nContents differ. "
;
code_t_open:
;
;   Implements T{
;
    fenter

    ;   Record original stack pointer

    ld  (stack_pointer_origin), sp
    
    ;   Record source start position
    ld      a, (_gtIN)      ; current position in buffer
    dec     a
    dec     a
    ld      (test_start), a ; not yet the length

    ld      b, 0
    ld      c, a

    ld      hl, (TIB)       ; Buffer address
    add     hl, bc

    ld      (test_str), hl

    fret

code_right_arrow:
;
;   Implements ->
;
    fenter

    ;   Record stack pointer after test

    ld      (stack_pointer_after), sp
   
    ;   Copy data stack

    ld      de, sp
    ld      hl, (stack_pointer_origin)
    set_carry_0    
    sbc     hl, de

    ld      bc, hl      ; length (bytes)
    ld      (stack_depth), bc
    ld      hl, sp
    ld      de, stack_copy

    ldir

    ;   Restore stack

    ld      sp, (stack_pointer_origin)

    fret        

code_t_close:
;
;   Implementes }T
;
    fenter

    ld  hl, (stack_pointer_after)
    ld  de, sp
    set_carry_0
    sbc hl, de

    jr  z, _compare_stacks

    ld      hl, err_depth_differ
    push    hl
    fcall   print_line
    fcall   _test_print
    jr      _code_t_close_end

_compare_stacks:

    push    iy
    fcall   code_to_r           ; Save iy in the return stack

    ld      iy, stack_copy
    ld      hl, (stack_pointer_after)

_code_t_close_cycle:

    ld      a, (hl)
    cp      (iy)
    jr      z, _code_t_close_cycle_next

    ld      hl, err_content_differ
    push    hl
    fcall   print_line
    fcall   _test_print
    jr      _code_restore

_code_t_close_cycle_next:

    inc     hl
    inc     iy
    dec     bc
    jr      nz, _code_t_close_cycle

_code_restore:

    fcall   code_r_from
    pop     iy

_code_t_close_end:

    ;   Restore stack as before the test
    ld  sp, (stack_pointer_origin)

    fret    

_test_print:
;
;   Print the test that failed.
;
    fenter

    ;   Start address

    ld      hl, (test_str)
    push    hl

    ;   Calculate length

    ld      a, (test_start)
    ld      b, a
    ld      a, (_gtIN)    
    sub     b

    ld      b, 0
    ld      c, a
    push    bc

    fcall   code_type
    fcall   code_space

    ld      hl, stack_copy
    ld      (stack_pointer), hl

_test_print_cycle:

    ld      bc, (stack_depth)
    ld      a, b
    or      c
    jr      z, _test_print_end

    dec     bc
    dec     bc
    ld      (stack_depth), bc

    ld      hl, (stack_pointer)
    ld      de, (hl)
    inc     hl
    inc     hl
    ld      (stack_pointer), hl

    push    de
    fcall   code_dot
    jr      _test_print_cycle
    
_test_print_end:
   
    fret

