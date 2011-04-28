* ===========================================================================
* rental module 
*
* date: 05/01/91
* author: KST
*
* revision
* date: 12/4/93
* edc: take out resv grid table <F6>
* 05.13.98
* edc: add remote handheld module (rrnpkra)
* ----------------------------------------------------
* 10.15.08: add add'l charge 5 & 6 (rrnoaget2)
* ===========================================================================

do while .t.
   xret1 = f_pushmenu (xoption0)
   if xret1 = 0
      exit
   else
      xoption1 = substr (goption [xret1], 4)
      set key -3 to rrnds
      set key -4 to rrndr
      * set key -5 to f_resvgrid
      do case
      case xret1 = 1
         do rrnoa
      case xret1 = 2
         do rrnfm
      case xret1 = 3
         do rrnca
      case xret1 = 4
         do rrnsc
      case xret1 = 5      && enter manual contract
         do rrnec
      case xret1 = 6      && display rate table
         do rrndr with .t.
      case xret1 = 7
         do rrnvu
      case xret1 = 8
         do rrnds with .t.
      case xret1 = 9
         do rrnrmt        && remote handheld module
      endcase
      close databases
      set key -3 to
      set key -4 to
      set key -5 to
   endif
enddo


******************************
function rrnpkra

parameters xstat

declare yarray [5]
if xstat = "O"
   f_use ("RAAGR")
   set filter to .not. empty (floc) .and. frano <> 0 
else
   f_use ("RAAGRH")
endif
go top
if eof ()
   if xstat = "O"
      f_popup ("No Open Contract File Found!!! Press Any Key to Continue...", .t.)
   else
      f_popup ("No Closed Contract File Found!!! Press Any Key to Continue...", .t.)
   endif

   use
   return .f.
endif
yarray [1] = " Contract Number .... "
yarray [2] = " Last Name .......... "
if xstat = "O"
   yarray [3] = " Unit Number ........ "
   yarray [4] = " Reference Number ... "
   yarray [5] = " Stamp RA Number .... "
else
   yarray [3] = " Reference Number ... "
endif
yptr = f_pick_a (02, 05, "", "", YARRAY, if (xstat = "O", 5, 3), 1)
if yptr = 0
   use
   return .f.
endif

ycolor = setcolor (gsubcolor)
yscn = f_box (2, 21, 4, 62)
do case
case yptr = 1
   ykey = "l_floc + str (l_frano, 6)"
   ytitle = "Contract No.컴컴컴Renter"
   yexp = "f_truncate (trim (floc) + [-] + ltrim (str (frano, 6)), 18) + " ;
      + "f_truncate (trim (ffname) + [ ] + flname, 27)"
   l_floc = gloc
   @ 3, 23 say "Contract Number ...."
   @ 3, 44 get l_floc picture "!!!!!!!!!!"
   @ 3, 55 get l_frano picture "999999"
case yptr = 2
   ykey = "upper (l_flname)"
   ytitle = "Renter컴컴컴컴컴컴컴컴컴컴컴컴컴횮heck Out At"
   yexp = "f_truncate (trim (flname) + [, ] + ffname, 28) + " + ;
      "[ ] + floc + [ ] + dtoc (fdateout)"
   @ 3, 23 say "Last Name ............."
   @ 3, 47 get l_flname
case yptr = 3 .and. xstat = "O"
   ykey = "l_funit"
   ytitle = "Unit No.컴컴컴횮heck Out At"
   yexp = "funit + [ ] + floc + [ ] + dtoc (fdateout)"
   @ 3, 23 say "Unit Number ............."
   @ 3, 49 get l_funit picture "!!!!!!!!!!"
case yptr = 4 .or. (yptr = 3 .and. xstat = "C")
   ykey = "upper(l_frefno)"
   ytitle = "Refer No.컴Contract No.컴컴컴Renter"
   yexp = "frefno+[ ]+f_truncate (trim (floc) + [-] + ltrim (str (frano, 6)), 18) + " ;
      + "f_truncate (trim (ffname) + [ ] + flname, 27)"
   @ 3, 23 say "Reference Number ......"
   @ 3, 47 get l_frefno
