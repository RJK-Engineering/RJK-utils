SET delfilec=&SET delfiled=&SET delfilen=&SET delfiles=

SET listfile=%TEMP%\CMD%RANDOM%c.tmp
ECHO %args% | FIND "%%C" >NUL
IF %errorlevel% equ 0 (
    FOR /F %%C IN ("%listfile%") DO SET args=%args%
    CALL getclip /d > %listfile%
    SET delfilec=%listfile%
)

SET listfile=%TEMP%\CMD%RANDOM%d.tmp
ECHO %args% | FIND "%%D" >NUL
IF %errorlevel% equ 0 (
    FOR /F %%D IN ("%listfile%") DO SET args=%args%
    IF defined paramdir PUSHD. & cd/d %paramdir%
    IF exist %listfile% del/q %listfile%
    FOR /F "delims=" %%F IN ('dir/a-d/b') DO ECHO %%~fF>> %listfile%
    IF defined paramdir POPD
    SET delfiled=%listfile%
)

SET listfile=%TEMP%\CMD%RANDOM%n.tmp
ECHO %args% | FIND "%%N" >NUL
IF %errorlevel% equ 0 (
    FOR /F %%N IN ("%listfile%") DO SET args=%args%
    dir/a:-d/b %paramdir% > %listfile%
    SET delfilen=%listfile%
)

SET listfile=%TEMP%\CMD%RANDOM%s.tmp
ECHO %args% | FIND "%%S" >NUL
IF %errorlevel% equ 0 (
    FOR /F %%S IN ("%listfile%") DO SET args=%args%
    dir/a:-d/b/s %paramdir% > %listfile%
    SET delfiles=%listfile%
)
