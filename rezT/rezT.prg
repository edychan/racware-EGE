* =================================================================
* Thrifty Reservation Retrieval System - Main program
*
* Setup:
*   create h:\rezT
*   modify rez.dbf
*      FFTPPATH = h:\TWH\REZ\
*      FRESPATH = h:\REZT\RES\
*   create rezP.bat
*   create cartype.dbf
*     car code reference table (e.g. 90 = MVAR)
* changes
* 11.01.11: first time on line
*    location code = THY
* 
* ===========================================================
parameter xtick
*
private i, j, k, jctr, jfile

set delete on
* open system parameter
if .not. file ("rez.dbf") .or. .not. file("cartype.dbf")
   ?
   ? "  Missing System File..."
   ?
   ? "  Please contact Supervisor..."
   ?
   quit
endif
*
if pcount() > 0
   xtick = val(xtick)
else
   * xtick = 0           
   xtick = 300        && 5 * 60 sec.
endif
*
gloc = [THY]          && Thrifty EGE location code

* get path
use rez
gdbfpath=trim(fdbfpath)
gmempath=trim(fmempath)
gftppath=trim(fftppath)
grespath=trim(frespath)
use
*

* ---10.18.11: Build car type matrix
use cartype
gcarcode = ""
gcartype = ""
do while .not.eof()
   gcarcode = gcarcode + fcode + ";"
   gcartype = gcartype + ftype + ";"
   skip
enddo   
use
* ---

set excl off
*
ltransit = grespath + "transit.dbf"
if .not. file(ltransit)
  ytmp = gdbfpath + "tmp.dbf"
  create &ytmp
  append blank
  replace field_name with "FIELD"
  replace field_type with "C"
  replace field_len with 132
  replace field_dec with 0 
  create &ltransit from &ytmp
  use
  erase &ytmp
endif

set excl on
select 0
use &ltransit alias transit
pack
set excl off
*
do while .t.
   declare nfile[35]
   * lpat = '*.*'
   lpat = '*.REZ'            && 01.28.08: new naming convention (*.REZ)
   ltxt = gftppath + lpat
   nf=adir(ltxt,nfile)
   asort(nfile)
   nf=if(nf>35,35,nf)
   if nf > 0
      do rez_rr
   else
      ? "0 file received ..."
   endif
   * ---- 03.11.08
   * if xtick = 0
   *    exit
   * elseif inkey (xtick) = 27    && wait x sec
   *    exit
   * endif

   inkey (xtick)

   * ---- 03.11.08
enddo

close all

**************
procedure rez_rr
*
private ystr, yfld

? "Processing " + str(nf,3)+ " received files to transit ..."
*
lresdb = gdbfpath + "rares.dbf"
lres1 = gdbfpath + "rares1.ntx"
lres2 = gdbfpath + "rares2.ntx"
select 0
use &lresdb index &lres1, &lres2 alias rares
*
ltadb = gdbfpath + "raagnt.dbf"
lta1 = gdbfpath + "raagnt1.ntx"
lta2 = gdbfpath + "raagnt2.ntx"
select 0
use &ltadb index &lta1, &lta2 alias raagnt
*
yfil = gdbfpath + "racust"
yntx1 = gdbfpath + "racust1"
yntx2 = gdbfpath + "racust2"
yntx3 = gdbfpath + "racust3"
yntx4 = gdbfpath + "racust4"
select 0
use &yfil index &yntx1, &yntx2, &yntx3, &yntx4 alias racust
set order to 2    && cust # order
*
rest from (gmempath+"racust") additive
rest from (gmempath+"rares") additive
*
set excl on
select transit
pack
for i=1 to nf
  lfile = gftppath+alltrim(nfile[i])
  lfunit = fopen (lfile)
  llen = fseek (lfunit, 0, 2)   && eof (file length)
  fseek (lfunit, 0, 0)          && bof
  yfld = ""
  ystr = ""
  yptr = 0
  if ferror() = 0
     do while llen > yptr
        yptr = yptr + 1
        ystr = freadstr (lfunit, 1)
        if ystr = chr(29)     && 1d
            exit
        endif
        if ystr = chr(10) .or. ystr=chr(13)      && 0a:line feed
           if .not.empty(yfld)
              select transit
              append blank
              replace field with yfld
              yfld = ""
           endif
        else
           yfld = yfld + ystr
        endif
     enddo
  endif
  fclose (lfunit)
  copy file &lfile to (grespath+nfile[i])   && save file
  erase &lfile                              && delete file
next i
set excl off
*
? "Scanning reservations ..."

