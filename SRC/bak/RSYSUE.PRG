*
* racware e-mail system
*
* 06.26.97: add message to all option
*

private yfil, ys1, yfilnum, yptr, ybuffer, yeof, ybytes

do while .t.
   xret3 = f_pushmenu (xoption2)
   if xret3 = 0
      exit
   endif
   xoption3 = substr (goption [xret3], 4)
   f_clrscn ("E-MAIL MAINTENANCE")
   do case
   case xret3 = 1
      private ynamelst [9], i, ydest
      afill (ynamelst, "")
      f_use ("rausr")
      f_box (02, 03, 04, 78)
      yptr = 0
      do while .t.
         if f_pick_f (05, 3, "", "", "fid + [ -> ] + " + ;
               "f_truncate (trim (ffname) + [ ] + flname, 27)")
            yptr = yptr + 1
            ynamelst [yptr] = alltrim(fid)
            @ 03, 5+(yptr-1)*5 say fid pict "XXX"
            if yptr = 9
               exit
            endif
         else
            exit
         endif
      enddo
      if yptr = 0
         select rausr
         use
         loop
      endif
      yfil = gmsgpath + ynamelst [1] + "_" + alltrim (gusrid) + ".msg"
      if file (yfil)
         f_rrout (yfil, .t., "Message To ")
      else
         ys1 = fcreate (yfil,0)
         if ys1 < 0
            f_popup ("Unable to create message file. Press Any Key to Retry...", .t.)
            select rausr
            use
            loop
         endif
         fclose (ys1)
         f_rrout (yfil, .t., "Message To ")
      endif
      * check filesize
      if swfilesize (yfil) < 10
         delete file &yfil
         select rausr
         use
         loop
      endif
      * write to the rest
      for i = 2 to yptr 
         ydest = gmsgpath + ynamelst [i] + "_" + alltrim (gusrid) + ".msg"
         if yfil <> ydest
            if file (ydest)                     && 07.24.00:
               for j = 1 to 9
                  ydest = gmsgpath + ynamelst [i] + "_" + alltrim (gusrid) + str(j,1) + ".msg"
                  if .not. file (ydest)
                     exit
                  endif
               next j
            endif
            copy file &yfil to &ydest
         endif
      next i
      * if gsup
      *   if f_confirm ("Send to other locations? [Y/N]", "YN") = "Y"
      *      copy file &yfil to (gsupmpath + alltrim(fid) + "_" + ;
      *            alltrim (gusrid) + ".msg")
      *   endif
      select rausr
      use
   case xret3 = 2
      f_clrscn ("E-MAIL MAINTENANCE")
      yfil = gmsgpath + alltrim (gusrid) + "_*" + ".msg"
      yfilnum = adir (yfil)
      if yfilnum = 0
         f_popup ("No Message For Now...", .t.)
         loop
      endif

      private yfilary [yfilnum]
      adir (yfil, yfilary)
      for yptr = 1 to yfilnum
         yfilary [yptr] = f_truncate (strtran (upper (alltrim (substr (yfilary [yptr], ;
               len (alltrim (gusrid)) + 2))), ".MSG", ""), 4)
      next
      yptr = 1
      do while .t.
         if yfilnum > 1
            yptr = f_pick_a (2, 5, "", "From", yfilary, yfilnum, 1)
            if yptr = 0
               exit
            endif
         else
            yptr = 1
         endif
         yfil = gmsgpath + alltrim (gusrid) + "_" + alltrim (yfilary [yptr]) + ".msg"
         f_rrout (yfil, .f., "Message From " + alltrim (yfilary [yptr]))
         if f_confirm ("Do you want to erase this message? [Y/N]", "YN") = "Y"
            adel (yfilary, yptr)
            yfilnum = yfilnum - 1
            erase &yfil
            if yfilnum = 0
               exit
            endif
         elseif yfilnum = 1
            exit
         endif
      enddo
   case xret3 = 3       && system message
      yfil = gmsgpath + "@RAC.msg"
      if file (yfil)
         keyboard chr(27)
         f_rrout (yfil, .f., "Message To ALL"  )
         if f_confirm ("Do you want to erase this message? [Y/N]", "YN") = "Y"
            erase &yfil
         else
            f_rrout (yfil, .t., "Message To ALL"  )
         endif
      else
         ys1 = fcreate (yfil,0)
         if ys1 < 0
            f_popup ("Unable to create message file. Press Any Key to Retry...", .t.)
            loop
         endif
         fclose (ys1)
         f_rrout (yfil, .t., "Message To ALL")
      endif
   endcase
enddo

