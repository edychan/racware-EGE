* ===============================================
* Dollar EGE internet rate processing module
*
* 12.12.06: add xdays parameter
* 06.19.08: add LOC parameter
* 06.23.08: CRSRatePlan change from [D] to [JACCD] & [W] to [JACCW]   
*
* 12.17.08: cdw chage to 34.95 per alan
* -----------------------------------------------
* 07.23.09: For ege, add [JC] to mirror [VALUE]
*           except JC is 125% of VALUE
* 12.03.09: Add 3rd parameter
*           xfactor::=multiplier for [JC] rate
* -----------
* 10.03.11: change [EGE]/[VALUE] to [   ]/[VALUE]; so Thrifty RAC uses the same VALUE rate
* 
* ===============================================
parameters xloc, xdays, xfactor
set excl off
set delete on
clear

yfactor = 1.25       && default is 125%

if pcount() < 2
   ?
   ?
   ? "Usage: IREZ EGE 180 1.25"
   ?
   ?
   quit

* --12.03.09
elseif pcount () = 3
   yfactor = val(xfactor)
* --

endif

* -- for debug 
* ? yfactor*2
* inkey(0)
* --

xloc = upper(xloc)
if .not. xloc $ [EGE;JAC]
   ?
   ? "Invalid Location ..."
   ?
   quit
endif

xdays = val(xdays)
xdate = date() + xdays

* xdbfpath = ""     && debugg only **
xdbfpath = "h:\racware\dbf\"
xrezpath = ""

? "Dollar "+trim(xloc)+" internet rate processing "+time()
*
yfil = "itransit.dbf"
if .not. file (yfil)
   ytmp = "tmp.dbf"
   create &ytmp
   append blank
   replace field_name with "FIELD"
   replace field_type with "C"
   replace field_len with 150
   replace field_dec with 0 
   create &yfil from &ytmp
   use
   erase &ytmp
endif
*
if xloc = [EGE]
   * xloc = [EGE       ]  && index key length = 10
   xloc = space(10)     && 10.03.11: => Thrifty RAC uses the same VALUE rate
   xcode = [VALUE ]     && index key length = 6
   * xcdwchg = 29.95      && per allen
   xcdwchg = 34.95      && 12.17.08
else
   xloc = [JAC       ]  && index key length = 10
   xcode = [VALUE ]     && index key length = 6
   xcdwchg = 34.95      && per allen
endif
*
yfil = xrezpath + "irez.txt"
if file (yfil)
   do pr_irez with yfil
else
  ? "Skip: Missing data file (irez.txt) "
endif
*
? "Internet rate Update Completed "+time()
* inkey(5)
?

close all
return

********************
procedure pr_irez
parameter xfile

select 0
set excl on
use itransit alias transit
zap
set excl off

* append data
append from &xfile sdf

erase &xfile

* open data file
ypath = xdbfpath
yfil = ypath + "RARTM"
select 0
use &yfil index &yfil alias rartm
*
ydata = ""
select transit
go top
locate for [z:row] $ field
do while .not. eof ()
   xfield = upper(field)
   do case
   case [/RS:DATA] $ xfield                         && end of data
      exit
   case [Z:ROW] $ xfield .and. .not.empty(ydata)    && new row
      yrectype = rrget ([CRSRATEPLAN],ydata)
      yclass = rrget ([CRSCARTYPE],ydata)
      yclass = f_truncate(yclass, 4)
      ystr = rrget ([STARTDATE],ydata)
      ydatefrom = ctod (substr(ystr,6,2)+"/"+substr(ystr,9,2)+"/"+substr(ystr,1,4))
      * For now dayto and dayfrom should be the same
      * ystr = rrget ([ENDDATE],ydata)
      * ydateto = ctod (substr(ystr,6,2)+"/"+substr(ystr,9,2)+"/"+substr(ystr,1,4))

      * 12.12.06:
      if ydatefrom >= xdate
         exit
      endif

      * -- 06.19.08: rateplan change from [D] to [JACCD]; [W] to [JACCW] 
      yrectype = substr(yrectype,len(yrectype),1)
      if yrectype = [D]
         ystr = rrget ([ RATE],ydata)              && leave as [ RATE]
         ydlychg = val(ystr)
         yhrchg = ydlychg / 3
         yhrchg = if(yhrchg > 99.99,99.99,yhrchg)  && 12.15.06
         ystr = rrget ([DISTANCEALLOWANCE],ydata)
         ydlymlg = val (ystr)
      else
         ystr = rrget ([ RATE],ydata)
         ywkchg = val (ystr)
         ystr = rrget ([DISTANCEALLOWANCE],ydata)
         ywkmlg = val (ystr)
      endif

      * ? "<:-"+dtos(ydatefrom)+" "+yclass

      * update RARTM
      select rartm
      seek xcode+xloc+yclass+dtos(ydatefrom)
      if eof ()
         append blank
         replace fcode with xcode, floc with xloc, fclass with yclass 
         replace fdatefrom with ydatefrom, fdateto with ydatefrom
         replace fcdwchg with xcdwchg
      else
         rlock ()
      endif
      if yrectype = [D]
         replace fdlychg with ydlychg, fdlymlg with ydlymlg, fhrchg with yhrchg
      else
         * 06.28.10: check for numeric overflow
         replace fwkchg with if(ywkchg>9999,9999,ywkchg), fwkmlg with ywkmlg
      endif
      commit
      unlock

      * --07.23.09: add [JC] = 125% of [VALUE] for EGE only
      if empty(xloc)       && 10.03.11: => Thrifty use same [JC] rate
      * if xloc = [EGE]

      x1code = [JC]+space(4)
      select rartm
      seek x1code+xloc+yclass+dtos(ydatefrom)
      if eof ()
         append blank
         replace fcode with x1code, floc with xloc, fclass with yclass 
         replace fdatefrom with ydatefrom, fdateto with ydatefrom
         replace fcdwchg with xcdwchg
      else
         rlock ()
      endif
      if yrectype = [D]
         replace fdlychg with (yfactor*ydlychg), fdlymlg with ydlymlg, fhrchg with yfactor*yhrchg
      else
         * 06.28.10: check numeric overflow
         replace fwkchg with if(yfactor*ywkchg>9999,9999,yfactor*ywkchg), fwkmlg with ywkmlg
      endif
      commit
      unlock

      endif
      * --07.23.09

      ydata = xfield

   otherwise
      ydata = ydata + xfield
   endcase
   
   select transit
   skip
enddo

return

************************
function rrget
parameter xkey, xdata

private yfld

yfld = ""
ylen = len(xkey)

ypos = at(xkey, xdata)
if ypos > 0
   ystart = ypos + ylen + 2     && CRSCarType='CCAR'
   yend = at(['], substr(xdata,ystart)) - 1
   yfld = substr(xdata, ystart, yend)
endif

*? xkey + "->" + xdata
*? str(ypos,3)+" "+str(ystart,3)+" "+str(yend,3)+" "+yfld
*inkey (0)

return (yfld)


*********************
function f_truncate

parameters xstr, xlen

return left (xstr + replicate (" ", xlen), xlen)


