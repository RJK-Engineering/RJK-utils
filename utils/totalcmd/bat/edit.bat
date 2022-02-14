@ECHO OFF
SETLOCAL

IF not defined EDITOR SET EDITOR=c:\progz\SciTE\SciTE.exe

IF "%~1"=="" EXIT/b
SET file=%1
IF exist %1 GOTO GO

FOR /f "delims=" %%F IN ('where %1') DO (
    ECHO %%F
    IF /i not "%%~xF"==".exe" IF /i not "%%~xF"==".com" (
        SET file=%%F
    )
)

:GO
START "" /b "%EDITOR%" %file%
