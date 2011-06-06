* ===========================================================================
* report module
*
* date: 05/01/91
* author: edc
*
* revision
* 03/04/94 (edc): fix missing ra report.
* 02.24.98 (edc): increase # of digits for vehicle revenue report
* 12.04.03: change Additional revenue by agent report (see mgmt_7)
*
* 12.26.07: allow both upper & lower case letter in printer control code
* 06.19.08: set upsell % (TG, GPS see mgmt_7)
* ---------------------------------------------------------------------------
* 03.20.09: add'l charge increase from 4 to 6
*           mgmt_7, _8, _9
* 11.13.09: add add'l filter for mgmt_7
* 12.02.09: add 3 add'l charge for mgmt_7
* ------------------------------------------------
* 01.05.10: mgmt_7: bug fix calculate subtotals
* 02.02.10: mgmt_7: display yield as 99.99
* 04.30.10: mgmt_7: setup RCP
* 05.06.10: mgmt_7: change commission % for CDW, RCP & Travel guide
* --
* 06.01.11: mgmt_7: ra prefix=1 => 1 and 2 combined totals
* ===========================================================================
private yret, yfile, i, yfld, ytitle, ycond, yopt, yfilter

rest from (gmempath + "rarpt") additive
bliovlclr ()

if empty (gete ("RACCPRT"))
   l_cprt = chr (27) + chr (15)
else
   l_cprt = alltrim (gete ("RACCPRT"))   &&12.26.07
   l_cprt = &l_cprt
endif
if empty (gete ("RACNPRT"))
   l_nprt = chr (18)
else
   l_nprt = alltrim (gete ("RACNPRT"))   && 12.26.07
   l_nprt = &l_nprt
endif
do while .t.
   xret1 = f_pushmenu (xoption0)
   blimempak (-1)
   if xret1 = 0
      exit
   endif
   xoption1 = substr (goption [xret1], 4)
   f_use ("rarpt")
   set filter to
   do case
   case xret1 = 1
      f_clrscn ("RENTAL & OPERATION REPORT")
      yfilter = "#1"
   case xret1 = 2
      f_clrscn ("RESERVATION REPORT")
      yfilter = "#2"
   case xret1 = 3
      f_clrscn ("CREDIT CARD REPORT")
      yfilter = "#3"
   case xret1 = 4
      f_clrscn ("INVENTORY REPORT")
      yfilter = "#4"
   case xret1 = 5
      f_clrscn ("MARKETING & SALE REPORT")
      yfilter = "#5"
   case xret1 = 6
      private ychoice [9]
      do while .t.
         f_clrscn ("MANAGEMENT REPORT")
         l_formlen = 132
         l_page = 0
         l_date = dtoc (date ())
         l_time = time ()
         ychoice[1] = "Vehicle Utilization Report   "
         ychoice[2] = "Vehicle Tally Report         "
         ychoice[3] = "Vehicle Revenue Report       "
         ychoice[4] = "RA Freqency Report           "
         ychoice[5] = "Missing RA Report            "
         ychoice[6] = "Travel Agent Commission      "
         ychoice[7] = "Additional Revenue by Agent  "
         ychoice[8] = "Additional Revenue by DBR    "
         ychoice[9] = "Location Yield Report        "
         yptr = 1
         yret = f_pick_a (02, 05, "", "", ychoice, 9, yptr)
         if yret = 0
            exit
         endif
         if yret = 1
            do mgmt_1  
         elseif yret = 2
            do mgmt_2
         elseif yret = 3
            do mgmt_3
         elseif yret = 4
            do mgmt_4
         elseif yret = 5
            do mgmt_5
         elseif yret = 6
            do mgmt_6
         elseif yret = 7
            do mgmt_7
         elseif yret = 8
            do mgmt_8
         elseif yret = 9
            do mgmt_9
         endif
      enddo
      loop
   case xret1 = 7
      do rrptrr
      loop
   endcase
   seek yfilter
   if .not. eof()
      if f_pick_f (02, 3, "", "", "[ -> ]+ftitle+[ <- ]","","fname","yfilter")
         yrname = rarpt->fname
         ytitle = ""
         ycond = ""
         yret = f_rr (yrname, ytitle)
         if yret < 0
            tone(500, 9)
            f_popup ("Invalid Report Setup... Error: "+str(yret,3) ;
               + ". Press Any Key...",.t.)
         endif
      endif
   else
      tone (500, 9)
      f_popup ("File is Empty. Press Any Key to Continue...",.t.)
   endif
enddo

release all like l_*
close database

**********************************
procedure mgmt_1
private y1, y2, yt, yrow, ycol, ystr, ydisp
private nloc, yloc [10], ytotal [10], yatot[10], yrtot[10]
private nclass, yclass[25]

f_box (02, 05, 04, 78, "You have selected")
@ 03, 07 say "Vehicle Utilization Report"

ydisp = f_confirm ("[D]isplay on Screen  [P]rint [Q]uit", "DPQ")
if ydisp ="Q"
   return
endif

f_popup ("Please Wait...")
f_use ("ravm")
select 0
if .not. file (gstnpath + "mgmt_1.dbf")
   create (gstnpath + "stru")
   use (gstnpath + "stru") exclusive
   append blank
   replace field_name with "FLOC"
   replace field_type with "C"
   replace field_len with 10
   replace field_dec with 0
   append blank
   replace field_name with "FCLASS"
   replace field_type with "C"
   replace field_len with 4
   replace field_dec with 0
   append blank
   replace field_name with "FAVAIL"
   replace field_type with "N"
   replace field_len with 5
   replace field_dec with 0
   append blank
   replace field_name with "FRENTED"
   replace field_type with "N"
   replace field_len with 5
   replace field_dec with 0
   append blank
   replace field_name with "FTOTAL"
   replace field_type with "N"
   replace field_len with 5
   replace field_dec with 0
   use
   create (gstnpath + "mgmt_1") from (gstnpath + "stru")
   erase (gstnpath + "stru.dbf")
endif
use (gstnpath + "mgmt_1") exclusive alias mgmt_1
index on floc + fclass to (gstnpath + "mgmt_1")
set index to (gstnpath + "mgmt_1")
zap

nclass = 0
y1 = ""
afill (yatot, 0)
afill (yrtot, 0)
afill (ytotal, 0)
select ravm
go top
do while .not. eof ()

   if .not. (fclass $ y1)
      nclass = if (nclass > 25, 25, nclass + 1)
      yclass [nclass] = fclass
      y1 = y1 + fclass + ";"
   endif

   select mgmt_1
   seek ravm->floc + ravm->fclass
   if eof ()
      append blank
      replace floc with ravm->floc, fclass with ravm->fclass
   endif
   if ravm->fstatus = "O"
      replace frented with frented + 1
   else
      replace favail with favail + 1
   endif
   replace ftotal with ftotal + 1
   select ravm
   skip

enddo
select ravm 
use
asort (yclass)

select mgmt_1
index on fclass to (gstnpath+"mgmt_1a.ntx")
total on fclass fields frented, favail, ftotal to (gstnpath+"mgmt_1t.dbf")
select 0
use (gstnpath+"mgmt_1t.dbf") excl alias mgmt_1t
 
select mgmt_1
set index to (gstnpath+"mgmt_1.ntx")
go top
nloc = 0
y2 = ""
do while .not. eof ()
   if .not. (floc $ y2)
      nloc = if (nloc > 10, 10, nloc + 1)
      yloc [nloc] = floc
      y2 = y2 + floc + "/"
   endif
   skip
enddo
asort (yloc)

l_ftitle = "Vehicle Utilization Report"
l_header = ""
for i = 1 to nloc
   l_header = l_header + yloc[i] + space(7)
next i
l_header = space(20) + l_header + [TOTAL]
yc1 = max (20, int (l_formlen/2) - int (len (gtitle) / 2))
yc2 = max (20, int (l_formlen/2) - int (len (l_ftitle) / 2))
yc3 = l_formlen - 12

f_popup ("Creating Report ...")
if ydisp = "D"
   yfil=gstnpath+"rrout.rpt"
   set device to print
   set printer to &yfil
else
   set device to print
endif

