* ===========================================================================
* check in rental agreement
*
* date: 05/01/91
* author: KST
*
* revision
* date: 06/18/92
* edc: fix weekly charge calculation
* date: 07/06/92
* edc: fix surcharge calculation
* date: 09/14/92
* edc: fix calendar day calculation
* date: 06/21/93 
* edc: get lowest charge
* date: 08/09/93
* edc: fix gas charge by (M)iles or (G)auge
* date: 08/31/93
* edc: retrieve cc track info from raagr
* date: 12/20/93
* edc: correct rate calc. for grace 
* date: 01/07/94
* edc: fix time & mileage calculation problems
* date: 08/29/94
* edc: fuel purchase option. assume add'l chg code = "FPO?"
* date: 01/27/95
* edc: bug fix when fuel charge is taxable.
* date: 01/31/95
* edc: <F3> freesell (see rrncahlp2)
* date: 09.29.97
* edc: allow more than 1 surcharges
* 07.09.99: set century on
* 10.23.01: add email address
*
* 12.01.06: capture loc = checkout loc
*
* 08.27.08: if fhr > 2 => fdays + 1 (see also rrnec.prg)
* ------------------------------------------------------------
* 10.15.08: add add'l charge 5 & 6
* 11.15.08: add FDUEIN (due in date)
*           add early due charge
*           add late add'l daily charge
* -------------------------------------------------------------
* 12.21.09: exclude jet center from [ERC]
* -----
* 10.18.10: get user id
* -----
* 04.28.11: paperless ra
* 1. mandatory email
* 2. prompt with current email after confirm before save
* 3. do not print close ra, instead prompt
* 4. if no, save ra and exit
* ===========================================================================
store space (15) to yitem1, yitem2, yitem3, yitem4, yitem5, yitem6   && 10.15.08
set century on     && 07.09.99
yendedit = .f.
yfreesell = gfreesell
store 0.00 to ytot1, ytot2
store 0 to ysyssurchg, ydaychg
f_clrscn ("Check In Rental Agreement")
restore from (gmempath + "RAAGRH2") additive
* -- 10.15.08
restore from (gmempath + "RAAGRH") additive
* --
l_ftrack = space(70)
l_fpo = .f.            && fuel purchase option  08/29/94

l_fsurchg = 0          && 03.10.09
l_fsurchg1 = 0

l_femail = space(50)   && 5.03.11: email address 

* --10.15.08
l_foitem5 = [    ]
l_foitem6 = [    ]
l_forate5 = 0.00
l_forate6 = 0.00
l_fodly5 = .f.
l_fodly6 = .f.
l_fotax5 = .f.
l_fotax6 = .f.
l_fotot5 = 0.00
l_fotot6 = 0.00
l_fduein = ctod("")
* --

* --10.18.10: add get user id
f_use ("rausr")
if .not. get_usrid (@l_fid2)
   return
endif
select rausr
use
@ 01, 70 say "<" + l_fid2 + "/" + gusrid + ">"    && 10.18.10
* --

if .not. rrnpkra ("O")
   return
endif
* 08/31/93: edc: restore cc track 1 info. from raagr
gccinfo = substr(l_ftrack,1,at('?',l_ftrack)-1)      

f_use ("RASYS")
go top
ylowrchg = flowrchg           && get lowest charge
use

f_use ("RALOC")
seek l_floc
if found ()
   yggracehr = fgracehr
   yggracefr = ffreehr
   ygraceins = fgraceins
   ygfuelchg = ffuelchg
   ygfueltax = ffueltax
   ygsurchg = fsurchg
   ysurtx = fsurtx
   ygwkmin = fwkmin
   ygwkmax = fwkmax
   ygmthmin = fmthmin
   ygmthmax = fmthmax
else
   yggracehr = ggracehr
   yggracefr = ggracefr
   ygfuelchg = gfuelchg
   ygfueltax = gfueltax
   ygraceins = ggraceins
   ygsurchg = gsurchg
   * ygsurtx = gsurtx
   ysurtx = gsurtx         && 06/18/93 (edc): typo
   ygwkmin = gwkmin
   ygwkmax = gwkmax
   ygmthmin = gmthmin
   ygmthmax = gmthmax
endif
use
f_getscn ("RRNCA")
store "" to yccnum1, yccnum2, yccnum3
store 0.00 to yamtdue1, yamtdue2, yamtdue3
store space (30) to yauthstat1, yauthstat2, yauthstat3
store __gccspecauth to yrectyp1, yrectyp2, yrectyp3
store .f. to yauthonly1, yauthonly2, yauthonly3
yccswipe1 = if(empty(gccinfo),"M","C")   && 11/11/93 card or manual
yccswipe2 = "M"
yccswipe3 = "M"

select raagr
set key 28 to rrncah
set key -1 to rrncahlp
set key -2 to rrncahlp2

do fgetrrnca with .t.
do while .t.
   ykeyin = f_confirm ("[C]heck In  [N]ext  [P]revious  [Q]uit", "CNPQ")
   do case
   case ykeyin = "C"
      do while .t.
         setcolor (gredcolor)
         if .not. yfreesell
            @ 24, 01 say "F3 Overwrite Free Sell"
         endif
         setcolor (gbluecolor)
         f_rd ()
         if yendedit
            ykey = f_confirm ("[C]onfirm  [E]dit  [I]gnore Changes", "CEI")
         else
            ykey = f_confirm ("[E]dit  [I]gnore Changes", "EI")
         endif
         do case
         case ykey = "C"

         * -- 05.03.11: default is to send close ra as email
         clear gets
         setcolor (gsubcolor)
         yscn = f_box (13, 10, 16, 73)
         @ 14, 11 say "email:"
         do while .t.
            @ 14, 18 get l_femail picture replicate ("x", 50) ;
               valid f_valid (f_goodem (l_femail, .t.), "Invalid email address ...")    && [NA] is valid email 
            if f_rd () = 27
			   f_valid (.f., "Please enter a valid email or NA")
		       loop
		    else
               exit
            endif			
		 enddo	
		 
         * update gempath+"ramsg.dbf"
         yfil = gempath + "ramsg.dbf"
         if file (yfil) .and. len(trim(l_femail)) > 2     && only send with a valid email
            select 0
            use &yfil
            reclock ()
            append blank
            f_replace ()
         endif
         f_restbox (yscn)
         setcolor (gbluecolor)
		 * -- 05.03.11 

		 if f_confirm ("Do you want to print contract? ", "YN") = "Y"
               * y2k
               set century off
               do rrnprt with "I"
               set century on
            endif
            f_popup ("Please Wait While Saving Closed Contract...", .f.)
            f_use ("raagrh")
            append blank
            l_frastat = "C"
            f_replace ()
            f_fupdate ("A")
            use
            select raagr
            f_clrrec ()
            f_use ("ravm", 1)
            seek l_funit
            if found ()
               f_fupdate ("C")
               reclock ()
               if .not. empty (freason)
                  replace fstatus with "H"
               else
                  replace fstatus with if (gautopkvh, "I", "A")
               endif
               replace floc with l_frloc
               replace futime with dtos (l_fdatein) + l_ftimein
               replace fcurra with 0, frenter with " "
               replace flastra with l_frano, fckindt with l_fdatein
               replace fmileage with l_fmlgin, fdueback with ctod ("  /  /  ")
               commit
               unlock
            endif
            *if ravm->fresv
            *   f_use ("RAVRES", 1)
            *   seek l_funit + "A" + l_floc + str (l_frano, 6)
            *   if found ()
            *      f_clrrec ()
            *   endif
            *   use
            *endif

            f_use ("RAAGRX")
            append blank
            l_fexchg = .f.
            f_replace ()
            if .not. empty (l_fexdate)
               reclock ()
               replace fdateout with l_fexdate, ftimeout with l_fextime
               commit
               unlock
            endif
            reclock ()
            replace ffueltot with l_ffueltot - l_fefueltot
            replace fdmgtot with l_fdmgtot - l_fedmgtot
            commit
            unlock
            f_fupdate ("A")
            use
            f_use ("RACRED", 1)
            seek l_floc + str (l_frano, 6)
            do while floc = l_floc .and. frano = l_frano .and. .not. eof ()
               if .not. (fccnum $ (l_fccnum1 + ";" + l_fccnum2 ;
                     + ";" + l_fccnum3)) .or. (frectype <> __gccuncap .and. ;
                     frectype <> __gcccap)
                  reclock ()
                  if ftranstyp = "C"
                     replace fauthamt with -abs (fauthamt), fcapamt with -abs (fcapamt)
                  endif
                  replace ftranstyp with "D"
                  commit
                  unlock
               endif
               skip
            enddo
            for y = 1 to 3
               ystr = "L_FPAYCOD" + str (y, 1)
               if &ystr = 1
                  f_findblank ()
                  ystr1 = "L_FCCNUM" + str (y, 1)
                  ystr2 = "L_FPAYTYP" + str (y, 1)
                  ystr3 = "L_FCCEXP" + str (y, 1)
                  ystr4 = "L_FAUTHCD" + str (y, 1)
                  ystr5 = "L_FAMT" + str (y, 1)
                  ystr6 = "YAUTHONLY" + str (y, 1)
                  ystr7 = "YRECTYP" + str (y, 1)
                  ystr8 = "YAUTHSTAT" + str (y, 1)
                  ystr9 = "YCCSWIPE" + str (y, 1)      && 11/11/93 card swipe or manual enter
                  replace fccnum with &ystr1, fcctype with &ystr2
                  replace fccexp with &ystr3, fauthcode with &ystr4
                  replace fauthamt with abs (&ystr5), fauthonly with &ystr6
                  replace frectype with if (empty (gccnet), __gccuncap, &ystr7)
                  replace fauthstat with &ystr8
                  replace fauthdate with date (), fauthtime with time ()
                  replace ffname with l_ffname, flname with l_flname
                  replace fmname with &ystr9      && 11/11/93 card swipe or manual enter
                  replace floc with l_floc, frano with l_frano
                  * 12.01.06: capture loc = checkout loc
                  * replace frloc with l_frloc
                  replace frloc with l_floc

                  if &ystr5 < 0.00
                     replace ftranstyp with "C"
                  elseif .not. empty (&ystr4) .and. &ystr7 = __gccspecauth
                     replace ftranstyp with "F"
                  else
                     replace ftranstyp with "S"
                  endif
                  commit
                  unlock
                  f_fupdate ("A")
               endif
            next
            * MUST be last one to update (may change l_floc, l_frloc)
            f_use ("RADTR")
            f_findblank ()
            l_fdrop = 0.00
            l_frectype = if (l_floc <> l_frloc, "F", "C")

            * 08.27.08:
            if l_fhr > 2
               l_fdays = l_fdays + 1
            endif
            * 08.27.08

            f_replace ()
            f_fupdate ("A")
            if l_floc <> l_frloc
               f_findblank ()
               ytmp = l_frloc
               l_frloc = l_floc
               l_floc = ytmp         
               l_frectype = "T"
               f_replace ()
               f_fupdate ("A")
            endif
            use
            exit
         case ykey = "E"
            do fgetrrnca with .f.
            loop
         case ykey = "I"
            exit
         endcase
      enddo
      exit
   case ykeyin = "N"
      clear gets
      skip 1
      if eof ()
         f_popup ("End of file. Press Any Key...", .t.)
         go bottom
      endif
      f_retrieve ()
      do fgetrrnca with .t.
   case ykeyin = "P"
      clear gets
      skip -1
      if bof ()
         f_popup ("Top of file. Press Any Key...", .t.)
         go top
      endif
      f_retrieve ()
      do fgetrrnca with .t.
   case ykeyin = "Q"
      clear gets
      exit
   endcase
