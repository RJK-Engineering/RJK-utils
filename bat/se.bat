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

if not exist "%_environment%" echo Environment does not exist & EXIT/B

set _r=%_environment%\
if "%_environment%"=="c:\scripts" (
    set _s=c:\workspace\
) else (
    set _s=c:\scripts\
)

call set PATH=%%PATH:%_s%RJK-utils\bat=%_r%RJK-utils\bat%%
call set PATH=%%PATH:%_s%RJK-utils\utils\bat=%_r%RJK-utils\utils\bat%%
call set PATH=%%PATH:%_s%RJK-utils\utils\system\bat=%_r%RJK-utils\utils\system\bat%%
call set PATH=%%PATH:%_s%RJK-utils\utils\tbmtv\bat=%_r%RJK-utils\utils\tbmtv\bat%%
call set PATH=%%PATH:%_s%RJK-utils\utils\totalcmd\bat=%_r%RJK-utils\utils\totalcmd\bat%%
call set PERL5LIB=%%PERL5LIB:%_s%RJK-perl5lib\lib=%_r%RJK-perl5lib\lib%%

if defined _environment (
    set RJK_UTILS_HOME=%_environment%\RJK-utils
    cd /d "%_environment%"
    FOR /F "tokens=1-10 delims=\ " %%i in ("%_subdirs%") do (
        cd %%i>NUL 2>&1 && cd %%j>NUL 2>&1 && cd %%k>NUL 2>&1 && cd %%l>NUL 2>&1 && cd %%m>NUL 2>&1 && ^
        cd %%n>NUL 2>&1 && cd %%o>NUL 2>&1 && cd %%p>NUL 2>&1 && cd %%q>NUL 2>&1 && cd %%r>NUL 2>&1
    )
) else (
    echo Not in environment
    EXIT/B
)

echo PATH=%PATH%
echo PERL5LIB=%PERL5LIB%
echo RJK_UTILS_HOME=%RJK_UTILS_HOME%
