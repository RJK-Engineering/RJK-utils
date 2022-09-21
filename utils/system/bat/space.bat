@echo off
setlocal

set minutes=%1
if not defined minutes set minutes=30
set/a seconds=minutes*60

%~dp0..\sendkeys\sendkeys.bat " " %seconds%
