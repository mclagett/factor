! Copyright (C) 2005, 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: alien alien.accessors alien.c-types arrays cpu.ppc.assembler
cpu.ppc.architecture cpu.ppc.allot cpu.architecture kernel
kernel.private math math.private namespaces sequences words
generic quotations byte-arrays hashtables hashtables.private
generator generator.registers generator.fixup sequences.private
sbufs vectors system layouts math.floats.private
classes classes.tuple classes.tuple.private sbufs.private
vectors.private strings.private slots.private combinators
bit-arrays float-arrays compiler.constants ;
IN: cpu.ppc.intrinsics

: %slot-literal-known-tag
    "val" operand
    "obj" operand
    "n" get cells
    "obj" get operand-tag - ;

: %slot-literal-any-tag
    "obj" operand "scratch" operand %untag
    "val" operand "scratch" operand "n" get cells ;

: %slot-any
    "obj" operand "scratch" operand %untag
    "offset" operand "n" operand 1 SRAWI
    "scratch" operand "val" operand "offset" operand ;

\ slot {
    ! Slot number is literal and the tag is known
    {
        [ %slot-literal-known-tag LWZ ] H{
            { +input+ { { f "obj" known-tag } { [ small-slot? ] "n" } } }
            { +scratch+ { { f "val" } } }
            { +output+ { "val" } }
        }
    }
    ! Slot number is literal
    {
        [ %slot-literal-any-tag LWZ ] H{
            { +input+ { { f "obj" } { [ small-slot? ] "n" } } }
            { +scratch+ { { f "scratch" } { f "val" } } }
            { +output+ { "val" } }
        }
    }
    ! Slot number in a register
    {
        [ %slot-any LWZX ] H{
            { +input+ { { f "obj" } { f "n" } } }
            { +scratch+ { { f "val" } { f "scratch" } { f "offset" } } }
            { +output+ { "val" } }
        }
    }
} define-intrinsics

: load-cards-offset ( dest -- )
    "cards_offset" f pick %load-dlsym  dup 0 LWZ ;

: %write-barrier ( -- )
    "val" get operand-immediate? "obj" get fresh-object? or [
        "obj" operand "scratch" operand card-bits SRWI
        "val" operand load-cards-offset
        "scratch" operand dup "val" operand ADD
        "val" operand "scratch" operand 0 LBZ
        "val" operand dup card-mark ORI
        "val" operand "scratch" operand 0 STB
    ] unless ;

\ set-slot {
    ! Slot number is literal and tag is known
    {
        [ %slot-literal-known-tag STW %write-barrier ] H{
            { +input+ { { f "val" } { f "obj" known-tag } { [ small-slot? ] "n" } } }
            { +scratch+ { { f "scratch" } } }
            { +clobber+ { "val" } }
        }
    }
    ! Slot number is literal
    {
        [ %slot-literal-any-tag STW %write-barrier ] H{
            { +input+ { { f "val" } { f "obj" } { [ small-slot? ] "n" } } }
            { +scratch+ { { f "scratch" } } }
            { +clobber+ { "val" } }
        }
    }
    ! Slot number is in a register
    {
        [ %slot-any STWX %write-barrier ] H{
            { +input+ { { f "val" } { f "obj" } { f "n" } } }
            { +scratch+ { { f "scratch" } { f "offset" } } }
            { +clobber+ { "val" } }
        }
    }
} define-intrinsics

: fixnum-register-op ( op -- pair )
    [ "out" operand "y" operand "x" operand ] swap suffix H{
        { +input+ { { f "x" } { f "y" } } }
        { +scratch+ { { f "out" } } }
        { +output+ { "out" } }
    } 2array ;

: fixnum-value-op ( op -- pair )
    [ "out" operand "x" operand "y" operand ] swap suffix H{
        { +input+ { { f "x" } { [ small-tagged? ] "y" } } }
        { +scratch+ { { f "out" } } }
        { +output+ { "out" } }
    } 2array ;

: define-fixnum-op ( word imm-op reg-op -- )
    >r fixnum-value-op r> fixnum-register-op 2array
    define-intrinsics ;

