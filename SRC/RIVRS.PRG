* ===========================================================================
* Record Vehcile Sale
*
* date: 05/01/91
* author: EDC
*
* revision
* 11/03/93
* edc: allow fuzzy search by unit#
* 09/25/95
* edc: keep vm record 
*
* ===========================================================================
private yarray[4], yptr, yret, ykey, yval, ytyp1, ytyp2, ytyp3, ytyp4
private ytyp5, ytyp6

do while .t.
   xret2 = f_pushmenu (xoption1)
   if xret2 = 0
      exit
   endif
   xoption2 = substr (goption [xret2], 4)
   set key 28 to rivrshlp
   do case
   case xret2 = 1
      f_use ("ravh")
      do while .t.
         f_clrscn ("VEHICLE SALE MAINTENANCE")
         rest from (gmempath + "ravh") additive
         @ 02, 02 say "Vehicle # " get l_funit picture "!!!!!!!!!!" ;
            valid rivrs1()
         if f_rd() = 27	.or. empty(l_funit)
            exit
         endif
         set exact on
         seek l_funit
         set exact off
         if eof()
            f_add ("ravh", "ravh", "rivrs2")
            loop
         else
            tone (500, 9)
            f_popup ("Duplicate Vehicle #. Press Any Key to Retry...",.t.)
         endif
      enddo
   case xret2 = 2
      f_use ("ravh")
      go top
      if .not. f_valid (.not. eof (), "No sold vehicle records found!")
         close databases
         return
      endif
      do while .t.
         f_clrscn ("VEHICLE SALE MAINTENANCE")
         rest from (gmempath + "ravh") additive
         @ 02, 02 say "Vehicle # " get l_funit picture "!!!!!!!!!!"
         if f_rd () = 27
            exit
         endif
         select ravh
         * 11/03/93 (edc)
         set softseek on
         seek l_funit
         set softseek off
         if f_pick_f (02, 05, "", "Unit No.컴횸ic No.컴컴Vin " ;
            + "No.컴컴컴컴컴컴컴컴컴Make", ;
            "funit+[ ]+flic+[ ]+fvin+[ ]+fmake")
            f_update ("ravh", "ravh", "rivrs3")
         endif
      enddo
   case xret2 = 3
      do rivbc
   endcase
   set key 28 to
enddo

release all like l_*
close database


******************************
procedure rivrshlp

private yvar

yvar = alltrim (upper(readvar()))
do case
case yvar = "L_FUNIT"
   if xret2 = 1
      f_use ("ravm", 3)
      seek "H"
      if .not. found ()
         tone (500,9)
         f_popup ("Vehicle NOT on HOLD status. Press Any Key to Retry...",.t.)
         use
      else
         if f_pick_f (02, 05, "", "Unit No.컴횸ic No.컴컴Vin " ;
               + "No.컴컴컴컴컴컴컴컴컴Make", ;
               "funit+[ ]+flic+[ ]+fvin+[ ]+fmake", "", "fstatus", "[H]")
            &yvar = ravm->funit
            keyboard chr(13)
         endif
         use
      endif
   else
      f_use ("RAVH", 1)
      set softseek on
      seek l_funit
      set softseek off
      if eof () 
         go bottom
      endif
      if f_pick_f (02, 05, "", "Unit No.컴횸ic No.컴컴Vin " ;
         + "No.컴컴컴컴컴컴컴컴컴Make", ;
         "funit+[ ]+flic+[ ]+fvin+[ ]+fmake")
         l_funit = funit
         keyboard chr (13)
      endif
   endif
      
case yvar = "L_FTYP"
   f_use ("RAVB")
   go top
   if .not. eof ()
      set softseek on
      seek upper (&yvar)
      if eof ()
         go bottom
      endif
      set softseek off
      if f_pick_f (15, 15, "", "Code횯escription컴컴컴컴컴컴컴컴컴컴컴Amount", ;
            "fcode+[ ]+f_truncate(fdesc,30)+[ ]+str(fdue,8,2)")
         &yvar = fcode
         keyboard chr (13)
      endif
   else
      f_valid (.f., "No Bonus Program Code Found!!!")
   endif
otherwise
   tone (500,9)
   f_popup ("No Help information for this Field. Press Any Key to Continue...",.t.)
endcase
set cursor on
return


******************************
function rivrs1

f_use ("ravm", 1)
seek l_funit
if .not. found ()
   tone (500,9)
   f_popup ("Vehicle Record Does Not Exist. Press Any Key to Retry...",.t.)
   use
   return .f.
elseif ravm->fstatus <> "H"
   tone (500,9)
   f_popup ("Vehicle NOT on HOLD status. Press Any Key to Retry...",.t.)
   use
   return .f.
else
   l_floc = ravm->foloc
   l_fyear = ravm->fyear
   l_fmake = ravm->fmake
   l_fmodel = ravm->fmodel
   l_fdesc = ravm->fdesc
   l_flic = ravm->flic
   l_fvin = ravm->fvin
   l_fpuramt = ravm->fpuramt
   l_fpurdt = ravm->fpurdt
   l_fmileage = fmileage
   l_ftyp1 = fcode1
   l_ftyp2 = fcode2
   l_ftyp3 = fcode3
   l_ftyp4 = fcode4
   l_ftyp5 = fcode5
   ytyp1 = l_ftyp1
   ytyp2 = l_ftyp2
   ytyp3 = l_ftyp3
   ytyp4 = l_ftyp4
   ytyp5 = l_ftyp5
   l_fdue1 = fdue1
   l_fdue2 = fdue2
   l_fdue3 = fdue3
   l_fdue4 = fdue4
   l_fdue5 = fdue5
   l_fpaid1 = fpaid1
   l_fpaid2 = fpaid2
   l_fpaid3 = fpaid3
   l_fpaid4 = fpaid4
   l_fpaid5 = fpaid5
   use
   return .t.
endif


******************************
procedure rivrs2

* delete vehicle master record
f_use ("ravm", 1)
seek l_funit
if found ()
   f_fupdate ("D")
   reclock ()
   delete
   unlock
endif
use

* change vehicle status to sold
*f_use ("ravm", 1)
*seek l_funit
*if found ()
*   l_fstatus = "S"
*   reclock ()
*   replace ravm->fstatus with l_fstatus
*   unlock
*   f_fupdate ("C")
*endif
*use

* delete vehicle service record
*f_use ("ravms")
*seek l_funit
*do while .not. eof() .and. funit = l_funit
*   f_fupdate ("D")
*   reclock ()
*   delete
*   unlock
*   skip
*enddo
*use   

******************************
procedure rivrs3

ytyp1 = l_ftyp1
ytyp2 = l_ftyp2
ytyp3 = l_ftyp3
ytyp4 = l_ftyp4
ytyp5 = l_ftyp5


******************************
function rivrsf1

return .t.


******************************
function rivrsf2

parameters xcnt
private ystr, ystr1
ystr = "l_ftyp" + str (xcnt, 1)
if empty (&ystr)
   keyboard chr (18)
   return .t.
endif
ystr1 = "ytyp" + str (xcnt, 1)
if &ystr1 = &ystr
   return .t.
endif
f_use ("RAVB")
seek &ystr
if f_valid (found ())
   ystr = "l_fdue" + str (xcnt, 1)
   &ystr = fdue
   return .t.
else
   return .f.
endif