enddo
set century off
set key 28 to
set key -2 to
set key -1 to
close databases


******************************
* F1 help 
******************************
procedure rrncah

private yvar

yvar = upper (alltrim (readvar ()))
if yvar = "L_FDMGTOT"         && display charge of exchanged vehicles
   f_valid (.f., "Damage Charge For Exchanged Vehicles = " ;
      + str (l_fedmgtot, 8, 2))
elseif yvar = "L_FFUELTOT"    && display fuel charge of exchanged vehicles
   f_valid (.f., "Fuel Charge For Exchanged Vehicles = " ;
      + str (l_fefueltot, 8, 2))
elseif yvar = "L_FPAYTYP"     && give listing of valid payment type.
   f_use ("RAPAYTYP")
   go top
   if .not. eof ()
      locate for fpaycode >= &yvar
      if eof ()
         go bottom
      endif
      if f_pick_f (10, 68, "", "", "fpaycode")
         &yvar = rapaytyp->fpaycode
         keyboard chr (13)
      endif
   else
      f_valid (.f., "No Valid Payment Type Found!!!")
   endif
elseif yvar = "L_FCCNUM"      && swipe card
   private yccnum, yexpdt, ystr
   ystr = "L_FCCEXP" + right (yvar, 1)
   yccnum = &yvar
   yexpdt = &ystr
   if get_card (@yccnum, l_flname, l_ffname, @yexpdt) .and. ;
         .not. empty (yccnum)
      &yvar = yccnum
      &ystr = yexpdt
   endif
elseif yvar = "L_FGASTYP"     && display fuel charge method
   private yarray [2], yptr
   yarray [1] = "M - Charge by mileage driven"
   yarray [2] = "G - Charge by Gauge Reading "
   yptr = if (l_fgastyp = "M", 1, 2)
   yptr = f_pick_a (4, 50, "", "", yarray, 2, yptr)
   if yptr <> 0
      * l_fgastyp = yarray [yptr]
      * 08/09/93 (edc): bug
      l_fgastyp = if(yptr=1,"M","G")
      keyboard chr (13)
   endif
else
   f_valid (.f., "No Help information for this Field ...")
endif

******************************
* get close RA screen
******************************
procedure fgetrrnca
parameters xnew
private yedit, yscn, ycolor

if xnew
   if .not. empty (l_fremark)
      ycolor = setcolor (gsubcolor)
      yscn = f_box (13, 9, 22, 62)
      * @ 17, 11 say "Remark"
      setcolor (gsubget)
      @ 14, 11 say substr(l_fremark,1,50)
      @ 15, 11 say substr(l_fremark,51,50)
      @ 16, 11 say substr(l_fremark,101,50)
      @ 17, 11 say substr(l_fremark,151,50)
      @ 18, 11 say substr(l_fremark,201,50)
      @ 19, 11 say substr(l_fremark,251,50)
      @ 20, 11 say substr(l_fremark,301,50)
      @ 21, 11 say substr(l_fremark,351,50)
      setcolor (ycolor)
      f_popup ("Press Any Key to Continue...", .t.)
      f_restbox (yscn)
   endif
   l_frloc = gloc

   * -- 10.20.08: schedule return date
   * l_fduein = l_fdatein   
   l_fdatein = date ()    && actual return date
   * --

   l_ftimein = time ()
   l_fmlgin = l_fmlgout
   l_fmlg = 0
   l_ffuelin = l_ffuelout
   l_femlg = l_femlgin - l_femlgout
   * l_fid2 = gusrid     && 10.18.10: get userid instead of gusrid
endif

@ 1, 16 say l_frano picture replicate ([9], 6)
@ 1, 36 say l_flname

* -- 10.20.08
@ 2, 16 say l_fduein
* --

@ 2, 36 say l_ffname
@ 3, 16 say l_floc
@ 3, 34 say l_fdateout
@ 3, 45 say l_ftimeout
@ 4, 16 get l_frloc picture replicate ([!], 10) ;
   valid f_valid (l_frloc $ gusrloc)
@ 4, 34 get l_fdatein valid f_valid (f_y2k(@l_fdatein) .and. l_fdatein >= l_fdateout)
@ 4, 45 get l_ftimein picture [99:99] valid rrnca1 ()
@ 7, 16 say l_funit picture replicate ([!], 10)

@ 8, 16 get l_fmlgin picture replicate ([9], 6) valid rrnca2 ()
@ 9, 16 say l_fmlgout picture replicate ([9], 6)
@ 10, 16 say l_fmlg picture replicate ([9], 6)
@ 11, 16 say l_ffuelout picture [9]
@ 11, 23 get l_ffuelin picture [9] valid rrnca3 ()
@ 7, 37 say l_feunit picture replicate ([!], 10)
@ 8, 37 say l_femlgin picture replicate ([9], 6)
@ 9, 37 say l_femlgout picture replicate ([9], 6)
@ 10, 37 say l_femlg picture replicate ([9], 6)
@ 11, 37 say l_fefuelou picture [9]
@ 11, 44 say l_fefuelin picture [9]
*
yedit = yfreesell
*
IF yedit

