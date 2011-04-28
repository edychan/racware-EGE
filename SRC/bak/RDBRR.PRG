* ===========================================================================
* this is the routine to display/print DBR.
*
* date: 05/01/91
* author: EDC
*
* revision
* date: 07/16/92
* edc: check "CK" deposit should be treated as cash deposit
* date: 06/30/93
* edc: speed enhancement
* ===========================================================================
private ycctyp, ycashcc, yrecvcc, not_auth_only, yfil
private i, j, yret, yopt, yfnd

l_foutopt = f_confirm ("[D]isplay  [P]rint  [Q]uit","DPQ")
if l_foutopt = "Q"
   return
endif

f_popup("Please Wait While Computing ...",.f.)

ycctyp = ""
ycashcc = ""
yrecvcc = ""
not_auth_only = ""

f_use ("rapaytyp")
do while .not. eof()
   if facctype = "C"
      ycashcc = ycashcc + fpaycode + ";"
      if ftype = 2
         ycctyp = ycctyp + fpaycode + ";"
      endif 
   else
      yrecvcc = yrecvcc + fpaycode + ";"
   endif
   if .not. fauthonly
      not_auth_only = not_auth_only + fpaycode + ";"
   endif
   skip
enddo

f_use ("radbrt")
f_use ("radbrs")
yfil = gstnpath + "radbrs"
copy stru to &yfil
use
use &yfil alias radbrs excl
index on fpaytyp to &yfil

select radbr
f_fupdate ("C")
reclock()
replace fclosed with 0,fdays with 0,fmiles with 0,ftmetot with 0
replace fmlgtot with 0,fdisc with 0,fcred with 0,fothamt with 0
replace fcdw with 0,ftax with 0,fpai with 0,fgas with 0
replace fdamage with 0,fothchgs with 0,ftotal with 0,fprev with 0
replace frecv with 0,fdep with 0,frentals with 0
replace fcash with 0,facctrec with 0

store 0 to l_fclosed,l_fdays,l_fmiles,l_ftmetot
store 0 to l_fmlgtot,l_fdisc,l_fcred,l_fothamt
store 0 to l_fcdw,l_ftax,l_fpai,l_fgas
store 0 to l_fdamage,l_fothchgs,l_ftotal,l_fprev
store 0 to l_frecv,l_fdep,l_frentals
store 0 to l_fcash,l_facctrec

select radbrt
set exact off
set filter to radbrt->frectype > "*"
seek (l_floc+str(l_fdbrno,4))

