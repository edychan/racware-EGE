* ===========================================================================
* this is the utility routine for racware.
*
* date: 05/01/91
* author: KST
*
* revision
* 10/15/93: (edc) fix calculation ysum based on ftranstyp
*           if ftranstyp="F" or "S"  (force or sale) then ysum = ysum + amt
*           elseif ftranstyp = "C"   (credit) then ysum = ysum - amt  
* 06.02.99: do not update tran. message
* ===========================================================================
f_clrscn ("Mark UnCaptured Transactions to Capture")
ydbrno = 0
yloc = gloc
yresponse = space (30)
ydate = date ()
ytime = time ()

do while .t.
   @ 02, 5 say "DBR Number...... " get ydbrno pict "9999"
   @ 04, 5 say "Capture Location " get yloc pict "!!!!!!!!!!"
   @ 06, 5 say "OK Number....... " get yresponse
   @ 08, 5 say "Capture Date ...." get ydate
   @ 10, 5 say "Capture Time ...." get ytime pict "99:99:99"
   f_rd ()
   yans = f_confirm ("[C]ontinue  [E]dit   [Q]uit", "CEQ")
   if yans = "Q"
      close databases
      return
   endif
   if yans = "C"
      exit
   endif
enddo
f_use ("racred", 4)
seek yloc + str (ydbrno, 4)
ysum = 0.00
do while yloc = frloc .and. ydbrno = fdbrno .and. .not. eof ()
   if frectype = __gccuncap .and. .not. fauthonly
      if ftranstyp = "S" .or. ftranstyp = "F"
         ysum = ysum + fauthamt
      elseif ftranstyp = "C"
         ysum = ysum - fauthamt
      endif
   endif
   skip
enddo
if f_confirm ("Total of DBR " + alltrim (str (ydbrno)) + " = " + ;
      alltrim (str (ysum)) + ".  Is this right? [Y/N] ", "YN") = "Y"

   ybatch = 0
   seek yloc + str(ydbrno,4)
   do while yloc = frloc .and. ydbrno = fdbrno .and. .not. eof ()
      if frectype = __gccuncap .and. .not. fauthonly
         ybatch = max (ybatch, fbatch)
         f_fupdate ("C")
         reclock ()
         * replace fauthstat with yresponse    && 06.02.99
         replace fremark with yresponse        && move to remarks
         replace frectype with __gcccap
         replace fcapamt with fauthamt
         replace fcapdate with ydate
         replace fcaptime with ytime
         commit
         unlock
      endif
      skip
   enddo
   f_use ("rasys")
   go top
   if fccbatch <= ybatch
      reclock ()
      replace fccbatch with ybatch + 1
      unlock
      commit
   endif
endif
close databases

