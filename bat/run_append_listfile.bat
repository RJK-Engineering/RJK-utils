SET listfile=%TEMP%\CMD%RANDOM%.tmp
SET dellistfile=1

SET _args=%args%
SET args=%args% %listfile%

IF defined appendc (
    CALL getclip /d > %listfile%
) ELSE IF defined appendd (
    IF exist %listfile% del/q %listfile%
    IF defined dirpath PUSHD. & cd/d %dirpath%
    FOR /F "delims=" %%F IN ('dir/a-d/b') DO ECHO %%~fF>> %listfile%
    IF defined dirpath POPD
) ELSE IF defined appendn (
    dir/a-d/b %dirpath% > %listfile%
) ELSE IF defined appends (
    dir/a-d/b/s %dirpath% > %listfile%
) ELSE (
    SET dellistfile=
    SET args=%_args%
)
