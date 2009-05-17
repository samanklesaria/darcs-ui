USING: accessors arrays cocoa.dialogs closures darcs-ui.commands
file-trees io io.directories kernel math models monads
models.mapped sequences splitting ui ui.frp ui.gadgets.buttons
ui.gadgets.comboboxes ui.gadgets.labels ui.gadgets.scrollers
ui.baseline-alignment unicode.case ;
IN: darcs-ui

: <patch-viewer> ( columns -- scroller ) <frp-table>
   [ first ] >>val-quot
   { "Patch" "Author" "Date" } >>column-titles
   <scroller> ;

: <change-list> ( {str} -- gadget ) <frp-list> t >>multiple-selection? indexed <scroller> ;

: answer ( length indices -- ) [ index [ "y\n" ] [ "n\n" ] if write flush ] curry each ;
: <patch-button> ( str quot -- button ) \ drop [
      whatsnew [ length <model> ] keep <model>
      [
         <change-list> ->% 1 "okay" <frp-button> -> <updates> [ answer ] <2mapped> ,
      ] <vbox> { 229 200 } >>pref-dim "select changes" open-window
   ] rot 2curry <border-button> ;

: toolbar ( -- )
   "record" C[ <model> "Patch Name:" ask [ record ] <2mapped> ] <patch-button> ,
   "push" C[ push ] <patch-button> ,
   "pull" C[ pull ] <patch-button> ,
   "send" C[ send ] <patch-button> ,
   "apply" C[ open-dir-panel first apply ] <patch-button> , ;

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
         C[ patches ] <2mapped> <patch-viewer> ->% .5
         files "\n" split create-tree <model> <dir-table> <scroller> ->% .5
           [ file? ] <filter> [ comment>> ] fmap swap
      ] <hbox> ,% .5
      C[ cnts ] <2mapped> "Select a patch and file to see its historical contents" <model>
         swap <switch> <label-control> <scroller> ,% .5
   ] <vbox> "darcs" open-window ;

: open-file ( -- ) [ open-dir-panel first [ darcs-window ] with-directory ] with-ui ;

MAIN: open-file