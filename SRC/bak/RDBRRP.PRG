private ycashcc, yrecvcc, not_auth_only, yfil
private i, j, yret, yopt, yfnd
private xans

f_clrscn ("REPRINT POSTED DAILY BUSINESS REPORT")
xans = .f.
@ 02, 02 say "Warning! This report may take a long period of time."
@ 03, 02 say "Do you want to continue? ............................" ;
   get xans pict "Y"
if f_rd () = 27
   return
endif
if .not. xans
   return
endif

l_floc = gloc
l_fdbrno = 0

@ 05, 02 say "DBR Location... " get l_floc pict "!!!!!!!!!!" ;
   valid f_valid (l_floc $ gusrloc)
@ 06, 02 say "DBR Number..... " get l_fdbrno pict "9999"
if f_rd () = 27
   return
endif
l_foutopt = f_confirm ("[D]isplay  [P]rint  [Q]uit","DPQ")
if l_foutopt = "Q"
   return
endif

f_popup ("Please wait while locating DBR from history file...")
f_use ("RAHDBRT")
yfil = gstnpath + "RADBRT"
copy to &yfil for floc = l_floc .and. fdbrno = l_fdbrno
use &yfil alias radbrt excl
if .not. f_valid (reccount () > 0, "No record found!!!")
   close databases
   return
endif

f_popup ("Please Wait While Computing...")

ycashcc = ""
yrecvcc = ""
not_auth_only = ""

f_use ("rapaytyp")
do while .not. eof()
   if facctype = "C"
      ycashcc = ycashcc + fpaycode + ";"
   else
      yrecvcc = yrecvcc + fpaycode + ";"
   endif
   if .not. fauthonly
      not_auth_only = not_auth_only + fpaycode + ";"
   endif
   skip
enddo

f_use ("radbr")
yfil = gstnpath + "radbr"
copy stru to &yfil
use &yfil alias radbr excl
append blank
replace floc with l_floc, fdbrno with l_fdbrno
commit

f_use ("radbrs")
yfil = gstnpath + "radbrs"
copy stru to &yfil
use &yfil alias radbrs excl
index on fpaytyp to &yfil

select radbrt
set filter to radbrt->frectype > "*"
go top

