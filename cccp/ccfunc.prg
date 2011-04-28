* ============================================
* Functions for CCCP standalone module
*
* ============================================

function modem_resp

return (waitfor (if (at ("V0", __ginitstr) > 0, "0", "OK"), __gtimeout) = 0)


******************************
function waitfor

parameters xstr, xtime
private ysec0, ystr, yonhook, ychar, ykey

if pcount () < 2
   xtime = __gtimeout
endif
ysec0 = seconds ()
ystr = ""
yonhook = statuscd (__gcomm)

do while (seconds () - ysec0) < xtime
   if rxcount (__gcomm) > 0
      ychar = rxchar (__gcomm)
      ystr = ystr + chr (ychar)
      if ychar = 13
         debug_disp (ystr)
      endif

      do case
      case at (xstr, ystr) > 0
         debug_disp ("Waitfor Found: " + xstr)
         return 0

      case ychar = 21
         debug_disp ("Waitfor Error: NAK")
         return 21

      case "NO DIALTONE" $ upper (ystr)
         debug_disp ("Waitfor Error: NO DIALTONE")
         return 10

      case "NO CARRIER" $ upper (ystr)
         debug_disp ("Waitfor Error: NO CARRIER")
         return 9

      case "BUSY" $ upper (ystr)
         debug_disp ("Waitfor Error: BUSY")
         return 8

      case "ERROR" $ upper (ystr)
         debug_disp ("Waitfor Error: ERROR")
         return 1
      endcase
   elseif yonhook .and. .not. statuscd (__gcomm)
      debug_disp ("Waitfor Error: Carrier Loss")
      return 9
   endif

   if inkey () = 27
      return 27
   endif
enddo

debug_disp ("Waitfor Found Only: " + ystr)
return -89


******************************
function debug_disp

parameters xstr

if gcclog
   private ysel
   ysel = select ()
   select 0
   if .not. file (gstnpath + "CCLOG.DBF")
      create tempstru
      use tempstru exclusive
      append blank
      replace field_name with "FDATE"
      replace field_type with "D"
      replace field_len with 8
      replace field_dec with 0
      append blank
      replace field_name with "FTIME"
      replace field_type with "C"
      replace field_len with 8
      replace field_dec with 0
      append blank
      replace field_name with "FLINE"
      replace field_type with "C"
      replace field_len with 60
      replace field_dec with 0
      use
      create (gstnpath + "CCLOG") from tempstru
      erase tempstru.dbf
   endif
   use (gstnpath + "CCLOG") exclusive
   do while .not. empty (xstr)
      append blank
      replace fdate with date (), ftime with time (), ;
         fline with left (xstr, 60)
      xstr = substr (xstr, 61)
   enddo
   use
   select (ysel)
endif

******************************
function tformat

parameters xtyp, xpm1, xpm2, xpm3, xpm4, xpm5, xpm6, xpm7, xpm8, xpm9, xpm10
private ypm5, yblk, yblk1, yblk2, yfs, ycs, ydate, ymth, yyr, ytranstyp
fs = chr (28)
cs = ","

