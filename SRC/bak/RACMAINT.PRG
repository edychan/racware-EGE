public gstation, gdbfpath, gmempath, gstnpath, gmsgpath
public gdbffiles, gstnfiles, gusrid, gusrgp
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
set century on      && y2k

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

afill (gboxsav, .f.)
afill (gscrsav, .f.)

gmenulevel = 0
gsup = .f.

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

if .not. file (gmempath + "RAPATH.MEM")
   do racs with .f.
endif
public gloc, gstgrp, gserver, gmaxusr, glgouttme

glocname = "RAC File Maintenance"

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
gserver = fserver
use

f_use ("RASYS")
go top
gmaxusr = fmaxusr
glgouttme = flgouttme
use
f_popback ()

do while .t.
   if .not. usrlgin ()
      loop
   endif
   do while .t.
      xret0 = f_pushmenu ("MAINTENANCE MENU")
      if xret0 = 0
         if usrlgout (.t.)
            exit
         else
           loop
         endif
      endif
      blimempak (-1)
      do case
         case xret0 = 1            && initialize 
            do racs with .t.
         case xret0 = 2            && browse database
            do rsysud
         case xret0 = 3            && recover index/pack database
            do rsysmri
         case xret0 = 4            && rebuild database
            do rsysum
         case xret0 = 5            && update ra print form
            do rsysfm          
      endcase
   enddo
enddo


******************************
procedure racs

parameter xdisplay
if xdisplay
  f_clrscn ("Initialize Indexes/Databases")
  setcolor (gbluecolor)
  @ 01, 01 say "All users MUST log off the system at this time !"
  ywhich = .f.
  @ 02, 01 say "Do you want to continue? [Y/N] " get ywhich picture "Y"
  f_rd ()
  if .not. ywhich
     return
  endif
  ywhich = .f.
  @ 03,01 SAY "ARE YOU SURE? [Y/N] " get ywhich pict "Y"
  f_rd ()
  if .not. ywhich
     return
  endif
endif
select 0
use (gdbfpath + "RAIDX") alias raidx
if file (gdbfpath + "RAIDX.NTX")
   set index to (gdbfpath + "RAIDX")
else
   index on fname + fodr to (gdbfpath + "RAIDX")
endif
select 0
use (gdbfpath + "RAPATH") alias rapath
public gfilnum
count for .not. deleted () to gfilnum

public gfilattr [gfilnum]
go top
gfilnum = 0
do while .not. eof ()
   gfilnum = gfilnum + 1
   xstr = "_G" + alltrim (fname)
   public &xstr
   &xstr = str (gfilnum, 2) + f_truncate (fpath, 1)
   select raidx
   seek rapath->fname
   do while fname = rapath->fname .and. .not. eof ()
      &xstr = &xstr + f_truncate (fndx, 8)
      skip
   enddo
   select rapath
   xstr = "_GK" + alltrim (fname)
   public &xstr
   if empty (fkeyfld)
      &xstr = ""
   else
      &xstr = alltrim (str (fkeyodr, 1) + fkeyfld)
      xstr = "_GB" + alltrim (fname)
      public &xstr
      xstr1 = alltrim (fblankfld)
      &xstr = &xstr1
   endif
   skip
enddo
use

save to (gmempath + "RAPATH") all like _g*
select raidx
use

use (gdbfpath + "dbsetup")
if file (gdbfpath + "dbsetup.ntx")
   set index to (gdbfpath + "dbsetup")
else
   index on f_name + f_code + f_field to (gdbfpath + "dbsetup")
endif

