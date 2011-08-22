* ===========================================================================
*
* RacWare Report Writer sub programs
*
* Author: EDC
* Date:  05/01/92
*
* Revision:
* 06/11/93: (edc) output to user given file name.
* 10/22/93: (edc) fix strange symbol display
* 11/03/93: (edc) sort date by the year in asending order
* 01/17/95: (edc) user defined formlen (fformlen)
* 01/17/95: (edc) add sub total for selected fields
*                 special symbol-> "{" ==> sum
*                                  "&" ==> count 
*                                  "+" ==> sum on alias
*                                  "#" ==> count on alias
* 07.31.98: year 2000 
* 05.07.99: y2k changes for sorting date field
* 07.01.99: set century on
* 12.07.04: fix window xp printing problem
* 03.13.08: add "T" keyword to print distinct rows
* ---
* 06.21.11: add email function 
* ===========================================================================

function f_rr

parameters xrptname, xtitle
private i, j, k, yret, ynewpage, yrptname

f_use ("rarpt", 1)
seek f_truncate (xrptname, 15)
if .not. f_valid (found (), "Missing Report " + xrptname)
   return -1
endif

l_outopt = " "
yrptname = rarpt->ftitle
f_box (02, 05, 04, 78, "You have selected")
@ 03, 07 say rarpt->fname + [ -> ] + rarpt->ftitle

* 06.21.11: add email report function
if gemrpt
   l_outopt = f_confirm ("[D]isplay on Screen  [P]rint  [F]ile  [E]mail  [Q]uit", "DPFEQ")    && add email
else
   l_outopt = f_confirm ("[D]isplay on Screen  [P]rint  [F]ile  [Q]uit", "DPFQ")    
endif
* --06.21.11

if l_outopt = "Q"
   return 0
endif

l_filename = space(40)
do while l_outopt = "F"
   @ 07, 00
   @ 07, 05 say "File Name: " get l_filename 
   if f_rd() = 27
      return 0
   else
      ykeyin = f_confirm ("Is this correct [Y/N/Q] ", "YNQ")
      if ykeyin = "Y"
         @ 07, 00
         exit
      elseif ykeyin = "Q"
         return 0
      endif
   endif
enddo

yemail = f_truncate(gemail,40)
* -- add email function: 06.21.11
do while l_outopt = "E"
   @ 07, 00
   @ 07, 05 say "email: " get yemail pict replicate ("x", 40) valid ;
     f_valid (f_goodem (yemail, .f.), "Invalid email address ...")     && cannot enter NA as valid email 
   if f_rd() = 27
      return 0
   else
      ykeyin = f_confirm ("Is this correct [Y/N/Q] ", "YNQ")
      if ykeyin = "Y"
         @ 07, 00
		 l_filename = gempath + "rr"+strtran(time(),":","")+".txt"
         exit
      elseif ykeyin = "Q"
         return 0
      endif
   endif
enddo
* --

for n = 1 to fcount ()
   xfld = field (n)
   xlfld = "L_" + xfld
   if type (xfld) = "C"
      &xlfld = alltrim (&xfld)
   else
      &xlfld = &xfld
   endif
next

l_foutopt = if(l_outopt=" ",l_foutopt,l_outopt)   && foutopt can be defined in rarpt.dbf
ynewpage = .t.
yret = 0

if empty (gete ("RACCPRT"))
   l_cprt = chr (27) + chr (15)
else
   l_cprt = alltrim (gete ("RACCPRT"))
   l_cprt = &l_cprt
endif
if empty (gete ("RACNPRT"))
   l_nprt = chr (18)
else
   l_nprt = alltrim (gete ("RACNPRT"))
   l_nprt = &l_nprt
endif

l_frlen = 2
* 01/17/95
l_fformlen = if(type("l_fformlen")="U", 132, l_fformlen)
l_formlen = if(l_fformlen>0, l_fformlen, 132)
*
l_fldlen = 0
l_nofld = 15
l_nofil = 3
l_nosfld = 3
l_sortlen = 0
l_nogfld = 3
l_notfld = 6
l_nopfld = 4
declare l_stitle [l_nofld]
declare l_rcalc [l_nofld]
declare l_rlen [l_nofld]
declare l_rfld [l_nofld]
declare l_rcol [l_nofld]
declare l_rtype [l_nofld]
declare l_dlen [l_nofld]
l_nostotal = 0
declare l_stotal [l_nofld]     && 01/17/95: subtotals
declare l_sortkey [l_nosfld]
declare l_stype [l_nosfld]
declare l_slen [l_nosfld]
declare l_group [l_nogfld]
declare l_gdesc [l_nogfld]
declare l_glen [l_nogfld]
declare l_gtype [l_nogfld]
declare l_sumfld [l_notfld]
declare l_sumtyp [l_notfld]
declare l_sumlen [l_notfld]
declare l_sumdec [l_notfld]
declare l_tdesc [l_notfld]
declare l_tcond [l_notfld]
declare l_tfunc [l_notfld]
declare l_total [l_notfld]

for i = 1 to l_nofld
   yfld = "l_cell" + alltrim (str (i, 2))
   &yfld = ""
next

for i = 1 to l_nogfld
   yfld = "l_fgdesc" + alltrim (str (i, 2))
   l_gdesc [i] = trim (&yfld)
next

*** y2k
set century on
for i = 1 to l_nopfld
   yfld = "l_fptyp" + alltrim (str (i, 2))
   ytyp = &yfld
   yfld = "l_fpinit" + alltrim (str (i, 2))
   ypinit = &yfld
   yfld = "l_param" + alltrim (str (i, 2))
   if .not. empty (ytyp)
      if .not. empty (ypinit) .and. type (ypinit) <> "U"
         if ytyp = "C"
            ylen = "l_fplen" + alltrim (str (i, 2))
            &yfld = f_truncate (&ypinit, &ylen)
         else
            &yfld = &ypinit
         endif
      else
         do case
         case ytyp = "N"
            &yfld = 0
         case ytyp = "D"
            &yfld = ctod ("  /  /    ")        && y2k
         case ytyp = "L"
            &yfld = .t.
         otherwise
            ylen = "l_fplen" + alltrim (str (i, 2))
            &yfld = space (&ylen)
         endcase
      endif
   else
      &yfld = ""
   endif
