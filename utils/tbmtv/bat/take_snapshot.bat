@echo off

set video=%1
set seconds=%2
set hms=%3

set "dir=%~dp1"
set "name=%~n1"

if "%seconds%"=="" set seconds=30
if "%hms%"=="" (
    set start=%seconds%
) else (
    set start=%hms%
)
if "%hms%"=="" (
    set timestr=%start%s
) else (
    set timestr=%start::=.%
)

set "image=%dir%%name%_%timestr%.jpg"

ffmpeg -n -i %video% -ss %start% -vframes 1 "%image%"