go top
xp_name = f_name
xp_code = f_code
do while .not. eof ()
   blimempak (-1)
   if f_code = "D"
      xfilestr = "_G" + alltrim (xp_name)
      if .not. f_valid (type (xfilestr) = "C", ;
            "Error: Unknown File: " + xp_name)
         quit
      endif
      xpath = substr (&xfilestr, 3, 1)
      do case
      case xpath = "D"
         xpath = gdbfpath
      case xpath = "S"
         xpath = gstnpath
      otherwise
         xpath = ""
      endcase
      if .not. file (xpath + trim (dbsetup->f_name) + ".DBF")
         select 0
         create filetmp
         use filetmp exclusive
         select dbsetup
         f_popup ("Creating " + trim (xp_name))
         do while f_name == xp_name .and. f_code == xp_code .and. .not. eof ()
            select filetmp
            append blank
            replace field_name with dbsetup->f_field
            replace field_type with dbsetup->f_type
            replace field_len with dbsetup->f_width
            replace field_dec with dbsetup->f_dec
            select dbsetup
            xfname = "L_" + f_field
            if empty (f_init)
               if f_type = "C"
                  &xfname = space (f_width)
               elseif f_type = "N"
                  &xfname = 0
               elseif f_type = "D"
                  &xfname = ctod (space (8))
               elseif f_type = "L"
                  &xfname = .f.
               endif
            else
               xfinit = f_init
               &xfname = &xfinit
            endif
            skip
         enddo
         f_popup ("Please Wait While Initializing...")
         select filetmp
         create (xpath + trim (xp_name) + ".dbf") from filetmp
         save to (gmempath + trim (xp_name) + ".mem") all like l_*
         release all like l_*
         use
         erase filetmp.dbf
         select dbsetup
      elseif .not. file (gmempath + trim (dbsetup->f_name) + ".MEM")
         do while f_name == xp_name .and. f_code == xp_code .and. .not. eof ()
            xfname = "L_" + f_field
            if empty (f_init)
               if f_type = "C"
                  &xfname = space (f_width)
               elseif f_type = "N"
                  &xfname = 0
               elseif f_type = "D"
                  &xfname = ctod (space (8))
               elseif f_type = "L"
                  &xfname = .f.
               endif
            else
               xfinit = f_init
               &xfname = &xfinit
            endif
            skip
         enddo
         save to (gmempath + trim (xp_name) + ".mem") all like l_*
         release all like l_*
      else
         do while f_name == xp_name .and. f_code == xp_code .and. .not. eof ()
            skip
         enddo
      endif
   elseif f_code = "M"
      if .not. file (gmempath + trim (dbsetup->f_name) + ".MEM")
         xfprev = left (f_field, 2) + "*"
         do while f_name == xp_name .and. f_code == xp_code .and. .not. eof ()
            xfname = f_field
            if empty (f_init)
               if f_type = "C"
                  &xfname = space (f_width)
               elseif f_type = "N"
                  &xfname = 0
               elseif f_type = "D"
                  &xfname = ctod (space (8))
               elseif f_type = "L"
                  &xfname = .f.
               endif
            else
               xfinit = f_init
               &xfname = &xfinit
            endif
            skip
         enddo
         save to (gmempath + trim (xp_name) + ".mem") all like &xfprev
         release all like l_*
      else
         do while f_name == xp_name .and. f_code == xp_code .and. .not. eof ()
            skip
         enddo
      endif
   else
      skip
   endif
   xp_name = f_name
   xp_code = f_code
enddo
use
f_popup ("Please Wait While Checking Indexes...")

f_use ("RAIDX")
go top

do while .not. eof ()
   xfname = alltrim (fname)
   xfndx = alltrim (fndx)
   xfilestr = "_G" + xfname
   do case
   case substr (&xfilestr, 3, 1) = "D"
      xpath = gdbfpath
   case substr (&xfilestr, 3, 1) = "S"
      xpath = gstnpath
   otherwise
      xpath = ""
   endcase

   if .not. file (xpath + xfndx + ".NTX")
      if .not. f_valid (file (xpath + xfname + ".DBF"), ;
            "Error: " + xfname + ".DBF Does Not Exist")
         quit
      endif
      xsel = left (&xfilestr, 2)
      select &xsel
      use (xpath + xfname)
      filelock ()
      xidx = raidx->fidx
      f_popup ("Creating Index: " + xfndx)
      index on &xidx to (xpath + xfndx)
      use

      select raidx
   endif
   skip
enddo
use
f_popback ()