yrow = mgmt_hdr (ydisp, .f.)
select mgmt_1
go top
for i = 1 to nclass
   yrow = if (int (i/9)*9 = i, mgmt_hdr (ydisp, .t.), yrow)
   @ yrow, 01 say "CLASS: "+yclass[i]
   yrow = yrow + 2

   select mgmt_1
   @ yrow, 03 say "UNIT RENTED"
   ystr = ""
   for j = 1 to nloc
      seek yloc[j] + yclass[i]
      ystr = if (eof (), ystr + str(0,7) + str (0,6) + [%],  ;
                 ystr + str(frented,7) + str (frented/ftotal*100,6) + [%])
      yrtot[j] = if (eof (), yrtot[j], yrtot[j] + frented)
   next j
   select mgmt_1t
   locate for fclass = yclass [i]
   ystr = if (eof (), ystr + str(0,7) + str(0,6) + [%],  ;
          ystr + str(frented,7) + str (frented/ftotal*100,6) + [%])
   @ yrow, 20 say ystr

   yrow = yrow + 1
   select mgmt_1
   @ yrow, 03 say "UNIT AVAILABLE"
   ystr = ""
   for j = 1 to nloc
      seek yloc[j] + yclass[i]
      ystr = if (eof (), ystr + str(0,7) + str (0,6) + [%],  ;
                 ystr + str(favail,7) + str (favail/ftotal*100,6) + [%])
      yatot[j] = if (eof (), yatot[j], yatot[j] + favail)
   next j
   select mgmt_1t
   locate for fclass = yclass [i]
   ystr = if(eof (), ystr + str(0,7) + str(0,6) + [%],  ;
          ystr + str(favail,7) + str (favail/ftotal*100,6) + [%])
   @ yrow, 20 say ystr

   yrow = yrow + 1
   select mgmt_1
   @ yrow, 03 say "TOTAL UNITS"
   ystr = ""
   for j = 1 to nloc
      seek yloc[j] + yclass[i]
      ystr = if (eof (), ystr + str(0,7) + space(7),  ;
             ystr + str(ftotal,7) + space (7))
      ytotal[j] = if (eof (), ytotal[j], ytotal[j] + ftotal)
   next j
   select mgmt_1t
   locate for fclass = yclass [i]
   ystr = if (eof (), ystr + str(0,7) + space (7),   ;
          ystr + str(ftotal,7) + space (7))
   @ yrow, 20 say ystr

   yrow = yrow + 2

next i

@ yrow, 01 say "REPORT SUMMARY"
yrow = yrow + 1
ystr = ""
yt1 = 0
yt2 = 0
@ yrow, 03 say "UNIT RENTED"
for i = 1 to nloc
   ystr = ystr + str(yrtot[i],7) + str(yrtot[i]/ytotal[i]*100,6) + [%]
   yt1 = yt1 + yrtot [i]
   yt2 = yt2 + ytotal [i]
next i
ystr = ystr + str(yt1,7) + str(yt1/yt2*100,6) + [%]
@ yrow, 20 say ystr
yrow = yrow + 1
ystr = ""
yt1 = 0
@ yrow, 03 say "UNIT AVAILABLE"
for i = 1 to nloc
   ystr = ystr + str(yatot[i],7) + str(yatot[i]/ytotal[i]*100,6) + [%]
   yt1 = yt1 + yatot [i]
next i
ystr = ystr + str(yt1,7) + str(yt1/yt2*100,6) + [%]
@ yrow, 20 say ystr
yrow = yrow + 1
ystr = ""
yt1 = 0
@ yrow, 03 say "TOTAL UNITS"
for i = 1 to nloc
   ystr = ystr + str(ytotal[i],7) + space (7)
next i
ystr = ystr + str(yt2,7) 
@ yrow, 20 say ystr

mgmt_end (yrow)

select mgmt_1
use
select mgmt_1t
use

******************************
function mgmt_hdr

parameters xdisp, xfeed
private i, yln, ylen, ycol, ydesc
if xdisp = "P"
   if xfeed
      eject
   else
      setprc (0, 0)
      @ 00, 01 say l_cprt
   endif
elseif xfeed
   @ yrow+1, 0 say ""
   setprc (0, 0)   
   @ 0, 0 say replicate ("�", l_formlen-1)
else 
   setprc (0,0)
endif
l_page = l_page + 1
@ 01, 01 say 'DATE: ' + l_date
@ 01, yc1 say gtitle
@ 01, yc3 say 'PAGE: ' + str (l_page, 3)
@ 02, 01 say 'TIME: ' + l_time
@ 02, yc2 say l_ftitle
@ 04, 01 say l_header
yln = 6

return (yln)

**********************************
function mgmt_end
parameter xrow

if ydisp = "P"
   @ xrow + 1, 0 say l_nprt
   eject
endif

set device to screen
set printer to
set console on
set print off
if ydisp = "D"
   yfil=gstnpath+"rrout.rpt"
   setcolor ("W/N")
   clear
   run racbrow &yfil
   setcolor (gbluecolor)
endif

*************************************
procedure mgmt_2
private ydate, ymo, yyr, ystart, yend, ydays, ystatus, yln, ylcnt, ydisp
private ylogic, y1, y2, y3, ytotal, ycars

f_box (02, 05, 04, 78, "You have selected")
@ 03, 07 say "Monthly Vehicle Tally Report"
ydate = substr(dtoc(date()),1,2)+[/] + substr(dtoc(date()),7,2)
ydisp = "D"
@ 07, 03 say "Month....." get ydate pict "99/99" 
if f_rd () = 27
  return
endif

ymo = substr (ydate,1,2)
yyr = substr (ydate,4,2)
ydisp = f_confirm ("[D]isplay on Screen  [P]rint [Q]uit", "DPQ")
if ydisp ="Q"
   return
endif

f_popup ("Please Wait...")

ystart = ctod(ymo+"/01/"+yyr) 

* 08/10/95: chg for current month calc.
if ymo = substr(dtoc(date()),1,2) .and. yyr = substr(dtoc(date()),7,2)    
   ydays = val(substr(dtoc(date()),4,2))
   yend = date()
else
   for i = 31 to 28 step -1
      if .not. empty(ctod(ymo+"/"+str(i,2)+"/"+yyr))
         exit
      endif
   next
   ydays = i
   yend = ctod(ymo+"/"+str(i,2)+"/"+yyr)
endif

if .not. file (gstnpath + "mgmt_2.dbf")
   create (gstnpath + "stru")
   use (gstnpath + "stru") exclusive
   append blank
   replace field_name with "FUNIT"
   replace field_type with "C"
   replace field_len with 10
   replace field_dec with 0
   append blank
   replace field_name with "FSTATUS"
   replace field_type with "C"
   replace field_len with 31
   replace field_dec with 0
   use
   create (gstnpath + "mgmt_2") from (gstnpath + "stru")
   erase (gstnpath + "stru.dbf")
endif
use (gstnpath + "mgmt_2") exclusive alias mgmt_2
index on funit to (gstnpath + "mgmt_2")
zap

f_use ("ravm")
go top
do while .not. eof ()
   select mgmt_2
   seek ravm->funit
   if eof () .and. ravm->fpurdt <= yend       && ignore new acq. vehicles
      append blank
      replace funit with ravm->funit, fstatus with replicate("0",31)
   endif
   select ravm
   skip
enddo
select ravm 
use

f_use ("raagrh",4)
select raagrh
set softseek on
seek (ystart-31)       && assume max. open ra = 31 days
set softseek off
do while fdatein <= yend .and. .not. eof ()
   y1 = 0
   y2 = 0
   if raagrh->fdatein <= yend 
      if raagrh->fdateout < ystart
         y1 = 1
         y2 = (raagrh->fdatein - ystart) + 1
      else
         y1 = day (raagrh->fdateout)
         y2 = (raagrh->fdatein - raagrh->fdateout) + 1
      endif
   elseif raagrh->fdateout <= yend
      y1 = day (raagrh->fdateout)
      y2 = (yend - raagrh->fdateout) + 1
   elseif raagrh->fdateout < ystart .and. raagrh->fdatein > yend
      y1 = 1
      y2 = ydays
   endif
   if y1 > 0
      select mgmt_2
      seek raagrh->funit
      if eof ()
         append blank
         replace funit with raagrh->funit, fstatus with replicate("0",31)
      endif
      replace fstatus with stuff (fstatus, y1, y2, replicate ("1",y2))
   endif
   select raagrh
   skip
enddo
select raagrh 
use

f_use ("raagr")
set filter to frano <> 0
go top
do while .not. eof ()
   y1 = 0
   y2 = 0
   if raagr->fdatein <= yend 
      if raagr->fdateout < ystart
         y1 = 1
         y2 = (raagr->fdatein - ystart) + 1
      else
         y1 = day (raagr->fdateout)
         y2 = (raagr->fdatein - raagr->fdateout) + 1
      endif
   elseif raagr->fdateout <= yend
      y1 = day (raagr->fdateout)
      y2 = (yend - raagr->fdateout) + 1
   elseif raagr->fdateout < ystart .and. raagr->fdatein > yend
      y1 = 1
      y2 = ydays
   endif
   if y1 > 0
      select mgmt_2
      seek raagr->funit
      if eof ()
         append blank
         replace funit with raagr->funit, fstatus with replicate("0",31)
      endif
      replace fstatus with stuff (fstatus, y1, y2, replicate ("1",y2))
   endif
   select raagr
   skip
enddo
select raagr 
use

select mgmt_2
go top
if eof ()
   f_valid (.f., "Empty Selection...")
   use
   return
endif 

l_ftitle = "Monthly Vehicle Tally Report"+[   For: ]+ ymo + [/] + yyr
l_header = space(12)
for i = 1 to ydays
   l_header = l_header + str(i,3)
next
l_header = l_header + [  ] + [**T O T A L**]
yc1 = max (20, int (l_formlen/2) - int (len (gtitle) / 2))
yc2 = max (20, int (l_formlen/2) - int (len (l_ftitle) / 2))
yc3 = l_formlen - 12

f_popup ("Creating Report ...")
if ydisp = "D"
   yfil=gstnpath+"rrout.rpt"
   set device to print
   set printer to &yfil
else
   set device to print
endif

yrow = mgmt_hdr (ydisp, .f.)

