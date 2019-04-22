@echo off

perl -I "%~dp0..\fs\lib" "%~dp0..\fs\sync.pl" %*

if %errorlevel% gtr 0 pause
