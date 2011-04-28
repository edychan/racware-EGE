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

