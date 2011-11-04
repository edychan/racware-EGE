* ===========================================================================
* this is the routine to process reservation projection report for racware.
*
* date: 05/01/91
* author: KST
*
* revision
* date: 07/20/92  
* edc: vehicles should be counted only if they are at the specificed location
* date: 12/22/92
* edc: provide 'ALL' for all locations
* date: 02/12/92
* edc: count the res projection as is. (per Dollar Eagle)
* date: 12/05/95
* edc: increase car group to 10
* 07.09.99: preset car group in rasys.dbf (FREMARK1)
*
* 12.01.06: provide option to include ON HOLD units
* -------------------------------------------------
* 04.13.11: add File option
* 06.21.11: add email report option
* ===========================================================================
f_clrscn ("Reservation Projection Report")
setcolor (gsubcolor)
f_box (2, 5, 17, 72)
ydate1 = date ()
ydate2 = date () + 6
yloc = gloc
yaccrual = "N"
yresvper = 0.00
ywkinmult = 0.00
yrpt = "D"
private yvdate [10], yvchg [10], yvclas [10]
afill (yvdate, ctod (space (8)))
afill (yvchg, 0)
afill (yvclas, space (4))
private ycargp [10], yflag
afill (ycargp, space(34))
yflag = .f.
yonhold = .f.
* preload ycargp
private yfil, yfld
yfil = gmempath + "racargp.mem"
if file (yfil)
   restore from &yfil additive
   for i = 1 to 10
      yfld = "l_cargp" + strtran(str(i,2), " ", "")
      ycargp [i] = &yfld
   next
endif
use

@ 03, 07 say "Location [ALL].............."
@ 04, 07 say "Date........................            -"
@ 05, 07 say "[S]ummary/[D]etail.........."
@ 06, 07 say "Accrual [Y/N]..............."
@ 07, 07 say "No Show %...................      %"
@ 08, 07 say "WalkIn %....................      %"
@ 09, 07 say "Include ON HOLD Unit........"
@ 10, 07 say "Car Group..................."
@ 11, 07 say "Date     Class  Fleet Variant  Date     Class  Fleet Variant"
set century on
do while .t.
   @ 03, 36 get yloc picture "!!!!!!!!!!" ;
     valid f_valid (yloc $ gusrloc .or. yloc='ALL')
   @ 04, 36 get ydate1 valid f_valid (f_y2k (@ydate1) .and. ydate1 >= date ())
   @ 04, 49 get ydate2 valid f_valid (f_y2k (@ydate2) .and. ydate2 >= ydate1)
   @ 05, 36 get yrpt pict "!" valid f_valid (yrpt $ "DS")
   @ 06, 36 get yaccrual pict "!" valid f_valid (yaccrual $ "YN")
   @ 07, 36 get yresvper pict "99.99"
   @ 08, 36 get ywkinmult pict "99.99"
   * for i = 1 to 5
   *   @ i + 8, 18 say str(i,1)+"..............."
   *   @ i + 8, 36 get ycargp[i] pict "!!!!-!!!!-!!!!-!!!!-!!!!-!!!!-!!!!"
   *next 
   @ 09, 36 get yonhold picture [Y] 
   @ 10, 36 get yflag picture [Y] valid rrvpj2 ()
   for i = 1 to 5
      @ i + 11, 07 get yvdate [i*2-1]
      @ i + 11, 19 get yvclas [i*2-1] pict "!!!!"
      @ i + 11, 27 get yvchg [i*2-1] pict "9999"
      @ i + 11, 38 get yvdate [i*2]
      @ i + 11, 50 get yvclas [i*2] pict "!!!!"
      @ i + 11, 58 get yvchg [i*2] pict "9999"
   next
   f_rd ()
   set century off
   * --06.21.11: add email option
   if gemrpt
      ydisp = f_confirm ("[D]isplay  [F]ile  [P]rint   [E]dit   [S]end   [Q]uit", "DFPESQ")
   else
      ydisp = f_confirm ("[D]isplay  [F]ile  [P]rint   [E]dit   [Q]uit", "DFPEQ")
   endif
   if ydisp = "Q"
      close databases
      return
   endif
   if ydisp $ "DFPS"
      exit
   endif
