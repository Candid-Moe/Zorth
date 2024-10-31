\
\	Forth
\

: bl #32 ;               \ ( -- 0x20 )
: char+ 1 + ;            \ ( c-addr1 -- c-addr2 ) 
: char bl word char+ c@ ; 
: [char] char literal ; immediate
: ( [char] ) parse drop drop ; immediate
: .( [char] ) parse type ; immediate
: chars ;                \ ( n1 -- n2 )

: cell+ 2 + ;
: cells 2 * ;            \ ( n1 -- n2 )
: compile, , ; immediate

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

$0 constant TEXT-COLOR-BLACK
$1 constant TEXT-COLOR-DARK-BLUE
$2 constant TEXT-COLOR-DARK-GREEN
$3 constant TEXT-COLOR-DARK-CYAN 
$4 constant TEXT-COLOR-DARK-RED  
$5 constant TEXT-COLOR-DARK-MAGENTA
$6 constant TEXT-COLOR-BROWN       
$7 constant TEXT-COLOR-LIGHT-GRAY  
$8 constant TEXT-COLOR-DARK-GRAY   
$9 constant TEXT-COLOR-BLUE        
$a constant TEXT-COLOR-GREEN       
$b constant TEXT-COLOR-CYAN        
$c constant TEXT-COLOR-RED         
$d constant TEXT-COLOR-MAGENTA     
$e constant TEXT-COLOR-YELLOW      
$f constant TEXT-COLOR-WHITE       

.( . ) 

: 1+    1 + ;
: 1-    1 - ;
: decimal #10 base ! ; 
: hex     #16 base ! ; 

( Comparations )
: <>    = invert ;
: 0=    0 = ;
: 0<>   0 <> ;
: 0<    0 < ;
: 0>    0 > ;

.( . )  
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

: ahead
    postpone jmp
    here >cs 0 ,
    ; immediate

: ." postpone s" postpone type ; immediate

: abort" ( "ccc<quote>" -- ) 
    postpone jz
    here >cs 0 ,
    postpone ."
    postpone abort
    here cs> !
    ; immediate

: check-compile-mode ( -- )
    state @ invert
    abort" Error. Not valid in interpreter mode. "
    ; 

: if 
    postpone jz 
    here >cs 0 ,
    ; immediate

: else postpone jmp 0 ,     \ jmp after the 'then' part
        here cs> !          \ patch the if
        here 2 - >cs        \ save the address for the patch
    ; immediate       

: then here cs> ! 
    ; immediate

.( . )  

: ?dup  dup 0<> if dup then ;
: +!    dup >r @ + r> ! ;
: abs   dup 0< if negate then ;
: max   2dup < if swap drop else drop then ;
: min   2dup < if drop else swap drop then ;
: . ( n -- ) 
    base @ #10 =
    if
        dup abs 0 <# #s rot sign #> 
    else
        s>d <# #s #>
    then
    type space
    ;

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
: buffer:   create allot ;
: variable  align here 0 , constant ;
: parse-name bl word count ;

: ] true    state ! ; immediate
: [ false   state ! ; immediate

.( . )

: u. s>d <# #s #> type ;
: unused $FFFF here - ;
: exit      0 , ; immediate
: recurse   dict @ , ; immediate
: roll                          \ x0 i*x u.i -- i*x x0 )
  dup if swap >r 1- recurse r> swap exit then  drop ;
: -rot  2 roll 2 roll ;         \ ( w1 w2 w3 – w3 w1 w2 ) gforth

.( . ) 

