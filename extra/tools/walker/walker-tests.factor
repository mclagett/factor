USING: tools.walker io io.streams.string kernel math
math.private namespaces prettyprint sequences tools.test
continuations math.parser threads arrays tools.walker.debug ;
IN: tools.walker.tests

[ { } ] [
    [ ] test-walker
] unit-test

[ { 1 } ] [
    [ 1 ] test-walker
] unit-test

[ { 1 2 3 } ] [
    [ 1 2 3 ] test-walker
] unit-test

[ { "Yo" 2 } ] [
    [ 2 >r "Yo" r> ] test-walker
] unit-test

[ { 2 } ] [
    [ t [ 2 ] [ "hi" ] if ] test-walker
] unit-test

[ { "hi" } ] [
    [ f [ 2 ] [ "hi" ] if ] test-walker
] unit-test

[ { 4 } ] [
    [ 2 2 fixnum+ ] test-walker
] unit-test

: foo 2 2 fixnum+ ;

[ { 8 } ] [
    [ foo 4 fixnum+ ] test-walker
] unit-test

[ { C{ 1 1.5 } { } C{ 1 1.5 } { } } ] [
    [ C{ 1 1.5 } { } 2dup ] test-walker
] unit-test

[ { t } ] [
    [ 5 5 number= ] test-walker
] unit-test

[ { f } ] [
    [ 5 6 number= ] test-walker
] unit-test

[ { f } ] [
    [ "XYZ" "XYZ" mismatch ] test-walker
] unit-test

[ { t } ] [
    [ "XYZ" "XYZ" sequence= ] test-walker
] unit-test

[ { t } ] [
    [ "XYZ" "XYZ" = ] test-walker
] unit-test

[ { f } ] [
    [ "XYZ" "XuZ" = ] test-walker
] unit-test

[ { 4 } ] [
    [ 2 2 + ] test-walker
] unit-test

[ { 3 } ] [
    [ [ 3 "x" set "x" get ] with-scope ] test-walker
] unit-test

[ { "hi\n" } ] [
    [ [ "hi" print ] with-string-writer ] test-walker
] unit-test

[ { "4\n" } ] [
    [ [ 2 2 + number>string print ] with-string-writer ] test-walker
] unit-test
                                                            
[ { 1 2 3 } ] [
    [ { 1 2 3 } set-datastack ] test-walker
] unit-test

[ { 6 } ]
[ [ 3 [ nip continue ] callcc0 2 * ] test-walker ] unit-test

[ { 6 } ]
[ [ [ 3 swap continue-with ] callcc1 2 * ] test-walker ] unit-test

[ { } ]
[ [ [ ] [ ] recover ] test-walker ] unit-test

[ { 6 } ]
[ [ [ 3 throw ] [ 2 * ] recover ] test-walker ] unit-test

[ { } ] [
    [ "a" "b" set "c" "d" set [ ] test-walker ] with-scope
] unit-test