@ 13, 16 get l_fdly picture [999] valid rrncaret (1)
@ 13, 24 get l_fdlychg picture [9999.99] valid rrnca5 ()
@ 13, 37 say l_fdlytot picture [99999.99]
@ 14, 16 get l_fwkd picture [999] valid rrncaret (1)
@ 14, 24 get l_fwkdchg picture [9999.99] valid rrnca9 ()
@ 14, 37 say l_fwkdtot picture [99999.99]
@ 15, 16 get l_fwk picture [999] valid rrncaret (1)
@ 15, 24 get l_fwkchg picture [9999.99] valid rrnca11 ()
@ 15, 37 say l_fwktot picture [99999.99]
@ 16, 16 get l_fmth picture [999] valid rrncaret (1)
@ 16, 24 get l_fmthchg picture [9999.99] valid rrnca14 ()
@ 16, 37 say l_fmthtot picture [99999.99]
@ 17, 16 get l_fhr picture [999] valid rrncaret (1)
@ 17, 24 get l_fhrchg picture [9999.99] valid rrnca17 ()
@ 17, 37 say l_fhrtot picture [99999.99]
@ 18, 16 get l_fmlgs picture [9999] valid rrncaret (1)
@ 18, 24 get l_fmlgchg picture [9999.99] valid rrnca20 ()
@ 18, 37 say l_fmlgtot picture [99999.99]
@ 19, 37 say l_ftmetot + l_fmlgtot picture [99999.99]
@ 20, 16 get l_fdisc picture [99] valid rrnca22 ()
@ 20, 37 say l_fdisctot picture [99999.99]
@ 21, 16 get l_fcdwdays picture [999]
@ 21, 24 get l_fcdw picture [9999.99] valid rrnca25 ()
@ 21, 37 say l_fcdwtot picture [99999.99]
@ 22, 16 get l_fpaidays picture [999]
@ 22, 24 get l_fpai picture [9999.99] valid rrnca28 ()
@ 22, 37 say l_fpaitot picture [99999.99]
*
if empty(ygsurchg)
   @ 23, 37 say l_fothtot1 + l_fothtot2 picture [99999.99]
else
   @ 23, 15 say l_fothtot1 + l_fothtot2 picture [99999.99]
   @ 23, 24 say [Surcharge...]
   @ 23, 37 get l_fsurchg picture [99999.99] 
endif
*
ENDIF
* @ 1, 71 get l_fcredtot picture [99999.99]         && 05.16.01
@ 2, 58 get l_ftax picture [99.99] valid rrnca34 ()
@ 2, 71 say l_ftaxtot picture [99999.99]
*
@ 3, 66 get l_fgastyp pict "!" valid rrnca351 ()
@ 3, 71 get l_ffueltot picture [99999.99] valid rrnca34 ()    && 01/27/95
@ 4, 71 get l_fdmgtot picture [99999.99] valid rrnca35 ()
@ 6, 71 get l_fdepamt picture [99999.99] valid rrnca36 ()
@ 7, 71 say l_famtdue picture [99999.99]
*
@ 10, 57 get l_fpaytyp1 picture [!!!] valid rrnca38 ()
@ 10, 69 get l_fdbacct1 picture replicate ([!], 10) valid ;
   f_valid (l_fpaycod1 < 3 .or. .not. empty (l_fdbacct1))  
@ 11, 57 get l_fccnum1 picture replicate ([9], 20) valid rrnca39 ()
@ 12, 57 get l_fccexp1 picture "99/99" valid ;
   f_valid (l_fpaycod1 <> 1 .or. f_expired (l_fccexp1), "Card Expired!!!")
@ 13, 57 get l_famt1 picture [99999.99] valid rrnca40 ()
@ 13, 73 get l_fauthcd1 picture replicate ([!], 6) valid rrnca41 ()
@ 15, 57 get l_fpaytyp2 picture [!!!] valid rrnca42 ()
@ 15, 69 get l_fdbacct2 picture replicate ([!], 10) valid ;
   f_valid (l_fpaycod2 < 3 .or. .not. empty (l_fdbacct2))   
@ 16, 57 get l_fccnum2 picture replicate ([9], 20) valid rrnca44 ()
@ 17, 57 get l_fccexp2 picture "99/99" valid ;
   f_valid (l_fpaycod2 <> 1 .or. f_expired (l_fccexp2), "Card Expired!!!")
@ 18, 57 get l_famt2 picture [99999.99] valid rrnca45 ()
@ 18, 73 get l_fauthcd2 picture replicate ([!], 6) valid rrnca46 ()

@ 20, 57 get l_fpaytyp3 picture [!!!] valid rrnca47 ()
@ 21, 57 get l_fccnum3 picture replicate ([9], 20) valid rrnca48 ()
@ 22, 57 get l_fccexp3 picture "99/99" valid ;
   f_valid (l_fpaycod3 <> 1 .or. f_expired (l_fccexp3), "Card Expired!!!")
@ 23, 57 get l_famt3 picture [99999.99] valid rrnca49 ()
@ 23, 73 get l_fauthcd3 picture replicate ([!], 6) valid rrnca50 () .and. ;
   f_compute (@yendedit, .t.)


******************************
* check check in time and date
******************************
function rrnca1

if .not. f_valid (f_timeok (@l_ftimein))
   return .f.
endif
if l_fdateout < l_fdatein
   return .t.
else
   return f_valid (l_ftimein >= l_ftimeout)
endif


******************************
* check mile in with mile out
******************************
function rrnca2

if lastkey () = 5
   return .t.
endif

if f_valid (l_fmlgin >= l_fmlgout)
   if l_fmlgin = l_fmlgout
      f_valid (.f., "Warning!  No Miles Driven!")
      if f_confirm ("[R]etype    [C]ontinue ", "RC") = "R"
         return .f.
      endif
   endif
   l_fmlg = l_fmlgin - l_fmlgout
   if l_fmlg / (l_fdatein - l_fdateout + 1) > 500
      f_valid (.f., "Warning! Please Check Odometer Reading ...") 
      if f_confirm ("[R]etype    [C]ontinue ", "RC") = "R"
         return .f.
      endif
   endif
   @ 10, 16 say l_fmlg picture "999999"
   return .t.
else
   return .f.
endif


******************************
* check fuel level and do time and mileage calculation
******************************
function rrnca3

if lastkey () = 5
   return .t.
endif

if .not. f_valid (l_ffuelin <= 8)
   return .f.
endif
do rrncacal1
return .t.

*-----------------------------------------
* time and mileage calculation
* 11.01.08: add early rental fee calc
*           add add'l date rental fee calc
*------------------------------------------
procedure rrncacal1
private y1, y2, y3, yto, yti, yrtot, yfdays, yfhr
private ymhr, ytotd, ytotw, ytotm, yrdays, yrwk, yrmlg, yrmlgd, yrmlgw, yrmlgm

f_popup ("Please Wait While Calculating Time & Mileage Charges...", .f.)

* initialize variables
l_fdly = 0
l_fwkd = 0
l_fwkdtot = 0
l_fdlytot = 0
l_fwktot = 0
l_fmthtot = 0
l_fhrtot = 0
* --

if l_fcalday
   yto = 0
   yti = 0
* edc: 09/14/92
   l_fdays = l_fdatein - l_fdateout + 1
   y1 = val(left (gckintme,2))*100 + val (substr (gckintme, 4, 2))
   y2 = val(left (l_ftimeout,2))*100 + val (substr (l_ftimeout, 4, 2))
   y3 = val(left (l_ftimein,2))*100 + val (substr (l_ftimein, 4, 2))

   if y2 < y1 .and. y3 > y1
      l_fdays = l_fdays+1
   endif
   if y2 >= y1 .and. y3 <= y1
      l_fdays = l_fdays-1
   endif
****
   ymins = 0
   l_fhr = 0
else
   yto = val (substr (l_ftimeout, 1, 2)) * 60 + ;
      val (substr (l_ftimeout, 4, 2))
   yti = val (substr (l_ftimein, 1 ,2)) * 60 + val (substr (l_ftimein, 4, 2))
   ymins = (l_fdatein - l_fdateout) * 24 * 60 + yti - yto
   *** 06/01/94
   if l_fhrchg = 0 .or. l_fdlychg > 0 .or. l_fwkdchg > 0 .or.   ;
      l_fwkchg > 0 .or. l_fmthchg > 0
      l_fdays = int (ymins / 1440)
      ymins = ymins - l_fdays * 1440
   else
      l_fdays = 0
   endif
   * -- 11.01.08
   *if l_fdays < 1  .and. l_fdlychg > 0      && 06/01/94(edc) for limo rental
   *   l_fdays = 1
   *   ymins = 0
   *endif
   * --

endif

if ygraceins
   ydaychg = if(ymins<=yggracehr,l_fdays,l_fdays + 1)
else
   ydaychg = if(ymins<=0,l_fdays,l_fdays + 1)
endif

if ymins <= yggracehr
   ymins = 0
elseif yggracefr
   ymins = ymins - yggracehr
endif

l_fhr = int (ymins / 60)
ymins = ymins - l_fhr * 60
if ymins > 0
   if l_fhr >= 23 .and. l_fdlychg > 0      && 06/01/94(edc) for limo rental
      l_fdays = l_fdays + 1
      l_fhr = 0
   else
      l_fhr = l_fhr + 1
   endif
   ymins = 0
endif

l_fcdwdays = ydaychg
l_fpaidays = ydaychg
l_fcdwtot = l_fcdwdays * l_fcdw
l_fpaitot = l_fpaidays * l_fpai

l_fmlgs = l_fmlg + l_femlgs
l_frhr = l_fhr
l_fdly = l_fdays

if (l_fhr * l_fhrchg) >= l_fdlychg .and. l_fdlychg > 0
   l_fdly = l_fdly + 1
   l_fhr = 0
endif

* -- 11.15.08: check if add'l date rate apply
l_fwkd = 0
if l_fdatein > l_fduein
   l_fwkd = l_fdly - (l_fduein-l_fdateout)
