* ===========================================================================
* add/update reservation record
*
* date: 05/01/91
* author: KST
*
* revision
* date : 09/25/92
* edc: new features for insurance replacement rentals
* date: 01/28/93
* edc: warn user about duplicate res.
* date: 01/29/93
* edc: add more fields for insurance replacement rentals
* date: 10/07/93
* edc: save old values for comparsion to stop from replacing rates.
* date: 11/03/93
* edc: change claim# to Reference # (recall at open RA)
* date: 12/04/93
* edc: take out resv grid
* date: 12/05/93
* edc: handle advance res deposit
* date: 12/21/93
* edc: f_rvstat, if empty(fresvstat) causes PROC Type Mismatch L+C
*      correction: if empty(fresvstat) return "UNKNOWN"
* date: 02/15/94
* edc: handle advance deposit
* date: 08/09/94
* edc: specialty vehicle res table
* date: 04/17/95
* edc: rrvfmup7, allow user update travel agent file info.
* date: 12/07/95: 
* edc: allow cc deposit for open res
* 12.08.97
* change <f2> to accept driver lic. & exp. date (for dl-ege only)
* 11.16.98
* popup rate remark if not empty
* 07.09.99: set century on
* ===========================================================================

parameters xtyp
private yatc, ycustno, ycrpno, yrate, yclass, yloc, ycomm, yresvno, yunit
private yrdateout, yrdatein, yans, ydateout

f_clrscn ("Reservation File")
f_popup ("Please Wait...")
set century on       && 07.09.99
set key 28 to rrvfmhlp
set key -1 to rrvfmget
set key -2 to rrvfmfs

f_popback ()
if xtyp = "A"
   yans = "D"
   do while .t.
      if yans = "D"
         restore from (gmempath + "RARES") additive
         l_fcode = grate
         l_fdateout = date ()
         l_floc = gloc
         l_frloc = gloc
         l_fbookdate = date ()
         l_fid = gusrid
      endif      
      yfreesell = gfreesell
      ydateout = ctod (space (8))
      store space (13) to yrdateout, yrdatein
      store "~" to ycustno, ycrpno, yrate, yclass, yloc, yunit, yatc, ;
            yresvno
      f_use ("raloc")
      seek gloc
      l_fresvno = ""
      if l_fresvno <> strtran (str (swcalcxorb (gloc, 10) * 10000000 + ;
            fresvno, 10), " ", "0")
         f_fupdate ("C")
         reclock ()
         if fresvno >= 9999999
            replace fresvno with 1
         else
            replace fresvno with fresvno + 1
         endif
         commit
         unlock
         l_fresvno = strtran (str (swcalcxorb (gloc, 10) * 10000000 + ;
               fresvno, 10), " ", "0")
      endif
      l_fresvstat = "O"
      f_screen (0, "RARES")
      do while .t.
         if .not. yfreesell
            setcolor (gredcolor)
            @ 24, 01 say "F3 Overwrite Free Sell"
         endif
         setcolor (gbluecolor)
         f_rd ()
         if empty (l_fresvno)
            ykeyin = f_confirm ("[E]dit  [V]oid", "EV")
         else
            ykeyin = f_confirm ("[C]onfirm  [E]dit  [V]oid", "CEV")
         endif
         do case
         case ykeyin = "C"
            * 01/28/93: warn user about duplicate res.
            f_use ("rares")
            set order to 2
            seek 'O'+upper(l_flname)
            yans = "Y"
            do while .not. eof() .and. upper(rares->flname) = upper(l_flname)
               if rares->fdateout = l_fdateout
                  yans = f_confirm ("Warning: Duplicate Reservation Found!" + ;
                  " Continue ?[Y/N]", "YNyn")
                  exit
               else
                 skip
               endif
            enddo
            set order to 1
            if yans $ "Nn"
               exit
            endif
            * 
            append blank
            f_replace ()
            f_fupdate ("A")

            *f_use ("ravres")
            *f_relvres ()
            *f_findblank ()
            *replace funit with l_funit, ftype with "R", ffrom with l_fdateout
            *replace fto with l_fdatein, fnumber with l_fresvno
            *replace ffromtime with l_ftimeout, ftotime with l_ftimein
            *commit
            *unlock
            *f_fupdate ("A")
            *use

            f_use ("rartm")
            if f_getrate (l_fcode, l_floc, l_fclass, l_fdateout)
               f_fupdate ("C")
               reclock ()
               replace fresvcnt with fresvcnt + 1
               commit
               unlock
            endif
            use
            if .not. empty (l_fatc)
               f_use ("raagnt", 1)
               seek l_fatc
               if found ()
                  f_fupdate ("C")
                  reclock ()
                  replace fres with fres + 1
                  replace factdt with date ()
                  commit
                  unlock
               endif
               use
            endif
            * handle advance deposit 12/05/93
            if l_fdepamt > 0
               f_use ("radtr")
               f_findblank ()
               replace floc with gloc, frano with 999999, frloc with gloc
               replace flname with l_flname, funit with l_fresvno
               replace frectype with "A"
               replace famt1 with l_fdepamt, fpaytyp1 with "CA"
               replace ftotal with l_fdepamt
               commit
               unlock
               use
            endif
            *************************************
            exit
         case ykeyin = "E"
            f_screen (1, "RARES")
            loop
         case ykeyin = "V"
            if f_confirm ("Are You Sure To Void This Reservation? [Y/N]", ;
                  "YN") = "Y"
               exit
            else
               keyboard chr (18)
               loop
            endif
         endcase
      enddo
      *f_relvres ()
      yans = f_confirm ("Want to enter another one? [S]imilar/" + ;
            "[D]ifferent one/[N]o", "SDN")
      if yans = "N"
         exit
      endif
   enddo
