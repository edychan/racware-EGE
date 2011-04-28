* ===========================================================================
* setup vehicle file
*
* date: 05/01/91
* author: EDC
*
* revision
* 04/21/93
* edc: add foreign location
* 05/09/93
* edc: take out res grid table
* ===========================================================================
private yarray[4], yptr, yret, ykey, yval
ybonus = .f.
rest from (gmempath+"ravm") additive
do while .t.
   xret2 = f_pushmenu (xoption1)
   if xret2 = 0
      exit
   endif
   xoption2 = substr (goption [xret2], 4)
   set key 28 to rivimhlp
   set key -1 to rivimget
   do case
   case xret2 = 1
      do while .t.
         f_use ("ravm")
         f_clrscn ("VEHICLE FILE MAINTENANCE")
         @ 02, 02 say "Vehicle # " get l_funit picture "!!!!!!!!!!"
         if f_rd() = 27	.or. empty(l_funit)
            exit
         endif
         set exact on
         seek l_funit
         set exact off
         if eof()
            l_fchgdt = date ()
            f_add ("ravm", "ravm", "rivimfa")
            loop
         else
            tone (500, 9)
            f_popup ("Duplicate Vehicle #. Press Any Key to Retry ...",.t.)
         endif
      enddo
   case xret2 = 2
      do while .t.
         f_use ("ravm")
         set filter to
         f_clrscn ("VEHICLE FILE MAINTENANCE")
         yarray[1] = " Vehicle # ..... "
         yarray[2] = " License # ..... "
         yarray[3] = " VIN # ......... "
         yarray[4] = " Make .......... "
         yptr = 1
         yret = f_pick_a (02, 05, "", "", yarray, 4, yptr)
         if yret = 0
            exit
         endif
         if yret = 3
            yval = space (24)
         else
            yval = space (10)
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
            f_use ("RAVM",1)
            seek yval
            yfnd = (yval == alltrim (funit))
         case yret = 2
            f_use ("ravm",2)
            seek yval
            yfnd = (yval == alltrim (flic))
         case yret = 3
            set filter to yval $ fvin
            go top
            yfnd = (yval == alltrim (fvin))
         case yret = 4
            set filter to yval $ fmake
            go top
         endcase
         set softseek off
         if eof()
            tone (500, 9)
            f_popup ("No Matching Record. Press Any Key to Retry ...",.t.)
            loop
         endif
         if yfnd .or. f_pick_f (02, 05, "", "Unit No.컴횸ic No.컴컴Vin " ;
               + "No.컴컴컴컴컴컴컴컴컴Make", ;
               "funit+[ ]+flic+[ ]+fvin+[ ]+fmake")
            f_update ("ravm", "ravm", "", "rivimfu", "rivimd")
         endif
      enddo
   endcase
   set key 28 to
   set key -1 to
enddo
release all like l_*
close database


******************************
procedure rivimhlp

private yvar

yvar = alltrim (upper(readvar()))
do case
case yvar $ "L_FLOC;L_FOLOC"
   f_use ("raloc")
   set filter to floc $ gusrloc
   go top
   if f_pick_f (03, 37, "", "", "floc+[->]+substr(fname,1,25)")
      &yvar = raloc->floc
      keyboard chr(13)
   endif
   select raloc
   set filter to
   use
case "L_FSVC"	$ yvar
   f_use	("rasvc")
   if f_pick_f (10, 35, "", "", "fsvc+[->]+substr(fdesc,1,35)")
      &yvar = rasvc->fsvc
      keyboard chr(13)
   endif
   select rasvc
   use
otherwise
   tone (500,9)
   f_popup ("No Help information for this Field. Press Any Key to Continue...",.t.)
endcase
set cursor on
return


******************************
function rivvld1

if .not. ybonus .and. l_fbonus
   do rivimget
endif
ybonus = l_fbonus
return .t.


******************************
procedure rivimget

