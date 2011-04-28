do while .t.
   xret3 = f_pushmenu (xoption2)
   if xret3 = 0
      exit
   endif
   xoption3 = substr (goption [xret3], 4)
   f_clrscn ("USER FILE MAINTENANCE")
   rest from (gmempath+"rausr") additive
   do case
   case xret3 = 1
      set key 28 to rsssuhlp
      f_use ("rausr")
      do while .t.
         @ 05, 02 say "User ID..... " get l_fid picture "!!!"
         if f_rd() = 27
            exit
         endif
         set exact on
         seek l_fid
         set exact off
         if .not. found ()
            l_fmoddt = date ()
            f_add ("rausr", "rausr", "rsysssuf")
            use
            exit
         else
            tone (500, 9)
            f_popup ("Duplicate User ID. Press Any Key to Retry...",.t.)
         endif
      enddo
      set key 28 to
   case xret3 = 2
      set key 28 to rsssuhlp
      f_use ("rausr")
      if .not. eof ()
         seek gusrid
         if f_pick_f (05, 03, "", "", "fid+[ -> ]+f_truncate(trim(ffname)+" ;
               + "[ ]+flname,27)")
            f_update ("rausr", "rausr", "", "rsysssu1")
            use
         endif
      else
         f_popup ("File is Empty. Press Any Key to Continue...", .t.)
      endif
      set key 28 to
   case xret3 = 3
      f_clrscn ("USER GROUP MAINTENANCE")
      f_use ("ragroup")
      do while reccount () < 10
         append blank
      enddo
      declare l_fgroup [10], l_ffreesell [10], l_fexdos [10]

      @ 2, 10 say "GROUP             FREESELL    EXIT TO DOS"
      for n = 1 to 10
         go n
         @ 3 + n, 10 say str (n - 1, 1) + " - "
         l_fgroup [n] = fgroup
         l_ffreesell [n] = ffreesell
         l_fexdos [n] = fexdos
      next
      do while .t.
         for n = 1 to 10
            @ 3 + n, 14 get l_fgroup [n] pict "!!!!!!!!!!"
            @ 3 + n, 31 get l_ffreesell [n] pict "Y"
            @ 3 + n, 45 get l_fexdos [n] pict "Y"
         next
         f_rd ()
         yans = f_confirm ("[C]onfirm  [E]dit  [I]gnore Changes", "CEI")
         if yans = "E"
            loop
         endif
         if yans = "C"
            for n = 1 to 10
               go n
               reclock ()
               replace fgroup with l_fgroup [n]
               replace ffreesell with l_ffreesell [n]
               replace fexdos with l_fexdos [n]
               unlock
            next
         endif
         exit
      enddo
      use
   endcase
enddo
release all like l_*
close database


******************************
procedure rsssuhlp

private yvar

yvar = alltrim (upper(readvar()))
do case
case yvar = "L_FGROUP"
   f_use ("ragroup")
   set filter to .not. empty (fgroup)
   go top
   if f_valid (.not. eof (), "No User Group Set Up Yet!!!")
      if f_pick_f (05, 32,"","",	"str(recno () - 1, 1) + [ - ] + fgroup")
         if .not. (str (recno () - 1, 1) $ l_fgroup)
            l_fgroup = f_truncate (trim (l_fgroup) + str (recno () - 1, 1), 10)
         endif
         do rsysssuf
      endif
   endif
   select ragroup
   use
case yvar = "L_FLOCGP"
   f_use ("ralocgp")
   go top
   set filter to .not. empty (fgroup)
   if f_valid (.not. eof (), "No Location Group Set Up Yet!!!")
      if f_pick_f (05, 32,"","",	"fgroup")
         l_flocgp = fgroup
         keyboard chr (13)
      endif
   endif
   select ralocgp
   use
otherwise
   tone (500,9)
   f_popup ("No Help information for this Field. Press Any Key to Continue...",.t.)
endcase
set cursor on
return


******************************
procedure rsysssu1

l_fmoddt = max (date (), l_fmoddt)
do rsysssuf


******************************
procedure rsysssuf

private ystr, n
ystr = space (10)
for n = 0 to 9
   if str (n, 1) $ l_fgroup
      ystr = stuff (ystr, n + 1, 1, str (n, 1))
   endif
next
l_fgroup = ystr

