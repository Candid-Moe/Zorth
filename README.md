# Zorth: Forth for the Zeal 8-bit OS
Zorth is a free Forth interpreter written from scratch for the Zeal 8-bit OS. 

Currently execute most of the CORE words, plus some extensions:

```see words clearstack dump s= synonym :noname 4hex 2hex holds endcase endof of case repeat while .s /string clear is to value marker within action-of defer! defer@ defer ['] ' ." >body roll recurse exit .r unused u. spaces [ ] lit, lit include parse-name variable buffer: compile, erase fill c, fm/mod um/mod */ */mod / mod /mod 2* min max abs +! 2over 2! 2@ 2r@ 2r> 2>r 2drop 2dup 2swap rot nip tuck over ?dup 0> 0< 0<> 0= <> hex decimal 1- 1+ MID-UINT+1 MID-UINT MIN-INT MAX-INT MAX-UINT MSB <TRUE> <FALSE> 1S 0S case-of case-sys leave-sys do-sys colon-sys value constant ahead , cells cell+ chars .( ( [char] char char+ bl u> u< = > < included }T -> T{ cs-roll s>d source-id find c" >ctrl ctrl> ioctl_set_xy ioctl move dict execute j unloop source xor itoa um* m* 2/ ud/mod leave s" i loop do state does> does> parse quit abort postpone depth c! c@ again until invert cr then else if pick emit drop true false or and base evaluate bye \ literal @ ! ; : create allot here aligned align cmove cs@ cs> >cs rdrop r@ r> >r immediate sm/rem swap lshift rshift * - + dup . pad word str= negate space refill >in type count accept key? key begin hide #s hold #> # <# compile, jmp jz```

Zorth follows the ![Forth Standard](https://forth-standard.org/standard/core) specifications and takes ![gForth](https://gforth.org/) as a reference. You can use both as documentation.

This repository contains:

- prod/zorth.bin and prod/forth.fs, the two files needed to run Forth or make your own os_with_romdisk.img
- prod/os_with_romdisk.img, for running on the real hardware.
- assembler source files if you have interest in it.

## How to run it in the emulator ##

You only need the files `prod/zorth.bin` and `prod/forth.fs`.

In the emulator, type `cd h:/` and then select the PC directory where you copied the files.
Now you have access to your PC directory from the emulador.

In the emulator, type `exec zorth.bin` and voila!

![Screenshot at 2024-08-13 10-20-01](https://github.com/user-attachments/assets/98326d9a-c733-4023-b121-ebfaad680ae2)


## How to run on the Zeal 8-bit board ##
You can load `prod/os_with_romdisk.img` onto your board. This contains the Zeal 8 bits OS plus zorth.bin and forth.fs on drive A:

You can create your own image, packaging zorth.bin and forth.fs onto the romdisk while compiling the OS and then loading the image.

## How compile source files ##

I use the Z80 Assembler from project [z88dk](https://github.com/z88dk/z88dk). You only need `z80asm` file.

Compile with `z80asm -Iinclude -s -l -m -g -b zorth.asm`

## Extensions ##

**2hex** ( x -- ) Display x as two hex digit.

**4hex**  ( x -- ) Display x as four hex digit.

**clear** ( -- )  Clear screen

**clearstack** ( -- ) Clear de data stack

**dict**  ( -- addr ) Address of last entry in dictionary.

**hide** ( -- ) Take the last word of the dictionary, but keep xt valid.

**jz** ( x -- ) If x is zero, jump to the address in the next cell.

**jmp** ( -- ) Jump to the address in the next cell.


