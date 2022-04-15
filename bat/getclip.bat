@echo off

REM display clipboard
IF "%~1"=="/d" (
    CSCRIPT /nologo /e:JScript "%~dpn0.js"
    EXIT/b
)

REM set %clip% to first line on clipboard
SET clip=
FOR /f "delims=" %%F in ('CSCRIPT /nologo /e:JScript "%~dpn0.js"') DO (
    SET "clip=%%F"
    EXIT/b
)
