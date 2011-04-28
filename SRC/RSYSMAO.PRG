do while .t.
   xret3 = f_pushmenu (xoption2)
   if xret3 = 0
      exit
   else
      xoption3 = substr (goption [xret3], 4)
      do case
      case xret3 = 1
         do rsysmaoa
      case xret3 = 2
         do rsysmaod
      endcase
   endif
enddo

