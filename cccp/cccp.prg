* ===========================================================================
* credit card processing: capture batch
* 05.15.07: standalone module
* ===========================================================================
parameter xloc, xdbr

public gstation, gdbfpath, gstnpath, gccnet
public __gccunauth, __gccauth, __gccuncap, __gcccap, __gccautherr
public __gccspecauth, __gccadj
public __ginitstr, __gmodem, __gcomm, __gbaud, __gparity, __gstopbit
public __gdatabit, __gxbuff, __grbuff, __gtimeout, __gname, __gaddr, __gcity
public __gstate, __gzip, __gcountry, __gcash, __gccsale, __gccforce
public __gccvoid, __gcccredit, __gccunauth, __gccauth, __gccuncap
public __gcccap, __gccautherr, __gccspecauth
public __gplanno, __gcompany, __gprefix, __gstore, __gica
public __gmerch, __gtermid, __gserial, __gamex, __gamexph1, __gamexph2
public __gcompuid, __gcompuph, __gphone, gaxbaud

private yresponse, ybatch, ynewbatch, yerror, ybalance, yreccnt, yscn, yrow
private ydetail, ybalance, ybal, yvoids, ydbr
private yterm_id, ymessage, yamexdial, ycnt, yloc
private y1, y2, y3, y4, y5

set exclusive off
set delete on
set exact off
set confirm on
set scoreboard off
set cursor off
set century off
set key 28 to
set key -1 to
set key -2 to

clear
if .not. file("cccp.dbf")
   ?
   ? "  Missing System File..."
   ?
   quit
endif

use cccp
gloc = floc
gstation = alltrim(fstation)
gdbfpath = alltrim(fdbfpath)
gstnpath = alltrim(fstnpath)
gcclog = fcclog
gdbrno = fdbrno
gccnet = alltrim(fccnet)
use

if pcount () = 0
   ydbr = 0
   yloc = gloc
   @ 03, 05 say "Enter Location: " get yloc pict "!!!!!!!!!!"
   @ 04, 05 say "      DBR #   : " get ydbr pict "9999" valid ydbr > 0 
   if f_rd () = 27
      return
   endif
else
   yloc = xloc
   ydbr = val(xdbr)
endif

__gccunauth = 1
__gccauth = 2
__gccuncap = 3
__gcccap = 4
__gccautherr = 5
__gccspecauth = 6
__gccadj = 7

if .not. getccsetup (yloc)
   ? "Invalid CC setup ..."
   inkey (0)
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

? "Counting Transactions..."

set delete on

*f_use ("RASYS")
yfil = gdbfpath + "rasys"
select 0
use &yfil alias rasys

*f_use ("RALOC")
yfil = gdbfpath + "raloc"
select 0
use &yfil index &yfil alias raloc

*f_use ("RAAGRH")
yfil = gdbfpath + "raagrh"
y1 = gdbfpath + "raagrh1"
y2 = gdbfpath + "raagrh2"
y3 = gdbfpath + "raagrh3"
y4 = gdbfpath + "raagrh4"
select 0
use &yfil index &y1, &y2, &y3, &y4 alias raagrh

*f_use ("RACRED", 4)
yfil = gdbfpath + "racred"
y1 = gdbfpath + "racred1"
y2 = gdbfpath + "racred2"
y3 = gdbfpath + "racred3"
y4 = gdbfpath + "racred4"
y5 = gdbfpath + "racred5"
select 0
use &yfil index &y1, &y2, &y3, &y4, &y5 alias racred
set order to 4

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
seek yloc + str (ydbr, 4)
ycnt = 0
do while .not. eof () .and. fdbrno = ydbr .and. frloc = yloc
   ycnt = ycnt + 1
   yrecno = recno ()
   select stfil
   append blank
   * f_wtbox ("Counting Transaction... # " + alltrim (str (ycnt)))
   replace frecno with yrecno
   commit
   select racred
   skip
enddo
set softseek off

select stfil
yreccnt = reccount ()
if yreccnt = 0
   ? "No Transactions To Capture... "
   rcccbcln ()
   return
endif

? "Totaling Of The " + alltrim (str (yreccnt)) + ;
   " Transactions ..."

select rasys
go top
if fccbatch <= 0
   ybatch = 1
else
   ybatch = fccbatch
endif
ynewbatch = ybatch + 1

