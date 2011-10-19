*
* PARSE PROGRAM
*
* 12.08.97 
* read line 12 for additional rate info
* 12.28.99
* read line 01 for return location (can be empty if floc=frloc)
* 12.17.01: phone fomrat for internet res
* 01.02.02: rate calc.
*
f_popup ("Scanning reservations ...")

lresdb = grespath + "rares.dbf"
lres1 = grespath + "rares1.ntx"
lres2 = grespath + "rares2.ntx"
if .not. file (lresdb) .or. .not. file(lres1) .or. .not. file(lres2)
  f_popup ("Connection Lost -> Press any key to continue ...",.t.)
  lerr = .t.
  return
else
  select 50
  use &lresdb index &lres1, &lres2 alias rares
endif  

ltadb = grespath + "raagnt.dbf"
lta1 = grespath + "raagnt1.ntx"
lta2 = grespath + "raagnt2.ntx"
if .not. file (ltadb) .or. .not. file(lta1) .or. .not. file(lta2)
  f_popup ("Connection Lost -> Press any key to continue ...",.t.)
  lerr = .t.
  return
else
  select 51
  use &ltadb index &lta1, &lta2 alias raagnt
endif  

* handle rac comm here
lsup = .f.
xfil = gsuppath + "RARES.DBF"
xntx = gsuppath + "RARES.NTX"

if file (xfil) .AND. file (xntx)
   lsup = .t.
   select 52
   use &xfil index &xntx  alias supres
endif

ltransit = gdbfpath+"transit"
select 53
use &ltransit excl alias transit
go top

rest from (gmempath+"rares") additive
l_fid = "REZ"
l_action = " "
yaddr = ""
yaddr1 = ""
ycity = ""
ystate = ""
yzip = ""

