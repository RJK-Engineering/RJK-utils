SET tmpfile=%TEMP%\CMD%RANDOM%.tmp

FOR /F "delims=" %%F IN (%listfile%) DO (
    FOR /F "delims=" %%G IN ('dir/b/s %%F') DO >>%tmpfile% ECHO %%G
)

SET listfile=%tmpfile%
SET dellistfile=1
