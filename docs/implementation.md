# Implementation
This interpreter implements a Forth virtual machine with three stacks (data, return and control). Most of the code follows Forth conventions, with a few pure Z80 assembler routines.

## Registers
* A, BC, DE, HL are working registers, values not preserved.
* SP is the data stack, used to pass arguments and receive results.
* IX is the return stack, used when calling *code_XXX* routines.
* IY is the control stack, keep track of open control structs.
## Routines
Routines called *code_XXX* implements the *XXX* Forth word. Those must be called using the *fcall* macro. Those must start with `fenter` macro (copies return address to the return stack) and exit with `fret`.

Other routines are normal Z80 routines that follows standard conventions for assembler code.

You can mix callings to either style.