select transit
go top
l_fid = "REZ"
l_action = " "
store "" to l_fatc, f_fagent, yaddr, yaddr1, ycity, ystate, yzip
do while .not. eof()
   * parsing starts here
   lline = substr(transit->field,1,2)
   lstr = trim(transit->field)
   xstr = " "
   xpos = 4
   do case
     case lline = '01'
        ? lstr
        l_fairline = substr(lstr,62,2)
        l_fflight = substr(lstr,65,10)
        do nxtstr
        l_action = xstr
        do nxtstr
        l_fresvno = xstr
        if l_action = "A"       && Adjustment
           select rares
           seek l_fresvno
           if .not. eof ()
             f_retrieve ()
           endif
        endif
        do nxtstr
        l_floc = if(xstr=[EGE],gloc,xstr)
        do nxtstr
        if len(xstr) < 8      && return location
           l_frloc = if(xstr=[EGE],gloc,xstr)
           do nxtstr
        else
           l_frloc = l_floc
        endif
        xstr = if(xstr=[02/29/12],[02/29/2012],xstr)    && 09.01.11: leap yr
        l_fdateout = ctod(xstr)
        ? l_fdateout
        f_y2k (@l_fdateout)
        l_fdatein = l_fdateout
        do nxtstr
        if .not. empty(xstr) .and. len(xstr)<5
           ** in case: time out is not entered
           l_ftimeout = substr(xstr,1,2)+":"+substr(xstr,3,2)
           do nxtstr
           xstr = if(xstr=[02/29/12],[02/29/2012],xstr)
           l_fdatein = ctod(xstr)
        else
           xstr = if(xstr=[02/29/12],[02/29/2012],xstr)
           l_fdatein = ctod(xstr)
        endif
        ? l_fdatein
        f_y2k (@l_fdatein)
        do nxtstr
        if .not. empty(xstr)
           l_ftimein = substr(xstr,1,2)+":"+substr(xstr,3,2)
        endif
        l_fdays = if(abs(l_fdatein - l_fdateout) > 999, 0, l_fdatein - l_fdateout)
     case lline = '02'
	 * customer name: 4,33
	 * company name: 35,64
        ? lstr
        do nxtstr
        l_flname = substr (xstr,1,at("/",xstr)-1)
        l_ffname = substr (xstr,at("/",xstr)+1)
        l_fcompany = substr(lstr,35,30)
     case lline = '03'
	 * address: 4,33
	 * phone #: 35,48
        ? lstr
        l_faddr = substr(lstr,4,30)
        ystr = substr(lstr,35,14)
        ystr = strtran(ystr,"/","")
        ystr = strtran(ystr,"(","")
        ystr = strtran(ystr,")","")
        ystr = strtran(ystr,"-","")
        ystr = strtran(ystr," ","")
        if len(ystr) = 10
           l_fphone = substr(ystr,1,3)+"-"+substr(ystr,4,3)+"-"+substr(ystr,7,4)
        else
           l_fphone = ystr
        endif
     case lline = '04'
	 * address 2: 4,33 (30)
	 * city: 35,54 (20)
	 * state: 56,57 (2)
     * zip: 59,68 (10)	 
        ? lstr
        l_fcity = substr(lstr,4,20)
        l_fstate = substr(lstr,25,2)
        l_fzip = substr(lstr,28,10)
     case lline = '05'
	 * cctype: 35,36 (2)
	 * cc #  : 38,57 (20)
	 * ccexp : 59,63 (5)
        ? lstr
        l_fcctype = substr(lstr,35,2)
		l_fcctype = if(l_fcctype=[VI],[VA],l_fcctype)
        l_fccnum = substr(lstr,38,20)    
        l_fccexp = substr(lstr,59,5)
     case lline = '06'
	 * discount: 15,18 (4)
        ? lstr
        l_fdisc = val(substr(lstr,15,4))
     case lline = '07'         
	 * restrictions
     case lline = '08'  
	 * rate info:
	    ? lstr
        * l_fmthmlg = val(substr(lstr,11,4))
        * l_fmthchg = val(substr(lstr,16,13))
        * l_fmthchg = if(l_fmthchg>9999, 0, l_fmthchg)
        * l_fmthmlg = if(l_fmthmlg>9999, 0, l_fmthmlg)
        l_fwkmlg = val(substr(lstr,37,4))
        l_fwkmlg = if(l_fwkmlg>9999, 0, l_fwkmlg)
        l_fwkchg = val(substr(lstr,42,13))
        l_fwkchg = if(l_fwkchg>9999, 0, l_fwkchg)
     case lline = '09'
        l_fdlymlg = val(substr(lstr,11,4))
        l_fdlychg = val(substr(lstr,16,13))
        l_fdlymlg = if(l_fdlymlg>999, 0, l_fdlymlg)
        l_fhrchg = val(substr(lstr,42,13))
        l_fdlychg = if(l_fdlychg>999, 0, l_fdlychg)
        l_fhrchg = if(l_fhrchg>999, 0, l_fhrchg)
        *
        l_fhrchg = if(l_fhrchg>0, l_fhrchg, l_fdlychg/3)    
        * l_fdlychg = if(l_fdays=5.and.l_fwkchg>0, l_fwkchg/5, l_fdlychg)   && dollar specific???
     case lline = '10'
	 * extra day rate
        if val(substr(lstr,16,13)) > 0 .and. l_fdays > 7      
           l_fxdlychg = val(substr(lstr,16,13))
           l_fxdlychg = if(l_fxdlychg>999, 0, l_fxdlychg)
        endif
     case lline = '11'
        ? lstr
        * xstr = substr(lstr,8,5)
        xstr = substr(lstr,8,2)          && currently: carcode is 2 char long
		l_fclass = ctype(xstr)
        * l_fmlgchg = val(substr(lstr,45,10))                 && ???
        * l_fmlgchg = if(l_fmlgchg>99, 0, l_fmlgchg)
     case lline = '12'
     case lline = '13'
     case lline = '14'
     case lline = '15'
	    ? lstr
        l_fcode = substr(lstr,56,5)                         
     case lline = '16'
        ? lstr
		xstr = substr(lstr,35,8)
        if .not. empty(xstr)
           l_fatc = xstr
           l_fagent = substr(lstr,4,30)
        endif
     case lline = '17'
	    if .not. empty(l_fatc)
           ? lstr
           yaddr = alltrim(substr(lstr,4,30))
		endif
     case lline = '18'
	    if .not. empty(l_fatc)
           ? lstr
           yaddr1 = alltrim(substr(lstr,4,30))
           ycity = substr(lstr,35,20)
           ystate = substr(lstr,56,2) 
           yzip = substr(lstr,59,10)
		endif
     case lline = '19'
        ? lstr
        l_fcustno = substr(lstr,4,10)         && profile #
        l_fcinsur1 = substr(lstr,17,30)       && driver lic #
        l_fshop = substr(lstr,48,2)           && lic state
        l_fcexp1 = ctod (substr(lstr,57,2)+'/'+ ;
          substr(lstr,59,2)+'/'+substr(lstr,61,2))
        f_y2k (@l_fcexp1)                     && dob
        l_fexp1 = ctod (substr(lstr,57,2)+'/'+ ;
          substr(lstr,59,2)+'/'+substr(lstr,54,2))
        f_y2k (@l_fexp1)                      && expiration
        if .not. empty(l_fcustno)             && set up for customer file
           l_flic = l_fcinsur1
           l_flicst = substr(l_fshop,1,2)
           l_fbirthdt = l_fcexp1
           l_fexpdt = l_fexp1
        endif
     case lline = '20'
     case lline = '21'
     case lline = '22'
     case lline = '23'
     case lline = '24'               && 08.16.11: get email address
	    ? lstr
		l_fremark1 = substr(lstr,4,60)
     case lline = '25'
	    ? lstr
		l_fremark2 = substr(lstr,4,60)
        *
     case lline = '26'           
     case lline = '27'           
        ? lstr
        xstr = substr(lstr,13,8)
        xstr = if(xstr=[02/29/12],[02/29/2012],xstr)
        if l_action = "R"       && New res
           l_fbookdate = ctod(xstr)
           f_y2k(@l_fbookdate)
		elseif l_action = "C"    && cancel
		   l_fcxldate = ctod(xstr)
		   f_y2k(@l_fcxldate)
		endif   
        * start process res here ...
        if  .not. empty (l_fresvno)
		   select rares
           seek l_fresvno
           if l_action = "C"       && cancel
              if found ()
                rlock ()
                * replace fdatein with date()     
                replace fcxldate with l_fcxldate     
                replace fresvstat with "C"
                commit
                unlock
              endif
            else
              l_fresvstat = "O"
              if l_fhrchg >= 100                && 12.18.06:
                 l_fhrchg = 99.99
              endif
              if eof ()
                append blank
              else
                rlock()
              endif
              f_replace ()
            endif
            if .not. empty(l_fcustno)
               select racust
               seek l_fcustno
               if eof ()
                 append blank
               else
                 rlock()
               endif
               f_replace ()
             endif
            * handle travel agent info.
            if .not. empty (l_fatc)
               select raagnt
               seek l_fatc
               if eof()
                  append blank
               else
                  rlock()
               endif
               replace fatc with l_fatc, fcompany with l_fagent
               replace faddr with yaddr, faddr1 with yaddr1, fcity with ycity
               replace fstate with ystate, fzip with yzip
               replace fres with fres+1, factdt with l_fbookdate
               replace fmoddt with date()
               commit
               unlock
               store " " to yaddr, yaddr1, ycity, ystate, yzip
            endif
         endif
         rest from (gmempath+"racust") additive
         rest from (gmempath+"rares") additive
         l_fid = "REZ"
         l_action = " "
         store "" to l_fatc, f_fagent, yaddr, yaddr1, ycity, ystate, yzip
   endcase
   select transit
   delete
   skip