{
    { fixnum+fast ADDI ADD }
    { fixnum-fast SUBI SUBF }
    { fixnum-bitand ANDI AND }
    { fixnum-bitor ORI OR }
    { fixnum-bitxor XORI XOR }
} [
    first3 define-fixnum-op
] each

\ fixnum*fast {
    {
        [
            "out" operand "x" operand "y" get MULLI
        ] H{
            { +input+ { { f "x" } { [ small-tagged? ] "y" } } }
            { +scratch+ { { f "out" } } }
            { +output+ { "out" } }
        }
    } {
        [
            "out" operand "x" operand %untag-fixnum
            "out" operand "y" operand "out" operand MULLW
        ] H{
            { +input+ { { f "x" } { f "y" } } }
            { +scratch+ { { f "out" } } }
            { +output+ { "out" } }
        }
    }
} define-intrinsics

: %untag-fixnums ( seq -- )
    [ dup %untag-fixnum ] unique-operands ;

\ fixnum-shift-fast {
    {
        [
            "out" operand "x" operand "y" get
            dup 0 < [ neg SRAWI ] [ swapd SLWI ] if
            ! Mask off low bits
            "out" operand dup %untag
        ] H{
            { +input+ { { f "x" } { [ ] "y" } } }
            { +scratch+ { { f "out" } } }
            { +output+ { "out" } }
        }
    }
    {
        [
            { "positive" "end" } [ define-label ] each
            "out" operand "y" operand %untag-fixnum
            0 "y" operand 0 CMPI
            "positive" get BGE
            "out" operand dup NEG
            "out" operand "x" operand "out" operand SRAW
            "end" get B
            "positive" resolve-label
            "out" operand "x" operand "out" operand SLW
            "end" resolve-label
            ! Mask off low bits
            "out" operand dup %untag
        ] H{
            { +input+ { { f "x" } { f "y" } } }
            { +scratch+ { { f "out" } } }
            { +output+ { "out" } }
        }
    }
} define-intrinsics

: generate-fixnum-mod
    #! PowerPC doesn't have a MOD instruction; so we compute
    #! x-(x/y)*y. Puts the result in "s" operand.
    "s" operand "r" operand "y" operand MULLW
    "s" operand "s" operand "x" operand SUBF ;

\ fixnum-mod [
    ! divide x by y, store result in x
    "r" operand "x" operand "y" operand DIVW
    generate-fixnum-mod
] H{
    { +input+ { { f "x" } { f "y" } } }
    { +scratch+ { { f "r" } { f "s" } } }
    { +output+ { "s" } }
} define-intrinsic

\ fixnum-bitnot [
    "x" operand dup NOT
    "x" operand dup %untag
] H{
    { +input+ { { f "x" } } }
    { +output+ { "x" } }
} define-intrinsic

: fixnum-register-jump ( op -- pair )
    [ "x" operand 0 "y" operand CMP ] swap suffix
    { { f "x" } { f "y" } } 2array ;

: fixnum-value-jump ( op -- pair )
    [ 0 "x" operand "y" operand CMPI ] swap suffix
    { { f "x" } { [ small-tagged? ] "y" } } 2array ;

: define-fixnum-jump ( word op -- )
    [ fixnum-value-jump ] keep fixnum-register-jump
    2array define-if-intrinsics ;

{
    { fixnum< BLT }
    { fixnum<= BLE }
    { fixnum> BGT }
    { fixnum>= BGE }
    { eq? BEQ }
} [
    first2 define-fixnum-jump
] each

: overflow-check ( insn1 insn2 -- )
    [
        >r 0 0 LI
        0 MTXER
        "r" operand "y" operand "x" operand r> execute
        >r
        "end" define-label
        "end" get BNO
        { "x" "y" } %untag-fixnums
        "r" operand "y" operand "x" operand r> execute
        "r" get %allot-bignum-signed-1
        "end" resolve-label
    ] with-scope ; inline

: overflow-template ( word insn1 insn2 -- )
    [ overflow-check ] 2curry H{
        { +input+ { { f "x" } { f "y" } } }
        { +scratch+ { { f "r" } } }
        { +output+ { "r" } }
        { +clobber+ { "x" "y" } }
    } define-intrinsic ;