: >body 10 + ;
: ' bl word find 0= if ." Error. Word not found: " count type 0 then ; 
: ['] ( compilation: "name" --; run-time: -- xt ) 
    ' literal ; immediate
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

: forget ( "<spaces>name" -- ) 
    bl word find
    if     @ dict !
    else   ." Not found." cr
    then
    ; immediate
: marker dict @ create , does> @ dict ! ; 
: value constant ;
: to ' >body ! ; 
: is
   state @ if
     postpone ['] postpone defer!
   else
     ' defer!
   then ; immediate

: /string  DUP >R - SWAP R> CHARS + SWAP ;

.( . )

: then, ( orig -- ) postpone then ;

: ?do ( -- do-sys )
  postpone 2dup  postpone =
  postpone if    postpone 2drop
  postpone else
  postpone do  ['] then,
; immediate

: do ( -- do-sys )
  postpone do ['] noop
; immediate

: loop ( do-sys -- )
  >r postpone loop  r> execute
; immediate

: +loop ( do-sys -- )
  >r postpone +loop r> execute
; immediate

: .s ." < " depth . ." > " depth 0 ?do i pick . loop ;
: spaces ( n -- ) 0 ?do space loop ;
: .r   ( n1 n2 -- ) >r s>d <# #S #> dup r> swap - spaces type ;
: fill ( c-addr u char -- )  rot rot 0 ?do 2dup ! 1 + loop ; 
: erase ( c-addr u -- )    0 fill ;
: blank ( c-addr u -- )   bl fill ; 

.( . )

: begin here >cs ; immediate

: again postpone jmp cs> , ; immediate

: until postpone jz cs> , ; immediate

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
: resize ( a-addr1 u -- a-addr2 ior ) \ Not implemented
    drop false
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
    0 ?do space dup c@ 2hex 1 + loop drop ;

: clearstack ( n ... -- )           \   Delete all items in data stack
    begin 
        depth 
    while 
        drop 
    repeat ;

.( . )
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
    r> 0 ?do
        dup 4hex space          ( -- addr )
        dup @ dup 4hex space    ( -- addr xt )
        4 + @ count #16 min
        type cr
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
\ FAM constants. See zos-sys.asm

$000  constant r/o 
$100  constant w/o 
$200  constant r/w
$1000 constant o-create

16    constant FILENAME-LEN-MAX

0     constant SEEK-SET
1     constant SEEK-CUR
2     constant SEEK-END

300 same-page
256 buffer: in-buf
17  buffer: namez
variable line-terminator
$a line-terminator !

: bin ( fam1 -- fam2 ) ;

: flush-file ( fileid -- ior ) ;

.( . )

: file-seek ( ud seek fileid -- ud-offset ior )
    8 lshift 6 + swap            ( -- ud file-op seek )
    >r rot rot r> 
    z80-syscall
    3 roll drop
    ;    

: file-size ( fileid -- ud ior )
    8 lshift 4 + in-buf 0 0
    z80-syscall
    >r drop drop drop
    in-buf @ 
    in-buf 2 + @
    r>
    ;

: file-status ( c-addr u -- x ior )
    namez asciiz 5 swap         
    in-buf swap 0
    z80-syscall
    nip nip nip
    ;

: file-position ( fileid -- ud ior ) 
    >r 0 0 SEEK-CUR r>
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

.( . )

: create-file ( c-addr u fam -- fileid ior )
    o-create or
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
    SEEK-SET swap 
    file-seek
    nip nip
    ;
    
: read-line ( c-addr u1 fileid -- u3 flag ior )
    2>r dup 2r> dup >r  ( -- c-addr c-addr u1 fileid : R -- fileid)
    read-file           ( -- c-addr u2 ior )
    if ." read failed" rdrop drop 0 0 -1 exit then
    ?dup 0= if rdrop 0 0 -1 exit then

    swap over           ( -- u2 c-addr u2 )
    0x0a scan nip       ( -- u2 u3 )
    ?dup if                    
        dup >r - 1+ r>         ( -- u2-u3 u3 )
        1- negate s>d       ( -- u2-u3 ud )
        SEEK-CUR r> file-seek 2drop drop ( -- u2-u3 )
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

.( . )

: include-file
    ( i * x fileid -- j * x ) 

    255 allocate        ( -- fileid a-addr ior )
    ?dup if
        ." Error getting buffer " 2hex 2drop cr
        exit
    then

    swap >r                  ( a-addr fileid -- a-addr : R -- fileid )
    begin
        dup 253 r@ read-line ( -- a-addr u flag ior )
        ?dup if
            2drop drop
            1                   ( -- a-addr 1 )
        else
            if                  ( a-addr u flag -- a-addr u )
                over >r
\                2dup type
                evaluate        ( -- )
                r>              ( -- a-addr )
                0                   
            else
                drop 
                1    
            then
        then
    until        
    free drop 
    r> close-file drop
    ;

: included 
    ( i * x c-addr u -- j * x )
    r/o open-file
    ?dup if 
        ." Error opening file " 2hex drop cr
    else
        include-file
    then
    ;

: include ( i*x "name" -- j*x ) 
    parse-name included  
    ; 

cr
.( Finished ) cr

unused u. .(  bytes free) cr    


