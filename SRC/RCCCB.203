* ===========================================================================
* credit card processing: capture batch
*
* date: 05/01/91
* author: KST
*
* revision
* date: 08/31/93
* edc: pass to tformat whether the cc trans. read thru swipe
*      or entered manually. (yccswipe)
* date: 09/30/93 
* edc: make sure dbr# > 0
* date: 11/19/93
* edc: bug fixes for ndc capture
*
* ===========================================================================
private yresponse, ybatch, ynewbatch, yerror, ybalance, yreccnt, yscn, yrow
private ydetail, ybalance, ybal, yvoids, ydbr1, ydbr2
private yterm_id, ymessage, yamexdial, ycnt, yloc

set cursor off
f_clrscn ("Batch Settlement")

setcolor (gredcolor)
ydbr1 = 0
ydbr2 = 0
yloc = gloc
@ 24, 01 say "Enter Location: [          ]  DBR's To Capture: [    ] -> [    ]"
@ 24, 18 get yloc picture "!!!!!!!!!!"
* 09/30/93 (edc) make sure dbr# > 0
@ 24, 50 get ydbr1 picture "9999" valid ydbr1 > 0 .and. f_compute (@ydbr2, ydbr1)
@ 24, 60 get ydbr2 picture "9999"
if f_rd () = 27
   return
endif
@ 24, 00
if f_confirm ("Capture " + alltrim (yloc) + " from DBR " + ;
      alltrim (str (ydbr1)) + " to " + alltrim (str (ydbr2)) + " [Y/N]", "YN") = "N"
   return
endif

if .not. getccsetup (yloc)
   return
endif

etx = chr (03)
enq = chr (05)
ack = chr (06)
eot = chr (04)
stx = chr (02)
nak = chr (21)
fs  = chr (28)
yresponse = space (30)

setcolor (gsubcolor)
f_mess (.t., "Counting Transactions...", "N/W")
set delete on
f_use ("RASYS")
f_use ("RALOC")
f_use ("RAAGRH")
f_use ("RACRED", 4)

set filter to frectype = __gccuncap .and. .not. fauthonly .and. ;
   .not. (ftranstyp $ "XD")
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
set softseek on
seek yloc + str (ydbr1, 4)
ycnt = 0
do while .not. eof () .and. fdbrno <= ydbr2 .and. frloc = yloc
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
set softseek off

select stfil
yreccnt = reccount ()
if yreccnt = 0
   f_mess (.f.)
   f_mess (.t., "No Transactions To Capture... Press ENTER...", "N/W")
   rcccbcln ()
   return
endif

f_mess (.f.)
f_mess (.t., "Totaling Of The " + alltrim (str (yreccnt)) + ;
   " Transactions ...", "N/W")

select rasys
go top
if fccbatch <= 0
   ybatch = 1
else
   ybatch = fccbatch
endif
ynewbatch = ybatch + 1

f_box (11, 1, 22, 77, "Settlement Transactions")
@ 12, 3 say "ÄCONTRACTÄÄÄÄÄÄÄÄ ÄCREDIT CARDÄÄÄÄÄÄÄÄ ÄAMOUNTÄ " + ;
   "ÄTRANSACTION TYPEÄÄÄÄÄÄÄÄ"