if gccnet = "LPA"
   do case
   case xtyp == "S"
      * xpm1 : client #
      * xpm2 : merchant #
      * xpm3 : terminal #
      * xpm4 : serial #
      * xpm5 : [001]
      * xpm6 : [@]
      * xpm7 : cc #
      * xpm8 : cc exp. MMYY
      * xpm9 : []
      * xpm10: auth. amt.
      private yrdays
      yrdays = strtran (str(int (val(xpm10) / 20), 2), " ", "0")
      yrdays = if(yrdays="00", "01", yrdays)    && cannot be [00]
      yrdays = if(yrdays="**", "99", yrdays)    && 11.03.99
      do while .t.
         if alltrim(xpm7) $ gccinfo       && if the card is swiped, ie. acct # equals 
            yblk = [K.]       +  ;
                   [A02000]   +  ;
                   substr(xpm1,1,4) + ;   && client #
                   xpm2       +  ;        && merchant #
                   xpm3       +  ;        && term #
                   [1]        +  ;        && 1=> single, 2=> multi trans.
                   [000]      +  ;        && filler always 000
                   [001]      +  ;        && seq #
                   [F]        +  ;        && F=>financial
                   [02]       +  ;        && 01=> sale, 02=> auth.
                   [2]        +  ;        && 1=> accept PIN, 2=> does not
                   [01]       +  ;        && 01=> card swipe, origin unknown
                   gccinfo    +  ;        && magnetic stripe swipe
                   fs         +  ;
                   xpm10      +  ;        && auth amt
                   fs         +  ;
                   [00000000] +  ;        && filler
                   fs         +  ;
                   [A]        +  ;        && Auto Rental
                   [N]        +  ;        && swipe trans.
                   yrdays     +  ;        && *duration of rental
                   fs         +  ;
                   fs         +  ;
                   [005]      +  ;        && Auto Rental
                   [00000.00] +  ;        && extra charge amt.
                   [00000000] +  ;        && *ra # (X8)
                   f_truncate(__gcity,18)+ ; && *rental city (X18)
                   __gstate   +  ;        && *state (X2)
                   strtran(dtoc(date()),"/","") + ;  && *rental date MMDDYY
                   strtran(time(),":","") + ;        && *rental time HHMMSS
                   f_truncate(__gcity,18)+ ; && *rental city (X18)
                   __gstate   +  ;        && *state (X2)
                   strtran(dtoc(date()+val(yrdays)),"/","") + ; && *return date
                   strtran(time(),":","") + ;         && *return time
                   f_truncate("ON FILE",20) + ;       && *name (X20)
                   [000000]               && extra chg reason
            gccswipe = "C"      && card read
         else
            * 09.23.99: revision per paymentech, for MC: preferred customer should always be [N]
            private ycctype
            ycctype = " "
            good_card (alltrim(xpm7), @ycctype)
            yblk = [K.]       +  ;
                   [A02000]   +  ;
                   substr(xpm1,1,4) + ;   && client #
                   xpm2       +  ;        && merchant #
                   xpm3       +  ;        && term #
                   [1]        +  ;        && 1=> single, 2=> multi trans.
                   [000]      +  ;        && filler always 000
                   [001]      +  ;        && seq #
                   [F]        +  ;        && F=>financial
                   [02]       +  ;        && 01=> sale, 02=> auth.
                   [2]        +  ;        && 1=> accept PIN, 2=> does not
                   [02]       +  ;        && 02=> manual entered
                   alltrim(xpm7)  +  ;    && cc #   08.25.99: alltrim(cc#) per KAL
                   fs         +  ;
                   strtran(xpm8, "/", "")  +  ;  && cc exp MMYY
                   fs         +  ; 
                   xpm10      +  ;        && auth amt
                   fs         +  ;
                   [00000000] +  ;        && filler
                   fs         +  ;
                   [A]        +  ;        && Auto Rental
                   if(ycctype="MC",[N],[Y])   +  ;  && manual entered
                   yrdays     +  ;        && *duration of rental
                   fs         +  ;
                   fs         +  ;
                   [005]      +  ;        && Auto Rental
                   [00000.00] +  ;        && extra charge amt.
                   [00000000] +  ;        && *ra # (X8)
                   f_truncate(__gcity,18)+ ; && *rental city (X18)
                   __gstate   +  ;        && *state (X2)
                   strtran(dtoc(date()),"/","") + ;  && *rental date MMDDYY
                   strtran(time(),":","") + ;        && *rental time HHMMSS
                   f_truncate(__gcity,18)+ ; && *rental city (X18)
                   __gstate   +  ;        && *state (X2)
                   strtran(dtoc(date()+val(yrdays)),"/","") + ; && *return date
                   strtran(time(),":","") + ;         && *return time
                   f_truncate("ON FILE",20) + ;       && *name (X20)
                   [000000]               && extra chg reason
            gccswipe = "M"      && manual enter
         endif

         if lrc (yblk + chr (03)) <> 0
            exit
         endif
         * 01/12/2000: depends on time to be different for lrc calculation
         inkey(1)
         * ypm5 = str(val(ypm5)+100,len(ypm5))    && reference # eg. 001, 123
      enddo

   case xtyp == "AMEX"
      xpm4 = strtran (xpm4, "/", "")
      do while .t.
         yblk = xpm1 + fs + xpm2 + xpm3 + fs + xpm4 + fs + alltrim (xpm5)
         if lrc (yblk + chr (03)) <> 0
            exit
         endif
         ydate = xpm4
         ymth = val (left (ydate, 2))
         yyr = val (right (ydate, 2))
         if ymth < 12
            ymth = ymth + 1
         else
            ymth = 1
            yyr = yyr + 1
         endif
         xpm4 = strtran (str (ymth * 100 + yyr, 4), " ", "0")
      enddo
   case xtyp == "I"               && incremental auth.
      * xpm1 : client #
      * xpm2 : merchant #
      * xpm3 : terminal #
      * xpm4 : serial #
      * xpm5 : [001]
      * xpm6 : org. authcode
      * xpm7 : cc #
      * xpm8 : cc exp. MMYY
      * xpm9 : []
      * xpm10: auth. amt.
      private yrdays
      yrdays = strtran (str(int (val(xpm10) / 20), 2), " ", "0")
      yrdays = if(yrdays="00", "01", yrdays)    && cannot be [00]
      yrdays = if(yrdays="**", "99", yrdays)    && 11.03.99
      do while .t.
         yblk = [K.]       +  ;
                [A02000]   +  ;
                substr(xpm1,1,4) + ;   && client #
                xpm2       +  ;        && merchant #
                xpm3       +  ;        && term #
                [1]        +  ;        && 1=> single, 2=> multi trans.
                [000]      +  ;        && filler always 000
                [001]      +  ;        && seq #
                [F]        +  ;        && F=>financial
                [08]       +  ;        && incremental auth.
                [2]        +  ;        && 1=> accept PIN, 2=> does not
                [02]       +  ;        && 02=> manual entered
                xpm7       +  ;        && cc #
                fs         +  ;
                strtran(xpm8, "/", "")  +  ;  && cc exp MMYY
                fs         +  ; 
                xpm10      +  ;        && auth amt
                fs         +  ;
                [00000000] +  ;        && filler
                fs         +  ;
                [A]        +  ;        && Auto Rental
                [Y]        +  ;        && manual entered
                yrdays     +  ;        && *duration of rental
                fs         +  ;
                fs         +  ;
                [005]      +  ;        && Auto Rental
                [00000.00] +  ;        && extra charge amt.
                [00000000] +  ;        && *ra # (X8)
                f_truncate(__gcity,18)+ ; && *rental city (X18)
                __gstate   +  ;        && *state (X2)
                strtran(dtoc(date()),"/","") + ;  && *rental date MMDDYY
                strtran(time(),":","") + ;        && *rental time HHMMSS
                f_truncate(__gcity,18)+ ; && *rental city (X18)
                __gstate   +  ;        && *state (X2)
                strtran(dtoc(date()+val(yrdays)),"/","") + ; && *return date
                strtran(time(),":","") + ;         && *return time
                f_truncate("ON FILE",20) + ;       && *name (X20)
                [000000]   + ;                     && extra chg reason
                fs         + ;
                racred->fauthcode       + ;        && *xpm6 org. authcode
                fs
         if lrc (yblk + chr (03)) <> 0
            exit
         endif
         * 01/12/2000: depends on time to be different for lrc calculation
         inkey(1)
         * ypm5 = str(val(ypm5)+100,len(ypm5))    && reference # eg. 001, 123
      enddo
   case xtyp == "R"               && reverse auth.
      * xpm1 : client #
      * xpm2 : merchant #
      * xpm3 : terminal #
      * xpm4 : serial #
      * xpm5 : [001]
      * xpm6 : org. authcode
      * xpm7 : cc #
      * xpm8 : cc exp. MMYY
      * xpm9 : []
      * xpm10: auth. amt.
      private yrdays
      yrdays = strtran (str(int (val(xpm10) / 20), 2), " ", "0")
      yrdays = if(yrdays="00", "01", yrdays)    && cannot be [00]
      yrdays = if(yrdays="**", "99", yrdays)    && 11.03.99
      do while .t.
         yblk = [K.]       +  ;
                [A02000]   +  ;
                substr(xpm1,1,4) + ;   && client #
                xpm2       +  ;        && merchant #
                xpm3       +  ;        && term #
                [1]        +  ;        && 1=> single, 2=> multi trans.
                [000]      +  ;        && filler always 000
                [001]      +  ;        && seq #
                [F]        +  ;        && F=>financial
                [09]       +  ;        && reverse auth.
                [2]        +  ;        && 1=> accept PIN, 2=> does not
                [02]       +  ;        && 02=> manual entered
                xpm7       +  ;        && cc #
                fs         +  ;
                strtran(xpm8, "/", "")  +  ;  && cc exp MMYY
                fs         +  ; 
                xpm10      +  ;        && auth amt
                fs         +  ;
                [00000000] +  ;        && filler
                fs         +  ;
                [A]        +  ;        && Auto Rental
                [Y]        +  ;        && manual entered
                yrdays     +  ;        && *duration of rental
                fs         +  ;
                fs         +  ;
                [005]      +  ;        && Auto Rental
                [00000.00] +  ;        && extra charge amt.
                [00000000] +  ;        && *ra # (X8)
                f_truncate(__gcity,18)+ ; && *rental city (X18)
                __gstate   +  ;        && *state (X2)
                strtran(dtoc(date()),"/","") + ;  && *rental date MMDDYY
                strtran(time(),":","") + ;        && *rental time HHMMSS
                f_truncate(__gcity,18)+ ; && *rental city (X18)
                __gstate   +  ;        && *state (X2)
                strtran(dtoc(date()+val(yrdays)),"/","") + ; && *return date
                strtran(time(),":","") + ;         && *return time
                f_truncate("ON FILE",20) + ;       && *name (X20)
                [000000]   + ;                     && extra chg reason
                fs         + ;
                racred->fauthcode       + ;        && *xpm6 org. authcode
                fs
         if lrc (yblk + chr (03)) <> 0
            exit
         endif
         * 01/12/2000: depends on time to be different for lrc calculation
         inkey(1)
         * ypm5 = str(val(ypm5)+100,len(ypm5))    && reference # eg. 001, 123
      enddo
   case xtyp = "HEADER1"
      * xpm1: client #
      * xpm2: merch #
      * xpm3: terminal #
      * xpm4: batch #
      * xpm5: total sales amt
      * xpm6: total return amt
      * xpm7: trans count
      yblk = [K.]        + ;
             [A02000]    + ;
             substr(xpm1,1,4) + ;   && client #
             xpm2        + ;     && merch #
             xpm3        + ;     && terminal #
             [1]         + ;     && 1=> single batch
             [000]       + ;     && filler
             [001]       + ;     && 000 thru 998
             [F]         + ;     && financial trans
             [51]        + ;     && Batch Release
             [000]+xpm4  + ;     && batch # (X6)
             [000]       + ;     && constant
             [0]         + ;     && current batch
             [000]+xpm7  + ;     && trans count
             alltrim (str (val (xpm5) - val (xpm6))) + ;   && net amount
             fs          + ;
             [RACWARE050199]+space(10) + ; && system info.
             fs          + ;
             [00000000]  
   case xtyp = "HEADER2"
      yblk = [K.]        + ;
             [A02000]    + ;
             substr(xpm1,1,4) + ;   && client #
             xpm2        + ;     && merch #
             xpm3        + ;     && terminal #
             [1]         + ;     && 1=> single batch
             [000]       + ;     && filler
             [001]       + ;     && 000 thru 998
             [F]         + ;     && financial trans
             [54]        + ;     && Batch Release
             [000]+xpm4  + ;     && batch # (X6)
             [000]       + ;     && constant
             [0]         + ;     && current batch
             [000]+xpm7  + ;     && trans count
             alltrim (str (val (xpm5) - val (xpm6))) + ;   && net amount
             fs          + ;
             [RACWARE050199]+space(10) + ; && system info.
             fs          + ;
             [00000000]  

   case xtyp = "TRAILER"
      yblk = [000]       + ;     && always
             [000]       + ;     && always
             [F]         + ;     && Financial trans
             [00000000]  + ;     && filler
             [55]                && Batch Upload Trailer

   case xtyp = "DETAIL"
      * xpm1: cc #
      * xpm2: trans type (F,S,C)
      * xpm3: auth amt
      * xpm4: cc type
      * xpm5: auth code
      * xpm6: seq #
      * xpm7: ra info.
      * xpm8: cc exp
      * xpm9: networkid + source
      if xpm2 = [F]       && force
         xpm2 = [03]
      elseif xpm2 = [C]   && return
         xpm2 = [06]
      else                && sale
         xpm2 = [01]
      endif
      do while .t.
         yblk = [000]        + ;   && constant
                xpm6         + ;   && seq #
                [F]          + ;   && constant
                [00000000]   + ;   && constant
                xpm2         + ;
                [A]          + ;   && A=> Actual, C=> Changed
                if(gccswipe="C", [01], [02])    + ;  && 01=> swipe, 02=>manual
                alltrim(xpm1)+ ;   && cc #
                fs           + ;
                xpm8         + ;   && *cc exp MMYY
                xpm3         + ;   && trans amt
                fs           + ;
                fs           + ;
                fs           + ;
                fs           + ;
                strtran (dtoc(date()), "/", "") + ;  && tran date MMDDYY
                strtran (time(), ":", "")       + ;  && tran time HHMMSS
                xpm5                            + ;  && auth code
                if(xpm4="VA", [VI], trim(xpm4)) + ;  && card type
                xpm9                            + ;  && *auth network id
                fs           + ;
                [A]          + ;   && Auto Rental
                if(gccswipe="C".or.xpm4="MC", [N], [Y]) + ;  && N=> swipe, Y=>manual
                [05]         + ;   && *duration of rental
                fs           + ;
                [005]        + ;   && 005=Auto rental
                xpm7         + ;   && industry specific data
                chr (30)           && rs
         if lrc (yblk + chr (3)) <> 0
            exit
         endif
         inkey (2)
      enddo
   endcase