endif

if l_fwkd > 0
   if l_fwkdchg <= 0        && calc add'l date rate if missing ...
      if gadlychg > 0
         l_fwkdchg = l_fdlychg + gadlychg      
      else
         l_fwkdchg = round(l_fdlychg * (1 + gadlypct / 100), 2)
      endif
   endif
   if l_fwkdchg > 0
      l_fwkdtot = l_fwkdchg * l_fwkd    && use add'l date rate
      l_fdly = l_fdly - l_fwkd
   else
      l_fwkd = 0
   endif
endif
* -- 11.15.08

store 99999.99 to ytotd, ytotw, ytotm, yrtot

yfdays = l_fdly
yfhr = l_fhr              && save for week/month calc.

* estimate daily chg 01/07/95:(edc)
if l_fdlychg > 0.00
   if l_fdlymlg = 0       && unlimited
      yrmlgd = 0
   else
      yrmlg = l_fmlgs - (l_fdlymlg * l_fdly) 
      yrmlgd = if(yrmlg > 0, yrmlg * l_fmlgchg, 0)
      * compare daily charge taking into account of mileage calc.
      *if ylowrchg         && edc: 12/11/95 
      *   y1 = (l_fdly * l_fdlychg) + (l_fhr * l_fhrchg) + yrmlgd
      *   yrmlg = l_fmlgs - (l_fdlymlg * (l_fdly + 1))       
      *   yrmlgd = if(yrmlg > 0, yrmlg * l_fmlgchg, 0)
      *   y2 = ((l_fdly + 1) * l_fdlychg) + yrmlgd
      *   if y1 > y2
      *      l_fdly = l_fdly + 1
      *      l_fhr = 0
      *   endif
      *   yrmlg = l_fmlgs - (l_fdlymlg * l_fdly) 
      *   yrmlgd = if(yrmlg > 0, yrmlg * l_fmlgchg, 0)
      *endif
   endif
   ytotd = l_fdly * l_fdlychg + l_fhr * l_fhrchg + yrmlgd
   yrtot = ytotd
endif

yrdays = l_fdly
yrhr = l_fhr
* estimate weekly chg 01/07/95:(edc)
l_fwk = 0
if l_fwkchg > 0.00       &&  .and. (l_ftmtyp = 3 .or. ylowrchg)
   if ylowrchg
      l_fwk = int (yfdays/7)
      l_fdly = yfdays - l_fwk * 7
      l_fhr = yfhr
      if l_fdly * l_fdlychg + l_fhr * l_fhrchg > l_fwkchg
         l_fwk = l_fwk + 1
         l_fdly = 0
         l_fhr = 0
      endif
      if l_fdly > 0 .and. l_fdlychg <= 0
         l_fwk = l_fwk + 1
         l_fdly = 0
         l_fhr = 0
      endif
      if l_fwkmlg = 0       && unlimited
         yrmlgw = 0
      else
         * compare weekly charge taking into account of mileage calc.
         yrmlg = l_fmlgs - ((l_fwkmlg * l_fwk) + (l_fdlymlg * l_fdly)) 
         yrmlgw = if(yrmlg > 0, yrmlg * l_fmlgchg, 0)
         *y1 = (l_fwk * l_fwkchg) + (l_fdly * l_fdlychg) +   ;
         *     + (l_fhr * l_fhrchg) + yrmlgw
         *yrmlg = l_fmlgs - (l_fwkmlg * l_fwk + l_fdlymlg * (l_fdly+1)) 
         *yrmlgw = if(yrmlg > 0, yrmlg * l_fmlgchg, 0)
         *y2 = l_fwk * l_fwkchg + (l_fdly+1) * l_fdlychg +   ;
         *     + yrmlgw
         *if y1 > y2 .and. l_fdlychg > 0.00
         *   l_fdly = l_fdly + 1 
         *   l_fhr = 0
         *   y1 = y2
         *endif
         *yrmlg = l_fmlgs - (l_fwkmlg * (l_fwk + 1))       
         *yrmlgw = if(yrmlg > 0, yrmlg * l_fmlgchg, 0)
         *y2 = ((l_fwk + 1) * l_fwkchg) + yrmlgw
         *if y1 > y2
         *   l_fwk = l_fwk + 1
         *   l_fdly = 0
         *   l_fhr = 0
         *endif
         *yrmlg = l_fmlgs - ((l_fwkmlg * l_fwk) + (l_fdlymlg * l_fdly)) 
         *yrmlgw = if(yrmlg > 0, yrmlg * l_fmlgchg, 0)
      endif
      if l_fwk > 0
         ytotw = l_fwk * l_fwkchg + l_fdly * l_fdlychg +   ;
                 l_fhr * l_fhrchg + yrmlgw
         if ytotw > ytotd
            l_fwk = 0
            l_fdly = yrdays 
            l_fhr = yrhr
         else
            yrtot = ytotw
         endif
      else
         * restore old values
         l_fdly = yrdays 
         l_fhr = yrhr
      endif

   elseif l_ftmtyp = 3
      do while l_fdly >= ygwkmin
         l_fwk = l_fwk + 1
         l_fdly = l_fdly - ygwkmax
         if l_fdly < 0
            l_fhr = 0
            l_fdly = 0
         endif
      enddo
   endif
   l_fwktot = l_fwkchg * l_fwk
else
   l_fwktot = 0.00
endif

* estimate monthly chg 01/07/95:(edc)
yrwk = l_fwk
yrdays = l_fdly
yrhr = l_fhr
l_fmth = 0
if l_fmthchg > 0.00         && .and. (l_ftmtyp = 4 .or. ylowrchg)
   if ylowrchg
   * 01/07/95: (edc) stll need to compare mileage....
      l_fmth = int (yfdays/30)
      l_fdly = yfdays - l_fmth * 30
      l_fwk = int (l_fdly/7)
      l_fdly = l_fdly - l_fwk * 7
      l_fhr = yfhr          && restore org. hr.
      if l_fdly * l_fdlychg + l_fhr * l_fhrchg > l_fwkchg
         l_fwk = l_fwk + 1
         l_fdly = 0
         l_fhr = 0
      endif
      if l_fdly > 0 .and. l_fdlychg <= 0 
         l_fwk = l_fwk + 1
         l_fdly = 0
         l_fhr = 0
      endif 
      if l_fwk * l_fwkchg + l_fdly * l_fdlychg + l_fhr * l_fhrchg > l_fmthchg
         l_fmth = l_fmth + 1
         l_fwk = 0
         l_fdly = 0
         l_fhr = 0
      endif
      if l_fmthmlg = 0       && unlimited
         yrmlgm = 0
      else
         * compare monthly charge taking into account of mileage calc.
         yrmlg = l_fmlgs - ((l_fmthmlg * l_fmth) + (l_fwkmlg * l_fwk) +  ;
                            (l_fdlymlg * l_fdly)) 
         yrmlgm = if(yrmlg > 0, yrmlg * l_fmlgchg, 0)
         *y1 = (l_fmth * l_fmthchg) + (l_fwk * l_fwkchg) +   ;
         *     (l_fdly * l_fdlychg) + (l_fhr * l_fhrchg) + yrmlgm
         *yrmlg = l_fmlgs - (l_fmthmlg * (l_fmth + 1))       
         *yrmlgm = if(yrmlg > 0, yrmlg * l_fmlgchg, 0)
         *y2 = ((l_fmth + 1) * l_fmthchg) + yrmlgm
         *if y1 > y2
         *   l_fmth = l_fmth + 1
         *   l_fwk = 0
         *   l_fdly = 0
         *   l_fhr = 0
         *endif
         *yrmlg = l_fmlgs - ((l_fmthmlg * l_fmth) + (l_fwkmlg * l_fwk) +  ;
         *                   (l_fdlymlg * l_fdly)) 
         *yrmlgm = if(yrmlg > 0, yrmlg * l_fmlgchg, 0)
      endif
      if l_fmth > 0
         ytotm = l_fmth * l_fmthchg + l_fwk * l_fwkchg +    ;
                 l_fdly * l_fdlychg + l_fhr * l_fhrchg + yrmlgm
         if ytotm > yrtot 
            * restore old values
            l_fmth = 0
            l_fwk = yrwk
            l_fdly = yrdays 
            l_fhr = yrhr
         else
            l_fdly = yfdays - (l_fmth * 30) - (l_fwk * 7)
            l_fdly = if(l_fdly > 0, l_fdly, 0)
            l_fwktot = l_fwk * l_fwkchg
         endif
      else
         l_fwk = yrwk
         l_fdly = yrdays 
         l_fhr = yrhr
      endif

   elseif l_ftmtyp = 4
      do while l_fdly >= ygmthmin
         l_fmth = l_fmth + 1
         l_fdly = l_fdly - ygmthmax
         if l_fdly < 0
            l_fhr = 0
            l_fdly = 0
         endif
      enddo
   endif
   l_fmthtot = l_fmthchg * l_fmth
