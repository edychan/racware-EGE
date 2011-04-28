f_clrscn ("Fleet Status Summary Table")

yloc = gloc
set key 28 to rivlfhlp
@ 2, 5 say "Enter Location.... " get yloc pict "!!!!!!!!!!" ;
      valid f_valid ((yloc + ";") $ gusrloc)
if f_rd () = 27
   set key 28 to
   return
endif
set key 28 to

f_popup ("Please Wait...", .f.)
f_use ("ravm")
select 0
if .not. file (gstnpath + "ralfs.dbf")
   create (gstnpath + "stru")
   use (gstnpath + "stru") exclusive
   append blank
   replace field_name with "FCLASS"
   replace field_type with "C"
   replace field_len with 4
   replace field_dec with 0
   append blank
   replace field_name with "FAVAIL"
   replace field_type with "N"
   replace field_len with 5
   replace field_dec with 0
   append blank
   replace field_name with "FOUT"
   replace field_type with "N"
   replace field_len with 5
   replace field_dec with 0
   append blank
   replace field_name with "FHOLD"
   replace field_type with "N"
   replace field_len with 5
   replace field_dec with 0
   append blank
   replace field_name with "FIN"
   replace field_type with "N"
   replace field_len with 5
   replace field_dec with 0
   use
   create (gstnpath + "ralfs") from (gstnpath + "stru")
   erase (gstnpath + "stru.dbf")
endif
use (gstnpath + "ralfs") exclusive alias ralfs
index on fclass to (gstnpath + "ralfs")
set index to (gstnpath + "ralfs")
zap

select ravm
set filter to floc = yloc
go top
store 0 to yanum, yonum, yhnum, yinum
do while .not. eof ()
   select ralfs
   seek ravm->fclass
   if .not. found ()
      append blank
      replace fclass with ravm->fclass
      commit
   endif
   do case
      case ravm->fstatus = "A"
         replace favail with favail + 1
         yanum = yanum + 1
      case ravm->fstatus = "O"
         replace fout with fout + 1
         yonum = yonum + 1
      case ravm->fstatus = "H"
         replace fhold with fhold + 1
         yhnum = yhnum + 1
      case ravm->fstatus = "I"
         replace fin with fin + 1
         yinum = yinum + 1
   endcase
   select ravm
   skip
enddo
select ralfs
f_popback ()
if reccount () = 0
   f_popup ("No Vehicles Found In This Location... Press Any Key...", .t.)
else
   setcolor (gpickback)
   f_box (4, 5, 6, 55)
   @ 4, 6 say "ÄÄÄÄÄÄÄÄÄAvailÄÄÄÄÄÄInÄÄÄÄÄOutÄÄÄÄHoldÄÂÄÄÄTotalÄ"
   @ 5, 11 say str (yanum, 9) + str (yinum, 8) + str (yonum, 8) ;
      + str (yhnum, 8) + " ³" + str (yanum + yinum + yonum + yhnum, 8)
   @ 6, 5 say "Ã"
   @ 6, 55 say "´"
   f_pick_f (6, 5, "", "NOTITLE", ;
      "[ ]+fclass+str(favail,9)+str(fin,8)+str(fout,8)+str(fhold,8)+" + ;
      "[ ³]+str(favail+fin+fout+fhold,8)+[ ]", "X")
endif
close databases


******************************
procedure rivlfhlp

f_use ("raloc", 1)
go top
if .not. eof ()
   if f_pick_f (03, 05, "", "", "floc+[->]+substr(fname,1,25)")
      yloc = raloc->floc
      keyboard chr(13)
   endif
endif

