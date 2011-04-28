do while .t.
   xret1 = f_pushmenu (xoption0)
   if xret1 = 0
      exit
   endif
   xoption1 = substr (goption [xret1], 4)
   do case
   case xret1 = 1
      do rmkcrp
   case xret1 = 2
      do rmkcust
   case xret1 = 3
      f_clrscn ("REFERRAL CODE TABLE MAINTENANCE")
      f_use ("rarefr")
      declare l_dbfld [2], l_dbcol [2], l_dbvalid [2], l_dbpict [2]
      l_dbfld[1]="frefr"
      l_dbfld[2]="fdesc"
      l_dbcol[1]="Referral Code"
      l_dbcol[2]="Description"
      l_dbvalid[1] = ".t."
      l_dbvalid[2] = ".t."
      l_dbpict[1] = replicate ("!", 20)
      l_dbpict[2] = replicate ("X", 50)
      f_edit (l_dbfld, l_dbcol, 0, .t., l_dbvalid, l_dbpict)
      use
   endcase
enddo

