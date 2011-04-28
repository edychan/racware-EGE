if "%1" == "" goto done
clipper %1 -l -o..\obj
if errorlevel 1 goto exit 

if "%2" == "" goto done
clipper %2 -l -o..\obj
if errorlevel 1 goto exit 

if "%3" == "" goto done
clipper %3 -l -o..\obj
if errorlevel 1 goto exit 

if "%4" == "" goto done
clipper %4 -l -o..\obj
if errorlevel 1 goto exit 

if "%5" == "" goto done
clipper %5 -l -o..\obj
if errorlevel 1 goto exit 

:done
cd ..\obj

:exit