do while .not. eof() .and. (radbrt->floc = l_floc .and.  ;
      radbrt->fdbrno = l_fdbrno)
   yrectype = frectype
   ycash    = if(radbrt->fpaytyp1+";" $ ycashcc, radbrt->famt1, 0.00) + ;
      if(radbrt->fpaytyp2+";" $ ycashcc, radbrt->famt2, 0.00) + ;
      if(radbrt->fpaytyp3+";" $ ycashcc, radbrt->famt3, 0.00)

   xacctrec = if(radbrt->fpaytyp1+";" $ yrecvcc, radbrt->famt1, 0.00) + ;
      if(radbrt->fpaytyp2+";" $ yrecvcc, radbrt->famt2, 0.00) + ;
      if(radbrt->fpaytyp3+";" $ yrecvcc, radbrt->famt3, 0.00)

   * select radbr
   do case
   case yrectype $ "CF"
      l_fclosed = l_fclosed + 1
      l_fdays = l_fdays+radbrt->fdays
      l_fmiles = l_fmiles+radbrt->fmlg
      l_ftmetot = l_ftmetot+radbrt->ftmetot
      l_fmlgtot = l_fmlgtot+radbrt->fmlgtot
      l_fdisc = l_fdisc+radbrt->fdisctot
      l_fcred = l_fcred+radbrt->fcredtot
      l_fcdw = l_fcdw+radbrt->fcdwtot
      l_ftax = l_ftax+radbrt->ftaxtot
      l_fpai = l_fpai+radbrt->fpaitot
      l_fgas = l_fgas+radbrt->ffueltot
      l_fdamage = l_fdamage+radbrt->fdmgtot
      l_fothamt = l_fothamt+radbrt->fotot1+radbrt->fotot2+radbrt->fotot3+radbrt->fotot4
      l_fothchgs = l_fothchgs+radbrt->fsurchg
      l_ftotal = l_ftotal+radbrt->ftotal
      l_fprev = l_fprev+radbrt->fdepamt
      l_frecv = l_frecv+radbrt->famt1+radbrt->famt2+radbrt->famt3
      l_fcash = l_fcash+ycash
      l_facctrec = l_facctrec+xacctrec
   case yrectype = "D"
      l_frentals = l_frentals + 1
      * edc: check deposit should be treated as cash deposit
      if radbrt->fpaytyp1+";" $ ycctyp
         l_fdep = l_fdep+radbrt->famt1
         l_frecv = l_frecv+radbrt->famt1
         l_fcash = l_fcash+radbrt->famt1
      else
         select radbrt
         skip
         loop
      endif
   case yrectype = "A"
      l_fdep = l_fdep+radbrt->famt1
      l_frecv = l_frecv+radbrt->famt1
      l_fcash = l_fcash+if(radbrt->fpaytyp1+";" $ ycashcc, radbrt->famt1, 0.00)
      l_facctrec = l_facctrec+if(radbrt->fpaytyp1+";" $ yrecvcc, radbrt->famt1, 0.00)
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
reclock ()
replace fclosed with l_fclosed,fdays with l_fdays
replace fmiles with l_fmiles,ftmetot with l_ftmetot
replace fmlgtot with l_fmlgtot,fdisc with l_fdisc
replace fcred with l_fcred,fothamt with l_fothamt
replace fcdw with l_fcdw,ftax with l_ftax,fpai with l_fpai,fgas with l_fgas
replace fdamage with l_fdamage,fothchgs with l_fothchgs
replace ftotal with l_ftotal,fprev with l_fprev
replace frecv with l_frecv,fdep with l_fdep,frentals with l_frentals
replace fcash with l_fcash,facctrec with l_facctrec
commit
unlock
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
seek (l_floc+str(l_fdbrno,4)+"A")
yfnd = .f.
if found ()
   yfnd = .t.
   yln = f_dbrh (yln, l_pgsize, "A")
endif
do while .not. eof() .and. (radbrt->floc = l_floc .and.  ;
      radbrt->fdbrno = l_fdbrno .and. frectype = "A")
   yln = f_dbrh (yln, l_pgsize, "A")
   @yln,01 say str(frano,6)+[ ]+flname+[   ]+str(famt1,7,2)+[ ]+fpaytyp1
   yln = f_dbrh (yln, l_pgsize, "A")
   skip
enddo
if yfnd
   yln = yln + 1
   @ yln, 01 say replicate ("-",130)
endif
yfnd = .f.
seek (l_floc+str(l_fdbrno,4)+"D")
if found ()
   yfnd = .t.
   yln = f_dbrh (yln, 0,"D")
endif
do while .not. eof() .and. (radbrt->floc = l_floc .and.  ;
      radbrt->fdbrno = l_fdbrno .and. frectype = "D")
   yln = f_dbrh (yln, l_pgsize, "D")
   @yln,01 say str(frano,6)+[ ]+flname+[  ]+funit
   if fcdwtot > 0
      @yln,37 say str(fcdwtot,6,2)
   endif
   if fpaitot > 0
      @yln,46 say str(fpaitot,6,2)
   endif
   if fpaytyp1+";" $ ycctyp
      @yln,55 say str(famt1,7,2)+[  ]+fpaytyp1
   endif
   @yln,70 say frloc       
   yln = f_dbrh (yln, l_pgsize, "D")
   skip
enddo
if yfnd
   yln = yln + 1
   @ yln, 01 say replicate ("-",130)
endif
seek (l_floc+str(l_fdbrno,4)+"C")
yfnd = .f.
if found ()
   yfnd = .t.
   yln = f_dbrh (yln, 0,"C")
