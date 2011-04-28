* ===========================================================================
* Reservation Tally sheet
*
* date: 06/07/93
* author: edc
*
* revision
*
* ===========================================================================

*f_clrscn ()
*do f_resvgrid
*close databases

f_clrscn ("Reservation Tally Report")
setcolor (gsubcolor)
f_box (2, 5, 6, 66)
ydate1 = dtoc(date ())
ymmyy = substr(ydate1,1,2)+"/"+substr(ydate1,7,2)
yloc = gloc
yclasses = space (4)
yunits = 0

@ 3, 7 say "Location [ALL].............."
@ 4, 7 say "Date........................"
@ 5, 7 say "Class......................."

do while .t.
   @ 3, 36 get yloc picture "!!!!!!!!!!" ;
     valid f_valid (yloc $ gusrloc .or. yloc='ALL')
   @ 4, 36 get ymmyy      && valid f_valid (ydate1 >= date ())
   @ 5, 36 get yclasses pict replicate ("!", 4)
   f_rd ()
   ydisp = f_confirm ("[D]isplay  [P]rint   [E]dit   [Q]uit", "EDPQ")
   if ydisp = "Q"
      close databases
      return
   endif
   if ydisp $ "DP"
      exit
   endif
enddo

f_popup ("Creating Tally Report Database", .f.)

select 0
if .not. file (gstnpath + "ratally.dbf")
   create (gstnpath + "stru")
   use (gstnpath + "stru") exclusive
   append blank
   replace field_name with "FRESVNO", field_type with "C"
   replace field_len with 10
   append blank
   replace field_name with "FUNIT", field_type with "C"
   replace field_len with 3
   append blank
   replace field_name with "FSTART", field_type with "D"
   replace field_len with 8
   append blank
   replace field_name with "FDAYS", field_type with "N"
   replace field_len with 3
   append blank
   replace field_name with "FTIMEIN", field_type with "C"
   replace field_len with 5
   append blank
   replace field_name with "FTIMEOUT", field_type with "C"
   replace field_len with 5
   use
   create (gstnpath + "ratally") from (gstnpath + "stru")
   erase (gstnpath + "stru.dbf")
endif
use (gstnpath + "ratally") exclusive alias ratally
zap
index on dtos(fstart)+str(1000-fdays,3) to (gstnpath + "ratally")

* count # of vehicles
f_use ("ravm")
go top
do while .not. eof()
    if ravm->fclass = yclasses
       yunits = yunits + 1
    endif
    skip
enddo

* search open ra's
if yloc = 'ALL'
   ycond1='.t.'
else
   ycond1='raagr->floc = yloc'
endif

f_use ("raagr")
go top
do while .not. eof()
   if raagr->frano <= 0
      skip
      loop
   endif
   select ravm
   seek raagr->funit
   if .not. eof() .and. ravm->fclass = yclasses .and. &ycond1
      select ratally
      append blank
      replace fresvno with str(raagr->frano,6)
      replace fstart with raagr->fdateout
      replace fdays with if(raagr->fdays > 0, raagr->fdays, 1)
      replace ftimein with raagr->ftimein
      replace ftimeout with raagr->ftimeout
   endif
   select raagr
   skip
enddo
select ravm
use
select raagr
use

if yloc = 'ALL'
   ycond1='.t.'
else
   ycond1='rares->floc = yloc'
endif

f_use ("rares", 2)
seek "O"

do while fresvstat = "O" .and. .not. eof ()
   if &ycond1 .and. rares->fclass = yclasses
      select ratally
      append blank
      replace fresvno with rares->fresvno
      replace fstart with rares->fdateout
      replace fdays with rares->fdays
      replace ftimein with rares->ftimein
      replace ftimeout with rares->ftimeout
   endif
   select rares
   skip
enddo
use

select ratally
go top
if eof ()
  f_popup ("Empty Selection .... ",.t.)
  close data
  return
endif

f_popup ("Creating Report", .f.)
declare yarray [yunits]
afill(yarray, space(13))
yt = 1
do while .not. eof () 
   for i = 1 to yunits
      if yarray [i] <= dtos(fstart)+ftimeout
         yarray [i] = dtos(fstart+fdays)+ftimein
         replace funit with strtran(str(i,3)," ","0")
         exit
      endif
   next 
   if empty (funit)
      replace funit with strtran('N'+str(yt,2)," ","0")
      yt=yt+1
   endif
   skip
enddo
index on funit+dtos(fstart) to (gstnpath + "ratally2")

yfil = gstnpath + "rrout.rpt"
yheading1 = "Run Date: " + dtoc (date ()) + space (30) + ;
   "Reservation Tally Report" + space (45) + "Page"
yheading2 = "Run Time: " + time () + space (22) + "Location: " + yloc + ;
   "  Class " + yclasses + "  Period " + ymmyy