else
   restore from (gmempath + "RARES") additive
   yfreesell = gfreesell
   f_use ("rares")
   if eof ()
      f_popup ("No Reservation File Found!!!. Press Any Key to Continue", .t.)
      close databases
      set key 28 to
      set key -2 to
      set key -1 to
      return
   endif
   private yarray [5], yptr, ycolor, yscn, ykey
   yarray [1] = " Confirmation No.  "
   yarray [2] = " Last Name         "
   yptr = f_pick_a (02, 05, "", "", YARRAY, 2, 1)
   if yptr = 0
      set key 28 to
      set key -2 to
      set key -1 to
      return
   endif
   ycolor = setcolor (gsubcolor)
   yscn = f_box (2, 21, 4, 58)
   do case
   case yptr = 1
      ykey = "l_fresvno"
      ytitle = "Stat컴컴Resv No.컴횸ocation컴횼ame컴컴컴컴컴컴컴컴컴컴컴컴�" ;
         + "Resv Dte"
      yexp = "f_rvstat (fresvstat) + [ ] + fresvno + [ ] + floc + [ ] + " + ;
         "f_truncate (trim (ffname) + [ ] + flname, 28) + [ ] + " + ;
         "dtoc (fdateout)"
      @ 3, 23 say "Confirmation No. ......"
      @ 3, 47 get l_fresvno picture "!!!!!!!!!!"
   case yptr = 2
      ykey = "l_fresvstat + upper (l_flname)"
      ytitle = "Stat컴컴Name"
      yexp = "f_rvstat (fresvstat) + [ ] + f_truncate (trim (flname) + [, ] " + ;
         "+ ffname, 28) + [ Pick Up Car At ] + floc + [ ] + dtoc (fdateout)"
      @ 3, 23 say "Last Name ........."
      @ 3, 43 get l_flname
   endcase
   if f_rd () = 27
      setcolor (ycolor)
      close databases
      set key 28 to
      set key -2 to
      set key -1 to
      return
   endif
   set order to (yptr)
   if yptr = 2
      yarray [1] = " Open             "
      yarray [2] = " Used (RA Closed) "
      yarray [3] = " Used (RA Open)   "
      yarray [4] = " No Show          "
      yarray [5] = " Cancel           "
      yptr = f_pick_a (04, 30, "", "", YARRAY, 5, 1)
      if yptr = 0
         set key 28 to
         set key -2 to
         set key -1 to
         return
      endif
      l_fresvstat = substr ("OUXNC", yptr, 1)
   endif
   f_restbox (yscn)
   setcolor (ycolor)
   set softseek on
   seek &ykey
   if eof ()
      go bottom
   endif
   set softseek off

   if .not. found () .or. yptr = 2
      if .not. f_pick_f (02, 77 - len (&yexp), "", ytitle, yexp)
         close databases
         set key 28 to
         set key -2 to
         set key -1 to
         return
      endif
   endif

   f_retrieve ()
   do rrvfmsm      && 10/07/93 (edc): save old values
   f_screen (0, "RARES")

   do while .t.
      * 04/28/94: edc show cancellation date correctly
      if l_fresvstat = "O"
         @ 17,45 say "Checkout Date....."
         @ 17,64 say "        "
         * 12/07/95: edc allow cc deposit for open res
         ykeyin = f_confirm ("[U]pdate  [C]ancel  [R]esv Deposit  " + ;
            "[N]ext  [P]revious  [Q]uit", "UCRNPQ")
      elseif l_fresvstat $ "X;U"
         @ 17,45 say "Checkout Date....."
         @ 17,64 say l_fdateout
         ykeyin = f_confirm ("[D]etail  [N]ext  " + ;
            "[P]revious  [Q]uit", "DNPQ")
      else
         if l_fresvstat = "C"
            @ 07,23 say  l_fdateout+l_fdays
            @ 17,45 say "Date Cancelled...."
            @ 17,64 say l_fdatein
         else
            @ 17,45 say "Checkout Date....."
            @ 17,64 say "        "
         endif
         ykeyin = f_confirm ("[R]esv Deposit  [D]etail  [N]ext  " + ;
            "[P]revious  [Q]uit", "RDNPQ")
      endif
      do case
      * 02/15/94: handle res. deposit
      case ykeyin = "R"
         clear gets
         setcolor (gsubcolor)
         yscn = f_box (13, 14, 19, 63)
         ypaytyp = rares->fcctype
         yamt = 0.00
         yexp = rares->fccexp
         yccnum = rares->fccnum
         yauthcode = space (6)
         yauthstat = space (20)
         yrectype = __gccuncap
         yauthonly = .f.
         @ 14, 16 say "Deposit Type............. "
         @ 15, 16 say "CC Number ............... "
         @ 16, 16 say "Expiration............... "
         @ 17, 16 say "Amount .................. "
         @ 18, 16 say "Auth Code ............... "
         do while .t.
            ycode = 0
            @ 14, 42 get ypaytyp picture "!!!" ;
               valid f_valid (good_paytype (ypaytyp, @ycode), ;
               "Invalid Payment Type!!!")
            @ 15, 15 clear to 18, 62
            if f_rd () = 27
               exit
            endif
            if good_cctype (ypaytyp, @yauthonly)
               @ 15, 16 say "CC Number ............... "
               @ 16, 16 say "Exp ..................... "
               @ 17, 16 say "Amount .................. "
               @ 18, 16 say "Auth Code ............... "
               @ 15, 42 get yccnum picture replicate ("9", 20) ;
                  valid f_valid (good_card (yccnum), "Invalid Credit Card!!!")
               @ 16, 42 get yexp picture "99/99" ;
                  valid f_valid (f_expired (yexp), "Card Expired!!!")
               @ 17, 42 get yamt picture "99999.99" valid f_valid (yamt >=0)
               @ 18, 42 get yauthcode picture "!!!!!!"
            else
               @ 18, 16 say "Amount .................. "
               @ 18, 42 get yamt picture "99999.99" valid f_valid (yamt >=0)
            endif
            f_rd ()
            if empty(yauthcode) .and. ycode = 1
               yauthstat = space (30)
               if get_auth ("S", yccnum, yexp, yamt, @yauthcode, ;
                            @yauthstat) = 0
                 if f_valid (auth_ok (yauthstat, @yauthcode), ;
                            "Warning! Credit Card Authorization is rejected!")
                    @ 18, 42 say yauthcode
                    yrectype = 3
                 else
                    yrectype = 6
                 endif
               endif
            endif
            ykeyin = f_confirm ("[C]onfirm   [E]dit   [I]gnore", "CEI")
            if ykeyin = "C"
               select rares
               f_fupdate ("C")
               reclock ()
               replace fdepamt with fdepamt + yamt
               commit
               unlock
               if ycode = 1          
                  f_use ("RACRED", 1)
                  f_findblank ()
                  replace fauthonly with yauthonly, fauthamt with abs (yamt)
                  replace fauthcode with yauthcode, fauthstat with yauthstat
                  replace fauthdate with date (), fauthtime with time ()
                  replace fccexp with yexp, fccnum with yccnum
                  replace fcctype with ypaytyp, ffname with rares->ffname
                  replace flname with rares->flname, floc with rares->floc
                  replace frano with 999999, frectype with yrectype
                  replace frloc with rares->floc
                  if empty (yauthcode) 
                     replace ftranstyp with "F"
                  else
                     replace ftranstyp with "S"
                  endif
                  commit
                  unlock
                  f_fupdate ("A")
                  use
               endif
               f_use ("RADTR")
               f_findblank ()
               replace floc with rares->floc, frano with 999999
               replace funit with rares->fresvno, frloc with rares->floc
               replace flname with rares->flname, fpaytyp1 with ypaytyp
               replace foitem1 with "RES", fotot1 with yamt
               replace famt1 with yamt, frectype with "C"
               replace ftotal with yamt           
               commit
               unlock
               f_fupdate ("A")
               use
               f_screen (0, "RARES")
               exit
            elseif ykeyin = "E"
               loop
            else
               exit
            endif
         enddo
         select rares
         f_restbox (yscn)
         setcolor (gbluecolor)

      case ykeyin = "D"
         ycolor = setcolor (gsubcolor)
         yscn = f_box (5, 4, 13, 75)
         
         @ 06, 6 say "Reference#............."             && 11/03/93 (edc)
         @ 07, 6 say "Last/First Name........"
         @ 08, 9 say "Address............."
         @ 09, 9 say "City/St/Zip........."     
         @ 10, 9 say "Phone #............."
         @ 11, 9 say "Driver Lic/State...."
         @ 12, 9 say "Expire/DOB.........."
         setcolor (gsubget)
         @ 06, 30 say l_frefno
         @ 07, 30 say l_flname
         @ 07, 45 say l_ffname
         @ 08, 30 say l_faddr
         @ 09, 30 say l_fcity
         @ 09, 46 say l_fstate
         @ 09, 50 say l_fzip
         @ 10, 30 say l_fphone
         @ 11, 30 say l_fcinsur1             && driver lic
         @ 11, 52 say substr(l_fshop,1,2)    && state
         @ 12, 30 say l_fexp1                && expiration
         @ 12, 40 say l_fcexp1               && DOB
         f_popup ("Press Any Key to Continue...", .t.)
         f_restbox (yscn)
         setcolor (ycolor)
      case ykeyin = "U"
         do while .t.
            if .not. yfreesell
               setcolor (gredcolor)
               @ 24, 01 say "F3 Overwrite Free Sell"
            endif
            setcolor (gbluecolor)
            f_rd ()
            if empty (l_fresvno)
               ykey = f_confirm ("[E]dit  [I]gnore Changes", "EI")
            else
               ykey = f_confirm ("[C]onfirm  [E]dit  [I]gnore Changes", "CEI")
            endif
            do case
            case ykey = "C"
               f_use ("rartm")
               if f_getrate (rares->fcode, rares->floc, rares->fclass, ;
                     rares->fdateout)
                  f_fupdate ("C")
                  reclock ()
                  replace fresvcnt with fresvcnt - 1
                  commit
                  unlock
               endif
               if f_getrate (l_fcode, l_floc, l_fclass, l_fdateout)
                  f_fupdate ("C")
                  reclock ()
                  replace fresvcnt with fresvcnt + 1
                  commit
                  unlock
               endif
               * advance deposit  12/05/93
               if l_fdepamt <> rares->fdepamt
               f_use ("radtr")
               f_findblank ()
               replace floc with gloc, frano with 999999, frloc with gloc
               replace flname with l_flname, funit with l_fresvno
               replace frectype with "A"
               replace famt1 with l_fdepamt-rares->fdepamt, fpaytyp1 with "CA"
               replace ftotal with l_fdepamt-rares->fdepamt
               commit
               unlock
               use
               endif
               ********************************
               if l_fatc <> rares->fatc
                  if .not. empty (l_fatc)
                     f_use ("raagnt", 1)
                     seek l_fatc
                     if found ()
                        f_fupdate ("C")
                        reclock ()
                        replace fres with fres + 1
                        replace factdt with date ()
                        commit
                        unlock
                     endif
                  endif
                  if .not. empty (rares->fatc)
                     f_use ("raagnt", 1)
                     seek rares->fatc
                     if found ()
                        f_fupdate ("C")
                        reclock ()
                        replace fres with fres - 1
                        commit
                        unlock
                     endif
                  endif
               endif
               *f_use ("ravres", 1)
               *if rares->funit <> l_funit
               *   if .not. empty (rares->funit)
               *      seek rares->funit + "R" + rares->fresvno
               *      if found ()
               *         f_clrrec ()
               *      endif
               *   endif
               *   if .not. empty (l_funit)
               *      f_relvres ()
               *      f_findblank ()
               *      replace funit with l_funit, ffrom with l_fdateout
               *      replace fto with l_fdatein, ftype with "R"
               *      replace fnumber with l_fresvno
               *      replace ffromtime with l_ftimeout, ftotime with l_ftimein
               *      commit
               *      unlock
               *      f_fupdate ("A")
               *   endif
               *elseif .not. empty (l_funit) .and. ;
               *      (rares->fdateout <> l_fdateout .or. ;
               *      rares->ftimeout <> l_ftimeout .or. ;
               *      rares->fdatein <> l_fdatein .or. ;
               *      rares->ftimein <> l_ftimein)
               *   seek rares->funit + "R" + rares->fresvno
               *   if found ()
               *      f_fupdate ("C")
               *      reclock ()
               *      replace ffrom with l_fdateout, fto with l_fdatein
               *      replace ffromtime with l_ftimeout, ftotime with l_ftimein
               *      commit
               *      unlock
               *   else
               *      f_findblank ()
               *      replace funit with l_funit, ffrom with l_fdateout
               *      replace fto with l_fdatein, ftype with "R"
               *      replace ffromtime with l_ftimeout
               *      replace ftotime with l_ftimein
               *      replace fnumber with rares->fresvno
               *      commit
               *      unlock
               *      f_fupdate ("A")
               *   endif
               *endif
               *use
               f_use ("rares")
               f_fupdate ("C")
               f_replace ()
               exit
            case ykey = "E"
               f_screen (1, "RARES")
               loop
            case ykey = "I"
               if f_confirm ("Are You Sure to Ignore the Change? [Y/N]", ;
                     "YN") = "Y"
                  exit
               else
                  keyboard chr (18)
                  loop
               endif
               exit
            endcase
         enddo
         exit
      case ykeyin = "C"
         if f_confirm ("Are you sure? [Y/N]", "YN") = "Y"
            clear gets
            l_fdatein = date ()
            @ 17, 45 say "Date Cancelled...."
            @ 17, 64 get l_fdatein
            * 06/08/94 (edc) update remarks field
            @ 21, 23 get l_fremark1
            @ 22, 23 get l_fremark2
            if f_rd () = 27
               exit
            endif
            f_fupdate ("C")
            reclock ()
            replace fdatein with l_fdatein      && 04/06/94 (edc)
            replace fresvstat with "C"
            replace fremark1 with l_fremark1, fremark2 with l_fremark2
            commit
            unlock
            *if .not. empty (rares->funit)
            *   f_use ("ravres")
            *   seek rares->funit + "R" + rares->fresvno
            *   if found ()
            *      f_clrrec ()
            *   endif
            *   use
            *endif
            f_use ("rartm")
            if f_getrate (rares->fcode, rares->floc, rares->fclass, ;
                  rares->fdateout)
               f_fupdate ("C")
               reclock ()
               replace fresvcnt with fresvcnt - 1
               commit
               unlock
            endif
            if .not. empty (rares->fatc)
               f_use ("raagnt", 1)
               seek rares->fatc
               if found ()
                  f_fupdate ("C")
                  reclock ()
                  replace fres with fres - 1
                  commit
                  unlock
               endif
            endif
            exit
         else
            f_screen (1, "RARES")
         endif
      case ykeyin = "N"
         clear gets
         skip 1
         if eof ()
            f_popup ("End of file. Press Any Key to Continue...", .t.)
            go bottom
         else
            f_retrieve ()
            do rrvfmsm      && 10/07/93 (edc): save old values
            f_screen (1, "RARES")
         endif
      case ykeyin = "P"
         clear gets
         skip -1
         if bof ()
            f_popup ("Top of file. Press Any Key to Continue...", .t.)
            go top
         else
            f_retrieve ()
            do rrvfmsm      && 10/07/93 (edc): save old values
            f_screen (1, "RARES")
         endif
      case ykeyin = "Q"
         clear gets
         exit
      endcase
   enddo
   *f_relvres ()
