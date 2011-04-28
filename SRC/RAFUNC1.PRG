* ===========================================================================
* this is the utility routine for racware credit card communication.
*
* date: 05/01/91
* author: KST
*
* revision
* date: 07/14/92
* edc: change tformat to indicate the trans. was swipped 
* date: 05/26/93 
* edc: change tformat to indicate read from card reader during authorization 
* date: 08/30/93
* edc: get_card - get track 1 credit card info.
*      obtain info. between (not including) %xxxxxxxxxxxxxxxxxxxxxxx?
* date: 08/15/94
* edc: correct lrc = 0 in tformat
* date: 11/01/96
* edc: modem_send - add ccp central dialing
* 05.01.99: implement Paymentech UTF
* edc: tformat
*      auth_ok
* 05.03.07: use gccpath for CCTRAN.DBF (see RINIT)
*
* 02.11.08: Force user to swipe card again (See get_card)
* ---------------------------------------------------------------------------
* 02.20.09: filter [!] in gtrack preceeding expiration date (see get_card)
* ===========================================================================
* function modem_resp ::= check if the command send to the modem gets an OK.
* return .t. if the computer receives an OK.
* 
* function waitfor ::= wait for a response from the modem.
* parameters xstr ::= the response that the computer is waiting for.
*            xtime ::= the time limit in seconds.
* 
* function debug_disp ::= if cclog is set to "Y", write the character string
*                         to cclog.dbf in station directory.
* parameters xstr ::= the character string to be written.
* 
* function get_card ::= get the credit card information from a credit card
*                       swipe.
* parameters xccnum ::= the return value for the credit card number (passed
*                       by reference)
*            xlname ::= the return last name for the credit card holder 
*                       (passed by reference)
*            xfname ::= the return first name for the credit card holder 
*                       (passed by reference)
*            xccexp ::= the return expired date for the credit card holder 
*                       (passed by reference)
* return .t. if credit card is read successfully.
* 
* function good_card ::= check if the credit card is a good number.
* parameters xccnum ::= the credit card number
*            xcctype ::= the return credit card (passed by reference)
* return .t. if the credit card number is valid.
* 
* function mod10 ::= a function used to verify credit card number.
* parameters xccnum ::= the credit card number to be tested.
* 
* function good_cctype ::= a function to test if a credit card is good.
* parameters xcctype ::= the credit card type to be tested.
*            xauthonly ::= the return value of whether the card is authorized
*                          only.  (passed by reference)
* 
* function newauth ::= to get a new authorization with user interface.
* parameters xtranstyp ::= the transaction type, S, F or C.
*            xccnum ::= the credit card number.
*            xccexp ::= the credit card expired date.
*            xauthamt ::= the amount to authorize.
*            xauthcode ::= the return authorization card. (passed by 
*                          reference)
*            xauthstat ::= the return message from the credit card 
*                          network. (passed by reference)
* 
* function auth_ok ::= check if the return message from the credit card
*                      network has the authorization code or error.
* parameters xstring ::= the message from the credit card network.
*            xauthcode ::= the return authorized code (passed by reference)
* 
* function tformat ::= to format the message to be send to the credit card
*                      network.
* parameters xtyp ::= the transaction type. S, F or C
*            xpm1, xpm2, xpm3, xpm4, xpm5, xpm6, xpm7, xpm8, xpm9, xpm10:
*                     the parameter depend on what transaction type it is.
* 
* function get_auth ::= to get a new authorization with user interface.
* parameters xtranstyp ::= the transaction type, S, F or C.
*            xccnum ::= the credit card number.
*            xccexp ::= the credit card expired date.
*            xauthamt ::= the amount to authorize.
*            xauthcode ::= the return authorization card. (passed by 
*                          reference)
*            xauthstat ::= the return message from the credit card 
*                          network. (passed by reference)
* 
* function modem_error ::= return the description of the silver comm 
*                          error code.
*
* function lrc ::= a xor function for communication error checking.
* parameters xstr ::= the string to calculate the xor value.
* 
* function modem_send ::= a function to dial out and send a message to 
*                         the credit card network and get a response.
* parameters xmessage ::= the message to be send.
*            xresponse ::= the response returned from the credit card
*                          network (passed by reference)
* 
* function send_message ::= the function that calculate the lrc value
*                           and format the message with stx and lrc and
*                           send the message out.
* parameters xstr ::= the message to be sent out.
*            xlrc ::= the return lrc value (passed by reference)
* 
* function get_comm ::= wait for a char from the modem and return the
*                       the character string received before the char.
* parameters xstr ::= the character received (passed by reference)
*            xdelim ::= the delimitor to wait for.
*            xonline ::= whether the phone line is connected.
* 
* function hangup ::= to hang up the modem.
* 
* function net_dial ::= the function to dial to the network.
* parameters xamexdial ::= whether it's is american express authorization.
* 
* function snd_recv ::= the function to send a message and wait for a 
*                       response
* parameters xsndtype ::= the send type. send auth, batch auth or capture.
*            xmessage ::= the message to be sent
*            xresponse ::= the response received from the network.
*            xdispmess ::= optional.
*                          the message to be display on the screen.
* 
* function f_mkbox ::= make a popup window on the screen.
* parameters xmess ::= the title of the window.
* 
* function f_rmbox ::= remove the window.
* 
* function f_wtbox ::= write centralized message on the screen.
* parameters xmess ::= the message to be written on the screen.
* 
* function swuseport ::= special setup of comm 3 or 4.
* parameters xport ::= the comm port to use.
* 
* function txwclear ::= wait until the send out buffer to be cleared.
* parameters xport ::= the comm port to use.
* 
* function getccsetup ::= get credit card and merchant setup information.
* parameter xloc ::= the location of the merchant information.
* ******************************

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
function get_card

