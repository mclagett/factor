USING: help.markup help.syntax io kernel math quotations
multiline ;
IN: windows.com

HELP: com-query-interface
{ $values { "interface" "Pointer to a COM interface implementing " { $snippet "IUnknown" } } { "iid" "An interface GUID (IID)" } { "interface'" "Pointer to a COM interface implementing the interface indicated by " { $snippet "iid" } } }
{ $description "A small wrapper around " { $link IUnknown::QueryInterface } ". Queries " { $snippet "interface" } " to see if it implements the interface indicated by " { $snippet "iid" } ". Returns a pointer to the " { $snippet "iid" } " interface if implemented, or raises an error if the object does not implement the interface.\n\nCOM memory management conventions state that the returned pointer must be immediately retained using " { $link com-add-ref } ". The pointer must then be released using " { $link com-release } " when it is no longer needed." } ;

HELP: com-add-ref
{ $values { "interface" "Pointer to a COM interface implementing " { $snippet "IUnknown" } } }
{ $description "A small wrapper around " { $link IUnknown::AddRef } ". Increments the reference count on " { $snippet "interface" } ", keeping it on the stack. The reference count must be decremented with " { $link com-release } " when the reference is no longer held." } ;

HELP: com-release
{ $values { "interface" "Pointer to a COM interface implementing " { $snippet "IUnknown" } } }
{ $description "A small wrapper around " { $link IUnknown::Release } ". Decrements the reference count on " { $snippet "interface" } ", releasing the underlying object if the reference count has reached zero." } ;
