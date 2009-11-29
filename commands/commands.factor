USING: accessors arrays continuations io.encodings.utf8
io.launcher io.files kernel regexp sequences fries
ui.gadgets.alerts fry run-desc regexp.private ;
IN: darcs-ui.commands

: remove-entities ( str -- str' )
    { { R/ &lt/ "<" }
    { R/ &quot/ "\"" }
    { R/ &amp/ "&" }
    { R/ &gt/ ">" }
    { R/ &apos/ "'" } } swap
    [ first2 re-replace ] reduce ;

: prepare-patches ( changelog -- table-columns )
    R" </patch>" [ subseq ] (re-split) but-last-slice [
        [ R/ <name>[^<]+</ first-match 6 tail-slice but-last ]
        [ R/ author='[^']+/ first-match 8 tail ]
        [ R/ local_date='[^']+/ first-match 12 tail ] tri
        [ remove-entities ] tri@ 3array
    ] map ;
: (patches) ( str -- table-columns )  i" darcs changes --xml-output _"
   [ run-desc prepare-patches ] [ 2drop "Error showing patches" alert* f ] recover ;
: patches ( method search -- table-columns )
   [ drop "" (patches) { "working" "" "" } prefix ] [ i" --_ \"_\"" (patches) ] if-empty ;

: whatsnew ( -- matches ) "darcs whatsnew" run-desc R/ ^[^+-].*/m all-matching-slices ;

: pull ( repo -- ) i" darcs pull --mark-conflicts -a _" [ try-process ]
   [ nip code>> 1 = [ "Conflicts marked- fix them and re-record" alert* ] [ "Can't connect" alert* ] if ] recover ; inline
: repo-push ( repo -- ) i{ "darcs" "push" "-a" _ } [ try-process ] [ 2drop "Push refused" alert* ] recover ; inline
: send ( repo -- ) i{ "darcs" "send" "-a" _ } [ try-process ] [ 2drop "Sending failed" alert* ] recover ; inline
: app ( file -- ) i{ "darcs" "apply" "-a" _ } [ try-process ] [ 2drop "Applying failed" alert* ] recover ; inline
: record ( quot name author -- ) i{ "darcs" "record" "--skip-long-comment" "-m" _ "--author" _ }
   utf8 rot with-process-writer ; inline

: cnts ( file patch -- result ) dup "working" = [ drop utf8 file-contents ]
   [ i" exact \"_\"" swap i{ "darcs" "show" "contents" "--match" _ _ }
      [ run-desc ] [ 2drop "FILE DOESN'T EXIST FOR SELECTED PATCH" ] recover ] if ;
: files ( -- str ) "darcs show files" [ run-desc ] [ drop "Error showing files" alert* ] recover ;

: diff ( file patch1 patch2 -- result ) over "working" =
   [ nip i{ "darcs" "diff" "-p" _ } ]
   [ i{ "darcs" "diff" "--from-patch" _ "--to-patch" _ } ] if
   swap dup t = [ drop ] [ suffix ] if [ run-desc ] [ 2drop "DIFF FAILED" ] recover ;

: init-repo ( -- ) "darcs init" try-process ;
: add-repo-file ( files -- ) { "darcs" "add" "-r" } prepend
   [ try-process ] [ 2drop "File couldn't be added to repository" alert* ] recover ;
: remove-repo-file ( files -- ) { "darcs" "remove" } prepend
   [ try-process ] [ 2drop "File doesn't exist in repository" alert* ] recover ;
: repo-get ( filename -- ) i" darcs get _" [ try-process ] [ 2drop "Error connecting" alert* ] recover ;