private ycolor, xr1, xr2
private yl, yinitstr, yerror, ykey, ystr, ychar, yfld1, yfld2, n

f_clrscn ("Modem Initialization")

if .not. getccsetup ()
   return
endif

xr1 = 1
xr2 = 23
yl = xr1

yl = f_outline (yl, xr1, xr2, "Opening Modem Comm Port " + str (__gcomm, 1))
closecomm (__gcomm)
swuseport (__gcomm)

yerror = opencomm (__gcomm, __grbuff, __gxbuff)

if yerror <> 0
   yl = f_outline (yl, xr1, xr2, "Modem Open Error " + str (yerror, 2))
   closecomm (__gcomm)
   inkey (0)
   return
endif

yinitstr = upper (alltrim (__ginitstr))
yl = f_outline (yl, xr1, xr2, "Initilizing using " + trim (yinitstr))
setbaud (__gcomm, __gbaud, __gparity, __gstopbit, __gdatabit)

if statuscd (__gcomm)
   yl = f_outline (yl, xr1, xr2, "Carrier Detect CD High.")
endif

yl = f_outline (yl, xr1, xr2, "Reseting Modem")
txchar (__gcomm, chr(13))
txchar (__gcomm, chr(13))
* txstring (__gcomm, "ATZ" + chr(13))
txstring (__gcomm, "AT" + chr(13))     && 10/14/95
if .not. modem_resp ()
   * yl = f_outline (yl, xr1, xr2, "Modem Not responding to ATZ")
   yl = f_outline (yl, xr1, xr2, "Modem Not responding to ATZ")
endif

swdelay (9)

txchar (__gcomm, chr(13))
txchar (__gcomm, chr(13))
rxflush (__gcomm)

yl = f_outline (yl, xr1, xr2, "Initializing Modem")
txstring (__gcomm, alltrim (yinitstr) + chr (13))
swdelay (9)
txwclear (__gcomm)

if .not. modem_resp ()
   yl = f_outline (yl, xr1, xr2, "Modem Not responding to " + yinitstr)
else
   keyboard chr (13) + yinitstr + chr (13)
endif

ystr = ""
ycol = 0
ychar = ""
do while .t.
   ykey = inkey ()
   if ykey = 27
      exit
   endif
   if ykey <> 0
      txchar (__gcomm, chr (ykey))
      if ykey = 13 .or. (ykey >= 32 .and. ykey <= 127)
         if ykey <> 13
            @ yl, ycol say chr (ykey)
         endif
         if ycol < 78 .and. ykey <> 13
            ycol = ycol + 1
         else
            ycol = 1
            if yl = xr2
               scroll (xr1, 0, xr2, 79, 1)
            else
               yl = yl + 1
            endif
         endif
      endif
   endif

   if .not. rxempty (__gcomm)
      ychar = rxchar (__gcomm)
      @ yl, ycol say chr (ychar)
      if ycol < 78 .and. ychar <> 13
         ycol = ycol + 1
      else
         ycol = 1
         if yl = xr2
            scroll (xr1, 0, xr2, 79, 1)
         else
            yl = yl + 1
         endif
      endif
      if ychar = 13
         ystr = ""
      endif
      if (ychar > 32 .and. ychar <= 127) .or. gcclog
         ystr = ystr + chr (ychar)
      endif
   endif
enddo
if .not. empty (ychar)
   yl = f_outline (yl, xr1, xr2, ystr)
endif

closecomm (__gcomm)


******************************
function f_outline

parameters xline, xrow1, xrow2, xmessage
do while .not. empty (xmessage)
   @ xline, 1 say left (xmessage, 78)
   xmessage = substr (xmessage, 79)
   if xline < xrow2
      xline = xline + 1
   else
      scroll (xrow1, 0, xrow2, 79, 1)
   endif
enddo
return xline

