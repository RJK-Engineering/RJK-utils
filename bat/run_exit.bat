
IF defined error (
    ECHO %error%
    IF not defined ignoreerrors PAUSE & SET paused=1
) ELSE IF %errorlevel% gtr 0 (
    ECHO Exit code %errorlevel%
    IF not defined ignoreexitcode PAUSE & SET paused=1
)
