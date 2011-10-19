set lib=f:\rac\lib
clipper @racres 
if errorlevel 1 goto err
blinker fi racres, alterror
:err
