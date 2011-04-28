* ===========================================================================
* process dbr
*
* date: 05/01/91
* author: edc
*
* revision
* date: 06/11/92
* edc: retain customer insurance info.
* date: 01/04/94
* edc: for intercity check-ins, only update racred.dbf for type 'C' & 'T' only
* 12.08.97
* do not update customer file if names are different
* 10.23.01: add email address to racust
* ===========================================================================
private ycnt, yntyp, yrectyp[6], yrptdate, yok, ydbrloc, yloc, ydbrno, yupdcust

rest from (gmempath+"radtr") additive      
l_floc = gloc
yrptdate = date()
yret = f_box (03, 03, 12, 65)
@ 4,05 say "Enter DBR Report Date  " get yrptdate valid f_y2k (@yrptdate)
@ 5,05 say "Enter Location Code .. " get l_floc picture "!!!!!!!!!!" ;
   valid f_valid(l_floc$gusrloc.or.l_floc="ALL ".or.empty(l_floc), ;
   "Invalid Location Code !")
if f_rd() = 27
   release all like l_*
   return
endif
if empty (l_floc)
   l_floc = "ALL"
endif
f_use ("raloc")
go top
if l_floc = 'ALL'
   declare l_loc [reccount ()]
   ynloc = 0
   do while .not. eof ()
      if floc $ gusrloc
         ynloc = ynloc + 1
         l_loc [ynloc] = raloc->floc
         skip
      endif
   enddo
else
   declare l_loc[1]
   ynloc=1
   l_loc[1]=l_floc
endif

if f_confirm ("Is this correct [Y/N]", "YN") = "N"
   f_valid (.f.,"User Abort ...")
   release all like l_*
   return
endif

f_use ("rasys")
go top
yupdcust=fupdcust
select rasys
use

yntyp=6
yrectyp[1]="A"       
yrectyp[2]="C"       
yrectyp[3]="D"       
yrectyp[4]="F"       
yrectyp[5]="T"       
yrectyp[6]="P"       

