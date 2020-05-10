@echo off

REM switch between environments

SET _dir1=%cd:~0,10%
SET _dir2=%cd:~0,12%

set _to_env=
if /i "%_dir1%"=="c:\scripts" (
    set _to_env=workspace
    SET _subdirs=%cd:~11%
    set PATH=%PATH:c:\scripts\RJK-utils\bat;=c:\workspace\RJK-utils\bat;%
    set PERL5LIB=%PERL5LIB:c:\scripts\RJK-perl5lib\lib;=c:\workspace\RJK-perl5lib\lib;%
)
if /i "%_dir2%"=="c:\workspace" (
    set _to_env=scripts
    SET _subdirs=%cd:~13%
    set PATH=%PATH:c:\workspace\RJK-utils\bat;=c:\scripts\RJK-utils\bat;%
    set PERL5LIB=%PERL5LIB:c:\workspace\RJK-perl5lib\lib;=c:\scripts\RJK-perl5lib\lib;%
)

if defined _to_env (
    cd "c:\%_to_env%\%_subdirs%"
    set RJK_UTILS_HOME=c:\%_to_env%\RJK-utils
) else (
    echo Not in environment
)

echo PATH=%PATH%
echo PERL5LIB=%PERL5LIB%
echo RJK_UTILS_HOME=%RJK_UTILS_HOME%