\ fixnum+ \ ADD \ ADDO. overflow-template
\ fixnum- \ SUBF \ SUBFO. overflow-template

: generate-fixnum/i
    #! This VOP is funny. If there is an overflow, it falls
    #! through to the end, and the result is in "x" operand.
    #! Otherwise it jumps to the "no-overflow" label and the
    #! result is in "r" operand.
    "end" define-label
    "no-overflow" define-label
    "r" operand "x" operand "y" operand DIVW
    ! if the result is greater than the most positive fixnum,
    ! which can only ever happen if we do
    ! most-negative-fixnum -1 /i, then the result is a bignum.
    most-positive-fixnum "s" operand LOAD
    "r" operand 0 "s" operand CMP
    "no-overflow" get BLE
    most-negative-fixnum neg "x" operand LOAD
    "x" get %allot-bignum-signed-1 ;

\ fixnum/i [
    generate-fixnum/i
    "end" get B
    "no-overflow" resolve-label
    "r" operand "x" operand %tag-fixnum
    "end" resolve-label
] H{
    { +input+ { { f "x" } { f "y" } } }
    { +scratch+ { { f "r" } { f "s" } } }
    { +output+ { "x" } }
    { +clobber+ { "y" } }
} define-intrinsic

\ fixnum/mod [
    generate-fixnum/i
    0 "s" operand LI
    "end" get B
    "no-overflow" resolve-label
    generate-fixnum-mod
    "r" operand "x" operand %tag-fixnum
    "end" resolve-label
] H{
    { +input+ { { f "x" } { f "y" } } }
    { +scratch+ { { f "r" } { f "s" } } }
    { +output+ { "x" "s" } }
    { +clobber+ { "y" } }
} define-intrinsic

\ fixnum>bignum [
    "x" operand dup %untag-fixnum
    "x" get %allot-bignum-signed-1
] H{
    { +input+ { { f "x" } } }
    { +output+ { "x" } }
} define-intrinsic

\ bignum>fixnum [
    "nonzero" define-label
    "positive" define-label
    "end" define-label
    "x" operand dup %untag
    "y" operand "x" operand cell LWZ
     ! if the length is 1, its just the sign and nothing else,
     ! so output 0
    0 "y" operand 1 v>operand CMPI
    "nonzero" get BNE
    0 "y" operand LI
    "end" get B
    "nonzero" resolve-label
    ! load the value
    "y" operand "x" operand 3 cells LWZ
    ! load the sign
    "x" operand "x" operand 2 cells LWZ
    ! is the sign negative?
    0 "x" operand 0 CMPI
    "positive" get BEQ
    "y" operand dup -1 MULI
    "positive" resolve-label
    "y" operand dup %tag-fixnum
    "end" resolve-label
] H{
    { +input+ { { f "x" } } }
    { +scratch+ { { f "y" } } }
    { +clobber+ { "x" } }
    { +output+ { "y" } }
} define-intrinsic

: define-float-op ( word op -- )
    [ "z" operand "x" operand "y" operand ] swap suffix H{
        { +input+ { { float "x" } { float "y" } } }
        { +scratch+ { { float "z" } } }
        { +output+ { "z" } }
    } define-intrinsic ;

{
    { float+ FADD }
    { float- FSUB }
    { float* FMUL }
    { float/f FDIV }
} [
    first2 define-float-op
] each

: define-float-jump ( word op -- )
    [ "x" operand 0 "y" operand FCMPU ] swap suffix
    { { float "x" } { float "y" } } define-if-intrinsic ;

{
    { float< BLT }
    { float<= BLE }
    { float> BGT }
    { float>= BGE }
    { float= BEQ }
} [
    first2 define-float-jump
] each

\ float>fixnum [
    "scratch" operand "in" operand FCTIWZ
    "scratch" operand 1 0 param@ STFD
    "out" operand 1 cell param@ LWZ
    "out" operand dup %tag-fixnum
] H{
    { +input+ { { float "in" } } }
    { +scratch+ { { float "scratch" } { f "out" } } }
    { +output+ { "out" } }
} define-intrinsic

