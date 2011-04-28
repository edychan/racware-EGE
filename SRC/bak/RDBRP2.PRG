f_popup ("Updating DBR MTD Totals ...")
f_use ("radbrtot")

seek upper (l_floc + l_fperoid)
private yfnd
yfnd = found ()
if .not. yfnd
   append blank
   reclock ()
   replace floc with l_floc, fperoid with l_fperoid
else
   f_fupdate ("C")
   reclock ()
endif
replace fdbrno with l_fdbrno     
replace fclosed with fclosed + radbr->fclosed
replace fdays with fdays + radbr->fdays,fmiles with fmiles + radbr->fmiles
replace ftmetot with ftmetot + radbr->ftmetot - radbr->fdisc
replace fmlgtot with fmlgtot + radbr->fmlgtot
replace fcred with fcred + radbr->fcred,fdisc with fdisc + radbr->fdisc
replace fothamt with fothamt + radbr->fothamt,fcdw with fcdw + radbr->fcdw
replace ftax with ftax + radbr->ftax,fpai with fpai + radbr->fpai
replace fgas with fgas + radbr->fgas,fdamage with fdamage + radbr->fdamage
replace fothchgs with fothchgs + radbr->fothchgs,ftotal with ftotal + radbr->ftotal
replace fprev with fprev + radbr->fprev, fdep with fdep + radbr->fdep
replace frecv with frecv + radbr->fcash, fbill with fbill + radbr->facctrec
commit
unlock
if .not. yfnd
   f_fupdate ("A")
endif
f_popback ()

