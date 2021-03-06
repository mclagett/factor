! Copyright (C) 2006, 2007 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: arrays assocs io kernel math models namespaces
prettyprint dlists sequences threads sequences words
debugger ui.gadgets ui.gadgets.worlds ui.gadgets.tracks
ui.gestures ui.backend ui.render continuations init combinators
hashtables concurrency.flags ;
IN: ui

! Assoc mapping aliens to gadgets
SYMBOL: windows

: window ( handle -- world ) windows get-global at ;

: window-focus ( handle -- gadget ) window world-focus ;

: register-window ( world handle -- )
    #! Add the new window just below the topmost window. Why?
    #! So that if the new window doesn't actually receive focus
    #! (eg, we're using focus follows mouse and the mouse is not
    #! in the new window when it appears) Factor doesn't get
    #! confused and send workspace operations to the new window,
    #! etc.
    swap 2array windows get-global push
    windows get-global dup length 1 >
    [ [ length 1- dup 1- ] keep exchange ] [ drop ] if ;

: unregister-window ( handle -- )
    windows global [ [ first = not ] with subset ] change-at ;

: raised-window ( world -- )
    windows get-global [ second eq? ] with find drop
    windows get-global [ length 1- ] keep exchange ;

: focus-gestures ( new old -- )
    drop-prefix <reversed>
    T{ lose-focus } swap each-gesture
    T{ gain-focus } swap each-gesture ;

: focus-world ( world -- )
    t over set-world-focused?
    dup raised-window
    focus-path f focus-gestures ;

: unfocus-world ( world -- )
    f over set-world-focused?
    focus-path f swap focus-gestures ;

M: world graft*
    dup (open-window)
    dup world-title over set-title
    request-focus ;

: reset-world ( world -- )
    #! This is used when a window is being closed, but also
    #! when restoring saved worlds on image startup.
    dup world-fonts clear-assoc
    dup unfocus-world
    f swap set-world-handle ;

M: world ungraft*
    dup free-fonts
    dup hand-clicked close-global
    dup hand-gadget close-global
    dup world-handle (close-window)
    reset-world ;

: find-window ( quot -- world )
    windows get values
    [ gadget-child swap call ] with find-last nip ; inline

SYMBOL: ui-hook

: init-ui ( -- )
    <dlist> \ graft-queue set-global
    <dlist> \ layout-queue set-global
    V{ } clone windows set-global ;

: restore-gadget-later ( gadget -- )
    dup gadget-graft-state {
        { { f f } [ ] }
        { { f t } [ ] }
        { { t t } [
            { f f } over set-gadget-graft-state
        ] }
        { { t f } [
            dup unqueue-graft
            { f f } over set-gadget-graft-state
        ] }
    } case graft-later ;

: restore-gadget ( gadget -- )
    dup restore-gadget-later
    gadget-children [ restore-gadget ] each ;

: restore-world ( world -- )
    dup reset-world restore-gadget ;

: restore-windows ( -- )
    windows get [ values ] keep delete-all
    [ restore-world ] each
    forget-rollover ;

: restore-windows? ( -- ? )
    windows get empty? not ;

: update-hand ( world -- )
    dup hand-world get-global eq?
    [ hand-loc get-global swap move-hand ] [ drop ] if ;

: layout-queued ( -- seq )
    [
        in-layout? on
        layout-queue [
            dup layout find-world [ , ] when*
        ] dlist-slurp
    ] { } make prune ;

: redraw-worlds ( seq -- )
    [ dup update-hand draw-world ] each ;

: notify ( gadget -- )
    dup gadget-graft-state
    dup first { f f } { t t } ?
    pick set-gadget-graft-state {
        { { f t } [ dup activate-control graft* ] }
        { { t f } [ dup deactivate-control ungraft* ] }
    } case ;

: notify-queued ( -- )
    graft-queue [ notify ] dlist-slurp ;

: update-ui ( -- )
    [ notify-queued layout-queued redraw-worlds ] assert-depth ;

: ui-wait ( -- )
    10 sleep ;

: ui-try ( quot -- ) [ ui-error ] recover ;

SYMBOL: ui-thread

: ui-running ( quot -- )
    t \ ui-running set-global
    [ f \ ui-running set-global ] [ ] cleanup ; inline

: ui-running? ( -- ? )
    \ ui-running get-global ;

: update-ui-loop ( -- )
    ui-running? ui-thread get-global self eq? and [
        ui-notify-flag get lower-flag
        [ update-ui ] ui-try
        update-ui-loop
    ] when ;

: start-ui-thread ( -- )
    [ self ui-thread set-global update-ui-loop ]
    "UI update" spawn drop ;

: open-world-window ( world -- )
    dup pref-dim over set-gadget-dim dup relayout graft ;

: open-window ( gadget title -- )
    >r [ 1 track, ] { 0 1 } make-track r>
    f <world> open-world-window ;

: set-fullscreen? ( ? gadget -- )
    find-world set-fullscreen* ;

: fullscreen? ( gadget -- ? )
    find-world fullscreen* ;

: raise-window ( gadget -- )
    find-world raise-window* ;

HOOK: close-window ui-backend ( gadget -- )

M: object close-window
    find-world [ ungraft ] when* ;

: start-ui ( -- )
    restore-windows? [
        restore-windows
    ] [
        init-ui ui-hook get call
    ] if
    notify-ui-thread start-ui-thread ;

[
    f \ ui-running set-global
    <flag> ui-notify-flag set-global
] "ui" add-init-hook

HOOK: ui ui-backend ( -- )

MAIN: ui

: with-ui ( quot -- )
    ui-running? [
        call
    ] [
        f windows set-global
        ui-hook [ ui ] with-variable
    ] if ;
