* ===========================================================================
* rental agreement maint.
*
* date: 05/01/91
* author: kst
*
* revision
* date: 06/04/92
* edc: fix additional deposit problem reported by PV.
* date: 07/20/92
* edc: exchange vehicle; should allow user to exit without any change.
* date: 09/27/92
* edc: new feature for insurance replacement rentals
* date: 02/23/93
* edc: fix remarks to show during extend contracts. (see rrnfmu1)
* date: 08/31/93
* edc: restore cc track 1 info.
* date: 12/4/93
* edc: change zip code to alphanumeric
*      take out resv grid table
* date: 01/05/94
* edc: retain damage info. for vehicle exchange
*      fix fuel calc. by 'M' or 'G'
* date: 08/11/94
* edc: allow DB type to add DB acct # for additional deposit
* date: 10/19/94
* edc: user can make additional deposit when extending contract
* 08.12.99
* set century off
* ===========================================================================
parameters xtyp
private yadriver, yothchg, yestamt, ycdwyn, ypaiyn

set century off
yfreesell = gfreesell
do case
case xtyp = 1
   f_clrscn ("Extend Contract")
case xtyp = 2
   f_clrscn ("Exchange Vehicle")
   rest from (gmempath + "RAAGRH2") additive
   rest from (gmempath + "RAAGRX") additive
case xtyp = 3
   f_clrscn ("Additional Deposit")
case xtyp = 4
   f_clrscn ("Update Contract")
case xtyp = 5
   f_clrscn ("Reprint Contract")
endcase
restore from (gmempath + "RAAGR") additive
if .not. rrnpkra ("O")
   return
endif
* 08/31/93 edc: restore cc track 1 info.
gccinfo = substr(l_ftrack,1,at('?',l_ftrack)-1)

f_getscn ("rrnoa")
do fgetrrnfm
do while .t.
   ykeyin = f_confirm ("[C]hoose This One  [N]ext  [P]revious  [Q]uit", ;
      "CNPQ")
   do case
   case ykeyin = "C"
      do case
      case xtyp = 1
         do rrnfmu1
      case xtyp = 2
         do rrnfmu2
      case xtyp = 3
         do rrnfmu3
      case xtyp = 4
         yrate = l_frate
         yloc = l_floc
         ydateout = l_fdateout
         yclass = l_fclass
         yccauth = .t.
         yraupd = .t.
         do rrnfmu4
      case xtyp = 5
         do rrnfmu5
      endcase
      exit
   case ykeyin = "N"
      clear gets
      skip 1
      if eof ()
         f_popup ("End of file. Press Any Key...", .t.)
         go bottom
      endif
      f_retrieve ()
      do fgetrrnfm
   case ykeyin = "P"
      clear gets
      skip -1
      if bof ()
         f_popup ("Top of file . Press Any Key...", .t.)
         go top
      endif
      f_retrieve ()
      do fgetrrnfm
   case ykeyin = "Q"
      clear gets
      exit
   endcase
enddo
close databases


******************************
procedure rrnfmu1

private yfnd, yln, yctr

clear gets
setcolor (gsubcolor)
yln = 5
yscn = f_box (yln, 01, 22, 52)
ydays = 0

* 02/23/93: fix show remarks during extend ra.
*           use l_floc+str(l_frano,6) instead of raagr->floc+str(frano,6)
f_use ("raagrl")
seek l_floc+str(l_frano,6)
yln = yln + 1
yctr = 1
do while .not. eof () .and. frano=l_frano 
   if fcode = "E"
      @ yln, 03 say str(yctr,2)+". "
      @ yln, 07 say raagrl->frmk1
      @ yln+1, 07 say raagrl->frmk2
      yln = yln+2
      yctr = yctr+1
   endif
   skip
