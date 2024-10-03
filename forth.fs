\
\	Forth
\
\ : compile, , ;

: bl 32 ;                \ ( -- 0x20 )
: char+ 1 + ;            \ ( c-addr1 -- c-addr2 ) 
: char bl word char+ c@ ; 
: [char] char literal ; immediate
: ( [char] ) parse drop drop ; immediate
: .( [char] ) parse type ; immediate
: chars ;                \ ( n1 -- n2 )

: cell+ 2 + ;
: cells 2 * ;            \ ( n1 -- n2 )
: , here ! 1 cells allot ; 
: ahead here >cs ;

.( Loading dictionary ) cr

: constant create , does> @ ;
: value constant ;

( SYS constants )
1 constant colon-sys
2 constant do-sys
3 constant leave-sys
4 constant case-sys
5 constant case-of

0                   CONSTANT 0S
0 INVERT            CONSTANT 1S
0S                  CONSTANT <FALSE>
1S                  CONSTANT <TRUE> 
1 1 RSHIFT INVERT   CONSTANT MSB

( Numeric constants )
0 invert          constant          MAX-UINT
0 invert 1 rshift constant          MAX-INT
0 invert 1 rshift invert constant   MIN-INT
0 invert 1 rshift constant          MID-UINT
0 invert 1 rshift invert constant   MID-UINT+1

.( . ) 
: 1+    1 + ;
: 1-    1 - ;
: decimal 10 base ! ; 
: hex   16 base ! ; 

( Comparations )
: <>    = invert ;
: 0=    0 = ;
: 0<>   0 <> ;
: 0<    0 < ;
: 0>    0 > ;

(   Stack operations )
.( . ) 
: ?dup  dup 0<> if dup then ;
: over  >r dup r> swap ;  \ ( x1 x2 -- x1 x2 x1 )
: tuck  swap over ;       \ ( x1 x2 -- x2 x1 x2 )
: nip   swap drop ;        \ ( x1 x2 -- x2 )
: rot   >r swap r> swap ;  \ ( x1 x2 x3 -- x2 x3 x1 ) 
: 2swap >r rot r> rot ;  \ ( x1 x2 x3 x4 -- x3 x4 x1 x2 ) 
: 2dup  over over ;
: 2drop drop drop ;
: 2>r   swap >r >r ;              \ ( x1 x2 -- ) ( R: -- x1 x2 ) 
: 2r>   r> r> swap ;              \ ( -- x1 x2 ) ( R: x1 x2 -- ) 
: 2r@   r> r> 2dup >r >r swap ;   \ ( -- x1 x2 ) ( R: x1 x2 -- x1 x2 ) 
: 2@    dup cell+ @ swap @ ;   \ ( a-addr -- x1 x2 ) 
: 2!    swap over ! cell+ ! ;  \ ( x1 x2 a-addr -- ) 
: 2over 3 pick 3 pick ;

.( . ) 

: +!    dup >r @ + r> ! ;
: abs   dup 0< if negate then ;
: max   2dup < if swap drop else drop then ;
: min   2dup < if drop else swap drop then ;

.( . ) 

: 2*    1 lshift ;
: /mod  >R S>D R> SM/REM ;
: mod   /mod drop ;
: /     /mod swap drop ;
: */mod >r m* r> sm/rem ; \ ( n1 n2 n3 -- n4 ) 
: */    */mod swap drop ;
: fm/mod ( d n -- rem quot )
    DUP >R
    SM/REM
    ( if the remainder is not zero and has a different sign than the divisor )
    OVER DUP 0<> SWAP 0< R@ 0< XOR AND 
    IF
        1- SWAP R> + SWAP
    ELSE
        RDROP
    THEN
;
.( . ) 
: c,        here c! 1 allot ; immediate
: fill      rot rot 0 do 2dup ! 1 + loop ; \ ( c-addr u char -- ) 
: erase     0 fill ;
: compile,  , ; immediate
: buffer:   create allot ;
: variable  align here 0 , constant ;
: parse-name bl word count ;
: include   parse-name included  ; ( i*x "name" -- j*x ) 

.( . )  

