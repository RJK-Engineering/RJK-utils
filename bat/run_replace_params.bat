SET delfilec=&SET delfiled=&SET delfilen=&SET delfiles=

SET clip=
ECHO %args% | FINDSTR "%%~*[dpnxf]*F" >NUL
IF %errorlevel% equ 0 CALL getclip
IF defined clip FOR /F "tokens=*" %%F IN (""%clip%"") DO SET args=%args%

SET tmpfile=%TEMP%\CMD%RANDOM%c.tmp
ECHO %args% | FIND "%%C" >NUL
IF %errorlevel% equ 0 (
    FOR /F %%C IN ("%tmpfile%") DO SET args=%args%
    CALL getclip /d > %tmpfile%
    SET delfilec=%tmpfile%
)

SET tmpfile=%TEMP%\CMD%RANDOM%d.tmp
ECHO %args% | FIND "%%D" >NUL
IF %errorlevel% equ 0 (
    FOR /F %%D IN ("%tmpfile%") DO SET args=%args%
    IF defined paramdir PUSHD. & cd/d %paramdir%
    IF exist %tmpfile% del/q %tmpfile%
    FOR /F "delims=" %%F IN ('dir/a-d/b') DO ECHO %%~fF>> %tmpfile%
    IF defined paramdir POPD
    SET delfiled=%tmpfile%
)

SET tmpfile=%TEMP%\CMD%RANDOM%n.tmp
ECHO %args% | FIND "%%N" >NUL
IF %errorlevel% equ 0 (
    FOR /F %%N IN ("%tmpfile%") DO SET args=%args%
    dir/a:-d/b %paramdir% > %tmpfile%
    SET delfilen=%tmpfile%
)

SET tmpfile=%TEMP%\CMD%RANDOM%s.tmp
ECHO %args% | FIND "%%S" >NUL
IF %errorlevel% equ 0 (
    FOR /F %%S IN ("%tmpfile%") DO SET args=%args%
    dir/a:-d/b/s %paramdir% > %tmpfile%
    SET delfiles=%tmpfile%
)