enddo
select raagr
yrmk1=space(40)
yrmk2=space(40)
do while .t.
   @ yln, 03 say "Check Out Date ...."
   @ yln+1, 03 say "Current Due Date .."
   @ yln+2, 03 say "Additional Days ..."
   @ yln+3, 03 say "New Due Date ......"
   @ yln+4, 03 say "Remarks "
   @ yln, 23 say raagr->fdateout
   @ yln, 32 say raagr->ftimeout
   @ yln+1, 23 say raagr->fdatein
   @ yln+1, 32 say raagr->ftimein
   @ yln+2, 23 get ydays picture "999" valid rrnfmu11 ()
   @ yln+3, 23 get l_fdatein valid f_valid (f_y2k(@l_fdatein) .and. ;
                   l_fdatein >= l_fdateout)
   @ yln+3, 32 get l_ftimein valid rrnfmu12 ()
   @ yln+4, 11 get yrmk1
   @ yln+5, 11 get yrmk2
   f_rd ()
   l_fdays = l_fdatein - l_fdateout + 1
   yestamt = round (rrncalc (), 2)
   @ 18, 69 say yestamt picture "99999.99"

   ykeyin = f_confirm ("[C]onfirm   [E]dit   [I]gnore", "CEI")
   if ykeyin = "C"
      select raagr
      reclock ()
      replace fdays with fdays + ydays, fdatein with l_fdatein
      commit
      unlock
      select raagrl
      append blank
      reclock ()
      replace floc with raagr->floc, frano with raagr->frano
      replace fcode with "E"
      replace fdate with date (), ftime with time ()
      replace fid with gusrid
      replace frmk1 with yrmk1, frmk2 with yrmk2
      commit
      unlock
      f_fupdate ("A")
      use
      f_use ("RAVM")
      seek l_funit
      if found ()
         f_fupdate ("C")
         reclock ()
         replace fdueback with l_fdatein
         commit
         unlock
      endif
      select ravm
      use
      exit
   elseif ykeyin = "E"
      loop
   else
      exit
   endif
enddo
f_restbox (yscn)
setcolor (gbluecolor)

* additional deposit   10/19/94

if f_confirm ("[A]dditional Deposit   [Q]uit", "AQ") = "A"
   do rrnfmu3
endif

******************************
function rrnfmu11

if f_valid ((ydays + raagr->fdays + raagr->fdateout) > raagr->fdateout)
   l_fdatein = l_fdateout + ydays + raagr->fdays
   @ yln+3, 23 say l_fdatein
   return .t.
else
   return .f.
endif


******************************
function rrnfmu12

if f_valid (f_timeok (l_ftimein) .and. (dtos (l_fdatein) + l_ftimein) ;
      >= (dtos (raagr->fdateout) + raagr->ftimeout))
   select raagr
   ydays = l_fdatein - l_fdateout - raagr->fdays
   setcolor (gsubget)
   @ yln+2, 23 say ydays picture "999"
   setcolor (gsubcolor)
   return .t.
else
   return .f.
endif


******************************
procedure rrnfmu2

clear gets
private yunit, ydesc
yunit = space (10)
ycolor = setcolor (gsubcolor)
yscn = f_box (1, 5, 22, 64)
@ 2, 7 say "Exchanged Vehicle Unit # ............."
@ 3, 9 say "Desc ............"
@ 4, 9 say "License ........."
@ 5, 9 say "Class ..........."
@ 6, 9 say "Mileage Out .....           In ....."
@ 7, 9 say "Fuel Out/In .....  /8- /8   Calc ...    [G]auge/[M]ile"
@ 8, 9 say "Damage .........."
@ 11, 9 say "Damage Charge ...           Fuel Chg"
@ 12, 9 say "Turn In Date/Time"
@ 13, 7 say "Exchange Vehicle Unit # .............."
@ 14, 9 say "Desc ............"
@ 15, 9 say "License ........."
@ 16, 9 say "Class ..........."
@ 17, 9 say "Mileage Out ....."
@ 18, 9 say "Fuel Out ........  /8"
@ 19, 9 say "Damage .........."
f_use ("RAVM", 1)
l_feunit = l_funit
l_femlgout = l_fmlgout
l_femlgin = l_femlgout
l_fefuelout = l_ffuelout
l_fefuelin = l_fefuelout
l_fexdate = date ()
l_fextime = time ()
* 01/05/94
*l_fedmg1 = l_fdmg1
*l_fedmg2 = l_fdmg2
*l_fedmg3 = l_fdmg3
l_funit = space (10)
l_ffuel = 8
l_fmlgout = 0
store 0.00 to ygaschg, ydmgchg

seek l_feunit
@  2, 46 say l_feunit
if found ()
   ydesc = alltrim (fyear + " " + fcolor + " " + fmake + " " + fmodel)
   do while "  " $ ydesc
      ydesc = strtran (ydesc, "  ", " ")
   enddo
   @ 3, 27 say f_truncate (ydesc, 29)
   @ 4, 27 say flic
   @ 5, 27 say fclass
   l_fedmg1 = fdmg1
   l_fedmg2 = fdmg2
   l_fedmg3 = fdmg3
   ytank = ftank
   yepa = fepa