enddo

ywkinmult = ywkinmult / (100.00 - ywkinmult)
if yonhold        && 12.01.06
   ycond = [AIXH]
else
   ycond = [AIX]
endif  

private yrptname, yemail, yffile
yrptname = "Reservation Projection Report"
* --04.13.11
if ydisp = "F"
   yffile = gstnpath + "res_proj.rpt"
elseif ydisp = "S"
   yffile = gempath + "rr"+strtran(time(),":","")+".txt"
   yscn = f_box (13, 10, 16, 73)
   yemail = f_truncate(gemail, 40)
   @ 14, 11 say "Email:"
   do while .t.
      @ 14, 18 get yemail picture replicate ("x", 40) ;     
         valid f_valid (f_goodem (yemail, .f.), "Invalid email address ...")   && cannot enter NA as valid email
      if f_rd () = 27
         close databases
		 return
     else
         exit	 
     endif
   enddo
else
   yffile = gstnpath + "rrout.rpt"
endif
* --
f_popup ("Please Wait...", .f.)
f_use ("raagr")

f_use ("ravm")
* edc: 07/20 count vehicle that is in the specified location only ...
if yloc = "EGE"
   set filter to trim(floc) $ "EGE;THY"      && 11.01.11: special case EGE + THY
elseif yloc <> "ALL"
   set filter to floc = yloc
else
  set filter to
endif

yflag = .f.
for i = 1 to 10
   if .not. empty(substr(ycargp[i],1,4))
      yflag = .t.
      exit
   endif
next

select 0
create (gstnpath + "stru")
use (gstnpath + "stru") exclusive
append blank
replace field_name with "FCLASS"
replace field_type with "C"
replace field_len with 4
replace field_dec with 0
append blank
replace field_name with "FGROUP"
replace field_type with "C"
replace field_len with 34
replace field_dec with 0
append blank
replace field_name with "FAVAIL"
replace field_type with "N"
replace field_len with 4
replace field_dec with 0
use
create (gstnpath + "ravehs") from (gstnpath + "stru")
erase (gstnpath + "stru.dbf")
use (gstnpath + "ravehs") exclusive alias ravehs
zap
index on fclass to (gstnpath + "ravehs")

if .not. yflag               && yflag = .f. ==> for all car class
   select ravm
   go top
   do while .not. eof ()
      select ravehs
      seek ravm->fclass
      if .not. found ()
         append blank
         replace fclass with ravm->fclass
         if ravm->fstatus $ ycond
            replace favail with 1
         endif
      elseif ravm->fstatus $ ycond
         replace favail with favail + 1
      endif
      select ravm
      skip
   enddo
else
   select ravehs
   for i = 1 to 10
      if .not. empty(substr(ycargp[i],1,4))
         append blank
         replace fclass with substr(ycargp[i],1,4)
         replace fgroup with ycargp[i]
      endif
   next
   select ravm
   go top
   do while .not. eof ()
      if fstatus $ ycond
         select ravehs
         locate for ravm->fclass $ fgroup
         if found ()
            replace favail with favail + 1
         endif
      endif
      select ravm
      skip
   enddo
endif

select ravehs
private yclass [reccount ()]
go top
ynum = 0
setcolor (gbluecolor)
@ 1, 0 clear to 23, 79
do while .not. eof ()
   ynum = ynum + 1
   yclass [ynum] = fclass
   @ 2, 5 say "Number of vehicle classes = " + ltrim (str (ynum))
   skip
enddo

f_popup ("Creating Projection Report Database", .f.)

