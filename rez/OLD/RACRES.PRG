*
* Reservation Retrieval System - Main program
*
* changes
* 1. 08/13/96. add development flag, by pass modem initialization
* 2. 08/13/96. add reject queue feature
* 3. 10/27/04. Res deliver by VPN
*
parameter xdev

public gstation, gdbfpath, gmempath, gscnpath, gstnpath, gmsgpath
public glocname, gdbffiles, gstnfiles, gcclog, gusrid, gusrgp
public gmesscolor, gbluecolor, gblueget, gmenuback, glgincolor
public gsubcolor, gsubget, gpickfore, gpickback, gredcolor
public gmenulevel, goption [9], gopts
public gmenupk [4], gmenuscn [4], gscrsav [81], gboxsav [10]
public gmcol1 [4], gmcol2 [4], gbluecolor, gredcolor, gmucolor

set exclusive off
set delete on
set exact off
set confirm on
set scoreboard off
set cursor off

if gete ("RESCOLOR") = "Y"
   gmucolor = .t.
elseif gete ("RESCOLOR") = "N"
   gmucolor = .f.
else
   gmucolor = iscolor ()
endif

if .not. file ("RASYS.DBF")
   quit
endif

use rasys 
go top
if gmucolor
   gmesscolor = fmesscolor
   gbluecolor = fbluecolor
   gblueget = substr (fbluecolor, at (",", fbluecolor) + 1)
   gmenuback = fmenuback
   glgincolor = flgincolor
   gsubcolor = fsubcolor
   gsubget = substr (fsubcolor, at (",", fsubcolor) + 1)
   gpickfore = fpickcolor
   gpickback = substr (fpickcolor, at (",", fpickcolor) + 1)
   gredcolor = fredcolor
else
   gmesscolor = "w/n"
   gbluecolor = "w/n, n/w"
   gblueget = "n/w"
   gmenuback = "/n"
   glgincolor = "w/n, w/n"
   gsubcolor = "n/w, w/n"
   gsubget = "w/n"
   gpickfore = "w/n"
   gpickback = "n/w"
   gredcolor = "n/w, n/w"
endif

afill (gboxsav, .f.)
afill (gscrsav, .f.)

gmenulevel = 0

setcolor (gmenuback)
clear
@ 23, 00 say replicate (chr (196), 80)
blimempak (-1)
save screen to gmenuscn [1]
f_popup ("Please Wait While Initializing...")

afill (gmenupk, 0)
if gmucolor
   n = at (",", fmcol1)
   gmcol1 [1] = substr (fmcol1, 1, n - 1)
   gmcol2 [1] = substr (fmcol1, n + 1)
   n = at (",", fmcol2)
   gmcol1 [2] = substr (fmcol2, 1, n - 1)
   gmcol2 [2] = substr (fmcol2, n + 1)
   n = at (",", fmcol3)
   gmcol1 [3] = substr (fmcol3, 1, n - 1)
   gmcol2 [3] = substr (fmcol3, n + 1)
   n = at (",", fmcol4)
   gmcol1 [4] = substr (fmcol4, 1, n - 1)
   gmcol2 [4] = substr (fmcol4, n + 1)
else
   afill (gmcol1, "/W")
   afill (gmcol2, "W/N")
endif

* get path
gdbfpath = alltrim(fdbfpath)
grespath = alltrim(frespath)
gmempath = alltrim(fmempath)
gsuppath = alltrim(fsuppath)
           
* get comm parameter
gcomm = val(substr(fremark1,1,2))      && comm port
grbuff = 1030
gxbuff = 1030
gbaud = val(substr(fremark1,3,5))      && baud 1200 - 19200
if substr(fremark1,8,1) = "N"          && none
   gparity = 0
elseif substr(fremark1,8,1) = "O"      && odd
   gparity = 1
elseif substr(fremark1,8,1) = "E"      && even
   gparity = 2
endif
gwordlen = val(substr(fremark1,9,1))   && word len
gstopbit = val(substr(fremark1,10,1))  && stop bit
ginit = alltrim(substr(fremark1,11))   && init string
ginit = if(empty(ginit), "AT E0 V1 X4 S9=1 S11=40 S0=1", ginit)
greslen = freslen                      && length of res #
gmaxfil = fmaxfil                      && max no of history file

gtitle = alltrim(ftitle)               && rate code
use

gcommpct = 12                          && resort standard comm.

glocname = "Budget Rent A Car - Reservation Retrieval System"
gusrid = "RES"
gusrgp = "0123456789"
gusrline = 1
gmaxusr = 5
glgouttme = 0

f_popback ()

if pcount () = 0
   do rresr
