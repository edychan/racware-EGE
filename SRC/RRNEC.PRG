* ===========================================================================
* Enter batch contracts
*
* date: 05/01/91
* author: KST
*
* revision
* date: 04/26/93
* edc: validate check out/in date & time
* date: 04/27/93
* edc: search customer for repeat customer info. (lname+fname)
* date: 04/27/93
* edc: add foreign location
* date: 12/4/93
* edc: change zip code to alphanumeric
* 05.13.98
* edc: add remote handheld module edit check
* ------------------------------------------------------------------
* 08.27.08: if frhr > 2 => fdays + 1
* 10.15.08: add 2 add'l charge 5 & 6
* ===========================================================================
f_use ("RAAGRH")
restore from (gmempath + "RAAGRH2") additive
restore from (gmempath + "RAAGRH") additive
f_getscn ("RAAGR")
set key 28 to rrnech
set key -1 to rrnech2
yendedit = .f.

l_floc = gloc
l_frloc = gloc
l_ftrack = ""    && 01.24.05

* --10.15.08
l_foitem5 = [    ]
l_foitem6 = [    ]
l_fotot5 = 0.00
l_fotot6 = 0.00
* --

@ 02,11 get l_floc picture "!!!!!!!!!!" ;
   valid f_valid (.not. empty (l_floc) .and. l_floc $ gusrloc)
@ 02,22 get l_frano picture "999999" valid f_valid (l_frano > 0 .or. lastkey() = 5)
if f_rd () = 27
   close databases
   set key 28 to
   return
endif
f_use ("raagr", 1)
seek l_floc + str (l_frano, 6)
if found ()
   if raagr->frastat = "X"       && 05.13.98
      f_valid (.f., "RA in Transit status... ")
      close data 
      set key 28 to
      return
   else
      ynewra = "O"
      yendedit = .f.
      f_retrieve ()
   endif
else
   f_use ("raagrh", 1)
   seek l_floc + str (l_frano, 6)
   if found ()
      ynewra = "C"
      yendedit = .t.
      f_retrieve ()
   else
      yendedit = .f.
      ynewra = "N"
   endif
endif

if .not. empty (l_feunit)
   ytmp = l_feunit
   l_feunit = l_funit
   l_funit = ytmp
   ytmp = l_femlgout
   l_femlgout = l_fmlgout
   l_fmlgout = ytmp
   ytmp = l_femlgin
   l_femlgin = l_fmlgin
   l_fmlgin = ytmp
else
   l_fexdate = l_fdatein
   l_fdatein = ctod (space (8))
   l_fextime = l_ftimein
   l_ftimein = "  :  "
