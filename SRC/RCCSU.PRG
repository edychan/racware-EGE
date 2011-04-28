if empty (gccnet)
   return
endif
f_clrscn ()
f_popup ("Please Wait While Retrieving Setup Information...", .f.)
f_use ("RAMDMSU")
f_use ("RACCSU")
restore from (gmempath + "RACCSU") additive

f_use ("RASTN")
seek f_truncate (gstation, 8)
l_finitstr = finitstr
l_fmodem = fmodem
l_fcomm = fcomm
l_fbaud = fbaud
l_ftimeout = ftimeout
select ramdmsu
seek l_fmodem
if .not. found ()
   go top
endif
f_getscn ("RAMDM" + gccnet)
l_floc = gloc
@ 02, 61 say gstation
f_use ("RALOC", 1)
set key 28 to rccsuhlp
do while .t.
   @ 02, 22 get l_floc pict "!!!!!!!!!!" 
   if f_rd () = 27
      close database
      set key 28 to
      return
   endif
   if f_valid (l_floc $ gusrloc)   
      exit
   endif
enddo
select raloc
use

select raccsu
seek l_floc
if found ()
   yccfnd = .t.
   f_retrieve ()
else
   yccfnd = .f.
endif

f_popback ()
do while .t.
   f_screen (1, "RAMDM" + gccnet)
   f_rd ()
   ykey = f_confirm ("[C]onfirm  [E]dit  [I]gnore Changes", "CEI")
   do case
   case ykey = "C"
      select rastn
      reclock ()
      replace finitstr with l_finitstr
      replace fmodem with l_fmodem
      replace fcomm with l_fcomm
      replace fbaud with l_fbaud
      replace ftimeout with l_ftimeout
      commit
      unlock
      select raccsu
      if yccfnd 
         f_fupdate ("C")            
         f_replace ()
      else
         append blank
         f_replace ()
         f_fupdate ("A")
      endif
      exit
   case ykey = "E"
      loop
   case ykey = "I"
      exit
   endcase
enddo
set key 28 to
close databases


******************************
procedure rccsuhlp

private yvar, yarray [4], yptr

yvar = alltrim (upper (readvar ()))
do case
case yvar = "L_FLOC"
   select raloc
   if f_pick_f (1, 55, "", "", "FLOC")
      l_floc = floc
   endif
   keyboard chr (13)
case yvar = "L_FMODEM"
   select ramdmsu
   if f_pick_f (3, 55, "", "", "FMODEM")
      l_fmodem = ramdmsu->fmodem
      l_finitstr = ramdmsu->finit
   endif
   keyboard chr (13)
case yvar = "L_FCOMM"
   yarray [1] = "0"
   yarray [2] = "1"
   yarray [3] = "2"
   yarray [4] = "3"
   yptr = f_pick_a (5, 27, "", "", YARRAY, 4, ;
      ascan (yarray, str (l_fcomm, 1)))
   if yptr > 0
      l_fcomm = val (yarray [yptr])
      keyboard chr (13)
   endif
case yvar = "L_FBAUD"
   yarray [1] = " 300"
   yarray [2] = "1200"
   yarray [3] = "2400"
   yptr = f_pick_a (5, 27, "", "", YARRAY, 3, ;
      ascan (yarray, str (l_fbaud, 4)))
   if yptr > 0
      l_fbaud = val (yarray [yptr])
      keyboard chr (13)
   endif
case yvar = "L_FPARITY"
   yarray [1] = "1"
   yarray [2] = "2"
   yptr = f_pick_a (5, 27, "", "", YARrAY, 2, ;
      ascan (yarray, str (l_fparity, 1)))
   if yptr > 0
      l_fparity = val (yarray [yptr])
      keyboard chr (13)
   endif
case yvar = "L_FSTOPBIT"
   yarray [1] = "1"
   yarray [2] = "2"
   yptr = f_pick_a (5, 27, "", "", YARRAY, 2, ;
      ascan (yarray, str (l_fstopbit, 1)))
   if yptr > 0
      keyboard chr (13)
      l_fstopbit = val (yarray [yptr])
   endif
case yvar = "L_FDATABIT"
   yarray [1] = "7"
   yarray [2] = "8"
   yptr = f_pick_a (5, 27, "", "", YARRAY, 2, ;
      ascan (yarray, str (l_fdatabit, 1)))
   if yptr > 0
      keyboard chr (13)
      l_fdatabit = val (yarray [yptr])
   endif
endcase
set cursor on

