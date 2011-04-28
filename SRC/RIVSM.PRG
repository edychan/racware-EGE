* ===========================================================================
* scheduled maintenance
*
*
* date: 01/29/93
* edc: formatting bug 
*
* date: 02/01/93
* edc: fix rivsmf1
* date: 08/11/94
* edc: default mileage/date entries
* ===========================================================================
private ydbfld [4], ydbcol [4], ydbvld [4]
do while .t.
   xret2 = f_pushmenu (xoption1)
   if xret2 = 0
      exit
   endif
   xoption2 = substr (goption [xret2], 4)
   set key 28 to rivsmhlp
   do case
   case xret2 = 1
      f_clrscn ("VEHICLE MAINTENANCE FILE")
      rest from (gmempath + "ravms") additive
      @ 02, 02 say "Vehicle Number " get l_funit picture replicate ([!], 10) ;
         valid rivsm1 ()
      if f_rd () = 27 .or. empty (l_funit)
         exit
      endif
      f_use ("ravms")
      f_add ("ravms", "ravms", "rivsm2b")
      f_use ("ravm")
      seek l_funit
      if .not. eof ()
         f_fupdate ("C")
         reclock ()
         replace fexpense with fexpense + ravms->fcost + ravms->fothexp
         commit
         unlock
      endif
      close databases
   case xret2 = 2
      f_clrscn ("VEHICLE MAINTENANCE FILE")
      rest from (gmempath+"ravms") additive
      f_use ("ravms")
      go top
      if eof ()
         tone (500, 9)
         f_popup ("File is Empty! Press Any Key...",.t.)
         exit
      endif
      @ 02, 02 say "Vehicle Number " get l_funit picture replicate ([!], 10)
      if f_rd () = 27
         exit
      endif
      set softseek on
      seek l_funit
      set softseek off
      if eof ()
         tone (500, 9)
         f_popup ("No Matching Record. Press Any Key to Retry...",.t.)
         loop
      elseif found () .or. f_pick_f (02, 05, "", "Unit No.컴횯ate Out훁hop컴컴컴컴�" ;
            + "컴컴컴컴Due Back  Date In ", "funit+[ ]+dtoc(foutdt)+[ ]+" ;
            + "fshop+[ ]+dtoc(fduedt)+[ ]+dtoc(findt)")
         yamt = ravms->fcost + ravms->fothexp
         f_update ("ravms", "ravms", "rivsm2a", "rivsm2b")
         f_use ("ravm")
         seek l_funit
         if .not. eof ()
            f_fupdate ("C")
            reclock ()
            replace fexpense with fexpense - yamt + ;
                  (ravms->fcost + ravms->fothexp)
            commit
            unlock
         endif
         close databases
      endif
   case xret2 = 3
      f_clrscn ("SCHEDULE MAINTENANCE FILE")
      private yarray [4], yptr, yscn, yans1, yans2, yans3
      yarray [1] = "Range of Vehicle Numbers"
      yarray [2] = "Vehicle Class           "
      yarray [3] = "Unit Number             "
      yarray [4] = "Maint. Record Browsing  "
      yptr = f_pick_a (02, 05, "", "", yarray, 4, 1)
      do case 
      case yptr = 1
         f_use ("ravsm")
         setcolor (gsubcolor)
         yscn = f_box (02, 05, 10, 42)
         store space (10) to yans1, yans2
         yans4 = 0
         yans5 = date ()
         yans3 = "  "
         @ 03, 07 say "From Unit #           "
         @ 04, 07 say "To Unit #             "
         @ 05, 07 say "Service Code          "
         @ 06, 07 say "Last Performed Mileage"
         @ 07, 07 say "Last Performed Date   "
         @ 03, 31 get yans1 pict "!!!!!!!!!!"
         @ 04, 31 get yans2 pict "!!!!!!!!!!"
         @ 05, 31 get yans3 pict "!!" valid f_valid (f_verify ("RASVC", 1, yans3))
         @ 06, 31 get yans4 pict "999999"
         @ 07, 31 get yans5
         f_rd ()
         if f_confirm ("[C]onfirm  [Q]uit", "CQ") = "C"
            f_use ("ravm")
            set softseek on
            seek yans1
            set softseek off
            do while .not. eof () .and. funit <= yans2
               @ 09, 07 say "Updating unit: " + funit
               select ravsm
               seek ravm->funit + yans3
               if .not. found ()
                  append blank
                  reclock ()
                  replace fsvc with yans3, funit with ravm->funit
                  replace fmlgin with yans4
                  replace fdtin with yans5
                  commit
                  unlock
                  f_fupdate ("A")
               else
                  f_fupdate ("C")
                  reclock ()
                  replace fmlgin with max (yans4, fmlgin)
                  replace fdtin with max (yans5, fdtin)
                  commit
                  unlock
               endif
               select ravm
               skip
            enddo
            f_popup ("Process Done.  Press any key", .t.)
            setcolor (gbluecolor)
            f_restbox (yscn)
         endif
      case yptr = 2
         f_use ("ravsm")
         setcolor (gsubcolor)
         yscn = f_box (02, 05, 10, 42)
         store space (4) to yans1
         yans3 = "  "
         yans4 = 0
         yans5 = date ()
         @ 03, 07 say "Unit Class"
         @ 04, 07 say "Service Code"
         @ 05, 07 say "Last Performed Mileage"
         @ 06, 07 say "Last Performed Date   "
         @ 03, 31 get yans1 pict "!!!!"
         @ 04, 31 get yans3 pict "!!" valid f_valid (f_verify ("RASVC", 1, yans3))
         @ 05, 31 get yans4 pict "999999"
         @ 06, 31 get yans5 
         f_rd ()
         if f_confirm ("[C]onfirm  [Q]uit", "CQ") = "C"
            f_use ("ravm")
            set filter to fclass = yans1
            go top
            do while .not. eof ()
               @ 09, 07 say "Updating unit: " + funit
               select ravsm
               seek ravm->funit + yans3
               if .not. found ()
                  append blank
                  reclock ()
                  replace fsvc with yans3, funit with ravm->funit
                  replace fmlgin with yans4, fdtin with yans5
                  commit
                  unlock
                  f_fupdate ("A")
               else
                  f_fupdate ("C")
                  reclock ()
                  replace fmlgin with max (yans4, fmlgin)
                  replace fdtin with max (yans5, fdtin)
                  commit
                  unlock
               endif
               select ravm
               skip
            enddo
            f_popup ("Process Done.  Press any key", .t.)
            setcolor (gbluecolor)
            f_restbox (yscn)
         endif
      case yptr = 3
         f_use ("ravsm")
         f_use ("ravm", 1)
         rest from (gmempath + "ravsm") additive
         setcolor (gsubcolor)
         yscn = f_box (02, 01, 22, 78)
         l_funit = space (10)
         yans3 = "  "
         yans4 = 0
         yans5 = date ()
         @ 03, 63 say "Last Performed"
         * 01/29/93: edc change @ 04,07 to @ 04,03
         @ 04, 03 say "Unit No.컴횸ic No.컴컴Yr Make컴컴컴횺odel컴컴컴" + ;
               "Color컴컴훁VC횺iles컴Date컴"
         private yrow
         yrow = 5
         do while .t.
            @ yrow, 2 get l_funit pict "!!!!!!!!!!"
            if f_rd () = 27
               exit
            endif
            select ravm
            seek l_funit
            if .not. f_valid (found (), "Invalid Unit #!")
               loop
            endif
            @ yrow, 13 say flic+[ ]+fyear+[ ]+fmake+[ ]+fmodel+[ ]+fcolor
            @ yrow, 60 get yans3 pict "!!" valid rivsmf1 ()
            @ yrow, 63 get yans4 pict "999999"
            @ yrow, 70 get yans5 
            f_rd ()
            if f_confirm ("[C]onfirm  [V]oid", "CV") = "V"
               loop
            endif
            select ravsm
            seek ravm->funit + yans3
            if .not. found ()
               append blank
               reclock ()
               replace fsvc with yans3, funit with ravm->funit
               replace fmlgin with yans4, fdtin with yans5
               commit
               unlock
               f_fupdate ("A")
            else
               f_fupdate ("C")
               reclock ()
               replace fmlgin with yans4, fdtin with yans5
               commit
               unlock
            endif
            if yrow < 21
               yrow = yrow + 1
            else
               scroll (05, 06, 21, 67)
            endif
         enddo
         setcolor (gbluecolor)
         f_restbox (yscn)
      case yptr = 4      
         f_use ("ravsm")
         rest from (gmempath + "ravsm") additive
         ydbfld [1] = "funit"
         ydbfld [2] = "fsvc"
         ydbfld [3] = "fmlgin"
         ydbfld [4] = "fdtin"
         ydbcol [1] = "Unit"
         ydbcol [2] = "SVC"
         ydbcol [3] = "Last Performed Mileage"
         ydbcol [4] = "Last Performed Date"
         ydbvld [1] = "f_valid (f_verify ('RAVM', 1, l_funit))"
         ydbvld [2] = "f_valid (f_verify ('RASVC', 1, l_fsvc))"
         ydbvld [3] = ".t."
         ydbvld [4] = ".t."
         f_edit (ydbfld, ydbcol, 0, .t., ydbvld)
      endcase
      close databases
   case xret2 = 4
      do rivsc
   endcase
   set key 28 to