else
   l_fmthtot = 0.00
endif

if l_fdlychg > 0.00
   l_fdlytot = l_fdlychg * l_fdly
elseif l_fwkchg > 0.00
   if l_fdly > 0      && 01/10/94:(edc)  
      l_fwk = l_fwk + 1
      l_fwktot = l_fwktot + l_fwkchg
      l_fdly = 0
      l_fhr = 0 
   endif
elseif l_fmthchg > 0
   if l_fdly > 0.00 .or. l_fwk > 0.00
      l_fmth = l_fmth + 1
      l_fmthtot = l_fmthtot + l_fmthchg
      l_fwk = 0
      l_fdly = 0
      l_fhr = 0
   endif
endif
l_fhrtot = l_fhr * l_fhrchg
l_ftmetot = l_fdlytot + l_fwkdtot + l_fwktot + l_fmthtot + l_fhrtot

* --12.21.09: exclude jet center (RA begin with [3]) from [ERC]
if l_frloc = [EGE] .and. substr(alltrim(str(l_frano)),1,1) = [3]
   && do not charge [ERC]
else
* --11.15.08: check if early rental fee apply by compare to est T&M in open RA
* if l_ftmechg > l_ftmetot
* -- 01.12.09: grace = 1 day per allen
if l_ftmechg - l_ftmetot > l_fdlychg .or. ;
   l_fduein - l_fdatein >= 2                 && 01.14.09: return >2 days early
   * -- Apply early rental charge as [ERC]
   for i = 1 to 6      && add 2 add'l charge
      ystr1 = "L_FOITEM" + str (i, 1)
      if  empty(&ystr1) .or. &ystr1 = [ERC]
         &ystr1 = [ERC ]
         ystr2 = "L_FORATE" + str(i,1)
         &ystr2 = l_ftmechg - l_ftmetot
         exit
      endif
   next
else
   * -- zero out ERC just in case
   for i = 1 to 6      && add 2 add'l charge
      ystr1 = "L_FOITEM" + str (i, 1)
      if &ystr1 = [ERC]
         &ystr1 = [ERC ]
         ystr2 = "L_FORATE" + str(i,1)
         &ystr2 = 0
         exit
      endif
   next
endif
* --

endif
* --12.21.09

* calculate mileage charge 
l_fmlgfree = 0
if l_fwkd > 0
   if l_fwkdmlg = 0
      l_fmlgfree = l_fmlgs
   elseif l_fwkdmlg > 1
      l_fmlgfree = l_fmlgfree + l_fwkd * l_fwkdmlg
   endif
endif
if l_fdly > 0
   if l_fdlymlg = 0
      l_fmlgfree = l_fmlgs
   elseif l_fdlymlg > 1
      l_fmlgfree = l_fmlgfree + l_fdly * l_fdlymlg
   endif
endif
if l_fwk > 0
   if l_fwkmlg = 0
      l_fmlgfree = l_fmlgs
   elseif l_fwkmlg > 1
      l_fmlgfree = l_fmlgfree + l_fwk * l_fwkmlg
   endif
endif
if l_fmth > 0
   if l_fmthmlg = 0
      l_fmlgfree = l_fmlgs
   elseif l_fmthmlg > 1
      l_fmlgfree = l_fmlgfree + l_fmth * l_fmthmlg
   endif
endif

if l_fmlgfree >= l_fmlgs
   l_fmlgs = 0
else
   l_fmlgs = l_fmlgs - l_fmlgfree
endif
l_fmlgtot = l_fmlgs * l_fmlgchg

l_fdisctot = round (l_fdisc * (l_ftmetot + l_fmlgtot) / 100.00, 2)

do rrncacal2


******************************
* additional charge calculation
******************************
procedure rrncacal2
private yothcnt, ysurflag
f_popup ("Please Wait While Rental Charges...", .f.)

f_use ("ravm", 1)
seek l_funit

l_fothtot1 = 0.00          && taxable
l_fothtot2 = 0.00          && non taxable
l_fpo = .f.                && fuel purchase option

yothcnt = 1
ysurflag = .t.

* -- 10.15.08: for i = 1 to 4
for i = 1 to 6      && add 2 add'l charge
   ystr1 = "L_FOITEM" + str (i, 1)
   if  &ystr1 = "FPO"     && 08/29/94: fuel purchase option
      ystr2 = "L_FORATE" + str (i, 1)
      l_fpo = if(&ystr2 > 0, .t., .f.)
   elseif &ystr1 = "SUR1"
      ysurflag = .f.
      ystr1 = "L_FORATE" + str (i, 1)
      * l_fsurchg1 = &ystr1     && 03.10.09: edc
   endif
   *
   if .not. empty(&ystr1)
      yothcnt = yothcnt + 1
   endif

   ystr1 = "L_FORATE" + str (i, 1)
   ystr2 = "L_FODLY" + str (i, 1)
   if &ystr2
      ychg = &ystr1 * ydaychg
   else
      ychg = &ystr1
   endif
   ystr2 = "L_FOTOT" + str (i, 1)
   &ystr2 = ychg

   ystr1 = "L_FOTAX" + str (i, 1)
   if &ystr1
      l_fothtot1 = l_fothtot1 + ychg
   else
      l_fothtot2 = l_fothtot2 + ychg
   endif
next 

* -- 09.29.97 additional surchg (note: exempt vehicle)
* -- 10.15.08 if .not. empty(gsurchg1) .and. yothcnt <= 4 .and. ysurflag 
if .not. empty(gsurchg1) .and. yothcnt <= 6 .and. ysurflag     && -- 10.15.08
   ychg = &gsurchg1
   ystr1 = "L_FOITEM" + str (yothcnt, 1)
   &ystr1 = "SUR1"     
   ystr1 = "L_FODLY" + str (yothcnt, 1)
   &ystr1 = .f.
   ystr1 = "L_FORATE" + str (yothcnt, 1)
   &ystr1 = ychg
   ystr1 = "L_FOTOT" + str (yothcnt, 1)
   &ystr1 = ychg
   * l_fsurchg1 = ychg    && 03.10.09: edc
   ystr1 = "L_FOTAX" + str (yothcnt, 1)
   &ystr1 = gsurtx1   && 04.30.07
   if &ystr1
      l_fothtot1 = l_fothtot1 + ychg
   else
      l_fothtot2 = l_fothtot2 + ychg
   endif
endif
*
if l_fdmgtot = 0.00
   l_fdmgtot = l_fedmgtot
endif

setcolor (gblueget)
@ 13, 16 say l_fdly picture [999]
@ 14, 16 say l_fwkd picture [999]
@ 15, 16 say l_fwk picture [999]
@ 16, 16 say l_fmth picture [999]
@ 17, 16 say l_fhr picture [999]
@ 18, 16 say l_fmlgs picture [9999]
@ 20, 16 say l_fdisc picture [99]
@ 21, 16 say l_fcdwdays picture [999]
@ 21, 24 say l_fcdw picture [9999.99]
@ 22, 16 say l_fpaidays picture [999]
@ 22, 24 say l_fpai picture [9999.99]
@ 1, 71 say l_fcredtot picture [99999.99]
@ 2, 58 say l_ftax picture [99.99]
@ 4, 71 say l_fdmgtot picture [99999.99]

@ 13, 24 say l_fdlychg picture [9999.99]
@ 14, 24 say l_fwkdchg picture [9999.99]
@ 15, 24 say l_fwkchg picture [9999.99]
@ 16, 24 say l_fmthchg picture [9999.99]
@ 17, 24 say l_fhrchg picture [9999.99]
@ 18, 24 say l_fmlgchg picture [9999.99]

setcolor (gbluecolor)
@ 13, 37 say l_fdlytot picture [99999.99]
@ 14, 37 say l_fwkdtot picture [99999.99]
@ 15, 37 say l_fwktot picture [99999.99]
@ 16, 37 say l_fmthtot picture [99999.99]
@ 17, 37 say l_fhrtot picture [99999.99]
@ 18, 37 say l_fmlgtot picture [99999.99]
@ 20, 37 say l_fdisctot picture [99999.99]
@ 21, 37 say l_fcdwtot picture [99999.99]
@ 22, 37 say l_fpaitot picture [99999.99]

* edc:07/06/92 calculate surcharge

if .not. empty(ygsurchg)
   l_fsurchg = &ygsurchg
   @ 23, 15 say l_fothtot1 + l_fothtot2 picture [99999.99]
   @ 23, 24 say [Surcharge...]
   @ 23, 37 say l_fsurchg picture [99999.99] 
else
   @ 23, 37 say l_fothtot1 + l_fothtot2 picture [99999.99]
endif

@ 2, 71 say l_ftaxtot picture [99999.99]
@ 19, 37 say l_ftmetot + l_fmlgtot picture [99999.99]

* edc: 12/04/92
*if ysurtx
*   l_fothtot1 = l_fothtot1 + l_fsurchg
*else
*   l_fothtot2 = l_fothtot2 + l_fsurchg
*endif

