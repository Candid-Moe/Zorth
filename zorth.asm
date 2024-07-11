;   Zorth - (c) Candid Moe 2024

;
;   Zorth is a Forth interpreter for the Zeal 8 bit OS
;
lstoff
include "zos_sys.asm"
include "macros.asm"
lston

include "main.asm"
include "word.asm"
include "rstack.asm"
include "ascii2bin.asm"
include "dictionary.asm"
include "alu.asm"
include "multiply.asm"
include "divide.asm"
include "itoa.asm"
include "itoa_16.asm"

;   Storage must be the last include

include "storage.asm"

