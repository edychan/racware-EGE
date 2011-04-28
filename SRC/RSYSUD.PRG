private yfile
f_clrscn ("DATABASE INQUIRY")

set delete off
set exclusive off

do while .t.
   yfile = space (30)
   @ 02, 02 say "Enter database name: " get yfile picture replicate ("!", 30)
   if f_rd () = 27
      exit
   endif
   if .not. f_use (trim (yfile))
      loop
   endif
   f_dbedit ()
   use
enddo
set delete on

