* ===========================================================================
* Rate Table Maint.
*
* date: 05/01/91
* author: KST
*
* date: 12/03/93
* edc: implement block rate
* 01.31.07: new block rate screen
* ---------------------------------------------
* 11.11.09: add LMR rate maint. (see rsysssr4)
* ===========================================================================
do while .t.
   xret3 = f_pushmenu (xoption2)
   if xret3 = 0
      exit
   else
      xoption3 = substr (goption [xret3], 4)
      do case
      case xret3 = 1                && Add rate
         do rsysssru with "A"       
      case xret3 = 2                && update rate
         do rsysssru with "U"       
      case xret3 = 3                && block rate
         do rsysssrb     
      case xret3 = 4                && LMR special rate for DL-EGE
         do rsysssr4
      endcase
   endif
enddo

* ------------------------------------
* 11.11.09: LMR Rate Maint.
*
* -------------------------------------
procedure rsysssr4

private yrate1, yrate2, yfromdate, ytodate
private ypercent, ydlymlg, ywkmlg, ymlgchg
private yoption, yfil

f_clrscn ("LMR RATE MAINT.")

f_box (2, 5, 17, 72)

@ 03, 07 say "Base Rate......."
@ 04, 07 say "LMR Rate........"
@ 05, 07 say "From Date......."
@ 06, 07 say "To Date........."
@ 07, 07 say "Percent off.....       %"
@ 08, 07 say "Daily Mileage..."
@ 09, 07 say "Weekly Mileage.."
@ 10, 07 say "Mileage Charge.."

yrate1 = "VALUE "        && code: C6
yrate2 = "LMR   "
yfromdate = date()
ytodate = date()
ypercent = 0
ydlymlg = 0
ywkmlg = 0
ymlgchg = 0

do while .t.
   set century on
   @ 03, 24 get yrate1 picture "!!!!!!"
   @ 04, 24 get yrate2 picture "!!!!!!"
   @ 05, 24 get yfromdate picture "@D" valid ;
     f_valid (yfromdate >= date())
   @ 06, 24 get ytodate picture "@D" valid ;
     f_valid (ytodate >= yfromdate)
   @ 07, 24 get ypercent picture "99.99" valid ;
     f_valid (ypercent > 0, "Must be greater than zero") 
   @ 08, 24 get ydlymlg picture "9999"
   @ 09, 24 get ywkmlg picture "9999"
   @ 10, 24 get ymlgchg picture "99.99"
   if f_rd () = 27
      set century off
      return
   elseif ypercent <= 0
      f_valid (.f.,"Please enter Percent off")
      loop
   endif
   set century off
   yoption = f_confirm ("[C]onfirm  [E]dit  [Q]uit", "CEQ")
   if yoption = "Q"
      return
   endif
   if yoption = "C"
      exit
   endif
enddo

* -- add record to audit file
yfil = gdbfpath + "ralogrt"
select 0
use &yfil
append blank
replace fline with "Date: "+dtoc(date())+" "+ ;
                   "Time: "+time()+" "+ ;
                   "User: "+gusrid+"-->"+;
  yrate1+" "+yrate2+" "+dtoc(yfromdate)+" "+dtoc(ytodate)+" "+;
  str(ypercent,6,2)+" "+str(ydlymlg,6)+" "+str(ywkmlg,6)+" "+str(ymlgchg,6,2) 
commit
use

* -- open rate table
restore from (gmempath + "rartm") additive
f_use ("rartm")

select 0
yfil = gdbfpath + "rartm"
use &yfil index &yfil alias lmr

* --
select rartm
seek yrate1
@ 12, 07 say "Processing "
ypercent = ypercent / 100      && ypercent is % off
ypercent = 1 - ypercent        && e.g. 1 - .1 = .9
do while .not. eof () .and. rartm->fcode = yrate1
   if rartm->fdatefrom < yfromdate .or. rartm->fdatefrom > ytodate
      skip
      loop
   endif
   @ 12, 27 say dtoc(rartm->fdatefrom)
   f_retrieve ()
   l_fcode = yrate2
   select lmr
   seek l_fcode+l_floc+l_fclass+dtos(l_fdatefrom)
   if eof ()
      append blank
   else
      reclock ()
   endif
   l_fhrchg = l_fhrchg * ypercent
   l_fdlychg = l_fdlychg * ypercent
   l_fwkchg = l_fwkchg * ypercent
   l_fmthchg = l_fmthchg * ypercent
   l_fdlymlg = ydlymlg
   l_fwkmlg = ywkmlg
   l_fmlgchg = ymlgchg
   f_replace ()

   select rartm
   skip