case yptr = 5
   @ 3, 23 say "Stamp RA Number ........."
   @ 3, 49 get l_fstamp
endcase
if f_rd () = 27
   setcolor (ycolor)
   use
   return .f.
endif
f_restbox (yscn)
setcolor (ycolor)
if yptr <= 3
   set order to (yptr)
   set softseek on
   seek &ykey
   if eof ()
      go bottom
   endif
   set softseek off
   if found () .and. yptr <> 2
      if xstat = "O"
         if raagr->frastat <> "X"
            f_retrieve ()
            return .t.
         else
            f_valid (.f., "RA in Transit status...")
            use 
            return .f.
         endif
      else
         f_retrieve ()
         return .t.
      endif
   endif
elseif yptr = 4
   locate for trim (frefno) = trim (l_frefno)
   if found ()
      if xstat = "O"
         if raagr->frastat <> "X"
            f_retrieve ()
            return .t.
         else
            f_valid (.f., "RA in Transit status...")
            use 
            return .f.
         endif
      else
         f_retrieve ()
         return .t. 
      endif
   else
      use
      return .f.
   endif
else
   locate for alltrim (fstamp) = alltrim (l_fstamp)
   if found ()
      if xstat = "O"
         if raagr->frastat <> "X"
            f_retrieve ()
            return .t.
         else
            f_valid (.f., "RA in Transit status...")
            use 
            return .f.
         endif
      else
         f_retrieve ()
         return .t.
      endif
   else
      use
      return .f.
   endif
endif

if .not. f_pick_f (02, 77 - len (&yexp), "", ytitle, yexp)
   return .f.
endif
if xstat = "O"
   if raagr->frastat = "X"
      f_valid (.f., "RA in Transit status...")
      use 
      return .f.
   else
      f_retrieve ()
   endif
endif

return .t.

******************************
procedure rrnoaget2

private yscn, ycolor, yptr, yitem
ycolor = setcolor (gsubcolor)
* -- 10.15.08
yscn = f_box (13, 30, 21, 77)
@ 14, 32 say "Code Item Desc        Charge  Daily  Taxable"
setcolor (gsubget)
@ 15, 32 say l_foitem1
@ 15, 37 say yitem1
@ 15, 53 say l_forate1 picture "9999.99"
@ 15, 64 say l_fodly1 picture "Y"
@ 15, 72 say l_fotax1 picture "Y"
@ 16, 32 say l_foitem2
@ 16, 37 say yitem2
@ 16, 53 say l_forate2 picture "9999.99"
@ 16, 64 say l_fodly2 picture "Y"
@ 16, 72 say l_fotax2 picture "Y"
@ 17, 32 say l_foitem3
@ 17, 37 say yitem3
@ 17, 53 say l_forate3 picture "9999.99"
@ 17, 64 say l_fodly3 picture "Y"
@ 17, 72 say l_fotax3 picture "Y"
@ 18, 32 say l_foitem4
@ 18, 37 say yitem4
@ 18, 53 say l_forate4 picture "9999.99"
@ 18, 64 say l_fodly4 picture "Y"
@ 18, 72 say l_fotax4 picture "Y"

* -- 10.15.08
@ 19, 32 say l_foitem5
@ 19, 37 say yitem5
@ 19, 53 say l_forate5 picture "9999.99"
@ 19, 64 say l_fodly5 picture "Y"
@ 19, 72 say l_fotax5 picture "Y"
@ 20, 32 say l_foitem6
@ 20, 37 say yitem6
@ 20, 53 say l_forate6 picture "9999.99"
@ 20, 64 say l_fodly6 picture "Y"
@ 20, 72 say l_fotax6 picture "Y"
* --

