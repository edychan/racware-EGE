*
* Reservation Retrieval System - Load received files.
*
private i, j, k, jctr, jfile

f_popup ("Processing received files to transit ...")

set excl on
declare nfile[35], ofile[5]
lpat = '*.txt'       
ltxt = gdbfpath + lpat
nf=adir(ltxt,nfile)
asort(nfile)
nf=if(nf>35,35,nf)

ltransit = gdbfpath + "transit.dbf"

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

select 1
use &ltransit
pack
use RASYS
go top
jctr = if(fccbatch>gmaxfil,1,fccbatch)
use

for i=1 to nf
  lfile = gdbfpath+alltrim(upper(nfile[i]))
  if file (lfile)
     lfunit = fopen (lfile)
     llen = fseek (lfunit, 0, 2)
     fclose (lfunit)
     if llen > 0
       f_popup ("Appending "+lfile+" to transit ...")
       select 0
       use &ltransit
       append from &lfile sdf
       * keep 100 transit file
       lpat = "*."+strtran(str(jctr,3)," ","0")
       ltxt = gdbfpath + lpat
       j=adir(ltxt,ofile)
       j=if(j>5,5,j)
       for k=1 to j
          jfile = gdbfpath+alltrim(upper(ofile[k]))
          erase &jfile
       next k
       * save current file
       lnewfile = stuff(lfile,at('TXT',lfile),3,strtran(str(jctr,3)," ","0"))
       rename  &lfile to &lnewfile
       jctr = jctr + 1
       use
     else
       erase &lfile
     endif
  endif
next i

use RASYS
go top
replace fccbatch with jctr
use

set excl off
f_popback ()

return