private ytot [ydays]
afill (ytot, 0)
ytotal = 0
select mgmt_2
go top
ycars = reccount ()
do while .not. eof ()
   yrow = if (int (yrow/55)*55 = yrow, mgmt_hdr (ydisp, .t.), yrow)
   ystr = ""
   y1 = 0
   for i = 1 to ydays
      ystr = ystr + space(2) + substr(fstatus,i,1) 
      if substr(fstatus,i,1) = "1"
         y1 = y1 + 1
         ytot [i] = ytot [i] + 1
         ytotal = ytotal + 1
      endif
   next 
   ystr = funit+[  ]+ystr+[  ]+str(y1,3)+[  ]+str(y1/ydays*100,5,1)+[%]
   @ yrow, 01 say ystr
   yrow = yrow + 1
   skip
enddo
* output summary
l_header = ""
yrow = mgmt_hdr (ydisp, .t.)
yrow = yrow + 2
ystr = space(40) + "R E P O R T    S U M M A R Y"
@ yrow, 01 say ystr
yrow = yrow + 2
ystr = ""
for i = 1 to ydays
   ystr = ystr + str(i,4)
next
ystr = ystr+" TOTAL"
@ yrow, 01 say ystr
yrow = yrow + 2
ystr = ""
for i = 1 to ydays 
   ystr = ystr + str(ytot[i],4) 
next
ystr = ystr + [ ] + str(ytotal,4)
@ yrow, 01 say ystr
yrow = yrow + 1
ystr = " "
for i = 1 to ydays 
   ystr = ystr + str(ytot[i]/ycars*100,3)+[%]
next
ystr = ystr + [ ] + str(ytotal/(ycars*ydays)*100,3)+[%]
@ yrow, 01 say ystr

@ yrow+2, 01 say "TOTAL UNIT............... "+str(ycars,6)
@ yrow+4, 01 say "ACCUMULATED RENTAL DAYS.. "+str(ytotal,6)
@ yrow+6, 01 say "TOTAL RENTAL DAYS........ "+str(ycars*ydays,6)
@ yrow+8, 01 say "TOTAL UTILIZATION........ "+str(ytotal/(ycars*ydays)*100,6,2)+[%]
mgmt_end (yrow)

select mgmt_2
use

**********************************
procedure mgmt_3
private ystart, yend, yclass, yfnd, ystatus, yln, ylcnt, ydisp, ylogic

f_box (02, 05, 04, 78, "You have selected")
@ 03, 07 say "Vehicle Revenue Report"
yclass = space (4)
ystart = date()
yend = date()

@ 07, 3 say "Class....." get yclass pict "!!!!"
@ 08, 3 say "From......" get ystart pict "@D" valid f_y2k (@ystart)
@ 09, 3 say "To........" get yend pict "@D" valid ;
  f_valid (f_y2k (@yend) .and. yend >= ystart)
if f_rd () = 27
  return
endif

ydisp = f_confirm ("[D]isplay on Screen  [P]rint [Q]uit", "DPQ")
if ydisp ="Q"
   return
endif

f_popup ("Please Wait...")
if .not. file (gstnpath + "mgmt_3.dbf")
   create (gstnpath + "stru")
   use (gstnpath + "stru") exclusive
   append blank
   replace field_name with "FUNIT"
   replace field_type with "C"
   replace field_len with 10
   replace field_dec with 0
   append blank
   replace field_name with "FCLASS"
   replace field_type with "C"
   replace field_len with 4
   replace field_dec with 0
   append blank
   replace field_name with "FMODEL"
   replace field_type with "C"
   replace field_len with 13
   replace field_dec with 0
   append blank
   replace field_name with "FPRICE"
   replace field_type with "N"
   replace field_len with 8
   replace field_dec with 2
   append blank
   replace field_name with "FTNM"
   replace field_type with "N"
   replace field_len with 8
   replace field_dec with 2
   append blank
   replace field_name with "FCDW"
   replace field_type with "N"
   replace field_len with 8
   replace field_dec with 2
   append blank
   replace field_name with "FDAYS"
   replace field_type with "N"
   replace field_len with 4
   replace field_dec with 0
   use
   create (gstnpath + "mgmt_3") from (gstnpath + "stru")
   erase (gstnpath + "stru.dbf")
endif
use (gstnpath + "mgmt_3") exclusive alias mgmt_3
zap
index on funit+fclass to (gstnpath + "mgmt_3")

f_use ("ravm")
f_use ("raagrh",4)
set relation to funit into ravm
select raagrh
set softseek on
seek ystart
set softseek off
do while fdatein <= yend .and. .not. eof ()
   select mgmt_3
   seek raagrh->funit
   if eof()
      if ravm->fclass = yclass
         select mgmt_3 
         append blank
         replace funit with raagrh->funit, fclass with ravm->fclass
         replace fmodel with ravm->fyear+[ ]+ravm->fmodel, fprice with ravm->fpuramt
         replace ftnm with raagrh->ftmetot+raagrh->fmlgtot, fcdw with raagrh->fcdwtot
         ydays = raagrh->fdatein-raagrh->fdateout
         replace fdays with if(ydays>0, ydays, 1)
      endif
   else
      ydays = raagrh->fdatein-raagrh->fdateout
      rlock ()
      replace ftnm with ftnm+raagrh->ftmetot+raagrh->fmlgtot
      replace fcdw with fcdw+raagrh->fcdwtot
      replace fdays with fdays+if(ydays>0, ydays, 1)
   endif
   select raagrh
   skip     
enddo   
select ravm 
use 
select raagrh
use

select mgmt_3
go top
if eof ()
   f_valid (.f., "Empty Selection...")
   use
   return
else
   store 0 to sumtnm, sumcdw, sumdays, sumrev, sumavg
   sum ftnm, fcdw, ftnm+fcdw, fdays, (ftnm+fcdw)/fdays to   ;
       sumtnm, sumcdw, sumrev, sumdays, sumavg
endif 

l_ftitle = "Vehicle Revenue Report"+[ / ]+yclass+[ From: ]+dtoc(ystart)+  ;
           [ to: ]+dtoc(yend)
l_header = "UNIT #    MODEL           PURCHASE     T & M        "+  ;
           "CDW    # DAYS    REVENUE       AVG REV."
yc1 = max (20, int (l_formlen/2) - int (len (gtitle) / 2))
yc2 = max (20, int (l_formlen/2) - int (len (l_ftitle) / 2))
yc3 = l_formlen - 12

f_popup ("Creating Report ...")
if ydisp = "D"
   yfil=gstnpath+"rrout.rpt"
   set device to print
   set printer to &yfil
else
   set device to print
endif

yrow = mgmt_hdr (ydisp, .f.)

select mgmt_3
go top
do while .not. eof ()
   yrow = if (int (yrow/55)*55 = yrow, mgmt_hdr (ydisp, .t.), yrow)
   ystr = funit+[ ]+fmodel+[ ]+str(fprice,8,2)+[ ]+str(ftnm,10,2)+[  ]+  ;
          str(fcdw,10,2)+[  ]+str(fdays,7)+[  ]+str(ftnm+fcdw,10,2)+[  ]+   ;
          str((ftnm+fcdw)/fdays,10,2)
   @ yrow, 01 say ystr
   yrow = yrow + 1
   skip
enddo

* output summary
yrow = yrow + 2
ystr = space(34)+str(sumtnm,10,2)+[  ]+str(sumcdw,10,2)+  ;
      [  ]+str(sumdays,7)+[  ]+str(sumrev,10,2)+[  ]+str(sumavg,10,2)
@ yrow,1 say ystr

mgmt_end (yrow)

select mgmt_3
use

**********************************
procedure mgmt_4

* RA frequency report
private ystart, yend, yloc, yfnd, ystatus, yln, ylcnt, ydisp
* ydow1 == total checkout for day of week
* ydow2 == total checkin for day of week
private i, i1, ylogic, y1, y2, y3, ydow1 [7], ydow2 [7], ydow [7]

afill (ydow1, 0)
afill (ydow2, 0)

f_box (02, 05, 04, 78, "You have selected")
@ 03, 07 say "RA Frequency Report"
yloc = gloc
ystart = date()
yend = date()
ydisp = "D"
yshow = "D"
@ 07, 3 say "Location............ " get yloc pict "!!!!!!!!!!" valid   ;
        f_valid (f_verify("raloc",1,yloc) .or. empty(yloc))
@ 08, 3 say "From................ " get ystart pict "@D" valid f_y2k (@ystart)
@ 09, 3 say "To.................. " get yend pict "@D" valid f_y2k (@yend)
@ 10, 3 say "[S]ummary/[D]etail.. " get yshow pict "!" valid ;
        f_valid (yshow $ "S;D")
if f_rd () = 27
  return
endif

ydisp = f_confirm ("[D]isplay on Screen  [P]rint [Q]uit", "DPQ")
if ydisp ="Q"
   return
endif

