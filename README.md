# Zorth: Forth for the Zeal 8-bit OS
Zorth is a free Forth interpreter written from scratch for the Zeal 8-bit OS. 

![Screenshot at 2024-08-13 06-59-51](https://github.com/user-attachments/assets/dbbb56f1-df31-4f70-884e-5b439821c319)

Currently execute most of the CORE words, plus some extensions.

This repository contains:

- zorth.bin and forth.fs, the two files needed to run Forth.
- assembler source files if you have interest in it.

## How to run it in the emulator ##

In the emulator, type `cd h:/` and then select your PC directory where you copy the files.
Now you have access to your PC directory from the emulador.
In the emulator, type `exec zorth.bin` and voila!

![Screenshot at 2024-08-13 10-20-01](https://github.com/user-attachments/assets/98326d9a-c733-4023-b121-ebfaad680ae2)


## How to run in the Zeal 8-bit board ##

You have to pack zorth.bin and forth.fs in the romdisk while compiling the operating system, and then upload the image

## How compile source files ##

I use the Z80 Assembler from project [z88dk](https://github.com/z88dk/z88dk). You only need `z80asm` file.

Compile with `z80asm -Iinclude -s -l -m -g -b zorth.asm`

## Extensions ##

**clear** ( -- )  Clear screen

**dict**  ( -- addr ) Address of dictionary pointer.

## Pending ##

- Several unsigned arithmetic operations.
- Most formating/editing words.
- case, of, endof, endcase.
- accept, key
