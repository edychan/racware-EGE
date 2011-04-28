* ===========================================================================
* post DBR - create G/L & A/R transactions
*
* date: 05/01/91
* author: edc
*
* revision
* date: 03/24/93
* edc: change description for G/L & A/R entries 
* ----------------------------------------------------------------------
* 10.15.08: add 2 add'l charge 5 & 6
* ===========================================================================
parameter xfloc, xfdbrno, xok

xok = .t.

f_popup ("Checking Interface Setup ...")
f_use ("raloc")
seek xfloc
if eof ()
   xok = .f.
   f_valid (.f.,"Missing Location Setup ...")
   return
endif
yglpost = raloc->fglpost
yarpost = raloc->farpost
use
if .not. yglpost .and. .not. yarpost   
   xok = .t.
   return
endif

ntypes = 0             
private ytyp[20]       
private ycust[20]
private yacct[20]      
private yloc[20]       
private yamt[20]       
private yamtto[20]     

noitem = 0             
private yoacc[20]      
private yoamt[20]      
private yotyp[20]      

ycashcc = ""           
yrecvcc = ""           
xfrptdate = radbr->frptdate

f_use ("rapaytyp")
go top
if eof ()
   xok = .f.
   f_valid (.f.,"Missing Payment Type Setup ...")
   return
endif
do while .not. eof()
   if facctype = "C"
      ycashcc = ycashcc + fpaycode + ";"
   else
      yrecvcc = yrecvcc + fpaycode + ";"
   endif
   skip
enddo

f_use ("raglacc")
if eof ()
   xok = .f.
   f_valid (.f.,"Invalid Account Setup ...")
   return
endif

f_use ("rapaycd")
f_popup ("Totalling receipts ...")

tempdbf  = gstnpath+"RAARTRS.DBF"
tempdbf2 = gstnpath+"RAGLTRS.DBF"

if yarpost
   f_use ("raartrs")
   copy structure to &tempdbf
   use &tempdbf excl alias raartrs
endif

f_use ("radbrt")
set exact off
set filter to frectype > '*'
seek upper(xfloc+str(xfdbrno,4))

do while (.not. eof() .and. floc = xfloc .and. fdbrno = xfdbrno)
   do krdbrp1a with radbrt->fpaytyp1,radbrt->famt1,radbrt->fdbacct1
   do krdbrp1a with radbrt->fpaytyp2,radbrt->famt2,radbrt->fdbacct2
   do krdbrp1a with radbrt->fpaytyp3,radbrt->famt3
   if .not. xok
      f_valid (.f.,"Process Aborted ...")
      return
   endif
   if radbrt->frectype $ "CF"       
      * -- 10.15.08
      do krdbrp1d with radbrt->foitem1,radbrt->fotot1
      do krdbrp1d with radbrt->foitem2,radbrt->fotot2
      do krdbrp1d with radbrt->foitem3,radbrt->fotot3
      do krdbrp1d with radbrt->foitem4,radbrt->fotot4
      do krdbrp1d with radbrt->foitem5,radbrt->fotot5
      do krdbrp1d with radbrt->foitem6,radbrt->fotot6
      * --
      do krdbrp1d with "SURC",radbrt->fsurchg

      if .not. xok
         f_valid (.f.,"Process Aborted ...")
         return
      endif
   endif
   select radbrt
   skip
enddo
select radbrt
use

xftme = space(10)
xfmlg = space(10)
xfcdw = space(10)
xfpai = space(10)
xftax = space(10)
xfgas = space(10)
xfdamage = space(10)
xfcredit = space(10)
xfdisc = space(10)
xfdeposit = space(10)
xfintrloc = space(10)

