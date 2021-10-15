ECHO USAGE: %script% [OPTIONS] [COMMAND] [OPTIONS] [FILELIST] [OPTIONS] [ARGS]
ECHO.
ECHO Execute COMMAND with ARGS for every file in FILELIST.
ECHO In ARGS, %%%%F expands to the current file (for help run: %script% /??).
ECHO.
IF "%help%"=="usage" (
    ECHO DISPLAY EXTENDED HELP: %script% /?
    ECHO DISPLAY FULL HELP: %script% /??
    GOTO END
)

ECHO OPTIONS
ECHO./d        Display path name before each execution.
ECHO./n        Display file name before each execution.
ECHO./p        Force pause before exit
ECHO./-p       Force no pause before exit (pauses on error by default)
ECHO./t [n]    Timeout before exit
ECHO./q        Be quiet (supress standard output)
ECHO./-e       Hide errors (supress error output)
ECHO./r        Redirect error output to standard output
ECHO./c        Redirect standard output to clipboard
ECHO /a [path] Append standard output to file
ECHO /o [path] Append standard output to file
ECHO /-        OPTIONS terminator, rest of command line are ARGS
IF "%help%"=="extended" GOTO END

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
ECHO.
ECHO BUGS: ARGS can't contain /?

:END
