;   Zorth - (c) Candid Moe 2024
;
;   colon:  define a new Forth word
;

code_colon:
;
;   Implements :
;   ( C: "<spaces>name" -- colon-sys )
;
;   Skip leading space delimiters. Parse name delimited by a space. 
;   Create a definition for name, called a "colon definition". 
;   Enter compilation state and start the current definition, 
;   producing colon-sys. 
;   Append the initiation semantics given below to the current definition.
;
;   The execution semantics of name will be determined by the words compiled
;   into the body of the definition. 
;   The current definition shall not be findable in the dictionary until it
;   is ended (or until the execution of DOES> in some systems).
;
;   Initiation:
;   ( i * x -- i * x ) ( R: -- nest-sys )
;
;   Save implementation-dependent information nest-sys about the calling definition.
;   The stack effects i * x represent arguments to name.
;
;   name Execution:
;   ( i * x -- j * x )
;
;   Execute the definition name. 
;   The stack effects i * x and j * x represent arguments to and results 
;   from name, respectively. 
;
    fenter

    ;   Check MODE_EXECUTION
    ld  a, (_MODE_INTERPRETER)
    cp  TRUE
    jr  nz, _colon_error

    ;   Create dictionary entry

    fcall   code_create
    jr      z, _colon_end
    
    ld  a, FALSE
    ld  (_MODE_INTERPRETER), a

    ;   Put a marker in the control stack   
    ld      hl, colon_sys
    ctrl_push

    ;   Delete default code gen by CREATE
    ld  hl, (_DP)
    dec hl
    dec hl
;    dec hl
;    dec hl
    ld (_DP), hl

    ;
    ;   Mark entry as COLON definition
    ;
    ld  hl, (_DICT)
    inc hl
    inc hl

    ld  a, (hl)
    or  BIT_COLON
    ld  (hl), a

_colon_end:

    fret

_colon_error:
    ;
    ;   Display error message and quit
    ;
    ld hl, err_mode_comp
    push hl
    fcall print_line
    fret

_colon_error_no_name:
    ;
    ;   No name was given
    ;
    ld hl, err_missing_name
    push hl
    fcall print_line
    fret

code_semmicolon:
;
;   Implements ;
;
;   Interpretation:
;   Interpretation semantics for this word are undefined.
;
;   Compilation:
;   ( C: colon-sys -- )
;
;   Append the run-time semantics below to the current definition. 
;   End the current definition, allow it to be found in the dictionary 
;   and enter interpretation state, consuming colon-sys. 
;   If the data-space pointer is not aligned, reserve enough data space to align it.
;
;   Run-time:
;   ( -- ) ( R: nest-sys -- )
;
;   Return to the calling definition specified by nest-sys.
;
    fenter

    ;   Check MODE
    ld  a, (_MODE_INTERPRETER)
    cp  FALSE
    jr  nz, _colon_error

    ;   Back to execution mode
    ld  a, TRUE
    ld  (_MODE_INTERPRETER), a

    ;   Check the control stack; must have a colon-sys
    ctrl_pop
    ld  de, colon_sys
    set_carry_0   
    sbc hl, de

    jr  nz, _code_unstructed_error

    ;   Mark the end of current definition
    ld  hl, 0
    push hl
    fcall add_cell    
    
    fret

_code_unstructed_error:
        
    fcall dict_delete_last

    ld  hl, err_unstructed
    push hl
    fcall print_line

    ld  hl, _PAD
    push hl
    fcall print_line
    fcall code_backslash
    
    fret

