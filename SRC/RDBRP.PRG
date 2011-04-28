* ----------------------------------------------------------------------
* post dbr
*
* ----------------------------------------------------------------------
* 10.15.08: add 2 add'l charge 5 & 6
* ----------------------------------------------------------------------
private yok

l_floc = floc
l_fdbrno = fdbrno
l_fdbrptdate = frptdate
l_fperoid = substr(dtoc(l_fdbrptdate),7,2)  + substr(dtoc(l_fdbrptdate),1,2)
yok = .t.

if notzero(ftotal+fdep-frecv-fprev)
   f_valid (.f.,"Please reprint DBR after Audits ...")
   * --10.15.08 close data     
   return
endif

do rdbrp1 with l_floc, l_fdbrno, yok                     

if yok
   * do rdbrp2                            
   do rdbrp3                            
   select radbr
   f_fupdate ("C")
   reclock ()
   replace fpost with date(), fglpstd with .t.
   commit
   unlock
else
   select radbr
   f_fupdate ("C")
   reclock ()
   replace fglpstd with .f.
   commit
   unlock
endif

close data
release all like l_*
