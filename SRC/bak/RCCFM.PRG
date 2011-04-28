do while .t.
   xret2 = f_pushmenu (xoption1)
   if xret2 = 0
      exit
   else
      xoption2 = substr (goption [xret2], 4)
      do case
      case xret2 = 1
         do rccfmup with "A"

      case xret2 = 2
         do rccfmup with "U"

      case xret2 = 3
         do rccfmup3

      endcase
   endif
enddo

