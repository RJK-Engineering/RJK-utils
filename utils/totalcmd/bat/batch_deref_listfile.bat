IF not defined listfileext SET listfileext=txt
IF /I not "%~x1"==".%listfileext%" EXIT/B

SET line=
FOR /F "delims=" %%F IN (%listfile%) DO (
    IF defined line EXIT/B
    CALL SET line=%%F
)
SET listfile=%line%
