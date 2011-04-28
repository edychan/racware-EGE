do while .t.
   xret1 = f_pushmenu (xoption0)
   if xret1 = 0
      exit
   else
      xoption1 = substr (goption [xret1], 4)
      do case
      case xret1 = 1
         if gccmodem
            do rcccb
         endif
         __gloc = gloc

      case xret1 = 2
         if gccmodem
            do rccab
         endif

      case xret1 = 3
         do rccfm

      case xret1 = 4
         do rccsu

      case xret1 = 5
         if gccmodem
            do rccim
         endif

      endcase
   endif
enddo