do krdbrp1c with "TIME"      ,"TME",xftme,xok
do krdbrp1c with "MILEAGE"   ,"MLG",xfmlg,xok
do krdbrp1c with "CDW"       ,"CDW",xfcdw,xok
do krdbrp1c with "PAI"       ,"PAI",xfpai,xok
do krdbrp1c with "SALES TAX" ,"TAX",xftax,xok
do krdbrp1c with "FUEL"      ,"GAS",xfgas,xok
do krdbrp1c with "DAMAGE"    ,"DMG",xfdamage,xok
do krdbrp1c with "CREDITS"   ,"CR" ,xfcredit,xok
do krdbrp1c with "DISCOUNTS" ,"DIS",xfdisc,xok
do krdbrp1c with "DEPOSITS"  ,"DEP",xfdeposit,xok
do krdbrp1c with "INTER LOC" ,"LOC",xfintrloc,xok
if .not. xok
   f_valid (.f.,"Process Aborted ...")
   return
endif
f_popup ("Writing to Transaction File ...")

f_use ("ragltrs")
copy structure to &tempdbf2
use &tempdbf2 excl alias ragltrs

ymth = substr(dtoc(xfrptdate),7,2)+substr(dtoc(xfrptdate),1,2)
* 03/24/93: edc: change description
* ydesc = "DBR #"+ltrim(str(xfdbrno))+" "+xfloc+" "+dtoc(xfrptdate)
ydesc = "#"+ltrim(str(xfdbrno))+" "+trim(xfloc)+" "+dtoc(xfrptdate)
do krdbrp1b with xftme,0,(radbr->ftmetot),ydesc,"TIME"
do krdbrp1b with xfmlg,0,(radbr->fmlgtot),ydesc,"MILEAGE"
do krdbrp1b with xfcdw,0,(radbr->fcdw),ydesc,"CDW"
do krdbrp1b with xfpai,0,(radbr->fpai),ydesc,"PAI"
do krdbrp1b with xftax,0,(radbr->ftax),ydesc,"SALES TAX"
do krdbrp1b with xfgas,0,(radbr->fgas),ydesc,"FUEL"
do krdbrp1b with xfdamage,0,(radbr->fdamage),ydesc,"DAMAGE"
do krdbrp1b with xfcredit,(radbr->fcred),0,ydesc,"CREDITS"
do krdbrp1b with xfdisc,(radbr->fdisc),0,ydesc,"DISCOUNTS"
do krdbrp1b with xfdeposit,0,(radbr->fdep),ydesc,"RECVD DEPS"
do krdbrp1b with xfdeposit,(radbr->fprev),0,ydesc,"APPLD DEPS"

for i = 1 to noitem
   do krdbrp1b with yoacc[i],0,yoamt[i],ydesc,yotyp[i]
next i

for i = 1 to ntypes
   if xfloc <> yloc[I]
      do krdbrp1b with xfintrloc,yamt[I],0,ydesc,ytyp[I]+" FR "+yloc[I]
      do krdbrp1b with yacct[I],yamtto[I],0,ydesc,ytyp[I]+" TO "+yloc[I]
      do krdbrp1b with xfintrloc,0,yamtto[I],ydesc,ytyp[I]+" TO "+yloc[I]
   else
      do krdbrp1b with yacct[I],yamt[I],0,ydesc,ytyp[I]
   endif
next I

select ragltrs
sum all ftrsamt to ybal
use

if yarpost        
   select raartrs
   use
endif

if notzero(ybal)
   f_valid (.f.,"ERROR: DBR is out of balance by $"+ltrim(str(ybal,11,2)))
   xok = .f.
   return
endif

set excl on
f_use ("ragltrs")
append from &tempdbf2
use
set excl off

if yarpost
   set excl on
   f_use ("raartrs")
   append from &tempdbf
   use
   set excl off
endif

select radbr
return


******************************
procedure krdbrp1a

parameters xtyp,xamt,xcustno

if xamt = 0 .or. empty(xtyp)
   return
endif

if pcount () < 3
   xcustno=space(6)
endif

xloc = if(radbrt->frectype $ "FT", radbrt->frloc, xfloc)
n = 1
do while n <= ntypes
   if (xtyp = ytyp[n] .and. xloc = yloc[n])
      exit
   endif
   n = n+1
enddo

