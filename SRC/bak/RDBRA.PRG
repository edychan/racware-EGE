* ===========================================================================
* audit dbr
*
* date: 05/01/91
* author: edc
*
* revision
* date: 01/14/93
* edc: add input field for location id
* date: 02/01/93
* edc: validate paycode if pay amount > 0
* date: 03/30/93
* edc:  save direct bill info. back to raagrh
* date: 03/02/94
* edc: special case for resv. deposit. (ra#=999999)
* date: 08/11/94
* edc: proc error using help function for misc charges
* date: 10/20/94
* edc: make sure dbrt record is balanced before user can exit
* date: 12/15/98
* edc: update cdw total and credit total to raagrh
* ===========================================================================
private yret, yscn, ychg
declare ytyp [3], yamt [3], yccrec [3], ycccap [3]
declare yccnum [3], yccexp [3], yrectype [3], yauthonly [3]
yauth = .f.
afill (yccnum, space (20))
afill (yccexp, "  /  ")
afill (yrectype, 0)
afill (yauthonly, .f.)

ychg = .f.
l_dbrno = l_fdbrno
l_dbrloc = l_floc
l_fbal=0.00
l_ftnm=0.00
f_popup ("Please Wait ...")
set key 28 to rdbrahlp
f_use ("raagrh")
f_use ("racrp")
f_use ("racred")
f_use ("raagr")
f_use ("radbrt")
f_popback()
set filter to frectype <> "*" 
go top
set exact off
do while .t.
   f_getscn ("RADBRA")
   yret = f_confirm ("[A]dd Record  [U]pdate Record  [D]elete Record  "+   ;
      "[Q]uit","AUDQ")
   do case
   case yret = "Q"
      exit
   case yret $ "UD"
      rest from (gmempath+"radbrt") additive
      l_floc = l_dbrloc
      l_fdbrno = l_dbrno
      l_loc = l_dbrloc
      @ 02,17 say trim(l_floc)+[-]+str(l_fdbrno,4)
      @ 03,17 get l_frectype picture [!] valid f_valid(l_frectype $ "ACDFT")
      @ 04,17 get l_loc picture [!!!!!!!!!!]   && 01/14/93
      @ 04,27 say [-]
      @ 04,28 get l_frano picture [999999] 
      *@ 04,28 get l_frano picture [999999] valid f_valid(f_verify("radbrt",1,   ;
      *          l_floc+str(l_fdbrno,4)+l_frectype+str(l_frano,6)))
      if f_rd() = 27 
         loop
      endif
      select radbrt
      set softseek on
      seek l_dbrloc+str(l_dbrno,4)+l_frectype+str(l_frano,6)
      set softseek off
      if .not. f_pick_f (03, 10, "", "DBR # TYPEÄÄÄÄÄÄÄ-RA #ÄÄÄÄÄÄÄLAST NAME ÄÄÄÄUNIT #", ;
            "str(fdbrno,4)+[   ]+frectype+[   ]+if(frectype='T',frloc,floc)+str(frano,6)+[  ]+flname+" ;
            +"[ ]+funit","","floc+str(fdbrno,4)","l_dbrloc+str(l_dbrno,4)")
         loop
      endif
      l_loc = if(radbrt->frectype='T',radbrt->frloc,radbrt->floc)
      if radbrt->frectype $ "CFT" .and. radbrt->frano <> 999999     && 03/01/94:edc
         select raagrh
         seek l_loc+str(radbrt->frano,6)
         if eof()
            f_valid (.f.,"RA does not exists ...")
            loop
         endif
      endif
      select radbrt
      f_retrieve ()
      l_frloc = if(l_frectype="T", l_floc, l_frloc)  && edc: 01/15/93
      @ 02,17 say trim(l_floc)+[-]+str(l_fdbrno,4)
      @ 03,17 say l_frectype 
      @ 04,17 say l_loc 
      @ 04,27 say [-]
      @ 04,28 say l_frano
      f_dbrget ()
      if yret = "D"
         clear gets
         if f_confirm ("Are you sure? [Y/N]", "YN") = "Y"
            ychg=.t.
            f_popup ("Please Wait ...")
            f_fupdate ("C")
            reclock ()
            replace frectype with "*", flname with "**DELETED**"
            commit
            unlock
            if l_frectype $ "CFT" .and. l_frano <> 999999     && 03/01/94:edc
               select raagrh
               seek l_loc+str(l_frano,6)
               if found()
                  f_fupdate ("C")
                  reclock ()
                  replace fdbrno with 0
                  commit
                  unlock
               endif
            endif
            select radbrt
            f_popback ()
         endif
         loop
      endif
      if l_frectype $ "CFT" .and. l_frano <> 999999     && 03/01/94:edc
         ytyp [1] = l_fpaytyp1
         ytyp [2] = l_fpaytyp2
         ytyp [3] = l_fpaytyp3
         yamt [1] = l_famt1
         yamt [2] = l_famt2
         yamt [3] = l_famt3
         afill (yccrec, 0)
         afill (ycccap, .f.)
   
         f_use ("racred", 1)
         set filter to .not. (ftranstyp $ "XD")
         yloc = if (l_frectype = "T", l_frloc, l_floc)
         seek yloc + str (l_frano, 6)
         do while yloc = floc .and. l_frano = frano .and. .not. eof ()
            yfnd = .f.
            for n = 1 to 3
               if yccrec [n] = 0 .and. ytyp [n] = fcctype .and. ;
                     yamt [n] = fauthamt
                  yccrec [n] = recno ()
                  ycccap [n] = (frectype = __gcccap)
                  yccnum [n] = fccnum
                  yccexp [n] = fccexp
                  yauthonly [n] = fauthonly
                  yfnd = .t.
                  exit
               endif
            next
            if .not. yfnd
               f_fupdate ("D")
               reclock ()
               delete
               unlock
            endif
            skip
         enddo
      endif
      select radbrt
      do while .t.
         f_rd ()
         * 10/20/94 edc: update l_ftotal in case of [PGDN]
         l_ftotal = l_ftmetot+l_fmlgtot-l_fdisctot-l_fcredtot+l_fotot1+l_fotot2 ;
             +l_fotot3+l_fotot4+l_fsurchg+l_fcdwtot+l_fpaitot+l_ffueltot+l_fdmgtot ;
             +l_ftaxtot
         *
         yopt = f_confirm ("[C]onfirm   [E]dit   [I]gnore Changes","CEI")
         if yopt = "C"
            if (notzero (l_famt1).and.empty(l_fpaytyp1))
               f_valid(.f.,"Missing Payment Type 1 ...")
               loop
            elseif (notzero (l_famt2).and.empty(l_fpaytyp2))
               f_valid(.f.,"Missing Payment Type 2 ...")
               loop
            elseif (notzero (l_famt3).and.empty(l_fpaytyp3))
               f_valid(.f.,"Missing Payment Type 3 ...")
               loop
            endif
            if l_frectype $ "CFT" .and. ;
                  notzero (l_ftotal-(l_famt1+l_famt2+l_famt3+l_fdepamt))
               f_valid(.f.,"Out of Balance ...")
               loop
            endif
            select radbrt
            f_fupdate ("C")
            reclock()
            replace frectype with "*"
            commit
            unlock
            if l_frectype $ "CFT" .and. l_frano <> 999999     && 03/01/94:edc
               rdbrar ()
               f_dbraf5 ()      && edc: 01/15/93 update raagrh first
            endif
            f_findblank ()
            ** edc: take care of T (to) trans.
            l_frloc = if (l_frectype="T", l_loc, l_frloc)
            f_replace ()
            f_fupdate ("A")
            ychg = .t.
            exit
         elseif yopt = "E"
            f_dbrget ()
            loop
         else
            exit
         endif
      enddo
   case yret = "A"
      rest from (gmempath+"radbrt") additive
      l_floc = l_dbrloc
      l_fdbrno = l_dbrno
      l_loc = l_dbrloc
      yflg = .f.
      do while .t.
         @ 02,17 say trim(l_floc)+[-]+str(l_fdbrno,4)
         @ 03,17 get l_frectype picture [!] valid f_valid(l_frectype $ "ACDFT")
         @ 04,17 get l_loc picture [!!!!!!!!!!] valid ;       && 01/14/93
                 f_valid(if(l_frectype$"ACDF", l_loc=l_floc, l_loc<>l_floc))
         @ 04,27 say [-]
         @ 04,28 get l_frano picture [999999]
         if f_rd() = 27 
            yflg = .t.
            exit
         endif
         select radbrt
         seek l_floc+str(l_fdbrno,4)+l_frectype+str(l_frano,6)
         if found()
            f_valid (.f.,"Record Exists Already ...")
            loop
         endif
         if l_frectype $ "CFT"
            select raagrh
            seek l_loc+str(l_frano,6)
            if found()
               if raagrh->fdbrno > 0 .and. raagrh->fdbrno <> l_fdbrno .and. ;
                     l_frectype = "C"
                  f_valid (.f.,"RA reported in DBR #"+str(raagrh->fdbrno,4)+" ...")
                  loop
               else
                  l_flname = raagrh->flname
                  l_frloc = raagrh->frloc
                  l_funit = raagrh->funit
                  l_fdays = raagrh->fdays
                  l_ftmetot = raagrh->ftmetot
                  l_fmlgtot = raagrh->fmlgtot
                  l_fdisctot = raagrh->fdisctot
                  l_fcredtot = raagrh->fcredtot
                  l_fcdwtot = raagrh->fcdwtot
                  l_ftaxtot = raagrh->ftaxtot
                  l_fpaitot = raagrh->fpaitot
                  l_ffueltot = raagrh->ffueltot
                  l_fdmgtot = raagrh->fdmgtot
                  l_foitem1 = raagrh->foitem1
                  l_foitem2 = raagrh->foitem2
                  l_foitem3 = raagrh->foitem3
                  l_foitem4 = raagrh->foitem4
                  l_fotot1 = raagrh->fotot1
                  l_fotot2 = raagrh->fotot2
                  l_fotot3 = raagrh->fotot3
                  l_fotot4 = raagrh->fotot4
                  l_fsurchg = raagrh->fsurchg
                  l_ftotal = raagrh->ftotal
                  l_fdepamt = raagrh->fdepamt
                  l_fpaytyp1 = raagrh->fpaytyp1
                  l_famt1 = raagrh->famt1
                  l_fpaytyp2 = raagrh->fpaytyp2
                  l_famt2 = raagrh->famt2
                  l_fpaytyp3 = raagrh->fpaytyp3
                  l_famt3 = raagrh->famt3
                  ** edc: 01/15/93
                  l_fdbacct1 = raagrh->fdbacct1
                  l_fdbacct2 = raagrh->fdbacct2
               endif
            else
               f_valid (.f.,"RA does not exists ...")
               loop
            endif
         else
            select raagr
            seek l_loc+str(l_frano,6)
            if found ()
               l_floc = l_loc
               l_fdbrno = l_dbrno
               l_frloc = frloc
               l_flname = flname
               l_funit = funit
               l_fpaytyp1 = fpaytyp1
               l_famt1 = fdepamt
            else
               ** add check-outs without looking at the raagr.dbf  03/11/94
               l_floc = l_loc
               l_fdbrno = l_dbrno
               l_frloc = l_loc
               l_flname = space (14)
               l_funit = space (10)
               l_fpaytyp1 = space(3)
               l_famt1 = 0.00
            endif
         endif
         exit
      enddo
      if yflg
        loop
      endif
      ytyp [1] = l_fpaytyp1
      ytyp [2] = l_fpaytyp2
      ytyp [3] = l_fpaytyp3
      yamt [1] = l_famt1
      yamt [2] = l_famt2
      yamt [3] = l_famt3
      afill (yccrec, 0)
      afill (ycccap, .f.)
      f_use ("racred", 1)
      set filter to .not. (ftranstyp $ "XD")
      yloc = if (l_frectype = "T", l_frloc, l_floc)
      seek yloc + str (l_frano, 6)
      do while yloc = floc .and. l_frano = frano .and. .not. eof ()
         yfnd = .f.
         for n = 1 to 3
            if yccrec [n] = 0 .and. ytyp [n] = fcctype .and. ;
                  yamt [n] = fauthamt
               yccrec [n] = recno ()
               ycccap [n] = (frectype = __gcccap)
               yccnum [n] = fccnum
               yccexp [n] = fccexp
               yauthonly [n] = fauthonly
               yfnd = .t.
               exit
            endif
         next
         if .not. yfnd
            f_fupdate ("D")
            reclock ()
            delete
            unlock
         endif
         skip
      enddo
      do while .t.
         select radbrt
         f_dbrget ()
         f_rd ()
         * 10/20/94 edc: update l_ftotal in case of [PGDN]
         l_ftotal = l_ftmetot+l_fmlgtot-l_fdisctot-l_fcredtot+l_fotot1+l_fotot2 ;
             +l_fotot3+l_fotot4+l_fsurchg+l_fcdwtot+l_fpaitot+l_ffueltot+l_fdmgtot ;
             +l_ftaxtot
         *
         yopt = f_confirm ("[C]onfirm   [E]dit   [V]oid ","CEV")
         if yopt = "C"
            if (notzero (l_famt1) .and.empty(l_fpaytyp1))
               f_valid(.f.,"Missing Payment Type 1 ...")
               loop
            elseif (notzero(l_famt2) .and.empty(l_fpaytyp2))
               f_valid(.f.,"Missing Payment Type 2 ...")
               loop
            elseif (notzero(l_famt3) .and.empty(l_fpaytyp3))
               f_valid(.f.,"Missing Payment Type 3 ...")
               loop
            endif
            if l_frectype $ "CFT" .and. ;
                  notzero (l_ftotal-(l_famt1+l_famt2+l_famt3+l_fdepamt))
               f_valid(.f.,"Out of Balance ...")
               loop
            endif
            if l_frectype $ "CFT" .and. l_frano <> 999999     && 03/01/94:edc
                rdbrar ()
                f_dbraf5 ()      && edc: 01/15/93 update raagrh first
            endif
            f_findblank ()
            ** edc: take care of t (to) trans.
            l_frloc = if (l_frectype="T", l_loc, l_frloc)
            f_replace ()
            f_fupdate ("A")
            ychg = .t.
            exit
         elseif yopt = "E"
            loop
         else
            exit
         endif
      enddo
   endcase
enddo

select radbr
if ychg
   f_fupdate ("C")
   reclock()
   replace ftotal with 0.00         
   replace fauddate with date()
   commit
   unlock
endif

set key 28 to
release all like l_*
close databases
return


******************************
procedure rdbrahlp

private yvar, yarray[5], yptr

yvar = alltrim (upper(readvar()))
do case
case yvar = "L_FRECTYPE"
   yarray[1] = " A - Additional Deposit    "
   yarray[2] = " C - Closed Contract       "
   yarray[3] = " D - Deposit               "
   yarray[4] = " F - From location Revenue "
   yarray[5] = " T - To Location Revenue   "
   yptr = 1
   yptr = f_pick_a (05,32,"","",yarray,5,yptr)
   if yptr > 0
      &yvar = substr(yarray[yptr],2,1)
      keyboard chr(13)
   endif
*case yvar = "L_LOC" 
*   select radbrt
*   seek l_floc+str(l_fdbrno,4)+l_frectype
*   if f_valid (.not. eof (), "No [" + l_frectype + "] found...")
*      if f_pick_f (03, 10, "", "DBR # TYPEÄÄÄÄÄÄÄ-RA #ÄÄÄÄÄÄÄLAST NAME ÄÄÄÄUNIT #", ;
*            "str(fdbrno,4)+{   ]+frectype+[   ]+if(frectype='T',frloc,floc)+str(frano,6)+[  ]+flname+" ;
*            +"[ ]+funit","","floc+str(fdbrno,4)","l_floc+str(l_fdbrno,4)")
*         l_loc = if(radbrt->frectype="T", radbrt->frloc, radbrt->floc)
*         l_frano = radbrt->frano
*      endif
*   endif
*case yvar = "L_FRANO"
*   select radbrt
*   seek l_floc+str(l_fdbrno,4)+l_frectype
*   if f_valid (.not. eof (), "No [" + l_frectype + "] found...")
*      if f_pick_f (03, 10, "", "DBR # TYPEÄÄÄÄÄÄÄ-RA #ÄÄÄÄÄÄÄLAST NAME ÄÄÄÄUNIT #", ;
*            "str(fdbrno,4)+[   ]+frectype+[   ]+if(frectype='T',frloc,floc)+str(frano,6)+[  ]+flname+" ;
*            +"[ ]+funit","","floc+str(fdbrno,4)","l_floc+str(l_fdbrno,4)")
*         l_frano = radbrt->frano
*      endif
*   endif
case "L_FPAYTYP" $ yvar
   f_use ("rapaytyp")
   go top
   if f_valid (.not. eof(), "Paycode file is not accessible ...")
      if f_pick_f (12,48,"","TypeÄDescription ÄÄÄÄÄÄÄ","fpaycode+[ ]+fdesc")
         &yvar = rapaytyp->fpaycode
         keyboard chr(13)
      endif
   endif
   select rapaytyp
   use
case "L_FOITEM" $ yvar
   f_use ("rapaycd")
   go top
   if f_valid (.not. eof(), "Misc. Charge file is not accessible ...")
      if f_pick_f (12,48,"","TypeÄDescription ÄÄÄÄÄÄÄ", ;
            "fpaycd+[ ]+fitem+[ ]+str(frate,5,2)")
         &yvar = rapaycd->fpaycd
         keyboard chr(13)
      endif
   endif
   select rapaycd
   use
otherwise
   tone (500,9)
   f_popup ("No Help information for this Field. Press Any Key to Continue ...", .t.)
endcase
set cursor on
return


******************************
function f_dbrget

l_fbal = 0
l_ftnm = 0

if l_frectype $ "CFT"
   @ 05,17 get l_flname picture replicate ([X],14)
   @ 06,17 get l_frloc picture replicate ([!],10) ;
      valid f_valid(f_verify("raloc",1,l_frloc) ;
           .and.if(l_frectype$"FT",l_loc <> l_frloc, .t.))
   @ 04,59 get l_funit pict replicate ([!],10)
   @ 05,59 get l_fdays pict replicate ([9],  3)
   @ 06,59 get l_fmlg pict replicate ([9],  5)
   @ 08,17 get l_ftmetot pict [99999.99]
   @ 09,17 get l_fmlgtot pict [99999.99] valid f_dbraf6 ()
   @ 11,17 get l_fdisctot pict [99999.99]
   @ 12,17 get l_fcredtot pict [99999.99]
   @ 13,17 get l_foitem1 pict [!!!!] valid f_valid (f_verify ("RAPAYCD", 1, upper (l_foitem1)).or.empty(l_foitem1))
   * 02/01/93 edc: check pay code if pay amount > 0
   @ 13,22 get l_fotot1 pict [99999.99] valid ;
     f_valid (if(l_fotot1=0.00,empty(l_foitem1),.not.empty(l_foitem1))  ;
              .or.lastkey()=5,"Missing Pay Code !")
   @ 14,17 get l_foitem2 pict [!!!!] valid f_valid (f_verify ("RAPAYCD", 1, upper (l_foitem2)).or.empty(l_foitem2))
   @ 14,22 get l_fotot2 pict [99999.99] valid ;
     f_valid (if(l_fotot2=0.00,empty(l_foitem2),.not.empty(l_foitem2))  ;
              .or.lastkey()=5,"Missing Pay Code !")
   @ 15,17 get l_foitem3 pict [!!!!] valid f_valid (f_verify ("RAPAYCD", 1, upper (l_foitem3)).or.empty(l_foitem3))
   @ 15,22 get l_fotot3 pict [99999.99] valid ;
     f_valid (if(l_fotot3=0.00,empty(l_foitem3),.not.empty(l_foitem3))  ;
              .or.lastkey()=5,"Missing Pay Code !")
   @ 16,17 get l_foitem4 pict [!!!!] valid f_valid (f_verify ("RAPAYCD", 1, upper (l_foitem4)).or.empty(l_foitem4))
   @ 16,22 get l_fotot4 pict [99999.99] valid ;
     f_valid (if(l_fotot4=0.00,empty(l_foitem4),.not.empty(l_foitem4))  ;
              .or.lastkey()=5,"Missing Pay Code !")
   @ 18,17 get l_fsurchg picture [99999.99]
   @ 19,17 get l_fcdwtot picture [99999.99]
   @ 08,59 get l_fpaitot picture [99999.99]
   @ 09,59 get l_ffueltot picture [99999.99]
   @ 10,59 get l_fdmgtot picture [99999.99]
   @ 11,59 get l_ftaxtot pict [99999.99] valid f_dbraf7 ()
   @ 14,59 get l_fdepamt pict [99999.99] valid f_dbraf8 ()
   @ 19,44 get l_fpaytyp1 picture [!!!] valid ytyp [1] = l_fpaytyp1 .or. ;
      good_paytype (l_fpaytyp1)
   @ 19,49 get l_famt1 picture [99999.99] valid rdbraf1 ()
   @ 19,59 get l_fdbacct1 picture replicate ([!],10)
   @ 20,44 get l_fpaytyp2 picture [!!!] valid ytyp [2] = l_fpaytyp2 .or. ;
      empty(l_fpaytyp2) .or. good_paytype (l_fpaytyp2)
   @ 20,49 get l_famt2 picture [99999.99] valid rdbraf2 ()
   @ 20,59 get l_fdbacct2 picture [!!!!!!!!!!]
   @ 21,44 get l_fpaytyp3 picture [!!!] valid ytyp [3] = l_fpaytyp3 .or. ;
      empty (l_fpaytyp3) .or. good_paytype (l_fpaytyp3)
   @ 21,49 get l_famt3 picture [99999.99] valid rdbraf3 ()
else
   @ 05,17 get l_flname picture replicate ([X],14)
   @ 04,59 get l_funit picture replicate ([!],10)
   @ 19,44 get l_fpaytyp1 picture [!!!] valid good_paytype (l_fpaytyp1)
   @ 19,49 get l_famt1 picture [99999.99] valid f_valid(l_famt1>=0,"Invalid amouunt!")
endif
return .t.


******************************
function rdbraf1

if ycccap [1] .and. (ytyp [1] <> l_fpaytyp1 .or. .not. iszero (yamt [1] - l_famt1))
   f_valid (.f., "Credit Card Transaction Has Already Been Captured!")
   setcolor (gblueget)
   l_fpaytyp1 = ytyp [1]
   l_famt1 = yamt [1]
   setcolor (gblueget)
   @ 19,44 say l_fpaytyp1 picture [!!!]
   @ 19,49 say l_famt1 picture [99999.99]
   setcolor (gbluecolor)
   return .f.
endif
l_famt2 = l_ftotal-l_fdepamt-l_famt1
return .t.


******************************
function rdbraf2

if ycccap [2] .and. (ytyp [2] <> l_fpaytyp2 .or. .not. iszero (yamt [2] - l_famt2))
   f_valid (.f., "Credit Card Transaction Has Already Been Captured!")
   setcolor (gblueget)
   l_fpaytyp2 = ytyp [2]
   l_famt2 = yamt [2]
   setcolor (gblueget)
   @ 20,44 say l_fpaytyp2 picture [!!!]
   @ 20,49 say l_famt2 picture [99999.99]
   setcolor (gbluecolor)
   return .f.
endif
l_famt3 = l_ftotal-l_fdepamt-l_famt1-l_famt2
return .t.


******************************
function rdbraf3

if ycccap [3] .and. (ytyp [3] <> l_fpaytyp3 .or. .not. iszero (yamt [3] - l_famt3))
   f_valid (.f., "Credit Card Transaction Has Already Been Captured!")
   setcolor (gblueget)
   l_fpaytyp3 = ytyp [3]
   l_famt3 = yamt [3]
   setcolor (gblueget)
   @ 21,44 say l_fpaytyp3 picture [!!!]
   @ 21,49 say l_famt3 picture [99999.99]
   setcolor (gbluecolor)
   return .f.
endif
return f_valid (iszero (l_ftotal-(l_famt1+l_famt2+l_famt3+l_fdepamt)), ;
   "Out of Balance ...")


******************************
function rdbraf4

if ycccap [1] .and. (ytyp [1] <> l_fpaytyp1 .or. iszero (yamt [1] - l_famt1))
   f_valid (.f., "Credit Card Transaction Has Already Been Captured!")
   setcolor (gblueget)
   l_fpaytyp1 = ytyp [1]
   l_famt1 = yamt [1]
   setcolor (gblueget)
   @ 19,44 say l_fpaytyp1 picture [!!!]
   @ 19,49 say l_famt1 picture [99999.99]
   setcolor (gbluecolor)
   return .f.
endif
return .t.


******************************
function rdbrar

select racred
setcolor (gsubcolor)
if l_fpaytyp1 <> ytyp [1] .or. .not. iszero (l_famt1 - yamt [1])
   if good_cctyp (l_fpaytyp1, @yauth)
      yauthonly [1] = yauth
      if yrectype [1] = 0
         yrectype [1] = 6
      endif
      yscn = f_box (16, 9, 22, 45)
      @ 17, 11 say "Payment 1"
      @ 18, 11 say "CC #"
      @ 18, 20 say l_fpaytyp1
      @ 19, 11 say "Expire "
      @ 20, 11 say "Rec Type"
      @ 21, 11 say "Amount"
      @ 18, 24 get yccnum [1] picture replicate ("!", 20)
      @ 19, 20 get yccexp [1] picture "99/99"
      @ 20, 20 get yrectype [1] picture "9"
      @ 21, 20 say l_famt1 picture "99999.99"
      f_rd ()
      if yccrec [1] = 0
         f_findblank ()
         replace floc with if (l_frectype = "T", l_frloc, l_floc)
         replace frloc with if (l_frectype = "T", l_floc, l_frloc)
         replace frano with l_frano, fdbrno with l_fdbrno
         replace flname with l_flname, fauthdate with date ()
         replace fauthtime with time ()
      else
         go (yccrec [1])
         f_fupdate ("C")
         reclock ()
      endif
      replace fccnum with yccnum [1], fcctype with l_fpaytyp1
      replace fccexp with yccexp [1], frectype with yrectype [1]
      replace ftranstyp with if (l_famt1 < 0.00, "C", "S")
      replace fauthonly with yauthonly [1], fauthamt with abs (l_famt1)
      commit
      unlock
      if yccrec [1] = 0
         f_fupdate ("A")
      endif
   endif
endif

if l_fpaytyp2 <> ytyp [2] .or. .not. iszero (l_famt2 - yamt [2])
   if good_cctyp (l_fpaytyp2, @yauth)
      yauthonly [2] = yauth
      if yrectype [2] = 0
         yrectype [2] = 6
      endif
      yscn = f_box (16, 9, 22, 45)
      @ 17, 11 say "Payment 2"
      @ 18, 11 say "CC #"
      @ 18, 20 say l_fpaytyp2
      @ 19, 11 say "Expire "
      @ 20, 11 say "Rec Type"
      @ 21, 11 say "Amount"
      @ 18, 24 get yccnum [2] picture replicate ("!", 20)
      @ 19, 20 get yccexp [2] picture "99/99"
      @ 20, 20 get yrectype [2] picture "9"
      @ 21, 20 say l_famt2 picture "99999.99"
      f_rd ()
      if yccrec [2] = 0
         f_findblank ()
         reclock ()
         replace floc with if (l_frectype = "T", l_frloc, l_floc)
         replace frloc with if (l_frectype = "T", l_floc, l_frloc)
         replace frano with l_frano, fdbrno with l_fdbrno
         replace flname with l_flname, fauthdate with date ()
         replace fauthtime with time ()
      else
         go (yccrec [2])
         f_fupdate ("C")
         reclock ()
      endif
      replace fccnum with yccnum [2], fcctype with l_fpaytyp2
      replace fccexp with yccexp [2], frectype with yrectype [2]
      replace ftranstyp with if (l_famt2 < 0.00, "C", "S")
      replace fauthonly with yauthonly [2], fauthamt with abs (l_famt2)
      commit
      unlock
      if yccrec [2] = 0
         f_fupdate ("A")
      endif
   endif
endif

if l_fpaytyp1 <> ytyp [3] .or. .not. iszero (l_famt3 - yamt [3])
   if good_cctyp (l_fpaytyp3, @yauth)
      yauthonly [3] = yauth
      if yrectype [3] = 0
         yrectype [3] = 6
      endif
      yscn = f_box (16, 9, 22, 45)
      @ 17, 11 say "Payment 3"
      @ 18, 11 say "CC #"
      @ 18, 20 say l_fpaytyp3
      @ 19, 11 say "Expire "
      @ 20, 11 say "Rec Type"
      @ 21, 11 say "Amount"
      @ 18, 24 get yccnum [3] picture replicate ("!", 20)
      @ 19, 20 get yccexp [3] picture "99/99"
      @ 20, 20 get yrectype [3] picture "9"
      @ 21, 20 say l_famt3 picture "99999.99"
      f_rd ()
      if yccrec [3] = 0
         f_findblank ()
         reclock ()
         replace floc with if (l_frectype = "T", l_frloc, l_floc)
         replace frloc with if (l_frectype = "T", l_floc, l_frloc)
         replace frano with l_frano, fdbrno with l_fdbrno
         replace flname with l_flname, fauthdate with date ()
         replace fauthtime with time ()
      else
         go (yccrec [3])
         f_fupdate ("C")
         reclock ()
      endif
      replace fccnum with yccnum [3], fcctype with l_fpaytyp3
      replace fccexp with yccexp [3], frectype with yrectype [3]
      replace ftranstyp with if (l_famt3 < 0.00, "C", "S")
      replace fauthonly with yauthonly [3], fauthamt with abs (l_famt3)
      commit
      unlock
      if yccrec [3] = 0
         f_fupdate ("A")
      endif
   endif
endif
select radbrt
setcolor (gbluecolor)


******************************
function f_dbraf5

select raagrh
seek l_loc+str(l_frano,6)
if found()
   f_fupdate ("C")
   reclock ()
   replace fdbrno with l_fdbrno
   replace flname with l_flname,frloc with l_frloc,funit with l_funit
   replace fdays with l_fdays, ftmetot with l_ftmetot
   replace fmlgtot with l_fmlgtot, fdisctot with l_fdisctot
   * 12.15.98:
   replace fcdwtot with l_fcdwtot, fcredtot with l_fcredtot
   *
   replace ftaxtot with l_ftaxtot, fpaitot with l_fpaitot
   replace ffueltot with l_ffueltot,fdmgtot with l_fdmgtot
   replace foitem1 with l_foitem1, fotot1 with l_fotot1
   replace foitem2 with l_foitem2, fotot2 with l_fotot2
   replace foitem3 with l_foitem3, fotot3 with l_fotot3
   replace foitem4 with l_foitem4, fotot4 with l_fotot4
   replace fsurchg with l_fsurchg
   replace ftotal with l_ftotal,fdepamt with l_fdepamt
   replace famtdue with l_ftotal-fdepamt
   replace fpaytyp1 with l_fpaytyp1,famt1 with l_famt1
   replace fpaytyp2 with l_fpaytyp2,famt2 with l_famt2
   replace fpaytyp3 with l_fpaytyp3,famt3 with l_famt3
   * 03/30/93: (edc) save direct bill info.
   replace fdbacct1 with l_fdbacct1, fdbacct2 with l_fdbacct2
   commit
   unlock
endif
select radbrt
return .t.


******************************
function f_dbraf6

l_ftnm = l_ftmetot+l_fmlgtot
@ 10,17 say l_ftnm pict [99999.99]
return .t.


******************************
function f_dbraf7

l_ftotal = l_ftmetot+l_fmlgtot-l_fdisctot-l_fcredtot+l_fotot1+l_fotot2 ;
   +l_fotot3+l_fotot4+l_fsurchg+l_fcdwtot+l_fpaitot+l_ffueltot+l_fdmgtot ;
   +l_ftaxtot
@ 13,59 say l_ftotal pict [99999.99]
return .t.


******************************
function f_dbraf8

l_fbal = l_ftotal-l_fdepamt
@ 15,59 say l_fbal pict [99999.99]
return .t.

