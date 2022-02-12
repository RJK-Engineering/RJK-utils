@echo off

call mpc /open "%~dpn1"

:try
    timeout 1
    call run /x c:\workspace\mpc-utils\tools\video-settings\MPCSetVideoSettings.bat "%~dpn1"
if %errorlevel% gtr 0 goto :try
