
IF defined error (
    ECHO %error%
    CALL run_log ERROR %error%
    IF not defined ignoreerrors PAUSE
    EXIT/B 1
)

SET exitcode=%errorlevel%

IF defined printexitcode (
    IF %errorlevel%==0 (
        ECHO Exit code %errorlevel% ^(success^)
    ) ELSE (
        ECHO Exit code %errorlevel%
    )
)

IF %errorlevel% gtr 0 (
    CALL run_log Exit code %errorlevel%
    IF defined ignoreexitcode EXIT/B
    IF not defined printexitcode ECHO Exit code %errorlevel%
    PAUSE
)
