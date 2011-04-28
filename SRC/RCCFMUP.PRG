* ===========================================================================
* credit card processing: File maint.
*
* date: 05/01/91
* author: KST
*
* revision
*
* ===========================================================================
parameters xupdtype
private yarray [7], yptr, ykey, yexp, yscn, yans, ycolor, ytitle
f_clrscn ("CREDIT CARD TRANSACTION FILE")
rest from (gmempath + "RACRED") additive
gccinfo = " "
f_use ("RACRED")
if xupdtype = "U"
   set filter to .not. empty (fccnum)
   go top
   if eof ()
      f_popup ("No Credit Card File Found!  Press Any Key to continue...", .t.)
      use
      return
   endif
   yarray [1] = " By Contract Number ...... "
   yarray [2] = " By Last Name ............ "
   yarray [3] = " By Batch Number ......... "
   yarray [4] = " By Credit Card Number ... "
   yptr = f_pick_a (03, 02, "", "", YARRAY, 4, 1)
   if yptr = 0
      return
   endif
   ycolor = setcolor (gsubcolor)
   yscn = f_box (3, 02, 5, 47)
   do case
   case yptr = 1
      ykey = "l_floc + str (l_frano, 6)"
      ytitle = "Contract Number컴횮redit Card Number"
      yexp = "f_truncate (floc + [-] + ltrim (str (frano, 6)), 17) + " + ;
         "[ ] + fccnum"
      l_floc = gloc
      @ 04, 04 say "Contract Loc/Contract No           -"
      @ 04, 29 get l_floc picture "!!!!!!!!!!"
      @ 04, 40 get l_frano picture "999999"
   case yptr = 2
      ykey = "upper (l_flname)"
      ytitle = "Name컴컴컴컴컴컴컴컴컴컴컴컴컴Credit Care Number"
      yexp = "f_truncate (trim (flname) + [, ] + ffname, 28) + [ ] + fccnum"
      @ 04, 04 say "Last Name ................."
      @ 04, 32 get l_flname
   case yptr = 3
      ykey = "str (l_fbatch, 5) + str (l_fitem, 3)"
      ytitle = "Batch/Item횮redit Card Number"
      yexp = "str (fbatch, 5) + [/] + str (fitem, 3) + [  ] + fccnum"
      @ 04, 04 say "Batch/Item Number ..............      /   "
      @ 04, 37 get l_fbatch picture "99999"
      @ 04, 43 get l_fitem picture "999"
   case yptr = 4
      ykey = "l_fccnum"
      ytitle = "Credit Care Number컴Trans횲unc컴Amount"
      yexp = "fccnum + [ ] + ftranstyp + [     ] + str (frectype, 1) " + ;
         "+ [  ] + str (fauthamt, 8, 2)"
      @ 04, 04 say "Credit Card Number .."
      @ 04, 26 get l_fccnum
      yptr = 5
   endcase
   if f_rd () = 27
      setcolor (ycolor)
      use
      return
   endif
   f_restbox (yscn)
   setcolor (ycolor)
   set order to (yptr)
   set softseek on
   seek &ykey
   if eof ()
      go bottom
   endif
   set softseek off

   if .not. f_pick_f (05, 02, "", ytitle, yexp)
      use
      return
   endif

   set key 28 to rccuphlp

   select racred
   f_retrieve ()
   f_screen (0, "racred")

   do while .t.
      if ftranstyp $ "XD"
         ykeyin = f_confirm ("[N]ext  [P]revious  [Q]uit", "NPQ")
      else
         ykeyin = f_confirm ("[U]pdate  [D]elete  [N]ext  [P]revious  [Q]uit", ;
            "UDNPQ")
      endif
      do case
      case ykeyin = "U"
         do while .t.
            f_rd ()
            ykey = f_confirm ("[C]onfirm  [E]dit  [I]gnore Changes", "CEI")
            do case
            case ykey = "C"
               select racred
               if empty(fmname)    && 06.28.99
                  l_fmname = if(empty(gccinfo), "M", "C")
               endif
               f_fupdate ("C")
               f_replace ()
               exit
            case ykey = "E"
               f_screen (1, "racred")
               loop
            case ykey = "I"
               if chr (f_popup ("Are You Sure? ", .t.)) $ [Yy]
                  exit
               else
                  keyboard chr (18)
                  loop
               endif
               exit
            endcase
         enddo
         exit
      case ykeyin = "D"
         if f_confirm ("Are you sure? [Y/N]", "YN") = "Y"
            clear gets
            select racred
            f_fupdate ("D")
            f_clrrec ()
            exit
         else
            f_screen (1, "racred")
         endif
      case ykeyin = "N"
         clear gets
         skip 1
         if eof ()
            f_popup ("End of file. Press Any Key...", .t.)
            go bottom
         endif
         select racred
         f_retrieve ()
         f_screen (1, "racred")
      case ykeyin = "P"
         clear gets
         skip -1
         if bof ()
            f_popup ("Top of file. Press Any Key...", .t.)
            go top
         endif
         select racred
         f_retrieve ()
         f_screen (1, "racred")
      case ykeyin = "Q"
         clear gets
         exit
      endcase
   enddo
