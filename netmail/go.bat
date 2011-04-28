@echo off

rem RacWare email processing
:begin

osmail.exe

if exist rezdata.txt call sndrez.bat
if exist rezdata.txt del rezdata.txt 

if exist radata.txt  call sndra.bat
if exist radata.txt del radata.txt 

rem Set time delay (seconds)
sleep 10

rem goto begin
