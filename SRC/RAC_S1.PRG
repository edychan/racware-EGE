*
* print res voucher
*
f_clrscn ("PRINT RESERVATION VOUCHER")

f_box (02, 03, 04, 70)
yresvno = space(10)
ytitle = "Stat컴컴Resv No.컴횸ocation컴횼ame컴컴컴컴컴컴컴컴컴컴컴컴�"  + ;
         "Resv Dte"
yexp = "f_rvstat (fresvstat) + [ ] + fresvno + [ ] + floc + [ ] + " + ;
       "f_truncate (trim (ffname) + [ ] + flname, 28) + [ ] + " + ;
       "dtoc (fdateout)"
f_use ("rares")
f_use ("raagnt")
select rares
set relation to rares->fatc into raagnt
yfil = "j:\racware\dbf\raresfrm"
select 0
use &yfil index &yfil alias prtfrm

do while .t.
   @ 03, 05 say "Enter RES #: " get yresvno
   if f_rd () = 27 .or. empty(yresvno)
      exit
   endif
   select rares
   set softseek on
   seek yresvno
   set softseek off
   if eof ()
      go bottom
   endif
   if f_pick_f (02, 77 - len (&yexp), "", ytitle, yexp)
      do prtres 
   endif
enddo

close data

******************************
function f_rvstat

parameter xstat

do case
case xstat = "O"
   return "OPEN   "
case xstat = "X"
   return "USED   "
case xstat = "U"
   return "CLOSED "
case xstat = "C"
   return "CANCEL "
case xstat = "N"
   return "NO SHOW"
otherwise
   return "UNKNOWN"
endcase

**************************
procedure prtres

begin sequence
   yrow = 0
   ybuffer = space (132)
   f_popback ()
   do while .t.
      if f_popup ("Press any key when you are ready to print...", .t.) = 27
         exit
      endif
      setprc (0, 0)
      set console off
      set print on
      select prtfrm
      go top
      do while .not. eof () 
         do while frow > yrow
            ? trim (ybuffer)
            ybuffer = space (132)
            yrow = yrow + 1
         enddo

         yfld = ffield
         ypict = trim (fpict)
         yfld = transform (&yfld, ypict)
         ybuffer = stuff (ybuffer, fcol + 1, len (yfld), yfld)
         skip
      enddo
      ? trim (ybuffer)
      eject
      exit
   enddo
end
set print off
set printer to
set console on
set device to screen

f_popback ()
return