else
   set key 28 to rccuphlp
   f_add ("RACRED", "RACRED")
endif
use
set key 28 to


******************************
procedure rccuphlp

private yvar, yptr

yvar = alltrim (upper (readvar ()))
do case
case yvar = "L_FTRANSTY"
   yarray [1] = "S - Sale   "
   yarray [2] = "C - Credit "
   yarray [3] = "F - Force  "
   yarray [4] = "D - Deleted"
   yarray [5] = "X - Sent   "
   if gccnet = "NDC"
      yarray [6] = "V - Void   "
   endif
   yptr = f_pick_a (10, 34, "", "", YARRAY, if (gccnet = "NDC", 6, 5), ;
      ascan (yarray, l_ftransty))
   if yptr > 0
      l_ftransty = left (yarray [yptr], 1)
      keyboard chr (13)
   endif
case yvar = "L_FRECTYPE"
   yarray [1] = "0" + str (__gccunauth, 1) + ;
      " - Unauthorized                     "
   yarray [2] = "0" + str (__gccauth, 1) + ;
      " - Authorized                       "
   yarray [3] = "0" + str (__gccuncap, 1) + ;
      " - Ready to Capture                 "
   yarray [4] = "0" + str (__gcccap, 1) + ;
      " - Captured                         "
   yarray [5] = "0" + str (__gccautherr, 1) + ;
      " - Error in Authorization           "
   yarray [6] = "0" + str (__gccspecauth, 1) + ;
      " - Unauthorized but Ready to Capture"
   yptr = f_pick_a (11, 34, "", "", YARRAY, 6, ascan (yarray, "0" + ;
      str (l_frectype, 1)))
   if yptr > 0
      l_frectype = val (left (yarray [yptr], 2))
      keyboard chr (13)
   endif
case yvar = "L_FCCNUM"
   get_card (@l_fccnum, @l_flname, @l_ffname, @l_fccexp)
case yvar = "L_FAUTHCOD"
   if gccmodem .and. (l_frectype = __gccunauth .or. l_frectype = __gccspecauth)
      if get_auth (l_ftransty, l_fccnum, l_fccexp, l_fauthamt, ;
            @l_fauthcode, @l_fauthstat) = 0
         if f_valid (auth_ok (l_fauthstat, @l_fauthcode), ;
               "Warning!!! Credit Card Authorization Is Rejected!!!")
            if l_frectype = __gccspecauth
               l_frectype = __gccuncap
            else
               l_frectype = __gccauth
            endif
            setcolor (gblueget)
            l_fauthdat = date ()
            l_fauthtim = time ()
            @ 15, 22 say l_fauthdat
            @ 15, 31 say l_fauthtim
            @ 11, 30 say l_frectype pict "99"
            setcolor (gbluecolor)
         else
            setcolor (gblueget)
            l_frectype = __gccautherr
            @ 11, 30 say l_frectype pict "99"
            setcolor (gbluecolor)
         endif
      endif
   endif
otherwise
   f_valid (.f., "No Detail information for this Field ...")
endcase
set cursor on


******************************
function rccfmup1

return f_valid (l_frectype = __gccunauth .or. l_frectype = __gccauth .or. ;
   l_frectype = __gccuncap .or. l_frectype = __gcccap .or. ;
   l_frectype = __gccautherr .or. l_frectype = __gccspecauth)


******************************
function rccfmup2

return .t.

