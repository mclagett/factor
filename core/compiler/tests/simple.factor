USING: compiler.units tools.test kernel kernel.private
sequences.private math.private math combinators strings
alien arrays memory ;
IN: compiler.tests

! Test empty word
[ ] [ [ ] compile-call ] unit-test

! Test literals
[ 1 ] [ [ 1 ] compile-call ] unit-test
[ 31 ] [ [ 31 ] compile-call ] unit-test
[ 255 ] [ [ 255 ] compile-call ] unit-test
[ -1 ] [ [ -1 ] compile-call ] unit-test
[ 65536 ] [ [ 65536 ] compile-call ] unit-test
[ -65536 ] [ [ -65536 ] compile-call ] unit-test
[ "hey" ] [ [ "hey" ] compile-call ] unit-test

! Calls
: no-op ;

[ ] [ [ no-op ] compile-call ] unit-test
[ 3 ] [ [ no-op 3 ] compile-call ] unit-test
[ 3 ] [ [ 3 no-op ] compile-call ] unit-test

: bar 4 ;

[ 4 ] [ [ bar no-op ] compile-call ] unit-test
[ 4 3 ] [ [ no-op bar 3 ] compile-call ] unit-test
[ 3 4 ] [ [ 3 no-op bar ] compile-call ] unit-test

[ ] [ no-op ] unit-test

! Conditionals

[ 1 ] [ t [ [ 1 ] [ 2 ] if ] compile-call ] unit-test
[ 2 ] [ f [ [ 1 ] [ 2 ] if ] compile-call ] unit-test
[ 1 3 ] [ t [ [ 1 ] [ 2 ] if 3 ] compile-call ] unit-test
[ 2 3 ] [ f [ [ 1 ] [ 2 ] if 3 ] compile-call ] unit-test

[ "hi" ] [ 0 [ { [ "hi" ] [ "bye" ] } dispatch ] compile-call ] unit-test
[ "bye" ] [ 1 [ { [ "hi" ] [ "bye" ] } dispatch ] compile-call ] unit-test

[ "hi" 3 ] [ 0 [ { [ "hi" ] [ "bye" ] } dispatch 3 ] compile-call ] unit-test
[ "bye" 3 ] [ 1 [ { [ "hi" ] [ "bye" ] } dispatch 3 ] compile-call ] unit-test

[ 4 1 ] [ 0 [ { [ bar 1 ] [ 3 1 ] } dispatch ] compile-call ] unit-test
[ 3 1 ] [ 1 [ { [ bar 1 ] [ 3 1 ] } dispatch ] compile-call ] unit-test
[ 4 1 3 ] [ 0 [ { [ bar 1 ] [ 3 1 ] } dispatch 3 ] compile-call ] unit-test
[ 3 1 3 ] [ 1 [ { [ bar 1 ] [ 3 1 ] } dispatch 3 ] compile-call ] unit-test

[ 2 3 ] [ 1 [ { [ gc 1 ] [ gc 2 ] } dispatch 3 ] compile-call ] unit-test

! Labels

: recursive ( ? -- ) [ f recursive ] when ; inline

[ ] [ t [ recursive ] compile-call ] unit-test

[ ] [ t recursive ] unit-test

! Make sure error reporting works

[ [ dup ] compile-call ] must-fail
[ [ drop ] compile-call ] must-fail

! Regression

[ ] [ [ callstack ] compile-call drop ] unit-test

! Regression

: empty ;

[ "b" ] [ 1 [ empty { [ "a" ] [ "b" ] } dispatch ] compile-call ] unit-test

: dummy-if-1 t [ ] [ ] if ;

[ ] [ dummy-if-1 ] unit-test

: dummy-if-2 f [ ] [ ] if ;

[ ] [ dummy-if-2 ] unit-test

: dummy-if-3 t [ 1 ] [ 2 ] if ;

[ 1 ] [ dummy-if-3 ] unit-test

: dummy-if-4 f [ 1 ] [ 2 ] if ;

[ 2 ] [ dummy-if-4 ] unit-test

: dummy-if-5 0 dup 1 fixnum<= [ drop 1 ] [ ] if ;

