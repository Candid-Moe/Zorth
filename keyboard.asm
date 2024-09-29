    DEFC FLAGS_CAPS_MASK  = 1 << 0
    DEFC FLAGS_SHIFT_MASK = 1 << 1
    DEFC FLAGS_CTRL_MASK  = 1 << 2

code_key_question:
;
;   Implements KEY? 
;   ( -- flag )
;
;   If a character is available, return true. Otherwise, return false. 
;   If non-character keyboard events are available before the first valid character,
;   they are discarded and are subsequently unavailable. 
;   The character shall be returned by the next execution of KEY.
;
;   After KEY? returns with a value of true, subsequent executions of KEY? prior to 
;   the execution of KEY or EKEY also return true, without discarding keyboard events. 
;
    fenter

    ld      bc, TRUE

    ld      a, (_editor_read)
    cp      0
    jr      nz, _code_key_question_end

    call    kbd_raw_mode
    call    _key_check
    jr      nz, _code_key_question_end
    ld      bc, FALSE
    
_code_key_question_end:
    push    bc
    fret

code_key:
;
;   Implements KEY
;   ( -- char )
;
;   Receive one character char, a member of the implementation-defined character set.
;   Keyboard events that do not correspond to such characters are discarded until a 
;   valid character is received, and those events are subsequently unavailable.
;
;   All standard characters can be received. Characters received by KEY are not displayed.
;
;   Any standard character returned by KEY has the numeric value specified in 3.1.2.1
;   Graphic characters. Programs that require the ability to receive control characters
;   have an environmental dependency. 

    fenter

    ld      a, (_editor_read)
    cp      0
    jr      nz, _code_key_copy

    call    kbd_raw_mode

_code_key_cycle:

    call    _key_check
    jr      z, _code_key_cycle

_code_key_copy:

    xor     a
    ld      (_editor_read), a

    ld      b, 0
    ld      a, (_editor_keys)
    ld      c, a
    push    bc
    
    fret

    ;=========================================================;
    ;==================  CONTROLLER ==========================;
    ;=========================================================;

_key_check:
;
;   Check if a character is ready for reading.
;   Return: Z is no char is available,
;          NZ otherwise
;
    call    _editor_wait_for_event
    ld      a, (_editor_read)
    cp      0

    ret

kbd_raw_mode:

; Set STDIN to raw input

    ld h, DEV_STDIN
    ld c, KB_CMD_SET_MODE
    ld e, KB_MODE_RAW | KB_READ_NON_BLOCK
    IOCTL()
    or  a
    ret z

    ; Error, the target doesn't support RAW mode
    S_WRITE3(DEV_STDOUT, _editor_raw_err_str, _editor_raw_err_str_end - _editor_raw_err_str)
    EXIT()
_editor_raw_err_str:
    DEFM "Could not switch input to RAW mode\n"
_editor_raw_err_str_end:
    
kbd_cooked_mode:

; Set STDIN to cooked input
    ; Set STDIN to raw input
    ld h, DEV_STDIN
    ld c, KB_CMD_SET_MODE
    ld e, KB_MODE_COOKED | KB_READ_BLOCK
    IOCTL()

    ret

is_print:
    ; Printable characters are above 0x20 (space) and below 0x7F
    cp ' '
    ret c
    cp 0x7F
    ccf
    ret


_editor_wait_for_event:
    ; Get the key pressed from the keyboard

    S_READ3(DEV_STDIN, _editor_keys, 1)

_event_received:

    ld a, b
    or c
    ret z

_editor_event_next:
    ; We received at least one character, process it
    ld a, (de)
    inc de
    cp KB_RELEASED
    jr nz, _editor_event_not_ignore

    ; Make the assumption that the released key follows directly

    dec c
    ld a, (de)
    call controller_check_if_special
    ret z

    inc de
    dec c

    ret z
    jp _editor_event_next

_editor_event_not_ignore:
    push bc
    push de
    call _editor_event_process_char
    pop de
    pop bc
    dec c
    jp nz, _editor_event_next
    ret


    ; Parameters:
    ;   A - Character to test
    ; Returns:
    ;   A - 0 if the character is not special
    ;       > 0 if it is
controller_check_if_special:
    cp KB_LEFT_SHIFT
    jr z, _controller_toggle_shift
    cp KB_RIGHT_SHIFT
    jr z, _controller_toggle_shift
    cp KB_LEFT_CTRL
    jr z, _controller_toggle_ctrl
    cp KB_RIGHT_CTRL
    jr z, _controller_toggle_ctrl
    ; Return 0, it was not a special character
    xor a
    ret