parameters xccnum, xlname, xfname, xccexp
private yccinfo, ycolor, yscn, ycardinfo, ypos, yans
private yccnum, ylname, yfname, yccexp, ylccnum, yllname, ylfname

gccinfo = ""        && 05/26/93 (edc)
yccinfo = ""        && 03.04.08

if gccreader = 0
   return .f.
endif
set cursor off
ylccnum = len (xccnum)
yllname = len (xlname)
ylfname = len (xfname)
yccnum = space (ylccnum)
ylname = space (yllname)
yfname = space (ylfname)
yccexp = space (4)

ycolor = setcolor (gsubcolor)
yscn = f_box (10, 17, 14, 38 + max (ylccnum, yllname + ylfname + 1))
@ 11, 19 say "Card Number.... "
@ 12, 19 say "Card Expired... "
@ 13, 19 say "Card Holder.... "

do while .t.
   f_popup ("Please Swipe Card...")
   ycardinfo = card_read  ()
   f_popback ()
   if .not. empty (ycardinfo)
      if left (ycardinfo, 1) = chr (27)
         set cursor on
         setcolor (ycolor)
         f_restbox (yscn)
         return .f.
      endif
      * 08/30/93
      * obtain track 1 info. - %xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx?
      * (ie. track 2 info comes after ? sign)
      ypos = at('%',ycardinfo)
      if ypos > 0
         yccinfo = substr(ycardinfo,ypos+1,at('?', ycardinfo)-ypos-1)
         * 02.20.09: exp date 
         yccinfo = strtran(yccinfo,"!","")
      else
         f_popup ("Please Swipe Card Again, press any key to continue...",.t.)
      endif
      if gccreader = 1
         ypos = 3
      else
         ypos = 2
      endif
      ypos = f_parse (ycardinfo, @yccnum, ypos, asc ("^"), ylccnum)
      ypos = f_parse (ycardinfo, @ylname, ypos, asc ("/"), yllname)
      ypos = f_parse (ycardinfo, @yfname, ypos, asc ("^"), ylfname)
      f_parse (ycardinfo, @yccexp, ypos, 13, 4)
      yccexp = f_truncate (yccexp, 4)
      yccexp = right (yccexp, 2) + left (yccexp, 2)
      yccnum = f_truncate (strtran (yccnum, " ", ""), ylccnum)

      ylname = transform (f_truncate (ltrim (ylname), yllname), ;
         "!" + replicate ("X", yllname - 1))
      yfname = transform (f_truncate (ltrim (yfname), ylfname), ;
         "!" + replicate ("X", ylfname - 1))
      @ 11, 35 say yccnum
      @ 12, 35 say stuff (yccexp, 3, 0, "/")
      @ 13, 35 say trim (yfname) + " " + ylname
   * ---- 02.11.08: swipe card again
      if empty(ylname) .or. empty(yfname) .or. yccexp < [0000] .or. yccexp > [9999]
         yans = f_confirm ("[V]oid   [R]etry", "VR")
      else
         yans = f_confirm ("[C]onfirm   [V]oid   [R]etry", "CVR")
      endif
   else
      yans = "V"
   endif
   if yans = "R"
      loop
   endif
   f_restbox (yscn)
   setcolor (ycolor)
   set cursor on
   if yans = "C"
      xlname = ylname
      xfname = yfname
      xccnum = yccnum
      xccexp = stuff (yccexp, 3, 0, "/")
      gccinfo = yccinfo          && 03.04.08
      return .t.
   elseif yans = "V"
      return .f.
   endif