f_popup ("Please Wait...")
if .not. file (gstnpath + "mgmt_4.dbf")
   create (gstnpath + "stru")
   use (gstnpath + "stru") exclusive
   append blank
   replace field_name with "FDATE"
   replace field_type with "D"
   replace field_len with 8
   replace field_dec with 0
   append blank
   replace field_name with "FTIME"
   replace field_type with "C"
   replace field_len with 5
   replace field_dec with 0
   append blank
   replace field_name with "FRANO"
   replace field_type with "N"
   replace field_len with 6
   replace field_dec with 0
   append blank
   replace field_name with "FUNIT"
   replace field_type with "C"
   replace field_len with 10
   replace field_dec with 0
   append blank
   replace field_name with "FSTATUS"
   replace field_type with "C"
   replace field_len with 1
   replace field_dec with 0
   use
   create (gstnpath + "mgmt_4") from (gstnpath + "stru")
   erase (gstnpath + "stru.dbf")
endif
use (gstnpath + "mgmt_4") exclusive alias mgmt_4
zap

f_use ("raagrh",4)
select raagrh
set softseek on
seek (ystart-31)       && assume max. open ra = 31 days
set softseek off
ylogic = if(empty(yloc),".t.","raagrh->floc=yloc .or. raagrh->frloc=yloc")
do while fdatein <= yend .and. .not. eof ()
   if raagrh->fdateout >= ystart .and. raagrh->fdateout <= yend .and. &ylogic
      select mgmt_4
      append blank
      replace fdate with raagrh->fdateout, ftime with raagrh->ftimeout
      replace frano with raagrh->frano, funit with raagrh->funit
      replace fstatus with "O"
   endif
   if raagrh->fdatein >= ystart .and. raagrh->fdatein <= yend .and. &ylogic
      select mgmt_4
      append blank
      replace fdate with raagrh->fdatein, ftime with raagrh->ftimein
      replace frano with raagrh->frano, funit with raagrh->funit
      replace fstatus with "I"
   endif
   select raagrh
   skip
enddo
select raagrh 
use

f_use ("raagr")
set filter to frano <> 0
go top
ylogic = if(empty(yloc),".t.","raagr->floc=yloc")
do while .not. eof ()
   if raagr->fdateout >= ystart .and. raagr->fdateout <= yend .and. &ylogic
      select mgmt_4
      append blank
      replace fdate with raagr->fdateout, ftime with raagr->ftimeout
      replace frano with raagr->frano, funit with raagr->funit
      replace fstatus with "O"
   endif
   select raagr
   skip
enddo
select raagr 
use

select mgmt_4
go top
if eof ()
   f_valid (.f., "Empty Selection...")
   use
   return
else
   index on DTOS(FDATE)+FTIME to (gstnpath + "mgmt_4")
endif 

l_ftitle = "RA Frequency Report"+[   From: ]+dtoc(ystart)+  ;
           [ to: ]+dtoc(yend)
l_header = "DATE      TIME    RA#     UNIT#       ACTION   "
yc1 = max (20, int (l_formlen/2) - int (len (gtitle) / 2))
yc2 = max (20, int (l_formlen/2) - int (len (l_ftitle) / 2))
yc3 = l_formlen - 12

f_popup ("Creating Report ...")
if ydisp = "D"
   yfil=gstnpath+"rrout.rpt"
   set device to print
   set printer to &yfil
else
   set device to print
endif

yrow = mgmt_hdr (ydisp, .f.)

select mgmt_4
go top
ykey = fdate
y1 = 0
y2 = 0
y3 = 0
do while .not. eof ()
   if yshow = "D"
      yrow = if (int (yrow/55)*55 = yrow, mgmt_hdr (ydisp, .t.), yrow)
      ystr = dtoc(fdate)+[  ]+ftime+[   ]+str(frano,6)+[  ]+funit+[  ]+  ;
          if(fstatus="O","CHECK OUT","CHECK IN")
      @ yrow, 01 say ystr
      yrow = yrow + 1
   endif
   i1 = dow(fdate)
   if fstatus = "O"
      y1 = y1 + 1
      ydow1 [i1] = ydow1 [i1] + 1
   elseif fstatus = "I"
      y2 = y2 + 1
      ydow2 [i1] = ydow2 [i1] + 1
   endif
   y3 = y3 + 1
   skip
   if fdate <> ykey .and. yshow = "D"
      ykey = fdate
      @ yrow, 01 say "CHECK OUT = " + str(y1,4) + [   ] +  ;
                     "CHECK IN  = " + str(y2,4) + [   ] +  ;
                     "TOTAL     = " + str(y3,4)
      yrow = yrow + 2
      y1 = 0
      y2 = 0
      y3 = 0
   endif
enddo

ydow [1] = "Sunday:   "
ydow [2] = "Monday:   "
ydow [3] = "Tuesday:  "
ydow [4] = "Wednesday:"
ydow [5] = "Thursday: "
ydow [6] = "Friday:   "
ydow [7] = "Saturday: "

for i = 1 to 7
   yrow = if (int (yrow/55)*55 = yrow, mgmt_hdr (ydisp, .t.), yrow)
   @ yrow, 01 say "For " + ydow [i] + [   ] + ;
                  "CHECK OUT = " + str(ydow1[i],5) + [   ] +  ;
                  "CHECK IN  = " + str(ydow2[i],5) + [   ] +  ;
                  "TOTAL     = " + str(ydow1[i]+ydow2[i],5)
   yrow = yrow + 2
next
 
mgmt_end (yrow)

select mgmt_4
use

*************************
procedure mgmt_5
private yrano1, yrano2, yloc, yfnd, ystatus, yln, ylcnt, ydisp

f_box (02, 05, 04, 78, "You have selected")
@ 03, 07 say "Missing RA Report"
yloc = gloc
yrano1 = 0
yrano2 = 0

@ 07, 3 say "Location.." get yloc pict "!!!!!!!!!!" valid   ;
        f_valid (f_verify("raloc",1,yloc) .or. empty(yloc))
@ 08, 3 say "From RA # " get yrano1 pict "999999"
@ 09, 3 say "To RA #   " get yrano2 pict "999999"
if f_rd () = 27
   return
endif

ydisp = f_confirm ("[D]isplay on Screen  [P]rint [Q]uit", "DPQ")
if ydisp ="Q"
   return
endif

if empty (yloc)
   f_use ("raloc")
   private ylocary [reccount ()]
   go top
   nloc = 0
   do while .not. eof ()
      if floc $ gusrloc
         nloc = nloc + 1
         ylocary [nloc] = floc
      endif
      skip
   enddo
   use
endif

f_use ("RAAGR")
f_use ("RAAGRH")
yln = 0
ylcnt = 0
f_popup ("Creating Report ...")
if ydisp = "D"
   yfil=gstnpath+"rrout.rpt"
   set device to print
   set printer to &yfil
else
   set device to print
endif
for n = yrano1 to yrano2
   yfnd = .f.
   ystatus = "MISSING"
   select raagr
   if empty (yloc)
      for n1 = 1 to nloc
         seek ylocary [n1] + str (n, 6)
         if found ()
            ystatus = "OPEN RA"
            yfnd = .t.
            exit
         endif
      next
   else
      seek yloc + str (n, 6)
      if found ()
         * ystatus = "CLOSED "  
         ystatus = "OPEN RA"        && 03/04/94:EDC 
         yfnd = .t.
      endif
   endif
   if .not. yfnd
      select raagrh
      if empty (yloc)
         for n1 = 1 to nloc
            seek ylocary [n1] + str (n, 6)
            if found ()
               yfnd = .t.
               ystatus = "CLOSED "
               exit
            endif
         next
      else
         seek yloc + str (n, 6)
         if found ()
            yfnd = .t.
            ystatus = "CLOSED "
         endif
      endif
   endif
   *if .not. yfnd
      if yln > 56
         if ydisp = "D"
            @ yln + 1, 0 say replicate (chr (196), 78)
            @ yln + 2, 0 say ""
            setprc (0, 0)
         else
            eject
         endif
         yln = 0
      endif
      if yln = 0
         @ 1, 0 say "MISSING RA REPORT AS OF " + DTOC (DATE ())
         @ 2, 0 say "FOR LOCATION " + yloc + "   From " + str (yrano1, 6) + ;
            "   To " + str (yrano2, 6)
         yln = 4
      endif
      @ yln, ylcnt * 16 say f_truncate (ltrim (str (n, 6)), 7) + [-] +  ;
                            ystatus + [ ]
      if ylcnt = 4
         yln = yln + 1
         ylcnt = 0
      else
         ylcnt = ylcnt + 1
      endif
   *endif
next
if yln > 0 .and. ydisp = "P"
   eject
endif
select raagrh
use
select raagr
use
set device to screen
set printer to
set console on
set print off
if ydisp = "D"
   yfil=gstnpath+"rrout.rpt"
   setcolor ("W/N")
   clear
   run racbrow &yfil
   setcolor (gbluecolor)
endif

**********************************
procedure mgmt_6
private ystart, yend, ytnm, yfnd, ystatus, yln, ylcnt, ydisp, ylogic

f_box (02, 05, 04, 78, "You have selected")
@ 03, 07 say "Travel Agent Commission Report"
ystart = date()
yend = date()

@ 07, 3 say "From......" get ystart pict "@D" valid f_y2k (@ystart)
@ 08, 3 say "To........" get yend pict "@D" valid ;
  f_valid (f_y2k (@yend) .and. yend >= ystart)
if f_rd () = 27
  return
endif