endif

return yblk


****************************
function net_dial

parameters xamexdial
private yerror, yphone, ysec, yfld1, yfld2, n

? "Opening Modem Comm Port " + str (__gcomm, 1)
closecomm (__gcomm)
swdelay (10)
swuseport (__gcomm)

yerror = opencomm (__gcomm, __grbuff, __gxbuff)
if yerror <> 0
   ? "Comm Port Open Error: " + str (yerror, 2)
   closecomm (__gcomm)
   inkey (0)
   return yerror
endif
setbaud (__gcomm, if (xamexdial, gaxbaud, __gbaud), __gparity, __gstopbit, ;
   __gdatabit)
swdelay (10)

if gccnet = "NDC"
   yphone = __gphone
elseif gccnet = "LPA"
   if xamexdial
      yphone = if (empty (__gamexph1), __gamexph2, __gamexph1)
   else
      yphone = if (empty (__gphone), __gcompuph, __gphone)
   endif
endif

swdelay (10)

f_wtbox ("Initializing Modem...")

if statuscd (__gcomm)
   f_wtbox ("Aborted: Carrier Detect...")
   hangup ()
   closecomm (__gcomm)
   swdelay (10)
   txwclear (__gcomm)
   return 1
else
   txchar (__gcomm, chr (13))
   txchar (__gcomm, chr (13))
   txstring (__gcomm, "AT" + chr (13))      && 10/04/94  edc
   if .not. modem_resp ()
      f_wtbox ("Aborted: Modem Not Respond to AT...")
      closecomm (__gcomm)
      swdelay (10)
      txwclear (__gcomm)
      return 1
   endif
   swdelay (9)

   txchar (__gcomm, chr (13))
   txchar (__gcomm, chr (13))
   rxflush (__gcomm)
   txstring (__gcomm, alltrim (__ginitstr) + chr (13))
   swdelay (9)
   txwclear (__gcomm)
