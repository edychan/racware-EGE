******************************
procedure errorsys

altd ()


******************************
function expr_error

parameters name, line, info, model, _1, _2, _3
private result, sample, _color1, _color2, _scn
_color1 = ""
_color2 = ""
_scn = ""

if info = "zero divide"
   if "%" $ model
      return _1
   else
      return 0
   end
end

altd (2)

if type ("result") != "U"
   return result
end

savscn (@_color1, @_color2, @_scn, 1)

if info = "type mismatch"
   sample = model
   sample = strtran (sample, "_1", type ("_1"))
   sample = strtran (sample, "_2", type ("_2"))
   sample = strtran (sample, "_3", type ("_3"))

   @ 24, 0 say "Proc " + name + " line " + ltrim (str (line)) + ", " + ;
      info + ": " + sample
   log_error ("Proc " + name + " line " + ltrim (str (line)) + ", " + ;
      info + ": " + sample)
else
   @ 24, 0 say "Proc " + name + " line " + ltrim (str (line)) + ", " + ;
      info
   log_error ("Proc " + name + " line " + ltrim (str (line)) + ", " + ;
      info)
end
inkey (0)
set cursor on
break


******************************
function misc_error

parameters name, line, info, model
private _color1, _color2, _scn
_color1 = ""
_color2 = ""
_scn = ""

altd (2)

savscn (@_color1, @_color2, @_scn, 1)
@ 24, 0 say "Proc " + name + " line " + ltrim (str (line)) + ", " + ;
   info + ": " + model
log_error ("Proc " + name + " line " + ltrim (str (line)) + ", " + ;
   info + ": " + model)

inkey (0)
set cursor on
break


******************************
function open_error

parameters name, line, info, model, _1
private _color1, _color2, _scn
_color1 = ""
_color2 = ""
_scn = ""

altd (2)

savscn (@_color1, @_color2, @_scn, 0)
@ 23, 0 say "Proc " + name + " line " + ltrim (str (line)) + ", "  + ;
   info + ": " + model + " " + _1
@ 24, 0 say "Press Esc to abort, any other key to retry..."
setcolor (_color2)
@ 24, 47 say ""
@ 24, 47 say ""

if inkey (0) == 27
   log_error ("Proc " + name + " line " + ltrim (str (line)) + ", "  + ;
      info + ": " + model + " " + _1)
   set cursor on
   break
end

rstscn (_color1, _scn, 0)
return .t.


******************************
function undef_error

parameters name, line, info, model, _1
private _color1, _color2, _scn
_color1 = ""
_color2 = ""
_scn = ""

altd (2)

savscn (@_color1, @_color2, @_scn, 0)
@ 23, 0 say "Proc " + name + " line " + ltrim (str (line)) + ", "  + ;
   info + ": " + " " + _1
log_error ("Proc " + name + " line " + ltrim (str (line)) + ", "  + ;
   info + ": " + " " + _1)
@ 24, 0 say "Press Esc to abort, any other key to retry..."
setcolor (_color2)
@ 24, 47 say ""
@ 24, 47 say ""

if inkey (0) == 27
   set cursor on
   break
end

rstscn (_color1, _scn, 0)
return .t.


******************************
function print_error

parameters name, line
private key, file, _color1, _color2, _scn
_color1 = ""
_color2 = ""
_scn = ""

savscn (@_color1, @_color2, @_scn, 0)
@ 23, 0 say "Proc " + name + " line " + ltrim (str (line)) + ;
   ", printer not ready"
@ 24, 0 say "Press [I]gnore, [R]etry, [F]ile, [Q]uit..."
setcolor (_color2)

do while .t.
   @ 24, 44 say ""
   @ 24, 44 say ""
   key = upper (chr (inkey (0)))

   if key == "Q"
      set cursor on
      break

   elseif key == "I"
      rstscn (_color1, _scn, 0)
      return .f.

   elseif key == "R"
      rstscn (_color1, _scn, 0)
      return .t.

   elseif key == "F"
      @ 24, 0
      accept "Filename - " to file
      set printer to (file)
      rstscn (_color1, _scn, 0)
      return .t.
   end
end


******************************
function db_error

parameters name, line, info
private _color1, _color2, _scn
_color1 = ""
_color2 = ""
_scn = ""

altd (2)

savscn (@_color1, @_color2, @_scn, 1)
@ 24, 0 say "Proc " + name + " line " + ltrim (str (line)) + ;
   ", " + info
log_error ("Proc " + name + " line " + ltrim (str (line)) + ;
   ", " + info)
inkey (0)
set cursor on
break


******************************
function log_error

parameters proc_error
private xsel

xsel = select ()

inkey (3)
select 0

if ! file ("raclog.dbf")
   create errortmp
   use errortmp exclusive
   append blank
   replace field_name with "PROCERR", field_type with "C", field_len with 80
   append blank
   replace field_name with "PROCDATE", field_type with "D", field_len with 8
   append blank
   replace field_name with "PROCTIME", field_type with "C", field_len with 8
   use

   create raclog from errortmp
   erase errortmp.dbf
endif

use raclog
append blank

rlock ()
replace procerr with proc_error
replace procdate with date ()
replace proctime with time ()
use
select (xsel)


******************************
function savscn

parameters xcolor1, xcolor2, xscn, xnum
private ycolor
set device to screen
if gete ("RACCOLOR") = "Y"
   ycolor = .t.
elseif gete ("RACCOLOR") = "N"
   ycolor = .f.
else
   ycolor = iscolor ()
endif
xcolor1 = setcolor (gmesscolor)
xcolor2 = if (ycolor, "*" + ltrim (gmesscolor), "N*/W")
xscn = savescreen (22 + xnum, 00, 24, 79)
@ 22 + xnum, 00 clear to 24, 79
@ 22 + xnum, 00 say replicate (chr (205), 80)
setcolor (xcolor2)
@ 22 + xnum, 30 say " SYSTEM ERROR "
setcolor (gmesscolor)


******************************
function rstscn

parameters xcolor, xscn, xnum
setcolor (xcolor)
restscreen (22 + xnum, 00, 24, 79, xscn)

