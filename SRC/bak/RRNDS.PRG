parameter xparam
if pcount () >= 1
   xparam = .t.
else
   xparam = .f.
endif
private yarray[4], yptr, yret, ykey, yval, yval1, yfullscn, ycolor, yptr1
private yord, yrecno, yfilter, ysel, yloc, ylocfilter

blimempak (-1)
save screen to yfullscn

f_clrscn ("Display Vehicle Status")
ysel = select ()
ycolor = setcolor (gsubcolor)
f_use ("ravm")
yfilter = dbfilter ()
yord = indexord ()
yrecno = recno ()
yloc = gloc
set filter to
do while .t.
   go top
   if .not. eof ()
      yarray[1] = " Vehicle # ..... "
      yarray[2] = " Class/Status .. "
      yarray[3] = " License ....... "
      yptr = 1
      yret = f_pick_a (02, 05, "", "", yarray, 3, yptr)
      if yret = 0
         exit
      endif
      do case
      case yret = 1
         yval = space (10)
      case yret = 2
         yval = space (4)
         @ 03, 23 say "/"
         yval1 = " "
      case yret = 3
         yval = space (15)
      endcase
      f_box (2, 1, 5, 50)
      @ 03, 02 say yarray [yret]
      @ 04, 02 say " Location ...... "
      if yret = 2
         yptr1 = 1
         do while .t.
            do case
            case yptr1 = 1
               f_getfld (@yval, 3, 19, "", 4, "!!!!", .t.)
            case yptr1 = 2
               f_getfld (@yval1, 3, 24, "", 1, "!", .t.)
            case yptr1 = 3
               f_getfld (@yloc, 4, 19, "", 1, "!!!!!!!!!!", .t.)
            endcase
            ykey = lastkey ()
            if (ykey = 24 .or. ykey = 13) .and. yptr1 < 3
               yptr1 = yptr1 + 1
            elseif ykey = 5 .and. yptr1 > 1
               yptr1 = yptr1 - 1
            elseif ykey = 27 .or. ykey = 13 .or. ykey = 3 .or. ykey = 18
               exit
            endif
         enddo
         if ykey = 27
            loop
         endif
      else
         yptr1 = 1
         do while .t.
            do case
            case yptr1 = 1
               f_getfld (@yval, 3, 19, "", len (yval), ;
                  replicate ([!], len (yval)))
            case yptr1 = 2
               f_getfld (@yloc, 4, 19, "", 1, "!!!!!!!!!!", .t.)
            endcase
            ykey = lastkey ()
            if (ykey = 24 .or. ykey = 13) .and. yptr1 < 2
               yptr1 = yptr1 + 1
            elseif ykey = 5 .and. yptr1 > 1
               yptr1 = yptr1 - 1
            elseif ykey = 27 .or. ykey = 13 .or. ykey = 3 .or. ykey = 18
               exit
            endif
         enddo
         if ykey = 27
            loop
         endif
      endif

      yval = upper (trim (yval))
      if empty (yloc)
         ylocfilter = "floc $ gusrloc"
      elseif yloc $ gusrloc
         ylocfilter = "floc = yloc"
      else
         f_popup ("No Matching Record. Press Any Key to Retry ...",.t.)
         loop
      endif
      set softseek on
      do case
      case yret = 1
         f_use ("ravm", 1)
         set filter to &ylocfilter
         seek yval
      case yret = 2
         f_use ("ravm", 3)
         if .not. empty (yval)
            set filter to fclass = yval .and. &ylocfilter
         else
            set filter to &ylocfilter
         endif
         go top
         if .not. empty (yval1)
            seek yval1
         endif
      case yret = 3
         f_use ("ravm", 2)
         set filter to &ylocfilter
         seek yval
      endcase
      set softseek off
      if eof()
         tone (500, 9)
         f_popup ("No Matching Record. Press Any Key to Retry ...",.t.)
         loop
      else
         if .not. f_pick_f (02, 04, "", "StatÄClasÄUnit No.ÄÄÄYrÄModel" + ;
               "ÄÄÄÄÄÄLic. No.ÄÄÄStall #ÄÄCurrent Renter", ;
               "[ ]+fstatus+[ ]+freason+[ ]+fclass+[ ]+funit+[ ]+fyear" ;
               + "+ [ ] +fmodel+[ ]+flic+[ ]+fstall+[     ]+frenter+[ ]", "X")
            exit
         endif
      endif
   else
      tone (500, 9)
      f_popup ("File is empty. Press Any Key...",.t.)
      exit
   endif
enddo

if empty (yfilter)
   set filter to
else
   set filter to &yfilter
endif
if yord > 0
   set order to yord
endif
go (yrecno)

rest screen from yfullscn
setcolor (ycolor)
select (ysel)
