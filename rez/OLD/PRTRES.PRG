*
* printing routine for budget reservation retrival system
*
set delete on
set excl off
lresrpt = "f:\res\dbf\resrpt.dbf"
if .not. file(lresrpt)
   quit
endif
select 1
use &lresrpt

dispmess ("Please wait while creating report...", .f., .f.)
x = 0
set printer to prnfile.txt
set device to print
set print on
set console off
xrptname = "BUDGET RESERVATION ACTIVITY REPORT"
xdate = dtoc(date())
go top
do while .not. eof ()
   if x > 45
      x = 0
      ? chr (12)
   endif
   if x = 0
      ? space (40 - int (len (xrptname) / 2)) + xrptname
      ? space (38) + xdate
      ? replicate ("Ä", 78)
   endif
   x = x + 1
   ? FIELD
   rlock ()
   delete
   skip
enddo
? 
eject
set device to screen
set print off
set printer to
dispmess ("Please wait while printing report...", .f., .f.)
set console off
type prnfile.txt to print
set console on
dispmess ("Report is printed. Press any key to continue", .t., .f.)
close all
return


function dispmess

parameter xmess, xans, xbell
private yans, ycursor

ycursor = iscursor ()
xmess = alltrim (xmess)
@ 24, 00
@ 24, 01 say xmess
if xbell
   tone (500, 9)
endif
if xans
   set cursor on
   yans = inkey (0)
   if .not. ycursor
      set cursor off
   endif
   @ 24, 00
   return yans
else
   return .f.
endif

