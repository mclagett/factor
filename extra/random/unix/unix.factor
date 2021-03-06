USING: alien.c-types io io.files io.nonblocking kernel
namespaces random io.encodings.binary init
accessors system ;
IN: random.unix

TUPLE: unix-random path ;

C: <unix-random> unix-random

: file-read-unbuffered ( n path -- bytes )
    over default-buffer-size [
        binary <file-reader> [ read ] with-stream
    ] with-variable ;

M: unix-random random-bytes* ( n tuple -- byte-array )
    path>> file-read-unbuffered ;

os openbsd? [
    [
        "/dev/srandom" <unix-random> secure-random-generator set-global
        "/dev/prandom" <unix-random> insecure-random-generator set-global
    ] "random.unix" add-init-hook
] [
    [
        "/dev/random" <unix-random> secure-random-generator set-global
        "/dev/urandom" <unix-random> insecure-random-generator set-global
    ] "random.unix" add-init-hook
] if
