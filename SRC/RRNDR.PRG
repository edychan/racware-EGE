* -------------------------------------------------
* display rate table
*
* y2k: set century off
* -------------------------------------------------
* 11.25.09: set new filter  
* 12.28.09: implement block rate
* -------------------------------------------------
parameter xparam
xparam = (pcount () >= 1)
private yarray [3], yret, ykey, yfullscn, ycolor
private yord, yrecno, yfilter, ysel, yidx
private yrtloc, yrtcode, yrtclass, yrtstr

blimempak (-1)
save screen to yfullscn
f_clrscn ("Display Rate Table")
ycolor = setcolor (gsubcolor)
ysel = select ()

set century off

f_use ("RARTM")
yfilter = dbfilter ()
yord = indexord ()
yrecno = recno ()
set filter to

* 12.28.09:
yrtcode = "VALUE "
yrtclass = space(4)
yrtloc = gloc
yrtstr = ""

do while .t.
   go top
   if .not. eof()
      yarray[1] = " Rate Code ....."
      yarray[2] = " Class ........."
      yarray[3] = " Location ......"
      yret = f_pick_a (02, 05, "", "", yarray, 3, 1)
      if yret = 0
         exit
      endif
      f_box (2, 1, 4, 50)
      @ 03, 02 say yarray [yret]
      do case
      case yret = 1
         if .not. f_getfld (@yrtcode, 3, 20, "", 6, replicate ([!], 6))
            loop
         endif
      case yret = 2
         if .not. f_getfld (@yrtclass, 3, 20, "", 4, replicate ([!], 4))
            loop
         endif
      case yret = 3
         if .not. f_getfld (@yrtloc, 3, 20, "", 10, replicate ([!], 10))
            loop
         endif
      endcase

      * --12.28.09: implement block rate
      f_use ("rartml")
      seek yrtloc+yrtcode
      do while .not. eof () .and. rartml->floc=yrtloc .and. rartml->fcode=yrtcode 
         if check_block (date())
            yrtstr = yrtstr + rartml->fclass + [;]
         endif
         skip
      enddo
      select rartml
      use
      * --

      select rartm
      do case
      case yret = 1
         set filter to fcode = yrtcode .and. fdatefrom = date() ;
            .and. .not. (fclass $ yrtstr)
         go top
      case yret = 2
         set filter to fclass = yrtclass .and. fdatefrom = date() ;
            .and. .not. (fclass $ yrtstr)
         go top
      case yret = 3
         set filter to floc = yrtloc .and. fdatefrom = date() ;
            .and. .not. (fclass $ yrtstr)
         go top
      endcase
      if eof()
         tone (500, 9)
         f_popup ("No Matching Record. Press Any Key to Retry ...",.t.)
         loop
      else
         yidx = 1
         do while .t.
            if yidx = 1            
               f_pick_f (02, 01, "", "ÄRateÄÄÄLocationÄÄÄClassÄÄFromÄÄÄ" ;
                     + "ÄÄÄToÄÄÄÄÄDailyÄÄÄÄWeeklyÄÄÄX'dayÄ", ;
                     "fcode+[ ]+if(empty(floc),[ALL       ],floc)+[ ]+" + ;
                     "fclass+[ ]+dtoc(fdatefrom)+[ ]+dtoc(fdateto)+[ ]+" + ;
                     "str(fdlychg,8,2)+[ ]+str(fwkchg,8,2)+[ ]+str(fxdlychg,8,2)", + ;
                     "rrndrd")
            elseif yidx = 2
               f_pick_f (02, 01, "", "RateÄÄÄLocationÄÄÄClassÄÄFromÄÄÄÄÄÄ" + ;
                     "ToÄÄÄÄDyMlÄWdMlÄWkMlÄMoMlÄÄHr Chg", ;
                     "fcode+[ ]+if(empty(floc),[ALL       ],floc)+[ ]+" + ;
                     "fclass+[ ]+dtoc(fdatefrom)+[ ]+dtoc(fdateto)+[ ]+" + ;
                     "str(fdlymlg,5)+str(fwkdmlg,5)+str(fwkmlg,5)+" + ;
                     "str(fmthmlg,5)+str(fhrchg,8,2)", "rrndrd")
            elseif yidx = 3
               f_pick_f (02, 01, "", "RateÄÄÄLocationÄÄÄClassÄÄFromÄÄÄÄÄÄ" + ;
                     "ToÄÄÄÄRemark", ;
                     "fcode+[ ]+if(empty(floc),[ALL       ],floc)+[ ]+" + ;
                     "fclass+[ ]+dtoc(fdatefrom)+[ ]+dtoc(fdateto)+[ ]+" + ;
                     "left(fremark,30)", "rrndrd")
            endif
            ykey = lastkey ()
            if ykey = 27
               exit
            endif
            if ykey = 4
               if yidx < 3
                  yidx = yidx + 1
               endif
            elseif ykey = 19
               if yidx > 1
                  yidx = yidx - 1
               endif
            endif
         enddo
      endif
   else
      tone (500, 9)
      f_popup ("File is empty. Press Any Key to Continue...",.t.)
      exit
   endif
enddo

if empty (yfilter)
   set filter to
else
   set filter to &yfilter
endif
if yord > 0
   set order to yord
endif
go (yrecno)
rest screen from yfullscn
setcolor (ycolor)
select (ysel)
set century on

**************************************
procedure rrndrd

private ycolor, yscn

ycolor = setcolor (gsubcolor)
yscn = f_box (02, 44, 16, 77)
@ 03, 46 say "Rate"
@ 04, 46 say "Location"
@ 05, 46 say "Class"
@ 06, 46 say "From"
@ 07, 46 say "To"
@ 08, 46 say "Daily                    Miles"
* @ 09, 46 say "ExtraDay                 Miles"
@ 09, 46 say "ExtraDay                      "
@ 10, 46 say "Weekly                   Miles"
* @ 11, 46 say "Monthly                  Miles"
@ 12, 46 say "Late Chg          /Hour"
@ 13, 46 say "Mile Chg          /Mile"
@ 15, 46 say "Press any key to continue"
setcolor (gsubget)
@ 03, 56 say fcode
@ 04, 56 say floc
@ 05, 56 say fclass
@ 06, 56 say fdatefrom
@ 07, 56 say fdateto
@ 08, 56 say fdlychg pict "99999.99"
@ 08, 65 say fdlymlg pict "99999"
@ 09, 56 say fxdlychg pict "99999.99"
* @ 09, 65 say fwkdmlg pict "99999"
@ 10, 56 say fwkchg pict "99999.99"
@ 10, 65 say fwkmlg pict "99999"
*@ 11, 56 say fmthchg pict "99999.99"
*@ 11, 65 say fmthmlg pict "99999"
@ 12, 56 say fhrchg pict "99999.99"
@ 13, 56 say fmlgchg pict "99999.99"
f_getkey ()
setcolor (ycolor)
f_restbox (yscn)
