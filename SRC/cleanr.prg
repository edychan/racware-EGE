*
* usage: cleanr <date>
*
parameter xdate
set excl on

if pcount() <> 1
   ?
   ? "Usage: CleanR <date> "
   ?
   quit
endif

ydate = ctod(xdate)
if empty(ydate) .or. ydate>date()
   ?
   ? "Invalid date ..."
   ?
   quit
endif

yfil = "h:\racware\dbf\rartm"
select 0
use &yfil index &yfil alias rartm

go top
do while .not. eof ()
   if fdateto <= ydate
      delete
   endif
   skip
enddo

pack

?
? "Process completed."
?

close all


