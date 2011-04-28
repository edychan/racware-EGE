* ===========================================================================
* Rate Table Maint.
*
* date: 05/01/91
* author: KST
*
* date: 12/03/93
* edc: implement block rate
* ===========================================================================
do while .t.
   xret3 = f_pushmenu (xoption2)
   if xret3 = 0
      exit
   else
      xoption3 = substr (goption [xret3], 4)
      do case
      case xret3 = 1                && block rate
         do rsysssru with "A"       
      case xret3 = 2                && update rate
         do rsysssru with "U"       
      case xret3 = 3                && block rate
         f_clrscn ("BLOCK RATE")
         f_use ("rartml")
         declare l_dbfld [9], l_dbcol [9], l_dbvalid [9], l_dbpict [9]
         l_dbfld[1]="floc"
         l_dbfld[2]="fcode"
         l_dbfld[3]="fclass"
         l_dbfld[4]="fdtfrom1"
         l_dbfld[5]="fdtto1"
         l_dbfld[6]="fdtfrom2"
         l_dbfld[7]="fdtto2"
         l_dbfld[8]="fdtfrom3"
         l_dbfld[9]="fdtto3"
         l_dbcol[1]="Location"
         l_dbcol[2]="Rate"
         l_dbcol[3]="Class"
         l_dbcol[4]="From"
         l_dbcol[5]="To"
         l_dbcol[6]="From"
         l_dbcol[7]="To"
         l_dbcol[8]="From"
         l_dbcol[9]="To"
         l_dbvalid[1]=".t."
         l_dbvalid[2]=".t."
         l_dbvalid[3]=".t."
         l_dbvalid[4]=".t."
         l_dbvalid[5]=".t."
         l_dbvalid[6]=".t."
         l_dbvalid[7]=".t."
         l_dbvalid[8]=".t."
         l_dbvalid[9]=".t."
         l_dbpict[1]="!!!!!!!!!!"
         l_dbpict[2]="!!!!!!"
         l_dbpict[3]="!!!!"
         l_dbpict[4]="@D"
         l_dbpict[5]="@D"
         l_dbpict[6]="@D"
         l_dbpict[7]="@D"
         l_dbpict[8]="@D"
         l_dbpict[9]="@D"
         f_edit (l_dbfld, l_dbcol, 0, .t., l_dbvalid, l_dbpict)
         use
      endcase
   endif
enddo

