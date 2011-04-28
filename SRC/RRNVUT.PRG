* ===========================================================================
* Transfer Vehicle
*
* 05.05.09: New link btw EGE & JAC
*     1. Check Vehicle Loc
*     2. Sync VM tables (gsynpath)
*     3. Do not update VM revenue sub totals such as T&M, CDW, ...
* 
* ===========================================================================
f_clrscn ("Transfer Vehicle")

private xkey, yrow, yunit, ydate, ystr, ymiles, yloc, ystall
private yfil, yntx1, yntx2, yntx3

* -- open tables
f_use ("raagrx")
f_use ("RAVM", 1)

* -- 05.05.09
if .not.empty(gsynpath)
   yfil = gsynpath + "ravm.dbf"
   if file(yfil)     && make sure the file is accessable...
      yntx1 = gsynpath + "ravm1"
      yntx2 = gsynpath + "ravm2"
      yntx3 = gsynpath + "ravm3"
      select 0
      use &yfil index &yntx1, &yntx2, &yntx3 alias vmtbl
   else
      gsynpath = ""
   endif
endif
* --

setcolor (gbluecolor)
@ 01, 01 say "Unit No.   Description                        Date     " + ;
   "Location   Miles  Stall"
@ 02, 01 say "컴컴컴컴컴 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 컴컴컴컴 " + ;
   "컴컴컴컴컴 컴컴컴 컴컴�"
yrow = 3
yunit = space (10)
set key 28 to rrnvuf1
do while .t.
   @ yrow, 1 get yunit picture "!!!!!!!!!!"
   if f_rd () = 27
      exit
   endif
   select ravm
   seek yunit
   if .not. f_valid (found (), "Unit Number Not Found...")
      loop
   elseif ravm->floc <> gloc
      f_valid (.f., "Please Select from "+trim(gloc)+" Inventory...")
      loop
   endif
   ystr = ltrim (fyear + " " + fcolor + " " + fmake + " " + fmodel)
   do while "  " $ ystr
      ystr = strtran (ystr, "  ", " ")
   enddo
   @ yrow, 12 say f_truncate (ystr, 34)
   @ yrow + 1, 12 say flic
   @ yrow, 56 say floc
   @ yrow, 67 say fmileage pict "999999"
   @ yrow, 75 say fstall
   ydate = date ()
   yloc = floc
   ymiles = fmileage
   ystall = fstall
   do while .t.
      @ yrow + 1, 47 get ydate
      @ yrow + 1, 56 get yloc pict "!!!!!!!!!!" ;
         valid f_valid (yloc $ gusrloc .and. yloc <> gloc, "Cannot Transfer to "+trim(yloc))
      @ yrow + 1, 67 get ymiles pict "999999" ;
         valid f_valid (ymiles >= fmileage)
      @ yrow + 1, 75 get ystall pict "!!!!"
      f_rd ()
      xkey = f_confirm ("[C]onfirm  [E]dit  [I]gnore Changes", "CEI")
      do case
      case xkey = "C"
         if yloc <> ravm->floc .or. ymiles <> ravm->fmileage
            select raagrx
            append blank
            reclock ()
            replace fdatein with ydate, fdateout with  ydate
            replace fexchg with .f., flname with "TRANSFER: " + gusrid
            replace floc with ravm->floc, fmlgin with ravm->fmileage
            replace fmlgout with ymiles, fulic with ravm->flic
            replace funit with ravm->funit, ffname with "VEH TRANS"
            commit
            unlock
            f_fupdate ("A")
         endif

         * -- 05.05.09: syn VM data 
         if .not.empty(gsynpath)
            select vmtbl
            seek yunit
            if eof ()
               append blank
               replace funit with yunit
            endif
            reclock ()

            replace floc with yloc, fmileage with ymiles, fstall with ystall
            replace futime with dtos (date ()) + time ()
            replace fstatus with "H", freason with "T"

            replace fclass with ravm->fclass, fcolor with ravm->fcolor, fdesc with ravm->fdesc
            replace fvin with ravm->fvin, fyear with ravm->fyear, fmake with ravm->fmake  
            replace fmodel with ravm->fmodel, flic with ravm->flic, flicst with ravm->flicst
            replace figkey with ravm->figkey, ftrkey with ravm->ftrkey
            replace ftank with ravm->ftank, fepa with ravm->fepa

            replace foloc with ravm->foloc, fpuramt with ravm->fpuramt, fpurdt with ravm->fpurdt
            replace floan with ravm->floan, fdeprrt with ravm->fdeprrt

            replace fregdt with ravm->fregdt, fduedt with ravm->fduedt
            replace fdtcap with ravm->fdtcap, fmlgcap with ravm->fmlgcap
            replace fdmg1 with ravm->fdmg1, fdmg2 with ravm->fdmg2, fdmg3 with ravm->fdmg3
            replace FBONUS with ravm->fbonus, FBY with ravm->fby
            replace fcode1 with ravm->fcode1, fcode2 with ravm->fcode2, fcode3 with ravm->fcode3, fcode4 with ravm->fcode4, fcode5 with ravm->fcode5
            replace fdue1 with ravm->fdue1, fdue2 with ravm->fdue2, fdue3 with ravm->fdue3, fdue4 with ravm->fdue4, fdue5 with ravm->fdue5
            replace fpaid1 with ravm->fpaid1, fpaid2 with ravm->fpaid2, fpaid3 with ravm->fpaid3, fpaid4 with ravm->fpaid4, fpaid5 with ravm->fpaid5

            commit
            unlock
         endif

         select ravm
         f_fupdate ("C")
         reclock ()
         replace floc with yloc, fmileage with ymiles, fstall with ystall
         replace futime with dtos (date ()) + time ()
         * 05.01.09
         replace fstatus with "H", freason with "T"
         commit
         unlock

         exit
      case xkey = "E"
         loop
      case xkey = "I"
         exit
      endcase
   enddo
   if xkey <> "I"
      if yrow < 21
         yrow = yrow + 2
      else
         scroll (3, 0, 23, 79, 2)
      endif
   else
      @ yrow, 12 clear to yrow + 1, 79
   endif
   yunit = space (10)
enddo

set key 28 to
close database

