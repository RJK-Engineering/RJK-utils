IF not defined listfileext SET listfileext=txt

SET line=
FOR /F "delims=" %%F IN (%listfile%) DO (
    IF defined line EXIT/B
    IF /I not "%%~xF"==".%listfileext%" EXIT/B
    SET line=%%F
)
SET listfile=%line%
