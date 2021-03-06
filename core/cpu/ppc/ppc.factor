USING: cpu.ppc.architecture cpu.ppc.intrinsics cpu.architecture
namespaces alien.c-types kernel system combinators ;

{
    { [ os macosx? ] [
        4 "longlong" c-type set-c-type-align
        4 "ulonglong" c-type set-c-type-align
        4 "double" c-type set-c-type-align
    ] }
    { [ os linux? ] [
        t "longlong" c-type set-c-type-stack-align?
        t "ulonglong" c-type set-c-type-stack-align?
    ] }
} cond
