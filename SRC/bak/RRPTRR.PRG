* ===========================================================================
*
* RacWare Report Writer - user interface
*
* Author: EDC
* Date:  05/01/92
*
* ===========================================================================

private yret, yfile, i, yfld

do while .t.
   xret2 = f_pushmenu (xoption1)
   if xret2 = 0
      exit
   endif
   xoption2 = substr (goption [xret2], 4)
   f_clrscn ("RAC REPORT WRITER")
   do case
   case xret2 = 1
      rest from (gmempath+"rarpt") additive
      @ 02, 02 say "Report Name "
      @ 02, 14 get l_fname picture "!!!!!!!!!!!!!!!"
      if f_rd () = 27 .or. empty (l_fname)
         close databases
         loop
      endif
      f_use ("rarpt")
      seek l_fname
      if .not. found ()
         f_box (02, 05, 04, 70, "Creating ...")
         @ 03, 07 say l_fname
         do while .t.
            do rrgetscn
            ykeyin = f_confirm ("[C]onfirm  [E]dit  [V]oid", "CEV")
            do case
            case ykeyin = "C"
               append blank
               f_replace ()
               f_fupdate ("A")
               exit
            case ykeyin = "E"
               loop
            case ykeyin = "V"
               exit
            endcase
         enddo
      else
         tone (500, 9)
         f_popup ("Duplicate Report Name. Press Any Key to Retry ...",.t.)
      endif
      close databases
   case xret2 = 2
      rest from (gmempath+"rarpt") additive
      @ 02, 02 say "Report Name " get l_fname picture "!!!!!!!!!!!!!!!"
      if f_rd () = 27
         close databases
         loop
      endif
      f_use ("rarpt")
      go top
      set softseek on
      seek l_fname
      set softseek off
      if eof ()
         go bottom
      endif
      if .not. (found () .or. f_pick_f (02, 3, "", "", "fname+[ -> ]+ftitle"))
         close databases
         loop
      endif
      f_retrieve ()
      f_box (02, 05, 04, 78, "You have selected")
      @ 03, 07 say fname+[ -> ]+ftitle
      ykeyin = f_confirm ("[U]pdate  [D]elete  [Q]uit", "UDQ")
      do case
      case ykeyin = "U"
         do while .t.
            do rrgetscn
            if l_fsys
               ykey = f_confirm ("[E]dit  [I]gnore Changes  " + ;
                     "[S]ave to another name", "EIS*")
            else
               ykey = f_confirm ("[C]onfirm  [E]dit  [I]gnore Changes  " + ;
                     "[S]ave to another name", "CEIS")
            endif
            do case
            case ykey = "S"
               setcolor (gbluecolor)
               @ 03, 06 clear to 03, 77
               do while .t.
                  @ 03, 08 say "New Report Name... " ;
                     get l_fname picture "!!!!!!!!!!!!!!!"
                  if f_rd () = 27 .or. empty (l_fname)
                     exit
                  endif
                  select rarpt
                  seek l_fname
                  if f_valid (.not. found (), "Duplicate Report Name. ")
                     append blank
                     l_fsys = .f.
                     f_replace ()
                     f_fupdate ("A")
                     exit
                  endif
               enddo
               exit
            case ykey $ "C*"
               f_fupdate ("C")
               f_replace ()
               exit
            case ykey = "I"
               exit
            endcase
         enddo
      case ykeyin = "D"
         if f_confirm ("Are you sure? [Y/N]", "YN") = "Y"
            clear gets
            f_fupdate ("D")
            reclock ()
            delete
            unlock
         endif
      endcase
      close databases
   case xret2 = 3
      l_fname = f_truncate (l_fname, 15)
      @ 02, 02 say "Report Name " get l_fname picture "!!!!!!!!!!!!!!!"
      if f_rd () = 27
         loop
      endif
      f_use ("rarpt")
      set softseek on
      seek l_fname
      set softseek off
      if eof ()
         go bottom
      endif
      if .not. (found () .or. f_pick_f (02, 3, "", "", "fname+[ -> ]+ftitle"))
         loop
      endif
      f_rr (fname, ftitle)
      blimempak (-1)
   endcase
enddo


******************************
procedure rrgetscn

