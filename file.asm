;   Zorth - (c) Candid Moe 2024
;   
;   file: file operations
;

code_xincluded:
;
;   Implements INCLUDED 
;   ( i * x c-addr u -- j * x )
;
;   Remove c-addr u from the stack. Save the current input source specification, 
;   including the current value of SOURCE-ID. Open the file specified by c-addr u, 
;   store the resulting fileid in SOURCE-ID, and make it the input source. 
;   Store zero in BLK. Other stack effects are due to the words included.
;
;   Repeat until end of file: read a line from the file, fill the input buffer from 
;   the contents of that line, set >IN to zero, and interpret.
;
;   Text interpretation begins at the start of the file.
;
;   When the end of the file is reached, close the file and restore the input source
;   specification to its saved value.
;
;   An ambiguous condition exists if the named file can not be opened, if an I/O
;   exception occurs reading the file, or if an I/O exception occurs while closing
;   the file. When an ambiguous condition exists, the status (open or closed) of 
;   any files that were being interpreted is implementation-defined.
;
;   INCLUDED may allocate memory in data space before it starts interpreting the file. 
    
    fenter
    
    pop     hl      ; Discard count byte
    pop     bc      ; File name address
    add     hl, bc
    ld      (hl), 0 ; make it an ASCIIZ string
    ld      de, (_DP)
    STAT

    cp      ERR_SUCCESS
    jr      z, _load_fs_open

    ;   File not found
    ld      hl, err_file_not_found
    push    hl
    fcall   print_line
    fcall   code_cr
    jr      _load_fs_end    

_load_fs_open:
    
    ld      h, O_RDONLY
    OPEN
    ld      (_device_number), a

_load_fs_block:

    ;   Always read a full buffer

    ld      de, _file_buffer
    ld      bc, 255
    ld      a, (_device_number)
    ld      h, a
    READ

    ld      a, c    ; BC = number of bytes read
    cp      255
    jr      nz,     _load_fs_last

_load_fs_full_block:    

    ;   Search the last '\n' and "cut" the buffer there

    ld      hl, _file_buffer + 254
    ld      a, '\n'
    cpdr

    ld      hl, _file_buffer
    push    hl
    push    bc
    ld      a, c
    ld      (_count), a
    fcall   code_evaluate

    ;   Do a SEEK to restart reading from last incomplete line
    ld      a,  (_device_number)
    ld      h, a
    ld      bc, -1
    ld      d, -1

    ld      a, (_count)
    sub     255
    ld      e, a

    ld      a, SEEK_CUR
    SEEK

    jr      _load_fs_block

_load_fs_last:

    ld      hl, _file_buffer
    push    hl
    push    bc
    fcall   code_evaluate

    ld      a, (_device_number)
    CLOSE

_load_fs_end:
    
    fret


_device_number: db   0
_count:         db   0
_file_buffer:   defs 255    
