* ====================================================================
* Onsum netmail driver program.
* --------------------------------------------------------------------
* 06.15.09: 1. Output rezdata.txt for reservation
* 07.15.09: 2. Output radata.txt for contract
* --------------------------------------------------------------------
* 12.27.10
* overhaul send rez message
* 1. use only 1 template rezmsg.htm (header, body, footer)
* 2. add noshow/cancellation notification
* 3. modify rezmsg.dbf (add fstatus, fcxldate, freschg and fccinfo
* ---------------------------------------------------------------------
* 02.15.11: correct Eagle phone #
* -----------
* 06.21.11: add email report function
* =====================================================================
clear
set delete on
set excl off

do makrez

do makagr

do makrep         && email report function

close all

* =====================================================================
* 06.21.11: add email report function
procedure makrep
yfil = "emrpt.dbf"
if .not. file (yfil)
   return
endif

select 0
use &yfil alias rep
go top
if eof ()
   return
endif

? "Start processing Report email queue ..." + str(reccount())
yfil = "rarep.txt"
set device to print
set printer to &yfil
setprc (0,0)

* -- write header
yln = 0
@yln, 0 say [to,from,report,attachment]        
yln = yln + 1

yfrom = "dollar.ege.manager@centurytel.net"
select rep
do while .not. eof () 

   yto = trim(rep->femail)
   yreport = trim(rep->freport)
   yfile = trim(rep->ffile)   

   yfld = ["] + yto + ["] + [,] + ;
          ["] + yfrom + ["] + [,] + ;
          ["] + yreport + ["] + [,] + ;
          ["] + yfile + ["] 

   @yln, 0 say yfld
   yln = yln + 1
   rlock ()
   delete
   skip
enddo

set printer to
set console on
set print off
set device to screen

? "Complete processing Report queue ..."
?
?

* =====================================================================
procedure makagr
yfil = "ramsg.dbf"
if .not. file (yfil)
   return
endif

select 0
use &yfil alias ra
go top
if eof ()
   return
endif

? "Start processing RA email queue ..." + str(reccount())
yfil = "radata.txt"
set device to print
set printer to &yfil
setprc (0,0)

* -- write header
yln = 0
@yln, 0 say [to,from,location,customer,addcust,vehicle,rateinfo,return,racharge,payment]        
yln = yln + 1

select ra
do while .not. eof () 

   yto = alltrim(ra->femail)

   if ra->floc = "EGE"
      * yfrom = "dollarrentacar_ege@hotmail.com"
      yfrom = "dollar.ege.manager@centurytel.net"
   else
      yfrom = "jacksonholedollar@bresnan.net"
   endif
   * --location section
   if ra->floc = "EGE"
      ylocation = "Dollar Rent a Car<br>" +;
                  "Eagle County Regional Airport<br>" +;
                  "216 Eldon Wilson Road<br>" +;
                  "Gypsum, CO 81637<br>" +;
                  "Phone: 970-524-7334<br>"
   else
      ylocation = "Dollar Rent a Car<br>" +;
                  "345 WEST BROADWAY<br>" +;
                  "JACKSON HOLE, WYOMING<br>" +;
                  "Phone: 307-733-9224<br>"
   endif
   * --customer section
   ycust = alltrim(ra->ffname)+" "+alltrim(ra->flname)+"<br>" +;
           alltrim(ra->faddr)+"<br>" + ;
           alltrim(ra->fcity)+", "+ra->fstate+" "+ra->fzip+"<br>"
   * --addition driver section
   if empty(ra->falname)
      yaddcust = ""
   else
      yaddcust = alltrim(ra->fafname)+" "+alltrim(ra->falname)+"<br>" +;
           alltrim(ra->faaddr)+"<br>" + ;
           alltrim(ra->facity)+", "+ra->fastate+" "+ra->fazip+"<br>"
   endif
   * --vehicle section
   yvehicle = "Check Out: "+dtoc(ra->fdateout)+" " +;
              "Time: "+ra->ftimeout+"<br><br>" +;
              "Vehicle #: "+ra->funit+"<br>" +;
              "Mileage In: "+str(ra->fmlgin,6,0)+"<br>" +;
              "Mileage Out: "+str(ra->fmlgout,6,0)+"<br>" +;
              "Total Miles Driven: "+str(ra->fmlgin-ra->fmlgout,6,0)+"<br>" +; 
              "Fuel Level In: "+str(ra->ffuelin,1)+"/8<br>" +;
              "Fuel Level Out: "+str(ra->ffuelout,1)+"/8<br>"
   * --rate information
   yrateinfo = if(ra->fdlychg>0,"Daily: $"+str(ra->fdlychg,8,2)+"<br>","") +;
            if(ra->fwkdchg>0,"Extra day: $"+str(ra->fwkdchg,8,2)+"<br>","") +;
            if(ra->fwkchg>0,"Weekly: $"+str(ra->fwkchg,8,2)+"<br>","") +;
            if(ra->fmthchg>0,"Monthly: $"+str(ra->fmthchg,8,2)+"<br>","") +;
            if(ra->fhrchg>0,"hour: $"+str(ra->fhrchg,8,2)+"<br>","") +;
            "<br>" +;
            "State Tax<br>" +;
            if(ra->floc="EGE","Airport Access 16%<br>","Airport Access <br>") +;
            if(ra->floc="EGE","Colorado Road Safety $2 /day<br>","WY Surcharge 4% <br>")
   * --return section
   yreturn = "RA #: "+trim(ra->floc)+str(ra->frano,6,0)+"<br>" +;
              "Due Back: "+if(empty(ra->fduein),dtoc(ra->fdatein),dtoc(ra->fduein))+"<br>" +;
              "Check In: "+dtoc(ra->fdatein)+" " +;
              "Time: "+ra->ftimein+"<br>"
   * --charge section
   yracharge = if(ra->fhrtot>0,str(fhr,2)+" hour @ "+str(ra->fhrchg,7,2)+": "+str(ra->fhrtot,8,2)+"<br>","") +;
    if(ra->fdlytot>0,str(fdly,2)+" day @ "+str(ra->fdlychg,7,2)+": "+str(ra->fdlytot,8,2)+"<br>","") +;
    if(ra->fwkdtot>0,str(fwkd,2)+" ex day @ "+str(ra->fwkdchg,7,2)+": "+str(ra->fwkdtot,8,2)+"<br>","") +;
    if(ra->fwktot>0,str(fwk,2)+" week @ "+str(ra->fwkchg,7,2)+": "+str(ra->fwktot,8,2)+"<br>","") +;
    if(ra->fmthtot>0,str(fmth,2)+" month @ "+str(ra->fmthchg,7,2)+": "+str(ra->fmthtot,8,2)+"<br>","") +;
    if(ra->fmlgtot>0,"Mileage: "+str(ra->fmlgtot,8,2)+"<br>","") +;
    if(ra->fcdwtot>0,"LDW: "+str(ra->fcdwtot,8,2)+"<br>","") +;
    if(ra->fpaitot>0,"PEC: "+str(ra->fpaitot,8,2)+"<br>","") +;
    if(ra->fdmgtot>0,"Damage: "+str(ra->fdmgtot,8,2)+"<br>","") +;
    if(ra->ffueltot>0,"fuel: "+str(ra->ffueltot,8,2)+"<br>","") +;
    if(ra->fotot1>0,ra->foitem1+": "+str(ra->fotot1,8,2)+"<br>","") +;
    if(ra->fotot2>0,ra->foitem2+": "+str(ra->fotot2,8,2)+"<br>","") +;
    if(ra->fotot3>0,ra->foitem3+": "+str(ra->fotot3,8,2)+"<br>","") +;
    if(ra->fotot4>0,ra->foitem4+": "+str(ra->fotot4,8,2)+"<br>","") +;
    if(ra->fotot5>0,ra->foitem5+": "+str(ra->fotot5,8,2)+"<br>","") +;
    if(ra->fotot6>0,ra->foitem6+": "+str(ra->fotot6,8,2)+"<br>","") +;
    if(ra->fdisctot>0,"Discount: "+str(ra->fdisctot,8,2)+"<br>","") +;
    if(ra->fcredtot>0,"Credit: "+str(ra->fcredtot,8,2)+"<br>","") +;
    if(ra->fsurchg>0,"AP Access: "+str(ra->fsurchg,8,2)+"<br>","") +;
    if(ra->ftaxtot>0,"Tax: "+str(ra->ftaxtot,8,2)+"<br>","") +;
    "<br>" +;
    "Total: "+str(ra->ftotal,8,2)+"<br>" +;
    if(ra->fdepamt>0,"Deposit: "+str(ra->fdepamt,8,2)+"<br>","") 
   * --payment section
   ypayment = if(ra->famt1>0,"[1] "+trim(ra->fpaytyp1)+" "+substr(fccnum1,len(trim(fccnum1))-3)+"....  "+str(ra->famt1,8,2)+"<br>","") + ;
    if(ra->famt2>0,"[2] "+trim(ra->fpaytyp2)+" "+substr(fccnum2,len(trim(fccnum1))-3)+"....  "+str(ra->famt2,8,2)+"<br>","") + ;
    if(ra->famt3>0,"[3] "+trim(ra->fpaytyp3)+" "+substr(fccnum3,len(trim(fccnum1))-3)+"....  "+str(ra->famt3,8,2)+"<br>","") 

   yfld = ["] + yto + ["] + [,] + ;
          ["] + yfrom + ["] + [,] + ;
          ["] + ylocation + ["] + [,] + ;
          ["] + ycust + ["] + [,] + ;
          ["] + yaddcust + ["] + [,] + ;
          ["] + yvehicle + ["] + [,] + ;
          ["] + yrateinfo + ["] + [,] + ;
          ["] + yreturn + ["] + [,] + ;
          ["] + yracharge + ["] + [,] + ;
          ["] + ypayment + ["] 

   @yln, 0 say yfld
   yln = yln + 1
   rlock ()
   delete
   skip
enddo

set printer to
set console on
set print off
set device to screen

? "Complete processing RA queue ..."
?
?

* =====================================================================
procedure makrez
private yheader, ybody, yfooter

yfil = "rezmsg.dbf"
if .not. file (yfil)
   return
endif

select 0
use &yfil alias rez
go top
if eof ()
   return
endif

? "Start processing REZ email queue ..." + str(reccount())
yfil = "cartype"
select 0
use &yfil index &yfil alias cartype

yfil = "rezdata.txt"     && rez msg data 
set device to print
set printer to &yfil
setprc (0,0)

* -- write header
yln = 0
* --12.30.10
* @yln, 0 say [to,from,name,resno,cartype,dateout,datein,rate,surchg,surchg1,taxtot,estchg,filename]
@yln, 0 say [to,from,rzheader,rzbody,rzfooter]        
yln = yln + 1

select rez
do while .not. eof () 

   * --define cartype
   select cartype
   seek alltrim(rez->fcartype)
   if eof ()
      ycardesc = alltrim(rez->fcartype)
   else
      ycardesc = alltrim(cartype->fdesc)
   endif

   select rez
   * --define from
   if upper(rez->ffile) = "EGE"
      yfrom = "dollar.ege.manager@centurytel.net"
      yloc = "Eagle County Airport Terminal or Eagle/ Vail Private Jet Center"
      yrloc = "Eagle County Regional Airport, 216 Eldon Wilson Rd, Gypsum, CO 81637"
      yphone = "970-524-7334 or dollar.ege.manager@centurytel.net"
	  ycity = "EAGLE"
      ystate = "COLORADO"
      yrestrict = "COLORADO"
	  yuse = "For use within Colorado only."
   else
      yfrom = "jacksonholedollar@bresnan.net"
      yloc = "345 West Broadway Jackson, WY (Airport Serving- Free shuttle) "
      yrloc = "345 West Broadway Jackson, WY (Airport Serving- Free shuttle) "
      yphone = "307-733-9224 or jacksonholedollar@bresnan.net"
	  ycity = "JACKSONHOLE"
      ystate = "WYOMING"
      yrestrict = "WYOMING, IDAHO AND MONTANA"
	  yuse = "For use within the States of Wyoming, Idaho, and Montana."
   endif

   * --detail
   if rez->fstatus = "N"
      yheader = "<p align='center'><b>This e-mail is a receipt for your No Show/ Cancellation from Dollar Rent A Car.</b></p>" + ;
                "<p align='center'><b>Reservation: " + alltrim(fname) + "." + "</b></p>" + ;
                "<p align='center'<span><b>Here is your confirmation number : </b></span>" + ;
                "<span style='color:#E61E14'><b>" + alltrim(fresvno) + "<br><br>" + ;
                "Reservation Status: NO SHOW" + "<br>"+ ;
                "No Show Date: "+substr(fdateout,1,10)+"<br>"+ ;
                "No Show Charge: "+"$"+alltrim(str(freschg,10,2))+"<br>"+ ;
                "Charged on: "+trim(fccinfo) + ;
                "</b></span><br><br>" + ;
				"<b>Contact us direct for your next booking at this same location and we will honor<br>" + ;
                "An additional 15% discount to your next reservation before pick up!</b></p>"
      ydetail = ""
      ygreeting = ""
      yfine = ""
   elseif rez->fstatus = "C"
      yheader = "<p align='center'><b>This e-mail is a receipt for your No Show/ Cancellation from Dollar Rent A Car.</b></p>" + ;
                "<p align='center'><b>Reservation: " + alltrim(fname) + "." + "</b></p>" + ;
                "<p align='center'<span><b>Here is your confirmation number : </b></span>" + ;
                "<span style='color:#E61E14'><b>" + alltrim(fresvno) + "<br><br>" + ;
                "Reservation Status: CANCEL" + "<br>"+ ;
                "Cancellation Date: "+substr(fcxldate,1,10)+"<br>"+ ;
                "Cancellation Charge: "+"$"+alltrim(str(freschg,10,2))+"<br>"+ ;
                "Charged on: "+trim(fccinfo) + ;
                "</b></span><br><br>" + ;
				"<b>Contact us direct for your next booking at this same location and we will honor<br>" + ;
                "An additional 15% discount to your next reservation before pick up!</b></p>"
      ydetail = ""
      ygreeting = ""
      yfine = ""

				else
      yheader = "<p align='center'><b>This e-mail is just a friendly reminder from your friends at Dollar Rent A Car.</b></p>" + ;
             "<p align='center'>We look forward to seeing you <b>" + alltrim(fname) + ".</b><br>" + ;
             "<b><span>Here is your confirmation number : </span><span style='font-size: 15.0pt;color:#E61E14'>" + ;
			 alltrim(fresvno) + "</span></b></p>"
      ygreeting = "<b>Your reservation for a "+ ycardesc + " " + ;
                  "is confirmed for " + dformat(fdateout) + ;
		          " in " + ycity + ", " + ystate + "." + "</b><br><br>" 
      yfine = yuse + ;
              "<span style='font-size: 8pt'>Base rate does not include additional drivers, optional coverages, " + ;
              "upgrades, child seats, ski racks, fuel, etc., or taxes, surcharges, airport fee on these items." + ;
		      "</span><br><br>"
      ydetail = "<b>" + ystate+" SURCHARGE: </b>"+"$"+alltrim(str(fsurchg1,10,2))+"<br>"+ ;
                "<b>AIRPORT ACCESS FEE: </b>"+"$"+alltrim(str(fsurchg,10,2))+"<br>"+ ;
                "<b>RENTAL TAX: </b>"+"$"+alltrim(str(ftaxtot,10,2))+"<br><br>"+ ;
                "<b><span style='font-size: 16pt'>TOTAL ESTIMATED CHARGES: "+"$"+alltrim(str(ftotal,10,2))+"</span></b><br>"
   endif

   * --define body
			   
   ybody = ygreeting + ;
      "<b>Pickup Location: </b>" + yloc + "<br>" + ;
      "<b>Pickup Location Contact: </b>" + yphone + "<br>" + ;
      "<br>" + ;
      "<b>Return Location:  </b>" + yrloc + "<br>" + ;
      "<b>Return Location Contact: </b>" + yphone + "<br>" + ;
      "<br>" + ;
      "<b>Pickup Date/Time: </b>" + dformat(fdateout) + "<br>" + ;
      "<b>Return Date/Time: </b>" + dformat(fdatein) + "<br>" + ;
      "<br>" + ;
      "<b>Vehicle Type: </b>" + ycardesc + "<br>" + ;
      "<br>" + ;
      "<b>Your Base Rate is: </b>" + alltrim(fratedesc) + "<br>  <br>" + ;
      yfine + ;
      ydetail

   * --define footer
   yfooter = "<u><b>Cancellation Policy</b></u>" + ;
             "<b>: Reservations must be cancelled before 48 hours prior to pick-up date to avoid " + ;
			 "a one day cancellation fee." + "<br><br>" + ;
             "Driving is limited to the state of " + yrestrict + "." + "<br><br>" + ;
             "This location DOES NOT accept debit cards/check cards. Major credit card and valid " + ;
             "driver's license must be in the same name." + "<br><br>" + ;
             "Renters must be at least 25 years of age." 			 

   select rez
   yfld = ["] + alltrim(femail) + ["] + [,] + ;
          ["] + yfrom + ["] + [,] + ;
          ["] + yheader + ["] + [,] + ;
          ["] + ybody + ["] + [,] + ;
          ["] + yfooter + ["] 

   @yln, 0 say yfld
   yln = yln + 1
   rlock ()
   delete
   skip
enddo

set printer to
set console on
set print off
set device to screen

? "Complete processing REZ queue ..."
?
?

* =========================================
* dformat:
* xdate = mm/dd/yyyy 99:99
*    return January 1, 2010 12:00pm
* 
function dformat
parameters xdate
private ymo, yday, ytime

ymo = substr(xdate,1,2)

do case
case ymo = [01]
   ymonth = "January"
case ymo = [02]
   ymonth = "Feburary"
case ymo = [03]
   ymonth = "March"
case ymo = [04]
   ymonth = "April"
case ymo = [05]
   ymonth = "May"
case ymo = [06]
   ymonth = "June"
case ymo = [07]
   ymonth = "July"
case ymo = [08]
   ymonth = "August"
case ymo = [09]
   ymonth = "September"
case ymo = [10]
   ymonth = "October"
case ymo = [11]
   ymonth = "November"
otherwise
   ymonth = "December"
endcase

yhr = val(substr(xdate,12,2))
if yhr = 0
   ytime = [12]+substr(xdate,14,3)+" am"
elseif yhr = 12
   ytime = [12]+substr(xdate,14,3)+" pm"
elseif yhr > 12
   yhr = yhr - 12
   ytime = str(yhr,2)+substr(xdate,14,3)+" pm"
else 
   ytime = substr(xdate,12,5)+" am"
endif

ystr = ymonth + " " + substr(xdate,4,2)+[, ]+substr(xdate,7,4)+[ @ ]+ytime
return ystr
