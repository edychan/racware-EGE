do while .t.
   ypos = 0
   do while ypos = 0
      ycardinfo = card_read  ()
      ypos = at('%',ycardinfo)
   enddo
   gccinfo = substr(ycardinfo,ypos+1,at('?', ycardinfo)-ypos-1)
   ? gccinfo
   ? len(gccinfo)
   inkey (0)
enddo  

