*
* archive sold vehicle
*
private yclnval, yclnpict, yclnlgc, yclninq

f_clrscn ("Archive Sold Vehicles")
setcolor (gbluecolor)

yclnval = date () - 180

@ 10, 5 say "Enter Sold Date for Sold Vehicles to archive " ;
   get yclnval valid f_y2k (@yclnval)
if f_rd () = 27
   return
endif

if f_confirm ("Are you sure to archive sold vehicles sold before " + ;
      dtoc (yclnval) + "? [Y/N]", "YN") = "N"
   return
endif

f_use ("RAVH")
go top
ycnt = 0
yarch = 0
copy to (gstnpath + "RAVH") for rsysmavk ()
use

@ 14, 0 clear to 16, 79

select 0
use (gstnpath + "RAVH") exclusive

ydiskno = 1
do while .not. eof ()
   do while .t.
      if f_popup ("Insert a blank formatted diskette and hit ENTER...", .t.) = 27
         if f_confirm ("Do you want to quit? [Y/N] ", "YN") = "Y"
            close database
            erase (gstnpath + "RAVH.DBF")
            return
         endif
      endif
      if file ("A:RAVH.DBF")
         loop
      endif
      copy stru to a:ravh.dbf
      if .not. file ("a:ravh.dbf")
         loop
      endif
      exit
   enddo

   @ 14, 5 say "Disk " + str (ydiskno, 2)
   nrecs = int ((diskspace (1) - header ()) / recsize ()) - 2
   ncpy = 0
   copy to a:ravh while rsysaa1 ()
   ydiskno = ydiskno + 1
   skip
enddo
use

f_popup ("Deleting Archived Records", .f.)
set exclusive on
f_use ("ravh")
set exclusive off
delete for fsolddt < yclnval

f_popup ("Packing history database", .f.)
pack
close databases
erase (gstnpath + "RAVH.DBF")

f_popup ("Archive Complete.  Press ENTER...", .t.)


******************************
function rsysmavk

ycnt = ycnt + 1
@ 14, 5 say "Scanning Sold Vehicles " + str (ycnt, 6) + " of " + ;
   str (reccount (), 6)
if fsolddt >= yclnval
   return .f.
endif
yarch = yarch + 1
@ 16, 5 say "Sold Vehicles Archived  " + str (yarch, 6)
return .t.
