* ===========================================================================
* rate table maint.
*
* date: 05/01/91
* author: KST
*
* revision
* date: 12/21/93
* edc: allow to change the effective to date.
* 10.21.99
* set century on
* ===========================================================================
parameters xupd
private xrow, xcdw

set century on   && 10.21.99
f_clrscn ("Rate Table Maintenance")
setcolor (gbluecolor)
restore from (gmempath + "rartm") additive
f_use ("RALOC")
seek gloc
l_fcdwchg = fcdwamt
f_use ("RARTM")

l_floc = space (10)
l_fcode = space (6)
l_fclass = space (4)
store ctod (space (8)) to l_fdatefrom, l_fdateto

ycnt = 1
do while .t.
   if xupd = "U"
      setcolor (gredcolor)
      @ 24, 00
      @ 24, 01 say "Press F1 For To Pick Rate"
   endif
   setcolor (gbluecolor)
   @ ycnt, 1 say "Rate          LOC               Class    " + ;
      "  Effective             -"
   @ ycnt + 1, 13 say "Daily    Weekend    Weekly   Monthly  Late Chg" + ;
      "   Mile Chg  Wknd Day"
   @ ycnt + 2, 1 say "Charge   " + space(62) + "Min"
   @ ycnt + 3, 1 say "Free Mile" + space(62) + "Max"
   @ ycnt + 4, 1 say "Reg. CDW :          CDW1:       Limit1:       CDW2:        Limit2:"
   @ ycnt + 5, 1 say "Remark:"
   @ ycnt + 6, 1 say "Res Limit:         Oversell:     %  Booked:"
   if xupd = "U"
      set key 28 to rsysssrh
   endif

   @ ycnt, 6 get l_fcode picture "!!!!!!" valid f_valid (.not. empty (l_fcode))
   @ ycnt, 20 get l_floc picture "!!!!!!!!!!" ;
      valid f_valid (empty (l_floc) .or. f_verify ("RALOC", 1, l_floc))
   @ ycnt, 39 get l_fclass picture "!!!!" valid f_valid (.not. empty (l_fclass))
   @ ycnt, 54 get l_fdatefrom valid f_y2k (@l_fdatefrom)
   if f_rd () = 27
      set key 28 to
      exit
   endif
   set key 28 to
   if upper (l_floc) = "ALL"
      l_floc = space (10)
   endif

   select rartm
   seek l_fcode + l_floc + l_fclass + dtos (l_fdatefrom)
   if xupd = "U"
      if f_valid (found (), "Rate Not Found!!!")
         f_retrieve ()
      else
         loop
      endif
      @ ycnt, 54 get l_fdatefrom
      clear gets
   else
      if .not. f_valid (.not. found (), "Rate Already Exists!!!")
         loop
      endif
   endif

   do while .t.
      @ ycnt, 69 get l_fdateto ;
         valid f_valid (f_y2k (@l_fdateto) .and. ;
                       (l_fdateto >= l_fdatefrom .or. empty (l_fdateto)))
      @ ycnt + 2, 13 get l_fdlychg picture "9999.99"
      @ ycnt + 3, 15 get l_fdlymlg picture "9999"
      @ ycnt + 2, 22 get l_fwkdchg picture "9999.99"
      @ ycnt + 3, 24 get l_fwkdmlg picture "9999"
      @ ycnt + 2, 32 get l_fwkchg picture "9999.99"
      @ ycnt + 3, 34 get l_fwkmlg picture "9999"
      @ ycnt + 2, 42 get l_fmthchg picture "9999.99"
      @ ycnt + 3, 44 get l_fmthmlg picture "9999"
      @ ycnt + 2, 52 get l_fhrchg picture "9999.99"
      @ ycnt + 2, 63 get l_fmlgchg picture "99.99"
      @ ycnt + 2, 76 get l_fwkdmin pict "99"
      @ ycnt + 3, 76 get l_fwkdmax pict "99"
      @ ycnt + 4, 13 get l_fcdwchg picture "99.99"
      @ ycnt + 4, 26 get l_fcdwded picture "99.99"
      @ ycnt + 4, 40 get l_fdedamt picture "9999"
      @ ycnt + 4, 52 get l_fcdwded2 pict "99.99"
      @ ycnt + 4, 67 get l_fdedamt2 pict "9999"
      @ ycnt + 5, 13 get l_fremark
      @ ycnt + 6, 13 get l_fresvok picture "99999"
      @ ycnt + 6, 30 get l_fresvovr picture "999"
      @ ycnt + 6, 44 get l_fresvcnt picture "9999"

      f_rd ()
      if xupd = "A"
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
      if ycnt < 17
         ycnt = ycnt + 8
      else
         scroll (1, 0, 23, 79, 8)
      endif
   endif
   if ycnt > 1
      @ ycnt - 1, 1 say replicate (chr (196), 78)
   endif
enddo
set century off
set key 28 to
close databases


******************************
procedure rsysssrh

select rartm
go top
if .not. eof ()
   set softseek on
   seek l_fcode + l_floc + l_fclass + dtos (l_fdatefrom)
   if eof ()
      go bottom
   endif
   set softseek off
   if f_pick_f (ycnt + 1, 9, "", "Rate   Location   Clas   From      To", ;
         "FCODE + [ ] + IF (EMPTY (FLOC), " + ;
         "[ALL       ], FLOC) + [ ] + FCLASS + [ ] + DTOC (FDATEFROM) + " + ;
         "[ ] + DTOC (FDATETO)")
      setcolor ("N/W")
      l_fcode = rartm->fcode
      l_floc = rartm->floc
      l_fclass = rartm->fclass
      l_fdatefrom = fdatefrom
      l_fdateto = fdateto
      @ ycnt, 6 say l_fcode
      @ ycnt, 20 say l_floc
      @ ycnt, 39 say l_fclass
      @ ycnt, 54 say l_fdatefrom
      @ ycnt, 69 say l_fdateto
      setcolor (gbluecolor)

      keyboard chr (3)
   endif
endif