enddo


******************************
function good_card

parameters xccnum, xcctype
private ysel, yrange

ysel = select ()
f_use ("RACC")

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
function good_cctype

parameters xcctype, xauthonly
private ycard, ysel

ycard = .f.
ysel = select ()
f_use ("RAPAYTYP")
locate for fpaycode = xcctype
if .not. eof ()
   ycard = fcard
   xauthonly = fauthonly
endif
use
select (ysel)
return ycard


******************************
function newauth

parameters xtranstyp, xccnum, xccexp, xauthamt, xauthcode, xauthstat
private yret, yerror

if .not. gccmodem .or. empty (gccnet)
   return "F"
endif
if .not. getccsetup ()
   return "F"
endif

if .not. (xtranstyp = "F" .and. gccnet = "NDC")
   xauthcode = space (6)
endif

xauthstat = space (30)
if f_confirm ("[D]ial Out For Approval   [F]ill in Auth. #", "DF") = "D"
   do while .t.
      if get_auth (xtranstyp, xccnum, xccexp, xauthamt, @xauthcode, ;
            @xauthstat) = 0
         if f_valid (auth_ok (xauthstat, @xauthcode), ;
               "Warning!!! Credit Card Authorization Is Rejected!!!")
            yret = "D"
         else
            yret = "E"
         endif
         exit
      else
         yret = f_confirm ("[R]etry   [F]ill in Auth. #", "RF")
         if yret <> "R"
            exit
         endif
      endif
   enddo
else
   yret = "F"
endif
return yret


******************************
function auth_ok

parameters xstring, xauthcode
private yauth_ok, ystring

xauthcode = space (6)

yauth_ok = .f.
if gccnet = "LPA"
   * 05.01.99: NEW AUTH. RESPONSE
   * if left (xstring, 2) $ "AA AV AT"
   *    yauth_ok = .t.
   *    xauthcode = substr (xstring, 3, 6)
   * elseif xstring = "APPROVED"
   *    yauth_ok = .t.
   *    xauthcode = substr (xstring, 10, 2)
   * endif
   if substr(xstring,1,1) = [A]
      yauth_ok = .t.
      xauthcode = substr(xstring, 3, 6)
   endif
elseif gccnet = "NDC"
   if substr (xstring, 2, 2) $ "AP AI"
      yauth_ok = .t.
      xauthcode = substr (xstring, 4)
   elseif left (xstring, 2) $ "AP AI OK"
      yauth_ok = .t.
      if substr (xstring, 3, 1) = chr (28)
         xauthcode = substr (xstring, 4, 6)
      else
         xauthcode = substr (xstring, 3, 6)
      endif
   endif
endif
xauthcode = f_truncate (strtran (xauthcode, chr (28), ""), 6)
return yauth_ok


******************************
function tformat