f_popback ()


******************************
* calculate daily charge
******************************
function rrnca5

l_fdlytot = l_fdlychg * l_fdly
@ 13, 37 say l_fdlytot picture [99999.99]
return .t.


******************************
* calculate spec rate charge
******************************
function rrnca9

l_fwkdtot = l_fwkdchg * l_fwkd
@ 14, 37 say l_fwkdtot picture [99999.99]
return .t.


******************************
* calculate weekly charge
******************************
function rrnca11

l_fwktot = l_fwkchg * l_fwk
@ 15, 37 say l_fwktot picture [99999.99]
return .t.


******************************
* calculate monthly charge
******************************
function rrnca14

l_fmthtot = l_fmthchg * l_fmth
@ 16, 37 say l_fmthtot picture [99999.99]
return .t.


******************************
* calculate hourly charge
******************************
function rrnca17

l_fhrtot = l_fhrchg * l_fhr
@ 17, 37 say l_fhrtot picture [99999.99]
return .t.


******************************
* calculate mileage charge
******************************
function rrnca20

l_fmlgtot = l_fmlgchg * l_fmlgs
@ 18, 37 say l_fmlgtot picture [99999.99]
l_ftmetot = l_fdlytot + l_fwkdtot + l_fwktot + l_fmthtot + l_fhrtot
@ 19, 37 say l_ftmetot + l_fmlgtot picture [99999.99]
return .t.


******************************
* calculate discount
******************************
function rrnca22

l_fdisctot = round (l_fdisc * (l_fdlytot + l_fwkdtot + l_fwktot + l_fmthtot + ;
   l_fhrtot + l_fmlgtot) / 100.00, 2)
@ 20, 37 say l_fdisctot picture [99999.99]

if lastkey () = 5 .and. .not. yfreesell
   keyboard chr (5)
endif
return .t.


******************************
* calculate cdw
******************************
function rrnca25

l_fcdwtot = l_fcdwdays * l_fcdw
@ 21, 37 say l_fcdwtot picture "99999.99"
return .t.


******************************
* calculate pai
******************************
function rrnca28

l_fpaitot = l_fpaidays * l_fpai
@ 22, 37 say l_fpaitot picture "99999.99"
do rrncacal2
return .t.


******************************
* calculate taxable subtot
******************************
function rrnca34

ytot1 = l_ftmetot + l_fmlgtot - l_fdisctot + if (l_fcdwtax, l_fcdwtot, 0.00) ;
   + if (l_fpaitax, l_fpaitot, 0.00) + if (gfueltax, l_ffueltot, 0.00)  ;
   + if (ysurtx, l_fsurchg, 0.00) + l_fothtot1 - l_fcredtot
l_ftaxtot = round (ytot1 * l_ftax / 100.00, 2)

@ 2, 71 say l_ftaxtot picture "99999.99"
return .t.


******************************
* calculate gas charge
******************************
function rrnca351

if .not. f_valid (l_fgastyp $ "GM")
   return .f.
endif

l_ffueltot = l_fefueltot

* 08/29/94: edc fuel purchase option
if l_fpo
   l_ffueltot = 0
   return .t.
endif

f_use ("ravm", 1)
seek l_funit
if found ()
   *if l_fgastyp = "G" .or. ((l_fmlgin - l_fmlgout) > (ftank * fepa))
   * 12/28/93 (edc): correct fuel calc.
   if l_fgastyp = "G" .or. (l_fmlgin - l_fmlgout) > 50
      if l_ffuelin < l_ffuelout
         l_ffueltot = l_ffueltot + round (ftank * (l_ffuelout - l_ffuelin) / ;
            8 * ygfuelchg, 2)
      endif
   elseif fepa > 0            && 08/29/94 edc: avoid divide by 0
      l_ffueltot = l_ffueltot + round ((l_fmlgin - l_fmlgout) / ;
         fepa * ygfuelchg, 2)
   endif
endif
select raagr
return .t.

******************************
* calculate total
******************************
function rrnca35
* edc: 12/04/92
*ytot2 = if (l_fcdwtax, 0.00, l_fcdwtot) + if (l_fpaitax, 0.00, l_fpaitot) ;
*   + l_fothtot2 + l_ffueltot + l_fdmgtot
* edc: 01/27/95 exclude fuel when fuel is taxable
ytot2 = if (l_fcdwtax, 0.00, l_fcdwtot) + if (l_fpaitax, 0.00, l_fpaitot) ;
   + if (ysurtx, 0.00, l_fsurchg) + l_fothtot2   ;
   + if (gfueltax, 0.00, l_ffueltot) + l_fdmgtot
l_ftotal = round (ytot1 + ytot2 + l_ftaxtot, 2)

@ 2, 71 say l_ftaxtot picture "99999.99"
@ 5, 71 say l_ftotal picture [99999.99]
return .t.


******************************
* calculate amount due
******************************
function rrnca36

l_famtdue = round (l_ftotal - l_fdepamt, 2)
l_famt1 = l_famtdue - l_famt2 - l_famt3
@ 7, 71 say l_famtdue picture [99999.99]

return .t.


******************************
* check payment code 1
******************************
function rrnca51

if l_famt1 = 0.00
   return .t.
endif
if .not. str (l_fpaycod1, 1) $ "123"
   return .f.
endif
if l_fpaycod1 = 1 .or. l_fpaycod1 = 2
   l_fdbacct1 = space (10)
endif
if l_fpaycod1 <> 1
   l_fccnum1 = space (20)
   l_fccexp1 = "  /  "
   l_fauthcd1 = space (6)
endif
return .t.


******************************
* check pay code 3
******************************
function rrnca57

if l_famt3 = 0.00
   return .t.
endif
if .not. str (l_fpaycod3, 1) $ "12"
   return .f.
endif
if l_fpaycod1 = 2
   l_fccnum3 = space (20)
   l_fccexp3 = "  /  "
   l_fauthcd3 = space (6)
endif
return .t.


******************************
* check pay code 2
******************************
function rrnca54

if l_famt2 = 0.00
   return .t.
endif
if .not. str (l_fpaycod2, 1) $ "123"
   return .f.
endif
if l_fpaycod2 = 1 .or. l_fpaycod2 = 2
   l_fdbacct2 = space (10)
endif
if l_fpaycod2 <> 1
   l_fccnum2 = space (20)
   l_fccexp2 = "  /  "
   l_fauthcd2 = space (6)
endif
return .t.


******************************
* check payment type 1
******************************
function rrnca38

if lastkey () = 18
   return .t.
endif
if f_valid (good_paytype (l_fpaytyp1, @l_fpaycod1), "Invalid Payment Type!!!")
   return f_valid (rrnca51 (), "Invalid Payment Type!!!")
else
   return .f.
endif


******************************
* check credit card number 1
******************************
function rrnca39

if l_fpaycod1 <> 1 .or. (yccnum1 = l_fccnum1 .and. yamtdue1 >= l_famt1 .and. ;
      yamtdue1 <> 0.00)
   return .t.
endif
if f_valid (good_card (l_fccnum1, @l_fpaytyp1), "Invalid Credit Card!!!")
   setcolor (gblueget)
   @ 10, 57 say l_fpaytyp1
   setcolor (gbluecolor)
   return .t.
else
   return .f.
endif

******************************
* get authorization code for credit card 1
******************************
function rrnca40

private yauthcd

if ((yccnum1 = l_fccnum1 .and. yamtdue1 >= l_famt1 .and. yamtdue1 <> 0.00) ;
      .or. l_fpaycod1 <> 1 .or. .not. gccmodem) .and. .not. empty (l_fauthcd1)
   return .t.
