@echo off

if not defined RJK_UTILS_HOME FOR /F "delims=" %%P IN ("%~dp0..") DO set RJK_UTILS_HOME=%%~dpfP

perl %RJK_UTILS_HOME%\utils\%*

if %errorlevel% gtr 0. (
    if not defined RJK_UTIL_NOPAUSEONERROR pause
) else if defined COMMANDER_INI (
    if not defined RJK_UTIL_NOPAUSE pause
)
