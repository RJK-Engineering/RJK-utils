IF not defined COMMANDER_RUN_LOG EXIT/B

REM %1 MUST NOT END WITH: " 2"
REM -> this will result in a redirect: " 2>> logfile"
rem ECHO %DATE% %TIME% %~1>> "%COMMANDER_RUN_LOG%"

FOR /F "tokens=*" %%F IN ("%DATE% %TIME% %~1") DO (
    ECHO %%F>> "%COMMANDER_RUN_LOG%"
)