enddo        
select rares
use
select raagnt
use
select racust
use
? "Process completed..."

***************************
* - gcartype = '90;93,97;UU;...'
* - gcartype = 'MVAR ;CCAR ;FCAR ;XXAR ;...
function ctype
parameter xstr
private y1 

y1 = at(xstr, gcarcode)
if y1 = 1
   return (substr(gcartype,1,5))
elseif y1 > 0
   return (substr(gcartype, (int((y1-1)/3) * 6) + 1, 5))   && if code = 97 => type = ((7-1)/3) * 6 + 1 = 13 
else
   return (xstr)
endif
   
***************************
procedure nxtstr

if xpos > len(lstr)
   xstr = ""
   return 
endif

xpos = nxtchr (lstr, xpos)
xstr = getstr (lstr, xpos)
xpos = xpos + len(xstr)
xpos = nxtchr (lstr, xpos)
return
***************************
function getstr

parameter xstr, xpos
private y1

y1 = at(" ",substr(xstr,xpos))
if y1 > 0
   return (substr(xstr,xpos,y1-1))
else
   return (substr(xstr,xpos))
endif
*****************************
function nxtchr

parameter xstr, xpos

do while substr(xstr,xpos,1) = " " 
   xpos = xpos + 1
enddo

return (xpos)

