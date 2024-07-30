\
\	Forth
\
: , here ! 1 allot ; 
: 1+ 1 + ;
: 1- 1 - ;
: decimal 10 base ! ; 
: bl 32 ;                \ ( -- 0x20 )
: hex 16 base ! ; 
: 0= $0000 or  if false else true then ;
: 0< $8000 and if true else false then ;
: 0> 0= if false else 0< if false else true then then ; \ ( n -- flag ) if n > 0
: 0<> 0= invert ;
: > - 0> ;
: < - 0< ;
: <> - 0<> ;
: = - 0= ;
: over >r dup r> swap ;  \ ( x1 x2 -- x1 x2 x1 )
: tuck swap over ;       \ ( x1 x2 -- x2 x1 x2 )
: nip swap drop ;        \ ( x1 x2 -- x2 )
: rot >r swap r> swap ;  \ ( x1 x2 x3 -- x2 x3 x1 ) 
: 2swap >r rot r> rot ;  \ ( x1 x2 x3 x4 -- x3 x4 x1 x2 ) 
: 2dup over over ;
: ?dup dup 0<> if dup then ;
: char+ 1 + ;            \ ( c-addr1 -- c-addr2 ) 
: chars ;                \ ( n1 -- n2 )
: cells 2 * ;            \ ( n1 -- n2 )
: +! dup >r @ + r> ! ;
: abs dup 0< if negate then ;
: max 2dup < if swap drop else drop then ;
: buffer create allot ;
: char bl word 1 + c@ ; immediate
: c, here c! 1 allot ; immediate
: compile, , 1 cells allot ; immediate
: [char] postpone char postpone literal ; immediate
: ( [char] ) parse drop drop ; immediate
: .( [char] ) parse type ; immediate
: , here ! 1 cells allot ;
: constant create , does> @ ;
: variable align here 0 , constant ;