private yarray[10], yptr, yret, yfil
setcolor (gsubcolor)
set key 28 to rrhlp
set key 25 to rrdelins
set key 14 to rrdelins
yarray [1] = " Report Title     "
yarray [2] = " Select File      "
yarray [3] = " Set Relation     "
yarray [4] = " Query            "
yarray [5] = " Select Field     "
yarray [6] = " Sort Field       "
yarray [7] = " Group Field      "
yarray [8] = " Calculated Field "
yarray [9] = " Parameter        "
yptr = 1
do while .t.
   yptr = f_pick_a (05, 05, "", "", yarray, 9, yptr)
   do case
   case yptr = 1
      if type("l_fformlen") = "U"
         yret = f_box (06, 05, 08, 70, "Report Title")
         @ 07, 07 say "Title: " get l_ftitle picture replicate ([x],50)
         f_rd ()
         f_restbox (yret)
     else
         yret = f_box (06, 05, 09, 75, "Report Title")
         @ 07, 07 say "Title:       " get l_ftitle picture replicate ([x],50)
         @ 08, 07 say "Form Length: " get l_fformlen pict [999]
         f_rd ()
         f_restbox (yret)
     endif
   case yptr = 2
      yret = f_box (06, 05, 14, 70, "Select File")
      @ 07, 07 say "[S]ummary/[D]etail: " get l_fdisp picture [!] valid f_valid(l_fdisp $ "S;D")
      @ 08, 07 say "File 1: " get l_file1 picture replicate ([!],8)
      @ 08, 34 say "Order: " get l_forder pict "9"
      @ 09, 07 say "Range From:" get l_frange1 pict replicate ("X", 50)
      @ 10, 07 say "      To:  " get l_frange2 pict replicate ("X", 50)
      @ 12, 07 say "File 2: " get l_file2 picture replicate ([!],8)
      @ 12, 34 say "Order: " get l_forder2 pict "9"
      @ 13, 07 say "File 3: " get l_file3 picture replicate ([!],8)
      @ 13, 34 say "Order: " get l_forder3 pict "9"
      f_rd ()
      f_restbox (yret)
   case yptr = 3
      yret = f_box (06, 05, 09, 70, "Set Relation")
      @ 07, 07 say "Key: " get l_fkey1 picture replicate ([x],30)
      @ 07, 45 say "Alias: " get l_falias1 picture replicate ([x],15)
      @ 08, 07 say "Key: " get l_fkey2 picture replicate ([x],30)
      @ 08, 45 say "Alias: " get l_falias2 picture replicate ([x],15)
      f_rd ()
      f_restbox (yret)
   case yptr = 4
      yret = f_box (06, 05, 11, 70, "Query")
      @ 07, 07 say "Condition: " get l_fcond1 picture replicate ([x],50)
      @ 08, 07 say "           " get l_fcond2 picture replicate ([x],50)
      @ 09, 07 say "           " get l_fcond3 picture replicate ([x],50)
      @ 10, 07 say "           " get l_fcond4 picture replicate ([x],50)
      f_rd ()
      f_restbox (yret)
   case yptr = 5
      yret = f_box (06, 01, 22, 78, "Select FieldÄÄHeading")
      @ 07, 03 get l_field1 picture replicate ([!],74)
      @ 08, 03 get l_field2 picture replicate ([!],74)
      @ 09, 03 get l_field3 picture replicate ([!],74)
      @ 10, 03 get l_field4 picture replicate ([!],74)
      @ 11, 03 get l_field5 picture replicate ([!],74)
      @ 12, 03 get l_field6 picture replicate ([!],74)
      @ 13, 03 get l_field7 picture replicate ([!],74)
      @ 14, 03 get l_field8 picture replicate ([!],74)
      @ 15, 03 get l_field9 picture replicate ([!],74)
      @ 16, 03 get l_field10 picture replicate ([!],74)
      @ 17, 03 get l_field11 picture replicate ([!],74)
      @ 18, 03 get l_field12 picture replicate ([!],74)
      @ 19, 03 get l_field13 picture replicate ([!],74)
      @ 20, 03 get l_field14 picture replicate ([!],74)
      @ 21, 03 get l_field15 picture replicate ([!],74)
      f_rd ()
      @ 07, 61 clear to 21, 61
      @ 07, 55 say "  Desc" get l_fdesc1 picture replicate ([X],15)
      @ 08, 55 say "  Desc" get l_fdesc2 picture replicate ([X],15)
      @ 09, 55 say "  Desc" get l_fdesc3 picture replicate ([X],15)
      @ 10, 55 say "  Desc" get l_fdesc4 picture replicate ([X],15)
      @ 11, 55 say "  Desc" get l_fdesc5 picture replicate ([X],15)
      @ 12, 55 say "  Desc" get l_fdesc6 picture replicate ([X],15)
      @ 13, 55 say "  Desc" get l_fdesc7 picture replicate ([X],15)
      @ 14, 55 say "  Desc" get l_fdesc8 picture replicate ([X],15)
      @ 15, 55 say "  Desc" get l_fdesc9 picture replicate ([X],15)
      @ 16, 55 say "  Desc" get l_fdesc10 picture replicate ([X],15)
      @ 17, 55 say "  Desc" get l_fdesc11 picture replicate ([X],15)
      @ 18, 55 say "  Desc" get l_fdesc12 picture replicate ([X],15)
      @ 19, 55 say "  Desc" get l_fdesc13 picture replicate ([X],15)
      @ 20, 55 say "  Desc" get l_fdesc14 picture replicate ([X],15)
      @ 21, 55 say "  Desc" get l_fdesc15 picture replicate ([X],15)
      f_rd ()
      f_restbox (yret)
   case yptr = 6
      yret = f_box (06, 05, 10, 70, "Sort Field")
      @ 07, 07 say "Field: " get l_fsort1 picture replicate ([!],50)
      @ 08, 07 say "Field: " get l_fsort2 picture replicate ([!],50)
      @ 09, 07 say "Field: " get l_fsort3 picture replicate ([!],50)
      f_rd ()
      f_restbox (yret)
   case yptr = 7
      yret = f_box (06, 05, 19, 70, "Group Field")
      @ 07, 07 say "Group - 1"
      @ 08, 09 say "Field " get l_fgroup1 picture replicate ([!],50)
      @ 09, 09 say "Desc: " get l_fgdesc1 picture replicate ([x],50)
      @ 10, 09 say "New Page: " get l_fnp1 picture "Y"
      @ 11, 07 say "Group - 2"
      @ 12, 09 say "Field " get l_fgroup2 picture replicate ([!],50)
      @ 13, 09 say "Desc: " get l_fgdesc2 picture replicate ([x],50)
      @ 14, 09 say "New Page: " get l_fnp2 picture "Y"
      @ 15, 07 say "Group - 3"
      @ 16, 09 say "Field " get l_fgroup3 picture replicate ([!],50)
      @ 17, 09 say "Desc: " get l_fgdesc3 picture replicate ([x],50)
      @ 18, 09 say "New Page: " get l_fnp3 picture "Y"
      f_rd ()
      f_restbox (yret)
   case yptr = 8
      yret = f_box (06, 05, 19, 78, "Calculated Field")
      @ 07, 07 say "Field " get l_ftotal1 picture replicate ([!],50)
      @ 07, 66	say "Func: " get l_ftfunc1 picture "!"
      @ 08, 09 say "where " get l_ftcond1 picture replicate ([x],30)
      @ 08, 49 say "Desc: " get l_ftdesc1 picture replicate ([x],20)
      @ 09, 07 say "Field " get l_ftotal2 picture replicate ([!],50)
      @ 09, 66	say "Func: " get l_ftfunc2 picture "!"
      @ 10, 09 say "where " get l_ftcond2 picture replicate ([x],30)
      @ 10, 49 say "Desc: " get l_ftdesc2 picture replicate ([x],20)
      @ 11, 07 say "Field " get l_ftotal3 picture replicate ([!],50)
      @ 11, 66	say "Func: " get l_ftfunc3 picture "!"
      @ 12, 09 say "where " get l_ftcond3 picture replicate ([x],30)
      @ 12, 49 say "Desc: " get l_ftdesc3 picture replicate ([x],20)
      @ 13, 07 say "Field " get l_ftotal4 picture replicate ([!],50)
      @ 13, 66	say "Func: " get l_ftfunc4 picture "!"
      @ 14, 09 say "where " get l_ftcond4 picture replicate ([x],30)
      @ 14, 49 say "Desc: " get l_ftdesc4 picture replicate ([x],20)
      @ 15, 07 say "Field " get l_ftotal5 picture replicate ([!],50)
      @ 15, 66	say "Func: " get l_ftfunc5 picture "!"
      @ 16, 09 say "where " get l_ftcond5 picture replicate ([x],30)
      @ 16, 49 say "Desc: " get l_ftdesc5 picture replicate ([x],20)
      @ 17, 07 say "Field " get l_ftotal6 picture replicate ([!],50)
      @ 17, 66	say "Func: " get l_ftfunc6 picture "!"
      @ 18, 09 say "where " get l_ftcond6 picture replicate ([x],30)
      @ 18, 49 say "Desc: " get l_ftdesc6 picture replicate ([x],20)
      f_rd ()
      f_restbox (yret)
   case yptr = 9
      yret = f_box (06, 05, 19, 70, "Parameter")
      @ 07, 07 say "Prompt: " get l_fprompt1 picture replicate ([X],40)
      @ 08, 09 say "Picture " get l_fpict1 picture replicate ([x],20)
      @ 08, 42 say "Type: " get l_fptyp1 picture [!] valid l_fptyp1 $ " CNDL"
      @ 08, 52 say "Length: " get l_fplen1 picture [99]
      @ 09, 09 say "Init Val" get l_fpinit1 picture replicate ([X],40)
      @ 10, 07 say "Prompt: " get l_fprompt2 picture replicate ([X],40)
      @ 11, 09 say "Picture " get l_fpict2 picture replicate ([x],20)
      @ 11, 42 say "Type: " get l_fptyp2 picture [!] valid l_fptyp2 $ " CNDL"
      @ 11, 52 say "Length: " get l_fplen2 picture [99]
      @ 12, 09 say "Init Val" get l_fpinit2 picture replicate ([X],40)
      @ 13, 07 say "Prompt: " get l_fprompt3 picture replicate ([X],40)
      @ 14, 09 say "Picture " get l_fpict3 picture replicate ([x],20)
      @ 14, 42 say "Type: " get l_fptyp3 picture [!] valid l_fptyp3 $ " CNDL"
      @ 14, 52 say "Length: " get l_fplen3 picture [99]
      @ 15, 09 say "Init Val" get l_fpinit3 picture replicate ([X],40)
      @ 16, 07 say "Prompt: " get l_fprompt4 picture replicate ([X],40)
      @ 17, 09 say "Picture " get l_fpict4 picture replicate ([x],20)
      @ 17, 42 say "Type: " get l_fptyp4 picture [!] valid l_fptyp4 $ " CNDL"
      @ 17, 52 say "Length: " get l_fplen4 picture [99]
      @ 18, 09 say "Init Val" get l_fpinit4 picture replicate ([X],40)
      f_rd ()
      f_restbox (yret)
   otherwise
      exit
   endcase
