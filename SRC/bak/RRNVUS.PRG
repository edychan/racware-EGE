* ===========================================================================
* update vehicle status
*
* revision
*
* date: 01/28/93
* edc: update vehicle mileage also.
* 12.29.98: cannot change vehicle status other than from "I" or "A"
* ===========================================================================

f_clrscn ("Vehicle Status Update")
f_use ("RAVM", 1)
@ 01, 01 say "Unit No.   Description                     License    " + ;
   "Stall Status Code Mileage"
@ 02, 01 say "ÄÄÄÄÄÄÄÄÄÄ ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ ÄÄÄÄÄÄÄÄÄÄ " + ;
   "ÄÄÄÄÄ ÄÄÄÄÄÄ ÄÄÄÄ ÄÄÄÄÄÄÄ"
yrow = 3
yunit = space (10)
set key 28 to rrnvuf1
do while .t.
   @ yrow, 1 get yunit picture "!!!!!!!!!!"
   if f_rd () = 27
      exit
   endif
   select ravm
   seek yunit
   if .not. f_valid (found (), "Unit Number Not Found!!!")
      loop
   elseif .not. ravm->fstatus $ "I;A"     && 12.30.98
      f_valid (.f., "Invalid Stat -> " + ravm->fstatus)
      loop
   endif
   ystr = ltrim (trim(floc)+"->"+fyear + " " + fcolor + " " + fmodel)
   do while "  " $ ystr
      ystr = strtran (ystr, "  ", " ")
   enddo
   @ yrow, 12 say f_truncate (ystr, 31)
   @ yrow, 44 say flic
   ystat = fstatus
   ystall = fstall
   yreason = freason
   ymiles = fmileage
   ydmg1 = fdmg1
   ydmg2 = fdmg2
   ydmg3 = fdmg3
   do while .t.
      @ yrow, 56 get ystall pict "!!!!"
      @ yrow, 64 get ystat picture "!" valid f_valid (ystat $ "AOHI")
      @ yrow, 69 get yreason picture "!" valid ((f_locate ("RAVS","fcode",yreason)).or.empty(yreason))
      @ yrow, 73 get ymiles pict "999999" ;
         valid f_valid (ymiles >= fmileage)
      f_rd ()
      xkey = f_confirm ("[C]onfirm  [E]dit  [I]gnore Changes", "CEI")
      do case
      case xkey = "C"
         f_fupdate ("C")
         reclock ()
         if fstatus = "H" .and. ystat <> "H"
            replace freason with " "
         else
            replace freason with yreason
         endif
         replace fstatus with ystat, fmileage with ymiles
         replace fstall with ystall, fdmg1 with ydmg1
         replace fdmg2 with ydmg2, fdmg3 with ydmg3
         replace futime with dtos (date ()) + time ()
         commit
         unlock
         exit
      case xkey = "E"
         loop
      case xkey = "I"
         exit
      endcase
   enddo
   if xkey <> "I"
      if yrow < 23
         yrow = yrow + 1
      else
         scroll (3, 0, 23, 79, 1)
      endif
   else
      @ yrow, 12
   endif
   yunit = space (10)
enddo

set key 28 to
close database

