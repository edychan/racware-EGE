private ydbfld[4], ydbcol[4], ydbvalid[4], ydbpict[4]
f_clrscn ("SERVICE CODE MAINTENANCE")
f_use ("rasvc")
ydbfld[1] = "fsvc"
ydbfld[2] = "fdesc"
ydbfld[3] = "fmileage"
ydbfld[4] = "fcost"
ydbcol[1] = "Code"
ydbcol[2] = "Description"
ydbcol[3] = "Interval"
ydbcol[4] = "Cost"
ydbvalid[1] = ".t."
ydbvalid[2] = ".t."
ydbvalid[3] = ".t."
ydbvalid[4] = ".t."
ydbpict[1] = "!!"
ydbpict[2] = replicate ("X", 40)
ydbpict[3] = "99999"
ydbpict[4] = "9999.99"

f_edit (ydbfld, ydbcol, 0, .t., ydbvalid, ydbpict)
use
