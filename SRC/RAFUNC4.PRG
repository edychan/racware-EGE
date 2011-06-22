******************************
function usrlgin

public gusrline, gfreesell, gexdos, gusrloc, gusrlocgp
public g_version
private yusr, ypass, ycnt, ysp, yok, yfil, ydrv
g_version = "4.0c"

f_use ("rasys")
go top
setcolor (glgincolor)
@ 04, 02 clear to 13, 39
@ 04, 02, 13, 39 box ("лплллмл")
f_shadow (04, 02, 13, 39)
@ 06,07 say "     Welcome to RACWARE"
@ 07,07 say "Car Rental Management System"
@ 09,07 say "       Version " + g_version
@ 10,07 say "  Copyright (c) 1990, " + str (year (date ()), 4) + "."
@ 11,07 say "     OnSum Group Corp."
@ 10, 35 clear to 18, 70
@ 10, 35, 18, 70 box ("лплллмл")
f_shadow (10, 35, 18, 70)
set console off

select rasys
if type ("ftemp") <> "U"
   yy1 = str(bin2w(substr(ftemp,1,1)),1)
   yy2 = str(bin2w(substr(ftemp,2,1)),1)
   ym1 = str(bin2w(substr(ftemp,3,1)),1)
   ym2 = str(bin2w(substr(ftemp,4,1)),1)
   yd1 = str(bin2w(substr(ftemp,5,1)),1)
   yd2 = str(bin2w(substr(ftemp,6,1)),1)
   yctr = if(substr(ftemp,7,1)=" ",0,bin2w(substr(ftemp,7,1)))
   * allow 3 retrys, (i.e. user trys to back date)
   if yctr > 2 
      f_valid (.f., "Internal Error: 17")
      close all
      quit
   endif
   ystr = ym1+ym2+"/"+yd1+yd2+"/"+yy1+yy2
   if ctod(ystr) < date ()
      rlock ()
      replace ftemp with substr(ftemp,1,6)+substr(l2bin(yctr+1),1,1)
      commit
      unlock
      f_valid (.f., "Internal Error: 18")
      close all
      quit
   endif 
endif
*

use
do while .t.
   set cursor on
   yusr = "   "
   ysp = 53
   @ 11,40 say "User ID ....     "
   @ 12,40 say "                        "
   @ 11, ysp get yusr picture "!!!"
   read
   f_use ("rausr")
   seek yusr
   if .not. f_valid (found (), "Unknown User ID!!!")
      select rausr
      use
      loop
   elseif .not. f_valid (ftermdt > date () .or. empty (ftermdt), ;
         "User ID has been terminated.  Contact Supervisor!!!")
      select rausr
      use
      loop
   endif

   ypass = ""
   ysp = 53
   @ 12,40 say "Password ... "
   @ 12,53 say space (10)
   do while len (ypass) < 11
      @ 12, ysp say ""
      wait to ychr
      if len (ychr) > 0
         @ 12, ysp say "X"
         ysp = ysp + 1
         ypass = ypass + upper (ychr)
      else
         exit
      endif
   enddo
   if f_truncate (ypass, len (fpasswd)) = fpasswd
      exit
   else
      f_popup ("Invalid Password. Press Any Key to Retry ...", .t.)
      select rausr
      use
      loop
   endif
enddo
set console on

f_use ("rconsole")
ycnt = reccount() + 1
if ycnt < gmaxusr
   for i = ycnt to gmaxusr
      append blank
      reclock ()
      replace fline with recno(), fstatus with "IDLE"
      unlock
   next
endif

go top
yok = .f.
do while .not. eof () .and. recno () <= gmaxusr
   if fstatus = "IDLE"
      gusrline = recno ()
      reclock ()
      replace fuser with yusr, fstatus with "ACTIVE", fdate with date ()
      replace ftime with time (), fstation with gstation
      unlock
      yok = .t.
      exit
   endif
   skip
enddo

if yok
   go top
   do while .not. eof ()
      if fstation = gstation .and. gusrline <> recno ()
         reclock ()
         replace fuser with "OPEN", fstatus with "IDLE", fmodule with space (25)
         replace fdate with ctod ("  /  /  "), ftime with "  :  :  "
         replace fstation with space (8)
         unlock
      endif
      skip
   enddo
endif

select rconsole
use

