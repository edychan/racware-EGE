*
* additional revenue report
*
private yret, yfile, i, yfld, ytitle, ycond, yopt, yfilter

rest from (gmempath + "rarpt") additive
bliovlclr ()

if empty (gete ("RACCPRT"))
   l_cprt = chr (27) + chr (15)
else
   l_cprt = alltrim (upper (gete ("RACCPRT")))
   l_cprt = &l_cprt
endif
if empty (gete ("RACNPRT"))
   l_nprt = chr (18)
else
   l_nprt = alltrim (upper (gete ("RACNPRT")))
   l_nprt = &l_nprt
endif

f_clrscn ("SUPPLEMENT REPORT")
l_formlen = 132
l_page = 0
l_date = dtoc (date ())
l_time = time ()

private ystart, yend, ycode, ytnm, yfnd, ystatus, yln, ylcnt, ydisp, ylogic

f_box (02, 05, 04, 78, "You have selected")
@ 03, 07 say "Additional Revenue Report"
ystart = date()
yend = date()
yac1 = space(4)
yac2 = space(4)
yac3 = space(4)
yac4 = space(4)
yac5 = space(4)
yac6 = space(4)

@ 07, 03 say "From Date...... " get ystart pict "@D"
@ 08, 03 say "To Date........ " get yend pict "@D"
@ 09, 03 say "Revenue Code... " get yac1 pict "!!!!"
@ 09, 25 get yac2 pict "!!!!"
@ 09, 30 get yac3 pict "!!!!"
@ 09, 35 get yac4 pict "!!!!"
@ 09, 40 get yac5 pict "!!!!"
@ 09, 45 get yac6 pict "!!!!"

if f_rd () = 27
  return
endif

ydisp = f_confirm ("[D]isplay on Screen  [P]rint [Q]uit", "DPQ")
if ydisp ="Q"
   return
endif

f_popup ("Please Wait...")

if .not. file (gstnpath + "sup_1.dbf")
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
   replace field_len with 5
   replace field_dec with 0
   append blank
   replace field_name with "FCDW"
   replace field_type with "N"
   replace field_len with 7
   replace field_dec with 2
   append blank
   replace field_name with "FPAI"
   replace field_type with "N"
   replace field_len with 7
   replace field_dec with 2
   append blank
   replace field_name with "FRESUP"
   replace field_type with "N"
   replace field_len with 6
   replace field_dec with 2
   append blank
   replace field_name with "FAC1"
   replace field_type with "N"
   replace field_len with 6
   replace field_dec with 2
   append blank
   replace field_name with "FAC2"
   replace field_type with "N"
   replace field_len with 6
   replace field_dec with 2
   append blank
   replace field_name with "FAC3"
   replace field_type with "N"
   replace field_len with 6
   replace field_dec with 2
   append blank
   replace field_name with "FAC4"
   replace field_type with "N"
   replace field_len with 6
   replace field_dec with 2
   append blank
   replace field_name with "FAC5"
   replace field_type with "N"
   replace field_len with 6
   replace field_dec with 2
   append blank
   replace field_name with "FAC6"
   replace field_type with "N"
   replace field_len with 6
   replace field_dec with 2
   use
   create (gstnpath + "sup_1") from (gstnpath + "stru")
   erase (gstnpath + "stru.dbf")
endif
use (gstnpath + "sup_1") exclusive alias sup_1
zap
index on fid+str(frano,6) to (gstnpath + "sup_1")