endif
do rrnecget
f_rd ()
do while .t.
   if yendedit
      if ynewra $ "NO"
         ykey = f_confirm ("[C]onfirm  [E]dit  [V]oid", "CEV")
      else
         ykey = f_confirm ("[C]onfirm  [E]dit  [I]gnore changes", "CEI")
      endif
   else
      if ynewra $ "NO"
         ykey = f_confirm ("[E]dit  [V]oid", "EV")
      else
         ykey = f_confirm ("[E]dit  [I]gnore changes", "EI")
      endif
   endif
   do case
   case ykey = "C"
      f_popup ("Please Wait While Saving Closed Contract...", .f.)
      if .not. empty (l_feunit)
         ytmp = l_feunit
         l_feunit = l_funit
         l_funit = ytmp
         ytmp = l_femlgout
         l_femlgout = l_fmlgout
         l_fmlgout = ytmp
         ytmp = l_femlgin
         l_femlgin = l_fmlgin
         l_fmlgin = ytmp
      else
         l_fdatein = l_fexdate
         l_fexdate = ctod (space (8))
         l_ftimein = l_fextime
         l_fextime = "  :  "
      endif
      select raagrh
      l_frastat = "C"
      if ynewra $ "NO"
         append blank
      else
         f_fupdate ("C")
      endif
      f_replace ()
      if ynewra $ "NO"
         f_fupdate ("A")
      endif
      if ynewra = "O"
         f_use ("ravm")
         seek l_funit
         if found ()
            f_fupdate ("C")
            reclock ()
            replace fstatus with if (gautopkvh, "I", "A")
            replace fckindt with l_fdatein
            replace fmileage with l_fmlgin
            replace futime with dtos (l_fdatein) + l_ftimein
            l_fulic = flic
            commit
            unlock
         endif
         use
         f_use ("RAAGRX", 3)
         append blank
         l_fexchg = .f.
         f_replace ()
         if .not. empty (l_fexdate)
            reclock ()
            replace fdateout with raagr->fexdate, ftimeout with raagr->fextime
            commit
            unlock
         endif
         f_fupdate ("A")
         use
         select raagr
         f_clrrec ()
         use
      endif
      if ynewra = "N"
         f_use ("ravm", 1)
         seek l_funit
         l_fulic = if (found (), flic, space (10))
         if .not. empty (l_feunit)
            seek l_feunit
            ylic = if (found (), flic, space (10))
         endif
         use

         f_use ("raagrx")
         append blank
         l_fexchg = .f.
         f_replace ()
         if .not. empty (l_fexdate)
            reclock ()
            replace fdateout with l_fexdate, ftimeout with l_fextime
            commit
            unlock
         endif
         f_fupdate ("A")
         if .not. empty (l_feunit)
            append blank
            l_fexchg = .t.
            f_replace ()
            reclock ()
            replace fdatein with l_fexdate, ftimein with l_fextime
            replace fmlgout with l_femlgout, fmlgin with l_femlgin
            replace fmlgtot with 0.00, ftmetot with 0.00, fulic with ylic
            replace funit with l_feunit
            commit
            unlock
            f_fupdate ("A")
         endif
      endif

      if .not. empty (l_fresvno)
         f_use ("RARES")
         seek l_fresvno + l_floc
         if found ()
            f_fupdate ("C")
            reclock ()
            replace frano with l_frano       && 01/05/94: edc
            replace fresvstat with "U"
            replace ftnm with l_ftmetot + l_fmlgtot
            replace fcomm with round (fcommpct * ftnm / 100.00, 2)
            commit
            unlock
         endif
         use
      endif

      if l_fdbrno = 0
         f_use ("RADTR")
         l_fmlg = l_fmlgin - l_fmlgout + l_femlgin - l_femlgout
         if ynewra = "C"
            do while .t.
               seek "C" + l_floc + str (l_frano, 6)
               if .not. found ()
                  exit
               endif
               f_fupdate ("D")
               reclock ()
               delete
               unlock
            enddo
            do while .t.
               seek "F" + l_floc + str (l_frano, 6)
               if .not. found ()
                  exit
               endif
               f_fupdate ("D")
               reclock ()
               delete
               unlock
            enddo
            do while .t.
               seek "T" + l_floc + str (l_frano, 6)
               if .not. found ()
                  exit
               endif
               f_fupdate ("D")
               reclock ()
               delete
               unlock
            enddo
         endif
         f_findblank ()
         l_frectype = if (l_floc <> l_frloc, "F", "C")
         
         * 08.27.08
         if l_frhr > 2
            l_fdays = l_fdays + 1
         endif
         * 08.27.08

         f_replace ()
         f_fupdate ("A")

         if l_floc <> l_frloc
            f_findblank ()
            l_frloc = raagrh->floc
            l_floc = raagrh->frloc
            l_frectype = "T"
            f_replace ()
            f_fupdate ("A")
         endif
         use
      endif
      use
      exit
      f_popback ()
   case ykey = "E"
      do rrnecget
      f_rd ()
      loop
   case ykey $ "VI"
      exit
   endcase
enddo
close databases
set key 28 to


******************************
procedure rrnecget

setcolor (gbluecolor)
@ 02,11 say l_floc
@ 02,22 say l_frano picture "999999"
if ynewra <> "C"
   @ 02,34 get l_fdbrno picture "9999"
else
   @ 02,34 say l_fdbrno picture "9999"
endif
@ 03,11 get l_frloc picture "!!!!!!!!!!" valid f_valid (l_frloc $ gusrloc)
@ 03,22 say "Foreign    [Y/N]" 
@ 03,30 get l_fforeign pict "Y" 
@ 04,11 get l_flname valid f_valid (.not. empty (l_flname))
@ 05,11 get l_ffname valid rrnec10 ()
@ 06,11 get l_faddr
@ 07,11 get l_fcity
@ 08,11 get l_fstate picture "!!"
@ 08,14 get l_fzip picture "XXXXX-XXXX"
@ 09,11 get l_fphone picture "999-999-9999"
@ 10,11 get l_flic
@ 10,36 get l_flicst picture "!!"
@ 11,11 get l_flicexp
@ 11,30 get l_fdob
@ 13,11 get l_fcrpnm
@ 14,11 get l_fcrpaddr
@ 15,11 get l_fcrpcity
@ 16,11 get l_fcrpstate picture "!!"
@ 16,14 get l_fcrpzip picture "XXXXX-XXXX"
@ 17,11 get l_fcrpph picture "999-999-9999"
@ 18,11 get l_freferal valid f_valid (f_verify ("RAREFR", 1, upper (l_freferal)))
@ 03,53 get l_ftmetot picture "99999.99"
@ 04,53 get l_fmlgtot  picture "99999.99" valid rrnec1 ()
@ 05,53 say l_fmlgtot + l_ftmetot picture "99999.99"

