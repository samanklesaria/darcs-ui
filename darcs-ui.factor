USING: accessors arrays cocoa.dialogs closures continuations
darcs-ui.commands fry file-trees io io.files io.directories
io.encodings.utf8 kernel math models monads sequences
splitting ui ui.gadgets.alerts ui.frp ui.gadgets.comboboxes
ui.gadgets.labels ui.gadgets.scrollers ui.baseline-alignment
unicode.case ;
IN: darcs-ui

: <patch-viewer> ( columns -- scroller ) <frp-table>
   [ first ] >>val-quot
   { "Patch" "Author" "Date" } >>column-titles
   <scroller> ;

: <change-list> ( {str} -- gadget ) <frp-list> t >>multiple-selection? indexed <scroller> ;

: answer ( length indices -- ) [ index [ "y" ] [ "n" ] if write ] curry each flush ;

: patches-quot ( -- model-of-quot )
   [ whatsnew [ length <model> ] keep <model>
      [ <change-list> ->% 1 "okay" <frp-button> [ close-window ] >>hook
         -> <updates> [ [ answer ] 2curry ] liftA2
      ] <vbox> { 229 200 } >>pref-dim "select changes" open-window
   ] [ drop [ ] "No changes!" alert f <model> ] recover ;

: <patch-button> ( str -- model ) <frp-button> -> [ drop patches-quot ] bind ;

: load-pref ( name file -- model ) "_darcs/prefs/" prepend dup exists?
   [ utf8 file-contents <model> nip ]
   [ '[ dup _ utf8 set-file-contents ] swap ask-user swap fmap ] if ;

: toolbar ( -- merged )
   "record" <patch-button> dup [ drop "Patch Name:" ask-user ] bind dup
      C[ drop "Your Name:" "author" load-pref ] bind C[ record ] $>3
   "push" <patch-button> C[ push ] $> ,
   "pull" <patch-button> C[ pull ] $>
   "send" <patch-button> C[ send ] $> ,
   "apply" <patch-button> C[ open-dir-panel first apply ] $> 3array <merge> t <model> swap <switch> ;

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

DEFER: open-file
: create-repo ( -- ) "The selected folder is not a darcs repo.  Would you like to create one?" { "yes" "no" } ask-buttons
   [ [ drop init-repo darcs-window ] $> activate-model ] [ [ drop open-file ] $> activate-model ] bi* ;

: open-file ( -- ) [ open-dir-panel
      [ first [ "_darcs" exists? [ darcs-window ] [ create-repo ] if ] with-directory ] unless-empty
   ] with-ui ;

MAIN: open-file