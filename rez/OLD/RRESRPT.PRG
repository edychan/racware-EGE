*
*  Reservation Retrieval System - Report Module
*
private ylst, ylim, lmonth, ltransit, yfnd
private xdiv

f_clrscn ("Reservation Retrievel System - Report Module")

ltransit = gdbfpath+"transit"
select 52
use &ltransit excl alias transit
go top

if eof ()
   f_popup ("No New Reservation Notice...", .t.)
   close all
   return
endif

ylst = f_confirm ("[P]rint    [B]rowse    [R]eturn","BPR") 
if ylst = "P"
   ylim=50
elseif ylst = "B"
   f_dbedit ()
   close all 
   return
else 
   close all
   return
endif

xdiv=replicate(chr(196),77)
yfnd = .f.

* locate 1st res
do while .not. eof()
   lline = alltrim(upper(transit->field))
   if substr(lline,1,3) <> "CF "
      skip
      loop
   else 
      yfnd = .t.
      exit
   endif
enddo

if .not. yfnd
   f_popup ("No New Reservation Notice...", .t.)
   select transit
   use
   return
endif

if ylst='P'
  f_popup ("Please Wait While Printing...")
  set device to print
  ln=1
else
  clear
  ln=0
endif

do while .not. eof ()
   lline = alltrim(upper(transit->field))
   if substr (lline,1,3) $ "CF ;CR ;DT ;TI ;FI ;NM ;TA ;RR ;RT ;"
   else
      skip
      loop
   endif
   if substr(lline,1,3) = "CF "
      @ ln,01 say xdiv
      ln = ln + 1
   endif
   if ln > ylim
      if ylst='P'
        eject
        ln=1
      else
        if inkey(0) = 27
          exit
        else
          clear
          ln=0
        endif
      endif
   endif

   @ ln, 01 say lline
   ln=ln+1

   select transit
   skip
enddo        

if ylst='P'
  eject
  set device to screen
endif

f_popup ("Press any key to continue ...",.t.)

close all
return

******************************
function f_dbedit

parameters xdbfld, xdbcol, xeditno, xdelete, xdbvalid, xdbpict
private i, yusrdef, yvalid, ypict
if empty (fieldname(1))
   return .f.
endif

yvalid = (pcount () < 5)
ypict = (pcount () < 6)

if pcount () < 3
   xeditno = 0
endif

if pcount () < 4
   xdelete = .t.
endif

setcolor (gredcolor)
if xdelete
   @ 24, 02 say "F2" + space (16) + "F3" + space (18) + "F4" ;
      + space (18) + "F5"
   @ 24, 05 say "Edit Record"
   @ 24, 23 say "Insert Record"
   @ 24, 43 say "Delete Record"
   @ 24, 63 say "Recall Record"
else
   @ 24, 02 say "F2"
   @ 24, 05 say "Edit Record"
endif

setcolor (gbluecolor)
@ 03, 00 clear to 03, 79
@ 03, 45 say "Record: " + ltrim (str (recno ())) + "/" ;
   + ltrim (str (reccount ()))

if pcount() < 2
   declare field_list[fcount()]
   for i = 1 to fcount()
      field_list[i] = fieldname(i)
   next
   yusrdef = .f.

   blimempak (-1)
   dbedit (4, 0, 22, 79, field_list, "dbfunc")
else
   yusrdef = .t.
   blimempak (-1)
   dbedit (4, 0, 22, 79, &xdbfld, "dbfunc", 0, &xdbcol)
endif
blimempak (-1)
return .t.


******************************
function dbfunc

parameters xmode, xfield_no
private ychanged, yvldstr

ychanged = .f.
do case
case xmode = 0
   ret_cd = 1

   @ 23, 00
   if ychanged
      ret_cd = 2
      ychanged = .f.
   endif

   @ 03, 53 say ltrim (str (recno ())) + "/" + ltrim (str (reccount ()))
   if deleted ()
      setcolor (if (gmucolor, "*"+ltrim(gbluecolor), "*W/N"))
      ?? " - * DELETED *" + space (5)
      setcolor (gbluecolor)
   else
      ?? space (20)
   endif

   return (ret_cd)

case xmode < 4
   return (1)

case lastkey () = 27
   return (0)

case lastkey () = -2
   if xdelete
      append blank
      commit
      go reccount ()
      keyboard chr (31) + chr (29)
      return (1)
   else
      return (1)
   endif

case lastkey () = -3
   if  xdelete
      reclock ()
      delete
      commit
      unlock
      @ 03, 53 say ltrim (str (recno ())) + "/" + ltrim (str (reccount ()))
      setcolor (if (gmucolor, "*"+ltrim(gbluecolor), "*W/N"))
      ?? " - * DELETED *" + space (5)
      setcolor (gbluecolor)
      return (2)
   else
      return (1)
   endif

case lastkey () = -4
   if xdelete
      reclock ()
      recall
      commit
      unlock
      @ 03, 53 say ltrim (str (recno ())) + "/" + ltrim (str (reccount ()))
      ?? space (20)
      return (2)
   else
      return (1)
   endif

case lastkey () = -1 .or. (lastkey () >= 32 .and. lastkey () <= 127)
   if .not. yusrdef .or. xfield_no >= xeditno
      reclock ()
      if lastkey () <> -1
         keyboard chr (lastkey ())
      endif
      set cursor on
      if yusrdef
         cur_field = &xdbfld [xfield_no]
      else
         cur_field = field (xfield_no)
      endif
      if yvalid
         if ypict
            @ row (), col () get &cur_field
         else
            @ row (), col () get &cur_field pict &xdbpict [xfield_no]
         endif
      else
         yvldstr = &xdbvalid [xfield_no]
         if ypict
            @ row (), col () get &cur_field valid &yvldstr
         else
            @ row (), col () get &cur_field pict &xdbpict [xfield_no] ;
               valid &yvldstr
         endif
      endif
      read
      set cursor off
      ychanged = updated ()
      commit
      unlock
      keyboard chr (4)
      return (2)
   else
      return (1)
   endif
endcase

return (1)