select 0
if .not. file (gstnpath + "raproj.dbf")
   create (gstnpath + "stru")
   use (gstnpath + "stru") exclusive
   append blank
   replace field_name with "FDATE"
   replace field_type with "D"
   replace field_len with 8
   replace field_dec with 0
   append blank
   replace field_name with "FHR"
   replace field_type with "C"
   replace field_len with 1
   replace field_dec with 0
   append blank
   replace field_name with "FCLASS"
   replace field_type with "C"
   replace field_len with 4
   replace field_dec with 0
   append blank
   replace field_name with "FNET"
   replace field_type with "N"
   replace field_len with 4
   replace field_dec with 0
   append blank
   replace field_name with "FRES"
   replace field_type with "N"
   replace field_len with 4
   replace field_dec with 0
   append blank
   replace field_name with "FWKIN"
   replace field_type with "N"
   replace field_len with 4
   replace field_dec with 0
   append blank
   replace field_name with "FDUE"
   replace field_type with "N"
   replace field_len with 4
   replace field_dec with 0
   use
   create (gstnpath + "raproj") from (gstnpath + "stru")
   erase (gstnpath + "stru.dbf")
endif
use (gstnpath + "raproj") exclusive alias raproj
zap
index on fclass + dtos (fdate) + fhr to (gstnpath + "raproj")

for n = 0 to (ydate2 - date ())
   select ravehs
   go top
   do while .not. eof ()
      select raproj
      append blank
      replace fdate with date () + n, fhr with "A", fclass with ravehs->fclass
      replace fres with 0, fdue with 0, fwkin with 0
      if n = 0
         replace fnet with ravehs->favail
      else
         replace fnet with 0
      endif
      commit
      append blank
      replace fdate with date () + n, fhr with "P", fclass with ravehs->fclass
      replace fnet with 0, fres with 0, fdue with 0, fwkin with 0
      commit
      select ravehs
      skip
   enddo
next

f_popback ()

x = 0
f_use ("rares", 2)
seek "O"
if yloc = 'EGE'    && 11.01.11: special case 
   ycond1='fdateout <= ydate2 .and. trim(floc) $ [EGE;THY]'
   ycond2='fdatein <= ydate2 .and. trim(floc) $ [EGE;THY]'
elseif yloc <> 'ALL'
   ycond1='fdateout <= ydate2 .and. floc = yloc'
   ycond2='fdatein <= ydate2 .and. frloc = yloc'
else
   ycond1='fdateout <= ydate2'
   ycond2='fdatein <= ydate2' 
endif
do while fresvstat = "O" .and. .not. eof ()
   x = x + 1
   @ 4, 5 say "Scanning " + ltrim (str (x)) + " reservations"
   if &ycond1
      if ftimeout < "12:00"
         l_fhr = "A"
      else
         l_fhr = "P"
      endif
      select raproj
      ykey = rrvpj1 (rares->fclass)
      seek ykey + dtos (rares->fdateout) + l_fhr
      replace fres with fres + 1
      commit
      select rares
   endif
   if &ycond2
      if ftimein < "12:00"    && 08/10/95: ftimein instead of ftimeout
         l_fhr = "A"
      else
         l_fhr = "P"
      endif
      select raproj
      ykey = rrvpj1 (rares->fclass)
      seek ykey + dtos (rares->fdatein) + l_fhr
      replace fdue with fdue + 1
      commit
      select rares
   endif
   skip
enddo
use
select raproj
for n = 1 to 10
   if .not. empty (yvdate [n]) .and. .not. empty (yvclas [n])
      ykey = rrvpj1 (yvclas [n])
      seek ykey + dtos (yvdate [n]) + "A"
      if found ()
         replace fnet with fnet + yvchg [n]
      endif
   endif
next

select raagr
set filter to frano > 0 .and. .not. empty (floc) ;
      .and. upper (flocal1) <> "REWRITE"
go top
x = 0
do while .not. eof ()
   x = x + 1
   @ 6, 5 say "Scanning " + ltrim (str (x)) + " Open Contracts"
   if &ycond2
      if ftimein < "12:00"
         l_fhr = "A"
      else
         l_fhr = "P"
      endif
      select raproj
      ykey = rrvpj1 (raagr->fuclass)
      seek ykey + dtos (raagr->fdatein) + l_fhr
      replace fdue with fdue + 1
      commit
      select raagr
   endif
   skip
enddo
use

