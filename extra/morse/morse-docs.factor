! Copyright (C) 2007 Alex Chapman
! See http://factorcode.org/license.txt for BSD license.
USING: help.markup help.syntax ;
IN: morse

HELP: ch>morse
{ $values
    { "ch" "A character that has a morse code translation" } { "str" "A string consisting of zero or more dots and dashes" } }
{ $description "If the given character has a morse code translation, then return that translation, otherwise return an empty string." } ;

HELP: morse>ch
{ $values
    { "str" "A string of dots and dashes that represents a single character in morse code" } { "ch" "The translated character" } }
{ $description "If the given string represents a morse code character, then return that character, otherwise return f" } ;

HELP: >morse
{ $values
    { "str" "A string of ASCII characters which can be translated into morse code" } { "str" "A string in morse code" } }
{ $description "Translates ASCII text into morse code, represented by a series of dots, dashes, and slashes." }
{ $see-also morse> ch>morse } ;

HELP: morse>
{ $values { "str" "A string of morse code, in which the character '.' represents dots, '-' dashes, ' ' spaces between letters, and ' / ' spaces between words." } { "str" "The ASCII translation of the given string" } }
{ $description "Translates morse code into ASCII text" }
{ $see-also >morse morse>ch } ;
