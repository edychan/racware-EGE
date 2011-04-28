* ===========================================================================
*
* Additional RR report for RacWare
*
* ===========================================================================
* -- Process a selected report --
* parameter reptname,parm1a,parm1b,parm2a,parm2b,parm3a,parm3b,parm4a,parm4b

public gstation, gdbfpath, gmempath, gstnpath, gmsgpath
public gdbffiles, gstnfiles, gusrid, gusrgp, gsup
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
gmaxusr = fmaxusr
glgouttme = flgouttme
gtitle = alltrim (ftitle)
gsup = .f.
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

use

*public gloc, gstgrp, gserver, gmaxusr, glgouttme

glocname = "RacWare Customize Report Writer"

*restore from (gmempath + "RAPATH") additive
*f_use ("RASTN")
*seek f_truncate (gstation, 8)
*if .not. found ()
*   append blank
*   restore from (gmempath + "RASTN") additive
*   l_fstn = gstation
*   f_replace ()
*endif
*gloc = floc
*gstgrp = fstgrp
*gserver = fserver
*use

*f_use ("RASYS")
*go top
*gmaxusr = fmaxusr
*glgouttme = flgouttme
*use
*f_popback ()
*l_fname = space(8)
if .not. file ("j:rrunin.dbf") 
   f_popup ("Missing Report Database !",.t.)
   clear
   quit
*elseif .not. file ("j:rrunin.ntx")
*   select 0
*   use j:rrunin excl
*   index on ri_report to j:rrunin
*   use
endif

if .not. file ("i:rarept.dbf")
   if .not. file ("j:rr_rept.dbf")
      f_popup ("Missing Report Parameter File !",.t.)
      clear
      quit
   else
      run copy j:rr_rept.dbf i:rarept.dbf
   endif
endif

do while .t.
   blimempak (-1)
   f_clrscn ("Customize Reports For RacWare")
   select 1
*  use j:rrunin index j:rrunin
   use j:rrunin
   if .not. eof()
      if f_pick_f (02, 3, "", "", "[ -> ]+ri_report+[ <- ]")
         f_box (02, 05, 04, 78, "You have selected")
         @ 03, 07 say ri_report
         l_foutopt = f_confirm ("[D]isplay on Screen  [P]rint [Q]uit", "DPQ")
         ychoice = recno()
         reclock()
         if l_foutopt = "D"
            replace ri_printer with "D"
         elseif l_foutopt = "P"
            replace ri_printer with "1"
         else
            loop
         endif
         unlock
         do case
         case ychoice = 1          && ra-tally report
             ystartdate = date()
             yenddate = date()
             yloc = space(10)
             yranum1 = 0
             yranum2 = 0
             @ 07, 07 say "LOCATION...."
             @ 08, 07 say "START DATE.."
             @ 09, 07 say "END DATE...."
             @ 10, 07 say "START RA#..."
             @ 11, 07 say "END RA#....."
             do while .t.
                @ 07, 19 get yloc pict "!!!!!!!!!!"
                @ 08, 19 get ystartdate 
                @ 09, 19 get yenddate
                @ 10, 19 get yranum1 pict "999999"
                @ 11, 19 get yranum2 pict "999999"
                f_rd ()
                l_foutopt = f_confirm ("Is this correct [Y/N] ", "YN")
                if l_foutopt = "Y"
                   exit
                endif
             enddo
             select 2
             use i:rarept
             rlock ()
             replace startdate with ystartdate, enddate with yenddate
             replace loc with yloc, num1 with yranum1, num2 with yranum2
             commit
             unlock
         case ychoice = 2          && Travel agent commission report
             ystartdate = date()
             yenddate = date()

             @ 07, 07 say "START DATE.."
             @ 08, 07 say "END DATE...."
             do while .t.
                @ 07, 19 get ystartdate 
                @ 08, 19 get yenddate
                f_rd ()
                l_foutopt = f_confirm ("Is this correct [Y/N] ", "YN")
                if l_foutopt = "Y"
                   exit
                endif
             enddo
             select 2
             use i:rarept
             rlock ()
             replace startdate with ystartdate, enddate with yenddate
             commit
             unlock
         otherwise
         endcase
         ynumber = str(ychoice,3)
         close data
         run rruntime j:rrunin &ynumber &gstation/I
       else
         close data
         quit
      endif
   else
      tone (500, 9)
      f_popup ("File is Empty. Press Any Key to Continue...",.t.)
      quit
   endif
enddo



