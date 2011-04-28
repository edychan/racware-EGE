* ===========================================================================
*
* RacWare main program
*
* ===========================================================================
do while .t.
   begin sequence
      do rinit
      restore from (gmempath + "RAPATH.MEM") additive

      do while .t.
         if .not. usrlgin ()
            loop
         endif
         do while .t.
            xret0 = f_pushmenu ("MAIN MENU")
            if xret0 = 0
               if usrlgout (.t.)
                  exit
               else
                  loop
               endif
            endif
            xoption0 = substr (goption [xret0], 4)
            bliovlclr ()
            set century off      && 08.24.99
            do case
            case xret0 = 1
               do rrnt

            case xret0 = 2
               do rres

            case xret0 = 3
               do rccp

            case xret0 = 4
               do rinv

            case xret0 = 5
               do rmkt

            case xret0 = 6
               do rdyp

            case xret0 = 7
               do rrpt

            case xret0 = 8
               do rsys

            endcase
         enddo
      enddo
   end
   set key 28 to
   set key -1 to
   set key -2 to
   set key -3 to
   set key -4 to
   set key -5 to
   set key -6 to               && calculator
   set key -7 to               && phone book
   set key -8 to               && reminder
   set key -9 to               && calendar
   usrlgout (.f.)
enddo

