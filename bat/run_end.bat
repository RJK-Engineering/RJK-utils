
IF %errorlevel% GTR 0 (
    ECHO Exit code %errorlevel%
    IF NOT DEFINED nopause SET pause=1
)

IF DEFINED timeout timeout %timeout%
IF DEFINED pause pause