***********************
* convert date to year2000 format
* pass by reference
function f_y2k
parameter xdate
if year (xdate) <= 1920   
   ydate = dtoc(xdate)
   xdate = ctod(substr(ydate,1,6)+"20"+substr(ydate,7,2))
endif
return .t.

*******************************
function f_replace

private xfld, xlfld, n

rlock ()
for n = 1 to fcount ()
   xfld = field (n)
   xlfld = "L_" + xfld
   replace &xfld with &xlfld
next
commit
unlock

******************************
function f_retrieve

private xfld, xlfld, n

for n = 1 to fcount ()
   xfld = field (n)
   xlfld = "L_" + xfld
   &xlfld = &xfld
next

******************************
function f_clrscn

parameters xtitle
private yr1, yc1, yr2, yc2

setcolor (gbluecolor)
blimempak (-1)
for n = 1 to 10
   yr1 = 12 + round (-1.2 * n, 0)
   yc1 = 40 + round (-4.0 * n, 0)
   yr2 = 12 + round (1.2 * n, 0)
   yc2 = 40 + round (3.9 * n, 0)
   if type ("gboxsav [n]") = "L"
      gboxsav [n] = savescreen (yr1, yc1, yr2, yc2)
   endif
   @ yr1, yc1 clear to yr2, yc2
next
blimempak (-1)
setcolor (gredcolor)
@ 00, 00
@ 24, 00
if pcount () >= 1
   @ 00, 40 - int (len (xtitle) / 2) say xtitle
endif

setcolor (gbluecolor)

******************************
function f_confirm

parameters xmessage, xopt
private xocolor, xpick, xkeyin, yscn, ycursor

ycursor = iscursor ()

blimempak (-1)
yscn = savescreen (24, 00, 24, 79)
xocolor = setcolor (gredcolor)

@ 24, 00
xkeyin = 0
xpick = " "
@ 24, 01 say trim (xmessage) + "........ [ ]"
set cursor on
@ 24, len (trim (xmessage)) + 10 say "["
do while .t.
   xkeyin = f_getkey ()
   if xkeyin >= 32 .and. xkeyin <= 127
      xpick = upper (chr (xkeyin))
      @ 24, len (trim (xmessage)) + 11 say xpick
      @ 24, len (trim (xmessage)) + 11 say ""
      if xpick $ xopt
         exit
      endif
      tone (500, 9)
   endif
enddo
@ 24, 00
setcolor (xocolor)
blimempak (-1)
restscreen (24, 00, 24, 79, yscn)
blimempak (-1)
if ycursor
   set cursor on
else
   set cursor off
endif
return xpick

******************************
function f_getkey

clear typeahead
return inkey (0)

******************************
function nextrec

parameter xval

return left (xval, len (xval) - 1) + chr (asc (right (xval, 1)) + 1)

******************************
function f_truncate

parameters xstr, xlen

return left (xstr + replicate (" ", xlen), xlen)