do while .not. eof () 
   yrectype = frectype
   ycash    = if(radbrt->fpaytyp1+";" $ ycashcc, radbrt->famt1, 0.00) + ;
      if(radbrt->fpaytyp2+";" $ ycashcc, radbrt->famt2, 0.00) + ;
      if(radbrt->fpaytyp3+";" $ ycashcc, radbrt->famt3, 0.00)

   xacctrec = if(radbrt->fpaytyp1+";" $ yrecvcc, radbrt->famt1, 0.00) + ;
      if(radbrt->fpaytyp2+";" $ yrecvcc, radbrt->famt2, 0.00) + ;
      if(radbrt->fpaytyp3+";" $ yrecvcc, radbrt->famt3, 0.00)

   select radbr
   do case
   case yrectype $ "CF"
      replace fclosed with fclosed + 1
      replace fdays with fdays+radbrt->fdays,fmiles with fmiles+radbrt->fmlg
      replace ftmetot with ftmetot+radbrt->ftmetot,fmlgtot with fmlgtot+radbrt->fmlgtot
      replace fdisc with fdisc+radbrt->fdisctot
      replace fcred with fcred+radbrt->fcredtot
      replace fcdw with fcdw+radbrt->fcdwtot
      replace ftax with ftax+radbrt->ftaxtot,fpai with fpai+radbrt->fpaitot
      replace fgas with fgas+radbrt->ffueltot,fdamage with fdamage+radbrt->fdmgtot
      replace fothamt with fothamt+radbrt->fotot1+radbrt->fotot2+radbrt->fotot3+radbrt->fotot4
      replace fothchgs with fothchgs+radbrt->fsurchg
      replace ftotal with ftotal+radbrt->ftotal
      replace fprev with fprev+radbrt->fdepamt
      replace frecv with frecv+radbrt->famt1+radbrt->famt2+radbrt->famt3
      replace fcash with fcash+ycash, facctrec with facctrec+xacctrec
   case yrectype = "D"
      replace frentals with frentals + 1
      if radbrt->fpaytyp1 = "CA"
         replace fdep with fdep+radbrt->famt1,frecv with frecv+radbrt->famt1
         replace fcash with fcash+radbrt->famt1
      else
         select radbrt
         skip
         loop
      endif
   case yrectype = "A"
      replace fdep with fdep+radbrt->famt1,frecv with frecv+radbrt->famt1
      replace fcash with fcash+if(radbrt->fpaytyp1+";" $ ycashcc, radbrt->famt1, 0.00)
      replace facctrec with facctrec+if(radbrt->fpaytyp1+";" $ yrecvcc, radbrt->famt1, 0.00)
   endcase

   select radbrs
   ycnt = 1
   do while ycnt <= 3
      ytyp = "radbrt->fpayTyp" + str(ycnt,1)
      yamt = "radbrt->famt" + str(ycnt,1)
      xtyp = &ytyp
      xamt = &yamt
      if xamt # 0
         seek xtyp
         if eof() .or. .not. found()
            append blank
            replace floc with l_floc,fdbrno with l_fdbrno
            replace fpaytyp with xtyp
            select rapaytyp
            locate for fpaycode = xtyp
            if .not. eof()
               select radbrs
               replace fdesc with rapaytyp->fdesc
               replace facctype with if (rapaytyp->facctype="C", "CASH EQUIVALENT", "RECEIVABLES")
            else
               select radbrs
               replace facctype with "RECEIVABLES"
            endif
         endif
         do case
         case yrectype = "F"
            replace fduefrom with fduefrom+xamt
         case yrectype = "T"
            replace fdeposit with fdeposit+xamt
            replace fdueto with fdueto - xamt
         otherwise
            replace fdeposit with fdeposit + xamt
         endcase
         replace frecv with fdeposit + fdueto + fduefrom
      endif
      ycnt = ycnt + 1
   enddo
   select radbrt
   skip
enddo
select radbr
commit
if empty (gete ("RACCPRT"))
   l_cprt = chr(27)+chr(15)
else
   l_cprt = alltrim (upper (gete ("RACCPRT")))
   l_cprt = &l_cprt
endif
if empty (gete ("RACNPRT"))
   l_nprt = chr(18)
else
   l_nprt = alltrim (upper (gete ("RACNPRT")))
   l_nprt = &l_nprt
endif

if l_foutopt = "D"
   f_popup ("Please Wait ...")
   yfil=gstnpath+"rrout.rpt"
   set device to print
   set printer to &yfil
else
   f_popup ("Printing DBR ...")
   set device to print
   setprc (0,0)
   @ 00, 01 say l_cprt
endif
l_date = dtoc(date())
l_time = time()
l_page = 0
yln = 99
l_pgsize = 55
select radbrt

set filter to frectype = "A"
go top
if .not. eof ()
   yln = f_dbrph (yln, l_pgsize, "A")
   do while .not. eof ()
      yln = f_dbrph (yln, l_pgsize, "A")
      @yln,01 say str(frano,6)+[ ]+flname+[   ]+str(famt1,7,2)+[ ]+fpaytyp1
      yln = f_dbrph (yln, l_pgsize, "A")
      skip
   enddo
   yln = yln + 1
   @ yln, 01 say replicate ("-", 130)
endif

set filter to frectype = "D"
go top
if .not. eof ()
   yln = f_dbrph (yln, 0,"D")
   do while .not. eof ()
      yln = f_dbrph (yln, l_pgsize, "D")
      @ yln, 01 say str(frano,6)+[ ]+flname+[  ]+funit
      if fcdwtot > 0
         @ yln,37 say str(fcdwtot,6,2)
      endif
      if fpaitot > 0
         @yln,46 say str(fpaitot,6,2)
      endif
      if fpaytyp1 = "CA"
         @yln,55 say str(famt1,7,2)+[  ]+fpaytyp1
      endif
      @yln,70 say frloc       
      yln = f_dbrph (yln, l_pgsize, "D")
      skip
   enddo
   yln = yln + 1
   @ yln, 01 say replicate ("-",130)