ydisp = f_confirm ("[D]isplay on Screen  [P]rint [Q]uit", "DPQ")
if ydisp ="Q"
   return
endif

f_popup ("Please Wait...")
if .not. file (gstnpath + "mgmt_6.dbf")
   create (gstnpath + "stru")
   use (gstnpath + "stru") exclusive
   append blank
   replace field_name with "FATC"
   replace field_type with "C"
   replace field_len with 10
   replace field_dec with 0
   append blank
   replace field_name with "FCOMPANY"
   replace field_type with "C"
   replace field_len with 30
   replace field_dec with 0
   append blank
   replace field_name with "FLOC"
   replace field_type with "C"
   replace field_len with 10
   replace field_dec with 0
   append blank
   replace field_name with "FRANO"
   replace field_type with "N"
   replace field_len with 6
   replace field_dec with 0
   append blank
   replace field_name with "FRESVNO"
   replace field_type with "C"
   replace field_len with 10
   replace field_dec with 0
   append blank
   replace field_name with "FLNAME"
   replace field_type with "C"
   replace field_len with 15
   replace field_dec with 0
   append blank
   replace field_name with "FDATEIN"
   replace field_type with "D"
   replace field_len with 8
   replace field_dec with 0
   append blank
   replace field_name with "FRATE"
   replace field_type with "C"
   replace field_len with 5
   replace field_dec with 0
   append blank
   replace field_name with "FDAYS"
   replace field_type with "N"
   replace field_len with 4
   replace field_dec with 0
   append blank
   replace field_name with "FTNM"
   replace field_type with "N"
   replace field_len with 8
   replace field_dec with 2
   append blank
   replace field_name with "FCOMMPCT"
   replace field_type with "N"
   replace field_len with 2
   replace field_dec with 0
   append blank
   replace field_name with "FCOMM"
   replace field_type with "N"
   replace field_len with 6
   replace field_dec with 2
   use
   create (gstnpath + "mgmt_6") from (gstnpath + "stru")
   erase (gstnpath + "stru.dbf")
endif
use (gstnpath + "mgmt_6") exclusive alias mgmt_6
zap
index on fcompany+fatc+fresvno to (gstnpath + "mgmt_6")

f_use ("raagnt")
f_use ("rares")
set relation to fatc into raagnt
f_use ("raagrh",4)
set relation to fresvno into rares
select raagrh
set softseek on
seek ystart
set softseek off
do while fdatein <= yend .and. .not. eof ()
   if empty (raagrh->fresvno) .or. empty(rares->fatc)
      skip
      loop
   endif
   select mgmt_6
   ytnm = raagrh->ftmetot+raagrh->fmlgtot-raagrh->fdisctot
   append blank
   replace fatc with rares->fatc, fcompany with raagnt->fcompany
   replace floc with raagrh->floc
   replace frano with raagrh->frano, fresvno with raagrh->fresvno
   replace flname with raagrh->flname+[ ]+substr(raagrh->ffname,1,1)
   replace fdatein with raagrh->fdatein
   replace frate with raagrh->frate, fdays with raagrh->fdays
   replace ftnm with ytnm, fcommpct with rares->fcommpct
   replace fcomm with ytnm * rares->fcommpct / 100
   select raagrh
   skip
enddo
select rares
use
select raagrh
use

select mgmt_6
go top
if eof ()
   f_valid (.f., "Empty Selection...")
   use
   return
endif 

l_ftitle = "Travel Agent Commission Report"+[  From: ]+dtoc(ystart)+  ;
           [ to: ]+dtoc(yend)
l_header = "RENTAL AGREEMENT   RES #      RENTER               DATE  "+  ;
           "RATE  DAYS   T & M    COMMISSION"
yc1 = max (20, int (l_formlen/2) - int (len (gtitle) / 2))
yc2 = max (20, int (l_formlen/2) - int (len (l_ftitle) / 2))
yc3 = l_formlen - 12

f_popup ("Creating Report ...")
if ydisp = "D"
   yfil=gstnpath+"rrout.rpt"
   set device to print
   set printer to &yfil
else
   set device to print
endif

yrow = mgmt_hdr (ydisp, .f.)

select mgmt_6
go top
ykey = "~"
y1 = 0
y2 = 0
do while .not. eof ()
   yrow = if (yrow > 55, mgmt_hdr (ydisp, .t.), yrow)
   if fatc <> ykey
      yrow = if (yrow+7 > 55, mgmt_hdr (ydisp, .t.), yrow)
      ykey = fatc
      select raagnt
      seek ykey
      @ yrow, 01 say "AGENT: "+ ykey
      yrow = yrow + 1
      @ yrow, 08 say raagnt->fcompany+space(5)+raagnt->fphone
      yrow = yrow + 1
      @ yrow, 08 say raagnt->faddr
      yrow = yrow + 1
      if .not. empty (raagnt->faddr1)
         @ yrow, 08 say raagnt->faddr1
         yrow = yrow + 1
      endif
      @ yrow, 08 say raagnt->fcity+space(2)+raagnt->fstate+space(2)+raagnt->fzip
      yrow = yrow + 2
      select mgmt_6
   endif
   ystr = floc+[ ]+str(frano,6)+[ ]+fresvno+[ ]+flname+[ ]+  ;
          dtoc(fdatein)+[ ]+frate+[ ]+str(fdays,4)+[  ]+   ;
          str(ftnm,8,2)+[  ]+str(fcommpct,2)+[%  ]+str(fcomm,6,2)
   @ yrow, 01 say ystr
   yrow = yrow + 1
   y1 = y1 + 1
   y2 = y2 + fcomm
   skip
   if fatc <> ykey
      @ yrow, 01 say "# of RA: " + str(y1,4) + space(5) +  ;
                     "Commission = " + str(y2,8,2)
      yrow = yrow + 3
      y1 = 0
      y2 = 0
   endif
enddo

* output summary

mgmt_end (yrow)

select mgmt_6
use

**********************************
* 11.13.09: add add'l filter
* 12.02.09: add 3 add'l charge code
* 12.09.09: take out yxxx 
* --
* 06.01.11: ra prefix =1 => 1 and 2 combined
* --
procedure mgmt_7
private yret, yfile, i, yfld, ytitle, ycond, yopt, yfilter, ydetail,ydays
private ystart, yend, ycode, ytnm, yfnd, ystatus, yln, ylcnt, ydisp, ylogic
private yf1, yf2, yf3, yf4, yf5, yf6, yxxx   && 12.03.03
private yseq   && 11.11.09

f_box (02, 05, 04, 78, "You have selected")
@ 03, 07 say "Additional Revenue by Agent Report"
ystart = date()
yend = date()
yac1 = space(4)
yac2 = space(4)
yac3 = space(4)
yac4 = space(4)
yac5 = space(4)
yac6 = space(4)
* --12.02.09
yac7 = space(4)
yac8 = space(4)
yac9 = space(4)
* --
yxxx = space(4)     && 12.10.03:special code to run old report
ydetail = "N"
yseq = 0            && 11.13.09: ra filter default is ALL

@ 07, 03 say "From Date...... " get ystart pict "@D" valid f_y2k (@ystart)
@ 08, 03 say "To Date........ " get yend pict "@D" valid f_y2k (@yend)
@ 09, 03 say "Revenue Code... " get yac1 pict "!!!!"
@ 09, 25 get yac2 pict "!!!!"
@ 09, 30 get yac3 pict "!!!!"
@ 09, 35 get yac4 pict "!!!!"
@ 09, 40 get yac5 pict "!!!!"
@ 09, 45 get yac6 pict "!!!!"
* --12.02.09
@ 09, 50 get yac7 pict "!!!!"
@ 09, 55 get yac8 pict "!!!!"
@ 09, 60 get yac9 pict "!!!!"

* --12.09.09
* @ 09, 65 get yxxx pict "!!!!" valid ;      && 12.10.03
*   f_valid (empty(yxxx).or.yxxx=[BILL].or.yxxx=[QR],"Please enter [BILL] or [QR]")    && 10.30.06  
* -- 11.13.09

@ 10, 03 say "RA Prefix...... " get yseq pict "9" valid ;
  f_valid (yseq >=0 .and. yseq <= 3, "Please enter 0, 1, 2 or 3")
* --
@ 11, 03 say "Detail [Y/N]... " get ydetail pict "!" valid f_valid (ydetail $ "YN")
if f_rd () = 27
  return
endif

ydisp = f_confirm ("[D]isplay on Screen  [P]rint [Q]uit", "DPQ")
if ydisp ="Q"
   return
endif

f_popup ("Please Wait...")
yac1 = if (empty(yac1), yac1, alltrim(yac1))
yac2 = if (empty(yac2), yac2, alltrim(yac2))
yac3 = if (empty(yac3), yac3, alltrim(yac3))
yac4 = if (empty(yac4), yac4, alltrim(yac4))
yac5 = if (empty(yac5), yac5, alltrim(yac5))
yac6 = if (empty(yac6), yac6, alltrim(yac6))
* --12.02.09
yac7 = if (empty(yac7), yac7, alltrim(yac7))
yac8 = if (empty(yac8), yac8, alltrim(yac8))
yac9 = if (empty(yac9), yac9, alltrim(yac9))
* --