* -- 10.15.08:
@ 06,53 get l_fsurchg picture "@Z 99999.99"
@ 07,45 get l_foitem1 valid rrnec9 ()
@ 07,53 get l_fotot1 picture "@Z 99999.99"
@ 08,45 get l_foitem2 valid rrnec9 ()
@ 08,53 get l_fotot2 picture "@Z 99999.99"
@ 09,45 get l_foitem3 valid rrnec9 ()
@ 09,53 get l_fotot3 picture "@Z 99999.99"
@ 10,45 get l_foitem4 valid rrnec9 ()
@ 10,53 get l_fotot4 picture "@Z 99999.99"
@ 11,45 get l_foitem5 valid rrnec9 ()
@ 11,53 get l_fotot5 picture "@Z 99999.99"
@ 12,45 get l_foitem6 valid rrnec9 ()
@ 12,53 get l_fotot6 picture "@Z 99999.99"

@ 03,70 get l_fcdwtot picture "@Z 99999.99"
@ 04,70 get l_fpaitot picture "@Z 99999.99"
@ 05,70 get l_ffueltot picture "@Z 99999.99"
@ 06,70 get l_fdmgtot picture "@Z 99999.99"
@ 07,70 get l_fdisctot picture "@Z 99999.99"
@ 08,70 get l_fcredtot picture "@Z 99999.99"
@ 09,70 get l_ftaxtot picture "@Z 99999.99" valid rrnec2 ()
* --
@ 10,70 say l_ftotal picture "99999.99"
@ 11,70 get l_fdepamt picture "99999.99" valid rrnec3 ()
@ 12,70 say l_famtdue picture "99999.99"

* -- 10.15.08

@ 15,54 get l_fpaytyp1 picture "!!!" valid f_valid (good_paytype (l_fpaytyp1))
@ 15,59 get l_famt1 picture "99999.99" valid rrnec5 ()
@ 15,69 get l_fdbacct1 picture replicate ("!", len (l_fdbacct1)) ;
   valid f_valid (if ("DB" $ l_fpaytyp1, .not. empty (l_fdbacct1), .t.))
@ 16,54 get l_fpaytyp2 picture "!!!" valid ;
   f_valid (l_famt2 = 0.00 .or. good_paytype (l_fpaytyp2))
@ 16,59 get l_famt2 picture "99999.99" valid rrnec7 ()
@ 16,69 get l_fdbacct2 picture replicate ("!", len (l_fdbacct2)) ;
   valid f_valid (if ("DB" $ l_fpaytyp2, .not. empty (l_fdbacct2), .t.))
@ 17,54 get l_fpaytyp3 picture "!!!" valid ;
   f_valid (l_famt3 = 0.00 .or. good_paytype (l_fpaytyp3))
@ 17,59 get l_famt3 picture "99999.99" valid ;
   f_valid (iszero (l_famtdue - l_famt1 - l_famt2 - l_famt3))
@ 21,02 get l_funit valid f_valid (.not. empty (l_funit))
@ 21,13 get l_fdateout
@ 21,22 get l_ftimeout pict "99:99" valid f_valid (f_timeok (@l_ftimeout))
@ 21,28 get l_fexdate valid f_valid (l_fexdate >= l_fdateout)
@ 21,37 get l_fextime pict "99:99" valid f_valid (f_timeok (@l_fextime))
@ 21,44 get l_fmlgout picture "99999"
@ 21,50 get l_fmlgin picture "99999" valid f_valid (l_fmlgin >= l_fmlgout)
@ 22,2 get l_feunit
@ 22,28 get l_fdatein 
@ 22,37 get l_ftimein pict "99:99" valid rrnec11 ()
@ 22,44 get l_femlgout picture "99999"
@ 22,50 get l_femlgin picture "99999" valid f_valid (l_femlgin >= l_femlgout)
@ 20,69 get l_fdays picture "9999"
@ 20,74 get l_frhr picture "99"
@ 21,63 get l_fresvno
@ 22,63 get l_frefno
@ 23,67 get l_fstamp valid f_compute (@yendedit, .t.)
setcolor (gbluecolor)


******************************
function rrnec1

@ 05,53 say l_fmlgtot + l_ftmetot picture "99999.99"
return .t.


******************************
function rrnec2

