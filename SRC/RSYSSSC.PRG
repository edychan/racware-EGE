* ===========================================================================
* System Configuration:
*
* 05/01/92
* Author: EDC
*
* Revision:
* 03/30/93: (edc) add garpost, gglpost, gaccpath & gfileno
* ===========================================================================
f_use ("RALOC")
yloc = gloc
seek gloc
l_frano = frano
l_fresvno = fresvno
l_fdbrno = fdbrno

f_use ("RASTN")
seek f_truncate (gstation, 8)
gloc = floc
gccnet = fccnet
gstgrp = fstgrp
gccreader = fccreader
gccmodem = fccmodem
gserver = fserver

set key 28 to rssschlp
f_use ("RASYS")
go top
restore from (gmempath + "RASYS") additive
f_retrieve ()
f_screen (0, "RASYS")
do while .t.
   f_rd ()
   ykeyin = f_confirm ("[C]onfirm   [E]dit   [I]gnore Changes", "CEI")
   if ykeyin = "C"
      select rastn
      reclock ()
      replace floc with gloc
      replace fccnet with gccnet
      replace fstgrp with gstgrp
      replace fccreader with gccreader
      replace fccmodem with gccmodem
      replace fserver with gserver
      commit
      unlock
      
      select rasys
      l_fmoddate = date ()
      f_replace ()
      gmaxusr = fmaxusr
      glgouttme = flgouttme
      gautopkvh = fautopkvh
      gtitle = alltrim (ftitle)
      gsup = fsup
      f_use ("RALOC")
      seek gloc
      if found ()
         gmaxage = fmaxage
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
         garpost = farpost
         gglpost = fglpost
         gaccpath = alltrim (fapath)
         gfileno = ffileno
      endif
      exit
   elseif ykeyin = "E"
      f_screen (1, "RASYS")
      loop
   else
      select rastn
      gloc = floc
      gccnet = fccnet
      gstgrp = fstgrp
      if empty (gccnet)
         gccmodem = .f.
      else
         gccmodem = fccmodem
      endif
      gccreader = fccreader
      gserver = fserver
      exit
   endif
enddo
set key 28 to
close databases


******************************
procedure rssschlp

private yvar, yarray[4], yptr

yvar = alltrim (upper (readvar()))
do case
case yvar = "GLOC"
   f_use ("raloc")
   go top
   if .not. eof ()
      if f_pick_f (03, 37, "", "", "floc+[->]+substr(fname,1,25)")
         &yvar = raloc->floc
         keyboard chr(13)
      endif
   endif
case yvar = "GCCNET"
   yarray[1] = " N/A ->Not in use           "
   yarray[2] = " LPA ->Transnet Inc.        "
   yarray[3] = " NDC ->National Data Corp.  "
   yptr = 1
   yptr = f_pick_a (11,32,"","",yarray,3,yptr)
   if yptr = 1
      &yvar = space(3)
      keyboard chr(13)
   elseif yptr > 1
      &yvar = substr(yarray[yptr],2,3)
      keyboard chr(13)
   endif
case yvar = "GCCREADER"
   yarray[1] = " 0 ->Not in use    "
   yarray[2] = " 1 ->Worthington   "
   yarray[3] = " 2 ->Keytronic     "
   yptr = 1
   yptr = f_pick_a (11,32,"","",yarray,3,yptr)
   if yptr = 1
      &yvar = 0
      keyboard chr(13)
   elseif yptr > 1
      &yvar = yptr - 1
      keyboard chr(13)
   endif
otherwise
   tone (500,9)
   f_popup ("No Help information for this Field. Press Any Key to Continue...",.t.)
endcase
set cursor on
return


******************************
function rsysssc1

if yloc = gloc
   return .t.
endif
if f_valid (gloc $ gusrloc)
   select raloc
   seek gloc
   l_frano = frano
   l_fdbrno = fdbrno
   l_fresvno = fresvno
   @ 15, 31 say l_frano pict "9999999"
   @ 16, 31 say l_fdbrno pict "9999999"
   @ 17, 31 say l_fresvno pict "9999999"
   yloc = gloc
   return .t.
else
   return .f.
endif