for i=1 to ynloc
   l_floc = l_loc[i]
   f_use ("raloc", 1)
   seek l_loc [i]
   l_fdbrno = if(fdbrno > 0, fdbrno, 101)    
   yloc=l_floc
   ydbrno = l_fdbrno

   @ 7,05 say "New DBR Report Number  " + str(l_fdbrno,4)
   @ 8,05 say "Report Date .......... " + dtoc(yrptdate)

   f_use ("radbrt")
   f_use ("raagrh")
   f_use ("racred")

   f_use ("radtr")
   go top
   @ 10,05 say "Processing Record .... "
   ycnt=0
   for j = 1 to yntyp
      seek yrectyp[j]
      do while .not. eof() .and. radtr->frectype=yrectyp[j]
         if radtr->floc <> l_floc
            skip
            loop
         endif
         ycnt=ycnt+1
         @ 10,28 say str(ycnt,4)
         if radtr->frectype = "T"
            ydbrloc = radtr->frloc
         else
            ydbrloc = radtr->floc
         endif
         if radtr->frectype $ "CFT"
         * if radtr->frectype $ "CT"       && 01/04/94: edc
            select racred
            seek ydbrloc+str(radtr->frano, 6)
            do while ydbrloc+str(radtr->frano,6) =  ;
                  racred->floc+str(racred->frano,6) .and. .not. eof()
               if fdbrno = 0
                  f_fupdate ("C")
                  reclock()
                  replace fdbrno with l_fdbrno
                  commit
                  unlock
               endif
               skip
            enddo
            select radtr
         endif
         if radtr->frectype $ "AD" .and. good_cctype (fpaytyp1)
            select racred
            seek ydbrloc+str(radtr->frano, 6)
            do while ydbrloc+str(radtr->frano,6) =  ;
                  racred->floc+str(racred->frano,6) .and. .not. eof()
               if (frectype = __gcccap .or. frectype = __gccuncap) .and. ;
                     fcctype = radtr->fpaytyp1 .and. fauthamt = radtr->famt1
                  f_fupdate ("C")
                  reclock()
                  replace fdbrno with l_fdbrno
                  commit
                  unlock
                  exit
               endif
               skip
            enddo
            select radtr
         endif
         f_retrieve ()
         select radbrt
         f_findblank ()
         f_replace ()
         f_fupdate ("A")
         if radtr->frectype $ "CF"    
            select raagrh
            seek (radtr->floc+str(radtr->frano,6))
            if found()
               f_fupdate ("C")
               reclock()
               replace fdbrno with l_fdbrno
               commit
               unlock
               if empty (raagrh->fcustno)
                  if yupdcust
                     f_use ("RACUST", 2)
                     seek raagrh->flic
                     yfnd = .t.
                     if .not. found ()
                        set order to 3
                        seek raagrh->flic
                        if .not. found ()
                           yfnd = .f.
                        endif
                     endif
                     if .not. yfnd
                        append blank
                        reclock ()
                        replace fcustno with strtran(raagrh->flic," ",""), faddr with raagrh->faddr
                        replace fbirthdt with raagrh->fdob, fcaddr with raagrh->fcrpaddr
                        replace fccity with raagrh->fcrpcity, fcompany with raagrh->fcrpnm
                        replace fcphone with raagrh->fcrpph
                        replace fcstate with raagrh->fcrpstate
                        replace fcctype with raagrh->fpaytyp1
                        replace fcity with raagrh->fcity, fczip with raagrh->fcrpzip
                        replace ffname with raagrh->ffname, flic with raagrh->flic
                        replace flname with raagrh->flname, fphone with raagrh->fphone
                        replace fstate with raagrh->fstate
                        replace fzip with raagrh->fzip, fexpdt with raagrh->flicexp
                        replace flicst with raagrh->flicst
                        replace fckout with max (raagrh->fdateout, fckout)
                        replace fckin with max (raagrh->fdatein, fckin)
                        replace frental with frental + 1
                        replace fsale with fsale + raagrh->ftotal
                        * 06/11/92 edc for recording insurance info.
                        replace finsur1 with raagrh->finsur1, finsur2 with raagrh->finsur2
                        * 10.23.01
                        replace femail with raagrh->femail
                        replace fmoddt with date ()
                        commit
                        unlock
                        f_fupdate ("A")
                        select raagrh
                        f_fupdate ("C")
                        reclock ()
                        replace fcustno with racust->fcustno
                        commit
                        unlock
                     endif
                     select racust
                     use
                  endif
               endif
            endif
         elseif frectype = "D"
            yfnd = .f.
            f_use ("raagr", 1)
            seek (radtr->floc+str(radtr->frano,6))
            if found ()
               yfnd = .t.
               yalias = alias ()
            else
               f_use ("raagrh", 1)
               seek (radtr->floc+str(radtr->frano,6))
               if found ()
                  yfnd = .t.
                  yalias = alias ()
               endif
            endif
            if yfnd
               if .not. empty (&yalias->fcustno)
                  f_use ("racust", 2)
                  seek &yalias->fcustno
                  * 12.08.95: only update if names matches
                  if found () .and. ;
                     substr(&yalias->flname,1,15) = substr(racust->flname,1,15) .and. ;
                     substr(&yalias->ffname,1,5) = substr(racust->ffname,1,5)
                     f_fupdate ("C")
                     reclock ()
                     replace fckout with max (&yalias->fdateout, fckout)
                     replace faddr with &yalias->faddr
                     replace fbirthdt with &yalias->fdob, fcaddr with &yalias->fcrpaddr
                     replace fccity with &yalias->fcrpcity, fcompany with &yalias->fcrpnm
                     replace fcphone with &yalias->fcrpph, fcrpno with &yalias->fcrpno
                     replace fcstate with &yalias->fcrpstate, flicst with &yalias->flicst
                     replace fcity with &yalias->fcity, fczip with &yalias->fcrpzip
                     replace ffname with &yalias->ffname, flic with &yalias->flic
                     replace flname with &yalias->flname, fphone with &yalias->fphone
                     replace fstate with &yalias->fstate
                     replace fzip with &yalias->fzip, fexpdt with &yalias->flicexp
                     * 10.23.01
                     replace femail with if(empty(&yalias->femail), femail, &yalias->femail)
                     commit
                     unlock
                  endif
               endif
               if .not. empty (&yalias->fcrpno)
                  f_use ("racrp", 1)
                  seek &yalias->fcrpno
                  if found ()
                     f_fupdate ("C")
                     reclock ()
                     replace fckout with max (&yalias->fdateout, fckout)
                     commit
                     unlock
                  endif
               endif
            endif
         endif
         select radtr
         if f_clrskip () = 0
            exit
         endif
      enddo
   next j
   select radtr
   use

   if ycnt > 0
      f_popup ("Creating DBR Header ...")
      f_use ("radbr")
      append blank
      reclock ()
      replace fdbrno with l_fdbrno, floc with l_floc, frptdate with yrptdate
      commit
      unlock
      f_fupdate ("A")
      f_popup ("Updating System DBR counter ...")
      select raloc
      f_fupdate ("C")
      reclock()
      replace fdbrno with if (l_fdbrno=9999, 1, l_fdbrno + 1)   
      commit
      unlock
      f_popback ()
      if ynloc = 1
         select radbr
         yrecno = recno ()
         close databases
         f_use ("radbr")
         go yrecno
         do rdbrr
      endif
   elseif ynloc = 1
      f_valid (.f.,"No Transaction to be processed ...")
   endif
next i

release all like l_*
close database
