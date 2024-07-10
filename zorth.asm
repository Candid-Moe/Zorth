;
;   Zorth is a Forth interpreter for the Zeal 8 bit OS
;
lstoff
include "zos_sys.asm"
include "macros.asm"
lston

include "main.asm"
include "word.asm"
include "ascii2bin.asm"
include "dictionary.asm"
include "alu.asm"
include "itoa_16.asm"
;   Storage must be the last include
include "storage.asm"