f_popup ("Accumulating Data", .f.)
select raproj
go top
yprevclass = "~~~~"
do while .not. eof ()
   if fclass <> yprevclass
      yprevclass = fclass
   else
      replace fwkin with round (fres * ywkinmult, 0)
      replace fnet with fnet + ynextnet
      replace fres with round (fres * (100.00 - yresvper) / 100.00, 0)
   endif
   ynextnet = fnet - fres - fwkin + fdue
   * 02/12/93 edc: count res as is.
   if ynextnet < 0 .and. fhr = "P" .and. yaccrual = "N"
      ynextnet = 0
   endif
   skip
enddo

f_popup ("Creating Report", .f.)
yheading1 = "Run Date: " + dtoc (date ()) + space (30) + ;
   "Reservation Projection Report" + space (45) + "Page"
yheading2 = "Run Time: " + time () + space (22) + "Location: " + yloc + ;
   "  From " + dtoc (ydate1) + " To " + dtoc (ydate2)
if ydisp = "P"
   yheading1 = chr (15) + yheading1
endif
yline = 0
ypage = 0
if ydisp $ "D;F;S"           && 06.22.11: email option
   set printer to &yffile
   set device to print
else
   set device to print
endif
setprc (0,0)
for n = 0 to (ydate2 - ydate1)
   for n1 = 1 to 2
      if ynum <= 20 .or. ydisp $ "D;F;S"      && 06.22.11
         if yline > 52
            if ydisp = "P"
               eject
            else
               @ yline + 1, 0 say replicate ("Ä", 131)
               @ yline + 2, 0 say ""
               setprc (0, 0)
            endif
            yline = 0
         endif
         if yline = 0
            ypage = ypage + 1
            yline = yline + 1
            @ yline, 0 say yheading1 + str (ypage, 4)
            yline = yline + 1
            @ yline, 0 say yheading2
            yline = yline + 2
            @ yline, 0 say "DATE"
            for n2 = 1 to ynum
               @ yline, 18 + (n2 - 1) * 5 say yclass [n2]
            next
            @ yline, 18 + ynum * 5 say "Total"
            yline = yline + 1
            @ yline, 0 say "-----------"
            for n2 = 1 to ynum
               @ yline, 18 + (n2 - 1) * 5 say "----"
            next
            @ yline, 18 + ynum * 5 say "-----"
            yline = yline + 1
         endif

         yline = yline + 1
         @ yline, 0 say dtoc (ydate1 + n) + if (n1 = 1, " am", " pm") + " Avail"
         ylinetot = 0
         for n2 = 1 to ynum
            seek yclass [n2] + dtos (ydate1 + n) + if (n1 = 1, "A", "P")
            ylinetot = ylinetot + fnet
            @ yline, 18 + (n2 - 1) * 5 say str (fnet, 4)
         next
         @ yline, 18 + ynum * 5 say str (ylinetot, 5)
         if yrpt = "D"
            yline = yline + 1
            @ yline, 12 say "Resv"
            ylinetot = 0
            for n2 = 1 to ynum
               seek yclass [n2] + dtos (ydate1 + n) + if (n1 = 1, "A", "P")
               ylinetot = ylinetot + fres
               @ yline, 18 + (n2 - 1) * 5 say str (fres, 4)
            next
            @ yline, 18 + ynum * 5 say str (ylinetot, 5)

            yline = yline + 1
            @ yline, 12 say "Wk In"
            ylinetot = 0
            for n2 = 1 to ynum
               seek yclass [n2] + dtos (ydate1 + n) + if (n1 = 1, "A", "P")
               ylinetot = ylinetot + fwkin
               @ yline, 18 + (n2 - 1) * 5 say str (fwkin, 4)
            next
            @ yline, 18 + ynum * 5 say str (ylinetot, 5)

            yline = yline + 1
            @ yline, 12 say "Due"
            ylinetot = 0
            for n2 = 1 to ynum
               seek yclass [n2] + dtos (ydate1 + n) + if (n1 = 1, "A", "P")
               ylinetot = ylinetot + fdue
               @ yline, 18 + (n2 - 1) * 5 say str (fdue, 4)
            next
            @ yline, 18 + ynum * 5 say str (ylinetot, 5)
         endif
         yline = yline + 1
      else
         ycnt1 = 1
         ycnt2 = ynum
         store 0 to ylinetot1, ylinetot2, ylinetot3, ylinetot4
         do while .t.
            if yline > 52
               eject
               yline = 0
            endif
            if yline = 0
               ypage = ypage + 1
               yline = yline + 1
               @ yline, 0 say yheading1 + str (ypage, 4)
               yline = yline + 1
               @ yline, 0 say yheading2
            endif

            ycnt2 = ycnt1 + 19
            if ycnt2 > ynum
               ycnt2 = ynum
            endif
            yline = yline + 2
            if ycnt1 = 1
               @ yline, 0 say "DATE"
            endif
            for n2 = ycnt1 to ycnt2
               @ yline, 18 + (n2 - ycnt1) * 5 say yclass [n2]
            next
            if ycnt2 = ynum
               @ yline, 18 + (ycnt2 - ycnt1 + 1) * 5 say "Total"
            endif
            yline = yline + 1
            if ycnt1 = 1
               @ yline, 0 say "-----------"
            endif
            for n2 = ycnt1 to ycnt2
               @ yline, 18 + (n2 - ycnt1) * 5 say "----"
            next
            if ycnt2 = ynum
               @ yline, 18 + (ycnt2 - ycnt1 + 1) * 5 say "-----"
            endif
            yline = yline + 1
            if ycnt1 = 1
               @ yline, 0 say dtoc (ydate1 + n) + if (n1 = 1, " am", " pm") + " Avail"
            else
               @ yline, 12 say "Avail"
            endif
            for n2 = ycnt1 to ycnt2
               seek yclass [n2] + dtos (ydate1 + n) + if (n1 = 1, "A", "P")
               ylinetot1 = ylinetot1 + fnet
               @ yline, 18 + (n2 - ycnt1) * 5 say str (fnet, 4)
            next
            if ycnt2 = ynum
               @ yline, 18 + (ycnt2 - ycnt1 + 1) * 5 say str (ylinetot1, 5)
            endif
            if yrpt = "D"
               yline = yline + 1
               @ yline, 12 say "Resv"
               for n2 = ycnt1 to ycnt2
                  seek yclass [n2] + dtos (ydate1 + n) + if (n1 = 1, "A", "P")
                  ylinetot2 = ylinetot2 + fres
                  @ yline, 18 + (n2 - ycnt1) * 5 say str (fres, 4)
               next
               if ycnt2 = ynum
                  @ yline, 18 + (ycnt2 - ycnt1 + 1) * 5 say str (ylinetot2, 5)
               endif
               yline = yline + 1
               @ yline, 12 say "Wk In"
               for n2 = ycnt1 to ycnt2
                  seek yclass [n2] + dtos (ydate1 + n) + if (n1 = 1, "A", "P")
                  ylinetot3 = ylinetot3 + fwkin
                  @ yline, 18 + (n2 - ycnt1) * 5 say str (fwkin, 4)
               next
               if ycnt2 = ynum
                  @ yline, 18 + (ycnt2 - ycnt1 + 1) * 5 say str (ylinetot3, 5)
               endif
               yline = yline + 1
               @ yline, 12 say "Due"
               for n2 = ycnt1 to ycnt2
                  seek yclass [n2] + dtos (ydate1 + n) + if (n1 = 1, "A", "P")
                  ylinetot4 = ylinetot4 + fdue
                  @ yline, 18 + (n2 - ycnt1) * 5 say str (fdue, 4)
               next
               if ycnt2 = ynum
                  @ yline, 18 + (ycnt2 - ycnt1 + 1) * 5 say str (ylinetot4, 5)
               endif
            endif
            if ycnt2 = ynum
               exit
            endif
            ycnt1 = ycnt2 + 1
         enddo
         yline = yline + 1
      endif
   next