endif

if .not. modem_resp ()
   f_wtbox ("Modem Not Respond To Init Str")
   closecomm (__gcomm)
   swdelay (10)           
   txwclear (__gcomm)
   return 1
endif

f_wtbox ("Dialing Number " + alltrim (yphone))
txchar (__gcomm, chr (13))
txwclear (__gcomm)
swdelay (10)
txstring (__gcomm, "ATDT" + alltrim (yphone) + chr (13))
txwclear (__gcomm)

yerror = waitfor ("CONNECT")

if yerror <> 0
   txchar (__gcomm, chr (13))
   txchar (__gcomm, chr (13))
   hangup ()
   closecomm (__gcomm)
   swdelay (10)        
   txwclear (__gcomm)
   return yerror
endif

f_wtbox ("Connected...")
yerror = waitfor (enq, 5)        && 10/04/94  edc

return 0

******************************
function snd_recv

parameters xsndtype, xmessage, xresponse, xdispmess
private ytries, ylrc, ylrc1
if pcount () < 4
   f_wtbox ("Transmitting ...")
else
   f_wtbox ("Transmitting " + xdispmess + "...")
endif

ytries = 1
do while ytries <= 3
   send_message (xmessage)
   do case
   case (xsndtype + ";") $ "N1;N2;N3;L1;"
      yerror = waitfor (ack)
   case (xsndtype + ";") $ "SG;BT;L2;H1;"     && new type H1: Header1
      yerror = waitfor (stx)
   endcase
   if chr (yerror) = nak
      f_wtbox ("NAK: Re-Transmitting...")
      ytries = ytries + 1
      loop
   endif
   if yerror <> 0
      f_wtbox ("Aborted: Error in Trans..." + str (yerror))
   endif
   exit
