do while .t.
   xret2 = f_pushmenu (xoption1)
   if xret2 = 0
      exit
   else
      xoption2 = substr (goption [xret2], 4)
      do case
      case xret2 = 1
         do rrnfmu with 1
      case xret2 = 2
         do rrnfmu with 2
      case xret2 = 3
         do rrnfmu with 3
      case xret2 = 4
         do rrnfmu with 4
      case xret2 = 5
         do rrnfmu with 5
      endcase
   endif
enddo