[ 1 ] [ dummy-if-5 ] unit-test

: dummy-if-6
    dup 1 fixnum<= [
        drop 1
    ] [
        1 fixnum- dup 1 fixnum- fixnum+
    ] if ;

[ 17 ] [ 10 dummy-if-6 ] unit-test

: dead-code-rec
    t [
        3.2
    ] [
        dead-code-rec
    ] if ;

[ 3.2 ] [ dead-code-rec ] unit-test

: one-rec [ f one-rec ] [ "hi" ] if ;

[ "hi" ] [ t one-rec ] unit-test

: after-if-test
    t [ ] [ ] if 5 ;

[ 5 ] [ after-if-test ] unit-test

DEFER: countdown-b

: countdown-a ( n -- ) dup 0 eq? [ drop ] [ 1 fixnum- countdown-b ] if ;
: countdown-b ( n -- ) dup 0 eq? [ drop ] [ 1 fixnum- countdown-a ] if ;

[ ] [ 10 countdown-b ] unit-test

: dummy-when-1 t [ ] when ;

[ ] [ dummy-when-1 ] unit-test

: dummy-when-2 f [ ] when ;

[ ] [ dummy-when-2 ] unit-test

: dummy-when-3 dup [ dup fixnum* ] when ;

[ 16 ] [ 4 dummy-when-3 ] unit-test
[ f ] [ f dummy-when-3 ] unit-test

: dummy-when-4 dup [ dup dup fixnum* fixnum* ] when swap ;

[ 64 f ] [ f 4 dummy-when-4 ] unit-test
[ f t ] [ t f dummy-when-4 ] unit-test

: dummy-when-5 f [ dup fixnum* ] when ;

[ f ] [ f dummy-when-5 ] unit-test

: dummy-unless-1 t [ ] unless ;

[ ] [ dummy-unless-1 ] unit-test

: dummy-unless-2 f [ ] unless ;

[ ] [ dummy-unless-2 ] unit-test

: dummy-unless-3 dup [ drop 3 ] unless ;

[ 3 ] [ f dummy-unless-3 ] unit-test
[ 4 ] [ 4 dummy-unless-3 ] unit-test

! Test cond expansion
[ "even" ] [
    [
        2 {
            { [ dup 2 mod 0 = ] [ drop "even" ] }
            { [ dup 2 mod 1 = ] [ drop "odd" ] }
        } cond
    ] compile-call
] unit-test

[ "odd" ] [
    [
        3 {
            { [ dup 2 mod 0 = ] [ drop "even" ] }
            { [ dup 2 mod 1 = ] [ drop "odd" ] }
        } cond
    ] compile-call
] unit-test

[ "neither" ] [
    [
        3 {
            { [ dup string? ] [ drop "string" ] }
            { [ dup float? ] [ drop "float" ] }
            { [ dup alien? ] [ drop "alien" ] }
            [ drop "neither" ]
        } cond
    ] compile-call
] unit-test

[ 3 ] [
    [
        3 {
            { [ dup fixnum? ] [ ] }
            [ drop t ]
        } cond
    ] compile-call
] unit-test

GENERIC: single-combination-test

M: object single-combination-test drop ;
M: f single-combination-test nip ;
M: array single-combination-test drop ;
M: integer single-combination-test drop ;

[ 2 3 ] [ 2 3 t single-combination-test ] unit-test
[ 2 3 ] [ 2 3 4 single-combination-test ] unit-test
[ 2 f ] [ 2 3 f single-combination-test ] unit-test

DEFER: single-combination-test-2

: single-combination-test-4
    dup [ single-combination-test-2 ] when ;

: single-combination-test-3
    drop 3 ;

GENERIC: single-combination-test-2
M: object single-combination-test-2 single-combination-test-3 ;
M: f single-combination-test-2 single-combination-test-4 ;

[ 3 ] [ t single-combination-test-2 ] unit-test
[ 3 ] [ 3 single-combination-test-2 ] unit-test
[ f ] [ f single-combination-test-2 ] unit-test

! Regression
[ 100 ] [ [ 100 [ [ ] times ] keep ] compile-call ] unit-test
