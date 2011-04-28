* ===========================================================================
* Reservation module - mark no shows
*
* date: 05/01/91
* author: KST
*
* revision
* date: 01/06/93
* edc: only mark no show for gloc (system location)
* ===========================================================================
f_clrscn ("Mark No Show Reservations")
setcolor (gbluecolor)
f_use ("rasys")
ydate = date () - fnoshwday
use
yans = .f.
@ 2, 2 say "Today is " + dtoc (date ())
@ 3, 2 say "Reservation Date considered to be no show is " get ydate valid ;
  f_y2k (@ydate)
f_rd ()
if f_confirm ("Do you want to mark No Show reservations? ", "YN") = "N"
   return
endif

* f_use ("ravres", 1)    && 01/05/94 (edc) take res grid tbl
f_use ("rares", 2)
y1 = 0
y2 = 0
select 0
if .not. file (gstnpath + "rans.dbf")
   create (gstnpath + "stru")
   use (gstnpath + "stru") exclusive
   append blank
   replace field_name with "RECNUM"
   replace field_type with "N"
   replace field_len with 10
   replace field_dec with 0
   append blank
   replace field_name with "STAT"
   replace field_type with "C"
   replace field_len with 1
   replace field_dec with 0
   use
   create (gstnpath + "rans") from (gstnpath + "stru")
   erase (gstnpath + "stru.dbf")
endif
use (gstnpath + "rans") exclusive alias rans
zap
select rares
seek "O"
do while fresvstat = "O" .and. .not. eof ()
   y1 = y1 + 1
   @ 5, 2 say "Records Scanned ... " + str (y1, 6)
   if fdateout <= ydate .and. floc = gloc    && 01/05/93: only mark no show for gloc
      y3 = recno ()
      if frano > 0
         *f_fupdate ("C")
         *reclock ()
         *replace fresvstat with "X"
         *commit
         *unlock
         select rans
         append blank
         replace recnum with y3, stat with "X"
      else
         y2 = y2 + 1
         @ 7, 2 say "No show ........... " + str (y2, 6)
         *f_fupdate ("C")
         *reclock ()
         *replace fresvstat with "N"
         *commit
         *unlock
         select rans
         append blank
         replace recnum with y3, stat with "N"
      endif
      *if .not. empty (funit)
      *   select ravres
      *   seek rares->funit + "R" + rares->fresvno
      *   if found ()
      *      f_clrrec ()
      *   endif
      *endif
   endif
   select rares 
   skip
enddo

f_popup ("Please Wait While Updating Reservation File...", .f.)

f_use ("rares",1)        && reset index to fresvno
select rans
go top
do while .not. eof ()
   select rares
   go rans->recnum
   f_fupdate ("C")
   reclock ()
   replace fresvstat with rans->stat
   commit
   unlock
   select rans
   skip
enddo
 
f_popup ("Update Completed. Press Any Key to Continue...", .t.)
close databases



