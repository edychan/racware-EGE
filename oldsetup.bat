@echo off
subst f: c:\
subst i: c:\
subst j: c:\

set racdrv=F:
set racsid=stn00
set racpth=\rac\dl-ege\
cd j:%racpth%racware\dbf
cd i:%racpth%racware\stn\stn00
f:
cd %racpth%racware

