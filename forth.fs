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
: over  >r dup r> swap ;    \ ( x1 x2 -- x1 x2 x1 )
: tuck  swap over ;         \ ( x1 x2 -- x2 x1 x2 )
: nip   swap drop ;         \ ( x1 x2 -- x2 )
: rot   >r swap r> swap ;   \ ( x1 x2 x3 -- x2 x3 x1 ) 
: 2swap >r rot r> rot ;     \ ( x1 x2 x3 x4 -- x3 x4 x1 x2 ) 
: 2dup  over over ;
: 2drop drop drop ;
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
: um/mod ( ud u1 -- u2 u3) ud/mod drop ;
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
: -rot  2 roll 2 roll ;         \ ( w1 w2 w3 – w3 w1 w2 ) gforth

.( . ) 

: >body 10 + ;
: ." postpone s" postpone type ; immediate
: ' bl word find 0= if ." Error. Word not found: " count type 0 then ; 
: ['] ( compilation: "name" --; run-time: -- xt ) postpone ' ; immediate
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

: 2hex ( print low TOS byte as HH ) base @ >r hex s>d <# # # #> type r> base ! ;
: 4hex ( print TOS as HHHH ) base @ >r hex s>d <# # # # # #> type r> base ! ;

: :noname s" : noname" evaluate dict @ hide ;
: synonym ( "newname" "oldname" -- )
    create      ( Make a new empty dict entry)
    bl word
    find ( -- name xt flag ) 0= if drop count type ."  not found" exit then
    dup
    2 + @ ( Flags and length )
    dict @ 2 + !
    6 + @ ( Code address )
    dict @ 6 + !
;
synonym s= str=

: allocate ( u -- a-addr ior )
    2 + ( space for ptr ) heap @ swap - ( -- addr )
    1- aligned dup                      ( -- a-addr a-addr )  
    here u> if
        dup heap @ swap !   ( write old heap under the block)
        dup heap !
        2 +         ( heap -- a-addr )
        0           ( -- a-addr ior )
    else
        -1          ( heap -- heap -1 )
    then
;

: free ( a-addr -- ior )
    2 - @ ?dup if
        heap !
        0       ( -- ior )
    else
        -1      ( -- ior )
    then
;

.( . ) 

: asciiz \ Convert text c-addr1 u to asciiz in c-addr2 
    ( c-addr1 u c-addr2 -- c-addr2 )
    dup    >r
    2dup + >r
    swap move
    0 r> c!
    r>
    ;

: dump ( addr u -- )                \   Dump memory
    0 do space dup c@ 2hex 1 + loop drop ;

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
    drop
;                

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

: same-page ( u -- )    \ Garanties that next u size bytes allocted from same page
    here + $c000 and dup here $c000 and
    = if
        drop
    else
        here - allot
    then
;

.( . )
\ The values for these constant are dictated by Zeal-8 OS
\ FAM constants. See zos_sys.asm

$000  constant r/o 
$100  constant w/o 
$200  constant r/w
$1000 constant o_create

16    constant FILENAME_LEN_MAX

0     constant SEEK_SET
1     constant SEEK_CUR
2     constant SEEK_END

300 same-page
256 buffer: in_buf
17  buffer: namez
variable line-terminator
$a line-terminator !

: bin ( fam1 -- fam2 ) ;

: flush-file ( fileid -- ior ) ;

: file-seek ( ud seek fileid -- ud-offset ior )
    8 lshift 6 + swap            ( -- ud file-op seek )
    >r rot rot r> 
    z80-syscall
    3 roll drop
    ;    

: file-size ( fileid -- ud ior )
    8 lshift 4 + in_buf 0 0
    z80-syscall
    >r drop drop drop
    in_buf @ 
    in_buf 2 + @
    r>
    ;

: file-status ( c-addr u -- x ior )
    namez asciiz 5 swap         
    in_buf swap 0
    z80-syscall
    nip nip nip
    ;

: file-position ( fileid -- ud ior ) 
    >r 0 0 SEEK_CUR r>
    file-seek
    ;
    
: open-file ( c-addr u fam -- fileid ior ) \ ior = 0 means sucess 
            >r namez asciiz r>
            2 + swap            \ HL = flags + OPEN code            
            0 swap              \ DE = 0, BC = z-addr
            0                   \ A
            z80-syscall
            nip nip nip
            dup $80 < if 0 else dup $ff00 + abs then            
    ;

: close-file ( fileid -- ior ) 
    8 lshift 3 + 0 0 0
    z80-syscall
    nip nip nip
    ;

: create-file ( c-addr u fam -- fileid ior )
    o_create or
    open-file
    ;

: delete-file ( c-addr u -- ior ) 
    dup 1+ allocate            ( -- c-addr u addr2 ior )
    if drop drop drop -1 exit then
    ( -- c-addr u addr2 )
    2dup + 0 swap !             \ put a '\0' at the end
    dup >r                      ( -- c-addr u addr2 : R -- addr2 ) 
    swap move
    #13 r@ 0 0 
    z80-syscall
    nip nip nip
    r> free drop
    ;

: read-file ( c-addr u1 fileid -- u2 ior ) 
    8 lshift rot rot ( -- fileid c-addr u1 )
    0
    z80-syscall
    2>r 2drop 2r>
    ;

: reposition-file ( ud fileid -- ior )
    SEEK_SET swap 
    file-seek
    nip nip
    ;
    
: read-line ( c-addr u1 fileid -- u3 flag ior )
    2>r dup 2r> dup >r  ( -- c-addr c-addr u1 fileid : R -- fileid)
    read-file           ( -- c-addr u2 ior )
    if ." read failed" rdrop drop 0 0 -1 exit then
    ?dup 0= if rdrop ." eof " 0 0 -1 exit then

    swap over           ( -- u2 c-addr u2 )
    0x0a scan nip       ( -- u2 u3 )
    ?dup if                    
        dup >r - 1+ r>         ( -- u2-u3 u3 )
        1- negate s>d       ( -- u2-u3 ud )
        SEEK_CUR r> file-seek 2drop drop ( -- u2-u3 )
        true 0       
    else
        2drop 2drop drop rdrop
        0 false -1
    then
    ;
    
: write-file ( c-addr u fileid -- ior ) 
    8 lshift 1 + ( HL = fileid & write code)
    -rot 0
    z80-syscall
    nip nip nip
    ;

: write-line    ( c-addr u fileid -- ior ) 
    dup >r
    write-file
    ?dup if
        rdrop
    else
        line-terminator 1 r>
        write-file
    then          
    ;

cr
.( Finished ) cr
unused u. .(  bytes free) cr    

