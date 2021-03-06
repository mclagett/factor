USING: kernel layouts math namespaces sequences sequences.private ;
IN: math.ranges

TUPLE: range from length step ;

: <range> ( a b step -- range )
    >r over - r>
    [ / 1+ 0 max >integer ] keep
    range construct-boa ;

M: range length ( seq -- n )
    range-length ;

M: range nth-unsafe ( n range -- obj )
    [ range-step * ] keep range-from + ;

INSTANCE: range immutable-sequence

: twiddle 2dup > -1 1 ? ; inline

: (a, dup roll + -rot ; inline

: ,b) dup neg rot + swap ; inline

: [a,b] ( a b -- range ) twiddle <range> ;

: (a,b] ( a b -- range ) twiddle (a, <range> ;

: [a,b) ( a b -- range ) twiddle ,b) <range> ;

: (a,b) ( a b -- range ) twiddle (a, ,b) <range> ;

: [0,b] ( b -- range ) 0 swap [a,b] ;

: [1,b] ( b -- range ) 1 swap [a,b] ;

: [0,b) ( b -- range ) 0 swap [a,b) ;

: range-increasing? ( range -- ? )
    range-step 0 > ;

: range-decreasing? ( range -- ? )
    range-step 0 < ;

: first-or-peek ( seq head? -- elt )
    [ first ] [ peek ] if ;

: range-min ( range -- min )
    dup range-increasing? first-or-peek ;

: range-max ( range -- max )
    dup range-decreasing? first-or-peek ;

: clamp-to-range ( n range -- n )
    tuck range-min max swap range-max min ;

: sequence-index-range  ( seq -- range )
    length [0,b) ;
