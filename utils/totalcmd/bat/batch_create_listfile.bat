SET listfile=%TEMP%\CMD%RANDOM%.tmp
SET dellistfile=1

IF defined fromclip (
    >%listfile% CALL getclip /d
) ELSE IF defined fromdird (
    IF defined dirpath PUSHD. & cd/d %dirpath%
    IF exist %listfile% del/q %listfile%
    FOR /F "delims=" %%F IN ('dir/a-d/b') DO >>%listfile% ECHO %%~fF
    IF defined dirpath POPD
) ELSE IF defined fromdirn (
    >%listfile% dir/a-d/b %dirpath%
) ELSE IF defined fromdirs (
    >%listfile% dir/a-d/b/s %dirpath%
) ELSE (
    SET listfile=
    SET dellistfile=
)