private yscn, ydate1, ydate2, ycolor, yptr
ycolor = setcolor (gsubcolor)
yscn = f_box (9, 48, 16, 75)
@ 10, 50 say "Code   Amt Due  Amt Paid"
setcolor (gsubget)
@ 11, 50 say l_fcode1
@ 11, 56 say l_fdue1 picture "99999.99"
@ 11, 66 say l_fpaid1 picture "99999.99"
@ 12, 50 say l_fcode2
@ 12, 56 say l_fdue2 picture "99999.99"
@ 12, 66 say l_fpaid2 picture "99999.99"
@ 13, 50 say l_fcode3
@ 13, 56 say l_fdue3 picture "99999.99"
@ 13, 66 say l_fpaid3 picture "99999.99"
@ 14, 50 say l_fcode4
@ 14, 56 say l_fdue4 picture "99999.99"
@ 14, 66 say l_fpaid4 picture "99999.99"
@ 15, 50 say l_fcode5
@ 15, 56 say l_fdue5 picture "99999.99"
@ 15, 66 say l_fpaid5 picture "99999.99"

yptr = 1
do while .t.
   do case
   case yptr = 1
      f_getfld (@l_fcode1, 11, 50, "W/N", 0, replicate ("X", 4), .t., ;
         "rivimh1")
      if empty (l_fcode1)
         exit
      endif
      if .not. f_valid (f_verify ("RAVB", 1, upper (l_fcode1)))
         loop
      endif
      l_fdue1 = ravb->fdue
   case yptr = 2
      f_getnum (@l_fdue1, 11, 56, "W/N", "99999.99", .t.)
   case yptr = 3
      f_getnum (@l_fpaid1, 11, 66, "W/N", "99999.99", .t.)
   case yptr = 4
      f_getfld (@l_fcode2, 12, 50, "W/N", 0, replicate ("X", 4), .t., ;
         "rivimh1")
      if empty (l_fcode2)
         exit
      endif
      if .not. f_valid (f_verify ("RAVB", 1, upper (l_fcode2)))
         loop
      endif
      l_fdue2 = ravb->fdue
   case yptr = 5
      f_getnum (@l_fdue2, 12, 56, "W/N", "99999.99", .t.)
   case yptr = 6
      f_getnum (@l_fpaid2, 12, 66, "W/N", "99999.99", .t.)
   case yptr = 7
      f_getfld (@l_fcode3, 13, 50, "W/N", 0, replicate ("X", 4), .t., ;
         "rivimh1")
      if empty (l_fcode3)
         exit
      endif
      if .not. f_valid (f_verify ("RAVB", 1, upper (l_fcode3)))
         loop
      endif
      l_fdue3 = ravb->fdue
   case yptr = 8
      f_getnum (@l_fdue3, 13, 56, "W/N", "99999.99", .t.)
   case yptr = 9
      f_getnum (@l_fpaid3, 13, 66, "W/N", "99999.99", .t.)
   case yptr = 10
      f_getfld (@l_fcode4, 14, 50, "W/N", 0, replicate ("X", 4), .t., ;
         "rivimh1")
      if empty (l_fcode4)
         exit
      endif
      if .not. f_valid (f_verify ("RAVB", 1, upper (l_fcode4)))
         loop
      endif
      l_fdue4 = ravb->fdue
   case yptr = 11
      f_getnum (@l_fdue4, 14, 56, "W/N", "99999.99", .t.)
   case yptr = 12
      f_getnum (@l_fpaid4, 14, 66, "W/N", "99999.99", .t.)
   case yptr = 13
      f_getfld (@l_fcode5, 15, 50, "W/N", 0, replicate ("X", 4), .t., ;
         "rivimh1")
      if empty (l_fcode5)
         exit
      endif
      if .not. f_valid (f_verify ("RAVB", 1, upper (l_fcode5)))
         loop
      endif
      l_fdue5 = ravb->fdue
   case yptr = 14
      f_getnum (@l_fdue5, 15, 56, "W/N", "99999.99", .t.)
   case yptr = 15
      f_getnum (@l_fpaid5, 15, 66, "W/N", "99999.99", .t.)
   endcase
   ykey = lastkey ()
   if (ykey = 24 .or. ykey = 13) .and. yptr < 14
      yptr = yptr + 1
   elseif ykey = 5 .and. yptr > 1
      yptr = yptr - 1
   elseif ykey = 27 .or. ykey = 13 .or. ykey = 3 .or. ykey = 18
      exit
   endif