l_ftotal = round (l_fmlgtot + l_ftmetot - l_fdisctot - l_fcredtot + l_fotot1 ;
   + l_fotot2 + l_fotot3 + l_fotot4 + l_fotot5 + l_fotot6 + l_fsurchg + ;   && 10.15.08           
   + l_fcdwtot + l_ftaxtot + l_fpaitot + l_ffueltot + l_fdmgtot, 2)
@ 10,70 say l_ftotal picture "99999.99"
return .t.


******************************
function rrnec3

l_famtdue = round (l_ftotal - l_fdepamt, 2)
@ 12,70 say l_famtdue picture "99999.99"

l_famt1 = l_famtdue - l_famt2 - l_famt3

return .t.


******************************
function rrnec5

if iszero (l_famt1 - l_famtdue)
   l_famt2 = 0.00
   l_famt3 = 0.00
   l_fpaytyp2 = "   "
   l_fpaytyp3 = "   "
elseif iszero (l_famt2)
   l_famt2 = l_famtdue - l_famt1
endif
return .t.


******************************
function rrnec7

if iszero ((l_famt1 + l_famt2) - l_famtdue)
   l_famt3 = 0.00
   l_fpaytyp3 = "   "
else
   l_famt3 = l_famtdue - l_famt1 - l_famt2
endif
return .t.


******************************
function rrnec9

private yvar
yvar = alltrim (upper (readvar ()))

if empty (&yvar)
   return .t.
else
   return f_valid (f_verify ("RAPAYCD", 1, upper (&yvar)))
endif


******************************
function rrnec10

if lastkey () = 5
   return .t.
endif

if .not. f_valid (.not. empty(l_ffname),"This field cannot be blank!")
   return .f.
endif 
* search customer file
if ynewra = "N"        && only search on new ra's
   f_use ("racust",1)
   go top
   if .not. eof()
      seek upper(l_flname)
      do while .not. eof() .and. racust->flname = l_flname
         if racust->ffname = l_ffname
            if f_pick_f (2, 2, "", "Name컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴횭irthday횫cct #", ;
                  "f_truncate (trim (ffname) + [ ] + flname, 28) + " + ;
                  "if (fhold, [ On Hold ], [ ------- ]) + dtoc (fbirthdt)" ;
                  + "+ [ ] + fcustno")
               l_faddr = racust->faddr
               l_fdob = racust->fbirthdt
               l_flic = racust->flic
               l_flicst = racust->flicst
               l_flicexp = racust->fexpdt
               l_fcrpno = racust->fcrpno
               l_fcrpaddr = racust->fcaddr
               l_fcrpcity = racust->fccity
               l_fcrpnm = racust->fcompany
               l_fcrpph = racust->fcphone
               l_fcrpstate = racust->fcstate
               l_fcity = racust->fcity
               l_fcrpzip = racust->fczip
               l_fcustno = racust->fcustno
               l_flic = racust->flic
               l_flicst = racust->flicst
               l_flicexp = racust->fexpdt
               l_fphone = racust->fphone
               l_fstate = racust->fstate
               l_fzip = racust->fzip
               l_ffname = racust->ffname
               l_flname = racust->flname
               l_finsur1 = racust->finsur1
               l_finsur2 = racust->finsur2
               setcolor (gblueget)
               @ 05,11 say l_ffname 
               @ 06,11 say l_faddr
               @ 07,11 say l_fcity
               @ 08,11 say l_fstate 
               @ 08,14 say l_fzip 
               @ 09,11 say l_fphone 
               @ 10,11 say l_flic
               @ 10,36 say l_flicst
               @ 11,11 say l_flicexp
               @ 11,30 say l_fdob
               @ 13,11 say l_fcrpnm
               @ 14,11 say l_fcrpaddr
               @ 15,11 say l_fcrpcity
               @ 16,11 say l_fcrpstate 
               @ 16,14 say l_fcrpzip 
               @ 17,11 say l_fcrpph 
               setcolor (gbluecolor)
               set cursor on
               keyboard chr (13)
            endif
            exit
         endif
         skip
      enddo
   endif
endif
return .t.


******************************
* check check in time and date
******************************
function rrnec11

if lastkey () = 5
   return .t.
endif

if empty (l_feunit)
   ydatein = l_fexdate
   ytimein = l_fextime
else
   if .not. f_valid (f_timeok (@l_ftimein))
      return .f.
   endif
   ydatein = l_fdatein
   ytimein = l_ftimein
endif

