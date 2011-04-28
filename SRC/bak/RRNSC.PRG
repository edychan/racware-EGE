* ===========================================================================
* rental module - view closed contract
*
* date: 05/01/91
* author: KST
*
* revision
* date: 02/01/94
* edc: add reprint closed contract option
* date: 08.12.99: set century off
* 10.23.01: add email address
* ===========================================================================
set century off
f_clrscn ("View Close Contract")

l_floc = gloc
l_frano = 0
l_flname = space (14)
l_funit = space (10)
l_frefno = space (14)
if .not. rrnpkra ("C")
   close databases
   return
endif

f_getscn ("RAAGR")
do while .t.
   do rrnscdisp
   ykeyin = f_confirm ("[N]ext   [P]revious   [R]eprint   [Q]uit", "NPRQ")
   do case
   case ykeyin = "N"
      skip 1
      if eof ()
         f_popup ("End of file. Press Any Key...", .t.)
         go bottom
      endif
   case ykeyin = "P"
      skip -1
      if bof ()
         f_popup ("Top of file. Press Any Key...", .t.)
         go top
      endif
   case ykeyin = "R"
      if f_confirm ("Do you want to reprint contract? ", "YN") = "Y"
         do rrnprt with "C"
      endif
   case ykeyin = "Q"
      exit
   endcase
enddo

close databases


******************************
procedure rrnscdisp

@ 12,02 say "Email .."
setcolor (gblueget)
@ 02,11 say floc
@ 02,22 say frano picture "999999"
@ 02,34 say fdbrno picture "9999"
@ 03,11 say frloc
@ 04,11 say flname
@ 05,11 say ffname
@ 06,11 say faddr
@ 07,11 say fcity
@ 08,11 say fstate
@ 08,14 say fzip
@ 09,11 say fphone
@ 10,11 say flic
@ 10,36 say flicst
@ 11,11 say flicexp
@ 11,30 say fdob
@ 12,11 say femail pict replicate ('X', 27)      && 10.23.01
@ 13,11 say fcrpnm
@ 14,11 say fcrpaddr
@ 15,11 say fcrpcity
@ 16,11 say fcrpstate
@ 16,14 say fcrpzip
@ 17,11 say fcrpph
@ 18,11 say freferal
@ 03,53 say ftmetot picture "@Z 99999.99"
@ 04,53 say fmlgtot  picture "@Z 99999.99"
@ 05,53 say fmlgtot + ftmetot picture "@Z 99999.99"
@ 06,53 say fdisctot picture "@Z 99999.99"
@ 07,53 say fcredtot picture "@Z 99999.99"
@ 08,53 say fcdwtot picture "@Z 99999.99"
@ 09,45 say foitem1
@ 10,45 say foitem2
@ 11,45 say foitem3
@ 12,45 say foitem4
@ 09,53 say fotot1 picture "@Z 99999.99"
@ 10,53 say fotot2 picture "@Z 99999.99"
@ 11,53 say fotot3 picture "@Z 99999.99"
@ 12,53 say fotot4 picture "@Z 99999.99"
@ 03,70 say fsurchg picture "@Z 99999.99"
@ 05,70 say ftaxtot picture "@Z 99999.99"
@ 06,70 say fpaitot picture "@Z 99999.99"
@ 07,70 say ffueltot picture "@Z 99999.99"
@ 08,70 say fdmgtot picture "@Z 99999.99"
@ 09,70 say ftotal picture "@Z 99999.99"
@ 11,71 say fdepamt picture "@Z 9999.99"
@ 12,71 say famtdue picture "@Z 9999.99"
@ 15,54 say fpaytyp1
@ 15,59 say famt1 picture "@Z 99999.99"
@ 16,54 say fpaytyp2
@ 16,59 say famt2 picture "@Z 99999.99"
@ 17,54 say fpaytyp3
@ 17,59 say famt3 picture "@Z 99999.99"
@ 15,69 say fdbacct1
@ 16,69 say fdbacct2

if empty (feunit)
   @ 21,02 say funit
   @ 22,02 say space (10)
   @ 21,28 say fdatein
   @ 21,37 say ftimein pict "99:99"
   @ 22,28 say space (8)
   @ 22,37 say space (5)
   @ 21,44 say fmlgout picture "99999"
   @ 21,50 say fmlgin picture "99999"
   @ 22,44 say space (5)
   @ 22,50 say space (5)
else
   @ 21,02 say feunit
   @ 22,02 say funit
   @ 21,28 say fexdate
   @ 21,37 say fextime pict "99:99"
   @ 22,28 say fdatein
   @ 22,37 say ftimein pict "99:99"
   @ 21,44 say femlgout picture "99999"
   @ 21,50 say femlgin picture "99999"
   @ 22,44 say fmlgout picture "99999"
   @ 22,50 say fmlgin picture "99999"
endif
@ 21,13 say fdateout
@ 21,22 say ftimeout pict "99:99"
@ 20,69 say fdays picture "9999"
@ 20,74 say frhr pict "99"
@ 21,63 say fresvno
@ 22,63 say frefno
@ 23,67 say fstamp
setcolor (gbluecolor)
