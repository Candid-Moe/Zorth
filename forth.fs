\
\	Forth
\
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
: mas if 1 else 2 then 3 ;
