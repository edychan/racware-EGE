* ===========================================================================
* DBR - send dbr to central
*
* date: 05/01/91
* author: EDC
*
* revision
*
* ===========================================================================
private xkeyfld, xblankfld
private xfil, xntx, n, xfld1, xfld2, xkey, xupd

f_popup ("Please Wait While Checking Credit Card File...")

f_use ("racred", 4)
seek l_floc + str (l_fdbrno, 4)
yupd = .f.
do while .not. eof () .and. l_floc = frloc .and. l_fdbrno = fdbrno
   if frectype = __gccuncap .or. frectype = __gccspecauth
      yupd = .t.
      exit
   endif
   skip
enddo

if yupd
   f_valid (.f., "Warning! DBR has uncaptured credit card transactions!")
   if f_confirm ("Do you want to continue? [Y/N]", "YN") = "N"
      close database
      return
   endif
endif

f_popup ("Please Wait While Marking Credit Card File To Send...")

xfil = gsuppath + "RACRED.DBF"
xntx = gsuppath + "RACRED.NTX"

if file (xfil) .and. file (xntx)
   xkeyfld = "_GKRACRED"
   xkeyfld = substr (&xkeyfld, 2)
   xblankfld = "_GBRACRED"
   xblankfld = &xblankfld
   select 0
   use &xfil index &xntx alias supfil

   select racred
   seek l_floc + str (l_fdbrno, 4)

   do while .not. eof () .and. frloc = l_floc .and. fdbrno = l_fdbrno
      if .not. (frectype = __gccuncap .or. frectype = __gcccap .or. ;
            frectype = __gccspecauth)
         skip
         loop
      endif

      select supfil
      seek xblankfld
      xupd = .f.
      do while .not. eof () .and. &xkeyfld = xblankfld
         if rlock ()
            xupd = .t.
            exit
         else
            skip
         endif
      enddo
      if .not. xupd
         xupd = .t.
         append blank
         rlock ()
      endif

      for n = 1 to fcount ()
         xfld1 = field (n)
         xfld2 = "RACRED->" + xfld1
         replace &xfld1 with &xfld2
      next
      replace fupdate with "A"
      commit
      unlock
      select racred
      reclock ()
      if ftranstyp = "C"
         replace fauthamt with -abs (fauthamt), fcapamt with -abs (fcapamt)
      endif
      replace ftranstyp with "X"
      commit
      unlock
      skip
   enddo
   select supfil
   use
endif
select racred
use

f_use ("radbr", 1)

xfil = gsuppath + "RADBR.DBF"
xntx = gsuppath + "RADBR.NTX"

if file (xfil) .and. file (xntx)
   xkeyfld = "_GKRADBR"
   xkeyfld = substr (&xkeyfld, 2)
   xblankfld = "_GBRADBR"
   xblankfld = &xblankfld
   select 0
   use &xfil index &xntx alias supfil
   seek xblankfld
   xupd = .f.
   do while .not. eof () .and. &xkeyfld = xblankfld
      if rlock ()
         xupd = .t.
         exit
      else
         skip
      endif
   enddo
   if .not. xupd
      xupd = .t.
      append blank
      rlock ()
   endif

   for n = 1 to fcount ()
      xfld1 = field (n)
      xfld2 = "RADBR->" + xfld1
      replace &xfld1 with &xfld2
   next
   replace fupdate with "A"
   commit
   unlock
   use
endif

select radbr
reclock ()
replace fpost with date (), fglpstd with .t.
commit
unlock
use

f_popup ("Please Wait While Marking DBR File To Send...")

f_use ("rahdbrt", 1)
f_use ("radbrt", 1)

xfil = gsuppath + "RADBRT.DBF"
xntx = gsuppath + "RADBRT.NTX"

if file (xfil) .and. file (xntx)
   xkeyfld = "_GKRADBRT"
   xkeyfld = substr (&xkeyfld, 2)
   xblankfld = "_GBRADBRT"
   xblankfld = &xblankfld
   select 0
   use &xfil index &xntx alias supfil
   do while .t.
      select radbrt
      seek l_floc + str (l_fdbrno, 4)
      if .not. found ()
         exit
      endif

      select supfil
      seek xblankfld
      xupd = .f.
      do while .not. eof () .and. &xkeyfld = xblankfld
         if rlock ()
            xupd = .t.
            exit
         else
            skip
         endif
      enddo
      if .not. xupd
         xupd = .t.
         append blank
         rlock ()
      endif

      select rahdbrt
      append blank
      rlock ()

      for n = 1 to fcount ()
         xfld1 = field (n)
         xfld2 = "RADBRT->" + xfld1
         xfld3 = "RAHDBRT->" + xfld1
         xfld1 = "SUPFIL->" + xfld1
         replace &xfld1 with &xfld2
         replace &xfld3 with &xfld2
      next
      select rahdbrt
      commit
      unlock
      select supfil
      replace fupdate with "A"
      commit
      unlock
      select radbrt
      f_clrrec ()
   enddo
   select supfil
   use
endif

close databases
f_popback ()

