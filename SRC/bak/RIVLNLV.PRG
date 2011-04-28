* ===========================================================================
* locate violator for vehicle loss notice (claims)
*
* date: 09/28/92
* author: edc
*
* ===========================================================================

f_clrscn ("VEHICLE LOSS NOTICE MAINT.")
f_popup ("Please Wait...", .f.)
f_use ("RAVLN")
f_use ("RAVM", 1)
f_use ("RAAGRX", 1)
set relation to funit into ravm

@ 01, 01 say "Lic. Plate  Claim #       Date      Time   Location       " + ;
   "  Remarks"
@ 02, 01 say "컴컴컴컴컴  컴컴컴컴컴컴  컴컴컴컴  컴컴�  컴컴컴컴컴컴컴� " + ;
   " 컴컴컴컴컴컴컴컴컴"
@ 18, 01 say replicate (chr (196), 78)
@ 19, 01 say "Unit # ..... "
@ 20, 01 say "RA# ........ "
@ 21, 01 say "Renter ..... "
@ 22, 01 say "Date Out ... "
@ 23, 01 say "Date In .... "

f_popback ()
yline = 3
rest from (gmempath + "RAVLN") additive
do while .t.
   @ yline, 01 get l_flic picture "!!!!!!!!!!"
   @ yline, 13 get l_fviono picture "!!!!!!!!!!!!"
   @ yline, 27 get l_fviodate
   @ yline, 37 get l_fviotime picture "99:99"
   @ yline, 44 get l_fvioloc
   if f_rd () = 27
      exit
   endif

   select raagrx
   seek l_flic
   yfnd = .f.
   do while .not. eof () .and. l_flic = fulic
      if l_fviodate < fdateout .or. l_fviodate > fdatein .or. ;
            (l_fviodate = fdateout .and. l_fviotime < ftimeout) .or. ;
            (l_fviodate = fdatein .and. l_fviotime > ftimein)
         skip
         loop
      else
         yfnd = .t.
         exit
      endif
   enddo

   if f_valid (yfnd, "Vehicle Not Rented!!!")
      ystr = ltrim (ravm->fyear + " " + ravm->fcolor + " " + ravm->fmake ;
         + " " + ravm->fmodel)
      do while "  " $ ystr
         ystr = strtran (ystr, "  ", " ")
      enddo
      l_fname = trim (flname) + ", " + ffname

      @ 19, 14 say trim (funit) + " - " + ystr
      @ 20, 14 say trim (floc) + "-" + ltrim (str (frano, 6))
      @ 21, 14 say l_fname
      @ 22, 14 say dtoc (fdateout) + " " + ftimeout
      @ 23, 14 say dtoc (fdatein) + " " + ftimein
   else
      @ 19, 14 clear to 19, 79
      @ 20, 14 clear to 20, 79
      @ 21, 14 clear to 21, 79
      @ 22, 14 clear to 22, 79
      @ 23, 14 clear to 23, 79
      loop
   endif

   select ravln
   seek l_flic + dtoc (l_fviodate) + l_fviotime + l_fviono
   if .not. found ()
      append blank
   endif

   f_fupdate ("C")
   reclock ()
   replace flic with l_flic, fpaid with .f.
   replace fviono with l_fviono, fviodate with l_fviodate
   replace fviotime with l_fviotime, fvioloc with l_fvioloc
   if yfnd
      replace fname with l_fname, frano with raagrx->frano
      replace floc with raagrx->floc, funit with ravm->funit
      replace fyear with ravm->fyear, fmake with ravm->fmake
      replace fmodel with ravm->fmodel, fvin with ravm->fvin
      replace faddr with raagrx->faddr, fcity with raagrx->fcity
      replace fstate with raagrx->fstate, fzip with raagrx->fzip
      replace fdob with raagrx->fdob, flicno with raagrx->flic
   else
      replace fname with " ", frano with 0
      replace floc with " ", funit with " "
      replace faddr with " ", fcity with " "
      replace fstate with " ", fzip with " "
      replace fdob with ctod (space (8)), flicno with " "
   endif
   commit
   unlock
   if yline < 17
      yline = yline + 1
   else
      scroll (3, 0, 17, 79)
   endif
   rest from (gmempath + "RAVLN") additive
enddo
close databases