endif

close databases
set century off
set key 28 to
set key -1 to
set key -2 to


******************************
procedure rrvfmsm
* save old values
ycustno = fcustno
ycrpno = fcrpno
yrate = fcode
yclass = fclass
yloc = floc
ydateout = fdateout
yatc = fatc
yresvno = l_fresvno
yunit = l_funit
yrdateout = dtos (fdateout) + ftimeout
yrdatein = dtos (fdatein) + ftimein

return

******************************
procedure rrvfmfs

if yfreesell
   return
endif
private yscn, ycolor, yusr, ypass, ysp, ychr
ycolor = setcolor (gsubcolor)
yscn = f_box (1, 24, 4, 78)
@ 2, 26 say "Enter Username With Ability Of Free Sell"
@ 3, 26 say "Password ..............................."
yusr = space (3)
do while .t.
   if .not. f_getfld (@yusr, 2, 67, "W/N", 3, "!!!")
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
            yfreesell = .t.
            exit
         endif
      endif
   next
   if .not. f_valid (yfreesell, "User Does Not Have Free Sell Right!!!")
      loop
   endif
   use
   f_use ("rausr")

   set console off
   ypass = ""
   ysp = 67
   setcolor (gsubget)
   @ 3, ysp say space (10)
   do while len (ypass) < 11
      @ 3, ysp say ""
      wait to ychr
      if len (ychr) > 0
         @ 3, ysp say "X"
         ysp = ysp + 1
         ypass = ypass + upper (ychr)
      else
         exit
      endif
   enddo
   set console on
   if .not. f_valid (f_truncate (ypass, len (fpasswd)) = fpasswd, ;
         "Invalid Password, Please Retry ...")
      @ 3, 67 say space (10)
      loop
   endif
   f_use ("rausr")
   use
   exit
