USING: continuations crypto.xor kernel strings tools.test ;
IN: crypto.xor.tests

! No key
[ ""        dup  xor-crypt           ] [ T{ no-xor-key f } = ] must-fail-with
[ { }       dup  xor-crypt           ] [ T{ no-xor-key f } = ] must-fail-with
[ V{ }      dup  xor-crypt           ] [ T{ no-xor-key f } = ] must-fail-with
[ "" "asdf" dupd xor-crypt xor-crypt ] [ T{ no-xor-key f } = ] must-fail-with

! a xor a = 0
[ "\0\0\0\0\0\0\0" ] [ "abcdefg" dup xor-crypt ] unit-test

[ { 15 15 15 15 } ] [ { 10 10 10 10 } { 5 5 5 5 } xor-crypt ] unit-test

[ "asdf" ] [ "key" "asdf" dupd xor-crypt xor-crypt >string ] unit-test
[ "" ] [ "key" "" xor-crypt >string ] unit-test
[ "a longer message...!" ] [
    "."
    "a longer message...!" dupd xor-crypt xor-crypt >string
] unit-test
[ "a longer message...!" ] [
    "a very long key, longer than the message even."
    "a longer message...!" dupd xor-crypt xor-crypt >string
] unit-test