enddo
set key 28 to
set key 25 to
set key 14 to


******************************
procedure rrhlp

private i, yvar, yret, yptr, yfil, yarray [5]

yvar = alltrim (upper(readvar()))
yret = substr(yvar,1,len(yvar)-1)
do case
case yret $ "L_FILE;L_FALIAS"
   f_use ("rapath")
   if f_pick_f (05, 37, "", "", "falias")
      &yvar = f_truncate(fname, 8)
      keyboard chr(13)
   endif
   f_use ("rarpt")
case yret $ "L_FIELD;L_FIELD1;L_FSORT;L_FGROUP;L_FTOTAL;L_FKEY;L_FCOND"
   if empty(l_file1)
      f_popup ("You must select File 1 First. Press Any Key to Continue...",.t.)
      return
   endif
   if empty(l_file2+l_file3)
      yptr = 1
   else
      i = 1
      yarray[1] = l_file1
      if .not. empty(l_file2)
         i = i + 1
         yarray[2] = l_file2
      endif
      if .not. empty(l_file3)
         i = i + 1
         yarray[3] = l_file3
      endif
      yptr = f_pick_a (05, 41, "", "", yarray, i, 1)
   endif
   if yptr > 0
      f_use ("dbsetup")
      yfil = "l_file" + str(yptr,1)
      seek &yfil
      if .not. f_valid (found (), "Missing Dictionary Definitions ...")
         f_use ("rarpt")
         return
      endif
      if f_pick_f (05, 37, "", &yfil, "left(f_desc,25)+[ - ]+f_field+[ ]+" + ;
            "f_type+str(f_width,3)+[.]+str(f_dec,1)", "","f_name","["+&yfil+"]")
         if yret $ "L_FCOND"
            &yvar = f_truncate(trim(f_name)+"->"+trim(f_field), len (&yvar))
         else
            &yvar = f_truncate(trim(f_name)+"->"+trim(f_field), len (&yvar))
            keyboard chr(13)
         endif
      endif
   endif
   f_use ("rarpt")