next
do while .t.
   yln = 7
   j = 0
   k = 0
   for i = 1 to l_nopfld
      yfld = "l_fprompt" + alltrim (str (i, 2))
      if upper (&yfld) = "ENTER "
         &yfld = substr (&yfld, 7)
      endif
      do while "." $ &yfld
         &yfld = strtran (&yfld, ".", "")
      enddo
      do while ":" $ &yfld
         &yfld = strtran (&yfld, ":", "")
      enddo
      if len (&yfld) > k
         k = len (&yfld)
      endif
   next
   k = k + 2
   for i = 1 to l_nopfld
      yfld = "l_fptyp" + alltrim (str (i, 2))
      ytyp = &yfld
      yfld = "l_param" + alltrim (str (i, 2))
      if .not. empty (ytyp)
         j = j + 1
         yprompt = "l_fprompt" + alltrim (str (i, 2))
         ypict = "l_fpict" + alltrim (str (i, 2))
         @ yln, 05 say &yprompt + replicate (".", k - len (&yprompt)) ;
           get &yfld picture alltrim (&ypict)
         yln = yln + 1
      else
         &yfld = ""
      endif
   next
   if j > 0
      f_rd ()
      ykeyin = f_confirm ("Is this correct [Y/N/Q] ", "YNQ")
      if ykeyin = "Y"
         * year 2000 check
         * if l_fptyp1 = "D"
         *    f_y2k (@l_param1)
         * endif
         * if l_fptyp2 = "D"
         *    f_y2k (@l_param2)
         * endif
         * if l_fptyp3 = "D"
         *    f_y2k (@l_param3)
         * endif
         * if l_fptyp4 = "D"
         *   f_y2k (@l_param4)
         * endif
         exit
      elseif ykeyin = "Q"
         return 0
      endif
   else
      exit
   endif
enddo
set century off

f_popup ("Please Wait...")
yret = f_rrin ()
if yret < 0
   close databases
   return yret
endif

* 10/03/00: add new command: set delete off
if l_fupdate = "D"
   set delete off
endif
yret = f_rrun ()
set delete on
if yret < 0 .or. yret = 99
   close databases
   return yret
endif
if l_foutopt = "D"
   set color to
   clear
   yfile = gstnpath + "rrout.rpt"
   run racbrow &yfile
   setcolor (gbluecolor)
elseif l_foutopt = "E"      &&  add email report function
   * --06.21.11
   if f_sndrep (yemail, yrptname, substr(l_filename, at("rr", l_filename)))    && i.e. rr123456.txt
      f_valid (.f., "Email is now in the message queue ...")
   else
      f_valid (.f., "Email is not setup ...")
   endif
   
   * --
endif

return yret


******************************
function f_rrin

private i, j, k, ydb, yfile, yfld, ypos, yt, ycol, ylen, ytype

f_use ("dbsetup")
for i = 1 to l_nofil
   yfile = "l_file" + str (i, 1)
   if empty (&yfile)
      exit
   endif
   f_use ("dbsetup")
   seek f_truncate (&yfile, 8)
   if .not. f_valid (found (), "Invalid File: " + &yfile)
      return (-1)
   endif
next
l_nofil = i - 1
if .not. f_valid (l_nofil > 0, "Please select file and retry ...")
   return (-2)
endif

