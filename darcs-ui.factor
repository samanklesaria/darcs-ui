USING: accessors arrays cocoa.dialogs closures file-trees
io.directories io.launcher kernel math models monads
models.mapped sequences splitting ui ui.frp ui.gadgets.buttons
ui.gadgets.comboboxes ui.gadgets.labels ui.gadgets.scrollers
unicode.case str-fry xml xml.data xml.traversal inspector ;
IN: darcs-ui

: extract ( tag name -- string ) tag-named children>string ;
: prepare-patch ( changelog -- table-columns )
   string>xml "patch" tags-named
      [  [ "name" extract ]
         [ [ "author" attr ] [ "local_date" attr ] bi ]
         bi 3array
      ] map { "working" "" "" } prefix ;

: <patch-viewer> ( columns -- scroller ) <frp-table>
   [ first ] >>val-quot
   { "Patch" "Author" "Date" } >>column-titles
   <scroller> ;

: with-patches ( str -- ) drop ;

: toolbar ( -- )
    "push" [ "darcs push" with-patches ] <border-button> ,
    "pull" [ "darcs pull" with-patches ] <border-button> ,
    "send" [ "darcs send" with-patches ] <border-button> ,
    "apply" [ open-dir-panel first "darcs apply " prepend with-patches ] <border-button> ,
    "record" [ "darcs push" with-patches ] <border-button> , ;

: darcs-window ( -- ) [
      [
          toolbar
          <spacer>
          { "MATCHES:" "PATCHES:"
            "FROM-TAG:" "FROM-PATCH:" "FROM-MATCH:"
            "TO-TAG:" "TO-MATCH:" "TO-PATCH:"
         } <combobox> -> [ but-last >lower ] fmap
         <frp-field> { 100 10 } >>pref-dim ->% 1
      ] <hbox> ,
      [
         C[ [ drop "" ] [ I"  --_ '_'" ] if-empty
           "darcs changes --xml-output" prepend run-desc prepare-patch ] <2mapped> <patch-viewer> ->% .5
        "darcs show files" run-desc "\n" split create-tree <model> <dir-table> <scroller> ->% .5
           [ file? ] <filter> [ comment>> ] fmap
      ] <vbox> ,% .5
     C[ 2dup and [ I" darcs show contents --match 'exact \"_\"' '_'" run-desc ]
         [ 2drop "Select a patch and file to see its historical contents" ] if ]
         <2mapped> <label-control> <scroller> ,% .5
   ] <vbox> "darcs" open-window ;

: open-file ( -- ) [ open-dir-panel first [ darcs-window ] with-directory ] with-ui ;

MAIN: open-file