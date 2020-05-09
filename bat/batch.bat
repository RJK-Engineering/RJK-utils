@ECHO OFF
SETLOCAL

rem extended help
IF "%~1" == "/?" GOTO HELP

rem arguments: [COMMAND] [OPTIONS] [FILELISTFILE] [ARGS]

rem [COMMAND] required
IF "%~1" == "" GOTO USAGE
SET cmd=%1
rem use "call" for batch files
IF "%~x1" == ".bat" SET cmd=call %1
SHIFT

rem [OPTIONS]
:getopt
IF "%~1" == "/?" GOTO HELP
IF "%~1" == "/f" SET display=%%~fF & GOTO nextopt
IF "%~1" == "/n" SET display=%%~nxF & GOTO nextopt
IF "%~1" == "/p" SET pause=1 & GOTO nextopt
IF "%~1" == "/q" SET quiet=1 & GOTO nextopt
IF "%~1" == "/r" SET redirect=1 & GOTO nextopt
IF "%~1" == "/d" SET debug=1 & GOTO nextopt
GOTO endgetopt
:nextopt
SHIFT & GOTO getopt
:endgetopt

rem [FILELISTFILE] required
IF "%~1" == "" GOTO USAGE
SET filelist=%1 & SHIFT

rem [ARGS]
:getarg
IF "%~1" == "" GOTO endgetarg
IF "%~1" == "--" GOTO endgetarg
IF DEFINED args (SET args=%args% %1) ELSE (SET args=%1)
SHIFT & GOTO getarg
:endgetarg

IF DEFINED debug (
    ECHO filelist: %filelist%
    ECHO cmd: %cmd%
    ECHO args: %args%
    ECHO display: %display%
    SET pause=1
)

FOR /F "tokens=*" %%F IN (%filelist%) DO (
    IF DEFINED debug (
        ECHO %%~fF
        ECHO %cmd% %args%
    ) ELSE (
        IF DEFINED display ECHO %display%
        IF DEFINED quiet (%cmd% %args% >NUL) ELSE IF DEFINED redirect (%cmd% %args% 2>&1) ELSE (%cmd% %args%)
    )
)
GOTO END

:HELP
SET help=1
:USAGE
ECHO USAGE: %0 [COMMAND] [OPTIONS] [FILELISTFILE] [ARGS]
ECHO.
ECHO Execute COMMAND with ARGS for every file in FILELISTFILE.
ECHO %%F in COMMAND or ARGS expands to the current file.
ECHO In ARGS, arguments after a "--" will be ignored.
ECHO.
ECHO OPTIONS
ECHO./?   Display extended help.
ECHO./f   Display fully qualified path name before each execution.
ECHO./n   Display file name before each execution.
ECHO./p   Pause before exit.
ECHO./q   Be quiet (suppress standard output).
ECHO./d   Debug mode.
IF NOT DEFINED help GOTO END

ECHO.
ECHO Example usage in Total Commander:
ECHO     Command:   batch.bat command.exe /n
ECHO     Params:    ?/p %%L "%%%%~nxF"
ECHO Extra OPTIONS can be added or removed quickly (by pressing HOME) at
ECHO the start of the parameter list in the dialog box opened on execution.

ECHO.
ECHO The following table lists the modifiers you can use in expansion.
ECHO %%~F    Expands %%F and removes any surrounding quotation marks ("").
ECHO %%~fF   Expands %%F to a fully qualified path name.
ECHO %%~dF   Expands %%F to a drive letter.
ECHO %%~pF   Expands %%F to a path.
ECHO %%~nF   Expands %%F to a file name.
ECHO %%~xF   Expands %%F to a file extension.
ECHO %%~sF   Expanded path contains short names only.
ECHO %%~aF   Expands %%F to file attributes.
ECHO %%~tF   Expands %%F to date and time of file.
ECHO %%~zF   Expands %%F to size of file.
ECHO %%~$P:F Searches the directories listed in the P environment variable and expands %%F to the fully qualified name of the first one found. If the environment variable name is not defined or the file is not found, this modifier expands to the empty string.
ECHO.
ECHO The following table lists possible combinations of modifiers and qualifiers that you can use to get compound results.
ECHO %%~dpF    Expands %%F to a drive letter and path.
ECHO %%~nxF    Expands %%F to a file name and extension.
ECHO %%~dp$P:F Searches the directories listed in the P environment variable for %%F and expands to the drive letter and path of the first one found.
ECHO %%~ftzaF  Expands %%F to a dir-like output line.
ECHO.
ECHO (source: http://www.microsoft.com/resources/documentation/windows/xp/all/proddocs/en-us/percent.mspx)

:END
IF %errorlevel% GTR 0 (
    ECHO Error level %errorlevel%
    SET pause=1
)
IF DEFINED pause pause
