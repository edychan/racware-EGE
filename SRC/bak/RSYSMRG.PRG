*f_clrscn ("Rebuild Reservation Grid Table")
*setcolor (gbluecolor)
*private yrow, yra, yresv, yans
*yans = .f.
*@ 02, 02 say "All users must exit out of the rental or reservation module."
*@ 03, 02 say "during this process.  Do you want to continue..............." ;
*   get yans pict "Y"
*if f_rd () = 27 .or. .not. yans
*   return
*else
*   @ 02, 00 clear to 03, 79
*endif
*yrow = 4
*@ 02, 04 say "Unit #      Resv Grid Tbl   RA   Resv"
*@ 03, 04 say "컴컴컴컴컴  컴컴컴컴컴컴�  컴컴  컴컴  컴컴컴컴"
*f_use ("RAVRES", 1)
*f_use ("RAAGR", 3)
*f_use ("RARES", 2)
*f_use ("RAVM", 1)
*go top
*do while .not. eof ()
*   @ yrow, 04 say ravm->funit
*   if .not. fresv
*      @ yrow, 21 say "No"
*      @ yrow, 43 say "Cleaning"
*      select ravres
*      seek ravm->funit
*      do while funit = ravm->funit .and. .not. eof ()
*         if f_clrskip () = 0
*            exit
*         endif
*      enddo
*   else
*      yra = 0
*      yresv = 0
*      @ yrow, 21 say "Yes"
*      @ yrow, 43 say "Cleaning"
*      select ravres
*      seek ravm->funit
*      do while funit = ravm->funit .and. .not. eof ()
*         if f_clrskip () = 0
*            exit
*         endif
*      enddo
*      @ yrow, 43 say "Building"
*      select raagr
*      seek ravm->funit
*      @ yrow, 31 say yra pict "9999"
*      do while funit = ravm->funit .and. .not. eof ()
*         yra = yra + 1
*         @ yrow, 31 say yra pict "9999"
*         select ravres
*         f_findblank ()
*         replace funit with ravm->funit, ffrom with raagr->fdateout
*         replace fto with raagr->fdatein, ftype with "A"
*         replace fnumber with raagr->floc + str (raagr->frano, 6)
*         replace ffromtime with raagr->ftimeout, ftotime with raagr->ftimein
*         commit
*         unlock
*         f_fupdate ("A")
*         select raagr
*         skip
*      enddo
*      select rares
*      seek "O"
*      @ yrow, 37 say yresv pict "9999"
*      do while fresvstat = "O" .and. .not. eof ()
*         if funit = ravm->funit
*            yresv = yresv + 1
*            @ yrow, 37 say yresv pict "9999"
*            select ravres
*            f_findblank ()
*            replace funit with ravm->funit, ffrom with rares->fdateout
*            replace fto with rares->fdatein, ftype with "R"
*            replace fnumber with rares->fresvno
*            replace ffromtime with rares->ftimeout
*            replace ftotime with rares->ftimein
*            commit
*            unlock
*            f_fupdate ("A")
*            select rares
*         endif
*         skip
*      enddo
*      @ yrow, 43 say "Done     "
*   endif
*   if yrow >= 22
*      scroll (04, 00, yrow, 78, 1)
*   else
*      yrow = yrow + 1
*   endif
*   select ravm
*   skip
*enddo
*close database 
*f_popup ("Process completed. Press any key to continue...", .t.)