endif

set filter to frectype = "C"
go top
if .not. eof ()
   yln = f_dbrph (yln, 0,"C")
   do while .not. eof() 
      yln = f_dbrph (yln, l_pgsize,"C")
      yotot1 = fotot1+fotot2+fotot3+fotot4
      @yln,01 say str(frano,6)+[ ]+funit+[      ]+str(fdays,4)+[  ]+str(ftmetot+fmlgtot-fdisctot,8,2)+ ;
         [  ]+str(fcdwtot,7,2)+[  ]+str(yotot1,8,2)+[     ]+str(ffueltot,7,2)+[ ]+ ;
         str(ftaxtot,7,2)+[ ]+str(fdmgtot,8,2)+[ ]+str(fcredtot,8,2)+[  ]+ ;
         str(ftotal,8,2)+[  ]+str(famt1,8,2)+[  ]+fpaytyp1+[ ]+fdbacct1
      yln = f_dbrph (yln, l_pgsize,"C")
      @yln,01 say flname
      @yln,23 say str(fmlg,5)
      if fdisctot > 0
         @yln,31 say str(fdisctot,7,2)
      endif
      yotot2=fsurchg
      @yln,40 say str(fpaitot,7,2)+[  ]+str(yotot2,8,2)
      if fdepamt > 0
         @yln,98 say str(fdepamt,7,2)
      endif
      if famt2 <> 0
         @yln,107 say str(famt2,8,2)+[  ]+fpaytyp2+[ ]+fdbacct2
      endif
      if famt3 <> 0
         yln = f_dbrph (yln, l_pgsize,"C")
         @yln,107 say str(famt3,8,2)+[  ]+fpaytyp3
      endif
      yln = f_dbrph (yln, l_pgsize,"C")
      skip
   enddo
   yln = yln + 1
   @ yln, 01 say replicate ("-",130)
endif

set filter to frectype = "F"
go top
if .not. eof ()
   yln = f_dbrph (yln, 0,"F")
   do while .not. eof() 
      yln = f_dbrph (yln, l_pgsize,"F")
      @yln,01 say "Check-out: "+floc+"  "+"Check-in: "+frloc
      yln = f_dbrph (yln, l_pgsize,"F")
      yotot1 = fotot1+fotot2+fotot3+fotot4
      @yln,01 say str(frano,6)+[ ]+funit+[      ]+str(fdays,4)+[  ]+str(ftmetot+fmlgtot-fdisctot,8,2)+ ;
         [  ]+str(fcdwtot,7,2)+[  ]+str(yotot1,8,2)+[     ]+str(ffueltot,7,2)+[ ]+ ;
         str(ftaxtot,7,2)+[ ]+str(fdmgtot,8,2)+[ ]+str(fcredtot,8,2)+[  ]+ ;
         str(ftotal,8,2)+[  ]+str(famt1,8,2)+[  ]+fpaytyp1+[ ]+fdbacct1
      yln = f_dbrph (yln, l_pgsize,"F")
      @yln,01 say flname
      @yln,23 say str(fmlg,5)
      if fdisctot > 0
         @yln,31 say str(fdisctot,7,2)
      endif
      yotot2=fsurchg
      @yln,40 say str(fpaitot,7,2)+[  ]+str(yotot2,8,2)
      if fdepamt > 0
         @yln,98 say str(fdepamt,7,2)
      endif
      if famt2 <> 0
         @yln,107 say str(famt2,8,2)+[  ]+fpaytyp2+[ ]+fdbacct2
      endif
      if famt3 <> 0
         yln = f_dbrph (yln, l_pgsize,"F")
         @yln,107 say str(famt3,8,2)+[  ]+fpaytyp3
      endif
      yln = f_dbrph (yln, l_pgsize, "F")
      skip
   enddo
   yln = yln + 1
   @ yln, 01 say replicate ("-",130)
endif

