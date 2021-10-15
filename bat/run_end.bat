
IF %errorlevel% gtr 0 (
    ECHO Exit code %errorlevel%
    IF not defined nopause SET pause=1
)

IF defined timeout TIMEOUT %timeout%
IF defined pause PAUSE
