*
* export ascii data
*
f_clrscn ("EXPORT CUSTOMER DATA")

f_box (02, 03, 04, 70)
yfil = space(40)
@ 03, 05 say "Enter ASCII filename: " get yfil

if f_rd () = 27 .or. empty(yfil)
   return
endif

f_popup ("Please wait while processing ....")
f_use ("racust")
* copy to &yfil delimited

set device to print
set printer to &yfil
setprc (0,0)
yln = 0
do while .not. eof ()
   @yln, 00 say fcustno+[ ]+flname+[ ]+ffname+[ ]+faddr+[ ]+fcity+[ ]+   ;
                fstate+[ ]+fzip+[ ]+fphone
   yln = yln + 1
   skip
enddo

set printer to
set console on
set print off
set device to screen

f_valid (.f., "Process Completed...")
close all