enddo
close database


******************************
procedure rivsmhlp

private yvar, ysel

ysel = select ()

yvar = alltrim (upper (readvar ()))
do case
case yvar = "L_FUNIT"
   if xret2 = 2
      f_use ("ravms")
   else
      f_use ("ravm")
   endif
   go top
   if f_valid (.not. eof (), "No Record Found...")
      if f_pick_f (02, 05, "", "Unit No.컴횸ic No.컴컴Year" ;
         + "Make 컴컴컴Model 컴컴Color", ;
         "funit+[ ]+flic+[ ]+fyear+[ ]+fmake+[ ]+fmodel+[ ]+fcolor")
         &yvar = funit
         keyboard chr (13)
      endif
   endif
case yvar = "L_FTYPE"
   f_use ("ravs")
   go top
   if eof ()
      tone (500,9)
      f_popup ("Status Code File is Empty. Press Any Key to Continue...",.t.)
   elseif f_pick_f (11, 32, "", "", "fcode+[->]+substr (fdesc,1,40)")
      &yvar = fcode
      keyboard chr (13)
   endif
case "L_FSVC" $ yvar .or. yvar = "YANS3"
   f_use ("rasvc")
   go top
   if eof ()
      tone (500,9)
      f_popup ("Service Code File is Empty. Press Any Key to Continue...",.t.)
   elseif f_pick_f (12,32,"","SVC횯escription 컴컴컴컴컴","fsvc+[ ]+fdesc")
      if yvar = "FSVC"
         f_fupdate ("C")
         select (ysel)
         replace fsvc with rasvc->fsvc
         commit
      else
         &yvar = rasvc->fsvc
      endif
      keyboard chr (13)
   endif
