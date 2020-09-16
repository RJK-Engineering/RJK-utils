@echo off
if "%EDITOR%"=="" set EDITOR=c:\progz\SciTE\SciTE.exe

if not "%2" == "" (
    goto END
) else if "%~1" == "" (
    goto END
) else if exist "%~1" (
    start "" /b "%EDITOR%" %*
) else (
    goto SEARCH
)
goto END

:SEARCH
set found=0
for /f %%F in ('where %1') do (
    start "" /b "%EDITOR%" %%F
    set found=1
)

:NEW
if %found%==0 start "" /b "%EDITOR%" %*

:END
