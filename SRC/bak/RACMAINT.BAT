set lib=f:\rac\lib
clipper @racmaint -o..\obj
cd..\obj
blinker @racmaint
copy racmaint.exe f:\rac\dl-ege\racware
del racmaint.obj
del racmaint.exe
cd..\src