endif
yccnum1 = l_fccnum1
yamtdue1 = l_famt1
if l_fpaycod1 = 1 .and. good_cctype (l_fpaytyp1, @yauthonly1)
   f_use ("racred", 1)
   seek l_floc + str (l_frano, 6) + l_fccnum1
   private yauthtot
   yauthtot = 0.00
   do while l_floc + str (l_frano, 6) + l_fccnum1 = floc + str (frano, 6) + ;
         fccnum
      if frectype = __gccauth
         yauthtot = yauthtot + if (ftranstyp = "C", -1, 1) * abs (fauthamt)
         if empty (l_fauthcd1)
            l_fauthcd1 = fauthcode
         endif
      endif
      skip
   enddo
   if yauthtot < l_famt1
      if raagr->fhldamt >= l_famt1 .and. l_fccnum1 = raagr->fccnum1 .and. ;
            .not. empty (raagr->fauthcd1) .and. (l_floc <> l_frloc)
         l_fauthcd1 = raagr->fauthcd1
         f_findblank ()
         replace fccnum with l_fccnum1, fcctype with l_fpaytyp1
         replace fccexp with l_fccexp1, fauthcode with l_fauthcd1
         replace fauthamt with l_famt1-yauthtot, fauthonly with yauthonly1
         replace frectype with __gccauth, fauthstat with yauthstat1
         replace fauthdate with date (), fauthtime with time ()
         replace ffname with l_ffname, flname with l_flname
         * 11/11/93: card swipe or manual
         replace fmname with yccswipe1
         *
         replace floc with l_floc, frano with l_frano
         replace frloc with l_floc, ftranstyp with "S"     && 12.01.06: use l_floc
         commit
         unlock
         f_fupdate ("A")
         yrectyp1 = __gccuncap
      else
         yauthcd = l_fauthcd1
         yret = newauth (if (l_famt1 >= 0.00, "S", "C"), l_fccnum1, ;
            l_fccexp1, l_famt1 - yauthtot, @l_fauthcd1, @yauthstat1)
         if empty (l_fauthcd1)
            l_fauthcd1 = yauthcd
         endif
         if yret = "D"
            yccswipe1 = gccswipe      && save gccswipe set in tformat
            f_findblank ()
            replace fccnum with l_fccnum1, fcctype with l_fpaytyp1
            replace fccexp with l_fccexp1, fauthcode with l_fauthcd1
            replace fauthamt with l_famt1-yauthtot, fauthonly with yauthonly1
            replace frectype with __gccauth, fauthstat with yauthstat1
            replace fauthdate with date (), fauthtime with time ()
            replace ffname with l_ffname, flname with l_flname
            * 11/11/93 card or manual (set in tformat)
            replace fmname with gccswipe
            *
            replace floc with l_floc, frano with l_frano
            replace frloc with l_floc, ftranstyp with "S"   && 12.01.06: use l_floc
            commit
            unlock
            f_fupdate ("A")
            yrectyp1 = __gccuncap
         elseif yret = "E"
            yrectyp1 = __gccautherr
         else
            yrectyp1 = __gccspecauth
         endif
      endif
   else
      yrectyp1 = __gccuncap
   endif
endif
set cursor on
setcolor (gblueget)
@ 13, 73 say l_fauthcd1
setcolor (gbluecolor)
return .t.

******************************
* calculate balance for payment 2
******************************
function rrnca41

l_famt2 = l_famtdue - l_famt1 - l_famt3
if iszero (l_famt2) .and. iszero (l_famt3)
   yendedit = .t.
   keyboard chr (18)
   l_famt2 = 0.00
endif
return .t.


******************************
* check payment type 2
******************************
function rrnca42

if lastkey () = 18
   return .t.
endif
if f_valid (good_paytype (l_fpaytyp2, @l_fpaycod2), "Invalid Payment Type!!!")
   return f_valid (rrnca54 (), "Invalid Payment Type!!!")
else
   return .f.
endif


******************************
* check credit card number 2
******************************
function rrnca44

if l_fpaycod2 <> 1 .or. (yccnum2 = l_fccnum2 .and. yamtdue2 = l_famt2 ;
      .and. yamtdue2 <> 0.00)
   return .t.
endif
if f_valid (good_card (l_fccnum2, @l_fpaytyp2), "Invalid Credit Card!!!")
   setcolor (gblueget)
   @ 15, 57 say l_fpaytyp2
   setcolor (gbluecolor)
   return .t.
else
   return .f.
endif


******************************
* get authorization code for credit card 2
******************************
function rrnca45

private yauthcd
if ((yccnum2 = l_fccnum2 .and. yamtdue2 = l_famt2 .and. yamtdue2 <> 0.00) ;
      .or. l_fpaycod2 <> 1 .or. .not. gccmodem) .and. .not. empty (l_fauthcd2)
   return .t.
endif
yccnum2 = l_fccnum2
yamtdue2 = l_famt2
if l_fpaycod2 = 1 .and. good_cctype (l_fpaytyp2, @yauthonly2)
   f_use ("racred", 1)
   seek l_floc + str (l_frano, 6) + l_fccnum2
   private yauthtot
   yauthtot = 0.00
   do while l_floc + str (l_frano, 6) + l_fccnum2 = floc + str (frano, 6) + ;
         fccnum
      if frectype = __gccauth
         yauthtot = yauthtot + if (ftranstyp = "C", -1, 1) * abs (fauthamt)
         if empty (l_fauthcd2)
            l_fauthcd2 = fauthcode
         endif
      endif
      skip
   enddo
   if yauthtot < l_famt2
      if raagr->fhldamt >= l_famt2 .and. l_fccnum2 = raagr->fccnum1 .and. ;
            .not. empty (raagr->fauthcd1) .and. (l_floc <> l_frloc)
         l_fauthcd2 = raagr->fauthcd1
         f_findblank ()
         replace fccnum with l_fccnum2, fcctype with l_fpaytyp2
         replace fccexp with l_fccexp2, fauthcode with l_fauthcd2
         replace fauthamt with l_famt2-yauthtot, fauthonly with yauthonly2
         replace frectype with __gccauth, fauthstat with yauthstat2
         replace fauthdate with date (), fauthtime with time ()
         replace ffname with l_ffname, flname with l_flname
         * 11/11/93: card swipe or manual
         replace fmname with yccswipe1         && use old cc1
         *
         replace floc with l_floc, frano with l_frano
         replace frloc with l_floc, ftranstyp with "S"      && 12.01.06: use l_floc
         commit
         unlock
         f_fupdate ("A")
         yrectyp2 = __gccuncap
      else
         yauthcd = l_fauthcd2
         yret = newauth (if (l_famt2 >= 0.00, "S", "C"), l_fccnum2, ;
            l_fccexp2, l_famt2, @l_fauthcd2, @yauthstat2)
         if empty (l_fauthcd2)
            l_fauthcd2 = yauthcd
         endif
         if yret = "D"
            yccswipe2 = gccswipe      && save gccswipe set in tformat
            f_findblank ()
            replace fccnum with l_fccnum2, fcctype with l_fpaytyp2
            replace fccexp with l_fccexp2, fauthcode with l_fauthcd2
            replace fauthamt with l_famt2-yauthtot, fauthonly with yauthonly2
            replace frectype with __gccauth, fauthstat with yauthstat2
            replace fauthdate with date (), fauthtime with time ()
            replace ffname with l_ffname, flname with l_flname
            * 11/11/93 card or manual (set in tformat)
            replace fmname with gccswipe
            *
            replace floc with l_floc, frano with l_frano
            replace frloc with l_floc, ftranstyp with "S"    && 12.01.06: use l_floc
            commit
            unlock
            f_fupdate ("A")
            yrectyp2 = __gccuncap
         elseif yret = "E"
            yrectyp2 = __gccautherr
         else
            yrectyp2 = __gccspecauth
         endif
      endif
   else
      yrectyp2 = __gccuncap
   endif
endif
set cursor on
setcolor (gblueget)
@ 18, 73 say l_fauthcd2
setcolor (gbluecolor)
return .t.


******************************
* calculate balance for payment 3
******************************
function rrnca46

l_famt3 = l_famtdue - l_famt1 - l_famt2
if iszero (l_famt3)
   yendedit = .t.
   keyboard chr (18)
   l_famt3 = 0.00
endif
return .t.


******************************
* check payment type 3
******************************
function rrnca47

if lastkey () = 18
   return .t.
endif
if f_valid (good_paytype (l_fpaytyp3, @l_fpaycod3), "Invalid Payment Type!!!")
   return f_valid (rrnca57 (), "Invalid Payment Type!!!")
else
   return .f.
endif


******************************
* check credit card number 3
******************************
function rrnca48

if l_fpaycod3 <> 1
   return .t.
endif
if yccnum3 = l_fccnum3 .and. yamtdue3 >= l_famt3 .and. yamtdue3 <> 0.00
   return .t.
endif
if f_valid (good_card (l_fccnum3, @l_fpaytyp3), "Invalid Credit Card!!!")
   setcolor (gblueget)
   @ 20, 57 say l_fpaytyp3
   setcolor (gbluecolor)
   return .t.
else
   return .f.
endif


******************************
* get authorization code for credit card 3
******************************
function rrnca49

private yauthcd
if ((yccnum3 = l_fccnum3 .and. yamtdue3 = l_famt3 .and. yamtdue3 <> 0.00) ;
      .or. l_fpaycod3 <> 1 .or. .not. gccmodem) .and. .not. empty (l_fauthcd3)
   return .t.
