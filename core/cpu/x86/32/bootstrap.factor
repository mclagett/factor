! Copyright (C) 2007 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: bootstrap.image.private kernel namespaces system
cpu.x86.assembler layouts vocabs parser ;
IN: bootstrap.x86

4 \ cell set

: arg0 EAX ;
: arg1 EDX ;
: temp-reg EBX ;
: stack-reg ESP ;
: ds-reg ESI ;
: fixnum>slot@ arg0 1 SAR ;
: rex-length 0 ;

<< "resource:core/cpu/x86/bootstrap.factor" parse-file parsed >>
call
