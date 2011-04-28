* ===========================================================================
* setup location file
*
* date: 05/01/91
* author: EDC
*
* revision
* date: 09/14/92
* edc: update gckintme
*
* 04/21/93
* edc: add foreign location
*
* ===========================================================================
do while .t.
   xret3 = f_pushmenu (xoption2)
   if xret3 = 0
      exit
   endif
   xoption3 = substr (goption [xret3], 4)
   f_clrscn ("LOCATION FILE MAINTENANCE")
   rest from (gmempath+"raloc") additive
   do case
   case xret3 = 1
      set key 28 to rsyssslh
      f_use ("raloc")
      do while .t.
         @ 02, 02 say "Location " get l_floc picture "!!!!!!!!!!"
         if f_rd() = 27
            exit
         endif
         set exact on
         seek l_floc
         set exact off
         if eof()
            f_add ("raloc", "raloc", "rsysssl1")
            use
            exit
         else
            tone (500, 9)
            f_popup ("Duplicate Location #. Press Any Key to Retry ...",.t.)
         endif
      enddo
      set key 28 to
   case xret3 = 2
      set key 28 to rsyssslh
      f_use ("raloc")
      if .not. eof()
         seek gloc
         if .not. found ()
            go top
         endif
         if f_pick_f (02, 03, "", "Location컴횮ity컴컴컴컴컴컴컴컴횮ontact ", ;
               "floc+[ ]+fcity+[ ]+fcontact")
            f_update ("raloc", "raloc", "", "rsyssslf", "rsysssl2")
            if floc = gloc
               gmaxage = fmaxage
               gminage = fminage
               ggracehr = fgracehr
               ggracefr = ffreehr
               gfuelchg = ffuelchg
               gfueltax = ffueltax
               gtaxrate = ftaxrate
               grafrmno = frafrmno
               gsurchg = fsurchg
               gsurtx = fsurtx
               gwkmin = fwkmin
               gwkmax = fwkmax
               gmthmin = fmthmin
               gmthmax = fmthmax
               grate = frack
               glocname = alltrim (fname)
               gcalday = fcalday            && edc: 09/14/92
               gckintme = fckintme          && edc: 09/14/92
               garpost = farpost
               gglpost = fglpost
               gaccpath = alltrim (fapath)
               gfileno = ffileno
            endif
            use
         endif
      else
         tone (500, 9)
         f_popup ("File is Empty. Press Any Key to Continue...",.t.)
      endif
      set key 28 to
   case xret3 = 3
      f_clrscn ("LOCATION GROUP MAINTENANCE")
      f_use ("ralocgp")
      * 04/21/93: (edc) add foreign location
      declare l_dbfld[2], l_dbcol[2], l_valid [2], l_pict[2]
      l_dbfld[1]="fgroup"
      l_dbcol[1]="Group Name"
      l_valid[1]=".t."
      l_pict[1]="!!!!!!!!!!"
      l_dbfld[2]="fforeign"
      l_dbcol[2]="Foreign [Y/N]"
      l_valid[2]=".t."
      l_pict[2]="Y"
      f_edit (l_dbfld, l_dbcol, 0, .t., l_valid, l_pict)
      use
   endcase
enddo
release all like l_*
close database


******************************
procedure rsyssslf

l_fmoddate = date ()

* 04/21/93: (edc) add foreign location
if .not. empty(l_flocgp)
   f_use ("ralocgp")
   set filter to fgroup = l_flocgp
   go top
   if .not. eof()
      l_fforeign = fforeign
   endif
endif 

******************************
procedure rsyssslh

private yvar

yvar = alltrim (upper(readvar()))
do case
case yvar = "L_FLOCGP"
   f_use ("ralocgp")
   go top
   if f_valid (.not. eof (), "No Location Group Set Up Yet!!!")
      if f_pick_f (05, 32,"","",	"fgroup")
         l_flocgp = fgroup
         l_fforeign = fforeign
         keyboard chr (13)
      endif
   endif
   select ralocgp
   use
case yvar $ "L_FMINAGE;L_FMAXAGE;L_FLIMAGE;"
   f_popup ("Lower age allowed to drive and Age Range without warning.", .f.)
otherwise
   tone (500,9)
   f_popup ("No Help information for this Field. Press Any Key to Continue...",.t.)
endcase
set cursor on


******************************
procedure rsysssl1

if empty (gusrlocgp) .or. empty (l_flocgp) .or. ;
      gusrlocgp = l_flocgp
   gusrloc = gusrloc + l_floc + ";"
endif

* 04/21/93: (edc) add foreign location
if .not. empty(l_flocgp)
   f_use ("ralocgp")
   set filter to fgroup = l_flocgp
   go top
   if .not. eof()
      l_fforeign = fforeign
   endif
endif 



******************************
procedure rsysssl2

gusrloc = strtran (gusrloc, l_floc + ";", "")
reclock ()
delete
commit
unlock

