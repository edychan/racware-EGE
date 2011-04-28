* ===========================================================================
* review parking tickets (claims)
*
* date: 09/28/92
* author: edc
*
* date: 01/28/93
* edc: refine inquiry function
*      add maintenance screen
* 10/26/93 (edc): add 2nd index to search by violation #
* ===========================================================================
private yarray[2], yptr, yret, ykey, yval

f_use ("rapkg")
set filter to
if .not. f_valid (.not. eof(), "File is empty !")
   use
   return
endif

do while .t.
   f_clrscn ("Parking Violation")
   yarray[1] = " Plate #........ "
   yarray[2] = " Violation #.... "
   yptr = 1
   yret = f_pick_a (02, 05, "", "", yarray, 2, yptr)
   if yret = 0
      exit
   endif
   if yret = 1
      yval = space (10)
   else
      yval = space (12)
   endif
   @ 02, 02 say yarray [yret] get yval picture replicate ([!], len (yval))
   if f_rd ()	= 27
      exit
   endif
   yval = upper (alltrim (yval))
   set softseek on
   yfnd = .f.
   do case
   case yret = 1
      f_use ("rapkg",1)
      seek yval
      yfnd = (yval == alltrim (funit))
   case yret = 2
      f_use ("rapkg",2)
      seek yval
      yfnd = (yval == alltrim (flic))
   endcase

   if f_pick_f (4, 2, "", "Plate #컴컴Date컴컴훂ime컴" + ;
         "Location컴컴컴Contract #컴컴컴Violation #컴", ;
         "flic+[ ]+dtoc(fviodate)+[ ]+fviotime+[ ]+fvioloc+[ ]+" + ;
         "floc+[-]+str(frano,6)+[ ]+fviono")
      f_update ("rapkg", "rapkg")
   endif
enddo

close databases

