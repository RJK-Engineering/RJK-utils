IF not defined COMMANDER_RUN_LOG EXIT/B

REM IMPORTANT: Use a FOR loop to prevent pitfall in "ECHO %1>> file":
REM When %1 ends with " 1" or " 2", 1 or 2 will be interpreted as
REM magic number for standard output and standard error: " 1>> file"
FOR /F "tokens=*" %%F IN ("%DATE% %TIME% %~1") DO (
    ECHO %%F>> "%COMMANDER_RUN_LOG%"
)
