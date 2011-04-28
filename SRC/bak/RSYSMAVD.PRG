declare yarray [3]
f_getscn ("RAVH")
l_funit = space (10)

do while .t.
   if f_popup ("Insert archive diskette into drive and hit ENTER... ", .t.) = 27
      exit
   endif

   if .not. f_valid (file ("A:RAVH.DBF"), ;
         "Diskette is not an archive diskette!!!")
      loop
   endif

   f_popup ("Please wait...indexing archive file...", .f.)
   f_use ("ravh")
   copy stru to (gstnpath + "RAVH")
   use
   use (gstnpath + "RAVH") exclusive
   index on funit to (gstnpath + "X1")
   set index to (gstnpath + "X1")
   append from a:ravh
   f_popback ()

   go top
   if .not. f_valid (.not. eof (), "Archive disk is empty")
      close databases
      return
   endif
   do while .t.
      ybox = f_box (02, 05, 04, 29)
      @ 03, 07 say "Vehicle # " get l_funit picture "!!!!!!!!!!"
      if f_rd () = 27
         exit
      endif
      f_restbox (ybox)
      set softseek on
      seek l_funit
      set softseek off
      if eof ()
         go bottom
      endif
      if .not. f_pick_f (02, 05, "", "Unit No.컴횸ic No.컴컴Vin " ;
         + "No.컴컴컴컴컴컴컴컴컴Make", ;
         "funit+[ ]+flic+[ ]+fvin+[ ]+fmake")
         loop
      endif
      do while .t.
         setcolor (gblueget)
         f_screen (1, "RAVHO")
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
         case ykeyin = "Q"
            exit
         endcase
      enddo
   enddo
enddo
close databases
erase (gstnpath + "RAVH.DBF")
erase (gstnpath + "X1.ntx")
