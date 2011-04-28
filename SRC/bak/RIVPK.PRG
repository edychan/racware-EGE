* ===========================================================================
* parking ticket module
*
*
* date: 01/28/93
* edc: refine inquiry function
* ===========================================================================

do while .t.
   xret2 = f_pushmenu (xoption1)
   if xret2 = 0
      exit
   endif
   xoption2 = substr (goption [xret2], 4)
   rest from (gmempath+"rapkg") additive
   do case
   case xret2 = 1
      do rivpklv
   case xret2 = 2
      do rivpkpn
   case xret2 = 3
      do rivpkfm
   endcase
enddo

