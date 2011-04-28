if gete ("RACCOLOR") = "Y"
   gmucolor = .t.
elseif gete ("RACCOLOR") = "N"
   gmucolor = .f.
else
   gmucolor = iscolor ()
endif
setcolor (if (gmucolor, "bg+/b", "w/n"))
clear
set cursor off
@ 0, 0 say "RacWare Menu V3.20"
@ 1, 0 say "Copyright (c) 1990, " + str (year (date ()), 4) + ;
   " by OnSum Group Corporation.  All Right Reserved."
inkey (2)

set exclusive off
set delete on
set exact off
set confirm on
set scoreboard off
clear typeahead

if empty (gete ("RACPTH"))
   xpath = "\"
else
   xpath = alltrim (upper (gete ("RACPTH")))
endif

if empty (gete ("RACDBF"))
   gdbfpath = "J:" + xpath + "RACWARE\DBF\"
else
   gdbfpath = alltrim (upper (gete ("RACDBF")))
endif

if empty (gete ("RACSID"))
   gstation = ""
else
   gstation = alltrim (upper (gete ("RACSID")))
endif

if empty (gete ("RACSTN"))
   gstnpath = "I:" + xpath + "RACWARE\STN\" + gstation + "\"
else
   gstnpath = alltrim (upper (gete ("RACSTN")))
endif

if file (gstnpath + "roption.dbf")
   yfil = gstnpath + "roption"
elseif file (gdbfpath + "roption.dbf")
   yfil = gdbfpath + "roption"
else
   set color to
   clear
   set cursor on
   quit
endif
use &yfil
if file (yfil + ".ntx")
   set index to &yfil
endif

go top
yrec = 0
yautocnt = 0
declare autoset [30]
go top
locate for foption = "MASTERPASSWORD"
if .not. found ()
   append blank
   rlock ()
   replace foption with "MASTERPASSWORD"
   commit
   unlock
endif
ympass = fpassword
ympassrec = recno ()
set filter to foption <> "MASTERPASSWORD"
go top
count to yrec
if yrec = 0
   set color to
   clear
   set cursor on
   quit
endif

xarrow = 0
if .not. empty (gete ("RACMENU"))
   go top
   xrecno = val (gete ("RACMENU"))
   do while .not. eof ()
      if xrecno = recno ()
         exit
      endif
      xarrow = xarrow + 1
      skip
   enddo
endif

go top
getautoset ()
gexitpass = getexitpass ()
asort (autoset, 1, yautocnt)

if yrec >= 17
   yrec = 17
   yrow1 = 5
   yrow2 = 23
else
   yrow1 = 5 + int ((17 - yrec) / 2)
   yrow2 = yrow1 + yrec + 1
endif

ylen = len (foption) + 5

setcolor (if (gmucolor, "bg/b", "w/n"))
for n = 3 to 23
   @ n, 0 say replicate (chr (176), 80)
next
setcolor (if (gmucolor, "b/bg", "n/w"))
@ 0, 0 clear to 2, 79
@ 0, 0 to 2, 79
@ 1, 02 say "RacWare Menu V3.20"
@ 24, 0
@ 24, 3 say "F2 - Set Auto Run Time     F3 - Set Password     " + ;
      "F4 - Set Master Password"

setcolor (if (gmucolor, "gr+/b", "w/n"))
@ yrow1 - 2, 21 to yrow2, 21 + ylen + 3 double
@ yrow1 - 1, 21 say chr (186) + " " + f_truncate ("   Main Menu", ylen) + ;
   " " + chr (186)
@ yrow1, 21 say chr (204) + replicate (chr (205), ylen + 2) + chr (185)
setcolor (if (gmucolor, "w+/b", "w/n"))
go bottom
yerec = recno ()
go top
ybrec = recno ()
for n = 1 to yrec
   @ yrow1 + n, 22 say " " + f_truncate (chr (64 + n) + ;
         ". " + foption, ylen) + " "
   skip
next
if .not. eof ()
   setcolor ("n/w")
   @ yrow1 + n, 21 say chr (25)
endif

declare runtime [9]

go top
ycrow = yrow1 + 1
yautook = .f.
if xarrow > 0
   keyboard (replicate (chr (24), xarrow))
