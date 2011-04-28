return


******************************
function expr_error

param name, line, info, model, _1, _2, _3

set device to screen
setcolor (if (gmucolor, "W/R", "N/W"))
@ 24, 0
@ 24, 0 say "Proc " + m->name + " line " + ltrim (str (m->line)) + ;
   ", " + info
log_error ("Proc " + name + " line " + ltrim (str (line)) + ;
   ", " + info)
inkey (0)
altd ()
quit


******************************
function undef_error

param name, line, info, model, _1

set device to screen
setcolor (if (gmucolor, "W/R", "N/W"))
@ 24, 0
@ 24, 0 say "Proc " + name + " line " + ltrim (str (line)) + ;
   ", " + info + " " + _1
log_error ("Proc " + name + " line " + ltrim (str (line)) + ;
   ", " + info + " " + _1)
inkey (0)
quit


******************************
function misc_error

param name, line, info, model

set device to screen
setcolor (if (gmucolor, "W/R", "N/W"))
@ 24, 0
@ 24, 0 say "Proc " + name + " line " + ltrim (str (line)) + ;
   ", " + info
log_error ("Proc " + name + " line " + ltrim (str (line)) + ;
   ", " + info)
inkey (0)
quit


******************************
function open_error

param name, line, info, model, _1

if neterr () .and. model == "USE"
   return .f.
endif

set device to screen
_sav = setcolor (if (gmucolor, "W/R", "N/W"))
@ 24, 0
@ 24, 0 say "Proc " + name + " line " + ltrim (str (line)) + ;
   ", " + info + " " + _1 + " (" + ltrim (str (doserror ())) + ")"
@ 24, 65 say "Retry? (Y/N)"

do while .t.
   if chr (inkey (0)) $ "YyNn"
      exit
   endif
enddo

log_error ("Proc " + name + " line " + ltrim (str (line)) + ;
   ", " + info + " " + _1 + " (" + ltrim (str (doserror ())) + ")")
if .not. chr (lastkey ()) $ "Yy"
   quit
end

setcolor (gredcolor)
@ 24,0

setcolor (_sav)
return .t.


******************************
function db_error

param name, line, info

set device to screen
_sav = setcolor (if (gmucolor, "W/R", "N/W"))
@ 24, 0
@ 24, 0 say "Proc " + name + " line " + ltrim (str (line)) + ;
   ", " + info
log_error ("Proc " + name + " line " + ltrim (str (line)) + ;
   ", " + info)

inkey (0)

quit


******************************
function print_error

param name, line

set device to screen
_sav = setcolor (if (gmucolor, "W/R", "N/W"))
@ 24, 0
@ 24, 0 say "Proc " + name + " line " + ltrim (str (line)) + ;
   ", printer not ready"

@ 24, 65 say "Retry? (Y/N)"

do while .not. chr (inkey (0)) $ "YyNn"
enddo

setcolor (_sav)

if .not. chr (lastkey ()) $ "Yy"
   quit
end

setcolor (gredcolor)
@ 24,0

return .t.


******************************
function log_error

parameter proc_error
private xsel

xsel = select ()

inkey (3)
select 0

if ! file ("raclog.dbf")
   create errortmp
   use errortmp excl
   append blank
   replace field_name with "PROCERR", field_type with "C", field_len with 80
   append blank
   replace field_name with "PROCDATE", field_type with "D", field_len with 8
   append blank
   replace field_name with "PROCTIME", field_type with "C", field_len with 8
   use

   create ("raclog") from errortmp
   erase errortmp.dbf
endif

use raclog excl
append blank

replace procerr with proc_error
replace procdate with date ()
replace proctime with time ()
use
select (xsel)


******************************
function altc_error

set device to screen
_sav = setcolor (if (gmucolor, "W/R", "N/W"))
@ 24, 0
@ 24, 0 say "Abnormal Break out is requested.  Are you sure? "

if chr (inkey (0)) $ "Yy"
   quit
else
   setcolor (gredcolor)
   @ 24, 00
   setcolor (_sav)
   return .t.
endif