if n > ntypes
   ntypes = n
   ytyp[n] = xtyp
   yloc[n] = xloc
   yamt[n] = 0.00
   yamtto[n] = 0.00
   select rapaytyp
   locate for fpaycode = xtyp
   if eof ()
      xok = .f.
      f_valid (.f.,"Invalid Payment Type: "+xtyp)
      return
   elseif empty(rapaytyp->faccno)
      xok = .f.
      f_valid (.f.,"Missing Account Setup: "+xtyp)
      return
   else
      xcustno = if(empty(xcustno),rapaytyp->fcustno,xcustno)
      ycust[n] = xcustno
      yacct[n] = rapaytyp->faccno
   endif
else
   xcustno = if(empty(xcustno),ycust[n],xcustno)
endif
if radbrt->frectype = "T"
   yamtto[n] = round(yamtto[n] + xamt,2)
else
   yamt[n] = round(yamt[n] + xamt,2)
   if xtyp $ yrecvcc .and. yarpost
      if empty (xcustno)
         f_valid (.f.,"Missing DB Acct. # for RA: "+str(radbrt->frano,6))
         xok =.f.
         return
      else
         do krdbrp1e with xcustno,xtyp,xamt,yacct[n]
      endif
   endif
endif

return


******************************
procedure krdbrp1b

parameters acctno,debit,credit,desc,ref

if debit <> 0 .or. credit <> 0
   select ragltrs
   append blank
   replace floc with xfloc, fdbrno with xfdbrno
   replace faccno with acctno,ftrsdes with desc,ftrsref with ref
   replace ftrsdate with dtoc(date()),ftrsmth with ymth,ftrsid with "1"
   replace ftrsamt with if(debit<>0,debit,-credit), fpost with "O"
endif

return

******************************
procedure krdbrp1c

parameters xdesc,xpaycd,xaccno,xok

select raglacc
locate for fcode = xpaycd
if eof ()
   f_valid (.f.,"Missing Revenue Type: "+xpaycd)
   xok = .f.
elseif empty(raglacc->faccno)
   xok = .f.
   f_valid (.f.,"Missing Account Setup: "+xpaycd)
else
   xok = .t.
   xaccno = raglacc->faccno
endif


******************************
procedure krdbrp1d

parameters xtyp,xamt

if xamt = 0 .or. empty(xtyp)
   return
endif

n = 1
do while n <= noitem
   if xtyp = yotyp[n]
      exit
   endif
   n = n+1
enddo

if n > noitem
   noitem = n
   yotyp[n] = xtyp
   yoamt[n] = 0.00
   select rapaycd
   seek xtyp
   if eof ()
      xok = .f.
      f_valid (.f.,"Invalid Misc. Charge Code: "+xtyp)
      return
   elseif empty(rapaycd->faccno)
      xok = .f.
      f_valid (.f.,"Missing Account Setup: "+xtyp)
      return
   else
      yoacc[n] = rapaycd->faccno
   endif
endif
yoamt[n] = yoamt[n] + xamt

return


******************************
procedure krdbrp1e

parameters lcustno,ltyp,lamt,lacctno
private lsono, lstatus, ldesc, ltnm, ldis

lsono = xfloc
lstatus = str(radbrt->frano,6)
if ltyp = "DBC"
   ldis = -2             
elseif ltyp = "DB "
   ldis = -1             
else
   ldis = 0              
endif
* ldesc = "("+trim(ltyp)+") "+trim(xfloc)+"/"+ltrim(str(xfdbrno))+" "+;
*   "RA #"+ltrim(str(radbrt->frano,6))+" "+trim(radbrt->flname)
* 03/24/93: change the description for invoices
ldesc = "("+trim(ltyp)+") "+trim(xfloc)+"/"+;
    "RA #"+ltrim(str(radbrt->frano,6))+" "+trim(radbrt->flname)
ltnm  = radbrt->ftmetot+radbrt->fmlgtot-radbrt->fdisctot
select raartrs
append blank
reclock ()
replace floc with xfloc, fdbrno with xfdbrno
replace fitemno with lacctno, fpost with "O"
replace fcustno with lcustno,fshipdate with dtoc(xfrptdate)
replace fdescript with ldesc,fprice with lamt,fcost with ltnm
replace fsono with lsono, fstatus with lstatus, fdisrate with ldis
commit
unlock

select radbrt
return