select rausr
if yok
   if val (left (time (), 2)) >= 19
      @ 14,40 say "Good Evening, "+ ffname
   elseif val (left (time (), 2)) >= 12
      @ 14,40 say "Good Afternoon, "+ ffname
   else
      @ 14,40 say "Good Morning, "+ ffname
   endif
   * --06.21.11: add email report function
   gemail = if (type("femail")="U", "", trim(femail))
   gemrpt = if (type("femrpt")="U", .f., femrpt)
   * --06.21.11
   gusrid = fid
   gusrgp = alltrim (fgroup)
   f_use ("RAGROUP")
   gfreesell = .f.
   gexdos = .f.
   for n = 0 to 9
      if str (n, 1) $ gusrgp
         go (n + 1)
         gfreesell = gfreesell .or. ffreesell
         gexdos = gexdos .or. fexdos
      endif
   next
   use
   f_use ("RALOC")
   go top
   gusrloc = ""
   gusrlocgp = rausr->flocgp
   do while .not. eof ()
      if empty (gusrlocgp) .or. empty (flocgp) .or. ;
            (gusrlocgp = flocgp)
         gusrloc = gusrloc + floc + ";"
      endif
      skip
   enddo
   use
   select rausr
   use
   @ 15,40 say "Checking messages ..."
   * first check system message ...
   * yfil = gmsgpath + "@RAC.msg"
   * if file (yfil)
   *    f_rrout (yfil, .f., "System Message")
   * endif
   *
   yfil = gmsgpath + alltrim (gusrid) + "_*" + ".msg"
   yfilnum = adir (yfil)
   if yfilnum > 0
      f_clrscn ("Messages For You")
      private yfilary [yfilnum]
      adir (yfil, yfilary)
      for yptr = 1 to yfilnum
         yfilary [yptr] = f_truncate (strtran (upper (alltrim ;
            (substr (yfilary [yptr], len (alltrim (gusrid)) + 2))), ;
            ".MSG", ""), 6)
      next
      yptr = 1
      do while .t.
         if yfilnum > 1
            yptr = f_pick_a (2, 5, "", "From", yfilary, yfilnum, 1)
         else
            yptr = 1
         endif
         if yptr > 0
            yfil = gmsgpath + alltrim (gusrid) + "_" + alltrim (yfilary [yptr]) + ".msg"
            f_rrout (yfil, .f., "Message From " + alltrim (yfilary [yptr]))
            if f_confirm ("Do you want to erase this message? [Y/N]", "YN") = "Y"
               adel (yfilary, yptr)
               yfilnum = yfilnum - 1
               erase &yfil
               if yfilnum = 0
                  exit
               endif
            elseif yfilnum = 1
               exit
            endif
         else
            exit
         endif
      enddo
   endif
   *
   if diskspace (asc (upper(substr(gdbfpath,1,1)))-64) < 1000000
      tone (500, 9)
      f_popup ("WARNING! Hard disk is almost full! Contact Supervisor!")
      inkey (0)
   endif
   gmenulevel = 0
   return (.t.)
else
   f_popup ("No Login Permitted. Press Any Key and Contact Supervisor...", .t.)
   select rausr
   use
   return (.f.)
endif


******************************
function usrlgout

parameters xusrlgout
release all like l_*
close database
if xusrlgout
   if .not. (chr (f_popup ("Logout? [Y/N] ", .t.)) $ [Yy])
      return .f.
   endif
endif

f_use ("rconsole")
go gusrline
reclock()
if fstatus = "DISABLE"
   replace fuser with "OPEN", fmodule with space (25)
   replace fdate with ctod ("  /  /  "), ftime with "  :  :  "
   replace fstation with space (8)
else
   replace fuser with "OPEN", fstatus with "IDLE", fmodule with space (25)
   replace fdate with ctod ("  /  /  "), ftime with "  :  :  "
   replace fstation with space (8)
endif
unlock
use

if gexdos .and. xusrlgout
   if chr (f_popup ("Exit RacWare ? [Y/N] ", .t.)) $ [Yy]
      set cursor on
      quit
   endif
endif
return .t.


******************************
function f_rrout

parameters xfile, xedit, xtitle

private ymemo, ys1, ylen, yblen, yptr, xrow1, xrow2, xcol1, xcol2

xrow1 = 3
xrow2 = 21
xcol1 = 3
xcol2 = 76

if .not. file (xfile)
   return (-1)
endif

yfunc = "f_memo"

deja_vu = .f.

yocolor = setcolor ("n/w")
ymemo = memoread (xfile)
set cursor on

blimempak (-1)
f_box (xrow1 - 1, xcol1 - 1, xrow2 + 1, xcol2 + 1)
if .not. empty (xtitle)
   @ xrow1 - 1, xcol1 + 1 say " " + alltrim (xtitle) + " "
endif
if xedit
   @ xrow2 + 1, xcol2 - 39 say " <CNTL> W - save edit ФФ <ESC> - quit "
   memowrit (xfile, memoedit (ymemo, xrow1, xcol1, xrow2, xcol2, ;
      xedit, yfunc, min (78, xcol2 - xcol1 + 1), 10))
else
   memoedit (ymemo, xrow1, xcol1, xrow2, xcol2, xedit, yfunc, ;
      min (78, xcol2 - xcol1 + 1), 10)
endif
set cursor off
setcolor (yocolor)
return (0)


******************************
function f_memo

parameters mode, line, col
private ykey
ret_val = 0
do case
case mode = 3
   if .not. deja_vu
      deja_vu = .t.
      ret_val = 35
   endif
case mode = 0
   @ xrow2 + 1, xcol1 + 2 say strtran (f_truncate ("(" + ltrim (str (line)) ;
      + "," + ltrim (str (col)) + ")", 8), " ", "Ф")
endcase

return ret_val

