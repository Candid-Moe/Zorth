# Implementation
This interpreter implements a Forth virtual machine with three stacks (data, return and control). Most of the code follows Forth conventions, with a few pure Z80 assembler routines.

## Registers
* A, BC, DE, HL are working registers, values not preserved.
* SP is the data stack, used to pass arguments and receive results.
* IX is the return stack, used when calling *code_XXX* routines.
* IY is the control stack, keep track of open control structs.

## Names

Standard Forth names like TIB, PAD, etc. are prefixes with underscore, thus _TIB and _PAD.

Routines that implements the Forth word `XXX` are called `code_XXX`.

Due to Z80 Assembler restrictions, Forth names like >IN or #TIB cannot be coded directly. Thus, the following conventions are used:
* '>' is replaced with 'gt' (greather than), thus _gtIN
* '#' is replaced with 'g', thus _gTIB.

## Routines

Routines that implements the *XXX* Forth word must be called using the *fcall* macro. Those must start with `fenter` macro (copies return address to the return stack) and exit with `fret`.

Example:

```
code_pad:
;
;   Implements PAD
;   ( -- c-addr )
;
;   c-addr is the address of a transient region that can be used
;   to hold data for intermediate processing. 
;
    fenter

    ld      hl, _PAD
    push    hl

    fret
``` 
and you called it with
```
fcall code_PAD
```
Other routines are normal Z80 routines that follows standard conventions for assembler code.

You can mix callings to either style.
