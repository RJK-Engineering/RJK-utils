@echo on

set video=%1
set seconds=%2
set hms=%3

set "dir=%~dp1"
set "name=%~n1"

if "%seconds%"=="" set seconds=30

if "%hms%"=="" (
    set start=%seconds%
    set timestr=%seconds%s
) else (
    set start=%hms:.=:%
    set timestr=%hms::=.%
)

set "image=%dir%%name%_%timestr%.jpg"

rem width divisible by 2
rem ffmpeg -n -i %video% -ss %start% -vframes 1 -vf "scale=trunc(oh*a/2+0.5)*2:360" "%image%"

ffmpeg -n -i %video% -ss %start% -vframes 1 -vf "scale=-1:360" "%image%"
