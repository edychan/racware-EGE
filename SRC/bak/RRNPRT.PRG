* ===========================================================================
* contract printing module
*
* date: 05/01/91
* author: kst
*
* revision
* 12/09/93 (edc): allow re-enter ra# for reprint during open ra
* 12.07.04: fix window xp printing problem
* ===========================================================================
parameters xtyp, xfunc
private xformno, yrow, ybuffer, yfld, ypict, ysel

xformno = grafrmno

* if pcount () < 3    && 12/09/94 allow reenter ra# for reprint during open
if pcount () < 2
   xfunc = ""
endif

ysel = select ()

f_use ("RAAGRFRM")
begin sequence
   yrow = 0
   ybuffer = space (132)
   f_popback ()
   do while .t.
      setcolor (gredcolor)
      do while .t.
         @ 24, 01 say "Enter contract form number to use......[  ]"
         @ 24, 41 get xformno pict "99"
         if f_rd () = 27
            xformno = 0
            exit
         endif
         seek str (xformno, 2) + xtyp
         if .not. f_valid (found (), "Warning!  Contract Printing Form " + ;
               str (xformno, 2) + " Not Found!!!")
            loop
         else
            exit
         endif
      enddo
      setcolor (gbluecolor)
      if xformno = 0
         exit
      endif

      if f_popup ("Press any key when you are ready to print...", .t.) = 27
         exit
      endif
      set console off
      set print on
      set device to print
      set printer to lpt1
      setprc (0, 0)
      do while .not. eof () .and. ffrmno = xformno .and. ffrmtyp = xtyp
         do while frow > yrow
            ? trim (ybuffer)
            ybuffer = space (132)
            yrow = yrow + 1
         enddo

         yfld = ffield
         ypict = trim (fpict)
         yfld = transform (&yfld, ypict)
         ybuffer = stuff (ybuffer, fcol + 1, len (yfld), yfld)
         skip
      enddo
      ? trim (ybuffer)
      eject
      set printer to
      set print off
      set console on
      set device to screen
      if f_confirm ("Do you want to reprint the contract? ", "YN") = "Y"
         if .not. empty (xfunc)
            do &xfunc
         endif
         go top
         seek str (xformno, 2) + xtyp
         yrow = 0
         loop
      else
         exit
      endif
   enddo
end
use

set printer to
set print off
set console on
set device to screen

select (ysel)
f_popback ()
