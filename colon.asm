;   Zorth - (c) Candid Moe 2024
;
;   colon:  define a new Forth word
;

code_colon:
;
;   Implements :
:   ( C: "<spaces>name" -- colon-sys )
:
:   Skip leading space delimiters. Parse name delimited by a space. 
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

    ld  (_MODE_EXECUTION), FALSE

    ;   Extract word name from TIB
    ld      hl, ' '
    push    hl
    fcall   code_word

    ;   Put a marker in the control stack   
    ld      hl, colon_sys
    ctrl_push
    
    ;   Start a new entry
    fcall   dict_new

    fret

