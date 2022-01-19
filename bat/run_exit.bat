
IF defined error (
    ECHO %error%
    IF not defined ignoreerrors PAUSE
) ELSE IF %errorlevel% gtr 0 (
    ECHO Exit code %errorlevel%
    IF not defined ignoreexitcode PAUSE
)