enddo
setcolor (ycolor)
f_restbox (yscn)


******************************
procedure rrvfmhlp

private yvar, yscn, ycolor, ylname, yfname, ycustno
yvar = upper (readvar ())
ycolor = setcolor (gsubcolor)
if yvar $ "L_FCLASS;L_FCODE"
   if empty(l_fcode)
      do rrndr
   else
      f_use ("RARTM")
      set filter to (empty(fdatefrom) .and. l_fdateout <= fdateto) .or.  ;
                 (l_fdateout >= fdatefrom .and. l_fdateout <= fdateto) .or. ;
                 (empty(fdateto) .and. l_fdateout >= fdatefrom) .or. ;
                 (empty(fdatefrom) .and. empty(fdateto))
      go top
      seek l_fcode+l_floc
      if eof ()
         f_valid (.f., "Invalid Rate Code...")
      else
         set century off
         f_pick_f (02, 01, "", "훀ate컴횸ocation컴횮lass컴From컴�" + ;
                  "컴훂o컴컴컴횯ly컴컴훇kd컴컴컴Wk컴컴횺th", ;
                  "fcode+[ ]+if(empty(floc),[ALL       ],floc)+[ ]+" + ;
                  "fclass+[ ]+dtoc(fdatefrom)+[ ]+dtoc(fdateto)+[ ]+" + ;
                  "str(fdlychg,8,2)+str(fwkdchg,8,2)+str(fwkchg,8,2)+" + ;
                  "str(fmthchg,8,2)", "rrndrd","fcode+floc","l_fcode+l_floc")
         set century on
      endif
      select rartm
      set filter to
      use
   endif
elseif yvar $ "L_FCUSTNO;L_FLOC;L_FRLOC;L_FDATEOUT;L_FDATEIN,L_FTIMEIN"
   ylname = l_flname
   yscn = f_box (2, 23, 4, 58)
   @ 3, 25 say "Last Name ... "
   if .not. f_getfld (@ylname, 3, 39, "W/N")
      setcolor (ycolor)
      f_restbox (yscn)
      return
   else
      if empty (ylname)
         ycustno = l_fcustno
         @ 3, 25 say "Customer # .... "
         if .not. f_getfld (@ycustno, 3, 41, "W/N")
            setcolor (ycolor)
            f_restbox (yscn)
            return
         endif
      else
         ycustno = ""
      endif
   endif
   if empty (ycustno)
      f_use ("racust", 1)
   else
      f_use ("racust", 2)
      ylname = ycustno
   endif
   set softseek on
   seek upper (ylname)
   if eof ()
      go bottom
   endif
   set softseek off
   if f_pick_f (2, 2, "", "Name컴컴컴컴컴컴컴컴컴컴컴Customer #컴컴�" +   ;
         "컴City컴컴컴컴컴컴횾hone�", "f_truncate (trim (ffname) + [ ] + " + ;
         "flname, 26)+[ ]+fcustno+[ ]+substr(fcity,1,13)+[ ]+fstate+[ ]+fphone")
      if f_valid (.not. fhold, "Customer is on HOLD status!!!")
         l_fcustno = racust->fcustno
         if yvar = "L_FCUSTNO"
            keyboard chr (13)
         endif
      endif
   endif
   set filter to
   f_use ("rares")
   f_restbox (yscn)
