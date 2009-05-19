USING: accessors arrays cocoa.dialogs closures continuations
darcs-ui.commands file-trees fry io io.directories kernel
math models monads sequences splitting ui ui.gadgets.alerts
ui.frp ui.gadgets.buttons ui.gadgets.comboboxes
ui.gadgets.labels ui.gadgets.scrollers ui.baseline-alignment
unicode.case ;
IN: darcs-ui

: <patch-viewer> ( columns -- scroller ) <frp-table>
   [ first ] >>val-quot
   { "Patch" "Author" "Date" } >>column-titles
   <scroller> ;

: <change-list> ( {str} -- gadget ) <frp-list> t >>multiple-selection? indexed <scroller> ;

: answer ( length indices -- ) [ index [ "y" ] [ "n" ] if write ] curry each flush ;

: <patch-button> ( str quot -- button ) '[ drop
      [ whatsnew [ length <model> ] keep <model>
         [ <change-list> ->% 1 "okay" <frp-button> [ close-window ] >>hook
            -> <updates> [ [ answer ] 2curry @ ] <$2 ,
         ] <vbox> { 229 200 } >>pref-dim "select changes" open-window
      ] [ drop [ ] "No changes!" alert ] recover
   ] <border-button> ;

: toolbar ( -- merged )
   "record" f <model> [
      C[ [ <model> ] dip "Patch Name:" ask-user* [ record ] <$2 activate-model ] curry <patch-button> ,
   ] keep
   "push" C[ push ] <patch-button> ,
   "pull" C[ pull ] <patch-button> ,
   "send" C[ send ] <patch-button> ,
   "apply" C[ open-dir-panel first apply ] <patch-button> , t <model> swap <switch> ;

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
         C[ patches ] liftA3 <patch-viewer> ->% .5
         files "\n" split create-tree <model> <dir-table> <scroller> ->% .5
           [ file? ] <filter> [ comment>> ] fmap swap
      ] <hbox> ,% .5
      C[ cnts ] liftA2 "Select a patch and file to see its historical contents" <model>
         swap <switch> <label-control> <scroller> ,% .5
   ] <vbox> "darcs" open-window ;

: open-file ( -- ) [ open-dir-panel first [ darcs-window ] with-directory ] with-ui ;

MAIN: open-file