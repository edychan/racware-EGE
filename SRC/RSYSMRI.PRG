f_clrscn ("Recover Indexes/Databases")
setcolor (gbluecolor)
@ 01, 01 say "All users MUST log off the system at this time !"
ywhich = .f.
@ 02, 01 say "Do you want to continue? [Y/N] " get ywhich picture "Y"
f_rd ()
if .not. ywhich
   return
endif
ywhich = "I"
@ 02, 01 say "Rebuild Indexes or Databases? [I/D] " get ywhich picture "!" ;
   valid f_valid (ywhich $ "ID")
if f_rd () = 27
   return
endif
do while .t.
   ydb = space (8)
   @ 05, 01 clear to 23, 79
   @ 03, 01 say "Enter database name or ALL " get ydb ;
      picture "!!!!!!!!" valid f_valid (ydb = "ALL     " .or. ;
      f_verify ("dbsetup", 1, ydb))
   if f_rd () = 27
      exit
   endif
   f_use ("dbsetup")
   use

   yall = (ydb = "ALL     ")
   f_use ("rapath")
   go top
   @ 05, 10 say "Database       Description           Status"
   @ 06, 08 say "컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�"
   yline = 7
   do while .not. eof ()
      if yall
         if fname = "RAPATH"
            skip
            loop
         else
            ydb = fname
         endif
      else
         locate for fname = ydb
      endif
      set exclusive on
      @ yline, 10 say fname
      @ yline, 25 say falias
      if f_use (trim (ydb))
         if ywhich = "D"
            @ yline, 47 say "Packing"
            set index to
            set delete off
            copy to (gstnpath + trim (ydb)) for .not. deleted ()
            set delete on
            zap
            use
            f_use (trim (ydb))
            reindex
            append from (gstnpath + trim (ydb))
            erase (gstnpath + trim (ydb)+ ".dbf")
            @ yline, 47 say "Packed "
         else
            @ yline, 47 say "Reindexing"
            reindex
            @ yline, 47 say "Reindexed "
         endif
         use
      else
         @ yline, 50 say "Open Error"
      endif
      set exclusive off
      if yall
         select rapath
         skip
         if yline < 23
            yline = yline + 1
         else
            scroll (7, 0, 23, 79, 1)
         endif
      else
         exit
      endif
   enddo
   if ywhich = "D"
      f_popup ("Rebuilding Databases Completed... Press ENTER...", .t.)
   else
      f_popup ("Rebuilding Indexes Completed... Press ENTER...", .t.)
   endif
enddo

close database
