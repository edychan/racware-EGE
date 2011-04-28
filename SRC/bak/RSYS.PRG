do while .t.
   xret1 = f_pushmenu (xoption0)
   if xret1 = 0
      exit
   endif
   xoption1 = substr (goption [xret1], 4)
   do case
   case xret1 = 1
      do rsyss
   case xret1 = 2
      do rsysm
   case xret1 = 3
      do rsysu
   endcase
enddo