else
   l_fedmg1 = space (20)      && 06/14/94 (edc) 
   l_fedmg2 = space (20)
   l_fedmg3 = space (20)
   ytank = 0
   yepa = 0
endif
@ 6, 27 say l_femlgout picture "999999"
@ 7, 27 say l_fefuelout picture "9"

set key 28 to rrnfmu2hlp
yendedit = .f.
do while .t.
   @ 6, 46 get l_femlgin picture "999999" valid ;
      f_valid (f_valid (l_femlgin > l_femlgout, ;
      "Warning!  No Miles Driven!") .or. l_femlgin >= l_femlgout)
   @ 7, 31 get l_fefuelin picture "9"
   @ 7, 46 get l_fgastyp picture "!" valid rrnfmu22 ()
   @ 8, 27 get l_fedmg1
   @ 9, 27 get l_fedmg2
   @ 10, 27 get l_fedmg3
   @ 11, 27 get ydmgchg pict "99999.99"
   @ 11, 46 get ygaschg pict "99999.99"
   @ 12, 27 get l_fexdate valid f_valid (f_y2k(@l_fexdate) .and. ;
                l_fexdate >= l_fdateout)
   @ 12, 36 get l_fextime pict "99:99"
   @ 13, 46 get l_funit picture "!!!!!!!!!!" valid rrnfmu21 ()
   @ 17, 27 get l_fmlgout picture "999999"
   @ 18, 27 get l_ffuelout picture "9" valid f_compute (@yendedit, .t.)
   @ 19, 27 get l_fdmg1
   @ 20, 27 get l_fdmg2
   @ 21, 27 get l_fdmg3
   f_rd ()
   if yendedit
      ykeyin = f_confirm ("[C]onfirm   [E]dit   [I]gnore Changes", "CEI")
   else
      ykeyin = f_confirm ("[E]dit   [I]gnore Changes", "EI")
   endif
   if ykeyin = "E"
      loop
   elseif ykeyin = "I"          && edc: elseif ykeyin = "V" ; typo
      if .not. empty (l_funit)
         select ravm
         set order to 1
         seek l_funit
         if found ()
            f_fupdate ("C")
            reclock ()
            replace fstatus with "A"
            commit
            unlock
         endif
      endif
      exit
   else
      select ravm
      set order to 1
      seek l_feunit
      if found ()
         f_fupdate ("C")
         reclock ()
         if .not. empty (freason)
            replace fstatus with "H"
         else
            replace fstatus with if (gautopkvh, "I", "A")
         endif
         replace fcurra with 0, frenter with " "
         replace flastra with l_frano, fckindt with l_fexdate   && 06/16/94 edc
         replace fdueback with ctod ("  /  /  ")
         replace fmileage with l_femlgin, fdmg1 with l_fedmg1
         replace fdmg2 with l_fedmg2, fdmg3 with l_fedmg3
         replace futime with dtos (l_fexdate) + l_fextime
         commit
         unlock
      endif
      seek l_funit
      if found ()
         f_fupdate ("C")
         reclock ()
         replace fstatus with "O", fckoutdt with l_fexdate    && 06/16/94 edc
         replace fcurra with l_frano, fdueback with l_fdatein
         replace fmileage with l_fmlgout, frenter with l_flname
         replace fdmg1 with l_fdmg1, fdmg2 with l_fdmg2, fdmg3 with l_fdmg3
         replace futime with dtos (l_fexdate) + l_fextime
         commit
         unlock
      endif
      yulic = raagr->fulic
      l_fulic = ravm->flic
      select raagr
      f_fupdate ("C")
      reclock ()
      replace funit with l_funit, fmlgout with l_fmlgout
      replace ffuelout with l_ffuelout, fuclass with ravm->fclass
      replace fulic with l_fulic
      replace feunit with l_feunit, femlgout with l_femlgout
      replace femlgin with l_femlgin, fefuelout with l_fefuelout
      replace fefuelin with l_fefuelin
      replace femlgs with femlgs + l_femlgin - l_femlgout
      replace fefueltot with fefueltot + ygaschg
      replace fedmgtot with fedmgtot + ydmgchg
      if .not. empty (fexdate)
         l_fdateout = fexdate
         l_ftimeout = fextime
      endif
      replace fexdate with l_fexdate, fextime with l_fextime
      commit
      unlock
      f_use ("RAAGRX")
      append blank
      l_funit = l_feunit
      l_fexchg = .t.
      l_fmlgin = l_femlgin
      l_fmlgout = l_femlgout
      l_fdatein = l_fexdate
      l_ftimein = l_fextime
      l_fulic = yulic
      l_fdmgtot = ydmgchg
      l_ffueltot = ygaschg
      f_replace ()
      f_fupdate ("A")
      use
      f_use ("RAAGRL")
      append blank
      reclock ()
      replace floc with raagr->floc, frano with raagr->frano
      replace fcode with "X"
      replace fdate with date (), ftime with time ()
      replace fid with gusrid
      commit
      unlock
      f_fupdate ("A")
      use
      exit
   endif
