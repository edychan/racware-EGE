do while .t.
   xret1 = f_pushmenu (xoption0)
   if xret1 = 0
      exit
   else
      xoption1 = substr (goption [xret1], 4)
      do case
      case xret1 = 1        && inventory maint.
         do rivim
      case xret1 = 2        && status code maint.
         do rivrc
      case xret1 = 3        && vehicle maint. records
         do rivsm
      case xret1 = 4        && parking ticket module
         do rivpk
      case xret1 = 5        && record sale record
         do rivrs
      case xret1 = 6        && vehicle loss notice
         do rivln
      case xret1 = 7        && fleet summary table
         do rivlf
      endcase
   endif
enddo
