f_clrscn ("Record Void Contract")
f_use ("RADTR")
f_use ("RAAGR", 1)
f_use ("RAAGRH", 1)
yrow = 3
@ 1, 10 say "Location    RA No.    Status"
@ 2, 10 say "컴컴컴컴컴  컴컴컴    컴컴컴컴컴컴컴컴"
yloc = gloc
do while .t.
   yrano = 0
   @ yrow, 10 get yloc picture "!!!!!!!!!!" valid f_valid (.not. empty (yloc))
   @ yrow, 22 get yrano picture "999999" valid f_valid (yrano > 0)
   if f_rd () = 27
      exit
   endif
   yfnd = .f.
   select raagr
   seek yloc + str (yrano, 6)
   if found ()
      yfnd = .t.
   else
      select raagrh
      seek yloc + str (yrano, 6)
      if found ()
         yfnd = .t.
      endif
   endif
   if yfnd
      tone (500, 9)
      @ yrow, 32 say "Already Exist!!!"
   else
      if f_confirm ("Are You Sure To Void It? [Y/N]", "YN") = "Y"
         select raagrh
         append blank
         reclock ()
         replace floc with yloc, frano with yrano, frastat with "R", ;
            flname with "VOIDED: "+gusrid, fdateout with date ();
            fdatein with date (), frloc with yloc
         commit
         unlock
         f_fupdate ("A")

         select radtr
         append blank
         reclock ()
         replace floc with yloc, frano with yrano, frectype with 'D'
         replace flname with "VOIDED: " + gusrid, frloc with yloc
         commit
         unlock
         f_fupdate ("A")
         @ yrow, 32 say "Voided"
      else
         @ yrow, 32 say "Not Voided"
      endif
   endif
   if yrow < 23
      yrow = yrow + 1
   else
      scroll (3, 0, 23, 79, 1)
   endif
enddo