endif
do while .not. eof() .and. (radbrt->floc = l_floc .and.  ;
      radbrt->fdbrno = l_fdbrno .and. frectype = "C")
   yln = f_dbrh (yln, l_pgsize,"C")
   yotot1 = fotot1+fotot2+fotot3+fotot4
   @yln,01 say str(frano,6)+[ ]+funit+[      ]+str(fdays,4)+[  ]+str(ftmetot+fmlgtot-fdisctot,8,2)+ ;
      [  ]+str(fcdwtot,7,2)+[  ]+str(yotot1,8,2)+[     ]+str(ffueltot,7,2)+[ ]+ ;
      str(ftaxtot,7,2)+[ ]+str(fdmgtot,8,2)+[ ]+str(fcredtot,8,2)+[  ]+ ;
      str(ftotal,8,2)+[  ]+str(famt1,8,2)+[  ]+fpaytyp1+[ ]+fdbacct1
   yln = f_dbrh (yln, l_pgsize,"C")
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
      yln = f_dbrh (yln, l_pgsize,"C")
      @yln,107 say str(famt3,8,2)+[  ]+fpaytyp3
   endif
   yln = f_dbrh (yln, l_pgsize,"C")
   skip
enddo
if yfnd
   yln = yln + 1
   @ yln, 01 say replicate ("-",130)
endif

seek (l_floc+str(l_fdbrno,4)+"F")
yfnd = .f.
if found ()
   yfnd = .t.
   yln = f_dbrh (yln, 0,"F")
endif
do while .not. eof() .and. (radbrt->floc = l_floc .and.  ;
      radbrt->fdbrno = l_fdbrno .and. frectype = "F")
   yln = f_dbrh (yln, l_pgsize,"F")
   @yln,01 say "Check-out: "+floc+"  "+"Check-in: "+frloc
   yln = f_dbrh (yln, l_pgsize,"F")
   yotot1 = fotot1+fotot2+fotot3+fotot4
   @yln,01 say str(frano,6)+[ ]+funit+[      ]+str(fdays,4)+[  ]+str(ftmetot+fmlgtot-fdisctot,8,2)+ ;
      [  ]+str(fcdwtot,7,2)+[  ]+str(yotot1,8,2)+[     ]+str(ffueltot,7,2)+[ ]+ ;
      str(ftaxtot,7,2)+[ ]+str(fdmgtot,8,2)+[ ]+str(fcredtot,8,2)+[  ]+ ;
      str(ftotal,8,2)+[  ]+str(famt1,8,2)+[  ]+fpaytyp1+[ ]+fdbacct1
   yln = f_dbrh (yln, l_pgsize,"F")
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
      yln = f_dbrh (yln, l_pgsize,"F")
      @yln,107 say str(famt3,8,2)+[  ]+fpaytyp3
   endif
   yln = f_dbrh (yln, l_pgsize, "F")
   skip
enddo
if yfnd
   yln = yln + 1
   @ yln, 01 say replicate ("-",130)
endif

seek (l_floc+str(l_fdbrno,4)+"T")
yfnd = .f.
if found ()
   yfnd = .t.
   yln = f_dbrh (yln, 0, "T")
endif
do while .not. eof() .and. (radbrt->floc = l_floc .and.  ;
      radbrt->fdbrno = l_fdbrno .and. frectype = "T")
   yln = f_dbrh (yln, l_pgsize,"T")
   @yln,01 say "Check-out: "+frloc+"  "+"Check-in: "+floc
   yln = f_dbrh (yln, l_pgsize,"T")
   yotot1 = fotot1+fotot2+fotot3+fotot4
   @yln,01 say str(frano,6)+[ ]+funit+[      ]+str(fdays,4)+[  ]+str(ftmetot+fmlgtot-fdisctot,8,2)+ ;
      [  ]+str(fcdwtot,7,2)+[  ]+str(yotot1,8,2)+[     ]+str(ffueltot,7,2)+[ ]+ ;
      str(ftaxtot,7,2)+[ ]+str(fdmgtot,8,2)+[ ]+str(fcredtot,8,2)+[  ]+ ;
      str(ftotal,8,2)+[  ]+str(famt1,8,2)+[  ]+fpaytyp1+[ ]+fdbacct1
   yln = f_dbrh (yln, l_pgsize,"T")
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
      yln = f_dbrh (yln, l_pgsize,"T")
      @yln,107 say str(famt3,8,2)+[  ]+fpaytyp3
   endif
   yln = f_dbrh (yln, l_pgsize,"T")
   skip