if l_fdateout < ydatein .or.   ;
   (l_fdateout = ydatein .and. ytimein >= l_ftimeout)
   yto = val (substr (l_ftimeout, 1, 2)) * 60 + ;
      val (substr (l_ftimeout, 4, 2))
   yti = val (substr (ytimein, 1 ,2)) * 60 + val (substr (ytimein, 4, 2))
   ymins = (ydatein - l_fdateout) * 24 * 60 + yti - yto
   l_fdays = int (ymins / 1440)
   ymins = ymins - l_fdays * 1440
   if l_fdays < 1
      l_fdays = 1
      l_frhr = 0
   else
      l_frhr = ymins / 60
   endif
   return .t.
else
   return f_valid (.f., "Please check Check-in Date & Time ...")
endif

******************************
procedure rrnech

private yvar, yptr, yscn, ycolor, yname, yarray [2], ystr
yvar = alltrim (upper (readvar ()))
ycolor = setcolor (gsubcolor)
do case
case yvar = "L_FOITEM"
   f_use ("RAPAYCD")
   go top
   if .not. eof ()
      set softseek on
      seek upper (&yvar)
      if eof ()
         go bottom
      endif
      set softseek off
      if f_pick_f (17, 37, "", "Code횯esc컴컴컴컴컴컴컴Rate", ;
            "fpaycd + [ ] + fitem + [ ] + str (frate, 7, 2)")
         &yvar = fpaycd
         keyboard chr (13)
      endif
   endif
case yvar = "L_FPAYTYP"
   f_use ("RAPAYTYP")
   go top
   if f_valid (.not. eof (), "No Valid Payment Type Found!!!")
      locate for fpaycode >= &yvar
      if eof ()
         go bottom
      endif
      if f_pick_f (15, 68, "", "", "fpaycode")
         &yvar = rapaytyp->fpaycode
         keyboard chr (13)
      endif
   endif
case yvar = "L_FREFERAL"
   f_use ("RAREFR")
   go top
   if f_valid (.not. eof (), "No Valid Referral Code Found!!!")
      set softseek on
      seek l_freferal
      if eof ()
         go bottom
      endif
      set softseek off
      if f_pick_f (15, 5, "", "", "frefr+[ - ]+fdesc")
         &yvar = rarefr->frefr
         keyboard chr (13)
      endif
   endif
otherwise
   f_valid (.f., "No Help information for this Field ...")
endcase
setcolor (ycolor)

* =====================================
procedure rrnech2
private yn1, yn2, yn3, yn4, yn5, yn6, yn7, yn8

   ycolor = setcolor (gsubcolor)
   yscn = f_box (13, 9, 22, 62)
   yn1 = substr(l_fremark,1,50)
   yn2 = substr(l_fremark,51,50)
   yn3 = substr(l_fremark,101,50)
   yn4 = substr(l_fremark,151,50)
   yn5 = substr(l_fremark,201,50)
   yn6 = substr(l_fremark,251,50)
   yn7 = substr(l_fremark,301,50)
   yn8 = substr(l_fremark,351,50)
   * @ 17, 11 say "Remark"
   setcolor (gsubget)
   @ 14, 11 say yn1
   @ 15, 11 say yn2
   @ 16, 11 say yn3
   @ 17, 11 say yn4
   @ 18, 11 say yn5
   @ 19, 11 say yn6
   @ 20, 11 say yn7
   @ 21, 11 say yn8
   yptr = 1
   do while .t.
      do case
      case yptr = 1
         f_getfld (@yn1, 14, 11, "", 0, replicate ("X", 50), .t.)
      case yptr = 2
         f_getfld (@yn2, 15, 11, "", 0, replicate ("X", 50), .t.)
      case yptr = 3
         f_getfld (@yn3, 16, 11, "", 0, replicate ("X", 50), .t.)
      case yptr = 4
         f_getfld (@yn4, 17, 11, "", 0, replicate ("X", 50), .t.)
      case yptr = 5
         f_getfld (@yn5, 18, 11, "", 0, replicate ("X", 50), .t.)
      case yptr = 6
         f_getfld (@yn6, 19, 11, "", 0, replicate ("X", 50), .t.)
      case yptr = 7
         f_getfld (@yn7, 20, 11, "", 0, replicate ("X", 50), .t.)
      case yptr = 8
         f_getfld (@yn8, 21, 11, "", 0, replicate ("X", 50), .t.)
      endcase
      ykey = lastkey ()
      if (ykey = 24 .or. ykey = 13) .and. yptr < 8
         yptr = yptr + 1
      elseif ykey = 5 .and. yptr > 1
         yptr = yptr - 1
      elseif ykey = 27 .or. ykey = 13 .or. ykey = 3 .or. ykey = 18
         exit
      endif
   enddo

   l_fremark = yn1 + yn2 + yn3 + yn4 + yn5 + yn6 + yn7 + yn8
   f_restbox (yscn)

   setcolor (ycolor)