enddo
      
close data
f_valid (.f., "Process completed")

*********************
procedure rsysssrb

f_clrscn ("BLOCK RATE")

set key 28 to rsysssrb1
setcolor (gredcolor)
@ 24, 00
@ 24, 01 say "Press F1 For To Pick Rate"
setcolor (gbluecolor)
restore from (gmempath + "rartml") additive
f_use ("RARTML")

l_floc = space (10)
l_fcode = space (6)
l_fclass = space (4)

ycnt = 1
do while .t.
   @ ycnt, 1 say "Location:            Rate:        Class:      [ACAR/OPEN]"
   @ ycnt + 1, 05 say "From: MM/DD/YY  To: MM/DD/YY" 
   @ ycnt + 2, 05 say "From: MM/DD/YY  To: MM/DD/YY" 
   @ ycnt + 3, 05 say "From: MM/DD/YY  To: MM/DD/YY" 

   @ ycnt, 11 get l_floc picture "!!!!!!!!!!" ;
      valid f_valid (f_verify ("RALOC", 1, l_floc))   && 07.28.10: disallow empty loc
   @ ycnt, 28 get l_fcode picture "!!!!!!" valid f_valid (.not. empty (l_fcode))
   @ ycnt, 42 get l_fclass picture "!!!!" valid ;
     f_valid (l_fclass $ [ACAR;OPEN] .or. ;
              f_verify ("RARTM",1,l_fcode+l_floc+l_fclass),"Rate Not Found ...")
   if f_rd () = 27
      exit
   endif

   *-- 07.28.10: add ACAR ::= all class
   if l_fclass = [ACAR]
      f_use ("rartm")
      set softseek on
      seek l_fcode+l_floc
      set softseek off
      if eof()
         f_valid (.f., "Invalid Rate Code...")
         loop
      endif
      * 
      @ ycnt, 11 say l_floc
      @ ycnt, 28 say l_fcode
      @ ycnt, 42 say l_fclass
      @ ycnt+2, 05 say space(50)
      @ ycnt+3, 05 say space(50)
      do while .t.
         @ ycnt+1, 11 get l_fdtfrom1 pict "@D" valid ;
         f_valid (f_y2k (@l_fdtfrom1) .and. l_fdtfrom1 >= date(),"Invalid Date")
         @ ycnt+1, 25 get l_fdtto1 pict "@D" valid ;
           f_valid (f_y2k (@l_fdtto1).and.l_fdtto1>=l_fdtfrom1,"Invalid Date")
         f_rd ()
         xkey = f_confirm ("[C]onfirm  [E]dit  [V]oid", "CEV")
         do case
         case xkey = "C"
            select rartml
            set softseek on
            seek l_floc + l_fcode
            set softseek off
            do while .not. eof() .and. l_floc+l_fcode = floc+fcode
               if empty(fdtfrom1) .or. fdtto1 < date()
                  reclock()
                  replace fdtfrom1 with l_fdtfrom1, fdtto1 with l_fdtto1
                  commit
                  unlock
               elseif empty(fdtfrom2) .or. fdtto2 < date()
                  reclock()
                  replace fdtfrom2 with l_fdtfrom1, fdtto2 with l_fdtto1
                  commit
                  unlock
               else
                  reclock()
                  replace fdtfrom3 with l_fdtfrom1, fdtto3 with l_fdtto1
                  commit
                  unlock
               endif
               select rartml
               skip
            enddo

            f_valid (.f.,"Process completed.")
            exit
         case xkey = "E"
            loop
         case xkey = "V"
            exit
         endcase
      enddo
      *
      exit
   elseif l_fclass = [OPEN]      && 08.17.10: reopen all class
      * --
      f_use ("rartm")
      set softseek on
      seek l_fcode+l_floc
      set softseek off
      if eof()
         f_valid (.f., "Invalid Rate Code...")
         loop
      endif
      do while .t.
         xkey = f_confirm ("ALL Car Classes Will be Unblocked. Are you Sure? [Y/N]", "YN")
         do case
         case xkey = "Y"
            if f_confirm ("ARE YOU SURE? [Y/N]", "YN") = "N"
               exit 
            endif
            ydate = ctod("")
            select rartml
            set softseek on
            seek l_floc + l_fcode
            set softseek off
            do while .not. eof() .and. l_floc+l_fcode = floc+fcode
               reclock()
               replace fdtfrom1 with ydate, fdtto1 with ydate
               replace fdtfrom2 with ydate, fdtto2 with ydate
               replace fdtfrom3 with ydate, fdtto3 with ydate
               commit
               unlock
               select rartml
               skip
            enddo

            f_valid (.f.,"Process completed.")
            exit
         case xkey = "N"
            exit
         endcase
      enddo
      exit
      * -- 08.17.10
   endif
   * -- 07.28.10
   
   if upper (l_floc) = "ALL"
      l_floc = space (10)
   endif

   select rartml
   seek l_floc + l_fcode + l_fclass 
   if .not. eof()
      f_retrieve ()
   endif

   @ ycnt, 11 say l_floc
   @ ycnt, 28 say l_fcode
   @ ycnt, 42 say l_fclass
   do while .t.

      @ ycnt+1, 11 get l_fdtfrom1 pict "@D" valid ;
      f_y2k (@l_fdtfrom1)
      @ ycnt+1, 25 get l_fdtto1 pict "@D" valid ;
        f_valid (f_y2k (@l_fdtto1).and.l_fdtto1>=l_fdtfrom1)
      @ ycnt+2, 11 get l_fdtfrom2 pict "@D" valid f_y2k (@l_fdtfrom2)
      @ ycnt+2, 25 get l_fdtto2 pict "@D" valid ;
        f_valid (f_y2k (@l_fdtto2).and.l_fdtto2>=l_fdtfrom2)
      @ ycnt+3, 11 get l_fdtfrom3 pict "@D" valid f_y2k (@l_fdtfrom3)
      @ ycnt+3, 25 get l_fdtto3 pict "@D" valid ;
        f_valid (f_y2k (@l_fdtto3).and.l_fdtto3>=l_fdtfrom3)
      f_rd ()
      if eof()
         xkey = f_confirm ("[C]onfirm  [E]dit  [V]oid", "CEV")
         do case
         case xkey = "C"
            append blank
            f_replace ()
            f_fupdate ("A")
            exit
         case xkey = "E"
            loop
         case xkey = "V"
            exit
         endcase
      else
         xkey = f_confirm ("[C]onfirm  [D]elete  [E]dit  [I]gnore Changes", ;
               "CDEI")
         do case
         case xkey = "C"
            f_fupdate ("C")
            f_replace ()
            exit
         case xkey = "E"
            loop
         case xkey = "D"
            if f_confirm ("Are You Sure? [Y/N]", "YN") = "Y"
               f_fupdate ("D")
               reclock ()
               delete
               unlock
            endif
            exit
         case xkey = "I"
            exit
         endcase
      endif
   enddo

   if xkey <> "I"
      if ycnt < 15
         ycnt = ycnt + 5
      else
         scroll (1, 0, 23, 79, 5)
      endif
   endif
   if ycnt > 1
      @ ycnt - 1, 1 say replicate (chr (196), 78)
   endif
enddo

set key 28 to
close databases

*********************************
procedure rsysssrb1

select rartml
go top
if .not. eof ()
   set softseek on
   seek l_floc + l_fcode + l_fclass 
   if eof ()
      go bottom
   endif
   set softseek off
   if f_pick_f (2, 3, "", "Loc Rate    Class      Dates", ;
         "IF (EMPTY (FLOC), " + ;
         "[ALL], trim(FLOC)) + [ ] + FCODE + [  ] + FCLASS + [   ] +" + ;
         "DTOC (FDTFROM1) + [-] + DTOC (FDTTO1) + [  ] +" + ;
         "DTOC (FDTFROM2) + [-] + DTOC (FDTTO2) + [  ] +" + ;
         "DTOC (FDTFROM3) + [-] + DTOC (FDTTO3) ")
      l_floc = floc
      l_fcode = fcode
      l_fclass = fclass
      keyboard chr (3)
   endif
endif

