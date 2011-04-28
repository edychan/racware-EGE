do while .t.
   xret2 = f_pushmenu (xoption1)
   if xret2 = 0
      exit
   else
      xoption2 = substr (goption [xret2], 4)
      do case
      case xret2 = 1
         do rrnvus
      case xret2 = 2
         do rrnvut
      case xret2 = 3
         do rrnvud
      endcase
   endif
enddo


******************************
procedure rrnvuf1

private yvar, yarray[4], yptr

yvar = alltrim (upper(readvar()))
do case
case yvar = "YUNIT"
   f_use ("ravm")
   go top
   set softseek on
   seek &yvar
   if eof()
      tone (500,9)
      f_popup ("Vehicle File is Empty. Press Any Key to Continue ...",.t.)
   elseif f_pick_f (03, 03, "", "Unit No.ÄÄÄLic No.ÄÄÄÄYear" ;
         + "Make ÄÄÄÄÄÄModel ÄÄÄÄColorÄÄÄÄÄStatÄÄÄLoc", ;
         "funit+[ ]+flic+[ ]+fyear+[ ]+fmake+[ ]+fmodel+[ ]+fcolor+[ ]+fstatus+[ ]+freason+[   ]+substr(floc,1,4)")
      &yvar = ravm->funit
      keyboard chr(13)
   endif
   set softseek off
case yvar = "YLOC"
   f_use ("raloc", 1)
   set softseek on
   seek &yvar
   go top
   if f_pick_f (03, 05, "", "", "floc+[->]+substr(fname,1,25)")
      &yvar = raloc->floc
      keyboard chr(13)
   endif
   select ravm
   set softseek off
case yvar = "YSTAT"
   yarray[1] = " [A]vailable        "
   yarray[2] = " [O]n Rent          "
   yarray[3] = " [I]n But Not ready "
   yarray[4] = " [H]old             "
   yptr = at (&yvar, "AOIH")
   if yptr = 0
      yptr = 1
   endif
   yptr = f_pick_a (03,05,"","",yarray,4,yptr)
   if yptr > 0
      &yvar = substr(yarray[yptr],3,1)
      keyboard chr(13)
   endif
   select ravm
case yvar = "YREASON"
   f_use ("ravs")
   go top
   if eof()
      tone (500,9)
      f_popup ("Reason Code File is Empty. Press Any Key to Continue...",.t.)
      use
   elseif f_pick_f (03, 05, "", "", "fcode+[->]+fdesc")
      &yvar = ravs->fcode
      use
      keyboard chr(13)
   endif
   select ravm
otherwise
   tone (500,9)
   f_popup ("No Help information for this Field. Press Any Key to Continue...",.t.)
endcase
set cursor on

