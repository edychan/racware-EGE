*
* Quick-Cap: 06/15/92.
*
do while .t.
   begin sequence
      do rinit
      glocname = "Quick-Cap: Electronic Draft Capture System"
      restore from (gmempath + "RAPATH") additive
      
      do while .t.
         if .not. usrlgin ()
            loop
         endif
         do while .t.
            xret1 = f_pushmenu ("QUICK-CAP")
            if xret1 = 0
               if usrlgout (.t.)
                  exit
               else
                 loop
               endif
            else
               xoption1 = substr (goption [xret1], 4)
               do case
               case xret1 = 1     && capture batch
                  if gccmodem
                     do rcccb
                  endif
                  __gloc = gloc
      
               case xret1 = 2     && authorize batch
                  if gccmodem
                     do rccab
                  endif
      
               case xret1 = 3     && file maint.
                  do rccfm
      
               case xret1 = 4     && report
                  do rccrpt
      
               case xret1 = 5     && location setup
                  do rccloc

               case xret1 = 6     && system configuration
                  do rccsys

               case xret1 = 7     && setup
                 do rccsu

               case xret1 = 8     && initialize modem
                  if gccmodem
                     do rccim
                  endif
      
               endcase
            endif
         enddo
         blimempak (-1)
      enddo
   end
enddo

*
procedure rccrpt
private yret, yfile, i, yfld, ytitle, ycond, yopt, yfilter

rest from (gmempath + "rarpt") additive
bliovlclr ()
f_use ("rarpt")
f_clrscn ("CREDIT CARD REPORT")
yfilter = "#3"
seek yfilter
if .not. eof()
   if f_pick_f (02, 3, "", "", "[ -> ]+ftitle+[ <- ]","","fname","yfilter")
      yrname = rarpt->fname
      ytitle = ""
      ycond = ""
      yret = f_rr (yrname, ytitle)
      if yret < 0
         tone(500, 9)
         f_popup ("Invalid Report Setup... Error: "+str(yret,3) ;
            + ". Press Any Key...",.t.)
      endif
   endif
else
   tone (500, 9)
   f_popup ("File is Empty. Press Any Key to Continue...",.t.)
endif

release all like l_*
close database

*
procedure rccloc

f_clrscn ("LOCATION MAINTENANCE")
f_use ("raloc")
declare l_dbfld [3], l_dbcol [3], l_dbvalid [3], l_dbpict [3]
l_dbfld[1]="floc"
l_dbfld[2]="fname"
l_dbfld[3]="fphone"
l_dbcol[1]="Location Id"
l_dbcol[2]="Location Name"
l_dbcol[3]="Phone"
l_dbvalid[1]=".t."
l_dbvalid[2]=".t."
l_dbvalid[3]=".t."
l_dbpict[1]="!!!!!!!!!!"
l_dbpict[2]="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
l_dbpict[3]="999-999-9999"
f_edit (l_dbfld, l_dbcol, 0, .t., l_dbvalid, l_dbpict)

go top
gusrloc = ""
do while .not. eof ()
   gusrloc = gusrloc + floc + ";"
   skip
enddo
use

*
procedure rccsys

f_clrscn ("SYSTEM PARAMETERS")
f_use ("rastn")
declare l_dbfld [5], l_dbcol [5], l_dbvalid [5], l_dbpict [5]

l_dbfld[1]="fstn"
l_dbfld[2]="floc"
l_dbfld[3]="fccnet"
l_dbfld[4]="fccreader"
l_dbfld[5]="fccmodem"

l_dbcol[1]="Station"
l_dbcol[2]="Location"
l_dbcol[3]="Network"
l_dbcol[4]="Reader"
l_dbcol[5]="Modem"

l_dbvalid[1]=".t."
l_dbvalid[2]="f_valid(f_verify([raloc], 1, upper(l_floc)), [Invalid Location Id!])"
l_dbvalid[3]="f_valid(l_fccnet $ [LPA;NDC;], [Enter LPA for Transnet or NDC " + ;
                     "for NDC network])"
l_dbvalid[4]="f_valid(l_fccreader < 3, [Enter 0->no, 1->MagTek, 2->Keytronic])"
l_dbvalid[5]=".t."

l_dbpict[1]="!!!!!!!!"
l_dbpict[2]="!!!!!!!!!!"
l_dbpict[3]="!!!"
l_dbpict[4]="9"
l_dbpict[5]="Y"

f_edit (l_dbfld, l_dbcol, 0, .f., l_dbvalid, l_dbpict)

* update location code if applicable
seek f_truncate (gstation, 8)
if .not. eof ()
   gloc = floc
   gccreader = fccreader
   gccnet = fccnet
   gccmodem = fccmodem
endif
use

