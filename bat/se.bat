@echo off

REM switch between environments

set _to_env=%1

if not defined _to_env (
    if /i "%cd:~0,12%"=="c:\workspace" (
        set _subdirs=%cd:~13%
        set _to_env=scripts
    )
    if /i "%cd:~0,10%"=="c:\scripts" (
        set _subdirs=%cd:~11%
        set _to_env=workspace
    )
)

if "%_to_env%"=="workspace" (
    set PATH=%PATH:c:\scripts\RJK-utils\bat=c:\workspace\RJK-utils\bat%
    set PERL5LIB=%PERL5LIB:c:\scripts\RJK-perl5lib\lib=c:\workspace\RJK-perl5lib\lib%
)
if "%_to_env%"=="scripts" (
    set PATH=%PATH:c:\workspace\RJK-utils\bat=c:\scripts\RJK-utils\bat%
    set PERL5LIB=%PERL5LIB:c:\workspace\RJK-perl5lib\lib=c:\scripts\RJK-perl5lib\lib%
)

if defined _to_env (
    set RJK_UTILS_HOME=c:\%_to_env%\RJK-utils
    cd "c:\%_to_env%"
    FOR /F "tokens=1-10 delims=\ " %%i in ("%_subdirs%") do (
        cd %%i>NUL 2>&1 && cd %%j>NUL 2>&1 && cd %%k>NUL 2>&1 && cd %%l>NUL 2>&1 && cd %%l>NUL 2>&1 && ^
        cd %%m>NUL 2>&1 && cd %%n>NUL 2>&1 && cd %%o>NUL 2>&1 && cd %%p>NUL 2>&1 && cd %%q>NUL 2>&1
    )
) else (
    echo Not in environment
)

echo PATH=%PATH%
echo PERL5LIB=%PERL5LIB%
echo RJK_UTILS_HOME=%RJK_UTILS_HOME%