* -- 06.19.08: set upsell % accordingly
* -- 04.30.10: set up RCP
if empty(yxxx)
   do case
   case yac1 $ "FPO;HFP"
      yf1 = .25
   case yac1 $ "GPS"
      yf1 = .7
   case yac1 $ "TG;RCP"        && --05.06.10: change comm %
      yf1 = .9
   otherwise
      yf1 = 1
   endcase

   do case
   case yac2 $ "FPO;HFP"
      yf2 = .25
   case yac2 $ "GPS"
      yf2 = .7
   case yac2 $ "TG;RCP"
      yf2 = .9
   otherwise
      yf2 = 1
   endcase

   do case
   case yac3 $ "FPO;HFP"
      yf3 = .25
   case yac3 $ "GPS"
      yf3 = .7
   case yac3 $ "TG;RCP"
      yf3 = .9
   otherwise
      yf3 = 1
   endcase

   do case
   case yac4 $ "FPO;HFP"
      yf4 = .25
   case yac4 $ "GPS"
      yf4 = .7
   case yac4 $ "TG;RCP"
      yf4 = .9
   otherwise
      yf4 = 1
   endcase

   do case
   case yac5 $ "FPO;HFP"
      yf5 = .25
   case yac5 $ "GPS"
      yf5 = .7
   case yac5 $ "TG;RCP"
      yf5 = .9
   otherwise
      yf5 = 1
   endcase

   do case
   case yac6 $ "FPO;HFP"
      yf6 = .25
   case yac6 $ "GPS"
      yf6 = .7
   case yac6 $ "TG;RCP"
      yf6 = .9
   otherwise
      yf6 = 1
   endcase

   do case
   case yac7 $ "FPO;HFP"
      yf7 = .25
   case yac7 $ "GPS"
      yf7 = .7
   case yac7 $ "TG;RCP"
      yf7 = .9
   otherwise
      yf7 = 1
   endcase

   do case
   case yac8 $ "FPO;HFP"
      yf8 = .25
   case yac8 $ "GPS"
      yf8 = .7
   case yac8 $ "TG;RCP"
      yf8 = .9
   otherwise
      yf8 = 1
   endcase

   do case
   case yac9 $ "FPO;HFP"
      yf9 = .25
   case yac6 $ "GPS"
      yf9 = .7
   case yac9 $ "TG;RCP"
      yf9 = .9
   otherwise
      yf9 = 1
   endcase
else
   yf1 = 1
   yf2 = 1
   yf3 = 1
   yf4 = 1
   yf5 = 1
   yf6 = 1

   yf7 = 1
   yf8 = 1
   yf9 = 1

endif
*  ---- 06.19.08

if .not. file (gstnpath + "mgmt_7.dbf")
   create (gstnpath + "stru")
   use (gstnpath + "stru") exclusive
   append blank
   replace field_name with "FID"
   replace field_type with "C"
   replace field_len with 3
   replace field_dec with 0
   append blank
   replace field_name with "FRANO"
   replace field_type with "N"
   replace field_len with 6
   replace field_dec with 0
   append blank
   replace field_name with "FDAYS"
   replace field_type with "N"
   replace field_len with 6
   replace field_dec with 0
   append blank
   replace field_name with "FCDW"
   replace field_type with "N"
   replace field_len with 8
   replace field_dec with 2
   append blank
   replace field_name with "FPAI"
   replace field_type with "N"
   replace field_len with 8
   replace field_dec with 2
   append blank
   replace field_name with "FRESUP"
   replace field_type with "N"
   replace field_len with 8
   replace field_dec with 2
   append blank
   replace field_name with "FAC1"
   replace field_type with "N"
   replace field_len with 8
   replace field_dec with 2
   append blank
   replace field_name with "FAC2"
   replace field_type with "N"
   replace field_len with 8
   replace field_dec with 2
   append blank
   replace field_name with "FAC3"
   replace field_type with "N"
   replace field_len with 8
   replace field_dec with 2
   append blank
   replace field_name with "FAC4"
   replace field_type with "N"
   replace field_len with 8
   replace field_dec with 2
   append blank
   replace field_name with "FAC5"
   replace field_type with "N"
   replace field_len with 8
   replace field_dec with 2
   append blank
   replace field_name with "FAC6"
   replace field_type with "N"
   replace field_len with 8
   replace field_dec with 2
   * --12.02.09
   append blank
   replace field_name with "FAC7"
   replace field_type with "N"
   replace field_len with 8
   replace field_dec with 2
   append blank
   replace field_name with "FAC8"
   replace field_type with "N"
   replace field_len with 8
   replace field_dec with 2
   append blank
   replace field_name with "FAC9"
   replace field_type with "N"
   replace field_len with 8
   replace field_dec with 2
   * --

   use
   create (gstnpath + "mgmt_7") from (gstnpath + "stru")
   erase (gstnpath + "stru.dbf")
endif
use (gstnpath + "mgmt_7") exclusive alias mgmt_7
zap
index on fid+str(frano,6) to (gstnpath + "mgmt_7")

f_use ("rares")
f_use ("raagrh",4)
set relation to fresvno into rares
select raagrh
set softseek on
seek ystart
set softseek off
do while fdatein <= yend .and. .not. eof ()
   * ? recno()  && debug

   * --11.13.09
   if yseq = 1     && 06/01/11: => 1 and 2
      ii = val(substr(str(frano,6),1,1))
      if ii < 1 .or. ii > 2    && 1 and 2
         skip
         loop
      endif
   elseif yseq > 1
      if val(substr(str(frano,6),1,1)) <> yseq
         skip
         loop
      endif
   endif
   * --

   if empty(yxxx) .and. raagrh->fcustno = "QR"      && 12.03.03
      skip
      loop
   elseif yxxx=[QR] .and. raagrh->fcustno <> "QR"   && 10.30.06
      skip
      loop 
   endif
   * get up sale (replace up sale with SLI 12.10.99)
   yresup = 0
   * get add'l charge
   y1 = 0
   y2 = 0
   y3 = 0
   y4 = 0
   y5 = 0
   y6 = 0
   * --12.02.09
   y7 = 0
   y8 = 0
   y9 = 0
   * --

   * for i = 1 to 4
   for i = 1 to 6    && 03.20.09
      yt1 = "raagrh->foitem"+str(i,1)
      yt2 = "raagrh->fotot"+str(i,1)
      yitem = &yt1
      * 12.10.99
      if "SLI" $ yitem
         yresup = yresup + &yt2
      endif

      * -- 06.18.08 calc base on upsell %
      do case
      case yac1 $ yitem
         y1 = y1 + yf1*&yt2 
      case yac2 $ yitem 
         y2 = y2 + yf2*&yt2
      case yac3 $ yitem 
         y3 = y3 + yf3*&yt2
      case yac4 $ yitem 
         y4 = y4 + yf4*&yt2
      case yac5 $ yitem 
         y5 = y5 + yf5*&yt2
      case yac6 $ yitem 
         y6 = y6 + yf6*&yt2
      * --12.02.09
      case yac7 $ yitem 
         y7 = y7 + yf7*&yt2
      case yac8 $ yitem 
         y8 = y8 + yf8*&yt2
      case yac9 $ yitem 
         y9 = y9 + yf9*&yt2
      * --
      endcase
      * ---

   next i
   * 10.30.06
   ydays = if(raagrh->frhr > 1,raagrh->fdays + 1,raagrh->fdays)
   ydays = if(raagrh->ftotal>0,ydays,0)
   * update report db
   select mgmt_7
   append blank
   replace fid with raagrh->fid1, frano with raagrh->frano
   replace fdays with ydays
   replace fcdw with raagrh->fcdwtot * .9     && 05.06.10: set comm %
   replace fpai with raagrh->fpaitot, fresup with yresup
   replace fac1 with y1, fac2 with y2, fac3 with y3
   replace fac4 with y4, fac5 with y5, fac6 with y6
   replace fac7 with y7, fac8 with y8, fac9 with y9
   commit
   unlock
   select raagrh
   skip
enddo
select rares
use
select raagrh
use

select mgmt_7
go top
if eof ()
   f_valid (.f., "Empty Selection...")
   use
   return
endif 

l_ftitle = "Additional Revenue by Agent Report"+[  From: ]+dtoc(ystart)+  ;
           [ to: ]+dtoc(yend)
* l_header = "RA #   Days        LDW        PAI        UPS        "+yac1+[      ]+yac2+[       ]+yac3+[       ]+yac4+[       ]+yac5+[       ]+yac6  
* l_header = "RA #   Days        LDW        PAI        SLI        "+yac1+[        ]+yac2+[        ]+yac3+[        ]+yac4+[        ]+yac5+[        ]+yac6  
l_header = "RA #   Days        LDW        PAI        SLI"+space(6)+yac1+[    ]+yac2+[   ]+yac3+[   ]+yac4+[   ]+yac5+[   ]+yac6+[   ]+yac7+[  ]+yac8+[   ]+yac9  

yc1 = max (20, int (l_formlen/2) - int (len (gtitle) / 2))
yc2 = max (20, int (l_formlen/2) - int (len (l_ftitle) / 2))
yc3 = l_formlen - 12

f_popup ("Creating Report ...")
if ydisp = "D"
   yfil=gstnpath+"rrout.rpt"
   set device to print
   set printer to &yfil