enddo

set key 28 to
select ravm
use
f_restbox (yscn)


******************************
function rrnfmu21

if yunit = l_funit .and. .not. empty (l_funit)
   return .t.
endif
if .not. f_valid (.not. empty (l_funit))
   return .f.
endif

select ravm
set order to 1
seek l_funit
if .not. f_valid (found (), "Unit Not Found!!!")
   return .f.
elseif .not. f_valid (fstatus $ "AI", "Unit Not Available!!!")
   return .f.
endif

if fstatus = "I"
   tone (500, 9)
   if f_confirm ("Warning: Vehicle status is IN but not " + ;
         "AVAILABLE.  Pick it? [Y/N]", "YN") = "N"
      return .f.
   endif
endif

yunit = l_funit
reclock ()
replace fstatus with "X"
commit
unlock
ydesc = alltrim (fyear + " " + fcolor + " " + fmake + " " + fmodel)
do while "  " $ ydesc
   ydesc = strtran (ydesc, "  ", " ")
enddo
@ 14, 27 say f_truncate (ydesc, 29)
@ 15, 27 say flic
@ 16, 27 say fclass
l_fulic = flic
l_fuclass = fclass
l_fmlgout = fmileage
l_fdmg1 = fdmg1
l_fdmg2 = fdmg2
l_fdmg3 = fdmg3
setcolor (gsubget)
@ 17, 27 say l_fmlgout picture "999999"
@ 18, 27 say l_ffuelout picture "9"
@ 19, 27 say l_fdmg1
@ 20, 27 say l_fdmg2
@ 21, 27 say l_fdmg3
setcolor (gsubcolor)

if .not. empty (yunit)
   seek yunit
   if found ()
      f_fupdate ("C")
      reclock ()
      replace fstatus with "A"
      commit
      unlock
   endif
endif
return .t.


******************************
function rrnfmu22

if .not. f_valid (l_fgastyp $ "GM")
   return .f.
endif
ygaschg = 0
* 1/05/94 (edc) if l_fgastyp = "G" .or. ((l_femlgin - l_femlgout) > ytank * yepa)
if l_fgastyp = "G" .or. ((l_femlgin - l_femlgout) > 50)
   if l_fefuelin < l_fefuelout
      ygaschg = round (ytank * (l_fefuelout - l_fefuelin) / 8 * gfuelchg, 2)
   endif
else
   ygaschg = round ((l_femlgin - l_femlgout) / yepa * gfuelchg, 2)
endif

if gfueltax
   ygaschg = round (ygaschg * (1 + gtaxrate / 100), 2)   && edc 02/03/95
endif
setcolor (gsubget)
@ 11, 46 say ygaschg pict "99999.99"
setcolor (gsubcolor)

return .t.


******************************
procedure rrnfmu2hlp

private yscn
yscn = f_box (11, 53, 13, 77)
@ 12, 55 say "Vehicle Class..."
ystr = if (.not. empty (l_fuclass), l_fuclass, l_fclass)
if .not. f_getfld (@ystr, 12, 72, "W/N", 4, "!!!!")
   f_restbox (yscn)
else
   f_restbox (yscn)
   select ravm
   set order to 3
   seek "A" + l_floc + ystr
   if .not. found ()
      f_valid (.f., "No " + alltrim (ystr) + ;
         " size vehicles are available!!!")
   else
      if f_pick_f (11, 10, "", "Unit No.ÄÄÄClasÄYrÄMakeÄÄÄÄÄÄÄModelÄÄÄÄÄÄÄ" ;
            + "MilesÄÄStall", "funit + [ ] + fclass + [ ] + fyear + " + ;
            "[ ] + fmake + [ ] + fmodel + [ ] + str (fmileage, 6) + [ ] " + ;
            " + fstall + [ ]", "", "[A] + floc + fclass", ;
            "[A" + l_floc + ystr + "]")
         l_funit = ravm->funit
      endif
   endif
