USING: closures darcs-ui io.launcher kernel make sequences str-fry ;
IN: darcs-ui.commands

: patches ( method search -- str )
   [ drop "" ] [ I" --_ \"_\"" ] if-empty
   I" darcs changes --xml-output _" run-desc ;

: with-patches ( str -- ) drop ;

: pull ( -- ) "darcs pull" with-patches ;
: push ( -- ) "darcs push" with-patches ;
: send ( -- ) "darcs send" with-patches ;
: apply ( file -- ) I" darcs apply _" with-patches ;
: record ( -- ) "darcs record" with-patches ;

: contents ( file patch -- result ) [ "darcs" , "show" , "contents" , "--match" , I" exact \"_\"" , , ] { } make run-desc ;

: files ( -- str ) "darcs show files" run-desc ;