endif
yautoscn = savescreen (8, 59, 18, 75)
do while .t.
   setcolor (if (gmucolor, "b/w", "n/w"))
   @ ycrow, 22 say " " + f_truncate (chr (65 + ycrow - yrow1 - 1) + ;
      ". " + foption, ylen) + " "
   if fautotime
      setcolor (if (gmucolor, "w+/rb, n/w", "w/n, n/w"))
      @ 8, 59 clear to 18, 75
      @ 8, 59 to 18, 75
      @ 8, 60 say " Auto Run Time "
      setcolor (if (gmucolor, "w+/rb, n/w", "w/n, n/w"))
      for n = 1 to 9
         ystr = "fauto" + str (n, 1)
         runtime [n] = left (&ystr, 5)
         @ 8 + n, 65 get runtime [n] pict "99:99"
      next
   else
      restscreen (8, 59, 18, 75, yautoscn)
   endif

   setcolor (if (gmucolor, "b/bg", "n/w"))
   do while .t.
      ydate = date ()
      ytime = cdow (ydate) + "  " + cmonth (ydate) + " " + ;
         alltrim (str (day (ydate))) + ", " + str (year (ydate), 4) + "  " ;
         + time ()
      @ 1, 63 - len (ytime) say space (15) + ytime

      if .not. yautook
         ykeyin = inkey ()
         if ykeyin >= 97 .and. ykeyin <= 122
            ykeyin = ykeyin - 32
         endif
         if (str (ykeyin, 2) + ";") $ (" 5;24;18; 3;13;-2;-3;27;" + ;
               if (fautotime, "-1;", ""))
            exit
         endif
         if ykeyin >= 65 .and. ykeyin <= (64 + yrec)
            exit
         endif

         for nautoset = 1 to yautocnt
            if left (time (), 5) >= left (autoset [nautoset], 5) .and. ;
                  ctod (substr (autoset [nautoset], 6, 8)) < date ()
               yautook = .t.
               yautorec = val (substr (autoset [nautoset], 14, 2))
               go top
               if yautorec = recno ()
                  ykeyin = 13
               else
                  ykeyin = 24
               endif
               exit
            endif
         next
         if yautook
            exit
         endif
      else
         if yautorec = recno ()
            ykeyin = 13
         else
            ykeyin = 24
         endif
         exit
      endif
   enddo

   if ykeyin <> -1
      clear gets
   endif
   setcolor (if (gmucolor, "w+/b", "w/n"))
   if ykeyin <> 13 .and. ykeyin <> -1 .and. ykeyin <> -2
      @ ycrow, 22 say " " + f_truncate (chr (65 + ycrow - yrow1 - 1) + ;
         ". " + foption, ylen) + " "
   endif
   do case
   case ykeyin = -1
      if askpasswd ()
         set cursor on
         read
         set cursor off
         if lastkey () <> 27
            rlock ()
            for n = 1 to 9
               ystr = "fauto" + str (n, 1)
               if empty (left (runtime [n], 2))
                  replace &ystr with space (16)
               elseif &ystr <> runtime [n]
                  replace &ystr with runtime [n] + ;
                        if (runtime [n] < left (time (), 5), dtoc (date ()), ;
                        space (8))
               endif
            next
            commit
            unlock
            getautoset ()
         endif
      endif
   case ykeyin = -2
      setcolor (if (gmucolor, "w+/rb", "w/n"))
      yscn = savescreen (yrow2 - 3, 26, yrow2 - 1, 60)
      @ yrow2 - 3, 26 clear to yrow2 - 1, 60
      @ yrow2 - 3, 26 to yrow2 - 1, 60
      if .not. empty (fpassword) .or. .not. empty (ympass)
         setcolor (if (gmucolor, "w+/rb", "w/n"))
         @ yrow2 - 2, 28 say "OLD/MASTER PASSWORD:            "
         setcolor ("n/w")
         if .not. (keyinpasswd (yrow2 - 2, 49) + ";") $ ;
               (fpassword + ";" + ympass + ";")
            setcolor (if (gmucolor, "w+*/rb", "n*/w"))
            tone (500, 9)
            @ yrow2 - 2, 28 say "Incorrect Password!!!           "
            inkey (3)
            restscreen (yrow2 - 3, 26, yrow2 - 1, 60, yscn)
            loop
         endif
      endif
      setcolor (if (gmucolor, "w+/rb", "w/n"))
      @ yrow2 - 2, 28 say "NEW PASSWORD:                   "
      setcolor ("n/w")
      ypass = keyinpasswd (yrow2 - 2, 42)
      setcolor (if (gmucolor, "w+/rb", "w/n"))
      @ yrow2 - 2, 28 say "RETYPE PASSWORD:                "
      setcolor ("n/w")
      if ypass <> keyinpasswd (yrow2 - 2, 45)
         setcolor (if (gmucolor, "w+*/rb", "w*/n"))
         tone (500, 9)
         @ yrow2 - 2, 28 say "Passwords Not Matched!!!        "
         inkey (3)
      else
         rlock ()
         replace fpassword with ypass
         commit
         unlock
         setcolor (if (gmucolor, "w+*/rb", "w*/n"))
         @ yrow2 - 2, 28 say "New Password Is Set...          "
         gexitpass = getexitpass ()
         inkey (1)
      endif
      restscreen (yrow2 - 3, 26, yrow2 - 1, 60, yscn)
   case ykeyin = -3
      setcolor (if (gmucolor, "w+/rb", "w/n"))
      yscn = savescreen (yrow2 - 3, 26, yrow2 - 1, 60)
      @ yrow2 - 3, 26 clear to yrow2 - 1, 60
      @ yrow2 - 3, 26 to yrow2 - 1, 60
      setcolor (if (gmucolor, "w+/rb", "w/n"))
      @ yrow2 - 2, 28 say "OLD MASTER PASSWORD:            "
      setcolor ("n/w")
      if .not. (keyinpasswd (yrow2 - 2, 49) = ympass)
         setcolor (if (gmucolor, "w+*/rb", "n*/w"))
         tone (500, 9)
         @ yrow2 - 2, 28 say "Incorrect Password!!!           "
         inkey (3)
         restscreen (yrow2 - 3, 26, yrow2 - 1, 60, yscn)
         loop
      endif
      setcolor (if (gmucolor, "w+/rb", "w/n"))
      @ yrow2 - 2, 28 say "NEW MASTER PASSWORD:            "
      setcolor ("n/w")
      ypass = keyinpasswd (yrow2 - 2, 49)
      setcolor (if (gmucolor, "w+/rb", "w/n"))
      @ yrow2 - 2, 28 say "RETYPE PASSWORD:                "
      setcolor ("n/w")
      if ypass <> keyinpasswd (yrow2 - 2, 45)
         setcolor (if (gmucolor, "w+*/rb", "w*/n"))
         tone (500, 9)
         @ yrow2 - 2, 28 say "Passwords Not Matched!!!   "
         inkey (3)
      else
         ympass = ypass
         yrec = recno ()
         set filter to
         go ympassrec
         rlock ()
         replace fpassword with ympass
         commit
         unlock
         set filter to foption <> "MASTERPASSWORD"
         setcolor (if (gmucolor, "w+*/rb", "w*/n"))
         @ yrow2 - 2, 28 say "New Password Is Set...          "
         gexitpass = getexitpass ()
         inkey (1)
         go yrec
      endif
      restscreen (yrow2 - 3, 26, yrow2 - 1, 60, yscn)
   case ykeyin = 5
      skip -1
      if bof ()
         go top
      else
         if ycrow > yrow1 + 1
            ycrow = ycrow - 1
         else
            scroll (yrow1 + 1, 26, yrow2 - 1, 21 + ylen, -1)
            if recno () = ybrec
               setcolor (if (gmucolor, "gr+/b", "w/n"))
               @ yrow1, 21 say chr (204)
            endif
            setcolor ("n/w")
            @ yrow2, 21 say chr (25)
            setcolor (if (gmucolor, "w+/b", "w/n"))
         endif
      endif
   case ykeyin = 24
      skip 1
      if eof ()
         go bottom
      else
         if ycrow < yrow2 - 1
            ycrow = ycrow + 1
         else
            scroll (yrow1 + 1, 26, yrow2 - 1, 21 + ylen, 1)
            if recno () = yerec
               setcolor (if (gmucolor, "gr+/b", "w/n"))
               @ yrow2, 21 say chr (200)
            endif
            setcolor ("n/w")
            @ yrow1, 21 say chr (24)
            setcolor (if (gmucolor, "w+/b", "w/n"))
         endif
      endif
   case ykeyin = 18
      ycnt = 1
      for n = 1 to yrec - 1
         skip -1
         if bof ()
            go top
            exit
         endif
         if ycrow > yrow1 + 1
            ycrow = ycrow - 1
         else
            scroll (yrow1 + 1, 26, yrow2 - 1, 21 + ylen, -1)
            @ ycrow, 23 say f_truncate (chr (65 + ycrow - yrow1 - 1) + ;
               ". " + foption, ylen)
            if recno () = ybrec
               setcolor (if (gmucolor, "gr+/b", "w/n"))
               @ yrow1, 21 say chr (204)
            endif
            setcolor ("n/w")
            @ yrow2, 21 say chr (25)
            setcolor (if (gmucolor, "w+/b", "w/n"))
         endif
         ycnt = ycnt + 1
      next
   case ykeyin = 3
      ycnt = 1
      for n = 1 to yrec - 1
         skip 1
         if eof ()
            go bottom
            exit
         endif
         if ycrow < yrow2 - 1
            ycrow = ycrow + 1
         else
            scroll (yrow1 + 1, 25, yrow2 - 1, 21 + ylen, 1)
            @ ycrow, 23 say f_truncate (chr (65 + ycrow - yrow1 - 1) + ;
               ". " + foption, ylen)
            if recno () = yerec
               setcolor (if (gmucolor, "gr+/b", "w/n"))
               @ yrow2, 21 say chr (200)
            endif
            setcolor ("n/w")
            @ yrow1, 21 say chr (24)
            setcolor (if (gmucolor, "w+/b", "w/n"))
         endif
         ycnt = ycnt + 1
      next
   case ykeyin = 27
      if .not. exitfunc ()
         loop
      endif
      if .not. empty (gexitpass)
         setcolor (if (gmucolor, "w+/rb", "w/n"))
         yscn = savescreen (yrow2 - 3, 26, yrow2 - 1, 56)
         @ yrow2 - 3, 26 clear to yrow2 - 1, 56
         @ yrow2 - 3, 26 to yrow2 - 1, 56
         @ yrow2 - 2, 28 say "ENTER PASSWORD:      "
         setcolor ("n/w")
         if .not. (keyinpasswd (yrow2 - 2, 44) + ";") $ gexitpass
            setcolor (if (gmucolor, "w+*/rb", "w*/n"))
            tone (500, 9)
            @ yrow2 - 2, 28 say "Incorrect Password!!!       "
            inkey (3)
            restscreen (yrow2 - 3, 26, yrow2 - 1, 56, yscn)
            loop
         endif
         restscreen (yrow2 - 3, 26, yrow2 - 1, 56, yscn)
      endif
      exit

   case ykeyin = 13
      if .not. empty (fcommand)
         if fcommand = "EXITDOS"
            if .not. exitfunc ()
               loop
            endif
         endif

         if .not. yautook
            if askpasswd ()
               exit
            endif
         else
            if yautook
               ystr = "fauto" + substr (autoset [nautoset], 16, 1)
               rlock ()
               replace &ystr with stuff (&ystr, 6, 8, dtoc (date ()))
               commit
               unlock
               autoset [nautoset] = stuff (autoset [nautoset], 6, 8, ;
                     dtoc (date ()))
            endif
            exit
         endif
      elseif yautook
         yautook = .f.
      endif
   otherwise
      if ykeyin <> (64 + ycrow - yrow1)
         skip ykeyin - ycrow - 64 + yrow1
         ycrow = ykeyin - 64 + yrow1
      endif
      keyboard chr (13)
   endcase
