divide16:
;   From: https://github.com/Zeda/Z80-Optimized-Routines/blob/master/math/division/BC_Div_DE_faster.z80
;
;   BC/DE ==> BC, remainder in HL
;   NOTE: BC/0 returns 0 as the quotient.
;   min: 738cc
;   max: 898cc
;   avg: 818cc
;   144 bytes

  xor a
  ld h,a
  ld l,a
  sub e
  ld e,a
  sbc a,a
  sub d
  ld d,a

  ld a,b
  rla \ adc hl,hl \ add hl,de \ jr c,$+4 \ sbc hl,de
  rla \ adc hl,hl \ add hl,de \ jr c,$+4 \ sbc hl,de
  rla \ adc hl,hl \ add hl,de \ jr c,$+4 \ sbc hl,de
  rla \ adc hl,hl \ add hl,de \ jr c,$+4 \ sbc hl,de
  rla \ adc hl,hl \ add hl,de \ jr c,$+4 \ sbc hl,de
  rla \ adc hl,hl \ add hl,de \ jr c,$+4 \ sbc hl,de
  rla \ adc hl,hl \ add hl,de \ jr c,$+4 \ sbc hl,de
  rla \ adc hl,hl \ add hl,de \ jr c,$+4 \ sbc hl,de
  rla
  ld b,a

  ld a,c
  rla \ adc hl,hl \ add hl,de \ jr c,$+4 \ sbc hl,de
  rla \ adc hl,hl \ add hl,de \ jr c,$+4 \ sbc hl,de
  rla \ adc hl,hl \ add hl,de \ jr c,$+4 \ sbc hl,de
  rla \ adc hl,hl \ add hl,de \ jr c,$+4 \ sbc hl,de
  rla \ adc hl,hl \ add hl,de \ jr c,$+4 \ sbc hl,de
  rla \ adc hl,hl \ add hl,de \ jr c,$+4 \ sbc hl,de
  rla \ adc hl,hl \ add hl,de \ jr c,$+4 \ sbc hl,de
  rla \ adc hl,hl \ add hl,de \ jr c,$+4 \ sbc hl,de
  rla
  ld c,a

  ret

div32_16:
;HLIX/BC -> HLIX remainder DE
;174+4*div32_16_sub8
;min: 2186cc
;max: 2794cc
;avg: 2466cc
;61 bytes
  ex de,hl   ; 4

; Negate BC to allow add instead of sbc
  xor a      ; 4
; Need to set HL to 0 anyways, so save 2cc and a byte
  ld h,a     ; 4
  ld l,a     ; 4
  sub c      ; 4
  ld c,a     ; 4
  sbc a,a    ; 4
  sub b      ; 4
  ld b,a     ; 4


  ld a,d              ; 4
  call div32_16_sub8  ; 17
  rla                 ; 4
  ld d,a              ; 4

  ld a,e              ; 4
  call div32_16_sub8  ; 17
  rla                 ; 4
  ld e,a              ; 4

  ld a,ixh            ; 8
  call div32_16_sub8  ; 17
  rla                 ; 4
  ld ixh,a            ; 8

  ld a,ixl            ; 8
  call div32_16_sub8  ; 17
  rla                 ; 4
  ld ixl,a            ; 8

  ex de,hl   ; 4
  ret        ; 10

div32_16_sub8:
;119+8*div32_16_sub
;min: 503cc
;max: 655cc
;avg: 573cc
  call next1
next1:
;17+2(17+2(div32_16_sub)))
  call next2
next2:
;17+2(div32_16_sub)
  call div32_16_sub
div32_16_sub:
;48+{8,0+{0,19}}
;min: 48cc
;max: 67cc
;avg: 56.75cc
  rla        ; 4
  adc hl,hl  ; 15
  jr c,next3    ;12/7
  add hl,bc  ; 11
  ret c      ;11/5
  sbc hl,bc  ; 15
  ret        ; 10
next3:
  add hl,bc  ; 11
  scf        ; 4
  ret        ; 10
