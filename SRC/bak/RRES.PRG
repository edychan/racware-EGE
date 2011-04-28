* ===========================================================================
* Reservation module 
*
* date: 05/01/91
* author: KST
*
* revision
* date: 12/4/93
* edc: take out resv grid table <F6>
* ===========================================================================
do while .t.
   xret1 = f_pushmenu (xoption0)
   if xret1 = 0
      exit
   endif
   xoption1 = substr (goption [xret1], 4)
   do case
   case xret1 = 1 .or. xret1 = 2
      do rrvfm with if (xret1 = 1, "A", "U")
   case xret1 = 3
      f_clrscn ("TRAVEL AGENT FILE MAINTENANCE")
      rest from (gmempath+"raagnt") additive
      f_use ("raagnt")
      do while .t.
         @ 03, 03 say "ATC Number " get l_fatc picture "!!!!!!!!!!"
         if f_rd() = 27 .or. empty(l_fatc)
            exit
         endif
         set exact on
         seek l_fatc
         set exact off
         if eof()
            set key 28 to ragnthlp
            l_fmoddt = date()
            f_add ("raagnt", "raagnt")
            use
            set key 28 to
            exit
         else
            tone (500, 9)
            f_popup ("Duplicate ATC #. Press Any Key to Retry ...",.t.)
         endif
      enddo
   case xret1 = 4
      f_clrscn ("TRAVEL AGENT FILE MAINTENANCE")
      declare yarray [2]
      rest from (gmempath+"raagnt") additive
      f_use ("RAAGNT")
      go top
      if eof ()
         f_popup ("No Reservations Found!!! Press Any Key to Continue...", .t.)
         close databases
         return
      endif
      yarray [1] = " ATC Number ......... "
      yarray [2] = " Agent Name ......... "
      yptr = f_pick_a (02, 05, "", "", YARRAY, 2, 1)
      if yptr = 0
         close databases
         return
      endif

      ycolor = setcolor (gsubcolor)
      yscn = f_box (2, 21, 4, 62)
      do case
      case yptr = 1
         ykey = "l_fatc"
         ytitle = "ATC No.컴컴Agent Name"
         yexp = "fatc + [ ] + fcompany"
         @ 3, 23 say "ATC Number ................"
         @ 3, 51 get l_fatc pict "!!!!!!!!!!"
      case yptr = 2
         ykey = "upper (l_fcompany)"
         ytitle = "Agent Name컴컴컴컴컴횫TC No."
         yexp = "fcompany + [ ] + fatc"
         @ 3, 23 say "Agent Name "
         @ 3, 36 get l_fcompany
      endcase
      if f_rd () = 27
         setcolor (ycolor)
         close databases
         return
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
      if (yptr = 1 .and. found ()) .or. f_pick_f (02, 03, "", ytitle, yexp)
         f_retrieve ()
         set key 28 to ragnthlp
         f_update ("raagnt", "raagnt", "", "rres1")
         set key 28 to
      endif
      close databases
   case xret1 = 5
      do rrvpj
   case xret1 = 6
      do rrvrg
   case xret1 = 7
      do rrvcln
   endcase
enddo
release all like l_*
close database


******************************
procedure ragnthlp

tone (500,9)
f_popup ("No Help information for this Field. Press Any Key to Continue...",.t.)
set cursor on
return


******************************
procedure rres1

l_fmoddt = max (date (), l_fmoddt)