endif
yccnum3 = l_fccnum3
yamtdue3 = l_famt3
if l_fpaycod3 = 1 .and. good_cctype (l_fpaytyp3, @yauthonly3)
   f_use ("racred", 1)
   seek l_floc + str (l_frano, 6) + l_fccnum3
   private yauthtot
   yauthtot = 0.00
   do while l_floc + str (l_frano, 6) + l_fccnum3 = floc + str (frano, 6) + ;
         fccnum
      if frectype = __gccauth
         yauthtot = yauthtot + if (ftranstyp = "C", -1, 1) * abs (fauthamt)
         if empty (l_fauthcd2)
            l_fauthcd2 = fauthcode
         endif
      endif
      skip
   enddo
   if yauthtot < l_famt3
      if raagr->fhldamt >= l_famt3 .and. l_fccnum3 = raagr->fccnum1 .and. ;
            .not. empty (raagr->fauthcd1) .and. (l_floc <> l_frloc)
         l_fauthcd3 = raagr->fauthcd1
         f_findblank ()
         replace fccnum with l_fccnum3, fcctype with l_fpaytyp3
         replace fccexp with l_fccexp3, fauthcode with l_fauthcd3
         replace fauthamt with l_famt3-yauthtot, fauthonly with yauthonly3
         replace frectype with __gccauth, fauthstat with yauthstat3
         replace fauthdate with date (), fauthtime with time ()
         replace ffname with l_ffname, flname with l_flname
         * 11/11/93: card swipe or manual
         replace fmname with yccswipe1       && use old cc1
         *
         replace floc with l_floc, frano with l_frano
         replace frloc with l_floc, ftranstyp with "S"      && 12.01.06: use l_floc
         commit
         unlock
         f_fupdate ("A")
         yrectyp3 = __gccuncap
      else
         yauthcd = l_fauthcd3
         yret = newauth (if (l_famt3 >= 0.00, "S", "C"), l_fccnum3, ;
            l_fccexp3, l_famt3, @l_fauthcd3, @yauthstat3)
         if empty (l_fauthcd3)
            l_fauthcd3 = yauthcd
         endif
         if yret = "D"
            yccswipe3 = gccswipe      && save gccswipe set in tformat
            f_findblank ()
            replace fccnum with l_fccnum3, fcctype with l_fpaytyp3
            replace fccexp with l_fccexp3, fauthcode with l_fauthcd3
            replace fauthamt with l_famt3-yauthtot, fauthonly with yauthonly3
            replace frectype with __gccauth, fauthstat with yauthstat3
            replace fauthdate with date (), fauthtime with time ()
            replace ffname with l_ffname, flname with l_flname
            * 11/11/93 card or manual (set in tformat)
            replace fmname with gccswipe
            *
            replace floc with l_floc, frano with l_frano
            replace frloc with l_floc, ftranstyp with "S"    && 12.01.06: use l_floc
            commit
            unlock
            f_fupdate ("A")
            yrectyp3 = __gccuncap
         elseif yret = "E"
            yrectyp3 = __gccautherr
         else
            yrectyp3 = __gccspecauth
         endif
      endif
   else
      yrectyp3 = __gccuncap
   endif
endif
set cursor on
setcolor (gblueget)
@ 23, 73 say l_fauthcd3
setcolor (gbluecolor)
return .t.


******************************
* check if the 3 payment balance equals the total balance
******************************
function rrnca50

return f_valid (iszero (l_famtdue - l_famt1 - l_famt2 - l_famt3), ;
   "Payments And Total Due Are Not Balanced!!!")


******************************
* F1 help
******************************
procedure rrncahlp

private yvar, yscn, ycolor, ycalday, ytmtyp
yvar = upper (alltrim (readvar ()))
if yvar $ "L_FDLY;L_FDLYCHG;L_FWKD;L_FWKDCHG;L_FWK;L_FWKCHG;L_FMTH;" + ;
      "L_FMTHCHG;L_FHR;L_FHRCHG;L_FMLGS;L_FMLGCHG"

*  change time and mileage calc type. and whether to us calendar day

   ycalday = l_fcalday
   ytmtyp = l_ftmtyp
   ycolor = setcolor (gsubcolor)
   yscn = f_box (13, 45, 20, 78)

   @ 14, 47 say "Rate Charge Type............"
   @ 15, 50 say "1. Daily"
   @ 16, 50 say "2. Weekend"
   @ 17, 50 say "3. Weekly"
   @ 18, 50 say "4. Monthly"
   @ 19, 47 say "Calendar Day Calculation...."

   setcolor (gsubget)
   @ 14, 76 say l_ftmtyp pict "9"
   do while .t.
      f_getnum (@l_ftmtyp, 14, 76, "", "9")
      if f_valid (l_ftmtyp >= 1 .and. l_ftmtyp <= 4, "Invalid Entry")
         exit
      endif
   enddo
   @ 19, 76 say l_fcalday pict "Y"
   f_getlgc (19, 76, @l_fcalday)
   setcolor (ycolor)
   f_restbox (yscn)
   if ycalday <> l_fcalday .or. ytmtyp <> l_ftmtyp
      do rrncacal1
   endif
elseif yvar = "L_FFUELTOT"

   * display individual exchanged vehicle charge

   f_use ("raagrx", 3)
   seek l_floc + str (l_frano, 6)
   if f_valid (found (), "No Exchange Vehicle Records Found!!!")
      f_pick_f (3, 17, "", "Exch Unit컴횯amage컴컴횲uel", ;
         "funit+str(fdmgtot,9,2)+str(ffueltot,9,2)","X", ;
         "floc+str(frano,6)","l_floc+str(l_frano,6)")
   endif
   use
elseif yvar = "L_FDMGTOT"

   * enter damage description

   f_use ("ravm", 1)
   seek l_funit
   if found ()
      ycolor = setcolor (gsubcolor)
      yscn = f_box (05, 55, 10, 78)
      l_fdmg1 = fdmg1
      l_fdmg2 = fdmg2
      l_fdmg3 = fdmg3
      @ 06, 57 say "Damage:"
      setcolor (gsubget)
      @ 07, 57 say l_fdmg1
      @ 08, 57 say l_fdmg2
      @ 09, 57 say l_fdmg3
      yptr = 1
      do while .t.
         do case
         case yptr = 1
            f_getfld (@l_fdmg1, 07, 57, "W/N", 0, replicate ("X", 20), .t.)
         case yptr = 2
            f_getfld (@l_fdmg2, 08, 57, "W/N", 0, replicate ("X", 20), .t.)
         case yptr = 3
            f_getfld (@l_fdmg3, 09, 57, "W/N", 0, replicate ("X", 20), .t.)
         endcase
         ykey = lastkey ()
         if (ykey = 24 .or. ykey = 13) .and. yptr < 3
            yptr = yptr + 1
         elseif ykey = 5 .and. yptr > 1
            yptr = yptr - 1
         elseif ykey = 27 .or. ykey = 13 .or. ykey = 3 .or. ykey = 18
            exit
         endif
      enddo
      f_fupdate ("C")
      reclock ()
      replace fdmg1 with l_fdmg1, fdmg2 with l_fdmg2, fdmg3 with l_fdmg3
      commit
      unlock
      f_restbox (yscn)
      setcolor (ycolor)
   endif
   select raagr
elseif yvar $ "L_FCDW;L_FPAI;L_FCDWDAYS;L_FPAIDAYS"
   * update additional charge
   do rrnoaget2
   do rrncacal2
endif


******************************
* F3 - allow freeseel using supervisor's user account
******************************
procedure rrncahlp2

if yfreesell
   return
endif
private yscn, ycolor, yusr, ypass, ysp, ychr, yok
ycolor = setcolor (gsubcolor)
yscn = f_box (10, 05, 13, 59)
@ 11, 07 say "Enter Username With Ability Of Free Sell"
@ 12, 07 say "Password ..............................."
yusr = space (3)
yok = .f.
do while .t.
   if .not. f_getfld (@yusr, 11, 48, "W/N", 3, "!!!")
      setcolor (ycolor)
      f_restbox (yscn)
      return
   endif
   f_use ("RAUSR")
   seek yusr
   if .not. f_valid (found (), "Invalid User Name!!!")
      loop
   endif
   f_use ("RAGROUP")
   for n = 0 to 9
      if str (n, 1) $ rausr->fgroup
         go (n + 1)
         if ffreesell
            yok = .t.
            exit
         endif
      endif
   next
   if .not. f_valid (yok, "User Does Not Have Free Sell Right!!!")
      loop
   endif
   use
   select rausr

   set console off
   ypass = ""
   ysp = 48
   setcolor (gsubget)
   @ 12, ysp say space (10)
   do while len (ypass) < 11
      @ 12, ysp say ""
      wait to ychr
      if len (ychr) > 0
         @ 12, ysp say "X"
         ysp = ysp + 1
         ypass = ypass + upper (ychr)
      else
         exit
      endif
   enddo
   set console on
   if .not. f_valid (f_truncate (ypass, len (fpasswd)) = fpasswd, ;
         "Invalid Password, Please Retry ...")
      @ 12, 48 say space (10)
      loop
   else
      select rausr
      use
      f_compute (@yfreesell, .t.)
      exit
   endif
enddo
setcolor (ycolor)
f_restbox (yscn)


******************************
function rrncaret

parameters xtyp

if .not. yfreesell
   if lastkey () = 5
      if xtyp <> 0
         keyboard chr (5)
      endif
   else
      if xtyp <> 2
         keyboard chr (13)
      endif
   endif
endif
return .t.

