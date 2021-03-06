! Copyright (C) 2006, 2007 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel namespaces opengl opengl.gl ;
IN: ui.backend

SYMBOL: ui-backend

HOOK: set-title ui-backend ( string world -- )

HOOK: set-fullscreen* ui-backend ( ? world -- )

HOOK: fullscreen* ui-backend ( world -- ? )

HOOK: (open-window) ui-backend ( world -- )

HOOK: (close-window) ui-backend ( handle -- )

HOOK: raise-window* ui-backend ( world -- )

HOOK: select-gl-context ui-backend ( handle -- )

HOOK: flush-gl-context ui-backend ( handle -- )

: with-gl-context ( handle quot -- )
    swap [ select-gl-context call ] keep
    glFlush flush-gl-context gl-error ; inline