enddo
if yfnd
   yln = yln + 1
   @ yln, 01 say replicate ("-",130)
endif

select radbrt
set filter to
seek (l_floc+str(l_fdbrno,4)+"*")
yfnd = .f.
if found ()
   yfnd = .t.
   yln = f_dbrh (yln, 0,"*")
endif
do while .not. eof() .and. (radbrt->floc = l_floc .and.  ;
      radbrt->fdbrno = l_fdbrno .and. frectype = "*")
   yln = f_dbrh (yln, l_pgsize,"*")
   yotot1 = fotot1+fotot2+fotot3+fotot4
   @yln,01 say str(frano,6)+[ ]+funit+[      ]+str(fdays,4)+[  ]+str(ftmetot+fmlgtot-fdisctot,8,2)+ ;
      [  ]+str(fcdwtot,7,2)+[  ]+str(yotot1,8,2)+[     ]+str(ffueltot,7,2)+[ ]+ ;
      str(ftaxtot,7,2)+[ ]+str(fdmgtot,8,2)+[ ]+str(fcredtot,8,2)+[  ]+ ;
      str(ftotal,8,2)+[  ]+str(famt1,8,2)+[  ]+fpaytyp1+[ ]+fdbacct1
   yln = f_dbrh (yln, l_pgsize, "*")
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
      yln = f_dbrh (yln, l_pgsize,"*")
      @yln,107 say str(famt3,8,2)+[  ]+fpaytyp3
   endif
   yln = yln + 1                         
   @ yln, 01 say replicate ("-",130)     
   skip
enddo
if yfnd
   yln = yln + 1
   @ yln, 01 say replicate ("-",130)
endif

select radbrt
use

select radbr
yln=f_dbrh (yln+1, l_pgsize)
@yln,55 say "**  D B R   T O T A L S  **"
yln=f_dbrh (yln, l_pgsize)
@yln,01 say "                   DAYS/    T&M/      CDW/      MISC. 1   /"+  ;
   "                                            TOTAL/"
yln=f_dbrh (yln, l_pgsize)
@yln,01 say "CHECKOUTS CHECKINS MILES    DISC      PAI       MISC. 2     "+  ;
   "FUEL    TAX     DAMAGE   CREDIT   DEPOSIT  PRV PMT   RECEIVED  "
yln=f_dbrh (yln, l_pgsize)
@yln,01 say "--------- -------- ------ --------- -------- -------------- "+  ;
   "------ -------- -------- -------- -------- --------- --------- "
yln=f_dbrh (yln, l_pgsize)
* 01.05.98 increase field length for tax, total recv
@yln,02 say str(frentals,4)+space(7)+str(fclosed,4)+[    ]+str(fdays,4)+[  ]+ ;
   str(ftmetot+fmlgtot-fdisc,9,2)+[ ]+str(fcdw,8,2)+[ ]+str(fothamt,8,2)+space(6)+  ;
   str(fgas,7,2)+[ ]+str(ftax,8,2)+[ ]+str(fdamage,8,2)+[ ]+       ;
   str(fcred,8,2)+[ ]+str(fdep,8,2)+[ ]+str(ftotal,9,2)+[ ]+     ;
   str(frecv,9,2)
yln=f_dbrh (yln, l_pgsize)
@yln,19 say str(fmiles,6)
if fdisc > 0
   @yln,29 say str(fdisc,7,2)
endif
@yln,37 say str(fpai,8,2)
if fothchgs > 0
   @yln,46 say str(fothchgs,8,2)
endif
if fprev > 0
   @yln,105 say str(fprev,8,2)
endif
yln = f_dbrh (yln+1, l_pgsize)
@ yln, 01 say replicate ("-",130)