otherwise
   tone (500,9)
   f_popup ("No Help information for this Field. Press Any Key to Continue...",.t.)
endcase
select (ysel)
set cursor on


******************************
function rivsm1

f_use ("ravm")
seek l_funit
if eof ()
   tone (500,9)
   f_popup ("Vehicle Record Does Not Exist. Press Any Key to Retry...",.t.)
   return .f.
else
   l_fyear = ravm->fyear
   l_fmake = ravm->fmake
   l_fmodel = ravm->fmodel
   l_flic = ravm->flic
   l_fcolor = ravm->fcolor
   l_foutmile = ravm->fmileage
   l_foutdt = date ()
   return .t.
endif


******************************
procedure rivsm2a

l_findt = if (empty (l_findt), date (), l_findt)
l_finmile = if (l_finmile > 0, l_finmile, l_foutmile)

******************************
procedure rivsm2b

private i, yfld

if empty (l_fsvc1+l_fsvc2+l_fsvc3+l_fsvc4+l_fsvc5)
   return
endif
f_use ("ravsm")
for i = 1 to 5
   yfld="l_fsvc"+str (i,1)
   yfld=&yfld
   if .not. empty (yfld)
      seek l_funit+yfld
      if .not. eof () .and. fmlgin < l_foutmile
         f_fupdate ("C")
         reclock ()
         replace fmlgin with l_foutmile, fdtin with l_foutdt
         commit
         unlock
      endif
   endif
next


******************************
function rivsmf1

* 02/01/93 change from procedure to function - return .f. when code is invalid
if f_valid (f_verify ("RASVC", 1, yans3), "Invalid SVC Code !")
   select ravsm
   seek l_funit + yans3
   if found ()
      yans4 = fmlgin
      yans5 = fdtin
      setcolor (gsubget)
      @ yrow, 63 say yans4 pict "999999"
      @ yrow, 70 say yans5 
      setcolor (gsubcolor)
   endif
else
   return .f.
endif

return .t.