parameters xtyp, xpm1, xpm2, xpm3, xpm4, xpm5, xpm6, xpm7, xpm8, xpm9, xpm10
private ypm5, yblk, yblk1, yblk2, yfs, ycs, ydate, ymth, yyr, ytranstyp
fs = chr (28)
cs = ","

if gccnet = "NDC"
   do case
   case (xtyp + ";") $ "S;C;V;"
      xpm3 = alltrim (strtran (xpm3, "/", ""))
      if xtyp == "S"
         xtranstyp = __gccsale
      elseif xtyp == "C"
         xtranstyp = __gcccredit
      elseif xtyp == "V"
         xtranstyp = __gccvoid
      endif
      do while .t.
         yblk = alltrim (xpm1) + fs + "H" + xtranstyp + fs + ;
            alltrim (xpm2) + fs + xpm3 + fs + alltrim (xpm4)
         if lrc (yblk + chr (03)) <> 0
            exit
         endif
         ydate = xpm3
         ymth = val (left (ydate, 2))
         yyr = val (right (ydate, 2))
         if ymth < 12
            ymth = ymth + 1
         else
            ymth = 1
            yyr = yyr + 1
         endif
         ypm3 = strtran (str (ymth * 100 + yyr, 4), " ", "0")
      enddo

   case xtyp == "F"
      xpm3 = alltrim (strtran (xpm3, "/", ""))
      do while .t.
         yblk = alltrim (xpm1) + fs + "L" + __gccforce + fs + ;
            alltrim (xpm2) + fs + xpm3 + fs + alltrim (xpm4) + fs + ;
            alltrim (xpm5)
         if lrc (yblk + chr (03)) <> 0
            exit
         endif
         ydate = xpm3
         ymth = val (left (ydate, 2))
         yyr = val (right (ydate, 2))
         if ymth < 12
            ymth = ymth + 1
         else
            ymth = 1
            yyr = yyr + 1
         endif
         xpm3 = strtran (str (ymth * 100 + yyr, 4), " ", "0")
      enddo

   case xtyp == "DB"
      do case
      case xpm3 = "F"
         xpm3 = __gccforce
      case xpm3 = "C"
         xpm3 = __gcccredit
      case xpm3 = "S"
         xpm3 = __gccsale
      endcase
      yblk = alltrim (xpm1) + cs + alltrim (xpm2) + cs + alltrim (xpm3) + ;
         cs + alltrim (xpm4) + cs + alltrim (xpm5) + cs + alltrim (xpm6)

   case xtyp == "FB"
      yblk = alltrim (xpm1) + fs + "l10" + fs + alltrim (xpm2) + fs + ;
         alltrim (xpm3) + fs + alltrim (xpm4) + fs + alltrim (xpm5) + fs + ;
         alltrim (xpm6) + fs + alltrim (xpm7)

   case xtyp == "IB"
      yblk = alltrim (xpm1) + fs + "l10" + fs + alltrim (xpm2)

   case xtyp == "LB"
      yblk = alltrim (xpm1) + fs + "l11" + fs + alltrim (xpm2) + fs + ;
         alltrim (xpm3) + fs

   case xtyp == "FOB"
      yblk = alltrim (xpm1) + fs + "l11" + fs + alltrim (xpm2) + fs + ;
         alltrim (xpm3) + fs + alltrim (xpm4) + fs + alltrim (xpm5) + fs + ;
         alltrim (xpm6) + fs + alltrim (xpm7) + fs + alltrim (xpm8) + fs

   endcase