elseif yvar = "L_FCRPNO"
   ylname = space (25)
   yscn = f_box (2, 23, 4, 65)
   @ 3, 25 say "Company Name  "
   if .not. f_getfld (@ylname, 3, 39, "W/N")
      setcolor (ycolor)
      f_restbox (yscn)
      return
   endif
   f_use ("racrp", 2)
   set softseek on
   seek upper (ylname)
   if eof ()
      go bottom
   endif
   set softseek off
   if f_pick_f (2, 2, "", "Company Name컴컴컴컴컴컴컴컴컴컴컴Corporate No.컴�" + ;
         "Phone No.", "fcompany + if (fhold, [ On Hold ], [ ------- ]) + fcrpno + [ ] + fphone")
      if f_valid (.not. fhold, "Corporate Account is on HOLD status!!!")
         l_fcrpno = racrp->fcrpno
         if .not. empty (racrp->frate)
            l_fcode = racrp->frate
         endif
         l_fdisc = racrp->fdisc
         keyboard chr (13)
      endif
   endif
   set filter to
   f_use ("rares")
   f_restbox (yscn)
elseif yvar = "L_FATC"
   f_use ("raagnt", 1)
   go top
   if f_valid (.not. eof (), "No Travel Agents File Found!!!")
      set softseek on
      seek l_fatc
      if eof ()
         go bottom
      endif
      set softseek off
      if f_pick_f (11, 30, "", "", "fatc + [ - ] + fcompany + [  Tel ] " ;
            + "+ fphone", "")
         l_fatc = raagnt->fatc
         keyboard chr (13)
      endif
   endif
elseif yvar = "L_FAGENT"
   f_use ("raagnt", 2)
   go top
   if f_valid (.not. eof (), "No Travel Agents File Found!!!")
      set softseek on
      seek upper (l_fagent)
      if eof ()
         go bottom
      endif
      set softseek off
      if f_pick_f (11, 30, "", "", "fcompany + [ - ] + fatc + [  Tel ] " ;
            + "+ fphone", "")
         l_fatc = raagnt->fatc
         keyboard chr (5)
      endif
   endif
elseif yvar = "L_FUNIT"    && 08/09/94: specialty vehicle res table
   f_use ("ravm",1)
   set filter to fresv
   go top
   if eof ()
      f_valid (.f., "No Help information for this Field ...")
   else
      do while .t.
         f_pick_f (03, 10, "", "Unit No.컴횮lass훊r횮olor컴컴컴Model컴컴컴�" ;
            + "Desc컴컴컴컴Miles", "funit + [ ] + fclass + [ ] + fyear + " + ;
            "[ ]+fcolor+[ ]+fmodel+[ ]+substr(fdesc,1,15)+[ ]+str (fmileage, 6)",  ;
            "rrvgrid")
         if lastkey () = 27
            exit
         endif
      enddo
   endif
   select ravm
   set filter to 
   use
else
   f_valid (.f., "No Help information for this Field ...")
endif
setcolor (ycolor)
return

******************************
procedure rrvgrid
private ycolor, yscn, yord, yrecno, yrow

ycolor = setcolor (gsubcolor)
yscn = f_box (05, 15, 16, 70)

@ 06, 16 say "Res #     Check Out    Date/Time Out   Date/Time In  "
@ 15, 25 say "Press any key to continue"

if xtyp = "A"      && add res
   f_use ("rares",2)
else
   select rares
   yord = indexord ()
   yrecno = recno ()
   set order to 2
endif
l_funit = ravm->funit
l_fclass = ravm->fclass
set filter to funit = ravm->funit .and. fresvno <> l_fresvno .and.   ;
             ((fdateout >= l_fdateout .and. fdateout <= l_fdatein) .or.  ;
              (fdatein >= l_fdateout .and. fdatein <= l_fdatein) .or.   ;
              (fdateout <= l_fdateout .and. fdatein >= l_fdatein))
go top
if eof ()
   @ 08,16 say "OPEN "
else
   seek "O"
   yrow = 7
   setcolor (gsubget)
   do while .not. eof () .and. fresvstat = "O"
      @ yrow, 16 say fresvno+[ ]+floc+[  ]+dtoc(fdateout)+[ ]+ftimeout+[  ]+   ;
                     dtoc(fdatein)+[ ]+ftimein
      yrow = yrow + 1
      if yrow > 14
         exit
      endif
      skip
   enddo
endif
set filter to
f_getkey ()
setcolor (ycolor)
f_restbox (yscn)
if xtyp = "U"     && update res
   select rares
   set order to yord
   go yrecno
endif
select ravm

******************************
procedure rrvfmget
*
* revision:
* date: 09/25/92
* edc: new features for insurance replacement rentals
* date: 01/29/93
* edc: add more fields for ins

private yscn, ycolor, yptr, ydate1, ydate2
ycolor = setcolor (gsubcolor)
yscn = f_box (5, 4, 13, 75)

@ 06, 6 say "Reference#............."
@ 07, 6 say "Last/First Name........"
@ 08, 9 say "Address............."
@ 09, 9 say "City/St/Zip........."     
@ 10, 9 say "Phone #............."
@ 11, 9 say "Driver Lic/State...."
@ 12, 9 say "Expire/DOB.........."
setcolor (gsubget)
set century off     && y2k
@ 06, 30 say l_frefno
@ 07, 30 say l_flname
@ 07, 45 say l_ffname
@ 08, 30 say l_faddr
@ 09, 30 say l_fcity
@ 09, 46 say l_fstate
@ 09, 50 say l_fzip
@ 10, 30 say l_fphone
@ 11, 30 say l_fcinsur1             && driver lic
@ 11, 52 say substr(l_fshop,1,2)    && state
@ 12, 30 say l_fexp1                && expiration
@ 12, 40 say l_fcexp1               && DOB
yptr = 1
ydate1 = dtoc (l_fexp1)
ydate2 = dtoc (l_fcexp1)
do while .t.
   do case
   case yptr = 1
      f_getfld (@l_frefno, 6, 30, "W/N", 0, replicate ("X", 14), .t.)
   case yptr = 2
      f_getfld (@l_flname, 7, 30, "W/N", 0, replicate ("!", 14), .t.)
   case yptr = 3
      f_getfld (@l_ffname, 7, 45, "W/N", 0, replicate ("!", 12), .t.)
   case yptr = 4
      f_getfld (@l_faddr, 8, 30, "W/N", 0, replicate ("X", 25), .t.)
   case yptr = 5
      f_getfld (@l_fcity, 9, 30, "W/N", 0, replicate ("X", 15), .t.)
   case yptr = 6
      f_getfld (@l_fstate, 9, 46, "W/N", 0, replicate ("!", 2), .t.)
   case yptr = 7
      f_getfld (@l_fzip, 9, 50, "W/N", 0, "XXXXX-XXXX", .t.)
   case yptr = 8
      f_getfld (@l_fphone, 10, 30, "W/N", 0, "999-999-9999", .t.)
   case yptr = 9
      f_getfld (@l_fcinsur1, 11, 30, "W/N", 0, replicate ("X", 20), .t.)
   case yptr = 10
      f_getfld (@l_fshop, 11, 52, "W/N", 0, replicate ("!", 2), .t.)
   case yptr = 11
      f_getfld (@ydate1, 12, 30, "W/N", 0, "99/99/99", .t.)
      l_fexp1 = ctod (ydate1)
      if .not. f_valid (f_expdate (l_fexp1) ;
         .or. (empty(l_fcinsur1).and.empty(l_fexp1)),  ; 
               "Warning! Date Expired!")
         loop
      endif
   case yptr = 12
      f_getfld (@ydate2, 12, 40, "W/N", 0, "99/99/99", .t.)
      l_fcexp1 = ctod (ydate2)
   endcase
   ykey = lastkey ()
   if (ykey = 24 .or. ykey = 13) .and. yptr < 12
      yptr = yptr + 1
   elseif ykey = 5 .and. yptr > 1
      yptr = yptr - 1
   elseif ykey = 27 .or. ykey = 13 .or. ykey = 3 .or. ykey = 18
      exit
   endif