\ fixnum>float [
    HEX: 4330 "scratch" operand LIS
    "scratch" operand 1 0 param@ STW
    "scratch" operand "in" operand %untag-fixnum
    "scratch" operand dup HEX: 8000 XORIS
    "scratch" operand 1 cell param@ STW
    "f1" operand 1 0 param@ LFD
    4503601774854144.0 "scratch" operand load-indirect
    "f2" operand "scratch" operand float-offset LFD
    "f1" operand "f1" operand "f2" operand FSUB
] H{
    { +input+ { { f "in" } } }
    { +scratch+ { { f "scratch" } { float "f1" } { float "f2" } } }
    { +output+ { "f1" } }
} define-intrinsic


\ tag [
    "out" operand "in" operand tag-mask get ANDI
    "out" operand dup %tag-fixnum
] H{
    { +input+ { { f "in" } } }
    { +scratch+ { { f "out" } } }
    { +output+ { "out" } }
} define-intrinsic

: userenv ( reg -- )
    #! Load the userenv pointer in a register.
    "userenv" f rot %load-dlsym ;

\ getenv [
    "n" operand dup 1 SRAWI
    "x" operand userenv
    "x" operand "n" operand "x" operand ADD
    "x" operand dup 0 LWZ
] H{
    { +input+ { { f "n" } } }
    { +scratch+ { { f "x" } } }
    { +output+ { "x" } }
    { +clobber+ { "n" } }
} define-intrinsic

\ setenv [
    "n" operand dup 1 SRAWI
    "x" operand userenv
    "x" operand "n" operand "x" operand ADD
    "val" operand "x" operand 0 STW
] H{
    { +input+ { { f "val" } { f "n" } } }
    { +scratch+ { { f "x" } } }
    { +clobber+ { "n" } }
} define-intrinsic

\ <tuple> [
    tuple "layout" get layout-size 2 + cells %allot
    ! Store layout
    "layout" get 12 load-indirect
    12 11 cell STW
    ! Zero out the rest of the tuple
    f v>operand 12 LI
    "layout" get layout-size [ 12 11 rot 2 + cells STW ] each
    ! Store tagged ptr in reg
    "tuple" get tuple %store-tagged
] H{
    { +input+ { { [ tuple-layout? ] "layout" } } }
    { +scratch+ { { f "tuple" } } }
    { +output+ { "tuple" } }
} define-intrinsic

\ <array> [
    array "n" get 2 + cells %allot
    ! Store length
    "n" operand 12 LI
    12 11 cell STW
    ! Store initial element
    "n" get [ "initial" operand 11 rot 2 + cells STW ] each
    ! Store tagged ptr in reg
    "array" get object %store-tagged
] H{
    { +input+ { { [ inline-array? ] "n" } { f "initial" } } }
    { +scratch+ { { f "array" } } }
    { +output+ { "array" } }
} define-intrinsic

\ <byte-array> [
    byte-array "n" get 2 cells + %allot
    ! Store length
    "n" operand 12 LI
    12 11 cell STW
    ! Store initial element
    0 12 LI
    "n" get cell align cell /i [ 12 11 rot 2 + cells STW ] each
    ! Store tagged ptr in reg
    "array" get object %store-tagged
] H{
    { +input+ { { [ inline-array? ] "n" } } }
    { +scratch+ { { f "array" } } }
    { +output+ { "array" } }
} define-intrinsic

\ <ratio> [
    ratio 3 cells %allot
    "numerator" operand 11 1 cells STW
    "denominator" operand 11 2 cells STW
    ! Store tagged ptr in reg
    "ratio" get ratio %store-tagged
] H{
    { +input+ { { f "numerator" } { f "denominator" } } }
    { +scratch+ { { f "ratio" } } }
    { +output+ { "ratio" } }
} define-intrinsic

