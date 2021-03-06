
USING: kernel system namespaces sequences splitting combinators
       io io.files io.launcher prettyprint bootstrap.image
       bake combinators.cleave
       builder.util
       builder.common
       builder.release.branch
       builder.release.tidy
       builder.release.archive
       builder.release.upload ;

IN: builder.release

! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

: (release) ( -- )
  update-clean-branch
  tidy
  make-archive
  upload
  save-archive ;

: clean-build? ( -- ? )
  { "load-everything-vocabs" "test-all-vocabs" } [ eval-file empty? ] all? ;

: release ( -- ) clean-build? [ (release) ] when ;