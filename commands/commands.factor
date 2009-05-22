USING: arrays closures continuations darcs-ui io.encodings.utf8
io.launcher kernel regexp sequences fries xml xml.data xml.traversal ;
IN: darcs-ui.commands

: extract ( tag name -- string ) tag-named children>string ;

: prepare-patches ( changelog -- table-columns )
   string>xml "patch" tags-named
      [  [ "name" extract ]
         [ [ "author" attr ] [ "local_date" attr ] bi ]
         bi 3array
      ] map ;

: patches ( _ method search -- table-columns ) rot drop
   [ drop "" ] [ i" --_ \"_\"" ] if-empty
   i" darcs changes --xml-output _" run-desc prepare-patches ;

! this fails
: whatsnew ( -- matches ) "darcs whatsnew" run-desc R/ ^[^+-].*/m all-matching-subseqs ;

: with-patches ( quot desc -- ) utf8 rot with-process-writer ; inline

: pull ( quot -- ) "darcs pull" with-patches ; inline
: push ( quot -- ) "darcs push" with-patches ; inline
: send ( quot -- ) "darcs send" with-patches ; inline
: apply ( quot file -- ) i" darcs apply _" with-patches ; inline
: record ( quot name author -- ) i{ "darcs" "record" "--skip-long-comment" "-m" _ "--author" _ }
   with-patches ; inline

: cnts ( file patch -- result ) i" exact \"_\"" swap i{ "darcs" "show" "contents" "--match" _ _ }
   [ run-desc ] [ 2drop "File doesn't exist for selected patch" ] recover ;

: files ( -- str ) "darcs show files" run-desc ;