@ECHO OFF
SETLOCAL

IF "%~1"=="" GOTO USAGE

rem clear vars, they are inherited from master environment
SET display=
SET pause=
SET nopause=
SET quiet=
SET noerror=
SET redirect=
SET debug=
SET filelist=
SET cmd=
SET args=

:getopt
IF "%~1"=="" GOTO endgetopt
IF DEFINED args SET "args=%args% %1" & GOTO nextopt
IF "%~1"=="/?" GOTO HELP
IF "%~1"=="/f" SET "display=%%~fF" & GOTO nextopt
IF "%~1"=="/n" SET "display=%%~nxF" & GOTO nextopt
IF "%~1"=="/p" SET "pause=1" & GOTO nextopt
IF "%~1"=="/-p" SET "nopause=1" & GOTO nextopt
IF "%~1"=="/q" SET "quiet=>NUL" & GOTO nextopt
IF "%~1"=="/-e" SET "noerror=2>NUL" & GOTO nextopt
IF "%~1"=="/r" SET "redirect=2>&1" & GOTO nextopt
IF "%~1"=="/d" SET "debug=1" & GOTO nextopt
IF NOT DEFINED cmd SET "cmd=%1" & (IF "%~x1"==".bat" SET "cmd=call %1") & GOTO nextopt
IF NOT DEFINED filelist SET "filelist=%1" & GOTO nextopt
SET args=%1
:nextopt
SHIFT & GOTO getopt
:endgetopt

IF DEFINED debug (
    ECHO *=%*
    ECHO display=%display% pause=%pause% nopause=%nopause%
    ECHO quiet="%quiet%" noerror="%noerror%" redirect="%redirect%"
    ECHO filelist=%filelist%
    ECHO cmd=%cmd%
    ECHO args=%args%
    SET pause=1
)

IF NOT DEFINED filelist GOTO USAGE

FOR /F "tokens=*" %%F IN (%filelist%) DO (
    IF DEFINED debug (
        ECHO %%~fF
        ECHO %cmd% %args%
    ) ELSE (
        IF DEFINED display ECHO %display%
        %cmd% %args% %quiet% %noerror% %redirect%
    )
)
GOTO END

:HELP
SET help=1
:USAGE
ECHO USAGE: %0 [OPTIONS] [COMMAND] [OPTIONS] [FILELIST] [OPTIONS] [ARGS]
ECHO.
ECHO Execute COMMAND with ARGS for every file in FILELIST.
ECHO %%F in COMMAND or ARGS expands to the current file.
ECHO.
ECHO OPTIONS
ECHO./?   Display extended help.
ECHO./f   Display fully qualified path name before each execution.
ECHO./n   Display file name before each execution.
ECHO./p   Pause before exit (only pauses on error by default, overrides /-p).
ECHO./-p  No pause before exit (pauses on error by default).
ECHO./q   Be quiet (suppress standard output).
ECHO./-e  No error output (suppress standard error).
ECHO./r   Redirect standard error output to standard output.
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
    IF NOT DEFINED nopause SET pause=1
)
IF DEFINED pause pause