enddo

if yerror <> 0
   if ytries > 3
      f_wtbox ("Aborted: Too Many NAK's")
   endif
   hangup ()
   closecomm (__gcomm)
   swdelay (10)
   return yerror
endif

do case
case xsndtype = "L1"
   return 0
endcase

f_wtbox ("Receiving...")

ytries = 1
do while ytries <= 3
   do case
   case (xsndtype + ";") $ "N1;N2;"
      yerror = waitfor (enq)
      if yerror = 0
         return 0
      endif
   case (xsndtype + ";") $ "N3;SG;BT;L2;"
      yerror = get_comm (@xresponse, etx)
   case (xsndtype + ";") $ "H1;"           && 05.01.99
      yerror = get_comm (@xresponse, etx)
   endcase
   if yerror <> 0
      f_wtbox ("Aborted: Time Out on Receiving...")
      debug_disp ("GetAuth Error in Receiving " + xresponse)
      hangup ()
      closecomm (__gcomm)
      swdelay (10)
      return yerror
   endif

   swdelay (9)
   ylrc = rxchar (__gcomm)
   xresponse = strtran (xresponse, stx, "")
   ylrc1 = lrc (xresponse)
   if ylrc1 = ylrc
      debug_disp ("LRC of response GOOD... Unbelievable!")
      exit
   else
      debug_disp ("LRC Not Matched...")
      debug_disp ("Response = " + xresponse)
      debug_disp ("LRC ERROR Calc LRC = " + str (ylrc) + "   Host LRC=  " ;
         + str (ylrc1))
      debug_disp ("Sending NAK")
      txchar (__gcomm, nak)
      swdelay (9)
   endif

   ytries = ytries + 1