yrow = 12
if gccnet = "NDC"
   if yreccnt < 3
      debug_disp ("Using NDC One Block")
      ydetail = ""
      ybalance = 0.00
      ybal = 0.00
      yvoids = 0
      select stfil
      go top
      do while .t.
         * 11/19/93 edc: 
         select racred
         go stfil->frecno
         ydetail = ydetail + tformat ("DB", fccnum, ;
            alltrim (str (fauthamt)), ftranstyp, fauthcode, "", "T01")
         if yrow >= 21
            scroll (13, 2, 21, 76, 1)
         else
            yrow = yrow + 1
         endif
         @ yrow, 03 say alltrim (floc) + "-" + ltrim (str (frano, 6))
         @ yrow, 21 say fccnum
         @ yrow, 42 say fauthamt picture "99999.99"
         if ftranstyp = "V"
            yvoids = yvoids + 1
            @ yrow, 51 say "Void"
         elseif ftranstyp = "S" .or. ftranstyp = "F"
            ybal = ybal + fauthamt
            @ yrow, 51 say if (ftranstyp = "S", "Sale", "Force")
         else
            ybal = ybal - fauthamt
            @ yrow, 51 say "Credit"
         endif

         ybalance = ybalance + fauthamt
         select stfil      && 11/19/93: edc
         skip
         if eof ()
            exit
         else
            ydetail = ydetail + fs
         endif
      enddo
      yterm_id = __gprefix + alltrim (__gica) + alltrim (__gmerch)
      ymessage = tformat ("FOB", yterm_id, __gplanno, __gcompany, ;
         __gstore, alltrim (str (yreccnt - yvoids)), ;
         alltrim (str (yreccnt)), ydetail, alltrim (str (abs (ybal))))
      yamexdial = .f.
      yscn = f_mkbox ("Communication Port Status")
      if modem_send (@ymessage, @yresponse) <> 0
         rcccbcln ()
         return
      endif
   else
      ybalance = 0.00
      ybal = 0.00
      yvoids = 0
      select stfil
      go top
      *count for ftranstyp = "V" to yvoids   && 11/19/93: edc
      yterm_id = __gprefix + alltrim (__gica) + alltrim (__gmerch)
      * 11/19/93: edc
      select racred
      go stfil->frecno
      *
      ydetail = tformat ("DB", fccnum, alltrim (str (fauthamt)), ;
         ftranstyp, fauthcode,"","T01") + fs
      yrow = yrow + 1
      @ yrow, 03 say alltrim (floc) + "-" + ltrim (str (frano, 6))
      @ yrow, 21 say fccnum
      @ yrow, 42 say fauthamt picture "99999.99"
      if ftranstyp = "S" .or. ftranstyp = "F"
         ybal = ybal + fauthamt
         @ yrow, 51 say if (ftranstyp = "S", "Sale", "Force")
      elseif ftranstyp = "C"
         ybal = ybal - fauthamt
         @ yrow, 51 say "Credit"
      else
         @ yrow, 51 say "Void"
      endif
      ybalance = ybalance + fauthamt
      ymessage = tformat ("FB", yterm_id, __gplanno, __gcompany, __gstore, ;
         alltrim (str (yreccnt - yvoids)), alltrim (str (yreccnt)), ydetail)
      yscn = f_mkbox ("Communication Port Status")
      if net_dial (.f.) <> 0
         rcccbcln ()
         return
      endif
      debug_disp ("NDC_SENDing 1st Block")
      if snd_recv ("N1", ymessage, @yresponse, "Header") <> 0
         rcccbcln ()
         return
      endif
      select stfil
      skip
      select racred
      go stfil->frecno
      ydetail = ""
      ycnt = 1
      ** important: send n-1 items, leave the last item in last block
      for i = 2 to yreccnt - 1
         ydetail = ydetail + tformat ("DB" ,fccnum, ;
            alltrim (str (fauthamt)), ftranstyp, fauthcode, "", "T01") ;
            + fs
         if yrow >= 21
            scroll (13, 2, 21, 76, 1)
         else
            yrow = yrow + 1
         endif
         @ yrow, 03 say alltrim (floc) + "-" + ltrim (str (frano, 6))
         @ yrow, 21 say fccnum
         @ yrow, 42 say fauthamt picture "99999.99"
         if ftranstyp = "V"
            @ yrow, 51 say "Void"
         elseif ftranstyp = "S" .or. ftranstyp = "F"
            ybal = ybal + fauthamt
            @ yrow, 51 say if (ftranstyp = "S", "Sale", "Force")
         else
            ybal = ybal - fauthamt
            @ yrow, 51 say "Credit"
         endif
         ybalance = ybalance + fauthamt
         if ycnt/4 = int (ycnt/4)    && sending 4 block at a time
            ymessage = tformat ("IB", yterm_id, ydetail)
            debug_disp ("NDC_SENDing 2nd Block 4 records")
            if snd_recv ("N2", ymessage, @yresponse, ;
                  "Detail Block " + alltrim (str (ycnt))) <> 0
               rcccbcln ()
               return
            endif
            ydetail = ""
         endif
         * 11/19/93: edc
         select stfil
         skip
         ycnt = ycnt + 1
         select racred
         go stfil->frecno
      next 

      if .not. empty (ydetail)
         ymessage = tformat ("IB", yterm_id, ydetail)
         debug_disp ("NDC_SENDing 2nd Block 4 records")
         if snd_recv ("N2", ymessage, @yresponse, ;
               "Detail Block " + alltrim (str (ycnt))) <> 0
            rcccbcln ()
            return
         endif
      endif
      debug_disp ("Block 2 Complete")

      * send last detail record with trailer block
      select stfil
      go bottom
      select racred
      go stfil->frecno
      if yrow >= 21
         scroll (13, 2, 21, 76, 1)
      else
         yrow = yrow + 1
      endif
      @ yrow, 03 say alltrim (floc) + "-" + ltrim (str (frano, 6))
      @ yrow, 21 say fccnum
      @ yrow, 42 say fauthamt picture "99999.99"
      if ftranstyp = "V"
         @ yrow, 51 say "Void"
      elseif ftranstyp = "S" .or. ftranstyp = "F"
         ybal = ybal + fauthamt
         @ yrow, 51 say if (ftranstyp = "S", "Sale", "Force")
      else
         ybal = ybal - fauthamt
         @ yrow, 51 say "Credit"
      endif
      ydetail = tformat ("DB", fccnum, ;
         alltrim (str (fauthamt)), ftranstyp, fauthcode,"","T01")
      
      ymessage = tformat ("LB", yterm_id, ydetail, ;
         alltrim (str (abs (ybal))))
      debug_disp ("NDC_SENDing 3rd Block")
      if snd_recv ("N3", ymessage, @yresponse, "Trailer Block") = 0
         f_wtbox ("Hanging Up...")
         hangup()
         closecomm(__gcomm)
      else
         rcccbcln ()
         return
      endif
      f_wtbox (yresponse)
      f_popup ("Press ENTER to continue...", .t.)
   endif
