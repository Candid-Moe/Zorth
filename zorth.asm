;   Zorth - (c) Candid Moe 2024

;
;   Zorth is a Forth interpreter for the Zeal 8 bit OS
;
lstoff
include "zos_sys.asm"
include "zos_keyboard.asm"
include "zos_video.asm"
include "macros.asm"
lston

include "main.asm"
include "execute.asm"
include "word.asm"
include "rstack.asm"
include "ascii2bin.asm"
include "evaluate.asm"
include "memory.asm"
include "string.asm"
include "control.asm"
include "alu.asm"
include "colon.asm"
include "tester.asm"
include "format.asm"
include "arithmetic/arith.asm"
include "keyboard.asm"
include "dictionary.asm"

;   Storage must be the last include

include "storage.asm"

