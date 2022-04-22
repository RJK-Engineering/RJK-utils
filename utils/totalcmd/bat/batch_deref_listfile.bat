SET line=
FOR /F "delims=" %%F IN (%listfile%) DO (
    IF defined line EXIT/B
    CALL SET line=%%F
)

IF not defined listfileext SET listfileext=txt
FOR /F %%F IN ("%line%") DO (
    IF /I not "%%~xF"==".%listfileext%" EXIT/B
)

SET listfile=%line%