endif


******************************
procedure rrnfmu3

private yscn, ypaytyp, yamt, yexp, yccnum, yauthcode, yauthstat
private yrectype, yauthonly, ydbacct


clear gets
setcolor (gsubcolor)
yscn = f_box (08, 14, 19, 63)
ypaytyp = raagr->fpaytyp1
yamt = 0.00
yexp = raagr->fccexp1
yccnum = raagr->fccnum1
yauthcode = space (6)
yauthstat = space (20)
yrectype = __gccunauth
yauthonly = .f.
ydbacct = raagr->fdbacct1

@ 09, 16 say "Current Deposit ......... "
@ 10, 16 say "Current Hold Amt ........ "
@ 14, 16 say "Additional Deposit Type.. "
@ 09, 42 say raagr->fdepamt picture "99999.99"
@ 10, 42 say raagr->fhldamt picture "99999.99"
@ 15, 16 say "CC Number ............... "
@ 16, 16 say "Exp ..................... "
@ 17, 16 say "Amount .................. "
@ 18, 16 say "Auth Code ............... "
ycaphold = "N"
do while .t.
   if empty (gccnet) .or. raagr->fhldamt <= 0
      ycaphold = "N"
      @ 12, 16 clear to 12, 60
      @ 12, 16 say "Additional Deposit?   [Y/N]"
      @ 12, 36 get ycaphold pict "!" valid ycaphold $ "YN"
      if f_rd () = 27 .or. ycaphold = "N"
         exit
      endif
      ycaphold = "N"
   else
      * disable cc capture  
      * ycaphold = "Q"
      * @ 12, 16 clear to 12, 60
      * @ 12, 16 say "Capture Prev Hold Credit Card?    [Y/N/Q]"
      * @ 12, 47 get ycaphold pict "!" valid ycaphold $ "YNQ"
      * if f_rd () = 27 .or. ycaphold = "Q"
      *    exit
      * endif
   endif
   if ycaphold = "Y"
      f_use ("racred", 1)
      set filter to frectype = __gccauth
      seek raagr->floc + str (raagr->frano, 6)
      if .not. f_valid (.not. eof (), "No Credit Card Amount Being Hold...")
         loop
      endif
      yans = "N"
      * 06/04 edc - take out rrnfmu32 function in f_pick_f 
      *       problem reported by PV.   
      if f_pick_f (13, 16, "", "Credit Card NumberÄÄÄHold Amt", ;
            "fccnum + [ ] + str (fauthamt, 8, 2)", "", ;
            "floc + str (frano, 6)", "raagr->floc + str (raagr->frano, 6)")

         yans = f_confirm ("Are you sure ? [Y/N]", "YN")

         if yans = "Y"
            f_fupdate ("C")
            reclock ()
            replace frectype with __gccuncap
            commit
            unlock
            f_use ("RADTR")
            f_findblank ()
            replace floc with l_floc, frano with l_frano, frloc with l_frloc
            replace flname with l_flname, fpaytyp1 with racred->fcctype
            replace famt1 with racred->fauthamt, frectype with "A"
            replace ftotal with racred->fauthamt        
            commit
            unlock
            f_fupdate ("A")
            use
            f_use ("RAAGRL")
            append blank
            reclock ()
            replace floc with raagr->floc, frano with raagr->frano
            replace fcode with "A"
            replace fdate with date (), ftime with time ()
            replace fid with gusrid
            commit
            unlock
            f_fupdate ("A")
            use
            select raagr
            f_fupdate ("C")
            reclock ()
            replace fdepamt with fdepamt + racred->fauthamt
            replace fhldamt with fhldamt - racred->fauthamt
            @ 9, 42 say raagr->fdepamt picture "99999.99"
            @ 10, 42 say raagr->fhldamt picture "99999.99"
            commit
            unlock
         endif

      endif
      select racred
      use
   else
      ycode = 0
      @ 14, 42 get ypaytyp picture "!!!" ;
         valid f_valid (good_paytype (ypaytyp, @ycode), ;
         "Invalid Payment Type!!!")
      @ 15, 15 clear to 18, 62
      if f_rd () = 27
         exit
      endif
      if good_cctype (ypaytyp, @yauthonly)
         @ 15, 16 say "CC Number ............... "
         @ 16, 16 say "Exp ..................... "
         @ 17, 16 say "Amount .................. "
         @ 18, 16 say "Auth Code ............... "
         @ 15, 42 get yccnum picture replicate ("9", 20) ;
            valid f_valid (good_card (yccnum), "Invalid Credit Card!!!")
         @ 16, 42 get yexp picture "99/99" ;
            valid f_valid (f_expired (yexp), "Card Expired!!!")
         @ 17, 42 get yamt picture "99999.99" valid rrnfmu31 ()
         @ 18, 42 get yauthcode picture "!!!!!!"
      elseif ycode = 2
         @ 15, 16 say "Amount .................. "
         @ 15, 42 get yamt picture "99999.99" valid f_valid (yamt <> 0.00)
      elseif ycode = 3
         @ 15, 16 say "DB #......................"
         @ 15, 42 get ydbacct 
      endif
      f_rd ()
      if ycode = 1
         @ 9, 42 say raagr->fdepamt picture "99999.99"
         @ 10, 42 say raagr->fhldamt + yamt picture "99999.99"
      elseif ycode = 2
         @ 9, 42 say raagr->fdepamt + yamt picture "99999.99"
         @ 10, 42 say raagr->fhldamt picture "99999.99"
      endif

      ykeyin = f_confirm ("[C]onfirm   [E]dit   [I]gnore", "CEI")
      if ykeyin = "C"
         select raagr
         f_fupdate ("C")
         reclock ()
         if ycode = 1
            replace fpaytyp1 with ypaytyp, fccnum1 with yccnum
            replace fccexp1 with yexp, fauthcd1 with yauthcode
            replace fhldamt with fhldamt + yamt
         elseif ycode = 2
            replace fdepamt with fdepamt + yamt
         elseif ycode = 3
            replace fpaytyp1 with ypaytyp, fccnum1 with ""
            replace fccexp1 with "", fauthcd1 with ""
            replace fdbacct1 with ydbacct, fhldamt with 0
         endif
         commit
         unlock
         if ycode = 1          
            f_use ("RACRED", 1)
            f_findblank ()
            replace fauthonly with yauthonly, fauthamt with abs (yamt)
            replace fauthcode with yauthcode, fauthstat with yauthstat
            replace fauthdate with date (), fauthtime with time ()
            replace fccexp with yexp, fccnum with yccnum
            replace fcctype with ypaytyp, ffname with raagr->ffname
            replace flname with raagr->flname, floc with raagr->floc
            replace frano with raagr->frano, frectype with yrectype
            replace frloc with raagr->frloc
            if yamt < 0.00
               replace ftranstyp with "C"
            elseif .not. empty (yauthcode) .and. yrectype = __gccunauth
               replace ftranstyp with "F"
            else
               replace ftranstyp with "S"
            endif
            commit
            unlock
            f_fupdate ("A")
            use
         endif

         f_use ("RAAGRL")
         append blank
         reclock ()
         replace floc with raagr->floc, frano with raagr->frano
         replace fcode with "A"
         replace fdate with date (), ftime with time ()
         replace fid with gusrid
         commit
         unlock
         f_fupdate ("A")
         use
         if ycode = 2
            f_use ("RADTR")
            f_findblank ()
            replace floc with l_floc, frano with l_frano, frloc with l_frloc
            replace flname with l_flname, fpaytyp1 with ypaytyp
            replace famt1 with yamt, frectype with "A"
            replace ftotal with yamt           
            commit
            unlock
            f_fupdate ("A")
            use
         endif
         exit     && 12.23.04: per dlege request
      elseif ykeyin = "E"
         loop
      elseif ykeyin = "I"
         exit
      endif
   endif