else
   do case
   case xtyp == "S"
      * xpm8 = alltrim (strtran (xpm8, "/", ""))
      * ypm5 = xpm5
      * do while .t.
      *  05/26/93 (edc): change to get authorization indicating card reader
      *    if alltrim(xpm7) $ gccinfo       && if the card is swiped, ie. acct # equals 
      *       yblk = "F." + xpm1 + xpm2 + xpm3 + alltrim (xpm4) + "1" + ypm5 + ;
      *         "@" + "T" + gccinfo + fs +  ;
      *         alltrim (xpm9) + fs + strtran (alltrim (xpm10), ".", "") + fs + ;
      *         __gccsale + fs + "00"
      *       gccswipe = "C"      && card read
      *    else
      *       yblk = "F." + xpm1 + xpm2 + xpm3 + alltrim (xpm4) + "0" + ypm5 + ;
      *         "@" + "@" + alltrim (xpm7) + fs + xpm8 + fs + ;
      *         alltrim (xpm9) + fs + strtran (alltrim (xpm10), ".", "") + fs + ;
      *         __gccsale + fs + "00"
      *       gccswipe = "M"      && manual enter
      *   endif
      * 05.01.99
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

   * ** old format **
   * case xtyp = "HEADER" .or. xtyp = "TRAILER"
   *    do while .t.
   *       yblk = "F." + xpm1 + xpm2 + xpm3 + fs + "2" + fs + "999" + xpm4 + ;
   *          strtran (time (), ":", "") + strtran (dtoc (date ()), "/", "") + ;
   *          fs + xpm7 + fs + xpm5 +fs + xpm6 + fs + ;
   *          alltrim (str (val (xpm5) - val (xpm6))) + fs + ;
   *          substr (__gamex, 3) + fs + "501" + fs + ;
   *          if (xtyp = "HEADER", "10", "19")
   *       if lrc (yblk + chr (03)) <> 0
   *          exit
   *       endif
   *       inkey (2)
   *   enddo

   case xtyp = "DETAIL"
      *do case
      *case xpm2 $ "FS"
      *   xpm2 = "1"
      *case xpm2 = "C"
      *   xpm2 = "5"
      *endcase
      *do while .t.
      *   yblk1 = xpm1 + xpm2 + xpm3
      * data source: 1=card
      *              2=manual
      *   if gccswipe = "C"       && 11/11/93 (edc) for card swipe
      *      yblk2 = if (alltrim (xpm4) = "VA", "VI", alltrim (xpm4)) + xpm5 + ;
      *         "31" + strtran (time (), ":", "") + ;
      *         strtran (dtoc (date ()), "/", "") + "11" + xpm7
      *   else
      *      yblk2 = if (alltrim (xpm4) = "VA", "VI", alltrim (xpm4)) + xpm5 + ;
      *         "32" + strtran (time (), ":", "") + ;
      *         strtran (dtoc (date ()), "/", "") + "11" + xpm7
      *   endif

      *   yblk = "F005" + xpm6 + strtran (str (len ("F005" + xpm6 + yblk1 + ;
      *      "A" + yblk2) + 3, 3), " ","0") + yblk1 + "C" + yblk2

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


******************************
function get_auth

parameters xtranstyp, xccnum, xccexp, xauthamt, xauthcode, xauthstat
private yamexdial, yterm_id, ysec, yerror, ymessage, ycardtype
private y1, y2, y3, y4

set cursor off
if .not. gccmodem .or. empty (gccnet)
   return 0
endif
if .not. getccsetup ()
   return 0
endif

yamexdial = .f.
ycardtype = space (3)

yerror = 0
ysec = seconds () + 60.0
xauthstat = space (30)
xauthamt = abs (round (xauthamt, 2))

if gccnet = "NDC"
   yterm_id = __gprefix + alltrim (__gica) + alltrim (__gmerch)
   do case
   case (xtranstyp + ";") $ "S;C;V;"
      ymessage = tformat (xtranstyp, yterm_id, xccnum, xccexp, ;
         alltrim (str (xauthamt)))
   case xtranstyp = "F"
      ymessage = tformat ("F", yterm_id, xccnum, xccexp, ;
         alltrim (str (xauthamt)), xauthcode)
   otherwise
      return 0
   endcase
