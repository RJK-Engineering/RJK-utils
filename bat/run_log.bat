IF not defined COMMANDER_RUN_LOG EXIT/B

REM IMPORTANT: Use a FOR loop to prevent pitfall in "ECHO %*>> file":
REM when %* ends with " 1" or " 2", 1 or 2 will be interpreted as
REM magic number for standard output or standard error: " 1>> file"
FOR /F "tokens=*" %%F IN ("%DATE% %TIME% %*") DO (
    ECHO %%F>> "%COMMANDER_RUN_LOG%"
)