case yret $ "L_FTFUNC"
   yarray[1] = " 1 - Count      "
   yarray[2] = " 2 - Sum        "
   yarray[3] = " 3 - Average    "
   yarray[4] = " 4 - Percentage "
   yarray[5] = " 5 - Calc       "
   yptr = f_pick_a (05, 41, "", "", yarray, 5, 1)
   if yptr > 0
      &yvar = str(yptr,1)
      keyboard chr(13)
   endif
case yvar $ "L_FORDER;L_FORDER2;L_FORDER3"
   f_use ("raidx")
   if yvar = "L_FORDER2"
      yfil = l_file2
   elseif yvar = "L_FORDER3"
      yfil = l_file3
   else
      yfil = l_file1
   endif

   seek f_truncate (yfil, 8)
   if f_valid (found (), "No Indexes Found For This File!!!")
      if f_pick_f (05, 10, "", "", "fodr+[ ]+fidx","", "fname", ;
            "[" + f_truncate (yfil, 8) + "]")
         &yvar = val (fodr)
         keyboard chr (13)
      endif
   endif
   f_use ("rarpt")
case yret = "L_FRANGE"
   f_use ("raidx")
   seek f_truncate (l_file1, 8) + str (l_forder, 1)
   if f_valid (found (), "Invalid File Name or Index Order!!!")
      f_popup ("Index Key - " + alltrim (fidx) + ". Press Any Key...", .t.)
   endif
   f_use ("rarpt")
