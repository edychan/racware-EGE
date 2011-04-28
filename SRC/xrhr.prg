*
* update rental hr 
* run remotely (h:\racware\dbf)
* should be run using remote desktop (much faster)
*
set excl off

xdate = ctod('01/01/2007')
select 0
use h:\racware\dbf\raagrh index h:\racware\dbf\raagrh4 alias raagrh
set softseek on
seek xdate

do while .not. eof ()
   if frhr = 0
      
      yto = val (substr (ftimeout, 1, 2)) * 60 + ;
         val (substr (ftimeout, 4, 2))
      yti = val (substr (ftimein, 1 ,2)) * 60 + val (substr (ftimein, 4, 2))
      ymins = (fdatein - fdateout) * 24 * 60 + yti - yto
      ydays = int (ymins / 1440)
      ymins = ymins - ydays * 1440
      ymins = ymins - 60    && grace 
      yhr = int (ymins / 60)
      ymins = ymins - yhr * 60
      if ymins > 0
         yhr = yhr + 1
      endif
      if yhr > 0
         ? "Update RA "+flname
         rlock ()
         replace frhr with yhr
         commit
         unlock
      endif
   endif
   skip
enddo

close all


