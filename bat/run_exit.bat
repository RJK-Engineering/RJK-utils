
IF defined error (
    ECHO %error%
    IF defined COMMANDER_RUN_LOG ECHO %error%>> %COMMANDER_RUN_LOG%
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
    IF defined COMMANDER_RUN_LOG ECHO %errorlevel%>> %COMMANDER_RUN_LOG%
    IF defined ignoreexitcode EXIT/B
    IF not defined printexitcode ECHO Exit code %errorlevel%
    PAUSE
)