\ <complex> [
    complex 3 cells %allot
    "real" operand 11 1 cells STW
    "imaginary" operand 11 2 cells STW
    ! Store tagged ptr in reg
    "complex" get complex %store-tagged
] H{
    { +input+ { { f "real" } { f "imaginary" } } }
    { +scratch+ { { f "complex" } } }
    { +output+ { "complex" } }
} define-intrinsic

\ <wrapper> [
    wrapper 2 cells %allot
    "obj" operand 11 1 cells STW
    ! Store tagged ptr in reg
    "wrapper" get object %store-tagged
] H{
    { +input+ { { f "obj" } } }
    { +scratch+ { { f "wrapper" } } }
    { +output+ { "wrapper" } }
} define-intrinsic

! Alien intrinsics
: %alien-accessor ( quot -- )
    "offset" operand dup %untag-fixnum
    "offset" operand dup "alien" operand ADD
    "value" operand "offset" operand 0 roll call ; inline

: alien-integer-get-template
    H{
        { +input+ {
            { unboxed-c-ptr "alien" c-ptr }
            { f "offset" fixnum }
        } }
        { +scratch+ { { f "value" } } }
        { +output+ { "value" } }
        { +clobber+ { "offset" } }
    } ;

: %alien-integer-get ( quot -- )
    %alien-accessor
    "value" operand dup %tag-fixnum ; inline

: alien-integer-set-template
    H{
        { +input+ {
            { f "value" fixnum }
            { unboxed-c-ptr "alien" c-ptr }
            { f "offset" fixnum }
        } }
        { +clobber+ { "value" "offset" } }
    } ;

: %alien-integer-set ( quot -- )
    "offset" get "value" get = [
        "value" operand dup %untag-fixnum
    ] unless
    %alien-accessor ; inline

: define-alien-integer-intrinsics ( word get-quot word set-quot -- )
    [ %alien-integer-set ] curry
    alien-integer-set-template
    define-intrinsic
    [ %alien-integer-get ] curry
    alien-integer-get-template
    define-intrinsic ;

\ alien-unsigned-1 [ LBZ ]
\ set-alien-unsigned-1 [ STB ]
define-alien-integer-intrinsics

\ alien-signed-1 [ pick >r LBZ r> dup EXTSB ]
\ set-alien-signed-1 [ STB ]
define-alien-integer-intrinsics

\ alien-unsigned-2 [ LHZ ]
\ set-alien-unsigned-2 [ STH ]
define-alien-integer-intrinsics

\ alien-signed-2 [ LHA ]
\ set-alien-signed-2 [ STH ]
define-alien-integer-intrinsics

\ alien-cell [
    [ LWZ ] %alien-accessor
] H{
    { +input+ {
        { unboxed-c-ptr "alien" c-ptr }
        { f "offset" fixnum }
    } }
    { +scratch+ { { unboxed-alien "value" } } }
    { +output+ { "value" } }
    { +clobber+ { "offset" } }
} define-intrinsic

\ set-alien-cell [
    [ STW ] %alien-accessor
] H{
    { +input+ {
        { unboxed-c-ptr "value" pinned-c-ptr }
        { unboxed-c-ptr "alien" c-ptr }
        { f "offset" fixnum }
    } }
    { +clobber+ { "offset" } }
} define-intrinsic

: alien-float-get-template
    H{
        { +input+ {
            { unboxed-c-ptr "alien" c-ptr }
            { f "offset" fixnum }
        } }
        { +scratch+ { { float "value" } } }
        { +output+ { "value" } }
        { +clobber+ { "offset" } }
    } ;

: alien-float-set-template
    H{
        { +input+ {
            { float "value" float }
            { unboxed-c-ptr "alien" c-ptr }
            { f "offset" fixnum }
        } }
        { +clobber+ { "offset" } }
    } ;

: define-alien-float-intrinsics ( word get-quot word set-quot -- )
    [ %alien-accessor ] curry
    alien-float-set-template
    define-intrinsic
    [ %alien-accessor ] curry
    alien-float-get-template
    define-intrinsic ;

\ alien-double [ LFD ]
\ set-alien-double [ STFD ]
define-alien-float-intrinsics

\ alien-float [ LFS ]
\ set-alien-float [ STFS ]
define-alien-float-intrinsics
