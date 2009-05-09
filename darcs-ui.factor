USING: accessors arrays cocoa.dialogs closures darcs-ui.commands
file-trees io.directories kernel math models monads
models.mapped sequences splitting ui ui.frp ui.gadgets.buttons
ui.gadgets.comboboxes ui.gadgets.labels ui.gadgets.scrollers
ui.baseline-alignment unicode.case xml xml.data xml.traversal
namespaces ;
IN: darcs-ui

: extract ( tag name -- string ) tag-named children>string ;
: prepare-patches ( changelog -- table-columns )
   string>xml "patch" tags-named
      [  [ "name" extract ]
         [ [ "author" attr ] [ "local_date" attr ] bi ]
         bi 3array
      ] map { "working" "" "" } prefix ;

: <patch-viewer> ( columns -- scroller ) <frp-table>
   [ first ] >>val-quot
   { "Patch" "Author" "Date" } >>column-titles
   <scroller> ;

: toolbar ( -- )
    "push" [ push ] <border-button> ,
    "pull" [ pull ] <border-button> ,
    "send" [ send ] <border-button> ,
    "apply" [ open-dir-panel first apply ] <border-button> ,
    "record" [ record ] <border-button> , ;

: darcs-window ( -- ) [
      [
          toolbar
          <spacer>
          { "PATCHES:" "MATCHES:"
            "FROM-TAG:" "FROM-PATCH:" "FROM-MATCH:"
            "TO-TAG:" "TO-MATCH:" "TO-PATCH:"
         } <combobox> -> [ but-last >lower ] fmap
         <frp-field> { 100 10 } >>pref-dim ->% 1
      ] <hbox> +baseline+ >>align ,
      [
         C[ patches prepare-patches ] <2mapped> <patch-viewer> ->% .5
         files "\n" split create-tree <model> <dir-table> <scroller> ->% .5
           [ file? ] <filter> [ comment>> ] fmap swap
      ] <hbox> ,% .5
     C[ 2dup and [ contents ] [ 2drop "Select a patch and file to see its historical contents" ] if ]
         <2mapped> <label-control> <scroller> ,% .5
   ] <vbox> "darcs" open-window ;

: open-file ( -- ) [ open-dir-panel first [ darcs-window ] with-directory ] with-ui ;

MAIN: open-file