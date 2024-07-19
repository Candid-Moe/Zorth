;   Zorth - (c) Candid Moe 2024
;   
;   file: file operations
;

load_fs:
    ;
    ;   Load and evaluate the file.
    ;   ( c-addr -- )
    ;
    fenter

    pop     bc      ; File name
    inc     bc      ; Discard count byte
    ld      de, (_DP)
    STAT

    cp      ERR_SUCCESS
    jr      nz, _load_fs_error
    
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

_load_fs_error:
    
    fret


_device_number: db   0
_count:         db   0
_file_buffer:   defs 255    