else
   set device to print
endif

yrow = mgmt_hdr (ydisp, .f.)

select mgmt_7
go top
ykey = "~"
ytotday = 0
ycdwtot = 0
ypaitot = 0
yrestot = 0
ytot1 = 0
ytot2 = 0
ytot3 = 0
ytot4 = 0
ytot5 = 0
ytot6 = 0
* --12.02.09
ytot7 = 0
ytot8 = 0
ytot9 = 0
ytt = 0
* --
ygtotday = 0
ygcdwtot = 0
ygpaitot = 0
ygrestot = 0
ygtot1 = 0
ygtot2 = 0
ygtot3 = 0
ygtot4 = 0
ygtot5 = 0
ygtot6 = 0
* --12.02.09
ygtot7 = 0
ygtot8 = 0
ygtot9 = 0
* --
do while .not. eof ()
   yrow = if (yrow > 55, mgmt_hdr (ydisp, .t.), yrow)
   if fid <> ykey
      yrow = if (yrow+7 > 55, mgmt_hdr (ydisp, .t.), yrow)
      ykey = fid
      @ yrow, 01 say "AGENT: "+ ykey
      yrow = yrow + 1
      select mgmt_7
   endif
   if ydetail = [Y]
      ystr = str(frano,6)+[  ]+str(fdays,4)+[   ]+str(fcdw,8,2)+[   ]+ ;
          str(fpai,8,2)+[   ]+str(fresup,8,2)+[   ]+ ;
          str(fac1,5)+[  ]+str(fac2,5)+[  ]+str(fac3,5)+[  ]+ ;
          str(fac4,5)+[  ]+str(fac5,5)+[  ]+str(fac6,5)+[  ]+ ;
          str(fac7,5)+[  ]+str(fac8,5)+[  ]+str(fac9,5)+[  ]+ ;
          str(fcdw+fpai+fresup+fac1+fac2+fac3+fac4+fac5+fac6+fac7+fac8+fac9,8,2)
      @ yrow, 01 say ystr
      yrow = yrow + 1
   endif
   ytotday = ytotday + fdays
   ycdwtot = ycdwtot + fcdw
   ypaitot = ypaitot + fpai
   yrestot = yrestot + fresup
   ytot1 = ytot1 + fac1
   ytot2 = ytot2 + fac2
   ytot3 = ytot3 + fac3
   ytot4 = ytot4 + fac4
   ytot5 = ytot5 + fac5
   ytot6 = ytot6 + fac6

   ytot7 = ytot7 + fac7
   ytot8 = ytot8 + fac8
   ytot9 = ytot9 + fac9

   ygtotday = ygtotday + fdays
   ygcdwtot = ygcdwtot + fcdw
   ygpaitot = ygpaitot + fpai
   ygrestot = ygrestot + fresup
   ygtot1 = ygtot1 + fac1
   ygtot2 = ygtot2 + fac2
   ygtot3 = ygtot3 + fac3
   ygtot4 = ygtot4 + fac4
   ygtot5 = ygtot5 + fac5
   ygtot6 = ygtot6 + fac6

   ygtot7 = ygtot7 + fac7
   ygtot8 = ygtot8 + fac8
   ygtot9 = ygtot9 + fac9

   skip
   if fid <> ykey
      yrow = yrow + 1
      * --01.05.10: correct subtotal (bug fix)
      ytt = ycdwtot+ypaitot+yrestot+ytot1+ytot2+ytot3+ytot4+ytot5+ytot6+ytot7+ytot8+ytot9
      * --
      ystr = [Totals: ]+str(ytotday,4)+[  ]+str(ycdwtot,9,2)+[  ]+ ;
          str(ypaitot,9,2)+[  ]+str(yrestot,9,2)+[  ]+ ;
          str(ytot1,6)+[ ]+str(ytot2,6)+[ ]+str(ytot3,6)+[ ]+ ;
          str(ytot4,6)+[ ]+str(ytot5,6)+[ ]+str(ytot6,6)+[ ]+ ;
          str(ytot7,6)+[ ]+str(ytot8,6)+[ ]+str(ytot9,6)+[ ]+ ;
          str(ytt,9,2)
      @ yrow, 01 say ystr
      yrow = yrow + 1
      ytotday = if(ytotday > 0, ytotday, 1)
      * 02.02.10: display yield as 99.99
      ystr = [Yields: ]+space(4)+[   ]+str(ycdwtot/ytotday,8,2)+[   ]+ ;
          str(ypaitot/ytotday,8,2)+[   ]+str(yrestot/ytotday,8,2)+[   ]+ ;
          str(ytot1/ytotday,5,2)+[  ]+str(ytot2/ytotday,5,2)+[  ]+str(ytot3/ytotday,5,2)+[  ]+ ;
          str(ytot4/ytotday,5,2)+[  ]+str(ytot5/ytotday,5,2)+[  ]+str(ytot6/ytotday,5,2)+[  ]+ ;
          str(ytot7/ytotday,5,2)+[  ]+str(ytot8/ytotday,5,2)+[  ]+str(ytot9/ytotday,5,2)+[  ]+ ;
          str(ytt/ytotday,8,2)
      @ yrow, 01 say ystr
      yrow = yrow + 2
      ytotday = 0
      ycdwtot = 0
      ypaitot = 0
      yrestot = 0
      ytot1 = 0
      ytot2 = 0
      ytot3 = 0
      ytot4 = 0
      ytot5 = 0
      ytot6 = 0

      ytot7 = 0
      ytot8 = 0
      ytot9 = 0

   endif
enddo

* output summary
yrow = yrow + 1
* -- 01.05.10: bug fix 
* ytt = ygcdwtot+ygpaitot+ygrestot+ygtot1+ygtot2+ygtot3+ygtot4+ygtot5+ygtot6
ytt = ygcdwtot+ygpaitot+ygrestot+ygtot1+ygtot2+ygtot3+ygtot4+ygtot5+ygtot6+ygtot7+ygtot8+ygtot9
* --
ystr = [Grand : ]+str(ygtotday,4)+[  ]+str(ygcdwtot,9,2)+[  ]+ ;
       str(ygpaitot,9,2)+[  ]+str(ygrestot,9,2)+[  ]+ ;
       str(ygtot1,6)+[ ]+str(ygtot2,6)+[ ]+str(ygtot3,6)+[ ]+ ;
       str(ygtot4,6)+[ ]+str(ygtot5,6)+[ ]+str(ygtot6,6)+[ ]+ ;
       str(ygtot7,6)+[ ]+str(ygtot8,6)+[ ]+str(ygtot9,6)+[ ]+ ;
       str(ytt,9,2)
@ yrow, 01 say ystr
yrow = yrow + 1
ygtotday = if(ygtotday > 0, ygtotday, 1)
* 02.02.10: display yield as 99.99
ystr = [Yields: ]+space(4)+[  ]+str(ygcdwtot/ygtotday,9,2)+[  ]+ ;
       str(ygpaitot/ygtotday,9,2)+[  ]+str(ygrestot/ygtotday,9,2)+[  ]+ ;
       str(ygtot1/ygtotday,6,2)+[ ]+str(ygtot2/ygtotday,6,2)+[ ]+str(ygtot3/ygtotday,6,2)+[ ]+ ;
       str(ygtot4/ygtotday,6,2)+[ ]+str(ygtot5/ygtotday,6,2)+[ ]+str(ygtot6/ygtotday,6,2)+[ ]+ ;
       str(ygtot7/ygtotday,6,2)+[ ]+str(ygtot8/ygtotday,6,2)+[ ]+str(ygtot9/ygtotday,6,2)+[ ]+ ;
       str(ytt/ygtotday,9,2)
@ yrow, 01 say ystr

mgmt_end (yrow)

select mgmt_7
use

**********************************
procedure mgmt_8
private yret, yfile, i, yfld, ytitle, ycond, yopt, yfilter
private ystart, yend, ycode, ytnm, yfnd, ystatus, yln, ylcnt, ydisp, ylogic

f_box (02, 05, 04, 78, "You have selected")
@ 03, 07 say "Additional Revenue by DBR Report"
yloc = gloc
ydbrno = 0
@ 07, 03 say "Location....... " get yloc pict "!!!!!!!!!!"
@ 08, 03 say "DBR............ " get ydbrno pict "9999" valid ;
  f_valid (f_verify("radbr",1,yloc+str(ydbrno,4))) 
if f_rd () = 27
  return
endif
select radbr
ystart = radbr->frptdate - 7
yend = radbr->frptdate + 7
use

ydisp = f_confirm ("[D]isplay on Screen  [P]rint [Q]uit", "DPQ")
if ydisp ="Q"
   return
endif

f_popup ("Please Wait...")

if .not. file (gstnpath + "mgmt_8.dbf")
   create (gstnpath + "stru")
   use (gstnpath + "stru") exclusive
   append blank
   replace field_name with "FSTN"
   replace field_type with "C"
   replace field_len with 1
   replace field_dec with 0
   append blank
   replace field_name with "FDESC"
   replace field_type with "C"
   replace field_len with 4
   replace field_dec with 0
   append blank
   replace field_name with "FTOTAL"
   replace field_type with "N"
   replace field_len with 9
   replace field_dec with 2
   use
   create (gstnpath + "mgmt_8") from (gstnpath + "stru")
   erase (gstnpath + "stru.dbf")
