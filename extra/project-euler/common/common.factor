USING: arrays kernel math math.functions math.miller-rabin math.matrices
    math.parser math.primes.factors math.ranges namespaces sequences
    sequences.lib sorting unicode.case ;
IN: project-euler.common

! A collection of words used by more than one Project Euler solution
! and/or related words that could be useful for future problems.

! Problems using each public word
! -------------------------------
! alpha-value - #22, #42
! cartesian-product - #4, #27, #29, #32, #33, #43, #44, #56
! collect-consecutive - #8, #11
! log10 - #25, #134
! max-path - #18, #67
! nth-triangle - #12, #42
! number>digits - #16, #20, #30, #34, #35, #38, #43, #52, #55, #56
! palindrome? - #4, #36, #55
! pandigital? - #32, #38
! pentagonal? - #44, #45
! propagate-all - #18, #67
! sum-proper-divisors - #21
! tau* - #12
! [uad]-transform - #39, #75


: nth-pair ( n seq -- nth next )
    over 1+ over nth >r nth r> ;

: perfect-square? ( n -- ? )
    dup sqrt mod zero? ;

<PRIVATE

: count-shifts ( seq width -- n )
    >r length 1+ r> - ;

: max-children ( seq -- seq )
    [ dup length 1- [ over nth-pair max , ] each ] { } make nip ;

! Propagate one row into the upper one
: propagate ( bottom top -- newtop )
    [ over 1 tail rot first2 max rot + ] map nip ;

: shift-3rd ( seq obj obj -- seq obj obj )
    rot 1 tail -rot ;

: (sum-divisors) ( n -- sum )
    dup sqrt >fixnum [1,b] [
        [ 2dup mod zero? [ 2dup / + , ] [ drop ] if ] each
        dup perfect-square? [ sqrt >fixnum neg , ] [ drop ] if
    ] { } make sum ;

: transform ( triple matrix -- new-triple )
    [ 1array ] dip m. first ;

PRIVATE>

: alpha-value ( str -- n )
    >lower [ CHAR: a - 1+ ] sigma ;

: cartesian-product ( seq1 seq2 -- seq1xseq2 )
    swap [ swap [ 2array ] map-with ] map-with concat ;

: collect-consecutive ( seq width -- seq )
    [
        2dup count-shifts [ 2dup head shift-3rd , ] times
    ] { } make 2nip ;

: log10 ( m -- n )
    log 10 log / ;

: max-path ( triangle -- n )
    dup length 1 > [
        2 cut* first2 max-children [ + ] 2map suffix max-path
    ] [
        first first
    ] if ;

: number>digits ( n -- seq )
    [ dup zero? not ] [ 10 /mod ] [ ] unfold reverse nip ;

: nth-triangle ( n -- n )
    dup 1+ * 2 / ;

: palindrome? ( n -- ? )
    number>string dup reverse = ;

: pandigital? ( n -- ? )
    number>string natural-sort "123456789" = ;

: pentagonal? ( n -- ? )
    dup 0 > [ 24 * 1+ sqrt 1+ 6 / 1 mod zero? ] [ drop f ] if ;

! Not strictly needed, but it is nice to be able to dump the triangle after the
! propagation
: propagate-all ( triangle -- newtriangle )
    reverse [ first dup ] keep 1 tail [ propagate dup ] map nip reverse swap suffix ;

: sum-divisors ( n -- sum )
    dup 4 < [ { 0 1 3 4 } nth ] [ (sum-divisors) ] if ;

: sum-proper-divisors ( n -- sum )
    dup sum-divisors swap - ;

: abundant? ( n -- ? )
    dup sum-proper-divisors < ;

: deficient? ( n -- ? )
    dup sum-proper-divisors > ;

: perfect? ( n -- ? )
    dup sum-proper-divisors = ;

! The divisor function, counts the number of divisors
: tau ( m -- n )
    group-factors flip second 1 [ 1+ * ] reduce ;

! Optimized brute-force, is often faster than prime factorization
: tau* ( m -- n )
    factor-2s [ 1+ ] dip [ perfect-square? -1 0 ? ] keep
    dup sqrt >fixnum [1,b] [
        dupd mod zero? [ [ 2 + ] dip ] when
    ] each drop * ;

! These transforms are for generating primitive Pythagorean triples
: u-transform ( triple -- new-triple )
    { { 1 2 2 } { -2 -1 -2 } { 2 2 3 } } transform ;
: a-transform ( triple -- new-triple )
    { { 1 2 2 } { 2 1 2 } { 2 2 3 } } transform ;
: d-transform ( triple -- new-triple )
    { { -1 -2 -2 } { 2 1 2 } { 2 2 3 } } transform ;