elseif gccnet = "LPA"
   ybalance = 0.00
   ybal = 0.00
   select stfil
   go top
   yrow = 12
   ycnt = 0
   do while .not. eof()
      ycnt = ycnt + 1
      select racred
      go stfil->frecno
      if ftranstyp = "S" .or. ftranstyp = "F"
         ybalance = ybalance + fauthamt
      elseif ftranstyp = "C"
         ybal = ybal + fauthamt
      endif
      if yrow >= 21
         scroll (13, 2, 21, 76, 1)
      else
         yrow = yrow + 1
      endif
      @ yrow, 03 say alltrim (floc) + "-" + ltrim (str (frano, 6))
      @ yrow, 21 say fccnum
      @ yrow, 42 say fauthamt picture "99999.99"
      if ftranstyp = "V"
         @ yrow, 51 say "Void"
      elseif ftranstyp = "S" .or. ftranstyp = "F"
         @ yrow, 51 say if (ftranstyp = "S", "Sale", "Force")
      else
         @ yrow, 51 say "Credit"
      endif
      f_mess (.f.)
      f_mess (.t., "Totaling " + alltrim (str (ycnt)) + " of " + ;
         alltrim (str (yreccnt)) + " Transactions ... $" ;
         + alltrim (str (ybalance - ybal)), "N/W")
      select stfil
      skip
   enddo

   yscn = f_mkbox ("Communication Port Status")

   if net_dial (.f.) <> 0
      rcccbcln ()
      return
   endif

   ymessage = tformat ("HEADER", __gcompuid, __gmerch, __gtermid, ;
      strtran (str (ybatch, 3), " ", "0"), alltrim (str (ybalance)), ;
      alltrim (str (ybal)), strtran (str (yreccnt, 3), " ", "0"))

   if snd_recv ("L1", @ymessage, @yresponse, "Header") <> 0
      rcccbcln ()
      return
   endif
   select stfil
   go top
   yrow = 12
   @ 13, 2 clear to 21, 76
   ycnt = 0
   do while .not. eof ()
      ycnt = ycnt + 1
      select racred
      go stfil->frecno
      select raloc
      seek racred->floc
      if found ()
         yrainfo = rightjust (fcity, 18, " ") + fstate
      else
         yrainfo = space (20)
      endif
      seek racred->frloc
      if found ()
         yrainfo = yrainfo + rightjust (fcity, 18, " ") + fstate
      else
         yrainfo = space (20)
      endif
      select raagrh
      seek racred->floc + str (racred->frano, 6)
      if found ()
         ydateout = fdateout
         ydatein = fdatein
         ytimeout = ftimeout
         ytimein = ftimein
         yname = rightjust (trim (ffname) + " " + flname, 20, " ")
      else
         ydateout = racred->fauthdate
         ydatein = date ()
         ytimeout = left (racred->fauthtime, 5)
         ytimein = left (time (), 5)
         yname = rightjust (trim (racred->ffname) + " " + ;
            racred->flname, 20, " ")
      endif
      if ydateout >= ydatein
         ydateout = ydatein - 1
      endif
      ydateout = strtran (dtoc (ydateout), "/", "")
      ydatein = strtran (dtoc (ydatein), "/", "")
      ytimeout = stuff (ytimeout, 3, 1, "") + "00"
      ytimein = stuff (ytimein, 3, 1, "") + "00"

      yrainfo = stuff (yrainfo, 21, 0, ydateout + ytimeout) + ;
         ydatein + ytimein + yname
      select racred
      yrainfo = "00000.00" + str (frano, 8) + yrainfo
      * 11/11/93 (edc) card or manual
      gccswipe = racred->fmname
      *
      ymessage = tformat ("DETAIL", rightjust (fccnum, 24, " "), ftranstyp, ;
         strtran (str (fauthamt, 8, 2)," ", "0"), fcctype, ;
         rightjust (fauthcode, 6, "0"), ;
         strtran (str (ycnt, 3), " ", "0"), yrainfo)
      if yrow >= 21
         scroll (13, 2, 21, 76, 1)
      else
         yrow = yrow + 1
      endif
      @ yrow, 03 say alltrim (floc) + "-" + ltrim (str (frano, 6))
      @ yrow, 21 say fccnum
      @ yrow, 42 say fauthamt picture "99999.99"
      if ftranstyp = "V"
         @ yrow, 51 say "Void"
      elseif ftranstyp = "S" .or. ftranstyp = "F"
         @ yrow, 51 say if (ftranstyp = "S", "Sale", "Force")
      else
         @ yrow, 51 say "Credit"
      endif
      f_mess (.f.)
      f_mess (.t., "Sending " + alltrim (str (ycnt)) + " of " + ;
         alltrim (str (yreccnt)) + " Transactions ...", "N/W")
      if snd_recv ("L1", @ymessage, @yresponse, "Record # " + ;
            alltrim (str (ycnt))) <> 0
         rcccbcln ()
         return
      endif
      select stfil
      skip
   enddo

   ymessage = tformat ("TRAILER", __gcompuid, __gmerch, __gtermid, ;
      strtran (str (ybatch, 3), " ", "0"), alltrim (str (ybalance)), ;
      alltrim (str (ybal)), strtran (str (yreccnt, 3), " ", "0"))
   if snd_recv ("L2", @ymessage, @yresponse, "Summary") <> 0
      rcccbcln ()
      return
   endif

   if left (alltrim (substr (yresponse, 17, 32)), 2) = "OK"
      ynewbatch = val (substr (yresponse, 2, 3))
   endif
   yresponse = alltrim (substr (yresponse, 17, 32))
   f_wtbox ("Hanging Up...")
   hangup ()
   closecomm (__gcomm)
   f_wtbox (yresponse)
   f_popup ("Press ENTER to continue...", .t.)
