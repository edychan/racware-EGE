* ===========================================================================
* Corporate File Maint. Module
*
* 05/01/92
* Author: EDC
*
* Revision:
* 03/30/93: (edc) create customer info. into a/r
* 
* ===========================================================================
do while .t.
   xret2 = f_pushmenu (xoption1)
   if xret2 = 0
      exit
   endif
   xoption2 = substr (goption [xret2], 4)
   f_clrscn ("CORPORATE FILE MAINTENANCE")
   rest from (gmempath+"racrp") additive
   set key 28 to rcrphlp
   do case
   case xret2 = 1
      f_use ("racrp")
      do while .t.
         @ 02, 03 say "Account Number " get l_fcrpno picture "!!!!!!!!!!!!!!!"
         if f_rd() = 27 .or. empty(l_fcrpno)
            exit
         endif
         set exact on
         seek l_fcrpno
         set exact off
         if eof()
            l_fmoddt = date()
            f_add ("racrp", "racrp", "rmkcrp1a")
            use
            exit
         else
            tone (500, 9)
            f_popup ("Duplicate Corporate #. Press Any Key to Retry...",.t.)
         endif
      enddo
   case xret2 = 2
      f_use ("racrp")
      if .not. eof()
         declare yarray [2]
         yarray[1] = " Account Number "
         yarray[2] = " Corporate Name "
         yret = f_pick_a (02, 05, "", "", yarray, 2, 1)
         if yret = 0
            loop
         endif
         if yret = 1
            yval = space (15)
         else
            yval = space (25)
         endif
         @ 02, 05 say yarray[yret] get yval
         read
         yval = upper (yval)
         set softseek on
         set exact off
         select racrp
         set order to (yret)
         seek yval
         set softseek off
         if eof()
            tone (500, 9)
            f_popup ("No Matching Record. Press Any Key to Retry...",.t.)
            select racrp
            use
            loop
         elseif (yret = 1 .and. found ()) .or. ;
               f_pick_f (02, 3, "", "Corp. Number컴컴Company Name컴컴컴컴컴" + ;
               "컴컴Contact컴컴컴컴컴컴컴Rate", "fcrpno+[ ]+fcompany+[ ]+" + ;
               "fcontact+[ ]+frate")
            f_update ("racrp", "racrp", "", "rmkcrp1")
            use
         endif
      else
         select racrp
         use
         tone (500, 9)
         f_popup ("File is empty. Press Any Key...",.t.)
      endif
   endcase
   set key 28 to
enddo

release all like l_*
close database


******************************
procedure rcrphlp

private yvar, yarray[4], yptr

yvar = alltrim (upper(readvar()))
do case
case yvar = "L_FTYPE"
   yarray[1] = " [C]orporate     "
   yarray[2] = " [T]our operator "
   yarray[3] = " [O]ther         "
   yptr = 1
   yptr = f_pick_a (11,32,"","",yarray,3,yptr)
   if yptr > 0
      &yvar = substr(yarray[yptr],3,1)
      keyboard chr(13)
   endif
otherwise
   tone (500,9)
   f_popup ("No Help information for this Field. Press Any Key to Continue...",.t.)
endcase
set cursor on
return


******************************
procedure rmkcrp1

l_fmoddt = max (date (), l_fmoddt)

if .not. garpost .or. empty(l_fdbacct)
   return
endif   

yarcus = gaccpath + "arcus" + gfileno
if file (yarcus + ".dbf") .and. file (yarcus + ".ntx")
   select 0
   use &yarcus index &yarcus alias arcus
else
   return
endif

* update customer info. in a/r 
select arcus
seek l_fdbacct
if .not. eof ()
   reclock ()
   replace fcompany with l_fcompany
   replace faddr1 with l_faddr
   replace fcity with l_fcity, fstate with l_fstate
   replace fzip with l_fzip, fphone with l_fphone
   commit
   unlock
endif

select arcus
use
return

******************************
procedure rmkcrp1a

if .not. garpost .or. empty(l_fdbacct)
   return
endif   

yarsys = gaccpath + "arsys" + gfileno
if file (yarsys + ".dbf")
   select 0
   use &yarsys alias arsys
   yaracc = substr (fglacc, 166, 14)
   use
else
   return
endif

yarcus = gaccpath + "arcus" + gfileno
if file (yarcus + ".dbf") .and. file (yarcus + ".ntx")
   select 0
   use &yarcus index &yarcus alias arcus
else
   return
endif

* add customer info. into a/r 
select arcus
seek l_fdbacct
if .not. found ()
   append blank
   reclock ()
   replace fcustno with l_fdbacct
   replace fcompany with l_fcompany
   replace faddr1 with l_faddr
   replace fcity with l_fcity, fstate with l_fstate
   replace fzip with l_fzip, fphone with l_fphone
   replace fpaytype with "7", factive with .t., faracc with yaracc
   commit
   unlock
endif

select arcus
use
return
