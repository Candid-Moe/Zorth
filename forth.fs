\
\	Forth
\
: , here ! 1 allot ;
: 1+ 1 + ;
: 1- 1 - ;
: decimal 10 base ! ; 
: bl 32 ;                \ ( -- 0x20 )
: hex 16 base ! ; 
: over >r dup r> swap ;  \ ( x1 x2 -- x1 x2 x1 )
: tuck swap over ;       \ ( x1 x2 -- x2 x1 x2 )
: nip swap drop ;        \ ( x1 x2 -- x2 )
: rot >r swap r> swap ;  \ ( x1 x2 x3 -- x2 x3 x1 ) 
: 2swap >r rot r> rot ;  \ ( x1 x2 x3 x4 -- x3 x4 x1 x2 ) 
: char+ 1 + ;            \ ( c-addr1 -- c-addr2 ) 
: chars ;                \ ( n1 -- n2 )
: cells 2 * ;            \ ( n1 -- n2 )
: 0= $0000 or  if false else true then ;
: 0< $8000 and if true else false then ;
: 0> 0= if false else 0< if false else true then then ; \ ( n -- flag ) if n > 0
: 0<> 0= invert ;
: > - 0> ;
: < - 0< ;
: <> - 0<> ;
: = - 0= ;
: +! dup >r @ + r> ! ;
: abs dup 0< if negate then ;
: ?dup dup 0<> if dup then ;
: buffer create allot ;
: char bl word 1 + c@ ;
: c, here c! 1 allot ; immediate
: compile, , 2 allot ; immediate


