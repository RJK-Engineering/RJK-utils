@echo off

if not defined RJK_UTILS_HOME FOR /F "delims=" %%P IN ("%~dp0..") DO set RJK_UTILS_HOME=%%~dpfP

perl "%RJK_UTILS_HOME%\%RJK_UTIL%" %*

if %errorlevel% gtr 0 pause