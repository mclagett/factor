! Copyright (C) 2005, 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: arrays kernel parser sequences words help help.topics
namespaces vocabs definitions compiler.units ;
IN: help.syntax

: HELP:
    scan-word bootstrap-word
    dup set-word
    dup >link save-location
    \ ; parse-until >array swap set-word-help ; parsing

: ARTICLE:
    location >r
    \ ; parse-until >array [ first2 ] keep 2 tail <article>
    over add-article >link r> remember-definition ; parsing

: ABOUT:
    scan-object
    in get vocab
    dup changed-definition
    set-vocab-help ; parsing
