private yerror, yreccnt, ycnt, yterm_id
private yresponse, yauthcode, yrow, yscn, yloc

set cursor off
f_clrscn ("Batch Authorization")
etx = chr (03)
enq = chr (05)
ack = chr (06)
eot = chr (04)
stx = chr (02)
nak = chr (21)
fs  = chr (28)

setcolor (gredcolor)
ydays = 10
yloc = gloc
@ 24, 01 say "# of days old Approvals to be re-authorized: [   ]   " + ;
   "Location: [          ]"
@ 24, 47 get ydays picture "999"
@ 24, 65 get yloc pict "!!!!!!!!!!"
if f_rd () = 27
   return
endif
@ 24, 00

if .not. getccsetup (yloc)
   return
endif

ydate = date () - ydays

setcolor (gsubcolor)
yresponse = space (30)

f_mess (.t., "Counting Unauthorized Transaction...", "N/W")
f_use ("RAAGR", 1)

set delete on
f_use ("RACRED")
set filter to .not. (ftranstyp $ "XD") .and. (frectype = __gccunauth .or. ;
   frectype = __gccspecauth .or. ((frectype = __gccauth .or. ;
   frectype = __gccuncap) .and. fauthdate < ydate))
select 0
if .not. file (gstnpath + "RCCCNT.DBF")
   create errortmp
   use errortmp exclusive
   append blank
   replace field_name with "FRECNO", field_type with "N", field_len with 6
   use
   create (gstnpath + "RCCCNT") from errortmp
   erase errortmp.dbf
endif
use (gstnpath + "RCCCNT") exclusive alias stfil
zap

select racred
go top
ycnt = 0
do while .not. eof ()
   if frectype = __gccunauth .or. frectype = __gccauth
      select raagr
      seek racred->floc + str (racred->frano, 6)
      if .not. found ()
         select racred
         yrec1 = recno ()
         skip
         if eof ()
            go (yrec1)
            f_clrrec ()
            exit
         endif
         yrec2 = recno ()
         go (yrec1)
         f_clrrec ()
         go (yrec2)
         loop
      endif
   endif
   select racred
   if .not. (frloc = yloc .or. empty (yloc))
      skip
      loop
   endif
   ycnt = ycnt + 1
   yrecno = recno ()
   select stfil
   append blank
   f_mess (.f.)
   f_mess (.t., "Counting Transaction... # " + ;
      alltrim (str (ycnt)), "N/W")
   replace frecno with yrecno
   commit
   select racred
   skip
enddo
select raagr
use

select stfil
yreccnt = reccount ()
if yreccnt = 0
   f_mess (.f.)
   f_mess (.t., "No Transactions To Authorize... Press ENTER...", "N/W")
   inkey (0)
   select stfil
   use
   select racred
   use
   return
endif

f_mess (.f.)
f_mess (.t., "Processing " + alltrim (str (yreccnt)) + ;
   " Unauthorized Transactions", "N/W")

yscn = f_mkbox ("Communication Port Status")
yerror = net_dial (.f.)
if yerror <> 0
   close databases
   return
endif

select stfil
go top
if gccnet = "NDC"
   yterm_id = __gprefix + alltrim (__gica) + alltrim (__gmerch)
endif
yrow = 12

f_box (11, 1, 22, 77, "Authorization Status")
@ 12, 3 say "ÄCONTRACTÄÄÄÄÄÄÄÄ ÄCREDIT CARDÄÄÄÄÄÄÄÄ ÄAMOUNTÄ " + ;
   "ÄSTATUSÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ"
ycnt = 0
do while .not. eof ()
   ycnt = ycnt + 1
   select racred
   go stfil->frecno
   if gccnet = "NDC"
      do case
      case ftranstyp = "S"
         ymessage = tformat ("S", yterm_id, fccnum, fccexp, ;
            alltrim (str (fauthamt)))
      case ftranstyp = "C"
         ymessage = tformat ("C", yterm_id, fccnum, fccexp, ;
            alltrim (str (fauthamt)))
      case ftranstyp = "F"
         ymessage = tformat ("F", yterm_id, fccnum, fccexp, ;
            alltrim (str (fauthamt)), fauthcode)
      otherwise
         select stfil
         skip
         loop
      endcase
   else
      do case
      case ftranstyp = "S"
         ymessage = tformat ("S", __gcompuid, __gmerch, __gtermid, ;
            __gserial, "001", "B", fccnum, fccexp, "", ;
            alltrim (str (fauthamt)))
      case ftranstyp = "C"
         ymessage = tformat ("S", __gcompuid, __gmerch, __gtermid, ;
            __gserial, "001", "B", fccnum, fccexp, "", ;
            alltrim (str (fauthamt)))
      case ftranstyp = "F"
         ymessage = tformat ("S", __gcompuid, __gmerch, __gtermid, ;
            __gserial, "123", "B", fccnum, fccexp, "", ;
            alltrim (str (fauthamt)))
      otherwise
         select stfil
         skip
         loop
      endcase
   endif

   if yrow >= 21
      scroll (13, 2, 21, 76, 1)
   else
      yrow = yrow + 1
   endif
   @ yrow, 03 say alltrim (floc) + "-" + ltrim (str (frano, 6))
   @ yrow, 21 say fccnum
   @ yrow, 42 say fauthamt picture "99999.99"

   yerror = snd_recv ("BT", ymessage, @yresponse, "Transaction # " ;
      + alltrim (str (ycnt)))
   if yerror <> 0
      exit
   endif

   if gccnet = "LPA"
      yresponse = alltrim (substr (yresponse, 15, 8) + " " + ;
         substr (yresponse, 29))
   endif
   f_fupdate ("C")
   reclock ()
   replace fauthstat with yresponse
   yauthcode = space (6)
   if auth_ok (yresponse, @yauthcode)
      if frectype = __gccspecauth
         replace frectype with __gccuncap
      elseif frectype = __gccunauth
         replace frectype with __gccauth
      endif
      replace fauthcode with yauthcode
      replace fauthdate with date (), fauthtime with time ()
      @ yrow, 51 say "Approved: " + fauthcode
   else
      replace frectype with __gccautherr
      replace fauthdate with date (), fauthtime with time ()
      @ yrow, 51 say left (ltrim (fauthstat), 25)
   endif
   commit
   unlock
   select stfil
   skip
enddo

f_wtbox ("Hanging up...")
hangup ()
closecomm (__gcomm)
f_rmbox (yscn)

f_mess (.f.)
f_mess (.t., "Transaction Complete...", "N/W")
inkey (5)
f_mess (.f.)
close databases