: lit ( -- x ) ( R: addr1 -- addr2 ) r> dup cell+ >r @ ;
: lit, ( x -- ) postpone literal ;
: ] true  state ! ; immediate
: [ false state ! ; immediate
: spaces 0 do space loop ;

.( . ) 

: u. s>d <# #s #> type ;
: unused $FFFF here - ;
: .r ( n1 n2 -- ) swap dup itoa c@ rot swap - ?dup 0> if spaces then itoa count type ;
: exit      0 , ; immediate
: recurse   dict @ , ; immediate
: roll                          \ x0 i*x u.i -- i*x x0 )
  dup if swap >r 1- recurse r> swap exit then  drop ;
.( . ) 

: >body 10 + ;
: ." postpone s" postpone type ; immediate
: ' bl word find 0= if ." Error. Word not found: " count type 0 then ;
: ['] ( compilation: "name" --; run-time: -- xt ) ' literal ; immediate
: defer  ( "name" -- ) create 0 , does> ( ... -- ... ) @ execute ;
: defer@ ( xt1 -- xt2 ) >body @ ;
: defer! ( xt2 xt1 -- ) >body ! ;
: action-of
   STATE @ IF
     POSTPONE ['] POSTPONE DEFER@
   ELSE
     ' DEFER@
   THEN ; IMMEDIATE
: within ( test low high -- flag ) over - rot rot - u> ;

.( . ) 

: marker dict @ create , does> @ dict ! ; 
: value constant ;
: to ' >body ! ; 
: is
   state @ if
     postpone ['] postpone defer!
   else
     ' defer!
   then ; immediate

.( . ) 

: clear 0 6 0 ioctl ;                   \ Screen clear
: /string  DUP >R - SWAP R> CHARS + SWAP ;
: .s ." < " depth . ." > " depth if depth 0 do i pick . loop then ;

: while ( dest -- orig dest / flag -- )
   \ conditional exit from loops
   postpone if	          \ conditional forward brach
    1 cs-roll	           \ keep dest on top
; immediate

: repeat ( orig dest -- / -- )
   \ resolve a single WHILE and return to BEGIN
   postpone again	       \ uncond. backward branch to dest
   postpone then	       \ resolve forward branch from orig
; immediate

.( . ) 

: case 0  ; IMMEDIATE ( init count of OFs )

: of ( #of -- orig #of+1 / x -- )
   1+	                   ( count OFs )
   >R	                   ( move off the stack in case the control-flow )
                           ( stack is the data stack. )
   POSTPONE OVER POSTPONE = ( copy and test case value)
   POSTPONE IF   	       ( add orig to control flow stack )
   POSTPONE DROP	       ( discards case value if = )
   R>	                   ( we can bring count back now )
; IMMEDIATE

: endof ( orig1 #of -- orig2 #of )
   >R	                   ( move off the stack in case the control-flow )
                           ( stack is the data stack. )
   POSTPONE ELSE
   R>	                   ( we can bring count back now )
; IMMEDIATE

: endcase ( orig1..orign #of -- )
   POSTPONE DROP	        ( discard case value )
   DUP IF
     0 DO
          POSTPONE THEN
       LOOP
   THEN
; IMMEDIATE

: holds ( addr u -- )
   BEGIN DUP WHILE 1- 2DUP + C@ HOLD REPEAT 2DROP ; 
.( . ) 

: :noname s" : noname" evaluate dict @ hide ;

: dump ( addr u -- )                \   Dump memory
    0 do dup c@ s>d <# # # #> type 1 + loop ;

: clearstack ( n ... -- )           \   Delete all items in data stack
    begin 
        depth 
    while 
        drop 
    repeat ;

: words
    dict @ 
    begin
        dup 4 + @ count type space
        @ dup 0=
    until
;                

: 4hex ( print TOS as HHHH ) base @ >r hex s>d <# # # # # #> type r> base ! ;

: see     
    bl word dup ( -- name name )
    find ( -- name xt flag ) 0= if drop count type ."  not found" exit then
    dup 4hex space swap count type
    2 + ( # of pgma steps ) dup c@ >r 
    1+ ( flags ) dup c@ dup
    1 and if ."  colon" then
    2 and if ."  immediate" then
    cr
    1+  ( @name )
    2 + ( @code )
    r> 0 
    do
        dup 4hex space          ( address )
        dup @ dup 4hex space    ( content )
        4 + @ dup $4000 > if count type else drop then ( name )
        cr
        2 +
    loop    
;

cr
.( Finished ) cr
unused u. .(  bytes free) cr



