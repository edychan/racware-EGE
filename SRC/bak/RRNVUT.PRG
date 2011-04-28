f_clrscn ("Transfer Vehicle")
f_use ("raagrx")
f_use ("RAVM", 1)
setcolor (gbluecolor)
@ 01, 01 say "Unit No.   Description                        Date     " + ;
   "Location   Miles  Stall"
@ 02, 01 say "컴컴컴컴컴 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 컴컴컴컴 " + ;
   "컴컴컴컴컴 컴컴컴 컴컴�"
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
   endif
   ystr = ltrim (fyear + " " + fcolor + " " + fmake + " " + fmodel)
   do while "  " $ ystr
      ystr = strtran (ystr, "  ", " ")
   enddo
   @ yrow, 12 say f_truncate (ystr, 34)
   @ yrow + 1, 12 say flic
   @ yrow, 56 say floc
   @ yrow, 67 say fmileage pict "999999"
   @ yrow, 75 say fstall
   ydate = date ()
   yloc = floc
   ymiles = fmileage
   ystall = fstall
   do while .t.
      @ yrow + 1, 47 get ydate
      @ yrow + 1, 56 get yloc pict "!!!!!!!!!!" ;
         valid f_valid (yloc $ gusrloc, "Invalid Location!!!")
      @ yrow + 1, 67 get ymiles pict "999999" ;
         valid f_valid (ymiles >= fmileage)
      @ yrow + 1, 75 get ystall pict "!!!!"
      f_rd ()
      xkey = f_confirm ("[C]onfirm  [E]dit  [I]gnore Changes", "CEI")
      do case
      case xkey = "C"
         if yloc <> ravm->floc .or. ymiles <> ravm->fmileage
            select raagrx
            append blank
            reclock ()
            replace fdatein with ydate, fdateout with  ydate
            replace fexchg with .f., flname with "TRANSFER: " + gusrid
            replace floc with ravm->floc, fmlgin with ravm->fmileage
            replace fmlgout with ymiles, fulic with ravm->flic
            replace funit with ravm->funit, ffname with "VEH TRANS"
            commit
            unlock
            f_fupdate ("A")
         endif
         select ravm
         f_fupdate ("C")
         reclock ()
         replace floc with yloc, fmileage with ymiles, fstall with ystall
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
      if yrow < 21
         yrow = yrow + 2
      else
         scroll (3, 0, 23, 79, 2)
      endif
   else
      @ yrow, 12 clear to yrow + 1, 79
   endif
   yunit = space (10)
enddo

set key 28 to
close database