endif
use (gstnpath + "mgmt_8") exclusive alias mgmt_8
zap
index on fstn+fdesc to (gstnpath + "mgmt_8")

f_use ("raagrh",4)
set softseek on
seek ystart
set softseek off
do while fdatein <= yend .and. .not. eof ()
   if raagrh->floc <> yloc .or.  ;
      raagrh->fdbrno <> ydbrno
      skip
      loop
   endif
   * get #ra, #days, CDW, PAI
   select mgmt_8
   seek substr(str(raagrh->frano,6),1,1)+"#RA"
   if eof ()
      append blank
      replace fstn with substr(str(raagrh->frano,6),1,1), fdesc with [#RA]
   endif
   replace ftotal with ftotal + 1
   seek substr(str(raagrh->frano,6),1,1)+"#DAY"
   if eof ()
      append blank
      replace fstn with substr(str(raagrh->frano,6),1,1), fdesc with [#DAY]
   endif
   replace ftotal with ftotal + raagrh->fdays
   seek substr(str(raagrh->frano,6),1,1)+"CDW"
   if eof ()
      append blank
      replace fstn with substr(str(raagrh->frano,6),1,1), fdesc with [CDW]
   endif
   replace ftotal with ftotal + raagrh->fcdwtot
   seek substr(str(raagrh->frano,6),1,1)+"PAI"
   if eof ()
      append blank
      replace fstn with substr(str(raagrh->frano,6),1,1), fdesc with [PAI]
   endif
   replace ftotal with ftotal + raagrh->fpaitot
   * get add'l charge
   * for i = 1 to 4
   for i = 1 to 6    && 03.20.09
      yt1 = "raagrh->foitem"+str(i,1)
      yt2 = "raagrh->fotot"+str(i,1)
      yitem = &yt1
      if .not. empty(yitem)
         seek substr(str(raagrh->frano,6),1,1)+yitem
         if eof ()
            append blank
            replace fstn with substr(str(raagrh->frano,6),1,1), fdesc with yitem
         endif
         replace ftotal with ftotal + &yt2
      endif
   next i
   select raagrh
   skip
enddo
select raagrh
use

select mgmt_8
go top
if eof ()
   f_valid (.f., "Empty Selection...")
   use
   return
endif 

l_ftitle = "Additional Revenue Summary Report"+[  DBR: ]+str(ydbrno,5)
l_header = "   STATION   DESC       TOTAL"
yc1 = max (20, int (l_formlen/2) - int (len (gtitle) / 2))
yc2 = max (20, int (l_formlen/2) - int (len (l_ftitle) / 2))
yc3 = l_formlen - 12

f_popup ("Creating Report ...")
if ydisp = "D"
   yfil=gstnpath+"rrout.rpt"
   set device to print
   set printer to &yfil
else
   set device to print
endif

yrow = mgmt_hdr (ydisp, .f.)

select mgmt_8
go top
ykey = "~"
do while .not. eof ()
   yrow = if (yrow > 55, mgmt_hdr (ydisp, .t.), yrow)
   if ykey <> fstn
      ykey = fstn
      ystr = space(7) + fstn + [     ] + fdesc + [   ] + str(ftotal,9,2)
      yrow = yrow + 1
   else
      ystr = space(8) + [     ] + fdesc + [   ] + str(ftotal,9,2)
   endif
   @ yrow, 01 say ystr
   yrow = yrow + 1
   skip
enddo

* output summary
select mgmt_8
index on fdesc to (gstnpath + "mgmt_8")
total on fdesc fields ftotal to (gstnpath + "mgmt_8a")
use (gstnpath + "mgmt_8a")
go top
yrow = yrow + 2
yrow = if (yrow > 55, mgmt_hdr (ydisp, .t.), yrow)
@ yrow, 01 say "Summary:"
yrow = yrow + 2
do while .not. eof ()
   yrow = if (yrow > 55, mgmt_hdr (ydisp, .t.), yrow)
   ystr = space(8) + [     ] + fdesc + [   ] + str(ftotal,9,2)
   @ yrow, 01 say ystr
   yrow = yrow + 1
   skip
enddo
use

mgmt_end (yrow)

***************************
* Add'l Revenue summary report
procedure mgmt_9
private yret, yfile, i, yfld, ytitle, ycond, yopt, yfilter
private yloc, ystart, yend, ycode, ytnm, yfnd, ystatus, yln, ylcnt, ydisp

f_box (02, 05, 04, 78, "You have selected")
@ 03, 07 say "Location Yield Report"
yloc = gloc
ystart = date()
yend = date()
@ 06, 03 say "Location....... " get yloc pict "!!!!!!!!!!"
@ 07, 03 say "From Date...... " get ystart pict "@D" valid f_y2k (@ystart)
@ 08, 03 say "To Date........ " get yend pict "@D" valid ;
  f_valid (f_y2k (@yend) .and. yend >= ystart)       

if f_rd () = 27
  return
endif

ydisp = f_confirm ("[D]isplay on Screen  [P]rint [Q]uit", "DPQ")
if ydisp ="Q"
   return
endif

f_popup ("Please Wait...")
* load paycode array
f_use ("rapaycd")
ip = reccount()
private ypcode [ip], ypdesc [ip], yptot [ip], yncnt [ip]
i = 1 
go top
do while .not. eof ()
   ypcode [i] = fpaycd
   ypdesc [i] = fitem
   yptot [i] = 0
   yncnt [i] = 0
   i = i + 1
   skip
enddo
ip = i - 1
select rapaycd
use
* accumulate total
private ydays, ynra, ycdw, ypai, ysli, yupg, ywu, yra1, yra2, yytot
private yncdw, ynpai, ynsli, ynupg, ynwu
store 0 to ydays, ynra, ycdw, ypai, ysli, yupg, ywu
store 0 to yncdw, ynpai, ynsli, ynupg, ynwu
f_use ("raagrh",4)
set softseek on
seek ystart
set softseek off
yra1 = 999999
yra2 = 0
do while fdatein <= yend .and. .not. eof ()
   * 
   if raagrh->floc <> yloc .or. raagrh->ftotal <= 0    && skip 0 revenue ra
      skip
      loop
   endif
   * find starting and ending ra
   if frano < yra1
      yra1 = frano
   endif
   if frano > yra2
      yra2 = frano
   endif
   * accumulate # days and ra
   ynra = ynra + 1
   ydays = ydays + if (frhr >= 3, fdays + 1, fdays + frhr / 3)
   * accumulate cdw, pai, sli, upg
   ycdw = ycdw + fcdwtot
   ypai = ypai + fpaitot
   * accumulate %
   yncdw = if(fcdwtot > 0, yncdw + 1, yncdw)
   ynpai = if(fpaitot > 0, ynpai + 1, ynpai)
   * check add'l charge
   * for i = 1 to 4
   for i = 1 to 6   && 03.20.09
      yt1 = "raagrh->foitem"+str(i,1)
      yt2 = "raagrh->fotot"+str(i,1)
      yitem = &yt1
      if .not. empty(yitem)
         for j = 1 to ip
            if yitem = ypcode [j]
               yptot [j] = yptot [j] + &yt2
               yncnt [j] = if(&yt2 > 0, yncnt [j] + 1, yncnt [j])
               exit
            endif
         next j 
      endif
   next i
   skip
enddo
select raagrh
use

l_ftitle = "Location Yield Report"+[  From: ]+dtoc(ystart)+  ;
           [ to: ]+dtoc(yend)
l_header = " "
yc1 = max (20, int (l_formlen/2) - int (len (gtitle) / 2))
yc2 = max (20, int (l_formlen/2) - int (len (l_ftitle) / 2))
yc3 = l_formlen - 12

f_popup ("Creating Report ...")
if ydisp = "D"
   yfil=gstnpath+"rrout.rpt"
   set device to print
   set printer to &yfil
else
   set device to print
endif

yrow = mgmt_hdr (ydisp, .f.)

* output line items
y1 = if(ynra > 0, ynra, 1)
@ yrow, 03 say "# RA............" + str(ynra,9)
yrow = yrow + 1
@ yrow, 03 say "# Days.........." + str(ydays,9,2)
yrow = yrow + 2
@ yrow, 03 say "LDW Total......." + str(ycdw,9,2) + space(5) + str(yncdw/y1*100,6,2)+[ %]
yrow = yrow + 1
@ yrow, 03 say "PAI Total......." + str(ypai,9,2) + space(5) + str(ynpai/y1*100,6,2)+[ %]
yrow = yrow + 2
yytot = ycdw + ypai + ysli + yupg
for i = 1 to ip
   @ yrow, 03 say ypdesc [i] + ": " + str(yptot [i],8,2) + space(5) + str(yncnt[i]/y1*100,6,2)+[ %]
   yytot = yytot + yptot [i]
   yrow = yrow + 1
next i
yrow = yrow + 2
@ yrow, 03 say "Location Total.." + str(yytot, 9,2)
yrow = yrow + 1
@ yrow, 03 say "Location Yield.." + str(yytot / ydays,9,2)

mgmt_end (yrow)
close all        && leave this in... (edc)





