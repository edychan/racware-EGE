* 
* Reservation Retrieval System - Re-process 
*
f_clrscn ("Reservation Retreival System")

f_box (03, 10, 05, 50)

ldate = date ()
do while .t.
  @ 04, 16 say "Date ....... " get ldate
  if f_rd () = 27
    return
  endif
  if f_confirm ("Is this correct? [Y/N] ","YN") = "Y"
    exit
  endif
enddo

declare nfile[35]
ldate = dtoc(ldate)
lpat = substr(ldate,1,2)+substr(ldate,4,2)+"*."
ltxt = gdbfpath + lpat

nf=adir(ltxt,nfile)
if nf <= 0
  f_popup ("No Reservation Found ...",.t.)
		return
endif

asort(nfile)
nf=if(nf>35,35,nf)

SET EXCL ON
ltransit = gdbfpath + "transit.dbf"
if .not. file(ltransit)
  ytmp = gdbfpath + "tmp.dbf"
  create &ytmp
  append blank
  replace field_name with "FIELD"
  replace field_type with "C"
  replace field_len with 700
  replace field_dec with 0 
  create &ltransit from &ytmp
  use
  erase &ytmp
endif

select 1
use &ltransit
pack
use

for i=1 to nf
  lfile = gdbfpath+alltrim(upper(nfile[i]))
  if file (lfile)
     lfunit = fopen (lfile)
     llen = fseek (lfunit, 0, 2)
     fclose (lfunit)
     if llen > 0
       f_popup ("Appending "+lfile+" to transit ...")
       lnewfile = lfile+".txt"
       rename  &lfile to &lnewfile
       select 0
       use &ltransit
       append from &lnewfile sdf
       use
		 rename &lnewfile to &lfile
       f_popback ()
     else
       erase &lfile
     endif
  endif
next i

SET EXCL OFF

* start processing

do rresr2

f_popup ("Process Completed ...",.t.)

return