select radbrs
index on facctype to (gstnpath+"radbrs2")
go top
yfnd = .f.
if .not. eof()
   yfnd = .t.
   yln = f_dbrh (l_pgsize+1, l_pgsize)
   @yln,55 say "**  R E V E N U E    S U M M A R Y  **"
   yln = f_dbrh (yln+1, l_pgsize)
   @yln,28 say "RECEIVED     DUE FROM     DUE TO      REVENUE  "
   yln = f_dbrh (yln, l_pgsize)
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
      yln = f_dbrh (yln, l_pgsize)
      @yln,28 say "----------   ----------   ----------  ---------"
      yln = f_dbrh (yln, l_pgsize)
      @yln,01 say trim(l_val)+" TOTALS:"
      @yln,29 say str(l_deposit,9,2)
      @yln,42 say str(l_duefrom,8,2)
      @yln,55 say str(l_dueto,8,2)
      @yln,66 say str(l_recv,9,2)
      yln = f_dbrh (yln, l_pgsize)
      @yln,28 say "==========   ==========   ==========  ========="
      yln = f_dbrh (yln, l_pgsize)
      l_val = radbrs->facctype
      l_deposit=0
      l_duefrom=0
      l_dueto=0
      l_recv=0
   endif
   yln = f_dbrh (yln, l_pgsize)
   @yln,01 say fpaytyp+[ ]+fdesc
   @yln,29 say str(fdeposit,9,2)
   @yln,42 say str(fduefrom,8,2)
   @yln,55 say str(fdueto,8,2)
   @yln,66 say str(frecv,9,2)
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
yln = f_dbrh (yln, l_pgsize)
@yln,28 say "----------   ----------   ----------  ---------"
yln = f_dbrh (yln, l_pgsize)
@yln,01 say trim(l_val)+" TOTALS:"
@yln,29 say str(l_deposit,9,2)
@yln,42 say str(l_duefrom,8,2)
@yln,55 say str(l_dueto,8,2)
@yln,66 say str(l_recv,9,2)
yln = f_dbrh (yln, l_pgsize)
@yln,28 say "==========   ==========   ==========  ========="
yln = f_dbrh (yln+1, l_pgsize)
@yln,42 say "TOTAL REVENUE"
@yln,66 say str(l_trecv,9,2)
yln = f_dbrh (yln, l_pgsize)
@yln,42 say "PLUS PREV PAYMENT"
@yln,66 say str(radbr->fprev,9,2)
yln = f_dbrh (yln, l_pgsize)
@yln,42 say "LESS CASH DEPOSIT"
@yln,66 say str(radbr->fdep,9,2)
yln = f_dbrh (yln, l_pgsize)
@yln,66 say "---------"
yln = f_dbrh (yln, l_pgsize)
@yln,42 say "NET REVENUE"
@yln,66 say str(l_trecv+radbr->fprev-radbr->fdep,9,2)
yln = f_dbrh (yln, l_pgsize)
@yln,66 say "========="

select radbrs
use
select radbr
use
select rapaytyp
use
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
close database


******************************
function f_dbrh

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
   @ 02,60 say "#" + str(l_fdbrno,4)+[ - ]+dtoc(radbr->frptdate)
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
      yln = f_dbrh (yln+1, l_pgsize)
      @yln,01 say "RA#     NAME            UNIT #       CDW      PAI     DEPOSIT        CHECK-IN"
      yln = f_dbrh (yln, l_pgsize)
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
      yln = f_dbrh (yln, l_pgsize)
      @ yln,01 say "NAME                 MILES    DISC      PAI    "+   ;
         "   MISC. 2    FUEL     TAX    DAMAGE   CREDIT   PRV PMT    RECEIVED TYPE DB ACCT"
      yln = f_dbrh (yln, l_pgsize)
      @ yln,01 say "-------------------- ------ --------- -------- "+   ;
         "------------- ------- ------- -------- -------- ---------  -------- ---  --------"
      yln = yln + 1
   endcase
else
   yln = xln + 1
endif
blimempak (-1)
return (yln)

