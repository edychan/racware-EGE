* -----------------------------------------------------------------
* process dbr data for Dollar Fastlane Data Warehouse
*
* 03.26.03: per DL-EGE, only supply min. info.
* 05.24.07: add JAC and JACN01 location 
*     Note: Location code MUST be *** EGE, JAC, DRIGGS ***
* -----------------------------------------------------------------
* 10.15.08: add 2 add'l charges 5 & 6
* -----------------------------------------------------------------
*
* FIELD         TYPE    REQ'D
* [day_sysid_cust]: 
* custno        C10     Y
* custtyp       C3      
* corpno        C10
* lname         C20     Y
* fname         C20     Y
* company       C30
* h_addr1       C35
* h_addr2       C35
* h_city        C25
* h_state       C2
* h_zip         C10
* h_country     C3
* h_phone       C15
* c_addr1       C35
* c_addr2       C35
* c_city        C25
* c_state       C2
* c_zip         C10
* c_country     C3
* c_phone       C15
* dl_no         C20
* dl_state      C2
* dl_exp        D10
* dl_bday       D10
* cc_typ        C6
* cc_num        C20
* cc_exp        D10
* accident_date D10
* gender        C1              [M/F]
* Loc           C6      Y
* profile_no    C10
* dateout       D10
* timeout       C5
* billto        C6
*
* [day_sysid_ra]
* rano          C10     Y
* resno         C12
* unit_out      C7
* unit_in       C7
* cartyp_out    C4      Y
* cartyp_in     C4      Y
* status        C1      Y       [O:Open,C:close,V:void,H:hold,W:wait]
* mlgout        C6      Y
* mlgin         C6
* mlgdriven     C5
* dateout       D10     Y
* timeout       C5      Y
* datein        D10
* timein        C5
* dbr_date      D10
* dbr_time      C5
* loc_out       C6      Y
* loc_in        C6
* fuel_out      C1      Y       [0-8]
* fuel_in       C1
* rate_out      C8      Y
* rate_in       C8
* dlychg        C10.2   Y       [Only 1 of 6 rate is req'd]
* wkchg         C10.2   Y       [Only 1 of 6 rate is req'd]
* mthchg        C10.2   Y       [Only 1 of 6 rate is req'd]
* adlychg       C10.2   Y       [Only 1 of 6 rate is req'd]
* hrchg         C10.2   Y       [Only 1 of 6 rate is req'd]
* mlgchg        C10.2   Y       [Only 1 of 6 rate is req'd]
* referral      C5      Y
* tot_hr        C3
* tot_day       C3
* tot_wk        C3
* tot_mth       C3
* tot_aday      C3
* mlgtot        C10.2
* dlytot        C10.2
* wktot         C10.2
* mthtot        C10.2
* adlytot       C10.2
* hrtot         C10.2
* chgdays       C10.2
* tnmchg        C10.2
* tnm_tour      C10.2
* tnm_retail    C10.2
* wholesale     C1              [0:no,1:yes]
* fueltot       C10.2
* droptot       C10.2
* opttot        C10.2
* cvgtot        C10.2
* othtot        C10.2
* misctot       C10.2
* miscdesc      C15
* miscadj       C10.2
* disctot       C10.2
* comm          C1      Y       [0:no,1:yes]
* iata          C8
* commtot       C10.2
* commperc      C10.2
* commpaid      C10.2
* discperc      C10.2
* totrevenue    C10.2
* paidamt       C10.2
* deposit       C10.2
* refund        C10.2
* custno        C10
* ffno          C17
* ffairline     C3
* promocode     C10
* exchange_ct   C2
* empout        C30
* empin         C30
* oneway        C1      Y       [0:no,1:yes]
* accident      C1      Y       [0:no,1:yes]
* add_drv       C30
* source        C1      Y       [C:counter,R:res...]
* profileno     C10
* postflag      C1
* VIN           C20
* rate_flg      C1
* src_loc       C6
* ra_typ        C2
* media_code    C10
* confno        C10
* ws_rate       C8
* res_promo     C10
* dbr_dateout   D10
* dbr_timeout   C5
* corpno        C10
* billto        C6
*
* [day_sysid_ra_chg]
* rano          C10     Y
* loc_out       C6
* chg_typ       C4      Y       [OPT, CVG...
* chg_code      C10     Y
* chg_desc      C30
* retail_rate   C10.2
* net_rate      C10.2
* chg_amt       C10.2   Y
* Filler        C149            [REMEMBER to put comma, space(10)+[,]+space(10)+...
*
* [day_sysid_ra_pay]
* rano          C10     Y
* loc_out       C6
* pay_typ       C6      Y       [AX,VI,MC,DS...
* pay_amt       C10.2   Y
* cc number     C20
* cc exp        D10
* date in       D10
* DBR date      D10
* DBR time      C5
* status        C1
*
* [day_sysid_od]
* rano          C10     Y
* loc_out       C6
* od_name       C30     Y
* dl_number     C20
* dl_state      C2
* dl_expdate    D10
* dl_birthdate  D10
* Status        C1              [C] for Closed
*
* -----------------------------------------------------------------
private ii, yzero, ydow, ystr, ycustno
ystr = "sun,mon,tue,wed,thu,fri,sat"
yzero = space(7)+".00"
ii = dow(radbr->frptdate)   && dbr date
* ii = dow(date())              && use today date
ydow = substr(ystr, (ii-1)*4+1, 3)
* open tables
f_use ("rapaycd")
f_use ("raagr")
f_use ("raagrh")
f_use ("radbrt")
seek radbr->floc+str(radbr->fdbrno,4)
if eof ()
   f_valid (.f., "No Data...")
   return
endif
set relation to floc+str(frano,6) into raagrh
* day_sysid_cust
select 0
create (gstnpath + "stru")
use (gstnpath + "stru") exclusive
append blank
replace field_name with "FLINE"
replace field_type with "C"
replace field_len with 503
replace field_dec with 0
use
create (gstnpath + "fl_cust") from (gstnpath + "stru")
erase (gstnpath + "stru.dbf")
use (gstnpath + "fl_cust") exclusive alias cust
* day_sysid_ra
select 0
create (gstnpath + "stru")
use (gstnpath + "stru") exclusive
append blank
replace field_name with "FLINE"
replace field_type with "C"
replace field_len with 835
replace field_dec with 0
use
create (gstnpath + "fl_ra") from (gstnpath + "stru")
erase (gstnpath + "stru.dbf")
use (gstnpath + "fl_ra") exclusive alias ra
* day_sysid_od
select 0
create (gstnpath + "stru")
use (gstnpath + "stru") exclusive
append blank
replace field_name with "FLINE"
replace field_type with "C"
replace field_len with 97
replace field_dec with 0
use
create (gstnpath + "fl_od") from (gstnpath + "stru")
erase (gstnpath + "stru.dbf")
use (gstnpath + "fl_od") exclusive alias od
* day_sysid_ra_chg
select 0
create (gstnpath + "stru")
use (gstnpath + "stru") exclusive
append blank
replace field_name with "FLINE"
replace field_type with "C"
replace field_len with 266
replace field_dec with 0
use
create (gstnpath + "fl_chg") from (gstnpath + "stru")
erase (gstnpath + "stru.dbf")
use (gstnpath + "fl_chg") exclusive alias chg
* day_sysid_ra_pay
select 0
create (gstnpath + "stru")
use (gstnpath + "stru") exclusive
append blank
replace field_name with "FLINE"
replace field_type with "C"
replace field_len with 100
replace field_dec with 0
use
create (gstnpath + "fl_pay") from (gstnpath + "stru")
erase (gstnpath + "stru.dbf")
use (gstnpath + "fl_pay") exclusive alias pay
*
set century on
xlocation = "ORI001"
xloc = radbr->floc     && dbr loc (EGE, JAC, 
xdbrdate = dtoc(radbr->frptdate)
xdbrtime = "23:00"
*
f_box (09, 05, 22, 65, "Processing Transaction")
yrow = 9
select radbrt
do while .not. eof () .and. radbrt->fdbrno = radbr->fdbrno
   * only process closed ra for now
   if .not. radbrt->frectype $ [C] .or. empty(raagrh->flname)
      skip
      loop
   endif
   if radbrt->frectype = [C] 
      if empty(raagrh->fcustno)
         ycustno = f_truncate(strtran(raagrh->flic," ",""),10)
      else
         ycustno = f_truncate(strtran(raagrh->fcustno," ",""),10)
      endif
      select cust
      append blank
        replace fline with ycustno+","+space(3)+","+space(10)+","+ ;
        f_truncate(strtran(raagrh->flname,","," "),20)+","+ ;
        f_truncate(strtran(raagrh->ffname,","," "),20)+","+ ;
        f_truncate(strtran(raagrh->fcrpnm,","," "),30)+","+ ;
        f_truncate(strtran(raagrh->faddr,","," "),35)+","+ space(35)+","+ ;
        f_truncate(strtran(raagrh->fcity,","," "),25)+","+ ;
        f_truncate(raagrh->fstate,2)+","+ ;
        f_truncate(strtran(raagrh->fzip,","," "),10)+","+space(3)+","+ ;
        f_truncate(raagrh->fphone,15)+","+ ;
        f_truncate(strtran(raagrh->fcrpaddr,","," "),35)+","+space(35)+","+ ;
        f_truncate(strtran(raagrh->fcrpcity,","," "),25)+","+ ;
        f_truncate(raagrh->fcrpstate,2)+","+ ;
        f_truncate(strtran(raagrh->fcrpzip,","," "),10)+","+space(3)+","+ ;
        f_truncate(raagrh->fcrpph,20)+","+ ;
        f_truncate(raagrh->flic,20)+","+  ;
        f_truncate(raagrh->flicst,2)+","+ ;
        if (empty(raagrh->flicexp),"?",dtoc(raagrh->flicexp))+","+  ;
        if (empty(raagrh->fdob),"?",dtoc(raagrh->fdob))+","+  ;
        f_truncate(f_chkpaytyp(raagrh->fpaytyp1),6)+","+ ;
        f_truncate(raagrh->fccnum1,20)+"," + ;
        if (len(alltrim(raagrh->fccexp1))<>5,"?", ;
        substr(raagrh->fccexp1,1,2)+"/01/20"+substr(raagrh->fccexp1,4,2))+","+ ;
        "?"+","+ ;
        space(1)+","+ ;
        xlocation+","+ ;
        space(10)+","+ ;
        dtoc(raagrh->fdateout)+","+  ;
        f_truncate(raagrh->ftimeout,5)
      
      if len(alltrim(raagrh->falname)) > 2 
         select od
         append blank
         replace fline with f_truncate(str(raagrh->frano),10)+","+ ;
            f_truncate(raagrh->floc,6)+","+  ;
            f_truncate (strtran(trim(raagrh->falname),",","")+ ;
              " "+strtran(raagrh->fafname,",",""),30)+","+ ;
            f_truncate(raagrh->falic,20)+","+ ;
            f_truncate(raagrh->falicst,2)+","+ ;
            if(empty(raagrh->falicexp),"?",dtoc(raagrh->falicexp))+","+ ;
            if(empty(raagrh->fadob),"?",dtoc(raagrh->fadob))+","+ ;
            if(radbrt->frectype=[C],[C],[O])
      endif
      * resets fuel, drop, opt, cvg, misc charges
      l_fuel = 0
      l_drop = 0
      l_opt = 0
      l_cvg = 0
      l_misc = 0
      l_mdesc = space(15)
      *
      if radbrt->ftmetot > 0
         rdbr7a ("TIME",radbrt->ftmetot)
      endif
      if radbrt->fmlgtot > 0
         rdbr7a ("TIME",radbrt->fmlgtot)
      endif
      if radbrt->ffueltot > 0
         rdbr7a ("FUEL",radbrt->ffueltot)
      endif
      * CVG charges
      if radbrt->fcdwtot > 0
         rdbr7a ("LDW1",radbrt->fcdwtot)
      endif
      if radbrt->fpaitot > 0
         rdbr7a ("PAI",radbrt->fpaitot)
      endif
      * other charges
      if radbrt->fotot1 > 0
         rdbr7a (radbrt->foitem1,radbrt->fotot1)
      endif
      if radbrt->fotot2 > 0
         rdbr7a (radbrt->foitem2,radbrt->fotot2)
      endif
      if radbrt->fotot3 > 0
         rdbr7a (radbrt->foitem3,radbrt->fotot3)
      endif
      if radbrt->fotot4 > 0
         rdbr7a (radbrt->foitem4,radbrt->fotot4)
      endif
      * -- 10.15.08
      if radbrt->fotot5 > 0
         rdbr7a (radbrt->foitem5,radbrt->fotot5)
      endif
      if radbrt->fotot6 > 0
         rdbr7a (radbrt->foitem6,radbrt->fotot6)
      endif
      *
      if raagrh->famt1 > 0
         rdbr7b (raagrh->fpaytyp1, raagrh->famt1, raagrh->fccnum1, ;
                 raagrh->fccexp1, dtoc(raagrh->fdatein), xdbrdate)
      endif
      if raagrh->famt2 > 0
         rdbr7b (raagrh->fpaytyp2, raagrh->famt2, raagrh->fccnum2, ;
                 raagrh->fccexp2, dtoc(raagrh->fdatein), xdbrdate)
      endif
      if raagrh->famt3 > 0
         rdbr7b (raagrh->fpaytyp2, raagrh->famt3, raagrh->fccnum3, ;
                 raagrh->fccexp3, dtoc(raagrh->fdatein), xdbrdate)
      endif
      *
      ycomm = if(empty(raagrh->fresvno),"0","1")
      ysrc = if(ycomm="0","C","R")
      select ra
      append blank
      replace fline with f_truncate(str(raagrh->frano),10)+","+ ;
        f_truncate(raagrh->fresvno,12)+","+  ;
        f_truncate(if(empty(raagrh->feunit),raagrh->funit,raagrh->feunit),7)+","+ ;
        f_truncate(raagrh->funit,7)+","+ ;
        substr(raagrh->fclass,1,4)+","+substr(raagrh->fclass,1,4)+","+ ;
        "C"+","+str(raagrh->fmlgout,6)+","+ ;
        str(raagrh->fmlgin,6)+","+str(raagrh->fmlgin-raagrh->fmlgout,5)+","+ ;
        dtoc(raagrh->fdateout)+","+raagrh->ftimeout+","+ ;
        dtoc(raagrh->fdatein)+","+raagrh->ftimein+","+ ;
        xdbrdate+","+xdbrtime+","+ ;
        substr(raagrh->floc,1,6)+","+substr(raagrh->frloc,1,6)+","+ ;
        str(raagrh->ffuelout,1)+","+str(raagrh->ffuelin,1)+","+ ;
        f_truncate(raagrh->frate,8)+","+ ;
        f_truncate(raagrh->frate,8)+","+ ;
        str(raagrh->fdlychg,10,2)+","+str(raagrh->fwkchg,10,2)+","+ ;
        yzero+","+yzero+","+yzero+","+yzero+","+ ;
        substr(raagrh->freferal,1,5)+","+ ;
        str(raagrh->fhr,3)+","+str(raagrh->fdly,3)+","+ ;
        str(raagrh->fwk,3)+","+str(raagrh->fmth,3)+","+space(3)+","+ ;
        str(raagrh->fmlgtot,10,2)+","+ ;
        str(raagrh->fdlytot,10,2)+","+ ;
        str(raagrh->fwktot,10,2)+","+  ;
        str(raagrh->fmthtot,10,2)+","+ ;
        yzero+","+ ;
        str(raagrh->fhrtot,10,2)+","+  ;    
        yzero+","+ ;
        str(raagrh->ftmetot+raagrh->fmlgtot,10,2)+","+ ;
        yzero+","+ ;
        str(raagrh->ftmetot+raagrh->fmlgtot,10,2)+","+ ;
        "0"+","+ ;
        str(l_fuel,10,2)+","+ ;
        yzero+","+ ;
        str(l_opt,10,2)+","+ ;
        str(l_cvg,10,2)+","+ ;
        str(l_opt+l_cvg,10,2)+","+ ;
        str(l_misc,10,2)+","+ ;
        f_truncate(l_mdesc,15)+","+ ;
        yzero+","+ ;
        str(raagrh->fdisctot,10,2)+","+ ;
        ycomm+","+space(8)+","+ ;
        yzero+","+yzero+","+yzero+","+yzero+","+yzero+","+ ;
        str(raagrh->famt1+raagrh->famt2+raagrh->famt3,10,2)+","+ ;
        str(raagrh->fdepamt,10,2)+","+ ;
        yzero+","+ ;
        ycustno+","+ ;
        space(17)+","+space(3)+","+space(10)+","+space(2)+","+ ;
        f_truncate(raagrh->fid1,30)+","+f_truncate(raagrh->fid2,30)+","+ ;
        "0"+","+"0"+","+ ;
        if(empty(raagrh->falname),space(30), ;
          f_truncate(strtran(trim(raagrh->falname)+[ ]+raagrh->fafname,","," "),30))+","+ ;
        ysrc+","+ ;
        space(10)+","+ ;
        "Y"+","+ ;
        space(20)+","+space(1)+","+ ;
        xlocation+","+ ;
        space(2)+","+space(10)+","+ ;
        f_truncate(raagrh->fresvno,10)+","+ ;
        space(8)+","+space(10)+","+ ;
        dtoc(raagrh->fdateout)+","+xdbrtime+","+ ;
        space(10)+","+space(6)
   else
      * look into open ra
      select raagr
      seek radbrt->floc+str(radbrt->frano,6)
      if .not. eof ()     && ra still open
      ycomm = if(empty(raagr->fresvno),"0","1")
      ysrc = if(ycomm="0","C","R")
      select ra
      append blank
      replace fline with f_truncate(str(raagr->frano),10)+","+space(12)+","+  ;
        f_truncate(raagr->funit,7)+","+space(7)+","+ ;
        substr(raagr->fclass,1,4)+","+space(4)+","+ ;
        "O"+","+str(raagr->fmlgout,6)+","+space(6)+","+space(5)+","+ ;
        dtoc(raagr->fdateout)+","+raagr->ftimeout+","+space(10)+","+space(5)+","+ ;
        space(10)+","+space(5)+","+substr(raagr->floc,1,6)+","+space(6)+","+ ;
        str(raagr->ffuelout,1)+","+space(1)+","+f_truncate(raagr->frate,8)+","+ ;
        space(8)+","+str(raagr->fdlychg,10,2)+","+str(raagr->fwkchg,10,2)+","+ ;
        yzero+","+yzero+","+yzero+","+yzero+","+substr(raagr->freferal,1,5)+","+ ;
        space(3)+","+space(3)+","+space(3)+","+space(3)+","+space(3)+","+ ;
        yzero+","+yzero+","+yzero+","+yzero+","+yzero+","+yzero+","+yzero+","+ ;
        yzero+","+yzero+","+yzero+","+"0"+","+ ;
        yzero+","+yzero+","+yzero+","+yzero+","+yzero+","+yzero+","+ ;
        space(15)+","+yzero+","+yzero+","+ycomm+","+space(8)+","+ ;
        yzero+","+yzero+","+yzero+","+yzero+","+ ;
        yzero+","+yzero+","+yzero+","+yzero+","+ ;
        space(10)+","+space(17)+","+space(3)+","+space(10)+","+space(2)+","+space(30)+","+ ;
        space(30)+","+"0"+","+"0"+","+space(30)+","+ysrc+","+ ;
        space(10)+","+space(1)+","+space(20)+","+ ;
        space(1)+","+space(6)+","+space(2)+","+space(10)+","+ ;
        f_truncate(raagr->fresvno,10)+","+ ;
        space(8)+","+space(10)+","+ ;
        xdbrdate+","+xdbrtime+","+ ;
        space(10)+","+space(6)
        endif
   endif
   select radbrt
   if yrow >= 21
      scroll (10, 10, 21, 60, 1)
   else
      yrow = yrow + 1
   endif
   @ yrow, 13 say str(frano,6)+" "+dtoc(fdateout)+" "+substr(flname,1,30)+" "+funit
   skip
enddo
*
set century off
*
f_wrtfile ("cust", "cust.txt")
f_wrtfile ("od", "od.txt")
f_wrtfile ("ra", "ra.txt")
f_wrtfile ("pay", "pay.txt")
f_wrtfile ("chg", "chg.txt")

* create upload.bat

* --07.27.09: path change from H: to D: for JAC & DRIGGS
do case   && 05.24.07: add JAC, JACN01
case xloc = "JAC"
   ypre = ydow+[_dlrjac_]        && system id assigned by dollar
   ydwhpath = [D:\DLCOMM\OUTBOUND\]   && path of ftp server
case xloc = "DRIGGS"
   ypre = ydow+[_dlrjacn01_]        && system id assigned by dollar
   ydwhpath = [D:\DLCOMM\OUTBOUND\]   && path of ftp server
otherwise
   ypre = ydow+[_dlrege_]        && system id assigned by dollar
   ydwhpath = [H:\DLCOMM\OUTBOUND\]   && path of ftp server
endcase
*
yfil = gcompath + "upload.bat"
set device to print
set printer to &yfil
setprc (0,0)
yln = 0
@ yln, 0 say [@echo off]
yln = yln + 1
@ yln, 0 say [echo ============= Customer File =========================]
yln = yln + 1
@ yln, 0 say [if exist cust.txt copy cust.txt ] + ydwhpath+ypre + [cust]
yln = yln + 1
@ yln, 0 say [echo ============= RA File ===============================]
yln = yln + 1
@ yln, 0 say [if exist ra.txt copy ra.txt ] + ydwhpath+ypre + [ra]
yln = yln + 1
@ yln, 0 say [echo ============= Add'l Driver File =====================]
yln = yln + 1
@ yln, 0 say [if exist od.txt copy od.txt ] + ydwhpath+ypre + [od]
yln = yln + 1
@ yln, 0 say [echo ============= Payment File ==========================]
yln = yln + 1
@ yln, 0 say [if exist pay.txt copy pay.txt ] + ydwhpath+ypre + [ra_pay]
yln = yln + 1
@ yln, 0 say [echo ============= Charge File ===========================]
yln = yln + 1
@ yln, 0 say [if exist chg.txt copy chg.txt ] + ydwhpath+ypre + [ra_chg]
yln = yln + 1
@ yln, 0 say [if exist *.txt del *.txt]
yln = yln + 1
@ yln, 0 say [echo *****************************************************]
yln = yln + 1
@ yln, 0 say [echo ************** Process Completed ********************]
yln = yln + 1
@ yln, 0 say [echo *****************************************************]
yln = yln + 1
@ yln, 0 say [pause]
yln = yln + 1
@ yln, 0 say [exit]

set printer to
set console on
set print off
set device to screen

f_valid (.f., "Process Completed")

*******************
* add to day_sysid_ra_chg
function rdbr7a
parameter xtyp, xamt
private ychgcode, ychgtyp, yglacctyp, ydesc, ytax
do case
   case xtyp = "TIME"
      ychgcode = "TIME"
      ychgtyp = "TIME"
      ydesc = "Time - Miles"
      yglacctyp = "R"
      ytax = "1"
   case xtyp = "FUEL"
      ychgcode = "FUEL"
      ychgtyp = "FUEL"
      ydesc = "FUEL"
      yglacctyp = "F"
      ytax = "0"
   case xtyp = "LDW1"
      ychgcode = "LDW1"
      ychgtyp = "CVG"
      ydesc = "LossDmgWaivr"
      yglacctyp = "R"
      ytax = "0"
   case xtyp = "PAI"
      ychgcode = "PAI"
      ychgtyp = "CVG"
      ydesc = "PersAccdCovg"
      yglacctyp = "R"
      ytax = "0"
   otherwise
      select rapaycd
      seek xtyp
      if eof ()
         ychgcode = "MISC"
         ychgtyp = "MISC"
         ydesc = "Misc. Charge"
         yglacctyp = "N"
         ytax = "0"
      else
         ychgcode = rapaycd->fchgcode
         ychgtyp = rapaycd->fchgtyp
         ydesc = rapaycd->fchgdesc
         yglacctyp = rapaycd->fglacctyp
         ytax = if(rapaycd->ftax,"1","0")
      endif
endcase

* accumulate total
do case
case ychgtyp = [FUEL]
   l_fuel = l_fuel + xamt
case ychgtyp = [CVG]
   l_cvg = l_cvg + xamt
case ychgtyp = [OPT]
   l_opt = l_opt + xamt
case ychgtyp = [MISC]
   l_misc = l_misc + xamt
   l_mdesc = ydesc
endcase
*
select chg
append blank
replace fline with f_truncate(str(radbrt->frano),10)+","+ ;
   f_truncate(raagrh->floc,6)+","+ ;
   f_truncate(ychgtyp,4)+","+f_truncate(ychgcode,10)+","+ ;
   f_truncate(ydesc,30)+","+ ;
   str(xamt,10,2)+","+ ;
   yzero+","+str(1,10,2)+","+str(xamt,10,2)+","+yzero+","+ ;
   ytax+","+ ;
   "0"+","+ ;
   space(4)+","+space(25)+","+ ;
   xdbrdate+","+xdbrtime+","+ ;
   "C"+","+ ;
   space(6)+","+space(30)+","+yzero+","+space(8)+","+ ;
   "N"+","+ ;
   space(3)+","+ ;
   yglacctyp+","+ ;
   yzero+","+ ;
   "Y"+","+ ;
   space(12)
return .t.

*******************
* add to day_sysid_ra_pay
function rdbr7b
parameter xtyp, xamt, xccnum, xccexp, xdatein, xdbrdate
private yccexp

xtyp = f_chkpaytyp (xtyp)
yccexp = if(empty(xccnum),"?",substr(xccexp,1,2)+"/01/20"+substr(xccexp,4,2))
select pay
append blank
replace fline with f_truncate(str(radbrt->frano),10)+","+ ;
   f_truncate(raagrh->floc,6)+","+ ;
   f_truncate(xtyp,6)+","+ ;
   str(xamt,10,2)+","+ ;
   f_truncate(xccnum,20)+","+ ;
   yccexp+","+ ;
   [P]+","+ ;
   xdatein+","+ ;
   xdbrdate+","+ ;
   xdbrtime+","+ ;
   if(radbrt->frectype=[C],[C],[O])
return .t.

**************************
function f_chkpaytyp
parameter xtyp

do case
case xtyp = [VA]
   xtyp = [VI]
case xtyp = [CSH]
   xtyp = [CH]
endcase

return xtyp

**************************
function f_wrtfile
parameter xfile, xoutfile
private yfil, yln, yhandle

select &xfile
go top
if eof ()
   return .t.
endif
*
yfil = gcompath + xoutfile
if file (yfil)
   erase &yfil
endif
*
yhandle = fcreate (yfil)
*
do while .not. eof ()
   fwrite (yhandle, fline+chr(10))
   skip
enddo

fclose (yhandle)

return .t.
*************************************