enddo

if fcommand <> "EXITDOS" .and. ykeyin <> 27
   setcolor (if (gmucolor, "n/w", "w/n"))
   @ 12, 30 clear to 16, 44
   @ 12, 30 to 16, 44
   setcolor (if (gmucolor, "n*/w", "w*/n"))
   @ 14, 32 say "Please Wait"
   memowrit (gstnpath + "RACSUBAT.BAT", strtran (alltrim (fcommand), ;
      "~", chr (13) + " ") + chr (13) + " SET RACMENU=" + ;
      alltrim (str (recno ())))
   set cursor on
   errorlevel (90)
   quit
else
   set color to
   clear
   set cursor on
   quit
endif


******************************
function f_truncate

parameters xstr, xlen

return left (xstr + replicate (" ", xlen), xlen)


******************************
function keyinpasswd

parameter x, y
private ypass, ysp, ychr

set console off
ypass = ""
ysp = y
@ x, y say space (10)
set cursor on
do while len (ypass) < 11
   @ x, ysp say ""
   wait to ychr
   if len (ychr) > 0
      @ x, ysp say "X"
      ysp = ysp + 1
      ypass = ypass + upper (ychr)
   else
      exit
   endif
enddo
set console on
set cursor off
return f_truncate (ypass, 10)