set filter to frectype = "T"
go top
if .not. eof ()
   yln = f_dbrph (yln, 0, "T")
   do while .not. eof() 
      yln = f_dbrph (yln, l_pgsize,"T")
      @yln,01 say "Check-out: "+frloc+"  "+"Check-in: "+floc
      yln = f_dbrph (yln, l_pgsize,"T")
      yotot1 = fotot1+fotot2+fotot3+fotot4
      @yln,01 say str(frano,6)+[ ]+funit+[      ]+str(fdays,4)+[  ]+str(ftmetot+fmlgtot-fdisctot,8,2)+ ;
         [  ]+str(fcdwtot,7,2)+[  ]+str(yotot1,8,2)+[     ]+str(ffueltot,7,2)+[ ]+ ;
         str(ftaxtot,7,2)+[ ]+str(fdmgtot,8,2)+[ ]+str(fcredtot,8,2)+[  ]+ ;
         str(ftotal,8,2)+[  ]+str(famt1,8,2)+[  ]+fpaytyp1+[ ]+fdbacct1
      yln = f_dbrph (yln, l_pgsize,"T")
      @yln,01 say flname
      @yln,23 say str(fmlg,5)
      if fdisctot > 0
         @yln,31 say str(fdisctot,7,2)
      endif
      yotot2=fsurchg
      @yln,40 say str(fpaitot,7,2)+[  ]+str(yotot2,8,2)
      if fdepamt > 0
         @yln,98 say str(fdepamt,7,2)
      endif
      if famt2 <> 0
         @yln,107 say str(famt2,8,2)+[  ]+fpaytyp2+[ ]+fdbacct2
      endif
      if famt3 <> 0
         yln = f_dbrph (yln, l_pgsize,"T")
         @yln,107 say str(famt3,8,2)+[  ]+fpaytyp3
      endif
      yln = f_dbrph (yln, l_pgsize,"T")
      skip
   enddo
   yln = yln + 1
   @ yln, 01 say replicate ("-",130)
endif

select radbrt
set filter to frectype = "*"
go top
if .not. eof ()
   yln = f_dbrph (yln, 0,"*")
   do while .not. eof() 
      yln = f_dbrph (yln, l_pgsize,"*")
      yotot1 = fotot1+fotot2+fotot3+fotot4
      @yln,01 say str(frano,6)+[ ]+funit+[      ]+str(fdays,4)+[  ]+str(ftmetot+fmlgtot-fdisctot,8,2)+ ;
         [  ]+str(fcdwtot,7,2)+[  ]+str(yotot1,8,2)+[     ]+str(ffueltot,7,2)+[ ]+ ;
         str(ftaxtot,7,2)+[ ]+str(fdmgtot,8,2)+[ ]+str(fcredtot,8,2)+[  ]+ ;
         str(ftotal,8,2)+[  ]+str(famt1,8,2)+[  ]+fpaytyp1+[ ]+fdbacct1
      yln = f_dbrph (yln, l_pgsize, "*")
      @yln,01 say flname
      @yln,23 say str(fmlg,5)
      if fdisctot > 0
         @yln,31 say str(fdisctot,7,2)
      endif
      yotot2=fsurchg
      @yln,40 say str(fpaitot,7,2)+[  ]+str(yotot2,8,2)
      if fdepamt > 0
         @yln,98 say str(fdepamt,7,2)
      endif
      if famt2 <> 0
         @yln,107 say str(famt2,8,2)+[  ]+fpaytyp2+[ ]+fdbacct2
      endif
      if famt3 <> 0
         yln = f_dbrph (yln, l_pgsize,"*")
         @yln,107 say str(famt3,8,2)+[  ]+fpaytyp3
      endif
      yln = yln + 1                         
      @ yln, 01 say replicate ("-",130)     
      skip
   enddo
   yln = yln + 1
   @ yln, 01 say replicate ("-",130)
endif

select radbrt
use

select radbr
yln=f_dbrph (yln+1, l_pgsize)
@yln,55 say "**  D B R   T O T A L S  **"
yln=f_dbrph (yln, l_pgsize)
@yln,01 say "                   DAYS/    T&M/      CDW/      MISC. 1   /"+  ;
   "                                            TOTAL/"
