@echo off
if "%EDITOR%"=="" set EDITOR=c:\progz\SciTE\SciTE.exe

if "%~1"=="" (
    goto END
) else if exist "%~1" (
    start "" /b "%EDITOR%" %1
    goto END
)

set found=0
for /f "delims=" %%F in ('where %1') do (
    if /i not "%%~xF"==".exe" if /i not "%%~xF"==".com" start "" /b "%EDITOR%" "%%F"
    set found=1
)
if %found%==1 goto END

if "%2"=="new" (
    start "" /b "%EDITOR%" %1
) else (
    echo Add "new" to open new file.
)

:END