******************************
function askpasswd

if .not. empty (fpassword)
   setcolor (if (gmucolor, "w+/rb", "n/w"))
   yscn = savescreen (yrow2 - 3, 26, yrow2 - 1, 55)
   @ yrow2 - 3, 26 clear to yrow2 - 1, 55
   @ yrow2 - 3, 26 to yrow2 - 1, 55
   @ yrow2 - 2, 28 say "ENTER PASSWORD:"
   setcolor ("n/w")
   if (keyinpasswd (yrow2 - 2, 44) + ";") $ (fpassword + ";" + ympass + ";")
      restscreen (yrow2 - 3, 26, yrow2 - 1, 55, yscn)
      return .t.
   else
      setcolor (if (gmucolor, "w+*/rb", "w*/n"))
      tone (500, 9)
      @ yrow2 - 2, 28 say "Incorrect Password!!!      "
      inkey (3)
      restscreen (yrow2 - 3, 26, yrow2 - 1, 55, yscn)
      return .f.
   endif
else
   return .t.
endif


******************************
function getautoset

private ystr, n, yrecno
yrecno = recno ()

yautocnt = 0
go top
do while .not. eof ()
   if fautotime
      for n = 1 to 9
         ystr = "FAUTO" + str (n, 1)
         if yautocnt < 30 .and. .not. empty (left (&ystr, 2))
            yautocnt = yautocnt + 1
            autoset [yautocnt] = &ystr + str (recno (), 2) + str (n, 1)
         endif
      next
   endif
   skip