enddo

if ytries > 3
   f_wtbox ("Aborted: Not Many NAK's in Receiving...")
   debug_disp ("Aborted: Not Many NAK's in Receiving...")
   hangup ()
   closecomm (__gcomm)
   swdelay (10)
   return yerror
endif

xresponse = left (xresponse, len (xresponse) - 1)

txwclear (__gcomm)
txchar (__gcomm, ack)
do case
case xsndtype = "SG;L2;"
   yerror = waitfor (eot, 1)
case (xsndtype + ";") $ "N3;BT;"
   yerror = waitfor (enq, 1)
case xsndtype = "H1"
   * if header 1 is accepted, the host will always return a [A 901]
   if [A 901] $ xresponse     
      yerror = waitfor (enq)
      return yerror
   else
      f_wtbox ("Error: "+substr(xresponse, 1, 60))
      debug_disp ("Error: "+substr(xresponse, 1, 60))
      hangup ()
      closecomm (__gcomm)
      swdelay (10)
      return -1
   endif
endcase

return 0

******************************
function send_message

parameters xstr, xlrc
xstr = xstr + etx
xlrc = lrc (xstr)
xstr = xstr + chr (xlrc)

debug_disp ("Message Sending: " + xstr + " LRC = " + str (xlrc))
if xlrc = 0
   debug_disp ("Warning: Lrc Calculated to 0")
   debug_disp ("Message = " + xstr)
endif
txwclear (__gcomm)
swdelay (12)
xstr = stx + xstr
txstring (__gcomm, xstr)
swdelay (12)
txwclear (__gcomm)
debug_disp ("Message Sent: " + xstr)

******************************
function good_card

parameters xccnum, xcctype
private ysel, yrange, yfil

ysel = select ()

* f_use ("RACC")
yfil = gdbfpath + "racc"
select 0
use &yfil alias racc

yrange = val (left (xccnum, 3))
locate for frange1 <= yrange .and. frange2 >= yrange

