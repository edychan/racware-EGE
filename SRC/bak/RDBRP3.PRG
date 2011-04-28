private ycnt, yfld1, yfld2

f_popup ("Updating DBR : "+trim(l_floc)+"->"+str(l_fdbrno,4))
yloc = l_floc
ydbrno = l_fdbrno
f_use ("rares")
f_use ("racust",2)
f_use ("racrp")
f_use ("ravm")
f_use ("raagrh")
f_use ("rahdbrt")
f_use ("radbrt")
select radbrt
seek yloc + str (ydbrno, 4)
do while floc = yloc .and. fdbrno = ydbrno .and. .not. eof ()
   if radbrt->frectype $ "CF"
      select raagrh
      seek radbrt->floc + str (radbrt->frano, 6)
      if found ()
         select ravm
         seek raagrh->funit
         if found ()
            f_popup ("Updating Vehicle File ...")
            f_fupdate ("C")
            reclock()
            replace ftnm with ftnm+raagrh->ftmetot+raagrh->fmlgtot
            replace fcdw with fcdw+raagrh->fcdwtot
            replace fpai with fpai+raagrh->fpaitot
            replace ftax with ftax+raagrh->ftaxtot
            replace fdays with fdays+raagrh->fdays
            commit
            unlock
         endif
         if .not. empty (raagrh->fcustno)
            select racust
            seek raagrh->fcustno
            if found ()
               f_popup ("Updating Customer File ...")
               f_fupdate ("C")
               reclock ()
               replace fckin with max (raagrh->fdatein, fckin)
               replace frental with frental + 1
               replace fsale with fsale + raagrh->ftotal
               commit
               unlock
            endif
         endif
         if .not. empty (raagrh->fcrpno)
            select racrp
            seek raagrh->fcrpno
            if found ()
               f_popup ("Updating Corporate File ...")
               f_fupdate ("C")
               reclock ()
               replace fckin with max (raagrh->fdatein, fckin)
               replace frental with frental + 1
               replace fsale with fsale + raagrh->ftotal
               commit
               unlock
            endif
         endif
         if .not. empty (raagrh->fresvno)
            select rares
            seek raagrh->fresvno
            if found ()
               f_popup ("Updating Reservation File ...")
               f_fupdate ("C")
               reclock ()
               replace fresvstat with "U"
               replace ftnm with raagrh->ftmetot + raagrh->fmlgtot
               replace fcomm with fcommpct * ftnm / 100.00
               commit
               unlock
            endif
         endif
      endif
   endif
   select rahdbrt
   append blank
   reclock ()
   for ycnt = 1 to fcount ()
      yfld1 = field (ycnt)
      yfld2 = "radbrt->" + yfld1
      replace &yfld1 with &yfld2
   next
   commit
   unlock
   select radbrt
   if f_clrskip () = 0
      exit
   endif
enddo
