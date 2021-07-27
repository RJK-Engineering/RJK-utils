
IF %errorlevel% GTR 0 (
    ECHO Error level %errorlevel%
    IF NOT DEFINED nopause SET pause=1
)

IF DEFINED pause pause