do while .not. eof ()
   if len (alltrim (xccnum)) <> flength .and. flength <> 0
      continue
   elseif fchecktype = "MOD10" .and. .not. mod10 (xccnum)
      continue
   else
      xcctype = fcardtype
      exit
   endif
enddo

if eof ()
   xcctype = "   "
endif
use
select (ysel)
return .not. empty (xcctype)


******************************
function mod10

parameters xccnum
private y, ycard, ysum, ycnt

ycard = ""
ycnt = 0
for y = len (alltrim (xccnum)) to 1 step -1
   if ycnt = 0
      ycard = ycard + substr (xccnum, y, 1)
      ycnt = 1
   else
      ycard = ycard + alltrim (str (val (substr (xccnum, y, 1)) * 2))
      ycnt = 0
   endif
next

ysum = 0
for y = 1 to len (ycard)
   ysum = ysum + val (substr (ycard, y, 1))
next

return ((ysum/10) = int (ysum/10))

******************************
function get_comm

parameters xstr, xdelim, xonline
private ychar, ysec, ykey

ychar = ""
xstr = ""
ytries = 0

ysec = seconds () + __gtimeout

if pcount () < 3
   xonline = statuscd (__gcomm)
endif

do while ychar <> xdelim
   if rxcount (__gcomm) > 0
      if ysec > seconds ()
         ychar = chr (rxchar (__gcomm))
         xstr = xstr + ychar
      else
         debug_disp ("Get_comm Error: Timeout")
         return -89
      endif
   elseif xonline .and. .not. statuscd (__gcomm)
      debug_disp ("Get_comm: Carrier Loss Aborting")
      return -9
   endif

   ykey = inkey ()
   if ykey <> 0
      return ykey
   endif
enddo

debug_disp ("Get_comm Recieved: " + xstr)
return 0

*************************************
function f_mkbox

parameters xmess
? xmess


******************************
function f_rmbox

parameters xscn


******************************
function f_wtbox

parameters xmess

xmess = alltrim (xmess)
? xmess


******************************
function swuseport

parameters xport

if xport = 2
   swsetdev (xport, 1000, 4)
elseif xport = 3
   swsetdev (xport, 744, 3)
endif


******************************
function txwclear

parameters xport

do while .t.
   if txcount (xport) <= 0
      exit
   endif
enddo

******************************
function hangup

private yerror, ykey

do while statuscd (__gcomm)
   debug_disp ("Carrier Detect... Attempting Hangup...")
   smescape (__gcomm)
   txstring (__gcomm, "AT H0" + chr (13))
   txwclear (__gcomm)
   if statuscd (__gcomm)
      yerror = waitfor ("OK", 7)
      if yerror = 27
         debug_disp ("Aborting Hangup")
         return (yerror)
      endif
      if yerror = 0
         debug_disp ("Hangup OK")
         return 0
      endif
   endif
enddo

txchar (__gcomm, chr(13))
txchar (__gcomm, chr(13))

debug_disp ("No Carrier. Force Hangup OK")
return 0

*******************************
function getccsetup

parameter xloc
private xsel, yfil

xsel = select ()

* f_use ("RASTN")

yfil = gdbfpath + "rastn"
select 0
use &yfil index &yfil alias rastn
seek f_truncate (gstation, 8)
__ginitstr = finitstr
__gmodem = upper(trim(fmodem))
__gcomm = fcomm
__gbaud = fbaud
__gtimeout = ftimeout
use

* f_use ("RACCSU")

yfil = gdbfpath + "raccsu"
select 0
use &yfil index &yfil alias raccsu
seek xloc
if eof ()
   use
   select (xsel)
   return .f.
endif
for n = 1 to fcount ()
   yfld1 = field (n)
   yfld2 = "__g" + substr (yfld1, 2)
   &yfld2 = &yfld1
next
if gccnet = "LPA"
   __gmerch = left (__gmerch, 12)
endif
use

if gccnet = "LPA"
   __gccsale = "54"
   __gccforce = "54"
   __gcccredit = "5"
elseif gccnet = "NDC"
   __gccsale = "10"
   __gccforce = "19"
   __gcccredit = "17"
   __gccvoid = "18"
endif
select (xsel)
return .t.

******************************
function f_truncate

parameters xstr, xlen

return left (xstr + replicate (" ", xlen), xlen)

******************************
function f_rd

set cursor on
read
set cursor off
return lastkey ()


return (0)


