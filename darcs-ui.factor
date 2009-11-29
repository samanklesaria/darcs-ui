USING: accessors arrays ascii closures cocoa.dialogs
colors.constants continuations darcs-ui.commands enter
file-trees io io.directories io.encodings.utf8 io.files
io.pathnames kernel models models.combinators models.filter
models.merge monads sequences splitting ui
ui.baseline-alignment ui.gadgets.alerts ui.gadgets.comboboxes
ui.gadgets.editors ui.gadgets.labels ui.gadgets.layout
ui.gadgets.model-buttons ui.gadgets.scrollers ui.gadgets.tables
ui.pens.solid ;
IN: darcs-ui

: <patch-viewer> ( columns -- scroller ) <quot-renderer>
   [ first ] >>val-quot
   { "Patch" "Author" "Date" } >>column-titles
   <table> t >>multiple-selection? <scroller> ;

: <change-list> ( {str} -- selection ) list-renderer <table> t >>multiple-selection?
    [ <scroller> ,% 1 ] [ selection-index>> ] bi ;

: answer ( length indices -- ) [ index [ "y" ] [ "n" ] if write ] curry each flush ;

: patches-quot ( -- model-of-quot )
   [ whatsnew [ length <model> ] keep <model>
      [ <change-list> "okay" <model-button> -> dup [ close-window ] $> ,
         updates [ [ answer ] 2curry ] smart fmap
      ] <vbox> { 229 200 } >>pref-dim "select changes" open-window
   ] [ drop "No changes!" alert* f <model> ] recover ;

: load-pref ( name file -- model ) "_darcs/prefs/" prepend dup exists?
   [ utf8 [ readln ] with-file-reader <model> nip ]
   [ [ ask-user ] dip DIR[ utf8 set-file-contents ] curry $> ] if ;

: toolbar ( -- file-updates patch-updates )
   IMG-MODEL-BUTTON: add -> DIR[ drop open-dir-panel [ add-repo-file ] when* ] $>
   IMG-MODEL-BUTTON: rem -> DIR[ drop open-panel [ remove-repo-file ] when* ] $>
      2merge t >>value
   IMG-MODEL-BUTTON: rec -> DIR[ patches-quot ] bind* dup [ drop "Patch Name:" ask-user ] bind dup
      DIR[ "Your Name:" "author" load-pref ] bind* DIR[ record ] 3 in $>
   IMG-MODEL-BUTTON: push -> DIR[ "Push To:" "defaultrepo" load-pref ] bind* DIR[ repo-push ] $> ,
   IMG-MODEL-BUTTON: pull -> DIR[ "Pull From:" "defaultrepo" load-pref ] bind* DIR[ pull ] $>
   IMG-MODEL-BUTTON: send -> DIR[ "Send To:" "defaultrepo" load-pref ] bind* DIR[ send ] $> ,
   IMG-MODEL-BUTTON: app -> DIR[ open-dir-panel [ first app ] when* ] $> 3array merge t >>value ;

: darcs-window ( -- ) [
      [
          toolbar <spacer>
          { "PATCHES:" "MATCHES:"
            "FROM-TAG:" "FROM-PATCH:" "FROM-MATCH:"
            "TO-TAG:" "TO-MATCH:" "TO-PATCH:"
         } <combobox> -> [ but-last >lower ] fmap
         <model-field*> { 100 10 } >>pref-dim ->% 1
      ] <hbox> +baseline+ >>align COLOR: black <solid> >>interior ,
      [
         DIR[ rot drop patches ] 3 in fmap <patch-viewer> ->% .5 [ [ f ] when-empty ] fmap
         [ DIR[ drop files "\n" split create-tree ] fmap <dir-table> <scroller> ->% .5
           [ file? ] filter-model [ comment>> ] fmap
         ] dip
      ] <hbox> ,% .5 [
         [ length 1 = ] filter-model DIR[ first cnts ] 2 in fmap
         "Select a patch and file to see its historical contents" <model> switch-models
      ] [ [ length 2 = ] filter-model DIR[ first2 swap diff ] 2 in fmap ] 2bi
      2merge <label-control> <scroller> ,% .5
   ] <vbox> "darcs" open-window ;

DEFER: open-repo
: create-repo ( -- ) "The selected folder is not a darcs repo.  Would you like to create one?" { "get remote" "init local" "find another repo" } ask-buttons
   [ [ "Repo Name:" ask-user ] bind* DIR[ dup repo-get file-name [ darcs-window ] with-directory ] $> ]
   [ DIR[ drop [ init-repo darcs-window ] [ drop "Can't write to folder" alert* ] recover ] $> ]
   [ [ drop open-repo ] $> ] tri* [ activate-model ] tri@ ;

: open-repo ( -- ) open-dir-panel [ first [ "_darcs" exists? [ darcs-window ] [ create-repo ] if ] with-directory ] unless-empty ;

ENTER: [ open-repo ] with-ui ;