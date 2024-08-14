\
\	Forth
\
: bl 32 ;                \ ( -- 0x20 )
: char bl word 1 + c@ ; immediate
: [char] postpone char postpone literal ; immediate
: ( [char] ) parse drop drop ; immediate
: .( [char] ) parse type ; immediate
: cells 2 * ;            \ ( n1 -- n2 )
: , here ! 1 cells allot ; 

.( Loading dictionary )

: constant create , does> @ ;

1 constant colon-sys
2 constant do-sys
3 constant leave-sys
4 constant case-sys
5 constant case-of

.( . )
: 1+ 1 + ;
: 1- 1 - ;
: m* * ;
: decimal 10 base ! ; 
: hex 16 base ! ; 
: 0= $0000 or  if false else true then ;
: 0<> 0= invert ;
: ?dup dup 0<> if dup then ;
: 0< $8000 and if true else false then ;
: 0> ?dup 0= if false else 0< if false else true then then ; \ ( n -- flag ) if n > 0
.( . )
: > - 0> ;
: < - 0< ;
: <> - 0<> ;
: = - 0= ;
: over >r dup r> swap ;  \ ( x1 x2 -- x1 x2 x1 )
: tuck swap over ;       \ ( x1 x2 -- x2 x1 x2 )
: nip swap drop ;        \ ( x1 x2 -- x2 )
: rot >r swap r> swap ;  \ ( x1 x2 x3 -- x2 x3 x1 ) 
.( . )
: 2swap >r rot r> rot ;  \ ( x1 x2 x3 x4 -- x3 x4 x1 x2 ) 
: 2dup over over ;
: 2drop drop drop ;
: 2>r swap >r >r ;       \ ( x1 x2 -- ) ( R: -- x1 x2 ) 
: 2r> r> r> swap ;       \ ( -- x1 x2 ) ( R: x1 x2 -- ) 
: 2r@ r> r> 2dup >r >r swap ; \ ( -- x1 x2 ) ( R: x1 x2 -- x1 x2 ) 
.( . )
: char+ 1 + ;            \ ( c-addr1 -- c-addr2 ) 
: chars ;                \ ( n1 -- n2 )
: cell+ 2 + ;
: 2@ dup cell+ @ swap @ ;   \ ( a-addr -- x1 x2 ) 
: 2! swap over ! cell+ ! ;  \ ( x1 x2 a-addr -- ) 
: 2* 1 lshift ;
.( . )
: 2over 3 pick 3 pick ;
: +! dup >r @ + r> ! ;
: s>d dup 0< if -1 else 0 then ;
: abs dup 0< if negate then ;
: max 2dup < if swap drop else drop then ;
: min 2dup < if drop else swap drop then ;
.( . )
: c, here c! 1 allot ; immediate
: fill rot rot 0 do 2dup ! 1 + loop ; \ ( c-addr u char -- ) 
: erase 0 fill ;
: compile, , ; immediate
: buffer:  create allot ;
: variable align here 0 , constant ;
: value constant ;
.( . )
: lit ( -- x ) ( R: addr1 -- addr2 ) r> dup cell+ >r @ ;
: lit, ( x -- ) postpone literal ;
: ] true  state ! ; immediate
: [ false state ! ; immediate
: spaces 0 do space loop ;
.( . )
: /mod 
       dup $8000 and dup >r >r abs swap 
       dup $8000 and >r abs swap 
       divide r> r>  
       <> if 
            1+ negate swap 1+ swap
          then
       r> if
            swap negate swap
         then ;
.( . )
: mod /mod drop ;
: / dup $8000 and >r abs swap 
    dup $8000 and >r abs swap 
    divide swap drop r> r>  
    <> if negate then ;

: u. dup 0< if 10000 swap over 5 0 do /mod $30 + emit swap 10 / swap over loop drop else . then ;
: u< - 0< ;
: u> - 0> ;
: .r ( n1 n2 -- ) swap dup itoa c@ rot swap - ?dup 0> if spaces then itoa count type ;
: exit 0 , ; immediate
.( . )
: >body 10 + ;
: ['] ( compilation: "name" --; run-time: -- xt ) ' postpone literal ; immediate
: ." postpone s" ['] type postpone , ; immediate
: defer ( "name" -- ) create 0 , does> ( ... -- ... ) @ execute ;
: defer@ ( xt1 -- xt2 ) >body @ ;
: defer! ( xt2 xt1 -- ) >body ! ;
: action-of state @ if
        postpone ['] postpone defer@
    else
        ' defer@
    then ; immediate
: within ( test low high -- flag ) over - rot rot - u> ;
.( . )
: marker dict @ create , does> @ dict ! ; 
: recurse dict @ , ; immediate
: value constant ;
: to ' >body ! ; 
: is
   state @ if
     postpone ['] postpone defer!
   else
     ' defer!
   then ; immediate
\ : abort" state @ if postpone s" type else ." Interpreting a compile-only word" then ; immediate
.( . )
: clear 0 6 0 ioctl ;                   \ Screen clear
: unused $FFFF here - ;
: case case-sys >cs ; immediate        
: of over = ;
: endof ;
: endcase cs> drop does> drop ;
.( . )
        
: fac ( +n1 -- +n2)
   dup 2 < if drop 1 exit then
   dup 1- recurse * ;

: collentz ( u -- )
    begin
        dup u.
        dup 1 = 
            if 
                drop exit 
            then
        dup 1 and 
            if
                3 * 1 +
            else
                1 rshift
            then
    again ;

\ 10 7 /mod . .  \ 1 3
\ 10 -7 /mod . . \ -2 -4
\ -10 7 /mod . . \ -2 4
\ -10 -7 /mod . . \ 1 -3
cr

