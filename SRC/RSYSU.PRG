do while .t.
   xret2 = f_pushmenu (xoption1)
   if xret2 = 0
      exit
   endif
   xoption2 = substr (goption [xret2], 4)
   do case
   case xret2 = 1
      f_clrscn ("SYSTEM CONSOLE")

      if file ("raclog.dbf")
         select 0
         use raclog
         if .not. eof()
            if f_confirm ("Do you want to view System Log File? [Y/N]", ;
                  "YN") = "Y"
               f_pick_f (10, 3, "", "컴Date컴횺essage", ;
                  "dtoc(procdate)+[ ]+substr(procerr,1,60)", "X")
               if f_confirm ("Do you want to erase System Log File? [Y/N]", ;
                     "YN") = "Y"
                  use raclog exclusive
                  zap
                  unlock
               endif
            endif
         endif
         use
      endif
      private yrecno, y, y1

      f_use ("rconsole")
      go top
      yrecno = recno ()
      setcolor (gsubcolor)
      f_box (02, 02, 22, 75)
      @ 02, 04 say "Stn훃sr컴Status컴훂ask컴컴컴컴컴컴컴컴컴컴컴Log " + ;
            "In Time컴컴컴훁tation"
      do while .t.
         set cursor off
         y = 3
         go yrecno
         setcolor (gsubcolor)
         do while y <= 21 .and. .not. eof ()
            @ y, 4 say str (fline, 3) + if (gusrline = fline, [*], [ ]) + ;
                  left (fuser, 4) + [ ] + left (fstatus, 8) + [ ] + fmodule ;
                  + [ ] + dtoc (fdate) + [ ] + ftime + [ ] + fstation
            y = y + 1
            skip
         enddo
         if y <= 21
            @ y, 03 clear to 21, 74
         endif 
         setcolor (gredcolor)
         @ 24, 01 say "[C]lear Stn  [D]isable Lgn  [E]nable Lgn  " + ;
               "[F]orwd  [B]ackwd  [Q]uit... "
         y = upper (chr (inkey ()))
         if .not. (y $ "CDEFBQ")
            loop
         endif
         set cursor on
         do case
         case y = "Q"
            set cursor off
            exit
         case y = "C"
            y1 = 0
            @ 24, 00
            @ 24, 01 say "Station Number to clear.... [   ]"
            @ 24, 30 get y1 pict "999" valid ;
                  f_valid (y1 >= 1 .and. y1 <= reccount ())
            if f_rd () = 13
               @ 24, 00
               if f_confirm ("Are you sure to clear " + str (y1, 3) + ;
                     "? [Y/N]", "YN") = "Y"
                  go y1
                  reclock()
                  replace fuser with "OPEN", fstatus with "IDLE"
                  replace fmodule with space (25)
                  replace fdate with ctod ("  /  /  "), ftime with "  :  :  "
                  replace fstation with space (8)
                  commit
                  unlock
               endif
            else
               @ 24, 00
            endif
         case y = "D"
            go top
            do while .not. eof()
               if gusrline <> fline
                  reclock ()
                  replace fstatus with "DISABLE"
                  unlock
               endif
               skip
            enddo
         case y = "E"
            go top
            do while .not. eof()
               if gusrline <> fline .and. fstatus = "DISABLE"
                  reclock ()
                  replace fuser with "OPEN", fstatus with "IDLE"
                  unlock
               endif
               skip
            enddo
         case y = "F"
            go yrecno
            skip 15
            if .not. eof ()
               yrecno = recno ()
            endif
         case y = "B"
            go yrecno
            skip -15
            if bof ()
               go top
            endif
            yrecno = recno ()
         endcase
      enddo
      close databases
   case xret2 = 2
      do rsysue
   case xret2 = 3
      *set color to
      *clear screen
      *? "Enter EXIT to get back to Racware"
      *?
      *set cursor on
      *blimempak (-1)
      *! command
      *set cursor off

      private ydir
      private yfld[3], ycol[3], yvalid[3], ypict[3]
      
      ydir = gdbfpath + gusrid + ".dat"
      select 0
      if .not. file (ydir)
         create (gstnpath + "stru")
         use (gstnpath + "stru") exclusive
         append blank
         replace field_name with "NAME"
         replace field_type with "C"
         replace field_len with 20
         replace field_dec with 0
         append blank
         replace field_name with "COMMENT"
         replace field_type with "C"
         replace field_len with 20
         replace field_dec with 0
         append blank
         replace field_name with "PHONE"
         replace field_type with "C"
         replace field_len with 12
         replace field_dec with 0
         use
         create (ydir) from (gstnpath + "stru")
         erase (gstnpath + "stru.dbf")
      endif
      if .not. file (gdbfpath + gusrid + ".ntx")
         use (ydir) excl
         index on name to (gdbfpath + gusrid + ".ntx")
      endif
      
      f_clrscn ("PHONE BOOK")
      use (ydir) index (gdbfpath + gusrid + ".ntx")
      go top
      yfld[1]="name"
      yfld[2]="comment"
      yfld[3]="phone"
      ycol[1]="Name"
      ycol[2]="Comment"
      ycol[3]="Phone"
      yvalid[1]=".t."
      yvalid[2]=".t."
      yvalid[3]=".t."
      ypict[1]=replicate ("!",20)
      ypict[2]=replicate ("X",20)
      ypict[3]="xxx-xxx-xxxx"
      f_edit (yfld, ycol, 0, .t., yvalid, ypict)
      use

   case xret2 = 4

      private yfil
      private yfld[3], ycol[3], yvalid[3], ypict[3]
      
      yfil = gdbfpath + gusrid + ".cal"
      select 0
      if .not. file (yfil)
         create (gstnpath + "stru")
         use (gstnpath + "stru") exclusive
         append blank
         replace field_name with "FDATE"
         replace field_type with "D"
         replace field_len with 8
         replace field_dec with 0
         append blank
         replace field_name with "FTIME"
         replace field_type with "C"
         replace field_len with 5
         replace field_dec with 0
         append blank
         replace field_name with "EVENT"
         replace field_type with "C"
         replace field_len with 40
         replace field_dec with 0
         use
         create (yfil) from (gstnpath + "stru")
         erase (gstnpath + "stru.dbf")
      endif
      if .not. file (gdbfpath + gusrid + ".nx2")
         use (yfil) excl
         index on dtos(fdate)+ftime to (gdbfpath + gusrid + ".nx2")
      endif
      
      f_clrscn ("REMINDER")
      use (yfil) index (gdbfpath + gusrid + ".nx2")
      go top
      yfld[1]="FDATE"
      yfld[2]="FTIME"
      yfld[3]="EVENT"
      ycol[1]="DATE"
      ycol[2]="TIME"
      ycol[3]="EVENT"
      yvalid[1]=".t."
      yvalid[2]=".t."
      yvalid[3]=".t."
      ypict[1]="@D"
      ypict[2]="99:99"
      ypict[3]=replicate ("X",40)
      f_edit (yfld, ycol, 0, .t., yvalid, ypict)
      use
   endcase
enddo
