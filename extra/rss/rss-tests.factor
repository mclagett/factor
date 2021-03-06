USING: rss io kernel io.files tools.test io.encodings.utf8 ;
IN: rss.tests

: load-news-file ( filename -- feed )
    #! Load an news syndication file and process it, returning
    #! it as an feed tuple.
    utf8 <file-reader> read-feed ;

[ T{
    feed
    f
    "Meerkat"
    "http://meerkat.oreillynet.com"
    {
        T{
            entry
            f
            "XML: A Disruptive Technology"
            "http://c.moreover.com/click/here.pl?r123"
            "\n      XML is placing increasingly heavy loads on the existing technical\n      infrastructure of the Internet.\n    "
            f
        }
    }
} ] [ "extra/rss/rss1.xml" resource-path load-news-file ] unit-test
[ T{
    feed
    f
    "dive into mark"
    "http://example.org/"
    {
        T{
            entry
            f
            "Atom draft-07 snapshot"
            "http://example.org/2005/04/02/atom"
            "\n         <div xmlns=\"http://www.w3.org/1999/xhtml\">\n           <p><i>[Update: The Atom draft is finished.]</i></p>\n         </div>\n       "

            "2003-12-13T08:29:29-04:00"
        }
    }
} ] [ "extra/rss/atom.xml" resource-path load-news-file ] unit-test
