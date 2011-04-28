* ===========================================================================
* this is the utility routine for contract form printing  maint.
*
* date: 06/29/92
* author: edc
*
* revision
*
* ===========================================================================
declare l_dbfld [3], l_dbcol [3], l_dbvalid [3], l_dbpict [3]
l_dbfld[1]="frow"
l_dbfld[2]="fcol"
l_dbfld[3]="ffield"
l_dbcol[1]="ROW"
l_dbcol[2]="COL"
l_dbcol[3]="FIELD"
l_dbvalid[1]=".t."
l_dbvalid[2]="fmhlp()"
l_dbvalid[3]=".t."
l_dbpict[1]="99"
l_dbpict[2]="99"
l_dbpict[3]="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

select 51
use fmtable alias fmtable
f_use ("raagrfrm")

do while .t.
   f_clrscn ("Form Maintenance")
   setcolor (gbluecolor)
   yfrmno = 0
   yfrmtyp = " "
   @ 02, 01 say "Enter Form number:  " get yfrmno picture "99" 
   @ 03, 01 say "Enter Form Type  :  " get yfrmtyp pict "!" ;
     valid f_valid(yfrmtyp $ "I;O;R","Enter I-Checkin, O-Checkout, R-Reprint")
   if f_rd () = 27
     close all
     return
   endif
   select raagrfrm
   set filter to ffrmno=yfrmno .and. ffrmtyp=yfrmtyp
   go top
   f_edit (l_dbfld, l_dbcol, 0, .t., l_dbvalid, l_dbpict)
enddo


function fmhlp

select fmtable
f_pick_f (10, 05, "", "Field Name  Description "+space(30), ;
               "f_field+[ ]+f_desc")

select raagrfrm
return .t.
