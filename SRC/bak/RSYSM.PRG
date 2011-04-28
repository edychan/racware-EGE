do while .t.
   xret2 = f_pushmenu (xoption1)
   if xret2 = 0
      exit
   endif
   xoption2 = substr (goption [xret2], 4)
   do case
   case xret2 = 1
      do rsysmao
   case xret2 = 2
      do rsysmav
   case xret2 = 3
      do rsysmrg
   case xret2 = 4
      do rsysmpu
   case xret2 = 5
      do rsysmri
   endcase
enddo

release all like l_*
close database