next
if ydisp = "P"
   @ yline, 130 say chr (18)
   eject
endif

set device to screen
set printer to
f_popback()
if ydisp = "D"
   set color to
   clear
   run racbrow &yffile
elseif ydisp = "S"
   * --06.21.11
   if f_sndrep (yemail, yrptname, substr(yffile, at("rr", yffile)))    && i.e. rr123456.txt
      f_valid (.f., "Email is now in the message queue ...")
   else
      f_valid (.f., "Email is not setup ...")
   endif
   * --   
endif

close database

*******************************
function rrvpj1
parameter xkey
private ysel

if .not. yflag
   return xkey
endif

ysel = select ()
select ravehs
go top
locate for xkey $ fgroup
if found ()
   xkey = fclass
endif

select (ysel)
return xkey

*******************************
function rrvpj2

if yflag

private yscn, ycolor, yptr, yyr, yfld
ycolor = setcolor (gsubcolor)
yscn = f_box (10, 10, 21, 51)
for i = 1 to 10
   @ i+10, 12 say str(i,2)+". "
next i

setcolor (gsubget)
for i = 1 to 10
   @ i+10, 16 say ycargp [i]
next i

yptr = 1
do while .t.
   do case
   case yptr = 1
      yfld = ycargp[1]
      f_getfld (@yfld, 11, 16, "W/N", 34, "!!!!-!!!!-!!!!-!!!!-!!!!-!!!!-!!!!", .t.)
      ycargp[1] = yfld
   case yptr = 2
      yfld = ycargp[2]
      f_getfld (@yfld, 12, 16, "W/N", 34, "!!!!-!!!!-!!!!-!!!!-!!!!-!!!!-!!!!", .t.)
      ycargp[2] = yfld
   case yptr = 3
      yfld = ycargp[3]
      f_getfld (@yfld, 13, 16, "W/N", 34, "!!!!-!!!!-!!!!-!!!!-!!!!-!!!!-!!!!", .t.)
      ycargp[3] = yfld
   case yptr = 4
      yfld = ycargp[4]
      f_getfld (@yfld, 14, 16, "W/N", 34, "!!!!-!!!!-!!!!-!!!!-!!!!-!!!!-!!!!", .t.)
      ycargp[4] = yfld
   case yptr = 5
      yfld = ycargp[5]
      f_getfld (@yfld, 15, 16, "W/N", 34, "!!!!-!!!!-!!!!-!!!!-!!!!-!!!!-!!!!", .t.)
      ycargp[5] = yfld
   case yptr = 6
      yfld = ycargp[6]
      f_getfld (@yfld, 16, 16, "W/N", 34, "!!!!-!!!!-!!!!-!!!!-!!!!-!!!!-!!!!", .t.)
      ycargp[6] = yfld
   case yptr = 7
      yfld = ycargp[7]
      f_getfld (@yfld, 17, 16, "W/N", 34, "!!!!-!!!!-!!!!-!!!!-!!!!-!!!!-!!!!", .t.)
      ycargp[7] = yfld
   case yptr = 8
      yfld = ycargp[8]
      f_getfld (@yfld, 18, 16, "W/N", 34, "!!!!-!!!!-!!!!-!!!!-!!!!-!!!!-!!!!", .t.)
      ycargp[8] = yfld
   case yptr = 9
      yfld = ycargp[9]
      f_getfld (@yfld, 19, 16, "W/N", 34, "!!!!-!!!!-!!!!-!!!!-!!!!-!!!!-!!!!", .t.)
      ycargp[9] = yfld
   case yptr = 10
      yfld = ycargp[10]
      f_getfld (@yfld, 20, 16, "W/N", 34, "!!!!-!!!!-!!!!-!!!!-!!!!-!!!!-!!!!", .t.)
      ycargp[10] = yfld
   endcase
   ykey = lastkey ()
   if (ykey = 24 .or. ykey = 13) .and. yptr < 10
      yptr = yptr + 1
   elseif ykey = 5 .and. yptr > 1
      yptr = yptr - 1
   elseif ykey = 27 .or. ykey = 13 .or. ykey = 3 .or. ykey = 18
      exit
   endif
enddo
* save ycargp
yfil = gmempath + "racargp"
for i = 1 to 10
   yfld = "l_cargp" + strtran (str(i,2), " ", "")
   &yfld = ycargp [i]
next
save to &yfil all like l_cargp*
*
f_restbox (yscn)
setcolor (ycolor)
endif
return .t.