elseif gccnet = "LPA"
   good_card (xccnum, @ycardtype)
   if alltrim (ycardtype) == "AX" .and. .not. empty (__gamexph1 + __gamexph2)
      xtranstyp = "AMEX"
      yamexdial = .t.
   endif

   do case
   case xtranstyp = "S"
      ymessage = tformat ("S", __gcompuid, __gmerch, __gtermid, __gserial, ;
        "001", "@", xccnum, xccexp, "", alltrim (str (xauthamt)))
   case xtranstyp = "C"
      ymessage = tformat ("S", __gcompuid, __gmerch, __gtermid, __gserial, ;
         "001", "@", xccnum, xccexp, "", alltrim (str (xauthamt)))
   case xtranstyp = "F"
      ymessage = tformat ("S", __gcompuid, __gmerch, __gtermid, __gserial, ;
         "123", "@", xccnum, xccexp, "", alltrim (str (xauthamt)))
   case xtranstyp = "I"      && 06.28.99 incremental
      ymessage = tformat ("I", __gcompuid, __gmerch, __gtermid, __gserial, ;
         "123", "@", xccnum, xccexp, "", alltrim (str (xauthamt)))
   case xtranstyp = "R"      && 06.28.99 reversal
      ymessage = tformat ("R", __gcompuid, __gmerch, __gtermid, __gserial, ;
         "123", "@", xccnum, xccexp, "", alltrim (str (xauthamt)))
   case xtranstyp = "AMEX"
      ymessage = tformat ("AMEX", __gamex, "@", xccnum, xccexp, ;
         alltrim (str (xauthamt)))
   otherwise
      return 0
   endcase
endif

do while yerror <> 27
   yerror = modem_send (ymessage, @xauthstat)
   if yerror = 0
      if gccnet = "LPA"
         * 05.01.99: new auth format
         * if yamexdial
         *    xauthstat = alltrim (xauthstat)
         * else
         *    xauthstat = alltrim (substr (xauthstat, 15, 8) + " " + ;
         *       substr (xauthstat, 29))
         * endif
         * parse auth. stat to get auth code, network id & source
         y1 = substr (xauthstat,1,8)      && auth code [A 090140]
         y2 = at (chr(28), xauthstat)     && locate 1st fs
         y4 = []
         if y2 > 0                        && locate 2nd fs
            y3 = at (chr(28), substr(xauthstat, y2+1))
            if y3 > 0
               y4 = substr(xauthstat, y2+y3+1, 3)
            endif
         endif
         xauthstat = upper(y1 + [ ] + y4)
      endif
      exit
   else
      if f_popup (modem_error (yerror) + ;
            " Press ENTER To Retry or ESC to quit...", .t.) = 27
         exit
      endif
   endif
enddo

return yerror


******************************
function modem_error

parameters yresponse
do case
case yerror = 27
   yresponse = "User Abort"
case yerror = -89
   yresponse = "Modem Time Out"
case yerror = 1
   yresponse = "Modem Not Responding"
case yerror = 2
   yresponse = "ENQ Received"
case yerror = 3
   yresponse = "STX Recieved"
case yerror = 4
   yresponse = "LRC Check Failed"
case yerror = 5
   yresponse = "Too Many Errors"
case yerror = 6
   yresponse = "EOT Received"
case yerror = 7
   yresponse = "ETX Received"
case yerror = 8
   yresponse = "Line Busy"
case yerror = 9
   yresponse = "Carrier Loss"
case yerror = 10
   yresponse = "No Dialtone"
otherwise
   yresponse = "Unknown Modem Error"
endcase

return yresponse


******************************
function lrc

parameters xstr
return swcalcxorb (xstr, len (xstr))


******************************
function modem_send

parameters xmessage, xresponse
private yfil, yerror, ykey, ycolor, yscn
private xsel, ysec, yphone

etx = chr (03)
enq = chr (05)
ack = chr (06)
eot = chr (04)
stx = chr (02)
nak = chr (21)
fs  = chr (28)

ycolor = setcolor (gsubcolor)
yscn = f_mkbox ("Communication Port Status")
xresponse = "User Abort"