enddo
f_restbox (yscn)
setcolor (ycolor)
set century on

******************************
function rrvfmup0

if f_valid (f_verify("raloc",1,l_floc),"Invalid Location...")
   l_frloc = if(empty(l_frloc), l_floc, l_frloc)     && 12.28.99
   return .t.
else
   return .f.
endif

******************************
function rrvfmup1

if f_valid (f_y2k (@l_fdateout) .and. l_fdays >= 0)
   l_fdatein = l_fdateout + l_fdays
   return .t.
else
   return .f.
endif


******************************
function rrvfmup2

if f_valid (f_y2k(@l_fdatein) .and. l_fdatein >= l_fdateout)
   if l_fdays <> (l_fdatein - l_fdateout)
      l_fdays = l_fdatein - l_fdateout
      *  keyboard chr (5) + chr (5)       && 12/21/93 (edc): do not go back
      @ 06, 23 say l_fdays pict "999"
   endif
   * 12.08.97 
   if l_fcode = substr(grate,1,6) .and. xtyp = [A]        && first time only
      do case
      case l_fdays >= 0 .and. l_fdays <= 4
         l_fcode = substr(grate,1,6)
      case l_fdays >= 5 .and. l_fdays <= 7 
         l_fcode = substr(grate,8,6)
      otherwise
         l_fcode = substr(grate,15,6)
      endcase
      l_fcode = if(empty(l_fcode), substr(grate,1,6), l_fcode)
      setcolor (gblueget)
      @ 03, 67 say l_fcode
      setcolor (gbluecolor)
   endif
   * 12.18.04: force customer lookup popup for 1st go around when add
   if xtyp = [A] .and. empty(l_fclass)    
      keyboard chr(28)
   endif
   *
   return .t.
else
   return .f.
endif


******************************
function rrvfmup3

if l_fcustno = ycustno .or. empty (l_fcustno)
   return .t.
endif

if f_valid (f_verify ("RACUST", 2, l_fcustno), "Invalid Customer Number!!!")
   if f_valid (.not. racust->fhold, "Customer is on HOLD Status!!!")
      ycustno = l_fcustno
      l_flname = racust->flname
      l_ffname = racust->ffname
      if .not. empty (racust->frate)
         l_fcode = racust->frate
      endif
      l_faddr = racust->faddr
      l_fcity = racust->fcity
      l_fstate = racust->fstate
      l_fzip = racust->fzip
      l_fphone = racust->fphone
      l_fdisc = racust->fdisc
      l_fccnum = racust->fccnum
      l_fcctype = racust->fcctype
      l_fccexp = racust->fccexp
      * 10.08.98
      l_fcinsur1 = racust->flic    && drive lic
      l_fshop = racust->flicst     && lic state
      l_fexp1 = racust->fexpdt     && exp. date
      l_fcexp1 = racust->fbirthdt  && dob
      * 10.23.01: add email
      l_femail = racust->femail
      f_valid (empty (racust->frmk1), alltrim (racust->frmk1))
      f_valid (empty (racust->frmk2), alltrim (racust->frmk2))
      * 12.27.04: display customer info 
      setcolor (gblueget)
      @ 02, 49 say l_femail
      @ 09, 69 say l_fdisc
      @ 12, 23 say l_flname
      @ 13, 23 say l_ffname
      @ 14, 23 say l_fphone
      @ 16, 23 say l_fccnum
      @ 17, 23 say l_fcctype
      @ 17, 28 say l_fccexp
      setcolor (gbluecolor)
      *
      return .t.
   else
      return .f.
   endif
else
   return .f.
endif


******************************
function rrvfmup4

if l_fcrpno = ycrpno .or. empty (l_fcrpno)
   return .t.
endif
f_use ("racrp", 1)
seek l_fcrpno
if f_valid (found ())
   if f_valid (.not. fhold, "Corporate account is on HOLD Status!!!")
      ycrpno = l_fcrpno
      if .not. empty (frate)
         l_fcode = frate
      endif
      l_fdisc = fdisc
      f_valid (empty (frmk1), alltrim (frmk1))
      f_valid (empty (frmk2), alltrim (frmk2))
      f_valid (empty (frmk3), alltrim (frmk3))
      return .t.
   else
      return .f.
   endif
else
   return .f.
endif


******************************
function rrvfmup5

private yflag, yord, yrecno

if lastkey () = 5 .or. empty (l_funit)
   return .t.
endif

*if empty (l_funit) .or. (l_funit = yunit .and. ;
*      (dtos (l_fdateout) + l_ftimeout) = yrdateout ;
*      .and. (dtos (l_fdatein) + l_ftimein = yrdatein))
*   return .t.
*endif

*if empty (l_funit) .or. l_funit = yunit
*   return .t.
*endif

f_use ("RAVM", 1)
seek l_funit
if .not. f_valid (found (), "Invalid Unit #!!!")
   use 
   return .f.
elseif .not. f_valid (fresv, "This unit CANNOT be reserved !")
   use
   return .f.
endif
* 08/09/94: specialty vehicle res table
if xtyp = "A"      && add res
   f_use ("rares",2)
else
   select rares
   yord = indexord ()
   yrecno = recno ()
   set order to 2
endif
seek "O"
yflag = .t.
do while .not. eof() .and. fresvstat = "O"
   if funit <> ravm->funit .or. fresvno = l_fresvno
      skip
      loop
   endif
   if l_fdateout > fdateout .and. l_fdateout < fdatein
      yflag = .f.
      exit
   elseif l_fdatein > fdateout .and. l_fdatein < fdatein
      yflag = .f.
      exit
   elseif l_fdateout <= fdateout .and. l_fdatein >= fdatein
      yflag = .f.
      exit
   elseif l_fdateout = fdateout .and. l_ftimeout >= ftimeout
      yflag = .f.
      exit
   elseif l_fdateout = fdatein .and. l_ftimeout <= ftimein
      yflag = .f.
      exit
   endif
   skip