enddo
go (yrecno)
return .t.


******************************
function getexitpass

private ystr, n, yrecno, yexitpass
yrecno = recno ()

yexitpass = ""
go top
do while .not. eof ()
   if fcommand = "EXITDOS" .and. .not. empty (fpassword)
      yexitpass = yexitpass + fpassword + ";"
   endif
   skip
enddo
go (yrecno)
return yexitpass + ympass + ";"


******************************
function exitfunc

setcolor (if (gmucolor, "gr+/w", "w/n"))
yscn = savescreen (yrow2 - 6, 32, yrow2 - 1, 44)
@ yrow2 - 6, 32 clear to yrow2 - 1, 44
@ yrow2 - 6, 32 to yrow2 - 1, 44 double
@ yrow2 - 5, 34 say "Exit Menu"
@ yrow2 - 4, 32 say "ฬอออออออออออน"
yptr = 2
setcolor (if (gmucolor, "rb/w", "w/n"))
@ yrow2 - 3, 34 say "No"
setcolor (if (gmucolor, "w+/rb", "n/w"))
@ yrow2 - 2, 33 say " Yes       "
do while .t.
   ykey = inkey (0)
   do case
      case ykey = 5
         if yptr = 2
            setcolor (if (gmucolor, "w+/rb", "n/w"))
            @ yrow2 - 3, 33 say " No        "
            setcolor (if (gmucolor, "rb/w", "w/n"))
            @ yrow2 - 2, 33 say " Yes       "
            yptr = 1
         endif
      case ykey = 24
         if yptr = 1
            setcolor (if (gmucolor, "w+/rb", "n/w"))
            @ yrow2 - 2, 33 say " Yes       "
            setcolor (if (gmucolor, "rb/w", "w/n"))
            @ yrow2 - 3, 33 say " No        "
            yptr = 2
         endif
      case ykey = 13 .or. ykey = 27
         exit
   endcase
enddo
restscreen (yrow2 - 6, 32, yrow2 - 1, 44, yscn)
return (ykey = 13 .and. yptr = 2)