_controller_toggle_ctrl:
    ld a, FLAGS_CTRL_MASK
    jr _controller_toggle
_controller_toggle_shift:
    ld a, FLAGS_SHIFT_MASK
    jr _controller_toggle
_controller_toggle_caps:
    ld a, FLAGS_CAPS_MASK
_controller_toggle:
    ld hl, _editor_flags
    xor (hl)
    ld (hl), a
    ret



    ; Process the keyboard key stored in A register:
    ; Parameters:
    ;   A  - Key code to process
    ; Returns:
    ;   None
    ; Alters:
    ;   A, BC, DE, HL
_editor_event_process_char:
    ; Copy character in B
    ld b, a
    call is_print
    ; C flag not set is A is printable
    ; jp nc, _controller_print_printable
    jp c, _editor_event_process_not_printable
    jp _controller_print_printable
_editor_event_process_not_printable:
    cp KB_CAPS_LOCK
    jr z, _controller_toggle_caps
    ; Check if the character is special, i.e. CTRL or SHIFT
    call controller_check_if_special
    ; Return A > 0 if it was, we can return directly then
    or a
    ; This RET will be replaced by the routines that need to receive user input without interpreting them
    ret nz
    jp _editor_event_process_special_ascii

    ; Jump to this branch if the keyboard key/character to process is an ASCII
    ; special key, such as newline, backspace, arrows, etc...
    ; Parameters:
    ;   B - ASCII special character
_editor_event_process_special_ascii:
    ; Put back the character value in A
    ld a, b
    cp KB_KEY_TAB
;    jr z, _controller_insert_tab
    cp KB_KEY_ENTER
;    jp z, _buffer_insert_new_line
    cp KB_KEY_BACKSPACE
;    jp z, _buffer_remove_char_at_cursor
    cp KB_LEFT_ARROW
;    jp z, _buffer_previous_char
    cp KB_RIGHT_ARROW
;    jp z, _buffer_next_char
    cp KB_UP_ARROW
;    jp z, _buffer_previous_line
    cp KB_DOWN_ARROW
;    jp z, _buffer_next_line
    ret

    ; A, B - Character to print
_controller_print_printable:
    call    _controller
    ld      a, b
    ld      (_editor_keys), a
    ld      a, 1
    ld      (_editor_read), a
    ret

_controller:        
    ; If caps lock XOR shift is 1, look for the alternate keys
    ld hl, _editor_flags
    ld a, (hl)
    ; If CTRL key is pressed, interpret the key differently
    and FLAGS_CTRL_MASK
    jr nz, _controller_ctrl_combination
    
    ld a, (hl)
    ; Put LSB in D
    ld d, 0
    rrca
    rl d
    and 1
    xor d
    ; If the result is 0, no need to look for the alternate set
    ret z
    ; Else, we have to get the alternate set of keys
    ld a, b
    ; Check if it starts before or after 0x5B
    cp 0x5b
    jp c, _controller_print_printable_before
    ld hl, alternate_key_set_from_bracket
    sub 0x5b
    jp _controller_print_printable_table
_controller_print_printable_before:
    ld hl, alternate_key_set_from_space
    sub 0x20
_controller_print_printable_table:
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld b, (hl)
    ret


    ; A CTRL + Key combination was pressed, interpret it here
    ; Parameter:
    ;   B - Character pressed with CTRL (printable char)
    ; Returns:
    ;   -
    ; Alters:
    ;   A, BC, DE, HL
_controller_ctrl_combination:
    ld  a, b

    cp  KB_KEY_C
    jz  code_quit

    cp KB_KEY_L
;    jp z, model_show_location
    cp KB_KEY_S
;    jp z, model_save_file
    cp KB_KEY_K
;    jr z, _controller_ask_and_exit
    ; Unsupported feature
    ld hl, str_unsupported
    ret


str_unsupported: DEFM "Not implemented", 0
alternate_key_set_from_space:   ; Characters starting at 0x20
    DEFM " !\"#$%&\"()*+<_>?)!@#$%^&*(::<+>?"
alternate_key_set_from_bracket: ; Characters starting at 0x5B
    DEFM "{|}^_~ABCDEFGHIJKLMNOPQRSTUVWXYZ"


_editor_keys:  DEFS 1
_editor_read:  db   0
_editor_flags: DEFM 0