enddo
l_fclass = if(yflag,ravm->fclass,l_fclass)
select ravm 
use
if xtyp = "U"     && update res
   select rares
   set order to yord
   go yrecno
endif
if yflag
   return .t.
else
   f_valid (.f., "This unit CANNOT be reserved due to schedule conflict !")
   return .f.
endif

*elseif (dtos (l_fdateout) + l_ftimeout) >= yrdateout ;
*      .or. (dtos (l_fdatein) + l_ftimein <= yrdatein)
*   if f_validres (l_funit, l_fdateout, l_ftimeout, l_fdatein, ;
*         l_ftimein, "R" + l_fresvno)
*      f_markvres (l_funit, l_fdateout, l_ftimeout, l_fdatein, ;
*         l_ftimein)
*      if l_funit <> yunit .or. empty (l_fclass)
*         l_fclass = ravm->fclass
*      endif
*      yunit = l_funit
*      yrdateout = dtos (l_fdateout) + l_ftimeout
*      yrdatein = dtos (l_fdatein) + l_ftimein
*      select ravm
*      use
*      return .t.
*   else
*      select ravm
*      use
*      return .f.
*   endif
*endif

******************************
function rrvfmup6

if lastkey () = 5
   return .t.
endif

if .not. f_valid (.not. empty (l_fclass))
   return .f.
endif
if l_fcode = yrate .and. l_fclass = yclass .and. l_floc = yloc .and. ;
      l_fdateout = ydateout
   if .not. yfreesell
      keyboard replicate (chr (13), 12)
   endif
   return .t.
endif

* implement block rate
if block_rate ()
   return .f.
endif

f_use ("rartm")
if f_valid (f_getrate (l_fcode, l_floc, l_fclass, l_fdateout), ;
      "Rate Not Found!!!")
   if f_valid (rartm->fresvok = 0 .or. rartm->fresvcnt < rartm->fresvok * ;
         (1 + rartm->fresvovr / 100), "Reservation Exceeds Limit!!!")
      l_fdlychg = rartm->fdlychg
      l_fdlymlg = rartm->fdlymlg
      l_fwkdchg = rartm->fwkdchg
      l_fwkdmlg = rartm->fwkdmlg
      l_fwkdmin = rartm->fwkdmin
      l_fwkdmax = rartm->fwkdmax
      l_fwkchg = rartm->fwkchg
      l_fwkmlg = rartm->fwkmlg
      l_fmthchg = rartm->fmthchg
      l_fmthmlg = rartm->fmthmlg
      l_fhrchg = rartm->fhrchg
      l_fmlgchg = rartm->fmlgchg
      l_fcdw = rartm->fcdwchg
      setcolor (gblueget)
      @ 4, 56 say l_fdlychg picture [9999.99]
      @ 4, 64 say l_fdlymlg picture [9999]
      @ 5, 56 say l_fwkdchg picture [9999.99]
      @ 5, 64 say l_fwkdmlg picture [9999]
      @ 6, 56 say l_fwkchg  picture [9999.99]
      @ 6, 64 say l_fwkmlg  picture [9999]
      @ 7, 56 say l_fmthchg picture [9999.99]
      @ 7, 64 say l_fmthmlg picture [9999]
      @ 8, 56 say l_fhrchg  picture [9999.99]
      @ 9, 56 say l_fmlgchg picture [9999.99]
      @ 10, 60 say l_fwkdmin picture [99]
      @ 10, 68 say l_fwkdmax picture [99]
      setcolor (gbluecolor)
      yrate = l_fcode
      yclass = l_fclass
      yloc = l_floc
      ydateout = l_fdateout
      * 11.16.98: popup rate remark if .not. empty
      if .not. empty(rartm->fremark)
         f_valid (.f., rartm->fremark)
      endif
      if .not. yfreesell
         keyboard replicate (chr (13), 12)
      endif
      return .t.
   else
      keyboard chr (5)
      return .f.
   endif
else
   keyboard chr (5)
   return .f.
endif

******************************
function block_rate

yblock = .f.

f_use ("rartml")
seek l_floc+l_fcode+l_fclass

do while .not. eof () .and. rartml->floc=l_floc .and. rartml->fcode=l_fcode  ;
          .and. rartml->fclass = l_fclass .and. .not. yblock
   yblock = check_block ()
   skip
enddo

if yblock
   f_valid (.f.,"Rate is blocked for this period...")
   use
   return .t.
endif

* handle rate code for ALL locations
seek space(10)+l_fcode+l_fclass
do while .not. eof () .and. rartml->floc=space(10) .and. rartml->fcode=l_fcode  ;
          .and. rartml->fclass = l_fclass .and. .not. yblock
   yblock = check_block ()
   skip
enddo
use
if yblock
   f_valid (.f.,"Rate is blocked for this period...")
   return .t.
else
   return .f.
endif

*********************
function check_block

zblock = .f.
if .not. empty(rartml->fdtfrom1)
   if l_fdateout >= rartml->fdtfrom1 .and. l_fdateout <= rartml->fdtto1
       zblock = .t.
   endif
   *if l_fdatein >= rartml->fdtfrom1 .and. l_fdatein <= rartml->fdtto1
   *    zblock = .t.
   *endif
endif
if .not. empty(rartml->fdtfrom2)
   if l_fdateout >= rartml->fdtfrom2 .and. l_fdateout <= rartml->fdtto2
       zblock = .t.
   endif
   *if l_fdatein >= rartml->fdtfrom2 .and. l_fdatein <= rartml->fdtto2
   *    zblock = .t.
   *endif
endif
if .not. empty(rartml->fdtfrom3)
   if l_fdateout >= rartml->fdtfrom3 .and. l_fdateout <= rartml->fdtto3
       zblock = .t.
   endif
   *if l_fdatein >= rartml->fdtfrom3 .and. l_fdatein <= rartml->fdtto3
   *    zblock = .t.
   *endif
endif
return (zblock)

******************************
function rrvfmup7

if empty (l_fatc)              && .or. l_fatc = yatc
   return .t.
endif
f_use ("raagnt", 1)
seek l_fatc
if found ()
   if .not. (empty(raagnt->fcompany).or.empty(raagnt->faddr).or. ;
      raagnt->fstd=0)
      yatc = l_fatc
      l_fagent = raagnt->fcompany
      do rrvfmup8
      l_fcommpct = ycomm
      return .t.
   endif