f_use ("rares")
f_use ("raagrh",4)
set relation to fresvno into rares
select raagrh
set softseek on
seek ystart
set softseek off
do while fdatein <= yend .and. .not. eof ()
   * get up sale
   if empty(raagrh->fresvno) .or. rares->fdlychg <= 0.00 .or. raagrh->fdays > 5
      yresup = 0
   else
     yresup = raagrh->ftmetot - rares->fdlychg * fdays
     yresup = if(yresup > 0, yresup, 0)
   endif
   * get add'l charge
   y1 = 0
   y2 = 0
   y3 = 0
   y4 = 0
   y5 = 0
   y6 = 0
   for i = 1 to 4
      yt1 = "raagrh->foitem"+str(i,1)
      yt2 = "raagrh->fotot"+str(i,1)
      yitem = &yt1
      do case
      case yac1 $ yitem 
         y1 = y1 + &yt2
      case yac2 $ yitem 
         y2 = y2 + &yt2
      case yac3 $ yitem 
         y3 = y3 + &yt2
      case yac4 $ yitem 
         y4 = y4 + &yt2
      case yac5 $ yitem 
         y5 = y5 + &yt2
      case yac6 $ yitem 
         y6 = y6 + &yt2
      endcase
   next i
   * update report db
   select sup_1
   append blank
   replace fid with raagrh->fid1, frano with raagrh->frano
   replace fdays with if(raagrh->fdays>9999,9999,raagrh->fdays), fcdw with raagrh->fcdwtot
   replace fpai with raagrh->fpaitot, fresup with yresup
   replace fac1 with y1, fac2 with y2, fac3 with y3
   replace fac4 with y4, fac5 with y5, fac6 with y6
   commit
   unlock
   select raagrh
   skip
enddo
select rares
use
select raagrh
use

select sup_1
go top
if eof ()
   f_valid (.f., "Empty Selection...")
   use
   return
endif 

l_ftitle = "Incremental Performance Report"+[  From: ]+dtoc(ystart)+  ;
           [ to: ]+dtoc(yend)
l_header = "RA #   Days        LDW        PAI        UPS        "+yac1+[      ]+yac2+[       ]+yac3+[       ]+yac4+[       ]+yac5+[       ]+yac6  
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

select sup_1
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
do while .not. eof ()
   yrow = if (yrow > 55, mgmt_hdr (ydisp, .t.), yrow)
   if fid <> ykey
      yrow = if (yrow+7 > 55, mgmt_hdr (ydisp, .t.), yrow)
      ykey = fid
      @ yrow, 01 say "AGENT: "+ ykey
      yrow = yrow + 1
      select sup_1
   endif
   ystr = str(frano,6)+[  ]+str(fdays,4)+[   ]+str(fcdw,8,2)+[   ]+ ;
          str(fpai,8,2)+[   ]+str(fresup,8,2)+[   ]+ ;
          str(fac1,8,2)+[   ]+str(fac2,8,2)+[   ]+str(fac3,8,2)+[   ]+ ;
          str(fac4,8,2)+[   ]+str(fac5,8,2)+[   ]+str(fac6,8,2)
   @ yrow, 01 say ystr
   yrow = yrow + 1
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
   skip
   if fid <> ykey
      yrow = yrow + 1
      ystr = [Totals: ]+str(ytotday,4)+[   ]+str(ycdwtot,8,2)+[   ]+ ;
          str(ypaitot,8,2)+[   ]+str(yrestot,8,2)+[   ]+ ;
          str(ytot1,8,2)+[   ]+str(ytot2,8,2)+[   ]+str(ytot3,8,2)+[   ]+ ;
          str(ytot4,8,2)+[   ]+str(ytot5,8,2)+[   ]+str(ytot6,8,2)
      @ yrow, 01 say ystr
      yrow = yrow + 1
      ytotday = if(ytotday > 0, ytotday, 1)
      ystr = [Yields: ]+space(4)+[   ]+str(ycdwtot/ytotday,8,2)+[   ]+ ;
          str(ypaitot/ytotday,8,2)+[   ]+str(yrestot/ytotday,8,2)+[   ]+ ;
          str(ytot1/ytotday,8,2)+[   ]+str(ytot2/ytotday,8,2)+[   ]+str(ytot3/ytotday,8,2)+[   ]+ ;
          str(ytot4/ytotday,8,2)+[   ]+str(ytot5/ytotday,8,2)+[   ]+str(ytot6/ytotday,8,2)
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
   endif
enddo

* output summary

mgmt_end (yrow)

select sup_1
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
   @ 0, 0 say replicate ("Ä", l_formlen-1)
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