yptr = 1
do while .t.
   do case
   case yptr = 1
      yitem = l_foitem1
      f_getfld (@l_foitem1, 15, 32, "", 0, replicate ("!", 4), .t., "rrnoagh")
      if empty (l_foitem1)
         yitem1 = space (15)
         l_forate1 = 0.00
         l_fodly1 = .f.
         l_fotax1 = .f.
         yptr = 25
      else
         if .not. f_valid (f_verify ("RAPAYCD", 1, upper (l_foitem1)))
            loop
         endif
         yitem1 = rapaycd->fitem
         if yitem <> l_foitem1
            l_forate1 = rapaycd->frate
            l_fodly1 = rapaycd->fdly
            l_fotax1 = rapaycd->ftax
         endif
      endif
      @ 15, 37 say yitem1
      @ 15, 53 say l_forate1 picture "9999.99"
      @ 15, 64 say l_fodly1 picture "Y"
      @ 15, 72 say l_fotax1 picture "Y"
   case yptr = 2
      f_getnum (@l_forate1, 15, 53, "", "9999.99", .t.)
   case yptr = 3
      f_getlgc (15, 64, @l_fodly1)
   case yptr = 4
      f_getlgc (15, 72, @l_fotax1)
   case yptr = 5
      yitem = l_foitem2
      f_getfld (@l_foitem2, 16, 32, "", 0, replicate ("!", 4), .t., "rrnoagh")
      if empty (l_foitem2)
         yitem2 = space (15)
         l_forate2 = 0.00
         l_fodly2 = .f.
         l_fotax2 = .f.
         yptr = 25
      else
         if .not. f_valid (f_verify ("RAPAYCD", 1, upper (l_foitem2)))
            loop
         endif
         yitem2 = rapaycd->fitem
         if yitem <> l_foitem2
            l_forate2 = rapaycd->frate
            l_fodly2 = rapaycd->fdly
            l_fotax2 = rapaycd->ftax
         endif
      endif
      @ 16, 37 say yitem2
      @ 16, 53 say l_forate2 picture "9999.99"
      @ 16, 64 say l_fodly2 picture "Y"
      @ 16, 72 say l_fotax2 picture "Y"
   case yptr = 6
      f_getnum (@l_forate2, 16, 53, "", "9999.99", .t.)
   case yptr = 7
      f_getlgc (16, 64, @l_fodly2)
   case yptr = 8
      f_getlgc (16, 72, @l_fotax2)
   case yptr = 9
      yitem = l_foitem3
      f_getfld (@l_foitem3, 17, 32, "", 0, replicate ("!", 4), .t., "rrnoagh")
      if empty (l_foitem3)
         yitem3 = space (15)
         l_forate3 = 0.00
         l_fodly3 = .f.
         l_fotax3 = .f.
         yptr = 25
      else
         if .not. f_valid (f_verify ("RAPAYCD", 1, upper (l_foitem3)))
            loop
         endif
         yitem3 = rapaycd->fitem
         if yitem <> l_foitem3
            l_forate3 = rapaycd->frate
            l_fodly3 = rapaycd->fdly
            l_fotax3 = rapaycd->ftax
         endif
      endif
      @ 17, 37 say yitem3
      @ 17, 53 say l_forate3 picture "9999.99"
      @ 17, 64 say l_fodly3 picture "Y"
      @ 17, 72 say l_fotax3 picture "Y"
   case yptr = 10
      f_getnum (@l_forate3, 17, 53, "", "9999.99", .t.)
   case yptr = 11
      f_getlgc (17, 64, @l_fodly3)
   case yptr = 12
      f_getlgc (17, 72, @l_fotax3)
   case yptr = 13
      yitem = l_foitem4
      f_getfld (@l_foitem4, 18, 32, "", 0, replicate ("!", 4), .t., "rrnoagh")
      if empty (l_foitem4)
         yitem4 = space (15)
         l_forate4 = 0.00
         l_fodly4 = .f.
         l_fotax4 = .f.
         yptr = 25
      else
         if .not. f_valid (f_verify ("RAPAYCD", 1, upper (l_foitem4)))
            loop
         endif
         yitem4 = rapaycd->fitem
         if yitem <> l_foitem4
            l_forate4 = rapaycd->frate
            l_fodly4 = rapaycd->fdly
            l_fotax4 = rapaycd->ftax
         endif
      endif
      @ 18, 37 say yitem4
      @ 18, 53 say l_forate4 picture "9999.99"
      @ 18, 64 say l_fodly4 picture "Y"
      @ 18, 72 say l_fotax4 picture "Y"
   case yptr = 14
      f_getnum (@l_forate4, 18, 53, "", "9999.99", .t.)
   case yptr = 15
      f_getlgc (18, 64, @l_fodly4)
   case yptr = 16
      f_getlgc (18, 72, @l_fotax4)

   * --10.15.08

   case yptr = 17
      yitem = l_foitem5
      f_getfld (@l_foitem5, 19, 32, "", 0, replicate ("!", 4), .t., "rrnoagh")
      if empty (l_foitem5)
         yitem5 = space (15)
         l_forate5 = 0.00
         l_fodly5 = .f.
         l_fotax5 = .f.
         yptr = 25
      else
         if .not. f_valid (f_verify ("RAPAYCD", 1, upper (l_foitem5)))
            loop
         endif
         yitem5 = rapaycd->fitem
         if yitem <> l_foitem5
            l_forate5 = rapaycd->frate
            l_fodly5 = rapaycd->fdly
            l_fotax5 = rapaycd->ftax
         endif
      endif
      @ 19, 37 say yitem5
      @ 19, 53 say l_forate5 picture "9999.99"
      @ 19, 64 say l_fodly5 picture "Y"
      @ 19, 72 say l_fotax5 picture "Y"
   case yptr = 18
      f_getnum (@l_forate5, 19, 53, "", "9999.99", .t.)
   case yptr = 19
      f_getlgc (19, 64, @l_fodly5)
   case yptr = 20
      f_getlgc (19, 72, @l_fotax5)

   case yptr = 21
      yitem = l_foitem6
      f_getfld (@l_foitem6, 20, 32, "", 0, replicate ("!", 4), .t., "rrnoagh")
      if empty (l_foitem6)
         yitem6 = space (15)
         l_forate6 = 0.00
         l_fodly6 = .f.
         l_fotax6 = .f.
         yptr = 25
      else
         if .not. f_valid (f_verify ("RAPAYCD", 1, upper (l_foitem6)))
            loop
         endif
         yitem6 = rapaycd->fitem
         if yitem <> l_foitem6
            l_forate6 = rapaycd->frate
            l_fodly6 = rapaycd->fdly
            l_fotax6 = rapaycd->ftax
         endif
      endif
      @ 20, 37 say yitem6
      @ 20, 53 say l_forate6 picture "9999.99"
      @ 20, 64 say l_fodly6 picture "Y"
      @ 20, 72 say l_fotax6 picture "Y"
   case yptr = 22
      f_getnum (@l_forate6, 20, 53, "", "9999.99", .t.)
   case yptr = 23
      f_getlgc (20, 64, @l_fodly6)
   case yptr = 24
      f_getlgc (20, 72, @l_fotax6)

   * --10.15.08

   endcase
   ykey = lastkey ()
   if (ykey = 24 .or. ykey = 13) .and. yptr < 24      && 10.15.08: yptr ++8
      yptr = yptr + 1
   elseif ykey = 5 .and. yptr > 1
      yptr = yptr - 1
   elseif ykey = 27 .or. ykey = 13 .or. ykey = 3 .or. ykey = 18 .or. yptr > 24      && 10.15.08: yptr ++8
      exit
   endif
enddo
f_restbox (yscn)
setcolor (ycolor)


******************************
procedure rrnoagh

f_use ("RAPAYCD")
go top
if .not. eof ()
   set softseek on
   seek upper (yfield)
   if eof ()
      go bottom
   endif
   set softseek off
   if f_pick_f (17, 37, "", "Code횯esc컴컴컴컴컴컴컴Rate", ;
         "fpaycd + [ ] + fitem + [ ] + str (frate, 7, 2)")
      ytmpfld = fpaycd
      keyboard chr (13)
   endif
endif

