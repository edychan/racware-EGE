*
* reservation retrieval system - receiver program
*
f_clrscn ("Dollar Rent a Car - Reservation Retreival System")

* for Budget res system  defined in RASYS.DBF
* gcomm = 0
* grbuff = 1030
* gxbuff = 1030
* gbaud = 1200
* gparity = 2         && even parity
* gstopbit = 1
* gwordlen = 7


closecomm (gcomm)

do while .t.
  if txcount (gcomm) <= 0 
    exit  
  endif 
enddo

do while .t.

  yerror = opencomm (gcomm, grbuff, gxbuff)

  if yerror <> 0
    f_valid (.f.,"Error: Unable to initialize communication port ...")
    do rresr1
    do rresr2
    return 
  endif

  yerror = setbaud (gcomm, gbaud, gparity, gstopbit, gwordlen)

  if yerror <> 0
    f_valid (.f.,"Error: Unable to initialize modem ...") 
    do rresr1
    do rresr2
    closecomm (gcomm) 
    return   
  endif


  txchar (gcomm, chr (13))
  txchar (gcomm, chr (13))
  txstring (gcomm, "ATZ" + chr (13))
  if waitok () <> 0
    f_valid (.f.,"Error: Modem not responding - ATZ ...") 
    closecomm (gcomm) 
    do rresr1
    do rresr2
    return   
  endif


  swdelay (10)
  txchar (gcomm, chr(13))
  txchar (gcomm, chr(13))
  rxflush (gcomm)

  txstring (gcomm, ginit + chr (13))
 
  if waitok () <> 0
    f_valid (.f.,"Error: Modem not responding to" + ginit) 
    closecomm (gcomm) 
    return   
  endif

  swdelay (10)
  rxflush (gcomm)

  lfile = gdbfpath+substr(dtoc(date()),1,2)+substr(dtoc(date()),4,2)+  ;
          substr(time(),1,2)+substr(time(),4,2)+".txt"
  outfile = fcreate (lfile)

  yreset = .t.

  if gparity = 0
     yparity = "N"
  elseif gparity = 1   
     yparity = "O"
  elseif gparity = 2
     yparity = "E"
  endif

  f_popup ("Waiting for Call Using Comm " + str(gcomm+1,2) +   ;
           " Baud " + str(gbaud,5) + ;
           " ["+yparity+str(gwordlen,1)+str(gstopbit,1)+"]",.f.)
  orgsec = second ()
  zclk = 1               

  do while yreset .and. inkey () <> 27

    * display time ticks
    xsec = second () - orgsec
    @ 24, 01 say substr ("|/-\", zclk, 1)
    zclk = zclk + 1
    if zclk > 4
       zclk = 1
    endif
    **************************

    do while statuscd (gcomm) 

      yreset = .f.  

      do while rxcount (gcomm) > 0   
        ychar = rxchar (gcomm)   
        ?? chr (ychar)   
        fwrite (outfile, chr (ychar), 1)   
      enddo  

      swdelay (12)  

    enddo 

  enddo

  fclose (outfile)

  f_popup ("Received OK ...")

  if statuscd (gcomm)
    smescape (gcomm) 
  endif
  txstring (gcomm, "AT H0" + chr (13))
  swdelay (12)
  closecomm (gcomm)

  lerr = .f.

  do rresr1       && load received files to transit

  do rresr2       && start parsing

  *  if lastkey () = 27 .or. lerr     && 06/14/96: edc
  if lastkey () = 27 

    * display log file
    * if file ("resrpt.dbf")
    *    select 0
    *    use resrpt index resrpt
    *    if .not. eof()
    *       if f_confirm ("Do you want to view System Log File? [Y/N]", ;
    *             "YN") = "Y"
    *          f_pick_f (10, 3, "", "ÄÄDateÄÄÄMessage", ;
    *             "trandate+[ ]+seq+[ ]+cnf")
    *          if f_confirm ("Do you want to erase System Log File? [Y/N]", ;
    *                "YN") = "Y"
    *             use resrpt exclusive
    *             zap
    *             unlock
    *          endif
    *       endif
    *    endif
    *    use
    * endif

    do while .t.
       yret = f_confirm ("[V]iew Reservations  [W]ait for Call  [Q]uit", "IVWQ")
       if yret = "Q"
          close all
          quit  
       elseif yret = "V"
          do rresrpt
       else
          exit    
       endif
    enddo
  endif
enddo


function waitok
private ysec0, ystr, ychar

ysec0 = seconds ()
ystr = ""
do while (seconds () - ysec0) < 10
  if rxcount (gcomm) > 0 
    ychar = rxchar (gcomm)  
    ystr = ystr + chr (ychar)  
    if at ("OK", ystr) > 0 .or. at ("0", ystr) > 0  
      return 0     
    endif    
  endif   
enddo

return -1



