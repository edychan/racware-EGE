*
* archive old contracts
* 07.31.98 (edc): year 2000
private yclnval, yclnpict, yclnlgc, yclninq

f_clrscn ("Archive Old Contract")
setcolor (gbluecolor)

yclnval = date () - 180
ydrv = space(24)

@ 10, 5 say "Enter Contract Check In Date for contracts to archive " ;
   get yclnval valid f_y2k (@yclnval)
@ 11, 5 say "Target Drive (e.g. F:\RACWARE\DBF\) : " get ydrv 
if f_rd () = 27
   return
endif

if f_confirm ("Are you sure to archive contracts closed before " + ;
      dtoc (yclnval) + "? [Y/N]", "YN") = "N"
   return
endif

ycnt = 0
yarch = 0

if empty(ydrv)
   f_use ("RAAGRH")
   go top
   copy to (gstnpath + "RAAGRH") for rsysmaok ()
   use
   @ 14, 0 clear to 16, 79
   ydiskno = 1
   select 0
   use (gstnpath + "RAAGRH") exclusive
   do while .not. eof ()
      do while .t.
         if f_popup ("Insert a blank formatted diskette and hit ENTER...", .t.) = 27
            if f_confirm ("Do you want to quit? [Y/N] ", "YN") = "Y"
               close database
               erase (gstnpath + "RAAGRH.DBF")
               return
            endif
         endif
         if file ("A:RAAGRH.DBF")
            loop
         endif
         copy stru to a:raagrh.dbf
         if .not. file ("a:raagrh.dbf")
            loop
         endif
         exit
      enddo
   
      @ 14, 5 say "Disk " + str (ydiskno, 2)
      nrecs = int ((diskspace (1) - header ()) / recsize ()) - 2
      ncpy = 0
      copy to a:raagrh while rsysaa1 ()
      ydiskno = ydiskno + 1
      skip
   enddo
   use
   erase (gstnpath + "RAAGRH.DBF")
else
   f_use ("RAAGRH",4)
   restore from (gmempath + "RAAGRH") additive
   yfil = alltrim(ydrv) + "RAHAGR.DBF"
   if .not. file (yfil)
       copy stru to &yfil
   endif
   select 0
   use &yfil alias rahagr
   select raagrh
   go top
   do while .not. eof () .and. fdatein <= yclnval
      rsysmaok ()
      f_retrieve ()
      select rahagr
      append blank
      f_replace ()
      select raagrh
      skip
   enddo
   select rahagr
   use
   select raagrh
   use
endif

if yarch > 0
   f_popup ("Deleting Archived Records", .f.)
   set exclusive on
   f_use ("raagrh")
   set exclusive off
   delete for fdatein < yclnval
   
   f_popup ("Packing history database", .f.)
   pack
endif

close databases
release all like l_*

f_popup ("Archive Complete.  Press ENTER...", .t.)


******************************
function rsysaa1

ncpy = ncpy + 1
@ 16, 5 say "Record " + str (ncpy, 6)
return (ncpy < nrecs)


******************************
function rsysmaok

ycnt = ycnt + 1
@ 14, 5 say "Scanning Contracts " + str (ycnt, 6) + " of " + ;
   str (reccount (), 6)
if frastat = "O" .or. fdatein > yclnval
   return .f.
endif
yarch = yarch + 1
@ 16, 5 say "Contract Archived  " + str (yarch, 6)
return .t.
