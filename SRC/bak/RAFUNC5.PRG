******************************
procedure calculator

private ykey, ycolor, xformat, num, ans, oper, yscn

ycolor = setcolor ()
yscn = f_box (04, 11, 14, 71)
set color to

ykey = 0
xformat = "999999999.99"

@ 04, 11 say "ÛßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßÛ"
@ 05, 11 say "Û  ÚÄÄÄÂÄÄÄÂÄÄÄÂÄÄÄ¿                                        Û"
@ 06, 11 say "Û  ³ 7 ³ 8 ³ 9 ³ + ³                                        Û"
@ 07, 11 say "Û  ÃÄÄÄÅÄÄÄÅÄÄÄÅÄÄÄ´                               ÚÄÄÄÄÄ¿  Û"
@ 08, 11 say "Û  ³ 4 ³ 5 ³ 6 ³ - ³                               ³ Neg ³  Û"
@ 09, 11 say "Û  ÃÄÄÄÅÄÄÄÅÄÄÄÅÄÄÄ´                               ÃÄÄÄÄÄ´  Û"
@ 10, 11 say "Û  ³ 1 ³ 2 ³ 3 ³ * ³                               ³  C  ³  Û"
@ 11, 11 say "Û  ÃÄÄÄÅÄÄÄÅÄÄÄÅÄÄÄ´                               ÃÄÄÄÄÄ´  Û"
@ 12, 11 say "Û  ³ 0 ³ . ³   ³ / ³                               ³ A C ³  Û"
@ 13, 11 say "Û  ÀÄÄÄÁÄÄÄÙ   ÀÄÄÄÙ                               ÀÄÄÄÄÄÙ  Û"
@ 14, 11 say "ÛÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÛ"


num = 0.00
ans = 0.00

do while .t.
   if .not. f_getnum2 ()
      exit
   endif
   if oper = "A"
      num = 0.00
      ans = 0.00
      @ 13, 33 say " * CLEAR *   "
      scroll (05, 31, 13, 61, 2)
      loop
   endif
   ans = f_calc2 (ans, num)
   scroll (05, 31, 13, 61, 1)
enddo
setcolor (ycolor)
f_restbox (yscn)

      
******************************
function f_calc2

parameter xnum1, xnum2

do case
case oper = "+"
   if (xnum1 + xnum2) > 999999999.99
      @ 13, 47 say " * OVERFLOW *"
      return 0
   else
      @ 13, 47 say xnum1 + xnum2 pict xformat
      @ 13, 59 say "="
      return xnum1 + xnum2
   endif
case oper = "-"
   if (xnum1 - xnum2) < -99999999.99
      @ 13, 47 say " * OVERFLOW *"
      return 0
   else
      @ 13, 47 say xnum1 - xnum2 pict xformat
      @ 13, 59 say "="
      return xnum1 - xnum2
   endif
case oper = "*"
   if (xnum1 * xnum2) > 999999999.99
      @ 13, 47 say " * OVERFLOW *"
      return 0
   else
      @ 13, 47 say xnum1 * xnum2 pict xformat
      @ 13, 59 say "="
      return xnum1 * xnum2
   endif
case oper = "/"
   if xnum2 = 0
      @ 13, 47 say " * OVERFLOW *"
      return 0
   elseif (xnum1 / xnum2) > 999999999.99 .or. (xnum1 / xnum2) < -99999999.99
      @ 13, 47 say " * OVERFLOW *"
      return 0
   else
      @ 13, 47 say xnum1 / xnum2 pict xformat
      @ 13, 59 say "="
      return xnum1 / xnum2
   endif
otherwise
   @ 13, 47 say ans pict xformat
   @ 13, 59 say "="
   return ans
endcase
                                              

******************************
function f_getnum2

private ypos, yfield, ydotpos, ynumkey, n, yins

yins = readinsert ()
setcolor ("n/w")
yfield = transform (num, xformat)
ypos = 1
@ 13, 33 say yfield

do while .t.
   @ 13, 33 say yfield
   @ 13, 33 + ypos - 1 say ""
   ykey = inkey (0)
   oper = upper (chr (ykey))
   do case
   case ykey = 27
      set color to
      return .f.
   case oper = "C"
      num = 0
      yfield = transform (num, xformat)
      ypos = 1
      @ 13, 33 say yfield
   case oper $ "+-*/A" 
      num = val (yfield)
      set color to
      @ 13, 33 say transform (num, xformat)
      if oper <> "A"
         @ 13, 45 say oper
      endif
      return .t.
   case ykey = 22
      yins = .not. yins
      readinsert (.not. readinsert ())
   case ykey = 19
      if ypos > 1
         ypos = ypos - 1
      endif
   case ykey = 4
      if ypos < len (yfield)
         ypos = ypos + 1
      endif
   case ykey = 7
      yfield = stuff (yfield, ypos, 1, "") + " "
   case ykey = 8
      if ypos > 1
         if yins
            yfield = stuff (yfield, ypos - 1, 1, "") + " "
         else
            yfield = stuff (yfield, ypos - 1, 1, " ")
         endif
         ypos = ypos - 1
      endif
   case oper = "N"
      for n = 1 to 12
         if substr (yfield, n, 1) <> " "
            exit
         endif
      next
      if n = 1
         if substr (yfield, 1, 1) = "-"
            yfield = substr (yfield, 2) + " "
         else
            yfield = "-" + left (yfield, 11)
         endif
      elseif n <= 12
         if substr (yfield, n, 1) = "-"
            yfield = stuff (yfield, n, 1, " ")
         else
            yfield = stuff (yfield, n - 1, 1, "-")
         endif
      endif
   case oper $ "0123456789 ."
      yfield = stuff (yfield, ypos, 1, oper)
      if ypos < 12
         if substr (yfield, ypos + 1, 1) = " "
            yfield = left (left (yfield, ypos) + space (12), 12)
         endif   
         ypos = ypos + 1
      endif
   endcase
enddo