do while .not. eof()

   * parsing starts here
   lline = substr(transit->field,1,2)
   lstr = trim(transit->field)
   xstr = " "
   xpos = 4
   do case
     case lline = '01'
        ? lstr
        do nxtstr
        l_action = xstr
        do nxtstr
        l_fresvno = xstr
        * do not overwrite old info. with new info.
        if l_action = "A"       && Adjustment
           select rares
           seek l_fresvno
           if .not. eof ()
             f_retrieve ()
           endif
        endif
        do nxtstr
        l_floc = xstr
        * 12.28.99
        do nxtstr
        if len(xstr) < 8      && return location
           l_frloc = xstr
           do nxtstr
        else
           l_frloc = l_floc
        endif
        xstr = if(xstr=[02/29/00],[02/29/2000],xstr)
        l_fdateout = ctod(xstr)
        ? l_fdateout
        f_y2k (@l_fdateout)
        l_fdatein = l_fdateout
        do nxtstr
        if .not. empty(xstr) .and. len(xstr)<5
           ** in case: time out is not entered
           l_ftimeout = substr(xstr,1,2)+":"+substr(xstr,3,2)
           do nxtstr
           xstr = if(xstr=[02/29/00],[02/29/2000],xstr)
           l_fdatein = ctod(xstr)
        else
           xstr = if(xstr=[02/29/00],[02/29/2000],xstr)
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
        ? lstr
        do nxtstr
        l_flname = substr (xstr,1,at("/",xstr)-1)
        l_ffname = substr (xstr,at("/",xstr)+1)
     case lline = '03'
        ? lstr
        do nxtstr
        if .not. empty(xstr)
           * 12.17.01: internet format 123-123-1234
           if len(xstr) > 5
              l_fphone = xstr
           else
           * 12.17.01: reg. format (123) 123-1234
              l_fphone = substr(xstr,2,3)
              do nxtstr
              l_fphone = l_fphone + "-" + xstr
           endif
        endif
     case lline = '04'
        ? lstr
        l_fairline = substr(lstr,35,2)
        l_fflight = strtran(substr(lstr,37),"/","")
     case lline = '05'
     case lline = '06'
     case lline = '07'          && credit card info.
        ? lstr
        do nxtstr
        l_fcctype = if (empty(xstr), l_fcctype, xstr)
        do nxtstr
        yfccnum = ""
        do while .not. empty (xstr)
           if at("/",xstr) > 0
              l_fccexp = xstr
           else
              yfccnum = yfccnum + xstr
           endif
           do nxtstr
        enddo
        l_fccnum = if (empty(yfccnum), l_fccnum, strtran(yfccnum,"-",""))
     case lline = '08'
     case lline = '09'
        ? lstr
        do nxtstr
        l_fclass = xstr
        do nxtstr
        l_fcode = xstr
     case lline = '10'
        ? lstr
        l_fmlgchg = val(substr(lstr,13,8))
        l_fmthchg = val(substr(lstr,23,8))
        l_fwkchg = val(substr(lstr,32,8))
        l_fdlychg = val(substr(lstr,50,8))
        l_fdlychg = if(l_fdlychg>0, l_fdlychg, val(substr(lstr,42,8)))      && 01.19.98 edc
        l_fhrchg = val(substr(lstr,59,8))
        * add'l check for numeric overflow 12.02.99
        l_fmlgchg = if(l_fmlgchg>99, 0, l_fmlgchg)
        l_fmthchg = if(l_fmthchg>9999, 0, l_fmthchg)
        l_fwkchg = if(l_fwkchg>9999, 0, l_fwkchg)
        l_fdlychg = if(l_fdlychg>999, 0, l_fdlychg)
        l_fhrchg = if(l_fhrchg>99, 0, l_fhrchg)
        *
        l_fhrchg = if(l_fhrchg>0, l_fhrchg, l_fdlychg/3)    && 05/05/94 edc
        * 01.02.02
        l_fdlychg = if(l_fdays=5.and.l_fwkchg>0, l_fwkchg/5, l_fdlychg)
     case lline = '11'
        ? lstr
        l_fmthmlg = val(substr(lstr,23,8))
        l_fwkmlg = val(substr(lstr,32,8))
        l_fdlymlg = val(substr(lstr,50,8))  
        * add'l check for numeric overflow 12.02.99
        l_fmthmlg = if(l_fmthmlg>9999, 0, l_fmthmlg)
        l_fwkmlg = if(l_fwkmlg>9999, 0, l_fwkmlg)
        l_fdlymlg = if(l_fdlymlg>999, 0, l_fdlymlg)  

     case lline = '12'
        * 12.08.97
        ? lstr
        if l_fhrchg <= 0
           l_fhrchg = val(substr(lstr,14,8))
           l_fhrchg = if(l_fhrchg>999, 0, l_fhrchg)
        endif
        if l_fdlychg <= 0
           l_fdlychg = val(substr(lstr,32,8))
           l_fdlychg = if(l_fdlychg>999, 0, l_fdlychg)
        endif
        l_fhrchg = if(l_fhrchg>0, l_fhrchg, l_fdlychg/3)   
     case lline = '13'
     case lline = '14'
     case lline = '15'
     case lline = '16'
     case lline = '17'
        ? lstr
        l_fremark1 = substr(lstr,4)
     case lline = '18'
        ? lstr
        l_fremark2 = substr(lstr,4)
     case lline = '19'
     case lline = '20'
        ? lstr
        xpos = 35
        do nxtstr
        if .not. empty (xstr)
           l_fatc = xstr
           l_fagent = substr(lstr,4,30)
        endif
     case lline = '21'
        ? lstr
        yaddr = alltrim(substr(lstr,4,30))
     case lline = '22'
        ? lstr
        yaddr1 = alltrim(substr(lstr,4,30))
     case lline = '23'
        ? lstr
        ycity = substr(lstr,4,20)
        ystate = substr(lstr,25,2) 
        yzip = substr(lstr,28,10)
     case lline = '24'
     case lline = '25'
        ? lstr
        do nxtstr
        do nxtstr
        xstr = if(xstr=[02/29/00],[02/29/2000],xstr)
        l_fbookdate = ctod (xstr)
        f_y2k (@l_fbookdate)
        *
        if  .not. empty (l_fresvno)
           select rares
           seek l_fresvno
           if l_action = "C"       && cancel
              if found ()
                reclock ()
                replace fdatein with date()     && 10.23.01 cancellation date
                replace fresvstat with "C"
                commit
                unlock
              endif
            else
              l_fresvstat = "O"
              if eof ()
                append blank
              else
                reclock()
              endif
              f_replace ()
              * handle rac comm here
         
              if lsup
                select supres
                l_fupdate = "A"
                seek space (10)
                fnd = .f.
                do while .not. eof () .and. empty (fresvno)
                   if rlock ()
                      fnd = .t.
                      exit
                   else
                      skip
                   endif
                enddo
                if .not. fnd
                   append blank
                endif
                f_replace ()
              endif
              *
            endif
            * handle travel agent info.
            if .not. empty (l_fatc)
               select raagnt
               seek l_fatc
               if eof()
                  append blank
               else
                  reclock()
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

         rest from (gmempath+"rares") additive
         l_fid = "REZ"
         l_action = " "
   endcase
   select transit
   delete
   skip
enddo        

close all
f_popback()

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

function getstr

parameter xstr, xpos

y1 = at(" ",substr(xstr,xpos))
if y1 > 0
   return (substr(xstr,xpos,y1-1))
else
   return (substr(xstr,xpos))
endif

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
