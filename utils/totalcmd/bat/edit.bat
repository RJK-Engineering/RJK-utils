@ECHO OFF
SETLOCAL

IF not defined EDITOR SET EDITOR=c:\progz\SciTE\SciTE.exe

IF "%~1"=="" GOTO END
IF exist %1 (
    START "" /b "%EDITOR%" %1
    GOTO END
)

SET found=
FOR /f "delims=" %%F IN ('where %1') DO (
    ECHO %%F
    IF /i not "%%~xF"==".exe" IF /i not "%%~xF"==".com" START "" /b "%EDITOR%" "%%F"
    SET found=1
)
IF defined found GOTO END

IF "%2"=="new" (
    START "" /b "%EDITOR%" %1
) ELSE (
    ECHO Add "new" to open new file.
)

:END