yln=f_dbrph (yln, l_pgsize)
@yln,01 say "CHECKOUTS CHECKINS MILES    DISC      PAI       MISC. 2     "+  ;
   "FUEL    TAX     DAMAGE   CREDIT   DEPOSIT  PRV PMT   RECEIVED  "
yln=f_dbrph (yln, l_pgsize)
@yln,01 say "--------- -------- ------ --------- -------- -------------- "+  ;
   "------ -------- -------- -------- -------- --------- --------- "
yln=f_dbrph (yln, l_pgsize)
@yln,02 say str(frentals,4)+space(7)+str(fclosed,4)+[    ]+str(fdays,4)+[  ]+ ;
   str(ftmetot+fmlgtot-fdisc,8,2)+[ ]+str(fcdw,8,2)+[ ]+str(fothamt,8,2)+space(7)+  ;
   str(fgas,7,2)+[ ]+str(ftax,7,2)+[ ]+str(fdamage,8,2)+[ ]+       ;
   str(fcred,8,2)+[ ]+str(fdep,8,2)+[ ]+str(ftotal,8,2)+[   ]+     ;
   str(frecv,8,2)
yln=f_dbrph (yln, l_pgsize)
@yln,19 say str(fmiles,6)
if fdisc > 0
   @yln,28 say str(fdisc,7,2)
endif
@yln,36 say str(fpai,8,2)
if fothchgs > 0
   @yln,45 say str(fothchgs,8,2)
endif
if fprev > 0
   @yln,103 say str(fprev,8,2)
endif
yln = f_dbrph (yln+1, l_pgsize)
@ yln, 01 say replicate ("-",130)

select radbrs
index on facctype to (gstnpath+"radbrs2")
go top
yfnd = .f.
if .not. eof()
   yfnd = .t.
   yln = f_dbrph (l_pgsize+1, l_pgsize)
   @yln,55 say "**  R E V E N U E    S U M M A R Y  **"
   yln = f_dbrph (yln+1, l_pgsize)
   @yln,28 say "RECEIVED     DUE FROM     DUE TO      REVENUE  "
   yln = f_dbrph (yln, l_pgsize)
   @yln,28 say "----------   ----------   ----------  ---------"
endif
l_val=radbrs->facctype
l_deposit=0
l_duefrom=0
l_dueto=0
l_recv=0
l_tdeposit=0
l_tduefrom=0
l_tdueto=0
l_trecv=0
do while .not. eof()
   if l_val <> radbrs->facctype
      yln = f_dbrph (yln, l_pgsize)
      @yln,28 say "----------   ----------   ----------  ---------"
      yln = f_dbrph (yln, l_pgsize)
      @yln,01 say trim(l_val)+" TOTALS:"
      @yln,29 say str(l_deposit,8,2)
      @yln,42 say str(l_duefrom,8,2)
      @yln,55 say str(l_dueto,8,2)
      @yln,67 say str(l_recv,8,2)
      yln = f_dbrph (yln, l_pgsize)
      @yln,28 say "==========   ==========   ==========  ========="
      yln = f_dbrph (yln, l_pgsize)
      l_val = radbrs->facctype
      l_deposit=0
      l_duefrom=0
      l_dueto=0
      l_recv=0
   endif
   yln = f_dbrph (yln, l_pgsize)
   @yln,01 say fpaytyp+[ ]+fdesc
   @yln,29 say str(fdeposit,8,2)
   @yln,42 say str(fduefrom,8,2)
   @yln,55 say str(fdueto,8,2)
   @yln,67 say str(frecv,8,2)
   l_deposit=l_deposit+fdeposit
   l_duefrom=l_duefrom+fduefrom
   l_dueto=l_dueto+fdueto
   l_recv=l_recv+frecv
   l_tdeposit=l_tdeposit+fdeposit
   l_tduefrom=l_tduefrom+fduefrom
   l_tdueto=l_tdueto+fdueto
   l_trecv=l_trecv+frecv
   skip
