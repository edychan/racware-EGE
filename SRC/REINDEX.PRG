*  
* reindex program for RacWare
*

set excl off
clear
do rinit
restore from (gmempath + "RAPATH.MEM") additive
f_use ("rapath")
go top
@ 05, 10 say "Database       Description           Status"
@ 06, 08 say "컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�"
yline = 7
do while .not. eof ()
   if fname = "RAPATH"
      skip
      loop
   else
      ydb = fname
   endif
   set excl on
   @ yline, 10 say fname
   @ yline, 25 say falias
   if f_use (trim (ydb))
      @ yline, 47 say "Reindexing"
      reindex
      @ yline, 47 say "Reindexed "
      use
   else
      @ yline, 50 say "Open Error"
   endif
   set exclusive off
   select rapath
   skip
   if yline < 23
      yline = yline + 1
   else
      scroll (7, 0, 23, 79, 1)
   endif
enddo

close database

