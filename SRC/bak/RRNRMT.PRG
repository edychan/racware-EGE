*
* transit ra module
* ra check in by remote handheld
*
do while .t.
   xret2 = f_pushmenu (xoption1)
   if xret2 = 0
      exit
   else
      xoption2 = substr (goption [xret2], 4)
      do case
      case xret2 = 1
         do rrnrmt1
      case xret2 = 2
         do rrnrmt2
      case xret2 = 3
         do rrnrmt3
      endcase
   endif
enddo

*******
* release transit ra status
*
procedure rrnrmt1
private yloc, yrano, yunit, yname

f_clrscn ("EXPRESS CHECK-IN : Release Transit RA ")
f_use ("RAAGR")
f_use ("RAAGRT")
@ 01, 01 say "LOC        RA #   Unit #     Name                "
@ 02, 01 say "컴컴컴컴컴 컴컴컴 컴컴컴컴컴 컴컴컴컴컴컴컴컴컴� "
yrow = 3
yloc = gloc
do while .t.
   yrano = 0
   yunit = space(10)
   yname = space(20)
   @ yrow, 01 get yloc pict "!!!!!!!!!!"
   @ yrow, 12 get yrano pict "999999"
   if f_rd () = 27
      exit
   endif
   select raagr
   seek yloc+str(yrano,6)
   if eof ()
      f_valid (.f., "Invalid RA #...")
      loop
   elseif raagr->frastat <> "X"
      f_valid (.f., "Not a Transit RA #...")
      loop
   endif
   select raagrt
   seek yloc+str(yrano,6)
   if eof ()
      select raagr
      reclock ()
      replace frastat with " "
      commit
      unlock
      f_valid (.f., "Transit RA status changed...")
      loop
   endif   
   @ yrow, 19 say raagrt->funit
   @ yrow, 30 say raagrt->fname
   xkey = f_confirm ("[C]onfirm  [E]dit  [Q]uit ", "CEQ")
   do case
   case xkey = "C"
      select raagr
      reclock ()
      replace frastat with " "
      commit
      unlock
      select raagrt
      reclock ()
      f_clrrec ()
      commit
      unlock
   case xkey = "E"
      loop
   case xkey = "Q"
      exit
   endcase
   if xkey <> "I"
      if yrow < 23
         yrow = yrow + 1
      else
         scroll (3, 0, 23, 79, 1)
      endif
   else
      @ yrow, 12
   endif
enddo

close database

*******
procedure rrnrmt2
private yloc, yrano

f_clrscn ("EXPRESS CHECK-IN : AUDIT TRANSIT RA ")
rest from (gmempath+"raagrt") additive
f_use ("RAAGRT")
set filter to frano > 0
go top
do while .t.
   yloc = gloc
   yrano = 0
   f_box (02, 05, 04, 40)
   @ 03, 07 say "LOC/RA#...."
   @ 03, 19 get yloc pict "!!!!!!!!!!" valid ;
     f_valid (f_verify ("RALOC", 1, yloc), "Invalid LOC...")
   @ 03, 30 get yrano pict "999999"
   if f_rd () = 27
      exit
   endif
   select raagrt
   set softseek on
   seek yloc + str(yrano,6)
   set softseek off 
   if eof()
      f_valid (.f.,"No Matching Record. Press Any Key to Retry ...")
      loop
   endif
   if f_pick_f (02, 05, "", "","trim(floc)+[-]+str(frano,6)+[  ]+funit+[  ]+fname")
      f_update ("raagrt", "raagrt", "", "", "rrnrmt2b")
   endif
enddo

set filter to
close data

****************
* cal total
function rrnrmt2a
private ynet

l_ftotal = l_ftmetot + l_fmlgtot + l_fcdwtot + l_fpaitot + l_ffueltot + ;
           l_fsurchg + l_ftaxtot + l_fotot1 + l_fotot2 + l_fotot3 + l_fotot4 
ynet = l_ftotal - l_fdepamt - l_fdisctot
@ 22, 18 say str(l_ftotal,8,2)  
@ 23, 03 say "Net Due......."
@ 23, 18 say str(ynet,8,2)
return .t.

******************
* delete transit ra
procedure rrnrmt2b

f_use ("raagr")
select raagr
seek l_floc + str(l_frano, 6)
if .not. eof ()
   reclock ()
   replace frastat with " "
   commit
   unlock
endif
use
select raagrt
reclock ()
f_clrrec ()
commit
unlock

********
procedure rrnrmt3
private yloc, yrow, y1, yccinfo, ytmp

f_clrscn ("EXPRESS CHECK-IN : Process Transit RA ")

f_use ("RAAGRT")
go top
if eof ()
   f_valid (.f., "Empty Selection...")
   close data
   return
endif

f_box (02, 03, 04, 65)
yloc = gloc
@ 03, 05 say "Enter Express Check-in Location: " get yloc pict "!!!!!!!!!!" valid ;
  f_valid (f_verify ("RALOC", 1, yloc), "Invalid Location...") 
if f_rd () = 27
   close data
   return
endif

