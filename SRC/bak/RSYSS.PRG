do while .t.
   xret2 = f_pushmenu (xoption1)
   if xret2 = 0
      exit
   endif
   xoption2 = substr (goption [xret2], 4)
   do case
   case xret2 = 1
      do rsysssc
   case xret2 = 2
      do rsysssu
   case xret2 = 3
      do rsysssl
   case xret2 = 4
      do rsysssr
   case xret2 = 5
      f_clrscn ("MENU SECURITY MAINTENANCE")
      declare fgp [10], fgppk [10]
      f_use ("ragroup")
      for n = 1 to 10
         go n
         fgp [n] = fgroup
      next
      use
      f_use ("litebar")
      declare fopts [reccount ()], frecno [reccount ()]
      index on str (flevel, 1) + ftitle + foption to (gstnpath + "litebar")
      do while .t.
         if f_pick_f (2, 5, "", "Menu Title컴컴컴컴컴컴컴Menu " + ;
               "Option컴컴컴컴컴컴컴컴Security", ;
               "ftitle+[  ]+foption+[  ]+fsecurity")
            yoldsecur = fsecurity
            for n = 1 to 10
               if empty (fgp [n])
                  fgppk [n] = .f.
               else
                  fgppk [n] = (str (n - 1, 1) $ fsecurity)
               endif
            next
            do while .t.
               @ 2, 2 say "Menu Title: " + ftitle
               @ 3, 2 say "Menu Option: " + foption
               for n = 1 to 10
                  if .not. empty (fgp [n])
                     @ 4 + n, 2 say str (n - 1, 1) + " " + fgp [n] + " " ;
                        get fgppk [n] pict "Y"
                  endif
               next
               f_rd ()
               yans1 = f_confirm ("[C]onfirm  [E]dit  [I]gnore Changes", "CEI")
               if yans1 = "C"
                  yrecno = recno ()
                  yfopts = 1
                  fopts [yfopts] = str (flevel + 1, 1) + substr (foption, 4)
                  frecno [yfopts] = yrecno
                  yfoptscnt = 1
                  do while .t.
                     seek fopts [yfoptscnt]
                     do while str (flevel, 1) + ftitle = fopts [yfoptscnt] ;
                           .and. .not. eof ()
                        yfopts = yfopts + 1
                        fopts [yfopts] = str (flevel + 1, 1) + ;
                           substr (foption, 4)
                        frecno [yfopts] = recno ()
                        skip
                     enddo
                     if yfoptscnt = yfopts
                        exit
                     endif
                     yfoptscnt = yfoptscnt + 1
                  enddo
                  for yfoptscnt = 1 to yfopts
                     go (frecno [yfoptscnt])
                     ystr = space (10)
                     for n = 1 to 10
                        if (str (n - 1, 1) $ fsecurity .or. ;
                              .not. (str (n - 1, 1) $ yoldsecur)) .and. fgppk [n]
                           ystr = stuff (ystr, n, 1, str (n - 1, 1))
                        endif
                     next
                     reclock ()
                     replace fsecurity with ystr
                     commit
                     unlock
                     fopts [yfoptscnt] = ""
                     frecno [yfoptscnt] = ""
                  next
                  afill (fopts, "")
                  go (yrecno)
                  exit
               elseif yans1 = "I"
                  exit
               endif
            enddo
         else
            exit
         endif
      enddo
      use
   case xret2 = 6
      f_clrscn ("SCREEN SECURITY MAINTENANCE")
      f_use ("fscreen")
      set filter to .not. empty (f_get)
      go top
      declare l_dbfld[3], l_dbcol[3]
      l_dbfld[1]="f_scn"
      l_dbfld[2]="f_get"
      l_dbfld[3]="fsecurity"
      l_dbcol[1]="Screen Name"
      l_dbcol[2]="Field Name"
      l_dbcol[3]="Security Level"
      f_edit (l_dbfld, l_dbcol, 3, .f.)
      use
   case xret2 = 7
      f_clrscn ("PAY CODE TABLE MAINTENANCE")
      f_use ("rapaycd")
      declare l_dbfld [10], l_dbcol [10], l_dbvalid [10], l_dbpict [10], l_edfld [10]
      l_dbfld[1]="fpaycd"
      l_dbfld[2]="fitem"
      l_dbfld[3]="frate"
      l_dbfld[4]="ftax"
      l_dbfld[5]="fdly"
      l_dbfld[6]="faccno"
      l_dbfld[7]="fchgcode"
      l_dbfld[8]="fchgdesc"
      l_dbfld[9]="fchgtyp"
      l_dbfld[10]="fglacctyp"

      l_dbcol[1]="Pay Code"
      l_dbcol[2]="Description"
      l_dbcol[3]="Rate"
      l_dbcol[4]="Taxable"
      l_dbcol[5]="Daily Chg"
      l_dbcol[6]="Account No"
      l_dbcol[7]="Chg Code"
      l_dbcol[8]="Chg Desc"
      l_dbcol[9]="Chg Type"
      l_dbcol[10]="G/L Type"

      l_edfld[1] = ".t."
      l_edfld[2] = ".t."
      l_edfld[3] = ".t."
      l_edfld[4] = ".f."
      l_edfld[5] = ".f."
      l_edfld[6] = ".f."
      l_edfld[7] = ".t."
      l_edfld[8] = ".f."
      l_edfld[9] = ".f."
      l_edfld[10] = ".f."

      l_dbvalid[1]=".t."
      l_dbvalid[2]=".t."
      l_dbvalid[3]=".t."
      l_dbvalid[4]=".t."
      l_dbvalid[5]=".t."
      l_dbvalid[6]=".t."
      l_dbvalid[7]=".t."
      l_dbvalid[8]=".t."
      l_dbvalid[9]="f_valid (l_fchgtyp $ [CVG ;FUEL;MISC;OPT ;TIME])"
      l_dbvalid[10]="f_valid (l_fglacctyp $ [R;N;F;O])"

      l_dbpict[1]="!!!!"
      l_dbpict[2]="XXXXXXXXXXXXXXX"
      l_dbpict[3]="9999.99"
      l_dbpict[4]="Y"
      l_dbpict[5]="Y"
      l_dbpict[6]="XXXXXXXXXX"
      l_dbpict[7]="!!!!!!!!!!"
      l_dbpict[8]=replicate ("X", 30)
      l_dbpict[9]="!!!!"
      l_dbpict[10]="!"

      f_edit (l_dbfld, l_dbcol, 0, .t., l_dbvalid, l_dbpict, l_edfld)
      use
   case xret2 = 8
      f_clrscn ("PAYMENT TYPE TABLE MAINTENANCE")
      f_use ("rapaytyp")
      declare l_dbfld [6], l_dbcol [6], l_dbvalid [6], l_dbpict [6]
      l_dbfld[1]="fpaycode"
      l_dbfld[2]="fdesc"
      l_dbfld[3]="facctype"
      l_dbfld[4]="ftype"
      l_dbfld[5]="faccno"
      l_dbfld[6]="fcustno"
      l_dbcol[1]="Code"
      l_dbcol[2]="Description"
      l_dbcol[3]="Type"
      l_dbcol[4]="Code"
      l_dbcol[5]="Acct No"
      l_dbcol[6]="Cust No"
      l_dbvalid[1]=".t."
      l_dbvalid[2]=".t."
      l_dbvalid[3]="f_valid(l_facctype$[RC])"
      l_dbvalid[4]="f_valid(l_ftype>=1.and.l_ftype<=3)"
      l_dbvalid[5]=".t."
      l_dbvalid[6]=".t."
      l_dbpict[1]="!!!"
      l_dbpict[2]=replicate ("X", 20)
      l_dbpict[3]="!"
      l_dbpict[4]="9"
      l_dbpict[5]="XXXXXXXXXX"
      l_dbpict[6]="!!!!!!!!!!"
      f_edit (l_dbfld, l_dbcol, 0, .t., l_dbvalid, l_dbpict)
      use
   endcase
enddo
release all like l_*
close database

