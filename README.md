# Zorth: Forth for the Zeal 8-bit OS
Zorth is a free Forth interpreter written from scratch for the Zeal 8-bit OS. 

![Screenshot at 2024-08-13 06-59-51](https://github.com/user-attachments/assets/dbbb56f1-df31-4f70-884e-5b439821c319)

Currently execute most of the CORE words, plus some extensions. 

Zorth follows the ![Forth Standard](https://forth-standard.org/standard/core) specifications and takes ![gForth](https://gforth.org/) as a reference. You can use both as documentation.

This repository contains:

- zorth.bin and forth.fs, the two files needed to run Forth or make your own os_with_romdisk.img
- os_with_romdisk.img, for running on the real hardware.
- assembler source files if you have interest in it.

## How to run it in the emulator ##

You only need the files `zorth.bin` and `forth.fs`.

In the emulator, type `cd h:/` and then select the PC directory where you copied the files.
Now you have access to your PC directory from the emulador.

In the emulator, type `exec zorth.bin` and voila!

![Screenshot at 2024-08-13 10-20-01](https://github.com/user-attachments/assets/98326d9a-c733-4023-b121-ebfaad680ae2)


## How to run on the Zeal 8-bit board ##
You can load `os_with_romdisk.img` onto your board. This contains the Zeal 8 bits OS plus zorth.bin and forth.fs on drive A:

You can create your own image, packaging zorth.bin and forth.fs onto the romdisk while compiling the OS and then loading the image.

## How compile source files ##

I use the Z80 Assembler from project [z88dk](https://github.com/z88dk/z88dk). You only need `z80asm` file.

Compile with `z80asm -Iinclude -s -l -m -g -b zorth.asm`

## Extensions ##

**clear** ( -- )  Clear screen

**dict**  ( -- addr ) Address of dictionary pointer.

## Pending ##

- Most formating/editing words.
- case, of, endof, endcase and other control structures
- accept, key
