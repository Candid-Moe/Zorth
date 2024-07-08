;written by Zeda
;Converts a 16-bit signed integer to an ASCII string.

itoa_16:
;Input:
;   DE is the number to convert
;   HL points to where to write the ASCII string (up to 7 bytes needed).
;Output:
;   HL points to the null-terminated ASCII string
;      NOTE: This isn't necessarily the same as the input HL.
  push de
  push bc
  push af
  push hl
  bit 7,d
  jr z, uno
  xor a
  sub e
  ld e,a
  sbc a,a
  sub d
  ld d,a
  ld (hl),'-'     ;negative char on TI-OS
  inc hl
uno:
  ex de,hl

  ld bc,-10000
  ld a,'0'-1
  inc a 
  add hl,bc 
  jr c,$-2
  ld (de),a
  inc de

  ld bc,1000
  ld a,'9'+1
  dec a 
  add hl,bc 
  jr nc,$-2
  ld (de),a
  inc de

  ld bc,-100
  ld a,'0'-1
  inc a 
  add hl,bc 
  jr c,$-2
  ld (de),a
  inc de

  ld a,l
  ld h,'9'+1
  dec h 
  add a,10 
  jr nc,$-3
  add a,'0'
  ex de,hl
  ld (hl),d
  inc hl
  ld (hl),a
  inc hl
  ld (hl),0

;No strip the leading zeros
  pop hl

;If the first char is a negative sign, skip it
  ld a,(hl)
  cp $1A
  push af
  ld a,'0'
  jr nz,$+3
  inc hl
  cp (hl)
  jr z,$-2

;Check if we need to re-write the negative sign
  pop af
  jr nz,dos
  dec hl
  ld (hl),a
dos:

  pop af
  pop bc
  pop de
  ret 
