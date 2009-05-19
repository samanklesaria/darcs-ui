USING: arrays closures darcs-ui io.encodings.utf8 io.launcher
kernel make regexp sequences str-fry xml xml.data xml.traversal ;
IN: darcs-ui.commands

: extract ( tag name -- string ) tag-named children>string ;

: prepare-patches ( changelog -- table-columns )
   string>xml "patch" tags-named
      [  [ "name" extract ]
         [ [ "author" attr ] [ "local_date" attr ] bi ]
         bi 3array
      ] map { "working" "" "" } prefix ;

: patches ( _ method search -- table-columns ) rot drop
   [ drop "" ] [ I" --_ \"_\"" ] if-empty
   I" darcs changes --xml-output _" run-desc prepare-patches ;

: whatsnew ( -- matches ) "darcs whatsnew" run-desc R/ .+(\n[-+]    .*)*/ all-matching-subseqs ;

: with-patches ( quot desc -- ) utf8 rot with-process-writer ; inline

: pull ( quot -- ) "darcs pull" with-patches ; inline
: push ( quot -- ) "darcs push" with-patches ; inline
: send ( quot -- ) "darcs send" with-patches ; inline
: apply ( quot file -- ) I" darcs apply _" with-patches ; inline
: record ( quot name -- ) { "darcs" "record" "--skip-long-comment" "-m" }
   swap suffix with-patches ; inline

: cnts ( file patch -- result ) [ "darcs" , "show" , "contents" , "--match" , I" exact \"_\"" , , ] { } make run-desc ;

: files ( -- str ) "darcs show files" run-desc ;