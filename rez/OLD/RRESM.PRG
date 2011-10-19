* 
* Reservation Retrieval System - Maintenance
*

f_clrscn ("CODE TABLE MAINTENANCE")      
ldbf = gdbfpath + "rarescd"
select 1
use &ldbf

declare l_dbfld [4], l_dbcol [4], l_dbvalid [4], l_dbpict [4]      

l_dbfld[1]="fcode"      
l_dbfld[2]="fmemvar"      
l_dbfld[3]="fdesc"      
l_dbfld[4]="ftype"      

l_dbcol[1]="Code"      
l_dbcol[2]="Variable"      
l_dbcol[3]="Description"      
l_dbcol[4]="Type"      

l_dbvalid[1]=".t."      
l_dbvalid[2]=".t."      
l_dbvalid[3]=".t."      
l_dbvalid[4]=".t."      

l_dbpict[1]="!!"      
l_dbpict[2]="XXXXXXXXXXXXXX"      
l_dbpict[3]=replicate ([X],30)
l_dbpict[4]="X"      

f_edit (l_dbfld, l_dbcol, 0, .t., l_dbvalid, l_dbpict)      
use      
