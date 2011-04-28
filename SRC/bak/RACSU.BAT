clipper racsu -l -o..\obj
if errorlevel 1 goto exit 
cd ..\obj
blinker @racsu
copy racsu.exe c:\racware
del racsu.obj
del racsu.exe
cd ..\3.30
