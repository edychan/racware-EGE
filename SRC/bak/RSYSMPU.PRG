*
* purge old data
* 07.31.98: (edc) year 2000
*
set century on
f_clrscn ("Purge Old Data")
f_use ("RAPATH")
ykeyin = " "
go top
do while .not. eof ()
   if empty (fclninq) .or. fname = "RAPATH"
      skip
      loop
   endif

   yclnval = fclnval
   yclnval = &yclnval
   yclnpict = fclnpict
   yclnpict = &yclnpict

   do while .t.
      @ 10, 05 say "DATABASE..................................... " + falias
      @ 12, 05 say f_truncate ("ENTER " + upper (trim (fclninq)) + ;
         " TO PURGE" + replicate (".", 30), 45) get yclnval picture yclnpict
      @ 14, 05 say "SCANNING..................................... " + ;
         str (0, 6) + " OF " + str (0, 6)
      @ 16, 05 say "RECORDS PURGED............................... " + ;
         str (0, 6)
      if ykeyin = "N"
         clear gets
      else
         f_rd ()
         ykeyin = f_confirm ("[C]onfirm  [S]kip this file  [E]dit  " + ;
            "[N]on stop  [Q]uit", "CSENQ")
      endif
      if ykeyin = "Q"
         set century off
         close databases
         return
      endif

      if ykeyin = "E"
         loop
      endif
      exit
   enddo
   if ykeyin = "S"
      skip
      loop
   endif
   if type ("yclnval") = "D"
      f_y2k (@yclnval)
   endif
   ycnt = 0
   ypurge = 0

   ylgc = fclnlgc
   f_use (trim (rapath->fname))
   ysize = reccount ()
   go top
   delete for rsysmpuok ()
   use
   f_popup ("Done!  Press any key to go to the next database...", .f.)
   if inkey (5) = 27
      ykeyin = " "
   endif
   select rapath
   skip
enddo
close databases
set century off

******************************
function rsysmpuok

ycnt = ycnt + 1
@ 14, 05 say "SCANNING..................................... " + ;
   str (ycnt, 6) + " OF " + str (ysize, 6)
if &ylgc
   ypurge = ypurge + 1
   @ 16, 05 say "RECORDS PURGED............................... " + ;
      str (ypurge, 6)
   reclock ()
   delete
   unlock
endif
return .f.