enddo
setcolor (gbluecolor)
close databases


******************************
function rrnfmu31

private yret
yret = newauth ("S", yccnum, yexp, yamt, @yauthcode, @yauthstat)
if yret = "D"
   yrectype = __gccauth
elseif yret = "E"
   yrectype = __gccautherr
else
   yrectype = __gccunauth
endif
set cursor on
return .t.


******************************
procedure rrnfmu32

yans = f_confirm ("Are you sure you want to capture this amount? [Y/N]", ;
   "YN")

******************************
procedure rrnfmu4

private yccdial
yraupd = .t.
set key 28 to rrnoah1
set key -1 to rrnoah2
set key -2 to rrnoah3
yfreesell = gfreesell

do while .t.
   store space (15) to yitem1, yitem2, yitem3, yitem4
   * 12.17.97 change for sli
   ysliyn = if(l_forate1 > 0, .t., .f.)
   *
   ycdwkep = l_fcdw
   ypaikep = l_fpai
   yresvno = l_fresvno
   ycrpno = l_fcrpno
   yadvrchg = yadriver
   yresvrate = .not. empty (l_fresvno)
   yrate = l_frate
   yclass = l_fclass
   yloc = l_floc
   yunit = l_funit
   ychgchg = yothchg
   yccnum = l_fccnum1
   yccamt = l_fdepamt
   l_fstall = space (4)
   setcolor (gredcolor)
   if .not. yfreesell
      @ 24, 01 say "F3 Overwrite Free Sell"
   endif
   setcolor (gbluecolor)

   f_rd ()
   ykeyin = f_confirm ("[C]onfirm   [E]dit   [I]gnore", "CEI")
   if ykeyin = "C"
      select raagr
      l_fdepamt = fdepamt
      f_fupdate ("C")
      f_replace ()
      * 01/06/94 (edc) update vm with current ra info.
      f_use ("RAVM")
      seek raagr->funit
      if found ()
         f_fupdate ("C")
         reclock ()
         replace fstatus with "O", fckoutdt with raagr->fdateout
         replace fcurra with raagr->frano, fdueback with raagr->fdatein, floc with raagr->floc
         replace fmileage with raagr->fmlgout, frenter with raagr->flname
         replace futime with dtos (date ()) + time ()
         commit
         unlock
      endif
      use
      *
      f_use ("RAAGRL")
      append blank
      reclock ()
      replace floc with raagr->floc, frano with raagr->frano
      replace fcode with "U"
      replace fdate with date (), ftime with time ()
      replace fid with gusrid
      commit
      unlock
      f_fupdate ("A")
      use
      exit
   elseif ykeyin = "E"
      do fgetrrnfm
      loop
   elseif ykeyin = "I"
      if f_confirm ("Are You Sure to Ignore the Change? [Y/N]", "YN") = "Y"
         exit
      else
         do fgetrrnfm
         loop
      endif
   endif