endif
tone (500, 9)
if f_confirm ("Do You Want To Update Travel Agent File ? [Y/N] ", ;
      "YN") = "N"
   yatc = l_fatc
   return .t.
endif

set cursor on
private yscn, ycolor, yrcompany, ystcomm, ycmcomm, yspcomm, yptr
private yaddr, yaddr1, ycity, ycontact, ystate, yzip, yphone, yfax

ycolor = setcolor (gsubcolor)
yscn = f_box (09, 25, 22, 77)
@ 10, 27 say "ATC Number .. "
@ 11, 27 say "Company ..... "
@ 12, 27 say "Address ..... "
@ 14, 27 say "City ........ "
@ 15, 27 say "State/Zip ... "
@ 16, 27 say "Contact ..... "
@ 17, 27 say "Phone ....... "
@ 18, 27 say "Fax ......... "
@ 19, 30 say "Standard ........ "
@ 20, 30 say "Consortium ...... "
@ 21, 30 say "Special ......... "

if eof ()
   yrcompany = space(30)
   ystcomm = 0
   ycmcomm = 0
   yspcomm = 0
   store space (20) to ycontact
   store space (30) to yaddr, yaddr1
   store space (15) to ycity
   ystate = "  "
   yzip = "     -    "
   store "   -   -    " to yfax, yphone
else
   yrcompany = raagnt->fcompany
   ystcomm = raagnt->fstd
   ycmcomm = raagnt->fcsm
   yspcomm = raagnt->fspecial
   ycontact = raagnt->fcontact
   yaddr = raagnt->faddr
   yaddr1 = raagnt->faddr1
   ycity = raagnt->fcity
   ystate = raagnt->fstate
   yzip = raagnt->fzip
   yfax = raagnt->ffax
   yphone = raagnt->fphone
endif

@ 10, 41 say l_fatc
setcolor (gsubget)
@ 11, 41 say yrcompany
@ 12, 41 say yaddr
@ 13, 41 say yaddr1
@ 14, 41 say ycity
@ 15, 41 say ystate
@ 15, 44 say yzip
@ 16, 41 say ycontact
@ 17, 41 say yphone
@ 18, 41 say yfax
@ 19, 48 say ystcomm picture "99"
@ 20, 48 say ycmcomm picture "99"
@ 21, 48 say yspcomm picture "99"

yptr = 1
do while .t.
   do case
   case yptr = 1
      f_getfld (@yrcompany, 11, 41, "W/N", 0, replicate ("X", 30), .t.)
   case yptr = 2
      f_getfld (@yaddr, 12, 41, "W/N", 0, replicate ("X", 30), .t.)
   case yptr = 3
      f_getfld (@yaddr1, 13, 41, "W/N", 0, replicate ("X", 30), .t.)
   case yptr = 4
      f_getfld (@ycity, 14, 41, "W/N", 0, replicate ("X", 15), .t.)
   case yptr = 5
      f_getfld (@ystate, 15, 41, "W/N", 0, "!!", .t.)
   case yptr = 6
      f_getfld (@yzip, 15, 44, "W/N", 0, "XXXXX-XXXX", .t.)
   case yptr = 7
      f_getfld (@ycontact, 16, 41, "W/N", 0, replicate ("X", 20), .t.)
   case yptr = 8
      f_getfld (@yphone, 17, 41, "W/N", 0, "999-999-9999", .t.)
   case yptr = 9
      f_getfld (@yfax, 18, 41, "W/N", 0, "999-999-9999", .t.)
   case yptr = 10
      f_getnum (@ystcomm, 19, 48, "W/N", "99", .t.)
   case yptr = 11
      f_getnum (@ycmcomm, 20, 48, "W/N", "99", .t.)
   case yptr = 12
      f_getnum (@yspcomm, 21, 48, "W/N", "99", .t.)
   endcase
   ykey = lastkey ()
   if (ykey = 24 .or. ykey = 13) .and. yptr < 12
      yptr = yptr + 1
   elseif ykey = 5 .and. yptr > 1
      yptr = yptr - 1
   elseif ykey = 27 .or. ykey = 13 .or. ykey = 3 .or. ykey = 18
      exit
   endif
enddo
f_restbox (yscn)
setcolor (ycolor)

f_use ("raagnt")
seek l_fatc
if eof ()
   append blank
endif
reclock ()
replace fatc with l_fatc, fcompany with yrcompany
replace fstd with ystcomm, fcsm with ycmcomm, fspecial with yspcomm
replace faddr with yaddr, faddr1 with yaddr1, fcity with ycity, fcontact with ycontact
replace fstate with ystate, fzip with yzip, fmoddt with date ()
replace fphone with yphone, ffax with yfax
commit
unlock
f_fupdate ("A")

yatc = l_fatc
l_fagent = raagnt->fcompany
do rrvfmup8
l_fcommpct = ycomm
return .t.


******************************
procedure rrvfmup8

private yarray [3], yptr
yarray [1] = "Standard Commission .... " + str (fstd, 2) + "%"
yarray [2] = "Consortium Commission .. " + str (fcsm, 2) + "%"
yarray [3] = "Special Commission ..... " + str (fspecial, 2) + "%"

yptr = f_pick_a (15, 40, "", "", YARRAY, 3, 1)
if yptr = 2
   ycomm = fcsm
elseif yptr = 3
   ycomm = fspecial
else
   ycomm = fstd
endif


******************************
function rrvfmup9

private yrecno, yfnd
if empty (l_fresvno)
   return f_valid (.f.)
endif
if yresvno = l_fresvno
   return .t.
endif
f_use ("rares", 1)
if xtyp = "A"
   seek l_fresvno
   *return f_valid (.not. found (), "Reservation Number Already Exist!!!")
   if eof ()
      return .t.
   else
      if f_confirm ("Warning: Duplicate Reservation # !" + ;
         " Continue ?[Y/N]", "YNyn") $ "Yy"
         return .t.
      else
         return .f.
      endif
   endif  
else
   yrecno = recno ()
   seek l_fresvno
   yfnd = .not. found () .or. yrecno = recno ()
   go yrecno
   return f_valid (yfnd, "Reservation Number Already Exist!!!")
endif


******************************
function rrvfmup10

if .not. f_valid (.not. empty (l_flname))
   return .f.
endif

if .not. yfreesell .and. lastkey () = 5
   keyboard replicate (chr (5), 12)
endif
return .t.


******************************
function f_rvstat

parameter xstat

do case
case xstat = "O"
   return "OPEN   "
case xstat = "X"
   return "USED   "
case xstat = "U"
   return "CLOSED "
case xstat = "C"
   return "CANCEL "
case xstat = "N"
   return "NO SHOW"
otherwise
   return "UNKNOWN"
endcase

