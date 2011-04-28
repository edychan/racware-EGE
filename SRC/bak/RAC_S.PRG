* ===========================================================================
*
* RacWare main program
*
* ===========================================================================
do while .t.
   begin sequence
      do rinit
      restore from (gmempath + "RAPATH.MEM") additive

      do while .t.
         if .not. usrlgin ()
            loop
         endif
         do while .t.
            xret0 = f_pushmenu ("SUPPLEMENT MENU")
            if xret0 = 0
               if usrlgout (.t.)
                  exit
               else
                  loop
               endif
            endif
            xoption0 = substr (goption [xret0], 4)
            bliovlclr ()
            do case
            case xret0 = 1        && print vocher
               do rac_s1
            case xret0 = 2        && export customer data
               do rac_s2
            case xret0 = 3        && revenue report
               do rac_s3
            endcase
         enddo
      enddo
   end
   set key 28 to
   set key -1 to
   set key -2 to
   set key -3 to
   set key -4 to
   set key -5 to
   set key -6 to               && calculator
   set key -7 to               && phone book
   set key -8 to               && reminder
   set key -9 to               && calendar
   usrlgout (.f.)
enddo

procedure rinit
* ===========================================================================
* Initialize system variables
*
* 05/01/92
* Author: EDC
*
* Revision:
* 03/30/93: (edc) add garpost, gglpost, gaccpath & gfileno
* ===========================================================================
public gstation, gdbfpath, gmempath, gstnpath, gmsgpath
public gsuppath, gsupmpath
public gdbffiles, gstnfiles, gcclog, gusrid, gusrgp, gsup, gcntl
public gmesscolor, gbluecolor, gblueget, gmenuback, glgincolor
public gsubcolor, gsubget, gpickfore, gpickback, gredcolor
public gmenulevel, goption [9], gopts
public gmenupk [4], gmenuscn [4], gscrsav [81], gboxsav [10]
public gmcol1 [4], gmcol2 [4], gbluecolor, gredcolor, gmucolor
public __gccunauth, __gccauth, __gccuncap, __gcccap, __gccautherr
public __gccspecauth, __gccadj
public __ginitstr, __gmodem, __gcomm, __gbaud, __gparity, __gstopbit
public __gdatabit, __gxbuff, __grbuff, __gtimeout, __gname, __gaddr, __gcity
public __gstate, __gzip, __gcountry, __gcash, __gccsale, __gccforce
public __gccvoid, __gcccredit, __gccunauth, __gccauth, __gccuncap
public __gcccap, __gccautherr, __gccspecauth
public __gplanno, __gcompany, __gprefix, __gstore, __gica
public __gmerch, __gtermid, __gserial, __gamex, __gamexph1, __gamexph2
public __gcompuid, __gcompuph, __gphone, gaxbaud

__gccunauth = 1
__gccauth = 2
__gccuncap = 3
__gcccap = 4
__gccautherr = 5
__gccspecauth = 6
__gccadj = 7

set exclusive off
set delete on
set exact off
set confirm on
set scoreboard off
set cursor off

set key 28 to
set key -1 to
set key -2 to

gcclog = (gete ("CCLOG") $ "Yy")

if empty (gete ("RACDRV"))
   xdrive = "C:"
else
   xdrive = alltrim (upper (gete ("RACDRV")))
endif

if empty (gete ("RACPTH"))
   xpath = "\"
else
   xpath = alltrim (upper (gete ("RACPTH")))
endif

if empty (gete ("RACSID"))
   gstation = ""
else
   gstation = alltrim (upper (gete ("RACSID")))
endif

if empty (gete ("RACDBF"))
   gdbfpath = "J:" + xpath + "RACWARE\DBF\"
else
   gdbfpath = alltrim (upper (gete ("RACDBF")))
endif

if empty (gete ("RACSTN"))
   gstnpath = "I:" + xpath + "RACWARE\STN\" + gstation + "\"
else
   gstnpath = alltrim (upper (gete ("RACSTN")))
endif