if __gmodem = [SYSTEM]        && use centralize dial
   * 11/01/96:
   if .not. file (gccpath+"cctran.dbf")
      f_wtbox ("Cannot Open CC Trans...")
      return -1
   endif
   xsel = select ()
   yfil = gccpath+"cctran"
   select 0
   use &yfil alias cctran
   go __gtimeout              && setup in merchant/modem setup
   if eof ()
      f_wtbox ("Invalid Timeout value...")
      yerror = -1
   else
      reclock ()
      replace fmsg with xmessage, fresponse with "", fstat with 0
      commit 
      unlock
      f_wtbox ("Please Wait While Processing...")
      do while .t.
         ykey = inkey(1)      && check result every 1 second
         if ykey = 27
            reclock ()
            replace fmsg with ""
            commit
            unlock
            f_wtbox ("User Abort...")
            inkey (0)
            setcolor (ycolor)
            f_rmbox (yscn)
            yerror = -1
            exit
         endif
         go __gtimeout
         xresponse = fresponse
         if .not. empty(xresponse)
            reclock ()
            replace fmsg with ""
            commit
            unlock
            yerror = 0
            f_wtbox ("Transaction Complete...")
            inkey (1)
            f_wtbox (xresponse)
            inkey (0)
            setcolor (ycolor)
            f_rmbox (yscn)
            exit
         endif
      enddo
   endif
   select cctran
   use
   select (xsel)
   return yerror
   *
else
   yerror = net_dial (yamexdial)
   if yerror <> 0
      hangup ()
      closecomm (__gcomm)
      swdelay (10)
      setcolor (ycolor)
      f_rmbox (yscn)
      return yerror
   endif
   
   yerror = snd_recv ("SG", xmessage, @xresponse)
   if yerror <> 0
      hangup ()
      closecomm (__gcomm)
      swdelay (10)
      setcolor (ycolor)
      f_rmbox (yscn)
      return yerror
   endif
   f_wtbox ("Hanging Up...")
   hangup ()
   closecomm (__gcomm)
   f_wtbox ("Transaction Complete...")
   inkey (2)
   f_wtbox (xresponse)
   inkey (0)
   setcolor (ycolor)
   f_rmbox (yscn)
   return 0
endif

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


******************************
function net_dial

parameters xamexdial
private yerror, yphone, ysec, yfld1, yfld2, n

f_wtbox ("Opening Modem Comm Port " + str (__gcomm, 1))
closecomm (__gcomm)
swdelay (10)
swuseport (__gcomm)

yerror = opencomm (__gcomm, __grbuff, __gxbuff)
if yerror <> 0
   f_wtbox ("Comm Port Open Error: " + str (yerror, 2))
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

f_wtbox ("Initializing Modem")

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
   * txstring (__gcomm, "ATZ" + chr (13))
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
*if yerror <> 0
*   f_wtbox ("Aborted: Error Waiting for ENQ")
*   hangup ()
*   closecomm (__gcomm)
*   swdelay (10)
*   txwclear (__gcomm)
*   return yerror
*endif

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
function f_mkbox

parameters xmess
return f_box (3, 9, 7, 70, xmess)


******************************
function f_rmbox

blimempak (-1)
parameters xscn
f_restbox (xscn)
blimempak (-1)


******************************
function f_wtbox

parameters xmess
private ylen, yspace
xmess = alltrim (xmess)
ylen = len (xmess)
if ylen > 58
   xmess = left (xmess, 58)
endif
yspace = int ((58 - ylen) / 2)
@ 5, 11 say space (yspace) + xmess + space (58 - ylen - yspace)


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
function getccsetup

parameter xloc
private xsel

if empty (gccnet)
   return .f.
endif

if pcount () < 1
   xloc = gloc
endif

xsel = select ()
f_use ("RASTN")
seek f_truncate (gstation, 8)
__ginitstr = finitstr
__gmodem = upper(trim(fmodem))
__gcomm = fcomm
__gbaud = fbaud
__gtimeout = ftimeout
use
if .not. f_valid (.not. empty (__ginitstr), "Station Modem Setup Not Found!")
   select (xsel)
   return .f.
endif

f_use ("RACCSU")
seek xloc
if .not. f_valid (found (), "Location Merchant Setup Not Found!")
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
