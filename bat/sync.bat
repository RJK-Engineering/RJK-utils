@echo off

perl -I "%~dp0..\utils\fs\lib" "%~dp0..\utils\fs\sync.pl" %*

if %errorlevel% gtr 0 pause