yrow = 12
if gccnet = "LPA"       && must be LPA network
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
      ? str(frano,6)+" "+fccnum+" "+str(fauthamt,10,2)
      select stfil
      skip
   enddo

   yscn = f_mkbox ("Communication Port Status")

   if net_dial (.f.) <> 0
      rcccbcln ()
      return
   endif

   ymessage = tformat ("HEADER1", __gcompuid, __gmerch, __gtermid, ;
      strtran (str (ybatch, 3), " ", "0"), alltrim (str (ybalance)), ;
      alltrim (str (ybal)), strtran (str (yreccnt, 3), " ", "0"))
   if snd_recv ("H1", @ymessage, @yresponse, "Header1") <> 0
      rcccbcln ()
      return
   endif
   ymessage = tformat ("HEADER2", __gcompuid, __gmerch, __gtermid, ;
      strtran (str (ybatch, 3), " ", "0"), alltrim (str (ybalance)), ;
      alltrim (str (ybal)), strtran (str (yreccnt, 3), " ", "0"))
   if snd_recv ("L1", @ymessage, @yresponse, "Header2") <> 0
      rcccbcln ()
      return
   endif

   select stfil
   go top
   yrow = 12
   ycnt = 0
   do while .not. eof ()
      ycnt = ycnt + 1
      select racred
      go stfil->frecno
      select raloc
      seek racred->floc
      if found ()
         yrainfo = f_truncate (fcity, 18) + fstate
      else
         yrainfo = space (20)
      endif
      seek racred->frloc
      if found ()
         yrainfo = yrainfo + f_truncate (fcity, 18) + fstate
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
         * yname = rightjust (trim (ffname) + " " + flname, 20, " ")
         yname = f_truncate (trim (ffname) + " " + flname, 20)
      else
         ydateout = racred->fauthdate
         ydatein = date ()
         ytimeout = left (racred->fauthtime, 5)
         ytimein = left (time (), 5)
         * yname = rightjust (trim (racred->ffname) + " " + racred->flname, 20, " ")
         yname = f_truncate (trim (racred->ffname) + " " + racred->flname, 20)
      endif
      if ydateout >= ydatein
         ydateout = ydatein - 1
      endif
      ydateout = strtran (dtoc (ydateout), "/", "")
      ydatein = strtran (dtoc (ydatein), "/", "")
      ytimeout = stuff (ytimeout, 3, 1, "") + "00"
      ytimein = stuff (ytimein, 3, 1, "") + "00"

      yrainfo = stuff (yrainfo, 21, 0, ydateout + ytimeout) + ;
                ydatein + ytimein + ;
                yname + ;
                [000000]
      select racred
      * yrainfo = extra amt    (X8)
      *           ra #         (X8)
      *           rental city  (X18)
      *           rental state (X2)
      *                  date  (MMDDYY)
      *                  time  (HHMMSS)
      *           return city  (X18)
      *                  date  (MMDDYY)
      *                  time  (HHMMSS)
      *           renter name  (X20)
      *           xtra charge  (X6) [000000] always
      yrainfo = "00000.00" + f_truncate (alltrim(str(frano, 6)), 8) + yrainfo
      * 11/11/93 (edc) card or manual
      gccswipe = racred->fmname
      *
      * ymessage = tformat ("DETAIL", rightjust (fccnum, 24, " "), ftranstyp, ;
      *    strtran (str (fauthamt, 8, 2)," ", "0"), fcctype, ;
      *    rightjust (fauthcode, 6, "0"), ;
      *    strtran (str (ycnt, 3), " ", "0"), yrainfo)
      ymessage = tformat ("DETAIL", fccnum, ftranstyp, ;
         alltrim (str (fauthamt, 8, 2)), fcctype, ;
         rightjust (fauthcode, 6, "0"), ;
         strtran (str (ycnt, 3), " ", "0"), yrainfo,  ;
         strtran (fccexp, "/", ""),  ;
         strtran (substr(fauthstat,10,3), " ", "0"))            

      ? str(frano,6) + " " + fccnum + " " + str(fauthamt,10,2)
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

   yresponse = alltrim (substr (yresponse, 29, 32))
   f_wtbox ("Hanging Up...")
   hangup ()
   closecomm (__gcomm)
   f_wtbox (yresponse)
endif

f_rmbox (yscn)
? " Please wait while updating Transactions..."
select rasys
if left (yresponse, 2) = "OK"
   go top
   rlock ()
   replace fccbatch with if(fccbatch >= 999, 1, fccbatch + 1)
endif

select stfil
go top
yrow = 12
do while .not. eof ()
   ycnt = recno ()
   select racred
   go stfil->frecno
   ? "Updating "+str(frano,6)
   rlock ()
   replace fremark with yresponse     && 06.02.99 move to remark
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

if left (yresponse, 2) = "OK" 
   ? "Batch Capture # " + alltrim (str (ybatch, 3)) + ;
      " Successfull"
else
   ? "Warning: Batch # " + alltrim (str (ybatch, 3)) + ;
      " Is Not Captured!!!"
endif

inkey (0)
close all

******************************
function rcccbcln

inkey (0)
close data


******************************
function rightjust

parameter xstr, xlen, xfill

xstr = trim (xstr)
return replicate (xfill, xlen - len (xstr)) + xstr

