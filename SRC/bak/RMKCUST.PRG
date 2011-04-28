private yarray[3], yptr, yret, ykey, yval

do while .t.
   xret2 = f_pushmenu (xoption1)
   if xret2 = 0
      exit
   endif
   xoption2 = substr (goption [xret2], 4)
   f_clrscn ("CUSTOMER FILE MAINTENANCE")
   rest from (gmempath+"racust") additive
   set key 28 to rcusthlp
   do case
   case xret2 = 1
      f_use ("racust", 2)
      do while .t.
         @ 02, 05 say "Account Number " get l_fcustno ;
            picture "!!!!!!!!!!!!!!!"
         if f_rd() = 27 .or. empty(l_fcustno)
            exit
         endif
         set exact on
         seek l_fcustno
         set exact off
         if eof()
            l_fmoddt = date()
            f_add ("racust", "racust")
            close databases
            exit
         else
            tone (500, 9)
            f_popup ("Duplicate Customer #. Press Any Key to Retry ...",.t.)
         endif
      enddo
   case xret2 = 2
      f_use ("racust",2)
      go top
      if .not. eof()
         yarray[1] = " Account Number "
         yarray[2] = " Last Name..... "
         yarray[3] = " First Name.... "
         yret = f_pick_a (02, 05, "", "", yarray, 3, 1)
         if yret = 0
            loop
         endif
         yval = space (15)
         @ 02, 05 say yarray[yret] get yval
         read
         yval = upper (yval)
         if yret = 1
            f_use ("racust", 2)
         elseif yret = 2
            f_use ("racust", 1)
         else
            f_use ("racust", 4)
         endif
         set softseek on
         set exact off
         seek yval
         set softseek off
         if eof()
            tone (500, 9)
            f_popup ("No Matching Record. Press Any Key to Retry...",.t.)
            close databases
            loop
         endif
         if (found () .and. yret = 1) .or. ;
               f_pick_f (02, 3, "", "Customer No.컴컴Last Name컴컴컴First " + ;
               "Name컴훀ate", "fcustno+[ ]+flname+[ ]+ffname+[ ]+frate")
            f_update ("racust", "racust", "", "rmkcust1")
            close databases
         endif
      else
         close databases
         tone (500, 9)
         f_popup ("File is empty. Press Any Key...",.t.)
      endif
   endcase
   set key 28 to
enddo
release all like l_*
close database


******************************
procedure rcusthlp

tone (500,9)
f_popup ("No Help information for this Field. Press Any Key to Continue...",.t.)
set cursor on
return


******************************
procedure rmkcust1

l_fmoddt = max (date (), l_fmoddt)


******************************
function rmkcustf

if empty (l_fcrpno)
   return .t.
endif
f_use ("racrp", 1)
seek l_fcrpno
if found ()
   l_fcompany = fcompany
   l_fcaddr = faddr
   l_fccity = fcity
   l_fcstate = fstate
   l_fczip = fzip
   l_frate = frate
   l_fdisc = fdisc
   l_fcphone = fphone
   l_fdbacct = fdbacct
   l_fcctype = fcctype
   l_fccnum = fccnum
endif
select racust
return .t.

