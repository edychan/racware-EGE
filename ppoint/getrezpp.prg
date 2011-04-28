* =======================================================
* getrezpp - output res data (txt) for powerpoint app
*
* 12.18.08.
* 01.22.09: +3 hr look ahead
* 01.28.09: set display ndisplay = 20
* =======================================================
parameter xtick
set delete on
set excl off

if pcount() > 0
   xtick = val(xtick)
else
   xtick = 3600        && 60 * 60 sec.
endif
 
* --get path
gdbfpath = "h:\racware\dbf\"
goutpath = ""
* --

ndisplay = 20

ltransit = "ppout.dbf"
if .not. file(ltransit)
  ytmp = gdbfpath + "tmp.dbf"
  create &ytmp
  append blank
  replace field_name with "FLNAME"
  replace field_type with "C"
  replace field_len with 25
  replace field_dec with 0 
  append blank
  replace field_name with "FFNAME"
  replace field_type with "C"
  replace field_len with 25
  replace field_dec with 0 
  append blank
  replace field_name with "FTIME"
  replace field_type with "C"
  replace field_len with 5
  replace field_dec with 0 

  create &ltransit from &ytmp
  use
  erase &ytmp
endif

select 0
use &ltransit excl alias transit
* ytmp = "ppout.ntx"
* index on flname+ffname to &ytmp

do while .t.     && forever loop

   do rez_pp

   inkey (xtick)

enddo

close all

* ==============================================================
procedure rez_pp

xdate = date()                      &&
* xhr = val(substr(time(),1,2)) + 3   && +3 hr look ahead 

? dtos(xdate)+":"+time()+">>"+"Processing rez to transit ..."

select transit                      &&
zap

lresdb = gdbfpath + "rares.dbf"
* -- lresntx = gdbfpath + "rares3.ntx"     && order = dateout
lresntx = gdbfpath + "rares2.ntx"     && order = status
select 0
use &lresdb index &lresntx alias rares
* --seek xdate
seek [O]

if eof ()
   return
endif

* -- do while fdateout = xdate

do while fresvstat = [O]
   * -- if rares->fresvstat = [O]
   if rares->fdateout = xdate                && .and. xhr - val(substr(rares->ftimeout,1,2)) >= 0
     if .not. rares->fairline $ [PI;PP;PA]   && 02.02.09 (per eric) 
      select transit
      append blank
      replace flname with rares->flname, ffname with rares->ffname
      replace ftime with rares->ftimeout    && 01.28.09
      commit
      unlock
     endif
   endif

   select rares
   skip

enddo

select rares
use

* --01.28.09: set display to 20 (sort by time first)
select transit
if reccount() > ndisplay
   index on ftime to xxx
   go top
   for i = 1 to ndisplay
      skip
   next
   do while .not. eof()
      delete
      skip
   enddo
   pack
endif

index on flname+ ffname to xxx
* --

* -- output file
? "Creating Rez Listing ..."

yfil = goutpath + "pplist.txt"
set device to print
set printer to &yfil
setprc (0,0)

* write header
yln = 0
ychr = chr(9)
select transit
go top
do while .not. eof ()
   yfld = ""
   for i = 1 to 2
      yfld = yfld + trim(flname) + ychr + trim(ffname) + ychr
      skip
   next i
   @yln, 0 say yfld
   yln = yln + 1
enddo

set printer to
set console on
set print off
set device to screen

? "Process completed.. "

