USING: ui.gadgets ui.gadgets.editors listener io help.syntax
help.markup ;
IN: ui.tools.interactor

HELP: interactor
{ $class-description "An interactor is an " { $link editor } " intended to be used as the input component of a " { $link "ui-listener" } "."
$nl
"Interactors are created by calling " { $link <interactor> } "."
$nl
"Interactors implement the " { $link stream-readln } ", " { $link stream-read } " and " { $link read-quot } " generic words." } ;
