@ECHO OFF
SETLOCAL

IF not defined EDITOR SET EDITOR=c:\progz\SciTE\SciTE.exe
IF "%~1"=="" EXIT/b 1

FOR %%F IN (%*) DO (
    IF exist "%%~F" (
        CALL :EDIT "%%~F"
    ) ELSE (
        CALL :FIND "%%~F"
        IF not defined found CALL :EDIT "%%~F"
    )
)
EXIT/b

:FIND
SET found=
FOR /f "delims=" %%F IN ('where %1') DO (
    IF /i not "%%~xF"==".exe" IF /i not "%%~xF"==".com" (
        CALL :EDIT "%%~F"
        SET found=1
    )
)
EXIT/b

:EDIT
ECHO %1
START "" /b "%EDITOR%" %1
EXIT/b