else
   do rresr1
   do rresr2
endif

close data

******************************
function f_popup

parameters xmessage, xrequest
private xrow, xhalf_len, xocolor, xkeyin, ycursor

ycursor = iscursor ()
set cursor off

if pcount () < 2
   xrequest = .f.
endif

if type ("gscrsav [40]") <> "L"
   f_popback ()
endif

blimempak (-1)
for xrow = 1 to 79
   gscrsav [xrow] = savescreen (24, xrow, 24, xrow)
next
blimempak (-1)

xmessage = alltrim (xmessage)
if len (xmessage) > 76
   xmessage = left (xmessage, 76)
endif
xhalf_len = round (len (xmessage) / 2, 0)

xocolor = setcolor (gmesscolor)

for xrow = 1 to xhalf_len + 2
   @ 24, 40 - xrow clear to 24, 40 + xrow
next

@ 24, 41 - xhalf_len say xmessage
setcolor (xocolor)

xkeyin = 0
if xrequest
   set cursor on
   xkeyin = f_getkey ()
   f_popback ()
endif
if ycursor
   set cursor on
else
   set cursor off
endif
return (xkeyin)


******************************
function f_popback

if type ("GSCRSAV [40]") <> "L"
   private xrow
   blimempak (-1)
   for xrow = 1 to 40
      restscreen (24, xrow, 24, xrow, gscrsav [xrow])
      restscreen (24, 80 - xrow, 24, 80 - xrow, gscrsav [80 - xrow])
      gscrsav [xrow] = .f.
      gscrsav [80 - xrow] = .f.
   next
   blimempak (-1)
endif

******************************
function f_replace

private xfld, xlfld, n

reclock ()
for n = 1 to fcount ()
   xfld = field (n)
   xlfld = "L_" + xfld
   replace &xfld with &xlfld
next
commit
unlock

******************************
function f_retrieve

private xfld, xlfld, n

for n = 1 to fcount ()
   xfld = field (n)
   xlfld = "L_" + xfld
   &xlfld = &xfld
next

******************************
function f_clrscn

parameters xtitle
private yr1, yc1, yr2, yc2

setcolor (gbluecolor)
blimempak (-1)
for n = 1 to 10
   yr1 = 12 + round (-1.2 * n, 0)
   yc1 = 40 + round (-4.0 * n, 0)
   yr2 = 12 + round (1.2 * n, 0)
   yc2 = 40 + round (3.9 * n, 0)
   if type ("gboxsav [n]") = "L"
      gboxsav [n] = savescreen (yr1, yc1, yr2, yc2)
   endif
   @ yr1, yc1 clear to yr2, yc2
next
blimempak (-1)
setcolor (gredcolor)
@ 00, 00
@ 24, 00
if pcount () >= 1
   @ 00, 40 - int (len (xtitle) / 2) say xtitle
endif

setcolor (gbluecolor)

******************************
function f_confirm

parameters xmessage, xopt
private xocolor, xpick, xkeyin, yscn, ycursor

ycursor = iscursor ()

blimempak (-1)
yscn = savescreen (24, 00, 24, 79)
xocolor = setcolor (gredcolor)

@ 24, 00
xkeyin = 0
xpick = " "
@ 24, 01 say trim (xmessage) + "........ [ ]"
set cursor on
@ 24, len (trim (xmessage)) + 10 say "["
do while .t.
   xkeyin = f_getkey ()
   if xkeyin >= 32 .and. xkeyin <= 127
      xpick = upper (chr (xkeyin))
      @ 24, len (trim (xmessage)) + 11 say xpick
      @ 24, len (trim (xmessage)) + 11 say ""
      if xpick $ xopt
         exit
      endif
      tone (500, 9)
   endif
enddo
@ 24, 00
setcolor (xocolor)
blimempak (-1)
restscreen (24, 00, 24, 79, yscn)
blimempak (-1)
if ycursor
   set cursor on
else
   set cursor off
endif
return xpick

******************************
function f_valid

parameters xcond, xmess

if xcond
   return .t.
else
   tone (500, 9)
   if pcount () < 2
      f_popup ("Invalid Entry!!! Press Any Key...", .t.)
   else
      f_popup (trim (xmess) + " Press Any Key...", .t.)
   endif
   set cursor on
   return .f.
endif

******************************
function f_getkey

clear typeahead
return inkey (0)

******************************
function reclock

private ycount, yerr

if empty (alias ())
   return (0)
endif
ycount = 30
yerr = .f.
do while .not. rlock ()
   yerr = .t.
   ycount = ycount - 1
   if ycount = 0
      f_popup ("Unable to lock " + alias () + " database... Working...", .f.)
      ycount = 30
   endif

   f_popup ("Trying to lock " + alias () + " record...", .f.)
   inkey (.5)
