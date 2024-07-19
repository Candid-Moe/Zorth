\
\	Forth
\
: 1+ 1 + ;
: 1- 1 - ;
: decimal 10 base ! ; 
: hex 16 base ! ; 
: over >r dup r> swap ;  \ ( x1 x2 -- x1 x2 x1 )
: tuck swap over ;       \ ( x1 x2 -- x2 x1 x2 )
: bl 32 ;                \ ( -- 0x20 )
: nip swap drop ;        \ ( x1 x2 -- x2 )
: char+ 1 + ;            \ ( c-addr1 -- c-addr2 ) 
: chars ;                \ ( n1 -- n2 )


