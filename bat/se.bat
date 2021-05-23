@echo off

REM set environment/switch between environments

if not "%~1"=="" (
    set _environment=%~df1
) else if "%_environment%"=="" (
    rem initial environment
    set _environment=c:\workspace
) else (
    if /i "%cd:~0,12%"=="c:\workspace" (
        set _environment=c:\scripts
    ) else if /i "%cd:~0,10%"=="c:\scripts" (
        set _environment=c:\workspace
    )
)

FOR /F "tokens=1-10 delims=\ " %%i in ("%cd%") do (
    set _subdirs=%%k\%%l\%%m\%%n\%%o\%%p\%%q\%%r
)

if not exist "%_environment%" echo Environment does not exist & goto END

if "%_environment%"=="c:\workspace" (
    set "PATH=%PATH:c:\scripts\RJK-utils\bat=c:\workspace\RJK-utils\bat%"
    set "PATH=%PATH:c:\scripts\RJK-utils\utils\bat=c:\workspace\RJK-utils\utils\bat%"
    set "PATH=%PATH:c:\scripts\RJK-utils\utils\totalcmd\bat=c:\workspace\RJK-utils\utils\totalcmd\bat%"
    set "PERL5LIB=%PERL5LIB:c:\scripts\RJK-perl5lib\lib=c:\workspace\RJK-perl5lib\lib%"
) else if "%_environment%"=="c:\scripts" (
    set "PATH=%PATH:c:\workspace\RJK-utils\bat=c:\scripts\RJK-utils\bat%"
    set "PATH=%PATH:c:\workspace\RJK-utils\utils\bat=c:\scripts\RJK-utils\utils\bat%"
    set "PATH=%PATH:c:\workspace\RJK-utils\utils\totalcmd\bat=c:\scripts\RJK-utils\utils\totalcmd\bat%"
    set "PERL5LIB=%PERL5LIB:c:\workspace\RJK-perl5lib\lib=c:\scripts\RJK-perl5lib\lib%"
) else if defined _environment (
    echo Invalid environment & goto END
)

if defined _environment (
    set RJK_UTILS_HOME=%_environment%\RJK-utils
    cd /d "%_environment%"
    FOR /F "tokens=1-10 delims=\ " %%i in ("%_subdirs%") do (
        cd %%i>NUL 2>&1 && cd %%j>NUL 2>&1 && cd %%k>NUL 2>&1 && cd %%l>NUL 2>&1 && cd %%m>NUL 2>&1 && ^
        cd %%n>NUL 2>&1 && cd %%o>NUL 2>&1 && cd %%p>NUL 2>&1 && cd %%q>NUL 2>&1 && cd %%r>NUL 2>&1
    )
) else (
    echo Not in environment
    goto END
)

echo PATH=%PATH%
echo PERL5LIB=%PERL5LIB%
echo RJK_UTILS_HOME=%RJK_UTILS_HOME%

:END
