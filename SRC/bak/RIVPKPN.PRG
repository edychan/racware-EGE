* ===========================================================================
* print ticket notification
*
*
* ===========================================================================

f_use ("raloc")
seek gloc
yname = fname
yaddr = faddr
ycity = fcity
ystate = fstate
yzip = fzip
use
f_use ("rapkg")
set filter to .not. fpaid
if eof ()
   f_valid (.f., "No Outstanding Parking Tickets")
   close databases
   return
endif
go top
set device to print
yfil = gstnpath + "rrout.rpt"
set printer to &yfil
set print on
set console off
xfirst = .t.
do while .not. eof ()
   if xfirst
      ? chr (18)
      xfirst = .f.
   else
      ? chr (12)
   endif
   ? "Run Date " + dtoc (date ()) + "           Office of The Parking Clerk"
   ? "Run Time " + time () + "           Lessee Identification Form"
   ?
   ? "Lessor:  " + yname
   ? "         " + yaddr
   ? "         " + ycity
   ? "         " + ystate + " " + yzip
   ?
   ?
   ? "Vehicle Licence Number .................. " + flic
   ? "Violation # ............................. " + fviono
   ? "Viol. Date and Time ..................... " + dtoc (fviodate) + " " ;
      + fviotime
   ? "Viol. Location .......................... " + fvioloc
   ?
   ?
   ?
   ?
   ? "Fine .................................... ___________________"
   ?
   ? "Lessee: " + fname
   ? "        " + faddr
   ? "        " + fcity
   ? "        " + fstate + " " + fzip
   ?
   ? "Driver License ... " + flicno
   ? "Day of Birth ..... " + dtoc (fdob)
   ? "Ref # ............ " + alltrim (floc) + "-" + ltrim (str (frano, 6))
   skip
enddo
? chr (12)
set device to screen
set printer to
set print off
set console off
f_popup ("Make sure printer is ready and press ENTER to Print...", .t.)
run copy &yfil lpt1: >nul
close database

