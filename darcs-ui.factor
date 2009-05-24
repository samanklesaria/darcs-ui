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
         -> <updates> [ [ answer ] 2curry ] 2fmap-&
      ] <vbox> { 229 200 } >>pref-dim "select changes" open-window
   ] [ drop [ ] "No changes!" alert f <model> ] recover ;

: <patch-button> ( str -- model ) <frp-button> -> [ drop patches-quot ] bind ;

: load-pref ( name file -- model ) "_darcs/prefs/" prepend dup exists?
   [ utf8 file-contents <model> nip ]
   [ '[ dup _ utf8 set-file-contents ] swap ask-user swap fmap ] if ;

! Must update after all have refreshed, not after one has refreshed
! Make all, any
: toolbar ( -- merged )
   "add" <frp-button> -> [ drop open-dir-panel add ] $>
   "record" <patch-button> dup [ drop "Patch Name:" ask-user ] bind dup
      C[ drop "Your Name:" "author" load-pref ] bind C[ record ] 3$>-&
   "push" <patch-button> dup [ "Push To:" "defaultrepo" load-pref ] bind* C[ push ] 2$>-& ,
   "pull" <patch-button> dup [ "Pull From:" "defaultrepo" load-pref ] bind* C[ pull ] 2$>-&
   "send" <patch-button> dup [ "Send To:" "defaultrepo" load-pref ] bind* C[ send ] 2$>-& ,
   "apply" <patch-button> C[ open-dir-panel first apply ] $> 4array <merge> t <model> swap <switch> ;

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
         C[ patches ] 3fmap-| <patch-viewer> ->% .5
         files "\n" split create-tree <model> <dir-table> <scroller> ->% .5
           [ file? ] <filter> [ comment>> ] fmap swap
      ] <hbox> ,% .5
      C[ cnts ] 2fmap-| "Select a patch and file to see its historical contents" <model>
         swap <switch> <label-control> <scroller> ,% .5
   ] <vbox> "darcs" open-window ;

DEFER: open-file
: create-repo ( -- ) "The selected folder is not a darcs repo.  Would you like to create one?" { "yes" "no" } ask-buttons
   [ [ drop init-repo darcs-window ] $> activate-model ] [ [ drop open-file ] $> activate-model ] bi* ;

: open-file ( -- ) [ open-dir-panel
      [ first [ "_darcs" exists? [ darcs-window ] [ create-repo ] if ] with-directory ] unless-empty
   ] with-ui ;

MAIN: open-file