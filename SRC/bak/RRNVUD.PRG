f_clrscn ("Vehicle Status Update")
f_use ("RAVM", 1)
@ 1, 1 say "Unit No.   Description                     License    Damage"
@ 2, 1 say "컴컴컴컴컴 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴� 컴컴컴컴컴 컴컴컴컴컴컴컴컴컴컴"
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
   @ yrow, 12 say f_truncate (ystr, 31)
   @ yrow, 44 say flic
   ydmg1 = fdmg1
   ydmg2 = fdmg2
   ydmg3 = fdmg3
   do while .t.
      @ yrow, 55 get ydmg1
      @ yrow + 1, 55 get ydmg2
      @ yrow + 2, 55 get ydmg3
      f_rd ()
      xkey = f_confirm ("[C]onfirm  [E]dit  [I]gnore Changes", "CEI")
      do case
      case xkey = "C"
         f_fupdate ("C")
         reclock ()
         replace fdmg1 with ydmg1, fdmg2 with ydmg2, fdmg3 with ydmg3
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
         yrow = yrow + 3
      else
         scroll (3, 0, 23, 79, 3)
      endif
   else
      @ yrow, 12 clear to yrow + 2, 79
   endif
   yunit = space (10)
enddo

set key 28 to
close database