*yheading3 = "  Date    Unit   Days   Due      Res#/RA#"
yheading3 = "01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 " + ;
            "31 32 33 34 35 36 37 38 39 40 "
if ydisp = "P"
   yheading1 = chr (15) + yheading1
endif
ypage = 0
ynum = 0
if ydisp = "D"
   set printer to &yfil
   set device to print
else
   set device to print
endif
setprc (0,0)
select ratally
go top

* print out data table
*do while .not. eof() 
*   if yline = 0
*      ypage = ypage + 1
*      yline = yline + 1
*      @ yline, 0 say yheading1 + str (ypage, 4)
*      yline = yline + 1
*      @ yline, 0 say yheading2 
*      yline = yline + 3
*      @ yline, 0 say "Start    Unit Days Due       Res#/RA#"
*      yline = yline + 2
*   endif
*   if fstart+fdays >= ydate1 .and. fstart+fdays <= ydate2 
*      @ yline, 0 say dtoc(fstart)+" "+funit+"  "+str(fdays,3)+"  "+dtoc(fstart+fdays)+"  "+fresvno
*      yline = yline + 2
*      if yline > 52
*         yline = 0
*      endif
*   endif
*   skip
*enddo

ydate1 = ctod(substr(ymmyy,1,2)+"/01/"+substr(ymmyy,4,2))
f_y2k (@ydate1)
ydate2 = ydate1+30
f_y2k (@ydate2)
ypage = ypage + 1
yline = 1
@ yline, 0 say yheading1 + str (ypage, 4)
yline = yline + 1
@ yline, 0 say yheading2 
yline = yline + 3
@ yline, 5 say yheading3
yline = yline + 2
for j = 1 to yunits
   yp = strtran(str(j,3)," ","0")
   @ yline, 0 say yp
   select ratally 
   seek yp
   do while .not. eof () .and. yp = funit 
      if fstart+fdays >= ydate1 .and. fstart <= ydate2
          if substr(dtoc(fstart),1,2)=substr(ymmyy,1,2)   && current month
             y1 = val(substr(dtoc(fstart),4,2))
             ycol = (y1-1)*3
             ystr = if(ycol+(fdays*3)<=120,"x"+replicate("-", fdays*3-2)+"x",   ;
                    "x"+replicate("-", 120-ycol-2)+"x")
             @ yline, ycol+5 say ystr
          elseif fstart < ydate1           && from previous month
             y1 = fdays-(ydate1-fstart)+1
             ystr = if(y1*3<=120,"x"+replicate("-", y1*3-2)+"x",   ;
                    "x"+replicate("-", 120-2)+"x")
             @ yline, 5 say ystr
          endif
      endif
      skip
   enddo
   yline = yline + 2
   if yline > 52
      if ydisp = "P"
         eject
      else
         @ yline + 1, 0 say replicate ("Ä", 131)
         @ yline + 2, 0 say ""
         setprc (0, 0)
      endif
      ypage = ypage + 1
      yline = 1
      @ yline, 0 say yheading1 + str (ypage, 4)
      yline = yline + 1
      @ yline, 0 say yheading2 
      yline = yline + 3
      @ yline, 5 say yheading3
      yline = yline + 2
   endif
next j
*  print overbooked units
select ratally 
seek "N01"
if .not. eof()
   do while .not. eof () .and. funit = "N"
      if yline > 52
         if ydisp = "P"
            eject
         else
            @ yline + 1, 0 say replicate ("Ä", 131)
            @ yline + 2, 0 say ""
            setprc (0, 0)
         endif
         ypage = ypage + 1
         yline = 1
         @ yline, 0 say yheading1 + str (ypage, 4)
         yline = yline + 1
         @ yline, 0 say yheading2 
         yline = yline + 3
         @ yline, 5 say yheading3
         yline = yline + 2
      endif

      if fstart+fdays >= ydate1 .and. fstart <= ydate2
          if substr(dtoc(fstart),1,2)=substr(ymmyy,1,2)     && current month
             y1 = val(substr(dtoc(fstart),4,2))
             ycol = (y1-1)*3
             ystr = if(ycol+(fdays*3)<=120,"x"+replicate("-", fdays*3-2)+"x",   ;
                    "x"+replicate("-", 120-ycol-2)+"x")
             @ yline, 0 say funit
             @ yline, ycol+5 say ystr
             yline = yline + 2
          elseif fstart < ydate1           && from previous month
             y1 = fdays-(ydate1-fstart)+1
             ystr = if(y1*3<=120,"x"+replicate("-", y1*3-2)+"x",   ;
                    "x"+replicate("-", 120-2)+"x")
             @ yline, 0 say funit
             @ yline, 5 say ystr
             yline = yline + 2
          endif
      endif
      skip
   enddo
endif
*
if ydisp = "P"
   @ yline, 130 say chr (18)
   eject
endif
*
set device to screen
set printer to
f_popback()
if ydisp = "D"
   set color to
   clear
   run racbrow &yfil
endif

close database

