private ydbfld [3], ydbcol [3], ydbvalid [3], ydbpict [3]
f_clrscn ("VEHICLE BONUS CODE TABLE MAINTENANCE")
f_use ("ravb")
ydbfld[1]="fcode"
ydbfld[2]="fdesc"
ydbfld[3]="fdue"
ydbcol[1]="Code"
ydbcol[2]="Description"
ydbcol[3]="Amount"
ydbvalid[1]=".t."
ydbvalid[2]=".t."
ydbvalid[3]=".t."
ydbpict[1]="!!!!"
ydbpict[2]=replicate("X",50)
ydbpict[3]="99999.99"
f_edit (ydbfld, ydbcol, 0, .t., ydbvalid, ydbpict)
use