otherwise
   f_popup ("No Help information for this Field. Press Any Key to Continue...",.t.)
endcase
set cursor on


******************************
procedure rrdelins

private ykey
private i, yvar, yret, yptr

ykey = lastkey ()
yvar = alltrim (upper (readvar ()))
yret = left (yvar, len (yvar) - 1)
yptr = val (right (yvar, 1))

setcolor (gsubget)

do case
case yret = "L_FCOND"
   rrptrrdp (ykey, 4, 1, yptr, "L_FCOND", space (50), 7, 19)
case yret $ "L_FIELD;L_FIELD1;"
   rrptrrdp (ykey, 15, 1, val (substr (yvar, 8)), "L_FIELD", space (74), 7, 3)
case yret $ "L_FDESC;L_FDESC1;"
   rrptrrdp (ykey, 15, 1, val (substr (yvar, 8)), "L_FDESC", space (15), 7, 62)
case yret = "L_FSORT"
   rrptrrdp (ykey, 3, 1, yptr, "L_FSORT", space (50), 7, 15)
case yret $ "L_FGROUP;L_FGDESC;L_FNP;"
   rrptrrdp (ykey, 3, 4, yptr, "L_FGROUP", space (50), 8, 16)
   rrptrrdp (ykey, 3, 4, yptr, "L_FGDESC", space (50), 9, 16)
   rrptrrdp (ykey, 3, 4, yptr, "L_FNP", .f., 10, 20, "Y")
case yret $ "L_FTOTAL;L_FTFUNC;L_FTCOND;L_FTDESC;"
   rrptrrdp (ykey, 6, 2, yptr, "L_FTOTAL", space (50), 7, 14)
   rrptrrdp (ykey, 6, 2, yptr, "L_FTFUNC", " ", 7, 73)
   rrptrrdp (ykey, 6, 2, yptr, "L_FTCOND", space (30), 8, 16)
   rrptrrdp (ykey, 6, 2, yptr, "L_FTDESC", space (20), 8, 56)
case yret $ "L_FPROMPT;L_FPICT;L_FPTYP;L_FPLEN;L_FPINIT;"
   rrptrrdp (ykey, 4, 3, yptr, "L_FPROMPT", space (40), 7, 16)
   rrptrrdp (ykey, 4, 3, yptr, "L_FPICT", space (20), 8, 18)
   rrptrrdp (ykey, 4, 3, yptr, "L_FPTYP", " ", 8, 49)
   rrptrrdp (ykey, 4, 3, yptr, "L_FPLEN", 0, 8, 61, "99")
   rrptrrdp (ykey, 4, 3, yptr, "L_FPINIT", space (40), 9, 18)
endcase
setcolor (gsubcolor)


******************************
function rrptrrdp

parameter xkey, xcnt, xinc, xptr, xfld, xspace, xrow, xcol, xpict
private i, yfld1, yfld2
if pcount () < 9
   xpict = ""
endif
if xkey = 25
   for i = xptr to xcnt - 1
      yfld1 = xfld + alltrim (str (i, 2))
      yfld2 = xfld + alltrim (str (i + 1, 2))
      &yfld1 = &yfld2
   next
   yfld1 = xfld + alltrim (str (xcnt, 2))
   &yfld1 = xspace
else
   for i = xcnt to xptr + 1 step -1
      yfld1 = xfld + alltrim (str (i, 2))
      yfld2 = xfld + alltrim (str (i - 1, 2))
      &yfld1 = &yfld2
   next
   yfld1 = xfld + alltrim (str (xptr, 2))
   &yfld1 = xspace
endif
for i = xptr to xcnt
   yfld1 = xfld + alltrim (str (i, 2))
   if empty (xpict)
      @ xrow + (i - 1) * xinc, xcol say &yfld1
   else
      @ xrow + (i - 1) * xinc, xcol say &yfld1 pict xpict
   endif
next

