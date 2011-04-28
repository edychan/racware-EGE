* ===========================================================================
* review vehicle loss notice (claims)
*
* date: 09/28/92
* author: edc
*
* date: 01/28/93
* edc: refine inquiry function
* ===========================================================================

f_use ("RAVLN")
if .not. f_valid (.not. eof(), "File is empty !")
   use
   return
endif

do while .t.
   f_clrscn ("REVIEW VEHICLE LOSS NOTICE")
   @ 03, 02 say "Plate # "
   l_flic = space (10)
   @ 03, 11 get l_flic picture "!!!!!!!!!!"
   if f_rd () = 27 
      exit
   endif
   if empty(l_flic)
      go top
   else
      set softseek on
      seek l_flic
      set softseek off
   endif

   if f_pick_f (4, 2, "", "Plate #컴컴Date컴컴훂ime컴" + ;
         "Location컴컴컴Remark컴컴컴컴컴Violation #컴", ;
         "flic+[ ]+dtoc(fviodate)+[ ]+fviotime+[ ]+fvioloc+[ ]+" + ;
         "f_truncate (frmk1, 15)+[ ]+fviono")
      f_update ("ravln", "ravln")
   endif
enddo

close databases


