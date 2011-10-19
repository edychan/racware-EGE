*
* special case: for dollar eagle
* 1. set hourly charge 
* 2. mark repeat customer
* 3. skip processed record
* Revision:
* 12/02/96: set delete on to avoid matching deleted records
* 11/25/97: rematch QR customer for today res.
set excl off
set delete on
* 
clear
select 2 
use j:racust index j:racust1      && by last name
select 1
use j:rares index j:rares2
seek "O"
@ 05, 05 say "Processing: "
xdate = date()
y = 0
do while .not. eof () .and. fresvstat = "O"
   y = y + 1
   @ 05, 17 say str(y,6)
   * skip processed record.. 01/23/97 edc
   * re-match for today res  11/25/97 edc
   if .not. empty(a->fupdate) .and. a->fdateout <> xdate
      select 1
      skip
      loop
   endif
   *
   select 2
   seek upper(trim(a->flname))
   do while .not. eof () .and. upper(trim(b->flname)) = upper(trim(a->flname))
      if upper(substr(b->ffname,1,5)) = upper(substr(a->ffname,1,5))
         select 1
         rlock ()
         if upper(b->fcustno) = "QR"
            replace fupdate with "#"
         else
            replace fupdate with "*"
         endif
         commit
         unlock
         exit
      endif
      skip
   enddo
   select 1
   if empty(fupdate)      && mark processed records...
      rlock ()
      replace fupdate with "?"
   endif
   if fhrchg > 0
      skip
      loop
   endif
   rlock ()
   if fdlychg > 0
      replace fhrchg with fdlychg/3    
   elseif fwkchg > 0
      replace fhrchg with fwkchg/15    
   else
     replace fhrchg with 40
   endif
   commit 
   unlock
   skip
enddo
close data
quit