enddo
if yerr
   f_popback ()
endif
return (0)

function f_pick_f

parameters xrow, xcol, xcolor, xtitle, xdispfld, xfunc, xkeyfld, xkeyval
private ycolor, yscn, ylen, yrow, ycrow, ykeyin, yrecno, ycnt
private yrectop, yrecbott, ycond, ydisponly, ynotitle

ydisponly = .f.
if pcount () < 6
   xfunc = ""
elseif left (xfunc, 1) = "X"
   if xfunc == "X"
      xfunc = ""
   endif
   ydisponly = .t.
endif
set cursor off
yrecno = recno ()
if pcount () < 8
   ycond = ".T."
   go top
   yrectop = recno ()
   go bottom
   yrecbott = recno ()
else
   ycond = xkeyfld + " = " + xkeyval
   seek &xkeyval
   if eof ()
      return .f.
   endif
   yrectop = recno ()

   set softseek on
   seek nextrec (&xkeyval)
   if eof ()
      go bottom
   else
      skip -1
   endif
   yrecbott = recno ()
   set softseek off
endif

yrow = xrow + reccount () + 1
if yrow > 22
   yrow = 22
endif

if ydisponly
   ylen = len (&xdispfld)
else
   ylen = len (&xdispfld) + 3
endif
ycnt = 1
do while .t.
   skip
   if eof () .or. .not. &ycond
      exit
   elseif ycnt < (yrow - xrow - 1)
      ycnt = ycnt + 1
   else
      exit
   endif
enddo

go (yrecno)
if ycnt < (yrow - xrow - 1)
   skip (ycnt - yrow + xrow + 1)
   if bof () .or. .not. &ycond
      go yrectop
   endif
endif

if empty (xcolor)
   xcolor = gpickback
endif
ycolor = setcolor (xcolor)

blimempak (-1)
if (xcol + ylen + 1) > 78
   xcol = 77 - ylen
endif
if xtitle = "NOTITLE"
   yscn = savescreen (xrow + 1, xcol - 1, yrow + 1, xcol + ylen + 1)
else
   yscn = savescreen (xrow, xcol - 1, yrow + 1, xcol + ylen + 1)
   @ xrow, xcol say chr (218) + replicate (chr (196), ylen) + chr (191)
   if ydisponly
      @ xrow, xcol + 1 say xtitle
   else
      @ xrow, xcol + 4 say xtitle
   endif
endif
ycrow = xrow + 1
ycnt = 99
do while ycrow < yrow .and. .not. eof () .and. &ycond
   if yrecno = recno ()
      ycnt = ycrow
   endif
   if ydisponly
      @ ycrow, xcol say chr (179) + f_truncate (&xdispfld, ylen) + chr (179)
   else
      @ ycrow, xcol say chr (179) + f_truncate (chr (65 + ycrow - xrow - 1) + ;
         ". " + &xdispfld, ylen) + chr (179)
   endif
   skip
   ycrow = ycrow + 1
enddo
if ycnt = 99
   ycnt = ycrow - 1
endif
yrow = ycrow
@ yrow, xcol say chr (192) + replicate (chr (196), ylen) + chr (217)
f_shadow (xrow, xcol, yrow, xcol + ylen + 1)
if yrow = xrow + 1
   setcolor (ycolor)
   blimempak (-1)
   if xtitle = "NOTITLE"
      restscreen (xrow + 1, xcol - 1, yrow + 1, xcol + ylen + 1, yscn)
   else
      restscreen (xrow, xcol - 1, yrow + 1, xcol + ylen + 1, yscn)
   endif
   blimempak (-1)
   set cursor on
   return .f.
endif