j = 0
l_fldlen = 0
for i = 1 to l_nofld
   yfld = "l_field" + alltrim (str (i, 2))
   yfld = &yfld
   ydesc = "l_fdesc" + alltrim (str (i, 2))
   if .not. empty (yfld)
      j = j + 1
      * 01/17/95: field sub totals
      if left (yfld, 1) = "{"
         l_stotal [j] = "S"
         l_nostotal = l_nostotal + 1
         yfld = substr (yfld, 2)
      elseif left (yfld, 1) = "&"
         l_stotal [j] = "N"
         l_nostotal = l_nostotal + 1
         yfld = substr (yfld, 2)
      else
         l_stotal [j] = ""
      endif
      *
      if left (yfld, 1) $ "+#["
         if left (yfld, 1) $ "+#"
            ypos = at ('[', yfld)
            l_rcalc [j] = trim (left (yfld, ypos - 1))
            yfld = substr (yfld, ypos)
         else
            l_rcalc [j] = ""
         endif
         ypos = at ('\', yfld)
         l_rfld [j] = substr (yfld, 2, ypos - 2)
         ypos = ypos + 1
         l_rtype [j] = substr (yfld, ypos, 1)
         l_rcol [j] = l_frlen
         l_stitle [j] = &ydesc
         yfld = alltrim (strtran (substr (yfld, ypos + 2), "]", ""))
         if l_rtype [j] = "N"
            ypos = at ("\", yfld)
            l_dlen [j] = val (left (yfld, ypos - 1))
            l_rtype [j] = "N" + substr (yfld, ypos + 1)
         else
            l_dlen [j] = val (yfld)
         endif
         l_rlen [j] = min (max (l_dlen [j], len (l_stitle [j])), ;
            l_formlen - l_frlen)
      else
         l_rcalc [j] = ""
         f_use ("dbsetup")
         yt = substr (yfld, at ('>', yfld) + 1)
         seek f_truncate (substr (yfld, 1, at ('-', yfld) - 1), 8) + 'D' + ;
            f_truncate (yt, 10)
         if .not. f_valid (found (), "Invalid Field: " + yt)
            return (-3)
         endif
         l_rfld [j] = yfld
         l_rcol [j] = l_frlen
         l_stitle [j] = &ydesc
         if empty (l_stitle [j])
            l_stitle [j] = alltrim (dbsetup->f_desc)
         endif
         l_dlen [j] = dbsetup->f_width
         l_rlen [j] = min (max (dbsetup->f_width, len (l_stitle [j])), ;
            l_formlen - l_frlen)
         if dbsetup->f_type = "N"
            l_rtype [j] = dbsetup->f_type + alltrim (str (dbsetup->f_dec))
         else
            l_rtype [j] = dbsetup->f_type
         endif
      endif

      if l_rtype [j] = "N"   
         l_dlen [j] = l_rlen [j]
      endif
      l_fldlen = l_fldlen + l_rlen [j]
      l_frlen = l_frlen + l_rlen [j] + 1
      if l_frlen > l_formlen
         exit
      endif
   endif
next
l_nofld = j
if .not. f_valid (l_nofld > 0, "Please select field and retry ...")
   return (-4)
endif

j = int (min (l_formlen - l_frlen, l_frlen) / l_nofld)
if j > 0
   for i = 2 to l_nofld
      l_rcol [i] = l_rcol [i] + j * (i - 1)
   next
endif

j = 0
for i = 1 to l_nosfld
   yfld = "l_fsort" + str (i, 1)
   yfld = &yfld
   if .not. empty (yfld)
      j = j + 1
      if left (yfld, 1) = "["
         ypos = at ('\', yfld)
         l_sortkey [j] = substr (yfld, 2, ypos - 2)
         ypos = ypos + 1
         l_stype [j] = substr (yfld, ypos, 1)
         yfld = alltrim (strtran (substr (yfld, ypos + 2), "]", ""))
         if l_stype [j] = "N"
            ypos = at ("\", yfld)
            l_slen [j] = val (left (yfld, ypos - 1))
            l_stype [j] = "N" + substr (yfld, ypos + 1)
         else
            l_slen [j] = val (yfld)
         endif
         l_sortlen = l_sortlen + l_slen [j]
      else
         f_use ("dbsetup")
         yt = substr (yfld, at ('>', yfld) + 1)
         l_sortkey [j] = yfld
         seek f_truncate (substr (yfld, 1, at ('-', yfld) - 1), 8) + 'D' + ;
            f_truncate (yt, 10)
         if .not. f_valid (found (), "Invalid Sort Field: " + yt)
            return (-5)
         endif
         l_slen [j] = dbsetup->f_width
         l_sortlen = l_sortlen + dbsetup->f_width
         if dbsetup->f_type = "N"
            l_stype [j] = "N" + alltrim (str (dbsetup->f_dec))
         else
            l_stype [j] = dbsetup->f_type
         endif
      endif
   endif
next
l_nosfld = j

j = 0
for i = 1 to l_nogfld
   yfld = "l_fgroup" + str (i, 1)
   yfld = &yfld
   if .not. empty (yfld)
      j = j + 1
      if left (yfld, 1) = "["
         ypos = at ('\', yfld)
         l_group [j] = substr (yfld, 2, ypos - 2)
         ypos = ypos + 1
         l_gtype [j] = substr (yfld, ypos, 1)
         yfld = alltrim (strtran (substr (yfld, ypos + 2), "]", ""))
         if l_gtype [j] = "N"
            ypos = at ("\", yfld)
            l_glen [j] = val (left (yfld, ypos - 1))
            l_gtype [j] = "N" + substr (yfld, ypos + 1)
         else
            l_glen [j] = val (yfld)
         endif
      else
         f_use ("dbsetup")
         yt = substr (yfld, at ('>', yfld) + 1)
         l_group [i] = yfld
         seek f_truncate (substr (yfld, 1, at ('-', yfld) - 1), 8) + 'D' + ;
            f_truncate (yt, 10)
         if .not. f_valid (found (), "Invalid Group Field: " + yt)
            return (-6)
         endif
         l_glen [j] = dbsetup->f_width
         if dbsetup->f_type = "N"
            l_gtype [j] = dbsetup->f_type + alltrim (str (dbsetup->f_dec))
         else
            l_gtype [j] = dbsetup->f_type
         endif
      endif
   endif
next
l_nogfld = j

j = 0
for i = 1 to l_notfld
   yfld = "l_ftotal" + str (i, 1)
   yfld = &yfld
   if .not. empty (yfld)
      j = j + 1
      yfld = "l_ftdesc" + alltrim (str (j, 2))
      l_tdesc [j] = trim (&yfld)
      yfld = "l_ftcond" + alltrim (str (j, 2))
      if empty (&yfld)
         l_tcond [j] = ".T."
      else
         l_tcond [j] = trim (&yfld)
      endif
      yfld = "l_ftfunc" + alltrim (str (j, 2))
      l_tfunc [j] = &yfld

      yfld = "l_ftotal" + str (i, 1)
      yfld = &yfld
      if l_tfunc [j] <> "5"
         if left (yfld, 1) = "["
            ypos = at ('\', yfld)
            l_sumfld [j] = substr (yfld, 2, ypos - 2)
            ypos = ypos + 1
            l_sumtyp [j] = substr (yfld, ypos, 1)
            yfld = alltrim (strtran (substr (yfld, ypos + 2), "]", ""))
            if l_sumtyp [j] = "N"
               ypos = at ("\", yfld)
               l_sumlen [j] = max (val (left (yfld, ypos - 1)), 10)
               l_sumdec [j] = val (substr (yfld, ypos + 1))
            else
               l_sumdec [j] = 0
               l_sumlen [j] = val (yfld)
            endif
         else
            f_use ("dbsetup")
            yt = substr (yfld, at ('>', yfld) + 1)
            l_sumfld [j] = yfld
            seek f_truncate (substr (yfld, 1, at ('-', yfld) - 1), 8) + 'D' + ;
               f_truncate (yt, 10)
            if .not. f_valid (found (), "Invalid Calculated Field: " + yt)
               return (-7)
            endif
            l_sumlen [j] = max (dbsetup->f_width, 10)
            l_sumtyp [j] = dbsetup->f_type
            if dbsetup->f_type = "N"
               l_sumdec [j] = dbsetup->f_dec
            elseif f_valid (l_tfunc [j] = "1", yt + "is not numeric ...")
               l_sumdec [j] = 0
            else
               return (-8)
            endif
         endif
      else
         l_sumfld [j] = yfld
      endif
   endif
next
l_notfld = j

f_use ("dbsetup")
use
return (0)


******************************
function f_rrun

private i, j, yc1, yc2, yc3, ybuffer, ycond
private yfil, yln, ycol, yfld, ydesc, yy, yz
private ysortfil, ysrcfil, ytarget, yrlen

if .not. empty (l_file2)
   f_use (l_file2, l_forder2)
   yndxkey2 = indexkey (0)
endif

if .not. empty (l_file3)
   f_use (l_file3, l_forder3)
   yndxkey3 = indexkey (0)
endif

select 0
yfil = gstnpath + "#tmp"
create &yfil
use &yfil exclusive
if l_nosfld > 0
   append blank
   replace field_name with "SORTFLD", field_type with "C"
   replace field_len with l_sortlen
endif
for i = 1 to l_nogfld
   append blank
   yfil = "GROUP" + str (i, 1)
   replace field_name with yfil, field_type with "C"
   replace field_len with l_glen [i]
next
for i = 1 to l_notfld
   if l_tfunc [i] <> "5"
      append blank
      yfil = "TOTAL" + str (i, 1)
      replace field_name with yfil, field_type with "N"
      replace field_len with l_sumlen [i], field_dec with l_sumdec [i]
      append blank
      yfil = "TOK" + str (i, 1)
      replace field_name with yfil, field_type with "L"
      replace field_len with 1
   endif
next
append blank
replace field_name with "FFLDS", field_type with "C"
replace field_len with l_fldlen
use
create (gstnpath + "#sort") from (gstnpath + "#tmp")
use

if l_forder > 0
   f_use ("raidx", 1)
   seek f_truncate (l_file1, 8) + str (l_forder, 1)
   if .not. f_valid (found (), "Invalid Index Order!!!")
      use
      return (-9)
   else
      yidx = alltrim (fidx)
   endif
   f_use (l_file1, l_forder)
else
   f_use (l_file1)
   yidx = ""
endif

ysortfil = gstnpath + "#sort"
select 0
use &ysortfil exclusive alias sortdb
if l_nosfld > 0
   index on sortfld to &ysortfil
endif

j = 0

select &l_file1

ycond = alltrim (l_fcond1) + alltrim (l_fcond2) + alltrim (l_fcond3) + ;
   alltrim (l_fcond4)
if empty (ycond)
   ycond = ".t."
else
   if .not. f_valid (type (ycond) = "L", "Invalid query definition ...")
      return (-4)
   endif
endif

if empty (yidx)
   go top
else
   * 07/26/95: allow function for range setup
   *if .not. f_valid (type (yidx) = type (l_frange1) .and. ;
   *      type (yidx) = type (l_frange2), "Invalid Range Set Up...")
   *   return (-9)
   *endif
   set softseek on
   seek &l_frange1
   set softseek off
endif

j0 = 0
f_popup ("Please wait or <Esc> to abort")
do while .not. eof ()
   if inkey () = 27
      if chr (f_popup ("Do you want to quit? [Y/N] ", .t.)) $ "Yy"
         return 99
      endif
   endif
   j0 = j0 + 1
   if .not. empty (yidx)
      if &yidx > &l_frange2
         exit
      endif
   endif

   if .not. empty (l_fkey1) .and. .not. empty (l_falias1)
      select &l_falias1
      seek &l_fkey1
   endif
   if .not. empty (l_fkey2) .and. .not. empty (l_falias2)
      select &l_falias2
      seek &l_fkey2
   endif

   select sortdb
   append blank
   ybuffer = ""
   yfnd = &ycond
   for i = 1 to l_nofld
      yfld = l_rfld [i]
      if ("L_CELL" + alltrim (str (i, 2))) $ yfld
         f_valid (.f., "L_CELL" + alltrim (str (i, 2)) + " is recuring ...")
         return (-5)
      endif
      * if .not. f_valid (type (yfld) <> "U", yfld + " is not accessable ...")
      *    return (-5)
      * endif
      ycell = "l_cell" + alltrim (str (i, 2))
      if .not. empty (l_rcalc [i])
         yval = 0
         if substr (l_rcalc [i], 2) == l_falias1
            select &l_falias1
            yrecno = recno ()
            do while &yndxkey2 = &l_fkey1
               if &ycond
                  yfnd = .t.
                  if left (l_rcalc [i], 1) = "+"
                     yval = yval + &yfld
                  else
                     yval = yval + 1
                  endif
               endif
               skip
            enddo
            go (yrecno)
         elseif substr (l_rcalc [i], 2) == l_falias2
            select &l_falias2
            yrecno = recno ()
            do while &yndxkey3 = &l_fkey2
               if &ycond
                  yfnd = .t.
                  if left (l_rcalc [i], 1) = "+"
                     yval = yval + &yfld
                  else
                     yval = yval + 1
                  endif
               endif
               skip
            enddo
            go (yrecno)
         endif
         &ycell = yval
         ybuffer = ybuffer + str (&ycell, l_dlen [i], ;
            val (right (l_rtype [i], 1)))
      else
         if l_rtype [i] = "C"
            &ycell = f_truncate (&yfld, l_dlen [i])
            ybuffer = ybuffer + &ycell
         else
            &ycell = &yfld
            if l_rtype [i] = "N"
               ybuffer = ybuffer + str (&ycell, l_dlen [i], ;
                  val (right (l_rtype [i], 1)))
            elseif l_rtype [i] = "D"
               ybuffer = ybuffer + dtoc (&ycell)
            elseif l_rtype [i] = "L"
               ybuffer = ybuffer + if (&yfld, "Y", "N")
            endif
         endif
      endif
   next
   select sortdb
   if yfnd
      replace fflds with ybuffer
      j = j + 1
      if l_nosfld > 0
         select sortdb
         ybuffer = ""
         for i = 1 to l_nosfld
            yfld = l_sortkey [i]
            if .not. f_valid (type (yfld) <> "U", ;
                  yfld + " (sort) is not accessable ...")
               return (-6)
            endif
            if l_stype [i] = "C"
               ybuffer = ybuffer + f_truncate (&yfld, l_slen [i])
            elseif l_stype [i] = "N"
               ystrtmp = str (abs (&yfld), l_slen [i], ;
                  val (right (l_stype [i], 2)))
               if &yfld < 0
                  ystrtmp = strtran (ystrtmp, " ", "A")
                  ybuffer = ybuffer + "-" + substr (ystrtmp, 2)
               else
                  ystrtmp = strtran (ystrtmp, " ", "0")
                  ybuffer = ybuffer + ystrtmp
               endif
            elseif l_stype [i] = "D"
               * ybuffer = ybuffer + dtoc (&yfld)
               && 11/03/93: by the year in ascending order
               * 05.07.99: y2k changes
               * yfld = dtoc (&yfld)
               * ybuffer = ybuffer + substr(yfld,7,2)+substr(yfld,1,2)+substr(yfld,4,2)
               ybuffer = ybuffer + dtos (&yfld)
            else
               ybuffer = ybuffer + if (&yfld, "Y", "N")
            endif
         next
         replace sortfld with ybuffer
      endif
      if l_nogfld > 0
         select sortdb
         for i = 1 to l_nogfld
            ybuffer = ""
            yfld = l_group [i]
            if .not. f_valid (type (yfld) <> "U", ;
                  yfld + " (group) is not accessable ...")
               return (-7)
            endif
            if l_gtype [i] = "N"
               ybuffer = str (&yfld, l_glen [i], val (right (l_gtype [i], 1)))
            elseif l_gtype [i] = "D"
               ybuffer = dtoc (&yfld)
               *&& 11/03/93: by the year in ascending order
               *yfld = dtoc (&yfld)
               *ybuffer = substr(yfld,7,2)+substr(yfld,1,2)+substr(yfld,4,2)
            elseif l_gtype [i] = "L"
               ybuffer = ybuffer + if (&yfld, "Y", "N")
            else
               ybuffer = f_truncate (&yfld, l_glen [i])
            endif
            yfld = "GROUP" + str (i, 1)
            replace &yfld with ybuffer
         next
      endif
      if l_notfld > 0
         select sortdb
         for i = 1 to l_notfld
            if l_tfunc [i] <> "5"
               ybuffer = ""
               yfld = l_tcond [i]
               if .not. f_valid (type (yfld) = "L", ;
                     yfld + " (calculated): Invalid logic ...")
                  return (-8)
               endif
               if &yfld
                  if l_tfunc [i] = "1"
                     yfld = "TOTAL" + str (i, 1)
                     replace &yfld with 1
                  else
                     yfld = l_sumfld [i]
                     ybuffer = &yfld
                     yfld = "TOTAL" + str (i, 1)
                     replace &yfld with ybuffer
                  endif
                  yfld = "TOK" + str (i, 1)
                  replace &yfld with .t.
               else
                  yfld = "TOK" + str (i, 1)
                  replace &yfld with .f.
               endif
            endif
         next
      endif
   else
      delete
   endif
   @ 24, 01 say " Pick: " + ltrim (str (j, 5)) + "  Scan: " ;
      + ltrim (str (j0, 5)) + " "
   select &l_file1
   skip
enddo
select &l_file1
use

if .not. empty (l_file2)
   select &l_file2
   use
endif

if .not. empty (l_file3)
   select &l_file3
   use
endif

select sortdb
go top
if .not. f_valid (.not. eof (), "Empty Selection ...")
   return (99)
endif

f_popup ("Creating Report ...")
if l_foutopt $ "DEF"        && 06.21.11: add Email
   if empty(l_filename)
      yfil = gstnpath + "rrout.rpt"
   else
      yfil = l_filename
   endif
   set device to print
   set printer to &yfil
else
   * set device to print
   set console off
   set print on
   set device to print
   set printer to lpt1
endif

i = l_formlen
yc1 = max (20, int (i/2) - int (len (gtitle) / 2))
yc2 = max (20, int (i/2) - int (len (l_ftitle) / 2))
yc3 = l_formlen - 12

if l_nogfld > 0 .or. l_notfld > 0
   select sortdb
   l_reccount = reccount ()
   if l_nogfld > 0
      declare l_reccnt [l_nogfld]
      afill (l_reccnt, 0)
      declare l_okey [l_nogfld], l_gp1 [l_nogfld]
      afill (l_okey, "")
      afill (l_gp1, .t.)
   endif
   if l_notfld > 0
      declare l_t1 [l_notfld], l_c1 [l_notfld]
      declare l_t2 [l_notfld], l_c2 [l_notfld]
      declare l_t3 [l_notfld], l_c3 [l_notfld]
      declare l_gt [l_notfld], l_gc [l_notfld]
      afill (l_t1, 0)
      afill (l_t2, 0)
      afill (l_t3, 0)
      afill (l_gt, 0)
      afill (l_c1, 0)
      afill (l_c2, 0)
      afill (l_c3, 0)
      afill (l_gc, 0)
   endif
endif

if l_nostotal > 0
   declare l_sum [l_nofld]            && hold area for present subtotals at break
   declare l_scnt [l_nogfld + 1]      && 
   declare l_st1 [l_nofld]
   declare l_st2 [l_nofld]
   declare l_st3 [l_nofld]
   declare l_sgt [l_nofld]
   afill (l_sum, 0)
   afill (l_scnt, 0)
   afill (l_st1, 0)
   afill (l_st2, 0)
   afill (l_st3, 0)
   afill (l_sgt, 0)
endif

l_date = dtoc (date ())
l_time = time ()
l_page = 0
l_pgsize = 55

yheader = ""
for n = 1 to l_nopfld
   ystr1 = "l_fprompt" + alltrim (str (n, 2))
   if .not. empty (&ystr1)
      ystr2 = "l_param" + alltrim (str (n, 2))
      ystr3 = "l_fpict" + alltrim (str (n, 2))
      ystr4 = "l_fptyp" + alltrim (str (n, 2))
      ystr5 = "l_fplen" + alltrim (str (n, 2))
      ystr = upper (&ystr1) + ": "
      if type (ystr2) = "N"
         ystr = ystr + alltrim (str (&ystr2))
      elseif type (ystr2) = "C"
         if empty (&ystr2)
            ystr = ystr + "ALL"
         else
            ystr = ystr + alltrim (&ystr2)
         endif
      elseif type (ystr2) = "L"
         ystr = ystr + if (&ystr2, "YES", "NO")
      elseif type (ystr2) = "D"
         if empty (&ystr2)
            ystr = ystr + "ALL"
         else
            ystr = ystr + dtoc (&ystr2)
         endif
      endif
      do while "  " $ ystr
         ystr = strtran (ystr, "  ", " ")
      enddo
      yheader = yheader + ystr + "   "
   endif
next
yheader = alltrim (yheader)
ylh = len (yheader)

if l_formlen > ylh
   yheader = space (int (l_formlen / 2) - int (ylh / 2)) + yheader
endif

yln = f_rrformat (99, l_pgsize)

* 03.13.08: implement distinct
select sortdb
go top
yoldkey = ""
if l_fdisp <> "T"      && Distinct function perform on sort key only
   yshow = ".t."
else
   if type ("sortfld") = "U"
      yshow = ".t."
   else
      yshow = "yoldkey <> sortfld"
   endif
endif
* --- 03.13.08

do while .not. eof ()
   for i = l_nogfld to 1 step -1
      yfld = "GROUP" + str (i, 1)
      if (&yfld <> l_okey [i]) .or. l_gp1 [i]
         if .not. l_gp1 [i]
            for i1 = 1 to i

               * 01/17/95: output subtotals
               if l_nostotal > 0
                  yln = f_rrformat (yln, l_pgsize)
                  for j = 1 to l_nofld
                     if l_stotal [j] = "S"          && sum
                        yz = "l_st" + str (i1, 1)
                        yfld = str(&yz [j], l_dlen [j], val (right (l_rtype [j], 1)))
                        @ yln, l_rcol [j] say yfld
                        l_sum [j] = &yz [j]         && hold subtotal value
                        &yz [j] = 0
                     elseif l_stotal [j] = "N"      && count
                        yz = l_scnt [i1]
                        @ yln, l_rcol [j] say str(yz, l_dlen [j], 0)
                        l_sum [j] = yz              && hold subtotal value
                        l_scnt [i1] = 0
                     endif
                  next
                  yln = f_rrformat (yln, l_pgsize)
                  for j = 1 to l_nofld
                     if l_stotal [j] $ "SN"
                        ycol = l_rcol [j]
                        ylen = l_rlen [j]
                        @ yln, ycol say replicate ("-", ylen)
                     endif
                  next
                  yln = f_rrformat (yln, l_pgsize)
               endif
               *

               if l_notfld > 0
                  yln = f_rrformat (yln, l_pgsize)
                  @ yln, 02 say "SUMMARY FOR " + l_okey [i1]
               endif
               for j = 1 to l_notfld
                  yy = "l_t" + str (i1, 1)
                  yz = "l_c" + str (i1, 1)
                  yln = f_rrformat (yln, l_pgsize)
                  if l_tfunc [j] = "1"
                     l_total [j] = &yz [j]
                     *if &yz [j] = l_reccnt [i1]   && 08/18/94 edc
                     *   @ yln, 02 say l_tdesc [j] + [ ] + str (&yz [j], 10)
                     *else
                        @ yln, 02 say l_tdesc [j] + [ ] + str (&yz [j], 10) + ;
                           [  ] + str ((&yz [j] / l_reccnt [i1])*100, ;
                           l_sumlen [j], l_sumdec [j]) + [%]
                     *endif
                  elseif l_tfunc [j] = "2"
                     l_total [j] = &yy [j]
                     @ yln, 02 say l_tdesc [j] + [ ]  + str (&yy [j], ;
                        l_sumlen [j], l_sumdec [j])
                  elseif l_tfunc [j] = "3"
                     l_total [j] = &yy [j] / &yz [j]
                     @ yln, 02 say l_tdesc [j] + [ ]  + str ((&yy [j] / ;
                        &yz [j]), l_sumlen [j], l_sumdec [j])
                  elseif l_tfunc [j] = "4"
                     l_total [j] = &yy [j]
                     @ yln, 02 say l_tdesc [j] + [ ] + str (&yy [j], ;
                        l_sumlen [j], l_sumdec [j]) + [ <sum>]
                     yln = f_rrformat (yln, l_pgsize)
                     @ yln, 03 + len (l_tdesc [j]) say str (&yz [j], 10) +  [ <rec>]
                     yln = f_rrformat (yln, l_pgsize)
                     @ yln, 03 + len (l_tdesc [j]) say str ((&yy [j] / &yz [j]), ;
                        l_sumlen [j], l_sumdec [j]) + [ <avg>]
                     *if &yz [j] <> l_reccnt [i1]    && 08/18/94 edc
                        yln = f_rrformat (yln, l_pgsize)
                        @ yln, 03 + len (l_tdesc [j]) say str ((&yz [j] / ;
                           l_reccnt [i1])*100, l_sumlen [j], l_sumdec [j]) ;
                           + [%]
                     *endif
                  else
                     yfld = l_sumfld [j]
                     l_total [j] = &yfld
                     * @ yln, 02 say l_tdesc [j] + [ ] + &yfld
                     @ yln, 02 say l_tdesc [j] + [ ] + str(l_total [j],10,2)
                  endif
                  &yy [j] = 0
                  &yz [j] = 0
               next
               yln = f_rrformat (yln, l_pgsize)
            next
            if .not. ynewpage
               ystr = "L_FNP" + str (i, 1)
               if &ystr
                  yln = f_rrformat (yln, 0)
               endif
            elseif l_notfld > 0
               yln = f_rrformat (yln, l_pgsize)
            endif
            for i1 = i to 1 step -1
               yfld = "GROUP" + str (i1, 1)
               yln = f_rrformat (yln, l_pgsize)
               @ yln, 02 say l_gdesc [i1] + [ ] + &yfld
               yln = f_rrformat (yln, l_pgsize)
               l_okey [i1] = &yfld
               l_reccnt [i1] = 1
            next
            exit
         endif
         yln = f_rrformat (yln, l_pgsize)
         @ yln, 02 say l_gdesc [i] + [ ] + &yfld
         yln = f_rrformat (yln, l_pgsize)
         l_gp1 [i] = .f.
         l_okey [i] = &yfld
         l_reccnt [i] = 1
      else
         l_reccnt [i] = l_reccnt [i] + 1
      endif
   next
   if l_fdisp <> "S" .or. l_nostotal > 0

      * --03.13.08
      if &yshow   

      if type("sortfld") <> "U"
         yoldkey = sortfld
      endif
      * --03.13.08

      yptr = 1
      for i = 1 to l_nofld
         yfld = substr (fflds, yptr, l_dlen [i])
         if l_fdisp <> "S"
            @ yln, l_rcol [i] say yfld
         endif
         * 01/17/95: subtotal fields
         if l_stotal [i] = "S"
            l_st1 [i] = l_st1[i] + val (yfld)
            l_st2 [i] = l_st2[i] + val (yfld)
            l_st3 [i] = l_st3[i] + val (yfld)
            l_sgt [i] = l_sgt[i] + val (yfld)
         elseif l_stotal [i] = "N"
            for j = 1 to l_nogfld + 1
                l_scnt [j] = l_scnt [j] + 1
            next
         endif
         *
         yptr = yptr + l_dlen [i]
      next
      if l_fdisp <> "S"
         yln = f_rrformat (yln, l_pgsize)
      endif

      endif    && 03.13.08

   endif
   for i = 1 to l_notfld
      if l_tfunc [i] <> "5"
         yfld = "TOK" + str (i, 1)
         if &yfld
            l_c1 [i] = l_c1 [i] + 1
            l_c2 [i] = l_c2 [i] + 1
            l_c3 [i] = l_c3 [i] + 1
            l_gc [i] = l_gc [i] + 1
            yfld = "TOTAL" + str (i, 1)
            l_t1 [i] = l_t1 [i] + &yfld
            l_t2 [i] = l_t2 [i] + &yfld
            l_t3 [i] = l_t3 [i] + &yfld
            l_gt [i] = l_gt [i] + &yfld
         endif
      endif
   next
   select sortdb
   skip
enddo

for i = 1 to l_nogfld
   * 01/17/95: output subtotals
   if l_nostotal > 0
      yln = f_rrformat (yln, l_pgsize)
      for j = 1 to l_nofld
         if l_stotal [j] = "S"
            yz = "l_st" + str (i, 1)
            yfld = str(&yz [j], l_dlen [j], val (right (l_rtype [j], 1)))
            @ yln, l_rcol [j] say yfld
            l_sum [j] = &yz [j]         && hold subtotal value
         elseif l_stotal [j] = "N"      && count
            yz = l_scnt [i]
            l_sum [j] = yz
            @ yln, l_rcol [j] say str(yz, l_dlen [j], 0)
         endif
      next
      yln = f_rrformat (yln, l_pgsize)
      for j = 1 to l_nofld
         if l_stotal [j] $ "SN"
            ycol = l_rcol [j]
            ylen = l_rlen [j]
            @ yln, ycol say replicate ("-", ylen)
         endif
      next
      yln = f_rrformat (yln, l_pgsize)
   endif
   *
   if l_notfld > 0
      yln = f_rrformat (yln, l_pgsize)
      @ yln, 02 say "SUMMARY FOR " + l_okey [i]
   endif
   for j = 1 to l_notfld
      yy = "l_t" + str (i, 1)
      yz = "l_c" + str (i, 1)
      yln = f_rrformat (yln, l_pgsize)
      if l_tfunc [j] = "1"
         l_total [j] = &yz [j]
         *if &yz [j] = l_reccnt [i]    && 08/18/94 edc
         *   @ yln, 02 say l_tdesc [j] + [ ]  + str (&yz [j], 10)
         *else
            @ yln, 02 say l_tdesc [j] + [ ]  + str (&yz [j], 10) +   ;
               [  ] + str ((&yz [j] / l_reccnt [i])*100, l_sumlen [j], ;
               l_sumdec [j]) + [%]
         *endif
      elseif l_tfunc [j] = "2"
         l_total [j] = &yy [j]
         @ yln, 02 say l_tdesc [j] + [ ]  + str (&yy [j], ;
            l_sumlen [j], l_sumdec [j])
      elseif l_tfunc [j] = "3"
         l_total [j] = &yy [j] / &yz [j]
         @ yln, 02 say l_tdesc [j] + [ ]  + str ((&yy [j] / &yz [j]), ;
            l_sumlen [j], l_sumdec [j])
      elseif l_tfunc [j] = "4"
         l_total [j] = &yy [j]
         @ yln, 02 say l_tdesc [j] + [ ] + str (&yy [j], ;
            l_sumlen [j], l_sumdec [j]) + [ <sum>]
         yln = f_rrformat (yln, l_pgsize)
         @ yln, 03 + len (l_tdesc [j]) say str (&yz [j], 10) +  [ <rec>]
         yln = f_rrformat (yln, l_pgsize)
         @ yln, 03 + len (l_tdesc [j]) say str ((&yy [j] / &yz [j]), ;
            l_sumlen [j], l_sumdec [j]) + [ <avg>]
         *if &yz [j] <> l_reccnt [i]    && 08/18/94 edc
            yln = f_rrformat (yln, l_pgsize)
            @ yln, 03 + len (l_tdesc [j]) say str ((&yz [j] / ;
               l_reccnt [i])*100, l_sumlen [j], l_sumdec [j]) + [%]
         *endif
      else
         yfld = l_sumfld [j]
         l_total [j] = &yfld
         * @ yln, 02 say l_tdesc [j] + [ ] + &yfld
         @ yln, 02 say l_tdesc [j] + [ ] + str(l_total [j],10,2)
      endif
   next
   yln = yln + 1
next

* 01/17/95: output subtotals
if l_nostotal > 0
   yln = f_rrformat (yln, l_pgsize)
   for j = 1 to l_nofld
      if l_stotal [j] = "S"
         yfld = str(l_sgt [j], l_dlen [j], val (right (l_rtype [j], 1)))
         l_sum [j] = l_sgt [j]
         @ yln, l_rcol [j] say yfld
      elseif l_stotal [j] = "N"      && count
         yz = l_scnt [l_nogfld+1]
         l_sum [j] = yz
         @ yln, l_rcol [j] say str(yz, l_dlen [j], 0)
      endif
   next
   yln = f_rrformat (yln, l_pgsize)
   for j = 1 to l_nofld
      if l_stotal [j] $ "SN"
         ycol = l_rcol [j]
         ylen = l_rlen [j]
         @ yln, ycol say replicate ("=", ylen)
      endif
   next
   yln = f_rrformat (yln, l_pgsize)
endif
*

if l_notfld > 0
   yln = f_rrformat (yln + 1, l_pgsize)
   @ yln, 02 say "REPORT SUMMARY "
   for j = 1 to l_notfld
      yln = f_rrformat (yln, l_pgsize)
      if l_tfunc [j] = "1"
         l_total [j] = l_gc [j]
         *if (l_gc [j] = l_reccount)     && 08/18/94 edc
         *   @ yln, 02 say l_tdesc [j] + [ ]  + str (l_gc [j], 10)
         *else
            @ yln, 02 say l_tdesc [j] + [ ]  + str (l_gc [j], 10) +    ;
               [  ] + str ((l_gc [j] / l_reccount)*100, l_sumlen [j], ;
               l_sumdec [j]) + [%]
         *endif
      elseif l_tfunc [j] = "2"
         l_total [j] = l_gt [j]
         @ yln, 02 say l_tdesc [j] + [ ]  + str (l_gt [j], ;
            l_sumlen [j], l_sumdec [j])
      elseif l_tfunc [j] = "3"
         l_total [j] = l_gt [j] / l_gc [j]
         @ yln, 02 say l_tdesc [j] + [ ]  + str ((l_gt [j] / l_gc [j]), ;
            l_sumlen [j], l_sumdec [j])
      elseif l_tfunc [j] = "4"
         l_total [j] = l_gt [j]
         @ yln, 02 say l_tdesc [j] + [ ] + str (l_gt [j], l_sumlen [j], l_sumdec [j]) + [ <sum>]
         yln = f_rrformat (yln, l_pgsize)
         @ yln, 03 + len (l_tdesc [j]) say str (l_gc [j], 10) +  [ <rec>]
         yln = f_rrformat (yln, l_pgsize)
         @ yln, 03 + len (l_tdesc [j]) say str ((l_gt [j] / l_gc [j]), l_sumlen [j], l_sumdec [j]) + [ <avg>]
         *if l_gc [j] <> l_reccount      && 08/18/94 edc
            yln = f_rrformat (yln, l_pgsize)
            @ yln, 03 + len (l_tdesc [j]) say str ((l_gc [j] / l_reccount) * 100, l_sumlen [j], l_sumdec [j]) + [%]
         *endif
      else
         yfld = l_sumfld [j]
         l_total [j] = &yfld
         @ yln, 02 say l_tdesc [j] + [ ] + str(l_total [j],10,2)
         * @ yln, 02 say l_tdesc [j] + [ ] + &yfld
      endif
   next
endif

if l_foutopt = "P"
   if l_formlen > 80
      @ yln + 1, 0 say l_nprt
   endif
   eject
endif

set printer to
set print off
set console on
set device to screen

select sortdb
use
f_popback ()
return (0)


******************************
function f_rrformat

parameters xln, xpgsize
private i, yln, ylen, ycol, ydesc
if xln > xpgsize
   if l_foutopt = "P"
      if xln <> 99
         eject
      else
         setprc (0, 0)
         if l_formlen > 80
            @ 00, 01 say l_cprt
         endif
      endif
   elseif xln <> 99
      @ xln + 1, 0 say ""
      setprc (0, 0)
      @ 0, 0 say replicate ("Ä", l_formlen-1)
   else
      setprc (0, 0)       && 10/22/93(edc): fix strange symbol during display
   endif
   l_page = l_page + 1
   @ 01, 01 say 'DATE: ' + l_date
   @ 01, yc1 say gtitle
   @ 01, yc3 say 'PAGE: ' + str (l_page, 3)
   @ 02, 01 say 'TIME: ' + l_time
   @ 02, yc2 say l_ftitle
   @ 03, 01 say yheader
   if l_fdisp <> "S"
      yln = 4
      for i = 1 to l_nofld
         ycol = l_rcol [i]
         ydesc = l_stitle [i]
         @ yln, ycol say ydesc
      next
      yln = 5
      for i = 1 to l_nofld
         ycol = l_rcol [i]
         ylen = l_rlen [i]
         @ yln, ycol say replicate ("-", ylen)
      next
      yln = 7
   else
      yln = 5
   endif
   ynewpage = .t.
else
   yln = xln + 1
   ynewpage = .f.
endif
return (yln)

