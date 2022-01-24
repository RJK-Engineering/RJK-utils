@ECHO OFF

IF /I "%~1"=="/install" (
    CALL %~dpn0_check.bat
    IF "%installed%"=="%~f0" (
        ECHO Script already installed.
        GOTO END
    )
    ECHO Installing cmd.exe auto-run script %~f0
    IF NOT "%installed%"=="" (
        ECHO Warning! Replacing currently installed cmd.exe auto-run script: %installed%
    )
    reg add "HKCU\Software\Microsoft\Command Processor" /v "AutoRun" /t REG_EXPAND_SZ /d "%~f0"
    GOTO INFO
) ELSE IF /I "%~1"=="/uninstall" (
    ECHO Uninstalling cmd.exe auto-run script
    PAUSE
    reg delete "HKCU\Software\Microsoft\Command Processor" /v "AutoRun" /f
    GOTO END
) ELSE IF /I "%~1"=="/check" (
    CALL %~dpn0_check.bat
    ECHO Currently installed cmd.exe auto-run script: %installed%
    GOTO END
)

ENDLOCAL
SET AUTORUN_MACROS=%~dpn0.macros.properties
DOSKEY /MACROFILE=%AUTORUN_MACROS%
SET tempfile=%TEMP%\cmd-autorun-startup-info-lockfile
IF EXIST %tempfile% GOTO END
ECHO.> %tempfile%

:INFO
ECHO.
ECHO Running cmd.exe auto-run script, to uninstall this script run: %0 /uninstall
ECHO.
ECHO Available DOSKEY macros:
DOSKEY /MACROS
ECHO.

:END

REM Exit code of this autorun script is exit code of "cmd /c" execution!!!
REM If bat file on next line is executed that will determine the exit code.
IF EXIST %~dpn0_local.bat %~dpn0_local.bat
REM If bat file on previous line is executed the rest of this script
REM is not executed bacause no CALL is used to execute the bat file.
REM Using CALL will result in recursive execution of cmd.exe!!!
