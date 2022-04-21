SET listfile=%TEMP%\CMD%RANDOM%.tmp
SET dellistfile=1

SET _args=%args%
SET args=%args% %listfile%

IF defined appendc (
    >%listfile% CALL getclip /d
) ELSE IF defined appendd (
    IF exist %listfile% del/q %listfile%
    IF defined dirpath PUSHD. & cd/d %dirpath%
    FOR /F "delims=" %%F IN ('dir/a-d/b') DO >>%listfile% ECHO %%~fF
    IF defined dirpath POPD
) ELSE IF defined appendn (
    >%listfile% dir/a-d/b %dirpath%
) ELSE IF defined appends (
    >%listfile% dir/a-d/b/s %dirpath%
) ELSE (
    SET dellistfile=
    SET args=%_args%
)
