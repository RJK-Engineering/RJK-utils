
IF defined printexitcode (
    IF %errorlevel%==0 (
        ECHO Exit code %errorlevel% ^(success^)
    ) ELSE (
        ECHO Exit code %errorlevel%
    )
)

IF defined error (
    ECHO %error%
    IF not defined ignoreerrors PAUSE
) ELSE IF %errorlevel% gtr 0 (
    IF not defined printexitcode ECHO Exit code %errorlevel%
    IF not defined ignoreexitcode PAUSE
)