enddo
yln = f_dbrph (yln, l_pgsize)
@yln,28 say "----------   ----------   ----------  ---------"
yln = f_dbrph (yln, l_pgsize)
@yln,01 say trim(l_val)+" TOTALS:"
@yln,29 say str(l_deposit,8,2)
@yln,42 say str(l_duefrom,8,2)
@yln,55 say str(l_dueto,8,2)
@yln,67 say str(l_recv,8,2)
yln = f_dbrph (yln, l_pgsize)
@yln,28 say "==========   ==========   ==========  ========="
yln = f_dbrph (yln+1, l_pgsize)
@yln,42 say "TOTAL REVENUE"
@yln,67 say str(l_trecv,8,2)
yln = f_dbrph (yln, l_pgsize)
@yln,42 say "PLUS PREV PAYMENT"
@yln,67 say str(radbr->fprev,8,2)
yln = f_dbrph (yln, l_pgsize)
@yln,42 say "LESS CASH DEPOSIT"
@yln,67 say str(radbr->fdep,8,2)
yln = f_dbrph (yln, l_pgsize)
@yln,67 say "---------"
yln = f_dbrph (yln, l_pgsize)
@yln,42 say "NET REVENUE"
@yln,67 say str(l_trecv+radbr->fprev-radbr->fdep,8,2)
yln = f_dbrph (yln, l_pgsize)
@yln,67 say "========="

if l_foutopt = "P"
   eject
endif
set device to screen
set printer to
if l_foutopt = "D"
   set color to
   clear
   run racbrow &yfil
   setcolor (gbluecolor)
endif

f_popback ()
release all like l_*
close databases


******************************
function f_dbrph

blimempak (-1)
parameters xln, xpgsize, xrtype
private i, yln, ylen, ycol, ydesc
if pcount () < 3
   xrtype = " "
endif
if xln > xpgsize
   if l_foutopt = "P"
      if xln <> 99
         eject
      endif
   endif
   l_page = l_page+1
   @ 01,01 say "DATE: " + l_date
   @ 01,55 say "DAILY BUSINESS REPORT ("+trim(l_floc)+")"
   @ 01,120 say "PAGE: " + str(l_page,3)
   @ 02,01 say "TIME: " + l_time
   @ 02,60 say "#" + str(l_fdbrno,4)+[ - POStED DBR]
   @ 03,01 say replicate ("-",130)
   yln = 5
   if xrtype = " "
      return (yln)
   endif
   do case
   case xrtype = "A"
      @yln,55 say " **  D E P O S I T  **"
      yln = yln + 1
      @yln,01 say "RA#     NAME            DEPOSIT"
      yln = yln + 1
      @ yln,01 say "------  -------------  ----------"
      yln = yln + 1
   case xrtype = "D"
      @yln,55 say "**  C H E C K O U T S  **"
      yln = f_dbrph (yln+1, l_pgsize)
      @yln,01 say "RA#     NAME            UNIT #       CDW      PAI     DEPOSIT        CHECK-IN"
      yln = f_dbrph (yln, l_pgsize)
      @ yln,01 say "------ -------------   ----------   ------   ------  ------------   ----------"
      yln = yln + 1
   otherwise
      yhead = " "
      if xrtype = "C"
         yhead = "**  C H E C K I N S  **"
      elseif xrtype = "F"
         yhead = "**  D U E   F R O M   **"
      elseif xrtype = "T"
         yhead = "**  D U E   T O  **"
      elseif xrtype = "*"
         yhead = "**  A u d i t s  **"
      endif
      @yln,55 say yhead
      yln = yln + 1
      @ yln,01 say "RA#/UNIT #/          DAYS/    T&M/      CDW/   "+  ;
         "   MISC. 1   /                                  TOTAL/"
      yln = f_dbrph (yln, l_pgsize)
      @ yln,01 say "NAME                 MILES    DISC      PAI    "+   ;
         "   MISC. 2    FUEL     TAX    DAMAGE   CREDIT   PRV PMT    RECEIVED TYPE DB ACCT"
      yln = f_dbrph (yln, l_pgsize)
      @ yln,01 say "-------------------- ------ --------- -------- "+   ;
         "------------- ------- ------- -------- -------- ---------  -------- ---  --------"
      yln = yln + 1
   endcase
else
   yln = xln + 1
endif
blimempak (-1)
return (yln)