enddo

set key 28 to
set key -1 to
set key -2 to


******************************
procedure rrnfmu5

clear gets
f_use ("RAVM")
seek raagr->funit
do rrnprt with "R"
select ravm
use
select raagr


******************************
procedure fgetrrnfm

yadriver = .not. empty (l_falname + l_fafname)
yestamt = 0.00
yothchg = .not. empty (l_foitem1)
ycdwyn = (l_fcdw > 0.00)
ypaiyn = (l_fpai > 0.00)

@ 1, 12 get l_fresvno picture replicate ([!], 10) valid rrnoa1 ()
@ 2, 12 get l_flname valid f_valid (.not. empty (l_flname))
@ 2, 36 get l_ffname valid f_valid (.not. empty (l_ffname))
@ 3, 12 get l_faddr 
@ 4, 12 get l_fcity 
@ 4, 36 get l_fstate picture [!!]
@ 4, 39 get l_fzip picture [XXXXX-XXXX]
@ 5, 12 get l_fphone picture [999-999-9999]
@ 6, 12 get l_flic picture replicate ([!], 15) ;
   valid f_valid (.not. empty (l_flic))
@ 6, 36 get l_flicst picture [!!] valid f_valid (.not. empty (l_flicst))
@ 7, 12 get l_flicexp valid ;
   f_valid (f_expdate (l_flicexp), "Warning! Driver License Expired!!!")
@ 7, 36 get l_fdob valid rrnoa2 ()
@ 8, 12 get l_fcrpno picture replicate ([!], 15) valid rrnoa4 ()
@ 9, 12 get l_fcrpnm
@ 10, 12 get l_fcrpph picture [999-999-9999]
* 10.23.01: add email
@ 11, 01 say "Email ...."
@ 11, 12 get l_femail
@ 12, 12 get l_flocal1
@ 12, 33 get l_flocal2 
@ 13, 12 get l_finsur1 
@ 13, 33 get l_finsur2 
* @ 14, 12 get l_freferal       && edc: req. by resort
@ 14, 12 say l_freferal
*
@ 15, 26 get yadriver picture [Y] valid rrnoa5 ()
@ 17, 12 get l_floc picture replicate ([!], 10) ;
   valid f_valid (l_floc $ gusrloc, "Invalid Location!!!")
