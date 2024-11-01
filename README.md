# Zorth: Forth for the Zeal 8-bit OS
Zorth is a free Forth interpreter written from scratch for the Zeal 8-bit OS. 

Currently execute most of the CORE words, plus some extensions:

```
! # #> ' ( * */ + +! , - -> . ." .( / : ; < <# <> = > @ [ ['] \ ] 0< 0<>
0= 0> 0S 1+ 1- 1S 2! 2* 2/ 2@ 2drop 2dup 2hex 2over 2>r 2r> 2r@ 2swap 4hex
abort abort" abs accept action-of again ahead align aligned allocate allot
and asciiz at-xy base begin bin bl blank >body buffer: bye c! c" c, c@ case
case-of case-sys cell+ cells [char] char char+ chars clearstack
close-file cmove colon-sys colors compile, constant count cr create create-file
>cs cs> cs@ cs-roll decimal defer defer! defer@ delete-file depth dict ?do do does>
do-sys drop dump ?dup dup else emit endcase endof erase evaluate execute exit
false <FALSE> FILENAME-LEN-MAX file-position file-seek file-size fill find flush-file
fm/mod free heap here hex hide hold holds i if immediate >in in-buf include included
include-file invert ioctl is j jmp jz key key? leave leave-sys line-terminator literal
+loop loop lshift m* marker max MAX-INT MAX-UINT MID-UINT MID-UINT+1 min MIN-INT
*/mod /mod mod move MSB namez negate nip :noname noop o-create of open-file or
over pad page parse parse-name pick postpone quit .r >r r> r@ rdrop read-file
read-line recurse refill repeat reposition-file resize r/o roll -rot rot rshift
r/w #s .s s" s= same-page scan s>d see SEEK-CUR SEEK-END SEEK-SET sign sm/rem
source source-id space spaces state str= /string swap synonym }T T{ TEXT-COLOR-BLACK
TEXT-COLOR-BLUE TEXT-COLOR-BROWN TEXT-COLOR-CYAN TEXT-COLOR-DARK-BLUE TEXT-COLOR-DARK-CYAN
TEXT-COLOR-DARK-GRAY TEXT-COLOR-DARK-GREEN TEXT-COLOR-DARK-MAGENTA TEXT-COLOR-DARK-RED
TEXT-COLOR-GREEN TEXT-COLOR-LIGHT-GRAY TEXT-COLOR-MAGENTA TEXT-COLOR-RED TEXT-COLOR-WHITE
TEXT-COLOR-YELLOW then then, to true <TRUE> tuck type u. u< u> ud/mod um* um/mod unloop
until unused value value variable while within w/o word words write-file write-line xor
z80-syscall
```

Zorth follows the [Forth Standard](https://forth-standard.org/standard/core) specifications and takes [gForth](https://gforth.org/) as a reference. You can use both as documentation.

This repository contains:

- prod/zorth.bin, the file needed to run Forth or make your own os_with_romdisk.img
- prod/os_with_romdisk.img, for running on the real hardware.
- assembler source files if you have interest in it.

## Status ##

This project is in beta. It runs in my machine, but needs users to fully test it.

## How to run it in the emulator ##

You only need the file `prod/zorth.bin`.

In the emulator, type `cd h:/` and then select the PC directory where you copied the file.
Now you have access to your PC directory from the emulador.

In the emulator, type `exec zorth.bin` and voila!

![Screenshot at 2024-08-13 10-20-01](https://github.com/user-attachments/assets/98326d9a-c733-4023-b121-ebfaad680ae2)


## How to run on the Zeal 8-bit board ##
You can load `prod/os_with_romdisk.img` onto your board. This contains the Zeal 8 bits OS plus zorth.bin and forth.fs on drive A:

You can create your own image, packaging zorth.bin onto the romdisk while compiling the OS and then loading the image.

## How compile source files ##

I use the Z80 Assembler from project [z88dk](https://github.com/z88dk/z88dk). You only need `z80asm` file.

Compile with `z80asm -Iinclude -s -l -m -g -b zorth.asm`

## Extensions ##

**asciiz** ( c-addr1 u c-addr2 -- c-addr2 ) \ Converts text c-addr1 u to asciiz in c-addr2 
    
**2hex** ( x -- ) Displays x as two hex digit.

**4hex**  ( x -- ) Displays x as four hex digit.

**clear** ( -- )  Clears the screen.

**clearstack** ( i * x -- ) Clears the data stack

**dict**  ( -- addr ) Address of dictionary pointer (to last entry).

**heap** ( -- addr ) Address of heap pointer.

**hide** ( -- ) Remove the last word of the dictionary, but keeps xt valid. 

**ioctl** ( device_number command_number param -- flag ) Execute a IOCTL.

**jz** ( x -- ) If x is zero, jump to the address in the next cell.

**jmp** ( -- ) Jump to the address in the next cell.

**>cs** ( x -- ; C: -- x ) Push TOS to the control stack

**cs>** ( -- x ; C: x -- ) Pops x from control stack and pushes it into the data stack.

**cs@** ( -- x ; C: x -- x ) Fetch x from control stack and pushes into the data stack.

**noop** ( -- ) No operation

**unused** ( -- x ) RAM free space (in bytes)

**-rot** ( w1 w2 w3 – w3 w1 w2 ) \ gforth

**same-page** ( x -- ) guarantees that the next n bytes will be on the same page in memory

Check the assembler files in *include/* sudirectory for system/hardware parameters-
