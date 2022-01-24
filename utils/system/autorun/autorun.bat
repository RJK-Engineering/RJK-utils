@ECHO OFF

IF /I "%~1"=="/install" (
    CALL %~dpn0_check.bat
    GOTO INSTALL
) ELSE IF /I "%~1"=="/uninstall" (
    ECHO Uninstalling cmd.exe auto-run script
    PAUSE
    reg delete "HKCU\Software\Microsoft\Command Processor" /v "AutoRun" /f
    GOTO END
) ELSE IF /I "%~1"=="/check" (
    CALL %~dpn0_check.bat
    GOTO END
)

ENDLOCAL
SET AUTORUN_MACROS=%~dpn0.macros.properties
DOSKEY /MACROFILE=%AUTORUN_MACROS%
SET tempfile=%TEMP%\cmd-autorun-startup-info-lockfile
IF EXIST %tempfile% GOTO END
ECHO.> %tempfile%

:INSTALL
IF "%installed%"=="%~f0" (
    ECHO Script already installed.
    SET installed=
    GOTO END
)
ECHO Installing cmd.exe auto-run script %~f0
IF defined installed ECHO Warning! Replacing currently installed cmd.exe auto-run script: %installed%
SET installed=
REG add "HKCU\Software\Microsoft\Command Processor" /v "AutoRun" /t REG_EXPAND_SZ /d "%~f0"

:INFO
ECHO.
ECHO Running cmd.exe auto-run script, to uninstall this script run: %0 /uninstall
ECHO.
ECHO Available DOSKEY macros:
DOSKEY /MACROS
ECHO.

REM NOTE: CALL is not used because it will result in recursive execution of cmd.exe,
REM however not using CALL means that the rest of this script will not be executed!
IF EXIST %~dpn0_local.bat %~dpn0_local.bat
GOTO END

:END
IF defined installed (
    ECHO Currently installed cmd.exe auto-run script: %installed%
    SET installed=
)
REM make sure errorlevel is set to zero after execution of this script
EXIT /b 0
