USING: kernel vocabs vocabs.loader sequences system ;

{ "ui" "help" "tools" }
[ "bootstrap." swap append vocab ] all? [
    "ui.tools" require

    "ui.cocoa" vocab [
        "ui.cocoa.tools" require
    ] when
] when

macosx? [ "ui.tools.deploy" require ] when