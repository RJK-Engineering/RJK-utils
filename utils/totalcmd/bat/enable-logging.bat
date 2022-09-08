@echo off

cscript /nologo "%~dpn0.vbs" "Rob^ - Total Commander"

if "%COMMANDER_CONF_LOG_ENABLED%"=="1" (
    setx COMMANDER_CONF_LOG_ENABLED 0
    call settcbicon TotalCommander.bar "Conf: Log file" icons\c\red.ico
) else (
    setx COMMANDER_CONF_LOG_ENABLED 1
    call settcbicon TotalCommander.bar "Conf: Log file" icons\c\green.ico
)