go (yrecno)
ycrow = ycnt
do while .t.
   setcolor (gpickfore)
   if ydisponly
      @ ycrow, xcol + 1 say f_truncate (&xdispfld, ylen)
   else
      @ ycrow, xcol + 1 say f_truncate (chr (65 + ycrow - xrow - 1) + ;
         ". " + &xdispfld, ylen)
   endif
   do while .t.
      ykeyin = inkey (0)
      if ykeyin >= 97 .and. ykeyin <= 122 .and. .not. ydisponly
         ykeyin = ykeyin - 32
      endif
      if (str (ykeyin, 2) + ";") $ " 4; 5;24;27;19;18; 3;" + ;
            if (ydisponly .and. empty (xfunc), "", "13;")
         exit
      endif
      if ykeyin >= 65 .and. ykeyin <= (63 + yrow - xrow) .and. .not. ydisponly
         exit
      endif
   enddo

   if ykeyin <> 13
      setcolor (xcolor)
      if ydisponly
         @ ycrow, xcol + 1 say f_truncate (&xdispfld, ylen)
      else
         @ ycrow, xcol + 1 say f_truncate (chr (65 + ycrow - xrow - 1) + ;
            ". " + &xdispfld, ylen)
      endif
   endif
   do case
   case ykeyin = 5
      skip -1
      if bof () .or. .not. &ycond
         go yrectop
      else
         if ycrow > xrow + 1
            ycrow = ycrow - 1
         else
            if ydisponly
               scroll (xrow + 1, xcol + 1, yrow - 1, xcol + ylen, -1)
            else
               scroll (xrow + 1, xcol + 4, yrow - 1, xcol + ylen, -1)
            endif
         endif
      endif
   case ykeyin = 24
      skip 1
      if eof () .or. .not. &ycond
         go yrecbott
      else
         if ycrow < yrow - 1
            ycrow = ycrow + 1
         else
            if ydisponly
               scroll (xrow + 1, xcol + 1, yrow - 1, xcol + ylen, 1)
            else
               scroll (xrow + 1, xcol + 4, yrow - 1, xcol + ylen, 1)
            endif
         endif
      endif
   case ykeyin = 18
      ycnt = 1
      do while ycnt <= (yrow - xrow - 2)
         skip -1
         if bof () .or. .not. &ycond
            go yrectop
            exit
         endif
         if ycrow > xrow + 1
            ycrow = ycrow - 1
         else
            if ydisponly
               scroll (xrow + 1, xcol + 1, yrow - 1, xcol + ylen, -1)
               @ ycrow, xcol + 1 say f_truncate (&xdispfld, ylen)
            else
               scroll (xrow + 1, xcol + 4, yrow - 1, xcol + ylen, -1)
               @ ycrow, xcol + 1 say f_truncate (chr (65 + ycrow - xrow - 1) + ;
                  ". " + &xdispfld, ylen)
            endif
         endif
         ycnt = ycnt + 1
      enddo
   case ykeyin = 3
      ycnt = 1
      do while ycnt <= (yrow - xrow - 2)
         skip 1
         if eof () .or. .not. &ycond
            go yrecbott
            exit
         endif
         if ycrow < yrow - 1
            ycrow = ycrow + 1
         else
            if ydisponly
               scroll (xrow + 1, xcol + 1, yrow - 1, xcol + ylen, 1)
               @ ycrow, xcol + 1 say f_truncate (&xdispfld, ylen)
            else
               scroll (xrow + 1, xcol + 4, yrow - 1, xcol + ylen, 1)
               @ ycrow, xcol + 1 say f_truncate (chr (65 + ycrow - xrow - 1) + ;
                  ". " + &xdispfld, ylen)
            endif
         endif
         ycnt = ycnt + 1
      enddo
   case ykeyin = 13 .or. ykeyin = 27 .or. ykeyin = 4 .or. ykeyin = 19
      if .not. empty (xfunc) .and. ykeyin = 13
         do &xfunc
      elseif .not. ydisponly .or. ykeyin <> 13 
         setcolor (ycolor)
         blimempak (-1)
         if xtitle = "NOTITLE"
            restscreen (xrow + 1, xcol - 1, yrow + 1, xcol + ylen + 1, yscn)
         else
            restscreen (xrow, xcol - 1, yrow + 1, xcol + ylen + 1, yscn)
         endif
         blimempak (-1)
         set cursor on
         if ykeyin <> 27
            return .t.
         else
            go (yrecno)
            return .f.
         endif
      endif
   otherwise
      if ykeyin <> (64 + ycrow - xrow)
         skip ykeyin - 64 - ycrow + xrow
         ycrow = ykeyin - 64 + xrow
      endif
      keyboard chr (13)
   endcase
enddo

******************************
function nextrec

parameter xval

return left (xval, len (xval) - 1) + chr (asc (right (xval, 1)) + 1)

******************************
function f_shadow

parameters xr1, xc1, xr2, xc2
private ycolor

if gmucolor
   att (xr1 + 1, xc1 - 1, xr2 + 1, xc1 - 1, 8)
   att (xr2 + 1, xc1, xr2 + 1, xc2 - 1, 8)
else
   ycolor = setcolor ("w/n")
   @ xr1 + 1, xc1 - 1 clear to xr2 + 1, xc1 - 1
   @ xr2 + 1, xc1 clear to xr2 + 1, xc2 - 1
   setcolor (ycolor)
endif

******************************
function f_truncate

parameters xstr, xlen

return left (xstr + replicate (" ", xlen), xlen)


