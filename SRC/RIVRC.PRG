private ydbfld [2], ydbcol [2], ydbvalid [2], ydbpict [2]
f_clrscn ("STATUS CODE MAINTENANCE")
f_use ("ravs")
ydbfld[1] = "fcode"
ydbfld[2] = "fdesc"
ydbcol[1] = "Code"
ydbcol[2] = "Description"
ydbvalid[1]=".t."
ydbvalid[2]=".t."
ydbpict[1]="!"
ydbpict[2]=replicate("X",50)
f_edit (ydbfld, ydbcol, 0, .t., ydbvalid, ydbpict)
use