if empty (gete ("RACMEM"))
   gmempath = xdrive + xpath + "RACWARE\MEM\"
else
   gmempath = alltrim (upper (gete ("RACMEM")))
endif

if empty (gete ("RACSUP"))
   gsuppath = xdrive + xpath + "RACWARE\SUP\"
else
   gsuppath = alltrim (upper (gete ("RACSUP")))
endif
gsupmpath = gsuppath + "MAIL\"
gsuppath = gsuppath + "DBF\"

if empty (gete ("RACMSG"))
   gmsgpath = xdrive + xpath + "RACWARE\MAIL\"
else
   gmsgpath = alltrim (upper (gete ("RACMSG")))
endif

if gete ("RACCOLOR") = "Y"
   gmucolor = .t.
elseif gete ("RACCOLOR") = "N"
   gmucolor = .f.
else
   gmucolor = iscolor ()
endif

use (gdbfpath + "RASYS")
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
gcntl = fcntl
gaxbaud = faxbaud
afill (gboxsav, .f.)
afill (gscrsav, .f.)

gmenulevel = 0

setcolor (gmenuback)
clear
@ 23, 00 say replicate (chr (196), 80)

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

use

public gloc, gccnet, gstgrp, gccreader, gccmodem, gserver, gmaxusr, glgouttme
public gautopkvh, gtitle, gmaxage, gminage, glimage, ggracehr, ggracefr, gfuelchg
public gfueltax, gtaxrate, grafrmno, gsurchg, gsurtx, gwkmin, gwkmax, ggraceins
public gmthmin, gmthmax, grate, gcalday, gckintme, glocname
public garpost, gglpost, gaccpath, gfileno
* new variable to hold credit card reader track 1 info
public gccinfo, gccswipe
gccinfo=""
gccswipe=""       && card read or manual enter

restore from (gmempath + "RAPATH") additive
f_use ("RASTN")
seek f_truncate (gstation, 8)
if .not. found ()
   append blank
   restore from (gmempath + "RASTN") additive
   l_fstn = gstation
   f_replace ()
endif
gloc = floc
gstgrp = fstgrp
gccreader = fccreader
gccnet = fccnet
if empty (gccnet)
   gccmodem = .f.
else
   gccmodem = fccmodem
endif
gserver = fserver
use

f_use ("RASYS")
go top
gmaxusr = fmaxusr
glgouttme = flgouttme
gautopkvh = fautopkvh
gtitle = alltrim (ftitle)
gsup = fsup
use

f_use ("RALOC")
seek gloc
if .not. found ()
   f_valid (.f., "Warning!  Default Location Unknown!")
   gmaxage = 65
   glimage = 16
   gminage = 21
   ggracehr = 0
   ggraceins = .t.
   ggracefr = .f.
   gfuelchg = 2.00
   gfueltax = .f.
   gtaxrate = 0.00
   grafrmno = 0
   gsurchg = ""
   gsurtx = .f.
   gwkmin = 7
   gwkmax = 7
   gmthmin = 30
   gmthmax = 30
   grate = space (6)
   glocname = ""
   gcalday = .f.
   gckintme = "00:00"
   garpost = .f.
   gglpost = .f.
   gaccpath = "L:"
   gfileno = "01"
else
   gmaxage = fmaxage
   glimage = flimage
   gminage = fminage
   ggracehr = fgracehr
   ggraceins = fgraceins
   ggracefr = ffreehr
   gfuelchg = ffuelchg
   gfueltax = ffueltax
   gtaxrate = ftaxrate
   grafrmno = frafrmno
   gsurchg = fsurchg
   gsurtx = fsurtx
   gwkmin = fwkmin
   gwkmax = fwkmax
   gmthmin = fmthmin
   gmthmax = fmthmax
   grate = frack
   glocname = alltrim (fname)
   gcalday = fcalday
   gckintme = fckintme
   garpost = farpost
   gglpost = fglpost
   gaccpath = alltrim (fapath)
   gfileno = ffileno
endif
use

f_popback ()


******************************
procedure cleanup

quit

