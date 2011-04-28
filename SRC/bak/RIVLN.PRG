* ===========================================================================
* vehicle loss notice (claims) maint.
*
* date: 09/28/92
* author: edc
*
* ===========================================================================
do while .t.
   xret2 = f_pushmenu (xoption1)
   if xret2 = 0
      exit
   endif
   xoption2 = substr (goption [xret2], 4)
   rest from (gmempath+"ravln") additive
   do case
   case xret2 = 1
      do rivlnlv          && locate violator
   case xret2 = 2
      do rivlnfm          && review loss notice
   endcase
enddo


