set delete on
declare idxary [10], ntxary [10]
f_clrscn ("Database Maintenance")
setcolor (gbluecolor)
@ 01, 01 say "All users MUST log off the system at this time !"
yret = .f.
@ 02, 01 say "Do you want to continue? [Y/N] " get yret picture "Y"
f_rd ()
if .not. yret
   return
endif
release all like l_*
do while .t.
   ydbf = space (8)
   @ 03, 01 say "Enter database name:  " get ydbf picture "!!!!!!!!" ;
      valid f_valid (ydbf = "ALL     " .or. f_verify ("dbsetup", 1, ydbf))
   if f_rd () = 27
      close database
      return
   endif
   if ydbf <> "ALL     "
      ydb = ydbf
      set delete off
      f_use ("dbsetup")
      set filter to f_name = ydb .or. empty (f_name)
      go top
      do while .t.
         f_dbedit ()
         yret = f_confirm ("[C]onfirm  [E]dit  [I]gnore Changes", "CEI")
         do case
         case yret $ "CI"
            exit
         case yret = "E"
            loop
         endcase
      enddo
      set delete on
      if yret = "I"
         loop
      endif

      yfil = gdbfpath + "x" + trim (substr (ydb, 2)) + ".dbf"
      if .not. f_valid (.not. file (yfil), ;
         "Warning!  Last Update was aborted!!!  Request Ignored!!!")
         loop
      endif

      select dbsetup
      set filter to
      seek ydb
      if .not. found ()
         loop
      endif

      ykeyflds = ""
      f_use ("raidx")
      seek ydb
      ynumidx = 0
      xfilestr = "_G" + trim (ydb)
      &xfilestr = left (&xfilestr, 3)
      do while fname = ydb .and. .not. eof ()
         ykeyflds = ykeyflds + upper (trim (fidx)) + ";"
         ynumidx = ynumidx + 1
         idxary [ynumidx] = trim (fidx)
         ntxary [ynumidx] = trim (fndx)
         &xfilestr = &xfilestr + f_truncate (fndx, 8)
         skip
      enddo
      use
      select 0
      create filetmp
      use filetmp exclusive

      f_popup ("Please wait ....")
      release all like l_*
      select dbsetup
      do while f_name = ydb .and. .not. eof ()
         if upper (trim (f_field)) $ ykeyflds
            select filetmp
            append blank
            replace field_name with dbsetup->f_field
            replace field_type with dbsetup->f_type
            replace field_len with dbsetup->f_width
            replace field_dec with dbsetup->f_dec
            select dbsetup
            xfname = "L_" + f_field
            if empty (f_init)
               if f_type = "C"
                  &xfname = space (f_width)
               elseif f_type = "N"
                  &xfname = 0
               elseif f_type = "D"
                  &xfname = ctod (space (8))
               elseif f_type = "L"
                  &xfname = .f.
               endif
            else
               xfinit = f_init
               if f_type = "C"
                  &xfname = f_truncate (&xfinit, f_width)
               else
                  &xfname = &xfinit
               endif
            endif
         endif
         skip
      enddo
      seek ydb
      do while f_name = ydb .and. .not. eof ()
         if .not. (upper (trim (f_field)) $ ykeyflds)
            select filetmp
            append blank
            replace field_name with dbsetup->f_field
            replace field_type with dbsetup->f_type
            replace field_len with dbsetup->f_width
            replace field_dec with dbsetup->f_dec
            select dbsetup
            xfname = "L_" + f_field
            if empty (f_init)
               if f_type = "C"
                  &xfname = space (f_width)
               elseif f_type = "N"
                  &xfname = 0
               elseif f_type = "D"
                  &xfname = ctod (space (8))
               elseif f_type = "L"
                  &xfname = .f.
               endif
            else
               xfinit = f_init
               if f_type = "C"
                  &xfname = f_truncate (&xfinit, f_width)
               else
                  &xfname = &xfinit
               endif
            endif
         endif
         skip
      enddo
      use
      f_popup ("Creating new database ...")
      if ydb <> "RAPATH  "
         save to (gmempath + trim (ydb) + ".mem") all like l_*
      endif
      select filetmp
      if file (gdbfpath + trim (ydb) + ".dbf")
         rename (gdbfpath + trim (ydb) + ".dbf") to &yfil
         create (gdbfpath + trim (ydb) + ".dbf") from filetmp
         use
         set excl on
         use (gdbfpath + trim (ydb))
         for n = 1 to ynumidx
            yidxkey = idxary [n]
            index on &yidxkey to (gdbfpath + ntxary [n])
         next
         use
         f_use (trim (ydb))
         set excl off
         zap
         reindex
         append from &yfil
         erase &yfil
      endif
      use
      erase filetmp.dbf
      release all like l_*
      f_popup ("Completed. Press Any Key to Continue...",.t.)
   else
      f_use ("rapath")
      yreccount = reccount ()
      @ 4, 0 clear to 23, 79
      for ycnt = 1 to yreccount
         f_use ("rapath")
         go (ycnt)
         if deleted ()
            loop
         endif
         ydb = fname
         @ 05, 01 say "Working on Database:  " + ydb
         use

         yfil = gdbfpath + "x" + trim (substr (ydb, 2)) + ".dbf"
         if .not. f_valid (.not. file (yfil), ;
            "warning!  Last Update was aborted!!!  Request Ignored!!!")
            loop
         endif

         f_use ("dbsetup")
         set filter to
         seek ydb
         if .not. found ()
            loop
         endif

         ykeyflds = ""
         f_use ("raidx")
         seek ydb
         ynumidx = 0
         xfilestr = "_G" + trim (ydb)
         &xfilestr = left (&xfilestr, 3)
         do while fname = ydb .and. .not. eof ()
            ykeyflds = ykeyflds + upper (trim (fidx)) + ";"
            ynumidx = ynumidx + 1
            idxary [ynumidx] = trim (fidx)
            ntxary [ynumidx] = trim (fndx)
            &xfilestr = &xfilestr + f_truncate (fndx, 8)
            skip
         enddo
         use
         select 0
         create filetmp
         use filetmp exclusive

         f_popup ("Please wait ....")
         release all like l_*
         select dbsetup
         do while f_name = ydb .and. .not. eof ()
            if upper (trim (f_field)) $ ykeyflds
               select filetmp
               append blank
               replace field_name with dbsetup->f_field
               replace field_type with dbsetup->f_type
               replace field_len with dbsetup->f_width
               replace field_dec with dbsetup->f_dec
               select dbsetup
               xfname = "L_" + f_field
               if empty (f_init)
                  if f_type = "C"
                     &xfname = space (f_width)
                  elseif f_type = "N"
                     &xfname = 0
                  elseif f_type = "D"
                     &xfname = ctod (space (8))
                  elseif f_type = "L"
                     &xfname = .f.
                  endif
               else
                  xfinit = f_init
                  if f_type = "C"
                     &xfname = f_truncate (&xfinit, f_width)
                  else
                     &xfname = &xfinit
                  endif
               endif
            endif
            skip
         enddo
         seek ydb
         do while f_name = ydb .and. .not. eof ()
            if .not. (upper (trim (f_field)) $ ykeyflds)
               select filetmp
               append blank
               replace field_name with dbsetup->f_field
               replace field_type with dbsetup->f_type
               replace field_len with dbsetup->f_width
               replace field_dec with dbsetup->f_dec
               select dbsetup
               xfname = "L_" + f_field
               if empty (f_init)
                  if f_type = "C"
                     &xfname = space (f_width)
                  elseif f_type = "N"
                     &xfname = 0
                  elseif f_type = "D"
                     &xfname = ctod (space (8))
                  elseif f_type = "L"
                     &xfname = .f.
                  endif
               else
                  xfinit = f_init
                  if f_type = "C"
                     &xfname = f_truncate (&xfinit, f_width)
                  else
                     &xfname = &xfinit
                  endif
               endif
            endif
            skip
         enddo
         use
         f_popup ("Creating new database ...")
         if ydb <> "RAPATH  "
            save to (gmempath + trim (ydb) + ".mem") all like l_*
         endif
         select filetmp
         if file (gdbfpath + trim (ydb) + ".dbf")
            rename (gdbfpath + trim (ydb) + ".dbf") to &yfil
            create (gdbfpath + trim (ydb) + ".dbf") from filetmp
            use
            set excl on
            use (gdbfpath + trim (ydb))
            for n = 1 to ynumidx
               yidxkey = idxary [n]
               index on &yidxkey to (gdbfpath + ntxary [n])
            next
            use
            f_use (trim (ydb))
            set excl off
            zap
            reindex
            append from &yfil
            erase &yfil
         endif
         use
         erase filetmp.dbf
         release all like l_*
         f_popup ("Completed. Press Any Key to Continue...")
         inkey (2)
         f_popback ()
      next
      @ 4, 0 clear to 23, 79
   endif
   save to (gmempath + "RAPATH") all like _g*
enddo

