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

    ld  a, FALSE
    ld  (_MODE_INTERPRETER), a


    ;   Extract word name from TIB and start new entry
    ld      hl, ' '
    push    hl
    fcall   code_word
    ;   Check for missing name
    pop     hl
    ld      a, (hl)
    cp      0
    jr      z, _colon_error_no_name

    ;   Create dictionary entry
    push    hl
    fcall   code_create

    ;   Put a marker in the control stack   
    ld      hl, colon_sys
    ctrl_push

    ;   Delete default code address
    ld  hl, (_DP)
    dec hl
    dec hl
    ld (_DP), hl

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
;   Implements semicolon CORE
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

    ;   Check the control stack; must have a colon-sys
    ld  a, (IY)
    cp  0
    jr  nz, _code_semmicolon_error
    ld  a, (IY + 1)
    cp  colon_sys
    jr  nz, _code_semmicolon_error

    inc iy
    inc iy

    ;   Mark the end of current definition
    ld  hl, 0
    push hl
    fcall add_cell    
    
    ;   Back to execution mode
    ld  a, TRUE
    ld  (_MODE_INTERPRETER), a

    fret

_code_semmicolon_error:
    ;
    ld  hl, err_mode_not_comp
    fcall   print_line
    fret
    





