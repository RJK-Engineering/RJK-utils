FOR /F "tokens=* usebackq" %%F IN ("%~1") DO (
    %COMMANDER_EXE% /o /s /l="%%~fF" /t
)