endif

f_rmbox (yscn)
f_mess (.f.)
f_mess (.t., "Updating Transactions, Please Wait...", "N/W")

select rasys
if left (yresponse, 2) = "OK"
   go top
   reclock ()
   if gccnet = "NDC"
      if fccbatch >= 999
         replace fccbatch with 1
      else
         replace fccbatch with max (fccbatch + 1, ynewbatch)
      endif
   else
      replace fccbatch with ynewbatch
   endif
endif

select stfil
@ 13, 2 clear to 21, 76
go top
yrow = 12
do while .not. eof ()
   ycnt = recno ()
   select racred
   go stfil->frecno
   if yrow >= 21
      scroll (13, 2, 21, 76, 1)
   else
      yrow = yrow + 1
   endif
   @ yrow, 03 say alltrim (floc) + "-" + ltrim (str (frano, 6))
   @ yrow, 21 say fccnum
   @ yrow, 42 say fauthamt picture "99999.99"
   @ yrow, 51 say "Updated"
   f_fupdate ("C")
   reclock ()
   replace fauthstat with yresponse
   if left (yresponse, 2) = "OK"
      replace frectype with __gcccap
      replace fcapamt with fauthamt
      replace fcapdate with date ()
      replace fcaptime with time ()
   endif
   replace fbatch with ybatch
   replace fitem with ycnt
   commit
   unlock
   select stfil
   skip
enddo

if left (yresponse, 2) <> "OK"
   f_valid (.f., "Warning: Batch # " + alltrim (str (ybatch, 3)) + ;
      " Is Not Captured!!!")
   inkey (10)
else
   f_valid (.f., "Batch Capture # " + alltrim (str (ybatch, 3)) + ;
      " Successfull")
endif
close databases


******************************
function rcccbcln

f_popup ("Press any key to continue...", .t.)
close databases


******************************
function rightjust

parameter xstr, xlen, xfill

xstr = trim (xstr)
return replicate (xfill, xlen - len (xstr)) + xstr

