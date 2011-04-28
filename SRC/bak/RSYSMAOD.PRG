f_clrscn ("Archive Old Contract")
setcolor (gbluecolor)
ydrv = space(24)
@ 05, 02 say "Enter Source Drive (e.g. F:\RACWARE\DBF\) : " get ydrv
if f_rd () = 27
   return
endif

declare yarray [3]
f_getscn ("RAAGR")
l_floc = gloc
l_frano = 0
l_flname = space (14)
l_funit = space (10)
l_frefno = space (14)

do while .t.

   if empty (ydrv)
      if f_popup ("Insert archive diskette into drive and hit ENTER... ", .t.) = 27
         exit
      endif
   
      if .not. f_valid (file ("A:RAAGRH.DBF"), ;
            "Diskette is not an archive diskette!!!")
         loop
      endif
   
      f_popup ("Please wait...indexing archive file...", .f.)
      f_use ("raagrh")
      copy stru to (gstnpath + "RAAGRH")
      use
      use (gstnpath + "RAAGRH") exclusive
      index on floc + str (frano,6) to (gstnpath + "X1")
      index on upper (flname) to (gstnpath + "X2")
      index on upper (frefno) to (gstnpath + "X3")
      set index to (gstnpath + "X1"), (gstnpath + "X2"), (gstnpath + "X3")
      append from a:raagrh
      f_popback ()
   else
      yfil = alltrim(ydrv) + "RAHAGR.DBF"
      if .not. f_valid (file (yfil), ;
            "Contract Database missing...")
         exit
      endif
      f_popup ("Please wait...indexing archive file...", .f.)
      use &yfil excl
      index on floc + str (frano,6) to (gstnpath + "X1")
      index on upper (flname) to (gstnpath + "X2")
      index on upper (frefno) to (gstnpath + "X3")
      set index to (gstnpath + "X1"), (gstnpath + "X2"), (gstnpath + "X3")
      f_popback ()
   endif
   yarray [1] = " Contract Number .... "
   yarray [2] = " Last Name .......... "
   yarray [3] = " Reference Number ... "

   do while .t.
      yptr = f_pick_a (02, 05, "", "", YARRAY, 3, 1)
      if yptr = 0
         use
         exit
      endif
      ycolor = setcolor (gsubcolor)
      yscn = f_box (2, 21, 4, 62)
      do case
      case yptr = 1
         ytitle = "Contract No.컴컴컴Renter"
         ykey = "l_floc + str (l_frano, 6)"
         yexp = "f_truncate (trim (floc) + [-] + ltrim (str (frano, 6)), " + ;
            "18) + f_truncate (trim (ffname) + [ ] + flname, 27)"
         l_floc = gloc
         @ 3, 23 say "Contract Number ...."
         @ 3, 44 get l_floc picture "!!!!!!!!!!"
         @ 3, 55 get l_frano picture "999999"
      case yptr = 2
         ytitle = "Renter컴컴컴컴컴컴컴컴컴컴컴컴컴횮heck Out At"
         ykey = "upper (l_flname)"
         yexp = "f_truncate (trim (flname) + [, ] + ffname, 28) + " + ;
            "[ Check Out At ] + floc + [ ] + dtoc (fdateout)"
         @ 3, 23 say "Last Name ............."
         @ 3, 43 get l_flname
      case yptr = 3
         ykey = "upper (l_frefno)"
         ytitle = "Ref No.컴컴컴컴Check Out At"
         yexp = "[Ref No ] + frefno + [  Check Out At ] + floc + [ ] + " + ;
            "dtoc (fdateout)"
         @ 3, 23 say "Reference Number ........"
         @ 3, 43 get l_frefno
      endcase
      if f_rd () = 27
         setcolor (ycolor)
         use
         exit
      endif
      f_restbox (yscn)
      setcolor (ycolor)
      set order to (yptr)
      set softseek on
      seek &ykey
      if eof ()
         go bottom
      endif
      set softseek off
      if .not. ((found () .and. yptr <> 2) .or. f_pick_f (02, 77 - len (&yexp), "", ytitle, yexp))
         use
         exit
      endif

      do while .t.
         setcolor (gblueget)
         @ 02,11 say floc
         @ 02,22 say frano picture "999999"
         @ 02,34 say fdbrno picture "9999"
         @ 03,11 say frloc
         @ 04,11 say flname
         @ 05,11 say ffname
         @ 06,11 say faddr
         @ 07,11 say fcity
         @ 08,11 say fstate
         @ 08,14 say fzip
         @ 09,11 say fphone
         @ 10,11 say flic
         @ 10,36 say flicst
         @ 11,11 say flicexp
         @ 11,30 say fdob
         @ 13,11 say fcrpnm
         @ 14,11 say fcrpaddr
         @ 15,11 say fcrpcity
         @ 16,11 say fcrpstate
         @ 16,14 say fcrpzip
         @ 17,11 say fcrpph
         @ 18,11 say freferal
         @ 03,53 say ftmetot picture "@Z 99999.99"
         @ 04,53 say fmlgtot  picture "@Z 99999.99"
         @ 05,53 say fmlgtot + ftmetot picture "@Z 99999.99"
         @ 06,53 say fdisctot picture "@Z 99999.99"
         @ 07,53 say fcredtot picture "@Z 99999.99"
         @ 08,53 say fcdwtot picture "@Z 99999.99"
         @ 09,45 say foitem1
         @ 10,45 say foitem2
         @ 11,45 say foitem3
         @ 12,45 say foitem4
         @ 09,53 say fotot1 picture "@Z 99999.99"
         @ 10,53 say fotot2 picture "@Z 99999.99"
         @ 11,53 say fotot3 picture "@Z 99999.99"
         @ 12,53 say fotot4 picture "@Z 99999.99"
         @ 03,70 say fsurchg picture "@Z 99999.99"
         @ 05,70 say ftaxtot picture "@Z 99999.99"
         @ 06,70 say fpaitot picture "@Z 99999.99"
         @ 07,70 say ffueltot picture "@Z 99999.99"
         @ 08,70 say fdmgtot picture "@Z 99999.99"
         @ 09,70 say ftotal picture "@Z 99999.99"
         @ 11,71 say fdepamt picture "@Z 9999.99"
         @ 12,71 say famtdue picture "@Z 9999.99"
         @ 15,54 say fpaytyp1
         @ 15,59 say famt1 picture "@Z 99999.99"
         @ 16,54 say fpaytyp2
         @ 16,59 say famt2 picture "@Z 99999.99"
         @ 17,54 say fpaytyp3
         @ 17,59 say famt3 picture "@Z 99999.99"
         @ 15,69 say fdbacct1
         @ 16,69 say fdbacct2

         if empty (feunit)
            @ 21,02 say funit
            @ 22,02 say space (10)
            @ 21,28 say fdatein
            @ 21,37 say ftimein pict "99:99"
            @ 22,28 say space (8)
            @ 22,37 say space (5)
            @ 21,44 say fmlgout picture "99999"
            @ 21,50 say fmlgin picture "99999"
            @ 22,44 say space (5)
            @ 22,50 say space (5)
         else
            @ 21,02 say feunit
            @ 22,02 say funit
            @ 21,28 say fexdate
            @ 21,37 say fextime pict "99:99"
            @ 22,28 say fdatein
            @ 22,37 say ftimein pict "99:99"
            @ 21,44 say femlgout picture "99999"
            @ 21,50 say femlgin picture "99999"
            @ 22,44 say fmlgout picture "99999"
            @ 22,50 say fmlgin picture "99999"
         endif
         @ 21,13 say fdateout
         @ 21,22 say ftimeout pict "99:99"
         @ 20,69 say fdays picture "9999"
         @ 20,74 say frhr pict "99"
         @ 21,63 say fresvno
         @ 22,63 say frefno
         @ 23,67 say fstamp
         setcolor (gbluecolor)

         ykeyin = f_confirm ("[N]ext   [P]revious   [Q]uit", "NPQ")
         do case
         case ykeyin = "N"
            skip 1
            if eof ()
               f_popup ("End of file. Press Any Key to Continue...", .t.)
               go bottom
            endif
            loop
         case ykeyin = "P"
            skip -1
            if bof ()
               f_popup ("Top of file. Press Any Key to Continue...", .t.)
               go top
            endif
            loop
         case ykeyin = "Q"          && need to loop back to inquiry...
            exit
         endcase
      enddo
      exit     && need to loop back to inquiry...
   enddo
   exit
enddo
close databases
erase (gstnpath + "X1.ntx")
erase (gstnpath + "X2.ntx")
erase (gstnpath + "X3.ntx")
erase (gstnpath + "RAAGRH.DBF")
