! Copyright (c) 2008 Aaron Schaefer.
! See http://factorcode.org/license.txt for BSD license.
USING: combinators.lib kernel math.parser math.ranges project-euler.common
    sequences ;
IN: project-euler.036

! http://projecteuler.net/index.php?section=problems&id=36

! DESCRIPTION
! -----------

! The decimal number, 585 = 1001001001 (binary), is palindromic in both bases.

! Find the sum of all numbers, less than one million, which are palindromic in
! base 10 and base 2.

! (Please note that the palindromic number, in either base, may not include
! leading zeros.)


! SOLUTION
! --------

! Only check odd numbers since the binary number must begin and end with 1

<PRIVATE

: both-bases? ( n -- ? )
    { [ dup palindrome? ]
      [ dup >bin dup reverse = ] } && nip ;

PRIVATE>

: euler036 ( -- answer )
    1 1000000 2 <range> [ both-bases? ] subset sum ;

! [ euler036 ] 100 ave-time
! 3891 ms run / 173 ms GC ave time - 100 trials

MAIN: euler036