@ 17, 35 get l_frloc picture replicate ([!], 10) ;
   valid f_valid (l_frloc $ gusrloc, "Invalid Location!!!")
@ 18, 12 say l_fdateout 
@ 18, 21 get l_ftimeout picture [99:99]
@ 19, 12 say l_fdays picture [999]
@ 20, 12 say l_fdatein 
@ 20, 21 get l_ftimein picture [99:99]
@ 21, 21 get l_fcalday picture [Y]
@ 22, 21 get l_fwkdday picture [Y] valid rrnoa9 ()
@ 22, 29 get l_fwkdmin picture [99] valid f_valid (l_fwkdmin >= 0)
@ 22, 37 get l_fwkdmax picture [99] valid f_valid (l_fwkdmax >= l_fwkdmin)
@ 23, 12 get l_fdisc picture [99]
@ 23, 29 get l_ftax pict [99.99]
@ 1, 64 get l_frate picture replicate ([!], 6) ;
   valid f_valid (.not. empty (l_frate))
@ 1, 71 get l_fclass picture replicate ([!], 4) valid rrnoa10 ()
@ 2, 52 say "Type"
@ 2, 57 get l_ftmtyp picture [9] valid rrnoa15 ()
@ 3, 64 get l_fdlychg picture [9999.99]
@ 3, 75 get l_fdlymlg picture replicate ([9], 4)
@ 4, 64 get l_fwkdchg picture [9999.99]
@ 4, 75 get l_fwkdmlg picture replicate ([9], 4)
@ 5, 64 get l_fwkchg picture [9999.99]
@ 5, 75 get l_fwkmlg picture replicate ([9], 4)
@ 6, 64 get l_fmthchg picture [9999.99]
@ 6, 75 get l_fmthmlg picture replicate ([9], 4)

@ 7, 61 get l_fhrchg picture [99.99]
@ 8, 61 get l_fmlgchg picture [99.99]

@ 7, 72 get ycdwyn pict "Y" valid rrnfmu16 ()   && 12.10.03:  valid rrnoa16 ()
@ 7, 74 get l_fcdw picture [99.99] valid rrnoa161 ()
@ 8, 72 get ypaiyn pict "Y" valid rrnoa162 ()
@ 8, 74 get l_fpai picture [99.99] valid rrnoa163 ()

@ 10, 61 say l_funit
@ 11, 61 say l_fuclass
@ 12, 61 say l_fmlgout picture replicate ([9], 6)
@ 12, 76 say l_ffuelout picture [9]
@ 13, 69 get yothchg picture [Y] valid rrnoa12 (.f.)
@ 15, 64 say l_fpaytyp1 picture [!!!]
@ 16, 59 say l_fccnum1 picture replicate ([9], 20)
@ 17, 56 say "  /  "
@ 17, 69 say l_fdbacct1 picture replicate ([!], 10)
@ 18, 69 say 0.00 picture [99999.99]
@ 19, 69 say l_fdepamt + l_fhldamt picture [99999.99]
@ 20, 69 say l_fauthcd1 picture replicate ([!], 6)
@ 21, 65 get l_frefno picture replicate ([X], 14)
@ 22, 73 get l_fstamp picture "!!!!!!"
@ 23, 73 say l_frano picture "999999"

***************
function rrnfmu16
private yscn, ycolor, yptr, yitem
ycolor = setcolor (gsubcolor)
yscn = f_box (9, 50, 11, 70)
@ 10, 52 say "CDW "
setcolor (gsubget)
@ 10, 57 say l_fcdw pict "99.99"
@ 10, 64 say l_fcdwded pict "9999"
yptr = 1
do while .t.
   do case
   case yptr = 1
      f_getnum (@l_fcdw, 10, 57, "", "99.99", .t.)
   case yptr = 2
      f_getnum (@l_fcdwded, 10, 64, "", "9999", .t.)
   endcase
   ykey = lastkey ()
   if (ykey = 24 .or. ykey = 13) .and. yptr < 2
      yptr = yptr + 1
   elseif ykey = 5 .and. yptr > 1
      yptr = yptr - 1
   elseif ykey = 27 .or. ykey = 13 .or. ykey = 3 .or. ykey = 18 .or. yptr > 2
      exit
   endif
enddo
f_restbox (yscn)
setcolor (ycolor)

return .t.
