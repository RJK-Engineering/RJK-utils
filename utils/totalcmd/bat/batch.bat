@ECHO OFF
SETLOCAL

SET script=%0
IF "%~1"=="" GOTO USAGE

REM clear vars, they are inherited from master environment
FOR %%V IN (cmd filelist args display pause nopause timeout quiet errorredirect clip output call) do set %%V=

:GETOPT
IF "%~1"=="" GOTO ENDGETOPT
IF DEFINED args SET args=%args% %1&        GOTO NEXTOPT
IF "%~1"=="/?" GOTO HELP
IF "%~1"=="/f"  SET display=%%~fF&         GOTO NEXTOPT
IF "%~1"=="/n"  SET display=%%~nxF&        GOTO NEXTOPT
IF "%~1"=="/p"  SET pause=1& SET nopause=& GOTO NEXTOPT
IF "%~1"=="/-p" SET nopause=1& SET pause=& GOTO NEXTOPT
IF "%~1"=="/t"  SET timeout=%2&    SHIFT & GOTO NEXTOPT
IF "%~1"=="/q"  SET "quiet=>NUL"         & GOTO NEXTOPT
IF "%~1"=="/-e" SET "errorredirect=2>NUL"& GOTO NEXTOPT
IF "%~1"=="/r"  SET "errorredirect=2>&1" & GOTO NEXTOPT
IF "%~1"=="/c"  SET "clip=|CLIP"         & GOTO NEXTOPT
IF "%~1"=="/a"  SET "append=>>%2"& SHIFT & GOTO NEXTOPT
IF "%~1"=="/-"  SET args=%2&       SHIFT & GOTO NEXTOPT
IF NOT DEFINED cmd (
    SET cmd=%1
    SET extension=%~x1
) ELSE IF NOT DEFINED filelist (
    SET filelist=%1
) ELSE (
    SET args=%1
)
:NEXTOPT
SHIFT & GOTO GETOPT
:ENDGETOPT

IF NOT DEFINED filelist GOTO USAGE

IF "%extension%"==".pl"  SET call=perl
IF "%extension%"==".bat" SET call=call

IF DEFINED call SET cmd=%call% %cmd%
IF DEFINED errorredirect SET "errorredirect= %errorredirect%"

FOR /F "tokens=*" %%F IN (%filelist%) DO (
    IF DEFINED display ECHO %display%
    %cmd% %args%%quiet%%append%%errorredirect%%clip%
)
GOTO END

:HELP
SET help=1
:USAGE
ECHO USAGE: %script% [OPTIONS] [COMMAND] [OPTIONS] [FILELIST] [OPTIONS] [ARGS]
ECHO.
ECHO Execute COMMAND with ARGS for every file in FILELIST.
ECHO %%F in COMMAND or ARGS expands to the current file.
ECHO.
ECHO OPTIONS
ECHO./?   Display extended help.
ECHO./f   Display fully qualified path name before each execution.
ECHO./n   Display file name before each execution.
ECHO./p        Force pause before exit
ECHO./-p       Force no pause before exit (pauses on error by default)
ECHO./t [n]    Timeout before exit
ECHO./q        Be quiet (supress standard output)
ECHO./-e       Hide errors (supress error output)
ECHO./r        Redirect error output to standard output
ECHO./c        Redirect standard output to clipboard
ECHO /a [path] Append standard output to file
ECHO /-        OPTIONS terminator, rest of command line are ARGS
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
call run_end
