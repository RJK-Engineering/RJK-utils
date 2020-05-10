@echo off
if "%1"=="" goto HELP

for /f %%F in ('where %1.bat') do (
    SETLOCAL
    echo ==============================================================================
    echo %%F
    echo ==============================================================================
    type %%F
    echo.
)
goto END

:HELP
echo USAGE: %0 [search pattern]
echo Search for batch files and display their contents.
echo For search pattern help, see the "where" command.
:END