*
restore from (gmempath + "RAAGRH2") additive
private l_fname
l_ftrack = space(70)

f_use ("raagr")
f_use ("radtr")
f_use ("raagrh")
f_use ("raagrx", 3)
f_use ("racred")
f_use ("rares")
f_box (06, 05, 22, 65, "Processing Transit RA")
yrow = 6
select raagrt
go top
do while .not. eof ()
   set softseek on
   seek yloc
   set softseek off
   if eof ()
      exit
   endif
   if yrow >= 21
      scroll (7, 10, 21, 60, 1)
   else
      yrow = yrow + 1
   endif
   @ yrow, 07 say trim(raagrt->floc)+"-"+str(raagrt->frano,6)+" "+raagrt->fname

   * retrieve data
   @ yrow, 47 say "Working..."
   select raagr
   seek raagrt->floc + str(raagrt->frano,6)
   if eof ()
      select raagrt
      if f_clrskip () = 0
         exit
      else
         loop
      endif
   else
      f_retrieve ()
   endif
   select raagrt          && must do this after retrieve from raagr
   f_retrieve ()
   l_famtdue = raagrt->ftotal - raagrt->fdepamt
   l_famt1 = l_famtdue
   l_fmlgin = l_fmlgout + raagrt->fmlg
   l_frastat = "C"
   l_frectype = "C"
   l_fexchg = .f.

   * update raagrh
   @ yrow, 47 say "Updating AGRH... "
   select raagrh
   seek raagrt->floc + str(raagrt->frano,6)
   if eof ()
      append blank
   else
      reclock ()
   endif
   f_replace ()
   f_fupdate ("A")

   * update racred
   @ yrow, 47 say "Updating CCP...  "
   select racred
   seek l_floc + str (l_frano, 6)
   do while floc = l_floc .and. frano = l_frano .and. .not. eof ()
      if .not. (fccnum = l_fccnum1) .or. (frectype <> __gccuncap .and. ;
            frectype <> __gcccap)
         reclock ()
         if ftranstyp = "C"
            replace fauthamt with -abs (fauthamt), fcapamt with -abs (fcapamt)
         endif
         replace ftranstyp with "D"
         commit
         unlock
      endif
      skip
   enddo
   if l_fpaycod1 = 1
      f_findblank ()
      yccinfo = substr(l_ftrack,1,at('?',l_ftrack)-1)      
      y1 = .f.
      good_cctype (l_fpaytyp1, @y1)
      replace fccnum with l_fccnum1, fcctype with l_fpaytyp1
      replace fccexp with l_fccexp1, fauthcode with l_fauthcd1
      replace fauthamt with abs (l_famt1), fauthonly with y1
      replace frectype with __gccuncap
      * replace fauthstat with &ystr8
      replace fauthdate with date (), fauthtime with time ()
      replace ffname with l_ffname, flname with l_flname
      replace fmname with if(empty(yccinfo),"M","C")
      replace floc with l_floc, frano with l_frano
      replace frloc with l_frloc
      if l_famt1 < 0.00
         replace ftranstyp with "C"
      elseif empty (l_fauthcd1) 
         replace ftranstyp with "F"
      else
         replace ftranstyp with "S"
      endif
      commit
      unlock
      f_fupdate ("A")
   endif

   * update raagrx
   @ yrow, 47 say "Updating AGRX... "
   select raagrx
   seek raagrt->floc + str(raagrt->frano,6)
   if eof ()
      append blank
   else
      reclock ()
   endif
   f_replace ()
   f_fupdate ("A")
   * update rares
   if .not. empty (l_fresvno)
      @ yrow, 47 say "Updating RES ... "
      select rares
      seek l_fresvno + l_floc
      if .not. eof ()
         f_fupdate ("C")
         reclock ()
         replace frano with l_frano 
         replace fresvstat with "U"
         replace ftnm with l_ftmetot + l_fmlgtot
         replace fcomm with round (fcommpct * ftnm / 100.00, 2)
         commit
         unlock
      endif
   endif

   * update radtr  (must be last one to update, may change l_floc, l_frloc
   @ yrow, 47 say "Updating DTR...  "
   select radtr
   l_frectype = if (l_floc <> l_frloc, "F", "C")
   seek l_frectype + raagrt->floc + str(raagrt->frano,6)
   if eof ()
      f_findblank ()
   else
      reclock ()
   endif
   f_replace ()
   f_fupdate ("A")
   if l_floc <> l_frloc
      ytmp = l_frloc
      l_frloc = l_floc
      l_floc = ytmp         
      l_frectype = "T"
      seek l_frectype + raagrt->floc + str(raagrt->frano,6)
      if eof ()
         f_findblank ()
      else
         reclock ()
      endif
      f_replace ()
      f_fupdate ("A")
   endif

   * blank out raagr
   select raagr
   f_clrrec ()

   @ yrow, 47 clear to yrow, 64
   @ yrow, 47 say "Completed..."
   select raagrt
   if f_clrskip () = 0
      exit
   endif
enddo

f_valid (.f., "Process Completed.")
close data