enddo
f_restbox (yscn)
setcolor (ycolor)


******************************
procedure rivimh1

f_use ("RAVB")
go top
if .not. eof ()
   set softseek on
   seek upper (yfield)
   if eof ()
      go bottom
   endif
   set softseek off
   if f_pick_f (9, 1, "", "Code횯escription컴컴컴컴컴컴컴컴컴컴컴Amount", ;
         "fcode+[ ]+f_truncate(fdesc,30)+[ ]+str(fdue,8,2)")
      ytmpfld = fcode
      keyboard chr (13)
   endif
else
   f_valid (.f., "No Bonus Program Code Found!!!")
endif


******************************
procedure rivimfa

* 04/21/93: (edc) add foreign location
f_use ("raloc")
seek l_foloc
if .not. eof()
   l_fforeign = fforeign
endif
*
******************************
procedure rivimfu

* 04/21/93: (edc) add foreign location
f_use ("raloc")
seek l_foloc
if .not. eof()
   l_fforeign = fforeign
endif
*
if ravm->fstatus = "H" .and. l_fstatus <> "H"
   l_freason = " "
endif
l_fchgdt = date ()

*if .not. ravm->fresv .and. l_fresv
*   if f_confirm ("Do you want to update reservation grid table? [Y/N]", ;
*         "YN") = "Y"
*      f_popup ("Please wait...", .f.)
*      f_use ("RAVRES")
*      seek l_funit
*      do while funit = l_funit .and. .not. eof ()
*         if f_clrskip () = 0
*            exit
*         endif
*      enddo
*      f_use ("raagr", 3)
*      seek l_funit
*      do while funit = l_funit .and. .not. eof ()
*         select ravres
*         f_findblank ()
*         replace funit with l_funit, ffrom with raagr->fdateout
*         replace ffromtime with raagr->ftimeout
*         replace ftotime with raagr->ftimein
*         replace fto with raagr->fdatein, ftype with "A"
*         replace fnumber with raagr->floc + str (raagr->frano, 6)
*         commit
*         unlock
*         f_fupdate ("A")
*         select raagr
*         skip
*      enddo
*      use
*      f_use ("rares", 2)
*      seek "O"
*      do while fresvstat = "O" .and. .not. eof ()
*         if funit = l_funit
*            select ravres
*            f_findblank ()
*            replace funit with l_funit, ffrom with rares->fdateout
*            replace ffromtime with rares->ftimeout
*            replace ftotime with rares->ftimein
*            replace fto with rares->fdatein, ftype with "A"
*            replace fnumber with rares->fresvno
*            commit
*            unlock
*            f_fupdate ("A")
*            select rares
*         endif
*         skip
*      enddo
*      use
*      select ravres
*      use
*      f_popback ()
*   endif
*elseif ravm->fresv .and. .not. l_fresv
*   if f_confirm ("Do you want to clear reservation grid table? [Y/N]", ;
*         "YN") = "Y"
*      f_popup ("Please wait...", .f.)
*      f_use ("RAVRES")
*      seek l_funit
*      do while funit = l_funit .and. .not. eof ()
*         if f_clrskip () = 0
*            exit
*         endif
*      enddo
*      use
*      f_popback ()
*   endif
*endif

******************************
procedure rivimd

f_popup ("Please wait...", .f.)
*f_use ("RAVRES")
*seek l_funit
*do while funit = l_funit .and. .not. eof ()
*   if f_clrskip () = 0
*      exit
*   endif
*enddo
*use

f_use ("raagrx")
append blank
reclock ()
replace fdatein with ravm->fpurdt, fdateout with date ()
replace flname with "DELETE: " + gusrid, floc with gloc
replace fcity with ravm->foloc, fmlgin with ravm->fmileage
replace frano with 0, fulic with ravm->flic, ftimeout with time ()
replace funit with ravm->funit
commit
unlock
f_fupdate ("A")
use
select ravm
f_fupdate ("D")
reclock ()
delete
commit
unlock
f_popback ()

